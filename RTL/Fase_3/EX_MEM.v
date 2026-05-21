// Registro de pipeline entre EX y MEM.
module EX_MEM(
    input clk,
    input reset,

    input [31:0] alu_result_in,
    input [31:0] write_data_in,
    input [4:0] write_reg_in,

    input MemtoReg_in,
    input RegWrite_in,
    input MemRead_in,
    input MemWrite_in,

    output reg [31:0] alu_result_out,
    output reg [31:0] write_data_out,
    output reg [4:0] write_reg_out,

    output reg MemtoReg_out,
    output reg RegWrite_out,
    output reg MemRead_out,
    output reg MemWrite_out
);
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            alu_result_out <= 32'd0;
            write_data_out <= 32'd0;
            write_reg_out <= 5'd0;
            MemtoReg_out <= 1'b0;
            RegWrite_out <= 1'b0;
            MemRead_out <= 1'b0;
            MemWrite_out <= 1'b0;
        end else begin
            alu_result_out <= alu_result_in;
            write_data_out <= write_data_in;
            write_reg_out <= write_reg_in;
            MemtoReg_out <= MemtoReg_in;
            RegWrite_out <= RegWrite_in;
            MemRead_out <= MemRead_in;
            MemWrite_out <= MemWrite_in;
        end
    end
endmodule
