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

        // Current instructions in instructions.hex:
        // addi x1, x0, 30
        // addi x2, x0, 23
        // beq x1, x2, br_equal
        // bge x1, x2, br_greater
        // sw x1, 0x400(x0)
        // 
        // br_greater:
        // sub x3, x0, x1
        // 
        // br_equal:
        // sw x2, 0x400(x0)
        
        $display("\nFinal Register State:");
        $display("x1 = %h", dut.rf_inst.registers[1]);
        $display("x2 = %h", dut.rf_inst.registers[2]);
        $display("x3 = %h", dut.rf_inst.registers[3]);
        $display("x4 = %h", dut.rf_inst.registers[4]);
        $display("x5 = %h", dut.rf_inst.registers[5]);

        // Display first 5 words of data memory
        $display("\nData Memory (first 5 words):");
        $display("Addr 0x0400: %h", dut.dm_inst.mem[0]);
        $display("Addr 0x0404: %h", dut.dm_inst.mem[1]);
        $display("Addr 0x0408: %h", dut.dm_inst.mem[2]);
        $display("Addr 0x040C: %h", dut.dm_inst.mem[3]);
        $display("Addr 0x0410: %h", dut.dm_inst.mem[4]);
        
        $finish;
    end

endmodule