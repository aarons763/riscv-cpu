`timescale 1ns / 1ps

module tb_imm_gen;

  logic [31:0] instr;
  logic [31:0] imm_ext;

  integer errors = 0;

  imm_gen dut (
      .instr  (instr),
      .imm_ext(imm_ext)
  );

  task automatic check(input string name, input logic [31:0] input_instr,
                       input logic [31:0] expected_imm);
    begin
      instr = input_instr;
      #1;

      if (imm_ext !== expected_imm) begin
        errors = errors + 1;
        $display("FAIL %-14s instr=%h imm=%h expected=%h", name, instr, imm_ext, expected_imm);
      end else begin
        $display("PASS %-14s imm=%h", name, imm_ext);
      end
    end
  endtask

  initial begin
    // I-type: addi x1, x0, 0x123
    check("I positive", 32'h12300093, 32'h00000123);

    // I-type: addi x1, x0, -1
    check("I negative", 32'hfff00093, 32'hffffffff);

    // S-type: sw x2, -16(x1)
    check("S negative", 32'hfe20a823, 32'hfffffff0);

    // B-type: beq x1, x2, +16
    check("B positive", 32'h00208863, 32'h00000010);

    // B-type: bne x1, x2, -4
    check("B negative", 32'hfe209ee3, 32'hfffffffc);

    // U-type: lui x1, 0xabcde
    check("U lui", 32'habcde0b7, 32'habcde000);

    // U-type: auipc x1, 0x12345
    check("U auipc", 32'h12345097, 32'h12345000);

    // J-type: jal x1, +8
    check("J positive", 32'h008000ef, 32'h00000008);

    // J-type: jal x0, -4
    check("J negative", 32'hffdff06f, 32'hfffffffc);

    // Unsupported instruction: immediate should be zero.
    check("default", 32'h00000000, 32'h00000000);

    if (errors == 0) begin
      $display("ALL IMMEDIATE-GENERATOR TESTS PASSED");
      $finish;
    end else begin
      $fatal(1, "%0d IMMEDIATE-GENERATOR TEST(S) FAILED", errors);
    end
  end

endmodule
