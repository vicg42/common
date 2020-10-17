#-----------------------------------------------------------------------
# author : Viktor Golovachenko
#-----------------------------------------------------------------------
file delete -force -- work

vlib work
vlog ./bmp_io.sv -sv
vlog ../src/cubic_table.v
vlog ../src/scaler_cubic_h_n.v
vlog ../src/scaler_cubic_v_n.v -sv +define+SIM_FSM
vlog ../src/scaler_bicubic_n.v

vlog  ./monitor.sv -sv
vlog  ./scaler_bicubic_n_tb.sv -sv

vsim -t 1ps -novopt -lib work scaler_bicubic_n_tb \

do scaler_bicubic_n_tb_wave.do

#--------------------------
#View waveform
#--------------------------
view wave
config wave -timelineunits us
view structure
view signals
run 3us

#quit -force
