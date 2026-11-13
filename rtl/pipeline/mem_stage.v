`timescale 1ns/1ps
module mem_stage(input clk, reset, valid, mem_read, mem_write,
 input [31:0] address, store_data, output [31:0] load_data);
data_mem dmem(clk,reset,valid && mem_read,valid && mem_write,address,store_data,load_data);
endmodule
