module instruction_memory (
    input  wire [31:0] addr,
    output wire [31:0] instruction
);

    // Only 256 words of instruction memory for simplicity
    reg [31:0] memory [0:255];

    initial begin
        $readmemh("../sim/instructions.hex", memory);
    end

    assign instruction = memory[addr[9:2]]; // Word-aligned addressing

endmodule