## NOTE:  Do not edit this file.
## Autogenerated by ProjNav (creatfdo.tcl) on Mon Jan 26 12:17:18 ���������� ����� (����) 2009
##
vlib work

do update_comp.do

vsim -t 1ps   -lib work vereskm_hdd_tb
do vereskm_hdd_tb_wave.do
view wave
view structure
view signals
run 1000ns

