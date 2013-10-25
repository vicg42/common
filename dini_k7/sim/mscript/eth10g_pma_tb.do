vlib work
vmap work work
vcom -work work ../../ise/src/core_gen/eth10g_pma_core.vhd
vcom -work work ../../ise/src/core_gen/eth10g_pma_core/example_design/gtx/eth10g_pma_core_gt_usrclk_source.vhd
vcom -work work ../../ise/src/core_gen/eth10g_pma_core/example_design/gtx/eth10g_pma_core_gtwizard_10gbaser.vhd
vcom -work work ../../ise/src/core_gen/eth10g_pma_core/example_design/gtx/eth10g_pma_core_gtwizard_10gbaser_gt.vhd
vcom -work work ../../ise/src/core_gen/eth10g_pma_core/example_design/eth10g_pma_core_example_design.vhd
vcom -work work ../../ise/src/eth/eth10g_pma_core_block.vhd
vcom -work work ../../ise/src/eth/eth10g_pma.vhd
vcom -work work ../testbanch/eth10g_pma_tb.vhd

vsim -t ps work.eth10g_pma_tb -voptargs="+acc"
do eth10g_pma_tb_wave.do
run -all
