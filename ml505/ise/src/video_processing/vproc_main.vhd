-------------------------------------------------------------------------
-- Company     : Linkos
-- Engineer    : Golovachenko Victor
--
-- Create Date : 14.02.2013 17:55:29
-- Module Name : vproc_main
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
use work.eth_phypin_pkg.all;
use work.eth_pkg.all;
use work.dsn_eth_pkg.all;
use work.clocks_pkg.all;
use work.cfgdev_pkg.all;
use work.mem_ctrl_pkg.all;
use work.mem_wr_pkg.all;
use work.dsn_video_ctrl_pkg.all;

entity vproc_main is
generic(
G_SIM      : string:="OFF"
);
port(
--------------------------------------------------
--DVI
--------------------------------------------------
pin_inout_dvi_sda: inout std_logic;
pin_inout_dvi_scl: inout std_logic;
pin_out_dvi_clk  : out   std_logic_vector(1 downto 0);
pin_out_dvi_d    : out   std_logic_vector(11 downto 0);
pin_out_dvi_de   : out   std_logic;
pin_out_dvi_hs   : out   std_logic;
pin_out_dvi_vs   : out   std_logic;

--------------------------------------------------
--Технологический порт
--------------------------------------------------
pin_out_led         : out   std_logic_vector(7 downto 0);
pin_in_btn_N        : in    std_logic;
pin_out_TP          : out   std_logic_vector(2 downto 0);

--------------------------------------------------
--Memory banks
--------------------------------------------------
pin_out_phymem      : out   TMEMCTRL_phy_outs;
pin_inout_phymem    : inout TMEMCTRL_phy_inouts;

--------------------------------------------------
--ETH
--------------------------------------------------
pin_out_ethphy    : out   TEthPhyPinOUT;
pin_in_ethphy     : in    TEthPhyPinIN;
pin_inout_ethphy_mdio : inout std_logic;
pin_out_ethphy_mdc    : out   std_logic;
pin_out_ethphy_rst    : out   std_logic;

--------------------------------------------------
--Reference clock
--------------------------------------------------
pin_in_refclk       : in    TRefClkPinIN
);
end entity;

architecture struct of vproc_main is

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

component eth_bram_prm
port(
p_out_cfg_adr      : out  std_logic_vector(7 downto 0);
p_out_cfg_adr_ld   : out  std_logic;
p_out_cfg_adr_fifo : out  std_logic;

p_out_cfg_txdata   : out  std_logic_vector(15 downto 0);
p_out_cfg_wr       : out  std_logic;

p_in_clk  : in  std_logic;
p_in_rst  : in  std_logic
);
end component;

component eth_gt_clkbuf is
port(
p_in_ethphy : in    TEthPhyPinIN;
p_out_clk   : out   std_logic_vector(1 downto 0)
);
end component;

component ethg_vctrl_rxfifo
port(
din         : in  std_logic_vector(31 downto 0);
wr_en       : in  std_logic;
wr_clk      : in  std_logic;

dout        : out std_logic_vector(31 downto 0);
rd_en       : in  std_logic;
rd_clk      : in  std_logic;

empty       : out std_logic;
full        : out std_logic;
prog_full   : out std_logic;

rst         : in  std_logic
);
end component;

component host_vbuf
port(
din         : in  std_logic_vector(31 downto 0);
wr_en       : in  std_logic;
wr_clk      : in  std_logic;

dout        : out std_logic_vector(31 downto 0);
rd_en       : in  std_logic;
rd_clk      : in  std_logic;

empty       : out std_logic;
full        : out std_logic;
prog_full   : out std_logic;

rst         : in  std_logic
);
end component;

component dvi_ctrl
generic(
G_DBG : string := "OFF";
G_SIM : string := "OFF"
);
port(
p_out_err     : out   std_logic;

--VIN
p_in_vdi      : in    std_logic_vector(31 downto 0);
p_out_vdi_rd  : out   std_logic;
p_out_vdi_clk : out   std_logic;

--VOUT
p_out_clk     : out   std_logic_vector(1 downto 0);
p_out_vd      : out   std_logic_vector(11 downto 0);
p_out_vde     : out   std_logic;
p_out_hs      : out   std_logic;
p_out_vs      : out   std_logic;

--I2C
p_inout_sda   : inout std_logic;
p_inout_scl   : inout std_logic;

--Технологический
p_in_tst      : in    std_logic_vector(31 downto 0);
p_out_tst     : out   std_logic_vector(31 downto 0);

--System
p_in_clk      : in    std_logic;
p_in_rst      : in    std_logic
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

--//--------------------------
--//Связь с модулем слежения
--//--------------------------
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
--//CH WRITE
p_out_memwr           : out TMemIN;
p_in_memwr            : in  TMemOUT;
--//CH READ
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

signal i_sys_rst_cnt                    : std_logic_vector(5 downto 0):=(others=>'0');
signal i_sys_rst                        : std_logic;
signal i_usr_rst                        : std_logic;
signal i_mnl_rst                        : std_logic;

signal i_usrclk_rst                     : std_logic;
signal g_usrclk                         : std_logic_vector(7 downto 0);
signal g_usr_highclk                    : std_logic;

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

signal i_eth_prm_rst                    : std_logic;
signal i_eth_prm_radr                   : std_logic_vector(7 downto 0);
signal i_eth_prm_radr_ld                : std_logic;
signal i_eth_prm_radr_fifo              : std_logic;
signal i_eth_prm_wr                     : std_logic;
signal i_eth_prm_txd                    : std_logic_vector(15 downto 0);

signal i_eth_gt_txp                     : std_logic_vector(1 downto 0);
signal i_eth_gt_txn                     : std_logic_vector(1 downto 0);
signal i_eth_gt_rxn                     : std_logic_vector(1 downto 0);
signal i_eth_gt_rxp                     : std_logic_vector(1 downto 0);
signal i_eth_gt_refclk125_in            : std_logic_vector(1 downto 0);

signal i_eth_out                        : TEthOUTs;
signal i_eth_in                         : TEthINs;
signal i_ethphy_out                     : TEthPhyOUT;
signal i_ethphy_in                      : TEthPhyIN;
signal dbg_eth_out                      : TEthDBG;
signal i_eth_tst_out                    : std_logic_vector(31 downto 0);

signal sr_eth_rxbuf_din                 : std_logic_vector(31 downto 0);
signal sr_eth_rxbuf_wr                  : std_logic;
signal sr_eth_rxbuf_sof                 : std_logic;
signal i_eth_pkt_type                   : std_logic_vector(3 downto 0);
signal i_eth_pkt_to                     : std_logic;

signal i_eth_fltr_do                    : std_logic_vector(31 downto 0);
signal i_eth_fltr_wr_cfg                : std_logic;
signal i_eth_fltr_wr_vctrl              : std_logic;

signal i_vctrl_vbufi_do                 : std_logic_vector(31 downto 0);
signal i_vctrl_vbufi_rd                 : std_logic;
signal i_vctrl_vbufi_empty              : std_logic;
signal i_vctrl_vbufi_pfull              : std_logic;
signal i_vctrl_vbufi_full               : std_logic;
signal i_vctrl_vbufo_di                 : std_logic_vector(31 downto 0);
signal i_vctrl_vbufo_wr                 : std_logic;
signal i_vctrl_vbufo_empty              : std_logic;
signal i_vctrl_vbufo_full               : std_logic;

signal i_vctrl_vchsel                   : std_logic_vector(3 downto 0);
signal i_vctrl_hrd_start                : std_logic;
signal i_vctrl_hrd_done                 : std_logic;
signal i_vctrl_tst_out                  : std_logic_vector(31 downto 0);
signal i_vctrlwr_memin                  : TMemIN;
signal i_vctrlwr_memout                 : TMemOUT;
signal i_vctrlrd_memin                  : TMemIN;
signal i_vctrlrd_memout                 : TMemOUT;

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

signal i_dvi_clk_in                     : std_logic;
signal i_dvi_di                         : std_logic_vector(31 downto 0);
signal i_dvi_vs                         : std_logic;
signal i_dvi_hs                         : std_logic;

attribute keep : string;
attribute keep of i_ethphy_out : signal is "true";
attribute keep of g_usr_highclk : signal is "true";

signal i_test01_led     : std_logic;
signal tst_reg_adr_cnt  : std_logic_vector(C_CFGPKT_RADR_M_BIT-C_CFGPKT_RADR_L_BIT downto 0);
Type TCfg_tstreg is array (0 to 0) of std_logic_vector(i_cfg_rxd'range);
signal tst_reg          : TCfg_tstreg;


--//MAIN
begin


--***********************************************************
--//RESET модулей
--***********************************************************
process(i_ethphy_out)
begin
  if rising_edge(i_ethphy_out.clk) then
    if i_sys_rst_cnt(i_sys_rst_cnt'high) = '0' then
      i_sys_rst_cnt <= i_sys_rst_cnt + 1;
    end if;
  end if;
end process;

i_sys_rst <= i_sys_rst_cnt(i_sys_rst_cnt'high - 1);

gen_ml505 : if strcmp(C_PCFG_BOARD,"ML505") generate
i_usr_rst <= pin_in_btn_N;
end generate gen_ml505;

gen_htgv6 : if strcmp(C_PCFG_BOARD,"HTGV6") generate
i_usr_rst <= not pin_in_btn_N;
end generate gen_htgv6;

i_mnl_rst <= i_sys_rst or i_usr_rst;


--***********************************************************
--Установка частот проекта:
--***********************************************************
m_clocks : clocks
port map(
p_out_rst  => i_usrclk_rst,
p_out_gclk => g_usrclk,

p_in_clkopt=> (others=>'0'),
p_in_clk   => pin_in_refclk
);

--g_usr_highclk <= g_usrclk(1);
g_usr_highclk <= i_mem_ctrl_sysout.clk;
i_mem_ctrl_sysin.ref_clk <= g_usrclk(0);
i_mem_ctrl_sysin.clk <= g_usrclk(1);

i_dvi_clk_in <= g_usrclk(2);


--***********************************************************
--Проект Ethernet - dsn_eth.vhd
--***********************************************************
ibuf_eth_gt_refclk : eth_gt_clkbuf
port map(
p_in_ethphy => pin_in_ethphy,
p_out_clk   => i_eth_gt_refclk125_in
);

pin_out_ethphy.sgmii.txp <= i_ethphy_out.pin.sgmii.txp;
pin_out_ethphy.sgmii.txn <= i_ethphy_out.pin.sgmii.txn;
i_ethphy_in.pin.sgmii.rxp <= pin_in_ethphy.sgmii.rxp;
i_ethphy_in.pin.sgmii.rxn <= pin_in_ethphy.sgmii.rxn;

i_ethphy_in.clk <= i_eth_gt_refclk125_in(0);

pin_out_ethphy_rst <= not i_ethphy_out.rst;
pin_inout_ethphy_mdio <= i_ethphy_out.mdio when i_ethphy_out.mdio_t = '1' else 'Z';
pin_out_ethphy_mdc <= i_ethphy_out.mdc;
i_ethphy_in.mdio <= pin_inout_ethphy_mdio;

i_eth_prm_rst <= not i_ethphy_out.rdy or i_mnl_rst;

--Модуль настройки параметров работы dsn_eth.vhd
m_eth_prm : eth_bram_prm
port map(
p_out_cfg_adr      => i_eth_prm_radr,
p_out_cfg_adr_ld   => i_eth_prm_radr_ld,
p_out_cfg_adr_fifo => i_eth_prm_radr_fifo,

p_out_cfg_txdata   => i_eth_prm_txd,
p_out_cfg_wr       => i_eth_prm_wr,

p_in_clk  => i_ethphy_out.clk,
p_in_rst  => i_eth_prm_rst
);

m_eth : dsn_eth
generic map(
G_ETH.gtch_count_max  => C_PCFG_ETH_GTCH_COUNT_MAX,
G_ETH.usrbuf_dwidth   => 32,
G_ETH.phy_dwidth      => 8,--C_PCFG_ETH_PHY_DWIDTH,
G_ETH.phy_select      => 0,--C_PCFG_ETH_PHY_SEL,
G_ETH.mac_length_swap => 0,--1/0 Поле Length/Type первый мл./ст. байт (0 - по стандарту!!! 1 - как в проекте Вереск)
G_MODULE_USE => C_PCFG_ETH_USE,
G_DBG        => C_PCFG_ETH_DBG,
G_SIM        => G_SIM
)
port map(
-------------------------------
--Конфигурирование
-------------------------------
p_in_cfg_clk      => i_ethphy_out.clk,

p_in_cfg_adr      => i_eth_prm_radr(7 downto 0),
p_in_cfg_adr_ld   => i_eth_prm_radr_ld,
p_in_cfg_adr_fifo => i_eth_prm_radr_fifo,

p_in_cfg_txdata   => i_eth_prm_txd,
p_in_cfg_wd       => i_eth_prm_wr,

p_out_cfg_rxdata  => open,
p_in_cfg_rd       => '0',

p_in_cfg_done     => '0',
p_in_cfg_rst      => i_sys_rst,

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
p_out_dbg         => dbg_eth_out,
p_in_tst          => i_eth_tst_out,
p_out_tst         => open,

-------------------------------
--System
-------------------------------
p_in_rst          => i_mnl_rst
);

i_eth_in(0).rxbuf.empty <= i_cfg_tst_out(28);-- <= i_rxbuf_empty;--//HOST->FPGA
i_eth_in(0).rxbuf.full  <= i_cfg_tst_out(29);-- <= i_rxbuf_full ;
i_eth_in(0).txbuf.empty <= i_cfg_tst_out(30);-- <= i_txbuf_empty;--//HOST<-FPGA
i_eth_in(0).txbuf.full  <= i_cfg_tst_out(31);-- <= i_txbuf_full ;


--***********************************************************
--Switcher. Анализирует принятый по Eth пакет и перенаправляет
--данные в модули CFG или VCTRL
--***********************************************************
process(i_mnl_rst, i_ethphy_out)
begin
  if i_mnl_rst = '1' then
    sr_eth_rxbuf_din <= (others=>'0');
    sr_eth_rxbuf_wr <= '0';
    sr_eth_rxbuf_sof <= '0';
    i_eth_pkt_to <= '0';

  elsif rising_edge(i_ethphy_out.clk) then

    sr_eth_rxbuf_din <= i_eth_out(0).rxbuf.din;
    sr_eth_rxbuf_wr <= i_eth_out(0).rxbuf.wr;
    sr_eth_rxbuf_sof <= i_eth_out(0).rxbuf.sof;

    if i_eth_out(0).rxbuf.sof = '1' and i_eth_out(0).rxbuf.wr = '1' then
      if i_eth_pkt_type = CONV_STD_LOGIC_VECTOR(16#A#, i_eth_pkt_type'length) then
        i_eth_pkt_to <= '1';
      else
        i_eth_pkt_to <= '0';
      end if;
    end if;

  end if;
end process;

i_eth_pkt_type <= i_eth_out(0).rxbuf.din(19 downto 16);

i_eth_fltr_do <= sr_eth_rxbuf_din;
i_eth_fltr_wr_cfg <= sr_eth_rxbuf_wr and i_eth_pkt_to;
i_eth_fltr_wr_vctrl <= sr_eth_rxbuf_wr and not i_eth_pkt_to;


--***********************************************************
--CFG (Настройка модуле проекта)
--Прием/Отправка по Eth пакетов cfg
--***********************************************************
m_cfg : cfgdev_host
generic map(
G_DBG => "ON",
G_HOST_DWIDTH => C_HDEV_DWIDTH
)
port map(
-------------------------------
--Связь с Хостом
-------------------------------
p_out_host_rxrdy     => open,
p_out_host_rxd       => i_eth_in(0).txbuf.dout,
p_in_host_rd         => i_eth_out(0).txbuf.rd,

p_out_host_txrdy     => open,
p_in_host_txd        => i_eth_fltr_do,
p_in_host_wr         => i_eth_fltr_wr_cfg,

p_out_host_irq       => open,
p_in_host_clk        => i_ethphy_out.clk,

-------------------------------
--
-------------------------------
p_out_module_rdy     => open,
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
p_in_cfg_clk         => g_usr_highclk,

-------------------------------
--Технологический
-------------------------------
p_in_tst             => (others=>'0'),
p_out_tst            => i_cfg_tst_out,

-------------------------------
--System
-------------------------------
p_in_rst => i_mnl_rst
);

--//Распределяем управление от блока конфигурирования(cfgdev.vhd):
i_cfg_rxd <= i_cfg_rxd_dev(C_CFGDEV_TESTING) when i_cfg_dadr(3 downto 0) = CONV_STD_LOGIC_VECTOR(C_CFGDEV_TESTING, 4)   else
             (others=>'0');

gen_cfg_dev : for i in 0 to C_CFGDEV_COUNT - 1 generate
i_cfg_wr_dev(i)   <= i_cfg_wr   when i_cfg_dadr = i else '0';
i_cfg_rd_dev(i)   <= i_cfg_rd   when i_cfg_dadr = i else '0';
i_cfg_done_dev(i) <= i_cfg_done when i_cfg_dadr = i else '0';
end generate gen_cfg_dev;



--***********************************************************
--Видео контролер.
--Формирование видео кадра из принимаемых по Eth видеопакетов
--***********************************************************
--//IBUF Eth -> VCTRL
m_vbufi : ethg_vctrl_rxfifo
port map(
din         => i_eth_fltr_do,
wr_en       => i_eth_fltr_wr_vctrl,
wr_clk      => i_ethphy_out.clk,

dout        => i_vctrl_vbufi_do,
rd_en       => i_vctrl_vbufi_rd,
rd_clk      => g_usr_highclk,

empty       => i_vctrl_vbufi_empty,
full        => i_vctrl_vbufi_full,
prog_full   => i_vctrl_vbufi_pfull,

rst         => i_mnl_rst
);

i_vctrl_vchsel <= (others=>'0');
i_vctrl_hrd_start <= not i_vctrl_vbufi_empty;

m_vctrl : dsn_video_ctrl
generic map(
G_ROTATE => "OFF",
G_ROTATE_BUF_COUNT => 16,
G_SIMPLE => "ON",
G_SIM    => G_SIM,

G_MEM_AWIDTH => C_VCTRL_REG_MEM_LAST_BIT,
G_MEM_DWIDTH => C_HDEV_DWIDTH
)
port map(
-------------------------------
-- Конфигурирование модуля dsn_video_ctrl.vhd (host_clk domain)
-------------------------------
p_in_host_clk        => g_usr_highclk,

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
p_in_vctrl_hrdchsel  => i_vctrl_vchsel,
p_in_vctrl_hrdstart  => i_vctrl_hrd_start,
p_in_vctrl_hrddone   => '0',--i_vctrl_hrd_done,
p_out_vctrl_hirq     => open,
p_out_vctrl_hdrdy    => open,
p_out_vctrl_hfrmrk   => open,

-------------------------------
-- STATUS модуля dsn_video_ctrl.vhd
-------------------------------
p_out_vctrl_modrdy   => open,
p_out_vctrl_moderr   => open,
p_out_vctrl_rd_done  => open,

p_out_vctrl_vrdprm   => open,
p_out_vctrl_vfrrdy   => open,
p_out_vctrl_vrowmrk  => open,

-------------------------------
-- Связь с модулем слежения
-------------------------------
p_in_trc_busy        => (others=>'0'),
p_out_trc_vbuf       => open,

-------------------------------
-- Связь с буферами модуля dsn_switch.vhd
-------------------------------
p_out_vbuf_clk       => open,

p_in_vbufin_rdy      => '1',
p_in_vbufin_dout     => i_vctrl_vbufi_do,
p_out_vbufin_dout_rd => i_vctrl_vbufi_rd,
p_in_vbufin_empty    => i_vctrl_vbufi_empty,
p_in_vbufin_full     => i_vctrl_vbufi_full,
p_in_vbufin_pfull    => i_vctrl_vbufi_pfull,

p_out_vbufout_din    => i_vctrl_vbufo_di,
p_out_vbufout_din_wd => i_vctrl_vbufo_wr,
p_in_vbufout_empty   => i_vctrl_vbufo_empty,
p_in_vbufout_full    => i_vctrl_vbufo_full,

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
p_in_rst => i_mnl_rst
);


--***********************************************************
--Контроллер ОЗУ
--***********************************************************
--//Подключаем устройства к арбитру ОЗУ
i_memin_ch(0)    <= i_vctrlwr_memin;
i_vctrlwr_memout <= i_memout_ch(0);

i_memin_ch(1)    <= i_vctrlrd_memin;
i_vctrlrd_memout <= i_memout_ch(1);

--i_memin_ch(2) <= i_host_memin;
--i_host_memout <= i_memout_ch(2);

--//Арбитр контроллера памяти
m_mem_arb : mem_arb
generic map(
G_CH_COUNT   => 2,
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
p_out_tst   => open,

-------------------------------
--System
-------------------------------
p_in_clk    => g_usr_highclk,
p_in_rst    => i_mnl_rst
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
--DVI
--Выдаем данные VCTRL на монитор
--***********************************************************
--//Выходной буфер модуля dsn_video_ctrl.vhd
m_vctrl_bufo : host_vbuf
port map(
din         => i_vctrl_vbufo_di,
wr_en       => i_vctrl_vbufo_wr,
wr_clk      => g_usr_highclk,

dout        => i_dvi_di,
rd_en       => i_dvi_vs,
rd_clk      => g_usr_highclk,

empty       => i_vctrl_vbufo_empty,
full        => open,
prog_full   => i_vctrl_vbufo_full,

rst         => i_mnl_rst
);

pin_out_dvi_hs <= i_dvi_hs;
pin_out_dvi_vs <= i_dvi_vs;

m_dvi : dvi_ctrl
generic map(
G_DBG => "OFF",
G_SIM => "OFF"
)
port map(
p_out_err     => open,--i_dvi_ctrl_err,

--VIN
p_in_vdi      => (others=>'0'),
p_out_vdi_rd  => open,
p_out_vdi_clk => open,

--VOUT
p_out_clk     => pin_out_dvi_clk,
p_out_vd      => pin_out_dvi_d  ,
p_out_vde     => pin_out_dvi_de ,
p_out_hs      => i_dvi_hs ,
p_out_vs      => i_dvi_vs ,

--I2C
p_inout_sda   => pin_inout_dvi_sda,
p_inout_scl   => pin_inout_dvi_scl,

--Технологический
p_in_tst      => (others=>'0'),
p_out_tst     => open,--tst_div_ctrl_out,

--System
p_in_clk      => i_dvi_clk_in,
p_in_rst      => i_mnl_rst
);



--//#########################################
--//DBG
--//#########################################
pin_out_led(0)<=OR_reduce(i_dvi_di);
pin_out_led(1)<=OR_reduce(dbg_eth_out.app(0).mac_rx) or OR_reduce(dbg_eth_out.app(0).mac_tx) or i_cfg_tst_out(0);
pin_out_led(2)<='0';
pin_out_led(3)<=dbg_eth_out.app(0).mac_rx(1);--i_dhcp_done

pin_out_led(4)<= '0';
pin_out_led(5)<= not i_ethphy_out.rdy;--read bad ID from ETHPHY
pin_out_led(6)<= i_ethphy_out.link;
pin_out_led(7)<= i_test01_led;

pin_out_TP <= (others=>'0'); --зарезервировано для ML505/mem

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
p_in_clk       => i_ethphy_out.clk,
p_in_rst       => i_mnl_rst
);


--***********************************************************
--Firmware + Test Register
--***********************************************************
--//Счетчик адреса регистров
process(i_mnl_rst, g_usr_highclk)
begin
  if i_mnl_rst = '1' then
    tst_reg_adr_cnt <= (others=>'0');
  elsif rising_edge(g_usr_highclk) then
    if i_cfg_radr_ld = '1' then
      tst_reg_adr_cnt <= i_cfg_radr;
    else
      if i_cfg_radr_fifo = '0' and (i_cfg_wr_dev(C_CFGDEV_TESTING) = '1' or i_cfg_rd_dev(C_CFGDEV_TESTING) = '1') then
        tst_reg_adr_cnt <= tst_reg_adr_cnt + 1;
      end if;
    end if;
  end if;
end process;

--//Запись регистров
process(i_mnl_rst, g_usr_highclk)
begin
  if i_mnl_rst = '1' then
    for i in 0 to 0 loop
      tst_reg(i) <= (others=>'0');
    end loop;
  elsif rising_edge(g_usr_highclk) then
    if i_cfg_wr_dev(C_CFGDEV_TESTING) = '1' then
      if tst_reg_adr_cnt = CONV_STD_LOGIC_VECTOR(1, tst_reg_adr_cnt'length) then
          tst_reg(0) <= i_cfg_txd;
      end if;
    end if;
  end if;
end process;

--//Чтение регистров
process(i_mnl_rst, g_usr_highclk)
begin
  if i_mnl_rst = '1' then
    i_cfg_rxd_dev(C_CFGDEV_TESTING) <= (others=>'0');
  elsif rising_edge(g_usr_highclk) then
    if i_cfg_rd_dev(C_CFGDEV_TESTING) = '1' then
      if tst_reg_adr_cnt = CONV_STD_LOGIC_VECTOR(0, tst_reg_adr_cnt'length) then
         i_cfg_rxd_dev(C_CFGDEV_TESTING) <= CONV_STD_LOGIC_VECTOR(C_FPGA_FIRMWARE_VERSION, i_cfg_rxd_dev(C_CFGDEV_TESTING)'length);
      elsif tst_reg_adr_cnt = CONV_STD_LOGIC_VECTOR(1, tst_reg_adr_cnt'length) then
         i_cfg_rxd_dev(C_CFGDEV_TESTING) <= tst_reg(0);
      end if;
    end if;
  end if;
end process;


end architecture;
