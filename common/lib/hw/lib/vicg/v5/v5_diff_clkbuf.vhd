-------------------------------------------------------------------------
-- Company     : Linkos
-- Engineer    : Golovachenko Victor
--
-- Create Date : 02.06.2012 10:03:54
-- Module Name : diff_clkbuf
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

entity diff_clkbuf is
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

architecture v5_only of diff_clkbuf is

begin

m_buf : IBUFDS port map(I  => p_in_clkp, IB => p_in_clkn, O => p_out_clk);

end architecture;
