-------------------------------------------------------------------------
-- Company     : Linkos
-- Engineer    : Golovachenko Victor
--
-- Create Date : 03.12.2011 16:45:15
-- Module Name : eth_mdio_tb
--
-- Description :
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

use ieee.std_logic_textio.all;
use std.textio.all;

library work;
use work.vicg_common_pkg.all;
use work.eth_pkg.all;

entity eth_mdio_tb is
port(
p_out_mdc            : out    std_logic
);
end eth_mdio_tb;

architecture behavior of eth_mdio_tb is

component eth_mdio
generic(
G_DIV : integer:=2;
G_DBG : string:="OFF";
G_SIM : string:="OFF"
);
port(
--------------------------------------
--Управление
--------------------------------------
p_in_cfg_start : in    std_logic;
p_in_cfg_wr    : in    std_logic;
p_in_cfg_aphy  : in    std_logic_vector(4 downto 0);
p_in_cfg_areg  : in    std_logic_vector(4 downto 0);
p_in_cfg_txd   : in    std_logic_vector(15 downto 0);
p_out_cfg_rxd  : out   std_logic_vector(15 downto 0);
p_out_cfg_done : out   std_logic;

--------------------------------------
--Связь с PHY
--------------------------------------
p_inout_mdio   : inout  std_logic;
p_out_mdc      : out    std_logic;
--p_out_mdio_t   : out    std_logic;
--p_out_mdio     : out    std_logic;
--p_in_mdio      : in     std_logic;
--p_out_mdc      : out    std_logic;

--------------------------------------------------
--Технологические сигналы
--------------------------------------------------
p_in_tst       : in    std_logic_vector(31 downto 0);
p_out_tst      : out   std_logic_vector(31 downto 0);

--------------------------------------
--SYSTEM
--------------------------------------
p_in_clk       : in    std_logic;
p_in_rst       : in    std_logic
);
end component;

constant CI_CLK_PERIOD  : TIME := 8 ns; --125MHz

signal i_clk            : std_logic;
signal i_rst            : std_logic;

signal i_cfg_start      : std_logic;
signal i_cfg_wr         : std_logic;
signal i_cfg_aphy       : std_logic_vector(4 downto 0);
signal i_cfg_areg       : std_logic_vector(4 downto 0);
signal i_cfg_txd        : std_logic_vector(15 downto 0);
signal i_cfg_rxd        : std_logic_vector(15 downto 0);
signal i_cfg_done       : std_logic;

signal i_mdio           : std_logic;
signal i_tst_out        : std_logic_vector(31 downto 0);


--MAIN
begin



m_mdio : eth_mdio
generic map (
G_DIV => 4,
G_DBG => "ON",
G_SIM => "OFF"
)
port map(
--------------------------------------
--Управление
--------------------------------------
p_in_cfg_start => i_cfg_start,
p_in_cfg_wr    => i_cfg_wr,
p_in_cfg_aphy  => i_cfg_aphy,
p_in_cfg_areg  => i_cfg_areg,
p_in_cfg_txd   => i_cfg_txd,
p_out_cfg_rxd  => i_cfg_rxd,
p_out_cfg_done => i_cfg_done,

--------------------------------------
--Связь с PHY
--------------------------------------
p_inout_mdio   => i_mdio,
p_out_mdc      => p_out_mdc,
--p_out_mdio_t   : out    std_logic;
--p_out_mdio     : out    std_logic;
--p_in_mdio      : in     std_logic;
--p_out_mdc      : out    std_logic;

--------------------------------------------------
--Технологические сигналы
--------------------------------------------------
p_in_tst       => (others=>'0'),
p_out_tst      => i_tst_out,

--------------------------------------
--SYSTEM
--------------------------------------
p_in_clk       => i_clk,
p_in_rst       => i_rst
);



gen_clk : process
begin
  i_clk<='0';
  wait for CI_CLK_PERIOD/2;
  i_clk<='1';
  wait for CI_CLK_PERIOD/2;
end process;


i_rst<='1','0' after 1 us;

i_mdio<='1' when i_tst_out(0)='1' else 'Z';

--//########################################
--//Main Ctrl
--//########################################
process
begin
  i_cfg_start<='0';
  i_cfg_wr<='0';
  i_cfg_aphy<=(others=>'0');
  i_cfg_areg<=(others=>'0');
  i_cfg_txd <=(others=>'0');

  wait until i_rst='0';

  wait for 1 us;

  wait until i_clk'event and i_clk='1';
  i_cfg_start<='1';
  i_cfg_aphy<=CONV_STD_LOGIC_VECTOR(16#06#, i_cfg_aphy'length);
  i_cfg_areg<=CONV_STD_LOGIC_VECTOR(16#0A#, i_cfg_areg'length);
  i_cfg_txd <=CONV_STD_LOGIC_VECTOR(16#7FFA#, i_cfg_txd'length);
  i_cfg_wr<=C_ETH_MDIO_WR;
  wait until i_clk'event and i_clk='1';
  i_cfg_start<='0';

  wait until i_clk'event and i_clk='1' and i_cfg_done='1';
  wait for 10 ns;

  wait until i_clk'event and i_clk='1';
  i_cfg_start<='1';
  i_cfg_aphy<=CONV_STD_LOGIC_VECTOR(16#06#, i_cfg_aphy'length);
  i_cfg_areg<=CONV_STD_LOGIC_VECTOR(16#0A#, i_cfg_areg'length);
  i_cfg_txd <=CONV_STD_LOGIC_VECTOR(16#7FFA#, i_cfg_txd'length);
  i_cfg_wr<=C_ETH_MDIO_RD;
  wait until i_clk'event and i_clk='1';
  i_cfg_start<='0';

  wait for 10 ns;

  wait;
end process;



--END MAIN
end;



