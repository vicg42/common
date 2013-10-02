-------------------------------------------------------------------------
-- Company     : Linkos
-- Engineer    : Golovachenko Victor
--
-- Create Date : 25.11.2008 18:38
-- Module Name : time_gen_tb
--
-- Назначение/Описание :
--    Проверка работы модуля time_gen
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

entity time_gen_tb is
end time_gen_tb;

architecture behavior of time_gen_tb is

constant C_CLK_PERIOD : TIME := 6.6 ns; --150MHz

component time_gen
generic
(
G_T05us  : integer:=10#1000#
);
port
(
p_out_en05us : out   std_logic;
p_out_en1us  : out   std_logic;
p_out_en1ms  : out   std_logic;
p_out_en1sec : out   std_logic;
p_out_en1min : out   std_logic;

-------------------------------
--System
-------------------------------
p_in_rst     : in    std_logic;
p_in_clk     : in    std_logic
);
end component;

signal clk                       : std_logic := '0';
signal rst                       : std_logic := '0';

--Main
begin

time_gen_i : time_gen
generic map
(
G_T05us  => 24
)
port map
(
p_out_en05us => open,
p_out_en1us  => open,
p_out_en1ms  => open,
p_out_en1sec => open,
p_out_en1min => open,

-------------------------------
--System
-------------------------------
p_in_rst     => rst,
p_in_clk     => clk
);


clk_gen : process
begin
  clk<='0';
  wait for C_CLK_PERIOD/2;
  clk<='1';
  wait for C_CLK_PERIOD/2;
end process;

rst<='1','0' after 1 us;


--End Main
end;
