-------------------------------------------------------------------------
-- Company     : Yansar
-- Engineer    : Golovachenko Victor
--
-- Create Date : 17.07.2014 14:58:40
-- Module Name : debounce
--
-- Назначение/Описание :
--
-- Revision:
-- Revision 0.01 - File Created
--
--------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.vicg_common_pkg.all;

entity debounce is
generic(
G_PUSH_LEVEL : std_logic := '0'; --Лог. уровень когда кнопка нажата
G_DEBVAL : integer := 4
);
port(
p_in_btn  : in    std_logic;
p_out_btn : out   std_logic;

p_in_clk_en : in    std_logic;
p_in_clk    : in    std_logic
);
end entity debounce;

architecture behavioral of debounce is

signal i_debcnt           : unsigned(log2(G_DEBVAL) downto 0) := (others => '0');
signal i_btn              : std_logic := not G_PUSH_LEVEL;
signal i_btn_push         : std_logic := '0';

begin --architecture behavioral

p_out_btn <= i_btn_push;

process(p_in_clk)
begin
  if rising_edge(p_in_clk) then

    if p_in_clk_en = '1' then

      i_btn <= p_in_btn;

      if i_btn /= G_PUSH_LEVEL then
        i_debcnt <= (others => '0');
        i_btn_push <= '0';
      else
        if i_debcnt = TO_UNSIGNED(G_DEBVAL ,i_debcnt'length) then
          i_btn_push <= '1';
        else
          i_debcnt <= i_debcnt + 1;
        end if;
      end if;

    end if;

  end if;
end process;


end architecture behavioral;
