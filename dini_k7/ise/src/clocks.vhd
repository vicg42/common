-------------------------------------------------------------------------
-- Company     : Linkos
-- Engineer    : Golovachenko Victor
--
-- Create Date : 18.10.2011 15:59:43
-- Module Name : clocks
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
use ieee.std_logic_unsigned.all;
use ieee.std_logic_misc.all;

library unisim;
use unisim.vcomponents.all;

library work;
use work.clocks_pkg.all;
--use work.eth_pkg.all;
use work.prj_cfg.all;

entity clocks is
port(
p_out_rst  : out   std_logic;
p_out_gclk : out   std_logic_vector(7 downto 0);

p_in_clkopt: in    std_logic_vector(3 downto 0);
p_out_clk  : out   TRefClkPinOUT;
p_in_clk   : in    TRefClkPinIN
);
end;

architecture synth of clocks is

signal i_pll_clkin   : std_logic;
signal g_pll_clkin   : std_logic;
signal i_pll_rst_cnt : std_logic_vector(4 downto 0) := "11111";
signal i_pll_rst     : std_logic := '1';
signal i_clk_fb      : std_logic_vector(0 downto 0);
signal g_clk_fb      : std_logic_vector(0 downto 0);
signal i_pll_locked  : std_logic_vector(0 downto 0);
signal i_clk_out     : std_logic_vector(7 downto 0);
signal i_mem_clkin   : std_logic;

begin


p_out_clk.oe <= (others=>'1');-- Oscillator Output Enable


m_buf : IBUFDS port map(I  => p_in_clk.clk_p(0), IB => p_in_clk.clk_n(0), O => i_pll_clkin);--400MHz
bufg_pll_clkin : BUFG port map(I  => i_pll_clkin, O  => g_pll_clkin);

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

-- Reference clock MMCM (CLKFBOUT range 600.00 MHz to 1440.00 MHz)
-- CLKFBOUT = (CLKIN1/DIVCLK_DIVIDE) * CLKFBOUT_MULT_F
-- CLKOUTn  = (CLKIN1/DIVCLK_DIVIDE) * CLKFBOUT_MULT_F/CLKOUTn_DIVIDE
-- CLKFBOUT = (400 MHz/4) * 10.000      = 1000 MHz
-- CLKOUT0  = (400 MHz/4) * 10.000/2.5  = 400 MHz
-- CLKOUT1  = (400 MHz/4) * 10.000/5    = 200 MHz
-- CLKOUT2  = (400 MHz/4) * 10.000/8    = 125 MHz
-- CLKOUT3  = (400 MHz/4) * 10.000/10   = 100 MHz

mmcm_ref_clk_i : MMCME2_BASE
generic map(
BANDWIDTH          => "OPTIMIZED", -- string := "OPTIMIZED"
CLKIN1_PERIOD      => 2.500,       -- real := 0.0
DIVCLK_DIVIDE      => 4,           -- integer := 1 (1 to 128)
CLKFBOUT_MULT_F    => 10.000,      -- real := 1.0  (5.0 to 64.0)
CLKOUT0_DIVIDE_F   => 2.500,       -- real := 1.0  (1.0 to 128.0)
CLKOUT1_DIVIDE     => 5,           -- integer := 1
CLKOUT2_DIVIDE     => 8,           -- integer := 1
CLKOUT3_DIVIDE     => 10,          -- integer := 1
CLKOUT4_DIVIDE     => 25,          -- integer := 1
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
REF_JITTER1        => 0.0,         -- real := 0.0
STARTUP_WAIT       => FALSE)       -- boolean := FALSE
port map(
RST       => i_pll_rst,    -- in std_ulogic;
PWRDWN    => '0',          -- in std_ulogic;
CLKIN1    => g_pll_clkin,  -- in std_ulogic;
CLKFBIN   => g_clk_fb(0),  -- in std_ulogic;
CLKFBOUT  => i_clk_fb(0),  -- out std_ulogic;
CLKFBOUTB => open,         -- out std_ulogic;
CLKOUT0   => i_clk_out(0), -- out std_ulogic;
CLKOUT0B  => open,         -- out std_ulogic;
CLKOUT1   => i_clk_out(1), -- out std_ulogic;
CLKOUT1B  => open,         -- out std_ulogic;
CLKOUT2   => i_clk_out(2), -- out std_ulogic;
CLKOUT2B  => open,         -- out std_ulogic;
CLKOUT3   => i_clk_out(3), -- out std_ulogic;
CLKOUT3B  => open,         -- out std_ulogic;
CLKOUT4   => i_clk_out(5), -- out std_ulogic;
CLKOUT5   => open,         -- out std_ulogic;
CLKOUT6   => open,         -- out std_ulogic;
LOCKED    => i_pll_locked(0)-- out std_ulogic;
);
-- MMCM feedback (not using BUFG, because we don't care about phase compensation)
g_clk_fb(0) <= i_clk_fb(0);

-- Generate asynchronous reset
p_out_rst <= not(AND_reduce(i_pll_locked));

bufg_clk0: BUFG port map(I => i_clk_out(1), O => p_out_gclk(0)); --200MHz
                                                 p_out_gclk(1) <= g_pll_clkin; --400MHz
bufg_clk2: BUFG port map(I => i_clk_out(3), O => p_out_gclk(2)); --100MHz
                                                 p_out_gclk(3)<=i_clk_out(4);


m_buf_pciexp : IBUFDS_GTE2 port map (
I     => p_in_clk.pciexp_clk_p,
IB    => p_in_clk.pciexp_clk_n,
CEB   => '0',
O     => i_clk_out(4),
ODIV2 => open
);




end;
