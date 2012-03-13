source "../../common/script/projnav.tcl"
#file mkdir "../ise/prj
cd ../ise/prj

set _cwd [pwd]
puts "Currunt PATH ${_cwd}"

set _usrdef_design "hdd_test"
set _usrdef_entity "hdd_test_main"
set _usrdef_xilinx_family "spartan6"
set _usrdef_chip_family "s6lxt"
set _usrdef_device "6slx100t"
set _usrdef_speed  2
set _usrdef_pkg    "fgg676"
set _usrdef_ucf_filename "hdd_test"
set _usrdef_ucf_filepath "..\ucf\hdd_test.ucf"

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
      [ list "../../../common/lib/hw/cfgdev_ctrl/cfgdev_pkg.vhd" $_VHDPkg ] \
      [ list "../../../common/lib/hw/cfgdev_ctrl/cfgdev_ftdi.vhd" $_VHDMod ] \
      [ list "../../../common/lib/hw/cfgdev_ctrl/cfgdev_uart.vhd" $_VHDMod ] \
      [ list "../src/core_gen/cfgdev_rxfifo.vhd" $_VHDMod ] \
      [ list "../src/core_gen/cfgdev_2txfifo.vhd" $_VHDMod ] \
      [ list "../../../common/lib/hw/uart/uart_main_rev01.vhd" $_VHDMod ] \
      [ list "../../../common/lib/hw/uart/src/bbfifo_16x8.vhd" $_VHDMod ] \
      [ list "../../../common/lib/hw/uart/src/kcuart_rx.vhd" $_VHDMod ] \
      [ list "../../../common/lib/hw/uart/src/kcuart_tx.vhd" $_VHDMod ] \
      [ list "../../../common/lib/hw/uart/src/uart_rx.vhd" $_VHDMod ] \
      [ list "../../../common/lib/hw/uart/src/uart_tx.vhd" $_VHDMod ] \
      [ list "../src/core_gen/hdd_ram_hfifo_tx.vhd" $_VHDMod ] \
      [ list "../src/core_gen/hdd_ram_hfifo_rx.vhd" $_VHDMod ] \
      [ list "../src/core_gen/sata_cmdfifo.vhd" $_VHDMod ] \
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
      [ list "../../../common/lib/hw/sata/src/sata_player_s6gt_clkmux_hscam.vhd" $_VHDMod ] \
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
      [ list "../../../common/lib/hw/sata/src/sata_raid_decoder_v2.vhd" $_VHDMod ] \
      [ list "../../../common/lib/hw/sata/src/sata_raid_ctrl_v2.vhd" $_VHDMod ] \
      [ list "../../../common/lib/hw/sata/src/sata_raid.vhd" $_VHDMod ] \
      [ list "../../../common/lib/hw/sata/src/sata_measure.vhd" $_VHDMod ] \
      [ list "../../../common/lib/hw/sata/src/sata_testgen.vhd" $_VHDMod ] \
      [ list "../../../common/lib/hw/sata/src/dsn_raid_main.vhd" $_VHDMod ] \
      [ list "../../../common/lib/hw/sata/dsn_hdd_pkg.vhd" $_VHDPkg ] \
      [ list "../../../common/lib/hw/sata/dsn_hdd.vhd" $_VHDMod ] \
      [ list "../../../common/lib/hw/sata/dsn_hdd_reg_def.vhd" $_VHDPkg ] \
      [ list "../src/core_gen/dbgcs_iconx1.vhd" $_VHDMod ] \
      [ list "../src/core_gen/dbgcs_iconx2.vhd" $_VHDMod ] \
      [ list "../src/core_gen/dbgcs_iconx3.vhd" $_VHDMod ] \
      [ list "../src/core_gen/dbgcs_sata_layer.vhd" $_VHDMod ] \
      [ list "../src/core_gen/dbgcs_sata_rambuf.vhd" $_VHDMod ] \
      [ list "../src/core_gen/dbgcs_sata_raid.vhd" $_VHDMod ] \
      [ list "../src/core_gen/dbgcs_sata_rbuf.vhd" $_VHDMod ] \
      [ list "../hdd_test_prj_cfg.vhd" $_VHDPkg ] \
      [ list "../hdd_test_main.vhd" $_VHDMod ] \
      [ list "../../ucf/hdd_test.ucf" "hdd_test_main" ] \
    ] \
  ] \
]

::projNav::makeProjects $_cwd $_usrdef_design $_usrdef_entity $_projects 10

#cd ../src
#exec "updata_ngc.bat"

