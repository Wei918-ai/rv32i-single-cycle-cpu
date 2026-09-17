module cpu ( input wire clk,
             input wire rst
 );
 
 wire [31:0] PC, PCNext, PCPlus4,PCTarget;
 wire [31:0] instr;
 wire [31:0] ImmExt, SrcB;
 wire [31:0] RD1, RD2;
 wire [31:0] ALUResult, Result, ReadData;
 wire PCSrc, MemWrite, ALUSrc, RegWrite, Zero;
 wire [1:0] ResultSrc, ALUControl, ImmSrc;
 
 alu alu1(.A(RD1), .B(SrcB), .Zero(Zero), 
          .ALUControl(ALUControl), .result(ALUResult)
 );
 
 data_mem data_mem1(.A(ALUResult), .clk(clk), .WE(MemWrite), 
                    .RD(ReadData), .WD(RD2)
 );
 
 instr_mem instr_mem1(.A(PC), .instr(instr)
 );
 
 pc pc1(.PCnext(PCNext), .clk(clk), .rst(rst), .PC(PC)
 );
 
 regfile regfile1(.ra1(instr[19:15]), 
                  .ra2(instr[24:20]),
                  .wa3(instr[11:7]),
                  .wd(Result), .rd1(RD1), .rd2(RD2),
                  .clk(clk), .we(RegWrite)
 );
 
 sign_extend sign_extend1(.ImmSrc(ImmSrc), 
                          .ImmExt(ImmExt),
                          .inst(instr)
 );
 
 control control1(.opcode(instr[6:0]),
                  .funct3(instr[14:12]),
                  .funct7b5(instr[30]),
                  .Zero(Zero),
                  .RegWrite(RegWrite),
                  .ImmSrc(ImmSrc),
                  .ALUSrc(ALUSrc),
                  .MemWrite(MemWrite),
                  .ResultSrc(ResultSrc),
                  .ALUControl(ALUControl),
                  .PCSrc(PCSrc)
 );
 
 assign SrcB = ALUSrc ? ImmExt : RD2;
 assign PCNext = PCSrc ? PCTarget : PCPlus4;
 assign Result = (ResultSrc==0) ? ALUResult : (ResultSrc==1) ? ReadData : PCPlus4;
 assign PCTarget = PC + ImmExt;
 assign PCPlus4 = PC + 4;
 
 endmodule
 
                  
 
 
 
