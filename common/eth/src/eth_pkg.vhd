-------------------------------------------------------------------------
-- Company     : Telemix
-- Engineer    : Golovachenko Victor
--
-- Create Date : 03.05.2011 16:39:18
-- Module Name : eth_pkg
--
-- Description :
--
-- Revision:
-- Revision 0.01 - File Created
--
-------------------------------------------------------------------------
library ieee;
use ieee.STD_LOGIC_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_arith.all;

library work;
use work.vicg_common_pkg.all;

package eth_pkg is

constant C_ETH_USRBUF_DWIDTH : integer:=32;--//Шина данных пользовательских буферов RXBUF/TXBUF
constant C_GTCH_COUNT_MAX    : integer:=2; --//


type TEthMacAdr is array (0 to 5) of std_logic_vector(7 downto 0);
type TEthMAC is record
dst     : TEthMacAdr;
src     : TEthMacAdr;
lentype : std_logic_vector(15 downto 0);
end record;

type TEthCfg is record
usrctrl  : std_logic_vector(15 downto 0);
mac      : TEthMAC;
end record;


type TBus02_GTCH is array (0 to C_GTCH_COUNT_MAX-1) of std_logic_vector (1 downto 0);
type TBus03_GTCH is array (0 to C_GTCH_COUNT_MAX-1) of std_logic_vector (2 downto 0);
type TBus04_GTCH is array (0 to C_GTCH_COUNT_MAX-1) of std_logic_vector (3 downto 0);
type TBus05_GTCH is array (0 to C_GTCH_COUNT_MAX-1) of std_logic_vector (4 downto 0);
type TBus07_GTCH is array (0 to C_GTCH_COUNT_MAX-1) of std_logic_vector (6 downto 0);
type TBus08_GTCH is array (0 to C_GTCH_COUNT_MAX-1) of std_logic_vector (7 downto 0);
type TBus16_GTCH is array (0 to C_GTCH_COUNT_MAX-1) of std_logic_vector (15 downto 0);
type TBus21_GTCH is array (0 to C_GTCH_COUNT_MAX-1) of std_logic_vector (20 downto 0);
type TBus32_GTCH is array (0 to C_GTCH_COUNT_MAX-1) of std_logic_vector (31 downto 0);

type TBusUsrBUF_GTCH is array (0 to C_GTCH_COUNT_MAX-1) of std_logic_vector (C_ETH_USRBUF_DWIDTH-1 downto 0);
type TEthCfg_GTCH is array (0 to C_GTCH_COUNT_MAX-1) of TEthCfg;



component eth_main
generic(
G_DBG : string:="OFF";
G_SIM : string:="OFF"
);
port(
--//Управление
p_in_gctrl             : in    std_logic_vector(31 downto 0);

--//------------------------------------
--//Eth - Channel
--//------------------------------------
--//настройка канала
p_in_eth_cfg           : in    TEthCfg_GTCH;

--//Связь с RXBUF
p_out_eth_rxbuf_din    : out   TBusUsrBUF_GTCH;
p_out_eth_rxbuf_wr     : out   std_logic_vector(C_GTCH_COUNT_MAX-1 downto 0);
p_in_eth_rxbuf_full    : in    std_logic_vector(C_GTCH_COUNT_MAX-1 downto 0);
p_out_eth_rxd_sof      : out   std_logic_vector(C_GTCH_COUNT_MAX-1 downto 0);
p_out_eth_rxd_eof      : out   std_logic_vector(C_GTCH_COUNT_MAX-1 downto 0);

--//Связь с TXBUF
p_in_eth_txbuf_dout    : in    TBusUsrBUF_GTCH;
p_out_eth_txbuf_rd     : out   std_logic_vector(C_GTCH_COUNT_MAX-1 downto 0);
p_in_eth_txbuf_empty   : in    std_logic_vector(C_GTCH_COUNT_MAX-1 downto 0);
--p_in_eth_txd_rdy       : in    std_logic_vector(C_GTCH_COUNT_MAX-1 downto 0);

--------------------------------------------------
--ETH Driver
--------------------------------------------------
p_out_eth_gt_txp       : out   std_logic_vector(C_GTCH_COUNT_MAX-1 downto 0);
p_out_eth_gt_txn       : out   std_logic_vector(C_GTCH_COUNT_MAX-1 downto 0);
p_in_eth_gt_rxp        : in    std_logic_vector(C_GTCH_COUNT_MAX-1 downto 0);
p_in_eth_gt_rxn        : in    std_logic_vector(C_GTCH_COUNT_MAX-1 downto 0);

p_in_eth_gt_refclk     : in    std_logic;
p_out_eth_gt_refclkout : out   std_logic;

p_out_eth_gt_plllkdet  : out   std_logic;

--------------------------------------------------
--Технологические сигналы
--------------------------------------------------
p_in_tst               : in    std_logic_vector(31 downto 0);
p_out_tst              : out   std_logic_vector(31 downto 0);

--//------------------------------------
--//SYSTEM
--//------------------------------------
p_in_rst               : in    std_logic
);
end component;

component eth_rx
generic(
G_DBG : string:="OFF";
G_SIM : string:="OFF"
);
port(
--//------------------------------------
--//Управление
--//------------------------------------
p_in_cfg              : in    TEthCfg;

--//------------------------------------
--//Связь с пользовательским RXBUF
--//------------------------------------
p_out_rxbuf_din       : out   std_logic_vector(C_ETH_USRBUF_DWIDTH-1 downto 0);
p_out_rxbuf_wr        : out   std_logic;
p_in_rxbuf_full       : in    std_logic;
p_out_rxd_sof         : out   std_logic;
p_out_rxd_eof         : out   std_logic;

--//------------------------------------
--//Связь с Local link RxFIFO
--//------------------------------------
p_in_rxll_data        : in    std_logic_vector(7 downto 0);
p_in_rxll_sof_n       : in    std_logic;
p_in_rxll_eof_n       : in    std_logic;
p_in_rxll_src_rdy_n   : in    std_logic;
p_out_rxll_dst_rdy_n  : out   std_logic;
p_in_rxll_fifo_status : in    std_logic_vector(3 downto 0);

--//------------------------------------
--//Управление передачей PAUSE Control Frame
--//(более подробно см. ug194.pdf/Flow Control Block/Flow Control Implementation Example)
--//------------------------------------
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


component eth_tx
generic(
G_DBG : string:="OFF";
G_SIM : string:="OFF"
);
port(
--//------------------------------------
--//Управление
--//------------------------------------
p_in_cfg             : in    TEthCfg;

--//------------------------------------
--//Связь с пользовательским TXBUF
--//------------------------------------
p_in_txbuf_dout      : in    std_logic_vector(C_ETH_USRBUF_DWIDTH-1 downto 0);
p_out_txbuf_rd       : out   std_logic;
p_in_txbuf_empty     : in    std_logic;
--p_in_txd_rdy         : in    std_logic;

--//------------------------------------
--//Связь с Local link TxFIFO
--//------------------------------------
p_out_txll_data      : out   std_logic_vector(7 downto 0);
p_out_txll_sof_n     : out   std_logic;
p_out_txll_eof_n     : out   std_logic;
p_out_txll_src_rdy_n : out   std_logic;
p_in_txll_dst_rdy_n  : in    std_logic;

--------------------------------------------------
--Технологические сигналы
--------------------------------------------------
p_in_tst             : in    std_logic_vector(31 downto 0);
p_out_tst            : out   std_logic_vector(31 downto 0);

--//------------------------------------
--//SYSTEM
--//------------------------------------
p_in_clk             : in    std_logic;
p_in_rst             : in    std_logic
);
end component;




component emac_core_main
port(
--//------------------------------------
--//EMAC - Channel 0
--//------------------------------------
--//#########  Client side  #########
-- Local link Receiver Interface - EMAC0
--RX_LL_CLOCK_0                   : in  std_logic;
--RX_LL_RESET_0                   : in  std_logic;
RX_LL_DATA_0                    : out std_logic_vector(7 downto 0);
RX_LL_SOF_N_0                   : out std_logic;
RX_LL_EOF_N_0                   : out std_logic;
RX_LL_SRC_RDY_N_0               : out std_logic;
RX_LL_DST_RDY_N_0               : in  std_logic;
RX_LL_FIFO_STATUS_0             : out std_logic_vector(3 downto 0);

-- Local link Transmitter Interface - EMAC0
--TX_LL_CLOCK_0                   : in  std_logic;
--TX_LL_RESET_0                   : in  std_logic;
TX_LL_DATA_0                    : in  std_logic_vector(7 downto 0);
TX_LL_SOF_N_0                   : in  std_logic;
TX_LL_EOF_N_0                   : in  std_logic;
TX_LL_SRC_RDY_N_0               : in  std_logic;
TX_LL_DST_RDY_N_0               : out std_logic;

--EMAC0_RXCLIENTCLKOUT            : out std_logic;
--EMAC0_TXCLIENTCLKOUT            : out std_logic;

-- Client Receiver Interface - EMAC0
EMAC0CLIENTRXDVLD               : out std_logic;
EMAC0CLIENTRXFRAMEDROP          : out std_logic;
EMAC0CLIENTRXSTATS              : out std_logic_vector(6 downto 0);
EMAC0CLIENTRXSTATSVLD           : out std_logic;
EMAC0CLIENTRXSTATSBYTEVLD       : out std_logic;

-- Client Transmitter Interface - EMAC0
CLIENTEMAC0TXIFGDELAY           : in  std_logic_vector(7 downto 0);
EMAC0CLIENTTXSTATS              : out std_logic;
EMAC0CLIENTTXSTATSVLD           : out std_logic;
EMAC0CLIENTTXSTATSBYTEVLD       : out std_logic;

-- MAC Control Interface - EMAC0
CLIENTEMAC0PAUSEREQ             : in  std_logic;
CLIENTEMAC0PAUSEVAL             : in  std_logic_vector(15 downto 0);

--EMAC-MGT link status
EMAC0CLIENTSYNCACQSTATUS        : out std_logic;
-- EMAC0 Interrupt
EMAC0ANINTERRUPT                : out std_logic;

--//#########  PHY side  #########
-- Clock Signals - EMAC0
-- 1000BASE-X PCS/PMA Interface - EMAC0
PHYAD_0                         : in  std_logic_vector(4 downto 0);
TXP_0                           : out std_logic;
TXN_0                           : out std_logic;
RXP_0                           : in  std_logic;
RXN_0                           : in  std_logic;

-- 1000BASE-X PCS/PMA RocketIO Reference Clock buffer inputs
--MGTCLK_P                        : in  std_logic;
--MGTCLK_N                        : in  std_logic;
p_in_emac_0_clkref              : in  std_logic;
p_out_emac_0_clk125MHz          : out std_logic;
p_out_emac_0_rst                : out std_logic;

--//------------------------------------
--//EMAC - Channel 1
--//------------------------------------
PHYAD_1                         : in  std_logic_vector(4 downto 0);
TXN_1                           : out std_logic;
TXP_1                           : out std_logic;
RXN_1                           : in  std_logic;
RXP_1                           : in  std_logic;


--//------------------------------------
--//SYSTEM
--//------------------------------------
p_in_drp_ctrl                   : in  std_logic_vector(31 downto 0);
p_out_gtp_plllkdet              : out std_logic;
p_out_ust_tst                   : out std_logic_vector(31 downto 0);

-- Asynchronous Reset
RESET                           : in  std_logic
);
end component;


end eth_pkg;

package body eth_pkg is

end eth_pkg;
