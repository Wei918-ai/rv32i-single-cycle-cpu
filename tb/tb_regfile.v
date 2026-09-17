`timescale 1ns / 1ps

module tb_regfile;
  reg         clk;
  reg         we;
  reg  [4:0]  ra1, ra2, wa3;
  reg  [31:0] wd;
  wire [31:0] rd1, rd2;

  integer errors = 0;

  // Instantiate the DUT
  regfile dut (
    .clk(clk), .we(we),
    .ra1(ra1), .ra2(ra2), .wa3(wa3),
    .wd(wd),
    .rd1(rd1), .rd2(rd2)
  );

  // 1) Generate clock: toggle every 5ns -> period 10ns
  initial clk = 0;
  always #5 clk = ~clk;

  // 2) Write task: write wd into wa3 on the rising edge
  task write_reg;
    input [4:0]  addr;
    input [31:0] data;
    begin
      @(negedge clk);      // Set inputs on falling edge, away from sampling point
      we = 1; wa3 = addr; wd = data;
      @(posedge clk);      // Rising edge performs the actual write
      @(negedge clk);
      we = 0;              // Turn off enable after writing
    end
  endtask

  // 3) Read check task (read is combinational, apply address and wait a bit)
  task check_read;
    input [4:0]  addr;
    input [31:0] expected;
    begin
      ra1 = addr;
      #1;                  // Wait for combinational logic to settle
      if (rd1 !== expected) begin
        errors = errors + 1;
        $display("ERROR: read x%0d = %h (expect %h)", addr, rd1, expected);
      end else begin
        $display("PASS : read x%0d = %h", addr, rd1);
      end
    end
  endtask

  // 4) Test sequence
  initial begin
    we = 0; ra1 = 0; ra2 = 0; wa3 = 0; wd = 0;
    #12;  // Wait for clock to stabilize

    // Test 1: write x5 = 0xABCD, then read back
    write_reg(5, 32'h0000ABCD);
    check_read(5, 32'h0000ABCD);

    // Test 2: write x10 = 0x12345678, then read back
    write_reg(10, 32'h12345678);
    check_read(10, 32'h12345678);

    // Test 3: x0 is always 0 -- deliberately write to x0, read must still be 0
    write_reg(0, 32'hFFFFFFFF);
    check_read(0, 32'h00000000);

    // Test 4: no write when we=0 -- x5 should keep its value, not overwritten
    @(negedge clk);
    we = 0; wa3 = 5; wd = 32'hDEADBEEF;  // Enable is off, this should not be written
    @(posedge clk); #1;
    check_read(5, 32'h0000ABCD);          // Should still be the original ABCD

    if (errors == 0) $display(">>> All pass!");
    else             $display(">>> Error %0d", errors);
    $finish;
  end
endmodule
