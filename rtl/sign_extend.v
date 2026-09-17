module sign_extend ( input wire [1:0] ImmSrc,
                     input wire [31:0] inst,
                     output reg [31:0] ImmExt
);

  always @(*) begin
   case(ImmSrc)
   2'b00: ImmExt = {{20{inst[31]}}, inst[31:20]};
   2'b01: ImmExt = {{20{inst[31]}}, inst[31:25], inst[11:7]};
   2'b10: ImmExt = {{20{inst[31]}}, inst[7], inst[30:25], inst[11:8], 1'b0};
   2'b11: ImmExt = {{12{inst[31]}}, inst[19:12], inst[20], inst[30:21], 1'b0};
   default: ImmExt = 0;
   endcase
  end
endmodule
