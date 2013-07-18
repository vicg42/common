
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

entity eth10g_fiber_core is
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

end eth10g_fiber_core;


architecture TOP_LEVEL of eth10g_fiber_core is


component eth10g_mac
port(
rx_axis_tdata   : out std_logic_vector(63 downto 0);
rx_axis_tkeep   : out std_logic_vector(7 downto 0);
rx_axis_tvalid  : out std_logic;
rx_axis_tlast   : out std_logic;
rx_axis_tready  : in  std_logic;

tx_axis_tdata   : in  std_logic_vector(63 downto 0);
tx_axis_tkeep   : in  std_logic_vector(7 downto 0);
tx_axis_tvalid  : in  std_logic;
tx_axis_tlast   : in  std_logic;
tx_axis_tready  : out std_logic;
tx_axis_tuser   : in  std_logic;

---------------------------------------------------------------------------
-- Interface to the host.
---------------------------------------------------------------------------
reset          : in  std_logic;       -- Resets the MAC.
tx_axis_aresetn      : in  std_logic;
tx_ifg_delay : in std_logic_vector(7 downto 0);
--    tx_axis_tuser : in std_logic;
tx_statistics_vector : out std_logic_vector(25 downto 0); -- Statistics information on the last frame.
tx_statistics_valid  : out std_logic;                     -- High when stats are valid.
pause_val      : in  std_logic_vector(15 downto 0); -- Indicates the length of the pause that should be transmitted.
pause_req      : in  std_logic;                    -- A '1' indicates that a pause frame should  be sent.
rx_axis_aresetn      : in  std_logic;
rx_statistics_vector : out std_logic_vector(29 downto 0); -- Statistics info on the last received frame.
rx_statistics_valid  : out std_logic;                      -- High when above stats are valid.
tx_configuration_vector : in std_logic_vector(31 downto 0);
rx_configuration_vector : in std_logic_vector(31 downto 0);
pause_addr_vector       : in std_logic_vector(47 downto 0);
status_vector  : out std_logic_vector(1 downto 0);
tx_dcm_locked  : in std_logic;
gtx_clk        : in  std_logic;                     -- The global transmit clock from the outside world.
xgmii_tx_clk   : out std_logic;                -- the TX clock from the reconcilliation sublayer.
xgmii_txd      : out std_logic_vector(63 downto 0); -- Transmitted data
xgmii_txc      : out std_logic_vector(7 downto 0); -- Transmitted control
xgmii_rx_clk   : in  std_logic;                     -- The rx clock from the PHY layer.
xgmii_rxd      : in  std_logic_vector(63 downto 0); -- Received data
xgmii_rxc      : in  std_logic_vector(7 downto 0)  -- received control
);
end component;

signal xgmii_tx_clk : std_logic;
signal xgmii_txd    : std_logic_vector(63 downto 0);
signal xgmii_txc    : std_logic_vector(7 downto 0);
signal xgmii_rx_clk : std_logic := '0';
signal xgmii_rxd    : std_logic_vector(63 downto 0) := X"0707070707070707";
signal xgmii_rxc    : std_logic_vector(7 downto 0) := "11111111";

signal reset   : std_logic := '1';    -- start in
                                      -- reset
signal aresetn  : std_logic;

signal tx_ifg_delay         : std_logic_vector(7 downto 0);
signal tx_axis_tuser        : std_logic;
signal tx_statistics_vector : std_logic_vector(25 downto 0);
signal tx_statistics_valid  : std_logic;

signal pause_val : std_logic_vector(15 downto 0) := (others => '0');
signal pause_req : std_logic                     := '0';
signal rx_statistics_vector : std_logic_vector(29 downto 0);
signal rx_statistics_valid  : std_logic;

signal tx_configuration_vector : std_logic_vector(31 downto 0):= X"00000016";
signal rx_configuration_vector : std_logic_vector(31 downto 0):= X"00000016";
signal pause_addr_vector       : std_logic_vector(47 downto 0):= X"000000000000";
signal status_vector : std_logic_vector(1 downto 0);

component eth10g_pma
port (
refclk_p         : in  std_logic;
refclk_n         : in  std_logic;
core_clk156_out  : out std_logic;
reset            : in  std_logic;
xgmii_txd        : in  std_logic_vector(63 downto 0);
xgmii_txc        : in  std_logic_vector(7 downto 0);
xgmii_rxd        : out std_logic_vector(63 downto 0);
xgmii_rxc        : out std_logic_vector(7 downto 0);
xgmii_rx_clk     : out std_logic;
txp              : out std_logic;
txn              : out std_logic;
rxp              : in  std_logic;
rxn              : in  std_logic;

core_status      : out std_logic_vector(7 downto 0);
resetdone        : out std_logic;
signal_detect    : in  std_logic;
tx_fault         : in  std_logic;
tx_disable       : out std_logic
);
end component;

signal i_pma_core_status : std_logic_vector(7 downto 0);
signal i_pma_resetdone : std_logic;
signal i_pma_sfp_signal_detect : std_logic;
signal i_pma_sfp_tx_fault : std_logic;
signal i_pma_sfp_tx_disable : std_logic;
signal i_pma_core_clk156_out : std_logic;



begin

p_out_tst(7 downto 0) <= i_pma_core_status;
--p_out_tst(8) <= i_pma_resetdone;
--p_out_tst(9) <= i_pma_core_clk156_out;

p_out_phy.link <= not p_in_phy.pin.fiber.sfp_sd;
p_out_phy.rdy <= i_pma_resetdone;
p_out_phy.clk <= i_pma_core_clk156_out;
p_out_phy.rst <= p_in_rst;

p_out_phy.pin.fiber.sfp_txdis <= i_pma_sfp_tx_disable;--'1';
i_pma_sfp_signal_detect <= p_in_phy.pin.fiber.sfp_sd;
i_pma_sfp_tx_fault <= p_in_phy.pin.fiber.sfp_txfault;


pause_val <= CONV_STD_LOGIC_VECTOR(16#00#, pause_val'length);
pause_req <= '0';

tx_ifg_delay <= CONV_STD_LOGIC_VECTOR(16#00#, tx_ifg_delay'length);
--tx_configuration_vector <= X"00000016";
--rx_configuration_vector <= X"00000016";

tx_configuration_vector(0) <= '0';--Transmitter Reset.
tx_configuration_vector(1) <= '1';--Transmitter Enable.
tx_configuration_vector(2) <= '0';--Transmitter VLAN Enable.
tx_configuration_vector(3) <= '0';--Transmitter In-Band FCS Enable.
tx_configuration_vector(4) <= '0';--Transmitter Jumbo Frame Enable.
tx_configuration_vector(5) <= '0';--Transmit Flow Control Enable.
tx_configuration_vector(6) <= '0';--Reserved
tx_configuration_vector(7) <= '0';--Transmitter Preserve Preamble Enable.
tx_configuration_vector(8) <= '0';--Transmitter Interframe Gap Adjust Enable.
tx_configuration_vector(9) <= '0';--Transmitter LAN/WAN Mode.
tx_configuration_vector(10) <= '0';-- Deficit Idle Count Enable.
tx_configuration_vector(13 downto 11) <= (others=>'0');-- Reserved
tx_configuration_vector(14) <= '0';-- TX MTU Enable.ation settings.
tx_configuration_vector(15) <= '0';--Reserved
tx_configuration_vector(31 downto 16) <= (others=>'0');--TX MTU Size.

rx_configuration_vector(0) <= '0';--Receiver Reset.
rx_configuration_vector(1) <= '1';--Receiver Enable.
rx_configuration_vector(2) <= '0';--Receiver VLAN Enable.
rx_configuration_vector(3) <= '0';--Receiver In-Band FCS Enable.
rx_configuration_vector(4) <= '0';--Receiver Jumbo Frame Enable.
rx_configuration_vector(5) <= '0';--Receive Flow Control Enable.
rx_configuration_vector(6) <= '0';--Reserved
rx_configuration_vector(7) <= '0';--Receiver Preserve Preamble Enable.
rx_configuration_vector(8) <= '0';--Receiver Length/Type Error Disable.
rx_configuration_vector(9) <= '0';--Control Frame Length Check Disable.
rx_configuration_vector(10) <= '0';--Reconciliation Sublayer Fault Inhibit.
rx_configuration_vector(13 downto 11) <= (others=>'0');--Reserved
rx_configuration_vector(14) <= '0';--RX MTU Enable.
rx_configuration_vector(15) <= '0';--Reserved
rx_configuration_vector(31 downto 16) <= (others=>'0');--RX MTU Size.



reset <= p_in_rst;
aresetn <= not reset;

m_mac: eth10g_mac
port map (
rx_axis_tdata   => p_out_phy2app(0).axirx_tdata ,--rx_axis_tdata_int,
rx_axis_tkeep   => p_out_phy2app(0).axirx_tkeep ,--rx_axis_tkeep_int,
rx_axis_tvalid  => p_out_phy2app(0).axirx_tvalid,--rx_axis_tvalid_int,
rx_axis_tlast   => p_out_phy2app(0).axirx_tlast ,--rx_axis_tlast_int,
rx_axis_tready  => p_in_phy2app(0).axirx_tready ,--rx_axis_tready_int,

tx_axis_tdata   => p_in_phy2app(0).axitx_tdata  ,--tx_axis_tdata_int,
tx_axis_tkeep   => p_in_phy2app(0).axitx_tkeep  ,--tx_axis_tkeep_int,
tx_axis_tvalid  => p_in_phy2app(0).axitx_tvalid ,--tx_axis_tvalid_int,
tx_axis_tlast   => p_in_phy2app(0).axitx_tlast  ,--tx_axis_tlast_int,
tx_axis_tready  => p_out_phy2app(0).axitx_tready,--tx_axis_ready,
tx_axis_tuser   => p_in_phy2app(0).axitx_tuser  ,--tx_axis_tuser,

reset                   => reset,
tx_axis_aresetn         => aresetn,
--      tx_axis_tuser           => tx_axis_tuser,
tx_ifg_delay            => tx_ifg_delay,
tx_statistics_vector    => tx_statistics_vector,
tx_statistics_valid     => tx_statistics_valid,
pause_val               => pause_val,
pause_req               => pause_req,
rx_axis_aresetn         => aresetn,
rx_statistics_vector    => rx_statistics_vector,
rx_statistics_valid     => rx_statistics_valid,
tx_configuration_vector => tx_configuration_vector,
rx_configuration_vector => rx_configuration_vector,
pause_addr_vector       => pause_addr_vector,
status_vector           => status_vector,
tx_dcm_locked           => i_pma_resetdone,--tx_dcm_locked,--: in std_logic;
gtx_clk                 => i_pma_core_clk156_out,--tx_clk0,--gtx_clk,
xgmii_tx_clk            => open,--xgmii_tx_clk,
xgmii_txd               => xgmii_txd,
xgmii_txc               => xgmii_txc,
xgmii_rx_clk            => xgmii_rx_clk,
xgmii_rxd               => xgmii_rxd,
xgmii_rxc               => xgmii_rxc
);


m_pma : eth10g_pma
port map (
reset           => reset,
core_clk156_out => i_pma_core_clk156_out,
xgmii_txd       => xgmii_txd,
xgmii_txc       => xgmii_txc,
xgmii_rx_clk    => xgmii_rx_clk,
xgmii_rxd       => xgmii_rxd,
xgmii_rxc       => xgmii_rxc,
refclk_p        => p_in_phy.pin.fiber.refclk_p,
refclk_n        => p_in_phy.pin.fiber.refclk_n,

txp             => p_out_phy.pin.fiber.txp(0),
txn             => p_out_phy.pin.fiber.txn(0),
rxp             => p_in_phy.pin.fiber.rxp(0),
rxn             => p_in_phy.pin.fiber.rxn(0),
resetdone       => i_pma_resetdone,
signal_detect   => i_pma_sfp_signal_detect,
tx_fault        => i_pma_sfp_tx_fault,
tx_disable      => i_pma_sfp_tx_disable,
core_status     => i_pma_core_status
);

end TOP_LEVEL;
