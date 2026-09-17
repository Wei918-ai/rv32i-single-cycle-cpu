module alu( input wire [31:0] A,
            input wire [31:0] B,
            input wire [1:0] ALUControl,
            output reg [31:0] result,
            output wire Zero
            );
            
 always @(*) begin
   case(ALUControl)
     2'b00 : result = A & B;
     2'b01 : result = A | B;
     2'b10 : result = A + B;
     2'b11 : result = A - B;
     default: result = 0;
   endcase
 end
 
  assign Zero = ( result == 0);
  
 endmodule
