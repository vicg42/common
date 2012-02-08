source "../../common/script/projnav.tcl"
#file mkdir "../ise/prj
cd ../ise/prj

set _cwd [pwd]
puts "Currunt PATH ${_cwd}"

set _usrdef_design "hscam"
set _usrdef_entity "hscam_main"
set _usrdef_xilinx_family "spartan6"
set _usrdef_chip_family "s6lxt"
set _usrdef_device "6slx100t"
set _usrdef_speed  2
set _usrdef_pkg    "fgg676"
set _usrdef_ucf_filename "hscam"
set _usrdef_ucf_filepath "..\ucf\hscam.ucf"

set _VMod $::projNav::VMod
set _VHDMod $::projNav::VHDMod
set _VHDPkg $::projNav::VHDPkg

set _projects [ list \
  [ list \
    $_usrdef_xilinx_family $_usrdef_device $_usrdef_pkg $_usrdef_speed xrc5t1 [ list \
      [ list "../../../common/lib/hw/lib/vicg/vicg_common_pkg.vhd" $_VHDPkg ] \
      [ list "../../../common/lib/hw/lib/vicg/v5/mclk_gtp_wrap.vhd" $_VHDMod ] \
      [ list "../../../common/lib/hw/timer/time_gen.vhd" $_VHDMod ] \
      [ list "../../../common/lib/hw/testing/fpga_test_01.vhd" $_VHDMod ] \
      [ list "../../../common/lib/hw/mem/mem_glob_pkg.vhd" $_VHDPkg ] \
      [ list "../../../common/lib/hw/mem/xilinx/mem_wr_s6_pkg.vhd" $_VHDPkg ] \
      [ list "../../../common/lib/hw/mem/xilinx/mem_wr_s6.vhd" $_VHDMod ] \
      [ list "../../../common/lib/hw/xapp/xapp691/src/vhdl/fifo_utils.vhd" $_VHDPkg ] \
      [ list "../../../common/lib/hw/xapp/xapp691/src/vhdl/BRAM/BRAM_S8_S72.vhd" $_VHDMod ] \
      [ list "../../../common/lib/hw/xapp/xapp691/src/vhdl/BRAM/BRAM_S72_S72.vhd" $_VHDMod ] \
      [ list "../../../common/lib/hw/xapp/xapp691/src/vhdl/BRAM/BRAM_S36_S72.vhd" $_VHDMod ] \
      [ list "../../../common/lib/hw/xapp/xapp691/src/vhdl/BRAM/BRAM_S18_S72.vhd" $_VHDMod ] \
      [ list "../../../common/lib/hw/xapp/xapp691/src/vhdl/DRAM/RAM_64nX1.vhd" $_VHDMod ] \
      [ list "../../../common/lib/hw/xapp/xapp691/src/vhdl/DRAM/DRAM_fifo_pkg.vhd" $_VHDPkg ] \
      [ list "../../../common/lib/hw/xapp/xapp691/src/vhdl/BRAM/BRAM_S8_S144.vhd" $_VHDMod ] \
      [ list "../../../common/lib/hw/xapp/xapp691/src/vhdl/BRAM/BRAM_S72_S144.vhd" $_VHDMod ] \
      [ list "../../../common/lib/hw/xapp/xapp691/src/vhdl/BRAM/BRAM_S36_S144.vhd" $_VHDMod ] \
      [ list "../../../common/lib/hw/xapp/xapp691/src/vhdl/BRAM/BRAM_S16_S144.vhd" $_VHDMod ] \
      [ list "../../../common/lib/hw/xapp/xapp691/src/vhdl/BRAM/BRAM_S144_S144.vhd" $_VHDMod ] \
      [ list "../../../common/lib/hw/xapp/xapp691/src/vhdl/BRAM/BRAM_fifo_pkg.vhd" $_VHDPkg ] \
      [ list "../../../common/lib/hw/xapp/xapp691/src/vhdl/DRAM/DRAM_macro.vhd" $_VHDMod ] \
      [ list "../../../common/lib/hw/xapp/xapp691/src/vhdl/BRAM/BRAM_macro.vhd" $_VHDMod ] \
      [ list "../../../common/lib/hw/xapp/xapp691/src/vhdl/DRAM/DRAM_fifo.vhd" $_VHDMod ] \
      [ list "../../../common/lib/hw/xapp/xapp691/src/vhdl/BRAM/BRAM_fifo.vhd" $_VHDMod ] \
      [ list "../../../common/lib/hw/xapp/xapp691/src/vhdl/ll_fifo_pkg.vhd" $_VHDPkg ] \
      [ list "../../../common/lib/hw/xapp/xapp691/src/vhdl/ll_fifo_DRAM.vhd" $_VHDMod ] \
      [ list "../../../common/lib/hw/xapp/xapp691/src/vhdl/ll_fifo_BRAM.vhd" $_VHDMod ] \
      [ list "../../../common/lib/hw/xapp/xapp691/src/vhdl/ll_fifo.vhd" $_VHDMod ] \
      [ list "../../../common/lib/hw/cfgdev_ctrl/cfgdev_pkg.vhd" $_VHDPkg ] \
      [ list "../../../common/lib/hw/cfgdev_ctrl/cfgdev_ftdi.vhd" $_VHDMod ] \
      [ list "../src/core_gen/hdd_ram_hfifo.vhd" $_VHDMod ] \
      [ list "../src/core_gen/sata_rxfifo.vhd" $_VHDMod ] \
      [ list "../src/core_gen/sata_txfifo.vhd" $_VHDMod ] \
      [ list "../src/core_gen/hdd_rxfifo.vhd" $_VHDMod ] \
      [ list "../src/core_gen/hdd_txfifo.vhd" $_VHDMod ] \
      [ list "../src/core_gen/hdd_cmdfifo.vhd" $_VHDMod ] \
      [ list "../../../common/lib/hw/sata/src/sata_glob_pkg.vhd" $_VHDPkg ] \
      [ list "../../../common/lib/hw/sata/src/sata_pkg.vhd" $_VHDPkg ] \
      [ list "../../../common/lib/hw/sata/src/sata_testgen_pkg.vhd" $_VHDPkg ] \
      [ list "../../../common/lib/hw/sata/src/sata_raid_pkg.vhd" $_VHDPkg ] \
      [ list "../../../common/lib/hw/sata/src/sata_sim_lite_pkg.vhd" $_VHDPkg ] \
      [ list "../../../common/lib/hw/sata/src/sata_unit_pkg.vhd" $_VHDPkg ] \
      [ list "../../../common/lib/hw/sata/src/sata_scrambler.vhd" $_VHDMod ] \
      [ list "../../../common/lib/hw/sata/src/sata_crc.vhd" $_VHDMod ] \
      [ list "../../../common/lib/hw/sata/src/sata_dcm_s6.vhd" $_VHDMod ] \
      [ list "../../../common/lib/hw/sata/src/sata_spd_ctrl_s6gtp.vhd" $_VHDMod ] \
      [ list "../../../common/lib/hw/sata/src/sata_player_s6gtx.vhd" $_VHDMod ] \
      [ list "../../../common/lib/hw/sata/src/sata_player_gtsim.vhd" $_VHDMod ] \
      [ list "../../../common/lib/hw/sata/src/sata_player_oob.vhd" $_VHDMod ] \
      [ list "../../../common/lib/hw/sata/src/sata_player_tx.vhd" $_VHDMod ] \
      [ list "../../../common/lib/hw/sata/src/sata_player_rx.vhd" $_VHDMod ] \
      [ list "../../../common/lib/hw/sata/src/sata_player.vhd" $_VHDMod ] \
      [ list "../../../common/lib/hw/sata/src/sata_llayer.vhd" $_VHDMod ] \
      [ list "../../../common/lib/hw/sata/src/sata_tlayer.vhd" $_VHDMod ] \
      [ list "../../../common/lib/hw/sata/src/sata_alayer.vhd" $_VHDMod ] \
      [ list "../../../common/lib/hw/sata/src/sata_dbgcs.vhd" $_VHDMod ] \
      [ list "../../../common/lib/hw/sata/src/sata_host.vhd" $_VHDMod ] \
      [ list "../../../common/lib/hw/sata/src/sata_connector.vhd" $_VHDMod ] \
      [ list "../src/hdd/sata_raid_decoder.vhd" $_VHDMod ] \
      [ list "../src/hdd/sata_raid_ctrl.vhd" $_VHDMod ] \
      [ list "../../../common/lib/hw/sata/src/sata_raid.vhd" $_VHDMod ] \
      [ list "../../../common/lib/hw/sata/src/sata_measure.vhd" $_VHDMod ] \
      [ list "../../../common/lib/hw/sata/src/sata_testgen.vhd" $_VHDMod ] \
      [ list "../../../common/lib/hw/sata/src/dsn_raid_main.vhd" $_VHDMod ] \
      [ list "../../../common/lib/hw/sata/dsn_hdd_pkg.vhd" $_VHDPkg ] \
      [ list "../src/hdd/dsn_hdd.vhd" $_VHDMod ] \
      [ list "../src/hdd/sata_player_s6gt_clkmux.vhd" $_VHDMod ] \
      [ list "../../../common/lib/hw/sata/dsn_hdd_rambuf.vhd"  $_VHDMod ] \
      [ list "../../../common/lib/hw/sata/dsn_hdd_reg_def.vhd" $_VHDPkg ] \
      [ list "../src/core_gen/mem_ctrl_core/user_design/rtl/iodrp_controller.vhd" $_VHDMod ] \
      [ list "../src/core_gen/mem_ctrl_core/user_design/rtl/iodrp_mcb_controller.vhd" $_VHDMod ] \
      [ list "../src/core_gen/mem_ctrl_core/user_design/rtl/mcb_raw_wrapper.vhd" $_VHDMod ] \
      [ list "../src/core_gen/mem_ctrl_core/user_design/rtl/mcb_soft_calibration.vhd" $_VHDMod ] \
      [ list "../src/core_gen/mem_ctrl_core/user_design/rtl/mcb_soft_calibration_top.vhd" $_VHDMod ] \
      [ list "../src/core_gen/mem_ctrl_core/user_design/rtl/memc5_wrapper.vhd" $_VHDMod ] \
      [ list "../src/core_gen/vin_bufcam.vhd" $_VHDMod ] \
      [ list "../src/core_gen/vin_bufhdd.vhd" $_VHDMod ] \
      [ list "../src/core_gen/vin_bufout" $_VHDMod ] \
      [ list "../src/core_gen/vout_buf.vhd" $_VHDMod ] \
      [ list "../src/core_gen/dbgcs_iconx1.vhd" $_VHDMod ] \
      [ list "../src/core_gen/dbgcs_iconx2.vhd" $_VHDMod ] \
      [ list "../src/core_gen/dbgcs_iconx3.vhd" $_VHDMod ] \
      [ list "../src/core_gen/dbgcs_sata_layer.vhd" $_VHDMod ] \
      [ list "../src/core_gen/dbgcs_sata_rambuf.vhd" $_VHDMod ] \
      [ list "../src/core_gen/dbgcs_sata_raid.vhd" $_VHDMod ] \
      [ list "../src/core_gen/dbgcs_sata_rbuf.vhd" $_VHDMod ] \
      [ list "../src/hdd/vtiming_gen.vhd" $_VHDMod ] \
      [ list "../src/hdd/memc5_infrastructure.vhd" $_VHDMod ] \
      [ list "../src/hdd/mem_ctrl_pkg.vhd" $_VHDPkg ] \
      [ list "../src/hdd/mem_ctrl.vhd" $_VHDMod ] \
      [ list "../src/hdd/video_ctrl_pkg.vhd" $_VHDPkg ] \
      [ list "../src/hdd/video_reader.vhd" $_VHDMod ] \
      [ list "../src/hdd/video_writer.vhd" $_VHDMod ] \
      [ list "../src/hdd/video_ctrl.vhd" $_VHDMod ] \
      [ list "../src/hdd/vin_cam.vhd" $_VHDMod ] \
      [ list "../src/hdd/vin_hdd.vhd" $_VHDMod ] \
      [ list "../src/hdd/vout.vhd" $_VHDMod ] \
      [ list "../src/hdd/clock.vhd" $_VHDMod ] \
      [ list "../src/hdd/hdd_main_unit_pkg.vhd" $_VHDPkg ] \
      [ list "../src/hdd/hdd_main_cfg.vhd" $_VHDPkg ] \
      [ list "../src/hdd/hdd_main.vhd" $_VHDMod ] \
      [ list "../hscam_main.vhd" $_VHDMod ] \
      [ list "../../ucf/hscam.ucf" "hscam_main" ] \
    ] \
  ] \
]

::projNav::makeProjects $_cwd $_usrdef_design $_usrdef_entity $_projects 10

#cd ../src
#exec "updata_ngc.bat"
