module data_mem ( input wire clk,
                  input wire WE,
                  input wire [31:0] A,
                  input wire [31:0] WD,
                  output wire [31:0] RD
);

reg [31:0] ram [63:0];

always @ (posedge clk)
 if (WE) ram[A[7:2]] <= WD;

assign RD = ram[A[7:2]];

endmodule
