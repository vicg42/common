library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_textio.all;
use std.textio.all;

library work;
use work.vicg_common_pkg.all;

entity char_screen_tb is
generic(
G_DBG : string := "OFF"
);
port(
p_out_tp      : out  std_logic_vector(23 downto 0);
p_out_vd      : out  std_logic_vector(23 downto 0);
p_out_tst     : out  std_logic_vector(31 downto 0)
);
end char_screen_tb;

architecture behavior of char_screen_tb is

--  определяем частоты генераторов на плате:
constant period_sys_clk       : time := 56.388 ns;--17,733990147783251231527093596059 mhz

component char_screen is
generic(
G_FONT_SIZEY : integer := 10;
G_CHAR_COUNT : integer := 8
);
port(
p_in_ram_adr  : in  std_logic_vector(11 downto 0);
p_in_ram_din  : in  std_logic_vector(31 downto 0);

--SYNC
p_out_vd      : out  std_logic_vector(23 downto 0);
p_in_vd       : in   std_logic_vector(23 downto 0);
p_in_vsync    : in  std_logic; --Vertical Sync
p_in_hsync    : in  std_logic; --Horizontal Sync
p_in_den      : in  std_logic; --Pixels

p_out_tst     : out  std_logic_vector(31 downto 0);

--System
p_in_clk      : in   std_logic;
p_in_rst      : in   std_logic
);
end component char_screen;

component vga_gen is
generic(
G_SEL : integer := 0 --Resolution select
);
port(
--SYNC
p_out_vsync   : out  std_logic; --Vertical Sync
p_out_hsync   : out  std_logic; --Horizontal Sync
p_out_den     : out  std_logic; --Pixels

--System
p_in_clk      : in   std_logic;
p_in_rst      : in   std_logic
);
end component vga_gen;

signal i_rst :  std_logic;
signal i_clk :  std_logic;

signal i_vsync       : std_logic;
signal i_hsync       : std_logic;
signal i_pixen       : std_logic;

signal i_ram_adr     : unsigned(11 downto 0) := (others => '0');
signal i_ram_din     : unsigned(31 downto 0) := (others => '0');
signal i_vout_pixcnt : unsigned(11 downto 0) := (others => '0');

signal sr_pixen      : std_logic_vector(0 to 1) := (others => '0');
signal i_tst_out     : std_logic_vector(31 downto 0);
signal i_vd          : std_logic_vector(23 downto 0);

begin

i_rst <='1', '0'after 500 ns;

board_clk : process
begin
  i_clk<='0';
  wait for period_sys_clk/2;
  i_clk<='1';
  wait for period_sys_clk/2;
end process;

m_vga : vga_gen
generic map(
G_SEL => 0
)
port map(
--SYNC
p_out_vsync   => i_vsync,
p_out_hsync   => i_hsync,
p_out_den     => i_pixen,

--System
p_in_clk      => i_clk,
p_in_rst      => i_rst
);


uut : char_screen
generic map(
G_FONT_SIZEY => 8,
G_CHAR_COUNT => 8
)
port map(
p_in_ram_adr  => std_logic_vector(i_ram_adr(11 downto 0)),
p_in_ram_din  => std_logic_vector(i_ram_din(31 downto 0)),

--SYNC
p_out_vd      => i_vd,
p_in_vd       => (others => '0'),--p_in_vd,
p_in_vsync    => i_vsync,
p_in_hsync    => i_hsync,
p_in_den      => i_pixen,

p_out_tst     => i_tst_out,

--System
p_in_clk      => i_clk,
p_in_rst      => i_rst
);

p_out_vd <= i_vd;
p_out_tst <= i_tst_out;

process
begin
    i_ram_adr <= (others => '0');
    i_ram_din <= (others => '0');

wait until i_rst = '0';

wait until rising_edge(i_clk);

    i_ram_adr(11) <= '0';
    i_ram_adr(10) <= '1';
    i_ram_adr(9 downto 0) <= TO_UNSIGNED(16#00#, 10);
    i_ram_din <= TO_UNSIGNED(16#99#, 8) & TO_UNSIGNED(16#99#, 8) & TO_UNSIGNED(16#C3#, 8) & TO_UNSIGNED(16#7E#, 8);

wait until rising_edge(i_clk);
    i_ram_adr(11) <= '0';
    i_ram_adr(10) <= '1';
    i_ram_adr(9 downto 0) <= TO_UNSIGNED(16#01#, 10);
    i_ram_din <= TO_UNSIGNED(16#FF#, 8) & TO_UNSIGNED(16#E7#, 8) & TO_UNSIGNED(16#E7#, 8) & TO_UNSIGNED(16#F3#, 8);

wait until rising_edge(i_clk);
    i_ram_adr(11) <= '0';
    i_ram_adr(10) <= '1';
    i_ram_adr(9 downto 0) <= TO_UNSIGNED(16#02#, 10);
    i_ram_din <= TO_UNSIGNED(16#99#, 8) & TO_UNSIGNED(16#99#, 8) & TO_UNSIGNED(16#C3#, 8) & TO_UNSIGNED(16#7E#, 8);

wait until rising_edge(i_clk);
    i_ram_adr(11) <= '0';
    i_ram_adr(10) <= '1';
    i_ram_adr(9 downto 0) <= TO_UNSIGNED(16#03#, 10);
    i_ram_din <= TO_UNSIGNED(16#99#, 8) & TO_UNSIGNED(16#99#, 8) & TO_UNSIGNED(16#C3#, 8) & TO_UNSIGNED(16#7E#, 8);

wait until rising_edge(i_clk);
    i_ram_adr(11) <= '0';
    i_ram_adr(10) <= '1';
    i_ram_adr(9 downto 0) <= TO_UNSIGNED(16#04#, 10);
    i_ram_din <= TO_UNSIGNED(16#99#, 8) & TO_UNSIGNED(16#99#, 8) & TO_UNSIGNED(16#C3#, 8) & TO_UNSIGNED(16#7E#, 8);

wait until rising_edge(i_clk);

    i_ram_adr(11) <= '1';
    i_ram_adr(10) <= '0';
    i_ram_adr(9 downto 0) <= TO_UNSIGNED(16#00#, 10);
    i_ram_din <= TO_UNSIGNED(16#04#, 8) & TO_UNSIGNED(16#03#, 8) & TO_UNSIGNED(16#02#, 8) & TO_UNSIGNED(16#01#, 8);

wait until rising_edge(i_clk);

    i_ram_adr(11) <= '1';
    i_ram_adr(10) <= '0';
    i_ram_adr(9 downto 0) <= TO_UNSIGNED(16#01#, 10);
    i_ram_din <= TO_UNSIGNED(16#08#, 8) & TO_UNSIGNED(16#07#, 8) & TO_UNSIGNED(16#06#, 8) & TO_UNSIGNED(16#05#, 8);

wait until rising_edge(i_clk);

    i_ram_adr <= (others => '0');
    i_ram_din <= (others => '0');

wait;
end process;

process(i_clk)
begin
  if rising_edge(i_clk) then
    if i_pixen = '1' then
      i_vout_pixcnt <= i_vout_pixcnt + 1;
    else
      i_vout_pixcnt <= (others => '0');
    end if;
  end if;
end process;

p_out_tp(0) <= i_vout_pixcnt(i_vout_pixcnt'high);


process(i_clk)
variable GUI_line  : LINE;--Строка для вывода в ModelSim
variable string_value : unsigned(3 downto 0);
begin
  if rising_edge(i_clk) then
    sr_pixen <= i_pixen & sr_pixen(0 to 0);

    if sr_pixen(0) = '0' and sr_pixen(1) = '1' then
      writeline(output, GUI_line);
    else
      if i_pixen = '1' then
        if i_tst_out(8) = '1' then
          write(GUI_line, string'(" 0x"));

          for y in 1 to 2 loop
          string_value := UNSIGNED(i_tst_out((8 - (4 * (y  -1))) - 1 downto (8 - (4 * y)));
          write(GUI_line, Int2StrHEX(TO_INTEGER(string_value)));
          end loop;

          write(GUI_line, string'(" "));
        end if;
      end if;
    end if;

  end if;
end process;


end;
