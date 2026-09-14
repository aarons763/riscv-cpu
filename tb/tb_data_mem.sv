`timescale 1ns / 1ps

module tb_data_mem;

  logic          clk = 0;
  logic          mem_write;
  logic          mem_read;
  logic   [31:0] addr;
  logic   [31:0] write_data;
  logic   [31:0] read_data;

  integer        errors = 0;

  data_mem dut (
      .clk(clk),
      .mem_write(mem_write),
      .mem_read(mem_read),
      .addr(addr),
      .write_data(write_data),
      .read_data(read_data)
  );

  always #5 clk = ~clk;

  task automatic check(input string name, input logic [31:0] actual, input logic [31:0] expected);
    begin
      if (actual !== expected) begin
        errors = errors + 1;
        $display("FAIL %-20s got=%h expected=%h", name, actual, expected);
      end else begin
        $display("PASS %-20s value=%h", name, actual);
      end
    end
  endtask

  initial begin
    mem_write  = 0;
    mem_read   = 0;
    addr       = 0;
    write_data = 0;
    #1;

    // When reading is disabled, read_data must be zero.
    check("read disabled", read_data, 32'd0);

    // Write one aligned 32-bit word to address 0.
    addr       = 32'd0;
    write_data = 32'hDEADBEEF;
    mem_write  = 1;
    @(posedge clk);
    #1;
    mem_write = 0;

    // Read that same word.
    mem_read  = 1;
    #1;
    check("read address 0", read_data, 32'hDEADBEEF);

    // Write another word at byte address 12, which is word index 3.
    addr       = 32'd12;
    write_data = 32'h12345678;
    mem_write  = 1;
    @(posedge clk);
    #1;
    mem_write = 0;

    // Read the second location.
    mem_read  = 1;
    #1;
    check("read address 12", read_data, 32'h12345678);

    // Confirm address 0 retained its original value.
    addr = 32'd0;
    #1;
    check("address 0 retained", read_data, 32'hDEADBEEF);

    // A clock edge with mem_write = 0 must not alter memory.
    addr       = 32'd0;
    write_data = 32'hFFFFFFFF;
    mem_write  = 0;
    @(posedge clk);
    #1;
    mem_read = 1;
    check("write disabled", read_data, 32'hDEADBEEF);

    // Read output must return to zero when mem_read is disabled.
    mem_read = 0;
    #1;
    check("read disabled again", read_data, 32'd0);

    if (errors == 0) begin
      $display("ALL DATA-MEMORY TESTS PASSED");
      $finish;
    end else begin
      $fatal(1, "%0d DATA-MEMORY TEST(S) FAILED", errors);
    end
  end

endmodule
