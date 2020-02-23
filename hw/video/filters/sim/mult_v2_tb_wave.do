onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -divider input
add wave -noupdate /mult_v2_tb/mult/di_i
add wave -noupdate /mult_v2_tb/mult/de_i
add wave -noupdate /mult_v2_tb/mult/hs_i
add wave -noupdate /mult_v2_tb/mult/vs_i
add wave -noupdate -divider output
add wave -noupdate /mult_v2_tb/mult/do_o
add wave -noupdate /mult_v2_tb/mult/de_o
add wave -noupdate /mult_v2_tb/mult/hs_o
add wave -noupdate /mult_v2_tb/mult/vs_o
add wave -noupdate -divider entity
add wave -noupdate -radix decimal -childformat {{{/mult_v2_tb/mult/di[2]} -radix decimal} {{/mult_v2_tb/mult/di[1]} -radix decimal} {{/mult_v2_tb/mult/di[0]} -radix decimal}} -expand -subitemconfig {{/mult_v2_tb/mult/di[2]} {-height 15 -radix decimal} {/mult_v2_tb/mult/di[1]} {-height 15 -radix decimal} {/mult_v2_tb/mult/di[0]} {-height 15 -radix decimal}} /mult_v2_tb/mult/di
add wave -noupdate -radix decimal -childformat {{{/mult_v2_tb/mult/coe[2]} -radix decimal} {{/mult_v2_tb/mult/coe[1]} -radix decimal} {{/mult_v2_tb/mult/coe[0]} -radix decimal}} -expand -subitemconfig {{/mult_v2_tb/mult/coe[2]} {-height 15 -radix decimal} {/mult_v2_tb/mult/coe[1]} {-height 15 -radix decimal} {/mult_v2_tb/mult/coe[0]} {-height 15 -radix decimal}} /mult_v2_tb/mult/coe
add wave -noupdate /mult_v2_tb/mult/r_mr
add wave -noupdate /mult_v2_tb/mult/r_mrgb_round
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
configure wave -timelineunits ns
update
WaveRestoreZoom {935048 ps} {1214051 ps}
