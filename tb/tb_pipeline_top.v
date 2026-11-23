`timescale 1ns/1ps
`ifndef PROGRAM_FILE
`define PROGRAM_FILE "programs/01_arithmetic.hex"
`define EXPECTED_FILE "programs/01_arithmetic.expected"
`define LAST_PC 32
`define EXPECTED_RETIRED 9
`endif
module tb_pipeline_top;
`ifndef EXPECTED_STALLS
`define EXPECTED_STALLS -1
`endif
reg clk=0,reset=1;
wire [31:0] pc,if_instr,retire_pc,retire_instr;
wire retire_valid, retire_write;
wire [4:0] retire_rd;
wire [31:0] retire_data;
reg [31:0] expected [0:95];
integer cycles=0,retired=0,i,taken_branches=0;
integer trace_file, stalls=0;
reg [31:0] checked_target, held_pc, held_id_pc, held_instr;
reg overlap=0;
always #5 clk=~clk;
pipeline_top #(`PROGRAM_FILE) dut(.clk(clk), .reset(reset), .pc(pc),
 .if_instr(if_instr), .retire_valid(retire_valid), .retire_pc(retire_pc),
 .retire_instr(retire_instr), .retire_write(retire_write), .retire_rd(retire_rd),
 .retire_data(retire_data));
initial begin
 trace_file=$fopen("build/pipeline.csv","w");
 if(!trace_file) $fatal(1,"FAIL opening trace file");
 $fdisplay(trace_file,"cycle,if_pc,id_valid,id_pc,ex_valid,ex_pc,mem_valid,mem_pc,wb_valid,wb_pc,wb_instr,wb_write,wb_rd,wb_data,taken,stall");
 $readmemh(`EXPECTED_FILE,expected);
 $dumpfile("build/pipeline.vcd");$dumpvars(0,tb_pipeline_top);
 repeat(2) @(negedge clk);
 reset=0;
end
always @(posedge clk) begin
 if(!reset) begin
  cycles=cycles+1;
  $fdisplay(trace_file,"%0d,%08h,%0d,%08h,%0d,%08h,%0d,%08h,%0d,%08h,%08h,%0d,%0d,%08h,%0d,%0d",
   cycles,pc,dut.id_valid,dut.id_pc,dut.ex_valid,dut.ex_pc,
   dut.mem_valid,dut.mem_pc,dut.wb_valid,retire_pc,retire_instr,
   retire_write,retire_rd,retire_data,dut.taken,dut.stall);
  if(dut.id_valid && dut.ex_valid && dut.mem_valid && dut.wb_valid &&
    pc!=dut.id_pc && dut.id_pc!=dut.ex_pc && dut.ex_pc!=dut.mem_pc && dut.mem_pc!=dut.wb_pc &&
    pc!=dut.ex_pc && pc!=dut.mem_pc && pc!=dut.wb_pc &&
    dut.id_pc!=dut.mem_pc && dut.id_pc!=dut.wb_pc && dut.ex_pc!=dut.wb_pc)
   begin
    if(!overlap) $display("PASS overlap IF=%h ID=%h EX=%h MEM=%h WB=%h",pc,dut.id_pc,dut.ex_pc,dut.mem_pc,dut.wb_pc);
    overlap=1;
   end
  if(retire_valid) begin
   retired=retired+1;
   if(retire_pc==`LAST_PC) begin
    #1;
    for(i=0;i<32;i=i+1)
     if(dut.decode.rf.regs[i] !== expected[i]) begin
      $display("FAIL register x%0d got=%h expected=%h",i,dut.decode.rf.regs[i],expected[i]);$fatal(1);
     end
    for(i=0;i<64;i=i+1)
     if(dut.memory.dmem.words[i] !== expected[i+32]) begin
      $display("FAIL memory word %0d",i);$fatal(1);
     end
    if(!overlap || retired!=`EXPECTED_RETIRED) $fatal(1,"FAIL overlap or retirement count");
    if(cycles!=retired+4+2*taken_branches+stalls) $fatal(1,"FAIL cycle accounting");
    if (`EXPECTED_STALLS >= 0 && stalls != `EXPECTED_STALLS)
     $fatal(1,"FAIL stalls: got %0d expected %0d",stalls,`EXPECTED_STALLS);
    $fclose(trace_file);
    $display("PASS pipeline %s cycles=%0d retired=%0d overlap=1 taken=%0d stalls=%0d",`PROGRAM_FILE,cycles,retired,taken_branches,stalls);
    $finish;
   end
  end
  if(cycles>500) $fatal(1,"FAIL timeout");
 end
end
always @(posedge clk) begin
 if(!reset && dut.taken) begin
  taken_branches=taken_branches+1;
  checked_target=dut.target;
  #1;
  if(dut.id_valid || dut.ex_valid || pc !== checked_target)
   $fatal(1,"FAIL branch flush or target");
 end
end
always @(posedge clk) begin
 if (!reset && dut.stall) begin
  stalls=stalls+1;
  held_pc=pc;
  held_id_pc=dut.id_pc;
  held_instr=dut.id_instr;
  #1;
  if (pc !== held_pc || !dut.id_valid || dut.id_pc !== held_id_pc ||
      dut.id_instr !== held_instr || dut.ex_valid)
   $fatal(1,"FAIL load-use hold or bubble");
 end
end
endmodule
