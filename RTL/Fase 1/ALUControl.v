// Control de la ALU
module ALUControl(
    input [5:0] funct,
    input [1:0] ALUOp,
    output reg [3:0] alu_control
);
    always @(*) begin
        if (ALUOp == 2'b10) begin // Instrucciones Tipo R
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
        end else begin
            alu_control = 4'b0000;
        end
    end
endmodule
