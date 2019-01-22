onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /filter_core_3x3_tb/filter_core_3x3/clk
add wave -noupdate -radix unsigned /filter_core_3x3_tb/filter_core_3x3/DE_I_PERIOD
add wave -noupdate -radix unsigned /filter_core_3x3_tb/filter_core_3x3/PIPELINE
add wave -noupdate /filter_core_3x3_tb/filter_core_3x3/bypass
add wave -noupdate -radix unsigned /filter_core_3x3_tb/filter_core_3x3/di_i
add wave -noupdate /filter_core_3x3_tb/filter_core_3x3/de_i
add wave -noupdate /filter_core_3x3_tb/filter_core_3x3/hs_i
add wave -noupdate /filter_core_3x3_tb/filter_core_3x3/vs_i
add wave -noupdate /filter_core_3x3_tb/filter_core_3x3/sr_vs_i
add wave -noupdate /filter_core_3x3_tb/filter_core_3x3/sr_hs_i
add wave -noupdate /filter_core_3x3_tb/filter_core_3x3/sr_de_i
add wave -noupdate /filter_core_3x3_tb/filter_core_3x3/vs_opt
add wave -noupdate /filter_core_3x3_tb/filter_core_3x3/line_out_en
add wave -noupdate /filter_core_3x3_tb/filter_core_3x3/buf_wptr_clr
add wave -noupdate /filter_core_3x3_tb/filter_core_3x3/buf_wptr_en
add wave -noupdate -radix unsigned /filter_core_3x3_tb/filter_core_3x3/buf_wptr
add wave -noupdate -radix unsigned /filter_core_3x3_tb/filter_core_3x3/buf0_do
add wave -noupdate -radix unsigned /filter_core_3x3_tb/filter_core_3x3/buf1_do
add wave -noupdate /filter_core_3x3_tb/filter_core_3x3/vs_opt
add wave -noupdate /filter_core_3x3_tb/filter_core_3x3/de_o
add wave -noupdate /filter_core_3x3_tb/filter_core_3x3/hs_o
add wave -noupdate /filter_core_3x3_tb/filter_core_3x3/vs_o
add wave -noupdate -radix unsigned /filter_core_3x3_tb/filter_core_3x3/x1
add wave -noupdate -radix unsigned /filter_core_3x3_tb/filter_core_3x3/x2
add wave -noupdate -radix unsigned /filter_core_3x3_tb/filter_core_3x3/x3
add wave -noupdate -radix unsigned /filter_core_3x3_tb/filter_core_3x3/x4
add wave -noupdate -radix unsigned /filter_core_3x3_tb/filter_core_3x3/x5
add wave -noupdate -radix unsigned /filter_core_3x3_tb/filter_core_3x3/x6
add wave -noupdate -radix unsigned /filter_core_3x3_tb/filter_core_3x3/x7
add wave -noupdate -radix unsigned /filter_core_3x3_tb/filter_core_3x3/x8
add wave -noupdate -radix unsigned /filter_core_3x3_tb/filter_core_3x3/x9
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 2} {4464000 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 329
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
WaveRestoreZoom {0 ps} {15750 ns}
