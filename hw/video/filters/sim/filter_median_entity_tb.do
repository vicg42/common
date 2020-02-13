#-----------------------------------------------------------------------
#
# author    : Golovachenko Victor
#
#------------------------------------------------------------------------
file delete -force -- work

vlib work

vlog  ../filter_median_5x5_entity.v
vlog  ../filter_median_7x7_entity.v
vlog  ./filter_median_entity_tb.sv -sv

vsim  -t 1ps -novopt +notimingchecks -lib work filter_median_entity_tb

do filter_median_entity_tb_wave.do

view wave
config wave -timelineunits us
view structure
view signals
run 5us

