
library unisim;
use unisim.vcomponents.all;

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_misc.all;

library work;
use work.eth_pkg.all;

library unisim;
use unisim.vcomponents.all;

-------------------------------------------------------------------------------
-- Entity declaration for the example design
-------------------------------------------------------------------------------

entity eth_phy is --entity ethg_fiber_core is
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

end eth_phy;


architecture top_level of eth_phy is

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

-- 200MHz reference clock for the IDELAYCTRL
refclk               : in std_logic;

--------------------------------------------------------------------------
-- Core connected to GTP0
--------------------------------------------------------------------------

-- GMII Interface
-----------------
gmii_tx_clk0         : in std_logic;                     -- Transmit clock from client MAC.
gmii_rx_clk0         : out std_logic;                    -- Receive clock to client MAC.
gmii_txd0            : in std_logic_vector(7 downto 0);  -- Transmit data from client MAC.
gmii_tx_en0          : in std_logic;                     -- Transmit control signal from client MAC.
gmii_tx_er0          : in std_logic;                     -- Transmit control signal from client MAC.
gmii_rxd0            : out std_logic_vector(7 downto 0); -- Received Data to client MAC.
gmii_rx_dv0          : out std_logic;                    -- Received control signal to client MAC.
gmii_rx_er0          : out std_logic;                    -- Received control signal to client MAC.

-- Management: Alternative to MDIO Interface
--------------------------------------------
configuration_vector0: in std_logic_vector(4 downto 0);  -- Alternative to MDIO interface.

-- General IO's
---------------
status_vector0       : out std_logic_vector(15 downto 0); -- Core status.
reset0               : in std_logic;                     -- Asynchronous reset for entire core.
signal_detect0       : in std_logic;                     -- Input from PMD to indicate presence of optical input.


--------------------------------------------------------------------------
-- Tranceiver interfaces
--------------------------------------------------------------------------

brefclk_p            : in std_logic;                     --125MHz, very high quality
brefclk_n            : in std_logic;                     --125MHz, very high quality

txp0                 : out std_logic;
txn0                 : out std_logic;
rxp0                 : in std_logic;
rxn0                 : in std_logic;

txp1                 : out std_logic;
txn1                 : out std_logic;
rxp1                 : in std_logic;
rxn1                 : in std_logic
);
end component;


component ethg_mac
port (
--FPGA <- ETH
--rx_ll_clock          : out std_logic;
rx_ll_data_out       : out std_logic_vector(7 downto 0);
rx_ll_sof_out_n      : out std_logic;
rx_ll_eof_out_n      : out std_logic;
rx_ll_src_rdy_out_n  : out std_logic;
rx_ll_dst_rdy_in_n   : in  std_logic;

--FPGA -> ETH
--tx_ll_clock          : out std_logic;
tx_ll_data_in        : in  std_logic_vector(7 downto 0);
tx_ll_sof_in_n       : in  std_logic;
tx_ll_eof_in_n       : in  std_logic;
tx_ll_src_rdy_in_n   : in  std_logic;
tx_ll_dst_rdy_out_n  : out std_logic;

-- asynchronous reset
reset                : in  std_logic;

-- Reference clock for IDELAYCTRL's
refclk               : in  std_logic;


-- Client Receiver Statistics Interface
---------------------------------------
rx_clk               : out std_logic;
rx_statistics_vector : out std_logic;
--rx_statistics_valid  : out std_logic;

-- Client Transmitter Statistics Interface
------------------------------------------
tx_clk               : out std_logic;
tx_statistics_vector : out std_logic;
--tx_statistics_valid  : out std_logic;

-- MAC Control Interface
------------------------
--pause_req            : in  std_logic;
--pause_val            : in  std_logic;
pause_req                  : in  std_logic;
pause_val                  : in  std_logic_vector(15 downto 0);

-- GMII Interface
-----------------
gtx_clk              : in  std_logic;

gmii_txd             : out std_logic_vector(7 downto 0);
gmii_tx_en           : out std_logic;
gmii_tx_er           : out std_logic;
gmii_tx_clk          : out std_logic;

gmii_rxd             : in  std_logic_vector(7 downto 0);
gmii_rx_dv           : in  std_logic;
gmii_rx_er           : in  std_logic;
gmii_rx_clk          : in  std_logic;

mii_tx_clk           : in  std_logic;

-- Configuration Vector
-----------------------
configuration_vector : in  std_logic_vector(67 downto 0)

);
end component;

signal i_reset                 : std_logic;

signal g_refclk                : std_logic;
signal g_clk62_5M              : std_logic;
signal g_clk125M               : std_logic;

signal i_dcm_clkout            : std_logic_vector(1 downto 0);
signal i_dcm_clkfbout          : std_logic;
signal g_dcm_clkfbout          : std_logic;
signal i_userclk2_bufg         : std_logic;
signal g_userclk2_bufg         : std_logic;
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
signal i_mac_configuration_vector: std_logic_vector(67 downto 0);

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

signal tst_pma_core_status     : std_logic_vector(15 downto 0);


begin

--p_out_tst(0) <= OR_reduce(tst_pma_core_status);

p_out_dbg(0).d <= EXT(tst_pma_core_status, p_out_dbg(0).d'length);
process(g_userclk2_bufg)
begin
  if rising_edge(g_userclk2_bufg) then
    tst_pma_core_status <= i_pma_core_status;
  end if;
end process;

p_out_phy.link <= i_pma_sfp_signal_detect;
p_out_phy.rdy <= i_dcm_locked;
p_out_phy.clk <= g_userclk2_bufg;--g_clk125M;--
p_out_phy.rst <= p_in_rst;

p_out_phy.pin.fiber.sfp_txdis <= '0';
i_pma_sfp_signal_detect <= p_in_phy.pin.fiber.sfp_sd;
--i_pma_sfp_tx_fault <= p_in_phy.pin.fiber.sfp_txfault;

g_refclk <= p_in_phy.opt(C_ETHPHY_OPTIN_REFCLK_IODELAY_BIT);

i_reset <= p_in_rst;

--configureatin
i_mac_configuration_vector(47 downto 0) <= (others=>'0'); --Pause frame MAC Source Address[47:0]

i_mac_configuration_vector(48) <= '0'; --Receiver Half Duplex
i_mac_configuration_vector(49) <= '0'; --Receiver VLAN Enable
i_mac_configuration_vector(50) <= '1'; --Receiver Enable
i_mac_configuration_vector(51) <= '0'; --Receiver In-band FCS Enable
i_mac_configuration_vector(52) <= '1'; --Receiver Jumbo Frame Enable
i_mac_configuration_vector(53) <= '0'; --Receiver Reset

i_mac_configuration_vector(54) <= '0'; --Transmitter Interframe Gap Adjust Enable
i_mac_configuration_vector(55) <= '0'; --Transmitter Half Duplex
i_mac_configuration_vector(56) <= '0'; --Transmitter VLAN Enable
i_mac_configuration_vector(57) <= '1'; --Transmitter Enable
i_mac_configuration_vector(58) <= '0'; --Transmitter In-Band FCS Enable
i_mac_configuration_vector(59) <= '1'; --Transmitter Jumbo Frame Enable
i_mac_configuration_vector(60) <= '0'; --Transmitter Reset

i_mac_configuration_vector(61) <= '0'; --Transmit Flow Control Enable
i_mac_configuration_vector(62) <= '0'; --Receive Flow Control Enable
i_mac_configuration_vector(63) <= '0'; --Length/Type Error Check Disable
i_mac_configuration_vector(64) <= '0'; --Address Filter Enable

i_mac_configuration_vector(66 downto 65)<= "10";--00/01/10 - 10/100/1000 Mb/s

i_mac_configuration_vector(67) <= '1'; --Control Frame Length Check Disable


i_mac_pause_val <= CONV_STD_LOGIC_VECTOR(16#00#, i_mac_pause_val'length);
i_mac_pause_req <= '0';

i_pma_cfg_vector(0) <= '0';--0/1 - Normal operation / Enable Transmit irrespective of state of RX (802.3ah)/
i_pma_cfg_vector(1) <= '0';--Loopback Control
i_pma_cfg_vector(2) <= '0';--Power Down
i_pma_cfg_vector(3) <= '0';--Isolate
i_pma_cfg_vector(4) <= '0';--Auto-Negotiation Enable




--####################################################
--MAC CORE
--####################################################
m_mac : ethg_mac
port map(
--FPGA <- ETH
--rx_ll_clock          => rx_ll_clock        ,
rx_ll_data_out       => p_out_phy2app(0).rxd(G_ETH.phy_dwidth-1 downto 0),--rx_ll_data_0_i,      --: out std_logic_vector(7 downto 0);
rx_ll_sof_out_n      => p_out_phy2app(0).rxsof_n,                         --rx_ll_sof_n_0_i,     --: out std_logic;
rx_ll_eof_out_n      => p_out_phy2app(0).rxeof_n,                         --rx_ll_eof_n_0_i,     --: out std_logic;
rx_ll_src_rdy_out_n  => p_out_phy2app(0).rxsrc_rdy_n,                     --rx_ll_src_rdy_n_0_i, --: out std_logic;
rx_ll_dst_rdy_in_n   => p_in_phy2app (0).rxdst_rdy_n,                     --rx_ll_dst_rdy_n_0_i, --: in  std_logic;

--FPGA -> ETH
--tx_ll_clock          => tx_ll_clock        ,
tx_ll_data_in        => p_in_phy2app (0).txd(G_ETH.phy_dwidth-1 downto 0),--tx_ll_data_0_i,
tx_ll_sof_in_n       => p_in_phy2app (0).txsof_n,                         --tx_ll_sof_n_0_i,
tx_ll_eof_in_n       => p_in_phy2app (0).txeof_n,                         --tx_ll_eof_n_0_i,
tx_ll_src_rdy_in_n   => p_in_phy2app (0).txsrc_rdy_n,                     --tx_ll_src_rdy_n_0_i,
tx_ll_dst_rdy_out_n  => p_out_phy2app(0).txdst_rdy_n,                     --tx_ll_dst_rdy_n_0_i,

-- asynchronous reset
reset                => i_reset,

-- Reference clock for IDELAYCTRL's
refclk               => g_refclk,

-- Client Receiver Statistics Interface
rx_clk               => open,
rx_statistics_vector => open,
--rx_statistics_valid  : out std_logic;

-- Client Transmitter Statistics Interface
tx_clk               => open,
tx_statistics_vector => open,

-- MAC Control Interface
pause_req            => i_mac_pause_req,
pause_val            => i_mac_pause_val,

-- GMII Interface
gtx_clk              => g_userclk2_bufg,--g_clk125M,

gmii_txd             => i_pma_gmii_txd    , --: out std_logic_vector(7 downto 0);
gmii_tx_en           => i_pma_gmii_tx_en  , --: out std_logic;
gmii_tx_er           => i_pma_gmii_tx_er  , --: out std_logic;
gmii_tx_clk          => i_pma_gmii_tx_clk , --: out std_logic;

gmii_rxd             => i_pma_gmii_rxd    , --: in  std_logic_vector(7 downto 0);
gmii_rx_dv           => i_pma_gmii_rx_dv  , --: in  std_logic;
gmii_rx_er           => i_pma_gmii_rx_er  , --: in  std_logic;
gmii_rx_clk          => i_pma_gmii_rx_clk , --: in  std_logic;

mii_tx_clk           => i_pma_gmii_rx_clk ,--: in  std_logic;

-- Configuration Vector
configuration_vector => i_mac_configuration_vector
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
gt_userclk_bufg     => '0',
gt_userclk2_bufg    => g_userclk2_bufg,--g_clk125M,
gt_resetdone        => i_pma_resetdone,
dcm_locked          => i_dcm_locked,

-- 200MHz reference clock for the IDELAYCTRL
refclk               => g_refclk, --: in std_logic;

--------------------------------------------------------------------------
-- Core connected to GTP0
--------------------------------------------------------------------------

-- GMII Interface (client MAC <=> PCS)
-----------------
gmii_tx_clk0         => i_pma_gmii_tx_clk, --: in std_logic;
gmii_txd0            => i_pma_gmii_txd   , --: in std_logic_vector(7 downto 0);
gmii_tx_en0          => i_pma_gmii_tx_en , --: in std_logic;
gmii_tx_er0          => i_pma_gmii_tx_er , --: in std_logic;

gmii_rx_clk0         => i_pma_gmii_rx_clk, --: out std_logic;
gmii_rxd0            => i_pma_gmii_rxd   , --: out std_logic_vector(7 downto 0);
gmii_rx_dv0          => i_pma_gmii_rx_dv , --: out std_logic;
gmii_rx_er0          => i_pma_gmii_rx_er , --: out std_logic;

-- Management: Alternative to MDIO Interface
configuration_vector0 => i_pma_cfg_vector, --: in std_logic_vector(4 downto 0);  -- Alternative to MDIO interface.

-- General IO's
status_vector0       => i_pma_core_status,      --: out std_logic_vector(15 downto 0); -- Core status.
reset0               => i_reset,                --: in std_logic;                     -- Asynchronous reset for entire core.
signal_detect0       => i_pma_sfp_signal_detect,--: in std_logic                      -- Input from PMD to indicate presence of optical input.

--------------------------------------------------------------------------
-- Tranceiver interfaces
--------------------------------------------------------------------------
brefclk_p            => p_in_phy.pin.fiber.clk_p,--125MHz, very high quality
brefclk_n            => p_in_phy.pin.fiber.clk_n,--125MHz, very high quality

txp0                 => p_out_phy.pin.fiber.txp(0) ,
txn0                 => p_out_phy.pin.fiber.txn(0) ,
rxp0                 => p_in_phy.pin.fiber.rxp(0)  ,
rxn0                 => p_in_phy.pin.fiber.rxn(0)  ,

txp1                 => p_out_phy.pin.fiber.txp(1) ,
txn1                 => p_out_phy.pin.fiber.txn(1) ,
rxp1                 => p_in_phy.pin.fiber.rxp(1)  ,
rxn1                 => p_in_phy.pin.fiber.rxn(1)
);



--####################################################
--Clocking
--####################################################
----########################
----ETH_1G
----########################
----g_userclk2_bufg <= i_pma_gt_txoutclk_bufg;--g_clk125M <= i_pma_gt_txoutclk_bufg;
----i_dcm_locked <= '1';
--client_dcm_1G : DCM_BASE
--generic map(
--CLKIN_PERIOD      => 8.0, -- Specify period of input clock in ns from 1.25 to 1000.00
--CLKFX_MULTIPLY    => 2,   -- Can be any integer from 2 to 32
--CLKFX_DIVIDE      => 2,   -- Can be any integer from 1 to 32
--CLKIN_DIVIDE_BY_2 => FALSE,
--CLKDV_DIVIDE      => 2.0, --
--CLKOUT_PHASE_SHIFT    => "NONE",
--CLK_FEEDBACK          => "1X",
--DCM_PERFORMANCE_MODE  => "MAX_SPEED",
--DCM_AUTOCALIBRATION   => TRUE,
--DESKEW_ADJUST         => "SYSTEM_SYNCHRONOUS",
--DFS_FREQUENCY_MODE    => "LOW",
--DLL_FREQUENCY_MODE    => "HIGH",
--DUTY_CYCLE_CORRECTION => TRUE,
--FACTORY_JF   => X"F0F0",
--PHASE_SHIFT  => 0,
--STARTUP_WAIT => FALSE
--)
--port map (
--CLKIN    => i_pma_gt_txoutclk_bufg,
--CLKFB    => g_dcm_clkfbout     ,
--RST      => i_dcm_rst          ,
--CLK0     => i_dcm_clkfbout,
--CLK90    => open               ,
--CLK180   => open               ,
--CLK270   => open               ,
--CLK2X    => open               ,
--CLK2X180 => open               ,
--CLKDV    => open               ,
--CLKFX    => i_userclk2_bufg    ,
--CLKFX180 => open               ,
--LOCKED   => i_dcm_locked
--);
--
--i_dcm_rst <= i_reset;-- or (not i_pma_resetdone);
--
--bufg_dcm_fb : BUFG port map (I => i_dcm_clkfbout, O => g_dcm_clkfbout);
--bufg_gt_usrclk2 : BUFG port map (I => i_userclk2_bufg, O => g_userclk2_bufg);

--########################
--ETH_2G
--########################
client_dcm_2G : DCM_BASE
generic map(
CLKIN_PERIOD      => 8.0, -- Specify period of input clock in ns from 1.25 to 1000.00
CLKFX_MULTIPLY    => 2,   -- Can be any integer from 2 to 32
CLKFX_DIVIDE      => 1,   -- Can be any integer from 1 to 32
CLKIN_DIVIDE_BY_2 => FALSE,
CLKDV_DIVIDE      => 2.0, --
CLKOUT_PHASE_SHIFT    => "NONE",
CLK_FEEDBACK          => "1X",
DCM_PERFORMANCE_MODE  => "MAX_SPEED",
DCM_AUTOCALIBRATION   => TRUE,
DESKEW_ADJUST         => "SYSTEM_SYNCHRONOUS",
DFS_FREQUENCY_MODE    => "HIGH",
DLL_FREQUENCY_MODE    => "HIGH",
DUTY_CYCLE_CORRECTION => TRUE,
FACTORY_JF   => X"F0F0",
PHASE_SHIFT  => 0,
STARTUP_WAIT => FALSE
)
port map (
CLKIN    => i_pma_gt_txoutclk_bufg,
CLKFB    => g_dcm_clkfbout     ,
RST      => i_dcm_rst          ,
CLK0     => i_dcm_clkfbout     ,
CLK90    => open               ,
CLK180   => open               ,
CLK270   => open               ,
CLK2X    => open               ,
CLK2X180 => open               ,
CLKDV    => open               ,
CLKFX    => i_userclk2_bufg    ,
CLKFX180 => open               ,
LOCKED   => i_dcm_locked
);

i_dcm_rst <= i_reset;-- or (not i_pma_resetdone);

bufg_dcm_fb : BUFG port map (I => i_dcm_clkfbout, O => g_dcm_clkfbout);
bufg_gt_usrclk2 : BUFG port map (I => i_userclk2_bufg, O => g_userclk2_bufg);--g_clk125M);



end top_level;
