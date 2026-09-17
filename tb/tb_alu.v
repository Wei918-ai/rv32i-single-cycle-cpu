`timescale 1ns / 1ps

module tb_alu;
  // 1) Signals connected to the DUT
  reg  [31:0] A, B;
  reg  [1:0]  ALUControl;
  wire [31:0] result;
  wire        Zero;

  integer errors = 0;   // Error count

  // 2) Instantiate the DUT
  alu dut (
    .A(A),
    .B(B),
    .ALUControl(ALUControl),
    .result(result),
    .Zero(Zero)
  );

  // 3) Self-check task: apply inputs, wait, compare
  task check;
    input [31:0] ta, tb_in;
    input [1:0]  tctrl;
    input [31:0] expected;
    input        exp_zero;
    begin
      A = ta; B = tb_in; ALUControl = tctrl;
      #10;   // Wait for logic to settle
      if (result !== expected || Zero !== exp_zero) begin
        errors = errors + 1;
        $display("ERROR: A=%h B=%h ctrl=%b | result=%h (expect %h) Zero=%b (expect %b)",
                  ta, tb_in, tctrl, result, expected, Zero, exp_zero);
      end else begin
        $display("PASS : A=%h B=%h ctrl=%b -> result=%h Zero=%b",
                  ta, tb_in, tctrl, result, Zero);
      end
    end
  endtask

  // 4) Test sequence
  initial begin
    // ALUControl: 00=AND 01=OR 10=ADD 11=SUB
    check(32'd5,  32'd3,  2'b10, 32'd8,        1'b0); // ADD
    check(32'd8,  32'd3,  2'b11, 32'd5,        1'b0); // SUB
    check(32'd5,  32'd5,  2'b11, 32'd0,        1'b1); // SUB equal -> Zero=1
    check(32'd3,  32'd8,  2'b11, 32'hFFFFFFFB, 1'b0); // SUB negative
    check(32'hF0, 32'h0F, 2'b00, 32'h00,       1'b1); // AND -> Zero=1
    check(32'hF0, 32'h0F, 2'b01, 32'hFF,       1'b0); // OR
    check(32'd0,  32'd0,  2'b10, 32'd0,        1'b1); // ADD -> Zero=1

    // 5) Summary
    if (errors == 0) $display(">>> All Pass!");
    else             $display(">>> error %0d ", errors);
    $finish;
  end
endmodule
