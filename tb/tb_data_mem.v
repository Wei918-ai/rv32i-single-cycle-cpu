`timescale 1ns / 1ps
module tb_data_mem;
  reg         clk, WE;
  reg  [31:0] A, WD;
  wire [31:0] RD;
  integer errors = 0;

  data_mem dut (.clk(clk), .WE(WE), .A(A), .WD(WD), .RD(RD));

  initial clk = 0;
  always #5 clk = ~clk;         // Generate clock

  // Write task: set inputs on falling edge, write on rising edge
  task write_mem;
    input [31:0] addr, data;
    begin
      @(negedge clk); WE=1; A=addr; WD=data;
      @(posedge clk);
      @(negedge clk); WE=0;
    end
  endtask

  // Read check: read is combinational, apply address and wait a bit
  task check_read;
    input [31:0] addr, expected;
    begin
      A = addr; #1;
      if (RD !== expected) begin
        errors=errors+1;
        $display("ERROR: addr=%0d -> RD=%h (expect %h)", addr, RD, expected);
      end else
        $display("PASS : addr=%0d -> RD=%h", addr, RD);
    end
  endtask

  initial begin
    WE=0; A=0; WD=0; #12;

    write_mem(32'd8,  32'h0000AAAA);      // Write address 8
    check_read(32'd8, 32'h0000AAAA);      // Read back

    write_mem(32'd12, 32'h12345678);      // Write address 12 (different address)
    check_read(32'd12, 32'h12345678);
    check_read(32'd8,  32'h0000AAAA);     // Address 8 should be unaffected

    // WE=0 means no write
    @(negedge clk); WE=0; A=32'd8; WD=32'hDEADBEEF;
    @(posedge clk); #1;
    check_read(32'd8, 32'h0000AAAA);      // Should still be AAAA

    if (errors==0) $display(">>> All Pass!");
    else           $display(">>> Error: %0d ", errors);
    $finish;
  end
endmodule
