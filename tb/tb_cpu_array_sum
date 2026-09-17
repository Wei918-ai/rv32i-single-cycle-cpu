`timescale 1ns / 1ps
//======================================================================
//  tb_cpu_array_sum  -  D8 array sum (milestone M3)
//  Store array 5,10,20 into ram[0]/ram[1]/ram[2], accumulate in a loop,
//  proving that loop + memory access + branch work together correctly.
//  x1 (sum) should finally be 35.
//======================================================================
module tb_cpu_array_sum;

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

    // Cycle-by-cycle trace for easy comparison (comment out if not needed)
    always @(posedge clk) if (!rst)
        $display("t=%0t  PC=%0d  x1(sum)=%0d  x2(address)=%0d  x3(counter)=%0d",
                  $time, dut.PC, dut.regfile1.rf[1], dut.regfile1.rf[2], dut.regfile1.rf[3]);

    initial begin
        rst = 1;
        @(negedge clk); @(negedge clk);
        rst = 0;

        #500;   // 16 instructions + loop running 3 times, 500ns is enough

        $display("\n================================");
        check("x1 sum(5+10+20)", dut.regfile1.rf[1], 32'd35);
        check("x2 address point",   dut.regfile1.rf[2], 32'd12);
        check("x3 counter=0",     dut.regfile1.rf[3], 32'd0);
        check("ram[0]",            dut.data_mem1.ram[0], 32'd5);
        check("ram[1]",            dut.data_mem1.ram[1], 32'd10);
        check("ram[2]",            dut.data_mem1.ram[2], 32'd20);
        $display("==================================================");

        if (errors == 0)
            $display(">>> all pass <<<\n>>> M3 finish <<<\n");
        else
            $display(">>> error %0d  <<<\n", errors);
        $finish;
    end

endmodule
