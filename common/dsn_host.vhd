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

lclk_locked         : in    std_logic;--//Status
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
p_in_usr_tst        : in    std_logic_vector(127 downto 0);
p_out_usr_tst       : out   std_logic_vector(127 downto 0);

p_out_hclk          : out   std_logic;
p_out_gctrl         : out   std_logic_vector(31 downto 0);

p_out_dev_ctrl      : out   std_logic_vector(31 downto 0);
p_out_dev_din       : out   std_logic_vector(31 downto 0);
p_in_dev_dout       : in    std_logic_vector(31 downto 0);
p_out_dev_wd        : out   std_logic;
p_out_dev_rd        : out   std_logic;
p_in_dev_flag       : in    std_logic_vector(7 downto 0);
p_in_dev_status     : in    std_logic_vector(31 downto 0);
p_in_dev_irq        : in    std_logic_vector(31 downto 0);
p_in_dev_option     : in    std_logic_vector(127 downto 0);

----//связь с модулем memory_ctrl.vhd
--p_out_mem_ctl_reg   : out   std_logic_vector(0 downto 0);
--p_out_mem_mode_reg  : out   std_logic_vector(511 downto 0);
--p_in_mem_locked     : in    std_logic_vector(7 downto 0);
--p_in_mem_trained    : in    std_logic_vector(15 downto 0);

p_out_mem_bank1h    : out   std_logic_vector(15 downto 0);
p_out_mem_ce        : out   std_logic;
p_out_mem_cw        : out   std_logic;
p_out_mem_rd        : out   std_logic;
p_out_mem_wr        : out   std_logic;
p_out_mem_term      : out   std_logic;
p_out_mem_adr       : out   std_logic_vector(32 - 1 downto 0);
p_out_mem_be        : out   std_logic_vector(32/8 - 1 downto 0);
p_out_mem_din       : out   std_logic_vector(32 - 1 downto 0);
p_in_mem_dout       : in    std_logic_vector(32 - 1 downto 0);

p_in_mem_wf         : in    std_logic;
p_in_mem_wpf        : in    std_logic;
p_in_mem_re         : in    std_logic;
p_in_mem_rpe        : in    std_logic;

--------------------------------------------------
--// Технологический
--------------------------------------------------
p_in_tst            : in    std_logic_vector(31 downto 0);
p_out_tst           : out   std_logic_vector(171 downto 0);

--------------------------------------------------
--System
--------------------------------------------------
p_out_module_rdy    : out   std_logic;
p_in_rst_n          : in    std_logic
);
end dsn_host;

architecture behavioral of dsn_host is

constant C_MEMCTRL_CFG_MODE_REG_COUNT  : integer:=3;--//32 bit
constant C_MEMCTRL_ADDR_WIDTH  : natural :=32;
constant C_MEMCTRL_DATA_WIDTH  : natural :=32;

component lbus_connector_32bit_tst
generic(
-- Bit of local bus address that is used to decode FPGA space
la_top : in    natural
);
port(
--------------------------------------------------
-- Связь с хостом по Local bus
--------------------------------------------------
lad        : inout std_logic_vector(31 downto 0);--(31 downto 0);
lbe_l      : in    std_logic_vector(32/8-1 downto 0);--(3 downto 0);
lads_l     : in    std_logic;
lwrite     : in    std_logic;
lblast_l   : in    std_logic;
lbterm_l   : inout std_logic;
lready_l   : inout std_logic;
fholda     : in    std_logic;
finto_l    : out   std_logic;

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
lad                : inout std_logic_vector(31 downto 0);
lbe_l              : in    std_logic_vector(32/8-1 downto 0);
lads_l             : in    std_logic;
lwrite             : in    std_logic;
lblast_l           : in    std_logic;
lbterm_l           : inout std_logic;
lready_l           : inout std_logic;
fholda             : in    std_logic;
finto_l            : out   std_logic;

--------------------------------------------------
--Связь с уст-вами проекта Veresk-M
--------------------------------------------------
p_out_hclk         : out   std_logic;
p_out_gctrl        : out   std_logic_vector(31 downto 0);

p_out_dev_ctrl     : out   std_logic_vector(31 downto 0);
p_in_dev_status    : in    std_logic_vector(31 downto 0);
p_out_dev_din      : out   std_logic_vector(31 downto 0);
p_in_dev_dout      : in    std_logic_vector(31 downto 0);
p_out_dev_wd       : out   std_logic;
p_out_dev_rd       : out   std_logic;

p_out_dev_eof      : out   std_logic;

p_in_tst_in        : in    std_logic_vector(127 downto 0);

----//связь с модулем memory_ctrl.vhd
--p_out_mem_ctl_reg  : out   std_logic_vector(0 downto 0);
--p_out_mem_mode_reg : out   std_logic_vector(511 downto 0);
--p_in_mem_locked    : in    std_logic_vector(7 downto 0);
--p_in_mem_trained   : in    std_logic_vector(15 downto 0);

p_out_mem_bank1h   : out   std_logic_vector(15 downto 0);
p_out_mem_ce       : out   std_logic;
p_out_mem_cw       : out   std_logic;
p_out_mem_rd       : out   std_logic;
p_out_mem_wr       : out   std_logic;
p_out_mem_term     : out   std_logic;
p_out_mem_adr      : out   std_logic_vector(C_MEMCTRL_ADDR_WIDTH - 1 downto 0);
p_out_mem_be       : out   std_logic_vector(C_MEMCTRL_DATA_WIDTH / 8 - 1 downto 0);
p_out_mem_din      : out   std_logic_vector(C_MEMCTRL_DATA_WIDTH - 1 downto 0);
p_in_mem_dout      : in    std_logic_vector(C_MEMCTRL_DATA_WIDTH - 1 downto 0);

p_in_mem_wf        : in    std_logic;
p_in_mem_wpf       : in    std_logic;
p_in_mem_re        : in    std_logic;
p_in_mem_rpe       : in    std_logic;

scl_i              : in    std_logic;
scl_o              : out   std_logic;
sda_i              : in    std_logic;
sda_o              : out   std_logic;

--------------------------------------------------
--System
--------------------------------------------------
clk_locked         : in    std_logic;--//Status
clk                : in    std_logic;
p_in_rst_n         : in    std_logic
);
end component;

component pciexp_main
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
p_out_dev_wd         : out   std_logic;
p_out_dev_rd         : out   std_logic;
p_in_dev_flag        : in    std_logic_vector(7 downto 0);
p_in_dev_status      : in    std_logic_vector(31 downto 0);
p_in_dev_irq         : in    std_logic_vector(31 downto 0);
p_in_dev_option      : in    std_logic_vector(127 downto 0);

--p_out_mem_ctl_reg    : out   std_logic_vector(0 downto 0);
--p_out_mem_mode_reg   : out   std_logic_vector(511 downto 0);
--p_in_mem_locked      : in    std_logic_vector(7 downto 0);
--p_in_mem_trained     : in    std_logic_vector(15 downto 0);

p_out_mem_bank1h     : out   std_logic_vector(15 downto 0);
p_out_mem_adr        : out   std_logic_vector(34 downto 0);
p_out_mem_ce         : out   std_logic;
p_out_mem_cw         : out   std_logic;
p_out_mem_rd         : out   std_logic;
p_out_mem_wr         : out   std_logic;
p_out_mem_be         : out   std_logic_vector(7 downto 0);
p_out_mem_term       : out   std_logic;
p_out_mem_din        : out   std_logic_vector(31 downto 0);
p_in_mem_dout        : in    std_logic_vector(31 downto 0);

p_in_mem_wf          : in    std_logic;
p_in_mem_wpf         : in    std_logic;
p_in_mem_re          : in    std_logic;
p_in_mem_rpe         : in    std_logic;

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

signal i_lbus_mem_ctl_reg          : std_logic_vector(0 downto 0);
signal i_lbus_mem_mode_reg         : std_logic_vector(511 downto 0);

signal i_lbus_hclk_out             : std_logic;

signal i_lbus_gctrl                : std_logic_vector(31 downto 0);
signal i_lbus_dev_ctrl             : std_logic_vector(31 downto 0);
signal i_lbus_dev_din              : std_logic_vector(31 downto 0);
signal i_lbus_dev_wd               : std_logic;
signal i_lbus_dev_rd               : std_logic;

signal i_lbus_mem_bank1h           : std_logic_vector(15 downto 0);
signal i_lbus_mem_ce               : std_logic;
signal i_lbus_mem_cw               : std_logic;
signal i_lbus_mem_rd               : std_logic;
signal i_lbus_mem_wr               : std_logic;
signal i_lbus_mem_term             : std_logic;
signal i_lbus_mem_adr              : std_logic_vector(C_MEMCTRL_ADDR_WIDTH - 1 downto 0);
signal i_lbus_mem_be               : std_logic_vector(C_MEMCTRL_DATA_WIDTH / 8 - 1 downto 0);
signal i_lbus_mem_din              : std_logic_vector(C_MEMCTRL_DATA_WIDTH - 1 downto 0);

signal i_pciexp_hclk_out           : std_logic;
signal i_pciexp_out_usr_tst        : std_logic_vector(127 downto 0);

signal i_pciexp_gctrl              : std_logic_vector(31 downto 0);
signal i_pciexp_dev_ctrl           : std_logic_vector(31 downto 0);
signal i_pciexp_dev_din            : std_logic_vector(31 downto 0);
signal i_pciexp_dev_wd             : std_logic;
signal i_pciexp_dev_rd             : std_logic;

signal i_pciexp_mem_ctl_reg        : std_logic_vector(0 downto 0);
signal i_pciexp_mem_mode_reg       : std_logic_vector(511 downto 0);

signal i_pciexp_mem_bank1h         : std_logic_vector(15 downto 0);
signal i_pciexp_mem_adr            : std_logic_vector(34 downto 0);
signal i_pciexp_mem_ce             : std_logic;
signal i_pciexp_mem_cw             : std_logic;
signal i_pciexp_mem_rd             : std_logic;
signal i_pciexp_mem_wr             : std_logic;
signal i_pciexp_mem_be             : std_logic_vector(7 downto 0);
signal i_pciexp_mem_term           : std_logic;
signal i_pciexp_mem_din            : std_logic_vector(31 downto 0);

signal scl                         : std_logic;
signal sda                         : std_logic;

--MAIN
begin


--//---------------------------------------------------
--//Рабочий вариант (Только PCI-Express)
--//---------------------------------------------------
gen_sim_off : if strcmp(G_SIM_HOST,"OFF") generate

p_out_usr_tst<= i_pciexp_out_usr_tst;
p_out_gctrl  <= i_pciexp_gctrl;

----//связь с модулем memory_ctrl.vhd
--p_out_mem_ctl_reg<= i_pciexp_mem_ctl_reg;
--gen_mem_mode : for i in 0 to C_MEMCTRL_CFG_MODE_REG_COUNT-1 generate
--  p_out_mem_mode_reg((32* (i + 1)) - 23 downto  32* i)<=i_pciexp_mem_mode_reg(10* (i + 1) - 1 downto 10 * i);
--end generate gen_mem_mode;
--p_out_mem_mode_reg(511 downto (C_MEMCTRL_CFG_MODE_REG_COUNT*32))<=(others=>'0');

p_out_mem_bank1h <= i_pciexp_mem_bank1h;
p_out_mem_adr    <= i_pciexp_mem_adr(C_MEMCTRL_ADDR_WIDTH - 1 downto 0);
p_out_mem_ce     <= i_pciexp_mem_ce;
p_out_mem_cw     <= i_pciexp_mem_cw;
p_out_mem_rd     <= i_pciexp_mem_rd;
p_out_mem_wr     <= i_pciexp_mem_wr;
p_out_mem_be     <= i_pciexp_mem_be(C_MEMCTRL_DATA_WIDTH/8 - 1 downto 0);
p_out_mem_term   <= i_pciexp_mem_term;
p_out_mem_din    <= i_pciexp_mem_din(31 downto 0);

--//связь с другими модулями
p_out_dev_ctrl   <= i_pciexp_dev_ctrl;
p_out_dev_din    <= i_pciexp_dev_din;
p_out_dev_wd     <= i_pciexp_dev_wd;
p_out_dev_rd     <= i_pciexp_dev_rd;


--//-------------------------------------------------------
--//Проект PCI-EXPRESS
--//-------------------------------------------------------
m_pciexp : pciexp_main
port map(
--//-------------------------------------------------------
--// User Port
--//-------------------------------------------------------
p_out_usr_tst        => i_pciexp_out_usr_tst,
p_in_usr_tst         => p_in_usr_tst,

p_out_hclk           => p_out_hclk,
p_out_gctrl          => i_pciexp_gctrl,

p_out_dev_ctrl       => i_pciexp_dev_ctrl,
p_out_dev_din        => i_pciexp_dev_din,
p_in_dev_dout        => p_in_dev_dout,
p_out_dev_wd         => i_pciexp_dev_wd,
p_out_dev_rd         => i_pciexp_dev_rd,
p_in_dev_flag        => p_in_dev_flag,
p_in_dev_status      => p_in_dev_status,
p_in_dev_irq         => p_in_dev_irq,
p_in_dev_option      => p_in_dev_option,

--p_out_mem_ctl_reg    => i_pciexp_mem_ctl_reg,
--p_out_mem_mode_reg   => i_pciexp_mem_mode_reg,
--p_in_mem_locked      => p_in_mem_locked,
--p_in_mem_trained     => p_in_mem_trained,

p_out_mem_bank1h     => i_pciexp_mem_bank1h,
p_out_mem_adr        => i_pciexp_mem_adr,
p_out_mem_ce         => i_pciexp_mem_ce,
p_out_mem_cw         => i_pciexp_mem_cw,
p_out_mem_rd         => i_pciexp_mem_rd,
p_out_mem_wr         => i_pciexp_mem_wr,
p_out_mem_be         => i_pciexp_mem_be,
p_out_mem_term       => i_pciexp_mem_term,
p_out_mem_din        => i_pciexp_mem_din,
p_in_mem_dout        => p_in_mem_dout,

p_in_mem_wf          => p_in_mem_wf,
p_in_mem_wpf         => p_in_mem_wpf,
p_in_mem_re          => p_in_mem_re,
p_in_mem_rpe         => p_in_mem_rpe,

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

p_out_module_rdy     => p_out_module_rdy,--open,
p_in_gtp_refclkin    => p_in_pciexp_gt_clkin,
p_out_gtp_refclkout  => p_out_pciexp_gt_clkout

);

m_local_bus_tst : lbus_connector_32bit_tst
generic map(
la_top => 23 --Bit of local bus address that is used to decode FPGA space
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


--//---------------------------------------------------
--//Вариант для моделирования (Моделирование через LocalBus)
--//---------------------------------------------------
gen_sim_on : if strcmp(G_SIM_HOST,"ON") generate

p_out_tst<=(others=>'0');

p_out_module_rdy <= not p_in_rst_n;

p_out_pciexp_txp <=p_in_pciexp_rxp;
p_out_pciexp_txn <=p_in_pciexp_rxn;

i_pciexp_gctrl(0)<='1';
i_pciexp_gctrl(31 downto 1)<=(others=>'0');

p_out_pciexp_gt_clkout<=p_in_pciexp_gt_clkin;--lclk;

p_out_usr_tst      <= (others=>'0');--i_lbus_out_usr_tst;

p_out_gctrl        <= i_lbus_gctrl;

--//связь с модулем memory_ctrl.vhd
--p_out_mem_ctl_reg  <= i_lbus_mem_ctl_reg;
--p_out_mem_mode_reg <= i_lbus_mem_mode_reg;

p_out_mem_bank1h   <= i_lbus_mem_bank1h;
p_out_mem_adr      <= i_lbus_mem_adr(C_MEMCTRL_ADDR_WIDTH - 1 downto 0);
p_out_mem_ce       <= i_lbus_mem_ce;
p_out_mem_cw       <= i_lbus_mem_cw;
p_out_mem_rd       <= i_lbus_mem_rd;
p_out_mem_wr       <= i_lbus_mem_wr;
p_out_mem_be       <= i_lbus_mem_be(C_MEMCTRL_DATA_WIDTH / 8 - 1 downto 0);
p_out_mem_term     <= i_lbus_mem_term;
p_out_mem_din      <= i_lbus_mem_din(31 downto 0);

--//связь с другими модулями
p_out_dev_ctrl     <= i_lbus_dev_ctrl;
p_out_dev_din      <= i_lbus_dev_din;
p_out_dev_wd       <= i_lbus_dev_wd;
p_out_dev_rd       <= i_lbus_dev_rd;

p_out_hclk         <= i_lbus_hclk_out;

-- Связь с хостом по Local bus
m_local_bus : lbus_connector_32bit
generic map(
la_top => 23 --Bit of local bus address that is used to decode FPGA space
)
port map(
--------------------------------------------------
-- Связь с хостом по Local bus
--------------------------------------------------
lad                => lad,
lbe_l              => lbe_l,
lads_l             => lads_l,
lwrite             => lwrite,
lblast_l           => lblast_l,
lbterm_l           => lbterm_l,
lready_l           => lready_l,
fholda             => fholda,
finto_l            => finto_l,

--------------------------------------------------
--Связь с уст-вами проекта Veresk-M
--------------------------------------------------
p_out_hclk         => i_lbus_hclk_out,

p_out_gctrl        => i_lbus_gctrl,
p_out_dev_ctrl     => i_lbus_dev_ctrl,
p_in_dev_status    => p_in_dev_status,
p_out_dev_din      => i_lbus_dev_din,
p_in_dev_dout      => p_in_dev_dout,
p_out_dev_wd       => i_lbus_dev_wd,
p_out_dev_rd       => i_lbus_dev_rd,

p_out_dev_eof      => open,

p_in_tst_in        => p_in_usr_tst,

----//связь с модулем memory_ctrl.vhd
--p_out_mem_ctl_reg  => i_lbus_mem_ctl_reg,
--p_out_mem_mode_reg => i_lbus_mem_mode_reg,
--p_in_mem_locked    => p_in_mem_locked,
--p_in_mem_trained   => p_in_mem_trained,

p_out_mem_bank1h   => i_lbus_mem_bank1h,
p_out_mem_ce       => i_lbus_mem_ce,
p_out_mem_cw       => i_lbus_mem_cw,
p_out_mem_rd       => i_lbus_mem_rd,
p_out_mem_wr       => i_lbus_mem_wr,
p_out_mem_term     => i_lbus_mem_term,
p_out_mem_adr      => i_lbus_mem_adr,
p_out_mem_be       => i_lbus_mem_be,
p_out_mem_din      => i_lbus_mem_din,
p_in_mem_dout      => p_in_mem_dout,

p_in_mem_wf        => p_in_mem_wf,
p_in_mem_wpf       => p_in_mem_wpf,
p_in_mem_re        => p_in_mem_re,
p_in_mem_rpe       => p_in_mem_rpe,

scl_i              => scl,
scl_o              => scl,
sda_i              => sda,
sda_o              => sda,

--------------------------------------------------
--System
--------------------------------------------------
clk_locked => lclk_locked,
clk        => lclk,
p_in_rst_n => p_in_rst_n
);

end generate gen_sim_on;



--END MAIN
end behavioral;
