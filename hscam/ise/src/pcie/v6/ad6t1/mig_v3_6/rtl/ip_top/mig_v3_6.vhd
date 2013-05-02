--*****************************************************************************
-- (c) Copyright 2009 - 2010 Xilinx, Inc. All rights reserved.
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
--*****************************************************************************
--   ____  ____
--  /   /\/   /
-- /___/  \  /    Vendor             : Xilinx
-- \   \   \/     Version            : 3.6
--  \   \         Application        : MIG
--  /   /         Filename           : mig_v3_6.vhd
-- /___/   /\     Date Last Modified : $Date: 2010/09/23 10:19:37 $
-- \   \  /  \    Date Created       : Mon Jun 23 2008
--  \___\/\___\
--
-- Device           : Virtex-6
-- Design Name      : DDR3 SDRAM
-- Purpose          :
--                   Top-level  module. This module serves both as an example,
--                   and allows the user to synthesize a self-contained design,
--                   which they can use to test their hardware. In addition to
--                   the memory controller.
--                   instantiates:
--                     1. Clock generation/distribution, reset logic
--                     2. IDELAY control block
--                     3. Synthesizable testbench - used to model user's backend
--                        logic
-- Reference        :
-- Revision History :
--*****************************************************************************

library ieee;
library unisim;
use ieee.std_logic_1164.all;
use unisim.vcomponents.all;
use ieee.numeric_std.all;
use work.ddr2_ddr3_chipscope.all;

entity mig_v3_6 is
  generic(
     REFCLK200_FREQ        : real := 200.0;
                                     -- # = 200 when design frequency <= 533 MHz,
                                     --   = 300 when design frequency > 533 MHz.
     IODELAY200_GRP        : string := "IODELAY200_MIG";
                                     -- It is associated to a set of IODELAYs with
                                     -- an IDELAYCTRL that have same IODELAY CONTROLLER
                                     -- clock frequency.
     CLK_f0FBOUT_MULT_F    : integer := 6;
                                     -- write PLL VCO multiplier.
     DIVCLK_f0_DIVIDE      : integer := 2;
                                     -- write PLL VCO divisor.
     CLK_f0OUT_DIVIDE      : integer := 3;
                                     -- VCO output divisor for fast (memory) clocks.
     nCK_PER_CLK_f0        : integer := 2;
                                     -- # of memory CKs per fabric clock.
                                     -- # = 2, 1.
     tCK_f0                : integer := 2500;
                                     -- memory tCK paramter.
                                     -- # = Clock Period.
     C0_DEBUG_PORT         : string := "OFF";
                                     -- # = "ON" Enable debug signals/controls.
                                     --   = "OFF" Disable debug signals/controls.
     C0_SIM_BYPASS_INIT_CAL : string := "OFF";
                                     -- # = "OFF" -  Complete memory init &
                                     --              calibration sequence
                                     -- # = "SKIP" - Skip memory init &
                                     --              calibration sequence
                                     -- # = "FAST" - Skip memory init & use
                                     --              abbreviated calib sequence
	 C0_SIM_INIT_OPTION       : string := "NONE";
                                     -- # = "SKIP_PU_DLY" - Skip the memory
                                     --                     initilization sequence,
                                     --   = "NONE" - Complete the memory
                                     --              initilization sequence.
     C0_SIM_CAL_OPTION     : string := "NONE";
                                     -- # = "FAST_CAL" - Skip the delay
                                     --                  Calibration process,
                                     --   = "NONE" - Complete the delay
                                     --              Calibration process.
     C0_nCS_PER_RANK       : integer := 1;
                                     -- # of unique CS outputs per Rank for
                                     -- phy.
     C0_DQS_CNT_WIDTH      : integer := 2;
                                     -- # = ceil(log2(DQS_WIDTH)).
     C0_RANK_WIDTH         : integer := 1;
                                     -- # = ceil(log2(RANKS)).
     C0_BANK_WIDTH         : integer := 3;
                                     -- # of memory Bank Address bits.
     C0_CK_WIDTH           : integer := 1;
                                     -- # of CK/CK# outputs to memory.
     C0_CKE_WIDTH          : integer := 1;
                                     -- # of CKE outputs to memory.
     C0_COL_WIDTH          : integer := 10;
                                     -- # of memory Column Address bits.
     C0_CS_WIDTH           : integer := 1;
                                     -- # of unique CS outputs to memory.
     C0_DM_WIDTH           : integer := 4;
                                     -- # of Data Mask bits.
     C0_DQ_WIDTH           : integer := 32;
                                     -- # of Data (DQ) bits.
     C0_DQS_WIDTH          : integer := 4;
                                     -- # of DQS/DQS# bits.
     C0_ROW_WIDTH          : integer := 13;
                                     -- # of memory Row Address bits.
     C0_BURST_MODE         : string := "OTF";
                                     -- Burst Length (Mode Register 0).
                                     -- # = "8", "4", "OTF".
     C0_BM_CNT_WIDTH       : integer := 2;
                                     -- # = ceil(log2(nBANK_MACHS)).
     C0_ADDR_CMD_MODE      : string := "1T" ;
                                     -- # = "2T", "1T".
     C0_ORDERING           : string := "NORM";
                                     -- # = "NORM", "STRICT", "RELAXED".
     C0_WRLVL              : string := "ON";
                                     -- # = "ON" - DDR3 SDRAM
                                     --   = "OFF" - DDR2 SDRAM.
     C0_PHASE_DETECT       : string := "ON";
                                     -- # = "ON", "OFF".
     C0_RTT_NOM            : string := "60";
                                     -- RTT_NOM (ODT) (Mode Register 1).
                                     -- # = "DISABLED" - RTT_NOM disabled,
                                     --   = "120" - RZQ/2,
                                     --   = "60"  - RZQ/4,
                                     --   = "40"  - RZQ/6.
     C0_RTT_WR             : string := "OFF";
                                     -- RTT_WR (ODT) (Mode Register 2).
                                     -- # = "OFF" - Dynamic ODT off,
                                     --   = "120" - RZQ/2,
                                     --   = "60"  - RZQ/4,
     C0_OUTPUT_DRV         : string := "HIGH";
                                     -- Output Driver Impedance Control (Mode Register 1).
                                     -- # = "HIGH" - RZQ/7,
                                     --   = "LOW" - RZQ/6.
     C0_REG_CTRL           : string := "OFF";
                                     -- # = "ON" - RDIMMs,
                                     --   = "OFF" - Components, SODIMMs, UDIMMs.
     C0_nDQS_COL0          : integer := 4;
                                     -- Number of DQS groups in I/O column #1.
     C0_nDQS_COL1          : integer := 0;
                                     -- Number of DQS groups in I/O column #2.
     C0_nDQS_COL2          : integer := 0;
                                     -- Number of DQS groups in I/O column #3.
     C0_nDQS_COL3          : integer := 0;
                                     -- Number of DQS groups in I/O column #4.
     C0_DQS_LOC_COL0       : std_logic_vector(31 downto 0) := X"03020100";
                                     -- DQS groups in column #1.
     C0_DQS_LOC_COL1       : std_logic_vector(0 downto 0) := "0";
                                     -- DQS groups in column #2.
     C0_DQS_LOC_COL2       : std_logic_vector(0 downto 0) := "0";
                                     -- DQS groups in column #3.
     C0_DQS_LOC_COL3       : std_logic_vector(0 downto 0) := "0";
                                     -- DQS groups in column #4.
     C0_tPRDI              : integer := 1000000;
                                     -- memory tPRDI paramter.
     C0_tREFI              : integer := 7800000;
                                     -- memory tREFI paramter.
     C0_tZQI               : integer := 128000000;
                                     -- memory tZQI paramter.
	 C0_ADDR_WIDTH            : integer := 27;
                                     -- # = RANK_WIDTH + BANK_WIDTH
                                     --     + ROW_WIDTH + COL_WIDTH;
     C0_ECC_TEST           : string := "OFF";
     C0_TCQ                : integer := 100;
     C0_DATA_WIDTH         : integer := 32;
     C0_PAYLOAD_WIDTH      : integer := 32;
   

     C1_DEBUG_PORT         : string := "OFF";
                                     -- # = "ON" Enable debug signals/controls.
                                     --   = "OFF" Disable debug signals/controls.
     C1_SIM_BYPASS_INIT_CAL : string := "OFF";
                                     -- # = "OFF" -  Complete memory init &
                                     --              calibration sequence
                                     -- # = "SKIP" - Skip memory init &
                                     --              calibration sequence
                                     -- # = "FAST" - Skip memory init & use
                                     --              abbreviated calib sequence
	 C1_SIM_INIT_OPTION       : string := "NONE";
                                     -- # = "SKIP_PU_DLY" - Skip the memory
                                     --                     initilization sequence,
                                     --   = "NONE" - Complete the memory
                                     --              initilization sequence.
     C1_SIM_CAL_OPTION     : string := "NONE";
                                     -- # = "FAST_CAL" - Skip the delay
                                     --                  Calibration process,
                                     --   = "NONE" - Complete the delay
                                     --              Calibration process.
     C1_nCS_PER_RANK       : integer := 1;
                                     -- # of unique CS outputs per Rank for
                                     -- phy.
     C1_DQS_CNT_WIDTH      : integer := 2;
                                     -- # = ceil(log2(DQS_WIDTH)).
     C1_RANK_WIDTH         : integer := 1;
                                     -- # = ceil(log2(RANKS)).
     C1_BANK_WIDTH         : integer := 3;
                                     -- # of memory Bank Address bits.
     C1_CK_WIDTH           : integer := 1;
                                     -- # of CK/CK# outputs to memory.
     C1_CKE_WIDTH          : integer := 1;
                                     -- # of CKE outputs to memory.
     C1_COL_WIDTH          : integer := 10;
                                     -- # of memory Column Address bits.
     C1_CS_WIDTH           : integer := 1;
                                     -- # of unique CS outputs to memory.
     C1_DM_WIDTH           : integer := 4;
                                     -- # of Data Mask bits.
     C1_DQ_WIDTH           : integer := 32;
                                     -- # of Data (DQ) bits.
     C1_DQS_WIDTH          : integer := 4;
                                     -- # of DQS/DQS# bits.
     C1_ROW_WIDTH          : integer := 13;
                                     -- # of memory Row Address bits.
     C1_BURST_MODE         : string := "OTF";
                                     -- Burst Length (Mode Register 0).
                                     -- # = "8", "4", "OTF".
     C1_BM_CNT_WIDTH       : integer := 2;
                                     -- # = ceil(log2(nBANK_MACHS)).
     C1_ADDR_CMD_MODE      : string := "1T" ;
                                     -- # = "2T", "1T".
     C1_ORDERING           : string := "NORM";
                                     -- # = "NORM", "STRICT", "RELAXED".
     C1_WRLVL              : string := "ON";
                                     -- # = "ON" - DDR3 SDRAM
                                     --   = "OFF" - DDR2 SDRAM.
     C1_PHASE_DETECT       : string := "ON";
                                     -- # = "ON", "OFF".
     C1_RTT_NOM            : string := "60";
                                     -- RTT_NOM (ODT) (Mode Register 1).
                                     -- # = "DISABLED" - RTT_NOM disabled,
                                     --   = "120" - RZQ/2,
                                     --   = "60"  - RZQ/4,
                                     --   = "40"  - RZQ/6.
     C1_RTT_WR             : string := "OFF";
                                     -- RTT_WR (ODT) (Mode Register 2).
                                     -- # = "OFF" - Dynamic ODT off,
                                     --   = "120" - RZQ/2,
                                     --   = "60"  - RZQ/4,
     C1_OUTPUT_DRV         : string := "HIGH";
                                     -- Output Driver Impedance Control (Mode Register 1).
                                     -- # = "HIGH" - RZQ/7,
                                     --   = "LOW" - RZQ/6.
     C1_REG_CTRL           : string := "OFF";
                                     -- # = "ON" - RDIMMs,
                                     --   = "OFF" - Components, SODIMMs, UDIMMs.
     C1_nDQS_COL0          : integer := 4;
                                     -- Number of DQS groups in I/O column #1.
     C1_nDQS_COL1          : integer := 0;
                                     -- Number of DQS groups in I/O column #2.
     C1_nDQS_COL2          : integer := 0;
                                     -- Number of DQS groups in I/O column #3.
     C1_nDQS_COL3          : integer := 0;
                                     -- Number of DQS groups in I/O column #4.
     C1_DQS_LOC_COL0       : std_logic_vector(31 downto 0) := X"03020100";
                                     -- DQS groups in column #1.
     C1_DQS_LOC_COL1       : std_logic_vector(0 downto 0) := "0";
                                     -- DQS groups in column #2.
     C1_DQS_LOC_COL2       : std_logic_vector(0 downto 0) := "0";
                                     -- DQS groups in column #3.
     C1_DQS_LOC_COL3       : std_logic_vector(0 downto 0) := "0";
                                     -- DQS groups in column #4.
     C1_tPRDI              : integer := 1000000;
                                     -- memory tPRDI paramter.
     C1_tREFI              : integer := 7800000;
                                     -- memory tREFI paramter.
     C1_tZQI               : integer := 128000000;
                                     -- memory tZQI paramter.
	 C1_ADDR_WIDTH            : integer := 27;
                                     -- # = RANK_WIDTH + BANK_WIDTH
                                     --     + ROW_WIDTH + COL_WIDTH;
     C1_ECC_TEST           : string := "OFF";
     C1_TCQ                : integer := 100;
     C1_DATA_WIDTH         : integer := 32;
     C1_PAYLOAD_WIDTH      : integer := 32;
   

     C2_DEBUG_PORT         : string := "OFF";
                                     -- # = "ON" Enable debug signals/controls.
                                     --   = "OFF" Disable debug signals/controls.
     C2_SIM_BYPASS_INIT_CAL : string := "OFF";
                                     -- # = "OFF" -  Complete memory init &
                                     --              calibration sequence
                                     -- # = "SKIP" - Skip memory init &
                                     --              calibration sequence
                                     -- # = "FAST" - Skip memory init & use
                                     --              abbreviated calib sequence
	 C2_SIM_INIT_OPTION       : string := "NONE";
                                     -- # = "SKIP_PU_DLY" - Skip the memory
                                     --                     initilization sequence,
                                     --   = "NONE" - Complete the memory
                                     --              initilization sequence.
     C2_SIM_CAL_OPTION     : string := "NONE";
                                     -- # = "FAST_CAL" - Skip the delay
                                     --                  Calibration process,
                                     --   = "NONE" - Complete the delay
                                     --              Calibration process.
     C2_nCS_PER_RANK       : integer := 1;
                                     -- # of unique CS outputs per Rank for
                                     -- phy.
     C2_DQS_CNT_WIDTH      : integer := 2;
                                     -- # = ceil(log2(DQS_WIDTH)).
     C2_RANK_WIDTH         : integer := 1;
                                     -- # = ceil(log2(RANKS)).
     C2_BANK_WIDTH         : integer := 3;
                                     -- # of memory Bank Address bits.
     C2_CK_WIDTH           : integer := 1;
                                     -- # of CK/CK# outputs to memory.
     C2_CKE_WIDTH          : integer := 1;
                                     -- # of CKE outputs to memory.
     C2_COL_WIDTH          : integer := 10;
                                     -- # of memory Column Address bits.
     C2_CS_WIDTH           : integer := 1;
                                     -- # of unique CS outputs to memory.
     C2_DM_WIDTH           : integer := 4;
                                     -- # of Data Mask bits.
     C2_DQ_WIDTH           : integer := 32;
                                     -- # of Data (DQ) bits.
     C2_DQS_WIDTH          : integer := 4;
                                     -- # of DQS/DQS# bits.
     C2_ROW_WIDTH          : integer := 13;
                                     -- # of memory Row Address bits.
     C2_BURST_MODE         : string := "OTF";
                                     -- Burst Length (Mode Register 0).
                                     -- # = "8", "4", "OTF".
     C2_BM_CNT_WIDTH       : integer := 2;
                                     -- # = ceil(log2(nBANK_MACHS)).
     C2_ADDR_CMD_MODE      : string := "1T" ;
                                     -- # = "2T", "1T".
     C2_ORDERING           : string := "NORM";
                                     -- # = "NORM", "STRICT", "RELAXED".
     C2_WRLVL              : string := "ON";
                                     -- # = "ON" - DDR3 SDRAM
                                     --   = "OFF" - DDR2 SDRAM.
     C2_PHASE_DETECT       : string := "ON";
                                     -- # = "ON", "OFF".
     C2_RTT_NOM            : string := "60";
                                     -- RTT_NOM (ODT) (Mode Register 1).
                                     -- # = "DISABLED" - RTT_NOM disabled,
                                     --   = "120" - RZQ/2,
                                     --   = "60"  - RZQ/4,
                                     --   = "40"  - RZQ/6.
     C2_RTT_WR             : string := "OFF";
                                     -- RTT_WR (ODT) (Mode Register 2).
                                     -- # = "OFF" - Dynamic ODT off,
                                     --   = "120" - RZQ/2,
                                     --   = "60"  - RZQ/4,
     C2_OUTPUT_DRV         : string := "HIGH";
                                     -- Output Driver Impedance Control (Mode Register 1).
                                     -- # = "HIGH" - RZQ/7,
                                     --   = "LOW" - RZQ/6.
     C2_REG_CTRL           : string := "OFF";
                                     -- # = "ON" - RDIMMs,
                                     --   = "OFF" - Components, SODIMMs, UDIMMs.
     C2_nDQS_COL0          : integer := 0;
                                     -- Number of DQS groups in I/O column #1.
     C2_nDQS_COL1          : integer := 0;
                                     -- Number of DQS groups in I/O column #2.
     C2_nDQS_COL2          : integer := 4;
                                     -- Number of DQS groups in I/O column #3.
     C2_nDQS_COL3          : integer := 0;
                                     -- Number of DQS groups in I/O column #4.
     C2_DQS_LOC_COL0       : std_logic_vector(0 downto 0) := "0";
                                     -- DQS groups in column #1.
     C2_DQS_LOC_COL1       : std_logic_vector(0 downto 0) := "0";
                                     -- DQS groups in column #2.
     C2_DQS_LOC_COL2       : std_logic_vector(31 downto 0) := X"03020100";
                                     -- DQS groups in column #3.
     C2_DQS_LOC_COL3       : std_logic_vector(0 downto 0) := "0";
                                     -- DQS groups in column #4.
     C2_tPRDI              : integer := 1000000;
                                     -- memory tPRDI paramter.
     C2_tREFI              : integer := 7800000;
                                     -- memory tREFI paramter.
     C2_tZQI               : integer := 128000000;
                                     -- memory tZQI paramter.
	 C2_ADDR_WIDTH            : integer := 27;
                                     -- # = RANK_WIDTH + BANK_WIDTH
                                     --     + ROW_WIDTH + COL_WIDTH;
     C2_ECC_TEST           : string := "OFF";
     C2_TCQ                : integer := 100;
     C2_DATA_WIDTH         : integer := 32;
     C2_PAYLOAD_WIDTH      : integer := 32;
   

     C3_DEBUG_PORT         : string := "OFF";
                                     -- # = "ON" Enable debug signals/controls.
                                     --   = "OFF" Disable debug signals/controls.
     C3_SIM_BYPASS_INIT_CAL : string := "OFF";
                                     -- # = "OFF" -  Complete memory init &
                                     --              calibration sequence
                                     -- # = "SKIP" - Skip memory init &
                                     --              calibration sequence
                                     -- # = "FAST" - Skip memory init & use
                                     --              abbreviated calib sequence
	 C3_SIM_INIT_OPTION       : string := "NONE";
                                     -- # = "SKIP_PU_DLY" - Skip the memory
                                     --                     initilization sequence,
                                     --   = "NONE" - Complete the memory
                                     --              initilization sequence.
     C3_SIM_CAL_OPTION     : string := "NONE";
                                     -- # = "FAST_CAL" - Skip the delay
                                     --                  Calibration process,
                                     --   = "NONE" - Complete the delay
                                     --              Calibration process.
     C3_nCS_PER_RANK       : integer := 1;
                                     -- # of unique CS outputs per Rank for
                                     -- phy.
     C3_DQS_CNT_WIDTH      : integer := 2;
                                     -- # = ceil(log2(DQS_WIDTH)).
     C3_RANK_WIDTH         : integer := 1;
                                     -- # = ceil(log2(RANKS)).
     C3_BANK_WIDTH         : integer := 3;
                                     -- # of memory Bank Address bits.
     C3_CK_WIDTH           : integer := 1;
                                     -- # of CK/CK# outputs to memory.
     C3_CKE_WIDTH          : integer := 1;
                                     -- # of CKE outputs to memory.
     C3_COL_WIDTH          : integer := 10;
                                     -- # of memory Column Address bits.
     C3_CS_WIDTH           : integer := 1;
                                     -- # of unique CS outputs to memory.
     C3_DM_WIDTH           : integer := 4;
                                     -- # of Data Mask bits.
     C3_DQ_WIDTH           : integer := 32;
                                     -- # of Data (DQ) bits.
     C3_DQS_WIDTH          : integer := 4;
                                     -- # of DQS/DQS# bits.
     C3_ROW_WIDTH          : integer := 13;
                                     -- # of memory Row Address bits.
     C3_BURST_MODE         : string := "OTF";
                                     -- Burst Length (Mode Register 0).
                                     -- # = "8", "4", "OTF".
     C3_BM_CNT_WIDTH       : integer := 2;
                                     -- # = ceil(log2(nBANK_MACHS)).
     C3_ADDR_CMD_MODE      : string := "1T" ;
                                     -- # = "2T", "1T".
     C3_ORDERING           : string := "NORM";
                                     -- # = "NORM", "STRICT", "RELAXED".
     C3_WRLVL              : string := "ON";
                                     -- # = "ON" - DDR3 SDRAM
                                     --   = "OFF" - DDR2 SDRAM.
     C3_PHASE_DETECT       : string := "ON";
                                     -- # = "ON", "OFF".
     C3_RTT_NOM            : string := "60";
                                     -- RTT_NOM (ODT) (Mode Register 1).
                                     -- # = "DISABLED" - RTT_NOM disabled,
                                     --   = "120" - RZQ/2,
                                     --   = "60"  - RZQ/4,
                                     --   = "40"  - RZQ/6.
     C3_RTT_WR             : string := "OFF";
                                     -- RTT_WR (ODT) (Mode Register 2).
                                     -- # = "OFF" - Dynamic ODT off,
                                     --   = "120" - RZQ/2,
                                     --   = "60"  - RZQ/4,
     C3_OUTPUT_DRV         : string := "HIGH";
                                     -- Output Driver Impedance Control (Mode Register 1).
                                     -- # = "HIGH" - RZQ/7,
                                     --   = "LOW" - RZQ/6.
     C3_REG_CTRL           : string := "OFF";
                                     -- # = "ON" - RDIMMs,
                                     --   = "OFF" - Components, SODIMMs, UDIMMs.
     C3_nDQS_COL0          : integer := 2;
                                     -- Number of DQS groups in I/O column #1.
     C3_nDQS_COL1          : integer := 2;
                                     -- Number of DQS groups in I/O column #2.
     C3_nDQS_COL2          : integer := 0;
                                     -- Number of DQS groups in I/O column #3.
     C3_nDQS_COL3          : integer := 0;
                                     -- Number of DQS groups in I/O column #4.
     C3_DQS_LOC_COL0       : std_logic_vector(15 downto 0) := X"0100";
                                     -- DQS groups in column #1.
     C3_DQS_LOC_COL1       : std_logic_vector(15 downto 0) := X"0302";
                                     -- DQS groups in column #2.
     C3_DQS_LOC_COL2       : std_logic_vector(0 downto 0) := "0";
                                     -- DQS groups in column #3.
     C3_DQS_LOC_COL3       : std_logic_vector(0 downto 0) := "0";
                                     -- DQS groups in column #4.
     C3_tPRDI              : integer := 1000000;
                                     -- memory tPRDI paramter.
     C3_tREFI              : integer := 7800000;
                                     -- memory tREFI paramter.
     C3_tZQI               : integer := 128000000;
                                     -- memory tZQI paramter.
	 C3_ADDR_WIDTH            : integer := 27;
                                     -- # = RANK_WIDTH + BANK_WIDTH
                                     --     + ROW_WIDTH + COL_WIDTH;
     C3_ECC_TEST           : string := "OFF";
     C3_TCQ                : integer := 100;
     C3_DATA_WIDTH         : integer := 32;
     C3_PAYLOAD_WIDTH      : integer := 32;
   
    RST_ACT_LOW             : integer := 1;
                                       -- =1 for active low reset,
                                       -- =0 for active high.
    INPUT_CLK_TYPE          : string  := "SINGLE_ENDED";
                                       -- input clock type DIFFERENTIAL or SINGLE_ENDED
    STARVE_LIMIT            : integer := 2
                                       -- # = 2,3,4.
    );
  port(

      sys_clk_f0    : in    std_logic;
      clk200_ref    : in    std_logic;
      c0_ddr3_dq    : inout std_logic_vector(C0_DQ_WIDTH-1 downto 0);
      c0_ddr3_dm    : out   std_logic_vector(C0_DM_WIDTH-1 downto 0);
      c0_ddr3_addr  : out   std_logic_vector(C0_ROW_WIDTH-1 downto 0);
      c0_ddr3_ba    : out   std_logic_vector(C0_BANK_WIDTH-1 downto 0);
      c0_ddr3_ras_n : out   std_logic;
      c0_ddr3_cas_n : out   std_logic;
      c0_ddr3_we_n  : out   std_logic;
      c0_ddr3_reset_n : out   std_logic;
      c0_ddr3_cs_n  : out   std_logic_vector((C0_CS_WIDTH*C0_nCS_PER_RANK)-1 downto 0);
      c0_ddr3_odt   : out   std_logic_vector((C0_CS_WIDTH*C0_nCS_PER_RANK)-1 downto 0);
      c0_ddr3_cke   : out   std_logic_vector(C0_CKE_WIDTH-1 downto 0);
      c0_ddr3_dqs_p : inout std_logic_vector(C0_DQS_WIDTH-1 downto 0);
      c0_ddr3_dqs_n : inout std_logic_vector(C0_DQS_WIDTH-1 downto 0);
      c0_ddr3_ck_p  : out   std_logic_vector(C0_CK_WIDTH-1 downto 0);
      c0_ddr3_ck_n  : out   std_logic_vector(C0_CK_WIDTH-1 downto 0);
      c0_app_wdf_wren : in    std_logic;
      c0_app_wdf_data : in    std_logic_vector((4*C0_PAYLOAD_WIDTH)-1 downto 0);
      c0_app_wdf_mask : in    std_logic_vector((4*C0_PAYLOAD_WIDTH)/8-1 downto 0);
      c0_app_wdf_end : in    std_logic;
      c0_app_addr   : in    std_logic_vector(C0_ADDR_WIDTH-1 downto 0);
      c0_app_cmd    : in    std_logic_vector(2 downto 0);
      c0_app_en     : in    std_logic;
      c0_app_rdy    : out   std_logic;
      c0_app_wdf_rdy : out   std_logic;
      c0_app_rd_data : out   std_logic_vector((4*C0_PAYLOAD_WIDTH)-1 downto 0);
      c0_app_rd_data_valid : out   std_logic;
      c0_tb_rst     : out   std_logic;
      c0_tb_clk     : out   std_logic;
      c0_phy_init_done : out   std_logic;


      c1_ddr3_dq    : inout std_logic_vector(C1_DQ_WIDTH-1 downto 0);
      c1_ddr3_dm    : out   std_logic_vector(C1_DM_WIDTH-1 downto 0);
      c1_ddr3_addr  : out   std_logic_vector(C1_ROW_WIDTH-1 downto 0);
      c1_ddr3_ba    : out   std_logic_vector(C1_BANK_WIDTH-1 downto 0);
      c1_ddr3_ras_n : out   std_logic;
      c1_ddr3_cas_n : out   std_logic;
      c1_ddr3_we_n  : out   std_logic;
      c1_ddr3_reset_n : out   std_logic;
      c1_ddr3_cs_n  : out   std_logic_vector((C1_CS_WIDTH*C1_nCS_PER_RANK)-1 downto 0);
      c1_ddr3_odt   : out   std_logic_vector((C1_CS_WIDTH*C1_nCS_PER_RANK)-1 downto 0);
      c1_ddr3_cke   : out   std_logic_vector(C1_CKE_WIDTH-1 downto 0);
      c1_ddr3_dqs_p : inout std_logic_vector(C1_DQS_WIDTH-1 downto 0);
      c1_ddr3_dqs_n : inout std_logic_vector(C1_DQS_WIDTH-1 downto 0);
      c1_ddr3_ck_p  : out   std_logic_vector(C1_CK_WIDTH-1 downto 0);
      c1_ddr3_ck_n  : out   std_logic_vector(C1_CK_WIDTH-1 downto 0);
      c1_app_wdf_wren : in    std_logic;
      c1_app_wdf_data : in    std_logic_vector((4*C1_PAYLOAD_WIDTH)-1 downto 0);
      c1_app_wdf_mask : in    std_logic_vector((4*C1_PAYLOAD_WIDTH)/8-1 downto 0);
      c1_app_wdf_end : in    std_logic;
      c1_app_addr   : in    std_logic_vector(C1_ADDR_WIDTH-1 downto 0);
      c1_app_cmd    : in    std_logic_vector(2 downto 0);
      c1_app_en     : in    std_logic;
      c1_app_rdy    : out   std_logic;
      c1_app_wdf_rdy : out   std_logic;
      c1_app_rd_data : out   std_logic_vector((4*C1_PAYLOAD_WIDTH)-1 downto 0);
      c1_app_rd_data_valid : out   std_logic;
      c1_tb_rst     : out   std_logic;
      c1_tb_clk     : out   std_logic;
      c1_phy_init_done : out   std_logic;


      c2_ddr3_dq    : inout std_logic_vector(C2_DQ_WIDTH-1 downto 0);
      c2_ddr3_dm    : out   std_logic_vector(C2_DM_WIDTH-1 downto 0);
      c2_ddr3_addr  : out   std_logic_vector(C2_ROW_WIDTH-1 downto 0);
      c2_ddr3_ba    : out   std_logic_vector(C2_BANK_WIDTH-1 downto 0);
      c2_ddr3_ras_n : out   std_logic;
      c2_ddr3_cas_n : out   std_logic;
      c2_ddr3_we_n  : out   std_logic;
      c2_ddr3_reset_n : out   std_logic;
      c2_ddr3_cs_n  : out   std_logic_vector((C2_CS_WIDTH*C2_nCS_PER_RANK)-1 downto 0);
      c2_ddr3_odt   : out   std_logic_vector((C2_CS_WIDTH*C2_nCS_PER_RANK)-1 downto 0);
      c2_ddr3_cke   : out   std_logic_vector(C2_CKE_WIDTH-1 downto 0);
      c2_ddr3_dqs_p : inout std_logic_vector(C2_DQS_WIDTH-1 downto 0);
      c2_ddr3_dqs_n : inout std_logic_vector(C2_DQS_WIDTH-1 downto 0);
      c2_ddr3_ck_p  : out   std_logic_vector(C2_CK_WIDTH-1 downto 0);
      c2_ddr3_ck_n  : out   std_logic_vector(C2_CK_WIDTH-1 downto 0);
      c2_app_wdf_wren : in    std_logic;
      c2_app_wdf_data : in    std_logic_vector((4*C2_PAYLOAD_WIDTH)-1 downto 0);
      c2_app_wdf_mask : in    std_logic_vector((4*C2_PAYLOAD_WIDTH)/8-1 downto 0);
      c2_app_wdf_end : in    std_logic;
      c2_app_addr   : in    std_logic_vector(C2_ADDR_WIDTH-1 downto 0);
      c2_app_cmd    : in    std_logic_vector(2 downto 0);
      c2_app_en     : in    std_logic;
      c2_app_rdy    : out   std_logic;
      c2_app_wdf_rdy : out   std_logic;
      c2_app_rd_data : out   std_logic_vector((4*C2_PAYLOAD_WIDTH)-1 downto 0);
      c2_app_rd_data_valid : out   std_logic;
      c2_tb_rst     : out   std_logic;
      c2_tb_clk     : out   std_logic;
      c2_phy_init_done : out   std_logic;


      c3_ddr3_dq    : inout std_logic_vector(C3_DQ_WIDTH-1 downto 0);
      c3_ddr3_dm    : out   std_logic_vector(C3_DM_WIDTH-1 downto 0);
      c3_ddr3_addr  : out   std_logic_vector(C3_ROW_WIDTH-1 downto 0);
      c3_ddr3_ba    : out   std_logic_vector(C3_BANK_WIDTH-1 downto 0);
      c3_ddr3_ras_n : out   std_logic;
      c3_ddr3_cas_n : out   std_logic;
      c3_ddr3_we_n  : out   std_logic;
      c3_ddr3_reset_n : out   std_logic;
      c3_ddr3_cs_n  : out   std_logic_vector((C3_CS_WIDTH*C3_nCS_PER_RANK)-1 downto 0);
      c3_ddr3_odt   : out   std_logic_vector((C3_CS_WIDTH*C3_nCS_PER_RANK)-1 downto 0);
      c3_ddr3_cke   : out   std_logic_vector(C3_CKE_WIDTH-1 downto 0);
      c3_ddr3_dqs_p : inout std_logic_vector(C3_DQS_WIDTH-1 downto 0);
      c3_ddr3_dqs_n : inout std_logic_vector(C3_DQS_WIDTH-1 downto 0);
      c3_ddr3_ck_p  : out   std_logic_vector(C3_CK_WIDTH-1 downto 0);
      c3_ddr3_ck_n  : out   std_logic_vector(C3_CK_WIDTH-1 downto 0);
      c3_app_wdf_wren : in    std_logic;
      c3_app_wdf_data : in    std_logic_vector((4*C3_PAYLOAD_WIDTH)-1 downto 0);
      c3_app_wdf_mask : in    std_logic_vector((4*C3_PAYLOAD_WIDTH)/8-1 downto 0);
      c3_app_wdf_end : in    std_logic;
      c3_app_addr   : in    std_logic_vector(C3_ADDR_WIDTH-1 downto 0);
      c3_app_cmd    : in    std_logic_vector(2 downto 0);
      c3_app_en     : in    std_logic;
      c3_app_rdy    : out   std_logic;
      c3_app_wdf_rdy : out   std_logic;
      c3_app_rd_data : out   std_logic_vector((4*C3_PAYLOAD_WIDTH)-1 downto 0);
      c3_app_rd_data_valid : out   std_logic;
      c3_tb_rst     : out   std_logic;
      c3_tb_clk     : out   std_logic;
      c3_phy_init_done : out   std_logic;

    sys_rst        : in std_logic
    );
end entity mig_v3_6;

architecture arch_mig_v3_6 of mig_v3_6 is






  constant SYSCLK_f0_PERIOD : integer := tCK_f0 * nCK_PER_CLK_f0;

  constant C0_APP_DATA_WIDTH : integer := C0_PAYLOAD_WIDTH * 4;
  constant C0_APP_MASK_WIDTH : integer := C0_APP_DATA_WIDTH / 8;

  constant C1_APP_DATA_WIDTH : integer := C1_PAYLOAD_WIDTH * 4;
  constant C1_APP_MASK_WIDTH : integer := C1_APP_DATA_WIDTH / 8;

  constant C2_APP_DATA_WIDTH : integer := C2_PAYLOAD_WIDTH * 4;
  constant C2_APP_MASK_WIDTH : integer := C2_APP_DATA_WIDTH / 8;

  constant C3_APP_DATA_WIDTH : integer := C3_PAYLOAD_WIDTH * 4;
  constant C3_APP_MASK_WIDTH : integer := C3_APP_DATA_WIDTH / 8;

  component clk_ibuf
    generic (
      INPUT_CLK_TYPE : string
      );
    port (
      sys_clk_p : in  std_logic;
      sys_clk_n : in  std_logic;
      sys_clk   : in  std_logic;
      mmcm_clk  : out std_logic
      );
  end component;

  component iodelay_ctrl
    generic (
      TCQ            : integer;
      IODELAY_GRP    : string;
      INPUT_CLK_TYPE : string;
      RST_ACT_LOW    : integer
      );
    port (
      clk_ref_p        : in  std_logic;
      clk_ref_n        : in  std_logic;
      clk_ref          : in  std_logic;
      sys_rst          : in  std_logic;
      iodelay_ctrl_rdy : out std_logic
      );
  end component iodelay_ctrl;

  component infrastructure
    generic (
     TCQ             : integer;
     CLK_PERIOD      : integer;
     nCK_PER_CLK     : integer;
     CLKFBOUT_MULT_F : integer;
     DIVCLK_DIVIDE   : integer;
     CLKOUT_DIVIDE   : integer;
     RST_ACT_LOW     : integer
     );
    port (
     clk_mem          : out std_logic;
     clk              : out std_logic;
     clk_rd_base      : out std_logic;
     rstdiv0          : out std_logic;
     mmcm_clk         : in  std_logic;
     sys_rst          : in  std_logic;
     iodelay_ctrl_rdy : in  std_logic;
     PSDONE           : out std_logic;
     PSEN             : in  std_logic;
     PSINCDEC         : in  std_logic
     );
  end component infrastructure;

  component c0_memc_ui_top
    generic(
      REFCLK_FREQ           : real;
      SIM_BYPASS_INIT_CAL   : string;
      SIM_INIT_OPTION       : string;
      SIM_CAL_OPTION        : string;
      IODELAY_GRP           : string;
      nCK_PER_CLK           : integer;
      nCS_PER_RANK          : integer;
      DQS_CNT_WIDTH         : integer;
      RANK_WIDTH            : integer;
      BANK_WIDTH            : integer;
      CK_WIDTH              : integer;
      CKE_WIDTH             : integer;
      COL_WIDTH             : integer;
      CS_WIDTH              : integer;
      DQ_WIDTH              : integer;
      DM_WIDTH              : integer;
      DQS_WIDTH             : integer;
      ROW_WIDTH             : integer;
      BURST_MODE            : string;
      BM_CNT_WIDTH          : integer;
      ADDR_CMD_MODE         : string;
      ORDERING              : string;
      WRLVL                 : string;
      PHASE_DETECT          : string;
      RTT_NOM               : string;
      RTT_WR                : string;
      OUTPUT_DRV            : string;
      REG_CTRL              : string;
      nDQS_COL0             : integer;
      nDQS_COL1             : integer;
      nDQS_COL2             : integer;
      nDQS_COL3             : integer;
      DQS_LOC_COL0          : std_logic_vector(31 downto 0);
      DQS_LOC_COL1          : std_logic_vector(0 downto 0);
      DQS_LOC_COL2          : std_logic_vector(0 downto 0);
      DQS_LOC_COL3          : std_logic_vector(0 downto 0);
      tCK                   : integer;
      DEBUG_PORT            : string;
      tPRDI                 : integer;
      tREFI                 : integer;
      tZQI                  : integer;
      ADDR_WIDTH            : integer;
      TCQ                   : integer;
      ECC_TEST              : string;
      PAYLOAD_WIDTH         : integer
      );
    port(
      clk                       : in    std_logic;
      clk_mem                   : in    std_logic;
      clk_rd_base               : in    std_logic;
      rst                       : in    std_logic;
      ddr_addr                  : out   std_logic_vector(ROW_WIDTH-1 downto 0);
      ddr_ba                    : out   std_logic_vector(BANK_WIDTH-1 downto 0);
      ddr_cas_n                 : out   std_logic;
      ddr_ck_n                  : out   std_logic_vector(CK_WIDTH-1 downto 0);
      ddr_ck                    : out   std_logic_vector(CK_WIDTH-1 downto 0);
      ddr_cke                   : out   std_logic_vector(CKE_WIDTH-1 downto 0);
      ddr_cs_n                  : out   std_logic_vector(CS_WIDTH*nCS_PER_RANK-1 downto 0);
      ddr_dm                    : out   std_logic_vector(DM_WIDTH-1 downto 0);
      ddr_odt                   : out   std_logic_vector(CS_WIDTH*nCS_PER_RANK-1 downto 0);
      ddr_ras_n                 : out   std_logic;
      ddr_reset_n               : out   std_logic;
      ddr_parity                : out   std_logic;
      ddr_we_n                  : out   std_logic;
      ddr_dq                    : inout std_logic_vector(DQ_WIDTH-1 downto 0);
      ddr_dqs_n                 : inout std_logic_vector(DQS_WIDTH-1 downto 0);
      ddr_dqs                   : inout std_logic_vector(DQS_WIDTH-1 downto 0);
      pd_PSEN                   : out   std_logic;
      pd_PSINCDEC               : out   std_logic;
      pd_PSDONE                 : in    std_logic;
      dfi_init_complete         : out   std_logic;
      bank_mach_next            : out   std_logic_vector(BM_CNT_WIDTH-1 downto 0);
      app_ecc_multiple_err      : out   std_logic_vector(3 downto 0);
      app_rd_data               : out   std_logic_vector((PAYLOAD_WIDTH*4)-1 downto 0);
      app_rd_data_end           : out   std_logic;
      app_rd_data_valid         : out   std_logic;
      app_rdy                   : out   std_logic;
      app_wdf_rdy               : out   std_logic;
      app_addr                  : in    std_logic_vector(ADDR_WIDTH-1 downto 0);
      app_cmd                   : in    std_logic_vector(2 downto 0);
      app_en                    : in    std_logic;
      app_hi_pri                : in    std_logic;
      app_sz                    : in    std_logic;
      app_wdf_data              : in    std_logic_vector((PAYLOAD_WIDTH*4)-1 downto 0);
      app_wdf_end               : in    std_logic;
      app_wdf_mask              : in    std_logic_vector((PAYLOAD_WIDTH/2)-1 downto 0);
      app_wdf_wren              : in    std_logic;
      dbg_wr_dq_tap_set         : in    std_logic_vector(5*DQS_WIDTH-1 downto 0);
      dbg_wr_dqs_tap_set        : in    std_logic_vector(5*DQS_WIDTH-1 downto 0);       
      dbg_wr_tap_set_en         : in    std_logic;
      dbg_wrlvl_start           : out   std_logic;  
      dbg_wrlvl_done            : out   std_logic;  
      dbg_wrlvl_err             : out   std_logic;  
      dbg_wl_dqs_inverted       : out   std_logic_vector(DQS_WIDTH-1 downto 0);
      dbg_wr_calib_clk_delay    : out   std_logic_vector(2*DQS_WIDTH-1 downto 0);
      dbg_wl_odelay_dqs_tap_cnt : out   std_logic_vector(5*DQS_WIDTH-1 downto 0);
      dbg_wl_odelay_dq_tap_cnt  : out   std_logic_vector(5*DQS_WIDTH-1 downto 0);
      dbg_rdlvl_start           : out   std_logic_vector(1 downto 0);  
      dbg_rdlvl_done            : out   std_logic_vector(1 downto 0);
      dbg_rdlvl_err             : out   std_logic_vector(1 downto 0);
      dbg_cpt_tap_cnt           : out   std_logic_vector(5*DQS_WIDTH-1 downto 0);
      dbg_cpt_first_edge_cnt    : out   std_logic_vector(5*DQS_WIDTH-1 downto 0);
      dbg_cpt_second_edge_cnt   : out   std_logic_vector(5*DQS_WIDTH-1 downto 0);
      dbg_rd_bitslip_cnt        : out   std_logic_vector(3*DQS_WIDTH-1 downto 0);
      dbg_rd_clkdly_cnt         : out   std_logic_vector(2*DQS_WIDTH-1 downto 0);
      dbg_rd_active_dly         : out   std_logic_vector(4 downto 0);
      dbg_pd_off                : in    std_logic;
      dbg_pd_maintain_off       : in    std_logic;
      dbg_pd_maintain_0_only    : in    std_logic;
      dbg_inc_cpt               : in    std_logic;
      dbg_dec_cpt               : in    std_logic;
      dbg_inc_rd_dqs            : in    std_logic;
      dbg_dec_rd_dqs            : in    std_logic;
      dbg_inc_dec_sel           : in    std_logic_vector(DQS_CNT_WIDTH-1 downto 0);
      dbg_inc_rd_fps            : in    std_logic;
      dbg_dec_rd_fps            : in    std_logic;
      dbg_dqs_tap_cnt           : out   std_logic_vector(5*DQS_WIDTH-1 downto 0);
      dbg_dq_tap_cnt            : out   std_logic_vector(5*DQS_WIDTH-1 downto 0);
      dbg_rddata                : out   std_logic_vector(4*DQ_WIDTH-1 downto 0)
     );
  end component c0_memc_ui_top;

  component c1_memc_ui_top
    generic(
      REFCLK_FREQ           : real;
      SIM_BYPASS_INIT_CAL   : string;
      SIM_INIT_OPTION       : string;
      SIM_CAL_OPTION        : string;
      IODELAY_GRP           : string;
      nCK_PER_CLK           : integer;
      nCS_PER_RANK          : integer;
      DQS_CNT_WIDTH         : integer;
      RANK_WIDTH            : integer;
      BANK_WIDTH            : integer;
      CK_WIDTH              : integer;
      CKE_WIDTH             : integer;
      COL_WIDTH             : integer;
      CS_WIDTH              : integer;
      DQ_WIDTH              : integer;
      DM_WIDTH              : integer;
      DQS_WIDTH             : integer;
      ROW_WIDTH             : integer;
      BURST_MODE            : string;
      BM_CNT_WIDTH          : integer;
      ADDR_CMD_MODE         : string;
      ORDERING              : string;
      WRLVL                 : string;
      PHASE_DETECT          : string;
      RTT_NOM               : string;
      RTT_WR                : string;
      OUTPUT_DRV            : string;
      REG_CTRL              : string;
      nDQS_COL0             : integer;
      nDQS_COL1             : integer;
      nDQS_COL2             : integer;
      nDQS_COL3             : integer;
      DQS_LOC_COL0          : std_logic_vector(31 downto 0);
      DQS_LOC_COL1          : std_logic_vector(0 downto 0);
      DQS_LOC_COL2          : std_logic_vector(0 downto 0);
      DQS_LOC_COL3          : std_logic_vector(0 downto 0);
      tCK                   : integer;
      DEBUG_PORT            : string;
      tPRDI                 : integer;
      tREFI                 : integer;
      tZQI                  : integer;
      ADDR_WIDTH            : integer;
      TCQ                   : integer;
      ECC_TEST              : string;
      PAYLOAD_WIDTH         : integer
      );
    port(
      clk                       : in    std_logic;
      clk_mem                   : in    std_logic;
      clk_rd_base               : in    std_logic;
      rst                       : in    std_logic;
      ddr_addr                  : out   std_logic_vector(ROW_WIDTH-1 downto 0);
      ddr_ba                    : out   std_logic_vector(BANK_WIDTH-1 downto 0);
      ddr_cas_n                 : out   std_logic;
      ddr_ck_n                  : out   std_logic_vector(CK_WIDTH-1 downto 0);
      ddr_ck                    : out   std_logic_vector(CK_WIDTH-1 downto 0);
      ddr_cke                   : out   std_logic_vector(CKE_WIDTH-1 downto 0);
      ddr_cs_n                  : out   std_logic_vector(CS_WIDTH*nCS_PER_RANK-1 downto 0);
      ddr_dm                    : out   std_logic_vector(DM_WIDTH-1 downto 0);
      ddr_odt                   : out   std_logic_vector(CS_WIDTH*nCS_PER_RANK-1 downto 0);
      ddr_ras_n                 : out   std_logic;
      ddr_reset_n               : out   std_logic;
      ddr_parity                : out   std_logic;
      ddr_we_n                  : out   std_logic;
      ddr_dq                    : inout std_logic_vector(DQ_WIDTH-1 downto 0);
      ddr_dqs_n                 : inout std_logic_vector(DQS_WIDTH-1 downto 0);
      ddr_dqs                   : inout std_logic_vector(DQS_WIDTH-1 downto 0);
      pd_PSEN                   : out   std_logic;
      pd_PSINCDEC               : out   std_logic;
      pd_PSDONE                 : in    std_logic;
      dfi_init_complete         : out   std_logic;
      bank_mach_next            : out   std_logic_vector(BM_CNT_WIDTH-1 downto 0);
      app_ecc_multiple_err      : out   std_logic_vector(3 downto 0);
      app_rd_data               : out   std_logic_vector((PAYLOAD_WIDTH*4)-1 downto 0);
      app_rd_data_end           : out   std_logic;
      app_rd_data_valid         : out   std_logic;
      app_rdy                   : out   std_logic;
      app_wdf_rdy               : out   std_logic;
      app_addr                  : in    std_logic_vector(ADDR_WIDTH-1 downto 0);
      app_cmd                   : in    std_logic_vector(2 downto 0);
      app_en                    : in    std_logic;
      app_hi_pri                : in    std_logic;
      app_sz                    : in    std_logic;
      app_wdf_data              : in    std_logic_vector((PAYLOAD_WIDTH*4)-1 downto 0);
      app_wdf_end               : in    std_logic;
      app_wdf_mask              : in    std_logic_vector((PAYLOAD_WIDTH/2)-1 downto 0);
      app_wdf_wren              : in    std_logic;
      dbg_wr_dq_tap_set         : in    std_logic_vector(5*DQS_WIDTH-1 downto 0);
      dbg_wr_dqs_tap_set        : in    std_logic_vector(5*DQS_WIDTH-1 downto 0);       
      dbg_wr_tap_set_en         : in    std_logic;
      dbg_wrlvl_start           : out   std_logic;  
      dbg_wrlvl_done            : out   std_logic;  
      dbg_wrlvl_err             : out   std_logic;  
      dbg_wl_dqs_inverted       : out   std_logic_vector(DQS_WIDTH-1 downto 0);
      dbg_wr_calib_clk_delay    : out   std_logic_vector(2*DQS_WIDTH-1 downto 0);
      dbg_wl_odelay_dqs_tap_cnt : out   std_logic_vector(5*DQS_WIDTH-1 downto 0);
      dbg_wl_odelay_dq_tap_cnt  : out   std_logic_vector(5*DQS_WIDTH-1 downto 0);
      dbg_rdlvl_start           : out   std_logic_vector(1 downto 0);  
      dbg_rdlvl_done            : out   std_logic_vector(1 downto 0);
      dbg_rdlvl_err             : out   std_logic_vector(1 downto 0);
      dbg_cpt_tap_cnt           : out   std_logic_vector(5*DQS_WIDTH-1 downto 0);
      dbg_cpt_first_edge_cnt    : out   std_logic_vector(5*DQS_WIDTH-1 downto 0);
      dbg_cpt_second_edge_cnt   : out   std_logic_vector(5*DQS_WIDTH-1 downto 0);
      dbg_rd_bitslip_cnt        : out   std_logic_vector(3*DQS_WIDTH-1 downto 0);
      dbg_rd_clkdly_cnt         : out   std_logic_vector(2*DQS_WIDTH-1 downto 0);
      dbg_rd_active_dly         : out   std_logic_vector(4 downto 0);
      dbg_pd_off                : in    std_logic;
      dbg_pd_maintain_off       : in    std_logic;
      dbg_pd_maintain_0_only    : in    std_logic;
      dbg_inc_cpt               : in    std_logic;
      dbg_dec_cpt               : in    std_logic;
      dbg_inc_rd_dqs            : in    std_logic;
      dbg_dec_rd_dqs            : in    std_logic;
      dbg_inc_dec_sel           : in    std_logic_vector(DQS_CNT_WIDTH-1 downto 0);
      dbg_inc_rd_fps            : in    std_logic;
      dbg_dec_rd_fps            : in    std_logic;
      dbg_dqs_tap_cnt           : out   std_logic_vector(5*DQS_WIDTH-1 downto 0);
      dbg_dq_tap_cnt            : out   std_logic_vector(5*DQS_WIDTH-1 downto 0);
      dbg_rddata                : out   std_logic_vector(4*DQ_WIDTH-1 downto 0)
     );
  end component c1_memc_ui_top;

  component c2_memc_ui_top
    generic(
      REFCLK_FREQ           : real;
      SIM_BYPASS_INIT_CAL   : string;
      SIM_INIT_OPTION       : string;
      SIM_CAL_OPTION        : string;
      IODELAY_GRP           : string;
      nCK_PER_CLK           : integer;
      nCS_PER_RANK          : integer;
      DQS_CNT_WIDTH         : integer;
      RANK_WIDTH            : integer;
      BANK_WIDTH            : integer;
      CK_WIDTH              : integer;
      CKE_WIDTH             : integer;
      COL_WIDTH             : integer;
      CS_WIDTH              : integer;
      DQ_WIDTH              : integer;
      DM_WIDTH              : integer;
      DQS_WIDTH             : integer;
      ROW_WIDTH             : integer;
      BURST_MODE            : string;
      BM_CNT_WIDTH          : integer;
      ADDR_CMD_MODE         : string;
      ORDERING              : string;
      WRLVL                 : string;
      PHASE_DETECT          : string;
      RTT_NOM               : string;
      RTT_WR                : string;
      OUTPUT_DRV            : string;
      REG_CTRL              : string;
      nDQS_COL0             : integer;
      nDQS_COL1             : integer;
      nDQS_COL2             : integer;
      nDQS_COL3             : integer;
      DQS_LOC_COL0          : std_logic_vector(0 downto 0);
      DQS_LOC_COL1          : std_logic_vector(0 downto 0);
      DQS_LOC_COL2          : std_logic_vector(31 downto 0);
      DQS_LOC_COL3          : std_logic_vector(0 downto 0);
      tCK                   : integer;
      DEBUG_PORT            : string;
      tPRDI                 : integer;
      tREFI                 : integer;
      tZQI                  : integer;
      ADDR_WIDTH            : integer;
      TCQ                   : integer;
      ECC_TEST              : string;
      PAYLOAD_WIDTH         : integer
      );
    port(
      clk                       : in    std_logic;
      clk_mem                   : in    std_logic;
      clk_rd_base               : in    std_logic;
      rst                       : in    std_logic;
      ddr_addr                  : out   std_logic_vector(ROW_WIDTH-1 downto 0);
      ddr_ba                    : out   std_logic_vector(BANK_WIDTH-1 downto 0);
      ddr_cas_n                 : out   std_logic;
      ddr_ck_n                  : out   std_logic_vector(CK_WIDTH-1 downto 0);
      ddr_ck                    : out   std_logic_vector(CK_WIDTH-1 downto 0);
      ddr_cke                   : out   std_logic_vector(CKE_WIDTH-1 downto 0);
      ddr_cs_n                  : out   std_logic_vector(CS_WIDTH*nCS_PER_RANK-1 downto 0);
      ddr_dm                    : out   std_logic_vector(DM_WIDTH-1 downto 0);
      ddr_odt                   : out   std_logic_vector(CS_WIDTH*nCS_PER_RANK-1 downto 0);
      ddr_ras_n                 : out   std_logic;
      ddr_reset_n               : out   std_logic;
      ddr_parity                : out   std_logic;
      ddr_we_n                  : out   std_logic;
      ddr_dq                    : inout std_logic_vector(DQ_WIDTH-1 downto 0);
      ddr_dqs_n                 : inout std_logic_vector(DQS_WIDTH-1 downto 0);
      ddr_dqs                   : inout std_logic_vector(DQS_WIDTH-1 downto 0);
      pd_PSEN                   : out   std_logic;
      pd_PSINCDEC               : out   std_logic;
      pd_PSDONE                 : in    std_logic;
      dfi_init_complete         : out   std_logic;
      bank_mach_next            : out   std_logic_vector(BM_CNT_WIDTH-1 downto 0);
      app_ecc_multiple_err      : out   std_logic_vector(3 downto 0);
      app_rd_data               : out   std_logic_vector((PAYLOAD_WIDTH*4)-1 downto 0);
      app_rd_data_end           : out   std_logic;
      app_rd_data_valid         : out   std_logic;
      app_rdy                   : out   std_logic;
      app_wdf_rdy               : out   std_logic;
      app_addr                  : in    std_logic_vector(ADDR_WIDTH-1 downto 0);
      app_cmd                   : in    std_logic_vector(2 downto 0);
      app_en                    : in    std_logic;
      app_hi_pri                : in    std_logic;
      app_sz                    : in    std_logic;
      app_wdf_data              : in    std_logic_vector((PAYLOAD_WIDTH*4)-1 downto 0);
      app_wdf_end               : in    std_logic;
      app_wdf_mask              : in    std_logic_vector((PAYLOAD_WIDTH/2)-1 downto 0);
      app_wdf_wren              : in    std_logic;
      dbg_wr_dq_tap_set         : in    std_logic_vector(5*DQS_WIDTH-1 downto 0);
      dbg_wr_dqs_tap_set        : in    std_logic_vector(5*DQS_WIDTH-1 downto 0);       
      dbg_wr_tap_set_en         : in    std_logic;
      dbg_wrlvl_start           : out   std_logic;  
      dbg_wrlvl_done            : out   std_logic;  
      dbg_wrlvl_err             : out   std_logic;  
      dbg_wl_dqs_inverted       : out   std_logic_vector(DQS_WIDTH-1 downto 0);
      dbg_wr_calib_clk_delay    : out   std_logic_vector(2*DQS_WIDTH-1 downto 0);
      dbg_wl_odelay_dqs_tap_cnt : out   std_logic_vector(5*DQS_WIDTH-1 downto 0);
      dbg_wl_odelay_dq_tap_cnt  : out   std_logic_vector(5*DQS_WIDTH-1 downto 0);
      dbg_rdlvl_start           : out   std_logic_vector(1 downto 0);  
      dbg_rdlvl_done            : out   std_logic_vector(1 downto 0);
      dbg_rdlvl_err             : out   std_logic_vector(1 downto 0);
      dbg_cpt_tap_cnt           : out   std_logic_vector(5*DQS_WIDTH-1 downto 0);
      dbg_cpt_first_edge_cnt    : out   std_logic_vector(5*DQS_WIDTH-1 downto 0);
      dbg_cpt_second_edge_cnt   : out   std_logic_vector(5*DQS_WIDTH-1 downto 0);
      dbg_rd_bitslip_cnt        : out   std_logic_vector(3*DQS_WIDTH-1 downto 0);
      dbg_rd_clkdly_cnt         : out   std_logic_vector(2*DQS_WIDTH-1 downto 0);
      dbg_rd_active_dly         : out   std_logic_vector(4 downto 0);
      dbg_pd_off                : in    std_logic;
      dbg_pd_maintain_off       : in    std_logic;
      dbg_pd_maintain_0_only    : in    std_logic;
      dbg_inc_cpt               : in    std_logic;
      dbg_dec_cpt               : in    std_logic;
      dbg_inc_rd_dqs            : in    std_logic;
      dbg_dec_rd_dqs            : in    std_logic;
      dbg_inc_dec_sel           : in    std_logic_vector(DQS_CNT_WIDTH-1 downto 0);
      dbg_inc_rd_fps            : in    std_logic;
      dbg_dec_rd_fps            : in    std_logic;
      dbg_dqs_tap_cnt           : out   std_logic_vector(5*DQS_WIDTH-1 downto 0);
      dbg_dq_tap_cnt            : out   std_logic_vector(5*DQS_WIDTH-1 downto 0);
      dbg_rddata                : out   std_logic_vector(4*DQ_WIDTH-1 downto 0)
     );
  end component c2_memc_ui_top;

  component c3_memc_ui_top
    generic(
      REFCLK_FREQ           : real;
      SIM_BYPASS_INIT_CAL   : string;
      SIM_INIT_OPTION       : string;
      SIM_CAL_OPTION        : string;
      IODELAY_GRP           : string;
      nCK_PER_CLK           : integer;
      nCS_PER_RANK          : integer;
      DQS_CNT_WIDTH         : integer;
      RANK_WIDTH            : integer;
      BANK_WIDTH            : integer;
      CK_WIDTH              : integer;
      CKE_WIDTH             : integer;
      COL_WIDTH             : integer;
      CS_WIDTH              : integer;
      DQ_WIDTH              : integer;
      DM_WIDTH              : integer;
      DQS_WIDTH             : integer;
      ROW_WIDTH             : integer;
      BURST_MODE            : string;
      BM_CNT_WIDTH          : integer;
      ADDR_CMD_MODE         : string;
      ORDERING              : string;
      WRLVL                 : string;
      PHASE_DETECT          : string;
      RTT_NOM               : string;
      RTT_WR                : string;
      OUTPUT_DRV            : string;
      REG_CTRL              : string;
      nDQS_COL0             : integer;
      nDQS_COL1             : integer;
      nDQS_COL2             : integer;
      nDQS_COL3             : integer;
      DQS_LOC_COL0          : std_logic_vector(15 downto 0);
      DQS_LOC_COL1          : std_logic_vector(15 downto 0);
      DQS_LOC_COL2          : std_logic_vector(0 downto 0);
      DQS_LOC_COL3          : std_logic_vector(0 downto 0);
      tCK                   : integer;
      DEBUG_PORT            : string;
      tPRDI                 : integer;
      tREFI                 : integer;
      tZQI                  : integer;
      ADDR_WIDTH            : integer;
      TCQ                   : integer;
      ECC_TEST              : string;
      PAYLOAD_WIDTH         : integer
      );
    port(
      clk                       : in    std_logic;
      clk_mem                   : in    std_logic;
      clk_rd_base               : in    std_logic;
      rst                       : in    std_logic;
      ddr_addr                  : out   std_logic_vector(ROW_WIDTH-1 downto 0);
      ddr_ba                    : out   std_logic_vector(BANK_WIDTH-1 downto 0);
      ddr_cas_n                 : out   std_logic;
      ddr_ck_n                  : out   std_logic_vector(CK_WIDTH-1 downto 0);
      ddr_ck                    : out   std_logic_vector(CK_WIDTH-1 downto 0);
      ddr_cke                   : out   std_logic_vector(CKE_WIDTH-1 downto 0);
      ddr_cs_n                  : out   std_logic_vector(CS_WIDTH*nCS_PER_RANK-1 downto 0);
      ddr_dm                    : out   std_logic_vector(DM_WIDTH-1 downto 0);
      ddr_odt                   : out   std_logic_vector(CS_WIDTH*nCS_PER_RANK-1 downto 0);
      ddr_ras_n                 : out   std_logic;
      ddr_reset_n               : out   std_logic;
      ddr_parity                : out   std_logic;
      ddr_we_n                  : out   std_logic;
      ddr_dq                    : inout std_logic_vector(DQ_WIDTH-1 downto 0);
      ddr_dqs_n                 : inout std_logic_vector(DQS_WIDTH-1 downto 0);
      ddr_dqs                   : inout std_logic_vector(DQS_WIDTH-1 downto 0);
      pd_PSEN                   : out   std_logic;
      pd_PSINCDEC               : out   std_logic;
      pd_PSDONE                 : in    std_logic;
      dfi_init_complete         : out   std_logic;
      bank_mach_next            : out   std_logic_vector(BM_CNT_WIDTH-1 downto 0);
      app_ecc_multiple_err      : out   std_logic_vector(3 downto 0);
      app_rd_data               : out   std_logic_vector((PAYLOAD_WIDTH*4)-1 downto 0);
      app_rd_data_end           : out   std_logic;
      app_rd_data_valid         : out   std_logic;
      app_rdy                   : out   std_logic;
      app_wdf_rdy               : out   std_logic;
      app_addr                  : in    std_logic_vector(ADDR_WIDTH-1 downto 0);
      app_cmd                   : in    std_logic_vector(2 downto 0);
      app_en                    : in    std_logic;
      app_hi_pri                : in    std_logic;
      app_sz                    : in    std_logic;
      app_wdf_data              : in    std_logic_vector((PAYLOAD_WIDTH*4)-1 downto 0);
      app_wdf_end               : in    std_logic;
      app_wdf_mask              : in    std_logic_vector((PAYLOAD_WIDTH/2)-1 downto 0);
      app_wdf_wren              : in    std_logic;
      dbg_wr_dq_tap_set         : in    std_logic_vector(5*DQS_WIDTH-1 downto 0);
      dbg_wr_dqs_tap_set        : in    std_logic_vector(5*DQS_WIDTH-1 downto 0);       
      dbg_wr_tap_set_en         : in    std_logic;
      dbg_wrlvl_start           : out   std_logic;  
      dbg_wrlvl_done            : out   std_logic;  
      dbg_wrlvl_err             : out   std_logic;  
      dbg_wl_dqs_inverted       : out   std_logic_vector(DQS_WIDTH-1 downto 0);
      dbg_wr_calib_clk_delay    : out   std_logic_vector(2*DQS_WIDTH-1 downto 0);
      dbg_wl_odelay_dqs_tap_cnt : out   std_logic_vector(5*DQS_WIDTH-1 downto 0);
      dbg_wl_odelay_dq_tap_cnt  : out   std_logic_vector(5*DQS_WIDTH-1 downto 0);
      dbg_rdlvl_start           : out   std_logic_vector(1 downto 0);  
      dbg_rdlvl_done            : out   std_logic_vector(1 downto 0);
      dbg_rdlvl_err             : out   std_logic_vector(1 downto 0);
      dbg_cpt_tap_cnt           : out   std_logic_vector(5*DQS_WIDTH-1 downto 0);
      dbg_cpt_first_edge_cnt    : out   std_logic_vector(5*DQS_WIDTH-1 downto 0);
      dbg_cpt_second_edge_cnt   : out   std_logic_vector(5*DQS_WIDTH-1 downto 0);
      dbg_rd_bitslip_cnt        : out   std_logic_vector(3*DQS_WIDTH-1 downto 0);
      dbg_rd_clkdly_cnt         : out   std_logic_vector(2*DQS_WIDTH-1 downto 0);
      dbg_rd_active_dly         : out   std_logic_vector(4 downto 0);
      dbg_pd_off                : in    std_logic;
      dbg_pd_maintain_off       : in    std_logic;
      dbg_pd_maintain_0_only    : in    std_logic;
      dbg_inc_cpt               : in    std_logic;
      dbg_dec_cpt               : in    std_logic;
      dbg_inc_rd_dqs            : in    std_logic;
      dbg_dec_rd_dqs            : in    std_logic;
      dbg_inc_dec_sel           : in    std_logic_vector(DQS_CNT_WIDTH-1 downto 0);
      dbg_inc_rd_fps            : in    std_logic;
      dbg_dec_rd_fps            : in    std_logic;
      dbg_dqs_tap_cnt           : out   std_logic_vector(5*DQS_WIDTH-1 downto 0);
      dbg_dq_tap_cnt            : out   std_logic_vector(5*DQS_WIDTH-1 downto 0);
      dbg_rddata                : out   std_logic_vector(4*DQ_WIDTH-1 downto 0)
     );
  end component c3_memc_ui_top;





  signal clk200_ref_p                   : std_logic;
  signal clk200_ref_n                   : std_logic;
  signal sys_clk_f0_p                   : std_logic;
  signal sys_clk_f0_n                   : std_logic;
  signal mmcm_clk_f0                    : std_logic;
  signal iodelay200_ctrl_rdy            : std_logic;
      
  signal c0_rst                         : std_logic;
  signal c0_clk                         : std_logic;
  signal c0_clk_mem                     : std_logic;
  signal c0_clk_rd_base                 : std_logic;
  signal c0_pd_PSDONE                   : std_logic;
  signal c0_pd_PSEN                     : std_logic;
  signal c0_pd_PSINCDEC                 : std_logic;
  signal c0_bank_mach_next              : std_logic_vector((C0_BM_CNT_WIDTH)-1 downto 0);
  signal c0_ddr3_parity                 : std_logic;
  signal c0_app_rd_data_end             : std_logic;
  signal c0_app_hi_pri                  : std_logic;

  signal c0_dfi_init_complete           : std_logic;
  signal c0_app_ecc_multiple_err_i      : std_logic_vector(3 downto 0);
  signal c0_traffic_wr_data_counts      : std_logic_vector(47 downto 0);
  signal c0_traffic_rd_data_counts      : std_logic_vector(47 downto 0);

  signal c1_rst                         : std_logic;
  signal c1_clk                         : std_logic;
  signal c1_clk_mem                     : std_logic;
  signal c1_clk_rd_base                 : std_logic;
  signal c1_pd_PSDONE                   : std_logic;
  signal c1_pd_PSEN                     : std_logic;
  signal c1_pd_PSINCDEC                 : std_logic;
  signal c1_bank_mach_next              : std_logic_vector((C1_BM_CNT_WIDTH)-1 downto 0);
  signal c1_ddr3_parity                 : std_logic;
  signal c1_app_rd_data_end             : std_logic;
  signal c1_app_hi_pri                  : std_logic;

  signal c1_dfi_init_complete           : std_logic;
  signal c1_app_ecc_multiple_err_i      : std_logic_vector(3 downto 0);
  signal c1_traffic_wr_data_counts      : std_logic_vector(47 downto 0);
  signal c1_traffic_rd_data_counts      : std_logic_vector(47 downto 0);

  signal c2_rst                         : std_logic;
  signal c2_clk                         : std_logic;
  signal c2_clk_mem                     : std_logic;
  signal c2_clk_rd_base                 : std_logic;
  signal c2_pd_PSDONE                   : std_logic;
  signal c2_pd_PSEN                     : std_logic;
  signal c2_pd_PSINCDEC                 : std_logic;
  signal c2_bank_mach_next              : std_logic_vector((C2_BM_CNT_WIDTH)-1 downto 0);
  signal c2_ddr3_parity                 : std_logic;
  signal c2_app_rd_data_end             : std_logic;
  signal c2_app_hi_pri                  : std_logic;

  signal c2_dfi_init_complete           : std_logic;
  signal c2_app_ecc_multiple_err_i      : std_logic_vector(3 downto 0);
  signal c2_traffic_wr_data_counts      : std_logic_vector(47 downto 0);
  signal c2_traffic_rd_data_counts      : std_logic_vector(47 downto 0);

  signal c3_rst                         : std_logic;
  signal c3_clk                         : std_logic;
  signal c3_clk_mem                     : std_logic;
  signal c3_clk_rd_base                 : std_logic;
  signal c3_pd_PSDONE                   : std_logic;
  signal c3_pd_PSEN                     : std_logic;
  signal c3_pd_PSINCDEC                 : std_logic;
  signal c3_bank_mach_next              : std_logic_vector((C3_BM_CNT_WIDTH)-1 downto 0);
  signal c3_ddr3_parity                 : std_logic;
  signal c3_app_rd_data_end             : std_logic;
  signal c3_app_hi_pri                  : std_logic;

  signal c3_dfi_init_complete           : std_logic;
  signal c3_app_ecc_multiple_err_i      : std_logic_vector(3 downto 0);
  signal c3_traffic_wr_data_counts      : std_logic_vector(47 downto 0);
  signal c3_traffic_rd_data_counts      : std_logic_vector(47 downto 0);


  signal c0_dbg_cpt_first_edge_cnt      : std_logic_vector(5*C0_DQS_WIDTH-1 downto 0);
  signal c0_dbg_cpt_second_edge_cnt     : std_logic_vector(5*C0_DQS_WIDTH-1 downto 0);
  signal c0_dbg_cpt_tap_cnt             : std_logic_vector(5*C0_DQS_WIDTH-1 downto 0);
  signal c0_dbg_dec_cpt                 : std_logic;
  signal c0_dbg_dec_rd_dqs              : std_logic;
  signal c0_dbg_dec_rd_fps              : std_logic;
  signal c0_dbg_dq_tap_cnt              : std_logic_vector(5*C0_DQS_WIDTH-1 downto 0);
  signal c0_dbg_dqs_tap_cnt             : std_logic_vector(5*C0_DQS_WIDTH-1 downto 0);
  signal c0_dbg_inc_cpt                 : std_logic;
  signal c0_dbg_inc_dec_sel             : std_logic_vector(C0_DQS_CNT_WIDTH-1 downto 0);
  signal c0_dbg_inc_rd_dqs              : std_logic;
  signal c0_dbg_inc_rd_fps              : std_logic;
  signal c0_dbg_ocb_mon_off             : std_logic;
  signal c0_dbg_pd_off                  : std_logic;
  signal c0_dbg_pd_maintain_off         : std_logic;
  signal c0_dbg_pd_maintain_0_only      : std_logic;
  signal c0_dbg_rd_active_dly           : std_logic_vector(4 downto 0);
  signal c0_dbg_rd_bitslip_cnt          : std_logic_vector(3*C0_DQS_WIDTH-1 downto 0);
  signal c0_dbg_rd_clkdly_cnt           : std_logic_vector(2*C0_DQS_WIDTH-1 downto 0);
  signal c0_dbg_rddata                  : std_logic_vector(4*C0_DQ_WIDTH-1 downto 0);
  signal c0_dbg_rdlvl_done              : std_logic_vector(1 downto 0);
  signal c0_dbg_rdlvl_err               : std_logic_vector(1 downto 0);
  signal c0_dbg_rdlvl_start             : std_logic_vector(1 downto 0);
  signal c0_dbg_wl_dqs_inverted         : std_logic_vector(C0_DQS_WIDTH-1 downto 0);
  signal c0_dbg_wl_odelay_dq_tap_cnt    : std_logic_vector(5*C0_DQS_WIDTH-1 downto 0);
  signal c0_dbg_wl_odelay_dqs_tap_cnt   : std_logic_vector(5*C0_DQS_WIDTH-1 downto 0);
  signal c0_dbg_wr_calib_clk_delay      : std_logic_vector(2*C0_DQS_WIDTH-1 downto 0);
  signal c0_dbg_wr_dq_tap_set           : std_logic_vector(5*C0_DQS_WIDTH-1 downto 0);
  signal c0_dbg_wr_dqs_tap_set          : std_logic_vector(5*C0_DQS_WIDTH-1 downto 0);       
  signal c0_dbg_wr_tap_set_en           : std_logic;  
  signal c0_dbg_idel_up_all             : std_logic;  
  signal c0_dbg_idel_down_all           : std_logic;  
  signal c0_dbg_idel_up_cpt             : std_logic;  
  signal c0_dbg_idel_down_cpt           : std_logic;  
  signal c0_dbg_idel_up_rsync           : std_logic;  
  signal c0_dbg_idel_down_rsync         : std_logic;  
  signal c0_dbg_sel_all_idel_cpt        : std_logic;  
  signal c0_dbg_sel_all_idel_rsync      : std_logic;  
  signal c0_dbg_pd_inc_cpt              : std_logic;  
  signal c0_dbg_pd_dec_cpt              : std_logic;  
  signal c0_dbg_pd_inc_dqs              : std_logic;  
  signal c0_dbg_pd_dec_dqs              : std_logic;  
  signal c0_dbg_pd_disab_hyst           : std_logic;  
  signal c0_dbg_pd_disab_hyst_0         : std_logic;  
  signal c0_dbg_wrlvl_done              : std_logic;  
  signal c0_dbg_wrlvl_err               : std_logic;  
  signal c0_dbg_wrlvl_start             : std_logic;  
  signal c0_dbg_tap_cnt_during_wrlvl    : std_logic_vector(4 downto 0);
  signal c0_dbg_rsync_tap_cnt           : std_logic_vector(19 downto 0);
  signal c0_dbg_phy_pd                  : std_logic_vector(255 downto 0);
  signal c0_dbg_phy_read                : std_logic_vector(255 downto 0);
  signal c0_dbg_phy_rdlvl               : std_logic_vector(255 downto 0);
  signal c0_dbg_phy_top                 : std_logic_vector(255 downto 0);
  signal c0_dbg_pd_msb_sel              : std_logic_vector(3 downto 0);
  signal c0_dbg_rd_data_edge_detect     : std_logic_vector(C0_DQS_WIDTH-1 downto 0);
  signal c0_dbg_sel_idel_cpt            : std_logic_vector(C0_DQS_CNT_WIDTH-1 downto 0);
  signal c0_dbg_sel_idel_rsync          : std_logic_vector(C0_DQS_CNT_WIDTH-1 downto 0);
  signal c0_dbg_pd_byte_sel             : std_logic_vector(C0_DQS_CNT_WIDTH-1 downto 0);

  signal c1_dbg_cpt_first_edge_cnt      : std_logic_vector(5*C1_DQS_WIDTH-1 downto 0);
  signal c1_dbg_cpt_second_edge_cnt     : std_logic_vector(5*C1_DQS_WIDTH-1 downto 0);
  signal c1_dbg_cpt_tap_cnt             : std_logic_vector(5*C1_DQS_WIDTH-1 downto 0);
  signal c1_dbg_dec_cpt                 : std_logic;
  signal c1_dbg_dec_rd_dqs              : std_logic;
  signal c1_dbg_dec_rd_fps              : std_logic;
  signal c1_dbg_dq_tap_cnt              : std_logic_vector(5*C1_DQS_WIDTH-1 downto 0);
  signal c1_dbg_dqs_tap_cnt             : std_logic_vector(5*C1_DQS_WIDTH-1 downto 0);
  signal c1_dbg_inc_cpt                 : std_logic;
  signal c1_dbg_inc_dec_sel             : std_logic_vector(C1_DQS_CNT_WIDTH-1 downto 0);
  signal c1_dbg_inc_rd_dqs              : std_logic;
  signal c1_dbg_inc_rd_fps              : std_logic;
  signal c1_dbg_ocb_mon_off             : std_logic;
  signal c1_dbg_pd_off                  : std_logic;
  signal c1_dbg_pd_maintain_off         : std_logic;
  signal c1_dbg_pd_maintain_0_only      : std_logic;
  signal c1_dbg_rd_active_dly           : std_logic_vector(4 downto 0);
  signal c1_dbg_rd_bitslip_cnt          : std_logic_vector(3*C1_DQS_WIDTH-1 downto 0);
  signal c1_dbg_rd_clkdly_cnt           : std_logic_vector(2*C1_DQS_WIDTH-1 downto 0);
  signal c1_dbg_rddata                  : std_logic_vector(4*C1_DQ_WIDTH-1 downto 0);
  signal c1_dbg_rdlvl_done              : std_logic_vector(1 downto 0);
  signal c1_dbg_rdlvl_err               : std_logic_vector(1 downto 0);
  signal c1_dbg_rdlvl_start             : std_logic_vector(1 downto 0);
  signal c1_dbg_wl_dqs_inverted         : std_logic_vector(C1_DQS_WIDTH-1 downto 0);
  signal c1_dbg_wl_odelay_dq_tap_cnt    : std_logic_vector(5*C1_DQS_WIDTH-1 downto 0);
  signal c1_dbg_wl_odelay_dqs_tap_cnt   : std_logic_vector(5*C1_DQS_WIDTH-1 downto 0);
  signal c1_dbg_wr_calib_clk_delay      : std_logic_vector(2*C1_DQS_WIDTH-1 downto 0);
  signal c1_dbg_wr_dq_tap_set           : std_logic_vector(5*C1_DQS_WIDTH-1 downto 0);
  signal c1_dbg_wr_dqs_tap_set          : std_logic_vector(5*C1_DQS_WIDTH-1 downto 0);       
  signal c1_dbg_wr_tap_set_en           : std_logic;  
  signal c1_dbg_idel_up_all             : std_logic;  
  signal c1_dbg_idel_down_all           : std_logic;  
  signal c1_dbg_idel_up_cpt             : std_logic;  
  signal c1_dbg_idel_down_cpt           : std_logic;  
  signal c1_dbg_idel_up_rsync           : std_logic;  
  signal c1_dbg_idel_down_rsync         : std_logic;  
  signal c1_dbg_sel_all_idel_cpt        : std_logic;  
  signal c1_dbg_sel_all_idel_rsync      : std_logic;  
  signal c1_dbg_pd_inc_cpt              : std_logic;  
  signal c1_dbg_pd_dec_cpt              : std_logic;  
  signal c1_dbg_pd_inc_dqs              : std_logic;  
  signal c1_dbg_pd_dec_dqs              : std_logic;  
  signal c1_dbg_pd_disab_hyst           : std_logic;  
  signal c1_dbg_pd_disab_hyst_0         : std_logic;  
  signal c1_dbg_wrlvl_done              : std_logic;  
  signal c1_dbg_wrlvl_err               : std_logic;  
  signal c1_dbg_wrlvl_start             : std_logic;  
  signal c1_dbg_tap_cnt_during_wrlvl    : std_logic_vector(4 downto 0);
  signal c1_dbg_rsync_tap_cnt           : std_logic_vector(19 downto 0);
  signal c1_dbg_phy_pd                  : std_logic_vector(255 downto 0);
  signal c1_dbg_phy_read                : std_logic_vector(255 downto 0);
  signal c1_dbg_phy_rdlvl               : std_logic_vector(255 downto 0);
  signal c1_dbg_phy_top                 : std_logic_vector(255 downto 0);
  signal c1_dbg_pd_msb_sel              : std_logic_vector(3 downto 0);
  signal c1_dbg_rd_data_edge_detect     : std_logic_vector(C1_DQS_WIDTH-1 downto 0);
  signal c1_dbg_sel_idel_cpt            : std_logic_vector(C1_DQS_CNT_WIDTH-1 downto 0);
  signal c1_dbg_sel_idel_rsync          : std_logic_vector(C1_DQS_CNT_WIDTH-1 downto 0);
  signal c1_dbg_pd_byte_sel             : std_logic_vector(C1_DQS_CNT_WIDTH-1 downto 0);

  signal c2_dbg_cpt_first_edge_cnt      : std_logic_vector(5*C2_DQS_WIDTH-1 downto 0);
  signal c2_dbg_cpt_second_edge_cnt     : std_logic_vector(5*C2_DQS_WIDTH-1 downto 0);
  signal c2_dbg_cpt_tap_cnt             : std_logic_vector(5*C2_DQS_WIDTH-1 downto 0);
  signal c2_dbg_dec_cpt                 : std_logic;
  signal c2_dbg_dec_rd_dqs              : std_logic;
  signal c2_dbg_dec_rd_fps              : std_logic;
  signal c2_dbg_dq_tap_cnt              : std_logic_vector(5*C2_DQS_WIDTH-1 downto 0);
  signal c2_dbg_dqs_tap_cnt             : std_logic_vector(5*C2_DQS_WIDTH-1 downto 0);
  signal c2_dbg_inc_cpt                 : std_logic;
  signal c2_dbg_inc_dec_sel             : std_logic_vector(C2_DQS_CNT_WIDTH-1 downto 0);
  signal c2_dbg_inc_rd_dqs              : std_logic;
  signal c2_dbg_inc_rd_fps              : std_logic;
  signal c2_dbg_ocb_mon_off             : std_logic;
  signal c2_dbg_pd_off                  : std_logic;
  signal c2_dbg_pd_maintain_off         : std_logic;
  signal c2_dbg_pd_maintain_0_only      : std_logic;
  signal c2_dbg_rd_active_dly           : std_logic_vector(4 downto 0);
  signal c2_dbg_rd_bitslip_cnt          : std_logic_vector(3*C2_DQS_WIDTH-1 downto 0);
  signal c2_dbg_rd_clkdly_cnt           : std_logic_vector(2*C2_DQS_WIDTH-1 downto 0);
  signal c2_dbg_rddata                  : std_logic_vector(4*C2_DQ_WIDTH-1 downto 0);
  signal c2_dbg_rdlvl_done              : std_logic_vector(1 downto 0);
  signal c2_dbg_rdlvl_err               : std_logic_vector(1 downto 0);
  signal c2_dbg_rdlvl_start             : std_logic_vector(1 downto 0);
  signal c2_dbg_wl_dqs_inverted         : std_logic_vector(C2_DQS_WIDTH-1 downto 0);
  signal c2_dbg_wl_odelay_dq_tap_cnt    : std_logic_vector(5*C2_DQS_WIDTH-1 downto 0);
  signal c2_dbg_wl_odelay_dqs_tap_cnt   : std_logic_vector(5*C2_DQS_WIDTH-1 downto 0);
  signal c2_dbg_wr_calib_clk_delay      : std_logic_vector(2*C2_DQS_WIDTH-1 downto 0);
  signal c2_dbg_wr_dq_tap_set           : std_logic_vector(5*C2_DQS_WIDTH-1 downto 0);
  signal c2_dbg_wr_dqs_tap_set          : std_logic_vector(5*C2_DQS_WIDTH-1 downto 0);       
  signal c2_dbg_wr_tap_set_en           : std_logic;  
  signal c2_dbg_idel_up_all             : std_logic;  
  signal c2_dbg_idel_down_all           : std_logic;  
  signal c2_dbg_idel_up_cpt             : std_logic;  
  signal c2_dbg_idel_down_cpt           : std_logic;  
  signal c2_dbg_idel_up_rsync           : std_logic;  
  signal c2_dbg_idel_down_rsync         : std_logic;  
  signal c2_dbg_sel_all_idel_cpt        : std_logic;  
  signal c2_dbg_sel_all_idel_rsync      : std_logic;  
  signal c2_dbg_pd_inc_cpt              : std_logic;  
  signal c2_dbg_pd_dec_cpt              : std_logic;  
  signal c2_dbg_pd_inc_dqs              : std_logic;  
  signal c2_dbg_pd_dec_dqs              : std_logic;  
  signal c2_dbg_pd_disab_hyst           : std_logic;  
  signal c2_dbg_pd_disab_hyst_0         : std_logic;  
  signal c2_dbg_wrlvl_done              : std_logic;  
  signal c2_dbg_wrlvl_err               : std_logic;  
  signal c2_dbg_wrlvl_start             : std_logic;  
  signal c2_dbg_tap_cnt_during_wrlvl    : std_logic_vector(4 downto 0);
  signal c2_dbg_rsync_tap_cnt           : std_logic_vector(19 downto 0);
  signal c2_dbg_phy_pd                  : std_logic_vector(255 downto 0);
  signal c2_dbg_phy_read                : std_logic_vector(255 downto 0);
  signal c2_dbg_phy_rdlvl               : std_logic_vector(255 downto 0);
  signal c2_dbg_phy_top                 : std_logic_vector(255 downto 0);
  signal c2_dbg_pd_msb_sel              : std_logic_vector(3 downto 0);
  signal c2_dbg_rd_data_edge_detect     : std_logic_vector(C2_DQS_WIDTH-1 downto 0);
  signal c2_dbg_sel_idel_cpt            : std_logic_vector(C2_DQS_CNT_WIDTH-1 downto 0);
  signal c2_dbg_sel_idel_rsync          : std_logic_vector(C2_DQS_CNT_WIDTH-1 downto 0);
  signal c2_dbg_pd_byte_sel             : std_logic_vector(C2_DQS_CNT_WIDTH-1 downto 0);

  signal c3_dbg_cpt_first_edge_cnt      : std_logic_vector(5*C3_DQS_WIDTH-1 downto 0);
  signal c3_dbg_cpt_second_edge_cnt     : std_logic_vector(5*C3_DQS_WIDTH-1 downto 0);
  signal c3_dbg_cpt_tap_cnt             : std_logic_vector(5*C3_DQS_WIDTH-1 downto 0);
  signal c3_dbg_dec_cpt                 : std_logic;
  signal c3_dbg_dec_rd_dqs              : std_logic;
  signal c3_dbg_dec_rd_fps              : std_logic;
  signal c3_dbg_dq_tap_cnt              : std_logic_vector(5*C3_DQS_WIDTH-1 downto 0);
  signal c3_dbg_dqs_tap_cnt             : std_logic_vector(5*C3_DQS_WIDTH-1 downto 0);
  signal c3_dbg_inc_cpt                 : std_logic;
  signal c3_dbg_inc_dec_sel             : std_logic_vector(C3_DQS_CNT_WIDTH-1 downto 0);
  signal c3_dbg_inc_rd_dqs              : std_logic;
  signal c3_dbg_inc_rd_fps              : std_logic;
  signal c3_dbg_ocb_mon_off             : std_logic;
  signal c3_dbg_pd_off                  : std_logic;
  signal c3_dbg_pd_maintain_off         : std_logic;
  signal c3_dbg_pd_maintain_0_only      : std_logic;
  signal c3_dbg_rd_active_dly           : std_logic_vector(4 downto 0);
  signal c3_dbg_rd_bitslip_cnt          : std_logic_vector(3*C3_DQS_WIDTH-1 downto 0);
  signal c3_dbg_rd_clkdly_cnt           : std_logic_vector(2*C3_DQS_WIDTH-1 downto 0);
  signal c3_dbg_rddata                  : std_logic_vector(4*C3_DQ_WIDTH-1 downto 0);
  signal c3_dbg_rdlvl_done              : std_logic_vector(1 downto 0);
  signal c3_dbg_rdlvl_err               : std_logic_vector(1 downto 0);
  signal c3_dbg_rdlvl_start             : std_logic_vector(1 downto 0);
  signal c3_dbg_wl_dqs_inverted         : std_logic_vector(C3_DQS_WIDTH-1 downto 0);
  signal c3_dbg_wl_odelay_dq_tap_cnt    : std_logic_vector(5*C3_DQS_WIDTH-1 downto 0);
  signal c3_dbg_wl_odelay_dqs_tap_cnt   : std_logic_vector(5*C3_DQS_WIDTH-1 downto 0);
  signal c3_dbg_wr_calib_clk_delay      : std_logic_vector(2*C3_DQS_WIDTH-1 downto 0);
  signal c3_dbg_wr_dq_tap_set           : std_logic_vector(5*C3_DQS_WIDTH-1 downto 0);
  signal c3_dbg_wr_dqs_tap_set          : std_logic_vector(5*C3_DQS_WIDTH-1 downto 0);       
  signal c3_dbg_wr_tap_set_en           : std_logic;  
  signal c3_dbg_idel_up_all             : std_logic;  
  signal c3_dbg_idel_down_all           : std_logic;  
  signal c3_dbg_idel_up_cpt             : std_logic;  
  signal c3_dbg_idel_down_cpt           : std_logic;  
  signal c3_dbg_idel_up_rsync           : std_logic;  
  signal c3_dbg_idel_down_rsync         : std_logic;  
  signal c3_dbg_sel_all_idel_cpt        : std_logic;  
  signal c3_dbg_sel_all_idel_rsync      : std_logic;  
  signal c3_dbg_pd_inc_cpt              : std_logic;  
  signal c3_dbg_pd_dec_cpt              : std_logic;  
  signal c3_dbg_pd_inc_dqs              : std_logic;  
  signal c3_dbg_pd_dec_dqs              : std_logic;  
  signal c3_dbg_pd_disab_hyst           : std_logic;  
  signal c3_dbg_pd_disab_hyst_0         : std_logic;  
  signal c3_dbg_wrlvl_done              : std_logic;  
  signal c3_dbg_wrlvl_err               : std_logic;  
  signal c3_dbg_wrlvl_start             : std_logic;  
  signal c3_dbg_tap_cnt_during_wrlvl    : std_logic_vector(4 downto 0);
  signal c3_dbg_rsync_tap_cnt           : std_logic_vector(19 downto 0);
  signal c3_dbg_phy_pd                  : std_logic_vector(255 downto 0);
  signal c3_dbg_phy_read                : std_logic_vector(255 downto 0);
  signal c3_dbg_phy_rdlvl               : std_logic_vector(255 downto 0);
  signal c3_dbg_phy_top                 : std_logic_vector(255 downto 0);
  signal c3_dbg_pd_msb_sel              : std_logic_vector(3 downto 0);
  signal c3_dbg_rd_data_edge_detect     : std_logic_vector(C3_DQS_WIDTH-1 downto 0);
  signal c3_dbg_sel_idel_cpt            : std_logic_vector(C3_DQS_CNT_WIDTH-1 downto 0);
  signal c3_dbg_sel_idel_rsync          : std_logic_vector(C3_DQS_CNT_WIDTH-1 downto 0);
  signal c3_dbg_pd_byte_sel             : std_logic_vector(C3_DQS_CNT_WIDTH-1 downto 0);

  signal ddr3_cs0_clk          : std_logic;
  signal ddr3_cs0_control      : std_logic_vector(35 downto 0);
  signal ddr3_cs0_data         : std_logic_vector(383 downto 0);
  signal ddr3_cs0_trig         : std_logic_vector(7 downto 0);
  signal ddr3_cs1_async_in     : std_logic_vector(255 downto 0);
  signal ddr3_cs1_control      : std_logic_vector(35 downto 0);
  signal ddr3_cs2_async_in     : std_logic_vector(255 downto 0);
  signal ddr3_cs2_control      : std_logic_vector(35 downto 0);
  signal ddr3_cs3_async_in     : std_logic_vector(255 downto 0);
  signal ddr3_cs3_control      : std_logic_vector(35 downto 0);
  signal ddr3_cs4_clk          : std_logic;
  signal ddr3_cs4_control      : std_logic_vector(35 downto 0);
  signal ddr3_cs4_sync_out     : std_logic_vector(31 downto 0);

  attribute keep : string;




begin

  --***************************************************************************
  c0_phy_init_done            <= c0_dfi_init_complete;
  c0_app_hi_pri               <= '0';
  c0_tb_clk                   <= c0_clk;
  c0_tb_rst                   <= c0_rst;
  clk200_ref_p                <= '0';
  clk200_ref_n                <= '0';
  sys_clk_f0_p                <= '0';
  sys_clk_f0_n                <= '0';
  c1_phy_init_done            <= c1_dfi_init_complete;
  c1_app_hi_pri               <= '0';
  c1_tb_clk                   <= c1_clk;
  c1_tb_rst                   <= c1_rst;
  c2_phy_init_done            <= c2_dfi_init_complete;
  c2_app_hi_pri               <= '0';
  c2_tb_clk                   <= c2_clk;
  c2_tb_rst                   <= c2_rst;
  c3_phy_init_done            <= c3_dfi_init_complete;
  c3_app_hi_pri               <= '0';
  c3_tb_clk                   <= c3_clk;
  c3_tb_rst                   <= c3_rst;


  u_clk_f0_ibuf : clk_ibuf
    generic map(
      INPUT_CLK_TYPE => INPUT_CLK_TYPE
      )
    port map(
      sys_clk_p => sys_clk_f0_p,
      sys_clk_n => sys_clk_f0_n,
      sys_clk   => sys_clk_f0,
      mmcm_clk  => mmcm_clk_f0
      );



  u200_iodelay_ctrl : iodelay_ctrl
    generic map(
      TCQ            => C0_TCQ,
      IODELAY_GRP    => IODELAY200_GRP,
      INPUT_CLK_TYPE => INPUT_CLK_TYPE,
      RST_ACT_LOW    => RST_ACT_LOW
      )
    port map(
      clk_ref_p        => clk200_ref_p,
      clk_ref_n        => clk200_ref_n,
      clk_ref          => clk200_ref,
      sys_rst          => sys_rst,
      iodelay_ctrl_rdy => iodelay200_ctrl_rdy
      );
   


  c0_u_infrastructure : infrastructure
    generic map(
      TCQ             => C0_TCQ,
      CLK_PERIOD      => SYSCLK_f0_PERIOD,
      nCK_PER_CLK     => nCK_PER_CLK_f0,
      CLKFBOUT_MULT_F => CLK_f0FBOUT_MULT_F,
      DIVCLK_DIVIDE   => DIVCLK_f0_DIVIDE,
      CLKOUT_DIVIDE   => CLK_f0OUT_DIVIDE,
      RST_ACT_LOW     => RST_ACT_LOW
      )
    port map(
      clk_mem          => c0_clk_mem,
      clk              => c0_clk,
      clk_rd_base      => c0_clk_rd_base,
      rstdiv0          => c0_rst,
      mmcm_clk         => mmcm_clk_f0,
      sys_rst          => sys_rst,
      iodelay_ctrl_rdy => iodelay200_ctrl_rdy,
      PSDONE           => c0_pd_PSDONE,
      PSEN             => c0_pd_PSEN,
      PSINCDEC         => c0_pd_PSINCDEC
      );

  c1_u_infrastructure : infrastructure
    generic map(
      TCQ             => C1_TCQ,
      CLK_PERIOD      => SYSCLK_f0_PERIOD,
      nCK_PER_CLK     => nCK_PER_CLK_f0,
      CLKFBOUT_MULT_F => CLK_f0FBOUT_MULT_F,
      DIVCLK_DIVIDE   => DIVCLK_f0_DIVIDE,
      CLKOUT_DIVIDE   => CLK_f0OUT_DIVIDE,
      RST_ACT_LOW     => RST_ACT_LOW
      )
    port map(
      clk_mem          => c1_clk_mem,
      clk              => c1_clk,
      clk_rd_base      => c1_clk_rd_base,
      rstdiv0          => c1_rst,
      mmcm_clk         => mmcm_clk_f0,
      sys_rst          => sys_rst,
      iodelay_ctrl_rdy => iodelay200_ctrl_rdy,
      PSDONE           => c1_pd_PSDONE,
      PSEN             => c1_pd_PSEN,
      PSINCDEC         => c1_pd_PSINCDEC
      );

  c2_u_infrastructure : infrastructure
    generic map(
      TCQ             => C2_TCQ,
      CLK_PERIOD      => SYSCLK_f0_PERIOD,
      nCK_PER_CLK     => nCK_PER_CLK_f0,
      CLKFBOUT_MULT_F => CLK_f0FBOUT_MULT_F,
      DIVCLK_DIVIDE   => DIVCLK_f0_DIVIDE,
      CLKOUT_DIVIDE   => CLK_f0OUT_DIVIDE,
      RST_ACT_LOW     => RST_ACT_LOW
      )
    port map(
      clk_mem          => c2_clk_mem,
      clk              => c2_clk,
      clk_rd_base      => c2_clk_rd_base,
      rstdiv0          => c2_rst,
      mmcm_clk         => mmcm_clk_f0,
      sys_rst          => sys_rst,
      iodelay_ctrl_rdy => iodelay200_ctrl_rdy,
      PSDONE           => c2_pd_PSDONE,
      PSEN             => c2_pd_PSEN,
      PSINCDEC         => c2_pd_PSINCDEC
      );

  c3_u_infrastructure : infrastructure
    generic map(
      TCQ             => C3_TCQ,
      CLK_PERIOD      => SYSCLK_f0_PERIOD,
      nCK_PER_CLK     => nCK_PER_CLK_f0,
      CLKFBOUT_MULT_F => CLK_f0FBOUT_MULT_F,
      DIVCLK_DIVIDE   => DIVCLK_f0_DIVIDE,
      CLKOUT_DIVIDE   => CLK_f0OUT_DIVIDE,
      RST_ACT_LOW     => RST_ACT_LOW
      )
    port map(
      clk_mem          => c3_clk_mem,
      clk              => c3_clk,
      clk_rd_base      => c3_clk_rd_base,
      rstdiv0          => c3_rst,
      mmcm_clk         => mmcm_clk_f0,
      sys_rst          => sys_rst,
      iodelay_ctrl_rdy => iodelay200_ctrl_rdy,
      PSDONE           => c3_pd_PSDONE,
      PSEN             => c3_pd_PSEN,
      PSINCDEC         => c3_pd_PSINCDEC
      );


  c0_u_memc_ui_top : c0_memc_ui_top
    generic map(
      ADDR_CMD_MODE       => C0_ADDR_CMD_MODE,
      BANK_WIDTH          => C0_BANK_WIDTH,
      CK_WIDTH            => C0_CK_WIDTH,
      CKE_WIDTH           => C0_CKE_WIDTH,
      nCK_PER_CLK         => nCK_PER_CLK_f0,
      COL_WIDTH           => C0_COL_WIDTH,
      CS_WIDTH            => C0_CS_WIDTH,
      DM_WIDTH        => C0_DM_WIDTH,
      nCS_PER_RANK        => C0_nCS_PER_RANK,
      DEBUG_PORT          => C0_DEBUG_PORT,
      IODELAY_GRP         => IODELAY200_GRP,
      DQ_WIDTH            => C0_DQ_WIDTH,
      DQS_WIDTH           => C0_DQS_WIDTH,
      DQS_CNT_WIDTH       => C0_DQS_CNT_WIDTH,
      ORDERING            => C0_ORDERING,
      OUTPUT_DRV          => C0_OUTPUT_DRV,
      PHASE_DETECT        => C0_PHASE_DETECT,
      RANK_WIDTH          => C0_RANK_WIDTH,
      REFCLK_FREQ         => REFCLK200_FREQ,
      REG_CTRL            => C0_REG_CTRL,
      ROW_WIDTH           => C0_ROW_WIDTH,
      RTT_NOM             => C0_RTT_NOM,
      RTT_WR              => C0_RTT_WR,
      SIM_CAL_OPTION      => C0_SIM_CAL_OPTION,
      SIM_INIT_OPTION     => C0_SIM_INIT_OPTION,
      SIM_BYPASS_INIT_CAL => C0_SIM_BYPASS_INIT_CAL,
      WRLVL               => C0_WRLVL,
      nDQS_COL0           => C0_nDQS_COL0,
      nDQS_COL1           => C0_nDQS_COL1,
      nDQS_COL2           => C0_nDQS_COL2,
      nDQS_COL3           => C0_nDQS_COL3,
      DQS_LOC_COL0        => C0_DQS_LOC_COL0,
      DQS_LOC_COL1        => C0_DQS_LOC_COL1,
      DQS_LOC_COL2        => C0_DQS_LOC_COL2,
      DQS_LOC_COL3        => C0_DQS_LOC_COL3,
      BURST_MODE          => C0_BURST_MODE,
      BM_CNT_WIDTH        => C0_BM_CNT_WIDTH,
      tCK                 => tCK_f0,
      tPRDI               => C0_tPRDI,
      tREFI               => C0_tREFI,
      tZQI                => C0_tZQI,
      ADDR_WIDTH          => C0_ADDR_WIDTH,
      TCQ                 => C0_TCQ,
      ECC_TEST            => C0_ECC_TEST,
      PAYLOAD_WIDTH       => C0_PAYLOAD_WIDTH
      )
    port map(
      clk                       => c0_clk,
      clk_mem                   => c0_clk_mem,
      clk_rd_base               => c0_clk_rd_base,
      rst                       => c0_rst,
      ddr_addr                  => c0_ddr3_addr,
      ddr_ba                    => c0_ddr3_ba,
      ddr_cas_n                 => c0_ddr3_cas_n,
      ddr_ck_n                  => c0_ddr3_ck_n,
      ddr_ck                    => c0_ddr3_ck_p,
      ddr_cke                   => c0_ddr3_cke,
      ddr_cs_n                  => c0_ddr3_cs_n,
      ddr_dm                    => c0_ddr3_dm,
      ddr_odt                   => c0_ddr3_odt,
      ddr_ras_n                 => c0_ddr3_ras_n,
      ddr_reset_n               => c0_ddr3_reset_n,
      ddr_parity                => c0_ddr3_parity,
      ddr_we_n                  => c0_ddr3_we_n,
      ddr_dq                    => c0_ddr3_dq,
      ddr_dqs_n                 => c0_ddr3_dqs_n,
      ddr_dqs                   => c0_ddr3_dqs_p,
      pd_PSEN                   => c0_pd_PSEN,
      pd_PSINCDEC               => c0_pd_PSINCDEC,
      pd_PSDONE                 => c0_pd_PSDONE,
      dfi_init_complete         => c0_dfi_init_complete,
      bank_mach_next            => c0_bank_mach_next,
      app_ecc_multiple_err      => c0_app_ecc_multiple_err_i,
      app_rd_data               => c0_app_rd_data,
      app_rd_data_end           => c0_app_rd_data_end,
      app_rd_data_valid         => c0_app_rd_data_valid,
      app_rdy                   => c0_app_rdy,
      app_wdf_rdy               => c0_app_wdf_rdy,
      app_addr                  => c0_app_addr,
      app_cmd                   => c0_app_cmd,
      app_en                    => c0_app_en,
      app_hi_pri                => c0_app_hi_pri,
      app_sz                    => '1',
      app_wdf_data              => c0_app_wdf_data,
      app_wdf_end               => c0_app_wdf_end,
      app_wdf_mask              => c0_app_wdf_mask,
      app_wdf_wren              => c0_app_wdf_wren,
      dbg_wr_dqs_tap_set        => c0_dbg_wr_dqs_tap_set,
      dbg_wr_dq_tap_set         => c0_dbg_wr_dq_tap_set,
      dbg_wr_tap_set_en         => c0_dbg_wr_tap_set_en,
      dbg_wrlvl_start           => c0_dbg_wrlvl_start,
      dbg_wrlvl_done            => c0_dbg_wrlvl_done,
      dbg_wrlvl_err             => c0_dbg_wrlvl_err,
      dbg_wl_dqs_inverted       => c0_dbg_wl_dqs_inverted,
      dbg_wr_calib_clk_delay    => c0_dbg_wr_calib_clk_delay,
      dbg_wl_odelay_dqs_tap_cnt => c0_dbg_wl_odelay_dqs_tap_cnt,
      dbg_wl_odelay_dq_tap_cnt  => c0_dbg_wl_odelay_dq_tap_cnt,
      dbg_rdlvl_start           => c0_dbg_rdlvl_start,
      dbg_rdlvl_done            => c0_dbg_rdlvl_done,
      dbg_rdlvl_err             => c0_dbg_rdlvl_err,
      dbg_cpt_tap_cnt           => c0_dbg_cpt_tap_cnt,
      dbg_cpt_first_edge_cnt    => c0_dbg_cpt_first_edge_cnt,
      dbg_cpt_second_edge_cnt   => c0_dbg_cpt_second_edge_cnt,
      dbg_rd_bitslip_cnt        => c0_dbg_rd_bitslip_cnt,
      dbg_rd_clkdly_cnt         => c0_dbg_rd_clkdly_cnt,
      dbg_rd_active_dly         => c0_dbg_rd_active_dly,
      dbg_pd_off                => c0_dbg_pd_off,
      dbg_pd_maintain_off       => c0_dbg_pd_maintain_off,
      dbg_pd_maintain_0_only    => c0_dbg_pd_maintain_0_only,
      dbg_inc_cpt               => c0_dbg_inc_cpt,
      dbg_dec_cpt               => c0_dbg_dec_cpt,
      dbg_inc_rd_dqs            => c0_dbg_inc_rd_dqs,
      dbg_dec_rd_dqs            => c0_dbg_dec_rd_dqs,
      dbg_inc_dec_sel           => c0_dbg_inc_dec_sel,
      dbg_inc_rd_fps            => c0_dbg_inc_rd_fps,
      dbg_dec_rd_fps            => c0_dbg_dec_rd_fps,
      dbg_dqs_tap_cnt           => c0_dbg_dqs_tap_cnt,
      dbg_dq_tap_cnt            => c0_dbg_dq_tap_cnt,
      dbg_rddata                => c0_dbg_rddata
      );

  c1_u_memc_ui_top : c1_memc_ui_top
    generic map(
      ADDR_CMD_MODE       => C1_ADDR_CMD_MODE,
      BANK_WIDTH          => C1_BANK_WIDTH,
      CK_WIDTH            => C1_CK_WIDTH,
      CKE_WIDTH           => C1_CKE_WIDTH,
      nCK_PER_CLK         => nCK_PER_CLK_f0,
      COL_WIDTH           => C1_COL_WIDTH,
      CS_WIDTH            => C1_CS_WIDTH,
      DM_WIDTH        => C1_DM_WIDTH,
      nCS_PER_RANK        => C1_nCS_PER_RANK,
      DEBUG_PORT          => C1_DEBUG_PORT,
      IODELAY_GRP         => IODELAY200_GRP,
      DQ_WIDTH            => C1_DQ_WIDTH,
      DQS_WIDTH           => C1_DQS_WIDTH,
      DQS_CNT_WIDTH       => C1_DQS_CNT_WIDTH,
      ORDERING            => C1_ORDERING,
      OUTPUT_DRV          => C1_OUTPUT_DRV,
      PHASE_DETECT        => C1_PHASE_DETECT,
      RANK_WIDTH          => C1_RANK_WIDTH,
      REFCLK_FREQ         => REFCLK200_FREQ,
      REG_CTRL            => C1_REG_CTRL,
      ROW_WIDTH           => C1_ROW_WIDTH,
      RTT_NOM             => C1_RTT_NOM,
      RTT_WR              => C1_RTT_WR,
      SIM_CAL_OPTION      => C1_SIM_CAL_OPTION,
      SIM_INIT_OPTION     => C1_SIM_INIT_OPTION,
      SIM_BYPASS_INIT_CAL => C1_SIM_BYPASS_INIT_CAL,
      WRLVL               => C1_WRLVL,
      nDQS_COL0           => C1_nDQS_COL0,
      nDQS_COL1           => C1_nDQS_COL1,
      nDQS_COL2           => C1_nDQS_COL2,
      nDQS_COL3           => C1_nDQS_COL3,
      DQS_LOC_COL0        => C1_DQS_LOC_COL0,
      DQS_LOC_COL1        => C1_DQS_LOC_COL1,
      DQS_LOC_COL2        => C1_DQS_LOC_COL2,
      DQS_LOC_COL3        => C1_DQS_LOC_COL3,
      BURST_MODE          => C1_BURST_MODE,
      BM_CNT_WIDTH        => C1_BM_CNT_WIDTH,
      tCK                 => tCK_f0,
      tPRDI               => C1_tPRDI,
      tREFI               => C1_tREFI,
      tZQI                => C1_tZQI,
      ADDR_WIDTH          => C1_ADDR_WIDTH,
      TCQ                 => C1_TCQ,
      ECC_TEST            => C1_ECC_TEST,
      PAYLOAD_WIDTH       => C1_PAYLOAD_WIDTH
      )
    port map(
      clk                       => c1_clk,
      clk_mem                   => c1_clk_mem,
      clk_rd_base               => c1_clk_rd_base,
      rst                       => c1_rst,
      ddr_addr                  => c1_ddr3_addr,
      ddr_ba                    => c1_ddr3_ba,
      ddr_cas_n                 => c1_ddr3_cas_n,
      ddr_ck_n                  => c1_ddr3_ck_n,
      ddr_ck                    => c1_ddr3_ck_p,
      ddr_cke                   => c1_ddr3_cke,
      ddr_cs_n                  => c1_ddr3_cs_n,
      ddr_dm                    => c1_ddr3_dm,
      ddr_odt                   => c1_ddr3_odt,
      ddr_ras_n                 => c1_ddr3_ras_n,
      ddr_reset_n               => c1_ddr3_reset_n,
      ddr_parity                => c1_ddr3_parity,
      ddr_we_n                  => c1_ddr3_we_n,
      ddr_dq                    => c1_ddr3_dq,
      ddr_dqs_n                 => c1_ddr3_dqs_n,
      ddr_dqs                   => c1_ddr3_dqs_p,
      pd_PSEN                   => c1_pd_PSEN,
      pd_PSINCDEC               => c1_pd_PSINCDEC,
      pd_PSDONE                 => c1_pd_PSDONE,
      dfi_init_complete         => c1_dfi_init_complete,
      bank_mach_next            => c1_bank_mach_next,
      app_ecc_multiple_err      => c1_app_ecc_multiple_err_i,
      app_rd_data               => c1_app_rd_data,
      app_rd_data_end           => c1_app_rd_data_end,
      app_rd_data_valid         => c1_app_rd_data_valid,
      app_rdy                   => c1_app_rdy,
      app_wdf_rdy               => c1_app_wdf_rdy,
      app_addr                  => c1_app_addr,
      app_cmd                   => c1_app_cmd,
      app_en                    => c1_app_en,
      app_hi_pri                => c1_app_hi_pri,
      app_sz                    => '1',
      app_wdf_data              => c1_app_wdf_data,
      app_wdf_end               => c1_app_wdf_end,
      app_wdf_mask              => c1_app_wdf_mask,
      app_wdf_wren              => c1_app_wdf_wren,
      dbg_wr_dqs_tap_set        => c1_dbg_wr_dqs_tap_set,
      dbg_wr_dq_tap_set         => c1_dbg_wr_dq_tap_set,
      dbg_wr_tap_set_en         => c1_dbg_wr_tap_set_en,
      dbg_wrlvl_start           => c1_dbg_wrlvl_start,
      dbg_wrlvl_done            => c1_dbg_wrlvl_done,
      dbg_wrlvl_err             => c1_dbg_wrlvl_err,
      dbg_wl_dqs_inverted       => c1_dbg_wl_dqs_inverted,
      dbg_wr_calib_clk_delay    => c1_dbg_wr_calib_clk_delay,
      dbg_wl_odelay_dqs_tap_cnt => c1_dbg_wl_odelay_dqs_tap_cnt,
      dbg_wl_odelay_dq_tap_cnt  => c1_dbg_wl_odelay_dq_tap_cnt,
      dbg_rdlvl_start           => c1_dbg_rdlvl_start,
      dbg_rdlvl_done            => c1_dbg_rdlvl_done,
      dbg_rdlvl_err             => c1_dbg_rdlvl_err,
      dbg_cpt_tap_cnt           => c1_dbg_cpt_tap_cnt,
      dbg_cpt_first_edge_cnt    => c1_dbg_cpt_first_edge_cnt,
      dbg_cpt_second_edge_cnt   => c1_dbg_cpt_second_edge_cnt,
      dbg_rd_bitslip_cnt        => c1_dbg_rd_bitslip_cnt,
      dbg_rd_clkdly_cnt         => c1_dbg_rd_clkdly_cnt,
      dbg_rd_active_dly         => c1_dbg_rd_active_dly,
      dbg_pd_off                => c1_dbg_pd_off,
      dbg_pd_maintain_off       => c1_dbg_pd_maintain_off,
      dbg_pd_maintain_0_only    => c1_dbg_pd_maintain_0_only,
      dbg_inc_cpt               => c1_dbg_inc_cpt,
      dbg_dec_cpt               => c1_dbg_dec_cpt,
      dbg_inc_rd_dqs            => c1_dbg_inc_rd_dqs,
      dbg_dec_rd_dqs            => c1_dbg_dec_rd_dqs,
      dbg_inc_dec_sel           => c1_dbg_inc_dec_sel,
      dbg_inc_rd_fps            => c1_dbg_inc_rd_fps,
      dbg_dec_rd_fps            => c1_dbg_dec_rd_fps,
      dbg_dqs_tap_cnt           => c1_dbg_dqs_tap_cnt,
      dbg_dq_tap_cnt            => c1_dbg_dq_tap_cnt,
      dbg_rddata                => c1_dbg_rddata
      );

  c2_u_memc_ui_top : c2_memc_ui_top
    generic map(
      ADDR_CMD_MODE       => C2_ADDR_CMD_MODE,
      BANK_WIDTH          => C2_BANK_WIDTH,
      CK_WIDTH            => C2_CK_WIDTH,
      CKE_WIDTH           => C2_CKE_WIDTH,
      nCK_PER_CLK         => nCK_PER_CLK_f0,
      COL_WIDTH           => C2_COL_WIDTH,
      CS_WIDTH            => C2_CS_WIDTH,
      DM_WIDTH        => C2_DM_WIDTH,
      nCS_PER_RANK        => C2_nCS_PER_RANK,
      DEBUG_PORT          => C2_DEBUG_PORT,
      IODELAY_GRP         => IODELAY200_GRP,
      DQ_WIDTH            => C2_DQ_WIDTH,
      DQS_WIDTH           => C2_DQS_WIDTH,
      DQS_CNT_WIDTH       => C2_DQS_CNT_WIDTH,
      ORDERING            => C2_ORDERING,
      OUTPUT_DRV          => C2_OUTPUT_DRV,
      PHASE_DETECT        => C2_PHASE_DETECT,
      RANK_WIDTH          => C2_RANK_WIDTH,
      REFCLK_FREQ         => REFCLK200_FREQ,
      REG_CTRL            => C2_REG_CTRL,
      ROW_WIDTH           => C2_ROW_WIDTH,
      RTT_NOM             => C2_RTT_NOM,
      RTT_WR              => C2_RTT_WR,
      SIM_CAL_OPTION      => C2_SIM_CAL_OPTION,
      SIM_INIT_OPTION     => C2_SIM_INIT_OPTION,
      SIM_BYPASS_INIT_CAL => C2_SIM_BYPASS_INIT_CAL,
      WRLVL               => C2_WRLVL,
      nDQS_COL0           => C2_nDQS_COL0,
      nDQS_COL1           => C2_nDQS_COL1,
      nDQS_COL2           => C2_nDQS_COL2,
      nDQS_COL3           => C2_nDQS_COL3,
      DQS_LOC_COL0        => C2_DQS_LOC_COL0,
      DQS_LOC_COL1        => C2_DQS_LOC_COL1,
      DQS_LOC_COL2        => C2_DQS_LOC_COL2,
      DQS_LOC_COL3        => C2_DQS_LOC_COL3,
      BURST_MODE          => C2_BURST_MODE,
      BM_CNT_WIDTH        => C2_BM_CNT_WIDTH,
      tCK                 => tCK_f0,
      tPRDI               => C2_tPRDI,
      tREFI               => C2_tREFI,
      tZQI                => C2_tZQI,
      ADDR_WIDTH          => C2_ADDR_WIDTH,
      TCQ                 => C2_TCQ,
      ECC_TEST            => C2_ECC_TEST,
      PAYLOAD_WIDTH       => C2_PAYLOAD_WIDTH
      )
    port map(
      clk                       => c2_clk,
      clk_mem                   => c2_clk_mem,
      clk_rd_base               => c2_clk_rd_base,
      rst                       => c2_rst,
      ddr_addr                  => c2_ddr3_addr,
      ddr_ba                    => c2_ddr3_ba,
      ddr_cas_n                 => c2_ddr3_cas_n,
      ddr_ck_n                  => c2_ddr3_ck_n,
      ddr_ck                    => c2_ddr3_ck_p,
      ddr_cke                   => c2_ddr3_cke,
      ddr_cs_n                  => c2_ddr3_cs_n,
      ddr_dm                    => c2_ddr3_dm,
      ddr_odt                   => c2_ddr3_odt,
      ddr_ras_n                 => c2_ddr3_ras_n,
      ddr_reset_n               => c2_ddr3_reset_n,
      ddr_parity                => c2_ddr3_parity,
      ddr_we_n                  => c2_ddr3_we_n,
      ddr_dq                    => c2_ddr3_dq,
      ddr_dqs_n                 => c2_ddr3_dqs_n,
      ddr_dqs                   => c2_ddr3_dqs_p,
      pd_PSEN                   => c2_pd_PSEN,
      pd_PSINCDEC               => c2_pd_PSINCDEC,
      pd_PSDONE                 => c2_pd_PSDONE,
      dfi_init_complete         => c2_dfi_init_complete,
      bank_mach_next            => c2_bank_mach_next,
      app_ecc_multiple_err      => c2_app_ecc_multiple_err_i,
      app_rd_data               => c2_app_rd_data,
      app_rd_data_end           => c2_app_rd_data_end,
      app_rd_data_valid         => c2_app_rd_data_valid,
      app_rdy                   => c2_app_rdy,
      app_wdf_rdy               => c2_app_wdf_rdy,
      app_addr                  => c2_app_addr,
      app_cmd                   => c2_app_cmd,
      app_en                    => c2_app_en,
      app_hi_pri                => c2_app_hi_pri,
      app_sz                    => '1',
      app_wdf_data              => c2_app_wdf_data,
      app_wdf_end               => c2_app_wdf_end,
      app_wdf_mask              => c2_app_wdf_mask,
      app_wdf_wren              => c2_app_wdf_wren,
      dbg_wr_dqs_tap_set        => c2_dbg_wr_dqs_tap_set,
      dbg_wr_dq_tap_set         => c2_dbg_wr_dq_tap_set,
      dbg_wr_tap_set_en         => c2_dbg_wr_tap_set_en,
      dbg_wrlvl_start           => c2_dbg_wrlvl_start,
      dbg_wrlvl_done            => c2_dbg_wrlvl_done,
      dbg_wrlvl_err             => c2_dbg_wrlvl_err,
      dbg_wl_dqs_inverted       => c2_dbg_wl_dqs_inverted,
      dbg_wr_calib_clk_delay    => c2_dbg_wr_calib_clk_delay,
      dbg_wl_odelay_dqs_tap_cnt => c2_dbg_wl_odelay_dqs_tap_cnt,
      dbg_wl_odelay_dq_tap_cnt  => c2_dbg_wl_odelay_dq_tap_cnt,
      dbg_rdlvl_start           => c2_dbg_rdlvl_start,
      dbg_rdlvl_done            => c2_dbg_rdlvl_done,
      dbg_rdlvl_err             => c2_dbg_rdlvl_err,
      dbg_cpt_tap_cnt           => c2_dbg_cpt_tap_cnt,
      dbg_cpt_first_edge_cnt    => c2_dbg_cpt_first_edge_cnt,
      dbg_cpt_second_edge_cnt   => c2_dbg_cpt_second_edge_cnt,
      dbg_rd_bitslip_cnt        => c2_dbg_rd_bitslip_cnt,
      dbg_rd_clkdly_cnt         => c2_dbg_rd_clkdly_cnt,
      dbg_rd_active_dly         => c2_dbg_rd_active_dly,
      dbg_pd_off                => c2_dbg_pd_off,
      dbg_pd_maintain_off       => c2_dbg_pd_maintain_off,
      dbg_pd_maintain_0_only    => c2_dbg_pd_maintain_0_only,
      dbg_inc_cpt               => c2_dbg_inc_cpt,
      dbg_dec_cpt               => c2_dbg_dec_cpt,
      dbg_inc_rd_dqs            => c2_dbg_inc_rd_dqs,
      dbg_dec_rd_dqs            => c2_dbg_dec_rd_dqs,
      dbg_inc_dec_sel           => c2_dbg_inc_dec_sel,
      dbg_inc_rd_fps            => c2_dbg_inc_rd_fps,
      dbg_dec_rd_fps            => c2_dbg_dec_rd_fps,
      dbg_dqs_tap_cnt           => c2_dbg_dqs_tap_cnt,
      dbg_dq_tap_cnt            => c2_dbg_dq_tap_cnt,
      dbg_rddata                => c2_dbg_rddata
      );

  c3_u_memc_ui_top : c3_memc_ui_top
    generic map(
      ADDR_CMD_MODE       => C3_ADDR_CMD_MODE,
      BANK_WIDTH          => C3_BANK_WIDTH,
      CK_WIDTH            => C3_CK_WIDTH,
      CKE_WIDTH           => C3_CKE_WIDTH,
      nCK_PER_CLK         => nCK_PER_CLK_f0,
      COL_WIDTH           => C3_COL_WIDTH,
      CS_WIDTH            => C3_CS_WIDTH,
      DM_WIDTH        => C3_DM_WIDTH,
      nCS_PER_RANK        => C3_nCS_PER_RANK,
      DEBUG_PORT          => C3_DEBUG_PORT,
      IODELAY_GRP         => IODELAY200_GRP,
      DQ_WIDTH            => C3_DQ_WIDTH,
      DQS_WIDTH           => C3_DQS_WIDTH,
      DQS_CNT_WIDTH       => C3_DQS_CNT_WIDTH,
      ORDERING            => C3_ORDERING,
      OUTPUT_DRV          => C3_OUTPUT_DRV,
      PHASE_DETECT        => C3_PHASE_DETECT,
      RANK_WIDTH          => C3_RANK_WIDTH,
      REFCLK_FREQ         => REFCLK200_FREQ,
      REG_CTRL            => C3_REG_CTRL,
      ROW_WIDTH           => C3_ROW_WIDTH,
      RTT_NOM             => C3_RTT_NOM,
      RTT_WR              => C3_RTT_WR,
      SIM_CAL_OPTION      => C3_SIM_CAL_OPTION,
      SIM_INIT_OPTION     => C3_SIM_INIT_OPTION,
      SIM_BYPASS_INIT_CAL => C3_SIM_BYPASS_INIT_CAL,
      WRLVL               => C3_WRLVL,
      nDQS_COL0           => C3_nDQS_COL0,
      nDQS_COL1           => C3_nDQS_COL1,
      nDQS_COL2           => C3_nDQS_COL2,
      nDQS_COL3           => C3_nDQS_COL3,
      DQS_LOC_COL0        => C3_DQS_LOC_COL0,
      DQS_LOC_COL1        => C3_DQS_LOC_COL1,
      DQS_LOC_COL2        => C3_DQS_LOC_COL2,
      DQS_LOC_COL3        => C3_DQS_LOC_COL3,
      BURST_MODE          => C3_BURST_MODE,
      BM_CNT_WIDTH        => C3_BM_CNT_WIDTH,
      tCK                 => tCK_f0,
      tPRDI               => C3_tPRDI,
      tREFI               => C3_tREFI,
      tZQI                => C3_tZQI,
      ADDR_WIDTH          => C3_ADDR_WIDTH,
      TCQ                 => C3_TCQ,
      ECC_TEST            => C3_ECC_TEST,
      PAYLOAD_WIDTH       => C3_PAYLOAD_WIDTH
      )
    port map(
      clk                       => c3_clk,
      clk_mem                   => c3_clk_mem,
      clk_rd_base               => c3_clk_rd_base,
      rst                       => c3_rst,
      ddr_addr                  => c3_ddr3_addr,
      ddr_ba                    => c3_ddr3_ba,
      ddr_cas_n                 => c3_ddr3_cas_n,
      ddr_ck_n                  => c3_ddr3_ck_n,
      ddr_ck                    => c3_ddr3_ck_p,
      ddr_cke                   => c3_ddr3_cke,
      ddr_cs_n                  => c3_ddr3_cs_n,
      ddr_dm                    => c3_ddr3_dm,
      ddr_odt                   => c3_ddr3_odt,
      ddr_ras_n                 => c3_ddr3_ras_n,
      ddr_reset_n               => c3_ddr3_reset_n,
      ddr_parity                => c3_ddr3_parity,
      ddr_we_n                  => c3_ddr3_we_n,
      ddr_dq                    => c3_ddr3_dq,
      ddr_dqs_n                 => c3_ddr3_dqs_n,
      ddr_dqs                   => c3_ddr3_dqs_p,
      pd_PSEN                   => c3_pd_PSEN,
      pd_PSINCDEC               => c3_pd_PSINCDEC,
      pd_PSDONE                 => c3_pd_PSDONE,
      dfi_init_complete         => c3_dfi_init_complete,
      bank_mach_next            => c3_bank_mach_next,
      app_ecc_multiple_err      => c3_app_ecc_multiple_err_i,
      app_rd_data               => c3_app_rd_data,
      app_rd_data_end           => c3_app_rd_data_end,
      app_rd_data_valid         => c3_app_rd_data_valid,
      app_rdy                   => c3_app_rdy,
      app_wdf_rdy               => c3_app_wdf_rdy,
      app_addr                  => c3_app_addr,
      app_cmd                   => c3_app_cmd,
      app_en                    => c3_app_en,
      app_hi_pri                => c3_app_hi_pri,
      app_sz                    => '1',
      app_wdf_data              => c3_app_wdf_data,
      app_wdf_end               => c3_app_wdf_end,
      app_wdf_mask              => c3_app_wdf_mask,
      app_wdf_wren              => c3_app_wdf_wren,
      dbg_wr_dqs_tap_set        => c3_dbg_wr_dqs_tap_set,
      dbg_wr_dq_tap_set         => c3_dbg_wr_dq_tap_set,
      dbg_wr_tap_set_en         => c3_dbg_wr_tap_set_en,
      dbg_wrlvl_start           => c3_dbg_wrlvl_start,
      dbg_wrlvl_done            => c3_dbg_wrlvl_done,
      dbg_wrlvl_err             => c3_dbg_wrlvl_err,
      dbg_wl_dqs_inverted       => c3_dbg_wl_dqs_inverted,
      dbg_wr_calib_clk_delay    => c3_dbg_wr_calib_clk_delay,
      dbg_wl_odelay_dqs_tap_cnt => c3_dbg_wl_odelay_dqs_tap_cnt,
      dbg_wl_odelay_dq_tap_cnt  => c3_dbg_wl_odelay_dq_tap_cnt,
      dbg_rdlvl_start           => c3_dbg_rdlvl_start,
      dbg_rdlvl_done            => c3_dbg_rdlvl_done,
      dbg_rdlvl_err             => c3_dbg_rdlvl_err,
      dbg_cpt_tap_cnt           => c3_dbg_cpt_tap_cnt,
      dbg_cpt_first_edge_cnt    => c3_dbg_cpt_first_edge_cnt,
      dbg_cpt_second_edge_cnt   => c3_dbg_cpt_second_edge_cnt,
      dbg_rd_bitslip_cnt        => c3_dbg_rd_bitslip_cnt,
      dbg_rd_clkdly_cnt         => c3_dbg_rd_clkdly_cnt,
      dbg_rd_active_dly         => c3_dbg_rd_active_dly,
      dbg_pd_off                => c3_dbg_pd_off,
      dbg_pd_maintain_off       => c3_dbg_pd_maintain_off,
      dbg_pd_maintain_0_only    => c3_dbg_pd_maintain_0_only,
      dbg_inc_cpt               => c3_dbg_inc_cpt,
      dbg_dec_cpt               => c3_dbg_dec_cpt,
      dbg_inc_rd_dqs            => c3_dbg_inc_rd_dqs,
      dbg_dec_rd_dqs            => c3_dbg_dec_rd_dqs,
      dbg_inc_dec_sel           => c3_dbg_inc_dec_sel,
      dbg_inc_rd_fps            => c3_dbg_inc_rd_fps,
      dbg_dec_rd_fps            => c3_dbg_dec_rd_fps,
      dbg_dqs_tap_cnt           => c3_dbg_dqs_tap_cnt,
      dbg_dq_tap_cnt            => c3_dbg_dq_tap_cnt,
      dbg_rddata                => c3_dbg_rddata
      );







  -- If debug port is not enabled, then make certain control input
  -- to Debug Port are disabled
  c0_gen_dbg_tie_off : if (C0_DEBUG_PORT = "OFF") generate
    c0_dbg_wr_dqs_tap_set     <= (others => '0');
    c0_dbg_wr_dq_tap_set      <= (others => '0');
    c0_dbg_wr_tap_set_en      <= '0';
    c0_dbg_pd_off             <= '0';
    c0_dbg_pd_maintain_off    <= '0';
    c0_dbg_pd_maintain_0_only <= '0';
    c0_dbg_ocb_mon_off        <= '0';
    c0_dbg_inc_cpt            <= '0';
    c0_dbg_dec_cpt            <= '0';
    c0_dbg_inc_rd_dqs         <= '0';
    c0_dbg_dec_rd_dqs         <= '0';
    c0_dbg_inc_dec_sel        <= (others => '0');
    c0_dbg_inc_rd_fps         <= '0';
    c0_dbg_pd_msb_sel         <= (others => '0');
    c0_dbg_sel_idel_cpt       <= (others => '0');	 
    c0_dbg_sel_idel_rsync     <= (others => '0');
    c0_dbg_pd_byte_sel        <= (others => '0');	
    c0_dbg_dec_rd_fps         <= '0';
  end generate c0_gen_dbg_tie_off;

  c0_gen_dbg_enable : if (C0_DEBUG_PORT = "ON") generate

    -- Connect these to VIO if changing output (write) 
    -- IODELAY taps desired 
    c0_dbg_wr_dqs_tap_set     <= (others => '0');
    c0_dbg_wr_dq_tap_set      <= (others => '0');
    c0_dbg_wr_tap_set_en      <= '0';

    -- Connect these to VIO if changing read base clock
    -- phase required
    c0_dbg_inc_rd_fps         <= '0';
    c0_dbg_dec_rd_fps         <= '0';

    --*******************************************************
    -- CS0 - ILA for monitoring PHY status, testbench error,
    --       and synchronized read data
    --*******************************************************

    -- Assignments for ILA monitoring general PHY
    -- status and synchronized read data
    ddr3_cs0_clk              <= c0_clk;
    ddr3_cs0_trig(1 downto 0) <= c0_dbg_rdlvl_done;
    ddr3_cs0_trig(3 downto 2) <= c0_dbg_rdlvl_err;
    ddr3_cs0_trig(4)          <= c0_dfi_init_complete;
    ddr3_cs0_trig(5)          <= '0';  -- Reserve for ERROR from TrafficGen
    ddr3_cs0_trig(7 downto 5) <= (others => '0');

    -- Support for only up to 72-bits of data
    c0_gen_dq_le_72 : if (C0_DQ_WIDTH <= 72) generate
      ddr3_cs0_data(4*C0_DQ_WIDTH-1 downto 0) <= c0_dbg_rddata;
    end generate c0_gen_dq_le_72;

    c0_gen_dq_gt_72 : if (C0_DQ_WIDTH > 72) generate
      ddr3_cs0_data(287 downto 0) <= c0_dbg_rddata(287 downto 0);
    end generate c0_gen_dq_gt_72;

    ddr3_cs0_data(289 downto 288) <= c0_dbg_rdlvl_done;
    ddr3_cs0_data(291 downto 290) <= c0_dbg_rdlvl_err;
    ddr3_cs0_data(292)            <= c0_dfi_init_complete;
    ddr3_cs0_data(293)            <= '0'; -- Reserve for ERROR from TrafficGen
    ddr3_cs0_data(383 downto 294) <= (others => '0');

    --*******************************************************
    -- CS1 - Input VIO for monitoring PHY status and
    --       write leveling/calibration delays
    --*******************************************************

    -- Support for only up to 18 DQS groups
    c0_gen_dqs_le_18_cs1 : if (C0_DQS_WIDTH <= 18) generate
      ddr3_cs1_async_in(5*C0_DQS_WIDTH-1 downto 0)     <= c0_dbg_wl_odelay_dq_tap_cnt;
      ddr3_cs1_async_in(5*C0_DQS_WIDTH+89 downto 90)   <= c0_dbg_wl_odelay_dqs_tap_cnt;
      ddr3_cs1_async_in(C0_DQS_WIDTH+179 downto 180)   <= c0_dbg_wl_dqs_inverted;
      ddr3_cs1_async_in(2*C0_DQS_WIDTH+197 downto 198) <= c0_dbg_wr_calib_clk_delay;
    end generate c0_gen_dqs_le_18_cs1;

    c0_gen_dqs_gt_18_cs1 : if (C0_DQS_WIDTH > 18) generate
      ddr3_cs1_async_in(89 downto 0)    <= c0_dbg_wl_odelay_dq_tap_cnt(89 downto 0);
      ddr3_cs1_async_in(179 downto 90)  <= c0_dbg_wl_odelay_dqs_tap_cnt(89 downto 0);
      ddr3_cs1_async_in(197 downto 180) <= c0_dbg_wl_dqs_inverted(17 downto 0);
      ddr3_cs1_async_in(233 downto 198) <= c0_dbg_wr_calib_clk_delay(35 downto 0);
    end generate c0_gen_dqs_gt_18_cs1;

    ddr3_cs1_async_in(235 downto 234) <= c0_dbg_rdlvl_done(1 downto 0);
    ddr3_cs1_async_in(237 downto 236) <= c0_dbg_rdlvl_err(1 downto 0);
    ddr3_cs1_async_in(238)            <= c0_dfi_init_complete;
    ddr3_cs1_async_in(239)            <= '0'; -- Pre-MIG 3.4: Used for rst_pll_ck_fb
    ddr3_cs1_async_in(240)            <= '0'; -- Reserve for ERROR from TrafficGen
    ddr3_cs1_async_in(255 downto 241) <= (others => '0');

    --*******************************************************
    -- CS2 - Input VIO for monitoring Read Calibration
    --       results.
    --*******************************************************

    -- Support for only up to 18 DQS groups
    c0_gen_dqs_le_18_cs2 : if (C0_DQS_WIDTH <= 18) generate
      ddr3_cs2_async_in(5*C0_DQS_WIDTH-1 downto 0)     <= c0_dbg_cpt_tap_cnt;
      -- Reserved for future monitoring of DQ tap counts from read leveling
      ddr3_cs2_async_in(5*C0_DQS_WIDTH+89 downto 90)   <= (others => '0');
      ddr3_cs2_async_in(3*C0_DQS_WIDTH+179 downto 180) <= c0_dbg_rd_bitslip_cnt;
    end generate c0_gen_dqs_le_18_cs2;

    c0_gen_dqs_gt_18_cs2 : if (C0_DQS_WIDTH > 18) generate
      ddr3_cs2_async_in(89 downto 0)    <= c0_dbg_cpt_tap_cnt(89 downto 0);
      -- Reserved for future monitoring of DQ tap counts from read leveling
      ddr3_cs2_async_in(179 downto 90)  <= (others => '0');
      ddr3_cs2_async_in(233 downto 180) <= c0_dbg_rd_bitslip_cnt(53 downto 0);
    end generate c0_gen_dqs_gt_18_cs2;

    ddr3_cs2_async_in(238 downto 234) <= c0_dbg_rd_active_dly;
    ddr3_cs2_async_in(255 downto 239) <= (others => '0');

    --*******************************************************
    -- CS3 - Input VIO for monitoring more Read Calibration
    --       results.
    --*******************************************************

    -- Support for only up to 18 DQS groups
    c0_gen_dqs_le_18_cs3 : if (C0_DQS_WIDTH <= 18) generate
      ddr3_cs3_async_in(5*C0_DQS_WIDTH-1 downto 0)     <= c0_dbg_cpt_first_edge_cnt;
      ddr3_cs3_async_in(5*C0_DQS_WIDTH+89 downto 90)   <= c0_dbg_cpt_second_edge_cnt;
      ddr3_cs3_async_in(2*C0_DQS_WIDTH+179 downto 180) <= c0_dbg_rd_clkdly_cnt;
    end generate c0_gen_dqs_le_18_cs3;

    c0_gen_dqs_gt_18_cs3 : if (C0_DQS_WIDTH > 18) generate
      ddr3_cs3_async_in(89 downto 0)    <= c0_dbg_cpt_first_edge_cnt(89 downto 0);
      ddr3_cs3_async_in(179 downto 90)  <= c0_dbg_cpt_second_edge_cnt(89 downto 0);
      ddr3_cs3_async_in(215 downto 180) <= c0_dbg_rd_clkdly_cnt(35 downto 0);
    end generate c0_gen_dqs_gt_18_cs3;

    ddr3_cs3_async_in(255 downto 216) <= (others => '0');

    --*******************************************************
    -- CS4 - Output VIO for disabling OCB monitor, Read Phase
    --       Detector, and dynamically changing various
    --       IODELAY values used for adjust read data capture
    --       timing
    --*******************************************************

    ddr3_cs4_clk                               <= c0_clk;
    c0_dbg_pd_off             <= ddr3_cs4_sync_out(0);
    c0_dbg_pd_maintain_off    <= ddr3_cs4_sync_out(1);
    c0_dbg_pd_maintain_0_only <= ddr3_cs4_sync_out(2);
    c0_dbg_ocb_mon_off        <= ddr3_cs4_sync_out(3);
    c0_dbg_inc_cpt            <= ddr3_cs4_sync_out(4);
    c0_dbg_dec_cpt            <= ddr3_cs4_sync_out(5);
    c0_dbg_inc_rd_dqs         <= ddr3_cs4_sync_out(6);
    c0_dbg_dec_rd_dqs         <= ddr3_cs4_sync_out(7);
    c0_dbg_inc_dec_sel        <= ddr3_cs4_sync_out(C0_DQS_CNT_WIDTH+7 downto 8);

    u_c0_icon : icon5
      port map(
        CONTROL0 => ddr3_cs0_control,
        CONTROL1 => ddr3_cs1_control,
        CONTROL2 => ddr3_cs2_control,
        CONTROL3 => ddr3_cs3_control,
        CONTROL4 => ddr3_cs4_control
        );

    u_c0_cs0 : ila384_8
      port map(
        CLK     => ddr3_cs0_clk,
        DATA    => ddr3_cs0_data,
        TRIG0   => ddr3_cs0_trig,
        CONTROL => ddr3_cs0_control
        );

    u_c0_cs1 : vio_async_in256
      port map(
        ASYNC_IN => ddr3_cs1_async_in,
        CONTROL  => ddr3_cs1_control
        );

    u_c0_cs2 : vio_async_in256
      port map(
        ASYNC_IN => ddr3_cs2_async_in,
        CONTROL  => ddr3_cs2_control
        );

    u_c0_cs3 : vio_async_in256
      port map(
        ASYNC_IN => ddr3_cs3_async_in,
        CONTROL  => ddr3_cs3_control
        );

    u_c0_cs4 : vio_sync_out32
      port map(
        SYNC_OUT => ddr3_cs4_sync_out,
        CLK      => ddr3_cs4_clk,
        CONTROL  => ddr3_cs4_control
        );

  end generate c0_gen_dbg_enable;

  -- If debug port is not enabled, then make certain control input
  -- to Debug Port are disabled
  c1_gen_dbg_tie_off : if (C1_DEBUG_PORT = "OFF") generate
    c1_dbg_wr_dqs_tap_set     <= (others => '0');
    c1_dbg_wr_dq_tap_set      <= (others => '0');
    c1_dbg_wr_tap_set_en      <= '0';
    c1_dbg_pd_off             <= '0';
    c1_dbg_pd_maintain_off    <= '0';
    c1_dbg_pd_maintain_0_only <= '0';
    c1_dbg_ocb_mon_off        <= '0';
    c1_dbg_inc_cpt            <= '0';
    c1_dbg_dec_cpt            <= '0';
    c1_dbg_inc_rd_dqs         <= '0';
    c1_dbg_dec_rd_dqs         <= '0';
    c1_dbg_inc_dec_sel        <= (others => '0');
    c1_dbg_inc_rd_fps         <= '0';
    c1_dbg_pd_msb_sel         <= (others => '0');
    c1_dbg_sel_idel_cpt       <= (others => '0');	 
    c1_dbg_sel_idel_rsync     <= (others => '0');
    c1_dbg_pd_byte_sel        <= (others => '0');	
    c1_dbg_dec_rd_fps         <= '0';
  end generate c1_gen_dbg_tie_off;


  -- If debug port is not enabled, then make certain control input
  -- to Debug Port are disabled
  c2_gen_dbg_tie_off : if (C2_DEBUG_PORT = "OFF") generate
    c2_dbg_wr_dqs_tap_set     <= (others => '0');
    c2_dbg_wr_dq_tap_set      <= (others => '0');
    c2_dbg_wr_tap_set_en      <= '0';
    c2_dbg_pd_off             <= '0';
    c2_dbg_pd_maintain_off    <= '0';
    c2_dbg_pd_maintain_0_only <= '0';
    c2_dbg_ocb_mon_off        <= '0';
    c2_dbg_inc_cpt            <= '0';
    c2_dbg_dec_cpt            <= '0';
    c2_dbg_inc_rd_dqs         <= '0';
    c2_dbg_dec_rd_dqs         <= '0';
    c2_dbg_inc_dec_sel        <= (others => '0');
    c2_dbg_inc_rd_fps         <= '0';
    c2_dbg_pd_msb_sel         <= (others => '0');
    c2_dbg_sel_idel_cpt       <= (others => '0');	 
    c2_dbg_sel_idel_rsync     <= (others => '0');
    c2_dbg_pd_byte_sel        <= (others => '0');	
    c2_dbg_dec_rd_fps         <= '0';
  end generate c2_gen_dbg_tie_off;


  -- If debug port is not enabled, then make certain control input
  -- to Debug Port are disabled
  c3_gen_dbg_tie_off : if (C3_DEBUG_PORT = "OFF") generate
    c3_dbg_wr_dqs_tap_set     <= (others => '0');
    c3_dbg_wr_dq_tap_set      <= (others => '0');
    c3_dbg_wr_tap_set_en      <= '0';
    c3_dbg_pd_off             <= '0';
    c3_dbg_pd_maintain_off    <= '0';
    c3_dbg_pd_maintain_0_only <= '0';
    c3_dbg_ocb_mon_off        <= '0';
    c3_dbg_inc_cpt            <= '0';
    c3_dbg_dec_cpt            <= '0';
    c3_dbg_inc_rd_dqs         <= '0';
    c3_dbg_dec_rd_dqs         <= '0';
    c3_dbg_inc_dec_sel        <= (others => '0');
    c3_dbg_inc_rd_fps         <= '0';
    c3_dbg_pd_msb_sel         <= (others => '0');
    c3_dbg_sel_idel_cpt       <= (others => '0');	 
    c3_dbg_sel_idel_rsync     <= (others => '0');
    c3_dbg_pd_byte_sel        <= (others => '0');	
    c3_dbg_dec_rd_fps         <= '0';
  end generate c3_gen_dbg_tie_off;



end architecture arch_mig_v3_6;
