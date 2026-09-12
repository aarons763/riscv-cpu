module cpu_top (
    input  logic clk,
    input  logic rst
);
    logic [31:0] pc, pc_next, pc_plus4, pc_target;
    logic [31:0] instr;
    logic [31:0] rd1, rd2, imm_ext, wd3, alu_result_or_mem;
    logic [31:0] alu_a, alu_b, alu_result;
    logic [31:0] read_data;
    logic        zero, branch_taken;

    // control signals
    logic reg_write, alu_src, mem_write, mem_read, branch, jump, jalr, lui, auipc;
    logic [1:0] result_src;
    logic [3:0] alu_ctrl;

    // ---- PC register ----
    always_ff @(posedge clk or posedge rst)
        if (rst) pc <= 32'b0;
        else     pc <= pc_next;

    assign pc_plus4  = pc + 32'd4;
    assign pc_target = pc + imm_ext;

    // branch condition evaluation (uses ALU result computed via sub/slt above)
    always_comb begin
        case (instr[14:12]) // funct3
            3'b000: branch_taken = branch &&  zero;              // beq
            3'b001: branch_taken = branch && !zero;              // bne
            3'b100: branch_taken = branch &&  alu_result[0];     // blt
            3'b101: branch_taken = branch && !alu_result[0];     // bge
            3'b110: branch_taken = branch &&  alu_result[0];     // bltu
            3'b111: branch_taken = branch && !alu_result[0];     // bgeu
            default: branch_taken = 1'b0;
        endcase
    end

    assign pc_next = (branch_taken || jump) ?
                        (jalr ? {alu_result[31:1], 1'b0} : pc_target)
                        : pc_plus4;

    // ---- instruction memory ----
    instr_mem imem (.addr(pc), .instr(instr));

    // ---- control unit ----
    control ctrl (
        .opcode(instr[6:0]), .funct3(instr[14:12]), .funct7_5(instr[30]),
        .reg_write(reg_write), .alu_src(alu_src), .mem_write(mem_write),
        .mem_read(mem_read), .result_src(result_src), .branch(branch),
        .jump(jump), .jalr(jalr), .lui(lui), .auipc(auipc), .alu_ctrl(alu_ctrl)
    );

    // ---- register file ----
    regfile rf (
        .clk(clk), .we3(reg_write),
        .a1(instr[19:15]), .a2(instr[24:20]), .a3(instr[11:7]),
        .wd3(wd3), .rd1(rd1), .rd2(rd2)
    );

    // ---- immediate generator ----
    imm_gen immgen (.instr(instr), .imm_ext(imm_ext));

    // ---- ALU ----
    assign alu_a = auipc ? pc : rd1;
    assign alu_b = alu_src ? imm_ext : rd2;
    alu alu_inst (.a(alu_a), .b(alu_b), .alu_ctrl(alu_ctrl), .result(alu_result), .zero(zero));

    // ---- data memory ----
    data_mem dmem (
        .clk(clk), .mem_write(mem_write), .mem_read(mem_read),
        .addr(alu_result), .write_data(rd2), .read_data(read_data)
    );

    // ---- writeback mux ----
    always_comb begin
        case (result_src)
            2'b00:   wd3 = lui ? imm_ext : alu_result; // alu / lui
            2'b01:   wd3 = read_data;                  // load
            2'b10:   wd3 = pc_plus4;                   // jal/jalr link
            default: wd3 = alu_result;
        endcase
    end
endmodule
