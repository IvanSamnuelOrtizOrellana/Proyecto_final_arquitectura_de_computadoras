// Datapath principal MIPS segmentado de 5 etapas para instrucciones R, I y J.
module MIPS_Top(
    input clk,
    input reset
);
    // =========================
    // IF: Instruction Fetch
    // =========================
    wire [31:0] pc;
    wire [31:0] next_pc;
    wire [31:0] if_pc_plus_4;
    wire [31:0] instruction;

    // =========================
    // IF/ID
    // =========================
    wire [31:0] if_id_pc_plus_4;
    wire [31:0] if_id_instruction;
    wire if_id_enable;
    wire if_id_flush;

    // =========================
    // ID: Instruction Decode
    // =========================
    wire [5:0] id_opcode;
    wire [4:0] id_rs;
    wire [4:0] id_rt;
    wire [4:0] id_rd;
    wire [4:0] id_shamt;
    wire [5:0] id_funct;

    wire [31:0] rf_read_data1;
    wire [31:0] rf_read_data2;
    wire [31:0] id_read_data1;
    wire [31:0] id_read_data2;
    wire [31:0] id_sign_ext_imm;

    wire id_RegDst;
    wire id_ALUSrc;
    wire id_MemtoReg;
    wire id_RegWrite;
    wire id_MemRead;
    wire id_MemWrite;
    wire id_Branch;
    wire id_Jump;
    wire [1:0] id_ALUOp;

    wire [31:0] id_jump_target;
    wire id_uses_rs;
    wire id_uses_rt;
    wire load_use_stall;
    wire stall;
    wire id_ex_flush;

    // =========================
    // ID/EX
    // =========================
    wire [31:0] id_ex_pc_plus_4;
    wire [31:0] id_ex_read_data1;
    wire [31:0] id_ex_read_data2;
    wire [31:0] id_ex_sign_ext_imm;
    wire [4:0] id_ex_rs;
    wire [4:0] id_ex_rt;
    wire [4:0] id_ex_rd;
    wire [4:0] id_ex_shamt;
    wire [5:0] id_ex_funct;

    wire id_ex_RegDst;
    wire id_ex_ALUSrc;
    wire id_ex_MemtoReg;
    wire id_ex_RegWrite;
    wire id_ex_MemRead;
    wire id_ex_MemWrite;
    wire id_ex_Branch;
    wire [1:0] id_ex_ALUOp;

    // =========================
    // EX: Execute
    // =========================
    wire [31:0] ex_forward_a;
    wire [31:0] ex_forward_b;
    wire [31:0] ex_alu_b_in;
    wire [31:0] ex_branch_offset;
    wire [31:0] ex_branch_target;
    wire [31:0] alu_result;
    wire [4:0] ex_write_reg;
    wire [3:0] alu_control;
    wire zero;
    wire branch_taken_ex;
    wire ex_valid_RegWrite;

    wire forward_a_from_ex_mem;
    wire forward_a_from_mem_wb;
    wire forward_b_from_ex_mem;
    wire forward_b_from_mem_wb;

    // =========================
    // EX/MEM
    // =========================
    wire [31:0] ex_mem_alu_result;
    wire [31:0] ex_mem_write_data;
    wire [4:0] ex_mem_write_reg;

    wire ex_mem_MemtoReg;
    wire ex_mem_RegWrite;
    wire ex_mem_MemRead;
    wire ex_mem_MemWrite;

    // =========================
    // MEM: Memory
    // =========================
    wire [31:0] mem_read_data;

    // =========================
    // MEM/WB y WB
    // =========================
    wire [31:0] mem_wb_read_data;
    wire [31:0] mem_wb_alu_result;
    wire [4:0] mem_wb_write_reg;
    wire mem_wb_RegWrite;
    wire mem_wb_MemtoReg;
    wire [31:0] write_data_rf;

    // Alias util para el testbench existente: RegWrite visible es el de WB.
    wire RegWrite;

    PC pc_reg(
        .clk(clk),
        .reset(reset),
        .next_pc(next_pc),
        .pc(pc)
    );

    Adder adder_pc(
        .a(pc),
        .b(32'd4),
        .result(if_pc_plus_4)
    );

    InstructionMemory im(
        .address(pc),
        .instruction(instruction)
    );

    assign if_id_enable = ~stall;
    assign if_id_flush = branch_taken_ex | id_Jump;

    IF_ID if_id_reg(
        .clk(clk),
        .reset(reset),
        .enable(if_id_enable),
        .flush(if_id_flush),
        .pc_plus_4_in(if_pc_plus_4),
        .instruction_in(instruction),
        .pc_plus_4_out(if_id_pc_plus_4),
        .instruction_out(if_id_instruction)
    );

    // =========================
    // ID: Instruction Decode
    // =========================
    assign id_opcode = if_id_instruction[31:26];
    assign id_rs = if_id_instruction[25:21];
    assign id_rt = if_id_instruction[20:16];
    assign id_rd = if_id_instruction[15:11];
    assign id_shamt = if_id_instruction[10:6];
    assign id_funct = if_id_instruction[5:0];

    Control ctrl(
        .opcode(id_opcode),
        .RegDst(id_RegDst),
        .ALUSrc(id_ALUSrc),
        .MemtoReg(id_MemtoReg),
        .RegWrite(id_RegWrite),
        .MemRead(id_MemRead),
        .MemWrite(id_MemWrite),
        .Branch(id_Branch),
        .Jump(id_Jump),
        .ALUOp(id_ALUOp)
    );

    RegisterFile rf(
        .clk(clk),
        .RegWrite(RegWrite),
        .rs(id_rs),
        .rt(id_rt),
        .rd(mem_wb_write_reg),
        .write_data(write_data_rf),
        .read_data1(rf_read_data1),
        .read_data2(rf_read_data2)
    );

    SignExtend sign_ext(
        .in(if_id_instruction[15:0]),
        .out(id_sign_ext_imm)
    );

    // Bypass WB->ID para compensar que el banco de registros escribe en flanco.
    assign id_read_data1 = (mem_wb_RegWrite && (mem_wb_write_reg != 5'd0) &&
                            (mem_wb_write_reg == id_rs)) ? write_data_rf : rf_read_data1;
    assign id_read_data2 = (mem_wb_RegWrite && (mem_wb_write_reg != 5'd0) &&
                            (mem_wb_write_reg == id_rt)) ? write_data_rf : rf_read_data2;

    assign id_jump_target = {if_id_pc_plus_4[31:28], if_id_instruction[25:0], 2'b00};

    assign id_uses_rs = (id_opcode == 6'b000000) || // Tipo R
                        (id_opcode == 6'b100011) || // lw
                        (id_opcode == 6'b101011) || // sw
                        (id_opcode == 6'b000100) || // beq
                        (id_opcode == 6'b001000);   // addi

    assign id_uses_rt = (id_opcode == 6'b000000) || // Tipo R
                        (id_opcode == 6'b101011) || // sw
                        (id_opcode == 6'b000100);   // beq

    assign load_use_stall = id_ex_MemRead && (id_ex_rt != 5'd0) &&
                            ((id_uses_rs && (id_ex_rt == id_rs)) ||
                             (id_uses_rt && (id_ex_rt == id_rt)));
    assign stall = load_use_stall & ~branch_taken_ex;
    assign id_ex_flush = stall | branch_taken_ex | id_Jump;

    // Prioridad: branch tomado en EX, luego stall, luego jump en ID, luego PC+4.
    assign next_pc = branch_taken_ex ? ex_branch_target :
                     (stall ? pc :
                     (id_Jump ? id_jump_target : if_pc_plus_4));

    ID_EX id_ex_reg(
        .clk(clk),
        .reset(reset),
        .flush(id_ex_flush),
        .pc_plus_4_in(if_id_pc_plus_4),
        .read_data1_in(id_read_data1),
        .read_data2_in(id_read_data2),
        .sign_ext_imm_in(id_sign_ext_imm),
        .rs_in(id_rs),
        .rt_in(id_rt),
        .rd_in(id_rd),
        .shamt_in(id_shamt),
        .funct_in(id_funct),
        .RegDst_in(id_RegDst),
        .ALUSrc_in(id_ALUSrc),
        .MemtoReg_in(id_MemtoReg),
        .RegWrite_in(id_RegWrite),
        .MemRead_in(id_MemRead),
        .MemWrite_in(id_MemWrite),
        .Branch_in(id_Branch),
        .ALUOp_in(id_ALUOp),
        .pc_plus_4_out(id_ex_pc_plus_4),
        .read_data1_out(id_ex_read_data1),
        .read_data2_out(id_ex_read_data2),
        .sign_ext_imm_out(id_ex_sign_ext_imm),
        .rs_out(id_ex_rs),
        .rt_out(id_ex_rt),
        .rd_out(id_ex_rd),
        .shamt_out(id_ex_shamt),
        .funct_out(id_ex_funct),
        .RegDst_out(id_ex_RegDst),
        .ALUSrc_out(id_ex_ALUSrc),
        .MemtoReg_out(id_ex_MemtoReg),
        .RegWrite_out(id_ex_RegWrite),
        .MemRead_out(id_ex_MemRead),
        .MemWrite_out(id_ex_MemWrite),
        .Branch_out(id_ex_Branch),
        .ALUOp_out(id_ex_ALUOp)
    );

    // =========================
    // EX: Execute
    // =========================
    assign forward_a_from_ex_mem = ex_mem_RegWrite && ~ex_mem_MemRead &&
                                   (ex_mem_write_reg != 5'd0) &&
                                   (ex_mem_write_reg == id_ex_rs);
    assign forward_b_from_ex_mem = ex_mem_RegWrite && ~ex_mem_MemRead &&
                                   (ex_mem_write_reg != 5'd0) &&
                                   (ex_mem_write_reg == id_ex_rt);
    assign forward_a_from_mem_wb = mem_wb_RegWrite && (mem_wb_write_reg != 5'd0) &&
                                   ~forward_a_from_ex_mem &&
                                   (mem_wb_write_reg == id_ex_rs);
    assign forward_b_from_mem_wb = mem_wb_RegWrite && (mem_wb_write_reg != 5'd0) &&
                                   ~forward_b_from_ex_mem &&
                                   (mem_wb_write_reg == id_ex_rt);

    assign ex_forward_a = forward_a_from_ex_mem ? ex_mem_alu_result :
                          (forward_a_from_mem_wb ? write_data_rf : id_ex_read_data1);
    assign ex_forward_b = forward_b_from_ex_mem ? ex_mem_alu_result :
                          (forward_b_from_mem_wb ? write_data_rf : id_ex_read_data2);

    Mux2 #(32) mux_alu_src(
        .d0(ex_forward_b),
        .d1(id_ex_sign_ext_imm),
        .sel(id_ex_ALUSrc),
        .out(ex_alu_b_in)
    );

    ALUControl alu_ctrl(
        .funct(id_ex_funct),
        .ALUOp(id_ex_ALUOp),
        .alu_control(alu_control)
    );

    ALU alu(
        .a(ex_forward_a),
        .b(ex_alu_b_in),
        .shamt(id_ex_shamt),
        .alu_control(alu_control),
        .result(alu_result),
        .zero(zero)
    );

    ShiftLeft2 shift_branch(
        .in(id_ex_sign_ext_imm),
        .out(ex_branch_offset)
    );

    Adder adder_branch(
        .a(id_ex_pc_plus_4),
        .b(ex_branch_offset),
        .result(ex_branch_target)
    );

    assign branch_taken_ex = id_ex_Branch & zero;

    Mux2 #(5) mux_reg_dst(
        .d0(id_ex_rt),
        .d1(id_ex_rd),
        .sel(id_ex_RegDst),
        .out(ex_write_reg)
    );

    assign ex_valid_RegWrite = id_ex_RegWrite & (alu_control != 4'b1111);

    EX_MEM ex_mem_reg(
        .clk(clk),
        .reset(reset),
        .alu_result_in(alu_result),
        .write_data_in(ex_forward_b),
        .write_reg_in(ex_write_reg),
        .MemtoReg_in(id_ex_MemtoReg),
        .RegWrite_in(ex_valid_RegWrite),
        .MemRead_in(id_ex_MemRead),
        .MemWrite_in(id_ex_MemWrite),
        .alu_result_out(ex_mem_alu_result),
        .write_data_out(ex_mem_write_data),
        .write_reg_out(ex_mem_write_reg),
        .MemtoReg_out(ex_mem_MemtoReg),
        .RegWrite_out(ex_mem_RegWrite),
        .MemRead_out(ex_mem_MemRead),
        .MemWrite_out(ex_mem_MemWrite)
    );

    // =========================
    // MEM: Memory
    // =========================
    DataMemory dm(
        .clk(clk),
        .MemRead(ex_mem_MemRead),
        .MemWrite(ex_mem_MemWrite),
        .address(ex_mem_alu_result),
        .write_data(ex_mem_write_data),
        .read_data(mem_read_data)
    );

    MEM_WB mem_wb_reg(
        .clk(clk),
        .reset(reset),
        .read_data_in(mem_read_data),
        .alu_result_in(ex_mem_alu_result),
        .write_reg_in(ex_mem_write_reg),
        .RegWrite_in(ex_mem_RegWrite),
        .MemtoReg_in(ex_mem_MemtoReg),
        .read_data_out(mem_wb_read_data),
        .alu_result_out(mem_wb_alu_result),
        .write_reg_out(mem_wb_write_reg),
        .RegWrite_out(mem_wb_RegWrite),
        .MemtoReg_out(mem_wb_MemtoReg)
    );

    // =========================
    // WB: Write Back
    // =========================
    Mux2 #(32) mux_mem_to_reg(
        .d0(mem_wb_alu_result),
        .d1(mem_wb_read_data),
        .sel(mem_wb_MemtoReg),
        .out(write_data_rf)
    );

    assign RegWrite = mem_wb_RegWrite;
endmodule
