-------------------------------------------------------------------------------
-- Title      : Virtex-5 Ethernet MAC Example Design Wrapper
-- Project    : Virtex-5 Embedded Tri-Mode Ethernet MAC Wrapper
-- File       : emac_core_rgmii_example_design.vhd
-- Version    : 1.8
-------------------------------------------------------------------------------
--
-- (c) Copyright 2004-2010 Xilinx, Inc. All rights reserved.
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
--
-------------------------------------------------------------------------------
-- Description:  This is the VHDL example design for the Virtex-5
--               Embedded Ethernet MAC.  It is intended that
--               this example design can be quickly adapted and downloaded onto
--               an FPGA to provide a real hardware test environment.
--
--               This level:
--
--               * instantiates the TEMAC local link file that instantiates
--                 the TEMAC top level together with a RX and TX FIFO with a
--                 local link interface;
--
--               * instantiates a simple client I/F side example design,
--                 providing an address swap and a simple
--                 loopback function;
--
--               * Instantiates IBUFs on the GTX_CLK, REFCLK and HOSTCLK inputs
--                 if required;
--
--               Please refer to the Datasheet, Getting Started Guide, and
--               the Virtex-5 Embedded Tri-Mode Ethernet MAC User Gude for
--               further information.
--
--
--
--    ---------------------------------------------------------------------
--    | EXAMPLE DESIGN WRAPPER                                            |
--    |           --------------------------------------------------------|
--    |           |LOCAL LINK WRAPPER                                     |
--    |           |              -----------------------------------------|
--    |           |              |BLOCK LEVEL WRAPPER                     |
--    |           |              |    ---------------------               |
--    | --------  |  ----------  |    | ETHERNET MAC      |               |
--    | |      |  |  |        |  |    | WRAPPER           |  ---------    |
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
-------------------------------------------------------------------------------


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

--      -- Client Receiver Interface - EMAC0
--      EMAC0CLIENTRXDVLD               : out std_logic;
--      EMAC0CLIENTRXFRAMEDROP          : out std_logic;
--      EMAC0CLIENTRXSTATS              : out std_logic_vector(6 downto 0);
--      EMAC0CLIENTRXSTATSVLD           : out std_logic;
--      EMAC0CLIENTRXSTATSBYTEVLD       : out std_logic;
--
--      -- Client Transmitter Interface - EMAC0
--      CLIENTEMAC0TXIFGDELAY           : in  std_logic_vector(7 downto 0);
--      EMAC0CLIENTTXSTATS              : out std_logic;
--      EMAC0CLIENTTXSTATSVLD           : out std_logic;
--      EMAC0CLIENTTXSTATSBYTEVLD       : out std_logic;
--
--      -- MAC Control Interface - EMAC0
--      CLIENTEMAC0PAUSEREQ             : in  std_logic;
--      CLIENTEMAC0PAUSEVAL             : in  std_logic_vector(15 downto 0);
--
--
--      -- Clock Signals - EMAC0
--      GTX_CLK_0                       : in  std_logic;
--
--      -- RGMII Interface - EMAC0
--      RGMII_TXD_0                     : out std_logic_vector(3 downto 0);
--      RGMII_TX_CTL_0                  : out std_logic;
--      RGMII_TXC_0                     : out std_logic;
--      RGMII_RXD_0                     : in  std_logic_vector(3 downto 0);
--      RGMII_RX_CTL_0                  : in  std_logic;
--      RGMII_RXC_0                     : in  std_logic;
--
--      -- Reference clock for RGMII IODELAYs
--      REFCLK                          : in  std_logic;
--
--
--      -- Asynchronous Reset
--      RESET                           : in  std_logic
   );
end eth_mii;


architecture TOP_LEVEL of eth_mii is

-------------------------------------------------------------------------------
-- Component Declarations for lower hierarchial level entities
-------------------------------------------------------------------------------
  -- Component Declaration for the TEMAC wrapper with
  -- Local Link FIFO.
  component emac_core_rgmii_locallink is
   port(
      -- EMAC0 Clocking
      -- TX Clock output from EMAC
      TX_CLK_OUT                       : out std_logic;
      -- EMAC0 TX Clock input from BUFG
      TX_CLK_0                         : in  std_logic;

      -- Local link Receiver Interface - EMAC0
      RX_LL_CLOCK_0                   : in  std_logic;
      RX_LL_RESET_0                   : in  std_logic;
      RX_LL_DATA_0                    : out std_logic_vector(7 downto 0);
      RX_LL_SOF_N_0                   : out std_logic;
      RX_LL_EOF_N_0                   : out std_logic;
      RX_LL_SRC_RDY_N_0               : out std_logic;
      RX_LL_DST_RDY_N_0               : in  std_logic;
      RX_LL_FIFO_STATUS_0             : out std_logic_vector(3 downto 0);

      -- Local link Transmitter Interface - EMAC0
      TX_LL_CLOCK_0                   : in  std_logic;
      TX_LL_RESET_0                   : in  std_logic;
      TX_LL_DATA_0                    : in  std_logic_vector(7 downto 0);
      TX_LL_SOF_N_0                   : in  std_logic;
      TX_LL_EOF_N_0                   : in  std_logic;
      TX_LL_SRC_RDY_N_0               : in  std_logic;
      TX_LL_DST_RDY_N_0               : out std_logic;

      -- Client Receiver Interface - EMAC0
      EMAC0CLIENTRXDVLD               : out std_logic;
      EMAC0CLIENTRXFRAMEDROP          : out std_logic;
      EMAC0CLIENTRXSTATS              : out std_logic_vector(6 downto 0);
      EMAC0CLIENTRXSTATSVLD           : out std_logic;
      EMAC0CLIENTRXSTATSBYTEVLD       : out std_logic;

      -- Client Transmitter Interface - EMAC0
      CLIENTEMAC0TXIFGDELAY           : in  std_logic_vector(7 downto 0);
      EMAC0CLIENTTXSTATS              : out std_logic;
      EMAC0CLIENTTXSTATSVLD           : out std_logic;
      EMAC0CLIENTTXSTATSBYTEVLD       : out std_logic;

      -- MAC Control Interface - EMAC0
      CLIENTEMAC0PAUSEREQ             : in  std_logic;
      CLIENTEMAC0PAUSEVAL             : in  std_logic_vector(15 downto 0);


      -- Clock Signals - EMAC0
      GTX_CLK_0                       : in  std_logic;

      -- RGMII Interface - EMAC0
      RGMII_TXD_0                     : out std_logic_vector(3 downto 0);
      RGMII_TX_CTL_0                  : out std_logic;
      RGMII_TXC_0                     : out std_logic;
      RGMII_RXD_0                     : in  std_logic_vector(3 downto 0);
      RGMII_RX_CTL_0                  : in  std_logic;
      RGMII_RXC_0                     : in  std_logic;



      -- Asynchronous Reset
      RESET                           : in  std_logic
   );
  end component;

   ---------------------------------------------------------------------
   --  Component Declaration for 8-bit address swapping module
   ---------------------------------------------------------------------
   component address_swap_module_8
   port (
      rx_ll_clock         : in  std_logic;                     -- Input CLK from MAC Reciever
      rx_ll_reset         : in  std_logic;                     -- Synchronous reset signal
      rx_ll_data_in       : in  std_logic_vector(7 downto 0);  -- Input data
      rx_ll_sof_in_n      : in  std_logic;                     -- Input start of frame
      rx_ll_eof_in_n      : in  std_logic;                     -- Input end of frame
      rx_ll_src_rdy_in_n  : in  std_logic;                     -- Input source ready
      rx_ll_data_out      : out std_logic_vector(7 downto 0);  -- Modified output data
      rx_ll_sof_out_n     : out std_logic;                     -- Output start of frame
      rx_ll_eof_out_n     : out std_logic;                     -- Output end of frame
      rx_ll_src_rdy_out_n : out std_logic;                     -- Output source ready
      rx_ll_dst_rdy_in_n  : in  std_logic                      -- Input destination ready
      );
   end component;

-----------------------------------------------------------------------
-- Signal Declarations
-----------------------------------------------------------------------

    -- Global asynchronous reset
    signal reset_i               : std_logic;

    -- client interface clocking signals - EMAC0
    signal ll_clk_0_i            : std_logic;

    -- address swap transmitter connections - EMAC0
    signal tx_ll_data_0_i      : std_logic_vector(7 downto 0);
    signal tx_ll_sof_n_0_i     : std_logic;
    signal tx_ll_eof_n_0_i     : std_logic;
    signal tx_ll_src_rdy_n_0_i : std_logic;
    signal tx_ll_dst_rdy_n_0_i : std_logic;

   -- address swap receiver connections - EMAC0
    signal rx_ll_data_0_i           : std_logic_vector(7 downto 0);
    signal rx_ll_sof_n_0_i          : std_logic;
    signal rx_ll_eof_n_0_i          : std_logic;
    signal rx_ll_src_rdy_n_0_i      : std_logic;
    signal rx_ll_dst_rdy_n_0_i      : std_logic;

    -- create a synchronous reset in the transmitter clock domain
    signal ll_pre_reset_0_i          : std_logic_vector(5 downto 0);
    signal ll_reset_0_i              : std_logic;

    attribute async_reg : string;
    attribute async_reg of ll_pre_reset_0_i : signal is "true";


    -- Reference clock for RGMII IODELAYs
    signal refclk_ibufg_i            : std_logic;
    signal refclk_bufg_i             : std_logic;

    -- EMAC0 Clocking signals

    -- RGMII input clocks to wrappers
    signal tx_clk_0                  : std_logic;
    signal rx_clk_0_i                : std_logic;
    signal rgmii_rxc_0_delay         : std_logic;

    -- IDELAY controller
    signal idelayctrl_reset_0_r      : std_logic_vector(12 downto 0);
    signal idelayctrl_reset_0_i      : std_logic;

    -- Setting attribute for RGMII/GMII IDELAY
    -- For more information on IDELAYCTRL and IDELAY, please refer to
    -- the Virtex-5 User Guide.
    attribute syn_noprune              : boolean;
    attribute syn_noprune of dlyctrl0  : label is true;


    attribute buffer_type : string;
    signal gtx_clk_0_i               : std_logic;
    attribute buffer_type of gtx_clk_0_i  : signal is "none";

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

signal RGMII_RXC_0               : std_logic;
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

i_CLIENTEMACTXIFGDELAY<=CONV_STD_LOGIC_VECTOR(16#0D#, i_CLIENTEMACTXIFGDELAY'length);

p_out_phy.link<=i_phy_link and i_phy_cfg_done;
p_out_phy.rdy<=not i_phy_err and i_phy_cfg_done;
p_out_phy.clk<=ll_clk_0_i;
p_out_phy.rst<=i_phy_rst;
p_out_phy.opt(C_ETHPHY_OPTOUT_RST_BIT)<=idelayctrl_reset_0_i;

reset_i<=p_in_rst;
gtx_clk_0_i<=p_in_phy.clk; --GTX_CLK_0
refclk_ibufg_i<=p_in_phy.clk; --REFCLK
RGMII_RXC_0<=p_in_phy.pin.rgmii(0).rxc;

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
    ---------------------------------------------------------------------------
    -- Reset Input Buffer
    ---------------------------------------------------------------------------
--    reset_ibuf : IBUF port map (I => RESET, O => reset_i);

    -- EMAC0 Clocking

    -- Use IDELAY on RGMII_RXC_0 to move the clock into
    -- alignment with the data

    -- Instantiate IDELAYCTRL for the IDELAY in Fixed Tap Delay Mode
    dlyctrl0 : IDELAYCTRL port map (
        RDY    => open,
        REFCLK => refclk_bufg_i,
        RST    => idelayctrl_reset_0_i
        );

    delay0rstgen :process (refclk_bufg_i, reset_i)
    begin
      if (reset_i = '1') then
        idelayctrl_reset_0_r(0)           <= '0';
        idelayctrl_reset_0_r(12 downto 1) <= (others => '1');
      elsif refclk_bufg_i'event and refclk_bufg_i = '1' then
        idelayctrl_reset_0_r(0)           <= '0';
        idelayctrl_reset_0_r(12 downto 1) <= idelayctrl_reset_0_r(11 downto 0);
      end if;
    end process delay0rstgen;

    idelayctrl_reset_0_i <= idelayctrl_reset_0_r(12);

    -- Please modify the value of the IOBDELAYs according to your design.
    -- For more information on IDELAYCTRL and IODELAY, please refer to
    -- the Virtex-5 User Guide.
    rgmii_rxc0_delay : IODELAY
    generic map (
        IDELAY_TYPE    => "FIXED",
       	IDELAY_VALUE   => 0,
        DELAY_SRC      => "I",
        SIGNAL_PATTERN => "CLOCK"
        )
    port map (
        IDATAIN    => RGMII_RXC_0,
        ODATAIN    => '0',
        DATAOUT    => rgmii_rxc_0_delay,
        DATAIN     => '0',
        C          => '0',
        T          => '0',
        CE         => '0',
        INC        => '0',
        RST        => '0'
        );


    -- Put the 125MHz reference clock through a BUFG.
    -- Used to clock the TX section of the EMAC wrappers.
    -- This clock can be shared between multiple MAC instances.
    bufg_tx_0 : BUFG port map (I => gtx_clk_0_i, O => tx_clk_0);

    -- Put the RX PHY clock through a BUFG.
    -- Used to clock the RX section of the EMAC wrappers.
    bufg_rx_0 : BUFG port map (I => rgmii_rxc_0_delay, O => rx_clk_0_i);

    ll_clk_0_i <= tx_clk_0;


    ------------------------------------------------------------------------
    -- Instantiate the EMAC Wrapper with LL FIFO
    -- (emac_core_rgmii_locallink.v)
    ------------------------------------------------------------------------
    m_emac_ll : emac_core_rgmii_locallink
    port map (
      -- EMAC0 Clocking
      -- TX Clock output from EMAC
      TX_CLK_OUT                      => open,
      -- EMAC0 TX Clock input from BUFG
      TX_CLK_0                        => tx_clk_0,
      -- Local link Receiver Interface - EMAC0
      RX_LL_CLOCK_0                   => ll_clk_0_i,
      RX_LL_RESET_0                   => ll_reset_0_i,
      RX_LL_DATA_0                    => p_out_phy2app(0).rxd(G_ETH.phy_dwidth-1 downto 0),--rx_ll_data_0_i,
      RX_LL_SOF_N_0                   => p_out_phy2app(0).rxsof_n,                         --rx_ll_sof_n_0_i,
      RX_LL_EOF_N_0                   => p_out_phy2app(0).rxeof_n,                         --rx_ll_eof_n_0_i,
      RX_LL_SRC_RDY_N_0               => p_out_phy2app(0).rxsrc_rdy_n,                     --rx_ll_src_rdy_n_0_i,
      RX_LL_DST_RDY_N_0               => p_in_phy2app (0).rxdst_rdy_n,                     --rx_ll_dst_rdy_n_0_i,
      RX_LL_FIFO_STATUS_0             => p_out_phy2app(0).rxbuf_status,                    --open,

      -- Unused Receiver signals - EMAC0
      EMAC0CLIENTRXDVLD               => open, --EMAC0CLIENTRXDVLD,
      EMAC0CLIENTRXFRAMEDROP          => open, --EMAC0CLIENTRXFRAMEDROP,
      EMAC0CLIENTRXSTATS              => open, --EMAC0CLIENTRXSTATS,
      EMAC0CLIENTRXSTATSVLD           => open, --EMAC0CLIENTRXSTATSVLD,
      EMAC0CLIENTRXSTATSBYTEVLD       => open, --EMAC0CLIENTRXSTATSBYTEVLD,

      -- Local link Transmitter Interface - EMAC0
      TX_LL_CLOCK_0                   => ll_clk_0_i,
      TX_LL_RESET_0                   => ll_reset_0_i,
      TX_LL_DATA_0                    => p_in_phy2app (0).txd(G_ETH.phy_dwidth-1 downto 0),--tx_ll_data_0_i,
      TX_LL_SOF_N_0                   => p_in_phy2app (0).txsof_n,                         --tx_ll_sof_n_0_i,
      TX_LL_EOF_N_0                   => p_in_phy2app (0).txeof_n,                         --tx_ll_eof_n_0_i,
      TX_LL_SRC_RDY_N_0               => p_in_phy2app (0).txsrc_rdy_n,                     --tx_ll_src_rdy_n_0_i,
      TX_LL_DST_RDY_N_0               => p_out_phy2app(0).txdst_rdy_n,                     --tx_ll_dst_rdy_n_0_i,

      -- Unused Transmitter signals - EMAC0
      CLIENTEMAC0TXIFGDELAY           => i_CLIENTEMACTXIFGDELAY, --CLIENTEMAC0TXIFGDELAY,
      EMAC0CLIENTTXSTATS              => open,                   --EMAC0CLIENTTXSTATS,
      EMAC0CLIENTTXSTATSVLD           => open,                   --EMAC0CLIENTTXSTATSVLD,
      EMAC0CLIENTTXSTATSBYTEVLD       => open,                   --EMAC0CLIENTTXSTATSBYTEVLD,

      -- MAC Control Interface - EMAC0
      CLIENTEMAC0PAUSEREQ             => '0',           --CLIENTEMAC0PAUSEREQ,
      CLIENTEMAC0PAUSEVAL             => (others=>'0'), --CLIENTEMAC0PAUSEVAL,


      -- Clock Signals - EMAC0
      GTX_CLK_0                       => '0',
      -- RGMII Interface - EMAC0
      RGMII_TXD_0                     => p_out_phy.pin.rgmii(0).txd,   --RGMII_TXD_0,
      RGMII_TX_CTL_0                  => p_out_phy.pin.rgmii(0).tx_ctl,--RGMII_TX_CTL_0,
      RGMII_TXC_0                     => p_out_phy.pin.rgmii(0).txc,   --RGMII_TXC_0,
      RGMII_RXD_0                     => p_in_phy.pin.rgmii(0).rxd,    --RGMII_RXD_0,
      RGMII_RX_CTL_0                  => p_in_phy.pin.rgmii(0).rx_ctl, --RGMII_RX_CTL_0,
      RGMII_RXC_0                     => rx_clk_0_i,

      -- Asynchronous Reset
      RESET                           => reset_i
    );

--    ---------------------------------------------------------------------
--    --  Instatiate the address swapping module
--    ---------------------------------------------------------------------
--    client_side_asm_emac0 : address_swap_module_8
--      port map (
--        rx_ll_clock         => ll_clk_0_i,
--        rx_ll_reset         => ll_reset_0_i,
--        rx_ll_data_in       => rx_ll_data_0_i,
--        rx_ll_sof_in_n      => rx_ll_sof_n_0_i,
--        rx_ll_eof_in_n      => rx_ll_eof_n_0_i,
--        rx_ll_src_rdy_in_n  => rx_ll_src_rdy_n_0_i,
--        rx_ll_data_out      => tx_ll_data_0_i,
--        rx_ll_sof_out_n     => tx_ll_sof_n_0_i,
--        rx_ll_eof_out_n     => tx_ll_eof_n_0_i,
--        rx_ll_src_rdy_out_n => tx_ll_src_rdy_n_0_i,
--        rx_ll_dst_rdy_in_n  => tx_ll_dst_rdy_n_0_i
--    );
--
--    rx_ll_dst_rdy_n_0_i     <= tx_ll_dst_rdy_n_0_i;


    -- Create synchronous reset in the transmitter clock domain.
    gen_ll_reset_emac0 : process (ll_clk_0_i, reset_i)
    begin
      if reset_i = '1' then
        ll_pre_reset_0_i <= (others => '1');
        ll_reset_0_i     <= '1';
      elsif ll_clk_0_i'event and ll_clk_0_i = '1' then
        ll_pre_reset_0_i(0)          <= '0';
        ll_pre_reset_0_i(5 downto 1) <= ll_pre_reset_0_i(4 downto 0);
        ll_reset_0_i                 <= ll_pre_reset_0_i(5);
      end if;
    end process gen_ll_reset_emac0;

    ------------------------------------------------------------------------
    -- REFCLK used for RGMII IODELAYCTRL primitive - Need to supply a 200MHz clock
    ------------------------------------------------------------------------
--    refclk_ibufg : IBUFG port map(I => REFCLK, O => refclk_ibufg_i);
    refclk_bufg  : BUFG  port map(I => refclk_ibufg_i, O => refclk_bufg_i);

--    ----------------------------------------------------------------------
--    -- Cause the tools to automatically choose a GC pin for the
--    -- GTX_CLK_0 line.
--    ----------------------------------------------------------------------
--    gtx_clk0_ibuf : IBUFG port map (I => GTX_CLK_0, O => gtx_clk_0_i);


end TOP_LEVEL;
