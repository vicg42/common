-------------------------------------------------------------------------
-- Company     : Linkos
-- Engineer    : Golovachenko Victor
--
-- Create Date : 03/02/2010
-- Module Name : vereskm_test_main
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

entity vereskm_test_main is
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
pin_out_phymem    : out   TMEMCTRL_phy_outs;
pin_inout_phymem  : inout TMEMCTRL_phy_inouts;

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

pin_out_eth1phy       : out   TEthPhyRGMIIPinOUT;
pin_in_eth1phy        : in    TEthPhyRGMIIPinIN;

pin_out_eth1phy_txdn  : out   std_logic_vector(7 downto 4);
pin_in_eth1phy_clk125 : in    std_logic;
pin_out_eth1phy_rstn  : out   std_logic;
pin_inout_eth1phy_mdoi: inout std_logic;
pin_out_eth1phy_mdc   : out   std_logic;

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

architecture struct of vereskm_test_main is


component dbgcs_iconx1
  PORT (
    CONTROL0 : INOUT STD_LOGIC_VECTOR(35 DOWNTO 0)
    );
end component;

component dbgcs_iconx2
  PORT (
    CONTROL1 : INOUT STD_LOGIC_VECTOR(35 DOWNTO 0);
    CONTROL0 : INOUT STD_LOGIC_VECTOR(35 DOWNTO 0)
    );
end component;

component dbgcs_iconx3
  PORT (
    CONTROL2 : INOUT STD_LOGIC_VECTOR(35 DOWNTO 0);
    CONTROL1 : INOUT STD_LOGIC_VECTOR(35 DOWNTO 0);
    CONTROL0 : INOUT STD_LOGIC_VECTOR(35 DOWNTO 0)
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

component dbgcs_sata_raid_b
  PORT (
    CONTROL : INOUT STD_LOGIC_VECTOR(35 DOWNTO 0);
    CLK : IN STD_LOGIC;
    DATA : IN STD_LOGIC_VECTOR(255 downto 0); --(122 DOWNTO 0);(172 downto 0); --(122 DOWNTO 0);
    TRIG0 : IN STD_LOGIC_VECTOR(41 DOWNTO 0)
    );
end component;

component dbgcs_cfg
  PORT (
    CONTROL : INOUT STD_LOGIC_VECTOR(35 DOWNTO 0);
    CLK : IN STD_LOGIC;
    DATA : IN STD_LOGIC_VECTOR(31 downto 0); --(122 DOWNTO 0);
    TRIG0 : IN STD_LOGIC_VECTOR(15 DOWNTO 0)
    );
end component;

signal i_dbgcs_hdd_raid                 : std_logic_vector(35 downto 0);
signal i_hddraid_dbgcs                  : TSH_ila;

signal i_dbgcs_memaxi                : std_logic_vector(35 downto 0);
signal i_dbgcs_memaxi_trg            : std_logic_vector(41 downto 0);
signal i_dbgcs_memaxi_view           : std_logic_vector(255 downto 0);

signal i_dbgcs_mem                : std_logic_vector(35 downto 0);
signal i_dbgcs_mem_trg            : std_logic_vector(41 downto 0);
signal i_dbgcs_mem_view           : std_logic_vector(255 downto 0);

signal i_dbgcs_int0                  : std_logic_vector(35 downto 0);
signal i_dbgcs_int0_trg              : std_logic_vector(15 downto 0);
signal i_dbgcs_int0_view             : std_logic_vector(31 downto 0);

signal i_dbgcs_int1                  : std_logic_vector(35 downto 0);
signal i_dbgcs_int1_trg              : std_logic_vector(15 downto 0);
signal i_dbgcs_int1_view             : std_logic_vector(31 downto 0);

signal i_irq_rdy                     : std_logic_vector(7 downto 0);
signal i_tmr_dly_clr                 : std_logic;
signal i_tmr_dly                     : std_logic_vector(22 downto 0);
signal sr_irq_assert_n               : std_logic:='1';
signal tst_mem_trained               : std_logic:='0';

component host_ethg_txfifo
port(
din         : IN  std_logic_vector(31 downto 0);
wr_en       : IN  std_logic;
wr_clk      : IN  std_logic;

dout        : OUT std_logic_vector(31 downto 0);
rd_en       : IN  std_logic;
rd_clk      : IN  std_logic;

empty       : OUT std_logic;
full        : OUT std_logic;
--almost_full : OUT std_logic;
almost_empty: OUT std_logic;

rst         : IN  std_logic
);
end component;

component dsn_hdd_rambuf is
generic(
G_MODULE_USE  : string:="ON";
G_RAMBUF_SIZE : integer:=23;
G_DBGCS       : string:="OFF";
G_SIM         : string:="OFF";
G_USE_2CH     : string:="ON";
G_MEM_BANK_M_BIT : integer:=31;
G_MEM_BANK_L_BIT : integer:=31;
G_MEM_AWIDTH  : integer:=32;
G_MEM_DWIDTH  : integer:=32
);
port(
-------------------------------
-- Конфигурирование
-------------------------------
p_in_rbuf_cfg         : in    THDDRBufCfg;
p_out_rbuf_status     : out   THDDRBufStatus;
p_in_lentrn_exp       : in    std_logic;

--//--------------------------
--//Связь с буфером видеоданных
--//--------------------------
p_in_bufi_dout        : in    std_logic_vector(G_MEM_DWIDTH-1 downto 0);
p_out_bufi_rd         : out   std_logic;
p_in_bufi_empty       : in    std_logic;
p_in_bufi_full        : in    std_logic;
p_in_bufi_pfull       : in    std_logic;
p_in_bufi_wrcnt       : in    std_logic_vector(3 downto 0);

p_out_bufo_din        : out   std_logic_vector(G_MEM_DWIDTH-1 downto 0);
p_out_bufo_wr         : out   std_logic;
p_in_bufo_full        : in    std_logic;

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
p_out_memch0          : out   TMemIN;
p_in_memch0           : in    TMemOUT;

p_out_memch1          : out   TMemIN;
p_in_memch1           : in    TMemOUT;

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


signal i_usr_rst                        : std_logic;

signal i_refclk200MHz                   : std_logic;
signal g_refclk200MHz                   : std_logic;

signal i_gt_X0Y6_rst                    : std_logic;
signal i_gt_X0Y6_clkin                  : std_logic;
signal i_gt_X0Y6_clkout                 : std_logic;

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
signal i_cfg_dadr                       : std_logic_vector(C_CFGPKT_DADR_M_BIT-C_CFGPKT_DADR_L_BIT downto 0);
signal i_cfg_radr                       : std_logic_vector(C_CFGPKT_RADR_M_BIT-C_CFGPKT_RADR_L_BIT downto 0);
signal i_cfg_radr_ld                    : std_logic;
signal i_cfg_radr_fifo                  : std_logic;
signal i_cfg_wr                         : std_logic;
signal i_cfg_rd                         : std_logic;
signal i_cfg_txd                        : std_logic_vector(15 downto 0);
signal i_cfg_rxd                        : std_logic_vector(15 downto 0);
Type TCfgRxD is array (0 to C_CFGDEV_COUNT-1) of std_logic_vector(i_cfg_rxd'range);
signal i_cfg_rxd_dev                    : TCfgRxD;
signal i_cfg_done                       : std_logic;
signal i_cfg_wr_dev                     : std_logic_vector(C_CFGDEV_COUNT-1 downto 0);
signal i_cfg_rd_dev                     : std_logic_vector(C_CFGDEV_COUNT-1 downto 0);
signal i_cfg_done_dev                   : std_logic_vector(C_CFGDEV_COUNT-1 downto 0);
signal i_cfg_tst_out                    : std_logic_vector(31 downto 0);

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

signal i_mem_ctrl_status                : TMEMCTRL_status;
signal i_mem_ctrl_sysin                 : TMEMCTRL_sysin;
signal i_mem_ctrl_sysout                : TMEMCTRL_sysout;

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
signal i_hdd_memout_null                : TMemOUT;

signal i_dsntst_rst                     : std_logic;
signal i_dsntst_txdata_rdy              : std_logic;
signal i_dsntst_txdata_dout             : std_logic_vector(31 downto 0);
signal i_dsntst_txdata_wd               : std_logic;
signal i_dsntst_txbuf_empty             : std_logic;
signal i_dsntst_txbuf_full              : std_logic;
signal i_dsntst_bufclk                  : std_logic;
signal i_dsntst_tst_out                 : std_logic_vector(31 downto 0);


signal i_test01_led     : std_logic;
signal tst_clr          : std_logic;


type TEth_fsmtx is (
S_IDLE,
S_TX0,
S_TX1
);
signal fsm_eth1tx_cs: TEth_fsmtx;

type TEth_fsmprog is (
S_IDLE,
S_TX0,
S_TX1,
S_TX2,
S_TX3,
S_TX4,
S_TX5
);
signal fsm_eth1prog_cs: TEth_fsmprog;

signal i_eth1cfg_radr                       : std_logic_vector(7 downto 0);--(C_CFGPKT_RADR_M_BIT-C_CFGPKT_RADR_L_BIT downto 0);
signal i_eth1cfg_radr_ld                    : std_logic;
signal i_eth1cfg_radr_fifo                  : std_logic;
signal i_eth1cfg_wr                         : std_logic;
signal i_eth1cfg_rd                         : std_logic;
signal i_eth1cfg_txd                        : std_logic_vector(15 downto 0);
signal i_eth1cfg_rxd                        : std_logic_vector(15 downto 0);

signal i_eth1_out                        : TEthOUTs;
signal i_eth1_in                         : TEthINs;
signal i_eth1phy_out                     : TEthPhyOUT;
signal i_eth1phy_in                      : TEthPhyIN;
signal i_eth1_tst_out                    : std_logic_vector(31 downto 0);

signal i_eth1tx_cntout                   : std_logic_vector(15 downto 0);
signal sr_btn_S                          : std_logic_vector(0 to 6);
signal i_eth1tx_start                    : std_logic;
signal sr_btn_W                          : std_logic_vector(0 to 6);
signal i_eth1prog_start                  : std_logic;
signal i_eth1_dout                       : std_logic_vector(31 downto 0);
signal i_eth1_dout_wr                    : std_logic;
signal i_eth1_dlen                       : std_logic_vector(15 downto 0);
signal i_t1ms                            : std_logic;



attribute keep : string;
attribute keep of g_host_clk : signal is "true";
attribute keep of i_ethphy_out : signal is "true";
attribute keep of i_eth1phy_out : signal is "true";



--//MAIN
begin

--***********************************************************
--//RESET модулей
--***********************************************************
i_host_rst_n <=lreset_l;

i_gt_X0Y6_rst<=not i_host_rdy;
i_tmr_rst    <=not i_host_rst_n or i_host_rst_all;
i_cfg_rst    <=not i_host_rst_n or i_host_rst_all;
i_eth_rst    <=not i_host_rst_n or i_host_rst_all or i_host_rst_eth or i_usr_rst;
i_vctrl_rst  <=not i_host_rst_n or i_host_rst_all;
i_trc_rst    <=not i_host_rst_n or i_host_rst_all;
i_swt_rst    <=not i_host_rst_n or i_host_rst_all;
i_mem_ctrl_sysin.rst<=not i_host_rst_n or i_host_rst_all or i_host_rst_mem;
i_dsntst_rst <=not i_host_rst_n or i_host_rst_all;
i_hdd_rst    <=not i_host_rst_n or i_host_rst_all or i_usr_rst or i_hdd_rbuf_cfg.greset;
i_arb_mem_rst<=i_mem_ctrl_sysin.rst;

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
p_out_refclkout => i_gt_X0Y6_clkout
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

i_mem_ctrl_sysin.clk<=g_refclk200MHz;
g_usr_highclk<=i_mem_ctrl_sysout.clk;


--***********************************************************
--Модуль конфигурирования устр-в
--***********************************************************
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
p_out_tst            => i_cfg_tst_out,

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
p_in_eth_clk              => i_ethphy_out.clk,                    --g_eth_gt_refclkout,

p_in_eth_rxd_sof          => i_eth_out(0).rxbuf.sof,              --i_eth_rxd_sof,
p_in_eth_rxd_eof          => i_eth_out(0).rxbuf.eof,              --i_eth_rxd_eof,
p_in_eth_rxbuf_din        => i_eth_out(0).rxbuf.din(31 downto 0), --i_eth_rxbuf_din,
p_in_eth_rxbuf_wr         => i_eth_out(0).rxbuf.wr,               --i_eth_rxbuf_wr,
p_out_eth_rxbuf_empty     => i_eth_in(0).rxbuf.empty,             --i_host_rxbuf_empty(C_HDEV_ETH_DBUF),
p_out_eth_rxbuf_full      => i_eth_in(0).rxbuf.full,              --i_eth_rxbuf_full,

p_out_eth_txbuf_dout      => i_eth_in(0).txbuf.dout(31 downto 0), --i_eth_txbuf_dout,
p_in_eth_txbuf_rd         => i_eth_out(0).txbuf.rd,               --i_eth_txbuf_rd,
p_out_eth_txbuf_empty     => i_eth_in(0).txbuf.empty,             --i_eth_txbuf_empty,
p_out_eth_txbuf_full      => i_eth_in(0).txbuf.full,              --i_host_txbuf_full(C_HDEV_ETH_DBUF),


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

pin_out_eth1phy<=i_ethphy_out.pin.rgmii(0);
i_ethphy_in.pin.rgmii(0)<=pin_in_eth1phy;

i_ethphy_in.clk<=i_eth_gt_refclk125;

pin_out_eth1phy_mdc   <='0';
pin_out_eth1phy_txdn<=(others=>'0');
pin_out_sfp_tx_dis<='0';
i_ethphy_in.opt(C_ETHPHY_OPTIN_REFCLK_IODELAY_BIT)<=i_refclk200MHz;
i_ethphy_in.opt(C_ETHPHY_OPTIN_SFP_SD_BIT)<=pin_in_sfp_sd;

gen_fiber : if cmpval(C_PCFG_ETH_PHY_SEL, C_ETH_PHY_FIBER) generate
pin_out_eth1phy_rstn <='1';
obuft_eth1phy_mdoi : OBUFT port map (O => pin_inout_eth1phy_mdoi, I => '0', T => '1'  );
end generate gen_fiber;

gen_rgmii : if cmpval(C_PCFG_ETH_PHY_SEL, C_ETH_PHY_RGMII) generate
pin_out_eth1phy_rstn <=not i_ethphy_out.opt(C_ETHPHY_OPTOUT_RST_BIT);
obuft_eth1phy_mdoi : OBUFT port map (O => pin_inout_eth1phy_mdoi, I => '0', T => '1'  );
end generate gen_rgmii;

gen_ethfiber_ad5T1 : if strcmp(C_PCFG_BOARD,"ALPHA_DATA") generate
--//Значение для перепрограм. мультиплексора CLKIN RocketIO ETH
i_ethphy_in.opt(C_ETHPHY_OPTIN_V5GT_CLKIN_MUX_M_BIT downto C_ETHPHY_OPTIN_V5GT_CLKIN_MUX_L_BIT) <=CONV_STD_LOGIC_VECTOR(16#07#, C_ETHPHY_OPTIN_V5GT_CLKIN_MUX_M_BIT-C_ETHPHY_OPTIN_V5GT_CLKIN_MUX_L_BIT+1);
--//Значение для перепрограм. мультиплексора CLKSOUTH RocketIO ETH
i_ethphy_in.opt(C_ETHPHY_OPTIN_V5GT_SOUTH_MUX_VAL_M_BIT downto C_ETHPHY_OPTIN_V5GT_SOUTH_MUX_VAL_L_BIT)<=CONV_STD_LOGIC_VECTOR(16#00#, C_ETHPHY_OPTIN_V5GT_SOUTH_MUX_VAL_M_BIT-C_ETHPHY_OPTIN_V5GT_SOUTH_MUX_VAL_L_BIT+1);
i_ethphy_in.opt(C_ETHPHY_OPTIN_V5GT_CLKIN_MUX_CNG_BIT)<='1';  --//1- перепрограммирование мультиплексора CLKIN RocketIO ETH
i_ethphy_in.opt(C_ETHPHY_OPTIN_V5GT_SOUTH_MUX_CNG_BIT)<='0';  --//1- перепрограммирование мультиплексора CLKSOUTH RocketIO ETH
i_ethphy_in.opt(C_ETHPHY_OPTIN_V5GT_NORTH_MUX_CNG_BIT)<='0';  --//1- перепрограммирование мультиплексора CLKNORTH RocketIO ETH
i_ethphy_in.opt(C_ETHPHY_OPTIN_DRPCLK_BIT)            <=g_pciexp_gt_refclkout;
end generate gen_ethfiber_ad5T1;

m_eth : dsn_eth
generic map(
G_ETH.gtch_count_max  => C_PCFG_ETH_GTCH_COUNT_MAX,
G_ETH.usrbuf_dwidth   => 32,
G_ETH.phy_dwidth      => C_PCFG_ETH_PHY_DWIDTH,
G_ETH.phy_select      => C_PCFG_ETH_PHY_SEL,
G_ETH.mac_length_swap => 1, --1/0 Поле Length/Type первый мл./ст. байт (0 - по стандарту!!! 1 - как в проекте Вереск)
G_MODULE_USE => C_PCFG_ETH_USE,
G_DBG        => C_PCFG_ETH_DBG,
G_SIM        => G_SIM
)
port map(
-------------------------------
--Конфигурирование
-------------------------------
p_in_cfg_clk      => g_host_clk,

p_in_cfg_adr      => i_cfg_radr(7 downto 0),
p_in_cfg_adr_ld   => i_cfg_radr_ld,
p_in_cfg_adr_fifo => i_cfg_radr_fifo,

p_in_cfg_txdata   => i_cfg_txd,
p_in_cfg_wd       => i_cfg_wr_dev(C_CFGDEV_ETH),

p_out_cfg_rxdata  => i_cfg_rxd_dev(C_CFGDEV_ETH),
p_in_cfg_rd       => i_cfg_rd_dev(C_CFGDEV_ETH),

p_in_cfg_done     => i_cfg_done_dev(C_CFGDEV_ETH),
p_in_cfg_rst      => i_cfg_rst,

-------------------------------
--Связь с UsrBuf
-------------------------------
p_out_eth         => i_eth_out,
p_in_eth          => i_eth_in,

-------------------------------
--ETH
-------------------------------
p_out_ethphy      => i_ethphy_out,
p_in_ethphy       => i_ethphy_in,

-------------------------------
--Технологический
-------------------------------
p_out_dbg         => open,
p_in_tst          => i_eth_tst_out,
p_out_tst         => open,

-------------------------------
--System
-------------------------------
p_in_rst          => i_eth_rst
);


--***********************************************************
--Проект модуля видео контролера - dsn_video_ctrl.vhd
--***********************************************************
i_vctrl_hirq_out<=EXT(i_vctrl_hirq, i_vctrl_hirq_out'length);
i_vctrl_hrdy_out<=EXT(i_vctrl_hrdy, i_vctrl_hrdy_out'length);

m_vctrl : dsn_video_ctrl
generic map(
G_ROTATE => C_PCFG_VCTRL_ROTATE,
G_ROTATE_BUF_COUNT => C_PCFG_VCTRL_ROTATE_BUF_COUNT,
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
i_swt_hdd_tstgen_cfg<=i_hdd_rbuf_cfg.tstgen;

m_hdd : dsn_hdd
generic map(
G_MEM_DWIDTH => C_HDEV_DWIDTH,
G_RAID_DWIDTH=> C_PCFG_HDD_RAID_DWIDTH,
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
p_in_cfg_clk          => g_host_clk,

p_in_cfg_adr          => i_cfg_radr(7 downto 0),
p_in_cfg_adr_ld       => i_cfg_radr_ld,
p_in_cfg_adr_fifo     => i_cfg_radr_fifo,

p_in_cfg_txdata       => i_cfg_txd,
p_in_cfg_wd           => i_cfg_wr_dev(C_CFGDEV_HDD),

p_out_cfg_rxdata      => i_cfg_rxd_dev(C_CFGDEV_HDD),
p_in_cfg_rd           => i_cfg_rd_dev(C_CFGDEV_HDD),

p_in_cfg_done         => i_cfg_done_dev(C_CFGDEV_HDD),
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

p_in_hdd_txd_wrclk    => g_usr_highclk,
p_in_hdd_txd          => i_hdd_txdata,
p_in_hdd_txd_wr       => i_hdd_txdata_wd,
p_out_hdd_txbuf_pfull => i_hdd_txbuf_pfull,
p_out_hdd_txbuf_full  => i_hdd_txbuf_full,
p_out_hdd_txbuf_empty => i_hdd_txbuf_empty,

p_in_hdd_rxd_rdclk    => g_usr_highclk,
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
p_out_sata_dcm_gclk2div=> open,--g_hdd_dcm_gclk75M,
p_out_sata_dcm_gclk2x  => open,--g_hdd_dcm_gclk300M,
p_out_sata_dcm_gclk0   => open,--g_hdd_dcm_gclk150M,

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
G_USE_2CH     => "OFF",
G_MEM_BANK_M_BIT  => C_VCTRL_REG_MEM_ADR_BANK_M_BIT,
G_MEM_BANK_L_BIT  => C_VCTRL_REG_MEM_ADR_BANK_L_BIT,
G_MEM_AWIDTH  => C_HREG_MEM_ADR_LAST_BIT,
G_MEM_DWIDTH  => C_HDEV_DWIDTH
)
port map(
-------------------------------
-- Конфигурирование
-------------------------------
p_in_rbuf_cfg       => i_hdd_rbuf_cfg,
p_out_rbuf_status   => i_hdd_rbuf_status,
p_in_lentrn_exp     => '1',

--//--------------------------
--//Upstream Port(Связь с буфером источника данных)
--//--------------------------
p_in_bufi_dout      => i_hdd_vbuf_dout,
p_out_bufi_rd       => i_hdd_vbuf_rd,
p_in_bufi_empty     => i_hdd_vbuf_empty,
p_in_bufi_full      => i_hdd_vbuf_full,
p_in_bufi_pfull     => i_hdd_vbuf_pfull,
p_in_bufi_wrcnt     => i_hdd_vbuf_wrcnt,

p_out_bufo_din      => open,
p_out_bufo_wr       => open,
p_in_bufo_full      => '0',

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
p_out_memch0         => i_hdd_memin,
p_in_memch0          => i_hdd_memout,

p_out_memch1         => open,
p_in_memch1          => i_hdd_memout_null,

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
i_host_tst_in(75)<=i_mem_ctrl_status.rdy;
i_host_tst_in(76)<='0';--AND_reduce(i_memctrl_trained(C_PCFG_MEMCTRL_BANK_COUNT downto 0));
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

i_host_dev_status(C_HREG_DEV_STATUS_MEMCTRL_RDY_BIT)<=i_mem_ctrl_status.rdy;
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
G_SIM => G_SIM
)
port map(
------------------------------------
--User Post
------------------------------------
p_in_mem        => i_arb_memin,
p_out_mem       => i_arb_memout,

------------------------------------
--Memory physical interface
------------------------------------
p_out_phymem    => pin_out_phymem,
p_inout_phymem  => pin_inout_phymem,

------------------------------------
--Memory status
------------------------------------
p_out_status    => i_mem_ctrl_status,

------------------------------------
--System
------------------------------------
p_out_sys       => i_mem_ctrl_sysout,
p_in_sys        => i_mem_ctrl_sysin
);


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
pin_out_TP(3)<=OR_reduce(i_eth1_out(0).rxbuf.din) or i_eth1tx_start or i_eth1_out(0).rxbuf.wr;
                            --//pin14
pin_out_TP(4)<='0';         --//pin16
                            --//pin18
pin_out_TP(5)<='0';         -- /pin20
                            --//pin22
pin_out_TP(6)<='0';         -- /pin24
pin_out_TP(7)<='0';         -- /pin26

--Светодиоды
pin_out_led_E<=i_test01_led; --;
pin_out_led_N<=i_eth1phy_out.opt(C_ETHPHY_OPTOUT_RST_BIT); --i_hdd_gt_plldet and i_hdd_dcm_lock;
pin_out_led_S<=i_mem_ctrl_status.rdy;
pin_out_led_W<=i_usr_rst;-- when pin_in_btn_W='0' else i_hdd_dbgled(1).spd(1);
pin_out_led_C<=not lclk_dcm_lock or i_usr_rst;-- when pin_in_btn_W='0' else i_hdd_dbgled(1).spd(0);

pin_out_led(0)<=i_hdd_dbgled(1).busy;
pin_out_led(1)<=i_hdd_dbgled(1).wr;
pin_out_led(2)<=i_hdd_dbgled(1).rdy when i_hdd_dbgled(1).err='0' else i_test01_led;
pin_out_led(3)<=i_hdd_dbgled(1).link;

pin_out_led(4)<=i_hdd_dbgled(0).busy;
pin_out_led(5)<=i_hdd_dbgled(0).wr;
pin_out_led(6)<=i_hdd_dbgled(0).rdy when i_hdd_dbgled(0).err='0' else i_test01_led;
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

end generate gen_ml505;


----//DBG:

gen_dbg_hdd : if strcmp(C_PCFG_HDD_DBGCS,"ON") generate

m_dbgcs_icon : dbgcs_iconx1
port map(
CONTROL0 => i_dbgcs_hdd_raid
);

m_dbgcs_sh0_raid : dbgcs_sata_raid
port map(
CONTROL => i_dbgcs_hdd_raid,
CLK     => i_hdd_dbgcs.raid.clk,
DATA    => i_hddraid_dbgcs.data(172 downto 0),--(122 downto 0),
TRIG0   => i_hddraid_dbgcs.trig0(41 downto 0)
);

--//-------- TRIG: ------------------
i_hddraid_dbgcs.trig0(18 downto 0)<=i_hdd_dbgcs.raid.trig0(18 downto 0);
i_hddraid_dbgcs.trig0(19)<=i_hdd_rbuf_status.err;--i_hdd_tst_out(5);--<=i_sh_cxd_rd;

--//SH0
i_hddraid_dbgcs.trig0(24 downto 20)<=i_hdd_dbgcs.sh(0).layer.trig0(34 downto 30);--llayer
i_hddraid_dbgcs.trig0(29 downto 25)<=i_hdd_dbgcs.sh(0).layer.trig0(39 downto 35);--tlayer
--//SH1
i_hddraid_dbgcs.trig0(34 downto 30)<=i_hdd_dbgcs.sh(1).layer.trig0(34 downto 30);--llayer
i_hddraid_dbgcs.trig0(39 downto 35)<=i_hdd_dbgcs.sh(1).layer.trig0(39 downto 35);--tlayer

i_hddraid_dbgcs.trig0(40)<=i_hdd_txbuf_empty;
i_hddraid_dbgcs.trig0(41)<=i_hdd_vbuf_empty;--i_hdd_txbuf_pfull;


--//-------- VIEW: ------------------
i_hddraid_dbgcs.data(28 downto 0)<=i_hdd_dbgcs.raid.data(28 downto 0);
i_hddraid_dbgcs.data(29)<=i_hdd_txbuf_pfull;

--//SH0
i_hddraid_dbgcs.data(34 downto 30)<=i_hdd_dbgcs.sh(0).layer.trig0(34 downto 30);--llayer
i_hddraid_dbgcs.data(39 downto 35)<=i_hdd_dbgcs.sh(0).layer.trig0(39 downto 35);--tlayer
i_hddraid_dbgcs.data(55 downto 40)<=i_hdd_dbgcs.sh(0).layer.data(65 downto 50);
i_hddraid_dbgcs.data(56)          <=i_hdd_dbgcs.sh(0).layer.data(49);--p_in_ll_rxd_wr; --llayer->tlayer
i_hddraid_dbgcs.data(57)          <=i_hdd_dbgcs.sh(0).layer.data(116);--p_in_ll_txd_rd; --llayer<-tlayer
i_hddraid_dbgcs.data(58)          <=i_hdd_dbgcs.sh(0).layer.data(118);--<=p_in_dbg.llayer.txbuf_status.aempty;
i_hddraid_dbgcs.data(59)          <=i_hdd_dbgcs.sh(0).layer.data(119);--<=p_in_dbg.llayer.txbuf_status.empty;
i_hddraid_dbgcs.data(60)          <=i_hdd_dbgcs.sh(0).layer.data(98);--<=p_in_dbg.llayer.rxbuf_status.pfull;
i_hddraid_dbgcs.data(61)          <=i_hdd_dbgcs.sh(0).layer.data(99);--<=p_in_dbg.llayer.txbuf_status.pfull;
i_hddraid_dbgcs.data(62)          <=i_hdd_dbgcs.sh(0).layer.data(117);--<=p_in_dbg.llayer.txd_close;

--//SH1
i_hddraid_dbgcs.data(67 downto 63)<=i_hdd_dbgcs.sh(1).layer.trig0(34 downto 30);--llayer
i_hddraid_dbgcs.data(72 downto 68)<=i_hdd_dbgcs.sh(1).layer.trig0(39 downto 35);--tlayer
i_hddraid_dbgcs.data(88 downto 73)<=i_hdd_dbgcs.sh(1).layer.data(65 downto 50);
i_hddraid_dbgcs.data(89)          <=i_hdd_dbgcs.sh(1).layer.data(49);--p_in_ll_rxd_wr; --llayer->tlayer
i_hddraid_dbgcs.data(90)          <=i_hdd_dbgcs.sh(1).layer.data(116);--p_in_ll_txd_rd; --llayer<-tlayer
i_hddraid_dbgcs.data(91)          <=i_hdd_dbgcs.sh(1).layer.data(118);--<=p_in_dbg.llayer.txbuf_status.aempty;
i_hddraid_dbgcs.data(92)          <=i_hdd_dbgcs.sh(1).layer.data(119);--<=p_in_dbg.llayer.txbuf_status.empty;
i_hddraid_dbgcs.data(93)          <=i_hdd_dbgcs.sh(1).layer.data(98);--<=p_in_dbg.llayer.rxbuf_status.pfull;
i_hddraid_dbgcs.data(94)          <=i_hdd_dbgcs.sh(1).layer.data(99);--<=p_in_dbg.llayer.txbuf_status.pfull;
i_hddraid_dbgcs.data(95)          <=i_hdd_dbgcs.sh(1).layer.data(117);--<=p_in_dbg.llayer.txd_close;

--//RAMBUF
i_hddraid_dbgcs.data(103 downto 100)<=i_hdd_rbuf_tst_out(29 downto 26);--<=tst_fsm_cs;
i_hddraid_dbgcs.data(104)<=i_hdd_txbuf_empty;
i_hddraid_dbgcs.data(105)<=i_hdd_rxbuf_empty;
i_hddraid_dbgcs.data(106)<=i_hdd_rbuf_status.err_type.rambuf_full;--i_hdd_txdata_wd;--RAM->HDD
i_hddraid_dbgcs.data(107)<=i_hdd_rbuf_status.err_type.bufi_full;--i_hdd_rxdata_rd;--RAM<-HDD
i_hddraid_dbgcs.data(108)<=i_hdd_rbuf_tst_out(11);--<=tst_rambuf_empty;
--i_hddraid_dbgcs.data(140 downto 109)<=i_hdd_dbgcs.raid.data(161 downto 130);--i_usr_rxd;--RAM<-HDD
--i_hddraid_dbgcs.data(172 downto 141)<=i_hdd_rxdata(31 downto 0);--RAM<-HDD

i_hddraid_dbgcs.data(109)<=i_hdd_memin.req;
i_hddraid_dbgcs.data(110)<=i_hdd_memin.ce;
i_hddraid_dbgcs.data(111)<=i_hdd_memin.cw;
i_hddraid_dbgcs.data(112)<=i_hdd_memin.term;
i_hddraid_dbgcs.data(113)<=i_hdd_memin.wr;
i_hddraid_dbgcs.data(114)<=i_hdd_memin.rd;

i_hddraid_dbgcs.data(115)<=i_arb_memin.req;
i_hddraid_dbgcs.data(116)<=i_arb_memin.ce;
i_hddraid_dbgcs.data(117)<=i_arb_memin.cw;
i_hddraid_dbgcs.data(118)<=i_arb_memin.term;
i_hddraid_dbgcs.data(119)<=i_arb_memin.wr;
i_hddraid_dbgcs.data(120)<=i_arb_memin.rd;

i_hddraid_dbgcs.data(121)<=i_swt_tst_out(1);--<=i_hdd_tst_den;
i_hddraid_dbgcs.data(122)<=i_hdd_vbuf_empty;
i_hddraid_dbgcs.data(123)<=i_hdd_vbuf_full;

i_hddraid_dbgcs.data(127 downto 124)<=(i_hdd_rbuf_tst_out(16) & i_hdd_rbuf_tst_out(4 downto 2));--write <=tst_fsm_cs(2 downto 0);
i_hddraid_dbgcs.data(131 downto 128)<=(i_hdd_rbuf_tst_out(17) & i_hdd_rbuf_tst_out(9 downto 7));--read  <=tst_fsm_cs(2 downto 0);

i_hddraid_dbgcs.data(132)<=i_hdd_rbuf_tst_out(15);--i_padding

end generate gen_dbg_hdd;


--m_dbgcs_icon : dbgcs_iconx2
--port map(
--CONTROL0 => i_dbgcs_memaxi,
--CONTROL1 => i_dbgcs_mem
--);
--
----//###
--m_dbgcs_memaxi : dbgcs_sata_raid_b
--port map(
--CONTROL => i_dbgcs_memaxi,
--CLK     => g_host_clk,
--DATA    => i_dbgcs_memaxi_view(255 downto 0),--(172 downto 0),--(122 downto 0),
--TRIG0   => i_dbgcs_memaxi_trg(41 downto 0)
--);
--
----//-------- TRIG: ------------------
--i_dbgcs_memaxi_trg(3 downto  0) <=i_host_tst_out(43 downto 40);--i_dmabuf_done_cnt;--//Счетчик отработаных буферов
--i_dbgcs_memaxi_trg(4)           <=i_host_mem_ctrl.start;
--i_dbgcs_memaxi_trg(5)           <=i_host_mem_ctrl.dir;
--i_dbgcs_memaxi_trg(6)           <=i_host_tst_out(57) and i_host_tst_out(56);-- <=i_trn_done;
--
--i_dbgcs_memaxi_trg(7)          <=i_host_tst_out(96) ;--i_irq_src_clr;--//Clr IRQ
--i_dbgcs_memaxi_trg(8)          <=i_host_tst_out(117);--i_dmatotal_mwr_done and i_dma_mwr_done_del;
--i_dbgcs_memaxi_trg(9)          <=i_host_tst_out(118);--i_dmatotal_mrd_done and i_dma_mrd_done_del;
--i_dbgcs_memaxi_trg(10)         <=i_host_tst_out(118) or i_host_tst_out(117);--i_dmatotal_mrd_done and i_dma_mrd_done_del;
--i_dbgcs_memaxi_trg(11)         <=i_host_tst2_out(0); --cfg_interrupt_n;
--i_dbgcs_memaxi_trg(12)         <=i_host_tst2_out(1); --cfg_interrupt_rdy_n;
--i_dbgcs_memaxi_trg(13)         <=i_host_tst2_out(2); --cfg_interrupt_assert_n;
--i_dbgcs_memaxi_trg(14)         <=i_host_tst2_out(3); --cfg_interrupt_msienable;
--
--i_dbgcs_memaxi_trg(15)         <=i_host_tst2_out(4); --trn_tsof_n,
--i_dbgcs_memaxi_trg(16)         <=i_host_tst2_out(9); --trn_rsof_n,
--
--i_dbgcs_memaxi_trg(17)         <=i_host_tst2_out(14);--trn_rbar_hit_n(0);
--i_dbgcs_memaxi_trg(18)         <=i_host_tst2_out(15);--trn_rbar_hit_n(1);
--
--i_dbgcs_memaxi_trg(22 downto 19)<=i_host_devadr(3 downto 0);--i_host_tst_out(61 downto 58);--<=i_hdev_adr;
--i_dbgcs_memaxi_trg(30 downto 23)<=i_host_tst_out(108 downto 101);--i_irq_src_act(7 downto 0);--//Status IRQx
--i_dbgcs_memaxi_trg(31)          <=i_host_tst_out(123);--p_out_usr_tst(123)<=i_tst_rd; Чтение рег FIRMWARE
--i_dbgcs_memaxi_trg(32)          <=i_cfg_done_dev(C_CFGDEV_TMR);
--i_dbgcs_memaxi_trg(33)          <=i_host_tst_out(0);--бит(0) регистра C_HOST_REG_TST0
--i_dbgcs_memaxi_trg(34)          <=i_host_tst_out(123);--i_dmatrn_init;
--i_dbgcs_memaxi_trg(35)          <=i_host_tst_out(124);--i_dma_start;
--i_dbgcs_memaxi_trg(36)          <=i_cfg_wr_dev(C_CFGDEV_VCTRL);
--i_dbgcs_memaxi_trg(37)          <=i_cfg_rd_dev(C_CFGDEV_VCTRL);
--i_dbgcs_memaxi_trg(38)          <=i_cfg_done_dev(C_CFGDEV_VCTRL);
--i_dbgcs_memaxi_trg(39)          <=i_host_dev_wr;
--i_dbgcs_memaxi_trg(40)          <=i_host_dev_rd;
--i_dbgcs_memaxi_trg(41)          <='0';
--
--
----//-------- VIEW: ------------------
--i_dbgcs_memaxi_view(17 downto  0) <=i_host_mem_ctrl.req_len;
--i_dbgcs_memaxi_view(21 downto  18)<=i_host_devadr(3 downto 0);
--i_dbgcs_memaxi_view(22)           <=i_host_tst_out(125);--cpld_tpl_work;
--i_dbgcs_memaxi_view(23)           <=i_host_tst_out(126);--trn_rdw_sel
--i_dbgcs_memaxi_view(24)           <=i_host_tst_out(56); --i_dmatrn_mem_done(0)
--i_dbgcs_memaxi_view(25)           <=i_host_tst_out(57); --i_dmatrn_mem_done(1)
--i_dbgcs_memaxi_view(26)           <=i_host_tst_out(124);--i_dma_start;
--i_dbgcs_memaxi_view(27)           <=i_host_tst_out(123);--i_dmatrn_init;
--i_dbgcs_memaxi_view(28)           <=i_host_tst_out(120);--p_in_throttle_tst(0); --//mrd_work_throttle
--i_dbgcs_memaxi_view(29)           <=i_host_tst_out(62); --p_in_cpld_malformed;
--i_dbgcs_memaxi_view(30)           <=i_host_mem_ctrl.start;
--i_dbgcs_memaxi_view(31)           <=i_host_mem_status.done;
--i_dbgcs_memaxi_view(49 downto  32)<=i_host_mem_ctrl.adr(17 downto 0);
--i_dbgcs_memaxi_view(60 downto 50) <=i_host_tst_out(74 downto 64);--p_in_cpld_total_size;
--
--i_dbgcs_memaxi_view(79 downto 61) <=i_host_tst2_out(114 downto 96);--p_out_tst(159 downto 96)<=trn_rd;
----i_dbgcs_memaxi_view(74 downto 70) <=(others=>'0');
----
----i_dbgcs_memaxi_view(75)           <=i_host_mem_status.done;
----i_dbgcs_memaxi_view(76)           <=i_host_mem_ctrl.dir;
----i_dbgcs_memaxi_view(77)           <=i_host_mem_ctrl.start;
----i_dbgcs_memaxi_view(78)           <=i_host_tst_out(119);--i_dmatrn_mwr_done;
----i_dbgcs_memaxi_view(79)           <=i_host_tst_out(122);--i_dmatrn_mrd_done;
--
--i_dbgcs_memaxi_view(80)            <=i_host_dev_wr;
--i_dbgcs_memaxi_view(81)            <=i_host_dev_opt_in(C_HDEV_OPTIN_TXFIFO_PFULL_BIT);
--i_dbgcs_memaxi_view(82)            <=i_host_mem_tst_out(8);--i_txbuf_empty;
--i_dbgcs_memaxi_view(83)            <=i_host_dev_rd;
--i_dbgcs_memaxi_view(84)            <=i_host_dev_opt_in(C_HDEV_OPTIN_RXFIFO_EMPTY_BIT);
--i_dbgcs_memaxi_view(85)            <=i_host_mem_tst_out(7);--i_rxbuf_full;
--
--i_dbgcs_memaxi_view(86)            <=i_host_tst_out(96)            ;--i_irq_src_clr;--//Clr IRQ
--i_dbgcs_memaxi_view(90 downto 87)  <=i_host_tst2_out(121 downto 118);--p_out_tst(159 downto 96)<=trn_rd;
--i_dbgcs_memaxi_view(98 downto 91)  <=i_host_tst_out(108 downto 101);--i_irq_src_act(7 downto 0);--//Status IRQx
--i_dbgcs_memaxi_view(106 downto 99) <=i_host_tst_out(116 downto 109);--i_irq_src_set(7 downto 0);--//Set    IRQx
--i_dbgcs_memaxi_view(107)           <='0';--i_host_tst2_out(120);--p_out_tst(159 downto 96)<=trn_rd;
--i_dbgcs_memaxi_view(108)           <='0';--i_host_tst2_out(121);--p_out_tst(159 downto 96)<=trn_rd;
--
--i_dbgcs_memaxi_view(109)           <=i_host_tst2_out(0); --cfg_interrupt_n;
--i_dbgcs_memaxi_view(110)           <=i_host_tst2_out(1); --cfg_interrupt_rdy_n;
--i_dbgcs_memaxi_view(111)           <=i_host_tst2_out(2); --cfg_interrupt_assert_n;
--i_dbgcs_memaxi_view(112)           <=i_host_tst2_out(3); --cfg_interrupt_msienable;
--
--i_dbgcs_memaxi_view(113)           <=i_host_tst2_out(4); --trn_tsof_n,
--i_dbgcs_memaxi_view(114)           <=i_host_tst2_out(5); --trn_teof_n,
--i_dbgcs_memaxi_view(115)           <=i_host_tst2_out(6); --trn_tsrc_rdy_n,
--i_dbgcs_memaxi_view(116)           <=i_host_tst2_out(7); --trn_tdst_rdy_n,
--i_dbgcs_memaxi_view(117)           <=i_host_tst2_out(8); --trn_tsrc_dsc_n,
--i_dbgcs_memaxi_view(118)           <=i_host_tst2_out(9); --trn_rsof_n,
--i_dbgcs_memaxi_view(119)           <=i_host_tst2_out(10);--trn_reof_n,
--i_dbgcs_memaxi_view(120)           <=i_host_tst2_out(11);--trn_rsrc_rdy_n,
--i_dbgcs_memaxi_view(121)           <=i_host_tst2_out(12);--trn_rsrc_dsc_n,
--i_dbgcs_memaxi_view(122)           <=i_host_tst2_out(13);--trn_rdst_rdy_n,
--
--i_dbgcs_memaxi_view(123)           <=i_host_tst2_out(14);--trn_rbar_hit_n(0);
--i_dbgcs_memaxi_view(124)           <=i_host_tst2_out(15);--trn_rbar_hit_n(1);
--
--i_dbgcs_memaxi_view(169 downto 125)<=i_host_tst2_out(159 downto 115);--p_out_tst(159 downto 96)<=trn_rd;
--i_dbgcs_memaxi_view(170)           <=i_host_tst_out(121); --i_cpld_done;
--i_dbgcs_memaxi_view(171)           <=i_host_tst_out(127); --p_in_txbuf_wr_last;
--i_dbgcs_memaxi_view(172)           <=i_host_tst2_out(160);--trn_rrem_n(0);;
--
--i_dbgcs_memaxi_view(179 downto 173)<=i_host_tst_out(38 downto 32);--p_in_mrd_pkt_len_tst(15 downto 0);
--
--i_dbgcs_memaxi_view(211 downto 180)<=i_host_dev_txd;
----i_dbgcs_memaxi_view(243 downto 212)<=i_host_dev_rxd;
--
--i_dbgcs_memaxi_view(227 downto 212)<=i_host_tst2_out(215 downto 200); --//cur_rd_count_hwm_o
--i_dbgcs_memaxi_view(243 downto 228)<=i_host_tst2_out(231 downto 216); --//cpld_data_size_hwm_o
--i_dbgcs_memaxi_view(244)           <=i_host_tst2_out(248);--cpld_found
--i_dbgcs_memaxi_view(255 downto 245)<=(others=>'0');
--
----i_dbgcs_memaxi_view(187 downto 180)<=i_cfg_radr(7 downto 0);
----i_dbgcs_memaxi_view(188)<=i_cfg_radr_ld;
----i_dbgcs_memaxi_view(189)<=i_cfg_radr_fifo;
----i_dbgcs_memaxi_view(190)<=i_cfg_wr_dev(C_CFGDEV_VCTRL);
----i_dbgcs_memaxi_view(191)<=i_cfg_rd_dev(C_CFGDEV_VCTRL);
----i_dbgcs_memaxi_view(192)<=i_cfg_done_dev(C_CFGDEV_VCTRL);
----i_dbgcs_memaxi_view(211 downto 193)<=(others=>'0');
----i_dbgcs_memaxi_view(227 downto 212)<=i_cfg_txd;
----i_dbgcs_memaxi_view(243 downto 228)<=i_cfg_rxd_dev(C_CFGDEV_VCTRL);
--
--
--
--
--
--
--m_dbgcs_mem : dbgcs_sata_raid_b
--port map(
--CONTROL => i_dbgcs_mem,
--CLK     => g_usr_highclk,
--DATA    => i_dbgcs_mem_view(255 downto 0),--(172 downto 0),--(122 downto 0),
--TRIG0   => i_dbgcs_mem_trg(41 downto 0)
--);
--
----//-------- TRIG: ------------------
--i_dbgcs_mem_trg(3 downto  0) <=(others=>'0');
--i_dbgcs_mem_trg(4)           <=i_host_mem_tst_out(0);--i_mem_start;
--i_dbgcs_mem_trg(5)           <=i_arb_memin.ce;
--i_dbgcs_mem_trg(6)           <=i_host_mem_tst_out(1);--i_mem_done;
--i_dbgcs_mem_trg(33)          <=i_host_tst_out(0);--бит(0) регистра C_HOST_REG_TST0
--i_dbgcs_mem_trg(34)          <=i_host_memin.req;
--i_dbgcs_mem_trg(35)          <=i_vctrlwr_memin.req;
--i_dbgcs_mem_trg(36)          <=i_vctrlrd_memin.req;
--i_dbgcs_mem_trg(37)          <=i_hdd_memin.req;
--i_dbgcs_mem_trg(38)          <=i_trc_memin.req;
--i_dbgcs_mem_trg(39)          <=i_vctrl_hrd_start;
--i_dbgcs_mem_trg(41 downto 40)<=(others=>'0');
--
--
----//-------- VIEW: ------------------
--i_dbgcs_mem_view(3 downto 0)    <=i_host_mem_tst_out(5 downto 2);--m_mem_wr/tst_fsm_cs;
--i_dbgcs_mem_view(4)             <=i_host_mem_tst_out(0);--i_mem_start;
--i_dbgcs_mem_view(5)             <=i_arb_memin.ce;
--i_dbgcs_mem_view(6)             <=i_arb_memin.term;
--i_dbgcs_mem_view(7)             <=i_arb_memin.rd;
--i_dbgcs_mem_view(8)             <=i_arb_memin.wr;
--i_dbgcs_mem_view(9)             <=i_arb_memin.cw;
--i_dbgcs_mem_view(10)            <=i_arb_memout.buf_wpf;
--i_dbgcs_mem_view(11)            <=i_arb_memout.buf_re;
--i_dbgcs_mem_view(12)            <='0';
--i_dbgcs_mem_view(13)            <=i_arb_memin.req;
--i_dbgcs_mem_view(14)            <=i_arb_memout.req_en;
--i_dbgcs_mem_view(15)            <=i_host_mem_status.done;
--
--i_dbgcs_mem_view(19 downto 16)  <=i_arb_memin.bank(3 downto 0);
--i_dbgcs_mem_view(25 downto 20)  <=(others=>'0');
--
--i_dbgcs_mem_view(31 downto 26)  <=i_host_mem_tst_out(31 downto 26);--(31 downto 16);--m_mem_wr/i_mem_trn_len(5 downto 0);
--i_dbgcs_mem_view(63 downto 32)  <=i_arb_memin.adr(31 downto 0);
--i_dbgcs_mem_view(95 downto 64)  <=i_arb_memin.data(31 downto 0);
--i_dbgcs_mem_view(127 downto 96) <=i_arb_memout.data(31 downto 0);
--i_dbgcs_mem_view(143 downto 128)<=i_host_mem_tst_out(25 downto 10);--m_mem_wr/i_mem_lenreq(15 downto 0)
--
--i_dbgcs_mem_view(144)           <=i_host_mem_tst_out(6);--i_rxbuf_empty;
--i_dbgcs_mem_view(145)           <=i_host_mem_tst_out(7);--i_rxbuf_full;
--i_dbgcs_mem_view(146)           <=i_host_mem_tst_out(8);--i_txbuf_empty;
--i_dbgcs_mem_view(147)           <=i_host_mem_tst_out(9);--i_txbuf_full;
--
--i_dbgcs_mem_view(148)           <=i_host_memin.req;
--i_dbgcs_mem_view(149)           <=i_vctrlwr_memin.req;
--i_dbgcs_mem_view(150)           <=i_vctrlrd_memin.req;
--i_dbgcs_mem_view(151)           <=i_hdd_memin.req;
--i_dbgcs_mem_view(152)           <=i_trc_memin.req;
--
----i_dbgcs_mem_view(153)           <=i_host_memin.cw;
----i_dbgcs_mem_view(154)           <=i_host_memin.ce;
----i_dbgcs_mem_view(155)           <=i_host_memin.wr;
----i_dbgcs_mem_view(156)           <=i_host_memin.rd;
----i_dbgcs_mem_view(157)           <=i_host_memin.term;
----i_dbgcs_mem_view(158)           <=i_host_memout.buf_wpf;
----i_dbgcs_mem_view(159)           <=i_host_memout.buf_re;
--
--i_dbgcs_mem_view(172 downto 158)<=(others=>'0');
--i_dbgcs_mem_view(255 downto 173)<=(others=>'0');
--
--
--
------//DBG:
----m_dbgcs_icon : dbgcs_iconx3
----port map(
----CONTROL0 => i_dbgcs_memaxi,
----CONTROL1 => i_dbgcs_int0,
----CONTROL2 => i_dbgcs_int1
----);
----
------//###
----m_dbgcs_memaxi : dbgcs_sata_raid_b
----port map(
----CONTROL => i_dbgcs_memaxi,
----CLK     => g_host_clk,
----DATA    => i_dbgcs_memaxi_view(172 downto 0),--(122 downto 0),
----TRIG0   => i_dbgcs_memaxi_trg(41 downto 0)
----);
----
------//-------- TRIG: ------------------
----i_dbgcs_memaxi_trg(3 downto  0) <=(others=>'0');
----i_dbgcs_memaxi_trg(4)           <=i_host_mem_ce;
----i_dbgcs_memaxi_trg(5)           <=i_host_mem_cw;
----i_dbgcs_memaxi_trg(6)           <='0';
----
----i_dbgcs_memaxi_trg(7)          <=i_host_tst_out(96) ;--<=i_irq_src_clr;--//Clr IRQ
----i_dbgcs_memaxi_trg(8)          <=i_host_tst_out(117);--<=i_dmatotal_mwr_done and i_dma_mwr_done_del;
----i_dbgcs_memaxi_trg(9)          <=i_host_tst_out(118);--<=i_dmatotal_mrd_done and i_dma_mrd_done_del;
----i_dbgcs_memaxi_trg(10)         <=i_host_tst_out(118) or i_host_tst_out(117);--<=i_dmatotal_mrd_done and i_dma_mrd_done_del;
----i_dbgcs_memaxi_trg(11)         <=i_host_tst2_out(0);--p_out_tst(0)<=cfg_interrupt_n;
----i_dbgcs_memaxi_trg(12)         <=i_host_tst2_out(1);--p_out_tst(1)<=cfg_interrupt_rdy_n;
----i_dbgcs_memaxi_trg(13)         <=i_host_tst2_out(2);--p_out_tst(2)<=cfg_interrupt_assert_n;
----i_dbgcs_memaxi_trg(14)         <=i_host_tst2_out(3);--p_out_tst(3)<=cfg_interrupt_msienable;
----
----i_dbgcs_memaxi_trg(15)         <=i_host_tst2_out(4);--p_out_tst(4)<=trn_tsof_n,
----i_dbgcs_memaxi_trg(16)         <=i_host_tst2_out(9);--p_out_tst(9)<=trn_rsof_n,
----
----i_dbgcs_memaxi_trg(17)         <=i_host_tst2_out(14);--p_out_tst(14)<=trn_rbar_hit_n(0);
----i_dbgcs_memaxi_trg(18)         <=i_host_tst2_out(15);--p_out_tst(15)<=trn_rbar_hit_n(1);
----
----i_dbgcs_memaxi_trg(19)          <=i_host_tst_out(119);--p_out_usr_tst(119)<=v_reg_pciexp_ctrl(C_HREG_PCIE_MSI_EN_BIT);
----i_dbgcs_memaxi_trg(20)          <=i_host_tst_out(120);--p_out_usr_tst(120)<=p_in_cfg_msi_enable;
----i_dbgcs_memaxi_trg(21)          <=i_host_tst2_out(16);--p_out_tst(16)<=cfg_command(2);--//cfg_bus_mstr_enable
----i_dbgcs_memaxi_trg(22)          <=i_host_tst_out(121);--p_out_usr_tst(121)<=p_in_cfg_intrrupt_disable;
----i_dbgcs_memaxi_trg(30 downto 23)<=i_host_tst_out(108 downto 101);--<=i_irq_src_act(7 downto 0);--//Status IRQx
----i_dbgcs_memaxi_trg(31)          <=i_host_tst_out(123);--p_out_usr_tst(123)<=i_tst_rd; Чтение рег FIRMWARE
----i_dbgcs_memaxi_trg(32)          <=i_cfg_done_dev(C_CFGDEV_TMR);
----i_dbgcs_memaxi_trg(33)          <=i_host_tst_out(0);--бит(0) регистра C_HOST_REG_TST0
----i_dbgcs_memaxi_trg(41 downto 34) <=(others=>'0');
----
----
------//-------- VIEW: ------------------
----i_dbgcs_memaxi_view(63 downto  0)<=i_host_tst2_out(95 downto 32);--p_out_tst(95 downto 32)<=trn_td;
----i_dbgcs_memaxi_view(85 downto 64)<=i_host_tst2_out(117 downto 96);--p_out_tst(159 downto 96)<=trn_rd;
----
----i_dbgcs_memaxi_view(86)           <=i_host_tst_out(96)            ;--<=i_irq_src_clr;--//Clr IRQ
----i_dbgcs_memaxi_view(90 downto 87) <=i_host_tst2_out(121 downto 118);--p_out_tst(159 downto 96)<=trn_rd;
----i_dbgcs_memaxi_view(98 downto 91) <=i_host_tst_out(108 downto 101);--<=i_irq_src_act(7 downto 0);--//Status IRQx
----i_dbgcs_memaxi_view(106 downto 99)<=i_host_tst_out(116 downto 109);--<=i_irq_src_set(7 downto 0);--//Set    IRQx
----i_dbgcs_memaxi_view(107)          <='0';--i_host_tst2_out(120);--p_out_tst(159 downto 96)<=trn_rd;
----i_dbgcs_memaxi_view(108)          <='0';--i_host_tst2_out(121);--p_out_tst(159 downto 96)<=trn_rd;
----
----i_dbgcs_memaxi_view(109)         <=i_host_tst2_out(0);--p_out_tst(0)<=cfg_interrupt_n;
----i_dbgcs_memaxi_view(110)         <=i_host_tst2_out(1);--p_out_tst(1)<=cfg_interrupt_rdy_n;
----i_dbgcs_memaxi_view(111)         <=i_host_tst2_out(2);--p_out_tst(2)<=cfg_interrupt_assert_n;
----i_dbgcs_memaxi_view(112)         <=i_host_tst2_out(3);--p_out_tst(3)<=cfg_interrupt_msienable;
----
----i_dbgcs_memaxi_view(113)         <=i_host_tst2_out(4);--p_out_tst(4)<=trn_tsof_n,
----i_dbgcs_memaxi_view(114)         <=i_host_tst2_out(5);--p_out_tst(5)<=trn_teof_n,
----i_dbgcs_memaxi_view(115)         <=i_host_tst2_out(6);--p_out_tst(6)<=trn_tsrc_rdy_n,
----i_dbgcs_memaxi_view(116)         <=i_host_tst2_out(7);--p_out_tst(7)<=trn_tdst_rdy_n,
----i_dbgcs_memaxi_view(117)         <=i_host_tst2_out(8);--p_out_tst(8)<=trn_tsrc_dsc_n,
----i_dbgcs_memaxi_view(118)         <=i_host_tst2_out(9);--p_out_tst(9)<=trn_rsof_n,
----i_dbgcs_memaxi_view(119)         <=i_host_tst2_out(10);--p_out_tst(10)<=trn_reof_n,
----i_dbgcs_memaxi_view(120)         <=i_host_tst2_out(11);--p_out_tst(11)<=trn_rsrc_rdy_n,
----i_dbgcs_memaxi_view(121)         <=i_host_tst2_out(12);--p_out_tst(12)<=trn_rsrc_dsc_n,
----i_dbgcs_memaxi_view(122)         <=i_host_tst2_out(13);--p_out_tst(13)<=trn_rdst_rdy_n,
----
----i_dbgcs_memaxi_view(123)         <=i_host_tst2_out(14);--p_out_tst(14)<=trn_rbar_hit_n(0);
----i_dbgcs_memaxi_view(124)         <=i_host_tst2_out(15);--p_out_tst(15)<=trn_rbar_hit_n(1);
----
----i_dbgcs_memaxi_view(125)          <=i_host_tst_out(119);--p_out_usr_tst(119)<=v_reg_pciexp_ctrl(C_HREG_PCIE_MSI_EN_BIT);
----i_dbgcs_memaxi_view(126)          <=i_host_tst_out(120);--p_out_usr_tst(120)<=p_in_cfg_msi_enable;
----i_dbgcs_memaxi_view(127)          <=i_host_tst2_out(16);--p_out_tst(16)<=cfg_command(2);--//cfg_bus_mstr_enable
----i_dbgcs_memaxi_view(130 downto 128) <=i_host_tst2_out(19 downto 17);--p_out_tst(19 downto 17)<=cfg_interrupt_mmenable(2 downto 0);
----i_dbgcs_memaxi_view(131)           <=i_host_tst_out(121);--p_out_usr_tst(121)<=p_in_cfg_intrrupt_disable;
----i_dbgcs_memaxi_view(169 downto 132)<=i_host_tst2_out(159 downto 122);--p_out_tst(159 downto 96)<=trn_rd;
----i_dbgcs_memaxi_view(170)<=i_host_tst_out(123);--p_out_usr_tst(123)<=i_tst_rd; Чтение рег FIRMWARE
----i_dbgcs_memaxi_view(171)          <=i_host_tst_out(0);--бит(0) регистра C_HOST_REG_TST0
----
----
----m_dbgcs_int0: dbgcs_cfg
----port map(
----CONTROL => i_dbgcs_int0,
----CLK     => g_host_clk,
----DATA    => i_dbgcs_int0_view(31 downto 0),--(122 downto 0),
----TRIG0   => i_dbgcs_int0_trg(15 downto 0)
----);
----
------//-------- TRIG: ------------------
----i_dbgcs_int0_trg(0)         <=i_host_tst_out(96) ;--<=i_irq_src_clr;--//Clr IRQ
----i_dbgcs_int0_trg(1)         <=i_host_tst_out(117);--<=i_dmatotal_mwr_done and i_dma_mwr_done_del;
----i_dbgcs_int0_trg(2)         <=i_host_tst_out(110);--C_HIRQ_PCIE_DMA_RD                       : integer:=16#01#;--//TRN: PC->FPGA
----i_dbgcs_int0_trg(3)         <=i_host_tst_out(118) or i_host_tst_out(117);--<=i_dmatotal_mrd_done and i_dma_mrd_done_del;
----i_dbgcs_int0_trg(4)         <=i_host_tst2_out(0);--p_out_tst(0)<=cfg_interrupt_n;
----i_dbgcs_int0_trg(5)         <=i_host_tst2_out(1);--p_out_tst(1)<=cfg_interrupt_rdy_n;
----i_dbgcs_int0_trg(6)         <=i_host_tst2_out(2);--p_out_tst(2)<=cfg_interrupt_assert_n;
----i_dbgcs_int0_trg(7)         <=i_host_tst2_out(3);--p_out_tst(3)<=cfg_interrupt_msienable;
----i_dbgcs_int0_trg(8)         <=i_host_mem_ce;
----i_dbgcs_int0_trg(9)         <=i_host_tst_out(119);--p_out_usr_tst(119)<=v_reg_pciexp_ctrl(C_HREG_PCIE_MSI_EN_BIT);
----i_dbgcs_int0_trg(10)        <=i_host_tst_out(120);--p_out_usr_tst(120)<=p_in_cfg_msi_enable;
----i_dbgcs_int0_trg(11)        <=i_host_tst2_out(16);--p_out_tst(16)<=cfg_command(2);--//cfg_bus_mstr_enable
----i_dbgcs_int0_trg(12)        <=i_host_tst_out(122);--p_out_usr_tst(122)           <=i_trn_rst_sw;
----i_dbgcs_int0_trg(15 downto 13)<=(others=>'0');
----
----
------//-------- VIEW: ------------------
----i_dbgcs_int0_view(0)           <=i_host_tst_out(96)            ;--<=i_irq_src_clr;--//Clr IRQ
----i_dbgcs_int0_view(4 downto  1) <=i_host_tst_out(100 downto 97) ;--<=b_irq_src_idx(3 downto 0);--Номер для гашения IRQ
----i_dbgcs_int0_view(12 downto 5) <=i_host_tst_out(108 downto 101);--<=i_irq_src_act(7 downto 0);--//Status IRQx
----i_dbgcs_int0_view(20 downto 13)<=i_host_tst_out(116 downto 109);--<=i_irq_src_set(7 downto 0);--//Set    IRQx
----i_dbgcs_int0_view(21)          <=i_host_tst_out(117)           ;--<=i_dmatotal_mwr_done and i_dma_mwr_done_del;
----i_dbgcs_int0_view(22)          <=i_host_tst_out(118)           ;--<=i_dmatotal_mrd_done and i_dma_mrd_done_del;
----
----i_dbgcs_int0_view(23)         <=i_host_tst2_out(0);--p_out_tst(0)<=cfg_interrupt_n;
----i_dbgcs_int0_view(24)         <=i_host_tst2_out(1);--p_out_tst(1)<=cfg_interrupt_rdy_n;
----i_dbgcs_int0_view(25)         <=i_host_tst2_out(2);--p_out_tst(2)<=cfg_interrupt_assert_n;
----i_dbgcs_int0_view(26)         <=i_host_tst2_out(3);--p_out_tst(3)<=cfg_interrupt_msienable;
----
----i_dbgcs_int0_view(27)         <=i_host_tst2_out(21);--p_out_tst(21)<=trn_rcpl_streaming_n;
----i_dbgcs_int0_view(28)         <=i_host_tst2_out(22);--p_out_tst(22)<=trn_rnp_ok_n;
----
----i_dbgcs_int0_view(29)          <=i_host_tst_out(119);--p_out_usr_tst(119)<=v_reg_pciexp_ctrl(C_HREG_PCIE_MSI_EN_BIT);
----i_dbgcs_int0_view(30)          <=i_host_tst_out(120);--p_out_usr_tst(120)<=p_in_cfg_msi_enable;
----i_dbgcs_int0_view(31)          <=i_host_tst2_out(16);--p_out_tst(16)<=cfg_command(2);--//cfg_bus_mstr_enable
------i_dbgcs_int0_view(31 downto 29)<=(others=>'0');
----
----
----m_dbgcs_int1: dbgcs_cfg
----port map(
----CONTROL => i_dbgcs_int1,
----CLK     => g_host_clk,
----DATA    => i_dbgcs_int1_view(31 downto 0),--(122 downto 0),
----TRIG0   => i_dbgcs_int1_trg(15 downto 0)
----);
----
------//-------- TRIG: ------------------
----i_dbgcs_int1_trg(0)         <=i_host_tst_out(96)            ;--<=i_irq_src_clr;--//Clr IRQ
----i_dbgcs_int1_trg(1)         <=i_host_tst_out(117)           ;--<=i_dmatotal_mwr_done and i_dma_mwr_done_del;
----i_dbgcs_int1_trg(2)         <=i_host_tst_out(118)           ;--<=i_dmatotal_mrd_done and i_dma_mrd_done_del;
----i_dbgcs_int1_trg(3)         <=i_host_tst_out(118) or i_host_tst_out(117);--<=i_dmatotal_mrd_done and i_dma_mrd_done_del;
----i_dbgcs_int1_trg(4)         <=i_host_tst2_out(0);--p_out_tst(0)<=cfg_interrupt_n;
----i_dbgcs_int1_trg(5)         <=i_host_tst2_out(1);--p_out_tst(1)<=cfg_interrupt_rdy_n;
----i_dbgcs_int1_trg(6)         <=i_host_tst2_out(2);--p_out_tst(2)<=cfg_interrupt_assert_n;
----i_dbgcs_int1_trg(7)         <=i_host_tst2_out(3);--p_out_tst(3)<=cfg_command(10);--0/1 -INTx enable/disable
----i_dbgcs_int1_trg(8)         <=i_host_mem_ce;
----i_dbgcs_int1_trg(9)         <=tst_mem_trained;
----i_dbgcs_int1_trg(10)         <='0';
----i_dbgcs_int1_trg(11)          <=i_host_tst2_out(16);--p_out_tst(16)<=cfg_command(2);--//cfg_bus_mstr_enable
----i_dbgcs_int1_trg(15 downto 12)<=(others=>'0');
----
----
------//-------- VIEW: ------------------
----i_dbgcs_int1_view(22 downto 0) <=i_tmr_dly(22 downto 0);
----
----i_dbgcs_int1_view(23)         <=i_host_tst2_out(0);--p_out_tst(0)<=cfg_interrupt_n;
----i_dbgcs_int1_view(24)         <=i_host_tst2_out(1);--p_out_tst(1)<=cfg_interrupt_rdy_n;
----i_dbgcs_int1_view(25)         <=i_host_tst2_out(2);--p_out_tst(2)<=cfg_interrupt_assert_n;
----i_dbgcs_int1_view(26)         <=i_host_tst2_out(3);--p_out_tst(3)<=cfg_command(10);--0/1 -INTx enable/disable
----
----i_dbgcs_int1_view(27)         <=i_host_tst2_out(16);--p_out_tst(16)<=cfg_command(2);--//cfg_bus_mstr_enable
----i_dbgcs_int1_view(28)         <=tst_mem_trained;
----
----i_dbgcs_int1_view(31 downto 29) <=i_irq_rdy(2 downto 0);
------i_dbgcs_int1_view(31 downto 29)<=(others=>'0');
----
----
----i_tmr_dly_clr<=i_host_mem_ce or i_host_rst_all;
----process(i_tmr_dly_clr, g_pciexp_gt_refclkout)
----begin
----  if i_tmr_dly_clr='1' then
----    i_tmr_dly<=(others=>'0');
----  elsif g_pciexp_gt_refclkout'event and g_pciexp_gt_refclkout='1' then
----    sr_irq_assert_n<=i_host_tst2_out(2);--p_out_tst(2)<=cfg_interrupt_assert_n;
----
----    if sr_irq_assert_n='0' then
----      if i_tmr_dly/=(i_tmr_dly'range =>'1') then
----        i_tmr_dly<=i_tmr_dly + 1;
----      end if;
----    end if;
----
----  end if;
----end process;
----
----process(i_tmr_dly_clr, g_host_clk)
----begin
----  if i_tmr_dly_clr='1' then
----    i_irq_rdy<=(others=>'0');
----    tst_mem_trained<='0';
----  elsif g_host_clk'event and g_host_clk='1' then
----
----    tst_mem_trained<=i_memctrl_trained(0);
----
----    if i_host_tst2_out(1)='0' then
----        i_irq_rdy<=i_irq_rdy + 1;
----    end if;
----
----  end if;
----end process;







end architecture;
