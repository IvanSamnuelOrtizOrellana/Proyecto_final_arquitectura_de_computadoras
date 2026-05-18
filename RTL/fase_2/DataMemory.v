// Memoria de Datos
module DataMemory(
    input clk,
    input MemRead,
    input MemWrite,
    input [31:0] address,
    input [31:0] write_data,
    output [31:0] read_data
);
    reg [31:0] mem [0:255];
    
    assign read_data = MemRead ? mem[address[9:2]] : 32'd0;
    
    // Escritura síncrona
    always @(posedge clk) begin
        if (MemWrite) begin
            mem[address[9:2]] <= write_data;
        end
    end
endmodule
