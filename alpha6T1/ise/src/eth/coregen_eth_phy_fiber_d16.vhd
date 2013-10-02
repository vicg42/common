-------------------------------------------------------------------------------
-- Title      : Virtex-6 Embedded Tri-Mode Ethernet MAC Wrapper Example Design
-- Project    : Virtex-6 Embedded Tri-Mode Ethernet MAC Wrapper
-- File       : emac_core_example_design.vhd
-- Version    : 1.5
-------------------------------------------------------------------------------
--
-- (c) Copyright 2009-2011 Xilinx, Inc. All rights reserved.
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
-- Description:  This is the Example Design wrapper for the Virtex-6
--               Embedded Tri-Mode Ethernet MAC. It is intended that this
--               example design can be quickly adapted and downloaded onto an
--               FPGA to provide a hardware test environment.
--
--               The Example Design wrapper:
--
--               * instantiates the EMAC LocalLink-level wrapper (the EMAC
--                 block-level wrapper with the RX and TX FIFOs and a
--                 LocalLink interface);
--
--               * instantiates a simple example design which provides an
--                 address swap and loopback function at the user interface;
--
--               * instantiates the fundamental clocking resources required
--                 by the core.
--
--               Please refer to the Datasheet, Getting Started Guide, and
--               the Virtex-6 Embedded Tri-Mode Ethernet MAC User Gude for
--               further information.
--
--    ---------------------------------------------------------------------
--    |EXAMPLE DESIGN WRAPPER                                             |
--    |           --------------------------------------------------------|
--    |           |LOCALLINK-LEVEL WRAPPER                                |
--    |           |              -----------------------------------------|
--    |           |              |BLOCK-LEVEL WRAPPER                     |
--    |           |              |    ---------------------               |
--    | --------  |  ----------  |    | INSTANCE-LEVEL    |               |
--    | |      |  |  |        |  |    | WRAPPER           |  ---------    |
--    | |      |->|->|        |->|--->| Tx            Tx  |->|       |--->|
--    | |      |  |  |        |  |    | client        PHY |  |       |    |
--    | | ADDR |  |  | LOCAL- |  |    | I/F           I/F |  |       |    |
--    | | SWAP |  |  | LINK   |  |    |                   |  | PHY   |    |
--    | |      |  |  | FIFO   |  |    |                   |  | I/F   |    |
--    | |      |  |  |        |  |    |                   |  |       |    |
--    | |      |  |  |        |  |    | Rx            Rx  |  |       |    |
--    | |      |  |  |        |  |    | client        PHY |  |       |    |
--    | |      |<-|<-|        |<-|<---| I/F           I/F |<-|       |<---|
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
-- Entity declaration for the example design
-------------------------------------------------------------------------------

entity eth_phy_fiber is
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

end eth_phy_fiber;


architecture TOP_LEVEL of eth_phy_fiber is

-------------------------------------------------------------------------------
-- Component declarations for lower hierarchial level entities
-------------------------------------------------------------------------------

  -- Component declaration for the LocalLink-level EMAC wrapper
  component emac_core_locallink is
   port(
      -- 125MHz clock output from transceiver
      CLK125_OUT               : out std_logic;
      -- 125MHz clock input from BUFG
      CLK125                   : in  std_logic;
      -- 2x clock input from MMCM
      CLK2X                    : in  std_logic;
      CLK2X_MMCM_LOCKED        : in  std_logic;

      -- LocalLink receiver interface
      RX_LL_CLOCK              : in  std_logic;
      RX_LL_RESET              : in  std_logic;
      RX_LL_DATA               : out std_logic_vector(15 downto 0);
      RX_LL_SOF_N              : out std_logic;
      RX_LL_EOF_N              : out std_logic;
      RX_LL_SRC_RDY_N          : out std_logic;
      RX_LL_DST_RDY_N          : in  std_logic;
      RX_LL_REM                : out std_logic;
      RX_LL_FIFO_STATUS        : out std_logic_vector(3 downto 0);

      -- LocalLink transmitter interface
      TX_LL_CLOCK              : in  std_logic;
      TX_LL_RESET              : in  std_logic;
      TX_LL_DATA               : in  std_logic_vector(15 downto 0);
      TX_LL_SOF_N              : in  std_logic;
      TX_LL_EOF_N              : in  std_logic;
      TX_LL_SRC_RDY_N          : in  std_logic;
      TX_LL_DST_RDY_N          : out std_logic;
      TX_LL_REM                : in  std_logic;

      -- Client receiver interface
      EMACCLIENTRXDVLD         : out std_logic;
      EMACCLIENTRXFRAMEDROP    : out std_logic;
      EMACCLIENTRXSTATS        : out std_logic_vector(6 downto 0);
      EMACCLIENTRXSTATSVLD     : out std_logic;
      EMACCLIENTRXSTATSBYTEVLD : out std_logic;

      -- Client Transmitter Interface
      CLIENTEMACTXIFGDELAY     : in  std_logic_vector(7 downto 0);
      EMACCLIENTTXSTATS        : out std_logic;
      EMACCLIENTTXSTATSVLD     : out std_logic;
      EMACCLIENTTXSTATSBYTEVLD : out std_logic;

      -- MAC control interface
      CLIENTEMACPAUSEREQ       : in  std_logic;
      CLIENTEMACPAUSEVAL       : in  std_logic_vector(15 downto 0);

      -- EMAC-transceiver link status
      EMACCLIENTSYNCACQSTATUS  : out std_logic;
      EMACANINTERRUPT          : out std_logic;

      -- 1000BASE-X PCS/PMA interface
      TXP                      : out std_logic;
      TXN                      : out std_logic;
      RXP                      : in  std_logic;
      RXN                      : in  std_logic;
      PHYAD                    : in  std_logic_vector(4 downto 0);
      RESETDONE                : out std_logic;

      -- 1000BASE-X PCS/PMA clock buffer input
      CLK_DS                   : in  std_logic;

      -- Asynchronous reset
      RESET                    : in  std_logic
   );
  end component;

   --  Component declaration for address swapping module
   component address_swap_module_16
   port (
      rx_ll_clock         : in  std_logic;
      rx_ll_reset         : in  std_logic;
      rx_ll_data_in       : in  std_logic_vector(15 downto 0);
      rx_ll_sof_in_n      : in  std_logic;
      rx_ll_eof_in_n      : in  std_logic;
      rx_ll_src_rdy_in_n  : in  std_logic;
      rx_ll_rem_in        : in  std_logic_vector(0 downto 0);
      rx_ll_data_out      : out std_logic_vector(15 downto 0);
      rx_ll_sof_out_n     : out std_logic;
      rx_ll_eof_out_n     : out std_logic;
      rx_ll_src_rdy_out_n : out std_logic;
      rx_ll_rem_out       : out std_logic_vector(0 downto 0);
      rx_ll_dst_rdy_in_n  : in  std_logic
      );
   end component;


-----------------------------------------------------------------------
-- Signal declarations
-----------------------------------------------------------------------

    -- Global asynchronous reset
    signal reset_i             : std_logic;

    -- LocalLink interface clocking signal
    signal ll_clk_i            : std_logic;

    -- Address swap transmitter connections
    signal tx_ll_data_i        : std_logic_vector(15 downto 0);
    signal tx_ll_rem_i         : std_logic;
    signal tx_ll_rem_int       : std_logic_vector(0 downto 0);
    signal tx_ll_sof_n_i       : std_logic;
    signal tx_ll_eof_n_i       : std_logic;
    signal tx_ll_src_rdy_n_i   : std_logic;
    signal tx_ll_dst_rdy_n_i   : std_logic;

   -- Address swap receiver connections
    signal rx_ll_data_i        : std_logic_vector(15 downto 0);
    signal rx_ll_rem_i         : std_logic;
    signal rx_ll_rem_int       : std_logic_vector(0 downto 0);
    signal rx_ll_sof_n_i       : std_logic;
    signal rx_ll_eof_n_i       : std_logic;
    signal rx_ll_src_rdy_n_i   : std_logic;
    signal rx_ll_dst_rdy_n_i   : std_logic;

    -- Synchronous reset registers in the LocalLink clock domain
    signal ll_pre_reset_i     : std_logic_vector(5 downto 0);
    signal ll_reset_i         : std_logic;

    attribute async_reg : string;
    attribute async_reg of ll_pre_reset_i : signal is "true";

    -- Reset signal from the transceiver
    signal resetdone_i         : std_logic;
    signal resetdone_r         : std_logic;

    attribute async_reg of resetdone_r : signal is "true";

    -- Transceiver output clock (REFCLKOUT at 125MHz)
    signal clk125_o            : std_logic;

    -- 125MHz clock input to wrappers
    signal clk125              : std_logic;

    attribute keep : boolean;
    attribute keep of clk125   : signal is true;

    -- Input 125MHz differential clock for transceiver
    signal clk_ds              : std_logic;

    -- Buffered output clock from transceiver for MMCM
    signal clk125_o_bufg        : std_logic;

    -- Clock signals for MMCM at 2x GT reference rate
    signal clkfb                 : std_logic;
    signal clkfb_pre_bufg        : std_logic;
    signal clk125_pre_bufg       : std_logic;
    signal clk2x_pre_bufg        : std_logic;
    signal client_mmcm_locked_i  : std_logic;
    signal client_mmcm_locked_r  : std_logic;
    signal client_mmcm_locked_r2 : std_logic;

    attribute async_reg of client_mmcm_locked_r : signal is "true";

    -- 2x clock to wrappers
    signal clk2x                : std_logic;

    signal i_PHYAD                 : std_logic_vector(4 downto 0);
    signal i_CLIENTEMACTXIFGDELAY  : std_logic_vector(7 downto 0);

-------------------------------------------------------------------------------
-- Main body of code
-------------------------------------------------------------------------------

begin
  p_out_tst <=(others=>'0');

  i_PHYAD<=CONV_STD_LOGIC_VECTOR(16#01#, i_PHYAD'length);
  i_CLIENTEMACTXIFGDELAY<=CONV_STD_LOGIC_VECTOR(16#0D#, i_CLIENTEMACTXIFGDELAY'length);

  p_out_phy.link<=p_in_phy.pin.fiber.sfp_sd;
  p_out_phy.rdy<='1';
  p_out_phy.clk<=ll_clk_i;
  p_out_phy.rst<=ll_reset_i;
  p_out_phy.pin.fiber.sfp_txdis<='0';

  reset_i<=p_in_rst;
  clk_ds <=p_in_phy.clk;

--    -- Reset input buffer
--    reset_ibuf : IBUF port map (
--      I => RESET,
--      O => reset_i
--    );
--
--    -- Generate the clock input to the transceiver
--    -- (clk_ds can be shared between multiple EMAC instances, including
--    --  multiple instantiations of the EMAC wrappers)
--    clkingen : IBUFDS_GTXE1 port map (
--      I     => MGTCLK_P,
--      IB    => MGTCLK_N,
--      CEB   => '0',
--      O     => clk_ds,
--      ODIV2 => open
--    );

    -- The 125MHz clock from the transceiver is routed through a BUFG and
    -- input to the MMCM
    bufg_clk125 : BUFG port map (
      I => clk125_o,
      O => clk125_o_bufg
    );



--    -- Use an MMCM to multiply the 125MHz clock from the transceiver by 2
--    -- to get a 250MHz clock for EMAC. The 250MHz clock can only be used
--    -- when the EMAC is configured for a 16-bit client interface.
--    client_mmcm_2G : MMCM_BASE
--    generic map (
--      CLKFBOUT_MULT_F  => 5.0,
--      CLKOUT0_DIVIDE_F => 2.5,
--      CLKOUT1_DIVIDE   => 5,
--      CLKIN1_PERIOD    => 8.0,
--      REF_JITTER1      => 0.010
--    )
--    port map (
--      CLKFBOUT  => clkfb_pre_bufg,
--      CLKFBOUTB => open,
--      CLKOUT0   => clk2x_pre_bufg,
--      CLKOUT0B  => open,
--      CLKOUT1   => clk125_pre_bufg,
--      CLKOUT1B  => open,
--      CLKOUT2   => open,
--      CLKOUT2B  => open,
--      CLKOUT3   => open,
--      CLKOUT3B  => open,
--      CLKOUT4   => open,
--      CLKOUT5   => open,
--      CLKOUT6   => open,
--      LOCKED    => client_mmcm_locked_i,
--      CLKFBIN   => clkfb,
--      CLKIN1    => clk125_o_bufg,
--      PWRDWN    => '0',
--      RST       => reset_i
--    );

    -- Reference clock MMCM (CLKFBOUT range 600 MHz to 1200 MHz)
    -- CLKFBOUT = (CLKIN1/DIVCLK_DIVIDE) * CLKFBOUT_MULT_F
    -- CLKOUTn  = (CLKIN1/DIVCLK_DIVIDE) * CLKFBOUT_MULT_F/CLKOUTn_DIVIDE

--    -- This requires that the GTX reference clock be provided at 125 MHz.
--    -- Use an MMCM to multiply the 125MHz clock.
--    -- The EMAC is configured for a 16-bit client interface.
--    -- CLKFBOUT = (125 MHz/1) * 5.000       = 625 MHz
--    -- CLKOUT0  = (125 MHz/1) * 5.000/5.000 = 125 MHz
--    -- CLKOUT1  = (125 MHz/1) * 5.000/10    = 62.5 MHz
--    client_mmcm_1G : MMCM_BASE
--    generic map (
--      CLKFBOUT_MULT_F  => 5.0,
--      CLKOUT0_DIVIDE_F => 5.0,
--      CLKOUT1_DIVIDE   => 10,
--      CLKIN1_PERIOD    => 8.0,
--      REF_JITTER1      => 0.010
--    )
--    port map (
--      CLKFBOUT  => clkfb_pre_bufg,
--      CLKFBOUTB => open,
--      CLKOUT0   => clk2x_pre_bufg,
--      CLKOUT0B  => open,
--      CLKOUT1   => clk125_pre_bufg,
--      CLKOUT1B  => open,
--      CLKOUT2   => open,
--      CLKOUT2B  => open,
--      CLKOUT3   => open,
--      CLKOUT3B  => open,
--      CLKOUT4   => open,
--      CLKOUT5   => open,
--      CLKOUT6   => open,
--      LOCKED    => client_mmcm_locked_i,
--      CLKFBIN   => clkfb,
--      CLKIN1    => clk125_o_bufg,
--      PWRDWN    => '0',
--      RST       => reset_i
--    );

    -- This requires that the GTX reference clock be provided at 125 MHz.
    -- Use an MMCM to multiply the 125MHz clock.
    -- The EMAC is configured for a 16-bit client interface.
    -- CLKFBOUT = (125 MHz/1) * 5.000       = 625 MHz
    -- CLKOUT0  = (125 MHz/1) * 5.000/2.500 = 250 MHz
    -- CLKOUT1  = (125 MHz/1) * 5.000/5     = 125 MHz
    client_mmcm_2G : MMCM_BASE
    generic map (
      CLKFBOUT_MULT_F  => 5.0,
      CLKOUT0_DIVIDE_F => 2.5,
      CLKOUT1_DIVIDE   => 5,
      CLKIN1_PERIOD    => 8.0,
      REF_JITTER1      => 0.010
    )
    port map (
      CLKFBOUT  => clkfb_pre_bufg,
      CLKFBOUTB => open,
      CLKOUT0   => clk2x_pre_bufg,
      CLKOUT0B  => open,
      CLKOUT1   => clk125_pre_bufg,
      CLKOUT1B  => open,
      CLKOUT2   => open,
      CLKOUT2B  => open,
      CLKOUT3   => open,
      CLKOUT3B  => open,
      CLKOUT4   => open,
      CLKOUT5   => open,
      CLKOUT6   => open,
      LOCKED    => client_mmcm_locked_i,
      CLKFBIN   => clkfb,
      CLKIN1    => clk125_o_bufg,
      PWRDWN    => '0',
      RST       => reset_i
    );

--    -- This requires that the GTX reference clock be provided at 156.25 MHz.
--    -- This requires that the GTX reference clock be provided at 156.25 MHz.
--    -- Use an MMCM to multiply the 156.25 MHz clock.
--    -- The EMAC is configured for a 16-bit client interface.
--    -- CLKFBOUT = (156.25 MHz/1) * 5.000       = 781,25 MHz
--    -- CLKOUT0  = (156.25 MHz/1) * 5.000/2.500 = 312,5 MHz
--    -- CLKOUT1  = (156.25 MHz/1) * 5.000/5     = 156,25 MHz
--    client_mmcm_25G : MMCM_BASE
--    generic map (
--      CLKFBOUT_MULT_F  => 5.0,
--      CLKOUT0_DIVIDE_F => 2.5,
--      CLKOUT1_DIVIDE   => 5,
--      CLKIN1_PERIOD    => 6.4,
--      REF_JITTER1      => 0.010
--    )
--    port map (
--      CLKFBOUT  => clkfb_pre_bufg,
--      CLKFBOUTB => open,
--      CLKOUT0   => clk2x_pre_bufg,
--      CLKOUT0B  => open,
--      CLKOUT1   => clk125_pre_bufg,
--      CLKOUT1B  => open,
--      CLKOUT2   => open,
--      CLKOUT2B  => open,
--      CLKOUT3   => open,
--      CLKOUT3B  => open,
--      CLKOUT4   => open,
--      CLKOUT5   => open,
--      CLKOUT6   => open,
--      LOCKED    => client_mmcm_locked_i,
--      CLKFBIN   => clkfb,
--      CLKIN1    => clk125_o_bufg,
--      PWRDWN    => '0',
--      RST       => reset_i
--    );

--    -- This requires that the GTX reference clock be provided at 125 MHz.
--    -- Use an MMCM to multiply the 125MHz clock.
--    -- The EMAC is configured for a 16-bit client interface.
--    -- CLKFBOUT = (125 MHz/1) * 5.000       = 625 MHz
--    -- CLKOUT0  = (125 MHz/1) * 5.000/2.000 = 312.5 MHz
--    -- CLKOUT1  = (125 MHz/1) * 5.000/4     = 156.25 MHz
--    client_mmcm_25G : MMCM_BASE
--    generic map (
--      CLKFBOUT_MULT_F  => 5.0,
--      DIVCLK_DIVIDE    => 1,
--      CLKOUT0_DIVIDE_F => 2.0,
--      CLKOUT1_DIVIDE   => 4,
--      CLKIN1_PERIOD    => 8.0
--      REF_JITTER1      => 0.010
--    )
--    port map (
--      CLKFBOUT  => clkfb_pre_bufg,
--      CLKFBOUTB => open,
--      CLKOUT0   => clk2x_pre_bufg,
--      CLKOUT0B  => open,
--      CLKOUT1   => clk125_pre_bufg,
--      CLKOUT1B  => open,
--      CLKOUT2   => open,
--      CLKOUT2B  => open,
--      CLKOUT3   => open,
--      CLKOUT3B  => open,
--      CLKOUT4   => open,
--      CLKOUT5   => open,
--      CLKOUT6   => open,
--      LOCKED    => client_mmcm_locked_i,
--      CLKFBIN   => clkfb,
--      CLKIN1    => clk125_o_bufg,
--      PWRDWN    => '0',
--      RST       => reset_i
--    );

    -- Globally-buffer the feedback clock from the MMCM
    feedback_clk_bufg : BUFG port map (
      I => clkfb_pre_bufg,
      O => clkfb
    );

    -- Globally-buffer the 2x clock from the MMCM
    -- (clk2x can be shared between multiple EMAC instances, including
    --  multiple instantiations of the EMAC wrappers)
    tx_client_clk_out_bufg : BUFG port map (
      I => clk2x_pre_bufg,
      O => clk2x
    );

    -- The 125MHz clock from the transceiver (via the MMCM) is routed
    -- through a BUFG and input to the MAC wrappers
    -- (clk125 can be shared between multiple EMAC instances, including
    --  multiple instantiations of the EMAC wrappers)
    tx_client_clk_in_div2_bufg : BUFG port map (
      I => clk125_pre_bufg,
      O => clk125
    );

    -- Register the MMCM locked indicator to assist with timing closure
    -- and ensure clock stability on bring-up
    mmcm_lock_pr : process (clk125, reset_i)
    begin
        if reset_i = '1' then
            client_mmcm_locked_r  <= '0';
            client_mmcm_locked_r2 <= '0';
        elsif clk125'event and clk125 = '1' then
            client_mmcm_locked_r  <= client_mmcm_locked_i;
            client_mmcm_locked_r2 <= client_mmcm_locked_r;
        end if;
    end process mmcm_lock_pr;

    -- Clock the LocalLink interface with the phase-aligned and
    -- globally-buffered 125MHz clock from the MMCM
    ll_clk_i <= clk125;

    ------------------------------------------------------------------------
    -- Instantiate the LocalLink-level EMAC Wrapper (emac_core_locallink.vhd)
    ------------------------------------------------------------------------
    emac_core_locallink_inst : emac_core_locallink port map (
      -- 125MHz clock output from transceiver
      CLK125_OUT               => clk125_o,
      -- 125MHz clock input from BUFG
      CLK125                   => clk125,
      -- 2x clock input from MMCM
      CLK2X                    => clk2x,
      CLK2X_MMCM_LOCKED        => client_mmcm_locked_r2,

      -- LocalLink receiver interface
      RX_LL_CLOCK              => ll_clk_i,         --: in  std_logic;
      RX_LL_RESET              => ll_reset_i,       --: in  std_logic;
      RX_LL_DATA               => p_out_phy2app(0).rxd(G_ETH.phy_dwidth-1 downto 0),--rx_ll_data_i,     --: out std_logic_vector(15 downto 0);
      RX_LL_SOF_N              => p_out_phy2app(0).rxsof_n,                         --rx_ll_sof_n_i,    --: out std_logic;
      RX_LL_EOF_N              => p_out_phy2app(0).rxeof_n,                         --rx_ll_eof_n_i,    --: out std_logic;
      RX_LL_SRC_RDY_N          => p_out_phy2app(0).rxsrc_rdy_n,                     --rx_ll_src_rdy_n_i,--: out std_logic;
      RX_LL_DST_RDY_N          => p_in_phy2app (0).rxdst_rdy_n,                     --rx_ll_dst_rdy_n_i,--: in  std_logic;
      RX_LL_REM                => p_out_phy2app(0).rxrem(0),                        --rx_ll_rem_i,      --: out std_logic;
      RX_LL_FIFO_STATUS        => open,             --: out std_logic_vector(3 downto 0);

      -- Client receiver signals
      EMACCLIENTRXDVLD         => open, --EMACCLIENTRXDVLD,
      EMACCLIENTRXFRAMEDROP    => open, --EMACCLIENTRXFRAMEDROP,
      EMACCLIENTRXSTATS        => open, --EMACCLIENTRXSTATS,
      EMACCLIENTRXSTATSVLD     => open, --EMACCLIENTRXSTATSVLD,
      EMACCLIENTRXSTATSBYTEVLD => open, --EMACCLIENTRXSTATSBYTEVLD,

      -- LocalLink transmitter interface
      TX_LL_CLOCK              => ll_clk_i,
      TX_LL_RESET              => ll_reset_i,
      TX_LL_DATA               => p_in_phy2app (0).txd(G_ETH.phy_dwidth-1 downto 0),--tx_ll_data_i,
      TX_LL_SOF_N              => p_in_phy2app (0).txsof_n,                         --tx_ll_sof_n_i,
      TX_LL_EOF_N              => p_in_phy2app (0).txeof_n,                         --tx_ll_eof_n_i,
      TX_LL_SRC_RDY_N          => p_in_phy2app (0).txsrc_rdy_n,                     --tx_ll_src_rdy_n_i,
      TX_LL_DST_RDY_N          => p_out_phy2app(0).txdst_rdy_n,                     --tx_ll_dst_rdy_n_i,
      TX_LL_REM                => p_in_phy2app (0).txrem(0),                        --tx_ll_rem_i,

      -- Client transmitter signals
      CLIENTEMACTXIFGDELAY     => i_CLIENTEMACTXIFGDELAY, --CLIENTEMACTXIFGDELAY,
      EMACCLIENTTXSTATS        => open,                   --EMACCLIENTTXSTATS,
      EMACCLIENTTXSTATSVLD     => open,                   --EMACCLIENTTXSTATSVLD,
      EMACCLIENTTXSTATSBYTEVLD => open,                   --EMACCLIENTTXSTATSBYTEVLD,

      -- MAC control interface
      CLIENTEMACPAUSEREQ       => '0',           --CLIENTEMACPAUSEREQ,
      CLIENTEMACPAUSEVAL       => (others=>'0'), --CLIENTEMACPAUSEVAL,

      -- EMAC-transceiver link status
      EMACCLIENTSYNCACQSTATUS  => open,  --EMACCLIENTSYNCACQSTATUS,
      EMACANINTERRUPT          => open,  --EMACANINTERRUPT,

      -- 1000BASE-X PCS/PMA interface
      TXP                      => p_out_phy.pin.fiber.txp(0), --TXP,
      TXN                      => p_out_phy.pin.fiber.txn(0), --TXN,
      RXP                      => p_in_phy.pin.fiber.rxp(0),  --RXP,
      RXN                      => p_in_phy.pin.fiber.rxn(0),  --RXN,
      PHYAD                    => i_PHYAD,                    --PHYAD,
      RESETDONE                => resetdone_i,

      -- 1000BASE-X PCS/PMA reference clock buffer input
      CLK_DS                   => clk_ds,

      -- Asynchronous reset
      RESET                    => reset_i
    );

--    ---------------------------------------------------------------------
--    --  Instatiate the address swapping module
--    ---------------------------------------------------------------------
--    client_side_asm : address_swap_module_16 port map (
--      rx_ll_clock         => ll_clk_i,
--      rx_ll_reset         => ll_reset_i,
--      rx_ll_data_in       => rx_ll_data_i,
--      rx_ll_sof_in_n      => rx_ll_sof_n_i,
--      rx_ll_eof_in_n      => rx_ll_eof_n_i,
--      rx_ll_src_rdy_in_n  => rx_ll_src_rdy_n_i,
--      rx_ll_rem_in        => rx_ll_rem_int,
--      rx_ll_data_out      => tx_ll_data_i,
--      rx_ll_sof_out_n     => tx_ll_sof_n_i,
--      rx_ll_eof_out_n     => tx_ll_eof_n_i,
--      rx_ll_src_rdy_out_n => tx_ll_src_rdy_n_i,
--      rx_ll_rem_out       => tx_ll_rem_int,
--      rx_ll_dst_rdy_in_n  => tx_ll_dst_rdy_n_i
--    );
--
--    rx_ll_dst_rdy_n_i <= tx_ll_dst_rdy_n_i;
--    rx_ll_rem_int(0)  <= rx_ll_rem_i;
--    tx_ll_rem_i       <= tx_ll_rem_int(0);

    --Synchronize resetdone_i from the GT in the transmitter clock domain
    gen_resetdone_r : process(ll_clk_i, reset_i)
    begin
        if reset_i = '1' then
        resetdone_r <= '0';
      elsif ll_clk_i'event and ll_clk_i = '1' then
        resetdone_r <= resetdone_i;
      end if;
    end process gen_resetdone_r;

    -- Create synchronous reset in the transmitter clock domain
    gen_ll_reset : process (ll_clk_i, reset_i)
    begin
        if reset_i = '1' then
        ll_pre_reset_i <= (others => '1');
        ll_reset_i     <= '1';
      elsif ll_clk_i'event and ll_clk_i = '1' then
      if resetdone_r = '1' then
        ll_pre_reset_i(0)          <= '0';
        ll_pre_reset_i(5 downto 1) <= ll_pre_reset_i(4 downto 0);
        ll_reset_i                 <= ll_pre_reset_i(5);
      end if;
      end if;
    end process gen_ll_reset;


end TOP_LEVEL;
