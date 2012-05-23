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
use work.gmii_pkg.all;

entity gmii_main is
generic(
G_GT_NUM      : integer:=0;
G_GT_CH_COUNT : integer:=2;
G_DBG : string:="OFF";
G_SIM : string:="OFF"
);
port(
--------------------------------------
--GMII
--------------------------------------
p_in_txd     : in    TBus02_GTCH;
p_in_tx_en   : in    std_logic_vector(C_GTCH_COUNT_MAX-1 downto 0);
p_in_tx_er   : in    std_logic_vector(C_GTCH_COUNT_MAX-1 downto 0);
p_in_tx_col  : out   std_logic_vector(C_GTCH_COUNT_MAX-1 downto 0);

p_out_rxd    : out   TBus02_GTCH;
p_out_rx_dv  : out   std_logic_vector(C_GTCH_COUNT_MAX-1 downto 0);
p_out_rx_er  : out   std_logic_vector(C_GTCH_COUNT_MAX-1 downto 0);
p_out_rx_crs : out   std_logic_vector(C_GTCH_COUNT_MAX-1 downto 0);

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
p_in_tst     : in    std_logic_vector(31 downto 0);
p_out_tst    : out   std_logic_vector(63 downto 0);

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

signal i_gt_ch_rst                 : std_logic_vector(C_GTCH_COUNT_MAX-1 downto 0);
signal i_gt_plllkdet               : std_logic;
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

signal tst_pcs_rx                  : std_logic_vector(31 downto 0);
signal tst_pcs_tx                  : std_logic_vector(31 downto 0);


--MAIN
begin

--//----------------------------------
--//Технологические сигналы
--//----------------------------------
gen_dbg_off : if strcmp(G_DBG,"OFF") generate
p_out_tst(63 downto 0)<=(others=>'0');
end generate gen_dbg_off;

gen_dbg_on : if strcmp(G_DBG,"ON") generate
p_out_tst(15 downto 0)<=tst_pcs_rx(15 downto 0);
p_out_tst(16)<=i_gt_ch_rst(0);

p_out_tst(24 downto 17)<=i_gt_txdata(0)(7 downto 0);
p_out_tst(25)<=i_gt_txcharisk(0)(0);

p_out_tst(26)<=i_gt_txreset(0);
p_out_tst(28 downto 27)<=i_gt_txbufstatus(0);

p_out_tst(36 downto 29)<=i_gt_rxdata(0)(7 downto 0);
p_out_tst(37)<=i_gt_rxcharisk(0)(0);
p_out_tst(38)<=i_gt_rxbufreset(0);
p_out_tst(41 downto 39)<=i_gt_rxbufstatus(0);

p_out_tst(43 downto 40)<=i_gt_rxdisperr(0);
p_out_tst(47 downto 44)<=i_gt_rxnotintable(0);
p_out_tst(48)<=i_gt_rxbyteisaligned(0);

p_out_tst(63 downto 49)<=(others=>'0');
end generate gen_dbg_on;


--//###########################################################################
--//Размножение модулей управления соответствующего канала GT (RocketIO)
--//###########################################################################
gen_ch: for i in 0 to G_GT_CH_COUNT-1 generate

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
                                       (i)
p_out_gt_txreset    => i_gt_txreset    (i),
p_in_gt_txbufstatus => i_gt_txbufstatus(i),

--------------------------------------
--Технологические сигналы
--------------------------------------
p_in_tst  => (others=>'0'),
p_out_tst => tst_pcs_rx   ,

--------------------------------------
--SYSTEM
--------------------------------------
p_in_clk  => g_gt_usrclk2(i),
p_in_rst  => i_gt_ch_rst(i)
);

m_rx : gmii_pcs_tx
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
p_out_tst => tst_pcs_tx   ,

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

process(p_in_rst,i_gt_refclk)
begin
  if p_in_rst='1' then
    i_gt_ch_rst<=(others=>'1');

  elsif i_gt_refclk'event and i_gt_refclk='1' then

    if i_gt_plllkdet='1' and AND_reduce(i_gt_resetdone)='1' then
      i_gt_ch_rst<=(others=>'0');
    end if;

  end if;
end process;
----Автомат программирования регистров GTP
--process(p_in_rst,i_gt_refclk)
--begin
--  if p_in_rst='1' then
--
--    fsm_spdctrl_cs<=S_IDLE;
--    i_gt_ch_rst<=(others=>'0');
--
--  elsif i_gt_refclk'event and i_gt_refclk='1' then
--
--    case fsm_spdctrl_cs is
--
--      -----------------------------------------------
--      --Жду пока установятся тактовые частоты
--      -----------------------------------------------
--      when S_IDLE =>
--
--        if i_gt_plllkdet='1' and AND_reduce(i_gt_resetdone)='1' then
--          if i_tmr=CONV_STD_LOGIC_VECTOR(16#0F#, i_tmr'length) then
--            i_tmr_en<='0';
--            fsm_spdctrl_cs<=S_IDLE_INIT;
--          else
--            i_tmr_en<='1';
--          end if;
--        end if;
--
--      -----------------------------------------------
--      --Cброс GT
--      -----------------------------------------------
--      when S_IDLE_INIT =>
--
--        if i_tmr=CONV_STD_LOGIC_VECTOR(16#01F#, i_tmr'length) then
--          i_tmr_en<='0';
--          i_gt_ch_rst<=(others=>'0');
--          fsm_spdctrl_cs<=S_IDLE_INIT_DONE;
--
--        elsif i_tmr=CONV_STD_LOGIC_VECTOR(16#0F#, i_tmr'length) then
--          i_gt_ch_rst<=(others=>'1');
--
--        else
--          i_tmr_en<='1';
--        end if;
--
--      when S_IDLE_INIT_DONE =>
--
--        --Ждем завершения процеса сброса GT
--        if i_gt_plllkdet='1' and AND_reduce(i_gt_resetdone)='1' then
--          fsm_spdctrl_cs<=S_LINKUP;
--        end if;
--
--      when S_LINKUP =>
--
--          fsm_spdctrl_cs<=S_LINKUP;
--
--    end case;
--  end if;
--end process;


--END MAIN
end struct;

