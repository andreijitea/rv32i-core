`include "defines.vh"

module controller_multicycle (
    input  wire        clk,
    input  wire        rst,

    // Decoded instruction fields (from latched IR)
    input  wire [6:0]  i_opcode,
    input  wire [2:0]  i_funct3,
    input  wire [6:0]  i_funct7,

    // ALU status flags (from ALU compare)
    input  wire        i_zero,
    input  wire        i_neg,
    input  wire        i_carry,

    // Mux select signals (outputs)
    output reg  [1:0]  o_pc_sel,
    output reg  [1:0]  o_result_sel, // 00 = ALU, 01 = MEM, 10 = PC+4, 11 = LUI
    output reg         o_alu_a_sel,
    output reg         o_alu_b_sel,

    // ALU and Immediate Extender control signals
    output reg  [3:0]  o_alu_ctrl,
    output reg  [2:0]  o_imm_ctrl,

    // Register File control signals
    output reg         o_reg_we,

    // MDR control signals (capture memory read)
    output reg         o_mdr_we,

    // RAM control signals
    output reg         o_ram_we,
    output reg  [2:0]  o_ram_mode,

    // IR control signals
    output reg         o_ir_we,

    // PC write enable
    output reg         o_pc_we,

    // Decode latch control signal
    output reg o_decode_we,

    // Execute latch control signal
    output reg o_execute_we
);

    // Opcode definitions
    localparam OP_R_TYPE   = 7'b0110011;  // R-type
    localparam OP_I_TYPE   = 7'b0010011;  // I-type
    localparam OP_LOAD     = 7'b0000011;  // Load instructions
    localparam OP_STORE    = 7'b0100011;  // Store instructions
    localparam OP_BRANCH   = 7'b1100011;  // Branch instructions
    localparam OP_JAL      = 7'b1101111;  // JAL
    localparam OP_JALR     = 7'b1100111;  // JALR
    localparam OP_LUI      = 7'b0110111;  // LUI
    localparam OP_AUIPC    = 7'b0010111;  // AUIPC

    // Multicycle states
    localparam FETCH    = 3'b000;
    localparam FETCH2  = 3'b101; // for synchronous IMEM
    localparam DECODE   = 3'b001;
    localparam EXECUTE  = 3'b010;
    localparam MEMORY   = 3'b011;
    localparam MEMORY2  = 3'b110; // for synchronous DMEM (needed for loads)
    localparam WRITEBACK= 3'b100;

    reg [2:0] state, next_state;

    reg branch_taken;
    reg [2:0] debug_branch;

    // Sequential state register
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= FETCH;
        end
        else
            state <= next_state;
    end

    // Combinational next state and output logic
    always @(*) begin
        // Defaults (safe defaults)
        o_ir_we    = 1'b0;
        o_reg_we   = 1'b0;
        o_mdr_we   = 1'b0;
        o_ram_we   = 1'b0;

        o_pc_sel   = 2'b00;
        o_result_sel = 2'b00; 
        o_alu_a_sel = 1'b0;
        o_alu_b_sel = 1'b0;
        o_alu_ctrl  = `ALU_ADD;
        o_imm_ctrl  = `IMM_I_TYPE;
        o_ram_mode  = `DM_LW;

        o_pc_we     = 1'b0;
        o_decode_we = 1'b0;
        o_execute_we= 1'b0;

        branch_taken = 1'b0;
        debug_branch = 3'b000;

        next_state = FETCH; // default next state

        case (state)
            //------------------------------------------------------------------
            FETCH: begin
                // For synchronous IMEM we just set up for next cycle
                o_pc_sel = 2'b00; // PC + 4
            
                next_state = FETCH2;
            end

            FETCH2: begin
                // Synchronous IMEM: capture instruction into IR
                o_ir_we  = 1'b1;
                o_pc_sel = 2'b00; // PC + 4

                next_state = DECODE;
            end

            //------------------------------------------------------------------
            DECODE: begin
                // Latch instruction fields into decode cycle
                o_decode_we = 1'b1;

                case (i_opcode)
                    OP_R_TYPE:  o_imm_ctrl = `IMM_R_TYPE;
                    OP_I_TYPE:  o_imm_ctrl = `IMM_I_TYPE;
                    OP_LOAD:    o_imm_ctrl = `IMM_I_TYPE;
                    OP_STORE:   o_imm_ctrl = `IMM_S_TYPE;
                    OP_BRANCH:  o_imm_ctrl = `IMM_B_TYPE;
                    OP_JAL:     o_imm_ctrl = `IMM_J_TYPE;
                    OP_JALR:    o_imm_ctrl = `IMM_I_TYPE;
                    OP_LUI,
                    OP_AUIPC:   o_imm_ctrl = `IMM_U_TYPE;
                    default:    o_imm_ctrl = `IMM_I_TYPE;
                endcase

                next_state = EXECUTE;
            end

            //------------------------------------------------------------------
            EXECUTE: begin
                // Latch ALU outputs into EXECUTE stage
                o_execute_we = 1'b1;

                case (i_opcode)
                    // -------- R-type: ALU operation -> then WRITEBACK
                    OP_R_TYPE: begin
                        o_alu_b_sel = 1'b0; // rs2
                        o_alu_a_sel = 1'b0; // rs1
                        o_pc_we = 1'b1;     // update PC
                        o_pc_sel = 2'b00;   // PC + 4
                        
                        case ({i_funct7, i_funct3})
                            10'b0000000_000: o_alu_ctrl = `ALU_ADD;
                            10'b0100000_000: o_alu_ctrl = `ALU_SUB;
                            10'b0000000_001: o_alu_ctrl = `ALU_SLL;
                            10'b0000000_010: o_alu_ctrl = `ALU_SLT;
                            10'b0000000_011: o_alu_ctrl = `ALU_SLTU;
                            10'b0000000_100: o_alu_ctrl = `ALU_XOR;
                            10'b0000000_101: o_alu_ctrl = `ALU_SRL;
                            10'b0100000_101: o_alu_ctrl = `ALU_SRA;
                            10'b0000000_110: o_alu_ctrl = `ALU_OR;
                            10'b0000000_111: o_alu_ctrl = `ALU_AND;
                            default:         o_alu_ctrl = `ALU_ADD;
                        endcase

                        next_state = WRITEBACK;
                    end

                    // -------- I-type ALU immediate (ADDI, ANDI, etc.)
                    OP_I_TYPE: begin
                        o_alu_b_sel = 1'b1; // immediate
                        o_alu_a_sel = 1'b0; // rs1
                        o_pc_we = 1'b1;     // update PC
                        o_pc_sel = 2'b00;   // PC + 4

                        case (i_funct3)
                            3'b000: o_alu_ctrl = `ALU_ADD; // ADDI
                            3'b010: o_alu_ctrl = `ALU_SLT; // SLTI
                            3'b011: o_alu_ctrl = `ALU_SLTU;// SLTIU
                            3'b100: o_alu_ctrl = `ALU_XOR; // XORI
                            3'b110: o_alu_ctrl = `ALU_OR;  // ORI
                            3'b111: o_alu_ctrl = `ALU_AND; // ANDI
                            3'b001: o_alu_ctrl = `ALU_SLL; // SLLI
                            3'b101: begin
                                case (i_funct7)
                                    7'b0000000: o_alu_ctrl = `ALU_SRL; // SRLI
                                    7'b0100000: o_alu_ctrl = `ALU_SRA; // SRAI
                                    default:    o_alu_ctrl = `ALU_ADD;
                                endcase
                            end
                            default: o_alu_ctrl = `ALU_ADD;
                        endcase

                        next_state = WRITEBACK;
                    end

                    // -------- LOAD: compute address (rs1 + imm) -> MEMORY -> WRITEBACK
                    OP_LOAD: begin
                        o_alu_b_sel = 1'b1; // imm
                        o_alu_a_sel = 1'b0; // rs1
                        o_alu_ctrl  = `ALU_ADD; // address calc
                        o_pc_we = 1'b1;     // update PC
                        o_pc_sel = 2'b00;   // PC + 4

                        case (i_funct3)
                            3'b000: o_ram_mode = `DM_LB;
                            3'b001: o_ram_mode = `DM_LH;
                            3'b010: o_ram_mode = `DM_LW;
                            3'b100: o_ram_mode = `DM_LBU;
                            3'b101: o_ram_mode = `DM_LHU;
                            default: o_ram_mode = `DM_LW;
                        endcase

                        next_state = MEMORY;
                    end

                    // -------- STORE: compute address (rs1 + imm) -> MEMORY (write) -> FETCH
                    OP_STORE: begin
                        o_alu_b_sel = 1'b1; // imm
                        o_alu_a_sel = 1'b0; // rs1
                        o_alu_ctrl  = `ALU_ADD; // address calc
                        o_pc_we = 1'b1;     // update PC
                        o_pc_sel = 2'b00;   // PC + 4

                        case (i_funct3)
                            3'b000: o_ram_mode = `DM_SB;
                            3'b001: o_ram_mode = `DM_SH;
                            3'b010: o_ram_mode = `DM_SW;
                            default: o_ram_mode = `DM_SW;
                        endcase

                        next_state = MEMORY;
                    end

                    // -------- BRANCH: compare and update PC if taken (PC updated immediately)
                    OP_BRANCH: begin
                        o_alu_b_sel = 1'b0; // rs2
                        o_alu_a_sel = 1'b0; // rs1
                        o_alu_ctrl  = `ALU_SUB; // compare
                        o_pc_we    = 1'b1; // allow PC update

                        case (i_funct3)
                            3'b000: begin // BEQ
                                if (i_zero) begin
                                    branch_taken = 1'b1;
                                    debug_branch = 3'b001;
                                end
                            end
                            3'b001: begin // BNE
                                if (!i_zero) begin
                                    branch_taken = 1'b1;
                                    debug_branch = 3'b010;
                                end
                            end
                            3'b100: begin // BLT
                                if (i_neg) begin
                                    branch_taken = 1'b1;
                                    debug_branch = 3'b011;
                                end
                            end
                            3'b101: begin // BGE
                                if (!i_neg || i_zero) begin
                                    branch_taken = 1'b1;
                                    debug_branch = 3'b100;
                                end
                            end
                            3'b110: begin // BLTU
                                if (!i_carry) begin
                                    branch_taken = 1'b1;
                                    debug_branch = 3'b101;
                                end
                            end
                            3'b111: begin // BGEU
                                if (i_carry || i_zero) begin
                                    branch_taken = 1'b1;
                                    debug_branch = 3'b110;
                                end
                            end
                            default: begin
                                branch_taken = 1'b0;
                                debug_branch = 3'b000;
                            end
                        endcase

                        if (branch_taken) begin
                            o_pc_sel = 2'b01; // branch target path
                        end else begin
                            o_pc_sel = 2'b00; // PC + 4
                        end

                        // After EXECUTE branch, go to FETCH
                        next_state = FETCH;
                    end

                    // -------- JAL: set PC to target (PC+imm) and write PC+4 to rd in WB
                    OP_JAL: begin
                        o_pc_sel = 2'b01; // branch-like target selected (branch target path)
                        o_pc_we  = 1'b1; // allow PC update

                        next_state = WRITEBACK;
                    end

                    // -------- JALR: target = rs1 + imm, write PC+4 to rd
                    OP_JALR: begin
                        o_alu_a_sel = 1'b0; // rs1
                        o_alu_b_sel = 1'b1; // imm
                        o_alu_ctrl  = `ALU_ADD; // compute target
                        o_pc_sel    = 2'b10;    // select ALU result as PC target
                        o_pc_we     = 1'b1;     // allow PC update

                        next_state = WRITEBACK;
                    end

                    // -------- LUI: write immediate << 12 to rd (handled in WB)
                    OP_LUI: begin
                        o_pc_we = 1'b1;     // update PC
                        o_pc_sel = 2'b00;   // PC + 4

                        next_state = WRITEBACK;
                    end

                    // -------- AUIPC: PC + imm (ALU) -> WB
                    OP_AUIPC: begin
                        o_alu_a_sel = 1'b1; // PC
                        o_alu_b_sel = 1'b1; // imm
                        o_alu_ctrl  = `ALU_ADD;
                        o_pc_we = 1'b1;     // update PC
                        o_pc_sel = 2'b00;   // PC + 4

                        next_state = WRITEBACK;
                    end

                    default: begin
                        // Unhandled opcode -> treat as NOP
                        next_state = FETCH;
                    end
                endcase
            end

            //------------------------------------------------------------------
            MEMORY: begin
                // Memory state: for loads do read (capture into MDR), for stores do write
                if (i_opcode == OP_LOAD) begin
                    // For synchronous DMEM, we need an extra cycle to capture load data
                    next_state = MEMORY2;
                end else if (i_opcode == OP_STORE) begin
                    // Store: enable RAM write
                    o_ram_we = 1'b1;

                    next_state = FETCH;
                end else begin
                    // Shouldn't normally be here for other opcodes
                    next_state = FETCH;
                end
            end

            MEMORY2: begin
                // For synchronous DMEM, we need an extra cycle to capture load data
                o_mdr_we = 1'b1;

                next_state = WRITEBACK;
            end

            //------------------------------------------------------------------
            WRITEBACK: begin
                // Write result into register file (if applicable)
                o_reg_we = 1'b1;
                
                // Decide the o_result_sel
                case (i_opcode)
                    OP_R_TYPE:      o_result_sel = 2'b00; // ALU result
                    OP_I_TYPE:      o_result_sel = 2'b00; // ALU result
                    OP_LOAD:        o_result_sel = 2'b01; // Memory data
                    OP_JAL,
                    OP_JALR:        o_result_sel = 2'b10; // PC + 4
                    OP_LUI:         o_result_sel = 2'b11; // LUI immediate
                    OP_AUIPC:      o_result_sel = 2'b00; // ALU result
                    default:        o_result_sel = 2'b00; // default to ALU
                endcase

                next_state = FETCH;
            end

            //------------------------------------------------------------------
            default: begin
                next_state = FETCH;
            end
        endcase
    end

endmodule
