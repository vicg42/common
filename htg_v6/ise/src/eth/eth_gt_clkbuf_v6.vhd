-------------------------------------------------------------------------
-- Company     : Linkos
-- Engineer    : Golovachenko Victor
--
-- Create Date : 03.06.2012 16:49:57
-- Module Name : gt2_clkbuf
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

library work;
use work.eth_phypin_pkg.all;

entity eth_gt_clkbuf is
port(
p_in_ethphy : in    TEthPhyPinIN;
p_out_clk   : out   std_logic_vector(1 downto 0)
);
end entity;

architecture v6_only of eth_gt_clkbuf is

begin

m_buf0 : IBUFDS_GTXE1 port map (
I     => p_in_ethphy.fiber.clk_p,
IB    => p_in_ethphy.fiber.clk_n,
CEB   => '0',
O     => p_out_clk(0),
ODIV2 => open
);

p_out_clk(1)<='0';

end architecture;
