onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -divider {System Signals}
add wave -noupdate /eth10g_mac_tb/reset
add wave -noupdate /eth10g_mac_tb/gtx_clk
add wave -noupdate -divider {TX Client Interface}
add wave -noupdate -radix binary /eth10g_mac_tb/dut/fifo_block_i/xgmac_block/tx_axis_aresetn
add wave -noupdate -radix hexadecimal /eth10g_mac_tb/dut/fifo_block_i/xgmac_block/tx_axis_tdata
add wave -noupdate /eth10g_mac_tb/dut/fifo_block_i/xgmac_block/tx_axis_tvalid
add wave -noupdate /eth10g_mac_tb/dut/fifo_block_i/xgmac_block/tx_axis_tlast
add wave -noupdate -radix hexadecimal /eth10g_mac_tb/dut/fifo_block_i/xgmac_block/tx_axis_tkeep
add wave -noupdate /eth10g_mac_tb/dut/fifo_block_i/xgmac_block/tx_axis_tuser
add wave -noupdate /eth10g_mac_tb/dut/fifo_block_i/xgmac_block/tx_axis_tready
add wave -noupdate -radix hexadecimal /eth10g_mac_tb/tx_ifg_delay
add wave -noupdate -divider {TX Statistics Vector}
add wave -noupdate -radix binary /eth10g_mac_tb/tx_statistics_vector
add wave -noupdate /eth10g_mac_tb/tx_statistics_valid
add wave -noupdate -divider {RX Client Interface}
add wave -noupdate -radix binary /eth10g_mac_tb/dut/fifo_block_i/xgmac_block/rx_axis_aresetn
add wave -noupdate -radix hexadecimal /eth10g_mac_tb/dut/fifo_block_i/xgmac_block/rx_axis_tdata
add wave -noupdate -radix hexadecimal /eth10g_mac_tb/dut/fifo_block_i/xgmac_block/rx_axis_tkeep
add wave -noupdate /eth10g_mac_tb/dut/fifo_block_i/xgmac_block/rx_axis_tvalid
add wave -noupdate /eth10g_mac_tb/dut/fifo_block_i/xgmac_block/rx_axis_tuser
add wave -noupdate /eth10g_mac_tb/dut/fifo_block_i/xgmac_block/rx_axis_tlast
add wave -noupdate -divider {RX Statistics Vector}
add wave -noupdate -radix binary /eth10g_mac_tb/rx_statistics_vector
add wave -noupdate /eth10g_mac_tb/rx_statistics_valid
add wave -noupdate -divider {Flow Control}
add wave -noupdate -radix hexadecimal /eth10g_mac_tb/pause_val
add wave -noupdate /eth10g_mac_tb/pause_req
add wave -noupdate -divider {TX PHY Interface}
add wave -noupdate /eth10g_mac_tb/xgmii_tx_clk
add wave -noupdate -radix hexadecimal /eth10g_mac_tb/xgmii_txd
add wave -noupdate -radix binary /eth10g_mac_tb/xgmii_txc
add wave -noupdate -divider {RX PHY Interface}
add wave -noupdate /eth10g_mac_tb/xgmii_rx_clk
add wave -noupdate -radix hexadecimal /eth10g_mac_tb/xgmii_rxd
add wave -noupdate -radix binary /eth10g_mac_tb/xgmii_rxc
add wave -noupdate -divider {Management Interface}
add wave -noupdate -radix binary /eth10g_mac_tb/tx_configuration_vector
add wave -noupdate -radix binary /eth10g_mac_tb/rx_configuration_vector
add wave -noupdate -radix binary /eth10g_mac_tb/status_vector
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {0 ps} 0}
configure wave -namecolwidth 154
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 1
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ps
update
WaveRestoreZoom {846605 ps} {1283437 ps}
