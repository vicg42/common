onerror {resume}
quietly virtual function -install /saturation_tb/saturation_m -env /saturation_tb/saturation_m { &{/saturation_tb/saturation_m/r_m[17], /saturation_tb/saturation_m/r_m[16], /saturation_tb/saturation_m/r_m[15], /saturation_tb/saturation_m/r_m[14], /saturation_tb/saturation_m/r_m[13], /saturation_tb/saturation_m/r_m[12], /saturation_tb/saturation_m/r_m[11], /saturation_tb/saturation_m/r_m[10], /saturation_tb/saturation_m/r_m[9], /saturation_tb/saturation_m/r_m[8], /saturation_tb/saturation_m/r_m[7], /saturation_tb/saturation_m/r_m[6] }} r_m_i
quietly virtual function -install /saturation_tb/saturation_m -env /saturation_tb/saturation_m { &{/saturation_tb/saturation_m/yo_m[17], /saturation_tb/saturation_m/yo_m[16], /saturation_tb/saturation_m/yo_m[15], /saturation_tb/saturation_m/yo_m[14], /saturation_tb/saturation_m/yo_m[13], /saturation_tb/saturation_m/yo_m[12], /saturation_tb/saturation_m/yo_m[11], /saturation_tb/saturation_m/yo_m[10], /saturation_tb/saturation_m/yo_m[9], /saturation_tb/saturation_m/yo_m[8], /saturation_tb/saturation_m/yo_m[7], /saturation_tb/saturation_m/yo_m[6] }} yo_m_i
quietly virtual function -install /saturation_tb/saturation_m -env /saturation_tb/saturation_m { &{/saturation_tb/saturation_m/r_sum0[17], /saturation_tb/saturation_m/r_sum0[16], /saturation_tb/saturation_m/r_sum0[15], /saturation_tb/saturation_m/r_sum0[14], /saturation_tb/saturation_m/r_sum0[13], /saturation_tb/saturation_m/r_sum0[12], /saturation_tb/saturation_m/r_sum0[11], /saturation_tb/saturation_m/r_sum0[10], /saturation_tb/saturation_m/r_sum0[9], /saturation_tb/saturation_m/r_sum0[8], /saturation_tb/saturation_m/r_sum0[7], /saturation_tb/saturation_m/r_sum0[6] }} r_sum0_i
quietly virtual function -install /saturation_tb/saturation_m -env /saturation_tb/saturation_m { &{/saturation_tb/saturation_m/r_sum1[18], /saturation_tb/saturation_m/r_sum1[17], /saturation_tb/saturation_m/r_sum1[16], /saturation_tb/saturation_m/r_sum1[15], /saturation_tb/saturation_m/r_sum1[14], /saturation_tb/saturation_m/r_sum1[13], /saturation_tb/saturation_m/r_sum1[12], /saturation_tb/saturation_m/r_sum1[11], /saturation_tb/saturation_m/r_sum1[10], /saturation_tb/saturation_m/r_sum1[9], /saturation_tb/saturation_m/r_sum1[8], /saturation_tb/saturation_m/r_sum1[7], /saturation_tb/saturation_m/r_sum1[6] }} r_sum1_i
quietly WaveActivateNextPane {} 0
add wave -noupdate /saturation_tb/saturation_m/saturation
add wave -noupdate /saturation_tb/saturation_m/ycoe0
add wave -noupdate /saturation_tb/saturation_m/ycoe1
add wave -noupdate /saturation_tb/saturation_m/ycoe2
add wave -noupdate /saturation_tb/saturation_m/saturation
add wave -noupdate -expand /saturation_tb/saturation_m/di
add wave -noupdate /saturation_tb/saturation_m/ycoe0
add wave -noupdate /saturation_tb/saturation_m/ycoe1
add wave -noupdate /saturation_tb/saturation_m/ycoe2
add wave -noupdate /saturation_tb/saturation_m/yr_m
add wave -noupdate /saturation_tb/saturation_m/yg_m
add wave -noupdate /saturation_tb/saturation_m/yb_m
add wave -noupdate /saturation_tb/saturation_m/yrg_m
add wave -noupdate /saturation_tb/saturation_m/y
add wave -noupdate -radix unsigned /saturation_tb/saturation_m/yo
add wave -noupdate -radix unsigned /saturation_tb/saturation_m/r_m_i
add wave -noupdate /saturation_tb/saturation_m/r_m
add wave -noupdate -radix unsigned /saturation_tb/saturation_m/yo_m_i
add wave -noupdate /saturation_tb/saturation_m/yo_m
add wave -noupdate -radix decimal -childformat {{(11) -radix decimal} {(10) -radix decimal} {(9) -radix decimal} {(8) -radix decimal} {(7) -radix decimal} {(6) -radix decimal} {(5) -radix decimal} {(4) -radix decimal} {(3) -radix decimal} {(2) -radix decimal} {(1) -radix decimal} {(0) -radix decimal}} -subitemconfig {{/saturation_tb/saturation_m/r_sum0[17]} {-radix decimal} {/saturation_tb/saturation_m/r_sum0[16]} {-radix decimal} {/saturation_tb/saturation_m/r_sum0[15]} {-radix decimal} {/saturation_tb/saturation_m/r_sum0[14]} {-radix decimal} {/saturation_tb/saturation_m/r_sum0[13]} {-radix decimal} {/saturation_tb/saturation_m/r_sum0[12]} {-radix decimal} {/saturation_tb/saturation_m/r_sum0[11]} {-radix decimal} {/saturation_tb/saturation_m/r_sum0[10]} {-radix decimal} {/saturation_tb/saturation_m/r_sum0[9]} {-radix decimal} {/saturation_tb/saturation_m/r_sum0[8]} {-radix decimal} {/saturation_tb/saturation_m/r_sum0[7]} {-radix decimal} {/saturation_tb/saturation_m/r_sum0[6]} {-radix decimal}} /saturation_tb/saturation_m/r_sum0_i
add wave -noupdate /saturation_tb/saturation_m/r_sum0
add wave -noupdate -radix decimal /saturation_tb/saturation_m/r_sum1_i
add wave -noupdate /saturation_tb/saturation_m/r_sum1
add wave -noupdate -radix unsigned {/saturation_tb/saturation_m/do_[2]}
add wave -noupdate -radix unsigned {/saturation_tb/saturation_m/do_[1]}
add wave -noupdate -radix unsigned {/saturation_tb/saturation_m/do_[0]}
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
WaveRestoreZoom {0 ps} {60900 ps}
