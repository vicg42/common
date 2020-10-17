onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -radix ascii /scaler_bicubic_n_tb/READ_IMG_FILE
add wave -noupdate -radix unsigned /scaler_bicubic_n_tb/V_SCALE_INLINE_WIDTH
add wave -noupdate -radix ascii /scaler_bicubic_n_tb/WRITE_IMG_FILE
add wave -noupdate -radix unsigned /scaler_bicubic_n_tb/LINE_IN_SIZE_MAX
add wave -noupdate -radix unsigned /scaler_bicubic_n_tb/PIXEL_WIDTH
add wave -noupdate -radix unsigned /scaler_bicubic_n_tb/SCALE_STEP
add wave -noupdate /scaler_bicubic_n_tb/SCALE_COE
add wave -noupdate -radix unsigned /scaler_bicubic_n_tb/COE_WIDTH
add wave -noupdate -radix unsigned /scaler_bicubic_n_tb/SPARSE_OUT
add wave -noupdate -divider {New Divider}
add wave -noupdate -radix unsigned /scaler_bicubic_n_tb/dbg_cntx_i
add wave -noupdate -radix unsigned /scaler_bicubic_n_tb/dbg_cnty_i
add wave -noupdate -divider SCALER_H
add wave -noupdate /scaler_bicubic_n_tb/scaler_bicubic_m/scaler_cubic_h_m/di_i
add wave -noupdate /scaler_bicubic_n_tb/scaler_bicubic_m/scaler_cubic_h_m/de_i
add wave -noupdate /scaler_bicubic_n_tb/scaler_bicubic_m/scaler_cubic_h_m/hs_i
add wave -noupdate /scaler_bicubic_n_tb/scaler_bicubic_m/scaler_cubic_h_m/vs_i
add wave -noupdate {/scaler_bicubic_n_tb/scaler_bicubic_m/scaler_cubic_h_m/sr_de_i[0]}
add wave -noupdate -expand /scaler_bicubic_n_tb/scaler_bicubic_m/scaler_cubic_h_m/sr_di_i
add wave -noupdate -radix unsigned -childformat {{{/scaler_bicubic_n_tb/scaler_bicubic_m/scaler_cubic_h_m/cnt_i[23]} -radix unsigned} {{/scaler_bicubic_n_tb/scaler_bicubic_m/scaler_cubic_h_m/cnt_i[22]} -radix unsigned} {{/scaler_bicubic_n_tb/scaler_bicubic_m/scaler_cubic_h_m/cnt_i[21]} -radix unsigned} {{/scaler_bicubic_n_tb/scaler_bicubic_m/scaler_cubic_h_m/cnt_i[20]} -radix unsigned} {{/scaler_bicubic_n_tb/scaler_bicubic_m/scaler_cubic_h_m/cnt_i[19]} -radix unsigned} {{/scaler_bicubic_n_tb/scaler_bicubic_m/scaler_cubic_h_m/cnt_i[18]} -radix unsigned} {{/scaler_bicubic_n_tb/scaler_bicubic_m/scaler_cubic_h_m/cnt_i[17]} -radix unsigned} {{/scaler_bicubic_n_tb/scaler_bicubic_m/scaler_cubic_h_m/cnt_i[16]} -radix unsigned} {{/scaler_bicubic_n_tb/scaler_bicubic_m/scaler_cubic_h_m/cnt_i[15]} -radix unsigned} {{/scaler_bicubic_n_tb/scaler_bicubic_m/scaler_cubic_h_m/cnt_i[14]} -radix unsigned} {{/scaler_bicubic_n_tb/scaler_bicubic_m/scaler_cubic_h_m/cnt_i[13]} -radix unsigned} {{/scaler_bicubic_n_tb/scaler_bicubic_m/scaler_cubic_h_m/cnt_i[12]} -radix unsigned} {{/scaler_bicubic_n_tb/scaler_bicubic_m/scaler_cubic_h_m/cnt_i[11]} -radix unsigned} {{/scaler_bicubic_n_tb/scaler_bicubic_m/scaler_cubic_h_m/cnt_i[10]} -radix unsigned} {{/scaler_bicubic_n_tb/scaler_bicubic_m/scaler_cubic_h_m/cnt_i[9]} -radix unsigned} {{/scaler_bicubic_n_tb/scaler_bicubic_m/scaler_cubic_h_m/cnt_i[8]} -radix unsigned} {{/scaler_bicubic_n_tb/scaler_bicubic_m/scaler_cubic_h_m/cnt_i[7]} -radix unsigned} {{/scaler_bicubic_n_tb/scaler_bicubic_m/scaler_cubic_h_m/cnt_i[6]} -radix unsigned} {{/scaler_bicubic_n_tb/scaler_bicubic_m/scaler_cubic_h_m/cnt_i[5]} -radix unsigned} {{/scaler_bicubic_n_tb/scaler_bicubic_m/scaler_cubic_h_m/cnt_i[4]} -radix unsigned} {{/scaler_bicubic_n_tb/scaler_bicubic_m/scaler_cubic_h_m/cnt_i[3]} -radix unsigned} {{/scaler_bicubic_n_tb/scaler_bicubic_m/scaler_cubic_h_m/cnt_i[2]} -radix unsigned} {{/scaler_bicubic_n_tb/scaler_bicubic_m/scaler_cubic_h_m/cnt_i[1]} -radix unsigned} {{/scaler_bicubic_n_tb/scaler_bicubic_m/scaler_cubic_h_m/cnt_i[0]} -radix unsigned}} -subitemconfig {{/scaler_bicubic_n_tb/scaler_bicubic_m/scaler_cubic_h_m/cnt_i[23]} {-height 15 -radix unsigned} {/scaler_bicubic_n_tb/scaler_bicubic_m/scaler_cubic_h_m/cnt_i[22]} {-height 15 -radix unsigned} {/scaler_bicubic_n_tb/scaler_bicubic_m/scaler_cubic_h_m/cnt_i[21]} {-height 15 -radix unsigned} {/scaler_bicubic_n_tb/scaler_bicubic_m/scaler_cubic_h_m/cnt_i[20]} {-height 15 -radix unsigned} {/scaler_bicubic_n_tb/scaler_bicubic_m/scaler_cubic_h_m/cnt_i[19]} {-height 15 -radix unsigned} {/scaler_bicubic_n_tb/scaler_bicubic_m/scaler_cubic_h_m/cnt_i[18]} {-height 15 -radix unsigned} {/scaler_bicubic_n_tb/scaler_bicubic_m/scaler_cubic_h_m/cnt_i[17]} {-height 15 -radix unsigned} {/scaler_bicubic_n_tb/scaler_bicubic_m/scaler_cubic_h_m/cnt_i[16]} {-height 15 -radix unsigned} {/scaler_bicubic_n_tb/scaler_bicubic_m/scaler_cubic_h_m/cnt_i[15]} {-height 15 -radix unsigned} {/scaler_bicubic_n_tb/scaler_bicubic_m/scaler_cubic_h_m/cnt_i[14]} {-height 15 -radix unsigned} {/scaler_bicubic_n_tb/scaler_bicubic_m/scaler_cubic_h_m/cnt_i[13]} {-height 15 -radix unsigned} {/scaler_bicubic_n_tb/scaler_bicubic_m/scaler_cubic_h_m/cnt_i[12]} {-height 15 -radix unsigned} {/scaler_bicubic_n_tb/scaler_bicubic_m/scaler_cubic_h_m/cnt_i[11]} {-height 15 -radix unsigned} {/scaler_bicubic_n_tb/scaler_bicubic_m/scaler_cubic_h_m/cnt_i[10]} {-height 15 -radix unsigned} {/scaler_bicubic_n_tb/scaler_bicubic_m/scaler_cubic_h_m/cnt_i[9]} {-height 15 -radix unsigned} {/scaler_bicubic_n_tb/scaler_bicubic_m/scaler_cubic_h_m/cnt_i[8]} {-height 15 -radix unsigned} {/scaler_bicubic_n_tb/scaler_bicubic_m/scaler_cubic_h_m/cnt_i[7]} {-height 15 -radix unsigned} {/scaler_bicubic_n_tb/scaler_bicubic_m/scaler_cubic_h_m/cnt_i[6]} {-height 15 -radix unsigned} {/scaler_bicubic_n_tb/scaler_bicubic_m/scaler_cubic_h_m/cnt_i[5]} {-height 15 -radix unsigned} {/scaler_bicubic_n_tb/scaler_bicubic_m/scaler_cubic_h_m/cnt_i[4]} {-height 15 -radix unsigned} {/scaler_bicubic_n_tb/scaler_bicubic_m/scaler_cubic_h_m/cnt_i[3]} {-height 15 -radix unsigned} {/scaler_bicubic_n_tb/scaler_bicubic_m/scaler_cubic_h_m/cnt_i[2]} {-height 15 -radix unsigned} {/scaler_bicubic_n_tb/scaler_bicubic_m/scaler_cubic_h_m/cnt_i[1]} {-height 15 -radix unsigned} {/scaler_bicubic_n_tb/scaler_bicubic_m/scaler_cubic_h_m/cnt_i[0]} {-height 15 -radix unsigned}} /scaler_bicubic_n_tb/scaler_bicubic_m/scaler_cubic_h_m/cnt_i
add wave -noupdate -radix unsigned -childformat {{{/scaler_bicubic_n_tb/scaler_bicubic_m/scaler_cubic_h_m/cnt_o[23]} -radix unsigned} {{/scaler_bicubic_n_tb/scaler_bicubic_m/scaler_cubic_h_m/cnt_o[22]} -radix unsigned} {{/scaler_bicubic_n_tb/scaler_bicubic_m/scaler_cubic_h_m/cnt_o[21]} -radix unsigned} {{/scaler_bicubic_n_tb/scaler_bicubic_m/scaler_cubic_h_m/cnt_o[20]} -radix unsigned} {{/scaler_bicubic_n_tb/scaler_bicubic_m/scaler_cubic_h_m/cnt_o[19]} -radix unsigned} {{/scaler_bicubic_n_tb/scaler_bicubic_m/scaler_cubic_h_m/cnt_o[18]} -radix unsigned} {{/scaler_bicubic_n_tb/scaler_bicubic_m/scaler_cubic_h_m/cnt_o[17]} -radix unsigned} {{/scaler_bicubic_n_tb/scaler_bicubic_m/scaler_cubic_h_m/cnt_o[16]} -radix unsigned} {{/scaler_bicubic_n_tb/scaler_bicubic_m/scaler_cubic_h_m/cnt_o[15]} -radix unsigned} {{/scaler_bicubic_n_tb/scaler_bicubic_m/scaler_cubic_h_m/cnt_o[14]} -radix unsigned} {{/scaler_bicubic_n_tb/scaler_bicubic_m/scaler_cubic_h_m/cnt_o[13]} -radix unsigned} {{/scaler_bicubic_n_tb/scaler_bicubic_m/scaler_cubic_h_m/cnt_o[12]} -radix unsigned} {{/scaler_bicubic_n_tb/scaler_bicubic_m/scaler_cubic_h_m/cnt_o[11]} -radix unsigned} {{/scaler_bicubic_n_tb/scaler_bicubic_m/scaler_cubic_h_m/cnt_o[10]} -radix unsigned} {{/scaler_bicubic_n_tb/scaler_bicubic_m/scaler_cubic_h_m/cnt_o[9]} -radix unsigned} {{/scaler_bicubic_n_tb/scaler_bicubic_m/scaler_cubic_h_m/cnt_o[8]} -radix unsigned} {{/scaler_bicubic_n_tb/scaler_bicubic_m/scaler_cubic_h_m/cnt_o[7]} -radix unsigned} {{/scaler_bicubic_n_tb/scaler_bicubic_m/scaler_cubic_h_m/cnt_o[6]} -radix unsigned} {{/scaler_bicubic_n_tb/scaler_bicubic_m/scaler_cubic_h_m/cnt_o[5]} -radix unsigned} {{/scaler_bicubic_n_tb/scaler_bicubic_m/scaler_cubic_h_m/cnt_o[4]} -radix unsigned} {{/scaler_bicubic_n_tb/scaler_bicubic_m/scaler_cubic_h_m/cnt_o[3]} -radix unsigned} {{/scaler_bicubic_n_tb/scaler_bicubic_m/scaler_cubic_h_m/cnt_o[2]} -radix unsigned} {{/scaler_bicubic_n_tb/scaler_bicubic_m/scaler_cubic_h_m/cnt_o[1]} -radix unsigned} {{/scaler_bicubic_n_tb/scaler_bicubic_m/scaler_cubic_h_m/cnt_o[0]} -radix unsigned}} -subitemconfig {{/scaler_bicubic_n_tb/scaler_bicubic_m/scaler_cubic_h_m/cnt_o[23]} {-height 15 -radix unsigned} {/scaler_bicubic_n_tb/scaler_bicubic_m/scaler_cubic_h_m/cnt_o[22]} {-height 15 -radix unsigned} {/scaler_bicubic_n_tb/scaler_bicubic_m/scaler_cubic_h_m/cnt_o[21]} {-height 15 -radix unsigned} {/scaler_bicubic_n_tb/scaler_bicubic_m/scaler_cubic_h_m/cnt_o[20]} {-height 15 -radix unsigned} {/scaler_bicubic_n_tb/scaler_bicubic_m/scaler_cubic_h_m/cnt_o[19]} {-height 15 -radix unsigned} {/scaler_bicubic_n_tb/scaler_bicubic_m/scaler_cubic_h_m/cnt_o[18]} {-height 15 -radix unsigned} {/scaler_bicubic_n_tb/scaler_bicubic_m/scaler_cubic_h_m/cnt_o[17]} {-height 15 -radix unsigned} {/scaler_bicubic_n_tb/scaler_bicubic_m/scaler_cubic_h_m/cnt_o[16]} {-height 15 -radix unsigned} {/scaler_bicubic_n_tb/scaler_bicubic_m/scaler_cubic_h_m/cnt_o[15]} {-height 15 -radix unsigned} {/scaler_bicubic_n_tb/scaler_bicubic_m/scaler_cubic_h_m/cnt_o[14]} {-height 15 -radix unsigned} {/scaler_bicubic_n_tb/scaler_bicubic_m/scaler_cubic_h_m/cnt_o[13]} {-height 15 -radix unsigned} {/scaler_bicubic_n_tb/scaler_bicubic_m/scaler_cubic_h_m/cnt_o[12]} {-height 15 -radix unsigned} {/scaler_bicubic_n_tb/scaler_bicubic_m/scaler_cubic_h_m/cnt_o[11]} {-height 15 -radix unsigned} {/scaler_bicubic_n_tb/scaler_bicubic_m/scaler_cubic_h_m/cnt_o[10]} {-height 15 -radix unsigned} {/scaler_bicubic_n_tb/scaler_bicubic_m/scaler_cubic_h_m/cnt_o[9]} {-height 15 -radix unsigned} {/scaler_bicubic_n_tb/scaler_bicubic_m/scaler_cubic_h_m/cnt_o[8]} {-height 15 -radix unsigned} {/scaler_bicubic_n_tb/scaler_bicubic_m/scaler_cubic_h_m/cnt_o[7]} {-height 15 -radix unsigned} {/scaler_bicubic_n_tb/scaler_bicubic_m/scaler_cubic_h_m/cnt_o[6]} {-height 15 -radix unsigned} {/scaler_bicubic_n_tb/scaler_bicubic_m/scaler_cubic_h_m/cnt_o[5]} {-height 15 -radix unsigned} {/scaler_bicubic_n_tb/scaler_bicubic_m/scaler_cubic_h_m/cnt_o[4]} {-height 15 -radix unsigned} {/scaler_bicubic_n_tb/scaler_bicubic_m/scaler_cubic_h_m/cnt_o[3]} {-height 15 -radix unsigned} {/scaler_bicubic_n_tb/scaler_bicubic_m/scaler_cubic_h_m/cnt_o[2]} {-height 15 -radix unsigned} {/scaler_bicubic_n_tb/scaler_bicubic_m/scaler_cubic_h_m/cnt_o[1]} {-height 15 -radix unsigned} {/scaler_bicubic_n_tb/scaler_bicubic_m/scaler_cubic_h_m/cnt_o[0]} {-height 15 -radix unsigned}} /scaler_bicubic_n_tb/scaler_bicubic_m/scaler_cubic_h_m/cnt_o
add wave -noupdate /scaler_bicubic_n_tb/scaler_bicubic_m/scaler_cubic_h_m/de_new
add wave -noupdate {/scaler_bicubic_n_tb/scaler_bicubic_m/scaler_cubic_h_m/sr_de_i[2]}
add wave -noupdate -expand /scaler_bicubic_n_tb/scaler_bicubic_m/scaler_cubic_h_m/pix
add wave -noupdate /scaler_bicubic_n_tb/scaler_bicubic_m/scaler_cubic_h_m/coe_adr
add wave -noupdate -expand /scaler_bicubic_n_tb/scaler_bicubic_m/scaler_cubic_h_m/coe
add wave -noupdate {/scaler_bicubic_n_tb/scaler_bicubic_m/scaler_cubic_h_m/sr_de_i[3]}
add wave -noupdate /scaler_bicubic_n_tb/scaler_bicubic_m/scaler_cubic_h_m/mult
add wave -noupdate {/scaler_bicubic_n_tb/scaler_bicubic_m/scaler_cubic_h_m/sr_de_i[4]}
add wave -noupdate /scaler_bicubic_n_tb/scaler_bicubic_m/scaler_cubic_h_m/sum
add wave -noupdate -divider SCALER_V
add wave -noupdate -radix hexadecimal /scaler_bicubic_n_tb/scaler_bicubic_m/scaler_cubic_v_m/di_i
add wave -noupdate /scaler_bicubic_n_tb/scaler_bicubic_m/scaler_cubic_v_m/de_i
add wave -noupdate /scaler_bicubic_n_tb/scaler_bicubic_m/scaler_cubic_v_m/hs_i
add wave -noupdate /scaler_bicubic_n_tb/scaler_bicubic_m/scaler_cubic_v_m/vs_i
add wave -noupdate -radix unsigned /scaler_bicubic_n_tb/scaler_bicubic_m/scaler_cubic_v_m/buf_wcnt
add wave -noupdate -radix unsigned /scaler_bicubic_n_tb/scaler_bicubic_m/scaler_cubic_v_m/cnt_i
add wave -noupdate -radix unsigned /scaler_bicubic_n_tb/scaler_bicubic_m/scaler_cubic_v_m/cnt_o
add wave -noupdate /scaler_bicubic_n_tb/scaler_bicubic_m/scaler_cubic_v_m/de_new
add wave -noupdate /scaler_bicubic_n_tb/scaler_bicubic_m/scaler_cubic_v_m/line
add wave -noupdate /scaler_bicubic_n_tb/scaler_bicubic_m/scaler_cubic_v_m/coe_adr
add wave -noupdate /scaler_bicubic_n_tb/scaler_bicubic_m/scaler_cubic_v_m/coe
add wave -noupdate /scaler_bicubic_n_tb/scaler_bicubic_m/do_o
add wave -noupdate /scaler_bicubic_n_tb/scaler_bicubic_m/de_o
add wave -noupdate /scaler_bicubic_n_tb/scaler_bicubic_m/hs_o
add wave -noupdate /scaler_bicubic_n_tb/scaler_bicubic_m/vs_o
add wave -noupdate -divider {output monitor}
add wave -noupdate /scaler_bicubic_n_tb/monitor_m/di_i
add wave -noupdate /scaler_bicubic_n_tb/monitor_m/de_i
add wave -noupdate /scaler_bicubic_n_tb/monitor_m/hs_i
add wave -noupdate /scaler_bicubic_n_tb/monitor_m/vs_i
add wave -noupdate -radix unsigned /scaler_bicubic_n_tb/monitor_m/xcnt
add wave -noupdate -radix unsigned /scaler_bicubic_n_tb/monitor_m/ycnt
add wave -noupdate -radix unsigned /scaler_bicubic_n_tb/monitor_m/frcnt
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {0 ps} 0}
quietly wave cursor active 0
configure wave -namecolwidth 378
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
configure wave -timelineunits us
update
WaveRestoreZoom {1038252 ps} {1211294 ps}
