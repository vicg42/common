-------------------------------------------------------------------------------
-- Title      : Demo testbench
-- Project    : 10 Gigabit Ethernet MAC
-------------------------------------------------------------------------------
-- File       : demo_tb.vhd
-------------------------------------------------------------------------------
-- Description: This testbench will exercise the ports of the MAC core to
--              demonstrate the functionality.
-------------------------------------------------------------------------------
-- (c) Copyright 2004-2012 Xilinx, Inc. All rights reserved.
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
-- This testbench performs the following operations on the MAC core:
--  - The clock divide register is set for MIIM operation.
--  - The XGMII/XAUI port is wired as a loopback, so that transmitted frames
--    are then injected into the receiver.
--  - Four frames are pushed into the transmitter. The first is a minimum
--    length frame, the second is slightly longer, the third has an underrun
--    asserted and the fourth is less than minimum length and is hence padded
--    by the transmitter up to the minimum.
--  - These frames are then parsed by the receiver, which supplies the data out
--    on it's client interface. The testbench verifies that this data matches
--    that injected into the transmitter.

entity eth10g_mac_tb is
   generic (
      func_sim : boolean := false);
end eth10g_mac_tb;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
architecture behav of eth10g_mac_tb is

  signal axis_clk_out       : std_logic;

  signal tx_axis_tdata_int  : std_logic_vector(63 downto 0);
  signal tx_axis_tkeep_int  : std_logic_vector(7 downto 0);
  signal tx_axis_tvalid_int : std_logic;
  signal tx_axis_tlast_int  : std_logic;
  signal tx_axis_ready      : std_logic;

  signal rx_axis_tdata_int  : std_logic_vector(63 downto 0);
  signal rx_axis_tkeep_int  : std_logic_vector(7 downto 0);
  signal rx_axis_tvalid_int : std_logic;
  signal rx_axis_tlast_int  : std_logic;
  signal rx_axis_tready_int : std_logic;

   component eth10g_mac_core_address_swap
    port (
      rx_clk              : in  std_logic;
      reset               : in  std_logic;
      rx_axis_tdata       : in  std_logic_vector(63 downto 0);
      rx_axis_tkeep       : in  std_logic_vector(7 downto 0);
      rx_axis_tvalid      : in  std_logic;
      rx_axis_tlast       : in  std_logic;
      rx_axis_tready      : out std_logic;

      tx_axis_tdata       : out std_logic_vector(63 downto 0);
      tx_axis_tkeep       : out std_logic_vector(7 downto 0);
      tx_axis_tvalid      : out std_logic;
      tx_axis_tlast       : out std_logic;
      tx_axis_tready      : in  std_logic

      );
   end component;

  -----------------------------------------------------------------------------
  -- Component Declaration for Example Design (the top level wrapper example).
  -----------------------------------------------------------------------------
  component eth10g_mac
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

    axis_clk_out : out std_logic;
--    tx_dcm_locked  : in std_logic;

    ---------------------------------------------------------------------------
    -- Interface to the host.
    ---------------------------------------------------------------------------
    reset                   : in  std_logic;                     -- Resets the MAC.
    tx_axis_aresetn         : in  std_logic;
--    tx_axis_tuser           : in   std_logic; -- Temporary. IFG delay.
    tx_ifg_delay            : in   std_logic_vector(7 downto 0); -- Temporary. IFG delay.
    tx_statistics_vector    : out std_logic_vector(25 downto 0); -- Statistics information on the last frame.
    tx_statistics_valid     : out std_logic;                     -- High when stats are valid.

    pause_val               : in  std_logic_vector(15 downto 0); -- Indicates the length of the pause that should be transmitted.
    pause_req               : in  std_logic;                     -- A '1' indicates that a pause frame should  be sent.
    rx_axis_aresetn         : in  std_logic;
    rx_statistics_vector    : out std_logic_vector(29 downto 0); -- Statistics info on the last received frame.
    rx_statistics_valid     : out std_logic;                      -- High when above stats are valid.
    tx_configuration_vector : in std_logic_vector(31 downto 0);
    rx_configuration_vector : in std_logic_vector(31 downto 0);
    pause_addr_vector       : in std_logic_vector(47 downto 0);
    status_vector           : out std_logic_vector(1 downto 0);
    gtx_clk                 : in  std_logic;                     -- The global transmit clock from the outside world.
    xgmii_tx_clk            : out std_logic;                     -- the TX clock from the reconcilliation sublayer.
    xgmii_txd               : out std_logic_vector(63 downto 0); -- Transmitted data
    xgmii_txc               : out std_logic_vector(7 downto 0);  -- Transmitted control
    xgmii_rx_clk            : in  std_logic;                     -- The rx clock from the PHY layer.
    xgmii_rxd               : in  std_logic_vector(63 downto 0); -- Received data
    xgmii_rxc               : in  std_logic_vector(7 downto 0)  -- received control
);
end component;


  -- Address of management configuration register
  constant CONFIG_MANAGEMENT : std_logic_vector(31 downto 0) := X"00000500";
  -- Address of flow control configuration register
  constant CONFIG_FLOW_CTRL  : std_logic_vector(31 downto 0) := X"0000040C";
  -- addresses of statistics registers
  constant STATS_TX_OK       : std_logic_vector(31 downto 0) := X"000002D8";
  constant STATS_TX_UNDERRUN : std_logic_vector(31 downto 0) := X"000002F0";
  constant STATS_RX_OK       : std_logic_vector(31 downto 0) := X"00000290";
  constant STATS_RX_FCS_ERR  : std_logic_vector(31 downto 0) := X"00000298";

  constant RX_CLK_PERIOD     : time := 6400 ps;

  -----------------------------------------------------------------------------
  -- types to support frame data
  -----------------------------------------------------------------------------
  -- COLUMN_TYP is a type declaration for an object to hold an single
  -- XGMII column's information on the client interface i.e. 32 bit
  -- data/4 bit control. It holds both the data bytes and the valid signals
  -- for each byte lane.
  type COLUMN_TYP is record             -- Single column on client I/F
                       D : bit_vector(31 downto 0);  -- Data
                       C : bit_vector(3 downto 0);   -- Control
                     end record;
  type COLUMN_ARY_TYP is array (natural range <>) of COLUMN_TYP;
  -- FRAME_TYPE is a type declaration for an object to hold an entire frame of
  -- information. The columns which make up the frame are held in here, along
  -- with a flag to say whether the underrun flag should be asserted to the
  -- core on this frame. If TRUE, this underrun occurs on the clock cycle
  -- *after* the last column of data defined in the frame record.
  type FRAME_TYP is record
                      COLUMNS  : COLUMN_ARY_TYP(0 to 31);
                      CRC : bit_vector(31 downto 0);
                      LOOPBACK_CRC : bit_vector(31 downto 0);
                      UNDERRUN : boolean;            -- should this frame cause
                                                     -- underrun/error?
                    end record;
  type FRAME_TYP_ARY is array (natural range <>) of FRAME_TYP;

  -----------------------------------------------------------------------------
  -- Stimulus - Frame data
  -----------------------------------------------------------------------------
  -- The following constant holds the stimulus for the testbench. It is an
  -- ordered array of frames, with frame 0 the first to be injected into the
  -- core transmit interface by the testbench. See the datasheet for the
  -- position of the Ethernet fields within each frame.
  constant FRAME_DATA : FRAME_TYP_ARY := (
    0          => (                     -- Frame 0
      COLUMNS  => (
        0      => (D => X"04030201", C => X"F"),
        1      => (D => X"02020605", C => X"F"),
        2      => (D => X"06050403", C => X"F"),
        3      => (D => X"55AA2E00", C => X"F"),
        4      => (D => X"AA55AA55", C => X"F"),
        5      => (D => X"55AA55AA", C => X"F"),
        6      => (D => X"AA55AA55", C => X"F"),
        7      => (D => X"55AA55AA", C => X"F"),
        8      => (D => X"AA55AA55", C => X"F"),
        9      => (D => X"55AA55AA", C => X"F"),
        10     => (D => X"AA55AA55", C => X"F"),
        11     => (D => X"55AA55AA", C => X"F"),
        12     => (D => X"AA55AA55", C => X"F"),
        13     => (D => X"55AA55AA", C => X"F"),
        14     => (D => X"AA55AA55", C => X"F"),
        15     => (D => X"00000000", C => X"0"),
        others => (D => X"00000000", C => X"0")),
      CRC => X"0D4820F6",
      LOOPBACK_CRC => X"0727CB70",
      UNDERRUN => false),
    1          => (                     -- Frame 1
      COLUMNS  => (
        0      => (D => X"03040506", C => X"F"),
        1      => (D => X"05060102", C => X"F"),
        2      => (D => X"02020304", C => X"F"),
        3      => (D => X"EE110080", C => X"F"),
        4      => (D => X"11EE11EE", C => X"F"),
        5      => (D => X"EE11EE11", C => X"F"),
        6      => (D => X"11EE11EE", C => X"F"),
        7      => (D => X"EE11EE11", C => X"F"),
        8      => (D => X"11EE11EE", C => X"F"),
        9      => (D => X"EE11EE11", C => X"F"),
        10     => (D => X"11EE11EE", C => X"F"),
        11     => (D => X"EE11EE11", C => X"F"),
        12     => (D => X"11EE11EE", C => X"F"),
        13     => (D => X"EE11EE11", C => X"F"),
        14     => (D => X"11EE11EE", C => X"F"),
        15     => (D => X"EE11EE11", C => X"F"),
        16     => (D => X"11EE11EE", C => X"F"),
        17     => (D => X"EE11EE11", C => X"F"),
        18     => (D => X"11EE11EE", C => X"F"),
        19     => (D => X"EE11EE11", C => X"F"),
        20     => (D => X"11EE11EE", C => X"F"),
        21     => (D => X"0000EE11", C => X"3"),
        others => (D => X"00000000", C => X"0")),
      CRC => X"DE13388C",
      LOOPBACK_CRC => X"AD18E8E5",
      UNDERRUN => false),
    2          => (                     -- Frame 2
      COLUMNS  => (
        0      => (D => X"04030201", C => X"F"),
        1      => (D => X"02020605", C => X"F"),
        2      => (D => X"06050403", C => X"F"),
        3      => (D => X"55AA2E80", C => X"F"),
        4      => (D => X"AA55AA55", C => X"F"),
        5      => (D => X"55AA55AA", C => X"F"),
        6      => (D => X"AA55AA55", C => X"F"),
        7      => (D => X"55AA55AA", C => X"F"),
        8      => (D => X"AA55AA55", C => X"F"),
        9      => (D => X"55AA55AA", C => X"F"),
        10     => (D => X"AA55AA55", C => X"F"),
        11     => (D => X"55AA55AA", C => X"F"),
        12     => (D => X"AA55AA55", C => X"F"),
        13     => (D => X"55AA55AA", C => X"F"),
        14     => (D => X"AA55AA55", C => X"F"),
        15     => (D => X"55AA55AA", C => X"F"),
        16     => (D => X"AA55AA55", C => X"F"),
        17     => (D => X"55AA55AA", C => X"F"),
        18     => (D => X"AA55AA55", C => X"F"),
        19     => (D => X"55AA55AA", C => X"F"),
        others => (D => X"00000000", C => X"0")),
      CRC => X"20C6B69D",
      LOOPBACK_CRC => X"B34B7F4B",
      UNDERRUN => true),                -- Underrun this frame
    3          => (
      COLUMNS  => (
        0      => (D => X"03040506", C => X"F"),
        1      => (D => X"05060102", C => X"F"),
        2      => (D => X"02020304", C => X"F"),
        3      => (D => X"EE111500", C => X"F"),
        4      => (D => X"11EE11EE", C => X"F"),
        5      => (D => X"EE11EE11", C => X"F"),
        6      => (D => X"11EE11EE", C => X"F"),
        7      => (D => X"EE11EE11", C => X"F"),
        8      => (D => X"00EE11EE", C => X"7"),
        others => (D => X"00000000", C => X"0")),  -- This frame will need to
                                                   -- be padded
      CRC => X"6B734A56",
      LOOPBACK_CRC => X"2FD1D77A",
      UNDERRUN => false));

  -- DUT signals
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

  signal tx_configuration_vector : std_logic_vector(31 downto 0)
          := X"00000016";
  signal rx_configuration_vector : std_logic_vector(31 downto 0)
          := X"00000016";
  signal pause_addr_vector       : std_logic_vector(47 downto 0)
          := X"000000000000";
  signal status_vector : std_logic_vector(1 downto 0);
  signal gtx_clk      : std_logic := '0';
  signal xgmii_tx_clk : std_logic;
  signal xgmii_txd    : std_logic_vector(63 downto 0);
  signal xgmii_txc    : std_logic_vector(7 downto 0);
  signal xgmii_rx_clk : std_logic := '0';
  signal xgmii_rxd    : std_logic_vector(63 downto 0) := X"0707070707070707";
  signal xgmii_rxc    : std_logic_vector(7 downto 0) := "11111111";

  -- testbench control semaphores
  signal tx_monitor_finished : boolean := false;
  signal rx_monitor_finished : boolean := true;
  signal tx_monitor_errors   : boolean := false;
  signal simulation_finished : boolean := false;
  signal simulation_errors   : boolean := false;
begin  -- behav

  aresetn <= not reset;
  -----------------------------------------------------------------------------
  -- Wire up Device Under Test
  -----------------------------------------------------------------------------
  dut: eth10g_mac
    port map (
    rx_axis_tdata         =>  rx_axis_tdata_int,
    rx_axis_tkeep         =>  rx_axis_tkeep_int,
    rx_axis_tvalid        =>  rx_axis_tvalid_int,
    rx_axis_tlast         =>  rx_axis_tlast_int,
    rx_axis_tready        =>  rx_axis_tready_int,

    tx_axis_tdata         =>  tx_axis_tdata_int,
    tx_axis_tkeep         =>  tx_axis_tkeep_int,
    tx_axis_tvalid        =>  tx_axis_tvalid_int,
    tx_axis_tlast         =>  tx_axis_tlast_int,
    tx_axis_tready        =>  tx_axis_ready,
    tx_axis_tuser         => '0',

    axis_clk_out => axis_clk_out,
--    tx_dcm_locked => '1',

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
      gtx_clk                 => gtx_clk,
      xgmii_tx_clk            => xgmii_tx_clk,
      xgmii_txd               => xgmii_txd,
      xgmii_txc               => xgmii_txc,
      xgmii_rx_clk            => xgmii_rx_clk,
      xgmii_rxd               => xgmii_rxd,
      xgmii_rxc               => xgmii_rxc
);

  tx_ifg_delay <= (others => '0');      -- dummy up port
  tx_axis_tuser <= '0';      -- dummy up port


  -----------------------------------------------------------------------------
  -- Clock drivers
  -----------------------------------------------------------------------------
  p_gtx_clk : process                   -- drives GTX_CLK at 156.25 MHz
  begin
    gtx_clk <= '0';
    loop
      wait for 3.2 ns;                  -- 156.25 MHz GTX_CLK
      gtx_clk <= '1';
      wait for 3.2 ns;
      gtx_clk <= '0';
    end loop;
  end process p_gtx_clk;
  p_xgmii_rx_clk : process
  begin
    xgmii_rx_clk <= '0';
    wait for 1 ns;
    loop
      wait for 3.2 ns;
      xgmii_rx_clk <= '1';
      wait for 3.2 ns;
      xgmii_rx_clk <= '0';
    end loop;
  end process p_xgmii_rx_clk;



  -----------------------------------------------------------------------------
  -- Transmit Monitor process. This process checks the data coming out
  -- of the transmitter to make sure that it matches that inserted
  -- into the transmitter.
  -----------------------------------------------------------------------------
  p_tx_monitor : process
    variable cached_column_valid : boolean := false;
    variable cached_column_data : std_logic_vector(31 downto 0);
    variable cached_column_ctrl : std_logic_vector(3 downto 0);
    variable current_frame : natural := 0;

    procedure get_next_column (
      variable d : out std_logic_vector(31 downto 0);
      variable c : out std_logic_vector(3 downto 0)) is
    begin  -- get_next_column
      if cached_column_valid then
        d := cached_column_data;
        c := cached_column_ctrl;
        cached_column_valid := false;
      else
        wait until xgmii_tx_clk = '0';
        d := xgmii_txd(31 downto 0);
        c := xgmii_txc(3 downto 0);
        cached_column_data := xgmii_txd(63 downto 32);
        cached_column_ctrl := xgmii_txc(7 downto 4);
        cached_column_valid := true;
      end if;
    end get_next_column;

    procedure check_frame (
      constant frame : in frame_typ) is
      variable d : std_logic_vector(31 downto 0) := X"07070707";
      variable c : std_logic_vector(3 downto 0) := "1111";
      variable column_index, lane_index : integer;
      variable crc_candidate : std_logic_vector(31 downto 0);
    begin
      -- Wait for start code
      while not (d(7 downto 0) = X"FB" and c(0) = '1') loop
        get_next_column(d,c);
      end loop;
      get_next_column(d,c);             -- skip rest of preamble
      get_next_column(d,c);
      column_index := 0;
      -- test complete columns
      while frame.columns(column_index).c = "1111" loop
        if column_index = 0 then
            if d /= to_stdlogicvector(frame.columns(column_index+2).d(15 downto 0)) &
               to_stdlogicvector(frame.columns(column_index+1).d(31 downto 16)) then
               -- only report an error if it should be an intact frame
               if not frame.underrun then
                 report "Transmit fail: data mismatch at PHY interface"
                     severity error;
                 tx_monitor_errors <= true;
               end if;
               return;
            end if;
         elsif column_index = 1 then
            if d /= to_stdlogicvector(frame.columns(column_index-1).d(15 downto 0)) &
               to_stdlogicvector(frame.columns(column_index+1).d(31 downto 16)) then
               -- only report an error if it should be an intact frame
               if not frame.underrun then
                 report "Transmit fail: data mismatch at PHY interface"
                     severity error;
                 tx_monitor_errors <= true;
               end if;
               return;
            end if;
         elsif column_index = 2 then
            if d /= to_stdlogicvector(frame.columns(column_index-1).d(15 downto 0)) &
               to_stdlogicvector(frame.columns(column_index-2).d(31 downto 16)) then
               -- only report an error if it should be an intact frame
               if not frame.underrun then
                 report "Transmit fail: data mismatch at PHY interface"
                     severity error;
                 tx_monitor_errors <= true;
               end if;
               return;
            end if;

         else
            if d /= to_stdlogicvector(frame.columns(column_index).d) then
               -- only report an error if it should be an intact frame
               if not frame.underrun then
                 report "Transmit fail: data mismatch at PHY interface"
                     severity error;
                 tx_monitor_errors <= true;
               end if;
               return;                  -- end of comparison for this frame
            end if;
         end if;

        column_index := column_index + 1;
        get_next_column(d,c);
      end loop;
      -- now deal with the final partial column
      lane_index := 0;
      while frame.columns(column_index).c(lane_index) = '1' loop
        if d(lane_index*8+7 downto lane_index*8) /=
          to_stdlogicvector(frame.columns(column_index).d(lane_index*8+7 downto lane_index*8)) then
          -- only report an error if it should be an intact frame
          if not frame.underrun then
            report "Transmit fail: data mismatch at PHY interface"
                severity error;
            tx_monitor_errors <= true;
          end if;
          return;                       -- end of comparison for this frame
        end if;
        lane_index := lane_index + 1;
      end loop;

      -- now look for the CRC. There may be padding before it appears
      -- so we can't go blindly looking for the crc in the next 4
      -- bytes.  lane_index is the first padding or crc
      -- byte. initialise a candidate to the next four bytes then look
      -- for a non-data byte
      for i in 3 downto 0 loop
        if c(lane_index) = '1' then
          if not frame.underrun then
            report "Transmit fail: early terminate at PHY interface"
                severity error;
            tx_monitor_errors <= true;
          end if;
          return;
        end if;
        crc_candidate(i*8+7 downto i*8)
          := d(lane_index*8+7 downto lane_index*8);
        lane_index := lane_index + 1;
        if lane_index = 4 then
          get_next_column(d,c);
          lane_index := 0;
        end if;
      end loop;  -- i
      while c(lane_index) = '0' loop
        crc_candidate := crc_candidate(23 downto 0)
                         & d(lane_index*8+7 downto lane_index*8);
        lane_index := lane_index + 1;
        if lane_index = 4 then
          get_next_column(d,c);
          lane_index := 0;
        end if;
      end loop;
      -- test the gathered CRC against the specified one.
      if crc_candidate /= to_stdlogicvector(frame.LOOPBACK_CRC) then
        report "Transmit fail: CRC mismatch at PHY interface"
            severity error;
        tx_monitor_errors <= true;
      end if;
      report "Transmitter: Frame completed at PHY interface"
          severity note;
    end check_frame;

  begin

    for i in frame_data'low to frame_data'high loop
      if not frame_data(i).underrun then
        check_frame(frame_data(i));
      end if;
    end loop;  -- i

    tx_monitor_finished <= true;
    wait;
  end process p_tx_monitor;


  -----------------------------------------------------------------------------
  -- Receive Stimulus process. This process pushes frames of data through the
  --  receiver side of the core
  -----------------------------------------------------------------------------
  p_rx_stimulus : process
    variable cached_column_valid : boolean := false;
    variable cached_column_data : std_logic_vector(31 downto 0);
    variable cached_column_ctrl : std_logic_vector(3 downto 0);

    procedure send_column (
      constant d : in std_logic_vector(31 downto 0);
      constant c : in std_logic_vector(3 downto 0)) is
    begin  -- send_column
      if cached_column_valid then
        wait until xgmii_rx_clk = '1';
        xgmii_rxd(31 downto 0) <= cached_column_data;
        xgmii_rxc(3 downto 0) <= cached_column_ctrl;
        xgmii_rxd(63 downto 32) <= d;
        xgmii_rxc(7 downto 4) <= c;
        cached_column_valid := false;
      else
        cached_column_data := d;
        cached_column_ctrl := c;
        cached_column_valid := true;
      end if;
    end send_column;

    procedure send_column (
      constant c : in column_typ) is
    begin  -- send_column
      send_column(to_stdlogicvector(c.d),
                  not to_stdlogicvector(c.c));  -- invert "data_valid" sense
    end send_column;

    procedure send_idle is
    begin  -- send_idle
      send_column(X"07070707", "1111");
    end send_idle;

    procedure send_frame (
      constant frame : in frame_typ) is
      constant MIN_FRAME_DATA_BYTES : integer := 60;
      variable column_index, lane_index, byte_count : integer;
      variable scratch_column : column_typ;
    begin  -- send_frame
      column_index := 0;
      lane_index := 0;
      byte_count := 0;
      -- send first lane of preamble
      send_column(X"555555FB", "0001");
      -- send second lane of preamble
      send_column(X"D5555555", "0000");
      while frame.columns(column_index).c = "1111" loop
        send_column(frame.columns(column_index));
        column_index := column_index + 1;
        byte_count := byte_count + 4;
      end loop;
      while frame.columns(column_index).c(lane_index) = '1' loop
        scratch_column.d(lane_index*8+7 downto lane_index*8)
          := frame.columns(column_index).d(lane_index*8+7 downto lane_index*8);
        scratch_column.c(lane_index) := '1';
        lane_index := lane_index + 1;
        byte_count := byte_count + 1;
      end loop;
      while byte_count < MIN_FRAME_DATA_BYTES loop
        if lane_index = 4 then
          send_column(scratch_column);
          lane_index := 0;
        end if;
        scratch_column.d(lane_index*8+7 downto lane_index*8) := (others => '0');
        scratch_column.c(lane_index) := '1';
        lane_index := lane_index + 1;
        byte_count := byte_count + 1;
      end loop;
      -- send the crc
      for i in 3 downto 0 loop
        if lane_index = 4 then
          send_column(scratch_column);
          lane_index := 0;
        end if;
        scratch_column.d(lane_index*8+7 downto lane_index*8)
          := frame.crc(i*8+7 downto i*8);
        scratch_column.c(lane_index) := '1';
        lane_index := lane_index + 1;
      end loop;  -- i
      -- send the terminate/error column
      if lane_index = 4 then
        send_column(scratch_column);
        lane_index := 0;
      end if;
      if frame.underrun then
        -- send error code
        scratch_column.d(lane_index*8+7 downto lane_index*8) := X"FE";
        scratch_column.c(lane_index) := '0';
      else
        -- send terminate code
        scratch_column.d(lane_index*8+7 downto lane_index*8) := X"FD";
        scratch_column.c(lane_index) := '0';
      end if;
      lane_index := lane_index + 1;
      while lane_index < 4 loop
        scratch_column.d(lane_index*8+7 downto lane_index*8) := X"07";
        scratch_column.c(lane_index) := '0';
        lane_index := lane_index + 1;
      end loop;
      send_column(scratch_column);
      assert false
        report "Receiver: frame inserted into PHY interface"
        severity note;
    end send_frame;

  begin
     assert false
      report "Timing checks are not valid"
      severity note;
    while reset = '1' loop
      send_idle;
    end loop;
    -- wait for DCMs to lock
    for i in 1 to 175 loop
      send_idle;
    end loop;
    assert false
      report "Timing checks are valid"
      severity note;

    for i in frame_data'low to frame_data'high loop
      send_frame(frame_data(i));
      send_idle;
      send_idle;
    end loop;  -- i
    while true loop
      send_idle;
    end loop;
  end process p_rx_stimulus;


  p_reset : process
  begin
    -- reset the core
    assert false
      report "Resetting core..."
      severity note;
    reset <= '1';
    wait for 200 ns;
    reset <= '0';
    wait;
  end process p_reset;

  simulation_finished <=
    tx_monitor_finished;

  simulation_errors <=
    tx_monitor_errors;


  p_end_simulation : process
  begin
    wait until simulation_finished for 10 us;
    assert simulation_finished
      report "ERROR: Testbench timed out."
      severity note;
    assert not (simulation_finished and simulation_errors)
      report "Test completed with errors"
      severity note;
    assert not (simulation_finished and not simulation_errors)
      report "Test completed successfully."
      severity note;

    report "Simulation stopped."
      severity failure;
  end process p_end_simulation;




  address_swap_i : eth10g_mac_core_address_swap
    port map (
      rx_clk            =>  axis_clk_out,--gtx_clk,
      reset             =>  reset,
      rx_axis_tdata     =>  rx_axis_tdata_int,
      rx_axis_tkeep     =>  rx_axis_tkeep_int,
      rx_axis_tvalid    =>  rx_axis_tvalid_int,
      rx_axis_tlast     =>  rx_axis_tlast_int,
      rx_axis_tready    =>  rx_axis_tready_int,
      tx_axis_tdata     =>  tx_axis_tdata_int,
      tx_axis_tkeep     =>  tx_axis_tkeep_int,
      tx_axis_tvalid    =>  tx_axis_tvalid_int,
      tx_axis_tlast     =>  tx_axis_tlast_int,
      tx_axis_tready    =>  tx_axis_ready
   );

end behav;
