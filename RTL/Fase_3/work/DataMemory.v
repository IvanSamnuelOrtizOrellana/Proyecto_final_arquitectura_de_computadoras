// Memoria de datos con lectura combinacional y escritura sincrona.
module DataMemory(
    input clk,
    input MemRead,
    input MemWrite,
    input [31:0] address,
    input [31:0] write_data,
    output [31:0] read_data
);
    reg [31:0] mem [0:255];
    integer i;

    initial begin
        for (i = 0; i < 256; i = i + 1) begin
            mem[i] = 32'd0;
        end
    end

    assign read_data = MemRead ? mem[address[9:2]] : 32'd0;

    always @(posedge clk) begin
        if (MemWrite) begin
            mem[address[9:2]] <= write_data;
        end
    end
endmodule
