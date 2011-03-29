-------------------------------------------------------------------------
-- Company     : Linkos
-- Engineer    : Golovachenko Victor
--
-- Create Date : 25.11.2008 18:38
-- Module Name : fpga_test_01_tb
--
-- Назначение/Описание :
--    Проверка работы модуля time_gen
--
-- Revision:
-- Revision 0.01 - File Created
--
-------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.ALL;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;
use ieee.std_logic_arith.all;

library unisim;
use unisim.vcomponents.all;

entity fpga_test_01_tb is
end fpga_test_01_tb;

architecture behavior of fpga_test_01_tb is

constant С_CLK_PERIOD : TIME := 6.6 ns; --150MHz

component fpga_test_01
generic( G_T05us : integer:=10#12#);
port
(
p_out_test_led : out   std_logic;
p_out_test_done: out   std_logic;

p_out_1us      : out   std_logic;
p_out_1ms      : out   std_logic;
-------------------------------
--System
-------------------------------
p_in_clk       : in    std_logic;
p_in_rst       : in    std_logic
);
end component;

signal clk                       : std_logic := '0';
signal rst                       : std_logic := '0';

--Main
begin

m_fpga_test: fpga_test_01
generic map(G_T05us => 10#75#)
port map
(
p_out_test_led => open,
p_out_test_done=> open,

p_out_1us      => open,
p_out_1ms      => open,
-------------------------------
--System
-------------------------------
p_in_clk       => clk,
p_in_rst       => rst
);


clk_gen : process
begin
  clk<='0';
  wait for С_CLK_PERIOD/2;
  clk<='1';
  wait for С_CLK_PERIOD/2;
end process;

rst<='1','0' after 1 us;


--End Main
end;
