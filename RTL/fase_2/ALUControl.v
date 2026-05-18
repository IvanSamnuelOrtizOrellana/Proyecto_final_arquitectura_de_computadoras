// =============================================================
// Control de la ALU - Fase 2
// ALUOp[2:0] -> alu_control[3:0]:
//   010 + funct -> Tipo R (ver tabla)
//   000         -> 0010 ADD  (lw, sw, addi)
//   001         -> 0110 SUB  (beq)
//   011         -> 0111 SLT  (slti)
//   100         -> 0000 AND  (andi)
//   101         -> 0001 OR   (ori)
//
// alu_control[3:0]:
//   0000 -> AND
//   0001 -> OR
//   0010 -> ADD
//   0011 -> XOR
//   0110 -> SUB
//   0111 -> SLT
//   1000 -> SLL
//   1001 -> SRL
//   1100 -> NOR
// =============================================================
module ALUControl(
    input  [5:0] funct,
    input  [2:0] ALUOp,
    output reg [3:0] alu_control
);
    always @(*) begin
        case (ALUOp)
            3'b010: begin               // Tipo R — decodificar por funct
                case (funct)
                    6'b100000: alu_control = 4'b0010; // ADD
                    6'b100010: alu_control = 4'b0110; // SUB
                    6'b100100: alu_control = 4'b0000; // AND
                    6'b100101: alu_control = 4'b0001; // OR
                    6'b101010: alu_control = 4'b0111; // SLT
                    6'b100111: alu_control = 4'b1100; // NOR
                    6'b100110: alu_control = 4'b0011; // XOR
                    6'b000000: alu_control = 4'b1000; // SLL
                    6'b000010: alu_control = 4'b1001; // SRL
                    default:   alu_control = 4'b0000;
                endcase
            end
            3'b000: alu_control = 4'b0010; // ADD  (lw, sw, addi)
            3'b001: alu_control = 4'b0110; // SUB  (beq)
            3'b011: alu_control = 4'b0111; // SLT  (slti)
            3'b100: alu_control = 4'b0000; // AND  (andi)
            3'b101: alu_control = 4'b0001; // OR   (ori)
            default: alu_control = 4'b0000;
        endcase
    end
endmodule
