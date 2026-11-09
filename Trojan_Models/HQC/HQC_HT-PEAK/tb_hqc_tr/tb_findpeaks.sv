`timescale 1ns/1ps
module tb_findpeaks;
  reg clk=0,rst_ni=0,start_i=0,din_valid_i=0;
  reg [9:0] din0_i=0,din1_i=0;
  wire [7:0] gold_out,mut_out;
  wire gold_valid,mut_valid;
  integer i;
  always #5 clk=~clk;
  hqc_rmdecod_findpeaks G(
     .clk_i(clk),.rst_ni(rst_ni),.start_i(start_i),
     .din0_i(din0_i),.din1_i(din1_i),.din_valid_i(din_valid_i),
     .dout_o(gold_out),.dout_valid_o(gold_valid));
  hqc_rmdecod_findpeaks_mutant M(
     .clk_i(clk),.rst_ni(rst_ni),.start_i(start_i),
     .din0_i(din0_i),.din1_i(din1_i),.din_valid_i(din_valid_i),
     .dout_o(mut_out),.dout_valid_o(mut_valid));

  task automatic run_case(input integer tie_case);
    begin
      rst_ni=0;start_i=0;din_valid_i=0;din0_i=0;din1_i=0;
      repeat(3) @(negedge clk);
      rst_ni=1;start_i=1;
      @(negedge clk);
      start_i=0;
      for(i=0;i<64;i=i+1) begin
        din_valid_i=1;
        din0_i=(i==10)? (tie_case?10'd7:10'd9) : 10'd0;
        din1_i=(i==10)?10'd7:10'd0;
        @(negedge clk);
      end
      din_valid_i=0;din0_i=0;din1_i=0;
      @(negedge clk);
      #1;
      if (gold_valid !== 1'b1 || mut_valid !== 1'b1)
        $fatal(1,"peak valid missing tie=%0d",tie_case);
      if (tie_case) begin
        if(gold_out !== 8'h95 || mut_out !== 8'h94)
          $fatal(1,"tie discrepancy wrong: gold=%02x mut=%02x",gold_out,mut_out);
      end else begin
        if(gold_out !== 8'h94 || mut_out !== 8'h94)
          $fatal(1,"nontie should agree: gold=%02x mut=%02x",gold_out,mut_out);
      end
      $display("PASS RTL FINDPEAKS: tie=%0d gold=%02x mutant=%02x",tie_case,gold_out,mut_out);
      @(negedge clk);
    end
  endtask
  initial begin
    run_case(1);
    run_case(0);
    $finish;
  end
endmodule
