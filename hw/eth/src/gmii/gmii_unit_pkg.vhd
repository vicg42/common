------------------------------------------------------------------------
-- Company     : Linkos
-- Engineer    : Golovachenko Victor
--
-- Create Date : 24.05.2012 10:44:58
-- Module Name : gmii_unot_pkg
--
-- Description : Прототипы компонент
--
-- Revision:
-- Revision 0.01 - File Created
--
-------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_arith.all;

library work;
use work.vicg_common_pkg.all;
use work.gmii_pkg.all;

package gmii_unit_pkg is

component gmii_main is
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
end component;

component gmii_pcs_tx
generic(
G_GT_DBUS : integer:=8;
G_DBG : string:="OFF";
G_SIM : string:="OFF"
);
port(
--------------------------------------
--GMII
--------------------------------------
p_in_txd            : in    std_logic_vector(7 downto 0);
p_in_tx_en          : in    std_logic;
p_in_tx_er          : in    std_logic;
p_in_tx_col         : out   std_logic;

--------------------------------------
--RocketIO Transmiter
--------------------------------------
p_out_gt_txdata     : out   std_logic_vector(31 downto 0);
p_out_gt_txcharisk  : out   std_logic_vector(3 downto 0);

p_out_gt_txreset    : out   std_logic;
p_in_gt_txbufstatus : in    std_logic_vector(1 downto 0);

--------------------------------------
--Технологические сигналы
--------------------------------------
p_in_tst            : in    std_logic_vector(31 downto 0);
p_out_tst           : out   std_logic_vector(31 downto 0);

--------------------------------------
--SYSTEM
--------------------------------------
p_in_clk            : in    std_logic;
p_in_rst            : in    std_logic
);
end component;

component gmii_pcs_rx
generic(
G_GT_DBUS : integer:=8;
G_DBG : string:="OFF";
G_SIM : string:="OFF"
);
port(
--------------------------------------
--GMII
--------------------------------------
p_out_rxd               : out   std_logic_vector(7 downto 0);
p_out_rx_dv             : out   std_logic;
p_out_rx_er             : out   std_logic;
p_out_rx_crs            : out   std_logic;

--------------------------------------
--
--------------------------------------
p_out_rxcfg             : out   std_logic_vector(15 downto 0);

--------------------------------------
--RocketIO Receiver
--------------------------------------
p_in_gt_rxdata          : in    std_logic_vector(31 downto 0);
p_in_gt_rxcharisk       : in    std_logic_vector(3 downto 0);
p_in_gt_rxdisperr       : in    std_logic_vector(3 downto 0);
p_in_gt_rxnotintable    : in    std_logic_vector(3 downto 0);
p_in_gt_rxbyteisaligned : in    std_logic;

p_in_gt_rxbufstatus     : in    std_logic_vector(2 downto 0);
p_out_gt_rxbufreset     : out   std_logic;

--------------------------------------
--Технологические сигналы
--------------------------------------
p_in_tst                : in    std_logic_vector(31 downto 0);
p_out_tst               : out   std_logic_vector(31 downto 0);

--------------------------------------
--SYSTEM
--------------------------------------
p_in_clk                : in    std_logic;
p_in_rst                : in    std_logic
);
end component;

component gmii_pma
generic(
G_GT_NUM      : integer:=0;
G_GT_CH_COUNT : integer:=2;
G_GT_DBUS     : integer:=8;
G_SIM         : string :="OFF"
);
port(
---------------------------------------------------------------------------
--Usr Cfg
---------------------------------------------------------------------------
p_out_usrclk2          : out   std_logic_vector(C_GTCH_COUNT_MAX-1 downto 0); --//Тактирование модулей sata_host.vhd
p_out_resetdone        : out   std_logic_vector(C_GTCH_COUNT_MAX-1 downto 0);

---------------------------------------------------------------------------
--Driver(Сигналы подоваемые на разъем)
---------------------------------------------------------------------------
p_out_txn              : out   std_logic_vector(C_GTCH_COUNT_MAX-1 downto 0);
p_out_txp              : out   std_logic_vector(C_GTCH_COUNT_MAX-1 downto 0);
p_in_rxn               : in    std_logic_vector(C_GTCH_COUNT_MAX-1 downto 0);
p_in_rxp               : in    std_logic_vector(C_GTCH_COUNT_MAX-1 downto 0);

---------------------------------------------------------------------------
--Tranceiver
---------------------------------------------------------------------------
p_in_txdata            : in    TBus32_GTCH;                                   --//поток данных для передатчика DUAL_GTP
p_in_txcharisk         : in    TBus04_GTCH;                                   --//признак наличия упр.символов на порту txdata
p_in_txchadipmode      : in    TBus02_GTCH;
p_in_txchadipval       : in    TBus02_GTCH;

p_in_txreset           : in    std_logic_vector(C_GTCH_COUNT_MAX-1 downto 0); --//Сброс передатчика
p_out_txbufstatus      : out   TBus02_GTCH;

---------------------------------------------------------------------------
--Receiver
---------------------------------------------------------------------------
p_in_rxreset           : in    std_logic_vector(C_GTCH_COUNT_MAX-1 downto 0); --//Сброс GT RxPCS
p_out_rxstatus         : out   TBus03_GTCH;                                   --//Тип обнаруженного OOB сигнала
p_out_rxdata           : out   TBus32_GTCH;                                   --//поток данных от приемника DUAL_GTP
p_out_rxcharisk        : out   TBus04_GTCH;                                   --//признак наличия упр.символов в rxdata
p_out_rxdisperr        : out   TBus04_GTCH;                                   --//Ошибка паритета в принятом данном
p_out_rxnotintable     : out   TBus04_GTCH;                                   --//
p_out_rxbyteisaligned  : out   std_logic_vector(C_GTCH_COUNT_MAX-1 downto 0); --//Данные выровнены по байтам

p_in_rxbufreset        : in    std_logic_vector(C_GTCH_COUNT_MAX-1 downto 0);
p_out_rxbufstatus      : out   TBus03_GTCH;

----------------------------------------------------------------------------
--System
----------------------------------------------------------------------------
--Порт динамическаго конфигурирования DUAL_GTP
p_in_drpclk            : in    std_logic;
p_in_drpaddr           : in    std_logic_vector(7 downto 0);
p_in_drpen             : in    std_logic;
p_in_drpwe             : in    std_logic;
p_in_drpdi             : in    std_logic_vector(15 downto 0);
p_out_drpdo            : out   std_logic_vector(15 downto 0);
p_out_drprdy           : out   std_logic;

p_out_plllock          : out   std_logic;--//Захват частоты PLL DUAL_GTP
p_out_refclkout        : out   std_logic;--//Фактически дублирование p_in_refclkin. см. стр.68. ug196.pdf

p_in_refclkin          : in    std_logic;--//Опорнач частоа для работы DUAL_GTP

--p_in_optrefclksel      : in    std_logic_vector(3 downto 0);
--p_in_optrefclk         : in    std_logic_vector(3 downto 0);
--p_out_optrefclk        : out   std_logic_vector(3 downto 0);

p_in_rst               : in    std_logic
);
end component;



end gmii_unit_pkg;

