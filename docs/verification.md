# Verification Strategy

## Goal

Verify the implemented RV32I instruction subset at both the module level and complete-CPU level.

## Test Layers

| Layer | Testbench / command | Purpose |
|---|---|---|
| ALU | `make build-alu` | Verifies arithmetic, logic, shifts, signed/unsigned comparisons, zero detection, and 32-bit wraparound |
| Immediate generator | `make build-imm` | Verifies I/S/B/U/J immediate extraction and sign extension |
| Control decoder | `make build-control` | Verifies instruction decode control signals and ALU operation selection |
| Register file | `make build-regfile` | Verifies clocked writes, two combinational read ports, and immutable `x0` |
| Data memory | `make build-data-mem` | Verifies clocked writes, reads, and disabled read/write behavior |
| Smoke test | `make build-smoke` | Runs a short CPU program containing arithmetic, load/store, branch, and jump operations |
| Directed integration test | `make build-coverage` | Runs a longer program covering every currently supported instruction family |
| Lint | `make lint` | Uses Verilator to identify RTL issues before simulation |

## Directed Integration-Test Coverage

The integration program verifies:

- R-type ALU operations.
- I-type ALU operations.
- Word store followed by word load.
- `lui` and `auipc`.
- Taken and not-taken branch behavior.
- Signed versus unsigned branch comparison.
- `jal` and `jalr` target and link-register behavior.
- Infinite `jal x0, 0` halt loop.

## Known Lint Warnings

Verilator reports unused address bits in instruction and data memory.

This is expected in the current design:

- `addr[11:2]` selects one of 1024 32-bit words.
- `addr[1:0]` is ignored because accesses are word-aligned.
- `addr[31:12]` is ignored because each memory is limited to 4 KiB.

Future work will add assertions or trap behavior for unaligned/out-of-range accesses.

## Planned Verification Improvements

1. Python reference model and randomized differential testing.
2. Functional and code coverage collection using Verilator.
3. SystemVerilog assertions for invariants such as `x0 == 0`.
4. Formal checks with SymbiYosys.
5. Yosys synthesis and resource reporting.
6. Continuous integration that runs lint and tests on every Git commit.