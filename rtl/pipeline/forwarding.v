`timescale 1ns/1ps
module forwarding(input [4:0] rs1, rs2,
 input mem_write, mem_load, input [4:0] mem_rd, input [31:0] mem_data,
 input wb_write, input [4:0] wb_rd, input [31:0] wb_data,
 input [31:0] a, b, output [31:0] forwarded_a, forwarded_b);
wire mem_a = mem_write && mem_rd != 0 && mem_rd == rs1;
wire mem_b = mem_write && mem_rd != 0 && mem_rd == rs2;
wire wb_a = wb_write && wb_rd != 0 && wb_rd == rs1;
wire wb_b = wb_write && wb_rd != 0 && wb_rd == rs2;
// A matching load is younger than WB, but its address is not its result.
assign forwarded_a = mem_a ? (mem_load ? a : mem_data) : (wb_a ? wb_data : a);
assign forwarded_b = mem_b ? (mem_load ? b : mem_data) : (wb_b ? wb_data : b);
endmodule
