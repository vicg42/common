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

library unisim;
use unisim.vcomponents.all;

library work;
use work.vicg_common_pkg.all;
use work.eth_pkg.all;

entity eth_main is
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
end eth_main;


architecture behavioral of eth_main is


signal i_eth_rst                      : std_logic_vector(C_GTCH_COUNT_MAX-1 downto 0);
signal i_eth_clk125MHz                : std_logic_vector(C_GTCH_COUNT_MAX-1 downto 0);
signal i_eth_phyad                    : TBus05_GTCH;
signal i_eth_tx_ifg_delay             : TBus08_GTCH;
signal i_eth_pause_req                : std_logic_vector(C_GTCH_COUNT_MAX-1 downto 0);
signal i_eth_pause_val                : TBus16_GTCH;

signal i_eth_rxll_data                : TBus08_GTCH;
signal i_eth_rxll_sof_n               : std_logic_vector(C_GTCH_COUNT_MAX-1 downto 0);
signal i_eth_rxll_eof_n               : std_logic_vector(C_GTCH_COUNT_MAX-1 downto 0);
signal i_eth_rxll_src_rdy_n           : std_logic_vector(C_GTCH_COUNT_MAX-1 downto 0);
signal i_eth_rxll_dst_rdy_n           : std_logic_vector(C_GTCH_COUNT_MAX-1 downto 0);
signal i_eth_rxll_fifo_status         : TBus04_GTCH;

signal i_eth_txll_data                : TBus08_GTCH;
signal i_eth_txll_sof_n               : std_logic_vector(C_GTCH_COUNT_MAX-1 downto 0);
signal i_eth_txll_eof_n               : std_logic_vector(C_GTCH_COUNT_MAX-1 downto 0);
signal i_eth_txll_src_rdy_n           : std_logic_vector(C_GTCH_COUNT_MAX-1 downto 0);
signal i_eth_txll_dst_rdy_n           : std_logic_vector(C_GTCH_COUNT_MAX-1 downto 0);


signal i_eth_rx_tst_out               : std_logic_vector(31 downto 0);
signal i_eth_tx_tst_out               : std_logic_vector(31 downto 0);
signal i_eth_core_tst_out             : std_logic_vector(31 downto 0);


--MAIN
begin


--//----------------------------------
--//Технологические сигналы
--//----------------------------------
gen_dbg_off : if strcmp(G_DBG,"OFF") generate
p_out_tst(31 downto 0)<=(others=>'0');
end generate gen_dbg_off;

gen_dbg_on : if strcmp(G_DBG,"ON") generate
--ltstout:process(p_in_rst,p_in_clk)
--begin
--  if p_in_rst='1' then
--    tst_fms_cs_dly<=(others=>'0');
--    p_out_tst(31 downto 1)<=(others=>'0');
--  elsif p_in_clk'event and p_in_clk='1' then
--
--    tst_fms_cs_dly<=tst_fms_cs;
--    p_out_tst(0)<=OR_reduce(tst_fms_cs_dly);
--  end if;
--end process ltstout;

p_out_tst(0)<=i_eth_rx_tst_out(0) or i_eth_tx_tst_out(0);
p_out_tst(31 downto 1)<=(others=>'0');

end generate gen_dbg_on;



--//-----------------------------
--//Инициализация
--//-----------------------------

--//Определяем адреса устройства(MAC0,MAC1) для доступа к PCS/PMA Management Registers
i_eth_phyad(0)<= CONV_STD_LOGIC_VECTOR(16#10#, i_eth_phyad(0)'length);
i_eth_phyad(1)<= CONV_STD_LOGIC_VECTOR(16#11#, i_eth_phyad(0)'length);

--//Более подробно см. ug194.pdf/Transmit (TX) Client: 8-Bit Interface (without Clock Enables)/IFG Adjustment
--//x0D minimum IFG specified in IEEE802.3, the minimum IFG (12 idles).
i_eth_tx_ifg_delay(0)  <= CONV_STD_LOGIC_VECTOR(16#0D#, i_eth_tx_ifg_delay(0)'length);
i_eth_tx_ifg_delay(1)  <= CONV_STD_LOGIC_VECTOR(16#0D#, i_eth_tx_ifg_delay(0)'length);


p_out_eth_gt_refclkout<=i_eth_clk125MHz(0);


p_out_eth_rxbuf_din(1)<=(others=>'0');
p_out_eth_rxbuf_wr(1)<='0';
p_out_eth_rxd_sof(1)<='0';
p_out_eth_rxd_eof(1)<='0';

p_out_eth_txbuf_rd(1)<='0';



--//----------------------------------
--//Модули приема/передачи данных
--//----------------------------------
m_eth_rx : eth_rx
generic map(
G_DBG => G_DBG,
G_SIM => G_SIM
)
port map(
--//------------------------------------
--//Управление
--//------------------------------------
p_in_cfg              => p_in_eth_cfg(0),

--//------------------------------------
--//Связь с пользовательским RXBUF
--//------------------------------------
p_out_rxbuf_din       => p_out_eth_rxbuf_din(0),
p_out_rxbuf_wr        => p_out_eth_rxbuf_wr(0),
p_in_rxbuf_full       => p_in_eth_rxbuf_full(0),
p_out_rxd_sof         => p_out_eth_rxd_sof(0),
p_out_rxd_eof         => p_out_eth_rxd_eof(0),

--//------------------------------------
--//Связь с Local link RxFIFO
--//------------------------------------
p_in_rxll_data        => i_eth_rxll_data(0),
p_in_rxll_sof_n       => i_eth_rxll_sof_n(0),
p_in_rxll_eof_n       => i_eth_rxll_eof_n(0),
p_in_rxll_src_rdy_n   => i_eth_rxll_src_rdy_n(0),
p_out_rxll_dst_rdy_n  => i_eth_rxll_dst_rdy_n(0),
p_in_rxll_fifo_status => i_eth_rxll_fifo_status(0),

--//------------------------------------
--//Управление передачей PAUSE Control Frame
--//(более подробно см. ug194.pdf/Flow Control Block/Flow Control Implementation Example)
--//------------------------------------
p_out_pause_req       => i_eth_pause_req(0),
p_out_pause_val       => i_eth_pause_val(0),

--------------------------------------------------
--Технологические сигналы
--------------------------------------------------
p_in_tst              => p_in_tst,
p_out_tst             => i_eth_rx_tst_out,

--//------------------------------------
--//SYSTEM
--//------------------------------------
p_in_clk              => i_eth_clk125MHz(0),
p_in_rst              => i_eth_rst(0)
);


m_eth_tx : eth_tx
generic map(
G_DBG => G_DBG,
G_SIM => G_SIM
)
port map(
--//------------------------------------
--//Управление
--//------------------------------------
p_in_cfg             => p_in_eth_cfg(0),

--//------------------------------------
--//Связь с пользовательским TXBUF
--//------------------------------------
p_in_txbuf_dout      => p_in_eth_txbuf_dout(0),
p_out_txbuf_rd       => p_out_eth_txbuf_rd(0),
p_in_txbuf_empty     => p_in_eth_txbuf_empty(0),
--p_in_txd_rdy         => p_in_eth_txd_rdy(0),

--//------------------------------------
--//Связь с Local link TxFIFO
--//------------------------------------
p_out_txll_data      => i_eth_txll_data(0),
p_out_txll_sof_n     => i_eth_txll_sof_n(0),
p_out_txll_eof_n     => i_eth_txll_eof_n(0),
p_out_txll_src_rdy_n => i_eth_txll_src_rdy_n(0),
p_in_txll_dst_rdy_n  => i_eth_txll_dst_rdy_n(0),

--------------------------------------------------
--Технологические сигналы
--------------------------------------------------
p_in_tst             => p_in_tst,
p_out_tst            => i_eth_tx_tst_out,

--//------------------------------------
--//SYSTEM
--//------------------------------------
p_in_clk             => i_eth_clk125MHz(0),
p_in_rst             => i_eth_rst(0)
);



--//********************************************
--//********  Ethernet MAC - Core  *************
--//********************************************
m_emac_core_main : emac_core_main
port map(
--//------------------------------------
--//EMAC - Channel 0
--//------------------------------------
--//#########  Client side  #########
-- Local link Receiver Interface - EMAC0
--RX_LL_CLOCK_0                   : in  std_logic;
--RX_LL_RESET_0                   : in  std_logic;
RX_LL_DATA_0                    => i_eth_rxll_data(0),       --: out std_logic_vector(7 downto 0);
RX_LL_SOF_N_0                   => i_eth_rxll_sof_n(0),      --: out std_logic;
RX_LL_EOF_N_0                   => i_eth_rxll_eof_n(0),      --: out std_logic;
RX_LL_SRC_RDY_N_0               => i_eth_rxll_src_rdy_n(0),  --: out std_logic;
RX_LL_DST_RDY_N_0               => i_eth_rxll_dst_rdy_n(0),  --: in  std_logic;
RX_LL_FIFO_STATUS_0             => i_eth_rxll_fifo_status(0),--: out std_logic_vector(3 downto 0);

-- Local link Transmitter Interface - EMAC0
--TX_LL_CLOCK_0                   : in  std_logic;
--TX_LL_RESET_0                   : in  std_logic;
TX_LL_DATA_0                    => i_eth_txll_data(0),        --: in  std_logic_vector(7 downto 0);
TX_LL_SOF_N_0                   => i_eth_txll_sof_n(0),       --: in  std_logic;
TX_LL_EOF_N_0                   => i_eth_txll_eof_n(0),       --: in  std_logic;
TX_LL_SRC_RDY_N_0               => i_eth_txll_src_rdy_n(0),   --: in  std_logic;
TX_LL_DST_RDY_N_0               => i_eth_txll_dst_rdy_n(0),   --: out std_logic;

-- Client Receiver Interface - EMAC0
EMAC0CLIENTRXDVLD               => open,--i_eth0_rx_client_dvld,        --: out std_logic;
EMAC0CLIENTRXFRAMEDROP          => open,--i_eth0_rx_client_framedrop,   --: out std_logic;
EMAC0CLIENTRXSTATS              => open,--i_eth0_rx_client_stats,       --: out std_logic_vector(6 downto 0);
EMAC0CLIENTRXSTATSVLD           => open,--i_eth0_rx_client_statsvld,    --: out std_logic;
EMAC0CLIENTRXSTATSBYTEVLD       => open,--i_eth0_rx_client_statsbytevld,--: out std_logic;

-- Client Transmitter Interface - EMAC0
CLIENTEMAC0TXIFGDELAY           => i_eth_tx_ifg_delay(0),          --: in  std_logic_vector(7 downto 0);
EMAC0CLIENTTXSTATS              => open,--i_eth0_tx_client_stats,       --: out std_logic;
EMAC0CLIENTTXSTATSVLD           => open,--i_eth0_tx_client_statsvld,    --: out std_logic;
EMAC0CLIENTTXSTATSBYTEVLD       => open,--i_eth0_tx_client_statsbytevld,--: out std_logic;

-- MAC Control Interface - EMAC0
CLIENTEMAC0PAUSEREQ             => i_eth_pause_req(0),--: in  std_logic;
CLIENTEMAC0PAUSEVAL             => i_eth_pause_val(0),--: in  std_logic_vector(15 downto 0);

--EMAC-MGT link status
EMAC0CLIENTSYNCACQSTATUS        => open,--p_out_eth0_sync_acq_status,--: out std_logic;
-- EMAC0 Interrupt
EMAC0ANINTERRUPT                => open,--i_eth0_int,--: out std_logic;

--//#########  PHY side  #########
-- Clock Signals - EMAC0
-- 1000BASE-X PCS/PMA Interface - EMAC0
PHYAD_0                         => i_eth_phyad(0),      --: in  std_logic_vector(4 downto 0);
TXP_0                           => p_out_eth_gt_txp(0), --: out std_logic;
TXN_0                           => p_out_eth_gt_txn(0), --: out std_logic;
RXP_0                           => p_in_eth_gt_rxp(0),  --: in  std_logic;
RXN_0                           => p_in_eth_gt_rxn(0),  --: in  std_logic;

-- 1000BASE-X PCS/PMA RocketIO Reference Clock buffer inputs
p_in_emac_0_clkref              => p_in_eth_gt_refclk,--: in std_logic;

p_out_emac_0_clk125MHz          => i_eth_clk125MHz(0),--: out std_logic;
p_out_emac_0_rst                => i_eth_rst(0),      --: out std_logic;

--//------------------------------------
--//EMAC - Channel 1
--//------------------------------------
PHYAD_1                         => i_eth_phyad(0),      --: in  std_logic_vector(4 downto 0);
TXP_1                           => p_out_eth_gt_txp(1),--: out std_logic;
TXN_1                           => p_out_eth_gt_txn(1),--: out std_logic;
RXP_1                           => p_in_eth_gt_rxp(1), --: in  std_logic;
RXN_1                           => p_in_eth_gt_rxn(1), --: in  std_logic;


--//------------------------------------
--//SYSTEM
--//------------------------------------
p_in_drp_ctrl                   => p_in_gctrl,
p_out_gtp_plllkdet              => p_out_eth_gt_plllkdet,
p_out_ust_tst                   => i_eth_core_tst_out,

-- Asynchronous Reset
RESET                           => p_in_rst --: in std_logic;
);





--END MAIN
end behavioral;
