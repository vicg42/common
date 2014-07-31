onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /vtest_gen_tb/i_rst
add wave -noupdate /vtest_gen_tb/i_clk
add wave -noupdate -radix unsigned /vtest_gen_tb/tst_vfr_pixcount
add wave -noupdate -radix unsigned /vtest_gen_tb/tst_vfr_rowcount
add wave -noupdate -radix unsigned /vtest_gen_tb/tst_vfr_cfg
add wave -noupdate -radix unsigned /vtest_gen_tb/tst_vfr_synwidth
add wave -noupdate -radix hexadecimal /vtest_gen_tb/p_out_vd
add wave -noupdate /vtest_gen_tb/i_video_den
add wave -noupdate /vtest_gen_tb/p_out_vs
add wave -noupdate /vtest_gen_tb/p_out_hs
add wave -noupdate /vtest_gen_tb/uut/i_row_half
add wave -noupdate -radix hexadecimal /vtest_gen_tb/uut/i_pix_cnt
add wave -noupdate -radix hexadecimal /vtest_gen_tb/uut/i_row_cnt
add wave -noupdate -radix unsigned -childformat {{/vtest_gen_tb/uut/i_vd(0) -radix unsigned} {/vtest_gen_tb/uut/i_vd(1) -radix unsigned} {/vtest_gen_tb/uut/i_vd(2) -radix unsigned} {/vtest_gen_tb/uut/i_vd(3) -radix unsigned}} -subitemconfig {/vtest_gen_tb/uut/i_vd(0) {-height 15 -radix unsigned} /vtest_gen_tb/uut/i_vd(1) {-height 15 -radix unsigned} /vtest_gen_tb/uut/i_vd(2) {-height 15 -radix unsigned} /vtest_gen_tb/uut/i_vd(3) {-height 15 -radix unsigned}} /vtest_gen_tb/uut/i_vd
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {0 ps} 0} {{Cursor 2} {102298803476 ps} 0}
quietly wave cursor active 2
configure wave -namecolwidth 229
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 0
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
WaveRestoreZoom {14590346209 ps} {18168926401 ps}
