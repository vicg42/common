vlib work
vmap work work

vcom -work work ../../../common/lib/hw/lib/vicg/vicg_common_pkg.vhd
vcom -work work ../../../dini_k7/ise/eth10g_dbg_prj_cfg.vhd
vcom -work work ../../../common/prj_def.vhd

vcom -work work ../../ise/src/eth/eth_phypin_pkg.vhd

vcom -work work ../../../common/lib/hw/eth/src/eth_pkg.vhd
vcom -work work ../../../common/lib/hw/eth/src/eth_unit_pkg.vhd
vcom -work work ../../../common/lib/hw/eth/src/eth_mac_rx_64b.vhd
vcom -work work ../../../common/lib/hw/eth/src/eth_mac_tx_64b.vhd
vcom -work work ../../../common/lib/hw/eth/src/eth_app.vhd
vcom -work work ../../../common/lib/hw/eth/src/eth_main.vhd
vcom -work work ../../../common/lib/hw/eth/dsn_eth_pkg.vhd
vcom -work work ../../../common/lib/hw/eth/dsn_eth.vhd

vcom -work work ../../ise/src/eth/eth_phy.vhd
vcom -work work ../../ise/src/eth/eth10g_fiber_core.vhd

vcom -work work ../../ise/src/core_gen/eth10g_mac_core.vhd
vcom -work work ../../ise/src/core_gen/eth10g_mac_core/example_design/fifo/xgmac_fifo_pack.vhd
vcom -work work ../../ise/src/core_gen/eth10g_mac_core/example_design/fifo/eth10g_mac_core_fifo_ram.vhd
vcom -work work ../../ise/src/core_gen/eth10g_mac_core/example_design/fifo/eth10g_mac_core_axi_fifo.vhd
vcom -work work ../../ise/src/core_gen/eth10g_mac_core/example_design/fifo/eth10g_mac_core_xgmac_fifo.vhd
#vcom -work work ../../ise/src/core_gen/eth10g_mac_core/example_design/eth10g_mac_core_address_swap.vhd
vcom -work work ../../ise/src/eth/eth10g_mac_core_physical_if.vhd
vcom -work work ../../ise/src/core_gen/eth10g_mac_core/example_design/eth10g_mac_core_block.vhd
vcom -work work ../../ise/src/core_gen/eth10g_mac_core/example_design/eth10g_mac_core_fifo_block.vhd
vcom -work work ../../ise/src/eth/eth10g_mac.vhd

vcom -work work ../../ise/src/core_gen/eth10g_pma_core.vhd
vcom -work work ../../ise/src/core_gen/eth10g_pma_core/example_design/gtx/eth10g_pma_core_gt_usrclk_source.vhd
vcom -work work ../../ise/src/core_gen/eth10g_pma_core/example_design/gtx/eth10g_pma_core_gtwizard_10gbaser.vhd
vcom -work work ../../ise/src/core_gen/eth10g_pma_core/example_design/gtx/eth10g_pma_core_gtwizard_10gbaser_gt.vhd
vcom -work work ../../ise/src/core_gen/eth10g_pma_core/example_design/eth10g_pma_core_example_design.vhd
vcom -work work ../../ise/src/eth/eth10g_pma_core_block.vhd
vcom -work work ../../ise/src/eth/eth10g_pma.vhd

vcom -work work ../../ise/src/core_gen/host_ethg_txfifo_sim.vhd

vcom -work work ../testbanch/eth10g_dbg_tb.vhd

#vsim -t ps work.eth10g_dbg_tb -voptargs="+acc+/eth10g_dbg_tb/m_eth/gen_use_on.m_main/m_phy/m_if/m_mac/fifo_block_i/xgmac_block"
vsim -t ps work.eth10g_dbg_tb -voptargs="+acc"
#vsim -t ps work.eth10g_dbg_tb
do eth10g_dbg_tb_wave.do
run 100 ps;

