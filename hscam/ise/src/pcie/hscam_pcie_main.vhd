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
pin_out_pciexp_txp  : out   std_logic_vector(C_PCGF_PCIE_LINK_WIDTH-1 downto 0);
pin_out_pciexp_txn  : out   std_logic_vector(C_PCGF_PCIE_LINK_WIDTH-1 downto 0);
pin_in_pciexp_rxp   : in    std_logic_vector(C_PCGF_PCIE_LINK_WIDTH-1 downto 0);
pin_in_pciexp_rxn   : in    std_logic_vector(C_PCGF_PCIE_LINK_WIDTH-1 downto 0);
pin_in_pciexp_rstn  : in    std_logic;

--------------------------------------------------
--Reference clock
--------------------------------------------------
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
signal i_usrclk5_div                    : std_logic_vector(6 downto 0):=(others=>'0');

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

Type THostDCtrl is array (0 to C_HDEV_VCH_DBUF) of std_logic;
Type THostDWR is array (0 to C_HDEV_VCH_DBUF) of std_logic_vector(i_host_dev_txd'range);
signal i_host_wr                        : THostDCtrl;
signal i_host_rd                        : THostDCtrl;
signal i_host_txd                       : THostDWR;
signal i_host_rxd                       : THostDWR;
signal i_host_rxrdy                     : THostDCtrl;
signal i_host_txrdy                     : THostDCtrl;
signal i_host_rxbuf_empty               : THostDCtrl;
signal i_host_txbuf_full                : THostDCtrl;
signal i_host_irq                       : std_logic_vector(C_HIRQ_COUNT_MAX-1 downto 0);
--signal i_host_txd_rdy                   : THostDCtrl;
--signal i_host_rxerr                    : THostDCtrl;

signal i_host_rst_all                   : std_logic;
--signal i_host_rst_eth                   : std_logic;
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
signal i_swt_tst_out,i_swt_tst_in       : std_logic_vector(31 downto 0);

signal i_tmr_clk                        : std_logic;

signal i_vctrl_rst                      : std_logic;
signal hclk_hrddone_vctrl_cnt           : std_logic_vector(2 downto 0);
signal hclk_hrddone_vctrl               : std_logic;
--signal i_vctrl_vbufin_rdy               : std_logic;
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
--signal i_vctrl_hfrmrk                   : std_logic_vector(31 downto 0);
signal i_vctrl_vrd_done                 : std_logic;
signal i_vctrl_tst_out                  : std_logic_vector(31 downto 0);
signal i_vctrl_tst_in                   : std_logic_vector(31 downto 0);
signal i_vctrlwr_memin                  : TMemIN;
signal i_vctrlwr_memout                 : TMemOUT;
signal i_vctrlrd_memin                  : TMemIN;
signal i_vctrlrd_memout                 : TMemOUT;

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

signal i_ccd_vd                         : std_logic_vector(C_PCFG_VBUF_IWIDTH-1 downto 0);
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


signal tst_vbufin_dout                  : std_logic_vector(31 downto 0);
signal tst_vbufin_dout_rd               : std_logic;
signal tst_vbufin_empty                 : std_logic;
signal tst_vbufin_full                  : std_logic;

signal tst_rst_vctrl_bufs               : std_logic;
signal tst_swt_tst_out                  : std_logic_vector(31 downto 0);

signal sr_ccd_vs                        : std_logic_vector(1 downto 0);
signal i_ccd_vs_m                       : std_logic;

attribute keep : string;
attribute keep of g_host_clk : signal is "true";
attribute keep of g_usr_highclk : signal is "true";
attribute keep of g_usrclk : signal is "true";

signal i_test01_led     : std_logic;
signal tst_clr          : std_logic;


--//MAIN
begin


--***********************************************************
--//RESET модулей
--***********************************************************
i_host_rst_n <=pin_in_pciexp_rstn;

i_cfg_rst    <=not i_host_rst_n or i_host_rst_all or i_usrclk_rst;
i_vctrl_rst  <=not OR_reduce(i_mem_ctrl_status.rdy) or i_usrclk_rst;
i_swt_rst    <=not i_host_rst_n or i_host_rst_all or i_usrclk_rst;
i_host_mem_rst<=not OR_reduce(i_mem_ctrl_status.rdy);
i_mem_ctrl_sysin.rst<=not i_host_rst_n or i_host_rst_all or i_pll_rst_out;
i_arb_mem_rst<=not OR_reduce(i_mem_ctrl_status.rdy);


--***********************************************************
--Установка частот проекта:
--***********************************************************
m_clocks : clocks
port map(
p_out_rst  => i_usrclk_rst,
p_out_gclk => g_usrclk,

p_in_clkopt=> g_refclkopt,
p_in_clk   => pin_in_refclk
);


g_usr_highclk<=i_mem_ctrl_sysout.clk;

i_mem_ctrl_sysin.ref_clk<=g_usrclk(0);
i_mem_ctrl_sysin.clk<=g_usrclk(1);

i_pciexp_gt_refclk <= g_usrclk(3);

i_ccd_vclk <= g_usrclk(5);--pixclk
i_ccd_d80_d32_clk <= g_usrclk(6);--частота конвертирования данных 80bit -> 32bit


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
i_cfg_rxd <= i_cfg_rxd_dev(C_CFGDEV_SWT)     when i_cfg_dadr(3 downto 0)=CONV_STD_LOGIC_VECTOR(C_CFGDEV_SWT, 4)     else
             i_cfg_rxd_dev(C_CFGDEV_VCTRL)   when i_cfg_dadr(3 downto 0)=CONV_STD_LOGIC_VECTOR(C_CFGDEV_VCTRL, 4)   else
             (others=>'0');

gen_cfg_dev : for i in C_CFGDEV_SWT to C_CFGDEV_VCTRL generate
i_cfg_wr_dev(i)   <=i_cfg_wr   when i_cfg_dadr=i else '0';
i_cfg_rd_dev(i)   <=i_cfg_rd   when i_cfg_dadr=i else '0';
i_cfg_done_dev(i) <=i_cfg_done when i_cfg_dadr=i else '0';
end generate gen_cfg_dev;


--***********************************************************
--Проект модуля Комутатор
--***********************************************************
m_swt : dsn_switch
generic map(
G_VBUF_IWIDTH => C_PCFG_VBUF_IWIDTH,
G_VBUF_OWIDTH => C_PCFG_VBUF_OWIDTH
)
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

-- Связь Хост <-> VideoBUF
p_out_host_vbuf_dout      => i_host_rxd(C_HDEV_VCH_DBUF),
p_in_host_vbuf_rd         => i_host_rd(C_HDEV_VCH_DBUF),
p_out_host_vbuf_empty     => i_host_rxbuf_empty(C_HDEV_VCH_DBUF),

-------------------------------
-- Связь с VCTRL(dsn_video_ctrl.vhd) (vctrl_clk domain)
-------------------------------
p_in_vctrl_clk            => g_usr_highclk,--g_vctrl_swt_bufclk,

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
--Связь с ImageSensor
-------------------------------
p_in_vd            => i_ccd_vd,
p_in_vs            => i_ccd_vs,
p_in_hs            => i_ccd_hs,
p_in_vclk          => i_ccd_vclk,
p_in_vclk_en       => i_ccd_vclk_en,
p_in_ext_syn       => '0',

p_in_convert_clk   => i_ccd_d80_d32_clk,

-------------------------------
--Технологический
-------------------------------
p_in_tst           => (others => '0'),
p_out_tst          => i_swt_tst_out,

-------------------------------
--System
-------------------------------
p_in_rst => i_swt_rst
);


--***********************************************************
--Проект модуля видео контролера - dsn_video_ctrl.vhd
--***********************************************************
i_vctrl_hirq_out<=EXT(i_vctrl_hirq, i_vctrl_hirq_out'length);
i_vctrl_hrdy_out<=EXT(i_vctrl_hrdy, i_vctrl_hrdy_out'length);

m_vctrl : dsn_video_ctrl
generic map(
G_DBGCS  => "ON",
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
--p_out_vctrl_hfrmrk   => i_vctrl_hfrmrk,

-------------------------------
-- Связь с буферами модуля dsn_switch.vhd
-------------------------------
p_out_vbuf_clk       => g_vctrl_swt_bufclk,

p_in_vbufin_rdy      => '1',--i_vctrl_vbufin_rdy,
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
p_in_tst             => i_vctrl_tst_in,

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
i_host_tst_in(76)<=OR_reduce(tst_vbufin_dout) or tst_vbufin_dout_rd or tst_vbufin_empty or tst_vbufin_full or tst_rst_vctrl_bufs;
i_host_tst_in(126 downto 77)<=(others=>'0');
i_host_tst_in(127)<=i_vctrl_tst_out(0) or OR_reduce(tst_swt_tst_out(4 downto 0)) or OR_reduce(i_ccd_tst_out);




--//Статусы устройств
i_host_dev_status(C_HREG_DEV_STATUS_CFG_RDY_BIT)    <=i_cfg_rdy;
i_host_dev_status(C_HREG_DEV_STATUS_CFG_RXRDY_BIT)  <=i_host_rxrdy(C_HDEV_CFG_DBUF);
i_host_dev_status(C_HREG_DEV_STATUS_CFG_TXRDY_BIT)  <=i_host_txrdy(C_HDEV_CFG_DBUF);

i_host_dev_status(C_HREG_DEV_STATUS_ETH_RDY_BIT)    <='1';
i_host_dev_status(C_HREG_DEV_STATUS_ETH_LINK_BIT)   <='0';
i_host_dev_status(C_HREG_DEV_STATUS_ETH_RXRDY_BIT)  <='0';
i_host_dev_status(C_HREG_DEV_STATUS_ETH_TXRDY_BIT)  <='0';

gen_status_vch : for i in 0 to C_VCTRL_VCH_COUNT_MAX-1 generate
i_host_dev_status(C_HREG_DEV_STATUS_VCH0_FRRDY_BIT + i)<=i_vctrl_hrdy_out(i);
end generate gen_status_vch;

i_host_dev_status(C_HREG_DEV_STATUS_MEMCTRL_RDY_BIT)<=OR_reduce(i_mem_ctrl_status.rdy);

--//Запись/Чтение данных устройств хоста
gen_dev_dbuf : for i in 0 to i_host_wr'length-1 generate
i_host_wr(i) <=i_host_dev_wr when i_host_devadr=CONV_STD_LOGIC_VECTOR(i, i_host_devadr'length) else '0';
i_host_rd(i) <=i_host_dev_rd when i_host_devadr=CONV_STD_LOGIC_VECTOR(i, i_host_devadr'length) else '0';
i_host_txd(i)<=i_host_dev_txd;
end generate gen_dev_dbuf;

i_host_dev_rxd<=i_host_rxd(C_HDEV_CFG_DBUF) when i_host_devadr=CONV_STD_LOGIC_VECTOR(C_HDEV_CFG_DBUF, i_host_devadr'length) else
                i_host_rxd(C_HDEV_VCH_DBUF) when i_host_devadr=CONV_STD_LOGIC_VECTOR(C_HDEV_VCH_DBUF, i_host_devadr'length) else
                i_host_rxd(C_HDEV_MEM_DBUF) when i_host_devadr=CONV_STD_LOGIC_VECTOR(C_HDEV_MEM_DBUF, i_host_devadr'length) else
                (others=>'0');


--//Флаги (Host<-dev)
i_host_dev_opt_in(C_HDEV_OPTIN_TXFIFO_PFULL_BIT)<=i_host_txbuf_full(C_HDEV_MEM_DBUF) when i_host_devadr=CONV_STD_LOGIC_VECTOR(C_HDEV_MEM_DBUF, i_host_devadr'length) else
                                                  '0';

i_host_dev_opt_in(C_HDEV_OPTIN_RXFIFO_EMPTY_BIT)<=i_host_rxbuf_empty(C_HDEV_VCH_DBUF) when i_host_devadr=CONV_STD_LOGIC_VECTOR(C_HDEV_VCH_DBUF, i_host_devadr'length) else
                                                  i_host_rxbuf_empty(C_HDEV_MEM_DBUF) when i_host_devadr=CONV_STD_LOGIC_VECTOR(C_HDEV_MEM_DBUF, i_host_devadr'length) else
                                                  '0';

i_host_dev_opt_in(C_HDEV_OPTIN_MEMTRN_DONE_BIT)<=i_host_mem_status.done;
i_host_dev_opt_in(C_HDEV_OPTIN_VCTRL_FRSKIP_M_BIT downto C_HDEV_OPTIN_VCTRL_FRSKIP_L_BIT)<=i_vctrl_tst_out(23 downto 16);


--//Прерывания
i_host_dev_irq(C_HIRQ_CFG_RX)<=i_host_irq(C_HIRQ_CFG_RX);
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

--//Арбитр контроллера памяти
m_mem_arb : mem_arb
generic map(
G_CH_COUNT   => 3,
G_MEM_AWIDTH => C_AXI_AWIDTH,
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


--//#########################################
--//Генератор видеопотока
--//#########################################
i_ccd_vpix <= CONV_STD_LOGIC_VECTOR(1280/(C_PCFG_VBUF_IWIDTH/8), i_ccd_vpix'length);
i_ccd_vrow <= CONV_STD_LOGIC_VECTOR(1024, i_ccd_vrow'length);

i_ccd_cfg(2 downto 0) <= i_host_tst_out(2 downto 0); --0/1/2/3/4 - 30fps/60fps/120fps/240fps/480fps/
i_ccd_cfg(i_ccd_cfg'length - 1 downto 3) <= (others=>'0');

i_ccd_syn_h <= CONV_STD_LOGIC_VECTOR(1969, i_ccd_syn_h'length) when i_ccd_cfg(2 downto 0) = "000" else
               CONV_STD_LOGIC_VECTOR( 919, i_ccd_syn_h'length) when i_ccd_cfg(2 downto 0) = "001" else
               CONV_STD_LOGIC_VECTOR( 394, i_ccd_syn_h'length) when i_ccd_cfg(2 downto 0) = "010" else
               CONV_STD_LOGIC_VECTOR( 132, i_ccd_syn_h'length) when i_ccd_cfg(2 downto 0) = "011" else
               CONV_STD_LOGIC_VECTOR( 5, i_ccd_syn_h'length);-- when i_ccd_cfg(2 downto 0) = "011" else
i_ccd_syn_v <= i_ccd_syn_h;

m_vfr_gen : vfr_gen
generic map(
G_VD_WIDTH => C_PCFG_VBUF_IWIDTH,
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
p_in_rst      => i_host_rst_all
);


--//#########################################
--//DBG
--//#########################################
pin_out_led(0)<=i_test01_led;
pin_out_led(1)<=tst_vbufin_full;
pin_out_led(2)<='0';
pin_out_led(3)<='0';
pin_out_led(4)<='0';
pin_out_led(5)<='0';
pin_out_led(6)<='0';
pin_out_led(7)<='0';

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


process(g_usr_highclk)
begin
  if rising_edge(g_usr_highclk) then
  tst_vbufin_dout    <= i_vctrl_vbufin_dout ;
  tst_vbufin_dout_rd <= i_vctrl_vbufin_rd   ;
  tst_vbufin_empty   <= i_vctrl_vbufin_empty;
  tst_vbufin_full    <= i_vctrl_vbufin_full ;

  tst_rst_vctrl_bufs <= i_swt_tst_out(0);
  tst_swt_tst_out <= i_swt_tst_out;
  end if;
end process;

pin_out_TP(0) <= '0';
pin_out_TP(1) <= i_ccd_vs_m;
pin_out_TP(2) <= i_ccd_hs;
pin_out_TP(3) <= '0';
pin_out_TP(4) <= '0';
pin_out_TP(5) <= '0';
pin_out_TP(6) <= '0';
pin_out_TP(7) <= '0';


process(i_ccd_vclk)
begin
  if rising_edge(i_ccd_vclk) then
    sr_ccd_vs(0) <= i_ccd_vs;
    sr_ccd_vs(1) <= sr_ccd_vs(0);

    if sr_ccd_vs(1) = '0' and sr_ccd_vs(0) = '1' then
      i_ccd_vs_m <= not i_ccd_vs_m;
    end if;
  end if;
end process;

i_vctrl_tst_in(0) <= i_ccd_vs;
i_vctrl_tst_in(31 downto 1) <= (others=>'0');

end architecture;
