onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /eth_mac_tb/i_rst
add wave -noupdate -divider ETH_TX
add wave -noupdate -radix hexadecimal /eth_mac_tb/m_tx/p_in_txbuf_dout
add wave -noupdate -radix hexadecimal /eth_mac_tb/m_tx/p_out_txbuf_rd
add wave -noupdate -radix hexadecimal /eth_mac_tb/m_tx/p_in_txbuf_empty
add wave -noupdate -color {Cornflower Blue} -itemcolor Gold /eth_mac_tb/m_tx/fsm_eth_tx_cs
add wave -noupdate -radix hexadecimal /eth_mac_tb/m_tx/i_pkt_len
add wave -noupdate -radix hexadecimal /eth_mac_tb/m_tx/i_bcnt
add wave -noupdate -radix hexadecimal /eth_mac_tb/m_tx/i_dcnt
add wave -noupdate -radix hexadecimal /eth_mac_tb/m_tx/p_out_txll_data
add wave -noupdate /eth_mac_tb/m_tx/p_out_txll_rem
add wave -noupdate -radix hexadecimal /eth_mac_tb/m_tx/p_out_txll_sof_n
add wave -noupdate -radix hexadecimal /eth_mac_tb/m_tx/p_out_txll_eof_n
add wave -noupdate -radix hexadecimal /eth_mac_tb/m_tx/p_out_txll_src_rdy_n
add wave -noupdate /eth_mac_tb/m_tx/p_in_txll_dst_rdy_n
add wave -noupdate -divider ET_RX
add wave -noupdate -radix hexadecimal /eth_mac_tb/m_rx/p_in_rxll_data
add wave -noupdate /eth_mac_tb/m_rx/p_in_rxll_sof_n
add wave -noupdate /eth_mac_tb/m_rx/p_in_rxll_eof_n
add wave -noupdate /eth_mac_tb/m_rx/p_in_rxll_src_rdy_n
add wave -noupdate /eth_mac_tb/m_rx/p_out_rxll_dst_rdy_n
add wave -noupdate -color {Cornflower Blue} -itemcolor Gold /eth_mac_tb/m_rx/fsm_eth_rx_cs
add wave -noupdate -radix hexadecimal /eth_mac_tb/m_rx/i_bcnt
add wave -noupdate -radix hexadecimal /eth_mac_tb/m_rx/i_dcnt
add wave -noupdate -radix hexadecimal -childformat {{/eth_mac_tb/m_rx/i_rx_mac.dst -radix hexadecimal -childformat {{/eth_mac_tb/m_rx/i_rx_mac.dst(0) -radix hexadecimal -childformat {{/eth_mac_tb/m_rx/i_rx_mac.dst(0)(7) -radix hexadecimal} {/eth_mac_tb/m_rx/i_rx_mac.dst(0)(6) -radix hexadecimal} {/eth_mac_tb/m_rx/i_rx_mac.dst(0)(5) -radix hexadecimal} {/eth_mac_tb/m_rx/i_rx_mac.dst(0)(4) -radix hexadecimal} {/eth_mac_tb/m_rx/i_rx_mac.dst(0)(3) -radix hexadecimal} {/eth_mac_tb/m_rx/i_rx_mac.dst(0)(2) -radix hexadecimal} {/eth_mac_tb/m_rx/i_rx_mac.dst(0)(1) -radix hexadecimal} {/eth_mac_tb/m_rx/i_rx_mac.dst(0)(0) -radix hexadecimal}}} {/eth_mac_tb/m_rx/i_rx_mac.dst(1) -radix hexadecimal} {/eth_mac_tb/m_rx/i_rx_mac.dst(2) -radix hexadecimal} {/eth_mac_tb/m_rx/i_rx_mac.dst(3) -radix hexadecimal} {/eth_mac_tb/m_rx/i_rx_mac.dst(4) -radix hexadecimal} {/eth_mac_tb/m_rx/i_rx_mac.dst(5) -radix hexadecimal}}} {/eth_mac_tb/m_rx/i_rx_mac.src -radix hexadecimal -childformat {{/eth_mac_tb/m_rx/i_rx_mac.src(0) -radix hexadecimal} {/eth_mac_tb/m_rx/i_rx_mac.src(1) -radix hexadecimal} {/eth_mac_tb/m_rx/i_rx_mac.src(2) -radix hexadecimal} {/eth_mac_tb/m_rx/i_rx_mac.src(3) -radix hexadecimal} {/eth_mac_tb/m_rx/i_rx_mac.src(4) -radix hexadecimal} {/eth_mac_tb/m_rx/i_rx_mac.src(5) -radix hexadecimal}}} {/eth_mac_tb/m_rx/i_rx_mac.lentype -radix hexadecimal -childformat {{/eth_mac_tb/m_rx/i_rx_mac.lentype(15) -radix hexadecimal} {/eth_mac_tb/m_rx/i_rx_mac.lentype(14) -radix hexadecimal} {/eth_mac_tb/m_rx/i_rx_mac.lentype(13) -radix hexadecimal} {/eth_mac_tb/m_rx/i_rx_mac.lentype(12) -radix hexadecimal} {/eth_mac_tb/m_rx/i_rx_mac.lentype(11) -radix hexadecimal} {/eth_mac_tb/m_rx/i_rx_mac.lentype(10) -radix hexadecimal} {/eth_mac_tb/m_rx/i_rx_mac.lentype(9) -radix hexadecimal} {/eth_mac_tb/m_rx/i_rx_mac.lentype(8) -radix hexadecimal} {/eth_mac_tb/m_rx/i_rx_mac.lentype(7) -radix hexadecimal} {/eth_mac_tb/m_rx/i_rx_mac.lentype(6) -radix hexadecimal} {/eth_mac_tb/m_rx/i_rx_mac.lentype(5) -radix hexadecimal} {/eth_mac_tb/m_rx/i_rx_mac.lentype(4) -radix hexadecimal} {/eth_mac_tb/m_rx/i_rx_mac.lentype(3) -radix hexadecimal} {/eth_mac_tb/m_rx/i_rx_mac.lentype(2) -radix hexadecimal} {/eth_mac_tb/m_rx/i_rx_mac.lentype(1) -radix hexadecimal} {/eth_mac_tb/m_rx/i_rx_mac.lentype(0) -radix hexadecimal}}}} -expand -subitemconfig {/eth_mac_tb/m_rx/i_rx_mac.dst {-height 15 -radix hexadecimal -childformat {{/eth_mac_tb/m_rx/i_rx_mac.dst(0) -radix hexadecimal -childformat {{/eth_mac_tb/m_rx/i_rx_mac.dst(0)(7) -radix hexadecimal} {/eth_mac_tb/m_rx/i_rx_mac.dst(0)(6) -radix hexadecimal} {/eth_mac_tb/m_rx/i_rx_mac.dst(0)(5) -radix hexadecimal} {/eth_mac_tb/m_rx/i_rx_mac.dst(0)(4) -radix hexadecimal} {/eth_mac_tb/m_rx/i_rx_mac.dst(0)(3) -radix hexadecimal} {/eth_mac_tb/m_rx/i_rx_mac.dst(0)(2) -radix hexadecimal} {/eth_mac_tb/m_rx/i_rx_mac.dst(0)(1) -radix hexadecimal} {/eth_mac_tb/m_rx/i_rx_mac.dst(0)(0) -radix hexadecimal}}} {/eth_mac_tb/m_rx/i_rx_mac.dst(1) -radix hexadecimal} {/eth_mac_tb/m_rx/i_rx_mac.dst(2) -radix hexadecimal} {/eth_mac_tb/m_rx/i_rx_mac.dst(3) -radix hexadecimal} {/eth_mac_tb/m_rx/i_rx_mac.dst(4) -radix hexadecimal} {/eth_mac_tb/m_rx/i_rx_mac.dst(5) -radix hexadecimal}}} /eth_mac_tb/m_rx/i_rx_mac.dst(0) {-height 15 -radix hexadecimal -childformat {{/eth_mac_tb/m_rx/i_rx_mac.dst(0)(7) -radix hexadecimal} {/eth_mac_tb/m_rx/i_rx_mac.dst(0)(6) -radix hexadecimal} {/eth_mac_tb/m_rx/i_rx_mac.dst(0)(5) -radix hexadecimal} {/eth_mac_tb/m_rx/i_rx_mac.dst(0)(4) -radix hexadecimal} {/eth_mac_tb/m_rx/i_rx_mac.dst(0)(3) -radix hexadecimal} {/eth_mac_tb/m_rx/i_rx_mac.dst(0)(2) -radix hexadecimal} {/eth_mac_tb/m_rx/i_rx_mac.dst(0)(1) -radix hexadecimal} {/eth_mac_tb/m_rx/i_rx_mac.dst(0)(0) -radix hexadecimal}}} /eth_mac_tb/m_rx/i_rx_mac.dst(0)(7) {-height 15 -radix hexadecimal} /eth_mac_tb/m_rx/i_rx_mac.dst(0)(6) {-height 15 -radix hexadecimal} /eth_mac_tb/m_rx/i_rx_mac.dst(0)(5) {-height 15 -radix hexadecimal} /eth_mac_tb/m_rx/i_rx_mac.dst(0)(4) {-height 15 -radix hexadecimal} /eth_mac_tb/m_rx/i_rx_mac.dst(0)(3) {-height 15 -radix hexadecimal} /eth_mac_tb/m_rx/i_rx_mac.dst(0)(2) {-height 15 -radix hexadecimal} /eth_mac_tb/m_rx/i_rx_mac.dst(0)(1) {-height 15 -radix hexadecimal} /eth_mac_tb/m_rx/i_rx_mac.dst(0)(0) {-height 15 -radix hexadecimal} /eth_mac_tb/m_rx/i_rx_mac.dst(1) {-height 15 -radix hexadecimal} /eth_mac_tb/m_rx/i_rx_mac.dst(2) {-height 15 -radix hexadecimal} /eth_mac_tb/m_rx/i_rx_mac.dst(3) {-height 15 -radix hexadecimal} /eth_mac_tb/m_rx/i_rx_mac.dst(4) {-height 15 -radix hexadecimal} /eth_mac_tb/m_rx/i_rx_mac.dst(5) {-height 15 -radix hexadecimal} /eth_mac_tb/m_rx/i_rx_mac.src {-height 15 -radix hexadecimal -childformat {{/eth_mac_tb/m_rx/i_rx_mac.src(0) -radix hexadecimal} {/eth_mac_tb/m_rx/i_rx_mac.src(1) -radix hexadecimal} {/eth_mac_tb/m_rx/i_rx_mac.src(2) -radix hexadecimal} {/eth_mac_tb/m_rx/i_rx_mac.src(3) -radix hexadecimal} {/eth_mac_tb/m_rx/i_rx_mac.src(4) -radix hexadecimal} {/eth_mac_tb/m_rx/i_rx_mac.src(5) -radix hexadecimal}}} /eth_mac_tb/m_rx/i_rx_mac.src(0) {-height 15 -radix hexadecimal} /eth_mac_tb/m_rx/i_rx_mac.src(1) {-height 15 -radix hexadecimal} /eth_mac_tb/m_rx/i_rx_mac.src(2) {-height 15 -radix hexadecimal} /eth_mac_tb/m_rx/i_rx_mac.src(3) {-height 15 -radix hexadecimal} /eth_mac_tb/m_rx/i_rx_mac.src(4) {-height 15 -radix hexadecimal} /eth_mac_tb/m_rx/i_rx_mac.src(5) {-height 15 -radix hexadecimal} /eth_mac_tb/m_rx/i_rx_mac.lentype {-height 15 -radix hexadecimal -childformat {{/eth_mac_tb/m_rx/i_rx_mac.lentype(15) -radix hexadecimal} {/eth_mac_tb/m_rx/i_rx_mac.lentype(14) -radix hexadecimal} {/eth_mac_tb/m_rx/i_rx_mac.lentype(13) -radix hexadecimal} {/eth_mac_tb/m_rx/i_rx_mac.lentype(12) -radix hexadecimal} {/eth_mac_tb/m_rx/i_rx_mac.lentype(11) -radix hexadecimal} {/eth_mac_tb/m_rx/i_rx_mac.lentype(10) -radix hexadecimal} {/eth_mac_tb/m_rx/i_rx_mac.lentype(9) -radix hexadecimal} {/eth_mac_tb/m_rx/i_rx_mac.lentype(8) -radix hexadecimal} {/eth_mac_tb/m_rx/i_rx_mac.lentype(7) -radix hexadecimal} {/eth_mac_tb/m_rx/i_rx_mac.lentype(6) -radix hexadecimal} {/eth_mac_tb/m_rx/i_rx_mac.lentype(5) -radix hexadecimal} {/eth_mac_tb/m_rx/i_rx_mac.lentype(4) -radix hexadecimal} {/eth_mac_tb/m_rx/i_rx_mac.lentype(3) -radix hexadecimal} {/eth_mac_tb/m_rx/i_rx_mac.lentype(2) -radix hexadecimal} {/eth_mac_tb/m_rx/i_rx_mac.lentype(1) -radix hexadecimal} {/eth_mac_tb/m_rx/i_rx_mac.lentype(0) -radix hexadecimal}}} /eth_mac_tb/m_rx/i_rx_mac.lentype(15) {-height 15 -radix hexadecimal} /eth_mac_tb/m_rx/i_rx_mac.lentype(14) {-height 15 -radix hexadecimal} /eth_mac_tb/m_rx/i_rx_mac.lentype(13) {-height 15 -radix hexadecimal} /eth_mac_tb/m_rx/i_rx_mac.lentype(12) {-height 15 -radix hexadecimal} /eth_mac_tb/m_rx/i_rx_mac.lentype(11) {-height 15 -radix hexadecimal} /eth_mac_tb/m_rx/i_rx_mac.lentype(10) {-height 15 -radix hexadecimal} /eth_mac_tb/m_rx/i_rx_mac.lentype(9) {-height 15 -radix hexadecimal} /eth_mac_tb/m_rx/i_rx_mac.lentype(8) {-height 15 -radix hexadecimal} /eth_mac_tb/m_rx/i_rx_mac.lentype(7) {-height 15 -radix hexadecimal} /eth_mac_tb/m_rx/i_rx_mac.lentype(6) {-height 15 -radix hexadecimal} /eth_mac_tb/m_rx/i_rx_mac.lentype(5) {-height 15 -radix hexadecimal} /eth_mac_tb/m_rx/i_rx_mac.lentype(4) {-height 15 -radix hexadecimal} /eth_mac_tb/m_rx/i_rx_mac.lentype(3) {-height 15 -radix hexadecimal} /eth_mac_tb/m_rx/i_rx_mac.lentype(2) {-height 15 -radix hexadecimal} /eth_mac_tb/m_rx/i_rx_mac.lentype(1) {-height 15 -radix hexadecimal} /eth_mac_tb/m_rx/i_rx_mac.lentype(0) {-height 15 -radix hexadecimal}} /eth_mac_tb/m_rx/i_rx_mac
add wave -noupdate -radix hexadecimal /eth_mac_tb/m_rx/i_pkt_len
add wave -noupdate -radix hexadecimal -childformat {{/eth_mac_tb/m_rx/i_pkt_lentotal_byte(15) -radix hexadecimal} {/eth_mac_tb/m_rx/i_pkt_lentotal_byte(14) -radix hexadecimal} {/eth_mac_tb/m_rx/i_pkt_lentotal_byte(13) -radix hexadecimal} {/eth_mac_tb/m_rx/i_pkt_lentotal_byte(12) -radix hexadecimal} {/eth_mac_tb/m_rx/i_pkt_lentotal_byte(11) -radix hexadecimal} {/eth_mac_tb/m_rx/i_pkt_lentotal_byte(10) -radix hexadecimal} {/eth_mac_tb/m_rx/i_pkt_lentotal_byte(9) -radix hexadecimal} {/eth_mac_tb/m_rx/i_pkt_lentotal_byte(8) -radix hexadecimal} {/eth_mac_tb/m_rx/i_pkt_lentotal_byte(7) -radix hexadecimal} {/eth_mac_tb/m_rx/i_pkt_lentotal_byte(6) -radix hexadecimal} {/eth_mac_tb/m_rx/i_pkt_lentotal_byte(5) -radix hexadecimal} {/eth_mac_tb/m_rx/i_pkt_lentotal_byte(4) -radix hexadecimal} {/eth_mac_tb/m_rx/i_pkt_lentotal_byte(3) -radix hexadecimal} {/eth_mac_tb/m_rx/i_pkt_lentotal_byte(2) -radix hexadecimal} {/eth_mac_tb/m_rx/i_pkt_lentotal_byte(1) -radix hexadecimal} {/eth_mac_tb/m_rx/i_pkt_lentotal_byte(0) -radix hexadecimal}} -subitemconfig {/eth_mac_tb/m_rx/i_pkt_lentotal_byte(15) {-height 15 -radix hexadecimal} /eth_mac_tb/m_rx/i_pkt_lentotal_byte(14) {-height 15 -radix hexadecimal} /eth_mac_tb/m_rx/i_pkt_lentotal_byte(13) {-height 15 -radix hexadecimal} /eth_mac_tb/m_rx/i_pkt_lentotal_byte(12) {-height 15 -radix hexadecimal} /eth_mac_tb/m_rx/i_pkt_lentotal_byte(11) {-height 15 -radix hexadecimal} /eth_mac_tb/m_rx/i_pkt_lentotal_byte(10) {-height 15 -radix hexadecimal} /eth_mac_tb/m_rx/i_pkt_lentotal_byte(9) {-height 15 -radix hexadecimal} /eth_mac_tb/m_rx/i_pkt_lentotal_byte(8) {-height 15 -radix hexadecimal} /eth_mac_tb/m_rx/i_pkt_lentotal_byte(7) {-height 15 -radix hexadecimal} /eth_mac_tb/m_rx/i_pkt_lentotal_byte(6) {-height 15 -radix hexadecimal} /eth_mac_tb/m_rx/i_pkt_lentotal_byte(5) {-height 15 -radix hexadecimal} /eth_mac_tb/m_rx/i_pkt_lentotal_byte(4) {-height 15 -radix hexadecimal} /eth_mac_tb/m_rx/i_pkt_lentotal_byte(3) {-height 15 -radix hexadecimal} /eth_mac_tb/m_rx/i_pkt_lentotal_byte(2) {-height 15 -radix hexadecimal} /eth_mac_tb/m_rx/i_pkt_lentotal_byte(1) {-height 15 -radix hexadecimal} /eth_mac_tb/m_rx/i_pkt_lentotal_byte(0) {-height 15 -radix hexadecimal}} /eth_mac_tb/m_rx/i_pkt_lentotal_byte
add wave -noupdate -radix hexadecimal /eth_mac_tb/m_rx/i_dcnt_len
add wave -noupdate -radix hexadecimal /eth_mac_tb/m_rx/p_out_rxbuf_din
add wave -noupdate -radix hexadecimal /eth_mac_tb/m_rx/p_out_rxbuf_wr
add wave -noupdate /eth_mac_tb/m_rx/p_out_rxd_sof
add wave -noupdate /eth_mac_tb/m_rx/p_out_rxd_eof
add wave -noupdate /eth_mac_tb/m_rx/p_in_rxbuf_full
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {0 ps} 0}
configure wave -namecolwidth 150
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
WaveRestoreZoom {2191836 ps} {3260304 ps}
