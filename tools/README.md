# RV32I coverage test suite

Run:
    python3 build_coverage_test.py        # generates program.hex
    iverilog -g2012 -o cov.out ../rtl/regfile.sv ../rtl/alu.sv ../rtl/imm_gen.sv ../rtl/control.sv ../rtl/instr_mem.sv ../rtl/data_mem.sv ../rtl/cpu_top.sv tb_coverage.sv
    vvp cov.out
