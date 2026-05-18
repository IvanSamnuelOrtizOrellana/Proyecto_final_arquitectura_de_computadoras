
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

    // Generación de reloj
    always #5 clk = ~clk;

    initial begin
        clk = 0;
        reset = 1;
        #10;
        reset = 0;
        
        // Tiempo de simulación (ajustar según la cantidad de instrucciones)
        #200;
        $stop;
    end

    // Monitor de variables
    initial begin
        $monitor("Tiempo=%0t | PC=%h | Instr=%h | ALU_Res=%h | Escribe_Reg=%b",
                 $time, dut.pc, dut.instruction, dut.alu_result, dut.RegWrite);
    end
endmodule