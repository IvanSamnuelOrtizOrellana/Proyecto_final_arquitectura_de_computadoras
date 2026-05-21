// Memoria de instrucciones.
module InstructionMemory(
    input [31:0] address,
    output [31:0] instruction
);
    reg [31:0] mem [0:255];
    integer i;

    initial begin
        for (i = 0; i < 256; i = i + 1) begin
            mem[i] = 32'd0;
        end
        $readmemb("TestF3_MemInst.mem", mem);
    end

    // La memoria esta direccionada por palabra; se ignoran los bits [1:0].
    assign instruction = mem[address[9:2]];
endmodule
