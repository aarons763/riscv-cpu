# Generic Synthesis Summary

## Tool and Command

- Tool: Yosys 0.52
- Command: `make synth`
- Top module: `cpu_top`

## Result

Generic synthesis completed successfully with no Yosys errors.

| Metric | Result |
|---|---:|
| Logical cells | 121 |
| Abstract memory cells | 2 |
| Module instances in hierarchy | 7 |
| Top-level hierarchy | `cpu_top`, `alu`, `control`, `data_mem`, `imm_gen`, `instr_mem`, `regfile` |

## Logical Cell Breakdown

| Cell type | Count |
|---|---:|
| Adders | 3 |
| Subtractors | 1 |
| Multiplexers | 27 |
| Priority multiplexers | 10 |
| Equality comparators | 43 |
| Less-than comparators | 2 |
| Shift-left operators | 1 |
| Logical shift-right operators | 1 |
| Arithmetic shift-right operators | 1 |
| Abstract memories | 2 |

## Interpretation

This is a technology-independent synthesis result.

The two memories remain as abstract `$mem_v2` cells because the synthesis script uses `memory -nomap`. This avoids converting the 4 KiB instruction and data memories into large flip-flop arrays.

This report does not provide FPGA LUT count, ASIC area, timing, or maximum clock frequency. Those measurements require mapping the design to a specific FPGA family or ASIC standard-cell library.