-------------------------------------------------------------------------
-- Company     : Telemix
-- Engineer    : Golovachenko Victor
--
-- Create Date : 03.05.2011 16:39:31
-- Module Name : dsn_eth_pkg
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

package dsn_eth_pkg is

component dsn_eth
generic(
G_MODULE_USE : string:="ON";
G_ETH        : TEthGeneric;
G_DBG        : string:="OFF";
G_SIM        : string:="OFF"
);
port(
-------------------------------
--Конфигурирование
-------------------------------
p_in_cfg_clk      : in   std_logic;

p_in_cfg_adr      : in   std_logic_vector(7 downto 0);
p_in_cfg_adr_ld   : in   std_logic;
p_in_cfg_adr_fifo : in   std_logic;

p_in_cfg_txdata   : in   std_logic_vector(15 downto 0);
p_in_cfg_wd       : in   std_logic;

p_out_cfg_rxdata  : out  std_logic_vector(15 downto 0);
p_in_cfg_rd       : in   std_logic;

p_in_cfg_done     : in   std_logic;
p_in_cfg_rst      : in   std_logic;

-------------------------------
--Связь с UsrBuf
-------------------------------
p_out_eth         : out   TEthOUTs;
p_in_eth          : in    TEthINs;

-------------------------------
--ETH
-------------------------------
p_out_ethphy      : out   TEthPhyOUT;
p_in_ethphy       : in    TEthPhyIN;

-------------------------------
--Технологический
-------------------------------
p_out_dbg         : out   TEthDBG;
p_in_tst          : in    std_logic_vector(31 downto 0);
p_out_tst         : out   std_logic_vector(31 downto 0);

-------------------------------
--System
-------------------------------
p_in_rst          : in    std_logic
);
end component;


end dsn_eth_pkg;

