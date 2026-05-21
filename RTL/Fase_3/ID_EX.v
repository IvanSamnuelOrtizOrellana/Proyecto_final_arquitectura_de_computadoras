// Registro de pipeline entre ID y EX.
module ID_EX(
    input clk,
    input reset,
    input flush,

    input [31:0] pc_plus_4_in,
    input [31:0] read_data1_in,
    input [31:0] read_data2_in,
    input [31:0] sign_ext_imm_in,
    input [4:0] rs_in,
    input [4:0] rt_in,
    input [4:0] rd_in,
    input [4:0] shamt_in,
    input [5:0] funct_in,

    input RegDst_in,
    input ALUSrc_in,
    input MemtoReg_in,
    input RegWrite_in,
    input MemRead_in,
    input MemWrite_in,
    input Branch_in,
    input [1:0] ALUOp_in,

    output reg [31:0] pc_plus_4_out,
    output reg [31:0] read_data1_out,
    output reg [31:0] read_data2_out,
    output reg [31:0] sign_ext_imm_out,
    output reg [4:0] rs_out,
    output reg [4:0] rt_out,
    output reg [4:0] rd_out,
    output reg [4:0] shamt_out,
    output reg [5:0] funct_out,

    output reg RegDst_out,
    output reg ALUSrc_out,
    output reg MemtoReg_out,
    output reg RegWrite_out,
    output reg MemRead_out,
    output reg MemWrite_out,
    output reg Branch_out,
    output reg [1:0] ALUOp_out
);
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            pc_plus_4_out <= 32'd0;
            read_data1_out <= 32'd0;
            read_data2_out <= 32'd0;
            sign_ext_imm_out <= 32'd0;
            rs_out <= 5'd0;
            rt_out <= 5'd0;
            rd_out <= 5'd0;
            shamt_out <= 5'd0;
            funct_out <= 6'd0;
            RegDst_out <= 1'b0;
            ALUSrc_out <= 1'b0;
            MemtoReg_out <= 1'b0;
            RegWrite_out <= 1'b0;
            MemRead_out <= 1'b0;
            MemWrite_out <= 1'b0;
            Branch_out <= 1'b0;
            ALUOp_out <= 2'b00;
        end else if (flush) begin
            pc_plus_4_out <= 32'd0;
            read_data1_out <= 32'd0;
            read_data2_out <= 32'd0;
            sign_ext_imm_out <= 32'd0;
            rs_out <= 5'd0;
            rt_out <= 5'd0;
            rd_out <= 5'd0;
            shamt_out <= 5'd0;
            funct_out <= 6'd0;
            RegDst_out <= 1'b0;
            ALUSrc_out <= 1'b0;
            MemtoReg_out <= 1'b0;
            RegWrite_out <= 1'b0;
            MemRead_out <= 1'b0;
            MemWrite_out <= 1'b0;
            Branch_out <= 1'b0;
            ALUOp_out <= 2'b00;
        end else begin
            pc_plus_4_out <= pc_plus_4_in;
            read_data1_out <= read_data1_in;
            read_data2_out <= read_data2_in;
            sign_ext_imm_out <= sign_ext_imm_in;
            rs_out <= rs_in;
            rt_out <= rt_in;
            rd_out <= rd_in;
            shamt_out <= shamt_in;
            funct_out <= funct_in;
            RegDst_out <= RegDst_in;
            ALUSrc_out <= ALUSrc_in;
            MemtoReg_out <= MemtoReg_in;
            RegWrite_out <= RegWrite_in;
            MemRead_out <= MemRead_in;
            MemWrite_out <= MemWrite_in;
            Branch_out <= Branch_in;
            ALUOp_out <= ALUOp_in;
        end
    end
endmodule
