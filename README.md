# RV32I Core Processor

A complete implementation of a 32-bit RISC-V (RV32I) multicycle processor in Verilog. Supports 37 instructions from the RV32I base integer instruction set. Originally started as a single-cycle design, it was upgraded to a multicycle architecture to support synchronous ROM/RAM.

## Overview

This project implements the base RISC-V 32-bit integer instruction set (RV32I) using a multicycle microarchitecture. Unlike single-cycle designs, instructions take multiple clock cycles to complete, allowing the use of synchronous memories (realistic for FPGA/ASIC implementation) and resource sharing between stages.

**Note**: This is an educational implementation designed for learning computer architecture and digital design. Not intended for production use.

## Features

### Implemented Instructions (37 total)

**User-Level Instructions (U-mode):**
- **Arithmetic**: ADD, SUB, ADDI
- **Logical**: AND, OR, XOR, ANDI, ORI, XORI
- **Shift**: SLL, SRL, SRA, SLLI, SRLI, SRAI
- **Comparison**: SLT, SLTU, SLTI, SLTIU
- **Memory Access**: LB, LH, LW, LBU, LHU, SB, SH, SW
- **Control Flow**: BEQ, BNE, BLT, BGE, BLTU, BGEU, JAL, JALR
- **Upper Immediate**: LUI, AUIPC

### Multicycle Architecture

The processor uses a FSM controller with the following states:

| State | Description |
|-------|-------------|
| FETCH | Set up ROM address (PC) |
| FETCH2 | Capture instruction from synchronous ROM into IR |
| DECODE | Decode instruction, read registers, compute immediate |
| EXECUTE | Perform ALU operation, compute branch/jump targets, update PC |
| MEMORY | Memory access for load/store instructions |
| MEMORY2 | Capture load data from synchronous RAM into MDR |
| WRITEBACK | Write result back to register file |

### Cycle Counts by Instruction Type

| Instruction Type | Cycles | States Used |
|-----------------|--------|-------------|
| R-type (ADD, SUB, etc.) | 5 | FETCH → FETCH2 → DECODE → EXECUTE → WRITEBACK |
| I-type ALU (ADDI, etc.) | 5 | FETCH → FETCH2 → DECODE → EXECUTE → WRITEBACK |
| Load (LW, LB, etc.) | 7 | FETCH → FETCH2 → DECODE → EXECUTE → MEMORY → MEMORY2 → WRITEBACK |
| Store (SW, SB, etc.) | 5 | FETCH → FETCH2 → DECODE → EXECUTE → MEMORY |
| Branch (BEQ, BNE, etc.) | 4 | FETCH → FETCH2 → DECODE → EXECUTE |
| JAL | 5 | FETCH → FETCH2 → DECODE → EXECUTE → WRITEBACK |
| JALR | 5 | FETCH → FETCH2 → DECODE → EXECUTE → WRITEBACK |
| LUI, AUIPC | 5 | FETCH → FETCH2 → DECODE → EXECUTE → WRITEBACK |

### Architecture Components

- **Program Counter (PC)**: 32-bit program counter with write-enable gating
- **Instruction Memory**: 4KB synchronous ROM with hex file loading
- **Instruction Register (IR)**: Latches instruction for multi-cycle decoding
- **Register File**: 32 general-purpose registers (x0-x31), x0 hardwired to zero
- **ALU**: 10 operations with zero, negative, and carry flag generation
- **Data Memory**: 4KB synchronous RAM with byte/halfword/word access
- **Memory Data Register (MDR)**: Latches data from synchronous RAM
- **Controller FSM**: Multi-state controller generating all control signals
- **Immediate Extender**: Supports all 6 RISC-V immediate formats (I, S, B, U, J, R)
- **Datapath Registers**: `reg32b` modules for latching values between pipeline stages (regA, regB, ALUOut, ImmOut, OldPC)

### Key Design Features

- **Synchronous memories**: Compatible with FPGA block RAM and realistic ASIC memories
- **Clean datapath**: All sequential elements use dedicated `reg32b` modules with write-enable control
- **Flag-based branching**: Uses zero, negative, and carry flags for efficient branch comparison
- **Flexible memory access**: Supports signed/unsigned byte, halfword, and word operations
- **Modular design**: Separated datapath and control logic
- **PC latching**: Old PC is saved during DECODE for correct JAL/JALR return address calculation


## Building and Running

### Prerequisites

- Verilator (recommended) - converts Verilog to a fast C++ model and builds a C++ testbench
- GCC / g++ - to compile the generated model and testbench
- GTKWave (optional) - waveform viewer

Note: I updated the repository to use Verilator instead of Icarus Verilog for simulation.

### Quick Start (Verilator)

From the project root run:

```bash
# Generate, build and run the Verilator C++ testbench
make simulate

# View waveforms
make wave

# Clean build artifacts
make clean
```

## Testing

The current testbench (`sim/soc_tb.v`) validates basic functionality:
- Arithmetic and logical operations
- Memory load/store operations
- Data memory persistence

*Note: In the future, more comprehensive testbenches will be added to cover all instructions and edge cases.*

## References

- [RISC-V ISA Specification](https://riscv.org/technical/specifications/)
- [RISC-V Instruction Set Reference](https://msyksphinz-self.github.io/riscv-isadoc/html/index.html)
- [Digital Design and Computer Architecture: RISC-V Edition by Harris & Harris](https://shop.elsevier.com/books/digital-design-and-computer-architecture-risc-v-edition/harris/978-0-12-820064-3)