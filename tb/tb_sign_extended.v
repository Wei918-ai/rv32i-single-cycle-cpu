`timescale 1ns / 1ps

module tb_sign_extend;
  reg  [1:0]  ImmSrc;
  reg  [31:0] inst;
  wire [31:0] ImmExt;

  integer errors = 0;

  // Instantiate the DUT
  sign_extend dut (
    .ImmSrc(ImmSrc),
    .inst(inst),
    .ImmExt(ImmExt)
  );

  // Self-check task
  task check;
    input [1:0]  tsrc;
    input [31:0] tinst;
    input [31:0] expected;
    begin
      ImmSrc = tsrc; inst = tinst;
      #10;
      if (ImmExt !== expected) begin
        errors = errors + 1;
        $display("ERROR: ImmSrc=%b inst=%h | ImmExt=%h (expect %h)",
                  tsrc, tinst, ImmExt, expected);
      end else begin
        $display("PASS : ImmSrc=%b inst=%h -> ImmExt=%h", tsrc, tinst, ImmExt);
      end
    end
  endtask

  initial begin
    // ---- I-type (ImmSrc=00) ----
    check(2'b00, 32'h00100000, 32'h00000001); // imm=+1
    check(2'b00, 32'hFFF00000, 32'hFFFFFFFF); // imm=-1 (test sign extension)
    check(2'b00, 32'h00000000, 32'h00000000); // imm=0

    // ---- S-type (ImmSrc=01) ----  (≈ sw x1,8(x2))
    check(2'b01, 32'h00112423, 32'h00000008); // imm=+8

    // ---- B-type (ImmSrc=10) ----  (≈ beq x1,x2,8)
    check(2'b10, 32'h00208463, 32'h00000008); // imm=+8

    // ---- J-type (ImmSrc=11) ----  (≈ jal x1,8)
    check(2'b11, 32'h008000EF, 32'h00000008); // imm=+8

    if (errors == 0) $display(">>> All Pass!");
    else             $display(">>> Error %0d", errors);
    $finish;
  end
endmodule
