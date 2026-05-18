// =============================================================
// Memoria de Instrucciones - Fase 2
// Carga el archivo TestF2_MemInst.mem (programa de validación Fase 2)
// Acceso alineado a palabra: se usan bits [9:2] del PC
// =============================================================
module InstructionMemory(
    input  [31:0] address,
    output [31:0] instruction
);
    reg [31:0] mem [0:255];

    initial begin
        $readmemb("TestF2_MemInst.mem", mem);
    end

    // Lectura alineada a palabra (descarta 2 bits LSB)
    assign instruction = mem[address[9:2]];
endmodule
