module control (
    input logic [6:0] opcode,
    input logic [2:0] funct3,
    input logic       funct7_5, // instr[30]

    output logic       reg_write,
    output logic       alu_src,     // 0 = reg, 1 = imm
    output logic       mem_write,
    output logic       mem_read,
    output logic [1:0] result_src,  // 00=alu, 01=mem, 10=pc+4
    output logic       branch,
    output logic       jump,
    output logic       jalr,
    output logic       lui,
    output logic       auipc,
    output logic [3:0] alu_ctrl
);
  logic [1:0] alu_op;

  // ---- main decoder ----
  always_comb begin
    {reg_write, alu_src, mem_write, mem_read, result_src, branch, jump, jalr, lui,
        auipc, alu_op} = '0;

    case (opcode)
      7'b0110011: begin  // R-type
        reg_write = 1;
        alu_op = 2'b10;
      end
      7'b0010011: begin  // I-type ALU
        reg_write = 1;
        alu_src = 1;
        alu_op = 2'b11;
      end
      7'b0000011: begin  // load
        reg_write = 1;
        alu_src = 1;
        mem_read = 1;
        result_src = 2'b01;
      end
      7'b0100011: begin  // store
        alu_src   = 1;
        mem_write = 1;
      end
      7'b1100011: begin  // branch
        branch = 1;
        alu_op = 2'b01;
      end
      7'b1101111: begin  // jal
        reg_write = 1;
        jump = 1;
        result_src = 2'b10;
      end
      7'b1100111: begin  // jalr
        reg_write = 1;
        alu_src = 1;
        jump = 1;
        jalr = 1;
        result_src = 2'b10;
      end
      7'b0110111: begin  // lui
        reg_write = 1;
        lui = 1;
      end
      7'b0010111: begin  // auipc
        reg_write = 1;
        alu_src = 1;
        auipc = 1;
      end
      default: ;  // NOP / unsupported
    endcase
  end

  // ---- ALU control decoder ----
  always_comb begin
    case (alu_op)
      2'b00:   alu_ctrl = 4'b0000;  // loads/stores -> add
      2'b01: begin  // branches -> compare via subtract-family
        case (funct3)
          3'b000, 3'b001: alu_ctrl = 4'b0001;  // beq/bne -> sub, check zero
          3'b100, 3'b101: alu_ctrl = 4'b1000;  // blt/bge -> slt
          3'b110, 3'b111: alu_ctrl = 4'b1001;  // bltu/bgeu -> sltu
          default:        alu_ctrl = 4'b0001;
        endcase
      end
      2'b10: begin  // R-type
        case (funct3)
          3'b000:  alu_ctrl = funct7_5 ? 4'b0001 : 4'b0000;  // sub : add
          3'b111:  alu_ctrl = 4'b0010;  // and
          3'b110:  alu_ctrl = 4'b0011;  // or
          3'b100:  alu_ctrl = 4'b0100;  // xor
          3'b001:  alu_ctrl = 4'b0101;  // sll
          3'b101:  alu_ctrl = funct7_5 ? 4'b0111 : 4'b0110;  // sra : srl
          3'b010:  alu_ctrl = 4'b1000;  // slt
          3'b011:  alu_ctrl = 4'b1001;  // sltu
          default: alu_ctrl = 4'b0000;
        endcase
      end
      2'b11: begin  // I-type ALU (addi, andi, ori, ...)
        case (funct3)
          3'b000:  alu_ctrl = 4'b0000;  // addi
          3'b111:  alu_ctrl = 4'b0010;  // andi
          3'b110:  alu_ctrl = 4'b0011;  // ori
          3'b100:  alu_ctrl = 4'b0100;  // xori
          3'b001:  alu_ctrl = 4'b0101;  // slli
          3'b101:  alu_ctrl = funct7_5 ? 4'b0111 : 4'b0110;  // srai : srli
          3'b010:  alu_ctrl = 4'b1000;  // slti
          3'b011:  alu_ctrl = 4'b1001;  // sltiu
          default: alu_ctrl = 4'b0000;
        endcase
      end
      default: alu_ctrl = 4'b0000;
    endcase
  end
endmodule
