vlib plxsim

vlib work

do update_comp.do

vsim -t 1ps -lib work vereskm_main_tb
#vsim +notimingchecks -L unisim -L work -L secureip work.vereskm_main_tb

do {vereskm_main_tb_wave.do}
view wave
view structure
view signals
run 1us
