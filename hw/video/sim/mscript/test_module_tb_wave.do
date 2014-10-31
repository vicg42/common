onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -radix hexadecimal /test_module_tb/m_vmirx/p_in_cfg_mirx
add wave -noupdate -radix hexadecimal /test_module_tb/m_vmirx/p_in_cfg_pix_count
add wave -noupdate /test_module_tb/i_fsm_cs
add wave -noupdate -radix hexadecimal /test_module_tb/i_cntpix
add wave -noupdate -radix hexadecimal /test_module_tb/i_cntline
add wave -noupdate -radix hexadecimal /test_module_tb/m_vmirx/p_in_upp_data
add wave -noupdate -radix hexadecimal /test_module_tb/m_vmirx/p_in_upp_wr
add wave -noupdate -radix hexadecimal /test_module_tb/m_vmirx/p_out_upp_rdy_n
add wave -noupdate -color {Cornflower Blue} -itemcolor Gold -radix hexadecimal /test_module_tb/m_vmirx/i_fsm_cs
add wave -noupdate -radix hexadecimal /test_module_tb/m_vmirx/i_mirx_done
add wave -noupdate -radix hexadecimal /test_module_tb/m_vmirx/i_buf_adr
add wave -noupdate -radix hexadecimal /test_module_tb/m_vmirx/i_buf_di
add wave -noupdate -radix hexadecimal /test_module_tb/m_vmirx/i_buf_do
add wave -noupdate -radix hexadecimal /test_module_tb/m_vmirx/i_buf_enb
add wave -noupdate -radix hexadecimal /test_module_tb/m_vmirx/i_read_en
add wave -noupdate -radix hexadecimal /test_module_tb/m_vmirx/p_out_dwnp_data
add wave -noupdate -radix hexadecimal /test_module_tb/m_vmirx/p_out_dwnp_wr
add wave -noupdate -radix hexadecimal /test_module_tb/m_vmirx/p_in_dwnp_rdy_n
add wave -noupdate /test_module_tb/m_vmirx/p_out_dwnp_eof
add wave -noupdate -divider {New Divider}
add wave -noupdate -radix hexadecimal /test_module_tb/m_bayer/m_core/p_in_cfg_pix_count
add wave -noupdate -radix hexadecimal /test_module_tb/m_bayer/m_core/p_in_upp_data
add wave -noupdate -radix hexadecimal /test_module_tb/m_bayer/m_core/p_in_upp_wr
add wave -noupdate -radix hexadecimal /test_module_tb/m_bayer/m_core/p_out_upp_rdy_n
add wave -noupdate -radix hexadecimal /test_module_tb/m_bayer/m_core/p_in_upp_eof
add wave -noupdate -radix hexadecimal /test_module_tb/m_bayer/m_core/i_buf_adr
add wave -noupdate -expand /test_module_tb/m_bayer/m_core/sr_sol
add wave -noupdate /test_module_tb/m_bayer/m_core/i_eol
add wave -noupdate -expand /test_module_tb/m_bayer/m_core/sr_eol
add wave -noupdate /test_module_tb/m_bayer/m_core/i_eol_en
add wave -noupdate /test_module_tb/m_bayer/m_core/i_eof_en
add wave -noupdate /test_module_tb/m_bayer/m_core/i_eof
add wave -noupdate -color {Cornflower Blue} -itemcolor Gold /test_module_tb/m_bayer/m_core/i_fsm_ctrl
add wave -noupdate -radix hexadecimal /test_module_tb/m_bayer/m_core/i_cntline
add wave -noupdate /test_module_tb/m_bayer/m_core/i_dwnp_en
add wave -noupdate /test_module_tb/m_bayer/m_core/sr_dwnp_en
add wave -noupdate -radix hexadecimal /test_module_tb/m_bayer/m_core/i_buf_wr
add wave -noupdate -radix hexadecimal -childformat {{/test_module_tb/m_bayer/m_core/i_buf_do(0) -radix hexadecimal} {/test_module_tb/m_bayer/m_core/i_buf_do(1) -radix hexadecimal} {/test_module_tb/m_bayer/m_core/i_buf_do(2) -radix hexadecimal}} -expand -subitemconfig {/test_module_tb/m_bayer/m_core/i_buf_do(0) {-height 15 -radix hexadecimal} /test_module_tb/m_bayer/m_core/i_buf_do(1) {-height 15 -radix hexadecimal} /test_module_tb/m_bayer/m_core/i_buf_do(2) {-height 15 -radix hexadecimal}} /test_module_tb/m_bayer/m_core/i_buf_do
add wave -noupdate -radix hexadecimal -childformat {{/test_module_tb/m_bayer/m_core/i_matrix(0) -radix hexadecimal -childformat {{/test_module_tb/m_bayer/m_core/i_matrix(0)(0) -radix hexadecimal} {/test_module_tb/m_bayer/m_core/i_matrix(0)(1) -radix hexadecimal} {/test_module_tb/m_bayer/m_core/i_matrix(0)(2) -radix hexadecimal}}} {/test_module_tb/m_bayer/m_core/i_matrix(1) -radix hexadecimal -childformat {{/test_module_tb/m_bayer/m_core/i_matrix(1)(0) -radix hexadecimal} {/test_module_tb/m_bayer/m_core/i_matrix(1)(1) -radix hexadecimal} {/test_module_tb/m_bayer/m_core/i_matrix(1)(2) -radix hexadecimal}}} {/test_module_tb/m_bayer/m_core/i_matrix(2) -radix hexadecimal -childformat {{/test_module_tb/m_bayer/m_core/i_matrix(2)(0) -radix hexadecimal} {/test_module_tb/m_bayer/m_core/i_matrix(2)(1) -radix hexadecimal} {/test_module_tb/m_bayer/m_core/i_matrix(2)(2) -radix hexadecimal}}}} -subitemconfig {/test_module_tb/m_bayer/m_core/i_matrix(0) {-height 15 -radix hexadecimal -childformat {{/test_module_tb/m_bayer/m_core/i_matrix(0)(0) -radix hexadecimal} {/test_module_tb/m_bayer/m_core/i_matrix(0)(1) -radix hexadecimal} {/test_module_tb/m_bayer/m_core/i_matrix(0)(2) -radix hexadecimal}} -expand} /test_module_tb/m_bayer/m_core/i_matrix(0)(0) {-height 15 -radix hexadecimal} /test_module_tb/m_bayer/m_core/i_matrix(0)(1) {-height 15 -radix hexadecimal} /test_module_tb/m_bayer/m_core/i_matrix(0)(2) {-height 15 -radix hexadecimal} /test_module_tb/m_bayer/m_core/i_matrix(1) {-height 15 -radix hexadecimal -childformat {{/test_module_tb/m_bayer/m_core/i_matrix(1)(0) -radix hexadecimal} {/test_module_tb/m_bayer/m_core/i_matrix(1)(1) -radix hexadecimal} {/test_module_tb/m_bayer/m_core/i_matrix(1)(2) -radix hexadecimal}} -expand} /test_module_tb/m_bayer/m_core/i_matrix(1)(0) {-height 15 -radix hexadecimal} /test_module_tb/m_bayer/m_core/i_matrix(1)(1) {-height 15 -radix hexadecimal} /test_module_tb/m_bayer/m_core/i_matrix(1)(2) {-height 15 -radix hexadecimal} /test_module_tb/m_bayer/m_core/i_matrix(2) {-height 15 -radix hexadecimal -childformat {{/test_module_tb/m_bayer/m_core/i_matrix(2)(0) -radix hexadecimal} {/test_module_tb/m_bayer/m_core/i_matrix(2)(1) -radix hexadecimal} {/test_module_tb/m_bayer/m_core/i_matrix(2)(2) -radix hexadecimal}} -expand} /test_module_tb/m_bayer/m_core/i_matrix(2)(0) {-height 15 -radix hexadecimal} /test_module_tb/m_bayer/m_core/i_matrix(2)(1) {-height 15 -radix hexadecimal} /test_module_tb/m_bayer/m_core/i_matrix(2)(2) {-height 15 -radix hexadecimal}} /test_module_tb/m_bayer/m_core/i_matrix
add wave -noupdate /test_module_tb/m_bayer/m_core/p_in_dwnp_rdy_n
add wave -noupdate /test_module_tb/m_bayer/m_core/p_out_line_evod
add wave -noupdate /test_module_tb/m_bayer/m_core/p_out_pix_evod
add wave -noupdate /test_module_tb/m_bayer/m_core/sr_buf_wr(2)
add wave -noupdate -radix hexadecimal /test_module_tb/m_bayer/m_core/i_buf_do(2)
add wave -noupdate /test_module_tb/m_bayer/m_core/sr_buf_wr(1)
add wave -noupdate /test_module_tb/m_bayer/m_core/sr_eol(0)
add wave -noupdate -radix hexadecimal /test_module_tb/m_bayer/m_core/i_buf_do(1)
add wave -noupdate /test_module_tb/m_bayer/m_core/sr_buf_wr(0)
add wave -noupdate /test_module_tb/m_bayer/m_core/sr_eol(1)
add wave -noupdate -radix hexadecimal /test_module_tb/m_bayer/m_core/i_buf_do(0)
add wave -noupdate /test_module_tb/m_bayer/m_core/sr_buf_wr(0)
add wave -noupdate /test_module_tb/m_bayer/m_core/sr_matrix_wr(0)
add wave -noupdate /test_module_tb/m_bayer/m_core/sr_buf_wr
add wave -noupdate /test_module_tb/m_bayer/m_core/p_out_dwnp_wr
add wave -noupdate /test_module_tb/m_bayer/m_core/p_out_dwnp_eol
add wave -noupdate /test_module_tb/m_bayer/m_core/p_out_dwnp_eof
add wave -noupdate -radix hexadecimal -childformat {{/test_module_tb/m_bayer/m_core/p_out_matrix(0) -radix hexadecimal -childformat {{/test_module_tb/m_bayer/m_core/p_out_matrix(0)(0) -radix hexadecimal} {/test_module_tb/m_bayer/m_core/p_out_matrix(0)(1) -radix hexadecimal} {/test_module_tb/m_bayer/m_core/p_out_matrix(0)(2) -radix hexadecimal}}} {/test_module_tb/m_bayer/m_core/p_out_matrix(1) -radix hexadecimal -childformat {{/test_module_tb/m_bayer/m_core/p_out_matrix(1)(0) -radix hexadecimal} {/test_module_tb/m_bayer/m_core/p_out_matrix(1)(1) -radix hexadecimal} {/test_module_tb/m_bayer/m_core/p_out_matrix(1)(2) -radix hexadecimal}}} {/test_module_tb/m_bayer/m_core/p_out_matrix(2) -radix hexadecimal -childformat {{/test_module_tb/m_bayer/m_core/p_out_matrix(2)(0) -radix hexadecimal} {/test_module_tb/m_bayer/m_core/p_out_matrix(2)(1) -radix hexadecimal} {/test_module_tb/m_bayer/m_core/p_out_matrix(2)(2) -radix hexadecimal}}}} -expand -subitemconfig {/test_module_tb/m_bayer/m_core/p_out_matrix(0) {-height 15 -radix hexadecimal -childformat {{/test_module_tb/m_bayer/m_core/p_out_matrix(0)(0) -radix hexadecimal} {/test_module_tb/m_bayer/m_core/p_out_matrix(0)(1) -radix hexadecimal} {/test_module_tb/m_bayer/m_core/p_out_matrix(0)(2) -radix hexadecimal}} -expand} /test_module_tb/m_bayer/m_core/p_out_matrix(0)(0) {-height 15 -radix hexadecimal} /test_module_tb/m_bayer/m_core/p_out_matrix(0)(1) {-height 15 -radix hexadecimal} /test_module_tb/m_bayer/m_core/p_out_matrix(0)(2) {-height 15 -radix hexadecimal} /test_module_tb/m_bayer/m_core/p_out_matrix(1) {-height 15 -radix hexadecimal -childformat {{/test_module_tb/m_bayer/m_core/p_out_matrix(1)(0) -radix hexadecimal} {/test_module_tb/m_bayer/m_core/p_out_matrix(1)(1) -radix hexadecimal} {/test_module_tb/m_bayer/m_core/p_out_matrix(1)(2) -radix hexadecimal}} -expand} /test_module_tb/m_bayer/m_core/p_out_matrix(1)(0) {-height 15 -radix hexadecimal} /test_module_tb/m_bayer/m_core/p_out_matrix(1)(1) {-height 15 -radix hexadecimal} /test_module_tb/m_bayer/m_core/p_out_matrix(1)(2) {-height 15 -radix hexadecimal} /test_module_tb/m_bayer/m_core/p_out_matrix(2) {-height 15 -radix hexadecimal -childformat {{/test_module_tb/m_bayer/m_core/p_out_matrix(2)(0) -radix hexadecimal} {/test_module_tb/m_bayer/m_core/p_out_matrix(2)(1) -radix hexadecimal} {/test_module_tb/m_bayer/m_core/p_out_matrix(2)(2) -radix hexadecimal}} -expand} /test_module_tb/m_bayer/m_core/p_out_matrix(2)(0) {-height 15 -radix hexadecimal} /test_module_tb/m_bayer/m_core/p_out_matrix(2)(1) {-height 15 -radix hexadecimal} /test_module_tb/m_bayer/m_core/p_out_matrix(2)(2) {-height 15 -radix hexadecimal}} /test_module_tb/m_bayer/m_core/p_out_matrix
add wave -noupdate -radix hexadecimal /test_module_tb/m_vmirx/p_in_cfg_mirx
add wave -noupdate -radix hexadecimal /test_module_tb/m_vmirx/p_in_cfg_pix_count
add wave -noupdate /test_module_tb/i_fsm_cs
add wave -noupdate -radix hexadecimal /test_module_tb/i_cntpix
add wave -noupdate -radix hexadecimal /test_module_tb/i_cntline
add wave -noupdate -radix hexadecimal /test_module_tb/m_vmirx/p_in_upp_data
add wave -noupdate -radix hexadecimal /test_module_tb/m_vmirx/p_in_upp_wr
add wave -noupdate -radix hexadecimal /test_module_tb/m_vmirx/p_out_upp_rdy_n
add wave -noupdate -color {Cornflower Blue} -itemcolor Gold -radix hexadecimal /test_module_tb/m_vmirx/i_fsm_cs
add wave -noupdate -radix hexadecimal /test_module_tb/m_vmirx/i_mirx_done
add wave -noupdate -radix hexadecimal /test_module_tb/m_vmirx/i_buf_adr
add wave -noupdate -radix hexadecimal /test_module_tb/m_vmirx/i_buf_di
add wave -noupdate -radix hexadecimal /test_module_tb/m_vmirx/i_buf_do
add wave -noupdate -radix hexadecimal /test_module_tb/m_vmirx/i_buf_enb
add wave -noupdate -radix hexadecimal /test_module_tb/m_vmirx/i_read_en
add wave -noupdate -radix hexadecimal /test_module_tb/m_vmirx/p_out_dwnp_data
add wave -noupdate -radix hexadecimal /test_module_tb/m_vmirx/p_out_dwnp_wr
add wave -noupdate -radix hexadecimal /test_module_tb/m_vmirx/p_in_dwnp_rdy_n
add wave -noupdate /test_module_tb/m_vmirx/p_out_dwnp_eof
add wave -noupdate -divider {New Divider}
add wave -noupdate -radix hexadecimal /test_module_tb/m_bayer/m_core/p_in_cfg_pix_count
add wave -noupdate -radix hexadecimal /test_module_tb/m_bayer/m_core/p_in_upp_data
add wave -noupdate -radix hexadecimal /test_module_tb/m_bayer/m_core/p_in_upp_wr
add wave -noupdate -radix hexadecimal /test_module_tb/m_bayer/m_core/p_out_upp_rdy_n
add wave -noupdate -radix hexadecimal /test_module_tb/m_bayer/m_core/p_in_upp_eof
add wave -noupdate -radix hexadecimal /test_module_tb/m_bayer/m_core/i_buf_adr
add wave -noupdate /test_module_tb/m_bayer/m_core/sr_sol
add wave -noupdate /test_module_tb/m_bayer/m_core/i_eol
add wave -noupdate /test_module_tb/m_bayer/m_core/sr_eol
add wave -noupdate /test_module_tb/m_bayer/m_core/i_eol_en
add wave -noupdate /test_module_tb/m_bayer/m_core/i_eof_en
add wave -noupdate /test_module_tb/m_bayer/m_core/i_eof
add wave -noupdate -color {Cornflower Blue} -itemcolor Gold /test_module_tb/m_bayer/m_core/i_fsm_ctrl
add wave -noupdate -radix hexadecimal /test_module_tb/m_bayer/m_core/i_cntline
add wave -noupdate /test_module_tb/m_bayer/m_core/i_dwnp_en
add wave -noupdate /test_module_tb/m_bayer/m_core/sr_dwnp_en
add wave -noupdate -radix hexadecimal /test_module_tb/m_bayer/m_core/i_buf_wr
add wave -noupdate -radix hexadecimal -childformat {{/test_module_tb/m_bayer/m_core/i_buf_do(0) -radix hexadecimal} {/test_module_tb/m_bayer/m_core/i_buf_do(1) -radix hexadecimal} {/test_module_tb/m_bayer/m_core/i_buf_do(2) -radix hexadecimal}} -expand -subitemconfig {/test_module_tb/m_bayer/m_core/i_buf_do(0) {-height 15 -radix hexadecimal} /test_module_tb/m_bayer/m_core/i_buf_do(1) {-height 15 -radix hexadecimal} /test_module_tb/m_bayer/m_core/i_buf_do(2) {-height 15 -radix hexadecimal}} /test_module_tb/m_bayer/m_core/i_buf_do
add wave -noupdate -radix hexadecimal -childformat {{/test_module_tb/m_bayer/m_core/p_out_matrix(0) -radix hexadecimal -childformat {{/test_module_tb/m_bayer/m_core/p_out_matrix(0)(0) -radix hexadecimal} {/test_module_tb/m_bayer/m_core/p_out_matrix(0)(1) -radix hexadecimal} {/test_module_tb/m_bayer/m_core/p_out_matrix(0)(2) -radix hexadecimal}}} {/test_module_tb/m_bayer/m_core/p_out_matrix(1) -radix hexadecimal -childformat {{/test_module_tb/m_bayer/m_core/p_out_matrix(1)(0) -radix hexadecimal} {/test_module_tb/m_bayer/m_core/p_out_matrix(1)(1) -radix hexadecimal} {/test_module_tb/m_bayer/m_core/p_out_matrix(1)(2) -radix hexadecimal}}} {/test_module_tb/m_bayer/m_core/p_out_matrix(2) -radix hexadecimal -childformat {{/test_module_tb/m_bayer/m_core/p_out_matrix(2)(0) -radix hexadecimal} {/test_module_tb/m_bayer/m_core/p_out_matrix(2)(1) -radix hexadecimal} {/test_module_tb/m_bayer/m_core/p_out_matrix(2)(2) -radix hexadecimal}}}} -subitemconfig {/test_module_tb/m_bayer/m_core/p_out_matrix(0) {-radix hexadecimal -childformat {{/test_module_tb/m_bayer/m_core/p_out_matrix(0)(0) -radix hexadecimal} {/test_module_tb/m_bayer/m_core/p_out_matrix(0)(1) -radix hexadecimal} {/test_module_tb/m_bayer/m_core/p_out_matrix(0)(2) -radix hexadecimal}} -expand} /test_module_tb/m_bayer/m_core/p_out_matrix(0)(0) {-radix hexadecimal} /test_module_tb/m_bayer/m_core/p_out_matrix(0)(1) {-radix hexadecimal} /test_module_tb/m_bayer/m_core/p_out_matrix(0)(2) {-radix hexadecimal} /test_module_tb/m_bayer/m_core/p_out_matrix(1) {-radix hexadecimal -childformat {{/test_module_tb/m_bayer/m_core/p_out_matrix(1)(0) -radix hexadecimal} {/test_module_tb/m_bayer/m_core/p_out_matrix(1)(1) -radix hexadecimal} {/test_module_tb/m_bayer/m_core/p_out_matrix(1)(2) -radix hexadecimal}} -expand} /test_module_tb/m_bayer/m_core/p_out_matrix(1)(0) {-radix hexadecimal} /test_module_tb/m_bayer/m_core/p_out_matrix(1)(1) {-radix hexadecimal} /test_module_tb/m_bayer/m_core/p_out_matrix(1)(2) {-radix hexadecimal} /test_module_tb/m_bayer/m_core/p_out_matrix(2) {-radix hexadecimal -childformat {{/test_module_tb/m_bayer/m_core/p_out_matrix(2)(0) -radix hexadecimal} {/test_module_tb/m_bayer/m_core/p_out_matrix(2)(1) -radix hexadecimal} {/test_module_tb/m_bayer/m_core/p_out_matrix(2)(2) -radix hexadecimal}} -expand} /test_module_tb/m_bayer/m_core/p_out_matrix(2)(0) {-radix hexadecimal} /test_module_tb/m_bayer/m_core/p_out_matrix(2)(1) {-radix hexadecimal} /test_module_tb/m_bayer/m_core/p_out_matrix(2)(2) {-radix hexadecimal}} /test_module_tb/m_bayer/m_core/p_out_matrix
add wave -noupdate /test_module_tb/m_bayer/m_core/p_out_dwnp_wr
add wave -noupdate -radix hexadecimal /test_module_tb/p_out_dwnp_data
add wave -noupdate -radix hexadecimal /test_module_tb/p_out_dwnp_wr
add wave -noupdate -radix hexadecimal /test_module_tb/p_out_dwnp_eof
add wave -noupdate /test_module_tb/m_bayer/m_core/i_pix_evod
add wave -noupdate /test_module_tb/m_bayer/m_core/i_line_evod
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {0 ps} 0}
quietly wave cursor active 0
configure wave -namecolwidth 158
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
WaveRestoreZoom {590355 ps} {3759251 ps}
