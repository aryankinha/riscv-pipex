`timescale 1ns/1ps
module control_unit(input [31:0] instr,
 output reg reg_write, mem_read, mem_write, alu_imm, alu_sub,
 output reg branch, branch_ne, supported);
always @* begin
 reg_write=0; mem_read=0; mem_write=0; alu_imm=0; alu_sub=0;
 branch=0; branch_ne=0; supported=0;
 case (instr[6:0])
  7'h33: if (instr[14:12]==0 && (instr[31:25]==0 || instr[31:25]==7'h20)) begin
   supported=1; reg_write=1; alu_sub=instr[30];
  end
  7'h13: if (instr[14:12]==0) begin
   supported=1; reg_write=1; alu_imm=1;
  end
  7'h03: if (instr[14:12]==2) begin
   supported=1; reg_write=1; mem_read=1; alu_imm=1;
  end
  7'h23: if (instr[14:12]==2) begin
   supported=1; mem_write=1; alu_imm=1;
  end
  7'h63: if (instr[14:12]==0 || instr[14:12]==1) begin
   supported=1; branch=1; branch_ne=instr[12];
  end
  default: begin end
 endcase
end
endmodule
