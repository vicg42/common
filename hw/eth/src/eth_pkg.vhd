-------------------------------------------------------------------------
-- Company     : Linkos
-- Engineer    : Golovachenko Victor
--
-- Create Date : 28.11.2011 15:45:11
-- Module Name : eth_pkg
--
-- Description :
--
-- Revision:
-- Revision 0.01 - File Created
--
-------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

library work;
--use work.prj_cfg.all;
use work.eth_phypin_pkg.all;

package eth_pkg is

-------------------------------------
--EthCFG
-------------------------------------
--//Константы для выбора интерфейса EthPHY:
constant C_ETH_PHY_FIBER : integer:=0;
constant C_ETH_PHY_RGMII : integer:=1;
constant C_ETH_PHY_SGMII : integer:=2;
constant C_ETH_PHY_GMII  : integer:=3;


--//Структура параметров настройки модуля ETH (Generic)
type TEthGeneric is record
gtch_count_max : integer;--Кол-во каналов в модуле GT(RocketIO)
usrbuf_dwidth  : integer;--Шина данных пользовательских буферов RXBUF/TXBUF
phy_dwidth     : integer;--Шина данных EthPHY<->EthApp
phy_select     : integer;--Выбор интерфейса EthPHY
mac_length_swap: integer;--1/0 Поле Length/Type первый мл./ст. байт (0 - по стандарту!!! 1 - как в проекте Вереск)
end record;


--//для модуля eth_mdio.vhd
constant C_ETH_MDIO_WR  : std_logic:='1'; --//Не менять!!!!
constant C_ETH_MDIO_RD  : std_logic:='0'; --//Не менять!!!!


--//EthConfiguration
type TEthMacAdr is array (0 to 5) of std_logic_vector(7 downto 0);
type TEthMAC is record
dst     : TEthMacAdr;
src     : TEthMacAdr;
lentype : std_logic_vector(15 downto 0);
end record;

type TEthIPv4 is array (0 to 3) of std_logic_vector(7 downto 0);
type TEthIP is record
dst     : TEthIPv4;
src     : TEthIPv4;
end record;

type TEthPort is record
dst     : std_logic_vector(15 downto 0);
src     : std_logic_vector(15 downto 0);
end record;

type TEthCfg is record
usrctrl  : std_logic_vector(15 downto 0);
mac      : TEthMAC;
ip       : TEthIP;
prt      : TEthPort;
end record;
type TEthCfgs is array (0 to 1) of TEthCfg;


-------------------------------------
--EthPHY
-------------------------------------
constant C_ETHPHY_OPTIN_REFCLK_IODELAY_BIT       : integer:=6;
constant C_ETHPHY_OPTIN_SFP_SD_BIT               : integer:=7;
constant C_ETHPHY_OPTIN_V5GT_CLKIN_MUX_L_BIT     : integer:=8;
constant C_ETHPHY_OPTIN_V5GT_CLKIN_MUX_M_BIT     : integer:=10;
constant C_ETHPHY_OPTIN_V5GT_SOUTH_MUX_VAL_L_BIT : integer:=11;
constant C_ETHPHY_OPTIN_V5GT_SOUTH_MUX_VAL_M_BIT : integer:=12;
constant C_ETHPHY_OPTIN_V5GT_CLKIN_MUX_CNG_BIT   : integer:=13;
constant C_ETHPHY_OPTIN_V5GT_SOUTH_MUX_CNG_BIT   : integer:=14;
constant C_ETHPHY_OPTIN_V5GT_NORTH_MUX_CNG_BIT   : integer:=15;
constant C_ETHPHY_OPTIN_DRPCLK_BIT               : integer:=31;

constant C_ETHPHY_OPTOUT_RST_BIT                 : integer:=0;
constant C_ETHPHY_OPTOUT_SFP_TXDIS_BIT           : integer:=1;

type TEthPhyOUT is record
pin : TEthPhyPinOUT;
opt : std_logic_vector(127 downto 0);
rdy : std_logic; --//Готов к работе
link: std_logic; --//Есть соедитение с другой стороной
clk : std_logic;
rst : std_logic;
mdc : std_logic;
mdio: std_logic;
mdio_t: std_logic;
end record;

type TEthPhyIN is record
pin : TEthPhyPinIN;
opt : std_logic_vector(127 downto 0);
clk : std_logic;
mdio :std_logic;
--rst : std_logic;
end record;


-------------------------------------
--EthPHY<->EthApp
-------------------------------------
type TEthPhy2AppOUT is record
rxd         : std_logic_vector(15 downto 0);--RX_LL_DATA        : out std_logic_vector(7 downto 0);
rxsof_n     : std_logic;                    --RX_LL_SOF_N       : out std_logic;
rxeof_n     : std_logic;                    --RX_LL_EOF_N       : out std_logic;
rxsrc_rdy_n : std_logic;                    --RX_LL_SRC_RDY_N   : out std_logic;
rxrem       : std_logic_vector(0 downto 0); --RX_LL_REM         : out std_logic;
rxbuf_status: std_logic_vector(3 downto 0); --RX_LL_FIFO_STATUS : out std_logic_vector(3 downto 0);

txdst_rdy_n : std_logic;                    --TX_LL_DST_RDY_N   : out std_logic;
end record;

type TEthPhy2AppIN is record
rxdst_rdy_n : std_logic;                    --RX_LL_DST_RDY_N : in  std_logic;

txd         : std_logic_vector(15 downto 0);--TX_LL_DATA      : in  std_logic_vector(7 downto 0);
txsof_n     : std_logic;                    --TX_LL_SOF_N     : in  std_logic;
txeof_n     : std_logic;                    --TX_LL_EOF_N     : in  std_logic;
txsrc_rdy_n : std_logic;                    --TX_LL_SRC_RDY_N : in  std_logic;
txrem       : std_logic_vector(0 downto 0); --TX_LL_REM       : in  std_logic;
end record;

type TEthPhy2AppOUTs is array (0 to 1) of TEthPhy2AppOUT;
type TEthPhy2AppINs is array (0 to 1) of TEthPhy2AppIN;


-------------------------------------
--EthApp<->USR
-------------------------------------
type TEthUsrBuf is record
sof  : std_logic;
eof  : std_logic;
din  : std_logic_vector(31 downto 0);
dout : std_logic_vector(31 downto 0);
wr   : std_logic;
rd   : std_logic;
empty: std_logic;
full : std_logic;
end record;

type TEthUsrBufs is record
rxbuf : TEthUsrBuf;
txbuf : TEthUsrBuf;
end record;

type TEthOUTs is array (0 to 1) of TEthUsrBufs;
type TEthINs is array (0 to 1) of TEthUsrBufs;


-------------------------------------
--EthDBG
-------------------------------------
type TEthPhyDBG is record
d  : std_logic_vector(31 downto 0);
end record;
type TEthPhyDBGs is array (0 to 1) of TEthPhyDBG;

type TEthAppDBG is record
mac_tx  : std_logic_vector(31 downto 0);
mac_rx  : std_logic_vector(31 downto 0);
end record;
type TEthAppDBGs is array (0 to 1) of TEthAppDBG;

type TEthDBG is record
phy : TEthPhyDBGs;
app : TEthAppDBGs;
end record;

---------------------------------------
----EthCFG
---------------------------------------
----//Константы для выбора интерфейса EthPHY:
--constant C_ETH_PHY_FIBER : integer:=1;
--constant C_ETH_PHY_RGMII : integer:=2;
--constant C_ETH_PHY_SGMII : integer:=3;
--
--
----//Структура параметров настройки модуля ETH
--type TEthGeneric is record
--gtch_count_max : integer;--Кол-во каналов в модуле GT(RocketIO)
--usrbuf_dwidth  : integer;--Шина данных пользовательских буферов RXBUF/TXBUF
--phy_dwidth     : integer;--Шина данных EthPHY<->EthApp
--phy_select     : integer;--Выбор интерфейса EthPHY
--mac_length_swap: integer;--1/0 Поле Length/Type первый мл./ст. байт (0 - по стандарту!!! 1 - как в проекте Вереск)
--end record;
--
----//Настройки модуля ETH, которые передаются по generic
--constant CI_ETH_GPRM  : TEthGeneric:=(
--2, --C_PCFG_ETH_GTCH_COUNT_MAX,   --gtch_count_max
--32,--32,                          --usrbuf_dwidth
--16,--C_PCFG_ETH_PHY_DWIDTH,       --phy_dwidth
--0, --C_PCFG_ETH_PHY_SEL,          --phy_select
--0  --0                            --mac_length_swap
--);
--
--
----//EthConfiguration
--type TEthMacAdr is array (0 to 5) of std_logic_vector(7 downto 0);
--type TEthMAC is record
--dst     : TEthMacAdr;
--src     : TEthMacAdr;
--lentype : std_logic_vector(15 downto 0);
--end record;
--
--type TEthCfg is record
--usrctrl  : std_logic_vector(15 downto 0);
--mac      : TEthMAC;
--end record;
--type TEthCfgs is array (0 to CI_ETH_GPRM.gtch_count_max-1) of TEthCfg;
--
--
---------------------------------------
----EthPHY
---------------------------------------
--constant C_ETHPHY_OPTIN_REFCLK_IODELAY_BIT       : integer:=6;
--constant C_ETHPHY_OPTIN_SFP_SD_BIT               : integer:=7;
--constant C_ETHPHY_OPTIN_V5GT_CLKIN_MUX_L_BIT     : integer:=8;
--constant C_ETHPHY_OPTIN_V5GT_CLKIN_MUX_M_BIT     : integer:=10;
--constant C_ETHPHY_OPTIN_V5GT_SOUTH_MUX_VAL_L_BIT : integer:=11;
--constant C_ETHPHY_OPTIN_V5GT_SOUTH_MUX_VAL_M_BIT : integer:=12;
--constant C_ETHPHY_OPTIN_V5GT_CLKIN_MUX_CNG_BIT   : integer:=13;
--constant C_ETHPHY_OPTIN_V5GT_SOUTH_MUX_CNG_BIT   : integer:=14;
--constant C_ETHPHY_OPTIN_V5GT_NORTH_MUX_CNG_BIT   : integer:=15;
--constant C_ETHPHY_OPTIN_DRPCLK_BIT               : integer:=31;
--
--constant C_ETHPHY_OPTOUT_RST_BIT                : integer:=0;
--
--type TEthPhyOUT is record
--pin : TEthPhyPinOUT;
--opt : std_logic_vector(31 downto 0);
--rdy : std_logic; --//Готов к работе
--link: std_logic; --//Есть соедитение с другой стороной
--clk : std_logic;
--rst : std_logic;
--end record;
--
--type TEthPhyIN is record
--pin : TEthPhyPinIN;
--opt : std_logic_vector(31 downto 0);
--clk : std_logic;
----rst : std_logic;
--end record;
--
--
---------------------------------------
----EthPHY<->EthApp
---------------------------------------
--type TEthPhy2AppOUT is record
--rxd         : std_logic_vector(CI_ETH_GPRM.phy_dwidth-1 downto 0);--RX_LL_DATA        : out std_logic_vector(7 downto 0);
--rxsof_n     : std_logic;                                         --RX_LL_SOF_N       : out std_logic;
--rxeof_n     : std_logic;                                         --RX_LL_EOF_N       : out std_logic;
--rxsrc_rdy_n : std_logic;                                         --RX_LL_SRC_RDY_N   : out std_logic;
--rxrem       : std_logic_vector(0 downto 0);                      --RX_LL_REM         : out std_logic;
--rxbuf_status: std_logic_vector(3 downto 0);                      --RX_LL_FIFO_STATUS : out std_logic_vector(3 downto 0);
--
--txdst_rdy_n : std_logic;                                         --TX_LL_DST_RDY_N   : out std_logic;
--end record;
--
--type TEthPhy2AppIN is record
--rxdst_rdy_n : std_logic;                                         --RX_LL_DST_RDY_N : in  std_logic;
--
--txd         : std_logic_vector(CI_ETH_GPRM.phy_dwidth-1 downto 0);--TX_LL_DATA      : in  std_logic_vector(7 downto 0);
--txsof_n     : std_logic;                                         --TX_LL_SOF_N     : in  std_logic;
--txeof_n     : std_logic;                                         --TX_LL_EOF_N     : in  std_logic;
--txsrc_rdy_n : std_logic;                                         --TX_LL_SRC_RDY_N : in  std_logic;
--txrem       : std_logic_vector(0 downto 0);                      --TX_LL_REM       : in  std_logic;
--end record;
--
--type TEthPhy2AppOUTs is array (0 to CI_ETH_GPRM.gtch_count_max-1) of TEthPhy2AppOUT;
--type TEthPhy2AppINs is array (0 to CI_ETH_GPRM.gtch_count_max-1) of TEthPhy2AppIN;
--
--
---------------------------------------
----EthApp<->USR
---------------------------------------
--type TEthUsrBuf is record
--sof  : std_logic;
--eof  : std_logic;
--din  : std_logic_vector(CI_ETH_GPRM.usrbuf_dwidth-1 downto 0);
--dout : std_logic_vector(CI_ETH_GPRM.usrbuf_dwidth-1 downto 0);
--wr   : std_logic;
--rd   : std_logic;
--empty: std_logic;
--full : std_logic;
--end record;
--
--type TEthUsrBufs is record
--rxbuf : TEthUsrBuf;
--txbuf : TEthUsrBuf;
--end record;
--
--type TEthOUTs is array (0 to CI_ETH_GPRM.gtch_count_max-1) of TEthUsrBufs;
--type TEthINs is array (0 to CI_ETH_GPRM.gtch_count_max-1) of TEthUsrBufs;
--
--
---------------------------------------
----EthDBG
---------------------------------------
--type TEthPhyDBG is record
--d  : std_logic_vector(31 downto 0);
--end record;
--type TEthPhyDBGs is array (0 to CI_ETH_GPRM.gtch_count_max-1) of TEthPhyDBG;
--
--type TEthAppDBG is record
--mac_tx  : std_logic_vector(31 downto 0);
--mac_rx  : std_logic_vector(31 downto 0);
--end record;
--type TEthAppDBGs is array (0 to CI_ETH_GPRM.gtch_count_max-1) of TEthAppDBG;
--
--type TEthDBG is record
--phy : TEthPhyDBGs;
--app : TEthAppDBGs;
--end record;


end eth_pkg;


