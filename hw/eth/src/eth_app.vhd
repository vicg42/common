-------------------------------------------------------------------------
-- Company     : Linkos
-- Engineer    : Golovachenko Victor
--
-- Create Date : 28.11.2011 15:06:14
-- Module Name : eth_app
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
use ieee.std_logic_unsigned.all;

library work;
use work.vicg_common_pkg.all;
use work.eth_pkg.all;
--use work.eth_unit_pkg.all;

entity eth_app is
generic(
G_ETH : TEthGeneric;
G_DBG : string:="OFF";
G_SIM : string:="OFF"
);
port(
--------------------------------------
--Eth USR
--------------------------------------
--настройка
p_in_ethcfg  : in    TEthCfgs;
--Связь с UsrBUF
p_out_eth    : out   TEthOUTs;
p_in_eth     : in    TEthINs;

--------------------------------------
--EthPhy<->EthApp
--------------------------------------
p_in_phy2app : in    TEthPhy2AppOUTs;
p_out_phy2app: out   TEthPhy2AppINs;

--------------------------------------
--EthPHY
--------------------------------------
p_in_phy     : in    TEthPhyOUT;

--------------------------------------
--Технологические сигналы
--------------------------------------
p_out_dbg    : out   TEthAppDBGs;
p_in_tst     : in    std_logic_vector(31 downto 0);
p_out_tst    : out   std_logic_vector(31 downto 0);

--------------------------------------
--System
--------------------------------------
p_in_rst     : in    std_logic
);
end eth_app;


architecture behavioral of eth_app is

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
p_out_rxbuf_din       : out   std_logic_vector(G_ETH.usrbuf_dwidth-1 downto 0);
p_out_rxbuf_wr        : out   std_logic;
p_in_rxbuf_full       : in    std_logic;
p_out_rxd_sof         : out   std_logic;
p_out_rxd_eof         : out   std_logic;

--------------------------------------
--Связь с Local link RxFIFO
--------------------------------------
p_in_rxll_data        : in    std_logic_vector(G_ETH.phy_dwidth-1 downto 0);
p_in_rxll_sof_n       : in    std_logic;
p_in_rxll_eof_n       : in    std_logic;
p_in_rxll_src_rdy_n   : in    std_logic;
p_out_rxll_dst_rdy_n  : out   std_logic;
p_in_rxll_fifo_status : in    std_logic_vector(3 downto 0);
p_in_rxll_rem         : in    std_logic_vector(G_ETH.phy_dwidth/8 - 1 downto 0);

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

--//------------------------------------
--//SYSTEM
--//------------------------------------
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
p_in_txbuf_dout      : in    std_logic_vector(G_ETH.usrbuf_dwidth-1 downto 0);
p_out_txbuf_rd       : out   std_logic;
p_in_txbuf_empty     : in    std_logic;
--p_in_txd_rdy         : in    std_logic;

--------------------------------------
--Связь с Local link TxFIFO
--------------------------------------
p_out_txll_data      : out   std_logic_vector(G_ETH.phy_dwidth-1 downto 0);
p_out_txll_sof_n     : out   std_logic;
p_out_txll_eof_n     : out   std_logic;
p_out_txll_src_rdy_n : out   std_logic;
p_in_txll_dst_rdy_n  : in    std_logic;
p_out_txll_rem       : out   std_logic_vector(G_ETH.phy_dwidth/8 - 1 downto 0);

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

signal i_rst   : std_logic_vector(p_in_ethcfg'length-1 downto 0);

--MAIN
begin


--//----------------------------------
--//Технологические сигналы
--//----------------------------------
gen_dbg_off : if strcmp(G_DBG,"OFF") generate
p_out_tst(31 downto 0)<=(others=>'0');
end generate gen_dbg_off;

gen_dbg_on : if strcmp(G_DBG,"ON") generate
p_out_tst(31 downto 0)<=(others=>'0');
end generate gen_dbg_on;




--//----------------------------------
--//Модули приема/передачи данных
--//----------------------------------
gen_ch : for i in 0 to G_ETH.gtch_count_max-1 generate

i_rst(i) <= p_in_rst or p_in_phy.rst;

p_out_eth(i).rxbuf.wrclk <= p_in_phy.clk;
p_out_eth(i).txbuf.rdclk <= p_in_phy.clk;

m_mac_rx : eth_mac_rx
generic map(
G_ETH => G_ETH,
G_DBG => G_DBG,
G_SIM => G_SIM
)
port map(
--------------------------------------
--Управление
--------------------------------------
p_in_cfg              => p_in_ethcfg(i),

--------------------------------------
--Связь с пользовательским RXBUF
--------------------------------------
p_out_rxbuf_din       => p_out_eth(i).rxbuf.din(G_ETH.usrbuf_dwidth-1 downto 0),
p_out_rxbuf_wr        => p_out_eth(i).rxbuf.wr,
p_in_rxbuf_full       => p_in_eth (i).rxbuf.full,
p_out_rxd_sof         => p_out_eth(i).rxbuf.sof,
p_out_rxd_eof         => p_out_eth(i).rxbuf.eof,

--------------------------------------
--Связь с Local link RxFIFO
--------------------------------------
p_in_rxll_data        => p_in_phy2app(i).rxd(G_ETH.phy_dwidth-1 downto 0),
p_in_rxll_sof_n       => p_in_phy2app(i).rxsof_n,
p_in_rxll_eof_n       => p_in_phy2app(i).rxeof_n,
p_in_rxll_src_rdy_n   => p_in_phy2app(i).rxsrc_rdy_n,
p_out_rxll_dst_rdy_n  => p_out_phy2app (i).rxdst_rdy_n,
p_in_rxll_fifo_status => p_in_phy2app(i).rxbuf_status,
p_in_rxll_rem         => p_in_phy2app(i).rxrem(G_ETH.phy_dwidth/8-1 downto 0),

--------------------------------------
--Управление передачей PAUSE Control Frame
--(более подробно см. ug194.pdf/Flow Control Block/Flow Control Implementation Example)
--------------------------------------
p_out_pause_req       => open,
p_out_pause_val       => open,

--------------------------------------
--Технологические сигналы
--------------------------------------
p_in_tst              => p_in_tst,
p_out_tst             => p_out_dbg(i).mac_rx,

--------------------------------------
--SYSTEM
--------------------------------------
p_in_clk             => p_in_phy.clk,
p_in_rst             => i_rst(i)
);


m_mac_tx : eth_mac_tx
generic map(
G_ETH => G_ETH,
G_DBG => G_DBG,
G_SIM => G_SIM
)
port map(
--------------------------------------
--Управление
--------------------------------------
p_in_cfg             => p_in_ethcfg(i),

--------------------------------------
--Связь с пользовательским TXBUF
--------------------------------------
p_in_txbuf_dout      => p_in_eth (i).txbuf.dout(G_ETH.usrbuf_dwidth-1 downto 0),
p_out_txbuf_rd       => p_out_eth(i).txbuf.rd,
p_in_txbuf_empty     => p_in_eth (i).txbuf.empty,
--p_in_txd_rdy         => p_in_eth_txd_rdy(0),

--------------------------------------
--Связь с Local link TxFIFO
--------------------------------------
p_out_txll_data      => p_out_phy2app (i).txd(G_ETH.phy_dwidth-1 downto 0),
p_out_txll_sof_n     => p_out_phy2app (i).txsof_n,
p_out_txll_eof_n     => p_out_phy2app (i).txeof_n,
p_out_txll_src_rdy_n => p_out_phy2app (i).txsrc_rdy_n,
p_in_txll_dst_rdy_n  => p_in_phy2app(i).txdst_rdy_n,
p_out_txll_rem       => p_out_phy2app(i).txrem(G_ETH.phy_dwidth/8-1 downto 0),

--------------------------------------
--Технологические сигналы
--------------------------------------
p_in_tst             => p_in_tst,
p_out_tst            => p_out_dbg(i).mac_tx,

--------------------------------------
--SYSTEM
--------------------------------------
p_in_clk             => p_in_phy.clk,
p_in_rst             => i_rst(i)
);

end generate gen_ch;


--END MAIN
end behavioral;
