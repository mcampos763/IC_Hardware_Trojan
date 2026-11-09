`timescale 1ns/1ps
module tb_crp_integration;
    reg  [1:32] R;
    reg  [1:48] K_sub;
    wire [1:32] P_golden;
    wire [1:32] P_mutant;

    crp_golden_ref u_golden (.P(P_golden), .R(R), .K_sub(K_sub));
    crp_mutant_ref u_mutant (.P(P_mutant), .R(R), .K_sub(K_sub));

    initial begin
        // With R=0 and K_sub=0, E(R)^K_sub gives S1 address 000000.
        R = 32'b0;
        K_sub = 48'b0;
        #1;
        if ((P_golden ^ P_mutant) !== 32'h00000002) begin
            $display("FAIL: expected only P[31] (packed bit 1) to toggle; diff=%h",
                     (P_golden ^ P_mutant));
            $fatal(1);
        end

        // Change one S1 address bit: the trigger must no longer be active.
        K_sub[6] = 1'b1;
        #1;
        if (P_golden !== P_mutant) begin
            $display("FAIL: unexpected CRP difference with non-trigger S1 address; diff=%h",
                     (P_golden ^ P_mutant));
            $fatal(1);
        end

        $display("PASS: CRP integration propagates only the selected S1 output-bit change.");
        $finish;
    end
endmodule
