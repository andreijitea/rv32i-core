// Memory Map Definitions
// Instruction Memory (ROM) address range
`define ROM_START_ADDR 32'h0000_0000
`define ROM_SIZE       32'h0000_0400  // 1KB
`define ROM_END_ADDR   32'h0000_03FF

// Data Memory (RAM) address range
`define RAM_START_ADDR 32'h0000_0400
`define RAM_SIZE       32'h0000_0400  // 1KB
`define RAM_END_ADDR   32'h0000_07FF

// Future peripheral address ranges:
`define PERIPH_START_ADDR 32'h0000_0800