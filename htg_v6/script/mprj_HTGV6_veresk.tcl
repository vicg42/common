source "../../common/script/projnav.tcl"
#file mkdir "../ise/prj
cd ../ise/prj

set _cwd [pwd]
puts "Currunt PATH ${_cwd}"

set _usrdef_design "htgv6_veresk"
set _usrdef_entity "veresk_main"
set _usrdef_xilinx_family "virtex6"
set _usrdef_chip_family "v6lxt"
set _usrdef_device "6vlx240t"
set _usrdef_speed  1
set _usrdef_pkg    "ff1759"
set _usrdef_ucf_filename "veresk-6vlx240t-ff1759"


set _VMod $::projNav::VMod
set _VHDMod $::projNav::VHDMod
set _VHDPkg $::projNav::VHDPkg

set _projects [ list \
  [ list \
    $_usrdef_xilinx_family $_usrdef_device $_usrdef_pkg $_usrdef_speed xrc5t1 [ list \
      [ list "../../../common/lib/hw/lib/vicg/vicg_common_pkg.vhd" $_VHDPkg ] \
      [ list "../../../common/prj_def.vhd" $_VHDPkg ] \
      [ list "../../../common/lib/hw/timer/time_gen.vhd" $_VHDMod ] \
      [ list "../../../common/lib/hw/testing/fpga_test_01.vhd" $_VHDMod ] \
      [ list "../src/core_gen/cfgdev_rxfifo.vhd" $_VHDMod ] \
      [ list "../src/core_gen/cfgdev_2txfifo.vhd" $_VHDMod ] \
      [ list "../../../common/lib/hw/cfgdev_ctrl/cfgdev_pkg.vhd" $_VHDPkg ] \
      [ list "../../../common/lib/hw/cfgdev_ctrl/cfgdev_host.vhd" $_VHDMod ] \
      [ list "../src/core_gen/vcoldemosaic_bram.vhd" $_VHDMod ] \
      [ list "../../../common/lib/hw/video/color_demosaic/vcoldemosaic_main_rev3xx.vhd" $_VHDMod ] \
      [ list "../src/core_gen/vgamma_bram_rcol.vhd" $_VHDMod ] \
      [ list "../src/core_gen/vgamma_bram_gcol.vhd" $_VHDMod ] \
      [ list "../src/core_gen/vgamma_bram_bcol.vhd" $_VHDMod ] \
      [ list "../src/core_gen/vgamma_bram_gray.vhd" $_VHDMod ] \
      [ list "../../../common/lib/hw/video/gamma/vgamma_main.vhd" $_VHDMod ] \
      [ list "../src/core_gen/vpcolor_rbram.vhd" $_VHDMod ] \
      [ list "../src/core_gen/vpcolor_gbram.vhd" $_VHDMod ] \
      [ list "../src/core_gen/vpcolor_bbram.vhd" $_VHDMod ] \
      [ list "../../../common/lib/hw/video/pcolor/vpcolor_main.vhd" $_VHDMod ] \
      [ list "../src/core_gen/vscale_bram_coef.vhd" $_VHDMod ] \
      [ list "../src/core_gen/vscale_bram.vhd" $_VHDMod ] \
      [ list "../../../common/lib/hw/video/scaler/vscaler_main_rev3xx.vhd" $_VHDMod ] \
      [ list "../src/core_gen/vmirx_bram.vhd" $_VHDMod ] \
      [ list "../../../common/mirror/vmirx_main.vhd" $_VHDMod ] \
      [ list "../../../common/vctrl/dsn_video_ctrl_pkg.vhd" $_VHDPkg ] \
      [ list "../../../common/vctrl/video_reader_r.vhd" $_VHDMod ] \
      [ list "../../../common/vctrl/video_writer.vhd" $_VHDMod ] \
      [ list "../../../common/vctrl/dsn_video_ctrl.vhd" $_VHDMod ] \
      [ list "../src/core_gen/vbuf_rotate.vhd" $_VHDMod ] \
      [ list "../src/core_gen/hdd_rambuf_infifo.vhd" $_VHDMod ] \
      [ list "../../../common/lib/hw/sata/src/sata_testgen_pkg.vhd" $_VHDPkg ] \
      [ list "../../../common/lib/hw/sata/src/sata_testgen.vhd" $_VHDMod ] \
      [ list "../../../common/lib/hw/sata/src/sata_scrambler.vhd" $_VHDMod ] \
      [ list "../../../common/lib/hw/eth/src/eth_phypin_pkg.vhd" $_VHDPkg ] \
      [ list "../../../common/lib/hw/eth/src/eth_pkg.vhd" $_VHDPkg ] \
      [ list "../../../common/lib/hw/eth/src/eth_unit_pkg.vhd" $_VHDPkg ] \
      [ list "../../../common/lib/hw/eth/src/eth_mac_rx.vhd" $_VHDMod ] \
      [ list "../../../common/lib/hw/eth/src/eth_mac_tx.vhd" $_VHDMod ] \
      [ list "../../../common/lib/hw/eth/src/eth_app.vhd" $_VHDMod ] \
      [ list "../../../common/lib/hw/eth/src/eth_main.vhd" $_VHDMod ] \
      [ list "../../../common/lib/hw/eth/dsn_eth_pkg.vhd" $_VHDPkg ] \
      [ list "../../../common/lib/hw/eth/dsn_eth.vhd" $_VHDMod ] \
      [ list "../../../common/alphadata/lbus_connector_null.vhd" $_VHDMod ] \
      [ list "../../../common/alphadata/lbus_connector_null2.vhd" $_VHDMod ] \
      [ list "../src/core_gen/bram_dma_params.vhd" $_VHDMod ] \
      [ list "../../../common/lib/hw/pci_express/pcie_pkg.vhd" $_VHDPkg ] \
      [ list "../../../common/lib/hw/pci_express/pcie_unit_pkg.vhd" $_VHDPkg ] \
      [ list "../../../common/lib/hw/pci_express/pcie_v6_main.vhd" $_VHDMod ] \
      [ list "../../../common/lib/hw/pci_express/pcie_ctrl.vhd" $_VHDMod ] \
      [ list "../../../common/lib/hw/pci_express/pcie_reset.v" $_VMod ] \
      [ list "../../../common/lib/hw/pci_express/pcie_off_on.v" $_VMod ] \
      [ list "../../../common/lib/hw/pci_express/pcie_mrd_throttle.v" $_VMod ] \
      [ list "../../../common/lib/hw/pci_express/pcie_tx.v" $_VMod ] \
      [ list "../../../common/lib/hw/pci_express/pcie_rx.v" $_VMod ] \
      [ list "../../../common/lib/hw/pci_express/pcie_cfg.v" $_VMod ] \
      [ list "../../../common/lib/hw/pci_express/pcie_irq.vhd" $_VHDMod ] \
      [ list "../../../common/lib/hw/pci_express/pcie_irq_dev.vhd" $_VHDMod ] \
      [ list "../../../common/lib/hw/pci_express/pcie_usr_app.vhd" $_VHDMod ] \
      [ list "../src/core_gen/pcie2mem_fifo.vhd" $_VHDMod ] \
      [ list "../../../common/lib/hw/pci_express/pcie2mem_ctrl.vhd" $_VHDMod ] \
      [ list "../src/core_gen/ethg_vctrl_rxfifo.vhd" $_VHDMod ] \
      [ list "../src/core_gen/host_ethg_rxfifo.vhd" $_VHDMod ] \
      [ list "../src/core_gen/host_ethg_txfifo.vhd" $_VHDMod ] \
      [ list "../src/core_gen/host_vbuf.vhd" $_VHDMod ] \
      [ list "../../../common/veresk_pkg.vhd" $_VHDPkg ] \
      [ list "../../../common/video_pkt_filter.vhd" $_VHDMod ] \
      [ list "../../../common/dsn_timer.vhd" $_VHDMod ] \
      [ list "../../../common/dsn_switch.vhd" $_VHDMod ] \
      [ list "../../../common/dsn_host.vhd" $_VHDMod ] \
      [ list "../src/core_gen/core_pciexp_ep_blk_plus/source/pcie_bram_v6.vhd" $_VHDMod ] \
      [ list "../src/core_gen/core_pciexp_ep_blk_plus/source/gtx_tx_sync_rate_v6.vhd" $_VHDMod ] \
      [ list "../src/core_gen/core_pciexp_ep_blk_plus/source/gtx_rx_valid_filter_v6.vhd" $_VHDMod ] \
      [ list "../src/core_gen/core_pciexp_ep_blk_plus/source/gtx_drp_chanalign_fix_3752_v6.vhd" $_VHDMod ] \
      [ list "../src/core_gen/core_pciexp_ep_blk_plus/source/pcie_pipe_misc_v6.vhd" $_VHDMod ] \
      [ list "../src/core_gen/core_pciexp_ep_blk_plus/source/pcie_pipe_lane_v6.vhd" $_VHDMod ] \
      [ list "../src/core_gen/core_pciexp_ep_blk_plus/source/pcie_brams_v6.vhd" $_VHDMod ] \
      [ list "../src/core_gen/core_pciexp_ep_blk_plus/source/gtx_wrapper_v6.vhd" $_VHDMod ] \
      [ list "../src/core_gen/core_pciexp_ep_blk_plus/source/pcie_upconfig_fix_3451_v6.vhd" $_VHDMod ] \
      [ list "../src/core_gen/core_pciexp_ep_blk_plus/source/pcie_pipe_v6.vhd" $_VHDMod ] \
      [ list "../src/core_gen/core_pciexp_ep_blk_plus/source/pcie_gtx_v6.vhd" $_VHDMod ] \
      [ list "../src/core_gen/core_pciexp_ep_blk_plus/source/pcie_bram_top_v6.vhd" $_VHDMod ] \
      [ list "../src/core_gen/core_pciexp_ep_blk_plus/source/pcie_reset_delay_v6.vhd" $_VHDMod ] \
      [ list "../src/core_gen/core_pciexp_ep_blk_plus/source/pcie_clocking_v6.vhd" $_VHDMod ] \
      [ list "../src/core_gen/core_pciexp_ep_blk_plus/source/pcie_2_0_v6.vhd" $_VHDMod ] \
      [ list "../src/core_gen/core_pciexp_ep_blk_plus/source/core_pciexp_ep_blk_plus.vhd" $_VHDMod ] \
      [ list "../src/core_gen/emac_core/example_design/client/fifo/eth_fifo_8.vhd" $_VHDMod ] \
      [ list "../src/core_gen/emac_core/example_design/client/fifo/tx_client_fifo_8.vhd" $_VHDMod ] \
      [ list "../src/core_gen/emac_core/example_design/client/fifo/rx_client_fifo_8.vhd" $_VHDMod ] \
      [ list "../src/core_gen/emac_core/example_design/physical/double_reset.vhd" $_VHDMod ] \
      [ list "../src/core_gen/emac_core/example_design/physical/v6_gtxwizard.vhd" $_VHDMod ] \
      [ list "../src/core_gen/emac_core/example_design/physical/v6_gtxwizard_gtx.vhd" $_VHDMod ] \
      [ list "../src/core_gen/emac_core/example_design/physical/v6_gtxwizard_top.vhd" $_VHDMod ] \
      [ list "../src/core_gen/emac_core/example_design/emac_core_locallink.vhd" $_VHDMod ] \
      [ list "../src/core_gen/emac_core/example_design/emac_core_block.vhd" $_VHDMod ] \
      [ list "../src/eth/coregen_emac_core_d8.vhd" $_VHDMod ] \
      [ list "../src/eth/coregen_eth_phy_fiber_d8.vhd" $_VHDMod ] \
      [ list "../src/eth/eth_phy.vhd" $_VHDMod ] \
      [ list "../src/core_gen/mem_achcount3_synth.vhd" $_VHDMod ] \
      [ list "../src/core_gen/mem_achcount4_synth.vhd" $_VHDMod ] \
      [ list "../../../common/lib/hw/mem/mem_glob_pkg.vhd" $_VHDPkg ] \
      [ list "../../../common/lib/hw/mem/xilinx/mem_wr_axi_pkg.vhd" $_VHDPkg ] \
      [ list "../../../common/lib/hw/mem/xilinx/mem_wr_axi.vhd" $_VHDMod ] \
      [ list "../src/clocks.vhd" $_VHDMod ] \
      [ list "../src/mem_ctrl_axi_pkg.vhd" $_VHDMod ] \
      [ list "../src/mem_ctrl_axi.vhd" $_VHDMod ] \
      [ list "../src/mem_arb.vhd" $_VHDMod ] \
      [ list "../HTGV6_prj_cfg.vhd" $_VHDPkg ] \
      [ list "../../../common/veresk_main.vhd" $_VHDMod ] \
    ] \
  ] \
]

::projNav::makeProjects $_cwd $_usrdef_design $_usrdef_entity $_projects 10

#cd ../src
#exec "updata_ngc.bat"
