-------------------------------------------------------------------------
-- Company     : Linkos
-- Engineer    : Golovachenko Victor
--
-- Create Date : 02.06.2012 15:42:54
-- Module Name : prom_phypin_pkg
--
-- Description :
--
-- Revision:
-- Revision 0.01 - File Created
--
-------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;

library work;

package prom_phypin_pkg is

constant C_PROG_PHY_AWIDTH : integer := 24;
constant C_PROG_PHY_DWIDTH : integer := 16;
constant C_PROG_PHY_BUFSIZE_DEFAULT : integer := 32; --Byte

type TPromPhyOUT is record
a    : std_logic_vector(C_PROG_PHY_AWIDTH - 1 downto 0);
oe_n : std_logic;
we_n : std_logic;
cs_n : std_logic;
--rst_n : std_logic;
--adv_n : std_logic;
end record;

type TPromPhyIN is record
wt   : std_logic;
end record;

type TPromPhyINOUT is record
d : std_logic_vector(C_PROG_PHY_DWIDTH - 1 downto 0);
end record;

end prom_phypin_pkg;


