-------------------------------------------------------------------------
-- Company     : Linkos
-- Engineer    : Golovachenko Victor
--
-- Create Date : 05.06.2011 15:14:44
-- Module Name : sata_player_gt_clkmux
--
-- Назначение/Описание :
--   1. Связь компонента GTX(gig tx/rx) c sata_host.vhd
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

library unisim;
use unisim.vcomponents.all;

library work;
use work.vicg_common_pkg.all;
use work.sata_pkg.all;

entity sata_player_gt_clkmux is
generic
(
G_HDD_COUNT  : integer := 0;
G_SIM        : string  := "OFF"
);
port
(
p_out_optrefclksel : out   T04_SHCountMax;
p_out_optrefclk    : out   T04_SHCountMax;
p_in_optrefclk     : in    T04_SHCountMax
);
end sata_player_gt_clkmux;

architecture behavioral of sata_player_gt_clkmux is


constant C_SH_COUNT : integer:=C_SH_COUNT_MAX(G_HDD_COUNT-1);


--MAIN
begin


gen_sh : for i in 0 to C_SH_COUNT_MAX(C_HDD_COUNT_MAX-1)-1 generate

p_out_optrefclksel(i)<=CONV_STD_LOGIC_VECTOR(16#00#, p_out_optrefclksel(0)'length);
p_out_optrefclk(i)   <=(others=>'0');

end generate gen_sh;


--END MAIN
end behavioral;
