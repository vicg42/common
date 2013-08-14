-------------------------------------------------------------------------
-- Company     : Linkos
-- Engineer    : Golovachenko Victor
--
-- Create Date : 23.11.2011 17:11:04
-- Module Name : veresk_pkg
--
-- Description :
--
-- Revision:
-- Revision 0.01 - File Created
--
-------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_arith.all;

library work;
use work.prj_cfg.all;
use work.prj_def.all;
use work.dsn_video_ctrl_pkg.all;
use work.pcie_pkg.all;
use work.mem_wr_pkg.all;
use work.prom_phypin_pkg.all;

package veresk_pkg is


component dsn_host
generic(
G_PCIE_LINK_WIDTH : integer:=1;
G_PCIE_RST_SEL    : integer:=1;
G_DBG      : string:="OFF";
G_SIM_HOST : string:="OFF";
G_SIM_PCIE : std_logic:='0'
);
port(
-------------------------------
--PCI-Express
-------------------------------
p_out_pciexp_txp  : out   std_logic_vector(G_PCIE_LINK_WIDTH-1 downto 0);
p_out_pciexp_txn  : out   std_logic_vector(G_PCIE_LINK_WIDTH-1 downto 0);
p_in_pciexp_rxp   : in    std_logic_vector(G_PCIE_LINK_WIDTH-1 downto 0);
p_in_pciexp_rxn   : in    std_logic_vector(G_PCIE_LINK_WIDTH-1 downto 0);

p_in_pciexp_gt_clkin   : in    std_logic;
p_out_pciexp_gt_clkout : out   std_logic;

-------------------------------
--Пользовательский порт
-------------------------------
p_out_hclk        : out   std_logic;
p_out_gctrl       : out   std_logic_vector(C_HREG_CTRL_LAST_BIT downto 0);

--Управление внешними устройствами
p_out_dev_ctrl    : out   std_logic_vector(C_HREG_DEV_CTRL_LAST_BIT downto 0);
p_out_dev_din     : out   std_logic_vector(C_HDEV_DWIDTH-1 downto 0);
p_in_dev_dout     : in    std_logic_vector(C_HDEV_DWIDTH-1 downto 0);
p_out_dev_wr      : out   std_logic;
p_out_dev_rd      : out   std_logic;
p_in_dev_status   : in    std_logic_vector(C_HREG_DEV_STATUS_LAST_BIT downto 0);
p_in_dev_irq      : in    std_logic_vector(C_HIRQ_COUNT_MAX-1 downto 0);
p_in_dev_opt      : in    std_logic_vector(C_HDEV_OPTIN_LAST_BIT downto 0);
p_out_dev_opt     : out   std_logic_vector(C_HDEV_OPTOUT_LAST_BIT downto 0);

p_out_usr_tst     : out   std_logic_vector(127 downto 0);
p_in_usr_tst      : in    std_logic_vector(127 downto 0);

-------------------------------
--Технологический
-------------------------------
p_in_tst          : in    std_logic_vector(31 downto 0);
p_out_tst         : out   std_logic_vector(255 downto 0);

-------------------------------
--System
-------------------------------
p_out_module_rdy  : out   std_logic;
p_in_rst_n        : in    std_logic
);
end component;

component dsn_timer
port(
-------------------------------
-- Конфигурирование модуля dsn_timer.vhd (host_clk domain)
-------------------------------
p_in_host_clk         : in   std_logic;

p_in_cfg_adr          : in   std_logic_vector(7 downto 0);
p_in_cfg_adr_ld       : in   std_logic;
p_in_cfg_adr_fifo     : in   std_logic;

p_in_cfg_txdata       : in   std_logic_vector(15 downto 0);
p_in_cfg_wd           : in   std_logic;

p_out_cfg_rxdata      : out  std_logic_vector(15 downto 0);
p_in_cfg_rd           : in   std_logic;

p_in_cfg_done         : in   std_logic;

-------------------------------
-- STATUS модуля dsn_timer.vhd
-------------------------------
p_in_tmr_clk          : in   std_logic;
p_out_tmr_rdy         : out  std_logic;
p_out_tmr_error       : out  std_logic;

p_out_tmr_irq         : out  std_logic_vector(C_TMR_COUNT-1 downto 0);
p_out_tmr_en          : out  std_logic_vector(C_TMR_COUNT-1 downto 0);

-------------------------------
--System
-------------------------------
p_in_rst            : in    std_logic
);
end component;

component dsn_switch
port(
-------------------------------
-- Конфигурирование модуля DSN_SWITCH.VHD (host_clk domain)
-------------------------------
p_in_cfg_clk              : in   std_logic;

p_in_cfg_adr              : in   std_logic_vector(7 downto 0);
p_in_cfg_adr_ld           : in   std_logic;
p_in_cfg_adr_fifo         : in   std_logic;

p_in_cfg_txdata           : in   std_logic_vector(15 downto 0);
p_in_cfg_wd               : in   std_logic;

p_out_cfg_rxdata          : out  std_logic_vector(15 downto 0);
p_in_cfg_rd               : in   std_logic;

p_in_cfg_done             : in   std_logic;

-------------------------------
-- Связь с Хостом (host_clk domain)
-------------------------------
p_in_host_clk             : in   std_logic;

-- Связь Хост <-> ETH(dsn_eth.vhd)
p_out_host_eth_rxd_irq    : out  std_logic;
p_out_host_eth_rxd_rdy    : out  std_logic;
p_out_host_eth_rxd        : out  std_logic_vector(31 downto 0);
p_in_host_eth_rd          : in   std_logic;

p_out_host_eth_txbuf_rdy  : out  std_logic;
p_in_host_eth_txd         : in   std_logic_vector(31 downto 0);
p_in_host_eth_wr          : in   std_logic;

-- Связь Хост <-> VideoBUF
p_out_host_vbuf_dout      : out  std_logic_vector(31 downto 0);
p_in_host_vbuf_rd         : in   std_logic;
p_out_host_vbuf_empty     : out  std_logic;

---------------------------------
---- Связь с Накопителем(dsn_hdd.vhd)
---------------------------------
--p_in_hdd_tstgen           : in   THDDTstGen;
--p_in_hdd_vbuf_rdclk       : in   std_logic;
--
--p_out_hdd_vbuf_dout       : out  std_logic_vector(31 downto 0);
--p_in_hdd_vbuf_rd          : in   std_logic;
--p_out_hdd_vbuf_empty      : out  std_logic;
--p_out_hdd_vbuf_full       : out  std_logic;
--p_out_hdd_vbuf_pfull      : out  std_logic;
--p_out_hdd_vbuf_wrcnt      : out  std_logic_vector(3 downto 0);

-------------------------------
-- Связь с EthG(Оптика)(dsn_optic.vhd) (ethg_clk domain)
-------------------------------
p_in_eth_clk              : in   std_logic;

p_in_eth_rxd_sof          : in   std_logic;
p_in_eth_rxd_eof          : in   std_logic;
p_in_eth_rxbuf_din        : in   std_logic_vector(31 downto 0);
p_in_eth_rxbuf_wr         : in   std_logic;
p_out_eth_rxbuf_empty     : out  std_logic;
p_out_eth_rxbuf_full      : out  std_logic;

--p_out_eth_txd_rdy         : out  std_logic;
p_out_eth_txbuf_dout      : out  std_logic_vector(31 downto 0);
p_in_eth_txbuf_rd         : in   std_logic;
p_out_eth_txbuf_empty     : out  std_logic;
p_out_eth_txbuf_full      : out  std_logic;

-------------------------------
-- Связь с Модулем Видео контроллера(dsn_video_ctrl.vhd) (trc_clk domain)
-------------------------------
p_in_vctrl_clk            : in   std_logic;

p_out_vctrl_vbufin_rdy    : out  std_logic;
p_out_vctrl_vbufin_dout   : out  std_logic_vector(31 downto 0);
p_in_vctrl_vbufin_rd      : in   std_logic;
p_out_vctrl_vbufin_empty  : out  std_logic;
p_out_vctrl_vbufin_full   : out  std_logic;
p_out_vctrl_vbufin_pfull  : out  std_logic;

p_in_vctrl_vbufout_din    : in   std_logic_vector(31 downto 0);
p_in_vctrl_vbufout_wr     : in   std_logic;
p_out_vctrl_vbufout_empty : out  std_logic;
p_out_vctrl_vbufout_full  : out  std_logic;

-------------------------------
--Технологический
-------------------------------
p_in_tst                  : in    std_logic_vector(31 downto 0);
p_out_tst                 : out   std_logic_vector(31 downto 0);

-------------------------------
--System
-------------------------------
p_in_rst     : in    std_logic
);
end component;

component dsn_video_ctrl
generic(
G_DBGCS  : string:="OFF";
G_ROTATE : string:="OFF";
G_ROTATE_BUF_COUNT: integer:=16;
G_SIMPLE : string:="OFF";
G_SIM    : string:="OFF";

G_MEM_AWIDTH : integer:=32;
G_MEM_DWIDTH : integer:=32
);
port(
-------------------------------
-- Конфигурирование модуля dsn_video_ctrl.vhd (host_clk domain)
-------------------------------
p_in_host_clk         : in   std_logic;

p_in_cfg_adr          : in   std_logic_vector(7 downto 0);
p_in_cfg_adr_ld       : in   std_logic;
p_in_cfg_adr_fifo     : in   std_logic;

p_in_cfg_txdata       : in   std_logic_vector(15 downto 0);
p_in_cfg_wd           : in   std_logic;

p_out_cfg_rxdata      : out  std_logic_vector(15 downto 0);
p_in_cfg_rd           : in   std_logic;

p_in_cfg_done         : in   std_logic;

-------------------------------
-- Связь с ХОСТ
-------------------------------
p_in_vctrl_hrdchsel   : in    std_logic_vector(3 downto 0);
p_in_vctrl_hrdstart   : in    std_logic;
p_in_vctrl_hrddone    : in    std_logic;
p_out_vctrl_hirq      : out   std_logic_vector(C_VCTRL_VCH_COUNT-1 downto 0);
p_out_vctrl_hdrdy     : out   std_logic_vector(C_VCTRL_VCH_COUNT-1 downto 0);
p_out_vctrl_hfrmrk    : out   std_logic_vector(31 downto 0);

-------------------------------
-- STATUS модуля dsn_video_ctrl.vhd
-------------------------------
p_out_vctrl_modrdy    : out   std_logic;
p_out_vctrl_moderr    : out   std_logic;
p_out_vctrl_rd_done   : out   std_logic;

p_out_vctrl_vrdprm    : out   TReaderVCHParams;
p_out_vctrl_vfrrdy    : out   std_logic_vector(C_VCTRL_VCH_COUNT-1 downto 0);
p_out_vctrl_vrowmrk   : out   TVMrks;

----------------------------
--Связь с модулем слежения
----------------------------
p_in_trc_busy         : in    std_logic_vector(C_VCTRL_VCH_COUNT-1 downto 0);
p_out_trc_vbuf        : out   TVfrBufs;

-------------------------------
-- Связь с буферами модуля dsn_switch.vhd
-------------------------------
p_out_vbuf_clk        : out   std_logic;

p_in_vbufin_rdy       : in    std_logic;
p_in_vbufin_dout      : in    std_logic_vector(31 downto 0);
p_out_vbufin_dout_rd  : out   std_logic;
p_in_vbufin_empty     : in    std_logic;
p_in_vbufin_full      : in    std_logic;
p_in_vbufin_pfull     : in    std_logic;

p_out_vbufout_din     : out   std_logic_vector(31 downto 0);
p_out_vbufout_din_wd  : out   std_logic;
p_in_vbufout_empty    : in    std_logic;
p_in_vbufout_full     : in    std_logic;

---------------------------------
-- Связь с mem_ctrl.vhd
---------------------------------
--CH WRITE
p_out_memwr           : out TMemIN;
p_in_memwr            : in  TMemOUT;
--CH READ
p_out_memrd           : out TMemIN;
p_in_memrd            : in  TMemOUT;

-------------------------------
--Технологический
-------------------------------
p_out_tst             : out   std_logic_vector(31 downto 0);

-------------------------------
--System
-------------------------------
p_in_clk              : in    std_logic;
p_in_rst              : in    std_logic
);
end component;

component pcie2mem_ctrl
generic(
G_MEM_AWIDTH     : integer:=32;
G_MEM_DWIDTH     : integer:=32;
G_MEM_BANK_M_BIT : integer:=29;
G_MEM_BANK_L_BIT : integer:=28;
G_DBG            : string :="OFF"
);
port(
-------------------------------
--Управление
-------------------------------
p_in_ctrl         : in    TPce2Mem_Ctrl;
p_out_status      : out   TPce2Mem_Status;

p_in_txd          : in    std_logic_vector(31 downto 0);
p_in_txd_wr       : in    std_logic;
p_out_txbuf_full  : out   std_logic;

p_out_rxd         : out   std_logic_vector(31 downto 0);
p_in_rxd_rd       : in    std_logic;
p_out_rxbuf_empty : out   std_logic;

p_in_hclk         : in    std_logic;

-------------------------------
--Связь с mem_ctrl
-------------------------------
p_out_mem         : out   TMemIN;
p_in_mem          : in    TMemOUT;

-------------------------------
--Технологический
-------------------------------
p_in_tst          : in    std_logic_vector(31 downto 0);
p_out_tst         : out   std_logic_vector(31 downto 0);

-------------------------------
--System
-------------------------------
p_in_clk          : in    std_logic;
p_in_rst          : in    std_logic
);
end component;

component pult_io
port(
trans_ack      : in  std_logic;

data_i         : in  std_logic;
data_o         : out std_logic;
dir_485        : out std_logic;

host_clk_wr    : in  std_logic;
wr_en          : in  std_logic;
data_from_host : in  std_logic_vector(31 downto 0);

host_clk_rd    : in  std_logic;
rd_en          : in  std_logic;
data_to_host   : out std_logic_vector(31 downto 0);

busy           : out std_logic;
ready          : out std_logic;

tmr_en         : in  std_logic;
tmr_stb        : in  std_logic;
clk_io_en      : in  std_logic;
clk_io         : in  std_logic;
rst            : in  std_logic
);
end component;

component sync_u
port(
i_pps         : in  std_logic;
i_ext_1s      : in  std_logic;
i_ext_1m      : in  std_logic;

sync_iedge    : in  std_logic;
sync_oedge    : in  std_logic;
sync_time_en  : in  std_logic;
mode_set_time : in  std_logic;
type_of_sync  : in  std_logic_vector(1 downto 0);

sync_win      : out  std_logic;

stime         : out  std_logic_vector(31 downto 0);
n_sync        : out  std_logic_vector(7 downto 0);
sync_cou_err  : out  std_logic_vector(7 downto 0);

sync_out1     : out  std_logic;
out_1s        : out  std_logic;
out_1m        : out  std_logic;
sync_out2     : out  std_logic;
sync_ld       : out  std_logic;
sync_pic      : out  std_logic;
--sync_piezo    : out  std_logic;
--sync_cam_ir   : out  std_logic;

host_wr_data  : in  std_logic_vector(31 downto 0);
wr_en_time    : in  std_logic;
host_clk      : in  std_logic;

i_clk         : in  std_logic
);
end component;

component edev
generic(
G_DBG : string:="OFF";
G_SIM : string:="OFF"
);
port(
p_in_tmr_en       : in   std_logic;
p_in_tmr_stb      : in   std_logic;

-------------------------------
--Связь с HOST
-------------------------------
p_out_host_rxrdy  : out  std_logic;
p_out_host_rxd    : out  std_logic_vector(31 downto 0);
p_in_host_rd      : in   std_logic;

p_out_host_txrdy  : out  std_logic;
p_in_host_txd     : in   std_logic_vector(31 downto 0);
p_in_host_wr      : in   std_logic;

p_in_host_clk     : in   std_logic;

p_out_hirq        : out  std_logic;
p_out_herr        : out  std_logic;

--------------------------------------
--PHY (half-duplex)
--------------------------------------
p_in_phy_rx       : in   std_logic;
p_out_phy_tx      : out  std_logic;
p_out_phy_dir     : out  std_logic;

------------------------------------
--Технологические сигналы
------------------------------------
p_in_tst          : in   std_logic_vector(31 downto 0);
p_out_tst         : out  std_logic_vector(31 downto 0);

--------------------------------------
--System
--------------------------------------
p_in_bitclk       : in   std_logic;
p_in_clk          : in   std_logic;
p_in_rst          : in   std_logic
);
end component;

component prom_ld
generic(
G_HOST_DWIDTH : integer:=32
);
port(
-------------------------------
--Связь с HOST
-------------------------------
p_out_host_rxd   : out   std_logic_vector(G_HOST_DWIDTH - 1 downto 0);
p_in_host_rd     : in    std_logic;
p_out_rxbuf_full : out   std_logic;
p_out_rxbuf_empty: out   std_logic;

p_in_host_txd    : in    std_logic_vector(G_HOST_DWIDTH - 1 downto 0);
p_in_host_wr     : in    std_logic;
p_out_txbuf_full : out   std_logic;
p_out_txbuf_empty: out   std_logic;

p_in_host_clk    : in    std_logic;

p_out_hirq       : out   std_logic;
p_out_herr       : out   std_logic;

-------------------------------
--PHY
-------------------------------
p_in_phy         : in    TPromPhyIN;
p_out_phy        : out   TPromPhyOUT;
p_inout_phy      : inout TPromPhyINOUT;

-------------------------------
--Технологический
-------------------------------
p_in_tst         : in    std_logic_vector(31 downto 0);
p_out_tst        : out   std_logic_vector(31 downto 0);

-------------------------------
--System
-------------------------------
p_in_clk         : in    std_logic;
p_in_rst         : in    std_logic
);
end component;

end veresk_pkg;


package body veresk_pkg is

end veresk_pkg;






