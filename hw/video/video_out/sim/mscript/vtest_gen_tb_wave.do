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
add wave -noupdate -radix unsigned -childformat {{/vtest_gen_tb/uut/i_vd(0) -radix unsigned} {/vtest_gen_tb/uut/i_vd(1) -radix unsigned} {/vtest_gen_tb/uut/i_vd(2) -radix unsigned} {/vtest_gen_tb/uut/i_vd(3) -radix unsigned} {/vtest_gen_tb/uut/i_vd(4) -radix unsigned} {/vtest_gen_tb/uut/i_vd(5) -radix unsigned} {/vtest_gen_tb/uut/i_vd(6) -radix unsigned} {/vtest_gen_tb/uut/i_vd(7) -radix unsigned} {/vtest_gen_tb/uut/i_vd(8) -radix unsigned} {/vtest_gen_tb/uut/i_vd(9) -radix unsigned} {/vtest_gen_tb/uut/i_vd(10) -radix unsigned} {/vtest_gen_tb/uut/i_vd(11) -radix unsigned} {/vtest_gen_tb/uut/i_vd(12) -radix unsigned} {/vtest_gen_tb/uut/i_vd(13) -radix unsigned} {/vtest_gen_tb/uut/i_vd(14) -radix unsigned} {/vtest_gen_tb/uut/i_vd(15) -radix unsigned} {/vtest_gen_tb/uut/i_vd(16) -radix unsigned} {/vtest_gen_tb/uut/i_vd(17) -radix unsigned} {/vtest_gen_tb/uut/i_vd(18) -radix unsigned} {/vtest_gen_tb/uut/i_vd(19) -radix unsigned} {/vtest_gen_tb/uut/i_vd(20) -radix unsigned} {/vtest_gen_tb/uut/i_vd(21) -radix unsigned} {/vtest_gen_tb/uut/i_vd(22) -radix unsigned} {/vtest_gen_tb/uut/i_vd(23) -radix unsigned} {/vtest_gen_tb/uut/i_vd(24) -radix unsigned} {/vtest_gen_tb/uut/i_vd(25) -radix unsigned} {/vtest_gen_tb/uut/i_vd(26) -radix unsigned} {/vtest_gen_tb/uut/i_vd(27) -radix unsigned} {/vtest_gen_tb/uut/i_vd(28) -radix unsigned} {/vtest_gen_tb/uut/i_vd(29) -radix unsigned} {/vtest_gen_tb/uut/i_vd(30) -radix unsigned} {/vtest_gen_tb/uut/i_vd(31) -radix unsigned}} -subitemconfig {/vtest_gen_tb/uut/i_vd(0) {-height 15 -radix unsigned} /vtest_gen_tb/uut/i_vd(1) {-height 15 -radix unsigned} /vtest_gen_tb/uut/i_vd(2) {-height 15 -radix unsigned} /vtest_gen_tb/uut/i_vd(3) {-height 15 -radix unsigned} /vtest_gen_tb/uut/i_vd(4) {-height 15 -radix unsigned} /vtest_gen_tb/uut/i_vd(5) {-height 15 -radix unsigned} /vtest_gen_tb/uut/i_vd(6) {-height 15 -radix unsigned} /vtest_gen_tb/uut/i_vd(7) {-height 15 -radix unsigned} /vtest_gen_tb/uut/i_vd(8) {-height 15 -radix unsigned} /vtest_gen_tb/uut/i_vd(9) {-height 15 -radix unsigned} /vtest_gen_tb/uut/i_vd(10) {-height 15 -radix unsigned} /vtest_gen_tb/uut/i_vd(11) {-height 15 -radix unsigned} /vtest_gen_tb/uut/i_vd(12) {-height 15 -radix unsigned} /vtest_gen_tb/uut/i_vd(13) {-height 15 -radix unsigned} /vtest_gen_tb/uut/i_vd(14) {-height 15 -radix unsigned} /vtest_gen_tb/uut/i_vd(15) {-height 15 -radix unsigned} /vtest_gen_tb/uut/i_vd(16) {-height 15 -radix unsigned} /vtest_gen_tb/uut/i_vd(17) {-height 15 -radix unsigned} /vtest_gen_tb/uut/i_vd(18) {-height 15 -radix unsigned} /vtest_gen_tb/uut/i_vd(19) {-height 15 -radix unsigned} /vtest_gen_tb/uut/i_vd(20) {-height 15 -radix unsigned} /vtest_gen_tb/uut/i_vd(21) {-height 15 -radix unsigned} /vtest_gen_tb/uut/i_vd(22) {-height 15 -radix unsigned} /vtest_gen_tb/uut/i_vd(23) {-height 15 -radix unsigned} /vtest_gen_tb/uut/i_vd(24) {-height 15 -radix unsigned} /vtest_gen_tb/uut/i_vd(25) {-height 15 -radix unsigned} /vtest_gen_tb/uut/i_vd(26) {-height 15 -radix unsigned} /vtest_gen_tb/uut/i_vd(27) {-height 15 -radix unsigned} /vtest_gen_tb/uut/i_vd(28) {-height 15 -radix unsigned} /vtest_gen_tb/uut/i_vd(29) {-height 15 -radix unsigned} /vtest_gen_tb/uut/i_vd(30) {-height 15 -radix unsigned} /vtest_gen_tb/uut/i_vd(31) {-height 15 -radix unsigned}} /vtest_gen_tb/uut/i_vd
add wave -noupdate -color {Slate Blue} -itemcolor Gold /vtest_gen_tb/uut/fsm_cs
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {0 ps} 0}
quietly wave cursor active 1
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
WaveRestoreZoom {116593420328 ps} {116677649550 ps}
