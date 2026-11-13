`timescale 1ns/1ps
module id_ex_reg(
 input clk, reset,
 input flush,
 input valid_in,
 output reg valid,
 input [31:0] pc_in,
 output reg [31:0] pc,
 input [31:0] instr_in,
 output reg [31:0] instr,
 input [4:0] rs1_in,
 output reg [4:0] rs1,
 input [4:0] rs2_in,
 output reg [4:0] rs2,
 input [4:0] rd_in,
 output reg [4:0] rd,
 input [31:0] a_in,
 output reg [31:0] a,
 input [31:0] b_in,
 output reg [31:0] b,
 input [31:0] imm_in,
 output reg [31:0] imm,
 input reg_write_in,
 output reg reg_write,
 input mem_read_in,
 output reg mem_read,
 input mem_write_in,
 output reg mem_write,
 input alu_imm_in,
 output reg alu_imm,
 input alu_sub_in,
 output reg alu_sub,
 input branch_in,
 output reg branch,
 input branch_ne_in,
 output reg branch_ne);
always @(posedge clk) begin
 if (reset || flush) begin
  valid <= 0;
  pc <= 0;
  instr <= 32'h00000013;
  rs1 <= 0;
  rs2 <= 0;
  rd <= 0;
  a <= 0;
  b <= 0;
  imm <= 0;
  reg_write <= 0;
  mem_read <= 0;
  mem_write <= 0;
  alu_imm <= 0;
  alu_sub <= 0;
  branch <= 0;
  branch_ne <= 0;
 end else begin
  valid <= valid_in;
  pc <= pc_in;
  instr <= instr_in;
  rs1 <= rs1_in;
  rs2 <= rs2_in;
  rd <= rd_in;
  a <= a_in;
  b <= b_in;
  imm <= imm_in;
  reg_write <= reg_write_in;
  mem_read <= mem_read_in;
  mem_write <= mem_write_in;
  alu_imm <= alu_imm_in;
  alu_sub <= alu_sub_in;
  branch <= branch_in;
  branch_ne <= branch_ne_in;
 end
end
endmodule
