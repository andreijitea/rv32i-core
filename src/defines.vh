// ALU Control Signals
`define ALU_ADD   4'b0000
`define ALU_SUB   4'b0001
`define ALU_AND   4'b0010
`define ALU_OR    4'b0011
`define ALU_XOR   4'b0100
`define ALU_SLT   4'b0101
`define ALU_SLTU  4'b0110
`define ALU_SLL   4'b0111
`define ALU_SRL   4'b1000
`define ALU_SRA   4'b1001

// Immediate Source Signals
`define IMM_I_TYPE 3'b000
`define IMM_S_TYPE 3'b001
`define IMM_B_TYPE 3'b010
`define IMM_U_TYPE 3'b011
`define IMM_J_TYPE 3'b100
`define IMM_R_TYPE 3'b101

// Data Memory Mode Signals
`define DM_LB 3'b000
`define DM_LH 3'b001
`define DM_LW 3'b010
`define DM_LBU 3'b011
`define DM_LHU 3'b100
`define DM_SB 3'b101
`define DM_SH 3'b110
`define DM_SW 3'b111