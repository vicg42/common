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
generic(
G_USRCLK_COUNT : integer:=1
);
port(
p_out_gusrclk  : out std_logic_vector(G_USRCLK_COUNT-1 downto 0);
p_out_pll_lock : out std_logic;

p_in_clk       : in  std_logic;
p_in_rst       : in  std_logic
);
end entity;

architecture behavioral of clock is

signal i_clkfb  : std_logic;
signal i_clk    : std_logic_vector(5 downto 0);

--MAIN
begin


gen_clk : for i in 0 to G_USRCLK_COUNT-1 generate
m_bufg : BUFG port map(I => i_clk(i), O => p_out_gusrclk(i) );
end generate gen_clk;

m_pll_adv : PLL_ADV
generic map(
BANDWIDTH          => "OPTIMIZED",
CLKIN1_PERIOD      => 6.6666, --150MHz
CLKIN2_PERIOD      => 6.6666,
CLKOUT0_DIVIDE     => 2, --clk0 = ((150MHz * 4)/1) /2 = 300MHz
CLKOUT1_DIVIDE     => 9, --clk1 = ((150MHz * 4)/1) /9 = 66.6MHz
CLKOUT2_DIVIDE     => 3, --clk2 = ((150MHz * 4)/1) /3 = 200MHz
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
CLKFBOUT_MULT      => 4,
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
CLKOUT0          => i_clk(0),
CLKOUT1          => i_clk(1),
CLKOUT2          => i_clk(2),
CLKOUT3          => i_clk(3),
CLKOUT4          => i_clk(4),
CLKOUT5          => i_clk(5),
DO               => open,
DRDY             => open,
LOCKED           => p_out_pll_lock
);

end architecture behavioral;

