onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -divider SATA_HOST
add wave -noupdate /sata_player_tb/i_satadev_ctrl
add wave -noupdate -divider CmdBUF
add wave -noupdate /sata_player_tb/m_player/m_phy_tx/tst_val
add wave -noupdate -divider CH0/PHY_LAYER
add wave -noupdate -radix unsigned /sata_player_tb/m_player/i_cnt_sync
add wave -noupdate /sata_player_tb/m_player/i_synch
add wave -noupdate /sata_player_tb/m_player/i_resynch
add wave -noupdate -radix unsigned /sata_player_tb/m_player/tst_rcv_aperiod
add wave -noupdate /sata_player_tb/m_player/m_phy_oob/tst_pl_ctrl
add wave -noupdate /sata_player_tb/m_player/m_phy_oob/tst_pl_status
add wave -noupdate -divider CH0/PHY/RCV
add wave -noupdate -radix hexadecimal /sata_player_tb/m_player/m_phy_rx/p_in_gtp_rxdata
add wave -noupdate /sata_player_tb/m_player/m_phy_rx/p_in_gtp_rxcharisk
add wave -noupdate -radix hexadecimal /sata_player_tb/m_player/m_phy_rx/sr_rxdata
add wave -noupdate /sata_player_tb/m_player/m_phy_rx/sr_rxdtype
add wave -noupdate -radix hexadecimal /sata_player_tb/m_player/m_phy_tx/p_out_gtp_txcharisk
add wave -noupdate -radix hexadecimal /sata_player_tb/m_player/m_phy_tx/p_out_gtp_txdata
add wave -noupdate -color {Cornflower Blue} -itemcolor Gold /sata_player_tb/m_player/m_phy_rx/dbgrcv_type
add wave -noupdate -divider CH0/PHY/TSF
add wave -noupdate -radix unsigned /sata_player_tb/m_player/m_phy_tx/i_align_tmr
add wave -noupdate -radix hexadecimal /sata_player_tb/m_player/m_phy_tx/i_align_txen
add wave -noupdate -radix unsigned /sata_player_tb/m_player/m_phy_tx/i_align_burst_cnt
add wave -noupdate -color {Cornflower Blue} -itemcolor Gold /sata_player_tb/m_player/m_phy_tx/tst_pltx_status
add wave -noupdate -radix hexadecimal /sata_player_tb/m_player/m_phy_tx/p_in_txreq
add wave -noupdate -color {Cornflower Blue} -itemcolor Gold /sata_player_tb/m_player/m_phy_tx/dbgtsf_type
add wave -noupdate -radix hexadecimal /sata_player_tb/m_player/m_phy_tx/i_srambler_out
add wave -noupdate -radix hexadecimal /sata_player_tb/m_player/m_phy_tx/p_in_txd
add wave -noupdate -radix hexadecimal /sata_player_tb/m_player/m_phy_tx/sr_txdata
add wave -noupdate -divider {CH0/LINK LAYER}
add wave -noupdate -radix hexadecimal /sata_player_tb/m_llayer/p_in_ctrl
add wave -noupdate -radix hexadecimal /sata_player_tb/m_llayer/p_out_status
add wave -noupdate /sata_player_tb/m_llayer/tst_ll_ctrl
add wave -noupdate -radix hexadecimal /sata_player_tb/m_llayer/tst_ll_status
add wave -noupdate -radix hexadecimal /sata_player_tb/m_llayer/p_in_txd
add wave -noupdate /sata_player_tb/m_llayer/p_out_txd_rd
add wave -noupdate -expand /sata_player_tb/m_llayer/p_in_txd_status
add wave -noupdate /sata_player_tb/m_llayer/p_in_txd_close
add wave -noupdate -radix hexadecimal /sata_player_tb/m_llayer/p_out_rxd
add wave -noupdate /sata_player_tb/m_llayer/p_out_rxd_wr
add wave -noupdate /sata_player_tb/m_llayer/p_in_rxd_status
add wave -noupdate -radix unsigned /sata_player_tb/m_llayer/i_tmr
add wave -noupdate -color {Cornflower Blue} -itemcolor Gold /sata_player_tb/m_llayer/fsm_llayer_cs
add wave -noupdate /sata_player_tb/m_llayer/i_repeat_p
add wave -noupdate /sata_player_tb/m_llayer/i_init_work
add wave -noupdate -radix hexadecimal /sata_player_tb/m_llayer/sr_rxdata_fst
add wave -noupdate /sata_player_tb/m_llayer/i_rcv_work
add wave -noupdate /sata_player_tb/m_llayer/i_rcv_en
add wave -noupdate /sata_player_tb/m_llayer/i_txd_en
add wave -noupdate /sata_player_tb/m_llayer/i_srambler_en
add wave -noupdate -radix hexadecimal /sata_player_tb/m_llayer/i_srambler_out
add wave -noupdate /sata_player_tb/m_llayer/i_crc_en
add wave -noupdate -radix hexadecimal /sata_player_tb/m_llayer/i_crc_in
add wave -noupdate -radix hexadecimal /sata_player_tb/m_llayer/i_crc_out
add wave -noupdate /sata_player_tb/m_llayer/p_in_phy_txrdy_n
add wave -noupdate /sata_player_tb/m_llayer/p_in_phy_sync
add wave -noupdate -radix hexadecimal /sata_player_tb/m_llayer/i_txd_out
add wave -noupdate -radix hexadecimal /sata_player_tb/m_llayer/p_out_phy_txd
add wave -noupdate -radix hexadecimal /sata_player_tb/m_llayer/i_txp_cnt
add wave -noupdate -divider SIM_DEV
add wave -noupdate -radix hexadecimal /sata_player_tb/m_sata_dev/i_rxd
add wave -noupdate -radix hexadecimal /sata_player_tb/m_sata_dev/i_rxcharisk
add wave -noupdate -color {Cornflower Blue} -itemcolor Gold /sata_player_tb/m_sata_dev/i_rcv_allname
add wave -noupdate -color {Cornflower Blue} -itemcolor Gold /sata_player_tb/m_sata_dev/i_rcv_name
add wave -noupdate /sata_player_tb/m_sata_dev/i_usropt_in.rx.detect.prmtv.cont
add wave -noupdate /sata_player_tb/m_sata_dev/i_usropt_in.rx.detect.prmtv.align
add wave -noupdate /sata_player_tb/m_sata_dev/i_usropt_in.rx.detect.error
add wave -noupdate /sata_player_tb/m_sata_dev/i_usropt_in.rx.detect.rcvfis
add wave -noupdate /sata_player_tb/m_sata_dev/i_rxd_sync
add wave -noupdate -radix hexadecimal /sata_player_tb/m_sata_dev/i_usropt_in.rx.fisdata
add wave -noupdate -radix hexadecimal /sata_player_tb/m_sata_dev/i_usropt_in.rx.crc_calc
add wave -noupdate -divider SIM_DATABUF
add wave -noupdate -divider CH0/PHY/OOB
add wave -noupdate /sata_player_tb/m_player/p_in_rst
add wave -noupdate -radix hexadecimal /sata_player_tb/m_player/m_phy_oob/p_out_status
add wave -noupdate -color {Cornflower Blue} -itemcolor Gold /sata_player_tb/m_player/m_phy_oob/i_fsm_statecs
add wave -noupdate -radix hexadecimal /sata_player_tb/m_player/m_phy_oob/i_timer_en
add wave -noupdate -radix hexadecimal /sata_player_tb/m_player/m_phy_oob/i_timer
add wave -noupdate -radix hexadecimal /sata_player_tb/m_player/m_phy_oob/p_in_gtp_rxstatus
add wave -noupdate -radix unsigned /sata_player_tb/m_player/m_phy_oob/i_rx_prmt_cnt
add wave -noupdate /sata_player_tb/m_player/i_d10_2_senddis
add wave -noupdate -divider SPEED_CTRL
add wave -noupdate -color {Cornflower Blue} -itemcolor Gold /sata_player_tb/m_speed_ctrl/fsm_state_cs
add wave -noupdate /sata_player_tb/m_speed_ctrl/p_out_gtp_ch_rst
add wave -noupdate -radix hexadecimal /sata_player_tb/m_speed_ctrl/p_out_gtp_drpaddr
add wave -noupdate -radix hexadecimal /sata_player_tb/m_speed_ctrl/p_out_gtp_drpdi
add wave -noupdate -divider SIM_SYSTEM
add wave -noupdate /sata_player_tb/p_in_rst
add wave -noupdate /sata_player_tb/i_sata_dcm_lock
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {0 ps} 0}
configure wave -namecolwidth 207
configure wave -valuecolwidth 55
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
configure wave -timelineunits ns
update
WaveRestoreZoom {10799389 ps} {12668953 ps}
