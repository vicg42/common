-------------------------------------------------------------------------
-- Company     : Linkos
-- Engineer    : Golovachenko Victor
--
-- Create Date : 23.11.2011 18:05:23
-- Module Name : hdd_vm_main
--
-- Назначение/Описание :
-- Проект изделия Вереск-М(Р)
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

library work;
use work.vicg_common_pkg.all;
use work.prj_cfg.all;
use work.prj_def.all;
use work.veresk_pkg.all;
use work.cfgdev_pkg.all;
use work.mem_ctrl_pkg.all;
use work.mem_wr_pkg.all;
use work.eth_phypin_pkg.all;
use work.eth_pkg.all;
use work.dsn_eth_pkg.all;
use work.dsn_video_ctrl_pkg.all;
use work.pcie_pkg.all;
use work.clocks_pkg.all;

use work.sata_testgen_pkg.all;
use work.sata_glob_pkg.all;
use work.dsn_hdd_pkg.all;

entity hdd_vm_main is
generic(
G_SIM_HOST : string:="OFF";
G_SIM_PCIE : std_logic:='0';
G_DBG_PCIE : string:="OFF";
G_SIM      : string:="OFF"
);
port(
--------------------------------------------------
--SATA
--------------------------------------------------
pin_out_sata_txn    : out   std_logic_vector((C_SH_GTCH_COUNT_MAX*C_SH_COUNT_MAX(C_PCFG_HDD_COUNT-1))-1 downto 0);
pin_out_sata_txp    : out   std_logic_vector((C_SH_GTCH_COUNT_MAX*C_SH_COUNT_MAX(C_PCFG_HDD_COUNT-1))-1 downto 0);
pin_in_sata_rxn     : in    std_logic_vector((C_SH_GTCH_COUNT_MAX*C_SH_COUNT_MAX(C_PCFG_HDD_COUNT-1))-1 downto 0);
pin_in_sata_rxp     : in    std_logic_vector((C_SH_GTCH_COUNT_MAX*C_SH_COUNT_MAX(C_PCFG_HDD_COUNT-1))-1 downto 0);
pin_in_sata_clk_n   : in    std_logic_vector(C_SH_COUNT_MAX(C_PCFG_HDD_COUNT-1)-1 downto 0);
pin_in_sata_clk_p   : in    std_logic_vector(C_SH_COUNT_MAX(C_PCFG_HDD_COUNT-1)-1 downto 0);

--------------------------------------------------
--Технологический порт
--------------------------------------------------
pin_out_led         : out   std_logic_vector(7 downto 0);
pin_out_TP          : out   std_logic_vector(7 downto 5);

--------------------------------------------------
--Memory banks
--------------------------------------------------
pin_out_phymem      : out   TMEMCTRL_phy_outs;
pin_inout_phymem    : inout TMEMCTRL_phy_inouts;

--------------------------------------------------
--Ethernet
--------------------------------------------------
pin_out_sfp_tx_dis  : out   std_logic;--SFP - TX DISABLE
pin_in_sfp_sd       : in    std_logic;--SFP - SD signal detect

pin_out_ethphy      : out   TEthPhyPinOUT;
pin_in_ethphy       : in    TEthPhyPinIN;

--------------------------------------------------
--PCI-EXPRESS
--------------------------------------------------
pin_out_pciexp_txp  : out   std_logic_vector(C_PCGF_PCIE_LINK_WIDTH-1 downto 0);
pin_out_pciexp_txn  : out   std_logic_vector(C_PCGF_PCIE_LINK_WIDTH-1 downto 0);
pin_in_pciexp_rxp   : in    std_logic_vector(C_PCGF_PCIE_LINK_WIDTH-1 downto 0);
pin_in_pciexp_rxn   : in    std_logic_vector(C_PCGF_PCIE_LINK_WIDTH-1 downto 0);
pin_in_pciexp_clk_p : in    std_logic;
pin_in_pciexp_clk_n : in    std_logic;
pin_in_pciexp_rstn  : in    std_logic;

--------------------------------------------------
--Reference clock
--------------------------------------------------
pin_in_refclk       : in    TRefClkPinIN
);
end entity;

architecture struct of hdd_vm_main is

component dsn_hdd_rambuf
generic(
G_MEMOPT      : string:="OFF";
G_MODULE_USE  : string:="ON";
G_RAMBUF_SIZE : integer:=23;
G_DBGCS       : string:="OFF";
G_SIM         : string:="OFF";
G_USE_2CH     : string:="OFF";
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

----------------------------
--Связь с буфером видеоданных
----------------------------
p_in_bufi_dout        : in    std_logic_vector(G_MEM_DWIDTH-1 downto 0);
p_out_bufi_rd         : out   std_logic;
p_in_bufi_empty       : in    std_logic;
p_in_bufi_full        : in    std_logic;
p_in_bufi_pfull       : in    std_logic;
p_in_bufi_wrcnt       : in    std_logic_vector(3 downto 0);

p_out_bufo_din        : out   std_logic_vector(G_MEM_DWIDTH-1 downto 0);
p_out_bufo_wr         : out   std_logic;
p_in_bufo_full        : in    std_logic;
p_in_bufo_empty       : in    std_logic;

----------------------------
--Связь с модулем HDD
----------------------------
p_out_hdd_txd         : out   std_logic_vector(G_MEM_DWIDTH-1 downto 0);
p_out_hdd_txd_wr      : out   std_logic;
p_in_hdd_txbuf_pfull  : in    std_logic;
p_in_hdd_txbuf_full   : in    std_logic;
p_in_hdd_txbuf_empty  : in    std_logic;

p_in_hdd_rxd          : in    std_logic_vector(G_MEM_DWIDTH-1 downto 0);
p_out_hdd_rxd_rd      : out   std_logic;
p_in_hdd_rxbuf_empty  : in    std_logic;
p_in_hdd_rxbuf_pempty : in    std_logic;

---------------------------------
-- Связь с mem_ctrl.vhd
---------------------------------
p_out_memch0           : out   TMemIN;
p_in_memch0            : in    TMemOUT;

p_out_memch1           : out   TMemIN;
p_in_memch1            : in    TMemOUT;

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

component clocks
port(
p_out_rst  : out   std_logic;
p_out_gclk : out   std_logic_vector(7 downto 0);

p_in_clkopt: in    std_logic_vector(3 downto 0);
p_in_clk   : in    TRefClkPinIN
);
end component;

component gt_clkbuf is
port(
p_in_clkp  : in    std_logic;
p_in_clkn  : in    std_logic;
p_out_clk  : out   std_logic;
p_in_opt   : in    std_logic_vector(3 downto 0);
p_out_opt  : out   std_logic_vector(3 downto 0)
);
end component;

component eth_gt_clkbuf is
port(
p_in_ethphy : in    TEthPhyPinIN;
p_out_clk   : out   std_logic_vector(1 downto 0)
);
end component;

signal i_pll_rst_out                    : std_logic;
signal g_pll_clkin                      : std_logic;
signal g_pll_mem_clk                    : std_logic;
signal g_pll_tmr_clk                    : std_logic;
signal i_usrclk_rst                     : std_logic;
signal g_usrclk                         : std_logic_vector(7 downto 0);
signal g_usr_highclk                    : std_logic;
signal g_refclkopt                      : std_logic_vector(3 downto 0);
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
signal i_eth_gt_refclk125               : std_logic_vector(1 downto 0);
signal i_eth_rst                        : std_logic;
signal i_eth_out                        : TEthOUTs;
signal i_eth_in                         : TEthINs;
signal i_ethphy_out                     : TEthPhyOUT;
signal i_ethphy_in                      : TEthPhyIN;
--signal i_eth_tst_out                    : std_logic_vector(31 downto 0);
signal dbg_eth_out                      : TEthDBG;

signal i_tmr_rst                        : std_logic;
signal i_tmr_clk                        : std_logic;
signal i_tmr_hirq                       : std_logic_vector(C_TMR_COUNT-1 downto 0);

signal i_vctrl_rst                      : std_logic;
signal hclk_hrddone_vctrl_cnt           : std_logic_vector(2 downto 0);
signal hclk_hrddone_vctrl               : std_logic;
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
signal sr_vctrl_hrd_done                : std_logic_vector(1 downto 0);
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

signal i_trc_busy                       : std_logic_vector(C_VCTRL_VCH_COUNT-1 downto 0):=(others=>'0');
signal i_trc_vbufs                      : TVfrBufs;

signal i_host_mem_rst                   : std_logic;
signal i_host_mem_ctrl                  : TPce2Mem_Ctrl;
signal i_host_mem_status                : TPce2Mem_Status;
signal i_host_memin                     : TMemIN;
signal i_host_memout                    : TMemOUT;
signal i_host_mem_tst_out               : std_logic_vector(31 downto 0);

signal i_memctrl_rst                    : std_logic;
signal i_memctrl_locked                 : std_logic_vector(7 downto 0);
signal i_memctrl_ready                  : std_logic;

signal i_memin_ch                       : TMemINCh;
signal i_memout_ch                      : TMemOUTCh;
signal i_memin_bank                     : TMemINBank;
signal i_memout_bank                    : TMemOUTBank;

signal i_arb_mem_rst                    : std_logic;
signal i_arb_memin                      : TMemIN;
signal i_arb_memout                     : TMemOUT;
signal i_arb_mem_tst_out                : std_logic_vector(31 downto 0);

signal i_mem_ctrl_status                : TMEMCTRL_status;
signal i_mem_ctrl_sysin                 : TMEMCTRL_sysin;
signal i_mem_ctrl_sysout                : TMEMCTRL_sysout;

signal i_cfghdd_dadr                    : std_logic_vector(C_CFGPKT_DADR_M_BIT-C_CFGPKT_DADR_L_BIT downto 0);
signal i_cfghdd_radr                    : std_logic_vector(C_CFGPKT_RADR_M_BIT-C_CFGPKT_RADR_L_BIT downto 0);
signal i_cfghdd_radr_ld                 : std_logic;
signal i_cfghdd_radr_fifo               : std_logic;
signal i_cfghdd_wr                      : std_logic;
signal i_cfghdd_rd                      : std_logic;
signal i_cfghdd_txdata                  : std_logic_vector(15 downto 0);
signal i_cfghdd_done                    : std_logic;
signal i_cfghdd_rxdata                  : std_logic_vector(15 downto 0);

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
signal i_hdd_bufi_dout                  : std_logic_vector(31 downto 0);
signal i_hdd_bufi_rd                    : std_logic;
signal i_hdd_bufi_empty                 : std_logic;
signal i_hdd_bufi_full                  : std_logic;
signal i_hdd_bufi_pfull                 : std_logic;
signal i_hdd_bufi_wrcnt                 : std_logic_vector(3 downto 0);
signal i_hdd_rbuf_cfg                   : THDDRBufCfg;
signal i_hdd_rbuf_status                : THDDRBufStatus;
signal tst_hdd_rambuf_out               : std_logic_vector(31 downto 0);
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

attribute keep : string;
attribute keep of g_host_clk : signal is "true";
attribute keep of g_usr_highclk : signal is "true";
attribute keep of g_usrclk : signal is "true";
attribute keep of i_ethphy_out : signal is "true";

signal i_test01_led     : std_logic;
signal tst_clr          : std_logic;

component dbgcs_iconx1
  PORT (
    CONTROL0 : INOUT STD_LOGIC_VECTOR(35 DOWNTO 0));

end component;

component dbgcs_iconx2
  PORT (
    CONTROL0 : INOUT STD_LOGIC_VECTOR(35 DOWNTO 0);
    CONTROL1 : INOUT STD_LOGIC_VECTOR(35 DOWNTO 0));

end component;

component dbgcs_iconx3
  PORT (
    CONTROL0 : INOUT STD_LOGIC_VECTOR(35 DOWNTO 0);
    CONTROL1 : INOUT STD_LOGIC_VECTOR(35 DOWNTO 0);
    CONTROL2 : INOUT STD_LOGIC_VECTOR(35 DOWNTO 0));

end component;

component dbgcs_sata_layer
  PORT (
    CONTROL : INOUT STD_LOGIC_VECTOR(35 DOWNTO 0);
    CLK : IN STD_LOGIC;
    DATA : IN STD_LOGIC_VECTOR(122 DOWNTO 0);
    TRIG0 : IN STD_LOGIC_VECTOR(41 DOWNTO 0)
    );
end component;

component dbgcs_sata_raid_b
  PORT (
    CONTROL : INOUT STD_LOGIC_VECTOR(35 DOWNTO 0);
    CLK : IN STD_LOGIC;
    DATA : IN STD_LOGIC_VECTOR(255 downto 0); --(122 DOWNTO 0);
    TRIG0 : IN STD_LOGIC_VECTOR(49 DOWNTO 0)
    );
end component;

signal i_dbgcs_hwcfg                    : std_logic_vector(35 downto 0);
signal i_dbgcs_cfg,i_dbgcs_cfg1         : std_logic_vector(35 downto 0);
signal i_dbgcs_sh0_spd                  : std_logic_vector(35 downto 0);
signal i_dbgcs_hdd0_layer               : std_logic_vector(35 downto 0);
signal i_dbgcs_hdd1_layer               : std_logic_vector(35 downto 0);
signal i_dbgcs_hdd_raid                 : std_logic_vector(35 downto 0);
signal i_dbgcs_vctrl                    : std_logic_vector(35 downto 0);
signal i_dbgcs_vin                      : std_logic_vector(35 downto 0);
signal i_dbgcs_vout                     : std_logic_vector(35 downto 0);
signal i_vout_dbgcs                     : TSH_ila;
signal i_vin_dbgcs                      : TSH_ila;
signal i_cfg_dbgcs,i_cfg1_dbgcs         : TSH_ila;
signal i_hdd0layer_dbgcs                : TSH_ila;
signal i_hdd1layer_dbgcs                : TSH_ila;
signal i_hddraid_dbgcs                  : TSH_ila;
signal i_vctrl_dbgcs                    : TSH_ila;

signal sr_hddbufi_rst                   : std_logic_vector(0 to 1):=(others=>'0');
signal tst_hddbufi_rst_fedge            : std_logic:='0';
signal tst_hddbufi_rst_redge            : std_logic:='0';
signal tst_start_wr                     : std_logic;
signal tst_fsm_hddctrl                  : std_logic_vector(2 downto 0);
signal tst_sh_err                       : std_logic_vector(3 downto 0);
signal tst_llayer_send_data             : std_logic_vector(3 downto 0);


--//MAIN
begin


--***********************************************************
--//RESET модулей
--***********************************************************
i_host_rst_n <=pin_in_pciexp_rstn;

i_tmr_rst    <=not i_host_rst_n or i_host_rst_all;
i_cfg_rst    <=not i_host_rst_n or i_host_rst_all;
i_eth_rst    <=not i_host_rst_n or i_host_rst_all or i_host_rst_eth;
i_vctrl_rst  <=not OR_reduce(i_mem_ctrl_status.rdy);
i_swt_rst    <=not i_host_rst_n or i_host_rst_all;
i_host_mem_rst<=not OR_reduce(i_mem_ctrl_status.rdy);
i_mem_ctrl_sysin.rst<=not i_host_rst_n or i_host_rst_all or i_pll_rst_out;
i_arb_mem_rst<=not OR_reduce(i_mem_ctrl_status.rdy);
i_hdd_rst    <=not i_host_rst_n or i_host_rst_all;


--***********************************************************
--Установка частот проекта:
--***********************************************************
ibuf_pciexp_gt_refclk : gt_clkbuf
port map(
p_in_clkp  => pin_in_pciexp_clk_p,
p_in_clkn  => pin_in_pciexp_clk_n,
p_out_clk  => i_pciexp_gt_refclk,
p_in_opt   => (others=>'0'),
p_out_opt  => open
);

ibuf_eth_gt_refclk : eth_gt_clkbuf
port map(
p_in_ethphy => pin_in_ethphy,
p_out_clk   => i_eth_gt_refclk125
);

m_clocks : clocks
port map(
p_out_rst  => i_usrclk_rst,
p_out_gclk => g_usrclk,

p_in_clkopt=> g_refclkopt,
p_in_clk   => pin_in_refclk
);

g_refclkopt(0)<=g_host_clk;
g_refclkopt(1)<=i_ethphy_out.clk;

g_usr_highclk<=i_mem_ctrl_sysout.clk;
i_tmr_clk<=g_usrclk(2);
i_mem_ctrl_sysin.ref_clk<=g_usrclk(0);
i_mem_ctrl_sysin.clk<=g_usrclk(1);


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

p_out_hdd_vbuf_dout       => i_hdd_bufi_dout,
p_in_hdd_vbuf_rd          => i_hdd_bufi_rd,
p_out_hdd_vbuf_empty      => i_hdd_bufi_empty,
p_out_hdd_vbuf_full       => i_hdd_bufi_full,
p_out_hdd_vbuf_pfull      => i_hdd_bufi_pfull,
p_out_hdd_vbuf_wrcnt      => i_hdd_bufi_wrcnt,

-------------------------------
-- Связь с Eth(dsn_eth.vhd) (ethg_clk domain)
-------------------------------
p_in_eth_clk              => i_ethphy_out.clk,       --g_eth_gt_refclkout,

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
pin_out_ethphy<=i_ethphy_out.pin;
i_ethphy_in.pin<=pin_in_ethphy;

i_ethphy_in.clk<=i_eth_gt_refclk125(0);

pin_out_sfp_tx_dis<=i_ethphy_out.opt(C_ETHPHY_OPTOUT_SFP_TXDIS_BIT);

i_ethphy_in.opt(C_ETHPHY_OPTIN_REFCLK_IODELAY_BIT)<=g_usrclk(0);
i_ethphy_in.opt(C_ETHPHY_OPTIN_SFP_SD_BIT)<=pin_in_sfp_sd;
i_ethphy_in.opt(32)<=i_eth_gt_refclk125(1);
i_ethphy_in.opt(33)<=i_usrclk_rst;--rst
i_ethphy_in.opt(34)<=g_usrclk(2);--clkdrp

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
p_out_dbg             => dbg_eth_out,
p_in_tst              => (others=>'0'),
p_out_tst             => open,--i_eth_tst_out,

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
G_ROTATE => "OFF",
G_ROTATE_BUF_COUNT => 16,
G_SIMPLE => "ON",
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
p_out_vctrl_modrdy   => open,
p_out_vctrl_moderr   => open,
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
-------------------------------
--PCI-Express
-------------------------------
p_out_pciexp_txp   => pin_out_pciexp_txp,
p_out_pciexp_txn   => pin_out_pciexp_txn,
p_in_pciexp_rxp    => pin_in_pciexp_rxp,
p_in_pciexp_rxn    => pin_in_pciexp_rxn,

p_in_pciexp_gt_clkin   => i_pciexp_gt_refclk,
p_out_pciexp_gt_clkout => g_pciexp_gt_refclkout,

-------------------------------
--Пользовательский порт
-------------------------------
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

-------------------------------
--Технологический
-------------------------------
p_in_usr_tst       => i_host_tst_in,
p_out_usr_tst      => i_host_tst_out,
p_in_tst           => (others=>'0'),
p_out_tst          => i_host_tst2_out,

-------------------------------
--System
-------------------------------
p_out_module_rdy   => i_host_rdy,
p_in_rst_n         => i_host_rst_n
);

i_host_tst_in(63 downto 0)<=(others=>'0');
i_host_tst_in(71 downto 64)<=(others=>'0');
i_host_tst_in(72)<='0';
i_host_tst_in(73)<='0';
i_host_tst_in(74)<='0';
i_host_tst_in(75)<='0';
i_host_tst_in(76)<='0';
i_host_tst_in(126 downto 77)<=(others=>'0');
i_host_tst_in(127)<=i_vctrl_tst_out(0) or
                    OR_reduce(dbg_eth_out.app(0).mac_rx) or OR_reduce(dbg_eth_out.app(0).mac_tx);-- or
                    --i_arb_mem_tst_out(0) or i_swt_tst_out(0);


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

i_host_dev_status(C_HREG_DEV_STATUS_MEMCTRL_RDY_BIT)<=OR_reduce(i_mem_ctrl_status.rdy);


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


--//Прерывания
i_host_dev_irq(C_HIRQ_TMR0)  <=i_tmr_hirq(0);
i_host_dev_irq(C_HIRQ_CFG_RX)<=i_host_irq(C_HIRQ_CFG_RX);
i_host_dev_irq(C_HIRQ_ETH_RX)<=i_host_irq(C_HIRQ_ETH_RX);
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
  end if;
end process;

--//Пересинхронизация управляющих сигналов Хоста
process(i_host_rst_n, g_usr_highclk)
begin
  if i_host_rst_n='0' then
    i_vctrl_hrd_start<='0';

    i_vctrl_hrd_done<='0';
    sr_vctrl_hrd_done<=(others=>'0');

  elsif g_usr_highclk'event and g_usr_highclk='1' then
    i_vctrl_hrd_start<=hclk_hdev_dma_start(C_HDEV_VCH_DBUF);

    sr_vctrl_hrd_done(0)<=hclk_hrddone_vctrl;
    sr_vctrl_hrd_done(1)<=sr_vctrl_hrd_done(0);
    i_vctrl_hrd_done<=sr_vctrl_hrd_done(0) and not sr_vctrl_hrd_done(1);

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
p_in_rst         => i_host_mem_rst
);

--//Подключаем устройства к арбитру ОЗУ
i_memin_ch(0) <= i_host_memin;
i_host_memout <= i_memout_ch(0);

i_memin_ch(1)    <= i_vctrlwr_memin;
i_vctrlwr_memout <= i_memout_ch(1);

i_memin_ch(2)    <= i_vctrlrd_memin;
i_vctrlrd_memout <= i_memout_ch(2);

gen_memch4_on : if strcmp(C_PCFG_HDD_USE,"ON") generate

i_memin_ch(3)<= i_hdd_memin;
i_hdd_memout <= i_memout_ch(3);

end generate gen_memch4_on;

--//Арбитр контроллера памяти
m_mem_arb : mem_arb
generic map(
G_CH_COUNT   => selval(10#04#,10#03#, strcmp(C_PCFG_HDD_USE,"ON")),
G_MEM_AWIDTH => C_AXI_AWIDTH, --C_HREG_MEM_ADR_LAST_BIT,
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

--//Подключаем арбитра ОЗУ к соотв банку
i_memin_bank(0)<=i_arb_memin;
i_arb_memout   <=i_memout_bank(0);

--//Core Memory controller
m_mem_ctrl : mem_ctrl
generic map(
G_SIM => G_SIM
)
port map(
------------------------------------
--User Post
------------------------------------
p_in_mem   => i_memin_bank,
p_out_mem  => i_memout_bank,

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


--***********************************************************
--Проект Накопителя - dsn_hdd.vhd
--***********************************************************
--//Input 150MHz reference clock for SATA
gen_sata_gt : for i in 0 to C_SH_COUNT_MAX(C_PCFG_HDD_COUNT-1)-1 generate
  ibufds_hdd_gt_refclk : gt_clkbuf
  port map(
  p_in_clkp  => pin_in_sata_clk_p(i),
  p_in_clkn  => pin_in_sata_clk_n(i),
  p_out_clk  => i_hdd_gt_refclk150(i),
  p_in_opt   => (others=>'0'),
  p_out_opt  => open
  );
end generate gen_sata_gt;

--i_cfghdd_selif<=i_hdd_rbuf_cfg.usrif;

i_cfghdd_radr(7 downto 0)<=i_cfg_radr(7 downto 0)      ;-- when i_cfghdd_selif=C_HDD_CFGIF_PCIEXP else i_cfgu_radr(7 downto 0);
i_cfghdd_radr_ld         <=i_cfg_radr_ld               ;-- when i_cfghdd_selif=C_HDD_CFGIF_PCIEXP else i_cfgu_radr_ld         ;
i_cfghdd_radr_fifo       <=i_cfg_radr_fifo             ;-- when i_cfghdd_selif=C_HDD_CFGIF_PCIEXP else i_cfgu_radr_fifo       ;
i_cfghdd_txdata          <=i_cfg_txd                   ;-- when i_cfghdd_selif=C_HDD_CFGIF_PCIEXP else i_cfgu_txdata          ;
i_cfghdd_wr              <=i_cfg_wr_dev(C_CFGDEV_HDD)  ;-- when i_cfghdd_selif=C_HDD_CFGIF_PCIEXP else i_cfgu_wr              ;
i_cfghdd_rd              <=i_cfg_rd_dev(C_CFGDEV_HDD)  ;-- when i_cfghdd_selif=C_HDD_CFGIF_PCIEXP else i_cfgu_rd              ;
i_cfghdd_done            <=i_cfg_done_dev(C_CFGDEV_HDD);-- when i_cfghdd_selif=C_HDD_CFGIF_PCIEXP else i_cfgu_done            ;

i_cfg_rxd_dev(C_CFGDEV_HDD) <=i_cfghdd_rxdata;

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
p_out_hdd_rdy         => open,--i_hdd_module_rdy,
p_out_hdd_error       => open,--i_hdd_module_error,
p_out_hdd_busy        => open,--i_hdd_busy,
p_out_hdd_irq         => open,--i_hdd_hirq,
p_out_hdd_done        => open,--i_hdd_done,
p_out_hdd_lba_bp      => open,
p_in_hdd_test         => '0',
p_in_hdd_clr_err      => '0',

-------------------------------
-- Связь с Источниками/Приемниками данных накопителя
-------------------------------
p_out_rbuf_cfg        => i_hdd_rbuf_cfg,
p_in_rbuf_status      => i_hdd_rbuf_status,

p_in_sh_cxd           => (others=>'0'),
p_in_sh_cxd_wr        => '0',

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
p_out_sata_refclkout  => open,--g_hdd_gt_refclkout,
p_out_sata_gt_plldet  => open,--i_hdd_gt_plldet,
p_out_sata_dcm_lock   => open,--i_hdd_dcm_lock,
p_out_sata_dcm_gclk2div => open,
p_out_sata_dcm_gclk2x   => open,
p_out_sata_dcm_gclk0    => open,

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
G_MEMOPT     => "OFF",
G_MODULE_USE => C_PCFG_HDD_USE,
G_RAMBUF_SIZE=> C_PCFG_HDD_RAMBUF_SIZE,
G_DBGCS      => C_PCFG_HDD_DBGCS,
G_SIM        => G_SIM,
G_USE_2CH    => "OFF",
G_MEM_BANK_M_BIT => C_HREG_MEM_ADR_BANK_M_BIT,
G_MEM_BANK_L_BIT => C_HREG_MEM_ADR_BANK_L_BIT,
G_MEM_AWIDTH  => C_HREG_MEM_ADR_LAST_BIT,
G_MEM_DWIDTH  => C_HDEV_DWIDTH
)
port map(
-------------------------------
-- Конфигурирование
-------------------------------
p_in_rbuf_cfg       => i_hdd_rbuf_cfg,
p_out_rbuf_status   => i_hdd_rbuf_status,
p_in_lentrn_exp     => '0',

--//--------------------------
--//Upstream Port(Связь с буфером источника данных)
--//--------------------------
p_in_bufi_dout      => i_hdd_bufi_dout,
p_out_bufi_rd       => i_hdd_bufi_rd,
p_in_bufi_empty     => i_hdd_bufi_empty,
p_in_bufi_full      => i_hdd_bufi_full,
p_in_bufi_pfull     => i_hdd_bufi_pfull,
p_in_bufi_wrcnt     => i_hdd_bufi_wrcnt,

p_out_bufo_din      => open,--i_hdd_bufo_din,
p_out_bufo_wr       => open,--i_hdd_bufo_wr,
p_in_bufo_full      => '0',--i_vbufo_full,
p_in_bufo_empty     => '1',--i_vbufo_empty,

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
p_out_memch0          => i_hdd_memin,--TMemIN ;
p_in_memch0           => i_hdd_memout,--TMemOUT;

p_out_memch1          => open,--TMemIN ;
p_in_memch1           => i_hdd_memout,--TMemOUT;

-------------------------------
--Технологический
-------------------------------
p_in_tst            => (others=>'0'),
p_out_tst           => tst_hdd_rambuf_out,
p_out_dbgcs         => i_hdd_rambuf_dbgcs,

-------------------------------
--System
-------------------------------
p_in_clk => g_usr_highclk,
p_in_rst => i_hdd_rst
);

--//#########################################
--//DBG
--//#########################################
pin_out_led(0)<=i_test01_led;
pin_out_led(1)<='0';

--SATA0
pin_out_led(2)<=((i_hdd_dbgled(0).rdy and not i_hdd_dbgled(0).err) or (i_test01_led         and i_hdd_dbgled(0).err));
pin_out_led(3)<=  i_hdd_dbgled(0).busy;
pin_out_led(4)<=((i_hdd_dbgled(0).wr  and not i_hdd_dbgled(0).err) or (i_hdd_dbgled(0).link and i_hdd_dbgled(0).err));
--SATA1
pin_out_led(5)<=((i_hdd_dbgled(1).rdy and not i_hdd_dbgled(1).err) or (i_test01_led         and i_hdd_dbgled(1).err));
pin_out_led(6)<=  i_hdd_dbgled(1).busy;
pin_out_led(7)<=((i_hdd_dbgled(1).wr  and not i_hdd_dbgled(1).err) or (i_hdd_dbgled(1).link and i_hdd_dbgled(1).err));

pin_out_TP<=(others=>'0');

m_gt_03_test: fpga_test_01
generic map(
G_BLINK_T05   =>10#250#,
G_CLK_T05us   =>10#75#
)
port map(
p_out_test_led => i_test01_led,
p_out_test_done=> open,

p_out_1us      => open,
p_out_1ms      => open,
-------------------------------
--System
-------------------------------
p_in_clk       => g_host_clk,
p_in_rst       => i_cfg_rst
);


--################################################
--ChipScope DBG:
--################################################
gen_hdd_dbgcs : if strcmp(C_PCFG_HDD_DBGCS,"ON") generate

gen_sh_dbgcs : if strcmp(C_PCFG_HDD_SH_DBGCS,"ON") generate
m_dbgcs_icon : dbgcs_iconx3
port map(
CONTROL0 => i_dbgcs_sh0_spd,
CONTROL1 => i_dbgcs_hdd0_layer,
CONTROL2 => i_dbgcs_hdd1_layer
);

--//### DBG HDD0_SPD: ########
m_dbgcs_sh0_spd : dbgcs_sata_layer
port map
(
CONTROL => i_dbgcs_sh0_spd,
CLK     => i_hdd_dbgcs.sh(0).spd.clk,
DATA    => i_hdd_dbgcs.sh(0).spd.data(122 downto 0),
TRIG0   => i_hdd_dbgcs.sh(0).spd.trig0(41 downto 0)
);

--//### DBG HDD0: ########
m_dbgcs_hdd0_layer : dbgcs_sata_raid_b --dbgcs_sata_layer
port map
(
CONTROL => i_dbgcs_hdd0_layer,
CLK     => i_hdd_dbgcs.sh(0).layer.clk,
DATA    => i_hdd_dbgcs.sh(0).layer.data(255 downto 0),--(122 downto 0),
TRIG0   => i_hdd0layer_dbgcs.trig0(49 downto 0)
);

i_hdd0layer_dbgcs.trig0(19 downto 0)<=i_hdd_dbgcs.sh(0).layer.trig0(19 downto 0);--llayer
i_hdd0layer_dbgcs.trig0(20)<=i_hdd_dbgcs.sh(0).layer.data(160);--<=p_in_alstatus.sstatus(C_ASSTAT_DET_BIT_L+1);--//C_PSTAT_DET_ESTABLISH_ON_BIT
i_hdd0layer_dbgcs.trig0(21)<=i_hdd_dbgcs.sh(0).layer.data(161);--<=p_in_alstatus.sstatus(C_ASSTAT_DET_BIT_L+0);--//C_PSTAT_DET_DEV_ON_BIT
i_hdd0layer_dbgcs.trig0(22)<=i_hdd_dbgcs.sh(0).layer.data(162);--<=p_in_txelecidle;
i_hdd0layer_dbgcs.trig0(23)<=i_hdd_dbgcs.sh(0).layer.data(163);--<=p_in_rxelecidle;
i_hdd0layer_dbgcs.trig0(24)<=i_hdd_dbgcs.sh(0).layer.data(164);--<=p_in_txcomstart;
i_hdd0layer_dbgcs.trig0(25)<=i_hdd_dbgcs.sh(0).layer.data(167);--<=p_in_rxcdrreset;
i_hdd0layer_dbgcs.trig0(41 downto 26)<=i_hdd_dbgcs.sh(0).layer.trig0(41 downto 26);--llayer

--//### DBG HDD1: ########
gen_hdd1 : if C_PCFG_HDD_COUNT=1 generate
m_dbgcs_hdd1_layer : dbgcs_sata_raid_b --dbgcs_sata_layer
port map
(
CONTROL => i_dbgcs_hdd1_layer,
CLK     => i_hdd_dbgcs.sh(0).layer.clk,
DATA    => i_hdd_dbgcs.sh(0).layer.data(255 downto 0),--(122 downto 0),
TRIG0   => i_hdd1layer_dbgcs.trig0(49 downto 0)
);

i_hdd1layer_dbgcs.trig0(19 downto 0)<=i_hdd_dbgcs.sh(0).layer.trig0(19 downto 0);--llayer
i_hdd1layer_dbgcs.trig0(20)<=i_hdd_dbgcs.sh(0).layer.data(160);--<=p_in_alstatus.sstatus(C_ASSTAT_DET_BIT_L+1);--//C_PSTAT_DET_ESTABLISH_ON_BIT
i_hdd1layer_dbgcs.trig0(21)<=i_hdd_dbgcs.sh(0).layer.data(161);--<=p_in_alstatus.sstatus(C_ASSTAT_DET_BIT_L+0);--//C_PSTAT_DET_DEV_ON_BIT
i_hdd1layer_dbgcs.trig0(22)<=i_hdd_dbgcs.sh(0).layer.data(162);--<=p_in_txelecidle;
i_hdd1layer_dbgcs.trig0(23)<=i_hdd_dbgcs.sh(0).layer.data(163);--<=p_in_rxelecidle;
i_hdd1layer_dbgcs.trig0(24)<=i_hdd_dbgcs.sh(0).layer.data(164);--<=p_in_txcomstart;
i_hdd1layer_dbgcs.trig0(25)<=i_hdd_dbgcs.sh(0).layer.data(167);--<=p_in_rxcdrreset;
i_hdd1layer_dbgcs.trig0(41 downto 26)<=i_hdd_dbgcs.sh(0).layer.trig0(41 downto 26);--llayer
end generate gen_hdd1;

gen_hdd2 : if C_PCFG_HDD_COUNT>1 generate
m_dbgcs_hdd1_layer : dbgcs_sata_raid_b --dbgcs_sata_layer
port map
(
CONTROL => i_dbgcs_hdd1_layer,
CLK     => i_hdd_dbgcs.sh(1).layer.clk,
DATA    => i_hdd_dbgcs.sh(1).layer.data(255 downto 0),--(122 downto 0),
TRIG0   => i_hdd1layer_dbgcs.trig0(49 downto 0)
);

i_hdd1layer_dbgcs.trig0(19 downto 0)<=i_hdd_dbgcs.sh(1).layer.trig0(19 downto 0);--llayer
i_hdd1layer_dbgcs.trig0(20)<=i_hdd_dbgcs.sh(1).layer.data(160);--<=p_in_alstatus.sstatus(C_ASSTAT_DET_BIT_L+1);--//C_PSTAT_DET_ESTABLISH_ON_BIT
i_hdd1layer_dbgcs.trig0(21)<=i_hdd_dbgcs.sh(1).layer.data(161);--<=p_in_alstatus.sstatus(C_ASSTAT_DET_BIT_L+0);--//C_PSTAT_DET_DEV_ON_BIT
i_hdd1layer_dbgcs.trig0(22)<=i_hdd_dbgcs.sh(1).layer.data(162);--<=p_in_txelecidle;
i_hdd1layer_dbgcs.trig0(23)<=i_hdd_dbgcs.sh(1).layer.data(163);--<=p_in_rxelecidle;
i_hdd1layer_dbgcs.trig0(24)<=i_hdd_dbgcs.sh(1).layer.data(164);--<=p_in_txcomstart;
i_hdd1layer_dbgcs.trig0(25)<=i_hdd_dbgcs.sh(1).layer.data(167);--<=p_in_rxcdrreset;
i_hdd1layer_dbgcs.trig0(41 downto 26)<=i_hdd_dbgcs.sh(1).layer.trig0(41 downto 26);--llayer
end generate gen_hdd2;

end generate gen_sh_dbgcs;


gen_raid_dbgcs : if strcmp(C_PCFG_HDD_RAID_DBGCS,"ON") generate
--//### DGB HDD_RAID: ########
m_dbgcs_icon : dbgcs_iconx1
port map(
CONTROL0 => i_dbgcs_hdd_raid
--CONTROL1 => i_dbgcs_hwcfg
);

m_dbgcs_sh0_raid : dbgcs_sata_raid_b
port map(
CONTROL => i_dbgcs_hdd_raid,
CLK     => i_hdd_dbgcs.raid.clk,
DATA    => i_hddraid_dbgcs.data(255 downto 0),
TRIG0   => i_hddraid_dbgcs.trig0(49 downto 0)
);

--//-------- TRIG: ------------------
i_hddraid_dbgcs.trig0(11 downto 0)<=i_hdd_dbgcs.raid.trig0(11 downto 0);
i_hddraid_dbgcs.trig0(12)<='0';--i_mem_out_bank(C_PCFG_MEMBANK_0)(C_MEMCH_WR).txbuf_err or i_mem_out_bank(C_PCFG_MEMBANK_0)(C_MEMCH_WR).txbuf_underrun;
i_hddraid_dbgcs.trig0(13)<='0';--i_mem_out_bank(C_PCFG_MEMBANK_0)(C_MEMCH_RD).rxbuf_err or i_mem_out_bank(C_PCFG_MEMBANK_0)(C_MEMCH_RD).rxbuf_overflow;
i_hddraid_dbgcs.trig0(14)<='0';--    sr_vch_rst(0) and  not sr_vch_rst(1);--tst_redge;
i_hddraid_dbgcs.trig0(15)<='0';--not sr_vch_rst(0) and      sr_vch_rst(1);--tst_fedge;
i_hddraid_dbgcs.trig0(16)<=i_hdd_dbgcs.raid.trig0(16);--p_in_usr_cxd_wr;
i_hddraid_dbgcs.trig0(17)<=i_hdd_rbuf_status.err_type.rambuf_full or i_hdd_rbuf_status.err_type.bufi_full or
                           (i_hdd_rbuf_cfg.dmacfg.hm_w and i_hdd_bufi_full);-- or (i_hdd_rbuf_cfg.dmacfg.hm_r and i_vbufo_empty);
i_hddraid_dbgcs.trig0(18)<=i_hdd_dbgcs.raid.trig0(18);--dev_done
i_hddraid_dbgcs.trig0(19)<=i_hdd_bufi_empty;--i_vbufi_empty;

--//SH0
i_hddraid_dbgcs.trig0(24 downto 20)<=i_hdd_dbgcs.sh(0).layer.trig0(34 downto 30);--llayer
i_hddraid_dbgcs.trig0(29 downto 25)<=i_hdd_dbgcs.sh(0).layer.trig0(39 downto 35);--tlayer
--//SH1
gen_hdd1 : if C_PCFG_HDD_COUNT=1 generate
i_hddraid_dbgcs.trig0(34 downto 30)<=i_hdd_dbgcs.sh(0).layer.trig0(34 downto 30);--llayer
i_hddraid_dbgcs.trig0(39 downto 35)<=i_hdd_dbgcs.sh(0).layer.trig0(39 downto 35);--tlayer
end generate gen_hdd1;
gen_hdd2 : if C_PCFG_HDD_COUNT>1 generate
i_hddraid_dbgcs.trig0(34 downto 30)<=i_hdd_dbgcs.sh(1).layer.trig0(34 downto 30);--llayer
i_hddraid_dbgcs.trig0(39 downto 35)<=i_hdd_dbgcs.sh(1).layer.trig0(39 downto 35);--tlayer
end generate gen_hdd2;

i_hddraid_dbgcs.trig0(40)<=i_hdd_rbuf_status.err_type.rambuf_full;
i_hddraid_dbgcs.trig0(41)<='0';--p_in_vout_hs;
i_hddraid_dbgcs.trig0(42)<=i_hdd_rbuf_cfg.dmacfg.hm_w and i_hdd_bufi_rd;--OR_reduce(i_vbufi_rd);--start hdd_wr
i_hddraid_dbgcs.trig0(43)<=i_hdd_rbuf_cfg.dmacfg.hm_r;-- and i_hdd_bufo_wr;--start hdd_rd
i_hddraid_dbgcs.trig0(44)<=i_hdd_dbgcs.raid.trig0(17);--i_cmdpkt_get_done
i_hddraid_dbgcs.trig0(45)<=i_hdd_dbgcs.raid.trig0(16);--p_in_usr_cxd_wr;
i_hddraid_dbgcs.trig0(46)<='0';--tst_hddbufi_rst_fedge;
i_hddraid_dbgcs.trig0(47)<='0';--tst_hddbufi_rst_redge;
i_hddraid_dbgcs.trig0(48)<='0';--tst_vctrl_out(14);--i_vwr_fr_rdy
i_hddraid_dbgcs.trig0(49)<=(i_memin_bank(0).rd or i_memin_bank(0).wr) and i_arb_mem_tst_out(3);--i_mem_req_en(3);--i_mem_in_bank (C_PCFG_MEMBANK_0)(C_MEMCH_WR).txd_wr or i_mem_in_bank (C_PCFG_MEMBANK_0)(C_MEMCH_RD).rxd_rd;


--//-------- VIEW: ------------------
i_hddraid_dbgcs.data(28 downto 0)<=i_hdd_dbgcs.raid.data(28 downto 0);
i_hddraid_dbgcs.data(29)<='0';--(i_vbufo_rst or i_vbufi_rst);

--//SH0
i_hddraid_dbgcs.data(34 downto 30)<=i_hdd_dbgcs.sh(0).layer.trig0(34 downto 30);--llayer
i_hddraid_dbgcs.data(39 downto 35)<=i_hdd_dbgcs.sh(0).layer.trig0(39 downto 35);--tlayer
i_hddraid_dbgcs.data(55 downto 40)<=i_hdd_dbgcs.sh(0).layer.data(65 downto 50);--tst_vbufo_dout(15 downto 0);-- i_hdd_bufo_din(7 downto 0)&tst_vbufo_dout(7  downto 0);--
i_hddraid_dbgcs.data(56)          <='0';--i_vbufo_empty;--i_hdd_dbgcs.sh(0).layer.data(49);--p_in_ll_rxd_wr; --llayer->tlayer
i_hddraid_dbgcs.data(57)          <='0';--i_vbufo_full;--i_hdd_dbgcs.sh(0).layer.data(116);--p_in_ll_txd_rd; --llayer<-tlayer
i_hddraid_dbgcs.data(58)          <='0';--i_hdd_dbgcs.sh(0).layer.data(118);--<=p_in_dbg.llayer.txbuf_status.aempty;
i_hddraid_dbgcs.data(59)          <=i_hdd_dbgcs.sh(0).layer.data(119);--<=p_in_dbg.llayer.txbuf_status.empty;
i_hddraid_dbgcs.data(60)          <='0';--tst_vbufi_out(5);--i_det_ext_syn; --i_hdd_dbgcs.sh(0).layer.data(98);--<=p_in_dbg.llayer.rxbuf_status.pfull;
i_hddraid_dbgcs.data(61)          <=i_hdd_dbgcs.sh(0).layer.data(99);--<=p_in_dbg.llayer.txbuf_status.pfull;
i_hddraid_dbgcs.data(62)          <=i_hdd_dbgcs.sh(0).layer.data(33);--sh_err_det   --i_hdd_dbgcs.sh(0).layer.data(117);--<=p_in_dbg.llayer.txd_close;

--//SH1
gen_hdd11 : if C_PCFG_HDD_COUNT=1 generate
i_hddraid_dbgcs.data(67 downto 63)<=i_hdd_dbgcs.sh(0).layer.trig0(34 downto 30);--llayer
i_hddraid_dbgcs.data(72 downto 68)<=i_hdd_dbgcs.sh(0).layer.trig0(39 downto 35);--tlayer
i_hddraid_dbgcs.data(88 downto 73)<=i_hdd_dbgcs.sh(0).layer.data(81 downto 66);--i_hdd_dbgcs.sh(0).layer.data(65 downto 50);
i_hddraid_dbgcs.data(89)          <='0';--i_hdd_dbgcs.sh(0).layer.data(49);--p_in_ll_rxd_wr; --llayer->tlayer
i_hddraid_dbgcs.data(90)          <='0';--i_hdd_dbgcs.sh(0).layer.data(116);--p_in_ll_txd_rd; --llayer<-tlayer
i_hddraid_dbgcs.data(91)          <='0';--i_hdd_dbgcs.sh(0).layer.data(118);--<=p_in_dbg.llayer.txbuf_status.aempty;
i_hddraid_dbgcs.data(92)          <=i_hdd_dbgcs.sh(0).layer.data(119);--<=p_in_dbg.llayer.txbuf_status.empty;
i_hddraid_dbgcs.data(93)          <='0';--i_hdd_dbgcs.sh(0).layer.data(98);--<=p_in_dbg.llayer.rxbuf_status.pfull;
i_hddraid_dbgcs.data(94)          <=i_hdd_dbgcs.sh(0).layer.data(99);--<=p_in_dbg.llayer.txbuf_status.pfull;
i_hddraid_dbgcs.data(95)          <='0';--i_hdd_dbgcs.sh(0).layer.data(117);--<=p_in_dbg.llayer.txd_close;
end generate gen_hdd11;
gen_hdd21 : if C_PCFG_HDD_COUNT>1 generate
i_hddraid_dbgcs.data(67 downto 63)<=i_hdd_dbgcs.sh(1).layer.trig0(34 downto 30);--llayer
i_hddraid_dbgcs.data(72 downto 68)<=i_hdd_dbgcs.sh(1).layer.trig0(39 downto 35);--tlayer
i_hddraid_dbgcs.data(88 downto 73)<=i_hdd_dbgcs.sh(0).layer.data(81 downto 66);--i_hdd_rxbuf_do(7 downto 0)&i_hdd_txbuf_di(7 downto 0);--i_hdd_dbgcs.sh(1).layer.data(65 downto 50);
i_hddraid_dbgcs.data(89)          <='0';--p_in_vout_hs;--i_hdd_dbgcs.sh(1).layer.data(49);--p_in_ll_rxd_wr; --llayer->tlayer
i_hddraid_dbgcs.data(90)          <='0';--p_in_vout_vs;--i_hdd_dbgcs.sh(1).layer.data(116);--p_in_ll_txd_rd; --llayer<-tlayer
i_hddraid_dbgcs.data(91)          <='0';--i_hdd_dbgcs.sh(1).layer.data(118);--<=p_in_dbg.llayer.txbuf_status.aempty;
i_hddraid_dbgcs.data(92)          <=i_hdd_dbgcs.sh(1).layer.data(119);--<=p_in_dbg.llayer.txbuf_status.empty;
i_hddraid_dbgcs.data(93)          <='0';--i_hdd_dbgcs.sh(1).layer.data(98);--<=p_in_dbg.llayer.rxbuf_status.pfull;
i_hddraid_dbgcs.data(94)          <=i_hdd_dbgcs.sh(1).layer.data(99);--<=p_in_dbg.llayer.txbuf_status.pfull;
i_hddraid_dbgcs.data(95)          <='0';--i_hdd_dbgcs.sh(1).layer.data(117);--<=p_in_dbg.llayer.txd_close;
end generate gen_hdd21;

--//
i_hddraid_dbgcs.data(96) <='0';--tst_vbufi_out(2);--i_bufi_wr_en;
i_hddraid_dbgcs.data(97) <='0';--p_in_vin_vs;
i_hddraid_dbgcs.data(98) <='0';--p_in_vin_hs;

i_hddraid_dbgcs.data(99) <=i_hdd_bufi_empty;--i_vbufi_empty;
i_hddraid_dbgcs.data(100)<=i_hdd_bufi_full;--i_vbufi_full;
i_hddraid_dbgcs.data(101)<='0';--tst_vbufi_out(3);--OR_reduce(i_bufi_full);

i_hddraid_dbgcs.data(102)<=i_hdd_txbuf_pfull;
i_hddraid_dbgcs.data(103)<='0';--i_hdd_txbuf_full;
i_hddraid_dbgcs.data(104)<=i_hdd_dbgcs.raid.data(21);--i_hdd_txbuf_empty;

i_hddraid_dbgcs.data(105)<=i_hdd_rxbuf_empty;

i_hddraid_dbgcs.data(106)<=i_hdd_rbuf_status.err_type.rambuf_full;
i_hddraid_dbgcs.data(107)<=i_hdd_rbuf_status.err_type.bufi_full;
i_hddraid_dbgcs.data(108)<=tst_hdd_rambuf_out(11);--tst_rambuf_empty;

--//SH2
i_hddraid_dbgcs.data(113 downto 109)<=i_hdd_dbgcs.sh(2).layer.trig0(34 downto 30);--llayer
i_hddraid_dbgcs.data(118 downto 114)<=i_hdd_dbgcs.sh(2).layer.trig0(39 downto 35);--tlayer
i_hddraid_dbgcs.data(124 downto 119)<=i_hdd_dbgcs.raid.data(135 downto 130);--i_hdd_dbgcs.sh(2).layer.data(55 downto 50);--(65 downto 50);
i_hddraid_dbgcs.data(125)           <='0';--tst_hdd_rambuf_out(24);--<=i_memr_stop;  --i_hdd_dbgcs.sh(2).layer.data(49);--p_in_ll_rxd_wr; --llayer->tlayer
i_hddraid_dbgcs.data(126)           <='0';--tst_hdd_rambuf_out(25);--<=i_memw_start;   --i_hdd_dbgcs.sh(2).layer.data(116);--p_in_ll_txd_rd; --llayer<-tlayer
i_hddraid_dbgcs.data(127)           <='0';--tst_fsm_hddctrl(0);          --i_hdd_dbgcs.sh(2).layer.data(118);--<=p_in_dbg.llayer.txbuf_status.aempty;
i_hddraid_dbgcs.data(128)           <=i_hdd_dbgcs.sh(2).layer.data(119);--<=p_in_dbg.llayer.txbuf_status.empty;
i_hddraid_dbgcs.data(129)           <='0';--i_mem_mux_sel;--i_hdd_dbgcs.sh(2).layer.data(98);--<=p_in_dbg.llayer.rxbuf_status.pfull;
i_hddraid_dbgcs.data(130)           <=i_hdd_dbgcs.sh(2).layer.data(99);--<=p_in_dbg.llayer.txbuf_status.pfull;
i_hddraid_dbgcs.data(131)           <='0';--tst_fsm_hddctrl(1); --i_hdd_dbgcs.sh(2).layer.data(117);--<=p_in_dbg.llayer.txd_close;

--//SH3
i_hddraid_dbgcs.data(136 downto 132)<=i_hdd_dbgcs.sh(3).layer.trig0(34 downto 30);--llayer
i_hddraid_dbgcs.data(137)           <=i_hdd_dbgcs.measure.data(0);--i_dly_on(0);
i_hddraid_dbgcs.data(142 downto 138)<=i_hdd_dbgcs.sh(3).layer.trig0(39 downto 35);--tlayer
i_hddraid_dbgcs.data(148 downto 143)<=i_hdd_dbgcs.raid.data(141 downto 136);--i_hdd_dbgcs.sh(3).layer.data(55 downto 50);--(65 downto 50);
i_hddraid_dbgcs.data(149)           <='0';--tst_hdd_rambuf_out(23);--<=i_memr_start_hm_r          --i_hdd_dbgcs.sh(3).layer.data(49);--p_in_ll_rxd_wr; --llayer->tlayer
i_hddraid_dbgcs.data(150)           <=i_hdd_dbgcs.raid.data(142);--i_hdd_dbgcs.sh(3).layer.data(116);--p_in_ll_txd_rd; --llayer<-tlayer
i_hddraid_dbgcs.data(151)           <='0';--tst_fsm_hddctrl(2);--i_hdd_dbgcs.sh(3).layer.data(118);--<=p_in_dbg.llayer.txbuf_status.aempty;
i_hddraid_dbgcs.data(152)           <=i_hdd_dbgcs.sh(3).layer.data(119);--<=p_in_dbg.llayer.txbuf_status.empty;
i_hddraid_dbgcs.data(153)           <='0';--tst_vctrl_out(14);--i_vwr_fr_rdy  --i_hdd_dbgcs.sh(3).layer.data(98);--<=p_in_dbg.llayer.rxbuf_status.pfull;
i_hddraid_dbgcs.data(154)           <=i_hdd_dbgcs.sh(3).layer.data(99);--<=p_in_dbg.llayer.txbuf_status.pfull;
i_hddraid_dbgcs.data(155)           <='0';--sr_hddbufi_rst(0);--i_hdd_dbgcs.sh(3).layer.data(117);--<=p_in_dbg.llayer.txd_close;

i_hddraid_dbgcs.data(156)<=i_memin_bank(0).ce;--i_mem_in_bank (C_PCFG_MEMBANK_0)(C_MEMCH_WR).cmd_wr        ;
i_hddraid_dbgcs.data(157)<=i_memin_bank(0).cw;--i_mem_in_bank (C_PCFG_MEMBANK_0)(C_MEMCH_WR).txd_wr        ;
i_hddraid_dbgcs.data(158)<=i_memin_bank(0).rd;--i_mem_out_bank(C_PCFG_MEMBANK_0)(C_MEMCH_WR).txbuf_err     ;
i_hddraid_dbgcs.data(159)<=i_memin_bank(0).wr;--i_mem_out_bank(C_PCFG_MEMBANK_0)(C_MEMCH_WR).txbuf_underrun;
i_hddraid_dbgcs.data(160)<=i_memin_bank(0).term;--'0';--i_vctrl_vwr_off;
i_hddraid_dbgcs.data(161)<=i_arb_mem_tst_out(0);--i_mem_req_en  i_mem_in_bank (C_PCFG_MEMBANK_0)(C_MEMCH_RD).cmd_wr        ;
i_hddraid_dbgcs.data(162)<=i_arb_mem_tst_out(1);--i_mem_req_en
i_hddraid_dbgcs.data(163)<=i_arb_mem_tst_out(2);--i_mem_req_en  i_mem_out_bank(C_PCFG_MEMBANK_0)(C_MEMCH_RD).rxbuf_err     ;
i_hddraid_dbgcs.data(164)<=i_arb_mem_tst_out(3);--i_mem_req_en  i_mem_out_bank(C_PCFG_MEMBANK_0)(C_MEMCH_RD).rxbuf_overflow;
i_hddraid_dbgcs.data(165)<=i_hdd_tst_out(5);--i_sh_cxbuf_empty

i_hddraid_dbgcs.data(170 downto 166)<=tst_hdd_rambuf_out(30 downto 26);--tst_fsm_cs
i_hddraid_dbgcs.data(171)<='0';--tst_hdd_rambuf_out(4 downto 2);--mem_wr/fsm_cs
i_hddraid_dbgcs.data(172)<=tst_hdd_rambuf_out(13);--rambuf/padding
i_hddraid_dbgcs.data(204 downto 173)<=(i_hdd_rbuf_status.hwlog_size(29 downto 0)&"00");--i_mem_in_bank (C_PCFG_MEMBANK_0)(C_MEMCH_WR).txd(31 downto 0); --
i_hddraid_dbgcs.data(236 downto 205)<=i_hdd_dbgcs.measure.data(73 downto 42);--i_measure_dly_time(0);--i_mem_out_bank(C_PCFG_MEMBANK_0)(C_MEMCH_RD).rxd(31 downto 0);
i_hddraid_dbgcs.data(239 downto 237)<=(others=>'0');--tst_vctrl_out(26 downto 24);--vwriter/fsm
i_hddraid_dbgcs.data(242 downto 240)<=(others=>'0');--tst_vctrl_out(30 downto 28);--vreader/fsm
i_hddraid_dbgcs.data(245 downto 243)<=(others=>'0');--tst_vctrl_out(4 downto 2);--vwriter/mem_wr/fsm_cs
i_hddraid_dbgcs.data(248 downto 246)<=(others=>'0');--tst_vctrl_out(9 downto 7);--vreader/mem_wr/fsm_cs
i_hddraid_dbgcs.data(249)<='0';--tst_vctrl_out(27);--vwriter/padding
i_hddraid_dbgcs.data(250)<='0';--tst_vctrl_out(31);--vreader/padding
i_hddraid_dbgcs.data(251)<=i_memout_bank(0).buf_wpf;--i_mem_out_bank(C_PCFG_MEMBANK_0)(C_MEMCH_WR).txbuf_full;
i_hddraid_dbgcs.data(252)<=i_memout_bank(0).buf_re ;--i_mem_out_bank(C_PCFG_MEMBANK_0)(C_MEMCH_RD).rxbuf_empty;
i_hddraid_dbgcs.data(255 downto 253)<=i_hdd_dbgcs.raid.data(145 downto 143);

--process(i_hdd_dbgcs.raid.clk)
--begin
--  if i_hdd_dbgcs.raid.clk'event and i_hdd_dbgcs.raid.clk='1' then
--
--    sr_vin_vs<=p_in_vin_vs & sr_vin_vs(0 to 1);
--    i_vin_vs_fedge<=    sr_vin_vs(1) and not sr_vin_vs(2);
--    i_vin_vs_redge<=not sr_vin_vs(1) and     sr_vin_vs(2);
--
--    sr_hddbufi_rst<=((i_hdd_rbuf_cfg.dmacfg.hm_w and not i_hdd_tx_rdy) or i_hdd_rbuf_cfg.dmacfg.hm_r) & sr_hddbufi_rst(0 to 0);
--    tst_hddbufi_rst_fedge<=not sr_hddbufi_rst(0) and     sr_hddbufi_rst(1);--falling edge
--    tst_hddbufi_rst_redge<=    sr_hddbufi_rst(0) and not sr_hddbufi_rst(1);--rissing edge
--
----    if sr_vch_rst(0)='0' and sr_vch_rst(1)='1' then
----      tst_start_wr<='1';
----    elsif i_vbufi_empty='0' then
----      tst_start_wr<='0';
----    end if;
--
--    if i_hdd_rbuf_status.err_type.rambuf_full='1' then
--      --llayer
----      CONV_STD_LOGIC_VECTOR(16#01#, i_fsm_llayer'length) when p_in_dbg.llayer.fsm=S_L_IDLE          else
----      CONV_STD_LOGIC_VECTOR(16#0B#, i_fsm_llayer'length) when p_in_dbg.llayer.fsm=S_LT_RcvHold      else
----      CONV_STD_LOGIC_VECTOR(16#07#, i_fsm_llayer'length) when p_in_dbg.llayer.fsm=S_LT_SendData     else
--
--        for i in 0 to 3 loop
--          if i_hdd_dbgcs.raid.trig0(1)='1' then --=i_sh_det.err;
--            if i_hdd_dbgcs.sh(i).layer.trig0(34 downto 30)=CONV_STD_LOGIC_VECTOR(16#01#, 5) or
--               i_hdd_dbgcs.sh(i).layer.trig0(34 downto 30)=CONV_STD_LOGIC_VECTOR(16#0B#, 5) then
--                tst_sh_err(i)<='1'; --определяем sh по причине которого произошло переполнение
--            end if;
--          end if;
--
--          if tst_sh_err(i)='1' and i_hdd_dbgcs.sh(i).layer.trig0(34 downto 30)=CONV_STD_LOGIC_VECTOR(16#07#, 5) then
--            tst_llayer_send_data(i)<='1';
--          end if;
--        end loop;
--    else
--      tst_sh_err<=(others=>'0');
--      tst_llayer_send_data<=(others=>'0');
--    end if;
--  end if;
--end process;
--
--tst_fsm_hddctrl<=CONV_STD_LOGIC_VECTOR(16#01#, tst_fsm_hddctrl'length) when fsm_hddctrl=S_HDD_ELBA    else
--                 CONV_STD_LOGIC_VECTOR(16#02#, tst_fsm_hddctrl'length) when fsm_hddctrl=S_HDD_DLY0    else
--                 CONV_STD_LOGIC_VECTOR(16#03#, tst_fsm_hddctrl'length) when fsm_hddctrl=S_HDD_CMD     else
--                 CONV_STD_LOGIC_VECTOR(16#04#, tst_fsm_hddctrl'length) when fsm_hddctrl=S_HDD_DLY1    else
--                 CONV_STD_LOGIC_VECTOR(16#05#, tst_fsm_hddctrl'length) when fsm_hddctrl=S_HDD_DONE    else
--                 CONV_STD_LOGIC_VECTOR(16#00#, tst_fsm_hddctrl'length) ; --//when fsm_hddctrl=S_IDLE else


--m_dbgcs_hwcfg : dbgcs_sata_layer
--port map
--(
--CONTROL => i_dbgcs_hwcfg,
--CLK     => i_hdd_dbgcs.raid.clk,--p_in_vin_clk,--p_in_vout_clk,
--DATA    => i_vout_dbgcs.data(122 downto 0),
--TRIG0   => i_vout_dbgcs.trig0(41 downto 0)
--);
----//-------- TRIG: ------------------
--i_vout_dbgcs.trig0(0)<='0';
--i_vout_dbgcs.trig0(1)<=p_in_vout_hs;
--i_vout_dbgcs.trig0(2)<=tst_vbufo_out(0);--i_hd_mrk;
--i_vout_dbgcs.trig0(3)<=tst_vbufo_out(1);--i_buf_rd_en;
--i_vout_dbgcs.trig0(4)<=tst_vbufo_out(2);--i_vs_edge
--i_vout_dbgcs.trig0(5)<=tst_vbufo_out(3);--i_hd_vden
--i_vout_dbgcs.trig0(6)<=i_vbufo_empty;
--i_vout_dbgcs.trig0(7)<=p_in_vout_vs;
--i_vout_dbgcs.trig0(8)<=p_in_ext_syn;
--
--i_vout_dbgcs.trig0(9)<=p_in_vin_hs;
--i_vout_dbgcs.trig0(10)<=p_in_vin_vs;
--i_vout_dbgcs.trig0(11)<=i_vbufi_empty;
--i_vout_dbgcs.trig0(12)<=tst_vbufi_out(5);--i_det_ext_syn;
--i_vout_dbgcs.trig0(13)<=tst_vbufi_out(2);--i_bufi_wr_en;
--i_vout_dbgcs.trig0(14)<=i_vin_vs_fedge;
--i_vout_dbgcs.trig0(15)<=i_vin_vs_redge;
--i_vout_dbgcs.trig0(16)<=tst_vbufo_out(4);--i_vs_edge2
--i_vout_dbgcs.trig0(17)<=i_hdd_rbuf_cfg.dmacfg.hw_mode;
--
--i_vout_dbgcs.trig0(18)<=i_hdd_rbuf_status.err_type.rambuf_full;
--i_vout_dbgcs.trig0(19)<=OR_reduce(tst_llayer_send_data);--p_in_vout_hs;
--
--i_vout_dbgcs.trig0(i_vout_dbgcs.trig0'high downto 20)<=(others=>'0');
--
--
----//-------- VIEW: ------------------
--i_vout_dbgcs.data(15 downto 0)<=i_vbufo_dout(15 downto 0);
--i_vout_dbgcs.data(16)<=p_in_vout_vs;
--i_vout_dbgcs.data(17)<=p_in_vout_hs;
--i_vout_dbgcs.data(18)<=tst_vbufo_out(0);--i_hd_mrk;
--i_vout_dbgcs.data(19)<=tst_vbufo_out(1);--i_buf_rd_en;
--i_vout_dbgcs.data(20)<=tst_vbufo_out(2);--i_vs_edge
--i_vout_dbgcs.data(21)<=tst_vbufo_out(3);--i_hd_vden
--i_vout_dbgcs.data(22)<=i_vbufo_empty;
--i_vout_dbgcs.data(23)<=p_in_ext_syn;
--i_vout_dbgcs.data(26 downto 24)<=i_cam_ctrl(15 downto 13);
--
--i_vout_dbgcs.data(27)<=p_in_vin_hs;
--i_vout_dbgcs.data(28)<=p_in_vin_vs;
--i_vout_dbgcs.data(29)<=i_vbufi_empty;
--i_vout_dbgcs.data(30)<=tst_vbufi_out(5);--i_det_ext_syn;
--i_vout_dbgcs.data(31)<=tst_vbufi_out(2);--i_bufi_wr_en;
--
--i_vout_dbgcs.data(44 downto 32)<=i_cam_ctrl(12 downto 0);
--
--i_vout_dbgcs.data(45)<=i_vbufi_ext_sync;
--i_vout_dbgcs.data(46)<='0';
--
--i_vout_dbgcs.data(51 downto 47)<=i_hdd_dbgcs.sh(0).layer.trig0(34 downto 30);--llayer
--i_vout_dbgcs.data(56 downto 52)<=i_hdd_dbgcs.sh(0).layer.trig0(39 downto 35);--tlayer
--
--i_vout_dbgcs.data(61 downto 57)<=i_hdd_dbgcs.sh(1).layer.trig0(34 downto 30);--llayer
--i_vout_dbgcs.data(66 downto 62)<=i_hdd_dbgcs.sh(1).layer.trig0(39 downto 35);--tlayer
--
--i_vout_dbgcs.data(71 downto 67)<=i_hdd_dbgcs.sh(2).layer.trig0(34 downto 30);--llayer
--i_vout_dbgcs.data(76 downto 72)<=i_hdd_dbgcs.sh(2).layer.trig0(39 downto 35);--tlayer
--
--i_vout_dbgcs.data(91 downto 87)<=i_hdd_dbgcs.sh(3).layer.trig0(34 downto 30);--llayer
--i_vout_dbgcs.data(96 downto 92)<=i_hdd_dbgcs.sh(3).layer.trig0(39 downto 35);--tlayer
--
--i_vout_dbgcs.data(100 downto 97)<=i_hdd_dbgcs.raid.data(11 downto 8);--raid/i_usr_status.ch_bsy
--i_vout_dbgcs.data(104 downto 101)<=tst_sh_err(3 downto 0);
--i_vout_dbgcs.data(105)<=i_hdd_dbgcs.measure.data(0);--i_dly_on(0);
--i_vout_dbgcs.data(106)<=i_hdd_rbuf_status.err_type.rambuf_full;
--i_vout_dbgcs.data(107)<=i_hdd_rbuf_status.err_type.bufi_full;
--
--i_vout_dbgcs.data(i_vout_dbgcs.data'high downto 108)<=(others=>'0');

end generate gen_raid_dbgcs;

end generate gen_hdd_dbgcs;

end architecture;
