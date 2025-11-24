`include "memory_map.vh"

module memory_controller (
    input  wire clk,
    input  wire rst,
    
    // CPU interface (from ALU)
    input wire [31:0] address,
    input wire [31:0] write_data,
    output reg  [31:0] read_data,
    input wire we,
    input wire [2:0] mode,
    input wire re,

    // Data Memory interface
    output wire [31:0] dm_address,
    output wire [31:0] dm_write_data,
    input  wire [31:0] dm_read_data,
    output wire dm_we,
    output wire [2:0] dm_mode

    // Future: Connections to peripherals
);

    wire address_in_dm, address_in_periph;
    wire mem_access;

    assign address_in_dm = (address >= `RAM_START_ADDR && address <= `RAM_END_ADDR);
    assign address_in_periph = (address >= `PERIPH_START_ADDR);

    assign mem_access = we || re;

    // Data Memory connections
    assign dm_address = address - `RAM_START_ADDR;
    assign dm_write_data = write_data;
    assign dm_we = we && address_in_dm && !rst;
    assign dm_mode = mode;

    // Read Logic
    always @(*) begin
        if (rst) begin
            read_data = 32'b0;
        end else if (address_in_dm && mem_access) begin
            read_data = dm_read_data;
        end else if (address_in_periph && mem_access) begin
            read_data = 32'hDEADBEEF;
            if (we)
                $display("WARNING: Write to unmapped peripheral at 0x%h", address);
            else
                $display("WARNING: Read from unmapped peripheral at 0x%h", address);
        end else if (mem_access && !address_in_dm && !address_in_periph) begin
            read_data = 32'h00000000;
            $display("WARNING: Memory access to unmapped address 0x%h", address);
        end else begin
            // Not a memory operation, just pass through (no warning)
            read_data = 32'h00000000;
        end
    end
endmodule