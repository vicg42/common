-------------------------------------------------------------------------------
-- File       : eth10g_mac.vhd
-- Author     : Xilinx Inc.
-------------------------------------------------------------------------------
-- Description: This is the example design level vhdl code for the
-- Ten Gigabit Etherent MAC. It contains the FIFO block level instance and
-- Transmit clock generation.  Dependent on configuration options, it  may
-- also contain the address swap module for cores with both Transmit and
-- Receive.
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

entity eth10g_mac is
  port(
    rx_axis_tdata         : out std_logic_vector(63 downto 0);
    rx_axis_tkeep         : out std_logic_vector(7 downto 0);
    rx_axis_tvalid        : out std_logic;
    rx_axis_tlast         : out std_logic;
    rx_axis_tready        : in  std_logic;

    tx_axis_tdata         : in  std_logic_vector(63 downto 0);
    tx_axis_tkeep         : in  std_logic_vector(7 downto 0);
    tx_axis_tvalid        : in  std_logic;
    tx_axis_tlast         : in  std_logic;
    tx_axis_tready        : out std_logic;
    tx_axis_tuser         : in  std_logic;

    ---------------------------------------------------------------------------
    -- Interface to the management block.
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
  attribute iob : string;
  attribute iob of tx_statistics_vector : signal is "true";
  attribute iob of tx_statistics_valid : signal is "true";
  attribute iob of rx_statistics_vector : signal is "true";
  attribute iob of rx_statistics_valid : signal is "true";
end eth10g_mac;


architecture wrapper of eth10g_mac is

  -----------------------------------------------------------------------------
  -- Component Declaration for FIFO block level
  -----------------------------------------------------------------------------
    component eth10g_mac_core_fifo_block
    generic (
      fifo_size     : integer := 512);
    port (
    reset                 : in  std_logic;

    rx_axis_fifo_aresetn  : in  std_logic;
    rx_axis_mac_aresetn   : in  std_logic;
    rx_axis_tdata         : out std_logic_vector(63 downto 0);
    rx_axis_tkeep         : out std_logic_vector(7 downto 0);
    rx_axis_tvalid        : out std_logic;
    rx_axis_tlast         : out std_logic;
    rx_axis_tready        : in  std_logic;
    tx_axis_fifo_aresetn  : in  std_logic;
    tx_axis_mac_aresetn   : in std_logic;
    tx_axis_tdata         : in  std_logic_vector(63 downto 0);
    tx_axis_tkeep         : in  std_logic_vector(7 downto 0);
    tx_axis_tvalid        : in  std_logic;
    tx_axis_tlast         : in  std_logic;
    tx_axis_tready        : out std_logic;
    tx_axis_tuser         : in   std_logic;
    tx_ifg_delay          : in   std_logic_vector(7 downto 0);
    tx_statistics_vector  : out std_logic_vector(25 downto 0);
    tx_statistics_valid   : out std_logic;
    pause_val             : in  std_logic_vector(15 downto 0);
    pause_req             : in  std_logic;
    rx_statistics_vector  : out std_logic_vector(29 downto 0);
    rx_statistics_valid   : out std_logic;
    tx_configuration_vector : in std_logic_vector(79 downto 0);
    rx_configuration_vector : in std_logic_vector(79 downto 0);
    status_vector         : out std_logic_vector(1 downto 0);
      tx_clk0             : in std_logic;
      tx_dcm_locked       : in std_logic;
      xgmii_tx_clk        : out std_logic;                     -- the TX clock from the reconcilliation sublayer.
    xgmii_txd             : out std_logic_vector(63 downto 0); -- Transmitted data
    xgmii_txc             : out std_logic_vector(7 downto 0); -- Transmitted control
    rx_clk                : out std_logic;
    rx_dcm_locked         : out std_logic;
    xgmii_rx_clk          : in  std_logic;
    xgmii_rxd             : in  std_logic_vector(63 downto 0); -- Received data
    xgmii_rxc             : in  std_logic_vector(7 downto 0)  -- received control
  );
  end component;

--   component eth10g_mac_core_address_swap
--    port (
--      rx_clk              : in  std_logic;
--      reset               : in  std_logic;
--      rx_axis_tdata       : in  std_logic_vector(63 downto 0);
--      rx_axis_tkeep       : in  std_logic_vector(7 downto 0);
--      rx_axis_tvalid      : in  std_logic;
--      rx_axis_tlast       : in  std_logic;
--      rx_axis_tready      : out std_logic;
--
--      tx_axis_tdata       : out std_logic_vector(63 downto 0);
--      tx_axis_tkeep       : out std_logic_vector(7 downto 0);
--      tx_axis_tvalid      : out std_logic;
--      tx_axis_tlast       : out std_logic;
--      tx_axis_tready      : in  std_logic
--
--      );
--   end component;
  -----------------------------------------------------------------------------
  -- Internal Signal Declaration for XGMAC (the 10Gb/E MAC core).
  -----------------------------------------------------------------------------

  attribute keep : string;
  signal gtx_clk_dcm        : std_logic;
  signal tx_dcm_clk0        : std_logic;
--  signal tx_dcm_locked      : std_logic;
  signal tx_dcm_locked_reg  : std_logic;  -- Registered version (TX_CLK0)

  signal tx_clk0  : std_logic;  -- transmit clock on global routing

--  signal vcc, gnd           : std_logic;
  signal rx_clk_int         : std_logic;
  signal rx_dcm_locked      : std_logic;

  signal tx_configuration_vector_core : std_logic_vector(79 downto 0);
  signal rx_configuration_vector_core : std_logic_vector(79 downto 0);


--  signal rx_axis_tdata_int  : std_logic_vector(63 downto 0);
--  signal rx_axis_tkeep_int  : std_logic_vector(7 downto 0);
--  signal rx_axis_tvalid_int : std_logic;
--  signal rx_axis_tlast_int  : std_logic;
--  signal rx_axis_tready_int : std_logic;
  signal rx_statistics_vector_int : std_logic_vector(29 downto 0) := (others => '0');
  signal rx_statistics_valid_int  : std_logic := '0';

  signal tx_statistics_vector_int : std_logic_vector(25 downto 0)
    := (others => '0');
  signal tx_statistics_valid_int  : std_logic := '0';
--  signal tx_axis_tdata_int  : std_logic_vector(63 downto 0);
--  signal tx_axis_tkeep_int  : std_logic_vector(7 downto 0);
--  signal tx_axis_tvalid_int : std_logic;
--  signal tx_axis_tlast_int  : std_logic;
--  signal tx_axis_ready      : std_logic;
--  signal tx_reset           :std_logic;
--  signal rx_reset           :std_logic;
  signal clkfbout           : std_logic;
  signal clkfbout_buf       : std_logic;
  signal tx_mmcm_locked     : std_logic;

begin
--  vcc <= '1';
--  gnd <= '0';
--  tx_reset   <= reset or not tx_axis_aresetn;
--  rx_reset   <= reset or not rx_axis_aresetn;


  --Wire the same pause address vector to both TX & RX config vectors
  tx_configuration_vector_core <= pause_addr_vector & tx_configuration_vector;
  rx_configuration_vector_core <= pause_addr_vector & rx_configuration_vector;
  ------------------------------
  -- Instantiate the XGMAC core
  ------------------------------
  fifo_block_i : eth10g_mac_core_fifo_block
     generic map (
        fifo_size => 1024)
    port map (
      reset                => reset,
      rx_axis_mac_aresetn  => rx_axis_aresetn,
      rx_axis_fifo_aresetn => rx_axis_aresetn,
      rx_axis_tdata        => rx_axis_tdata ,--rx_axis_tdata_int,  --: out std_logic_vector(63 downto 0);
      rx_axis_tkeep        => rx_axis_tkeep ,--rx_axis_tkeep_int,  --: out std_logic_vector(7 downto 0);
      rx_axis_tvalid       => rx_axis_tvalid,--rx_axis_tvalid_int, --: out std_logic;
      rx_axis_tlast        => rx_axis_tlast ,--rx_axis_tlast_int,  --: out std_logic;
      rx_axis_tready       => rx_axis_tready,--rx_axis_tready_int, --: in  std_logic;

      tx_axis_mac_aresetn  => tx_axis_aresetn,
      tx_axis_fifo_aresetn => tx_axis_aresetn,
      tx_axis_tdata        => tx_axis_tdata  ,--tx_axis_tdata_int, --: in  std_logic_vector(63 downto 0);
      tx_axis_tkeep        => tx_axis_tkeep  ,--tx_axis_tkeep_int, --: in  std_logic_vector(7 downto 0);
      tx_axis_tvalid       => tx_axis_tvalid ,--tx_axis_tvalid_int,--: in  std_logic;
      tx_axis_tlast        => tx_axis_tlast  ,--tx_axis_tlast_int, --: in  std_logic;
      tx_axis_tready       => tx_axis_tready ,--tx_axis_ready,     --: out std_logic;
      tx_axis_tuser        => tx_axis_tuser,

      pause_val            => pause_val,
      pause_req            => pause_req,
--      tx_axis_tuser        => tx_axis_tuser,
      tx_ifg_delay         => tx_ifg_delay,
      tx_statistics_vector => tx_statistics_vector_int,
      tx_statistics_valid  => tx_statistics_valid_int,
      rx_statistics_vector => rx_statistics_vector_int,
      rx_statistics_valid  => rx_statistics_valid_int,
      tx_configuration_vector => tx_configuration_vector_core,
      rx_configuration_vector => rx_configuration_vector_core,
      status_vector        => status_vector,
      tx_clk0              => tx_clk0,
      tx_dcm_locked        => tx_dcm_locked,
      xgmii_tx_clk         => xgmii_tx_clk,
      xgmii_txd            => xgmii_txd,
      xgmii_txc            => xgmii_txc,
      rx_clk               => rx_clk_int,
      rx_dcm_locked        => rx_dcm_locked,
      xgmii_rx_clk         => xgmii_rx_clk,
      xgmii_rxd            => xgmii_rxd,
      xgmii_rxc            => xgmii_rxc
);

--  address_swap_i : eth10g_mac_core_address_swap
--    port map (
--      rx_clk            =>  rx_clk_int,
--      reset             =>  rx_reset,
--      rx_axis_tdata     =>  rx_axis_tdata_int,
--      rx_axis_tkeep     =>  rx_axis_tkeep_int,
--      rx_axis_tvalid    =>  rx_axis_tvalid_int,
--      rx_axis_tlast     =>  rx_axis_tlast_int,
--      rx_axis_tready    =>  rx_axis_tready_int,
--      tx_axis_tdata     =>  tx_axis_tdata_int,
--      tx_axis_tkeep     =>  tx_axis_tkeep_int,
--      tx_axis_tvalid    =>  tx_axis_tvalid_int,
--      tx_axis_tlast     =>  tx_axis_tlast_int,
--      tx_axis_tready    =>  tx_axis_ready
--   );

--  -- Transmit clock management
--  gtx_clk_ibufg : IBUFG
--    port map (
--      I => gtx_clk,
--      O => gtx_clk_dcm);
--
--
--
--  -- Clock management
--  tx_mmcm : MMCM_BASE
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
--     CLKIN1_PERIOD        => 6.400,
--     REF_JITTER1          => 0.010)
--  port map (
--     CLKFBOUT    => clkfbout,
--     CLKOUT0     => tx_dcm_clk0,
--     CLKIN1      => gtx_clk_dcm,
--     LOCKED      => tx_mmcm_locked,
--     CLKFBIN     => clkfbout_buf,
--     RST         => tx_reset,
--     PWRDWN      => '0');
--
--  tx_dcm_locked <= tx_mmcm_locked;
--
--  clkf_buf : BUFG
--    port map
--     (O => clkfbout_buf,
--      I => clkfbout);
--
--  tx_bufg0 : BUFG
--    port map (
--      I => tx_dcm_clk0,
--      O => tx_clk0);

tx_clk0 <= gtx_clk;

  -- We are explicitly instancing an OBUF for this signal because if we
  -- make a simple assignement and rely on XST to put the OBUF in, it
  -- will munge the name of the tx_clk0 net into a new name and the UCF
  -- clock constraint will no longer attach in ngdbuild.
  --tx_clk_obuf : OBUF
  --  port map (
  --    I => tx_clk0,
  --    O => tx_clk);




   p_tx_statistic_vector_regs : process (tx_clk0)
   begin
     if tx_clk0'event and tx_clk0 = '1' then
       tx_statistics_vector <= tx_statistics_vector_int;
       tx_statistics_valid  <= tx_statistics_valid_int;
     end if;
   end process p_tx_statistic_vector_regs;
   p_rx_statistic_vector_reg : process (rx_clk_int)
   begin
     if rx_clk_int'event and rx_clk_int = '1' then
       rx_statistics_vector <= rx_statistics_vector_int;
       rx_statistics_valid  <= rx_statistics_valid_int;
     end if;
   end process p_rx_statistic_vector_reg;

end wrapper;


