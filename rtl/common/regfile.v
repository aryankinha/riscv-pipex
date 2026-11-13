`timescale 1ns/1ps
module regfile(input clk, reset, we, input [4:0] rs1, rs2, rd,
 input [31:0] wd, output [31:0] a, b);
reg [31:0] regs [0:31];
integer i;
always @(posedge clk) begin
 if (reset) begin
  for (i=0;i<32;i=i+1) regs[i] <= 0;
 end else if (we && rd != 0) regs[rd] <= wd;
end
// ID can read the WB value at the same edge.
assign a = rs1 == 0 ? 32'b0 : (we && rd == rs1 ? wd : regs[rs1]);
assign b = rs2 == 0 ? 32'b0 : (we && rd == rs2 ? wd : regs[rs2]);
endmodule
