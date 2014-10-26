onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -radix hexadecimal /bayer_main_tb/m_bayer/p_in_cfg_bypass
add wave -noupdate -radix hexadecimal /bayer_main_tb/m_bayer/p_in_cfg_colorfst
add wave -noupdate -radix hexadecimal /bayer_main_tb/m_bayer/p_in_cfg_pix_count
add wave -noupdate -radix hexadecimal /bayer_main_tb/m_bayer/p_in_cfg_row_count
add wave -noupdate -radix hexadecimal /bayer_main_tb/m_bayer/p_in_cfg_init
add wave -noupdate -radix hexadecimal /bayer_main_tb/i_cntpix
add wave -noupdate -radix hexadecimal /bayer_main_tb/i_cntline
add wave -noupdate /bayer_main_tb/i_vfr_busy
add wave -noupdate /bayer_main_tb/i_vfr_start
add wave -noupdate /bayer_main_tb/m_bayer/p_out_upp_rdy_n
add wave -noupdate -radix hexadecimal /bayer_main_tb/m_bayer/m_core/p_in_upp_wr
add wave -noupdate -radix hexadecimal /bayer_main_tb/m_bayer/m_core/p_in_upp_eof
add wave -noupdate -radix hexadecimal /bayer_main_tb/m_bayer/m_core/p_in_upp_data
add wave -noupdate -radix hexadecimal /bayer_main_tb/m_bayer/m_core/i_buf_wr
add wave -noupdate -radix hexadecimal /bayer_main_tb/m_bayer/m_core/i_buf_adr
add wave -noupdate -radix hexadecimal -childformat {{/bayer_main_tb/m_bayer/m_core/i_buf_do(0) -radix hexadecimal} {/bayer_main_tb/m_bayer/m_core/i_buf_do(1) -radix hexadecimal} {/bayer_main_tb/m_bayer/m_core/i_buf_do(2) -radix hexadecimal}} -expand -subitemconfig {/bayer_main_tb/m_bayer/m_core/i_buf_do(0) {-height 15 -radix hexadecimal} /bayer_main_tb/m_bayer/m_core/i_buf_do(1) {-height 15 -radix hexadecimal} /bayer_main_tb/m_bayer/m_core/i_buf_do(2) {-height 15 -radix hexadecimal}} /bayer_main_tb/m_bayer/m_core/i_buf_do
add wave -noupdate /bayer_main_tb/m_bayer/m_core/sr_sol(2)
add wave -noupdate /bayer_main_tb/m_bayer/m_core/sr_eol(2)
add wave -noupdate /bayer_main_tb/m_bayer/m_core/i_pix_evod
add wave -noupdate /bayer_main_tb/m_bayer/m_core/i_line_evod
add wave -noupdate /bayer_main_tb/m_bayer/m_core/p_out_dwnp_wr
add wave -noupdate /bayer_main_tb/m_bayer/m_core/p_out_dwnp_eof
add wave -noupdate -radix hexadecimal -childformat {{/bayer_main_tb/m_bayer/m_core/p_out_matrix(0) -radix hexadecimal -childformat {{/bayer_main_tb/m_bayer/m_core/p_out_matrix(0)(0) -radix hexadecimal} {/bayer_main_tb/m_bayer/m_core/p_out_matrix(0)(1) -radix hexadecimal} {/bayer_main_tb/m_bayer/m_core/p_out_matrix(0)(2) -radix hexadecimal}}} {/bayer_main_tb/m_bayer/m_core/p_out_matrix(1) -radix hexadecimal -childformat {{/bayer_main_tb/m_bayer/m_core/p_out_matrix(1)(0) -radix hexadecimal} {/bayer_main_tb/m_bayer/m_core/p_out_matrix(1)(1) -radix hexadecimal} {/bayer_main_tb/m_bayer/m_core/p_out_matrix(1)(2) -radix hexadecimal}}} {/bayer_main_tb/m_bayer/m_core/p_out_matrix(2) -radix hexadecimal -childformat {{/bayer_main_tb/m_bayer/m_core/p_out_matrix(2)(0) -radix hexadecimal} {/bayer_main_tb/m_bayer/m_core/p_out_matrix(2)(1) -radix hexadecimal} {/bayer_main_tb/m_bayer/m_core/p_out_matrix(2)(2) -radix hexadecimal}}}} -expand -subitemconfig {/bayer_main_tb/m_bayer/m_core/p_out_matrix(0) {-height 15 -radix hexadecimal -childformat {{/bayer_main_tb/m_bayer/m_core/p_out_matrix(0)(0) -radix hexadecimal} {/bayer_main_tb/m_bayer/m_core/p_out_matrix(0)(1) -radix hexadecimal} {/bayer_main_tb/m_bayer/m_core/p_out_matrix(0)(2) -radix hexadecimal}} -expand} /bayer_main_tb/m_bayer/m_core/p_out_matrix(0)(0) {-height 15 -radix hexadecimal} /bayer_main_tb/m_bayer/m_core/p_out_matrix(0)(1) {-height 15 -radix hexadecimal} /bayer_main_tb/m_bayer/m_core/p_out_matrix(0)(2) {-height 15 -radix hexadecimal} /bayer_main_tb/m_bayer/m_core/p_out_matrix(1) {-height 15 -radix hexadecimal -childformat {{/bayer_main_tb/m_bayer/m_core/p_out_matrix(1)(0) -radix hexadecimal} {/bayer_main_tb/m_bayer/m_core/p_out_matrix(1)(1) -radix hexadecimal} {/bayer_main_tb/m_bayer/m_core/p_out_matrix(1)(2) -radix hexadecimal}} -expand} /bayer_main_tb/m_bayer/m_core/p_out_matrix(1)(0) {-height 15 -radix hexadecimal} /bayer_main_tb/m_bayer/m_core/p_out_matrix(1)(1) {-height 15 -radix hexadecimal} /bayer_main_tb/m_bayer/m_core/p_out_matrix(1)(2) {-height 15 -radix hexadecimal} /bayer_main_tb/m_bayer/m_core/p_out_matrix(2) {-height 15 -radix hexadecimal -childformat {{/bayer_main_tb/m_bayer/m_core/p_out_matrix(2)(0) -radix hexadecimal} {/bayer_main_tb/m_bayer/m_core/p_out_matrix(2)(1) -radix hexadecimal} {/bayer_main_tb/m_bayer/m_core/p_out_matrix(2)(2) -radix hexadecimal}} -expand} /bayer_main_tb/m_bayer/m_core/p_out_matrix(2)(0) {-height 15 -radix hexadecimal} /bayer_main_tb/m_bayer/m_core/p_out_matrix(2)(1) {-height 15 -radix hexadecimal} /bayer_main_tb/m_bayer/m_core/p_out_matrix(2)(2) {-height 15 -radix hexadecimal}} /bayer_main_tb/m_bayer/m_core/p_out_matrix
add wave -noupdate /bayer_main_tb/m_bayer/m_core/i_matrix_wr
add wave -noupdate -radix hexadecimal /bayer_main_tb/m_bayer/m_core/i_dwnp_en
add wave -noupdate /bayer_main_tb/m_bayer/m_core/i_sof_n
add wave -noupdate /bayer_main_tb/m_bayer/m_core/i_eof_en
add wave -noupdate /bayer_main_tb/m_bayer/m_core/i_eof
add wave -noupdate -radix hexadecimal /bayer_main_tb/m_bayer/m_core/i_cnteof
add wave -noupdate -radix hexadecimal /bayer_main_tb/m_bayer/p_out_dwnp_data
add wave -noupdate -radix hexadecimal /bayer_main_tb/m_bayer/p_out_dwnp_wr
add wave -noupdate -radix hexadecimal /bayer_main_tb/m_bayer/p_out_dwnp_eof
add wave -noupdate -radix hexadecimal /bayer_main_tb/m_bayer/p_in_dwnp_rdy_n
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {0 ps} 0}
quietly wave cursor active 0
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
WaveRestoreZoom {1912500 ps} {2880680 ps}
