#pragma once
#include <iostream>
#include <string>
#include <vector>
#include <cstdint>
#include <sstream>
#include <verilated.h>
#include <verilated_vcd_c.h>
#include "Vsoc_multicycle.h"

# define CYCLE_LIMIT 50
# define ROM_SIZE 1024
# define RAM_SIZE 1024

struct TestResult {
    std::string test_name;
    bool passed;
    std::string message;
};

class InstructionTest {
public:
    Vsoc_multicycle* dut;
    VerilatedVcdC* tfp = nullptr;
    vluint64_t sim_time = 0;
    std::vector<TestResult> results;

    // Helper function to convert uint32_t to hexadecimal string
    std::string to_hex(uint32_t value) {
        std::stringstream ss;
        ss << std::hex << value;
        return ss.str();
    }

    InstructionTest() {
        dut = new Vsoc_multicycle;
    }

    ~InstructionTest() {
        delete dut;
    }

    // Load instructions into ROM
    void load_instructions(const std::vector<uint32_t>& instructions) {
        for (size_t i = 0; i < instructions.size(); i++) {
            dut->soc_multicycle__DOT__rom_inst__DOT__rom_mem[i] = instructions[i];
        }

        // Fill remaining ROM with NOPs (0x00000013)
        for (size_t i = instructions.size(); i < ROM_SIZE; i++) {
            dut->soc_multicycle__DOT__rom_inst__DOT__rom_mem[i] = 0x00000013;
        }
    }

    void dump() {
        if (tfp) tfp->dump(sim_time);
        sim_time++;
    }

    // Run the simulation for a specified number of cycles
    void run_simulation(int cycles = CYCLE_LIMIT) {
        // Reset the DUT for 1 cycle
        dut->rst = 1;
        dut->clk = 1;
        dut->eval(); dump();

        dut->clk = 0;
        dut->eval(); dump();

        dut->rst = 0;
        dut->clk = 1;
        dut->eval(); dump();

        // Main simulation loop
        for (int i = 0; i < cycles; i++) {
            dut->clk = 0;
            dut->eval(); dump();
            dut->clk = 1;
            dut->eval(); dump();
        }
    }

    uint32_t read_register(int reg_num) {
        if (reg_num == 0) {
            return 0; // x0 is always 0
        }

        return dut->soc_multicycle__DOT__cpu_inst__DOT__regfile_inst__DOT__registers[reg_num];
    }

    uint32_t read_memory(int word_index) {
        return dut->soc_multicycle__DOT__ram_inst__DOT__ram_mem[word_index];
    }

    void run_test(const std::string& test_name, const std::vector<uint32_t>& instructions,
                  const std::vector<std::pair<int, uint32_t>>& expected_registers,
                  const std::vector<std::pair<int, uint32_t>>& expected_memory,
                  int cycles = CYCLE_LIMIT) {
        load_instructions(instructions);
        run_simulation(cycles);

        bool passed = true;
        std::string message;

        // Check register values
        for (const auto& [reg_num, expected_value] : expected_registers) {
            uint32_t actual_value = read_register(reg_num);
            if (actual_value != expected_value) {
                passed = false;
                message += "Register x" + std::to_string(reg_num) + ": expected 0x" +
                           to_hex(expected_value) + ", got 0x" + to_hex(actual_value) + "\n";
            }
        }

        // Check memory values
        for (const auto& [word_index, expected_value] : expected_memory) {
            uint32_t actual_value = read_memory(word_index);
            if (actual_value != expected_value) {
                passed = false;
                message += "Memory[" + std::to_string(word_index) + "]: expected 0x" +
                           to_hex(expected_value) + ", got 0x" + to_hex(actual_value) + "\n";
            }
        }

        results.push_back({test_name, passed, message});
    }

    void print_results() {
        for (const auto& result : results) {
            std::cout << "Test: " << result.test_name << " - " << (result.passed ? "PASSED" : "FAILED!!!!!") << "\n";
            if (!result.passed) {
                std::cout << result.message;
            }
        }
    }
};

// ============================================================
// Encoding note:
//   PC starts at 0x00000000 after reset.
//   Each word is stored little-endian in the hex vector.
//
// Cycle budget per instruction class (considering imem and dmem latencies of 1 cycle each):
//   ALU / branch / jump  : ~5 cycles  (FETCH,FETCH_WAIT,DECODE,EXECUTE,WRITEBACK)
//   LOAD                 : ~7 cycles  (+ MEMORY, MEMORY2)
//   STORE                : ~6 cycles  (+ MEMORY)
// ============================================================

void test_lui(InstructionTest& tester) {
    // ASM:
    //   lui x1, 0x12345       # x1 = 0x12345000
    tester.run_test(
        "LUI: x1 = 0x12345000",
        { 0x123450B7 },
        { {1, 0x12345000} },
        {}
    );
}

void test_auipc(InstructionTest& tester) {
    // ASM (PC=0 when instruction executes):
    //   auipc x1, 1           # x1 = PC(0) + 0x1000 = 0x00001000
    tester.run_test(
        "AUIPC: x1 = PC + 0x1000",
        { 0x00001097 },
        { {1, 0x00001000} },
        {}
    );
}

void test_addi(InstructionTest& tester) {
    // ASM:
    //   addi x1, x0, 42      # x1 = 42
    tester.run_test(
        "ADDI: x1 = x0 + 42",
        { 0x02A00093 },
        { {1, 42} },
        {}
    );
}

void test_slti(InstructionTest& tester) {
    // ASM:
    //   addi x1, x0, 3       # x1 = 3
    //   slti x2, x1, 10      # x2 = (3 <s 10) = 1
    tester.run_test(
        "SLTI: x2 = (x1 <s 10) = 1",
        { 0x00300093,   // addi x1, x0, 3
          0x00A0A113 }, // slti x2, x1, 10
        { {2, 1} },
        {}
    );
}

void test_sltiu(InstructionTest& tester) {
    // ASM:
    //   addi x1, x0, 3       # x1 = 3
    //   sltiu x2, x1, 10     # x2 = (3 <u 10) = 1
    tester.run_test(
        "SLTIU: x2 = (x1 <u 10) = 1",
        { 0x00300093,   // addi x1, x0, 3
          0x00A0B113 }, // sltiu x2, x1, 10
        { {2, 1} },
        {}
    );
}

void test_xori(InstructionTest& tester) {
    // ASM:
    //   addi x1, x0, 0xFF    # x1 = 0xFF
    //   xori x2, x1, 0x0F   # x2 = 0xFF ^ 0x0F = 0xF0
    tester.run_test(
        "XORI: x2 = 0xFF ^ 0x0F = 0xF0",
        { 0x0FF00093,   // addi x1, x0, 255
          0x00F0C113 }, // xori x2, x1, 15
        { {2, 0xF0} },
        {}
    );
}

void test_ori(InstructionTest& tester) {
    // ASM:
    //   addi x1, x0, 0xA0    # x1 = 0xA0
    //   ori  x2, x1, 0x0F   # x2 = 0xA0 | 0x0F = 0xAF
    tester.run_test(
        "ORI: x2 = 0xA0 | 0x0F = 0xAF",
        { 0x0A000093,   // addi x1, x0, 160
          0x00F0E113 }, // ori  x2, x1, 15
        { {2, 0xAF} },
        {}
    );
}

void test_andi(InstructionTest& tester) {
    // ASM:
    //   addi x1, x0, 0xFF    # x1 = 0xFF
    //   andi x2, x1, 0x0F   # x2 = 0xFF & 0x0F = 0x0F
    tester.run_test(
        "ANDI: x2 = 0xFF & 0x0F = 0x0F",
        { 0x0FF00093,   // addi x1, x0, 255
          0x00F0F113 }, // andi x2, x1, 15
        { {2, 0x0F} },
        {}
    );
}

void test_slli(InstructionTest& tester) {
    // ASM:
    //   addi x1, x0, 1       # x1 = 1
    //   slli x2, x1, 4       # x2 = 1 << 4 = 16
    tester.run_test(
        "SLLI: x2 = x1 << 4 = 16",
        { 0x00100093,   // addi x1, x0, 1
          0x00409113 }, // slli x2, x1, 4
        { {2, 16} },
        {}
    );
}

void test_srli(InstructionTest& tester) {
    // ASM:
    //   addi x1, x0, 64      # x1 = 64 = 0x40
    //   srli x2, x1, 2       # x2 = 64 >> 2 = 16 (logical)
    tester.run_test(
        "SRLI: x2 = 64 >>u 2 = 16",
        { 0x04000093,   // addi x1, x0, 64
          0x0020D113 }, // srli x2, x1, 2
        { {2, 16} },
        {}
    );
}

void test_srai(InstructionTest& tester) {
    // ASM:
    //   addi x1, x0, -8      # x1 = 0xFFFFFFF8 (-8)
    //   srai x2, x1, 1       # x2 = -8 >>s 1 = -4 = 0xFFFFFFFC
    tester.run_test(
        "SRAI: x2 = -8 >>s 1 = -4",
        { 0xFF800093,   // addi x1, x0, -8
          0x4010D113 }, // srai x2, x1, 1
        { {2, 0xFFFFFFFC} },
        {}
    );
}

void test_add(InstructionTest& tester) {
    // ASM:
    //   addi x1, x0, 10      # x1 = 10
    //   addi x2, x0, 20      # x2 = 20
    //   add  x3, x1, x2      # x3 = 30
    tester.run_test(
        "ADD: x3 = x1 + x2 = 30",
        { 0x00A00093,   // addi x1, x0, 10
          0x01400113,   // addi x2, x0, 20
          0x002081B3 }, // add  x3, x1, x2
        { {3, 30} },
        {}
    );
}

void test_sub(InstructionTest& tester) {
    // ASM:
    //   addi x1, x0, 20      # x1 = 20
    //   addi x2, x0, 5       # x2 = 5
    //   sub  x3, x1, x2      # x3 = 15
    tester.run_test(
        "SUB: x3 = x1 - x2 = 15",
        { 0x01400093,   // addi x1, x0, 20
          0x00500113,   // addi x2, x0, 5
          0x402081B3 }, // sub  x3, x1, x2
        { {3, 15} },
        {}
    );
}

void test_sll(InstructionTest& tester) {
    // ASM:
    //   addi x1, x0, 1       # x1 = 1
    //   addi x2, x0, 3       # x2 = 3
    //   sll  x3, x1, x2      # x3 = 1 << 3 = 8
    tester.run_test(
        "SLL: x3 = x1 << x2 = 8",
        { 0x00100093,   // addi x1, x0, 1
          0x00300113,   // addi x2, x0, 3
          0x002091B3 }, // sll  x3, x1, x2
        { {3, 8} },
        {}
    );
}

void test_slt(InstructionTest& tester) {
    // ASM:
    //   addi x1, x0, 5       # x1 = 5
    //   addi x2, x0, 10      # x2 = 10
    //   slt  x3, x1, x2      # x3 = (5 <s 10) = 1
    tester.run_test(
        "SLT: x3 = (x1 <s x2) = 1",
        { 0x00500093,   // addi x1, x0, 5
          0x00A00113,   // addi x2, x0, 10
          0x0020A1B3 }, // slt  x3, x1, x2
        { {3, 1} },
        {}
    );
}

void test_sltu(InstructionTest& tester) {
    // ASM:
    //   addi x1, x0, 5       # x1 = 5
    //   addi x2, x0, 10      # x2 = 10
    //   sltu x3, x1, x2      # x3 = (5 <u 10) = 1
    tester.run_test(
        "SLTU: x3 = (x1 <u x2) = 1",
        { 0x00500093,   // addi x1, x0, 5
          0x00A00113,   // addi x2, x0, 10
          0x0020B1B3 }, // sltu x3, x1, x2
        { {3, 1} },
        {}
    );
}

void test_xor(InstructionTest& tester) {
    // ASM:
    //   addi x1, x0, 0xFF    # x1 = 0xFF
    //   addi x2, x0, 0x0F   # x2 = 0x0F
    //   xor  x3, x1, x2      # x3 = 0xFF ^ 0x0F = 0xF0
    tester.run_test(
        "XOR: x3 = 0xFF ^ 0x0F = 0xF0",
        { 0x0FF00093,   // addi x1, x0, 255
          0x00F00113,   // addi x2, x0, 15
          0x0020C1B3 }, // xor  x3, x1, x2
        { {3, 0xF0} },
        {}
    );
}

void test_srl(InstructionTest& tester) {
    // ASM:
    //   addi x1, x0, 64      # x1 = 64
    //   addi x2, x0, 2       # x2 = 2
    //   srl  x3, x1, x2      # x3 = 64 >>u 2 = 16
    tester.run_test(
        "SRL: x3 = 64 >>u 2 = 16",
        { 0x04000093,   // addi x1, x0, 64
          0x00200113,   // addi x2, x0, 2
          0x0020D1B3 }, // srl  x3, x1, x2
        { {3, 16} },
        {}
    );
}

void test_sra(InstructionTest& tester) {
    // ASM:
    //   addi x1, x0, -8      # x1 = -8
    //   addi x2, x0, 1       # x2 = 1
    //   sra  x3, x1, x2      # x3 = -8 >>s 1 = -4 = 0xFFFFFFFC
    tester.run_test(
        "SRA: x3 = -8 >>s 1 = -4",
        { 0xFF800093,   // addi x1, x0, -8
          0x00100113,   // addi x2, x0, 1
          0x4020D1B3 }, // sra  x3, x1, x2
        { {3, 0xFFFFFFFC} },
        {}
    );
}

void test_or(InstructionTest& tester) {
    // ASM:
    //   addi x1, x0, 0xA0    # x1 = 0xA0
    //   addi x2, x0, 0x0F   # x2 = 0x0F
    //   or   x3, x1, x2      # x3 = 0xA0 | 0x0F = 0xAF
    tester.run_test(
        "OR: x3 = 0xA0 | 0x0F = 0xAF",
        { 0x0A000093,   // addi x1, x0, 160
          0x00F00113,   // addi x2, x0, 15
          0x0020E1B3 }, // or   x3, x1, x2
        { {3, 0xAF} },
        {}
    );
}

void test_and(InstructionTest& tester) {
    // ASM:
    //   addi x1, x0, 0xFF    # x1 = 0xFF
    //   addi x2, x0, 0x0F   # x2 = 0x0F
    //   and  x3, x1, x2      # x3 = 0xFF & 0x0F = 0x0F
    tester.run_test(
        "AND: x3 = 0xFF & 0x0F = 0x0F",
        { 0x0FF00093,   // addi x1, x0, 255
          0x00F00113,   // addi x2, x0, 15
          0x0020F1B3 }, // and  x3, x1, x2
        { {3, 0x0F} },
        {}
    );
}

void test_lb(InstructionTest& tester) {
    // RAM word[0] is pre-filled with 0x000000AB before running.
    // ASM:
    //   addi x1, x0, 0       # x1 = 0 (base address)
    //   lb   x2, 0(x1)       # x2 = sign_ext(RAM[0][7:0]) = 0xAB -> 0xFFFFFFAB
    tester.dut->soc_multicycle__DOT__ram_inst__DOT__ram_mem[0] = 0x000000AB;
    tester.run_test(
        "LB: x2 = sign_ext(mem[0][7:0]) = 0xFFFFFFAB",
        { 0x00000093,   // addi x1, x0, 0
          0x00008103 }, // lb   x2, 0(x1)
        { {2, 0xFFFFFFAB} },
        {},
        40
    );
}

void test_lh(InstructionTest& tester) {
    // RAM word[0] = 0x00008005 -> halfword at offset 0 = 0x8005, sign-extended = 0xFFFF8005
    // ASM:
    //   addi x1, x0, 0       # x1 = 0
    //   lh   x2, 0(x1)       # x2 = sign_ext(0x8005) = 0xFFFF8005
    tester.dut->soc_multicycle__DOT__ram_inst__DOT__ram_mem[0] = 0x00008005;
    tester.run_test(
        "LH: x2 = sign_ext(mem[0][15:0]) = 0xFFFF8005",
        { 0x00000093,   // addi x1, x0, 0
          0x00009103 }, // lh   x2, 0(x1)
        { {2, 0xFFFF8005} },
        {},
        40
    );
}

void test_lw(InstructionTest& tester) {
    // RAM word[0] = 0xDEADBEEF
    // ASM:
    //   addi x1, x0, 0       # x1 = 0
    //   lw   x2, 0(x1)       # x2 = 0xDEADBEEF
    tester.dut->soc_multicycle__DOT__ram_inst__DOT__ram_mem[0] = 0xDEADBEEF;
    tester.run_test(
        "LW: x2 = mem[0] = 0xDEADBEEF",
        { 0x00000093,   // addi x1, x0, 0
          0x0000A103 }, // lw   x2, 0(x1)
        { {2, 0xDEADBEEF} },
        {},
        40
    );
}

void test_lbu(InstructionTest& tester) {
    // RAM word[0] = 0x000000AB -> byte 0 = 0xAB, zero-extended = 0x000000AB
    // ASM:
    //   addi x1, x0, 0
    //   lbu  x2, 0(x1)       # x2 = 0x000000AB (no sign extension)
    tester.dut->soc_multicycle__DOT__ram_inst__DOT__ram_mem[0] = 0x000000AB;
    tester.run_test(
        "LBU: x2 = zero_ext(mem[0][7:0]) = 0xAB",
        { 0x00000093,   // addi x1, x0, 0
          0x0000C103 }, // lbu  x2, 0(x1)
        { {2, 0xAB} },
        {},
        40
    );
}

void test_lhu(InstructionTest& tester) {
    // RAM word[0] = 0x00008005 -> halfword 0 = 0x8005, zero-extended = 0x00008005
    // ASM:
    //   addi x1, x0, 0
    //   lhu  x2, 0(x1)       # x2 = 0x00008005
    tester.dut->soc_multicycle__DOT__ram_inst__DOT__ram_mem[0] = 0x00008005;
    tester.run_test(
        "LHU: x2 = zero_ext(mem[0][15:0]) = 0x8005",
        { 0x00000093,   // addi x1, x0, 0
          0x0000D103 }, // lhu  x2, 0(x1)
        { {2, 0x00008005} },
        {},
        40
    );
}

void test_sb(InstructionTest& tester) {
    // ASM:
    //   addi x1, x0, 0xAB    # x1 = 0xAB
    //   addi x2, x0, 0       # x2 = 0 (address)
    //   sb   x1, 4(x2)       # mem[1][7:0] = 0xAB  (byte addr 4 -> word[1] byte 0)
    tester.run_test(
        "SB: mem[1][7:0] = 0xAB",
        { 0x0AB00093,   // addi x1, x0, 0xAB
          0x00000113,   // addi x2, x0, 0
          0x00110223 }, // sb   x1, 4(x2)
        {},
        { {1, 0x000000AB} },
        40
    );
}

void test_sh(InstructionTest& tester) {
    // ASM:
    //   addi x1, x0, 0x7FF   # x1 = 0x7FF
    //   addi x2, x0, 0       # x2 = 0
    //   sh   x1, 4(x2)       # mem[1][15:0] = 0x07FF
    tester.run_test(
        "SH: mem[1][15:0] = 0x07FF",
        { 0x7FF00093,   // addi x1, x0, 0x7FF
          0x00000113,   // addi x2, x0, 0
          0x00111223 }, // sh   x1, 4(x2)
        {},
        { {1, 0x000007FF} },
        40
    );
}

void test_sw(InstructionTest& tester) {
    // ASM:
    //   addi x1, x0, 0x7FF   # x1 = 0x7FF
    //   addi x2, x0, 0       # x2 = 0
    //   sw   x1, 4(x2)       # mem[1] = 0x000007FF
    tester.run_test(
        "SW: mem[1] = 0x000007FF",
        { 0x7FF00093,   // addi x1, x0, 0x7FF
          0x00000113,   // addi x2, x0, 0
          0x00112223 }, // sw   x1, 4(x2)
        {},
        { {1, 0x000007FF} },
        40
    );
}

void test_jal(InstructionTest& tester) {
    // ASM (PC=0):
    //   jal  x1, 8           # x1 = 4 (PC+4), jump to PC+8 = 0x8
    //   addi x2, x0, 99      # SKIPPED (at PC=4)
    //   addi x3, x0, 42      # Executed (at PC=8) -> x3 = 42
    tester.run_test(
        "JAL: jumps +8, x1=4, x2 skipped, x3=42",
        { 0x008000EF,   // jal  x1, 8
          0x06300113,   // addi x2, x0, 99  <- skipped
          0x02A00193 }, // addi x3, x0, 42
        { {1, 4}, {2, 0}, {3, 42} },
        {},
        30
    );
}

void test_jalr(InstructionTest& tester) {
    // ASM (PC=0):
    //   addi x1, x0, 12      # x1 = 12 (target address)
    //   jalr x2, x1, 0       # x2 = 8 (PC+4=8), jump to x1+0 = 12
    //   addi x3, x0, 99      # SKIPPED (at PC=8)
    //   addi x3, x0, 42      # Executed (at PC=12) -> x3 = 42
    tester.run_test(
        "JALR: jumps to x1=12, x2=8, x3 skipped then 42",
        { 0x00C00093,   // addi x1, x0, 12
          0x00008167,   // jalr x2, x1, 0
          0x06300193,   // addi x3, x0, 99  <- skipped
          0x02A00193 }, // addi x3, x0, 42
        { {2, 8}, {3, 42} },
        {},
        40
    );
}

void test_beq(InstructionTest& tester) {
    // ASM (PC=0):
    //   addi x1, x0, 5       # x1 = 5
    //   addi x2, x0, 5       # x2 = 5
    //   beq  x1, x2, 8       # taken (5==5): jump to PC_of_beq(8) + 8 = 16
    //   addi x3, x0, 99      # SKIPPED (PC=12)
    //   addi x3, x0, 42      # Executed (PC=16) -> x3 = 42
    tester.run_test(
        "BEQ taken: x3=42 (skips 99)",
        { 0x00500093,   // addi x1, x0, 5
          0x00500113,   // addi x2, x0, 5
          0x00208463,   // beq  x1, x2, 8
          0x06300193,   // addi x3, x0, 99  <- skipped
          0x02A00193 }, // addi x3, x0, 42
        { {3, 42} },
        {},
        40
    );
}

void test_bne(InstructionTest& tester) {
    // ASM (PC=0):
    //   addi x1, x0, 5
    //   addi x2, x0, 7       # x1 != x2
    //   bne  x1, x2, 8       # taken: skip next, land at PC=16
    //   addi x3, x0, 99      # SKIPPED
    //   addi x3, x0, 42      # Executed -> x3 = 42
    tester.run_test(
        "BNE taken: x3=42 (skips 99)",
        { 0x00500093,   // addi x1, x0, 5
          0x00700113,   // addi x2, x0, 7
          0x00209463,   // bne  x1, x2, 8
          0x06300193,   // addi x3, x0, 99  <- skipped
          0x02A00193 }, // addi x3, x0, 42
        { {3, 42} },
        {},
        40
    );
}

void test_blt(InstructionTest& tester) {
    // ASM:
    //   addi x1, x0, 3
    //   addi x2, x0, 10
    //   blt  x1, x2, 8       # taken (3 <s 10): skip next
    //   addi x3, x0, 99      # SKIPPED
    //   addi x3, x0, 42      # Executed -> x3 = 42
    tester.run_test(
        "BLT taken: x3=42 (skips 99)",
        { 0x00300093,   // addi x1, x0, 3
          0x00A00113,   // addi x2, x0, 10
          0x0020C463,   // blt  x1, x2, 8
          0x06300193,   // addi x3, x0, 99  <- skipped
          0x02A00193 }, // addi x3, x0, 42
        { {3, 42} },
        {},
        40
    );
}

void test_bge(InstructionTest& tester) {
    // ASM:
    //   addi x1, x0, 10
    //   addi x2, x0, 3
    //   bge  x1, x2, 8       # taken (10 >=s 3): skip next
    //   addi x3, x0, 99      # SKIPPED
    //   addi x3, x0, 42      # Executed -> x3 = 42
    tester.run_test(
        "BGE taken: x3=42 (skips 99)",
        { 0x00A00093,   // addi x1, x0, 10
          0x00300113,   // addi x2, x0, 3
          0x0020D463,   // bge  x1, x2, 8
          0x06300193,   // addi x3, x0, 99  <- skipped
          0x02A00193 }, // addi x3, x0, 42
        { {3, 42} },
        {},
        40
    );
}

void test_bltu(InstructionTest& tester) {
    // ASM:
    //   addi x1, x0, 3
    //   addi x2, x0, 10
    //   bltu x1, x2, 8       # taken (3 <u 10): skip next
    //   addi x3, x0, 99      # SKIPPED
    //   addi x3, x0, 42      # Executed -> x3 = 42
    tester.run_test(
        "BLTU taken: x3=42 (skips 99)",
        { 0x00300093,   // addi x1, x0, 3
          0x00A00113,   // addi x2, x0, 10
          0x0020E463,   // bltu x1, x2, 8
          0x06300193,   // addi x3, x0, 99  <- skipped
          0x02A00193 }, // addi x3, x0, 42
        { {3, 42} },
        {},
        40
    );
}

void test_bgeu(InstructionTest& tester) {
    // ASM:
    //   addi x1, x0, 10
    //   addi x2, x0, 3
    //   bgeu x1, x2, 8       # taken (10 >=u 3): skip next
    //   addi x3, x0, 99      # SKIPPED
    //   addi x3, x0, 42      # Executed -> x3 = 42
    tester.run_test(
        "BGEU taken: x3=42 (skips 99)",
        { 0x00A00093,   // addi x1, x0, 10
          0x00300113,   // addi x2, x0, 3
          0x0020F463,   // bgeu x1, x2, 8
          0x06300193,   // addi x3, x0, 99  <- skipped
          0x02A00193 }, // addi x3, x0, 42
        { {3, 42} },
        {},
        40
    );
}

void test_fibo(InstructionTest& tester) {
    // ASM:
    //   addi x1, x0, 1
    //   sw x1, 0(x0)
    //   sw x1, 4(x0)
    //   
    //   addi x10, x0, 10
    //   
    //   loop:
    //   lw x1, 0(x0)
    //   lw x2, 4(x0)
    //   add x3, x1, x2
    //   sw x2, 0(x0)
    //   sw x3, 4(x0)
    //   addi x11, x0, 1
    //   sub x10, x10, x11
    //   bne x10, x0, loop
    tester.run_test(
        "Fibonacci loop: computes 12th Fibonacci number = 144",
        { 0x00100093,
          0x00102023,
          0x00102223,
          0x00a00513,
          0x00002083,
          0x00402103,
          0x002081b3,
          0x00202023,
          0x00302223,
          0x00100593,
          0x40b50533,
          0xfe0512e3 },
          { {1, 55}, {2, 89}, {3, 144}, {10, 0} },
          { {0, 0x00000059}, {1, 0x00000090} },
          1000
    );
}