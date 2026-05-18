// Memoria de Instrucciones
module InstructionMemory(
    input [31:0] address,
    output [31:0] instruction
);
    reg [31:0] mem [0:255];
    
    // Carga inicial del archivo .mem
    initial begin
        $readmemb("C:/ProyectoFinalArquitectura/TestF1_MemInst.mem", mem);
    end
    
    // Lectura alineada a palabra (ignora los 2 bits menos significativos)
    assign instruction = mem[address[9:2]]; 
endmodule
