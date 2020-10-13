onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -radix unsigned /scaler_v_tb/PIXEL_WIDTH
add wave -noupdate -radix unsigned /scaler_v_tb/scaler_v_m/LINE_STEP
add wave -noupdate /scaler_v_tb/V_SCALE
add wave -noupdate -radix unsigned /scaler_v_tb/scaler_v_m/di_i
add wave -noupdate /scaler_v_tb/scaler_v_m/de_i
add wave -noupdate /scaler_v_tb/scaler_v_m/hs_i
add wave -noupdate /scaler_v_tb/scaler_v_m/vs_i
add wave -noupdate -radix unsigned /scaler_v_tb/scaler_v_m/buf_wcnt
add wave -noupdate /scaler_v_tb/scaler_v_m/buf_wsel
add wave -noupdate -radix unsigned /scaler_v_tb/scaler_v_m/cnt_i
add wave -noupdate -expand /scaler_v_tb/scaler_v_m/coe
add wave -noupdate -expand /scaler_v_tb/scaler_v_m/m
add wave -noupdate -color {Slate Blue} -itemcolor Gold /scaler_v_tb/scaler_v_m/fsm_cs
add wave -noupdate -radix unsigned -childformat {{{/scaler_v_tb/scaler_v_m/dy[9]} -radix unsigned} {{/scaler_v_tb/scaler_v_m/dy[8]} -radix unsigned} {{/scaler_v_tb/scaler_v_m/dy[7]} -radix unsigned} {{/scaler_v_tb/scaler_v_m/dy[6]} -radix unsigned} {{/scaler_v_tb/scaler_v_m/dy[5]} -radix unsigned} {{/scaler_v_tb/scaler_v_m/dy[4]} -radix unsigned} {{/scaler_v_tb/scaler_v_m/dy[3]} -radix unsigned} {{/scaler_v_tb/scaler_v_m/dy[2]} -radix unsigned} {{/scaler_v_tb/scaler_v_m/dy[1]} -radix unsigned} {{/scaler_v_tb/scaler_v_m/dy[0]} -radix unsigned}} -subitemconfig {{/scaler_v_tb/scaler_v_m/dy[9]} {-height 15 -radix unsigned} {/scaler_v_tb/scaler_v_m/dy[8]} {-height 15 -radix unsigned} {/scaler_v_tb/scaler_v_m/dy[7]} {-height 15 -radix unsigned} {/scaler_v_tb/scaler_v_m/dy[6]} {-height 15 -radix unsigned} {/scaler_v_tb/scaler_v_m/dy[5]} {-height 15 -radix unsigned} {/scaler_v_tb/scaler_v_m/dy[4]} {-height 15 -radix unsigned} {/scaler_v_tb/scaler_v_m/dy[3]} {-height 15 -radix unsigned} {/scaler_v_tb/scaler_v_m/dy[2]} {-height 15 -radix unsigned} {/scaler_v_tb/scaler_v_m/dy[1]} {-height 15 -radix unsigned} {/scaler_v_tb/scaler_v_m/dy[0]} {-height 15 -radix unsigned}} /scaler_v_tb/scaler_v_m/dy
add wave -noupdate -radix unsigned /scaler_v_tb/scaler_v_m/cnt_sparse
add wave -noupdate -radix unsigned /scaler_v_tb/scaler_v_m/cnt_o
add wave -noupdate -radix unsigned /scaler_v_tb/scaler_v_m/do_o
add wave -noupdate /scaler_v_tb/scaler_v_m/de_o
add wave -noupdate /scaler_v_tb/scaler_v_m/hs_o
add wave -noupdate /scaler_v_tb/scaler_v_m/vs_o
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {0 ps} 0}
quietly wave cursor active 0
configure wave -namecolwidth 215
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
WaveRestoreZoom {22679464 ps} {22731191 ps}
