module instruction_reg (
    input wire clk,
    input wire rst,
    input wire [31:0] instr_in,
    output reg [31:0] instr_out,
    input wire load
);

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            instr_out <= 32'b0;
        end else if (load) begin
            instr_out <= instr_in;
        end
    end

endmodule