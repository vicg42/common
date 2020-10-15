onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -radix ascii /scaler_bicubic_tb/READ_IMG_FILE
add wave -noupdate -radix ascii /scaler_bicubic_tb/WRITE_IMG_FILE
add wave -noupdate -radix unsigned /scaler_bicubic_tb/LINE_IN_SIZE_MAX
add wave -noupdate -radix unsigned /scaler_bicubic_tb/PIXEL_WIDTH
add wave -noupdate /scaler_bicubic_tb/SCALE_COE
add wave -noupdate -radix unsigned /scaler_bicubic_tb/COE_WIDTH
add wave -noupdate -radix unsigned /scaler_bicubic_tb/SPARSE_OUT
add wave -noupdate -divider {New Divider}
add wave -noupdate -color {Slate Blue} -itemcolor Gold -radix unsigned /scaler_bicubic_tb/dbg_cntx_i
add wave -noupdate -color {Slate Blue} -itemcolor Gold -radix unsigned /scaler_bicubic_tb/dbg_cnty_i
add wave -noupdate /scaler_bicubic_tb/di_i
add wave -noupdate /scaler_bicubic_tb/de_i
add wave -noupdate /scaler_bicubic_tb/hs_i
add wave -noupdate /scaler_bicubic_tb/vs_i
add wave -noupdate /scaler_bicubic_tb/scaler_becubic_m/di_s
add wave -noupdate /scaler_bicubic_tb/scaler_becubic_m/de_s
add wave -noupdate /scaler_bicubic_tb/scaler_becubic_m/hs_s
add wave -noupdate /scaler_bicubic_tb/scaler_becubic_m/vs_s
add wave -noupdate -divider SCALER_H
add wave -noupdate -radix unsigned /scaler_bicubic_tb/scaler_becubic_m/scaler_cubic_h_m/scale_step
add wave -noupdate /scaler_bicubic_tb/scaler_becubic_m/scaler_cubic_h_m/dx
add wave -noupdate -expand /scaler_bicubic_tb/scaler_becubic_m/scaler_cubic_h_m/pix
add wave -noupdate -expand /scaler_bicubic_tb/scaler_becubic_m/scaler_cubic_h_m/coe
add wave -noupdate -radix unsigned -childformat {{{/scaler_bicubic_tb/scaler_becubic_m/scaler_cubic_h_m/cnt_i[23]} -radix unsigned} {{/scaler_bicubic_tb/scaler_becubic_m/scaler_cubic_h_m/cnt_i[22]} -radix unsigned} {{/scaler_bicubic_tb/scaler_becubic_m/scaler_cubic_h_m/cnt_i[21]} -radix unsigned} {{/scaler_bicubic_tb/scaler_becubic_m/scaler_cubic_h_m/cnt_i[20]} -radix unsigned} {{/scaler_bicubic_tb/scaler_becubic_m/scaler_cubic_h_m/cnt_i[19]} -radix unsigned} {{/scaler_bicubic_tb/scaler_becubic_m/scaler_cubic_h_m/cnt_i[18]} -radix unsigned} {{/scaler_bicubic_tb/scaler_becubic_m/scaler_cubic_h_m/cnt_i[17]} -radix unsigned} {{/scaler_bicubic_tb/scaler_becubic_m/scaler_cubic_h_m/cnt_i[16]} -radix unsigned} {{/scaler_bicubic_tb/scaler_becubic_m/scaler_cubic_h_m/cnt_i[15]} -radix unsigned} {{/scaler_bicubic_tb/scaler_becubic_m/scaler_cubic_h_m/cnt_i[14]} -radix unsigned} {{/scaler_bicubic_tb/scaler_becubic_m/scaler_cubic_h_m/cnt_i[13]} -radix unsigned} {{/scaler_bicubic_tb/scaler_becubic_m/scaler_cubic_h_m/cnt_i[12]} -radix unsigned} {{/scaler_bicubic_tb/scaler_becubic_m/scaler_cubic_h_m/cnt_i[11]} -radix unsigned} {{/scaler_bicubic_tb/scaler_becubic_m/scaler_cubic_h_m/cnt_i[10]} -radix unsigned} {{/scaler_bicubic_tb/scaler_becubic_m/scaler_cubic_h_m/cnt_i[9]} -radix unsigned} {{/scaler_bicubic_tb/scaler_becubic_m/scaler_cubic_h_m/cnt_i[8]} -radix unsigned} {{/scaler_bicubic_tb/scaler_becubic_m/scaler_cubic_h_m/cnt_i[7]} -radix unsigned} {{/scaler_bicubic_tb/scaler_becubic_m/scaler_cubic_h_m/cnt_i[6]} -radix unsigned} {{/scaler_bicubic_tb/scaler_becubic_m/scaler_cubic_h_m/cnt_i[5]} -radix unsigned} {{/scaler_bicubic_tb/scaler_becubic_m/scaler_cubic_h_m/cnt_i[4]} -radix unsigned} {{/scaler_bicubic_tb/scaler_becubic_m/scaler_cubic_h_m/cnt_i[3]} -radix unsigned} {{/scaler_bicubic_tb/scaler_becubic_m/scaler_cubic_h_m/cnt_i[2]} -radix unsigned} {{/scaler_bicubic_tb/scaler_becubic_m/scaler_cubic_h_m/cnt_i[1]} -radix unsigned} {{/scaler_bicubic_tb/scaler_becubic_m/scaler_cubic_h_m/cnt_i[0]} -radix unsigned}} -subitemconfig {{/scaler_bicubic_tb/scaler_becubic_m/scaler_cubic_h_m/cnt_i[23]} {-height 15 -radix unsigned} {/scaler_bicubic_tb/scaler_becubic_m/scaler_cubic_h_m/cnt_i[22]} {-height 15 -radix unsigned} {/scaler_bicubic_tb/scaler_becubic_m/scaler_cubic_h_m/cnt_i[21]} {-height 15 -radix unsigned} {/scaler_bicubic_tb/scaler_becubic_m/scaler_cubic_h_m/cnt_i[20]} {-height 15 -radix unsigned} {/scaler_bicubic_tb/scaler_becubic_m/scaler_cubic_h_m/cnt_i[19]} {-height 15 -radix unsigned} {/scaler_bicubic_tb/scaler_becubic_m/scaler_cubic_h_m/cnt_i[18]} {-height 15 -radix unsigned} {/scaler_bicubic_tb/scaler_becubic_m/scaler_cubic_h_m/cnt_i[17]} {-height 15 -radix unsigned} {/scaler_bicubic_tb/scaler_becubic_m/scaler_cubic_h_m/cnt_i[16]} {-height 15 -radix unsigned} {/scaler_bicubic_tb/scaler_becubic_m/scaler_cubic_h_m/cnt_i[15]} {-height 15 -radix unsigned} {/scaler_bicubic_tb/scaler_becubic_m/scaler_cubic_h_m/cnt_i[14]} {-height 15 -radix unsigned} {/scaler_bicubic_tb/scaler_becubic_m/scaler_cubic_h_m/cnt_i[13]} {-height 15 -radix unsigned} {/scaler_bicubic_tb/scaler_becubic_m/scaler_cubic_h_m/cnt_i[12]} {-height 15 -radix unsigned} {/scaler_bicubic_tb/scaler_becubic_m/scaler_cubic_h_m/cnt_i[11]} {-height 15 -radix unsigned} {/scaler_bicubic_tb/scaler_becubic_m/scaler_cubic_h_m/cnt_i[10]} {-height 15 -radix unsigned} {/scaler_bicubic_tb/scaler_becubic_m/scaler_cubic_h_m/cnt_i[9]} {-height 15 -radix unsigned} {/scaler_bicubic_tb/scaler_becubic_m/scaler_cubic_h_m/cnt_i[8]} {-height 15 -radix unsigned} {/scaler_bicubic_tb/scaler_becubic_m/scaler_cubic_h_m/cnt_i[7]} {-height 15 -radix unsigned} {/scaler_bicubic_tb/scaler_becubic_m/scaler_cubic_h_m/cnt_i[6]} {-height 15 -radix unsigned} {/scaler_bicubic_tb/scaler_becubic_m/scaler_cubic_h_m/cnt_i[5]} {-height 15 -radix unsigned} {/scaler_bicubic_tb/scaler_becubic_m/scaler_cubic_h_m/cnt_i[4]} {-height 15 -radix unsigned} {/scaler_bicubic_tb/scaler_becubic_m/scaler_cubic_h_m/cnt_i[3]} {-height 15 -radix unsigned} {/scaler_bicubic_tb/scaler_becubic_m/scaler_cubic_h_m/cnt_i[2]} {-height 15 -radix unsigned} {/scaler_bicubic_tb/scaler_becubic_m/scaler_cubic_h_m/cnt_i[1]} {-height 15 -radix unsigned} {/scaler_bicubic_tb/scaler_becubic_m/scaler_cubic_h_m/cnt_i[0]} {-height 15 -radix unsigned}} /scaler_bicubic_tb/scaler_becubic_m/scaler_cubic_h_m/cnt_i
add wave -noupdate /scaler_bicubic_tb/scaler_becubic_m/scaler_cubic_h_m/new_pix
add wave -noupdate /scaler_bicubic_tb/scaler_becubic_m/scaler_cubic_h_m/sof
add wave -noupdate /scaler_bicubic_tb/scaler_becubic_m/scaler_cubic_h_m/new_fr
add wave -noupdate /scaler_bicubic_tb/scaler_becubic_m/scaler_cubic_h_m/sol
add wave -noupdate /scaler_bicubic_tb/scaler_becubic_m/scaler_cubic_h_m/new_line
add wave -noupdate -radix unsigned -childformat {{{/scaler_bicubic_tb/scaler_becubic_m/scaler_cubic_h_m/cnt_o[23]} -radix unsigned} {{/scaler_bicubic_tb/scaler_becubic_m/scaler_cubic_h_m/cnt_o[22]} -radix unsigned} {{/scaler_bicubic_tb/scaler_becubic_m/scaler_cubic_h_m/cnt_o[21]} -radix unsigned} {{/scaler_bicubic_tb/scaler_becubic_m/scaler_cubic_h_m/cnt_o[20]} -radix unsigned} {{/scaler_bicubic_tb/scaler_becubic_m/scaler_cubic_h_m/cnt_o[19]} -radix unsigned} {{/scaler_bicubic_tb/scaler_becubic_m/scaler_cubic_h_m/cnt_o[18]} -radix unsigned} {{/scaler_bicubic_tb/scaler_becubic_m/scaler_cubic_h_m/cnt_o[17]} -radix unsigned} {{/scaler_bicubic_tb/scaler_becubic_m/scaler_cubic_h_m/cnt_o[16]} -radix unsigned} {{/scaler_bicubic_tb/scaler_becubic_m/scaler_cubic_h_m/cnt_o[15]} -radix unsigned} {{/scaler_bicubic_tb/scaler_becubic_m/scaler_cubic_h_m/cnt_o[14]} -radix unsigned} {{/scaler_bicubic_tb/scaler_becubic_m/scaler_cubic_h_m/cnt_o[13]} -radix unsigned} {{/scaler_bicubic_tb/scaler_becubic_m/scaler_cubic_h_m/cnt_o[12]} -radix unsigned} {{/scaler_bicubic_tb/scaler_becubic_m/scaler_cubic_h_m/cnt_o[11]} -radix unsigned} {{/scaler_bicubic_tb/scaler_becubic_m/scaler_cubic_h_m/cnt_o[10]} -radix unsigned} {{/scaler_bicubic_tb/scaler_becubic_m/scaler_cubic_h_m/cnt_o[9]} -radix unsigned} {{/scaler_bicubic_tb/scaler_becubic_m/scaler_cubic_h_m/cnt_o[8]} -radix unsigned} {{/scaler_bicubic_tb/scaler_becubic_m/scaler_cubic_h_m/cnt_o[7]} -radix unsigned} {{/scaler_bicubic_tb/scaler_becubic_m/scaler_cubic_h_m/cnt_o[6]} -radix unsigned} {{/scaler_bicubic_tb/scaler_becubic_m/scaler_cubic_h_m/cnt_o[5]} -radix unsigned} {{/scaler_bicubic_tb/scaler_becubic_m/scaler_cubic_h_m/cnt_o[4]} -radix unsigned} {{/scaler_bicubic_tb/scaler_becubic_m/scaler_cubic_h_m/cnt_o[3]} -radix unsigned} {{/scaler_bicubic_tb/scaler_becubic_m/scaler_cubic_h_m/cnt_o[2]} -radix unsigned} {{/scaler_bicubic_tb/scaler_becubic_m/scaler_cubic_h_m/cnt_o[1]} -radix unsigned} {{/scaler_bicubic_tb/scaler_becubic_m/scaler_cubic_h_m/cnt_o[0]} -radix unsigned}} -subitemconfig {{/scaler_bicubic_tb/scaler_becubic_m/scaler_cubic_h_m/cnt_o[23]} {-height 15 -radix unsigned} {/scaler_bicubic_tb/scaler_becubic_m/scaler_cubic_h_m/cnt_o[22]} {-height 15 -radix unsigned} {/scaler_bicubic_tb/scaler_becubic_m/scaler_cubic_h_m/cnt_o[21]} {-height 15 -radix unsigned} {/scaler_bicubic_tb/scaler_becubic_m/scaler_cubic_h_m/cnt_o[20]} {-height 15 -radix unsigned} {/scaler_bicubic_tb/scaler_becubic_m/scaler_cubic_h_m/cnt_o[19]} {-height 15 -radix unsigned} {/scaler_bicubic_tb/scaler_becubic_m/scaler_cubic_h_m/cnt_o[18]} {-height 15 -radix unsigned} {/scaler_bicubic_tb/scaler_becubic_m/scaler_cubic_h_m/cnt_o[17]} {-height 15 -radix unsigned} {/scaler_bicubic_tb/scaler_becubic_m/scaler_cubic_h_m/cnt_o[16]} {-height 15 -radix unsigned} {/scaler_bicubic_tb/scaler_becubic_m/scaler_cubic_h_m/cnt_o[15]} {-height 15 -radix unsigned} {/scaler_bicubic_tb/scaler_becubic_m/scaler_cubic_h_m/cnt_o[14]} {-height 15 -radix unsigned} {/scaler_bicubic_tb/scaler_becubic_m/scaler_cubic_h_m/cnt_o[13]} {-height 15 -radix unsigned} {/scaler_bicubic_tb/scaler_becubic_m/scaler_cubic_h_m/cnt_o[12]} {-height 15 -radix unsigned} {/scaler_bicubic_tb/scaler_becubic_m/scaler_cubic_h_m/cnt_o[11]} {-height 15 -radix unsigned} {/scaler_bicubic_tb/scaler_becubic_m/scaler_cubic_h_m/cnt_o[10]} {-height 15 -radix unsigned} {/scaler_bicubic_tb/scaler_becubic_m/scaler_cubic_h_m/cnt_o[9]} {-height 15 -radix unsigned} {/scaler_bicubic_tb/scaler_becubic_m/scaler_cubic_h_m/cnt_o[8]} {-height 15 -radix unsigned} {/scaler_bicubic_tb/scaler_becubic_m/scaler_cubic_h_m/cnt_o[7]} {-height 15 -radix unsigned} {/scaler_bicubic_tb/scaler_becubic_m/scaler_cubic_h_m/cnt_o[6]} {-height 15 -radix unsigned} {/scaler_bicubic_tb/scaler_becubic_m/scaler_cubic_h_m/cnt_o[5]} {-height 15 -radix unsigned} {/scaler_bicubic_tb/scaler_becubic_m/scaler_cubic_h_m/cnt_o[4]} {-height 15 -radix unsigned} {/scaler_bicubic_tb/scaler_becubic_m/scaler_cubic_h_m/cnt_o[3]} {-height 15 -radix unsigned} {/scaler_bicubic_tb/scaler_becubic_m/scaler_cubic_h_m/cnt_o[2]} {-height 15 -radix unsigned} {/scaler_bicubic_tb/scaler_becubic_m/scaler_cubic_h_m/cnt_o[1]} {-height 15 -radix unsigned} {/scaler_bicubic_tb/scaler_becubic_m/scaler_cubic_h_m/cnt_o[0]} {-height 15 -radix unsigned}} /scaler_bicubic_tb/scaler_becubic_m/scaler_cubic_h_m/cnt_o
add wave -noupdate -divider SCALER_V
add wave -noupdate -radix hexadecimal /scaler_bicubic_tb/scaler_becubic_m/scaler_cubic_v_m/di_i
add wave -noupdate /scaler_bicubic_tb/scaler_becubic_m/scaler_cubic_v_m/de_i
add wave -noupdate /scaler_bicubic_tb/scaler_becubic_m/scaler_cubic_v_m/hs_i
add wave -noupdate /scaler_bicubic_tb/scaler_becubic_m/scaler_cubic_v_m/vs_i
add wave -noupdate -radix unsigned /scaler_bicubic_tb/scaler_becubic_m/scaler_cubic_v_m/scale_step
add wave -noupdate -radix unsigned -childformat {{{/scaler_bicubic_tb/scaler_becubic_m/scaler_cubic_v_m/dy[5]} -radix unsigned} {{/scaler_bicubic_tb/scaler_becubic_m/scaler_cubic_v_m/dy[4]} -radix unsigned} {{/scaler_bicubic_tb/scaler_becubic_m/scaler_cubic_v_m/dy[3]} -radix unsigned} {{/scaler_bicubic_tb/scaler_becubic_m/scaler_cubic_v_m/dy[2]} -radix unsigned} {{/scaler_bicubic_tb/scaler_becubic_m/scaler_cubic_v_m/dy[1]} -radix unsigned} {{/scaler_bicubic_tb/scaler_becubic_m/scaler_cubic_v_m/dy[0]} -radix unsigned}} -subitemconfig {{/scaler_bicubic_tb/scaler_becubic_m/scaler_cubic_v_m/dy[5]} {-height 15 -radix unsigned} {/scaler_bicubic_tb/scaler_becubic_m/scaler_cubic_v_m/dy[4]} {-height 15 -radix unsigned} {/scaler_bicubic_tb/scaler_becubic_m/scaler_cubic_v_m/dy[3]} {-height 15 -radix unsigned} {/scaler_bicubic_tb/scaler_becubic_m/scaler_cubic_v_m/dy[2]} {-height 15 -radix unsigned} {/scaler_bicubic_tb/scaler_becubic_m/scaler_cubic_v_m/dy[1]} {-height 15 -radix unsigned} {/scaler_bicubic_tb/scaler_becubic_m/scaler_cubic_v_m/dy[0]} {-height 15 -radix unsigned}} /scaler_bicubic_tb/scaler_becubic_m/scaler_cubic_v_m/dy
add wave -noupdate -radix unsigned /scaler_bicubic_tb/scaler_becubic_m/scaler_cubic_v_m/cnt_i
add wave -noupdate -radix unsigned /scaler_bicubic_tb/scaler_becubic_m/scaler_cubic_v_m/buf_wcnt
add wave -noupdate /scaler_bicubic_tb/scaler_becubic_m/scaler_cubic_v_m/buf_wsel
add wave -noupdate -color {Slate Blue} -itemcolor Gold /scaler_bicubic_tb/scaler_becubic_m/scaler_cubic_v_m/fsm_cs
add wave -noupdate -radix unsigned /scaler_bicubic_tb/scaler_becubic_m/scaler_cubic_v_m/cnt_o
add wave -noupdate -radix unsigned /scaler_bicubic_tb/scaler_becubic_m/scaler_cubic_v_m/buf_rcnt
add wave -noupdate -radix unsigned /scaler_bicubic_tb/scaler_becubic_m/scaler_cubic_v_m/cnt_sparse
add wave -noupdate -expand /scaler_bicubic_tb/scaler_becubic_m/scaler_cubic_v_m/buf_do
add wave -noupdate -expand /scaler_bicubic_tb/scaler_becubic_m/scaler_cubic_v_m/line
add wave -noupdate -expand /scaler_bicubic_tb/scaler_becubic_m/scaler_cubic_v_m/coe
add wave -noupdate /scaler_bicubic_tb/scaler_becubic_m/scaler_cubic_v_m/do_o
add wave -noupdate -expand /scaler_bicubic_tb/scaler_becubic_m/scaler_cubic_v_m/sr_de_o_early
add wave -noupdate /scaler_bicubic_tb/scaler_becubic_m/scaler_cubic_v_m/sr_hs_o_early
add wave -noupdate /scaler_bicubic_tb/scaler_becubic_m/scaler_cubic_v_m/sr_vs_o_early
add wave -noupdate /scaler_bicubic_tb/scaler_becubic_m/scaler_cubic_v_m/do_o
add wave -noupdate /scaler_bicubic_tb/scaler_becubic_m/scaler_cubic_v_m/de_o
add wave -noupdate /scaler_bicubic_tb/scaler_becubic_m/scaler_cubic_v_m/hs_o
add wave -noupdate /scaler_bicubic_tb/scaler_becubic_m/scaler_cubic_v_m/vs_o
add wave -noupdate -divider {output monitor}
add wave -noupdate -color {Slate Blue} -itemcolor Gold -radix unsigned /scaler_bicubic_tb/monitor_m/xcnt
add wave -noupdate -color {Slate Blue} -itemcolor Gold -radix unsigned /scaler_bicubic_tb/monitor_m/ycnt
add wave -noupdate -radix unsigned /scaler_bicubic_tb/monitor_m/frcnt
add wave -noupdate -radix unsigned /scaler_bicubic_tb/monitor_m/wen
add wave -noupdate /scaler_bicubic_tb/monitor_m/di
add wave -noupdate /scaler_bicubic_tb/monitor_m/de
add wave -noupdate /scaler_bicubic_tb/monitor_m/hs
add wave -noupdate /scaler_bicubic_tb/monitor_m/vs
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
WaveRestoreZoom {0 ps} {26491798 ps}
