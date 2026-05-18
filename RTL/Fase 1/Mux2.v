// Multiplexor 2 a 1 parametrizable
module Mux2 #(parameter WIDTH = 32)(
    input [WIDTH-1:0] d0,
    input [WIDTH-1:0] d1,
    input sel,
    output [WIDTH-1:0] out
);
    assign out = sel ? d1 : d0;
endmodule
