-------------------------------------------------------------------------
-- Company     : Linkos
-- Engineer    : Golovachenko Victor
--
-- Create Date : 23.11.2011 18:05:23
-- Module Name : veresk_main
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
use work.prom_phypin_pkg.all;

entity veresk_main is
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
pin_out_led         : out   std_logic_vector(7 downto 0);
pin_out_TP          : out   std_logic_vector(2 downto 0);

--------------------------------------------------
--Memory banks
--------------------------------------------------
pin_out_phymem      : out   TMEMCTRL_phy_outs;
pin_inout_phymem    : inout TMEMCTRL_phy_inouts;

--------------------------------------------------
--Ethernet
--------------------------------------------------
pin_out_ethphy      : out   TEthPhyPinOUT;
pin_in_ethphy       : in    TEthPhyPinIN;
pin_inout_ethphy_mdio  : inout std_logic;
pin_out_ethphy_mdc     : out   std_logic;

--------------------------------------------------
--PCI-EXPRESS
--------------------------------------------------
pin_out_pciexp_txp  : out   std_logic_vector(C_PCGF_PCIE_LINK_WIDTH - 1 downto 0);
pin_out_pciexp_txn  : out   std_logic_vector(C_PCGF_PCIE_LINK_WIDTH - 1 downto 0);
pin_in_pciexp_rxp   : in    std_logic_vector(C_PCGF_PCIE_LINK_WIDTH - 1 downto 0);
pin_in_pciexp_rxn   : in    std_logic_vector(C_PCGF_PCIE_LINK_WIDTH - 1 downto 0);
pin_in_pciexp_rstn  : in    std_logic;

--------------------------------------------------
--PULT
--------------------------------------------------
pin_in_pult_rx      : in    std_logic;
pin_out_pult_tx     : out   std_logic;
pin_out_pult_dir    : out   std_logic;

--------------------------------------------------
--EDEV
--------------------------------------------------
pin_in_edev_rx      : in    std_logic;
pin_out_edev_tx     : out   std_logic;
pin_out_edev_dir    : out   std_logic;

--------------------------------------------------
--BUP (Блок управления приводами)
--------------------------------------------------
pin_in_bup_rx       : in    std_logic;
pin_out_bup_tx      : out   std_logic;
pin_out_bup_dir     : out   std_logic;

--------------------------------------------------
--VIZIR
--------------------------------------------------
pin_in_vizir_rx     : in    std_logic;
pin_out_vizir_tx    : out   std_logic;
pin_out_vizir_dir   : out   std_logic;

--------------------------------------------------
--SYNC
--------------------------------------------------
pin_in_pps          : in    std_logic;
pin_in_1s           : in    std_logic;
pin_in_1m           : in    std_logic;
pin_out_1s          : out   std_logic;
pin_out_1m          : out   std_logic;
pin_out_s120Hz      : out   std_logic;
pin_out_s120SAU     : out   std_logic;

--------------------------------------------------
--PROM
--------------------------------------------------
pin_in_prom         : in    TPromPhyIN;
pin_out_prom        : out   TPromPhyOUT;
pin_inout_prom      : inout TPromPhyINOUT;

--------------------------------------------------
--Reference clock
--------------------------------------------------
pin_out_refclk      : out   TRefClkPinOUT;
pin_in_refclk       : in    TRefClkPinIN
);
end entity;

architecture struct of veresk_main is

component fpga_test_01
generic(
G_BLINK_T05   : integer:=10#125#; -- 1/2 периода мигания светодиода.(время в ms)
G_CLK_T05us   : integer:=10#1000# -- кол-во периодов частоты порта p_in_clk
                                  -- укладывающиес_ в 1/2 периода 1us
);
port(
p_out_test_led : out   std_logic;--мигание сведодиода
p_out_test_done: out   std_logic;--сигнал переходи в '1' через 3 сек.

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
p_out_clk  : out   TRefClkPinOUT;
p_in_clk   : in    TRefClkPinIN
);
end component;

signal i_usrclk_rst                     : std_logic;
signal g_usrclk                         : std_logic_vector(7 downto 0);
signal g_usr_highclk                    : std_logic;
signal g_refclkopt                      : std_logic_vector(3 downto 0);
signal i_pciexp_gt_refclk               : std_logic;
signal g_pciexp_gt_refclkout            : std_logic;
signal i_usrclk5_div                    : std_logic_vector(4 downto 0):=(others=>'0');

signal i_host_rst_n                     : std_logic;
signal g_host_clk                       : std_logic;
signal i_host_gctrl                     : std_logic_vector(C_HREG_CTRL_LAST_BIT downto 0);
signal i_host_dev_ctrl                  : std_logic_vector(C_HREG_DEV_CTRL_LAST_BIT downto 0);
signal i_host_dev_txd                   : std_logic_vector(C_HDEV_DWIDTH - 1 downto 0);
signal i_host_dev_rxd                   : std_logic_vector(C_HDEV_DWIDTH - 1 downto 0);
signal i_host_dev_wr                    : std_logic;
signal i_host_dev_rd                    : std_logic;
signal i_host_dev_status                : std_logic_vector(C_HREG_DEV_STATUS_LAST_BIT downto 0);
signal i_host_dev_irq                   : std_logic_vector(C_HIRQ_COUNT_MAX - 1 downto 0);
signal i_host_dev_opt_in                : std_logic_vector(C_HDEV_OPTIN_LAST_BIT downto 0);
signal i_host_dev_opt_out               : std_logic_vector(C_HDEV_OPTOUT_LAST_BIT downto 0);

signal i_host_devadr                    : std_logic_vector(C_HREG_DEV_CTRL_ADR_M_BIT
                                                              - C_HREG_DEV_CTRL_ADR_L_BIT downto 0);
signal i_host_vchsel                    : std_logic_vector(3 downto 0);

Type THostDCtrl is array (0 to C_HDEV_COUNT - 1) of std_logic;
Type THostDWR is array (0 to C_HDEV_COUNT - 1) of std_logic_vector(C_HDEV_DWIDTH - 1 downto 0);
signal i_host_wr                        : THostDCtrl;
signal i_host_rd                        : THostDCtrl;
signal i_host_txd                       : THostDWR;
signal i_host_rxd                       : THostDWR;
signal i_host_rxbuf_full                : THostDCtrl;
signal i_host_rxbuf_empty               : THostDCtrl;
signal i_host_txbuf_full                : THostDCtrl;
signal i_host_txbuf_empty               : THostDCtrl;
signal i_host_txd_rdy                   : THostDCtrl;
signal i_host_err                       : THostDCtrl;

signal i_hdev_dma_start                 : std_logic_vector(C_HDEV_VCH downto C_HDEV_VCH);
signal hclk_hdev_dma_start              : std_logic_vector(C_HDEV_VCH downto C_HDEV_VCH);
Type THDevWidthCnt is array (C_HDEV_VCH to C_HDEV_VCH) of std_logic_vector(2 downto 0);
signal hclk_hdev_dma_start_cnt          : THDevWidthCnt;

signal i_host_tst_in                    : std_logic_vector(127 downto 0);
signal i_host_tst_out                   : std_logic_vector(127 downto 0);
--signal i_host_tst2_out                  : std_logic_vector(255 downto 0);

signal i_cfg_rst                        : std_logic;
signal i_cfg_dadr                       : std_logic_vector(C_CFGPKT_DADR_M_BIT - C_CFGPKT_DADR_L_BIT downto 0);
signal i_cfg_radr                       : std_logic_vector(C_CFGPKT_RADR_M_BIT - C_CFGPKT_RADR_L_BIT downto 0);
signal i_cfg_radr_ld                    : std_logic;
signal i_cfg_radr_fifo                  : std_logic;
signal i_cfg_wr                         : std_logic;
signal i_cfg_rd                         : std_logic;
signal i_cfg_txd                        : std_logic_vector(15 downto 0);
signal i_cfg_rxd                        : std_logic_vector(15 downto 0);
Type TCfgRxD is array (0 to C_CFGDEV_COUNT - 1) of std_logic_vector(i_cfg_rxd'range);
signal i_cfg_rxd_dev                    : TCfgRxD;
signal i_cfg_done                       : std_logic;
signal i_cfg_wr_dev                     : std_logic_vector(C_CFGDEV_COUNT - 1 downto 0);
signal i_cfg_rd_dev                     : std_logic_vector(C_CFGDEV_COUNT - 1 downto 0);
signal i_cfg_done_dev                   : std_logic_vector(C_CFGDEV_COUNT - 1 downto 0);
--signal i_cfg_tst_out                    : std_logic_vector(31 downto 0);

signal i_swt_rst                        : std_logic;
signal i_swt_tst_out                    : std_logic_vector(31 downto 0);
signal i_swt_tst_in                     : std_logic_vector(31 downto 0);
signal i_eth_rst                        : std_logic;
signal i_eth_out                        : TEthOUTs;
signal i_eth_in                         : TEthINs;
signal i_ethphy_out                     : TEthPhyOUT;
signal i_ethphy_in                      : TEthPhyIN;
--signal i_eth_tst_out                    : std_logic_vector(31 downto 0);
signal dbg_eth_out                      : TEthDBG;

signal i_tmr_rst                        : std_logic;
signal i_tmr_clk                        : std_logic;
signal i_tmr_hirq                       : std_logic_vector(C_TMR_COUNT - 1 downto 0);
signal i_tmr_en                         : std_logic_vector(C_TMR_COUNT - 1 downto 0);

signal i_vctrl_rst                      : std_logic;
signal hclk_hrddone_vctrl_cnt           : std_logic_vector(2 downto 0);
signal hclk_hrddone_vctrl               : std_logic;
signal i_vctrl_vbufi_do                 : std_logic_vector(C_PCFG_VCTRL_VBUFI_OWIDTH - 1 downto 0);
signal i_vctrl_vbufi_rd                 : std_logic;
signal i_vctrl_vbufi_empty              : std_logic;
signal i_vctrl_vbufi_pfull              : std_logic;
signal i_vctrl_vbufi_full               : std_logic;

signal i_vctrl_hrd_start                : std_logic;
signal i_vctrl_hrd_done                 : std_logic;
signal sr_vctrl_hrd_done                : std_logic_vector(1 downto 0);
signal i_vctrl_hrdy                     : std_logic_vector(C_VCTRL_VCH_COUNT - 1 downto 0);
signal i_vctrl_hfrmrk                   : std_logic_vector(31 downto 0);
signal i_vctrl_tst_out                  : std_logic_vector(31 downto 0);
signal i_vctrl_tst_in                   : std_logic_vector(31 downto 0);

signal i_host_mem_rst                   : std_logic;
signal i_host_mem_ctrl                  : TPce2Mem_Ctrl;
signal i_host_mem_status                : TPce2Mem_Status;
signal i_host_mem_tst_out               : std_logic_vector(31 downto 0);

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

signal i_sync_out                       : std_logic_vector(0 downto 0);

signal i_clk1MHz_en                     : std_logic;
signal i_pult_rst                       : std_logic;
signal i_edev_rst                       : std_logic;
signal i_bup_rst                        : std_logic;
signal i_bup_syn_en                     : std_logic;
signal i_bup_syn                        : std_logic;
signal i_vizir_rst                      : std_logic;

signal i_out_1s                         : std_logic;
signal i_pps                            : std_logic;

signal i_prom_rst                       : std_logic;

attribute keep : string;
attribute keep of g_host_clk : signal is "true";
attribute keep of g_usr_highclk : signal is "true";
attribute keep of g_usrclk : signal is "true";
attribute keep of i_ethphy_out : signal is "true";

signal i_test01_led     : std_logic;
signal tst_clr          : std_logic;
--signal tst_edev_out     : std_logic_vector(31 downto 0);
--signal tst_prom_out     : std_logic_vector(31 downto 0);


--MAIN
begin


--***********************************************************
--RESET модулей
--***********************************************************
i_host_rst_n <= pin_in_pciexp_rstn;

i_tmr_rst <= not i_host_rst_n or i_host_gctrl(C_HREG_CTRL_RST_ALL_BIT);
i_cfg_rst <= not i_host_rst_n or i_host_gctrl(C_HREG_CTRL_RST_ALL_BIT);

i_eth_rst <= not i_host_rst_n or i_host_gctrl(C_HREG_CTRL_RST_ALL_BIT)
                              or i_host_gctrl(C_HREG_CTRL_RST_ETH_BIT);

i_vctrl_rst <= not i_host_rst_n or i_host_gctrl(C_HREG_CTRL_RST_ALL_BIT);
i_swt_rst <= not i_host_rst_n or i_host_gctrl(C_HREG_CTRL_RST_ALL_BIT);
i_host_mem_rst <= not OR_reduce(i_mem_ctrl_status.rdy);
i_mem_ctrl_sysin.rst <= not i_host_rst_n or i_host_gctrl(C_HREG_CTRL_RST_ALL_BIT);
i_arb_mem_rst <= not OR_reduce(i_mem_ctrl_status.rdy);

i_pult_rst <= i_usrclk_rst or i_host_gctrl(C_HREG_CTRL_RST_ALL_BIT)
                            or i_host_gctrl(C_HREG_CTRL_RST_PULT_BIT);

i_edev_rst <= i_usrclk_rst or i_host_gctrl(C_HREG_CTRL_RST_ALL_BIT)
                            or i_host_gctrl(C_HREG_CTRL_RST_EDEV_BIT);

i_vizir_rst <= i_usrclk_rst or i_host_gctrl(C_HREG_CTRL_RST_ALL_BIT)
                            or i_host_gctrl(C_HREG_CTRL_RST_VIZIR_BIT);

i_bup_rst <= i_usrclk_rst or i_host_gctrl(C_HREG_CTRL_RST_ALL_BIT)
                          or i_host_gctrl(C_HREG_CTRL_RST_BUP_BIT);

i_prom_rst <= i_usrclk_rst or i_host_gctrl(C_HREG_CTRL_RST_PROM_BIT);


--***********************************************************
--Установка частот проекта:
--***********************************************************
m_clocks : clocks
port map(
p_out_rst  => i_usrclk_rst,
p_out_gclk => g_usrclk,

p_in_clkopt=> g_refclkopt,
p_out_clk  => pin_out_refclk,
p_in_clk   => pin_in_refclk
);

g_refclkopt(0) <= g_host_clk;
g_refclkopt(1) <= i_ethphy_out.clk;

g_usr_highclk <= i_mem_ctrl_sysout.clk;
i_tmr_clk <= g_usrclk(2);
i_mem_ctrl_sysin.ref_clk <= g_usrclk(0);
i_mem_ctrl_sysin.clk <= g_usrclk(1);

i_pciexp_gt_refclk <= g_usrclk(3);
i_ethphy_in.clk <= g_usrclk(4);


--***********************************************************
--Модуль конфигурирования устр-в
--***********************************************************
m_cfg : cfgdev_host
generic map(
G_DBG => "OFF",
G_HOST_DWIDTH => C_HDEV_DWIDTH
)
port map(
-------------------------------
--Связь с Хостом
-------------------------------
--host -> dev
p_in_htxbuf_di       => i_host_txd(C_HDEV_CFG),
p_in_htxbuf_wr       => i_host_wr(C_HDEV_CFG),
p_out_htxbuf_full    => i_host_txbuf_full(C_HDEV_CFG),
p_out_htxbuf_empty   => i_host_txbuf_empty(C_HDEV_CFG),

--host <- dev
p_out_hrxbuf_do      => i_host_rxd(C_HDEV_CFG),
p_in_hrxbuf_rd       => i_host_rd(C_HDEV_CFG),
p_out_hrxbuf_full    => open,
p_out_hrxbuf_empty   => i_host_rxbuf_empty(C_HDEV_CFG),

p_out_hirq           => i_host_dev_irq(C_HIRQ_CFG),
p_out_herr           => open,

p_in_hclk            => g_host_clk,

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

--Распределяем управление от блока конфигурирования(cfgdev.vhd):
i_cfg_rxd <= i_cfg_rxd_dev(C_CFGDEV_ETH)   when i_cfg_dadr(3 downto 0) = CONV_STD_LOGIC_VECTOR(C_CFGDEV_ETH, 4)   else
             i_cfg_rxd_dev(C_CFGDEV_VCTRL) when i_cfg_dadr(3 downto 0) = CONV_STD_LOGIC_VECTOR(C_CFGDEV_VCTRL, 4) else
             i_cfg_rxd_dev(C_CFGDEV_SWT)   when i_cfg_dadr(3 downto 0) = CONV_STD_LOGIC_VECTOR(C_CFGDEV_SWT, 4)   else
             i_cfg_rxd_dev(C_CFGDEV_TMR);--   when i_cfg_dadr(3 downto 0) = CONV_STD_LOGIC_VECTOR(C_CFGDEV_TMR, 4)   else

gen_cfg_dev : for i in 0 to C_CFGDEV_COUNT - 1 generate
i_cfg_wr_dev(i)   <= i_cfg_wr   when i_cfg_dadr = i else '0';
i_cfg_rd_dev(i)   <= i_cfg_rd   when i_cfg_dadr = i else '0';
i_cfg_done_dev(i) <= i_cfg_done when i_cfg_dadr = i else '0';
end generate gen_cfg_dev;


--***********************************************************
--Проект модуля Таймер
--***********************************************************
m_tmr : dsn_timer
port map(
-------------------------------
--CFG
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
--
-------------------------------
p_in_tmr_clk      => i_tmr_clk,
p_out_tmr_rdy     => open,
p_out_tmr_error   => open,

p_out_tmr_irq     => i_tmr_hirq,
p_out_tmr_en      => i_tmr_en,

-------------------------------
--System
-------------------------------
p_in_rst => i_tmr_rst
);


--***********************************************************
--Проект модуля Комутатор
--***********************************************************
m_swt : dsn_switch
generic map(
G_ETH_CH_COUNT => C_PCFG_ETH_COUNT,
G_ETH_DWIDTH => C_PCFG_ETH_USR_DWIDTH,
G_VBUFI_OWIDTH => C_PCFG_VCTRL_VBUFI_OWIDTH,
G_HOST_DWIDTH => C_HDEV_DWIDTH
)
port map(
-------------------------------
--CFG
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
--HOST
-------------------------------
--host -> dev
p_in_eth_htxbuf_di        => i_host_txd(C_HDEV_ETH),
p_in_eth_htxbuf_wr        => i_host_wr(C_HDEV_ETH),
p_out_eth_htxbuf_full     => i_host_txbuf_full(C_HDEV_ETH),
p_out_eth_htxbuf_empty    => i_host_txbuf_empty(C_HDEV_ETH),

--host <- dev
p_out_eth_hrxbuf_do       => i_host_rxd(C_HDEV_ETH),
p_in_eth_hrxbuf_rd        => i_host_rd(C_HDEV_ETH),
p_out_eth_hrxbuf_full     => i_host_rxbuf_full(C_HDEV_ETH),
p_out_eth_hrxbuf_empty    => i_host_rxbuf_empty(C_HDEV_ETH),

p_out_eth_hirq            => i_host_dev_irq(C_HIRQ_ETH),

p_in_hclk                 => g_host_clk,

-------------------------------
--ETH
-------------------------------
p_in_eth_tmr_irq          => i_tmr_hirq(C_TMR_ETH),
p_in_eth_tmr_en           => i_tmr_en(C_TMR_ETH),
p_in_eth_clk              => i_ethphy_out.clk,
p_in_eth                  => i_eth_out,
p_out_eth                 => i_eth_in,

-------------------------------
--VBUFI
-------------------------------
p_in_vbufi_rdclk          => g_usr_highclk,
p_out_vbufi_do            => i_vctrl_vbufi_do,
p_in_vbufi_rd             => i_vctrl_vbufi_rd,
p_out_vbufi_empty         => i_vctrl_vbufi_empty,
p_out_vbufi_full          => i_vctrl_vbufi_full,
p_out_vbufi_pfull         => i_vctrl_vbufi_pfull,

-------------------------------
--Технологический
-------------------------------
p_in_tst                  => (others=>'0'),--i_swt_tst_in,
p_out_tst                 => i_swt_tst_out,

-------------------------------
--System
-------------------------------
p_in_rst => i_swt_rst
);


--***********************************************************
--Проект Ethernet - dsn_eth.vhd
--***********************************************************
pin_out_ethphy <= i_ethphy_out.pin;
i_ethphy_in.pin <= pin_in_ethphy;

i_ethphy_in.opt(C_ETHPHY_OPTIN_REFCLK_IODELAY_BIT) <= g_usrclk(0);
i_ethphy_in.opt(32) <= g_usrclk(6);
i_ethphy_in.opt(33) <= i_usrclk_rst;--rst
i_ethphy_in.opt(34) <= g_usrclk(2);--clkdrp

pin_inout_ethphy_mdio <= i_ethphy_out.mdio when i_ethphy_out.mdio_t = '1' else 'Z';
pin_out_ethphy_mdc <= i_ethphy_out.mdc;
i_ethphy_in.mdio <= pin_inout_ethphy_mdio;

m_eth : dsn_eth
generic map(
G_ETH.ch_count        => C_PCFG_ETH_COUNT,
G_ETH.usrbuf_dwidth   => C_PCFG_ETH_USR_DWIDTH,
G_ETH.phy_dwidth      => C_PCFG_ETH_PHY_DWIDTH,
G_ETH.phy_select      => C_PCFG_ETH_PHY_SEL,
G_ETH.mac_length_swap => C_PCFG_ETH_MAC_LEN_SWAP,
G_MODULE_USE => C_PCFG_ETH_USE,
G_DBG        => C_PCFG_ETH_DBG,
G_SIM        => G_SIM
)
port map(
-------------------------------
--CFG
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
--USR
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
m_vctrl : dsn_video_ctrl
generic map(
G_USR_OPT => C_PCFG_VCTRL_USR_OPT,
G_DBGCS => C_PCFG_VCTRL_DBG,
G_MEM_AWIDTH => C_HREG_MEM_ADR_LAST_BIT,
G_MEMWR_DWIDTH => C_PCFG_VCTRL_VBUFI_OWIDTH,
G_MEMRD_DWIDTH => C_HDEV_DWIDTH
)
port map(
-------------------------------
--CFG
-------------------------------
p_in_cfg_clk         => g_host_clk,

p_in_cfg_adr         => i_cfg_radr(7 downto 0),
p_in_cfg_adr_ld      => i_cfg_radr_ld,
p_in_cfg_adr_fifo    => i_cfg_radr_fifo,

p_in_cfg_txdata      => i_cfg_txd,
p_in_cfg_wd          => i_cfg_wr_dev(C_CFGDEV_VCTRL),

p_out_cfg_rxdata     => i_cfg_rxd_dev(C_CFGDEV_VCTRL),
p_in_cfg_rd          => i_cfg_rd_dev(C_CFGDEV_VCTRL),

p_in_cfg_done        => i_cfg_done_dev(C_CFGDEV_VCTRL),

-------------------------------
--HOST
-------------------------------
p_in_hrdchsel        => i_host_vchsel,
p_in_hrdstart        => i_vctrl_hrd_start,
p_in_hrddone         => i_vctrl_hrd_done,
p_out_hirq           => i_host_dev_irq((C_HIRQ_VCH0 + C_VCTRL_VCH_COUNT) - 1 downto C_HIRQ_VCH0),
p_out_hdrdy          => i_vctrl_hrdy,
p_out_hfrmrk         => i_vctrl_hfrmrk,

p_in_vbufo_rdclk     => g_host_clk,
p_out_vbufo_do       => i_host_rxd(C_HDEV_VCH),
p_in_vbufo_rd        => i_host_rd(C_HDEV_VCH),
p_out_vbufo_empty    => i_host_rxbuf_empty(C_HDEV_VCH),

-------------------------------
--VBUFI
-------------------------------
p_in_vbufi_do        => i_vctrl_vbufi_do,
p_out_vbufi_rd       => i_vctrl_vbufi_rd,
p_in_vbufi_empty     => i_vctrl_vbufi_empty,
p_in_vbufi_full      => i_vctrl_vbufi_full,
p_in_vbufi_pfull     => i_vctrl_vbufi_pfull,

---------------------------------
--MEM
---------------------------------
--CH WRITE
p_out_memwr          => i_memin_ch(1),  --DEV -> MEM
p_in_memwr           => i_memout_ch(1), --DEV <- MEM
--CH READ
p_out_memrd          => i_memin_ch(2),  --DEV -> MEM
p_in_memrd           => i_memout_ch(2), --DEV <- MEM

-------------------------------
--Технологический
-------------------------------
p_in_tst             => i_vctrl_tst_in,
p_out_tst            => i_vctrl_tst_out,

-------------------------------
--System
-------------------------------
p_in_clk => g_usr_highclk,
p_in_rst => i_vctrl_rst
);

i_vctrl_tst_in(0) <= i_swt_tst_out(0);
i_vctrl_tst_in(31 downto 1) <= (others=>'0');


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
--USR Port
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
p_out_tst          => open,--i_host_tst2_out,

-------------------------------
--System
-------------------------------
p_out_module_rdy   => open,
p_in_rst_n         => i_host_rst_n
);

i_host_tst_in(31 downto 0) <= (others=>'0');
i_host_tst_in(63 downto 32) <= (others=>'0');
i_host_tst_in(64) <= i_vctrl_tst_out(0) or
                    OR_reduce(dbg_eth_out.app(0).mac_rx) or OR_reduce(dbg_eth_out.app(0).mac_tx);

i_host_tst_in(127 downto 66) <= (others=>'0');


--Статусы устройств
i_host_dev_status(C_HREG_DEV_STATUS_CFG_RDY_BIT) <= '1';
i_host_dev_status(C_HREG_DEV_STATUS_CFG_RXRDY_BIT) <= not i_host_rxbuf_empty(C_HDEV_CFG);
i_host_dev_status(C_HREG_DEV_STATUS_CFG_TXRDY_BIT) <= i_host_txbuf_empty(C_HDEV_CFG);

i_host_dev_status(C_HREG_DEV_STATUS_ETH_RDY_BIT) <= i_ethphy_out.rdy;
i_host_dev_status(C_HREG_DEV_STATUS_ETH_LINK_BIT) <= i_ethphy_out.link;
i_host_dev_status(C_HREG_DEV_STATUS_ETH_RXRDY_BIT) <= not i_host_rxbuf_empty(C_HDEV_ETH);
i_host_dev_status(C_HREG_DEV_STATUS_ETH_TXRDY_BIT) <= i_host_txbuf_empty(C_HDEV_ETH);

gen_status_vch : for i in 0 to C_VCTRL_VCH_COUNT - 1 generate
i_host_dev_status(C_HREG_DEV_STATUS_VCH0_FRRDY_BIT + i) <= i_vctrl_hrdy(i);
end generate gen_status_vch;

i_host_dev_status(C_HREG_DEV_STATUS_MEMCTRL_RDY_BIT) <= OR_reduce(i_mem_ctrl_status.rdy);

i_host_dev_status(C_HREG_DEV_STATUS_PULT_TXRDY_BIT) <= not i_host_txbuf_empty(C_HDEV_PULT);
i_host_dev_status(C_HREG_DEV_STATUS_PULT_RXRDY_BIT) <= i_host_dev_irq(C_HIRQ_PULT);

i_host_dev_status(C_HREG_DEV_STATUS_EDEV_RXERR_BIT) <= i_host_err(C_HDEV_EDEV);
i_host_dev_status(C_HREG_DEV_STATUS_EDEV_TXRDY_BIT) <= i_host_txbuf_empty(C_HDEV_EDEV);
i_host_dev_status(C_HREG_DEV_STATUS_EDEV_RXRDY_BIT) <= not i_host_rxbuf_empty(C_HDEV_EDEV)
                                                          and i_host_dev_irq(C_HIRQ_EDEV);

i_host_dev_status(C_HREG_DEV_STATUS_VIZIR_RXERR_BIT) <= i_host_err(C_HDEV_VIZIR);
i_host_dev_status(C_HREG_DEV_STATUS_VIZIR_TXRDY_BIT) <= i_host_txbuf_empty(C_HDEV_VIZIR);
i_host_dev_status(C_HREG_DEV_STATUS_VIZIR_RXRDY_BIT) <= not i_host_rxbuf_empty(C_HDEV_VIZIR)
                                                          and i_host_dev_irq(C_HIRQ_VIZIR);

i_host_dev_status(C_HREG_DEV_STATUS_BUP_RXERR_BIT) <= i_host_err(C_HDEV_BUP);
i_host_dev_status(C_HREG_DEV_STATUS_BUP_TXRDY_BIT) <= i_host_txbuf_empty(C_HDEV_BUP);
i_host_dev_status(C_HREG_DEV_STATUS_BUP_RXRDY_BIT) <= not i_host_rxbuf_empty(C_HDEV_BUP)
                                                        and i_host_dev_irq(C_HIRQ_BUP);

i_host_dev_status(C_HREG_DEV_STATUS_PROM_TXRDY_BIT) <= i_host_txbuf_empty(C_HDEV_PROM);
i_host_dev_status(C_HREG_DEV_STATUS_PROM_RXRDY_BIT) <= not i_host_rxbuf_empty(C_HDEV_PROM);
i_host_dev_status(C_HREG_DEV_STATUS_PROM_ERR_BIT) <= i_host_err(C_HDEV_PROM);

--Запись/Чтение данных устройств хоста
gen_dev_dbuf : for i in 0 to i_host_wr'length - 1 generate
i_host_wr(i)  <= i_host_dev_wr when i_host_devadr = CONV_STD_LOGIC_VECTOR(i, i_host_devadr'length) else '0';
i_host_rd(i)  <= i_host_dev_rd when i_host_devadr = CONV_STD_LOGIC_VECTOR(i, i_host_devadr'length) else '0';
i_host_txd(i) <= i_host_dev_txd;
i_host_txd_rdy(i) <= i_host_dev_ctrl(C_HREG_DEV_CTRL_DRDY_BIT)
                      when i_host_devadr = CONV_STD_LOGIC_VECTOR(i, i_host_devadr'length) else '0';
end generate gen_dev_dbuf;

i_host_dev_rxd
<= i_host_rxd(C_HDEV_CFG)   when i_host_devadr = CONV_STD_LOGIC_VECTOR(C_HDEV_CFG  , i_host_devadr'length) else
    i_host_rxd(C_HDEV_ETH)   when i_host_devadr = CONV_STD_LOGIC_VECTOR(C_HDEV_ETH  , i_host_devadr'length) else
    i_host_rxd(C_HDEV_MEM)   when i_host_devadr = CONV_STD_LOGIC_VECTOR(C_HDEV_MEM  , i_host_devadr'length) else
    i_host_rxd(C_HDEV_VCH)   when i_host_devadr = CONV_STD_LOGIC_VECTOR(C_HDEV_VCH  , i_host_devadr'length) else
    i_host_rxd(C_HDEV_EDEV)  when i_host_devadr = CONV_STD_LOGIC_VECTOR(C_HDEV_EDEV , i_host_devadr'length) else
    i_host_rxd(C_HDEV_PULT)  when i_host_devadr = CONV_STD_LOGIC_VECTOR(C_HDEV_PULT , i_host_devadr'length) else
    i_host_rxd(C_HDEV_VIZIR) when i_host_devadr = CONV_STD_LOGIC_VECTOR(C_HDEV_VIZIR, i_host_devadr'length) else
    i_host_rxd(C_HDEV_BUP)   when i_host_devadr = CONV_STD_LOGIC_VECTOR(C_HDEV_BUP  , i_host_devadr'length) else
    i_host_rxd(C_HDEV_PROM);--  when i_host_devadr = CONV_STD_LOGIC_VECTOR(C_HDEV_PROM , i_host_devadr'length) else

--Флаги (Host<-dev)
i_host_dev_opt_in(C_HDEV_OPTIN_TXFIFO_FULL_BIT)
<= i_host_txbuf_full(C_HDEV_MEM)  when i_host_devadr = CONV_STD_LOGIC_VECTOR(C_HDEV_MEM , i_host_devadr'length) else
    i_host_txbuf_full(C_HDEV_PROM) when i_host_devadr = CONV_STD_LOGIC_VECTOR(C_HDEV_PROM, i_host_devadr'length) else
    '0';

i_host_dev_opt_in(C_HDEV_OPTIN_RXFIFO_EMPTY_BIT)
<= i_host_rxbuf_empty(C_HDEV_MEM)  when i_host_devadr = CONV_STD_LOGIC_VECTOR(C_HDEV_MEM , i_host_devadr'length) else
    i_host_rxbuf_empty(C_HDEV_VCH)  when i_host_devadr = CONV_STD_LOGIC_VECTOR(C_HDEV_VCH , i_host_devadr'length) else
    i_host_rxbuf_empty(C_HDEV_PROM) when i_host_devadr = CONV_STD_LOGIC_VECTOR(C_HDEV_PROM, i_host_devadr'length) else
    '0';

i_host_dev_opt_in(C_HDEV_OPTIN_MEMTRN_DONE_BIT) <= i_host_mem_status.done;

i_host_dev_opt_in(C_HDEV_OPTIN_VCTRL_FRMRK_M_BIT downto C_HDEV_OPTIN_VCTRL_FRMRK_L_BIT) <= i_vctrl_hfrmrk;
i_host_dev_opt_in(C_HDEV_OPTIN_ETH_HEADER_M_BIT
                    downto C_HDEV_OPTIN_ETH_HEADER_L_BIT) <= i_host_rxd(C_HDEV_ETH)(31 downto 0);


--Обработка управляющих сигналов Хоста
i_host_mem_ctrl.dir <= not i_host_dev_ctrl(C_HREG_DEV_CTRL_DMA_DIR_BIT);
i_host_mem_ctrl.start <= i_host_dev_ctrl(C_HREG_DEV_CTRL_DMA_START_BIT)
                          when i_host_devadr = CONV_STD_LOGIC_VECTOR(C_HDEV_MEM,
                                                                        i_host_devadr'length) else '0';

i_host_mem_ctrl.adr <= i_host_dev_opt_out(C_HDEV_OPTOUT_MEM_ADR_M_BIT downto C_HDEV_OPTOUT_MEM_ADR_L_BIT);

i_host_mem_ctrl.req_len <= i_host_dev_opt_out(C_HDEV_OPTOUT_MEM_RQLEN_M_BIT
                                                  downto C_HDEV_OPTOUT_MEM_RQLEN_L_BIT);

i_host_mem_ctrl.trnwr_len <= i_host_dev_opt_out(C_HDEV_OPTOUT_MEM_TRNWR_LEN_M_BIT
                                                    downto C_HDEV_OPTOUT_MEM_TRNWR_LEN_L_BIT);

i_host_mem_ctrl.trnrd_len <= i_host_dev_opt_out(C_HDEV_OPTOUT_MEM_TRNRD_LEN_M_BIT
                                                  downto C_HDEV_OPTOUT_MEM_TRNRD_LEN_L_BIT);


i_host_devadr <= i_host_dev_ctrl(C_HREG_DEV_CTRL_ADR_M_BIT downto C_HREG_DEV_CTRL_ADR_L_BIT);

i_host_vchsel <= EXT(i_host_dev_ctrl(C_HREG_DEV_CTRL_VCH_M_BIT
                                      downto C_HREG_DEV_CTRL_VCH_L_BIT), i_host_vchsel'length);

gen_dma_start : for i in C_HDEV_VCH to C_HDEV_VCH generate
process(g_host_clk)
begin
  if rising_edge(g_host_clk) then
    if i_host_gctrl(C_HREG_CTRL_RST_ALL_BIT) = '1' then
      i_hdev_dma_start(i) <= '0';
      hclk_hdev_dma_start(i) <= '0';
      hclk_hdev_dma_start_cnt(i) <= (others=>'0');

    else
      --импульс начала DMA транзакции
      if i_host_devadr = i then
        if i_host_dev_ctrl(C_HREG_DEV_CTRL_DMA_START_BIT) = '1' then
          i_hdev_dma_start(i) <= '1';
        else
          i_hdev_dma_start(i) <= '0';
        end if;
      end if;

      --Растягиваем импульс начала DMA транзакции
      if i_hdev_dma_start(i) = '1' then
        hclk_hdev_dma_start(i) <= '1';
      elsif hclk_hdev_dma_start_cnt(i)(hclk_hdev_dma_start_cnt(i)'high) = '1' then
        hclk_hdev_dma_start(i) <= '0';
      end if;

      if hclk_hdev_dma_start(i) = '0' then
        hclk_hdev_dma_start_cnt(i) <= (others=>'0');
      else
        hclk_hdev_dma_start_cnt(i) <= hclk_hdev_dma_start_cnt(i) + 1;
      end if;

    end if;
  end if;
end process;

end generate gen_dma_start;

--Пересинхронизация управляющих сигналов Хоста
process(g_usr_highclk)
begin
  if rising_edge(g_usr_highclk) then
    i_vctrl_hrd_start <= hclk_hdev_dma_start(C_HDEV_VCH);

    sr_vctrl_hrd_done(0) <= hclk_hrddone_vctrl;
    sr_vctrl_hrd_done(1) <= sr_vctrl_hrd_done(0);
    i_vctrl_hrd_done <= sr_vctrl_hrd_done(0) and not sr_vctrl_hrd_done(1);

  end if;
end process;

--Растягиваем импульс подтверждения вычетки кадра
process(g_host_clk)
begin
  if rising_edge(g_host_clk) then
    if i_host_gctrl(C_HREG_CTRL_RST_ALL_BIT) = '1' then
      hclk_hrddone_vctrl <= '0';
      hclk_hrddone_vctrl_cnt <= (others=>'0');

    else

      if i_host_gctrl(C_HREG_CTRL_RDDONE_VCTRL_BIT) = '1' then
        hclk_hrddone_vctrl <= '1';
      elsif hclk_hrddone_vctrl_cnt(hclk_hrddone_vctrl_cnt'high) = '1' then
        hclk_hrddone_vctrl <= '0';
      end if;

      if hclk_hrddone_vctrl = '0' then
        hclk_hrddone_vctrl_cnt <= (others=>'0');
      else
        hclk_hrddone_vctrl_cnt <= hclk_hrddone_vctrl_cnt + 1;
      end if;

    end if;
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
--HOST
-------------------------------
p_in_ctrl         => i_host_mem_ctrl,
p_out_status      => i_host_mem_status,

--host -> dev
p_in_htxbuf_di     => i_host_txd(C_HDEV_MEM),
p_in_htxbuf_wr     => i_host_wr(C_HDEV_MEM),
p_out_htxbuf_full  => i_host_txbuf_full(C_HDEV_MEM),
p_out_htxbuf_empty => open,

--host <- dev
p_out_hrxbuf_do    => i_host_rxd(C_HDEV_MEM),
p_in_hrxbuf_rd     => i_host_rd(C_HDEV_MEM),
p_out_hrxbuf_full  => open,
p_out_hrxbuf_empty => i_host_rxbuf_empty(C_HDEV_MEM),

p_in_hclk          => g_host_clk,

-------------------------------
--MEM
-------------------------------
p_out_mem         => i_memin_ch(0), --DEV -> MEM
p_in_mem          => i_memout_ch(0),--DEV <- MEM

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


--Арбитр контроллера памяти
m_mem_arb : mem_arb
generic map(
G_CH_COUNT   => C_MEM_ARB_CH_COUNT,
G_MEM_AWIDTH => C_AXI_AWIDTH,
G_MEM_DWIDTH => C_AXIM_DWIDTH
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

--Подключаем арбитра ОЗУ к соотв банку
i_memin_bank(0) <= i_arb_memin;
i_arb_memout    <= i_memout_bank(0);

--Core Memory controller
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


--#########################################
--DBG
--#########################################
pin_out_led(0) <= i_test01_led;
pin_out_led(1) <= '0';
pin_out_led(2) <= '0';
pin_out_led(3) <= i_vctrl_tst_out(30);
pin_out_led(4) <= i_vctrl_tst_out(29);
pin_out_led(5) <= i_vctrl_tst_out(28);
pin_out_led(6) <= i_vctrl_tst_out(27);
pin_out_led(7) <= '0';


m_led_tst: fpga_test_01
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


--***********************************************************
--Модуль управления синхронизацией
--***********************************************************
m_sync : sync_u
port map(
i_pps         => i_pps,
i_ext_1s      => pin_in_1s,
i_ext_1m      => pin_in_1m,

sync_iedge    => i_host_gctrl(C_HREG_CTRL_ESYNC_IEDGE_BIT),
sync_oedge    => i_host_gctrl(C_HREG_CTRL_ESYNC_OEDGE_BIT),
sync_time_en  => i_host_gctrl(C_HREG_CTRL_TIME_EN_BIT),
mode_set_time => i_host_gctrl(C_HREG_CTRL_TIME_MODE_BIT),
type_of_sync  => i_host_gctrl(C_HREG_CTRL_ESYNC_MODE_M_BIT downto C_HREG_CTRL_ESYNC_MODE_L_BIT),

sync_win      => open,

stime         => i_host_dev_opt_in(C_HDEV_OPTIN_TIME_M_BIT downto C_HDEV_OPTIN_TIME_L_BIT),
n_sync        => open,
sync_cou_err  => open,

sync_out1     => i_sync_out(0),
out_1s        => i_out_1s,
out_1m        => pin_out_1m,
sync_out2     => open,
sync_ld       => open,
sync_pic      => open,
--sync_piezo    => open,
--sync_cam_ir   => open,

host_wr_data  => i_host_dev_opt_out(C_HDEV_OPTOUT_TIME_M_BIT downto C_HDEV_OPTOUT_TIME_L_BIT),
wr_en_time    => i_host_dev_opt_out(C_HDEV_OPTOUT_TIME_SET_BIT),
host_clk      => g_host_clk,

i_clk         => g_usrclk(7)
);

pin_out_s120Hz  <= i_sync_out(0);
pin_out_s120SAU <= i_sync_out(0);

pin_out_1s <= i_out_1s;
i_pps <= not pin_in_pps;

pin_out_TP(0) <= not i_out_1s;
pin_out_TP(1) <= not i_sync_out(0);
pin_out_TP(2) <= pin_in_pps;


--***********************************************************
--Модуль управления пультом
--***********************************************************
process(g_usrclk)
begin
  if rising_edge(g_usrclk(5)) then
    i_usrclk5_div <= i_usrclk5_div + 1;

    if i_usrclk5_div = CONV_STD_LOGIC_VECTOR(16#10#, i_usrclk5_div'length) then
    i_clk1MHz_en <= '1'; --1MHz/4 = 250kHz (bit clk)
    else
    i_clk1MHz_en <= '0';
    end if;

  end if;
end process;

m_pult : pult_io
generic map(
G_HOST_DWIDTH => C_HDEV_DWIDTH
)
port map(
trans_ack      => i_host_txd_rdy(C_HDEV_PULT),

data_i         => pin_in_pult_rx  ,
data_o         => pin_out_pult_tx ,
dir_485        => pin_out_pult_dir,

host_clk_wr    => g_host_clk,
wr_en          => i_host_wr(C_HDEV_PULT),
data_from_host => i_host_txd(C_HDEV_PULT),

host_clk_rd    => g_host_clk,
rd_en          => i_host_rd(C_HDEV_PULT),
data_to_host   => i_host_rxd(C_HDEV_PULT),

busy           => i_host_txbuf_empty(C_HDEV_PULT),
ready          => i_host_dev_irq(C_HIRQ_PULT),

tmr_en         => i_tmr_en(C_TMR_PULT),
tmr_stb        => i_tmr_hirq(C_TMR_PULT),
clk_io_en      => i_clk1MHz_en,
clk_io         => g_usrclk(5),
rst            => i_pult_rst
);


--***********************************************************
--RS485 (связь с уст-вами в теодалите)
--***********************************************************
m_edev : edev
generic map(
G_HOST_DWIDTH => C_HDEV_DWIDTH
)
port map(
p_in_tmr_en       => i_tmr_en(C_TMR_EDEV),
p_in_tmr_stb      => i_tmr_hirq(C_TMR_EDEV),

-------------------------------
--Связь с HOST
-------------------------------
--host -> dev
p_in_htxbuf_di      => i_host_txd(C_HDEV_EDEV),
p_in_htxbuf_wr      => i_host_wr(C_HDEV_EDEV),
p_out_htxbuf_full   => i_host_txbuf_full(C_HDEV_EDEV),
p_out_htxbuf_empty  => i_host_txbuf_empty(C_HDEV_EDEV),

--host <- dev
p_out_hrxbuf_do     => i_host_rxd(C_HDEV_EDEV),
p_in_hrxbuf_rd      => i_host_rd(C_HDEV_EDEV),
p_out_hrxbuf_full   => open,
p_out_hrxbuf_empty  => i_host_rxbuf_empty(C_HDEV_EDEV),

p_in_htxrdy         => i_host_txd_rdy(C_HDEV_EDEV),
p_out_hirq          => i_host_dev_irq(C_HIRQ_EDEV),
p_out_herr          => i_host_err(C_HDEV_EDEV),

p_in_hclk           => g_host_clk,

--------------------------------------
--PHY (half-duplex)
--------------------------------------
p_in_phy_rx       => pin_in_edev_rx  ,
p_out_phy_tx      => pin_out_edev_tx ,
p_out_phy_dir     => pin_out_edev_dir,

--------------------------------------
--
--------------------------------------
p_in_tst          => (others=>'0'),
p_out_tst         => open,--tst_edev_out,--

--------------------------------------
--System
--------------------------------------
p_in_bitclk       => '1', -- 1/0  = bitclk 1MHz/ bitclk 250kHz
p_in_clk          => g_usrclk(5),
p_in_rst          => i_edev_rst
);


--***********************************************************
--БУП (Блок управления приводами)
--***********************************************************
i_bup_syn_en <= i_tmr_en(C_TMR_BUP) or i_host_gctrl(C_HREG_CTRL_EN_SYN120_BUP_BIT);
i_bup_syn    <= i_tmr_hirq(C_TMR_BUP) or
                (i_host_gctrl(C_HREG_CTRL_EN_SYN120_BUP_BIT) and i_sync_out(0)); --120Hz из модуля m_sync

m_bup : edev
generic map(
G_HOST_DWIDTH => C_HDEV_DWIDTH
)
port map(
p_in_tmr_en       => i_bup_syn_en,
p_in_tmr_stb      => i_bup_syn,

-------------------------------
--Связь с HOST
-------------------------------
--host -> dev
p_in_htxbuf_di      => i_host_txd(C_HDEV_BUP),
p_in_htxbuf_wr      => i_host_wr(C_HDEV_BUP),
p_out_htxbuf_full   => i_host_txbuf_full(C_HDEV_BUP),
p_out_htxbuf_empty  => i_host_txbuf_empty(C_HDEV_BUP),

--host <- dev
p_out_hrxbuf_do     => i_host_rxd(C_HDEV_BUP),
p_in_hrxbuf_rd      => i_host_rd(C_HDEV_BUP),
p_out_hrxbuf_full   => open,
p_out_hrxbuf_empty  => i_host_rxbuf_empty(C_HDEV_BUP),

p_in_htxrdy         => i_host_txd_rdy(C_HDEV_BUP),
p_out_hirq          => i_host_dev_irq(C_HIRQ_BUP),
p_out_herr          => i_host_err(C_HDEV_BUP),

p_in_hclk           => g_host_clk,

--------------------------------------
--PHY (half-duplex)
--------------------------------------
p_in_phy_rx       => pin_in_bup_rx  ,
p_out_phy_tx      => pin_out_bup_tx ,
p_out_phy_dir     => pin_out_bup_dir,

--------------------------------------
--
--------------------------------------
p_in_tst          => (others=>'0'),
p_out_tst         => open,

--------------------------------------
--System
--------------------------------------
p_in_bitclk       => '1',  -- 1/0  = bitclk 1MHz/ bitclk 250kHz
p_in_clk          => g_usrclk(5),
p_in_rst          => i_bup_rst
);


--***********************************************************
--Визир
--***********************************************************
m_vizir : edev
generic map(
G_HOST_DWIDTH => C_HDEV_DWIDTH
)
port map(
p_in_tmr_en       => i_tmr_en(C_TMR_VIZIR),
p_in_tmr_stb      => i_tmr_hirq(C_TMR_VIZIR),

-------------------------------
--Связь с HOST
-------------------------------
--host -> dev
p_in_htxbuf_di      => i_host_txd(C_HDEV_VIZIR),
p_in_htxbuf_wr      => i_host_wr(C_HDEV_VIZIR),
p_out_htxbuf_full   => i_host_txbuf_full(C_HDEV_VIZIR),
p_out_htxbuf_empty  => i_host_txbuf_empty(C_HDEV_VIZIR),

--host <- dev
p_out_hrxbuf_do     => i_host_rxd(C_HDEV_VIZIR),
p_in_hrxbuf_rd      => i_host_rd(C_HDEV_VIZIR),
p_out_hrxbuf_full   => open,
p_out_hrxbuf_empty  => i_host_rxbuf_empty(C_HDEV_VIZIR),

p_in_htxrdy         => i_host_txd_rdy(C_HDEV_VIZIR),
p_out_hirq          => i_host_dev_irq(C_HIRQ_VIZIR),
p_out_herr          => i_host_err(C_HDEV_VIZIR),

p_in_hclk           => g_host_clk,

--------------------------------------
--PHY (half-duplex)
--------------------------------------
p_in_phy_rx       => pin_in_vizir_rx  ,
p_out_phy_tx      => pin_out_vizir_tx ,
p_out_phy_dir     => pin_out_vizir_dir,

--------------------------------------
--
--------------------------------------
p_in_tst          => (others=>'0'),
p_out_tst         => open,

--------------------------------------
--System
--------------------------------------
p_in_bitclk       => i_host_gctrl(C_HREG_CTRL_BITCLK_VIZIR_BIT),
p_in_clk          => g_usrclk(5),
p_in_rst          => i_vizir_rst
);


--***********************************************************
--FLASH with firmware
--***********************************************************
m_prom : prom_ld
generic map(
G_HOST_DWIDTH => C_HDEV_DWIDTH
)
port map(
-------------------------------
--Связь с HOST
-------------------------------
--host -> dev
p_in_htxbuf_di      => i_host_txd(C_HDEV_PROM),
p_in_htxbuf_wr      => i_host_wr(C_HDEV_PROM),
p_out_htxbuf_full   => i_host_txbuf_full(C_HDEV_PROM),
p_out_htxbuf_empty  => i_host_txbuf_empty(C_HDEV_PROM),

--host <- dev
p_out_hrxbuf_do     => i_host_rxd(C_HDEV_PROM),
p_in_hrxbuf_rd      => i_host_rd(C_HDEV_PROM),
p_out_hrxbuf_full   => open,
p_out_hrxbuf_empty  => i_host_rxbuf_empty(C_HDEV_PROM),

p_out_hirq          => i_host_dev_irq(C_HIRQ_PROM),
p_out_herr          => i_host_err(C_HDEV_PROM),

p_in_hclk           => g_host_clk,

-------------------------------
--PHY
-------------------------------
p_in_phy         => pin_in_prom,
p_out_phy        => pin_out_prom,
p_inout_phy      => pin_inout_prom,

-------------------------------
--Технологический
-------------------------------
p_in_tst         => (others=>'0'),
p_out_tst        => open,--tst_prom_out,

-------------------------------
--System
-------------------------------
p_in_clk         => i_tmr_clk,
p_in_rst         => i_prom_rst
);


end architecture;
