-------------------------------------------------------------------------
-- Company     : Linkos
-- Engineer    : Golovachenko Victor
--
-- Create Date : 05.06.2011 15:14:44
-- Module Name : sata_player_gt_clkmux
--
-- Назначение/Описание :
--   ТОЛЬКО ДЛЯ SPARTAN-6 - Управление опрными частотами для GTPA PLL0/PLL1
--
-- Revision:
-- Revision 0.01 - File Created
--
--------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_misc.all;
use ieee.std_logic_unsigned.all;

library work;
use work.vicg_common_pkg.all;
use work.sata_glob_pkg.all;
use work.sata_pkg.all;

entity sata_player_gt_clkmux is
generic(
G_HDD_COUNT : integer:=0;
G_SIM       : string :="OFF"
);
port(
p_out_optrefclksel : out   T04_SHCountMax;--//
p_out_optrefclk    : out   T04_SHCountMax;--//
p_in_optrefclk     : in    T04_SHCountMax --//
);
end sata_player_gt_clkmux;

architecture behavioral of sata_player_gt_clkmux is


constant C_SH_COUNT : integer:=C_SH_COUNT_MAX(G_HDD_COUNT-1);


--MAIN
begin

gen_off : if (p_out_optrefclksel'length-1)>C_SH_COUNT  generate
gen : for i in C_SH_COUNT to p_out_optrefclksel'length-1 generate
p_out_optrefclksel(i)<=(others=>'0');
p_out_optrefclk(i)   <=(others=>'0');
end generate gen;
end generate gen_off;

--//----------------------------------
--//SHCOUNT=1
--//----------------------------------
gen_shcount1 : if C_SH_COUNT=1  generate
p_out_optrefclksel(0)<=CONV_STD_LOGIC_VECTOR(16#04#, p_out_optrefclksel(0)'length);
p_out_optrefclk(0)   <=(others=>'0');
end generate gen_shcount1;

--//----------------------------------
--//SHCOUNT=2
--//----------------------------------
gen_shcount2 : if C_SH_COUNT=2  generate
p_out_optrefclksel(0)<=CONV_STD_LOGIC_VECTOR(16#04#, p_out_optrefclksel(0)'length);
p_out_optrefclk(0)   <=(others=>'0');

p_out_optrefclksel(1)<=CONV_STD_LOGIC_VECTOR(16#07#, p_out_optrefclksel(0)'length);
p_out_optrefclk(1)(0)<='0';
p_out_optrefclk(1)(1)<='0';
p_out_optrefclk(1)(2)<=p_in_optrefclk(0)(1);
p_out_optrefclk(1)(3)<=p_in_optrefclk(0)(1);
end generate gen_shcount2;


--END MAIN
end behavioral;
