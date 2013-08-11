-------------------------------------------------------------------------------
-- File       : eth10g_mac_core_physical_if.vhd
-- Author     : Xilinx Inc.
-------------------------------------------------------------------------------
-- Description: This is the Physical interface vhdl code for the
-- Ten Gigabit Etherent MAC. It may contain the Recieve clock
-- generation depending on the configuration options when
-- generated.
-------------------------------------------------------------------------------
-- (c) Copyright 2001-2012 Xilinx, Inc. All rights reserved.
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
--
-------------------------------------------------------------------------------
library unisim;
use unisim.vcomponents.all;

library ieee;
use ieee.std_logic_1164.all;

entity eth10g_mac_core_physical_if is
    port (
    reset          : in std_logic;
    rx_axis_rstn   : in std_logic;
    tx_clk0        : in  std_logic;
    tx_dcm_locked  : in  std_logic;
    xgmii_txd_core : in std_logic_vector(63 downto 0);
    xgmii_txc_core : in std_logic_vector(7 downto 0);
    xgmii_txd      : out std_logic_vector(63 downto 0);
    xgmii_txc      : out std_logic_vector(7 downto 0);
    xgmii_tx_clk   : out std_logic;
    rx_clk0        : out  std_logic;
    rx_dcm_locked  : out std_logic;
    xgmii_rx_clk   : in  std_logic;
    xgmii_rxd      : in  std_logic_vector(63 downto 0);
    xgmii_rxc      : in  std_logic_vector(7 downto 0);
    xgmii_rxd_core : out  std_logic_vector(63 downto 0);
    xgmii_rxc_core : out  std_logic_vector(7 downto 0)
    );
end eth10g_mac_core_physical_if;


architecture wrapper of eth10g_mac_core_physical_if is

  constant D_LOCAL_FAULT : bit_vector(63 downto 0) := X"0100009C0100009C";
  constant C_LOCAL_FAULT : bit_vector(7 downto 0) := "00010001";
  -----------------------------------------------------------------------------
  -- Internal Signal Declaration for XGMAC (the 10Gb/E MAC core).
  -----------------------------------------------------------------------------

--  signal vcc, gnd : std_logic;

  signal tx_dcm_locked_n: std_logic;

  signal xgmii_rx_clk_dcm : std_logic;
  signal rx_clk0_int : std_logic;
  signal rx_dcm_clk0 : std_logic;
  signal rx_reset : std_logic;
  signal rxd_sdr : std_logic_vector(63 downto 0);
  signal rxc_sdr : std_logic_vector(7 downto 0);
  signal clkfbout         : std_logic;
  signal clkfbout_buf     : std_logic;
  signal rx_mmcm_locked   : std_logic;

  attribute INIT : string;
  attribute KEEP : string;
  attribute KEEP of rx_clk0 : signal is "true";

  function bit_to_string (
    constant b : bit)
    return string is
  begin  -- bit_to_string
    if b = '1' then
      return "1";
    else
      return "0";
    end if;
  end bit_to_string;


begin
--  vcc <= '1';
--  gnd <= '0';
--  rx_reset <= reset or not rx_axis_rstn;

--  -- receive clock management
--  --  Global input clock buffer for Receiver Clock
--  xgmii_rx_clk_ibufg : IBUFG
--    port map (
--      I => xgmii_rx_clk,
--      O => xgmii_rx_clk_dcm);
--  rx_mmcm : MMCM_BASE
--  generic map
--    (BANDWIDTH            => "OPTIMIZED",
--     CLKOUT4_CASCADE      => FALSE,
--     CLOCK_HOLD           => FALSE,
--     STARTUP_WAIT         => FALSE,
--     DIVCLK_DIVIDE        => 1,
--     CLKFBOUT_MULT_F      => 6.000,
--     CLKFBOUT_PHASE       => 0.000,
--     CLKOUT0_DIVIDE_F     => 6.000,
--     CLKOUT0_PHASE        => 0.000,
--     CLKOUT0_DUTY_CYCLE   => 0.5,
--     CLKOUT1_DIVIDE       => 6,
--     CLKOUT1_PHASE        => 180.000,
--     CLKOUT1_DUTY_CYCLE   => 0.5,
--     CLKIN1_PERIOD        => 6.400,
--     REF_JITTER1          => 0.010)
--  port map (
--     CLKFBOUT    => clkfbout,
--     CLKOUT0     => rx_dcm_clk0,
--     CLKIN1      => xgmii_rx_clk_dcm,
--     LOCKED      => rx_mmcm_locked,
--     CLKFBIN     => clkfbout_buf,
--     RST         => rx_reset,
--     PWRDWN      => '0');
--
--  rx_dcm_locked <= rx_mmcm_locked;
--
--  clkf_buf : BUFG
--    port map
--     (O => clkfbout_buf,
--      I => clkfbout);
--
--  rx_bufg : BUFG
--    port map(
--      I => rx_dcm_clk0,
--      O => rx_clk0_int);

  rx_clk0 <= rx_clk0_int;


  -- infer some registers which should go into the IOBs
  p_input_ff : process (rx_clk0_int)
  begin
    if rx_clk0_int'event and rx_clk0_int = '1' then
      xgmii_rxd_core <= xgmii_rxd after 100 ps;
      xgmii_rxc_core <= xgmii_rxc after 100 ps;
    end if;
  end process p_input_ff;

  G_OUTPUT_FF_D : for I in 0 to 63 generate
  begin
    txd_oreg : FD
      generic map (
        INIT => D_LOCAL_FAULT(I))
      port map (
        Q  => xgmii_txd(I),
        C  => tx_clk0,
        D  => xgmii_txd_core(I));
  end generate;

  G_OUTPUT_FF_C : for I in 0 to 7 generate
  begin
    txc_oreg : FD
      generic map (
        INIT => C_LOCAL_FAULT(I))
      port map (
        Q  => xgmii_txc(I),
        C  => tx_clk0,
        D  => xgmii_txc_core(I));
  end generate;
--  tx_dcm_locked_n <= (not tx_dcm_locked);
--
--  tx_clk_oreg: ODDR
--    port map (
--      Q => xgmii_tx_clk,
--      D1 => '1',
--      D2 => '0',
--      C => tx_clk0,
--      CE => '1',
--      R => tx_dcm_locked_n,
--      S => '0');

  xgmii_tx_clk <= tx_clk0;

  rx_clk0_int <= tx_clk0;
  rx_dcm_locked <= tx_dcm_locked;

end wrapper;


