onerror {resume}
quietly virtual function -install /scaler_h_tb/scaler_h -env /scaler_h_tb { &{/scaler_h_tb/scaler_h/cnt_pix_i[11], /scaler_h_tb/scaler_h/cnt_pix_i[10], /scaler_h_tb/scaler_h/cnt_pix_i[9], /scaler_h_tb/scaler_h/cnt_pix_i[8], /scaler_h_tb/scaler_h/cnt_pix_i[7], /scaler_h_tb/scaler_h/cnt_pix_i[6], /scaler_h_tb/scaler_h/cnt_pix_i[5], /scaler_h_tb/scaler_h/cnt_pix_i[4], /scaler_h_tb/scaler_h/cnt_pix_i[3], /scaler_h_tb/scaler_h/cnt_pix_i[2], /scaler_h_tb/scaler_h/cnt_pix_i[1], /scaler_h_tb/scaler_h/cnt_pix_i[0] }} cnt_pix_i_11_0
quietly virtual function -install /scaler_h_tb/scaler_h -env /scaler_h_tb { &{/scaler_h_tb/scaler_h/cnt_pix_i[23], /scaler_h_tb/scaler_h/cnt_pix_i[22], /scaler_h_tb/scaler_h/cnt_pix_i[21], /scaler_h_tb/scaler_h/cnt_pix_i[20], /scaler_h_tb/scaler_h/cnt_pix_i[19], /scaler_h_tb/scaler_h/cnt_pix_i[18], /scaler_h_tb/scaler_h/cnt_pix_i[17], /scaler_h_tb/scaler_h/cnt_pix_i[16], /scaler_h_tb/scaler_h/cnt_pix_i[15], /scaler_h_tb/scaler_h/cnt_pix_i[14], /scaler_h_tb/scaler_h/cnt_pix_i[13], /scaler_h_tb/scaler_h/cnt_pix_i[12] }} cnt_pix_i_23_12
quietly virtual function -install /scaler_h_tb/scaler_h -env /scaler_h_tb { &{/scaler_h_tb/scaler_h/cnt_pix_o[23], /scaler_h_tb/scaler_h/cnt_pix_o[22], /scaler_h_tb/scaler_h/cnt_pix_o[21], /scaler_h_tb/scaler_h/cnt_pix_o[20], /scaler_h_tb/scaler_h/cnt_pix_o[19], /scaler_h_tb/scaler_h/cnt_pix_o[18], /scaler_h_tb/scaler_h/cnt_pix_o[17], /scaler_h_tb/scaler_h/cnt_pix_o[16], /scaler_h_tb/scaler_h/cnt_pix_o[15], /scaler_h_tb/scaler_h/cnt_pix_o[14], /scaler_h_tb/scaler_h/cnt_pix_o[13], /scaler_h_tb/scaler_h/cnt_pix_o[12] }} cnt_pix_o_23_12
quietly virtual function -install /scaler_h_tb/scaler_h -env /scaler_h_tb { &{/scaler_h_tb/scaler_h/cnt_pix_o[11], /scaler_h_tb/scaler_h/cnt_pix_o[10], /scaler_h_tb/scaler_h/cnt_pix_o[9], /scaler_h_tb/scaler_h/cnt_pix_o[8], /scaler_h_tb/scaler_h/cnt_pix_o[7], /scaler_h_tb/scaler_h/cnt_pix_o[6], /scaler_h_tb/scaler_h/cnt_pix_o[5], /scaler_h_tb/scaler_h/cnt_pix_o[4], /scaler_h_tb/scaler_h/cnt_pix_o[3], /scaler_h_tb/scaler_h/cnt_pix_o[2], /scaler_h_tb/scaler_h/cnt_pix_o[1], /scaler_h_tb/scaler_h/cnt_pix_o[0] }} cnt_pix_o_11_0
quietly WaveActivateNextPane {} 0
add wave -noupdate /scaler_h_tb/SCALE_FACTOR
add wave -noupdate -radix unsigned /scaler_h_tb/dbg_cnt_i
add wave -noupdate /scaler_h_tb/de_i
add wave -noupdate /scaler_h_tb/hs_i
add wave -noupdate /scaler_h_tb/vs_i
add wave -noupdate -divider INPUT
add wave -noupdate /scaler_h_tb/scaler_h/rst
add wave -noupdate /scaler_h_tb/scaler_h/clk
add wave -noupdate /scaler_h_tb/scaler_h/di_i
add wave -noupdate -expand /scaler_h_tb/scaler_h/sr_di_i
add wave -noupdate /scaler_h_tb/scaler_h/de_i
add wave -noupdate /scaler_h_tb/scaler_h/hs_i
add wave -noupdate /scaler_h_tb/scaler_h/vs_i
add wave -noupdate -divider {New Divider}
add wave -noupdate /scaler_h_tb/scaler_h/PIXEL_STEP
add wave -noupdate -radix unsigned /scaler_h_tb/scaler_h/cnt_pix_i_23_12
add wave -noupdate /scaler_h_tb/scaler_h/cnt_pix_i_11_0
add wave -noupdate -radix unsigned /scaler_h_tb/scaler_h/cnt_pix_o_23_12
add wave -noupdate /scaler_h_tb/scaler_h/cnt_pix_o_11_0
add wave -noupdate /scaler_h_tb/scaler_h/cnt_pix_i
add wave -noupdate /scaler_h_tb/scaler_h/cnt_pix_o
add wave -noupdate /scaler_h_tb/scaler_h/hs
add wave -noupdate /scaler_h_tb/SCALE_FACTOR
add wave -noupdate /scaler_h_tb/scaler_h/scale_step
add wave -noupdate /scaler_h_tb/scaler_h/new_pix
add wave -noupdate -expand /scaler_h_tb/scaler_h/pix
add wave -noupdate -childformat {{{/scaler_h_tb/scaler_h/coe[0]} -radix decimal} {{/scaler_h_tb/scaler_h/coe[1]} -radix decimal} {{/scaler_h_tb/scaler_h/coe[2]} -radix decimal} {{/scaler_h_tb/scaler_h/coe[3]} -radix decimal}} -expand -subitemconfig {{/scaler_h_tb/scaler_h/coe[0]} {-height 15 -radix decimal} {/scaler_h_tb/scaler_h/coe[1]} {-height 15 -radix decimal} {/scaler_h_tb/scaler_h/coe[2]} {-height 15 -radix decimal} {/scaler_h_tb/scaler_h/coe[3]} {-height 15 -radix decimal}} /scaler_h_tb/scaler_h/coe
add wave -noupdate -divider OUTPUT
add wave -noupdate -radix unsigned /scaler_h_tb/dbg_cnt_o
add wave -noupdate /scaler_h_tb/scaler_h/de_o
add wave -noupdate /scaler_h_tb/scaler_h/hs_o
add wave -noupdate /scaler_h_tb/scaler_h/vs_o
add wave -noupdate /scaler_h_tb/scaler_h/do_o
add wave -noupdate -divider Monitor
add wave -noupdate /scaler_h_tb/monitor/result_en
add wave -noupdate -radix unsigned /scaler_h_tb/monitor/data_size
add wave -noupdate -radix unsigned /scaler_h_tb/monitor/xcnt
add wave -noupdate -radix unsigned /scaler_h_tb/monitor/ycnt
add wave -noupdate -radix unsigned /scaler_h_tb/monitor/frcnt
TreeUpdate [SetDefaultTree]
WaveRestoreCursors
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
WaveRestoreZoom {0 ps} {5880 ns}