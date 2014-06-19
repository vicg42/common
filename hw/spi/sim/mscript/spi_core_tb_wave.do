onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -radix hexadecimal /spi_core_tb/i_adr
add wave -noupdate -radix hexadecimal /spi_core_tb/i_txd
add wave -noupdate -radix hexadecimal /spi_core_tb/i_rxd
add wave -noupdate /spi_core_tb/i_start
add wave -noupdate /spi_core_tb/i_dir
add wave -noupdate -color {Cornflower Blue} /spi_core_tb/m_core/i_fsm_core_cs
add wave -noupdate /spi_core_tb/m_core/sr_reg
add wave -noupdate -radix unsigned /spi_core_tb/m_core/i_bitcnt
add wave -noupdate /spi_core_tb/i_busy
add wave -noupdate /spi_core_tb/i_clk
add wave -noupdate /spi_core_tb/i_clk_en
add wave -noupdate -expand /spi_core_tb/i_spi_out
add wave -noupdate -expand /spi_core_tb/i_spi_in
add wave -noupdate /spi_core_tb/i_tst_out(0)
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
configure wave -timelineunits ps
update
WaveRestoreZoom {3262103 ps} {5398743 ps}
