source "../../common/script/projnav.tcl"
#file mkdir "../ise/prj
cd ../ise/prj

set _cwd [pwd]
puts "Currunt PATH ${_cwd}"

set _usrdef_design "ml505_eth_udp"
set _usrdef_entity "eth_udp_main"
set _usrdef_xilinx_family "virtex5"
set _usrdef_chip_family "v5lxt"
set _usrdef_device "5vlx50t"
set _usrdef_speed  1
set _usrdef_pkg    "ff1136"
set _usrdef_ucf_filename "sgmii_main_v5"
set _usrdef_ucf_filepath "..\ucf\sgmii_main_v5.ucf"

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
      [ list "../../../common/lib/hw/eth/src/eth_pkg.vhd" $_VHDPkg ] \
      [ list "../../../common/lib/hw/eth/src/eth_unit_pkg.vhd" $_VHDPkg ] \
      [ list "../../../common/lib/hw/eth/src/eth_mdio.vhd" $_VHDMod ] \
      [ list "../../../common/lib/hw/eth/src/eth_ip.vhd" $_VHDMod ] \
      [ list "../src/eth/eth_app.vhd" $_VHDMod ] \
      [ list "../../../common/lib/hw/eth/src/eth_main.vhd" $_VHDMod ] \
      [ list "../../../common/lib/hw/eth/dsn_eth_pkg.vhd" $_VHDPkg ] \
      [ list "../src/eth/dsn_eth.vhd" $_VHDMod ] \
      [ list "../src/core_gen/host_ethg_txfifo.vhd" $_VHDMod ] \
      [ list "../src/eth/eth_phypin_pkg.vhd" $_VHDPkg ] \
      [ list "../src/eth/eth_phy.vhd" $_VHDMod ] \
      [ list "../src/eth/eth_mdio_main.vhd" $_VHDMod ] \
      [ list "../src/eth/eth_udp_main.vhd" $_VHDMod ] \
      [ list "../src/core_gen/emac_core_sgmii/example_design/client/fifo/tx_client_fifo_8.vhd" $_VHDMod ] \
      [ list "../src/core_gen/emac_core_sgmii/example_design/client/fifo/rx_client_fifo_8.vhd" $_VHDMod ] \
      [ list "../src/core_gen/emac_core_sgmii/example_design/client/fifo/eth_fifo_8.vhd" $_VHDMod ] \
      [ list "../src/core_gen/emac_core_sgmii/example_design/physical/gtp_dual_1000X.vhd" $_VHDMod ] \
      [ list "../src/core_gen/emac_core_sgmii/example_design/physical/rocketio_wrapper_gtp.vhd" $_VHDMod ] \
      [ list "../src/core_gen/emac_core_sgmii/example_design/physical/rocketio_wrapper_gtp_tile.vhd" $_VHDMod ] \
      [ list "../src/core_gen/emac_core_sgmii/example_design/physical/rx_elastic_buffer.vhd" $_VHDMod ] \
      [ list "../src/core_gen/emac_core_sgmii/example_design/emac_core_sgmii_locallink.vhd" $_VHDMod ] \
      [ list "../src/core_gen/emac_core_sgmii/example_design/emac_core_sgmii_block.vhd" $_VHDMod ] \
      [ list "../src/core_gen/emac_core_sgmii/example_design/emac_core_sgmii.vhd" $_VHDMod ] \
      [ list "../src/eth/v5/coregen_eth_phy_sgmii.vhd" $_VHDMod ] \
      [ list "../src/eth/v5/eth_gt_clkbuf_v5_sgmii.vhd" $_VHDMod ] \
      [ list "../src/eth/v5/ethphy_test_main_prj_cfg.vhd" $_VHDPkg ] \
      [ list "../../ucf/sgmii_main_v5.ucf" "eth_udp_main" ] \
    ] \
  ] \
]

::projNav::makeProjects $_cwd $_usrdef_design $_usrdef_entity $_projects 3

#cd ../src
#exec "updata_ngc.bat"
