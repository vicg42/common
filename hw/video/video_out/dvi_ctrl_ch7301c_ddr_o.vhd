-------------------------------------------------------------------------
-- Company     : Linkos
-- Engineer    : Golovachenko Victor
--
-- Create Date : 24.09.2012 16:10:45
-- Module Name : dvi_ctrl_ddr_o
--
-- Назначение/Описание :
--
-- Revision:
-- Revision 0.01 - File Created
-------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;

library unisim;
use unisim.vcomponents.all;

entity dvi_ctrl_ddr_o is
port(
Q  : out   std_logic;
D1 : in    std_logic;
D2 : in    std_logic;
CE : in    std_logic;
C  : in    std_logic;
R  : in    std_logic;
S  : in    std_logic
);
end entity dvi_ctrl_ddr_o;

architecture behavioral of dvi_ctrl_ddr_o is

begin --architecture behavioral

m_ddr : ODDR
port map(
Q  => Q ,
D1 => D1,
D2 => D2,
CE => CE,
C  => C ,
R  => R ,
S  => S
);

end architecture behavioral;


