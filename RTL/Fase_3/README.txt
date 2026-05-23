# Procesador MIPS 32-bit — Fase 3
### Pipeline de 5 Etapas · Instrucciones Tipo J · Forwarding · Detección de Hazards

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

Esta fase completa el repertorio básico del ISA MIPS implementando las instrucciones de **formato Tipo J** (`j`, `jal`, `jr`) y activando el **pipeline de 5 etapas** con sincronización real entre etapas. Para que el pipeline funcione correctamente sin producir resultados incorrectos, se implementan tres mecanismos de resolución de conflictos:

- **Forwarding** (EX→EX y MEM→EX): reenvío del resultado de la ALU directamente a su entrada sin esperar Write-Back
- **Load-use hazard detection**: congela el PC y el buffer IF/ID cuando un `lw` es seguido inmediatamente por una instrucción que usa el registro cargado
- **Flush de control**: vacía los buffers de instrucciones incorrectamente captadas cuando se detecta un salto tomado

El algoritmo de validación es un **test de primalidad** que incluye llamadas a subrutina usando `jal` y retorno con `jr $ra`, demostrando el mecanismo completo de instrucciones Tipo J en el pipeline.

> Esta es la **Fase 3** y última fase del proyecto. Las Fases 1 y 2 implementaron instrucciones Tipo R e I respectivamente, y dejaron los 4 buffers de pipeline listos como infraestructura.

---

## Qué se agrega en esta fase

| Componente | Cambio respecto a Fase 2 |
|---|---|
| `Control.v` | Nuevas señales `Jump` y `JAL` para opcodes `000010` (j) y `000011` (jal) |
| `ALUControl.v` | Operaciones XOR y NOR añadidas; sin cambios estructurales |
| `MIPS_Top.v` | Forwarding unit, hazard detection unit, lógica JR, MUX de PC para J/JAL/JR, escritura de `$ra` en JAL |
| `ID_EX.v` | Agrega señal `flush` para insertar burbujas por stall o salto |
| `IF_ID.v` | Agrega señal `enable` (congela buffer en stall) y `flush` |
| Forwarding unit | Lógica combinacional en EX: detecta dependencias y selecciona el operando correcto |
| Hazard detection | Lógica combinacional en ID: detecta load-use y genera señal `stall` |

Los módulos `PC`, `Adder`, `ALU`, `Mux2`, `SignExtend`, `RegisterFile`, `DataMemory`, `InstructionMemory`, `EX_MEM` y `MEM_WB` no sufren cambios estructurales.

---

## Formato de instrucción Tipo J

```
 31      26 25                                              0
 ┌────────┬────────────────────────────────────────────────┐
 │ opcode │                   target                       │
 │ 6 bits │                   26 bits                      │
 └────────┴────────────────────────────────────────────────┘
```

La dirección efectiva de salto se construye concatenando los 4 bits más significativos de PC+4 con los 26 bits del campo `target` desplazados 2 posiciones a la izquierda:

```
jump_addr = { PC+4[31:28], target[25:0], 2'b00 }
```

`jr` es técnicamente una instrucción Tipo R (`funct = 001000`), pero se comporta como salto: el PC toma el valor del registro `rs`.

---

## ISA completo (Fases 1, 2 y 3)

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
| `jr`        | 001000 | `PC = rs`                   |
| `nop`       | 000000 | sin operación               |

### Tipo I (opcode distinto de `000000`)

| Instrucción | opcode | Operación                           |
|-------------|--------|-------------------------------------|
| `lw`        | 100011 | `rt = MEM[rs + SignExt(imm)]`       |
| `sw`        | 101011 | `MEM[rs + SignExt(imm)] = rt`       |
| `beq`       | 000100 | `if rs==rt: PC = PC+4 + imm<<2`     |
| `addi`      | 001000 | `rt = rs + SignExt(imm)`            |
| `slti`      | 001010 | `rt = (rs < SignExt(imm)) ? 1 : 0`  |
| `andi`      | 001100 | `rt = rs & ZeroExt(imm)`            |
| `ori`       | 001101 | `rt = rs \| ZeroExt(imm)`           |

### Tipo J — nuevas en Fase 3

| Instrucción | opcode | Operación                                     |
|-------------|--------|-----------------------------------------------|
| `j`         | 000010 | `PC = {PC+4[31:28], target, 2'b00}`           |
| `jal`       | 000011 | `$ra = PC+4;  PC = {PC+4[31:28], target, 2'b00}` |

### Señales de control — tabla completa

| Instrucción | RegDst | ALUSrc | MemtoReg | RegWrite | MemRead | MemWrite | Branch | Jump | JAL |
|-------------|--------|--------|----------|----------|---------|----------|--------|------|-----|
| Tipo R      | 1      | 0      | 0        | 1        | 0       | 0        | 0      | 0    | 0   |
| `lw`        | 0      | 1      | 1        | 1        | 1       | 0        | 0      | 0    | 0   |
| `sw`        | X      | 1      | X        | 0        | 0       | 1        | 0      | 0    | 0   |
| `beq`       | X      | 0      | X        | 0        | 0       | 0        | 1      | 0    | 0   |
| `addi`      | 0      | 1      | 0        | 1        | 0       | 0        | 0      | 0    | 0   |
| `slti`      | 0      | 1      | 0        | 1        | 0       | 0        | 0      | 0    | 0   |
| `andi`      | 0      | 1      | 0        | 1        | 0       | 0        | 0      | 0    | 0   |
| `ori`       | 0      | 1      | 0        | 1        | 0       | 0        | 0      | 0    | 0   |
| `j`         | X      | X      | X        | 0        | 0       | 0        | 0      | 1    | 0   |
| `jal`       | X      | X      | X        | 1        | 0       | 0        | 0      | 1    | 1   |
| `jr`        | 1      | 0      | 0        | 0        | 0       | 0        | 0      | 1    | 0   |

---

## Módulos implementados

```
RTL/Fase_3/
├── PC.v                  — Sin cambios respecto a Fase 2
├── Adder.v               — Sin cambios
├── InstructionMemory.v   — Carga TestF3_MemInst.mem
├── RegisterFile.v        — Sin cambios
├── ALU.v                 — Sin cambios estructurales
├── SignExtend.v          — Sin cambios
├── Mux2.v                — Sin cambios
├── ShiftLeft2.v          — Sin cambios
├── DataMemory.v          — Sin cambios
├── ALUControl.v          — Operaciones XOR y NOR añadidas
├── Control.v             — Señales Jump y JAL para opcodes 000010 / 000011
├── IF_ID.v               — Agrega enable (stall) y flush
├── ID_EX.v               — Agrega flush para burbujas
├── EX_MEM.v              — Sin cambios
├── MEM_WB.v              — Sin cambios
└── MIPS_Top.v            — Forwarding unit, hazard detection, lógica JAL/JR, Mux3 de PC
```

---

## Pipeline de 5 etapas

```
   IF           IF/ID          ID           ID/EX          EX          EX/MEM         MEM         MEM/WB         WB
┌──────┐     ┌─────────┐   ┌──────┐     ┌─────────┐   ┌──────┐     ┌─────────┐   ┌──────┐     ┌─────────┐   ┌──────┐
│  PC  │────►│ PC+4    │──►│ Ctrl │────►│ Señales │──►│ ALU  │────►│ ALUres  │──►│ DMEM │────►│ rdData  │──►│ MUX  │
│  IM  │     │ Instr   │   │ RF   │     │ Datos   │   │  FW  │     │ wrData  │   │      │     │ ALUres  │   │  RF  │
└──────┘     └─────────┘   └──────┘     └─────────┘   └──────┘     └─────────┘   └──────┘     └─────────┘   └──────┘
                 ▲ enable                   ▲ flush         │                                         │
                 │ flush               stall│           forwarding ◄───────────────────────────────────┘
                 └────────────── Hazard Detection Unit ──────┘
```

Todos los buffers y el PC se disparan en el **mismo flanco positivo del mismo reloj**, condición fundamental del capítulo 4.6 de P&H.

---

## Resolución de hazards

### 1 — Forwarding (hazards de datos RAW)

Una instrucción en EX puede necesitar el resultado de una instrucción que todavía no llegó a Write-Back. La forwarding unit detecta estas dependencias y selecciona el operando correcto sin insertar stalls:

```
// Forwarding EX/MEM → entrada A de la ALU
forward_a_from_ex_mem = EX_MEM.RegWrite
                      AND (EX_MEM.write_reg ≠ 0)
                      AND (EX_MEM.write_reg == ID_EX.rs)

// Forwarding MEM/WB → entrada A de la ALU
forward_a_from_mem_wb = MEM_WB.RegWrite
                      AND (MEM_WB.write_reg ≠ 0)
                      AND NOT forward_a_from_ex_mem
                      AND (MEM_WB.write_reg == ID_EX.rs)
```

La misma lógica se aplica simétricamente para la entrada B (`rt`). La prioridad es siempre EX/MEM sobre MEM/WB, porque EX/MEM contiene el resultado más reciente.

### 2 — Load-use hazard (stall de 1 ciclo)

Cuando un `lw` es seguido de una instrucción que lee el registro que acaba de cargar, el dato no está disponible hasta la etapa MEM del `lw`. El forwarding no puede resolver esto (el dato aún no existe en EX), por lo que se inserta una burbuja:

```
load_use_stall = ID_EX.MemRead
               AND (ID_EX.rt ≠ 0)
               AND ((ID_EX.rt == id_rs  AND instrucción_usa_rs)
                 OR (ID_EX.rt == id_rt  AND instrucción_usa_rt))
```

Efecto de `stall = 1`:
- El PC se congela (no incrementa)
- El buffer IF/ID se congela (`enable = 0`)
- El buffer ID/EX se vacía con flush (NOP viaja por el pipeline)

### 3 — Flush de control (saltos)

Cuando se detecta un salto, las instrucciones que ya entraron al pipeline después de él son incorrectas y deben descartarse:

| Tipo de salto | Dónde se detecta | Buffers que se vacían |
|---|---|---|
| `beq` tomado (`Branch AND zero`) | Etapa EX | IF/ID, ID/EX |
| `j` / `jal` | Etapa ID | IF/ID, ID/EX |
| `jr` | Etapa ID | IF/ID, ID/EX |

### Lógica de selección del PC

```
next_pc = branch_taken_ex  ? ex_branch_target   :   // beq tomado (resuelto en EX)
          stall             ? pc                 :   // stall: congela el PC
          id_Jump           ? id_jump_target     :   // j / jal / jr (resuelto en ID)
                              if_pc_plus_4           // flujo normal
```

---

## Instrucciones JAL y JR — mecanismo completo

`jal` es el puente entre hardware y software para llamadas a subrutina:

1. La Unidad de Control activa `Jump = 1` y `JAL = 1`
2. En la etapa ID, el PC salta a la dirección `jump_addr`
3. En la etapa WB, se escriben simultáneamente:
   - **dato**: `PC+4` (en lugar del resultado de la ALU o memoria)
   - **destino**: registro `$ra` (`$31`), en lugar del campo `rd`

```verilog
// En WB — lógica JAL
wb_write_data = wb_JAL ? wb_pc_plus4  : wb_alu_or_mem;
wb_write_reg  = wb_JAL ? 5'd31        : wb_write_reg_normal;
```

`jr $ra` es una instrucción Tipo R con `funct = 001000`. La unidad de control la trata como salto: `Jump = 1`, y `next_pc = registers[rs]` (el contenido de `$ra`).

> `$ra` no tiene ningún rol especial en el hardware; es simplemente el registro 31. Su significado como "dirección de retorno" es una **convención del ISA** que el compilador y el programador respetan.

---

## Algoritmo: Test de Primalidad con JAL / JR

### Fundamento matemático

Dado N ∈ ℕ, N es primo si y solo si no existe ningún divisor d con 2 ≤ d ≤ N−1 tal que `N mod d = 0`. Como el ISA no incluye `div`, el módulo se calcula por **restas sucesivas**: partir de `rem = N` y restar `d` repetidamente mientras `rem ≥ d`. Si `rem = 0` al terminar, `d` divide a `N`.

La subrutina `mod_sub` encapsula este cálculo. Se invoca con `jal` (que guarda `PC+4` en `$ra`) y retorna con `jr $ra`.

### Asignación de registros

| Registro | Uso en el algoritmo |
|----------|---------------------|
| `$t0`    | N — número a evaluar (cargado desde memoria con `lw`) |
| `$t1`    | i — divisor (empieza en 2, llega hasta N−1) |
| `$t2`    | rem — residuo parcial (copia de N, se le resta i) |
| `$t3`    | flag temporal (resultado de `slt`) |
| `$t4`    | result: 1 = primo, 0 = no primo |
| `$t6`    | N−1 (límite superior del bucle externo) |
| `$ra`    | dirección de retorno guardada por `jal` |

### Pseudocódigo ensamblador

```asm
        lw   $t0, 16($zero)       # N = MEM[4]
        addi $t1, $zero, 2        # i = 2
        addi $t4, $zero, 1        # result = 1 (asume primo)
        sub  $t6, $t0, $t4        # t6 = N - 1

outer_chk:
        slt  $t3, $t6, $t1        # t3 = (N-1 < i)?
        beq  $t3, $zero, skip     # si no → i <= N-1 → continúa
        j    save_result          # si sí → i > N-1 → es primo
skip:
        jal  mod_sub              # ← JAL: $ra = PC+4, salta a mod_sub
        beq  $t2, $zero, not_prime# rem == 0 → no es primo
        addi $t1, $t1, 1          # i++
        j    outer_chk

not_prime:
        add  $t4, $zero, $zero    # result = 0

save_result:
        sw   $t4, 20($zero)       # MEM[5] = result
halt:
        j    halt                 # bucle infinito (fin)

# ── Subrutina ──────────────────────────────────────────
mod_sub:
        add  $t2, $t0, $zero      # rem = N

mod_loop:
        slt  $t3, $t2, $t1        # t3 = (rem < i)?
        beq  $t3, $zero, do_sub   # rem >= i → seguir restando
        jr   $ra                  # ← JR: rem < i → retorna

do_sub:
        sub  $t2, $t2, $t1        # rem -= i
        j    mod_loop
```

### Instrucciones Tipo J en el archivo de memoria

| Índice | Instrucción        | Tipo   | Binario (32 bits)                    |
|--------|--------------------|--------|--------------------------------------|
| 7      | `jal mod_sub`      | J (000011) | `00001100000000000000000000001110` |
| 10     | `j outer_chk`      | J (000010) | `00001000000000000000000000000101` |
| 13     | `j halt`           | J (000010) | `00001000000000000000000000001101` |
| 18     | `j mod_loop`       | J (000010) | `00001000000000000000000000001111` |
| 19     | `jr $ra`           | R (001000) | `00000011111000000000000000001000` |

### Resultados esperados en simulación

| Señal / Registro | N = 7 (primo) | N = 4 (no primo) |
|------------------|---------------|------------------|
| `MEM[5]`         | 1             | 0                |
| `$ra` (reg 31)   | 0x00000020    | 0x00000020       |
| PC tras `jr $ra` | 0x20          | 0x20             |
| PC en `halt`     | 0x34          | 0x34             |

---

## Archivos de memoria

| Archivo              | Contenido |
|----------------------|-----------|
| `TestF3_MemInst.mem` | Programa completo de primalidad con `j`, `jal`, `jr` |
| `TestF1_BReg.mem`    | Banco de registros inicial de Fase 1 (R0=0, …, R31=31) |

> El archivo `.mem` de la Fase 3 es **solo de referencia**. La evaluación se realiza con el archivo que proporcione el profesor.

---

## Cómo simular en ModelSim

1. Crear un proyecto nuevo y agregar todos los archivos `.v` de `RTL/Fase_3/`
2. Compilar en orden: módulos individuales → buffers → `MIPS_Top.v` → `tb_MIPS.v`
3. Copiar `TestF3_MemInst.mem` al directorio de trabajo del proyecto
4. Simular `tb_MIPS` durante al menos **600 ns** (suficiente para N = 5)
5. En la ventana Wave agregar:

| Señal | Qué muestra |
|---|---|
| `pc` | Dirección de la instrucción actual |
| `instruction` | Instrucción de 32 bits en IF |
| `alu_result` | Resultado de la ALU en EX |
| `RegWrite` | Escritura activa en WB |
| `rf.registers[16]` | Contenido de `$s0` (resultado) |
| `rf.registers[31]` | Contenido de `$ra` (verificar JAL) |
| `branch_taken_ex` | Confirmar que BEQ se resuelve en EX |

**Verificación rápida:** tras el primer `jal`, el registro `$ra` debe contener `0x00000020` (PC+4 de la instrucción [7]). Cuando `jr $ra` se ejecuta, el PC debe saltar a `0x20`.

---

## Herramientas

| Herramienta | Versión recomendada | Uso |
|-------------|---------------------|-----|
| ModelSim-Altera | 20.1 o superior | Simulación y verificación |

---

## Estado del proyecto

| Fase | Contenido                                          | Estado       |
|------|----------------------------------------------------|--------------|
| ✅ Fase 1 | Datapath single-cycle, instrucciones Tipo R     | Completa     |
| ✅ Fase 2 | Instrucciones Tipo I, 4 buffers de pipeline     | Completa     |
| ✅ Fase 3 | Instrucciones Tipo J, forwarding, hazards       | **Completa** |

---

## Referencias

1. D. A. Patterson y J. L. Hennessy, *Computer Organization and Design: The Hardware/Software Interface*, 5ª ed. Morgan Kaufmann, 2014. Caps. 4.3, 4.4, 4.6.
2. MIPS Technologies, *MIPS32 Architecture for Programmers Vol. II: The MIPS32 Instruction Set*. MIPS Technologies, 2001.
3. S. Brown y Z. Vranesic, *Fundamentals of Digital Logic with Verilog Design*, 3ª ed. McGraw-Hill, 2014.
4. D. M. Harris y S. L. Harris, *Digital Design and Computer Architecture*, 2ª ed. Morgan Kaufmann, 2012.
5. Intel/Altera, *ModelSim-Altera Software Simulation User Guide*. Altera Corporation, 2016.
