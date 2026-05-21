// Unidad de Control Principal
module Control(
    input [5:0] opcode,
    output reg RegDst,
    output reg ALUSrc,
    output reg MemtoReg,
    output reg RegWrite,
    output reg MemRead,
    output reg MemWrite,
    output reg [1:0] ALUOp
);
    always @(*) begin
        // Valores por defecto para evitar latches
        RegDst = 0; ALUSrc = 0; MemtoReg = 0; 
        RegWrite = 0; MemRead = 0; MemWrite = 0; ALUOp = 2'b00;
        
        case (opcode)
            6'b000000: begin // Tipo R
                RegDst = 1;
                RegWrite = 1;
                ALUOp = 2'b10;
            end
            // Espacio para agregar Tipo I (lw, sw, beq) en la Fase 2
            default: begin
                RegWrite = 0;
            end
        endcase
    end
endmodule
