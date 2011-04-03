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
use work.sata_raid_pkg.all;

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
lclk                  : in    std_logic;
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

signal i_dsn_hdd_rst                    : std_logic;
signal i_sata_gtp_refclkmain            : std_logic;
signal i_sata_gt_refclk                 : std_logic_vector(0 downto 0);

signal i_usr_rxd                        : std_logic_vector(31 downto 0);
signal i_usr_rxd_rd                     : std_logic;
signal i_usr_txd                        : std_logic_vector(31 downto 0);
signal i_usr_txd_wr                     : std_logic;

signal i_satah_ctrl                     : std_logic_vector(31 downto 0);
signal i_satah_status                   : TUsrStatus;

signal i_hdd_cmd                        : std_logic_vector(15 downto 0);
signal i_hdd_cmd_wr                     : std_logic;

signal i_hdd_txd                        : std_logic_vector(31 downto 0);
signal i_hdd_txd_rd                     : std_logic;
signal i_hdd_txbuf_empty                : std_logic;

signal i_hdd_rxd                        : std_logic_vector(31 downto 0);
signal i_hdd_rxd_wr                     : std_logic;
signal i_hdd_rxbuf_full                 : std_logic;

signal i_satah_sim_gtp_txdata           : TBus32_SHCountMax;
signal i_satah_sim_gtp_txcharisk        : TBus04_SHCountMax;
signal i_satah_sim_gtp_rxstatus         : TBus03_SHCountMax;
signal i_satah_sim_gtp_rxelecidle       : std_logic_vector(C_HDD_COUNT_MAX-1 downto 0);
signal i_satah_sim_gtp_rxdisperr        : TBus04_SHCountMax;
signal i_satah_sim_gtp_rxnotintable     : TBus04_SHCountMax;
signal i_satah_sim_gtp_rxbyteisaligned  : std_logic_vector(C_HDD_COUNT_MAX-1 downto 0);


signal tst_hdd_in                       : std_logic_vector(31 downto 0);
signal tst_hdd_out                      : std_logic_vector(31 downto 0);

signal i_test01_led                     : std_logic;

signal sr_hdd_cmd_start                 : std_logic_vector(0 to 6);


--//MAIN
begin



--***********************************************************
--//RESET модулей
--***********************************************************
rst_sys_n <= lreset_l;
i_dsn_hdd_rst <=not rst_sys_n;--

--***********************************************************
--          Установка частот проекта:
--***********************************************************
--//Input 200MHz reference clock for IDELAY / ODELAY elements
ibufg_refclk : IBUFGDS_LVPECL_25 port map(I  => refclk_p, IB => refclk_n, O  => i_refclk200MHz);
bufg_refclk  : BUFG              port map(I  => i_refclk200MHz, O  => g_refclk200MHz);

--//Input 150MHz reference clock for SATA
ibufds_gtp_hdd_clkin : IBUFDS port map(I  => pin_in_sata_clk_p, IB => pin_in_sata_clk_n, O  => i_sata_gtp_refclkmain);


m_txbuf : sata_txfifo
port map
(
din        => i_usr_txd,
wr_en      => i_usr_txd_wr,
wr_clk     => lclk,

dout       => i_hdd_txd,
rd_en      => i_hdd_txd_rd,
rd_clk     => g_refclk200MHz,

full        => open,
prog_full   => open,
--almost_full => i_txbuf_afull(0),
empty       => i_hdd_txbuf_empty,
almost_empty=> open,

rst        => i_dsn_hdd_rst
);

m_rxbuf : sata_rxfifo
port map
(
din        => i_hdd_rxd,
wr_en      => i_hdd_rxd_wr,
wr_clk     => g_refclk200MHz,

dout       => i_usr_rxd,
rd_en      => i_usr_rxd_rd,
rd_clk     => lclk,

full        => open,
prog_full   => i_hdd_rxbuf_full,
--almost_full => open,
empty       => open,
--almost_empty=> open,

rst        => i_dsn_hdd_rst
);


--//SATA Контроллер
m_dsn_raid : dsn_raid_main
generic map
(
G_HDD_COUNT => 1,
G_GTP_DBUS  => 16,
G_DBG       => "OFF",
G_SIM       => G_SIM
)
port map
(
--------------------------------------------------
--Sata Driver
--------------------------------------------------
p_out_sata_txn              => pin_out_sata_txn,
p_out_sata_txp              => pin_out_sata_txp,
p_in_sata_rxn               => pin_in_sata_rxn,
p_in_sata_rxp               => pin_in_sata_rxp,

p_in_sata_refclk            => i_sata_gt_refclk,

--------------------------------------------------
--Связь с модулем dsn_hdd.vhd
--------------------------------------------------
p_in_usr_ctrl               => i_satah_ctrl,
p_out_usr_status            => i_satah_status,

--//cmdpkt
p_in_usr_cxd                => i_hdd_cmd,
p_in_usr_cxd_wr             => i_hdd_cmd_wr,

--//txfifo
p_in_usr_txd                => i_hdd_txd,
p_out_usr_txd_rd            => i_hdd_txd_rd,
p_in_usr_txbuf_empty        => i_hdd_txbuf_empty,

--//rxfifo
p_out_usr_rxd               => i_hdd_rxd,
p_out_usr_rxd_wr            => i_hdd_rxd_wr,
p_in_usr_rxbuf_full         => i_hdd_rxbuf_full,

--------------------------------------------------
--Моделирование/Отладка - в рабочем проекте не используется
--------------------------------------------------
p_out_sim_gtp_txdata        => open,
p_out_sim_gtp_txcharisk     => open,
p_in_sim_gtp_rxdata         => i_satah_sim_gtp_txdata,
p_in_sim_gtp_rxcharisk      => i_satah_sim_gtp_txcharisk,
p_in_sim_gtp_rxstatus       => i_satah_sim_gtp_rxstatus,
p_in_sim_gtp_rxelecidle     => i_satah_sim_gtp_rxelecidle,
p_in_sim_gtp_rxdisperr      => i_satah_sim_gtp_rxdisperr,
p_in_sim_gtp_rxnotintable   => i_satah_sim_gtp_rxnotintable,
p_in_sim_gtp_rxbyteisaligned=> i_satah_sim_gtp_rxbyteisaligned,
p_out_gtp_sim_rst           => open,
p_out_gtp_sim_clk           => open,

--------------------------------------------------
--Технологические сигналы
--------------------------------------------------
p_in_tst                    => "00000000000000000000000000000000",--tst_hdd_in,
p_out_tst                   => tst_hdd_out,
--------------------------------------------------
--System
--------------------------------------------------
p_in_clk                => g_refclk200MHz,
p_in_rst                => i_dsn_hdd_rst
);

i_sata_gt_refclk(0)<=i_sata_gtp_refclkmain;

gen_satah: for i in 0 to C_HDD_COUNT_MAX-1 generate

i_satah_sim_gtp_txdata(i)<=(others=>'0');
i_satah_sim_gtp_txcharisk(i)<=(others=>'0');
i_satah_sim_gtp_rxstatus(i)<=(others=>'0');
i_satah_sim_gtp_rxelecidle(i)<='0';
i_satah_sim_gtp_rxdisperr(i)<=(others=>'0');
i_satah_sim_gtp_rxnotintable(i)<=(others=>'0');
i_satah_sim_gtp_rxbyteisaligned(i)<='0';
end generate gen_satah;




i_satah_ctrl(0)<=pin_in_btn_C;--//Сброс регистра ошибок
i_satah_ctrl(31 downto 1)<=(others=>'0');


--//----------------------------------
--//Технологические сигналы
--//----------------------------------
--//J5 /pin2
pin_out_TP(0)<=OR_reduce(tst_hdd_out) or OR_reduce(i_usr_rxd);
--//J6
pin_out_TP(1)<=OR_reduce(i_satah_status.SError(0));
pin_out_TP(2)<='0';
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

pin_out_led(0)<=i_satah_status.glob_drdy;
pin_out_led(1)<=i_satah_status.glob_busy;
pin_out_led(2)<=i_satah_status.glob_err;
pin_out_led(3)<='0';

pin_out_led(4)<=i_satah_status.ch_drdy(0);
pin_out_led(5)<=i_satah_status.ch_err(0);
pin_out_led(6)<=i_satah_status.ch_drdy(1);
pin_out_led(7)<=i_satah_status.ch_err(1);


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
p_in_clk       => g_refclk200MHz,
p_in_rst       => '0'
);


gen_txd: for i in 0 to i_usr_txd'length-1 generate
i_usr_txd(i)<=pin_in_btn_W xor pin_in_btn_S;
end generate gen_txd;

i_usr_txd_wr<=pin_in_btn_W;
i_usr_rxd_rd<=pin_in_btn_E;


process(i_dsn_hdd_rst,g_refclk200MHz)
begin
  if i_dsn_hdd_rst='1' then
    sr_hdd_cmd_start<=(others=>'0');
    i_hdd_cmd<=(others=>'0');
    i_hdd_cmd_wr<='0';

  elsif g_refclk200MHz'event and g_refclk200MHz='1' then
    sr_hdd_cmd_start<=pin_in_btn_C & sr_hdd_cmd_start(0 to 5);

    if sr_hdd_cmd_start(5)='1' and sr_hdd_cmd_start(6)='0' then
      i_hdd_cmd_wr<='1';

    elsif i_hdd_cmd_wr='1' then
      if i_hdd_cmd=CONV_STD_LOGIC_VECTOR(C_USRAPP_CMDPKT_SIZE_WORD-1, i_hdd_cmd'length) then
        i_hdd_cmd<=(others=>'0');
        i_hdd_cmd_wr<='0';
      else
        i_hdd_cmd<=i_hdd_cmd + 1;
      end if;

    end if;
  end if;
end process;

end architecture;
