#-----------------------------------------------------------------------
# author : Viktor Golovachenko
#-----------------------------------------------------------------------
file delete -force -- work

vlib work
vlog ./bmp_io.sv -sv
vlog ../src/bilinear_table.v
vlog ../src/scaler_linear_h.v

vlog  ./monitor.sv -sv
vlog  ./scaler_linear_h_tb.sv -sv

vsim -t 1ps -novopt -lib work scaler_linear_h_tb \

do scaler_linear_h_tb_wave.do

#--------------------------
#View waveform
#--------------------------
view wave
config wave -timelineunits us
view structure
view signals
run 3us

#quit -force
