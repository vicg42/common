onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /hscam_pcie_tb/m_clocks/i_pll_locked
add wave -noupdate /hscam_pcie_tb/i_ccd_vclk
add wave -noupdate /hscam_pcie_tb/m_vfr_gen/i_div_cnt
add wave -noupdate /hscam_pcie_tb/m_vfr_gen/i_div
add wave -noupdate /hscam_pcie_tb/m_vfr_gen/fsm_cs
add wave -noupdate -radix hexadecimal /hscam_pcie_tb/m_vfr_gen/i_pix_cnt
add wave -noupdate -radix hexadecimal /hscam_pcie_tb/m_vfr_gen/i_row_cnt
add wave -noupdate -divider SWT/VIN
add wave -noupdate -radix hexadecimal /hscam_pcie_tb/m_swt/m_vctrl_bufi/p_in_vd
add wave -noupdate -radix hexadecimal /hscam_pcie_tb/m_swt/m_vctrl_bufi/sr_vd
add wave -noupdate /hscam_pcie_tb/m_swt/m_vctrl_bufi/p_in_hs
add wave -noupdate /hscam_pcie_tb/m_swt/m_vctrl_bufi/p_in_vs
add wave -noupdate /hscam_pcie_tb/m_swt/m_vctrl_bufi/p_in_vclk
add wave -noupdate /hscam_pcie_tb/m_swt/m_vctrl_bufi/p_in_vclk_en
add wave -noupdate /hscam_pcie_tb/m_swt/m_vctrl_bufi/i_bufi_wr_en
add wave -noupdate -expand /hscam_pcie_tb/m_swt/m_vctrl_bufi/i_bufi_wr
add wave -noupdate -radix hexadecimal /hscam_pcie_tb/m_swt/m_vctrl_bufi/i_vd_vector
add wave -noupdate -radix hexadecimal -childformat {{/hscam_pcie_tb/m_swt/m_vctrl_bufi/i_bufi_empty(4) -radix hexadecimal} {/hscam_pcie_tb/m_swt/m_vctrl_bufi/i_bufi_empty(3) -radix hexadecimal} {/hscam_pcie_tb/m_swt/m_vctrl_bufi/i_bufi_empty(2) -radix hexadecimal} {/hscam_pcie_tb/m_swt/m_vctrl_bufi/i_bufi_empty(1) -radix hexadecimal} {/hscam_pcie_tb/m_swt/m_vctrl_bufi/i_bufi_empty(0) -radix hexadecimal}} -subitemconfig {/hscam_pcie_tb/m_swt/m_vctrl_bufi/i_bufi_empty(4) {-height 15 -radix hexadecimal} /hscam_pcie_tb/m_swt/m_vctrl_bufi/i_bufi_empty(3) {-height 15 -radix hexadecimal} /hscam_pcie_tb/m_swt/m_vctrl_bufi/i_bufi_empty(2) {-height 15 -radix hexadecimal} /hscam_pcie_tb/m_swt/m_vctrl_bufi/i_bufi_empty(1) {-height 15 -radix hexadecimal} /hscam_pcie_tb/m_swt/m_vctrl_bufi/i_bufi_empty(0) {-height 15 -radix hexadecimal}} /hscam_pcie_tb/m_swt/m_vctrl_bufi/i_bufi_empty
add wave -noupdate -radix hexadecimal /hscam_pcie_tb/m_swt/m_vctrl_bufi/i_bufo_din
add wave -noupdate -radix hexadecimal /hscam_pcie_tb/m_swt/m_vctrl_bufi/i_bufo_wr
add wave -noupdate -radix hexadecimal /hscam_pcie_tb/m_swt/m_vctrl_bufi/p_out_vbufi_d
add wave -noupdate -radix hexadecimal /hscam_pcie_tb/m_swt/m_vctrl_bufi/p_in_vbufi_rd
add wave -noupdate -radix hexadecimal /hscam_pcie_tb/m_swt/m_vctrl_bufi/p_out_vbufi_empty
add wave -noupdate -radix hexadecimal /hscam_pcie_tb/m_swt/m_vctrl_bufi/p_out_vbufi_full
add wave -noupdate -divider VCTRL/Witer
add wave -noupdate /hscam_pcie_tb/m_vctrl/m_video_writer/m_mem_wr/p_in_clk
add wave -noupdate -radix hexadecimal /hscam_pcie_tb/m_vctrl/m_video_writer/p_in_upp_data
add wave -noupdate -radix hexadecimal /hscam_pcie_tb/m_vctrl/m_video_writer/p_in_upp_buf_empty
add wave -noupdate /hscam_pcie_tb/m_vctrl/m_video_writer/fsm_state_cs
add wave -noupdate -radix hexadecimal /hscam_pcie_tb/m_vctrl/m_video_writer/i_mem_dlen_rq
add wave -noupdate -radix hexadecimal /hscam_pcie_tb/m_vctrl/m_video_writer/i_mem_trn_len
add wave -noupdate /hscam_pcie_tb/m_vctrl/m_video_writer/i_mem_start
add wave -noupdate /hscam_pcie_tb/m_vctrl/m_video_writer/i_mem_done
add wave -noupdate /hscam_pcie_tb/m_vctrl/m_video_writer/m_mem_wr/fsm_state_cs
add wave -noupdate /hscam_pcie_tb/m_vctrl/m_video_writer/m_mem_wr/i_mem_trn_work
add wave -noupdate /hscam_pcie_tb/m_vctrl/m_video_writer/m_mem_wr/i_mem_wr
add wave -noupdate /hscam_pcie_tb/m_vctrl/m_video_writer/m_mem_wr/p_in_mem
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {0 ps} 0}
configure wave -namecolwidth 145
configure wave -valuecolwidth 118
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
WaveRestoreZoom {80889666 ps} {97898306 ps}
