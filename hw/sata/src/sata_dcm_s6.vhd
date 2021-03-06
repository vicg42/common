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
p_out_dcm_clk2x  : out   std_logic;
p_out_dcmlock    : out   std_logic;

p_out_refclkout  : out   std_logic;
p_in_clk         : in    std_logic;
p_in_rst         : in    std_logic
);
end sata_dcm;

architecture behavioral of sata_dcm is

constant CI_CLKDV_DIVIDE   : real:=selval_real(4.0, 2.0, (cmpval(G_GT_DBUS, 32) and cmpval(C_FSATA_GEN_DEFAULT, C_FSATA_GEN1)) );

--signal g_dcm_clkin    : std_logic;
signal g_dcm_clk0     : std_logic;
signal i_dcm_clk0     : std_logic;
signal i_dcm_clk2x    : std_logic;
signal i_dcm_clkdv    : std_logic;
signal g_dcm_clkfb    : std_logic;

--//MAIN
begin


--p_out_refclkout<=p_in_clk;
bufg_refclk    : BUFG port map (I => p_in_clk, O => p_out_refclkout);
p_out_dcm_clk2x<=i_dcm_clk2x;
bufg_dcm_clk0  : BUFG port map (I=>i_dcm_clk0,  O=>g_dcm_clk0); p_out_dcm_gclk0<=g_dcm_clk0;
bufg_dcm_clk2x : BUFG port map (I=>i_dcm_clk2x, O=>p_out_dcm_gclk2x);
bufg_dcm_clkdv : BUFG port map (I=>i_dcm_clkdv, O=>p_out_dcm_gclkdv);
bufg_dcm_clkfb : BUFIO2FB port map (I=>g_dcm_clk0, O=>g_dcm_clkfb);

m_dcm : DCM_SP
generic map(
CLKDV_DIVIDE           => CI_CLKDV_DIVIDE,
CLKFX_DIVIDE           => 1,
CLKFX_MULTIPLY         => 2,
CLKIN_DIVIDE_BY_2      => FALSE,  -- ������./����. ������ CLKIN �� 2
CLKIN_PERIOD           => 6.6,    -- Specify period of input clock in ns from 1.25 to 1000.00
CLKOUT_PHASE_SHIFT     => "NONE", -- Specify phase shift mode of NONE or FIXED
CLK_FEEDBACK           => "1X",   -- Specify clock feedback of NONE or 1X
DESKEW_ADJUST          => "SYSTEM_SYNCHRONOUS", -- SOURCE_SYNCHRONOUS, SYSTEM_SYNCHRONOUS or an integer from 0 to 15
DFS_FREQUENCY_MODE     => "LOW",  -- Unsupported - Do not change value
DLL_FREQUENCY_MODE     => "LOW",  -- Unsupported - Do not change value
DSS_MODE               => "NONE", -- Unsupported - Do not change value
DUTY_CYCLE_CORRECTION  => TRUE,   -- Unsupported - Do not change value
FACTORY_JF             => X"c080",-- Unsupported - Do not change value
PHASE_SHIFT            => 0,      -- Amount of fixed phase shift from -255 to 1023
STARTUP_WAIT           => FALSE   -- Delay configuration DONE until DCM LOCK, TRUE/FALSE
)
port map(
CLKFB    => g_dcm_clkfb,

CLK0     => i_dcm_clk0,
CLK90    => open,
CLK180   => open,
CLK270   => open,

CLK2X    => i_dcm_clk2x,
CLK2X180 => open,

CLKFX    => open,
CLKFX180 => open,

CLKDV    => i_dcm_clkdv,

LOCKED   => p_out_dcmlock,

PSDONE   => open,
STATUS   => open,
DSSEN    => '0',
PSCLK    => '0',
PSEN     => '0',
PSINCDEC => '0',

CLKIN    => p_in_clk,
RST      => p_in_rst
);


--//END MAIN
end BEHAVIORAL;
