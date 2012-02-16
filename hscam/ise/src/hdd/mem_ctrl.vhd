-------------------------------------------------------------------------
-- Company     : Linkos
-- Engineer    : Golovachenko Victor
--
-- Create Date : 21.01.2012 13:40:16
-- Module Name : mem_ctrl
--
-- Назначение/Описание :
--
--
-- Revision:
-- Revision 0.01 - File Created
--
-------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;

library work;
use work.vicg_common_pkg.all;
use work.mem_ctrl_pkg.all;

entity mem_ctrl is
generic(
G_SIM : string:= "OFF"
);
port(
------------------------------------
--User Post
------------------------------------
p_in_mem       : in    TMemINBank;
p_out_mem      : out   TMemOUTBank;

------------------------------------
--Memory physical interface
------------------------------------
p_out_phymem   : out   TMEMCTRL_phy_outs;
p_inout_phymem : inout TMEMCTRL_phy_inouts;

------------------------------------
--Memory status
------------------------------------
p_out_status   : out   TMEMCTRL_status;

------------------------------------
--System
------------------------------------
p_out_sys      : out   TMEMCTRL_sysout;
p_in_sys       : in    TMEMCTRL_sysin
);
end mem_ctrl;

architecture arc of mem_ctrl is


constant C5_SIMULATION : string := selstring("FALSE","TRUE", strcmp(G_SIM, "OFF"));

component memc5_infrastructure is
    generic (
      C_RST_ACT_LOW        : integer;
      C_INPUT_CLK_TYPE     : string;
      C_CLKOUT0_DIVIDE     : integer;
      C_CLKOUT1_DIVIDE     : integer;
      C_CLKOUT2_DIVIDE     : integer;
      C_CLKOUT3_DIVIDE     : integer;
      C_CLKFBOUT_MULT      : integer;
      C_DIVCLK_DIVIDE      : integer;
      C_INCLK_PERIOD       : integer

      );
    port (
      sys_clk_p                              : in    std_logic;
      sys_clk_n                              : in    std_logic;
      sys_clk                                : in    std_logic;
      sys_rst_i                              : in    std_logic;
      clk0                                   : out   std_logic;
      rst0                                   : out   std_logic;
      async_rst                              : out   std_logic;
      sysclk_2x                              : out   std_logic;
      sysclk_2x_180                          : out   std_logic;
      pll_ce_0                               : out   std_logic;
      pll_ce_90                              : out   std_logic;
      pll_lock                               : out   std_logic;
      mcb_drp_clk                            : out   std_logic

      );
  end component;


component memc5_wrapper is
    generic (
      C_MEMCLK_PERIOD      : integer;
      C_CALIB_SOFT_IP      : string;
      C_SIMULATION         : string;
      C_P0_MASK_SIZE       : integer;
      C_P0_DATA_PORT_SIZE   : integer;
      C_P1_MASK_SIZE       : integer;
      C_P1_DATA_PORT_SIZE   : integer;
      C_ARB_NUM_TIME_SLOTS   : integer;
      C_ARB_TIME_SLOT_0    : bit_vector(5 downto 0);
      C_ARB_TIME_SLOT_1    : bit_vector(5 downto 0);
      C_ARB_TIME_SLOT_2    : bit_vector(5 downto 0);
      C_ARB_TIME_SLOT_3    : bit_vector(5 downto 0);
      C_ARB_TIME_SLOT_4    : bit_vector(5 downto 0);
      C_ARB_TIME_SLOT_5    : bit_vector(5 downto 0);
      C_ARB_TIME_SLOT_6    : bit_vector(5 downto 0);
      C_ARB_TIME_SLOT_7    : bit_vector(5 downto 0);
      C_ARB_TIME_SLOT_8    : bit_vector(5 downto 0);
      C_ARB_TIME_SLOT_9    : bit_vector(5 downto 0);
      C_ARB_TIME_SLOT_10   : bit_vector(5 downto 0);
      C_ARB_TIME_SLOT_11   : bit_vector(5 downto 0);
      C_MEM_TRAS           : integer;
      C_MEM_TRCD           : integer;
      C_MEM_TREFI          : integer;
      C_MEM_TRFC           : integer;
      C_MEM_TRP            : integer;
      C_MEM_TWR            : integer;
      C_MEM_TRTP           : integer;
      C_MEM_TWTR           : integer;
      C_MEM_ADDR_ORDER     : string;
      C_NUM_DQ_PINS        : integer;
      C_MEM_TYPE           : string;
      C_MEM_DENSITY        : string;
      C_MEM_BURST_LEN      : integer;
      C_MEM_CAS_LATENCY    : integer;
      C_MEM_ADDR_WIDTH     : integer;
      C_MEM_BANKADDR_WIDTH   : integer;
      C_MEM_NUM_COL_BITS   : integer;
      C_MEM_DDR1_2_ODS     : string;
      C_MEM_DDR2_RTT       : string;
      C_MEM_DDR2_DIFF_DQS_EN   : string;
      C_MEM_DDR2_3_PA_SR   : string;
      C_MEM_DDR2_3_HIGH_TEMP_SR   : string;
      C_MEM_DDR3_CAS_LATENCY   : integer;
      C_MEM_DDR3_ODS       : string;
      C_MEM_DDR3_RTT       : string;
      C_MEM_DDR3_CAS_WR_LATENCY   : integer;
      C_MEM_DDR3_AUTO_SR   : string;
      C_MEM_DDR3_DYN_WRT_ODT   : string;
      C_MEM_MOBILE_PA_SR   : string;
      C_MEM_MDDR_ODS       : string;
      C_MC_CALIB_BYPASS    : string;
      C_MC_CALIBRATION_MODE   : string;
      C_MC_CALIBRATION_DELAY   : string;
      C_SKIP_IN_TERM_CAL   : integer;
      C_SKIP_DYNAMIC_CAL   : integer;
      C_LDQSP_TAP_DELAY_VAL   : integer;
      C_LDQSN_TAP_DELAY_VAL   : integer;
      C_UDQSP_TAP_DELAY_VAL   : integer;
      C_UDQSN_TAP_DELAY_VAL   : integer;
      C_DQ0_TAP_DELAY_VAL   : integer;
      C_DQ1_TAP_DELAY_VAL   : integer;
      C_DQ2_TAP_DELAY_VAL   : integer;
      C_DQ3_TAP_DELAY_VAL   : integer;
      C_DQ4_TAP_DELAY_VAL   : integer;
      C_DQ5_TAP_DELAY_VAL   : integer;
      C_DQ6_TAP_DELAY_VAL   : integer;
      C_DQ7_TAP_DELAY_VAL   : integer;
      C_DQ8_TAP_DELAY_VAL   : integer;
      C_DQ9_TAP_DELAY_VAL   : integer;
      C_DQ10_TAP_DELAY_VAL   : integer;
      C_DQ11_TAP_DELAY_VAL   : integer;
      C_DQ12_TAP_DELAY_VAL   : integer;
      C_DQ13_TAP_DELAY_VAL   : integer;
      C_DQ14_TAP_DELAY_VAL   : integer;
      C_DQ15_TAP_DELAY_VAL   : integer
      );
    port (
      mcb5_dram_dq                           : inout  std_logic_vector((C_NUM_DQ_PINS-1) downto 0);
      mcb5_dram_a                            : out  std_logic_vector((C_MEM_ADDR_WIDTH-1) downto 0);
      mcb5_dram_ba                           : out  std_logic_vector((C_MEM_BANKADDR_WIDTH-1) downto 0);
      mcb5_dram_ras_n                        : out  std_logic;
      mcb5_dram_cas_n                        : out  std_logic;
      mcb5_dram_we_n                         : out  std_logic;
      mcb5_dram_odt                          : out  std_logic;
      mcb5_dram_cke                          : out  std_logic;
      mcb5_dram_dm                           : out  std_logic;
      mcb5_dram_udqs                         : inout  std_logic;
      mcb5_dram_udqs_n                       : inout  std_logic;
      mcb5_rzq                               : inout  std_logic;
      mcb5_zio                               : inout  std_logic;
      mcb5_dram_udm                          : out  std_logic;
      calib_done                             : out  std_logic;
      async_rst                              : in  std_logic;
      sysclk_2x                              : in  std_logic;
      sysclk_2x_180                          : in  std_logic;
      pll_ce_0                               : in  std_logic;
      pll_ce_90                              : in  std_logic;
      pll_lock                               : in  std_logic;
      mcb_drp_clk                            : in  std_logic;
      mcb5_dram_dqs                          : inout  std_logic;
      mcb5_dram_dqs_n                        : inout  std_logic;
      mcb5_dram_ck                           : out  std_logic;
      mcb5_dram_ck_n                         : out  std_logic;
      p0_cmd_clk                            : in std_logic;
      p0_cmd_en                             : in std_logic;
      p0_cmd_instr                          : in std_logic_vector(2 downto 0);
      p0_cmd_bl                             : in std_logic_vector(5 downto 0);
      p0_cmd_byte_addr                      : in std_logic_vector(29 downto 0);
      p0_cmd_empty                          : out std_logic;
      p0_cmd_full                           : out std_logic;
      p0_wr_clk                             : in std_logic;
      p0_wr_en                              : in std_logic;
      p0_wr_mask                            : in std_logic_vector(C_P0_MASK_SIZE - 1 downto 0);
      p0_wr_data                            : in std_logic_vector(C_P0_DATA_PORT_SIZE - 1 downto 0);
      p0_wr_full                            : out std_logic;
      p0_wr_empty                           : out std_logic;
      p0_wr_count                           : out std_logic_vector(6 downto 0);
      p0_wr_underrun                        : out std_logic;
      p0_wr_error                           : out std_logic;
      p0_rd_clk                             : in std_logic;
      p0_rd_en                              : in std_logic;
      p0_rd_data                            : out std_logic_vector(C_P0_DATA_PORT_SIZE - 1 downto 0);
      p0_rd_full                            : out std_logic;
      p0_rd_empty                           : out std_logic;
      p0_rd_count                           : out std_logic_vector(6 downto 0);
      p0_rd_overflow                        : out std_logic;
      p0_rd_error                           : out std_logic;
      p1_cmd_clk                            : in std_logic;
      p1_cmd_en                             : in std_logic;
      p1_cmd_instr                          : in std_logic_vector(2 downto 0);
      p1_cmd_bl                             : in std_logic_vector(5 downto 0);
      p1_cmd_byte_addr                      : in std_logic_vector(29 downto 0);
      p1_cmd_empty                          : out std_logic;
      p1_cmd_full                           : out std_logic;
      p1_wr_clk                             : in std_logic;
      p1_wr_en                              : in std_logic;
      p1_wr_mask                            : in std_logic_vector(C_P1_MASK_SIZE - 1 downto 0);
      p1_wr_data                            : in std_logic_vector(C_P1_DATA_PORT_SIZE - 1 downto 0);
      p1_wr_full                            : out std_logic;
      p1_wr_empty                           : out std_logic;
      p1_wr_count                           : out std_logic_vector(6 downto 0);
      p1_wr_underrun                        : out std_logic;
      p1_wr_error                           : out std_logic;
      p1_rd_clk                             : in std_logic;
      p1_rd_en                              : in std_logic;
      p1_rd_data                            : out std_logic_vector(C_P1_DATA_PORT_SIZE - 1 downto 0);
      p1_rd_full                            : out std_logic;
      p1_rd_empty                           : out std_logic;
      p1_rd_count                           : out std_logic_vector(6 downto 0);
      p1_rd_overflow                        : out std_logic;
      p1_rd_error                           : out std_logic;
      selfrefresh_enter                     : in std_logic;
      selfrefresh_mode                      : out std_logic

      );
  end component;






   constant C5_CLKOUT0_DIVIDE       : integer := 1; --c5_sysclk_2x
   constant C5_CLKOUT1_DIVIDE       : integer := 1; --c5_sysclk_2x_180
   constant C5_CLKOUT2_DIVIDE       : integer := 16;--p_out_pll_gclkusr
   constant C5_CLKOUT3_DIVIDE       : integer := 8; --c5_mcb_drp_clk
   constant C5_CLKFBOUT_MULT        : integer := 2;
   constant C5_DIVCLK_DIVIDE        : integer := 1;

   constant C5_INCLK_PERIOD         : integer := ((C5_MEMCLK_PERIOD * C5_CLKFBOUT_MULT) / (C5_DIVCLK_DIVIDE * C5_CLKOUT0_DIVIDE * 2));

--   constant C5_CLKOUT0_DIVIDE       : integer := C_MEMPLL_CLKOUT0_DIVIDE;
--   constant C5_CLKOUT1_DIVIDE       : integer := C_MEMPLL_CLKOUT1_DIVIDE;
--   constant C5_CLKOUT2_DIVIDE       : integer := C_MEMPLL_CLKOUT2_DIVIDE;
--   constant C5_CLKOUT3_DIVIDE       : integer := C_MEMPLL_CLKOUT3_DIVIDE;
--   constant C5_CLKFBOUT_MULT        : integer := C_MEMPLL_CLKFBOUT_MULT ;
--   constant C5_DIVCLK_DIVIDE        : integer := C_MEMPLL_DIVCLK_DIVIDE ;
--
--   constant C5_INCLK_PERIOD         : integer := C5_MEMCLK_PERIOD;--((C5_MEMCLK_PERIOD * C5_CLKFBOUT_MULT) / (C5_DIVCLK_DIVIDE * C5_CLKOUT0_DIVIDE * 2));

   constant C5_ARB_NUM_TIME_SLOTS   : integer := 12;
   constant C5_ARB_TIME_SLOT_0      : bit_vector(5 downto 0) := o"02";
   constant C5_ARB_TIME_SLOT_1      : bit_vector(5 downto 0) := o"20";
   constant C5_ARB_TIME_SLOT_2      : bit_vector(5 downto 0) := o"02";
   constant C5_ARB_TIME_SLOT_3      : bit_vector(5 downto 0) := o"20";
   constant C5_ARB_TIME_SLOT_4      : bit_vector(5 downto 0) := o"02";
   constant C5_ARB_TIME_SLOT_5      : bit_vector(5 downto 0) := o"20";
   constant C5_ARB_TIME_SLOT_6      : bit_vector(5 downto 0) := o"02";
   constant C5_ARB_TIME_SLOT_7      : bit_vector(5 downto 0) := o"20";
   constant C5_ARB_TIME_SLOT_8      : bit_vector(5 downto 0) := o"02";
   constant C5_ARB_TIME_SLOT_9      : bit_vector(5 downto 0) := o"20";
   constant C5_ARB_TIME_SLOT_10     : bit_vector(5 downto 0) := o"02";
   constant C5_ARB_TIME_SLOT_11     : bit_vector(5 downto 0) := o"20";
   constant C5_MEM_TRAS             : integer := 40000;
   constant C5_MEM_TRCD             : integer := 15000;
   constant C5_MEM_TREFI            : integer := 7800000;
   constant C5_MEM_TRFC             : integer := 127500;
   constant C5_MEM_TRP              : integer := 15000;
   constant C5_MEM_TWR              : integer := 15000;
   constant C5_MEM_TRTP             : integer := 7500;
   constant C5_MEM_TWTR             : integer := 7500;
   constant C5_MEM_TYPE             : string := "DDR2";
   constant C5_MEM_DENSITY          : string := "1Gb";
   constant C5_MEM_BURST_LEN        : integer := 4;
   constant C5_MEM_CAS_LATENCY      : integer := 5;
   constant C5_MEM_NUM_COL_BITS     : integer := 10;
   constant C5_MEM_DDR1_2_ODS       : string := "FULL";
   constant C5_MEM_DDR2_RTT         : string := "50OHMS";
   constant C5_MEM_DDR2_DIFF_DQS_EN  : string := "YES";
   constant C5_MEM_DDR2_3_PA_SR     : string := "FULL";
   constant C5_MEM_DDR2_3_HIGH_TEMP_SR  : string := "NORMAL";
   constant C5_MEM_DDR3_CAS_LATENCY  : integer := 6;
   constant C5_MEM_DDR3_ODS         : string := "DIV6";
   constant C5_MEM_DDR3_RTT         : string := "DIV2";
   constant C5_MEM_DDR3_CAS_WR_LATENCY  : integer := 5;
   constant C5_MEM_DDR3_AUTO_SR     : string := "ENABLED";
   constant C5_MEM_DDR3_DYN_WRT_ODT  : string := "OFF";
   constant C5_MEM_MOBILE_PA_SR     : string := "FULL";
   constant C5_MEM_MDDR_ODS         : string := "FULL";
   constant C5_MC_CALIB_BYPASS      : string := "NO";
   constant C5_MC_CALIBRATION_MODE  : string := "CALIBRATION";
   constant C5_MC_CALIBRATION_DELAY  : string := "HALF";
   constant C5_SKIP_IN_TERM_CAL     : integer := 0;
   constant C5_SKIP_DYNAMIC_CAL     : integer := 0;
   constant C5_LDQSP_TAP_DELAY_VAL  : integer := 0;
   constant C5_LDQSN_TAP_DELAY_VAL  : integer := 0;
   constant C5_UDQSP_TAP_DELAY_VAL  : integer := 0;
   constant C5_UDQSN_TAP_DELAY_VAL  : integer := 0;
   constant C5_DQ0_TAP_DELAY_VAL    : integer := 0;
   constant C5_DQ1_TAP_DELAY_VAL    : integer := 0;
   constant C5_DQ2_TAP_DELAY_VAL    : integer := 0;
   constant C5_DQ3_TAP_DELAY_VAL    : integer := 0;
   constant C5_DQ4_TAP_DELAY_VAL    : integer := 0;
   constant C5_DQ5_TAP_DELAY_VAL    : integer := 0;
   constant C5_DQ6_TAP_DELAY_VAL    : integer := 0;
   constant C5_DQ7_TAP_DELAY_VAL    : integer := 0;
   constant C5_DQ8_TAP_DELAY_VAL    : integer := 0;
   constant C5_DQ9_TAP_DELAY_VAL    : integer := 0;
   constant C5_DQ10_TAP_DELAY_VAL   : integer := 0;
   constant C5_DQ11_TAP_DELAY_VAL   : integer := 0;
   constant C5_DQ12_TAP_DELAY_VAL   : integer := 0;
   constant C5_DQ13_TAP_DELAY_VAL   : integer := 0;
   constant C5_DQ14_TAP_DELAY_VAL   : integer := 0;
   constant C5_DQ15_TAP_DELAY_VAL   : integer := 0;
   constant C5_SMALL_DEVICE         : string := "FALSE"; -- The parameter is set to TRUE for all packages of xc6slx9 device
                                                         -- as most of them cannot fit the complete example design when the
                                                         -- Chip scope modules are enabled

  signal  c5_sys_clk_p                             : std_logic;
  signal  c5_sys_clk_n                             : std_logic;
  signal  c5_async_rst                             : std_logic;
  signal  c5_sysclk_2x                             : std_logic;
  signal  c5_sysclk_2x_180                         : std_logic;
  signal  c5_pll_ce_0                              : std_logic;
  signal  c5_pll_ce_90                             : std_logic;
  signal  c5_pll_lock                              : std_logic;
  signal  c5_mcb_drp_clk                           : std_logic;
  signal  c5_cmp_error                             : std_logic;
  signal  c5_cmp_data_valid                        : std_logic;
  signal  c5_vio_modify_enable                     : std_logic;
  signal  c5_error_status                          : std_logic_vector(191 downto 0);
  signal  c5_vio_data_mode_value                   : std_logic_vector(2 downto 0);
  signal  c5_vio_addr_mode_value                   : std_logic_vector(2 downto 0);
  signal  c5_cmp_data                              : std_logic_vector(31 downto 0);
  signal  c5_selfrefresh_enter                     : std_logic;
  signal  c5_selfrefresh_mode                      : std_logic;



begin


c5_sys_clk_p <= '0';
c5_sys_clk_n <= '0';
--c5_selfrefresh_enter <= '0';
memc5_infrastructure_inst : memc5_infrastructure
generic map(
C_RST_ACT_LOW     => C5_RST_ACT_LOW,--0,--
C_INPUT_CLK_TYPE  => C5_INPUT_CLK_TYPE,
C_CLKOUT0_DIVIDE  => C5_CLKOUT0_DIVIDE,
C_CLKOUT1_DIVIDE  => C5_CLKOUT1_DIVIDE,
C_CLKOUT2_DIVIDE  => C5_CLKOUT2_DIVIDE,
C_CLKOUT3_DIVIDE  => C5_CLKOUT3_DIVIDE,
C_CLKFBOUT_MULT   => C5_CLKFBOUT_MULT,
C_DIVCLK_DIVIDE   => C5_DIVCLK_DIVIDE,
C_INCLK_PERIOD    => C5_INCLK_PERIOD
)
port map(
sys_clk_p         => c5_sys_clk_p,
sys_clk_n         => c5_sys_clk_n,
sys_clk           => p_in_sys.clk,--c5_sys_clk,
sys_rst_i         => p_in_sys.rst,--c5_sys_rst_i,
clk0              => p_out_sys.clk,--open,-- C5_CLKOUT2_DIVIDE,
rst0              => open,--c5_rst0,
async_rst         => c5_async_rst,
sysclk_2x         => c5_sysclk_2x,
sysclk_2x_180     => c5_sysclk_2x_180,
pll_ce_0          => c5_pll_ce_0,
pll_ce_90         => c5_pll_ce_90,
pll_lock          => c5_pll_lock,
mcb_drp_clk       => c5_mcb_drp_clk
);


-- wrapper instantiation
gen_bank : for i in 0 to C_MEM_BANK_COUNT-1 generate

 memc5_wrapper_inst : memc5_wrapper

generic map
 (
   C_MEMCLK_PERIOD                   => C5_MEMCLK_PERIOD,
   C_CALIB_SOFT_IP                   => C5_CALIB_SOFT_IP,
   C_SIMULATION                      => C5_SIMULATION,
   C_P0_MASK_SIZE                    => C5_P0_MASK_SIZE,
   C_P0_DATA_PORT_SIZE               => C5_P0_DATA_PORT_SIZE,
   C_P1_MASK_SIZE                    => C5_P1_MASK_SIZE,
   C_P1_DATA_PORT_SIZE               => C5_P1_DATA_PORT_SIZE,
   C_ARB_NUM_TIME_SLOTS              => C5_ARB_NUM_TIME_SLOTS,
   C_ARB_TIME_SLOT_0                 => C5_ARB_TIME_SLOT_0,
   C_ARB_TIME_SLOT_1                 => C5_ARB_TIME_SLOT_1,
   C_ARB_TIME_SLOT_2                 => C5_ARB_TIME_SLOT_2,
   C_ARB_TIME_SLOT_3                 => C5_ARB_TIME_SLOT_3,
   C_ARB_TIME_SLOT_4                 => C5_ARB_TIME_SLOT_4,
   C_ARB_TIME_SLOT_5                 => C5_ARB_TIME_SLOT_5,
   C_ARB_TIME_SLOT_6                 => C5_ARB_TIME_SLOT_6,
   C_ARB_TIME_SLOT_7                 => C5_ARB_TIME_SLOT_7,
   C_ARB_TIME_SLOT_8                 => C5_ARB_TIME_SLOT_8,
   C_ARB_TIME_SLOT_9                 => C5_ARB_TIME_SLOT_9,
   C_ARB_TIME_SLOT_10                => C5_ARB_TIME_SLOT_10,
   C_ARB_TIME_SLOT_11                => C5_ARB_TIME_SLOT_11,
   C_MEM_TRAS                        => C5_MEM_TRAS,
   C_MEM_TRCD                        => C5_MEM_TRCD,
   C_MEM_TREFI                       => C5_MEM_TREFI,
   C_MEM_TRFC                        => C5_MEM_TRFC,
   C_MEM_TRP                         => C5_MEM_TRP,
   C_MEM_TWR                         => C5_MEM_TWR,
   C_MEM_TRTP                        => C5_MEM_TRTP,
   C_MEM_TWTR                        => C5_MEM_TWTR,
   C_MEM_ADDR_ORDER                  => C5_MEM_ADDR_ORDER,
   C_NUM_DQ_PINS                     => C5_NUM_DQ_PINS,
   C_MEM_TYPE                        => C5_MEM_TYPE,
   C_MEM_DENSITY                     => C5_MEM_DENSITY,
   C_MEM_BURST_LEN                   => C5_MEM_BURST_LEN,
   C_MEM_CAS_LATENCY                 => C5_MEM_CAS_LATENCY,
   C_MEM_ADDR_WIDTH                  => C5_MEM_ADDR_WIDTH,
   C_MEM_BANKADDR_WIDTH              => C5_MEM_BANKADDR_WIDTH,
   C_MEM_NUM_COL_BITS                => C5_MEM_NUM_COL_BITS,
   C_MEM_DDR1_2_ODS                  => C5_MEM_DDR1_2_ODS,
   C_MEM_DDR2_RTT                    => C5_MEM_DDR2_RTT,
   C_MEM_DDR2_DIFF_DQS_EN            => C5_MEM_DDR2_DIFF_DQS_EN,
   C_MEM_DDR2_3_PA_SR                => C5_MEM_DDR2_3_PA_SR,
   C_MEM_DDR2_3_HIGH_TEMP_SR         => C5_MEM_DDR2_3_HIGH_TEMP_SR,
   C_MEM_DDR3_CAS_LATENCY            => C5_MEM_DDR3_CAS_LATENCY,
   C_MEM_DDR3_ODS                    => C5_MEM_DDR3_ODS,
   C_MEM_DDR3_RTT                    => C5_MEM_DDR3_RTT,
   C_MEM_DDR3_CAS_WR_LATENCY         => C5_MEM_DDR3_CAS_WR_LATENCY,
   C_MEM_DDR3_AUTO_SR                => C5_MEM_DDR3_AUTO_SR,
   C_MEM_DDR3_DYN_WRT_ODT            => C5_MEM_DDR3_DYN_WRT_ODT,
   C_MEM_MOBILE_PA_SR                => C5_MEM_MOBILE_PA_SR,
   C_MEM_MDDR_ODS                    => C5_MEM_MDDR_ODS,
   C_MC_CALIB_BYPASS                 => C5_MC_CALIB_BYPASS,
   C_MC_CALIBRATION_MODE             => C5_MC_CALIBRATION_MODE,
   C_MC_CALIBRATION_DELAY            => C5_MC_CALIBRATION_DELAY,
   C_SKIP_IN_TERM_CAL                => C5_SKIP_IN_TERM_CAL,
   C_SKIP_DYNAMIC_CAL                => C5_SKIP_DYNAMIC_CAL,
   C_LDQSP_TAP_DELAY_VAL             => C5_LDQSP_TAP_DELAY_VAL,
   C_LDQSN_TAP_DELAY_VAL             => C5_LDQSN_TAP_DELAY_VAL,
   C_UDQSP_TAP_DELAY_VAL             => C5_UDQSP_TAP_DELAY_VAL,
   C_UDQSN_TAP_DELAY_VAL             => C5_UDQSN_TAP_DELAY_VAL,
   C_DQ0_TAP_DELAY_VAL               => C5_DQ0_TAP_DELAY_VAL,
   C_DQ1_TAP_DELAY_VAL               => C5_DQ1_TAP_DELAY_VAL,
   C_DQ2_TAP_DELAY_VAL               => C5_DQ2_TAP_DELAY_VAL,
   C_DQ3_TAP_DELAY_VAL               => C5_DQ3_TAP_DELAY_VAL,
   C_DQ4_TAP_DELAY_VAL               => C5_DQ4_TAP_DELAY_VAL,
   C_DQ5_TAP_DELAY_VAL               => C5_DQ5_TAP_DELAY_VAL,
   C_DQ6_TAP_DELAY_VAL               => C5_DQ6_TAP_DELAY_VAL,
   C_DQ7_TAP_DELAY_VAL               => C5_DQ7_TAP_DELAY_VAL,
   C_DQ8_TAP_DELAY_VAL               => C5_DQ8_TAP_DELAY_VAL,
   C_DQ9_TAP_DELAY_VAL               => C5_DQ9_TAP_DELAY_VAL,
   C_DQ10_TAP_DELAY_VAL              => C5_DQ10_TAP_DELAY_VAL,
   C_DQ11_TAP_DELAY_VAL              => C5_DQ11_TAP_DELAY_VAL,
   C_DQ12_TAP_DELAY_VAL              => C5_DQ12_TAP_DELAY_VAL,
   C_DQ13_TAP_DELAY_VAL              => C5_DQ13_TAP_DELAY_VAL,
   C_DQ14_TAP_DELAY_VAL              => C5_DQ14_TAP_DELAY_VAL,
   C_DQ15_TAP_DELAY_VAL              => C5_DQ15_TAP_DELAY_VAL
   )
port map(
mcb5_dram_dq       => p_inout_phymem(i).dq,    --mcb5_dram_dq     : inout std_logic_vector((C_NUM_DQ_PINS-1) downto 0);
mcb5_dram_a        => p_out_phymem  (i).a,     --mcb5_dram_a      : out   std_logic_vector((C_MEM_ADDR_WIDTH-1) downto 0);
mcb5_dram_ba       => p_out_phymem  (i).ba,    --mcb5_dram_ba     : out   std_logic_vector((C_MEM_BANKADDR_WIDTH-1) downto 0);
mcb5_dram_ras_n    => p_out_phymem  (i).ras_n, --mcb5_dram_ras_n  : out   std_logic;
mcb5_dram_cas_n    => p_out_phymem  (i).cas_n, --mcb5_dram_cas_n  : out   std_logic;
mcb5_dram_we_n     => p_out_phymem  (i).we_n,  --mcb5_dram_we_n   : out   std_logic;
mcb5_dram_odt      => p_out_phymem  (i).odt,   --mcb5_dram_odt    : out   std_logic;
mcb5_dram_cke      => p_out_phymem  (i).cke,   --mcb5_dram_cke    : out   std_logic;
mcb5_dram_dm       => p_out_phymem  (i).dm,    --mcb5_dram_dm     : out   std_logic;
mcb5_dram_udqs     => p_inout_phymem(i).udqs,  --mcb5_dram_udqs   : inout std_logic;
mcb5_dram_udqs_n   => p_inout_phymem(i).udqs_n,--mcb5_dram_udqs_n : inout std_logic;
mcb5_rzq           => p_inout_phymem(i).rzq,   --mcb5_rzq         : inout std_logic;
mcb5_zio           => p_inout_phymem(i).zio,   --mcb5_zio         : inout std_logic;
mcb5_dram_udm      => p_out_phymem  (i).udm,   --mcb5_dram_udm    : out   std_logic;
mcb5_dram_dqs      => p_inout_phymem(i).dqs,   --mcb5_dram_dqs    : inout std_logic;
mcb5_dram_dqs_n    => p_inout_phymem(i).dqs_n, --mcb5_dram_dqs_n  : inout std_logic;
mcb5_dram_ck       => p_out_phymem  (i).ck,    --mcb5_dram_ck     : out   std_logic;
mcb5_dram_ck_n     => p_out_phymem  (i).ck_n,  --mcb5_dram_ck_n   : out   std_logic;
mcb_drp_clk        => c5_mcb_drp_clk,

p0_cmd_clk         => p_in_mem (i)(0).clk,                                       --p0_cmd_clk       : in std_logic;
p0_cmd_en          => p_in_mem (i)(0).cmd_wr,                                    --p0_cmd_en        : in std_logic;
p0_cmd_instr       => p_in_mem (i)(0).cmd_i,                                     --p0_cmd_instr     : in std_logic_vector(2 downto 0);
p0_cmd_bl          => p_in_mem (i)(0).cmd_bl,                                    --p0_cmd_bl        : in std_logic_vector(5 downto 0);
p0_cmd_byte_addr   => p_in_mem (i)(0).adr(C_MEMCTRL_AWIDTH-1 downto 0),          --p0_cmd_byte_addr : in std_logic_vector(29 downto 0);
p0_cmd_empty       => p_out_mem(i)(0).cmdbuf_empty,                              --p0_cmd_empty     : out std_logic;
p0_cmd_full        => p_out_mem(i)(0).cmdbuf_full,                               --p0_cmd_full      : out std_logic;
p0_wr_clk          => p_in_mem (i)(0).clk,                                       --p0_wr_clk        : in std_logic;
p0_wr_en           => p_in_mem (i)(0).txd_wr,                                    --p0_wr_en         : in std_logic;
p0_wr_mask         => p_in_mem (i)(0).txd_be(C_MEMCTRL_CH0_BEWIDTH - 1 downto 0),--p0_wr_mask       : in std_logic_vector(C_P0_MASK_SIZE - 1 downto 0);
p0_wr_data         => p_in_mem (i)(0).txd(C_MEMCTRL_CH0_DWIDTH - 1 downto 0),    --p0_wr_data       : in std_logic_vector(C_P0_DATA_PORT_SIZE - 1 downto 0);
p0_wr_full         => p_out_mem(i)(0).txbuf_full,                                --p0_wr_full       : out std_logic;
p0_wr_empty        => p_out_mem(i)(0).txbuf_empty,                               --p0_wr_empty      : out std_logic;
p0_wr_count        => p_out_mem(i)(0).txbuf_wrcount,                             --p0_wr_count      : out std_logic_vector(6 downto 0);
p0_wr_underrun     => p_out_mem(i)(0).txbuf_underrun,                            --p0_wr_underrun   : out std_logic;
p0_wr_error        => p_out_mem(i)(0).txbuf_err,                                 --p0_wr_error      : out std_logic;
p0_rd_clk          => p_in_mem (i)(0).clk,                                       --p0_rd_clk        : in std_logic;
p0_rd_en           => p_in_mem (i)(0).rxd_rd,                                    --p0_rd_en         : in std_logic;
p0_rd_data         => p_out_mem(i)(0).rxd(C_MEMCTRL_CH0_DWIDTH - 1 downto 0),    --p0_rd_data       : out std_logic_vector(C_P0_DATA_PORT_SIZE - 1 downto 0);
p0_rd_full         => p_out_mem(i)(0).rxbuf_full,                                --p0_rd_full       : out std_logic;
p0_rd_empty        => p_out_mem(i)(0).rxbuf_empty,                               --p0_rd_empty      : out std_logic;
p0_rd_count        => p_out_mem(i)(0).rxbuf_rdcount,                             --p0_rd_count      : out std_logic_vector(6 downto 0);
p0_rd_overflow     => p_out_mem(i)(0).rxbuf_overflow,                            --p0_rd_overflow   : out std_logic;
p0_rd_error        => p_out_mem(i)(0).rxbuf_err,                                 --p0_rd_error      : out std_logic;

p1_cmd_clk         => p_in_mem (i)(1).clk,                                        --p0_cmd_clk       : in std_logic;
p1_cmd_en          => p_in_mem (i)(1).cmd_wr,                                    --p0_cmd_en        : in std_logic;
p1_cmd_instr       => p_in_mem (i)(1).cmd_i,                                     --p0_cmd_instr     : in std_logic_vector(2 downto 0);
p1_cmd_bl          => p_in_mem (i)(1).cmd_bl,                                    --p0_cmd_bl        : in std_logic_vector(5 downto 0);
p1_cmd_byte_addr   => p_in_mem (i)(1).adr(C_MEMCTRL_AWIDTH-1 downto 0),          --p0_cmd_byte_addr : in std_logic_vector(29 downto 0);
p1_cmd_empty       => p_out_mem(i)(1).cmdbuf_empty,                              --p0_cmd_empty     : out std_logic;
p1_cmd_full        => p_out_mem(i)(1).cmdbuf_full,                               --p0_cmd_full      : out std_logic;
p1_wr_clk          => p_in_mem (i)(1).clk,                                       --p0_wr_clk        : in std_logic;
p1_wr_en           => p_in_mem (i)(1).txd_wr,                                    --p0_wr_en         : in std_logic;
p1_wr_mask         => p_in_mem (i)(1).txd_be(C_MEMCTRL_CH1_BEWIDTH - 1 downto 0),--p0_wr_mask       : in std_logic_vector(C_P0_MASK_SIZE - 1 downto 0);
p1_wr_data         => p_in_mem (i)(1).txd(C_MEMCTRL_CH1_DWIDTH - 1 downto 0),    --p0_wr_data       : in std_logic_vector(C_P0_DATA_PORT_SIZE - 1 downto 0);
p1_wr_full         => p_out_mem(i)(1).txbuf_full,                                --p0_wr_full       : out std_logic;
p1_wr_empty        => p_out_mem(i)(1).txbuf_empty,                               --p0_wr_empty      : out std_logic;
p1_wr_count        => p_out_mem(i)(1).txbuf_wrcount,                             --p0_wr_count      : out std_logic_vector(6 downto 0);
p1_wr_underrun     => p_out_mem(i)(1).txbuf_underrun,                            --p0_wr_underrun   : out std_logic;
p1_wr_error        => p_out_mem(i)(1).txbuf_err,                                 --p0_wr_error      : out std_logic;
p1_rd_clk          => p_in_mem (i)(1).clk,                                       --p0_rd_clk        : in std_logic;
p1_rd_en           => p_in_mem (i)(1).rxd_rd,                                    --p0_rd_en         : in std_logic;
p1_rd_data         => p_out_mem(i)(1).rxd(C_MEMCTRL_CH1_DWIDTH - 1 downto 0),    --p0_rd_data       : out std_logic_vector(C_P0_DATA_PORT_SIZE - 1 downto 0);
p1_rd_full         => p_out_mem(i)(1).rxbuf_full,                                --p0_rd_full       : out std_logic;
p1_rd_empty        => p_out_mem(i)(1).rxbuf_empty,                               --p0_rd_empty      : out std_logic;
p1_rd_count        => p_out_mem(i)(1).rxbuf_rdcount,                             --p0_rd_count      : out std_logic_vector(6 downto 0);
p1_rd_overflow     => p_out_mem(i)(1).rxbuf_overflow,                            --p0_rd_overflow   : out std_logic;
p1_rd_error        => p_out_mem(i)(1).rxbuf_err,                                 --p0_rd_error      : out std_logic;

selfrefresh_enter  => '0',--c5_selfrefresh_enter,
selfrefresh_mode   => open,--c5_selfrefresh_mode,

calib_done         => p_out_status.rdy(i),--c5_calib_done,
async_rst          => c5_async_rst,
sysclk_2x          => c5_sysclk_2x,
sysclk_2x_180      => c5_sysclk_2x_180,
pll_ce_0           => c5_pll_ce_0,
pll_ce_90          => c5_pll_ce_90,
pll_lock           => c5_pll_lock
);

--p_out_mem(i).rxd<=(others=>'0');
--p_out_mem(i).rxbuf_full<='1';
--p_out_mem(i).rxbuf_empty<='1';
--p_out_mem(i).rxbuf_rdcount<=(others=>'0');
--p_out_mem(i).rxbuf_overflow<='0';
--p_out_mem(i).rxbuf_err<='0';
--
--p_out_mem(i).txbuf_full<='1';
--p_out_mem(i).txbuf_empty<='1';
--p_out_mem(i).txbuf_wrcount<=(others=>'0');
--p_out_mem(i).txbuf_underrun<='0';
--p_out_mem(i).txbuf_err<='0';

end generate gen_bank;


gen_bank2_null : if C_MEM_BANK_COUNT=1 generate
p_out_phymem  (1).a        <= (others=>'Z');
p_out_phymem  (1).ba       <= (others=>'Z');
p_out_phymem  (1).ras_n    <= 'Z';
p_out_phymem  (1).cas_n    <= 'Z';
p_out_phymem  (1).we_n     <= 'Z';
p_out_phymem  (1).odt      <= 'Z';
p_out_phymem  (1).cke      <= 'Z';
p_out_phymem  (1).dm       <= 'Z';
p_out_phymem  (1).udm      <= 'Z';
p_out_phymem  (1).ck       <= 'Z';
p_out_phymem  (1).ck_n     <= 'Z';
p_inout_phymem(1).dq     <= (others=>'Z');
p_inout_phymem(1).udqs   <= 'Z';
p_inout_phymem(1).udqs_n <= 'Z';
p_inout_phymem(1).dqs    <= 'Z';
p_inout_phymem(1).dqs_n  <= 'Z';
p_inout_phymem(1).rzq    <= 'Z';
p_inout_phymem(1).zio    <= 'Z';

end generate gen_bank2_null;


end  arc;
