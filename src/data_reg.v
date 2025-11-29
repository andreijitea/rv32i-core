module data_reg (
    input wire clk,
    input wire rst,
    input wire we,
    input wire [31:0] data_in,
    output reg [31:0] data_out
);

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            data_out <= 32'b0;
        end else if (we) begin
            data_out <= data_in;
        end
    end
endmodule