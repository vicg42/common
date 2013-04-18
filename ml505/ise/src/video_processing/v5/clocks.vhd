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
use ieee.std_logic_arith.all;
use ieee.std_logic_misc.all;
use ieee.std_logic_unsigned.all;

library unisim;
use unisim.vcomponents.all;

library work;
use work.clocks_pkg.all;
use work.eth_pkg.all;
use work.prj_cfg.all;

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
signal i_clk_fb      : std_logic_vector(0 downto 0);
signal g_clk_fb      : std_logic_vector(0 downto 0);
signal i_pll_locked  : std_logic_vector(0 downto 0);
signal i_clk_out     : std_logic_vector(7 downto 0);
signal i_eth_clk     : std_logic;

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
-- CLKFBOUT = (CLKIN1/DIVCLK_DIVIDE) * CLKFBOUT_MULT
-- CLKOUTn  = (CLKIN1/DIVCLK_DIVIDE) * CLKFBOUT_MULT/CLKOUTn_DIVIDE
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
CLKFBOUT => i_clk_fb(0),
CLKOUT0  => open,
CLKOUT1  => i_clk_out(1),
CLKOUT2  => i_clk_out(2),
CLKOUT3  => open,
CLKOUT4  => open,
CLKOUT5  => open,
LOCKED   => i_pll_locked(0),
CLKFBIN  => g_clk_fb(0),
CLKIN    => i_pll_clkin,
RST      => i_pll_rst
);

-- MMCM feedback (not using BUFG, because we don't care about phase compensation)
g_clk_fb(0) <= i_clk_fb(0);

-- Generate asynchronous reset
p_out_rst <= not(OR_reduce(i_pll_locked));

p_out_gclk(0) <= g_pll_clkin;
bufg_clk1: BUFG port map(I => i_clk_out(1), O => p_out_gclk(1)); --300MHz
bufg_clk2: BUFG port map(I => i_clk_out(2), O => p_out_gclk(2)); --100MHz
                                                 p_out_gclk(3)<='0';
                                                 p_out_gclk(4)<='0';--i_eth_clk; --125MHz
                                                 p_out_gclk(5)<='0';--зарезервировано 128MHz для pult, edev!!!
                                                 p_out_gclk(6)<='0';--i_clk_out(6);
p_out_gclk(7 downto 7)<=(others=>'0');--зарезервировано 14,401440MHz для sync!!!

--gen_eth_fiber : if C_PCFG_ETH_PHY_SEL=C_ETH_PHY_FIBER generate
--m_buf_fiber0  : IBUFDS port map(I  => p_in_clk.fiber_clk_p(0), IB => p_in_clk.fiber_clk_n(0), O => i_eth_clk);
--m_buf_fiber1  : IBUFDS port map(I  => p_in_clk.fiber_clk_p(1), IB => p_in_clk.fiber_clk_n(1), O => i_clk_out(6));
--end generate gen_eth_fiber;
--
--gen_eth_copper : if C_PCFG_ETH_PHY_SEL/=C_ETH_PHY_FIBER generate
--i_eth_clk<=i_clk_out(4);
--i_clk_out(6)<='0';
--end generate gen_eth_copper;
--
------------------------------------
----Eth Copper
------------------------------------
---- Reference clock PLL (CLKFBOUT range 400 MHz to 1000 MHz)
---- CLKFBOUT = (CLKIN1/DIVCLK_DIVIDE) * CLKFBOUT_MULT
---- CLKOUTn  = (CLKIN1/DIVCLK_DIVIDE) * CLKFBOUT_MULT/CLKOUTn_DIVIDE
---- CLKFBOUT = (200 MHz/2) * 10.000       = 1000 MHz
---- CLKOUT0  = (200 MHz/2) * 10.000/8     = 125 MHz
--
--m_pll_1 : PLL_BASE
--generic map(
--CLKIN_PERIOD   => 5.00,
--DIVCLK_DIVIDE  => 2,    --integer : 1 to 52
--CLKFBOUT_MULT  => 10,   --integer : 1 to 64
--CLKOUT0_DIVIDE => 8,    --integer : 1 to 128
--CLKOUT1_DIVIDE => 3,    --integer : 1 to 128
--CLKOUT2_DIVIDE => 9,    --integer : 1 to 128
--CLKOUT3_DIVIDE => 1,    --integer : 1 to 128
--CLKOUT0_PHASE  => 0.000,
--CLKOUT1_PHASE  => 0.000,
--CLKOUT2_PHASE  => 0.000,
--CLKOUT3_PHASE  => 0.000
--)
--port map(
--CLKFBOUT => i_clk_fb(1),
--CLKOUT0  => i_clk_out(4),
--CLKOUT1  => open,
--CLKOUT2  => open,
--CLKOUT3  => open,
--CLKOUT4  => open,
--CLKOUT5  => open,
--LOCKED   => i_pll_locked(1),
--CLKFBIN  => g_clk_fb(1),
--CLKIN    => i_pll_clkin,
--RST      => i_pll_rst
--);
--
---- MMCM feedback (not using BUFG, because we don't care about phase compensation)
--g_clk_fb(1) <= i_clk_fb(1);

end;