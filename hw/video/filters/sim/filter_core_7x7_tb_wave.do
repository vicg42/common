onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -radix unsigned /filter_core_7x7_tb/w
add wave -noupdate -radix unsigned /filter_core_7x7_tb/h
add wave -noupdate -radix unsigned /filter_core_7x7_tb/x
add wave -noupdate -radix unsigned /filter_core_7x7_tb/y
add wave -noupdate /filter_core_7x7_tb/filter_core/bypass
add wave -noupdate -divider input
add wave -noupdate /filter_core_7x7_tb/filter_core/di_i
add wave -noupdate /filter_core_7x7_tb/filter_core/de_i
add wave -noupdate /filter_core_7x7_tb/filter_core/hs_i
add wave -noupdate /filter_core_7x7_tb/filter_core/vs_i
add wave -noupdate -divider entity
add wave -noupdate /filter_core_7x7_tb/filter_core/buf0
add wave -noupdate /filter_core_7x7_tb/filter_core/buf1
add wave -noupdate /filter_core_7x7_tb/filter_core/buf2
add wave -noupdate /filter_core_7x7_tb/filter_core/buf3
add wave -noupdate /filter_core_7x7_tb/filter_core/buf4
add wave -noupdate /filter_core_7x7_tb/filter_core/buf5
add wave -noupdate /filter_core_7x7_tb/filter_core/buf6
add wave -noupdate /filter_core_7x7_tb/filter_core/x00
add wave -noupdate /filter_core_7x7_tb/filter_core/x01
add wave -noupdate /filter_core_7x7_tb/filter_core/x02
add wave -noupdate /filter_core_7x7_tb/filter_core/x03
add wave -noupdate /filter_core_7x7_tb/filter_core/x04
add wave -noupdate /filter_core_7x7_tb/filter_core/x05
add wave -noupdate /filter_core_7x7_tb/filter_core/x06
add wave -noupdate /filter_core_7x7_tb/filter_core/x07
add wave -noupdate /filter_core_7x7_tb/filter_core/x08
add wave -noupdate /filter_core_7x7_tb/filter_core/x09
add wave -noupdate /filter_core_7x7_tb/filter_core/x10
add wave -noupdate /filter_core_7x7_tb/filter_core/x11
add wave -noupdate /filter_core_7x7_tb/filter_core/x12
add wave -noupdate /filter_core_7x7_tb/filter_core/x13
add wave -noupdate /filter_core_7x7_tb/filter_core/x14
add wave -noupdate /filter_core_7x7_tb/filter_core/x15
add wave -noupdate /filter_core_7x7_tb/filter_core/x16
add wave -noupdate /filter_core_7x7_tb/filter_core/x17
add wave -noupdate /filter_core_7x7_tb/filter_core/x18
add wave -noupdate /filter_core_7x7_tb/filter_core/x19
add wave -noupdate /filter_core_7x7_tb/filter_core/x20
add wave -noupdate /filter_core_7x7_tb/filter_core/x21
add wave -noupdate /filter_core_7x7_tb/filter_core/x22
add wave -noupdate /filter_core_7x7_tb/filter_core/x23
add wave -noupdate /filter_core_7x7_tb/filter_core/x24
add wave -noupdate /filter_core_7x7_tb/filter_core/x25
add wave -noupdate /filter_core_7x7_tb/filter_core/x26
add wave -noupdate /filter_core_7x7_tb/filter_core/x27
add wave -noupdate /filter_core_7x7_tb/filter_core/x28
add wave -noupdate /filter_core_7x7_tb/filter_core/x29
add wave -noupdate /filter_core_7x7_tb/filter_core/x30
add wave -noupdate /filter_core_7x7_tb/filter_core/x31
add wave -noupdate /filter_core_7x7_tb/filter_core/x32
add wave -noupdate /filter_core_7x7_tb/filter_core/x33
add wave -noupdate /filter_core_7x7_tb/filter_core/x34
add wave -noupdate /filter_core_7x7_tb/filter_core/x35
add wave -noupdate /filter_core_7x7_tb/filter_core/x36
add wave -noupdate /filter_core_7x7_tb/filter_core/x37
add wave -noupdate /filter_core_7x7_tb/filter_core/x38
add wave -noupdate /filter_core_7x7_tb/filter_core/x39
add wave -noupdate /filter_core_7x7_tb/filter_core/x40
add wave -noupdate /filter_core_7x7_tb/filter_core/x41
add wave -noupdate /filter_core_7x7_tb/filter_core/x42
add wave -noupdate /filter_core_7x7_tb/filter_core/x43
add wave -noupdate /filter_core_7x7_tb/filter_core/x44
add wave -noupdate /filter_core_7x7_tb/filter_core/x45
add wave -noupdate /filter_core_7x7_tb/filter_core/x46
add wave -noupdate /filter_core_7x7_tb/filter_core/x47
add wave -noupdate /filter_core_7x7_tb/filter_core/x48
add wave -noupdate -divider output
add wave -noupdate /filter_core_7x7_tb/filter_core/de_o
add wave -noupdate /filter_core_7x7_tb/filter_core/hs_o
add wave -noupdate /filter_core_7x7_tb/filter_core/vs_o
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {0 ps} 0}
quietly wave cursor active 0
configure wave -namecolwidth 150
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
configure wave -timelineunits ns
update
WaveRestoreZoom {0 ps} {11550 ns}
