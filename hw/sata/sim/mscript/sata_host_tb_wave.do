onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -divider SATA_HOST
add wave -noupdate /sata_host_tb/i_satadev_ctrl
add wave -noupdate -radix hexadecimal /sata_host_tb/i_al_status
add wave -noupdate /sata_host_tb/i_cmddone_det
add wave -noupdate /sata_host_tb/i_cmddone_det_clr
add wave -noupdate /sata_host_tb/i_txcmd_start
add wave -noupdate /sata_host_tb/i_data_wrstart
add wave -noupdate /sata_host_tb/i_data_wrdone
add wave -noupdate /sata_host_tb/i_data_rdstart
add wave -noupdate /sata_host_tb/i_data_rddone
add wave -noupdate /sata_host_tb/i_tstdata_dwsize
add wave -noupdate -divider CmdBUF
add wave -noupdate -radix hexadecimal /sata_host_tb/ll_wcmdpkt_data
add wave -noupdate /sata_host_tb/ll_wcmdpkt_sof_n
add wave -noupdate /sata_host_tb/ll_wcmdpkt_eof_n
add wave -noupdate /sata_host_tb/ll_wcmdpkt_src_rdy_n
add wave -noupdate /sata_host_tb/ll_wcmdpkt_dst_rdy_n
add wave -noupdate /sata_host_tb/m_sata_host/gen_ch(0)/m_player/m_phy_tx/tst_val
add wave -noupdate -color {Cornflower Blue} -itemcolor Gold /sata_host_tb/m_sata_host/gen_ch(0)/m_alayer/tst_al_status
add wave -noupdate -divider TXBUF
add wave -noupdate -radix hexadecimal /sata_host_tb/i_usr_txd
add wave -noupdate -radix hexadecimal /sata_host_tb/i_usr_txd_wr
add wave -noupdate -radix hexadecimal /sata_host_tb/i_txbuf_dout(0)
add wave -noupdate -radix hexadecimal /sata_host_tb/i_txbuf_rd(0)
add wave -noupdate -radix hexadecimal /sata_host_tb/i_txbuf_full(0)
add wave -noupdate /sata_host_tb/i_txbuf_status(0)
add wave -noupdate -divider RXBUF
add wave -noupdate -radix hexadecimal /sata_host_tb/m_rxbuf/dout
add wave -noupdate -radix hexadecimal /sata_host_tb/m_rxbuf/din
add wave -noupdate /sata_host_tb/i_rxbuf_status(0)
add wave -noupdate -divider {CH0/APP LAYER}
add wave -noupdate -radix hexadecimal /sata_host_tb/m_sata_host/gen_ch(0)/m_alayer/p_in_ctrl
add wave -noupdate -radix hexadecimal /sata_host_tb/m_sata_host/gen_ch(0)/m_alayer/p_out_status
add wave -noupdate -radix hexadecimal /sata_host_tb/m_sata_host/gen_ch(0)/m_alayer/p_out_status.ATAStatus(7)
add wave -noupdate -radix hexadecimal /sata_host_tb/m_sata_host/gen_ch(0)/m_alayer/p_out_status.ATAStatus(3)
add wave -noupdate -radix hexadecimal /sata_host_tb/m_sata_host/gen_ch(0)/m_alayer/p_in_cmdfifo_dout
add wave -noupdate /sata_host_tb/m_sata_host/gen_ch(0)/m_alayer/p_in_cmdfifo_eof_n
add wave -noupdate /sata_host_tb/m_sata_host/gen_ch(0)/m_alayer/p_in_cmdfifo_src_rdy_n
add wave -noupdate /sata_host_tb/m_sata_host/gen_ch(0)/m_alayer/p_out_cmdfifo_dst_rdy_n
add wave -noupdate /sata_host_tb/m_sata_host/gen_ch(0)/m_alayer/p_in_clk
add wave -noupdate -radix hexadecimal /sata_host_tb/m_sata_host/gen_ch(0)/m_alayer/i_cmdfifo_dcnt
add wave -noupdate -radix hexadecimal /sata_host_tb/m_sata_host/gen_ch(0)/m_alayer/i_reg_shadow_addr
add wave -noupdate -radix hexadecimal /sata_host_tb/m_sata_host/gen_ch(0)/m_alayer/i_reg_shadow_wr
add wave -noupdate -radix hexadecimal /sata_host_tb/m_sata_host/gen_ch(0)/m_alayer/i_reg_shadow_wr_done
add wave -noupdate -radix hexadecimal /sata_host_tb/m_sata_host/gen_ch(0)/m_alayer/p_out_reg_shadow
add wave -noupdate -radix hexadecimal /sata_host_tb/m_sata_host/gen_ch(0)/m_alayer/p_in_reg_hold
add wave -noupdate /sata_host_tb/m_sata_host/gen_ch(0)/m_alayer/p_in_reg_update
add wave -noupdate -color {Cornflower Blue} -itemcolor Gold /sata_host_tb/m_sata_host/gen_ch(0)/m_alayer/tst_al_status
add wave -noupdate -divider {CH0/TR LAYER}
add wave -noupdate -radix hexadecimal /sata_host_tb/m_sata_host/gen_ch(0)/m_tlayer/p_in_tl_ctrl
add wave -noupdate -radix hexadecimal /sata_host_tb/m_sata_host/gen_ch(0)/m_tlayer/p_out_tl_status
add wave -noupdate /sata_host_tb/m_sata_host/gen_ch(0)/m_tlayer/tst_tl_ctrl
add wave -noupdate /sata_host_tb/m_sata_host/gen_ch(0)/m_tlayer/tst_tl_status
add wave -noupdate -radix unsigned /sata_host_tb/m_sata_host/gen_ch(0)/m_tlayer/p_in_txfifo_dout
add wave -noupdate -radix hexadecimal /sata_host_tb/m_sata_host/gen_ch(0)/m_tlayer/p_out_txfifo_rd
add wave -noupdate -expand /sata_host_tb/m_sata_host/gen_ch(0)/m_tlayer/p_in_txfifo_status
add wave -noupdate -radix unsigned /sata_host_tb/m_sata_host/gen_ch(0)/m_tlayer/i_dma_dcnt
add wave -noupdate -radix hexadecimal /sata_host_tb/m_sata_host/gen_ch(0)/m_tlayer/p_out_rxfifo_din
add wave -noupdate -radix hexadecimal /sata_host_tb/m_sata_host/gen_ch(0)/m_tlayer/p_out_rxfifo_wd
add wave -noupdate /sata_host_tb/m_sata_host/gen_ch(0)/m_tlayer/p_in_rxfifo_status
add wave -noupdate -color {Cornflower Blue} -itemcolor Gold /sata_host_tb/m_sata_host/gen_ch(0)/m_tlayer/fsm_tlayer_cs
add wave -noupdate -radix hexadecimal /sata_host_tb/m_sata_host/gen_ch(0)/m_tlayer/i_fh2d
add wave -noupdate /sata_host_tb/m_sata_host/gen_ch(0)/m_tlayer/i_fh2d_tx_en
add wave -noupdate /sata_host_tb/m_sata_host/gen_ch(0)/m_tlayer/i_fh2d_close
add wave -noupdate /sata_host_tb/m_sata_host/gen_ch(0)/m_tlayer/i_fdone
add wave -noupdate /sata_host_tb/m_sata_host/gen_ch(0)/m_tlayer/i_fdir_bit
add wave -noupdate /sata_host_tb/m_sata_host/gen_ch(0)/m_tlayer/i_fpiosetup
add wave -noupdate /sata_host_tb/m_sata_host/gen_ch(0)/m_tlayer/i_fdata_tx_en
add wave -noupdate /sata_host_tb/m_sata_host/gen_ch(0)/m_tlayer/i_fdata_txd_en
add wave -noupdate /sata_host_tb/m_sata_host/gen_ch(0)/m_tlayer/i_fdata_close
add wave -noupdate -radix unsigned /sata_host_tb/m_sata_host/gen_ch(0)/m_tlayer/i_fdcnt
add wave -noupdate /sata_host_tb/m_sata_host/gen_ch(0)/m_tlayer/i_dma_txd
add wave -noupdate -radix hexadecimal /sata_host_tb/m_sata_host/gen_ch(0)/m_tlayer/i_dma_dcnt
add wave -noupdate -radix unsigned /sata_host_tb/m_sata_host/gen_ch(0)/m_tlayer/i_dma_trncount_dw
add wave -noupdate -radix unsigned /sata_host_tb/m_sata_host/gen_ch(0)/m_tlayer/i_piosetup_trncount_byte
add wave -noupdate -radix unsigned /sata_host_tb/m_sata_host/gen_ch(0)/m_tlayer/i_piosetup_trncount_dw
add wave -noupdate -radix hexadecimal /sata_host_tb/m_sata_host/gen_ch(0)/m_tlayer/i_trn_err_cnt
add wave -noupdate -radix hexadecimal /sata_host_tb/m_sata_host/gen_ch(0)/m_tlayer/i_trn_repeat
add wave -noupdate -radix hexadecimal /sata_host_tb/m_sata_host/gen_ch(0)/m_tlayer/sr_llrxd
add wave -noupdate -radix hexadecimal /sata_host_tb/m_sata_host/gen_ch(0)/m_tlayer/sr_llrxd_en
add wave -noupdate /sata_host_tb/m_sata_host/gen_ch(0)/m_tlayer/i_rxd_en
add wave -noupdate -radix hexadecimal /sata_host_tb/m_sata_host/gen_ch(0)/m_tlayer/p_in_ll_rxd
add wave -noupdate /sata_host_tb/m_sata_host/gen_ch(0)/m_tlayer/p_in_ll_rxd_wr
add wave -noupdate -radix hexadecimal /sata_host_tb/m_sata_host/gen_ch(0)/m_tlayer/p_out_ll_txd
add wave -noupdate /sata_host_tb/m_sata_host/gen_ch(0)/m_tlayer/p_in_ll_txd_rd
add wave -noupdate -color {Cornflower Blue} -itemcolor Gold /sata_host_tb/m_sata_host/gen_ch(0)/m_alayer/tst_al_status
add wave -noupdate -divider CH0/PHY_LAYER
add wave -noupdate -radix unsigned /sata_host_tb/m_sata_host/gen_ch(0)/m_player/i_cnt_sync
add wave -noupdate /sata_host_tb/m_sata_host/gen_ch(0)/m_player/i_synch
add wave -noupdate /sata_host_tb/m_sata_host/gen_ch(0)/m_player/i_resynch
add wave -noupdate -radix unsigned /sata_host_tb/m_sata_host/gen_ch(0)/m_player/tst_rcv_aperiod
add wave -noupdate /sata_host_tb/m_sata_host/gen_ch(0)/m_player/m_phy_oob/tst_pl_ctrl
add wave -noupdate /sata_host_tb/m_sata_host/gen_ch(0)/m_player/m_phy_oob/tst_pl_status
add wave -noupdate -divider CH0/PHY/RCV
add wave -noupdate -radix hexadecimal /sata_host_tb/m_sata_host/gen_ch(0)/m_player/m_phy_rx/p_in_gtp_rxdata
add wave -noupdate /sata_host_tb/m_sata_host/gen_ch(0)/m_player/m_phy_rx/p_in_gtp_rxcharisk
add wave -noupdate -radix hexadecimal /sata_host_tb/m_sata_host/gen_ch(0)/m_player/m_phy_rx/sr_rxdata
add wave -noupdate /sata_host_tb/m_sata_host/gen_ch(0)/m_player/m_phy_rx/sr_rxdtype
add wave -noupdate -radix hexadecimal /sata_host_tb/m_sata_host/gen_ch(0)/m_player/m_phy_tx/p_out_gtp_txcharisk
add wave -noupdate -radix hexadecimal /sata_host_tb/m_sata_host/gen_ch(0)/m_player/m_phy_tx/p_out_gtp_txdata
add wave -noupdate -color {Cornflower Blue} -itemcolor Gold /sata_host_tb/m_sata_host/gen_ch(0)/m_player/m_phy_rx/dbgrcv_type
add wave -noupdate -divider CH0/PHY/TSF
add wave -noupdate -radix unsigned /sata_host_tb/m_sata_host/gen_ch(0)/m_player/m_phy_tx/i_align_tmr
add wave -noupdate -radix hexadecimal /sata_host_tb/m_sata_host/gen_ch(0)/m_player/m_phy_tx/i_align_txen
add wave -noupdate -radix unsigned /sata_host_tb/m_sata_host/gen_ch(0)/m_player/m_phy_tx/i_align_burst_cnt
add wave -noupdate -color {Cornflower Blue} -itemcolor Gold /sata_host_tb/m_sata_host/gen_ch(0)/m_player/m_phy_tx/tst_pltx_status
add wave -noupdate -radix hexadecimal /sata_host_tb/m_sata_host/gen_ch(0)/m_player/m_phy_tx/p_in_txreq
add wave -noupdate -color {Cornflower Blue} -itemcolor Gold /sata_host_tb/m_sata_host/gen_ch(0)/m_player/m_phy_tx/dbgtsf_type
add wave -noupdate -radix hexadecimal /sata_host_tb/m_sata_host/gen_ch(0)/m_player/m_phy_tx/i_srambler_out
add wave -noupdate -radix hexadecimal /sata_host_tb/m_sata_host/gen_ch(0)/m_player/m_phy_tx/p_in_txd
add wave -noupdate -radix hexadecimal /sata_host_tb/m_sata_host/gen_ch(0)/m_player/m_phy_tx/sr_txdata
add wave -noupdate -color {Cornflower Blue} -itemcolor Gold /sata_host_tb/m_sata_host/gen_ch(0)/m_alayer/tst_al_status
add wave -noupdate -divider {CH0/LINK LAYER}
add wave -noupdate -label CMD_BUSY /sata_host_tb/m_sata_host/gen_ch(0)/m_alayer/p_out_status.Usr(0)
add wave -noupdate -radix hexadecimal /sata_host_tb/m_sata_host/gen_ch(0)/m_llayer/p_in_ctrl
add wave -noupdate -radix hexadecimal /sata_host_tb/m_sata_host/gen_ch(0)/m_llayer/p_out_status
add wave -noupdate /sata_host_tb/m_sata_host/gen_ch(0)/m_llayer/tst_ll_ctrl
add wave -noupdate -radix hexadecimal /sata_host_tb/m_sata_host/gen_ch(0)/m_llayer/tst_ll_status
add wave -noupdate -radix hexadecimal /sata_host_tb/m_sata_host/gen_ch(0)/m_llayer/p_in_txd
add wave -noupdate /sata_host_tb/m_sata_host/gen_ch(0)/m_llayer/p_out_txd_rd
add wave -noupdate -expand /sata_host_tb/m_sata_host/gen_ch(0)/m_llayer/p_in_txd_status
add wave -noupdate /sata_host_tb/m_sata_host/gen_ch(0)/m_llayer/p_in_txd_close
add wave -noupdate -radix hexadecimal /sata_host_tb/m_sata_host/gen_ch(0)/m_llayer/p_out_rxd
add wave -noupdate /sata_host_tb/m_sata_host/gen_ch(0)/m_llayer/p_out_rxd_wr
add wave -noupdate /sata_host_tb/m_sata_host/gen_ch(0)/m_llayer/p_in_rxd_status
add wave -noupdate -radix unsigned /sata_host_tb/m_sata_host/gen_ch(0)/m_llayer/i_tmr
add wave -noupdate -color {Cornflower Blue} -itemcolor Gold /sata_host_tb/m_sata_host/gen_ch(0)/m_llayer/fsm_llayer_cs
add wave -noupdate /sata_host_tb/m_sata_host/gen_ch(0)/m_llayer/i_repeat_p
add wave -noupdate /sata_host_tb/m_sata_host/gen_ch(0)/m_llayer/i_init_work
add wave -noupdate -radix hexadecimal /sata_host_tb/m_sata_host/gen_ch(0)/m_llayer/sr_rxdata_fst
add wave -noupdate /sata_host_tb/m_sata_host/gen_ch(0)/m_llayer/i_rcv_work
add wave -noupdate /sata_host_tb/m_sata_host/gen_ch(0)/m_llayer/i_rcv_en
add wave -noupdate /sata_host_tb/m_sata_host/gen_ch(0)/m_llayer/i_txd_en
add wave -noupdate /sata_host_tb/m_sata_host/gen_ch(0)/m_llayer/i_srambler_en
add wave -noupdate -radix hexadecimal /sata_host_tb/m_sata_host/gen_ch(0)/m_llayer/i_srambler_out
add wave -noupdate /sata_host_tb/m_sata_host/gen_ch(0)/m_llayer/i_crc_en
add wave -noupdate -radix hexadecimal /sata_host_tb/m_sata_host/gen_ch(0)/m_llayer/i_crc_in
add wave -noupdate -radix hexadecimal /sata_host_tb/m_sata_host/gen_ch(0)/m_llayer/i_crc_out
add wave -noupdate /sata_host_tb/m_sata_host/gen_ch(0)/m_llayer/p_in_phy_txrdy_n
add wave -noupdate /sata_host_tb/m_sata_host/gen_ch(0)/m_llayer/p_in_phy_sync
add wave -noupdate -radix hexadecimal /sata_host_tb/m_sata_host/gen_ch(0)/m_llayer/i_txd_out
add wave -noupdate -radix hexadecimal /sata_host_tb/m_sata_host/gen_ch(0)/m_llayer/p_out_phy_txd
add wave -noupdate -radix hexadecimal /sata_host_tb/m_sata_host/gen_ch(0)/m_llayer/i_txp_cnt
add wave -noupdate -color {Cornflower Blue} -itemcolor Gold /sata_host_tb/m_sata_host/gen_ch(0)/m_alayer/tst_al_status
add wave -noupdate -divider SIM_DEV
add wave -noupdate -radix hexadecimal /sata_host_tb/m_sata_dev/i_rxd
add wave -noupdate -radix hexadecimal /sata_host_tb/m_sata_dev/i_rxcharisk
add wave -noupdate -color {Cornflower Blue} -itemcolor Gold /sata_host_tb/m_sata_dev/i_rcv_allname
add wave -noupdate -color {Cornflower Blue} -itemcolor Gold /sata_host_tb/m_sata_dev/i_rcv_name
add wave -noupdate /sata_host_tb/m_sata_dev/i_usropt_in.rx.detect.prmtv.cont
add wave -noupdate /sata_host_tb/m_sata_dev/i_usropt_in.rx.detect.prmtv.align
add wave -noupdate /sata_host_tb/m_sata_dev/i_usropt_in.rx.detect.error
add wave -noupdate /sata_host_tb/m_sata_dev/i_usropt_in.rx.detect.rcvfis
add wave -noupdate /sata_host_tb/m_sata_dev/i_rxd_sync
add wave -noupdate -radix hexadecimal /sata_host_tb/m_sata_dev/i_usropt_in.rx.fisdata
add wave -noupdate -radix hexadecimal /sata_host_tb/m_sata_dev/i_usropt_in.rx.crc_calc
add wave -noupdate -color {Cornflower Blue} -itemcolor Gold /sata_host_tb/m_sata_host/gen_ch(0)/m_alayer/tst_al_status
add wave -noupdate /sata_host_tb/m_sata_dev/i_usropt_out.dbuf.sync
add wave -noupdate -color {Cornflower Blue} -itemcolor Gold -label tx_name /sata_host_tb/m_sata_host/gen_ch(0)/m_player/m_phy_rx/dbgrcv_type
add wave -noupdate -radix hexadecimal /sata_host_tb/m_sata_host/gen_ch(0)/m_player/m_phy_rx/i_rxdata
add wave -noupdate -radix hexadecimal /sata_host_tb/m_sata_host/gen_ch(0)/m_player/m_phy_rx/i_rxdtype
add wave -noupdate -divider SIM_DATABUF
add wave -noupdate /sata_host_tb/m_sata_dev/gen_dbg_llayer_off/m_databuf/p_in_ctrl.trnsize
add wave -noupdate /sata_host_tb/m_sata_dev/gen_dbg_llayer_off/m_databuf/p_in_wr
add wave -noupdate /sata_host_tb/m_sata_dev/gen_dbg_llayer_off/m_databuf/p_in_ctrl.wstart
add wave -noupdate /sata_host_tb/m_sata_dev/gen_dbg_llayer_off/m_databuf/p_in_ctrl.wdone_clr
add wave -noupdate /sata_host_tb/m_sata_dev/gen_dbg_llayer_off/m_databuf/p_out_status.rx.en
add wave -noupdate /sata_host_tb/m_sata_dev/gen_dbg_llayer_off/m_databuf/p_out_status.rx.done
add wave -noupdate /sata_host_tb/m_sata_dev/gen_dbg_llayer_off/m_databuf/i_rxbuf_dout_rd
add wave -noupdate /sata_host_tb/m_sata_dev/gen_dbg_llayer_off/m_databuf/i_dbuf_rcnt
add wave -noupdate /sata_host_tb/m_sata_dev/gen_dbg_llayer_off/m_databuf/i_dbuf_wcnt
add wave -noupdate -radix hexadecimal /sata_host_tb/m_sata_dev/gen_dbg_llayer_off/m_databuf/i_rxbuf_dout
add wave -noupdate /sata_host_tb/m_sata_dev/gen_dbg_llayer_off/m_databuf/i_rxbuf_pfull
add wave -noupdate /sata_host_tb/m_sata_dev/gen_dbg_llayer_off/m_databuf/i_rxbuf_empty
add wave -noupdate -divider CH0/PHY/OOB
add wave -noupdate /sata_host_tb/m_sata_host/gen_ch(0)/m_player/p_in_rst
add wave -noupdate -radix hexadecimal /sata_host_tb/m_sata_host/gen_ch(0)/m_player/m_phy_oob/p_out_status
add wave -noupdate -color {Cornflower Blue} -itemcolor Gold /sata_host_tb/m_sata_host/gen_ch(0)/m_player/m_phy_oob/i_fsm_statecs
add wave -noupdate -radix hexadecimal /sata_host_tb/m_sata_host/gen_ch(0)/m_player/m_phy_oob/i_timer_en
add wave -noupdate -radix hexadecimal /sata_host_tb/m_sata_host/gen_ch(0)/m_player/m_phy_oob/i_timer
add wave -noupdate -radix hexadecimal /sata_host_tb/m_sata_host/gen_ch(0)/m_player/m_phy_oob/p_in_gtp_rxstatus
add wave -noupdate -radix unsigned /sata_host_tb/m_sata_host/gen_ch(0)/m_player/m_phy_oob/i_rx_prmt_cnt
add wave -noupdate /sata_host_tb/m_sata_host/gen_ch(0)/m_player/i_d10_2_senddis
add wave -noupdate -divider SPEED_CTRL
add wave -noupdate -color {Cornflower Blue} -itemcolor Gold /sata_host_tb/m_sata_host/m_speed_ctrl/fsm_state_cs
add wave -noupdate /sata_host_tb/m_sata_host/m_speed_ctrl/p_out_gtp_ch_rst
add wave -noupdate -radix hexadecimal /sata_host_tb/m_sata_host/m_speed_ctrl/p_out_gtp_drpaddr
add wave -noupdate -radix hexadecimal /sata_host_tb/m_sata_host/m_speed_ctrl/p_out_gtp_drpdi
add wave -noupdate -divider SIM_SYSTEM
add wave -noupdate /sata_host_tb/p_in_rst
add wave -noupdate /sata_host_tb/i_sata_dcm_lock
add wave -noupdate /sata_host_tb/i_sata_dcm_rst
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
WaveRestoreZoom {7196187 ps} {7347431 ps}
