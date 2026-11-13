`timescale 1ns/1ps
module if_id_reg(
 input clk, reset,
 input flush,
 input valid_in,
 output reg valid,
 input [31:0] pc_in,
 output reg [31:0] pc,
 input [31:0] instr_in,
 output reg [31:0] instr);
always @(posedge clk) begin
 if (reset || flush) begin
  valid <= 0;
  pc <= 0;
  instr <= 32'h00000013;
 end else begin
  valid <= valid_in;
  pc <= pc_in;
  instr <= instr_in;
 end
end
endmodule
