`include "defines.vh"

module extender (
    input  wire [31:0] imm_in,
    output wire [31:0] imm_out,
    input wire [2:0] imm_src
);

    reg [31:0] imm_reg;

    always @(*) begin
        case (imm_src)
            `IMM_I_TYPE: begin
                // I-type immediate (sign-extended)
                imm_reg = {{20{imm_in[31]}}, imm_in[31:20]};
            end
            `IMM_S_TYPE: begin
                // S-type immediate (sign-extended)
                imm_reg = {{20{imm_in[31]}}, imm_in[31:25], imm_in[11:7]};
            end
            `IMM_B_TYPE: begin
                // B-type immediate (sign-extended) and shifted left by 1
                imm_reg = {{19{imm_in[31]}}, imm_in[31], imm_in[7], imm_in[30:25], imm_in[11:8], 1'b0};
            end
            `IMM_U_TYPE: begin
                // U-type immediate (upper 20 bits)
                imm_reg = {imm_in[31:12], 12'b0};
            end
            `IMM_J_TYPE: begin
                // J-type immediate (sign-extended) and shifted left by 1
                imm_reg = {{11{imm_in[31]}}, imm_in[31], imm_in[19:12], imm_in[20], imm_in[30:21], 1'b0};
            end
            `IMM_R_TYPE: begin
                // R-type has no immediate, output zero
                imm_reg = 32'b0;
            end
            default: begin
                imm_reg = 32'b0;
            end
        endcase
    end

    assign imm_out = imm_reg;

endmodule