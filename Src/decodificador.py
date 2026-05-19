#!/usr/bin/env python3
"""
assembler.py  —  Ensamblador MIPS → Código Máquina Binario
Proyecto Final MIPS — Fase 2
CUCEI, Universidad de Guadalajara

Soporta instrucciones:
  Tipo R : add, sub, and, or, nor, xor, slt, sll, srl, nop
  Tipo I : addi, slti, andi, ori, xori, lui, lw, sw, beq, bne
  Tipo J : j

Uso:
  python3 assembler.py input.asm            → imprime binario en stdout
  python3 assembler.py input.asm -o out.mem → escribe archivo .mem
  python3 assembler.py input.asm --hex      → imprime en hexadecimal

Formato del .asm:
  - Etiquetas terminan en ':'     (e.g.  loop:)
  - Comentarios con '#'
  - Registros: $zero, $t0..$t7, $s0..$s7, $a0..$a3, $v0, $v1, $ra, etc.
  - Inmediatos en decimal o hexadecimal (0x...)
  - lw/sw con formato: lw $rt, offset($rs)
"""

import sys
import re
import argparse

# ── Tabla de registros ────────────────────────────────────────
REGISTERS = {
    '$zero':0, '$at':1,
    '$v0':2,   '$v1':3,
    '$a0':4,   '$a1':5,  '$a2':6,  '$a3':7,
    '$t0':8,   '$t1':9,  '$t2':10, '$t3':11,
    '$t4':12,  '$t5':13, '$t6':14, '$t7':15,
    '$s0':16,  '$s1':17, '$s2':18, '$s3':19,
    '$s4':20,  '$s5':21, '$s6':22, '$s7':23,
    '$t8':24,  '$t9':25,
    '$k0':26,  '$k1':27,
    '$gp':28,  '$sp':29, '$fp':30, '$ra':31,
}
# Alias numéricos ($0 .. $31)
for i in range(32):
    REGISTERS[f'${i}'] = i

# ── Tabla de instrucciones Tipo R (funct 6 bits) ──────────────
TYPE_R = {
    'add':  0b100000,
    'sub':  0b100010,
    'and':  0b100100,
    'or':   0b100101,
    'nor':  0b100111,
    'xor':  0b100110,
    'slt':  0b101010,
    'sll':  0b000000,
    'srl':  0b000010,
    'nop':  0b000000,  # alias: sll $0,$0,0
}

# ── Tabla de instrucciones Tipo I (opcode 6 bits) ─────────────
TYPE_I = {
    'addi': 0b001000,
    'slti': 0b001010,
    'andi': 0b001100,
    'ori':  0b001101,
    'xori': 0b001110,
    'lui':  0b001111,
    'lw':   0b100011,
    'sw':   0b101011,
    'beq':  0b000100,
    'bne':  0b000101,
}

# ── Tipo J ────────────────────────────────────────────────────
TYPE_J = {
    'j': 0b000010,
}


# ─────────────────────────────────────────────────────────────
# Utilidades
# ─────────────────────────────────────────────────────────────

def to_bin(value: int, bits: int) -> str:
    """Convierte entero (con signo) a binario de 'bits' dígitos."""
    if value < 0:
        value = value & ((1 << bits) - 1)
    return format(value, f'0{bits}b')


def parse_int(s: str) -> int:
    """Convierte string de inmediato (decimal o 0x...) a entero."""
    s = s.strip()
    try:
        return int(s, 0)
    except ValueError:
        raise ValueError(f"Inmediato inválido: '{s}'")


def parse_reg(s: str) -> int:
    """Resuelve nombre de registro a número (0-31)."""
    s = s.strip()
    if s not in REGISTERS:
        raise ValueError(f"Registro desconocido: '{s}'")
    return REGISTERS[s]


def parse_mem_operand(s: str):
    """
    Parsea 'offset($rs)' → (offset_int, rs_int).
    Acepta también '($rs)' sin offset (offset = 0).
    """
    s = s.strip()
    m = re.match(r'^(-?(?:0x[\da-fA-F]+|\d+))?\((\$\w+|\$\d+)\)$', s)
    if not m:
        raise ValueError(f"Operando de memoria inválido: '{s}'")
    off_str = m.group(1) or '0'
    rs_str  = m.group(2)
    return parse_int(off_str), parse_reg(rs_str)


# ─────────────────────────────────────────────────────────────
# Paso 1 — Tokenización y recolección de etiquetas
# ─────────────────────────────────────────────────────────────

def first_pass(lines):
    """
    Recorre las líneas del .asm, ignora comentarios/directivas,
    asigna índice de instrucción a cada etiqueta.
    Retorna (tokens, labels) donde tokens es lista de
    (line_num, mnemonic, [operands_raw]).
    """
    tokens = []
    labels = {}
    pc = 0  # índice de instrucción (no dirección byte)

    for lineno, raw in enumerate(lines, start=1):
        line = raw.split('#')[0].strip()   # quitar comentarios
        if not line:
            continue
        if line.startswith('.'):           # ignorar directivas
            continue

        # Puede haber etiqueta al inicio: "label: instrucción"
        # o solo la etiqueta sola en su línea: "label:"
        label_match = re.match(r'^([A-Za-z_]\w*)\s*:(.*)', line)
        if label_match:
            lbl  = label_match.group(1)
            rest = label_match.group(2).strip()
            labels[lbl] = pc
            if not rest:
                continue
            line = rest

        # Separar mnemónico de operandos
        parts = line.split(None, 1)
        mnemonic = parts[0].lower()
        ops_raw  = parts[1].strip() if len(parts) > 1 else ''
        tokens.append((lineno, mnemonic, ops_raw, pc))
        pc += 1

    return tokens, labels


# ─────────────────────────────────────────────────────────────
# Paso 2 — Codificación de instrucciones
# ─────────────────────────────────────────────────────────────

def encode(lineno, mnemonic, ops_raw, pc_idx, labels):
    """
    Codifica una instrucción a string binario de 32 bits.
    pc_idx es el índice (0-based) de esta instrucción.
    """

    # ── NOP ──────────────────────────────────────────────────
    if mnemonic == 'nop':
        return '0' * 32

    # ── Tipo R ───────────────────────────────────────────────
    if mnemonic in TYPE_R:
        funct = TYPE_R[mnemonic]
        ops = [o.strip() for o in ops_raw.split(',')]

        if mnemonic in ('sll', 'srl'):
            # sll $rd, $rt, shamt
            if len(ops) != 3:
                raise ValueError(f"Línea {lineno}: {mnemonic} espera $rd, $rt, shamt")
            rd    = parse_reg(ops[0])
            rt    = parse_reg(ops[1])
            shamt = parse_int(ops[2])
            if not (0 <= shamt <= 31):
                raise ValueError(f"Línea {lineno}: shamt fuera de rango [0,31]: {shamt}")
            return (to_bin(0,6) + to_bin(0,5) + to_bin(rt,5) +
                    to_bin(rd,5) + to_bin(shamt,5) + to_bin(funct,6))
        else:
            # add/sub/and/or/nor/xor/slt: $rd, $rs, $rt
            if len(ops) != 3:
                raise ValueError(f"Línea {lineno}: {mnemonic} espera $rd, $rs, $rt")
            rd = parse_reg(ops[0])
            rs = parse_reg(ops[1])
            rt = parse_reg(ops[2])
            return (to_bin(0,6) + to_bin(rs,5) + to_bin(rt,5) +
                    to_bin(rd,5) + to_bin(0,5) + to_bin(funct,6))

    # ── Tipo I — lw / sw ─────────────────────────────────────
    if mnemonic in ('lw', 'sw'):
        opcode = TYPE_I[mnemonic]
        ops = [o.strip() for o in ops_raw.split(',', 1)]
        if len(ops) != 2:
            raise ValueError(f"Línea {lineno}: {mnemonic} espera $rt, offset($rs)")
        rt         = parse_reg(ops[0])
        offset, rs = parse_mem_operand(ops[1])
        if not (-32768 <= offset <= 32767):
            raise ValueError(f"Línea {lineno}: offset fuera de rango [-32768,32767]: {offset}")
        return to_bin(opcode,6) + to_bin(rs,5) + to_bin(rt,5) + to_bin(offset,16)

    # ── Tipo I — lui ─────────────────────────────────────────
    if mnemonic == 'lui':
        opcode = TYPE_I['lui']
        ops = [o.strip() for o in ops_raw.split(',')]
        if len(ops) != 2:
            raise ValueError(f"Línea {lineno}: lui espera $rt, imm")
        rt  = parse_reg(ops[0])
        imm = parse_int(ops[1])
        if not (0 <= imm <= 65535):
            raise ValueError(f"Línea {lineno}: lui imm fuera de rango [0,65535]: {imm}")
        return to_bin(opcode,6) + to_bin(0,5) + to_bin(rt,5) + to_bin(imm,16)

    # ── Tipo I — beq / bne ───────────────────────────────────
    if mnemonic in ('beq', 'bne'):
        opcode = TYPE_I[mnemonic]
        ops = [o.strip() for o in ops_raw.split(',')]
        if len(ops) != 3:
            raise ValueError(f"Línea {lineno}: {mnemonic} espera $rs, $rt, label_o_offset")
        rs = parse_reg(ops[0])
        rt = parse_reg(ops[1])
        target_raw = ops[2]

        # Resolver etiqueta o número
        if re.match(r'^-?\d+$', target_raw) or target_raw.startswith('0x'):
            offset = parse_int(target_raw)
        elif target_raw in labels:
            target_pc = labels[target_raw]
            offset = target_pc - (pc_idx + 1)  # relativo a PC+4/4
        else:
            raise ValueError(f"Línea {lineno}: etiqueta desconocida '{target_raw}'")

        if not (-32768 <= offset <= 32767):
            raise ValueError(f"Línea {lineno}: offset branch fuera de rango: {offset}")
        return to_bin(opcode,6) + to_bin(rs,5) + to_bin(rt,5) + to_bin(offset,16)

    # ── Tipo I — addi / slti / andi / ori / xori ────────────
    if mnemonic in ('addi', 'slti', 'andi', 'ori', 'xori'):
        opcode = TYPE_I[mnemonic]
        ops = [o.strip() for o in ops_raw.split(',')]
        if len(ops) != 3:
            raise ValueError(f"Línea {lineno}: {mnemonic} espera $rt, $rs, imm")
        rt  = parse_reg(ops[0])
        rs  = parse_reg(ops[1])
        imm = parse_int(ops[2])
        if not (-32768 <= imm <= 65535):
            raise ValueError(f"Línea {lineno}: inmediato fuera de rango: {imm}")
        return to_bin(opcode,6) + to_bin(rs,5) + to_bin(rt,5) + to_bin(imm,16)

    # ── Tipo J — j ───────────────────────────────────────────
    if mnemonic == 'j':
        opcode = TYPE_J['j']
        target_raw = ops_raw.strip()
        if target_raw in labels:
            target_idx = labels[target_raw]
            target_addr = target_idx * 4           # dirección byte
            target_field = target_addr >> 2        # campo de 26 bits
        elif re.match(r'^-?\d+$', target_raw) or target_raw.startswith('0x'):
            target_field = parse_int(target_raw) & 0x3FFFFFF
        else:
            raise ValueError(f"Línea {lineno}: etiqueta desconocida para j: '{target_raw}'")
        return to_bin(opcode,6) + to_bin(target_field,26)

    raise ValueError(f"Línea {lineno}: instrucción desconocida '{mnemonic}'")


# ─────────────────────────────────────────────────────────────
# Ensamblador completo
# ─────────────────────────────────────────────────────────────

def assemble(source: str) -> list[str]:
    """
    Recibe el texto fuente .asm y devuelve lista de strings
    binarios de 32 bits, uno por instrucción.
    """
    lines = source.splitlines()
    tokens, labels = first_pass(lines)

    binaries = []
    for lineno, mnemonic, ops_raw, pc_idx in tokens:
        try:
            b = encode(lineno, mnemonic, ops_raw, pc_idx, labels)
        except ValueError as e:
            print(f"ERROR: {e}", file=sys.stderr)
            sys.exit(1)
        if len(b) != 32:
            print(f"ERROR: instrucción en línea {lineno} produjo {len(b)} bits", file=sys.stderr)
            sys.exit(1)
        binaries.append(b)

    return binaries


# ─────────────────────────────────────────────────────────────
# Función de verificación — decodifica un binario de vuelta
# (útil para debug)
# ─────────────────────────────────────────────────────────────

REG_NAMES = {v: k for k, v in REGISTERS.items() if k.startswith('$') and not k[1:].isdigit()}
FUNCT_NAMES = {v: k for k, v in TYPE_R.items()}
OPCODE_NAMES = {v: k for k, v in {**TYPE_I, **TYPE_J}.items()}

def decode_instruction(binary: str) -> str:
    """Decodifica un string de 32 bits a mnemónico legible (para debug)."""
    if len(binary) != 32:
        return "ERROR: longitud incorrecta"
    b = int(binary, 2)
    opcode = (b >> 26) & 0x3F
    rs     = (b >> 21) & 0x1F
    rt     = (b >> 16) & 0x1F
    rd     = (b >> 11) & 0x1F
    shamt  = (b >>  6) & 0x1F
    funct  = b & 0x3F
    imm16  = b & 0xFFFF
    if imm16 >= 0x8000:
        imm16_signed = imm16 - 0x10000
    else:
        imm16_signed = imm16
    target = b & 0x3FFFFFF

    def rn(n): return REG_NAMES.get(n, f'${n}')

    if opcode == 0:  # Tipo R
        name = FUNCT_NAMES.get(funct, f'funct={funct}')
        if name in ('sll', 'srl'):
            return f"{name} {rn(rd)}, {rn(rt)}, {shamt}"
        if name == 'nop' and rs == 0 and rt == 0 and rd == 0 and shamt == 0:
            return "nop"
        return f"{name} {rn(rd)}, {rn(rs)}, {rn(rt)}"
    elif opcode in (0b000010,):  # Tipo J
        return f"j {target << 2}"
    elif opcode in (0b100011,):  # lw
        return f"lw {rn(rt)}, {imm16_signed}({rn(rs)})"
    elif opcode in (0b101011,):  # sw
        return f"sw {rn(rt)}, {imm16_signed}({rn(rs)})"
    else:
        name = OPCODE_NAMES.get(opcode, f'op={opcode}')
        if name in ('beq', 'bne'):
            return f"{name} {rn(rs)}, {rn(rt)}, {imm16_signed}"
        return f"{name} {rn(rt)}, {rn(rs)}, {imm16_signed}"


# ─────────────────────────────────────────────────────────────
# CLI
# ─────────────────────────────────────────────────────────────

def main():
    parser = argparse.ArgumentParser(
        description="Ensamblador MIPS Fase 2 — CUCEI UDG",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Ejemplos:
  python3 assembler.py primality_test.asm
  python3 assembler.py primality_test.asm -o TestF2_Primalidad.mem
  python3 assembler.py primality_test.asm --hex
  python3 assembler.py primality_test.asm --decode
        """
    )
    parser.add_argument("input",  help="Archivo fuente .asm")
    parser.add_argument("-o", "--output", help="Archivo de salida .mem (default: stdout)")
    parser.add_argument("--hex",    action="store_true", help="Imprimir en hexadecimal además de binario")
    parser.add_argument("--decode", action="store_true", help="Imprimir decodificación de vuelta para verificar")
    args = parser.parse_args()

    # Leer fuente
    try:
        with open(args.input, 'r', encoding='utf-8') as f:
            source = f.read()
    except FileNotFoundError:
        print(f"ERROR: no se encontró el archivo '{args.input}'", file=sys.stderr)
        sys.exit(1)

    # Ensamblar
    binaries = assemble(source)

    # Construir salida
    lines_out = [
        f"// Generado por assembler.py — MIPS Fase 2 CUCEI",
        f"// Fuente: {args.input}",
        f"// Total instrucciones: {len(binaries)}",
        "",
    ]
    for i, b in enumerate(binaries):
        if args.decode:
            decoded = decode_instruction(b)
            comment = f"  // [{i:2d}] {decoded}"
        else:
            comment = ""
        if args.hex:
            hex_val = format(int(b, 2), '08X')
            lines_out.append(f"{b}  // 0x{hex_val}{comment}")
        else:
            lines_out.append(f"{b}{comment}")

    output_text = '\n'.join(lines_out) + '\n'

    # Escribir o imprimir
    if args.output:
        with open(args.output, 'w', encoding='utf-8') as f:
            f.write(output_text)
        print(f"✓ {len(binaries)} instrucciones escritas en '{args.output}'")
    else:
        print(output_text, end='')


if __name__ == '__main__':
    main()
