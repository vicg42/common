source projnav.tcl
#file mkdir "../ise/prj
cd ../ise/prj

set _cwd [pwd]
puts "Currunt PATH ${_cwd}"

set _usrdef_design "ml505_hdd_simple"
set _usrdef_entity "hdd_simple_main"
set _usrdef_xilinx_family "virtex5"
set _usrdef_chip_family "v5lxt"
set _usrdef_device "5vlx50t"
set _usrdef_speed  1
set _usrdef_pkg    "ff1136"
set _usrdef_ucf_filename "hdd_simple_main"
set _usrdef_ucf_filepath "..\ucf\hdd_simple_main.ucf"

set _VMod $::projNav::VMod
set _VHDMod $::projNav::VHDMod
set _VHDPkg $::projNav::VHDPkg

set _projects [ list \
  [ list \
    $_usrdef_xilinx_family $_usrdef_device $_usrdef_pkg $_usrdef_speed xrc5t1 [ list \
      [ list "../../../common/hw/lib/vicg/vicg_common_pkg.vhd" $_VHDPkg ] \
      [ list "../../../common/hw/lib/vicg/v5/mclk_gtp_wrap.vhd" $_VHDMod ] \
      [ list "../../../common/veresk_m/prj_def.vhd" $_VHDPkg ] \
      [ list "../../../common/hw/timer/time_gen.vhd" $_VHDMod ] \
      [ list "../../../common/hw/testing/fpga_test_01.vhd" $_VHDMod ] \
      [ list "../../../common/hw/xapp/xapp691/src/vhdl/fifo_utils.vhd" $_VHDPkg ] \
      [ list "../../../common/hw/xapp/xapp691/src/vhdl/BRAM/BRAM_S8_S72.vhd" $_VHDMod ] \
      [ list "../../../common/hw/xapp/xapp691/src/vhdl/BRAM/BRAM_S72_S72.vhd" $_VHDMod ] \
      [ list "../../../common/hw/xapp/xapp691/src/vhdl/BRAM/BRAM_S36_S72.vhd" $_VHDMod ] \
      [ list "../../../common/hw/xapp/xapp691/src/vhdl/BRAM/BRAM_S18_S72.vhd" $_VHDMod ] \
      [ list "../../../common/hw/xapp/xapp691/src/vhdl/DRAM/RAM_64nX1.vhd" $_VHDMod ] \
      [ list "../../../common/hw/xapp/xapp691/src/vhdl/DRAM/DRAM_fifo_pkg.vhd" $_VHDPkg ] \
      [ list "../../../common/hw/xapp/xapp691/src/vhdl/BRAM/BRAM_S8_S144.vhd" $_VHDMod ] \
      [ list "../../../common/hw/xapp/xapp691/src/vhdl/BRAM/BRAM_S72_S144.vhd" $_VHDMod ] \
      [ list "../../../common/hw/xapp/xapp691/src/vhdl/BRAM/BRAM_S36_S144.vhd" $_VHDMod ] \
      [ list "../../../common/hw/xapp/xapp691/src/vhdl/BRAM/BRAM_S16_S144.vhd" $_VHDMod ] \
      [ list "../../../common/hw/xapp/xapp691/src/vhdl/BRAM/BRAM_S144_S144.vhd" $_VHDMod ] \
      [ list "../../../common/hw/xapp/xapp691/src/vhdl/BRAM/BRAM_fifo_pkg.vhd" $_VHDPkg ] \
      [ list "../../../common/hw/xapp/xapp691/src/vhdl/DRAM/DRAM_macro.vhd" $_VHDMod ] \
      [ list "../../../common/hw/xapp/xapp691/src/vhdl/BRAM/BRAM_macro.vhd" $_VHDMod ] \
      [ list "../../../common/hw/xapp/xapp691/src/vhdl/DRAM/DRAM_fifo.vhd" $_VHDMod ] \
      [ list "../../../common/hw/xapp/xapp691/src/vhdl/BRAM/BRAM_fifo.vhd" $_VHDMod ] \
      [ list "../../../common/hw/xapp/xapp691/src/vhdl/ll_fifo_pkg.vhd" $_VHDPkg ] \
      [ list "../../../common/hw/xapp/xapp691/src/vhdl/ll_fifo_DRAM.vhd" $_VHDMod ] \
      [ list "../../../common/hw/xapp/xapp691/src/vhdl/ll_fifo_BRAM.vhd" $_VHDMod ] \
      [ list "../../../common/hw/xapp/xapp691/src/vhdl/ll_fifo.vhd" $_VHDMod ] \
      [ list "../../../common/hw/sata/core_gen/sata_rxfifo.vhd" $_VHDMod ] \
      [ list "../../../common/hw/sata/core_gen/sata_txfifo.vhd" $_VHDMod ] \
      [ list "../../../common/hw/sata/core_gen/hdd_rxfifo.vhd" $_VHDMod ] \
      [ list "../../../common/hw/sata/core_gen/hdd_txfifo.vhd" $_VHDMod ] \
      [ list "../../../common/hw/sata/core_gen/hdd_cmdfifo.vhd" $_VHDMod ] \
      [ list "../../../common/hw/sata/src/sata_pkg.vhd" $_VHDPkg ] \
      [ list "../../../common/hw/sata/src/sata_raid_pkg.vhd" $_VHDPkg ] \
      [ list "../../../common/hw/sata/src/sata_sim_lite_pkg.vhd" $_VHDPkg ] \
      [ list "../../../common/hw/sata/src/sata_unit_pkg.vhd" $_VHDPkg ] \
      [ list "../../../common/hw/sata/src/sata_scrambler.vhd" $_VHDMod ] \
      [ list "../../../common/hw/sata/src/sata_crc.vhd" $_VHDMod ] \
      [ list "../../../common/hw/sata/src/sata_dcm_v5.vhd" $_VHDMod ] \
      [ list "../../../common/hw/sata/src/sata_spd_ctrl_v5gtp.vhd" $_VHDMod ] \
      [ list "../../../common/hw/sata/src/sata_player_v5gtp.vhd" $_VHDMod ] \
      [ list "../../../common/hw/sata/src/sata_player_v5gt_clkmux.vhd" $_VHDMod ] \
      [ list "../../../common/hw/sata/src/sata_player_gtsim.vhd" $_VHDMod ] \
      [ list "../../../common/hw/sata/src/sata_player_oob.vhd" $_VHDMod ] \
      [ list "../../../common/hw/sata/src/sata_player_tx.vhd" $_VHDMod ] \
      [ list "../../../common/hw/sata/src/sata_player_rx.vhd" $_VHDMod ] \
      [ list "../../../common/hw/sata/src/sata_player.vhd" $_VHDMod ] \
      [ list "../../../common/hw/sata/src/sata_llayer.vhd" $_VHDMod ] \
      [ list "../../../common/hw/sata/src/sata_tlayer.vhd" $_VHDMod ] \
      [ list "../../../common/hw/sata/src/sata_alayer.vhd" $_VHDMod ] \
      [ list "../../../common/hw/sata/src/sata_dbgcs.vhd" $_VHDMod ] \
      [ list "../../../common/hw/sata/src/sata_host.vhd" $_VHDMod ] \
      [ list "../../../common/hw/sata/src/sata_connector.vhd" $_VHDMod ] \
      [ list "../../../common/hw/sata/src/sata_raid_decoder.vhd" $_VHDMod ] \
      [ list "../../../common/hw/sata/src/sata_raid_ctrl.vhd" $_VHDMod ] \
      [ list "../../../common/hw/sata/src/sata_raid.vhd" $_VHDMod ] \
      [ list "../../../common/hw/sata/src/sata_measure.vhd" $_VHDMod ] \
      [ list "../../../common/hw/sata/src/dsn_raid_main.vhd" $_VHDMod ] \
      [ list "../../../common/hw/sata/dsn_hdd_pkg.vhd" $_VHDPkg ] \
      [ list "../../../common/hw/sata/dsn_hdd.vhd" $_VHDMod ] \
      [ list "../ml505_hdd_prj_cfg.vhd" $_VHDPkg ] \
      [ list "../hdd_simple_main.vhd" $_VHDMod ] \
      [ list "../../ucf/hdd_simple_main.ucf" "hdd_simple_main" ] \
    ] \
  ] \
]

::projNav::makeProjects $_cwd $_usrdef_design $_usrdef_entity $_projects 10

#cd ../src
#exec "updata_ngc.bat"
