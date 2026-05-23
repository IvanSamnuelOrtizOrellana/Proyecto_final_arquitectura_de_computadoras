# Proyecto de Arquitectura de Computadoras

# Procesador MIPS 32-bit — Pipeline de 5 Etapas

**Materia:** Seminario de Solución de Problemas de Arquitectura de Computadoras  
**Universidad:** Universidad de Guadalajara — CUCEI  
**Carrera:** Ingeniería en Computación (ICOM)  
**Profesor:** Jorge Ernesto López Arce Delgado  
**Integrantes:**
- Diego Israel González Sánchez
- Derek Gabriel Casillas López
- Iván Samuel Ortiz Orellana
- Omar Luna Reyes

---

## Descripción

Implementación en Verilog de un procesador MIPS de 32 bits con pipeline de 5 etapas (IF → ID → EX → MEM → WB) capaz de ejecutar instrucciones tipo R, I y J. El proyecto se desarrolló en tres fases progresivas siguiendo el libro *Computer Organization and Design* de Patterson y Hennessy (5ª ed.), capítulos 4.3, 4.4 y 4.6.

El algoritmo de validación es un **test de primalidad por restas sucesivas**, que incluye llamadas a subrutinas usando `jal` y retorno con `jr`.

---

## Estructura del repositorio

```
ProyectoFinalArquitectura/
│
├── RTL/
│   ├── Fase_1/                  # Datapath single-cycle — instrucciones Tipo R
│   │   ├── PC.v
│   │   ├── Adder.v
│   │   ├── InstructionMemory.v
│   │   ├── RegisterFile.v
│   │   ├── ALU.v
│   │   ├── ALUControl.v
│   │   ├── Control.v
│   │   ├── Mux2.v
│   │   ├── SignExtend.v
│   │   ├── MIPS_Top.v
│   │   └── tb_MIPS.v
│   │
│   ├── Fase_2/                  # Agrega instrucciones Tipo I + 4 buffers pipeline
│   │   ├── DataMemory.v
│   │   ├── IF_ID.v
│   │   ├── ID_EX.v
│   │   ├── EX_MEM.v
│   │   ├── MEM_WB.v
│   │   ├── ShiftLeft2.v
│   │   ├── MIPS_Top.v
│   │   └── tb_MIPS.v
│   │
│   └── Fase_3/                  # Agrega instrucciones Tipo J + forwarding + detección de hazards
│       ├── PC.v
│       ├── Adder.v
│       ├── ALU.v
│       ├── ALUControl.v
│       ├── Control.v
│       ├── DataMemory.v
│       ├── EX_MEM.v
│       ├── ID_EX.v
│       ├── IF_ID.v
│       ├── InstructionMemory.v
│       ├── MEM_WB.v
│       ├── Mux2.v
│       ├── RegisterFile.v
│       ├── ShiftLeft2.v
│       ├── SignExtend.v
│       ├── MIPS_Top.v
│       └── tb_MIPS.v
│
├── mem/
│   ├── TestF1_MemInst.mem       # Instrucciones de prueba Fase 1 (Tipo R)
│   ├── TestF1_BReg.mem          # Banco de registros inicial (R0=0…R31=31)
│   ├── TestF2_MemInst.mem       # Instrucciones de prueba Fase 2 (Tipo I)
│   └── TestF3_MemInst.mem       # Programa primalidad con JAL/JR
│
├── asm/
│   └── primalidad.asm           # Código ensamblador del algoritmo de primalidad
│
└── README.md
```

---

## ISA implementado

### Instrucciones Tipo R (opcode `000000`)

| Instrucción | funct  | Operación            |
|-------------|--------|----------------------|
| `add`       | 100000 | rd = rs + rt         |
| `sub`       | 100010 | rd = rs − rt         |
| `and`       | 100100 | rd = rs & rt         |
| `or`        | 100101 | rd = rs \| rt        |
| `xor`       | 100110 | rd = rs ^ rt         |
| `nor`       | 100111 | rd = ~(rs \| rt)     |
| `slt`       | 101010 | rd = (rs < rt) ? 1:0 |
| `sll`       | 000000 | rd = rt << shamt     |
| `srl`       | 000010 | rd = rt >> shamt     |
| `jr`        | 001000 | PC = rs              |
| `nop`       | 000000 | sin operación        |

### Instrucciones Tipo I

| Instrucción | opcode | Operación                        |
|-------------|--------|----------------------------------|
| `lw`        | 100011 | rt = MEM[rs + imm]               |
| `sw`        | 101011 | MEM[rs + imm] = rt               |
| `beq`       | 000100 | if rs==rt: PC = PC+4 + imm<<2    |
| `addi`      | 001000 | rt = rs + imm (sign-ext)         |
| `slti`      | 001010 | rt = (rs < imm) ? 1 : 0          |
| `andi`      | 001100 | rt = rs & imm (zero-ext)         |
| `ori`       | 001101 | rt = rs \| imm (zero-ext)        |

### Instrucciones Tipo J

| Instrucción | opcode | Operación                              |
|-------------|--------|----------------------------------------|
| `j`         | 000010 | PC = {PC+4[31:28], target, 2'b00}      |
| `jal`       | 000011 | $ra = PC+4; PC = {PC+4[31:28], target} |

---

## Pipeline de 5 etapas

```
 ┌────┐   ┌────────┐   ┌────┐   ┌────────┐   ┌────────────┐   ┌───────────┐
 │ IF │──►│ IF/ID  │──►│ ID │──►│ ID/EX  │──►│     EX     │──►│  EX/MEM  │
 └────┘   └────────┘   └────┘   └────────┘   └────────────┘   └───────────┘
                                                                      │
 ┌────┐   ┌────────┐   ┌────┐   ┌─────────────────────────────────────┘
 │ WB │◄──│ MEM/WB │◄──│MEM │◄──┘
 └────┘   └────────┘   └────┘
```

Los 4 buffers de pipeline (IF/ID, ID/EX, EX/MEM, MEM/WB) se disparan en el mismo flanco de reloj que el PC.

### Hazards resueltos (Fase 3)

- **Load-use stall:** si la instrucción anterior es `lw` y la siguiente lee ese registro, se inserta una burbuja (el PC y el buffer IF/ID se congelan un ciclo).
- **Forwarding EX→EX y MEM→EX:** el resultado de la ALU se reenvía directamente desde EX/MEM o MEM/WB a la entrada de la ALU, eliminando stalls de datos en la mayoría de los casos.
- **Flush en saltos:** cuando un salto (`beq`, `j`, `jal`, `jr`) se resuelve en la etapa EX/ID, los buffers de las instrucciones incorrectamente capturadas se vacían (flush).

---

## Algoritmo: Test de Primalidad

El programa cargado en `TestF3_MemInst.mem` determina si `N` (precargado en memoria) es primo mediante **divisiones por restas sucesivas**. La instrucción `div` no está disponible en el ISA, por lo que el módulo se calcula restando el divisor repetidamente.

La subrutina `mod_sub` es invocada con `jal` (que guarda PC+4 en `$ra`) y retorna con `jr $ra`.

**Trazas de referencia:**

| N | ¿Primo? | Resultado en MEM[5] |
|---|---------|---------------------|
| 7 | Sí      | 1                   |
| 4 | No      | 0                   |

---

## Cómo simular en ModelSim

1. Abrir ModelSim y crear un proyecto nuevo.
2. Agregar todos los archivos `.v` de la carpeta `RTL/Fase_3/`.
3. Compilar en orden: módulos individuales primero, `MIPS_Top.v` al final, `tb_MIPS.v` al último.
4. Copiar `TestF3_MemInst.mem` al directorio de trabajo del proyecto.
5. Simular el módulo `tb_MIPS` por al menos **600 ns** (suficiente para N=5).
6. En la ventana Wave, agregar las señales `pc`, `instruction`, `alu_result`, `RegWrite` y `rf.registers[16]` (`$s0`).

---

## Herramientas

| Herramienta | Versión recomendada |
|-------------|---------------------|
| ModelSim- | 20.1 o superior |

---

## Referencias

1. D. A. Patterson y J. L. Hennessy, *Computer Organization and Design: The Hardware/Software Interface*, 5.ª ed. Morgan Kaufmann, 2014. Caps. 4.3, 4.4, 4.6.
2. MIPS Technologies, *MIPS32 Architecture for Programmers Vol. II: The MIPS32 Instruction Set*. MIPS Technologies, 2001.
3. S. Brown y Z. Vranesic, *Fundamentals of Digital Logic with Verilog Design*, 3.ª ed. McGraw-Hill, 2014.
4. D. M. Harris y S. L. Harris, *Digital Design and Computer Architecture*, 2.ª ed. Morgan Kaufmann, 2012.
5. Intel/Altera, *ModelSim-Altera Software Simulation User Guide*. Altera Corporation, 2016.
