
library unisim;
use unisim.vcomponents.all;

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

library work;
use work.eth_pkg.all;

-------------------------------------------------------------------------------
-- Entity declaration for the example design
-------------------------------------------------------------------------------

entity ethg_fiber_core is
  generic (
  G_ETH : TEthGeneric
  );
   port(
      --EthPhy<->EthApp
      p_out_phy2app : out   TEthPhy2AppOUTs;
      p_in_phy2app  : in    TEthPhy2AppINs;

      --EthPHY
      p_out_phy     : out   TEthPhyOUT;
      p_in_phy      : in    TEthPhyIN;

      --Технологический
      p_out_dbg     : out   TEthPhyDBGs;
      p_in_tst      : in    std_logic_vector(31 downto 0);
      p_out_tst     : out   std_logic_vector(31 downto 0);

      --System
      p_in_rst      : in    std_logic
   );

end ethg_fiber_core;


architecture top_level of ethg_fiber_core is

component ethg_pma
generic(
G_SIM : integer := 0 -- Set to 1 for simulation
);
port(
gt_txoutclk_bufg    : out std_logic;--add vicg
gt_userclk_bufg     : in  std_logic;
gt_userclk2_bufg    : in  std_logic;
gt_resetdone        : out std_logic;
dcm_locked          : in  std_logic;

-- An independent clock source used as the reference clock for an
-- IDELAYCTRL (if present) and for the main GT transceiver reset logic.
-- This example design assumes that this is of frequency 200MHz.
independent_clock    : in std_logic;

-- Tranceiver Interface
gtrefclk_p           : in std_logic;
gtrefclk_n           : in std_logic;
txp                  : out std_logic;
txn                  : out std_logic;
rxp                  : in std_logic;
rxn                  : in std_logic;

-- GMII Interface (client MAC <=> PCS)
gmii_tx_clk          : in std_logic;
gmii_rx_clk          : out std_logic;
gmii_txd             : in std_logic_vector(7 downto 0);
gmii_tx_en           : in std_logic;
gmii_tx_er           : in std_logic;
gmii_rxd             : out std_logic_vector(7 downto 0);
gmii_rx_dv           : out std_logic;
gmii_rx_er           : out std_logic;

-- Management: Alternative to MDIO Interface
configuration_vector : in std_logic_vector(4 downto 0);

-- General IO's
status_vector        : out std_logic_vector(15 downto 0);
reset                : in std_logic;
signal_detect        : in std_logic
);
end component;


component ethg_mac
port (
--FPGA <- ETH
rx_axis_tdata                : out std_logic_vector(7 downto 0);
rx_axis_tvalid               : out std_logic;
rx_axis_tready               : in  std_logic;
rx_axis_tlast                : out std_logic;

--FPGA -> ETH
tx_axis_tdata                : in  std_logic_vector(7 downto 0);
tx_axis_tvalid               : in  std_logic;
tx_axis_tready               : out std_logic;
tx_axis_tlast                : in  std_logic;

-- asynchronous reset
glbl_rst                      : in  std_logic;

-- 200MHz clock input from board
clk_in_p                      : in  std_logic;
clk_in_n                      : in  std_logic;

phy_resetn                    : out std_logic;


-- GMII Interface
gmii_txd                      : out std_logic_vector(7 downto 0);
gmii_tx_en                    : out std_logic;
gmii_tx_er                    : out std_logic;
gmii_tx_clk                   : out std_logic;

gmii_rxd                      : in  std_logic_vector(7 downto 0);
gmii_rx_dv                    : in  std_logic;
gmii_rx_er                    : in  std_logic;
gmii_rx_clk                   : in  std_logic;

gmii_col                      : in  std_logic;
gmii_crs                      : in  std_logic;
mii_tx_clk                    : in  std_logic;


-- Serialised statistics vectors
tx_statistics_s               : out std_logic;
rx_statistics_s               : out std_logic;

-- Serialised Pause interface controls
pause_req_s                   : in  std_logic;

-- Main example design controls
mac_speed                     : in  std_logic_vector(1 downto 0);
update_speed                  : in  std_logic;
config_board                  : in  std_logic;
--serial_command                : in  std_logic;
serial_response               : out std_logic;
gen_tx_data                   : in  std_logic;
chk_tx_data                   : in  std_logic;
reset_error                   : in  std_logic;
frame_error                   : out std_logic;
frame_errorn                  : out std_logic;
activity_flash                : out std_logic;
activity_flashn               : out std_logic

);
end component;

signal g_ref_clk               : std_logic;
signal g_clk62_5M              : std_logic;
signal g_clk125M               : std_logic;

signal i_dcm_clkout            : std_logic_vector(1 downto 0);
signal i_dcm_clkfbout          : std_logic;
signal i_dcm_locked            : std_logic;
signal i_dcm_rst               : std_logic;

signal i_pma_gt_txoutclk_bufg  : std_logic;

signal i_pma_gmii_tx_clk       : std_logic;
signal i_pma_gmii_rx_clk       : std_logic;
signal i_pma_gmii_txd          : std_logic_vector(7 downto 0);
signal i_pma_gmii_tx_en        : std_logic;
signal i_pma_gmii_tx_er        : std_logic;
signal i_pma_gmii_rxd          : std_logic_vector(7 downto 0);
signal i_pma_gmii_rx_dv        : std_logic;
signal i_pma_gmii_rx_er        : std_logic;

signal i_pma_cfg_vector        : std_logic_vector(4 downto 0);
signal i_pma_core_status       : std_logic_vector(15 downto 0);
signal i_pma_resetdone         : std_logic;
signal i_pma_sfp_signal_detect : std_logic;
signal i_pma_sfp_tx_fault      : std_logic;
signal i_pma_sfp_tx_disable    : std_logic;
signal i_pma_core_clk156_out   : std_logic;



begin

p_out_tst(7 downto 0) <= i_pma_core_status(7 downto 0);
--p_out_tst(8) <= i_pma_resetdone;
--p_out_tst(9) <= i_pma_core_clk156_out;

p_out_phy.link <= not p_in_phy.pin.fiber.sfp_sd;
p_out_phy.rdy <= i_pma_resetdone;
p_out_phy.clk <= i_pma_core_clk156_out;
p_out_phy.rst <= p_in_rst;

p_out_phy.pin.fiber.sfp_txdis <= i_pma_sfp_tx_disable;--'1';
i_pma_sfp_signal_detect <= p_in_phy.pin.fiber.sfp_sd;
i_pma_sfp_tx_fault <= p_in_phy.pin.fiber.sfp_txfault;

g_ref_clk <= p_in_phy.opt(C_ETHPHY_OPTIN_REFCLK_IODELAY_BIT);


pause_val <= CONV_STD_LOGIC_VECTOR(16#00#, pause_val'length);
pause_req <= '0';

tx_ifg_delay <= CONV_STD_LOGIC_VECTOR(16#00#, tx_ifg_delay'length);
--tx_configuration_vector <= X"00000016";
--rx_configuration_vector <= X"00000016";




reset <= p_in_rst;
aresetn <= not reset;


--####################################################
--Clocking
--####################################################
-- The GT transceiver provides a 62.5MHz clock to the FPGA fabrix.  This is
-- routed to an MMCM module where it is used to create phase and frequency
-- related 62.5MHz and 125MHz clock sources

-- Reference clock MMCM (CLKFBOUT range 600.00 MHz to 1440.00 MHz)
-- CLKFBOUT = (CLKIN1/DIVCLK_DIVIDE) * CLKFBOUT_MULT_F
-- CLKOUTn  = (CLKIN1/DIVCLK_DIVIDE) * CLKFBOUT_MULT_F/CLKOUTn_DIVIDE
-- CLKFBOUT = (62.5MHz/1) * 16.000       = 1000 MHz
-- CLKOUT0  = (62.5MHz/1) * 16.000/8     = 125 MHz
-- CLKOUT1  = (62.5MHz/1) * 16.000/16    = 62.5 MHz

m_dcm : MMCME2_ADV
generic map
(BANDWIDTH            => "OPTIMIZED",
CLKOUT4_CASCADE      => FALSE,
COMPENSATION         => "ZHOLD",
STARTUP_WAIT         => FALSE,
DIVCLK_DIVIDE        => 1,
CLKFBOUT_MULT_F      => 16.000,
CLKFBOUT_PHASE       => 0.000,
CLKFBOUT_USE_FINE_PS => FALSE,
CLKOUT0_DIVIDE_F     => 8.000,
CLKOUT0_PHASE        => 0.000,
CLKOUT0_DUTY_CYCLE   => 0.5,
CLKOUT0_USE_FINE_PS  => FALSE,
CLKOUT1_DIVIDE       => 16,
CLKOUT1_PHASE        => 0.000,
CLKOUT1_DUTY_CYCLE   => 0.5,
CLKOUT1_USE_FINE_PS  => FALSE,
CLKIN1_PERIOD        => 16.0,
REF_JITTER1          => 0.010)
port map
-- Output clocks
(CLKFBOUT            => i_dcm_clkfbout,
CLKFBOUTB            => open,
CLKOUT0              => i_dcm_clkout(0),
CLKOUT0B             => open,
CLKOUT1              => i_dcm_clkout(1),
CLKOUT1B             => open,
CLKOUT2              => open,
CLKOUT2B             => open,
CLKOUT3              => open,
CLKOUT3B             => open,
CLKOUT4              => open,
CLKOUT5              => open,
CLKOUT6              => open,
-- Input clock control
CLKFBIN              => i_dcm_clkfbout,
CLKIN1               => i_pma_gt_txoutclk_bufg,
CLKIN2               => '0',
-- Tied to always select the primary input clock
CLKINSEL             => '1',
-- Ports for dynamic reconfiguration
DADDR                => (others => '0'),
DCLK                 => '0',
DEN                  => '0',
DI                   => (others => '0'),
DO                   => open,
DRDY                 => open,
DWE                  => '0',
-- Ports for dynamic phase shift
PSCLK                => '0',
PSEN                 => '0',
PSINCDEC             => '0',
PSDONE               => open,
-- Other control and status signals
LOCKED               => i_dcm_locked,
CLKINSTOPPED         => open,
CLKFBSTOPPED         => open,
PWRDWN               => '0',
RST                  => i_dcm_rst
);

i_dcm_rst <= reset or (not i_pma_resetdone);

-- This 62.5MHz clock is placed onto global clock routing and is then used
-- for tranceiver TXUSRCLK/RXUSRCLK.
m_bufg_62_5M: BUFG port map (I => i_dcm_clkout(1), O  => g_clk62_5M);

-- This 125MHz clock is placed onto global clock routing and is then used
-- to clock all Ethernet core logic.
m_bufg_125M : BUFG port map (I => i_dcm_clkout(0), O  => g_clk125M);



--####################################################
--MAC CORE
--####################################################
m_mac : ethg_mac
port map(
--FPGA <- ETH
rx_axis_tdata   => p_out_phy2app(0).axirx_tdata(7 downto 0), --: out std_logic_vector(7 downto 0);
rx_axis_tvalid  => p_out_phy2app(0).axirx_tvalid,            --: out std_logic;
rx_axis_tready  => p_in_phy2app(0).axirx_tready ,            --: in  std_logic;
rx_axis_tlast   => p_out_phy2app(0).axirx_tlast ,            --: out std_logic;

--FPGA -> ETH
tx_axis_tdata   => p_in_phy2app(0).axitx_tdata(7 downto 0), --: in  std_logic_vector(7 downto 0);
tx_axis_tvalid  => p_in_phy2app(0).axitx_tvalid ,           --: in  std_logic;
tx_axis_tready  => p_out_phy2app(0).axitx_tready,           --: out std_logic;
tx_axis_tlast   => p_in_phy2app(0).axitx_tlast  ,           --: in  std_logic;


-- asynchronous reset
glbl_rst                      : in  std_logic;

-- 200MHz clock input from board
clk_in_p                      : in  std_logic;
clk_in_n                      : in  std_logic;

phy_resetn                    : out std_logic;

-- GMII Interface
gmii_txd                      => i_pma_gmii_txd    , --: out std_logic_vector(7 downto 0);
gmii_tx_en                    => i_pma_gmii_tx_en  , --: out std_logic;
gmii_tx_er                    => i_pma_gmii_tx_er  , --: out std_logic;
gmii_tx_clk                   => i_pma_gmii_tx_clk , --: out std_logic;
gmii_rxd                      => i_pma_gmii_rxd    , --: in  std_logic_vector(7 downto 0);
gmii_rx_dv                    => i_pma_gmii_rx_dv  , --: in  std_logic;
gmii_rx_er                    => i_pma_gmii_rx_er  , --: in  std_logic;
gmii_rx_clk                   => i_pma_gmii_rx_clk , --: in  std_logic;
gmii_col                      => '0',--: in  std_logic;
gmii_crs                      => '0',--: in  std_logic;
mii_tx_clk                    => i_pma_gmii_rx_clk ,--: in  std_logic;

-- Serialised statistics vectors
tx_statistics_s               => open,--: out std_logic;
rx_statistics_s               => open,--: out std_logic;

-- Serialised Pause interface controls
pause_req_s                   => '0',--: in  std_logic;

-- Main example design controls
mac_speed                     : in  std_logic_vector(1 downto 0);
update_speed                  : in  std_logic;
config_board                  : in  std_logic;
--serial_command                : in  std_logic;
serial_response               : out std_logic;
gen_tx_data                   : in  std_logic;
chk_tx_data                   : in  std_logic;
reset_error                   : in  std_logic;
frame_error                   : out std_logic;
frame_errorn                  : out std_logic;
activity_flash                : out std_logic;
activity_flashn               : out std_logic
);



--####################################################
--PMA CORE
--####################################################
i_pma_cfg_vector(0) <= '0';--0/1 - Normal operation / Enable Transmit irrespective of state of RX (802.3ah)/
i_pma_cfg_vector(1) <= '0';--Loopback Control
i_pma_cfg_vector(2) <= '0';--Power Down
i_pma_cfg_vector(3) <= '0';--Isolate
i_pma_cfg_vector(4) <= '0';--Auto-Negotiation Enable

pma : ethg_pma
generic(
G_SIM => '0'
)
port map(
gt_txoutclk_bufg    => i_pma_gt_txoutclk_bufg,
gt_userclk_bufg     => g_clk62_5M,
gt_userclk2_bufg    => g_clk125M,
gt_resetdone        => i_pma_resetdone,
dcm_locked          => i_dcm_locked,

-- An independent clock source used as the reference clock for an
-- IDELAYCTRL (if present) and for the main GT transceiver reset logic.
-- This example design assumes that this is of frequency 200MHz.
independent_clock    => g_ref_clk, --: in std_logic;

-- Tranceiver Interface
gtrefclk_p           => p_in_phy.pin.fiber.refclk_p,--125MHz, very high quality
gtrefclk_n           => p_in_phy.pin.fiber.refclk_n,--125MHz, very high quality
txp                  => p_out_phy.pin.fiber.txp(0) ,
txn                  => p_out_phy.pin.fiber.txn(0) ,
rxp                  => p_in_phy.pin.fiber.rxp(0)  ,
rxn                  => p_in_phy.pin.fiber.rxn(0)  ,

-- GMII Interface (client MAC <=> PCS)
gmii_tx_clk          => i_pma_gmii_tx_clk, --: in std_logic;
gmii_txd             => i_pma_gmii_txd   , --: in std_logic_vector(7 downto 0);
gmii_tx_en           => i_pma_gmii_tx_en , --: in std_logic;
gmii_tx_er           => i_pma_gmii_tx_er , --: in std_logic;

gmii_rx_clk          => i_pma_gmii_rx_clk, --: out std_logic;
gmii_rxd             => i_pma_gmii_rxd   , --: out std_logic_vector(7 downto 0);
gmii_rx_dv           => i_pma_gmii_rx_dv , --: out std_logic;
gmii_rx_er           => i_pma_gmii_rx_er , --: out std_logic;

-- Management: Alternative to MDIO Interface
configuration_vector => i_pma_cfg_vector,       --: in std_logic_vector(4 downto 0);

-- General IO's
status_vector        => i_pma_core_status,      --: out std_logic_vector(15 downto 0); -- Core status.
reset                => reset            ,      --: in std_logic;                     -- Asynchronous reset for entire core.
signal_detect        => i_pma_sfp_signal_detect --: in std_logic                      -- Input from PMD to indicate presence of optical input.
);


end top_level;
