`include "defines.vh"

module extender (
    input  wire [31:0] imm_in,
    output reg [31:0] imm_out,
    input wire [2:0] imm_src
);

    always @(*) begin
        case (imm_src)
            `IMM_I_TYPE: begin
                // I-type immediate (sign-extended)
                imm_out = {{20{imm_in[31]}}, imm_in[31:20]};
            end
            `IMM_S_TYPE: begin
                // S-type immediate (sign-extended)
                imm_out = {{20{imm_in[31]}}, imm_in[31:25], imm_in[11:7]};
            end
            `IMM_B_TYPE: begin
                // B-type immediate (sign-extended) and shifted left by 1
                imm_out = {{19{imm_in[31]}}, imm_in[31], imm_in[7], imm_in[30:25], imm_in[11:8], 1'b0};
            end
            `IMM_U_TYPE: begin
                // U-type immediate (upper 20 bits)
                imm_out = {imm_in[31:12], 12'b0};
            end
            `IMM_J_TYPE: begin
                // J-type immediate (sign-extended) and shifted left by 1
                imm_out = {{11{imm_in[31]}}, imm_in[31], imm_in[19:12], imm_in[20], imm_in[30:21], 1'b0};
            end
            `IMM_R_TYPE: begin
                // R-type has no immediate, output zero
                imm_out = 32'b0;
            end
            default: begin
                imm_out = 32'b0;
            end
        endcase
    end
endmodule