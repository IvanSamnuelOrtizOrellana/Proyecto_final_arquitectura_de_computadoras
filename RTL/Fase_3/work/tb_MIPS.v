// Testbench Global
`timescale 1ns/1ps

module tb_MIPS;
    reg clk;
    reg reset;

    // Instancia del Datapath
    MIPS_Top dut(
        .clk(clk),
        .reset(reset)
    );

    // Generacion de reloj
    always #5 clk = ~clk;

    initial begin
        clk = 0;
        reset = 1;
        #10;
        reset = 0;

        // Tiempo suficiente para terminar primalidad.asm con n = 5.
        #600;
        $stop;
    end

    // Monitor de variables principales y resultado en $s0.
    initial begin
        $monitor("Tiempo=%0t | PC=%h | Instr=%h | ALU_Res=%h | Escribe_Reg=%b | s0=%h",
                 $time, dut.pc, dut.instruction, dut.alu_result, dut.RegWrite,
                 dut.rf.registers[16]);
    end
endmodule
