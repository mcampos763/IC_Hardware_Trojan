@echo off
setlocal
if not exist build mkdir build
iverilog -g2005 -s tb_sbox1_exhaustive -o build\tb_sbox1_exhaustive.vvp validation\tb_sbox1_exhaustive.v validation\sbox1_golden_ref.v validation\sbox1_mutant_ref.v
if errorlevel 1 exit /b 1
vvp build\tb_sbox1_exhaustive.vvp
if errorlevel 1 exit /b 1
iverilog -g2005 -s tb_crp_integration -o build\tb_crp_integration.vvp validation\tb_crp_integration.v -f filelists\crp_validation_sources.f
if errorlevel 1 exit /b 1
vvp build\tb_crp_integration.vvp
if errorlevel 1 exit /b 1
python validation\check_sbox1_mapping.py
if errorlevel 1 exit /b 1
python validation\check_rtl_structure.py
if errorlevel 1 exit /b 1
echo All available validation steps passed.
