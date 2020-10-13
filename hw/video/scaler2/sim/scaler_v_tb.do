#-----------------------------------------------------------------------
# Engineer    : Golovachenko Victor
#
# Create Date : 18.05.2018 18:16:14
#
#------------------------------------------------------------------------
file delete -force -- work

vlib work
vlog ./bmp_io.sv -sv
vlog ../src/cubic_table.v
#vlog ../src/bilinear_table.v
#vlog ../src/lanczos_table.v
vlog ../src/scaler_cubic_v.v -sv +define+SIM_FSM

vlog  ./scaler_v_tb.sv -sv

vsim -t 1ps -novopt -lib work scaler_v_tb \

do scaler_v_tb_wave.do

#--------------------------
#View waveform
#--------------------------
view wave
config wave -timelineunits us
view structure
view signals
run 3us

#quit -force
