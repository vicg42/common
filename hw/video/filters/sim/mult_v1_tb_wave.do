onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -divider input
add wave -noupdate -expand /mult_v1_tb/r_num
add wave -noupdate /mult_v1_tb/mult/coe_i
add wave -noupdate -radix unsigned /mult_v1_tb/mult/di_i
add wave -noupdate /mult_v1_tb/mult/de_i
add wave -noupdate /mult_v1_tb/mult/hs_i
add wave -noupdate /mult_v1_tb/mult/vs_i
add wave -noupdate -divider output
add wave -noupdate -radix unsigned -childformat {{{/mult_v1_tb/mult/do_o[23]} -radix unsigned} {{/mult_v1_tb/mult/do_o[22]} -radix unsigned} {{/mult_v1_tb/mult/do_o[21]} -radix unsigned} {{/mult_v1_tb/mult/do_o[20]} -radix unsigned} {{/mult_v1_tb/mult/do_o[19]} -radix unsigned} {{/mult_v1_tb/mult/do_o[18]} -radix unsigned} {{/mult_v1_tb/mult/do_o[17]} -radix unsigned} {{/mult_v1_tb/mult/do_o[16]} -radix unsigned} {{/mult_v1_tb/mult/do_o[15]} -radix unsigned} {{/mult_v1_tb/mult/do_o[14]} -radix unsigned} {{/mult_v1_tb/mult/do_o[13]} -radix unsigned} {{/mult_v1_tb/mult/do_o[12]} -radix unsigned} {{/mult_v1_tb/mult/do_o[11]} -radix unsigned} {{/mult_v1_tb/mult/do_o[10]} -radix unsigned} {{/mult_v1_tb/mult/do_o[9]} -radix unsigned} {{/mult_v1_tb/mult/do_o[8]} -radix unsigned} {{/mult_v1_tb/mult/do_o[7]} -radix unsigned} {{/mult_v1_tb/mult/do_o[6]} -radix unsigned} {{/mult_v1_tb/mult/do_o[5]} -radix unsigned} {{/mult_v1_tb/mult/do_o[4]} -radix unsigned} {{/mult_v1_tb/mult/do_o[3]} -radix unsigned} {{/mult_v1_tb/mult/do_o[2]} -radix unsigned} {{/mult_v1_tb/mult/do_o[1]} -radix unsigned} {{/mult_v1_tb/mult/do_o[0]} -radix unsigned}} -subitemconfig {{/mult_v1_tb/mult/do_o[23]} {-height 15 -radix unsigned} {/mult_v1_tb/mult/do_o[22]} {-height 15 -radix unsigned} {/mult_v1_tb/mult/do_o[21]} {-height 15 -radix unsigned} {/mult_v1_tb/mult/do_o[20]} {-height 15 -radix unsigned} {/mult_v1_tb/mult/do_o[19]} {-height 15 -radix unsigned} {/mult_v1_tb/mult/do_o[18]} {-height 15 -radix unsigned} {/mult_v1_tb/mult/do_o[17]} {-height 15 -radix unsigned} {/mult_v1_tb/mult/do_o[16]} {-height 15 -radix unsigned} {/mult_v1_tb/mult/do_o[15]} {-height 15 -radix unsigned} {/mult_v1_tb/mult/do_o[14]} {-height 15 -radix unsigned} {/mult_v1_tb/mult/do_o[13]} {-height 15 -radix unsigned} {/mult_v1_tb/mult/do_o[12]} {-height 15 -radix unsigned} {/mult_v1_tb/mult/do_o[11]} {-height 15 -radix unsigned} {/mult_v1_tb/mult/do_o[10]} {-height 15 -radix unsigned} {/mult_v1_tb/mult/do_o[9]} {-height 15 -radix unsigned} {/mult_v1_tb/mult/do_o[8]} {-height 15 -radix unsigned} {/mult_v1_tb/mult/do_o[7]} {-height 15 -radix unsigned} {/mult_v1_tb/mult/do_o[6]} {-height 15 -radix unsigned} {/mult_v1_tb/mult/do_o[5]} {-height 15 -radix unsigned} {/mult_v1_tb/mult/do_o[4]} {-height 15 -radix unsigned} {/mult_v1_tb/mult/do_o[3]} {-height 15 -radix unsigned} {/mult_v1_tb/mult/do_o[2]} {-height 15 -radix unsigned} {/mult_v1_tb/mult/do_o[1]} {-height 15 -radix unsigned} {/mult_v1_tb/mult/do_o[0]} {-height 15 -radix unsigned}} /mult_v1_tb/mult/do_o
add wave -noupdate /mult_v1_tb/mult/de_o
add wave -noupdate /mult_v1_tb/mult/hs_o
add wave -noupdate /mult_v1_tb/mult/vs_o
add wave -noupdate -divider entity
add wave -noupdate -radix unsigned /mult_v1_tb/mult/OVERFLOW_BIT
add wave -noupdate -radix unsigned -childformat {{{/mult_v1_tb/mult/di[2]} -radix unsigned -childformat {{{/mult_v1_tb/mult/di[2][12]} -radix unsigned} {{/mult_v1_tb/mult/di[2][11]} -radix unsigned} {{/mult_v1_tb/mult/di[2][10]} -radix unsigned} {{/mult_v1_tb/mult/di[2][9]} -radix unsigned} {{/mult_v1_tb/mult/di[2][8]} -radix unsigned} {{/mult_v1_tb/mult/di[2][7]} -radix unsigned} {{/mult_v1_tb/mult/di[2][6]} -radix unsigned} {{/mult_v1_tb/mult/di[2][5]} -radix unsigned} {{/mult_v1_tb/mult/di[2][4]} -radix unsigned} {{/mult_v1_tb/mult/di[2][3]} -radix unsigned} {{/mult_v1_tb/mult/di[2][2]} -radix unsigned} {{/mult_v1_tb/mult/di[2][1]} -radix unsigned} {{/mult_v1_tb/mult/di[2][0]} -radix unsigned}}} {{/mult_v1_tb/mult/di[1]} -radix unsigned} {{/mult_v1_tb/mult/di[0]} -radix unsigned}} -expand -subitemconfig {{/mult_v1_tb/mult/di[2]} {-height 15 -radix unsigned -childformat {{{/mult_v1_tb/mult/di[2][12]} -radix unsigned} {{/mult_v1_tb/mult/di[2][11]} -radix unsigned} {{/mult_v1_tb/mult/di[2][10]} -radix unsigned} {{/mult_v1_tb/mult/di[2][9]} -radix unsigned} {{/mult_v1_tb/mult/di[2][8]} -radix unsigned} {{/mult_v1_tb/mult/di[2][7]} -radix unsigned} {{/mult_v1_tb/mult/di[2][6]} -radix unsigned} {{/mult_v1_tb/mult/di[2][5]} -radix unsigned} {{/mult_v1_tb/mult/di[2][4]} -radix unsigned} {{/mult_v1_tb/mult/di[2][3]} -radix unsigned} {{/mult_v1_tb/mult/di[2][2]} -radix unsigned} {{/mult_v1_tb/mult/di[2][1]} -radix unsigned} {{/mult_v1_tb/mult/di[2][0]} -radix unsigned}}} {/mult_v1_tb/mult/di[2][12]} {-height 15 -radix unsigned} {/mult_v1_tb/mult/di[2][11]} {-height 15 -radix unsigned} {/mult_v1_tb/mult/di[2][10]} {-height 15 -radix unsigned} {/mult_v1_tb/mult/di[2][9]} {-height 15 -radix unsigned} {/mult_v1_tb/mult/di[2][8]} {-height 15 -radix unsigned} {/mult_v1_tb/mult/di[2][7]} {-height 15 -radix unsigned} {/mult_v1_tb/mult/di[2][6]} {-height 15 -radix unsigned} {/mult_v1_tb/mult/di[2][5]} {-height 15 -radix unsigned} {/mult_v1_tb/mult/di[2][4]} {-height 15 -radix unsigned} {/mult_v1_tb/mult/di[2][3]} {-height 15 -radix unsigned} {/mult_v1_tb/mult/di[2][2]} {-height 15 -radix unsigned} {/mult_v1_tb/mult/di[2][1]} {-height 15 -radix unsigned} {/mult_v1_tb/mult/di[2][0]} {-height 15 -radix unsigned} {/mult_v1_tb/mult/di[1]} {-height 15 -radix unsigned} {/mult_v1_tb/mult/di[0]} {-height 15 -radix unsigned}} /mult_v1_tb/mult/di
add wave -noupdate -radix unsigned -childformat {{{/mult_v1_tb/mult/coe[2]} -radix unsigned} {{/mult_v1_tb/mult/coe[1]} -radix unsigned} {{/mult_v1_tb/mult/coe[0]} -radix hexadecimal}} -expand -subitemconfig {{/mult_v1_tb/mult/coe[2]} {-height 15 -radix unsigned} {/mult_v1_tb/mult/coe[1]} {-height 15 -radix unsigned} {/mult_v1_tb/mult/coe[0]} {-height 15 -radix hexadecimal}} /mult_v1_tb/mult/coe
add wave -noupdate /mult_v1_tb/mult/mr
add wave -noupdate /mult_v1_tb/mult/mg
add wave -noupdate /mult_v1_tb/mult/mb
add wave -noupdate -childformat {{{/mult_v1_tb/mult/do[0]} -radix unsigned}} -expand -subitemconfig {{/mult_v1_tb/mult/do[0]} {-height 15 -radix unsigned}} /mult_v1_tb/mult/do
add wave -noupdate {/mult_v1_tb/r_num[0]}
add wave -noupdate -height 15 -radix unsigned {/mult_v1_tb/mult/di[0]}
add wave -noupdate -height 15 -radix unsigned {/mult_v1_tb/mult/do[0]}
add wave -noupdate {/mult_v1_tb/mult/mr_round[20]}
add wave -noupdate {/mult_v1_tb/mult/mr_round[19]}
add wave -noupdate {/mult_v1_tb/mult/mr_round[18]}
add wave -noupdate /mult_v1_tb/mult/mr_round
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
WaveRestoreZoom {1001921 ps} {1210426 ps}
