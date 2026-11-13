`timescale 1ns/1ps
module data_mem(input clk, reset, read_en, write_en,
 input [31:0] address, wd, output [31:0] data);
reg [31:0] words [0:63];
integer i;
wire aligned = address < 256 && address[1:0]==0;
always @(posedge clk) begin
 if (reset) begin
  for (i=0;i<64;i=i+1) words[i] <= 0;
 end else if (write_en && aligned) words[address[7:2]] <= wd;
end
assign data = read_en && aligned ? words[address[7:2]] : 32'b0;
endmodule
