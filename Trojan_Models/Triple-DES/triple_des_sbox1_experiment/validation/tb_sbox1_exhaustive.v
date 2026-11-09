`timescale 1ns/1ps
module tb_sbox1_exhaustive;
    reg  [1:6] addr;
    wire [1:4] golden_dout;
    wire [1:4] mutant_dout;
    integer i;
    integer diff_count;

    sbox1_golden_ref u_golden (.addr(addr), .dout(golden_dout));
    sbox1_mutant_ref u_mutant (.addr(addr), .dout(mutant_dout));

    initial begin
        diff_count = 0;
        for (i = 0; i < 64; i = i + 1) begin
            addr = i;
            #1;
            if (i == 0) begin
                if (golden_dout !== 4'd14 || mutant_dout !== 4'd15) begin
                    $display("FAIL: addr=0 golden=%h mutant=%h", golden_dout, mutant_dout);
                    $fatal(1);
                end
            end else if (golden_dout !== mutant_dout) begin
                $display("FAIL: unexpected difference at addr=%0d golden=%h mutant=%h",
                         i, golden_dout, mutant_dout);
                $fatal(1);
            end
            if (golden_dout !== mutant_dout)
                diff_count = diff_count + 1;
        end

        if (diff_count != 1) begin
            $display("FAIL: expected exactly one changed S-box entry, got %0d", diff_count);
            $fatal(1);
        end
        $display("PASS: all 64 S-box inputs checked; only addr=000000 changed (E -> F).");
        $finish;
    end
endmodule
