`timescale 1ns/1ps
module single_cycle_top #(parameter HEX_FILE="programs/01_arithmetic.hex")
 (input clk, reset, output [31:0] pc, if_instr,
 output retire_valid, output [31:0] retire_pc, retire_instr,
 output retire_write, output [4:0] retire_rd, output [31:0] retire_data);
wire reg_write, mem_read, mem_write, alu_imm, alu_sub, branch, branch_ne;
wire supported, taken, we;
wire [4:0] rd;
wire [31:0] a, b, imm, result, store_data, target, load_data, write_data;

// The current instruction reads the old register state and writes at the edge.
if_stage #(HEX_FILE) fetch(clk,reset,taken,1'b0,target,pc,if_instr);
id_stage #(1'b0) decode(.clk(clk), .reset(reset), .wb_we(we), .wb_rd(rd),
 .wb_data(write_data), .instr(if_instr), .rs1(), .rs2(), .rd(rd), .a(a),
 .b(b), .imm(imm), .reg_write(reg_write), .mem_read(mem_read),
 .mem_write(mem_write), .alu_imm(alu_imm), .alu_sub(alu_sub),
 .branch(branch), .branch_ne(branch_ne), .supported(supported));
ex_stage execute(retire_valid,alu_imm,alu_sub,branch,branch_ne,pc,a,b,imm,
                 result,store_data,target,taken);
mem_stage memory(clk,reset,retire_valid,mem_read,mem_write,result,store_data,load_data);
wb_stage writeback(retire_valid,reg_write,mem_read,result,load_data,we,write_data);
assign retire_valid = supported && !reset;
assign retire_pc = pc;
assign retire_instr = if_instr;
assign retire_write = we && rd != 0;
assign retire_rd = retire_write ? rd : 5'b0;
assign retire_data = retire_write ? write_data : 32'b0;
endmodule
