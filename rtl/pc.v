module pc (input wire [31:0] PCnext,
           input wire clk,
           input wire rst,
           output reg [31:0] PC
);

always @(posedge clk)
 if (rst) PC <= 0;
 else PC <= PCnext;

endmodule
