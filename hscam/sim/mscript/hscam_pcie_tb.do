quit -sim

## Execute script to generate 'today package'
#exec C:/Xilinx/ISE_DS/ISE/bin/nt64/xtclsh ../gen_today_pkg.tcl today_pkg_admxrc6t1_sim.vhd >today_pkg_admxrc6t1_sim.vhd

### Delete existing libraries
#file delete -force -- work
#vlib work
#
#vlog     "C:/Xilinx/14.2/ISE_DS/ISE/verilog/src/glbl.v"
#
#vcom -93 "../../../common/lib/hw/lib/vicg/vicg_common_pkg.vhd"
#vcom -93 "../../ise/src/pcie/v5/clocks_pkg.vhd"
#vcom -93 "../../ise/src/pcie/v5/hscam_pcie_cfg.vhd"
#vcom -93 "../../ise/src/pcie/v5/clocks.vhd"
#vcom -93 "../../ise/src/pcie/vfr_gen.vhd"
#
#vcom -93 "../testbanch/hscam_pcie_tb.vhd"
#
## Testbench
#vcom -93 "../testbanch/hscam_pcie_tb.vhd"
#
###Load the design. Use required libraries.#
#vsim -t ps -novopt +notimingchecks -L unisim -L secureip work.hscam_pcie_tb glbl
#
#do hscam_pcie_wave.do



## Delete existing libraries
file delete -force -- work
vlib work

vlog     "C:/Xilinx/14.2/ISE_DS/ISE/verilog/src/glbl.v"

vcom -93 "../../../common/lib/hw/lib/vicg/vicg_common_pkg.vhd"

vcom -93 "../../../common/lib/hw/mem/mem_glob_pkg.vhd"
vcom -93 "../../../common/lib/hw/mem/alphadata/mem_wr_pkg.vhd"
vcom -93 "../../../common/lib/hw/mem/alphadata/mem_wr.vhd"

vcom -93 "../../ise/src/pcie/v5/hscam_pcie_cfg.vhd"
vcom -93 "../../../common/prj_def.vhd"
vcom -93 "../../ise/src/pcie/dsn_video_ctrl_pkg.vhd"
vcom -93 "../../../common/lib/hw/cfgdev_ctrl/cfgdev_pkg.vhd"
vcom -93 "../../../common/lib/hw/pci_express/pcie_pkg.vhd"
vcom -93 "../../ise/src/pcie/hscam_pcie_pkg.vhd"

vcom -93 "../../ise/src/pcie/v5/clocks_pkg.vhd"
vcom -93 "../../ise/src/pcie/v5/clocks.vhd"
vcom -93 "../../ise/src/pcie/vfr_gen.vhd"

vcom -93 "../../ise/src/core_gen/v5/vin_bufi.vhd"
vcom -93 "../../ise/src/core_gen/v5/vin_bufc.vhd"
vcom -93 "../../ise/src/core_gen/v5/vin_bufo.vhd"

vcom -93 "../../ise/src/pcie/dsn_switch.vhd"
vcom -93 "../../ise/src/pcie/dsn_video_ctrl.vhd"
vcom -93 "../../ise/src/pcie/video_reader.vhd"
vcom -93 "../../ise/src/pcie/video_writer.vhd"
vcom -93 "../../ise/src/pcie/vin.vhd"


vcom -93 "../testbanch/hscam_pcie_tb.vhd"

# Testbench
vcom -93 "../testbanch/hscam_pcie_tb.vhd"

##Load the design. Use required libraries.#
vsim -t ps -novopt +notimingchecks -L unisim -L secureip work.hscam_pcie_tb glbl

do hscam_pcie_wave2.do