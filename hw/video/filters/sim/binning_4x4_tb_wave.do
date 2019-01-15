onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /binning_2x2_tb/binning_2x2/bypass
add wave -noupdate /binning_2x2_tb/binning_2x2/di_i
add wave -noupdate /binning_2x2_tb/binning_2x2/de_i
add wave -noupdate /binning_2x2_tb/binning_2x2/hs_i
add wave -noupdate /binning_2x2_tb/binning_2x2/vs_i
add wave -noupdate /binning_2x2_tb/binning_2x2/clk
add wave -noupdate -divider {New Divider}
add wave -noupdate /binning_2x2_tb/binning_2x2/DE_SPARSE
add wave -noupdate /binning_2x2_tb/binning_2x2/sr_de_i
add wave -noupdate /binning_2x2_tb/binning_2x2/en_opt
add wave -noupdate /binning_2x2_tb/binning_2x2/en
add wave -noupdate /binning_2x2_tb/binning_2x2/sr_hs_i
add wave -noupdate /binning_2x2_tb/binning_2x2/sr_vs_i
add wave -noupdate /binning_2x2_tb/binning_2x2/dv_opt
add wave -noupdate /binning_2x2_tb/binning_2x2/vs_opt
add wave -noupdate /binning_2x2_tb/binning_2x2/buf_wptr_clr
add wave -noupdate /binning_2x2_tb/binning_2x2/buf_wptr_en
add wave -noupdate /binning_2x2_tb/binning_2x2/buf_wptr
add wave -noupdate /binning_2x2_tb/binning_2x2/buf0_do
add wave -noupdate /binning_2x2_tb/binning_2x2/x
add wave -noupdate {/binning_2x2_tb/binning_2x2/x[0]}
add wave -noupdate {/binning_2x2_tb/binning_2x2/x[1]}
add wave -noupdate {/binning_2x2_tb/binning_2x2/x[2]}
add wave -noupdate {/binning_2x2_tb/binning_2x2/x[3]}
add wave -noupdate /binning_2x2_tb/binning_2x2/de
add wave -noupdate /binning_2x2_tb/binning_2x2/hs
add wave -noupdate /binning_2x2_tb/binning_2x2/vs
add wave -noupdate /binning_2x2_tb/binning_2x2/line_out_en
add wave -noupdate /binning_2x2_tb/binning_2x2/sumx12
add wave -noupdate /binning_2x2_tb/binning_2x2/sumx34
add wave -noupdate {/binning_2x2_tb/binning_2x2/sr_de[0]}
add wave -noupdate {/binning_2x2_tb/binning_2x2/sr_hs[0]}
add wave -noupdate {/binning_2x2_tb/binning_2x2/sr_vs[0]}
add wave -noupdate -radix unsigned /binning_2x2_tb/binning_2x2/sumx1234
add wave -noupdate {/binning_2x2_tb/binning_2x2/sr_de[1]}
add wave -noupdate {/binning_2x2_tb/binning_2x2/sr_hs[1]}
add wave -noupdate {/binning_2x2_tb/binning_2x2/sr_vs[1]}
add wave -noupdate -radix unsigned /binning_2x2_tb/binning_2x2/sumx1234_div4
add wave -noupdate {/binning_2x2_tb/binning_2x2/sr_de[2]}
add wave -noupdate {/binning_2x2_tb/binning_2x2/sr_hs[2]}
add wave -noupdate {/binning_2x2_tb/binning_2x2/sr_vs[2]}
add wave -noupdate /binning_2x2_tb/binning_2x2/de_sel
add wave -noupdate /binning_2x2_tb/binning_2x2/sr_de_sel
add wave -noupdate /binning_2x2_tb/binning_2x2/do_
add wave -noupdate /binning_2x2_tb/binning_2x2/en_opt
add wave -noupdate /binning_2x2_tb/binning_2x2/do_o
add wave -noupdate /binning_2x2_tb/binning_2x2/de_o
add wave -noupdate /binning_2x2_tb/binning_2x2/hs_o
add wave -noupdate /binning_2x2_tb/binning_2x2/vs_o
add wave -noupdate -divider {New Divider}
add wave -noupdate /binning_2x2_tb/binning_2x2/clk
add wave -noupdate -radix unsigned /binning_2x2_tb/binning_4x4/DE_SPARSE
add wave -noupdate -radix unsigned /binning_2x2_tb/binning_4x4/PIPELINE
add wave -noupdate /binning_2x2_tb/binning_4x4/di_i
add wave -noupdate /binning_2x2_tb/binning_4x4/de_i
add wave -noupdate /binning_2x2_tb/binning_4x4/sr_de_i
add wave -noupdate /binning_2x2_tb/binning_4x4/hs_i
add wave -noupdate /binning_2x2_tb/binning_4x4/sr_hs_i
add wave -noupdate /binning_2x2_tb/binning_4x4/vs_i
add wave -noupdate /binning_2x2_tb/binning_4x4/vs_opt
add wave -noupdate /binning_2x2_tb/binning_4x4/dv_opt
add wave -noupdate /binning_2x2_tb/binning_4x4/buf_wptr_en
add wave -noupdate /binning_2x2_tb/binning_4x4/buf_wptr_clr
add wave -noupdate /binning_2x2_tb/binning_4x4/buf_wptr
add wave -noupdate /binning_2x2_tb/binning_4x4/buf0_do
add wave -noupdate /binning_2x2_tb/binning_4x4/en_opt
add wave -noupdate /binning_2x2_tb/binning_4x4/line_out_en
add wave -noupdate -expand /binning_2x2_tb/binning_4x4/x
add wave -noupdate /binning_2x2_tb/binning_4x4/de
add wave -noupdate /binning_2x2_tb/binning_4x4/hs
add wave -noupdate /binning_2x2_tb/binning_4x4/vs
add wave -noupdate /binning_2x2_tb/binning_4x4/sumx12
add wave -noupdate /binning_2x2_tb/binning_4x4/sumx34
add wave -noupdate {/binning_2x2_tb/binning_4x4/sr_de[0]}
add wave -noupdate {/binning_2x2_tb/binning_4x4/sr_hs[0]}
add wave -noupdate /binning_2x2_tb/binning_4x4/sumx1234
add wave -noupdate {/binning_2x2_tb/binning_4x4/sr_de[1]}
add wave -noupdate {/binning_2x2_tb/binning_4x4/sr_hs[1]}
add wave -noupdate /binning_2x2_tb/binning_4x4/sumx1234_div4
add wave -noupdate /binning_2x2_tb/binning_4x4/de_sel
add wave -noupdate {/binning_2x2_tb/binning_4x4/sr_de[2]}
add wave -noupdate {/binning_2x2_tb/binning_4x4/sr_hs[2]}
add wave -noupdate /binning_2x2_tb/binning_4x4/do_
add wave -noupdate /binning_2x2_tb/binning_4x4/sr_de_sel
add wave -noupdate {/binning_2x2_tb/binning_4x4/sr_de[3]}
add wave -noupdate {/binning_2x2_tb/binning_4x4/sr_hs[3]}
add wave -noupdate /binning_2x2_tb/binning_4x4/do_o_
add wave -noupdate /binning_2x2_tb/binning_4x4/de_o_
add wave -noupdate /binning_2x2_tb/binning_4x4/hs_o_
add wave -noupdate -divider {New Divider}
add wave -noupdate /binning_2x2_tb/do_o
add wave -noupdate /binning_2x2_tb/de_o
add wave -noupdate /binning_2x2_tb/hs_o
add wave -noupdate /binning_2x2_tb/vs_o
TreeUpdate [SetDefaultTree]
WaveRestoreCursors
quietly wave cursor active 0
configure wave -namecolwidth 285
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
configure wave -timelineunits ns
update
WaveRestoreZoom {2361564 ps} {4322108 ps}
