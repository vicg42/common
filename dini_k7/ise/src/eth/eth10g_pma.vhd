-------------------------------------------------------------------------------
-- Title      : Example Design level wrapper
-- Project    : 10GBASE-R
-------------------------------------------------------------------------------
-- File       : eth10g_pma.vhd
-------------------------------------------------------------------------------
-- Description: This file is a wrapper for the 10GBASE-R core; it contains all
-- of the clock buffers required for implementing the block level
-------------------------------------------------------------------------------
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

library ieee;
use ieee.std_logic_1164.all;

entity eth10g_pma is
    generic (
      QPLL_FBDIV_TOP : integer := 66;
      EXAMPLE_SIM_GTRESET_SPEEDUP : string    := "FALSE"
      );
    port (
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
      pma_loopback     : in std_logic;
      pma_reset        : in std_logic;
      global_tx_disable: in std_logic;
      pma_vs_loopback  : in std_logic_vector(3 downto 0);
      pcs_loopback     : in std_logic;
      pcs_reset        : in std_logic;
      test_patt_a      : in std_logic_vector(57 downto 0);
      test_patt_b      : in std_logic_vector(57 downto 0);
      data_patt_sel    : in std_logic;
      test_patt_sel    : in std_logic;
      rx_test_patt_en  : in std_logic;
      tx_test_patt_en  : in std_logic;
      prbs31_tx_en     : in std_logic;
      prbs31_rx_en     : in std_logic;
      pcs_vs_loopback  : in std_logic_vector(1 downto 0);
      set_pma_link_status      : in std_logic;
      set_pcs_link_status      : in std_logic;
      clear_pcs_status2        : in std_logic;
      clear_test_patt_err_count: in std_logic;

      pma_link_status         : out std_logic;
      rx_sig_det              : out std_logic;
      pcs_rx_link_status      : out std_logic;
      pcs_rx_locked           : out std_logic;
      pcs_hiber               : out std_logic;
      teng_pcs_rx_link_status : out std_logic;
      pcs_err_block_count     : out std_logic_vector(7 downto 0);
      pcs_ber_count           : out std_logic_vector(5 downto 0);
      pcs_rx_hiber_lh         : out std_logic;
      pcs_rx_locked_ll        : out std_logic;
      pcs_test_patt_err_count : out std_logic_vector(15 downto 0);
      status_vector_preserve  : out std_logic;
      core_status      : out std_logic_vector(7 downto 0);
      resetdone        : out std_logic;
      signal_detect    : in  std_logic;
      tx_fault         : in  std_logic;
      tx_disable       : out std_logic;

      configuration_vector_preserve : in std_logic;
      is_eval          : out std_logic;
      an_enable        : in  std_logic;
      training_enable  : in  std_logic;
      training_addr    : in  std_logic_vector(20 downto 0);
      training_rnw     : in  std_logic;
      training_wrdata  : in  std_logic_vector(15 downto 0);
      training_ipif_cs : in  std_logic;
      training_drp_cs  : in  std_logic;
      training_rddata  : out std_logic_vector(15 downto 0);
      training_rdack   : out std_logic;
      training_wrack   : out std_logic
      );
end eth10g_pma;

library ieee;
use ieee.numeric_std.all;

library unisim;
use unisim.vcomponents.all;

architecture wrapper of eth10g_pma is

----------------------------------------------------------------------------
-- Component Declaration for the 10GBASE-R block level.
----------------------------------------------------------------------------

  component eth10g_pma_core_block is
    generic (
      QPLL_FBDIV_TOP : integer := 66;
      EXAMPLE_SIM_GTRESET_SPEEDUP : string    := "FALSE"
      );
    port (
--      mmcm_locked_out  : out std_logic;
      refclk_n         : in  std_logic;
      refclk_p         : in  std_logic;
      clk156           : out std_logic;
      txclk322         : out std_logic;
      rxclk322         : out std_logic;
      dclk             : out std_logic;
      areset           : in  std_logic;
      reset            : in  std_logic;
      txreset322       : in  std_logic;
      rxreset322       : in  std_logic;
      dclk_reset       : in  std_logic;
      txp              : out std_logic;
      txn              : out std_logic;
      rxp              : in  std_logic;
      rxn              : in  std_logic;
      xgmii_txd        : in  std_logic_vector(63 downto 0);
      xgmii_txc        : in  std_logic_vector(7 downto 0);
      xgmii_rxd        : out std_logic_vector(63 downto 0);
      xgmii_rxc        : out std_logic_vector(7 downto 0);
      configuration_vector : in  std_logic_vector(535 downto 0);
      status_vector        : out std_logic_vector(447 downto 0);
      core_status      : out std_logic_vector(7 downto 0);
      tx_resetdone     : out std_logic;
      rx_resetdone     : out std_logic;
      signal_detect    : in  std_logic;
      tx_fault         : in  std_logic;
      tx_disable       : out std_logic);
  end component;

----------------------------------------------------------------------------
-- Signal declarations.
----------------------------------------------------------------------------

  signal clk156                : std_logic;
  signal txclk322              : std_logic;
  attribute keep : string;
  attribute keep of txclk322 : signal is "true";
  signal rxclk322              : std_logic;
  signal dclk                  : std_logic;

  signal txclk156_mmcm0_locked : std_logic;

  signal core_reset_tx: std_logic;
  signal core_reset_rx: std_logic;
  signal txreset322   : std_logic;
  signal rxreset322   : std_logic;
  signal dclk_reset   : std_logic;

  signal core_reset_tx_tmp: std_logic;
  signal core_reset_rx_tmp: std_logic;
  signal txreset322_tmp   : std_logic;
  signal rxreset322_tmp   : std_logic;
  signal dclk_reset_tmp   : std_logic;

  signal tx_resetdone_int : std_logic;
  signal rx_resetdone_int : std_logic;
  signal xgmii_txd_reg : std_logic_vector(63 downto 0);
  signal xgmii_txc_reg : std_logic_vector(7 downto 0);

  signal xgmii_rxd_int : std_logic_vector(63 downto 0);
  signal xgmii_rxc_int : std_logic_vector(7 downto 0);


  signal configuration_vector : std_logic_vector(535 downto 0) := (others => '0');
  signal status_vector : std_logic_vector(447 downto 0);

  attribute async_reg : string;
  attribute async_reg of core_reset_tx_tmp : signal is "true";
  attribute async_reg of core_reset_tx : signal is "true";
  attribute async_reg of core_reset_rx_tmp : signal is "true";
  attribute async_reg of core_reset_rx : signal is "true";
  attribute async_reg of txreset322_tmp : signal is "true";
  attribute async_reg of txreset322 : signal is "true";
  attribute async_reg of rxreset322_tmp : signal is "true";
  attribute async_reg of rxreset322 : signal is "true";
  attribute async_reg of dclk_reset_tmp : signal is "true";
  attribute async_reg of dclk_reset : signal is "true";
begin

   configuration_vector(0)   <= pma_loopback;
   configuration_vector(15)  <= pma_reset;
   configuration_vector(16)  <= global_tx_disable;
   configuration_vector(83 downto 80) <= pma_vs_loopback;
   configuration_vector(110) <= pcs_loopback;
   configuration_vector(111) <= pcs_reset;
   configuration_vector(169 downto 112) <= test_patt_a;
   configuration_vector(233 downto 176) <= test_patt_b;
   configuration_vector(240) <= data_patt_sel;
   configuration_vector(241) <= test_patt_sel;
   configuration_vector(242) <= rx_test_patt_en;
   configuration_vector(243) <= tx_test_patt_en;
   configuration_vector(244) <= prbs31_tx_en;
   configuration_vector(245) <= prbs31_rx_en;
   configuration_vector(271 downto 270) <= pcs_vs_loopback;
   configuration_vector(512) <= set_pma_link_status;
   configuration_vector(516) <= set_pcs_link_status;
   configuration_vector(518) <= clear_pcs_status2;
   configuration_vector(519) <= clear_test_patt_err_count;

   pma_link_status <= status_vector(18);
   rx_sig_det <= status_vector(48);
   pcs_rx_link_status <= status_vector(226);
   pcs_rx_locked <= status_vector(256);
   pcs_hiber <= status_vector(257);
   teng_pcs_rx_link_status <= status_vector(268);
   pcs_err_block_count <= status_vector(279 downto 272);
   pcs_ber_count <= status_vector(285 downto 280);
   pcs_rx_hiber_lh <= status_vector(286);
   pcs_rx_locked_ll <= status_vector(287);
   pcs_test_patt_err_count <= status_vector(303 downto 288);

  resetdone <= tx_resetdone_int and rx_resetdone_int;

  cr_proc : process(reset, clk156)
  begin
    if(reset = '1') then
      core_reset_tx_tmp <= '1';
      core_reset_tx <= '1';
      core_reset_rx_tmp <= '1';
      core_reset_rx <= '1';
    elsif(clk156'event and clk156 = '1') then
      -- Hold core in reset until everything else is ready...
      core_reset_tx_tmp <= (not(tx_resetdone_int) or reset or
                        tx_fault or not(signal_detect));
      core_reset_tx <= core_reset_tx_tmp;
      core_reset_rx_tmp <= (not(rx_resetdone_int) or reset or
                        tx_fault or not(signal_detect));
      core_reset_rx <= core_reset_rx_tmp;
    end if;
  end process;


  tr161proc : process(reset, txclk322)
  begin
    if(reset = '1') then
      txreset322_tmp <= '1';
      txreset322 <= '1';
    elsif(txclk322'event and txclk322 = '1') then
      txreset322_tmp <= core_reset_tx;
      txreset322 <= txreset322_tmp;
    end if;
  end process;

  rr161proc : process(reset, rxclk322)
  begin
    if(reset = '1') then
      rxreset322_tmp <= '1';
      rxreset322 <= '1';
    elsif(rxclk322'event and rxclk322 = '1') then
      rxreset322_tmp <= core_reset_rx;
      rxreset322 <= rxreset322_tmp;
    end if;
  end process;

  dr_proc : process(reset, dclk)
  begin
    if(reset = '1') then
      dclk_reset_tmp <= '1';
      dclk_reset <= '1';
    elsif(dclk'event and dclk = '1') then
      dclk_reset_tmp <= core_reset_rx;
      dclk_reset <= dclk_reset_tmp;
    end if;
  end process;

  -- Add a pipeline to the xmgii_tx inputs, to aid timing closure
  tx_reg_proc : process(clk156)
  begin
    if(clk156'event and clk156 = '1') then
      xgmii_txd_reg <= xgmii_txd;
      xgmii_txc_reg <= xgmii_txc;
    end if;
  end process;

  -- Add a pipeline to the xmgii_rx outputs, to aid timing closure
  rx_reg_proc : process(clk156)
  begin
    if(clk156'event and clk156 = '1') then
      xgmii_rxd <= xgmii_rxd_int;
      xgmii_rxc <= xgmii_rxc_int;
    end if;
  end process;


  ten_gig_eth_pcs_pma_block : eth10g_pma_core_block
    generic map (
      QPLL_FBDIV_TOP => QPLL_FBDIV_TOP,
      EXAMPLE_SIM_GTRESET_SPEEDUP => EXAMPLE_SIM_GTRESET_SPEEDUP
      )
    port map (
--      mmcm_locked_out  => mmcm_locked,
      refclk_n         => refclk_n,
      refclk_p         => refclk_p,
      clk156           => clk156,
      txclk322         => txclk322,
      rxclk322         => rxclk322,
      dclk             => dclk,
      areset           => reset,
      reset            => core_reset_tx,
      txreset322       => txreset322,
      rxreset322       => rxreset322,
      dclk_reset       => dclk_reset,
      txp              => txp,
      txn              => txn,
      rxp              => rxp,
      rxn              => rxn,
      xgmii_txd        => xgmii_txd_reg,
      xgmii_txc        => xgmii_txc_reg,
      xgmii_rxd        => xgmii_rxd_int,
      xgmii_rxc        => xgmii_rxc_int,
      configuration_vector => configuration_vector,
      status_vector        => status_vector,
      core_status      => core_status,
      tx_resetdone     => tx_resetdone_int,
      rx_resetdone     => rx_resetdone_int,
      signal_detect    => signal_detect,
      tx_fault         => tx_fault,
      tx_disable       => tx_disable);

-----------------------------------------------------------------------------------------------------------------------
-- Clock management logic

  core_clk156_out <= clk156;

--  rx_clk_ddr : ODDR
--    generic map (
--      DDR_CLK_EDGE => "SAME_EDGE")
--    port map (
--      Q =>  xgmii_rx_clk,
--      D1 => '1',
--      D2 => '0',
--      C  => clk156,
--      CE => '1',
--      R  => '0',
--      S  => '0');

  xgmii_rx_clk <= clk156;

  training_rddata <= (others => '0');
  training_rdack <= '0';
  training_wrack <= '0';

end wrapper;
