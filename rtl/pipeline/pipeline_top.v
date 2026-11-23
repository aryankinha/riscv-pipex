`timescale 1ns/1ps
module pipeline_top #(parameter HEX_FILE="programs/01_arithmetic.hex")
 (input clk, reset, output [31:0] pc, if_instr,
 output retire_valid, output [31:0] retire_pc, retire_instr,
 output retire_write, output [4:0] retire_rd, output [31:0] retire_data);
wire taken, stall, wb_we, supported;
wire [31:0] target, wb_data;
wire id_valid;
wire [31:0] id_pc;
wire [31:0] id_instr;
wire ex_valid;
wire [31:0] ex_pc;
wire [31:0] ex_instr;
wire [4:0] ex_rs1;
wire [4:0] ex_rs2;
wire [4:0] ex_rd;
wire [31:0] ex_a;
wire [31:0] ex_b;
wire [31:0] ex_imm;
wire ex_reg_write;
wire ex_mem_read;
wire ex_mem_write;
wire ex_alu_imm;
wire ex_alu_sub;
wire ex_branch;
wire ex_branch_ne;
wire mem_valid;
wire [31:0] mem_pc;
wire [31:0] mem_instr;
wire [4:0] mem_rs1;
wire [4:0] mem_rs2;
wire [4:0] mem_rd;
wire [31:0] mem_result;
wire [31:0] mem_store_data;
wire mem_reg_write;
wire mem_mem_read;
wire mem_mem_write;
wire wb_valid;
wire [31:0] wb_pc;
wire [31:0] wb_instr;
wire [4:0] wb_rs1;
wire [4:0] wb_rs2;
wire [4:0] wb_rd;
wire [31:0] wb_result;
wire [31:0] wb_load_data;
wire wb_reg_write;
wire wb_mem_read;
wire [4:0] dec_rs1;
wire [4:0] dec_rs2;
wire [4:0] dec_rd;
wire [31:0] dec_a;
wire [31:0] dec_b;
wire [31:0] dec_imm;
wire dec_reg_write;
wire dec_mem_read;
wire dec_mem_write;
wire dec_alu_imm;
wire dec_alu_sub;
wire dec_branch;
wire dec_branch_ne;
wire [31:0] ex_result, ex_store_data, mem_load_data;
wire decode_reads_rs2 = !dec_alu_imm || dec_mem_write;
// An EX load makes its data available for forwarding from WB one cycle later.
assign stall = id_valid && supported && ex_valid && ex_mem_read && ex_rd != 0 &&
               (ex_rd == dec_rs1 || (decode_reads_rs2 && ex_rd == dec_rs2));
if_stage #(HEX_FILE) fetch(clk,reset,taken,stall,target,pc,if_instr);
if_id_reg id_pipe(.clk(clk),
 .reset(reset),
 .flush(taken),
 .hold(stall),
 .valid_in(1'b1),
 .valid(id_valid),
 .pc_in(pc),
 .pc(id_pc),
 .instr_in(if_instr),
 .instr(id_instr));
id_stage decode(clk,reset,wb_we,wb_rd,wb_data,id_instr,dec_rs1,dec_rs2,dec_rd,dec_a,dec_b,dec_imm,dec_reg_write,dec_mem_read,dec_mem_write,dec_alu_imm,dec_alu_sub,dec_branch,dec_branch_ne,supported);
id_ex_reg ex_pipe(.clk(clk),
 .reset(reset),
 .flush(taken || stall),
 .valid_in(id_valid && supported),
 .valid(ex_valid),
 .pc_in(id_pc),
 .pc(ex_pc),
 .instr_in(id_instr),
 .instr(ex_instr),
 .rs1_in(dec_rs1),
 .rs1(ex_rs1),
 .rs2_in(dec_rs2),
 .rs2(ex_rs2),
 .rd_in(dec_rd),
 .rd(ex_rd),
 .a_in(dec_a),
 .a(ex_a),
 .b_in(dec_b),
 .b(ex_b),
 .imm_in(dec_imm),
 .imm(ex_imm),
 .reg_write_in(dec_reg_write),
 .reg_write(ex_reg_write),
 .mem_read_in(dec_mem_read),
 .mem_read(ex_mem_read),
 .mem_write_in(dec_mem_write),
 .mem_write(ex_mem_write),
 .alu_imm_in(dec_alu_imm),
 .alu_imm(ex_alu_imm),
 .alu_sub_in(dec_alu_sub),
 .alu_sub(ex_alu_sub),
 .branch_in(dec_branch),
 .branch(ex_branch),
 .branch_ne_in(dec_branch_ne),
 .branch_ne(ex_branch_ne));
wire [31:0] forwarded_a, forwarded_b;
forwarding bypass(ex_rs1, ex_rs2, mem_valid && mem_reg_write, mem_mem_read,
                  mem_rd, mem_result, wb_we, wb_rd, wb_data, ex_a, ex_b,
                  forwarded_a, forwarded_b);
ex_stage execute(ex_valid,ex_alu_imm,ex_alu_sub,ex_branch,ex_branch_ne,ex_pc,
                 forwarded_a,forwarded_b,ex_imm,ex_result,ex_store_data,target,taken);
ex_mem_reg mem_pipe(.clk(clk),
 .reset(reset),
 .valid_in(ex_valid),
 .valid(mem_valid),
 .pc_in(ex_pc),
 .pc(mem_pc),
 .instr_in(ex_instr),
 .instr(mem_instr),
 .rs1_in(ex_rs1),
 .rs1(mem_rs1),
 .rs2_in(ex_rs2),
 .rs2(mem_rs2),
 .rd_in(ex_rd),
 .rd(mem_rd),
 .result_in(ex_result),
 .result(mem_result),
 .store_data_in(ex_store_data),
 .store_data(mem_store_data),
 .reg_write_in(ex_reg_write),
 .reg_write(mem_reg_write),
 .mem_read_in(ex_mem_read),
 .mem_read(mem_mem_read),
 .mem_write_in(ex_mem_write),
 .mem_write(mem_mem_write));
mem_stage memory(clk,reset,mem_valid,mem_mem_read,mem_mem_write,mem_result,mem_store_data,mem_load_data);
mem_wb_reg wb_pipe(.clk(clk),
 .reset(reset),
 .valid_in(mem_valid),
 .valid(wb_valid),
 .pc_in(mem_pc),
 .pc(wb_pc),
 .instr_in(mem_instr),
 .instr(wb_instr),
 .rs1_in(mem_rs1),
 .rs1(wb_rs1),
 .rs2_in(mem_rs2),
 .rs2(wb_rs2),
 .rd_in(mem_rd),
 .rd(wb_rd),
 .result_in(mem_result),
 .result(wb_result),
 .load_data_in(mem_load_data),
 .load_data(wb_load_data),
 .reg_write_in(mem_reg_write),
 .reg_write(wb_reg_write),
 .mem_read_in(mem_mem_read),
 .mem_read(wb_mem_read));
wb_stage writeback(wb_valid,wb_reg_write,wb_mem_read,wb_result,wb_load_data,wb_we,wb_data);
assign retire_valid=wb_valid;
assign retire_pc=wb_pc;
assign retire_instr=wb_instr;
assign retire_write = wb_we && wb_rd != 0;
assign retire_rd = retire_write ? wb_rd : 5'b0;
assign retire_data = retire_write ? wb_data : 32'b0;
endmodule
