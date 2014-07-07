onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /tv_gen_tb/p_out_tv_kci
add wave -noupdate /tv_gen_tb/p_out_tv_ssi
add wave -noupdate /tv_gen_tb/p_out_tv_field
add wave -noupdate /tv_gen_tb/p_out_den
add wave -noupdate /tv_gen_tb/uut/cnt_2H
add wave -noupdate /tv_gen_tb/uut/cnt_N2H
add wave -noupdate /tv_gen_tb/uut/cnt_N2H5
add wave -noupdate /tv_gen_tb/uut/cnt_2H5
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {0 ps} 0}
quietly wave cursor active 0
configure wave -namecolwidth 273
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
WaveRestoreZoom {452433968 ps} {924608739 ps}
