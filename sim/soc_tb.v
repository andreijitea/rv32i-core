`timescale 1ns/1ps

module soc_tb;
    reg clk;
    reg rst;

    // Instantiate SoC
    soc_multicycle dut (
        .clk(clk),
        .rst(rst)
    );

    // Clock
    initial begin
        clk = 1;
        forever #5 clk = ~clk; // 100MHz
    end

    initial begin
        // Waveform dump
        $dumpfile("soc_tb.vcd");
        $dumpvars(0, soc_tb);
        $dumpvars(0, dut);

        // Reset
        rst = 1;
        #10;
        rst = 0;

        $display("Starting multicycle SOC test...");

        // Run for a while
        #2000;

        $display("Simulation finished");

        $display("First 5 registers:");
        $display("x1: %h", dut.cpu_inst.regfile_inst.registers[1]);
        $display("x2: %h", dut.cpu_inst.regfile_inst.registers[2]);
        $display("x3: %h", dut.cpu_inst.regfile_inst.registers[3]);
        $display("x4: %h", dut.cpu_inst.regfile_inst.registers[4]);
        $display("x5: %h", dut.cpu_inst.regfile_inst.registers[5]);

        $display("First 5 memory locations:");
        $display("mem[0]: %h", dut.ram_inst.ram_mem[0]);
        $display("mem[1]: %h", dut.ram_inst.ram_mem[1]);
        $display("mem[2]: %h", dut.ram_inst.ram_mem[2]);
        $display("mem[3]: %h", dut.ram_inst.ram_mem[3]);
        $display("mem[4]: %h", dut.ram_inst.ram_mem[4]);

        $finish;
    end
endmodule
