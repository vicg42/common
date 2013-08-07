--------------------------------------------------------------------------------
-- File       : ethg_mac.vhd
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
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;


--------------------------------------------------------------------------------
-- The entity declaration for the example_design level wrapper.
--------------------------------------------------------------------------------

entity ethg_mac is
    port(
      --FPGA <- ETH
--      rx_ll_clock          : out std_logic;
      rx_ll_data_out       : out std_logic_vector(7 downto 0);
      rx_ll_sof_out_n      : out std_logic;
      rx_ll_eof_out_n      : out std_logic;
      rx_ll_src_rdy_out_n  : out std_logic;
      rx_ll_dst_rdy_in_n   : in  std_logic;

      --FPGA -> ETH
--      tx_ll_clock          : out std_logic;
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
--      rx_statistics_valid  : out std_logic;

      -- Client Transmitter Statistics Interface
      ------------------------------------------
      tx_clk               : out std_logic;
      tx_statistics_vector : out std_logic;
--      tx_statistics_valid  : out std_logic;

     -- MAC Control Interface
      ------------------------
--      pause_req            : in  std_logic;
--      pause_val            : in  std_logic;
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
end ethg_mac;



architecture wrapper of ethg_mac is


  ------------------------------------------------------------------------------
  -- Component Declaration for the Tri-Mode EMAC core LocalLink wrapper
  ------------------------------------------------------------------------------
  component ethg_mac_core_locallink
    port(
      -- asynchronous reset
      reset                : in  std_logic;

      -- Reference clock for IDELAYCTRL's
      refclk               : in  std_logic;

      -- Client Receiver Statistics Interface
      ---------------------------------------
      rx_clk               : out std_logic;
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

      -- Configuration Vector
      -----------------------
      configuration_vector : in  std_logic_vector(67 downto 0)
      );
   end component;


--   -----------------------------------------------------------------------------
--   --  Component Declaration for address swapping module
--   -----------------------------------------------------------------------------
--   component address_swap_module
--   port (
--      rx_ll_clock          : in  std_logic;
--      rx_ll_reset          : in  std_logic;
--      rx_ll_data_in        : in  std_logic_vector(7 downto 0);
--      rx_ll_sof_in_n       : in  std_logic;
--      rx_ll_eof_in_n       : in  std_logic;
--      rx_ll_src_rdy_in_n   : in  std_logic;
--      rx_ll_data_out       : out std_logic_vector(7 downto 0);
--      rx_ll_sof_out_n      : out std_logic;
--      rx_ll_eof_out_n      : out std_logic;
--      rx_ll_src_rdy_out_n  : out std_logic;
--      rx_ll_dst_rdy_in_n   : in  std_logic
--      );
--   end component;


  ------------------------------------------------------------------------------
  -- Component declaration for the reset synchroniser
  ------------------------------------------------------------------------------
  component reset_sync
  port (
    reset_in               : in  std_logic;    -- Active high asynchronous reset
    clk                    : in  std_logic;    -- clock to be sync'ed to
    enable                 : in  std_logic;    -- allows control of reset removal
    reset_out              : out std_logic     -- "Synchronised" reset signal
    );
  end component;



  ------------------------------------------------------------------------------
  -- internal signals used in this example_design level wrapper.
  ------------------------------------------------------------------------------

  signal tx_clk_int        : std_logic;      -- Internal Tx core clock signal.
  signal rx_clk_int        : std_logic;      -- Internal Rx core clock signal


  signal refclk_bufg       : std_logic;      -- refclk routed through a BUFG.

  -- Tx LocalLink FIFO I/F
  signal tx_reset          : std_logic;
  signal tx_ll_clk         : std_logic;
  signal tx_ll_pre_reset   : std_logic_vector(5 downto 0);
  signal tx_ll_reset       : std_logic;
  signal tx_ll_data        : std_logic_vector(7 downto 0);
  signal tx_ll_sof_n       : std_logic;
  signal tx_ll_eof_n       : std_logic;
  signal tx_ll_src_rdy_n   : std_logic;
  signal tx_ll_dst_rdy_n   : std_logic;

  -- Rx LocalLink FIFO I/F
  signal rx_ll_clk         : std_logic;
  signal rx_ll_reset       : std_logic;
  signal rx_ll_data        : std_logic_vector(7 downto 0);
  signal rx_ll_sof_n       : std_logic;
  signal rx_ll_eof_n       : std_logic;
  signal rx_ll_src_rdy_n   : std_logic;
  signal rx_ll_dst_rdy_n   : std_logic;

  -- Internal and Registered versions of Tx and Rx Statistic Vectors
  signal rx_statistics_vector_int : std_logic_vector(27 downto 0);
  signal rx_statistics_valid_int  : std_logic;
  signal tx_statistics_vector_int : std_logic_vector(31 downto 0);
  signal tx_statistics_valid_int  : std_logic;
  signal rx_statistics_valid_reg  : std_logic_vector(27 downto 0);
  signal rx_statistics_vector_reg : std_logic_vector(27 downto 0);
  signal tx_statistics_valid_reg  : std_logic_vector(31 downto 0);
  signal tx_statistics_vector_reg : std_logic_vector(31 downto 0);

--  signal pause_val_reg            : std_logic_vector(15 downto 0);
--  signal pause_req_reg            : std_logic_vector(15 downto 0);

  signal tx_ifg_delay             : std_logic_vector(7 downto 0) := X"00";

  attribute keep : string;
  attribute keep of tx_ifg_delay  : signal is "true";



begin


---- Drive client clocks off chip
---- DDr logic is used for this purpose to ensure that clock routing/timing to the pin is
---- balanced as part of the clock tree
--    rx_clk_ddr : ODDR
--    port map (
--      Q                     => rx_clk,
--      C                     => rx_clk_int,
--      CE                    => '1',
--      D1                    => '1',
--      D2                    => '0',
--      R                     => reset,
--      S                     => '0'
--   );
rx_clk <= rx_clk_int;

--    tx_clk_ddr : ODDR
--    port map (
--      Q                     => tx_clk,
--      C                     => tx_clk_int,
--      CE                    => '1',
--      D1                    => '1',
--      D2                    => '0',
--      R                     => reset,
--      S                     => '0'
--   );
tx_clk <= tx_clk_int;

--  ------------------------------------------------------------------------------
--  -- REFCLK used for IODELAYCTRL primitive : Need to supply a 200MHz clock
--  ------------------------------------------------------------------------------
--  refclk_bufg_i  : BUFG  port map(I => refclk, O => refclk_bufg);
refclk_bufg <= refclk;

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
rx_statistics_vector <= '0';

--  ------------------------------------------------------------------------------
--  -- Prepare the Tx statistic vector for IOB's
--  ------------------------------------------------------------------------------
--
--  serialize_tx_stats : process(tx_clk_int)
--  begin
--    if (tx_clk_int'event and tx_clk_int = '1') then
--       if tx_statistics_valid_int = '1' then
--          tx_statistics_valid_reg  <= tx_statistics_valid_reg(30 downto 0) & tx_statistics_valid_int;
--          tx_statistics_vector_reg <= tx_statistics_vector_int;
--       else
--          tx_statistics_valid_reg  <= tx_statistics_valid_reg(30 downto 0) & '0';
--          tx_statistics_vector_reg <= tx_statistics_vector_reg(30 downto 0) & '0';
--       end if;
--    end if;
--  end process;
--
--  -- Route Statistics to Output ports
--  tx_statistics_vector <= tx_statistics_vector_reg(31);
--
--  tx_statistics_valid <= tx_statistics_valid_reg(31);
tx_statistics_vector <= '0';

--  ------------------------------------------------------------------------------
--  -- CApture the pause request -serialised to reduce IO
--  ------------------------------------------------------------------------------
--  serialize_pause : process(tx_clk_int)
--  begin
--    if (tx_clk_int'event and tx_clk_int = '1') then
--       if pause_req = '1' then
--          pause_req_reg  <= pause_req_reg(14 downto 0) & pause_req;
--       else
--          pause_req_reg  <= pause_req_reg(14 downto 0) & '0';
--       end if;
--       pause_val_reg <= pause_val_reg(14 downto 0) & pause_val;
--   end if;
--  end process;


  ------------------------------------------------------------------------------
  -- Instantiate the Tri-Mode EMAC core LocalLink wrapper
  ------------------------------------------------------------------------------
  trimac_locallink : ethg_mac_core_locallink
    port map (
      -- asynchronous reset
      reset                 => reset,

      -- Reference clock for IDELAYCTRL's
      refclk                => refclk_bufg,

      -- Client Receiver Statistics Interface
      rx_clk                => rx_clk_int,
      rx_statistics_vector  => rx_statistics_vector_int,
      rx_statistics_valid   => rx_statistics_valid_int,

      -- Client Receiver (LocalLink) Interface
      rx_ll_clock           => rx_ll_clk,
      rx_ll_reset           => rx_ll_reset,
      rx_ll_data_out        => rx_ll_data_out     ,--: out std_logic_vector(7 downto 0); rx_ll_data,      --
      rx_ll_sof_out_n       => rx_ll_sof_out_n    ,--: out std_logic;                    rx_ll_sof_n,     --
      rx_ll_eof_out_n       => rx_ll_eof_out_n    ,--: out std_logic;                    rx_ll_eof_n,     --
      rx_ll_src_rdy_out_n   => rx_ll_src_rdy_out_n,--: out std_logic;                    rx_ll_src_rdy_n, --
      rx_ll_dst_rdy_in_n    => rx_ll_dst_rdy_in_n ,--: in  std_logic;                    rx_ll_dst_rdy_n, --


      -- Client Transmitter Statistics Interface
      tx_clk                => tx_clk_int,
      tx_ifg_delay          => tx_ifg_delay,
      tx_statistics_vector  => tx_statistics_vector_int,
      tx_statistics_valid   => tx_statistics_valid_int,

      -- Client Transmitter (LocalLink) Interface
      tx_ll_clock           => tx_ll_clk,
      tx_ll_reset           => tx_ll_reset,
      tx_ll_data_in         => tx_ll_data_in      ,--: in  std_logic_vector(7 downto 0);--tx_ll_data,     --
      tx_ll_sof_in_n        => tx_ll_sof_in_n     ,--: in  std_logic;                   --tx_ll_sof_n,    --
      tx_ll_eof_in_n        => tx_ll_eof_in_n     ,--: in  std_logic;                   --tx_ll_eof_n,    --
      tx_ll_src_rdy_in_n    => tx_ll_src_rdy_in_n ,--: in  std_logic;                   --tx_ll_src_rdy_n,--
      tx_ll_dst_rdy_out_n   => tx_ll_dst_rdy_out_n,--: out std_logic;                   --tx_ll_dst_rdy_n,--

      -- Flow Control
      pause_req             => pause_req,--pause_req_reg(15),
      pause_val             => pause_val,--pause_val_reg,

      -- GMII Interface
      gtx_clk               => gtx_clk,
      gmii_txd              => gmii_txd,
      gmii_tx_en            => gmii_tx_en,
      gmii_tx_er            => gmii_tx_er,
      gmii_tx_clk           => gmii_tx_clk,
      gmii_rxd              => gmii_rxd,
      gmii_rx_dv            => gmii_rx_dv,
      gmii_rx_er            => gmii_rx_er,
      gmii_rx_clk           => gmii_rx_clk,
      mii_tx_clk            => mii_tx_clk,

      -- Configuration Vector
      configuration_vector  => configuration_vector
    );


--  ------------------------------------------------------------------------------
--  --  Instantiate the address swapping module
--  ------------------------------------------------------------------------------
--  client_side_asm : address_swap_module
--    port map (
--      rx_ll_clock           => tx_clk_int,
--      rx_ll_reset           => tx_ll_reset,
--      rx_ll_data_in         => rx_ll_data,
--      rx_ll_sof_in_n        => rx_ll_sof_n,
--      rx_ll_eof_in_n        => rx_ll_eof_n,
--      rx_ll_src_rdy_in_n    => rx_ll_src_rdy_n,
--      rx_ll_data_out        => tx_ll_data,
--      rx_ll_sof_out_n       => tx_ll_sof_n,
--      rx_ll_eof_out_n       => tx_ll_eof_n,
--      rx_ll_src_rdy_out_n   => tx_ll_src_rdy_n,
--      rx_ll_dst_rdy_in_n    => tx_ll_dst_rdy_n
--    );
--
--
--  -- The Address Swapping Module also implements loopback from Rx FIFO to Tx.
--  -- The following assignment completes the loopback:
--  rx_ll_dst_rdy_n <= tx_ll_dst_rdy_n;


end wrapper;
