source "../../common/script/projnav.tcl"
#file mkdir "../ise/prj
cd ../ise/prj_

set _cwd [pwd]
puts "Currunt PATH ${_cwd}"

set _usrdef_design "hscam_pcie_dinik7"
set _usrdef_entity "test_hscam_pcie_main"
set _usrdef_xilinx_family "kintex7"
set _usrdef_chip_family "k7t"
set _usrdef_device "7k325t"
set _usrdef_speed  2
set _usrdef_pkg    "ffg676"
set _usrdef_ucf_filename "hscam_pcie_dinik7"
set _usrdef_ucf_filepath "..\ucf\hscam_pcie_dinik7.ucf"

set _VMod $::projNav::VMod
set _VHDMod $::projNav::VHDMod
set _VHDPkg $::projNav::VHDPkg

set _projects [ list \
  [ list \
    $_usrdef_xilinx_family $_usrdef_device $_usrdef_pkg $_usrdef_speed xrc5t1 [ list \
      [ list "../../../common/lib/hw/lib/vicg/vicg_common_pkg.vhd" $_VHDPkg ] \
      [ list "../../../common/lib/hw/timer/time_gen.vhd" $_VHDMod ] \
      [ list "../../../common/lib/hw/testing/fpga_test_01.vhd" $_VHDMod ] \
      [ list "../../../common/lib/hw/cfgdev_ctrl/cfgdev_pkg.vhd" $_VHDPkg ] \
      [ list "../../../common/lib/hw/cfgdev_ctrl/cfgdev_host.vhd" $_VHDMod ] \
      [ list "../../../common/lib/hw/mem/mem_glob_pkg.vhd" $_VHDPkg ] \
      [ list "../../../common/lib/hw/mem/xilinx/mem_wr_axi_pkg.vhd" $_VHDPkg ] \
      [ list "../../../common/lib/hw/mem/xilinx/mem_wr_axi.vhd" $_VHDMod ] \
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
      [ list "../../../common/lib/hw/pci_express/pcie_v7_main_axi.vhd" $_VHDMod ] \
      [ list "../../../common/lib/hw/prom_loader/prog_flash.vhd" $_VHDMod ] \
      [ list "../../../common/lib/hw/prom_loader/prom_ld_main.vhd" $_VHDMod ] \
      [ list "../../../common/vctrl/dsn_video_ctrl_pkg.vhd" $_VHDPkg ] \
      [ list "../../../common/vctrl/dsn_video_ctrl.vhd" $_VHDMod ] \
      [ list "../../../common/vctrl/video_reader.vhd" $_VHDMod ] \
      [ list "../../../common/mirror/vmirx_main.vhd" $_VHDMod ] \
      [ list "../../../common/cfgdev_buf.vhd" $_VHDMod ] \
      [ list "../../../common/dsn_host.vhd" $_VHDMod ] \
      [ list "../../../common/dsn_timer.vhd" $_VHDMod ] \
      [ list "../src/pcie/video_writer.vhd" $_VHDMod ] \
      [ list "../src/pcie/vfr_gen.vhd" $_VHDMod ] \
      [ list "../src/pcie/vin.vhd" $_VHDMod ] \
      [ list "../src/pcie/dsn_switch.vhd" $_VHDMod ] \
      [ list "../src/pcie/test_hscam_pcie_pkg.vhd" $_VHDPkg ] \
      [ list "../src/pcie/test_hscam_pcie_main.vhd" $_VHDMod ] \
      [ list "../src/pcie/prj_def.vhd" $_VHDPkg ] \
      [ list "../src/pcie/k7/dinik7/prj_cfg.vhd" $_VHDPkg ] \
      [ list "../src/pcie/k7/dinik7/clocks.vhd" $_VHDMod ] \
      [ list "../src/pcie/k7/dinik7/clocks_pkg.vhd" $_VHDPkg ] \
      [ list "../src/pcie/k7/dinik7/mem_ctrl_axi_pkg.vhd" $_VHDMod ] \
      [ list "../../ucf/hscam_pcie_dinik7.ucf" "test_hscam_pcie_main" ] \
      [ list "../../../dini_k7/ise/src/prom_phypin_pkg.vhd" $_VHDPkg ] \
      [ list "../../../dini_k7/ise/src/mem_ctrl_axi.vhd" $_VHDMod ] \
      [ list "../../../dini_k7/ise/src/mem_arb.vhd" $_VHDMod ] \
      [ list "../../../dini_k7/ise/src/mem_core/rtl/mem_ctrl_core_axi.v" $_VMod ] \
      [ list "../../../dini_k7/ise/src/mem_core/rtl/axi/mig_7series_v1_9_axi_ctrl_addr_decode.v" $_VMod ] \
      [ list "../../../dini_k7/ise/src/mem_core/rtl/axi/mig_7series_v1_9_axi_ctrl_read.v" $_VMod ] \
      [ list "../../../dini_k7/ise/src/mem_core/rtl/axi/mig_7series_v1_9_axi_ctrl_reg.v" $_VMod ] \
      [ list "../../../dini_k7/ise/src/mem_core/rtl/axi/mig_7series_v1_9_axi_ctrl_reg_bank.v" $_VMod ] \
      [ list "../../../dini_k7/ise/src/mem_core/rtl/axi/mig_7series_v1_9_axi_ctrl_top.v" $_VMod ] \
      [ list "../../../dini_k7/ise/src/mem_core/rtl/axi/mig_7series_v1_9_axi_ctrl_write.v" $_VMod ] \
      [ list "../../../dini_k7/ise/src/mem_core/rtl/axi/mig_7series_v1_9_axi_mc.v" $_VMod ] \
      [ list "../../../dini_k7/ise/src/mem_core/rtl/axi/mig_7series_v1_9_axi_mc_ar_channel.v" $_VMod ] \
      [ list "../../../dini_k7/ise/src/mem_core/rtl/axi/mig_7series_v1_9_axi_mc_aw_channel.v" $_VMod ] \
      [ list "../../../dini_k7/ise/src/mem_core/rtl/axi/mig_7series_v1_9_axi_mc_b_channel.v" $_VMod ] \
      [ list "../../../dini_k7/ise/src/mem_core/rtl/axi/mig_7series_v1_9_axi_mc_cmd_arbiter.v" $_VMod ] \
      [ list "../../../dini_k7/ise/src/mem_core/rtl/axi/mig_7series_v1_9_axi_mc_cmd_fsm.v" $_VMod ] \
      [ list "../../../dini_k7/ise/src/mem_core/rtl/axi/mig_7series_v1_9_axi_mc_cmd_translator.v" $_VMod ] \
      [ list "../../../dini_k7/ise/src/mem_core/rtl/axi/mig_7series_v1_9_axi_mc_incr_cmd.v" $_VMod ] \
      [ list "../../../dini_k7/ise/src/mem_core/rtl/axi/mig_7series_v1_9_axi_mc_r_channel.v" $_VMod ] \
      [ list "../../../dini_k7/ise/src/mem_core/rtl/axi/mig_7series_v1_9_axi_mc_simple_fifo.v" $_VMod ] \
      [ list "../../../dini_k7/ise/src/mem_core/rtl/axi/mig_7series_v1_9_axi_mc_w_channel.v" $_VMod ] \
      [ list "../../../dini_k7/ise/src/mem_core/rtl/axi/mig_7series_v1_9_axi_mc_wr_cmd_fsm.v" $_VMod ] \
      [ list "../../../dini_k7/ise/src/mem_core/rtl/axi/mig_7series_v1_9_axi_mc_wrap_cmd.v" $_VMod ] \
      [ list "../../../dini_k7/ise/src/mem_core/rtl/axi/mig_7series_v1_9_ddr_a_upsizer.v" $_VMod ] \
      [ list "../../../dini_k7/ise/src/mem_core/rtl/axi/mig_7series_v1_9_ddr_axi_register_slice.v" $_VMod ] \
      [ list "../../../dini_k7/ise/src/mem_core/rtl/axi/mig_7series_v1_9_ddr_axi_upsizer.v" $_VMod ] \
      [ list "../../../dini_k7/ise/src/mem_core/rtl/axi/mig_7series_v1_9_ddr_axic_register_slice.v" $_VMod ] \
      [ list "../../../dini_k7/ise/src/mem_core/rtl/axi/mig_7series_v1_9_ddr_carry_and.v" $_VMod ] \
      [ list "../../../dini_k7/ise/src/mem_core/rtl/axi/mig_7series_v1_9_ddr_carry_latch_and.v" $_VMod ] \
      [ list "../../../dini_k7/ise/src/mem_core/rtl/axi/mig_7series_v1_9_ddr_carry_latch_or.v" $_VMod ] \
      [ list "../../../dini_k7/ise/src/mem_core/rtl/axi/mig_7series_v1_9_ddr_carry_or.v" $_VMod ] \
      [ list "../../../dini_k7/ise/src/mem_core/rtl/axi/mig_7series_v1_9_ddr_command_fifo.v" $_VMod ] \
      [ list "../../../dini_k7/ise/src/mem_core/rtl/axi/mig_7series_v1_9_ddr_comparator.v" $_VMod ] \
      [ list "../../../dini_k7/ise/src/mem_core/rtl/axi/mig_7series_v1_9_ddr_comparator_sel.v" $_VMod ] \
      [ list "../../../dini_k7/ise/src/mem_core/rtl/axi/mig_7series_v1_9_ddr_comparator_sel_static.v" $_VMod ] \
      [ list "../../../dini_k7/ise/src/mem_core/rtl/axi/mig_7series_v1_9_ddr_r_upsizer.v" $_VMod ] \
      [ list "../../../dini_k7/ise/src/mem_core/rtl/axi/mig_7series_v1_9_ddr_w_upsizer.v" $_VMod ] \
      [ list "../../../dini_k7/ise/src/mem_core/rtl/clocking/mig_7series_v1_9_clk_ibuf.v" $_VMod ] \
      [ list "../../../dini_k7/ise/src/mem_core/rtl/clocking/mig_7series_v1_9_infrastructure.v" $_VMod ] \
      [ list "../../../dini_k7/ise/src/mem_core/rtl/clocking/mig_7series_v1_9_iodelay_ctrl.v" $_VMod ] \
      [ list "../../../dini_k7/ise/src/mem_core/rtl/clocking/mig_7series_v1_9_tempmon.v" $_VMod ] \
      [ list "../../../dini_k7/ise/src/mem_core/rtl/controller/mig_7series_v1_9_arb_mux.v" $_VMod ] \
      [ list "../../../dini_k7/ise/src/mem_core/rtl/controller/mig_7series_v1_9_arb_row_col.v" $_VMod ] \
      [ list "../../../dini_k7/ise/src/mem_core/rtl/controller/mig_7series_v1_9_arb_select.v" $_VMod ] \
      [ list "../../../dini_k7/ise/src/mem_core/rtl/controller/mig_7series_v1_9_bank_cntrl.v" $_VMod ] \
      [ list "../../../dini_k7/ise/src/mem_core/rtl/controller/mig_7series_v1_9_bank_common.v" $_VMod ] \
      [ list "../../../dini_k7/ise/src/mem_core/rtl/controller/mig_7series_v1_9_bank_compare.v" $_VMod ] \
      [ list "../../../dini_k7/ise/src/mem_core/rtl/controller/mig_7series_v1_9_bank_mach.v" $_VMod ] \
      [ list "../../../dini_k7/ise/src/mem_core/rtl/controller/mig_7series_v1_9_bank_queue.v" $_VMod ] \
      [ list "../../../dini_k7/ise/src/mem_core/rtl/controller/mig_7series_v1_9_bank_state.v" $_VMod ] \
      [ list "../../../dini_k7/ise/src/mem_core/rtl/controller/mig_7series_v1_9_col_mach.v" $_VMod ] \
      [ list "../../../dini_k7/ise/src/mem_core/rtl/controller/mig_7series_v1_9_mc.v" $_VMod ] \
      [ list "../../../dini_k7/ise/src/mem_core/rtl/controller/mig_7series_v1_9_rank_cntrl.v" $_VMod ] \
      [ list "../../../dini_k7/ise/src/mem_core/rtl/controller/mig_7series_v1_9_rank_common.v" $_VMod ] \
      [ list "../../../dini_k7/ise/src/mem_core/rtl/controller/mig_7series_v1_9_rank_mach.v" $_VMod ] \
      [ list "../../../dini_k7/ise/src/mem_core/rtl/controller/mig_7series_v1_9_round_robin_arb.v" $_VMod ] \
      [ list "../../../dini_k7/ise/src/mem_core/rtl/ecc/mig_7series_v1_9_ecc_buf.v" $_VMod ] \
      [ list "../../../dini_k7/ise/src/mem_core/rtl/ecc/mig_7series_v1_9_ecc_dec_fix.v" $_VMod ] \
      [ list "../../../dini_k7/ise/src/mem_core/rtl/ecc/mig_7series_v1_9_ecc_gen.v" $_VMod ] \
      [ list "../../../dini_k7/ise/src/mem_core/rtl/ecc/mig_7series_v1_9_ecc_merge_enc.v" $_VMod ] \
      [ list "../../../dini_k7/ise/src/mem_core/rtl/ip_top/mig_7series_v1_9_mem_intfc.v" $_VMod ] \
      [ list "../../../dini_k7/ise/src/mem_core/rtl/ip_top/mig_7series_v1_9_memc_ui_top_axi.v" $_VMod ] \
      [ list "../../../dini_k7/ise/src/mem_core/rtl/phy/mig_7series_v1_9_ddr_byte_group_io.v" $_VMod ] \
      [ list "../../../dini_k7/ise/src/mem_core/rtl/phy/mig_7series_v1_9_ddr_byte_lane.v" $_VMod ] \
      [ list "../../../dini_k7/ise/src/mem_core/rtl/phy/mig_7series_v1_9_ddr_calib_top.v" $_VMod ] \
      [ list "../../../dini_k7/ise/src/mem_core/rtl/phy/mig_7series_v1_9_ddr_if_post_fifo.v" $_VMod ] \
      [ list "../../../dini_k7/ise/src/mem_core/rtl/phy/mig_7series_v1_9_ddr_mc_phy.v" $_VMod ] \
      [ list "../../../dini_k7/ise/src/mem_core/rtl/phy/mig_7series_v1_9_ddr_mc_phy_wrapper.v" $_VMod ] \
      [ list "../../../dini_k7/ise/src/mem_core/rtl/phy/mig_7series_v1_9_ddr_of_pre_fifo.v" $_VMod ] \
      [ list "../../../dini_k7/ise/src/mem_core/rtl/phy/mig_7series_v1_9_ddr_phy_4lanes.v" $_VMod ] \
      [ list "../../../dini_k7/ise/src/mem_core/rtl/phy/mig_7series_v1_9_ddr_phy_ck_addr_cmd_delay.v" $_VMod ] \
      [ list "../../../dini_k7/ise/src/mem_core/rtl/phy/mig_7series_v1_9_ddr_phy_dqs_found_cal.v" $_VMod ] \
      [ list "../../../dini_k7/ise/src/mem_core/rtl/phy/mig_7series_v1_9_ddr_phy_dqs_found_cal_hr.v" $_VMod ] \
      [ list "../../../dini_k7/ise/src/mem_core/rtl/phy/mig_7series_v1_9_ddr_phy_init.v" $_VMod ] \
      [ list "../../../dini_k7/ise/src/mem_core/rtl/phy/mig_7series_v1_9_ddr_phy_oclkdelay_cal.v" $_VMod ] \
      [ list "../../../dini_k7/ise/src/mem_core/rtl/phy/mig_7series_v1_9_ddr_phy_prbs_rdlvl.v" $_VMod ] \
      [ list "../../../dini_k7/ise/src/mem_core/rtl/phy/mig_7series_v1_9_ddr_phy_rdlvl.v" $_VMod ] \
      [ list "../../../dini_k7/ise/src/mem_core/rtl/phy/mig_7series_v1_9_ddr_phy_tempmon.v" $_VMod ] \
      [ list "../../../dini_k7/ise/src/mem_core/rtl/phy/mig_7series_v1_9_ddr_phy_top.v" $_VMod ] \
      [ list "../../../dini_k7/ise/src/mem_core/rtl/phy/mig_7series_v1_9_ddr_phy_wrcal.v" $_VMod ] \
      [ list "../../../dini_k7/ise/src/mem_core/rtl/phy/mig_7series_v1_9_ddr_phy_wrlvl.v" $_VMod ] \
      [ list "../../../dini_k7/ise/src/mem_core/rtl/phy/mig_7series_v1_9_ddr_phy_wrlvl_off_delay.v" $_VMod ] \
      [ list "../../../dini_k7/ise/src/mem_core/rtl/phy/mig_7series_v1_9_ddr_prbs_gen.v" $_VMod ] \
      [ list "../../../dini_k7/ise/src/mem_core/rtl/ui/mig_7series_v1_9_ui_cmd.v" $_VMod ] \
      [ list "../../../dini_k7/ise/src/mem_core/rtl/ui/mig_7series_v1_9_ui_rd_data.v" $_VMod ] \
      [ list "../../../dini_k7/ise/src/mem_core/rtl/ui/mig_7series_v1_9_ui_top.v" $_VMod ] \
      [ list "../../../dini_k7/ise/src/mem_core/rtl/ui/mig_7series_v1_9_ui_wr_data.v" $_VMod ] \
      [ list "../src/core_gen/k7/core_pciexp_ep_blk_plus_axi/source/core_pciexp_ep_blk_plus_axi.vhd" $_VHDMod ] \
      [ list "../src/core_gen/k7/core_pciexp_ep_blk_plus_axi/source/core_pciexp_ep_blk_plus_axi_gt_rx_valid_filter_7x.vhd" $_VHDMod ] \
      [ list "../src/core_gen/k7/core_pciexp_ep_blk_plus_axi/source/core_pciexp_ep_blk_plus_axi_gt_top.vhd" $_VHDMod ] \
      [ list "../src/core_gen/k7/core_pciexp_ep_blk_plus_axi/source/core_pciexp_ep_blk_plus_axi_pcie_bram_top_7x.vhd" $_VHDMod ] \
      [ list "../src/core_gen/k7/core_pciexp_ep_blk_plus_axi/source/core_pciexp_ep_blk_plus_axi_pcie_brams_7x.vhd" $_VHDMod ] \
      [ list "../src/core_gen/k7/core_pciexp_ep_blk_plus_axi/source/core_pciexp_ep_blk_plus_axi_pcie_bram_7x.vhd" $_VHDMod ] \
      [ list "../src/core_gen/k7/core_pciexp_ep_blk_plus_axi/source/core_pciexp_ep_blk_plus_axi_pcie_7x.vhd" $_VHDMod ] \
      [ list "../src/core_gen/k7/core_pciexp_ep_blk_plus_axi/source/core_pciexp_ep_blk_plus_axi_pcie_pipe_pipeline.vhd" $_VHDMod ] \
      [ list "../src/core_gen/k7/core_pciexp_ep_blk_plus_axi/source/core_pciexp_ep_blk_plus_axi_pcie_pipe_lane.vhd" $_VHDMod ] \
      [ list "../src/core_gen/k7/core_pciexp_ep_blk_plus_axi/source/core_pciexp_ep_blk_plus_axi_pcie_pipe_misc.vhd" $_VHDMod ] \
      [ list "../src/core_gen/k7/core_pciexp_ep_blk_plus_axi/source/core_pciexp_ep_blk_plus_axi_axi_basic_tx_thrtl_ctl.vhd" $_VHDMod ] \
      [ list "../src/core_gen/k7/core_pciexp_ep_blk_plus_axi/source/core_pciexp_ep_blk_plus_axi_axi_basic_rx.vhd" $_VHDMod ] \
      [ list "../src/core_gen/k7/core_pciexp_ep_blk_plus_axi/source/core_pciexp_ep_blk_plus_axi_axi_basic_rx_null_gen.vhd" $_VHDMod ] \
      [ list "../src/core_gen/k7/core_pciexp_ep_blk_plus_axi/source/core_pciexp_ep_blk_plus_axi_axi_basic_rx_pipeline.vhd" $_VHDMod ] \
      [ list "../src/core_gen/k7/core_pciexp_ep_blk_plus_axi/source/core_pciexp_ep_blk_plus_axi_axi_basic_tx_pipeline.vhd" $_VHDMod ] \
      [ list "../src/core_gen/k7/core_pciexp_ep_blk_plus_axi/source/core_pciexp_ep_blk_plus_axi_axi_basic_tx.vhd" $_VHDMod ] \
      [ list "../src/core_gen/k7/core_pciexp_ep_blk_plus_axi/source/core_pciexp_ep_blk_plus_axi_axi_basic_top.vhd" $_VHDMod ] \
      [ list "../src/core_gen/k7/core_pciexp_ep_blk_plus_axi/source/core_pciexp_ep_blk_plus_axi_pcie_top.vhd" $_VHDMod ] \
      [ list "../src/core_gen/k7/core_pciexp_ep_blk_plus_axi/source/core_pciexp_ep_blk_plus_axi_gt_wrapper.v" $_VMod ] \
      [ list "../src/core_gen/k7/core_pciexp_ep_blk_plus_axi/source/core_pciexp_ep_blk_plus_axi_gtp_pipe_reset.v" $_VMod ] \
      [ list "../src/core_gen/k7/core_pciexp_ep_blk_plus_axi/source/core_pciexp_ep_blk_plus_axi_gtp_pipe_rate.v" $_VMod ] \
      [ list "../src/core_gen/k7/core_pciexp_ep_blk_plus_axi/source/core_pciexp_ep_blk_plus_axi_gtp_pipe_drp.v" $_VMod ] \
      [ list "../src/core_gen/k7/core_pciexp_ep_blk_plus_axi/source/core_pciexp_ep_blk_plus_axi_qpll_wrapper.v" $_VMod ] \
      [ list "../src/core_gen/k7/core_pciexp_ep_blk_plus_axi/source/core_pciexp_ep_blk_plus_axi_qpll_drp.v" $_VMod ] \
      [ list "../src/core_gen/k7/core_pciexp_ep_blk_plus_axi/source/core_pciexp_ep_blk_plus_axi_qpll_reset.v" $_VMod ] \
      [ list "../src/core_gen/k7/core_pciexp_ep_blk_plus_axi/source/core_pciexp_ep_blk_plus_axi_rxeq_scan.v" $_VMod ] \
      [ list "../src/core_gen/k7/core_pciexp_ep_blk_plus_axi/source/core_pciexp_ep_blk_plus_axi_pipe_eq.v" $_VMod ] \
      [ list "../src/core_gen/k7/core_pciexp_ep_blk_plus_axi/source/core_pciexp_ep_blk_plus_axi_pipe_clock.v" $_VMod ] \
      [ list "../src/core_gen/k7/core_pciexp_ep_blk_plus_axi/source/core_pciexp_ep_blk_plus_axi_pipe_drp.v" $_VMod ] \
      [ list "../src/core_gen/k7/core_pciexp_ep_blk_plus_axi/source/core_pciexp_ep_blk_plus_axi_pipe_rate.v" $_VMod ] \
      [ list "../src/core_gen/k7/core_pciexp_ep_blk_plus_axi/source/core_pciexp_ep_blk_plus_axi_pipe_reset.v" $_VMod ] \
      [ list "../src/core_gen/k7/core_pciexp_ep_blk_plus_axi/source/core_pciexp_ep_blk_plus_axi_pipe_user.v" $_VMod ] \
      [ list "../src/core_gen/k7/core_pciexp_ep_blk_plus_axi/source/core_pciexp_ep_blk_plus_axi_pipe_sync.v" $_VMod ] \
      [ list "../src/core_gen/k7/core_pciexp_ep_blk_plus_axi/source/core_pciexp_ep_blk_plus_axi_pipe_wrapper.v" $_VMod ] \
      [ list "../src/core_gen/k7/cfgdev_fifo.vhd" $_VHDMod ] \
      [ list "../src/core_gen/k7/bram_dma_params.vhd" $_VHDMod ] \
      [ list "../src/core_gen/k7/vmirx_bram.vhd" $_VHDMod ] \
      [ list "../src/core_gen/k7/host_vbuf.vhd" $_VHDMod ] \
      [ list "../src/core_gen/k7/pcie2mem_fifo.vhd" $_VHDMod ] \
      [ list "../src/core_gen/k7/prom_buf.vhd" $_VHDMod ] \
      [ list "../src/core_gen/k7/vin_bufi.vhd" $_VHDMod ] \
      [ list "../src/core_gen/k7/vin_bufo.vhd" $_VHDMod ] \
      [ list "../src/core_gen/k7/vin_bufc.vhd" $_VHDMod ] \
      [ list "../src/core_gen/k7/mem_achcount3_synth.vhd" $_VHDMod ] \
    ] \
  ] \
]

::projNav::makeProjects $_cwd $_usrdef_design $_usrdef_entity $_projects 10

#cd ../src
#exec "updata_ngc.bat"
