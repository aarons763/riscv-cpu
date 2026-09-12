"""
Tiny RV32I encoder used to hand-build a first smoke-test program
without needing the full GNU toolchain. This is NOT a general assembler,
just enough to build the smoke_test program below.
"""

def r_type(funct7, rs2, rs1, funct3, rd, opcode):
    return (funct7 << 25) | (rs2 << 20) | (rs1 << 15) | (funct3 << 12) | (rd << 7) | opcode

def i_type(imm, rs1, funct3, rd, opcode):
    imm &= 0xFFF
    return (imm << 20) | (rs1 << 15) | (funct3 << 12) | (rd << 7) | opcode

def s_type(imm, rs2, rs1, funct3, opcode):
    imm &= 0xFFF
    imm_11_5 = (imm >> 5) & 0x7F
    imm_4_0 = imm & 0x1F
    return (imm_11_5 << 25) | (rs2 << 20) | (rs1 << 15) | (funct3 << 12) | (imm_4_0 << 7) | opcode

def b_type(imm, rs2, rs1, funct3, opcode):
    # imm is byte offset, must be even
    imm &= 0x1FFF
    b12   = (imm >> 12) & 0x1
    b11   = (imm >> 11) & 0x1
    b10_5 = (imm >> 5) & 0x3F
    b4_1  = (imm >> 1) & 0xF
    return (b12 << 31) | (b10_5 << 25) | (rs2 << 20) | (rs1 << 15) | (funct3 << 12) | (b4_1 << 8) | (b11 << 7) | opcode

def j_type(imm, rd, opcode):
    imm &= 0x1FFFFF
    b20    = (imm >> 20) & 0x1
    b19_12 = (imm >> 12) & 0xFF
    b11    = (imm >> 11) & 0x1
    b10_1  = (imm >> 1) & 0x3FF
    return (b20 << 31) | (b10_1 << 21) | (b11 << 20) | (b19_12 << 12) | (rd << 7) | opcode

def addi(rd, rs1, imm): return i_type(imm, rs1, 0b000, rd, 0b0010011)
def add(rd, rs1, rs2):  return r_type(0, rs2, rs1, 0b000, rd, 0b0110011)
def sub(rd, rs1, rs2):  return r_type(0b0100000, rs2, rs1, 0b000, rd, 0b0110011)
def sw(rs2, imm, rs1):  return s_type(imm, rs2, rs1, 0b010, 0b0100011)
def lw(rd, imm, rs1):   return i_type(imm, rs1, 0b010, rd, 0b0000011)
def beq(rs1, rs2, imm): return b_type(imm, rs2, rs1, 0b000, 0b1100011)
def jal(rd, imm):       return j_type(imm, rd, 0b1101111)

program = [
    addi(5, 0, 5),        # 0:  x5  = 5
    addi(6, 0, 10),       # 4:  x6  = 10
    add(7, 5, 6),         # 8:  x7  = x5 + x6 = 15
    sub(8, 6, 5),         # 12: x8  = x6 - x5 = 5
    sw(7, 0, 0),          # 16: mem[0] = x7 (15)
    lw(9, 0, 0),          # 20: x9 = mem[0] = 15
    beq(7, 9, 8),         # 24: if x7==x9, skip next instr (branch to 32)
    addi(10, 0, 999),     # 28: SKIPPED if branch taken
    addi(11, 0, 111),     # 32: x11 = 111  <-- branch target, proves branch worked
    jal(0, 0),            # 36: infinite loop (halt) - jal x0, self
]

with open("../rtl/smoke_test.hex", "w") as f:
    for instr in program:
        f.write(f"{instr:08x}\n")

print("Wrote program.hex with", len(program), "instructions")
for i, instr in enumerate(program):
    print(f"{i*4:3d}: {instr:08x}")
