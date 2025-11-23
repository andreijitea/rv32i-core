module register_file (
    input wire clk,
    input wire rst,
    input wire [4:0] rs1_addr,
    input wire [4:0] rs2_addr,
    input wire [4:0] rd_addr,
    input wire [31:0] rd_data,
    input wire rd_we,
    output wire [31:0] rs1_data,
    output wire [31:0] rs2_data
);

    reg [31:0] registers [0:31];

    // Read ports
    assign rs1_data = registers[rs1_addr];
    assign rs2_data = registers[rs2_addr];

    // Write port
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            integer i;
            for (i = 0; i < 32; i = i + 1) begin
                registers[i] <= 32'b0;
            end
        end else if (rd_we && rd_addr != 5'b0) begin
            registers[rd_addr] <= rd_data;
        end
    end

endmodule