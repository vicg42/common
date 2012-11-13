source "../../common/script/projnav.tcl"
#file mkdir "../ise/prj
cd ../ise/prj

set _cwd [pwd]
puts "Currunt PATH ${_cwd}"

set _usrdef_design "HTGV6_veresk"
set _usrdef_entity "veresk_main"
set _usrdef_xilinx_family "virtex6"
set _usrdef_chip_family "v6lxt"
set _usrdef_device "6vlx240t"
set _usrdef_speed  2
set _usrdef_pkg    "ff1759"
set _usrdef_ucf_filename "veresk_main"
set _usrdef_ucf_filepath "..\ucf\veresk_main_gmii.ucf"


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
      [ list "../veresk_prj_cfg_gmii.vhd" $_VHDPkg ] \
      [ list "../../../common/veresk_main.vhd" $_VHDMod ] \
      [ list "../../ucf/veresk_main_gmii.ucf" "veresk_main" ] \
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
      [ list "../src/core_gen/emac_core/example_design/client/fifo/eth_fifo_16.vhd" $_VHDMod ] \
      [ list "../src/core_gen/emac_core/example_design/client/fifo/tx_client_fifo_16.vhd" $_VHDMod ] \
      [ list "../src/core_gen/emac_core/example_design/client/fifo/rx_client_fifo_16.vhd" $_VHDMod ] \
      [ list "../src/core_gen/emac_core/example_design/physical/double_reset.vhd" $_VHDMod ] \
      [ list "../src/core_gen/emac_core/example_design/physical/v6_gtxwizard.vhd" $_VHDMod ] \
      [ list "../src/core_gen/emac_core/example_design/physical/v6_gtxwizard_top.vhd" $_VHDMod ] \
      [ list "../src/core_gen/emac_core/example_design/emac_core_locallink.vhd" $_VHDMod ] \
      [ list "../src/core_gen/emac_core/example_design/emac_core_block.vhd" $_VHDMod ] \
      [ list "../src/mem_core/rtl/axi/ddr_carry_latch_or.v" $_VMod ] \
      [ list "../src/mem_core/rtl/axi/ddr_carry_and.v" $_VMod ] \
      [ list "../src/mem_core/rtl/axi/ddr_comparator_sel_static.v" $_VMod ] \
      [ list "../src/mem_core/rtl/axi/ddr_comparator_sel.v" $_VMod ] \
      [ list "../src/mem_core/rtl/axi/ddr_comparator.v" $_VMod ] \
      [ list "../src/mem_core/rtl/axi/ddr_command_fifo.v" $_VMod ] \
      [ list "../src/mem_core/rtl/axi/ddr_carry_or.v" $_VMod ] \
      [ list "../src/mem_core/rtl/axi/ddr_carry_latch_and.v" $_VMod ] \
      [ list "../src/mem_core/rtl/axi/ddr_axic_register_slice.v" $_VMod ] \
      [ list "../src/mem_core/rtl/axi/axi_mc_wrap_cmd.v" $_VMod ] \
      [ list "../src/mem_core/rtl/axi/axi_mc_incr_cmd.v" $_VMod ] \
      [ list "../src/mem_core/rtl/axi/fi_xor.v" $_VMod ] \
      [ list "../src/mem_core/rtl/axi/ddr_w_upsizer.v" $_VMod ] \
      [ list "../src/mem_core/rtl/axi/ddr_r_upsizer.v" $_VMod ] \
      [ list "../src/mem_core/rtl/axi/ddr_a_upsizer.v" $_VMod ] \
      [ list "../src/mem_core/rtl/axi/ddr_axi_register_slice.v" $_VMod ] \
      [ list "../src/mem_core/rtl/axi/axi_mc_wr_cmd_fsm.v" $_VMod ] \
      [ list "../src/mem_core/rtl/axi/axi_mc_simple_fifo.v" $_VMod ] \
      [ list "../src/mem_core/rtl/axi/axi_mc_cmd_translator.v" $_VMod ] \
      [ list "../src/mem_core/rtl/axi/axi_mc_cmd_fsm.v" $_VMod ] \
      [ list "../src/mem_core/rtl/axi/axi_ctrl_reg.v" $_VMod ] \
      [ list "../src/mem_core/rtl/axi/axi_ctrl_addr_decode.v" $_VMod ] \
      [ list "../src/mem_core/rtl/axi/ddr_axi_upsizer.v" $_VMod ] \
      [ list "../src/mem_core/rtl/axi/axi_mc_w_channel.v" $_VMod ] \
      [ list "../src/mem_core/rtl/axi/axi_mc_r_channel.v" $_VMod ] \
      [ list "../src/mem_core/rtl/axi/axi_mc_cmd_arbiter.v" $_VMod ] \
      [ list "../src/mem_core/rtl/axi/axi_mc_b_channel.v" $_VMod ] \
      [ list "../src/mem_core/rtl/axi/axi_mc_aw_channel.v" $_VMod ] \
      [ list "../src/mem_core/rtl/axi/axi_mc_ar_channel.v" $_VMod ] \
      [ list "../src/mem_core/rtl/axi/axi_ctrl_write.v" $_VMod ] \
      [ list "../src/mem_core/rtl/axi/axi_ctrl_reg_bank.v" $_VMod ] \
      [ list "../src/mem_core/rtl/axi/axi_ctrl_read.v" $_VMod ] \
      [ list "../src/mem_core/rtl/axi/axi_mc.v" $_VMod ] \
      [ list "../src/mem_core/rtl/axi/axi_ctrl_top.v" $_VMod ] \
      [ list "../src/mem_core/rtl/controller/round_robin_arb.v" $_VMod ] \
      [ list "../src/mem_core/rtl/controller/bank_state.v" $_VMod ] \
      [ list "../src/mem_core/rtl/controller/bank_queue.v" $_VMod ] \
      [ list "../src/mem_core/rtl/controller/bank_compare.v" $_VMod ] \
      [ list "../src/mem_core/rtl/controller/arb_select.v" $_VMod ] \
      [ list "../src/mem_core/rtl/controller/arb_row_col.v" $_VMod ] \
      [ list "../src/mem_core/rtl/controller/rank_common.v" $_VMod ] \
      [ list "../src/mem_core/rtl/controller/rank_cntrl.v" $_VMod ] \
      [ list "../src/mem_core/rtl/controller/bank_common.v" $_VMod ] \
      [ list "../src/mem_core/rtl/controller/bank_cntrl.v" $_VMod ] \
      [ list "../src/mem_core/rtl/controller/arb_mux.v" $_VMod ] \
      [ list "../src/mem_core/rtl/controller/rank_mach.v" $_VMod ] \
      [ list "../src/mem_core/rtl/controller/col_mach.v" $_VMod ] \
      [ list "../src/mem_core/rtl/controller/bank_mach.v" $_VMod ] \
      [ list "../src/mem_core/rtl/controller/mc.v" $_VMod ] \
      [ list "../src/mem_core/rtl/ecc/ecc_merge_enc.v" $_VMod ] \
      [ list "../src/mem_core/rtl/ecc/ecc_gen.v" $_VMod ] \
      [ list "../src/mem_core/rtl/ecc/ecc_dec_fix.v" $_VMod ] \
      [ list "../src/mem_core/rtl/ecc/ecc_buf.v" $_VMod ] \
      [ list "../src/mem_core/rtl/phy/rd_bitslip.v" $_VMod ] \
      [ list "../src/mem_core/rtl/phy/circ_buffer.v" $_VMod ] \
      [ list "../src/mem_core/rtl/phy/phy_rddata_sync.v" $_VMod ] \
      [ list "../src/mem_core/rtl/phy/phy_rdctrl_sync.v" $_VMod ] \
      [ list "../src/mem_core/rtl/phy/phy_rdclk_gen.v" $_VMod ] \
      [ list "../src/mem_core/rtl/phy/phy_pd.v" $_VMod ] \
      [ list "../src/mem_core/rtl/phy/phy_dq_iob.v" $_VMod ] \
      [ list "../src/mem_core/rtl/phy/phy_dqs_iob.v" $_VMod ] \
      [ list "../src/mem_core/rtl/phy/phy_dm_iob.v" $_VMod ] \
      [ list "../src/mem_core/rtl/phy/phy_ck_iob.v" $_VMod ] \
      [ list "../src/mem_core/rtl/phy/phy_wrlvl.v" $_VMod ] \
      [ list "../src/mem_core/rtl/phy/phy_write.v" $_VMod ] \
      [ list "../src/mem_core/rtl/phy/phy_read.v" $_VMod ] \
      [ list "../src/mem_core/rtl/phy/phy_rdlvl.v" $_VMod ] \
      [ list "../src/mem_core/rtl/phy/phy_pd_top.v" $_VMod ] \
      [ list "../src/mem_core/rtl/phy/phy_init.v" $_VMod ] \
      [ list "../src/mem_core/rtl/phy/phy_dly_ctrl.v" $_VMod ] \
      [ list "../src/mem_core/rtl/phy/phy_data_io.v" $_VMod ] \
      [ list "../src/mem_core/rtl/phy/phy_control_io.v" $_VMod ] \
      [ list "../src/mem_core/rtl/phy/phy_clock_io.v" $_VMod ] \
      [ list "../src/mem_core/rtl/phy/phy_top.v" $_VMod ] \
      [ list "../src/mem_core/rtl/ui/ui_wr_data.v" $_VMod ] \
      [ list "../src/mem_core/rtl/ui/ui_rd_data.v" $_VMod ] \
      [ list "../src/mem_core/rtl/ui/ui_cmd.v" $_VMod ] \
      [ list "../src/mem_core/rtl/ui/ui_top.v" $_VMod ] \
      [ list "../src/mem_core/rtl/ip_top/mem_intfc.v" $_VMod ] \
      [ list "../src/iodelay_ctrl.v" $_VMod ] \
      [ list "../src/infrastructure.v" $_VMod ] \
      [ list "../src/mem_core/rtl/ip_top/memc_ui_top.v" $_VMod ] \
      [ list "../src/mem_core/rtl/ip_top/ddr2_ddr3_chipscope.v" $_VMod ] \
      [ list "../src/mem_core/rtl/ip_top/clk_ibuf.v" $_VMod ] \
      [ list "../src/mem_ctrl_core_axi.v" $_VMod ] \
      [ list "../../../common/lib/hw/mem/mem_glob_pkg.vhd" $_VHDPkg ] \
      [ list "../../../common/lib/hw/mem/xilinx/mem_wr_axi_pkg.vhd" $_VHDPkg ] \
      [ list "../../../common/lib/hw/mem/xilinx/mem_wr_axi.vhd" $_VHDMod ] \
      [ list "../src/mem_ctrl_axi_pkg.vhd" $_VHDMod ] \
      [ list "../src/mem_ctrl_axi.vhd" $_VHDMod ] \
      [ list "../src/mem_arb.vhd" $_VHDMod ] \
      [ list "../src/core_gen/mem_achcount3_synth.vhd" $_VHDMod ] \
      [ list "../src/core_gen/mem_achcount4_synth.vhd" $_VHDMod ] \
      [ list "../src/eth/coregen_emac_core_d16.vhd" $_VHDMod ] \
      [ list "../src/eth/coregen_eth_phy_fiber_d16.vhd" $_VHDMod ] \
      [ list "../src/eth/v6_gtxwizard_gtx_2G.vhd" $_VHDMod ] \
      [ list "../src/eth/eth_phy.vhd" $_VHDMod ] \
      [ list "../src/eth/eth_phypin_pkg.vhd" $_VHDPkg ] \
      [ list "../src/clocks.vhd" $_VHDMod ] \
      [ list "../src/clocks_pkg.vhd" $_VHDPkg ] \
      [ list "../../../common/lib/hw/pci_express/pcie_v6_main.vhd" $_VHDMod ] \
      [ list "../../../common/lib/hw/eth/src/eth_mdio.vhd" $_VHDMod ] \
      [ list "../src/eth/eth_mdio_main.vhd" $_VHDMod ] \
      [ list "../src/eth/coregen_eth_phy_gmii.vhd" $_VHDMod ] \
      [ list "../src/core_gen/emac_gmii_core/example_design/client/fifo/eth_fifo_8.vhd" $_VHDMod ] \
      [ list "../src/core_gen/emac_gmii_core/example_design/client/fifo/tx_client_fifo_8.vhd" $_VHDMod ] \
      [ list "../src/core_gen/emac_gmii_core/example_design/client/fifo/rx_client_fifo_8.vhd" $_VHDMod ] \
      [ list "../src/core_gen/emac_gmii_core/example_design/physical/gmii_if.vhd" $_VHDMod ] \
      [ list "../src/core_gen/emac_gmii_core/example_design/emac_gmii_core.vhd" $_VHDMod ] \
      [ list "../src/core_gen/emac_gmii_core/example_design/emac_gmii_core_block.vhd" $_VHDMod ] \
      [ list "../src/core_gen/emac_gmii_core/example_design/emac_gmii_core_locallink.vhd" $_VHDMod ] \
    ] \
  ] \
]

::projNav::makeProjects $_cwd $_usrdef_design $_usrdef_entity $_projects 4

#cd ../src
#exec "updata_ngc.bat"
