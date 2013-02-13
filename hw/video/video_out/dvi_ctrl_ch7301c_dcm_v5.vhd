-------------------------------------------------------------------------
-- Company     : Linkos
-- Engineer    : Golovachenko Victor
--
-- Create Date : 13.02.2013 16:50:19
-- Module Name : dvi_ctrl_dcm
--
-- Назначение/Описание :
--
-- Revision:
-- Revision 0.01 - File Created
-------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;

library unisim;
use unisim.vcomponents.all;

entity dvi_ctrl_dcm is
port(
p_out_rst     : out   std_logic;
p_out_gclk    : out   std_logic_vector(0 downto 0);

--System
p_in_clk      : in    std_logic;
p_in_rst      : in    std_logic
);
end dvi_ctrl_dcm;

architecture v5_only of dvi_ctrl_dcm is

signal i_locked              : std_logic;
signal i_clk_fb,g_clk_fb     : std_logic;
signal i_clk_out             : std_logic_vector(0 downto 0);

--MAIN
begin


-- Reference clock PLL (CLKFBOUT range 400 MHz to 1000 MHz)
-- CLKFBOUT = (CLKIN1/DIVCLK_DIVIDE) * CLKFBOUT_MULT
-- CLKOUTn  = (CLKIN1/DIVCLK_DIVIDE) * CLKFBOUT_MULT/CLKOUTn_DIVIDE
-- CLKFBOUT = (100 MHz/5) * 30.000       = 600 MHz
-- CLKOUT0  = (100 MHz/5) * 30.000/8     = 75 MHz
-- CLKOUT1  = (100 MHz/5) * 30.000/4     = 150 MHz
-- CLKOUT2  = (100 MHz/5) * 30.000/12    = 50 MHz
-- CLKOUT3  = (100 MHz/5) * 30.000/24    = 25 MHz

m_pll : PLL_BASE
generic map(
CLKIN_PERIOD   => 10.00,
DIVCLK_DIVIDE  => 5,     --integer : 1 to 52
CLKFBOUT_MULT  => 30,    --integer : 1 to 64
CLKOUT0_DIVIDE => 8,     --integer : 1 to 128
CLKOUT1_DIVIDE => 4,     --integer : 1 to 128
CLKOUT2_DIVIDE => 12,    --integer : 1 to 128
CLKOUT3_DIVIDE => 24,    --integer : 1 to 128
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
CLKOUT3  => open,--i_clk_out(3),
CLKOUT4  => open,
CLKOUT5  => open,
LOCKED   => i_locked,
CLKFBIN  => g_clk_fb,
CLKIN    => p_in_clk,
RST      => p_in_rst
);

g_clk_fb <= i_clk_fb;
p_out_rst <= not i_locked;

bufg_clk_pix: BUFG port map(I => i_clk_out(0), O => p_out_gclk(0));


--END MAIN
end v5_only;


