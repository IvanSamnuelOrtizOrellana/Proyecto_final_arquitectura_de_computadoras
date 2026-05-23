# Procesador MIPS 32-bit — Fase 1
### Datapath Single-Cycle · Instrucciones Tipo R

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

Esta fase implementa en Verilog HDL un **datapath de ciclo único (single-cycle)** para un procesador MIPS de 32 bits capaz de ejecutar instrucciones de **formato Tipo R**. El diseño sigue la arquitectura descrita en el capítulo 4 de *Computer Organization and Design* de Patterson & Hennessy (5ª ed.) y se valida mediante simulación en ModelSim.

En el modelo single-cycle, cada instrucción completa su ejecución en un único ciclo de reloj siguiendo el flujo:

```
Fetch (IF) → Decode (ID) → Execute (EX) → Memory (MEM) → Write-Back (WB)
```

> Esta es la **Fase 1** de un proyecto de tres fases. Las fases posteriores agregan instrucciones Tipo I (memoria y branches), instrucciones Tipo J (saltos), y finalmente el pipeline completo de 5 etapas.

---

## Arquitectura MIPS y filosofía RISC

El procesador MIPS (*Microprocessor without Interlocked Pipeline Stages*) fue desarrollado en Stanford por John Hennessy a principios de los 80. Pertenece a la familia **RISC** (*Reduced Instruction Set Computer*), cuyas características principales son:

- Conjunto pequeño de instrucciones simples y ortogonales
- Instrucciones de longitud fija (32 bits)
- Operaciones aritméticas solo entre registros; la memoria se accede exclusivamente con `lw`/`sw`
- 32 registros de propósito general (`$0`–`$31`), donde `$zero` está cableado permanentemente a cero
- Arquitectura Harvard modificada: memorias de instrucciones y datos separadas
- PC que se incrementa en 4 bytes por instrucción

---

## Formato de instrucción Tipo R

Todas las instrucciones Tipo R tienen `opcode = 000000`. La operación específica la determina el campo `funct` de 6 bits.

```
 31      26 25    21 20    16 15    11 10     6 5       0
 ┌────────┬────────┬────────┬────────┬────────┬────────┐
 │ opcode │   rs   │   rt   │   rd   │  shamt │  funct │
 │ 6 bits │ 5 bits │ 5 bits │ 5 bits │ 5 bits │ 6 bits │
 └────────┴────────┴────────┴────────┴────────┴────────┘
   000000   fuente1  fuente2  destino  desplaz.  operación
```

Sintaxis ensamblador: `instrucción $rd, $rs, $rt`  
Excepción (desplazamientos): `sll $rd, $rt, shamt`

---

## ISA implementado

| Instrucción | funct  | Operación                     | Sintaxis              |
|-------------|--------|-------------------------------|-----------------------|
| `add`       | 100000 | `rd = rs + rt`                | `add $rd, $rs, $rt`   |
| `sub`       | 100010 | `rd = rs − rt`                | `sub $rd, $rs, $rt`   |
| `and`       | 100100 | `rd = rs & rt`                | `and $rd, $rs, $rt`   |
| `or`        | 100101 | `rd = rs \| rt`               | `or $rd, $rs, $rt`    |
| `xor`       | 100110 | `rd = rs ^ rt`                | `xor $rd, $rs, $rt`   |
| `nor`       | 100111 | `rd = ~(rs \| rt)`            | `nor $rd, $rs, $rt`   |
| `slt`       | 101010 | `rd = (rs < rt) ? 1 : 0`      | `slt $rd, $rs, $rt`   |
| `sll`       | 000000 | `rd = rt << shamt`            | `sll $rd, $rt, shamt` |
| `srl`       | 000010 | `rd = rt >> shamt` (lógico)   | `srl $rd, $rt, shamt` |
| `nop`       | 000000 | sin operación (`sll $0,$0,0`) | `nop`                 |

---

## Módulos implementados

```
RTL/Fase_1/
├── PC.v                  — Contador de Programa (registro síncrono de 32 bits)
├── Adder.v               — Sumador combinacional PC+4
├── InstructionMemory.v   — ROM 256×32 bits, lectura combinacional ($readmemb)
├── RegisterFile.v        — Banco de 32 registros×32 bits, doble lectura, escritura síncrona
├── ALU.v                 — Operaciones: ADD, SUB, AND, OR, XOR, NOR, SLT, SLL, SRL
├── ALUControl.v          — Decodifica funct + ALUOp → alu_control [3:0]
├── Control.v             — Decodifica opcode → señales de control del datapath
├── Mux2.v                — Multiplexor 2:1 parametrizable (usado para RegDst y MemtoReg)
├── SignExtend.v           — Extensión de signo 16→32 bits (preparado para Fase 2)
├── DataMemory.v          — RAM 256×32 bits (preparada para Fase 2, no activa en Fase 1)
├── MIPS_Top.v            — Módulo superior: interconecta todos los bloques
└── tb_MIPS.v             — Testbench: reloj 10 ns, reset inicial, monitor de señales
```

### Flujo de una instrucción Tipo R

```
PC ──► InstructionMemory ──► Control (opcode)
                          └──► ALUControl (funct)
                          └──► RegisterFile (rs, rt) ──► ALU ──► RegisterFile (rd ← result)
                                                  ▲
                                           Mux RegDst selecciona rd (bits [15:11])
```

### Señales de control para instrucciones Tipo R

| Señal      | Valor | Descripción                                      |
|------------|-------|--------------------------------------------------|
| `RegDst`   | 1     | El registro destino es `rd` (campo [15:11])      |
| `ALUSrc`   | 0     | El segundo operando de la ALU viene del banco de registros |
| `MemtoReg` | 0     | El dato a escribir en el registro viene de la ALU |
| `RegWrite` | 1     | Escritura habilitada en el banco de registros    |
| `MemRead`  | 0     | No se lee memoria de datos                       |
| `MemWrite` | 0     | No se escribe memoria de datos                   |
| `Branch`   | 0     | No es instrucción de salto                       |
| `ALUOp`    | 10    | Modo Tipo R: la operación la define el campo `funct` |

---

## Archivos de memoria

| Archivo              | Contenido                                                   |
|----------------------|-------------------------------------------------------------|
| `TestF1_MemInst.mem` | Instrucciones de prueba en binario (add, sub, and, or, slt) |
| `TestF1_BReg.mem`    | Banco de registros inicial: registro N contiene el valor N (R0=0, R1=1, …, R31=31) |

---

## Algoritmos posibles con este ISA

Con las instrucciones Tipo R disponibles en esta fase es posible implementar:

- **Máximo Común Divisor** (algoritmo de Euclides por restas): usa `sub`, `slt` y control de flujo
- **Búsqueda de máximo/mínimo** en un conjunto de registros: usa `slt` para comparar
- **Operaciones lógicas y máscaras de bits**: con `and`, `or`, `xor`, `nor`
- **Multiplicación por potencias de 2**: con `sll` y `srl`
- **Multiplicación simulada por sumas repetidas**: con `add` en bucle (sin `mul`)

**Limitaciones en esta fase:**
- Sin acceso a memoria: todos los operandos deben estar precargados en registros
- Sin instrucciones de salto condicional activas en el hardware: los bucles dinámicos no se ejecutan en el datapath actual
- Sin inmediatos: no es posible cargar constantes arbitrarias con una sola instrucción

---

## Cómo simular en ModelSim

1. Crear un proyecto nuevo en ModelSim y agregar todos los archivos `.v` de `RTL/Fase_1/`
2. Compilar en orden: módulos individuales primero, `MIPS_Top.v` al final, `tb_MIPS.v` al último
3. Copiar `TestF1_MemInst.mem` y `TestF1_BReg.mem` al directorio de trabajo del proyecto
4. Simular el módulo `tb_MIPS` durante al menos **200 ns** (20 ciclos de ejecución)
5. En la ventana Wave agregar: `pc`, `instruction`, `alu_result`, `write_reg`, `RegWrite`

**Resultados esperados:** el PC incrementa de 4 en 4 (0x00 → 0x04 → 0x08 → …), `RegWrite` se activa en cada instrucción Tipo R, y `alu_result` refleja el resultado correcto de cada operación sobre los registros precargados.

---

## Herramientas

| Herramienta | Versión recomendada | Uso |
|-------------|---------------------|-----|
| ModelSim-Altera | 20.1 o superior | Simulación y verificación |
| Vivado (Xilinx) | 2020.2 o superior | Síntesis opcional |
| Quartus Prime (Altera) | 21.1 o superior | Síntesis opcional |

---

## Estado del proyecto

| Fase | Contenido                                      | Estado      |
|------|------------------------------------------------|-------------|
| ✅ Fase 1 | Datapath single-cycle, instrucciones Tipo R | **Completa** |
| ⬜ Fase 2 | Instrucciones Tipo I, buffers de pipeline   | Pendiente   |
| ⬜ Fase 3 | Instrucciones Tipo J, forwarding, hazards   | Pendiente   |

---

## Referencias

1. D. A. Patterson y J. L. Hennessy, *Computer Organization and Design: The Hardware/Software Interface*, 5ª ed. Morgan Kaufmann, 2014. Caps. 4.3, 4.4.
2. MIPS Technologies, *MIPS32 Architecture for Programmers Vol. II: The MIPS32 Instruction Set*. MIPS Technologies, 2001.
3. S. Brown y Z. Vranesic, *Fundamentals of Digital Logic with Verilog Design*, 3ª ed. McGraw-Hill, 2014.
4. D. M. Harris y S. L. Harris, *Digital Design and Computer Architecture*, 2ª ed. Morgan Kaufmann, 2012.
5. Intel/Altera, *ModelSim-Altera Software Simulation User Guide*. Altera Corporation, 2016.
