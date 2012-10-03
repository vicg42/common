onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /eth_mdio_tb/m_mdio/p_in_rst
add wave -noupdate /eth_mdio_tb/m_mdio/p_in_clk
add wave -noupdate -color {Cornflower Blue} -itemcolor Gold /eth_mdio_tb/m_mdio/fsm_ethmdio_cs
add wave -noupdate /eth_mdio_tb/m_mdio/p_in_cfg_start
add wave -noupdate -radix hexadecimal /eth_mdio_tb/m_mdio/p_in_cfg_wr
add wave -noupdate -radix hexadecimal /eth_mdio_tb/m_mdio/p_in_cfg_aphy
add wave -noupdate -radix hexadecimal /eth_mdio_tb/m_mdio/p_in_cfg_areg
add wave -noupdate -radix hexadecimal /eth_mdio_tb/m_mdio/p_in_cfg_txd
add wave -noupdate /eth_mdio_tb/m_mdio/i_tmr_cnt
add wave -noupdate /eth_mdio_tb/m_mdio/sr_en
add wave -noupdate -radix hexadecimal /eth_mdio_tb/m_mdio/i_txd
add wave -noupdate /eth_mdio_tb/m_mdio/i_txd_ld
add wave -noupdate /eth_mdio_tb/m_mdio/i_rxd_en
add wave -noupdate -radix unsigned /eth_mdio_tb/m_mdio/i_bitcnt
add wave -noupdate /eth_mdio_tb/m_mdio/i_fsm_en
add wave -noupdate /eth_mdio_tb/m_mdio/i_mdio_dir
add wave -noupdate -radix hexadecimal -childformat {{/eth_mdio_tb/m_mdio/sr_txd(15) -radix hexadecimal} {/eth_mdio_tb/m_mdio/sr_txd(14) -radix hexadecimal} {/eth_mdio_tb/m_mdio/sr_txd(13) -radix hexadecimal} {/eth_mdio_tb/m_mdio/sr_txd(12) -radix hexadecimal} {/eth_mdio_tb/m_mdio/sr_txd(11) -radix hexadecimal} {/eth_mdio_tb/m_mdio/sr_txd(10) -radix hexadecimal} {/eth_mdio_tb/m_mdio/sr_txd(9) -radix hexadecimal} {/eth_mdio_tb/m_mdio/sr_txd(8) -radix hexadecimal} {/eth_mdio_tb/m_mdio/sr_txd(7) -radix hexadecimal} {/eth_mdio_tb/m_mdio/sr_txd(6) -radix hexadecimal} {/eth_mdio_tb/m_mdio/sr_txd(5) -radix hexadecimal} {/eth_mdio_tb/m_mdio/sr_txd(4) -radix hexadecimal} {/eth_mdio_tb/m_mdio/sr_txd(3) -radix hexadecimal} {/eth_mdio_tb/m_mdio/sr_txd(2) -radix hexadecimal} {/eth_mdio_tb/m_mdio/sr_txd(1) -radix hexadecimal} {/eth_mdio_tb/m_mdio/sr_txd(0) -radix hexadecimal}} -subitemconfig {/eth_mdio_tb/m_mdio/sr_txd(15) {-height 15 -radix hexadecimal} /eth_mdio_tb/m_mdio/sr_txd(14) {-height 15 -radix hexadecimal} /eth_mdio_tb/m_mdio/sr_txd(13) {-height 15 -radix hexadecimal} /eth_mdio_tb/m_mdio/sr_txd(12) {-height 15 -radix hexadecimal} /eth_mdio_tb/m_mdio/sr_txd(11) {-height 15 -radix hexadecimal} /eth_mdio_tb/m_mdio/sr_txd(10) {-height 15 -radix hexadecimal} /eth_mdio_tb/m_mdio/sr_txd(9) {-height 15 -radix hexadecimal} /eth_mdio_tb/m_mdio/sr_txd(8) {-height 15 -radix hexadecimal} /eth_mdio_tb/m_mdio/sr_txd(7) {-height 15 -radix hexadecimal} /eth_mdio_tb/m_mdio/sr_txd(6) {-height 15 -radix hexadecimal} /eth_mdio_tb/m_mdio/sr_txd(5) {-height 15 -radix hexadecimal} /eth_mdio_tb/m_mdio/sr_txd(4) {-height 15 -radix hexadecimal} /eth_mdio_tb/m_mdio/sr_txd(3) {-height 15 -radix hexadecimal} /eth_mdio_tb/m_mdio/sr_txd(2) {-height 15 -radix hexadecimal} /eth_mdio_tb/m_mdio/sr_txd(1) {-height 15 -radix hexadecimal} /eth_mdio_tb/m_mdio/sr_txd(0) {-height 15 -radix hexadecimal}} /eth_mdio_tb/m_mdio/sr_txd
add wave -noupdate /eth_mdio_tb/m_mdio/sr_txd(15)
add wave -noupdate /eth_mdio_tb/m_mdio/i_txd_en
add wave -noupdate /eth_mdio_tb/m_mdio/tst_txd_en
add wave -noupdate /eth_mdio_tb/m_mdio/p_inout_mdio
add wave -noupdate /eth_mdio_tb/m_mdio/p_out_mdc
add wave -noupdate -radix hexadecimal -childformat {{/eth_mdio_tb/m_mdio/sr_rxd(15) -radix hexadecimal} {/eth_mdio_tb/m_mdio/sr_rxd(14) -radix hexadecimal} {/eth_mdio_tb/m_mdio/sr_rxd(13) -radix hexadecimal} {/eth_mdio_tb/m_mdio/sr_rxd(12) -radix hexadecimal} {/eth_mdio_tb/m_mdio/sr_rxd(11) -radix hexadecimal} {/eth_mdio_tb/m_mdio/sr_rxd(10) -radix hexadecimal} {/eth_mdio_tb/m_mdio/sr_rxd(9) -radix hexadecimal} {/eth_mdio_tb/m_mdio/sr_rxd(8) -radix hexadecimal} {/eth_mdio_tb/m_mdio/sr_rxd(7) -radix hexadecimal} {/eth_mdio_tb/m_mdio/sr_rxd(6) -radix hexadecimal} {/eth_mdio_tb/m_mdio/sr_rxd(5) -radix hexadecimal} {/eth_mdio_tb/m_mdio/sr_rxd(4) -radix hexadecimal} {/eth_mdio_tb/m_mdio/sr_rxd(3) -radix hexadecimal} {/eth_mdio_tb/m_mdio/sr_rxd(2) -radix hexadecimal} {/eth_mdio_tb/m_mdio/sr_rxd(1) -radix hexadecimal} {/eth_mdio_tb/m_mdio/sr_rxd(0) -radix hexadecimal}} -subitemconfig {/eth_mdio_tb/m_mdio/sr_rxd(15) {-height 15 -radix hexadecimal} /eth_mdio_tb/m_mdio/sr_rxd(14) {-height 15 -radix hexadecimal} /eth_mdio_tb/m_mdio/sr_rxd(13) {-height 15 -radix hexadecimal} /eth_mdio_tb/m_mdio/sr_rxd(12) {-height 15 -radix hexadecimal} /eth_mdio_tb/m_mdio/sr_rxd(11) {-height 15 -radix hexadecimal} /eth_mdio_tb/m_mdio/sr_rxd(10) {-height 15 -radix hexadecimal} /eth_mdio_tb/m_mdio/sr_rxd(9) {-height 15 -radix hexadecimal} /eth_mdio_tb/m_mdio/sr_rxd(8) {-height 15 -radix hexadecimal} /eth_mdio_tb/m_mdio/sr_rxd(7) {-height 15 -radix hexadecimal} /eth_mdio_tb/m_mdio/sr_rxd(6) {-height 15 -radix hexadecimal} /eth_mdio_tb/m_mdio/sr_rxd(5) {-height 15 -radix hexadecimal} /eth_mdio_tb/m_mdio/sr_rxd(4) {-height 15 -radix hexadecimal} /eth_mdio_tb/m_mdio/sr_rxd(3) {-height 15 -radix hexadecimal} /eth_mdio_tb/m_mdio/sr_rxd(2) {-height 15 -radix hexadecimal} /eth_mdio_tb/m_mdio/sr_rxd(1) {-height 15 -radix hexadecimal} /eth_mdio_tb/m_mdio/sr_rxd(0) {-height 15 -radix hexadecimal}} /eth_mdio_tb/m_mdio/sr_rxd
add wave -noupdate /eth_mdio_tb/m_mdio/i_rxd_latch
add wave -noupdate -radix hexadecimal /eth_mdio_tb/m_mdio/p_out_cfg_rxd
add wave -noupdate /eth_mdio_tb/m_mdio/p_out_cfg_done
add wave -noupdate -radix hexadecimal -childformat {{/eth_mdio_tb/sr_mdio(15) -radix hexadecimal} {/eth_mdio_tb/sr_mdio(14) -radix hexadecimal} {/eth_mdio_tb/sr_mdio(13) -radix hexadecimal} {/eth_mdio_tb/sr_mdio(12) -radix hexadecimal} {/eth_mdio_tb/sr_mdio(11) -radix hexadecimal} {/eth_mdio_tb/sr_mdio(10) -radix hexadecimal} {/eth_mdio_tb/sr_mdio(9) -radix hexadecimal} {/eth_mdio_tb/sr_mdio(8) -radix hexadecimal} {/eth_mdio_tb/sr_mdio(7) -radix hexadecimal} {/eth_mdio_tb/sr_mdio(6) -radix hexadecimal} {/eth_mdio_tb/sr_mdio(5) -radix hexadecimal} {/eth_mdio_tb/sr_mdio(4) -radix hexadecimal} {/eth_mdio_tb/sr_mdio(3) -radix hexadecimal} {/eth_mdio_tb/sr_mdio(2) -radix hexadecimal} {/eth_mdio_tb/sr_mdio(1) -radix hexadecimal} {/eth_mdio_tb/sr_mdio(0) -radix hexadecimal}} -subitemconfig {/eth_mdio_tb/sr_mdio(15) {-height 15 -radix hexadecimal} /eth_mdio_tb/sr_mdio(14) {-height 15 -radix hexadecimal} /eth_mdio_tb/sr_mdio(13) {-height 15 -radix hexadecimal} /eth_mdio_tb/sr_mdio(12) {-height 15 -radix hexadecimal} /eth_mdio_tb/sr_mdio(11) {-height 15 -radix hexadecimal} /eth_mdio_tb/sr_mdio(10) {-height 15 -radix hexadecimal} /eth_mdio_tb/sr_mdio(9) {-height 15 -radix hexadecimal} /eth_mdio_tb/sr_mdio(8) {-height 15 -radix hexadecimal} /eth_mdio_tb/sr_mdio(7) {-height 15 -radix hexadecimal} /eth_mdio_tb/sr_mdio(6) {-height 15 -radix hexadecimal} /eth_mdio_tb/sr_mdio(5) {-height 15 -radix hexadecimal} /eth_mdio_tb/sr_mdio(4) {-height 15 -radix hexadecimal} /eth_mdio_tb/sr_mdio(3) {-height 15 -radix hexadecimal} /eth_mdio_tb/sr_mdio(2) {-height 15 -radix hexadecimal} /eth_mdio_tb/sr_mdio(1) {-height 15 -radix hexadecimal} /eth_mdio_tb/sr_mdio(0) {-height 15 -radix hexadecimal}} /eth_mdio_tb/sr_mdio
add wave -noupdate -radix hexadecimal /eth_mdio_tb/m_mdio/p_out_tst
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
WaveRestoreZoom {0 ps} {10500 ns}
