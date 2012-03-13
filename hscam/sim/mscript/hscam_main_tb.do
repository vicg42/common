quit -sim

## Execute script to generate 'today package'
#exec C:/Xilinx/ISE_DS/ISE/bin/nt64/xtclsh ../gen_today_pkg.tcl today_pkg_admxrc6t1_sim.vhd >today_pkg_admxrc6t1_sim.vhd

## Delete existing libraries
file delete -force -- work
vlib work

vlog     "c:/Xilinx/ISE_DS/ISE/verilog/src/glbl.v"

vcom -93 "../../../common/lib/hw/lib/vicg/vicg_common_pkg.vhd"
vcom -93 "../testbanch/prj_cfg_sim.vhd"

vcom -93 "../../ise/src/hdd/mem_glob_pkg.vhd"
vcom -93 "../../../common/lib/hw/mem/xilinx/mem_wr_s6_pkg.vhd"
vcom -93 "../../../common/lib/hw/mem/xilinx/mem_wr_s6.vhd"

vcom -93 "../../ise/src/core_gen/*.vhd"

vcom -93 "../../../common/lib/hw/sata/dsn_hdd_reg_def.vhd"
vcom -93 "../../../common/lib/hw/sata/src/sata_glob_pkg.vhd"
vcom -93 "../../../common/lib/hw/sata/src/sata_pkg.vhd"
vcom -93 "../../../common/lib/hw/sata/src/sata_raid_pkg.vhd"
vcom -93 "../../../common/lib/hw/sata/src/sata_sim_lite_pkg.vhd"
vcom -93 "../../../common/lib/hw/sata/src/sata_unit_pkg.vhd"
vcom -93 "../../../common/lib/hw/sata/src/sata_testgen_pkg.vhd"
vcom -93 "../../../common/lib/hw/sata/src/sata_testgen.vhd"
vcom -93 "../../../common/lib/hw/sata/src/sata_scrambler.vhd"
vcom -93 "../../../common/lib/hw/sata/src/sata_crc.vhd"
vcom -93 "../../../common/lib/hw/sata/src/sata_dcm_s6.vhd"
vcom -93 "../../../common/lib/hw/sata/src/sata_spd_ctrl_s6gtp.vhd"
#vcom -93 "../../../common/lib/hw/sata/src/sata_player_s6gt_clkmux.vhd"
vcom -93 "../../../common/lib/hw/sata/src/sata_player_s6gt_clkmux_hscam.vhd"
#vcom -93 "../../../common/lib/hw/sata/src/sata_player_s6gtx.vhd"
vcom -93 "../../../common/lib/hw/sata/src/sata_player_gtsim.vhd"
vcom -93 "../../../common/lib/hw/sata/src/sata_dbgcs.vhd"
vcom -93 "../../../common/lib/hw/sata/src/sata_player_oob.vhd"
vcom -93 "../../../common/lib/hw/sata/src/sata_player_rx.vhd"
vcom -93 "../../../common/lib/hw/sata/src/sata_player_tx.vhd"
vcom -93 "../../../common/lib/hw/sata/src/sata_player.vhd"
vcom -93 "../../../common/lib/hw/sata/src/sata_llayer.vhd"
vcom -93 "../../../common/lib/hw/sata/src/sata_tlayer.vhd"
vcom -93 "../../../common/lib/hw/sata/src/sata_alayer.vhd"
vcom -93 "../../../common/lib/hw/sata/src/sata_host.vhd"
vcom -93 "../../../common/lib/hw/sata/src/sata_connector.vhd"
vcom -93 "../../../common/lib/hw/sata/src/sata_raid_decoder_v2.vhd"
vcom -93 "../../../common/lib/hw/sata/src/sata_raid_ctrl_v2.vhd"
vcom -93 "../../../common/lib/hw/sata/src/sata_measure.vhd"
vcom -93 "../../../common/lib/hw/sata/src/sata_raid.vhd"
vcom -93 "../../../common/lib/hw/sata/src/dsn_raid_main.vhd"
vcom -93 "../../../common/lib/hw/sata/dsn_hdd_pkg.vhd"
vcom -93 "../../../common/lib/hw/sata/dsn_hdd.vhd"
#vcom -93 "../../../common/lib/hw/sata/dsn_hdd_rambuf.vhd"
vcom -93 "../../../common/lib/hw/sata/dsn_hdd_rambuf_v2.vhd"
vcom -93 "../../../common/lib/hw/sata/dsn_hdd_rambuf_v2_wr_s6.vhd"

vcom -93 "../../../common/lib/hw/sata/sim/testbanch/sata_sim_pkg.vhd"
vcom -93 "../../../common/lib/hw/sata/sim/testbanch/sata_bufdata.vhd"
vcom -93 "../../../common/lib/hw/sata/sim/testbanch/sata_dev_model.vhd"
#vcom -93 "../testbanch/hdd_main3_tb.vhd"


vcom -93 "../../../common/lib/hw/cfgdev_ctrl/cfgdev_pkg.vhd"
vcom -93 "../../../common/lib/hw/cfgdev_ctrl/cfgdev_ftdi.vhd"

# MIG Code
vcom "../../ise/src/core_gen/mem_ctrl_core/example_design/rtl/*.vhd"
vcom -93 "../../ise/src/hdd/memc5_infrastructure.vhd"
vcom -93 "../../ise/src/hdd/mem_ctrl_pkg.vhd"
vcom -93 "../../ise/src/hdd/mem_ctrl.vhd"

vcom -93 "../../ise/src/hdd/video_ctrl_pkg.vhd"
vcom -93 "../../ise/src/hdd/hdd_main_unit_pkg.vhd"

vcom -93 "../../ise/src/hdd/clock.vhd"

vcom -93 "../../ise/src/hdd/video_reader.vhd"
vcom -93 "../../ise/src/hdd/video_writer.vhd"
vcom -93 "../../ise/src/hdd/video_ctrl.vhd"

#vcom -93 "../../ise/src/hdd/vin_cam.vhd"
vcom -93 "../../ise/src/hdd/vin_hdd.vhd"
vcom -93 "../../ise/src/hdd/vout.vhd"
vcom -93 "../../ise/src/hdd/vtiming_gen.vhd"

vcom -93 "../../ise/src/hdd/hdd_main.vhd"
vcom -93 "../../ise/hscam_main.vhd"


# Testbench
vcom -93 "../testbanch/hscam_main_tb.vhd"

#Pass the parameters for memory model parameter file#
vlog  +incdir+. +define+x1Gb +define+sg25 +define+x16 ddr2_model_c5.v

##Load the design. Use required libraries.#
vsim -t ps -novopt +notimingchecks -L unisim -L secureip work.hscam_main_tb glbl

do hscam_main_wave.do
