
library unisim;
use unisim.vcomponents.all;

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

library work;
use work.eth_pkg.all;

library unisim;
use unisim.vcomponents.all;

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
p_in_clk125M                : in std_logic;
p_in_refclk                 : in std_logic;
p_in_dcm_locked             : in std_logic;

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
--pause_req_s                   : in  std_logic;
pause_req                  : in  std_logic;
pause_val                  : in  std_logic_vector(15 downto 0);

-- Main example design controls
mac_speed                     : in  std_logic_vector(1 downto 0);
update_speed                  : in  std_logic;
--config_board                  : in  std_logic;
----serial_command                : in  std_logic;
--serial_response               : out std_logic;
--gen_tx_data                   : in  std_logic;
--chk_tx_data                   : in  std_logic;
reset_error                   : in  std_logic
--frame_error                   : out std_logic;
--frame_errorn                  : out std_logic;
--activity_flash                : out std_logic;
--activity_flashn               : out std_logic

);
end component;

signal i_reset                 : std_logic;

signal g_refclk                : std_logic;
signal g_clk62_5M              : std_logic;
signal g_clk125M               : std_logic;

signal i_dcm_clkout            : std_logic_vector(1 downto 0);
signal i_dcm_clkfbout          : std_logic;
signal i_dcm_locked            : std_logic;
signal i_dcm_rst               : std_logic;

signal i_rx_axis_tdata         : std_logic_vector(7 downto 0);
signal i_rx_axis_tvalid        : std_logic;
signal i_rx_axis_tready        : std_logic;
signal i_rx_axis_tlast         : std_logic;

signal i_tx_axis_tdata         : std_logic_vector(7 downto 0);
signal i_tx_axis_tvalid        : std_logic;
signal i_tx_axis_tready        : std_logic;
signal i_tx_axis_tlast         : std_logic;

signal i_mac_speed             : std_logic_vector(1 downto 0);
signal i_mac_speed_update      : std_logic;
signal i_mac_pause_val         : std_logic_vector(15 downto 0);
signal i_mac_pause_req         : std_logic;

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

p_out_phy.link <= not i_pma_sfp_signal_detect;
p_out_phy.rdy <= i_dcm_locked;
p_out_phy.clk <= g_clk125M;
p_out_phy.rst <= p_in_rst;

p_out_phy.pin.fiber.sfp_txdis <= '0';
i_pma_sfp_signal_detect <= p_in_phy.pin.fiber.sfp_sd;
--i_pma_sfp_tx_fault <= p_in_phy.pin.fiber.sfp_txfault;

g_refclk <= p_in_phy.opt(C_ETHPHY_OPTIN_REFCLK_IODELAY_BIT);

i_reset <= p_in_rst;

--configureatin
--p_out_phy.pin.fiber.sfp_rs <= "00";--Rate select
p_out_phy.pin.fiber.clk_sel <= "01";--0/1/2/3 - 100/125/150/156.25MHz
p_out_phy.pin.fiber.clk_oe <= '0';

i_mac_speed <= CONV_STD_LOGIC_VECTOR(2, i_mac_speed'length);--0/1/2 - 10/100/1000(Mb/s)
i_mac_speed_update <= '0';

i_mac_pause_val <= CONV_STD_LOGIC_VECTOR(16#00#, i_mac_pause_val'length);
i_mac_pause_req <= '0';

i_pma_cfg_vector(0) <= '0';--0/1 - Normal operation / Enable Transmit irrespective of state of RX (802.3ah)/
i_pma_cfg_vector(1) <= '0';--Loopback Control
i_pma_cfg_vector(2) <= '0';--Power Down
i_pma_cfg_vector(3) <= '0';--Isolate
i_pma_cfg_vector(4) <= '0';--Auto-Negotiation Enable



--####################################################
--AXI convertor
--####################################################
--FPGA <- ETH  (p_out_phy2app : out   TEthPhy2AppOUTs;)
--p_out_phy2app(0).axirx_tdata(7 downto 0) <= i_rx_axis_tdata ;
--p_out_phy2app(0).axirx_tvalid            <= i_rx_axis_tvalid;
--p_out_phy2app(0).axirx_tlast             <= i_rx_axis_tlast;
--i_rx_axis_tready <= p_in_phy2app(0).axirx_tready;

p_out_phy2app(0).rxd(7 downto 0) <= i_rx_axis_tdata;      --RX_LL_DATA        : out std_logic_vector(7 downto 0);
p_out_phy2app(0).rxsof_n         <= not i_rx_axis_tvalid; --RX_LL_SOF_N       : out std_logic;
p_out_phy2app(0).rxeof_n         <= not i_rx_axis_tlast;  --RX_LL_EOF_N       : out std_logic;
p_out_phy2app(0).rxsrc_rdy_n     <= not i_rx_axis_tvalid; --RX_LL_SRC_RDY_N   : out std_logic;
p_out_phy2app(0).rxrem           <= (others=>'0');      --RX_LL_REM         : out std_logic;
p_out_phy2app(0).rxbuf_status    <= (others=>'0');      --RX_LL_FIFO_STATUS : out std_logic_vector(3 downto 0);

p_out_phy2app(0).txdst_rdy_n <= not i_tx_axis_tready;    --TX_LL_DST_RDY_N   : out std_logic;


--FPGA -> ETH  (p_in_phy2app  : in    TEthPhy2AppINs;)
--i_tx_axis_tdata  <= p_in_phy2app(0).axitx_tdata(7 downto 0);
--i_tx_axis_tvalid <= p_in_phy2app(0).axitx_tvalid;
--i_tx_axis_tlast  <= p_in_phy2app(0).axitx_tlast;
--p_out_phy2app(0).axitx_tready <= i_tx_axis_tready;

i_rx_axis_tready <= not p_in_phy2app(0).rxdst_rdy_n; --RX_LL_DST_RDY_N : in  std_logic;

i_tx_axis_tdata <= p_in_phy2app(0).txd(7 downto 0);  --TX_LL_DATA
i_tx_axis_tvalid <= not p_in_phy2app(0).txsof_n or not p_in_phy2app(0).txsrc_rdy_n;
i_tx_axis_tlast <= not p_in_phy2app(0).txeof_n;      --TX_LL_EOF_N     : in  std_logic;


--####################################################
--MAC CORE
--####################################################
m_mac : ethg_mac
port map(
p_in_refclk     => g_refclk,
p_in_clk125M    => g_clk125M,
p_in_dcm_locked => i_dcm_locked,

--FPGA <- ETH
rx_axis_tdata   => i_rx_axis_tdata ,--p_out_phy2app(0).axirx_tdata(7 downto 0), --: out std_logic_vector(7 downto 0);
rx_axis_tvalid  => i_rx_axis_tvalid,--p_out_phy2app(0).axirx_tvalid,            --: out std_logic;
rx_axis_tready  => i_rx_axis_tready,--p_in_phy2app(0).axirx_tready ,            --: in  std_logic;
rx_axis_tlast   => i_rx_axis_tlast ,--p_out_phy2app(0).axirx_tlast ,            --: out std_logic;

--FPGA -> ETH
tx_axis_tdata   => i_tx_axis_tdata ,--p_in_phy2app(0).axitx_tdata(7 downto 0), --: in  std_logic_vector(7 downto 0);
tx_axis_tvalid  => i_tx_axis_tvalid,--p_in_phy2app(0).axitx_tvalid ,           --: in  std_logic;
tx_axis_tready  => i_tx_axis_tready,--p_out_phy2app(0).axitx_tready,           --: out std_logic;
tx_axis_tlast   => i_tx_axis_tlast ,--p_in_phy2app(0).axitx_tlast  ,           --: in  std_logic;


-- asynchronous reset
glbl_rst        => i_reset,
phy_resetn      => open,

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
--pause_req_s                   => '0',
pause_req                     => i_mac_pause_req,
pause_val                     => i_mac_pause_val,

-- Main example design controls
mac_speed                     => i_mac_speed,
update_speed                  => i_mac_speed_update,
--config_board                  : in  std_logic;
----serial_command                : in  std_logic;
--serial_response               : out std_logic;
--gen_tx_data                   : in  std_logic;
--chk_tx_data                   : in  std_logic;
reset_error                   => '0'
--frame_error                   : out std_logic;
--frame_errorn                  : out std_logic;
--activity_flash                : out std_logic;
--activity_flashn               : out std_logic
);



--####################################################
--PMA CORE
--####################################################
m_pma : ethg_pma
generic map(
G_SIM => 0
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
independent_clock    => g_refclk, --: in std_logic;

-- Tranceiver Interface
gtrefclk_p           => p_in_phy.pin.fiber.clk_p,--125MHz, very high quality
gtrefclk_n           => p_in_phy.pin.fiber.clk_n,--125MHz, very high quality
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
reset                => i_reset,                --: in std_logic;                     -- Asynchronous reset for entire core.
signal_detect        => i_pma_sfp_signal_detect --: in std_logic                      -- Input from PMD to indicate presence of optical input.
);



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

i_dcm_rst <= i_reset or (not i_pma_resetdone);

-- This 62.5MHz clock is placed onto global clock routing and is then used
-- for tranceiver TXUSRCLK/RXUSRCLK.
m_bufg_62_5M: BUFG port map (I => i_dcm_clkout(1), O  => g_clk62_5M);

-- This 125MHz clock is placed onto global clock routing and is then used
-- to clock all Ethernet core logic.
m_bufg_125M : BUFG port map (I => i_dcm_clkout(0), O  => g_clk125M);


end top_level;
