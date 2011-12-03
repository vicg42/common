-------------------------------------------------------------------------
-- Company     : Linkos
-- Engineer    : Golovachenko Victor
--
-- Create Date : 28.11.2011 15:45:21
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
use ieee.std_logic_unsigned.all;

library work;
use work.vicg_common_pkg.all;
use work.eth_pkg.all;
use work.eth_unit_pkg.all;

entity eth_main is
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
end eth_main;


architecture behavioral of eth_main is

signal i_phy_out           : TEthPhyOUT;
signal i_phy_in            : TEthPhyIN;
signal i_phy2app_out       : TEthPhy2AppOUTs;
signal i_phy2app_in        : TEthPhy2AppINs;

signal i_app_tst_out       : std_logic_vector(31 downto 0);
signal i_phy_tst_out       : std_logic_vector(31 downto 0);


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




--#############################################
--Eth App
--#############################################
m_app : eth_app
generic map(
G_ETH => G_ETH,
G_DBG => G_DBG,
G_SIM => G_SIM
)
port map(
--------------------------------------
--USR
--------------------------------------
--настройка
p_in_ethcfg  => p_in_ethcfg,
--Связь с UsrBUF
p_out_eth    => p_out_eth,
p_in_eth     => p_in_eth,

--------------------------------------
--EthPhy<->EthApp
--------------------------------------
p_in_phy2app => i_phy2app_out,
p_out_phy2app=> i_phy2app_in,

--------------------------------------
--EthPHY
--------------------------------------
p_in_phy     => i_phy_out,

--------------------------------------
--Технологические сигналы
--------------------------------------
p_out_dbg    => p_out_dbg.app,
p_in_tst     => p_in_tst,
p_out_tst    => i_app_tst_out,

--------------------------------------
--System
--------------------------------------
p_in_rst      => p_in_rst
);



--#############################################
--Eth PHY
--#############################################
m_phy : eth_phy
generic map(
G_ETH => G_ETH
)
port map(
--------------------------------------
--EthPhy<->EthApp
--------------------------------------
p_out_phy2app => i_phy2app_out,
p_in_phy2app  => i_phy2app_in,

--------------------------------------
--EthPHY
--------------------------------------
p_out_phy     => i_phy_out,
p_in_phy      => i_phy_in,

--------------------------------------
--Технологические сигналы
--------------------------------------
p_out_dbg     => p_out_dbg.phy,
p_in_tst      => p_in_tst,
p_out_tst     => i_phy_tst_out,

--------------------------------------
--System
--------------------------------------
p_in_rst      => p_in_rst
);

p_out_phy<=i_phy_out;
i_phy_in <=p_in_phy;


--END MAIN
end behavioral;
