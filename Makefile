RTL = \
	rtl/regfile.sv \
	rtl/alu.sv \
	rtl/imm_gen.sv \
	rtl/control.sv \
	rtl/instr_mem.sv \
	rtl/data_mem.sv \
	rtl/cpu_top.sv

build-smoke:
	cd tools && python3 mini_asm.py
	iverilog -g2012 -s tb_cpu -o build_smoke.out $(RTL) rtl/tb_cpu.sv
	vvp build_smoke.out +HEX=rtl/smoke_test.hex

build-coverage:
	cd tools && python3 build_coverage_test.py
	iverilog -g2012 -s tb_coverage -o build_coverage.out $(RTL) rtl/tb_coverage.sv
	vvp build_coverage.out +HEX=rtl/coverage_test.hex

lint:
	verilator --lint-only --Wall -Wno-fatal $(RTL)

build-alu:
	iverilog -g2012 -s tb_alu -o build_alu.out rtl/alu.sv tb/tb_alu.sv
	vvp build_alu.out

build-imm:
	iverilog -g2012 -s tb_imm_gen -o build_imm.out rtl/imm_gen.sv tb/tb_imm_gen.sv
	vvp build_imm.out

build-control:
	iverilog -g2012 -s tb_control -o build_control.out rtl/control.sv tb/tb_control.sv
	vvp build_control.out

build-regfile:
	iverilog -g2012 -s tb_regfile -o build_regfile.out rtl/regfile.sv tb/tb_regfile.sv
	vvp build_regfile.out

build-data-mem:
	iverilog -g2012 -s tb_data_mem -o build_data_mem.out rtl/data_mem.sv tb/tb_data_mem.sv
	vvp build_data_mem.out

random-alu:
	python3 tools/random_alu_test.py --tests 100 --length 100

synth:
	mkdir -p reports
	yosys -s scripts/synth.ys | tee reports/yosys_synthesis.log

test: build-alu build-imm build-control build-regfile build-data-mem build-smoke build-coverage

clean:
	rm -f build_random_alu.out build_data_mem.out build_regfile.out build_control.out build_alu.out build_imm.out build_smoke.out build_coverage.out wave.vcd
	rm -f rtl/smoke_test.hex rtl/coverage_test.hex