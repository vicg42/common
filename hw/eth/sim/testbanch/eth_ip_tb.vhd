-------------------------------------------------------------------------
-- Company     : Linkos
-- Engineer    : Golovachenko Victor
--
-- Create Date : 11.10.2012 17:40:57
-- Module Name : eth_ip_tb
--
-- Description : Моделирование работы модуля dsn_hdd.vhd
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

use ieee.std_logic_textio.all;
use std.textio.all;

library unisim;
use unisim.vcomponents.all;

library work;
use work.vicg_common_pkg.all;
use work.eth_pkg.all;
use work.prj_cfg.all;

entity eth_ip_tb is
generic(
G_USR_DBUS: integer:=32;
G_ETH_CORE_DBUS: integer:=8;
G_ETH_CORE_DBUS_SWP: integer:=1; --1/0 Поле Length/Type первый мл./ст. байт (0 - по стандарту!!! 1 - как в проекте Вереск)
G_DBG : string:="ON";
G_SIM : string:="ON"
);
port(
p_out_txll_data      : out   std_logic_vector(G_ETH_CORE_DBUS-1 downto 0);
p_out_txll_sof_n     : out   std_logic;
p_out_txll_eof_n     : out   std_logic;
p_out_txll_src_rdy_n : out   std_logic;
--p_in_txll_dst_rdy_n  : in    std_logic;
p_out_txll_rem       : out   std_logic_vector(0 downto 0);

p_out_rxbuf_din       : out   std_logic_vector(G_USR_DBUS-1 downto 0);
p_out_rxbuf_wr        : out   std_logic;
--p_in_rxbuf_full       : in    std_logic;
p_out_rxd_sof         : out   std_logic;
p_out_rxd_eof         : out   std_logic
);
end eth_ip_tb;

architecture behavior of eth_ip_tb is

constant C_ETH_GT_REFCLK_PERIOD : TIME := 6.6 ns; --150MHz
constant C_ETH_GT_DRPCLK_PERIOD : TIME := 6.6*8 ns;
constant C_CFG_PERIOD           : TIME := 6.6*5 ns;


constant CI_HREG_ETH_TYPE        : integer:=12;--6;
constant CI_HREG_ARP_HTYPE       : integer:=14;--7;
constant CI_HREG_ARP_PTYPE       : integer:=16;--8;
constant CI_HREG_ARP_HPLEN       : integer:=18;--9;
constant CI_HREG_ARP_OPER        : integer:=20;--10;
constant CI_HREG_IP_PROTOCOL     : integer:=23;--11;
constant CI_HREG_ICMP_OPER       : integer:=35;--17;

constant CI_TX_REQ_ARP_ACK       : integer:=1;
constant CI_TX_REQ_ICMP_ACK      : integer:=2;

constant CI_ETH_TYPE_ARP         : std_logic_vector(15 downto 0):=CONV_STD_LOGIC_VECTOR(16#0806#, 16);
constant CI_ETH_TYPE_IP          : std_logic_vector(15 downto 0):=CONV_STD_LOGIC_VECTOR(16#0800#, 16);

constant CI_IP_VER               : std_logic_vector(3 downto 0):=CONV_STD_LOGIC_VECTOR(4, 4);
constant CI_IP_HEADER_LEN        : std_logic_vector(3 downto 0):=CONV_STD_LOGIC_VECTOR(20/4, 4);
constant CI_IP_TTL               : std_logic_vector(7 downto 0):=CONV_STD_LOGIC_VECTOR(128, 8);
constant CI_IP_PTYPE_ICMP        : std_logic_vector(7 downto 0):=CONV_STD_LOGIC_VECTOR(1, 8);

constant CI_ARP_HTYPE            : std_logic_vector(15 downto 0):=CONV_STD_LOGIC_VECTOR(1, 16);
constant CI_ARP_HLEN             : std_logic_vector( 7 downto 0):=CONV_STD_LOGIC_VECTOR(6, 8);
constant CI_ARP_PLEN             : std_logic_vector( 7 downto 0):=CONV_STD_LOGIC_VECTOR(4, 8);
constant CI_ARP_HPLEN            : std_logic_vector(15 downto 0):=CONV_STD_LOGIC_VECTOR(16#0604#, 16);
constant CI_ARP_OPER_REQUST      : std_logic_vector(15 downto 0):=CONV_STD_LOGIC_VECTOR(1, 16);
constant CI_ARP_OPER_REPLY       : std_logic_vector(15 downto 0):=CONV_STD_LOGIC_VECTOR(2, 16);

constant CI_ICMP_OPER_REQUST     : std_logic_vector(7 downto 0):=CONV_STD_LOGIC_VECTOR(8, 8);
constant CI_ICMP_OPER_ECHO_REPLY : std_logic_vector(7 downto 0):=CONV_STD_LOGIC_VECTOR(0, 8);

component host_vbuf
  PORT (
    rst : IN STD_LOGIC;
    wr_clk : IN STD_LOGIC;
    rd_clk : IN STD_LOGIC;
    din : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
    wr_en : IN STD_LOGIC;
    rd_en : IN STD_LOGIC;
    dout : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
    full : OUT STD_LOGIC;
    empty : OUT STD_LOGIC;
    prog_full : OUT STD_LOGIC
  );
END component;

component eth_ip
generic(
G_ETH : TEthGeneric;
G_DBG : string:="OFF";
G_SIM : string:="OFF"
);
port(
--------------------------------------
--Управление
--------------------------------------
p_in_cfg         : in    TEthCfg;

--------------------------------------
--Связь с пользовательским RXBUF
--------------------------------------
p_out_rxbuf_din       : out   std_logic_vector(G_ETH.usrbuf_dwidth-1 downto 0);
p_out_rxbuf_wr        : out   std_logic;
p_in_rxbuf_full       : in    std_logic;
p_out_rxd_sof         : out   std_logic;
p_out_rxd_eof         : out   std_logic;

--------------------------------------
--Связь с пользовательским TXBUF
--------------------------------------
p_in_txbuf_dout       : in    std_logic_vector(G_ETH.usrbuf_dwidth-1 downto 0);
p_out_txbuf_rd        : out   std_logic;
p_in_txbuf_empty      : in    std_logic;
--p_in_txd_rdy          : in    std_logic;

--------------------------------------
--Связь с Local link RxFIFO
--------------------------------------
p_in_rxll_data        : in    std_logic_vector(G_ETH.phy_dwidth-1 downto 0);
p_in_rxll_sof_n       : in    std_logic;
p_in_rxll_eof_n       : in    std_logic;
p_in_rxll_src_rdy_n   : in    std_logic;
p_out_rxll_dst_rdy_n  : out   std_logic;
p_in_rxll_fifo_status : in    std_logic_vector(3 downto 0);
p_in_rxll_rem         : in    std_logic_vector(0 downto 0);

--------------------------------------
--Связь с Local link TxFIFO
--------------------------------------
p_out_txll_data      : out   std_logic_vector(G_ETH.phy_dwidth-1 downto 0);
p_out_txll_sof_n     : out   std_logic;
p_out_txll_eof_n     : out   std_logic;
p_out_txll_src_rdy_n : out   std_logic;
p_in_txll_dst_rdy_n  : in    std_logic;
p_out_txll_rem       : out   std_logic_vector(0 downto 0);

--------------------------------------------------
--Технологические сигналы
--------------------------------------------------
p_in_tst         : in    std_logic_vector(31 downto 0);
p_out_tst        : out   std_logic_vector(31 downto 0);

--------------------------------------
--SYSTEM
--------------------------------------
p_in_clk         : in    std_logic;
p_in_rst         : in    std_logic
);
end component;

signal i_clk                      : std_logic;
signal i_rst                      : std_logic;

signal i_eth_cfg                  : TEthCfg;

signal i_rxll_data                : std_logic_vector(G_ETH_CORE_DBUS-1 downto 0);
signal i_rxll_sof_n               : std_logic;
signal i_rxll_eof_n               : std_logic;
signal i_rxll_src_rdy_n           : std_logic;
signal i_rxll_dst_rdy_n           : std_logic;

type TARP_ask is array (0 to 21*2-1) of std_logic_vector(G_ETH_CORE_DBUS-1 downto 0);
type TICMP_ask is array (0 to 37*2-1) of std_logic_vector(G_ETH_CORE_DBUS-1 downto 0);
signal i_arp_ack              : TARP_ask;
signal i_icmp_ack,i_icmp_ack2,i_icmp_ack3 : TICMP_ask;
signal i_udp : TICMP_ask;

type TDev is record
mac : TEthMacAdr;
ip  : TEthIPv4;
prt : std_logic_vector(15 downto 0);
end record;
signal i_dev                  : TDev;

signal i_txbuf_dout               : std_logic_vector(G_USR_DBUS-1 downto 0);
signal i_txbuf_rd                 : std_logic;
signal i_txbuf_empty              : std_logic;

signal i_data                     : std_logic_vector(G_USR_DBUS-1 downto 0);
signal i_data_wr                  : std_logic;


--MAIN
begin


m_ip_ctrl : eth_ip
generic map(
G_ETH.gtch_count_max  => C_PCFG_ETH_GTCH_COUNT_MAX,
G_ETH.usrbuf_dwidth   => G_USR_DBUS,
G_ETH.phy_dwidth      => G_ETH_CORE_DBUS,
G_ETH.phy_select      => C_ETH_PHY_FIBER,
G_ETH.mac_length_swap => G_ETH_CORE_DBUS_SWP, --1/0 Поле Length/Type первый мл./ст. байт (0 - по стандарту!!! 1 - как в проекте Вереск)
G_DBG => G_DBG,
G_SIM => G_SIM
)
port map(
--------------------------------------
--Управление
--------------------------------------
p_in_cfg             => i_eth_cfg,

--------------------------------------
--Связь с пользовательским RXBUF
--------------------------------------
p_out_rxbuf_din       => open,
p_out_rxbuf_wr        => open,
p_in_rxbuf_full       => '0',
p_out_rxd_sof         => open,
p_out_rxd_eof         => open,

--------------------------------------
--Связь с пользовательским TXBUF
--------------------------------------
p_in_txbuf_dout      => i_txbuf_dout ,
p_out_txbuf_rd       => i_txbuf_rd   ,
p_in_txbuf_empty     => i_txbuf_empty,
--p_in_txd_rdy         : in    std_logic;

--------------------------------------
--Связь с Local link RxFIFO
--------------------------------------
p_in_rxll_data        => i_rxll_data     ,
p_in_rxll_sof_n       => i_rxll_sof_n    ,
p_in_rxll_eof_n       => i_rxll_eof_n    ,
p_in_rxll_src_rdy_n   => i_rxll_src_rdy_n,
p_out_rxll_dst_rdy_n  => i_rxll_dst_rdy_n,
p_in_rxll_fifo_status => (others=>'0'),
p_in_rxll_rem         => (others=>'0'),

--------------------------------------
--Связь с Local link TxFIFO
--------------------------------------
p_out_txll_data      => p_out_txll_data     ,
p_out_txll_sof_n     => p_out_txll_sof_n    ,
p_out_txll_eof_n     => p_out_txll_eof_n    ,
p_out_txll_src_rdy_n => p_out_txll_src_rdy_n,
p_in_txll_dst_rdy_n  => '0' ,
p_out_txll_rem       => p_out_txll_rem      ,

--------------------------------------------------
--Технологические сигналы
--------------------------------------------------
p_in_tst             => (others=>'0'),
p_out_tst            => open,

--------------------------------------
--SYSTEM
--------------------------------------
p_in_clk             => i_clk,
p_in_rst             => i_rst
);


gen_clk : process
begin
  i_clk<='0';
  wait for C_CFG_PERIOD/2;
  i_clk<='1';
  wait for C_CFG_PERIOD/2;
end process;

i_rst<='1','0' after 1 us;



--//########################################
--//Main Ctrl
--//########################################
i_eth_cfg.mac.lentype<=CONV_STD_LOGIC_VECTOR(16#000A#, i_eth_cfg.mac.lentype'length);
i_eth_cfg.usrctrl<=(others=>'0');

i_eth_cfg.mac.src(0)<=CONV_STD_LOGIC_VECTOR(16#A0#, i_eth_cfg.mac.src(0)'length);--(16#90#, i_eth_cfg.mac.src(0)'length);
i_eth_cfg.mac.src(1)<=CONV_STD_LOGIC_VECTOR(16#A1#, i_eth_cfg.mac.src(0)'length);--(16#E6#, i_eth_cfg.mac.src(0)'length);
i_eth_cfg.mac.src(2)<=CONV_STD_LOGIC_VECTOR(16#A2#, i_eth_cfg.mac.src(0)'length);--(16#BA#, i_eth_cfg.mac.src(0)'length);
i_eth_cfg.mac.src(3)<=CONV_STD_LOGIC_VECTOR(16#A3#, i_eth_cfg.mac.src(0)'length);--(16#CE#, i_eth_cfg.mac.src(0)'length);
i_eth_cfg.mac.src(4)<=CONV_STD_LOGIC_VECTOR(16#A4#, i_eth_cfg.mac.src(0)'length);--(16#31#, i_eth_cfg.mac.src(0)'length);
i_eth_cfg.mac.src(5)<=CONV_STD_LOGIC_VECTOR(16#A5#, i_eth_cfg.mac.src(0)'length);--(16#DA#, i_eth_cfg.mac.src(0)'length);

i_eth_cfg.mac.dst(0)<=CONV_STD_LOGIC_VECTOR(16#2A#, i_eth_cfg.mac.dst(0)'length);
i_eth_cfg.mac.dst(1)<=CONV_STD_LOGIC_VECTOR(16#2B#, i_eth_cfg.mac.dst(0)'length);
i_eth_cfg.mac.dst(2)<=CONV_STD_LOGIC_VECTOR(16#2C#, i_eth_cfg.mac.dst(0)'length);
i_eth_cfg.mac.dst(3)<=CONV_STD_LOGIC_VECTOR(16#2D#, i_eth_cfg.mac.dst(0)'length);
i_eth_cfg.mac.dst(4)<=CONV_STD_LOGIC_VECTOR(16#2E#, i_eth_cfg.mac.dst(0)'length);
i_eth_cfg.mac.dst(5)<=CONV_STD_LOGIC_VECTOR(16#2F#, i_eth_cfg.mac.dst(0)'length);

i_eth_cfg.ip.src(0)<=CONV_STD_LOGIC_VECTOR(10 , i_eth_cfg.ip.src(0)'length);--(10 , i_eth_cfg.ip.src(0)'length);
i_eth_cfg.ip.src(1)<=CONV_STD_LOGIC_VECTOR(1  , i_eth_cfg.ip.src(0)'length);--(1  , i_eth_cfg.ip.src(0)'length);
i_eth_cfg.ip.src(2)<=CONV_STD_LOGIC_VECTOR(7  , i_eth_cfg.ip.src(0)'length);--(7  , i_eth_cfg.ip.src(0)'length);
i_eth_cfg.ip.src(3)<=CONV_STD_LOGIC_VECTOR(232, i_eth_cfg.ip.src(0)'length);--(125, i_eth_cfg.ip.src(0)'length);

i_eth_cfg.ip.dst(0)<=CONV_STD_LOGIC_VECTOR(16#EA#, i_eth_cfg.ip.src(0)'length);
i_eth_cfg.ip.dst(1)<=CONV_STD_LOGIC_VECTOR(16#EB#, i_eth_cfg.ip.src(0)'length);
i_eth_cfg.ip.dst(2)<=CONV_STD_LOGIC_VECTOR(16#EC#, i_eth_cfg.ip.src(0)'length);
i_eth_cfg.ip.dst(3)<=CONV_STD_LOGIC_VECTOR(16#ED#, i_eth_cfg.ip.src(0)'length);

i_eth_cfg.prt.dst<=CONV_STD_LOGIC_VECTOR(0, i_eth_cfg.prt.dst'length);
i_eth_cfg.prt.src<=CONV_STD_LOGIC_VECTOR(200, i_eth_cfg.prt.src'length);



i_dev.mac(0)<=CONV_STD_LOGIC_VECTOR(16#90#, i_dev.mac(0)'length);--(16#00#, i_dev.mac(0)'length);
i_dev.mac(1)<=CONV_STD_LOGIC_VECTOR(16#E6#, i_dev.mac(0)'length);--(16#0E#, i_dev.mac(0)'length);
i_dev.mac(2)<=CONV_STD_LOGIC_VECTOR(16#BA#, i_dev.mac(0)'length);--(16#A6#, i_dev.mac(0)'length);
i_dev.mac(3)<=CONV_STD_LOGIC_VECTOR(16#CE#, i_dev.mac(0)'length);--(16#5A#, i_dev.mac(0)'length);
i_dev.mac(4)<=CONV_STD_LOGIC_VECTOR(16#31#, i_dev.mac(0)'length);--(16#5E#, i_dev.mac(0)'length);
i_dev.mac(5)<=CONV_STD_LOGIC_VECTOR(16#DA#, i_dev.mac(0)'length);--(16#E9#, i_dev.mac(0)'length);

i_dev.ip(0)<=CONV_STD_LOGIC_VECTOR(10 , i_dev.ip(0)'length);--(10 , i_dev.ip(0)'length);
i_dev.ip(1)<=CONV_STD_LOGIC_VECTOR(1  , i_dev.ip(0)'length);--(1  , i_dev.ip(0)'length);
i_dev.ip(2)<=CONV_STD_LOGIC_VECTOR(7  , i_dev.ip(0)'length);--(7  , i_dev.ip(0)'length);
i_dev.ip(3)<=CONV_STD_LOGIC_VECTOR(125, i_dev.ip(0)'length);--(240, i_dev.ip(0)'length);

i_dev.prt<=CONV_STD_LOGIC_VECTOR(11, i_dev.prt'length);


process
begin
--  p_in_txll_dst_rdy_n<='0';
--  p_in_rxbuf_full<='0';
  i_data<=(others=>'0');
  i_data_wr<='0';

  wait for 2 us;

  wait until i_clk'event and i_clk='1';
  i_data_wr<='1';                                         ---DLENGTH
  i_data<=CONV_STD_LOGIC_VECTOR(16#A1A0#, G_USR_DBUS/2) & CONV_STD_LOGIC_VECTOR(16#000A#, 16);

  wait until i_clk'event and i_clk='1';
  i_data_wr<='1';
  i_data<=CONV_STD_LOGIC_VECTOR(16#A5A4#, G_USR_DBUS/2)&CONV_STD_LOGIC_VECTOR(16#A3A2#, G_USR_DBUS/2);
  wait until i_clk'event and i_clk='1';
  i_data_wr<='1';
  i_data<=CONV_STD_LOGIC_VECTOR(16#A9A8#, G_USR_DBUS/2)&CONV_STD_LOGIC_VECTOR(16#A7A6#, G_USR_DBUS/2);

  wait until i_clk'event and i_clk='1';
  i_data_wr<='0';

  wait;
end process;


m_buf : host_vbuf
port map(
rst => i_rst,
wr_clk => i_clk,
rd_clk => i_clk,
din => i_data,
wr_en => i_data_wr,
rd_en => i_txbuf_rd,
dout => i_txbuf_dout,
full => open,
empty => i_txbuf_empty,
prog_full => open
);


process
begin

  i_rxll_data <= (others=>'0');
  i_rxll_sof_n <= '1';
  i_rxll_eof_n <= '1';
  i_rxll_src_rdy_n <= '1';

  wait for 2 us;

  wait until i_clk'event and i_clk='1' and i_rxll_dst_rdy_n='0';
  i_rxll_data <= i_arp_ack(0);
  i_rxll_sof_n <= '0';
  i_rxll_src_rdy_n <= '0';

  for i in 1 to i_arp_ack'length-2 loop
  wait until i_clk'event and i_clk='1' and i_rxll_dst_rdy_n='0';
  i_rxll_data <= i_arp_ack(i);
  i_rxll_sof_n <= '1';
  i_rxll_src_rdy_n <= '0';
  end loop;

  wait until i_clk'event and i_clk='1' and i_rxll_dst_rdy_n='0';
  i_rxll_data <= i_arp_ack(20);
  i_rxll_sof_n <= '1';
  i_rxll_eof_n <= '0';
  i_rxll_src_rdy_n <= '0';

  wait until i_clk'event and i_clk='1' and i_rxll_dst_rdy_n='0';
  i_rxll_data <= (others=>'0');
  i_rxll_sof_n <= '1';
  i_rxll_eof_n <= '1';
  i_rxll_src_rdy_n <= '1';

  wait for 2 us;

  wait until i_clk'event and i_clk='1' and i_rxll_dst_rdy_n='0';
  i_rxll_data <= i_icmp_ack(0);
  i_rxll_sof_n <= '0';
  i_rxll_src_rdy_n <= '0';

  for i in 1 to i_icmp_ack'length-2 loop
  wait until i_clk'event and i_clk='1' and i_rxll_dst_rdy_n='0';
  i_rxll_data <= i_icmp_ack(i);
  i_rxll_sof_n <= '1';
  i_rxll_src_rdy_n <= '0';
  end loop;

  wait until i_clk'event and i_clk='1' and i_rxll_dst_rdy_n='0';
  i_rxll_data <= i_icmp_ack(73);
  i_rxll_sof_n <= '1';
  i_rxll_eof_n <= '0';
  i_rxll_src_rdy_n <= '0';

  wait until i_clk'event and i_clk='1' and i_rxll_dst_rdy_n='0';
  i_rxll_data <= (others=>'0');
  i_rxll_sof_n <= '1';
  i_rxll_eof_n <= '1';
  i_rxll_src_rdy_n <= '1';



  wait for 2 us;

  wait until i_clk'event and i_clk='1' and i_rxll_dst_rdy_n='0';
  i_rxll_data <= i_icmp_ack2(0);
  i_rxll_sof_n <= '0';
  i_rxll_src_rdy_n <= '0';

  for i in 1 to i_icmp_ack'length-2 loop
  wait until i_clk'event and i_clk='1' and i_rxll_dst_rdy_n='0';
  i_rxll_data <= i_icmp_ack2(i);
  i_rxll_sof_n <= '1';
  i_rxll_src_rdy_n <= '0';
  end loop;

  wait until i_clk'event and i_clk='1' and i_rxll_dst_rdy_n='0';
  i_rxll_data <= i_icmp_ack2(73);
  i_rxll_sof_n <= '1';
  i_rxll_eof_n <= '0';
  i_rxll_src_rdy_n <= '0';

  wait until i_clk'event and i_clk='1' and i_rxll_dst_rdy_n='0';
  i_rxll_data <= (others=>'0');
  i_rxll_sof_n <= '1';
  i_rxll_eof_n <= '1';
  i_rxll_src_rdy_n <= '1';



  wait for 2 us;

  wait until i_clk'event and i_clk='1' and i_rxll_dst_rdy_n='0';
  i_rxll_data <= i_icmp_ack3(0);
  i_rxll_sof_n <= '0';
  i_rxll_src_rdy_n <= '0';

  for i in 1 to i_icmp_ack'length-2 loop
  wait until i_clk'event and i_clk='1' and i_rxll_dst_rdy_n='0';
  i_rxll_data <= i_icmp_ack3(i);
  i_rxll_sof_n <= '1';
  i_rxll_src_rdy_n <= '0';
  end loop;

  wait until i_clk'event and i_clk='1' and i_rxll_dst_rdy_n='0';
  i_rxll_data <= i_icmp_ack3(73);
  i_rxll_sof_n <= '1';
  i_rxll_eof_n <= '0';
  i_rxll_src_rdy_n <= '0';

  wait until i_clk'event and i_clk='1';
  i_rxll_data <= (others=>'0');
  i_rxll_sof_n <= '1';
  i_rxll_eof_n <= '1';
  i_rxll_src_rdy_n <= '1';




  wait for 2 us;

  wait until i_clk'event and i_clk='1' and i_rxll_dst_rdy_n='0';
  i_rxll_data <= i_udp(0);
  i_rxll_sof_n <= '0';
  i_rxll_src_rdy_n <= '0';

  for i in 1 to 50 loop--41 loop --
  wait until i_clk'event and i_clk='1' and i_rxll_dst_rdy_n='0';
  i_rxll_data <= i_udp(i);
  i_rxll_sof_n <= '1';
  i_rxll_src_rdy_n <= '0';
  end loop;

  wait until i_clk'event and i_clk='1' and i_rxll_dst_rdy_n='0';
  i_rxll_data <= i_udp(51);--i_udp(42);--
  i_rxll_sof_n <= '1';
  i_rxll_eof_n <= '0';
  i_rxll_src_rdy_n <= '0';

  wait until i_clk'event and i_clk='1';
  i_rxll_data <= (others=>'0');
  i_rxll_sof_n <= '1';
  i_rxll_eof_n <= '1';
  i_rxll_src_rdy_n <= '1';
  wait;
end process;



----------------------------------
--ARP запрос
----------------------------------
-- MAC адреса
i_arp_ack(0)  <= (others=>'1');--MAC Dst: адрес отправителя ARP запроса
i_arp_ack(1)  <= (others=>'1');
i_arp_ack(2)  <= (others=>'1');
i_arp_ack(3)  <= (others=>'1');
i_arp_ack(4)  <= (others=>'1');
i_arp_ack(5)  <= (others=>'1');
i_arp_ack(6)  <= i_dev.mac(0); --MAC Src: FPGA
i_arp_ack(7)  <= i_dev.mac(1);
i_arp_ack(8)  <= i_dev.mac(2);
i_arp_ack(9)  <= i_dev.mac(3);
i_arp_ack(10) <= i_dev.mac(4);
i_arp_ack(11) <= i_dev.mac(5);
--Eth type
i_arp_ack(12) <= CI_ETH_TYPE_ARP(15 downto 8);
i_arp_ack(13) <= CI_ETH_TYPE_ARP( 7 downto 0);
--ARP
i_arp_ack(14) <= CI_ARP_HTYPE(15 downto 8);  --ARP: HTYPE
i_arp_ack(15) <= CI_ARP_HTYPE( 7 downto 0);
i_arp_ack(16) <= CI_ETH_TYPE_IP(15 downto 8);--ARP: PTYPE
i_arp_ack(17) <= CI_ETH_TYPE_IP( 7 downto 0);
i_arp_ack(18) <= CI_ARP_HPLEN(15 downto 8);  --ARP: HLEN
i_arp_ack(19) <= CI_ARP_HPLEN( 7 downto 0);  --ARP: PLEN
i_arp_ack(20) <= CI_ARP_OPER_REQUST(15 downto 8);--ARP:  OPERATION
i_arp_ack(21) <= CI_ARP_OPER_REQUST( 7 downto 0);
i_arp_ack(22) <= i_dev.mac(0);--ARP: MAC src
i_arp_ack(23) <= i_dev.mac(1);
i_arp_ack(24) <= i_dev.mac(2);
i_arp_ack(25) <= i_dev.mac(3);
i_arp_ack(26) <= i_dev.mac(4);
i_arp_ack(27) <= i_dev.mac(5);
i_arp_ack(28) <= i_dev.ip(0); --ARP: IP src
i_arp_ack(29) <= i_dev.ip(1);
i_arp_ack(30) <= i_dev.ip(2);
i_arp_ack(31) <= i_dev.ip(3);
i_arp_ack(32) <= (others=>'0');--ARP: MAC dst
i_arp_ack(33) <= (others=>'0');
i_arp_ack(34) <= (others=>'0');
i_arp_ack(35) <= (others=>'0');
i_arp_ack(36) <= (others=>'0');
i_arp_ack(37) <= (others=>'0');
i_arp_ack(38) <= (others=>'0');--ARP: IP dst
i_arp_ack(39) <= (others=>'0');
i_arp_ack(40) <= (others=>'0');
i_arp_ack(41) <= (others=>'0');


----------------------------------
--ICMP запрос 1
----------------------------------
-- MAC адреса
i_icmp_ack(0)  <= i_eth_cfg.mac.src(0);
i_icmp_ack(1)  <= i_eth_cfg.mac.src(1);
i_icmp_ack(2)  <= i_eth_cfg.mac.src(2);
i_icmp_ack(3)  <= i_eth_cfg.mac.src(3);
i_icmp_ack(4)  <= i_eth_cfg.mac.src(4);
i_icmp_ack(5)  <= i_eth_cfg.mac.src(5);
i_icmp_ack(6)  <= i_dev.mac(0);
i_icmp_ack(7)  <= i_dev.mac(1);
i_icmp_ack(8)  <= i_dev.mac(2);
i_icmp_ack(9)  <= i_dev.mac(3);
i_icmp_ack(10) <= i_dev.mac(4);
i_icmp_ack(11) <= i_dev.mac(5);
--Eth type
i_icmp_ack(12) <= CI_ETH_TYPE_IP(15 downto 8);
i_icmp_ack(13) <= CI_ETH_TYPE_IP( 7 downto 0);
--IP
i_icmp_ack(14) <= CONV_STD_LOGIC_VECTOR(16#45#, 8); --IP: ver
i_icmp_ack(15) <= (others=>'0'); --IP: ToS (тип обслуживания)
i_icmp_ack(16) <= (others=>'0'); --IP: dlen
i_icmp_ack(17) <= CONV_STD_LOGIC_VECTOR(16#3C#, 8);
i_icmp_ack(18) <= CONV_STD_LOGIC_VECTOR(16#1F#, 8); --IP: id
i_icmp_ack(19) <= CONV_STD_LOGIC_VECTOR(16#74#, 8);
i_icmp_ack(20) <= (others=>'0'); --IP: flag
i_icmp_ack(21) <= (others=>'0');
i_icmp_ack(22) <= CONV_STD_LOGIC_VECTOR(16#80#, 8);--CI_IP_TTL;
i_icmp_ack(23) <= CONV_STD_LOGIC_VECTOR(16#01#, 8);--; --IP: protocol
i_icmp_ack(24) <= (others=>'0');-- when i_ip_crc_rdy='0' else i_ip_crc(15 downto 8); --IP: CRC
i_icmp_ack(25) <= (others=>'0');-- when i_ip_crc_rdy='0' else i_ip_crc( 7 downto 0);
i_icmp_ack(26) <= i_dev.ip(0); --IP: ip адрес отправителя ARP запроса
i_icmp_ack(27) <= i_dev.ip(1);
i_icmp_ack(28) <= i_dev.ip(2);
i_icmp_ack(29) <= i_dev.ip(3);
i_icmp_ack(30) <= i_eth_cfg.ip.src(0);
i_icmp_ack(31) <= i_eth_cfg.ip.src(1);
i_icmp_ack(32) <= i_eth_cfg.ip.src(2);
i_icmp_ack(33) <= i_eth_cfg.ip.src(3);
--ICMP
i_icmp_ack(34) <= CI_ICMP_OPER_REQUST;--ICMP: Operation
i_icmp_ack(35) <= (others=>'0');
i_icmp_ack(36) <= CONV_STD_LOGIC_VECTOR(16#4D#, 8);--ICMP: CRC
i_icmp_ack(37) <= CONV_STD_LOGIC_VECTOR(16#DD#, 8);--;
i_icmp_ack(38) <= CONV_STD_LOGIC_VECTOR(16#00#, 8);
i_icmp_ack(39) <= CONV_STD_LOGIC_VECTOR(16#01#, 8);
i_icmp_ack(40) <= CONV_STD_LOGIC_VECTOR(16#00#, 8);
i_icmp_ack(41) <= CONV_STD_LOGIC_VECTOR(16#7E#, 8);
i_icmp_ack(42) <= CONV_STD_LOGIC_VECTOR(16#61#, 8);
i_icmp_ack(43) <= CONV_STD_LOGIC_VECTOR(16#62#, 8);
i_icmp_ack(44) <= CONV_STD_LOGIC_VECTOR(16#63#, 8);
i_icmp_ack(45) <= CONV_STD_LOGIC_VECTOR(16#64#, 8);
i_icmp_ack(46) <= CONV_STD_LOGIC_VECTOR(16#65#, 8);
i_icmp_ack(47) <= CONV_STD_LOGIC_VECTOR(16#66#, 8);
i_icmp_ack(48) <= CONV_STD_LOGIC_VECTOR(16#67#, 8);
i_icmp_ack(49) <= CONV_STD_LOGIC_VECTOR(16#68#, 8);
i_icmp_ack(50) <= CONV_STD_LOGIC_VECTOR(16#69#, 8);
i_icmp_ack(51) <= CONV_STD_LOGIC_VECTOR(16#6A#, 8);
i_icmp_ack(52) <= CONV_STD_LOGIC_VECTOR(16#6B#, 8);
i_icmp_ack(53) <= CONV_STD_LOGIC_VECTOR(16#6C#, 8);
i_icmp_ack(54) <= CONV_STD_LOGIC_VECTOR(16#6D#, 8);
i_icmp_ack(55) <= CONV_STD_LOGIC_VECTOR(16#6E#, 8);
i_icmp_ack(56) <= CONV_STD_LOGIC_VECTOR(16#6F#, 8);
i_icmp_ack(57) <= CONV_STD_LOGIC_VECTOR(16#70#, 8);
i_icmp_ack(58) <= CONV_STD_LOGIC_VECTOR(16#71#, 8);
i_icmp_ack(59) <= CONV_STD_LOGIC_VECTOR(16#72#, 8);
i_icmp_ack(60) <= CONV_STD_LOGIC_VECTOR(16#73#, 8);
i_icmp_ack(61) <= CONV_STD_LOGIC_VECTOR(16#74#, 8);
i_icmp_ack(62) <= CONV_STD_LOGIC_VECTOR(16#75#, 8);
i_icmp_ack(63) <= CONV_STD_LOGIC_VECTOR(16#76#, 8);
i_icmp_ack(64) <= CONV_STD_LOGIC_VECTOR(16#77#, 8);
i_icmp_ack(65) <= CONV_STD_LOGIC_VECTOR(16#61#, 8);
i_icmp_ack(66) <= CONV_STD_LOGIC_VECTOR(16#62#, 8);
i_icmp_ack(67) <= CONV_STD_LOGIC_VECTOR(16#63#, 8);
i_icmp_ack(68) <= CONV_STD_LOGIC_VECTOR(16#64#, 8);
i_icmp_ack(69) <= CONV_STD_LOGIC_VECTOR(16#65#, 8);
i_icmp_ack(70) <= CONV_STD_LOGIC_VECTOR(16#66#, 8);
i_icmp_ack(71) <= CONV_STD_LOGIC_VECTOR(16#67#, 8);
i_icmp_ack(72) <= CONV_STD_LOGIC_VECTOR(16#68#, 8);
i_icmp_ack(73) <= CONV_STD_LOGIC_VECTOR(16#69#, 8);


----------------------------------
--ICMP запрос 2
----------------------------------
-- MAC адреса
i_icmp_ack2(0)  <= i_eth_cfg.mac.src(0);
i_icmp_ack2(1)  <= i_eth_cfg.mac.src(1);
i_icmp_ack2(2)  <= i_eth_cfg.mac.src(2);
i_icmp_ack2(3)  <= i_eth_cfg.mac.src(3);
i_icmp_ack2(4)  <= i_eth_cfg.mac.src(4);
i_icmp_ack2(5)  <= i_eth_cfg.mac.src(5);
i_icmp_ack2(6)  <= i_dev.mac(0);
i_icmp_ack2(7)  <= i_dev.mac(1);
i_icmp_ack2(8)  <= i_dev.mac(2);
i_icmp_ack2(9)  <= i_dev.mac(3);
i_icmp_ack2(10) <= i_dev.mac(4);
i_icmp_ack2(11) <= i_dev.mac(5);
--Eth type
i_icmp_ack2(12) <= CI_ETH_TYPE_IP(15 downto 8);
i_icmp_ack2(13) <= CI_ETH_TYPE_IP( 7 downto 0);
--IP
i_icmp_ack2(14) <= CONV_STD_LOGIC_VECTOR(16#45#, 8); --IP: ver
i_icmp_ack2(15) <= (others=>'0'); --IP: ToS (тип обслуживания)
i_icmp_ack2(16) <= (others=>'0'); --IP: dlen
i_icmp_ack2(17) <= CONV_STD_LOGIC_VECTOR(16#3C#, 8);
i_icmp_ack2(18) <= CONV_STD_LOGIC_VECTOR(16#1F#, 8); --IP: id
i_icmp_ack2(19) <= CONV_STD_LOGIC_VECTOR(16#78#, 8);
i_icmp_ack2(20) <= (others=>'0'); --IP: flag
i_icmp_ack2(21) <= (others=>'0');
i_icmp_ack2(22) <= CONV_STD_LOGIC_VECTOR(16#80#, 8);--CI_IP_TTL;
i_icmp_ack2(23) <= CONV_STD_LOGIC_VECTOR(16#01#, 8);--; --IP: protocol
i_icmp_ack2(24) <= (others=>'0');-- when i_ip_crc_rdy='0' else i_ip_crc(15 downto 8); --IP: CRC
i_icmp_ack2(25) <= (others=>'0');-- when i_ip_crc_rdy='0' else i_ip_crc( 7 downto 0);
i_icmp_ack2(26) <= i_dev.ip(0); --IP: ip адрес отправителя ARP запроса
i_icmp_ack2(27) <= i_dev.ip(1);
i_icmp_ack2(28) <= i_dev.ip(2);
i_icmp_ack2(29) <= i_dev.ip(3);
i_icmp_ack2(30) <= i_eth_cfg.ip.src(0);
i_icmp_ack2(31) <= i_eth_cfg.ip.src(1);
i_icmp_ack2(32) <= i_eth_cfg.ip.src(2);
i_icmp_ack2(33) <= i_eth_cfg.ip.src(3);
--ICMP
i_icmp_ack2(34) <= CI_ICMP_OPER_REQUST;--ICMP: Operation
i_icmp_ack2(35) <= (others=>'0');
i_icmp_ack2(36) <= CONV_STD_LOGIC_VECTOR(16#4D#, 8);--ICMP: CRC
i_icmp_ack2(37) <= CONV_STD_LOGIC_VECTOR(16#DC#, 8);--;
i_icmp_ack2(38) <= CONV_STD_LOGIC_VECTOR(16#00#, 8);
i_icmp_ack2(39) <= CONV_STD_LOGIC_VECTOR(16#01#, 8);
i_icmp_ack2(40) <= CONV_STD_LOGIC_VECTOR(16#00#, 8);
i_icmp_ack2(41) <= CONV_STD_LOGIC_VECTOR(16#7F#, 8);
i_icmp_ack2(42) <= CONV_STD_LOGIC_VECTOR(16#61#, 8);
i_icmp_ack2(43) <= CONV_STD_LOGIC_VECTOR(16#62#, 8);
i_icmp_ack2(44) <= CONV_STD_LOGIC_VECTOR(16#63#, 8);
i_icmp_ack2(45) <= CONV_STD_LOGIC_VECTOR(16#64#, 8);
i_icmp_ack2(46) <= CONV_STD_LOGIC_VECTOR(16#65#, 8);
i_icmp_ack2(47) <= CONV_STD_LOGIC_VECTOR(16#66#, 8);
i_icmp_ack2(48) <= CONV_STD_LOGIC_VECTOR(16#67#, 8);
i_icmp_ack2(49) <= CONV_STD_LOGIC_VECTOR(16#68#, 8);
i_icmp_ack2(50) <= CONV_STD_LOGIC_VECTOR(16#69#, 8);
i_icmp_ack2(51) <= CONV_STD_LOGIC_VECTOR(16#6A#, 8);
i_icmp_ack2(52) <= CONV_STD_LOGIC_VECTOR(16#6B#, 8);
i_icmp_ack2(53) <= CONV_STD_LOGIC_VECTOR(16#6C#, 8);
i_icmp_ack2(54) <= CONV_STD_LOGIC_VECTOR(16#6D#, 8);
i_icmp_ack2(55) <= CONV_STD_LOGIC_VECTOR(16#6E#, 8);
i_icmp_ack2(56) <= CONV_STD_LOGIC_VECTOR(16#6F#, 8);
i_icmp_ack2(57) <= CONV_STD_LOGIC_VECTOR(16#70#, 8);
i_icmp_ack2(58) <= CONV_STD_LOGIC_VECTOR(16#71#, 8);
i_icmp_ack2(59) <= CONV_STD_LOGIC_VECTOR(16#72#, 8);
i_icmp_ack2(60) <= CONV_STD_LOGIC_VECTOR(16#73#, 8);
i_icmp_ack2(61) <= CONV_STD_LOGIC_VECTOR(16#74#, 8);
i_icmp_ack2(62) <= CONV_STD_LOGIC_VECTOR(16#75#, 8);
i_icmp_ack2(63) <= CONV_STD_LOGIC_VECTOR(16#76#, 8);
i_icmp_ack2(64) <= CONV_STD_LOGIC_VECTOR(16#77#, 8);
i_icmp_ack2(65) <= CONV_STD_LOGIC_VECTOR(16#61#, 8);
i_icmp_ack2(66) <= CONV_STD_LOGIC_VECTOR(16#62#, 8);
i_icmp_ack2(67) <= CONV_STD_LOGIC_VECTOR(16#63#, 8);
i_icmp_ack2(68) <= CONV_STD_LOGIC_VECTOR(16#64#, 8);
i_icmp_ack2(69) <= CONV_STD_LOGIC_VECTOR(16#65#, 8);
i_icmp_ack2(70) <= CONV_STD_LOGIC_VECTOR(16#66#, 8);
i_icmp_ack2(71) <= CONV_STD_LOGIC_VECTOR(16#67#, 8);
i_icmp_ack2(72) <= CONV_STD_LOGIC_VECTOR(16#68#, 8);
i_icmp_ack2(73) <= CONV_STD_LOGIC_VECTOR(16#69#, 8);


----------------------------------
--ICMP запрос 3
----------------------------------
-- MAC адреса
i_icmp_ack3(0)  <= i_eth_cfg.mac.src(0);
i_icmp_ack3(1)  <= i_eth_cfg.mac.src(1);
i_icmp_ack3(2)  <= i_eth_cfg.mac.src(2);
i_icmp_ack3(3)  <= i_eth_cfg.mac.src(3);
i_icmp_ack3(4)  <= i_eth_cfg.mac.src(4);
i_icmp_ack3(5)  <= i_eth_cfg.mac.src(5);
i_icmp_ack3(6)  <= i_dev.mac(0);
i_icmp_ack3(7)  <= i_dev.mac(1);
i_icmp_ack3(8)  <= i_dev.mac(2);
i_icmp_ack3(9)  <= i_dev.mac(3);
i_icmp_ack3(10) <= i_dev.mac(4);
i_icmp_ack3(11) <= i_dev.mac(5);
--Eth type
i_icmp_ack3(12) <= CI_ETH_TYPE_IP(15 downto 8);
i_icmp_ack3(13) <= CI_ETH_TYPE_IP( 7 downto 0);
--IP
i_icmp_ack3(14) <= CONV_STD_LOGIC_VECTOR(16#45#, 8); --IP: ver
i_icmp_ack3(15) <= (others=>'0'); --IP: ToS (тип обслуживания)
i_icmp_ack3(16) <= (others=>'0'); --IP: dlen
i_icmp_ack3(17) <= CONV_STD_LOGIC_VECTOR(16#3C#, 8);
i_icmp_ack3(18) <= CONV_STD_LOGIC_VECTOR(16#1F#, 8); --IP: id
i_icmp_ack3(19) <= CONV_STD_LOGIC_VECTOR(16#93#, 8);
i_icmp_ack3(20) <= (others=>'0'); --IP: flag
i_icmp_ack3(21) <= (others=>'0');
i_icmp_ack3(22) <= CONV_STD_LOGIC_VECTOR(16#80#, 8);--CI_IP_TTL;
i_icmp_ack3(23) <= CONV_STD_LOGIC_VECTOR(16#01#, 8);--; --IP: protocol
i_icmp_ack3(24) <= (others=>'0');-- when i_ip_crc_rdy='0' else i_ip_crc(15 downto 8); --IP: CRC
i_icmp_ack3(25) <= (others=>'0');-- when i_ip_crc_rdy='0' else i_ip_crc( 7 downto 0);
i_icmp_ack3(26) <= i_dev.ip(0); --IP: ip адрес отправителя ARP запроса
i_icmp_ack3(27) <= i_dev.ip(1);
i_icmp_ack3(28) <= i_dev.ip(2);
i_icmp_ack3(29) <= i_dev.ip(3);
i_icmp_ack3(30) <= i_eth_cfg.ip.src(0);
i_icmp_ack3(31) <= i_eth_cfg.ip.src(1);
i_icmp_ack3(32) <= i_eth_cfg.ip.src(2);
i_icmp_ack3(33) <= i_eth_cfg.ip.src(3);
--ICMP
i_icmp_ack3(34) <= CI_ICMP_OPER_REQUST;--ICMP: Operation
i_icmp_ack3(35) <= (others=>'0');
i_icmp_ack3(36) <= CONV_STD_LOGIC_VECTOR(16#4C#, 8);--ICMP: CRC
i_icmp_ack3(37) <= CONV_STD_LOGIC_VECTOR(16#DB#, 8);--;
i_icmp_ack3(38) <= CONV_STD_LOGIC_VECTOR(16#00#, 8);
i_icmp_ack3(39) <= CONV_STD_LOGIC_VECTOR(16#01#, 8);
i_icmp_ack3(40) <= CONV_STD_LOGIC_VECTOR(16#00#, 8);
i_icmp_ack3(41) <= CONV_STD_LOGIC_VECTOR(16#80#, 8);
i_icmp_ack3(42) <= CONV_STD_LOGIC_VECTOR(16#61#, 8);
i_icmp_ack3(43) <= CONV_STD_LOGIC_VECTOR(16#62#, 8);
i_icmp_ack3(44) <= CONV_STD_LOGIC_VECTOR(16#63#, 8);
i_icmp_ack3(45) <= CONV_STD_LOGIC_VECTOR(16#64#, 8);
i_icmp_ack3(46) <= CONV_STD_LOGIC_VECTOR(16#65#, 8);
i_icmp_ack3(47) <= CONV_STD_LOGIC_VECTOR(16#66#, 8);
i_icmp_ack3(48) <= CONV_STD_LOGIC_VECTOR(16#67#, 8);
i_icmp_ack3(49) <= CONV_STD_LOGIC_VECTOR(16#68#, 8);
i_icmp_ack3(50) <= CONV_STD_LOGIC_VECTOR(16#69#, 8);
i_icmp_ack3(51) <= CONV_STD_LOGIC_VECTOR(16#6A#, 8);
i_icmp_ack3(52) <= CONV_STD_LOGIC_VECTOR(16#6B#, 8);
i_icmp_ack3(53) <= CONV_STD_LOGIC_VECTOR(16#6C#, 8);
i_icmp_ack3(54) <= CONV_STD_LOGIC_VECTOR(16#6D#, 8);
i_icmp_ack3(55) <= CONV_STD_LOGIC_VECTOR(16#6E#, 8);
i_icmp_ack3(56) <= CONV_STD_LOGIC_VECTOR(16#6F#, 8);
i_icmp_ack3(57) <= CONV_STD_LOGIC_VECTOR(16#70#, 8);
i_icmp_ack3(58) <= CONV_STD_LOGIC_VECTOR(16#71#, 8);
i_icmp_ack3(59) <= CONV_STD_LOGIC_VECTOR(16#72#, 8);
i_icmp_ack3(60) <= CONV_STD_LOGIC_VECTOR(16#73#, 8);
i_icmp_ack3(61) <= CONV_STD_LOGIC_VECTOR(16#74#, 8);
i_icmp_ack3(62) <= CONV_STD_LOGIC_VECTOR(16#75#, 8);
i_icmp_ack3(63) <= CONV_STD_LOGIC_VECTOR(16#76#, 8);
i_icmp_ack3(64) <= CONV_STD_LOGIC_VECTOR(16#77#, 8);
i_icmp_ack3(65) <= CONV_STD_LOGIC_VECTOR(16#61#, 8);
i_icmp_ack3(66) <= CONV_STD_LOGIC_VECTOR(16#62#, 8);
i_icmp_ack3(67) <= CONV_STD_LOGIC_VECTOR(16#63#, 8);
i_icmp_ack3(68) <= CONV_STD_LOGIC_VECTOR(16#64#, 8);
i_icmp_ack3(69) <= CONV_STD_LOGIC_VECTOR(16#65#, 8);
i_icmp_ack3(70) <= CONV_STD_LOGIC_VECTOR(16#66#, 8);
i_icmp_ack3(71) <= CONV_STD_LOGIC_VECTOR(16#67#, 8);
i_icmp_ack3(72) <= CONV_STD_LOGIC_VECTOR(16#68#, 8);
i_icmp_ack3(73) <= CONV_STD_LOGIC_VECTOR(16#69#, 8);



----------------------------------
--UDP
----------------------------------
-- MAC адреса
i_udp(0)  <= i_eth_cfg.mac.src(0);
i_udp(1)  <= i_eth_cfg.mac.src(1);
i_udp(2)  <= i_eth_cfg.mac.src(2);
i_udp(3)  <= i_eth_cfg.mac.src(3);
i_udp(4)  <= i_eth_cfg.mac.src(4);
i_udp(5)  <= i_eth_cfg.mac.src(5);
i_udp(6)  <= i_dev.mac(0);
i_udp(7)  <= i_dev.mac(1);
i_udp(8)  <= i_dev.mac(2);
i_udp(9)  <= i_dev.mac(3);
i_udp(10) <= i_dev.mac(4);
i_udp(11) <= i_dev.mac(5);
--Eth type
i_udp(12) <= CI_ETH_TYPE_IP(15 downto 8);
i_udp(13) <= CI_ETH_TYPE_IP( 7 downto 0);
--IP
i_udp(14) <= CONV_STD_LOGIC_VECTOR(16#45#, 8); --IP: ver
i_udp(15) <= (others=>'0'); --IP: ToS (тип обслуживания)
i_udp(16) <= (others=>'0'); --IP: dlen
i_udp(17) <= CONV_STD_LOGIC_VECTOR(16#3C#, 8);
i_udp(18) <= CONV_STD_LOGIC_VECTOR(16#1F#, 8); --IP: id
i_udp(19) <= CONV_STD_LOGIC_VECTOR(16#93#, 8);
i_udp(20) <= (others=>'0'); --IP: flag
i_udp(21) <= (others=>'0');
i_udp(22) <= CONV_STD_LOGIC_VECTOR(16#80#, 8);--CI_IP_TTL;
i_udp(23) <= CONV_STD_LOGIC_VECTOR(17, 8);--; --IP: protocol
i_udp(24) <= (others=>'0');-- when i_ip_crc_rdy='0' else i_ip_crc(15 downto 8); --IP: CRC
i_udp(25) <= (others=>'0');-- when i_ip_crc_rdy='0' else i_ip_crc( 7 downto 0);
i_udp(26) <= i_dev.ip(0); --IP: ip адрес отправителя ARP запроса
i_udp(27) <= i_dev.ip(1);
i_udp(28) <= i_dev.ip(2);
i_udp(29) <= i_dev.ip(3);
i_udp(30) <= i_eth_cfg.ip.src(0);
i_udp(31) <= i_eth_cfg.ip.src(1);
i_udp(32) <= i_eth_cfg.ip.src(2);
i_udp(33) <= i_eth_cfg.ip.src(3);
--UDP
i_udp(34) <= i_dev.prt(15 downto 8);--UDP: SRC PORT
i_udp(35) <= i_dev.prt( 7 downto 0);
i_udp(36) <= i_eth_cfg.prt.src(15 downto 8);--UDP: DST PORT
i_udp(37) <= i_eth_cfg.prt.src( 7 downto 0);
i_udp(38) <= CONV_STD_LOGIC_VECTOR(16#00#, 8);--UDP: DLEN=Data(byte) + 8(UDP header)
i_udp(39) <= CONV_STD_LOGIC_VECTOR(10 + 8, 8);
i_udp(40) <= CONV_STD_LOGIC_VECTOR(16#00#, 8);--UDP: CRC
i_udp(41) <= CONV_STD_LOGIC_VECTOR(16#00#, 8);
i_udp(42) <= CONV_STD_LOGIC_VECTOR(16#61#, 8);--UDP: DATA
i_udp(43) <= CONV_STD_LOGIC_VECTOR(16#62#, 8);
i_udp(44) <= CONV_STD_LOGIC_VECTOR(16#63#, 8);
i_udp(45) <= CONV_STD_LOGIC_VECTOR(16#64#, 8);
i_udp(46) <= CONV_STD_LOGIC_VECTOR(16#65#, 8);
i_udp(47) <= CONV_STD_LOGIC_VECTOR(16#66#, 8);
i_udp(48) <= CONV_STD_LOGIC_VECTOR(16#67#, 8);
i_udp(49) <= CONV_STD_LOGIC_VECTOR(16#68#, 8);
i_udp(50) <= CONV_STD_LOGIC_VECTOR(16#69#, 8);
i_udp(51) <= CONV_STD_LOGIC_VECTOR(16#6A#, 8);
i_udp(52) <= (others=>'0');--CONV_STD_LOGIC_VECTOR(16#6B#, 8);
i_udp(53) <= (others=>'0');--CONV_STD_LOGIC_VECTOR(16#6C#, 8);
i_udp(54) <= (others=>'0');--CONV_STD_LOGIC_VECTOR(16#6D#, 8);
i_udp(55) <= (others=>'0');--CONV_STD_LOGIC_VECTOR(16#6E#, 8);
i_udp(56) <= (others=>'0');--CONV_STD_LOGIC_VECTOR(16#6F#, 8);
i_udp(57) <= (others=>'0');--CONV_STD_LOGIC_VECTOR(16#70#, 8);
i_udp(58) <= (others=>'0');--CONV_STD_LOGIC_VECTOR(16#71#, 8);
i_udp(59) <= (others=>'0');--CONV_STD_LOGIC_VECTOR(16#72#, 8);
i_udp(60) <= (others=>'0');--CONV_STD_LOGIC_VECTOR(16#73#, 8);
i_udp(61) <= (others=>'0');--CONV_STD_LOGIC_VECTOR(16#74#, 8);
i_udp(62) <= (others=>'0');--CONV_STD_LOGIC_VECTOR(16#75#, 8);
i_udp(63) <= (others=>'0');--CONV_STD_LOGIC_VECTOR(16#76#, 8);
i_udp(64) <= (others=>'0');--CONV_STD_LOGIC_VECTOR(16#77#, 8);
i_udp(65) <= (others=>'0');--CONV_STD_LOGIC_VECTOR(16#61#, 8);
i_udp(66) <= (others=>'0');--CONV_STD_LOGIC_VECTOR(16#62#, 8);
i_udp(67) <= (others=>'0');--CONV_STD_LOGIC_VECTOR(16#63#, 8);
i_udp(68) <= (others=>'0');--CONV_STD_LOGIC_VECTOR(16#64#, 8);
i_udp(69) <= (others=>'0');--CONV_STD_LOGIC_VECTOR(16#65#, 8);
i_udp(70) <= (others=>'0');--CONV_STD_LOGIC_VECTOR(16#66#, 8);
i_udp(71) <= (others=>'0');--CONV_STD_LOGIC_VECTOR(16#67#, 8);
i_udp(72) <= (others=>'0');--CONV_STD_LOGIC_VECTOR(16#68#, 8);
i_udp(73) <= (others=>'0');--CONV_STD_LOGIC_VECTOR(16#69#, 8);



--END MAIN
end;

