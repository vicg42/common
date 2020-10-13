onerror {resume}
quietly virtual function -install /scaler_h_tb/scaler_h_m -env /scaler_h_tb/scaler_h_m { &{/scaler_h_tb/scaler_h_m/cnt_o[23], /scaler_h_tb/scaler_h_m/cnt_o[22], /scaler_h_tb/scaler_h_m/cnt_o[21], /scaler_h_tb/scaler_h_m/cnt_o[20], /scaler_h_tb/scaler_h_m/cnt_o[19], /scaler_h_tb/scaler_h_m/cnt_o[18], /scaler_h_tb/scaler_h_m/cnt_o[17], /scaler_h_tb/scaler_h_m/cnt_o[16], /scaler_h_tb/scaler_h_m/cnt_o[15], /scaler_h_tb/scaler_h_m/cnt_o[14], /scaler_h_tb/scaler_h_m/cnt_o[13], /scaler_h_tb/scaler_h_m/cnt_o[12] }} cnt_o_23_12
quietly virtual function -install /scaler_h_tb/scaler_h_m -env /scaler_h_tb/scaler_h_m { &{/scaler_h_tb/scaler_h_m/cnt_i[23], /scaler_h_tb/scaler_h_m/cnt_i[22], /scaler_h_tb/scaler_h_m/cnt_i[21], /scaler_h_tb/scaler_h_m/cnt_i[20], /scaler_h_tb/scaler_h_m/cnt_i[19], /scaler_h_tb/scaler_h_m/cnt_i[18], /scaler_h_tb/scaler_h_m/cnt_i[17], /scaler_h_tb/scaler_h_m/cnt_i[16], /scaler_h_tb/scaler_h_m/cnt_i[15], /scaler_h_tb/scaler_h_m/cnt_i[14], /scaler_h_tb/scaler_h_m/cnt_i[13], /scaler_h_tb/scaler_h_m/cnt_i[12] }} cnt_i_23_12
quietly WaveActivateNextPane {} 0
add wave -noupdate -radix unsigned /scaler_h_tb/PIXEL_STEP
add wave -noupdate -radix unsigned /scaler_h_tb/PIXEL_WIDTH
add wave -noupdate /scaler_h_tb/H_SCALE
add wave -noupdate -divider {New Divider}
add wave -noupdate -color {Slate Blue} -itemcolor Gold -radix unsigned /scaler_h_tb/dbg_cnt_i
add wave -noupdate /scaler_h_tb/clk
add wave -noupdate -radix unsigned /scaler_h_tb/scaler_h_m/di_i
add wave -noupdate /scaler_h_tb/scaler_h_m/de_i
add wave -noupdate /scaler_h_tb/scaler_h_m/hs_i
add wave -noupdate /scaler_h_tb/scaler_h_m/vs_i
add wave -noupdate -divider {New Divider}
add wave -noupdate /scaler_h_tb/scaler_h_m/dx
add wave -noupdate -expand /scaler_h_tb/scaler_h_m/coe
add wave -noupdate -expand /scaler_h_tb/scaler_h_m/m
add wave -noupdate /scaler_h_tb/scale_step_h
add wave -noupdate -radix unsigned -childformat {{{/scaler_h_tb/scaler_h_m/cnt_i[23]} -radix unsigned} {{/scaler_h_tb/scaler_h_m/cnt_i[22]} -radix unsigned} {{/scaler_h_tb/scaler_h_m/cnt_i[21]} -radix unsigned} {{/scaler_h_tb/scaler_h_m/cnt_i[20]} -radix unsigned} {{/scaler_h_tb/scaler_h_m/cnt_i[19]} -radix unsigned} {{/scaler_h_tb/scaler_h_m/cnt_i[18]} -radix unsigned} {{/scaler_h_tb/scaler_h_m/cnt_i[17]} -radix unsigned} {{/scaler_h_tb/scaler_h_m/cnt_i[16]} -radix unsigned} {{/scaler_h_tb/scaler_h_m/cnt_i[15]} -radix unsigned} {{/scaler_h_tb/scaler_h_m/cnt_i[14]} -radix unsigned} {{/scaler_h_tb/scaler_h_m/cnt_i[13]} -radix unsigned} {{/scaler_h_tb/scaler_h_m/cnt_i[12]} -radix unsigned} {{/scaler_h_tb/scaler_h_m/cnt_i[11]} -radix unsigned} {{/scaler_h_tb/scaler_h_m/cnt_i[10]} -radix unsigned} {{/scaler_h_tb/scaler_h_m/cnt_i[9]} -radix unsigned} {{/scaler_h_tb/scaler_h_m/cnt_i[8]} -radix unsigned} {{/scaler_h_tb/scaler_h_m/cnt_i[7]} -radix unsigned} {{/scaler_h_tb/scaler_h_m/cnt_i[6]} -radix unsigned} {{/scaler_h_tb/scaler_h_m/cnt_i[5]} -radix unsigned} {{/scaler_h_tb/scaler_h_m/cnt_i[4]} -radix unsigned} {{/scaler_h_tb/scaler_h_m/cnt_i[3]} -radix unsigned} {{/scaler_h_tb/scaler_h_m/cnt_i[2]} -radix unsigned} {{/scaler_h_tb/scaler_h_m/cnt_i[1]} -radix unsigned} {{/scaler_h_tb/scaler_h_m/cnt_i[0]} -radix unsigned}} -subitemconfig {{/scaler_h_tb/scaler_h_m/cnt_i[23]} {-height 15 -radix unsigned} {/scaler_h_tb/scaler_h_m/cnt_i[22]} {-height 15 -radix unsigned} {/scaler_h_tb/scaler_h_m/cnt_i[21]} {-height 15 -radix unsigned} {/scaler_h_tb/scaler_h_m/cnt_i[20]} {-height 15 -radix unsigned} {/scaler_h_tb/scaler_h_m/cnt_i[19]} {-height 15 -radix unsigned} {/scaler_h_tb/scaler_h_m/cnt_i[18]} {-height 15 -radix unsigned} {/scaler_h_tb/scaler_h_m/cnt_i[17]} {-height 15 -radix unsigned} {/scaler_h_tb/scaler_h_m/cnt_i[16]} {-height 15 -radix unsigned} {/scaler_h_tb/scaler_h_m/cnt_i[15]} {-height 15 -radix unsigned} {/scaler_h_tb/scaler_h_m/cnt_i[14]} {-height 15 -radix unsigned} {/scaler_h_tb/scaler_h_m/cnt_i[13]} {-height 15 -radix unsigned} {/scaler_h_tb/scaler_h_m/cnt_i[12]} {-height 15 -radix unsigned} {/scaler_h_tb/scaler_h_m/cnt_i[11]} {-height 15 -radix unsigned} {/scaler_h_tb/scaler_h_m/cnt_i[10]} {-height 15 -radix unsigned} {/scaler_h_tb/scaler_h_m/cnt_i[9]} {-height 15 -radix unsigned} {/scaler_h_tb/scaler_h_m/cnt_i[8]} {-height 15 -radix unsigned} {/scaler_h_tb/scaler_h_m/cnt_i[7]} {-height 15 -radix unsigned} {/scaler_h_tb/scaler_h_m/cnt_i[6]} {-height 15 -radix unsigned} {/scaler_h_tb/scaler_h_m/cnt_i[5]} {-height 15 -radix unsigned} {/scaler_h_tb/scaler_h_m/cnt_i[4]} {-height 15 -radix unsigned} {/scaler_h_tb/scaler_h_m/cnt_i[3]} {-height 15 -radix unsigned} {/scaler_h_tb/scaler_h_m/cnt_i[2]} {-height 15 -radix unsigned} {/scaler_h_tb/scaler_h_m/cnt_i[1]} {-height 15 -radix unsigned} {/scaler_h_tb/scaler_h_m/cnt_i[0]} {-height 15 -radix unsigned}} /scaler_h_tb/scaler_h_m/cnt_i
add wave -noupdate /scaler_h_tb/scaler_h_m/new_pix
add wave -noupdate /scaler_h_tb/scaler_h_m/sof
add wave -noupdate /scaler_h_tb/scaler_h_m/new_fr
add wave -noupdate /scaler_h_tb/scaler_h_m/sol
add wave -noupdate /scaler_h_tb/scaler_h_m/new_line
add wave -noupdate -radix unsigned -childformat {{{/scaler_h_tb/scaler_h_m/cnt_o[23]} -radix unsigned} {{/scaler_h_tb/scaler_h_m/cnt_o[22]} -radix unsigned} {{/scaler_h_tb/scaler_h_m/cnt_o[21]} -radix unsigned} {{/scaler_h_tb/scaler_h_m/cnt_o[20]} -radix unsigned} {{/scaler_h_tb/scaler_h_m/cnt_o[19]} -radix unsigned} {{/scaler_h_tb/scaler_h_m/cnt_o[18]} -radix unsigned} {{/scaler_h_tb/scaler_h_m/cnt_o[17]} -radix unsigned} {{/scaler_h_tb/scaler_h_m/cnt_o[16]} -radix unsigned} {{/scaler_h_tb/scaler_h_m/cnt_o[15]} -radix unsigned} {{/scaler_h_tb/scaler_h_m/cnt_o[14]} -radix unsigned} {{/scaler_h_tb/scaler_h_m/cnt_o[13]} -radix unsigned} {{/scaler_h_tb/scaler_h_m/cnt_o[12]} -radix unsigned} {{/scaler_h_tb/scaler_h_m/cnt_o[11]} -radix unsigned} {{/scaler_h_tb/scaler_h_m/cnt_o[10]} -radix unsigned} {{/scaler_h_tb/scaler_h_m/cnt_o[9]} -radix unsigned} {{/scaler_h_tb/scaler_h_m/cnt_o[8]} -radix unsigned} {{/scaler_h_tb/scaler_h_m/cnt_o[7]} -radix unsigned} {{/scaler_h_tb/scaler_h_m/cnt_o[6]} -radix unsigned} {{/scaler_h_tb/scaler_h_m/cnt_o[5]} -radix unsigned} {{/scaler_h_tb/scaler_h_m/cnt_o[4]} -radix unsigned} {{/scaler_h_tb/scaler_h_m/cnt_o[3]} -radix unsigned} {{/scaler_h_tb/scaler_h_m/cnt_o[2]} -radix unsigned} {{/scaler_h_tb/scaler_h_m/cnt_o[1]} -radix unsigned} {{/scaler_h_tb/scaler_h_m/cnt_o[0]} -radix unsigned}} -subitemconfig {{/scaler_h_tb/scaler_h_m/cnt_o[23]} {-height 15 -radix unsigned} {/scaler_h_tb/scaler_h_m/cnt_o[22]} {-height 15 -radix unsigned} {/scaler_h_tb/scaler_h_m/cnt_o[21]} {-height 15 -radix unsigned} {/scaler_h_tb/scaler_h_m/cnt_o[20]} {-height 15 -radix unsigned} {/scaler_h_tb/scaler_h_m/cnt_o[19]} {-height 15 -radix unsigned} {/scaler_h_tb/scaler_h_m/cnt_o[18]} {-height 15 -radix unsigned} {/scaler_h_tb/scaler_h_m/cnt_o[17]} {-height 15 -radix unsigned} {/scaler_h_tb/scaler_h_m/cnt_o[16]} {-height 15 -radix unsigned} {/scaler_h_tb/scaler_h_m/cnt_o[15]} {-height 15 -radix unsigned} {/scaler_h_tb/scaler_h_m/cnt_o[14]} {-height 15 -radix unsigned} {/scaler_h_tb/scaler_h_m/cnt_o[13]} {-height 15 -radix unsigned} {/scaler_h_tb/scaler_h_m/cnt_o[12]} {-height 15 -radix unsigned} {/scaler_h_tb/scaler_h_m/cnt_o[11]} {-height 15 -radix unsigned} {/scaler_h_tb/scaler_h_m/cnt_o[10]} {-height 15 -radix unsigned} {/scaler_h_tb/scaler_h_m/cnt_o[9]} {-height 15 -radix unsigned} {/scaler_h_tb/scaler_h_m/cnt_o[8]} {-height 15 -radix unsigned} {/scaler_h_tb/scaler_h_m/cnt_o[7]} {-height 15 -radix unsigned} {/scaler_h_tb/scaler_h_m/cnt_o[6]} {-height 15 -radix unsigned} {/scaler_h_tb/scaler_h_m/cnt_o[5]} {-height 15 -radix unsigned} {/scaler_h_tb/scaler_h_m/cnt_o[4]} {-height 15 -radix unsigned} {/scaler_h_tb/scaler_h_m/cnt_o[3]} {-height 15 -radix unsigned} {/scaler_h_tb/scaler_h_m/cnt_o[2]} {-height 15 -radix unsigned} {/scaler_h_tb/scaler_h_m/cnt_o[1]} {-height 15 -radix unsigned} {/scaler_h_tb/scaler_h_m/cnt_o[0]} {-height 15 -radix unsigned}} /scaler_h_tb/scaler_h_m/cnt_o
add wave -noupdate -divider {New Divider}
add wave -noupdate -radix unsigned -childformat {{{/scaler_h_tb/scaler_h_m/do_o[7]} -radix unsigned} {{/scaler_h_tb/scaler_h_m/do_o[6]} -radix unsigned} {{/scaler_h_tb/scaler_h_m/do_o[5]} -radix unsigned} {{/scaler_h_tb/scaler_h_m/do_o[4]} -radix unsigned} {{/scaler_h_tb/scaler_h_m/do_o[3]} -radix unsigned} {{/scaler_h_tb/scaler_h_m/do_o[2]} -radix unsigned} {{/scaler_h_tb/scaler_h_m/do_o[1]} -radix unsigned} {{/scaler_h_tb/scaler_h_m/do_o[0]} -radix unsigned}} -subitemconfig {{/scaler_h_tb/scaler_h_m/do_o[7]} {-height 15 -radix unsigned} {/scaler_h_tb/scaler_h_m/do_o[6]} {-height 15 -radix unsigned} {/scaler_h_tb/scaler_h_m/do_o[5]} {-height 15 -radix unsigned} {/scaler_h_tb/scaler_h_m/do_o[4]} {-height 15 -radix unsigned} {/scaler_h_tb/scaler_h_m/do_o[3]} {-height 15 -radix unsigned} {/scaler_h_tb/scaler_h_m/do_o[2]} {-height 15 -radix unsigned} {/scaler_h_tb/scaler_h_m/do_o[1]} {-height 15 -radix unsigned} {/scaler_h_tb/scaler_h_m/do_o[0]} {-height 15 -radix unsigned}} /scaler_h_tb/scaler_h_m/do_o
add wave -noupdate /scaler_h_tb/scaler_h_m/de_o
add wave -noupdate /scaler_h_tb/scaler_h_m/hs_o
add wave -noupdate /scaler_h_tb/scaler_h_m/vs_o
add wave -noupdate -color {Slate Blue} -itemcolor Gold -radix unsigned /scaler_h_tb/dbg_cnt_o
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {0 ps} 0}
quietly wave cursor active 0
configure wave -namecolwidth 234
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
configure wave -timelineunits us
update
WaveRestoreZoom {1289526 ps} {2037394 ps}
