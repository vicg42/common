vlib work
vmap work work
vcom -work work ../../ise/src/core_gen/eth10g_mac_core.vhd
vcom -work work ../../ise/src/core_gen/eth10g_mac_core/example_design/fifo/xgmac_fifo_pack.vhd
vcom -work work ../../ise/src/core_gen/eth10g_mac_core/example_design/fifo/eth10g_mac_core_fifo_ram.vhd
vcom -work work ../../ise/src/core_gen/eth10g_mac_core/example_design/fifo/eth10g_mac_core_axi_fifo.vhd
vcom -work work ../../ise/src/core_gen/eth10g_mac_core/example_design/fifo/eth10g_mac_core_xgmac_fifo.vhd
vcom -work work ../../ise/src/core_gen/eth10g_mac_core/example_design/eth10g_mac_core_address_swap.vhd
vcom -work work ../../ise/src/eth/eth10g_mac_core_physical_if.vhd
vcom -work work ../../ise/src/core_gen/eth10g_mac_core/example_design/eth10g_mac_core_block.vhd
vcom -work work ../../ise/src/core_gen/eth10g_mac_core/example_design/eth10g_mac_core_fifo_block.vhd
vcom -work work ../../ise/src/eth/eth10g_mac.vhd

vcom -work work ../testbanch/eth10g_mac_tb.vhd
vsim -gfunc_sim=true -t ps work.eth10g_mac_tb -voptargs="+acc+eth10g_mac_tb+/eth10g_mac_tb/dut/fifo_block_i/xgmac_block"
do eth10g_mac_tb_wave.do
run -all
