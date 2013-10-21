------------------------------------------------------------------------------
-- Title : Demo Testbench
-- Project : 10 Gigabit Ethernet PCS/PMA
------------------------------------------------------------------------------
-- File : eth10g_pma_tb.vhd
------------------------------------------------------------------------------
-- (c) Copyright 2009 - 2012 Xilinx, Inc. All rights reserved.
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
------------------------------------------------------------------------------
-- Description :
-- This test-fixture performs the following operations on the 10GBASE-R core:
-- Data frames of varying length are pushed into the transmit xgmii interface
-- and arte captured and checked on the serial side of the core.
-- Similarly, data frames are encoded into a serial stream which is applied to
-- the serial RX ports and are captured and checked at the xgmii rx interface.
------------------------------------------------------------------------------


entity eth10g_pma_tb is
generic (
EXAMPLE_SIM_GTRESET_SPEEDUP : string := "TRUE"
);
end eth10g_pma_tb;

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.numeric_std.all;

library unisim;
use unisim.vcomponents.all;

architecture behav of eth10g_pma_tb is

-------------------------------------------------------------------------------
-- component declaration of design under test.
-------------------------------------------------------------------------------

  -- Period in ps - in reality this should be 66*96.9696969....
  constant BITPERIOD : time := 98 ps;
  constant PERIOD156 : time := 66*98 ps;  -- this is the 161MHz clock

  -- Lock FSM states
  constant LOCK_INIT : integer := 0;
  constant RESET_CNT : integer := 1;
  constant TEST_SH_ST: integer := 2;

  component eth10g_pma
    generic (
      EXAMPLE_SIM_GTRESET_SPEEDUP : string    := "FALSE"
      );
    port (
--      mmcm_locked      : out std_logic;
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
--      pma_loopback     : in std_logic;
--      pma_reset        : in std_logic;
--      global_tx_disable: in std_logic;
--      pma_vs_loopback  : in std_logic_vector(3 downto 0);
--      pcs_loopback     : in std_logic;
--      pcs_reset        : in std_logic;
--      test_patt_a      : in std_logic_vector(57 downto 0);
--      test_patt_b      : in std_logic_vector(57 downto 0);
--      data_patt_sel    : in std_logic;
--      test_patt_sel    : in std_logic;
--      rx_test_patt_en  : in std_logic;
--      tx_test_patt_en  : in std_logic;
--      prbs31_tx_en     : in std_logic;
--      prbs31_rx_en     : in std_logic;
--      pcs_vs_loopback  : in std_logic_vector(1 downto 0);
--      set_pma_link_status      : in std_logic;
--      set_pcs_link_status      : in std_logic;
--      clear_pcs_status2        : in std_logic;
--      clear_test_patt_err_count: in std_logic;

--      pma_link_status         : out std_logic;
--      rx_sig_det              : out std_logic;
--      pcs_rx_link_status      : out std_logic;
--      pcs_rx_locked           : out std_logic;
--      pcs_hiber               : out std_logic;
--      teng_pcs_rx_link_status : out std_logic;
--      pcs_err_block_count     : out std_logic_vector(7 downto 0);
--      pcs_ber_count           : out std_logic_vector(5 downto 0);
--      pcs_rx_hiber_lh         : out std_logic;
--      pcs_rx_locked_ll        : out std_logic;
--      pcs_test_patt_err_count : out std_logic_vector(15 downto 0);
      core_status      : out std_logic_vector(7 downto 0);
      resetdone        : out std_logic;
      signal_detect    : in  std_logic;
      tx_fault         : in  std_logic;
      tx_disable       : out std_logic);
  end component;

  signal reset : std_logic;
  signal core_clk156_out : std_logic;

  signal xgmii_txd : std_logic_vector(63 downto 0);
  signal xgmii_txc : std_logic_vector(7 downto 0);
  signal xgmii_rxd : std_logic_vector(63 downto 0);
  signal xgmii_rxc : std_logic_vector(7 downto 0);
  signal xgmii_rx_clk : std_logic;

  signal refclk_p : std_logic;
  signal refclk_n : std_logic;
  signal bitclk : std_logic;

  signal txp : std_logic;
  signal txn : std_logic;
  signal rxp : std_logic;
  signal rxn : std_logic;


  signal core_status : std_logic_vector(7 downto 0);
  signal resetdone : std_logic;
  signal rxcodeerr_stable : std_logic;
  signal signal_detect : std_logic;
  signal tx_fault : std_logic;
  signal tx_disable : std_logic;

  signal block_lock : std_logic;
  signal test_sh : std_logic := '0';
  signal slip : std_logic := '0';
  signal BLSTATE : integer := 0;
  signal next_blstate : integer := 0;
  signal RxD : std_logic_vector(65 downto 0);
  signal RxD_aligned : std_logic_vector(65 downto 0);
  signal nbits : integer := 0;
  signal sh_cnt : integer := 0;
  signal sh_invalid_cnt : integer := 0;

  signal xgmii_rxd_int : std_logic_vector(63 downto 0);
  signal xgmii_rxc_int : std_logic_vector(7 downto 0);

  signal simulation_finished : boolean := false;
  signal sampleclk : std_logic;

  type column_typ is record
                       d : bit_vector(31 downto 0);
                       c : bit_vector(3 downto 0);
                     end record;

  type column_array_typ is array (natural range <>) of column_typ;

  type frame_typ is record
                      stim : column_array_typ(0 to 31);
                      length : integer;
                    end record;

  type frame_typ_array is array (natural range 0 to 3) of frame_typ;

  signal DeScrambler_Register : std_logic_vector(57 downto 0);
  signal RXD_input : std_logic_vector(63 downto 0);
  signal RX_Sync_header : std_logic_vector(1 downto 0);
  signal DeScr_wire : std_logic_vector(63 downto 0);
  signal DeScr_RXD : std_logic_vector(65 downto 0);

  signal TxEnc : std_logic_vector(65 downto 0) := (others => '0');
  signal d0 : std_logic_vector(31 downto 0) := (others => '0');
  signal c0 : std_logic_vector(3 downto 0) := (others => '0');
  signal d : std_logic_vector(63 downto 0) := (others => '0');
  signal c : std_logic_vector(7 downto 0) := (others => '0');
  signal decided_clk_edge : std_logic := '0';
  signal clk_edge : std_logic;

  signal TxEnc_Data : std_logic_vector(65 downto 0) := (others => '0');
  signal TxEnc_clock : std_logic;
  signal rxbitsready : std_logic := '0';
  signal TXD_Scr : std_logic_vector(65 downto 0) := (others => '0');

  signal Scrambler_Register : std_logic_vector(57 downto 0) := (others => '0');
  signal TXD_input : std_logic_vector(63 downto 0) := (others => '0');
  signal Sync_header : std_logic_vector(1 downto 0) := (others => '0');
  signal Scr_wire : std_logic_vector(63 downto 0) := (others => '0');

  -- To aid tx frame checking
  signal in_a_frame : std_logic := '0';

-------------------------------------------------------------------------------
-- define the stimulus the testbench will utilise.
-------------------------------------------------------------------------------

  constant frame_data : frame_typ_array := (
    0      => ( -- frame 0
      stim => (
        0  => ( d => X"040302FB", c => X"1" ),
        1  => ( d => X"02020605", c => X"0" ),
        2  => ( d => X"06050403", c => X"0" ),
        3  => ( d => X"55AA2E00", c => X"0" ),
        4  => ( d => X"AA55AA55", c => X"0" ),
        5  => ( d => X"55AA55AA", c => X"0" ),
        6  => ( d => X"AA55AA55", c => X"0" ),
        7  => ( d => X"55AA55AA", c => X"0" ),
        8  => ( d => X"AA55AA55", c => X"0" ),
        9  => ( d => X"55AA55AA", c => X"0" ),
        10 => ( d => X"AA55AA55", c => X"0" ),
        11 => ( d => X"55AA55AA", c => X"0" ),
        12 => ( d => X"AA55AA55", c => X"0" ),
        13 => ( d => X"55AA55AA", c => X"0" ),
        14 => ( d => X"FD55AA55", c => X"8" ),
        15 => ( d => X"07070707", c => X"F" ),
        16 => ( d => X"07070707", c => X"F" ),
        17 => ( d => X"07070707", c => X"F" ),
        18 => ( d => X"07070707", c => X"F" ),
        19 => ( d => X"07070707", c => X"F" ),
        20 => ( d => X"07070707", c => X"F" ),
        21 => ( d => X"07070707", c => X"F" ),
        22 => ( d => X"07070707", c => X"F" ),
        23 => ( d => X"07070707", c => X"F" ),
        24 => ( d => X"07070707", c => X"F" ),
        25 => ( d => X"07070707", c => X"F" ),
        26 => ( d => X"07070707", c => X"F" ),
        27 => ( d => X"07070707", c => X"F" ),
        28 => ( d => X"07070707", c => X"F" ),
        29 => ( d => X"07070707", c => X"F" ),
        30 => ( d => X"07070707", c => X"F" ),
        31 => ( d => X"07070707", c => X"F" )),
    length => 15),
    1      => ( -- frame 1
      stim => (
        0  => ( d => X"030405FB", c => X"1" ),
        1  => ( d => X"05060102", c => X"0" ),
        2  => ( d => X"02020304", c => X"0" ),
        3  => ( d => X"EE110080", c => X"0" ),
        4  => ( d => X"11EE11EE", c => X"0" ),
        5  => ( d => X"EE11EE11", c => X"0" ),
        6  => ( d => X"11EE11EE", c => X"0" ),
        7  => ( d => X"EE11EE11", c => X"0" ),
        8  => ( d => X"11EE11EE", c => X"0" ),
        9  => ( d => X"EE11EE11", c => X"0" ),
        10 => ( d => X"11EE11EE", c => X"0" ),
        11 => ( d => X"EE11EE11", c => X"0" ),
        12 => ( d => X"11EE11EE", c => X"0" ),
        13 => ( d => X"EE11EE11", c => X"0" ),
        14 => ( d => X"11EE11EE", c => X"0" ),
        15 => ( d => X"EE11EE11", c => X"0" ),
        16 => ( d => X"11EE11EE", c => X"0" ),
        17 => ( d => X"EE11EE11", c => X"0" ),
        18 => ( d => X"11EE11EE", c => X"0" ),
        19 => ( d => X"EE11EE11", c => X"0" ),
        20 => ( d => X"11EE11EE", c => X"0" ),
        21 => ( d => X"07FDEE11", c => X"C" ),
        22 => ( d => X"07070707", c => X"F" ),
        23 => ( d => X"07070707", c => X"F" ),
        24 => ( d => X"07070707", c => X"F" ),
        25 => ( d => X"07070707", c => X"F" ),
        26 => ( d => X"07070707", c => X"F" ),
        27 => ( d => X"07070707", c => X"F" ),
        28 => ( d => X"07070707", c => X"F" ),
        29 => ( d => X"07070707", c => X"F" ),
        30 => ( d => X"07070707", c => X"F" ),
        31 => ( d => X"07070707", c => X"F" )),
    length => 22),
    2      => ( -- frame 2
      stim => (
        0  => ( d => X"040302FB", c => X"1" ),
        1  => ( d => X"02020605", c => X"0" ),
        2  => ( d => X"06050403", c => X"0" ),
        3  => ( d => X"55AA2E80", c => X"0" ),
        4  => ( d => X"AA55AA55", c => X"0" ),
        5  => ( d => X"55AA55AA", c => X"0" ),
        6  => ( d => X"AA55AA55", c => X"0" ),
        7  => ( d => X"55AA55AA", c => X"0" ),
        8  => ( d => X"AA55AA55", c => X"0" ),
        9  => ( d => X"55AA55AA", c => X"0" ),
        10 => ( d => X"AA55AA55", c => X"0" ),
        11 => ( d => X"55AA55AA", c => X"0" ),
        12 => ( d => X"AA55AA55", c => X"0" ),
        13 => ( d => X"55AA55AA", c => X"0" ),
        14 => ( d => X"AA55AA55", c => X"0" ),
        15 => ( d => X"55AA55AA", c => X"0" ),
        16 => ( d => X"AA55AA55", c => X"0" ),
        17 => ( d => X"55AA55AA", c => X"0" ),
        18 => ( d => X"AA55AA55", c => X"0" ),
        19 => ( d => X"55AA55AA", c => X"0" ),
        20 => ( d => X"0707FDAA", c => X"E" ),
        21 => ( d => X"07070707", c => X"F" ),
        22 => ( d => X"07070707", c => X"F" ),
        23 => ( d => X"07070707", c => X"F" ),
        24 => ( d => X"07070707", c => X"F" ),
        25 => ( d => X"07070707", c => X"F" ),
        26 => ( d => X"07070707", c => X"F" ),
        27 => ( d => X"07070707", c => X"F" ),
        28 => ( d => X"07070707", c => X"F" ),
        29 => ( d => X"07070707", c => X"F" ),
        30 => ( d => X"07070707", c => X"F" ),
        31 => ( d => X"07070707", c => X"F" )),
    length => 21),
    3      => ( -- frame 3
      stim => (
        0  => ( d => X"030405FB", c => X"1" ),
        1  => ( d => X"05060102", c => X"0" ),
        2  => ( d => X"02020304", c => X"0" ),
        3  => ( d => X"EE110080", c => X"0" ),
        4  => ( d => X"11EE11EE", c => X"0" ),
        5  => ( d => X"EE11EE11", c => X"0" ),
        6  => ( d => X"11EE11EE", c => X"0" ),
        7  => ( d => X"EE11EE11", c => X"0" ),
        8  => ( d => X"11EE11EE", c => X"0" ),
        9  => ( d => X"070707FD", c => X"F" ),
        10 => ( d => X"07070707", c => X"F" ),
        11 => ( d => X"07070707", c => X"F" ),
        12 => ( d => X"07070707", c => X"F" ),
        13 => ( d => X"07070707", c => X"F" ),
        14 => ( d => X"07070707", c => X"F" ),
        15 => ( d => X"07070707", c => X"F" ),
        16 => ( d => X"07070707", c => X"F" ),
        17 => ( d => X"07070707", c => X"F" ),
        18 => ( d => X"07070707", c => X"F" ),
        19 => ( d => X"07070707", c => X"F" ),
        20 => ( d => X"07070707", c => X"F" ),
        21 => ( d => X"07070707", c => X"F" ),
        22 => ( d => X"07070707", c => X"F" ),
        23 => ( d => X"07070707", c => X"F" ),
        24 => ( d => X"07070707", c => X"F" ),
        25 => ( d => X"07070707", c => X"F" ),
        26 => ( d => X"07070707", c => X"F" ),
        27 => ( d => X"07070707", c => X"F" ),
        28 => ( d => X"07070707", c => X"F" ),
        29 => ( d => X"07070707", c => X"F" ),
        30 => ( d => X"07070707", c => X"F" ),
        31 => ( d => X"07070707", c => X"F" )),
    length => 10));

  signal read_back : frame_typ_array := (
    0         => (                       -- frame 0
      stim   => (others => ( d => (others => '0'), c => X"0")),
      length => 0),
    1         => (                       -- frame 1
      stim   => (others => ( d => (others => '0'), c => X"0")),
      length => 0),
    2         => (                       -- frame 2
      stim   => (others => ( d => (others => '0'), c => X"0")),
      length => 0),
    3         => (                       -- frame 3
      stim   => (others => ( d => (others => '0'), c => X"0")),
      length => 0));

-------------------------------------------------------------------------------
-- connect the design under test to the signals in the testbench.
-------------------------------------------------------------------------------

begin  -- behav


  signal_detect <= '1';
  tx_fault <= '0';


  dut : eth10g_pma
    generic map(
      EXAMPLE_SIM_GTRESET_SPEEDUP => EXAMPLE_SIM_GTRESET_SPEEDUP
      )
    port map (
--      mmcm_locked => open,
      reset           => reset,
      core_clk156_out => core_clk156_out,
      xgmii_txd       => xgmii_txd,
      xgmii_txc       => xgmii_txc,
      xgmii_rx_clk    => xgmii_rx_clk,
      xgmii_rxd       => xgmii_rxd,
      xgmii_rxc       => xgmii_rxc,
      refclk_p        => refclk_p,
      refclk_n        => refclk_n,
-------------------------------------------------------------------------------
-- Serial Interface
-------------------------------------------------------------------------------
      txp             => txp,
      txn             => txn,
      rxp             => rxp,
      rxn             => rxn,
      resetdone       => resetdone,
      signal_detect   => signal_detect,
      tx_fault        => tx_fault,
      tx_disable      => tx_disable,
      core_status     => core_status
--      pma_loopback              => '0',
--      pma_reset                 => '0',
--      global_tx_disable         => '0',
--      pma_vs_loopback           => "0000",
--      pcs_loopback              => '0',
--      pcs_reset                 => '0',
--      test_patt_a               => (others => '0'),
--      test_patt_b               => (others => '0'),
--      data_patt_sel             => '0',
--      test_patt_sel             => '0',
--      rx_test_patt_en           => '0',
--      tx_test_patt_en           => '0',
--      prbs31_tx_en              => '0',
--      prbs31_rx_en              => '0',
--      pcs_vs_loopback           => "00",
--      set_pma_link_status       => '0',
--      set_pcs_link_status       => '0',
--      clear_pcs_status2         => '0',
--      clear_test_patt_err_count => '0',
--      pma_link_status           => open,
--      rx_sig_det                => open,
--      pcs_rx_link_status        => open,
--      pcs_rx_locked             => open,
--      pcs_hiber                 => open,
--      teng_pcs_rx_link_status   => open,
--      pcs_err_block_count       => open,
--      pcs_ber_count             => open,
--      pcs_rx_hiber_lh           => open,
--      pcs_rx_locked_ll          => open,
--      pcs_test_patt_err_count   => open
    );

-------------------------------------------------------------------------------
-- Clock Drivers
-------------------------------------------------------------------------------

  -- Generate the refclk
  gen_refclk : process
  begin
    refclk_p <= '0';
    refclk_n <= '1';
    wait for PERIOD156/2;
    refclk_p <= '1';
    refclk_n <= '0';
    wait for PERIOD156/2;
  end process gen_refclk;

  -- Generate the sampleclk
  gen_sampleclk : process
  begin
    sampleclk <= '0';
    wait for PERIOD156/2;
    sampleclk <= '1';
    wait for PERIOD156/2;
  end process gen_sampleclk;

  -- Generate the bitclk
  gen_bitclk : process
    variable first : integer := 1;
  begin
    bitclk <= '0';
    if(first = 1) then
      wait for BITPERIOD/4;
      first := 0;
    end if;
    wait for BITPERIOD/2;
    bitclk <= '1';
    wait for BITPERIOD/2;
  end process gen_bitclk;


--  -- Generate the resets.
--  ------------------------------------------------------------------
--  -- Global Set/Reset
--  ------------------------------------------------------------------
--  p_gsr : process
--  begin
--    gsr <= '1';
--    wait for 500 ns;
--    gsr <= '0';
--    wait;
--  end process p_gsr;
--
--  rocbuf_i : ROCBUF
--    port map (
--      I => gsr,
--      O => open);
--
--
--  reset_proc : process
--  begin
--    report "Resetting the core..." severity note;
--    reset <= '0';
--    -- Wait for gsr to finish
--    wait until gsr = '1';
--    reset <= '1';
--    wait until gsr = '0';
--    reset <= '0';
--    wait until sampleclk = '0';



  reset_proc : process
  begin
    report "Resetting the core..." severity note;
    reset <= '0';
    -- Wait for gsr to finish
    wait for 2 us;
    reset <= '1';
    wait for 2 us;
    reset <= '0';
    wait until sampleclk = '0';

    -- Wait for GT init to finish
    wait until resetdone = '1';
    report ( "GT initialization operation done") severity note;
    resetloop : for i in 0 to 499 loop
      wait until sampleclk = '0';
    end loop;
    wait;
  end process reset_proc;



  -- Start Timebomb
  p_end_simulation : process
  begin
    wait until simulation_finished for 150 us;
    assert simulation_finished
      report "Error: Testbench timed out"
      severity failure;
    assert false
      report "Test completed successfully"
      severity failure;
  end process p_end_simulation;

  ------------------------------------------------------------------
  -- Transmit Stimulus code...
  ------------------------------------------------------------------
  tx_stimulus_proc : process

    -- Support code for transmitting frames through xgmii
      variable cached_column_valid : boolean := false;
      variable cached_column_data : std_logic_vector(31 downto 0);
      variable cached_column_ctrl : std_logic_vector(3 downto 0);

    procedure tx_stimulus_send_column (
         constant d : in std_logic_vector(31 downto 0);
         constant c : in std_logic_vector(3 downto 0)) is
      begin  -- send_column
         if cached_column_valid then
            wait until sampleclk = '1';
            wait for 3200 ps;
            xgmii_txd(31 downto 0) <= cached_column_data;
            xgmii_txc(3 downto 0) <= cached_column_ctrl;
            xgmii_txd(63 downto 32) <= d;
            xgmii_txc(7 downto 4) <= c;
            cached_column_valid := false;
         else
            cached_column_data := d;
            cached_column_ctrl := c;
            cached_column_valid := true;
         end if;
    end tx_stimulus_send_column;

    procedure tx_stimulus_send_idle is
    begin
      tx_stimulus_send_column(x"07070707", x"F");
    end tx_stimulus_send_idle;

    procedure send_column (
      constant c : in column_typ) is
    begin -- send_column
      tx_stimulus_send_column(to_stdlogicvector(c.d), to_stdlogicvector(c.c));
    end send_column;

    procedure tx_stimulus_send_frame (
      constant frame : in frame_typ) is
        variable column_index : integer := 0;
    begin
      while(column_index < frame.length) loop
        send_column(frame.stim(column_index));
        column_index := column_index + 1;
      end loop;
      report "Transmitter: frame inserted into XGMII interface";
    end tx_stimulus_send_frame;

  begin -- tx_stimulus

    -- wait until the core is ready after reset - this will be indicated
    -- by a rising edge on the resetdone signal.
    while (resetdone /= '1') loop
      tx_stimulus_send_idle;
    end loop;
    -- now wait until the testbench has block_lock on the transmitted idles
    while (block_lock /= '1') loop
      tx_stimulus_send_idle;
    end loop;

    tx_stimulus_send_frame(frame_data(0));
    tx_stimulus_send_idle;
    tx_stimulus_send_idle;
    tx_stimulus_send_frame(frame_data(1));
    tx_stimulus_send_idle;
    tx_stimulus_send_idle;
    tx_stimulus_send_frame(frame_data(2));
    tx_stimulus_send_idle;
    tx_stimulus_send_idle;
    tx_stimulus_send_frame(frame_data(3));
    while(true) loop
      tx_stimulus_send_idle;
    end loop;
    wait;
  end process;

  ------------------------------------------------------------------
  -- Transmit Monitor code.....
  ------------------------------------------------------------------

  -- Fill RxD with 66 bits...
  p_tx_serial_capture : process (bitclk)
  begin
    if(rising_edge(bitclk)) then
      if(slip = '0') then
      -- Just grab next 66 bits
        RxD(64 downto 0) <= RxD(65 downto 1);
        RxD(65) <= txp;
        if(nbits < 65) then
          nbits <= nbits + 1;
          test_sh <= '0';
        else
          nbits <= 0;
          test_sh <= '1';
        end if;
      else -- SLIP!!
      -- Just grab single bit
        RxD(64 downto 0) <= RxD(65 downto 1);
        RxD(65) <= txp;
        test_sh <= '1';
        nbits <= 0;
      end if;
    end if;
  end process p_tx_serial_capture;


  -- Implement the block lock state machine on serial TX...
  p_tx_block_lock : process (BLSTATE, test_sh, RxD)
  begin

    case (BLSTATE) is
      when LOCK_INIT =>
        block_lock <= '0';
        next_blstate <= RESET_CNT;
        slip <= '0';
        sh_cnt <= 0;
        sh_invalid_cnt <= 0;
      when RESET_CNT =>
        slip <= '0';
        if(test_sh = '1') then
          next_blstate <= TEST_SH_ST;
        else
          next_blstate <= RESET_CNT;
        end if;
      when TEST_SH_ST =>
        slip <= '0';
        next_blstate <= TEST_SH_ST;
        if(test_sh = '1' and (RxD(0) /= RxD(1))) then -- Good sync header candidate
          sh_cnt <= sh_cnt + 1; -- Immediate update!
          if(sh_cnt < 64) then
            next_blstate <= TEST_SH_ST;
          elsif(sh_cnt = 64 and sh_invalid_cnt > 0) then
            next_blstate <= RESET_CNT;
            sh_cnt <= 0;
            sh_invalid_cnt <= 0;
          elsif(sh_cnt = 64 and sh_invalid_cnt = 0) then
            block_lock <= '1';
            next_blstate <= RESET_CNT;
            sh_cnt <= 0;
            sh_invalid_cnt <= 0;
          end if;
        elsif(test_sh = '1') then -- Bad sync header
          sh_cnt <= sh_cnt + 1;
          sh_invalid_cnt <= sh_invalid_cnt + 1;
          if(sh_cnt = 64 and sh_invalid_cnt < 16 and block_lock = '1') then
            next_blstate <= RESET_CNT;
            sh_cnt <= 0;
            sh_invalid_cnt <= 0;
          elsif(sh_cnt < 64 and sh_invalid_cnt < 16
                  and test_sh = '1' and block_lock = '1') then
            next_blstate <= TEST_SH_ST;
          elsif(sh_invalid_cnt = 16 and block_lock = '0') then
            block_lock <= '0';
            slip <= '1';
            sh_cnt <= 0;
            sh_invalid_cnt <= 0;
            next_blstate <= RESET_CNT;
          end if;
        end if;
      when others =>
        block_lock <= '0';
        next_blstate <= RESET_CNT;
        slip <= '0';
        sh_cnt <= 0;
        sh_invalid_cnt <= 0;
    end case;
  end process p_tx_block_lock;

  -- Implement the block lock state machine on serial TX
  -- And capture the aligned 66 bit words....
  p_tx_block_lock_next_blstate : process (bitclk)
  begin
    if(rising_edge(bitclk)) then
      if(reset = '1' or resetdone = '0') then
        BLSTATE <= LOCK_INIT;
      else
        BLSTATE <= next_blstate;
      end if;
      if(test_sh = '1' and block_lock = '1') then
        RxD_aligned <= RxD;
      end if;
    end if;
  end process p_tx_block_lock_next_blstate;

  -- Descramble the TX serial data

  DeScr_wire(0) <= RXD_input(0) xor DeScrambler_Register(38) xor DeScrambler_Register(57);
  DeScr_wire(1) <= RXD_input(1) xor DeScrambler_Register(37) xor DeScrambler_Register(56);
  DeScr_wire(2) <= RXD_input(2) xor DeScrambler_Register(36) xor DeScrambler_Register(55);
  DeScr_wire(3) <= RXD_input(3) xor DeScrambler_Register(35) xor DeScrambler_Register(54);
  DeScr_wire(4) <= RXD_input(4) xor DeScrambler_Register(34) xor DeScrambler_Register(53);
  DeScr_wire(5) <= RXD_input(5) xor DeScrambler_Register(33) xor DeScrambler_Register(52);
  DeScr_wire(6) <= RXD_input(6) xor DeScrambler_Register(32) xor DeScrambler_Register(51);
  DeScr_wire(7) <= RXD_input(7) xor DeScrambler_Register(31) xor DeScrambler_Register(50);

  DeScr_wire(8) <= RXD_input(8) xor DeScrambler_Register(30) xor DeScrambler_Register(49);
  DeScr_wire(9) <= RXD_input(9) xor DeScrambler_Register(29) xor DeScrambler_Register(48);
  DeScr_wire(10) <= RXD_input(10) xor DeScrambler_Register(28) xor DeScrambler_Register(47);
  DeScr_wire(11) <= RXD_input(11) xor DeScrambler_Register(27) xor DeScrambler_Register(46);
  DeScr_wire(12) <= RXD_input(12) xor DeScrambler_Register(26) xor DeScrambler_Register(45);
  DeScr_wire(13) <= RXD_input(13) xor DeScrambler_Register(25) xor DeScrambler_Register(44);
  DeScr_wire(14) <= RXD_input(14) xor DeScrambler_Register(24) xor DeScrambler_Register(43);
  DeScr_wire(15) <= RXD_input(15) xor DeScrambler_Register(23) xor DeScrambler_Register(42);

  DeScr_wire(16) <= RXD_input(16) xor DeScrambler_Register(22) xor DeScrambler_Register(41);
  DeScr_wire(17) <= RXD_input(17) xor DeScrambler_Register(21) xor DeScrambler_Register(40);
  DeScr_wire(18) <= RXD_input(18) xor DeScrambler_Register(20) xor DeScrambler_Register(39);
  DeScr_wire(19) <= RXD_input(19) xor DeScrambler_Register(19) xor DeScrambler_Register(38);
  DeScr_wire(20) <= RXD_input(20) xor DeScrambler_Register(18) xor DeScrambler_Register(37);
  DeScr_wire(21) <= RXD_input(21) xor DeScrambler_Register(17) xor DeScrambler_Register(36);
  DeScr_wire(22) <= RXD_input(22) xor DeScrambler_Register(16) xor DeScrambler_Register(35);
  DeScr_wire(23) <= RXD_input(23) xor DeScrambler_Register(15) xor DeScrambler_Register(34);

  DeScr_wire(24) <= RXD_input(24) xor DeScrambler_Register(14) xor DeScrambler_Register(33);
  DeScr_wire(25) <= RXD_input(25) xor DeScrambler_Register(13) xor DeScrambler_Register(32);
  DeScr_wire(26) <= RXD_input(26) xor DeScrambler_Register(12) xor DeScrambler_Register(31);
  DeScr_wire(27) <= RXD_input(27) xor DeScrambler_Register(11) xor DeScrambler_Register(30);
  DeScr_wire(28) <= RXD_input(28) xor DeScrambler_Register(10) xor DeScrambler_Register(29);
  DeScr_wire(29) <= RXD_input(29) xor DeScrambler_Register(9) xor DeScrambler_Register(28);
  DeScr_wire(30) <= RXD_input(30) xor DeScrambler_Register(8) xor DeScrambler_Register(27);
  DeScr_wire(31) <= RXD_input(31) xor DeScrambler_Register(7) xor DeScrambler_Register(26);

  DeScr_wire(32) <= RXD_input(32) xor DeScrambler_Register(6) xor DeScrambler_Register(25);
  DeScr_wire(33) <= RXD_input(33) xor DeScrambler_Register(5) xor DeScrambler_Register(24);
  DeScr_wire(34) <= RXD_input(34) xor DeScrambler_Register(4) xor DeScrambler_Register(23);
  DeScr_wire(35) <= RXD_input(35) xor DeScrambler_Register(3) xor DeScrambler_Register(22);
  DeScr_wire(36) <= RXD_input(36) xor DeScrambler_Register(2) xor DeScrambler_Register(21);
  DeScr_wire(37) <= RXD_input(37) xor DeScrambler_Register(1) xor DeScrambler_Register(20);
  DeScr_wire(38) <= RXD_input(38) xor DeScrambler_Register(0) xor DeScrambler_Register(19);

  DeScr_wire(39) <= RXD_input(39) xor RXD_input(0) xor DeScrambler_Register(18);
  DeScr_wire(40) <= RXD_input(40) xor RXD_input(1) xor DeScrambler_Register(17);
  DeScr_wire(41) <= RXD_input(41) xor RXD_input(2) xor DeScrambler_Register(16);
  DeScr_wire(42) <= RXD_input(42) xor RXD_input(3) xor DeScrambler_Register(15);
  DeScr_wire(43) <= RXD_input(43) xor RXD_input(4) xor DeScrambler_Register(14);
  DeScr_wire(44) <= RXD_input(44) xor RXD_input(5) xor DeScrambler_Register(13);
  DeScr_wire(45) <= RXD_input(45) xor RXD_input(6) xor DeScrambler_Register(12);
  DeScr_wire(46) <= RXD_input(46) xor RXD_input(7) xor DeScrambler_Register(11);
  DeScr_wire(47) <= RXD_input(47) xor RXD_input(8) xor DeScrambler_Register(10);

  DeScr_wire(48) <= RXD_input(48) xor RXD_input(9) xor DeScrambler_Register(9);
  DeScr_wire(49) <= RXD_input(49) xor RXD_input(10) xor DeScrambler_Register(8);
  DeScr_wire(50) <= RXD_input(50) xor RXD_input(11) xor DeScrambler_Register(7);
  DeScr_wire(51) <= RXD_input(51) xor RXD_input(12) xor DeScrambler_Register(6);
  DeScr_wire(52) <= RXD_input(52) xor RXD_input(13) xor DeScrambler_Register(5);
  DeScr_wire(53) <= RXD_input(53) xor RXD_input(14) xor DeScrambler_Register(4);
  DeScr_wire(54) <= RXD_input(54) xor RXD_input(15) xor DeScrambler_Register(3);

  DeScr_wire(55) <= RXD_input(55) xor RXD_input(16) xor DeScrambler_Register(2);
  DeScr_wire(56) <= RXD_input(56) xor RXD_input(17) xor DeScrambler_Register(1);
  DeScr_wire(57) <= RXD_input(57) xor RXD_input(18) xor DeScrambler_Register(0);
  DeScr_wire(58) <= RXD_input(58) xor RXD_input(19) xor RXD_input(0);
  DeScr_wire(59) <= RXD_input(59) xor RXD_input(20) xor RXD_input(1);
  DeScr_wire(60) <= RXD_input(60) xor RXD_input(21) xor RXD_input(2);
  DeScr_wire(61) <= RXD_input(61) xor RXD_input(22) xor RXD_input(3);
  DeScr_wire(62) <= RXD_input(62) xor RXD_input(23) xor RXD_input(4);
  DeScr_wire(63) <= RXD_input(63) xor RXD_input(24) xor RXD_input(5);

  -- Synchronous part of descrambler
  p_descramble : process (core_clk156_out)
  begin
    if(rising_edge(core_clk156_out)) then
      if (reset = '1' or resetdone = '0' or block_lock = '0') then
      -- default is all IDLEs (code x1E)
        DeScrambler_Register(57 downto 0) <= "00" & x"00000000000003";
        RXD_input(63 downto 0) <= x"0000000000000000";
        RX_Sync_header <= "01";
        DeScr_RXD(65 downto 0) <="00" & x"0000000000000079";
      else
        RXD_input(63 downto 0) <= RxD_aligned(65 downto 2);
        RX_Sync_header <= RxD_aligned(1 downto 0);
        DeScr_RXD(65 downto 0) <= DeScr_wire(63 downto 0) & RX_Sync_header(1 downto 0);

        DeScrambler_Register(57) <= RXD_input(6);
        DeScrambler_Register(56) <= RXD_input(7);
        DeScrambler_Register(55) <= RXD_input(8);
        DeScrambler_Register(54) <= RXD_input(9);
        DeScrambler_Register(53) <= RXD_input(10);
        DeScrambler_Register(52) <= RXD_input(11);
        DeScrambler_Register(51) <= RXD_input(12);
        DeScrambler_Register(50) <= RXD_input(13);

        DeScrambler_Register(49) <= RXD_input(14);
        DeScrambler_Register(48) <= RXD_input(15);
        DeScrambler_Register(47) <= RXD_input(16);
        DeScrambler_Register(46) <= RXD_input(17);
        DeScrambler_Register(45) <= RXD_input(18);
        DeScrambler_Register(44) <= RXD_input(19);
        DeScrambler_Register(43) <= RXD_input(20);
        DeScrambler_Register(42) <= RXD_input(21);

        DeScrambler_Register(41) <= RXD_input(22);
        DeScrambler_Register(40) <= RXD_input(23);
        DeScrambler_Register(39) <= RXD_input(24);
        DeScrambler_Register(38) <= RXD_input(25);
        DeScrambler_Register(37) <= RXD_input(26);
        DeScrambler_Register(36) <= RXD_input(27);
        DeScrambler_Register(35) <= RXD_input(28);
        DeScrambler_Register(34) <= RXD_input(29);

        DeScrambler_Register(33) <= RXD_input(30);
        DeScrambler_Register(32) <= RXD_input(31);
        DeScrambler_Register(31) <= RXD_input(32);
        DeScrambler_Register(30) <= RXD_input(33);
        DeScrambler_Register(29) <= RXD_input(34);
        DeScrambler_Register(28) <= RXD_input(35);
        DeScrambler_Register(27) <= RXD_input(36);
        DeScrambler_Register(26) <= RXD_input(37);

        DeScrambler_Register(25) <= RXD_input(38);
        DeScrambler_Register(24) <= RXD_input(39);
        DeScrambler_Register(23) <= RXD_input(40);
        DeScrambler_Register(22) <= RXD_input(41);
        DeScrambler_Register(21) <= RXD_input(42);
        DeScrambler_Register(20) <= RXD_input(43);
        DeScrambler_Register(19) <= RXD_input(44);
        DeScrambler_Register(18) <= RXD_input(45);

        DeScrambler_Register(17) <= RXD_input(46);
        DeScrambler_Register(16) <= RXD_input(47);
        DeScrambler_Register(15) <= RXD_input(48);
        DeScrambler_Register(14) <= RXD_input(49);
        DeScrambler_Register(13) <= RXD_input(50);
        DeScrambler_Register(12) <= RXD_input(51);
        DeScrambler_Register(11) <= RXD_input(52);
        DeScrambler_Register(10) <= RXD_input(53);

        DeScrambler_Register(9) <= RXD_input(54);
        DeScrambler_Register(8) <= RXD_input(55);
        DeScrambler_Register(7) <= RXD_input(56);
        DeScrambler_Register(6) <= RXD_input(57);
        DeScrambler_Register(5) <= RXD_input(58);
        DeScrambler_Register(4) <= RXD_input(59);
        DeScrambler_Register(3) <= RXD_input(60);
        DeScrambler_Register(2) <= RXD_input(61);
        DeScrambler_Register(1) <= RXD_input(62);
        DeScrambler_Register(0) <= RXD_input(63);
      end if;
    end if;
  end process p_descramble;

  -- Decode and check the Descrambled TX data...
  -- This is not a complete decoder: It only decodes the
  -- block words we expect to see.
  p_check_tx : process (core_clk156_out)
    variable frame_no : integer := 0;
    variable word_no : integer := 0;
  begin
    if(rising_edge(core_clk156_out)) then
      if(reset = '1' or resetdone = '0' or block_lock = '0') then
        frame_no := 0;
        word_no := 0;
      -- Wait for a Start code...
      elsif(DeScr_RXD(1 downto 0) = "01" and
              DeScr_RXD(9 downto 2) = x"33") then
        in_a_frame <= '1';
      -- Start code in byte 4, data in bytes 5, 6, 7
        if((DeScr_RXD(65 downto 42) & x"FB" /=
            to_stdlogicvector(frame_data(frame_no).stim(word_no).d)) or
          (frame_data(frame_no).stim(word_no).c /= x"1")) then
          assert false
            report "Tx data check ERROR!!, frame " &
                    integer'image(frame_no) &
                    ", word " &
                    integer'image(word_no) &
                    ", StimData = " &
                    integer'image(conv_integer(ieee.std_logic_arith.unsigned(to_stdlogicvector(frame_data(frame_no).stim(word_no).d)))) &
                    "MonData = " &
                    integer'image(conv_integer(ieee.std_logic_arith.unsigned(DeScr_RXD(65 downto 42) & x"00")))
            severity error;
        else
          assert false
            report "Tx data check OK!!, frame " &
                   integer'image(frame_no) &
                   ", word " &
                   integer'image(word_no)
            severity note;
        end if;
        word_no := word_no + 1;
      elsif(DeScr_RXD(1 downto 0) = "01" and
              DeScr_RXD(9 downto 2) = x"78") then
        in_a_frame <= '1';
      -- Start code in byte 0, data on bytes 1..7
        if((DeScr_RXD(33 downto 10) & x"FB" /=
            to_stdlogicvector(frame_data(frame_no).stim(word_no).d)) or
           (frame_data(frame_no).stim(word_no).c /= x"1")) then
          assert false
            report "Tx data check ERROR!!, frame " &
                    integer'image(frame_no) &
                    ", word " &
                    integer'image(word_no) &
                    ", StimData = " &
                    integer'image(conv_integer(ieee.std_logic_arith.unsigned(to_stdlogicvector(frame_data(frame_no).stim(word_no).d)))) &
                    "MonData = " &
                    integer'image(conv_integer(ieee.std_logic_arith.unsigned(DeScr_RXD(33 downto 10) & x"00")))
            severity error;
        else
          assert false
            report "Tx data check OK!!, frame " &
                   integer'image(frame_no) &
                   ", word " &
                   integer'image(word_no)
            severity note;
        end if;
        if((DeScr_RXD(65 downto 34) /=
            to_stdlogicvector(frame_data(frame_no).stim(word_no+1).d)) or
           (frame_data(frame_no).stim(word_no+1).c /= x"0")) then
          assert false
            report "Tx data check ERROR!!, frame " &
                    integer'image(frame_no) &
                    ", word " &
                    integer'image(word_no+1) &
                    ", StimData = " &
                    integer'image(conv_integer(ieee.std_logic_arith.unsigned(to_stdlogicvector(frame_data(frame_no).stim(word_no+1).d)))) &
                    "MonData = " &
                    integer'image(conv_integer(ieee.std_logic_arith.unsigned(DeScr_RXD(65 downto 34))))
            severity error;
        else
          assert false
            report "Tx data check OK!!, frame " &
                   integer'image(frame_no) &
                   ", word " &
                   integer'image(word_no+1)
            severity note;
        end if;
        word_no := word_no + 2;
      elsif(in_a_frame = '1' and (DeScr_RXD(1 downto 0) = "01" and
              DeScr_RXD(9 downto 2) = x"FF")) then
        in_a_frame <= '0';
      -- T code in 7th byte, data in bytes 1..7
        if((DeScr_RXD(41 downto 10) /=
            to_stdlogicvector(frame_data(frame_no).stim(word_no).d)) or
           (frame_data(frame_no).stim(word_no).c /= x"0")) then
          assert false
            report "Tx data check ERROR!!, frame " &
                    integer'image(frame_no) &
                    ", word " &
                    integer'image(word_no) &
                    ", StimData = " &
                    integer'image(conv_integer(ieee.std_logic_arith.unsigned(to_stdlogicvector(frame_data(frame_no).stim(word_no).d)))) &
                    "MonData = " &
                    integer'image(conv_integer(ieee.std_logic_arith.unsigned(DeScr_RXD(41 downto 10))))
            severity error;
        else
          assert false
            report "Tx data check OK!!, frame " &
                   integer'image(frame_no) &
                   ", word " &
                   integer'image(word_no)
            severity note;
        end if;
        if((x"FD" & DeScr_RXD(65 downto 42) /=
            to_stdlogicvector(frame_data(frame_no).stim(word_no+1).d)) or
           (frame_data(frame_no).stim(word_no+1).c /= x"8")) then
          assert false
            report "Tx data check ERROR!!, frame " &
                    integer'image(frame_no) &
                    ", word " &
                    integer'image(word_no+1) &
                    ", StimData = " &
                    integer'image(conv_integer(ieee.std_logic_arith.unsigned(to_stdlogicvector(frame_data(frame_no).stim(word_no+1).d)))) &
                    "MonData = " &
                    integer'image(conv_integer(ieee.std_logic_arith.unsigned(x"00" & DeScr_RXD(65 downto 42))))
            severity error;
        else
          assert false
            report "Tx data check OK!!, frame " &
                   integer'image(frame_no) &
                   ", word " &
                   integer'image(word_no+1)
            severity note;
        end if;
        word_no := 0;
        frame_no := frame_no + 1;
      elsif(in_a_frame = '1' and (DeScr_RXD(1 downto 0) = "01" and
              DeScr_RXD(9 downto 2) = x"E1")) then
        in_a_frame <= '0';
      -- T code in 6th byte, data in bytes 1..6
        if((DeScr_RXD(41 downto 10) /=
            to_stdlogicvector(frame_data(frame_no).stim(word_no).d)) or
           (frame_data(frame_no).stim(word_no).c /= x"0")) then
          assert false
            report "Tx data check ERROR!!, frame " &
                    integer'image(frame_no) &
                    ", word " &
                    integer'image(word_no) &
                    ", StimData = " &
                    integer'image(conv_integer(ieee.std_logic_arith.unsigned(to_stdlogicvector(frame_data(frame_no).stim(word_no).d)))) &
                    "MonData = " &
                    integer'image(conv_integer(ieee.std_logic_arith.unsigned(DeScr_RXD(41 downto 10))))
            severity error;
        else
          assert false
            report "Tx data check OK!!, frame " &
                   integer'image(frame_no) &
                   ", word " &
                   integer'image(word_no)
            severity note;
        end if;
        if((x"07" & x"FD" & DeScr_RXD(57 downto 42) /=
            to_stdlogicvector(frame_data(frame_no).stim(word_no+1).d)) or
           (frame_data(frame_no).stim(word_no+1).c /= x"C")) then
          assert false
            report "Tx data check ERROR!!, frame " &
                    integer'image(frame_no) &
                    ", word " &
                    integer'image(word_no+1) &
                    ", StimData = " &
                    integer'image(conv_integer(ieee.std_logic_arith.unsigned(to_stdlogicvector(frame_data(frame_no).stim(word_no+1).d)))) &
                    "MonData = " &
                    integer'image(conv_integer(ieee.std_logic_arith.unsigned(x"00" & x"00" & DeScr_RXD(57 downto 42))))
            severity error;
        else
          assert false
            report "Tx data check OK!!, frame " &
                   integer'image(frame_no) &
                   ", word " &
                   integer'image(word_no+1)
            severity note;
        end if;
        word_no := 0;
        frame_no := frame_no + 1;
      elsif(in_a_frame = '1' and (DeScr_RXD(1 downto 0) = "01" and
              DeScr_RXD(9 downto 2) = x"D2")) then
        in_a_frame <= '0';
      -- T code in 6th byte, data in bytes 1..5
        if((DeScr_RXD(41 downto 10) /=
            to_stdlogicvector(frame_data(frame_no).stim(word_no).d)) or
           (frame_data(frame_no).stim(word_no).c /= x"0")) then
          assert false
            report "Tx data check ERROR!!, frame " &
                    integer'image(frame_no) &
                    ", word " &
                    integer'image(word_no) &
                    ", StimData = " &
                    integer'image(conv_integer(ieee.std_logic_arith.unsigned(to_stdlogicvector(frame_data(frame_no).stim(word_no).d)))) &
                    "MonData = " &
                    integer'image(conv_integer(ieee.std_logic_arith.unsigned(DeScr_RXD(41 downto 10))))
            severity error;
        else
          assert false
            report "Tx data check OK!!, frame " &
                   integer'image(frame_no) &
                   ", word " &
                   integer'image(word_no)
            severity note;
        end if;
        if((x"07" & x"07" & x"FD" & DeScr_RXD(49 downto 42) /=
            to_stdlogicvector(frame_data(frame_no).stim(word_no+1).d)) or
           (frame_data(frame_no).stim(word_no+1).c /= x"E")) then
          assert false
            report "Tx data check ERROR!!, frame " &
                    integer'image(frame_no) &
                    ", word " &
                    integer'image(word_no+1) &
                    ", StimData = " &
                    integer'image(conv_integer(ieee.std_logic_arith.unsigned(to_stdlogicvector(frame_data(frame_no).stim(word_no+1).d)))) &
                    "MonData = " &
                    integer'image(conv_integer(ieee.std_logic_arith.unsigned(x"00" & x"00" & x"00" & DeScr_RXD(49 downto 42))))
            severity error;
        else
          assert false
            report "Tx data check OK!!, frame " &
                   integer'image(frame_no) &
                   ", word " &
                   integer'image(word_no+1)
            severity note;
        end if;
        word_no := 0;
        frame_no := frame_no + 1;
      elsif(in_a_frame = '1' and (DeScr_RXD(1 downto 0) = "01" and
              DeScr_RXD(9 downto 2) = x"CC")) then
        in_a_frame <= '0';
      -- T code, data in bytes 1..4
        if((DeScr_RXD(41 downto 10) /=
            to_stdlogicvector(frame_data(frame_no).stim(word_no).d)) or
           (frame_data(frame_no).stim(word_no).c /= x"0")) then
          assert false
            report "Tx data check ERROR!!, frame " &
                    integer'image(frame_no) &
                    ", word " &
                    integer'image(word_no) &
                    ", StimData = " &
                    integer'image(conv_integer(ieee.std_logic_arith.unsigned(to_stdlogicvector(frame_data(frame_no).stim(word_no).d)))) &
                    "MonData = " &
                    integer'image(conv_integer(ieee.std_logic_arith.unsigned(DeScr_RXD(41 downto 10))))
            severity error;
        else
          assert false
            report "Tx data check OK!!, frame " &
                   integer'image(frame_no) &
                   ", word " &
                   integer'image(word_no)
            severity note;
        end if;
        if((x"07" & x"07" & x"07" & x"FD" /=
            to_stdlogicvector(frame_data(frame_no).stim(word_no+1).d)) or
           (frame_data(frame_no).stim(word_no+1).c /= x"F")) then
          assert false
            report "Tx data check ERROR!!, frame " &
                    integer'image(frame_no) &
                    ", word " &
                    integer'image(word_no+1) &
                    ", StimData = " &
                    integer'image(conv_integer(ieee.std_logic_arith.unsigned(to_stdlogicvector(frame_data(frame_no).stim(word_no+1).d)))) &
                    "MonData = " &
                    "00000000"
            severity error;
        else
          assert false
            report "Tx data check OK!!, frame " &
                   integer'image(frame_no) &
                   ", word " &
                   integer'image(word_no+1)
            severity note;
        end if;
        word_no := 0;
        frame_no := frame_no + 1;
      elsif(in_a_frame = '1' and (DeScr_RXD(1 downto 0) = "01" and
              DeScr_RXD(9 downto 2) = x"B4")) then
        in_a_frame <= '0';
      -- T code, data in bytes 1..3
        if((x"FD" & DeScr_RXD(33 downto 10) /=
            to_stdlogicvector(frame_data(frame_no).stim(word_no).d)) or
           (frame_data(frame_no).stim(word_no).c /= x"8")) then
          assert false
            report "Tx data check ERROR!!, frame " &
                    integer'image(frame_no) &
                    ", word " &
                    integer'image(word_no) &
                    ", StimData = " &
                    integer'image(conv_integer(ieee.std_logic_arith.unsigned(to_stdlogicvector(frame_data(frame_no).stim(word_no).d)))) &
                    "MonData = " &
                    integer'image(conv_integer(ieee.std_logic_arith.unsigned(x"00" & DeScr_RXD(33 downto 10))))
            severity error;
        else
          assert false
            report "Tx data check OK!!, frame " &
                   integer'image(frame_no) &
                   ", word " &
                   integer'image(word_no)
            severity note;
        end if;
        word_no := 0;
        frame_no := frame_no + 1;
      elsif(in_a_frame = '1' and (DeScr_RXD(1 downto 0) = "01" and
              DeScr_RXD(9 downto 2) = x"AA")) then
        in_a_frame <= '0';
      -- T code, data in bytes 1..2
        if((x"07" & x"FD" & DeScr_RXD(25 downto 10) /=
            to_stdlogicvector(frame_data(frame_no).stim(word_no).d)) or
           (frame_data(frame_no).stim(word_no).c /= x"C")) then
          assert false
            report "Tx data check ERROR!!, frame " &
                    integer'image(frame_no) &
                    ", word " &
                    integer'image(word_no) &
                    ", StimData = " &
                    integer'image(conv_integer(ieee.std_logic_arith.unsigned(to_stdlogicvector(frame_data(frame_no).stim(word_no).d)))) &
                    "MonData = " &
                    integer'image(conv_integer(ieee.std_logic_arith.unsigned(x"00" & x"00" & DeScr_RXD(25 downto 10))))
            severity error;
        else
          assert false
            report "Tx data check OK!!, frame " &
                   integer'image(frame_no) &
                   ", word " &
                   integer'image(word_no)
            severity note;
        end if;
        word_no := 0;
        frame_no := frame_no + 1;
      elsif(in_a_frame = '1' and (DeScr_RXD(1 downto 0) = "01" and
              DeScr_RXD(9 downto 2) = x"99")) then
        in_a_frame <= '0';
      -- T code, data in byte 1
        if((x"07" & x"07" & x"FD" & DeScr_RXD(17 downto 10) /=
            to_stdlogicvector(frame_data(frame_no).stim(word_no).d)) or
           (frame_data(frame_no).stim(word_no).c /= x"E")) then
          assert false
            report "Tx data check ERROR!!, frame " &
                    integer'image(frame_no) &
                    ", word " &
                    integer'image(word_no) &
                    ", StimData = " &
                    integer'image(conv_integer(ieee.std_logic_arith.unsigned(to_stdlogicvector(frame_data(frame_no).stim(word_no).d)))) &
                    "MonData = " &
                    integer'image(conv_integer(ieee.std_logic_arith.unsigned(x"00" & x"00" & x"00" & DeScr_RXD(17 downto 10))))
            severity error;
        else
          assert false
            report "Tx data check OK!!, frame " &
                   integer'image(frame_no) &
                   ", word " &
                   integer'image(word_no)
            severity note;
        end if;
        word_no := 0;
        frame_no := frame_no + 1;
      elsif(in_a_frame = '1' and (DeScr_RXD(1 downto 0) = "01" and
              DeScr_RXD(9 downto 2) = x"87")) then
        in_a_frame <= '0';
      -- T code, no data
        if((x"07" & x"07" & x"07" & x"FD" /=
            to_stdlogicvector(frame_data(frame_no).stim(word_no).d)) or
           (frame_data(frame_no).stim(word_no).c /= x"F")) then
          assert false
            report "Tx data check ERROR!!, frame " &
                    integer'image(frame_no) &
                    ", word " &
                    integer'image(word_no) &
                    ", StimData = " &
                    integer'image(conv_integer(ieee.std_logic_arith.unsigned(to_stdlogicvector(frame_data(frame_no).stim(word_no).d)))) &
                    "MonData = " &
                    "00000000"
            severity error;
        else
          assert false
            report "Tx data check OK!!, frame " &
                   integer'image(frame_no) &
                   ", word " &
                   integer'image(word_no)
            severity note;
        end if;
        word_no := 0;
        frame_no := frame_no + 1;
      elsif(in_a_frame = '1' and (DeScr_RXD(1 downto 0) = "10")) then -- All data
        if((DeScr_RXD(33 downto 2) /=
            to_stdlogicvector(frame_data(frame_no).stim(word_no).d)) or
           (frame_data(frame_no).stim(word_no).c /= x"0")) then
          assert false
            report "Tx data check ERROR!!, frame " &
                    integer'image(frame_no) &
                    ", word " &
                    integer'image(word_no) &
                    ", StimData = " &
                    integer'image(conv_integer(ieee.std_logic_arith.unsigned(to_stdlogicvector(frame_data(frame_no).stim(word_no).d)))) &
                    "MonData = " &
                    integer'image(conv_integer(ieee.std_logic_arith.unsigned(DeScr_RXD(33 downto 2))))
            severity error;
        else
          assert false
            report "Tx data check OK!!, frame " &
                   integer'image(frame_no) &
                   ", word " &
                   integer'image(word_no)
            severity note;
        end if;
        if((DeScr_RXD(65 downto 34) /=
            to_stdlogicvector(frame_data(frame_no).stim(word_no+1).d)) or
           (frame_data(frame_no).stim(word_no).c /= x"0")) then
          assert false
            report "Tx data check ERROR!!, frame " &
                    integer'image(frame_no) &
                    ", word " &
                    integer'image(word_no+1) &
                    ", StimData = " &
                    integer'image(conv_integer(ieee.std_logic_arith.unsigned(to_stdlogicvector(frame_data(frame_no).stim(word_no+1).d)))) &
                    "MonData = " &
                    integer'image(conv_integer(ieee.std_logic_arith.unsigned(DeScr_RXD(65 downto 34))))
            severity error;
        else
          assert false
            report "Tx data check OK!!, frame " &
                   integer'image(frame_no) &
                   ", word " &
                   integer'image(word_no+1)
            severity note;
        end if;
        word_no := word_no + 2;
      end if;
    end if;
  end process p_check_tx;

  ------------------------------------------------------------------
  -- Receive Monitor code.....
  ------------------------------------------------------------------
  p_rx_regs : process(xgmii_rx_clk)
  begin
    if(rising_edge(xgmii_rx_clk)) then
      xgmii_rxd_int <= xgmii_rxd;
      xgmii_rxc_int <= xgmii_rxc;
    end if;
  end process p_rx_regs;

  -- Simply compare what arrives on RX with what was Transmitted to core
  p_rx_check : process(xgmii_rx_clk)
    variable rx_frame_no : integer;
    variable rx_word_no : integer;
    variable rx_half_word : std_logic;
  begin
    if(xgmii_rx_clk'event) then
	  if(xgmii_rx_clk = '1') then
	    rx_half_word := '1';
      else
	    rx_half_word := '0';
      end if;
      if(reset = '1' or resetdone = '0' or block_lock = '0') then
        rx_frame_no := 0;
        rx_word_no := 0;
      elsif(rx_half_word = '0') then
        if(xgmii_rxc_int(3 downto 0) = x"1" and xgmii_rxd_int(7 downto 0) = x"FB") then -- Frames always begin with this
          if(xgmii_rxd_int(31 downto 0) /= to_stdlogicvector(frame_data(rx_frame_no).stim(rx_word_no).d)) then
            assert false
              report "Rx data check ERROR (/S/)!!, frame " &
              integer'image(rx_frame_no) &
              ", word " &
              integer'image(rx_word_no)
            severity error;
          else
            assert false
              report "Rx data check OK (/S/)!!, frame " &
              integer'image(rx_frame_no) &
              ", word " &
              integer'image(rx_word_no)
            severity note;
          end if;
          rx_word_no := rx_word_no + 1;
        elsif(rx_word_no > 0 and xgmii_rxc_int(3 downto 0) = x"0") then -- Data only
          if(xgmii_rxd_int(31 downto 0) /= to_stdlogicvector(frame_data(rx_frame_no).stim(rx_word_no).d)) then
            assert false
              report "Rx data check ERROR (/D/)!!, frame " &
              integer'image(rx_frame_no) &
              ", word " &
              integer'image(rx_word_no)
            severity error;
          else
            assert false
              report "Rx data check OK (/D/)!!, frame " &
              integer'image(rx_frame_no) &
              ", word " &
              integer'image(rx_word_no)
            severity note;
          end if;
          rx_word_no := rx_word_no + 1;
        elsif(rx_word_no > 0) then -- T code plus 0, 1, 2 or 3 data
          if(xgmii_rxd_int(31 downto 0) /= to_stdlogicvector(frame_data(rx_frame_no).stim(rx_word_no).d)) then
            assert false
              report "Rx data check ERROR (/T/)!!, frame " &
              integer'image(rx_frame_no) &
              ", word " &
              integer'image(rx_word_no)
            severity error;
          else
            assert false
              report "Rx data check OK (/T/)!!, frame " &
              integer'image(rx_frame_no) &
              ", word " &
              integer'image(rx_word_no)
            severity note;
          end if;
          rx_frame_no := rx_frame_no + 1;
          rx_word_no := 0;
        end if;
      else -- rx_half_word = '1'
        if(xgmii_rxc_int(7 downto 4) = x"1" and xgmii_rxd_int(39 downto 32) = x"FB") then -- Frames always begin with this
          if(xgmii_rxd_int(63 downto 32) /= to_stdlogicvector(frame_data(rx_frame_no).stim(rx_word_no).d)) then
            assert false
              report "Rx data check ERROR (/S/)!!, frame " &
              integer'image(rx_frame_no) &
              ", word " &
              integer'image(rx_word_no)
            severity error;
          else
            assert false
              report "Rx data check OK (/S/)!!, frame " &
              integer'image(rx_frame_no) &
              ", word " &
              integer'image(rx_word_no)
            severity note;
          end if;
          rx_word_no := rx_word_no + 1;
        elsif(rx_word_no > 0 and xgmii_rxc_int(7 downto 4) = x"0") then -- Data only
          if(xgmii_rxd_int(63 downto 32) /= to_stdlogicvector(frame_data(rx_frame_no).stim(rx_word_no).d)) then
            assert false
              report "Rx data check ERROR (/D/)!!, frame " &
              integer'image(rx_frame_no) &
              ", word " &
              integer'image(rx_word_no)
            severity error;
          else
            assert false
              report "Rx data check OK (/D/)!!, frame " &
              integer'image(rx_frame_no) &
              ", word " &
              integer'image(rx_word_no)
            severity note;
          end if;
          rx_word_no := rx_word_no + 1;
        elsif(rx_word_no > 0) then -- T code plus 0, 1, 2 or 3 data
          if(xgmii_rxd_int(63 downto 32) /= to_stdlogicvector(frame_data(rx_frame_no).stim(rx_word_no).d)) then
            assert false
              report "Rx data check ERROR (/T/)!!, frame " &
              integer'image(rx_frame_no) &
              ", word " &
              integer'image(rx_word_no)
            severity error;
          else
            assert false
              report "Rx data check OK (/T/)!!, frame " &
              integer'image(rx_frame_no) &
              ", word " &
              integer'image(rx_word_no)
            severity note;
          end if;
          rx_frame_no := rx_frame_no + 1;
          rx_word_no := 0;
        end if;
      end if;
      if(rx_frame_no = 4) then --  We're done!
        simulation_finished <= true;
      end if;
    end if;
  end process p_rx_check;

  ------------------------------------------------------------------
  -- Receive Stimulus code.....
  ------------------------------------------------------------------

  -- Support code for transmitting frames to core rxn/p

  p_rx_stimulus : process

    -- Encode next 64 bits of frame;
    procedure rx_stimulus_send_column (
      constant d1 : in std_logic_vector(31 downto 0);
      constant c1 : in std_logic_vector(3 downto 0)) is
    begin
      wait until core_clk156_out'event;
      d0 <= d1;
      c0 <= c1;

      d <= d1 & d0;
      c <= c1 & c0;

      -- Need to know when to apply the encoded data to the scrambler
      if(decided_clk_edge = '0' and (c0(0) = '1' or c0(1) = '1' or c0(2) = '1' or c0(3) = '1')) then -- Found first full 64 bit word
        clk_edge <= not(core_clk156_out);
        decided_clk_edge <= '1';
      end if;

      -- Detect column of IDLEs vs T code in byte 0
      if(c = x"FF" and d(7 downto 0) /= x"FD") then -- Column of IDLEs
        TxEnc(1 downto 0) <= "01";
        TxEnc(65 downto 2) <= x"000000000000001E";
      elsif(c /= x"00") then -- Control code somewhere
        TxEnc(1 downto 0) <= "01";

        if(c = "00000001") then -- Start code
          TxEnc(9 downto 2) <= x"78";
          TxEnc(65 downto 10) <= d(63 downto 8);
        end if;
        if(c = "00011111") then -- Start code
          TxEnc(9 downto 2) <= x"33";
          TxEnc(41 downto 10) <= x"00000000";
          TxEnc(65 downto 42) <= d(63 downto 40);
        elsif(c = "10000000") then -- End code
          TxEnc(9 downto 2) <= x"FF";
          TxEnc(65 downto 10) <= d(55 downto 0);
        elsif(c = "11000000") then -- End code
          TxEnc(9 downto 2) <= x"E1";
          TxEnc(57 downto 10) <= d(47 downto 0);
          TxEnc(65 downto 58) <= x"00";
        elsif(c = "11100000") then -- End code
          TxEnc(9 downto 2) <= x"D2";
          TxEnc(49 downto 10) <= d(39 downto 0);
          TxEnc(65 downto 50) <= x"0000";
        elsif(c = "11110000") then -- End code
          TxEnc(9 downto 2) <= x"CC";
          TxEnc(41 downto 10) <= d(31 downto 0);
          TxEnc(65 downto 42) <= x"000000";
        elsif(c = "11111000") then -- End code
          TxEnc(9 downto 2) <= x"B4";
          TxEnc(33 downto 10) <= d(23 downto 0);
          TxEnc(65 downto 34) <= x"00000000";
        elsif(c = "11111100") then -- End code
          TxEnc(9 downto 2) <= x"AA";
          TxEnc(25 downto 10) <= d(15 downto 0);
          TxEnc(65 downto 26) <= x"0000000000";
        elsif(c = "11111110") then -- End code
          TxEnc(9 downto 2) <= x"99";
          TxEnc(17 downto 10) <= d(7 downto 0);
          TxEnc(65 downto 18) <= x"000000000000";
        elsif(c = "11111111") then -- End code
          TxEnc(9 downto 2) <= x"87";
          TxEnc(65 downto 10) <= x"00000000000000";
        end if;
      else -- all data
        TxEnc(1 downto 0) <= "10";
        TxEnc(65 downto 2) <= d;
      end if;
    end rx_stimulus_send_column;

    procedure rx_send_column (
      constant c : in column_typ) is
    begin -- send_column
      rx_stimulus_send_column(to_stdlogicvector(c.d), to_stdlogicvector(c.c));
    end rx_send_column;

    procedure rx_stimulus_send_idle is
    begin
      rx_stimulus_send_column(x"07070707", "1111");
    end rx_stimulus_send_idle;

    procedure rx_stimulus_send_frame (
      constant frame : in frame_typ) is
        variable column_index : integer := 0;
    begin
      column_index := 0;
      -- send columns
      while (column_index < frame.length) loop
        rx_send_column(frame.stim(column_index));
        column_index := column_index + 1;
      end loop;
      report "Receiver: frame inserted into Serial interface" severity note;
    end rx_stimulus_send_frame;

  begin

    -- wait until the core is ready after reset - this will be indicated
    -- by a rising edge on the resetdone signal.
    while (resetdone /= '1') loop
      wait until core_clk156_out'event;
    end loop;
    -- now wait until the testbench has block_lock on the transmitted idles
    while (block_lock /= '1') loop
      rx_stimulus_send_idle;
    end loop;


    -- Give the GTX time to get block_lock on incoming data...
    while (core_status(0) /= '1') loop
      rx_stimulus_send_idle;
    end loop;

    rx_stimulus_send_frame(frame_data(0));
    rx_stimulus_send_idle;
    rx_stimulus_send_idle;
    rx_stimulus_send_frame(frame_data(1));
    rx_stimulus_send_idle;
    rx_stimulus_send_idle;
    rx_stimulus_send_frame(frame_data(2));
    rx_stimulus_send_idle;
    rx_stimulus_send_idle;
    rx_stimulus_send_frame(frame_data(3));
    while(true) loop rx_stimulus_send_idle; end loop;
    wait;
  end process p_rx_stimulus;

  -- Capture the 66 bit data for scrambling...
  TxEnc_clock <= clk_edge xnor core_clk156_out;

  p_rxready : process(TxEnc_clock)
  begin
    if(rising_edge(TxEnc_clock)) then
      TxEnc_Data <= TxEnc;
      if(resetdone = '1') then
        rxbitsready <= '1';
      end if;
    end if;
  end process;

  -- Scramble the TxEnc_Data before applying to rxn/p
  Scr_wire(0) <= TXD_input(0) xor Scrambler_Register(38) xor Scrambler_Register(57);
  Scr_wire(1) <= TXD_input(1) xor Scrambler_Register(37) xor Scrambler_Register(56);
  Scr_wire(2) <= TXD_input(2) xor Scrambler_Register(36) xor Scrambler_Register(55);
  Scr_wire(3) <= TXD_input(3) xor Scrambler_Register(35) xor Scrambler_Register(54);
  Scr_wire(4) <= TXD_input(4) xor Scrambler_Register(34) xor Scrambler_Register(53);
  Scr_wire(5) <= TXD_input(5) xor Scrambler_Register(33) xor Scrambler_Register(52);
  Scr_wire(6) <= TXD_input(6) xor Scrambler_Register(32) xor Scrambler_Register(51);
  Scr_wire(7) <= TXD_input(7) xor Scrambler_Register(31) xor Scrambler_Register(50);

  Scr_wire(8) <= TXD_input(8) xor Scrambler_Register(30) xor Scrambler_Register(49);
  Scr_wire(9) <= TXD_input(9) xor Scrambler_Register(29) xor Scrambler_Register(48);
  Scr_wire(10) <= TXD_input(10) xor Scrambler_Register(28) xor Scrambler_Register(47);
  Scr_wire(11) <= TXD_input(11) xor Scrambler_Register(27) xor Scrambler_Register(46);
  Scr_wire(12) <= TXD_input(12) xor Scrambler_Register(26) xor Scrambler_Register(45);
  Scr_wire(13) <= TXD_input(13) xor Scrambler_Register(25) xor Scrambler_Register(44);
  Scr_wire(14) <= TXD_input(14) xor Scrambler_Register(24) xor Scrambler_Register(43);
  Scr_wire(15) <= TXD_input(15) xor Scrambler_Register(23) xor Scrambler_Register(42);

  Scr_wire(16) <= TXD_input(16) xor Scrambler_Register(22) xor Scrambler_Register(41);
  Scr_wire(17) <= TXD_input(17) xor Scrambler_Register(21) xor Scrambler_Register(40);
  Scr_wire(18) <= TXD_input(18) xor Scrambler_Register(20) xor Scrambler_Register(39);
  Scr_wire(19) <= TXD_input(19) xor Scrambler_Register(19) xor Scrambler_Register(38);
  Scr_wire(20) <= TXD_input(20) xor Scrambler_Register(18) xor Scrambler_Register(37);
  Scr_wire(21) <= TXD_input(21) xor Scrambler_Register(17) xor Scrambler_Register(36);
  Scr_wire(22) <= TXD_input(22) xor Scrambler_Register(16) xor Scrambler_Register(35);
  Scr_wire(23) <= TXD_input(23) xor Scrambler_Register(15) xor Scrambler_Register(34);

  Scr_wire(24) <= TXD_input(24) xor Scrambler_Register(14) xor Scrambler_Register(33);
  Scr_wire(25) <= TXD_input(25) xor Scrambler_Register(13) xor Scrambler_Register(32);
  Scr_wire(26) <= TXD_input(26) xor Scrambler_Register(12) xor Scrambler_Register(31);
  Scr_wire(27) <= TXD_input(27) xor Scrambler_Register(11) xor Scrambler_Register(30);
  Scr_wire(28) <= TXD_input(28) xor Scrambler_Register(10) xor Scrambler_Register(29);
  Scr_wire(29) <= TXD_input(29) xor Scrambler_Register(9) xor Scrambler_Register(28);
  Scr_wire(30) <= TXD_input(30) xor Scrambler_Register(8) xor Scrambler_Register(27);
  Scr_wire(31) <= TXD_input(31) xor Scrambler_Register(7) xor Scrambler_Register(26);

  Scr_wire(32) <= TXD_input(32) xor Scrambler_Register(6) xor Scrambler_Register(25);
  Scr_wire(33) <= TXD_input(33) xor Scrambler_Register(5) xor Scrambler_Register(24);
  Scr_wire(34) <= TXD_input(34) xor Scrambler_Register(4) xor Scrambler_Register(23);
  Scr_wire(35) <= TXD_input(35) xor Scrambler_Register(3) xor Scrambler_Register(22);
  Scr_wire(36) <= TXD_input(36) xor Scrambler_Register(2) xor Scrambler_Register(21);
  Scr_wire(37) <= TXD_input(37) xor Scrambler_Register(1) xor Scrambler_Register(20);
  Scr_wire(38) <= TXD_input(38) xor Scrambler_Register(0) xor Scrambler_Register(19);
  Scr_wire(39) <= TXD_input(39) xor TXD_input(0) xor Scrambler_Register(38) xor Scrambler_Register(57) xor Scrambler_Register(18);
  Scr_wire(40) <= TXD_input(40) xor (TXD_input(1) xor Scrambler_Register(37) xor Scrambler_Register(56)) xor Scrambler_Register(17);
  Scr_wire(41) <= TXD_input(41) xor (TXD_input(2) xor Scrambler_Register(36) xor Scrambler_Register(55)) xor Scrambler_Register(16);
  Scr_wire(42) <= TXD_input(42) xor (TXD_input(3) xor Scrambler_Register(35) xor Scrambler_Register(54)) xor Scrambler_Register(15);
  Scr_wire(43) <= TXD_input(43) xor (TXD_input(4) xor Scrambler_Register(34) xor Scrambler_Register(53)) xor Scrambler_Register(14);
  Scr_wire(44) <= TXD_input(44) xor (TXD_input(5) xor Scrambler_Register(33) xor Scrambler_Register(52)) xor Scrambler_Register(13);
  Scr_wire(45) <= TXD_input(45) xor (TXD_input(6) xor Scrambler_Register(32) xor Scrambler_Register(51)) xor Scrambler_Register(12);
  Scr_wire(46) <= TXD_input(46) xor (TXD_input(7) xor Scrambler_Register(31) xor Scrambler_Register(50)) xor Scrambler_Register(11);
  Scr_wire(47) <= TXD_input(47) xor (TXD_input(8) xor Scrambler_Register(30) xor Scrambler_Register(49)) xor Scrambler_Register(10);

  Scr_wire(48) <= TXD_input(48) xor (TXD_input(9) xor Scrambler_Register(29) xor Scrambler_Register(48)) xor Scrambler_Register(9);
  Scr_wire(49) <= TXD_input(49) xor (TXD_input(10) xor Scrambler_Register(28) xor Scrambler_Register(47)) xor Scrambler_Register(8);
  Scr_wire(50) <= TXD_input(50) xor (TXD_input(11) xor Scrambler_Register(27) xor Scrambler_Register(46)) xor Scrambler_Register(7);
  Scr_wire(51) <= TXD_input(51) xor (TXD_input(12) xor Scrambler_Register(26) xor Scrambler_Register(45)) xor Scrambler_Register(6);
  Scr_wire(52) <= TXD_input(52) xor (TXD_input(13) xor Scrambler_Register(25) xor Scrambler_Register(44)) xor Scrambler_Register(5);
  Scr_wire(53) <= TXD_input(53) xor (TXD_input(14) xor Scrambler_Register(24) xor Scrambler_Register(43)) xor Scrambler_Register(4);
  Scr_wire(54) <= TXD_input(54) xor (TXD_input(15) xor Scrambler_Register(23) xor Scrambler_Register(42)) xor Scrambler_Register(3);
  Scr_wire(55) <= TXD_input(55) xor (TXD_input(16) xor Scrambler_Register(22) xor Scrambler_Register(41)) xor Scrambler_Register(2);

  Scr_wire(56) <= TXD_input(56) xor (TXD_input(17) xor Scrambler_Register(21) xor Scrambler_Register(40)) xor Scrambler_Register(1);
  Scr_wire(57) <= TXD_input(57) xor (TXD_input(18) xor Scrambler_Register(20) xor Scrambler_Register(39)) xor Scrambler_Register(0);
  Scr_wire(58) <= TXD_input(58) xor (TXD_input(19) xor Scrambler_Register(19) xor Scrambler_Register(38)) xor (TXD_input(0) xor Scrambler_Register(38) xor Scrambler_Register(57));
  Scr_wire(59) <= TXD_input(59) xor (TXD_input(20) xor Scrambler_Register(18) xor Scrambler_Register(37)) xor (TXD_input(1) xor Scrambler_Register(37) xor Scrambler_Register(56));
  Scr_wire(60) <= TXD_input(60) xor (TXD_input(21) xor Scrambler_Register(17) xor Scrambler_Register(36)) xor (TXD_input(2) xor Scrambler_Register(36) xor Scrambler_Register(55));
  Scr_wire(61) <= TXD_input(61) xor (TXD_input(22) xor Scrambler_Register(16) xor Scrambler_Register(35)) xor (TXD_input(3) xor Scrambler_Register(35) xor Scrambler_Register(54));
  Scr_wire(62) <= TXD_input(62) xor (TXD_input(23) xor Scrambler_Register(15) xor Scrambler_Register(34)) xor (TXD_input(4) xor Scrambler_Register(34) xor Scrambler_Register(53));
  Scr_wire(63) <= TXD_input(63) xor (TXD_input(24) xor Scrambler_Register(14) xor Scrambler_Register(33)) xor (TXD_input(5) xor Scrambler_Register(33) xor Scrambler_Register(52));


  p_scramble : process(TxEnc_clock)
  begin
    if(rising_edge(TxEnc_clock)) then
      if (reset = '1' or resetdone = '0') then
        Scrambler_Register(57 downto 0) <= "00" & x"00000000000003";
        TXD_input(63 downto 0) <= x"0000000000000000";
        Sync_header(1 downto 0) <= "10";
        TXD_Scr(65 downto 0) <= "00" & x"0000000000000002";
      else
        TXD_input(63 downto 0) <= TxEnc_Data(65 downto 2);
        Sync_header(1 downto 0) <= TxEnc_Data(1 downto 0);
        TXD_Scr(65 downto 0) <= Scr_wire(63 downto 0) & Sync_header(1 downto 0);

        Scrambler_Register(57) <= Scr_wire(6);
        Scrambler_Register(56) <= Scr_wire(7);
        Scrambler_Register(55) <= Scr_wire(8);
        Scrambler_Register(54) <= Scr_wire(9);
        Scrambler_Register(53) <= Scr_wire(10);
        Scrambler_Register(52) <= Scr_wire(11);
        Scrambler_Register(51) <= Scr_wire(12);
        Scrambler_Register(50) <= Scr_wire(13);

        Scrambler_Register(49) <= Scr_wire(14);
        Scrambler_Register(48) <= Scr_wire(15);
        Scrambler_Register(47) <= Scr_wire(16);
        Scrambler_Register(46) <= Scr_wire(17);
        Scrambler_Register(45) <= Scr_wire(18);
        Scrambler_Register(44) <= Scr_wire(19);
        Scrambler_Register(43) <= Scr_wire(20);
        Scrambler_Register(42) <= Scr_wire(21);

        Scrambler_Register(41) <= Scr_wire(22);
        Scrambler_Register(40) <= Scr_wire(23);
        Scrambler_Register(39) <= Scr_wire(24);
        Scrambler_Register(38) <= Scr_wire(25);
        Scrambler_Register(37) <= Scr_wire(26);
        Scrambler_Register(36) <= Scr_wire(27);
        Scrambler_Register(35) <= Scr_wire(28);
        Scrambler_Register(34) <= Scr_wire(29);

        Scrambler_Register(33) <= Scr_wire(30);
        Scrambler_Register(32) <= Scr_wire(31);
        Scrambler_Register(31) <= Scr_wire(32);
        Scrambler_Register(30) <= Scr_wire(33);
        Scrambler_Register(29) <= Scr_wire(34);
        Scrambler_Register(28) <= Scr_wire(35);
        Scrambler_Register(27) <= Scr_wire(36);
        Scrambler_Register(26) <= Scr_wire(37);

        Scrambler_Register(25) <= Scr_wire(38);
        Scrambler_Register(24) <= Scr_wire(39);
        Scrambler_Register(23) <= Scr_wire(40);
        Scrambler_Register(22) <= Scr_wire(41);
        Scrambler_Register(21) <= Scr_wire(42);
        Scrambler_Register(20) <= Scr_wire(43);
        Scrambler_Register(19) <= Scr_wire(44);
        Scrambler_Register(18) <= Scr_wire(45);

        Scrambler_Register(17) <= Scr_wire(46);
        Scrambler_Register(16) <= Scr_wire(47);
        Scrambler_Register(15) <= Scr_wire(48);
        Scrambler_Register(14) <= Scr_wire(49);
        Scrambler_Register(13) <= Scr_wire(50);
        Scrambler_Register(12) <= Scr_wire(51);
        Scrambler_Register(11) <= Scr_wire(52);
        Scrambler_Register(10) <= Scr_wire(53);

        Scrambler_Register(9) <=  Scr_wire(54);
        Scrambler_Register(8) <=  Scr_wire(55);
        Scrambler_Register(7) <=  Scr_wire(56);
        Scrambler_Register(6) <=  Scr_wire(57);
        Scrambler_Register(5) <=  Scr_wire(58);
        Scrambler_Register(4) <=  Scr_wire(59);
        Scrambler_Register(3) <=  Scr_wire(60);
        Scrambler_Register(2) <=  Scr_wire(61);
        Scrambler_Register(1) <=  Scr_wire(62);
        Scrambler_Register(0) <=  Scr_wire(63);
      end if;
    end if;
  end process p_scramble;

  -- Serialize the RX stimulus
  rxn <= not(rxp);

  p_rx_serialize : process(bitclk)
    variable rxbitno : integer;
  begin
    if(rising_edge(bitclk)) then
      if(reset = '1' or rxbitsready = '0') then
        rxp <= '1';
        rxbitno := 0;
      else
        rxp <= TXD_Scr(rxbitno);
        rxbitno := (rxbitno + 1) mod 66;
      end if;
    end if;
  end process p_rx_serialize;

end behav;
