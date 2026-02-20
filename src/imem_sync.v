module imem_sync #(
    parameter LATENCY = 1  // 1 = default (ready next cycle)
) (
    input wire clk,
    input wire rst,
    
    input wire [31:0] address,
    output reg [31:0] read_data,
    input wire req,
    output reg ready
);

    // 32 bit wide ROM with 1024 words (4KB)
    reg [31:0] rom_mem [0:1023];

    reg [$clog2(LATENCY+1)-1:0] count;

    // Synchronous read with configurable latency
    always @(posedge clk) begin
        ready <= 1'b0; // Default to not ready

        if (rst) begin
            read_data <= 32'b0;
            ready     <= 1'b0;
            count     <= '0;
        end else if (req) begin
            if (count == LATENCY - 1) begin
                ready     <= 1'b1;
                read_data <= rom_mem[address[11:2]];
                count     <= '0;
            end else begin
                count <= count + 1;
            end
        end else begin
            count <= '0;
        end
    end
endmodule