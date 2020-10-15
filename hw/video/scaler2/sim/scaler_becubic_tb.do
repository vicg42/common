#-----------------------------------------------------------------------
# author : Viktor Golovachenko
#-----------------------------------------------------------------------
file delete -force -- work

vlib work
vlog ./bmp_io.sv -sv
vlog ../src/cubic_table.v
vlog ../src/scaler_cubic_h.v
vlog ../src/scaler_cubic_v.v -sv +define+SIM_FSM
vlog ../src/scaler_bicubic.v

vlog  ./monitor.sv -sv
vlog  ./scaler_bicubic_tb.sv -sv

vsim -t 1ps -novopt -lib work scaler_bicubic_tb \

do scaler_bicubic_tb_wave.do

#--------------------------
#View waveform
#--------------------------
view wave
config wave -timelineunits us
view structure
view signals
run 3us

#quit -force
