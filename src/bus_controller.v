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

    localparam IDLE = 2'b00;
    localparam WAIT = 2'b01;

    reg [1:0] state;

    wire is_dmem, is_uart;
    assign is_dmem = (cpu_address <= `RAM_TOP);
    assign is_uart = (cpu_address >= `UART_BASE) && (cpu_address <= `UART_TOP);


    always @(posedge clk) begin
        if (rst) begin
            state <= IDLE;
            cpu_ready <= 1'b0;
            mem_req <= 2'b00;
        end else begin
            case (state)
                IDLE: 
                    if (cpu_req) begin
                        // Forward CPU request to memory
                        mem_address <= cpu_address;
                        mem_write_data <= cpu_write_data;
                        mem_we <= cpu_we;
                        mem_mode <= cpu_mode;
                        mem_req <= is_dmem ? 2'b01 : 
                                    (is_uart ? 2'b10 : 2'b00);
                        state <= WAIT;
                    end else begin
                        cpu_ready <= 1'b0;
                    end
                WAIT:
                    if ((mem_req[0] && mem_ready[0]) || (mem_req[1] && mem_ready[1])) begin
                        // Capture memory response
                        cpu_read_data <= is_dmem ? mem_read_data[0] : 
                                         (is_uart ? mem_read_data[1] : 32'b0);
                        cpu_ready <= 1'b1;
                        mem_req <= 2'b00;

                        state <= IDLE;
                    end else begin
                        cpu_ready <= 1'b0;
                    end
                default: state <= IDLE;
            endcase
        end
    end

endmodule