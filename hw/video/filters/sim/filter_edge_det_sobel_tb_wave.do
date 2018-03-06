onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /filter_edge_det_sobel_tb/clk
add wave -noupdate -radix unsigned /filter_edge_det_sobel_tb/in_xcnt
add wave -noupdate -radix unsigned /filter_edge_det_sobel_tb/in_ycnt
add wave -noupdate -radix unsigned /filter_edge_det_sobel_tb/filter_edge_det_sobel/d_in
add wave -noupdate /filter_edge_det_sobel_tb/filter_edge_det_sobel/dv_in
add wave -noupdate /filter_edge_det_sobel_tb/filter_edge_det_sobel/hs_in
add wave -noupdate /filter_edge_det_sobel_tb/filter_edge_det_sobel/vs_in
add wave -noupdate -divider {New Divider}
add wave -noupdate /filter_edge_det_sobel_tb/filter_edge_det_sobel/filter_core/bypass
add wave -noupdate -radix unsigned /filter_edge_det_sobel_tb/filter_edge_det_sobel/filter_core/line_buf_wptr
add wave -noupdate -radix unsigned /filter_edge_det_sobel_tb/filter_edge_det_sobel/filter_core/line_bufa_out
add wave -noupdate -radix unsigned /filter_edge_det_sobel_tb/filter_edge_det_sobel/filter_core/line_bufb_out
add wave -noupdate -radix unsigned -childformat {{{/filter_edge_det_sobel_tb/filter_edge_det_sobel/filter_core/sr_d_in[0]} -radix unsigned} {{/filter_edge_det_sobel_tb/filter_edge_det_sobel/filter_core/sr_d_in[1]} -radix unsigned} {{/filter_edge_det_sobel_tb/filter_edge_det_sobel/filter_core/sr_d_in[2]} -radix unsigned}} -expand -subitemconfig {{/filter_edge_det_sobel_tb/filter_edge_det_sobel/filter_core/sr_d_in[0]} {-height 15 -radix unsigned} {/filter_edge_det_sobel_tb/filter_edge_det_sobel/filter_core/sr_d_in[1]} {-height 15 -radix unsigned} {/filter_edge_det_sobel_tb/filter_edge_det_sobel/filter_core/sr_d_in[2]} {-height 15 -radix unsigned}} /filter_edge_det_sobel_tb/filter_edge_det_sobel/filter_core/sr_d_in
add wave -noupdate /filter_edge_det_sobel_tb/filter_edge_det_sobel/filter_core/sr_hs
add wave -noupdate /filter_edge_det_sobel_tb/filter_edge_det_sobel/filter_core/vs_in_d
add wave -noupdate /filter_edge_det_sobel_tb/filter_edge_det_sobel/filter_core/vs_in_dd
add wave -noupdate -radix unsigned -childformat {{{/filter_edge_det_sobel_tb/filter_edge_det_sobel/filter_core/bypass_delay[4]} -radix unsigned} {{/filter_edge_det_sobel_tb/filter_edge_det_sobel/filter_core/bypass_delay[3]} -radix unsigned} {{/filter_edge_det_sobel_tb/filter_edge_det_sobel/filter_core/bypass_delay[2]} -radix unsigned}} -subitemconfig {{/filter_edge_det_sobel_tb/filter_edge_det_sobel/filter_core/bypass_delay[4]} {-height 15 -radix unsigned} {/filter_edge_det_sobel_tb/filter_edge_det_sobel/filter_core/bypass_delay[3]} {-height 15 -radix unsigned} {/filter_edge_det_sobel_tb/filter_edge_det_sobel/filter_core/bypass_delay[2]} {-height 15 -radix unsigned}} /filter_edge_det_sobel_tb/filter_edge_det_sobel/filter_core/bypass_delay
add wave -noupdate /filter_edge_det_sobel_tb/filter_edge_det_sobel/filter_core/d_out
add wave -noupdate /filter_edge_det_sobel_tb/filter_edge_det_sobel/filter_core/dv_out
add wave -noupdate /filter_edge_det_sobel_tb/filter_edge_det_sobel/filter_core/hs_out
add wave -noupdate /filter_edge_det_sobel_tb/filter_edge_det_sobel/filter_core/vs_out
add wave -noupdate /filter_edge_det_sobel_tb/filter_edge_det_sobel/sr_hs
add wave -noupdate /filter_edge_det_sobel_tb/filter_edge_det_sobel/sr_vs
add wave -noupdate -divider {New Divider}
add wave -noupdate -radix unsigned /filter_edge_det_sobel_tb/filter_edge_det_sobel/filter_core/x1
add wave -noupdate -radix unsigned /filter_edge_det_sobel_tb/filter_edge_det_sobel/filter_core/x2
add wave -noupdate -radix unsigned /filter_edge_det_sobel_tb/filter_edge_det_sobel/filter_core/x3
add wave -noupdate -radix unsigned /filter_edge_det_sobel_tb/filter_edge_det_sobel/sum_p23
add wave -noupdate -radix unsigned /filter_edge_det_sobel_tb/filter_edge_det_sobel/sum_p123
add wave -noupdate -divider {New Divider}
add wave -noupdate -radix unsigned /filter_edge_det_sobel_tb/filter_edge_det_sobel/filter_core/x4
add wave -noupdate -radix unsigned /filter_edge_det_sobel_tb/filter_edge_det_sobel/filter_core/x5
add wave -noupdate -radix unsigned /filter_edge_det_sobel_tb/filter_edge_det_sobel/filter_core/x6
add wave -noupdate -radix unsigned /filter_edge_det_sobel_tb/filter_edge_det_sobel/sum_p47
add wave -noupdate -radix unsigned /filter_edge_det_sobel_tb/filter_edge_det_sobel/sum_p147
add wave -noupdate -radix unsigned /filter_edge_det_sobel_tb/filter_edge_det_sobel/sum_p69
add wave -noupdate -radix unsigned /filter_edge_det_sobel_tb/filter_edge_det_sobel/sum_p369
add wave -noupdate -divider {New Divider}
add wave -noupdate -radix unsigned /filter_edge_det_sobel_tb/filter_edge_det_sobel/filter_core/x7
add wave -noupdate -radix unsigned /filter_edge_det_sobel_tb/filter_edge_det_sobel/filter_core/x8
add wave -noupdate -radix unsigned /filter_edge_det_sobel_tb/filter_edge_det_sobel/filter_core/x9
add wave -noupdate -radix unsigned /filter_edge_det_sobel_tb/filter_edge_det_sobel/sum_p89
add wave -noupdate -radix unsigned /filter_edge_det_sobel_tb/filter_edge_det_sobel/sum_p789
add wave -noupdate -divider {New Divider}
add wave -noupdate -radix decimal -childformat {{{/filter_edge_det_sobel_tb/filter_edge_det_sobel/gx[11]} -radix unsigned} {{/filter_edge_det_sobel_tb/filter_edge_det_sobel/gx[10]} -radix unsigned} {{/filter_edge_det_sobel_tb/filter_edge_det_sobel/gx[9]} -radix unsigned} {{/filter_edge_det_sobel_tb/filter_edge_det_sobel/gx[8]} -radix unsigned} {{/filter_edge_det_sobel_tb/filter_edge_det_sobel/gx[7]} -radix unsigned} {{/filter_edge_det_sobel_tb/filter_edge_det_sobel/gx[6]} -radix unsigned} {{/filter_edge_det_sobel_tb/filter_edge_det_sobel/gx[5]} -radix unsigned} {{/filter_edge_det_sobel_tb/filter_edge_det_sobel/gx[4]} -radix unsigned} {{/filter_edge_det_sobel_tb/filter_edge_det_sobel/gx[3]} -radix unsigned} {{/filter_edge_det_sobel_tb/filter_edge_det_sobel/gx[2]} -radix unsigned} {{/filter_edge_det_sobel_tb/filter_edge_det_sobel/gx[1]} -radix unsigned} {{/filter_edge_det_sobel_tb/filter_edge_det_sobel/gx[0]} -radix unsigned}} -subitemconfig {{/filter_edge_det_sobel_tb/filter_edge_det_sobel/gx[11]} {-height 15 -radix unsigned} {/filter_edge_det_sobel_tb/filter_edge_det_sobel/gx[10]} {-height 15 -radix unsigned} {/filter_edge_det_sobel_tb/filter_edge_det_sobel/gx[9]} {-height 15 -radix unsigned} {/filter_edge_det_sobel_tb/filter_edge_det_sobel/gx[8]} {-height 15 -radix unsigned} {/filter_edge_det_sobel_tb/filter_edge_det_sobel/gx[7]} {-height 15 -radix unsigned} {/filter_edge_det_sobel_tb/filter_edge_det_sobel/gx[6]} {-height 15 -radix unsigned} {/filter_edge_det_sobel_tb/filter_edge_det_sobel/gx[5]} {-height 15 -radix unsigned} {/filter_edge_det_sobel_tb/filter_edge_det_sobel/gx[4]} {-height 15 -radix unsigned} {/filter_edge_det_sobel_tb/filter_edge_det_sobel/gx[3]} {-height 15 -radix unsigned} {/filter_edge_det_sobel_tb/filter_edge_det_sobel/gx[2]} {-height 15 -radix unsigned} {/filter_edge_det_sobel_tb/filter_edge_det_sobel/gx[1]} {-height 15 -radix unsigned} {/filter_edge_det_sobel_tb/filter_edge_det_sobel/gx[0]} {-height 15 -radix unsigned}} /filter_edge_det_sobel_tb/filter_edge_det_sobel/gx
add wave -noupdate -radix decimal /filter_edge_det_sobel_tb/filter_edge_det_sobel/gy
add wave -noupdate -radix unsigned /filter_edge_det_sobel_tb/filter_edge_det_sobel/gx_mod
add wave -noupdate -radix unsigned /filter_edge_det_sobel_tb/filter_edge_det_sobel/gy_mod
add wave -noupdate -divider {New Divider}
add wave -noupdate -radix unsigned /filter_edge_det_sobel_tb/filter_edge_det_sobel/dout
add wave -noupdate /filter_edge_det_sobel_tb/filter_edge_det_sobel/dv_out
add wave -noupdate /filter_edge_det_sobel_tb/filter_edge_det_sobel/hs_out
add wave -noupdate /filter_edge_det_sobel_tb/filter_edge_det_sobel/vs_out
add wave -noupdate /filter_edge_det_sobel_tb/filter_edge_det_sobel/sr_dv
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
WaveRestoreZoom {360611902 ps} {360641002 ps}
