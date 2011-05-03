-------------------------------------------------------------------------
-- Company     : Linkos
-- Engineer    : Golovachenko Victor
--
-- Create Date : 02/04/2010
-- Module Name : eth_main
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

library work;
use work.prj_def.all;
use work.eth_pkg.all;

library unisim;
use unisim.vcomponents.all;

entity eth_main is
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
p_in_usr0_mac_pattern           : in    std_logic_vector(127 downto 0);

--//Связь с пользовательским RXBUF
p_out_usr0_rxdata               : out   std_logic_vector(G_DWIDTH-1 downto 0);
p_out_usr0_rxdata_wr            : out   std_logic;
p_out_usr0_rxdata_rdy           : out   std_logic;--//Строб rxdata - последний 2DWORD пакета Eth ((инвертированый) - rxdata_eof_n)
p_out_usr0_rxdata_sof           : out   std_logic;--//Строб rxdata - первый 2DWORD пакета Eth ((инвертированый) - rxdata_sof_n)
p_in_usr0_rxbuf_full            : in    std_logic;

--//Связь с пользовательским TXBUF
p_in_usr0_txdata                : in    std_logic_vector(G_DWIDTH-1 downto 0);
p_out_usr0_txdata_rd            : out   std_logic;
p_in_usr0_txdata_rdy            : in    std_logic;--//Строб txdata - готовы, можно вычитывать данные из внешного TXBUF
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
p_in_rst                        : in  std_logic
);
end eth_main;


architecture behavioral of eth_main is


signal b_swap_ctr_swap                  : std_logic;
signal b_swap_ctr_loop                  : std_logic;
signal b_swap_ctr_adr                   : std_logic;

signal i_emac0_rst                      : std_logic;
signal i_emac0_clk125MHz                : std_logic;

signal i_emac0_tx_ifg_delay             : std_logic_vector(7 downto 0);

signal i_emac0_pause_req                : std_logic;
signal i_emac0_pause_val                : std_logic_vector(15 downto 0);

--signal i_emac0_sync_acq_status          : std_logic;
signal i_emac0_int                      : std_logic;
signal i_emac0_phyad                    : std_logic_vector(4 downto 0);

signal i_emac0_tx_ll_data_tmp           : std_logic_vector(7 downto 0);
signal i_emac0_tx_ll_sof_n_tmp          : std_logic;
signal i_emac0_tx_ll_eof_n_tmp          : std_logic;
signal i_emac0_tx_ll_src_rdy_n_tmp      : std_logic;
signal i_emac0_tx_ll_dst_rdy_n_tmp      : std_logic;

signal i_emac0_rx_ll_data_tmp           : std_logic_vector(7 downto 0);
signal i_emac0_rx_ll_sof_n_tmp          : std_logic;
signal i_emac0_rx_ll_eof_n_tmp          : std_logic;
signal i_emac0_rx_ll_src_rdy_n_tmp      : std_logic;
signal i_emac0_rx_ll_dst_rdy_n_tmp      : std_logic;
signal i_emac0_rx_ll_fifo_status_tmp    : std_logic_vector(3 downto 0);

signal i_emac0_tx_ll_data               : std_logic_vector(7 downto 0);
signal i_emac0_tx_ll_sof_n              : std_logic;
signal i_emac0_tx_ll_eof_n              : std_logic;
signal i_emac0_tx_ll_src_rdy_n          : std_logic;
signal i_emac0_tx_ll_dst_rdy_n          : std_logic;

signal i_emac0_rx_ll_data               : std_logic_vector(7 downto 0);
signal i_emac0_rx_ll_sof_n              : std_logic;
signal i_emac0_rx_ll_eof_n              : std_logic;
signal i_emac0_rx_ll_src_rdy_n          : std_logic;
signal i_emac0_rx_ll_dst_rdy_n          : std_logic;
signal i_emac0_rx_ll_fifo_status        : std_logic_vector(3 downto 0);

signal i_emac0_rx_client_dvld           : std_logic;
signal i_emac0_rx_client_framedrop      : std_logic;
signal i_emac0_rx_client_stats          : std_logic_vector(6 downto 0);
signal i_emac0_rx_client_statsvld       : std_logic;
signal i_emac0_rx_client_statsbytevld   : std_logic;

signal i_emac0_tx_client_stats          : std_logic;
signal i_emac0_tx_client_statsvld       : std_logic;
signal i_emac0_tx_client_statsbytevld   : std_logic;

signal i_emac0_rx_statistic_usr_tmp     : std_logic_vector(27 downto 0);
signal i_emac0_rx_statistic_usr_vld_tmp : std_logic;
signal i_emac0_rx_statistic_usr         : std_logic_vector(27 downto 0);
signal i_emac0_rx_statistic_usr_vld     : std_logic;

signal i_emac0_rx_client_clkin          : std_logic;
signal i_emac0_tx_client_clkin          : std_logic;


signal i_emac1_phyad                    : std_logic_vector(4 downto 0);

signal i_usr0_rxdata                    : std_logic_vector(G_DWIDTH-1 downto 0);
signal i_usr0_rxdata_wr                 : std_logic;
signal i_usr0_rxdata_rdy                : std_logic;

signal i_usr0_mac_pattern                 : TEthUsrPattern:=(
"10100000",
"10100001",
"10100010",
"10100011",
"10100100",
"10100101",
"10100110",
"10100111",
"10101000",
"10101001",
"10101010",
"10101011",
"10101100",
"10101101",
"10101110",
"10101111"
);

signal i_usr0_rxpattern_param           : std_logic_vector(15 downto 0);
signal i_usr0_txpattern_param           : std_logic_vector(15 downto 0);


signal i_drp_ctrl                       : std_logic_vector(31 downto 0);

signal i_ust_tst                        : std_logic_vector(31 downto 0);

signal i_tst_txdcnt                     : std_logic_vector(15 downto 0);



--MAIN
begin


--//-------------------------------------------------------------
--//Тестирование
--//-------------------------------------------------------------
p_out_ust_tst(7 downto 0)  <=i_ust_tst(7 downto 0);
p_out_ust_tst(15 downto 8) <=i_usr0_rxdata(7 downto 0);--i_ust_tst(15 downto 8);
p_out_ust_tst(19 downto 16)<=i_ust_tst(19 downto 16);

p_out_ust_tst(20)<=i_emac0_rx_ll_sof_n;
p_out_ust_tst(21)<=i_emac0_rx_ll_eof_n;
p_out_ust_tst(22)<=i_emac0_rx_ll_src_rdy_n;
p_out_ust_tst(23)<=i_emac0_rx_ll_dst_rdy_n;


p_out_ust_tst(24)<=i_emac0_tx_ll_sof_n;
p_out_ust_tst(25)<=i_emac0_tx_ll_eof_n;
p_out_ust_tst(26)<=i_emac0_tx_ll_src_rdy_n;
p_out_ust_tst(27)<=i_emac0_tx_ll_dst_rdy_n;

p_out_ust_tst(28)<=i_usr0_rxdata_wr;
p_out_ust_tst(29)<=i_usr0_rxdata_rdy or OR_reduce(i_tst_txdcnt);

p_out_ust_tst(31 downto 30)<=i_ust_tst(31 downto 30);

--p_out_ust_tst(35 downto 27)<=i_emac0_rx_ll_data,
--p_out_ust_tst(44 downto 36)<=i_emac0_tx_ll_data,
--//-------------------------------------------------------------



p_out_usr0_rxdata     <= i_usr0_rxdata;
p_out_usr0_rxdata_wr  <= i_usr0_rxdata_wr;
p_out_usr0_rxdata_rdy <= i_usr0_rxdata_rdy;

--//Распределяем биты управления
b_swap_ctr_swap<=p_in_glob_ctrl(C_DSN_ETHG_REG_CTRL_SWAP_LOOPBACK2_BIT);
b_swap_ctr_loop<=p_in_glob_ctrl(C_DSN_ETHG_REG_CTRL_SWAP_LOOPBACK1_BIT);
b_swap_ctr_adr <=p_in_glob_ctrl(C_DSN_ETHG_REG_CTRL_SWAP_LOOPBACK0_BIT);

i_drp_ctrl(30 downto 0)<=p_in_glob_ctrl(30 downto 0);
i_drp_ctrl(31)<=p_in_gtp_drp_clk;


--//Определяем адреса устройства(MAC0,MAC1) для доступа к PCS/PMA Management Registers
i_emac0_phyad         <= CONV_STD_LOGIC_VECTOR(16#10#, 5);
i_emac1_phyad         <= CONV_STD_LOGIC_VECTOR(16#11#, 5);

--//Более подробно см. ug194.pdf/Transmit (TX) Client: 8-Bit Interface (without Clock Enables)/IFG Adjustment
--//x0D minimum IFG specified in IEEE802.3, the minimum IFG (12 idles).
i_emac0_tx_ifg_delay  <= CONV_STD_LOGIC_VECTOR(16#0D#, 8);


--//*********************************************************************
--//********  Ethernet MAC - Core  *************
--//*********************************************************************
m_emac_core_main : emac_core_main
port map
(
--//------------------------------------
--//EMAC - Channel 0
--//------------------------------------
--//#########  Client side  #########
-- Local link Receiver Interface - EMAC0
--RX_LL_CLOCK_0                   : in  std_logic;
--RX_LL_RESET_0                   : in  std_logic;
RX_LL_DATA_0                    => i_emac0_rx_ll_data_tmp,       --: out std_logic_vector(7 downto 0);
RX_LL_SOF_N_0                   => i_emac0_rx_ll_sof_n_tmp,      --: out std_logic;
RX_LL_EOF_N_0                   => i_emac0_rx_ll_eof_n_tmp,      --: out std_logic;
RX_LL_SRC_RDY_N_0               => i_emac0_rx_ll_src_rdy_n_tmp,  --: out std_logic;
RX_LL_DST_RDY_N_0               => i_emac0_rx_ll_dst_rdy_n_tmp,  --: in  std_logic;
RX_LL_FIFO_STATUS_0             => i_emac0_rx_ll_fifo_status_tmp,--: out std_logic_vector(3 downto 0);

-- Local link Transmitter Interface - EMAC0
--TX_LL_CLOCK_0                   : in  std_logic;
--TX_LL_RESET_0                   : in  std_logic;
TX_LL_DATA_0                    => i_emac0_tx_ll_data_tmp,        --: in  std_logic_vector(7 downto 0);
TX_LL_SOF_N_0                   => i_emac0_tx_ll_sof_n_tmp,       --: in  std_logic;
TX_LL_EOF_N_0                   => i_emac0_tx_ll_eof_n_tmp,       --: in  std_logic;
TX_LL_SRC_RDY_N_0               => i_emac0_tx_ll_src_rdy_n_tmp,   --: in  std_logic;
TX_LL_DST_RDY_N_0               => i_emac0_tx_ll_dst_rdy_n_tmp,   --: out std_logic;

-- Client Receiver Interface - EMAC0
EMAC0CLIENTRXDVLD               => i_emac0_rx_client_dvld,        --: out std_logic;
EMAC0CLIENTRXFRAMEDROP          => i_emac0_rx_client_framedrop,   --: out std_logic;
EMAC0CLIENTRXSTATS              => i_emac0_rx_client_stats,       --: out std_logic_vector(6 downto 0);
EMAC0CLIENTRXSTATSVLD           => i_emac0_rx_client_statsvld,    --: out std_logic;
EMAC0CLIENTRXSTATSBYTEVLD       => i_emac0_rx_client_statsbytevld,--: out std_logic;

-- Client Transmitter Interface - EMAC0
CLIENTEMAC0TXIFGDELAY           => i_emac0_tx_ifg_delay,          --: in  std_logic_vector(7 downto 0);
EMAC0CLIENTTXSTATS              => i_emac0_tx_client_stats,       --: out std_logic;
EMAC0CLIENTTXSTATSVLD           => i_emac0_tx_client_statsvld,    --: out std_logic;
EMAC0CLIENTTXSTATSBYTEVLD       => i_emac0_tx_client_statsbytevld,--: out std_logic;

-- MAC Control Interface - EMAC0
CLIENTEMAC0PAUSEREQ             => i_emac0_pause_req,--: in  std_logic;
CLIENTEMAC0PAUSEVAL             => i_emac0_pause_val,--: in  std_logic_vector(15 downto 0);

--EMAC-MGT link status
EMAC0CLIENTSYNCACQSTATUS        => p_out_emac0_sync_acq_status,--: out std_logic;
-- EMAC0 Interrupt
EMAC0ANINTERRUPT                => i_emac0_int,--: out std_logic;

--//#########  PHY side  #########
-- Clock Signals - EMAC0
-- 1000BASE-X PCS/PMA Interface - EMAC0
PHYAD_0                         => i_emac0_phyad,       --: in  std_logic_vector(4 downto 0);
TXP_0                           => p_out_emac0_gtp_txp, --: out std_logic;
TXN_0                           => p_out_emac0_gtp_txn, --: out std_logic;
RXP_0                           => p_in_emac0_gtp_rxp,  --: in  std_logic;
RXN_0                           => p_in_emac0_gtp_rxn,  --: in  std_logic;

-- 1000BASE-X PCS/PMA RocketIO Reference Clock buffer inputs
p_in_emac_0_clkref              => p_in_emac0_clkref,--: in std_logic;

p_out_emac_0_clk125MHz          => i_emac0_clk125MHz,--: out std_logic;
p_out_emac_0_rst                => i_emac0_rst,      --: out std_logic;

--//------------------------------------
--//EMAC - Channel 1
--//------------------------------------
PHYAD_1                         => i_emac1_phyad,      --: in  std_logic_vector(4 downto 0);
TXP_1                           => p_out_emac1_gtp_txp,--: out std_logic;
TXN_1                           => p_out_emac1_gtp_txn,--: out std_logic;
RXP_1                           => p_in_emac1_gtp_rxp, --: in  std_logic;
RXN_1                           => p_in_emac1_gtp_rxn, --: in  std_logic;


--//------------------------------------
--//SYSTEM
--//------------------------------------
p_in_drp_ctrl                   => i_drp_ctrl,
p_out_gtp_plllkdet              => p_out_gtp_plllkdet,
p_out_ust_tst                   => i_ust_tst,

-- Asynchronous Reset
RESET                           => p_in_rst --: in std_logic;
);


--//*********************************************************************
--//Статистика принятых/запизаных пакетов
--//*********************************************************************
i_emac0_rx_client_clkin <= i_emac0_clk125MHz;
i_emac0_tx_client_clkin <= i_emac0_clk125MHz;

p_out_usr0_bufclk <= i_emac0_clk125MHz;

i_emac0_rx_statistic_usr<=(others=>'0');
i_emac0_rx_statistic_usr_vld<='0';
--m_eth_statistic_usr : eth_statistics_block_usr
--port map
--(
--p_out_rx_statistics_vector   => i_emac0_rx_statistic_usr_tmp,
--p_out_rx_statistics_valid    => i_emac0_rx_statistic_usr_vld_tmp,
--
---- Transmitter Statistic Vector inputs from ethernet MAC
--txclientclkin          => i_emac0_tx_client_clkin,
--clienttxstatsvld       => i_emac0_tx_client_statsvld,
--clienttxstats          => i_emac0_tx_client_stats,
--clienttxstatsbytevalid => i_emac0_tx_client_statsbytevld,
--
---- Receiver Statistic Vector inputs from ethernet MAC
--rxclientclkin          => i_emac0_rx_client_clkin,
--clientrxstatsvld       => i_emac0_rx_client_statsvld,
--clientrxstats          => i_emac0_rx_client_stats,
--clientrxstatsbytevalid => i_emac0_rx_client_statsbytevld,
--clientrxdvld           => i_emac0_rx_client_dvld,
--
---- asynchronous reset
--reset                  => i_emac0_rst
--);
--
--process (i_emac0_rst,i_emac0_rx_client_clkin)
--begin
--  if i_emac0_rst = '1' then
--      i_emac0_rx_statistic_usr<=(others=>'0');
--      i_emac0_rx_statistic_usr_vld<='0';
--  elsif i_emac0_rx_client_clkin'event and i_emac0_rx_client_clkin = '1' then
--    if i_emac0_rx_statistic_usr_vld_tmp='1' then
--      i_emac0_rx_statistic_usr<=i_emac0_rx_statistic_usr_tmp;
--    else
--      i_emac0_rx_statistic_usr<=(others=>'0');
--    end if;
--      i_emac0_rx_statistic_usr_vld<=i_emac0_rx_statistic_usr_vld_tmp;
--  end if;
--end process;

--m_eth_statistic : eth_statistics_block
--port map
--(
---- Management (host) interface for the Ethernet MAC cores
--host_clk               => i_emac0_clk125MHz,--: in std_logic;
--host_addr              => "0000000000",--: in std_logic_vector(9 downto 0);
--host_req               => '1',--: in std_logic;
--host_miim_sel          => '1',--: in std_logic;
--host_rd_data           => open,--: out std_logic_vector(31 downto 0);
--host_stats_lsw_rdy     => open,--: out std_logic;
--host_stats_msw_rdy     => open,--: out std_logic;
--
---- Transmitter Statistic Vector inputs from ethernet MAC
--txclientclkin          => i_emac0_tx_client_clkin,--
--clienttxstatsvld       => i_emac0_tx_client_statsvld,
--clienttxstats          => i_emac0_tx_client_stats,
--clienttxstatsbytevalid => i_emac0_tx_client_statsbytevld,
--
---- Receiver Statistic Vector inputs from ethernet MAC
--rxclientclkin          => i_emac0_rx_client_clkin,--
--clientrxstatsvld       => i_emac0_rx_client_statsvld,
--clientrxstats          => i_emac0_rx_client_stats,
--clientrxstatsbytevalid => i_emac0_rx_client_statsbytevld,
--clientrxdvld           => i_emac0_rx_client_dvld,
--
---- reference clock for the statistics core
--ref_clk                => i_emac0_clk125MHz,--
--
---- asynchronous reset
--reset                  => i_emac0_rst
--);



--//*********************************************************************
--//Модуль swaping-га, Выполняет следующие функции:
--//address='0' and loopback'0' - ll_1_rx_data <- ll_a_rx_data
--//                              ll_1_tx_data -> ll_a_tx_data
--//
--//address='0' and loopback'1' - ll_a_tx_data <- ll_a_rx_data
--//
--//address='1' and loopback'0' - ll_a_tx_data <- ll_a_rx_data + меняет местами адрес dst/src Eth кадра на ll_a_rx_data
--//*********************************************************************
--//Связь с модулем eth_mac_core.vhd
i_emac0_rx_ll_data <= i_emac0_rx_ll_data_tmp;
i_emac0_rx_ll_sof_n<= i_emac0_rx_ll_sof_n_tmp;
i_emac0_rx_ll_eof_n<= i_emac0_rx_ll_eof_n_tmp;
i_emac0_rx_ll_src_rdy_n<= i_emac0_rx_ll_src_rdy_n_tmp;
i_emac0_rx_ll_dst_rdy_n_tmp<=i_emac0_rx_ll_dst_rdy_n;

i_emac0_tx_ll_data_tmp <= i_emac0_tx_ll_data;
i_emac0_tx_ll_sof_n_tmp <= i_emac0_tx_ll_sof_n;
i_emac0_tx_ll_eof_n_tmp <= i_emac0_tx_ll_eof_n;
i_emac0_tx_ll_src_rdy_n_tmp <= i_emac0_tx_ll_src_rdy_n;
i_emac0_tx_ll_dst_rdy_n <= i_emac0_tx_ll_dst_rdy_n_tmp;

--m_eth_ll_swap : eth_ll_swap
--port map
--(
----//Связь с модулем eth_mac_core.vhd
--ll_a_rx_data        => i_emac0_rx_ll_data_tmp,      --: in  std_logic_vector(7 downto 0);
--ll_a_rx_sof_n       => i_emac0_rx_ll_sof_n_tmp,     --: in  std_logic;
--ll_a_rx_eof_n       => i_emac0_rx_ll_eof_n_tmp,     --: in  std_logic;
--ll_a_rx_src_rdy_n   => i_emac0_rx_ll_src_rdy_n_tmp, --: in  std_logic;
--ll_a_rx_dst_rdy_n   => i_emac0_rx_ll_dst_rdy_n_tmp, --: out std_logic;
--
--ll_a_tx_data        => i_emac0_tx_ll_data_tmp,      --: out std_logic_vector(7 downto 0);
--ll_a_tx_sof_n       => i_emac0_tx_ll_sof_n_tmp,     --: out std_logic;
--ll_a_tx_eof_n       => i_emac0_tx_ll_eof_n_tmp,     --: out std_logic;
--ll_a_tx_src_rdy_n   => i_emac0_tx_ll_src_rdy_n_tmp, --: out std_logic;
--ll_a_tx_dst_rdy_n   => i_emac0_tx_ll_dst_rdy_n_tmp, --: in  std_logic;
--
----//Связь с логикой пользователя
--ll_1_rx_data        => i_emac0_rx_ll_data,       --: out std_logic_vector(7 downto 0);
--ll_1_rx_sof_n       => i_emac0_rx_ll_sof_n,      --: out std_logic;
--ll_1_rx_eof_n       => i_emac0_rx_ll_eof_n,      --: out std_logic;
--ll_1_rx_src_rdy_n   => i_emac0_rx_ll_src_rdy_n,  --: out std_logic;
--ll_1_rx_dst_rdy_n   => i_emac0_rx_ll_dst_rdy_n,  --: in  std_logic;
--
--ll_1_tx_data        => i_emac0_tx_ll_data,       --: in  std_logic_vector(7 downto 0);
--ll_1_tx_sof_n       => i_emac0_tx_ll_sof_n,      --: in  std_logic;
--ll_1_tx_eof_n       => i_emac0_tx_ll_eof_n,      --: in  std_logic;
--ll_1_tx_src_rdy_n   => i_emac0_tx_ll_src_rdy_n,  --: in  std_logic;
--ll_1_tx_dst_rdy_n   => i_emac0_tx_ll_dst_rdy_n,  --: out std_logic;
--
---- Управление
--swap        => b_swap_ctr_swap,
--loopback    => b_swap_ctr_loop,
--address     => b_swap_ctr_adr,
--clk         => i_emac0_clk125MHz,
--rst         => i_emac0_rst
--);

i_emac0_rx_ll_fifo_status<=i_emac0_rx_ll_fifo_status_tmp;

--//*********************************************************************
--//Модули приема/передачи данных
--//*********************************************************************
--//Прием данных ETH
gen_set_ptrn : for i in 0 to 15 generate
i_usr0_mac_pattern(i)<=p_in_usr0_mac_pattern(8*(i+1)-1 downto 8*i);
end generate gen_set_ptrn;

i_usr0_rxpattern_param(C_PKT_MARKER_PATTERN_SIZE_MSB_BIT downto C_PKT_MARKER_PATTERN_SIZE_LSB_BIT)<=p_in_usr0_ctrl(C_DSN_ETHG_REG_MAC_RX_PATRN_SIZE_MSB_BIT downto C_DSN_ETHG_REG_MAC_RX_PATRN_SIZE_LSB_BIT);
i_usr0_rxpattern_param(15 downto C_PKT_MARKER_PATTERN_SIZE_MSB_BIT+1)<=(others=>'0');

m_eth_rx : eth_rx
generic map(
G_RD_REM_WIDTH    => G_REM_WIDTH,
G_RD_DWIDTH       => G_DWIDTH
)
port map
(
--//------------------------------------
--//Управление
--//------------------------------------
p_in_usr_ctrl                   => p_in_usr0_ctrl,
p_in_usr_pattern_param          => i_usr0_rxpattern_param,
p_in_usr_pattern                => i_usr0_mac_pattern,

--//------------------------------------
--//Связь с пользовательским RXBUF
--//------------------------------------
p_out_usr_rxdata                => i_usr0_rxdata,
p_out_usr_rxdata_wr             => i_usr0_rxdata_wr,
p_out_usr_rxdata_rdy            => i_usr0_rxdata_rdy,
p_out_usr_rxdata_sof            => p_out_usr0_rxdata_sof,
p_in_usr_rxbuf_full             => p_in_usr0_rxbuf_full,

--//------------------------------------
--//Связь с Local link RxFIFO
--//------------------------------------
p_in_rx_ll_data                 => i_emac0_rx_ll_data,
p_in_rx_ll_sof_n                => i_emac0_rx_ll_sof_n,
p_in_rx_ll_eof_n                => i_emac0_rx_ll_eof_n,
p_in_rx_ll_src_rdy_n            => i_emac0_rx_ll_src_rdy_n,
p_out_rx_ll_dst_rdy_n           => i_emac0_rx_ll_dst_rdy_n,
p_in_rx_ll_fifo_status          => i_emac0_rx_ll_fifo_status,

--//------------------------------------
--//Управление передачей PAUSE Control Frame
--//(более подробно см. ug194.pdf/Flow Control Block/Flow Control Implementation Example)
--//------------------------------------
p_out_pause_req                 => i_emac0_pause_req,
p_out_pause_val                 => i_emac0_pause_val,

--//------------------------------------
--//Статистика принятого пакета
--//------------------------------------
p_in_rx_statistic               => i_emac0_rx_statistic_usr,
p_in_rx_statistic_vld           => i_emac0_rx_statistic_usr_vld,

--//------------------------------------
--//SYSTEM
--//------------------------------------
p_in_clk                        => i_emac0_rx_client_clkin,
p_in_rst                        => i_emac0_rst
);

--//Передача данных ETH
i_usr0_txpattern_param(C_PKT_MARKER_PATTERN_SIZE_MSB_BIT downto C_PKT_MARKER_PATTERN_SIZE_LSB_BIT)<=p_in_usr0_ctrl(C_DSN_ETHG_REG_MAC_TX_PATRN_SIZE_MSB_BIT downto C_DSN_ETHG_REG_MAC_TX_PATRN_SIZE_LSB_BIT);
i_usr0_txpattern_param(15 downto C_PKT_MARKER_PATTERN_SIZE_MSB_BIT+1)<=(others=>'0');

m_eth_tx : eth_tx
generic map(
G_WR_REM_WIDTH    => G_REM_WIDTH,
G_WR_DWIDTH       => G_DWIDTH
)
port map
(
--//------------------------------------
--//Управление
--//------------------------------------
p_in_usr_ctrl                   => p_in_usr0_ctrl,
p_in_usr_pattern_param          => i_usr0_txpattern_param,
p_in_usr_pattern                => i_usr0_mac_pattern,

--//------------------------------------
--//Связь с пользовательским TXBUF
--//------------------------------------
p_in_usr_txdata                 => p_in_usr0_txdata,
p_out_usr_txdata_rd             => p_out_usr0_txdata_rd,
p_in_usr_txdata_rdy             => p_in_usr0_txdata_rdy,
p_in_usr_txbuf_empty            => p_in_usr0_txbuf_empty,
p_in_usr_txbuf_empty_almost     => p_in_usr0_txbuf_empty_almost,

--//------------------------------------
--//Связь с Local link TxFIFO
--//------------------------------------
p_out_tx_ll_data                => i_emac0_tx_ll_data,
p_out_tx_ll_sof_n               => i_emac0_tx_ll_sof_n,
p_out_tx_ll_eof_n               => i_emac0_tx_ll_eof_n,
p_out_tx_ll_src_rdy_n           => i_emac0_tx_ll_src_rdy_n,
p_in_tx_ll_dst_rdy_n            => i_emac0_tx_ll_dst_rdy_n,


--//------------------------------------
--//SYSTEM
--//------------------------------------
p_in_clk                        => i_emac0_tx_client_clkin,
p_in_rst                        => i_emac0_rst
);


process(i_emac0_rst,i_emac0_tx_client_clkin)
begin
  if i_emac0_rst='1' then
    i_tst_txdcnt<=(others=>'0');
  elsif i_emac0_tx_client_clkin'event and i_emac0_tx_client_clkin='1' then
    if i_emac0_tx_ll_src_rdy_n='1' then
      i_tst_txdcnt<=(others=>'0');
    else
      i_tst_txdcnt<=i_tst_txdcnt + 1;
    end if;
  end if;
end process;

--END MAIN
end behavioral;
