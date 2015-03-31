-------------------------------------------------------------------------
-- Engineer    : Golovachenko Victor
--
-- Create Date : 11/11/2009
-- Module Name : pcie_irq.vhd
--
-- Description : Endpoint Intrrupt Controller
--               pcie_blk_plus_ug341.pdf/topic Generating Interrupt Requests
--
-------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.reduce_pack.all;
use work.prj_def.all;

entity pcie_irq is
port(
-----------------------------
--Usr Ctrl
-----------------------------
p_in_irq_clr           : in   std_logic;
p_in_irq_num           : in   std_logic_vector(4 downto 0);                  --CH num
p_in_irq_set           : in   std_logic_vector(C_HIRQ_COUNT_MAX - 1 downto 0);
p_out_irq_status       : out  std_logic_vector(C_HIRQ_COUNT_MAX - 1 downto 0);

-----------------------------
--PCIE Port
-----------------------------
p_in_cfg_irq_dis       : in   std_logic;
p_in_cfg_msi           : in   std_logic;
p_in_cfg_irq_rdy_n     : in   std_logic;
p_out_cfg_irq_assert_n : out  std_logic;
p_out_cfg_irq_n        : out  std_logic;
p_out_cfg_irq_di       : out  std_logic_vector(7 downto 0);

-----------------------------
--DBG
-----------------------------
p_in_tst               : in   std_logic_vector(31 downto 0);
p_out_tst              : out  std_logic_vector(31 downto 0);

-----------------------------
--SYSTEM
-----------------------------
p_in_clk               : in   std_logic;
p_in_rst_n             : in   std_logic
);
end entity pcie_irq;

architecture behavioral of pcie_irq is

component pcie_irq_dev
generic(
G_TIME_DLY : integer:=0
);
port(
--User Ctrl
p_in_irq_set           : in   std_logic;
p_in_irq_clr           : in   std_logic;
p_out_irq_status       : out  std_logic;

--PCIE Port
p_in_cfg_msi           : in   std_logic;
p_in_cfg_irq_rdy_n     : in   std_logic;
p_out_cfg_irq_n        : out  std_logic;
p_out_cfg_irq_assert_n : out  std_logic;
p_out_cfg_irq_di       : out  std_logic_vector(7 downto 0);

--DBG
p_in_tst               : in  std_logic_vector(31 downto 0);
p_out_tst              : out std_logic_vector(31 downto 0);

--SYSTEM
p_in_clk               : in   std_logic;
p_in_rst_n             : in   std_logic
);
end component;

signal i_cfg_irq_n         : std_logic_vector(C_HIRQ_COUNT - 1 downto 0);
signal i_cfg_irq_assert_n  : std_logic_vector(C_HIRQ_COUNT - 1 downto 0);
signal i_irq_clr           : std_logic_vector(C_HIRQ_COUNT - 1 downto 0);


begin --architecture behavioral

p_out_tst <= (others => '0');


--16#00# - PCI_EXPRESS_LEGACY_INTA
--16#01# - PCI_EXPRESS_LEGACY_INTB
--16#02# - PCI_EXPRESS_LEGACY_INTC
--16#03# - PCI_EXPRESS_LEGACY_INTD
p_out_cfg_irq_di       <= std_logic_vector(TO_UNSIGNED(16#00#, p_out_cfg_irq_di'length));

p_out_cfg_irq_n        <= AND_reduce(i_cfg_irq_n(C_HIRQ_COUNT - 1 downto C_HIRQ_PCIE_DMA));
p_out_cfg_irq_assert_n <= AND_reduce(i_cfg_irq_assert_n(C_HIRQ_COUNT - 1 downto C_HIRQ_PCIE_DMA));


gen_ch: for ch in C_HIRQ_PCIE_DMA to C_HIRQ_COUNT - 1 generate

i_irq_clr(ch) <= p_in_irq_clr when UNSIGNED(p_in_irq_num) = ch else '0';

--IRQ ctrl
m_irq_dev : pcie_irq_dev
generic map(
G_TIME_DLY => 0
)
port map(
--USER Ctrl
p_in_irq_set           => p_in_irq_set(ch),
p_in_irq_clr           => i_irq_clr(ch),
p_out_irq_status       => p_out_irq_status(ch),

--PCIE Port
p_in_cfg_msi           => p_in_cfg_msi,
p_in_cfg_irq_rdy_n     => p_in_cfg_irq_rdy_n,
p_out_cfg_irq_n        => i_cfg_irq_n(ch),
p_out_cfg_irq_assert_n => i_cfg_irq_assert_n(ch),
p_out_cfg_irq_di       => open,

--DBG
p_in_tst               => (others => '0'),
p_out_tst              => open,--i_tst_out(ch),

--SYSTEM
p_in_clk               => p_in_clk,
p_in_rst_n             => p_in_rst_n
);

end generate gen_ch;

end architecture behavioral;

