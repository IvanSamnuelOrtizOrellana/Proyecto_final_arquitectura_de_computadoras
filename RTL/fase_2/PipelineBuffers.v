// =============================================================
// Buffers de Pipeline - Fase 2
// IF/ID  |  ID/EX  |  EX/MEM  |  MEM/WB
// Todos síncronos al mismo CLK. Reset activo-alto lleva todo a 0.
// =============================================================

// -------------------------------------------------------------
// Buffer IF/ID
// Captura al final de la etapa IF: PC+4 e Instrucción
// -------------------------------------------------------------
module IF_ID_Buffer(
    input        clk,
    input        reset,
    input [31:0] pc_plus4_in,
    input [31:0] instruction_in,
    output reg [31:0] pc_plus4_out,
    output reg [31:0] instruction_out
);
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            pc_plus4_out    <= 32'd0;
            instruction_out <= 32'd0;
        end else begin
            pc_plus4_out    <= pc_plus4_in;
            instruction_out <= instruction_in;
        end
    end
endmodule

// -------------------------------------------------------------
// Buffer ID/EX
// Captura al final de la etapa ID: señales de control + datos
// -------------------------------------------------------------
module ID_EX_Buffer(
    input        clk,
    input        reset,
    // --- Entradas de control ---
    input        RegDst_in,
    input        ALUSrc_in,
    input        MemtoReg_in,
    input        RegWrite_in,
    input        MemRead_in,
    input        MemWrite_in,
    input        Branch_in,
    input [2:0]  ALUOp_in,
    // --- Entradas de datos ---
    input [31:0] pc_plus4_in,
    input [31:0] read_data1_in,
    input [31:0] read_data2_in,
    input [31:0] sign_ext_imm_in,
    input [4:0]  rs_in,
    input [4:0]  rt_in,
    input [4:0]  rd_in,
    input [4:0]  shamt_in,
    input [5:0]  funct_in,
    // --- Salidas de control ---
    output reg        RegDst_out,
    output reg        ALUSrc_out,
    output reg        MemtoReg_out,
    output reg        RegWrite_out,
    output reg        MemRead_out,
    output reg        MemWrite_out,
    output reg        Branch_out,
    output reg [2:0]  ALUOp_out,
    // --- Salidas de datos ---
    output reg [31:0] pc_plus4_out,
    output reg [31:0] read_data1_out,
    output reg [31:0] read_data2_out,
    output reg [31:0] sign_ext_imm_out,
    output reg [4:0]  rs_out,
    output reg [4:0]  rt_out,
    output reg [4:0]  rd_out,
    output reg [4:0]  shamt_out,
    output reg [5:0]  funct_out
);
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            RegDst_out       <= 1'b0; ALUSrc_out      <= 1'b0;
            MemtoReg_out     <= 1'b0; RegWrite_out    <= 1'b0;
            MemRead_out      <= 1'b0; MemWrite_out    <= 1'b0;
            Branch_out       <= 1'b0; ALUOp_out       <= 3'b000;
            pc_plus4_out     <= 32'd0; read_data1_out <= 32'd0;
            read_data2_out   <= 32'd0; sign_ext_imm_out <= 32'd0;
            rs_out  <= 5'd0; rt_out  <= 5'd0; rd_out  <= 5'd0;
            shamt_out <= 5'd0; funct_out <= 6'd0;
        end else begin
            RegDst_out       <= RegDst_in;    ALUSrc_out      <= ALUSrc_in;
            MemtoReg_out     <= MemtoReg_in;  RegWrite_out    <= RegWrite_in;
            MemRead_out      <= MemRead_in;   MemWrite_out    <= MemWrite_in;
            Branch_out       <= Branch_in;    ALUOp_out       <= ALUOp_in;
            pc_plus4_out     <= pc_plus4_in;  read_data1_out  <= read_data1_in;
            read_data2_out   <= read_data2_in; sign_ext_imm_out <= sign_ext_imm_in;
            rs_out  <= rs_in;  rt_out  <= rt_in;  rd_out  <= rd_in;
            shamt_out <= shamt_in; funct_out <= funct_in;
        end
    end
endmodule

// -------------------------------------------------------------
// Buffer EX/MEM
// Captura al final de la etapa EX: resultado ALU, control mem
// -------------------------------------------------------------
module EX_MEM_Buffer(
    input        clk,
    input        reset,
    // --- Entradas de control ---
    input        MemtoReg_in,
    input        RegWrite_in,
    input        MemRead_in,
    input        MemWrite_in,
    input        Branch_in,
    // --- Entradas de datos ---
    input [31:0] branch_target_in,
    input        zero_in,
    input [31:0] alu_result_in,
    input [31:0] read_data2_in,
    input [4:0]  write_reg_in,
    // --- Salidas de control ---
    output reg        MemtoReg_out,
    output reg        RegWrite_out,
    output reg        MemRead_out,
    output reg        MemWrite_out,
    output reg        Branch_out,
    // --- Salidas de datos ---
    output reg [31:0] branch_target_out,
    output reg        zero_out,
    output reg [31:0] alu_result_out,
    output reg [31:0] read_data2_out,
    output reg [4:0]  write_reg_out
);
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            MemtoReg_out     <= 1'b0; RegWrite_out    <= 1'b0;
            MemRead_out      <= 1'b0; MemWrite_out    <= 1'b0;
            Branch_out       <= 1'b0;
            branch_target_out <= 32'd0; zero_out     <= 1'b0;
            alu_result_out   <= 32'd0; read_data2_out <= 32'd0;
            write_reg_out    <= 5'd0;
        end else begin
            MemtoReg_out     <= MemtoReg_in;   RegWrite_out    <= RegWrite_in;
            MemRead_out      <= MemRead_in;    MemWrite_out    <= MemWrite_in;
            Branch_out       <= Branch_in;
            branch_target_out <= branch_target_in; zero_out   <= zero_in;
            alu_result_out   <= alu_result_in; read_data2_out  <= read_data2_in;
            write_reg_out    <= write_reg_in;
        end
    end
endmodule

// -------------------------------------------------------------
// Buffer MEM/WB
// Captura al final de la etapa MEM: dato de memoria y resultado ALU
// -------------------------------------------------------------
module MEM_WB_Buffer(
    input        clk,
    input        reset,
    // --- Entradas de control ---
    input        MemtoReg_in,
    input        RegWrite_in,
    // --- Entradas de datos ---
    input [31:0] mem_read_data_in,
    input [31:0] alu_result_in,
    input [4:0]  write_reg_in,
    // --- Salidas de control ---
    output reg        MemtoReg_out,
    output reg        RegWrite_out,
    // --- Salidas de datos ---
    output reg [31:0] mem_read_data_out,
    output reg [31:0] alu_result_out,
    output reg [4:0]  write_reg_out
);
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            MemtoReg_out      <= 1'b0; RegWrite_out      <= 1'b0;
            mem_read_data_out <= 32'd0; alu_result_out   <= 32'd0;
            write_reg_out     <= 5'd0;
        end else begin
            MemtoReg_out      <= MemtoReg_in;   RegWrite_out      <= RegWrite_in;
            mem_read_data_out <= mem_read_data_in; alu_result_out <= alu_result_in;
            write_reg_out     <= write_reg_in;
        end
    end
endmodule
