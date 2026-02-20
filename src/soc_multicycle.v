module soc_multicycle #(
    parameter IMEM_LATENCY = 1,  // cycles before imem asserts ready
    parameter DMEM_LATENCY = 1   // cycles before dmem asserts ready
) (
    input wire clk,
    input wire rst
);

    // Internal signals
    wire [31:0] rom_addr;
    wire [31:0] rom_data;
    wire rom_req;
    wire rom_ready;

    wire [31:0] ram_addr;
    wire [31:0] ram_wdata;
    wire [31:0] ram_rdata;
    wire ram_we;
    wire [2:0] ram_mode;
    wire ram_req;
    wire ram_ready;


    // CPU instantiation
    cpu_multicycle cpu_inst (
        .clk(clk),
        .rst(rst),
        .o_rom_addr(rom_addr),
        .i_rom_data(rom_data),
        .o_ram_addr(ram_addr),
        .o_ram_wdata(ram_wdata),
        .i_ram_rdata(ram_rdata),
        .o_ram_we(ram_we),
        .o_ram_mode(ram_mode),
        .o_rom_req(rom_req),
        .i_rom_ready(rom_ready),
        .o_ram_req(ram_req),
        .i_ram_ready(ram_ready)
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
        .address(ram_addr),
        .write_data(ram_wdata),
        .read_data(ram_rdata),
        .we(ram_we),
        .mode(ram_mode),
        .req(ram_req),
        .ready(ram_ready)
    );

endmodule