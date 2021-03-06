onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /cfgdev_host_tb/i_host_rxd
add wave -noupdate /cfgdev_host_tb/i_host_rd
add wave -noupdate /cfgdev_host_tb/i_host_txd
add wave -noupdate /cfgdev_host_tb/i_host_wr
add wave -noupdate /cfgdev_host_tb/m_devcfg/p_in_rst
add wave -noupdate /cfgdev_host_tb/m_devcfg/p_in_cfg_clk
add wave -noupdate -radix hexadecimal -childformat {{/cfgdev_host_tb/i_pkts(0) -radix hexadecimal -childformat {{/cfgdev_host_tb/i_pkts(0)(0) -radix hexadecimal} {/cfgdev_host_tb/i_pkts(0)(1) -radix hexadecimal} {/cfgdev_host_tb/i_pkts(0)(2) -radix hexadecimal} {/cfgdev_host_tb/i_pkts(0)(3) -radix hexadecimal} {/cfgdev_host_tb/i_pkts(0)(4) -radix hexadecimal} {/cfgdev_host_tb/i_pkts(0)(5) -radix hexadecimal} {/cfgdev_host_tb/i_pkts(0)(6) -radix hexadecimal} {/cfgdev_host_tb/i_pkts(0)(7) -radix hexadecimal} {/cfgdev_host_tb/i_pkts(0)(8) -radix hexadecimal}}} {/cfgdev_host_tb/i_pkts(1) -radix hexadecimal} {/cfgdev_host_tb/i_pkts(2) -radix hexadecimal} {/cfgdev_host_tb/i_pkts(3) -radix hexadecimal} {/cfgdev_host_tb/i_pkts(4) -radix hexadecimal} {/cfgdev_host_tb/i_pkts(5) -radix hexadecimal} {/cfgdev_host_tb/i_pkts(6) -radix hexadecimal} {/cfgdev_host_tb/i_pkts(7) -radix hexadecimal} {/cfgdev_host_tb/i_pkts(8) -radix hexadecimal} {/cfgdev_host_tb/i_pkts(9) -radix hexadecimal} {/cfgdev_host_tb/i_pkts(10) -radix hexadecimal}} -subitemconfig {/cfgdev_host_tb/i_pkts(0) {-height 15 -radix hexadecimal -childformat {{/cfgdev_host_tb/i_pkts(0)(0) -radix hexadecimal} {/cfgdev_host_tb/i_pkts(0)(1) -radix hexadecimal} {/cfgdev_host_tb/i_pkts(0)(2) -radix hexadecimal} {/cfgdev_host_tb/i_pkts(0)(3) -radix hexadecimal} {/cfgdev_host_tb/i_pkts(0)(4) -radix hexadecimal} {/cfgdev_host_tb/i_pkts(0)(5) -radix hexadecimal} {/cfgdev_host_tb/i_pkts(0)(6) -radix hexadecimal} {/cfgdev_host_tb/i_pkts(0)(7) -radix hexadecimal} {/cfgdev_host_tb/i_pkts(0)(8) -radix hexadecimal}} -expand} /cfgdev_host_tb/i_pkts(0)(0) {-height 15 -radix hexadecimal} /cfgdev_host_tb/i_pkts(0)(1) {-height 15 -radix hexadecimal} /cfgdev_host_tb/i_pkts(0)(2) {-height 15 -radix hexadecimal} /cfgdev_host_tb/i_pkts(0)(3) {-height 15 -radix hexadecimal} /cfgdev_host_tb/i_pkts(0)(4) {-height 15 -radix hexadecimal} /cfgdev_host_tb/i_pkts(0)(5) {-height 15 -radix hexadecimal} /cfgdev_host_tb/i_pkts(0)(6) {-height 15 -radix hexadecimal} /cfgdev_host_tb/i_pkts(0)(7) {-height 15 -radix hexadecimal} /cfgdev_host_tb/i_pkts(0)(8) {-height 15 -radix hexadecimal} /cfgdev_host_tb/i_pkts(1) {-height 15 -radix hexadecimal} /cfgdev_host_tb/i_pkts(2) {-height 15 -radix hexadecimal} /cfgdev_host_tb/i_pkts(3) {-height 15 -radix hexadecimal} /cfgdev_host_tb/i_pkts(4) {-height 15 -radix hexadecimal} /cfgdev_host_tb/i_pkts(5) {-height 15 -radix hexadecimal} /cfgdev_host_tb/i_pkts(6) {-height 15 -radix hexadecimal} /cfgdev_host_tb/i_pkts(7) {-height 15 -radix hexadecimal} /cfgdev_host_tb/i_pkts(8) {-height 15 -radix hexadecimal} /cfgdev_host_tb/i_pkts(9) {-height 15 -radix hexadecimal} /cfgdev_host_tb/i_pkts(10) {-height 15 -radix hexadecimal}} /cfgdev_host_tb/i_pkts
add wave -noupdate /cfgdev_host_tb/m_devcfg/i_rxbuf_empty
add wave -noupdate -radix hexadecimal /cfgdev_host_tb/m_devcfg/i_dv_din
add wave -noupdate /cfgdev_host_tb/m_devcfg/i_dv_rd
add wave -noupdate -radix hexadecimal /cfgdev_host_tb/m_devcfg/i_dv_dout
add wave -noupdate -radix hexadecimal /cfgdev_host_tb/m_devcfg/i_dv_wr
add wave -noupdate -color {Slate Blue} -itemcolor Gold /cfgdev_host_tb/m_devcfg/fsm_state_cs
add wave -noupdate /cfgdev_host_tb/m_devcfg/i_cfg_dbyte
add wave -noupdate -radix hexadecimal -childformat {{/cfgdev_host_tb/m_devcfg/i_pkt_dheader(0) -radix hexadecimal} {/cfgdev_host_tb/m_devcfg/i_pkt_dheader(1) -radix hexadecimal} {/cfgdev_host_tb/m_devcfg/i_pkt_dheader(2) -radix hexadecimal}} -expand -subitemconfig {/cfgdev_host_tb/m_devcfg/i_pkt_dheader(0) {-height 15 -radix hexadecimal} /cfgdev_host_tb/m_devcfg/i_pkt_dheader(1) {-height 15 -radix hexadecimal} /cfgdev_host_tb/m_devcfg/i_pkt_dheader(2) {-height 15 -radix hexadecimal}} /cfgdev_host_tb/m_devcfg/i_pkt_dheader
add wave -noupdate /cfgdev_host_tb/m_devcfg/i_pkt_txack
add wave -noupdate -radix hexadecimal /cfgdev_host_tb/m_devcfg/i_pkt_field_data
add wave -noupdate -radix hexadecimal /cfgdev_host_tb/m_devcfg/i_pkt_cntd
add wave -noupdate -radix hexadecimal /cfgdev_host_tb/m_devcfg/p_in_cfg_txrdy
add wave -noupdate -radix hexadecimal /cfgdev_host_tb/m_devcfg/p_out_cfg_txdata
add wave -noupdate -radix hexadecimal /cfgdev_host_tb/m_devcfg/p_out_cfg_wr
add wave -noupdate -radix hexadecimal /cfgdev_host_tb/m_devcfg/p_in_cfg_rxrdy
add wave -noupdate -radix hexadecimal /cfgdev_host_tb/m_devcfg/p_in_cfg_rxdata
add wave -noupdate -radix hexadecimal /cfgdev_host_tb/m_devcfg/p_out_cfg_rd
add wave -noupdate /cfgdev_host_tb/m_devcfg/p_out_cfg_done
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {0 ps} 0}
quietly wave cursor active 0
configure wave -namecolwidth 155
configure wave -valuecolwidth 83
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
WaveRestoreZoom {0 ps} {5250 ns}
