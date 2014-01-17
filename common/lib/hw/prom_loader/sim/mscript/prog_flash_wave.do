onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -radix hexadecimal -childformat {{/prog_flash_tb/pin_phy.wt -radix hexadecimal}} -expand -subitemconfig {/prog_flash_tb/pin_phy.wt {-height 15 -radix hexadecimal}} /prog_flash_tb/pin_phy
add wave -noupdate -radix hexadecimal -childformat {{/prog_flash_tb/pinout_phy.d -radix hexadecimal}} -expand -subitemconfig {/prog_flash_tb/pinout_phy.d {-height 15 -radix hexadecimal}} /prog_flash_tb/pinout_phy
add wave -noupdate -radix hexadecimal -childformat {{/prog_flash_tb/pout_phy.a -radix hexadecimal} {/prog_flash_tb/pout_phy.oe_n -radix hexadecimal} {/prog_flash_tb/pout_phy.we_n -radix hexadecimal} {/prog_flash_tb/pout_phy.cs_n -radix hexadecimal}} -expand -subitemconfig {/prog_flash_tb/pout_phy.a {-height 15 -radix hexadecimal} /prog_flash_tb/pout_phy.oe_n {-height 15 -radix hexadecimal} /prog_flash_tb/pout_phy.we_n {-height 15 -radix hexadecimal} /prog_flash_tb/pout_phy.cs_n {-height 15 -radix hexadecimal}} /prog_flash_tb/pout_phy
add wave -noupdate -radix hexadecimal /prog_flash_tb/m_core/p_out_status
add wave -noupdate /prog_flash_tb/m_core/p_out_irq
add wave -noupdate /prog_flash_tb/m_core/p_in_clk_en
add wave -noupdate -color {Dark Orchid} -itemcolor Gold /prog_flash_tb/m_core/i_fsm_cs
add wave -noupdate -radix hexadecimal /prog_flash_tb/m_core/i_block_num
add wave -noupdate -radix hexadecimal /prog_flash_tb/m_core/i_block_end
add wave -noupdate -radix hexadecimal /prog_flash_tb/m_core/i_block_adr
add wave -noupdate -radix hexadecimal /prog_flash_tb/m_core/i_adr_byte
add wave -noupdate -radix hexadecimal /prog_flash_tb/m_core/i_size_byte
add wave -noupdate -radix hexadecimal /prog_flash_tb/m_core/i_adr_cnt
add wave -noupdate -radix hexadecimal /prog_flash_tb/m_core/i_adr
add wave -noupdate -radix hexadecimal /prog_flash_tb/m_core/i_adr_end
add wave -noupdate -radix hexadecimal /prog_flash_tb/m_core/i_size
add wave -noupdate -radix hexadecimal /prog_flash_tb/m_core/i_size_cnt
add wave -noupdate -radix hexadecimal /prog_flash_tb/m_core/i_size_remain
add wave -noupdate -radix hexadecimal /prog_flash_tb/m_core/i_trn_size
add wave -noupdate -radix hexadecimal -childformat {{/prog_flash_tb/m_core/i_bcnt(0) -radix hexadecimal}} -subitemconfig {/prog_flash_tb/m_core/i_bcnt(0) {-height 15 -radix hexadecimal}} /prog_flash_tb/m_core/i_bcnt
add wave -noupdate -radix hexadecimal /prog_flash_tb/m_core/i_cfi_bcnt
add wave -noupdate -radix hexadecimal /prog_flash_tb/m_core/p_in_txbuf_d
add wave -noupdate -radix hexadecimal /prog_flash_tb/m_core/p_out_txbuf_rd
add wave -noupdate /prog_flash_tb/m_core/i_txbuf_rd_last
add wave -noupdate -radix hexadecimal /prog_flash_tb/m_core/p_in_txbuf_empty
add wave -noupdate -radix hexadecimal /prog_flash_tb/m_core/p_out_rxbuf_d
add wave -noupdate -radix hexadecimal /prog_flash_tb/m_core/p_out_rxbuf_wr
add wave -noupdate /prog_flash_tb/m_core/i_rxbuf_wr_last
TreeUpdate [SetDefaultTree]
configure wave -namecolwidth 141
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
WaveRestoreZoom {310042887 ps} {316751240 ps}
