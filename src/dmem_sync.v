`include "defines.vh"

module dmem_sync #(
    parameter LATENCY = 1  // 1 = default (ready next cycle)
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

    // 32 bit wide RAM with 1024 words (4KB)
    reg [31:0] ram_mem [0:1023];


    wire [1:0] byte_offset;  // Byte offset within the word
    wire [9:0] word_index;  // Word index in memory

    reg [$clog2(LATENCY+1)-1:0] count;

    // Synchronous read/write with configurable latency
    always @(posedge clk) begin
        ready <= 1'b0; // Default to not ready
        
        if (rst) begin
            read_data <= 32'b0;
            ready     <= 1'b0;
            count     <= '0;
        end else if (req) begin
            if (count == LATENCY - 1) begin
                count <= '0;
                ready <= 1'b1;
                if (we) begin
                    // Write operation
                    case (mode)
                        `DM_SB: begin
                            // Store Byte
                            case (byte_offset)
                                2'b00: ram_mem[word_index][7:0]   <= write_data[7:0];
                                2'b01: ram_mem[word_index][15:8]  <= write_data[7:0];
                                2'b10: ram_mem[word_index][23:16] <= write_data[7:0];
                                2'b11: ram_mem[word_index][31:24] <= write_data[7:0];
                            endcase
                        end
                        `DM_SH: begin
                            // Store Halfword
                            case (byte_offset[1])
                                1'b0: ram_mem[word_index][15:0]  <= write_data[15:0];
                                1'b1: ram_mem[word_index][31:16] <= write_data[15:0];
                            endcase
                        end
                        `DM_SW: begin
                            // Store Word
                            ram_mem[word_index] <= write_data;
                        end
                        default: begin
                            // Default to Store Word
                            ram_mem[word_index] <= write_data;
                        end
                    endcase
                end else begin
                    // Read operation
                    case (mode)
                        `DM_LB: begin
                            // Load Byte (sign-extended)
                            case (byte_offset)
                                2'b00: read_data <= {{24{ram_mem[word_index][7]}}, ram_mem[word_index][7:0]};
                                2'b01: read_data <= {{24{ram_mem[word_index][15]}}, ram_mem[word_index][15:8]};
                                2'b10: read_data <= {{24{ram_mem[word_index][23]}}, ram_mem[word_index][23:16]};
                                2'b11: read_data <= {{24{ram_mem[word_index][31]}}, ram_mem[word_index][31:24]};
                            endcase
                        end
                        `DM_LBU: begin
                            // Load Byte Unsigned (zero-extended)
                            case (byte_offset)
                                2'b00: read_data <= {24'b0, ram_mem[word_index][7:0]};
                                2'b01: read_data <= {24'b0, ram_mem[word_index][15:8]};
                                2'b10: read_data <= {24'b0, ram_mem[word_index][23:16]};
                                2'b11: read_data <= {24'b0, ram_mem[word_index][31:24]};
                            endcase
                        end
                        `DM_LH: begin
                            // Load Halfword (sign-extended)
                            case (byte_offset[1])
                                1'b0: read_data <= {{16{ram_mem[word_index][15]}}, ram_mem[word_index][15:0]};
                                1'b1: read_data <= {{16{ram_mem[word_index][31]}}, ram_mem[word_index][31:16]};
                            endcase
                        end
                        `DM_LHU: begin
                            // Load Halfword Unsigned (zero-extended)
                            case (byte_offset[1])
                                1'b0: read_data <= {16'b0, ram_mem[word_index][15:0]};
                                1'b1: read_data <= {16'b0, ram_mem[word_index][31:16]};
                            endcase
                        end
                        `DM_LW: begin
                            // Load Word
                            read_data <= ram_mem[word_index];
                        end
                        default: begin
                            // Default to Load Word
                            read_data <= ram_mem[word_index];
                        end
                    endcase
                end
            end else begin
                count <= count + 1;
            end
        end else begin
            count <= '0;
        end
    end

    // Address decoding
    assign byte_offset = address[1:0];  // Bottom 2 bits for byte offset
    assign word_index  = address[11:2]; // Next 10 bits for word index (4KB RAM)
endmodule
