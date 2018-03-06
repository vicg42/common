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
busy        : out std_logic;
txd         : out std_logic;
--rxdata       : out std_logic_vector(7 downto 0);
--rxdata_rdy : out std_logic;
framing_err : out std_logic
);
end entity uartrx_tb;

architecture behavioral of uartrx_tb is

constant CI_CLK_PERIOD : TIME := 6.6 ns; --150MHz

component uart8_rx
port (
clk         : in std_logic;
rxd         : in std_logic;
baud_rate16 : in std_logic_vector(23 downto 0);  -- baud_rate16 = Fbaud*(2^24)*16/Fclk = Fbaud*(2^28)/Fclk
rxdata      : out std_logic_vector(7 downto 0);
rxdata_rdy  : out std_logic;
framing_err : out std_logic
);
end component uart8_rx;

component uart8_tx
port (
clk         : in std_logic;
baud_rate16 : in std_logic_vector(23 downto 0);
txdata      : in std_logic_vector(7 downto 0);
txstart     : in std_logic;
busy        : out std_logic;
txd         : out std_logic
);
end component uart8_tx;

signal i_clk         : std_logic;
signal i_rxd         : std_logic;
signal i_baud_rate16 : unsigned(23 downto 0) := TO_UNSIGNED(206158 , 24); --(115200 * (2^24)) / (150000000) = 206158
signal rxdata        : std_logic_vector(7 downto 0);
signal rxdata_rdy    : std_logic;


begin --architecture behavioral


m_rx : uart8_rx
port map(
clk           => i_clk,
rxd           => i_rxd,
baud_rate16   => std_logic_vector(i_baud_rate16),
rxdata        => rxdata    ,
rxdata_rdy    => rxdata_rdy,
framing_err   => framing_err
);

m_tx : uart8_tx
port map(
clk         => i_clk,
baud_rate16 => std_logic_vector(i_baud_rate16),
txdata      => std_logic_vector(TO_UNSIGNED(16#85#, 8)),--rxdata      ,
txstart     => rxdata_rdy,
busy        => busy,
txd         => txd
);


gen_clk0 : process
begin
i_clk <= '0';
wait for (CI_CLK_PERIOD / 2);
i_clk <= '1';
wait for (CI_CLK_PERIOD / 2);
end process;


--i_rxd <= '1', '0' after 1 us, '1' after 2 us;
i_rxd <= '1', '0' after 1 us, '1' after 16 us;


end architecture behavioral;
