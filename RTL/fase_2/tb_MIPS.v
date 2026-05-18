// =============================================================
// Testbench Global - Fase 2
// Verifica: instrucciones Tipo I (addi, slti, andi, ori, sw, lw)
//           y BEQ con loop infinito.
// Banco de registros precargado con TestF1_BReg.mem (R[N]=N)
// Memoria de instrucciones: TestF2_MemInst.mem
// =============================================================
`timescale 1ns/1ps

module tb_MIPS;
    reg clk;
    reg reset;

    // Instancia del datapath Fase 2
    MIPS_Top dut(
        .clk(clk),
        .reset(reset)
    );

    // Reloj de 100 MHz — periodo 10 ns
    always #5 clk = ~clk;

    // -------------------------------------------------------
    // Secuencia de reset e inicio
    // -------------------------------------------------------
    initial begin
        clk   = 0;
        reset = 1;
        #10;          // Un ciclo en reset
        reset = 0;

        // El programa ejecuta 8 instrucciones y luego hace BEQ
        // que vuelve a la instrucción 0, generando un loop.
        // Dejamos correr 30 ciclos para ver al menos 3 iteraciones
        // del loop y confirmar que el BEQ funciona correctamente.
        #300;
        $stop;
    end

    // -------------------------------------------------------
    // Monitor principal — imprime cada vez que cambian señales clave
    // -------------------------------------------------------
    initial begin
        $display("=== Simulacion MIPS Fase 2 ===");
        $display("Tiempo | PC       | Instruccion | ALU_Result | WrReg | RegWrite | Branch | PCSrc");
        $monitor("%0t ns | PC=%h | I=%h | ALU=%h | WrReg=%0d | RW=%b | Br=%b | PSrc=%b",
            $time,
            dut.pc,
            dut.if_id_instr,
            dut.alu_result_ex,
            dut.write_reg_ex,
            dut.RegWrite_ex,
            dut.Branch_ex,
            dut.pc_src
        );
    end

    // -------------------------------------------------------
    // Verificaciones automáticas de resultados esperados
    // Se evalúan después de dejar pasar suficientes ciclos
    // para que las instrucciones completen el pipeline.
    // -------------------------------------------------------
    initial begin
        // Esperar reset + suficientes ciclos para que las primeras
        // 7 instrucciones hayan pasado por todos los buffers (≥7 ciclos)
        @(negedge reset);
        repeat(12) @(posedge clk);

        $display("\n=== Verificacion de resultados esperados ===");

        // $t0 (reg 8) = 10 después de addi $t0, $zero, 10
        if (dut.rf.registers[8] === 32'd10)
            $display("PASS: $t0 (reg 8) = %0d (esperado 10)", dut.rf.registers[8]);
        else
            $display("FAIL: $t0 (reg 8) = %0d (esperado 10)", dut.rf.registers[8]);

        // $t1 (reg 9) = 1 después de slti $t1, $zero, 10
        if (dut.rf.registers[9] === 32'd1)
            $display("PASS: $t1 (reg 9) = %0d (esperado 1)", dut.rf.registers[9]);
        else
            $display("FAIL: $t1 (reg 9) = %0d (esperado 1)", dut.rf.registers[9]);

        // $t2 (reg 10) = 0 después de andi $t2, $zero, 10
        if (dut.rf.registers[10] === 32'd0)
            $display("PASS: $t2 (reg10) = %0d (esperado 0)", dut.rf.registers[10]);
        else
            $display("FAIL: $t2 (reg10) = %0d (esperado 0)", dut.rf.registers[10]);

        // $t3 (reg 11) = 10 después de ori $t3, $zero, 10
        if (dut.rf.registers[11] === 32'd10)
            $display("PASS: $t3 (reg11) = %0d (esperado 10)", dut.rf.registers[11]);
        else
            $display("FAIL: $t3 (reg11) = %0d (esperado 10)", dut.rf.registers[11]);

        // $t4 (reg 12) = 10 después de lw $t4, 0($zero)
        if (dut.rf.registers[12] === 32'd10)
            $display("PASS: $t4 (reg12) = %0d (esperado 10)", dut.rf.registers[12]);
        else
            $display("FAIL: $t4 (reg12) = %0d (esperado 10)", dut.rf.registers[12]);

        // mem[0] = 10 después de sw $t0, 0($zero)
        if (dut.dm.mem[0] === 32'd10)
            $display("PASS: mem[0]      = %0d (esperado 10)", dut.dm.mem[0]);
        else
            $display("FAIL: mem[0]      = %0d (esperado 10)", dut.dm.mem[0]);

        $display("==========================================\n");
    end

endmodule
