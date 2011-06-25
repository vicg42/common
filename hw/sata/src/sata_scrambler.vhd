-------------------------------------------------------------------------
-- Company     : Linkos
-- Engineer    : Golovachenko Victor
--
-- Create Date : 09.02.2011 15:58:19
-- Module Name : sata_scrambler
--
-- Назначение/Описание :
--  Модуль реализует алгоритм скемблиравния описаный в спецификации SATA
--  см. pdf d1532v3r4b ATA-ATAPI-7.pdf стр. 258
--
-- Revision:
-- Revision 0.01 - File Created
--
-------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

library unisim;
use unisim.vcomponents.all;

library work;
use work.vicg_common_pkg.all;

entity sata_scrambler is
generic
(
G_INIT_VAL : integer:=16#FFFF#
);
port
(
p_in_SOF      : in    std_logic;
p_in_en       : in    std_logic;
p_out_result  : out   std_logic_vector(31 downto 0);

--------------------------------------------------
--System
--------------------------------------------------
--p_in_clk_en   : in    std_logic;
p_in_clk      : in    std_logic;
p_in_rst      : in    std_logic
);
end sata_scrambler;

architecture behavioral of sata_scrambler is

signal i_srambler_out          : std_logic_vector(31 downto 0);

--MAIN
begin


p_out_result<=i_srambler_out;

process(p_in_rst,p_in_clk)
begin
  if p_in_rst='1' then
    i_srambler_out<=(others=>'0');
  elsif p_in_clk'event and p_in_clk='1' then
--  if p_in_clk_en='1' then
    if p_in_SOF='1' then
      i_srambler_out<=srambler32_0(CONV_STD_LOGIC_VECTOR(G_INIT_VAL, 16));
    else
      if p_in_en='1' then
        i_srambler_out<=srambler32_0(i_srambler_out(31 downto 16));
      end if;
    end if;
--  end if;
  end if;
end process;

--process(p_in_rst,p_in_clk)
--begin
--  if p_in_clk'event and p_in_clk='1' then
--    if p_in_rst='1' or p_in_SOF='1' then
--      i_srambler_out<=srambler32_0(CONV_STD_LOGIC_VECTOR(G_INIT_VAL, 16));
--    else
----    if p_in_clk_en='1' then
--      if p_in_en='1' then
--        i_srambler_out<=srambler32_0(i_srambler_out(31 downto 16));
--      end if;
----    end if;
--    end if;
--  end if;
--end process;

--END MAIN
end behavioral;
