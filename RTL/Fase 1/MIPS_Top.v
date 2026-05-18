// Datapath Principal e Interconexión General
module MIPS_Top(
    input clk,
    input reset
);
    // Cables de interconexión
    wire [31:0] pc, next_pc, instruction;
    wire [31:0] read_data1, read_data2, alu_result, mem_read_data, write_data_rf, sign_ext_imm, alu_b_in;
    wire [4:0] write_reg;
    wire [3:0] alu_control;
    wire zero;
    
    // Cables de control
    wire RegDst, ALUSrc, MemtoReg, RegWrite, MemRead, MemWrite;
    wire [1:0] ALUOp;

    // Instancias de módulos
    PC pc_reg(.clk(clk), .reset(reset), .next_pc(next_pc), .pc(pc));
    Adder adder_pc(.a(pc), .b(32'd4), .result(next_pc));
    InstructionMemory im(.address(pc), .instruction(instruction));

    Control ctrl(
        .opcode(instruction[31:26]),
        .RegDst(RegDst),
        .ALUSrc(ALUSrc),
        .MemtoReg(MemtoReg),
        .RegWrite(RegWrite),
        .MemRead(MemRead),
        .MemWrite(MemWrite),
        .ALUOp(ALUOp)
    );

    Mux2 #(5) mux_reg_dst(
        .d0(instruction[20:16]), 
        .d1(instruction[15:11]), 
        .sel(RegDst), 
        .out(write_reg)
    );

    RegisterFile rf(
        .clk(clk),
        .RegWrite(RegWrite),
        .rs(instruction[25:21]),
        .rt(instruction[20:16]),
        .rd(write_reg),
        .write_data(write_data_rf),
        .read_data1(read_data1),
        .read_data2(read_data2)
    );

    SignExtend sign_ext(.in(instruction[15:0]), .out(sign_ext_imm));

    Mux2 #(32) mux_alu_src(
        .d0(read_data2), 
        .d1(sign_ext_imm), 
        .sel(ALUSrc), 
        .out(alu_b_in)
    );

    ALUControl alu_ctrl(.funct(instruction[5:0]), .ALUOp(ALUOp), .alu_control(alu_control));
    
    ALU alu(
        .a(read_data1),
        .b(alu_b_in),
        .shamt(instruction[10:6]),
        .alu_control(alu_control),
        .result(alu_result),
        .zero(zero)
    );

    DataMemory dm(
        .clk(clk),
        .MemRead(MemRead),
        .MemWrite(MemWrite),
        .address(alu_result),
        .write_data(read_data2),
        .read_data(mem_read_data)
    );

    Mux2 #(32) mux_mem_to_reg(
        .d0(alu_result), 
        .d1(mem_read_data), 
        .sel(MemtoReg), 
        .out(write_data_rf)
    );

endmodule
