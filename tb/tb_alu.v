`timescale 1ns/1ps
module tb_alu;
reg [31:0] a,b;
reg sub;
wire [31:0] result;
integer cases;
alu dut(a,b,sub,result);
task check;
 input [31:0] x,y,want;
 input op;
 begin a=x;b=y;sub=op;#1;
  if (result !== want) begin $display("FAIL ALU"); $fatal(1); end
  cases=cases+1;
 end
endtask
initial begin
 cases=0;
 check(17,5,22,0); check(17,5,12,1); check(5,17,32'hfffffff4,1);
 check(32'hffffffff,1,0,0); check(32'h80000000,1,32'h7fffffff,1);
 check(0,0,0,0); check(0,0,0,1); check(32'h7fffffff,1,32'h80000000,0);
 $display("PASS ALU cases=%0d",cases); $finish;
end
endmodule
