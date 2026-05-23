# Procesador MIPS 32-bit — Fase 2
### Datapath Single-Cycle · Instrucciones Tipo I · Buffers de Pipeline

**Materia:** Seminario de Solución de Problemas de Arquitectura de Computadoras  
**Universidad:** Universidad de Guadalajara — CUCEI  
**Carrera:** Ingeniería en Computación  
**Profesor:** Jorge Ernesto López Arce Delgado  
**Integrantes:**
- Diego Israel González Sánchez
- Derek Gabriel Casillas López
- Iván Samuel Ortiz Orellana
- Omar Luna Reyes

---

## Descripción

Esta fase extiende el datapath de la Fase 1 para soportar instrucciones de **formato Tipo I**, cubriendo operaciones con inmediato (`addi`, `slti`, `andi`, `ori`), acceso a memoria (`lw`, `sw`) y control de flujo condicional (`beq`). Adicionalmente se incorporan los **cuatro buffers de pipeline** (IF/ID, ID/EX, EX/MEM, MEM/WB) requeridos por el capítulo 4.6 de Patterson & Hennessy, preparando la arquitectura para la segmentación completa de la Fase 3.

El diseño continúa operando en modo **single-cycle** (todos los buffers se actualizan en cada ciclo), pero la infraestructura de registros entre etapas ya está en su lugar.

> Esta es la **Fase 2** de un proyecto de tres fases. La Fase 1 implementó las instrucciones Tipo R. La Fase 3 agrega instrucciones Tipo J, forwarding y detección de hazards para activar el pipeline completo.

---

## Qué se agrega en esta fase

| Componente | Cambio respecto a Fase 1 |
|---|---|
| `Control.v` | Nuevo opcode por instrucción Tipo I; señal `Branch` activa para `beq` |
| `ALUControl.v` | `ALUOp` se amplía de 2 a 3 bits para distinguir entre las distintas operaciones inmediatas |
| `MIPS_Top.v` | Se integra el sumador de dirección BEQ, la lógica `pc_src`, y todos los buffers |
| `IF_ID.v` | Buffer nuevo: captura PC+4 e instrucción al final de IF |
| `ID_EX.v` | Buffer nuevo: captura señales de control, datos de registros, inmediato extendido y campos de instrucción |
| `EX_MEM.v` | Buffer nuevo: captura resultado ALU, flag zero, dirección de salto BEQ y señales MEM |
| `MEM_WB.v` | Buffer nuevo: captura dato leído de memoria y resultado ALU para el Write-Back |
| `DataMemory.v` | Activada: RAM 256×32 bits, lectura combinacional, escritura síncrona |

Los módulos `PC`, `Adder`, `ALU`, `Mux2`, `SignExtend`, `RegisterFile` e `InstructionMemory` no sufren cambios.

---

## Formato de instrucción Tipo I

```
 31      26 25    21 20    16 15                             0
 ┌────────┬────────┬────────┬────────────────────────────────┐
 │ opcode │   rs   │   rt   │           imm / offset         │
 │ 6 bits │ 5 bits │ 5 bits │             16 bits            │
 └────────┴────────┴────────┴────────────────────────────────┘
  tipo op.  fuente1  destino       inmediato con signo
```

El campo `imm` de 16 bits se extiende a 32 bits con extensión de signo antes de entrar a la ALU. En `beq`, este valor se desplaza 2 bits a la izquierda y se suma a PC+4 para calcular la dirección de salto.

---

## ISA completo (Fases 1 y 2)

### Tipo R (opcode `000000`)

| Instrucción | funct  | Operación                   |
|-------------|--------|-----------------------------|
| `add`       | 100000 | `rd = rs + rt`              |
| `sub`       | 100010 | `rd = rs − rt`              |
| `and`       | 100100 | `rd = rs & rt`              |
| `or`        | 100101 | `rd = rs \| rt`             |
| `xor`       | 100110 | `rd = rs ^ rt`              |
| `nor`       | 100111 | `rd = ~(rs \| rt)`          |
| `slt`       | 101010 | `rd = (rs < rt) ? 1 : 0`   |
| `sll`       | 000000 | `rd = rt << shamt`          |
| `srl`       | 000010 | `rd = rt >> shamt`          |
| `nop`       | 000000 | sin operación               |

### Tipo I — nuevas en Fase 2

| Instrucción | opcode | Operación                          | Sintaxis                   |
|-------------|--------|------------------------------------|----------------------------|
| `lw`        | 100011 | `rt = MEM[rs + SignExt(imm)]`      | `lw $rt, offset($rs)`      |
| `sw`        | 101011 | `MEM[rs + SignExt(imm)] = rt`      | `sw $rt, offset($rs)`      |
| `beq`       | 000100 | `if rs==rt: PC = PC+4 + imm<<2`    | `beq $rs, $rt, label`      |
| `addi`      | 001000 | `rt = rs + SignExt(imm)`           | `addi $rt, $rs, imm`       |
| `slti`      | 001010 | `rt = (rs < SignExt(imm)) ? 1 : 0` | `slti $rt, $rs, imm`       |
| `andi`      | 001100 | `rt = rs & ZeroExt(imm)`           | `andi $rt, $rs, imm`       |
| `ori`       | 001101 | `rt = rs \| ZeroExt(imm)`          | `ori $rt, $rs, imm`        |

---

## Módulos implementados

```
RTL/Fase_2/
├── PC.v                  — Sin cambios respecto a Fase 1
├── Adder.v               — Sin cambios
├── InstructionMemory.v   — Sin cambios
├── RegisterFile.v        — Sin cambios
├── ALU.v                 — Sin cambios
├── SignExtend.v          — Sin cambios
├── Mux2.v                — Sin cambios
├── DataMemory.v          — Activada: lectura combinacional, escritura síncrona
├── ALUControl.v          — ALUOp ampliado a 3 bits; nuevos casos para Tipo I
├── Control.v             — Soporta 8 opcodes; señal Branch para beq
├── IF_ID.v               — Buffer pipeline IF → ID
├── ID_EX.v               — Buffer pipeline ID → EX (el más amplio: señales de control + datos)
├── EX_MEM.v              — Buffer pipeline EX → MEM
├── MEM_WB.v              — Buffer pipeline MEM → WB
├── MIPS_Top.v            — Reescrito: integra buffers, lógica BEQ y Mux de PC
└── tb_MIPS.v             — Testbench actualizado para Fase 2
```

### Señales de control por instrucción

| Instrucción | RegDst | ALUSrc | MemtoReg | RegWrite | MemRead | MemWrite | Branch | ALUOp |
|-------------|--------|--------|----------|----------|---------|----------|--------|-------|
| Tipo R      | 1      | 0      | 0        | 1        | 0       | 0        | 0      | 010   |
| `lw`        | 0      | 1      | 1        | 1        | 1       | 0        | 0      | 000   |
| `sw`        | X      | 1      | X        | 0        | 0       | 1        | 0      | 000   |
| `beq`       | X      | 0      | X        | 0        | 0       | 0        | 1      | 001   |
| `addi`      | 0      | 1      | 0        | 1        | 0       | 0        | 0      | 000   |
| `slti`      | 0      | 1      | 0        | 1        | 0       | 0        | 0      | 011   |
| `andi`      | 0      | 1      | 0        | 1        | 0       | 0        | 0      | 100   |
| `ori`       | 0      | 1      | 0        | 1        | 0       | 0        | 0      | 101   |

### Lógica de salto BEQ

```
pc_src      = Branch_mem AND zero_mem
next_pc     = pc_src ? branch_target : pc_plus_4
branch_target = PC+4 + SignExt(imm16) << 2
```

El cálculo de la dirección de salto ocurre en la etapa EX; la decisión se toma en la etapa MEM cuando la señal `Branch` y el flag `zero` de la ALU están disponibles simultáneamente.

---

## Buffers de pipeline

Los cuatro buffers son registros síncronos de flanco positivo con reset activo-alto. Todos comparten el mismo `CLK` y `reset` que el PC, conforme al capítulo 4.6 de Patterson & Hennessy.

```
   IF          IF/ID         ID          ID/EX         EX         EX/MEM        MEM        MEM/WB        WB
┌──────┐    ┌─────────┐  ┌──────┐    ┌─────────┐  ┌──────┐    ┌─────────┐  ┌──────┐    ┌─────────┐  ┌──────┐
│  PC  │───►│ PC+4    │─►│ Ctrl │───►│ Señales │─►│ ALU  │───►│ ALUres  │─►│ DMEM │───►│ rdData  │─►│ MUX  │
│  IM  │    │ Instr   │  │ RF   │    │ Datos   │  │      │    │ wrData  │  │      │    │ ALUres  │  │  RF  │
└──────┘    └─────────┘  └──────┘    └─────────┘  └──────┘    └─────────┘  └──────┘    └─────────┘  └──────┘
```

| Buffer  | Qué captura al final de la etapa |
|---------|----------------------------------|
| `IF/ID`   | PC+4, instrucción de 32 bits |
| `ID/EX`   | RegDst, ALUSrc, MemtoReg, RegWrite, MemRead, MemWrite, Branch, ALUOp[2:0], read_data1, read_data2, sign_ext_imm, rs, rt, rd, shamt, funct |
| `EX/MEM`  | zero, alu_result, write_data (para sw), branch_target, write_reg, MemtoReg, RegWrite, MemRead, MemWrite |
| `MEM/WB`  | read_data (de memoria), alu_result, write_reg, RegWrite, MemtoReg |

---

## Archivos de memoria

| Archivo              | Contenido |
|----------------------|-----------|
| `TestF1_BReg.mem`    | Banco de registros inicial de Fase 1 (R0=0, R1=1, …, R31=31); se reutiliza en Fase 2 |
| `TestF2_MemInst.mem` | Programa de validación Fase 2: `nop`, `addi`, `slti`, `andi`, `ori`, `sw`, `lw`, `beq` |

### Programa de validación y resultados esperados

```asm
[0]  nop
[1]  addi $t0, $zero, 10     # $t0 = 10
[2]  slti $t1, $zero, 10     # $t1 = 1  (0 < 10)
[3]  andi $t2, $zero, 10     # $t2 = 0  (0 & 10)
[4]  ori  $t3, $zero, 10     # $t3 = 10 (0 | 10)
[5]  sw   $t0, 0($zero)      # MEM[0] = 10
[6]  lw   $t4, 0($zero)      # $t4 = MEM[0] = 10
[7]  beq  $zero, $zero, [0]  # salta de regreso a [0] (loop infinito)
```

| Registro / Memoria | Valor esperado | Instrucción que lo produce |
|--------------------|----------------|---------------------------|
| `$t0` (reg 8)      | 10             | `addi $t0, $zero, 10`     |
| `$t1` (reg 9)      | 1              | `slti` (0 < 10 → 1)       |
| `$t2` (reg 10)     | 0              | `andi` (0 & 10 = 0)       |
| `$t3` (reg 11)     | 10             | `ori`  (0 \| 10 = 10)     |
| `MEM[0]`           | 10             | `sw $t0, 0($zero)`        |
| `$t4` (reg 12)     | 10             | `lw $t4, 0($zero)`        |

---

## Algoritmo: Test de Primalidad

A partir de Fase 2 el algoritmo de primalidad propuesto en la Fase 1 puede ejecutarse completamente, ya que ahora están disponibles `addi` (para inicializar registros con constantes) y `beq` (para implementar bucles de control).

El algoritmo determina si `n` es primo probando divisores desde 2 hasta `n−1`. Para cada divisor calcula el residuo de `n ÷ divisor` mediante **restas sucesivas** (sin instrucción `div`).

### Asignación de registros

| Registro | Uso |
|----------|-----|
| `$t0`    | `n` — número a evaluar |
| `$t1`    | divisor (empieza en 2, incrementa de 1 en 1) |
| `$t2`    | residuo — copia de n, se resta el divisor iterativamente |
| `$t3`    | bandera temporal (resultado de `slti`) |
| `$t4`    | constante 1 |
| `$v0`    | resultado: 1 = primo, 0 = no primo |

### Traza de ejecución — n = 7 (primo)

| Divisor | Residuo final | ¿Divisible? |
|---------|---------------|-------------|
| 2       | 1 (7−2−2−2)   | No          |
| 3       | 1 (7−3−3)     | No          |
| 4       | 3 (7−4)       | No          |
| 5       | 2 (7−5)       | No          |
| 6       | 1 (7−6)       | No          |
| 7       | divisor ≥ n   | **FIN: `$v0` = 1 (PRIMO)** |

---

## Cómo simular en ModelSim

1. Crear un proyecto nuevo y agregar todos los archivos `.v` de `RTL/Fase_2/`
2. Compilar en orden: módulos individuales → buffers → `MIPS_Top.v` → `tb_MIPS.v`
3. Copiar `TestF2_MemInst.mem` y `TestF1_BReg.mem` al directorio de trabajo del proyecto
4. Simular `tb_MIPS` durante al menos **400 ns**
5. En la ventana Wave agregar: `pc`, `instruction`, `alu_result`, `RegWrite`, `MemRead`, `MemWrite`, `Branch`, `zero`, `pc_src`

**Tip:** Verificar que `$t0`=10, `$t1`=1, `$t2`=0, `$t3`=10 y `MEM[0]`=10 tras los primeros ciclos. El `beq` en la instrucción [7] debe hacer que el PC vuelva a 0x00.

---

## Herramientas

| Herramienta | Versión recomendada | Uso |
|-------------|---------------------|-----|
| ModelSim-Altera | 20.1 o superior | Simulación y verificación |
| Vivado (Xilinx) | 2020.2 o superior | Síntesis opcional |
| Quartus Prime (Altera) | 21.1 o superior | Síntesis opcional |

---

## Estado del proyecto

| Fase | Contenido                                          | Estado       |
|------|----------------------------------------------------|--------------|
| ✅ Fase 1 | Datapath single-cycle, instrucciones Tipo R     | Completa     |
| ✅ Fase 2 | Instrucciones Tipo I, 4 buffers de pipeline     | **Completa** |
| ⬜ Fase 3 | Instrucciones Tipo J, forwarding, hazards       | Pendiente    |

---

## Referencias

1. D. A. Patterson y J. L. Hennessy, *Computer Organization and Design: The Hardware/Software Interface*, 5ª ed. Morgan Kaufmann, 2014. Caps. 4.3, 4.4, 4.6.
2. MIPS Technologies, *MIPS32 Architecture for Programmers Vol. II: The MIPS32 Instruction Set*. MIPS Technologies, 2001.
3. S. Brown y Z. Vranesic, *Fundamentals of Digital Logic with Verilog Design*, 3ª ed. McGraw-Hill, 2014.
4. D. M. Harris y S. L. Harris, *Digital Design and Computer Architecture*, 2ª ed. Morgan Kaufmann, 2012.
5. Intel/Altera, *ModelSim-Altera Software Simulation User Guide*. Altera Corporation, 2016.
