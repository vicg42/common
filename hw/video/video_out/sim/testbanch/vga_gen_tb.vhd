
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity vga_gen_tb is
generic(
G_DBG : string := "OFF"
);
port(
p_out_vden    : out  std_logic;
p_out_vs      : out  std_logic;
p_out_hs      : out  std_logic
);
end vga_gen_tb;

architecture behavior of vga_gen_tb is

--  определяем частоты генераторов на плате:
constant period_sys_clk       : time := 56.388 ns;--17,733990147783251231527093596059 mhz

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

signal i_video_den       : std_logic;
signal i_video_vs        : std_logic;
signal i_video_hs        : std_logic;

begin

i_rst <='1', '0'after 500 ns;

board_clk : process
begin
  i_clk<='0';
  wait for period_sys_clk/2;
  i_clk<='1';
  wait for period_sys_clk/2;
end process;


uut : vga_gen
generic map(
G_SEL => 0
)
port map(
--SYNC
p_out_vsync   => i_video_vs,
p_out_hsync   => i_video_hs,
p_out_den     => i_video_den,

--System
p_in_clk      => i_clk,
p_in_rst      => i_rst
);


p_out_vden <= i_video_den;
p_out_vs   <= i_video_vs;
p_out_hs   <= i_video_hs;


end;
