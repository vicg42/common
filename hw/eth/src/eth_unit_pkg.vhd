-------------------------------------------------------------------------
-- Company     : Linkos
-- Engineer    : Golovachenko Victor
--
-- Create Date : 28.11.2011 15:47:02
-- Module Name : eth_unit_pkg
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
use work.eth_pkg.all;


package eth_unit_pkg is


component eth_app
generic(
G_ETH : TEthGeneric;
G_DBG : string:="OFF";
G_SIM : string:="OFF"
);
port(
--------------------------------------
--USR
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
end component;


component eth_phy
generic (
G_ETH : TEthGeneric;
G_DBG : string:="OFF";
G_SIM : string:="OFF"
);
port(
--EthPhy<->EthApp
p_out_phy2app : out   TEthPhy2AppOUTs;
p_in_phy2app  : in    TEthPhy2AppINs;

--EthPHY
p_out_phy     : out   TEthPhyOUT;
p_in_phy      : in    TEthPhyIN;

--Технологический
p_out_dbg     : out   TEthPhyDBGs;
p_in_tst      : in    std_logic_vector(31 downto 0);
p_out_tst     : out   std_logic_vector(31 downto 0);

--System
p_in_rst      : in    std_logic
);
end component;


component eth_main
generic(
G_ETH : TEthGeneric;
G_DBG : string:="OFF";
G_SIM : string:="OFF"
);
port(
--------------------------------------
--USR
--------------------------------------
--настройка
p_in_ethcfg  : in    TEthCfgs;
--Связь с UsrBUF
p_out_eth    : out   TEthOUTs;
p_in_eth     : in    TEthINs;

--------------------------------------
--Eth Driver
--------------------------------------
p_out_phy    : out   TEthPhyOUT;
p_in_phy     : in    TEthPhyIN;

--------------------------------------
--Технологические сигналы
--------------------------------------
p_out_dbg    : out   TEthDBG;
p_in_tst     : in    std_logic_vector(31 downto 0);
p_out_tst    : out   std_logic_vector(31 downto 0);

--------------------------------------
--System
--------------------------------------
p_in_rst     : in    std_logic
);
end component;



end eth_unit_pkg;

