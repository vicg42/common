-------------------------------------------------------------------------
-- Company     : Linkos
-- Engineer    : Golovachenko Victor
--
-- Create Date : 03/02/2010
-- Module Name : hdd_vm_main
--
-- Назначение/Описание :
--
--
-- Revision:
-- Revision 0.01 - File Created
--
-------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_misc.all;
use ieee.std_logic_unsigned.all;

library unisim;
use unisim.vcomponents.all;

library work;
use work.vicg_common_pkg.all;
use work.prj_cfg.all;
use work.prj_def.all;
use work.memif.all;
use work.vereskm_pkg.all;
use work.cfgdev_pkg.all;
use work.mem_ctrl_pkg.all;
use work.mem_wr_pkg.all;
use work.sata_testgen_pkg.all;
use work.sata_glob_pkg.all;
use work.dsn_hdd_pkg.all;
use work.eth_phypin_pkg.all;
use work.eth_pkg.all;
use work.dsn_eth_pkg.all;
use work.dsn_video_ctrl_pkg.all;
use work.pcie_pkg.all;

entity hdd_vm_main is
generic(
G_SIM_HOST : string:="OFF";
G_SIM_PCIE : std_logic:='0';
G_DBG_PCIE : string:="OFF";
G_SIM      : string:="OFF"
);
port(
--------------------------------------------------
--Технологический порт
--------------------------------------------------
pin_out_uart0_tx  : out   std_logic;
pin_in_uart0_rx   : in    std_logic;

pin_out_led       : out   std_logic_vector(7 downto 0);
pin_out_led_C     : out   std_logic;
pin_out_led_E     : out   std_logic;
pin_out_led_N     : out   std_logic;
pin_out_led_S     : out   std_logic;
pin_out_led_W     : out   std_logic;

pin_out_TP        : out   std_logic_vector(7 downto 0);

pin_in_btn_C      : in    std_logic;
pin_in_btn_E      : in    std_logic;
pin_in_btn_N      : in    std_logic;
pin_in_btn_S      : in    std_logic;
pin_in_btn_W      : in    std_logic;

pin_out_ddr2_cke1 : out   std_logic;
pin_out_ddr2_cs1  : out   std_logic;
pin_out_ddr2_odt1 : out   std_logic;

--------------------------------------------------
--Memory banks
--------------------------------------------------
ra0               : out   std_logic_vector(C_MEM_BANK0.ra_width - 1 downto 0);
rc0               : inout std_logic_vector(C_MEM_BANK0.rc_width - 1 downto 0);
rd0               : inout std_logic_vector(C_MEM_BANK0.rd_width - 1 downto 0);
--ra1               : out   std_logic_vector(C_MEM_BANK1.ra_width - 1 downto 0);
--rc1               : inout std_logic_vector(C_MEM_BANK1.rc_width - 1 downto 0);
--rd1               : inout std_logic_vector(C_MEM_BANK1.rd_width - 1 downto 0);

--------------------------------------------------
--Ethernet
--------------------------------------------------
pin_out_gt_X0Y6_txp   : out  std_logic_vector(1 downto 0);
pin_out_gt_X0Y6_txn   : out  std_logic_vector(1 downto 0);
pin_in_gt_X0Y6_rxp    : in   std_logic_vector(1 downto 0);
pin_in_gt_X0Y6_rxn    : in   std_logic_vector(1 downto 0);
pin_in_gt_X0Y6_clk_p  : in   std_logic;
pin_in_gt_X0Y6_clk_n  : in   std_logic;

pin_out_sfp_tx_dis    : out   std_logic;--SFP - TX DISABLE
pin_in_sfp_sd         : in    std_logic;--SFP - SD signal detect

pin_out_ethphy        : out   TEthPhyFiberPinOUT;
pin_in_ethphy         : in    TEthPhyFiberPinIN;

--------------------------------------------------
--PCI-EXPRESS
--------------------------------------------------
pin_out_pciexp_txp    : out   std_logic_vector(C_PCGF_PCIE_LINK_WIDTH-1 downto 0);
pin_out_pciexp_txn    : out   std_logic_vector(C_PCGF_PCIE_LINK_WIDTH-1 downto 0);
pin_in_pciexp_rxp     : in    std_logic_vector(C_PCGF_PCIE_LINK_WIDTH-1 downto 0);
pin_in_pciexp_rxn     : in    std_logic_vector(C_PCGF_PCIE_LINK_WIDTH-1 downto 0);
pin_in_pciexp_clk_p   : in    std_logic;
pin_in_pciexp_clk_n   : in    std_logic;

--------------------------------------------------
--SATA
--------------------------------------------------
pin_out_sata_txn      : out   std_logic_vector((C_SH_GTCH_COUNT_MAX*C_SH_COUNT_MAX(C_PCFG_HDD_COUNT-1))-1 downto 0);
pin_out_sata_txp      : out   std_logic_vector((C_SH_GTCH_COUNT_MAX*C_SH_COUNT_MAX(C_PCFG_HDD_COUNT-1))-1 downto 0);
pin_in_sata_rxn       : in    std_logic_vector((C_SH_GTCH_COUNT_MAX*C_SH_COUNT_MAX(C_PCFG_HDD_COUNT-1))-1 downto 0);
pin_in_sata_rxp       : in    std_logic_vector((C_SH_GTCH_COUNT_MAX*C_SH_COUNT_MAX(C_PCFG_HDD_COUNT-1))-1 downto 0);
pin_in_sata_clk_n     : in    std_logic_vector(C_SH_COUNT_MAX(C_PCFG_HDD_COUNT-1)-1 downto 0);
pin_in_sata_clk_p     : in    std_logic_vector(C_SH_COUNT_MAX(C_PCFG_HDD_COUNT-1)-1 downto 0);

--------------------------------------------------
-- Local bus
--------------------------------------------------
lreset_l              : in    std_logic;
lclk                  : in    std_logic;
lwrite                : in    std_logic;
lads_l                : in    std_logic;
lblast_l              : in    std_logic;
lbe_l                 : in    std_logic_vector(32/8-1 downto 0);
lad                   : inout std_logic_vector(32-1 downto 0);
lbterm_l              : inout std_logic;
lready_l              : inout std_logic;
fholda                : in    std_logic;
finto_l               : out   std_logic;

--------------------------------------------------
-- Reference clock 200MHz
--------------------------------------------------
pin_in_refclk200M_n   : in    std_logic;
pin_in_refclk200M_p   : in    std_logic
);
end entity;

architecture struct of hdd_vm_main is

component dbgcs_iconx1
  PORT (
    CONTROL0 : INOUT STD_LOGIC_VECTOR(35 DOWNTO 0)
    );
end component;

component dbgcs_iconx2
  PORT (
    CONTROL0 : INOUT STD_LOGIC_VECTOR(35 DOWNTO 0);
    CONTROL1 : INOUT STD_LOGIC_VECTOR(35 DOWNTO 0)
    );
end component;

component dbgcs_iconx3
  PORT (
    CONTROL0 : INOUT STD_LOGIC_VECTOR(35 DOWNTO 0);
    CONTROL1 : INOUT STD_LOGIC_VECTOR(35 DOWNTO 0);
    CONTROL2 : INOUT STD_LOGIC_VECTOR(35 DOWNTO 0)
    );
end component;

component dbgcs_sata_layer
  PORT (
    CONTROL : INOUT STD_LOGIC_VECTOR(35 DOWNTO 0);
    CLK : IN STD_LOGIC;
    DATA : IN STD_LOGIC_VECTOR(122 DOWNTO 0);
    TRIG0 : IN STD_LOGIC_VECTOR(41 DOWNTO 0)
    );
end component;

component dbgcs_sata_rambuf
  PORT (
    CONTROL : INOUT STD_LOGIC_VECTOR(35 DOWNTO 0);
    CLK : IN STD_LOGIC;
    DATA : IN STD_LOGIC_VECTOR(136 DOWNTO 0);
    TRIG0 : IN STD_LOGIC_VECTOR(11 DOWNTO 0)
    );
end component;

component dbgcs_sata_raid
  PORT (
    CONTROL : INOUT STD_LOGIC_VECTOR(35 DOWNTO 0);
    CLK : IN STD_LOGIC;
    DATA : IN STD_LOGIC_VECTOR(172 downto 0); --(122 DOWNTO 0);
    TRIG0 : IN STD_LOGIC_VECTOR(41 DOWNTO 0)
    );
end component;

component dbgcs_cfg
  PORT (
    CONTROL : INOUT STD_LOGIC_VECTOR(35 DOWNTO 0);
    CLK : IN STD_LOGIC;
    DATA : IN STD_LOGIC_VECTOR(113 downto 0);
    TRIG0 : IN STD_LOGIC_VECTOR(15 DOWNTO 0)
    );
end component;

component dbgcs_sata_hwstart
  PORT (
    CONTROL : INOUT STD_LOGIC_VECTOR(35 DOWNTO 0);
    CLK : IN STD_LOGIC;
    DATA : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
    TRIG0 : IN STD_LOGIC_VECTOR(7 DOWNTO 0)
    );
end component;

signal i_dbgcs_sh0_layer                : std_logic_vector(35 downto 0);
signal i_dbgcs_hdd_rambuf               : std_logic_vector(35 downto 0);
signal i_dbgcs_hdd_raid                 : std_logic_vector(35 downto 0);
signal i_dbgcs_cfg                      : std_logic_vector(35 downto 0);
signal i_dbgcs_hwstart_dly              : std_logic_vector(35 downto 0);

signal tst_sh0_llayer   : std_logic_vector(4 downto 0):=(others=>'0');
signal tst_sh1_llayer   : std_logic_vector(4 downto 0):=(others=>'0');
signal tst_trm_timeout  : std_logic_vector(15 downto 0):=(others=>'0');
--signal tst_hdd_mem_dcnt : std_logic_vector(15 downto 0):=(others=>'0');


component dsn_hdd_rambuf is
generic(
G_MODULE_USE  : string:="ON";
G_RAMBUF_SIZE : integer:=23;
G_DBGCS       : string:="OFF";
G_SIM         : string:="OFF";

G_MEM_AWIDTH  : integer:=32;
G_MEM_DWIDTH  : integer:=32
);
port(
-------------------------------
-- Конфигурирование
-------------------------------
p_in_rbuf_cfg         : in    THDDRBufCfg;
p_out_rbuf_status     : out   THDDRBufStatus;

--//--------------------------
--//Связь с буфером видеоданных
--//--------------------------
p_in_vbuf_dout        : in    std_logic_vector(31 downto 0);
p_out_vbuf_rd         : out   std_logic;
p_in_vbuf_empty       : in    std_logic;
p_in_vbuf_full        : in    std_logic;
p_in_vbuf_pfull       : in    std_logic;
p_in_vbuf_wrcnt       : in    std_logic_vector(3 downto 0);

--//--------------------------
--//Связь с модулем HDD
--//--------------------------
p_out_hdd_txd         : out   std_logic_vector(31 downto 0);
p_out_hdd_txd_wr      : out   std_logic;
p_in_hdd_txbuf_pfull  : in    std_logic;
p_in_hdd_txbuf_full   : in    std_logic;
p_in_hdd_txbuf_empty  : in    std_logic;

p_in_hdd_rxd          : in    std_logic_vector(31 downto 0);
p_out_hdd_rxd_rd      : out   std_logic;
p_in_hdd_rxbuf_empty  : in    std_logic;
p_in_hdd_rxbuf_pempty : in    std_logic;

---------------------------------
-- Связь с mem_ctrl.vhd
---------------------------------
p_out_mem             : out   TMemIN;
p_in_mem              : in    TMemOUT;

-------------------------------
--Технологический
-------------------------------
p_in_tst              : in    std_logic_vector(31 downto 0);
p_out_tst             : out   std_logic_vector(31 downto 0);
p_out_dbgcs           : out   TSH_ila;

-------------------------------
--System
-------------------------------
p_in_clk              : in    std_logic;
p_in_rst              : in    std_logic
);
end component;

component vtester_v01
generic(
G_SIM : string:="OFF"
);
port(
-------------------------------
-- Управление от Хоста
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
-- STATUS модуля dsn_testing.VHD
-------------------------------
p_out_module_rdy      : out  std_logic;
p_out_module_error    : out  std_logic;

-------------------------------
--Связь с выходным буфером
-------------------------------
p_out_dst_dout_rdy   : out   std_logic;
p_out_dst_dout       : out   std_logic_vector(31 downto 0);
p_out_dst_dout_wd    : out   std_logic;
p_in_dst_rdy         : in    std_logic;
--p_in_dst_clk         : in    std_logic;

-------------------------------
--Технологический
-------------------------------
p_out_tst           : out   std_logic_vector(31 downto 0);

-------------------------------
--System
-------------------------------
p_in_tmrclk  : in    std_logic;

p_in_clk     : in    std_logic;
p_in_rst     : in    std_logic
);
end component;

component fpga_test_01
generic(
G_BLINK_T05   : integer:=10#125#; -- 1/2 периода мигания светодиода.(время в ms)
G_CLK_T05us   : integer:=10#1000# -- кол-во периодов частоты порта p_in_clk
                                  -- укладывающиес_ в 1/2 периода 1us
);
port(
p_out_test_led : out   std_logic;--//мигание сведодиода
p_out_test_done: out   std_logic;--//сигнал переходи в '1' через 3 сек.

p_out_1us      : out   std_logic;
p_out_1ms      : out   std_logic;
-------------------------------
--System
-------------------------------
p_in_clk       : in    std_logic;
p_in_rst       : in    std_logic
);
end component;

component gtp_prog_clkmux
generic(
G_CLKIN_CHANGE     : std_logic := '0';
G_CLKSOUTH_CHANGE  : std_logic := '0';
G_CLKNORTH_CHANGE  : std_logic := '0';

G_CLKIN_MUX_VAL    : std_logic_vector(2 downto 0):="011";
G_CLKSOUTH_MUX_VAL : std_logic := '0';
G_CLKNORTH_MUX_VAL : std_logic := '0'
);
port(
p_in_drp_rst    : in    std_logic;
p_in_drp_clk    : in    std_logic;

p_out_txp       : out   std_logic_vector(1 downto 0);
p_out_txn       : out   std_logic_vector(1 downto 0);
p_in_rxp        : in    std_logic_vector(1 downto 0);
p_in_rxn        : in    std_logic_vector(1 downto 0);

p_in_clkin      : in    std_logic;
p_out_refclkout : out   std_logic
);
end component;

component lbus_dcm
generic(
G_CLKFX_DIV  : integer:=1;
G_CLKFX_MULT : integer:=2
);
port(
p_out_gclkin : out   std_logic;
p_out_clk0   : out   std_logic;
p_out_clkfx  : out   std_logic;
--p_out_clkdiv : out   std_logic;
--p_out_clk2x  : out   std_logic;
p_out_locked : out   std_logic;

p_in_clk     : in    std_logic;
p_in_rst     : in    std_logic
);
end component;

component mem_pll
port(
mclk      : in  std_logic;
rst       : in  std_logic;
refclk200 : in  std_logic;

clk0      : out std_logic;
clk45     : out std_logic;
clk2x0    : out std_logic;
clk2x90   : out std_logic;
locked    : out std_logic_vector(1 downto 0);
memrst    : out std_logic
);
end component;

signal i_usr_rst                        : std_logic;

signal i_refclk200MHz                   : std_logic;
signal g_refclk200MHz                   : std_logic;

signal i_gt_X0Y6_rst                    : std_logic;
signal i_gt_X0Y6_clkin                  : std_logic;

signal i_dcm_rst_cnt                    : std_logic_vector(5 downto 0);
signal i_dcm_rst                        : std_logic;

signal g_lbus_clkin                     : std_logic;
--signal g_lbus_clkdiv                    : std_logic;
--signal g_lbus_clk2x                     : std_logic;
signal g_lbus_clkfx                     : std_logic;
signal g_lbus_clk                       : std_logic;
signal lclk_dcm_lock                    : std_logic;

signal g_usr_highclk                    : std_logic;

signal i_memctrl_pllclk0                : std_logic;
signal i_memctrl_pllclk45               : std_logic;
signal i_memctrl_pllclk2x0              : std_logic;
signal i_memctrl_pllclk2x90             : std_logic;
signal i_memctrl_pll_rst_out            : std_logic;

signal i_pciexp_gt_refclk               : std_logic;
signal g_pciexp_gt_refclkout            : std_logic;

signal i_host_rdy                       : std_logic;
signal i_host_rst_n                     : std_logic;
signal g_host_clk                       : std_logic;
signal i_host_gctrl                     : std_logic_vector(C_HREG_CTRL_LAST_BIT downto 0);
signal i_host_dev_ctrl                  : std_logic_vector(C_HREG_DEV_CTRL_LAST_BIT downto 0);
signal i_host_dev_txd                   : std_logic_vector(C_HDEV_DWIDTH-1 downto 0);
signal i_host_dev_rxd                   : std_logic_vector(C_HDEV_DWIDTH-1 downto 0);
signal i_host_dev_wr                    : std_logic;
signal i_host_dev_rd                    : std_logic;
signal i_host_dev_status                : std_logic_vector(C_HREG_DEV_STATUS_LAST_BIT downto 0);
signal i_host_dev_irq                   : std_logic_vector(C_HIRQ_COUNT_MAX-1 downto 0);
signal i_host_dev_opt_in                : std_logic_vector(C_HDEV_OPTIN_LAST_BIT downto 0);
signal i_host_dev_opt_out               : std_logic_vector(C_HDEV_OPTOUT_LAST_BIT downto 0);

signal i_host_devadr                    : std_logic_vector(C_HREG_DEV_CTRL_ADR_M_BIT-C_HREG_DEV_CTRL_ADR_L_BIT downto 0);
signal i_host_vchsel                    : std_logic_vector(3 downto 0);

Type THostDCtrl is array (0 to C_HDEV_COUNT-1) of std_logic;
Type THostDWR is array (0 to C_HDEV_COUNT-1) of std_logic_vector(i_host_dev_txd'range);
signal i_host_wr                        : THostDCtrl;
signal i_host_rd                        : THostDCtrl;
signal i_host_txd                       : THostDWR;
signal i_host_rxd                       : THostDWR;
signal i_host_rxrdy                     : THostDCtrl;
signal i_host_txrdy                     : THostDCtrl;
signal i_host_rxbuf_empty               : THostDCtrl;
signal i_host_txbuf_full                : THostDCtrl;
signal i_host_irq                       : std_logic_vector(C_HIRQ_COUNT_MAX-1 downto 0);

signal i_host_rst_all                   : std_logic;
signal i_host_rst_eth                   : std_logic;
signal i_host_rst_mem                   : std_logic;
signal i_host_rddone_vctrl              : std_logic;
signal i_host_rddone_trcnik             : std_logic;

Type THDevWidthCnt is array (0 to C_HDEV_COUNT-1) of std_logic_vector(2 downto 0);
signal i_hdev_dma_start                 : std_logic_vector(C_HDEV_COUNT-1 downto 0);
signal hclk_hdev_dma_start              : std_logic_vector(C_HDEV_COUNT-1 downto 0);
signal hclk_hdev_dma_start_cnt          : THDevWidthCnt;

signal i_host_tst_in                    : std_logic_vector(127 downto 0);
signal i_host_tst_out                   : std_logic_vector(127 downto 0);
signal i_host_tst2_out                  : std_logic_vector(255 downto 0);

signal i_cfg_rst                        : std_logic;
signal i_cfg_rdy                        : std_logic;
signal i_cfg_dadr     ,i_cfgu_dadr     ,i_cfghdd_dadr      : std_logic_vector(C_CFGPKT_DADR_M_BIT-C_CFGPKT_DADR_L_BIT downto 0);
signal i_cfg_radr     ,i_cfgu_radr     ,i_cfghdd_radr      : std_logic_vector(C_CFGPKT_RADR_M_BIT-C_CFGPKT_RADR_L_BIT downto 0);
signal i_cfg_radr_ld  ,i_cfgu_radr_ld  ,i_cfghdd_radr_ld   : std_logic;
signal i_cfg_radr_fifo,i_cfgu_radr_fifo,i_cfghdd_radr_fifo : std_logic;
signal i_cfg_wr       ,i_cfgu_wr       ,i_cfghdd_wr        : std_logic;
signal i_cfg_rd       ,i_cfgu_rd       ,i_cfghdd_rd        : std_logic;
signal i_cfg_txd      ,i_cfgu_txdata   ,i_cfghdd_txdata    : std_logic_vector(15 downto 0);
signal i_cfg_done     ,i_cfgu_done     ,i_cfghdd_done      : std_logic;
signal i_cfg_rxd      ,i_cfgu_rxdata   ,i_cfghdd_rxdata    : std_logic_vector(15 downto 0);
Type TCfgRxD is array (0 to C_CFGDEV_COUNT-1) of std_logic_vector(i_cfg_rxd'range);
signal i_cfg_rxd_dev                    : TCfgRxD;
signal i_cfg_wr_dev                     : std_logic_vector(C_CFGDEV_COUNT-1 downto 0);
signal i_cfg_rd_dev                     : std_logic_vector(C_CFGDEV_COUNT-1 downto 0);
signal i_cfg_done_dev                   : std_logic_vector(C_CFGDEV_COUNT-1 downto 0);
--signal i_cfgdev_tst_out                 : std_logic_vector(31 downto 0);
signal i_cfg_dbgcs                      : TSH_ila;
signal i_cfghdd_selif                   : std_logic;
signal i_cfghdd_txrdy,i_cfghdd_rxrdy    : std_logic;

signal i_swt_rst                        : std_logic;
signal i_swt_tst_out                    : std_logic_vector(31 downto 0);

signal i_eth_gt_refclk125               : std_logic;
signal i_eth_rst                        : std_logic;
signal i_eth_out                        : TEthOUTs;
signal i_eth_in                         : TEthINs;
signal i_ethphy_out                     : TEthPhyOUT;
signal i_ethphy_in                      : TEthPhyIN;
signal i_eth_tst_out                    : std_logic_vector(31 downto 0);

signal i_tmr_rst                        : std_logic;
signal i_tmr_clk                        : std_logic;
signal i_tmr_hirq                       : std_logic_vector(C_TMR_COUNT-1 downto 0);

signal i_vctrl_rst                      : std_logic;
signal hclk_hrddone_vctrl_cnt           : std_logic_vector(2 downto 0);
signal hclk_hrddone_vctrl               : std_logic;
--signal i_vctrl_module_rdy               : std_logic;
--signal i_vctrl_module_error             : std_logic;
signal i_vctrl_vbufin_rdy               : std_logic;
signal i_vctrl_vbufin_dout              : std_logic_vector(31 downto 0);
signal i_vctrl_vbufin_rd                : std_logic;
signal i_vctrl_vbufin_empty             : std_logic;
signal i_vctrl_vbufin_pfull             : std_logic;
signal i_vctrl_vbufin_full              : std_logic;
signal i_vctrl_vbufout_din              : std_logic_vector(31 downto 0);
signal i_vctrl_vbufout_wd               : std_logic;
signal i_vctrl_vbufout_empty            : std_logic;
signal i_vctrl_vbufout_full             : std_logic;

signal i_vctrl_hrd_start                : std_logic;
signal i_vctrl_hrd_done                 : std_logic;
signal i_vctrl_hrd_done_dly             : std_logic_vector(1 downto 0);
signal g_vctrl_swt_bufclk               : std_logic;
signal i_vctrl_hirq                     : std_logic_vector(C_VCTRL_VCH_COUNT-1 downto 0);
signal i_vctrl_hrdy                     : std_logic_vector(C_VCTRL_VCH_COUNT-1 downto 0);
signal i_vctrl_hirq_out                 : std_logic_vector(C_VCTRL_VCH_COUNT_MAX-1 downto 0);
signal i_vctrl_hrdy_out                 : std_logic_vector(C_VCTRL_VCH_COUNT_MAX-1 downto 0);
signal i_vctrl_hfrmrk                   : std_logic_vector(31 downto 0);
signal i_vctrl_vrd_done                 : std_logic;
signal i_vctrl_tst_out                  : std_logic_vector(31 downto 0);
signal i_vctrl_vrdprms                  : TReaderVCHParams;
signal i_vctrl_vfrdy                    : std_logic_vector(C_VCTRL_VCH_COUNT-1 downto 0);
signal i_vctrl_vrowmrk                  : TVMrks;
signal i_vctrlwr_memin                  : TMemIN;
signal i_vctrlwr_memout                 : TMemOUT;
signal i_vctrlrd_memin                  : TMemIN;
signal i_vctrlrd_memout                 : TMemOUT;

signal i_trc_rst                        : std_logic;
signal hclk_hrddone_trcnik_cnt          : std_logic_vector(2 downto 0);
signal hclk_hrddone_trcnik              : std_logic;
signal i_trcnik_hrd_done_dly            : std_logic_vector(1 downto 0);
signal i_trcnik_hrd_done                : std_logic;
signal i_trcnik_hdrdy                   : std_logic:='0';
signal i_trcnik_hfrmrk                  : std_logic_vector(31 downto 0):=(others=>'0');
signal i_trc_tst_out                    : std_logic_vector(31 downto 0);
signal i_trc_vbufs                      : TVfrBufs;
signal i_trc_busy                       : std_logic_vector(C_VCTRL_VCH_COUNT-1 downto 0);
signal i_trc_memin                      : TMemIN;
signal i_trc_memout                     : TMemOUT;

signal i_host_mem_ctrl                  : TPce2Mem_Ctrl;
signal i_host_mem_status                : TPce2Mem_Status;
signal i_host_memin                     : TMemIN;
signal i_host_memout                    : TMemOUT;
signal i_host_mem_tst_out               : std_logic_vector(31 downto 0);

signal i_memctrl_rst                    : std_logic;
signal i_memctrl_locked                 : std_logic_vector(7 downto 0);
signal i_memctrl_trained                : std_logic_vector(max_num_bank - 1 downto 0);
signal i_memctrl_ready                  : std_logic;

signal i_memin_ch                       : TMemINCh;
signal i_memout_ch                      : TMemOUTCh;

signal i_arb_mem_rst                    : std_logic;
signal i_arb_memin                      : TMemIN;
signal i_arb_memout                     : TMemOUT;
signal i_arb_mem_tst_out                : std_logic_vector(31 downto 0);

signal i_swt_hdd_tstgen_cfg             : THDDTstGen;
signal i_hdd_rst                        : std_logic;
signal i_hdd_gt_refclk150               : std_logic_vector(C_SH_COUNT_MAX(C_PCFG_HDD_COUNT-1)-1 downto 0);
signal g_hdd_gt_refclkout               : std_logic;
signal i_hdd_gt_plldet                  : std_logic;
signal i_hdd_dcm_lock                   : std_logic;
signal i_hdd_module_rdy                 : std_logic;
signal i_hdd_module_error               : std_logic;
signal i_hdd_busy                       : std_logic;
--signal i_hdd_hirq                       : std_logic;
signal i_hdd_done                       : std_logic;
signal i_hdd_rxdata                     : std_logic_vector(31 downto 0);
signal i_hdd_rxdata_rd                  : std_logic;
signal i_hdd_rxbuf_empty                : std_logic;
signal i_hdd_rxbuf_pempty               : std_logic;
signal i_hdd_txdata                     : std_logic_vector(31 downto 0);
signal i_hdd_txdata_wd                  : std_logic;
signal i_hdd_txbuf_empty                : std_logic;
signal i_hdd_txbuf_pfull                : std_logic;
signal i_hdd_txbuf_full                 : std_logic;
signal i_hdd_vbuf_dout                  : std_logic_vector(31 downto 0);
signal i_hdd_vbuf_rd                    : std_logic;
signal i_hdd_vbuf_empty                 : std_logic;
signal i_hdd_vbuf_full                  : std_logic;
signal i_hdd_vbuf_pfull                 : std_logic;
signal i_hdd_vbuf_wrcnt                 : std_logic_vector(3 downto 0);
signal i_hdd_rbuf_cfg                   : THDDRBufCfg;
signal i_hdd_rbuf_status                : THDDRBufStatus;
signal i_hdd_rbuf_tst_out               : std_logic_vector(31 downto 0);
signal i_hdd_dbgled                     : THDDLed_SHCountMax;
signal i_hdd_tst_in                     : std_logic_vector(31 downto 0);
signal i_hdd_tst_out                    : std_logic_vector(31 downto 0);
signal i_hdd_dbgcs                      : TSH_dbgcs_exp;
signal i_hddrambuf_dbgcs                : TSH_ila;
signal i_hdd_rambuf_dbgcs               : TSH_ila;
--signal i_hdd_sim_gt_txdata              : TBus32_SHCountMax;--
--signal i_hdd_sim_gt_txcharisk           : TBus04_SHCountMax;--
--signal i_hdd_sim_gt_txcomstart          : std_logic_vector(C_HDD_COUNT_MAX-1 downto 0);--
signal i_hdd_sim_gt_rxdata              : TBus32_SHCountMax;
signal i_hdd_sim_gt_rxcharisk           : TBus04_SHCountMax;
signal i_hdd_sim_gt_rxstatus            : TBus03_SHCountMax;
signal i_hdd_sim_gt_rxelecidle          : std_logic_vector(C_HDD_COUNT_MAX-1 downto 0);
signal i_hdd_sim_gt_rxdisperr           : TBus04_SHCountMax;
signal i_hdd_sim_gt_rxnotintable        : TBus04_SHCountMax;
signal i_hdd_sim_gt_rxbyteisaligned     : std_logic_vector(C_HDD_COUNT_MAX-1 downto 0);
--signal i_hdd_sim_gt_sim_rst             : std_logic_vector(C_HDD_COUNT_MAX-1 downto 0);--
--signal i_hdd_sim_gt_sim_clk             : std_logic_vector(C_HDD_COUNT_MAX-1 downto 0);--

signal i_hdd_memin                      : TMemIN;
signal i_hdd_memout                     : TMemOUT;

signal i_dsntst_rst                     : std_logic;
signal i_dsntst_txdata_rdy              : std_logic;
signal i_dsntst_txdata_dout             : std_logic_vector(31 downto 0);
signal i_dsntst_txdata_wd               : std_logic;
signal i_dsntst_txbuf_empty             : std_logic;
signal i_dsntst_txbuf_full              : std_logic;
signal i_dsntst_bufclk                  : std_logic;
signal i_dsntst_tst_out                 : std_logic_vector(31 downto 0);


--
-- If the synthesizer replicates an asynchronous reset signal due high fanout,
-- this can prevent flip-flops being mapped into IOBs. We set the maximum
-- fanout for such nets to a high enough value that replication never occurs.
--
attribute MAX_FANOUT : string;
attribute MAX_FANOUT of i_memctrl_rst : signal is "100000";

attribute keep : string;
attribute keep of g_host_clk : signal is "true";

signal i_test01_led     : std_logic;
signal tst_clr          : std_logic;


--//MAIN
begin

--***********************************************************
--//RESET модулей
--***********************************************************
i_host_rst_n <=lreset_l;

i_gt_X0Y6_rst<=not i_host_rdy;
i_tmr_rst    <=not i_host_rst_n or i_host_rst_all;
i_cfg_rst    <=not i_host_rst_n or i_host_rst_all;
i_eth_rst    <=not i_host_rst_n or i_host_rst_all or i_host_rst_eth;
i_vctrl_rst  <=not i_host_rst_n or i_host_rst_all;
i_trc_rst    <=not i_host_rst_n or i_host_rst_all;
i_swt_rst    <=not i_host_rst_n or i_host_rst_all;
i_memctrl_rst<=not i_host_rst_n or i_host_rst_all or i_host_rst_mem;
i_dsntst_rst <=not i_host_rst_n or i_host_rst_all;
i_hdd_rst    <=not i_host_rst_n or i_host_rst_all or i_usr_rst;
i_arb_mem_rst<=i_memctrl_rst;

process(i_host_rst_n, g_refclk200MHz)
begin
  if i_host_rst_n = '0' then
    i_dcm_rst_cnt <= (others => '0');
  elsif g_refclk200MHz'event and g_refclk200MHz = '1' then
    if i_dcm_rst_cnt(i_dcm_rst_cnt'high) = '0' then
      i_dcm_rst_cnt <= i_dcm_rst_cnt + 1;
    end if;
  end if;
end process;

i_dcm_rst <= i_dcm_rst_cnt(i_dcm_rst_cnt'high - 1) or i_host_rst_all;


--***********************************************************
--Установка частот проекта:
--***********************************************************
--//Input 200MHz reference clock for IDELAY / ODELAY elements
ibufg_refclk : IBUFGDS_LVPECL_25 port map(I  => pin_in_refclk200M_p, IB => pin_in_refclk200M_n, O  => i_refclk200MHz);
bufg_refclk  : BUFG              port map(I  => i_refclk200MHz, O  => g_refclk200MHz);

--//Input 100MHz reference clock for PCI-EXPRESS
ibuf_pciexp_gt_refclk : IBUFDS port map (I=>pin_in_pciexp_clk_p, IB=> pin_in_pciexp_clk_n, O=>i_pciexp_gt_refclk );

--//Input 150MHz reference clock for SATA
gen_sata_gt : for i in 0 to C_SH_COUNT_MAX(C_PCFG_HDD_COUNT-1)-1 generate
ibufds_hdd_gt_refclk : IBUFDS port map(I  => pin_in_sata_clk_p(i), IB => pin_in_sata_clk_n(i), O  => i_hdd_gt_refclk150(i));
end generate gen_sata_gt;

--//Input 125MHz reference clock for Eth
ibufds_X0Y6_gt_refclk : IBUFDS port map(I => pin_in_gt_X0Y6_clk_p, IB => pin_in_gt_X0Y6_clk_n, O => i_gt_X0Y6_clkin);

--//Программирую ветвление опорной частоты GTP_X0Y6
--//Т.к в данном проекте опорная частота для GTP_X0Y7 будет браться не с диф. пинов pin_in_eth_clk_n/p, а
--//с линии CLKINNORTH (более подробно см. xilinx manual ug196.pdf/Appendix F)
m_gt_refclkout : gtp_prog_clkmux
generic map(
G_CLKIN_CHANGE      => '0',   --//разрешение/запрет изменения состояния мультиплексора CLKIN    - '1'/'0'
G_CLKSOUTH_CHANGE   => '0',   --//разрешение/запрет изменения состояния мультиплексора CLKSOUTH - '1'/'0'
G_CLKNORTH_CHANGE   => '1',   --//разрешение/запрет изменения состояния мультиплексора CLKNORTH - '1'/'0'

G_CLKIN_MUX_VAL     => "011", --//Значение для мультиплексора CLKIN
G_CLKSOUTH_MUX_VAL  => '1',   --//Значение для мультиплексора CLKSOUTH
G_CLKNORTH_MUX_VAL  => '1'    --//Значение для мультиплексора CLKNORTH
)
port map(
p_in_drp_rst    => i_gt_X0Y6_rst,
p_in_drp_clk    => g_pciexp_gt_refclkout,

p_out_txp       => pin_out_gt_X0Y6_txp,
p_out_txn       => pin_out_gt_X0Y6_txn,
p_in_rxp        => pin_in_gt_X0Y6_rxp,
p_in_rxn        => pin_in_gt_X0Y6_rxn,

p_in_clkin      => i_gt_X0Y6_clkin,
p_out_refclkout => open
);

--//Input 125MHz reference clock for GTP_X0Y7 Eth_MAC0
--//В данном проекте опорная частота для GTP_X0Y7 будет браться не с диф. пинов pin_in_eth_clk_n/p, а
--//с линии CLKINNORTH (более подробно см. xilinx manual ug196.pdf/Appendix F)
ibufds_gt_eth_refclk : IBUFDS port map(I  => pin_in_ethphy.clk_p, IB => pin_in_ethphy.clk_n, O  => i_eth_gt_refclk125);

--//DCM Local Bus
m_dcm_lbus : lbus_dcm
generic map(
G_CLKFX_DIV  => 1,
G_CLKFX_MULT => C_PCFG_LBUSDCM_CLKFX_M
)
port map(
p_out_gclkin => g_lbus_clkin,
p_out_clk0   => g_lbus_clk,
p_out_clkfx  => g_lbus_clkfx,
--p_out_clkdiv => g_lbus_clkdiv,
--p_out_clk2x  => g_lbus_clk2x,
p_out_locked => lclk_dcm_lock,

p_in_clk     => lclk,
p_in_rst     => i_dcm_rst
);

--//PLL контроллера памяти
m_pll_mem_ctrl : mem_pll
port map(
mclk      => g_refclk200MHz,
rst       => i_memctrl_rst,
refclk200 => g_refclk200MHz,

clk0      => i_memctrl_pllclk0,
clk45     => i_memctrl_pllclk45,
clk2x0    => i_memctrl_pllclk2x0,
clk2x90   => i_memctrl_pllclk2x90,
locked    => i_memctrl_locked(1 downto 0),
memrst    => i_memctrl_pll_rst_out
);

g_usr_highclk<=i_memctrl_pllclk2x0;
i_tmr_clk<=g_pciexp_gt_refclkout;


--***********************************************************
--Модуль конфигурирования устр-в
--***********************************************************
m_cfgu : cfgdev_uart
generic map(
G_BAUDCNT_VAL => 54 --108       --//G_BAUDCNT_VAL = Fuart_refclk/(16 * UART_BAUDRATE)
                           --//Например: Fuart_refclk=40MHz, UART_BAUDRATE=115200
                           --//
                           --// 40000000/(16 *115200)=21,701 - округляем до ближайшего цеого, т.е = 22
)
port map(
-------------------------------
--Связь с UART
-------------------------------
p_out_uart_tx        => pin_out_uart0_tx,
p_in_uart_rx         => pin_in_uart0_rx,
p_in_uart_refclk     => g_lbus_clk,--g_refclk200MHz,

-------------------------------
--
-------------------------------
p_out_module_rdy     => open,
p_out_module_error   => open,

-------------------------------
--Запись/Чтение конфигурационных параметров уст-ва
-------------------------------
p_out_cfg_dadr       => i_cfgu_dadr,
p_out_cfg_radr       => i_cfgu_radr,
p_out_cfg_radr_ld    => i_cfgu_radr_ld,
p_out_cfg_radr_fifo  => i_cfgu_radr_fifo,
p_out_cfg_wr         => i_cfgu_wr,
p_out_cfg_rd         => i_cfgu_rd,
p_out_cfg_txdata     => i_cfgu_txdata,
p_in_cfg_rxdata      => i_cfgu_rxdata,
p_in_cfg_txrdy       => i_cfghdd_txrdy,
p_in_cfg_rxrdy       => i_cfghdd_rxrdy,

p_out_cfg_done       => i_cfgu_done,
p_in_cfg_clk         => g_host_clk,

-------------------------------
--Технологический
-------------------------------
p_in_tst             => "00000000000000000000000000000000",
p_out_tst            => open,--i_cfgdev_tst_out,--

-------------------------------
--System
-------------------------------
p_in_rst => i_cfg_rst
);


m_cfg : cfgdev_host
port map(
-------------------------------
--Связь с Хостом
-------------------------------
p_out_host_rxrdy     => i_host_rxrdy(C_HDEV_CFG_DBUF),
p_out_host_rxd       => i_host_rxd(C_HDEV_CFG_DBUF),
p_in_host_rd         => i_host_rd(C_HDEV_CFG_DBUF),

p_out_host_txrdy     => i_host_txrdy(C_HDEV_CFG_DBUF),
p_in_host_txd        => i_host_txd(C_HDEV_CFG_DBUF),
p_in_host_wr         => i_host_wr(C_HDEV_CFG_DBUF),

p_out_host_irq       => i_host_irq(C_HIRQ_CFG_RX),
p_in_host_clk        => g_host_clk,

-------------------------------
--
-------------------------------
p_out_module_rdy     => i_cfg_rdy,
p_out_module_error   => open,

-------------------------------
--Запись/Чтение конфигурационных параметров уст-ва
-------------------------------
p_out_cfg_dadr       => i_cfg_dadr,
p_out_cfg_radr       => i_cfg_radr,
p_out_cfg_radr_ld    => i_cfg_radr_ld,
p_out_cfg_radr_fifo  => i_cfg_radr_fifo,
p_out_cfg_wr         => i_cfg_wr,
p_out_cfg_rd         => i_cfg_rd,
p_out_cfg_txdata     => i_cfg_txd,
p_in_cfg_rxdata      => i_cfg_rxd,
p_in_cfg_txrdy       => '1',
p_in_cfg_rxrdy       => '1',

p_out_cfg_done       => i_cfg_done,
p_in_cfg_clk         => g_host_clk,

-------------------------------
--Технологический
-------------------------------
p_in_tst             => (others=>'0'),
p_out_tst            => open,--i_cfg_tst_out,

-------------------------------
--System
-------------------------------
p_in_rst => i_cfg_rst
);

--//Распределяем управление от блока конфигурирования(cfgdev.vhd):
i_cfg_rxd<=i_cfg_rxd_dev(C_CFGDEV_ETH)     when i_cfg_dadr(3 downto 0)=CONV_STD_LOGIC_VECTOR(C_CFGDEV_ETH, 4)     else
           i_cfg_rxd_dev(C_CFGDEV_VCTRL)   when i_cfg_dadr(3 downto 0)=CONV_STD_LOGIC_VECTOR(C_CFGDEV_VCTRL, 4)   else
           i_cfg_rxd_dev(C_CFGDEV_SWT)     when i_cfg_dadr(3 downto 0)=CONV_STD_LOGIC_VECTOR(C_CFGDEV_SWT, 4)     else
           i_cfg_rxd_dev(C_CFGDEV_TMR)     when i_cfg_dadr(3 downto 0)=CONV_STD_LOGIC_VECTOR(C_CFGDEV_TMR, 4)     else
           i_cfg_rxd_dev(C_CFGDEV_HDD)     when i_cfg_dadr(3 downto 0)=CONV_STD_LOGIC_VECTOR(C_CFGDEV_HDD, 4)     else
           i_cfg_rxd_dev(C_CFGDEV_TESTING) when i_cfg_dadr(3 downto 0)=CONV_STD_LOGIC_VECTOR(C_CFGDEV_TESTING, 4) else
           i_cfg_rxd_dev(C_CFGDEV_TRCNIK)  when i_cfg_dadr(3 downto 0)=CONV_STD_LOGIC_VECTOR(C_CFGDEV_TRCNIK, 4)  else
           (others=>'0');

gen_cfg_dev : for i in 0 to C_CFGDEV_COUNT-1 generate
i_cfg_wr_dev(i)   <=i_cfg_wr   when i_cfg_dadr=i else '0';
i_cfg_rd_dev(i)   <=i_cfg_rd   when i_cfg_dadr=i else '0';
i_cfg_done_dev(i) <=i_cfg_done when i_cfg_dadr=i else '0';
end generate gen_cfg_dev;


--***********************************************************
--Проект модуля Таймер
--***********************************************************
m_tmr : dsn_timer
port map(
-------------------------------
-- Конфигурирование модуля dsn_timer.vhd (host_clk domain)
-------------------------------
p_in_host_clk     => g_host_clk,

p_in_cfg_adr      => i_cfg_radr(7 downto 0),
p_in_cfg_adr_ld   => i_cfg_radr_ld,
p_in_cfg_adr_fifo => i_cfg_radr_fifo,

p_in_cfg_txdata   => i_cfg_txd,
p_in_cfg_wd       => i_cfg_wr_dev(C_CFGDEV_TMR),

p_out_cfg_rxdata  => i_cfg_rxd_dev(C_CFGDEV_TMR),
p_in_cfg_rd       => i_cfg_rd_dev(C_CFGDEV_TMR),

p_in_cfg_done     => i_cfg_wr_dev(C_CFGDEV_TMR),

-------------------------------
-- STATUS модуля dsn_timer.vhd
-------------------------------
p_in_tmr_clk      => i_tmr_clk,
p_out_tmr_rdy     => open,
p_out_tmr_error   => open,

p_out_tmr_irq     => i_tmr_hirq,

-------------------------------
--System
-------------------------------
p_in_rst => i_tmr_rst
);

--***********************************************************
--Проект модуля Комутатор
--***********************************************************
m_swt : dsn_switch
port map(
-------------------------------
-- Конфигурирование модуля dsn_switch.vhd (p_in_cfg_clk domain)
-------------------------------
p_in_cfg_clk              => g_host_clk,

p_in_cfg_adr              => i_cfg_radr(7 downto 0),
p_in_cfg_adr_ld           => i_cfg_radr_ld,
p_in_cfg_adr_fifo         => i_cfg_radr_fifo,

p_in_cfg_txdata           => i_cfg_txd,
p_in_cfg_wd               => i_cfg_wr_dev(C_CFGDEV_SWT),

p_out_cfg_rxdata          => i_cfg_rxd_dev(C_CFGDEV_SWT),
p_in_cfg_rd               => i_cfg_rd_dev(C_CFGDEV_SWT),

p_in_cfg_done             => i_cfg_done_dev(C_CFGDEV_SWT),

-------------------------------
-- Связь с Хостом (host_clk domain)
-------------------------------
p_in_host_clk             => g_host_clk,

-- Связь Хост <-> ETH(dsn_eth.vhd)
p_out_host_eth_rxd_irq    => i_host_irq(C_HIRQ_ETH_RX),
p_out_host_eth_rxd_rdy    => i_host_rxrdy(C_HDEV_ETH_DBUF),
p_out_host_eth_rxd        => i_host_rxd(C_HDEV_ETH_DBUF),
p_in_host_eth_rd          => i_host_rd(C_HDEV_ETH_DBUF),

p_out_host_eth_txbuf_rdy  => i_host_txrdy(C_HDEV_ETH_DBUF),
p_in_host_eth_txd         => i_host_txd(C_HDEV_ETH_DBUF),
p_in_host_eth_wr          => i_host_wr(C_HDEV_ETH_DBUF),

-- Связь Хост <-> VideoBUF
p_out_host_vbuf_dout      => i_host_rxd(C_HDEV_VCH_DBUF),
p_in_host_vbuf_rd         => i_host_rd(C_HDEV_VCH_DBUF),
p_out_host_vbuf_empty     => i_host_rxbuf_empty(C_HDEV_VCH_DBUF),


-------------------------------
-- Связь с HDD(dsn_hdd.vhd)
-------------------------------
p_in_hdd_tstgen           => i_swt_hdd_tstgen_cfg,
p_in_hdd_vbuf_rdclk       => g_usr_highclk,

p_out_hdd_vbuf_dout       => i_hdd_vbuf_dout,  --open, --
p_in_hdd_vbuf_rd          => i_hdd_vbuf_rd,    --'0',  --
p_out_hdd_vbuf_empty      => i_hdd_vbuf_empty, --open, --
p_out_hdd_vbuf_full       => i_hdd_vbuf_full,  --open, --
p_out_hdd_vbuf_pfull      => i_hdd_vbuf_pfull, --open, --
p_out_hdd_vbuf_wrcnt      => i_hdd_vbuf_wrcnt, --open, --

-------------------------------
-- Связь с Eth(dsn_eth.vhd) (ethg_clk domain)
-------------------------------
p_in_eth_clk              => i_ethphy_out.clk,   --g_eth_gt_refclkout,

p_in_eth_rxd_sof          => i_eth_out(0).rxbuf.sof, --i_eth_rxd_sof,
p_in_eth_rxd_eof          => i_eth_out(0).rxbuf.eof, --i_eth_rxd_eof,
p_in_eth_rxbuf_din        => i_eth_out(0).rxbuf.din, --i_eth_rxbuf_din,
p_in_eth_rxbuf_wr         => i_eth_out(0).rxbuf.wr,  --i_eth_rxbuf_wr,
p_out_eth_rxbuf_empty     => i_eth_in(0).rxbuf.empty,--i_host_rxbuf_empty(C_HDEV_ETH_DBUF),
p_out_eth_rxbuf_full      => i_eth_in(0).rxbuf.full, --i_eth_rxbuf_full,

p_out_eth_txbuf_dout      => i_eth_in(0).txbuf.dout, --i_eth_txbuf_dout,
p_in_eth_txbuf_rd         => i_eth_out(0).txbuf.rd,  --i_eth_txbuf_rd,
p_out_eth_txbuf_empty     => i_eth_in(0).txbuf.empty,--i_eth_txbuf_empty,
p_out_eth_txbuf_full      => i_eth_in(0).txbuf.full, --i_host_txbuf_full(C_HDEV_ETH_DBUF),


-------------------------------
-- Связь с VCTRL(dsn_video_ctrl.vhd) (vctrl_clk domain)
-------------------------------
p_in_vctrl_clk            => g_vctrl_swt_bufclk,

p_out_vctrl_vbufin_rdy    => i_vctrl_vbufin_rdy,
p_out_vctrl_vbufin_dout   => i_vctrl_vbufin_dout,
p_in_vctrl_vbufin_rd      => i_vctrl_vbufin_rd,
p_out_vctrl_vbufin_empty  => i_vctrl_vbufin_empty,
p_out_vctrl_vbufin_full   => i_vctrl_vbufin_full,
p_out_vctrl_vbufin_pfull  => i_vctrl_vbufin_pfull,

p_in_vctrl_vbufout_din    => i_vctrl_vbufout_din,
p_in_vctrl_vbufout_wr     => i_vctrl_vbufout_wd,
p_out_vctrl_vbufout_empty => i_vctrl_vbufout_empty,
p_out_vctrl_vbufout_full  => i_vctrl_vbufout_full,


-------------------------------
-- Связь с Модулем Тестирования(dsn_testing.vhd)
-------------------------------
p_out_dsntst_bufclk       => i_dsntst_bufclk,      --open,         --
                                                   --
p_in_dsntst_txd_rdy       => i_dsntst_txdata_rdy,  --'0',          --
p_in_dsntst_txbuf_din     => i_dsntst_txdata_dout, --(others=>'0'),--
p_in_dsntst_txbuf_wr      => i_dsntst_txdata_wd,   --'0',          --
p_out_dsntst_txbuf_empty  => i_dsntst_txbuf_empty, --open,         --
p_out_dsntst_txbuf_full   => i_dsntst_txbuf_full,  --open,         --


-------------------------------
--Технологический
-------------------------------
p_in_tst                  => (others=>'0'),
p_out_tst                 => i_swt_tst_out,

-------------------------------
--System
-------------------------------
p_in_rst => i_swt_rst
);

--***********************************************************
--Проект Ethernet - dsn_eth.vhd
--***********************************************************
pin_out_ethphy<=i_ethphy_out.pin.fiber;
i_ethphy_in.pin.fiber<=pin_in_ethphy;

i_ethphy_in.clk<=i_eth_gt_refclk125;

pin_out_sfp_tx_dis<='0';
i_ethphy_in.opt(C_ETHPHY_OPTIN_REFCLK_IODELAY_BIT)<=i_refclk200MHz;
i_ethphy_in.opt(C_ETHPHY_OPTIN_SFP_SD_BIT)<=pin_in_sfp_sd;
----//Значение для перепрограм. мультиплексора CLKIN RocketIO ETH
--i_ethphy_in.opt(C_ETHPHY_OPTIN_V5GT_CLKIN_MUX_M_BIT downto C_ETHPHY_OPTIN_V5GT_CLKIN_MUX_L_BIT) <=CONV_STD_LOGIC_VECTOR(16#07#, C_ETHPHY_OPTIN_V5GT_CLKIN_MUX_M_BIT-C_ETHPHY_OPTIN_V5GT_CLKIN_MUX_L_BIT+1);
----//Значение для перепрограм. мультиплексора CLKSOUTH RocketIO ETH
--i_ethphy_in.opt(C_ETHPHY_OPTIN_V5GT_SOUTH_MUX_VAL_M_BIT downto C_ETHPHY_OPTIN_V5GT_SOUTH_MUX_VAL_L_BIT)<=CONV_STD_LOGIC_VECTOR(16#00#, C_ETHPHY_OPTIN_V5GT_SOUTH_MUX_VAL_M_BIT-C_ETHPHY_OPTIN_V5GT_SOUTH_MUX_VAL_L_BIT+1);
--i_ethphy_in.opt(C_ETHPHY_OPTIN_V5GT_CLKIN_MUX_CNG_BIT)<='1';  --//1- перепрограммирование мультиплексора CLKIN RocketIO ETH
--i_ethphy_in.opt(C_ETHPHY_OPTIN_V5GT_SOUTH_MUX_CNG_BIT)<='0';  --//1- перепрограммирование мультиплексора CLKSOUTH RocketIO ETH
--i_ethphy_in.opt(C_ETHPHY_OPTIN_V5GT_NORTH_MUX_CNG_BIT)<='0';  --//1- перепрограммирование мультиплексора CLKNORTH RocketIO ETH
--i_ethphy_in.opt(C_ETHPHY_OPTIN_DRPCLK_BIT)            <=p_in_ethphy.opt(0);

m_eth : dsn_eth
generic map(
G_ETH.gtch_count_max  => C_PCFG_ETH_GTCH_COUNT_MAX,
G_ETH.usrbuf_dwidth   => 32,
G_ETH.phy_dwidth      => 8,
G_ETH.phy_select      => C_ETH_PHY_FIBER,
G_ETH.mac_length_swap => 1, --1/0 Поле Length/Type первый мл./ст. байт (0 - по стандарту!!! 1 - как в проекте Вереск)
G_MODULE_USE => C_PCFG_ETH_USE,
G_DBG        => C_PCFG_ETH_DBG,
G_SIM        => G_SIM
)
port map(
-------------------------------
-- Конфигурирование модуля dsn_eth.vhd (host_clk domain)
-------------------------------
p_in_cfg_clk          => g_host_clk,

p_in_cfg_adr          => i_cfg_radr(7 downto 0),
p_in_cfg_adr_ld       => i_cfg_radr_ld,
p_in_cfg_adr_fifo     => i_cfg_radr_fifo,

p_in_cfg_txdata       => i_cfg_txd,
p_in_cfg_wd           => i_cfg_wr_dev(C_CFGDEV_ETH),

p_out_cfg_rxdata      => i_cfg_rxd_dev(C_CFGDEV_ETH),
p_in_cfg_rd           => i_cfg_rd_dev(C_CFGDEV_ETH),

p_in_cfg_done         => i_cfg_done_dev(C_CFGDEV_ETH),
p_in_cfg_rst          => i_cfg_rst,

-------------------------------
-- Связь с буферами модуля dsn_switch.vhd
-------------------------------
p_out_eth             => i_eth_out,
p_in_eth              => i_eth_in,

--------------------------------------------------
--ETH Driver
--------------------------------------------------
p_out_ethphy          => i_ethphy_out,
p_in_ethphy           => i_ethphy_in,

-------------------------------
--Технологический
-------------------------------
p_out_dbg             => open,
p_in_tst              => i_eth_tst_out,
p_out_tst             => open,

-------------------------------
--System
-------------------------------
p_in_rst              => i_eth_rst
);


--***********************************************************
--Проект модуля видео контролера - dsn_video_ctrl.vhd
--***********************************************************
i_vctrl_hirq_out<=EXT(i_vctrl_hirq, i_vctrl_hirq_out'length);
i_vctrl_hrdy_out<=EXT(i_vctrl_hrdy, i_vctrl_hrdy_out'length);

m_vctrl : dsn_video_ctrl
generic map(
G_SIMPLE => C_PCFG_VCTRL_SIMPLE,
G_SIM    => G_SIM,

G_MEM_AWIDTH => C_HREG_MEM_ADR_LAST_BIT,
G_MEM_DWIDTH => C_HDEV_DWIDTH
)
port map(
-------------------------------
-- Конфигурирование модуля dsn_video_ctrl.vhd (host_clk domain)
-------------------------------
p_in_host_clk        => g_host_clk,

p_in_cfg_adr         => i_cfg_radr(7 downto 0),
p_in_cfg_adr_ld      => i_cfg_radr_ld,
p_in_cfg_adr_fifo    => i_cfg_radr_fifo,

p_in_cfg_txdata      => i_cfg_txd,
p_in_cfg_wd          => i_cfg_wr_dev(C_CFGDEV_VCTRL),

p_out_cfg_rxdata     => i_cfg_rxd_dev(C_CFGDEV_VCTRL),
p_in_cfg_rd          => i_cfg_rd_dev(C_CFGDEV_VCTRL),

p_in_cfg_done        => i_cfg_done_dev(C_CFGDEV_VCTRL),

-------------------------------
-- Связь с ХОСТ
-------------------------------
p_in_vctrl_hrdchsel  => i_host_vchsel,
p_in_vctrl_hrdstart  => i_vctrl_hrd_start,
p_in_vctrl_hrddone   => i_vctrl_hrd_done,
p_out_vctrl_hirq     => i_vctrl_hirq,
p_out_vctrl_hdrdy    => i_vctrl_hrdy,
p_out_vctrl_hfrmrk   => i_vctrl_hfrmrk,

-------------------------------
-- STATUS модуля dsn_video_ctrl.vhd
-------------------------------
p_out_vctrl_modrdy   => open,--i_vctrl_module_rdy,
p_out_vctrl_moderr   => open,--i_vctrl_module_error,
p_out_vctrl_rd_done  => i_vctrl_vrd_done,

p_out_vctrl_vrdprm   => i_vctrl_vrdprms,
p_out_vctrl_vfrrdy   => i_vctrl_vfrdy,
p_out_vctrl_vrowmrk  => i_vctrl_vrowmrk,

-------------------------------
-- Связь с модулем слежения
-------------------------------
p_in_trc_busy        => i_trc_busy,
p_out_trc_vbuf       => i_trc_vbufs,

-------------------------------
-- Связь с буферами модуля dsn_switch.vhd
-------------------------------
p_out_vbuf_clk       => g_vctrl_swt_bufclk,

p_in_vbufin_rdy      => i_vctrl_vbufin_rdy,
p_in_vbufin_dout     => i_vctrl_vbufin_dout,
p_out_vbufin_dout_rd => i_vctrl_vbufin_rd,
p_in_vbufin_empty    => i_vctrl_vbufin_empty,
p_in_vbufin_full     => i_vctrl_vbufin_full,
p_in_vbufin_pfull    => i_vctrl_vbufin_pfull,

p_out_vbufout_din    => i_vctrl_vbufout_din,
p_out_vbufout_din_wd => i_vctrl_vbufout_wd,
p_in_vbufout_empty   => i_vctrl_vbufout_empty,
p_in_vbufout_full    => i_vctrl_vbufout_full,

---------------------------------
-- Связь с mem_ctrl.vhd
---------------------------------
--//CH WRITE
p_out_memwr          => i_vctrlwr_memin,
p_in_memwr           => i_vctrlwr_memout,
--//CH READ
p_out_memrd          => i_vctrlrd_memin,
p_in_memrd           => i_vctrlrd_memout,

-------------------------------
--Технологический
-------------------------------
p_out_tst            => i_vctrl_tst_out,

-------------------------------
--System
-------------------------------
p_in_clk => g_usr_highclk,
p_in_rst => i_vctrl_rst
);


--***********************************************************
--Проект Модуля Слежения - dsn_track.vhd
--***********************************************************
m_track : dsn_track_nik
generic map(
G_SIM             => G_SIM,
G_MODULE_USE      => C_PCFG_TRC_USE,

G_MEM_BANK_M_BIT  => C_VCTRL_REG_MEM_ADR_BANK_M_BIT,
G_MEM_BANK_L_BIT  => C_VCTRL_REG_MEM_ADR_BANK_L_BIT,

G_MEM_VCH_M_BIT   => C_VCTRL_MEM_VCH_M_BIT,
G_MEM_VCH_L_BIT   => C_VCTRL_MEM_VCH_L_BIT,
G_MEM_VFR_M_BIT   => C_VCTRL_MEM_VFR_M_BIT,
G_MEM_VFR_L_BIT   => C_VCTRL_MEM_VFR_L_BIT,
G_MEM_VLINE_M_BIT => C_VCTRL_MEM_VLINE_M_BIT,
G_MEM_VLINE_L_BIT => C_VCTRL_MEM_VLINE_L_BIT,

G_MEM_AWIDTH      => C_HREG_MEM_ADR_LAST_BIT,
G_MEM_DWIDTH      => C_HDEV_DWIDTH
)
port map(
-------------------------------
-- Управление от Хоста
-------------------------------
p_in_host_clk        => g_host_clk,

p_in_cfg_adr         => i_cfg_radr(7 downto 0),
p_in_cfg_adr_ld      => i_cfg_radr_ld,
p_in_cfg_adr_fifo    => i_cfg_radr_fifo,

p_in_cfg_txdata      => i_cfg_txd,
p_in_cfg_wd          => i_cfg_wr_dev(C_CFGDEV_TRCNIK),

p_out_cfg_rxdata     => i_cfg_rxd_dev(C_CFGDEV_TRCNIK),
p_in_cfg_rd          => i_cfg_rd_dev(C_CFGDEV_TRCNIK),

p_in_cfg_done        => i_cfg_done_dev(C_CFGDEV_TRCNIK),

-------------------------------
-- Связь с ХОСТ
-------------------------------
p_out_trc_hirq       => i_host_irq(C_HIRQ_TRCNIK),
p_out_trc_hdrdy      => i_trcnik_hdrdy,
p_out_trc_hfrmrk     => i_trcnik_hfrmrk,
p_in_trc_hrddone     => i_trcnik_hrd_done,

p_out_trc_bufo_dout  => open,
p_in_trc_bufo_rd     => '0',
p_out_trc_bufo_empty => open,

p_out_trc_busy       => i_trc_busy,

-------------------------------
-- Связь с VCTRL
-------------------------------
p_in_vctrl_vrdprms   => i_vctrl_vrdprms,
p_in_vctrl_vfrrdy    => i_vctrl_vfrdy,
p_in_vctrl_vbuf      => i_trc_vbufs,
p_in_vctrl_vrowmrk   => i_vctrl_vrowmrk,

---------------------------------
-- Связь с mem_ctrl.vhd
---------------------------------
p_out_mem            => i_trc_memin,
p_in_mem             => i_trc_memout,

-------------------------------
--Технологический
-------------------------------
p_in_tst             => (others=>'0'),
p_out_tst            => i_trc_tst_out,

-------------------------------
--System
-------------------------------
p_in_clk => g_usr_highclk,
p_in_rst => i_trc_rst
);


--***********************************************************
--Проект Накопителя - dsn_hdd.vhd
--***********************************************************
i_cfghdd_selif<=i_hdd_rbuf_cfg.usrif;

i_cfghdd_radr(7 downto 0)<=i_cfg_radr(7 downto 0)when i_cfghdd_selif=C_HDD_CFGIF_PCIEXP else i_cfgu_radr(7 downto 0);
i_cfghdd_radr_ld  <=i_cfg_radr_ld                when i_cfghdd_selif=C_HDD_CFGIF_PCIEXP else i_cfgu_radr_ld;
i_cfghdd_radr_fifo<=i_cfg_radr_fifo              when i_cfghdd_selif=C_HDD_CFGIF_PCIEXP else i_cfgu_radr_fifo;

i_cfghdd_txdata   <=i_cfg_txd                    when i_cfghdd_selif=C_HDD_CFGIF_PCIEXP else i_cfgu_txdata;
i_cfghdd_wr       <=i_cfg_wr_dev(C_CFGDEV_HDD)   when i_cfghdd_selif=C_HDD_CFGIF_PCIEXP else i_cfgu_wr;

i_cfg_rxd_dev(C_CFGDEV_HDD) <=i_cfghdd_rxdata;
i_cfghdd_rd       <=i_cfg_rd_dev(C_CFGDEV_HDD)   when i_cfghdd_selif=C_HDD_CFGIF_PCIEXP else i_cfgu_rd;

i_cfghdd_done     <=i_cfg_done_dev(C_CFGDEV_HDD) when i_cfghdd_selif=C_HDD_CFGIF_PCIEXP else i_cfgu_done;

i_swt_hdd_tstgen_cfg<=i_hdd_rbuf_cfg.tstgen;

m_hdd : dsn_hdd
generic map(
G_MODULE_USE=> C_PCFG_HDD_USE,
G_HDD_COUNT => C_PCFG_HDD_COUNT,
G_GT_DBUS   => C_PCFG_HDD_GT_DBUS,
G_DBG       => C_PCFG_HDD_DBG,
G_DBGCS     => C_PCFG_HDD_DBGCS,
G_SIM       => G_SIM
)
port map(
-------------------------------
-- Конфигурирование модуля dsn_hdd.vhd (p_in_cfg_clk domain)
-------------------------------
p_in_cfg_if           => C_HDD_CFGIF_PCIEXP,
p_in_cfg_clk          => g_host_clk,

p_in_cfg_adr          => i_cfghdd_radr(7 downto 0),--i_cfg_radr(7 downto 0),
p_in_cfg_adr_ld       => i_cfghdd_radr_ld,         --i_cfg_radr_ld,
p_in_cfg_adr_fifo     => i_cfghdd_radr_fifo,       --i_cfg_radr_fifo,

p_in_cfg_txdata       => i_cfghdd_txdata,          --i_cfg_txd,
p_in_cfg_wd           => i_cfghdd_wr,              --i_cfg_wr_dev(C_CFGDEV_HDD),

p_out_cfg_rxdata      => i_cfghdd_rxdata,          --i_cfg_rxd_dev(C_CFGDEV_HDD),
p_in_cfg_rd           => i_cfghdd_rd,              --i_cfg_rd_dev(C_CFGDEV_HDD),

p_in_cfg_done         => i_cfghdd_done,            --i_cfg_done_dev(C_CFGDEV_HDD),
p_in_cfg_rst          => i_cfg_rst,                --i_cfg_rst,

-------------------------------
-- STATUS модуля dsn_hdd.vhd
-------------------------------
p_out_hdd_rdy         => i_hdd_module_rdy,
p_out_hdd_error       => i_hdd_module_error,
p_out_hdd_busy        => i_hdd_busy,
p_out_hdd_irq         => open,--i_hdd_hirq,
p_out_hdd_done        => i_hdd_done,

-------------------------------
-- Связь с Источниками/Приемниками данных накопителя
-------------------------------
p_out_rbuf_cfg        => i_hdd_rbuf_cfg,
p_in_rbuf_status      => i_hdd_rbuf_status,

p_in_hdd_txd          => i_hdd_txdata,
p_in_hdd_txd_wr       => i_hdd_txdata_wd,
p_out_hdd_txbuf_pfull => i_hdd_txbuf_pfull,
p_out_hdd_txbuf_full  => i_hdd_txbuf_full,
p_out_hdd_txbuf_empty => i_hdd_txbuf_empty,

p_out_hdd_rxd         => i_hdd_rxdata,
p_in_hdd_rxd_rd       => i_hdd_rxdata_rd,
p_out_hdd_rxbuf_empty => i_hdd_rxbuf_empty,
p_out_hdd_rxbuf_pempty=> i_hdd_rxbuf_pempty,

--------------------------------------------------
--Sata Driver
--------------------------------------------------
p_out_sata_txn        => pin_out_sata_txn,
p_out_sata_txp        => pin_out_sata_txp,
p_in_sata_rxn         => pin_in_sata_rxn,
p_in_sata_rxp         => pin_in_sata_rxp,

p_in_sata_refclk      => i_hdd_gt_refclk150,
p_out_sata_refclkout  => g_hdd_gt_refclkout,
p_out_sata_gt_plldet  => i_hdd_gt_plldet,
p_out_sata_dcm_lock   => i_hdd_dcm_lock,

---------------------------------------------------------------------------
--Технологический порт
---------------------------------------------------------------------------
p_in_tst              => i_hdd_tst_in,
p_out_tst             => i_hdd_tst_out,

--------------------------------------------------
--//Debug/Sim
--------------------------------------------------
p_out_dbgcs                 => i_hdd_dbgcs,
p_out_dbgled                => i_hdd_dbgled,

p_out_sim_gt_txdata         => open,--i_hdd_sim_gt_txdata,    --
p_out_sim_gt_txcharisk      => open,--i_hdd_sim_gt_txcharisk, --
p_out_sim_gt_txcomstart     => open,--i_hdd_sim_gt_txcomstart,--
p_in_sim_gt_rxdata          => i_hdd_sim_gt_rxdata,
p_in_sim_gt_rxcharisk       => i_hdd_sim_gt_rxcharisk,
p_in_sim_gt_rxstatus        => i_hdd_sim_gt_rxstatus,
p_in_sim_gt_rxelecidle      => i_hdd_sim_gt_rxelecidle,
p_in_sim_gt_rxdisperr       => i_hdd_sim_gt_rxdisperr,
p_in_sim_gt_rxnotintable    => i_hdd_sim_gt_rxnotintable,
p_in_sim_gt_rxbyteisaligned => i_hdd_sim_gt_rxbyteisaligned,
p_out_gt_sim_rst            => open,--i_hdd_sim_gt_sim_rst,--
p_out_gt_sim_clk            => open,--i_hdd_sim_gt_sim_clk,--

--------------------------------------------------
--System
--------------------------------------------------
p_in_clk           => g_usr_highclk,
p_in_rst           => i_hdd_rst
);

gen_satah: for i in 0 to C_HDD_COUNT_MAX-1 generate
i_hdd_sim_gt_rxdata(i)<=(others=>'0');
i_hdd_sim_gt_rxcharisk(i)<=(others=>'0');
i_hdd_sim_gt_rxstatus(i)<=(others=>'0');
i_hdd_sim_gt_rxelecidle(i)<='0';
i_hdd_sim_gt_rxdisperr(i)<=(others=>'0');
i_hdd_sim_gt_rxnotintable(i)<=(others=>'0');
i_hdd_sim_gt_rxbyteisaligned(i)<='0';
end generate gen_satah;

m_hdd_rambuf : dsn_hdd_rambuf
generic map(
G_MODULE_USE  => C_PCFG_HDD_USE,
G_RAMBUF_SIZE => C_PCFG_HDD_RAMBUF_SIZE,
G_DBGCS       => C_PCFG_HDD_DBGCS,
G_SIM         => G_SIM,

G_MEM_AWIDTH  => C_HREG_MEM_ADR_LAST_BIT,
G_MEM_DWIDTH  => C_HDEV_DWIDTH
)
port map(
-------------------------------
-- Конфигурирование
-------------------------------
p_in_rbuf_cfg       => i_hdd_rbuf_cfg,
p_out_rbuf_status   => i_hdd_rbuf_status,

--//--------------------------
--//Upstream Port(Связь с буфером источника данных)
--//--------------------------
p_in_vbuf_dout      => i_hdd_vbuf_dout,
p_out_vbuf_rd       => i_hdd_vbuf_rd,
p_in_vbuf_empty     => i_hdd_vbuf_empty,
p_in_vbuf_full      => i_hdd_vbuf_full,
p_in_vbuf_pfull     => i_hdd_vbuf_pfull,
p_in_vbuf_wrcnt     => i_hdd_vbuf_wrcnt,

--//--------------------------
--//Связь с модулем HDD
--//--------------------------
p_out_hdd_txd        => i_hdd_txdata,
p_out_hdd_txd_wr     => i_hdd_txdata_wd,
p_in_hdd_txbuf_pfull => i_hdd_txbuf_pfull,
p_in_hdd_txbuf_full  => i_hdd_txbuf_full,
p_in_hdd_txbuf_empty => i_hdd_txbuf_empty,

p_in_hdd_rxd         => i_hdd_rxdata,
p_out_hdd_rxd_rd     => i_hdd_rxdata_rd,
p_in_hdd_rxbuf_empty => i_hdd_rxbuf_empty,
p_in_hdd_rxbuf_pempty=> i_hdd_rxbuf_pempty,

---------------------------------
-- Связь с mem_ctrl.vhd
---------------------------------
p_out_mem            => i_hdd_memin,
p_in_mem             => i_hdd_memout,

-------------------------------
--Технологический
-------------------------------
p_in_tst            => (others=>'0'),
p_out_tst           => i_hdd_rbuf_tst_out,
p_out_dbgcs         => i_hdd_rambuf_dbgcs,

-------------------------------
--System
-------------------------------
p_in_clk => g_usr_highclk,
p_in_rst => i_hdd_rst
);


--***********************************************************
--Проект модуля Тестирования - Имитация Видео данных
--***********************************************************
m_testing : vtester_v01
generic map(
G_SIM   => G_SIM
)
port map(
-------------------------------
-- Управление от Хоста
-------------------------------
p_in_host_clk         => g_host_clk,

p_in_cfg_adr          => i_cfg_radr(7 downto 0),
p_in_cfg_adr_ld       => i_cfg_radr_ld,
p_in_cfg_adr_fifo     => i_cfg_radr_fifo,

p_in_cfg_txdata       => i_cfg_txd,
p_in_cfg_wd           => i_cfg_wr_dev(C_CFGDEV_TESTING),

p_out_cfg_rxdata      => i_cfg_rxd_dev(C_CFGDEV_TESTING),
p_in_cfg_rd           => i_cfg_rd_dev(C_CFGDEV_TESTING),

p_in_cfg_done         => i_cfg_done_dev(C_CFGDEV_TESTING),

-------------------------------
-- STATUS модуля dsn_testing.VHD
-------------------------------
p_out_module_rdy      => open,
p_out_module_error    => open,

-------------------------------
--Связь с выходным буфером
-------------------------------
p_out_dst_dout_rdy    => i_dsntst_txdata_rdy,
p_out_dst_dout        => i_dsntst_txdata_dout,
p_out_dst_dout_wd     => i_dsntst_txdata_wd,
p_in_dst_rdy          => i_dsntst_txbuf_empty,
--p_in_dst_clk          => i_dsntst_bufclk,

-------------------------------
--Технологический
-------------------------------
p_out_tst             => i_dsntst_tst_out,

-------------------------------
--System
-------------------------------
p_in_tmrclk => g_pciexp_gt_refclkout,

p_in_clk    => i_dsntst_bufclk,
p_in_rst    => i_dsntst_rst
);


--***********************************************************
--Проект модуля хоста - dsn_host.vhd
--***********************************************************
m_host : dsn_host
generic map(
G_PCIE_LINK_WIDTH => C_PCGF_PCIE_LINK_WIDTH,
G_PCIE_RST_SEL    => C_PCGF_PCIE_RST_SEL,
G_DBG      => G_DBG_PCIE,
G_SIM_HOST => G_SIM_HOST,
G_SIM_PCIE => G_SIM_PCIE
)
port map(
--------------------------------------------------
-- Связь с хостом по Local bus
--------------------------------------------------
lad                => lad,
lbe_l              => lbe_l,
lads_l             => lads_l,
lwrite             => lwrite,
lblast_l           => lblast_l,
lbterm_l           => lbterm_l,
lready_l           => lready_l,
fholda             => fholda,
finto_l            => finto_l,
lclk               => g_lbus_clk,

--------------------------------------------------
-- Связь с хостом по PCI-EXPRESS
--------------------------------------------------
p_out_pciexp_txp   => pin_out_pciexp_txp,
p_out_pciexp_txn   => pin_out_pciexp_txn,
p_in_pciexp_rxp    => pin_in_pciexp_rxp,
p_in_pciexp_rxn    => pin_in_pciexp_rxn,

p_in_pciexp_gt_clkin   => i_pciexp_gt_refclk,
p_out_pciexp_gt_clkout => g_pciexp_gt_refclkout,

--------------------------------------------------
--Связь с уст-вами проекта Veresk-M
--------------------------------------------------
p_out_hclk         => g_host_clk,
p_out_gctrl        => i_host_gctrl,

p_out_dev_ctrl     => i_host_dev_ctrl,
p_out_dev_din      => i_host_dev_txd,
p_in_dev_dout      => i_host_dev_rxd,
p_out_dev_wr       => i_host_dev_wr,
p_out_dev_rd       => i_host_dev_rd,
p_in_dev_status    => i_host_dev_status,
p_in_dev_irq       => i_host_dev_irq,
p_in_dev_opt       => i_host_dev_opt_in,
p_out_dev_opt      => i_host_dev_opt_out,

--------------------------------------------------
--Технологический
--------------------------------------------------
p_in_usr_tst       => i_host_tst_in,
p_out_usr_tst      => i_host_tst_out,
p_in_tst           => (others=>'0'),
p_out_tst          => i_host_tst2_out,

--------------------------------------------------
--System
--------------------------------------------------
p_out_module_rdy   => i_host_rdy,
p_in_rst_n         => i_host_rst_n
);

i_host_tst_in(63 downto 0)<=(others=>'0');
i_host_tst_in(71 downto 64)<=(others=>'0');
i_host_tst_in(72)<='0';--i_eth_module_gt_plllkdet;
i_host_tst_in(73)<='0';--lclk_dcm_lock;
i_host_tst_in(74)<='0';--i_hdd_gt_plldet and i_hdd_dcm_lock;
i_host_tst_in(75)<=i_memctrl_ready;
i_host_tst_in(76)<=AND_reduce(i_memctrl_trained(C_PCFG_MEMCTRL_BANK_COUNT downto 0));
i_host_tst_in(126 downto 77)<=(others=>'0');
i_host_tst_in(127)<=i_vctrl_tst_out(0);-- xor i_hdd_tst_out(0);
                    --i_arb_mem_tst_out(0)  i_hdd_rbuf_tst_out(0) or i_swt_tst_out(0);


--//Статусы устройств
i_host_dev_status(C_HREG_DEV_STATUS_CFG_RDY_BIT)    <=i_cfg_rdy;
i_host_dev_status(C_HREG_DEV_STATUS_CFG_RXRDY_BIT)  <=i_host_rxrdy(C_HDEV_CFG_DBUF);
i_host_dev_status(C_HREG_DEV_STATUS_CFG_TXRDY_BIT)  <=i_host_txrdy(C_HDEV_CFG_DBUF);

i_host_dev_status(C_HREG_DEV_STATUS_ETH_RDY_BIT)    <=i_ethphy_out.rdy;
i_host_dev_status(C_HREG_DEV_STATUS_ETH_LINK_BIT)   <=i_ethphy_out.link;
i_host_dev_status(C_HREG_DEV_STATUS_ETH_RXRDY_BIT)  <=i_host_rxrdy(C_HDEV_ETH_DBUF);
i_host_dev_status(C_HREG_DEV_STATUS_ETH_TXRDY_BIT)  <=i_host_txrdy(C_HDEV_ETH_DBUF);

gen_status_vch : for i in 0 to C_VCTRL_VCH_COUNT_MAX-1 generate
i_host_dev_status(C_HREG_DEV_STATUS_VCH0_FRRDY_BIT + i)<=i_vctrl_hrdy_out(i);
end generate gen_status_vch;

i_host_dev_status(C_HREG_DEV_STATUS_MEMCTRL_RDY_BIT)<=i_memctrl_ready;
i_host_dev_status(C_HREG_DEV_STATUS_TRCNIK_DRDY_BIT)<=i_trcnik_hdrdy;


--//Запись/Чтение данных устройств хоста
i_host_wr(C_HDEV_MEM_DBUF) <=i_host_dev_wr when i_host_devadr=CONV_STD_LOGIC_VECTOR(C_HDEV_MEM_DBUF, i_host_devadr'length) else '0';
i_host_rd(C_HDEV_MEM_DBUF) <=i_host_dev_rd when i_host_devadr=CONV_STD_LOGIC_VECTOR(C_HDEV_MEM_DBUF, i_host_devadr'length) else '0';
i_host_txd(C_HDEV_MEM_DBUF)<=i_host_dev_txd;

i_host_wr(C_HDEV_CFG_DBUF) <=i_host_dev_wr when i_host_devadr=CONV_STD_LOGIC_VECTOR(C_HDEV_CFG_DBUF, i_host_devadr'length) else '0';
i_host_rd(C_HDEV_CFG_DBUF) <=i_host_dev_rd when i_host_devadr=CONV_STD_LOGIC_VECTOR(C_HDEV_CFG_DBUF, i_host_devadr'length) else '0';
i_host_txd(C_HDEV_CFG_DBUF)<=i_host_dev_txd;

i_host_wr(C_HDEV_ETH_DBUF) <=i_host_dev_wr when i_host_devadr=CONV_STD_LOGIC_VECTOR(C_HDEV_ETH_DBUF, i_host_devadr'length) else '0';
i_host_rd(C_HDEV_ETH_DBUF) <=i_host_dev_rd when i_host_devadr=CONV_STD_LOGIC_VECTOR(C_HDEV_ETH_DBUF, i_host_devadr'length) else '0';
i_host_txd(C_HDEV_ETH_DBUF)<=i_host_dev_txd;

i_host_rd(C_HDEV_VCH_DBUF) <=i_host_dev_rd when i_host_devadr=CONV_STD_LOGIC_VECTOR(C_HDEV_VCH_DBUF, i_host_devadr'length) else '0';

i_host_dev_rxd<=i_host_rxd(C_HDEV_CFG_DBUF) when i_host_devadr=CONV_STD_LOGIC_VECTOR(C_HDEV_CFG_DBUF, i_host_devadr'length) else
                i_host_rxd(C_HDEV_ETH_DBUF) when i_host_devadr=CONV_STD_LOGIC_VECTOR(C_HDEV_ETH_DBUF, i_host_devadr'length) else
                i_host_rxd(C_HDEV_VCH_DBUF) when i_host_devadr=CONV_STD_LOGIC_VECTOR(C_HDEV_VCH_DBUF, i_host_devadr'length) else
                i_host_rxd(C_HDEV_MEM_DBUF) when i_host_devadr=CONV_STD_LOGIC_VECTOR(C_HDEV_MEM_DBUF, i_host_devadr'length) else
                (others=>'0');


--//Флаги (Host<-dev)
i_host_dev_opt_in(C_HDEV_OPTIN_TXFIFO_PFULL_BIT)<=i_host_txbuf_full(C_HDEV_ETH_DBUF) when i_host_devadr=CONV_STD_LOGIC_VECTOR(C_HDEV_ETH_DBUF, i_host_devadr'length) else
                                                  i_host_txbuf_full(C_HDEV_MEM_DBUF) when i_host_devadr=CONV_STD_LOGIC_VECTOR(C_HDEV_MEM_DBUF, i_host_devadr'length) else
                                                  '0';

i_host_dev_opt_in(C_HDEV_OPTIN_RXFIFO_EMPTY_BIT)<=i_host_rxbuf_empty(C_HDEV_ETH_DBUF) when i_host_devadr=CONV_STD_LOGIC_VECTOR(C_HDEV_ETH_DBUF, i_host_devadr'length) else
                                                  i_host_rxbuf_empty(C_HDEV_VCH_DBUF) when i_host_devadr=CONV_STD_LOGIC_VECTOR(C_HDEV_VCH_DBUF, i_host_devadr'length) else
                                                  i_host_rxbuf_empty(C_HDEV_MEM_DBUF) when i_host_devadr=CONV_STD_LOGIC_VECTOR(C_HDEV_MEM_DBUF, i_host_devadr'length) else
                                                  '0';

i_host_dev_opt_in(C_HDEV_OPTIN_MEMTRN_DONE_BIT)<=i_host_mem_status.done;
i_host_dev_opt_in(C_HDEV_OPTIN_VCTRL_FRMRK_M_BIT downto C_HDEV_OPTIN_VCTRL_FRMRK_L_BIT)<=i_vctrl_hfrmrk;
i_host_dev_opt_in(C_HDEV_OPTIN_VCTRL_FRSKIP_M_BIT downto C_HDEV_OPTIN_VCTRL_FRSKIP_L_BIT)<=i_vctrl_tst_out(23 downto 16);
i_host_dev_opt_in(C_HDEV_OPTIN_TRC_DSIZE_M_BIT downto C_HDEV_OPTIN_TRC_DSIZE_L_BIT)<=i_trcnik_hfrmrk;


--//Прерывания
i_host_dev_irq(C_HIRQ_TMR0)  <=i_tmr_hirq(0);
i_host_dev_irq(C_HIRQ_CFG_RX)<=i_host_irq(C_HIRQ_CFG_RX);
i_host_dev_irq(C_HIRQ_ETH_RX)<=i_host_irq(C_HIRQ_ETH_RX);
i_host_dev_irq(C_HIRQ_TRCNIK)<=i_host_irq(C_HIRQ_TRCNIK);
gen_irq_vch : for i in 0 to C_VCTRL_VCH_COUNT_MAX-1 generate
i_host_dev_irq(C_HIRQ_VCH0 + i)<=i_vctrl_hirq_out(i);
end generate gen_irq_vch;


--//Обработка управляющих сигналов Хоста
i_host_mem_ctrl.dir       <=not i_host_dev_ctrl(C_HREG_DEV_CTRL_DMA_DIR_BIT);
i_host_mem_ctrl.start     <=i_host_dev_ctrl(C_HREG_DEV_CTRL_DMA_START_BIT) when i_host_devadr=CONV_STD_LOGIC_VECTOR(C_HDEV_MEM_DBUF, i_host_devadr'length) else '0';
i_host_mem_ctrl.adr       <=i_host_dev_opt_out(C_HDEV_OPTOUT_MEM_ADR_M_BIT downto C_HDEV_OPTOUT_MEM_ADR_L_BIT);
i_host_mem_ctrl.req_len   <=i_host_dev_opt_out(C_HDEV_OPTOUT_MEM_RQLEN_M_BIT downto C_HDEV_OPTOUT_MEM_RQLEN_L_BIT);
i_host_mem_ctrl.trnwr_len <=i_host_dev_opt_out(C_HDEV_OPTOUT_MEM_TRNWR_LEN_M_BIT downto C_HDEV_OPTOUT_MEM_TRNWR_LEN_L_BIT);
i_host_mem_ctrl.trnrd_len <=i_host_dev_opt_out(C_HDEV_OPTOUT_MEM_TRNRD_LEN_M_BIT downto C_HDEV_OPTOUT_MEM_TRNRD_LEN_L_BIT);

i_host_rst_all<=i_host_gctrl(C_HREG_CTRL_RST_ALL_BIT);
i_host_rst_eth<=i_host_gctrl(C_HREG_CTRL_RST_ETH_BIT);
i_host_rst_mem<=i_host_gctrl(C_HREG_CTRL_RST_MEM_BIT);
i_host_rddone_vctrl<=i_host_gctrl(C_HREG_CTRL_RDDONE_VCTRL_BIT);
i_host_rddone_trcnik<=i_host_gctrl(C_HREG_CTRL_RDDONE_TRCNIK_BIT);

i_host_devadr<=i_host_dev_ctrl(C_HREG_DEV_CTRL_ADR_M_BIT downto C_HREG_DEV_CTRL_ADR_L_BIT);
i_host_vchsel<=EXT(i_host_dev_ctrl(C_HREG_DEV_CTRL_VCH_M_BIT downto C_HREG_DEV_CTRL_VCH_L_BIT), i_host_vchsel'length);

process(i_host_rst_n, g_host_clk)
begin
  if i_host_rst_n='0' then
    for i in 0 to C_HDEV_COUNT-1 loop
      i_hdev_dma_start(i)<='0';
      hclk_hdev_dma_start(i)<='0';
      hclk_hdev_dma_start_cnt(i)<=(others=>'0');
    end loop;

    hclk_hrddone_vctrl<='0';
    hclk_hrddone_vctrl_cnt<=(others=>'0');

    hclk_hrddone_trcnik<='0';
    hclk_hrddone_trcnik_cnt<=(others=>'0');

  elsif g_host_clk'event and g_host_clk='1' then

    for i in 0 to C_HDEV_COUNT-1 loop
      --//импульс начала DMA транзакции
      if i_host_devadr=i then
        if i_host_dev_ctrl(C_HREG_DEV_CTRL_DMA_START_BIT)='1' then
          i_hdev_dma_start(i)<='1';
        else
          i_hdev_dma_start(i)<='0';
        end if;
      end if;
    end loop;--//for

    --//Расширитель импульсов:
    for i in 0 to C_HDEV_COUNT-1 loop
      --//Растягиваем импульс начала DMA транзакции
      if i_hdev_dma_start(i)='1' then
        hclk_hdev_dma_start(i)<='1';
      elsif hclk_hdev_dma_start_cnt(i)="100" then
        hclk_hdev_dma_start(i)<='0';
      end if;

      if hclk_hdev_dma_start(i)='0' then
        hclk_hdev_dma_start_cnt(i)<=(others=>'0');
      else
        hclk_hdev_dma_start_cnt(i)<=hclk_hdev_dma_start_cnt(i)+1;
      end if;
    end loop;

    --//Растягиваем импульс i_host_rddone_vctrl
    if i_host_rddone_vctrl='1' then
      hclk_hrddone_vctrl<='1';
    elsif hclk_hrddone_vctrl_cnt="100" then
      hclk_hrddone_vctrl<='0';
    end if;

    if hclk_hrddone_vctrl='0' then
      hclk_hrddone_vctrl_cnt<=(others=>'0');
    else
      hclk_hrddone_vctrl_cnt<=hclk_hrddone_vctrl_cnt+1;
    end if;

    --//Растягиваем импульс i_host_rddone_trcnik
    if i_host_rddone_trcnik='1' then
      hclk_hrddone_trcnik<='1';
    elsif hclk_hrddone_trcnik_cnt="100" then
      hclk_hrddone_trcnik<='0';
    end if;

    if hclk_hrddone_trcnik='0' then
      hclk_hrddone_trcnik_cnt<=(others=>'0');
    else
      hclk_hrddone_trcnik_cnt<=hclk_hrddone_trcnik_cnt+1;
    end if;

  end if;
end process;

--//Пересинхронизация управляющих сигналов Хоста
process(i_host_rst_n, g_usr_highclk)
begin
  if i_host_rst_n='0' then
    i_vctrl_hrd_start<='0';

    i_vctrl_hrd_done<='0';
    i_vctrl_hrd_done_dly<=(others=>'0');

    i_trcnik_hrd_done_dly<=(others=>'0');
    i_trcnik_hrd_done<='0';

  elsif g_usr_highclk'event and g_usr_highclk='1' then
    i_vctrl_hrd_start<=hclk_hdev_dma_start(C_HDEV_VCH_DBUF);

    i_vctrl_hrd_done_dly(0)<=hclk_hrddone_vctrl;
    i_vctrl_hrd_done_dly(1)<=i_vctrl_hrd_done_dly(0);
    i_vctrl_hrd_done<=i_vctrl_hrd_done_dly(0) and not i_vctrl_hrd_done_dly(1);

    i_trcnik_hrd_done_dly(0)<=hclk_hrddone_trcnik;
    i_trcnik_hrd_done_dly(1)<=i_trcnik_hrd_done_dly(0);
    i_trcnik_hrd_done<=i_trcnik_hrd_done_dly(0) and not i_trcnik_hrd_done_dly(1);

  end if;
end process;


--***********************************************************
--Модуль Контроллера памяти
--***********************************************************
--Связь модуля dsn_host c ОЗУ
m_host2mem : pcie2mem_ctrl
generic map(
G_MEM_AWIDTH     => C_HREG_MEM_ADR_LAST_BIT,
G_MEM_DWIDTH     => C_HDEV_DWIDTH,
G_MEM_BANK_M_BIT => C_HREG_MEM_ADR_BANK_M_BIT,
G_MEM_BANK_L_BIT => C_HREG_MEM_ADR_BANK_L_BIT,
G_DBG            => G_SIM
)
port map(
-------------------------------
--Управление
-------------------------------
p_in_ctrl         => i_host_mem_ctrl,
p_out_status      => i_host_mem_status,

p_in_txd          => i_host_txd(C_HDEV_MEM_DBUF),
p_in_txd_wr       => i_host_wr(C_HDEV_MEM_DBUF),
p_out_txbuf_full  => i_host_txbuf_full(C_HDEV_MEM_DBUF),

p_out_rxd         => i_host_rxd(C_HDEV_MEM_DBUF),
p_in_rxd_rd       => i_host_rd(C_HDEV_MEM_DBUF),
p_out_rxbuf_empty => i_host_rxbuf_empty(C_HDEV_MEM_DBUF),

p_in_hclk         => g_host_clk,

-------------------------------
--Связь с mem_ctrl
-------------------------------
p_out_mem         => i_host_memin,
p_in_mem          => i_host_memout,

-------------------------------
--Технологический
-------------------------------
p_in_tst          => (others=>'0'),
p_out_tst         => i_host_mem_tst_out,

-------------------------------
--System
-------------------------------
p_in_clk         => g_usr_highclk,
p_in_rst         => i_arb_mem_rst
);

--//Подключаем устройства к арбитру ОЗУ
i_memin_ch(0) <= i_host_memin;
i_host_memout <= i_memout_ch(0);

i_memin_ch(1)    <= i_vctrlwr_memin;
i_vctrlwr_memout <= i_memout_ch(1);

i_memin_ch(2)    <= i_vctrlrd_memin;
i_vctrlrd_memout <= i_memout_ch(2);

gen_ch34sel0 : if (strcmp(C_PCFG_HDD_USE,"ON")  and strcmp(C_PCFG_TRC_USE,"ON")) or
                  (strcmp(C_PCFG_HDD_USE,"OFF") and strcmp(C_PCFG_TRC_USE,"OFF")) or
                  (strcmp(C_PCFG_HDD_USE,"ON")  and strcmp(C_PCFG_TRC_USE,"OFF")) generate

i_memin_ch(3)<= i_hdd_memin;
i_hdd_memout <= i_memout_ch(3);

i_memin_ch(4)<= i_trc_memin;
i_trc_memout <= i_memout_ch(4);

end generate gen_ch34sel0;

gen_ch34sel1 : if (strcmp(C_PCFG_HDD_USE,"OFF") and strcmp(C_PCFG_TRC_USE,"ON")) generate
i_memin_ch(3) <= i_trc_memin;
i_trc_memout  <= i_memout_ch(3);

i_memin_ch(4)<= i_hdd_memin;
i_hdd_memout <= i_memout_ch(4);

end generate gen_ch34sel1;

--//Арбитр контроллера памяти
m_mem_arb : mem_arb
generic map(
G_CH_COUNT   => selval2(10#05#,10#04#,10#04#,10#03#, strcmp(C_PCFG_HDD_USE,"ON"),strcmp(C_PCFG_TRC_USE,"ON")),
G_MEM_AWIDTH => C_HREG_MEM_ADR_LAST_BIT,
G_MEM_DWIDTH => C_HDEV_DWIDTH
)
port map(
-------------------------------
--Связь с пользователями ОЗУ
-------------------------------
p_in_memch  => i_memin_ch,
p_out_memch => i_memout_ch,

-------------------------------
--Связь с mem_ctrl.vhd
-------------------------------
p_out_mem   => i_arb_memin,
p_in_mem    => i_arb_memout,

-------------------------------
--Технологический
-------------------------------
p_in_tst    => (others=>'0'),
p_out_tst   => i_arb_mem_tst_out,

-------------------------------
--System
-------------------------------
p_in_clk    => g_usr_highclk,
p_in_rst    => i_arb_mem_rst
);


m_mem_ctrl : mem_ctrl
generic map(
G_BANK_COUNT => C_PCFG_MEMCTRL_BANK_COUNT,
G_SIM        => G_SIM
)
port map(
-----------------------------
--Memory pins
-----------------------------
ra0        => ra0,
rc0        => rc0,
rd0        => rd0,

-----------------------------
-- User channel 0
-----------------------------
p_in_mem   => i_arb_memin,
p_out_mem  => i_arb_memout,

-----------------------------
--Status
-----------------------------
trained    => i_memctrl_trained,

-----------------------------
--System
-----------------------------
memclk0    => i_memctrl_pllclk0,
memclk45   => i_memctrl_pllclk45,
memclk2x0  => i_memctrl_pllclk2x0,
memclk2x90 => i_memctrl_pllclk2x90,
memrst     => i_memctrl_pll_rst_out,
rst        => i_memctrl_rst
);

i_memctrl_ready<=i_memctrl_locked(0);


--//#########################################
--//DBG
--//#########################################
--//Для ПЛАТЫ ALPHA DATA
gen_alphadata : if strcmp(C_PCFG_BOARD,"ALPHA_DATA") generate
begin

pin_out_led<=(others=>'0');
pin_out_led_C<=pin_in_btn_C;
pin_out_led_E<=pin_in_btn_E;
pin_out_led_N<=pin_in_btn_N;
pin_out_led_S<=pin_in_btn_S;
pin_out_led_W<=pin_in_btn_W;

pin_out_TP(0)<=pin_in_btn_C;
pin_out_TP(1)<=pin_in_btn_E;
pin_out_TP(2)<=pin_in_btn_N;
pin_out_TP(3)<=pin_in_btn_S;
pin_out_TP(4)<=pin_in_btn_W;
pin_out_TP(pin_out_TP'high downto 5)<=(others=>'0');

pin_out_ddr2_cke1<='0';
pin_out_ddr2_cs1<='0';
pin_out_ddr2_odt1<='0';

i_usr_rst<='0';
i_hdd_tst_in<=(others=>'0');

end generate gen_alphadata;


--//Для ПЛАТЫ ML505
gen_ml505 : if strcmp(C_PCFG_BOARD,"ML505") generate

pin_out_ddr2_cke1<='0';
pin_out_ddr2_cs1<='0';
pin_out_ddr2_odt1<='0';

i_usr_rst<=pin_in_btn_N;
i_hdd_tst_in(0)<=pin_in_btn_W;
i_hdd_tst_in(31 downto 1)<=(others=>'0');

--i_trc_busy<=(others=>'0');

--//J5 /pin2
pin_out_TP(0)<=pin_in_btn_E or i_trc_busy(0);

--//J6
pin_out_TP(1)<=pin_in_btn_C;--i_dsntst_tst_out(1);  --//pin6
                            --//pin8
pin_out_TP(2)<='0';         --//pin10
pin_out_TP(3)<='0';
                            --//pin14
pin_out_TP(4)<='0';         --//pin16
                            --//pin18
pin_out_TP(5)<='0';         -- /pin20
                            --//pin22
pin_out_TP(6)<='0';         -- /pin24
pin_out_TP(7)<='0';         -- /pin26

--Светодиоды
pin_out_led_E<=i_hdd_gt_plldet and i_hdd_dcm_lock;
pin_out_led_N<=lclk_dcm_lock when pin_in_btn_S='0' else i_test01_led;
pin_out_led_S<=i_memctrl_locked(0);
pin_out_led_W<='0' when pin_in_btn_W='0' else i_hdd_dbgled(1).spd(1);
pin_out_led_C<=not lclk_dcm_lock or i_usr_rst when pin_in_btn_W='0' else i_hdd_dbgled(1).spd(0);

pin_out_led(0)<=i_hdd_dbgled(1).busy;
pin_out_led(1)<=i_hdd_dbgled(1).err;
pin_out_led(2)<=i_hdd_dbgled(1).rdy;
pin_out_led(3)<=i_hdd_dbgled(1).link;

pin_out_led(4)<=i_hdd_dbgled(0).busy;
pin_out_led(5)<=i_hdd_dbgled(0).err;
pin_out_led(6)<=i_hdd_dbgled(0).rdy;
pin_out_led(7)<=i_hdd_dbgled(0).link;

m_gt_03_test: fpga_test_01
generic map(
G_BLINK_T05   =>10#250#, -- 1/2 периода мигания светодиода.(время в ms)
G_CLK_T05us   =>10#75#   -- 05us - 150MHz
)
port map(
p_out_test_led => i_test01_led,
p_out_test_done=> open,

p_out_1us      => open,
p_out_1ms      => open,
-------------------------------
--System
-------------------------------
p_in_clk       => g_refclk200MHz,
p_in_rst       => i_cfg_rst
);


gen_dbgcs : if strcmp(C_PCFG_HDD_DBGCS,"ON") generate

m_dbgcs_icon : dbgcs_iconx1
port map(
CONTROL0 => i_dbgcs_hdd_rambuf
--CONTROL0 => i_dbgcs_hdd_raid
);

--m_dbgcs_icon : dbgcs_iconx2
--port map(
--CONTROL0 => i_dbgcs_sh0_layer,--i_dbgcs_hdd_rambuf, --i_dbgcs_hdd_raid,   --
--CONTROL1 => i_dbgcs_hdd_raid  --i_dbgcs_hdd_raid    --i_dbgcs_hwstart_dly --
--);

--m_dbgcs_icon : dbgcs_iconx3
--port map(
--CONTROL0 => i_dbgcs_sh0_layer,
--CONTROL1 => i_dbgcs_hdd_rambuf,
--CONTROL2 => i_dbgcs_hdd_raid
--);



----//### HDD_SH_LAYER: ########
--m_dbgcs_sh0_layer : dbgcs_sata_raid --dbgcs_sata_layer
--port map(
--CONTROL => i_dbgcs_sh0_layer,
--CLK     => i_hdd_dbgcs.sh(1).layer.clk,
--DATA    => i_hdd_dbgcs.sh(1).layer.data(172 downto 0),--(122 downto 0),
--TRIG0   => i_hdd_dbgcs.sh(1).layer.trig0(41 downto 0)
--);



--//### HDD_RAMBUF: ########
m_dbgcs_hddrambuf : dbgcs_sata_raid -- dbgcs_sata_rambuf
port map(
CONTROL => i_dbgcs_hdd_rambuf,
CLK     => i_hdd_rambuf_dbgcs.clk,
DATA    => i_hddrambuf_dbgcs.data(172 downto 0),--(136 downto 0),
TRIG0   => i_hddrambuf_dbgcs.trig0(41 downto 0)
);

--//-------- TRIG: ------------------
i_hddrambuf_dbgcs.trig0(4 downto  0) <=i_hdd_rambuf_dbgcs.trig0(4 downto 0);--tst_fsm_cs(4 downto 0);
i_hddrambuf_dbgcs.trig0(5)           <=i_hdd_memin.ce;
i_hddrambuf_dbgcs.trig0(6)           <=i_hdd_memin.cw;
i_hddrambuf_dbgcs.trig0(20 downto 7) <=i_hdd_rambuf_dbgcs.trig0(20 downto 7);
i_hddrambuf_dbgcs.trig0(21)          <=i_vctrlwr_memout.req_en;
i_hddrambuf_dbgcs.trig0(22)          <=i_vctrlrd_memout.req_en;
i_hddrambuf_dbgcs.trig0(23)          <=i_hdd_memout.req_en;
i_hddrambuf_dbgcs.trig0(24)          <=i_arb_memin.ce;
i_hddrambuf_dbgcs.trig0(25)          <='0';
i_hddrambuf_dbgcs.trig0(26)          <='0';
i_hddrambuf_dbgcs.trig0(27)          <='0';
i_hddrambuf_dbgcs.trig0(28)          <='0';
i_hddrambuf_dbgcs.trig0(29)          <='0';
i_hddrambuf_dbgcs.trig0(41 downto 30)<=i_hdd_rambuf_dbgcs.trig0(41 downto 30);


--//-------- VIEW: ------------------
i_hddrambuf_dbgcs.data(0)<=i_hdd_memin.ce;       --//
i_hddrambuf_dbgcs.data(1)<=i_hdd_memin.cw;
i_hddrambuf_dbgcs.data(2)<=i_arb_memin.rd;   --//i_hdd_mem_rd;  --
i_hddrambuf_dbgcs.data(3)<=i_arb_memin.wr;   --//i_hdd_mem_wr;  --
i_hddrambuf_dbgcs.data(4)<=i_arb_memin.term; --//i_hdd_mem_term;--
i_hddrambuf_dbgcs.data(18 downto 5)<=i_hdd_rambuf_dbgcs.data(18 downto 5);

i_hddrambuf_dbgcs.data(19)<=i_swt_tst_out(0);--//tst_swt_hdd_vbuf_wr;

i_hddrambuf_dbgcs.data(119 downto 20)<=i_hdd_rambuf_dbgcs.data(119 downto 20);
i_hddrambuf_dbgcs.data(135 downto 120)<=i_arb_memout.data(15 downto 0);--tst_hdd_mem_dcnt;
i_hddrambuf_dbgcs.data(151 downto 136)<=i_hdd_rambuf_dbgcs.data(151 downto 136);

i_hddrambuf_dbgcs.data(152)          <=i_vctrlwr_memout.req_en;
i_hddrambuf_dbgcs.data(153)          <=i_vctrlrd_memout.req_en;
i_hddrambuf_dbgcs.data(154)          <=i_hdd_memout.req_en;
--i_hddrambuf_dbgcs.data(166 downto 155)<=i_arb_memin.data(27 downto 16);
i_hddrambuf_dbgcs.data(166 downto 155)<=i_hdd_rambuf_dbgcs.data(166 downto 155);

i_hddrambuf_dbgcs.data(172 downto 167)<=i_hdd_rambuf_dbgcs.data(172 downto 167);





----//### HDD_RAID: ########
--m_dbgcs_sh0_raid : dbgcs_sata_raid
--port map(
--CONTROL => i_dbgcs_hdd_raid,
--CLK     => i_hdd_dbgcs.raid.clk,
--DATA    => i_hddraid_dbgcs.data(172 downto 0),--(122 downto 0),
--TRIG0   => i_hddraid_dbgcs.trig0(41 downto 0)
--);
--
----//-------- TRIG: ------------------
--i_hddraid_dbgcs.trig0(18 downto 0)<=i_hdd_dbgcs.raid.trig0(18 downto 0);
--i_hddraid_dbgcs.trig0(19)<=i_cfg_rx_hirq;--tst_trm_timeout(10);--
--
----//SH0
--i_hddraid_dbgcs.trig0(24 downto 20)<=i_hdd_dbgcs.sh(0).layer.trig0(34 downto 30);--llayer
--i_hddraid_dbgcs.trig0(29 downto 25)<=i_hdd_dbgcs.sh(0).layer.trig0(39 downto 35);--tlayer
----//SH1
--i_hddraid_dbgcs.trig0(34 downto 30)<=i_hdd_dbgcs.sh(1).layer.trig0(34 downto 30);--llayer
--i_hddraid_dbgcs.trig0(39 downto 35)<=i_hdd_dbgcs.sh(1).layer.trig0(39 downto 35);--tlayer
--
--i_hddraid_dbgcs.trig0(40)<=i_hdd_rbuf_status.err;--i_hdd_dbgcs.raid.trig0(40);
--i_hddraid_dbgcs.trig0(41)<=i_hdd_txbuf_pfull;
--
--
----//-------- VIEW: ------------------
--i_hddraid_dbgcs.data(28 downto 0)<=i_hdd_dbgcs.raid.data(28 downto 0);
--i_hddraid_dbgcs.data(29)<=i_hdd_txbuf_pfull;
--
----//SH0
--i_hddraid_dbgcs.data(34 downto 30)<=i_hdd_dbgcs.sh(0).layer.trig0(34 downto 30);--llayer
--i_hddraid_dbgcs.data(39 downto 35)<=i_hdd_dbgcs.sh(0).layer.trig0(39 downto 35);--tlayer
--i_hddraid_dbgcs.data(55 downto 40)<=i_hdd_dbgcs.sh(0).layer.data(115 downto 100);--tst_cnt
------i_hddraid_dbgcs.data(55 downto 40)<=i_hdd_dbgcs.sh(0).layer.data(65 downto 50);--p_in_ll_rxd(15 downto 0);--llayer->tlayer
----i_hddraid_dbgcs.data(55 downto 40)<=i_hdd_dbgcs.sh(0).layer.data(97 downto 82);--p_in_ll_txd(15 downto 0);--llayer<-tlayer
--i_hddraid_dbgcs.data(56)          <=i_hdd_dbgcs.sh(0).layer.data(49);--p_in_ll_rxd_wr; --llayer->tlayer
--i_hddraid_dbgcs.data(57)          <=i_hdd_dbgcs.sh(0).layer.data(116);--p_in_ll_txd_rd; --llayer<-tlayer
--i_hddraid_dbgcs.data(58)          <=i_hdd_dbgcs.sh(0).layer.data(118);--<=p_in_dbg.llayer.txbuf_status.aempty; --p_in_gt_txcharisk(0);
--i_hddraid_dbgcs.data(59)          <=i_hdd_dbgcs.sh(0).layer.data(119);--<=p_in_dbg.llayer.txbuf_status.empty; --p_in_gt_txcharisk(1);
--i_hddraid_dbgcs.data(60)          <=i_hdd_dbgcs.sh(0).layer.data(98);--<=p_in_dbg.llayer.rxbuf_status.pfull; --p_in_gt_rxcharisk(0);
--i_hddraid_dbgcs.data(61)          <=i_hdd_dbgcs.sh(0).layer.data(99);--<=p_in_dbg.llayer.txbuf_status.pfull; --p_in_gt_rxcharisk(1);
--i_hddraid_dbgcs.data(62)          <=i_hdd_dbgcs.sh(0).layer.data(117);--<=p_in_dbg.llayer.txd_close;
--
----//SH1
--i_hddraid_dbgcs.data(67 downto 63)<=i_hdd_dbgcs.sh(1).layer.trig0(34 downto 30);--llayer
--i_hddraid_dbgcs.data(72 downto 68)<=i_hdd_dbgcs.sh(1).layer.trig0(39 downto 35);--tlayer
--i_hddraid_dbgcs.data(88 downto 73)<=i_hdd_dbgcs.sh(1).layer.data(115 downto 100);--tst_cnt
------i_hddraid_dbgcs.data(88 downto 73)<=i_hdd_dbgcs.sh(1).layer.data(65 downto 50);--p_in_ll_rxd(15 downto 0);--llayer->tlayer
----i_hddraid_dbgcs.data(88 downto 73)<=i_hdd_dbgcs.sh(1).layer.data(97 downto 82);--p_in_ll_txd(15 downto 0);--llayer<-tlayer
--i_hddraid_dbgcs.data(89)          <=i_hdd_dbgcs.sh(1).layer.data(49);--p_in_ll_rxd_wr; --llayer->tlayer
--i_hddraid_dbgcs.data(90)          <=i_hdd_dbgcs.sh(1).layer.data(116);--p_in_ll_txd_rd; --llayer<-tlayer
--i_hddraid_dbgcs.data(91)          <=i_hdd_dbgcs.sh(1).layer.data(118);--<=p_in_dbg.llayer.txbuf_status.aempty; --p_in_gt_txcharisk(0);
--i_hddraid_dbgcs.data(92)          <=i_hdd_dbgcs.sh(1).layer.data(119);--<=p_in_dbg.llayer.txbuf_status.empty; --p_in_gt_txcharisk(1);
--i_hddraid_dbgcs.data(93)          <=i_hdd_dbgcs.sh(1).layer.data(98);--<=p_in_dbg.llayer.rxbuf_status.pfull; --p_in_gt_rxcharisk(0);
--i_hddraid_dbgcs.data(94)          <=i_hdd_dbgcs.sh(1).layer.data(99);--<=p_in_dbg.llayer.txbuf_status.pfull; --p_in_gt_rxcharisk(1);
--i_hddraid_dbgcs.data(95)          <=i_hdd_done;--i_hdd_rambuf_dbgcs.data(3);--i_hdd_dbgcs.sh(1).layer.data(117);--<=p_in_dbg.llayer.txd_close;
--
----//RAMBUF
--i_hddraid_dbgcs.data(104 downto 100)<=i_hdd_rambuf_dbgcs.data(9 downto 5);--rambuf_fsm(3 downto 0);
----i_hddraid_dbgcs.data(104)<=i_hdd_memin.ce;
--i_hddraid_dbgcs.data(105)<=i_hdd_rxbuf_empty;
--i_hddraid_dbgcs.data(106)<=i_arb_memin.rd;--RAM->HDD
--i_hddraid_dbgcs.data(107)<=i_arb_memin.wr;--RAM<-HDD
--i_hddraid_dbgcs.data(108)<=i_arb_memin.term;
--i_hddraid_dbgcs.data(140 downto 109)<=i_mem_arb_dout(31 downto 0);--RAM->HDD
--i_hddraid_dbgcs.data(172 downto 141)<=i_mem_arb_din(31 downto 0);--RAM<-HDD


--process(i_hdd_rambuf_dbgcs.clk)
--begin
--if i_hdd_rambuf_dbgcs.clk'event and i_hdd_rambuf_dbgcs.clk='1' then
--  tst_sh0_llayer<=i_hdd_dbgcs.sh(0).layer.trig0(34 downto 30);--llayer
--  tst_sh1_llayer<=i_hdd_dbgcs.sh(1).layer.trig0(34 downto 30);--llayer
--
--  if tst_sh0_llayer=CONV_STD_LOGIC_VECTOR(16#0C#, tst_sh0_llayer'length) or
--     tst_sh1_llayer=CONV_STD_LOGIC_VECTOR(16#0C#, tst_sh1_llayer'length) or
--     tst_sh0_llayer=CONV_STD_LOGIC_VECTOR(16#13#, tst_sh0_llayer'length) or
--     tst_sh1_llayer=CONV_STD_LOGIC_VECTOR(16#13#, tst_sh1_llayer'length) then
--    tst_trm_timeout<=tst_trm_timeout + 1;
--  else
--    tst_trm_timeout<=(others=>'0');
--  end if;
--end if;
--end process;


--m_dbgcs_sata_hwstart : dbgcs_sata_hwstart
--port map(
--CONTROL => i_dbgcs_hwstart_dly,
--CLK     => i_hdd_dbgcs.hwstart_dly.clk,
--DATA    => i_hdd_dbgcs.hwstart_dly.data(7 downto 0),
--TRIG0   => i_hdd_dbgcs.hwstart_dly.trig0(7 downto 0)
--);


--m_dbgcs_cfg : dbgcs_cfg
--port map(
--CONTROL => i_dbgcs_cfg,
--CLK     => i_cfg_dbgcs.clk,
--DATA    => i_cfg_dbgcs.data(113 downto 0),--(122 downto 0),
--TRIG0   => i_cfg_dbgcs.trig0(15 downto 0)
--);
--
--i_cfg_dbgcs.clk<=g_host_clk;
--
--process(i_cfg_dbgcs.clk)
--begin
--if i_cfg_dbgcs.clk'event and i_cfg_dbgcs.clk='1' then
----//-------- TRIG: ------------------
--i_cfg_dbgcs.trig0(3 downto 0)<=i_cfg_dadr(3 downto 0);
--i_cfg_dbgcs.trig0(11 downto 4)<=i_cfg_radr(7 downto 0);
--i_cfg_dbgcs.trig0(12)<=i_cfg_wr;
--i_cfg_dbgcs.trig0(13)<=i_cfg_rd;
--i_cfg_dbgcs.trig0(14)<=i_host_cfg_rd;
--i_cfg_dbgcs.trig0(15)<=i_hdd_done;
--
--
----//-------- VIEW: ------------------
--i_cfg_dbgcs.data(3 downto 0)<=i_cfg_dadr(3 downto 0);
--i_cfg_dbgcs.data(11 downto 4)<=i_cfg_radr(7 downto 0);
--i_cfg_dbgcs.data(12)<=i_cfg_wr;
--i_cfg_dbgcs.data(13)<=i_cfg_rd;
--i_cfg_dbgcs.data(14)<=i_hdd_done;
--i_cfg_dbgcs.data(15)<=i_cfg_radr_ld;
--i_cfg_dbgcs.data(31 downto 16)<=i_cfg_txdata;
--i_cfg_dbgcs.data(47 downto 32)<=i_cfg_rxd_dev;
--i_cfg_dbgcs.data(48)<=i_host_cfg_rd;
--i_cfg_dbgcs.data(49)<=i_host_cfg_wd;
--i_cfg_dbgcs.data(81 downto 50)<=i_host_cfg_rxdata(31 downto 0);
--i_cfg_dbgcs.data(113 downto 82)<=i_hdd_dbgcs.measure.data(73 downto 42);--<=i_measure_dly_time;i_host_cfg_txdata(31 downto 0);
--end if;
--end process;


--m_dbgcs_sh0_spd : sata_dbgcs_spd
--port map(
--CONTROL => i_dbgcs_sh0_spd,
--CLK     => i_hdd_dbgcs.sh(0).spd.clk,
--DATA    => i_hdd_dbgcs.sh(0).spd.data(122 downto 0),
--TRIG0   => i_hdd_dbgcs.sh(0).spd.trig0(41 downto 0)
--);

end generate gen_dbgcs;


end generate gen_ml505;


end architecture;
