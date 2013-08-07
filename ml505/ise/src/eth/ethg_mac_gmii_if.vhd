--------------------------------------------------------------------------------
-- File       : gmii_if.vhd
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
-- Description:  This module creates a Gigabit Media Independent
--               Interface (GMII) by instantiating Input/Output buffers
--               and Input/Output flip-flops as required.
--
--               This interface is used to connect the Ethernet MAC to
--               an external Ethernet PHY via GMII connection.
--
--               The GMII receiver clocking logic is also defined here: the
--               receiver clock received from the PHY is unique and cannot be
--               shared across multiple instantiations of the core.  For the
--               receiver clock:
--
--               An IODELAY component is used to shift the input clock
--               to ensure that the set-up and hold times are observed.
--------------------------------------------------------------------------------

library unisim;
use unisim.vcomponents.all;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

--------------------------------------------------------------------------------
-- The entity declaration for the PHY IF design.
--------------------------------------------------------------------------------
entity gmii_if is
    port(
        -- Synchronous resets
        tx_reset                      : in  std_logic;
        rx_reset                      : in  std_logic;

        -- Current operating speed is 10/100
        speed_is_10_100               : in  std_logic;

        -- The following ports are the GMII physical interface: these will be at
        -- pins on the FPGA
        gmii_txd                      : out std_logic_vector(7 downto 0);
        gmii_tx_en                    : out std_logic;
        gmii_tx_er                    : out std_logic;
        gmii_tx_clk                   : out std_logic;
        gmii_rxd                      : in  std_logic_vector(7 downto 0);
        gmii_rx_dv                    : in  std_logic;
        gmii_rx_er                    : in  std_logic;
        gmii_rx_clk                   : in  std_logic;

        -- The following ports are the internal GMII connections from IOB logic
        -- to the TEMAC core
        txd_from_mac                  : in  std_logic_vector(7 downto 0);
        tx_en_from_mac                : in  std_logic;
        tx_er_from_mac                : in  std_logic;
        tx_clk                        : in  std_logic;
        rxd_to_mac                    : out std_logic_vector(7 downto 0);
        rx_dv_to_mac                  : out std_logic;
        rx_er_to_mac                  : out std_logic;

        -- Receiver clock for the MAC client I/F
        rx_core_clk                   : out std_logic;

        -- Receiver clock for the MAC and Client Logic
        rx_clk                        : out  std_logic
        );
end gmii_if;


architecture PHY_IF of gmii_if is


  ------------------------------------------------------------------------------
  -- Component declaration for clock divide-by-two module
  ------------------------------------------------------------------------------
  component clk_half
  port (
    reset       : in  std_logic;          -- Global Asynchronous Reset
    clk         : in  std_logic;          -- input clock
    clk_div2    : out std_logic           -- generated clock/2
    );
  end component;


  ------------------------------------------------------------------------------
  -- internal signals
  ------------------------------------------------------------------------------
  signal gmii_rx_dv_delay     : std_logic;
  signal gmii_rx_er_delay     : std_logic;
  signal gmii_rxd_delay       : std_logic_vector(7 downto 0);
  signal gmii_rx_clk_delay    : std_logic;

  signal rx_clk_int           : std_logic;
  signal rx_clk_div2          : std_logic;




begin


  ------------------------------------------------------------------------------
  -- GMII Transmitter Clock Management :
  -- drive gmii_tx_clk through IOB onto GMII interface
  ------------------------------------------------------------------------------

--   -- Instantiate a DDR output register.  This is a good way to drive
--   -- GMII_TX_CLK since the clock-to-PAD delay will be the same as that
--   -- for data driven from IOB Ouput flip-flops eg gmii_rxd[7:0].  This is set
--   -- to produce an inverted clock w.r.t. tx_clk so that
--   -- the rising edge is centralised within the
--   -- gmii_rxd[7:0] valid window.
--   gmii_tx_clk_ddr_iob : ODDR
--   port map(
--      Q           => gmii_tx_clk,
--      C           => tx_clk,
--      CE          => '1',
--      D1          => '0',
--      D2          => '1',
--      R           => '0',
--      S           => '0'
--   );
   gmii_tx_clk <= tx_clk;

   -----------------------------------------------------------------------------
   -- GMII Transmitter Logic :
   -- drive TX signals through IOBs onto GMII interface
   -----------------------------------------------------------------------------

   -- Infer IOB Output flip-flops.
   reg_gmii_tx_out : process (tx_clk)
   begin
      if tx_clk'event and tx_clk = '1' then
         gmii_tx_en        <= tx_en_from_mac;
         gmii_tx_er        <= tx_er_from_mac;
         gmii_txd          <= txd_from_mac;
      end if;
   end process reg_gmii_tx_out;


  ------------------------------------------------------------------------------
  -- GMII Receiver Clock Logic
  ------------------------------------------------------------------------------

--   -- Please modify the IDELAY_VALUE according to your design.
--   -- For more information on IDELAYCTRL and IODELAY, please refer to
--   -- the User Guide.
--   delay_gmii_rx_clk : IODELAY
--   generic map (
--      IDELAY_TYPE    => "FIXED",
--      IDELAY_VALUE   => 20,
--      DELAY_SRC      => "I"
--   )
--   port map (
--      IDATAIN        => gmii_rx_clk,
--      ODATAIN        => '0',
--      DATAOUT        => gmii_rx_clk_delay,
--      DATAIN         => '0',
--      C              => '0',
--      T              => '1',
--      CE             => '0',
--      INC            => '0',
--      RST            => '0'
--   );
   gmii_rx_clk_delay <= gmii_rx_clk;

--   -- Route IODELAY output through BUFG onto global clock network
--   bufg_gmii_rx_clk    : BUFG
--   port map (
--      I              => gmii_rx_clk_delay,
--      O              => rx_clk_int
--   );
   rx_clk_int <= gmii_rx_clk_delay;

   -- Assign the internal clock signal to the output port
   rx_clk <= rx_clk_int;


   -----------------------------------------------------------------------------
   -- GMII Receiver Logic : receive RX signals through IOBs from GMII interface
   -----------------------------------------------------------------------------

--   -- Drive input GMII Rx signals from PADS through IODELAYS.
--
--   -- Note: Delay value is set in UCF file
--   -- Please modify the IODELAY_VALUE according to your design.
--   -- For more information on IDELAYCTRL and IODELAY, please refer to
--   -- the User Guide.
--   delay_gmii_rx_dv : IODELAY
--   generic map (
--      IDELAY_TYPE    => "FIXED",
--      DELAY_SRC      => "I"
--   )
--   port map (
--      IDATAIN        => gmii_rx_dv,
--      ODATAIN        => '0',
--      DATAOUT        => gmii_rx_dv_delay,
--      DATAIN         => '0',
--      C              => '0',
--      T              => '1',
--      CE             => '0',
--      INC            => '0',
--      RST            => '0'
--   );
   gmii_rx_dv_delay <= gmii_rx_dv;

--   delay_gmii_rx_er : IODELAY
--   generic map (
--      IDELAY_TYPE    => "FIXED",
--      DELAY_SRC      => "I"
--   )
--   port map (
--      IDATAIN        => gmii_rx_er,
--      ODATAIN        => '0',
--      DATAOUT        => gmii_rx_er_delay,
--      DATAIN         => '0',
--      C              => '0',
--      T              => '1',
--      CE             => '0',
--      INC            => '0',
--      RST            => '0'
--   );
   gmii_rx_er_delay <= gmii_rx_er;

   rxdata_bus: for I in 7 downto 0 generate
--   delay_gmii_rxd : IODELAY
--   generic map (
--      IDELAY_TYPE    => "FIXED",
--      DELAY_SRC      => "I"
--   )
--   port map (
--      IDATAIN        => gmii_rxd(I),
--      ODATAIN        => '0',
--      DATAOUT        => gmii_rxd_delay(I),
--      DATAIN         => '0',
--      C              => '0',
--      T              => '1',
--      CE             => '0',
--      INC            => '0',
--      RST            => '0'
--   );
   gmii_rxd_delay(I) <= gmii_rxd(I);
   end generate;


   -- Infer IOB Input flip-flops.
   reg_gmii_rx_in : process (rx_clk_int)
   begin
      if rx_clk_int'event and rx_clk_int = '1' then
         if rx_reset = '1' then
            rx_dv_to_mac         <= '0';
            rx_er_to_mac         <= '0';
            rxd_to_mac           <= (others => '0');
         else
            rx_dv_to_mac         <= gmii_rx_dv_delay after 1 ps;
            rx_er_to_mac         <= gmii_rx_er_delay after 1 ps;
            rxd_to_mac           <= gmii_rxd_delay after 1 ps;
         end if;
      end if;
  end process reg_gmii_rx_in;



   -- When speed is 10/100, core clock is RX_CLK divided by 2.
   int_clk_div2_gen : CLK_HALF
   port map (
      RESET          => '0',
      CLK            => gmii_rx_clk_delay,
      CLK_DIV2       => rx_clk_div2
   );

   bufgmux_rx_speed_clk : BUFGMUX
   port map (
      O              => rx_core_clk,
      I0             => gmii_rx_clk_delay,
      I1             => rx_clk_div2,
      S              => speed_is_10_100
   );


   -- Assign the internal clock signal to the output port
   rx_clk <= rx_clk_int;


end PHY_IF;
