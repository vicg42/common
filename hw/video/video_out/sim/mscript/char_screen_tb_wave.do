onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -radix hexadecimal /char_screen_tb/uut/i_font_ram_wr
add wave -noupdate -radix hexadecimal /char_screen_tb/uut/i_text_ram_wr
add wave -noupdate -radix hexadecimal /char_screen_tb/uut/p_in_ram_adr
add wave -noupdate -radix hexadecimal /char_screen_tb/uut/p_in_ram_din
add wave -noupdate -radix unsigned /char_screen_tb/m_vga/p_out_pixcnt
add wave -noupdate -radix unsigned /char_screen_tb/m_vga/p_out_linecnt
add wave -noupdate /char_screen_tb/uut/i_screen_eny
add wave -noupdate /char_screen_tb/uut/i_screen_enx
add wave -noupdate /char_screen_tb/uut/p_in_pixen
add wave -noupdate /char_screen_tb/uut/p_in_vsync
add wave -noupdate /char_screen_tb/uut/p_in_hsync
add wave -noupdate /char_screen_tb/uut/i_screen_en
add wave -noupdate -radix hexadecimal /char_screen_tb/uut/i_text_ram_a
add wave -noupdate -radix unsigned /char_screen_tb/uut/i_font_ram_a
add wave -noupdate -radix hexadecimal /char_screen_tb/uut/i_font_dout
add wave -noupdate -radix hexadecimal /char_screen_tb/uut/sr_char_out
add wave -noupdate /char_screen_tb/uut/i_char_out_disx
add wave -noupdate /char_screen_tb/uut/i_char_out_disy
add wave -noupdate -radix hexadecimal /char_screen_tb/uut/i_font_cntx
add wave -noupdate -radix hexadecimal /char_screen_tb/uut/i_font_cnty
add wave -noupdate -radix hexadecimal /char_screen_tb/uut/i_font_dout
add wave -noupdate -radix hexadecimal /char_screen_tb/uut/i_char_cntx
add wave -noupdate -radix hexadecimal /char_screen_tb/uut/i_char_cnty
add wave -noupdate -radix hexadecimal /char_screen_tb/uut/i_char_ascii
add wave -noupdate /char_screen_tb/uut/tst_char
add wave -noupdate /char_screen_tb/uut/tst_charen
add wave -noupdate -radix hexadecimal /char_screen_tb/uut/p_out_vd
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {0 ps} 0}
quietly wave cursor active 0
configure wave -namecolwidth 291
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
WaveRestoreZoom {6950014072 ps} {6991897724 ps}
