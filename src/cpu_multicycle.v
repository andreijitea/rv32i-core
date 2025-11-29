module cpu_multicycle (
    input wire clk,
    input wire rst,

    // ROM interface
    output wire [31:0] o_rom_addr,
    input wire [31:0] i_rom_data,

    // RAM interface
    output wire [31:0] o_ram_addr,
    output wire [31:0] o_ram_wdata,
    input wire [31:0] i_ram_rdata,
    output wire o_ram_we,
    output wire [2:0] o_ram_mode
);

    // Internal signals
    reg  [31:0] w_pc;
    wire [31:0] w_next_pc;
    wire [31:0] w_pc_plus_4;
    wire [31:0] w_instr;

    wire [31:0] w_rs1_data;
    wire [31:0] w_rs2_data;
    wire [31:0] w_reg_wdata;

    wire [31:0] w_imm_ext;
    wire [2:0]  w_imm_sel;

    wire [31:0] w_pc_branch;
    wire [31:0] w_alu_a;
    wire [31:0] w_alu_b;
    wire [31:0] w_alu_result;
    wire [3:0]  w_alu_ctrl;
    wire w_zero_flag, w_neg_flag, w_carry_flag;

    wire [31:0] w_mdr_out;

    wire [31:0] w_regA;
    wire [31:0] w_regB;
    wire [31:0] w_ALUOut;
    wire [31:0] w_imm_out; 
    wire [31:0] w_pc_jump;

    // control signals from Controller
    wire [1:0]  w_pc_sel;
    wire [1:0]  w_wb_sel;
    wire        w_alu_a_sel;
    wire        w_alu_b_sel;
    wire [3:0]  w_ctrl_alu;
    wire [2:0]  w_ctrl_imm;
    wire        w_ctrl_reg_we;
    wire        w_ctrl_ir_we;
    wire        w_ctrl_mdr_we;
    wire        w_ctrl_ram_we;
    wire [2:0]  w_ctrl_ram_mode;
    wire w_pc_we;
    wire w_decode_we;
    wire w_execute_we;

    // PC instantiation
    program_counter pc_inst (
        .clk(clk),
        .rst(rst),
        .next_pc(w_next_pc),
        .pc(w_pc),
        .pc_we(w_pc_we)
    );

    // PC Adder instantiation
    adder pc_adder_inst (
        .a(w_pc),
        .b(32'd4),
        .sum(w_pc_plus_4)
    );

    // IR instantiation
    instruction_reg ir_inst (
        .clk(clk),
        .rst(rst),
        .instr_in(i_rom_data),
        .instr_out(w_instr),
        .load(w_ctrl_ir_we)
    );

    // Register File instantiation
    register_file regfile_inst (
        .clk(clk),
        .rst(rst),
        .rs1_addr(w_instr[19:15]),
        .rs2_addr(w_instr[24:20]),
        .rd_addr(w_instr[11:7]),
        .rd_data(w_reg_wdata),
        .rd_we(w_ctrl_reg_we),
        .rs1_data(w_rs1_data),
        .rs2_data(w_rs2_data)
    );

    // Immediate Extender instantiation
    extender imm_ext_inst (
        .imm_in(w_instr),
        .imm_out(w_imm_ext),
        .imm_src(w_ctrl_imm)
    );

    // Branch Adder instantiation
    adder branch_adder_inst (
        .a(w_pc),
        .b(w_imm_out),
        .sum(w_pc_branch)
    );

    // PC Mux instantiation
    mux4 pc_mux_inst (
        .sel(w_pc_sel),
        .in0(w_pc_plus_4),
        .in1(w_pc_branch),
        .in2(w_ALUOut),
        .in3(32'b0),
        .out(w_next_pc)
    );

    // AlU A Mux instantiation
    mux2 alu_a_mux_inst (
        .sel(w_alu_a_sel),
        .in0(w_regA),
        .in1(w_pc),
        .out(w_alu_a)
    );

    // AlU B Mux instantiation
    mux2 alu_b_mux_inst (
        .sel(w_alu_b_sel),
        .in0(w_regB),
        .in1(w_imm_out),
        .out(w_alu_b)
    );

    // ALU instantiation
    alu alu_inst (
        .a(w_alu_a),
        .b(w_alu_b),
        .alu_control(w_ctrl_alu),
        .alu_result(w_alu_result),
        .zero(w_zero_flag),
        .negative(w_neg_flag),
        .carry(w_carry_flag)
    );

    // MDR instantiation
    data_reg mdr_inst (
        .clk(clk),
        .rst(rst),
        .we(w_ctrl_mdr_we),
        .data_in(i_ram_rdata),
        .data_out(w_mdr_out)
    );

    // Write Back Mux instantiation
    mux4 wb_mux_inst (
        .sel(w_wb_sel),
        .in0(w_ALUOut),
        .in1(w_mdr_out),
        .in2(w_pc_jump),
        .in3(w_imm_out),
        .out(w_reg_wdata)
    );

    // Datapath registers
    // Used to latch values between cycles
    reg32b reg_imm_out (
        .clk(clk),
        .rst(rst),
        .we(w_decode_we),
        .data_in(w_imm_ext),
        .data_out(w_imm_out)
    );

    reg32b reg_a (
        .clk(clk),
        .rst(rst),
        .we(w_decode_we),
        .data_in(w_rs1_data),
        .data_out(w_regA)
    );

    reg32b reg_b (
        .clk(clk),
        .rst(rst),
        .we(w_decode_we),
        .data_in(w_rs2_data),
        .data_out(w_regB)
    );

    reg32b reg_aluout (
        .clk(clk),
        .rst(rst),
        .we(w_execute_we),
        .data_in(w_alu_result),
        .data_out(w_ALUOut)
    );

    reg32b reg_pc_wb_jump (
        .clk(clk),
        .rst(rst),
        .we(w_execute_we),
        .data_in(w_pc_plus_4),
        .data_out(w_pc_jump)
    );

    // Controller instantiation
    controller_multicycle ctrl_inst (
        .clk(clk),
        .rst(rst),
        .i_opcode(w_instr[6:0]),
        .i_funct3(w_instr[14:12]),
        .i_funct7(w_instr[31:25]),
        .i_zero(w_zero_flag),
        .i_neg(w_neg_flag),
        .i_carry(w_carry_flag),

        .o_pc_sel(w_pc_sel),
        .o_result_sel(w_wb_sel),
        .o_alu_a_sel(w_alu_a_sel),
        .o_alu_b_sel(w_alu_b_sel),

        .o_alu_ctrl(w_ctrl_alu),
        .o_imm_ctrl(w_ctrl_imm),

        .o_reg_we(w_ctrl_reg_we),

        .o_mdr_we(w_ctrl_mdr_we),

        .o_ram_we(w_ctrl_ram_we),
        .o_ram_mode(w_ctrl_ram_mode),

        .o_ir_we(w_ctrl_ir_we),
        .o_pc_we(w_pc_we),

        .o_decode_we(w_decode_we),
        .o_execute_we(w_execute_we)
    );

    // outputs to memory
    assign o_rom_addr  = w_pc;
    assign o_ram_addr  = w_ALUOut;
    assign o_ram_wdata = w_regB;
    assign o_ram_we    = w_ctrl_ram_we;
    assign o_ram_mode  = w_ctrl_ram_mode;

endmodule