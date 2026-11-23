`timescale 1ns/1ps
module if_stage #(parameter HEX_FILE="programs/01_arithmetic.hex")
 (input clk, reset, taken, stall, input [31:0] target, output reg [31:0] pc,
 output [31:0] instr);
always @(posedge clk) begin
 if (reset) pc <= 0;
 else if (taken) pc <= target;
 else if (!stall) pc <= pc + 4;
end
instr_mem #(HEX_FILE) imem(pc,instr);
endmodule
