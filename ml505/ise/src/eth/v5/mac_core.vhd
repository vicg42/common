--------------------------------------------------------------------------------
-- File       : mac_gmii_core_example_design.vhd
-- Author     : Xilinx Inc.
-- ------------------------------------------------------------------------------
-- (c) Copyright 2004-2009 Xilinx, Inc. All rights reserved.
--
-- This file contains confidential and proprietary information
-- of Xilinx, Inc. and is protected under U.S. and
-- international copyright and other intellectual property
-- laws.
--
-- DISCLAIMER
-- This disclaimer is not a license and does not grant any
-- rights to the materials distributed herewith. Except as
-- otherwise provided in a valid license issued to you by
-- Xilinx, and to the maximum extent permitted by applicable
-- law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND
-- WITH ALL FAULTS, AND XILINX HEREBY DISCLAIMS ALL WARRANTIES
-- AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING
-- BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-
-- INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and
-- (2) Xilinx shall not be liable (whether in contract or tort,
-- including negligence, or under any other theory of
-- liability) for any loss or damage of any kind or nature
-- related to, arising under or in connection with these
-- materials, including for any direct, or any indirect,
-- special, incidental, or consequential loss or damage
-- (including loss of data, profits, goodwill, or any type of
-- loss or damage suffered as a result of any action brought
-- by a third party) even if such damage or loss was
-- reasonably foreseeable or Xilinx had been advised of the
-- possibility of the same.
--
-- CRITICAL APPLICATIONS
-- Xilinx products are not designed or intended to be fail-
-- safe, or for use in any application requiring fail-safe
-- performance, such as life-support or safety devices or
-- systems, Class III medical devices, nuclear facilities,
-- applications related to the deployment of airbags, or any
-- other applications that could lead to death, personal
-- injury, or severe property or environmental damage
-- (individually and collectively, "Critical
-- Applications"). Customer assumes the sole risk and
-- liability of any use of Xilinx products in Critical
-- Applications, subject only to applicable laws and
-- regulations governing limitations on product liability.
--
-- THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS
-- PART OF THIS FILE AT ALL TIMES.
-- ------------------------------------------------------------------------------
-- Description:  This is the VHDL example design for the Tri-Mode
--               Ethernet MAC core. It is intended that this example design
--               can be quickly adapted and downloaded onto an FPGA to provide
--               a real hardware test environment.
--
--               This level:
--
--               * Instantiates the LocalLink wrapper, containing the
--                 block level wrapper and an RX and TX FIFO with a
--                 LocalLink interface;
--
--               * Instantiates a simple client example design,
--                 providing an address swap and a simple
--                 loopback function;
--
--               * Instantiates transmitter clocking circuitry
--
--               Please refer to the Datasheet, Getting Started Guide, and
--               the Tri-Mode Ethernet MAC User Gude for further information.
--
--
--    ---------------------------------------------------------------------
--    | EXAMPLE DESIGN WRAPPER                                            |
--    |           --------------------------------------------------------|
--    |           |LOCALLINK WRAPPER                                      |
--    |           |              -----------------------------------------|
--    |           |              |BLOCK LEVEL WRAPPER                     |
--    |           |              |    ---------------------               |
--    | --------  |  ----------  |    | ETHERNET MAC      |               |
--    | |      |  |  |        |  |    | CORE              |  ---------    |
--    | |      |->|->|        |--|--->| Tx            Tx  |--|       |--->|
--    | |      |  |  |        |  |    | client        PHY |  |       |    |
--    | | ADDR |  |  | LOCAL  |  |    | I/F           I/F |  |       |    |
--    | | SWAP |  |  |  LINK  |  |    |                   |  | PHY   |    |
--    | |      |  |  |  FIFO  |  |    |                   |  | I/F   |    |
--    | |      |  |  |        |  |    |                   |  |       |    |
--    | |      |  |  |        |  |    | Rx            Rx  |  |       |    |
--    | |      |  |  |        |  |    | client        PHY |  |       |    |
--    | |      |<-|<-|        |<-|----| I/F           I/F |<-|       |<---|
--    | |      |  |  |        |  |    |                   |  ---------    |
--    | --------  |  ----------  |    ---------------------               |
--    |           |              -----------------------------------------|
--    |           --------------------------------------------------------|
--    ---------------------------------------------------------------------
--
--------------------------------------------------------------------------------


library unisim;
use unisim.vcomponents.all;

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

library work;
use work.eth_pkg.all;



-------------------------------------------------------------------------------
-- The entity declaration for the example design.
-------------------------------------------------------------------------------
entity eth_mii is
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
end eth_mii;


architecture TOP_LEVEL of eth_mii is

  ------------------------------------------------------------------------------
  -- Component Declaration for the Tri-Mode EMAC core LocalLink wrapper
  ------------------------------------------------------------------------------
  component mac_gmii_core_locallink
    port(
      -- asynchronous reset
      reset                : in  std_logic;

      -- Reference clock for IDELAYCTRL's
      refclk               : in  std_logic;

      -- Client Receiver Statistics Interface
      ---------------------------------------
      rx_clk               : out std_logic;
      rx_enable            : out std_logic;
      rx_statistics_vector : out std_logic_vector(27 downto 0);
      rx_statistics_valid  : out std_logic;

      -- Client Receiver (LocalLink) Interface
      ----------------------------------------
      rx_ll_clock          : in  std_logic;
      rx_ll_reset          : in  std_logic;
      rx_ll_data_out       : out std_logic_vector(7 downto 0);
      rx_ll_sof_out_n      : out std_logic;
      rx_ll_eof_out_n      : out std_logic;
      rx_ll_src_rdy_out_n  : out std_logic;
      rx_ll_dst_rdy_in_n   : in  std_logic;


      -- Client Transmitter Statistics Interface
      ------------------------------------------
      tx_clk               : out std_logic;
      tx_enable            : out std_logic;
      tx_ifg_delay         : in  std_logic_vector(7 downto 0);
      tx_statistics_vector : out std_logic_vector(31 downto 0);
      tx_statistics_valid  : out std_logic;

      -- Client Transmitter (LocalLink) Interface
      -------------------------------------------
      tx_ll_clock          : in  std_logic;
      tx_ll_reset          : in  std_logic;
      tx_ll_data_in        : in  std_logic_vector(7 downto 0);
      tx_ll_sof_in_n       : in  std_logic;
      tx_ll_eof_in_n       : in  std_logic;
      tx_ll_src_rdy_in_n   : in  std_logic;
      tx_ll_dst_rdy_out_n  : out std_logic;

      -- MAC Control Interface
      ------------------------
      pause_req            : in  std_logic;
      pause_val            : in  std_logic_vector(15 downto 0);

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

      -- Initial Unicast Address Value
      unicast_address      : in  std_logic_vector(47 downto 0);

      -- Configuration Vector
      -----------------------
      configuration_vector : in  std_logic_vector(67 downto 0)
      );
   end component;

  ------------------------------------------------------------------------------
  -- internal signals used in this top level example design.
  ------------------------------------------------------------------------------

  -- clock/reset generation signals
  signal gtpreset          : std_logic;                        -- System reset for tranceiver.
  signal clkin             : std_logic;                        -- tranceiver 125MHz clock, very high quality.
  signal userclk2          : std_logic;                        -- Routed to TXUSERCLK2 and RXUSERCLK2 of tranceiver.
  signal refclkout         : std_logic;                        -- tranceiver output clock made available to the FPGA fabric.


  -- Signals for the core connected to GTP0
  ------------------------------------------

--  signal sgmii_clk_r0      : std_logic;                        -- Clock to client MAC (125MHz, 12.5MHz or 1.25MHz) (to rising edge DDR).
--  signal sgmii_clk_f0      : std_logic;                        -- Clock to client MAC (125MHz, 12.5MHz or 1.25MHz) (to falling edge DDR).
--  signal gmii_isolate0     : std_logic;                        -- Internal gmii_isolate signal.
  signal gmii_txd_int0     : std_logic_vector(7 downto 0);     -- Internal gmii_txd signal (between core and SGMII adaptation module).
  signal gmii_tx_en_int0   : std_logic;                        -- Internal gmii_tx_en signal (between core and SGMII adaptation module).
  signal gmii_tx_er_int0   : std_logic;                        -- Internal gmii_tx_er signal (between core and SGMII adaptation module).
  signal gmii_rxd_int0     : std_logic_vector(7 downto 0);     -- Internal gmii_rxd signal (between core and SGMII adaptation module).
  signal gmii_rx_dv_int0   : std_logic;                        -- Internal gmii_rx_dv signal (between core and SGMII adaptation module).
  signal gmii_rx_er_int0   : std_logic;                        -- Internal gmii_rx_er signal (between core and SGMII adaptation module).
--  signal gmii_txd_adapt0   : std_logic_vector(7 downto 0);     -- Internal gmii_txd signal (between SGMII adaptation module and IOBs).

  signal configuration_vector0: std_logic_vector(4 downto 0);  -- Alternative to MDIO interface.
  signal an_interrupt0        : std_logic;                    -- Interrupt to processor to signal that Auto-Negotiation has completed
  signal an_adv_config_vector0: std_logic_vector(15 downto 0); -- Alternate interface to program REG4 (AN ADV)
  signal an_restart_config0   : std_logic;                     -- Alternate signal to modify AN restart bit in REG0
  signal link_timer_value0    : std_logic_vector(8 downto 0);  -- Programmable Auto-Negotiation Link Timer Control

  -- General IO's
  ---------------
  signal status_vector0       : std_logic_vector(15 downto 0); -- Core status.
--  signal reset0               : std_logic;                     -- Asynchronous reset for entire core.
  signal signal_detect0       : std_logic;                     -- Input from PMD to indicate presence of optical input.

  -- Speed Control
  ----------------
  signal speed0_is_10_100     : std_logic;                     -- Core should operate at either 10Mbps or 100Mbps speeds
  signal speed0_is_100        : std_logic;                     -- Core should operate at 100Mbps speed



  ------------------------------------------------------------------------------
  -- Component Declaration for the Core Block level wrapper.
  ------------------------------------------------------------------------------
   component gmii2sgmii_core_block
      generic (
      -- Set to 1 to Speed up the GTP simulation
      SIM_GTPRESET_SPEEDUP : integer   := 0
      );
      port(

      refclkout            : out std_logic;                    -- tranceiver output clock made available to the FPGA fabric.
      gtpreset             : in  std_logic;                    -- Full System GTP Reset

      --------------------------------------------------------------------------
      -- Core connected to GTP0
      --------------------------------------------------------------------------

      -- GMII Interface
      -----------------
      sgmii_clk_r0         : out std_logic;                    -- Clock for client MAC (125Mhz, 12.5MHz or 1.25MHz).
      sgmii_clk_f0         : out std_logic;                    -- Clock for client MAC (125Mhz, 12.5MHz or 1.25MHz).
      sgmii_clk_en0        : out std_logic;                    -- Clock enable for client MAC
      gmii_txd0            : in std_logic_vector(7 downto 0);  -- Transmit data from client MAC.
      gmii_tx_en0          : in std_logic;                     -- Transmit control signal from client MAC.
      gmii_tx_er0          : in std_logic;                     -- Transmit control signal from client MAC.
      gmii_rxd0            : out std_logic_vector(7 downto 0); -- Received Data to client MAC.
      gmii_rx_dv0          : out std_logic;                    -- Received control signal to client MAC.
      gmii_rx_er0          : out std_logic;                    -- Received control signal to client MAC.
      gmii_isolate0        : out std_logic;                    -- Tristate control to electrically isolate GMII.

      -- Management: Alternative to MDIO Interface
      --------------------------------------------
      configuration_vector0: in std_logic_vector(4 downto 0);  -- Alternative to MDIO interface.
      an_interrupt0        : out std_logic;                    -- Interrupt to processor to signal that Auto-Negotiation has completed
      an_adv_config_vector0: in std_logic_vector(15 downto 0); -- Alternate interface to program REG4 (AN ADV)
      an_restart_config0   : in std_logic;                     -- Alternate signal to modify AN restart bit in REG0
      link_timer_value0    : in std_logic_vector(8 downto 0);  -- Programmable Auto-Negotiation Link Timer Control

      -- General IO's
      ---------------
      status_vector0       : out std_logic_vector(15 downto 0); -- Core status.
      reset0               : in std_logic;                     -- Asynchronous reset for entire core.
      signal_detect0       : in std_logic;                     -- Input from PMD to indicate presence of optical input.

      -- Speed Control
      ----------------
      speed0_is_10_100     : in std_logic;                     -- Core should operate at either 10Mbps or 100Mbps speeds
      speed0_is_100        : in std_logic;                     -- Core should operate at 100Mbps speed


      --------------------------------------------------------------------------
      -- Tranceiver interfaces
      --------------------------------------------------------------------------

      clkin                : in std_logic;                     -- tranceiver 125MHz clock, very high quality.
      userclk2             : in std_logic;                     -- 125MHz reference clock for all core logic..

      txp0                 : out std_logic;                    -- Differential +ve of serial transmission from PMA to PMD.
      txn0                 : out std_logic;                    -- Differential -ve of serial transmission from PMA to PMD.
      rxp0                 : in std_logic;                     -- Differential +ve for serial reception from PMD to PMA.
      rxn0                 : in std_logic;                     -- Differential -ve for serial reception from PMD to PMA.

      txp1                 : out std_logic;                    -- Differential +ve of serial transmission from PMA to PMD.
      txn1                 : out std_logic;                    -- Differential -ve of serial transmission from PMA to PMD.
      rxp1                 : in std_logic;                     -- Differential +ve for serial reception from PMD to PMA.
      rxn1                 : in std_logic                      -- Differential -ve for serial reception from PMD to PMA.

      );

   end component;

  ------------------------------------------------------------------------------
  -- internal signals used in this example_design level wrapper.
  ------------------------------------------------------------------------------

  signal tx_clk_int        : std_logic;      -- Internal Tx core clock signal.
  signal rx_clk_int        : std_logic;      -- Internal Rx core clock signal


  signal refclk_bufg       : std_logic;      -- refclk routed through a BUFG.
--  signal rx_enable_int     : std_logic;      -- Rx clock enable
--  signal tx_enable_int     : std_logic;      -- Tx clock enable

  -- Tx LocalLink FIFO I/F
  signal tx_reset          : std_logic;
  signal tx_ll_clk         : std_logic;
  signal tx_ll_pre_reset   : std_logic_vector(5 downto 0);
  signal tx_ll_reset       : std_logic;
--  signal tx_ll_data        : std_logic_vector(7 downto 0);
--  signal tx_ll_sof_n       : std_logic;
--  signal tx_ll_eof_n       : std_logic;
--  signal tx_ll_src_rdy_n   : std_logic;
--  signal tx_ll_dst_rdy_n   : std_logic;

  -- Rx LocalLink FIFO I/F
  signal rx_ll_clk         : std_logic;
  signal rx_ll_reset       : std_logic;
--  signal rx_ll_data        : std_logic_vector(7 downto 0);
--  signal rx_ll_sof_n       : std_logic;
--  signal rx_ll_eof_n       : std_logic;
--  signal rx_ll_src_rdy_n   : std_logic;
--  signal rx_ll_dst_rdy_n   : std_logic;

--  -- Internal and Registered versions of Tx and Rx Statistic Vectors
--  signal rx_statistics_vector_int : std_logic_vector(27 downto 0);
--  signal rx_statistics_valid_int  : std_logic;
--  signal tx_statistics_vector_int : std_logic_vector(31 downto 0);
--  signal tx_statistics_valid_int  : std_logic;
--  signal rx_statistics_valid_reg  : std_logic_vector(27 downto 0);
--  signal rx_statistics_vector_reg : std_logic_vector(27 downto 0);
--  signal tx_statistics_valid_reg  : std_logic_vector(31 downto 0);
--  signal tx_statistics_vector_reg : std_logic_vector(31 downto 0);
--
--  signal pause_val_reg            : std_logic_vector(15 downto 0);
--  signal pause_req_reg            : std_logic_vector(15 downto 0);

  signal unicast_address          : std_logic_vector(47 downto 0) := X"0605040302DA";
  attribute keep of unicast_address : signal is "true";


  -- GMII Interface
  -----------------
  signal gtx_clk              : std_logic;
  signal gmii_txd             : std_logic_vector(7 downto 0);
  signal gmii_tx_en           : std_logic;
  signal gmii_tx_er           : std_logic;
  signal gmii_tx_clk          : std_logic;
  signal gmii_rxd             : std_logic_vector(7 downto 0);
  signal gmii_rx_dv           : std_logic;
  signal gmii_rx_er           : std_logic;
  signal gmii_rx_clk          : std_logic;
  signal mii_tx_clk           : std_logic;



-----------
component eth_mdio_main
generic(
G_PHY_ADR : integer:=16#07#;
G_PHY_ID  : std_logic_vector(11 downto 0):="000011001100";
G_DIV : integer:=2; --Делитель частоты p_in_clk. Нужен для формирования сигнала MDC
G_DBG : string:="OFF";
G_SIM : string:="OFF"
);
port(
--------------------------------------
--Управление
--------------------------------------
p_out_phy_rst      : out   std_logic;
p_out_phy_err      : out   std_logic;
p_out_phy_link     : out   std_logic;
p_out_phy_cfg_done : out   std_logic;

--------------------------------------
--Eth PHY (Managment Interface)
--------------------------------------
--p_inout_mdio   : inout  std_logic;
--p_out_mdc      : out    std_logic;
p_out_mdio_t   : out    std_logic;
p_out_mdio     : out    std_logic;
p_in_mdio      : in     std_logic;
p_out_mdc      : out    std_logic;

--------------------------------------------------
--Технологические сигналы
--------------------------------------------------
p_in_tst       : in    std_logic_vector(31 downto 0);
p_out_tst      : out   std_logic_vector(31 downto 0);

--------------------------------------
--SYSTEM
--------------------------------------
p_in_clk       : in    std_logic;
p_in_rst       : in    std_logic
);
end component;

signal i_PHYAD,i_PHYAD_1       : std_logic_vector(4 downto 0);
signal i_CLIENTEMACTXIFGDELAY    : std_logic_vector(7 downto 0);

signal i_phy_rst                 : std_logic;
signal i_phy_err                 : std_logic;
signal i_phy_link                : std_logic;
signal i_phy_cfg_done            : std_logic;


-------------------------------------------------------------------------------
-- Main Body of Code
-------------------------------------------------------------------------------


begin

p_out_tst <=(others=>'0');
i_PHYAD_1<=CONV_STD_LOGIC_VECTOR(16#02#, i_PHYAD'length);
i_PHYAD<=CONV_STD_LOGIC_VECTOR(16#01#, i_PHYAD'length);
i_CLIENTEMACTXIFGDELAY<=CONV_STD_LOGIC_VECTOR(16#0D#, i_CLIENTEMACTXIFGDELAY'length);

p_out_phy.link<=i_phy_link and i_phy_cfg_done;
p_out_phy.rdy<=not i_phy_err and i_phy_cfg_done;
p_out_phy.clk<=tx_clk_int;
p_out_phy.rst<=i_phy_rst;
p_out_phy.opt(C_ETHPHY_OPTOUT_RST_BIT)<=ll_reset_0_i;

reset<=p_in_rst;
clkin<=p_in_phy.clk;
refclk_bufg<=p_in_phy.clk; --REFCLK
--  RGMII_RXC_0<=p_in_phy.pin.rgmii(0).rxc;

m_mdio_ctrl : eth_mdio_main
generic map(
G_PHY_ADR => 16#07#,
G_PHY_ID  => "000011001100", --ID for chip Marvel 88E1111
G_DIV => 16,
G_DBG => "OFF",
G_SIM => "OFF"
)
port map(
--------------------------------------
--Управление
--------------------------------------
p_out_phy_rst      => i_phy_rst,
p_out_phy_err      => i_phy_err,
p_out_phy_link     => i_phy_link,
p_out_phy_cfg_done => i_phy_cfg_done,

--------------------------------------
--Eth PHY (Managment Interface)
--------------------------------------
--p_inout_mdio   => pin_inout_ethphy_mdio,
--p_out_mdc      => pin_out_ethphy_mdc,
p_out_mdio_t   => p_out_phy.mdio_t,
p_out_mdio     => p_out_phy.mdio,
p_in_mdio      => p_in_phy.mdio,
p_out_mdc      => p_out_phy.mdc,

--------------------------------------------------
--Технологические сигналы
--------------------------------------------------
p_in_tst       => (others=>'0'),
p_out_tst      => open,

--------------------------------------
--SYSTEM
--------------------------------------
p_in_clk       => ll_clk_0_i,
p_in_rst       => p_in_rst
);


configuration_vector(47 downto 0) <= (others=>'0'); --Pause frame MAC Source Address[47:0]
configuration_vector(48) <= '0'; --Receiver in half-duplex mode/ full-duplex mode (1/0)
configuration_vector(49) <= '0'; --Receiver VLAN Enable
configuration_vector(50) <= sgmii_clk_en0; --Receiver Enable
configuration_vector(51) <= '0'; --Receiver does pass/not pass the FCS field (1/0)
configuration_vector(52) <= '0'; --Receiver Jumbo Frame Enable
configuration_vector(53) <= '0'; --Receiver Reset
configuration_vector(54) <= '1'; --Transmitter Interframe Gap Adjust Enable
configuration_vector(55) <= '0'; --Transmitter Half Duplex
configuration_vector(56) <= '0'; --Transmitter VLAN Enable
configuration_vector(57) <= sgmii_clk_en0; --Transmitter Enable
configuration_vector(58) <= '0'; --transmitter appends padding as required,
                                 --compute the FCS and append it to the frame
configuration_vector(59) <= '0'; --Transmitter Jumbo Frame Enable
configuration_vector(60) <= '0'; --Transmitter Reset
configuration_vector(61) <= '0'; --Transmit Flow Control Enable
configuration_vector(62) <= '0'; --Receive Flow Control Enable
configuration_vector(63) <= '0'; --Length/Type Error Check Disable
configuration_vector(64) <= '0'; --Address Filter Enable
configuration_vector(66 downto 65) <= "10"; --MAC Speed 00/01/10 - 10/100/1000 Mb/s
configuration_vector(67) <= '0'; --Control Frame Length Check Disable


--  ------------------------------------------------------------------------------
--  -- REFCLK used for IODELAYCTRL primitive : Need to supply a 200MHz clock
--  ------------------------------------------------------------------------------
--  refclk_bufg_i  : BUFG  port map(I => refclk, O => refclk_bufg);
  refclk <= refclk_bufg;

  -----------------------------------------------------------------------------
  -- Create synchronous reset signal for use in this and the address swapping
  -- module.
  -- NOTE: this reset has to be at least 6 cycles long to ensure the pipeline
  --       through the address swap module has fully cleared
  -----------------------------------------------------------------------------

  -- Create synchronous reset in the transmitter clock domain.
   tx_reset_gen : reset_sync
   port map(
      clk            => tx_clk_int,
      enable         => '1',
      reset_in       => reset,
      reset_out      => tx_reset
   );

  -- Create fully synchronous reset in the LocalLink transmitter clock domain.
  gen_tx_reset : process (tx_clk_int)
  begin
    if tx_clk_int'event and tx_clk_int = '1' then
       if tx_reset = '1' then
         tx_ll_pre_reset <= (others => '1');
         tx_ll_reset     <= '1';
       else
         tx_ll_pre_reset(0)          <= '0';
         tx_ll_pre_reset(5 downto 1) <= tx_ll_pre_reset(4 downto 0);
         tx_ll_reset                 <= tx_ll_pre_reset(5);
       end if;
    end if;
  end process gen_tx_reset;

  ------------------------------------------------------------------------------
  -- LocalLink FIFO Clock and Reset assignments
  ------------------------------------------------------------------------------

  -- Please note that the LocalLink FIFO is used with a common clock for Tx and
  -- Rx interfaces
  tx_ll_clk <= tx_clk_int;
  rx_ll_clk <= tx_clk_int;

  -- Due to the common clock, the FIFO synchronous resets can share the reset
  -- source
  rx_ll_reset <= tx_ll_reset;

--  ------------------------------------------------------------------------------
--  -- Prepare the Rx statistic vector for IOB's
--  ------------------------------------------------------------------------------
--
--  serialize_rx_stats : process(rx_clk_int)
--  begin
--    if (rx_clk_int'event and rx_clk_int = '1') then
--       if rx_statistics_valid_int = '1' then
--          rx_statistics_valid_reg  <= rx_statistics_valid_reg(26 downto 0) & rx_statistics_valid_int;
--          rx_statistics_vector_reg <= rx_statistics_vector_int;
--       else
--          rx_statistics_valid_reg  <= rx_statistics_valid_reg(26 downto 0) & '0';
--          rx_statistics_vector_reg <= rx_statistics_vector_reg(26 downto 0) & '0';
--       end if;
--    end if;
--  end process;
--
--  -- Route Statistics to Output ports
-- rx_statistics_vector <= rx_statistics_vector_reg(27);
--
-- rx_statistics_valid <= rx_statistics_valid_reg(27);

  ------------------------------------------------------------------------------
  -- Instantiate the Tri-Mode EMAC core LocalLink wrapper
  ------------------------------------------------------------------------------
  m_trimac_locallink : mac_gmii_core_locallink
    port map (
      -- asynchronous reset
      reset                 => reset,       --: in  std_logic;

      -- Reference clock for IDELAYCTRL's
      refclk                => refclk_bufg, --: in  std_logic;

      -- Client Receiver Statistics Interface
      rx_clk                => open,--rx_clk_int,               --: out std_logic;
      rx_enable             => open,--rx_enable_int,            --: out std_logic;
      rx_statistics_vector  => open,--rx_statistics_vector_int, --: out std_logic_vector(27 downto 0);
      rx_statistics_valid   => open,--rx_statistics_valid_int,  --: out std_logic;

      -- Client Receiver (LocalLink) Interface
      rx_ll_clock           => rx_ll_clk,       --: in  std_logic;
      rx_ll_reset           => rx_ll_reset,     --: in  std_logic;
      rx_ll_data_out        => p_out_phy2app(0).rxd(G_ETH.phy_dwidth-1 downto 0),--rx_ll_data,      --: out std_logic_vector(7 downto 0);
      rx_ll_sof_out_n       => p_out_phy2app(0).rxsof_n,                         --rx_ll_sof_n,     --: out std_logic;
      rx_ll_eof_out_n       => p_out_phy2app(0).rxeof_n,                         --rx_ll_eof_n,     --: out std_logic;
      rx_ll_src_rdy_out_n   => p_out_phy2app(0).rxsrc_rdy_n,                     --rx_ll_src_rdy_n, --: out std_logic;
      rx_ll_dst_rdy_in_n    => p_in_phy2app (0).rxdst_rdy_n,                     --rx_ll_dst_rdy_n, --: in  std_logic;

      -- Client Transmitter Statistics Interface
      tx_clk                => tx_clk_int,             --: out std_logic;
      tx_enable             => open,                   --: out std_logic;
      tx_ifg_delay          => i_CLIENTEMACTXIFGDELAY, --: in  std_logic_vector(7 downto 0);
      tx_statistics_vector  => open,                   --: out std_logic_vector(31 downto 0);
      tx_statistics_valid   => open,                   --: out std_logic;

      -- Client Transmitter (LocalLink) Interface
      tx_ll_clock           => tx_ll_clk,       --: in  std_logic;
      tx_ll_reset           => tx_ll_reset,     --: in  std_logic;
      tx_ll_data_in         => p_in_phy2app (0).txd(G_ETH.phy_dwidth-1 downto 0),--tx_ll_data,      --: in  std_logic_vector(7 downto 0);
      tx_ll_sof_in_n        => p_in_phy2app (0).txsof_n,                         --tx_ll_sof_n,     --: in  std_logic;
      tx_ll_eof_in_n        => p_in_phy2app (0).txeof_n,                         --tx_ll_eof_n,     --: in  std_logic;
      tx_ll_src_rdy_in_n    => p_in_phy2app (0).txsrc_rdy_n,                     --tx_ll_src_rdy_n, --: in  std_logic;
      tx_ll_dst_rdy_out_n   => p_out_phy2app(0).txdst_rdy_n,                     --tx_ll_dst_rdy_n, --: out std_logic;

      -- Flow Control
      pause_req             => '0',            --: in  std_logic;
      pause_val             => (others=>'0'),  --: in  std_logic_vector(15 downto 0);

      -- GMII Interface
      gtx_clk               => gtx_clk,      --: in  std_logic;
      gmii_txd              => gmii_txd,     --: out std_logic_vector(7 downto 0);
      gmii_tx_en            => gmii_tx_en,   --: out std_logic;
      gmii_tx_er            => gmii_tx_er,   --: out std_logic;
      gmii_tx_clk           => gmii_tx_clk,  --: out std_logic;
      gmii_rxd              => gmii_rxd,     --: in  std_logic_vector(7 downto 0);
      gmii_rx_dv            => gmii_rx_dv,   --: in  std_logic;
      gmii_rx_er            => gmii_rx_er,   --: in  std_logic;
      gmii_rx_clk           => gmii_rx_clk,  --: in  std_logic;
      mii_tx_clk            => mii_tx_clk,   --: in  std_logic;

      -- Initial Unicast Address Value
      unicast_address       => unicast_address, --: in  std_logic_vector(47 downto 0);

      -- Configuration Vector
      configuration_vector  => configuration_vector --: in  std_logic_vector(67 downto 0)
    );



    gtx_clk <= refclkout;

    signal_detect0 <= '1';
    --1Gb/s
    speed0_is_10_100 <= '0';
    speed0_is_100    <= '0';

    configuration_vector0(1 downto 0) <= (others => '0');   -- Disable Loopback
    configuration_vector0(2)          <= '0';               -- Disable POWERDOWN
    configuration_vector0(3)          <= '0';               -- Disable ISOLATE
    configuration_vector0(4)          <= '0';               -- Enable AN

    an_adv_config_vector0 <= "0000000000100001";
    an_restart_config0    <= '0';
    -- The link timer value is here set at 1.64 ms (please refer to the
    -- core's User Manual).
    link_timer_value0  <= "000110010";


   -----------------------------------------------------------------------------
   -- Virtex-5 Rocket System Reset
   -----------------------------------------------------------------------------

   -- Generate an asynchronous reset pulse for the GTP tranceiver
   gtpreset_gen : gmii2sgmii_core_reset_sync
   port map(
      clk       => userclk2,
      reset_in  => reset,--reset0,
      reset_out => gtpreset
   );

   -----------------------------------------------------------------------------
   -- Virtex-5 Rocket I/O Clock Management
   -----------------------------------------------------------------------------

--   -- NOTE: BREFCLK circuitry for the Rocket I/O requires the use of a
--   -- 125MHz differential input clock.  clkin is routed to the tranceiver
--   -- pair.
--
--   clkingen : IBUFDS
--   port map (
--      I  => brefclk_p,
--      IB => brefclk_n,
--      O  => clkin
--   );


   -- refclkout (125MHz) is made avaiable by the tranceiver to the FPGA
   -- fabric. This is placed onto global clock routing and is then used
   -- for tranceiver TXUSRCLK2/RXUSRCLK2 and used to clock all Ethernet
   -- core logic.

   bufg_clk125m : BUFG
   port map (
      I => refclkout,
      O => userclk2
   );

  ------------------------------------------------------------------------------
  -- Instantiate the Core Block level wrapper.
  ------------------------------------------------------------------------------

  m_gmii2sgmii_core : gmii2sgmii_core_block
    generic map
    (
      -- Simulation attribute: this setting does not affect the hardware
      -- It is a Smartmodel setting only.  Setting it to 1 reduces the
      -- simulation time required for the GTP to intialise.
      SIM_GTPRESET_SPEEDUP => 1
    )
    port map (

      refclkout            => refclkout,
      gtpreset             => gtpreset,

      sgmii_clk_r0         => open,--sgmii_clk_r0,    --: out std_logic;
      sgmii_clk_f0         => open,--sgmii_clk_f0,    --: out std_logic;
      sgmii_clk_en0        => sgmii_clk_en0,            --: out std_logic;
      gmii_txd0            => gmii_txd_int0,   --: in std_logic_vector(7 downto 0);
      gmii_tx_en0          => gmii_tx_en_int0, --: in std_logic;
      gmii_tx_er0          => gmii_tx_er_int0, --: in std_logic;
      gmii_rxd0            => gmii_rxd_int0,   --: out std_logic_vector(7 downto 0);
      gmii_rx_dv0          => gmii_rx_dv_int0, --: out std_logic;
      gmii_rx_er0          => gmii_rx_er_int0, --: out std_logic;
      gmii_isolate0        => open,--gmii_isolate0,   --: out std_logic;
--      mdc0                 => mdc0,
--      mdio0_i              => mdio0_i,
--      mdio0_o              => mdio0_o,
--      mdio0_t              => mdio0_t,
--      phyad0               => phyad0,
      configuration_vector0=> configuration_vector0, --: in std_logic_vector(4 downto 0);
--      configuration_valid0 => configuration_valid0,
      an_interrupt0        => an_interrupt0,         --: out std_logic;
      an_adv_config_vector0=> an_adv_config_vector0, --: in std_logic_vector(15 downto 0);
--      an_adv_config_val0   => an_adv_config_val0,
      an_restart_config0   => an_restart_config0,    --: in std_logic;
      link_timer_value0    => link_timer_value0,     --: in std_logic_vector(8 downto 0);
      status_vector0       => status_vector0,        --: out std_logic_vector(15 downto 0);
      reset0               => reset,--reset0,        --: in std_logic;
      signal_detect0       => signal_detect0,        --: in std_logic;
      speed0_is_10_100     => speed0_is_10_100,      --: in std_logic;
      speed0_is_100        => speed0_is_100,         --: in std_logic;

      clkin                => clkin,
      userclk2             => userclk2,

      txp0                 => p_out_phy.pin.sgmii.txp(0), --txp0,
      txn0                 => p_out_phy.pin.sgmii.txn(0), --txn0,
      rxp0                 => p_in_phy.pin.sgmii.rxp(0),  --rxp0,
      rxn0                 => p_in_phy.pin.sgmii.rxn(0),  --rxn0,
      txp1                 => p_out_phy.pin.sgmii.txp(1), --txp1,
      txn1                 => p_out_phy.pin.sgmii.txn(1), --txn1,
      rxp1                 => p_in_phy.pin.sgmii.rxp(1),  --rxp1,
      rxn1                 => p_in_phy.pin.sgmii.rxn(1)  --rxn1

      );

   -----------------------------------------------------------------------------
   -- GMII logic for the core connected to GTP0
   -----------------------------------------------------------------------------


   -- GMII transmitter data logic
   -------------------------------

   -- Drive input GMII signals through IOB input flip-flops (inferred).
   process (userclk2)
   begin
      if userclk2'event and userclk2 = '1' then
         gmii_txd_int0    <= gmii_txd;
         gmii_tx_en_int0  <= gmii_tx_en;
         gmii_tx_er_int0  <= gmii_tx_er;

      end if;
   end process;



--   -- SGMII clock logic
--   --------------------
--
--   -- All GMII transmitter input signals must be synchronous to this
--   -- clock.
--
--   -- All GMII receiver output signals are synchrounous to this clock.
--
--   -- This instantiates a DDR output register.  This is a nice way to
--   -- drive the output clock since the clock-to-PAD delay will the
--   -- same as that of data driven from an IOB Ouput flip-flop.
--
--   sgclk_ddr_iob0 : ODDR
--   port map(
--      Q  => sgmii_clk0,
--      C  => userclk2,
--      CE => '1',
--      D1 => sgmii_clk_r0,
--      D2 => sgmii_clk_f0,
--      R  => '0',
--      S  => '0'
--   );



   -- GMII receiver data logic
   ---------------------------

   -- Drive input GMII signals through IOB output flip-flops (inferred).
   process (userclk2)
   begin
      if userclk2'event and userclk2 = '1' then
         gmii_rxd    <= gmii_rxd_int0;
         gmii_rx_dv  <= gmii_rx_dv_int0;
         gmii_rx_er  <= gmii_rx_er_int0;

      end if;
   end process;

end TOP_LEVEL;
