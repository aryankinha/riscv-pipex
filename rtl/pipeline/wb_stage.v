`timescale 1ns/1ps
module wb_stage(input valid, reg_write, mem_read, input [31:0] result, load_data,
 output we, output [31:0] data);
assign we=valid && reg_write;
assign data=mem_read ? load_data : result;
endmodule
