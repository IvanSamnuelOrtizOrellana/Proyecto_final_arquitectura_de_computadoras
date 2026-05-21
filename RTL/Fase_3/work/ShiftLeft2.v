// Corrimiento logico a la izquierda de 2 bits.
module ShiftLeft2(
    input [31:0] in,
    output [31:0] out
);
    assign out = in << 2;
endmodule
