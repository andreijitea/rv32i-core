# RV32I Single-Cycle Processor

A complete implementation of a 32-bit RISC-V (RV32I) single-cycle processor in Verilog. So far, it supports 37 instructions from the RV32I base integer instruction set. In the future, more instructions and features may be added.

## Overview

This project implements the base RISC-V 32-bit integer instruction set (RV32I) using a single-cycle microarchitecture. The processor executes one instruction per clock cycle and includes all necessary datapath components and control logic.

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

### Architecture Components

- **Program Counter (PC)**: 32-bit program counter with reset capability
- **Instruction Memory**: 256-word instruction ROM with hex file loading
- **Register File**: 32 general-purpose registers (x0-x31), x0 hardwired to zero
- **ALU**: 10 operations with zero, negative, and carry flag generation
- **Data Memory**: 1KB byte-addressable RAM with byte/halfword/word access
- **Control Unit**: Fully decoded FSM-based controller
- **Immediate Extender**: Supports all 6 RISC-V immediate formats (I, S, B, U, J, R)

### Key Design Features

- **Flag-based branching**: Uses zero, negative, and carry flags for efficient branch comparison
- **Flexible memory access**: Supports signed/unsigned byte, halfword, and word operations
- **Clean modular design**: Separated datapath and control logic
- **PC multiplexing**: 4-way mux supporting sequential execution, branches, and jumps (JAL/JALR)
- **ALU input multiplexing**: Supports AUIPC by selecting PC as ALU input


## Building and Running

### Prerequisites

- Icarus Verilog (iverilog) - Verilog simulator
- GTKWave (optional) - Waveform viewer

### Quick Start

```bash
# Run simulation
make simulate

# Clean build artifacts
make clean
```

## Testing

The current testbench (`sim/cpu_tb.v`) validates basic functionality:
- Arithmetic and logical operations
- Memory load/store operations
- Data memory persistence

*Note: In the future, more comprehensive testbenches will be added to cover all instructions and edge cases.*

## References

- [RISC-V ISA Specification](https://riscv.org/technical/specifications/)
- [RISC-V Instruction Set Reference](https://msyksphinz-self.github.io/riscv-isadoc/html/index.html)
- [Digital Design and Computer Architecture: RISC-V Edition by Harris & Harris](https://shop.elsevier.com/books/digital-design-and-computer-architecture-risc-v-edition/harris/978-0-12-820064-3)