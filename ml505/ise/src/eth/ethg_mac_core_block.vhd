--------------------------------------------------------------------------------
-- File       : ethg_mac_core_block.vhd
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
-- Description: This is the block level VHDL design for the Tri-Mode
--              Ethernet MAC Example Design.
--
--              This block level:
--
--              * instantiates appropriate PHY interface module (GMII/MII/RGMII)
--                as required based on the user configuration;
--
--              Please refer to the Datasheet, Getting Started Guide, and
--              the Tri-Mode Ethernet MAC User Gude for further information.
--
--
--              -----------------------------------------|
--              | BLOCK LEVEL WRAPPER                    |
--              |                                        |
--              |    ---------------------               |
--              |    | ETHERNET MAC      |               |
--              |    | CORE              |  ---------    |
--              |    |                   |  |       |    |
--            --|--->| Tx            Tx  |--|       |--->|
--              |    | client        PHY |  |       |    |
--              |    | I/F           I/F |  |       |    |
--              |    |                   |  | PHY   |    |
--              |    |                   |  | I/F   |    |
--              |    |                   |  |       |    |
--              |    | Rx            Rx  |  |       |    |
--              |    | client        PHY |  |       |    |
--            <-|----| I/F           I/F |<-|       |<---|
--              |    |                   |  ---------    |
--              |    ---------------------               |
--              |                                        |
--              |                                        |
--              -----------------------------------------|
--

library unisim;
use unisim.vcomponents.all;

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;


--------------------------------------------------------------------------------
-- The entity declaration for the block level example design.
--------------------------------------------------------------------------------

entity ethg_mac_core_block is
   port(
      -- asynchronous reset
      reset                : in  std_logic;

      -- Reference clock for IDELAYCTRL's
      refclk               : in  std_logic;

      -- Client Receiver Interface
      ----------------------------
      rx_clk               : out std_logic;
      rx_statistics_vector : out std_logic_vector(27 downto 0);
      rx_statistics_valid  : out std_logic;
      rx_data              : out std_logic_vector(7 downto 0);
      rx_data_valid        : out std_logic;
      rx_good_frame        : out std_logic;
      rx_bad_frame         : out std_logic;

      -- Client Transmitter Interface
      -------------------------------
      tx_clk               : out std_logic;
      tx_ifg_delay         : in  std_logic_vector(7 downto 0);
      tx_statistics_vector : out std_logic_vector(31 downto 0);
      tx_statistics_valid  : out std_logic;
      tx_data              : in  std_logic_vector(7 downto 0);
      tx_data_valid        : in  std_logic;
      tx_ack               : out std_logic;
      tx_underrun          : in  std_logic;

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

      -- Configuration Vector
      -----------------------
      configuration_vector : in  std_logic_vector(67 downto 0)
   );
end ethg_mac_core_block;


architecture wrapper of ethg_mac_core_block is


   -----------------------------------------------------------------------------
   -- Component Declaration for TRIMAC (the Tri-Mode EMAC core).
   -----------------------------------------------------------------------------
   component ethg_mac_core
   port(
      -- asynchronous reset
      reset                : in std_logic;

      -- Physical Interface of the core
      --------------------------------
      emacphytxd           : out std_logic_vector(7 downto 0);
      emacphytxen          : out std_logic;
      emacphytxer          : out std_logic;
      phyemacrxd           : in std_logic_vector(7 downto 0);
      phyemacrxdv          : in std_logic;
      phyemacrxer          : in std_logic;

      -- Client Transmitter Interface
      -------------------------------
      clientemactxd        : in std_logic_vector(7 downto 0);
      clientemactxdvld     : in std_logic;
      emacclienttxack      : out std_logic;
      clientemactxunderrun : in std_logic;
      clientemactxifgdelay : in std_logic_vector(7 downto 0);

      -- MAC Control Interface
      ------------------------
      clientemacpausereq   : in std_logic;
      clientemacpauseval   : in std_logic_vector(15 downto 0);

      -- Client Receiver Interface
      ----------------------------
      emacclientrxd        : out std_logic_vector(7 downto 0);
      emacclientrxdvld     : out std_logic;
      emacclientrxgoodframe: out std_logic;
      emacclientrxbadframe : out std_logic;

      -- Client Transmitter Statistics
      --------------------------------
      emacclienttxstats    : out std_logic_vector(31 downto 0);
      emacclienttxstatsvld : out std_logic;

      -- Client Receiver Statistics
      -----------------------------
      emacclientrxstats    : out std_logic_vector(27 downto 0);
      emacclientrxstatsvld : out std_logic;
      -- Configuration Vector
      -----------------------
      tieemacconfigvec     : in std_logic_vector(67 downto 0);

      -- Core Clock I/Os
      ------------------
      txcoreclk            : in  std_logic;
      rxcoreclk            : in  std_logic;
      txgmiimiiclk         : in  std_logic;
      rxgmiimiiclk         : in  std_logic;

      -- Current Speed Indication
      ---------------------------
      speedis100           : out std_logic;
      speedis10100         : out std_logic;


      -- Always tie to '0' unless connecting to the SGMII LogiCORE
      corehassgmii         : in  std_logic
      );
   end component;


   -----------------------------------------------------------------------------
   -- Component Declaration for the Clock Generation Logic
   -----------------------------------------------------------------------------
   component tx_clk_gen
   port (
      reset                : in  std_logic;
      speed_is_10_100      : in  std_logic;
      clk                  : in  std_logic;
      mii_tx_clk           : in  std_logic;
      tx_core_clk          : out std_logic;
      tx_gmii_mii_clk      : out std_logic
   );
   end component;


   -----------------------------------------------------------------------------
   -- Component Declaration for the GMII IOB logic
   -----------------------------------------------------------------------------
   component gmii_if
   port(
      -- Synchronous resets
      tx_reset             : in  std_logic;
      rx_reset             : in  std_logic;

      -- Current operating speed is 10/100
      speed_is_10_100      : in  std_logic;

      -- The following ports are the GMII physical interface: these will be at
      -- pins on the FPGA
      gmii_txd             : out std_logic_vector(7 downto 0);
      gmii_tx_en           : out std_logic;
      gmii_tx_er           : out std_logic;
      gmii_tx_clk          : out std_logic;
      gmii_rxd             : in  std_logic_vector(7 downto 0);
      gmii_rx_dv           : in  std_logic;
      gmii_rx_er           : in  std_logic;
      gmii_rx_clk          : in  std_logic;

      -- The following ports are the internal GMII connections from IOB logic
      -- to the TEMAC core
      txd_from_mac         : in  std_logic_vector(7 downto 0);
      tx_en_from_mac       : in  std_logic;
      tx_er_from_mac       : in  std_logic;
      tx_clk               : in  std_logic;
      rxd_to_mac           : out std_logic_vector(7 downto 0);
      rx_dv_to_mac         : out std_logic;
      rx_er_to_mac         : out std_logic;

      -- Receiver clock for the MAC client I/F
      rx_core_clk          : out std_logic;

      -- Receiver clock for the MAC and Client Logic
      rx_clk               : out  std_logic
   );
   end component;


  ------------------------------------------------------------------------------
  -- Component declaration for the synchronisation flip-flop pair
  ------------------------------------------------------------------------------
  component sync_block
  port (
    clk                    : in  std_logic;    -- clock to be sync'ed to
    data_in                : in  std_logic;    -- Data to be 'synced'
    data_out               : out std_logic     -- synced data
    );
  end component;


  ------------------------------------------------------------------------------
  -- Component declaration for the reset synchroniser
  ------------------------------------------------------------------------------
  component reset_sync
  port (
    reset_in               : in  std_logic;    -- Active high asynchronous reset
    clk                    : in  std_logic;    -- clock to be sync'ed to
    enable                 : in  std_logic;    -- enable reset removal
    reset_out              : out std_logic     -- "Synchronised" reset signal
    );
  end component;


  ------------------------------------------------------------------------------
  -- internal signals used in this block level wrapper.
  ------------------------------------------------------------------------------

  attribute KEEP : string;

--  -- Signals used for the IDELAYCTRL reset circuitry
--  signal idelayctrl_reset_sync   : std_logic;                     -- Used to create a reset pulse in the IDELAYCTRL refclk domain.
--  signal idelay_reset_cnt        : std_logic_vector(3 downto 0);  -- Counter to create a long IDELAYCTRL reset pulse.
--  signal idelayctrl_reset        : std_logic;                     -- The reset pulse for the IDELAYCTRL.


  signal gmii_tx_en_int          : std_logic;                     -- Internal gmii_tx_en signal.
  signal gmii_tx_er_int          : std_logic;                     -- Internal gmii_tx_er signal.
  signal gmii_txd_int            : std_logic_vector(7 downto 0);  -- Internal gmii_txd signal.
  signal gmii_rx_dv_int          : std_logic;                     -- gmii_rx_dv registered in IOBs.
  signal gmii_rx_er_int          : std_logic;                     -- gmii_rx_er registered in IOBs.
  signal gmii_rxd_int            : std_logic_vector(7 downto 0);  -- gmii_rxd registered in IOBs.

  signal tx_clk_int              : std_logic;                     -- Internal transmitter core clock signal.

  signal speedis100_int          : std_logic;                     -- Asserted when speed is 100Mb/s.
  signal speedis10100_int        : std_logic;                     -- Asserted when speed is 10Mb/s or 100Mb/s.
  signal rx_gmii_clk_int     : std_logic;                     -- Internal receive gmii/mii clock signal.
  signal tx_gmii_clk_int     : std_logic;                     -- Internal transmit gmii/mii clock signal.

  signal tx_gmii_reset       : std_logic;                     -- Synchronous reset in the MAC and gmii Tx domain
  signal rx_gmii_reset       : std_logic;                     -- Synchronous reset in the MAC and gmii Rx domain


--  attribute keep of rx_gmii_clk_int    : signal is "true";
  signal rx_clk_int              : std_logic;                     -- Internal receiver core clock signal.

  attribute keep of tx_clk_int        : signal is "true";
  attribute keep of rx_clk_int        : signal is "true";


begin



--   -----------------------------------------------------------------------------
--   -- An IDELAYCTRL primitive needs to be instantiated for the Fixed Tap Delay
--   -- mode of the IDELAY.
--   -- All IDELAYs in Fixed Tap Delay mode and the IDELAYCTRL primitives have
--   -- to be LOC'ed in the UCF file.
--   -----------------------------------------------------------------------------
--   -- Instantiate IDELAYCTRL for all IDELAY and ODELAY elements in the design
--   dlyctrl : IDELAYCTRL
--   port map (
--      RDY               => open,
--      REFCLK            => refclk,
--      RST               => idelayctrl_reset
--   );
--
--
--   -- Create a synchronous reset in the IDELAYCTRL refclk clock domain.
--   idelayctrl_reset_gen : reset_sync
--   port map(
--      clk               => refclk,
--      enable            => '1',
--      reset_in          => reset,
--      reset_out         => idelayctrl_reset_sync
--   );
--
--
--   -- Reset circuitry for the IDELAYCTRL reset.
--
--   -- The IDELAYCTRL must experience a pulse which is at least 50 ns in
--   -- duration.  This is ten clock cycles of the 200MHz refclk.  Here we
--   -- drive the reset pulse for 12 clock cycles.
--   process (refclk)
--   begin
--      if refclk'event and refclk = '1' then
--         if idelayctrl_reset_sync = '1' then
--            idelay_reset_cnt <= "0000";
--            idelayctrl_reset <= '1';
--         else
--            idelayctrl_reset <= '1';
--            case idelay_reset_cnt is
--            when "0000"  => idelay_reset_cnt <= "0001";
--            when "0001"  => idelay_reset_cnt <= "0010";
--            when "0010"  => idelay_reset_cnt <= "0011";
--            when "0011"  => idelay_reset_cnt <= "0100";
--            when "0100"  => idelay_reset_cnt <= "0101";
--            when "0101"  => idelay_reset_cnt <= "0110";
--            when "0110"  => idelay_reset_cnt <= "0111";
--            when "0111"  => idelay_reset_cnt <= "1000";
--            when "1000"  => idelay_reset_cnt <= "1001";
--            when "1001"  => idelay_reset_cnt <= "1010";
--            when "1010"  => idelay_reset_cnt <= "1011";
--            when "1011"  => idelay_reset_cnt <= "1100";
--            when "1100"  => idelay_reset_cnt <= "1101";
--            when "1101"  => idelay_reset_cnt <= "1110";
--            when others  => idelay_reset_cnt <= "1110";
--                            idelayctrl_reset <= '0';
--            end case;
--         end if;
--      end if;
--   end process;


   -----------------------------------------------------------------------------
   -- Transmitter Clock generation circuit. These circuits produce the clocks
   -- for 10/100/1000 operation.
   -----------------------------------------------------------------------------
   clock_inst : tx_clk_gen
   port map (
      reset             => reset,
      speed_is_10_100   => speedis10100_int,
      clk               => gtx_clk,
      mii_tx_clk        => mii_tx_clk,
      tx_core_clk       => tx_clk_int,
      tx_gmii_mii_clk   => tx_gmii_clk_int
   );


   -- Assign the internal clock signals to output ports.
   tx_clk <= tx_clk_int;
   rx_clk <= rx_clk_int;



   -----------------------------------------------------------------------------
   -- Instantiate reset synchronisers
   -----------------------------------------------------------------------------

   -- Generate a synchronous reset signal in the Tx clock domain
   tx_gmii_reset_gen : reset_sync
   port map(
      clk               => tx_gmii_clk_int,
      enable            => '1',
      reset_in          => reset,
      reset_out         => tx_gmii_reset
   );


   -- Generate a synchronous reset signal in the Rx clock domain
   rx_gmii_reset_gen : reset_sync
   port map(
      clk               => rx_gmii_clk_int,
      enable            => '1',
      reset_in          => reset,
      reset_out         => rx_gmii_reset
   );


   -----------------------------------------------------------------------------
   -- Instantiate GMII Interface
   -----------------------------------------------------------------------------

   -- Instantiate the GMII physical interface logic
   gmii_interface : gmii_if
   port map (
      -- Synchronous resets
      tx_reset          => tx_gmii_reset,
      rx_reset          => rx_gmii_reset,

      -- Current operating speed is 10/100
      speed_is_10_100   => speedis10100_int,

      -- The following ports are the GMII physical interface: these will be at
      -- pins on the FPGA
      gmii_txd          => gmii_txd,
      gmii_tx_en        => gmii_tx_en,
      gmii_tx_er        => gmii_tx_er,
      gmii_tx_clk       => gmii_tx_clk,
      gmii_rxd          => gmii_rxd,
      gmii_rx_dv        => gmii_rx_dv,
      gmii_rx_er        => gmii_rx_er,
      gmii_rx_clk       => gmii_rx_clk,

      -- The following ports are the internal GMII connections from IOB logic
      -- to the TEMAC core
      txd_from_mac      => gmii_txd_int,
      tx_en_from_mac    => gmii_tx_en_int,
      tx_er_from_mac    => gmii_tx_er_int,
      tx_clk            => tx_gmii_clk_int,
      rxd_to_mac        => gmii_rxd_int,
      rx_dv_to_mac      => gmii_rx_dv_int,
      rx_er_to_mac      => gmii_rx_er_int,

      -- Receiver clock for the MAC client I/F
      rx_core_clk       => rx_clk_int,

      -- Receiver clock for the MAC and Client Logic
      rx_clk            => rx_gmii_clk_int
   );


   -----------------------------------------------------------------------------
   -- Instantiate the TRIMAC core
   -----------------------------------------------------------------------------
   trimac_core : ethg_mac_core
   port map (
      -- asynchronous reset
      reset                   => reset,

      -- Physical Interface of the core
      emacphytxd              => gmii_txd_int,
      emacphytxen             => gmii_tx_en_int,
      emacphytxer             => gmii_tx_er_int,
      phyemacrxd              => gmii_rxd_int,
      phyemacrxdv             => gmii_rx_dv_int,
      phyemacrxer             => gmii_rx_er_int,

      -- Client Transmitter Interface
      clientemactxd           => tx_data,
      clientemactxdvld        => tx_data_valid,
      emacclienttxack         => tx_ack,
      clientemactxunderrun    => tx_underrun,
      clientemactxifgdelay    => tx_ifg_delay,

      -- MAC Control Interface
      clientemacpausereq      => pause_req,
      clientemacpauseval      => pause_val,

      -- Client Receiver Interface
      emacclientrxd           => rx_data,
      emacclientrxdvld        => rx_data_valid,
      emacclientrxgoodframe   => rx_good_frame,
      emacclientrxbadframe    => rx_bad_frame,

      -- Client Transmitter Statistics
      emacclienttxstats       => tx_statistics_vector,
      emacclienttxstatsvld    => tx_statistics_valid,

      -- Client Receiver Statistics
      emacclientrxstats       => rx_statistics_vector,
      emacclientrxstatsvld    => rx_statistics_valid,

      -- Configuration Vector
      tieemacconfigvec        => configuration_vector,

      -- Core Clock I/Os
      txcoreclk               => tx_clk_int,
      rxcoreclk               => rx_clk_int,
      txgmiimiiclk            => tx_gmii_clk_int,
      rxgmiimiiclk            => rx_gmii_clk_int,

      -- Current Speed Indication
      speedis100              => speedis100_int,
      speedis10100            => speedis10100_int,


      -- Always tie to '0' unless connecting to the SGMII LogiCORE
      corehassgmii            => '0'
      );


end wrapper;
