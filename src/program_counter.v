module program_counter (
    input wire clk,
    input wire rst,
    input wire [31:0] next_pc,
    output wire [31:0] pc
);

    reg [31:0] pc_reg;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            pc_reg <= 32'b0;
        end else begin
            pc_reg <= next_pc;
        end
    end

    assign pc = pc_reg;

endmodule
