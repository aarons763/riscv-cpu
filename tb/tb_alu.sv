`timescale 1ns / 1ps

module tb_alu;

  logic   [31:0] a;
  logic   [31:0] b;
  logic   [ 3:0] alu_ctrl;
  logic   [31:0] result;
  logic          zero;

  integer        errors = 0;

  alu dut (
      .a(a),
      .b(b),
      .alu_ctrl(alu_ctrl),
      .result(result),
      .zero(zero)
  );

  task automatic check(input string name, input logic [31:0] input_a, input logic [31:0] input_b,
                       input logic [3:0] operation, input logic [31:0] expected_result,
                       input logic expected_zero);
    begin
      a        = input_a;
      b        = input_b;
      alu_ctrl = operation;

      #1;

      if (result !== expected_result || zero !== expected_zero) begin
        errors = errors + 1;
        $display("FAIL %-12s a=%h b=%h result=%h expected=%h zero=%b expected_zero=%b", name, a, b,
                 result, expected_result, zero, expected_zero);
      end else begin
        $display("PASS %-12s result=%h", name, result);
      end
    end
  endtask

  initial begin
    // alu_ctrl values come from rtl/alu.sv.

    check("add", 32'd5, 32'd3, 4'b0000, 32'd8, 1'b0);
    check("add_wrap", 32'h7fffffff, 32'd1, 4'b0000, 32'h80000000, 1'b0);

    check("sub", 32'd5, 32'd3, 4'b0001, 32'd2, 1'b0);
    check("sub_zero", 32'd5, 32'd5, 4'b0001, 32'd0, 1'b1);

    check("and", 32'hf0f0, 32'h0ff0, 4'b0010, 32'h00f0, 1'b0);
    check("or", 32'hf0f0, 32'h0ff0, 4'b0011, 32'hfff0, 1'b0);
    check("xor", 32'hf0f0, 32'h0ff0, 4'b0100, 32'hff00, 1'b0);

    check("sll_31", 32'd1, 32'd31, 4'b0101, 32'h80000000, 1'b0);
    check("srl_31", 32'h80000000, 32'd31, 4'b0110, 32'd1, 1'b0);
    check("sra_31", 32'h80000000, 32'd31, 4'b0111, 32'hffffffff, 1'b0);

    check("slt_true", 32'hffffffff, 32'd1, 4'b1000, 32'd1, 1'b0);
    check("slt_false", 32'd1, 32'hffffffff, 4'b1000, 32'd0, 1'b1);

    check("sltu_false", 32'hffffffff, 32'd1, 4'b1001, 32'd0, 1'b1);
    check("sltu_true", 32'd1, 32'hffffffff, 4'b1001, 32'd1, 1'b0);

    if (errors == 0) begin
      $display("ALL ALU TESTS PASSED");
      $finish;
    end else begin
      $fatal(1, "%0d ALU TEST(S) FAILED", errors);
    end
  end

endmodule
