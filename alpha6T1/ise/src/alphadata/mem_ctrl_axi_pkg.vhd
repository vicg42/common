-------------------------------------------------------------------------
-- Company     : Linkos
-- Engineer    : Golovachenko Victor
--
-- Create Date : 14.10.2011 18:38:37
-- Module Name : mem_ctrl_pkg
--
-- Description :
--
-- Revision:
-- Revision 0.01 - File Created
--
-------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_misc.all;
use ieee.std_logic_unsigned.all;

library work;
use work.vicg_common_pkg.all;
use work.prj_cfg.all;
use work.mem_wr_pkg.all;
use work.mem_glob_pkg.all;

package mem_ctrl_pkg is

constant C_AXIS_IDWIDTH    : integer:=4;
constant C_AXIM_IDWIDTH    : integer:=8;

constant C_AXI_AWIDTH      : integer:=32;
constant C_AXIM_DWIDTH     : integer:=C_PCGF_PCIE_DWIDTH;

type TAXIS_DWIDTH is array (0 to C_MEMCH_COUNT_MAX - 1) of integer;
------------------------------------------------------------------------------------------------------------
--                              slave num   | 0 | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 10| 11| 12| 13| 14| 15|
------------------------------------------------------------------------------------------------------------
constant C_AXIS_DWIDTH     : TAXIS_DWIDTH := (
C_PCGF_PCIE_DWIDTH,
32,
C_PCGF_PCIE_DWIDTH,
C_PCGF_PCIE_DWIDTH,
C_PCGF_PCIE_DWIDTH,
C_PCGF_PCIE_DWIDTH,
C_PCGF_PCIE_DWIDTH,
C_PCGF_PCIE_DWIDTH);

constant C_MEM_ARB_CH_COUNT  : integer := C_PCFG_MEMARB_CH_COUNT;

constant C_AXI_SUPPORTS_NARROW_BURST: integer:=1;
constant C_AXI_REG_EN0              : integer:=0;
constant C_AXI_REG_EN1              : integer:=0;

--type target_use_t    is (SIM_ON,SIM_OFF);
---- Select target use
--constant C_MEMCTRL_SIM                       : target_use_t := SIM_OFF;
--constant TARGET_USE       : target_use_t := C_MEMCTRL_SIM;
-- Define maximum number of memory banks
constant MAX_MEM_BANKS    : natural := 4;

-- Target FPGA DDR3 SDRAM interface
--  constant DDR3_VALID : boolean := true;
constant DDR3_BANKS : natural range 0 to MAX_MEM_BANKS := C_PCFG_MEMCTRL_BANK_COUNT; --4;

-- DDR3 memory interface widths
constant DDR3_BANK_ROW_WIDTH : natural := 13; -- 1 Gb Part = 8K x 16 x 8 banks
--  constant DDR3_BANK_ROW_WIDTH : natural := 14; -- 2 Gb Part = 16K x 16 x 8 banks
constant DDR3_BANK_DATA_WIDTH : natural := 32; -- 2 off 16-bit parts

-- MIG interface address width = Bank(3)+Row(13/14)+Col(10) and convert to byte addressing (+2)
constant DDR3_BYTE_ADDR_WIDTH : natural := 3 + DDR3_BANK_ROW_WIDTH + 10 + 2;

-- Convert to 16-byte addressing
constant DDR3_16_BYTE_ADDR_WIDTH : natural := DDR3_BYTE_ADDR_WIDTH - 4;


-- Target FPGA memory interface
--  constant MEM_VALID : boolean := DDR3_VALID;
constant MEM_BANKS : natural range 0 to MAX_MEM_BANKS := DDR3_BANKS;


-- DDR3 memory interface types
type ddr3_addr_out_t is record
a : std_logic_vector(DDR3_BANK_ROW_WIDTH-1 downto 0);
end record;

type ddr3_ctrl_out_t is record
ras_l   : std_logic;
cas_l   : std_logic;
we_l    : std_logic;
cs_l    : std_logic_vector(0 downto 0);
dm      : std_logic_vector((DDR3_BANK_DATA_WIDTH/8)-1  downto 0);
ba      : std_logic_vector(2 downto 0);
reset_l : std_logic;
odt     : std_logic_vector(0 downto 0);
cke     : std_logic_vector(0 downto 0);
end record;

type ddr3_data_inout_t is record
dq    : std_logic_vector(DDR3_BANK_DATA_WIDTH-1 downto 0);
dqs_p : std_logic_vector((DDR3_BANK_DATA_WIDTH/8)-1 downto 0);
dqs_n : std_logic_vector((DDR3_BANK_DATA_WIDTH/8)-1 downto 0);
end record;

type ddr3_clk_out_t is record
clk_p : std_logic_vector(0 downto 0);
clk_n : std_logic_vector(0 downto 0);
end record;

type ddr3_addr_out_array_t   is array (0 to DDR3_BANKS-1) of ddr3_addr_out_t;
type ddr3_ctrl_out_array_t   is array (0 to DDR3_BANKS-1) of ddr3_ctrl_out_t;
type ddr3_data_inout_array_t is array (0 to DDR3_BANKS-1) of ddr3_data_inout_t;
type ddr3_clk_out_array_t    is array (0 to DDR3_BANKS-1) of ddr3_clk_out_t;

type mem_addr_out_t is record
ddr3_addr_out : ddr3_addr_out_array_t;
end record;

type mem_ctrl_out_t is record
ddr3_ctrl_out : ddr3_ctrl_out_array_t;
end record;

type mem_data_inout_t is record
ddr3_data_inout : ddr3_data_inout_array_t;
end record;

type mem_clk_out_t is record
ddr3_clk_out : ddr3_clk_out_array_t;
end record;


-- Functions used to resolve correct settings for simulation/synthesis
function conv_sim_bypass_init_cal(
constant val: in string)
return string;

function conv_sim_init_option(
constant val: in string)
return string;

function conv_sim_cal_option(
constant val: in string)
return string;
--function conv_sim_bypass_init_cal(
--constant val: in target_use_t)
--return string;
--
--function conv_sim_init_option(
--constant val: in target_use_t)
--return string;
--
--function conv_sim_cal_option(
--constant val: in target_use_t)
--return string;


--------------------------------------------
-- DDR3 MIG core version 3.6 declarations --
--------------------------------------------

-- Define clocking generics
type mig_v3_6_clocks_t is record
REFCLK_FREQ     : real;
IODELAY_GRP     : string(1 to 11);
CLKFBOUT_MULT_F : integer;
DIVCLK_DIVIDE   : integer;
CLKOUT_DIVIDE   : integer;
nCK_PER_CLK     : integer;
tCK             : integer;
RST_ACT_LOW     : integer;
INPUT_CLK_TYPE  : string(1 to 12);
STARVE_LIMIT    : integer;
end record;

constant MIG_V3_6_CLOCKS : mig_v3_6_clocks_t :=
(REFCLK_FREQ      => 200.0,
 IODELAY_GRP      => "IODELAY_MIG",
 CLKFBOUT_MULT_F  => 6,
 DIVCLK_DIVIDE    => 2,
 CLKOUT_DIVIDE    => 3,
 nCK_PER_CLK      => 2,
 tCK              => 2500,
 RST_ACT_LOW      => 0,  -- Changed from 1 (active low)
 INPUT_CLK_TYPE   => "SINGLE_ENDED",
 STARVE_LIMIT     => 2);


-- Define common generics
type mig_v3_6_common_t is record
DEBUG_PORT      : string(1 to 3);
nCS_PER_RANK    : integer;
DQS_CNT_WIDTH   : integer;
RANK_WIDTH      : integer;
BANK_WIDTH      : integer;
CK_WIDTH        : integer;
CKE_WIDTH       : integer;
COL_WIDTH       : integer;
CS_WIDTH        : integer;
DM_WIDTH        : integer;
DQ_WIDTH        : integer;
DQS_WIDTH       : integer;
ROW_WIDTH       : integer;
BURST_MODE      : string(1 to 3);
BM_CNT_WIDTH    : integer;
ADDR_CMD_MODE   : string(1 to 5);
ORDERING        : string(1 to 4);
WRLVL           : string(1 to 2);
PHASE_DETECT    : string(1 to 2);
RTT_NOM         : string(1 to 2);
RTT_WR          : string(1 to 3);
OUTPUT_DRV      : string(1 to 4);
REG_CTRL        : string(1 to 3);
tPRDI           : integer;
tREFI           : integer;
tZQI            : integer;
tRFC            : integer;
ADDR_WIDTH      : integer;
ECC_TEST        : string(1 to 3);
TCQ             : integer;
DATA_WIDTH      : integer;
PAYLOAD_WIDTH   : integer;
end record;

constant MIG_V3_6_COMMON : mig_v3_6_common_t :=
(DEBUG_PORT       => "OFF",
 nCS_PER_RANK     => 1,
 DQS_CNT_WIDTH    => 2,
 RANK_WIDTH       => 1,
 BANK_WIDTH       => 3,
 CK_WIDTH         => 1,
 CKE_WIDTH        => 1,
 COL_WIDTH        => 10,
 CS_WIDTH         => 1,
 DM_WIDTH         => 4,
 DQ_WIDTH         => 32,
 DQS_WIDTH        => 4,
 ROW_WIDTH        => DDR3_BANK_ROW_WIDTH,  -- 13 for 1Gib devices, 14 for 2Gib devices
 BURST_MODE       => "OTF",
 BM_CNT_WIDTH     => 2,
 ADDR_CMD_MODE    => "UNBUF",
 ORDERING         => "NORM",
 WRLVL            => "ON",
 PHASE_DETECT     => "ON",
 RTT_NOM          => "60",
 RTT_WR           => "OFF",
 OUTPUT_DRV       => "HIGH",
 REG_CTRL         => "OFF",
 tPRDI            => 1000000,
 tREFI            => 7800000,
 tZQI             => 128000000,
 tRFC             => 160000,  -- >160ns for 2Gb devices (>110ns for 1Gb devices)
 ADDR_WIDTH       => DDR3_BYTE_ADDR_WIDTH-1, -- 27 for 1Gib devices, 28 for 2Gib devices
 ECC_TEST         => "OFF",
 TCQ              => 100,
 DATA_WIDTH       => 32,
 PAYLOAD_WIDTH    => 32);


-- Define column generics
type mig_v3_6_bank01_t is record
nDQS_COL0       : integer;
nDQS_COL1       : integer;
nDQS_COL2       : integer;
nDQS_COL3       : integer;
DQS_LOC_COL0    : std_logic_vector(31 downto 0);
DQS_LOC_COL1    : std_logic_vector(0 downto 0);
DQS_LOC_COL2    : std_logic_vector(0 downto 0);
DQS_LOC_COL3    : std_logic_vector(0 downto 0);
end record;

constant MIG_V3_6_BANK01 : mig_v3_6_bank01_t :=
(nDQS_COL0        => 4,
 nDQS_COL1        => 0,
 nDQS_COL2        => 0,
 nDQS_COL3        => 0,
 DQS_LOC_COL0     => X"03020100",
 DQS_LOC_COL1     => "0",
 DQS_LOC_COL2     => "0",
 DQS_LOC_COL3     => "0");

type mig_v3_6_bank2_t is record
nDQS_COL0       : integer;
nDQS_COL1       : integer;
nDQS_COL2       : integer;
nDQS_COL3       : integer;
DQS_LOC_COL0    : std_logic_vector(0 downto 0);
DQS_LOC_COL1    : std_logic_vector(0 downto 0);
DQS_LOC_COL2    : std_logic_vector(31 downto 0);
DQS_LOC_COL3    : std_logic_vector(0 downto 0);
end record;

constant MIG_V3_6_BANK2 : mig_v3_6_bank2_t :=
(nDQS_COL0        => 0,
 nDQS_COL1        => 0,
 nDQS_COL2        => 4,
 nDQS_COL3        => 0,
 DQS_LOC_COL0     => "0",
 DQS_LOC_COL1     => "0",
 DQS_LOC_COL2     => X"03020100",
 DQS_LOC_COL3     => "0");

type mig_v3_6_bank3_t is record
nDQS_COL0       : integer;
nDQS_COL1       : integer;
nDQS_COL2       : integer;
nDQS_COL3       : integer;
DQS_LOC_COL0    : std_logic_vector(15 downto 0);
DQS_LOC_COL1    : std_logic_vector(15 downto 0);
DQS_LOC_COL2    : std_logic_vector(0 downto 0);
DQS_LOC_COL3    : std_logic_vector(0 downto 0);
end record;

constant MIG_V3_6_BANK3 : mig_v3_6_bank3_t :=
(nDQS_COL0        => 2,
 nDQS_COL1        => 2,
 nDQS_COL2        => 0,
 nDQS_COL3        => 0,
 DQS_LOC_COL0     => X"0100",
 DQS_LOC_COL1     => X"0302",
 DQS_LOC_COL2     => "0",
 DQS_LOC_COL3     => "0");




-- Types for memory interface
type mem_if_stat_array_t   is array(0 to MEM_BANKS-1) of std_logic_vector(3 downto 0);
type mem_if_err_array_t    is array(0 to MEM_BANKS-1) of std_logic_vector(3 downto 0);
type mem_if_rdy_array_t    is array(0 to MEM_BANKS-1) of std_logic;
type mem_if_debug_array_t  is array(0 to MEM_BANKS-1) of std_logic_vector(31 downto 0);

Type TMemINBank  is array (0 to MEM_BANKS - 1) of TMemIN; --TMemINCh;
Type TMemOUTBank is array (0 to MEM_BANKS - 1) of TMemOUT;--TMemOUTCh;

Type TMemINCh is array (0 to C_MEM_ARB_CH_COUNT - 1) of TMemIN;
Type TMemOUTCh is array (0 to C_MEM_ARB_CH_COUNT - 1) of TMemOUT;

type TMEMCTRL_status is record
rdy      : std_logic_vector(MEM_BANKS-1 downto 0);
stat     : mem_if_stat_array_t;
err      : mem_if_err_array_t;
err_info : mem_if_debug_array_t;
end record;

type TMEMCTRL_sysin is record
clk   : std_logic;
ref_clk: std_logic;
rst   : std_logic;
end record;

type TMEMCTRL_sysout is record
gusrclk: std_logic_vector(0 downto 0);
clk   : std_logic;
end record;

type TMEMCTRL_phy_outs is record
adr : ddr3_addr_out_array_t; --type ddr3_addr_out_array_t   is array (0 to DDR3_BANKS-1) of ddr3_addr_out_t;
ctrl: ddr3_ctrl_out_array_t; --type ddr3_ctrl_out_array_t   is array (0 to DDR3_BANKS-1) of ddr3_ctrl_out_t;
clk : ddr3_clk_out_array_t;  --type ddr3_clk_out_array_t    is array (0 to DDR3_BANKS-1) of ddr3_clk_out_t;
end record;

type TMEMCTRL_phy_inouts is record
data: ddr3_data_inout_array_t; --type ddr3_data_inout_array_t is array (0 to DDR3_BANKS-1) of ddr3_data_inout_t;
end record;

component memory_ctrl_core
generic(
G_SIM          : string:= "OFF";
G_AXI_IDWIDTH  : integer:= 4;
G_AXI_AWIDTH   : integer:= 32;
G_AXI_DWIDTH   : integer:= 32;
G_AXI_SUPPORTS_NARROW_BURST: integer:= 1;
G_AXI_REG_EN0  : integer:= 0;
G_AXI_REG_EN1  : integer:= 0;
bank : integer range 0 to DDR3_BANKS-1 := 0);
port(
--// AXI Slave Interface:
p_out_saxi_clk     : out   std_logic;
p_out_saxi_rstn    : out   std_logic;
--// Write Address Ports
p_in_saxi_awid     : in    std_logic_vector(G_AXI_IDWIDTH-1 downto 0);
p_in_saxi_awaddr   : in    std_logic_vector(G_AXI_AWIDTH-1 downto 0);
p_in_saxi_awlen    : in    std_logic_vector(7 downto 0);
p_in_saxi_awsize   : in    std_logic_vector(2 downto 0);
p_in_saxi_awburst  : in    std_logic_vector(1 downto 0);
p_in_saxi_awlock   : in    std_logic_vector(0 downto 0);
p_in_saxi_awcache  : in    std_logic_vector(3 downto 0);
p_in_saxi_awprot   : in    std_logic_vector(2 downto 0);
p_in_saxi_awqos    : in    std_logic_vector(3 downto 0);
p_in_saxi_awvalid  : in    std_logic;
p_out_saxi_awready : out   std_logic;
--// Write Data Ports
p_in_saxi_wdata    : in    std_logic_vector(G_AXI_DWIDTH-1 downto 0);
p_in_saxi_wstrb    : in    std_logic_vector(G_AXI_DWIDTH/8-1 downto 0);
p_in_saxi_wlast    : in    std_logic;
p_in_saxi_wvalid   : in    std_logic;
p_out_saxi_wready  : out   std_logic;
--// Write Response Ports
p_out_saxi_bid     : out   std_logic_vector(G_AXI_IDWIDTH-1 downto 0);
p_out_saxi_bresp   : out   std_logic_vector(1 downto 0);
p_out_saxi_bvalid  : out   std_logic;
p_in_saxi_bready   : in    std_logic;
--// Read Address Ports
p_in_saxi_arid     : in    std_logic_vector(G_AXI_IDWIDTH-1 downto 0);
p_in_saxi_araddr   : in    std_logic_vector(G_AXI_AWIDTH-1 downto 0);
p_in_saxi_arlen    : in    std_logic_vector(7 downto 0);
p_in_saxi_arsize   : in    std_logic_vector(2 downto 0);
p_in_saxi_arburst  : in    std_logic_vector(1 downto 0);
p_in_saxi_arlock   : in    std_logic_vector(0 downto 0);
p_in_saxi_arcache  : in    std_logic_vector(3 downto 0);
p_in_saxi_arprot   : in    std_logic_vector(2 downto 0);
p_in_saxi_arqos    : in    std_logic_vector(3 downto 0);
p_in_saxi_arvalid  : in    std_logic;
p_out_saxi_arready : out   std_logic;
--// Read Data Ports
p_out_saxi_rid     : out   std_logic_vector(G_AXI_IDWIDTH-1 downto 0);
p_out_saxi_rdata   : out   std_logic_vector(G_AXI_DWIDTH-1 downto 0);
p_out_saxi_rresp   : out   std_logic_vector(1 downto 0);
p_out_saxi_rlast   : out   std_logic;
p_out_saxi_rvalid  : out   std_logic;
p_in_saxi_rready   : in    std_logic;
-- Memory interface
ddr3_rst              : in    std_logic;
ddr3_ref_clk          : in    std_logic;
ddr3_clk              : in    std_logic;
ddr3_iodelay_ctrl_rdy : in    std_logic;
-- Memory status
ddr3_if_rdy           : out   std_logic;
ddr3_if_stat          : out   std_logic_vector(3 downto 0);
ddr3_if_err           : out   std_logic_vector(3 downto 0);
-- Physical memory interface
ddr3_addr_out         : out   ddr3_addr_out_t;
ddr3_ctrl_out         : out   ddr3_ctrl_out_t;
ddr3_data_inout       : inout ddr3_data_inout_t;
ddr3_clk_out          : out   ddr3_clk_out_t;
-- Debug info
ddr3_if_debug         : out   std_logic_vector(31 downto 0));
end component;


component mem_ctrl
generic(
G_SIM : string:="OFF"
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
end component;

component mem_arb
generic(
G_CH_COUNT   : integer:=4;
G_MEM_AWIDTH : integer:=32;
G_MEM_DWIDTH : integer:=32
);
port(
-------------------------------
--Связь с пользователями ОЗУ
-------------------------------
p_in_memch  : in   TMemINCh;
p_out_memch : out  TMemOUTCh;

-------------------------------
--Связь с mem_ctrl.vhd
-------------------------------
p_out_mem   : out   TMemIN;
p_in_mem    : in    TMemOUT;

-------------------------------
--Технологический
-------------------------------
p_in_tst    : in    std_logic_vector(31 downto 0);
p_out_tst   : out   std_logic_vector(31 downto 0);

-------------------------------
--System
-------------------------------
p_in_clk    : in    std_logic;
p_in_rst    : in    std_logic
);
end component;

COMPONENT mem_achcount3
  PORT (
    INTERCONNECT_ACLK : IN STD_LOGIC;
    INTERCONNECT_ARESETN : IN STD_LOGIC;

    S00_AXI_ARESET_OUT_N : OUT STD_LOGIC;
    S00_AXI_ACLK : IN STD_LOGIC;
    S00_AXI_AWID : IN STD_LOGIC_VECTOR(C_AXIS_IDWIDTH - 1 DOWNTO 0);
    S00_AXI_AWADDR : IN STD_LOGIC_VECTOR(C_AXI_AWIDTH - 1 DOWNTO 0);
    S00_AXI_AWLEN : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
    S00_AXI_AWSIZE : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
    S00_AXI_AWBURST : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
    S00_AXI_AWLOCK : IN STD_LOGIC;
    S00_AXI_AWCACHE : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
    S00_AXI_AWPROT : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
    S00_AXI_AWQOS : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
    S00_AXI_AWVALID : IN STD_LOGIC;
    S00_AXI_AWREADY : OUT STD_LOGIC;
    S00_AXI_WDATA : IN STD_LOGIC_VECTOR(C_AXIS_DWIDTH(0) - 1 DOWNTO 0);
    S00_AXI_WSTRB : IN STD_LOGIC_VECTOR(C_AXIS_DWIDTH(0)/8 - 1 DOWNTO 0);
    S00_AXI_WLAST : IN STD_LOGIC;
    S00_AXI_WVALID : IN STD_LOGIC;
    S00_AXI_WREADY : OUT STD_LOGIC;
    S00_AXI_BID : OUT STD_LOGIC_VECTOR(C_AXIS_IDWIDTH - 1 DOWNTO 0);
    S00_AXI_BRESP : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
    S00_AXI_BVALID : OUT STD_LOGIC;
    S00_AXI_BREADY : IN STD_LOGIC;
    S00_AXI_ARID : IN STD_LOGIC_VECTOR(C_AXIS_IDWIDTH - 1 DOWNTO 0);
    S00_AXI_ARADDR : IN STD_LOGIC_VECTOR(C_AXI_AWIDTH - 1 DOWNTO 0);
    S00_AXI_ARLEN : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
    S00_AXI_ARSIZE : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
    S00_AXI_ARBURST : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
    S00_AXI_ARLOCK : IN STD_LOGIC;
    S00_AXI_ARCACHE : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
    S00_AXI_ARPROT : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
    S00_AXI_ARQOS : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
    S00_AXI_ARVALID : IN STD_LOGIC;
    S00_AXI_ARREADY : OUT STD_LOGIC;
    S00_AXI_RID : OUT STD_LOGIC_VECTOR(C_AXIS_IDWIDTH - 1 DOWNTO 0);
    S00_AXI_RDATA : OUT STD_LOGIC_VECTOR(C_AXIS_DWIDTH(0) - 1 DOWNTO 0);
    S00_AXI_RRESP : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
    S00_AXI_RLAST : OUT STD_LOGIC;
    S00_AXI_RVALID : OUT STD_LOGIC;
    S00_AXI_RREADY : IN STD_LOGIC;

    S01_AXI_ARESET_OUT_N : OUT STD_LOGIC;
    S01_AXI_ACLK : IN STD_LOGIC;
    S01_AXI_AWID : IN STD_LOGIC_VECTOR(C_AXIS_IDWIDTH - 1 DOWNTO 0);
    S01_AXI_AWADDR : IN STD_LOGIC_VECTOR(C_AXI_AWIDTH - 1 DOWNTO 0);
    S01_AXI_AWLEN : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
    S01_AXI_AWSIZE : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
    S01_AXI_AWBURST : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
    S01_AXI_AWLOCK : IN STD_LOGIC;
    S01_AXI_AWCACHE : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
    S01_AXI_AWPROT : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
    S01_AXI_AWQOS : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
    S01_AXI_AWVALID : IN STD_LOGIC;
    S01_AXI_AWREADY : OUT STD_LOGIC;
    S01_AXI_WDATA : IN STD_LOGIC_VECTOR(C_AXIS_DWIDTH(1) - 1 DOWNTO 0);
    S01_AXI_WSTRB : IN STD_LOGIC_VECTOR(C_AXIS_DWIDTH(1)/8 - 1 DOWNTO 0);
    S01_AXI_WLAST : IN STD_LOGIC;
    S01_AXI_WVALID : IN STD_LOGIC;
    S01_AXI_WREADY : OUT STD_LOGIC;
    S01_AXI_BID : OUT STD_LOGIC_VECTOR(C_AXIS_IDWIDTH - 1 DOWNTO 0);
    S01_AXI_BRESP : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
    S01_AXI_BVALID : OUT STD_LOGIC;
    S01_AXI_BREADY : IN STD_LOGIC;
    S01_AXI_ARID : IN STD_LOGIC_VECTOR(C_AXIS_IDWIDTH - 1 DOWNTO 0);
    S01_AXI_ARADDR : IN STD_LOGIC_VECTOR(C_AXI_AWIDTH - 1 DOWNTO 0);
    S01_AXI_ARLEN : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
    S01_AXI_ARSIZE : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
    S01_AXI_ARBURST : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
    S01_AXI_ARLOCK : IN STD_LOGIC;
    S01_AXI_ARCACHE : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
    S01_AXI_ARPROT : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
    S01_AXI_ARQOS : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
    S01_AXI_ARVALID : IN STD_LOGIC;
    S01_AXI_ARREADY : OUT STD_LOGIC;
    S01_AXI_RID : OUT STD_LOGIC_VECTOR(C_AXIS_IDWIDTH - 1 DOWNTO 0);
    S01_AXI_RDATA : OUT STD_LOGIC_VECTOR(C_AXIS_DWIDTH(1) - 1 DOWNTO 0);
    S01_AXI_RRESP : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
    S01_AXI_RLAST : OUT STD_LOGIC;
    S01_AXI_RVALID : OUT STD_LOGIC;
    S01_AXI_RREADY : IN STD_LOGIC;

    S02_AXI_ARESET_OUT_N : OUT STD_LOGIC;
    S02_AXI_ACLK : IN STD_LOGIC;
    S02_AXI_AWID : IN STD_LOGIC_VECTOR(C_AXIS_IDWIDTH - 1 DOWNTO 0);
    S02_AXI_AWADDR : IN STD_LOGIC_VECTOR(C_AXI_AWIDTH - 1 DOWNTO 0);
    S02_AXI_AWLEN : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
    S02_AXI_AWSIZE : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
    S02_AXI_AWBURST : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
    S02_AXI_AWLOCK : IN STD_LOGIC;
    S02_AXI_AWCACHE : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
    S02_AXI_AWPROT : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
    S02_AXI_AWQOS : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
    S02_AXI_AWVALID : IN STD_LOGIC;
    S02_AXI_AWREADY : OUT STD_LOGIC;
    S02_AXI_WDATA : IN STD_LOGIC_VECTOR(C_AXIS_DWIDTH(2) - 1 DOWNTO 0);
    S02_AXI_WSTRB : IN STD_LOGIC_VECTOR(C_AXIS_DWIDTH(2)/8 - 1 DOWNTO 0);
    S02_AXI_WLAST : IN STD_LOGIC;
    S02_AXI_WVALID : IN STD_LOGIC;
    S02_AXI_WREADY : OUT STD_LOGIC;
    S02_AXI_BID : OUT STD_LOGIC_VECTOR(C_AXIS_IDWIDTH - 1 DOWNTO 0);
    S02_AXI_BRESP : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
    S02_AXI_BVALID : OUT STD_LOGIC;
    S02_AXI_BREADY : IN STD_LOGIC;
    S02_AXI_ARID : IN STD_LOGIC_VECTOR(C_AXIS_IDWIDTH - 1 DOWNTO 0);
    S02_AXI_ARADDR : IN STD_LOGIC_VECTOR(C_AXI_AWIDTH - 1 DOWNTO 0);
    S02_AXI_ARLEN : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
    S02_AXI_ARSIZE : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
    S02_AXI_ARBURST : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
    S02_AXI_ARLOCK : IN STD_LOGIC;
    S02_AXI_ARCACHE : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
    S02_AXI_ARPROT : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
    S02_AXI_ARQOS : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
    S02_AXI_ARVALID : IN STD_LOGIC;
    S02_AXI_ARREADY : OUT STD_LOGIC;
    S02_AXI_RID : OUT STD_LOGIC_VECTOR(C_AXIS_IDWIDTH - 1 DOWNTO 0);
    S02_AXI_RDATA : OUT STD_LOGIC_VECTOR(C_AXIS_DWIDTH(2) - 1 DOWNTO 0);
    S02_AXI_RRESP : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
    S02_AXI_RLAST : OUT STD_LOGIC;
    S02_AXI_RVALID : OUT STD_LOGIC;
    S02_AXI_RREADY : IN STD_LOGIC;

    M00_AXI_ARESET_OUT_N : OUT STD_LOGIC;
    M00_AXI_ACLK : IN STD_LOGIC;
    M00_AXI_AWID : OUT STD_LOGIC_VECTOR(C_AXIM_IDWIDTH - 1 DOWNTO 0);
    M00_AXI_AWADDR : OUT STD_LOGIC_VECTOR(C_AXI_AWIDTH - 1 DOWNTO 0);
    M00_AXI_AWLEN : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
    M00_AXI_AWSIZE : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
    M00_AXI_AWBURST : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
    M00_AXI_AWLOCK : OUT STD_LOGIC;
    M00_AXI_AWCACHE : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
    M00_AXI_AWPROT : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
    M00_AXI_AWQOS : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
    M00_AXI_AWVALID : OUT STD_LOGIC;
    M00_AXI_AWREADY : IN STD_LOGIC;
    M00_AXI_WDATA : OUT STD_LOGIC_VECTOR(C_AXIM_DWIDTH - 1 DOWNTO 0);
    M00_AXI_WSTRB : OUT STD_LOGIC_VECTOR(C_AXIM_DWIDTH/8 - 1 DOWNTO 0);
    M00_AXI_WLAST : OUT STD_LOGIC;
    M00_AXI_WVALID : OUT STD_LOGIC;
    M00_AXI_WREADY : IN STD_LOGIC;
    M00_AXI_BID : IN STD_LOGIC_VECTOR(C_AXIM_IDWIDTH - 1 DOWNTO 0);
    M00_AXI_BRESP : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
    M00_AXI_BVALID : IN STD_LOGIC;
    M00_AXI_BREADY : OUT STD_LOGIC;
    M00_AXI_ARID : OUT STD_LOGIC_VECTOR(C_AXIM_IDWIDTH - 1 DOWNTO 0);
    M00_AXI_ARADDR : OUT STD_LOGIC_VECTOR(C_AXI_AWIDTH - 1 DOWNTO 0);
    M00_AXI_ARLEN : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
    M00_AXI_ARSIZE : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
    M00_AXI_ARBURST : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
    M00_AXI_ARLOCK : OUT STD_LOGIC;
    M00_AXI_ARCACHE : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
    M00_AXI_ARPROT : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
    M00_AXI_ARQOS : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
    M00_AXI_ARVALID : OUT STD_LOGIC;
    M00_AXI_ARREADY : IN STD_LOGIC;
    M00_AXI_RID : IN STD_LOGIC_VECTOR(C_AXIM_IDWIDTH - 1 DOWNTO 0);
    M00_AXI_RDATA : IN STD_LOGIC_VECTOR(C_AXIM_DWIDTH - 1 DOWNTO 0);
    M00_AXI_RRESP : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
    M00_AXI_RLAST : IN STD_LOGIC;
    M00_AXI_RVALID : IN STD_LOGIC;
    M00_AXI_RREADY : OUT STD_LOGIC
  );
END COMPONENT;

end;


package body mem_ctrl_pkg is

function conv_sim_bypass_init_cal(
  constant val: in string)
return string is
begin
  if val="ON" then --if strcmp(val,"ON")=true then  --
    return "FAST"; --  return "FAST";               --
  else             --else                           --
    return "OFF";  --  return "OFF";                --
  end if;          --end if;                        --
end;

function conv_sim_init_option(
  constant val: in string)
return string is
begin
  if val="ON" then        --if strcmp(val,"ON")=true then  --
    return "SKIP_PU_DLY"; --  return "SKIP_PU_DLY";        --
  else                    --else                           --
    return "NONE";        --  return "NONE";               --
  end if;                 --end if;                        --
end;

function conv_sim_cal_option(
  constant val: in string)
return string is
begin
  if val="ON" then       --if strcmp(val,"ON")=true then  --
    return "FAST_CAL";   --  return "FAST_CAL";           --
  else                   --else                           --
    return "NONE";       --  return "NONE";               --
  end if;                --end if;                        --
end;

--function conv_sim_bypass_init_cal(
--  constant val: in target_use_t)
--return string is
--begin
--  case val is
--    when SIM_OCP  => return "FAST";
--    when SIM_MPTL => return "FAST";
--    when SYN_NGC  => return "OFF";
--  end case;
--end;
--
--function conv_sim_init_option(
--  constant val: in target_use_t)
--return string is
--begin
--  case val is
--    when SIM_OCP  => return "SKIP_PU_DLY";
--    when SIM_MPTL => return "SKIP_PU_DLY";
--    when SYN_NGC  => return "NONE";
--  end case;
--end;
--
--function conv_sim_cal_option(
--  constant val: in target_use_t)
--return string is
--begin
--  case val is
--    when SIM_OCP  => return "FAST_CAL";
--    when SIM_MPTL => return "FAST_CAL";
--    when SYN_NGC  => return "NONE";
--  end case;
--end;


end;