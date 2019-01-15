onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /filter_blur_tb/clk
add wave -noupdate /filter_blur_tb/filter_blur/di_i
add wave -noupdate /filter_blur_tb/filter_blur/de_i
add wave -noupdate /filter_blur_tb/filter_blur/hs_i
add wave -noupdate /filter_blur_tb/filter_blur/vs_i
add wave -noupdate -divider {New Divider}
add wave -noupdate /filter_blur_tb/filter_blur/filter_core/bypass
add wave -noupdate /filter_blur_tb/filter_blur/filter_core/sr_hs
add wave -noupdate /filter_blur_tb/filter_blur/sr_hs
add wave -noupdate /filter_blur_tb/filter_blur/sr_vs
add wave -noupdate -divider {New Divider}
add wave -noupdate -radix unsigned /filter_blur_tb/filter_blur/filter_core/x1
add wave -noupdate -radix unsigned /filter_blur_tb/filter_blur/filter_core/x2
add wave -noupdate -radix unsigned /filter_blur_tb/filter_blur/filter_core/x3
add wave -noupdate -color {Cornflower Blue} /filter_blur_tb/filter_blur/sum_p32
add wave -noupdate -color {Cornflower Blue} /filter_blur_tb/filter_blur/sum_p321
add wave -noupdate -divider {New Divider}
add wave -noupdate -radix unsigned /filter_blur_tb/filter_blur/filter_core/x4
add wave -noupdate -radix unsigned /filter_blur_tb/filter_blur/filter_core/x5
add wave -noupdate -radix unsigned /filter_blur_tb/filter_blur/filter_core/x6
add wave -noupdate -color {Cornflower Blue} -radix unsigned /filter_blur_tb/filter_blur/sum_p65
add wave -noupdate -color {Cornflower Blue} -radix unsigned /filter_blur_tb/filter_blur/sum_p654
add wave -noupdate -divider {New Divider}
add wave -noupdate -radix unsigned /filter_blur_tb/filter_blur/filter_core/x7
add wave -noupdate -radix unsigned /filter_blur_tb/filter_blur/filter_core/x8
add wave -noupdate -radix unsigned /filter_blur_tb/filter_blur/filter_core/x9
add wave -noupdate -color {Cornflower Blue} -radix unsigned /filter_blur_tb/filter_blur/sum_p98
add wave -noupdate -color {Cornflower Blue} -radix unsigned /filter_blur_tb/filter_blur/sum_p987
add wave -noupdate -divider {New Divider}
add wave -noupdate -radix unsigned /filter_blur_tb/filter_blur/sum_p987654
add wave -noupdate -radix unsigned /filter_blur_tb/filter_blur/sum_p987654321
add wave -noupdate -divider {New Divider}
add wave -noupdate /filter_blur_tb/do_o
add wave -noupdate /filter_blur_tb/de_o
add wave -noupdate /filter_blur_tb/hs_o
add wave -noupdate /filter_blur_tb/vs_o
add wave -noupdate -radix unsigned /filter_blur_tb/monitor/xcnt
add wave -noupdate -radix unsigned /filter_blur_tb/monitor/ycnt
add wave -noupdate -radix unsigned /filter_blur_tb/monitor/frcnt
add wave -noupdate -radix unsigned /filter_blur_tb/monitor/data_size
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {230719 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 253
configure wave -valuecolwidth 47
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
configure wave -timelineunits ns
update
WaveRestoreZoom {0 ps} {2285329 ps}
