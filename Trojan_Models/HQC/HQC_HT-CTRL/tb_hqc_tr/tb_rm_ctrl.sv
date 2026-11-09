`timescale 1ns/1ps
module tb_rm_ctrl;
  reg clk=0, rst_ni=0,start_i=0,peak_valid_i=0,eas_start_ready_i=0,eas_din_ready_i=0;
  reg [7:0] peak_dout_i=0;
  reg [127:0] ram_din_i=0;
  wire gold_busy,gold_done, gold_wr;
  wire mut_busy,mut_done,mut_wr;
  wire [7:0] gold_data,mut_data;
  wire [5:0] gold_addr,mut_addr;
  integer idx, misses, done_pulses;
  always #5 clk=~clk;
  hqc_rmdecod_ctrl G (
    .clk_i(clk),.rst_ni(rst_ni),.start_i(start_i),.busy_o(gold_busy),.done_o(gold_done),
    .ram_din_i(ram_din_i),.ram_din_rd_o(),.ram_din_addr_o(),
    .eas_din_o(),.eas_start_ready_i(eas_start_ready_i),.eas_start_o(),
    .eas_din_valid_o(),.eas_din_ready_i(eas_din_ready_i),
    .peak_valid_i(peak_valid_i),.peak_dout_i(peak_dout_i),
    .ram_dout_wr_o(gold_wr),.ram_dout_o(gold_data),.ram_dout_addr_o(gold_addr));
  hqc_rmdecod_ctrl_mutant M (
    .clk_i(clk),.rst_ni(rst_ni),.start_i(start_i),.busy_o(mut_busy),.done_o(mut_done),
    .ram_din_i(ram_din_i),.ram_din_rd_o(),.ram_din_addr_o(),
    .eas_din_o(),.eas_start_ready_i(eas_start_ready_i),.eas_start_o(),
    .eas_din_valid_o(),.eas_din_ready_i(eas_din_ready_i),
    .peak_valid_i(peak_valid_i),.peak_dout_i(peak_dout_i),
    .ram_dout_wr_o(mut_wr),.ram_dout_o(mut_data),.ram_dout_addr_o(mut_addr));

  task automatic run_case(input [7:0] last_byte, input integer expected_misses);
    begin
      rst_ni=0;start_i=0;peak_valid_i=0;peak_dout_i=0; misses=0;done_pulses=0;
      repeat(3) @(negedge clk);
      rst_ni=1;start_i=1;
      @(negedge clk); start_i=0;
      for(idx=0;idx<46;idx=idx+1) begin
        @(negedge clk);
        peak_valid_i=1;
        peak_dout_i=(idx==45)?last_byte:idx[7:0];
        #1;
        if (gold_wr !== 1'b1 || gold_addr !== idx[5:0] || gold_data !== peak_dout_i)
          $fatal(1,"gold write invalid i=%0d",idx);
        if(mut_addr !== gold_addr || mut_data !== gold_data)
          $fatal(1,"mut address/data changed i=%0d",idx);
        if(mut_wr !== gold_wr) begin
          misses=misses+1;
          if(idx!=45 || last_byte!=8'hA5 || mut_wr!==1'b0)
            $fatal(1,"unplanned write deviation i=%0d",idx);
        end
        @(negedge clk);
        peak_valid_i=0;
        #1;
        if(idx==45) begin
          if(gold_done !== 1'b1 || mut_done !== 1'b1)
            $fatal(1,"last done should be raised in both designs");
          done_pulses=done_pulses+1;
        end
      end
      if(misses != expected_misses || done_pulses != 1)
        $fatal(1,"unexpected summary last=%02x misses=%0d done=%0d",last_byte,misses,done_pulses);
      $display("PASS RTL RM_CTRL: final_byte=%02x misses=%0d done_pulses=%0d",last_byte,misses,done_pulses);
      @(negedge clk);
    end
  endtask
  initial begin
    run_case(8'hA5,1);
    run_case(8'h5A,0);
    $finish;
  end
endmodule
