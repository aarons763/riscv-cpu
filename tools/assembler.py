"""
Two-pass mini-assembler with label support (branch/jump targets resolved
automatically instead of being hand-computed byte offsets).
"""
from isa import *

BRANCH_OPS = {'beq': beq, 'bne': bne, 'blt': blt, 'bge': bge, 'bltu': bltu, 'bgeu': bgeu}
JAL_OP = jal

class Assembler:
    def __init__(self):
        self.lines = []       # list of ('label', name) or ('instr', mnemonic, args)

    def label(self, name):
        self.lines.append(('label', name))

    def emit(self, mnemonic, *args):
        self.lines.append(('instr', mnemonic, args))

    def assemble(self):
        # pass 1: assign addresses
        addr = 0
        label_addr = {}
        addressed = []
        for line in self.lines:
            if line[0] == 'label':
                label_addr[line[1]] = addr
            else:
                addressed.append((addr, line))
                addr += 4

        # pass 2: encode
        program = []
        for addr, (_, mnemonic, args) in addressed:
            if mnemonic in BRANCH_OPS:
                rs1, rs2, target = args
                imm = label_addr[target] - addr
                program.append(BRANCH_OPS[mnemonic](rs1, rs2, imm))
            elif mnemonic == 'jal':
                rd, target = args
                imm = label_addr[target] - addr
                program.append(JAL_OP(rd, imm))
            else:
                fn = globals()[mnemonic]
                program.append(fn(*args))
        return program
