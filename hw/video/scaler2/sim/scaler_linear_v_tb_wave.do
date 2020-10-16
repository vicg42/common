onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -radix ascii /scaler_linear_v_tb/READ_IMG_FILE
add wave -noupdate -radix ascii /scaler_linear_v_tb/WRITE_IMG_FILE
add wave -noupdate -radix unsigned /scaler_linear_v_tb/LINE_IN_SIZE_MAX
add wave -noupdate -radix unsigned /scaler_linear_v_tb/scaler_linear_v_m/LINE_STEP
add wave -noupdate -radix unsigned /scaler_linear_v_tb/PIXEL_WIDTH
add wave -noupdate /scaler_linear_v_tb/SCALE_COE
add wave -noupdate -radix unsigned /scaler_linear_v_tb/COE_WIDTH
add wave -noupdate -radix unsigned /scaler_linear_v_tb/SPARSE_OUT
add wave -noupdate -divider {New Divider}
add wave -noupdate -color {Slate Blue} -itemcolor Gold -radix unsigned /scaler_linear_v_tb/dbg_cntx_i
add wave -noupdate -color {Slate Blue} -itemcolor Gold -radix unsigned /scaler_linear_v_tb/dbg_cnty_i
add wave -noupdate -radix hexadecimal /scaler_linear_v_tb/scaler_linear_v_m/di_i
add wave -noupdate /scaler_linear_v_tb/scaler_linear_v_m/de_i
add wave -noupdate /scaler_linear_v_tb/scaler_linear_v_m/hs_i
add wave -noupdate /scaler_linear_v_tb/scaler_linear_v_m/vs_i
add wave -noupdate -divider {New Divider}
add wave -noupdate /scaler_linear_v_tb/scaler_linear_v_m/de_i
add wave -noupdate /scaler_linear_v_tb/scaler_linear_v_m/hs_i
add wave -noupdate /scaler_linear_v_tb/scaler_linear_v_m/vs_i
add wave -noupdate /scaler_linear_v_tb/scaler_linear_v_m/di_i
add wave -noupdate -radix unsigned /scaler_linear_v_tb/scaler_linear_v_m/buf_wcnt
add wave -noupdate -expand /scaler_linear_v_tb/scaler_linear_v_m/buf_do
add wave -noupdate -expand /scaler_linear_v_tb/scaler_linear_v_m/sr0_buf_do
add wave -noupdate -radix unsigned /scaler_linear_v_tb/scaler_linear_v_m/cnt_i
add wave -noupdate -radix unsigned /scaler_linear_v_tb/scaler_linear_v_m/cnt_o
add wave -noupdate -radix unsigned /scaler_linear_v_tb/scaler_linear_v_m/dy
add wave -noupdate {/scaler_linear_v_tb/scaler_linear_v_m/sr_de_i[2]}
add wave -noupdate -expand /scaler_linear_v_tb/scaler_linear_v_m/line
add wave -noupdate -expand /scaler_linear_v_tb/scaler_linear_v_m/coe
add wave -noupdate -expand /scaler_linear_v_tb/scaler_linear_v_m/mult
add wave -noupdate /scaler_linear_v_tb/scaler_linear_v_m/sum
add wave -noupdate /scaler_linear_v_tb/scaler_linear_v_m/do_o
add wave -noupdate /scaler_linear_v_tb/scaler_linear_v_m/de_o
add wave -noupdate /scaler_linear_v_tb/scaler_linear_v_m/hs_o
add wave -noupdate /scaler_linear_v_tb/scaler_linear_v_m/vs_o
add wave -noupdate -divider {output monitor}
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
WaveRestoreZoom {0 ps} {3150 ns}
