-------------------------------------------------------------------------
-- Company     : Linkos
-- Engineer    : Golovachenko Victor
--
-- Create Date : 18.10.2011 15:59:43
-- Module Name : clocks
--
-- ����������/�������� :
--
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

entity clocks is
port(
-- Reset output
p_out_pll_rst      : out   std_logic;
-- Clock outputs
p_out_pll_gclkin   : out   std_logic;
p_out_pll_mem_clk  : out   std_logic;
p_out_pll_tmr_clk  : out   std_logic;
--p_out_pll_reg_clk  : out   std_logic;

-- Clock pins
p_in_clk           : in    std_logic
);
end;

architecture synth of clocks is

signal g_pll_clkin   : std_logic;
signal i_pll_rst_cnt : std_logic_vector(4 downto 0) := "11111";
signal i_pll_rst     : std_logic := '1';
signal i_clk_fb      : std_logic;
signal g_clk_fb      : std_logic;
signal i_pll_locked  : std_logic;
signal i_clk0_out    : std_logic;
signal i_clk1_out    : std_logic;
signal i_clk2_out    : std_logic;
signal i_clk3_out    : std_logic;


begin


bufg_pll_clkin : BUFG port map(I  => p_in_clk, O  => g_pll_clkin);

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


-- Reference clock MMCM (CLKFBOUT range 600 MHz to 1200 MHz)
-- CLKFBOUT = (CLKIN1/DIVCLK_DIVIDE) * CLKFBOUT_MULT_F
-- CLKOUTn  = (CLKIN1/DIVCLK_DIVIDE) * CLKFBOUT_MULT_F/CLKOUTn_DIVIDE
-- CLKFBOUT = (200 MHz/3) * 12.000       = 800 MHz
-- CLKOUT0  = (200 MHz/3) * 12.000/4.000 = 200 MHz (pll_pri_clk)
-- CLKOUT1  = (200 MHz/3) * 12.000/10    =  80 MHz (pll_reg_clk)
-- CLKOUT2  = (200 MHz/3) * 12.000/2     = 400 MHz (pll_mem_clk)
-- CLKOUT3  = (200 MHz/3) * 12.000/8     = 100 MHz (pll_tmr_clk)

mmcm_ref_clk_i : MMCM_BASE
generic map(
BANDWIDTH          => "OPTIMIZED", -- string := "OPTIMIZED"
CLKIN1_PERIOD      => 5.000,       -- real := 0.0
DIVCLK_DIVIDE      => 3,           -- integer := 1 (1 to 128)
CLKFBOUT_MULT_F    => 12.000,      -- real := 1.0  (5.0 to 64.0)
CLKOUT0_DIVIDE_F   => 4.000,       -- real := 1.0  (1.0 to 128.0)
CLKOUT1_DIVIDE     => 10,          -- integer := 1
CLKOUT2_DIVIDE     => 2,           -- integer := 1
CLKOUT3_DIVIDE     => 8,           -- integer := 1
CLKOUT4_DIVIDE     => 1,           -- integer := 1
CLKOUT5_DIVIDE     => 1,           -- integer := 1
CLKOUT6_DIVIDE     => 1,           -- integer := 1
CLKFBOUT_PHASE     => 0.000,       -- real := 0.0
CLKOUT0_PHASE      => 0.000,       -- real := 0.0
CLKOUT1_PHASE      => 0.000,       -- real := 0.0
CLKOUT2_PHASE      => 0.000,       -- real := 0.0
CLKOUT3_PHASE      => 0.000,       -- real := 0.0
CLKOUT4_PHASE      => 0.000,       -- real := 0.0
CLKOUT5_PHASE      => 0.000,       -- real := 0.0
CLKOUT6_PHASE      => 0.000,       -- real := 0.0
CLKOUT0_DUTY_CYCLE => 0.500,       -- real := 0.5
CLKOUT1_DUTY_CYCLE => 0.500,       -- real := 0.5
CLKOUT2_DUTY_CYCLE => 0.500,       -- real := 0.5
CLKOUT3_DUTY_CYCLE => 0.500,       -- real := 0.5
CLKOUT4_DUTY_CYCLE => 0.500,       -- real := 0.5
CLKOUT5_DUTY_CYCLE => 0.500,       -- real := 0.5
CLKOUT6_DUTY_CYCLE => 0.500,       -- real := 0.5
CLKOUT4_CASCADE    => FALSE,       -- boolean := FALSE
CLOCK_HOLD         => FALSE,       -- boolean := FALSE
REF_JITTER1        => 0.0,         -- real := 0.0
STARTUP_WAIT       => FALSE)       -- boolean := FALSE
port map(
RST       => i_pll_rst,    -- in std_ulogic;
PWRDWN    => '0',          -- in std_ulogic;
CLKIN1    => p_in_clk,     -- in std_ulogic;
CLKFBIN   => g_clk_fb,     -- in std_ulogic;
CLKFBOUT  => i_clk_fb,     -- out std_ulogic;
CLKFBOUTB => open,         -- out std_ulogic;
CLKOUT0   => i_clk0_out,   -- out std_ulogic;
CLKOUT0B  => open,         -- out std_ulogic;
CLKOUT1   => i_clk1_out,   -- out std_ulogic;
CLKOUT1B  => open,         -- out std_ulogic;
CLKOUT2   => i_clk2_out,   -- out std_ulogic;
CLKOUT2B  => open,         -- out std_ulogic;
CLKOUT3   => i_clk3_out,   -- out std_ulogic;
CLKOUT3B  => open,         -- out std_ulogic;
CLKOUT4   => open,         -- out std_ulogic;
CLKOUT5   => open,         -- out std_ulogic;
CLKOUT6   => open,         -- out std_ulogic;
LOCKED    => i_pll_locked  -- out std_ulogic;
);

-- MMCM feedback (not using BUFG, because we don't care about phase compensation)
g_clk_fb <= i_clk_fb;

-- Generate asynchronous reset
p_out_pll_rst <= not(i_pll_locked);

p_out_pll_gclkin <= g_pll_clkin;
bufg_mem_clk: BUFG port map(I => i_clk2_out, O => p_out_pll_mem_clk);
bufg_tmr_clk: BUFG port map(I => i_clk3_out, O => p_out_pll_tmr_clk);
--p_out_pll_pri_clk <= '0';
--p_out_pll_reg_clk <= '0';

end;