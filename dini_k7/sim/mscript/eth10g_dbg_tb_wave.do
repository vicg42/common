onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /eth10g_dbg_tb/reset
add wave -noupdate /eth10g_dbg_tb/resetdone
add wave -noupdate /eth10g_dbg_tb/m_eth/gen_use_on/m_main/m_phy/m_if/i_pma_sfp_signal_detect
add wave -noupdate /eth10g_dbg_tb/m_eth/gen_use_on/m_main/m_phy/m_if/i_pma_sfp_tx_fault
add wave -noupdate /eth10g_dbg_tb/m_eth/gen_use_on/m_main/m_phy/m_if/i_pma_sfp_tx_disable
add wave -noupdate -radix hexadecimal /eth10g_dbg_tb/m_eth/p_out_ethphy.rdy
add wave -noupdate -radix hexadecimal /eth10g_dbg_tb/m_eth/p_out_ethphy.link
add wave -noupdate /eth10g_dbg_tb/m_eth/gen_use_on/m_main/m_phy/m_if/i_pma_core_clk156_out
add wave -noupdate /eth10g_dbg_tb/m_eth/gen_use_on/m_main/m_phy/m_if/i_pma_clk156_mmcm_locked
add wave -noupdate -radix hexadecimal /eth10g_dbg_tb/m_eth/i_ethcfg
add wave -noupdate -radix hexadecimal -childformat {{/eth10g_dbg_tb/m_eth/p_out_ethphy.pin -radix hexadecimal} {/eth10g_dbg_tb/m_eth/p_out_ethphy.opt -radix hexadecimal} {/eth10g_dbg_tb/m_eth/p_out_ethphy.rdy -radix hexadecimal} {/eth10g_dbg_tb/m_eth/p_out_ethphy.link -radix hexadecimal} {/eth10g_dbg_tb/m_eth/p_out_ethphy.clk -radix hexadecimal} {/eth10g_dbg_tb/m_eth/p_out_ethphy.rst -radix hexadecimal} {/eth10g_dbg_tb/m_eth/p_out_ethphy.mdc -radix hexadecimal} {/eth10g_dbg_tb/m_eth/p_out_ethphy.mdio -radix hexadecimal} {/eth10g_dbg_tb/m_eth/p_out_ethphy.mdio_t -radix hexadecimal}} -subitemconfig {/eth10g_dbg_tb/m_eth/p_out_ethphy.pin {-height 15 -radix hexadecimal} /eth10g_dbg_tb/m_eth/p_out_ethphy.opt {-height 15 -radix hexadecimal} /eth10g_dbg_tb/m_eth/p_out_ethphy.rdy {-height 15 -radix hexadecimal} /eth10g_dbg_tb/m_eth/p_out_ethphy.link {-height 15 -radix hexadecimal} /eth10g_dbg_tb/m_eth/p_out_ethphy.clk {-height 15 -radix hexadecimal} /eth10g_dbg_tb/m_eth/p_out_ethphy.rst {-height 15 -radix hexadecimal} /eth10g_dbg_tb/m_eth/p_out_ethphy.mdc {-height 15 -radix hexadecimal} /eth10g_dbg_tb/m_eth/p_out_ethphy.mdio {-height 15 -radix hexadecimal} /eth10g_dbg_tb/m_eth/p_out_ethphy.mdio_t {-height 15 -radix hexadecimal}} /eth10g_dbg_tb/m_eth/p_out_ethphy
add wave -noupdate -radix hexadecimal /eth10g_dbg_tb/p_in_eth_htxbuf_di
add wave -noupdate /eth10g_dbg_tb/p_in_eth_htxbuf_wr
add wave -noupdate -radix hexadecimal -childformat {{/eth10g_dbg_tb/m_eth/p_out_eth(0) -radix hexadecimal -childformat {{/eth10g_dbg_tb/m_eth/p_out_eth(0).rxsof -radix hexadecimal} {/eth10g_dbg_tb/m_eth/p_out_eth(0).rxeof -radix hexadecimal} {/eth10g_dbg_tb/m_eth/p_out_eth(0).rxbuf_di -radix hexadecimal} {/eth10g_dbg_tb/m_eth/p_out_eth(0).rxbuf_wr -radix hexadecimal} {/eth10g_dbg_tb/m_eth/p_out_eth(0).txbuf_rd -radix hexadecimal}}}} -subitemconfig {/eth10g_dbg_tb/m_eth/p_out_eth(0) {-height 15 -radix hexadecimal -childformat {{/eth10g_dbg_tb/m_eth/p_out_eth(0).rxsof -radix hexadecimal} {/eth10g_dbg_tb/m_eth/p_out_eth(0).rxeof -radix hexadecimal} {/eth10g_dbg_tb/m_eth/p_out_eth(0).rxbuf_di -radix hexadecimal} {/eth10g_dbg_tb/m_eth/p_out_eth(0).rxbuf_wr -radix hexadecimal} {/eth10g_dbg_tb/m_eth/p_out_eth(0).txbuf_rd -radix hexadecimal}} -expand} /eth10g_dbg_tb/m_eth/p_out_eth(0).rxsof {-height 15 -radix hexadecimal} /eth10g_dbg_tb/m_eth/p_out_eth(0).rxeof {-height 15 -radix hexadecimal} /eth10g_dbg_tb/m_eth/p_out_eth(0).rxbuf_di {-height 15 -radix hexadecimal} /eth10g_dbg_tb/m_eth/p_out_eth(0).rxbuf_wr {-height 15 -radix hexadecimal} /eth10g_dbg_tb/m_eth/p_out_eth(0).txbuf_rd {-height 15 -radix hexadecimal}} /eth10g_dbg_tb/m_eth/p_out_eth
add wave -noupdate -radix hexadecimal -childformat {{/eth10g_dbg_tb/m_eth/p_in_eth(0) -radix hexadecimal -childformat {{/eth10g_dbg_tb/m_eth/p_in_eth(0).txbuf_do -radix hexadecimal} {/eth10g_dbg_tb/m_eth/p_in_eth(0).txbuf_full -radix hexadecimal} {/eth10g_dbg_tb/m_eth/p_in_eth(0).txbuf_empty -radix hexadecimal} {/eth10g_dbg_tb/m_eth/p_in_eth(0).rxbuf_full -radix hexadecimal} {/eth10g_dbg_tb/m_eth/p_in_eth(0).rxbuf_empty -radix hexadecimal}}}} -subitemconfig {/eth10g_dbg_tb/m_eth/p_in_eth(0) {-height 15 -radix hexadecimal -childformat {{/eth10g_dbg_tb/m_eth/p_in_eth(0).txbuf_do -radix hexadecimal} {/eth10g_dbg_tb/m_eth/p_in_eth(0).txbuf_full -radix hexadecimal} {/eth10g_dbg_tb/m_eth/p_in_eth(0).txbuf_empty -radix hexadecimal} {/eth10g_dbg_tb/m_eth/p_in_eth(0).rxbuf_full -radix hexadecimal} {/eth10g_dbg_tb/m_eth/p_in_eth(0).rxbuf_empty -radix hexadecimal}} -expand} /eth10g_dbg_tb/m_eth/p_in_eth(0).txbuf_do {-height 15 -radix hexadecimal} /eth10g_dbg_tb/m_eth/p_in_eth(0).txbuf_full {-height 15 -radix hexadecimal} /eth10g_dbg_tb/m_eth/p_in_eth(0).txbuf_empty {-height 15 -radix hexadecimal} /eth10g_dbg_tb/m_eth/p_in_eth(0).rxbuf_full {-height 15 -radix hexadecimal} /eth10g_dbg_tb/m_eth/p_in_eth(0).rxbuf_empty {-height 15 -radix hexadecimal}} /eth10g_dbg_tb/m_eth/p_in_eth
add wave -noupdate /eth10g_dbg_tb/m_eth/gen_use_on/m_main/m_app/gen_ch(0)/m_mac_tx/fsm_eth_tx_cs
add wave -noupdate -radix hexadecimal /eth10g_dbg_tb/m_eth/gen_use_on/m_main/m_app/gen_ch(0)/m_mac_tx/i_usrpkt_len_byte
add wave -noupdate -radix hexadecimal /eth10g_dbg_tb/m_eth/gen_use_on/m_main/m_app/gen_ch(0)/m_mac_tx/i_mac_dlen_byte
add wave -noupdate -radix hexadecimal /eth10g_dbg_tb/m_eth/gen_use_on/m_main/m_app/gen_ch(0)/m_mac_tx/i_mac_pkt_len_byte
add wave -noupdate -radix hexadecimal /eth10g_dbg_tb/m_eth/gen_use_on/m_main/m_app/gen_ch(0)/m_mac_tx/i_remain
add wave -noupdate -radix hexadecimal /eth10g_dbg_tb/m_eth/gen_use_on/m_main/m_app/gen_ch(0)/m_mac_tx/i_dcnt
add wave -noupdate /eth10g_dbg_tb/m_eth/gen_use_on/m_main/m_app/gen_ch(0)/m_mac_tx/sr_txbuf_dout
add wave -noupdate -radix hexadecimal /eth10g_dbg_tb/m_eth/gen_use_on/m_main/m_app/gen_ch(0)/m_mac_tx/p_in_txbuf_dout
add wave -noupdate -radix hexadecimal /eth10g_dbg_tb/m_eth/gen_use_on/m_main/m_app/gen_ch(0)/m_mac_tx/p_out_txbuf_rd
add wave -noupdate /eth10g_dbg_tb/m_eth/gen_use_on/m_main/m_app/gen_ch(0)/m_mac_tx/p_in_txbuf_empty
add wave -noupdate -radix hexadecimal /eth10g_dbg_tb/m_eth/gen_use_on/m_main/m_phy/m_if/i_tx_axis_tdata
add wave -noupdate -radix hexadecimal /eth10g_dbg_tb/m_eth/gen_use_on/m_main/m_phy/m_if/i_tx_axis_tkeep
add wave -noupdate -radix hexadecimal /eth10g_dbg_tb/m_eth/gen_use_on/m_main/m_phy/m_if/i_tx_axis_tvalid
add wave -noupdate -radix hexadecimal /eth10g_dbg_tb/m_eth/gen_use_on/m_main/m_phy/m_if/i_tx_axis_tlast
add wave -noupdate -radix hexadecimal /eth10g_dbg_tb/m_eth/gen_use_on/m_main/m_phy/m_if/i_tx_axis_tready
add wave -noupdate -radix hexadecimal /eth10g_dbg_tb/m_eth/gen_use_on/m_main/m_phy/m_if/i_tx_axis_tuser
add wave -noupdate -radix hexadecimal /eth10g_dbg_tb/m_eth/gen_use_on/m_main/m_phy/m_if/i_rx_axis_tdata
add wave -noupdate -radix hexadecimal /eth10g_dbg_tb/m_eth/gen_use_on/m_main/m_phy/m_if/i_rx_axis_tkeep
add wave -noupdate -radix hexadecimal /eth10g_dbg_tb/m_eth/gen_use_on/m_main/m_phy/m_if/i_rx_axis_tvalid
add wave -noupdate -radix hexadecimal /eth10g_dbg_tb/m_eth/gen_use_on/m_main/m_phy/m_if/i_rx_axis_tlast
add wave -noupdate -radix hexadecimal /eth10g_dbg_tb/m_eth/gen_use_on/m_main/m_phy/m_if/i_rx_axis_tready
add wave -noupdate /eth10g_dbg_tb/m_eth/gen_use_on/m_main/m_phy/m_if/xgmii_tx_clk
add wave -noupdate -radix hexadecimal /eth10g_dbg_tb/m_eth/gen_use_on/m_main/m_phy/m_if/xgmii_txd
add wave -noupdate -radix hexadecimal /eth10g_dbg_tb/m_eth/gen_use_on/m_main/m_phy/m_if/xgmii_txc
add wave -noupdate -radix hexadecimal /eth10g_dbg_tb/m_eth/gen_use_on/m_main/m_phy/m_if/xgmii_rx_clk
add wave -noupdate -radix hexadecimal /eth10g_dbg_tb/m_eth/gen_use_on/m_main/m_phy/m_if/xgmii_rxd
add wave -noupdate -radix hexadecimal /eth10g_dbg_tb/m_eth/gen_use_on/m_main/m_phy/m_if/xgmii_rxc
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {0 ps} 0}
configure wave -namecolwidth 232
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
WaveRestoreZoom {10342033 ps} {10409180 ps}
