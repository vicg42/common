-------------------------------------------------------------------------------
-- Title      : Virtex-5 Ethernet MAC Example Design Wrapper
-- Project    : Virtex-5 Embedded Tri-Mode Ethernet MAC Wrapper
-- File       : emac_core_example_design.vhd
-- Version    : 1.8
-------------------------------------------------------------------------------
--
-- (c) Copyright 2004-2010 Xilinx, Inc. All rights reserved.
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
--    | EXAMPLE DESIGN WRAPPER                                            |
--    |           --------------------------------------------------------|
--    |           |LOCAL LINK WRAPPER                                     |
--    |           |              -----------------------------------------|
--    |           |              |BLOCK LEVEL WRAPPER                     |
--    |           |              |    ---------------------               |
--    | --------  |  ----------  |    | ETHERNET MAC      |               |
--    | |      |  |  |        |  |    | WRAPPER           |  ---------    |
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
-------------------------------------------------------------------------------


library unisim;
use unisim.vcomponents.all;

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

library work;
use work.eth_pkg.all;

-------------------------------------------------------------------------------
-- Entity declaration for the example design
-------------------------------------------------------------------------------

entity eth_phy_fiber is
  generic (
  G_ETH : TEthGeneric
  );
   port(
      --EthPhy<->EthApp
      p_out_phy2app : out   TEthPhy2AppOUTs;
      p_in_phy2app  : in    TEthPhy2AppINs;

      --EthPHY
      p_out_phy     : out   TEthPhyOUT;
      p_in_phy      : in    TEthPhyIN;

      --Технологический
      p_out_dbg     : out   TEthPhyDBGs;
      p_in_tst      : in    std_logic_vector(31 downto 0);
      p_out_tst     : out   std_logic_vector(31 downto 0);

      --System
      p_in_rst      : in    std_logic
   );

end eth_phy_fiber;


architecture TOP_LEVEL of eth_phy_fiber is

-------------------------------------------------------------------------------
-- Component Declarations for lower hierarchial level entities
-------------------------------------------------------------------------------
  -- Component Declaration for the TEMAC wrapper with
  -- Local Link FIFO.
  component emac_core_locallink is
   port(
      p_in_drp_ctrl                   : in  std_logic_vector(31 downto 0);
      p_out_gtp_plllkdet              : out std_logic;
      p_out_ust_tst                   : out std_logic_vector(31 downto 0);

      -- EMAC0 Clocking
      -- 125MHz clock output from transceiver
      CLK125_OUT                       : out std_logic;
      -- 125MHz clock input from BUFG
      CLK125                           : in  std_logic;
      -- 250MHz clock input from DCM
      CLK250                           : in  std_logic;
      CLK250_DCM_LOCKED                : in  std_logic;

      -- Local link Receiver Interface - EMAC0
      RX_LL_CLOCK_0                   : in  std_logic;
      RX_LL_RESET_0                   : in  std_logic;
      RX_LL_DATA_0                    : out std_logic_vector(15 downto 0);
      RX_LL_SOF_N_0                   : out std_logic;
      RX_LL_EOF_N_0                   : out std_logic;
      RX_LL_SRC_RDY_N_0               : out std_logic;
      RX_LL_DST_RDY_N_0               : in  std_logic;
      RX_LL_REM_0                     : out std_logic;
      RX_LL_FIFO_STATUS_0             : out std_logic_vector(3 downto 0);

      -- Local link Transmitter Interface - EMAC0
      TX_LL_CLOCK_0                   : in  std_logic;
      TX_LL_RESET_0                   : in  std_logic;
      TX_LL_DATA_0                    : in  std_logic_vector(15 downto 0);
      TX_LL_SOF_N_0                   : in  std_logic;
      TX_LL_EOF_N_0                   : in  std_logic;
      TX_LL_SRC_RDY_N_0               : in  std_logic;
      TX_LL_DST_RDY_N_0               : out std_logic;
      TX_LL_REM_0                     : in  std_logic;

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
      TXP_0                           : out std_logic;
      TXN_0                           : out std_logic;
      RXP_0                           : in  std_logic;
      RXN_0                           : in  std_logic;
      PHYAD_0                         : in  std_logic_vector(4 downto 0);
      RESETDONE_0                     : out std_logic;

      -- 1000BASE-X PCS/PMA Interface - EMAC0
      TXP_1                           : out std_logic;
      TXN_1                           : out std_logic;
      RXP_1                           : in  std_logic;
      RXN_1                           : in  std_logic;
      PHYAD_1                         : in  std_logic_vector(4 downto 0);
      RESETDONE_1                     : out std_logic;

      -- 1000BASE-X PCS/PMA RocketIO Reference Clock buffer inputs
      CLK_DS                          : in  std_logic;

      -- RocketIO Reset input
      GTRESET                         : in  std_logic;



      -- Asynchronous Reset
      RESET                           : in  std_logic
   );
  end component;

   ---------------------------------------------------------------------
   --  Component Declaration for 16-bit address swapping module
   ---------------------------------------------------------------------
   component address_swap_module_16
   port (
      rx_ll_clock         : in  std_logic;                     -- Input CLK from MAC Reciever
      rx_ll_reset         : in  std_logic;                     -- Synchronous reset signal
      rx_ll_data_in       : in  std_logic_vector(15 downto 0); -- Input data
      rx_ll_sof_in_n      : in  std_logic;                     -- Input start of frame
      rx_ll_eof_in_n      : in  std_logic;                     -- Input end of frame
      rx_ll_src_rdy_in_n  : in  std_logic;                     -- Input source ready
      rx_ll_rem_in        : in  std_logic_vector(0 downto 0);  -- Remainder in
      rx_ll_data_out      : out std_logic_vector(15 downto 0); -- Modified output data
      rx_ll_sof_out_n     : out std_logic;                     -- Output start of frame
      rx_ll_eof_out_n     : out std_logic;                     -- Output end of frame
      rx_ll_src_rdy_out_n : out std_logic;                     -- Output source ready
      rx_ll_rem_out       : out std_logic_vector(0 downto 0);  -- Remainder out
      rx_ll_dst_rdy_in_n  : in  std_logic                      -- Input destination ready
      );
   end component;

   ---------------------------------------------------------------------
   --  Component Declaration for 8-bit address swapping module
   ---------------------------------------------------------------------
   component address_swap_module_8
   port (
      rx_ll_clock         : in  std_logic;                     -- Input CLK from MAC Reciever
      rx_ll_reset         : in  std_logic;                     -- Synchronous reset signal
      rx_ll_data_in       : in  std_logic_vector(7 downto 0);  -- Input data
      rx_ll_sof_in_n      : in  std_logic;                     -- Input start of frame
      rx_ll_eof_in_n      : in  std_logic;                     -- Input end of frame
      rx_ll_src_rdy_in_n  : in  std_logic;                     -- Input source ready
      rx_ll_data_out      : out std_logic_vector(7 downto 0);  -- Modified output data
      rx_ll_sof_out_n     : out std_logic;                     -- Output start of frame
      rx_ll_eof_out_n     : out std_logic;                     -- Output end of frame
      rx_ll_src_rdy_out_n : out std_logic;                     -- Output source ready
      rx_ll_dst_rdy_in_n  : in  std_logic                      -- Input destination ready
      );
   end component;

-----------------------------------------------------------------------
-- Signal Declarations
-----------------------------------------------------------------------

    -- Global asynchronous reset
    signal reset_i               : std_logic;

    -- client interface clocking signals - EMAC0
    signal ll_clk_0_i            : std_logic;

--    -- address swap transmitter connections - EMAC0
--    signal tx_ll_data_0_i      : std_logic_vector(15 downto 0);
--    signal tx_ll_rem_0_i       : std_logic;
--    signal tx_ll_rem_0_int     : std_logic_vector(0 downto 0);
--    signal tx_ll_sof_n_0_i     : std_logic;
--    signal tx_ll_eof_n_0_i     : std_logic;
--    signal tx_ll_src_rdy_n_0_i : std_logic;
--    signal tx_ll_dst_rdy_n_0_i : std_logic;
--
--   -- address swap receiver connections - EMAC0
--    signal rx_ll_data_0_i           : std_logic_vector(15 downto 0);
--    signal rx_ll_rem_0_i            : std_logic;
--    signal rx_ll_rem_0_int          : std_logic_vector(0 downto 0);
--    signal rx_ll_sof_n_0_i          : std_logic;
--    signal rx_ll_eof_n_0_i          : std_logic;
--    signal rx_ll_src_rdy_n_0_i      : std_logic;
--    signal rx_ll_dst_rdy_n_0_i      : std_logic;

    -- create a synchronous reset in the transmitter clock domain
    signal ll_pre_reset_0_i          : std_logic_vector(5 downto 0);
    signal ll_reset_0_i              : std_logic;

    attribute async_reg : string;
    attribute async_reg of ll_pre_reset_0_i : signal is "true";

    signal resetdone_0_i             : std_logic;


    -- EMAC0 Clocking signals

    -- Transceiver output clock (REFCLKOUT at 125MHz)
    signal clk125_o                  : std_logic;
    -- 125MHz clock input to wrappers
    signal clk125                    : std_logic;
    -- Input 125MHz differential clock for transceiver
    signal clk_ds                    : std_logic;

    -- Clock signals for DCM at 2Gb/s
    signal clk125_fb                 : std_logic;
    signal clk125_o_bufg             : std_logic;
    signal clk250_pre_bufg           : std_logic;
    signal client_dcm_locked_i       : std_logic;
    -- 250MHz clock to wrappers
    signal clk250                    : std_logic;

    -- GT reset signal
   signal gtreset                    : std_logic;
   signal reset_r                    : std_logic_vector(3 downto 0);
   attribute async_reg of reset_r    : signal is "TRUE";


    signal i_PHYAD,i_PHYAD_1       : std_logic_vector(4 downto 0);
    signal i_CLIENTEMACTXIFGDELAY  : std_logic_vector(7 downto 0);

    signal i_drp_ctrl              : std_logic_vector(31 downto 0);
    signal i_gt_clkin              : std_logic;
    signal i_gt_clkout             : std_logic;

component gtp_prog_clkmux
generic(
G_CLKIN_CHANGE     : std_logic := '0';
G_CLKSOUTH_CHANGE  : std_logic := '0';
G_CLKNORTH_CHANGE  : std_logic := '0';

G_CLKIN_MUX_VAL    : std_logic_vector(2 downto 0):="011";
G_CLKSOUTH_MUX_VAL : std_logic := '0';
G_CLKNORTH_MUX_VAL : std_logic := '0'
);
port(
p_in_drp_rst    : in    std_logic;
p_in_drp_clk    : in    std_logic;

p_out_txp       : out   std_logic_vector(1 downto 0);
p_out_txn       : out   std_logic_vector(1 downto 0);
p_in_rxp        : in    std_logic_vector(1 downto 0);
p_in_rxn        : in    std_logic_vector(1 downto 0);

p_in_clkin      : in    std_logic;
p_out_refclkout : out   std_logic
);
end component;

    signal pll_clkfb_pre_bufg : std_logic;
    signal pll_clkfb          : std_logic;


-------------------------------------------------------------------------------
-- Main Body of Code
-------------------------------------------------------------------------------


begin

  p_out_tst <=(others=>'0');
  i_PHYAD_1<=CONV_STD_LOGIC_VECTOR(16#02#, i_PHYAD'length);
  i_PHYAD<=CONV_STD_LOGIC_VECTOR(16#01#, i_PHYAD'length);
  i_CLIENTEMACTXIFGDELAY<=CONV_STD_LOGIC_VECTOR(16#0D#, i_CLIENTEMACTXIFGDELAY'length);

  p_out_phy.link<=p_in_phy.pin.fiber.sfp_sd;
  p_out_phy.rdy<='1';
  p_out_phy.clk<=ll_clk_0_i;
  p_out_phy.rst<=ll_reset_0_i;
  p_out_phy.pin.fiber.sfp_txdis<='0';

  reset_i<=p_in_rst;
  clk_ds <=p_in_phy.clk;


--//Программирую ветвление опорной частоты для GT - FIBER
m_gt_refclkout : gtp_prog_clkmux
generic map(
G_CLKIN_CHANGE      => '0',   --//разрешение/запрет изменения состояния мультиплексора CLKIN    - '1'/'0'
G_CLKSOUTH_CHANGE   => '0',   --//разрешение/запрет изменения состояния мультиплексора CLKSOUTH - '1'/'0'
G_CLKNORTH_CHANGE   => '1',   --//разрешение/запрет изменения состояния мультиплексора CLKNORTH - '1'/'0'

G_CLKIN_MUX_VAL     => "011", --//Значение для мультиплексора CLKIN
G_CLKSOUTH_MUX_VAL  => '1',   --//Значение для мультиплексора CLKSOUTH
G_CLKNORTH_MUX_VAL  => '1'    --//Значение для мультиплексора CLKNORTH
)
port map(
p_in_drp_rst    => p_in_phy.opt(33),--<=i_pll_rst_out,--reset_i,
p_in_drp_clk    => p_in_phy.opt(34),--<=g_pll_tmr_clk;--i_drp_ctrl(C_ETHPHY_OPTIN_DRPCLK_BIT),

p_out_txp       => p_out_phy.pin.fiber.tx2p,
p_out_txn       => p_out_phy.pin.fiber.tx2n,
p_in_rxp        => p_in_phy.pin.fiber.rx2p,
p_in_rxn        => p_in_phy.pin.fiber.rx2n,

p_in_clkin      => p_in_phy.opt(32),--i_eth_gt2_refclk125,
p_out_refclkout => i_gt_clkout
);

--//Значение для перепрограм. мультиплексора CLKIN RocketIO ETH
i_drp_ctrl(C_ETHPHY_OPTIN_V5GT_CLKIN_MUX_M_BIT downto C_ETHPHY_OPTIN_V5GT_CLKIN_MUX_L_BIT) <=CONV_STD_LOGIC_VECTOR(16#07#, C_ETHPHY_OPTIN_V5GT_CLKIN_MUX_M_BIT-C_ETHPHY_OPTIN_V5GT_CLKIN_MUX_L_BIT+1);
--//Значение для перепрограм. мультиплексора CLKSOUTH RocketIO ETH
i_drp_ctrl(C_ETHPHY_OPTIN_V5GT_SOUTH_MUX_VAL_M_BIT downto C_ETHPHY_OPTIN_V5GT_SOUTH_MUX_VAL_L_BIT)<=CONV_STD_LOGIC_VECTOR(16#00#, C_ETHPHY_OPTIN_V5GT_SOUTH_MUX_VAL_M_BIT-C_ETHPHY_OPTIN_V5GT_SOUTH_MUX_VAL_L_BIT+1);
i_drp_ctrl(C_ETHPHY_OPTIN_V5GT_CLKIN_MUX_CNG_BIT)<='1';  --//1- перепрограммирование мультиплексора CLKIN RocketIO ETH
i_drp_ctrl(C_ETHPHY_OPTIN_V5GT_SOUTH_MUX_CNG_BIT)<='0';  --//1- перепрограммирование мультиплексора CLKSOUTH RocketIO ETH
i_drp_ctrl(C_ETHPHY_OPTIN_V5GT_NORTH_MUX_CNG_BIT)<='0';  --//1- перепрограммирование мультиплексора CLKNORTH RocketIO ETH
m_bufg : BUFG port map(I => i_gt_clkout, O => i_drp_ctrl(C_ETHPHY_OPTIN_DRPCLK_BIT));

--    ---------------------------------------------------------------------------
--    -- Reset Input Buffer
--    ---------------------------------------------------------------------------
--    reset_ibuf : IBUF port map (I => RESET, O => reset_i);
--
--    -- EMAC0 Clocking
--
--    -- Generate the clock input to the GTP
--    -- clk_ds can be shared between multiple MAC instances.
--    clkingen : IBUFDS port map (
--      I  => MGTCLK_P,
--      IB => MGTCLK_N,
--      O  => clk_ds);


    ll_clk_0_i <= clk125;

    ------------------------------------------------------------------------
    -- Receive and Transmit Client Clock Management when configured in
    -- 16-bit mode. Use a DCM to generate the 250MHz clock for the MAC.
    -- This clock can be shared between multiple MAC instances.
    ------------------------------------------------------------------------
--    client_dcm_1G : DCM_BASE
--    generic map
--       (CLKFX_MULTIPLY     => 2,
--        CLKFX_DIVIDE       => 1,
--        CLKDV_DIVIDE       => 2.0)
--    port map (
--        CLKIN    => clk125_o_bufg      ,
--        CLKFB    => clk250             ,
--        RST      => '0'                ,
--        CLK0     => clk250_pre_bufg    ,
--        CLK90    => open               ,
--        CLK180   => open               ,
--        CLK270   => open               ,
--        CLK2X    => open               ,
--        CLK2X180 => open               ,
--        CLKDV    => clk125_fb          ,
--        CLKFX    => open               ,
--        CLKFX180 => open               ,
--        LOCKED   => client_dcm_locked_i
--        );

    client_dcm_2G : DCM_BASE
    generic map
       (CLKFX_MULTIPLY     => 2,
        CLKFX_DIVIDE       => 1)
    port map (
        CLKIN    => clk125_o_bufg      ,
        CLKFB    => clk125             ,
        RST      => '0'                ,
        CLK0     => clk125_fb          ,
        CLK90    => open               ,
        CLK180   => open               ,
        CLK270   => open               ,
        CLK2X    => open               ,
        CLK2X180 => open               ,
        CLKDV    => open               ,
        CLKFX    => clk250_pre_bufg    ,
        CLKFX180 => open               ,
        LOCKED   => client_dcm_locked_i
        );

--      -- Reference clock MMCM (CLKFBOUT range 400 MHz to 1200 MHz)
--      -- CLKFBOUT = (CLKIN1/DIVCLK_DIVIDE) * CLKFBOUT_MULT
--      -- CLKOUTn  = (CLKIN1/DIVCLK_DIVIDE) * CLKFBOUT_MULT/CLKOUTn_DIVIDE
--      -- CLKFBOUT = (125 MHz/1) * 5.000    = 625 MHz
--      -- CLKOUT0  = (125 MHz/1) * 5.000/2  = 312.5 MHz
--      -- CLKOUT1  = (125 MHz/1) * 5.000/4  = 156,25 MHz
--      client_dcm_25G : PLL_BASE
--      generic map(
--      CLKIN_PERIOD   => 8.0,--125MHz
--      DIVCLK_DIVIDE  => 1,
--      CLKFBOUT_MULT  => 5,
--      CLKOUT0_DIVIDE => 2,
--      CLKOUT1_DIVIDE => 4,
--      CLKOUT2_DIVIDE => 1,
--      CLKOUT3_DIVIDE => 1,
--      CLKOUT0_PHASE  => 0.000,
--      CLKOUT1_PHASE  => 0.000,
--      CLKOUT2_PHASE  => 0.000,
--      CLKOUT3_PHASE  => 0.000
--      )
--      port map(
--      CLKOUT0  => clk250_pre_bufg,
--      CLKOUT1  => clk125_fb,
--      CLKOUT2  => open,
--      CLKOUT3  => open,
--      CLKOUT4  => open,
--      CLKOUT5  => open,
--      LOCKED   => client_dcm_locked_i,
--      CLKFBOUT => pll_clkfb_pre_bufg,
--      CLKFBIN  => pll_clkfb,
--      CLKIN    => clk125_o_bufg,
--      RST      => '0');
--
--      pll_fb_bufg : BUFG port map (
--          I => pll_clkfb_pre_bufg,
--          O => pll_clkfb);

    tx_client_clk_out_0_bufg : BUFG port map (
        I => clk250_pre_bufg,
        O => clk250);

    tx_client_clk_in_dcm_0_bufg : BUFG port map (
        I => clk125_o,
        O => clk125_o_bufg);

    tx_client_clk_in_div2_0_bufg : BUFG port map (
        I => clk125_fb,
        O => clk125);

   --------------------------------------------------------------------
   -- RocketIO PMA reset circuitry
   --------------------------------------------------------------------
   process(reset_i, clk125_o_bufg)
   begin
     if (reset_i = '1') then
       reset_r <= "1111";
     elsif clk125_o_bufg'event and clk125_o_bufg = '1' then
       reset_r <= reset_r(2 downto 0) & reset_i;
     end if;
   end process;

   gtreset <= reset_r(3);



    ------------------------------------------------------------------------
    -- Instantiate the EMAC Wrapper with LL FIFO
    -- (emac_core_locallink.v)
    ------------------------------------------------------------------------
    m_emac_ll : emac_core_locallink
    port map (
      p_in_drp_ctrl                   => i_drp_ctrl,
      p_out_gtp_plllkdet              => open,
      p_out_ust_tst                   => open,

      -- EMAC0 Clocking
      -- 125MHz clock output from transceiver
      CLK125_OUT                      => clk125_o,
      -- 125MHz clock input from BUFG
      CLK125                          => clk125,
      -- 250MHz clock input from DCM
      CLK250                          => clk250,
      CLK250_DCM_LOCKED               => client_dcm_locked_i,
      -- Local link Receiver Interface - EMAC0
      RX_LL_CLOCK_0                   => ll_clk_0_i,                                                              --: in  std_logic;
      RX_LL_RESET_0                   => ll_reset_0_i,                                                            --: in  std_logic;
      RX_LL_DATA_0                    => p_out_phy2app(0).rxd(G_ETH.phy_dwidth-1 downto 0),--rx_ll_data_0_i,      --: out std_logic_vector(15 downto 0);
      RX_LL_SOF_N_0                   => p_out_phy2app(0).rxsof_n,                         --rx_ll_sof_n_0_i,     --: out std_logic;
      RX_LL_EOF_N_0                   => p_out_phy2app(0).rxeof_n,                         --rx_ll_eof_n_0_i,     --: out std_logic;
      RX_LL_SRC_RDY_N_0               => p_out_phy2app(0).rxsrc_rdy_n,                     --rx_ll_src_rdy_n_0_i, --: out std_logic;
      RX_LL_DST_RDY_N_0               => p_in_phy2app (0).rxdst_rdy_n,                     --rx_ll_dst_rdy_n_0_i, --: in  std_logic;
      RX_LL_REM_0                     => p_out_phy2app(0).rxrem(0),                        --rx_ll_rem_0_i,       --: out std_logic;
      RX_LL_FIFO_STATUS_0             => p_out_phy2app(0).rxbuf_status,                    --open,                --: out std_logic_vector(3 downto 0);

      -- Unused Receiver signals - EMAC0
      EMAC0CLIENTRXDVLD               => open, --EMAC0CLIENTRXDVLD,
      EMAC0CLIENTRXFRAMEDROP          => open, --EMAC0CLIENTRXFRAMEDROP,
      EMAC0CLIENTRXSTATS              => open, --EMAC0CLIENTRXSTATS,
      EMAC0CLIENTRXSTATSVLD           => open, --EMAC0CLIENTRXSTATSVLD,
      EMAC0CLIENTRXSTATSBYTEVLD       => open, --EMAC0CLIENTRXSTATSBYTEVLD,

      -- Local link Transmitter Interface - EMAC0
      TX_LL_CLOCK_0                   => ll_clk_0_i,                                                              --: in  std_logic;
      TX_LL_RESET_0                   => ll_reset_0_i,                                                            --: in  std_logic;
      TX_LL_DATA_0                    => p_in_phy2app (0).txd(G_ETH.phy_dwidth-1 downto 0),--tx_ll_data_0_i,      --: in  std_logic_vector(15 downto 0);
      TX_LL_SOF_N_0                   => p_in_phy2app (0).txsof_n,                         --tx_ll_sof_n_0_i,     --: in  std_logic;
      TX_LL_EOF_N_0                   => p_in_phy2app (0).txeof_n,                         --tx_ll_eof_n_0_i,     --: in  std_logic;
      TX_LL_SRC_RDY_N_0               => p_in_phy2app (0).txsrc_rdy_n,                     --tx_ll_src_rdy_n_0_i, --: in  std_logic;
      TX_LL_DST_RDY_N_0               => p_out_phy2app(0).txdst_rdy_n,                     --tx_ll_dst_rdy_n_0_i, --: out std_logic;
      TX_LL_REM_0                     => p_in_phy2app (0).txrem(0),                        --tx_ll_rem_0_i,       --: in  std_logic;

      -- Unused Transmitter signals - EMAC0
      CLIENTEMAC0TXIFGDELAY           => i_CLIENTEMACTXIFGDELAY, --CLIENTEMAC0TXIFGDELAY,
      EMAC0CLIENTTXSTATS              => open,                   --EMAC0CLIENTTXSTATS,
      EMAC0CLIENTTXSTATSVLD           => open,                   --EMAC0CLIENTTXSTATSVLD,
      EMAC0CLIENTTXSTATSBYTEVLD       => open,                   --EMAC0CLIENTTXSTATSBYTEVLD,

      -- MAC Control Interface - EMAC0
      CLIENTEMAC0PAUSEREQ             => '0',           --CLIENTEMAC0PAUSEREQ,
      CLIENTEMAC0PAUSEVAL             => (others=>'0'), --CLIENTEMAC0PAUSEVAL,

      --EMAC-MGT link status
      EMAC0CLIENTSYNCACQSTATUS        => open,  --EMAC0CLIENTSYNCACQSTATUS,
      -- EMAC0 Interrupt
      EMAC0ANINTERRUPT                => open,  --EMAC0ANINTERRUPT,


      -- Clock Signals - EMAC0
      -- 1000BASE-X PCS/PMA Interface - EMAC0
      TXP_0                           => p_out_phy.pin.fiber.txp(0), --TXP_0,
      TXN_0                           => p_out_phy.pin.fiber.txn(0), --TXN_0,
      RXP_0                           => p_in_phy.pin.fiber.rxp(0),  --RXP_0,
      RXN_0                           => p_in_phy.pin.fiber.rxn(0),  --RXN_0,
      PHYAD_0                         => i_PHYAD,                    --PHYAD_0,
      RESETDONE_0                     => resetdone_0_i,

      -- 1000BASE-X PCS/PMA interface
      TXP_1                           => p_out_phy.pin.fiber.txp(1), --TXP_0,
      TXN_1                           => p_out_phy.pin.fiber.txn(1), --TXN_0,
      RXP_1                           => p_in_phy.pin.fiber.rxp(1),  --RXP_0,
      RXN_1                           => p_in_phy.pin.fiber.rxn(1),  --RXN_0,
      PHYAD_1                         => i_PHYAD_1,                         --: in  std_logic_vector(4 downto 0);
      RESETDONE_1                     => open,--resetdone_i,

      -- 1000BASE-X PCS/PMA RocketIO Reference Clock buffer inputs
      CLK_DS                          => clk_ds,

      -- RocketIO Reset input
      GTRESET                         => gtreset,



      -- Asynchronous Reset
      RESET                           => reset_i
    );

--    ---------------------------------------------------------------------
--    --  Instatiate the address swapping module
--    ---------------------------------------------------------------------
--    client_side_asm_emac0 : address_swap_module_16
--      port map (
--        rx_ll_clock         => ll_clk_0_i,
--        rx_ll_reset         => ll_reset_0_i,
--        rx_ll_data_in       => rx_ll_data_0_i,
--        rx_ll_sof_in_n      => rx_ll_sof_n_0_i,
--        rx_ll_eof_in_n      => rx_ll_eof_n_0_i,
--        rx_ll_src_rdy_in_n  => rx_ll_src_rdy_n_0_i,
--        rx_ll_rem_in        => rx_ll_rem_0_int,
--        rx_ll_data_out      => tx_ll_data_0_i,
--        rx_ll_sof_out_n     => tx_ll_sof_n_0_i,
--        rx_ll_eof_out_n     => tx_ll_eof_n_0_i,
--        rx_ll_src_rdy_out_n => tx_ll_src_rdy_n_0_i,
--        rx_ll_rem_out       => tx_ll_rem_0_int,
--        rx_ll_dst_rdy_in_n  => tx_ll_dst_rdy_n_0_i
--    );
--
--    rx_ll_dst_rdy_n_0_i     <= tx_ll_dst_rdy_n_0_i;
--    rx_ll_rem_0_int(0)      <= rx_ll_rem_0_i;
--    tx_ll_rem_0_i           <= tx_ll_rem_0_int(0);


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





end TOP_LEVEL;
