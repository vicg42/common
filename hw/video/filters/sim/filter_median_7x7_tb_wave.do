onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -radix unsigned /filter_median_7x7_tb/w
add wave -noupdate -radix unsigned /filter_median_7x7_tb/h
add wave -noupdate -radix unsigned /filter_median_7x7_tb/x
add wave -noupdate -radix unsigned /filter_median_7x7_tb/y
add wave -noupdate -divider input
add wave -noupdate /filter_median_7x7_tb/filter_median/clk
add wave -noupdate /filter_median_7x7_tb/filter_median/di_i
add wave -noupdate /filter_median_7x7_tb/filter_median/de_i
add wave -noupdate /filter_median_7x7_tb/filter_median/hs_i
add wave -noupdate /filter_median_7x7_tb/filter_median/vs_i
add wave -noupdate -divider filter_core
add wave -noupdate /filter_median_7x7_tb/filter_median/filter_core_7x7/de_o
add wave -noupdate /filter_median_7x7_tb/filter_median/filter_core_7x7/hs_o
add wave -noupdate /filter_median_7x7_tb/filter_median/filter_core_7x7/vs_o
add wave -noupdate -divider filter_entity
add wave -noupdate /filter_median_7x7_tb/filter_median/xi
add wave -noupdate -divider output
add wave -noupdate /filter_median_7x7_tb/filter_median/do_o
add wave -noupdate /filter_median_7x7_tb/filter_median/de_o
add wave -noupdate /filter_median_7x7_tb/filter_median/hs_o
add wave -noupdate /filter_median_7x7_tb/filter_median/vs_o
add wave -noupdate /filter_median_7x7_tb/filter_median/bypass_o
add wave -noupdate -divider monitor
add wave -noupdate -radix unsigned /filter_median_7x7_tb/monitor/xcnt
add wave -noupdate -radix unsigned /filter_median_7x7_tb/monitor/ycnt
add wave -noupdate -radix unsigned /filter_median_7x7_tb/monitor/frcnt
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {0 ps} 0}
quietly wave cursor active 0
configure wave -namecolwidth 121
configure wave -valuecolwidth 67
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
WaveRestoreZoom {0 ps} {105 us}
