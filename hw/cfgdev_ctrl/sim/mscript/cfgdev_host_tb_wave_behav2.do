onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /cfgdev_host_tb/i_host_rxd
add wave -noupdate /cfgdev_host_tb/i_host_rd
add wave -noupdate /cfgdev_host_tb/i_host_txd
add wave -noupdate /cfgdev_host_tb/i_host_wr
add wave -noupdate /cfgdev_host_tb/m_devcfg/p_in_rst
add wave -noupdate /cfgdev_host_tb/m_devcfg/p_in_cfg_clk
add wave -noupdate -radix hexadecimal -childformat {{/cfgdev_host_tb/i_pkts(0) -radix hexadecimal -childformat {{/cfgdev_host_tb/i_pkts(0)(0) -radix hexadecimal} {/cfgdev_host_tb/i_pkts(0)(1) -radix hexadecimal} {/cfgdev_host_tb/i_pkts(0)(2) -radix hexadecimal} {/cfgdev_host_tb/i_pkts(0)(3) -radix hexadecimal} {/cfgdev_host_tb/i_pkts(0)(4) -radix hexadecimal} {/cfgdev_host_tb/i_pkts(0)(5) -radix hexadecimal} {/cfgdev_host_tb/i_pkts(0)(6) -radix hexadecimal} {/cfgdev_host_tb/i_pkts(0)(7) -radix hexadecimal} {/cfgdev_host_tb/i_pkts(0)(8) -radix hexadecimal} {/cfgdev_host_tb/i_pkts(0)(9) -radix hexadecimal}}} {/cfgdev_host_tb/i_pkts(1) -radix hexadecimal} {/cfgdev_host_tb/i_pkts(2) -radix hexadecimal} {/cfgdev_host_tb/i_pkts(3) -radix hexadecimal} {/cfgdev_host_tb/i_pkts(4) -radix hexadecimal} {/cfgdev_host_tb/i_pkts(5) -radix hexadecimal} {/cfgdev_host_tb/i_pkts(6) -radix hexadecimal} {/cfgdev_host_tb/i_pkts(7) -radix hexadecimal} {/cfgdev_host_tb/i_pkts(8) -radix hexadecimal} {/cfgdev_host_tb/i_pkts(9) -radix hexadecimal} {/cfgdev_host_tb/i_pkts(10) -radix hexadecimal}} -subitemconfig {/cfgdev_host_tb/i_pkts(0) {-height 15 -radix hexadecimal -childformat {{/cfgdev_host_tb/i_pkts(0)(0) -radix hexadecimal} {/cfgdev_host_tb/i_pkts(0)(1) -radix hexadecimal} {/cfgdev_host_tb/i_pkts(0)(2) -radix hexadecimal} {/cfgdev_host_tb/i_pkts(0)(3) -radix hexadecimal} {/cfgdev_host_tb/i_pkts(0)(4) -radix hexadecimal} {/cfgdev_host_tb/i_pkts(0)(5) -radix hexadecimal} {/cfgdev_host_tb/i_pkts(0)(6) -radix hexadecimal} {/cfgdev_host_tb/i_pkts(0)(7) -radix hexadecimal} {/cfgdev_host_tb/i_pkts(0)(8) -radix hexadecimal} {/cfgdev_host_tb/i_pkts(0)(9) -radix hexadecimal}} -expand} /cfgdev_host_tb/i_pkts(0)(0) {-height 15 -radix hexadecimal} /cfgdev_host_tb/i_pkts(0)(1) {-height 15 -radix hexadecimal} /cfgdev_host_tb/i_pkts(0)(2) {-height 15 -radix hexadecimal} /cfgdev_host_tb/i_pkts(0)(3) {-height 15 -radix hexadecimal} /cfgdev_host_tb/i_pkts(0)(4) {-height 15 -radix hexadecimal} /cfgdev_host_tb/i_pkts(0)(5) {-height 15 -radix hexadecimal} /cfgdev_host_tb/i_pkts(0)(6) {-height 15 -radix hexadecimal} /cfgdev_host_tb/i_pkts(0)(7) {-height 15 -radix hexadecimal} /cfgdev_host_tb/i_pkts(0)(8) {-height 15 -radix hexadecimal} /cfgdev_host_tb/i_pkts(0)(9) {-height 15 -radix hexadecimal} /cfgdev_host_tb/i_pkts(1) {-height 15 -radix hexadecimal} /cfgdev_host_tb/i_pkts(2) {-height 15 -radix hexadecimal} /cfgdev_host_tb/i_pkts(3) {-height 15 -radix hexadecimal} /cfgdev_host_tb/i_pkts(4) {-height 15 -radix hexadecimal} /cfgdev_host_tb/i_pkts(5) {-height 15 -radix hexadecimal} /cfgdev_host_tb/i_pkts(6) {-height 15 -radix hexadecimal} /cfgdev_host_tb/i_pkts(7) {-height 15 -radix hexadecimal} /cfgdev_host_tb/i_pkts(8) {-height 15 -radix hexadecimal} /cfgdev_host_tb/i_pkts(9) {-height 15 -radix hexadecimal} /cfgdev_host_tb/i_pkts(10) {-height 15 -radix hexadecimal}} /cfgdev_host_tb/i_pkts
add wave -noupdate -radix hexadecimal /cfgdev_host_tb/m_devcfg/p_in_cfg_txrdy
add wave -noupdate -radix hexadecimal /cfgdev_host_tb/m_devcfg/p_out_cfg_txdata
add wave -noupdate -radix hexadecimal /cfgdev_host_tb/m_devcfg/p_out_cfg_wr
add wave -noupdate -radix hexadecimal /cfgdev_host_tb/m_devcfg/p_in_cfg_rxrdy
add wave -noupdate -radix hexadecimal /cfgdev_host_tb/m_devcfg/p_in_cfg_rxdata
add wave -noupdate -radix hexadecimal /cfgdev_host_tb/m_devcfg/p_out_cfg_rd
add wave -noupdate /cfgdev_host_tb/m_devcfg/p_out_cfg_done
add wave -noupdate /cfgdev_host_tb/m_devcfg/p_out_cfg_radr_fifo
add wave -noupdate -radix hexadecimal /cfgdev_host_tb/i_cfg_adr_cnt
add wave -noupdate -radix hexadecimal /cfgdev_host_tb/i_reg0
add wave -noupdate -radix hexadecimal /cfgdev_host_tb/i_reg1
add wave -noupdate -radix hexadecimal /cfgdev_host_tb/i_reg2
add wave -noupdate -radix hexadecimal /cfgdev_host_tb/i_reg3
add wave -noupdate -radix hexadecimal /cfgdev_host_tb/i_reg4
add wave -noupdate -radix hexadecimal /cfgdev_host_tb/i_cfg_rxd
add wave -noupdate -divider {New Divider}
add wave -noupdate -color {Slate Blue} -itemcolor Gold /cfgdev_host_tb/m_devcfg/fsm_state_cs
add wave -noupdate -radix hexadecimal /cfgdev_host_tb/m_devcfg/p_out_cfg_dadr
add wave -noupdate -radix hexadecimal /cfgdev_host_tb/m_devcfg/p_out_cfg_radr
add wave -noupdate -radix hexadecimal /cfgdev_host_tb/m_devcfg/p_out_cfg_radr_ld
add wave -noupdate /cfgdev_host_tb/m_devcfg/p_in_htxbuf_wr
add wave -noupdate -radix hexadecimal /cfgdev_host_tb/m_devcfg/i_htxbuf_di_swap
add wave -noupdate -radix hexadecimal /cfgdev_host_tb/m_devcfg/i_hbufr_do
add wave -noupdate -radix hexadecimal /cfgdev_host_tb/m_devcfg/i_hbufr_rd
add wave -noupdate /cfgdev_host_tb/m_devcfg/p_out_htxbuf_full
add wave -noupdate /cfgdev_host_tb/m_devcfg/p_out_htxbuf_empty
add wave -noupdate /cfgdev_host_tb/m_devcfg/i_hbufr_clr
add wave -noupdate -radix hexadecimal /cfgdev_host_tb/m_devcfg/i_fdev_radr_ld
add wave -noupdate -radix hexadecimal /cfgdev_host_tb/m_devcfg/i_fdev_txd
add wave -noupdate -radix hexadecimal /cfgdev_host_tb/m_devcfg/i_fdev_done
add wave -noupdate -radix hexadecimal -childformat {{/cfgdev_host_tb/m_devcfg/i_pkth(0) -radix hexadecimal} {/cfgdev_host_tb/m_devcfg/i_pkth(1) -radix hexadecimal} {/cfgdev_host_tb/m_devcfg/i_pkth(2) -radix hexadecimal}} -expand -subitemconfig {/cfgdev_host_tb/m_devcfg/i_pkth(0) {-height 15 -radix hexadecimal} /cfgdev_host_tb/m_devcfg/i_pkth(1) {-height 15 -radix hexadecimal} /cfgdev_host_tb/m_devcfg/i_pkth(2) {-height 15 -radix hexadecimal}} /cfgdev_host_tb/m_devcfg/i_pkth
add wave -noupdate /cfgdev_host_tb/m_devcfg/i_fdev_wr
add wave -noupdate /cfgdev_host_tb/m_devcfg/i_fdev_rd
add wave -noupdate -radix hexadecimal /cfgdev_host_tb/m_devcfg/i_pkt_dcnt
add wave -noupdate -radix hexadecimal /cfgdev_host_tb/m_devcfg/p_out_hrxbuf_do
add wave -noupdate -radix hexadecimal /cfgdev_host_tb/m_devcfg/i_hbufw_di
add wave -noupdate -radix hexadecimal /cfgdev_host_tb/m_devcfg/i_hbufw_wr
add wave -noupdate -radix hexadecimal /cfgdev_host_tb/m_devcfg/p_in_hrxbuf_rd
add wave -noupdate -radix hexadecimal /cfgdev_host_tb/m_devcfg/p_out_hrxbuf_full
add wave -noupdate /cfgdev_host_tb/m_devcfg/p_out_hrxbuf_empty
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
WaveRestoreZoom {2020034 ps} {2340097 ps}
