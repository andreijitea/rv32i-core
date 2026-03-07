`include "defines.vh"

module uart #(
    parameter LATENCY = 1 // 1 = default (ready next cycle)
) (
    input wire clk,
    input wire rst,
    
    input wire [31:0] address,
    input wire [31:0] write_data,
    output reg [31:0] read_data,
    input wire we,
    input wire [2:0] mode,
    input wire req,
    output reg ready,
    output reg tx, // UART transmit line
    input wire rx   // UART receive line
);
    localparam CYCLES_PER_BIT = 10;
    localparam TX_REG_ADDR = 32'h0000_0000;
    localparam RX_REG_ADDR = 32'h0000_0004;
    localparam STATUS_REG_ADDR = 32'h0000_0008;

    // Tx register (address 0x0000_0000)
    reg [7:0] tx_reg;
    // Rx register (address 0x0000_0004)
    reg [7:0] rx_reg;
    // Status register (address 0x0000_0008)
    // Bit 0: Tx ready (1 = ready to accept new byte, 0 = busy transmitting)
    // Bit 1: Rx ready (1 = new byte received and ready to read, 0 = no new data)
    reg [7:0] status_reg;

    // For simplicity i keep the UART fixed to 8N1
    reg [9:0] tx_shift_reg; // Start bit + 8 data bits + stop bit
    reg [3:0] tx_bit_count;
    reg [3:0] tx_cycle_count;
    reg tx_busy; // Indicates if a byte is currently being transmitted

    reg [1:0] state;
    localparam IDLE = 2'b00;
    localparam TRANSMIT = 2'b01;
    localparam RECEIVE = 2'b10;

    always @(posedge clk) begin
        ready <= 1'b0; // Default to not ready
        status_reg[0] <= ~tx_busy; // Tx ready bit

        if (rst) begin
            read_data <= 32'b0;
            ready <= 1'b0;
            tx <= 1'b1; // Idle state for UART is high
            tx_busy <= 1'b0;
            tx_bit_count <= 0;
            tx_cycle_count <= 0;
            state <= IDLE;
            status_reg <= 8'b0;
        end else begin

            case (state)
                IDLE: begin
                    tx <= 1'b1;
                    if (req) begin
                        if (we && address == TX_REG_ADDR) begin
                            if (!tx_busy) begin
                                ready <= 1'b1;

                                tx_busy <= 1'b1;
                                tx_bit_count <= 0;
                                tx_cycle_count <= 0;

                                // Load shift register LSB first with start bit (0), data bits, and stop bit (1)
                                tx_shift_reg <= {1'b1, write_data[7:0], 1'b0};

                                state <= TRANSMIT;
                            end else begin
                                ready <= 1'b0; // Still busy transmitting previous byte
                            end
                        end else if (!we && address == STATUS_REG_ADDR) begin
                            // CPU is loading the status register
                            ready <= 1'b1;
                            read_data <= {24'b0, status_reg};
                        end else if (!we && address == RX_REG_ADDR) begin
                            // TODO
                        end else begin
                            ready <= 1'b0; // Invalid address
                        end
                    end else begin
                        ready <= 1'b0;
                    end
                end

                TRANSMIT: begin
                    tx <= tx_shift_reg[0]; // drive current bit every cycle

                    if (tx_cycle_count == CYCLES_PER_BIT - 1) begin
                        tx_cycle_count <= 0;

                        // Shift the register to get the next bit ready
                        tx_shift_reg <= {1'b1, tx_shift_reg[9:1]};
                        tx_bit_count <= tx_bit_count + 1;

                        if (tx_bit_count == 9) begin
                            // Finished transmitting start bit + 8 data bits + stop bit
                            tx_busy <= 1'b0;
                            state <= IDLE;
                        end
                    end else begin
                        tx_cycle_count <= tx_cycle_count + 1;
                    end
                end

                RECEIVE: begin
                    // TODO
                end

                default: state <= IDLE;
            endcase
        end
    end

endmodule