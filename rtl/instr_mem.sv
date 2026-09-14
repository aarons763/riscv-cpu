module instr_mem (
    input  logic [31:0] addr,
    output logic [31:0] instr
);

    logic [31:0] mem [0:1023];

`ifndef SYNTHESIS
    string hex_file;

    initial begin
        // Simulation-only program loading.
        if (!$value$plusargs("HEX=%s", hex_file))
            hex_file = "rtl/coverage_test.hex";

        $display("Loading instruction memory from %s", hex_file);
        $readmemh(hex_file, mem);
    end
`endif

    assign instr = mem[addr[11:2]];

endmodule
