module soc_multicycle #(
    parameter IMEM_LATENCY = 1,  // cycles before imem asserts ready
    parameter DMEM_LATENCY = 1,   // cycles before dmem asserts ready
    parameter UART_LATENCY = 1   // cycles before uart asserts ready
) (
    input wire clk,
    input wire rst
);

    // Internal signals
    // CPU <-> ROM
    wire [31:0] rom_addr;
    wire [31:0] rom_data;
    wire rom_req;
    wire rom_ready;

    // CPU <-> BC
    wire [31:0] cpu_addr;
    wire [31:0] cpu_wdata;
    wire [31:0] cpu_rdata;
    wire cpu_we;
    wire [2:0] cpu_mode;
    wire cpu_req;
    wire cpu_ready;

    // BC <-> RAM / UART
    wire [31:0] mem_addr;
    wire [31:0] mem_wdata;
    wire [31:0] mem_rdata [1:0]; // 0: dmem data, 1: uart data
    wire mem_we;
    wire [2:0] mem_mode;
    wire [1:0] mem_req; // 01: dmem, 10: uart
    wire [1:0] mem_ready; // 01: dmem, 10: uart

    // UART Tx/Rx lines
    wire uart_tx;
    wire uart_rx;

    // CPU instantiation
    cpu_multicycle cpu_inst (
        .clk(clk),
        .rst(rst),
        .o_rom_addr(rom_addr),
        .i_rom_data(rom_data),
        .o_ram_addr(cpu_addr),
        .o_ram_wdata(cpu_wdata),
        .i_ram_rdata(cpu_rdata),
        .o_ram_we(cpu_we),
        .o_ram_mode(cpu_mode),
        .o_rom_req(rom_req),
        .i_rom_ready(rom_ready),
        .o_ram_req(cpu_req),
        .i_ram_ready(cpu_ready)
    );

    // ROM instantiation
    imem_sync #(.LATENCY(IMEM_LATENCY)) rom_inst (
        .clk(clk),
        .rst(rst),
        .address(rom_addr),
        .read_data(rom_data),
        .req(rom_req),
        .ready(rom_ready)
    );

    // RAM instantiation
    dmem_sync #(.LATENCY(DMEM_LATENCY)) ram_inst (
        .clk(clk),
        .rst(rst),
        .address(mem_addr),
        .write_data(mem_wdata),
        .read_data(mem_rdata[0]),
        .we(mem_we),
        .mode(mem_mode),
        .req(mem_req[0]), 
        .ready(mem_ready[0])
    );

    // UART instantiation
    uart #(.LATENCY(UART_LATENCY)) uart_inst (
        .clk(clk),
        .rst(rst),
        .address(mem_addr),
        .write_data(mem_wdata),
        .read_data(mem_rdata[1]),
        .we(mem_we),
        .mode(mem_mode),
        .req(mem_req[1]), 
        .ready(mem_ready[1]),
        .tx(uart_tx),
        .rx(uart_rx)
    );

    // Bus controller instantiation
    bus_controller bus_ctrl_inst (
        .clk(clk),
        .rst(rst),
        // CPU Interface
        .cpu_address(cpu_addr),
        .cpu_write_data(cpu_wdata),
        .cpu_read_data(cpu_rdata),
        .cpu_we(cpu_we),
        .cpu_mode(cpu_mode),
        .cpu_req(cpu_req),
        .cpu_ready(cpu_ready),
        // Memory Interface
        .mem_address(mem_addr),
        .mem_write_data(mem_wdata),
        .mem_read_data(mem_rdata),
        .mem_we(mem_we),
        .mem_mode(mem_mode),
        .mem_req(mem_req),
        .mem_ready(mem_ready)
    ); 

endmodule