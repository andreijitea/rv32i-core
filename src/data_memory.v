`include "defines.vh"

module data_memory (
    input  wire clk,
    input  wire rst,
    input  wire [31:0] address,
    input  wire [31:0] write_data,
    output reg  [31:0] read_data,
    input wire we,
    input wire [2:0] mode
);

    // 1KB of data memory (256 words)
    reg [7:0] mem [0:1023];

    // Write Logic (Synchronous)
    always @(posedge clk) begin
        if (we && !rst) begin
            case (mode)
                `DM_SB: begin
                    // Store Byte
                    mem[address] <= write_data[7:0];
                end
                `DM_SH: begin
                    // Store Halfword
                    mem[address] <= write_data[7:0];
                    mem[address + 1] <= write_data[15:8];
                end
                `DM_SW: begin
                    // Store Word
                    mem[address] <= write_data[7:0];
                    mem[address + 1] <= write_data[15:8];
                    mem[address + 2] <= write_data[23:16];
                    mem[address + 3] <= write_data[31:24];
                end
                default: begin
                    // Default to Store Word
                    mem[address] <= write_data[7:0];
                    mem[address + 1] <= write_data[15:8];
                    mem[address + 2] <= write_data[23:16];
                    mem[address + 3] <= write_data[31:24];
                end
            endcase
        end
    end

    // Read Logic (Combinational)
    // Word-aligned addressing: ignore bottom 2 bits
    always @(*) begin
        if (rst) begin
            read_data = 32'b0;
        end else begin
            case (mode)
                `DM_LB: begin
                    // Load Byte (sign-extended)
                    read_data = {{24{mem[address][7]}}, mem[address]};
                end
                `DM_LH: begin
                    // Load Halfword (sign-extended)
                    read_data = {{16{mem[address + 1][7]}}, mem[address + 1], mem[address]};
                end
                `DM_LW: begin
                    // Load Word
                    read_data = {mem[address + 3], mem[address + 2], mem[address + 1], mem[address]};
                end
                `DM_LBU: begin
                    // Load Byte Unsigned (zero-extended)
                    read_data = {24'b0, mem[address]};
                end
                `DM_LHU: begin
                    // Load Halfword Unsigned (zero-extended)
                    read_data = {16'b0, mem[address + 1], mem[address]};
                end
                default: begin
                    // Default to Load Word
                    read_data = {mem[address + 3], mem[address + 2], mem[address + 1], mem[address]};
                end
            endcase
        end
    end
endmodule