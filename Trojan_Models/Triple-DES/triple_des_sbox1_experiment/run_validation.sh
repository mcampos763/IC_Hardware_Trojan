#!/usr/bin/env sh
set -eu
mkdir -p build
iverilog -g2005 -s tb_sbox1_exhaustive -o build/tb_sbox1_exhaustive.vvp \
  validation/tb_sbox1_exhaustive.v validation/sbox1_golden_ref.v validation/sbox1_mutant_ref.v
vvp build/tb_sbox1_exhaustive.vvp
iverilog -g2005 -s tb_crp_integration -o build/tb_crp_integration.vvp \
  validation/tb_crp_integration.v \
  validation/sbox1_golden_ref.v validation/sbox1_mutant_ref.v \
  validation/crp_golden_ref.v validation/crp_mutant_ref.v \
  golden_model/rtl_triple-des/common/sbox2.v \
  golden_model/rtl_triple-des/common/sbox3.v \
  golden_model/rtl_triple-des/common/sbox4.v \
  golden_model/rtl_triple-des/common/sbox5.v \
  golden_model/rtl_triple-des/common/sbox6.v \
  golden_model/rtl_triple-des/common/sbox7.v \
  golden_model/rtl_triple-des/common/sbox8.v
vvp build/tb_crp_integration.vvp
python3 validation/check_sbox1_mapping.py
python3 validation/check_rtl_structure.py
