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
use work.vicg_common_pkg.all;
use work.prj_def.all;
use work.prj_cfg.all;

entity dsn_host is
generic(
G_PCIE_LINK_WIDTH : integer:=1;
G_PCIE_RST_SEL    : integer:=1;
G_DBG      : string:="OFF";
G_SIM_HOST : string:="OFF";
G_SIM_PCIE : std_logic:='0'
);
port(
-------------------------------
--PCI-Express
-------------------------------
p_out_pciexp_txp  : out   std_logic_vector(G_PCIE_LINK_WIDTH-1 downto 0);
p_out_pciexp_txn  : out   std_logic_vector(G_PCIE_LINK_WIDTH-1 downto 0);
p_in_pciexp_rxp   : in    std_logic_vector(G_PCIE_LINK_WIDTH-1 downto 0);
p_in_pciexp_rxn   : in    std_logic_vector(G_PCIE_LINK_WIDTH-1 downto 0);

p_in_pciexp_gt_clkin   : in    std_logic;
p_out_pciexp_gt_clkout : out   std_logic;

-------------------------------
--Пользовательский порт
-------------------------------
p_out_hclk        : out   std_logic;
p_out_gctrl       : out   std_logic_vector(C_HREG_CTRL_LAST_BIT downto 0);

--Управление внешними устройствами
p_out_dev_ctrl    : out   std_logic_vector(C_HREG_DEV_CTRL_LAST_BIT downto 0);
p_out_dev_din     : out   std_logic_vector(C_HDEV_DWIDTH-1 downto 0);
p_in_dev_dout     : in    std_logic_vector(C_HDEV_DWIDTH-1 downto 0);
p_out_dev_wr      : out   std_logic;
p_out_dev_rd      : out   std_logic;
p_in_dev_status   : in    std_logic_vector(C_HREG_DEV_STATUS_LAST_BIT downto 0);
p_in_dev_irq      : in    std_logic_vector(C_HIRQ_COUNT_MAX-1 downto 0);
p_in_dev_opt      : in    std_logic_vector(C_HDEV_OPTIN_LAST_BIT downto 0);
p_out_dev_opt     : out   std_logic_vector(C_HDEV_OPTOUT_LAST_BIT downto 0);

p_out_usr_tst     : out   std_logic_vector(127 downto 0);
p_in_usr_tst      : in    std_logic_vector(127 downto 0);

-------------------------------
--Технологический
-------------------------------
p_in_tst          : in    std_logic_vector(31 downto 0);
p_out_tst         : out   std_logic_vector(255 downto 0);

-------------------------------
--System
-------------------------------
p_out_module_rdy  : out   std_logic;
p_in_rst_n        : in    std_logic
);
end dsn_host;

architecture behavioral of dsn_host is

component pcie_main
generic(
G_PCIE_LINK_WIDTH : integer:=1;
G_PCIE_RST_SEL    : integer:=1;
G_DBG : string:="OFF"
);
port(
--//-------------------------------------------------------
--// User Port
--//-------------------------------------------------------
p_out_hclk        : out   std_logic;
p_out_gctrl       : out   std_logic_vector(C_HREG_CTRL_LAST_BIT downto 0);

--Управление внешними устройствами
p_out_dev_ctrl    : out   std_logic_vector(C_HREG_DEV_CTRL_LAST_BIT downto 0);
p_out_dev_din     : out   std_logic_vector(C_HDEV_DWIDTH-1 downto 0);
p_in_dev_dout     : in    std_logic_vector(C_HDEV_DWIDTH-1 downto 0);
p_out_dev_wr      : out   std_logic;
p_out_dev_rd      : out   std_logic;
p_in_dev_status   : in    std_logic_vector(C_HREG_DEV_STATUS_LAST_BIT downto 0);
p_in_dev_irq      : in    std_logic_vector(C_HIRQ_COUNT_MAX-1 downto 0);
p_in_dev_opt      : in    std_logic_vector(C_HDEV_OPTIN_LAST_BIT downto 0);
p_out_dev_opt     : out   std_logic_vector(C_HDEV_OPTOUT_LAST_BIT downto 0);

p_out_usr_tst     : out   std_logic_vector(127 downto 0);
p_in_usr_tst      : in    std_logic_vector(127 downto 0);

--//-------------------------------------------------------
--// Технологический
--//-------------------------------------------------------
p_in_tst             : in    std_logic_vector(31 downto 0);
p_out_tst            : out   std_logic_vector(255 downto 0);

--//-------------------------------------------------------
--// System Port
--//-------------------------------------------------------
p_in_fast_simulation : in    std_logic;

p_out_pciexp_txp     : out   std_logic_vector(G_PCIE_LINK_WIDTH-1 downto 0);
p_out_pciexp_txn     : out   std_logic_vector(G_PCIE_LINK_WIDTH-1 downto 0);
p_in_pciexp_rxp      : in    std_logic_vector(G_PCIE_LINK_WIDTH-1 downto 0);
p_in_pciexp_rxn      : in    std_logic_vector(G_PCIE_LINK_WIDTH-1 downto 0);

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

gen_sim_off : if strcmp(G_SIM_HOST,"OFF") generate

m_pcie : pcie_main
generic map(
G_PCIE_LINK_WIDTH => G_PCIE_LINK_WIDTH,
G_PCIE_RST_SEL    => G_PCIE_RST_SEL,
G_DBG => G_DBG
)
port map(
--//-------------------------------------------------------
--// User Port
--//-------------------------------------------------------
p_out_hclk      => p_out_hclk     ,
p_out_gctrl     => p_out_gctrl    ,

--Управление внешними устройствами
p_out_dev_ctrl  => p_out_dev_ctrl ,
p_out_dev_din   => p_out_dev_din  ,
p_in_dev_dout   => p_in_dev_dout  ,
p_out_dev_wr    => p_out_dev_wr   ,
p_out_dev_rd    => p_out_dev_rd   ,
p_in_dev_status => p_in_dev_status,
p_in_dev_irq    => p_in_dev_irq   ,
p_in_dev_opt    => p_in_dev_opt   ,
p_out_dev_opt   => p_out_dev_opt  ,

p_out_usr_tst   => p_out_usr_tst  ,
p_in_usr_tst    => p_in_usr_tst   ,

--//-------------------------------------------------------
--// Технологический
--//-------------------------------------------------------
p_in_tst        => p_in_tst,
p_out_tst       => p_out_tst,

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

end generate gen_sim_off;


--END MAIN
end behavioral;
