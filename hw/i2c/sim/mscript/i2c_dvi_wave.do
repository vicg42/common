onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /i2c_master_core_tb/i_sys_rst
add wave -noupdate /i2c_master_core_tb/i_sys_clk
add wave -noupdate /i2c_master_core_tb/p_inout_sda
add wave -noupdate /i2c_master_core_tb/p_inout_scl
add wave -noupdate -radix hexadecimal /i2c_master_core_tb/i_txd
add wave -noupdate -divider I2C_master
add wave -noupdate -radix hexadecimal /i2c_master_core_tb/m_dvi7301/i_txd
add wave -noupdate -radix hexadecimal /i2c_master_core_tb/m_dvi7301/i_rxd
add wave -noupdate /i2c_master_core_tb/m_dvi7301/fsm_reg_cs
add wave -noupdate /i2c_master_core_tb/m_dvi7301/fsm_core_cs
add wave -noupdate /i2c_master_core_tb/m_dvi7301/m_i2c_core/fsm_i2c_cs
add wave -noupdate -radix hexadecimal /i2c_master_core_tb/m_dvi7301/m_i2c_core/p_in_cmd
add wave -noupdate /i2c_master_core_tb/m_dvi7301/m_i2c_core/i_scl_cnt
add wave -noupdate /i2c_master_core_tb/m_dvi7301/m_i2c_core/i_bit_cnt
add wave -noupdate -radix hexadecimal /i2c_master_core_tb/m_dvi7301/m_i2c_core/i_txd
add wave -noupdate /i2c_master_core_tb/m_dvi7301/m_i2c_core/i_sda_out
add wave -noupdate /i2c_master_core_tb/m_dvi7301/m_i2c_core/i_sda_out_en
add wave -noupdate /i2c_master_core_tb/m_dvi7301/m_i2c_core/p_in_start
add wave -noupdate /i2c_master_core_tb/m_dvi7301/m_i2c_core/p_in_txack
add wave -noupdate /i2c_master_core_tb/m_dvi7301/m_i2c_core/p_out_done
add wave -noupdate /i2c_master_core_tb/m_dvi7301/m_i2c_core/p_out_rxack
add wave -noupdate /i2c_master_core_tb/m_dvi7301/m_i2c_core/i_scl_out
add wave -noupdate /i2c_master_core_tb/m_dvi7301/m_i2c_core/i_scl_out_en
add wave -noupdate -divider I2C_slave
add wave -noupdate /i2c_master_core_tb/m_i2c_slave/state
add wave -noupdate /i2c_master_core_tb/m_i2c_slave/addr_match
add wave -noupdate -radix hexadecimal /i2c_master_core_tb/m_i2c_slave/i2c_header
add wave -noupdate -radix hexadecimal /i2c_master_core_tb/m_i2c_slave/dout
add wave -noupdate /i2c_master_core_tb/m_i2c_slave/en_dout
add wave -noupdate /i2c_master_core_tb/m_i2c_slave/slave_sda
add wave -noupdate /i2c_master_core_tb/m_i2c_slave/din
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {0 ps} 0}
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
WaveRestoreZoom {21640 ns} {55240 ns}
