`timescale 1ns / 1ps

module tb_cpu;
  logic clk = 0;
  logic rst;

  cpu_top dut (
      .clk(clk),
      .rst(rst)
  );

  always #5 clk = ~clk;  // 100 MHz virtual clock

  initial begin
    $dumpfile("wave.vcd");
    $dumpvars(0, tb_cpu);

    rst = 1;
    repeat (2) @(posedge clk);
    rst = 0;

    repeat (15) @(posedge clk);

    // Check final register values against expected results
    $display("---- Register check ----");
    $display("x5  = %0d (expect 5)", dut.rf.regs[5]);
    $display("x6  = %0d (expect 10)", dut.rf.regs[6]);
    $display("x7  = %0d (expect 15)", dut.rf.regs[7]);
    $display("x8  = %0d (expect 5)", dut.rf.regs[8]);
    $display("x9  = %0d (expect 15)", dut.rf.regs[9]);
    $display("x10 = %0d (expect 0, branch should skip this)", dut.rf.regs[10]);
    $display("x11 = %0d (expect 111, proves branch worked)", dut.rf.regs[11]);

    if (dut.rf.regs[5] == 5 && dut.rf.regs[6] == 10 && dut.rf.regs[7] == 15 &&
            dut.rf.regs[8] == 5 && dut.rf.regs[9] == 15 && dut.rf.regs[10] == 0 &&
            dut.rf.regs[11] == 111)
      $display("PASS: all checks correct");
    else $display("FAIL: mismatch above");

    $finish;
  end
endmodule
