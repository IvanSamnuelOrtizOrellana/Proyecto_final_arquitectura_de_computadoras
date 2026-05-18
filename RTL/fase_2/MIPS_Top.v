// =============================================================
// MIPS_Top - Fase 2
// Datapath single-cycle con buffers de pipeline preparados
// para futura extensión a pipeline completo (Cap. 4.6 P&H).
//
// Instrucciones soportadas:
//   Tipo R: add, sub, and, or, xor, nor, slt, sll, srl, nop
//   Tipo I: addi, slti, andi, ori, lw, sw, beq
//
// Flujo: IF -> IF/ID -> ID -> ID/EX -> EX -> EX/MEM -> MEM -> MEM/WB -> WB
// =============================================================

`include "PipelineBuffers.v"

module MIPS_Top(
    input clk,
    input reset
);

    // ===========================================================
    // ETAPA IF — Instruction Fetch
    // ===========================================================
    wire [31:0] pc;
    wire [31:0] pc_plus4_if;
    wire [31:0] instruction_if;
    wire [31:0] next_pc;
    wire        pc_src;            // 1 = salto BEQ tomado
    wire [31:0] branch_target_mem; // dirección de salto (viene de EX/MEM)

    PC pc_reg(
        .clk(clk), .reset(reset),
        .next_pc(next_pc),
        .pc(pc)
    );

    Adder adder_pc(
        .a(pc), .b(32'd4),
        .result(pc_plus4_if)
    );

    InstructionMemory im(
        .address(pc),
        .instruction(instruction_if)
    );

    // MUX selección de siguiente PC: flujo normal o salto BEQ
    Mux2 #(32) mux_next_pc(
        .d0(pc_plus4_if),
        .d1(branch_target_mem),
        .sel(pc_src),
        .out(next_pc)
    );

    // ===========================================================
    // BUFFER IF/ID
    // ===========================================================
    wire [31:0] if_id_pc_plus4;
    wire [31:0] if_id_instr;

    IF_ID_Buffer if_id_buf(
        .clk(clk), .reset(reset),
        .pc_plus4_in(pc_plus4_if),
        .instruction_in(instruction_if),
        .pc_plus4_out(if_id_pc_plus4),
        .instruction_out(if_id_instr)
    );

    // ===========================================================
    // ETAPA ID — Instruction Decode / Register Read
    // ===========================================================

    // Señales de control (combinacionales desde Control)
    wire        RegDst_id, ALUSrc_id, MemtoReg_id, RegWrite_id;
    wire        MemRead_id, MemWrite_id, Branch_id;
    wire [2:0]  ALUOp_id;

    // Datos leídos
    wire [31:0] read_data1_id, read_data2_id;
    wire [31:0] sign_ext_imm_id;

    // Retroalimentación desde WB
    wire        RegWrite_wb;
    wire [4:0]  write_reg_wb;
    wire [31:0] write_data_wb;

    Control ctrl(
        .opcode(if_id_instr[31:26]),
        .RegDst(RegDst_id),     .ALUSrc(ALUSrc_id),
        .MemtoReg(MemtoReg_id), .RegWrite(RegWrite_id),
        .MemRead(MemRead_id),   .MemWrite(MemWrite_id),
        .Branch(Branch_id),     .ALUOp(ALUOp_id)
    );

    RegisterFile rf(
        .clk(clk),
        .RegWrite(RegWrite_wb),
        .rs(if_id_instr[25:21]),
        .rt(if_id_instr[20:16]),
        .rd(write_reg_wb),
        .write_data(write_data_wb),
        .read_data1(read_data1_id),
        .read_data2(read_data2_id)
    );

    SignExtend sign_ext(
        .in(if_id_instr[15:0]),
        .out(sign_ext_imm_id)
    );

    // ===========================================================
    // BUFFER ID/EX
    // ===========================================================
    wire        RegDst_ex, ALUSrc_ex, MemtoReg_ex, RegWrite_ex;
    wire        MemRead_ex, MemWrite_ex, Branch_ex;
    wire [2:0]  ALUOp_ex;
    wire [31:0] pc_plus4_ex;
    wire [31:0] read_data1_ex, read_data2_ex, sign_ext_imm_ex;
    wire [4:0]  rs_ex, rt_ex, rd_ex, shamt_ex;
    wire [5:0]  funct_ex;

    ID_EX_Buffer id_ex_buf(
        .clk(clk), .reset(reset),
        // Control
        .RegDst_in(RegDst_id),     .ALUSrc_in(ALUSrc_id),
        .MemtoReg_in(MemtoReg_id), .RegWrite_in(RegWrite_id),
        .MemRead_in(MemRead_id),   .MemWrite_in(MemWrite_id),
        .Branch_in(Branch_id),     .ALUOp_in(ALUOp_id),
        // Datos
        .pc_plus4_in(if_id_pc_plus4),
        .read_data1_in(read_data1_id),
        .read_data2_in(read_data2_id),
        .sign_ext_imm_in(sign_ext_imm_id),
        .rs_in(if_id_instr[25:21]),
        .rt_in(if_id_instr[20:16]),
        .rd_in(if_id_instr[15:11]),
        .shamt_in(if_id_instr[10:6]),
        .funct_in(if_id_instr[5:0]),
        // Salidas control
        .RegDst_out(RegDst_ex),    .ALUSrc_out(ALUSrc_ex),
        .MemtoReg_out(MemtoReg_ex),.RegWrite_out(RegWrite_ex),
        .MemRead_out(MemRead_ex),  .MemWrite_out(MemWrite_ex),
        .Branch_out(Branch_ex),    .ALUOp_out(ALUOp_ex),
        // Salidas datos
        .pc_plus4_out(pc_plus4_ex),
        .read_data1_out(read_data1_ex),
        .read_data2_out(read_data2_ex),
        .sign_ext_imm_out(sign_ext_imm_ex),
        .rs_out(rs_ex), .rt_out(rt_ex), .rd_out(rd_ex),
        .shamt_out(shamt_ex), .funct_out(funct_ex)
    );

    // ===========================================================
    // ETAPA EX — Execute
    // ===========================================================
    wire [4:0]  write_reg_ex;
    wire [31:0] alu_b_in_ex;
    wire [3:0]  alu_control_ex;
    wire [31:0] alu_result_ex;
    wire        zero_ex;
    wire [31:0] branch_target_ex;

    // MUX RegDst: rd (tipo R) vs rt (tipo I)
    Mux2 #(5) mux_reg_dst(
        .d0(rt_ex), .d1(rd_ex),
        .sel(RegDst_ex),
        .out(write_reg_ex)
    );

    // MUX ALUSrc: registro vs inmediato con extensión de signo
    Mux2 #(32) mux_alu_src(
        .d0(read_data2_ex),
        .d1(sign_ext_imm_ex),
        .sel(ALUSrc_ex),
        .out(alu_b_in_ex)
    );

    ALUControl alu_ctrl(
        .funct(funct_ex),
        .ALUOp(ALUOp_ex),
        .alu_control(alu_control_ex)
    );

    ALU alu(
        .a(read_data1_ex),
        .b(alu_b_in_ex),
        .shamt(shamt_ex),
        .alu_control(alu_control_ex),
        .result(alu_result_ex),
        .zero(zero_ex)
    );

    // Cálculo de dirección de salto BEQ: PC+4 + (imm << 2)
    Adder adder_branch(
        .a(pc_plus4_ex),
        .b({sign_ext_imm_ex[29:0], 2'b00}),
        .result(branch_target_ex)
    );

    // ===========================================================
    // BUFFER EX/MEM
    // ===========================================================
    wire        MemtoReg_mem, RegWrite_mem, MemRead_mem, MemWrite_mem, Branch_mem;
    wire        zero_mem;
    wire [31:0] alu_result_mem, read_data2_mem;
    wire [4:0]  write_reg_mem;

    EX_MEM_Buffer ex_mem_buf(
        .clk(clk), .reset(reset),
        // Control
        .MemtoReg_in(MemtoReg_ex), .RegWrite_in(RegWrite_ex),
        .MemRead_in(MemRead_ex),   .MemWrite_in(MemWrite_ex),
        .Branch_in(Branch_ex),
        // Datos
        .branch_target_in(branch_target_ex),
        .zero_in(zero_ex),
        .alu_result_in(alu_result_ex),
        .read_data2_in(read_data2_ex),
        .write_reg_in(write_reg_ex),
        // Salidas control
        .MemtoReg_out(MemtoReg_mem), .RegWrite_out(RegWrite_mem),
        .MemRead_out(MemRead_mem),   .MemWrite_out(MemWrite_mem),
        .Branch_out(Branch_mem),
        // Salidas datos
        .branch_target_out(branch_target_mem),
        .zero_out(zero_mem),
        .alu_result_out(alu_result_mem),
        .read_data2_out(read_data2_mem),
        .write_reg_out(write_reg_mem)
    );

    // ===========================================================
    // ETAPA MEM — Memory Access
    // ===========================================================
    wire [31:0] mem_read_data_mem;

    DataMemory dm(
        .clk(clk),
        .MemRead(MemRead_mem),
        .MemWrite(MemWrite_mem),
        .address(alu_result_mem),
        .write_data(read_data2_mem),
        .read_data(mem_read_data_mem)
    );

    // Lógica BEQ: salto tomado si Branch=1 Y resultado ALU=0
    assign pc_src = Branch_mem & zero_mem;

    // ===========================================================
    // BUFFER MEM/WB
    // ===========================================================
    wire        MemtoReg_wb;
    wire [31:0] mem_read_data_wb, alu_result_wb;

    MEM_WB_Buffer mem_wb_buf(
        .clk(clk), .reset(reset),
        // Control
        .MemtoReg_in(MemtoReg_mem), .RegWrite_in(RegWrite_mem),
        // Datos
        .mem_read_data_in(mem_read_data_mem),
        .alu_result_in(alu_result_mem),
        .write_reg_in(write_reg_mem),
        // Salidas control
        .MemtoReg_out(MemtoReg_wb), .RegWrite_out(RegWrite_wb),
        // Salidas datos
        .mem_read_data_out(mem_read_data_wb),
        .alu_result_out(alu_result_wb),
        .write_reg_out(write_reg_wb)
    );

    // ===========================================================
    // ETAPA WB — Write Back
    // ===========================================================
    // MUX MemtoReg: resultado ALU (0) vs dato de memoria (1)
    Mux2 #(32) mux_mem_to_reg(
        .d0(alu_result_wb),
        .d1(mem_read_data_wb),
        .sel(MemtoReg_wb),
        .out(write_data_wb)
    );

endmodule
