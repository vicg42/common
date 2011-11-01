--
-- lbus_dcm.vhd - generate local bus clock for distribution within FPGA
--                using a DCM.
--
-- SYNTHESIZABLE
--

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_misc.all;
use ieee.std_logic_unsigned.all;

library unisim;
use unisim.vcomponents.all;

entity lbus_dcm is
generic(
G_CLKFX_DIV  : integer:=1;
G_CLKFX_MULT : integer:=2
);
port(
p_out_gclkin : out   std_logic;
p_out_clk0   : out   std_logic;
p_out_clkfx  : out   std_logic;
--p_out_clkdiv : out   std_logic;
--p_out_clk2x  : out   std_logic;
p_out_locked : out   std_logic;

p_in_clk     : in    std_logic;
p_in_rst     : in    std_logic
);
end entity;

architecture struct of lbus_dcm is

signal g_clkin      : std_logic;
signal i_clk0       : std_logic;
signal g_clk0       : std_logic;
signal i_clkfx      : std_logic;
signal i_clkdiv     : std_logic;
signal i_clk2x      : std_logic;

--//MAIN
begin

p_out_clk0 <= g_clk0;
p_out_gclkin <= g_clkin;

ibufg_lclk : IBUFG port map(I => p_in_clk,O => g_clkin);
bufg_clk   : BUFG  port map(I => i_clk0  ,O => g_clk0);
bufg_clkfx : BUFG  port map(I => i_clkfx ,O => p_out_clkfx);
--bufg_clkdiv: BUFG  port map(I => i_clkdiv,O => p_out_clkdiv);
--bufg_clk2x : BUFG  port map(I => i_clk2x ,O => p_out_clk2x);

m_dcm : DCM_BASE
generic map(
CLKFX_DIVIDE   => G_CLKFX_DIV,
CLKFX_MULTIPLY => G_CLKFX_MULT
)
port map(
CLKFB    => g_clk0,
CLK0     => i_clk0,
CLK90    => open,
CLK180   => open,
CLK270   => open,
CLK2X    => open,--i_clk2x,
CLK2X180 => open,
CLKDV    => open,--i_clkdiv,
CLKFX    => i_clkfx,
CLKFX180 => open,
LOCKED   => p_out_locked,

CLKIN    => g_clkin,
RST      => p_in_rst
);

--//END MAIN
end architecture;
