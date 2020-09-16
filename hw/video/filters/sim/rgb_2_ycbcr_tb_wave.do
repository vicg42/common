onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /rgb_2_ycbcr_tb/COE_WIDTH
add wave -noupdate /rgb_2_ycbcr_tb/COE_FRACTION_WIDTH
add wave -noupdate /rgb_2_ycbcr_tb/PIXEL_WIDTH
add wave -noupdate /rgb_2_ycbcr_tb/rgb_2_ycbcr_m/r_i
add wave -noupdate /rgb_2_ycbcr_tb/rgb_2_ycbcr_m/g_i
add wave -noupdate /rgb_2_ycbcr_tb/rgb_2_ycbcr_m/b_i
add wave -noupdate /rgb_2_ycbcr_tb/rgb_2_ycbcr_m/de_i
add wave -noupdate /rgb_2_ycbcr_tb/rgb_2_ycbcr_m/vs_i
add wave -noupdate /rgb_2_ycbcr_tb/rgb_2_ycbcr_m/hs_i
add wave -noupdate -divider ----
add wave -noupdate -radix decimal /rgb_2_ycbcr_tb/rgb_2_ycbcr_m/OVERFLOW_BIT
add wave -noupdate /rgb_2_ycbcr_tb/rgb_2_ycbcr_m/ROUND_ADDER
add wave -noupdate /rgb_2_ycbcr_tb/rgb_2_ycbcr_m/y_round
add wave -noupdate /rgb_2_ycbcr_tb/rgb_2_ycbcr_m/cb_round
add wave -noupdate /rgb_2_ycbcr_tb/rgb_2_ycbcr_m/cr_round
add wave -noupdate -divider OUTPUT
add wave -noupdate /rgb_2_ycbcr_tb/rgb_2_ycbcr_m/y_o
add wave -noupdate /rgb_2_ycbcr_tb/rgb_2_ycbcr_m/cb_o
add wave -noupdate /rgb_2_ycbcr_tb/rgb_2_ycbcr_m/cr_o
add wave -noupdate /rgb_2_ycbcr_tb/rgb_2_ycbcr_m/de_o
add wave -noupdate /rgb_2_ycbcr_tb/rgb_2_ycbcr_m/vs_o
add wave -noupdate /rgb_2_ycbcr_tb/rgb_2_ycbcr_m/hs_o
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {0 ps} 0}
quietly wave cursor active 0
configure wave -namecolwidth 338
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
WaveRestoreZoom {4453885200 ps} {6274669200 ps}
