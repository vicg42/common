-------------------------------------------------------------------------
-- Company     : Linkos
-- Engineer    : Golovachenko Victor
--
-- Create Date : 05.06.2011 15:14:19
-- Module Name : sata_dcm
--
-- Description :
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

library work;
use work.vicg_common_pkg.all;
use work.sata_pkg.all;

entity sata_dcm is
generic (
G_GT_DBUS : integer:=16
);
port(
p_out_dcm_gclk0  : out   std_logic;
p_out_dcm_gclk2x : out   std_logic;
p_out_dcm_gclkdv : out   std_logic;

p_out_dcmlock    : out   std_logic;

p_out_refclkout  : out   std_logic;
p_in_clk         : in    std_logic;
p_in_rst         : in    std_logic
);
end sata_dcm;

architecture behavioral of sata_dcm is

constant CI_CLKDV_DIVIDE   : integer:=selval(16, 8, (cmpval(G_GT_DBUS, 32) and cmpval(C_FSATA_GEN_DEFAULT, C_FSATA_GEN1)) );

signal g_dcm_clk0     : std_logic;
signal i_dcm_clk0     : std_logic;
signal i_dcm_clk2x    : std_logic;
signal i_dcm_clkdv    : std_logic;
signal g_dcm_clkfb    : std_logic;

--//MAIN
begin


p_out_refclkout<='0';--p_in_clk;
--bufg_refclk    : BUFG port map (I => p_in_clk, O => p_out_refclkout);

bufg_dcm_clk0  : BUFG port map (I=>i_dcm_clk0,  O=>g_dcm_clk0); p_out_dcm_gclk0<=g_dcm_clk0;
bufg_dcm_clk2x : BUFG port map (I=>i_dcm_clk2x, O=>p_out_dcm_gclk2x);
bufg_dcm_clkdv : BUFG port map (I=>i_dcm_clkdv, O=>p_out_dcm_gclkdv);

m_dcm : PLL_BASE
generic map(
CLKIN_PERIOD   => 6.6,             --150MHz
CLKOUT0_DIVIDE => 2,               --(150*4)/2 =300MHz
CLKOUT0_PHASE  => 0.0,
CLKOUT1_DIVIDE => 4,               --(150*4)/4 =150MHz
CLKOUT1_PHASE  => 0.0,
CLKOUT2_DIVIDE => CI_CLKDV_DIVIDE, --(150*4)/8 =75MHz; 37.5MHz
CLKOUT2_PHASE  => 0.0,
CLKOUT3_DIVIDE => 16,
CLKOUT3_PHASE  => 0.0,
CLKFBOUT_MULT  => 4,
DIVCLK_DIVIDE  => 1,
CLK_FEEDBACK   => "CLKFBOUT",
CLKFBOUT_PHASE => 0.0,
COMPENSATION   => "SYSTEM_SYNCHRONOUS"
)
port map(
CLKIN    => p_in_clk,
CLKFBIN  => g_dcm_clkfb,
CLKOUT0  => i_dcm_clk2x,
CLKOUT1  => i_dcm_clk0,
CLKOUT2  => i_dcm_clkdv,
CLKOUT3  => open,
CLKOUT4  => open,
CLKOUT5  => open,
CLKFBOUT => g_dcm_clkfb,
LOCKED   => p_out_dcmlock,
RST      => p_in_rst
);


--//END MAIN
end BEHAVIORAL;
