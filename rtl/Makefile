SRC = regfile.sv alu.sv imm_gen.sv control.sv instr_mem.sv data_mem.sv cpu_top.sv

smoke: $(SRC) tb_cpu.sv
	cd tests && python3 mini_asm.py
	iverilog -g2012 -o smoke.out $(addprefix rtl/,$(SRC)) rtl/tb_cpu.sv
	vvp smoke.out

coverage: $(SRC) tb_coverage.sv
	cd tests && python3 build_coverage_test.py
	iverilog -g2012 -o cov.out $(addprefix rtl/,$(SRC)) rtl/tb_coverage.sv
	vvp cov.out

clean:
	rm -f *.out rtl/*.hex wave.vcd