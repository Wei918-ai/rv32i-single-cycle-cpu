`timescale 1ns / 1ps
//======================================================================
//  tb_cpu_d7_full  -  D7 full version: program_d7 five items + JAL return address
//  New part (starting at address 0x2C):
//    jal x1, 8          <- should jump to 0x34, and x1 = 0x2C+4 = 48
//    addi x9, x0, 99    <- trap instruction, not executed if JAL really jumps
//    beq  x0, x0, 0     <- new self-locking halt
//  Criteria: x1==48 proves the return address is correct;
//            x9 still 2 (not 99) proves the jump really happened.
//======================================================================
module tb_cpu_d7_full;

    reg clk = 0;
    reg rst;
    integer errors = 0;

    cpu dut(.clk(clk), .rst(rst));

    always #5 clk = ~clk;

    task check;
        input [8*20:1] name;
        input [31:0]   actual;
        input [31:0]   expected;
        begin
            if (actual !== expected) begin
                errors = errors + 1;
                $display("  [FAIL] %0s = %0d  expect %0d", name, actual, expected);
            end else begin
                $display("  [ pass] %0s = %0d", name, actual);
            end
        end
    endtask

    initial begin
        rst = 1;
        @(negedge clk); @(negedge clk);
        rst = 0;

        #300;   // 14 straight-line instructions + 1 jump, 300ns is more than enough

        $display("\n========================================");
        check("x1  JAL",   dut.regfile1.rf[1], 32'd48);
        check("x3  SUB 15-9",      dut.regfile1.rf[3], 32'd6);
        check("x4  AND 15&9",      dut.regfile1.rf[4], 32'd9);
        check("x5  OR  15|9",      dut.regfile1.rf[5], 32'd15);
        check("x6  ADDI 15+(-1)",  dut.regfile1.rf[6], 32'd14);
        check("x7  LW  mem[0]",    dut.regfile1.rf[7], 32'd15);
        check("x8  BEQ-not-taken", dut.regfile1.rf[8], 32'd1);
        check("x9  right", dut.regfile1.rf[9], 32'd2);   // * Key: proves JAL really skipped the trap
        check("mem[0] SW x1",      dut.data_mem1.ram[0], 32'd15);
        $display("====================================================");

        if (errors == 0)
            $display(">>> All PASS <<<\n");
        else
            $display(">>> error %0d  <<<\n", errors);
        $finish;
    end

endmodule
