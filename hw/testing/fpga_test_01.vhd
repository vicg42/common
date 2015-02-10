-------------------------------------------------------------------------
-- Company     : Telemix
-- Engineer    : Golovachenko Victor
--
-- Create Date : 10/26/2007
-- Module Name : fpga_test_01
--
--------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.vicg_common_pkg.all;

entity fpga_test_01 is
generic(
G_BLINK_T05 : integer:=10#125#; -- 1/2 периода мигания светодиода.(время в ms)
G_CLK_T05us : integer:=10#1000# -- кол-во периодов частоты порта p_in_clk
                                -- укладывающиеся в 1/2 периода 1us
);
port
(
p_out_test_led : out   std_logic;--мигание сведодиода
p_out_test_done: out   std_logic;--сигнал переходи в '1' через 3 сек.

p_out_1us      : out   std_logic;
p_out_1ms      : out   std_logic;
-------------------------------
--System
-------------------------------
p_in_clk       : in    std_logic;
p_in_rst       : in    std_logic
);
end entity fpga_test_01;

architecture behavioral of fpga_test_01 is

component time_gen
generic(
G_T05us      : integer:=10#1000#
);
port(
p_out_en05us : out   std_logic;
p_out_en1us  : out   std_logic;
p_out_en1ms  : out   std_logic;
p_out_en1sec : out   std_logic;
p_out_en1min : out   std_logic;

-------------------------------
--System
-------------------------------
p_in_clk     : in    std_logic;
p_in_rst     : in    std_logic
);
end component time_gen;


signal i_discret_1us            : std_logic;
signal i_discret_1ms            : std_logic;
signal i_discret_1sec           : std_logic;
signal i_count_ms               : unsigned(7 downto 0);--(log2(G_BLINK_T05) - 1 downto 0);
signal i_count_sec              : unsigned(1 downto 0);
signal i_test_led               : std_logic;
signal i_test_done              : std_logic;


begin --architecture behavioral


p_out_test_led  <= i_test_led;
p_out_test_done <= i_test_done;
p_out_1ms       <= i_discret_1ms;
p_out_1us       <= i_discret_1us;

m_time_gen : time_gen
generic map(
G_T05us => G_CLK_T05us
)
port map(
p_out_en05us => open,
p_out_en1us  => i_discret_1us,
p_out_en1ms  => i_discret_1ms,
p_out_en1sec => i_discret_1sec,
p_out_en1min => open,

-------------------------------
--System
-------------------------------
p_in_clk     => p_in_clk,
p_in_rst     => p_in_rst
);

process(p_in_clk)
  variable a : std_logic;
begin
if rising_edge(p_in_clk) then
  if p_in_rst = '1' then
    i_count_ms <= (others => '0');
    i_count_sec <= (others => '0');
    a := '0';
    i_test_led <= '0';
    i_test_done <= '0';
  else
    --Blink
    if i_discret_1ms = '1' then
      if i_count_ms = TO_UNSIGNED(G_BLINK_T05, i_count_ms'length) then
        i_count_ms <= (others => '0');
        a := not a;
      else
        i_count_ms <= i_count_ms + 1;
      end if;
    end if;
    i_test_led <= a;

    --STOP
    if i_discret_1sec = '1' and i_test_done = '0' then
      if i_count_sec = TO_UNSIGNED(2, i_count_sec'length) then
        i_count_sec <= (others => '0');
        i_test_done <= '1';
      else
        i_count_sec <= i_count_sec + 1;
      end if;
    end if;
  end if;
end if;
end process;


end architecture behavioral;
