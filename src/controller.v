`include "defines.vh"

module controller (
    input  wire [6:0] opcode,
    input  wire [2:0] funct3,
    input  wire [6:0] funct7,
    input  wire zero,
    input wire negative,
    input wire carry,
    output reg [1:0] pc_src,
    output reg [1:0] result_src,
    output reg mem_write,
    output reg [3:0] alu_control,
    output reg alu_a_src,
    output reg alu_b_src,
    output reg [2:0] imm_src,
    output reg reg_write,
    output reg [2:0] data_mem_mode
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

    // Internal signals for branch logic
    reg branch;
    reg branch_taken;

    always @(*) begin
        // Default values
        reg_write = 1'b0;
        mem_write = 1'b0;
        alu_a_src = 1'b0;
        alu_b_src = 1'b0;
        pc_src = 2'b00;
        result_src = 2'b00;
        imm_src = 3'b000;
        alu_control = 4'b0000;
        branch = 1'b0;
        branch_taken = 1'b0;
        data_mem_mode = `DM_LW;

        case (opcode)
            OP_R_TYPE: begin
                // R-type instructions
                reg_write = 1'b1; // Enable register write
                alu_b_src = 1'b0;  // Use rs2
                result_src = 2'b00;  // Use ALU result
                imm_src = `IMM_R_TYPE; // Does nothing

                case ({funct7, funct3})
                    10'b0000000_000: alu_control = `ALU_ADD;   // ADD
                    10'b0100000_000: alu_control = `ALU_SUB;   // SUB
                    10'b0000000_001: alu_control = `ALU_SLL;   // SLL
                    10'b0000000_010: alu_control = `ALU_SLT;   // SLT
                    10'b0000000_011: alu_control = `ALU_SLTU;  // SLTU
                    10'b0000000_100: alu_control = `ALU_XOR;   // XOR
                    10'b0000000_101: alu_control = `ALU_SRL;   // SRL
                    10'b0100000_101: alu_control = `ALU_SRA;   // SRA
                    10'b0000000_110: alu_control = `ALU_OR;    // OR
                    10'b0000000_111: alu_control = `ALU_AND;   // AND
                    default: alu_control = `ALU_ADD;
                endcase
            end

            OP_I_TYPE: begin
                // I-type ALU instructions
                reg_write = 1'b1; // Enable register write
                alu_b_src = 1'b1; // Use immediate
                result_src = 2'b00; // Use ALU result
                imm_src = `IMM_I_TYPE;

                case (funct3)
                    3'b000: alu_control = `ALU_ADD;   // ADDI
                    3'b010: alu_control = `ALU_SLT;   // SLTI
                    3'b011: alu_control = `ALU_SLTU;  // SLTIU
                    3'b100: alu_control = `ALU_XOR;   // XORI
                    3'b110: alu_control = `ALU_OR;    // ORI
                    3'b111: alu_control = `ALU_AND;   // ANDI
                    3'b001: alu_control = `ALU_SLL;   // SLLI
                    3'b101: begin
                        case (funct7)
                            7'b0000000: alu_control = `ALU_SRL; // SRLI
                            7'b0100000: alu_control = `ALU_SRA; // SRAI
                            default: alu_control = `ALU_ADD;
                        endcase
                    end
                    default: alu_control = `ALU_ADD;
                endcase
            end

            OP_LOAD: begin
                // Load instructions (LW)
                reg_write = 1'b1;
                alu_b_src = 1'b1;  // Use immediate for address calculation
                result_src = 2'b01;  // Memory data
                imm_src = `IMM_I_TYPE;
                alu_control = `ALU_ADD;  // Address = rs1 + imm

                case (funct3)
                    3'b000: data_mem_mode = `DM_LB; // LB
                    3'b001: data_mem_mode = `DM_LH; // LH
                    3'b010: data_mem_mode = `DM_LW; // LW
                    3'b100: data_mem_mode = `DM_LBU; // LBU
                    3'b101: data_mem_mode = `DM_LHU; // LHU
                    default: data_mem_mode = `DM_LW;
                endcase
            end

            OP_STORE: begin
                // Store instructions (SW)
                mem_write = 1'b1;
                alu_b_src = 1'b1;  // Use immediate for address calculation
                imm_src = `IMM_S_TYPE;
                alu_control = `ALU_ADD;  // Address = rs1 + imm

                case (funct3)
                    3'b000: data_mem_mode = `DM_SB; // SB
                    3'b001: data_mem_mode = `DM_SH; // SH
                    3'b010: data_mem_mode = `DM_SW; // SW
                    default: data_mem_mode = `DM_SW;
                endcase
            end

            OP_BRANCH: begin
                // Branch instructions
                branch = 1'b1;
                alu_b_src = 1'b0;  // Use rs2 for comparison
                imm_src = `IMM_B_TYPE;
                alu_control = `ALU_SUB;  // Compare by subtraction

                // Determine if branch should be taken
                case (funct3)
                    3'b000: branch_taken = zero;        // BEQ
                    3'b001: branch_taken = ~zero;       // BNE
                    3'b100: branch_taken = negative;    // BLT
                    3'b101: branch_taken = ~negative;   // BGE
                    3'b110: branch_taken = ~carry;      // BLTU
                    3'b111: branch_taken = carry;       // BGEU
                    default: branch_taken = 1'b0;
                endcase

                pc_src = branch_taken ? 2'b01 : 2'b00; // Select branch target or next sequential PC
            end

            OP_JAL: begin
                // JAL instruction
                reg_write = 1'b1;
                result_src = 2'b10;  // PC + 4
                imm_src = `IMM_J_TYPE;
                pc_src = 2'b01; // Jump to PC + immediate (using branch target path)
            end

            OP_JALR: begin
                // JALR instruction
                reg_write = 1'b1;
                alu_b_src = 1'b1;  // Use immediate
                result_src = 2'b10;  // PC + 4
                imm_src = `IMM_I_TYPE;
                alu_control = `ALU_ADD;  // Target = rs1 + imm
                pc_src = 2'b10;  // Jump to ALU result
            end

            OP_LUI: begin
                // LUI instruction
                reg_write = 1'b1;
                result_src = 2'b11;
                imm_src = `IMM_U_TYPE;
                alu_b_src = 1'b0;  // Don't care
                alu_control = `ALU_ADD;  // Don't care
            end

            OP_AUIPC: begin
                // AUIPC instruction
                reg_write = 1'b1;
                result_src = 2'b00;  // ALU result
                imm_src = `IMM_U_TYPE;
                alu_a_src = 1'b1;  // Use PC
                alu_b_src = 1'b1;
                alu_control = `ALU_ADD;  // PC + immediate
            end

            default: begin
                // NOP or illegal instruction
                reg_write = 1'b0;
                mem_write = 1'b0;
            end
        endcase
    end

endmodule