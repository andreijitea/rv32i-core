#include <iostream>
#include <iomanip>
#include <verilated.h>
#include <verilated_vcd_c.h>
#include "Vsoc_multicycle.h"

#define MAX_SIM_TIME 200
#define CLK_PERIOD 10

vluint64_t sim_time = 0;

int main(int argc, char** argv) {
    Verilated::commandArgs(argc, argv);
    
    // Create DUT instance
    Vsoc_multicycle* dut = new Vsoc_multicycle;
    
    // Enable tracing
    Verilated::traceEverOn(true);
    VerilatedVcdC* tfp = new VerilatedVcdC;
    dut->trace(tfp, 99);
    tfp->open("soc_tb.vcd");
    
    std::cout << "Starting multicycle SOC test..." << std::endl;
    
    // Reset for 1 clock cycle
    dut->rst = 1;
    dut->clk = 1;
    dut->eval();
    tfp->dump(sim_time++);

    dut->clk = 0;
    dut->eval();
    tfp->dump(sim_time++);

    dut->rst = 0;
    dut->clk = 1;
    dut->eval();
    tfp->dump(sim_time++);

    // Main simulation loop
    while (sim_time < MAX_SIM_TIME) {
        // Toggle clock
        dut->clk = 0;
        dut->eval();
        tfp->dump(sim_time++);

        dut->clk = 1;
        dut->eval();
        tfp->dump(sim_time++);
    }
    
    std::cout << "Simulation finished at time " << sim_time << std::endl;
    std::cout << "First 5 register values:" << std::endl;
    for (int i = 1; i <= 5; i++) {
        std::cout << "R" << i << ": 0x" 
                  << std::hex << std::setw(8) << std::setfill('0') 
                  << dut->soc_multicycle__DOT__cpu_inst__DOT__regfile_inst__DOT__registers[i] 
                  << std::dec << std::endl;
    }

    std::cout << "First 10 memory locations:" << std::endl;
    for (int i = 0; i < 10; i++) {
        std::cout << "Mem[" << i << "]: 0x" 
                  << std::hex << std::setw(8) << std::setfill('0') 
                  << dut->soc_multicycle__DOT__ram_inst__DOT__ram_mem[i] 
                  << std::dec << std::endl;
    }
    
    // Final evaluation
    dut->eval();
    
    // Cleanup
    tfp->close();
    delete tfp;
    delete dut;
    
    return 0;
}