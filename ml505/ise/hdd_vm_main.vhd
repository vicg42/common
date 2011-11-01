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
use work.memory_ctrl_pkg.all;
use work.sata_glob_pkg.all;
use work.dsn_hdd_pkg.all;
use work.dsn_ethg_pkg.all;
use work.dsn_video_ctrl_pkg.all;

entity hdd_vm_main is
generic
(
G_SIM_HOST : string:="OFF";
G_SIM_PCIE : std_logic:='0';
G_DBG_PCIE : string:="OFF";
G_SIM      : string:="OFF"
);
port
(
--------------------------------------------------
--Технологический порт
--------------------------------------------------
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

pin_out_uart0_tx  : out   std_logic;
pin_in_uart0_rx   : in    std_logic;

--------------------------------------------------
--Memory banks (up to 16 supported by this design)
--------------------------------------------------
ra0               : out   std_logic_vector(C_MEM_BANK0.ra_width - 1 downto 0);
rc0               : inout std_logic_vector(C_MEM_BANK0.rc_width - 1 downto 0);
rd0               : inout std_logic_vector(C_MEM_BANK0.rd_width - 1 downto 0);
--ra1               : out   std_logic_vector(C_MEM_BANK1.ra_width - 1 downto 0);
--rc1               : inout std_logic_vector(C_MEM_BANK1.rc_width - 1 downto 0);
--rd1               : inout std_logic_vector(C_MEM_BANK1.rd_width - 1 downto 0);
--ra2               : out   std_logic_vector(C_MEM_BANK2.ra_width - 1 downto 0);
--rc2               : inout std_logic_vector(C_MEM_BANK2.rc_width - 1 downto 0);
--rd2               : inout std_logic_vector(C_MEM_BANK2.rd_width - 1 downto 0);
--ra3               : out   std_logic_vector(C_MEM_BANK3.ra_width - 1 downto 0);
--rc3               : inout std_logic_vector(C_MEM_BANK3.rc_width - 1 downto 0);
--rd3               : inout std_logic_vector(C_MEM_BANK3.rd_width - 1 downto 0);
--ra4               : out   std_logic_vector(C_MEM_BANK4.ra_width - 1 downto 0);
--rc4               : inout std_logic_vector(C_MEM_BANK4.rc_width - 1 downto 0);
--rd4               : inout std_logic_vector(C_MEM_BANK4.rd_width - 1 downto 0);
--ra5               : out   std_logic_vector(C_MEM_BANK5.ra_width - 1 downto 0);
--rc5               : inout std_logic_vector(C_MEM_BANK5.rc_width - 1 downto 0);
--rd5               : inout std_logic_vector(C_MEM_BANK5.rd_width - 1 downto 0);
--ra6               : out   std_logic_vector(C_MEM_BANK6.ra_width - 1 downto 0);
--rc6               : inout std_logic_vector(C_MEM_BANK6.rc_width - 1 downto 0);
--rd6               : inout std_logic_vector(C_MEM_BANK6.rd_width - 1 downto 0);
--ra7               : out   std_logic_vector(C_MEM_BANK7.ra_width - 1 downto 0);
--rc7               : inout std_logic_vector(C_MEM_BANK7.rc_width - 1 downto 0);
--rd7               : inout std_logic_vector(C_MEM_BANK7.rd_width - 1 downto 0);
--ra8               : out   std_logic_vector(C_MEM_BANK8.ra_width - 1 downto 0);
--rc8               : inout std_logic_vector(C_MEM_BANK8.rc_width - 1 downto 0);
--rd8               : inout std_logic_vector(C_MEM_BANK8.rd_width - 1 downto 0);
--ra9               : out   std_logic_vector(C_MEM_BANK9.ra_width - 1 downto 0);
--rc9               : inout std_logic_vector(C_MEM_BANK9.rc_width - 1 downto 0);
--rd9               : inout std_logic_vector(C_MEM_BANK9.rd_width - 1 downto 0);
--ra10              : out   std_logic_vector(C_MEM_BANK10.ra_width - 1 downto 0);
--rc10              : inout std_logic_vector(C_MEM_BANK10.rc_width - 1 downto 0);
--rd10              : inout std_logic_vector(C_MEM_BANK10.rd_width - 1 downto 0);
--ra11              : out   std_logic_vector(C_MEM_BANK11.ra_width - 1 downto 0);
--rc11              : inout std_logic_vector(C_MEM_BANK11.rc_width - 1 downto 0);
--rd11              : inout std_logic_vector(C_MEM_BANK11.rd_width - 1 downto 0);
--ra12              : out   std_logic_vector(C_MEM_BANK12.ra_width - 1 downto 0);
--rc12              : inout std_logic_vector(C_MEM_BANK12.rc_width - 1 downto 0);
--rd12              : inout std_logic_vector(C_MEM_BANK12.rd_width - 1 downto 0);
--ra13              : out   std_logic_vector(C_MEM_BANK13.ra_width - 1 downto 0);
--rc13              : inout std_logic_vector(C_MEM_BANK13.rc_width - 1 downto 0);
--rd13              : inout std_logic_vector(C_MEM_BANK13.rd_width - 1 downto 0);
--ra14              : out   std_logic_vector(C_MEM_BANK14.ra_width - 1 downto 0);
--rc14              : inout std_logic_vector(C_MEM_BANK14.rc_width - 1 downto 0);
--rd14              : inout std_logic_vector(C_MEM_BANK14.rd_width - 1 downto 0);
--ra15              : out   std_logic_vector(C_MEM_BANK15.ra_width - 1 downto 0);
--rc15              : inout std_logic_vector(C_MEM_BANK15.rc_width - 1 downto 0);
--rd15              : inout std_logic_vector(C_MEM_BANK15.rd_width - 1 downto 0);
--ramclko           : out   std_logic_vector(C_MEM_NUM_RAMCLK - 1 downto 0);

--------------------------------------------------
--Ethernet
--------------------------------------------------
pin_out_sfp_tx_dis    : out  std_logic;                      --//SFP - TX DISABLE
pin_in_sfp_sd         : in   std_logic;                      --//SFP - SD signal detect

pin_out_eth_txp       : out   std_logic_vector(1 downto 0);
pin_out_eth_txn       : out   std_logic_vector(1 downto 0);
pin_in_eth_rxp        : in    std_logic_vector(1 downto 0);
pin_in_eth_rxn        : in    std_logic_vector(1 downto 0);
pin_in_eth_clk_p      : in    std_logic;
pin_in_eth_clk_n      : in    std_logic;

pin_out_gt_X0Y6_txp   : out  std_logic_vector(1 downto 0);
pin_out_gt_X0Y6_txn   : out  std_logic_vector(1 downto 0);
pin_in_gt_X0Y6_rxp    : in   std_logic_vector(1 downto 0);
pin_in_gt_X0Y6_rxn    : in   std_logic_vector(1 downto 0);
pin_in_gt_X0Y6_clk_p  : in   std_logic;
pin_in_gt_X0Y6_clk_n  : in   std_logic;

--------------------------------------------------
--PCI-EXPRESS
--------------------------------------------------
pin_out_pciexp_txp    : out   std_logic_vector(C_PCIEXPRESS_LINK_WIDTH-1 downto 0);
pin_out_pciexp_txn    : out   std_logic_vector(C_PCIEXPRESS_LINK_WIDTH-1 downto 0);
pin_in_pciexp_rxp     : in    std_logic_vector(C_PCIEXPRESS_LINK_WIDTH-1 downto 0);
pin_in_pciexp_rxn     : in    std_logic_vector(C_PCIEXPRESS_LINK_WIDTH-1 downto 0);
pin_in_pciexp_clk_p   : in    std_logic;
pin_in_pciexp_clk_n   : in    std_logic;

--------------------------------------------------
--SATA
--------------------------------------------------
pin_out_sata_txn      : out   std_logic_vector((C_SH_GTCH_COUNT_MAX*C_SH_COUNT_MAX(C_HDD_COUNT-1))-1 downto 0);
pin_out_sata_txp      : out   std_logic_vector((C_SH_GTCH_COUNT_MAX*C_SH_COUNT_MAX(C_HDD_COUNT-1))-1 downto 0);
pin_in_sata_rxn       : in    std_logic_vector((C_SH_GTCH_COUNT_MAX*C_SH_COUNT_MAX(C_HDD_COUNT-1))-1 downto 0);
pin_in_sata_rxp       : in    std_logic_vector((C_SH_GTCH_COUNT_MAX*C_SH_COUNT_MAX(C_HDD_COUNT-1))-1 downto 0);
pin_in_sata_clk_n     : in    std_logic_vector(C_SH_COUNT_MAX(C_HDD_COUNT-1)-1 downto 0);
pin_in_sata_clk_p     : in    std_logic_vector(C_SH_COUNT_MAX(C_HDD_COUNT-1)-1 downto 0);

--------------------------------------------------
-- Local bus
--------------------------------------------------
lreset_l              : in    std_logic;
lclk                  : in    std_logic;
lwrite                : in    std_logic;
lads_l                : in    std_logic;
lblast_l              : in    std_logic;
lbe_l                 : in    std_logic_vector(32/8-1 downto 0);--(3 downto 0);
lad                   : inout std_logic_vector(32-1 downto 0);--(31 downto 0);
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

--component ROC generic (WIDTH : Time := 500 ns); port (O : out std_ulogic := '1'); end component;
component IBUFDS            port(I : in  std_logic; IB : in  std_logic; O  : out std_logic);end component;
component IBUFGDS_LVPECL_25 port(I : in  std_logic; IB : in  std_logic; O  : out std_logic);end component;
component BUFG              port(I : in  std_logic; O  : out std_logic);end component;

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

component cfgdev_uart
generic(
G_BAUDCNT_VAL: integer:=64
);
port
(
-------------------------------
--Связь с UART
-------------------------------
p_out_uart_tx        : out    std_logic;
p_in_uart_rx         : in     std_logic;
p_in_uart_refclk     : in     std_logic;

-------------------------------
--
-------------------------------
p_out_module_rdy     : out    std_logic;
p_out_module_error   : out    std_logic;

-------------------------------
--Запись/Чтение конфигурационных параметров уст-ва
-------------------------------
p_out_cfg_dadr       : out    std_logic_vector(C_CFGPKT_DADR_M_BIT - C_CFGPKT_DADR_L_BIT downto 0);
p_out_cfg_radr       : out    std_logic_vector(C_CFGPKT_RADR_M_BIT - C_CFGPKT_RADR_L_BIT downto 0);
p_out_cfg_radr_ld    : out    std_logic;
p_out_cfg_radr_fifo  : out    std_logic;
p_out_cfg_wr         : out    std_logic;
p_out_cfg_rd         : out    std_logic;
p_out_cfg_txdata     : out    std_logic_vector(15 downto 0);
p_in_cfg_rxdata      : in     std_logic_vector(15 downto 0);
p_in_cfg_txrdy       : in     std_logic;
p_in_cfg_rxrdy       : in     std_logic;
p_out_cfg_done       : out    std_logic;
--p_in_cfg_irq         : in     std_logic;

p_in_cfg_clk         : in     std_logic;

-------------------------------
--Технологический
-------------------------------
p_in_tst             : in     std_logic_vector(31 downto 0);
p_out_tst            : out    std_logic_vector(31 downto 0);

-------------------------------
--System
-------------------------------
p_in_rst             : in     std_logic
);
end component;

component fpga_test_01
generic(
G_BLINK_T05   : integer:=10#125#; -- 1/2 периода мигания светодиода.(время в ms)
G_CLK_T05us   : integer:=10#1000# -- кол-во периодов частоты порта p_in_clk
                                  -- укладывающиес_ в 1/2 периода 1us
);
port
(
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
generic
(
G_CLKIN_CHANGE             : std_logic := '0';
G_CLKSOUTH_CHANGE          : std_logic := '0';
G_CLKNORTH_CHANGE          : std_logic := '0';

G_CLKIN_MUX_VAL            : std_logic_vector(2 downto 0):="011";
G_CLKSOUTH_MUX_VAL         : std_logic := '0';
G_CLKNORTH_MUX_VAL         : std_logic := '0'
);
port(
p_in_drp_rst            : in    std_logic;
p_in_drp_clk            : in    std_logic;

p_out_txp               : out   std_logic_vector(1 downto 0);
p_out_txn               : out   std_logic_vector(1 downto 0);
p_in_rxp                : in    std_logic_vector(1 downto 0);
p_in_rxn                : in    std_logic_vector(1 downto 0);

p_in_clkin              : in    std_logic;
p_out_refclkout         : out   std_logic
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

component memory_ctrl_pll
port
(
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

signal i_dbgcs_sh0_layer                : std_logic_vector(35 downto 0);
signal i_dbgcs_hdd_rambuf               : std_logic_vector(35 downto 0);
signal i_dbgcs_hdd_raid                 : std_logic_vector(35 downto 0);
signal i_dbgcs_cfg                      : std_logic_vector(35 downto 0);
signal i_dbgcs_hwstart_dly              : std_logic_vector(35 downto 0);

signal tst_sh0_llayer   : std_logic_vector(4 downto 0):=(others=>'0');
signal tst_sh1_llayer   : std_logic_vector(4 downto 0):=(others=>'0');
signal tst_trm_timeout  : std_logic_vector(15 downto 0):=(others=>'0');
--signal tst_hdd_mem_dcnt : std_logic_vector(15 downto 0):=(others=>'0');


signal i_usr_rst                        : std_logic;

signal i_refclk200MHz                   : std_logic;
signal g_refclk200MHz                   : std_logic;

signal i_gt_X0Y6_rst                    : std_logic;
signal i_gt_X0Y6_clkin                  : std_logic;
--signal i_gt_X0Y6_refclkout              : std_logic;
--signal g_gt_X0Y6_refclkout              : std_logic;

signal ramclki                          : std_logic_vector(C_MEM_NUM_RAMCLK - 1 downto 0);

signal i_dcm_rst_cnt                    : std_logic_vector(5 downto 0);
signal i_dcm_rst                        : std_logic;

signal g_lbus_clkin                     : std_logic;
--signal g_lbus_clkdiv                    : std_logic;
--signal g_lbus_clk2x                     : std_logic;
signal g_lbus_clkfx                     : std_logic;
signal g_lbus_clk                       : std_logic;
signal lclk_dcm_lock                    : std_logic;

signal g_usr_highclk                    : std_logic;

signal i_memctrl_dcm_lock               : std_logic;

signal i_memctrl_pllclk0                : std_logic;
signal i_memctrl_pllclk45               : std_logic;
signal i_memctrl_pllclk2x0              : std_logic;
signal i_memctrl_pllclk2x90             : std_logic;
signal i_memctrl_pll_rst_out            : std_logic;

signal i_pciexp_gt_refclk               : std_logic;
signal g_pciexp_gt_refclkout            : std_logic;

Type THostDCtrl is array (0 to C_HDEV_COUNT-1) of std_logic;
Type THostDWR is array (0 to C_HDEV_COUNT-1) of std_logic_vector(31 downto 0);
signal i_host_wr                        : THostDCtrl;
signal i_host_rd                        : THostDCtrl;
signal i_host_txd                       : THostDWR;
signal i_host_rxd                       : THostDWR;
signal i_host_rxrdy                     : THostDCtrl;
signal i_host_txrdy                     : THostDCtrl;
signal i_host_rxbuf_empty               : THostDCtrl;
signal i_host_txbuf_full                : THostDCtrl;
signal i_host_irq                       : THostDCtrl;

signal i_host_rdy                       : std_logic;
signal i_host_rst_n                     : std_logic;
signal g_host_clk                       : std_logic;
signal i_host_gctrl                     : std_logic_vector(32-1 downto 0);
signal i_host_dev_status                : std_logic_vector(32-1 downto 0);
signal i_host_dev_irq                   : std_logic_vector(31 downto 0);
signal i_host_dev_option                : std_logic_vector(127 downto 0);
signal i_host_dev_ctrl                  : std_logic_vector(32-1 downto 0);
signal i_host_dev_txd                   : std_logic_vector(32-1 downto 0);
signal i_host_dev_rxd                   : std_logic_vector(32-1 downto 0);
signal i_host_dev_wr                    : std_logic;
signal i_host_dev_rd                    : std_logic;
signal i_host_dev_flag                  : std_logic_vector(7 downto 0);

signal i_host_devadr                    : std_logic_vector(C_HREG_DEV_CTRL_ADR_M_BIT-C_HREG_DEV_CTRL_ADR_L_BIT downto 0);
signal i_host_vchsel                    : std_logic_vector(3 downto 0);
signal i_host_dma_start                 : std_logic;

signal i_host_rst_all                   : std_logic;
signal i_host_rst_eth                   : std_logic;
signal i_host_rst_mem                   : std_logic;
signal i_host_rddone_vctrl              : std_logic;
signal i_host_rddone_trcnik             : std_logic;

Type THDevWidthCnt is array (0 to C_HDEV_COUNT-1) of std_logic_vector(2 downto 0);
signal i_hdev_dma_start                 : std_logic_vector(C_HDEV_COUNT-1 downto 0);
signal hclk_hdev_dma_start              : std_logic_vector(C_HDEV_COUNT-1 downto 0);
signal hclk_hdev_dma_start_cnt          : THDevWidthCnt;

signal hclk_hmem_ce                     : std_logic;
signal hclk_hmem_ce_cnt                 : std_logic_vector(2 downto 0);
signal i_hmem_ce                        : std_logic;

signal i_host_tst_in                    : std_logic_vector(127 downto 0);
signal i_host_tst_out                   : std_logic_vector(127 downto 0);
signal i_host_tst2_out                  : std_logic_vector(171 downto 0);

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
signal g_eth_gt_refclkout               : std_logic;
signal i_eth_rst                        : std_logic;
signal i_eth_rdy                        : std_logic;
signal i_eth_carier                     : std_logic;
signal i_eth_module_gt_plllkdet         : std_logic;
signal i_eth_rxd_sof                    : std_logic;
signal i_eth_rxd_eof                    : std_logic;
signal i_eth_rxbuf_din                  : std_logic_vector(31 downto 0);
signal i_eth_rxbuf_wr                   : std_logic;
signal i_eth_rxbuf_full                 : std_logic;
signal i_eth_txbuf_dout                 : std_logic_vector(31 downto 0);
signal i_eth_txbuf_rd                   : std_logic;
signal i_eth_txbuf_empty                : std_logic;
signal i_eth_tst_out                    : std_logic_vector(31 downto 0);

signal i_hdd_rst                        : std_logic;
signal i_hdd_gt_refclk150               : std_logic_vector(C_SH_COUNT_MAX(C_HDD_COUNT-1)-1 downto 0);
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

signal i_hdd_memarb_req                 : std_logic;
signal i_hdd_memarb_en                  : std_logic;
signal i_hdd_mem_bank1h                 : std_logic_vector(15 downto 0);
signal i_hdd_mem_ce                     : std_logic;
signal i_hdd_mem_cw                     : std_logic;
signal i_hdd_mem_term                   : std_logic;
signal i_hdd_mem_wr                     : std_logic;
signal i_hdd_mem_rd                     : std_logic;
signal i_hdd_mem_adr                    : std_logic_vector(C_MEMCTRL_ADDR_WIDTH - 1 downto 0);
signal i_hdd_mem_be                     : std_logic_vector(C_MEMCTRL_DATA_WIDTH / 8 - 1 downto 0);
signal i_hdd_mem_din                    : std_logic_vector(C_MEMCTRL_DATA_WIDTH - 1 downto 0);
signal i_hdd_mem_dout                   : std_logic_vector(C_MEMCTRL_DATA_WIDTH - 1 downto 0);
signal i_hdd_mem_wf                     : std_logic;
signal i_hdd_mem_wpf                    : std_logic;
signal i_hdd_mem_re                     : std_logic;
signal i_hdd_mem_rpe                    : std_logic;
--signal i_hdd_mem_clk                    : std_logic;

signal i_dsntst_rst                     : std_logic;
signal i_dsntst_txdata_rdy              : std_logic;
signal i_dsntst_txdata_dout             : std_logic_vector(31 downto 0);
signal i_dsntst_txdata_wd               : std_logic;
signal i_dsntst_txbuf_empty             : std_logic;
signal i_dsntst_txbuf_full              : std_logic;
signal i_dsntst_bufclk                  : std_logic;
signal i_dsntst_tst_out                 : std_logic_vector(31 downto 0);

signal i_tmr_rst                        : std_logic;
signal i_tmr_hirq                       : std_logic_vector(C_DSN_TMR_COUNT_TMR-1 downto 0);

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
signal i_vctrl_hirq                     : std_logic_vector(C_DSN_VCTRL_VCH_COUNT-1 downto 0);
signal i_vctrl_hrdy                     : std_logic_vector(C_DSN_VCTRL_VCH_COUNT-1 downto 0);
signal i_vctrl_hirq_out                 : std_logic_vector(C_DSN_VCTRL_VCH_MAX_COUNT-1 downto 0);
signal i_vctrl_hrdy_out                 : std_logic_vector(C_DSN_VCTRL_VCH_MAX_COUNT-1 downto 0);
signal i_vctrl_hfrmrk                   : std_logic_vector(31 downto 0);
signal i_vctrl_vrd_done                 : std_logic;
signal i_vctrl_tst_out                  : std_logic_vector(31 downto 0);
signal i_vctrl_vrdprms                  : TReaderVCHParams;
signal i_vctrl_vfrdy                    : std_logic_vector(C_DSN_VCTRL_VCH_COUNT-1 downto 0);
signal i_vctrl_vrowmrk                  : TVMrks;

signal i_vctrlrd_memarb_req             : std_logic;
signal i_vctrlrd_memarb_en              : std_logic;
signal i_vctrlrd_mem_bank1h             : std_logic_vector(15 downto 0);
signal i_vctrlrd_mem_ce                 : std_logic;
signal i_vctrlrd_mem_cw                 : std_logic;
signal i_vctrlrd_mem_term               : std_logic;
signal i_vctrlrd_mem_rd                 : std_logic;
signal i_vctrlrd_mem_wr                 : std_logic;
signal i_vctrlrd_mem_adr                : std_logic_vector(C_MEMCTRL_ADDR_WIDTH - 1 downto 0);
signal i_vctrlrd_mem_be                 : std_logic_vector(C_MEMCTRL_DATA_WIDTH / 8 - 1 downto 0);
signal i_vctrlrd_mem_din                : std_logic_vector(C_MEMCTRL_DATA_WIDTH - 1 downto 0);
signal i_vctrlrd_mem_dout               : std_logic_vector(C_MEMCTRL_DATA_WIDTH - 1 downto 0);
signal i_vctrlrd_mem_wf                 : std_logic;
signal i_vctrlrd_mem_wpf                : std_logic;
signal i_vctrlrd_mem_re                 : std_logic;
signal i_vctrlrd_mem_rpe                : std_logic;
--signal i_vctrlrd_mem_clk                : std_logic;

signal i_vctrlwr_memarb_req             : std_logic;
signal i_vctrlwr_memarb_en              : std_logic;
signal i_vctrlwr_mem_bank1h             : std_logic_vector(15 downto 0);
signal i_vctrlwr_mem_ce                 : std_logic;
signal i_vctrlwr_mem_cw                 : std_logic;
signal i_vctrlwr_mem_term               : std_logic;
signal i_vctrlwr_mem_rd                 : std_logic;
signal i_vctrlwr_mem_wr                 : std_logic;
signal i_vctrlwr_mem_adr                : std_logic_vector(C_MEMCTRL_ADDR_WIDTH - 1 downto 0);
signal i_vctrlwr_mem_be                 : std_logic_vector(C_MEMCTRL_DATA_WIDTH / 8 - 1 downto 0);
signal i_vctrlwr_mem_din                : std_logic_vector(C_MEMCTRL_DATA_WIDTH - 1 downto 0);
signal i_vctrlwr_mem_dout               : std_logic_vector(C_MEMCTRL_DATA_WIDTH - 1 downto 0);
signal i_vctrlwr_mem_wf                 : std_logic;
signal i_vctrlwr_mem_wpf                : std_logic;
signal i_vctrlwr_mem_re                 : std_logic;
signal i_vctrlwr_mem_rpe                : std_logic;
--signal i_vctrlwr_mem_clk                : std_logic;

signal i_trc_busy                       : std_logic_vector(C_DSN_VCTRL_VCH_COUNT-1 downto 0);
signal i_trc_vbufs                      : TVfrBufs;
signal i_trcnik_hdrdy                   : std_logic:='0';

signal i_memctrl_rst                    : std_logic;
signal i_host_mem_ctl_reg               : std_logic_vector(0 downto 0);
signal i_host_mem_mode_reg              : std_logic_vector(511 downto 0);
signal i_host_mem_locked                : std_logic_vector(7 downto 0);
signal i_host_mem_trained               : std_logic_vector(max_num_bank - 1 downto 0);

signal i_host_mem_bank1h                : std_logic_vector(15 downto 0);
signal i_host_mem_ce                    : std_logic;
signal i_host_mem_cw                    : std_logic;
signal i_host_mem_term                  : std_logic;
signal i_host_mem_wr                    : std_logic;
signal i_host_mem_rd                    : std_logic;
signal i_host_mem_adr                   : std_logic_vector(C_MEMCTRL_ADDR_WIDTH - 1 downto 0);
signal i_host_mem_be                    : std_logic_vector(C_MEMCTRL_DATA_WIDTH / 8 -1 downto 0);
signal i_host_mem_din                   : std_logic_vector(C_MEMCTRL_DATA_WIDTH - 1 downto 0);
signal i_host_mem_dout                  : std_logic_vector(C_MEMCTRL_DATA_WIDTH - 1 downto 0);
signal i_host_mem_wf                    : std_logic;
signal i_host_mem_wpf                   : std_logic;
signal i_host_mem_re                    : std_logic;
signal i_host_mem_rpe                   : std_logic;

--signal i_mem_arb1_clk                   : std_logic;
signal i_mem_arb1_bank1h                : std_logic_vector(15 downto 0);
signal i_mem_arb1_ce                    : std_logic;
signal i_mem_arb1_cw                    : std_logic;
signal i_mem_arb1_term                  : std_logic;
signal i_mem_arb1_rd                    : std_logic;
signal i_mem_arb1_wr                    : std_logic;
signal i_mem_arb1_adr                   : std_logic_vector(C_MEMCTRL_ADDR_WIDTH - 1 downto 0);
signal i_mem_arb1_be                    : std_logic_vector(C_MEMCTRL_DATA_WIDTH / 8 - 1 downto 0);
signal i_mem_arb1_din                   : std_logic_vector(C_MEMCTRL_DATA_WIDTH - 1 downto 0);
signal i_mem_arb1_dout                  : std_logic_vector(C_MEMCTRL_DATA_WIDTH - 1 downto 0);
signal i_mem_arb1_wf                    : std_logic;
signal i_mem_arb1_wpf                   : std_logic;
signal i_mem_arb1_re                    : std_logic;
signal i_mem_arb1_rpe                   : std_logic;
signal i_mem_arb1_tst_out               : std_logic_vector(31 downto 0);
signal i_mem_arb1_dout_tmp              : std_logic_vector(C_MEMCTRL_DATA_WIDTH - 1 downto 0);
signal i_mem_arb1_wf_tmp                : std_logic;
signal i_mem_arb1_wpf_tmp               : std_logic;
signal i_mem_arb1_re_tmp                : std_logic;
signal i_mem_arb1_rpe_tmp               : std_logic;
signal i_sim_mem_arb1_read_dly_cnt      : std_logic_vector(3 downto 0);
signal i_sim_mem_arb1_read_dly          : std_logic;

signal i_mem_null_bank1h                : std_logic_vector(15 downto 0);
signal i_mem_null_ce                    : std_logic;
signal i_mem_null_cw                    : std_logic;
signal i_mem_null_term                  : std_logic;
signal i_mem_null_rd                    : std_logic;
signal i_mem_null_wr                    : std_logic;
signal i_mem_null_adr                   : std_logic_vector(C_MEMCTRL_ADDR_WIDTH - 1 downto 0);
signal i_mem_null_be                    : std_logic_vector(C_MEMCTRL_DATA_WIDTH / 8 - 1 downto 0);
signal i_mem_null_din                   : std_logic_vector(C_MEMCTRL_DATA_WIDTH - 1 downto 0);
signal i_mem_null_dout                  : std_logic_vector(C_MEMCTRL_DATA_WIDTH - 1 downto 0);
signal i_mem_null_wf                    : std_logic;
signal i_mem_null_wpf                   : std_logic;
signal i_mem_null_re                    : std_logic;
signal i_mem_null_rpe                   : std_logic;

--
-- If the synthesizer replicates an asynchronous reset signal due high fanout,
-- this can prevent flip-flops being mapped into IOBs. We set the maximum
-- fanout for such nets to a high enough value that replication never occurs.
--
attribute MAX_FANOUT : string;
attribute MAX_FANOUT of i_memctrl_rst : signal is "100000";

attribute keep : string;
attribute keep of g_host_clk : signal is "true";

signal i_test01_led     : std_logic:='0';
signal tst_clr          : std_logic:='0';

signal ra1     : std_logic_vector(C_MEM_BANK1.ra_width - 1 downto 0);
signal rc1     : std_logic_vector(C_MEM_BANK1.rc_width - 1 downto 0);
signal rd1     : std_logic_vector(C_MEM_BANK1.rd_width - 1 downto 0);
signal ra2     : std_logic_vector(C_MEM_BANK2.ra_width - 1 downto 0);
signal rc2     : std_logic_vector(C_MEM_BANK2.rc_width - 1 downto 0);
signal rd2     : std_logic_vector(C_MEM_BANK2.rd_width - 1 downto 0);
signal ra3     : std_logic_vector(C_MEM_BANK3.ra_width - 1 downto 0);
signal rc3     : std_logic_vector(C_MEM_BANK3.rc_width - 1 downto 0);
signal rd3     : std_logic_vector(C_MEM_BANK3.rd_width - 1 downto 0);
signal ra4     : std_logic_vector(C_MEM_BANK4.ra_width - 1 downto 0);
signal rc4     : std_logic_vector(C_MEM_BANK4.rc_width - 1 downto 0);
signal rd4     : std_logic_vector(C_MEM_BANK4.rd_width - 1 downto 0);
signal ra5     : std_logic_vector(C_MEM_BANK5.ra_width - 1 downto 0);
signal rc5     : std_logic_vector(C_MEM_BANK5.rc_width - 1 downto 0);
signal rd5     : std_logic_vector(C_MEM_BANK5.rd_width - 1 downto 0);
signal ra6     : std_logic_vector(C_MEM_BANK6.ra_width - 1 downto 0);
signal rc6     : std_logic_vector(C_MEM_BANK6.rc_width - 1 downto 0);
signal rd6     : std_logic_vector(C_MEM_BANK6.rd_width - 1 downto 0);
signal ra7     : std_logic_vector(C_MEM_BANK7.ra_width - 1 downto 0);
signal rc7     : std_logic_vector(C_MEM_BANK7.rc_width - 1 downto 0);
signal rd7     : std_logic_vector(C_MEM_BANK7.rd_width - 1 downto 0);
signal ra8     : std_logic_vector(C_MEM_BANK8.ra_width - 1 downto 0);
signal rc8     : std_logic_vector(C_MEM_BANK8.rc_width - 1 downto 0);
signal rd8     : std_logic_vector(C_MEM_BANK8.rd_width - 1 downto 0);
signal ra9     : std_logic_vector(C_MEM_BANK9.ra_width - 1 downto 0);
signal rc9     : std_logic_vector(C_MEM_BANK9.rc_width - 1 downto 0);
signal rd9     : std_logic_vector(C_MEM_BANK9.rd_width - 1 downto 0);
signal ra10    : std_logic_vector(C_MEM_BANK10.ra_width - 1 downto 0);
signal rc10    : std_logic_vector(C_MEM_BANK10.rc_width - 1 downto 0);
signal rd10    : std_logic_vector(C_MEM_BANK10.rd_width - 1 downto 0);
signal ra11    : std_logic_vector(C_MEM_BANK11.ra_width - 1 downto 0);
signal rc11    : std_logic_vector(C_MEM_BANK11.rc_width - 1 downto 0);
signal rd11    : std_logic_vector(C_MEM_BANK11.rd_width - 1 downto 0);
signal ra12    : std_logic_vector(C_MEM_BANK12.ra_width - 1 downto 0);
signal rc12    : std_logic_vector(C_MEM_BANK12.rc_width - 1 downto 0);
signal rd12    : std_logic_vector(C_MEM_BANK12.rd_width - 1 downto 0);
signal ra13    : std_logic_vector(C_MEM_BANK13.ra_width - 1 downto 0);
signal rc13    : std_logic_vector(C_MEM_BANK13.rc_width - 1 downto 0);
signal rd13    : std_logic_vector(C_MEM_BANK13.rd_width - 1 downto 0);
signal ra14    : std_logic_vector(C_MEM_BANK14.ra_width - 1 downto 0);
signal rc14    : std_logic_vector(C_MEM_BANK14.rc_width - 1 downto 0);
signal rd14    : std_logic_vector(C_MEM_BANK14.rd_width - 1 downto 0);
signal ra15    : std_logic_vector(C_MEM_BANK15.ra_width - 1 downto 0);
signal rc15    : std_logic_vector(C_MEM_BANK15.rc_width - 1 downto 0);
signal rd15    : std_logic_vector(C_MEM_BANK15.rd_width - 1 downto 0);
signal ramclko : std_logic_vector(C_MEM_NUM_RAMCLK - 1 downto 0);

begin

ramclki <= (others => '-');


i_mem_null_bank1h<=(others=>'0');
i_mem_null_ce<='0';
i_mem_null_cw<='0';
i_mem_null_term<='0';
i_mem_null_rd<='0';
i_mem_null_wr<='0';
i_mem_null_adr<=(others=>'0');
i_mem_null_be<=(others=>'0');
i_mem_null_din<=(others=>'0');


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
i_dsntst_rst <=not i_host_rst_n or i_host_rst_all;
i_memctrl_rst<=not i_host_rst_n or i_host_rst_all or i_host_rst_mem;
i_hdd_rst    <=not i_host_rst_n or i_host_rst_all or i_usr_rst;


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
--          Установка частот проекта:
--***********************************************************
--//Input 200MHz reference clock for IDELAY / ODELAY elements
ibufg_refclk : IBUFGDS_LVPECL_25 port map(I  => pin_in_refclk200M_p, IB => pin_in_refclk200M_n, O  => i_refclk200MHz);
bufg_refclk  : BUFG              port map(I  => i_refclk200MHz, O  => g_refclk200MHz);

--//Input 100MHz reference clock for PCI-EXPRESS
ibuf_pciexp_gt_refclk : IBUFDS port map (I=>pin_in_pciexp_clk_p, IB=> pin_in_pciexp_clk_n, O=>i_pciexp_gt_refclk );

--//Input 150MHz reference clock for SATA
gen_sata_gt : for i in 0 to C_SH_COUNT_MAX(C_HDD_COUNT-1)-1 generate
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
p_out_refclkout => open --i_gt_X0Y6_refclkout
);

----//Буду использовать g_gt_X0Y6_refclkout для тактирования блока GTP_X0Y7/DRP (Ethernet)
--bufg_gt_X0Y6_refclk  : BUFG port map(I  => i_gt_X0Y6_refclkout, O  => g_gt_X0Y6_refclkout);

--//Input 125MHz reference clock for GTP_X0Y7 Eth_MAC0
--//В данном проекте опорная частота для GTP_X0Y7 будет браться не с диф. пинов pin_in_eth_clk_n/p, а
--//с линии CLKINNORTH (более подробно см. xilinx manual ug196.pdf/Appendix F)
ibufds_gt_eth_refclk : IBUFDS port map(I  => pin_in_eth_clk_p, IB => pin_in_eth_clk_n, O  => i_eth_gt_refclk125);

--//DCM Local Bus
m_dcm_lbus : lbus_dcm
generic map(
G_CLKFX_DIV  => 1,
G_CLKFX_MULT => C_LBUSDCM_CLKFX_M
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
m_pll_mem_ctrl : memory_ctrl_pll
port map(
mclk      => g_refclk200MHz,--g_lbus_clkfx,--
rst       => i_memctrl_rst,
refclk200 => g_refclk200MHz,

clk0      => i_memctrl_pllclk0,
clk45     => i_memctrl_pllclk45,
clk2x0    => i_memctrl_pllclk2x0,
clk2x90   => i_memctrl_pllclk2x90,
locked    => i_host_mem_locked(1 downto 0),
memrst    => i_memctrl_pll_rst_out
);
i_host_mem_locked(7 downto 2)<=(others=>'0');

i_memctrl_dcm_lock<=i_host_mem_locked(0);
g_usr_highclk<=i_memctrl_pllclk2x0;


--***********************************************************
--              Модули устройств проекта:
--***********************************************************

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

--//Распределяем управление от блока конфигурирования(cfgdev.vhd) для соотв. модуля проекта:
i_cfg_rxd<=i_cfg_rxd_dev(C_CFGDEV_ETHG)    when i_cfg_dadr(3 downto 0)=CONV_STD_LOGIC_VECTOR(C_CFGDEV_ETHG, 4)    else
           i_cfg_rxd_dev(C_CFGDEV_VCTRL)   when i_cfg_dadr(3 downto 0)=CONV_STD_LOGIC_VECTOR(C_CFGDEV_VCTRL, 4)   else
           i_cfg_rxd_dev(C_CFGDEV_SWT)     when i_cfg_dadr(3 downto 0)=CONV_STD_LOGIC_VECTOR(C_CFGDEV_SWT, 4)     else
           i_cfg_rxd_dev(C_CFGDEV_TMR)     when i_cfg_dadr(3 downto 0)=CONV_STD_LOGIC_VECTOR(C_CFGDEV_TMR, 4)     else
           i_cfg_rxd_dev(C_CFGDEV_HDD)     when i_cfg_dadr(3 downto 0)=CONV_STD_LOGIC_VECTOR(C_CFGDEV_HDD, 4)     else
           i_cfg_rxd_dev(C_CFGDEV_TESTING) when i_cfg_dadr(3 downto 0)=CONV_STD_LOGIC_VECTOR(C_CFGDEV_TESTING, 4) else
--           i_cfg_rxd_dev(C_CFGDEV_TRCNIK)  when i_cfg_dadr(3 downto 0)=CONV_STD_LOGIC_VECTOR(C_CFGDEV_TRCNIK, 4)  else
           (others=>'0');

gen_cfg_dev : for i in 0 to C_CFGDEV_COUNT-1 generate
i_cfg_wr_dev(i)   <=i_cfg_wr   when i_cfg_dadr=i else '0';
i_cfg_rd_dev(i)   <=i_cfg_rd   when i_cfg_dadr=i else '0';
i_cfg_done_dev(i) <=i_cfg_done when i_cfg_dadr=i else '0';
end generate gen_cfg_dev;


--***********************************************************
--Проект модуля Таймер
--***********************************************************
m_timers : dsn_timer
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
p_in_tmr_clk      => g_pciexp_gt_refclkout,
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
m_switch : dsn_switch
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
p_in_hdd_tstgen           => i_hdd_rbuf_cfg.tstgen,
p_in_hdd_vbuf_rdclk       => g_usr_highclk,

p_in_hdd_vbuf_dout        => i_hdd_vbuf_dout,
p_in_hdd_vbuf_rd          => i_hdd_vbuf_rd,
p_out_hdd_vbuf_empty      => i_hdd_vbuf_empty,
p_out_hdd_vbuf_full       => i_hdd_vbuf_full,
p_out_hdd_vbuf_pfull      => i_hdd_vbuf_pfull,
p_out_hdd_vbuf_wrcnt      => i_hdd_vbuf_wrcnt,

-------------------------------
-- Связь с Eth(dsn_ethg.vhd) (ethg_clk domain)
-------------------------------
p_in_eth_clk              => g_eth_gt_refclkout,

p_in_eth_rxd_sof          => i_eth_rxd_sof,
p_in_eth_rxd_eof          => i_eth_rxd_eof,
p_in_eth_rxbuf_din        => i_eth_rxbuf_din,
p_in_eth_rxbuf_wr         => i_eth_rxbuf_wr,
p_out_eth_rxbuf_empty     => i_host_rxbuf_empty(C_HDEV_ETH_DBUF),
p_out_eth_rxbuf_full      => i_eth_rxbuf_full,

p_out_eth_txbuf_dout      => i_eth_txbuf_dout,
p_in_eth_txbuf_rd         => i_eth_txbuf_rd,
p_out_eth_txbuf_empty     => i_eth_txbuf_empty,
p_out_eth_txbuf_full      => i_host_txbuf_full(C_HDEV_ETH_DBUF),


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
p_out_dsntst_bufclk       => i_dsntst_bufclk,

p_in_dsntst_txd_rdy       => i_dsntst_txdata_rdy,
p_in_dsntst_txbuf_din     => i_dsntst_txdata_dout,
p_in_dsntst_txbuf_wr      => i_dsntst_txdata_wd,
p_out_dsntst_txbuf_empty  => i_dsntst_txbuf_empty,
p_out_dsntst_txbuf_full   => i_dsntst_txbuf_full,


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
--Проект Gigabit Ethernet - dsn_ethg.vhd
--***********************************************************
m_ethg : dsn_ethg
generic map(
G_MODULE_USE => C_USE_ETH,
G_DBG        => G_DBG_ETH,
G_SIM        => G_SIM
)
port map(
-------------------------------
-- Конфигурирование модуля dsn_ethg.vhd (host_clk domain)
-------------------------------
p_in_cfg_clk          => g_host_clk,

p_in_cfg_adr          => i_cfg_radr(7 downto 0),
p_in_cfg_adr_ld       => i_cfg_radr_ld,
p_in_cfg_adr_fifo     => i_cfg_radr_fifo,

p_in_cfg_txdata       => i_cfg_txd,
p_in_cfg_wd           => i_cfg_wr_dev(C_CFGDEV_ETHG),

p_out_cfg_rxdata      => i_cfg_rxd_dev(C_CFGDEV_ETHG),
p_in_cfg_rd           => i_cfg_rd_dev(C_CFGDEV_ETHG),

p_in_cfg_done         => i_cfg_done_dev(C_CFGDEV_ETHG),
p_in_cfg_rst          => i_cfg_rst,

-------------------------------
-- STATUS модуля dsn_ethg.vhd
-------------------------------
p_out_eth_rdy          => i_eth_rdy,
p_out_eth_error        => i_eth_carier,
p_out_eth_gt_plllkdet  => i_eth_module_gt_plllkdet,

p_out_sfp_tx_dis       => pin_out_sfp_tx_dis,
p_in_sfp_sd            => pin_in_sfp_sd,

-------------------------------
-- Связь с буферами модуля dsn_switch.vhd
-------------------------------
p_out_eth_rxbuf_din    => i_eth_rxbuf_din,
p_out_eth_rxbuf_wr     => i_eth_rxbuf_wr,
p_in_eth_rxbuf_full    => i_eth_rxbuf_full,
p_out_eth_rxd_sof      => i_eth_rxd_sof,
p_out_eth_rxd_eof      => i_eth_rxd_eof,

p_in_eth_txbuf_dout    => i_eth_txbuf_dout,
p_out_eth_txbuf_rd     => i_eth_txbuf_rd,
p_in_eth_txbuf_empty   => i_eth_txbuf_empty,

--------------------------------------------------
--ETH Driver
--------------------------------------------------
p_out_eth_gt_txp       => pin_out_eth_txp,
p_out_eth_gt_txn       => pin_out_eth_txn,
p_in_eth_gt_rxp        => pin_in_eth_rxp,
p_in_eth_gt_rxn        => pin_in_eth_rxn,

p_in_eth_gt_refclk     => i_eth_gt_refclk125,
p_out_eth_gt_refclkout => g_eth_gt_refclkout,
p_in_eth_gt_drpclk     => g_pciexp_gt_refclkout,

-------------------------------
--Технологический
-------------------------------
p_in_tst               => (others=>'0'),
p_out_tst              => i_eth_tst_out,

-------------------------------
--System
-------------------------------
p_in_rst               => i_eth_rst
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
--Проект модуля видео контролера - dsn_video_ctrl.vhd
--***********************************************************
i_vctrl_hirq_out<=EXT(i_vctrl_hirq, i_vctrl_hirq_out'length);
i_vctrl_hrdy_out<=EXT(i_vctrl_hrdy, i_vctrl_hrdy_out'length);

m_video_ctrl : dsn_video_ctrl
generic map(
G_SIMPLE => C_DSN_VCTRL_SIMPLE,
G_SIM    => G_SIM
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

-----------------------------------
---- Связь с memory_ctrl.vhd
-----------------------------------
--//CH WRITE
p_out_memarb_wrreq   => i_vctrlwr_memarb_req,
p_in_memarb_wren     => i_vctrlwr_memarb_en,

p_out_memwr_bank1h   => i_vctrlwr_mem_bank1h,
p_out_memwr_ce       => i_vctrlwr_mem_ce,
p_out_memwr_cw       => i_vctrlwr_mem_cw,
p_out_memwr_rd       => i_vctrlwr_mem_rd,
p_out_memwr_wr       => i_vctrlwr_mem_wr,
p_out_memwr_term     => i_vctrlwr_mem_term,
p_out_memwr_adr      => i_vctrlwr_mem_adr,
p_out_memwr_be       => i_vctrlwr_mem_be,
p_out_memwr_din      => i_vctrlwr_mem_din,
p_in_memwr_dout      => i_vctrlwr_mem_dout,

p_in_memwr_wf        => i_vctrlwr_mem_wf,
p_in_memwr_wpf       => i_vctrlwr_mem_wpf,
p_in_memwr_re        => i_vctrlwr_mem_re,
p_in_memwr_rpe       => i_vctrlwr_mem_rpe,

--//CH READ
p_out_memarb_rdreq   => i_vctrlrd_memarb_req,
p_in_memarb_rden     => i_vctrlrd_memarb_en,

p_out_memrd_bank1h   => i_vctrlrd_mem_bank1h,
p_out_memrd_ce       => i_vctrlrd_mem_ce,
p_out_memrd_cw       => i_vctrlrd_mem_cw,
p_out_memrd_rd       => i_vctrlrd_mem_rd,
p_out_memrd_wr       => i_vctrlrd_mem_wr,
p_out_memrd_term     => i_vctrlrd_mem_term,
p_out_memrd_adr      => i_vctrlrd_mem_adr,
p_out_memrd_be       => i_vctrlrd_mem_be,
p_out_memrd_din      => i_vctrlrd_mem_din,
p_in_memrd_dout      => i_vctrlrd_mem_dout,

p_in_memrd_wf        => i_vctrlrd_mem_wf,
p_in_memrd_wpf       => i_vctrlrd_mem_wpf,
p_in_memrd_re        => i_vctrlrd_mem_re,
p_in_memrd_rpe       => i_vctrlrd_mem_rpe,

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


m_hdd : dsn_hdd
generic map(
G_MODULE_USE=> C_USE_HDD,
G_HDD_COUNT => C_HDD_COUNT,
G_GT_DBUS   => C_HDD_GT_DBUS,
G_DBG       => C_DBG_HDD,
G_DBGCS     => C_DBGCS_HDD,
G_SIM       => G_SIM
)
port map(
-------------------------------
-- Конфигурирование модуля dsn_hdd.vhd (p_in_cfg_clk domain)
-------------------------------
p_in_cfg_if           => i_host_tst_out(0),
p_in_cfg_clk          => g_host_clk,

p_in_cfg_adr          => i_cfghdd_radr(7 downto 0),
p_in_cfg_adr_ld       => i_cfghdd_radr_ld,
p_in_cfg_adr_fifo     => i_cfghdd_radr_fifo,

p_in_cfg_txdata       => i_cfghdd_txdata,
p_in_cfg_wd           => i_cfghdd_wr,
p_out_cfg_txrdy       => i_cfghdd_txrdy,

p_out_cfg_rxdata      => i_cfghdd_rxdata,
p_in_cfg_rd           => i_cfghdd_rd,
p_out_cfg_rxrdy       => i_cfghdd_rxrdy,

p_in_cfg_done         => i_cfghdd_done,
p_in_cfg_rst          => i_cfg_rst,

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

p_out_sim_gt_txdata         => open,--i_hdd_sim_gt_txdata,
p_out_sim_gt_txcharisk      => open,--i_hdd_sim_gt_txcharisk,
p_out_sim_gt_txcomstart     => open,--i_hdd_sim_gt_txcomstart,
p_in_sim_gt_rxdata          => i_hdd_sim_gt_rxdata,
p_in_sim_gt_rxcharisk       => i_hdd_sim_gt_rxcharisk,
p_in_sim_gt_rxstatus        => i_hdd_sim_gt_rxstatus,
p_in_sim_gt_rxelecidle      => i_hdd_sim_gt_rxelecidle,
p_in_sim_gt_rxdisperr       => i_hdd_sim_gt_rxdisperr,
p_in_sim_gt_rxnotintable    => i_hdd_sim_gt_rxnotintable,
p_in_sim_gt_rxbyteisaligned => i_hdd_sim_gt_rxbyteisaligned,
p_out_gt_sim_rst            => open,--i_hdd_sim_gt_sim_rst,
p_out_gt_sim_clk            => open,--i_hdd_sim_gt_sim_clk,

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
G_MODULE_USE  => C_USE_HDD,
G_RAMBUF_SIZE => C_HDD_RAMBUF_SIZE,
G_DBGCS       => C_DBGCS_HDD,
G_SIM         => G_SIM
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
-- Связь с memory_ctrl.vhd
---------------------------------
p_out_memarb_req    => i_hdd_memarb_req,
p_in_memarb_en      => i_hdd_memarb_en,

p_out_mem_bank1h    => i_hdd_mem_bank1h,
p_out_mem_ce        => i_hdd_mem_ce,
p_out_mem_cw        => i_hdd_mem_cw,
p_out_mem_rd        => i_hdd_mem_rd,
p_out_mem_wr        => i_hdd_mem_wr,
p_out_mem_term      => i_hdd_mem_term,
p_out_mem_adr       => i_hdd_mem_adr,
p_out_mem_be        => i_hdd_mem_be,
p_out_mem_din       => i_hdd_mem_din,
p_in_mem_dout       => i_hdd_mem_dout,

p_in_mem_wf         => i_hdd_mem_wf,
p_in_mem_wpf        => i_hdd_mem_wpf,
p_in_mem_re         => i_hdd_mem_re,
p_in_mem_rpe        => i_hdd_mem_rpe,

p_out_mem_clk       => open,

-------------------------------
--Технологический
-------------------------------
p_in_tst            => "00000000000000000000000000000000",
p_out_tst           => i_hdd_rbuf_tst_out,
p_out_dbgcs         => i_hdd_rambuf_dbgcs,

-------------------------------
--System
-------------------------------
p_in_clk => g_usr_highclk,
p_in_rst => i_hdd_rst
);


--***********************************************************
--Проект модуля хоста - dsn_host.vhd
--***********************************************************
m_host : dsn_host
generic map(
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
p_in_usr_tst       => i_host_tst_in,
p_out_usr_tst      => i_host_tst_out,

p_out_hclk         => g_host_clk,
p_out_gctrl        => i_host_gctrl,

p_out_dev_ctrl     => i_host_dev_ctrl,
p_out_dev_din      => i_host_dev_txd,
p_in_dev_dout      => i_host_dev_rxd,
p_out_dev_wd       => i_host_dev_wr,
p_out_dev_rd       => i_host_dev_rd,
p_in_dev_flag      => i_host_dev_flag,
p_in_dev_status    => i_host_dev_status,
p_in_dev_irq       => i_host_dev_irq,
p_in_dev_option    => i_host_dev_option,

p_out_mem_bank1h   => open,--i_host_mem_bank1h,
p_out_mem_ce       => i_host_mem_ce,
p_out_mem_cw       => i_host_mem_cw,
p_out_mem_rd       => i_host_mem_rd,
p_out_mem_wr       => i_host_mem_wr,
p_out_mem_term     => i_host_mem_term,
p_out_mem_be       => i_host_mem_be,
p_out_mem_adr      => i_host_mem_adr,
p_out_mem_din      => i_host_mem_din,
p_in_mem_dout      => i_host_mem_dout,

p_in_mem_wf        => i_host_mem_wf,
p_in_mem_wpf       => i_host_mem_wpf,
p_in_mem_re        => i_host_mem_re,
p_in_mem_rpe       => i_host_mem_rpe,

--//-------------------------------------------------------
--// Технологический
--//-------------------------------------------------------
p_in_tst           => (others=>'0'),
p_out_tst          => i_host_tst2_out,

--------------------------------------------------
--System
--------------------------------------------------
p_out_module_rdy   => i_host_rdy,
p_in_rst_n         => i_host_rst_n
);

--i_host_tst_in(20 downto 0)<=i_host_tst_out(20 downto 0);
--i_host_tst_in(27 downto 21)<=i_host_tst_out(27 downto 21);
--i_host_tst_in(37 downto 28)<=i_host_tst_out(37 downto 28);
--i_host_tst_in(46 downto 38)<=i_host_tst_out(46 downto 38);
--i_host_tst_in(63 downto 47)<=i_host_tst_out(63 downto 47);

i_host_tst_in(71 downto 64)<=i_vctrl_tst_out(23 downto 16);
i_host_tst_in(72)<=i_eth_module_gt_plllkdet;
i_host_tst_in(73)<=lclk_dcm_lock;
i_host_tst_in(74)<=i_hdd_gt_plldet and i_hdd_dcm_lock;
i_host_tst_in(75)<=i_memctrl_dcm_lock;
i_host_tst_in(76)<=AND_reduce(i_host_mem_trained(C_MEMCTRL_BANK_COUNT downto 0));
i_host_tst_in(126 downto 77)<=(others=>'0');
i_host_tst_in(127)<=i_vctrl_tst_out(0) xor
                    i_mem_arb1_tst_out(0) xor i_hdd_tst_out(0);-- i_hdd_rbuf_tst_out(0) or i_swt_tst_out(0);


--//Распределяем управление от хоста для соотв. модуля проекта:
i_host_rst_all<=i_host_gctrl(C_HREG_CTRL_RST_ALL_BIT);
i_host_rst_eth<=i_host_gctrl(C_HREG_CTRL_RST_ETH_BIT);
i_host_rst_mem<=i_host_gctrl(C_HREG_CTRL_RST_MEM_BIT);
i_host_rddone_vctrl<=i_host_gctrl(C_HREG_CTRL_RDDONE_VCTRL_BIT);
i_host_rddone_trcnik<=i_host_gctrl(C_HREG_CTRL_RDDONE_TRCNIK_BIT);

i_host_dma_start<=i_host_dev_ctrl(C_HREG_DEV_CTRL_DMA_START_BIT);
i_host_devadr<=i_host_dev_ctrl(C_HREG_DEV_CTRL_ADR_M_BIT downto C_HREG_DEV_CTRL_ADR_L_BIT);
i_host_vchsel<=EXT(i_host_dev_ctrl(C_HREG_DEV_CTRL_VCH_M_BIT downto C_HREG_DEV_CTRL_VCH_L_BIT), i_host_vchsel'length);


--//Статусы устр-в
i_host_dev_status(C_HREG_DEV_STATUS_CFG_RDY_BIT)    <=i_cfg_rdy;
i_host_dev_status(C_HREG_DEV_STATUS_CFG_RXRDY_BIT)  <=i_host_rxrdy(C_HDEV_CFG_DBUF);
i_host_dev_status(C_HREG_DEV_STATUS_CFG_TXRDY_BIT)  <=i_host_txrdy(C_HDEV_CFG_DBUF);

i_host_dev_status(C_HREG_DEV_STATUS_ETH_RDY_BIT)    <=i_eth_rdy;
i_host_dev_status(C_HREG_DEV_STATUS_ETH_CARIER_BIT) <=i_eth_carier;
i_host_dev_status(C_HREG_DEV_STATUS_ETH_RXRDY_BIT)  <=i_host_rxrdy(C_HDEV_ETH_DBUF);
i_host_dev_status(C_HREG_DEV_STATUS_ETH_TXRDY_BIT)  <=i_host_txrdy(C_HDEV_ETH_DBUF);

i_host_dev_status(C_HREG_DEV_STATUS_VCH0_FRRDY_BIT) <=i_vctrl_hrdy_out(0);
i_host_dev_status(C_HREG_DEV_STATUS_VCH1_FRRDY_BIT) <=i_vctrl_hrdy_out(1);
i_host_dev_status(C_HREG_DEV_STATUS_VCH2_FRRDY_BIT) <=i_vctrl_hrdy_out(2);

i_host_dev_status(C_HREG_DEV_STATUS_MEMCTRL_RDY_BIT)<=i_memctrl_dcm_lock;
i_host_dev_status(C_HREG_DEV_STATUS_TRCNIK_DRDY_BIT)<='0';--i_trcnik_hdrdy;


--//Запись/Чтение данных из устр-ва с адресом i_host_devadr
i_host_wr(C_HDEV_CFG_DBUF) <=i_host_dev_wr when i_host_devadr=CONV_STD_LOGIC_VECTOR(C_HDEV_CFG_DBUF, i_host_devadr'length) else '0';
i_host_rd(C_HDEV_CFG_DBUF) <=i_host_dev_rd when i_host_devadr=CONV_STD_LOGIC_VECTOR(C_HDEV_CFG_DBUF, i_host_devadr'length) else '0';
i_host_txd(C_HDEV_CFG_DBUF)<=i_host_dev_txd;

i_host_wr(C_HDEV_ETH_DBUF) <=i_host_dev_wr when i_host_devadr=CONV_STD_LOGIC_VECTOR(C_HDEV_ETH_DBUF, i_host_devadr'length) else '0';
i_host_rd(C_HDEV_ETH_DBUF) <=i_host_dev_rd when i_host_devadr=CONV_STD_LOGIC_VECTOR(C_HDEV_ETH_DBUF, i_host_devadr'length) else '0';
i_host_txd(C_HDEV_ETH_DBUF)<=i_host_dev_txd;

i_host_rd(C_HDEV_VCH_DBUF) <=i_host_dev_rd when i_host_devadr=CONV_STD_LOGIC_VECTOR(C_HDEV_VCH_DBUF, i_host_devadr'length)  else '0';


--/Чтение
i_host_dev_rxd<=i_host_rxd(C_HDEV_CFG_DBUF) when i_host_devadr=CONV_STD_LOGIC_VECTOR(C_HDEV_CFG_DBUF, i_host_devadr'length) else
                i_host_rxd(C_HDEV_ETH_DBUF) when i_host_devadr=CONV_STD_LOGIC_VECTOR(C_HDEV_ETH_DBUF, i_host_devadr'length) else
                i_host_rxd(C_HDEV_VCH_DBUF) when i_host_devadr=CONV_STD_LOGIC_VECTOR(C_HDEV_VCH_DBUF, i_host_devadr'length) else
                (others=>'0');


i_host_dev_flag(C_DEV_FLAG_TXFIFO_PFULL_BIT)<=i_host_txbuf_full(C_HDEV_ETH_DBUF) when i_host_devadr=CONV_STD_LOGIC_VECTOR(C_HDEV_ETH_DBUF, i_host_devadr'length) else
                                              '0';

i_host_dev_flag(C_DEV_FLAG_RXFIFO_EMPTY_BIT)<=i_host_rxbuf_empty(C_HDEV_ETH_DBUF) when i_host_devadr=CONV_STD_LOGIC_VECTOR(C_HDEV_ETH_DBUF, i_host_devadr'length) else
                                              i_host_rxbuf_empty(C_HDEV_VCH_DBUF) when i_host_devadr=CONV_STD_LOGIC_VECTOR(C_HDEV_VCH_DBUF, i_host_devadr'length) else
                                              '0';


--//Назначаем стробы для установки прерывания
i_host_dev_irq(C_HIRQ_TMR0)  <=i_tmr_hirq(0);
i_host_dev_irq(C_HIRQ_CFG_RX)<=i_host_irq(C_HIRQ_CFG_RX);
i_host_dev_irq(C_HIRQ_ETH_RX)<=i_host_irq(C_HIRQ_ETH_RX);
i_host_dev_irq(C_HIRQ_TRCNIK)<='0';--i_host_irq(C_HIRQ_TRCNIK);
i_host_dev_irq(C_HIRQ_VCH0)  <=i_vctrl_hirq_out(0);
i_host_dev_irq(C_HIRQ_VCH1)  <=i_vctrl_hirq_out(1);
i_host_dev_irq(C_HIRQ_VCH2)  <=i_vctrl_hirq_out(2);


--//
i_host_dev_option(31 downto 0)<=i_vctrl_hfrmrk;
i_host_dev_option(63 downto 32)<=(others=>'0');--i_trc_hfrmrk;
i_host_dev_option(95 downto 64)<=(others=>'0');--i_trcnik_hfrmrk;
i_host_dev_option(127 downto 96)<=(others=>'0');


--//Обработка управляющих сигналов Хоста
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

    hclk_hmem_ce<='0';
    hclk_hmem_ce_cnt<=(others=>'0');

  elsif g_host_clk'event and g_host_clk='1' then

    for i in 0 to C_HDEV_COUNT-1 loop
      --//импульс начала DMA транзакции
      if i_host_devadr=i then
        if i_host_dma_start='1' then
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

    --//Растягиваем импульс
    if i_host_mem_ce='1' then --or i_host_mem_term='1' then
      hclk_hmem_ce<='1';
    elsif hclk_hmem_ce_cnt(2)='1' then
      hclk_hmem_ce<='0';
    end if;

    if hclk_hmem_ce='0' then
      hclk_hmem_ce_cnt<=(others=>'0');
    else
      hclk_hmem_ce_cnt<=hclk_hrddone_vctrl_cnt+1;
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

    i_hmem_ce<='0';

  elsif g_usr_highclk'event and g_usr_highclk='1' then
    i_vctrl_hrd_start<=hclk_hdev_dma_start(C_HDEV_VCH_DBUF);

    i_vctrl_hrd_done_dly(0)<=hclk_hrddone_vctrl;
    i_vctrl_hrd_done_dly(1)<=i_vctrl_hrd_done_dly(0);
    i_vctrl_hrd_done<=i_vctrl_hrd_done_dly(0) and not i_vctrl_hrd_done_dly(1);

    i_hmem_ce<=hclk_hmem_ce;

  end if;
end process;



--***********************************************************
--Модуль Контроллера памяти - memory_ctrl.vhd
--***********************************************************
--//Арбитр канала 1 контроллера памяти
m_mem_arb_ch1 : memory_ch_arbitr
generic map(
G_CH_COUNT => selval(10#03#,10#02#, strcmp(C_USE_HDD,"ON")) --selval2(10#04#,10#03#,10#03#,10#02#, strcmp(C_USE_HDD,"ON"),strcmp(C_USE_TRACK,"ON"))
)
port map(
-------------------------------
-- Связь с CH0
-------------------------------
p_in_ch0_req     => i_vctrlwr_memarb_req,
p_out_ch0_en     => i_vctrlwr_memarb_en,

p_in_ch0_bank1h  => i_vctrlwr_mem_bank1h,
p_in_ch0_ce      => i_vctrlwr_mem_ce,
p_in_ch0_cw      => i_vctrlwr_mem_cw,
p_in_ch0_term    => i_vctrlwr_mem_term,
p_in_ch0_rd      => i_vctrlwr_mem_rd,
p_in_ch0_wr      => i_vctrlwr_mem_wr,
p_in_ch0_adr     => i_vctrlwr_mem_adr,
p_in_ch0_be      => i_vctrlwr_mem_be,
p_in_ch0_din     => i_vctrlwr_mem_din,
p_out_ch0_dout   => i_vctrlwr_mem_dout,

p_out_ch0_wf     => i_vctrlwr_mem_wf,
p_out_ch0_wpf    => i_vctrlwr_mem_wpf,
p_out_ch0_re     => i_vctrlwr_mem_re,
p_out_ch0_rpe    => i_vctrlwr_mem_rpe,

-------------------------------
-- Связь с CH1
-------------------------------
p_in_ch1_req     => i_vctrlrd_memarb_req,
p_out_ch1_en     => i_vctrlrd_memarb_en,

p_in_ch1_bank1h  => i_vctrlrd_mem_bank1h,
p_in_ch1_ce      => i_vctrlrd_mem_ce,
p_in_ch1_cw      => i_vctrlrd_mem_cw,
p_in_ch1_term    => i_vctrlrd_mem_term,
p_in_ch1_rd      => i_vctrlrd_mem_rd,
p_in_ch1_wr      => i_vctrlrd_mem_wr,
p_in_ch1_adr     => i_vctrlrd_mem_adr,
p_in_ch1_be      => i_vctrlrd_mem_be,
p_in_ch1_din     => i_vctrlrd_mem_din,
p_out_ch1_dout   => i_vctrlrd_mem_dout,

p_out_ch1_wf     => i_vctrlrd_mem_wf,
p_out_ch1_wpf    => i_vctrlrd_mem_wpf,
p_out_ch1_re     => i_vctrlrd_mem_re,
p_out_ch1_rpe    => i_vctrlrd_mem_rpe,

-------------------------------
-- Связь с CH2
-------------------------------
p_in_ch2_req     => i_hdd_memarb_req,
p_out_ch2_en     => i_hdd_memarb_en,

p_in_ch2_bank1h  => i_hdd_mem_bank1h,
p_in_ch2_ce      => i_hdd_mem_ce,
p_in_ch2_cw      => i_hdd_mem_cw,
p_in_ch2_term    => i_hdd_mem_term,
p_in_ch2_rd      => i_hdd_mem_rd,
p_in_ch2_wr      => i_hdd_mem_wr,
p_in_ch2_adr     => i_hdd_mem_adr,
p_in_ch2_be      => i_hdd_mem_be,
p_in_ch2_din     => i_hdd_mem_din,
p_out_ch2_dout   => i_hdd_mem_dout,

p_out_ch2_wf     => i_hdd_mem_wf,
p_out_ch2_wpf    => i_hdd_mem_wpf,
p_out_ch2_re     => i_hdd_mem_re,
p_out_ch2_rpe    => i_hdd_mem_rpe,

-------------------------------
-- Связь с CH3
-------------------------------
p_in_ch3_req     => '0',
p_out_ch3_en     => open,

p_in_ch3_bank1h  => i_mem_null_bank1h,
p_in_ch3_ce      => i_mem_null_ce,
p_in_ch3_cw      => i_mem_null_cw,
p_in_ch3_term    => i_mem_null_term,
p_in_ch3_rd      => i_mem_null_rd,
p_in_ch3_wr      => i_mem_null_wr,
p_in_ch3_adr     => i_mem_null_adr,
p_in_ch3_be      => i_mem_null_be,
p_in_ch3_din     => i_mem_null_din,
p_out_ch3_dout   => i_mem_null_dout,

p_out_ch3_wf     => i_mem_null_wf,
p_out_ch3_wpf    => i_mem_null_wpf,
p_out_ch3_re     => i_mem_null_re,
p_out_ch3_rpe    => i_mem_null_rpe,

---------------------------------
-- Связь с memory_ctrl.vhd
---------------------------------
p_out_mem_clk    => open,--i_mem_arb1_clk,

p_out_mem_bank1h => i_mem_arb1_bank1h,
p_out_mem_ce     => i_mem_arb1_ce,
p_out_mem_cw     => i_mem_arb1_cw,
p_out_mem_rd     => i_mem_arb1_rd,
p_out_mem_wr     => i_mem_arb1_wr,
p_out_mem_term   => i_mem_arb1_term,
p_out_mem_adr    => i_mem_arb1_adr,
p_out_mem_be     => i_mem_arb1_be,
p_out_mem_din    => i_mem_arb1_din,
p_in_mem_dout    => i_mem_arb1_dout,

p_in_mem_wf      => i_mem_arb1_wf,
p_in_mem_wpf     => i_mem_arb1_wpf,
p_in_mem_re      => i_mem_arb1_re,
p_in_mem_rpe     => i_mem_arb1_rpe,


-------------------------------
--Технологический
-------------------------------
p_in_tst         => "00000000000000000000000000000000",
p_out_tst        => i_mem_arb1_tst_out,

-------------------------------
--System
-------------------------------
p_in_clk         => g_usr_highclk,
p_in_rst         => i_memctrl_rst
);

gen_sim_on : if strcmp(G_SIM,"ON") generate

process(i_host_rst_n, g_usr_highclk)
  variable sim_mem_arb1_read: std_logic;
  variable sim_mem_arb1_dout: std_logic_vector(7 downto 0);
begin
  if i_host_rst_n='0' then
    i_sim_mem_arb1_read_dly_cnt<=(others=>'0');
    i_sim_mem_arb1_read_dly<='0';
      sim_mem_arb1_dout:=(others=>'0');

    i_mem_arb1_dout<=(others=>'0');
    i_mem_arb1_re <='1';

  elsif g_usr_highclk'event and g_usr_highclk='1' then
    sim_mem_arb1_read:='0';

    if i_mem_arb1_ce='1' and i_mem_arb1_cw='0' then
      i_sim_mem_arb1_read_dly<='1';
    else
      if i_sim_mem_arb1_read_dly='1' then
        if i_sim_mem_arb1_read_dly_cnt="1100" then
          i_sim_mem_arb1_read_dly_cnt<=(others=>'0');
          i_sim_mem_arb1_read_dly<='0';
          sim_mem_arb1_read:='1';
        else
          i_sim_mem_arb1_read_dly_cnt<=i_sim_mem_arb1_read_dly_cnt+1;
        end if;
      end if;
    end if;

    if i_vctrl_vrd_done='1' and i_mem_arb1_cw='0' then
      i_mem_arb1_dout<=(others=>'0');
      sim_mem_arb1_dout:=(others=>'0');

    elsif i_mem_arb1_re='0' and i_mem_arb1_rd='1' then
      sim_mem_arb1_dout:=sim_mem_arb1_dout+4;
    end if;

    i_mem_arb1_dout(7 downto 0)  <=sim_mem_arb1_dout;
    i_mem_arb1_dout(15 downto 8) <=sim_mem_arb1_dout+1;
    i_mem_arb1_dout(23 downto 16)<=sim_mem_arb1_dout+2;
    i_mem_arb1_dout(31 downto 24)<=sim_mem_arb1_dout+3;

    if sim_mem_arb1_read='1' then
      i_mem_arb1_re <='0';
    elsif i_mem_arb1_term='1' then
      i_mem_arb1_re <='1';
    end if;

  end if;
end process;

i_mem_arb1_rpe<='0';
i_mem_arb1_wf <='0';
i_mem_arb1_wpf<='0';

end generate gen_sim_on;

gen_sim_off : if strcmp(G_SIM,"OFF") generate
i_mem_arb1_dout<=i_mem_arb1_dout_tmp;
i_mem_arb1_re  <=i_mem_arb1_re_tmp;
i_mem_arb1_rpe <=i_mem_arb1_rpe_tmp;
i_mem_arb1_wf  <=i_mem_arb1_wf_tmp;
i_mem_arb1_wpf <=i_mem_arb1_wpf_tmp;
end generate gen_sim_off;

i_host_mem_mode_reg((32* (0 + 1)) - 23 downto  32* 0)<=CONV_STD_LOGIC_VECTOR(16#D4#, 10);
i_host_mem_mode_reg((32* (1 + 1)) - 23 downto  32* 1)<=CONV_STD_LOGIC_VECTOR(16#D4#, 10);
i_host_mem_mode_reg((32* (2 + 1)) - 23 downto  32* 2)<=CONV_STD_LOGIC_VECTOR(16#01#, 10);
i_host_mem_mode_reg(i_host_mem_mode_reg'high downto (3*32))<=(others=>'0');

m_mem_ctrl : memory_ctrl
generic map(
G_BANK_COUNT => C_MEMCTRL_BANK_COUNT,

bank0      => C_MEM_BANK0,
bank1      => C_MEM_BANK1,
bank2      => C_MEM_BANK2,
bank3      => C_MEM_BANK3,
bank4      => C_MEM_BANK4,
bank5      => C_MEM_BANK5,
bank6      => C_MEM_BANK6,
bank7      => C_MEM_BANK7,
bank8      => C_MEM_BANK8,
bank9      => C_MEM_BANK9,
bank10     => C_MEM_BANK10,
bank11     => C_MEM_BANK11,
bank12     => C_MEM_BANK12,
bank13     => C_MEM_BANK13,
bank14     => C_MEM_BANK14,
bank15     => C_MEM_BANK15,
num_ramclk => C_MEM_NUM_RAMCLK
)
port map(
-----------------------------
--System
-----------------------------
rst         => i_memctrl_rst,

memclk0     => i_memctrl_pllclk0,
memclk45    => i_memctrl_pllclk45,
memclk2x0   => i_memctrl_pllclk2x0,
memclk2x90  => i_memctrl_pllclk2x90,
memrst      => i_memctrl_pll_rst_out,

-----------------------------
-- Configuration
-----------------------------
mode_reg    => i_host_mem_mode_reg,
bank_reg    => "0000",--bank_reg,
trained     => i_host_mem_trained,

-----------------------------
-- User channel 0 (имеет наивысший приоритет)
-----------------------------
usr0_clk    => g_usr_highclk,
--Управление
usr0_bank1h => i_mem_arb1_bank1h,
usr0_ce     => i_mem_arb1_ce,
usr0_cw     => i_mem_arb1_cw,
usr0_term   => i_mem_arb1_term,
usr0_rd     => i_mem_arb1_rd,
usr0_wr     => i_mem_arb1_wr,
usr0_adr    => i_mem_arb1_adr,
usr0_be     => i_mem_arb1_be,
usr0_din    => i_mem_arb1_din,
usr0_dout   => i_mem_arb1_dout_tmp,
--TX/RXBUF STATUS
usr0_wf     => i_mem_arb1_wf_tmp,
usr0_wpf    => i_mem_arb1_wpf_tmp,
usr0_re     => i_mem_arb1_re_tmp,
usr0_rpe    => i_mem_arb1_rpe_tmp,

-----------------------------
-- User channel 1
-----------------------------
usr1_clk    => g_host_clk,
--Управление
usr1_bank1h => i_host_mem_bank1h,
usr1_ce     => i_host_mem_ce,
usr1_cw     => i_host_mem_cw,
usr1_term   => i_host_mem_term,
usr1_rd     => i_host_mem_rd,
usr1_wr     => i_host_mem_wr,
usr1_adr    => i_host_mem_adr,
usr1_be     => i_host_mem_be,
usr1_din    => i_host_mem_din,
usr1_dout   => i_host_mem_dout,
--TX/RXBUF STATUS
usr1_wf     => i_host_mem_wf,
usr1_wpf    => i_host_mem_wpf,
usr1_re     => i_host_mem_re,
usr1_rpe    => i_host_mem_rpe,


-----------------------------
-- To/from FPGA memory pins
-----------------------------
ra0  => ra0,
rc0  => rc0,
rd0  => rd0,
ra1  => ra1,
rc1  => rc1,
rd1  => rd1,
ra2  => ra2,
rc2  => rc2,
rd2  => rd2,
ra3  => ra3,
rc3  => rc3,
rd3  => rd3,
ra4  => ra4,
rc4  => rc4,
rd4  => rd4,
ra5  => ra5,
rc5  => rc5,
rd5  => rd5,
ra6  => ra6,
rc6  => rc6,
rd6  => rd6,
ra7  => ra7,
rc7  => rc7,
rd7  => rd7,
ra8  => ra8,
rc8  => rc8,
rd8  => rd8,
ra9  => ra9,
rc9  => rc9,
rd9  => rd9,
ra10 => ra10,
rc10 => rc10,
rd10 => rd10,
ra11 => ra11,
rc11 => rc11,
rd11 => rd11,
ra12 => ra12,
rc12 => rc12,
rd12 => rd12,
ra13 => ra13,
rc13 => rc13,
rd13 => rd13,
ra14 => ra14,
rc14 => rc14,
rd14 => rd14,
ra15 => ra15,
rc15 => rc15,
rd15 => rd15,
ramclki => ramclki,
ramclko => ramclko
);


--//-----------------------------------------
--//DBG
--//-----------------------------------------
--Светодиоды
tst_clr <=pin_in_btn_C or pin_in_btn_E or pin_in_btn_N or pin_in_btn_S;

pin_out_led_E<=i_hdd_gt_plldet and i_hdd_dcm_lock;                                              --i_hdd_gt_plldet and i_hdd_dcm_lock;
pin_out_led_N<=lclk_dcm_lock when pin_in_btn_S='0' else tst_clr or i_test01_led;                --i_hdd_busy or i_hdd_rst when pin_in_btn_S='0' else tst_clr;
pin_out_led_S<=i_memctrl_dcm_lock;                                                              --i_test01_led;
pin_out_led_W<=i_host_mem_ctl_reg(0) when pin_in_btn_W='0' else i_hdd_dbgled(1).spd(1);         --i_hdd_dbgled(0).spd(1) when pin_in_btn_W='0' else i_hdd_dbgled(1).spd(1);
pin_out_led_C<=not lclk_dcm_lock or i_usr_rst when pin_in_btn_W='0' else i_hdd_dbgled(1).spd(0);--i_hdd_dbgled(0).spd(0) when pin_in_btn_W='0' else i_hdd_dbgled(1).spd(0);

pin_out_led(0)<=i_hdd_dbgled(1).busy;
pin_out_led(1)<=i_hdd_dbgled(1).err;
pin_out_led(2)<=i_hdd_dbgled(1).rdy;
pin_out_led(3)<=i_hdd_dbgled(1).link;

pin_out_led(4)<=i_hdd_dbgled(0).busy;
pin_out_led(5)<=i_hdd_dbgled(0).err;
pin_out_led(6)<=i_hdd_dbgled(0).rdy;
pin_out_led(7)<=i_hdd_dbgled(0).link;


--//-----------------------------------------
--//Для ПЛАТЫ ALPHA DATA
--//-----------------------------------------
gen_alphadata : if strcmp(C_BOARD_USE,"ALPHA_DATA") generate

--pin_out_led<=(others=>'0');
--pin_out_led_C<=pin_in_btn_C;
--pin_out_led_E<=pin_in_btn_E;
--pin_out_led_N<=pin_in_btn_N;
--pin_out_led_S<=pin_in_btn_S;
--pin_out_led_W<=pin_in_btn_W;

pin_out_TP<=(others=>'0');

pin_out_ddr2_cke1<='0';
pin_out_ddr2_cs1<='0';
pin_out_ddr2_odt1<='0';

i_usr_rst<='0';
i_hdd_tst_in<=(others=>'0');

end generate gen_alphadata;


--//-----------------------------------------
--//Для ПЛАТЫ ML505
--//-----------------------------------------
gen_ml505 : if strcmp(C_BOARD_USE,"ML505") generate

pin_out_ddr2_cke1<='0';
pin_out_ddr2_cs1<='0';
pin_out_ddr2_odt1<='0';

i_usr_rst<=pin_in_btn_N;
i_hdd_tst_in(0)<=pin_in_btn_W;
i_hdd_tst_in(31 downto 1)<=(others=>'0');

i_trc_busy<=(others=>'0');

--//J5 /pin2
pin_out_TP(0)<=i_trc_busy(0);

--//J6
pin_out_TP(1)<=i_hdd_busy;  --//pin2
pin_out_TP(2)<=i_hdd_tst_out(6);--//pin6  p_out_tst(6)<=OR_reduce(i_sh_status.ch_bsy(G_HDD_COUNT-1 downto 0));
pin_out_TP(3)<=i_hdd_dbgled(0).dly;--//pin10
                            --//pin14
pin_out_TP(4)<='0';         --//pin16
                            --//pin18
pin_out_TP(5)<='0';         -- /pin20
                            --//pin22
pin_out_TP(6)<='0';         -- /pin24
pin_out_TP(7)<='0';         -- /pin26


m_gt_03_test: fpga_test_01
generic map(
G_BLINK_T05   =>10#250#, -- 1/2 периода мигания светодиода.(время в ms)
G_CLK_T05us   =>10#75#   -- 05us - 150MHz
)
port map
(
p_out_test_led => i_test01_led,
p_out_test_done=> open,

p_out_1us      => open,
p_out_1ms      => open,
-------------------------------
--System
-------------------------------
p_in_clk       => g_hdd_gt_refclkout,
p_in_rst       => i_hdd_rst
);


gen_dbgcs : if strcmp(C_DBGCS_HDD,"ON") generate

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
m_dbgcs_sh0_layer : dbgcs_sata_raid --dbgcs_sata_layer
port map
(
CONTROL => i_dbgcs_sh0_layer,
CLK     => i_hdd_dbgcs.sh(1).layer.clk,
DATA    => i_hdd_dbgcs.sh(1).layer.data(172 downto 0),--(122 downto 0),
TRIG0   => i_hdd_dbgcs.sh(1).layer.trig0(41 downto 0)
);



--//### HDD_RAMBUF: ########
m_dbgcs_hddrambuf : dbgcs_sata_raid -- dbgcs_sata_rambuf
port map
(
CONTROL => i_dbgcs_hdd_rambuf,
CLK     => i_hdd_rambuf_dbgcs.clk,
DATA    => i_hddrambuf_dbgcs.data(172 downto 0),--(136 downto 0),
TRIG0   => i_hddrambuf_dbgcs.trig0(41 downto 0)
);

--//-------- TRIG: ------------------
i_hddrambuf_dbgcs.trig0(4 downto  0) <=i_hdd_rambuf_dbgcs.trig0(4 downto 0);--tst_fsm_cs(4 downto 0);
i_hddrambuf_dbgcs.trig0(5)           <=i_hdd_mem_ce;
i_hddrambuf_dbgcs.trig0(6)           <=i_hdd_mem_cw;
i_hddrambuf_dbgcs.trig0(20 downto 7) <=i_hdd_rambuf_dbgcs.trig0(20 downto 7);
i_hddrambuf_dbgcs.trig0(21)          <=i_vctrlwr_memarb_en;
i_hddrambuf_dbgcs.trig0(22)          <=i_vctrlrd_memarb_en;
i_hddrambuf_dbgcs.trig0(23)          <=i_hdd_memarb_en;
i_hddrambuf_dbgcs.trig0(24)          <=i_mem_arb1_ce;
i_hddrambuf_dbgcs.trig0(25)          <='0';
i_hddrambuf_dbgcs.trig0(26)          <='0';
i_hddrambuf_dbgcs.trig0(27)          <='0';
i_hddrambuf_dbgcs.trig0(28)          <='0';
i_hddrambuf_dbgcs.trig0(29)          <='0';
i_hddrambuf_dbgcs.trig0(41 downto 30)<=i_hdd_rambuf_dbgcs.trig0(41 downto 30);


--//-------- VIEW: ------------------
i_hddrambuf_dbgcs.data(0)<=i_hdd_mem_ce;       --//
i_hddrambuf_dbgcs.data(1)<=i_hdd_mem_cw;
i_hddrambuf_dbgcs.data(2)<=i_mem_arb1_rd;   --//i_hdd_mem_rd;  --
i_hddrambuf_dbgcs.data(3)<=i_mem_arb1_wr;   --//i_hdd_mem_wr;  --
i_hddrambuf_dbgcs.data(4)<=i_mem_arb1_term; --//i_hdd_mem_term;--
i_hddrambuf_dbgcs.data(18 downto 5)<=i_hdd_rambuf_dbgcs.data(18 downto 5);

i_hddrambuf_dbgcs.data(19)<=i_swt_tst_out(0);--//tst_swt_hdd_vbuf_wr;

i_hddrambuf_dbgcs.data(119 downto 20)<=i_hdd_rambuf_dbgcs.data(119 downto 20);
i_hddrambuf_dbgcs.data(135 downto 120)<=i_mem_arb1_dout(15 downto 0);--tst_hdd_mem_dcnt;
i_hddrambuf_dbgcs.data(151 downto 136)<=i_hdd_rambuf_dbgcs.data(151 downto 136);

i_hddrambuf_dbgcs.data(152)          <=i_vctrlwr_memarb_en;
i_hddrambuf_dbgcs.data(153)          <=i_vctrlrd_memarb_en;
i_hddrambuf_dbgcs.data(154)          <=i_hdd_memarb_en;
--i_hddrambuf_dbgcs.data(166 downto 155)<=i_mem_arb1_din(27 downto 16);
i_hddrambuf_dbgcs.data(166 downto 155)<=i_hdd_rambuf_dbgcs.data(166 downto 155);

i_hddrambuf_dbgcs.data(172 downto 167)<=i_hdd_rambuf_dbgcs.data(172 downto 167);





----//### HDD_RAID: ########
--m_dbgcs_sh0_raid : dbgcs_sata_raid
--port map
--(
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
----i_hddraid_dbgcs.data(104)<=i_hdd_mem_ce;
--i_hddraid_dbgcs.data(105)<=i_hdd_rxbuf_empty;
--i_hddraid_dbgcs.data(106)<=i_mem_arb1_rd;--RAM->HDD
--i_hddraid_dbgcs.data(107)<=i_mem_arb1_wr;--RAM<-HDD
--i_hddraid_dbgcs.data(108)<=i_mem_arb1_term;
--i_hddraid_dbgcs.data(140 downto 109)<=i_mem_arb1_dout(31 downto 0);--RAM->HDD
--i_hddraid_dbgcs.data(172 downto 141)<=i_mem_arb1_din(31 downto 0);--RAM<-HDD


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
--port map
--(
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
--port map
--(
--CONTROL => i_dbgcs_sh0_spd,
--CLK     => i_hdd_dbgcs.sh(0).spd.clk,
--DATA    => i_hdd_dbgcs.sh(0).spd.data(122 downto 0),
--TRIG0   => i_hdd_dbgcs.sh(0).spd.trig0(41 downto 0)
--);

end generate gen_dbgcs;


end generate gen_ml505;


end architecture;
