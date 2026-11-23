`timescale 1ns/1ps
module id_stage #(parameter WRITE_THROUGH = 1'b1)(input clk, reset, wb_we, input [4:0] wb_rd,
 input [31:0] wb_data, instr, output [4:0] rs1, rs2, rd,
 output [31:0] a, b, imm,
 output reg_write, mem_read, mem_write, alu_imm, alu_sub, branch, branch_ne, supported);
assign rs1=instr[19:15];
assign rs2=instr[24:20];
assign rd=instr[11:7];
regfile #(WRITE_THROUGH) rf(clk,reset,wb_we,rs1,rs2,wb_rd,wb_data,a,b);
imm_gen ig(instr,imm);
control_unit control(instr,reg_write,mem_read,mem_write,alu_imm,alu_sub,branch,branch_ne,supported);
endmodule
