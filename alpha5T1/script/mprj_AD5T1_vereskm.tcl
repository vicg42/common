source "../../common/script/projnav.tcl"
#file mkdir "../ise/prj
cd ../ise/prj

set _cwd [pwd]
puts "Currunt PATH ${_cwd}"

set _usrdef_design "AD5T1_vereskm"
set _usrdef_entity "vereskm_main"
set _usrdef_xilinx_family "virtex5"
set _usrdef_chip_family "v5lxt"
set _usrdef_device "5vlx110t"
set _usrdef_speed  1
set _usrdef_pkg    "ff1136"
set _usrdef_ucf_filename "vereskm-5vlx110t-ffg1136"
set _usrdef_ucf_filepath "..\ucf\vereskm-5vlx110t-ffg1136.ucf"


set _VMod $::projNav::VMod
set _VHDMod $::projNav::VHDMod
set _VHDPkg $::projNav::VHDPkg

set _projects [ list \
  [ list \
    $_usrdef_xilinx_family $_usrdef_device $_usrdef_pkg $_usrdef_speed xrc5t1 [ list \
      [ list "../../../common/hw/lib/vicg/vicg_common_pkg.vhd" $_VHDPkg ] \
      [ list "../../../common/hw/lib/vicg/v5/mclk_gtp_wrap.vhd" $_VHDMod ] \
      [ list "../../../common/hw/lib/vicg/v5/gtp_drp_ctrl.vhd" $_VHDMod ] \
      [ list "../../../common/hw/lib/vicg/v5/gtp_prog_clkmux.vhd" $_VHDMod ] \
      [ list "../../../common/veresk_m/prj_def.vhd" $_VHDPkg ] \
      [ list "../../../common/hw/timer/time_gen.vhd" $_VHDMod ] \
      [ list "../../../common/hw/testing/fpga_test_01.vhd" $_VHDMod ] \
      [ list "../../../common/hw/lib/alphadata/admxrc/vhdl/common/dpmem/dpmem_pkg.vhd" $_VHDPkg ] \
      [ list "../../../common/hw/lib/alphadata/admxrc/vhdl/common/dpmem/dpbram0.vhd" $_VHDMod ] \
      [ list "../../../common/hw/lib/alphadata/admxrc/vhdl/common/dpmem/distmem0.vhd" $_VHDMod ] \
      [ list "../../../common/hw/lib/alphadata/admxrc/vhdl/common/dpmem/dpbram.vhd" $_VHDMod ] \
      [ list "../../../common/hw/lib/alphadata/admxrc/vhdl/common/dpmem/distmem.vhd" $_VHDMod ] \
      [ list "../../../common/hw/lib/alphadata/admxrc/vhdl/common/memif/memif_pkg.vhd" $_VHDPkg ] \
      [ list "../../../common/hw/lib/alphadata/admxrc/vhdl/common/memif/memif_int_pkg.vhd" $_VHDPkg ] \
      [ list "../../../common/hw/lib/alphadata/admxrc/vhdl/common/memif/memif_def_synth.vhd" $_VHDMod ] \
      [ list "../../../common/hw/lib/alphadata/admxrc/vhdl/common/memif/ddr2sdram/ddr2sdram_training_dc.vhd" $_VHDMod ] \
      [ list "../../../common/hw/lib/alphadata/admxrc/vhdl/common/memif/ddr2sdram/ddr2sdram_oserdes_dqs.vhd" $_VHDMod ] \
      [ list "../../../common/hw/lib/alphadata/admxrc/vhdl/common/memif/ddr2sdram/ddr2sdram_oserdes_dq.vhd" $_VHDMod ] \
      [ list "../../../common/hw/lib/alphadata/admxrc/vhdl/common/memif/ddr2sdram/ddr2sdram_iserdes_dq.vhd" $_VHDMod ] \
      [ list "../../../common/hw/lib/alphadata/admxrc/vhdl/common/memif/ddr2sdram/ddr2sdram_odt.vhd" $_VHDMod ] \
      [ list "../../../common/hw/lib/alphadata/admxrc/vhdl/common/memif/ddr2sdram/ddr2sdram_init.vhd" $_VHDMod ] \
      [ list "../../../common/hw/lib/alphadata/admxrc/vhdl/common/memif/ddr2sdram/ddr2sdram_dq_out.vhd" $_VHDMod ] \
      [ list "../../../common/hw/lib/alphadata/admxrc/vhdl/common/memif/ddr2sdram/ddr2sdram_dq_in_dc.vhd" $_VHDMod ] \
      [ list "../../../common/hw/lib/alphadata/admxrc/vhdl/common/memif/ddr2sdram/ddr2sdram_dq_in.vhd" $_VHDMod ] \
      [ list "../../../common/hw/lib/alphadata/admxrc/vhdl/common/memif/ddr2sdram/ddr2sdram_dqs_out.vhd" $_VHDMod ] \
      [ list "../../../common/hw/lib/alphadata/admxrc/vhdl/common/memif/ddr2sdram/ddr2sdram_dqs_in.vhd" $_VHDMod ] \
      [ list "../../../common/hw/lib/alphadata/admxrc/vhdl/common/memif/ddr2sdram/ddr2sdram_dm.vhd" $_VHDMod ] \
      [ list "../../../common/hw/lib/alphadata/admxrc/vhdl/common/memif/ddr2sdram/ddr2sdram_ctrl.vhd" $_VHDMod ] \
      [ list "../../../common/hw/lib/alphadata/admxrc/vhdl/common/memif/ddr2sdram/ddr2sdram_clkfw.vhd" $_VHDMod ] \
      [ list "../../../common/hw/lib/alphadata/admxrc/vhdl/common/memif/ddr2sdram/ddr2sdram_port.vhd" $_VHDMod ] \
      [ list "../../../common/hw/lib/alphadata/admxrc/vhdl/common/memif/ddr2sram_v4/ddr2sram_training.vhd" $_VHDMod ] \
      [ list "../../../common/hw/lib/alphadata/admxrc/vhdl/common/memif/ddr2sram_v4/ddr2sram_dq_out.vhd" $_VHDMod ] \
      [ list "../../../common/hw/lib/alphadata/admxrc/vhdl/common/memif/ddr2sram_v4/ddr2sram_dq_in.vhd" $_VHDMod ] \
      [ list "../../../common/hw/lib/alphadata/admxrc/vhdl/common/memif/ddr2sram_v4/ddr2sram_bwe.vhd" $_VHDMod ] \
      [ list "../../../common/hw/lib/alphadata/admxrc/vhdl/common/memif/ddr2sram_v4/ddr2sram_oserdes_dq.vhd" $_VHDMod ] \
      [ list "../../../common/hw/lib/alphadata/admxrc/vhdl/common/memif/ddr2sram_v4/ddr2sram_iserdes_dq.vhd" $_VHDMod ] \
      [ list "../../../common/hw/lib/alphadata/admxrc/vhdl/common/memif/ddr2sram_v4/ddr2sram_port_v4.vhd" $_VHDMod ] \
      [ list "../../../common/hw/lib/alphadata/admxrc/vhdl/common/memif/pulse_sync.vhd" $_VHDMod ] \
      [ list "../../../common/hw/lib/alphadata/admxrc/vhdl/common/memif/port_repl.vhd" $_VHDMod ] \
      [ list "../../../common/hw/lib/alphadata/admxrc/vhdl/common/memif/port_mux.vhd" $_VHDMod ] \
      [ list "../../../common/hw/lib/alphadata/admxrc/vhdl/common/memif/async_port.vhd" $_VHDMod ] \
      [ list "../../../common/hw/lib/alphadata/admxrc/vhdl/common/memif/cmd_fifo.vhd" $_VHDMod ] \
      [ list "../../../common/hw/lib/alphadata/admxrc/vhdl/common/memif/arbiter_4.vhd" $_VHDMod ] \
      [ list "../../../common/hw/lib/alphadata/admxrc/vhdl/common/memif/arbiter_2.vhd" $_VHDMod ] \
      [ list "../../../common/hw/lib/alphadata/admxrc/vhdl/common/fifo/afifo.vhd" $_VHDMod ] \
      [ list "../../../common/hw/lib/alphadata/admxrc/vhdl/common/fifo/fifo_pkg.vhd" $_VHDPkg ] \
      [ list "../../../common/hw/lib/alphadata/admxrc/vhdl/common/localbus/plxdssm.vhd" $_VHDMod ] \
      [ list "../../../common/hw/lib/alphadata/admxrc/vhdl/common/localbus/localbus_pkg.vhd" $_VHDPkg ] \
      [ list "../../../common/hw/mem/alphadata/memory_ctrl_pkg.vhd" $_VHDMod ] \
      [ list "../../../common/hw/mem/alphadata/memory_ctrl_pll.vhd" $_VHDMod ] \
      [ list "../../../common/hw/mem/alphadata/memory_ctrl_ch_wr.vhd" $_VHDMod ] \
      [ list "../../../common/hw/mem/alphadata/memory_ch_arbitr.vhd" $_VHDMod ] \
      [ list "../../../common/hw/mem/alphadata/memory_ctrl.vhd" $_VHDMod ] \
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
      [ list "../src/core_gen/cfgdev_rxfifo.vhd" $_VHDMod ] \
      [ list "../src/core_gen/cfgdev_2txfifo.vhd" $_VHDMod ] \
      [ list "../../../common/hw/cfgdev_ctrl/cfgdev_pkg.vhd" $_VHDPkg ] \
      [ list "../../../common/hw/cfgdev_ctrl/cfgdev_host.vhd" $_VHDMod ] \
      [ list "../src/core_gen/vcoldemosaic_bram.vhd" $_VHDMod ] \
      [ list "../../../common/hw/video/color_demosaic/vcoldemosaic_main_rev3xx.vhd" $_VHDMod ] \
      [ list "../src/core_gen/vgamma_bram_rcol.vhd" $_VHDMod ] \
      [ list "../src/core_gen/vgamma_bram_gcol.vhd" $_VHDMod ] \
      [ list "../src/core_gen/vgamma_bram_bcol.vhd" $_VHDMod ] \
      [ list "../src/core_gen/vgamma_bram_gray.vhd" $_VHDMod ] \
      [ list "../../../common/hw/video/gamma/vgamma_main.vhd" $_VHDMod ] \
      [ list "../src/core_gen/vpcolor_rbram.vhd" $_VHDMod ] \
      [ list "../src/core_gen/vpcolor_gbram.vhd" $_VHDMod ] \
      [ list "../src/core_gen/vpcolor_bbram.vhd" $_VHDMod ] \
      [ list "../../../common/hw/video/pcolor/vpcolor_main.vhd" $_VHDMod ] \
      [ list "../src/core_gen/vscale_bram_coef.vhd" $_VHDMod ] \
      [ list "../src/core_gen/vscale_bram.vhd" $_VHDMod ] \
      [ list "../../../common/hw/video/scaler/vscaler_main_rev3xx.vhd" $_VHDMod ] \
      [ list "../src/core_gen/vsobel_bram.vhd" $_VHDMod ] \
      [ list "../src/core_gen/vsobel_sub.vhd" $_VHDMod ] \
      [ list "../../../common/hw/video/sobel/vsobel_main_rev3xx.vhd" $_VHDMod ] \
      [ list "../src/core_gen/hdd_rambuf_infifo.vhd" $_VHDMod ] \
      [ list "../src/core_gen/sata_rxfifo.vhd" $_VHDMod ] \
      [ list "../src/core_gen/sata_txfifo.vhd" $_VHDMod ] \
      [ list "../src/core_gen/hdd_rxfifo.vhd" $_VHDMod ] \
      [ list "../src/core_gen/hdd_txfifo.vhd" $_VHDMod ] \
      [ list "../src/core_gen/hdd_cmdfifo.vhd" $_VHDMod ] \
      [ list "../../../common/hw/sata/src/sata_glob_pkg.vhd" $_VHDPkg ] \
      [ list "../../../common/hw/sata/src/sata_pkg.vhd" $_VHDPkg ] \
      [ list "../../../common/hw/sata/src/sata_testgen_pkg.vhd" $_VHDPkg ] \
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
      [ list "../../../common/hw/sata/src/sata_player_rx.vhd" $_VHDMod ] \
      [ list "../../../common/hw/sata/src/sata_player_tx.vhd" $_VHDMod ] \
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
      [ list "../../../common/hw/sata/src/sata_hwstart_ctrl.vhd" $_VHDMod ] \
      [ list "../../../common/hw/sata/src/sata_testgen.vhd" $_VHDMod ] \
      [ list "../../../common/hw/sata/src/dsn_raid_main.vhd" $_VHDMod ] \
      [ list "../../../common/hw/sata/dsn_hdd_pkg.vhd" $_VHDMod ] \
      [ list "../../../common/hw/sata/dsn_hdd.vhd" $_VHDMod ] \
      [ list "../../../common/hw/sata/dsn_hdd_rambuf.vhd" $_VHDMod ] \
      [ list "../../../common/veresk_m/color_conv/vrgb2yuv_main_rev0xx.vhd" $_VHDMod ] \
      [ list "../src/core_gen/vmirx_bram.vhd" $_VHDMod ] \
      [ list "../../../common/veresk_m/mirror/vmirx_main.vhd" $_VHDMod ] \
      [ list "../../../common/veresk_m/vctrl/dsn_video_ctrl_pkg.vhd" $_VHDPkg ] \
      [ list "../../../common/veresk_m/vctrl/video_reader.vhd" $_VHDMod ] \
      [ list "../../../common/veresk_m/vctrl/video_writer.vhd" $_VHDMod ] \
      [ list "../../../common/veresk_m/vctrl/dsn_video_ctrl.vhd" $_VHDMod ] \
      [ list "../../../common/veresk_m/tester/vtester_v01.vhd" $_VHDMod ] \
      [ list "../src/core_gen/trc_nik_bufout.vhd" $_VHDMod ] \
      [ list "../src/core_gen/trc_nik_vbuf.vhd" $_VHDMod ] \
      [ list "../src/core_gen/trc_nik_ramang.vhd" $_VHDMod ] \
      [ list "../src/core_gen/trc_nik_mult.vhd" $_VHDMod ] \
      [ list "../../../common/veresk_m/tracker_nik/dsn_track_nik_pkg.vhd" $_VHDPkg ] \
      [ list "../../../common/veresk_m/tracker_nik/dsn_track_nik.vhd" $_VHDMod ] \
      [ list "../../../common/veresk_m/tracker_nik/trc_nik_core.vhd" $_VHDMod ] \
      [ list "../../../common/veresk_m/tracker_nik/trc_nik_grado.vhd" $_VHDMod ] \
      [ list "../../../common/veresk_m/eth/core_gen/emac_core/example_design/client/fifo/eth_fifo_8.vhd" $_VHDMod ] \
      [ list "../../../common/veresk_m/eth/core_gen/emac_core/example_design/client/fifo/tx_client_fifo_8.vhd" $_VHDMod ] \
      [ list "../../../common/veresk_m/eth/core_gen/emac_core/example_design/client/fifo/rx_client_fifo_8.vhd" $_VHDMod ] \
      [ list "../../../common/veresk_m/eth/src/eth_pkg.vhd" $_VHDPkg ] \
      [ list "../../../common/veresk_m/eth/src/eth_rx_rev1xx.vhd" $_VHDMod ] \
      [ list "../../../common/veresk_m/eth/src/eth_tx_rev1xx.vhd" $_VHDMod ] \
      [ list "../../../common/veresk_m/eth/src/emac_core_main.vhd" $_VHDMod ] \
      [ list "../../../common/veresk_m/eth/src/eth_main.vhd" $_VHDMod ] \
      [ list "../../../common/veresk_m/eth/dsn_ethg_pkg.vhd" $_VHDPkg ] \
      [ list "../../../common/veresk_m/eth/dsn_ethg.vhd" $_VHDMod ] \
      [ list "../../../common/veresk_m/alphadata/lbus_connector_32bit.vhd" $_VHDMod ] \
      [ list "../../../common/veresk_m/alphadata/lbus_connector_32bit_tst.vhd" $_VHDMod ] \
      [ list "../../../common/veresk_m/alphadata/lbus_dcm.vhd" $_VHDMod ] \
      [ list "../src/core_gen/bram_dma_params.vhd" $_VHDMod ] \
      [ list "../../../common/veresk_m/pci_express/v5/pciexp_main.vhd" $_VHDMod ] \
      [ list "../../../common/veresk_m/pci_express/v5/pciexp_ctrl_rst.v" $_VMod ] \
      [ list "../../../common/veresk_m/pci_express/v5/pciexp_ep_cntrl.v" $_VMod ] \
      [ list "../../../common/veresk_m/pci_express/v5/BMD_TO_CTRL.v" $_VMod ] \
      [ list "../../../common/veresk_m/pci_express/v5/BMD_RD_THROTTLE.v" $_VMod ] \
      [ list "../../../common/veresk_m/pci_express/v5/BMD_ENGINE_TX.v" $_VMod ] \
      [ list "../../../common/veresk_m/pci_express/v5/BMD_ENGINE_RX.v" $_VMod ] \
      [ list "../../../common/veresk_m/pci_express/v5/BMD_CFG_CTRL.v" $_VMod ] \
      [ list "../../../common/veresk_m/pci_express/v5/BMD_INTR_CTRL.vhd" $_VHDMod ] \
      [ list "../../../common/veresk_m/pci_express/v5/BMD_INTR_CTRL_DEV.vhd" $_VHDMod ] \
      [ list "../../../common/veresk_m/pci_express/v5/pciexp_usr_ctrl.vhd" $_VHDMod ] \
      [ list "../src/core_gen/ethg_vctrl_rxfifo.vhd" $_VHDMod ] \
      [ list "../src/core_gen/host_ethg_rxfifo.vhd" $_VHDMod ] \
      [ list "../src/core_gen/host_ethg_txfifo.vhd" $_VHDMod ] \
      [ list "../src/core_gen/host_vbuf.vhd" $_VHDMod ] \
      [ list "../src/core_gen/dbgcs_iconx1.vhd" $_VHDMod ] \
      [ list "../src/core_gen/dbgcs_iconx2.vhd" $_VHDMod ] \
      [ list "../src/core_gen/dbgcs_iconx3.vhd" $_VHDMod ] \
      [ list "../src/core_gen/dbgcs_sata_layer.vhd" $_VHDMod ] \
      [ list "../src/core_gen/dbgcs_sata_rambuf.vhd" $_VHDMod ] \
      [ list "../src/core_gen/dbgcs_sata_raid.vhd" $_VHDMod ] \
      [ list "../../../common/veresk_m/vereskm_pkg.vhd" $_VHDPkg ] \
      [ list "../../../common/veresk_m/video_pkt_filter.vhd" $_VHDMod ] \
      [ list "../../../common/veresk_m/dsn_timer.vhd" $_VHDMod ] \
      [ list "../../../common/veresk_m/dsn_switch.vhd" $_VHDMod ] \
      [ list "../../../common/veresk_m/dsn_host.vhd" $_VHDMod ] \
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
      [ list "../src/eth/physical/rocketio_wrapper_gtp_tile.vhd" $_VHDMod ] \
      [ list "../src/eth/physical/rocketio_wrapper_gtp.vhd" $_VHDMod ] \
      [ list "../src/eth/physical/gtp_dual_1000X.vhd" $_VHDMod ] \
      [ list "../src/eth/emac_core_locallink.vhd" $_VHDMod ] \
      [ list "../src/eth/emac_core_block.vhd" $_VHDMod ] \
      [ list "../src/eth/emac_core.vhd" $_VHDMod ] \
      [ list "../AD5T1_prj_cfg.vhd" $_VHDPkg ] \
      [ list "../../../common/veresk_m/vereskm_main.vhd" $_VHDMod ] \
      [ list "../../ucf/vereskm-5vlx110t-ffg1136.ucf" "vereskm_main" ] \
    ] \
  ] \
]

::projNav::makeProjects $_cwd $_usrdef_design $_usrdef_entity $_projects 10

#cd ../src
#exec "updata_ngc.bat"
