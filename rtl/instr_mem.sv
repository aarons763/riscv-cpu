module instr_mem #(parameter string HEX_FILE = "coverage_test.hex")
    (input  logic [31:0] addr,
    output logic [31:0] instr
);
    logic [31:0] mem [0:1023]; // 4KB instruction memory

    initial $readmemh(HEX_FILE, mem);

    assign instr = mem[addr[11:2]]; // word-addressed
endmodule
