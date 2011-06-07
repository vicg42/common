-------------------------------------------------------------------------
-- Company     : Linkos
-- Engineer    : Golovachenko Victor
--
-- Create Date : 25/11/2008
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

entity sata_dcm is
generic (
G_GT_DBUS : integer:=16
);
port
(
p_out_dcm_gclk0     : out   std_logic;
p_out_dcm_gclk2x    : out   std_logic;
p_out_dcm_gclkdv    : out   std_logic;

p_out_dcmlock       : out   std_logic;

p_out_refclkout     : out   std_logic;
p_in_clk            : in    std_logic;--_vector(C_SH_COUNT_MAX(G_HDD_COUNT-1)-1 downto 0);
p_in_rst            : in    std_logic
);
end sata_dcm;

architecture behavioral of sata_dcm is

signal g_dcm_clkin    : std_logic;
signal g_dcm_clk0     : std_logic;
signal i_dcm_clk0     : std_logic;
signal i_dcm_clk2x    : std_logic;
signal i_dcm_clkdv    : std_logic;

--//MAIN
begin

p_out_refclkout <=g_dcm_clkin;
bufg_dcm_clkin : BUFG port map (I => p_in_clk, O => g_dcm_clkin);


bufg_dcm_clk0  : BUFG port map (I=>i_dcm_clk0,  O=>g_dcm_clk0); p_out_dcm_gclk0<=g_dcm_clk0;
bufg_dcm_clk2x : BUFG port map (I=>i_dcm_clk2x, O=>p_out_dcm_gclk2x);
bufg_dcm_clkdv : BUFG port map (I=>i_dcm_clkdv, O=>p_out_dcm_gclkdv);

m_dcm : DCM_BASE
generic map
(
CLKDV_DIVIDE           => 2.0,
CLKFX_DIVIDE           => 1,
CLKFX_MULTIPLY         => 2,
CLKIN_DIVIDE_BY_2      => FALSE,  -- разреш./запр. делить CLKIN на 2
CLKIN_PERIOD           => 6.667,  -- Specify period of input clock in ns from 1.25 to 1000.00
CLKOUT_PHASE_SHIFT     => "NONE", -- Specify phase shift mode of NONE or FIXED
CLK_FEEDBACK           => "1X",   -- Specify clock feedback of NONE or 1X
DCM_AUTOCALIBRATION    => TRUE,   -- DCM calibration circuitry TRUE/FALSE
DCM_PERFORMANCE_MODE   => "MAX_SPEED", -- Can be MAX_SPEED or MAX_RANGE
DESKEW_ADJUST          => "SYSTEM_SYNCHRONOUS", -- SOURCE_SYNCHRONOUS, SYSTEM_SYNCHRONOUS or an integer from 0 to 15
DFS_FREQUENCY_MODE     => "HIGH",  -- LOW or HIGH frequency mode for frequency synthesis
DLL_FREQUENCY_MODE     => "HIGH",  -- LOW, HIGH, or HIGH_SER frequency mode for DLL
DUTY_CYCLE_CORRECTION  => TRUE,    -- Duty cycle correction, TRUE or FALSE
FACTORY_JF             => X"F0F0", -- FACTORY JF Values Suggested to be set to X"F0F0"
PHASE_SHIFT            => 0,       -- Amount of fixed phase shift from -255 to 1023
--SIM_DEVICE             => "VIRTEX5",
STARTUP_WAIT           => FALSE    -- Delay configuration DONE until DCM LOCK, TRUE/FALSE
)
port map
(
CLKFB    => g_dcm_clk0,

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

CLKIN    => p_in_clk,
RST      => p_in_rst
);

--//END MAIN
end BEHAVIORAL;
