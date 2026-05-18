// Unidad Aritmético Lógica
module ALU(
    input [31:0] a,
    input [31:0] b,
    input [4:0] shamt,
    input [3:0] alu_control,
    output reg [31:0] result,
    output zero
);
    always @(*) begin
        case (alu_control)
            4'b0000: result = a & b;             // AND
            4'b0001: result = a | b;             // OR
            4'b0010: result = a + b;             // ADD
            4'b0110: result = a - b;             // SUB
            4'b0111: result = (a < b) ? 32'd1 : 32'd0; // SLT
            4'b1100: result = ~(a | b);          // NOR
            4'b0011: result = a ^ b;             // XOR
            4'b1000: result = b << shamt;        // SLL
            4'b1001: result = b >> shamt;        // SRL
            default: result = 32'd0;
        endcase
    end
    assign zero = (result == 0);
endmodule
