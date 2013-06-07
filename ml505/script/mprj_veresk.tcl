source "../../common/script/projnav.tcl"
#file mkdir "../ise/prj
cd ../ise/prj

set _cwd [pwd]
puts "Currunt PATH ${_cwd}"

set _usrdef_design "ml505_veresk"
set _usrdef_entity "veresk_main"
set _usrdef_xilinx_family "virtex5"
set _usrdef_chip_family "v5lxt"
set _usrdef_device "5vlx50t"
set _usrdef_speed  1
set _usrdef_pkg    "ff1136"
set _usrdef_ucf_filename "veresk_main"
set _usrdef_ucf_filepath "..\ucf\veresk_main.ucf"

set _VMod $::projNav::VMod
set _VHDMod $::projNav::VHDMod
set _VHDPkg $::projNav::VHDPkg
set _MXCO $::projNav::MXCO

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
      [ list "../../../common/veresk21/pult_core/pult_io_null.v" $_VMod ] \
      [ list "../../../common/veresk21/sync_u_null.v" $_VMod ] \
      [ list "../../../common/veresk21/edev_null.vhd" $_VHDMod ] \
      [ list "../veresk_prj_cfg.vhd" $_VHDPkg ] \
      [ list "../../../common/veresk_main.vhd" $_VHDMod ] \
      [ list "../../ucf/veresk_main.ucf" "veresk_main" ] \
      [ list "../src/core_gen/core_pciexp_ep_blk_plus/source/use_newinterrupt.v" $_VMod ] \
      [ list "../src/core_gen/core_pciexp_ep_blk_plus/source/pcie_blk_if.v" $_VMod ] \
      [ list "../src/core_gen/core_pciexp_ep_blk_plus/source/pcie_blk_ll.v" $_VMod ] \
      [ list "../src/core_gen/core_pciexp_ep_blk_plus/source/pcie_blk_ll_tx.v" $_VMod ] \
      [ list "../src/core_gen/core_pciexp_ep_blk_plus/source/pcie_blk_ll_tx_arb.v" $_VMod ] \
      [ list "../src/core_gen/core_pciexp_ep_blk_plus/source/pcie_blk_plus_ll_tx.v" $_VMod ] \
      [ list "../src/core_gen/core_pciexp_ep_blk_plus/source/pcie_blk_plus_ll_rx.v" $_VMod ] \
      [ list "../src/core_gen/core_pciexp_ep_blk_plus/source/tlm_rx_data_snk.v" $_VMod ] \
      [ list "../src/core_gen/core_pciexp_ep_blk_plus/source/tlm_rx_data_snk_mal.v" $_VMod ] \
      [ list "../src/core_gen/core_pciexp_ep_blk_plus/source/tlm_rx_data_snk_bar.v" $_VMod ] \
      [ list "../src/core_gen/core_pciexp_ep_blk_plus/source/tlm_rx_data_snk_pwr_mgmt.v" $_VMod ] \
      [ list "../src/core_gen/core_pciexp_ep_blk_plus/source/cmm_decoder.v" $_VMod ] \
      [ list "../src/core_gen/core_pciexp_ep_blk_plus/source/pcie_blk_ll_oqbqfifo.v" $_VMod ] \
      [ list "../src/core_gen/core_pciexp_ep_blk_plus/source/pcie_blk_ll_arb.v" $_VMod ] \
      [ list "../src/core_gen/core_pciexp_ep_blk_plus/source/pcie_blk_ll_credit.v" $_VMod ] \
      [ list "../src/core_gen/core_pciexp_ep_blk_plus/source/pcie_blk_cf.v" $_VMod ] \
      [ list "../src/core_gen/core_pciexp_ep_blk_plus/source/pcie_blk_cf_mgmt.v" $_VMod ] \
      [ list "../src/core_gen/core_pciexp_ep_blk_plus/source/pcie_blk_cf_err.v" $_VMod ] \
      [ list "../src/core_gen/core_pciexp_ep_blk_plus/source/pcie_blk_cf_pwr.v" $_VMod ] \
      [ list "../src/core_gen/core_pciexp_ep_blk_plus/source/pcie_blk_cf_arb.v" $_VMod ] \
      [ list "../src/core_gen/core_pciexp_ep_blk_plus/source/cmm_errman_cnt_en.v" $_VMod ] \
      [ list "../src/core_gen/core_pciexp_ep_blk_plus/source/cmm_errman_cnt_nfl_en.v" $_VMod ] \
      [ list "../src/core_gen/core_pciexp_ep_blk_plus/source/cmm_errman_cor.v" $_VMod ] \
      [ list "../src/core_gen/core_pciexp_ep_blk_plus/source/cmm_errman_cpl.v" $_VMod ] \
      [ list "../src/core_gen/core_pciexp_ep_blk_plus/source/cmm_errman_ftl.v" $_VMod ] \
      [ list "../src/core_gen/core_pciexp_ep_blk_plus/source/cmm_errman_nfl.v" $_VMod ] \
      [ list "../src/core_gen/core_pciexp_ep_blk_plus/source/cmm_errman_ram4x26.v" $_VMod ] \
      [ list "../src/core_gen/core_pciexp_ep_blk_plus/source/cmm_errman_ram8x26.v" $_VMod ] \
      [ list "../src/core_gen/core_pciexp_ep_blk_plus/source/cmm_intr.v" $_VMod ] \
      [ list "../src/core_gen/core_pciexp_ep_blk_plus/source/pcie_soft_int.v" $_VMod ] \
      [ list "../src/core_gen/core_pciexp_ep_blk_plus/source/bram_common.v" $_VMod ] \
      [ list "../src/core_gen/core_pciexp_ep_blk_plus/source/pcie_clocking.v" $_VMod ] \
      [ list "../src/core_gen/core_pciexp_ep_blk_plus/source/tx_sync_gtx.v" $_VMod ] \
      [ list "../src/core_gen/core_pciexp_ep_blk_plus/source/tx_sync_gtp.v" $_VMod ] \
      [ list "../src/core_gen/core_pciexp_ep_blk_plus/source/pcie_gtx_wrapper.v" $_VMod ] \
      [ list "../src/core_gen/core_pciexp_ep_blk_plus/source/pcie_gt_wrapper.v" $_VMod ] \
      [ list "../src/core_gen/core_pciexp_ep_blk_plus/source/pcie_gt_wrapper_top.v" $_VMod ] \
      [ list "../src/core_gen/core_pciexp_ep_blk_plus/source/pcie_mim_wrapper.v" $_VMod ] \
      [ list "../src/core_gen/core_pciexp_ep_blk_plus/source/pcie_reset_logic.v" $_VMod ] \
      [ list "../src/core_gen/core_pciexp_ep_blk_plus/source/pcie_top.v" $_VMod ] \
      [ list "../src/core_gen/core_pciexp_ep_blk_plus/source/prod_fixes.v" $_VMod ] \
      [ list "../src/core_gen/core_pciexp_ep_blk_plus/source/sync_fifo.v" $_VMod ] \
      [ list "../src/core_gen/core_pciexp_ep_blk_plus/source/extend_clk.v" $_VMod ] \
      [ list "../src/core_gen/core_pciexp_ep_blk_plus/source/pcie_ep.v" $_VMod ] \
      [ list "../src/core_gen/core_pciexp_ep_blk_plus/source/core_pciexp_ep_blk_plus.v" $_VMod ] \
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
      [ list "../src/core_gen/emac_core/example_design/client/fifo/eth_fifo_16.vhd" $_VHDMod ] \
      [ list "../src/core_gen/emac_core/example_design/client/fifo/tx_client_fifo_16.vhd" $_VHDMod ] \
      [ list "../src/core_gen/emac_core/example_design/client/fifo/rx_client_fifo_16.vhd" $_VHDMod ] \
      [ list "../src/veresk/eth/physical/gtp_dual_1000X.vhd" $_VHDMod ] \
      [ list "../src/veresk/eth/physical/rocketio_wrapper_gtp.vhd" $_VHDMod ] \
      [ list "../src/veresk/eth/physical/rocketio_wrapper_gtp_tile_2G.vhd" $_VHDMod ] \
      [ list "../src/veresk/eth/emac_core_d16.vhd" $_VHDMod ] \
      [ list "../src/veresk/eth/emac_core_block_d16.vhd" $_VHDMod ] \
      [ list "../src/veresk/eth/emac_core_locallink_d16.vhd" $_VHDMod ] \
      [ list "../src/veresk/eth/coregen_eth_phy_fiber_d16.vhd" $_VHDMod ] \
      [ list "../src/veresk/eth/eth_phypin_pkg.vhd" $_VHDPkg ] \
      [ list "../src/veresk/eth/eth_phy.vhd" $_VHDPkg ] \
      [ list "../src/veresk/clocks.vhd" $_VHDMod ] \
      [ list "../src/veresk/clocks_pkg.vhd" $_VHDPkg ] \
      [ list "../../../common/lib/hw/lib/vicg/v5/v5_gt_pkg.vhd" $_VHDPkg ] \
      [ list "../../../common/lib/hw/lib/vicg/v5/gtp_drp_ctrl.vhd" $_VHDMod ] \
      [ list "../../../common/lib/hw/lib/vicg/v5/gtp_prog_clkmux.vhd" $_VHDMod ] \
      [ list "../../../common/lib/hw/pci_express/pcie_v5_main.vhd" $_VHDMod ] \
      [ list "../../../common/lib/hw/prom_loader/prom_phypin_pkg.vhd" $_VHDPkg ] \
      [ list "../../../common/lib/hw/prom_loader/prog_flash.vhd" $_VHDMod ] \
      [ list "../../../common/lib/hw/prom_loader/prom_ld_main.vhd" $_VHDMod ] \
      [ list "../src/core_gen/prom_buf.vhd" $_VHDMod ] \
    ] \
  ] \
]

::projNav::makeProjects $_cwd $_usrdef_design $_usrdef_entity $_projects 3

#cd ../src
#exec "updata_ngc.bat"
