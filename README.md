# RV32I Single-Cycle CPU

A single-cycle RISC-V (RV32I subset) processor written in Verilog, verified through simulation in Vivado/XSim.

The focus of this project is not only implementing the datapath, but **proving that every instruction is actually correct** — a working sum program is not evidence that each instruction works, only that the instructions it happens to use are not broken.

---

## Specification

| Parameter | Value |
|---|---|
| Data width | 32-bit |
| Registers | 32 general-purpose (x0 hardwired to 0) |
| Instruction width | 32-bit |
| Addressing | Byte-addressed, `PC = PC + 4` |
| Microarchitecture | Single-cycle (fetch—decode—execute—memory—writeback in one clock) |
| Toolchain | Verilog, Vivado 2025.2, XSim |

### Supported instructions

| Instruction | Format | opcode | funct3 | funct7 | Operation |
|---|---|---|---|---|---|
| `ADD`  | R | 0110011 | 000 | 0000000 | `rd = rs1 + rs2` |
| `SUB`  | R | 0110011 | 000 | 0100000 | `rd = rs1 - rs2` |
| `AND`  | R | 0110011 | 111 | 0000000 | `rd = rs1 & rs2` |
| `OR`   | R | 0110011 | 110 | 0000000 | `rd = rs1 \| rs2` |
| `ADDI` | I | 0010011 | 000 | —| `rd = rs1 + imm` |
| `LW`   | I | 0000011 | 010 | —| `rd = mem[rs1 + imm]` |
| `SW`   | S | 0100011 | 010 | —| `mem[rs1 + imm] = rs2` |
| `BEQ`  | B | 1100011 | 000 | —| `if (rs1 == rs2) PC += imm` |
| `JAL`  | J | 1101111 | —| —| `rd = PC + 4; PC += imm` |

---

## Architecture

### Module hierarchy

| Module | File | Responsibility | Logic type |
|---|---|---|---|
| ALU | `rtl/alu.v` | add / sub / and / or, `Zero` flag | Combinational |
| Register file | `rtl/regfile.v` | 2-read/1-write, async read, sync write, x0 = 0 | Sync write, async read |
| Sign extender | `rtl/sign_extend.v` | Assembles and sign-extends I/S/B/J immediates | Combinational |
| Control unit | `rtl/control.v` | Two-level decode, generates all control signals | Combinational |
| Instruction memory | `rtl/instr_mem.v` | ROM, program loaded via `$readmemh` | Async read |
| Data memory | `rtl/data_mem.v` | 64 words, sync write, async read | Sync write, async read |
| Program counter | `rtl/pc.v` | Synchronous reset, updates every cycle | Sequential |
| Top level | `rtl/cpu.v` | Instantiation, 3 muxes, branch-target adder | Structural |

### Control signals

| Signal | Width | Controls |
|---|---|---|
| `RegWrite` | 1 | Whether the register file is written this cycle |
| `ImmSrc` | 2 | Which immediate format the sign extender assembles |
| `ALUSrc` | 1 | ALU operand B: register value or immediate |
| `MemWrite` | 1 | Whether data memory is written this cycle |
| `ResultSrc` | 2 | Writeback source: ALU result / memory data / PC+4 |
| `ALUControl` | 2 | ALU operation (`00`=AND, `01`=OR, `10`=ADD, `11`=SUB) |
| `PCSrc` | 1 | Next PC: branch/jump target or PC+4 |

### Two-level ALU decode

The control unit decodes the ALU operation in two stages:

1. **From `opcode`** → produces a coarse `ALUOp`: `00` (add), `01` (sub), or `10` (defer).
   `ADDI`/`LW`/`SW`/`JAL` need only addition and `BEQ` needs only subtraction, so these are resolved immediately from the opcode alone.
2. **From `ALUOp = 10`** → the four R-type instructions share one opcode (`0110011`) and are distinguished by `funct3` and `funct7[5]`, so only this case consults them.

This keeps `funct3` out of the decision path for instructions where it carries unrelated information `LW` has `funct3 = 010` (word-sized access), which has nothing to do with the ALU needing to add.

---

## Verification

Every instruction was verified by a dedicated test program, not inferred from a program that produces a correct final answer. All tests are self-checking: the testbench compares against expected values, counts mismatches, and prints a pass/fail summary no manual waveform inspection required.

### Test programs

| Program | Testbench | Coverage |
|---|---|---|
| `programs/program` | `tb/tb_cpu_d7_full.v` | `ADDI`, `ADD`, `BEQ` taken, `JAL``SUB`, `AND`, `OR`, negative-immediate `ADDI`, `LW`/`SW`, `BEQ`, `JAL` return address |
| `programs/program_multi_mem.hex` | `tb/tb_cpu_multi_mem.v` | `LW`/`SW` across multiple distinct addresses |
| `programs/program_array_sum.hex` | `tb/tb_cpu_array_sum.v` | Array summation: loop + memory access + branch working together `x1 = 35` |

### Per-instruction results

| Verified behaviour | Method | Expected | Result |
|---|---|---|---|
| `ADD` | Accumulate in loop | `x1 = 55` | Pass |
| `SUB` | `15 - 9` | `x3 = 6` | Pass |
| `AND` | `15 & 9` | `x4 = 9` | Pass |
| `OR` | `15 \| 9` | `x5 = 15` | Pass |
| `ADDI`, negative immediate | `15 + (-1)` | `x6 = 14` | Pass |
| `SW` →`LW`, same address | Store 15, read back | `x7 = 15` | Pass |
| `SW` →`LW`, distinct addresses | Store 10/11/12 to `ram[0..2]`, read back | `x4,x5,x6 = 10,11,12` | Pass |
| `BEQ` taken | Loop exit when counter reaches 0 | Loop terminates | Pass |
| `BEQ` not taken | `15 != 9`, must fall through | `x8 = 1` | Pass |
| `JAL` jump | Loop back-edge | Loop repeats | Pass |
| `JAL` return address | `jal x1, 8` at `0x2C` | `x1 = 48` (= `0x2C + 4`) | Pass |

### Verification techniques

**Distinct test values.** The multi-address memory test writes three *different* values (10, 11, 12) to three consecutive words. If the address decode (`A[7:2]`) were off by a bit and a store landed in the wrong word, identical test values would hide the fault — distinct values make any aliasing immediately visible.

**Trap instructions to prove control flow.** Checking that `JAL` writes the correct return address is not sufficient to prove the jump happened: if `Jump` were misrouted and the PC never jumped, `x1` could still be written correctly and the test would pass on a false premise. A trap instruction writing an out-of-range sentinel (`addi x9, x0, 99`) is placed between the jump and its target. The jump is only confirmed if that value **never appears**. The same technique verifies `BEQ` not-taken from the opposite direction: an instruction after the branch must execute.

**Self-locking halt.** Programs terminate with `beq x0, x0, 0` —offset 0 with an always-true condition, so the PC branches to itself and freezes. Ending with a `nop` instead lets the PC keep incrementing into uninitialised ROM, fetching `x` and polluting the simulation output.

**Reset alignment.** Reset is released on a falling clock edge (`@(negedge clk)`) so that the first rising edge after release executes instruction 0. Releasing reset on a rising edge swallows the first instruction.

---

## Repository layout

```
rtl/                    RTL sources
  alu.v
  regfile.v
  sign_extend.v
  control.v
  instr_mem.v
  data_mem.v
  pc.v
  cpu.v                 top level
tb/                     self-checking testbenches
  tb_alu.v
  tb_regfile.v
  tb_control.v
  tb_data_mem.v
  tb_cpu_d7_full.v      per-instruction verification
  tb_cpu_multi_mem.v    multi-address memory
  tb_cpu_array_sum.v    array summation
programs/               hand-assembled test programs (hex)
  program.hex
  program_multi_mem.hex
  program_array_sum.hex
docs/                   design notes, datapath
```

---

