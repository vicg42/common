onerror {resume}
quietly virtual function -install /scaler_v_tb/scaler_v -env /scaler_v_tb { &{/scaler_v_tb/scaler_v/cnt_line_i[11], /scaler_v_tb/scaler_v/cnt_line_i[10], /scaler_v_tb/scaler_v/cnt_line_i[9], /scaler_v_tb/scaler_v/cnt_line_i[8], /scaler_v_tb/scaler_v/cnt_line_i[7], /scaler_v_tb/scaler_v/cnt_line_i[6], /scaler_v_tb/scaler_v/cnt_line_i[5], /scaler_v_tb/scaler_v/cnt_line_i[4], /scaler_v_tb/scaler_v/cnt_line_i[3], /scaler_v_tb/scaler_v/cnt_line_i[2], /scaler_v_tb/scaler_v/cnt_line_i[1], /scaler_v_tb/scaler_v/cnt_line_i[0] }} cnt_line_i_11_0
quietly virtual function -install /scaler_v_tb/scaler_v -env /scaler_v_tb { &{/scaler_v_tb/scaler_v/cnt_line_i[23], /scaler_v_tb/scaler_v/cnt_line_i[22], /scaler_v_tb/scaler_v/cnt_line_i[21], /scaler_v_tb/scaler_v/cnt_line_i[20], /scaler_v_tb/scaler_v/cnt_line_i[19], /scaler_v_tb/scaler_v/cnt_line_i[18], /scaler_v_tb/scaler_v/cnt_line_i[17], /scaler_v_tb/scaler_v/cnt_line_i[16], /scaler_v_tb/scaler_v/cnt_line_i[15], /scaler_v_tb/scaler_v/cnt_line_i[14], /scaler_v_tb/scaler_v/cnt_line_i[13], /scaler_v_tb/scaler_v/cnt_line_i[12] }} cnt_line_i_23_12
quietly virtual function -install /scaler_v_tb/scaler_v -env /scaler_v_tb { &{/scaler_v_tb/scaler_v/cnt_line_o[11], /scaler_v_tb/scaler_v/cnt_line_o[10], /scaler_v_tb/scaler_v/cnt_line_o[9], /scaler_v_tb/scaler_v/cnt_line_o[8], /scaler_v_tb/scaler_v/cnt_line_o[7], /scaler_v_tb/scaler_v/cnt_line_o[6], /scaler_v_tb/scaler_v/cnt_line_o[5], /scaler_v_tb/scaler_v/cnt_line_o[4], /scaler_v_tb/scaler_v/cnt_line_o[3], /scaler_v_tb/scaler_v/cnt_line_o[2], /scaler_v_tb/scaler_v/cnt_line_o[1], /scaler_v_tb/scaler_v/cnt_line_o[0] }} cnt_line_o_11_0
quietly virtual function -install /scaler_v_tb/scaler_v -env /scaler_v_tb { &{/scaler_v_tb/scaler_v/cnt_line_o[23], /scaler_v_tb/scaler_v/cnt_line_o[22], /scaler_v_tb/scaler_v/cnt_line_o[21], /scaler_v_tb/scaler_v/cnt_line_o[20], /scaler_v_tb/scaler_v/cnt_line_o[19], /scaler_v_tb/scaler_v/cnt_line_o[18], /scaler_v_tb/scaler_v/cnt_line_o[17], /scaler_v_tb/scaler_v/cnt_line_o[16], /scaler_v_tb/scaler_v/cnt_line_o[15], /scaler_v_tb/scaler_v/cnt_line_o[14], /scaler_v_tb/scaler_v/cnt_line_o[13], /scaler_v_tb/scaler_v/cnt_line_o[12] }} cnt_line_o_23_12
quietly WaveActivateNextPane {} 0
add wave -noupdate /scaler_v_tb/SCALE_FACTOR
add wave -noupdate -radix unsigned /scaler_v_tb/dbg_cnt_i
add wave -noupdate /scaler_v_tb/clk
add wave -noupdate /scaler_v_tb/de_i
add wave -noupdate /scaler_v_tb/hs_i
add wave -noupdate /scaler_v_tb/vs_i
add wave -noupdate /scaler_v_tb/scaler_v/i_di
add wave -noupdate /scaler_v_tb/scaler_v/i_de
add wave -noupdate /scaler_v_tb/scaler_v/i_hs_edge
add wave -noupdate /scaler_v_tb/scaler_v/i_vs_edge
add wave -noupdate -divider SCALER_V
add wave -noupdate -radix unsigned /scaler_v_tb/scaler_v/LINE_STEP
add wave -noupdate -radix unsigned /scaler_v_tb/scaler_v/cnt_line_i_23_12
add wave -noupdate /scaler_v_tb/scaler_v/cnt_line_i_11_0
add wave -noupdate /scaler_v_tb/scaler_v/cnt_line_i
add wave -noupdate /scaler_v_tb/scaler_v/dbuf_num
add wave -noupdate -radix unsigned /scaler_v_tb/scaler_v/dbuf_wrcnt
add wave -noupdate /scaler_v_tb/scaler_v/dbuf
add wave -noupdate -color {Slate Blue} -itemcolor Gold /scaler_v_tb/scaler_v/fsm_cs
add wave -noupdate /scaler_v_tb/scaler_v/scale_line_size
add wave -noupdate -radix unsigned /scaler_v_tb/scaler_v/dbuf_rdcnt
add wave -noupdate /scaler_v_tb/scaler_v/dbuf_do
add wave -noupdate /scaler_v_tb/scaler_v/o_de
add wave -noupdate /scaler_v_tb/scaler_v/o_hs
add wave -noupdate -radix unsigned /scaler_v_tb/scaler_v/cnt_line_o_23_12
add wave -noupdate /scaler_v_tb/scaler_v/cnt_line_o_11_0
add wave -noupdate /scaler_v_tb/scaler_v/cnt_line_o
add wave -noupdate -radix unsigned -childformat {{{/scaler_v_tb/scaler_v/pix[0]} -radix unsigned} {{/scaler_v_tb/scaler_v/pix[1]} -radix unsigned} {{/scaler_v_tb/scaler_v/pix[2]} -radix unsigned} {{/scaler_v_tb/scaler_v/pix[3]} -radix unsigned}} -expand -subitemconfig {{/scaler_v_tb/scaler_v/pix[0]} {-height 15 -radix unsigned} {/scaler_v_tb/scaler_v/pix[1]} {-height 15 -radix unsigned} {/scaler_v_tb/scaler_v/pix[2]} {-height 15 -radix unsigned} {/scaler_v_tb/scaler_v/pix[3]} {-height 15 -radix unsigned}} /scaler_v_tb/scaler_v/pix
add wave -noupdate /scaler_v_tb/scaler_v/hs_out_early
add wave -noupdate -divider Monitor
add wave -noupdate -radix unsigned /scaler_v_tb/monitor/di_i
add wave -noupdate /scaler_v_tb/monitor/de_i
add wave -noupdate /scaler_v_tb/monitor/hs_i
add wave -noupdate /scaler_v_tb/monitor/vs_i
add wave -noupdate -radix unsigned /scaler_v_tb/dbg_cnt_o
add wave -noupdate /scaler_v_tb/monitor/result_en
add wave -noupdate -radix unsigned /scaler_v_tb/monitor/data_size
add wave -noupdate -radix unsigned /scaler_v_tb/monitor/xcnt
add wave -noupdate -radix unsigned /scaler_v_tb/monitor/ycnt
add wave -noupdate -radix unsigned /scaler_v_tb/monitor/frcnt
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {0 ps} 0}
quietly wave cursor active 0
configure wave -namecolwidth 234
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
WaveRestoreZoom {0 ps} {77324288 ps}
