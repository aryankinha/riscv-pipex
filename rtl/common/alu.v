`timescale 1ns/1ps
module alu(input [31:0] a, b, input sub, output [31:0] result);
assign result = sub ? a - b : a + b;
endmodule
