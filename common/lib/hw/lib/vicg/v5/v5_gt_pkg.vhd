-------------------------------------------------------------------------
-- Company     : Linkos
-- Engineer    : Golovachenko Victor
--
-- Create Date : 02.11.2011 15:30:23
-- Module Name : v5_gt_pkg
--
-- Description :
--
-- Revision:
-- Revision 0.01 - File Created
--
-------------------------------------------------------------------------
library ieee;
use ieee.STD_LOGIC_1164.all;

library work;
use work.vicg_common_pkg.all;

package v5_gt_pkg is

constant C_V5GT_CLKIN_MUX_L_BIT   : integer:=8; --//Значение для перепрограм. мультиплексора CLKIN RocketIO ETH
constant C_V5GT_CLKIN_MUX_M_BIT   : integer:=10; --//
constant C_V5GT_SOUTH_MUX_VAL_BIT : integer:=11; --//Значение для перепрограм. мультиплексора CLKSOUTH RocketIO ETH
constant C_V5GT_NORTH_MUX_VAL_BIT : integer:=12; --//Значение для перепрограм. мультиплексора CLKNORTH RocketIO ETH
constant C_V5GT_CLKIN_MUX_CNG_BIT : integer:=13; --//1- перепрограммирование мультиплексора CLKIN RocketIO ETH
constant C_V5GT_SOUTH_MUX_CNG_BIT : integer:=14; --//1- перепрограммирование мультиплексора CLKSOUTH RocketIO ETH
constant C_V5GT_NORTH_MUX_CNG_BIT : integer:=15; --//1- перепрограммирование мультиплексора CLKNORTH RocketIO ETH


end v5_gt_pkg;


package body v5_gt_pkg is

end v5_gt_pkg;

