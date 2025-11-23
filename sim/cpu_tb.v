`timescale 1ns/1ps

module cpu_tb;

    reg clk;
    reg rst;

    // Instantiate CPU
    cpu dut (
        .clk(clk),
        .rst(rst)
    );

    // Clock generation (10ns period = 100MHz)
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // Test sequence
    initial begin
        // Reset sequence
        rst = 1;
        #20;
        rst = 0;
        
        $display("Starting CPU test...");

        // Run for 200 clock cycles
        #2000;
        
        $display("\nFinal Register State:");
        $display("x1 = %h", dut.rf_inst.registers[1]);
        $display("x2 = %h", dut.rf_inst.registers[2]);
        $display("x3 = %h", dut.rf_inst.registers[3]);
        $display("x4 = %h", dut.rf_inst.registers[4]);
        $display("x5 = %h", dut.rf_inst.registers[5]);

        // Display first 5 words of data memory
        $display("\nData Memory (first 5 words):");
        $display("Addr 0x00: %h", {dut.dm_inst.mem[3], dut.dm_inst.mem[2], dut.dm_inst.mem[1], dut.dm_inst.mem[0]});
        $display("Addr 0x04: %h", {dut.dm_inst.mem[7], dut.dm_inst.mem[6], dut.dm_inst.mem[5], dut.dm_inst.mem[4]});
        $display("Addr 0x08: %h", {dut.dm_inst.mem[11], dut.dm_inst.mem[10], dut.dm_inst.mem[9], dut.dm_inst.mem[8]});
        $display("Addr 0x0C: %h", {dut.dm_inst.mem[15], dut.dm_inst.mem[14], dut.dm_inst.mem[13], dut.dm_inst.mem[12]});
        $display("Addr 0x10: %h", {dut.dm_inst.mem[19], dut.dm_inst.mem[18], dut.dm_inst.mem[17], dut.dm_inst.mem[16]});
        
        $finish;
    end

endmodule