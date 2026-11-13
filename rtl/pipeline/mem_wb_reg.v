`timescale 1ns/1ps
module mem_wb_reg(
 input clk, reset,
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
 input [31:0] result_in,
 output reg [31:0] result,
 input [31:0] load_data_in,
 output reg [31:0] load_data,
 input reg_write_in,
 output reg reg_write,
 input mem_read_in,
 output reg mem_read);
always @(posedge clk) begin
 if (reset) begin
  valid <= 0;
  pc <= 0;
  instr <= 32'h00000013;
  rs1 <= 0;
  rs2 <= 0;
  rd <= 0;
  result <= 0;
  load_data <= 0;
  reg_write <= 0;
  mem_read <= 0;
 end else begin
  valid <= valid_in;
  pc <= pc_in;
  instr <= instr_in;
  rs1 <= rs1_in;
  rs2 <= rs2_in;
  rd <= rd_in;
  result <= result_in;
  load_data <= load_data_in;
  reg_write <= reg_write_in;
  mem_read <= mem_read_in;
 end
end
endmodule
