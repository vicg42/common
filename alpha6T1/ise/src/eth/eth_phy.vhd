-------------------------------------------------------------------------
-- Company     : Linkos
-- Engineer    : Golovachenko Victor
--
-- Create Date : 29.11.2011 12:39:08
-- Module Name : eth_phy
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

entity eth_phy is
generic(
G_ETH : TEthGeneric
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
end eth_phy;


architecture behavioral of eth_phy is

component eth_phy_fiber
generic (
G_ETH : TEthGeneric
);
port(
--EthPhy<->EthApp
p_out_phy2app : out   TEthPhy2AppOUTs;
p_in_phy2app  : in    TEthPhy2AppINs;

--PHY
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

component eth_phy_rgmii
generic (
G_ETH : TEthGeneric
);
port(
--EthPhy<->EthApp
p_out_phy2app : out   TEthPhy2AppOUTs;
p_in_phy2app  : in    TEthPhy2AppINs;

--PHY
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


--MAIN
begin


gen_fiber : if cmpval(G_ETH.phy_select, C_ETH_PHY_FIBER) generate

m_if : eth_phy_fiber
generic map(
G_ETH => G_ETH
)
port map(
--EthPhy<->EthApp
p_out_phy2app => p_out_phy2app,
p_in_phy2app  => p_in_phy2app,

--EthPHY
p_out_phy     => p_out_phy,
p_in_phy      => p_in_phy,

--Технологический
p_out_dbg     => p_out_dbg,
p_in_tst      => p_in_tst,
p_out_tst     => p_out_tst,

--System
p_in_rst      => p_in_rst
);

end generate gen_fiber;


gen_rgmii : if cmpval(G_ETH.phy_select, C_ETH_PHY_RGMII) generate

m_if : eth_phy_rgmii
generic map(
G_ETH => G_ETH
)
port map(
--EthPhy<->EthApp
p_out_phy2app => p_out_phy2app,
p_in_phy2app  => p_in_phy2app,

--EthPHY
p_out_phy     => p_out_phy,
p_in_phy      => p_in_phy,

--Технологический
p_out_dbg     => p_out_dbg,
p_in_tst      => p_in_tst,
p_out_tst     => p_out_tst,

--System
p_in_rst      => p_in_rst
);

end generate gen_rgmii;


--END MAIN
end behavioral;
