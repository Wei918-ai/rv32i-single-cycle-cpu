`timescale 1ns / 1ps

module tb_control;

reg [6:0] opcode;
reg [2:0] funct3;
reg       funct7b5;
reg       Zero;
wire      RegWrite;
wire [1:0] ImmSrc;
wire      ALUSrc;
wire      MemWrite;
wire [1:0] ResultSrc;
wire [1:0] ALUControl;
wire      PCSrc;

integer errors= 0;

control dut(
.opcode(opcode), .funct3(funct3), .funct7b5(funct7b5), .Zero(Zero),
.RegWrite(RegWrite), .ImmSrc(ImmSrc), .ALUSrc(ALUSrc),
.MemWrite(MemWrite), .ResultSrc(ResultSrc),
.ALUControl(ALUControl), .PCSrc(PCSrc)
);

task check;
  input [6:0] t_op;
  input [2:0] t_funct3;
  input       t_funct7b5;
  input       t_Zero;
  input       exp_RegWrite;
  input [1:0] exp_ImmSrc;
  input       exp_ALUSrc;
  input       exp_MemWrite;
  input [1:0] exp_ResultSrc;
  input [1:0] exp_ALUControl;
  input       exp_PCSrc;
  
  
  begin
  opcode=t_op; funct3=t_funct3; funct7b5=t_funct7b5; Zero=t_Zero;
 #10;
 
  if (RegWrite!==exp_RegWrite||ImmSrc!==exp_ImmSrc||ALUSrc!==exp_ALUSrc||MemWrite!==exp_MemWrite||ResultSrc!==exp_ResultSrc||ALUControl!==exp_ALUControl||PCSrc!==exp_PCSrc) begin
  errors = errors +1;
  end
  end
 endtask
 
 initial begin
 check(7'b011_0011,3'b000,1'b0,1'b0, 1'b1,2'b00,1'b0,1'b0,2'b00,2'b10,1'b0);
 check(7'b011_0011,3'b000,1'b1,1'b0, 1'b1,2'b00,1'b0,1'b0,2'b00,2'b11,1'b0);
 check(7'b011_0011,3'b111,1'b0,1'b0, 1'b1,2'b00,1'b0,1'b0,2'b00,2'b00,1'b0);
 check(7'b011_0011,3'b110,1'b0,1'b0, 1'b1,2'b00,1'b0,1'b0,2'b00,2'b01,1'b0);
 check(7'b001_0011,3'b000,1'b0,1'b0, 1'b1,2'b00,1'b1,1'b0,2'b00,2'b10,1'b0);
 check(7'b000_0011,3'b010,1'b0,1'b0, 1'b1,2'b00,1'b1,1'b0,2'b01,2'b10,1'b0);
 check(7'b010_0011,3'b010,1'b0,1'b0, 1'b0,2'b01,1'b1,1'b1,2'b00,2'b10,1'b0);
 check(7'b110_0011,3'b000,1'b0,1'b0, 1'b0,2'b10,1'b0,1'b0,2'b00,2'b11,1'b0);
 check(7'b110_0011,3'b000,1'b0,1'b1, 1'b0,2'b10,1'b0,1'b0,2'b00,2'b11,1'b1);
 check(7'b110_1111,3'b000,1'b0,1'b0, 1'b1,2'b11,1'b0,1'b0,2'b10,2'b10,1'b1);
 
 if (errors ==0) $display("All Pass!");
 else            $display("Error %0d",errors);
 $finish;
 end
 
 endmodule
 
  
