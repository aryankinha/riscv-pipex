`timescale 1ns/1ps
module tb_control;
reg [31:0] instr;
wire rw,mr,mw,use_imm,asub,br,bne,ok;
wire [31:0] imm;
integer cases=0;
control_unit dut(instr,rw,mr,mw,use_imm,asub,br,bne,ok);
imm_gen ig(instr,imm);
task check;
 input [31:0] ins;
 input [7:0] want;
 begin instr=ins;#1;
 if({rw,mr,mw,use_imm,asub,br,bne,ok} !== want) begin
 $display("FAIL control %h",ins);$fatal(1);end
 cases=cases+1;
 end
endtask
initial begin
 check(32'h002081b3,8'b10000001);
 check(32'h402081b3,8'b10001001);
 check(32'hfff00093,8'b10010001);
 if(imm !== 32'hffffffff) $fatal(1,"FAIL I immediate");
 check(32'h00002083,8'b11010001);
 check(32'hfe102e23,8'b00110001);
 if(imm !== 32'hfffffffc) $fatal(1,"FAIL S immediate");
 check(32'hfe000ee3,8'b00000101);
 if(imm !== 32'hfffffffc) $fatal(1,"FAIL B immediate");
 check(32'h00001063,8'b00000111);
 check(32'h00000013,8'b10010001);
 check(32'h00000000,0);check(32'h0020f1b3,0);
 check(32'h022081b3,0);check(32'h00001083,0);
 check(32'h00001023,0);check(32'h00004063,0);
 $display("PASS control cases=%0d",cases);$finish;
end
endmodule
