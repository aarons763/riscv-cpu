# RV32I Single-Cycle RISC-V CPU

A working single-cycle RV32I core in SystemVerilog, verified in simulation with Icarus Verilog.

## Structure
- `rtl/` - CPU source (regfile, alu, control, imm_gen, instr_mem, data_mem, cpu_top) + testbench
- `tools/mini_asm.py` - hand-rolled encoder used to build the first smoke-test program

## Run the simulation
```
cd rtl
make sim
```
