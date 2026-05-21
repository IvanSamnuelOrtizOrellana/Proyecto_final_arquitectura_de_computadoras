// Registro de pipeline entre IF e ID.
module IF_ID(
    input clk,
    input reset,
    input enable,
    input flush,
    input [31:0] pc_plus_4_in,
    input [31:0] instruction_in,
    output reg [31:0] pc_plus_4_out,
    output reg [31:0] instruction_out
);
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            pc_plus_4_out <= 32'd0;
            instruction_out <= 32'd0;
        end else if (flush) begin
            pc_plus_4_out <= 32'd0;
            instruction_out <= 32'd0;
        end else if (enable) begin
            pc_plus_4_out <= pc_plus_4_in;
            instruction_out <= instruction_in;
        end
    end
endmodule
