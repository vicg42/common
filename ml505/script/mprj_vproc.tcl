source "../../common/script/projnav.tcl"
#file mkdir "../ise/prj
cd ../ise/prj

set _cwd [pwd]
puts "Currunt PATH ${_cwd}"

set _usrdef_design "ml505_vproc"
set _usrdef_entity "vproc_main"
set _usrdef_xilinx_family "virtex5"
set _usrdef_chip_family "v5lxt"
set _usrdef_device "5vlx50t"
set _usrdef_speed  1
set _usrdef_pkg    "ff1136"
set _usrdef_ucf_filename "vproc_v5"
set _usrdef_ucf_filepath "..\ucf\vproc_v5.ucf"

set _VMod $::projNav::VMod
set _VHDMod $::projNav::VHDMod
set _VHDPkg $::projNav::VHDPkg
set _MXCO $::projNav::MXCO

set _projects [ list \
  [ list \
    $_usrdef_xilinx_family $_usrdef_device $_usrdef_pkg $_usrdef_speed xrc5t1 [ list \
      [ list "../../../common/lib/hw/lib/vicg/vicg_common_pkg.vhd" $_VHDPkg ] \
      [ list "../../../common/lib/hw/timer/time_gen.vhd" $_VHDMod ] \
      [ list "../../../common/lib/hw/testing/fpga_test_01.vhd" $_VHDMod ] \
      [ list "../src/core_gen/cfgdev_rxfifo.vhd" $_VHDMod ] \
      [ list "../src/core_gen/cfgdev_2txfifo.vhd" $_VHDMod ] \
      [ list "../../../common/lib/hw/cfgdev_ctrl/cfgdev_pkg.vhd" $_VHDPkg ] \
      [ list "../../../common/lib/hw/cfgdev_ctrl/cfgdev_host_eth.vhd" $_VHDMod ] \
      [ list "../src/core_gen/vmirx_bram.vhd" $_VHDMod ] \
      [ list "../../../common/mirror/vmirx_main.vhd" $_VHDMod ] \
      [ list "../../../common/vctrl/dsn_video_ctrl_pkg.vhd" $_VHDPkg ] \
      [ list "../../../common/vctrl/dsn_video_ctrl.vhd" $_VHDMod ] \
      [ list "../../../common/vctrl/video_reader.vhd" $_VHDMod ] \
      [ list "../../../common/vctrl/video_writer.vhd" $_VHDMod ] \
      [ list "../../../common/lib/hw/eth/src/eth_mdio.vhd" $_VHDMod ] \
      [ list "../../../common/lib/hw/eth/src/eth_pkg.vhd" $_VHDPkg ] \
      [ list "../../../common/lib/hw/eth/src/eth_unit_pkg.vhd" $_VHDPkg ] \
      [ list "../../../common/lib/hw/eth/src/eth_ip.vhd" $_VHDMod ] \
      [ list "../../../common/lib/hw/eth/src/eth_main.vhd" $_VHDMod ] \
      [ list "../../../common/lib/hw/eth/dsn_eth_pkg.vhd" $_VHDPkg ] \
      [ list "../../../common/lib/hw/i2c/i2c_core_pkg.vhd" $_VHDPkg ] \
      [ list "../../../common/lib/hw/i2c/i2c_core_master.vhd" $_VHDMod ] \
      [ list "../../../common/lib/hw/video/video_out/dvi_ctrl_ch7301c.vhd" $_VHDMod ] \
      [ list "../../../common/lib/hw/video/video_out/dvi_ctrl_ch7301c_dcm_v5.vhd" $_VHDMod ] \
      [ list "../../../common/lib/hw/video/video_out/dvi_ctrl_ch7301c_ddr_o.vhd" $_VHDMod ] \
      [ list "../src/core_gen/ethg_vctrl_rxfifo.vhd" $_VHDMod ] \
      [ list "../src/core_gen/host_vbuf.vhd" $_VHDMod ] \
      [ list "../../../common/lib/hw/lib/alphadata/admxrc/vhdl/common/dpmem/dpmem_pkg.vhd" $_VHDPkg ] \
      [ list "../../../common/lib/hw/lib/alphadata/admxrc/vhdl/common/dpmem/dpbram0.vhd" $_VHDMod ] \
      [ list "../../../common/lib/hw/lib/alphadata/admxrc/vhdl/common/dpmem/distmem0.vhd" $_VHDMod ] \
      [ list "../../../common/lib/hw/lib/alphadata/admxrc/vhdl/common/dpmem/dpbram.vhd" $_VHDMod ] \
      [ list "../../../common/lib/hw/lib/alphadata/admxrc/vhdl/common/dpmem/distmem.vhd" $_VHDMod ] \
      [ list "../../../common/lib/hw/lib/alphadata/admxrc/vhdl/common/memif/memif_pkg.vhd" $_VHDPkg ] \
      [ list "../../../common/lib/hw/lib/alphadata/admxrc/vhdl/common/memif/memif_int_pkg.vhd" $_VHDPkg ] \
      [ list "../../../common/lib/hw/lib/alphadata/admxrc/vhdl/common/memif/memif_def_synth.vhd" $_VHDMod ] \
      [ list "../../../common/lib/hw/lib/alphadata/admxrc/vhdl/common/memif/ddr2sdram/ddr2sdram_training_dc.vhd" $_VHDMod ] \
      [ list "../../../common/lib/hw/lib/alphadata/admxrc/vhdl/common/memif/ddr2sdram/ddr2sdram_oserdes_dqs.vhd" $_VHDMod ] \
      [ list "../../../common/lib/hw/lib/alphadata/admxrc/vhdl/common/memif/ddr2sdram/ddr2sdram_oserdes_dq.vhd" $_VHDMod ] \
      [ list "../../../common/lib/hw/lib/alphadata/admxrc/vhdl/common/memif/ddr2sdram/ddr2sdram_iserdes_dq.vhd" $_VHDMod ] \
      [ list "../../../common/lib/hw/lib/alphadata/admxrc/vhdl/common/memif/ddr2sdram/ddr2sdram_odt.vhd" $_VHDMod ] \
      [ list "../../../common/lib/hw/lib/alphadata/admxrc/vhdl/common/memif/ddr2sdram/ddr2sdram_init.vhd" $_VHDMod ] \
      [ list "../../../common/lib/hw/lib/alphadata/admxrc/vhdl/common/memif/ddr2sdram/ddr2sdram_dq_out.vhd" $_VHDMod ] \
      [ list "../../../common/lib/hw/lib/alphadata/admxrc/vhdl/common/memif/ddr2sdram/ddr2sdram_dq_in_dc.vhd" $_VHDMod ] \
      [ list "../../../common/lib/hw/lib/alphadata/admxrc/vhdl/common/memif/ddr2sdram/ddr2sdram_dq_in.vhd" $_VHDMod ] \
      [ list "../../../common/lib/hw/lib/alphadata/admxrc/vhdl/common/memif/ddr2sdram/ddr2sdram_dqs_out.vhd" $_VHDMod ] \
      [ list "../../../common/lib/hw/lib/alphadata/admxrc/vhdl/common/memif/ddr2sdram/ddr2sdram_dqs_in.vhd" $_VHDMod ] \
      [ list "../../../common/lib/hw/lib/alphadata/admxrc/vhdl/common/memif/ddr2sdram/ddr2sdram_dm.vhd" $_VHDMod ] \
      [ list "../../../common/lib/hw/lib/alphadata/admxrc/vhdl/common/memif/ddr2sdram/ddr2sdram_ctrl.vhd" $_VHDMod ] \
      [ list "../../../common/lib/hw/lib/alphadata/admxrc/vhdl/common/memif/ddr2sdram/ddr2sdram_clkfw.vhd" $_VHDMod ] \
      [ list "../../../common/lib/hw/lib/alphadata/admxrc/vhdl/common/memif/ddr2sdram/ddr2sdram_port.vhd" $_VHDMod ] \
      [ list "../../../common/lib/hw/lib/alphadata/admxrc/vhdl/common/memif/pulse_sync.vhd" $_VHDMod ] \
      [ list "../../../common/lib/hw/lib/alphadata/admxrc/vhdl/common/memif/port_repl.vhd" $_VHDMod ] \
      [ list "../../../common/lib/hw/lib/alphadata/admxrc/vhdl/common/memif/port_mux.vhd" $_VHDMod ] \
      [ list "../../../common/lib/hw/lib/alphadata/admxrc/vhdl/common/memif/async_port.vhd" $_VHDMod ] \
      [ list "../../../common/lib/hw/lib/alphadata/admxrc/vhdl/common/memif/cmd_fifo.vhd" $_VHDMod ] \
      [ list "../../../common/lib/hw/lib/alphadata/admxrc/vhdl/common/fifo/afifo.vhd" $_VHDMod ] \
      [ list "../../../common/lib/hw/lib/alphadata/admxrc/vhdl/common/fifo/fifo_pkg.vhd" $_VHDPkg ] \
      [ list "../../../common/lib/hw/mem/mem_glob_pkg.vhd" $_VHDPkg ] \
      [ list "../../../common/lib/hw/mem/alphadata/mem_wr_pkg.vhd" $_VHDPkg ] \
      [ list "../../../common/lib/hw/mem/alphadata/mem_ctrl_pkg.vhd" $_VHDPkg ] \
      [ list "../../../common/lib/hw/mem/alphadata/mem_pll.vhd" $_VHDMod ] \
      [ list "../../../common/lib/hw/mem/alphadata/mem_wr.vhd" $_VHDMod ] \
      [ list "../../../common/lib/hw/mem/alphadata/mem_arb.vhd" $_VHDMod ] \
      [ list "../../../common/lib/hw/mem/alphadata/mem_ctrl.vhd" $_VHDMod ] \
      [ list "../src/core_gen/emac_core_sgmii_tri/example_design/client/fifo/tx_client_fifo_8.vhd" $_VHDMod ] \
      [ list "../src/core_gen/emac_core_sgmii_tri/example_design/client/fifo/rx_client_fifo_8.vhd" $_VHDMod ] \
      [ list "../src/core_gen/emac_core_sgmii_tri/example_design/client/fifo/eth_fifo_8.vhd" $_VHDMod ] \
      [ list "../src/core_gen/emac_core_sgmii_tri/example_design/physical/rocketio_wrapper_gtp_tile.vhd" $_VHDMod ] \
      [ list "../src/core_gen/emac_core_sgmii_tri/example_design/physical/rx_elastic_buffer.vhd" $_VHDMod ] \
      [ list "../src/core_gen/emac_core_sgmii_tri/example_design/physical/rocketio_wrapper_gtp.vhd" $_VHDMod ] \
      [ list "../src/core_gen/emac_core_sgmii_tri/example_design/physical/gtp_dual_1000X.vhd" $_VHDMod ] \
      [ list "../src/core_gen/emac_core_sgmii_tri/example_design/emac_core_sgmii_tri.vhd" $_VHDMod ] \
      [ list "../src/core_gen/emac_core_sgmii_tri/example_design/emac_core_sgmii_tri_block.vhd" $_VHDMod ] \
      [ list "../src/core_gen/emac_core_sgmii_tri/example_design/emac_core_sgmii_tri_locallink.vhd" $_VHDMod ] \
      [ list "../src/eth/eth_phypin_pkg.vhd" $_VHDPkg ] \
      [ list "../src/eth/eth_phy.vhd" $_VHDPkg ] \
      [ list "../src/eth/eth_mdio_main.vhd" $_VHDMod ] \
      [ list "../src/eth/eth_app.vhd" $_VHDMod ] \
      [ list "../src/eth/eth_bram_prm.vhd" $_VHDMod ] \
      [ list "../src/eth/dsn_eth.vhd" $_VHDMod ] \
      [ list "../src/eth/v5/eth_gt_clkbuf_v5_sgmii.vhd" $_VHDMod ] \
      [ list "../src/eth/v5/coregen_eth_phy_sgmii_trimode.vhd" $_VHDMod ] \
      [ list "../src/video_processing/v5/clocks.vhd" $_VHDMod ] \
      [ list "../src/video_processing/v5/clocks_pkg.vhd" $_VHDPkg ] \
      [ list "../src/video_processing/v5/prj_cfg.vhd" $_VHDPkg ] \
      [ list "../src/video_processing/prj_def.vhd" $_VHDPkg ] \
      [ list "../src/video_processing/vproc_main.vhd" $_VHDMod ] \
      [ list "../../ucf/vproc_v5.ucf" "vproc_main" ] \
    ] \
  ] \
]

::projNav::makeProjects $_cwd $_usrdef_design $_usrdef_entity $_projects 3

#cd ../src
#exec "updata_ngc.bat"
