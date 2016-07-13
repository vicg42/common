onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /uartrx_tb/m_rx/clk
add wave -noupdate /uartrx_tb/m_rx/baud_tick
add wave -noupdate -radix unsigned /uartrx_tb/m_rx/baud_cntr
add wave -noupdate /uartrx_tb/m_rx/rxd_presync
add wave -noupdate /uartrx_tb/m_rx/rxd_sync
add wave -noupdate /uartrx_tb/m_rx/rxd_d
add wave -noupdate /uartrx_tb/m_rx/rxd_dd
add wave -noupdate /uartrx_tb/m_rx/rxd_ddd
add wave -noupdate /uartrx_tb/m_rx/cntr
add wave -noupdate /uartrx_tb/m_rx/receive
add wave -noupdate /uartrx_tb/m_rx/new_bit
add wave -noupdate /uartrx_tb/m_rx/bit_val
add wave -noupdate /uartrx_tb/m_rx/byte_shift
add wave -noupdate /uartrx_tb/m_rx/rx_data_ready
add wave -noupdate /uartrx_tb/m_rx/framing_error
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
WaveRestoreZoom {57146512 ps} {109378704 ps}
