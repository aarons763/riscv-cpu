`timescale 1ns / 1ps

module tb_coverage;
  logic clk = 0;
  logic rst;

  cpu_top dut (
      .clk(clk),
      .rst(rst)
  );

  always #5 clk = ~clk;

  integer errors = 0;

  task check(string name, logic [31:0] actual, logic [31:0] expected);
    if (actual !== expected) begin
      $display("FAIL %-8s got=%0d (0x%h) expected=%0d (0x%h)", name, actual, actual, expected,
               expected);
      errors = errors + 1;
    end else begin
      $display("PASS %-8s = %0d (0x%h)", name, actual, actual);
    end
  endtask

  initial begin
    rst = 1;
    repeat (2) @(posedge clk);
    rst = 0;

    repeat (60) @(posedge clk);  // enough cycles to run all 52 instructions

    $display("==== R-type ALU ====");
    check("x3(add)", dut.rf.regs[3], 32'd8);
    check("x4(sub)", dut.rf.regs[4], 32'd2);
    check("x5(and)", dut.rf.regs[5], 32'd1);
    check("x6(or)", dut.rf.regs[6], 32'd7);
    check("x7(xor)", dut.rf.regs[7], 32'd6);
    check("x8(sll)", dut.rf.regs[8], 32'd40);
    check("x9(srl)", dut.rf.regs[9], 32'd0);
    check("x10(sra)", dut.rf.regs[10], 32'hFFFFFFFF);
    check("x11(slt)", dut.rf.regs[11], 32'd1);
    check("x12(sltu)", dut.rf.regs[12], 32'd0);

    $display("==== I-type ALU ====");
    check("x14(addi)", dut.rf.regs[14], 32'd100);
    check("x15(andi)", dut.rf.regs[15], 32'd1);
    check("x16(ori)", dut.rf.regs[16], 32'd7);
    check("x17(xori)", dut.rf.regs[17], 32'd4);
    check("x18(slli)", dut.rf.regs[18], 32'd20);
    check("x19(srli)", dut.rf.regs[19], 32'd2);
    check("x20(srai)", dut.rf.regs[20], 32'hFFFFFFFF);
    check("x21(slti)", dut.rf.regs[21], 32'd1);
    check("x22(sltiu)", dut.rf.regs[22], 32'd1);

    $display("==== load/store ====");
    check("x23(lw)", dut.rf.regs[23], 32'd5);

    $display("==== lui ====");
    check("x24(lui)", dut.rf.regs[24], 32'h12345000);
    check("x25(auipc)", dut.rf.regs[25], 32'h00001064);

    $display("==== branches (x30 error-accumulator, expect 0) ====");
    check("x30(branch errs)", dut.rf.regs[30], 32'd0);

    $display("==== jal / jalr ====");
    check("x26(jal link)", dut.rf.regs[26], 32'd180);  // JAL instr addr + 4
    check("x27(jal landed)", dut.rf.regs[27], 32'd77);
    check("x29(jalr link)", dut.rf.regs[29], 32'd196);  // jalr instr addr + 4
    check("x31(jalr landed)", dut.rf.regs[31], 32'd55);

    $display("========================================");
    if (errors == 0) begin
      $display("ALL CHECKS PASSED");
      $finish;
    end else begin
      $fatal(1, "%0d CHECK(S) FAILED", errors);
    end

    $finish;
  end
endmodule
