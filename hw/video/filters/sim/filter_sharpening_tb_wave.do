onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /filter_sharpening_tb/clk
add wave -noupdate /filter_sharpening_tb/filter_sharpening/di_i
add wave -noupdate /filter_sharpening_tb/filter_sharpening/de_i
add wave -noupdate /filter_sharpening_tb/filter_sharpening/hs_i
add wave -noupdate /filter_sharpening_tb/filter_sharpening/vs_i
add wave -noupdate -divider {New Divider}
add wave -noupdate /filter_sharpening_tb/filter_sharpening/filter_core/bypass
add wave -noupdate /filter_sharpening_tb/filter_sharpening/sr_hs
add wave -noupdate /filter_sharpening_tb/filter_sharpening/sr_vs
add wave -noupdate -divider {New Divider}
add wave -noupdate -radix unsigned /filter_sharpening_tb/filter_sharpening/filter_core/x1
add wave -noupdate -radix unsigned /filter_sharpening_tb/filter_sharpening/filter_core/x2
add wave -noupdate -radix unsigned /filter_sharpening_tb/filter_sharpening/filter_core/x3
add wave -noupdate -radix unsigned /filter_sharpening_tb/filter_sharpening/filter_core/x4
add wave -noupdate -radix unsigned /filter_sharpening_tb/filter_sharpening/filter_core/x5
add wave -noupdate -radix unsigned /filter_sharpening_tb/filter_sharpening/filter_core/x6
add wave -noupdate -radix unsigned /filter_sharpening_tb/filter_sharpening/filter_core/x7
add wave -noupdate -radix unsigned /filter_sharpening_tb/filter_sharpening/filter_core/x8
add wave -noupdate -radix unsigned /filter_sharpening_tb/filter_sharpening/filter_core/x9
add wave -noupdate -divider {New Divider}
add wave -noupdate -divider {New Divider}
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {21007 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 470
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
WaveRestoreZoom {0 ps} {4200 us}
