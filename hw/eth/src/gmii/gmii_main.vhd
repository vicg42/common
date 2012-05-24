-------------------------------------------------------------------------
-- Company     : Linkos
-- Engineer    : Golovachenko Victor
--
-- Create Date : 22.05.2012 11:55:44
-- Module Name : gmii_main
--
-- Назначение/Описание :
--
--
--
-------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_misc.all;
use ieee.std_logic_unsigned.all;

library work;
use work.vicg_common_pkg.all;
use work.gmii_unit_pkg.all;
use work.gmii_pkg.all;

entity gmii_main is
generic(
G_GT_NUM      : integer:=0;
G_GT_CH_COUNT : integer:=2;
G_GT_DBUS     : integer:=8;
G_DBGCS : string:="OFF";
G_DBG : string:="OFF";
G_SIM : string:="OFF"
);
port(
--------------------------------------
--GMII
--------------------------------------
p_in_txd     : in    TBus08_GTCH;
p_in_tx_en   : in    std_logic_vector(C_GTCH_COUNT_MAX-1 downto 0);
p_in_tx_er   : in    std_logic_vector(C_GTCH_COUNT_MAX-1 downto 0);
p_in_tx_col  : out   std_logic_vector(C_GTCH_COUNT_MAX-1 downto 0);

p_out_rxd    : out   TBus08_GTCH;
p_out_rx_dv  : out   std_logic_vector(C_GTCH_COUNT_MAX-1 downto 0);
p_out_rx_er  : out   std_logic_vector(C_GTCH_COUNT_MAX-1 downto 0);
p_out_rx_crs : out   std_logic_vector(C_GTCH_COUNT_MAX-1 downto 0);

p_out_clk    : out   std_logic_vector(C_GTCH_COUNT_MAX-1 downto 0);

--------------------------------------
--Driver(Сигналы подоваемые на разъем)
--------------------------------------
p_out_txn    : out   std_logic_vector(C_GTCH_COUNT_MAX-1 downto 0);
p_out_txp    : out   std_logic_vector(C_GTCH_COUNT_MAX-1 downto 0);
p_in_rxn     : in    std_logic_vector(C_GTCH_COUNT_MAX-1 downto 0);
p_in_rxp     : in    std_logic_vector(C_GTCH_COUNT_MAX-1 downto 0);

--------------------------------------
--Технологические сигналы
--------------------------------------
p_out_dbgcs  : out   TETH_ila;
p_in_tst     : in    std_logic_vector(31 downto 0);
p_out_tst    : out   std_logic_vector(31 downto 0);

--------------------------------------
--SYSTEM
--------------------------------------
p_out_gt_pllkdet : out   std_logic;
p_out_gt_refclk  : out   std_logic;--//выход порта REFCLKOUT модуля GT/sata_player_gt.vhdl
p_in_gt_drpclk   : in    std_logic;--//
p_in_gt_refclk   : in    std_logic;--//CLKIN для модуля GT (RocketIO)

p_in_rst         : in    std_logic
);
end gmii_main;

architecture struct of gmii_main is

--type TSpdCtrl_fsm_state is (
--S_IDLE,
--S_IDLE_INIT,
--S_IDLE_INIT_DONE,
--S_LINKUP
--);
--signal fsm_spdctrl_cs              : TSpdCtrl_fsm_state;
--
--signal i_tmr                       : std_logic_vector(4 downto 0);
--signal i_tmr_en                    : std_logic;
signal i_gt_ch_rst_tmp             : std_logic_vector(C_GTCH_COUNT_MAX-1 downto 0);
signal i_gt_ch_rst                 : std_logic_vector(C_GTCH_COUNT_MAX-1 downto 0);
signal i_gt_plllkdet               : std_logic;
signal i_gt_refclk                 : std_logic;
signal i_gt_resetdone              : std_logic_vector(C_GTCH_COUNT_MAX-1 downto 0);
signal g_gt_usrclk2                : std_logic_vector(C_GTCH_COUNT_MAX-1 downto 0);

signal i_gt_drpaddr                : std_logic_vector(7 downto 0):=(others=>'0');
signal i_gt_drpen                  : std_logic:='0';
signal i_gt_drpwe                  : std_logic:='0';
signal i_gt_drpdi                  : std_logic_vector(15 downto 0):=(others=>'0');
signal i_gt_drpdo                  : std_logic_vector(15 downto 0);
signal i_gt_drprdy                 : std_logic;

signal i_gt_rxreset                : std_logic_vector(C_GTCH_COUNT_MAX-1 downto 0);
signal i_gt_rxstatus               : TBus03_GTCH;
signal i_gt_rxelecidle             : std_logic_vector(C_GTCH_COUNT_MAX-1 downto 0):=(others=>'0');
signal i_gt_rxdata                 : TBus32_GTCH;
signal i_gt_rxcharisk              : TBus04_GTCH;
signal i_gt_rxdisperr              : TBus04_GTCH;
signal i_gt_rxnotintable           : TBus04_GTCH;
signal i_gt_rxbyteisaligned        : std_logic_vector(C_GTCH_COUNT_MAX-1 downto 0):=(others=>'0');

signal i_gt_rxbufstatus            : TBus03_GTCH;
signal i_gt_rxbufreset             : std_logic_vector(C_GTCH_COUNT_MAX-1 downto 0):=(others=>'0');

signal i_gt_txreset                : std_logic_vector(C_GTCH_COUNT_MAX-1 downto 0):=(others=>'0');
signal i_gt_txbufreset             : std_logic_vector(C_GTCH_COUNT_MAX-1 downto 0):=(others=>'0');
signal i_gt_txbufstatus            : TBus02_GTCH;

signal i_gt_txdata                 : TBus32_GTCH;
signal i_gt_txcharisk              : TBus04_GTCH;
signal i_gt_txchadipmode           : TBus02_GTCH;
signal i_gt_txchadipval            : TBus02_GTCH;

signal i_rxcfg                     : TBus16_GTCH;

signal tst_pcs_rx                  : TBus32_GTCH;
signal tst_pcs_tx                  : TBus32_GTCH;
signal tst_gt_ch_rst               : std_logic;

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


--//###########################################################################
--//Размножение модулей управления соответствующего канала GT (RocketIO)
--//###########################################################################
gen_ch: for i in 0 to G_GT_CH_COUNT-1 generate

p_out_clk(i)<=g_gt_usrclk2(i);

m_tx : gmii_pcs_tx
generic map(
G_GT_DBUS => G_GT_DBUS,
G_DBG => G_DBG,
G_SIM => G_SIM
)
port map(
--------------------------------------
--GMII
--------------------------------------
p_in_txd             => p_in_txd   (i),
p_in_tx_en           => p_in_tx_en (i),
p_in_tx_er           => p_in_tx_er (i),
p_in_tx_col          => p_in_tx_col(i),

--------------------------------------
--RocketIO Transmiter
--------------------------------------
p_out_gt_txdata     => i_gt_txdata     (i),
p_out_gt_txcharisk  => i_gt_txcharisk  (i),

p_out_gt_txreset    => i_gt_txreset    (i),
p_in_gt_txbufstatus => i_gt_txbufstatus(i),

--------------------------------------
--Технологические сигналы
--------------------------------------
p_in_tst  => (others=>'0'),
p_out_tst => tst_pcs_tx(i),

--------------------------------------
--SYSTEM
--------------------------------------
p_in_clk  => g_gt_usrclk2(i),
p_in_rst  => i_gt_ch_rst(i)
);

m_rx : gmii_pcs_rx
generic map(
G_GT_DBUS => G_GT_DBUS,
G_DBG => G_DBG,
G_SIM => G_SIM
)
port map(
--------------------------------------
--GMII
--------------------------------------
p_out_rxd              => p_out_rxd   (i),
p_out_rx_dv            => p_out_rx_dv (i),
p_out_rx_er            => p_out_rx_er (i),
p_out_rx_crs           => p_out_rx_crs(i),

--------------------------------------
--
--------------------------------------
p_out_rxcfg            => i_rxcfg(i),

--------------------------------------
--RocketIO Receiver
--------------------------------------
p_in_gt_rxdata          => i_gt_rxdata         (i),
p_in_gt_rxcharisk       => i_gt_rxcharisk      (i),
p_in_gt_rxdisperr       => i_gt_rxdisperr      (i),
p_in_gt_rxnotintable    => i_gt_rxnotintable   (i),
p_in_gt_rxbyteisaligned => i_gt_rxbyteisaligned(i),

p_in_gt_rxbufstatus     => i_gt_rxbufstatus    (i),
p_out_gt_rxbufreset     => i_gt_rxbufreset     (i),

--------------------------------------
--Технологические сигналы
--------------------------------------
p_in_tst  => (others=>'0'),
p_out_tst => tst_pcs_rx(i),

--------------------------------------
--SYSTEM
--------------------------------------
p_in_clk  => g_gt_usrclk2(i),
p_in_rst  => i_gt_ch_rst(i)
);
end generate gen_ch;


--//############################
--//GT (RocketIO)
--//############################
gen_sim_off : if strcmp(G_SIM,"OFF") generate

m_gt : gmii_pma
generic map(
G_GT_NUM      => G_GT_NUM,
G_GT_CH_COUNT => G_GT_CH_COUNT,
G_GT_DBUS     => G_GT_DBUS,
G_SIM         => G_SIM
)
port map(
--------------------------------------------------
--
--------------------------------------------------
p_out_usrclk2          => g_gt_usrclk2,
p_out_resetdone        => i_gt_resetdone,

--------------------------------------------------
--Driver
--------------------------------------------------
p_out_txn              => p_out_txn,
p_out_txp              => p_out_txp,
p_in_rxn               => p_in_rxn,
p_in_rxp               => p_in_rxp,

--------------------------------------------------
--Tranceiver
--------------------------------------------------
p_in_txdata            => i_gt_txdata,
p_in_txcharisk         => i_gt_txcharisk,
p_in_txchadipmode      => i_gt_txchadipmode,
p_in_txchadipval       => i_gt_txchadipval,

p_in_txreset           => i_gt_txreset,
p_out_txbufstatus      => i_gt_txbufstatus,

--------------------------------------------------
--Receiver
--------------------------------------------------
p_in_rxreset           => i_gt_rxreset,

p_out_rxstatus         => i_gt_rxstatus,
p_out_rxdata           => i_gt_rxdata,
p_out_rxcharisk        => i_gt_rxcharisk,
p_out_rxdisperr        => i_gt_rxdisperr,
p_out_rxnotintable     => i_gt_rxnotintable,
p_out_rxbyteisaligned  => i_gt_rxbyteisaligned,

p_in_rxbufreset        => i_gt_rxbufreset,
p_out_rxbufstatus      => i_gt_rxbufstatus,

--------------------------------------------------
--System
--------------------------------------------------
p_in_drpclk            => p_in_gt_drpclk,--'0'          ,--
p_in_drpaddr           => i_gt_drpaddr,  --(others=>'0'),--
p_in_drpen             => i_gt_drpen,    --'0'          ,--
p_in_drpwe             => i_gt_drpwe,    --'0'          ,--
p_in_drpdi             => i_gt_drpdi,    --(others=>'0'),--
p_out_drpdo            => i_gt_drpdo,    --open         ,--
p_out_drprdy           => i_gt_drprdy,   --open         ,--

p_out_plllock          => i_gt_plllkdet,
p_out_refclkout        => i_gt_refclk,

p_in_refclkin          => p_in_gt_refclk,

--p_in_optrefclksel      => p_in_optrefclksel,
--p_in_optrefclk         => p_in_optrefclk,
--p_out_optrefclk        => p_out_optrefclk,

p_in_rst               => p_in_rst
);

end generate gen_sim_off;

p_out_gt_refclk<=i_gt_refclk;

i_gt_rxreset<=(others=>'0');--i_gt_ch_rst;
--i_gt_ch_rst(0)<=not tst_gt_ch_rst or p_in_rst;
--i_gt_ch_rst(1)<=not tst_gt_ch_rst or p_in_rst;

process(p_in_rst,i_gt_refclk)
begin
  if p_in_rst='1' then
    i_gt_ch_rst<=(others=>'1');
    tst_gt_ch_rst<='0';
  elsif i_gt_refclk'event and i_gt_refclk='1' then

    if i_gt_plllkdet='1' and AND_reduce(i_gt_resetdone)='1' then
      tst_gt_ch_rst<='1';
      i_gt_ch_rst<=(others=>'0');
    end if;

  end if;
end process;


--//------------------------------------
--//DBG
--//------------------------------------
gen_dbgcs : if strcmp(G_DBGCS,"ON") generate

p_out_dbgcs.clk <= g_gt_usrclk2(0);

--//-------- TRIG: ------------------
p_out_dbgcs.trig0(5 downto 0)  <=tst_pcs_rx(0)(5  downto 0);--<=tst_fsm_pcs_sync;
p_out_dbgcs.trig0(11 downto 6) <=tst_pcs_rx(0)(11 downto 6);--<=tst_fsm_pcs_rx;
p_out_dbgcs.trig0(17 downto 12)<=tst_pcs_tx(0)(5 downto 0);--<=tst_fsm_pcs_tx;

p_out_dbgcs.trig0(18)          <=i_gt_ch_rst(0);

p_out_dbgcs.trig0(19)          <=i_gt_txreset(0);
p_out_dbgcs.trig0(21 downto 20)<=i_gt_txbufstatus(0);

p_out_dbgcs.trig0(22)          <=i_gt_rxbufreset(0);
p_out_dbgcs.trig0(25 downto 23)<=i_gt_rxbufstatus(0);

p_out_dbgcs.trig0(41 downto 26)<=(others=>'0');


--//-------- VIEW: ------------------
p_out_dbgcs.data(5 downto 0)   <=tst_pcs_rx(0)(5  downto 0);--<=tst_fsm_pcs_sync;
p_out_dbgcs.data(11 downto 6)  <=tst_pcs_rx(0)(11 downto 6);--<=tst_fsm_pcs_rx;
p_out_dbgcs.data(17 downto 12) <=tst_pcs_tx(0)(5 downto 0);--<=tst_fsm_pcs_tx;

p_out_dbgcs.data(18)           <=tst_pcs_rx(0)(12);--<=i_rx_even;
p_out_dbgcs.data(19)           <=i_gt_ch_rst(0);
p_out_dbgcs.data(20)           <=tst_gt_ch_rst;
p_out_dbgcs.data(31 downto 21) <=(others=>'0');


p_out_dbgcs.data(39 downto 32) <=i_gt_txdata(0)(7 downto 0);
p_out_dbgcs.data(40)           <=i_gt_txcharisk(0)(0);
p_out_dbgcs.data(48 downto 41) <=i_gt_rxdata(0)(7 downto 0);
p_out_dbgcs.data(49)           <=i_gt_rxcharisk(0)(0);

p_out_dbgcs.data(50)           <=i_gt_txreset(0);
p_out_dbgcs.data(52 downto 51) <=i_gt_txbufstatus(0);

p_out_dbgcs.data(53)           <=i_gt_rxbufreset(0);
p_out_dbgcs.data(56 downto 54) <=i_gt_rxbufstatus(0);

p_out_dbgcs.data(60 downto 57) <=i_gt_rxdisperr(0);
p_out_dbgcs.data(64 downto 61) <=i_gt_rxnotintable(0);
p_out_dbgcs.data(65)           <=i_gt_rxbyteisaligned(0);

p_out_dbgcs.data(115 downto 100)<=i_rxcfg(0)(15 downto 0);
p_out_dbgcs.data(172 downto 116)<=(others=>'0');

end generate gen_dbgcs;

--END MAIN
end struct;

