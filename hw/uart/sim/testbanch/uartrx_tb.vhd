-------------------------------------------------------------------------
-- Engineer    : Golovachenko Victor
--
-- Create Date : 13.07.2016 17:43:35
-- Module Name :
--
-- Description :
--
-------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity uartrx_tb is
port(
rx_data       : out std_logic_vector(7 downto 0);
rx_data_ready : out std_logic;
framing_error : out std_logic
);
end entity uartrx_tb;

architecture behavioral of uartrx_tb is

constant CI_CLK_PERIOD : TIME := 6.6 ns; --150MHz

component uart8_rx
port (
clk           : in std_logic;
rxd           : in std_logic;
baud_rate16   : in std_logic_vector(23 downto 0);  -- baud_rate16 = Fbaud*(2^24)*16/Fclk = Fbaud*(2^28)/Fclk
rx_data       : out std_logic_vector(7 downto 0);
rx_data_ready : out std_logic;
framing_error : out std_logic
);
end component uart8_rx;

signal i_clk         : std_logic;
signal i_rxd         : std_logic;
signal i_baud_rate16 : unsigned(23 downto 0) := TO_UNSIGNED(206158 , 24); --(115200 * (2^24)) / (150000000) = 206158


begin --architecture behavioral


m_rx : uart8_rx
port map(
clk           => i_clk,
rxd           => i_rxd,
baud_rate16   => std_logic_vector(i_baud_rate16),
rx_data       => rx_data      ,
rx_data_ready => rx_data_ready,
framing_error => framing_error
);


gen_clk0 : process
begin
i_clk <= '0';
wait for (CI_CLK_PERIOD / 2);
i_clk <= '1';
wait for (CI_CLK_PERIOD / 2);
end process;


i_rxd <= '1', '0' after 1 us, '1' after 16 us;


end architecture behavioral;
