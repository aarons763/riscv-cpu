module regfile (
    input  logic        clk,
    input  logic        we3,
    input  logic [ 4:0] a1,
    a2,
    a3,
    input  logic [31:0] wd3,
    output logic [31:0] rd1,
    rd2
);
  logic [31:0] regs[0:31];

  integer i;
  initial for (i = 0; i < 32; i = i + 1) regs[i] = 32'b0;

  // x0 is hardwired to 0
  assign rd1 = (a1 == 5'b0) ? 32'b0 : regs[a1];
  assign rd2 = (a2 == 5'b0) ? 32'b0 : regs[a2];

  always_ff @(posedge clk) begin
    if (we3 && a3 != 5'b0) regs[a3] <= wd3;
  end
endmodule
