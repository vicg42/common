onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /vtest_gen_tb/i_rst
add wave -noupdate /vtest_gen_tb/i_clk
add wave -noupdate -radix unsigned /vtest_gen_tb/tst_vfr_pixcount
add wave -noupdate -radix unsigned /vtest_gen_tb/tst_vfr_rowcount
add wave -noupdate -radix unsigned /vtest_gen_tb/tst_vfr_cfg
add wave -noupdate -radix unsigned /vtest_gen_tb/uut/p_in_vpix
add wave -noupdate -radix unsigned /vtest_gen_tb/uut/p_in_vrow
add wave -noupdate -radix unsigned /vtest_gen_tb/uut/p_in_syn_h
add wave -noupdate -radix unsigned /vtest_gen_tb/uut/p_in_syn_v
add wave -noupdate -radix hexadecimal /vtest_gen_tb/p_out_vd
add wave -noupdate /vtest_gen_tb/p_out_vs
add wave -noupdate /vtest_gen_tb/p_out_hs
add wave -noupdate -radix hexadecimal -childformat {{/vtest_gen_tb/uut/i_cfg(15) -radix hexadecimal} {/vtest_gen_tb/uut/i_cfg(14) -radix hexadecimal} {/vtest_gen_tb/uut/i_cfg(13) -radix hexadecimal} {/vtest_gen_tb/uut/i_cfg(12) -radix hexadecimal} {/vtest_gen_tb/uut/i_cfg(11) -radix hexadecimal} {/vtest_gen_tb/uut/i_cfg(10) -radix hexadecimal} {/vtest_gen_tb/uut/i_cfg(9) -radix hexadecimal} {/vtest_gen_tb/uut/i_cfg(8) -radix hexadecimal} {/vtest_gen_tb/uut/i_cfg(7) -radix hexadecimal} {/vtest_gen_tb/uut/i_cfg(6) -radix hexadecimal} {/vtest_gen_tb/uut/i_cfg(5) -radix hexadecimal} {/vtest_gen_tb/uut/i_cfg(4) -radix hexadecimal} {/vtest_gen_tb/uut/i_cfg(3) -radix hexadecimal} {/vtest_gen_tb/uut/i_cfg(2) -radix hexadecimal} {/vtest_gen_tb/uut/i_cfg(1) -radix hexadecimal} {/vtest_gen_tb/uut/i_cfg(0) -radix hexadecimal}} -subitemconfig {/vtest_gen_tb/uut/i_cfg(15) {-height 15 -radix hexadecimal} /vtest_gen_tb/uut/i_cfg(14) {-height 15 -radix hexadecimal} /vtest_gen_tb/uut/i_cfg(13) {-height 15 -radix hexadecimal} /vtest_gen_tb/uut/i_cfg(12) {-height 15 -radix hexadecimal} /vtest_gen_tb/uut/i_cfg(11) {-height 15 -radix hexadecimal} /vtest_gen_tb/uut/i_cfg(10) {-height 15 -radix hexadecimal} /vtest_gen_tb/uut/i_cfg(9) {-height 15 -radix hexadecimal} /vtest_gen_tb/uut/i_cfg(8) {-height 15 -radix hexadecimal} /vtest_gen_tb/uut/i_cfg(7) {-height 15 -radix hexadecimal} /vtest_gen_tb/uut/i_cfg(6) {-height 15 -radix hexadecimal} /vtest_gen_tb/uut/i_cfg(5) {-height 15 -radix hexadecimal} /vtest_gen_tb/uut/i_cfg(4) {-height 15 -radix hexadecimal} /vtest_gen_tb/uut/i_cfg(3) {-height 15 -radix hexadecimal} /vtest_gen_tb/uut/i_cfg(2) {-height 15 -radix hexadecimal} /vtest_gen_tb/uut/i_cfg(1) {-height 15 -radix hexadecimal} /vtest_gen_tb/uut/i_cfg(0) {-height 15 -radix hexadecimal}} /vtest_gen_tb/uut/i_cfg
add wave -noupdate -color {Dark Orchid} -itemcolor Gold /vtest_gen_tb/uut/i_fsm_hs_cs
add wave -noupdate -color {Dark Orchid} -itemcolor Gold /vtest_gen_tb/uut/i_fsm_vs_cs
add wave -noupdate /vtest_gen_tb/uut/i_row_half
add wave -noupdate -radix hexadecimal /vtest_gen_tb/uut/i_pix_cnt
add wave -noupdate -radix hexadecimal /vtest_gen_tb/uut/i_row_cnt
add wave -noupdate -radix unsigned -childformat {{/vtest_gen_tb/uut/i_vd(0) -radix unsigned} {/vtest_gen_tb/uut/i_vd(1) -radix unsigned} {/vtest_gen_tb/uut/i_vd(2) -radix unsigned} {/vtest_gen_tb/uut/i_vd(3) -radix unsigned}} -subitemconfig {/vtest_gen_tb/uut/i_vd(0) {-height 15 -radix unsigned} /vtest_gen_tb/uut/i_vd(1) {-height 15 -radix unsigned} /vtest_gen_tb/uut/i_vd(2) {-height 15 -radix unsigned} /vtest_gen_tb/uut/i_vd(3) {-height 15 -radix unsigned}} /vtest_gen_tb/uut/i_vd
add wave -noupdate /vtest_gen_tb/uut/i_vs
add wave -noupdate /vtest_gen_tb/uut/i_hs
add wave -noupdate /vtest_gen_tb/sr_video_hs(3)
add wave -noupdate /vtest_gen_tb/sr_video_hs(7)
add wave -noupdate /vtest_gen_tb/sr_video_vs(3)
add wave -noupdate /vtest_gen_tb/sr_video_vs(7)
add wave -noupdate -radix hexadecimal -childformat {{/vtest_gen_tb/sr_video_hs(0) -radix hexadecimal} {/vtest_gen_tb/sr_video_hs(1) -radix hexadecimal} {/vtest_gen_tb/sr_video_hs(2) -radix hexadecimal} {/vtest_gen_tb/sr_video_hs(3) -radix hexadecimal} {/vtest_gen_tb/sr_video_hs(4) -radix hexadecimal} {/vtest_gen_tb/sr_video_hs(5) -radix hexadecimal} {/vtest_gen_tb/sr_video_hs(6) -radix hexadecimal} {/vtest_gen_tb/sr_video_hs(7) -radix hexadecimal}} -subitemconfig {/vtest_gen_tb/sr_video_hs(0) {-height 15 -radix hexadecimal} /vtest_gen_tb/sr_video_hs(1) {-height 15 -radix hexadecimal} /vtest_gen_tb/sr_video_hs(2) {-height 15 -radix hexadecimal} /vtest_gen_tb/sr_video_hs(3) {-height 15 -radix hexadecimal} /vtest_gen_tb/sr_video_hs(4) {-height 15 -radix hexadecimal} /vtest_gen_tb/sr_video_hs(5) {-height 15 -radix hexadecimal} /vtest_gen_tb/sr_video_hs(6) {-height 15 -radix hexadecimal} /vtest_gen_tb/sr_video_hs(7) {-height 15 -radix hexadecimal}} /vtest_gen_tb/sr_video_hs
add wave -noupdate /vtest_gen_tb/i_eav
add wave -noupdate /vtest_gen_tb/i_sav
add wave -noupdate -radix hexadecimal -childformat {{/vtest_gen_tb/sr_video_d(0) -radix unsigned} {/vtest_gen_tb/sr_video_d(1) -radix unsigned} {/vtest_gen_tb/sr_video_d(2) -radix unsigned} {/vtest_gen_tb/sr_video_d(3) -radix unsigned}} -subitemconfig {/vtest_gen_tb/sr_video_d(0) {-height 15 -radix unsigned} /vtest_gen_tb/sr_video_d(1) {-height 15 -radix unsigned} /vtest_gen_tb/sr_video_d(2) {-height 15 -radix unsigned} /vtest_gen_tb/sr_video_d(3) {-height 15 -radix unsigned}} /vtest_gen_tb/sr_video_d
add wave -noupdate -radix hexadecimal /vtest_gen_tb/i_tx_buf_d
add wave -noupdate -radix hexadecimal -childformat {{/vtest_gen_tb/i_tx_dout(0) -radix hexadecimal} {/vtest_gen_tb/i_tx_dout(1) -radix hexadecimal}} -expand -subitemconfig {/vtest_gen_tb/i_tx_dout(0) {-height 15 -radix hexadecimal} /vtest_gen_tb/i_tx_dout(1) {-height 15 -radix hexadecimal}} /vtest_gen_tb/i_tx_dout
add wave -noupdate -radix unsigned /vtest_gen_tb/i_linecnt
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {0 ps} 0}
quietly wave cursor active 0
configure wave -namecolwidth 137
configure wave -valuecolwidth 60
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
WaveRestoreZoom {136951509607 ps} {143925892040 ps}
