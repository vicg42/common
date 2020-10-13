onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /scaler_v_tb/scaler_v_m/LINE_STEP
add wave -noupdate /scaler_v_tb/scaler_v_m/di_i
add wave -noupdate /scaler_v_tb/scaler_v_m/de_i
add wave -noupdate /scaler_v_tb/scaler_v_m/hs_i
add wave -noupdate /scaler_v_tb/scaler_v_m/vs_i
add wave -noupdate -radix unsigned /scaler_v_tb/scaler_v_m/cnt_o
add wave -noupdate -radix unsigned /scaler_v_tb/scaler_v_m/cnt_i
add wave -noupdate /scaler_v_tb/scaler_v_m/do_o
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
WaveRestoreZoom {0 ps} {14954310525 ps}
