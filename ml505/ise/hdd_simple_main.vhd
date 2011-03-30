-------------------------------------------------------------------------
-- Company     : Linkos
-- Engineer    : Golovachenko Victor
--
-- Create Date : 20.01.2011 11:43:14
-- Module Name : hdd_simple_main
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
--library ieee_proposed;
--use ieee_proposed.float_pkg.all;

library work;
use work.vicg_common_pkg.all;
use work.sata_unit_pkg.all;
use work.sata_pkg.all;

---- synopsys translate_off
--library unisim;
--use unisim.vcomponents.all;
---- synopsys translate_on

Library UNISIM;
use UNISIM.vcomponents.all;

entity hdd_simple_main is
generic
(
G_SIM             : string:="OFF"
);
port
(
--------------------------------------------------
--Светодиоды (Для платы ML505)
--------------------------------------------------
pin_out_led                      : out   std_logic_vector(7 downto 0);
pin_out_led_C                    : out   std_logic;
pin_out_led_E                    : out   std_logic;
pin_out_led_N                    : out   std_logic;
pin_out_led_S                    : out   std_logic;
pin_out_led_W                    : out   std_logic;

pin_out_TP                       : out   std_logic_vector(7 downto 0);

pin_in_btn_C                     : in    std_logic;
pin_in_btn_E                     : in    std_logic;
pin_in_btn_N                     : in    std_logic;
pin_in_btn_S                     : in    std_logic;
pin_in_btn_W                     : in    std_logic;

--------------------------------------------------
-- Local bus
--------------------------------------------------
lreset_l              : in    std_logic;
--lclk                  : in    std_logic;
--lwrite                : in    std_logic;
--lads_l                : in    std_logic;
--lblast_l              : in    std_logic;
--lbe_l                 : in    std_logic_vector(C_FHOST_DBUS/8-1 downto 0);--(3 downto 0);
--lad                   : inout std_logic_vector(C_FHOST_DBUS-1 downto 0);--(31 downto 0);
--lbterm_l              : inout std_logic;
--lready_l              : inout std_logic;
--fholda                : in    std_logic;
--finto_l               : out   std_logic;

--------------------------------------------------
--SATA
--------------------------------------------------
pin_out_sata_txn      : out   std_logic_vector(1 downto 0);
pin_out_sata_txp      : out   std_logic_vector(1 downto 0);
pin_in_sata_rxn       : in    std_logic_vector(1 downto 0);
pin_in_sata_rxp       : in    std_logic_vector(1 downto 0);
pin_in_sata_clk_n     : in    std_logic;
pin_in_sata_clk_p     : in    std_logic;

--------------------------------------------------
-- Reference clock 200MHz
--------------------------------------------------
refclk_n              : in    std_logic;
refclk_p              : in    std_logic
);
end entity;

architecture struct of hdd_simple_main is

--component ROC generic (WIDTH : Time := 500 ns); port (O : out std_ulogic := '1'); end component;
component IBUFDS            port(I : in  std_logic; IB : in  std_logic; O  : out std_logic);end component;
component IBUFGDS_LVPECL_25 port(I : in  std_logic; IB : in  std_logic; O  : out std_logic);end component;
component BUFG              port(I : in  std_logic; O  : out std_logic);end component;

component fpga_test_01
generic(
G_BLINK_T05   : integer:=10#125#; -- 1/2 периода мигания светодиода.(время в ms)
G_CLK_T05us   : integer:=10#1000# -- кол-во периодов частоты порта p_in_clk
                                  -- укладывающиеся в 1/2 периода 1us
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


signal rst_sys_n                        : std_logic;
--signal rst_sys                          : std_logic;

signal i_refclk200MHz                   : std_logic;
signal g_refclk200MHz                   : std_logic;

signal i_satah_module_rst               : std_logic;
signal i_sata_gtp_refclkmain            : std_logic;
signal i_satah_dcm_rst                  : std_logic;
signal g_satah_dcm_clkin                : std_logic;
signal g_satah_dcm_clk                  : std_logic;
signal g_satah_dcm_clk2x                : std_logic;
signal g_satah_dcm_clk2div              : std_logic;
signal i_satah_dcm_lock                 : std_logic;

signal i_sata_gtp_refclkout             : std_logic;
signal g_sata_gtp_refclkout             : std_logic;

signal i_usr_rxd                        : std_logic_vector(31 downto 0);
signal i_usr_rxd_rd                     : std_logic;
signal i_usr_txd                        : std_logic_vector(31 downto 0);
signal i_usr_txd_wr                     : std_logic;

signal i_satah_ctrl                     : TALCtrl_GtpCh;
signal i_satah_status                   : TALStatus_GtpCh;
signal i_usrfifo_clkout                 : std_logic_vector(C_GTP_CH_COUNT_MAX-1 downto 0);

signal ll_wcmdpkt_data                  : std_logic_vector(15 downto 0);
signal ll_wcmdpkt_eof                   : std_logic:='0';
signal ll_wcmdpkt_src_rdy_n             : std_logic;
signal ll_wcmdpkt_dst_rdy_n             : std_logic;
signal ll_wcmdpkt_sof_n                 : std_logic;
signal ll_wcmdpkt_eof_n                 : std_logic;

signal ll_rcmdpkt_data                  : TBus16_GtpCh;
signal ll_rcmdpkt_sof_n                 : std_logic_vector(C_GTP_CH_COUNT_MAX-1 downto 0):=(others=>'0');
signal ll_rcmdpkt_eof_n                 : std_logic_vector(C_GTP_CH_COUNT_MAX-1 downto 0):=(others=>'0');
signal ll_rcmdpkt_src_rdy_n             : std_logic_vector(C_GTP_CH_COUNT_MAX-1 downto 0):=(others=>'0');
signal ll_rcmdpkt_dst_rdy_n             : std_logic_vector(C_GTP_CH_COUNT_MAX-1 downto 0):=(others=>'0');

signal i_txbuf_dout                     : TBus32_GtpCh;
signal i_txbuf_rd                       : std_logic_vector(C_GTP_CH_COUNT_MAX-1 downto 0);
signal i_txbuf_status                   : TTxBufStatus_GtpCh;
signal i_txbuf_full                     : std_logic_vector(C_GTP_CH_COUNT_MAX-1 downto 0);

signal i_rxbuf_din                      : TBus32_GtpCh;
signal i_rxbuf_wd                       : std_logic_vector(C_GTP_CH_COUNT_MAX-1 downto 0);
signal i_rxbuf_status                   : TRxBufStatus_GtpCh;

signal i_satah_sim_gtp_txdata           : TBus16_GtpCh;
signal i_satah_sim_gtp_txcharisk        : TBus02_GtpCh;
signal i_satah_sim_gtp_rxstatus         : TBus03_GtpCh;
signal i_satah_sim_gtp_rxelecidle       : std_logic_vector(C_GTP_CH_COUNT_MAX-1 downto 0);
signal i_satah_sim_gtp_rxdisperr        : TBus02_GtpCh;
signal i_satah_sim_gtp_rxnotintable     : TBus02_GtpCh;
signal i_satah_sim_gtp_rxbyteisaligned  : std_logic_vector(C_GTP_CH_COUNT_MAX-1 downto 0);

signal tst_satah_in                     : std_logic_vector(31 downto 0);
signal tst_satah_out                    : std_logic_vector(31 downto 0);

signal i_test01_led                     : std_logic;

signal sr_start                         : std_logic_vector(0 to 6);
signal i_cmd_send_cnt                   : std_logic_vector(3 downto 0);
signal i_cmd_send                       : std_logic;


--//MAIN
begin



--***********************************************************
--//RESET модулей
--***********************************************************
rst_sys_n <= lreset_l;
i_satah_module_rst    <=not rst_sys_n;--

--***********************************************************
--          Установка частот проекта:
--***********************************************************
--//Input 200MHz reference clock for IDELAY / ODELAY elements
ibufg_refclk : IBUFGDS_LVPECL_25 port map(I  => refclk_p, IB => refclk_n, O  => i_refclk200MHz);
bufg_refclk  : BUFG              port map(I  => i_refclk200MHz, O  => g_refclk200MHz);

--//Input 150MHz reference clock for SATA
ibufds_gtp_hdd_clkin : IBUFDS port map(I  => pin_in_sata_clk_p, IB => pin_in_sata_clk_n, O  => i_sata_gtp_refclkmain);

--//генерация частот для модуля sata_host.vhd
bufg_sata : BUFG port map (I => i_sata_gtp_refclkout, O => g_sata_gtp_refclkout);
m_dcm_sata : sata_dcm
port map
(
p_out_dcm_gclk0  => g_satah_dcm_clk,
p_out_dcm_gclk2x => g_satah_dcm_clk2x,
p_out_dcm_gclkdv => g_satah_dcm_clk2div,

p_out_dcmlock    => i_satah_dcm_lock,

p_in_clk         => g_sata_gtp_refclkout, --//150MHz
p_in_rst         => i_satah_dcm_rst
);

--//Согласующие буфера:
m_cmdbuf : ll_fifo
generic map(
MEM_TYPE        => 0,           -- 0 choose BRAM, 1 choose Distributed RAM
BRAM_MACRO_NUM  => 1,           -- Memory Depth(Кол-во элементов BRAM (1BRAM-4kB). For BRAM only - Allowed: 1, 2, 4, 8, 16
DRAM_DEPTH      => 16,          -- Memory Depth. For DRAM only

WR_REM_WIDTH    => 1,           -- Remainder width of write data
WR_DWIDTH       => 16,          -- FIFO write data width,
                                   -- Acceptable values are 8, 16, 32, 64, 128.

RD_REM_WIDTH    => 1,           -- Remainder width of read data
RD_DWIDTH       => 16,          -- FIFO read data width,
                                   -- Acceptable values are 8, 16, 32, 64, 128.

USE_LENGTH      => false,       -- Length FIFO option
glbtm           => 1 ns         -- Global timing delay for simulation
)
port map
(
-- Reset
areset_in              => i_satah_module_rst,

-- Interface to downstream user application
data_out               => ll_rcmdpkt_data(0),
rem_out                => open,--ll_rcmdpkt_rem,
sof_out_n              => ll_rcmdpkt_sof_n(0),
eof_out_n              => ll_rcmdpkt_eof_n(0),
src_rdy_out_n          => ll_rcmdpkt_src_rdy_n(0),
dst_rdy_in_n           => ll_rcmdpkt_dst_rdy_n(0),

read_clock_in          => i_usrfifo_clkout(0),

-- Interface to upstream user application
data_in                => ll_wcmdpkt_data,
rem_in                 => "0",
sof_in_n               => ll_wcmdpkt_sof_n,
eof_in_n               => ll_wcmdpkt_eof_n,
src_rdy_in_n           => ll_wcmdpkt_src_rdy_n,
dst_rdy_out_n          => ll_wcmdpkt_dst_rdy_n,

write_clock_in         => g_refclk200MHz,

-- FIFO status signals
fifostatus_out         => open,

-- Length Status
len_rdy_out            => open,
len_out                => open,
len_err_out            => open
);

m_txbuf : sata_txfifo
port map
(
din        => i_usr_txd,
wr_en      => i_usr_txd_wr,
wr_clk     => g_refclk200MHz,

dout       => i_txbuf_dout(0),
rd_en      => i_txbuf_rd(0),
rd_clk     => i_usrfifo_clkout(0),

full        => i_txbuf_full(0),
prog_full   => i_txbuf_status(0).pfull,
--almost_full => i_txbuf_afull(0),
empty       => i_txbuf_status(0).empty,
almost_empty=> i_txbuf_status(0).aempty,

rst        => i_satah_module_rst
);

m_rxbuf : sata_rxfifo
port map
(
din        => i_rxbuf_din(0),
wr_en      => i_rxbuf_wd(0),
wr_clk     => i_usrfifo_clkout(0),

dout       => i_usr_rxd,
rd_en      => i_usr_rxd_rd,
rd_clk     => g_refclk200MHz,

full        => open,--i_rxbuf_full(0),
prog_full   => i_rxbuf_status(0).pfull,
--almost_full => i_txbuf_afull(0),
empty       => i_rxbuf_status(0).empty,
--almost_empty=> i_rxbuf_aempty(0),

rst        => i_satah_module_rst
);

i_txbuf_status(1).pfull<='0';
i_txbuf_status(1).empty<='0';
i_txbuf_status(1).aempty<='0';

i_rxbuf_status(1).pfull<='0';
i_rxbuf_status(1).empty<='0';

--//SATA Контроллер
m_sata_host : sata_host
generic map
(
G_SATA_MODULE_MAXCOUNT   => 1, --//кол-во модуле sata_host в иерархии модуля sata_dsn.vhd / (дипозон: 1...3)
G_SATA_MODULE_IDX        => 0, --//индекс модуля sata_host в иерархии модуля sata_dsn.vhd / (дипозон: 0...G_SATA_MODULE_MAXCOUNT-1)
G_SATA_MODULE_CH_COUNT   => 1, --//Кол-во портов SATA используемых в модуле sata_host.vhd / (дипозон: 1...2)
G_GTP_DBUS               => 16,--G_GTP_DBUS,
G_DBG                    => "ON", --G_DBG,
G_SIM                    => "OFF" --G_SIM
)
port map
(
---------------------------------------------------------------------------
--Sata Driver
---------------------------------------------------------------------------
p_out_sata_txn              => pin_out_sata_txn,
p_out_sata_txp              => pin_out_sata_txp,
p_in_sata_rxn               => pin_in_sata_rxn,
p_in_sata_rxp               => pin_in_sata_rxp,

--------------------------------------------------
--Связь с USERAPP Layer
--------------------------------------------------
p_out_usrfifo_clkout        => i_usrfifo_clkout,
p_out_status                => i_satah_status,
p_in_ctrl                   => i_satah_ctrl,

--//Связь с CMDFIFO
p_in_cmdfifo_dout           => ll_rcmdpkt_data,
p_in_cmdfifo_eof_n          => ll_rcmdpkt_eof_n,
p_in_cmdfifo_src_rdy_n      => ll_rcmdpkt_src_rdy_n,
p_out_cmdfifo_dst_rdy_n     => ll_rcmdpkt_dst_rdy_n,


--//Связь с TXFIFO
p_in_txbuf_dout             => i_txbuf_dout,
p_out_txbuf_rd              => i_txbuf_rd,
p_in_txbuf_status           => i_txbuf_status,

--//Связь с RXFIFO
p_out_rxbuf_din             => i_rxbuf_din,
p_out_rxbuf_wd              => i_rxbuf_wd,
p_in_rxbuf_status           => i_rxbuf_status,

---------------------------------------------------------------------------
--Технологические сигналы
---------------------------------------------------------------------------
p_in_tst                    => "00000000000000000000000000000000",--tst_satah_in,
p_out_tst                   => tst_satah_out,

---------------------------------------------------------------------------
--Моделирование/Отладка - в рабочем проекте не используется
---------------------------------------------------------------------------
--//Моделирование
p_out_sim_gtp_txdata        => open,
p_out_sim_gtp_txcharisk     => open,
p_in_sim_gtp_rxdata         => i_satah_sim_gtp_txdata,
p_in_sim_gtp_rxcharisk      => i_satah_sim_gtp_txcharisk,
p_in_sim_gtp_rxstatus       => i_satah_sim_gtp_rxstatus,
p_in_sim_gtp_rxelecidle     => i_satah_sim_gtp_rxelecidle,
p_in_sim_gtp_rxdisperr      => i_satah_sim_gtp_rxdisperr,
p_in_sim_gtp_rxnotintable   => i_satah_sim_gtp_rxnotintable,
p_in_sim_gtp_rxbyteisaligned=> i_satah_sim_gtp_rxbyteisaligned,
p_out_sim_rst               => open,
p_out_sim_clk               => open,

---------------------------------------------------------------------------
--System
---------------------------------------------------------------------------
p_in_sys_dcm_gclk2div       => g_satah_dcm_clk2div,
p_in_sys_dcm_gclk           => g_satah_dcm_clk,
p_in_sys_dcm_gclk2x         => g_satah_dcm_clk2x,
p_in_sys_dcm_lock           => i_satah_dcm_lock,
p_out_sys_dcm_rst           => i_satah_dcm_rst,

p_in_gtp_drpclk             => g_satah_dcm_clk2div,
p_out_gtp_refclk            => i_sata_gtp_refclkout,
p_in_gtp_refclk             => i_sata_gtp_refclkmain,
p_in_rst                    => i_satah_module_rst
);

gen_gtpch: for i in 0 to C_GTP_CH_COUNT_MAX-1 generate
i_satah_sim_gtp_txdata(i)<=(others=>'0');
i_satah_sim_gtp_txcharisk(i)<=(others=>'0');
i_satah_sim_gtp_rxstatus(i)<=(others=>'0');
i_satah_sim_gtp_rxelecidle(i)<='0';
i_satah_sim_gtp_rxdisperr(i)<=(others=>'0');
i_satah_sim_gtp_rxnotintable(i)<=(others=>'0');
i_satah_sim_gtp_rxbyteisaligned(i)<='0';

i_satah_ctrl(i)<=(others=>'0');
end generate gen_gtpch;





--//----------------------------------
--//Технологические сигналы
--//----------------------------------
--//J5 /pin2
pin_out_TP(0)<=OR_reduce(tst_satah_out) or OR_reduce(i_usr_rxd);
--//J6
pin_out_TP(1)<=OR_reduce(i_satah_status(0).ATAError) or OR_reduce(i_satah_status(0).SError);
pin_out_TP(2)<=OR_reduce(i_satah_status(0).ATAStatus) or OR_reduce(i_satah_status(0).SStatus);
pin_out_TP(3)<=i_test01_led;
pin_out_TP(4)<='0';
pin_out_TP(5)<='0';
pin_out_TP(6)<='0';
pin_out_TP(7)<=pin_in_btn_C or pin_in_btn_E or pin_in_btn_N or pin_in_btn_S or pin_in_btn_W;


--Светодиоды
pin_out_led_C<='0';
pin_out_led_E<='0';
pin_out_led_N<='0';
pin_out_led_S<='0';
pin_out_led_W<='0';

pin_out_led(0)<=i_satah_status(0).Usr(C_AUSER_BUSY_BIT);
pin_out_led(1)<=i_satah_status(0).ATAError(C_REG_ATA_STATUS_ERR_BIT) or
                i_satah_status(0).SError(C_ASERR_I_ERR_BIT) or
                i_satah_status(0).SError(C_ASERR_C_ERR_BIT) or
                i_satah_status(0).SError(C_ASERR_P_ERR_BIT);
pin_out_led(2)<='0';
pin_out_led(3)<='0';

pin_out_led(4)<=i_satah_status(0).ATAError(C_REG_ATA_STATUS_ERR_BIT);
pin_out_led(5)<=i_satah_status(0).SError(C_ASERR_C_ERR_BIT);
pin_out_led(6)<=i_satah_status(0).SError(C_ASERR_P_ERR_BIT);
pin_out_led(7)<=i_satah_status(0).SError(C_ASERR_I_ERR_BIT);

m_test01: fpga_test_01
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
p_in_clk       => g_sata_gtp_refclkout,--150Mhz
p_in_rst       => '0'
);


gen_cmdxd: for i in 0 to ll_wcmdpkt_data'length-1 generate
ll_wcmdpkt_data(i)<=pin_in_btn_W xor pin_in_btn_S;
end generate gen_cmdxd;

gen_txd: for i in 0 to i_usr_txd'length-1 generate
i_usr_txd(i)<=pin_in_btn_W xor pin_in_btn_S;
end generate gen_txd;

i_usr_txd_wr<=pin_in_btn_W;
i_usr_rxd_rd<=pin_in_btn_E;


process(i_satah_module_rst,g_refclk200MHz)
begin
  if i_satah_module_rst='1' then
    sr_start<=(others=>'0');
    i_cmd_send_cnt<=(others=>'0');
    i_cmd_send<='0';

    ll_wcmdpkt_src_rdy_n<='1';
    ll_wcmdpkt_eof_n<='1';
    ll_wcmdpkt_sof_n<='1';
  elsif g_refclk200MHz'event and g_refclk200MHz='1' then
    sr_start<=pin_in_btn_C & sr_start(0 to 5);

    if sr_start(5)='1' and sr_start(6)='0' then
      i_cmd_send<='1';

    elsif i_cmd_send='1' then
      if i_cmd_send_cnt="1111" then
        i_cmd_send_cnt<=(others=>'0');
        i_cmd_send<='0';
      else
        i_cmd_send_cnt<=i_cmd_send_cnt + 1;
      end if;

      if i_cmd_send_cnt="0001" then
        ll_wcmdpkt_sof_n<='0';
      else
        ll_wcmdpkt_sof_n<='1';
      end if;

      if i_cmd_send_cnt="1000" then
        ll_wcmdpkt_eof_n<='0';
      else
        ll_wcmdpkt_eof_n<='1';
      end if;

      if i_cmd_send_cnt="0001" then
        ll_wcmdpkt_src_rdy_n<='0';
      elsif i_cmd_send_cnt="1001" then
        ll_wcmdpkt_src_rdy_n<='1';
      end if;

    end if;
  end if;
end process;

end architecture;
