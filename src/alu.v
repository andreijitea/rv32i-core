`include "defines.vh"

module alu (
    input  wire [31:0] a,
    input  wire [31:0] b,
    input  wire [3:0]  alu_control,
    output reg  [31:0] alu_result,
    output wire zero,
    output wire negative,
    output wire carry
);

    always @(*) begin
        case (alu_control)
            `ALU_ADD:      alu_result = a + b;
            `ALU_SUB:      alu_result = a - b;
            `ALU_AND:      alu_result = a & b;
            `ALU_OR:       alu_result = a | b;
            `ALU_XOR:      alu_result = a ^ b;
            `ALU_SLT:      alu_result = ($signed(a) < $signed(b)) ? 32'b1 : 32'b0;
            `ALU_SLTU:     alu_result = (a < b) ? 32'b1 : 32'b0;
            `ALU_SLL:      alu_result = a << b[4:0];
            `ALU_SRL:      alu_result = a >> b[4:0];
            `ALU_SRA:      alu_result = $signed(a) >>> b[4:0];
            default:       alu_result = 32'b0;
        endcase
    end

    assign zero = (alu_result == 32'b0);
    assign negative = alu_result[31];
    assign carry = (alu_control == `ALU_SUB) ? (a >= b) : 1'b0;

endmodule