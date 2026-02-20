#include <iostream>
#include <verilated.h>
#include <verilated_vcd_c.h>
#include "Vsoc_multicycle.h"
#include "instruction_tests.hpp"

int main(int argc, char** argv) {
    Verilated::commandArgs(argc, argv);
    Verilated::traceEverOn(true);

    InstructionTest tester;

    VerilatedVcdC* tfp = new VerilatedVcdC;
    tester.dut->trace(tfp, 99);
    tfp->open("soc_tb.vcd");
    tester.tfp = tfp;

    std::cout << "=== RV32I Instruction Tests ===\n\n";

    test_lui(tester);
    test_auipc(tester);

    test_addi(tester);
    test_slti(tester);
    test_sltiu(tester);
    test_xori(tester);
    test_ori(tester);
    test_andi(tester);
    test_slli(tester);
    test_srli(tester);
    test_srai(tester);

    test_add(tester);
    test_sub(tester);
    test_sll(tester);
    test_slt(tester);
    test_sltu(tester);
    test_xor(tester);
    test_srl(tester);
    test_sra(tester);
    test_or(tester);
    test_and(tester);

    test_lb(tester);
    test_lh(tester);
    test_lw(tester);
    test_lbu(tester);
    test_lhu(tester);

    test_sb(tester);
    test_sh(tester);
    test_sw(tester);

    test_jal(tester);
    test_jalr(tester);

    test_beq(tester);
    test_bne(tester);
    test_blt(tester);
    test_bge(tester);
    test_bltu(tester);
    test_bgeu(tester);

    test_fibo(tester);

    tester.print_results();

    tfp->close();
    delete tfp;

    // Return non-zero if any test failed
    int failed = 0;
    for (const auto& r : tester.results)
        if (!r.passed) failed++;
    return failed;
}