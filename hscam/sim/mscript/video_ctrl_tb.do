#quit -sim

## Execute script to generate 'today package'
#exec C:/Xilinx/ISE_DS/ISE/bin/nt64/xtclsh ../gen_today_pkg.tcl today_pkg_admxrc6t1_sim.vhd >today_pkg_admxrc6t1_sim.vhd

# Delete existing libraries
file delete -force -- work
vlib work

vlog     "c:/Xilinx/ISE_DS/ISE/verilog/src/glbl.v"
vcom -93 "../testbanch/prj_cfg_sim.vhd"
vcom -93 "../../../common/lib/hw/lib/vicg/vicg_common_pkg.vhd"

## MIG Code
vcom "../../ise/src/core_gen/mem_ctrl_core/example_design/rtl/*.vhd"

vcom -93 "../../../common/lib/hw/mem/mem_glob_pkg.vhd"
vcom -93 "../../../common/lib/hw/mem/xilinx/mem_wr_s6_pkg.vhd"
vcom -93 "../../../common/lib/hw/mem/xilinx/mem_wr_s6.vhd"

#vcom -93 "../../ise/src/hdd/video_ctrl_pkg.vhd"
vcom -93 "../testbanch/video_ctrl_pkg_sim.vhd"
vcom -93 "../../ise/src/hdd/video_reader.vhd"
vcom -93 "../../ise/src/hdd/video_writer.vhd"
vcom -93 "../../ise/src/hdd/video_ctrl.vhd"

vcom -93 "../../ise/src/hdd/mem_ctrl_pkg.vhd"
vcom -93 "../../ise/src/hdd/mem_ctrl.vhd"

vcom -93 "../../ise/src/core_gen/vin_bufcam.vhd"

# Testbench
vcom -93 "../testbanch/video_ctrl_tb.vhd"

#Pass the parameters for memory model parameter file#
vlog  +incdir+. +define+x1Gb +define+sg25 +define+x16 ddr2_model_c5.v

##Load the design. Use required libraries.#
vsim -t ps -novopt +notimingchecks -L unisim -L secureip work.video_ctrl_tb glbl

do video_ctrl_wave.do
