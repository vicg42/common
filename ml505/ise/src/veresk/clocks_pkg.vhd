-------------------------------------------------------------------------
-- Company     : Linkos
-- Engineer    : Golovachenko Victor
--
-- Create Date : 10.06.2012 8:55:10
-- Module Name : clocks_pkg
--
-- Description :
--
-- Revision:
-- Revision 0.01 - File Created
--
-------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;

package clocks_pkg is

type TRefClkPinIN is record
clk_p : std_logic;
clk_n : std_logic;
pciexp_clk_p : std_logic;
pciexp_clk_n : std_logic;
fiber_clk_p  : std_logic_vector(1 downto 0);
fiber_clk_n  : std_logic_vector(1 downto 0);
end record;

type TRefClkPinOUT is record
oe : std_logic_vector(0 downto 0);
end record;

end clocks_pkg;

