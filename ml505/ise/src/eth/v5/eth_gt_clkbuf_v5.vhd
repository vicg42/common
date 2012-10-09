-------------------------------------------------------------------------
-- Company     : Linkos
-- Engineer    : Golovachenko Victor
--
-- Create Date : 03.06.2012 16:49:57
-- Module Name : gt2_clkbuf
--
-- Назначение/Описание :
--
-- Revision:
-- Revision 0.01 - File Created
--
-------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

library unisim;
use unisim.vcomponents.all;

library work;
use work.eth_phypin_pkg.all;

entity eth_gt_clkbuf is
port(
p_in_ethphy : in    TEthPhyPinIN;
p_out_clk   : out   std_logic_vector(1 downto 0)
);
end entity;

architecture v5_only of eth_gt_clkbuf is

signal i_pll_clkin   : std_logic;
signal g_pll_clkin   : std_logic;
signal i_pll_rst_cnt : std_logic_vector(4 downto 0) := "11111";
signal i_pll_rst     : std_logic := '1';
signal i_clk_fb      : std_logic;
signal g_clk_fb      : std_logic;
signal i_pll_locked  : std_logic;
signal i_clk_out     : std_logic_vector(7 downto 0);

begin

m_buf : IBUFDS port map(I  => p_in_ethphy.fiber.clk_p, IB => p_in_ethphy.fiber.clk_n, O => i_pll_clkin);--200MHz
bufg_pll_clkin : BUFG port map(I  => i_pll_clkin, O  => g_pll_clkin);

process(g_pll_clkin)
begin
  if rising_edge(g_pll_clkin) then
    if i_pll_rst_cnt = "00000" then
      i_pll_rst <= '0';
    else
      i_pll_rst <= '1';
      i_pll_rst_cnt <= i_pll_rst_cnt-1;
    end if;
  end if;
end process;

-- Reference clock PLL (CLKFBOUT range 400 MHz to 1000 MHz)
-- CLKFBOUT = (CLKIN1/DIVCLK_DIVIDE) * CLKFBOUT_MULT
-- CLKOUTn  = (CLKIN1/DIVCLK_DIVIDE) * CLKFBOUT_MULT/CLKOUTn_DIVIDE
-- CLKFBOUT = (200 MHz/2) * 10.000       = 1000 MHz
-- CLKOUT0  = (200 MHz/2) * 10.000/8     = 125 MHz

m_pll : PLL_BASE
generic map(
CLKIN_PERIOD   => 5.00,
DIVCLK_DIVIDE  => 2,    --integer : 1 to 52
CLKFBOUT_MULT  => 10,   --integer : 1 to 64
CLKOUT0_DIVIDE => 8,    --integer : 1 to 128
CLKOUT1_DIVIDE => 3,    --integer : 1 to 128
CLKOUT2_DIVIDE => 9,    --integer : 1 to 128
CLKOUT3_DIVIDE => 1,    --integer : 1 to 128
CLKOUT0_PHASE  => 0.000,
CLKOUT1_PHASE  => 0.000,
CLKOUT2_PHASE  => 0.000,
CLKOUT3_PHASE  => 0.000
)
port map(
CLKFBOUT => i_clk_fb,
CLKOUT0  => i_clk_out(0),
CLKOUT1  => open,--i_clk_out(1),
CLKOUT2  => open,--i_clk_out(2),
CLKOUT3  => open,
CLKOUT4  => open,
CLKOUT5  => open,
LOCKED   => i_pll_locked,
CLKFBIN  => g_clk_fb,
CLKIN    => i_pll_clkin,
RST      => i_pll_rst
);

-- MMCM feedback (not using BUFG, because we don't care about phase compensation)
g_clk_fb <= i_clk_fb;

p_out_clk(0) <= i_clk_out(0); --125MHz
p_out_clk(1) <= not(i_pll_locked);


--m_buf0 : IBUFDS port map(I  => p_in_ethphy.fiber.clk_p,  IB => p_in_ethphy.fiber.clk_n,  O => p_out_clk(0));
--p_out_clk(1) <= '0';


end architecture;
