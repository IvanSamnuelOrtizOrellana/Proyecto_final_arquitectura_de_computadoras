// Banco de Registros
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
    
    // Carga inicial del archivo .mem
    initial begin
        $readmemb("TestF1_BReg.mem", registers);
    end
    
    assign read_data1 = registers[rs];
    assign read_data2 = registers[rt];
    
    // Escritura síncrona, protegiendo el registro 0
    always @(posedge clk) begin
        if (RegWrite && rd != 5'd0) begin
            registers[rd] <= write_data;
        end
    end
endmodule
