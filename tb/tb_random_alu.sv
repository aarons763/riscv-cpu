`timescale 1ns / 1ps

module tb_random_alu;

  logic   clk = 0;
  logic   rst;
  integer cycles;
  integer i;

  cpu_top dut (
      .clk(clk),
      .rst(rst)
  );

  always #5 clk = ~clk;

  initial begin
    if (!$value$plusargs("CYCLES=%d", cycles)) cycles = 100;

    rst = 1;
    repeat (2) @(posedge clk);
    rst = 0;

    repeat (cycles) @(posedge clk);

    for (i = 0; i < 32; i = i + 1) $display("REG %0d %08h", i, dut.rf.regs[i]);

    $finish;
  end

endmodule
