-------------------------------------------------------------------------
-- Company     : Linkos
-- Engineer    : Golovachenko Victor
--
-- Create Date : 10/26/2007
-- Module Name : dsn_host
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
use ieee.std_logic_unsigned.all;

library unisim;
use unisim.vcomponents.all;
use work.prj_cfg.all;
use work.prj_def.all;
use work.vicg_common_pkg.all;

entity dsn_host is
generic(
G_DBG      : string:="OFF";
G_SIM_HOST : string:="OFF";
G_SIM_PCIE : std_logic:='0'
);
port(
--------------------------------------------------
-- Связь с хостом по Local bus
--------------------------------------------------
lad                 : inout std_logic_vector(31 downto 0);
lbe_l               : in    std_logic_vector(32/8-1 downto 0);
lads_l              : in    std_logic;
lwrite              : in    std_logic;
lblast_l            : in    std_logic;
lbterm_l            : inout std_logic;
lready_l            : inout std_logic;
fholda              : in    std_logic;
finto_l             : out   std_logic;
lclk                : in    std_logic;

--//-----------------------------
--// PCI-Express
--//-----------------------------
p_out_pciexp_txp    : out   std_logic_vector(C_PCIEXPRESS_LINK_WIDTH-1 downto 0);
p_out_pciexp_txn    : out   std_logic_vector(C_PCIEXPRESS_LINK_WIDTH-1 downto 0);
p_in_pciexp_rxp     : in    std_logic_vector(C_PCIEXPRESS_LINK_WIDTH-1 downto 0);
p_in_pciexp_rxn     : in    std_logic_vector(C_PCIEXPRESS_LINK_WIDTH-1 downto 0);

p_in_pciexp_gt_clkin   : in    std_logic;
p_out_pciexp_gt_clkout : out   std_logic;

--//-----------------------------------------------------
--//Пользовательский порт
--//-----------------------------------------------------
p_in_usr_tst     : in    std_logic_vector(127 downto 0);
p_out_usr_tst    : out   std_logic_vector(127 downto 0);

p_out_hclk       : out   std_logic;
p_out_gctrl      : out   std_logic_vector(31 downto 0);

p_out_dev_ctrl   : out   std_logic_vector(31 downto 0);
p_out_dev_din    : out   std_logic_vector(31 downto 0);
p_in_dev_dout    : in    std_logic_vector(31 downto 0);
p_out_dev_wr     : out   std_logic;
p_out_dev_rd     : out   std_logic;
p_in_dev_status  : in    std_logic_vector(31 downto 0);
p_in_dev_irq     : in    std_logic_vector(31 downto 0);
p_in_dev_opt     : in    std_logic_vector(127 downto 0);
p_out_dev_opt    : out   std_logic_vector(127 downto 0);

--------------------------------------------------
--// Технологический
--------------------------------------------------
p_in_tst         : in    std_logic_vector(31 downto 0);
p_out_tst        : out   std_logic_vector(171 downto 0);

--------------------------------------------------
--System
--------------------------------------------------
p_out_module_rdy : out   std_logic;
p_in_rst_n       : in    std_logic
);
end dsn_host;

architecture behavioral of dsn_host is

constant C_MEMCTRL_CFG_MODE_REG_COUNT  : integer:=3;--//32 bit
constant C_MEMCTRL_ADDR_WIDTH  : natural :=32;
constant C_MEMCTRL_DATA_WIDTH  : natural :=32;

component lbus_connector_32bit_tst
generic(
la_top : in    natural
);
port(
--------------------------------------------------
-- Связь с хостом по Local bus
--------------------------------------------------
lad      : inout std_logic_vector(31 downto 0);
lbe_l    : in    std_logic_vector(32/8-1 downto 0);
lads_l   : in    std_logic;
lwrite   : in    std_logic;
lblast_l : in    std_logic;
lbterm_l : inout std_logic;
lready_l : inout std_logic;
fholda   : in    std_logic;
finto_l  : out   std_logic;

--------------------------------------------------
--System
--------------------------------------------------
clk        : in    std_logic;
p_in_rst_n : in    std_logic
);
end component;

component lbus_connector_32bit
generic(
-- Bit of local bus address that is used to decode FPGA space
la_top : in    natural
);
port(
--------------------------------------------------
-- Связь с хостом по Local bus
--------------------------------------------------
lad              : inout std_logic_vector(31 downto 0);
lbe_l            : in    std_logic_vector(32/8-1 downto 0);
lads_l           : in    std_logic;
lwrite           : in    std_logic;
lblast_l         : in    std_logic;
lbterm_l         : inout std_logic;
lready_l         : inout std_logic;
fholda           : in    std_logic;
finto_l          : out   std_logic;

--------------------------------------------------
--Связь с уст-вами проекта Veresk-M
--------------------------------------------------
p_out_hclk       : out   std_logic;
p_out_gctrl      : out   std_logic_vector(31 downto 0);

p_out_dev_ctrl   : out   std_logic_vector(31 downto 0);
p_in_dev_status  : in    std_logic_vector(31 downto 0);
p_out_dev_din    : out   std_logic_vector(31 downto 0);
p_in_dev_dout    : in    std_logic_vector(31 downto 0);
p_out_dev_wr     : out   std_logic;
p_out_dev_rd     : out   std_logic;

p_out_dev_eof    : out   std_logic;

p_in_tst_in      : in    std_logic_vector(127 downto 0);

p_out_mem_bank1h : out   std_logic_vector(15 downto 0);
p_out_mem_ce     : out   std_logic;
p_out_mem_cw     : out   std_logic;
p_out_mem_rd     : out   std_logic;
p_out_mem_wr     : out   std_logic;
p_out_mem_term   : out   std_logic;
p_out_mem_adr    : out   std_logic_vector(C_MEMCTRL_ADDR_WIDTH - 1 downto 0);
p_out_mem_be     : out   std_logic_vector(C_MEMCTRL_DATA_WIDTH / 8 - 1 downto 0);
p_out_mem_din    : out   std_logic_vector(C_MEMCTRL_DATA_WIDTH - 1 downto 0);
p_in_mem_dout    : in    std_logic_vector(C_MEMCTRL_DATA_WIDTH - 1 downto 0);

p_in_mem_wf      : in    std_logic;
p_in_mem_wpf     : in    std_logic;
p_in_mem_re      : in    std_logic;
p_in_mem_rpe     : in    std_logic;

scl_i            : in    std_logic;
scl_o            : out   std_logic;
sda_i            : in    std_logic;
sda_o            : out   std_logic;

--------------------------------------------------
--System
--------------------------------------------------
clk                : in    std_logic;
p_in_rst_n         : in    std_logic
);
end component;

component pcie_main
port(
--//-------------------------------------------------------
--// User Port
--//-------------------------------------------------------
p_out_usr_tst        : out   std_logic_vector(127 downto 0);
p_in_usr_tst         : in    std_logic_vector(127 downto 0);

p_out_hclk           : out   std_logic;
p_out_gctrl          : out   std_logic_vector(31 downto 0);

p_out_dev_ctrl       : out   std_logic_vector(31 downto 0);
p_out_dev_din        : out   std_logic_vector(31 downto 0);
p_in_dev_dout        : in    std_logic_vector(31 downto 0);
p_out_dev_wr         : out   std_logic;
p_out_dev_rd         : out   std_logic;
p_in_dev_status      : in    std_logic_vector(31 downto 0);
p_in_dev_irq         : in    std_logic_vector(31 downto 0);
p_in_dev_opt         : in    std_logic_vector(127 downto 0);
p_out_dev_opt        : out   std_logic_vector(127 downto 0);

--//-------------------------------------------------------
--// Технологический
--//-------------------------------------------------------
p_in_tst             : in    std_logic_vector(31 downto 0);
p_out_tst            : out   std_logic_vector(171 downto 0);

--//-------------------------------------------------------
--// System Port
--//-------------------------------------------------------
p_in_fast_simulation : in    std_logic;

p_out_pciexp_txp     : out   std_logic_vector(C_PCIEXPRESS_LINK_WIDTH-1 downto 0);
p_out_pciexp_txn     : out   std_logic_vector(C_PCIEXPRESS_LINK_WIDTH-1 downto 0);
p_in_pciexp_rxp      : in    std_logic_vector(C_PCIEXPRESS_LINK_WIDTH-1 downto 0);
p_in_pciexp_rxn      : in    std_logic_vector(C_PCIEXPRESS_LINK_WIDTH-1 downto 0);

p_in_pciexp_rst      : in    std_logic;

p_out_module_rdy     : out   std_logic;
p_in_gtp_refclkin    : in    std_logic;
p_out_gtp_refclkout  : out   std_logic
);
end component;

signal scl                         : std_logic;
signal sda                         : std_logic;

--MAIN
begin


--//###################################################
--//Рабочий вариант
--//###################################################
gen_sim_off : if strcmp(G_SIM_HOST,"OFF") generate

m_pcie : pcie_main
port map(
--//-------------------------------------------------------
--// User Port
--//-------------------------------------------------------
p_out_usr_tst        => p_out_usr_tst,
p_in_usr_tst         => p_in_usr_tst,

p_out_hclk           => p_out_hclk,
p_out_gctrl          => p_out_gctrl,

p_out_dev_ctrl       => p_out_dev_ctrl,
p_out_dev_din        => p_out_dev_din,
p_in_dev_dout        => p_in_dev_dout,
p_out_dev_wr         => p_out_dev_wr,
p_out_dev_rd         => p_out_dev_rd,
p_in_dev_status      => p_in_dev_status,
p_in_dev_irq         => p_in_dev_irq,
p_in_dev_opt         => p_in_dev_opt,
p_out_dev_opt        => p_out_dev_opt,

--//-------------------------------------------------------
--// Технологический
--//-------------------------------------------------------
p_in_tst             => p_in_tst,
p_out_tst            => p_out_tst,

--//-------------------------------------------------------
--// System Port
--//-------------------------------------------------------
p_in_fast_simulation => G_SIM_PCIE,

p_out_pciexp_txp     => p_out_pciexp_txp,
p_out_pciexp_txn     => p_out_pciexp_txn,
p_in_pciexp_rxp      => p_in_pciexp_rxp,
p_in_pciexp_rxn      => p_in_pciexp_rxn,

p_in_pciexp_rst      => p_in_rst_n,

p_out_module_rdy     => p_out_module_rdy,
p_in_gtp_refclkin    => p_in_pciexp_gt_clkin,
p_out_gtp_refclkout  => p_out_pciexp_gt_clkout

);

m_lbus : lbus_connector_32bit_tst
generic map(
la_top => 23
)
port map(
--------------------------------------------------
-- Связь с хостом по Local bus
--------------------------------------------------
lad        => lad,
lbe_l      => lbe_l,
lads_l     => lads_l,
lwrite     => lwrite,
lblast_l   => lblast_l,
lbterm_l   => lbterm_l,
lready_l   => lready_l,
fholda     => fholda,
finto_l    => finto_l,

--------------------------------------------------
--System
--------------------------------------------------
clk        => lclk,
p_in_rst_n => p_in_rst_n
);

end generate gen_sim_off;


--//###################################################
--//Вариант для моделирования (Работа через LocalBus)
--//###################################################
gen_sim_on : if strcmp(G_SIM_HOST,"ON") generate

p_out_tst<=(others=>'0');
p_out_usr_tst      <= (others=>'0');
p_out_module_rdy <= not p_in_rst_n;

p_out_pciexp_txp <=p_in_pciexp_rxp;
p_out_pciexp_txn <=p_in_pciexp_rxn;

p_out_pciexp_gt_clkout<=p_in_pciexp_gt_clkin;--lclk;

m_lbus : lbus_connector_32bit
generic map(
la_top => 23
)
port map(
--------------------------------------------------
-- Связь с хостом по Local bus
--------------------------------------------------
lad              => lad,
lbe_l            => lbe_l,
lads_l           => lads_l,
lwrite           => lwrite,
lblast_l         => lblast_l,
lbterm_l         => lbterm_l,
lready_l         => lready_l,
fholda           => fholda,
finto_l          => finto_l,

--------------------------------------------------
--Связь с уст-вами проекта Veresk-M
--------------------------------------------------
p_out_hclk       => p_out_hclk,

p_out_gctrl      => p_out_gctrl,
p_out_dev_ctrl   => p_out_dev_ctrl,
p_in_dev_status  => p_in_dev_status,
p_out_dev_din    => p_out_dev_din,
p_in_dev_dout    => p_in_dev_dout,
p_out_dev_wr     => p_out_dev_wr,
p_out_dev_rd     => p_out_dev_rd,

p_out_dev_eof    => open,

p_in_tst_in      => p_in_usr_tst,

p_out_mem_bank1h => open,
p_out_mem_ce     => open,
p_out_mem_cw     => open,
p_out_mem_rd     => open,
p_out_mem_wr     => open,
p_out_mem_term   => open,
p_out_mem_adr    => open,
p_out_mem_be     => open,
p_out_mem_din    => open,
p_in_mem_dout    => (others=>'0'),

p_in_mem_wf      => '0',
p_in_mem_wpf     => '0',
p_in_mem_re      => '0',
p_in_mem_rpe     => '0',

scl_i            => scl,
scl_o            => scl,
sda_i            => sda,
sda_o            => sda,

--------------------------------------------------
--System
--------------------------------------------------
clk        => lclk,
p_in_rst_n => p_in_rst_n
);

end generate gen_sim_on;



--END MAIN
end behavioral;
