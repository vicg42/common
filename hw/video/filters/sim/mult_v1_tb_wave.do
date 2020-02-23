onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -divider input
add wave -noupdate /mult_v1_tb/mult/coe_i
add wave -noupdate /mult_v1_tb/mult/di_i
add wave -noupdate /mult_v1_tb/mult/de_i
add wave -noupdate /mult_v1_tb/mult/hs_i
add wave -noupdate /mult_v1_tb/mult/vs_i
add wave -noupdate -divider output
add wave -noupdate /mult_v1_tb/mult/do_o
add wave -noupdate /mult_v1_tb/mult/de_o
add wave -noupdate /mult_v1_tb/mult/hs_o
add wave -noupdate /mult_v1_tb/mult/vs_o
add wave -noupdate -divider entity
add wave -noupdate -radix unsigned -childformat {{{/mult_v1_tb/mult/coe[2]} -radix unsigned} {{/mult_v1_tb/mult/coe[1]} -radix unsigned} {{/mult_v1_tb/mult/coe[0]} -radix unsigned}} -expand -subitemconfig {{/mult_v1_tb/mult/coe[2]} {-height 15 -radix unsigned} {/mult_v1_tb/mult/coe[1]} {-height 15 -radix unsigned} {/mult_v1_tb/mult/coe[0]} {-height 15 -radix unsigned}} /mult_v1_tb/mult/coe
add wave -noupdate -radix unsigned -childformat {{{/mult_v1_tb/mult/di[2]} -radix unsigned -childformat {{{/mult_v1_tb/mult/di[2][7]} -radix unsigned} {{/mult_v1_tb/mult/di[2][6]} -radix unsigned} {{/mult_v1_tb/mult/di[2][5]} -radix unsigned} {{/mult_v1_tb/mult/di[2][4]} -radix unsigned} {{/mult_v1_tb/mult/di[2][3]} -radix unsigned} {{/mult_v1_tb/mult/di[2][2]} -radix unsigned} {{/mult_v1_tb/mult/di[2][1]} -radix unsigned} {{/mult_v1_tb/mult/di[2][0]} -radix unsigned}}} {{/mult_v1_tb/mult/di[1]} -radix unsigned} {{/mult_v1_tb/mult/di[0]} -radix unsigned}} -expand -subitemconfig {{/mult_v1_tb/mult/di[2]} {-height 15 -radix unsigned -childformat {{{/mult_v1_tb/mult/di[2][7]} -radix unsigned} {{/mult_v1_tb/mult/di[2][6]} -radix unsigned} {{/mult_v1_tb/mult/di[2][5]} -radix unsigned} {{/mult_v1_tb/mult/di[2][4]} -radix unsigned} {{/mult_v1_tb/mult/di[2][3]} -radix unsigned} {{/mult_v1_tb/mult/di[2][2]} -radix unsigned} {{/mult_v1_tb/mult/di[2][1]} -radix unsigned} {{/mult_v1_tb/mult/di[2][0]} -radix unsigned}}} {/mult_v1_tb/mult/di[2][7]} {-height 15 -radix unsigned} {/mult_v1_tb/mult/di[2][6]} {-height 15 -radix unsigned} {/mult_v1_tb/mult/di[2][5]} {-height 15 -radix unsigned} {/mult_v1_tb/mult/di[2][4]} {-height 15 -radix unsigned} {/mult_v1_tb/mult/di[2][3]} {-height 15 -radix unsigned} {/mult_v1_tb/mult/di[2][2]} {-height 15 -radix unsigned} {/mult_v1_tb/mult/di[2][1]} {-height 15 -radix unsigned} {/mult_v1_tb/mult/di[2][0]} {-height 15 -radix unsigned} {/mult_v1_tb/mult/di[1]} {-height 15 -radix unsigned} {/mult_v1_tb/mult/di[0]} {-height 15 -radix unsigned}} /mult_v1_tb/mult/di
add wave -noupdate /mult_v1_tb/mult/mr
add wave -noupdate /mult_v1_tb/mult/mg
add wave -noupdate /mult_v1_tb/mult/mb
add wave -noupdate -expand /mult_v1_tb/mult/do
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
WaveRestoreZoom {0 ps} {279003 ps}
