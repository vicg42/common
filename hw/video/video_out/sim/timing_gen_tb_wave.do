onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /timing_gen_tb/timing_gen/clk
add wave -noupdate -radix decimal /timing_gen_tb/timing_gen/PIXEL_WIDTH
add wave -noupdate -radix decimal /timing_gen_tb/timing_gen/pix_count
add wave -noupdate -radix decimal /timing_gen_tb/timing_gen/line_count
add wave -noupdate -radix decimal /timing_gen_tb/timing_gen/hs_count
add wave -noupdate -radix decimal /timing_gen_tb/timing_gen/vs_count
add wave -noupdate -color {Slate Blue} -itemcolor Gold /timing_gen_tb/timing_gen/fsm_cs
add wave -noupdate /timing_gen_tb/timing_gen/pix_cnt
add wave -noupdate /timing_gen_tb/timing_gen/cnt_x
add wave -noupdate /timing_gen_tb/timing_gen/cnt_y
add wave -noupdate /timing_gen_tb/timing_gen/do_o
add wave -noupdate /timing_gen_tb/timing_gen/de_o
add wave -noupdate /timing_gen_tb/timing_gen/hs_o
add wave -noupdate /timing_gen_tb/timing_gen/vs_o
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {0 ps} 0}
quietly wave cursor active 0
configure wave -namecolwidth 248
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
WaveRestoreZoom {0 ps} {215747834400 ps}
