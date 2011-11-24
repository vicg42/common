-------------------------------------------------------------------------
-- Company     : Linkos
-- Engineer    : Golovachenko Victor
--
-- Create Date : 21.11.2011 12:58:54
-- Module Name : mem_glob_pkg.vhd
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
use ieee.std_logic_unsigned.all;

package mem_glob_pkg is

constant C_MEMWR_AWIDTH_MAX : integer:=128;
constant C_MEMWR_DWIDTH_MAX : integer:=128;
constant C_MEMWR_IDWIDTH_MAX: integer:=8;

constant C_MEMCH_COUNT_MAX  : integer:=8;

end;
