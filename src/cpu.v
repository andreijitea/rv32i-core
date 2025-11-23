module cpu (
    input wire clk,
    input wire rst
);

    // Internal signals
    wire [31:0] next_pc, pc, pc_plus_4, pc_branch;
    wire [31:0] instr;
    wire [31:0] rs1_data, rs2_data;
    wire [31:0] imm_ext;
    wire [31:0] alu_result, alu_a, alu_b;
    wire zero_flag;
    wire negative_flag;
    wire carry_flag;
    wire [31:0] mem_read_data;
    wire [31:0] result_wb;
    wire [2:0] data_mem_mode;

    // Control signals
    wire [1:0] pc_src_ctrl;
    wire [1:0] result_src_ctrl;
    wire mem_write_ctrl;
    wire [3:0] alu_ctrl;
    wire alu_b_ctrl;
    wire alu_a_ctrl;
    wire [2:0] imm_src_ctrl;
    wire reg_write_ctrl;

    // Controller instantiation
    controller ctrl_inst (
        .opcode(instr[6:0]),
        .funct3(instr[14:12]),
        .funct7(instr[31:25]),
        .zero(zero_flag),
        .negative(negative_flag),
        .carry(carry_flag),
        .pc_src(pc_src_ctrl),
        .result_src(result_src_ctrl),
        .mem_write(mem_write_ctrl),
        .alu_control(alu_ctrl),
        .alu_a_src(alu_a_ctrl),
        .alu_b_src(alu_b_ctrl),
        .imm_src(imm_src_ctrl),
        .reg_write(reg_write_ctrl),
        .data_mem_mode(data_mem_mode)
    );

    program_counter pc_inst (
        .clk(clk),
        .rst(rst),
        .next_pc(next_pc),
        .pc(pc)
    );

    instruction_memory im_inst (
        .addr(pc),
        .instruction(instr)
    );

    adder pc_adder (
        .a(pc),
        .b(32'd4),
        .sum(pc_plus_4)
    );

    register_file rf_inst (
        .clk(clk),
        .rst(rst),
        .rs1_addr(instr[19:15]),
        .rs2_addr(instr[24:20]),
        .rd_addr(instr[11:7]),
        .rd_data(result_wb),
        .rd_we(reg_write_ctrl),
        .rs1_data(rs1_data),
        .rs2_data(rs2_data)
    );

    extender ext_inst (
        .imm_in(instr),
        .imm_out(imm_ext),
        .imm_src(imm_src_ctrl)
    );

    adder branch_adder (
        .a(pc),
        .b(imm_ext),
        .sum(pc_branch)
    );

    mux4 pc_mux (
        .sel(pc_src_ctrl),
        .in0(pc_plus_4),
        .in1(pc_branch),
        .in2(alu_result),
        .in3(32'b0),
        .out(next_pc)
    );

    mux2 alu_b_mux (
        .sel(alu_b_ctrl),
        .in0(rs2_data),
        .in1(imm_ext),
        .out(alu_b)
    );

    mux2 alu_a_mux (
        .sel(alu_a_ctrl),
        .in0(rs1_data),
        .in1(pc),
        .out(alu_a)
    );

    alu alu_inst (
        .a(alu_a),
        .b(alu_b),
        .alu_control(alu_ctrl),
        .alu_result(alu_result),
        .zero(zero_flag),
        .negative(negative_flag),
        .carry(carry_flag)
    );

    data_memory dm_inst (
        .clk(clk),
        .rst(rst),
        .address(alu_result),
        .write_data(rs2_data),
        .read_data(mem_read_data),
        .we(mem_write_ctrl),
        .mode(data_mem_mode)
    );

    mux4 wb_mux (
        .sel(result_src_ctrl),
        .in0(alu_result),
        .in1(mem_read_data),
        .in2(pc_plus_4),
        .in3(imm_ext),
        .out(result_wb)
    );

endmodule