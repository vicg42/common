-------------------------------------------------------------------------
-- Company     : Linkos
-- Engineer    : Golovachenko Victor
--
-- Create Date : 05.06.2011 15:14:31
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

entity sata_dcm is
generic(
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

signal i_clkfb        : std_logic;
signal g_dcm_clkin    : std_logic;
signal g_dcm_clk0     : std_logic;
signal i_dcm_clk0     : std_logic;
signal i_dcm_clk2x    : std_logic;
signal i_dcm_clkdv    : std_logic;

--//MAIN
begin


p_out_refclkout<=g_dcm_clkin;

bufg_gt_refclkout : BUFG port map (I => p_in_clk, O => g_dcm_clkin);

bufg_dcm_clk0  : BUFG port map (I=>i_dcm_clk0,  O=>g_dcm_clk0); p_out_dcm_gclk0<=g_dcm_clk0;
bufg_dcm_clk2x : BUFG port map (I=>i_dcm_clk2x, O=>p_out_dcm_gclk2x);
bufg_dcm_clkdv : BUFG port map (I=>i_dcm_clkdv, O=>p_out_dcm_gclkdv);


m_dcm : MMCM_BASE
generic map(
BANDWIDTH          => "OPTIMIZED",--Jitter programming("HIGH","LOW","OPTIMIZED")
CLKFBOUT_MULT_F    => 8.0,        --Multiply value fo rall CLKOUT(5.0-64.0).
CLKFBOUT_PHASE     => 0.0,        --Phase offset in degrees of CLKFB(0.00-360.00).
CLKIN1_PERIOD      => 6.6,        --150MHz - Input clock period in ns to ps resolution(i.e.33.333is30MHz).
CLKOUT0_DIVIDE_F   => 1.0,        --Divide amount for CLKOUT0(1.000-128.000).

--CLKOUT0_DUTY_CYCLE-CLKOUT6_DUTY_CYCLE:Duty cycle for each CLKOUT(0.01-0.99).
CLKOUT0_DUTY_CYCLE => 0.5,
CLKOUT1_DUTY_CYCLE => 0.5,
CLKOUT2_DUTY_CYCLE => 0.5,
CLKOUT3_DUTY_CYCLE => 0.5,
CLKOUT4_DUTY_CYCLE => 0.5,
CLKOUT5_DUTY_CYCLE => 0.5,
CLKOUT6_DUTY_CYCLE => 0.5,

--CLKOUT0_PHASE-CLKOUT6_PHASE:Phase offset for each CLKOUT(-360.000-360.000).
CLKOUT0_PHASE      => 0.0,
CLKOUT1_PHASE      => 0.0,
CLKOUT2_PHASE      => 0.0,
CLKOUT3_PHASE      => 0.0,
CLKOUT4_PHASE      => 0.0,
CLKOUT5_PHASE      => 0.0,
CLKOUT6_PHASE      => 0.0,

--CLKOUT1_DIVIDE-CLKOUT6_DIVIDE:Divide amount for each CLKOUT(1-128)
CLKOUT1_DIVIDE     => 4,
CLKOUT2_DIVIDE     => 8,
CLKOUT3_DIVIDE     => 16,
CLKOUT4_DIVIDE     => 1,
CLKOUT5_DIVIDE     => 1,
CLKOUT6_DIVIDE     => 1,
CLKOUT4_CASCADE    => FALSE, --Cascase CLKOUT4 counter with CLKOUT6(TRUE/FALSE)
CLOCK_HOLD         => FALSE, --Hold VCOF requency(TRUE/FALSE)
DIVCLK_DIVIDE      => 1,     --Master division value(1-80)
REF_JITTER1        => 0.0,   --Reference input jitter in UI(0.000-0.999).
STARTUP_WAIT       => FALSE  --Not supported. Must be set to FALSE.
)
port map(
--Clock Outputs:1-bit(each)output:User configurable clock outputs
CLKOUT0  => i_dcm_clk2x, --1-bit output:CLKOUT0 output
CLKOUT0B => open,        --1-bit output:Inverted CLKOUT0output

CLKOUT1  => i_dcm_clk0,  --1-bit output:CLKOUT1 output
CLKOUT1B => open,        --1-bit output:Inverted CLKOUT1output

CLKOUT2  => i_dcm_clkdv, --1-bit output:CLKOUT2 output
CLKOUT2B => open,        --1-bit output:Inverted CLKOUT2output

CLKOUT3  => open,        --1-bit output:CLKOUT3 output
CLKOUT3B => open,        --1-bit output:Inverted CLKOUT3output

CLKOUT4  => open,        --1-bit output:CLKOUT4 output
CLKOUT5  => open,        --1-bit output:CLKOUT5 output
CLKOUT6  => open,        --1-bit output:CLKOUT6 output

--Feedback Clocks:1-bit(each)output:Clock feedback ports
CLKFBOUT => i_clkfb,     --1-bitoutput:Feedback clock output
CLKFBOUTB=> open,        --1-bitoutput:Inverted CLKFBOUT output

--StatusPort:1-bit(each)output:MMCM status ports
LOCKED   => p_out_dcmlock,

--ClockInput:1-bit(each)input:Clock input
CLKIN1   => g_dcm_clkin,

--ControlPorts:1-bit(each)input:MMCM control ports
PWRDWN   => '0',

RST      => p_in_clk,    --1-bitinput:Reset input

--FeedbackClocks:1-bit(each)input:Clock feedback ports
CLKFBIN  => i_clkfb      --1-bitinput:Feedback clock input
);


--//END MAIN
end BEHAVIORAL;
