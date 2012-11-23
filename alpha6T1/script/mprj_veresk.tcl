source "../../common/script/projnav.tcl"
#file mkdir "../ise/prj
cd ../ise/prj

set _cwd [pwd]
puts "Currunt PATH ${_cwd}"

set _usrdef_design "AD6T1_veresk"
set _usrdef_entity "veresk_main"
set _usrdef_xilinx_family "virtex6"
set _usrdef_chip_family "v6lxt"
set _usrdef_device "6vlx240t"
set _usrdef_speed  1
set _usrdef_pkg    "ff1759"
set _usrdef_ucf_filename "veresk_main"
set _usrdef_ucf_filepath "..\ucf\veresk_main.ucf"


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
      [ list "../src/core_gen/vmirx_bram.vhd" $_VHDMod ] \
      [ list "../../../common/mirror/vmirx_main.vhd" $_VHDMod ] \
      [ list "../../../common/vctrl/dsn_video_ctrl_pkg.vhd" $_VHDPkg ] \
      [ list "../../../common/vctrl/dsn_video_ctrl.vhd" $_VHDMod ] \
      [ list "../../../common/vctrl/video_reader.vhd" $_VHDMod ] \
      [ list "../../../common/vctrl/video_writer.vhd" $_VHDMod ] \
      [ list "../../../common/lib/hw/eth/src/eth_pkg.vhd" $_VHDPkg ] \
      [ list "../../../common/lib/hw/eth/src/eth_unit_pkg.vhd" $_VHDPkg ] \
      [ list "../../../common/lib/hw/eth/src/eth_mac_rx.vhd" $_VHDMod ] \
      [ list "../../../common/lib/hw/eth/src/eth_mac_tx.vhd" $_VHDMod ] \
      [ list "../../../common/lib/hw/eth/src/eth_app.vhd" $_VHDMod ] \
      [ list "../../../common/lib/hw/eth/src/eth_main.vhd" $_VHDMod ] \
      [ list "../../../common/lib/hw/eth/dsn_eth_pkg.vhd" $_VHDPkg ] \
      [ list "../../../common/lib/hw/eth/dsn_eth.vhd" $_VHDMod ] \
      [ list "../src/core_gen/bram_dma_params.vhd" $_VHDMod ] \
      [ list "../src/core_gen/pcie2mem_fifo.vhd" $_VHDMod ] \
      [ list "../../../common/lib/hw/pci_express/pcie_pkg.vhd" $_VHDPkg ] \
      [ list "../../../common/lib/hw/pci_express/pcie_unit_pkg.vhd" $_VHDPkg ] \
      [ list "../../../common/lib/hw/pci_express/pcie2mem_ctrl.vhd" $_VHDMod ] \
      [ list "../../../common/lib/hw/pci_express/pcie_ctrl.vhd" $_VHDMod ] \
      [ list "../../../common/lib/hw/pci_express/pcie_reset.v" $_VMod ] \
      [ list "../../../common/lib/hw/pci_express/pcie_off_on.v" $_VMod ] \
      [ list "../../../common/lib/hw/pci_express/pcie_mrd_throttle.v" $_VMod ] \
      [ list "../../../common/lib/hw/pci_express/pcie_tx.vhd" $_VHDMod ] \
      [ list "../../../common/lib/hw/pci_express/pcie_rx.vhd" $_VHDMod ] \
      [ list "../../../common/lib/hw/pci_express/pcie_cfg.v" $_VMod ] \
      [ list "../../../common/lib/hw/pci_express/pcie_irq.vhd" $_VHDMod ] \
      [ list "../../../common/lib/hw/pci_express/pcie_irq_dev.vhd" $_VHDMod ] \
      [ list "../../../common/lib/hw/pci_express/pcie_usr_app.vhd" $_VHDMod ] \
      [ list "../src/core_gen/ethg_vctrl_rxfifo.vhd" $_VHDMod ] \
      [ list "../src/core_gen/host_ethg_rxfifo.vhd" $_VHDMod ] \
      [ list "../src/core_gen/host_ethg_txfifo.vhd" $_VHDMod ] \
      [ list "../src/core_gen/host_vbuf.vhd" $_VHDMod ] \
      [ list "../../../common/veresk_pkg.vhd" $_VHDPkg ] \
      [ list "../../../common/video_pkt_filter.vhd" $_VHDMod ] \
      [ list "../../../common/dsn_timer.vhd" $_VHDMod ] \
      [ list "../../../common/dsn_switch.vhd" $_VHDMod ] \
      [ list "../../../common/dsn_host.vhd" $_VHDMod ] \
      [ list "../src/core_gen/pult_buf.vhd" $_VHDMod ] \
      [ list "../../../common/veresk21/pult_core/mup_io.v" $_VMod ] \
      [ list "../../../common/veresk21/pult_core/pult_io.v" $_VMod ] \
      [ list "../../../common/veresk21/sync_u.v" $_VMod ] \
      [ list "../../../common/veresk21/master485n.v" $_VMod ] \
      [ list "../../../common/veresk21/edev.vhd" $_VHDMod ] \
      [ list "../src/core_gen/edev_buf.vhd" $_VHDMod ] \
      [ list "../veresk_prj_cfg.vhd" $_VHDPkg ] \
      [ list "../../../common/veresk_main.vhd" $_VHDMod ] \
      [ list "../../ucf/veresk_main.ucf" "veresk_main" ] \
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
      [ list "../src/alphadata/mig_v3_6/rtl/controller/round_robin_arb.vhd" $_VHDMod ] \
      [ list "../src/alphadata/mig_v3_6/rtl/controller/bank_state.vhd" $_VHDMod ] \
      [ list "../src/alphadata/mig_v3_6/rtl/controller/bank_queue.vhd" $_VHDMod ] \
      [ list "../src/alphadata/mig_v3_6/rtl/controller/bank_compare.vhd" $_VHDMod ] \
      [ list "../src/alphadata/mig_v3_6/rtl/controller/arb_select.vhd" $_VHDMod ] \
      [ list "../src/alphadata/mig_v3_6/rtl/controller/arb_row_col.vhd" $_VHDMod ] \
      [ list "../src/alphadata/mig_v3_6/rtl/controller/rank_common.vhd" $_VHDMod ] \
      [ list "../src/alphadata/mig_v3_6/rtl/controller/rank_cntrl.vhd" $_VHDMod ] \
      [ list "../src/alphadata/mig_v3_6/rtl/controller/bank_common.vhd" $_VHDMod ] \
      [ list "../src/alphadata/mig_v3_6/rtl/controller/bank_cntrl.vhd" $_VHDMod ] \
      [ list "../src/alphadata/mig_v3_6/rtl/controller/arb_mux.vhd" $_VHDMod ] \
      [ list "../src/alphadata/mig_v3_6/rtl/controller/rank_mach.vhd" $_VHDMod ] \
      [ list "../src/alphadata/mig_v3_6/rtl/controller/col_mach.vhd" $_VHDMod ] \
      [ list "../src/alphadata/mig_v3_6/rtl/controller/bank_mach.vhd" $_VHDMod ] \
      [ list "../src/alphadata/mig_v3_6/rtl/controller/mc.vhd" $_VHDMod ] \
      [ list "../src/alphadata/mig_v3_6/rtl/ecc/ecc_merge_enc.vhd" $_VHDMod ] \
      [ list "../src/alphadata/mig_v3_6/rtl/ecc/ecc_gen.vhd" $_VHDMod ] \
      [ list "../src/alphadata/mig_v3_6/rtl/ecc/ecc_dec_fix.vhd" $_VHDMod ] \
      [ list "../src/alphadata/mig_v3_6/rtl/ecc/ecc_buf.vhd" $_VHDMod ] \
      [ list "../src/alphadata/mig_v3_6/rtl/ip_top/mem_intfc.vhd" $_VHDMod ] \
      [ list "../src/alphadata/mig_v3_6/rtl/ip_top/infrastructure.vhd" $_VHDMod ] \
      [ list "../src/alphadata/mig_v3_6/rtl/phy/rd_bitslip.vhd" $_VHDMod ] \
      [ list "../src/alphadata/mig_v3_6/rtl/phy/circ_buffer.vhd" $_VHDMod ] \
      [ list "../src/alphadata/mig_v3_6/rtl/phy/phy_rddata_sync.vhd" $_VHDMod ] \
      [ list "../src/alphadata/mig_v3_6/rtl/phy/phy_rdctrl_sync.vhd" $_VHDMod ] \
      [ list "../src/alphadata/mig_v3_6/rtl/phy/phy_rdclk_gen.vhd" $_VHDMod ] \
      [ list "../src/alphadata/mig_v3_6/rtl/phy/phy_pd.vhd" $_VHDMod ] \
      [ list "../src/alphadata/mig_v3_6/rtl/phy/phy_dq_iob.vhd" $_VHDMod ] \
      [ list "../src/alphadata/mig_v3_6/rtl/phy/phy_dqs_iob.vhd" $_VHDMod ] \
      [ list "../src/alphadata/mig_v3_6/rtl/phy/phy_dm_iob.vhd" $_VHDMod ] \
      [ list "../src/alphadata/mig_v3_6/rtl/phy/phy_ck_iob.vhd" $_VHDMod ] \
      [ list "../src/alphadata/mig_v3_6/rtl/phy/phy_wrlvl.vhd" $_VHDMod ] \
      [ list "../src/alphadata/mig_v3_6/rtl/phy/phy_write.vhd" $_VHDMod ] \
      [ list "../src/alphadata/mig_v3_6/rtl/phy/phy_read.vhd" $_VHDMod ] \
      [ list "../src/alphadata/mig_v3_6/rtl/phy/phy_rdlvl.vhd" $_VHDMod ] \
      [ list "../src/alphadata/mig_v3_6/rtl/phy/phy_pd_top.vhd" $_VHDMod ] \
      [ list "../src/alphadata/mig_v3_6/rtl/phy/phy_init.vhd" $_VHDMod ] \
      [ list "../src/alphadata/mig_v3_6/rtl/phy/phy_dly_ctrl.vhd" $_VHDMod ] \
      [ list "../src/alphadata/mig_v3_6/rtl/phy/phy_data_io.vhd" $_VHDMod ] \
      [ list "../src/alphadata/mig_v3_6/rtl/phy/phy_control_io.vhd" $_VHDMod ] \
      [ list "../src/alphadata/mig_v3_6/rtl/phy/phy_clock_io.vhd" $_VHDMod ] \
      [ list "../src/alphadata/mig_v3_6/rtl/phy/phy_top.vhd" $_VHDMod ] \
      [ list "../src/alphadata/mig_v3_6/rtl/ui/ui_wr_data.vhd" $_VHDMod ] \
      [ list "../src/alphadata/mig_v3_6/rtl/ui/ui_rd_data.vhd" $_VHDMod ] \
      [ list "../src/alphadata/mig_v3_6/rtl/ui/ui_cmd.vhd" $_VHDMod ] \
      [ list "../src/alphadata/mig_v3_6/rtl/ui/ui_top.vhd" $_VHDMod ] \
      [ list "../src/alphadata/axi/carry_latch_or.v" $_VMod ] \
      [ list "../src/alphadata/axi/carry_and.v" $_VMod ] \
      [ list "../src/alphadata/axi/comparator_sel_static.v" $_VMod ] \
      [ list "../src/alphadata/axi/comparator_sel.v" $_VMod ] \
      [ list "../src/alphadata/axi/comparator.v" $_VMod ] \
      [ list "../src/alphadata/axi/command_fifo.v" $_VMod ] \
      [ list "../src/alphadata/axi/carry_or.v" $_VMod ] \
      [ list "../src/alphadata/axi/carry_latch_and.v" $_VMod ] \
      [ list "../src/alphadata/axi/axi_mc_wrap_cmd.v" $_VMod ] \
      [ list "../src/alphadata/axi/axi_mc_incr_cmd.v" $_VMod ] \
      [ list "../src/alphadata/axi/axic_register_slice.v" $_VMod ] \
      [ list "../src/alphadata/axi/w_upsizer.v" $_VMod ] \
      [ list "../src/alphadata/axi/r_upsizer.v" $_VMod ] \
      [ list "../src/alphadata/axi/a_upsizer.v" $_VMod ] \
      [ list "../src/alphadata/axi/axi_register_slice.v" $_VMod ] \
      [ list "../src/alphadata/axi/axi_mc_simple_fifo.v" $_VMod ] \
      [ list "../src/alphadata/axi/axi_mc_cmd_translator.v" $_VMod ] \
      [ list "../src/alphadata/axi/axi_mc_cmd_fsm.v" $_VMod ] \
      [ list "../src/alphadata/axi/axi_upsizer.v" $_VMod ] \
      [ list "../src/alphadata/axi/axi_mc_w_channel.v" $_VMod ] \
      [ list "../src/alphadata/axi/axi_mc_r_channel.v" $_VMod ] \
      [ list "../src/alphadata/axi/axi_mc_cmd_arbiter.v" $_VMod ] \
      [ list "../src/alphadata/axi/axi_mc_b_channel.v" $_VMod ] \
      [ list "../src/alphadata/axi/axi_mc_aw_channel.v" $_VMod ] \
      [ list "../src/alphadata/axi/axi_mc_ar_channel.v" $_VMod ] \
      [ list "../src/alphadata/axi/axi_mc.v" $_VMod ] \
      [ list "../src/core_gen/emac_core/example_design/client/fifo/eth_fifo_16.vhd" $_VHDMod ] \
      [ list "../src/core_gen/emac_core/example_design/client/fifo/tx_client_fifo_16.vhd" $_VHDMod ] \
      [ list "../src/core_gen/emac_core/example_design/client/fifo/rx_client_fifo_16.vhd" $_VHDMod ] \
      [ list "../src/core_gen/emac_core/example_design/physical/double_reset.vhd" $_VHDMod ] \
      [ list "../src/core_gen/emac_core/example_design/physical/v6_gtxwizard.vhd" $_VHDMod ] \
      [ list "../src/core_gen/emac_core/example_design/physical/v6_gtxwizard_top.vhd" $_VHDMod ] \
      [ list "../src/core_gen/emac_core/example_design/emac_core_locallink.vhd" $_VHDMod ] \
      [ list "../src/core_gen/emac_core/example_design/emac_core_block.vhd" $_VHDMod ] \
      [ list "../src/eth/coregen_emac_core_d16.vhd" $_VHDMod ] \
      [ list "../src/eth/coregen_eth_phy_fiber_d16.vhd" $_VHDMod ] \
      [ list "../src/eth/v6_gtxwizard_gtx_2G.vhd" $_VHDMod ] \
      [ list "../src/eth/eth_phy.vhd" $_VHDMod ] \
      [ list "../src/eth/eth_phypin_pkg.vhd" $_VHDPkg ] \
      [ list "../src/core_gen/mem_achcount3_synth.vhd" $_VHDMod ] \
      [ list "../src/core_gen/mem_achcount4_synth.vhd" $_VHDMod ] \
      [ list "../../../common/lib/hw/mem/mem_glob_pkg.vhd" $_VHDPkg ] \
      [ list "../../../common/lib/hw/mem/xilinx/mem_wr_axi_pkg.vhd" $_VHDPkg ] \
      [ list "../../../common/lib/hw/mem/xilinx/mem_wr_axi.vhd" $_VHDMod ] \
      [ list "../src/alphadata/c0_memc_ui_top_axi.vhd" $_VHDMod ] \
      [ list "../src/alphadata/c1_memc_ui_top_axi.vhd" $_VHDMod ] \
      [ list "../src/alphadata/c2_memc_ui_top_axi.vhd" $_VHDMod ] \
      [ list "../src/alphadata/c3_memc_ui_top_axi.vhd" $_VHDMod ] \
      [ list "../src/alphadata/mem_ctrl_axi_pkg.vhd" $_VHDPkg ] \
      [ list "../src/alphadata/mem_ctrl_axi_core.vhd" $_VHDMod ] \
      [ list "../src/alphadata/mem_ctrl_axi.vhd" $_VHDMod ] \
      [ list "../src/alphadata/mem_arb.vhd" $_VHDMod ] \
      [ list "../src/clocks.vhd" $_VHDMod ] \
      [ list "../src/clocks_pkg.vhd" $_VHDPkg ] \
      [ list "../../../common/lib/hw/pci_express/pcie_v6_main.vhd" $_VHDMod ] \
    ] \
  ] \
]

::projNav::makeProjects $_cwd $_usrdef_design $_usrdef_entity $_projects 3

#cd ../src
#exec "updata_ngc.bat"
