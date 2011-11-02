-------------------------------------------------------------------------
-- Company     : Linkos
-- Engineer    : Golovachenko Victor
--
-- Create Date : 09.02.2011 15:58:24
-- Module Name : sata_crc
--
-- Назначение/Описание :
--  Модуль реализует алгоритм вычисления CRC описаный в спецификации SATA
--  см. pdf d1532v3r4b ATA-ATAPI-7.pdf стр. 253
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

entity sata_crc is
generic(
G_INIT_VAL : integer:=16#52325032#
);
port(
p_in_SOF      : in    std_logic;
--p_in_EOF      : in    std_logic;
p_in_en       : in    std_logic;
p_in_data     : in    std_logic_vector(31 downto 0);
p_out_crc     : out   std_logic_vector(31 downto 0);

--------------------------------------------------
--System
--------------------------------------------------
--p_in_clk_en   : in    std_logic;--
p_in_clk      : in    std_logic;--
p_in_rst      : in    std_logic
);
end sata_crc;

architecture behavioral of sata_crc is


signal i_crc_calc               : std_logic_vector(31 downto 0);


--MAIN
begin


p_out_crc<=i_crc_calc;

process(p_in_rst,p_in_clk)
begin
  if p_in_rst='1' then
    i_crc_calc<=(others=>'0');
  elsif p_in_clk'event and p_in_clk='1' then
--  if p_in_clk_en='1' then
    if p_in_SOF='1' then
      i_crc_calc<=CONV_STD_LOGIC_VECTOR(G_INIT_VAL, i_crc_calc'length);
    else
      if p_in_en='1' then
        i_crc_calc<=crc32_0(p_in_data, i_crc_calc);
      end if;
    end if;
--  end if;
  end if;
end process;

--process(p_in_rst,p_in_clk)
--begin
--  if p_in_clk'event and p_in_clk='1' then
--    if p_in_rst='1' or p_in_SOF='1' then
--      i_crc_calc<=CONV_STD_LOGIC_VECTOR(G_INIT_VAL, i_crc_calc'length);
--    else
----    if p_in_clk_en='1' then
--      if p_in_en='1' then
--        i_crc_calc<=crc32_0(p_in_data, i_crc_calc);
--      end if;
----    end if;
--    end if;
--  end if;
--end process;

--END MAIN
end behavioral;
