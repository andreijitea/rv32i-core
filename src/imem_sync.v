module imem_sync (
    input wire clk,
    input wire rst,
    
    input wire [31:0] address,
    output reg [31:0] read_data
);

    // 32 bit wide ROM with 1024 words (4KB)
    reg [31:0] rom_mem [0:1023];

    // Initialize ROM from external file
    initial begin
        $readmemh("../sim/instructions.hex", rom_mem);
    end

    // Synchronous read
    always @(posedge clk) begin
        if (rst) begin
            read_data <= 32'b0;
        end else begin
            read_data <= rom_mem[address[11:2]]; // Word-aligned addressing
        end
    end
endmodule