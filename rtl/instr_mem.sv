module instr_mem (
    input  logic [31:0] addr,
    output logic [31:0] instr
);
    logic [31:0] mem [0:1023]; // 4KB instruction memory

    initial begin
        $readmemh("program.hex", mem);
    end

    assign instr = mem[addr[11:2]]; // word-addressed
endmodule
