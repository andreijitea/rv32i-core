module soc_multicycle (
    input wire clk,
    input wire rst
);

    // Internal signals
    wire [31:0] rom_addr;
    wire [31:0] rom_data;

    wire [31:0] ram_addr;
    wire [31:0] ram_wdata;
    wire [31:0] ram_rdata;
    wire ram_we;
    wire [2:0] ram_mode;


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
        .o_ram_mode(ram_mode)
    );

    // ROM instantiation
    imem_sync rom_inst (
        .clk(clk),
        .rst(rst),
        .address(rom_addr),
        .read_data(rom_data)
    );

    // RAM instantiation
    dmem_sync ram_inst (
        .clk(clk),
        .rst(rst),
        .address(ram_addr),
        .write_data(ram_wdata),
        .read_data(ram_rdata),
        .we(ram_we),
        .mode(ram_mode)
    );

endmodule