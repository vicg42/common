## NOTE:  Do not edit this file.
## Autogenerated by ProjNav (creatfdo.tcl) on Mon Jan 26 12:17:18 ���������� ����� (����) 2009
##
vlib work

vcom -93 "../../../lib/vicg/reduce_pack.vhd"
vcom -93 "../../../lib/vicg/vicg_common_pkg.vhd"

#vcom -93 "../../../uart/src/bbfifo_16x8.vhd"
#vcom -93 "../../../uart/src/kcuart_rx.vhd"
#vcom -93 "../../../uart/src/kcuart_tx.vhd"
#vcom -93 "../../../uart/src/uart_rx.vhd"
#vcom -93 "../../../uart/src/uart_tx.vhd"
#vcom -93 "../../../uart/uart_main_rev01.vhd"

vcom -93 "../../cfgdev2_pkg.vhd"
vcom -93 "../../cfgdev2_host.vhd"
vcom -93 "../../core_gen/cfgdev_fifo8bx8b.vhd"
vcom -93 "../../core_gen/cfgdev_fifo16bx16b.vhd"
vcom -93 "../../core_gen/cfgdev_fifo32bx32b.vhd"
vcom -93 "../../core_gen/cfgdev_fifo64bx64b.vhd"
vcom -93 "../../core_gen/cfgdev_fifo128bx128b.vhd"

vcom -93 "../testbanch/cfgdev_buf.vhd"
vcom -93 "../testbanch/cfgdev2_host_tb.vhd"

vsim -t 1ps   -lib work cfgdev_host_tb
do cfgdev2_host_tb_wave.do
view wave
view structure
view signals
run 1000ns

