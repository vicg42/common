#-----------------------------------------------------------------------
# author : Viktor Golovachenko
#-----------------------------------------------------------------------
file delete -force -- work

vlib work
vlog ./bmp_io.sv -sv
vlog ../src/linear_table.v
vlog ../src/scaler_linear_h.v
vlog ../src/scaler_linear_v.v -sv +define+SIM_FSM

vlog  ./monitor.sv -sv
vlog  ./scaler_bilinear_v_tb.sv -sv

vsim -t 1ps -novopt -lib work scaler_bilinear_v_tb \

#do scaler_bilinear_v_tb_wave.do

#--------------------------
#View waveform
#--------------------------
view wave
config wave -timelineunits us
view structure
view signals
run 3us

#quit -force
