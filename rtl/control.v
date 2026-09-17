module control ( input [6:0] opcode,
                 input Zero,
                 input [2:0] funct3,
                 input funct7b5,
                 output RegWrite,
                 output [1:0] ImmSrc,
                 output ALUSrc,
                 output MemWrite,
                 output [1:0] ResultSrc,
                 output reg [1:0] ALUControl,
                 output PCSrc
 );
 
 wire [1:0] ALUOp;
 wire Branch, Jump;
 reg [10:0] controls;
 
 always @(*) begin
  case (opcode)
    7'b001_0011: controls= 11'b1_00_1_0_00_0_0_00;  //ADDI
    7'b000_0011: controls= 11'b1_00_1_0_01_0_0_00;  //LW
    7'b010_0011: controls= 11'b0_01_1_1_00_0_0_00;  //SW
    7'b110_0011: controls= 11'b0_10_0_0_00_1_0_01;  //BEQ
    7'b110_1111: controls= 11'b1_11_0_0_10_0_1_00;  //JAL
    7'b011_0011: controls= 11'b1_00_0_0_00_0_0_10;  //R type
    default: controls= 0;
   endcase
  end
  
  assign {RegWrite, ImmSrc, ALUSrc, MemWrite, ResultSrc, Branch, Jump, ALUOp}= controls;
  
 always @(*) begin
  case (ALUOp)
    2'b00: ALUControl= 2'b10;
    2'b01: ALUControl= 2'b11;
    2'b10: begin
            case(funct3)
                3'b111: ALUControl= 2'b00;
                3'b110: ALUControl= 2'b01;
                3'b000: ALUControl= (funct7b5) ? 2'b11 : 2'b10;
                default: ALUControl= 0;
             endcase
            end
    default: ALUControl=0;
   endcase
  end
  
  assign PCSrc= Jump | (Branch & Zero);
endmodule
 
 
 
 
                 
