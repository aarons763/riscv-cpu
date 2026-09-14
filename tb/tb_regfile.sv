`timescale 1ns / 1ps

module tb_regfile;

  logic          clk = 0;
  logic          we3;
  logic   [ 4:0] a1;
  logic   [ 4:0] a2;
  logic   [ 4:0] a3;
  logic   [31:0] wd3;
  logic   [31:0] rd1;
  logic   [31:0] rd2;

  integer        errors = 0;

  regfile dut (
      .clk(clk),
      .we3(we3),
      .a1 (a1),
      .a2 (a2),
      .a3 (a3),
      .wd3(wd3),
      .rd1(rd1),
      .rd2(rd2)
  );

  always #5 clk = ~clk;

  task automatic check(input string name, input logic [31:0] actual, input logic [31:0] expected);
    begin
      if (actual !== expected) begin
        errors = errors + 1;
        $display("FAIL %-18s got=%h expected=%h", name, actual, expected);
      end else begin
        $display("PASS %-18s value=%h", name, actual);
      end
    end
  endtask

  initial begin
    // Start with writes disabled and read x0.
    we3 = 0;
    a1  = 0;
    a2  = 0;
    a3  = 0;
    wd3 = 0;
    #1;

    check("x0 starts at zero", rd1, 32'd0);

    // Write x5 = 0xDEADBEEF.
    a3  = 5;
    wd3 = 32'hDEADBEEF;
    we3 = 1;
    @(posedge clk);
    #1;
    we3 = 0;

    // Read x5 through port 1 and x0 through port 2.
    a1  = 5;
    a2  = 0;
    #1;
    check("read x5", rd1, 32'hDEADBEEF);
    check("read x0", rd2, 32'd0);

    // Write x7 = 0x12345678.
    a3  = 7;
    wd3 = 32'h12345678;
    we3 = 1;
    @(posedge clk);
    #1;
    we3 = 0;

    // Verify both independent read ports.
    a1  = 5;
    a2  = 7;
    #1;
    check("read-port 1 x5", rd1, 32'hDEADBEEF);
    check("read-port 2 x7", rd2, 32'h12345678);

    // Attempt to overwrite x0. RISC-V requires x0 to remain zero.
    a3  = 0;
    wd3 = 32'hFFFFFFFF;
    we3 = 1;
    @(posedge clk);
    #1;
    we3 = 0;

    a1  = 0;
    a2  = 0;
    #1;
    check("x0 ignores writes p1", rd1, 32'd0);
    check("x0 ignores writes p2", rd2, 32'd0);

    // Update x5, proving later writes replace earlier values.
    a3  = 5;
    wd3 = 32'hCAFEBABE;
    we3 = 1;
    @(posedge clk);
    #1;
    we3 = 0;

    a1  = 5;
    #1;
    check("x5 overwrite", rd1, 32'hCAFEBABE);

    if (errors == 0) begin
      $display("ALL REGISTER-FILE TESTS PASSED");
      $finish;
    end else begin
      $fatal(1, "%0d REGISTER-FILE TEST(S) FAILED", errors);
    end
  end

endmodule
