// =============================================================
// Unidad de Control Principal - Fase 2
// Instrucciones soportadas:
//   Tipo R  : opcode = 000000  (add, sub, and, or, xor, nor, slt, sll, srl)
//   lw      : opcode = 100011
//   sw      : opcode = 101011
//   beq     : opcode = 000100
//   addi    : opcode = 001000
//   slti    : opcode = 001010
//   andi    : opcode = 001100
//   ori     : opcode = 001101
//
// ALUOp[2:0]:
//   010 -> Tipo R   (ALUControl usa funct)
//   000 -> ADD      (lw, sw, addi)
//   001 -> SUB      (beq)
//   011 -> SLT      (slti)
//   100 -> AND      (andi)
//   101 -> OR       (ori)
// =============================================================
module Control(
    input  [5:0] opcode,
    output reg   RegDst,
    output reg   ALUSrc,
    output reg   MemtoReg,
    output reg   RegWrite,
    output reg   MemRead,
    output reg   MemWrite,
    output reg   Branch,
    output reg [2:0] ALUOp
);
    always @(*) begin
        // Valores por defecto — evita latches
        RegDst   = 1'b0;
        ALUSrc   = 1'b0;
        MemtoReg = 1'b0;
        RegWrite = 1'b0;
        MemRead  = 1'b0;
        MemWrite = 1'b0;
        Branch   = 1'b0;
        ALUOp    = 3'b000;

        case (opcode)
            6'b000000: begin // Tipo R
                RegDst   = 1'b1;
                RegWrite = 1'b1;
                ALUOp    = 3'b010;
            end
            6'b100011: begin // LW — load word
                ALUSrc   = 1'b1;
                MemtoReg = 1'b1;
                RegWrite = 1'b1;
                MemRead  = 1'b1;
                ALUOp    = 3'b000;
            end
            6'b101011: begin // SW — store word
                ALUSrc   = 1'b1;
                MemWrite = 1'b1;
                ALUOp    = 3'b000;
            end
            6'b000100: begin // BEQ — branch if equal
                Branch   = 1'b1;
                ALUOp    = 3'b001;
            end
            6'b001000: begin // ADDI — add immediate
                ALUSrc   = 1'b1;
                RegWrite = 1'b1;
                ALUOp    = 3'b000;
            end
            6'b001010: begin // SLTI — set less than immediate
                ALUSrc   = 1'b1;
                RegWrite = 1'b1;
                ALUOp    = 3'b011;
            end
            6'b001100: begin // ANDI — and immediate
                ALUSrc   = 1'b1;
                RegWrite = 1'b1;
                ALUOp    = 3'b100;
            end
            6'b001101: begin // ORI — or immediate
                ALUSrc   = 1'b1;
                RegWrite = 1'b1;
                ALUOp    = 3'b101;
            end
            default: begin
                RegWrite = 1'b0;
            end
        endcase
    end
endmodule
