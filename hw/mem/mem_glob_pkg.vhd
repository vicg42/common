-------------------------------------------------------------------------
-- Engineer    : Golovachenko Victor
--
-- Create Date : 21.11.2011 12:58:54
-- Module Name : mem_glob_pkg.vhd
--
-- Description :
--
-------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;

package mem_glob_pkg is

constant C_MEMWR_AWIDTH_MAX : integer:=64;
constant C_MEMWR_DWIDTH_MAX : integer:=256;
constant C_MEMWR_IDWIDTH_MAX: integer:=32;

constant C_MEMCH_COUNT_MAX  : integer:=8;

end package mem_glob_pkg;
