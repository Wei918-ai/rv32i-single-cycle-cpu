module instr_mem ( input wire [31:0] A,
                    output wire [31:0] instr
);

reg [31:0] rom [0:63];

initial begin
    $readmemh ("program", rom);
end

assign instr= rom[A[7:2]];

endmodule
