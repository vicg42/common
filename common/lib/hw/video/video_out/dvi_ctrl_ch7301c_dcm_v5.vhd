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
signal i_clk_out             : std_logic_vector(2 downto 0);
signal i_gnd                 : std_logic_vector(15 downto 0);

--MAIN
begin



bufg_clk_fb: BUFG port map(I => i_clk_fb, O => g_clk_fb);--g_clk_fb <= i_clk_fb;
p_out_rst <= not i_locked;

bufg_clk_pix: BUFG port map(I => i_clk_out(0), O => p_out_gclk(0));


m_dcm : DCM_ADV
generic map(
--CLKIN = 100MHz
CLKIN_PERIOD   => 10.000,

----CLKFX = 50MHz
--CLKFX_MULTIPLY => 2,
--CLKFX_DIVIDE   => 4,

--CLKFX = 75MHz
CLKFX_MULTIPLY => 3,
CLKFX_DIVIDE   => 4,

----CLKFX = 135MHz
--CLKFX_MULTIPLY => 27,
--CLKFX_DIVIDE   => 20,

----CLKFX = 175MHz
--CLKFX_MULTIPLY => 7,
--CLKFX_DIVIDE   => 4,

--CLKDV = 25MHz
CLKDV_DIVIDE          => 4.0,

CLKIN_DIVIDE_BY_2     => FALSE,
CLK_FEEDBACK          => "1X",
CLKOUT_PHASE_SHIFT    => "NONE",
DCM_AUTOCALIBRATION   => TRUE,
DCM_PERFORMANCE_MODE  => "MAX_SPEED",
DESKEW_ADJUST         => "SYSTEM_SYNCHRONOUS",
DFS_FREQUENCY_MODE    => "LOW",
DLL_FREQUENCY_MODE    => "LOW",
DUTY_CYCLE_CORRECTION => TRUE,
FACTORY_JF            => x"F0F0",
PHASE_SHIFT           => 0,
STARTUP_WAIT          => FALSE,
SIM_DEVICE            => "VIRTEX5"
)
port map (
CLKFB    => g_clk_fb,
CLK0     => i_clk_fb,
CLKDV    => i_clk_out(1),
CLKFX    => i_clk_out(0),
CLKFX180 => open,
CLK2X    => open,
CLK2X180 => open,
CLK90    => open,
CLK180   => open,
CLK270   => open,
DRDY     => open,

LOCKED   => i_locked,

DADDR(6 downto 0)=> i_gnd(6 downto 0),
DI(15 downto 0)  => i_gnd(15 downto 0),
DO       => open,
DEN      => '0',
DWE      => '0',
DCLK     => '0',

PSCLK    => '0',
PSEN     => '0',
PSINCDEC => '0',
PSDONE   => open,

CLKIN    => p_in_clk,
RST      => p_in_rst
);

i_gnd <= (others=>'0');

--END MAIN
end v5_only;


