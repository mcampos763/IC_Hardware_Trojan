`timescale 1ns/1ps
module tb_gf_mul;
  reg clk=0, start=0;
  reg [7:0] in_1=0, in_2=0;
  wire [7:0] gold_out, mut_out;
  wire gold_done, mut_done;
  integer a,b, cases=0, mismatches=0;
  always #5 clk=~clk;
  gf_mul G (.clk(clk),.start(start),.in_1(in_1),.in_2(in_2),.out(gold_out),.done(gold_done));
  gf_mul_mutant M (.clk(clk),.start(start),.in_1(in_1),.in_2(in_2),.out(mut_out),.done(mut_done));

  // Independent GF(2^8) Horner oracle using reduction polynomial x^8+x^4+x^3+x^2+1.
  function automatic [7:0] gf_ref(input [7:0] x, input [7:0] y);
    reg [7:0] acc;
    integer k;
    begin
      acc=8'h00;
      for(k=7;k>=0;k=k-1) begin
        acc={acc[6:0],1'b0} ^ (acc[7] ? 8'h1D : 8'h00);
        if(y[k]) acc=acc ^ x;
      end
      gf_ref=acc;
    end
  endfunction

  initial begin
    repeat(3) @(negedge clk);
    for(a=0;a<256;a=a+1) begin
      for(b=0;b<256;b=b+1) begin
        @(negedge clk);
        in_1=a[7:0]; in_2=b[7:0]; start=1;
        @(negedge clk);
        start=0;
        @(negedge clk);
        #1;
        cases=cases+1;
        if (gold_done !== 1'b1 || mut_done !== 1'b1)
          $fatal(1,"done incorrect a=%02x b=%02x",a,b);
        if (gold_out !== gf_ref(a[7:0],b[7:0]))
          $fatal(1,"golden oracle failed a=%02x b=%02x expected=%02x got=%02x",a,b,gf_ref(a[7:0],b[7:0]),gold_out);
        if (gold_out !== mut_out) begin
          mismatches=mismatches+1;
          if(a != 165 || b != 90 || mut_out !== (gold_out ^ 8'h01))
            $fatal(1,"unexpected mutation a=%02x b=%02x gold=%02x mutant=%02x",a,b,gold_out,mut_out);
        end
      end
    end
    if(cases != 65536 || mismatches != 1) $fatal(1,"unexpected counts cases=%0d mismatch=%0d",cases,mismatches);
    $display("PASS RTL GF_MUL: %0d input pairs; 1 targeted mismatch; golden matches GF oracle",cases);
    $finish;
  end
endmodule
