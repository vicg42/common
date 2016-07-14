onerror {resume}
quietly virtual function -install /uartrx_tb/m_rx -env /uartrx_tb { &{/uartrx_tb/m_rx/cntr[7], /uartrx_tb/m_rx/cntr[6], /uartrx_tb/m_rx/cntr[5], /uartrx_tb/m_rx/cntr[4] }} bitcnt
quietly virtual function -install /uartrx_tb/m_rx -env /uartrx_tb { &{/uartrx_tb/m_rx/cntr[7], /uartrx_tb/m_rx/cntr[6], /uartrx_tb/m_rx/cntr[5], /uartrx_tb/m_rx/cntr[4] }} bit_cnt
quietly virtual function -install /uartrx_tb/m_rx -env /uartrx_tb { &{/uartrx_tb/m_rx/cntr[3], /uartrx_tb/m_rx/cntr[2], /uartrx_tb/m_rx/cntr[1], /uartrx_tb/m_rx/cntr[0] }} bit_cnt_lsb
quietly WaveActivateNextPane {} 0
add wave -noupdate /uartrx_tb/m_rx/clk
add wave -noupdate -divider RX
add wave -noupdate /uartrx_tb/m_rx/baud_tick
add wave -noupdate -radix unsigned /uartrx_tb/m_rx/baud_cntr
add wave -noupdate /uartrx_tb/m_rx/rxd_presync
add wave -noupdate /uartrx_tb/m_rx/rxd_sync
add wave -noupdate -radix unsigned /uartrx_tb/m_rx/cntr
add wave -noupdate /uartrx_tb/m_rx/receive
add wave -noupdate /uartrx_tb/m_rx/new_bit
add wave -noupdate /uartrx_tb/m_rx/bit_val
add wave -noupdate /uartrx_tb/m_rx/bit_cnt
add wave -noupdate /uartrx_tb/m_rx/bit_cnt_lsb
add wave -noupdate /uartrx_tb/m_rx/byte_shift
add wave -noupdate -divider TX
add wave -noupdate /uartrx_tb/m_tx/baud_rate16
add wave -noupdate /uartrx_tb/m_tx/txdata
add wave -noupdate /uartrx_tb/m_tx/txstart
add wave -noupdate /uartrx_tb/m_tx/busy
add wave -noupdate /uartrx_tb/m_tx/txd
add wave -noupdate /uartrx_tb/m_tx/baud_tick
add wave -noupdate /uartrx_tb/m_tx/baud_cntr
add wave -noupdate /uartrx_tb/m_tx/cntr
add wave -noupdate /uartrx_tb/m_tx/byte_buf
add wave -noupdate /uartrx_tb/m_tx/busy_d
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {78460633 ps} 0}
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
WaveRestoreZoom {0 ps} {210 us}
