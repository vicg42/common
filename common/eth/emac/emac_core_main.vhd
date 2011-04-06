-------------------------------------------------------------------------------
-- Title      : Virtex-5 Ethernet MAC Example Design Wrapper
-- Project    : Virtex-5 Ethernet MAC Wrappers
-------------------------------------------------------------------------------
-- File       : emac_top.vhd
-------------------------------------------------------------------------------
-- Copyright (c) 2004-2008 by Xilinx, Inc. All rights reserved.
-- This text/file contains proprietary, confidential
-- information of Xilinx, Inc., is distributed under license
-- from Xilinx, Inc., and may be used, copied and/or
-- disclosed only pursuant to the terms of a valid license
-- agreement with Xilinx, Inc. Xilinx hereby grants you
-- a license to use this text/file solely for design, simulation,
-- implementation and creation of design files limited
-- to Xilinx devices or technologies. Use with non-Xilinx
-- devices or technologies is expressly prohibited and
-- immediately terminates your license unless covered by
-- a separate agreement.
--
-- Xilinx is providing this design, code, or information
-- "as is" solely for use in developing programs and
-- solutions for Xilinx devices. By providing this design,
-- code, or information as one possible implementation of
-- this feature, application or standard, Xilinx is making no
-- representation that this implementation is free from any
-- claims of infringement. You are responsible for
-- obtaining any rights you may require for your implementation.
-- Xilinx expressly disclaims any warranty whatsoever with
-- respect to the adequacy of the implementation, including
-- but not limited to any warranties or representations that this
-- implementation is free from claims of infringement, implied
-- warranties of merchantability or fitness for a particular
-- purpose.
--
-- Xilinx products are not intended for use in life support
-- appliances, devices, or systems. Use in such applications are
-- expressly prohibited.
--
-- This copyright and support notice must be retained as part
-- of this text at all times. (c) Copyright 2004-2008 Xilinx, Inc.
-- All rights reserved.

-------------------------------------------------------------------------------
-- Description:  This is the VHDL example design for the Virtex-5
--               Embedded Ethernet MAC.  It is intended that
--               this example design can be quickly adapted and downloaded onto
--               an FPGA to provide a real hardware test environment.
--
--               This level:
--
--               * instantiates the TEMAC local link file that instantiates
--                 the TEMAC top level together with a RX and TX FIFO with a
--                 local link interface;
--
--               * instantiates a simple client I/F side example design,
--                 providing an address swap and a simple
--                 loopback function;
--
--               * Instantiates IBUFs on the GTX_CLK, REFCLK and HOSTCLK inputs
--                 if required;
--
--               Please refer to the Datasheet, Getting Started Guide, and
--               the Virtex-5 Embedded Tri-Mode Ethernet MAC User Gude for
--               further information.
--
--
--
--    ---------------------------------------------------------------------
--    | emac_core_main.vhd                                                |
--    |           --------------------------------------------------------|
--    |           |emac_core_locallink.vhd                                |
--    |           |              -----------------------------------------|
--    |           |              |emac_core_block.vhd                     |
--    |           |              |    ---------------------               |
--    |           |  ----------  |    | ETHERNET MAC      |               |
--    |           |  |        |  |    | emac_core.vhd     |  ---------    |
--    ----------->|->|        |--|--->| Tx            Tx  |--|       |--->|
--    |           |  | client |  |    | client        PHY |  |       |    |
--    |           |  | side   |  |    | I/F           I/F |  |       |    |
--    |           |  | FIFO   |  |    |                   |  |       |    |
--    |           |  |        |  |    |                   |  |       |    |
--    |           |  | (LOCAL |  |    |                   |  |       |    |
--    |           |  |  LINK  |  |    |                   |  | PHY   |    |
--    |           |  |  FIFO) |  |    |                   |  | I/F   |    |
--    |           |  |        |  |    |                   |  |       |    |
--    |           |  |        |  |    | Rx            Rx  |  |       |    |
--    |           |  |        |  |    | client        PHY |  |       |    |
--    <-----------|<-|        |<-|----| I/F           I/F |<-|       |<---|
--    |           |  |        |  |    |                   |  ---------    |
--    |           |  ----------  |    ---------------------               |
--    |           |              -----------------------------------------|
--    |           --------------------------------------------------------|
--    ---------------------------------------------------------------------
--
-------------------------------------------------------------------------------

library unisim;
use unisim.vcomponents.all;

library ieee;
use ieee.std_logic_1164.all;

-------------------------------------------------------------------------------
-- The entity declaration for the example design.
-------------------------------------------------------------------------------
entity emac_core_main is
port
(
--//------------------------------------
--//EMAC - Channel 0
--//------------------------------------
--//#########  Client side  #########
-- Local link Receiver Interface - EMAC0
--RX_LL_CLOCK_0                   : in  std_logic;
--RX_LL_RESET_0                   : in  std_logic;
RX_LL_DATA_0                    : out std_logic_vector(7 downto 0);
RX_LL_SOF_N_0                   : out std_logic;
RX_LL_EOF_N_0                   : out std_logic;
RX_LL_SRC_RDY_N_0               : out std_logic;
RX_LL_DST_RDY_N_0               : in  std_logic;
RX_LL_FIFO_STATUS_0             : out std_logic_vector(3 downto 0);

-- Local link Transmitter Interface - EMAC0
--TX_LL_CLOCK_0                   : in  std_logic;
--TX_LL_RESET_0                   : in  std_logic;
TX_LL_DATA_0                    : in  std_logic_vector(7 downto 0);
TX_LL_SOF_N_0                   : in  std_logic;
TX_LL_EOF_N_0                   : in  std_logic;
TX_LL_SRC_RDY_N_0               : in  std_logic;
TX_LL_DST_RDY_N_0               : out std_logic;

-- Client Receiver Interface - EMAC0
EMAC0CLIENTRXDVLD               : out std_logic;
EMAC0CLIENTRXFRAMEDROP          : out std_logic;
EMAC0CLIENTRXSTATS              : out std_logic_vector(6 downto 0);
EMAC0CLIENTRXSTATSVLD           : out std_logic;
EMAC0CLIENTRXSTATSBYTEVLD       : out std_logic;

-- Client Transmitter Interface - EMAC0
CLIENTEMAC0TXIFGDELAY           : in  std_logic_vector(7 downto 0);
EMAC0CLIENTTXSTATS              : out std_logic;
EMAC0CLIENTTXSTATSVLD           : out std_logic;
EMAC0CLIENTTXSTATSBYTEVLD       : out std_logic;

-- MAC Control Interface - EMAC0
CLIENTEMAC0PAUSEREQ             : in  std_logic;
CLIENTEMAC0PAUSEVAL             : in  std_logic_vector(15 downto 0);

--EMAC-MGT link status
EMAC0CLIENTSYNCACQSTATUS        : out std_logic;
-- EMAC0 Interrupt
EMAC0ANINTERRUPT                : out std_logic;

--//#########  PHY side  #########
-- Clock Signals - EMAC0
-- 1000BASE-X PCS/PMA Interface - EMAC0
PHYAD_0                         : in  std_logic_vector(4 downto 0);
TXP_0                           : out std_logic;
TXN_0                           : out std_logic;
RXP_0                           : in  std_logic;
RXN_0                           : in  std_logic;

-- 1000BASE-X PCS/PMA RocketIO Reference Clock buffer inputs
--MGTCLK_P                        : in  std_logic;
--MGTCLK_N                        : in  std_logic;
p_in_emac_0_clkref              : in  std_logic;
p_out_emac_0_clk125MHz          : out std_logic;
p_out_emac_0_rst                : out std_logic;

--//------------------------------------
--//EMAC - Channel 1
--//------------------------------------
PHYAD_1                         : in  std_logic_vector(4 downto 0);
TXN_1                           : out std_logic;
TXP_1                           : out std_logic;
RXN_1                           : in  std_logic;
RXP_1                           : in  std_logic;


--//------------------------------------
--//SYSTEM
--//------------------------------------
p_in_drp_ctrl                   : in  std_logic_vector(31 downto 0);
p_out_gtp_plllkdet              : out std_logic;
p_out_ust_tst                   : out std_logic_vector(31 downto 0);

-- Asynchronous Reset
RESET                           : in  std_logic
);
end emac_core_main;


architecture TOP_LEVEL of emac_core_main is

-------------------------------------------------------------------------------
-- Component Declarations for lower hierarchial level entities
-------------------------------------------------------------------------------
-- Component Declaration for the TEMAC wrapper with
-- Local Link FIFO.
component emac_core_locallink is
port(
-- 125MHz clock output from transceiver
CLK125_OUT                       : out std_logic;
-- 125MHz clock input from BUFG
CLK125                           : in  std_logic;

--//--------------------------
--//EMAC0
--//--------------------------
-- Local link Receiver Interface - EMAC0
RX_LL_CLOCK_0                   : in  std_logic;
RX_LL_RESET_0                   : in  std_logic;
RX_LL_DATA_0                    : out std_logic_vector(7 downto 0);
RX_LL_SOF_N_0                   : out std_logic;
RX_LL_EOF_N_0                   : out std_logic;
RX_LL_SRC_RDY_N_0               : out std_logic;
RX_LL_DST_RDY_N_0               : in  std_logic;
RX_LL_FIFO_STATUS_0             : out std_logic_vector(3 downto 0);

-- Local link Transmitter Interface - EMAC0
TX_LL_CLOCK_0                   : in  std_logic;
TX_LL_RESET_0                   : in  std_logic;
TX_LL_DATA_0                    : in  std_logic_vector(7 downto 0);
TX_LL_SOF_N_0                   : in  std_logic;
TX_LL_EOF_N_0                   : in  std_logic;
TX_LL_SRC_RDY_N_0               : in  std_logic;
TX_LL_DST_RDY_N_0               : out std_logic;

--EMAC0_RXCLIENTCLKOUT            : out std_logic;
--EMAC0_TXCLIENTCLKOUT            : out std_logic;

-- Client Receiver Interface - EMAC0
EMAC0CLIENTRXDVLD               : out std_logic;
EMAC0CLIENTRXFRAMEDROP          : out std_logic;
EMAC0CLIENTRXSTATS              : out std_logic_vector(6 downto 0);
EMAC0CLIENTRXSTATSVLD           : out std_logic;
EMAC0CLIENTRXSTATSBYTEVLD       : out std_logic;

-- Client Transmitter Interface - EMAC0
CLIENTEMAC0TXIFGDELAY           : in  std_logic_vector(7 downto 0);
EMAC0CLIENTTXSTATS              : out std_logic;
EMAC0CLIENTTXSTATSVLD           : out std_logic;
EMAC0CLIENTTXSTATSBYTEVLD       : out std_logic;

-- MAC Control Interface - EMAC0
CLIENTEMAC0PAUSEREQ             : in  std_logic;
CLIENTEMAC0PAUSEVAL             : in  std_logic_vector(15 downto 0);

--EMAC-MGT link status
EMAC0CLIENTSYNCACQSTATUS        : out std_logic;
-- EMAC0 Interrupt
EMAC0ANINTERRUPT                : out std_logic;

-- Clock Signals - EMAC0
-- 1000BASE-X PCS/PMA Interface - EMAC0
RESETDONE_0                     : out std_logic;
PHYAD_0                         : in  std_logic_vector(4 downto 0);
TXP_0                           : out std_logic;
TXN_0                           : out std_logic;
RXP_0                           : in  std_logic;
RXN_0                           : in  std_logic;

--//--------------------------
--//EMAC1
--//--------------------------
--RESETDONE_1                     : out std_logic;
PHYAD_1                         : in  std_logic_vector(4 downto 0);
TXN_1                           : out std_logic;
TXP_1                           : out std_logic;
RXN_1                           : in  std_logic;
RXP_1                           : in  std_logic;


--//--------------------------
--//SYSTEM
--//--------------------------
-- 1000BASE-X PCS/PMA RocketIO Reference Clock buffer inputs
CLK_DS                          : in  std_logic;

p_in_drp_ctrl                   : in  std_logic_vector(31 downto 0);
p_out_gtp_plllkdet              : out std_logic;
p_out_ust_tst                   : out std_logic_vector(31 downto 0);

-- Asynchronous Reset
RESET                           : in  std_logic
);
end component;


-----------------------------------------------------------------------
-- Signal Declarations
-----------------------------------------------------------------------

-- Global asynchronous reset
signal reset_i               : std_logic;

-- client interface clocking signals - EMAC0
signal ll_clk_0_i            : std_logic;

-- create a synchronous reset in the transmitter clock domain
signal ll_pre_reset_0_i          : std_logic_vector(5 downto 0);
signal ll_reset_0_i              : std_logic;

attribute async_reg : string;
attribute async_reg of ll_pre_reset_0_i : signal is "true";

signal resetdone_0_i             : std_logic;


-- EMAC0 Clocking signals

-- Transceiver output clock (REFCLKOUT at 125MHz)
signal mac0_gtp_clk125_o         : std_logic;
-- 125MHz clock input to wrappers
signal mac0_gtp_clk125           : std_logic;
-- Input 125MHz differential clock for transceiver
signal clk_ds                    : std_logic;


attribute keep : string;
attribute keep of mac0_gtp_clk125 : signal is "true";


-------------------------------------------------------------------------------
-- Main Body of Code
-------------------------------------------------------------------------------


begin


---------------------------------------------------------------------------
-- Reset Input Buffer
---------------------------------------------------------------------------
--reset_ibuf : IBUF port map (I => RESET, O => reset_i);
reset_i<=RESET;

-- EMAC0 Clocking

-- Generate the clock input to the GTP
-- clk_ds can be shared between multiple MAC instances.
--clkingen : IBUFDS port map (
--I  => MGTCLK_P,
--IB => MGTCLK_N,
--O  => clk_ds);
clk_ds <=p_in_emac_0_clkref;

-- 125MHz from transceiver is routed through a BUFG and
-- input to the MAC wrappers.
-- This clock can be shared between multiple MAC instances.
--bufg_clk125 : BUFG port map (I => clk125_o, O => clk125);
bufg_clk125 : BUFG port map (I => mac0_gtp_clk125_o, O => mac0_gtp_clk125);

ll_clk_0_i <= mac0_gtp_clk125;
p_out_emac_0_clk125MHz<=mac0_gtp_clk125;

-- Create synchronous reset in the transmitter clock domain.
gen_ll_reset_emac0 : process (ll_clk_0_i, reset_i)
begin
if reset_i = '1' then
  ll_pre_reset_0_i <= (others => '1');
  ll_reset_0_i     <= '1';
elsif ll_clk_0_i'event and ll_clk_0_i = '1' then
if resetdone_0_i = '1' then
  ll_pre_reset_0_i(0)          <= '0';
  ll_pre_reset_0_i(5 downto 1) <= ll_pre_reset_0_i(4 downto 0);
  ll_reset_0_i                 <= ll_pre_reset_0_i(5);
end if;
end if;
end process gen_ll_reset_emac0;

p_out_emac_0_rst <= ll_reset_0_i;


------------------------------------------------------------------------
-- Instantiate the EMAC Wrapper with LL FIFO
-- (emac_pcspma_locallink.v)
------------------------------------------------------------------------
v5_emac_ll : emac_core_locallink
port map (
-- EMAC0 Clocking
-- 125MHz clock output from transceiver
CLK125_OUT                      => mac0_gtp_clk125_o,
-- 125MHz clock input from BUFG
CLK125                          => mac0_gtp_clk125,

--//--------------------------
--//EMAC0
--//--------------------------
-- Local link Receiver Interface - EMAC0
RX_LL_CLOCK_0                   => ll_clk_0_i,
RX_LL_RESET_0                   => ll_reset_0_i,
RX_LL_DATA_0                    => RX_LL_DATA_0,
RX_LL_SOF_N_0                   => RX_LL_SOF_N_0,
RX_LL_EOF_N_0                   => RX_LL_EOF_N_0,
RX_LL_SRC_RDY_N_0               => RX_LL_SRC_RDY_N_0,
RX_LL_DST_RDY_N_0               => RX_LL_DST_RDY_N_0,
RX_LL_FIFO_STATUS_0             => RX_LL_FIFO_STATUS_0,--open,

-- Unused Receiver signals - EMAC0
EMAC0CLIENTRXDVLD               => EMAC0CLIENTRXDVLD,
EMAC0CLIENTRXFRAMEDROP          => EMAC0CLIENTRXFRAMEDROP,
EMAC0CLIENTRXSTATS              => EMAC0CLIENTRXSTATS,
EMAC0CLIENTRXSTATSVLD           => EMAC0CLIENTRXSTATSVLD,
EMAC0CLIENTRXSTATSBYTEVLD       => EMAC0CLIENTRXSTATSBYTEVLD,

--EMAC0_RXCLIENTCLKOUT            => EMAC0_RXCLIENTCLKOUT,

-- Local link Transmitter Interface - EMAC0
TX_LL_CLOCK_0                   => ll_clk_0_i,
TX_LL_RESET_0                   => ll_reset_0_i,
TX_LL_DATA_0                    => TX_LL_DATA_0,
TX_LL_SOF_N_0                   => TX_LL_SOF_N_0,
TX_LL_EOF_N_0                   => TX_LL_EOF_N_0,
TX_LL_SRC_RDY_N_0               => TX_LL_SRC_RDY_N_0,
TX_LL_DST_RDY_N_0               => TX_LL_DST_RDY_N_0,

-- Unused Transmitter signals - EMAC0
CLIENTEMAC0TXIFGDELAY           => CLIENTEMAC0TXIFGDELAY,
EMAC0CLIENTTXSTATS              => EMAC0CLIENTTXSTATS,
EMAC0CLIENTTXSTATSVLD           => EMAC0CLIENTTXSTATSVLD,
EMAC0CLIENTTXSTATSBYTEVLD       => EMAC0CLIENTTXSTATSBYTEVLD,

--EMAC0_TXCLIENTCLKOUT            => EMAC0_TXCLIENTCLKOUT,

-- MAC Control Interface - EMAC0
CLIENTEMAC0PAUSEREQ             => CLIENTEMAC0PAUSEREQ,
CLIENTEMAC0PAUSEVAL             => CLIENTEMAC0PAUSEVAL,

--EMAC-MGT link status
EMAC0CLIENTSYNCACQSTATUS        => EMAC0CLIENTSYNCACQSTATUS,
-- EMAC0 Interrupt
EMAC0ANINTERRUPT                => EMAC0ANINTERRUPT,


-- Clock Signals - EMAC0
-- 1000BASE-X PCS/PMA Interface - EMAC0
RESETDONE_0                     => resetdone_0_i,
PHYAD_0                         => PHYAD_0,
TXP_0                           => TXP_0,
TXN_0                           => TXN_0,
RXP_0                           => RXP_0,
RXN_0                           => RXN_0,



--//--------------------------
--//EMAC1
--//--------------------------
--RESETDONE_1                    => open,
PHYAD_1                        => PHYAD_1,
TXN_1                          => TXN_1,
TXP_1                          => TXP_1,
RXN_1                          => RXN_1,
RXP_1                          => RXP_1,

---- unused transceiver
--TXN_1_UNUSED                    => TXN_1,
--TXP_1_UNUSED                    => TXP_1,
--RXN_1_UNUSED                    => RXN_1,
--RXP_1_UNUSED                    => RXP_1,

--//--------------------------
--//SYSTEM
--//--------------------------
-- 1000BASE-X PCS/PMA RocketIO Reference Clock buffer inputs
CLK_DS                          => clk_ds,


p_in_drp_ctrl                   => p_in_drp_ctrl,
p_out_gtp_plllkdet              => p_out_gtp_plllkdet,
p_out_ust_tst                   => p_out_ust_tst,

-- Asynchronous Reset
RESET                           => reset_i
);

--p_out_gtp_plllkdet<='0';
--p_out_ust_tst<=(others=>'0');


end TOP_LEVEL;
