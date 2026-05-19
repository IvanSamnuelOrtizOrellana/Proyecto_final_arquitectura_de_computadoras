# =============================================================
#  primality_test.asm  —  Test de Primalidad en MIPS 32-bit
#  Proyecto Final MIPS — Fase 2
#  CUCEI, Universidad de Guadalajara
#
#  DESCRIPCIÓN:
#    Determina si un número N es primo mediante divisiones
#    por restas sucesivas (trial division sin instrucción mul/div).
#
#  PRECONDICIÓN:
#    - N debe estar almacenado en MEM[4] (dirección byte 16)
#      antes de iniciar la simulación. Ejemplo: para N=13,
#      escribir 13 en la posición 4 del archivo DataMemory.
#    - El banco de registros se precarga con TestF1_BReg.mem
#      (registro i = valor i).
#
#  RESULTADO:
#    - MEM[5] (dirección byte 20) = 1  →  N es primo
#    - MEM[5] (dirección byte 20) = 0  →  N NO es primo
#
#  ALGORITMO:
#    result = 1                         # asumir primo
#    i = 2
#    mientras i <= N-1:
#        rem = N
#        mientras rem >= i:
#            rem = rem - i              # mod por restas
#        si rem == 0:
#            result = 0                 # divisor encontrado
#            salir
#        i = i + 1
#    guardar result en MEM[5]
#    halt (loop infinito)
#
#  TRAZA DE EJEMPLO — N=7 (primo):
#    i=2: 7 mod 2 = 1 → no divisor
#    i=3: 7 mod 3 = 1 → no divisor
#    i=4: 7 mod 4 = 3 → no divisor
#    i=5: 7 mod 5 = 2 → no divisor
#    i=6: 7 mod 6 = 1 → no divisor
#    i=7 > N-1=6 → fin → result=1 → primo ✓
#
#  TRAZA DE EJEMPLO — N=9 (no primo):
#    i=2: 9 mod 2 = 1 → no divisor
#    i=3: 9 mod 3 = 0 → DIVISOR → result=0 → no primo ✓
#
#  REGISTROS UTILIZADOS:
#    $t0 = N  (número a verificar)
#    $t1 = i  (candidato a divisor, empieza en 2)
#    $t2 = rem (resto del mod actual)
#    $t3 = temporal para comparaciones slt/beq
#    $t4 = result (1=primo, 0=no primo)
#    $t5 = 1  (constante)
#    $t6 = N-1 (cota superior del lazo exterior)
#
#  INSTRUCCIONES UTILIZADAS:
#    Tipo I: lw, sw, addi, beq
#    Tipo R: add, sub, slt
#
#  MAPA DE MEMORIA (dirección byte → contenido):
#    0x00 (MEM[0]) = libre
#    0x04 (MEM[1]) = libre
#    0x08 (MEM[2]) = libre
#    0x0C (MEM[3]) = libre
#    0x10 (MEM[4]) = N   ← ENTRADA (precarga manual)
#    0x14 (MEM[5]) = result ← SALIDA
# =============================================================

.text
.globl main

main:

# ── INICIALIZACIÓN ────────────────────────────────────────────
init:
    lw   $t0, 16($zero)      # $t0 = N  (cargar desde MEM[4])
    addi $t1, $zero, 2       # $t1 = i = 2
    addi $t5, $zero, 1       # $t5 = 1  (constante)
    addi $t4, $zero, 1       # $t4 = result = 1 (asumir primo)
    sub  $t6, $t0,   $t5     # $t6 = N - 1

# ── LAZO EXTERIOR: for i = 2 to N-1 ──────────────────────────
outer_chk:
    slt  $t3, $t6, $t1       # $t3 = (N-1 < i)  →  i > N-1
    beq  $t3, $t5, done      # si i > N-1 → salir (es primo)

# ── INICIO DEL CÁLCULO DE rem = N mod i ──────────────────────
mod_init:
    add  $t2, $t0, $zero     # $t2 = N (copia fresca para el mod)

# ── LAZO INTERIOR: while rem >= i → rem -= i ─────────────────
mod_loop:
    slt  $t3, $t2, $t1       # $t3 = (rem < i)
    beq  $t3, $t5, mod_done  # si rem < i → terminó el mod
    sub  $t2, $t2, $t1       # rem = rem - i
    beq  $zero, $zero, mod_loop  # repetir (salto incondicional)

# ── VERIFICAR RESIDUO ─────────────────────────────────────────
mod_done:
    beq  $t2, $zero, not_prime   # si rem == 0 → divisor encontrado

# ── INCREMENTAR i Y REPETIR ───────────────────────────────────
    add  $t1, $t1, $t5       # i = i + 1
    beq  $zero, $zero, outer_chk  # volver al lazo exterior

# ── NO PRIMO: se encontró un divisor ─────────────────────────
not_prime:
    add  $t4, $zero, $zero   # result = 0

# ── FIN: guardar resultado y halt ────────────────────────────
done:
    sw   $t4, 20($zero)      # MEM[5] = result
    beq  $zero, $zero, done  # halt (loop infinito)
