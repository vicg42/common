-------------------------------------------------------------------------
-- Company     : Telemix
-- Engineer    : Golovachenko Victor
--
-- Create Date : 02/04/2010
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


package eth_pkg is

constant C_PKT_MARKER_PATTERN_SIZE_LSB_BIT : integer:=0;
constant C_PKT_MARKER_PATTERN_SIZE_MSB_BIT : integer:=3;
constant C_PKT_MARKER_PATTERN_SIZE         : integer:=C_PKT_MARKER_PATTERN_SIZE_MSB_BIT-C_PKT_MARKER_PATTERN_SIZE_LSB_BIT+1;


type  TEthUsrPattern is array (0 to 15) of std_logic_vector(7 downto 0);
constant C_USR_PATTERN_MAC_DST_LSB_BIT     : integer:=0;
constant C_USR_PATTERN_MAC_DST_MSB_BIT     : integer:=5;
constant C_USR_PATTERN_MAC_SRC_LSB_BIT     : integer:=6;
constant C_USR_PATTERN_MAC_SRC_MSB_BIT     : integer:=11;
constant C_USR_PATTERN_MAC_LENTYPE_LSB_BIT : integer:=12;
constant C_USR_PATTERN_MAC_LENTYPE_MSB_BIT : integer:=13;




component eth_main
generic(
G_REM_WIDTH    :       integer := 4;           -- Remainder width of read data
G_DWIDTH       :       integer := 32          -- FIFO read data width,
);
port
(
--//Управление
p_in_glob_ctrl                  : in    std_logic_vector(31 downto 0);

--//------------------------------------
--//EMAC - Channel 0
--//------------------------------------
--//Управление
p_in_usr0_ctrl                  : in    std_logic_vector(15 downto 0);
--p_in_usr0_txpattern_param       : in    std_logic_vector(15 downto 0);
p_in_usr0_mac_pattern           : in    std_logic_vector(127 downto 0);

--//Связь с пользовательским RXBUF
p_out_usr0_rxdata               : out   std_logic_vector(G_DWIDTH-1 downto 0);
p_out_usr0_rxdata_wr            : out   std_logic;
p_out_usr0_rxdata_rdy           : out   std_logic;
p_out_usr0_rxdata_sof           : out   std_logic;
p_in_usr0_rxbuf_full            : in    std_logic;

--//Связь с пользовательским TXBUF
p_in_usr0_txdata                : in    std_logic_vector(G_DWIDTH-1 downto 0);
p_out_usr0_txdata_rd            : out   std_logic;
p_in_usr0_txdata_rdy            : in    std_logic;
p_in_usr0_txbuf_empty           : in    std_logic;
p_in_usr0_txbuf_empty_almost    : in    std_logic;

--частота для буферов RX/TXBUF
p_out_usr0_bufclk               : out   std_logic;

--//Связь с внешиним приемопередатчиком
p_out_emac0_gtp_txp             : out   std_logic;
p_out_emac0_gtp_txn             : out   std_logic;
p_in_emac0_gtp_rxp              : in    std_logic;
p_in_emac0_gtp_rxn              : in    std_logic;

--Опорная частота для RocketIO
p_in_emac0_clkref               : in    std_logic;

p_out_emac0_sync_acq_status     : out   std_logic;

--//------------------------------------
--//EMAC - Channel 1
--//------------------------------------
p_out_emac1_gtp_txp             : out   std_logic;
p_out_emac1_gtp_txn             : out   std_logic;
p_in_emac1_gtp_rxp              : in    std_logic;
p_in_emac1_gtp_rxn              : in    std_logic;


--//------------------------------------
--//SYSTEM
--//------------------------------------
p_in_gtp_drp_clk                : in  std_logic;
p_out_gtp_plllkdet              : out std_logic;
p_out_ust_tst                   : out std_logic_vector(31 downto 0);

-- Asynchronous Reset
p_in_rst                         : in  std_logic
);
end component;

component emac_core_main
port
(
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


--component eth_ll_swap
--port (
---- Local Link FIFO Signals
---- numbers are client side, letters are mac side
--ll_1_rx_data        : out std_logic_vector(7 downto 0);
--ll_1_rx_sof_n       : out std_logic;
--ll_1_rx_eof_n       : out std_logic;
--ll_1_rx_src_rdy_n   : out std_logic;
--ll_1_rx_dst_rdy_n   : in  std_logic;
--
--ll_1_tx_data        : in  std_logic_vector(7 downto 0);
--ll_1_tx_sof_n       : in  std_logic;
--ll_1_tx_eof_n       : in  std_logic;
--ll_1_tx_src_rdy_n   : in  std_logic;
--ll_1_tx_dst_rdy_n   : out std_logic;
--
----ll_2_rx_data        : out std_logic_vector(7 downto 0);
----ll_2_rx_sof_n       : out std_logic;
----ll_2_rx_eof_n       : out std_logic;
----ll_2_rx_src_rdy_n   : out std_logic;
----ll_2_rx_dst_rdy_n   : in  std_logic;
----
----ll_2_tx_data        : in  std_logic_vector(7 downto 0);
----ll_2_tx_sof_n       : in  std_logic;
----ll_2_tx_eof_n       : in  std_logic;
----ll_2_tx_src_rdy_n   : in  std_logic;
----ll_2_tx_dst_rdy_n   : out std_logic;
--
--ll_a_rx_data        : in  std_logic_vector(7 downto 0);
--ll_a_rx_sof_n       : in  std_logic;
--ll_a_rx_eof_n       : in  std_logic;
--ll_a_rx_src_rdy_n   : in  std_logic;
--ll_a_rx_dst_rdy_n   : out std_logic;
--
--ll_a_tx_data        : out std_logic_vector(7 downto 0);
--ll_a_tx_sof_n       : out std_logic;
--ll_a_tx_eof_n       : out std_logic;
--ll_a_tx_src_rdy_n   : out std_logic;
--ll_a_tx_dst_rdy_n   : in  std_logic;
--
----ll_b_rx_data        : in  std_logic_vector(7 downto 0);
----ll_b_rx_sof_n       : in  std_logic;
----ll_b_rx_eof_n       : in  std_logic;
----ll_b_rx_src_rdy_n   : in  std_logic;
----ll_b_rx_dst_rdy_n   : out std_logic;
----
----ll_b_tx_data        : out std_logic_vector(7 downto 0);
----ll_b_tx_sof_n       : out std_logic;
----ll_b_tx_eof_n       : out std_logic;
----ll_b_tx_src_rdy_n   : out std_logic;
----ll_b_tx_dst_rdy_n   : in  std_logic;
--
---- control
--swap        : in  std_logic;
--loopback    : in  std_logic;
--address     : in  std_logic;
--clk         : in  std_logic;
--rst         : in  std_logic
--);
--end component;
--
--component eth_statistics_block
--port (
---- reference clock for the statistics core
--ref_clk                : in std_logic;
--
---- Management (host) interface for the Ethernet MAC cores
--host_clk               : in std_logic;
--host_addr              : in std_logic_vector(9 downto 0);
--host_req               : in std_logic;
--host_miim_sel          : in std_logic;
--host_rd_data           : out std_logic_vector(31 downto 0);
--host_stats_lsw_rdy     : out std_logic;
--host_stats_msw_rdy     : out std_logic;
--
---- Transmitter Statistic Vector inputs from ethernet MAC
--txclientclkin          : in std_logic;
--clienttxstatsvld       : in std_logic;
--clienttxstats          : in std_logic;
--clienttxstatsbytevalid : in std_logic;
--
---- Receiver Statistic Vector inputs from ethernet MAC
--rxclientclkin          : in std_logic;
--clientrxstatsvld       : in std_logic;
--clientrxstats          : in std_logic_vector(6 downto 0);
--clientrxstatsbytevalid : in std_logic;
--clientrxdvld           : in std_logic;
--
---- asynchronous reset
--reset                  : in std_logic
--);
--end component;
--
--
--component eth_statistics_block_usr
--port (
--p_out_rx_statistics_vector   : out std_logic_vector(27 downto 0);
--p_out_rx_statistics_valid    : out std_logic;
--
---- Transmitter Statistic Vector inputs from ethernet MAC
--txclientclkin          : in std_logic;
--clienttxstatsvld       : in std_logic;
--clienttxstats          : in std_logic;
--clienttxstatsbytevalid : in std_logic;
--
---- Receiver Statistic Vector inputs from ethernet MAC
--rxclientclkin          : in std_logic;
--clientrxstatsvld       : in std_logic;
--clientrxstats          : in std_logic_vector(6 downto 0);
--clientrxstatsbytevalid : in std_logic;
--clientrxdvld           : in std_logic;
--
---- asynchronous reset
--reset                  : in std_logic
--);
--end component;


component eth_rx
generic(
G_RD_REM_WIDTH    :       integer := 4;           -- Remainder width of read data
G_RD_DWIDTH       :       integer := 32           -- FIFO read data width,
);
port
(
--//------------------------------------
--//Управление
--//------------------------------------
p_in_usr_ctrl                   : in    std_logic_vector(15 downto 0);
p_in_usr_pattern_param          : in    std_logic_vector(15 downto 0);
p_in_usr_pattern                : in    TEthUsrPattern;

--//------------------------------------
--//Связь с пользовательским RXBUF
--//------------------------------------
p_out_usr_rxdata                : out   std_logic_vector(G_RD_DWIDTH-1 downto 0);
p_out_usr_rxdata_wr             : out   std_logic;
p_out_usr_rxdata_rdy            : out   std_logic;
p_out_usr_rxdata_sof            : out   std_logic;
p_in_usr_rxbuf_full             : in    std_logic;

--//------------------------------------
--//Связь с Local link RxFIFO
--//------------------------------------
p_in_rx_ll_data                 : in    std_logic_vector(7 downto 0);
p_in_rx_ll_sof_n                : in    std_logic;
p_in_rx_ll_eof_n                : in    std_logic;
p_in_rx_ll_src_rdy_n            : in    std_logic;
p_out_rx_ll_dst_rdy_n           : out   std_logic;
p_in_rx_ll_fifo_status          : in    std_logic_vector(3 downto 0);

--//------------------------------------
--//Управление передачей PAUSE Control Frame
--//------------------------------------
p_out_pause_req                 : out   std_logic;
p_out_pause_val                 : out   std_logic_vector(15 downto 0);

--//------------------------------------
--//Статистика принятого пакета
--//------------------------------------
p_in_rx_statistic               : in    std_logic_vector(27 downto 0);
p_in_rx_statistic_vld           : in    std_logic;

--//------------------------------------
--//SYSTEM
--//------------------------------------
p_in_clk                        : in    std_logic;
p_in_rst                        : in    std_logic
);
end component;


component eth_tx
generic(
G_WR_REM_WIDTH    :       integer := 4;           -- Remainder width of read data
G_WR_DWIDTH       :       integer := 32           -- FIFO read data width,
);
port
(
--//------------------------------------
--//Управление
--//------------------------------------
p_in_usr_ctrl                   : in    std_logic_vector(15 downto 0);
p_in_usr_pattern_param          : in    std_logic_vector(15 downto 0);
p_in_usr_pattern                : in    TEthUsrPattern;

--//------------------------------------
--//Связь с пользовательским TXBUF
--//------------------------------------
p_in_usr_txdata                 : in    std_logic_vector(G_WR_DWIDTH-1 downto 0);
p_out_usr_txdata_rd             : out   std_logic;
p_in_usr_txdata_rdy             : in    std_logic;
p_in_usr_txbuf_empty            : in    std_logic;
p_in_usr_txbuf_empty_almost     : in    std_logic;

--//------------------------------------
--//Связь с Local link TxFIFO
--//------------------------------------
p_out_tx_ll_data                : out   std_logic_vector(7 downto 0);
p_out_tx_ll_sof_n               : out   std_logic;
p_out_tx_ll_eof_n               : out   std_logic;
p_out_tx_ll_src_rdy_n           : out   std_logic;
p_in_tx_ll_dst_rdy_n            : in    std_logic;


--//------------------------------------
--//SYSTEM
--//------------------------------------
p_in_clk                        : in    std_logic;
p_in_rst                        : in    std_logic
);
end component;

end eth_pkg;

package body eth_pkg is

end eth_pkg;
