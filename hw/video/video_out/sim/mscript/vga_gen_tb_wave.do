onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /vga_gen_tb/i_rst
add wave -noupdate /vga_gen_tb/i_clk
add wave -noupdate /vga_gen_tb/uut/i_vsync
add wave -noupdate /vga_gen_tb/uut/i_hsync
add wave -noupdate /vga_gen_tb/i_video_den
add wave -noupdate -radix unsigned /vga_gen_tb/uut/i_pixcnt
add wave -noupdate -radix unsigned /vga_gen_tb/uut/i_linecnt
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 2} {0 ps} 1}
quietly wave cursor active 1
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
configure wave -timelineunits ps
update
WaveRestoreZoom {0 ps} {4476266496 ps}
