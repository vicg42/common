onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -radix unsigned /scaler_h_tb/PIXEL_STEP
add wave -noupdate -radix unsigned /scaler_h_tb/x_cntr
add wave -noupdate -divider {New Divider}
add wave -noupdate /scaler_h_tb/scaler_h/TABLE_INPUT_WIDTH_MASK
add wave -noupdate -radix unsigned /scaler_h_tb/dbg_cnt_i
add wave -noupdate /scaler_h_tb/clk
add wave -noupdate /scaler_h_tb/scaler_h/di_i
add wave -noupdate /scaler_h_tb/scaler_h/de_i
add wave -noupdate /scaler_h_tb/scaler_h/hs_i
add wave -noupdate /scaler_h_tb/scaler_h/vs_i
add wave -noupdate -divider {New Divider}
add wave -noupdate -radix unsigned -childformat {{{/scaler_h_tb/scaler_h/cnt_i[23]} -radix unsigned} {{/scaler_h_tb/scaler_h/cnt_i[22]} -radix unsigned} {{/scaler_h_tb/scaler_h/cnt_i[21]} -radix unsigned} {{/scaler_h_tb/scaler_h/cnt_i[20]} -radix unsigned} {{/scaler_h_tb/scaler_h/cnt_i[19]} -radix unsigned} {{/scaler_h_tb/scaler_h/cnt_i[18]} -radix unsigned} {{/scaler_h_tb/scaler_h/cnt_i[17]} -radix unsigned} {{/scaler_h_tb/scaler_h/cnt_i[16]} -radix unsigned} {{/scaler_h_tb/scaler_h/cnt_i[15]} -radix unsigned} {{/scaler_h_tb/scaler_h/cnt_i[14]} -radix unsigned} {{/scaler_h_tb/scaler_h/cnt_i[13]} -radix unsigned} {{/scaler_h_tb/scaler_h/cnt_i[12]} -radix unsigned} {{/scaler_h_tb/scaler_h/cnt_i[11]} -radix unsigned} {{/scaler_h_tb/scaler_h/cnt_i[10]} -radix unsigned} {{/scaler_h_tb/scaler_h/cnt_i[9]} -radix unsigned} {{/scaler_h_tb/scaler_h/cnt_i[8]} -radix unsigned} {{/scaler_h_tb/scaler_h/cnt_i[7]} -radix unsigned} {{/scaler_h_tb/scaler_h/cnt_i[6]} -radix unsigned} {{/scaler_h_tb/scaler_h/cnt_i[5]} -radix unsigned} {{/scaler_h_tb/scaler_h/cnt_i[4]} -radix unsigned} {{/scaler_h_tb/scaler_h/cnt_i[3]} -radix unsigned} {{/scaler_h_tb/scaler_h/cnt_i[2]} -radix unsigned} {{/scaler_h_tb/scaler_h/cnt_i[1]} -radix unsigned} {{/scaler_h_tb/scaler_h/cnt_i[0]} -radix unsigned}} -subitemconfig {{/scaler_h_tb/scaler_h/cnt_i[23]} {-radix unsigned} {/scaler_h_tb/scaler_h/cnt_i[22]} {-radix unsigned} {/scaler_h_tb/scaler_h/cnt_i[21]} {-radix unsigned} {/scaler_h_tb/scaler_h/cnt_i[20]} {-radix unsigned} {/scaler_h_tb/scaler_h/cnt_i[19]} {-radix unsigned} {/scaler_h_tb/scaler_h/cnt_i[18]} {-radix unsigned} {/scaler_h_tb/scaler_h/cnt_i[17]} {-radix unsigned} {/scaler_h_tb/scaler_h/cnt_i[16]} {-radix unsigned} {/scaler_h_tb/scaler_h/cnt_i[15]} {-radix unsigned} {/scaler_h_tb/scaler_h/cnt_i[14]} {-radix unsigned} {/scaler_h_tb/scaler_h/cnt_i[13]} {-radix unsigned} {/scaler_h_tb/scaler_h/cnt_i[12]} {-radix unsigned} {/scaler_h_tb/scaler_h/cnt_i[11]} {-radix unsigned} {/scaler_h_tb/scaler_h/cnt_i[10]} {-radix unsigned} {/scaler_h_tb/scaler_h/cnt_i[9]} {-radix unsigned} {/scaler_h_tb/scaler_h/cnt_i[8]} {-radix unsigned} {/scaler_h_tb/scaler_h/cnt_i[7]} {-radix unsigned} {/scaler_h_tb/scaler_h/cnt_i[6]} {-radix unsigned} {/scaler_h_tb/scaler_h/cnt_i[5]} {-radix unsigned} {/scaler_h_tb/scaler_h/cnt_i[4]} {-radix unsigned} {/scaler_h_tb/scaler_h/cnt_i[3]} {-radix unsigned} {/scaler_h_tb/scaler_h/cnt_i[2]} {-radix unsigned} {/scaler_h_tb/scaler_h/cnt_i[1]} {-radix unsigned} {/scaler_h_tb/scaler_h/cnt_i[0]} {-radix unsigned}} /scaler_h_tb/scaler_h/cnt_i
add wave -noupdate /scaler_h_tb/scaler_h/sof
add wave -noupdate /scaler_h_tb/scaler_h/new_fr
add wave -noupdate /scaler_h_tb/scaler_h/new_pix
add wave -noupdate /scaler_h_tb/scaler_h/new_line
add wave -noupdate -radix unsigned -childformat {{{/scaler_h_tb/scaler_h/cnt_o[23]} -radix unsigned} {{/scaler_h_tb/scaler_h/cnt_o[22]} -radix unsigned} {{/scaler_h_tb/scaler_h/cnt_o[21]} -radix unsigned} {{/scaler_h_tb/scaler_h/cnt_o[20]} -radix unsigned} {{/scaler_h_tb/scaler_h/cnt_o[19]} -radix unsigned} {{/scaler_h_tb/scaler_h/cnt_o[18]} -radix unsigned} {{/scaler_h_tb/scaler_h/cnt_o[17]} -radix unsigned} {{/scaler_h_tb/scaler_h/cnt_o[16]} -radix unsigned} {{/scaler_h_tb/scaler_h/cnt_o[15]} -radix unsigned} {{/scaler_h_tb/scaler_h/cnt_o[14]} -radix unsigned} {{/scaler_h_tb/scaler_h/cnt_o[13]} -radix unsigned} {{/scaler_h_tb/scaler_h/cnt_o[12]} -radix unsigned} {{/scaler_h_tb/scaler_h/cnt_o[11]} -radix unsigned} {{/scaler_h_tb/scaler_h/cnt_o[10]} -radix unsigned} {{/scaler_h_tb/scaler_h/cnt_o[9]} -radix unsigned} {{/scaler_h_tb/scaler_h/cnt_o[8]} -radix unsigned} {{/scaler_h_tb/scaler_h/cnt_o[7]} -radix unsigned} {{/scaler_h_tb/scaler_h/cnt_o[6]} -radix unsigned} {{/scaler_h_tb/scaler_h/cnt_o[5]} -radix unsigned} {{/scaler_h_tb/scaler_h/cnt_o[4]} -radix unsigned} {{/scaler_h_tb/scaler_h/cnt_o[3]} -radix unsigned} {{/scaler_h_tb/scaler_h/cnt_o[2]} -radix unsigned} {{/scaler_h_tb/scaler_h/cnt_o[1]} -radix unsigned} {{/scaler_h_tb/scaler_h/cnt_o[0]} -radix unsigned}} -subitemconfig {{/scaler_h_tb/scaler_h/cnt_o[23]} {-radix unsigned} {/scaler_h_tb/scaler_h/cnt_o[22]} {-radix unsigned} {/scaler_h_tb/scaler_h/cnt_o[21]} {-radix unsigned} {/scaler_h_tb/scaler_h/cnt_o[20]} {-radix unsigned} {/scaler_h_tb/scaler_h/cnt_o[19]} {-radix unsigned} {/scaler_h_tb/scaler_h/cnt_o[18]} {-radix unsigned} {/scaler_h_tb/scaler_h/cnt_o[17]} {-radix unsigned} {/scaler_h_tb/scaler_h/cnt_o[16]} {-radix unsigned} {/scaler_h_tb/scaler_h/cnt_o[15]} {-radix unsigned} {/scaler_h_tb/scaler_h/cnt_o[14]} {-radix unsigned} {/scaler_h_tb/scaler_h/cnt_o[13]} {-radix unsigned} {/scaler_h_tb/scaler_h/cnt_o[12]} {-radix unsigned} {/scaler_h_tb/scaler_h/cnt_o[11]} {-radix unsigned} {/scaler_h_tb/scaler_h/cnt_o[10]} {-radix unsigned} {/scaler_h_tb/scaler_h/cnt_o[9]} {-radix unsigned} {/scaler_h_tb/scaler_h/cnt_o[8]} {-radix unsigned} {/scaler_h_tb/scaler_h/cnt_o[7]} {-radix unsigned} {/scaler_h_tb/scaler_h/cnt_o[6]} {-radix unsigned} {/scaler_h_tb/scaler_h/cnt_o[5]} {-radix unsigned} {/scaler_h_tb/scaler_h/cnt_o[4]} {-radix unsigned} {/scaler_h_tb/scaler_h/cnt_o[3]} {-radix unsigned} {/scaler_h_tb/scaler_h/cnt_o[2]} {-radix unsigned} {/scaler_h_tb/scaler_h/cnt_o[1]} {-radix unsigned} {/scaler_h_tb/scaler_h/cnt_o[0]} {-radix unsigned}} /scaler_h_tb/scaler_h/cnt_o
add wave -noupdate -divider {New Divider}
add wave -noupdate /scaler_h_tb/scaler_h/do_o
add wave -noupdate /scaler_h_tb/scaler_h/de_o
add wave -noupdate /scaler_h_tb/scaler_h/hs_o
add wave -noupdate /scaler_h_tb/scaler_h/vs_o
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
WaveRestoreZoom {10916736 ps} {14108608 ps}
