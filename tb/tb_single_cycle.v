`timescale 1ns/1ps
module tb_single_cycle;
reg clk=0, reset=1;
wire [31:0] retire_pc, retire_instr;
wire retire_valid, retire_write;
wire [4:0] retire_rd;
wire [31:0] retire_data;
reg [31:0] expected [0:95];
integer cycles=0, retired=0, trace_file, i;
always #5 clk=~clk;
single_cycle_top #(`PROGRAM_FILE) dut(.clk(clk), .reset(reset), .pc(), .if_instr(),
 .retire_valid(retire_valid), .retire_pc(retire_pc), .retire_instr(retire_instr),
 .retire_write(retire_write), .retire_rd(retire_rd), .retire_data(retire_data));
initial begin
 trace_file=$fopen("build/single_cycle.csv","w");
 if (!trace_file) $fatal(1,"FAIL opening baseline trace");
 $fdisplay(trace_file,"cycle,wb_valid,wb_pc,wb_instr,wb_write,wb_rd,wb_data");
 $readmemh(`EXPECTED_FILE,expected);
 repeat (2) @(negedge clk);
 reset=0;
end
always @(posedge clk) begin
 if (!reset) begin
  cycles=cycles+1;
  $fdisplay(trace_file,"%0d,%0d,%08h,%08h,%0d,%0d,%08h",
   cycles,retire_valid,retire_pc,retire_instr,retire_write,retire_rd,retire_data);
  if (retire_valid) begin
   retired=retired+1;
   if (retire_pc==`LAST_PC) begin
    #1;
    for (i=0;i<32;i=i+1)
     if (dut.decode.rf.regs[i] !== expected[i])
      $fatal(1,"FAIL baseline x%0d: got %h expected %h",i,dut.decode.rf.regs[i],expected[i]);
    for (i=0;i<64;i=i+1)
     if (dut.memory.dmem.words[i] !== expected[32+i])
      $fatal(1,"FAIL baseline data word %0d",i);
    if (retired!=`EXPECTED_RETIRED || cycles!=retired)
     $fatal(1,"FAIL baseline cycle or retirement count");
    $fclose(trace_file);
    $display("PASS single-cycle cycles=%0d retired=%0d",cycles,retired);
    $finish;
   end
  end
  if (cycles>500) $fatal(1,"FAIL baseline timeout");
 end
end
endmodule
