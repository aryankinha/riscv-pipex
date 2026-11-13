`timescale 1ns/1ps
module ex_stage(input valid, alu_imm, alu_sub, branch, branch_ne,
 input [31:0] pc, a, b, imm, output [31:0] result, store_data, target,
 output taken);
// Later forwarding paths can feed this operand selection.
wire [31:0] ex_operand_a = a;
wire [31:0] ex_operand_b = alu_imm ? imm : b;
alu arithmetic(ex_operand_a,ex_operand_b,alu_sub,result);
assign store_data=b;
assign target=pc+imm;
assign taken=valid && branch && ((a==b) != branch_ne);
endmodule
