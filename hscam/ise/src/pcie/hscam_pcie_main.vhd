-------------------------------------------------------------------------
-- Company     : Linkos
-- Engineer    : Golovachenko Victor
--
-- Create Date : 16.01.2013 13:02:57
-- Module Name : hscam_pcie_main
--
-- Назначение/Описание :
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
use work.hscam_pkg.all;
use work.cfgdev_pkg.all;
use work.mem_ctrl_pkg.all;
use work.mem_wr_pkg.all;
use work.dsn_video_ctrl_pkg.all;
use work.pcie_pkg.all;
use work.clocks_pkg.all;
use work.prom_phypin_pkg.all;

entity hscam_pcie_main is
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
pin_out_TP          : out   std_logic_vector(7 downto 0);

--------------------------------------------------
--Memory banks
--------------------------------------------------
pin_out_phymem      : out   TMEMCTRL_phy_outs;
pin_inout_phymem    : inout TMEMCTRL_phy_inouts;

--------------------------------------------------
--PCI-EXPRESS
--------------------------------------------------
pin_out_pciexp_txp  : out   std_logic_vector(C_PCGF_PCIE_LINK_WIDTH - 1 downto 0);
pin_out_pciexp_txn  : out   std_logic_vector(C_PCGF_PCIE_LINK_WIDTH - 1 downto 0);
pin_in_pciexp_rxp   : in    std_logic_vector(C_PCGF_PCIE_LINK_WIDTH - 1 downto 0);
pin_in_pciexp_rxn   : in    std_logic_vector(C_PCGF_PCIE_LINK_WIDTH - 1 downto 0);
pin_in_pciexp_rstn  : in    std_logic;

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

architecture struct of hscam_pcie_main is

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

signal i_host_devadr                    : std_logic_vector(C_HREG_DEV_CTRL_ADR_M_BIT - C_HREG_DEV_CTRL_ADR_L_BIT downto 0);
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
--signal i_host_txd_rdy                   : THostDCtrl;
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
signal i_swt_tst_out,i_swt_tst_in       : std_logic_vector(31 downto 0);

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

signal i_prom_rst                       : std_logic;

attribute keep : string;
attribute keep of g_host_clk : signal is "true";
attribute keep of g_usr_highclk : signal is "true";
attribute keep of g_usrclk : signal is "true";

signal i_test01_led     : std_logic;
signal tst_clr          : std_logic;
--signal tst_edev_out     : std_logic_vector(31 downto 0);
--signal tst_prom_out     : std_logic_vector(31 downto 0);

signal i_ccd_vd                         : std_logic_vector(C_PCFG_CCD_DWIDTH - 1 downto 0);
signal i_ccd_vs                         : std_logic;
signal i_ccd_hs                         : std_logic;
signal i_ccd_vclk                       : std_logic;
signal i_ccd_vclk_en                    : std_logic;
signal i_ccd_cfg                        : std_logic_vector(15 downto 0);
signal i_ccd_vpix                       : std_logic_vector(15 downto 0);
signal i_ccd_vrow                       : std_logic_vector(15 downto 0);
signal i_ccd_syn_h                      : std_logic_vector(15 downto 0);
signal i_ccd_syn_v                      : std_logic_vector(15 downto 0);
signal i_ccd_d80_d32_clk                : std_logic;
signal i_ccd_tst_out                    : std_logic_vector(31 downto 0);
signal i_ccd_fps                        : std_logic_vector(3 downto 0) := (others=>'0');


--MAIN
begin


--***********************************************************
--RESET модулей
--***********************************************************
i_host_rst_n <= pin_in_pciexp_rstn;

i_tmr_rst <= not i_host_rst_n or i_host_gctrl(C_HREG_CTRL_RST_ALL_BIT);
i_cfg_rst <= not i_host_rst_n or i_host_gctrl(C_HREG_CTRL_RST_ALL_BIT);

i_vctrl_rst <= not i_host_rst_n or i_host_gctrl(C_HREG_CTRL_RST_ALL_BIT);
i_swt_rst <= not i_host_rst_n or i_usrclk_rst or i_host_gctrl(C_HREG_CTRL_RST_ALL_BIT);
i_host_mem_rst <= not OR_reduce(i_mem_ctrl_status.rdy);
i_mem_ctrl_sysin.rst <= not i_host_rst_n or i_host_gctrl(C_HREG_CTRL_RST_ALL_BIT);
i_arb_mem_rst <= not OR_reduce(i_mem_ctrl_status.rdy);

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

g_usr_highclk <= i_mem_ctrl_sysout.clk;
i_tmr_clk <= g_usrclk(2);
i_mem_ctrl_sysin.ref_clk <= g_usrclk(0);
i_mem_ctrl_sysin.clk <= g_usrclk(1);

i_pciexp_gt_refclk <= g_usrclk(3);

i_ccd_vclk <= g_usrclk(5);--pixclk
i_ccd_d80_d32_clk <= g_usrclk(0);--частота конвертирования данных 80bit -> 32bit


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
i_cfg_rxd <= i_cfg_rxd_dev(C_CFGDEV_VCTRL) when i_cfg_dadr(3 downto 0) = CONV_STD_LOGIC_VECTOR(C_CFGDEV_VCTRL, 4) else
             i_cfg_rxd_dev(C_CFGDEV_SWT)   when i_cfg_dadr(3 downto 0) = CONV_STD_LOGIC_VECTOR(C_CFGDEV_SWT, 4)   else
             i_cfg_rxd_dev(C_CFGDEV_TMR)   when i_cfg_dadr(3 downto 0) = CONV_STD_LOGIC_VECTOR(C_CFGDEV_TMR, 4)   else
             (others=>'0');

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
G_VBUF_IWIDTH => C_PCFG_CCD_DWIDTH,
G_VBUF_OWIDTH => C_PCFG_VCTRL_VBUFI_OWIDTH
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
--Связь с ImageSensor
-------------------------------
p_in_vd                   => i_ccd_vd,
p_in_vs                   => i_ccd_vs,
p_in_hs                   => i_ccd_hs,
p_in_vclk                 => i_ccd_vclk,
p_in_vclk_en              => i_ccd_vclk_en,
p_in_ext_syn              => '0',

p_in_convert_clk          => i_ccd_d80_d32_clk,

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
p_in_tst                  => i_swt_tst_in,
p_out_tst                 => i_swt_tst_out,

-------------------------------
--System
-------------------------------
p_in_rst => i_swt_rst
);

i_swt_tst_in(0) <= i_tmr_hirq(C_TMR_ETH);
i_swt_tst_in(1) <= i_tmr_en(C_TMR_ETH);
i_swt_tst_in(31 downto 2) <= (others=>'0');


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

i_vctrl_tst_in(0) <= i_swt_tst_out(0);--Сброс выходного видеобуфера !!!
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
i_host_tst_in(64) <= i_vctrl_tst_out(0);

i_host_tst_in(127 downto 66) <= (others=>'0');


--Статусы устройств
i_host_dev_status(C_HREG_DEV_STATUS_CFG_RDY_BIT) <= '1';
i_host_dev_status(C_HREG_DEV_STATUS_CFG_RXRDY_BIT) <= not i_host_rxbuf_empty(C_HDEV_CFG);
i_host_dev_status(C_HREG_DEV_STATUS_CFG_TXRDY_BIT) <= i_host_txbuf_empty(C_HDEV_CFG);

i_host_dev_status(C_HREG_DEV_STATUS_ETH_RDY_BIT) <= '1';
i_host_dev_status(C_HREG_DEV_STATUS_ETH_LINK_BIT) <= '1';
i_host_dev_status(C_HREG_DEV_STATUS_ETH_RXRDY_BIT) <= '0';
i_host_dev_status(C_HREG_DEV_STATUS_ETH_TXRDY_BIT) <= '1';

gen_status_vch : for i in 0 to C_VCTRL_VCH_COUNT - 1 generate
i_host_dev_status(C_HREG_DEV_STATUS_VCH0_FRRDY_BIT + i) <= i_vctrl_hrdy(i);
end generate gen_status_vch;

i_host_dev_status(C_HREG_DEV_STATUS_MEMCTRL_RDY_BIT) <= OR_reduce(i_mem_ctrl_status.rdy);

i_host_dev_status(C_HREG_DEV_STATUS_PROM_TXRDY_BIT) <= i_host_txbuf_empty(C_HDEV_PROM);
i_host_dev_status(C_HREG_DEV_STATUS_PROM_RXRDY_BIT) <= not i_host_rxbuf_empty(C_HDEV_PROM);
i_host_dev_status(C_HREG_DEV_STATUS_PROM_ERR_BIT) <= i_host_err(C_HDEV_PROM);

--Запись/Чтение данных устройств хоста
gen_dev_dbuf : for i in 0 to i_host_wr'length - 1 generate
i_host_wr(i)  <= i_host_dev_wr when i_host_devadr = CONV_STD_LOGIC_VECTOR(i, i_host_devadr'length) else '0';
i_host_rd(i)  <= i_host_dev_rd when i_host_devadr = CONV_STD_LOGIC_VECTOR(i, i_host_devadr'length) else '0';
i_host_txd(i) <= i_host_dev_txd;
end generate gen_dev_dbuf;

i_host_dev_rxd
<= i_host_rxd(C_HDEV_CFG)   when i_host_devadr = CONV_STD_LOGIC_VECTOR(C_HDEV_CFG  , i_host_devadr'length) else
    i_host_rxd(C_HDEV_MEM)   when i_host_devadr = CONV_STD_LOGIC_VECTOR(C_HDEV_MEM  , i_host_devadr'length) else
    i_host_rxd(C_HDEV_VCH)   when i_host_devadr = CONV_STD_LOGIC_VECTOR(C_HDEV_VCH  , i_host_devadr'length) else
    i_host_rxd(C_HDEV_PROM);--  when i_host_devadr = CONV_STD_LOGIC_VECTOR(C_HDEV_PROM , i_host_devadr'length) else

--Флаги (Host<-dev)
i_host_dev_opt_in(C_HDEV_OPTIN_TXFIFO_FULL_BIT)
<= i_host_txbuf_full(C_HDEV_MEM) when i_host_devadr = CONV_STD_LOGIC_VECTOR(C_HDEV_MEM , i_host_devadr'length) else
    i_host_txbuf_full(C_HDEV_PROM) when i_host_devadr = CONV_STD_LOGIC_VECTOR(C_HDEV_PROM, i_host_devadr'length) else
    '0';

i_host_dev_opt_in(C_HDEV_OPTIN_RXFIFO_EMPTY_BIT)
<= i_host_rxbuf_empty(C_HDEV_MEM) when i_host_devadr = CONV_STD_LOGIC_VECTOR(C_HDEV_MEM , i_host_devadr'length) else
    i_host_rxbuf_empty(C_HDEV_VCH) when i_host_devadr = CONV_STD_LOGIC_VECTOR(C_HDEV_VCH , i_host_devadr'length) else
    i_host_rxbuf_empty(C_HDEV_PROM) when i_host_devadr = CONV_STD_LOGIC_VECTOR(C_HDEV_PROM, i_host_devadr'length) else
    '0';


i_host_dev_opt_in(C_HDEV_OPTIN_MEMTRN_DONE_BIT) <= i_host_mem_status.done;

i_host_dev_opt_in(C_HDEV_OPTIN_VCTRL_FRMRK_M_BIT downto C_HDEV_OPTIN_VCTRL_FRMRK_L_BIT) <= i_vctrl_hfrmrk;


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
pin_out_led(3) <= '0';
pin_out_led(4) <= '0';
pin_out_led(5) <= '0';
pin_out_led(6) <= '0';
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



--#########################################
--Генератор видеопотока
--#########################################
i_ccd_vpix <= CONV_STD_LOGIC_VECTOR(1280/(C_PCFG_CCD_DWIDTH/8), i_ccd_vpix'length);
i_ccd_vrow <= CONV_STD_LOGIC_VECTOR(1024, i_ccd_vrow'length);

--Управление через рег. C_HREG_TST0
--3..0 -  --0/1/2/3/4 - 30fps/60fps/120fps/240fps/480fps/
--7..4 -  --0/1/2/    - Test picture: V+H Counter/ V Counter/ H Counter/
i_ccd_cfg(7 downto 0) <= i_host_tst_out(7 downto 0);
i_ccd_cfg(i_ccd_cfg'length - 1 downto 8) <= (others=>'0');
process(i_ccd_vclk)
begin
  if rising_edge(i_ccd_vclk) then
    if i_ccd_vs = '1' then
      i_ccd_fps <= i_ccd_cfg(3 downto 0);
    end if;
  end if;
end process;

i_ccd_syn_h <= CONV_STD_LOGIC_VECTOR(1969, i_ccd_syn_h'length) when i_ccd_fps = CONV_STD_LOGIC_VECTOR(0, i_ccd_fps'length) else
               CONV_STD_LOGIC_VECTOR( 919, i_ccd_syn_h'length) when i_ccd_fps = CONV_STD_LOGIC_VECTOR(1, i_ccd_fps'length) else
               CONV_STD_LOGIC_VECTOR( 394, i_ccd_syn_h'length) when i_ccd_fps = CONV_STD_LOGIC_VECTOR(2, i_ccd_fps'length) else
               CONV_STD_LOGIC_VECTOR( 132, i_ccd_syn_h'length) when i_ccd_fps = CONV_STD_LOGIC_VECTOR(3, i_ccd_fps'length) else
               CONV_STD_LOGIC_VECTOR( 5, i_ccd_syn_h'length);-- when i_ccd_fps = CONV_STD_LOGIC_VECTOR(4, i_ccd_fps'length) else
i_ccd_syn_v <= i_ccd_syn_h;

m_vfr_gen : vfr_gen
generic map(
G_VD_WIDTH => C_PCFG_CCD_DWIDTH,
G_VSYN_ACTIVE => '1'
)
port map(
--CFG
p_in_cfg      => i_ccd_cfg,
p_in_vpix     => i_ccd_vpix,
p_in_vrow     => i_ccd_vrow,
p_in_syn_h    => i_ccd_syn_h,
p_in_syn_v    => i_ccd_syn_v,

--Test Video
p_out_vd      => i_ccd_vd,
p_out_vs      => i_ccd_vs,
p_out_hs      => i_ccd_hs,
p_out_vclk    => open,
p_out_vclk_en => i_ccd_vclk_en,

--Технологический
p_in_tst      => (others=>'0'),
p_out_tst     => i_ccd_tst_out,

--System
p_in_clk      => i_ccd_vclk,
p_in_rst      => i_swt_rst
);

pin_out_TP(7 downto 1) <= (others=>'0');
pin_out_TP(0) <= OR_reduce(i_tmr_hirq) or OR_reduce(i_tmr_en);


end architecture;
