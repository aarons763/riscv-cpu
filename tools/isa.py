"""
Extended RV32I encoder - covers every instruction the single-cycle
core supports, so we can build a real coverage test program.
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
    imm &= 0x1FFF
    b12   = (imm >> 12) & 0x1
    b11   = (imm >> 11) & 0x1
    b10_5 = (imm >> 5) & 0x3F
    b4_1  = (imm >> 1) & 0xF
    return (b12 << 31) | (b10_5 << 25) | (rs2 << 20) | (rs1 << 15) | (funct3 << 12) | (b4_1 << 8) | (b11 << 7) | opcode

def u_type(imm20, rd, opcode):
    return ((imm20 & 0xFFFFF) << 12) | (rd << 7) | opcode

def j_type(imm, rd, opcode):
    imm &= 0x1FFFFF
    b20    = (imm >> 20) & 0x1
    b19_12 = (imm >> 12) & 0xFF
    b11    = (imm >> 11) & 0x1
    b10_1  = (imm >> 1) & 0x3FF
    return (b20 << 31) | (b10_1 << 21) | (b11 << 20) | (b19_12 << 12) | (rd << 7) | opcode

# ---- R-type ----
def add(rd, rs1, rs2):  return r_type(0,        rs2, rs1, 0b000, rd, 0b0110011)
def sub(rd, rs1, rs2):  return r_type(0b0100000,rs2, rs1, 0b000, rd, 0b0110011)
def sll(rd, rs1, rs2):  return r_type(0,        rs2, rs1, 0b001, rd, 0b0110011)
def slt(rd, rs1, rs2):  return r_type(0,        rs2, rs1, 0b010, rd, 0b0110011)
def sltu(rd, rs1, rs2): return r_type(0,        rs2, rs1, 0b011, rd, 0b0110011)
def xor_(rd, rs1, rs2): return r_type(0,        rs2, rs1, 0b100, rd, 0b0110011)
def srl(rd, rs1, rs2):  return r_type(0,        rs2, rs1, 0b101, rd, 0b0110011)
def sra(rd, rs1, rs2):  return r_type(0b0100000,rs2, rs1, 0b101, rd, 0b0110011)
def or_(rd, rs1, rs2):  return r_type(0,        rs2, rs1, 0b110, rd, 0b0110011)
def and_(rd, rs1, rs2): return r_type(0,        rs2, rs1, 0b111, rd, 0b0110011)

# ---- I-type ALU ----
def addi(rd, rs1, imm):  return i_type(imm, rs1, 0b000, rd, 0b0010011)
def slti(rd, rs1, imm):  return i_type(imm, rs1, 0b010, rd, 0b0010011)
def sltiu(rd, rs1, imm): return i_type(imm, rs1, 0b011, rd, 0b0010011)
def xori(rd, rs1, imm):  return i_type(imm, rs1, 0b100, rd, 0b0010011)
def ori(rd, rs1, imm):   return i_type(imm, rs1, 0b110, rd, 0b0010011)
def andi(rd, rs1, imm):  return i_type(imm, rs1, 0b111, rd, 0b0010011)
def slli(rd, rs1, shamt):return i_type(shamt, rs1, 0b001, rd, 0b0010011)
def srli(rd, rs1, shamt):return i_type(shamt, rs1, 0b101, rd, 0b0010011)
def srai(rd, rs1, shamt):return i_type((0b0100000<<5)|shamt, rs1, 0b101, rd, 0b0010011)

# ---- loads / stores ----
def lw(rd, imm, rs1):   return i_type(imm, rs1, 0b010, rd, 0b0000011)
def sw(rs2, imm, rs1):  return s_type(imm, rs2, rs1, 0b010, 0b0100011)

# ---- branches ----
def beq(rs1, rs2, imm):  return b_type(imm, rs2, rs1, 0b000, 0b1100011)
def bne(rs1, rs2, imm):  return b_type(imm, rs2, rs1, 0b001, 0b1100011)
def blt(rs1, rs2, imm):  return b_type(imm, rs2, rs1, 0b100, 0b1100011)
def bge(rs1, rs2, imm):  return b_type(imm, rs2, rs1, 0b101, 0b1100011)
def bltu(rs1, rs2, imm): return b_type(imm, rs2, rs1, 0b110, 0b1100011)
def bgeu(rs1, rs2, imm): return b_type(imm, rs2, rs1, 0b111, 0b1100011)

# ---- jumps ----
def jal(rd, imm):        return j_type(imm, rd, 0b1101111)
def jalr(rd, rs1, imm):  return i_type(imm, rs1, 0b000, rd, 0b1100111)

# ---- upper immediate ----
def lui(rd, imm):    return u_type(imm, rd, 0b0110111)
def auipc(rd, imm):  return u_type(imm, rd, 0b0010111)
