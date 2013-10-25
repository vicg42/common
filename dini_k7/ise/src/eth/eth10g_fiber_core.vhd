library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_misc.all;

library work;
use work.eth_pkg.all;
use work.vicg_common_pkg.all;

-------------------------------------------------------------------------------
-- Entity declaration for the example design
-------------------------------------------------------------------------------

entity eth_phy is
  generic (
  G_ETH : TEthGeneric;
  G_DBG : string:="OFF";
  G_SIM : string:="OFF"
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


architecture TOP_LEVEL of eth_phy is

signal i_rx_axis_tdata   : std_logic_vector(63 downto 0);
signal i_rx_axis_tkeep   : std_logic_vector(7 downto 0);
signal i_rx_axis_tvalid  : std_logic;
signal i_rx_axis_tlast   : std_logic;
signal i_rx_axis_tready  : std_logic;

signal i_tx_axis_tdata   : std_logic_vector(63 downto 0);
signal i_tx_axis_tkeep   : std_logic_vector(7 downto 0);
signal i_tx_axis_tvalid  : std_logic;
signal i_tx_axis_tlast   : std_logic;
signal i_tx_axis_tready  : std_logic;
signal i_tx_axis_tuser   : std_logic;

signal axis_clk_out      : std_logic;

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

axis_clk_out : out std_logic;

--tx_dcm_locked  : in std_logic;

---------------------------------------------------------------------------
-- Interface to the host.
---------------------------------------------------------------------------
reset          : in  std_logic;       -- Resets the MAC.
tx_axis_aresetn      : in  std_logic;
tx_ifg_delay : in std_logic_vector(7 downto 0);
tx_axis_tuser : in std_logic;
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
signal xgmii_rxd    : std_logic_vector(63 downto 0);
signal xgmii_rxc    : std_logic_vector(7 downto 0);

signal reset   : std_logic := '1';    -- start in
                                      -- reset
signal aresetn  : std_logic;

signal tx_ifg_delay         : std_logic_vector(7 downto 0);
--signal tx_axis_tuser        : std_logic;
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
generic (
QPLL_FBDIV_TOP : integer := 66;
EXAMPLE_SIM_GTRESET_SPEEDUP : string := "FALSE"
);
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
  pma_loopback     : in std_logic;
  pma_reset        : in std_logic;
  global_tx_disable: in std_logic;
  pma_vs_loopback  : in std_logic_vector(3 downto 0);
  pcs_loopback     : in std_logic;
  pcs_reset        : in std_logic;
  test_patt_a      : in std_logic_vector(57 downto 0);
  test_patt_b      : in std_logic_vector(57 downto 0);
  data_patt_sel    : in std_logic;
  test_patt_sel    : in std_logic;
  rx_test_patt_en  : in std_logic;
  tx_test_patt_en  : in std_logic;
  prbs31_tx_en     : in std_logic;
  prbs31_rx_en     : in std_logic;
  pcs_vs_loopback  : in std_logic_vector(1 downto 0);
  set_pma_link_status      : in std_logic;
  set_pcs_link_status      : in std_logic;
  clear_pcs_status2        : in std_logic;
  clear_test_patt_err_count: in std_logic;

  pma_link_status         : out std_logic;
  rx_sig_det              : out std_logic;
  pcs_rx_link_status      : out std_logic;
  pcs_rx_locked           : out std_logic;
  pcs_hiber               : out std_logic;
  teng_pcs_rx_link_status : out std_logic;
  pcs_err_block_count     : out std_logic_vector(7 downto 0);
  pcs_ber_count           : out std_logic_vector(5 downto 0);
  pcs_rx_hiber_lh         : out std_logic;
  pcs_rx_locked_ll        : out std_logic;
  pcs_test_patt_err_count : out std_logic_vector(15 downto 0);
  status_vector_preserve  : out std_logic;
  core_status      : out std_logic_vector(7 downto 0);
  resetdone        : out std_logic;
  signal_detect    : in  std_logic;
  tx_fault         : in  std_logic;
  tx_disable       : out std_logic;

  configuration_vector_preserve : in std_logic;
  is_eval          : out std_logic;
  an_enable        : in  std_logic;
  training_enable  : in  std_logic;
  training_addr    : in  std_logic_vector(20 downto 0);
  training_rnw     : in  std_logic;
  training_wrdata  : in  std_logic_vector(15 downto 0);
  training_ipif_cs : in  std_logic;
  training_drp_cs  : in  std_logic;
  training_rddata  : out std_logic_vector(15 downto 0);
  training_rdack   : out std_logic;
  training_wrack   : out std_logic
);
end component;

signal i_pma_core_status : std_logic_vector(7 downto 0);
signal i_pma_resetdone : std_logic;
signal i_pma_sfp_signal_detect : std_logic;
signal i_pma_sfp_tx_fault : std_logic;
signal i_pma_sfp_tx_disable : std_logic;
signal i_pma_core_clk156_out : std_logic;
signal i_pma_clk156_mmcm_locked : std_logic;


signal tst_rx_axis_tdata   : std_logic_vector(63 downto 0);
signal tst_rx_axis_tkeep   : std_logic_vector(7 downto 0);
signal tst_rx_axis_tvalid  : std_logic;
signal tst_rx_axis_tlast   : std_logic;
signal tst_rx_axis_tready  : std_logic;

signal tst_tx_axis_tdata   : std_logic_vector(63 downto 0);
signal tst_tx_axis_tkeep   : std_logic_vector(7 downto 0);
signal tst_tx_axis_tvalid  : std_logic;
signal tst_tx_axis_tlast   : std_logic;
signal tst_tx_axis_tready  : std_logic;
signal tst_tx_axis_tuser   : std_logic;

signal tst_out             : std_logic_vector(3 downto 0) := (others => '0');
signal tst_sfp_txdis       : std_logic;
signal tst_sfp_sd          : std_logic;
signal tst_sfp_tx_fault    : std_logic;
signal tst_pma_core_status : std_logic_vector(i_pma_core_status'range);
signal tst_pma_resetdone   : std_logic;
signal tst_rx_idle         : std_logic := '0';
signal tst_rx_err          : std_logic := '0';
signal tst_rx              : std_logic := '0';

begin

p_out_tst(7 downto 0) <= i_pma_core_status;
--p_out_tst(8) <= i_pma_resetdone;
--p_out_tst(9) <= i_pma_core_clk156_out;
p_out_dbg(0).d(0) <= tst_pma_resetdone or OR_reduce(tst_pma_core_status) --or tst_rx_idle or tst_rx_err or tst_rx
                    or tst_sfp_tx_fault or tst_sfp_sd or tst_sfp_txdis;
p_out_dbg(0).d(1) <= tst_out(0);
p_out_dbg(0).d(2) <= tst_out(1);
p_out_dbg(0).d(3) <= tst_out(2);
p_out_dbg(0).d(4) <= tst_out(3);

p_out_phy.link <= i_pma_sfp_signal_detect;
p_out_phy.rdy <= i_pma_resetdone;
p_out_phy.clk <= axis_clk_out;--i_pma_core_clk156_out;
p_out_phy.rst <= p_in_rst;

p_out_phy.pin.fiber.clk_oe_n <= '0';-- Oscillator Output Enable
p_out_phy.pin.fiber.clk_sel <= "11";--00/01/10/11 - 100MHz/125Mhz/150Mhz/156.25Mhz
p_out_phy.pin.fiber.sfp_rs <= (others => '1');

p_out_phy.pin.fiber.sfp_txdis <= i_pma_sfp_tx_disable;--'0';
i_pma_sfp_signal_detect <= not p_in_phy.pin.fiber.sfp_sd;
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
tx_configuration_vector(4) <= '1';--Transmitter Jumbo Frame Enable.
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
rx_configuration_vector(4) <= '1';--Receiver Jumbo Frame Enable.
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
rx_axis_tdata   => i_rx_axis_tdata,  --p_out_phy2app(0).axirx_tdata ,--
rx_axis_tkeep   => i_rx_axis_tkeep,  --p_out_phy2app(0).axirx_tkeep ,--
rx_axis_tvalid  => i_rx_axis_tvalid, --p_out_phy2app(0).axirx_tvalid,--
rx_axis_tlast   => i_rx_axis_tlast,  --p_out_phy2app(0).axirx_tlast ,--
rx_axis_tready  => i_rx_axis_tready, --p_in_phy2app(0).axirx_tready ,--

tx_axis_tdata   => i_tx_axis_tdata,  --p_in_phy2app(0).axitx_tdata  ,--
tx_axis_tkeep   => i_tx_axis_tkeep,  --p_in_phy2app(0).axitx_tkeep  ,--
tx_axis_tvalid  => i_tx_axis_tvalid, --p_in_phy2app(0).axitx_tvalid ,--
tx_axis_tlast   => i_tx_axis_tlast,  --p_in_phy2app(0).axitx_tlast  ,--
tx_axis_tready  => i_tx_axis_tready, --p_out_phy2app(0).axitx_tready,--

axis_clk_out     => axis_clk_out,

--tx_dcm_locked           => i_pma_clk156_mmcm_locked,--tx_dcm_locked,--: in std_logic;

reset                   => reset,
tx_axis_aresetn         => aresetn,
tx_axis_tuser           => i_tx_axis_tuser,
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
gtx_clk                 => i_pma_core_clk156_out,--: in  std_logic;                     -- The global transmit clock from the outside world.  tx_clk0,--gtx_clk,
xgmii_tx_clk            => xgmii_tx_clk,         --: out std_logic;                     -- the TX clock from the reconcilliation sublayer.
xgmii_txd               => xgmii_txd,            --: out std_logic_vector(63 downto 0); -- Transmitted data
xgmii_txc               => xgmii_txc,            --: out std_logic_vector(7 downto 0);  -- Transmitted control
xgmii_rx_clk            => xgmii_rx_clk,         --: in  std_logic;                     -- The rx clock from the PHY layer.
xgmii_rxd               => xgmii_rxd,            --: in  std_logic_vector(63 downto 0); -- Received data
xgmii_rxc               => xgmii_rxc             --: in  std_logic_vector(7 downto 0)   -- received control
);


m_pma : eth10g_pma
generic map(
QPLL_FBDIV_TOP => 66,
EXAMPLE_SIM_GTRESET_SPEEDUP => selstring ("TRUE", "FALSE", strcmp(G_SIM, "ON"))
)
port map (
reset            => reset,
--mmcm_locked     => i_pma_clk156_mmcm_locked,
core_clk156_out  => i_pma_core_clk156_out,
xgmii_txd        => xgmii_txd,
xgmii_txc        => xgmii_txc,
xgmii_rx_clk     => xgmii_rx_clk,
xgmii_rxd        => xgmii_rxd,
xgmii_rxc        => xgmii_rxc,
refclk_p         => p_in_phy.pin.fiber.clk_p,
refclk_n         => p_in_phy.pin.fiber.clk_n,
txp              => p_out_phy.pin.fiber.txp(0),
txn              => p_out_phy.pin.fiber.txn(0),
rxp              => p_in_phy.pin.fiber.rxp(0),
rxn              => p_in_phy.pin.fiber.rxn(0),
resetdone        => i_pma_resetdone,
signal_detect    => i_pma_sfp_signal_detect,
tx_fault         => i_pma_sfp_tx_fault,
tx_disable       => i_pma_sfp_tx_disable,
core_status      => i_pma_core_status,

pma_loopback      => '0',          --: in std_logic;
pma_reset         => '0',          --: in std_logic;
global_tx_disable => '0',          --: in std_logic;
pma_vs_loopback   => (others=>'0'),--: in std_logic_vector(3 downto 0);
pcs_loopback      => '0',          --: in std_logic;
pcs_reset         => '0',          --: in std_logic;
test_patt_a       => (others=>'0'),--: in std_logic_vector(57 downto 0);
test_patt_b       => (others=>'0'),--: in std_logic_vector(57 downto 0);
data_patt_sel     => '0',          --: in std_logic;
test_patt_sel     => '0',          --: in std_logic;
rx_test_patt_en   => '0',          --: in std_logic;
tx_test_patt_en   => '0',          --: in std_logic;
prbs31_tx_en      => '0',          --: in std_logic;
prbs31_rx_en      => '0',          --: in std_logic;
pcs_vs_loopback   => (others=>'0'),--: in std_logic_vector(1 downto 0);
set_pma_link_status       => '0',  --: in std_logic;
set_pcs_link_status       => '0',  --: in std_logic;
clear_pcs_status2         => '0',  --: in std_logic;
clear_test_patt_err_count => '0',  --: in std_logic;

pma_link_status         => open,   --: out std_logic;
rx_sig_det              => open,   --: out std_logic;
pcs_rx_link_status      => open,   --: out std_logic;
pcs_rx_locked           => open,   --: out std_logic;
pcs_hiber               => open,   --: out std_logic;
teng_pcs_rx_link_status => open,   --: out std_logic;
pcs_err_block_count     => open,   --: out std_logic_vector(7 downto 0);
pcs_ber_count           => open,   --: out std_logic_vector(5 downto 0);
pcs_rx_hiber_lh         => open,   --: out std_logic;
pcs_rx_locked_ll        => open,   --: out std_logic;
pcs_test_patt_err_count => open,   --: out std_logic_vector(15 downto 0);
status_vector_preserve  => open,   --: out std_logic;

configuration_vector_preserve => '0',--: in std_logic;
is_eval          => open,          --: out std_logic;
an_enable        => '0',           --: in  std_logic;
training_enable  => '0',           --: in  std_logic;
training_addr    => (others=>'0'), --: in  std_logic_vector(20 downto 0);
training_rnw     => '0',           --: in  std_logic;
training_wrdata  => (others=>'0'), --: in  std_logic_vector(15 downto 0);
training_ipif_cs => '0',           --: in  std_logic;
training_drp_cs  => '0',           --: in  std_logic;
training_rddata  => open,          --: out std_logic_vector(15 downto 0);
training_rdack   => open,          --: out std_logic;
training_wrack   => open           --: out std_logic
);


--####################################################
--AXI convertor
--####################################################
--FPGA <- ETH
p_out_phy2app(0).rxd          <= i_rx_axis_tdata;
p_out_phy2app(0).rxsof_n      <= not i_rx_axis_tvalid;
p_out_phy2app(0).rxeof_n      <= not (i_rx_axis_tlast and i_rx_axis_tvalid);
p_out_phy2app(0).rxsrc_rdy_n  <= not i_rx_axis_tvalid;
p_out_phy2app(0).rxrem        <= i_rx_axis_tkeep;
p_out_phy2app(0).rxbuf_status <= (others=>'0');

i_rx_axis_tready <= not p_in_phy2app(0).rxdst_rdy_n;


--FPGA -> ETH
p_out_phy2app(0).txdst_rdy_n <= not i_tx_axis_tready;

i_tx_axis_tdata <= p_in_phy2app(0).txd;
i_tx_axis_tkeep <= p_in_phy2app(0).txrem;
i_tx_axis_tvalid <= not p_in_phy2app(0).txsof_n or not p_in_phy2app(0).txsrc_rdy_n;
i_tx_axis_tlast <= not p_in_phy2app(0).txeof_n;
i_tx_axis_tuser <= '0';


process(axis_clk_out)
begin
  if rising_edge(axis_clk_out) then

    tst_rx_axis_tdata  <= i_rx_axis_tdata ; --p_out_phy2app(0).axirx_tdata ,--
    tst_rx_axis_tkeep  <= i_rx_axis_tkeep ; --p_out_phy2app(0).axirx_tkeep ,--
    tst_rx_axis_tvalid <= i_rx_axis_tvalid; --p_out_phy2app(0).axirx_tvalid,--
    tst_rx_axis_tlast  <= i_rx_axis_tlast ; --p_out_phy2app(0).axirx_tlast ,--
    tst_rx_axis_tready <= i_rx_axis_tready; --p_in_phy2app(0).axirx_tready ,--

    tst_tx_axis_tdata  <= i_tx_axis_tdata ; --p_in_phy2app(0).axitx_tdata  ,--
    tst_tx_axis_tkeep  <= i_tx_axis_tkeep ; --p_in_phy2app(0).axitx_tkeep  ,--
    tst_tx_axis_tvalid <= i_tx_axis_tvalid; --p_in_phy2app(0).axitx_tvalid ,--
    tst_tx_axis_tlast  <= i_tx_axis_tlast ; --p_in_phy2app(0).axitx_tlast  ,--
    tst_tx_axis_tready <= i_tx_axis_tready; --p_out_phy2app(0).axitx_tready,--
--    tst_tx_axis_tuser  <= i_tx_axis_tuser ; --p_in_phy2app(0).axitx_tuser  ,--

    tst_out(0) <= tst_tx_axis_tready or tst_tx_axis_tlast or tst_tx_axis_tvalid
                  or tst_rx_axis_tready or tst_rx_axis_tlast or tst_rx_axis_tvalid;
--                  or tst_tx_axis_tuser;
    tst_out(2) <= OR_reduce(tst_tx_axis_tdata) or OR_reduce(tst_tx_axis_tkeep);

    tst_out(3) <= OR_reduce(tst_rx_axis_tdata) or OR_reduce(tst_rx_axis_tkeep);

    tst_sfp_txdis <= i_pma_sfp_tx_disable;--'1';
    tst_sfp_sd <= i_pma_sfp_signal_detect;
    tst_sfp_tx_fault <= i_pma_sfp_tx_fault;
    tst_pma_core_status <= i_pma_core_status;
    tst_pma_resetdone <= i_pma_resetdone;


--    if xgmii_rxd(63 downto 0) = X"0707070707070707" then
--    tst_rx_idle <= '1';
--    else
--    tst_rx_idle <= '0';
--    end if;
--
--    if xgmii_rxd(63 downto 0) = X"FEFEFEFEFEFEFEFE" then
--    tst_rx_err <= '1';
--    else
--    tst_rx_err <= '0';
--    end if;
--
--    tst_rx <= tst_rx_idle or tst_rx_err;

  end if;
end process;

end TOP_LEVEL;
