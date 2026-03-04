`include "defines.vh"

module uart #(
    parameter LATENCY = 1 // 1 = default (ready next cycle)
) (
    input wire clk,
    input wire rst,
    
    input wire [31:0] address,
    input wire [31:0] write_data,
    output reg  [31:0] read_data,
    input wire we,
    input wire [2:0] mode,
    input wire req,
    output reg ready
);

    always @(posedge clk) begin
        ready <= 1'b0; // Default to not ready

        if (rst) begin
            read_data <= 32'b0;
            ready     <= 1'b0;
        end
    end

endmodule