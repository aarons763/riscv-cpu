#!/usr/bin/env python3

import argparse
import random
import re
import subprocess
import sys
from pathlib import Path

from isa import (
    add, sub, sll, slt, sltu, xor_, srl, sra, or_, and_,
    addi, slti, sltiu, xori, ori, andi, slli, srli, srai,
    jal,
)

MASK32 = 0xFFFFFFFF
PROJECT_ROOT = Path(__file__).resolve().parents[1]
HEX_FILE = PROJECT_ROOT / "rtl" / "random_alu_test.hex"
SIM_FILE = PROJECT_ROOT / "build_random_alu.out"


def u32(value):
    """Keep a Python integer within the CPU's 32-bit register width."""
    return value & MASK32


def s32(value):
    """Interpret a 32-bit unsigned value as signed two's-complement."""
    value = u32(value)
    return value - (1 << 32) if value & 0x80000000 else value


def execute_r_type(operation, a, b):
    """Independent Python model of each R-type ALU operation."""
    shift_amount = b & 0x1F

    if operation == "add":
        return u32(a + b)
    if operation == "sub":
        return u32(a - b)
    if operation == "sll":
        return u32(a << shift_amount)
    if operation == "slt":
        return 1 if s32(a) < s32(b) else 0
    if operation == "sltu":
        return 1 if u32(a) < u32(b) else 0
    if operation == "xor":
        return u32(a ^ b)
    if operation == "srl":
        return u32(a) >> shift_amount
    if operation == "sra":
        return u32(s32(a) >> shift_amount)
    if operation == "or":
        return u32(a | b)
    if operation == "and":
        return u32(a & b)

    raise ValueError(f"Unknown R-type operation: {operation}")


def execute_i_type(operation, a, immediate):
    """Independent Python model of each immediate ALU operation."""
    immediate_u32 = u32(immediate)

    if operation == "addi":
        return u32(a + immediate)
    if operation == "slti":
        return 1 if s32(a) < immediate else 0
    if operation == "sltiu":
        return 1 if u32(a) < immediate_u32 else 0
    if operation == "xori":
        return u32(a ^ immediate_u32)
    if operation == "ori":
        return u32(a | immediate_u32)
    if operation == "andi":
        return u32(a & immediate_u32)
    if operation == "slli":
        return u32(a << immediate)
    if operation == "srli":
        return u32(a) >> immediate
    if operation == "srai":
        return u32(s32(a) >> immediate)

    raise ValueError(f"Unknown I-type operation: {operation}")


def generate_program(seed, random_operation_count):
    """Generate one legal ALU program and calculate expected registers."""
    rng = random.Random(seed)
    registers = [0] * 32
    program = []

    # Initialize x1 through x8 with values that include positive and negative
    # 12-bit immediates. x0 deliberately remains zero.
    for rd in range(1, 9):
        immediate = rng.randint(-2048, 2047)
        program.append(addi(rd, 0, immediate))
        registers[rd] = u32(immediate)

    r_type_encoders = {
        "add": add,
        "sub": sub,
        "sll": sll,
        "slt": slt,
        "sltu": sltu,
        "xor": xor_,
        "srl": srl,
        "sra": sra,
        "or": or_,
        "and": and_,
    }

    i_type_encoders = {
        "addi": addi,
        "slti": slti,
        "sltiu": sltiu,
        "xori": xori,
        "ori": ori,
        "andi": andi,
    }

    shift_encoders = {
        "slli": slli,
        "srli": srli,
        "srai": srai,
    }

    all_operations = (
        list(r_type_encoders)
        + list(i_type_encoders)
        + list(shift_encoders)
    )

    for _ in range(random_operation_count):
        operation = rng.choice(all_operations)
        rd = rng.randrange(32)
        rs1 = rng.randrange(32)

        if operation in r_type_encoders:
            rs2 = rng.randrange(32)
            program.append(r_type_encoders[operation](rd, rs1, rs2))
            result = execute_r_type(
                operation,
                registers[rs1],
                registers[rs2],
            )

        elif operation in i_type_encoders:
            immediate = rng.randint(-2048, 2047)
            program.append(i_type_encoders[operation](rd, rs1, immediate))
            result = execute_i_type(
                operation,
                registers[rs1],
                immediate,
            )

        else:
            shift_amount = rng.randrange(32)
            program.append(shift_encoders[operation](rd, rs1, shift_amount))
            result = execute_i_type(
                operation,
                registers[rs1],
                shift_amount,
            )

        # Hardware ignores writes to x0.
        if rd != 0:
            registers[rd] = u32(result)

        registers[0] = 0

    # Infinite self-loop after all generated instructions.
    program.append(jal(0, 0))
    return program, registers


def write_hex(program):
    with HEX_FILE.open("w") as output_file:
        for instruction in program:
            output_file.write(f"{instruction:08x}\n")


def compile_testbench():
    command = [
        "iverilog",
        "-g2012",
        "-s", "tb_random_alu",
        "-o", str(SIM_FILE),
        "rtl/regfile.sv",
        "rtl/alu.sv",
        "rtl/imm_gen.sv",
        "rtl/control.sv",
        "rtl/instr_mem.sv",
        "rtl/data_mem.sv",
        "rtl/cpu_top.sv",
        "tb/tb_random_alu.sv",
    ]

    result = subprocess.run(
        command,
        cwd=PROJECT_ROOT,
        text=True,
        capture_output=True,
    )

    if result.returncode != 0:
        print(result.stdout)
        print(result.stderr, file=sys.stderr)
        raise RuntimeError("RTL compilation failed")


def run_rtl(cycles):
    command = [
        "vvp",
        str(SIM_FILE),
        "+HEX=rtl/random_alu_test.hex",
        f"+CYCLES={cycles}",
    ]

    result = subprocess.run(
        command,
        cwd=PROJECT_ROOT,
        text=True,
        capture_output=True,
    )

    if result.returncode != 0:
        print(result.stdout)
        print(result.stderr, file=sys.stderr)
        raise RuntimeError("RTL simulation failed")

    actual_registers = {}

    for line in result.stdout.splitlines():
        match = re.fullmatch(r"REG\s+(\d+)\s+([0-9a-fA-F]{8})", line.strip())

        if match:
            register_number = int(match.group(1))
            register_value = int(match.group(2), 16)
            actual_registers[register_number] = register_value

    if len(actual_registers) != 32:
        print(result.stdout)
        raise RuntimeError("Did not receive all 32 register values from RTL")

    return [actual_registers[index] for index in range(32)]


def main():
    parser = argparse.ArgumentParser(
        description="Randomized ALU-only differential test for the RISC-V CPU."
    )
    parser.add_argument(
        "--seed",
        type=int,
        default=1,
        help="First random seed to run. Default: 1",
    )
    parser.add_argument(
        "--tests",
        type=int,
        default=100,
        help="Number of random programs to test. Default: 100",
    )
    parser.add_argument(
        "--length",
        type=int,
        default=100,
        help="Random ALU instructions per program. Default: 100",
    )
    arguments = parser.parse_args()

    compile_testbench()

    for test_number in range(arguments.tests):
        seed = arguments.seed + test_number
        program, expected_registers = generate_program(
            seed,
            arguments.length,
        )

        write_hex(program)

        # Extra cycles ensure all instructions execute before registers print.
        actual_registers = run_rtl(len(program) + 5)

        if actual_registers != expected_registers:
            print(f"FAIL: randomized ALU test failed with seed {seed}")

            for index in range(32):
                if actual_registers[index] != expected_registers[index]:
                    print(
                        f"x{index}: expected 0x{expected_registers[index]:08x}, "
                        f"got 0x{actual_registers[index]:08x}"
                    )

            print(
                f"Reproduce with: "
                f"python3 tools/random_alu_test.py --seed {seed} --tests 1"
            )
            sys.exit(1)

        print(
            f"PASS: seed {seed} "
            f"({arguments.length} random ALU instructions)"
        )

    print(
        f"ALL RANDOMIZED ALU TESTS PASSED: "
        f"{arguments.tests} programs, "
        f"{arguments.tests * arguments.length} random instructions"
    )


if __name__ == "__main__":
    main()