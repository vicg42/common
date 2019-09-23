#-----------------------------------------------------------------------
# Engineer    : Golovachenko Victor
#
# Create Date : 10.12.2018 16:28:55
#
#------------------------------------------------------------------------
file delete -force -- work

vlib work
vlog  ./bmp_io.sv -sv
vlog  ./bmp_io_tb.sv -sv +incdir+./

vsim  -t 1ps -novopt +notimingchecks -lib work bmp_io_tb


#--------------------------
#View waveform
#--------------------------
view wave
config wave -timelineunits us
view structure
view signals
run 1us
