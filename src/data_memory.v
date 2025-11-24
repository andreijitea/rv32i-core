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

    // 1KB Data Memory
    reg [31:0] mem [0:255];

    wire [1:0] byte_offset;  // Byte offset within the word
    wire [7:0] word_index;  // Word index in memory

    assign byte_offset = address[1:0];
    assign word_index = address[9:2];


    // Write Logic (Synchronous)
    always @(posedge clk) begin
        if (we && !rst) begin
            case (mode)
                `DM_SB: begin
                    // Store Byte
                    case (byte_offset)
                        2'b00: mem[word_index][7:0]   <= write_data[7:0];
                        2'b01: mem[word_index][15:8]  <= write_data[7:0];
                        2'b10: mem[word_index][23:16] <= write_data[7:0];
                        2'b11: mem[word_index][31:24] <= write_data[7:0];
                    endcase
                end
                `DM_SH: begin
                    // Store Halfword
                    case (byte_offset[1])
                        1'b0: mem[word_index][15:0]  <= write_data[15:0];
                        1'b1: mem[word_index][31:16] <= write_data[15:0];
                    endcase
                end
                `DM_SW: begin
                    // Store Word
                    mem[word_index] <= write_data;
                end
                default: begin
                    // Default to Store Word
                    mem[word_index] <= write_data;
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
                    case (byte_offset)
                        2'b00: read_data = {{24{mem[word_index][7]}}, mem[word_index][7:0]};
                        2'b01: read_data = {{24{mem[word_index][15]}}, mem[word_index][15:8]};
                        2'b10: read_data = {{24{mem[word_index][23]}}, mem[word_index][23:16]};
                        2'b11: read_data = {{24{mem[word_index][31]}}, mem[word_index][31:24]};
                    endcase
                end
                `DM_LH: begin
                    // Load Halfword (sign-extended)
                    case (byte_offset[1])
                        1'b0: read_data = {{16{mem[word_index][15]}}, mem[word_index][15:0]};
                        1'b1: read_data = {{16{mem[word_index][31]}}, mem[word_index][31:16]};
                    endcase
                end
                `DM_LW: begin
                    // Load Word
                    read_data = mem[word_index];
                end
                `DM_LBU: begin
                    // Load Byte Unsigned (zero-extended)
                    case (byte_offset)
                        2'b00: read_data = {24'b0, mem[word_index][7:0]};
                        2'b01: read_data = {24'b0, mem[word_index][15:8]};
                        2'b10: read_data = {24'b0, mem[word_index][23:16]};
                        2'b11: read_data = {24'b0, mem[word_index][31:24]};
                    endcase
                end
                `DM_LHU: begin
                    // Load Halfword Unsigned (zero-extended)
                    case (byte_offset[1])
                        1'b0: read_data = {16'b0, mem[word_index][15:0]};
                        1'b1: read_data = {16'b0, mem[word_index][31:16]};
                    endcase
                end
                default: begin
                    // Default to Load Word
                    read_data = mem[word_index];
                end
            endcase
        end
    end
endmodule