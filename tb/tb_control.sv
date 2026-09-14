`timescale 1ns / 1ps

module tb_control;

  logic   [6:0] opcode;
  logic   [2:0] funct3;
  logic         funct7_5;

  logic         reg_write;
  logic         alu_src;
  logic         mem_write;
  logic         mem_read;
  logic   [1:0] result_src;
  logic         branch;
  logic         jump;
  logic         jalr;
  logic         lui;
  logic         auipc;
  logic   [3:0] alu_ctrl;

  integer       errors = 0;

  control dut (
      .opcode(opcode),
      .funct3(funct3),
      .funct7_5(funct7_5),
      .reg_write(reg_write),
      .alu_src(alu_src),
      .mem_write(mem_write),
      .mem_read(mem_read),
      .result_src(result_src),
      .branch(branch),
      .jump(jump),
      .jalr(jalr),
      .lui(lui),
      .auipc(auipc),
      .alu_ctrl(alu_ctrl)
  );

  task automatic check(input string name, input logic [6:0] in_opcode, input logic [2:0] in_funct3,
                       input logic in_funct7_5, input logic exp_reg_write, input logic exp_alu_src,
                       input logic exp_mem_write, input logic exp_mem_read,
                       input logic [1:0] exp_result_src, input logic exp_branch,
                       input logic exp_jump, input logic exp_jalr, input logic exp_lui,
                       input logic exp_auipc, input logic [3:0] exp_alu_ctrl);
    begin
      opcode   = in_opcode;
      funct3   = in_funct3;
      funct7_5 = in_funct7_5;
      #1;

      if ({reg_write, alu_src, mem_write, mem_read, result_src,
                 branch, jump, jalr, lui, auipc, alu_ctrl}
                !==
                {exp_reg_write, exp_alu_src, exp_mem_write, exp_mem_read,
                 exp_result_src, exp_branch, exp_jump, exp_jalr,
                 exp_lui, exp_auipc, exp_alu_ctrl}) begin

        errors = errors + 1;
        $display("FAIL %s", name);
      end else begin
        $display("PASS %s", name);
      end
    end
  endtask

  initial begin
    // R-type ADD
    check("R ADD", 7'b0110011, 3'b000, 1'b0, 1, 0, 0, 0, 2'b00, 0, 0, 0, 0, 0, 4'b0000);

    // R-type SUB
    check("R SUB", 7'b0110011, 3'b000, 1'b1, 1, 0, 0, 0, 2'b00, 0, 0, 0, 0, 0, 4'b0001);

    // R-type SRA
    check("R SRA", 7'b0110011, 3'b101, 1'b1, 1, 0, 0, 0, 2'b00, 0, 0, 0, 0, 0, 4'b0111);

    // I-type ORI
    check("I ORI", 7'b0010011, 3'b110, 1'b0, 1, 1, 0, 0, 2'b00, 0, 0, 0, 0, 0, 4'b0011);

    // I-type SRAI
    check("I SRAI", 7'b0010011, 3'b101, 1'b1, 1, 1, 0, 0, 2'b00, 0, 0, 0, 0, 0, 4'b0111);

    // LW
    check("LW", 7'b0000011, 3'b010, 1'b0, 1, 1, 0, 1, 2'b01, 0, 0, 0, 0, 0, 4'b0000);

    // SW
    check("SW", 7'b0100011, 3'b010, 1'b0, 0, 1, 1, 0, 2'b00, 0, 0, 0, 0, 0, 4'b0000);

    // BEQ
    check("BEQ", 7'b1100011, 3'b000, 1'b0, 0, 0, 0, 0, 2'b00, 1, 0, 0, 0, 0, 4'b0001);

    // BLT
    check("BLT", 7'b1100011, 3'b100, 1'b0, 0, 0, 0, 0, 2'b00, 1, 0, 0, 0, 0, 4'b1000);

    // JAL
    check("JAL", 7'b1101111, 3'b000, 1'b0, 1, 0, 0, 0, 2'b10, 0, 1, 0, 0, 0, 4'b0000);

    // JALR
    check("JALR", 7'b1100111, 3'b000, 1'b0, 1, 1, 0, 0, 2'b10, 0, 1, 1, 0, 0, 4'b0000);

    // LUI
    check("LUI", 7'b0110111, 3'b000, 1'b0, 1, 0, 0, 0, 2'b00, 0, 0, 0, 1, 0, 4'b0000);

    // AUIPC
    check("AUIPC", 7'b0010111, 3'b000, 1'b0, 1, 1, 0, 0, 2'b00, 0, 0, 0, 0, 1, 4'b0000);

    // Unsupported opcode must behave as a NOP.
    check("INVALID", 7'b1111111, 3'b000, 1'b0, 0, 0, 0, 0, 2'b00, 0, 0, 0, 0, 0, 4'b0000);

    if (errors == 0) begin
      $display("ALL CONTROL-DECODER TESTS PASSED");
      $finish;
    end else begin
      $fatal(1, "%0d CONTROL-DECODER TEST(S) FAILED", errors);
    end
  end

endmodule
