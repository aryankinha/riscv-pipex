`timescale 1ns/1ps
module imm_gen(input [31:0] instr, output reg [31:0] imm);
always @* begin
 case (instr[6:0])
  7'h23: imm = {{20{instr[31]}},instr[31:25],instr[11:7]};
  7'h63: imm = {{19{instr[31]}},instr[31],instr[7],instr[30:25],instr[11:8],1'b0};
  default: imm = {{20{instr[31]}},instr[31:20]};
 endcase
end
endmodule
