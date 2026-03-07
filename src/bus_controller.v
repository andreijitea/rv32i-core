`include "defines.vh"

module bus_controller (
    input wire clk,
    input wire rst,

    // CPU Interface
    input wire [31:0] cpu_address,
    input wire [31:0] cpu_write_data,
    output reg  [31:0] cpu_read_data,
    input wire cpu_we,
    input wire [2:0] cpu_mode,
    input wire cpu_req,
    output reg cpu_ready,

    // Memory Interface
    output reg [31:0] mem_address,
    output reg [31:0] mem_write_data,
    input wire [31:0] mem_read_data [1:0], // 0: dmem data, 1: uart data
    output reg mem_we,
    output reg [2:0] mem_mode,
    output reg [1:0] mem_req, // 01: dmem, 10: uart
    input wire [1:0] mem_ready // 01: dmem ready, 10: uart ready
);

    localparam IDLE = 1'b0, WAIT = 1'b1;
    localparam RAM_REQ = 2'b01, UART_REQ = 2'b10;

    reg state;
    reg [31:0] decoded_address;
    reg [1:0] current_peripheral_select;

    always @(*) begin
        if (cpu_address <= `RAM_TOP) begin
            // DMEM address range
            decoded_address = cpu_address - `RAM_BASE;
            current_peripheral_select = RAM_REQ;
        end else if (cpu_address >= `UART_BASE && cpu_address <= `UART_TOP) begin
            // UART address range
            decoded_address = cpu_address - `UART_BASE;
            current_peripheral_select = UART_REQ;
        end else begin
            // Default to DMEM for unmapped addresses
            decoded_address = 32'b0;
            current_peripheral_select = RAM_REQ;
        end
    end

    always @(posedge clk) begin
        if (rst) begin
            state <= IDLE;

            cpu_read_data <= 32'b0;
            cpu_ready <= 1'b0;

            mem_address <= 32'b0;
            mem_write_data <= 32'b0;
            mem_we <= 1'b0;
            mem_mode <= 3'b0;
            mem_req <= 2'b00;
        end else begin
            case (state)
                IDLE: begin
                    cpu_ready <= 1'b0;

                    if (cpu_req) begin
                        state <= WAIT;

                        // Forward CPU request to memory
                        mem_address <= decoded_address;
                        mem_write_data <= cpu_write_data;
                        mem_we <= cpu_we;
                        mem_mode <= cpu_mode;
                        mem_req <= current_peripheral_select;

                        if (cpu_we) begin
                            // For writes, immediately set ready to allow next instruction
                            cpu_ready <= 1'b1;
                        end
                    end
                end
                WAIT: begin
                    cpu_ready <= 1'b0;

                    if ((mem_req[0] && mem_ready[0]) || (mem_req[1] && mem_ready[1])) begin
                        state <= IDLE;
                        // Capture memory response
                        cpu_read_data <= mem_req[0] ? mem_read_data[0] : 
                                         (mem_req[1] ? mem_read_data[1] : 32'b0);
                        
                        if (!mem_we) begin
                            // For reads, set ready after data is captured
                            cpu_ready <= 1'b1;
                        end
                        
                        mem_req <= 2'b0;
                        mem_we <= 1'b0;
                    end
                end
                default: state <= IDLE;
            endcase
        end
    end

endmodule