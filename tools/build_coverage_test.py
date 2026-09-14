from assembler import Assembler
from isa import *

a = Assembler()

# ---------------- R-type ALU ----------------
a.emit('addi', 1, 0, 5)     # x1 = 5   (A)
a.emit('addi', 2, 0, 3)     # x2 = 3   (B)
a.emit('addi', 13, 0, -1)   # x13 = -1 (all ones, for shift-arithmetic test)

a.emit('add', 3, 1, 2)      # x3  = 5+3        = 8
a.emit('sub', 4, 1, 2)      # x4  = 5-3        = 2
a.emit('and_', 5, 1, 2)     # x5  = 5&3        = 1
a.emit('or_', 6, 1, 2)      # x6  = 5|3        = 7
a.emit('xor_', 7, 1, 2)     # x7  = 5^3        = 6
a.emit('sll', 8, 1, 2)      # x8  = 5<<3       = 40
a.emit('srl', 9, 1, 2)      # x9  = 5>>3       = 0
a.emit('sra', 10, 13, 2)    # x10 = -1>>>3     = -1 (0xFFFFFFFF)
a.emit('slt', 11, 2, 1)     # x11 = (3<5)      = 1
a.emit('sltu', 12, 1, 2)    # x12 = (5<3 u)    = 0

# ---------------- I-type ALU ----------------
a.emit('addi', 14, 0, 100)  # x14 = 100
a.emit('andi', 15, 1, 3)    # x15 = 5&3   = 1
a.emit('ori', 16, 1, 2)     # x16 = 5|2   = 7
a.emit('xori', 17, 1, 1)    # x17 = 5^1   = 4
a.emit('slli', 18, 1, 2)    # x18 = 5<<2  = 20
a.emit('srli', 19, 1, 1)    # x19 = 5>>1  = 2
a.emit('srai', 20, 13, 1)   # x20 = -1>>>1 = -1
a.emit('slti', 21, 2, 5)    # x21 = (3<5)  = 1
a.emit('sltiu', 22, 2, 5)   # x22 = (3<5 u)= 1

# ---------------- load/store ----------------
a.emit('sw', 1, 0, 0)       # mem[0] = x1 = 5
a.emit('lw', 23, 0, 0)      # x23 = mem[0] = 5

# ---------------- lui ----------------
a.emit('lui', 24, 0x12345)  # x24 = 0x12345000
a.emit('auipc', 25, 0x1)    # x25 = current PC + 0x00001000

# ---------------- branches: beq/bne (equal-value case) ----------------
a.emit('addi', 1, 0, 7)
a.emit('addi', 2, 0, 7)     # x1 == x2 == 7
a.emit('beq', 1, 2, 'BEQ_OK')
a.emit('ori', 30, 30, 1)    # FAIL bit 0: beq should have taken
a.label('BEQ_OK')
a.emit('bne', 1, 2, 'BNE_FAIL')
a.emit('jal', 0, 'BNE_OK')
a.label('BNE_FAIL')
a.emit('ori', 30, 30, 2)    # FAIL bit 1: bne should NOT have taken
a.label('BNE_OK')

# ---------------- branches: blt/bge/bltu/bgeu (signed vs unsigned) ----------------
a.emit('addi', 1, 0, -5)    # x1 = -5  (0xFFFFFFFB - huge as unsigned)
a.emit('addi', 2, 0, 5)     # x2 = 5

a.emit('blt', 1, 2, 'BLT_OK')     # signed: -5 < 5 -> true, should take
a.emit('ori', 30, 30, 4)          # FAIL bit 2
a.label('BLT_OK')

a.emit('bge', 2, 1, 'BGE_OK')     # signed: 5 >= -5 -> true, should take
a.emit('ori', 30, 30, 8)          # FAIL bit 3: reached only if branch wasn't taken
a.label('BGE_OK')

a.emit('bltu', 1, 2, 'BLTU_FAIL') # unsigned: 0xFFFFFFFB < 5 -> FALSE, should NOT take
a.emit('jal', 0, 'BLTU_OK')
a.label('BLTU_FAIL')
a.emit('ori', 30, 30, 16)         # FAIL bit 4
a.label('BLTU_OK')

a.emit('bgeu', 1, 2, 'BGEU_OK')   # unsigned: 0xFFFFFFFB >= 5 -> TRUE, should take
a.emit('ori', 30, 30, 32)         # FAIL bit 5
a.label('BGEU_OK')

# ---------------- jal / jalr ----------------
a.emit('jal', 26, 'JAL_TARGET')   # x26 = return addr (pc+4)
a.emit('ori', 30, 30, 64)         # FAIL bit 6: should have jumped over this
a.label('JAL_TARGET')
a.emit('addi', 27, 0, 77)         # x27 = 77, proves jal landed here

a.emit('addi', 28, 0, 0)          # placeholder, patched below
a.emit('jalr', 29, 28, 0)         # x29 = return addr; jump to addr in x28
a.emit('ori', 30, 30, 128)        # FAIL bit 7: should have jumped over this
a.label('JALR_TARGET')
a.emit('addi', 31, 0, 55)         # x31 = 55, proves jalr landed here

a.label('HALT')
a.emit('jal', 0, 'HALT')          # infinite self-loop

program = a.assemble()

# patch the jalr target address (x28 = addr of JALR_TARGET) now that we know it
addr = 0
label_addr = {}
for line in a.lines:
    if line[0] == 'label':
        label_addr[line[1]] = addr
    else:
        addr += 4

jalr_target_addr = label_addr['JALR_TARGET']

# print exact addresses of the jal and jalr instructions themselves for testbench expected-value checks
addr = 0
for line in a.lines:
    if line[0] == 'label':
        continue
    if line[1] == 'jal' and line[2][1] == 'JAL_TARGET':
        print(f"jal instr addr = {addr}, expected link (pc+4) = {addr+4}")
    if line[1] == 'jalr':
        print(f"jalr instr addr = {addr}, expected link (pc+4) = {addr+4}")
    addr += 4
# find index of the placeholder 'addi x28, x0, 0' instruction and patch its immediate
idx = 0
addr = 0
for line in a.lines:
    if line[0] == 'label':
        continue
    if line[1] == 'addi' and line[2] == (28, 0, 0):
        program[idx] = addi(28, 0, jalr_target_addr)
    idx += 1

with open('../rtl/coverage_test.hex', 'w') as f:
    for instr in program:
        f.write(f"{instr:08x}\n")

print(f"Wrote program.hex with {len(program)} instructions")
print(f"JALR_TARGET address = {jalr_target_addr}")
print(f"JAL_TARGET address  = {label_addr['JAL_TARGET']}")
