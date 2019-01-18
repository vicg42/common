onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /filter_blur_tb/clk
add wave -noupdate -radix unsigned /filter_blur_tb/filter_blur/di_i
add wave -noupdate /filter_blur_tb/filter_blur/de_i
add wave -noupdate /filter_blur_tb/filter_blur/hs_i
add wave -noupdate -divider {New Divider}
add wave -noupdate /filter_blur_tb/filter_blur/filter_core/bypass
add wave -noupdate -expand /filter_blur_tb/filter_blur/filter_core/sr_hs_i
add wave -noupdate /filter_blur_tb/filter_blur/filter_core/sr_vs_i
add wave -noupdate /filter_blur_tb/filter_blur/vs_i
add wave -noupdate {/filter_blur_tb/filter_blur/filter_core/sr_vs_i[2]}
add wave -noupdate -expand /filter_blur_tb/filter_blur/filter_core/line_out_en
add wave -noupdate /filter_blur_tb/filter_blur/filter_core/vs_opt
add wave -noupdate /filter_blur_tb/filter_blur/filter_core/dv_opt
add wave -noupdate /filter_blur_tb/filter_blur/filter_core/buf_wptr_clr
add wave -noupdate /filter_blur_tb/filter_blur/filter_core/buf_wptr_en
add wave -noupdate /filter_blur_tb/filter_blur/filter_core/buf_wptr
add wave -noupdate /filter_blur_tb/filter_blur/filter_core/de
add wave -noupdate /filter_blur_tb/filter_blur/filter_core/hs
add wave -noupdate /filter_blur_tb/filter_blur/filter_core/vs
add wave -noupdate -radix unsigned /filter_blur_tb/filter_blur/filter_core/x1
add wave -noupdate -radix unsigned /filter_blur_tb/filter_blur/filter_core/x2
add wave -noupdate -radix unsigned /filter_blur_tb/filter_blur/filter_core/x3
add wave -noupdate -radix unsigned /filter_blur_tb/filter_blur/filter_core/x4
add wave -noupdate -radix unsigned /filter_blur_tb/filter_blur/filter_core/x5
add wave -noupdate -radix unsigned /filter_blur_tb/filter_blur/filter_core/x6
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
add wave -noupdate -radix unsigned /filter_blur_tb/monitor/xcnt
add wave -noupdate -radix unsigned /filter_blur_tb/monitor/ycnt
add wave -noupdate -radix unsigned /filter_blur_tb/monitor/frcnt
add wave -noupdate -radix unsigned /filter_blur_tb/monitor/data_size
TreeUpdate [SetDefaultTree]
WaveRestoreCursors
quietly wave cursor active 0
configure wave -namecolwidth 315
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
WaveRestoreZoom {13455609 ps} {13820368 ps}
