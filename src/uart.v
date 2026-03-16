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
    localparam TX_REG_ADDR = 32'h0000_0000;
    localparam RX_REG_ADDR = 32'h0000_0004;
    localparam STATUS_REG_ADDR = 32'h0000_0008;
    localparam BAUD_RATE_REG_ADDR = 32'h0000_000C;

    // Tx register (address 0x0000_0000)
    reg [7:0] tx_reg;
    // Rx register (address 0x0000_0004)
    reg [7:0] rx_reg;
    // Status register (address 0x0000_0008)
    // Bit 0: Tx ready (1 = ready to accept new byte, 0 = still transmitting previous byte)
    // Bit 1: Rx ready (1 = new byte received and ready to read, 0 = no new data)
    wire [7:0] status_reg = {6'b0, rx_ready, ~tx_busy};
    // Baud rate register
    reg [7:0] baud_rate_reg; 

    reg [7:0] tx_shift_reg;
    reg [7:0] tx_bit_count;
    reg [8:0] tx_cycle_count;
    reg tx_busy; // Indicates if a byte is currently being transmitted
    reg tx_start; // Indicates the start of a new transmission

    reg[7:0] rx_shift_reg;
    reg [3:0] rx_bit_count;
    reg [7:0] rx_cycle_count;
    reg rx_ready; // Indicates if a new byte has been received
    reg rx_done; // Signal to indicate a byte has been fully received and is ready to be read
    reg [7:0] rx_temp; // Temporary holding buffer inside Rx FSM

    localparam TX_IDLE = 2'b00;
    localparam TX_START = 2'b01;
    localparam TX_DATA = 2'b10;
    localparam TX_STOP = 2'b11;
    reg [1:0] tx_state;

    localparam RX_IDLE = 2'b00;
    localparam RX_START = 2'b01;
    localparam RX_DATA = 2'b10;
    localparam RX_STOP = 2'b11;
    reg [1:0] rx_state;

    // Bus interface state machine
    always @(posedge clk) begin
        if (rst) begin
            ready <= 1'b0;
            read_data <= 32'b0;

            tx_start <= 1'b0;
            tx_reg <= 8'b0;

            rx_ready <= 1'b0;
            rx_reg <= 8'b0;

            baud_rate_reg <= 8'd10; // Default baud rate top value
        end else begin
            ready <= 1'b0;
            tx_start <= 1'b0;

            if (rx_done) begin
                rx_reg <= rx_temp;
                rx_ready <= 1'b1;
            end

            if (req) begin
                ready <= 1'b1;

                if (we && address == TX_REG_ADDR) begin
                    // CPU is writing to the Tx register
                    if (!tx_busy) begin
                        tx_reg <= write_data[7:0]; // Load holding register
                        tx_start <= 1'b1;
                    end else begin
                        // Still busy transmitting previous byte
                        ready <= 1'b0;
                    end
                end else if (!we && address == STATUS_REG_ADDR) begin
                    // CPU is reading the status register
                    read_data <= {24'b0, status_reg};
                end else if (!we && address == RX_REG_ADDR) begin
                    // CPU is reading the Rx register
                    read_data <= {24'b0, rx_reg};
                    rx_ready <= 1'b0;
                end else if (we && address == BAUD_RATE_REG_ADDR) begin
                    // CPU is writing to the baud rate register
                    baud_rate_reg <= write_data[7:0];
                end else begin
                    // Invalid address, ignore
                    ready <= 1'b0;
                end
            end
        end
    end

    // Tx state machine
    always @(posedge clk) begin
        if (rst) begin
            tx <= 1'b1; // Idle state for UART is high
            tx_busy <= 1'b0;
            tx_bit_count <= 0;
            tx_cycle_count <= 0;
            tx_state <= TX_IDLE;
        end else begin
            case (tx_state)
                TX_IDLE: begin
                    // Idle
                    tx <= 1'b1;

                    if (tx_start) begin
                        tx_shift_reg <= tx_reg;
                        tx_busy <= 1'b1;
                        tx_bit_count <= 0;
                        tx_cycle_count <= 0;
                        tx_state <= TX_START;
                    end
                end
                TX_START: begin
                    // Start bit
                    tx <= 1'b0;

                    if (tx_cycle_count == baud_rate_reg - 1) begin
                        tx_cycle_count <= 0;
                        tx_state <= TX_DATA;
                    end else begin
                        tx_cycle_count <= tx_cycle_count + 1;
                    end
                end
                TX_DATA: begin
                    // Data bits
                    tx <= tx_shift_reg[0];

                    if (tx_cycle_count == baud_rate_reg - 1) begin
                        tx_cycle_count <= 0;
                        tx_shift_reg <= {1'b0, tx_shift_reg[7:1]}; // Shift right
                        tx_bit_count <= tx_bit_count + 1;

                        if (tx_bit_count == 7) begin
                            tx_state <= TX_STOP;
                        end
                    end else begin
                        tx_cycle_count <= tx_cycle_count + 1;
                    end
                end
                TX_STOP: begin
                    // Stop bit
                    tx <= 1'b1;

                    if (tx_cycle_count == baud_rate_reg - 1) begin
                        tx_cycle_count <= 0;
                        tx_busy <= 1'b0;
                        tx_state <= TX_IDLE;
                    end else begin
                        tx_cycle_count <= tx_cycle_count + 1;
                    end
                end
                default: tx_state <= TX_IDLE;
            endcase
        end        
    end

    // Rx state machine
    always @(posedge clk) begin
        if (rst) begin
            rx_bit_count <= 0;
            rx_cycle_count <= 0;
            rx_state <= RX_IDLE;
            rx_done <= 1'b0;
            rx_temp <= 8'b0;
        end else begin
            rx_done <= 1'b0;

            case (rx_state)
                RX_IDLE: begin
                    // Wait for start bit
                    if (rx == 1'b0) begin
                        rx_cycle_count <= 0;
                        rx_bit_count <= 0;
                        rx_state <= RX_START;
                    end
                end
                RX_START: begin
                    // Validate start bit
                    if (rx_cycle_count == baud_rate_reg / 2) begin
                        if (rx == 1'b0) begin
                            rx_cycle_count <= 0; // Reset counter for the first data bit
                            rx_state <= RX_DATA;
                        end else begin
                            // False start bit, go back to idle
                            rx_state <= RX_IDLE;
                        end
                    end else begin
                        rx_cycle_count <= rx_cycle_count + 1;
                    end
                end
                RX_DATA: begin
                    // Sample data bits
                    if (rx_cycle_count == baud_rate_reg - 1) begin
                        rx_cycle_count <= 0;
                        rx_shift_reg <= {rx, rx_shift_reg[7:1]}; 
                        rx_bit_count <= rx_bit_count + 1;

                        if (rx_bit_count == 7) begin
                            rx_state <= RX_STOP;
                        end
                    end else begin
                        rx_cycle_count <= rx_cycle_count + 1;
                    end
                end
                RX_STOP: begin
                    // Validate stop bit
                    if (rx_cycle_count == baud_rate_reg - 1) begin
                        rx_cycle_count <= 0;
                        if (rx == 1'b1) begin
                            // Load received byte into temp register and pulse done
                            rx_temp <= rx_shift_reg;
                            rx_done <= 1'b1;
                        end
                        rx_state <= RX_IDLE;
                    end else begin
                        rx_cycle_count <= rx_cycle_count + 1;
                    end
                end
                default: rx_state <= RX_IDLE;
            endcase
        end
    end

endmodule