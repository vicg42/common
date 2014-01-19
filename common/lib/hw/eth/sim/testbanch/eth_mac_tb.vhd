-------------------------------------------------------------------------
-- Company     : Linkos
-- Engineer    : Golovachenko Victor
--
-- Create Date : 31.03.2011 19:15:18
-- Module Name : eth_mac_tb
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

entity eth_mac_tb is
generic(
G_USR_DBUS: integer:=64;
G_ETH_CORE_DBUS: integer:=64;
G_ETH_CORE_DBUS_SWP: integer:=1; --1/0 Поле Length/Type первый мл./ст. байт (0 - по стандарту!!! 1 - как в проекте Вереск)
G_DBG : string:="ON";
G_SIM : string:="ON"
);
port(
--p_out_txll_data      : out   std_logic_vector(G_ETH_CORE_DBUS-1 downto 0);
--p_out_txll_sof_n     : out   std_logic;
--p_out_txll_eof_n     : out   std_logic;
--p_out_txll_src_rdy_n : out   std_logic;
----p_in_txll_dst_rdy_n  : in    std_logic;
--p_out_txll_rem       : out   std_logic_vector(0 downto 0)
tttt: OUT std_logic_vector(31 downto 0);
p_out_rxbuf_din       : out   std_logic_vector(G_USR_DBUS-1 downto 0);
p_out_rxbuf_wr        : out   std_logic;
--p_in_rxbuf_full       : in    std_logic;
p_out_rxd_sof         : out   std_logic;
p_out_rxd_eof         : out   std_logic
);
end eth_mac_tb;

architecture behavior of eth_mac_tb is

constant C_ETH_GT_REFCLK_PERIOD : TIME := 6.6 ns; --150MHz
constant C_ETH_GT_DRPCLK_PERIOD : TIME := 6.6*8 ns;
constant C_CFG_PERIOD           : TIME := 6.6*5 ns;

signal ttt_rd, ttt_empty : std_logic;

component ethg_vctrl_rxfifo
port(
din         : IN  std_logic_vector(127 downto 0);
wr_en       : IN  std_logic;
wr_clk      : IN  std_logic;

dout        : OUT std_logic_vector(31 downto 0);
rd_en       : IN  std_logic;
rd_clk      : IN  std_logic;

empty       : OUT std_logic;
full        : OUT std_logic;
prog_full   : OUT std_logic;

rst         : IN  std_logic
);
end component;

component host_vbuf
  generic (
  G_DWIDTH : integer:= 32
  );
  PORT (
    rst : IN STD_LOGIC;
    wr_clk : IN STD_LOGIC;
    rd_clk : IN STD_LOGIC;
    din : IN STD_LOGIC_VECTOR(G_USR_DBUS - 1 DOWNTO 0);
    wr_en : IN STD_LOGIC;
    rd_en : IN STD_LOGIC;
    dout : OUT STD_LOGIC_VECTOR(G_USR_DBUS - 1 DOWNTO 0);
    full : OUT STD_LOGIC;
    empty : OUT STD_LOGIC;
    prog_full : OUT STD_LOGIC
  );
END component;

component eth_mac_rx
generic(
G_ETH : TEthGeneric;
G_DBG : string:="OFF";
G_SIM : string:="OFF"
);
port(
--------------------------------------
--Управление
--------------------------------------
p_in_cfg              : in    TEthCfg;

--------------------------------------
--Связь с пользовательским RXBUF
--------------------------------------
p_out_rxbuf_din       : out   std_logic_vector(G_ETH.usrbuf_dwidth - 1 downto 0);
p_out_rxbuf_wr        : out   std_logic;
p_in_rxbuf_full       : in    std_logic;
p_out_rxd_sof         : out   std_logic;
p_out_rxd_eof         : out   std_logic;

--------------------------------------
--Связь с Local link RxFIFO
--------------------------------------
p_in_rxll_data        : in    std_logic_vector(G_ETH.phy_dwidth - 1 downto 0);
p_in_rxll_sof_n       : in    std_logic;
p_in_rxll_eof_n       : in    std_logic;
p_in_rxll_src_rdy_n   : in    std_logic;
p_out_rxll_dst_rdy_n  : out   std_logic;
p_in_rxll_fifo_status : in    std_logic_vector(3 downto 0);
p_in_rxll_rem         : in    std_logic_vector((G_ETH.phy_dwidth / 8) - 1 downto 0);

--------------------------------------
--Управление передачей PAUSE Control Frame
--(более подробно см. ug194.pdf/Flow Control Block/Flow Control Implementation Example)
--------------------------------------
p_out_pause_req       : out   std_logic;
p_out_pause_val       : out   std_logic_vector(15 downto 0);

--------------------------------------------------
--Технологические сигналы
--------------------------------------------------
p_in_tst              : in    std_logic_vector(31 downto 0);
p_out_tst             : out   std_logic_vector(31 downto 0);

--------------------------------------
--SYSTEM
--------------------------------------
p_in_clk              : in    std_logic;
p_in_rst              : in    std_logic
);
end component;


component eth_mac_tx
generic(
G_ETH : TEthGeneric;
G_DBG : string:="OFF";
G_SIM : string:="OFF"
);
port(
--------------------------------------
--Управление
--------------------------------------
p_in_cfg             : in    TEthCfg;

--------------------------------------
--Связь с пользовательским TXBUF
--------------------------------------
p_in_txbuf_dout      : in    std_logic_vector(G_ETH.usrbuf_dwidth - 1 downto 0);
p_out_txbuf_rd       : out   std_logic;
p_in_txbuf_empty     : in    std_logic;
--p_in_txd_rdy         : in    std_logic;

--------------------------------------
--Связь с Local link TxFIFO
--------------------------------------
p_out_txll_data      : out   std_logic_vector(G_ETH.phy_dwidth - 1 downto 0);
p_out_txll_sof_n     : out   std_logic;
p_out_txll_eof_n     : out   std_logic;
p_out_txll_src_rdy_n : out   std_logic;
p_in_txll_dst_rdy_n  : in    std_logic;
p_out_txll_rem       : out   std_logic_vector((G_ETH.phy_dwidth / 8) - 1 downto 0);

--------------------------------------------------
--Технологические сигналы
--------------------------------------------------
p_in_tst             : in    std_logic_vector(31 downto 0);
p_out_tst            : out   std_logic_vector(31 downto 0);

--------------------------------------
--SYSTEM
--------------------------------------
p_in_clk             : in    std_logic;
p_in_rst             : in    std_logic
);
end component;

signal i_clk                      : std_logic;
signal i_rst                      : std_logic;

signal i_eth_tx_cfg               : TEthCfg;
signal i_eth_rx_cfg               : TEthCfg;

signal i_txbuf_dout               : std_logic_vector(G_USR_DBUS-1 downto 0);
signal i_txbuf_rd                 : std_logic;
signal i_txbuf_empty              : std_logic;

signal i_data                     : std_logic_vector(G_USR_DBUS-1 downto 0);
signal i_data_wr                  : std_logic;

signal p_out_txll_data            : std_logic_vector(G_ETH_CORE_DBUS-1 downto 0);
signal p_out_txll_sof_n           : std_logic;
signal p_out_txll_eof_n           : std_logic;
signal p_out_txll_src_rdy_n       : std_logic;
signal p_in_txll_dst_rdy_n        : std_logic;
signal p_out_txll_rem             : std_logic_vector((G_ETH_CORE_DBUS / 8) - 1 downto 0);

signal p_in_rxbuf_full            : std_logic:='0';
signal i_rxbuf_full               : std_logic:='0';

signal i_txll_eof_n     : std_logic;
signal i_txll_src_rdy_n : std_logic;

signal sr_dly      : std_logic_vector(0 to 7);
signal tst_src_rdy : std_logic;

--MAIN
begin


m_rx : eth_mac_rx
generic map(
G_ETH.ch_count        => C_PCFG_ETH_COUNT,
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
p_in_cfg             => i_eth_rx_cfg,

--------------------------------------
--Связь с пользовательским RXBUF
--------------------------------------
p_out_rxbuf_din       => p_out_rxbuf_din,
p_out_rxbuf_wr        => p_out_rxbuf_wr ,
p_in_rxbuf_full       => p_in_rxbuf_full,
p_out_rxd_sof         => p_out_rxd_sof  ,
p_out_rxd_eof         => p_out_rxd_eof  ,

--------------------------------------
--Связь с Local link RxFIFO
--------------------------------------
p_in_rxll_data        => p_out_txll_data     ,
p_in_rxll_sof_n       => p_out_txll_sof_n    ,
p_in_rxll_eof_n       => p_out_txll_eof_n    ,
p_in_rxll_src_rdy_n   => p_out_txll_src_rdy_n,
p_out_rxll_dst_rdy_n  => p_in_txll_dst_rdy_n ,
p_in_rxll_fifo_status => (others=>'0')       ,
p_in_rxll_rem         => p_out_txll_rem      ,

--------------------------------------
--Управление передачей PAUSE Control Frame
--(более подробно см. ug194.pdf/Flow Control Block/Flow Control Implementation Example)
--------------------------------------
p_out_pause_req       => open,
p_out_pause_val       => open,

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


m_tx : eth_mac_tx
generic map(
G_ETH.ch_count        => C_PCFG_ETH_COUNT,
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
p_in_cfg             => i_eth_tx_cfg,

--------------------------------------
--Связь с пользовательским TXBUF
--------------------------------------
p_in_txbuf_dout      => i_txbuf_dout ,
p_out_txbuf_rd       => i_txbuf_rd   ,
p_in_txbuf_empty     => i_txbuf_empty,
--p_in_txd_rdy         : in    std_logic;

--------------------------------------
--Связь с Local link TxFIFO
--------------------------------------
p_out_txll_data      => p_out_txll_data     ,
p_out_txll_sof_n     => p_out_txll_sof_n    ,
p_out_txll_eof_n     => i_txll_eof_n    ,--p_out_txll_eof_n    ,
p_out_txll_src_rdy_n => i_txll_src_rdy_n,--p_out_txll_src_rdy_n,
p_in_txll_dst_rdy_n  => p_in_txll_dst_rdy_n ,--'0',--
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


p_out_txll_eof_n <= i_txll_eof_n;
p_out_txll_src_rdy_n <= i_txll_src_rdy_n;

--p_out_txll_eof_n     <= sr_dly(7);
--p_out_txll_src_rdy_n <= i_txll_src_rdy_n and not tst_src_rdy;
--
--process(i_rst, i_clk)
--begin
--  if i_rst = '1' then
--    sr_dly <= (others=>'1');
--    tst_src_rdy <= '0';
--  elsif rising_edge(i_clk) then
--    sr_dly <= i_txll_eof_n & sr_dly(0 to 6);
--
--    if p_out_txll_sof_n = '0' then
--      tst_src_rdy <= '1';
--    elsif sr_dly(7) = '0' then
--      tst_src_rdy <= '0';
--    end if;
--
--  end if;
--end process;


gen_clk : process
begin
  i_clk<='0';
  wait for C_CFG_PERIOD/2;
  i_clk<='1';
  wait for C_CFG_PERIOD/2;
end process;

i_rst<='1','0' after 1 us;



----########################################
----Main Ctrl (G_USR_DBUS - 32bit)
----########################################
--gen_mac_a : for i in 0 to i_eth_tx_cfg.mac.dst'length - 1 generate
--i_eth_tx_cfg.mac.dst(i) <= CONV_STD_LOGIC_VECTOR(i + 10, i_eth_tx_cfg.mac.dst(i)'length) ;
--i_eth_tx_cfg.mac.src(i) <= CONV_STD_LOGIC_VECTOR(i + 10 + i_eth_tx_cfg.mac.dst'length, i_eth_tx_cfg.mac.src(i)'length) ;
--end generate gen_mac_a;
--i_eth_tx_cfg.mac.lentype <= CONV_STD_LOGIC_VECTOR(16#8C#, i_eth_tx_cfg.mac.lentype'length);
--i_eth_tx_cfg.usrctrl <= (others=>'0');
--
--i_eth_rx_cfg.mac.dst <= i_eth_tx_cfg.mac.src;
--i_eth_rx_cfg.mac.src <= i_eth_tx_cfg.mac.dst;
--i_eth_rx_cfg.mac.lentype <= i_eth_tx_cfg.mac.lentype;
--i_eth_rx_cfg.usrctrl <= i_eth_tx_cfg.usrctrl;
--
--process
--begin
----  p_in_txll_dst_rdy_n<='0';
--  p_in_rxbuf_full <= '0';
--  i_data <= (others=>'0');
--  i_data_wr <= '0';
--
--  wait for 2 us;
--
--  wait until i_clk'event and i_clk = '1';
--  i_data_wr <= '1';
--  i_data <= CONV_STD_LOGIC_VECTOR(16#0201#, G_USR_DBUS/2) & i_eth_tx_cfg.mac.lentype;
--
--  wait until i_clk'event and i_clk = '1';
--  i_data_wr <= '1';
--  i_data <= CONV_STD_LOGIC_VECTOR(16#0605#, G_USR_DBUS/2) & CONV_STD_LOGIC_VECTOR(16#0403#, G_USR_DBUS/2);
--
--  wait until i_clk'event and i_clk = '1';
--  i_data_wr <= '1';
--  i_data <= CONV_STD_LOGIC_VECTOR(16#0A09#, G_USR_DBUS/2) & CONV_STD_LOGIC_VECTOR(16#0807#, G_USR_DBUS/2);
--
--  wait until i_clk'event and i_clk = '1';
--  i_data_wr <= '1';
--  i_data <= CONV_STD_LOGIC_VECTOR(16#0E0D#, G_USR_DBUS/2) & CONV_STD_LOGIC_VECTOR(16#0C0B#, G_USR_DBUS/2);
--
--  wait until i_clk'event and i_clk = '1';
--  i_data_wr <= '1';
--  i_data <= CONV_STD_LOGIC_VECTOR(16#1211#, G_USR_DBUS/2) & CONV_STD_LOGIC_VECTOR(16#100F#, G_USR_DBUS/2);
--
--  wait until i_clk'event and i_clk = '1';
--  i_data_wr <= '1';
--  i_data <= CONV_STD_LOGIC_VECTOR(16#1615#, G_USR_DBUS/2) & CONV_STD_LOGIC_VECTOR(16#1413#, G_USR_DBUS/2);
--
--  wait until i_clk'event and i_clk = '1';
--  i_data_wr <= '1';
--  i_data <= CONV_STD_LOGIC_VECTOR(16#1A19#, G_USR_DBUS/2) & CONV_STD_LOGIC_VECTOR(16#1817#, G_USR_DBUS/2);
--
--  wait until i_clk'event and i_clk = '1';
--  i_data_wr <= '1';
--  i_data <= CONV_STD_LOGIC_VECTOR(16#1E1D#, G_USR_DBUS/2) & CONV_STD_LOGIC_VECTOR(16#1C1B#, G_USR_DBUS/2);
--
--
--  wait until i_clk'event and i_clk = '1';
--  i_data_wr <= '1';
--  i_data <= CONV_STD_LOGIC_VECTOR(16#2221#, G_USR_DBUS/2) & CONV_STD_LOGIC_VECTOR(16#201F#, G_USR_DBUS/2);
--
--  wait until i_clk'event and i_clk = '1';
--  i_data_wr <= '1';
--  i_data <= CONV_STD_LOGIC_VECTOR(16#2625#, G_USR_DBUS/2) & CONV_STD_LOGIC_VECTOR(16#2423#, G_USR_DBUS/2);
--
--  wait until i_clk'event and i_clk = '1';
--  i_data_wr <= '1';
--  i_data <= CONV_STD_LOGIC_VECTOR(16#2A29#, G_USR_DBUS/2) & CONV_STD_LOGIC_VECTOR(16#2827#, G_USR_DBUS/2);
--
--  wait until i_clk'event and i_clk = '1';
--  i_data_wr <= '1';
--  i_data <= CONV_STD_LOGIC_VECTOR(16#2E2D#, G_USR_DBUS/2) & CONV_STD_LOGIC_VECTOR(16#2C2B#, G_USR_DBUS/2);
--
--
--
--  wait until i_clk'event and i_clk = '1';
--  i_data_wr <= '1';
--  i_data <= CONV_STD_LOGIC_VECTOR(16#3231#, G_USR_DBUS/2) & CONV_STD_LOGIC_VECTOR(16#302F#, G_USR_DBUS/2);
--
--  wait until i_clk'event and i_clk = '1';
--  i_data_wr <= '1';
--  i_data <= CONV_STD_LOGIC_VECTOR(16#3635#, G_USR_DBUS/2) & CONV_STD_LOGIC_VECTOR(16#3433#, G_USR_DBUS/2);
--
--  wait until i_clk'event and i_clk = '1';
--  i_data_wr <= '1';
--  i_data <= CONV_STD_LOGIC_VECTOR(16#3A39#, G_USR_DBUS/2) & CONV_STD_LOGIC_VECTOR(16#3837#, G_USR_DBUS/2);
--
--  wait until i_clk'event and i_clk = '1';
--  i_data_wr <= '1';
--  i_data <= CONV_STD_LOGIC_VECTOR(16#3E3D#, G_USR_DBUS/2) & CONV_STD_LOGIC_VECTOR(16#3C3B#, G_USR_DBUS/2);
--
--
--
--  wait until i_clk'event and i_clk = '1';
--  i_data_wr <= '1';
--  i_data <= CONV_STD_LOGIC_VECTOR(16#4241#, G_USR_DBUS/2) & CONV_STD_LOGIC_VECTOR(16#403F#, G_USR_DBUS/2);
--
--  wait until i_clk'event and i_clk = '1';
--  i_data_wr <= '1';
--  i_data <= CONV_STD_LOGIC_VECTOR(16#4645#, G_USR_DBUS/2) & CONV_STD_LOGIC_VECTOR(16#4443#, G_USR_DBUS/2);
--
--  wait until i_clk'event and i_clk = '1';
--  i_data_wr <= '1';
--  i_data <= CONV_STD_LOGIC_VECTOR(16#4A49#, G_USR_DBUS/2) & CONV_STD_LOGIC_VECTOR(16#4847#, G_USR_DBUS/2);
--
--  wait until i_clk'event and i_clk = '1';
--  i_data_wr <= '1';
--  i_data <= CONV_STD_LOGIC_VECTOR(16#4E4D#, G_USR_DBUS/2) & CONV_STD_LOGIC_VECTOR(16#4C4B#, G_USR_DBUS/2);
--
--
--
--  wait until i_clk'event and i_clk = '1';
--  i_data_wr <= '1';
--  i_data <= CONV_STD_LOGIC_VECTOR(16#5251#, G_USR_DBUS/2) & CONV_STD_LOGIC_VECTOR(16#504F#, G_USR_DBUS/2);
--
--  wait until i_clk'event and i_clk = '1';
--  i_data_wr <= '1';
--  i_data <= CONV_STD_LOGIC_VECTOR(16#5655#, G_USR_DBUS/2) & CONV_STD_LOGIC_VECTOR(16#5453#, G_USR_DBUS/2);
--
--  wait until i_clk'event and i_clk = '1';
--  i_data_wr <= '1';
--  i_data <= CONV_STD_LOGIC_VECTOR(16#5A59#, G_USR_DBUS/2) & CONV_STD_LOGIC_VECTOR(16#5857#, G_USR_DBUS/2);
--
--  wait until i_clk'event and i_clk = '1';
--  i_data_wr <= '1';
--  i_data <= CONV_STD_LOGIC_VECTOR(16#5E5D#, G_USR_DBUS/2) & CONV_STD_LOGIC_VECTOR(16#5C5B#, G_USR_DBUS/2);
--
--
--
--  wait until i_clk'event and i_clk = '1';
--  i_data_wr <= '1';
--  i_data <= CONV_STD_LOGIC_VECTOR(16#6261#, G_USR_DBUS/2) & CONV_STD_LOGIC_VECTOR(16#605F#, G_USR_DBUS/2);
--
--  wait until i_clk'event and i_clk = '1';
--  i_data_wr <= '1';
--  i_data <= CONV_STD_LOGIC_VECTOR(16#6665#, G_USR_DBUS/2) & CONV_STD_LOGIC_VECTOR(16#6463#, G_USR_DBUS/2);
--
--  wait until i_clk'event and i_clk = '1';
--  i_data_wr <= '1';
--  i_data <= CONV_STD_LOGIC_VECTOR(16#6A69#, G_USR_DBUS/2) & CONV_STD_LOGIC_VECTOR(16#6867#, G_USR_DBUS/2);
--
--  wait until i_clk'event and i_clk = '1';
--  i_data_wr <= '1';
--  i_data <= CONV_STD_LOGIC_VECTOR(16#6E6D#, G_USR_DBUS/2) & CONV_STD_LOGIC_VECTOR(16#6C6B#, G_USR_DBUS/2);
--
--
--
--  wait until i_clk'event and i_clk = '1';
--  i_data_wr <= '1';
--  i_data <= CONV_STD_LOGIC_VECTOR(16#7271#, G_USR_DBUS/2) & CONV_STD_LOGIC_VECTOR(16#706F#, G_USR_DBUS/2);
--
--  wait until i_clk'event and i_clk = '1';
--  i_data_wr <= '1';
--  i_data <= CONV_STD_LOGIC_VECTOR(16#7675#, G_USR_DBUS/2) & CONV_STD_LOGIC_VECTOR(16#7473#, G_USR_DBUS/2);
--
--  wait until i_clk'event and i_clk = '1';
--  i_data_wr <= '1';
--  i_data <= CONV_STD_LOGIC_VECTOR(16#7A79#, G_USR_DBUS/2) & CONV_STD_LOGIC_VECTOR(16#7877#, G_USR_DBUS/2);
--
--  wait until i_clk'event and i_clk = '1';
--  i_data_wr <= '1';
--  i_data <= CONV_STD_LOGIC_VECTOR(16#7E7D#, G_USR_DBUS/2) & CONV_STD_LOGIC_VECTOR(16#7C7B#, G_USR_DBUS/2);
--
--
--
--  wait until i_clk'event and i_clk = '1';
--  i_data_wr <= '1';
--  i_data <= CONV_STD_LOGIC_VECTOR(16#8281#, G_USR_DBUS/2) & CONV_STD_LOGIC_VECTOR(16#807F#, G_USR_DBUS/2);
--
--  wait until i_clk'event and i_clk = '1';
--  i_data_wr <= '1';
--  i_data <= CONV_STD_LOGIC_VECTOR(16#8685#, G_USR_DBUS/2) & CONV_STD_LOGIC_VECTOR(16#8483#, G_USR_DBUS/2);
--
--  wait until i_clk'event and i_clk = '1';
--  i_data_wr <= '1';
--  i_data <= CONV_STD_LOGIC_VECTOR(16#8A89#, G_USR_DBUS/2) & CONV_STD_LOGIC_VECTOR(16#8887#, G_USR_DBUS/2);
--
--  wait until i_clk'event and i_clk = '1';
--  i_data_wr <= '1';
--  i_data <= CONV_STD_LOGIC_VECTOR(16#8E8D#, G_USR_DBUS/2) & CONV_STD_LOGIC_VECTOR(16#8C8B#, G_USR_DBUS/2);
--
--
--  wait until i_clk'event and i_clk = '1';
--  i_data_wr <= '0';
--
--  wait;
--end process;



--########################################
--Main Ctrl (G_USR_DBUS - 64bit)
--########################################
gen_mac_a : for i in 0 to i_eth_tx_cfg.mac.dst'length - 1 generate
i_eth_tx_cfg.mac.dst(i) <= CONV_STD_LOGIC_VECTOR(i + 16#E0#, i_eth_tx_cfg.mac.dst(i)'length) ;
i_eth_tx_cfg.mac.src(i) <= CONV_STD_LOGIC_VECTOR(i + 16#F0#, i_eth_tx_cfg.mac.src(i)'length) ;
end generate gen_mac_a;
i_eth_tx_cfg.mac.lentype <= CONV_STD_LOGIC_VECTOR(16#25#, i_eth_tx_cfg.mac.lentype'length);
i_eth_tx_cfg.usrctrl <= (others=>'0');

i_eth_rx_cfg.mac.dst <= i_eth_tx_cfg.mac.src;
i_eth_rx_cfg.mac.src <= i_eth_tx_cfg.mac.dst;
i_eth_rx_cfg.mac.lentype <= i_eth_tx_cfg.mac.lentype;
i_eth_rx_cfg.usrctrl <= i_eth_tx_cfg.usrctrl;

process
begin
  i_data <= (others=>'0');
  i_data_wr <= '0';

  wait for 2 us;

  wait until i_clk'event and i_clk = '1';
  i_data_wr <= '1';
  i_data(31 downto 0)  <= CONV_STD_LOGIC_VECTOR(16#0201#, 16) & i_eth_tx_cfg.mac.lentype;
  i_data(63 downto 32) <= CONV_STD_LOGIC_VECTOR(16#0605#, 16) & CONV_STD_LOGIC_VECTOR(16#0403#, 16);

--  wait until i_clk'event and i_clk = '1';
--  i_data_wr <= '0';
--
--  wait for 200 ns;
--
  wait until i_clk'event and i_clk = '1';
  i_data_wr <= '1';
  i_data(31 downto 0)  <= CONV_STD_LOGIC_VECTOR(16#0A09#, 16) & CONV_STD_LOGIC_VECTOR(16#0807#, 16);
  i_data(63 downto 32) <= CONV_STD_LOGIC_VECTOR(16#0E0D#, 16) & CONV_STD_LOGIC_VECTOR(16#0C0B#, 16);

  wait until i_clk'event and i_clk = '1';
  i_data_wr <= '1';
  i_data(31 downto 0)  <= CONV_STD_LOGIC_VECTOR(16#1211#, 16) & CONV_STD_LOGIC_VECTOR(16#100F#, 16);
  i_data(63 downto 32) <= CONV_STD_LOGIC_VECTOR(16#1615#, 16) & CONV_STD_LOGIC_VECTOR(16#1413#, 16);

  wait until i_clk'event and i_clk = '1';
  i_data_wr <= '0';

  wait for 200 ns;

  wait until i_clk'event and i_clk = '1';
  i_data_wr <= '1';
  i_data(31 downto 0)  <= CONV_STD_LOGIC_VECTOR(16#1A19#, 16) & CONV_STD_LOGIC_VECTOR(16#1817#, 16);
  i_data(63 downto 32) <= CONV_STD_LOGIC_VECTOR(16#1E1D#, 16) & CONV_STD_LOGIC_VECTOR(16#1C1B#, 16);

  wait until i_clk'event and i_clk = '1';
  i_data_wr <= '1';
  i_data(31 downto 0)  <= CONV_STD_LOGIC_VECTOR(16#2221#, 16) & CONV_STD_LOGIC_VECTOR(16#201F#, 16);
  i_data(63 downto 32) <= CONV_STD_LOGIC_VECTOR(16#2625#, 16) & CONV_STD_LOGIC_VECTOR(16#2423#, 16);
--
--  wait until i_clk'event and i_clk = '1';
--  i_data_wr <= '0';
--
--  wait for 200 ns;
--
--  wait until i_clk'event and i_clk = '1';
--  i_data_wr <= '1';
--  i_data(31 downto 0)  <= CONV_STD_LOGIC_VECTOR(16#2A29#, 16) & CONV_STD_LOGIC_VECTOR(16#2827#, 16);
--  i_data(63 downto 32) <= CONV_STD_LOGIC_VECTOR(16#2E2D#, 16) & CONV_STD_LOGIC_VECTOR(16#2C2B#, 16);

  wait until i_clk'event and i_clk = '1';
  i_data_wr <= '0';

  wait;
end process;


i_rxbuf_full <= '0';--, '1' after 2950000 ps, '0' after 3000000 ps;

process(i_clk)
begin
  if rising_edge(i_clk) then
    p_in_rxbuf_full <= i_rxbuf_full;
  end if;
end process;

m_buf : host_vbuf
generic map(
G_DWIDTH => G_USR_DBUS
)
port map(
din => i_data,
wr_en => i_data_wr,
wr_clk => i_clk,

dout => i_txbuf_dout,
rd_en => i_txbuf_rd,
rd_clk => i_clk,

full => open,
empty => i_txbuf_empty,
prog_full => open,
rst => i_rst
);




----########################################
----Main Ctrl (G_USR_DBUS - 128bit)
----########################################
--gen_mac_a : for i in 0 to i_eth_tx_cfg.mac.dst'length - 1 generate
--i_eth_tx_cfg.mac.dst(i) <= CONV_STD_LOGIC_VECTOR(i + 16#E0#, i_eth_tx_cfg.mac.dst(i)'length) ;
--i_eth_tx_cfg.mac.src(i) <= CONV_STD_LOGIC_VECTOR(i + 16#F0#, i_eth_tx_cfg.mac.src(i)'length) ;
--end generate gen_mac_a;
--i_eth_tx_cfg.mac.lentype <= CONV_STD_LOGIC_VECTOR(16#F#, i_eth_tx_cfg.mac.lentype'length);
--i_eth_tx_cfg.usrctrl <= (others=>'0');
--
--i_eth_rx_cfg.mac.dst <= i_eth_tx_cfg.mac.src;
--i_eth_rx_cfg.mac.src <= i_eth_tx_cfg.mac.dst;
--i_eth_rx_cfg.mac.lentype <= i_eth_tx_cfg.mac.lentype;
--i_eth_rx_cfg.usrctrl <= i_eth_tx_cfg.usrctrl;
--
--process
--begin
--  i_data <= (others=>'0');
--  i_data_wr <= '0';
--
--  wait for 2 us;
--
--  wait until i_clk'event and i_clk = '1';
--  i_data_wr <= '1';
--  i_data(32*1 - 1 downto 32*0) <= CONV_STD_LOGIC_VECTOR(16#0201#, 16) & i_eth_tx_cfg.mac.lentype;
--  i_data(32*2 - 1 downto 32*1) <= CONV_STD_LOGIC_VECTOR(16#0605#, 16) & CONV_STD_LOGIC_VECTOR(16#0403#, 16);
--  i_data(32*3 - 1 downto 32*2) <= CONV_STD_LOGIC_VECTOR(16#0A09#, 16) & CONV_STD_LOGIC_VECTOR(16#0807#, 16);
--  i_data(32*4 - 1 downto 32*3) <= CONV_STD_LOGIC_VECTOR(16#0E0D#, 16) & CONV_STD_LOGIC_VECTOR(16#0C0B#, 16);
--
----  wait until i_clk'event and i_clk = '1';
----  i_data_wr <= '0';
----
----  wait for 200 ns;
--
--  wait until i_clk'event and i_clk = '1';
--  i_data_wr <= '1';
--  i_data(32*1 - 1 downto 32*0) <= CONV_STD_LOGIC_VECTOR(16#1211#, 16) & CONV_STD_LOGIC_VECTOR(16#100F#, 16);
--  i_data(32*2 - 1 downto 32*1) <= CONV_STD_LOGIC_VECTOR(16#1615#, 16) & CONV_STD_LOGIC_VECTOR(16#1413#, 16);
--  i_data(32*3 - 1 downto 32*2) <= CONV_STD_LOGIC_VECTOR(16#1A19#, 16) & CONV_STD_LOGIC_VECTOR(16#1817#, 16);
--  i_data(32*4 - 1 downto 32*3) <= CONV_STD_LOGIC_VECTOR(16#1E1D#, 16) & CONV_STD_LOGIC_VECTOR(16#1C1B#, 16);
--
----
----  wait for 200 ns;
----
----  wait until i_clk'event and i_clk = '1';
----  i_data_wr <= '1';
----  i_data(31 downto 0)  <= CONV_STD_LOGIC_VECTOR(16#2A29#, 16) & CONV_STD_LOGIC_VECTOR(16#2827#, 16);
----  i_data(63 downto 32) <= CONV_STD_LOGIC_VECTOR(16#2E2D#, 16) & CONV_STD_LOGIC_VECTOR(16#2C2B#, 16);
--
--  wait until i_clk'event and i_clk = '1';
--  i_data_wr <= '0';
--
--  wait;
--end process;
--
--
--i_rxbuf_full <= '0';--, '1' after 2950000 ps, '0' after 3000000 ps;
--
--process(i_clk)
--begin
--  if rising_edge(i_clk) then
--    p_in_rxbuf_full <= i_rxbuf_full;
--  end if;
--end process;
--
--
--
--
--m_buf : host_vbuf
--generic map(
--G_DWIDTH => G_USR_DBUS
--)
--port map(
--din => i_data,
--wr_en => i_data_wr,
--wr_clk => i_clk,
--
--dout => i_txbuf_dout,
--rd_en => i_txbuf_rd,
--rd_clk => i_clk,
--
--full => open,
--empty => i_txbuf_empty,
--prog_full => open,
--rst => i_rst
--);
--
--
--mm : ethg_vctrl_rxfifo
--port map(
--din => i_data,
--wr_en => i_data_wr,
--wr_clk => i_clk,
--
--dout        => tttt,--: OUT std_logic_vector(31 downto 0);
--rd_en       => ttt_rd,
--rd_clk      => i_clk,
--
--empty       => ttt_empty,--
--full        => open,--
--prog_full   => open,--
--
--rst         => i_rst
--);
--
--ttt_rd <= not ttt_empty;

--END MAIN
end;



