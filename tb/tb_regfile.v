`timescale 1ns/1ps
module tb_regfile;
reg clk=0,reset=1,we=0;
reg [4:0] rs1=0,rs2=0,rd=0;
reg [31:0] wd=0;
wire [31:0] a,b;
integer cases=0,i;
always #5 clk=~clk;
regfile dut(clk,reset,we,rs1,rs2,rd,wd,a,b);
task check;
 input [31:0] wa,wb;
 begin #1;
 if(a !== wa || b !== wb) begin $display("FAIL register file");$fatal(1);end
 cases=cases+1;
 end
endtask
initial begin
 @(negedge clk);reset=0;
 for(i=0;i<32;i=i+1) begin rs1=i[4:0];rs2=i[4:0];check(0,0);end
 rd=3;wd=32'h89abcdef;we=1;rs1=3;rs2=3;check(32'h89abcdef,32'h89abcdef);
 @(negedge clk);we=0;check(32'h89abcdef,32'h89abcdef);
 rd=0;wd=99;we=1;rs1=0;rs2=0;check(0,0);
 @(negedge clk);we=0;check(0,0);
 reset=1;@(negedge clk);reset=0;rs1=3;check(0,0);
 $display("PASS register file cases=%0d",cases);$finish;
end
endmodule
