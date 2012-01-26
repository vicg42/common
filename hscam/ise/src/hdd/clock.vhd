-------------------------------------------------------------------------
-- Company     : Linkos
-- Engineer    : Golovachenko Victor
--
-- Create Date : 18.01.2012 18:10:33
-- Module Name : clock
--
-- Назначение/Описание :
--
--
-- Revision:
-- Revision 0.01 - File Created
--
-------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;

library unisim;
use unisim.vcomponents.all;

entity clock is
port(
p_out_gusrclk0 : out std_logic;
p_out_gusrclk1 : out std_logic;
p_out_pll_lock : out std_logic;

p_in_clk       : in  std_logic;
p_in_rst       : in  std_logic
);
end entity;

architecture behavioral of clock is

signal i_clk0   : std_logic;
signal i_clk1   : std_logic;
signal i_clkfb  : std_logic;

--MAIN
begin


m_bufg_clk0 : BUFG port map(I => i_clk0, O => p_out_gusrclk0 );
m_bufg_clk1 : BUFG port map(I => i_clk1, O => p_out_gusrclk1 );


m_pll_adv : PLL_ADV
generic map(
BANDWIDTH          => "OPTIMIZED",
CLKIN1_PERIOD      => 6.6666, --150MHz
CLKIN2_PERIOD      => 6.6666,
CLKOUT0_DIVIDE     => 2, --clk0 = (150MHz/1) * (5/2) = 375MHz
CLKOUT1_DIVIDE     => 12,--clk1 = (150MHz/1) * (5/12)= 62.5MHz
CLKOUT2_DIVIDE     => 8,
CLKOUT3_DIVIDE     => 8,
CLKOUT4_DIVIDE     => 8,
CLKOUT5_DIVIDE     => 8,
CLKOUT0_PHASE      => 0.000,
CLKOUT1_PHASE      => 0.000,
CLKOUT2_PHASE      => 0.000,
CLKOUT3_PHASE      => 0.000,
CLKOUT4_PHASE      => 0.000,
CLKOUT5_PHASE      => 0.000,
CLKOUT0_DUTY_CYCLE => 0.500,
CLKOUT1_DUTY_CYCLE => 0.500,
CLKOUT2_DUTY_CYCLE => 0.500,
CLKOUT3_DUTY_CYCLE => 0.500,
CLKOUT4_DUTY_CYCLE => 0.500,
CLKOUT5_DUTY_CYCLE => 0.500,
SIM_DEVICE         => "SPARTAN6",
COMPENSATION       => "INTERNAL",
DIVCLK_DIVIDE      => 1,
CLKFBOUT_MULT      => 5,
CLKFBOUT_PHASE     => 0.0,
REF_JITTER         => 0.005000
)
port map(
CLKFBIN          => i_clkfb,
CLKINSEL         => '1',
CLKIN1           => p_in_clk,
CLKIN2           => '0',
DADDR            => (others => '0'),
DCLK             => '0',
DEN              => '0',
DI               => (others => '0'),
DWE              => '0',
REL              => '0',
RST              => p_in_rst,
CLKFBDCM         => open,
CLKFBOUT         => i_clkfb,
CLKOUTDCM0       => open,
CLKOUTDCM1       => open,
CLKOUTDCM2       => open,
CLKOUTDCM3       => open,
CLKOUTDCM4       => open,
CLKOUTDCM5       => open,
CLKOUT0          => i_clk0,
CLKOUT1          => i_clk1,
CLKOUT2          => open,
CLKOUT3          => open,
CLKOUT4          => open,
CLKOUT5          => open,
DO               => open,
DRDY             => open,
LOCKED           => p_out_pll_lock
);

end architecture behavioral;

