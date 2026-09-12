SRC = regfile.sv alu.sv imm_gen.sv control.sv instr_mem.sv data_mem.sv cpu_top.sv tb_cpu.sv

sim: $(SRC)
	iverilog -g2012 -o sim.out $(SRC)
	vvp sim.out

wave: sim
	gtkwave wave.vcd &

clean:
	rm -f sim.out wave.vcd
