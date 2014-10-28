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
add wave -noupdate -radix hexadecimal /test_module_tb/m_vmirx/i_fsm_cs
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
add wave -noupdate -radix hexadecimal /test_module_tb/m_bayer/m_core/i_buf_wr
add wave -noupdate -radix hexadecimal /test_module_tb/m_bayer/m_core/i_buf_adr
add wave -noupdate /test_module_tb/m_bayer/m_core/i_eol
add wave -noupdate /test_module_tb/m_bayer/m_core/sr_eol(2)
add wave -noupdate /test_module_tb/m_bayer/m_core/i_eof
add wave -noupdate -radix hexadecimal -childformat {{/test_module_tb/m_bayer/m_core/i_buf_do(0) -radix hexadecimal} {/test_module_tb/m_bayer/m_core/i_buf_do(1) -radix hexadecimal} {/test_module_tb/m_bayer/m_core/i_buf_do(2) -radix hexadecimal}} -expand -subitemconfig {/test_module_tb/m_bayer/m_core/i_buf_do(0) {-height 15 -radix hexadecimal} /test_module_tb/m_bayer/m_core/i_buf_do(1) {-height 15 -radix hexadecimal} /test_module_tb/m_bayer/m_core/i_buf_do(2) {-height 15 -radix hexadecimal}} /test_module_tb/m_bayer/m_core/i_buf_do
add wave -noupdate -radix hexadecimal /test_module_tb/m_bayer/m_core/i_dwnp_en
add wave -noupdate -radix hexadecimal /test_module_tb/m_bayer/m_core/i_cnteof
add wave -noupdate -radix hexadecimal /test_module_tb/m_bayer/m_core/i_matrix_wr
add wave -noupdate -radix hexadecimal -childformat {{/test_module_tb/m_bayer/m_core/i_matrix(0) -radix hexadecimal -childformat {{/test_module_tb/m_bayer/m_core/i_matrix(0)(0) -radix hexadecimal} {/test_module_tb/m_bayer/m_core/i_matrix(0)(1) -radix hexadecimal} {/test_module_tb/m_bayer/m_core/i_matrix(0)(2) -radix hexadecimal}}} {/test_module_tb/m_bayer/m_core/i_matrix(1) -radix hexadecimal -childformat {{/test_module_tb/m_bayer/m_core/i_matrix(1)(0) -radix hexadecimal} {/test_module_tb/m_bayer/m_core/i_matrix(1)(1) -radix hexadecimal} {/test_module_tb/m_bayer/m_core/i_matrix(1)(2) -radix hexadecimal}}} {/test_module_tb/m_bayer/m_core/i_matrix(2) -radix hexadecimal -childformat {{/test_module_tb/m_bayer/m_core/i_matrix(2)(0) -radix hexadecimal} {/test_module_tb/m_bayer/m_core/i_matrix(2)(1) -radix hexadecimal} {/test_module_tb/m_bayer/m_core/i_matrix(2)(2) -radix hexadecimal}}}} -expand -subitemconfig {/test_module_tb/m_bayer/m_core/i_matrix(0) {-radix hexadecimal -childformat {{/test_module_tb/m_bayer/m_core/i_matrix(0)(0) -radix hexadecimal} {/test_module_tb/m_bayer/m_core/i_matrix(0)(1) -radix hexadecimal} {/test_module_tb/m_bayer/m_core/i_matrix(0)(2) -radix hexadecimal}} -expand} /test_module_tb/m_bayer/m_core/i_matrix(0)(0) {-radix hexadecimal} /test_module_tb/m_bayer/m_core/i_matrix(0)(1) {-radix hexadecimal} /test_module_tb/m_bayer/m_core/i_matrix(0)(2) {-radix hexadecimal} /test_module_tb/m_bayer/m_core/i_matrix(1) {-radix hexadecimal -childformat {{/test_module_tb/m_bayer/m_core/i_matrix(1)(0) -radix hexadecimal} {/test_module_tb/m_bayer/m_core/i_matrix(1)(1) -radix hexadecimal} {/test_module_tb/m_bayer/m_core/i_matrix(1)(2) -radix hexadecimal}} -expand} /test_module_tb/m_bayer/m_core/i_matrix(1)(0) {-radix hexadecimal} /test_module_tb/m_bayer/m_core/i_matrix(1)(1) {-radix hexadecimal} /test_module_tb/m_bayer/m_core/i_matrix(1)(2) {-radix hexadecimal} /test_module_tb/m_bayer/m_core/i_matrix(2) {-radix hexadecimal -childformat {{/test_module_tb/m_bayer/m_core/i_matrix(2)(0) -radix hexadecimal} {/test_module_tb/m_bayer/m_core/i_matrix(2)(1) -radix hexadecimal} {/test_module_tb/m_bayer/m_core/i_matrix(2)(2) -radix hexadecimal}} -expand} /test_module_tb/m_bayer/m_core/i_matrix(2)(0) {-radix hexadecimal} /test_module_tb/m_bayer/m_core/i_matrix(2)(1) {-radix hexadecimal} /test_module_tb/m_bayer/m_core/i_matrix(2)(2) {-radix hexadecimal}} /test_module_tb/m_bayer/m_core/i_matrix
TreeUpdate [SetDefaultTree]
WaveRestoreCursors
quietly wave cursor active 0
configure wave -namecolwidth 205
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
WaveRestoreZoom {1867884 ps} {3318536 ps}
