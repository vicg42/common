onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /filter_median_tb/filter_median/di_i
add wave -noupdate /filter_median_tb/filter_median/de_i
add wave -noupdate /filter_median_tb/filter_median/hs_i
add wave -noupdate /filter_median_tb/filter_median/vs_i
add wave -noupdate -radix unsigned /filter_median_tb/filter_median/p1
add wave -noupdate -radix unsigned /filter_median_tb/filter_median/p2
add wave -noupdate -radix unsigned /filter_median_tb/filter_median/p3
add wave -noupdate -radix unsigned /filter_median_tb/filter_median/p4
add wave -noupdate -radix unsigned /filter_median_tb/filter_median/p5
add wave -noupdate -radix unsigned /filter_median_tb/filter_median/p6
add wave -noupdate -radix unsigned /filter_median_tb/filter_median/p7
add wave -noupdate -radix unsigned /filter_median_tb/filter_median/p8
add wave -noupdate -radix unsigned /filter_median_tb/filter_median/p9
add wave -noupdate /filter_median_tb/filter_median/median
add wave -noupdate -radix unsigned /filter_median_tb/filter_median/do_o
add wave -noupdate /filter_median_tb/filter_median/de_o
add wave -noupdate /filter_median_tb/filter_median/hs_o
add wave -noupdate /filter_median_tb/filter_median/vs_o
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {0 ps} 0}
quietly wave cursor active 0
configure wave -namecolwidth 344
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
WaveRestoreZoom {20955489 ps} {21094639 ps}
