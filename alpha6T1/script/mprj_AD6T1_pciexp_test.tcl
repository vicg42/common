source "../../common/script/projnav.tcl"
#file mkdir "../ise/prj
cd ../ise/prj

set _cwd [pwd]
puts "Currunt PATH ${_cwd}"

set _usrdef_design "AD6T1_pciexp_test"
set _usrdef_entity "pciexp_test_main"
set _usrdef_xilinx_family "virtex6"
set _usrdef_chip_family "v6lxt"
set _usrdef_device "6vlx240t"
set _usrdef_speed  1
set _usrdef_pkg    "ff1759"
set _usrdef_ucf_filename "AD6T1_pciexp_test"
set _usrdef_ucf_filepath "..\ucf\AD6T1_pciexp_test.ucf"

set _VMod $::projNav::VMod
set _VHDMod $::projNav::VHDMod
set _VHDPkg $::projNav::VHDPkg

set _projects [ list \
  [ list \
    $_usrdef_xilinx_family $_usrdef_device $_usrdef_pkg $_usrdef_speed xrc5t1 [ list \
      [ list "../../../common/hw/lib/vicg/vicg_common_pkg.vhd" $_VHDPkg ] \
      [ list "../../../common/veresk_m/prj_def.vhd" $_VHDPkg ] \
      [ list "../../../common/hw/timer/time_gen.vhd" $_VHDMod ] \
      [ list "../../../common/hw/testing/fpga_test_01.vhd" $_VHDMod ] \
      [ list "../../../common/hw/lib/alphadata/admxrc/vhdl/common/memif/memif_pkg.vhd" $_VHDPkg ] \
      [ list "../../../common/hw/lib/alphadata/admxrc/vhdl/common/localbus/plxdssm.vhd" $_VHDMod ] \
      [ list "../../../common/hw/lib/alphadata/admxrc/vhdl/common/localbus/localbus_pkg.vhd" $_VHDPkg ] \
      [ list "../../../common/hw/mem/alphadata/memory_ctrl_pkg.vhd" $_VHDMod ] \
      [ list "../../../common/veresk_m/alphadata/lbus_connector_32bit.vhd" $_VHDMod ] \
      [ list "../../../common/veresk_m/alphadata/lbus_connector_32bit_tst.vhd" $_VHDMod ] \
      [ list "../src/core_gen/bram_dma_params.vhd" $_VHDMod ] \
      [ list "../../../common/veresk_m/pci_express/v5/pciexp_main_v6.vhd" $_VHDMod ] \
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
      [ list "../src/core_gen/core_pciexp_ep_blk_plus/source/core_pciexp_ep_blk_plus.vhd" $_VHDMod ] \
      [ list "../src/core_gen/core_pciexp_ep_blk_plus/source/pcie_2_0_v6.vhd" $_VHDMod ] \
      [ list "../src/core_gen/core_pciexp_ep_blk_plus/source/pcie_upconfig_fix_3451_v6.vhd" $_VHDMod ] \
      [ list "../src/core_gen/core_pciexp_ep_blk_plus/source/gtx_drp_chanalign_fix_3752_v6.vhd" $_VHDMod ] \
      [ list "../src/core_gen/core_pciexp_ep_blk_plus/source/pcie_gtx_v6.vhd" $_VHDMod ] \
      [ list "../src/core_gen/core_pciexp_ep_blk_plus/source/gtx_wrapper_v6.vhd" $_VHDMod ] \
      [ list "../src/core_gen/core_pciexp_ep_blk_plus/source/gtx_tx_sync_rate_v6.vhd" $_VHDMod ] \
      [ list "../src/core_gen/core_pciexp_ep_blk_plus/source/gtx_rx_valid_filter_v6.vhd" $_VHDMod ] \
      [ list "../src/core_gen/core_pciexp_ep_blk_plus/source/pcie_bram_top_v6.vhd" $_VHDMod ] \
      [ list "../src/core_gen/core_pciexp_ep_blk_plus/source/pcie_brams_v6.vhd" $_VHDMod ] \
      [ list "../src/core_gen/core_pciexp_ep_blk_plus/source/pcie_bram_v6.vhd" $_VHDMod ] \
      [ list "../src/core_gen/core_pciexp_ep_blk_plus/source/pcie_clocking_v6.vhd" $_VHDMod ] \
      [ list "../src/core_gen/core_pciexp_ep_blk_plus/source/pcie_pipe_v6.vhd" $_VHDMod ] \
      [ list "../src/core_gen/core_pciexp_ep_blk_plus/source/pcie_pipe_lane_v6.vhd" $_VHDMod ] \
      [ list "../src/core_gen/core_pciexp_ep_blk_plus/source/pcie_pipe_misc_v6.vhd" $_VHDMod ] \
      [ list "../src/core_gen/core_pciexp_ep_blk_plus/source/pcie_reset_delay_v6.vhd" $_VHDMod ] \
      [ list "../src/core_gen/core_pciexp_ep_blk_plus/source/axi_basic_tx_thrtl_ctl.vhd" $_VHDMod ] \
      [ list "../src/core_gen/core_pciexp_ep_blk_plus/source/axi_basic_rx.vhd" $_VHDMod ] \
      [ list "../src/core_gen/core_pciexp_ep_blk_plus/source/axi_basic_rx_null_gen.vhd" $_VHDMod ] \
      [ list "../src/core_gen/core_pciexp_ep_blk_plus/source/axi_basic_rx_pipeline.vhd" $_VHDMod ] \
      [ list "../src/core_gen/core_pciexp_ep_blk_plus/source/axi_basic_tx.vhd" $_VHDMod ] \
      [ list "../src/core_gen/core_pciexp_ep_blk_plus/source/axi_basic_tx_pipeline.vhd" $_VHDMod ] \
      [ list "../src/core_gen/core_pciexp_ep_blk_plus/source/axi_basic_top.vhd" $_VHDMod ] \
      [ list "../../../common/veresk_m/vereskm_pkg.vhd" $_VHDPkg ] \
      [ list "../../../common/veresk_m/dsn_host.vhd" $_VHDMod ] \
      [ list "../AD6T1_pciexp_test_prj_cfg.vhd" $_VHDPkg ] \
      [ list "../../../ml505/ise/pciexp_test_main.vhd" $_VHDMod ] \
      [ list "../../ucf/AD6T1_pciexp_test.ucf" "pciexp_test_main" ] \
    ] \
  ] \
]

::projNav::makeProjects $_cwd $_usrdef_design $_usrdef_entity $_projects 10

#cd ../src
#exec "updata_ngc.bat"
