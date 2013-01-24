-------------------------------------------------------------------------
-- Company     : Linkos
-- Engineer    : Golovachenko Victor
--
-- Create Date : 21.01.2012 12:31:12
-- Module Name : hscam_pcie_tb
--
-- Назначение/Описание :
--
-- Revision:
-- Revision 0.01 - File Created
-------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_arith.all;

library unisim;
use unisim.vcomponents.all;

library work;
use work.vicg_common_pkg.all;
use work.prj_cfg.all;
use work.prj_def.all;
use work.hscam_pkg.all;
use work.cfgdev_pkg.all;
--use work.mem_ctrl_pkg.all;
use work.mem_wr_pkg.all;
use work.dsn_video_ctrl_pkg.all;
use work.pcie_pkg.all;
use work.clocks_pkg.all;


entity hscam_pcie_tb is
generic(
G_SIM    : string:="ON"
);
--port(
--i_ccd_vd      : out  std_logic_vector(80 - 1 downto 0);
--i_ccd_vs      : out  std_logic;
--i_ccd_hs      : out  std_logic;
--i_ccd_vclk_en : out  std_logic
--);
end hscam_pcie_tb;

architecture behavioral of hscam_pcie_tb is

component clocks
port(
p_out_rst  : out   std_logic;
p_out_gclk : out   std_logic_vector(7 downto 0);

p_in_clkopt: in    std_logic_vector(3 downto 0);
p_in_clk   : in    TRefClkPinIN
);
end component;

constant C5_CLK_PERIOD_NS   : real := 6600.0 / 1000.0; --constant C5_CLK_PERIOD_NS   : real := 3200.0 / 1000.0;
constant C5_TCYC_SYS        : real := C5_CLK_PERIOD_NS/2.0;
constant C5_TCYC_SYS_DIV2   : time := C5_TCYC_SYS * 1 ns;

signal i_rst                 : std_logic;
signal p_in_rst              : std_logic;
signal p_in_clk              : std_logic := '0';

signal pin_in_refclk         : TRefClkPinIN;

signal i_usrclk_rst                     : std_logic;
signal g_usrclk                         : std_logic_vector(7 downto 0);
signal g_usr_highclk                    : std_logic;
signal g_refclkopt                      : std_logic_vector(3 downto 0);

signal i_ccd_vd                         : std_logic_vector(C_PCFG_VBUF_IWIDTH-1 downto 0);
signal i_ccd_vs                         : std_logic;
signal i_ccd_hs                         : std_logic;
signal i_ccd_vclk_en                    : std_logic;
signal i_ccd_vclk                       : std_logic;
signal i_ccd_cfg                       : std_logic_vector(15 downto 0);
signal i_ccd_vpix                       : std_logic_vector(15 downto 0);
signal i_ccd_vrow                       : std_logic_vector(15 downto 0);
signal i_ccd_syn                        : std_logic_vector(15 downto 0);
signal i_ccd_dconvert_clk               : std_logic;
signal i_ccd_tst_out                    : std_logic_vector(31 downto 0);


signal i_pll_rst_out                    : std_logic;
signal g_pll_clkin                      : std_logic;
signal g_pll_mem_clk                    : std_logic;
signal g_pll_tmr_clk                    : std_logic;
--signal i_usrclk_rst                     : std_logic;
--signal g_usrclk                         : std_logic_vector(7 downto 0);
--signal g_usr_highclk                    : std_logic;
--signal g_refclkopt                      : std_logic_vector(3 downto 0);
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
--signal i_vctrl_vbufin_pfull             : std_logic;
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
signal i_vctrl_tst_out,i_vctrl_tst_in                  : std_logic_vector(31 downto 0);
signal i_vctrlwr_memin                  : TMemIN;
signal i_vctrlwr_memout                 : TMemOUT;
signal i_vctrlrd_memin                  : TMemIN;
signal i_vctrlrd_memout                 : TMemOUT;



--MAIN
begin

-- ========================================================================== --
-- Clocks Generation                                                          --
-- ========================================================================== --
process
begin
  p_in_clk <= not p_in_clk;
  wait for (C5_TCYC_SYS_DIV2);
end process;


pin_in_refclk.clk_p <= not p_in_clk;
pin_in_refclk.clk_n <=     p_in_clk;
pin_in_refclk.pciexp_clk_p <= not p_in_clk;
pin_in_refclk.pciexp_clk_n <=     p_in_clk;

-- ========================================================================== --
-- Reset Generation                                                           --
-- ========================================================================== --
process
begin
  i_rst <= '1';
  wait for 3 us;--200 ns;
  i_rst <= '0';
  wait;
end process;

i_swt_rst <= i_rst;
i_vctrl_rst <= i_rst;



--***********************************************************
--Установка частот проекта:
--***********************************************************
m_clocks : clocks
port map(
p_out_rst  => i_usrclk_rst,
p_out_gclk => g_usrclk,

p_in_clkopt=> (others=>'0'),--g_refclkopt,
p_in_clk   => pin_in_refclk
);

g_host_clk <= g_usrclk(0);
g_usr_highclk <= g_usrclk(1);

i_ccd_vclk <= g_usrclk(5);
i_ccd_dconvert_clk <= g_usrclk(6);--частота конвертирования данных 80bit -> 32bit


--//#########################################
--//Генератор видеопотока
--//#########################################
i_ccd_vpix <= CONV_STD_LOGIC_VECTOR(960/(C_PCFG_VBUF_IWIDTH/8), i_ccd_vpix'length);
i_ccd_vrow <= CONV_STD_LOGIC_VECTOR(4, i_ccd_vrow'length);
i_ccd_syn  <= CONV_STD_LOGIC_VECTOR(5, i_ccd_syn'length);

i_ccd_cfg(2 downto 0) <= (others=>'0');
i_ccd_cfg(i_ccd_cfg'length - 1 downto 3) <= (others=>'0');

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
p_in_syn_h    => i_ccd_syn,
p_in_syn_v    => i_ccd_syn,

--Test Video
p_out_vd      => i_ccd_vd,
p_out_vs      => i_ccd_vs,
p_out_hs      => i_ccd_hs,
p_out_vclk    => open,--
p_out_vclk_en => i_ccd_vclk_en,

--Технологический
p_in_tst      => (others=>'0'),
p_out_tst     => i_ccd_tst_out,

--System
p_in_clk      => i_ccd_vclk,
p_in_rst      => i_rst
);


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
p_in_vctrl_clk            => g_vctrl_swt_bufclk,

p_out_vctrl_vbufin_dout   => i_vctrl_vbufin_dout,
p_in_vctrl_vbufin_rd      => i_vctrl_vbufin_rd,
p_out_vctrl_vbufin_empty  => i_vctrl_vbufin_empty,
p_out_vctrl_vbufin_full   => i_vctrl_vbufin_full,

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

p_in_convert_clk   => i_ccd_dconvert_clk,--частота конвертирования данных 80bit -> 32bit

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
--i_vctrl_hirq_out<=EXT(i_vctrl_hirq, i_vctrl_hirq_out'length);
--i_vctrl_hrdy_out<=EXT(i_vctrl_hrdy, i_vctrl_hrdy_out'length);

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
p_out_vctrl_hirq     => open,--i_vctrl_hirq,
p_out_vctrl_hdrdy    => open,--i_vctrl_hrdy,
p_out_vctrl_hfrmrk   => open,--i_vctrl_hfrmrk,

-------------------------------
-- Связь с буферами модуля dsn_switch.vhd
-------------------------------
p_out_vbuf_clk       => g_vctrl_swt_bufclk,

p_in_vbufin_rdy      => '1',--i_vctrl_vbufin_rdy,
p_in_vbufin_dout     => i_vctrl_vbufin_dout,
p_out_vbufin_dout_rd => i_vctrl_vbufin_rd,
p_in_vbufin_empty    => i_vctrl_vbufin_empty,
p_in_vbufin_full     => i_vctrl_vbufin_full,
p_in_vbufin_pfull    => '0',--i_vctrl_vbufin_pfull,

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

i_vctrlwr_memout.req_en <= '1';
i_vctrlwr_memout.buf_wpf <= '0';
i_vctrlwr_memout.buf_re <= '1';

i_vctrl_tst_in(0) <= i_ccd_vs;

--END MAIN
end behavioral;

