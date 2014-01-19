-------------------------------------------------------------------------
-- Company     : Linkos
-- Engineer    : Golovachenko Victor
--
-- Create Date : 02.06.2012 10:03:54
-- Module Name : gt_clkbuf
--
-- Назначение/Описание :
--
-- Revision:
-- Revision 0.01 - File Created
--
-------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;

library unisim;
use unisim.vcomponents.all;

entity gt_clkbuf is
--generic(
--G_SIM     : string:="OFF"
--);
port(
p_in_clkp  : in    std_logic;
p_in_clkn  : in    std_logic;
p_out_clk  : out   std_logic;
p_in_opt   : in    std_logic_vector(3 downto 0);
p_out_opt  : out   std_logic_vector(3 downto 0)
);
end entity;

architecture v6_only of gt_clkbuf is

begin

m_buf : IBUFDS_GTXE1 port map (
I     => p_in_clkp,
IB    => p_in_clkn,
CEB   => '0',
O     => p_out_clk,
ODIV2 => open
);

end architecture;
