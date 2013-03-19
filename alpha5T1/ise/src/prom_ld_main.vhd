-------------------------------------------------------------------------
-- Company     : Linkos
-- Engineer    : Golovachenko Victor
--
-- Create Date : 25.11.2012 14:08:21
-- Module Name : prom_ld
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

library work;
use work.vicg_common_pkg.all;
use work.prom_phypin_pkg.all;

entity prom_ld is
generic(
G_HOST_DWIDTH : integer:=32
);
port(
-------------------------------
--Связь с HOST
-------------------------------
p_out_host_rxd   : out   std_logic_vector(G_HOST_DWIDTH - 1 downto 0);
p_in_host_rd     : in    std_logic;
p_out_rxbuf_full : out   std_logic;
p_out_rxbuf_empty: out   std_logic;

p_in_host_txd    : in    std_logic_vector(G_HOST_DWIDTH - 1 downto 0);
p_in_host_wr     : in    std_logic;
p_out_txbuf_full : out   std_logic;
p_out_txbuf_empty: out   std_logic;

p_in_host_clk    : in    std_logic;

p_out_hirq       : out   std_logic;
p_out_herr       : out   std_logic;

-------------------------------
--PHY
-------------------------------
p_in_phy         : in    TPromPhyIN;
p_out_phy        : out   TPromPhyOUT;
p_inout_phy      : inout TPromPhyINOUT;

-------------------------------
--Технологический
-------------------------------
p_in_tst         : in    std_logic_vector(31 downto 0);
p_out_tst        : out   std_logic_vector(31 downto 0);

-------------------------------
--System
-------------------------------
p_in_clk         : in    std_logic;
p_in_rst         : in    std_logic
);
end prom_ld;

architecture behavioral of prom_ld is


--MAIN
begin

--//----------------------------------
--//Технологические сигналы
--//----------------------------------
p_out_tst <= (others=>'0');


--//----------------------------------
--//
--//----------------------------------
p_out_hirq <= '0';
p_out_herr <= '0';
p_out_host_rxd <= (others=>'0');

p_out_rxbuf_full  <= '0';
p_out_rxbuf_empty <= '1';

p_out_txbuf_full  <= '0';
p_out_txbuf_empty <= '1';

p_inout_phy.d <= (others=>'0');
p_out_phy.a <= (others=>'0');


--END MAIN
end behavioral;

