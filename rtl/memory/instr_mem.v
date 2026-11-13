`timescale 1ns/1ps
module instr_mem #(parameter HEX_FILE="programs/01_arithmetic.hex")
 (input [31:0] pc, output [31:0] instr);
reg [31:0] words [0:63];
initial $readmemh(HEX_FILE, words);
assign instr = pc < 256 && pc[1:0]==0 ? words[pc[7:2]] : 32'h00000013;
endmodule
