// Banco de registros MIPS de 32 registros x 32 bits.
module RegisterFile(
    input clk,
    input RegWrite,
    input [4:0] rs,
    input [4:0] rt,
    input [4:0] rd,
    input [31:0] write_data,
    output [31:0] read_data1,
    output [31:0] read_data2
);
    reg [31:0] registers [0:31];
    integer i;

    initial begin
        for (i = 0; i < 32; i = i + 1) begin
            registers[i] = 32'd0;
        end
    end

    assign read_data1 = (rs == 5'd0) ? 32'd0 : registers[rs];
    assign read_data2 = (rt == 5'd0) ? 32'd0 : registers[rt];

    always @(posedge clk) begin
        if (RegWrite && rd != 5'd0) begin
            registers[rd] <= write_data;
        end
        registers[0] <= 32'd0;
    end
endmodule
