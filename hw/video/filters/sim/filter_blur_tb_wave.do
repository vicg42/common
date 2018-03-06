onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /filter_blur_tb/clk
add wave -noupdate -radix unsigned /filter_blur_tb/in_xcnt
add wave -noupdate -radix unsigned /filter_blur_tb/in_ycnt
add wave -noupdate -radix unsigned /filter_blur_tb/filter_blur/d_in
add wave -noupdate /filter_blur_tb/filter_blur/dv_in
add wave -noupdate /filter_blur_tb/filter_blur/hs_in
add wave -noupdate /filter_blur_tb/filter_blur/vs_in
add wave -noupdate -divider {New Divider}
add wave -noupdate /filter_blur_tb/filter_blur/filter_core/bypass
add wave -noupdate -radix unsigned /filter_blur_tb/filter_blur/filter_core/line_buf_wptr
add wave -noupdate -radix unsigned /filter_blur_tb/filter_blur/filter_core/line_bufa_out
add wave -noupdate -radix unsigned /filter_blur_tb/filter_blur/filter_core/line_bufb_out
add wave -noupdate -radix unsigned -childformat {{{/filter_blur_tb/filter_blur/filter_core/sr_d_in[2]} -radix unsigned} {{/filter_blur_tb/filter_blur/filter_core/sr_d_in[1]} -radix unsigned} {{/filter_blur_tb/filter_blur/filter_core/sr_d_in[0]} -radix unsigned}} -expand -subitemconfig {{/filter_blur_tb/filter_blur/filter_core/sr_d_in[2]} {-radix unsigned} {/filter_blur_tb/filter_blur/filter_core/sr_d_in[1]} {-radix unsigned} {/filter_blur_tb/filter_blur/filter_core/sr_d_in[0]} {-radix unsigned}} /filter_blur_tb/filter_blur/filter_core/sr_d_in
add wave -noupdate /filter_blur_tb/filter_blur/filter_core/sr_hs
add wave -noupdate /filter_blur_tb/filter_blur/filter_core/vs_in_d
add wave -noupdate /filter_blur_tb/filter_blur/filter_core/vs_in_dd
add wave -noupdate -radix unsigned -childformat {{{/filter_blur_tb/filter_blur/filter_core/bypass_delay[4]} -radix unsigned} {{/filter_blur_tb/filter_blur/filter_core/bypass_delay[3]} -radix unsigned} {{/filter_blur_tb/filter_blur/filter_core/bypass_delay[2]} -radix unsigned}} -subitemconfig {{/filter_blur_tb/filter_blur/filter_core/bypass_delay[4]} {-height 15 -radix unsigned} {/filter_blur_tb/filter_blur/filter_core/bypass_delay[3]} {-height 15 -radix unsigned} {/filter_blur_tb/filter_blur/filter_core/bypass_delay[2]} {-height 15 -radix unsigned}} /filter_blur_tb/filter_blur/filter_core/bypass_delay
add wave -noupdate /filter_blur_tb/filter_blur/filter_core/d_out
add wave -noupdate /filter_blur_tb/filter_blur/filter_core/dv_out
add wave -noupdate /filter_blur_tb/filter_blur/filter_core/hs_out
add wave -noupdate /filter_blur_tb/filter_blur/filter_core/vs_out
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
add wave -noupdate -radix unsigned /filter_blur_tb/filter_blur/dout
add wave -noupdate /filter_blur_tb/filter_blur/dv_out
add wave -noupdate /filter_blur_tb/filter_blur/hs_out
add wave -noupdate /filter_blur_tb/filter_blur/vs_out
add wave -noupdate /filter_blur_tb/filter_blur/sr_dv
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {21007 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 470
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
configure wave -timelineunits ns
update
WaveRestoreZoom {15106 ps} {29242 ps}
