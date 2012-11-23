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

library work;
use work.clocks_pkg.all;

entity clocks is
port(
p_out_rst  : out   std_logic;
p_out_gclk : out   std_logic_vector(7 downto 0);

p_in_clkopt: in    std_logic_vector(3 downto 0);
p_in_clk   : in    TRefClkPinIN
);
end;

architecture synth of clocks is

signal i_pll_clkin   : std_logic;
signal g_pll_clkin   : std_logic;
signal i_pll_rst_cnt : std_logic_vector(4 downto 0) := "11111";
signal i_pll_rst     : std_logic := '1';
signal i_clk_fb      : std_logic;
signal g_clk_fb      : std_logic;
signal i_pll_locked  : std_logic;
signal i_clk_out     : std_logic_vector(7 downto 0);

begin

m_buf : IBUFDS port map(I  => p_in_clk.clk_p, IB => p_in_clk.clk_n, O => i_pll_clkin);--200MHz
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

-- Reference clock PLL (CLKFBOUT range 400 MHz to 1000 MHz)
-- CLKFBOUT = (CLKIN1/DIVCLK_DIVIDE) * CLKFBOUT_MULT_F
-- CLKOUTn  = (CLKIN1/DIVCLK_DIVIDE) * CLKFBOUT_MULT_F/CLKOUTn_DIVIDE
-- CLKFBOUT = (200 MHz/2) * 9.000       = 900 MHz
-- CLKOUT1  = (200 MHz/2) * 9.000/3     = 300 MHz (mem_clk)
-- CLKOUT2  = (200 MHz/2) * 9.000/9     = 100 MHz (tmr_clk)

m_pll : PLL_BASE
generic map(
CLKIN_PERIOD   => 5.00,
DIVCLK_DIVIDE  => 2,     --integer : 1 to 52
CLKFBOUT_MULT  => 9,     --integer : 1 to 64
CLKOUT0_DIVIDE => 1,     --integer : 1 to 128
CLKOUT1_DIVIDE => 3,     --integer : 1 to 128
CLKOUT2_DIVIDE => 9,     --integer : 1 to 128
CLKOUT3_DIVIDE => 1,     --integer : 1 to 128
CLKOUT0_PHASE  => 0.000,
CLKOUT1_PHASE  => 0.000,
CLKOUT2_PHASE  => 0.000,
CLKOUT3_PHASE  => 0.000
)
port map(
CLKFBOUT => i_clk_fb,
CLKOUT0  => open,
CLKOUT1  => i_clk_out(1),
CLKOUT2  => i_clk_out(2),
CLKOUT3  => open,
CLKOUT4  => open,
CLKOUT5  => open,
LOCKED   => i_pll_locked,
CLKFBIN  => g_clk_fb,
CLKIN    => i_pll_clkin,
RST      => i_pll_rst
);

-- MMCM feedback (not using BUFG, because we don't care about phase compensation)
g_clk_fb <= i_clk_fb;

-- Generate asynchronous reset
p_out_rst <= not(i_pll_locked);

p_out_gclk(0) <= g_pll_clkin;
bufg_clk1: BUFG port map(I => i_clk_out(1), O => p_out_gclk(1)); --300MHz
bufg_clk2: BUFG port map(I => i_clk_out(2), O => p_out_gclk(2)); --100MHz
                                                 p_out_gclk(3)<=i_clk_out(3);
                                                 p_out_gclk(4)<=i_clk_out(4); --125MHz
                                                 p_out_gclk(5)<='0';--��������������� 128MHz ��� pult, edev!!!
                                                 p_out_gclk(6)<=i_clk_out(6);
p_out_gclk(7)<='0';--��������������� 14,401440MHz ��� sync!!!

m_buf_pciexp : IBUFDS port map(I  => p_in_clk.pciexp_clk_p, IB => p_in_clk.pciexp_clk_n, O => i_clk_out(3));

m_buf_fiber0 : IBUFDS port map(I  => p_in_clk.fiber_clk_p(0), IB => p_in_clk.fiber_clk_n(0), O => i_clk_out(4));
m_buf_fiber1 : IBUFDS port map(I  => p_in_clk.fiber_clk_p(1), IB => p_in_clk.fiber_clk_n(1), O => i_clk_out(6));

end;