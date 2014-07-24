onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /vtest_gen_tb/i_rst
add wave -noupdate /vtest_gen_tb/i_clk
add wave -noupdate -radix hexadecimal /vtest_gen_tb/p_out_vd
add wave -noupdate /vtest_gen_tb/p_out_vs
add wave -noupdate /vtest_gen_tb/p_out_hs
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {0 ps} 0} {{Cursor 2} {102298803476 ps} 0}
quietly wave cursor active 2
configure wave -namecolwidth 229
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
configure wave -timelineunits ps
update
WaveRestoreZoom {116612857162 ps} {116616414104 ps}
