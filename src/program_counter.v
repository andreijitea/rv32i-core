module program_counter (
    input wire clk,
    input wire rst,
    input wire [31:0] next_pc,
    output reg [31:0] pc,
    input wire pc_we
);

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            pc <= 32'b0;
        end else if (pc_we) begin
            pc <= next_pc;
        end
    end

endmodule
