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

library work;
use work.prj_cfg.all;
use work.vicg_common_pkg.all;
use work.mem_wr_pkg.all;

package mem_ctrl_pkg is

-- Define maximum number of memory banks
constant C_MEM_BANK_COUNT    : integer := C_PCFG_MEMCTRL_BANK_COUNT;
constant C_MEM_BANK_COUNT_MAX: integer := 2;

----CLKOUT0_DIVIDE=(Fclkin * C5_CLKFBOUT_MULT) / (C5_DIVCLK_DIVIDE * C5_CLKOUT0_DIVIDE );
----(150 * 5)/(1 * C5_CLKOUTxx_DIVIDE)
--
--constant C_MEMPLL_CLKOUT0_DIVIDE : integer := 2; --c5_sysclk_2x      =375MHZ
--constant C_MEMPLL_CLKOUT1_DIVIDE : integer := 2; --c5_sysclk_2x_180
--constant C_MEMPLL_CLKOUT2_DIVIDE : integer := 5; --p_out_pll_gclkusr =150MHZ) --(4; --p_out_pll_gclkusr =187,5MHZ)
--constant C_MEMPLL_CLKOUT3_DIVIDE : integer := 8; --c5_mcb_drp_clk = 93,75MHz
--constant C_MEMPLL_CLKFBOUT_MULT  : integer := 5;
--constant C_MEMPLL_DIVCLK_DIVIDE  : integer := 1;

constant C5_MEMCLK_PERIOD          : integer := 3300;--2600;--3200;-- Memory data transfer clock period.

constant C5_P0_MASK_SIZE           : integer := 8;
constant C5_P0_DATA_PORT_SIZE      : integer := 64;
constant C5_P1_MASK_SIZE           : integer := 8;
constant C5_P1_DATA_PORT_SIZE      : integer := 64;
constant C5_RST_ACT_LOW            : integer := 0;-- # = 1 for active low reset,-- # = 0 for active high reset.
constant C5_INPUT_CLK_TYPE         : string := "SINGLE_ENDED"; -- input clock type DIFFERENTIAL or SINGLE_ENDED.
constant C5_CALIB_SOFT_IP          : string := "TRUE";-- # = TRUE, Enables the soft calibration logic,-- # = FALSE, Disables the soft calibration logic.
constant C5_MEM_ADDR_ORDER         : string := "BANK_ROW_COLUMN";-- ROW_BANK_COLUMN or BANK_ROW_COLUMN.
constant C5_NUM_DQ_PINS            : integer := 16;-- External memory data width.
constant C5_MEM_ADDR_WIDTH         : integer := 13;-- External memory address width.
constant C5_MEM_BANKADDR_WIDTH     : integer := 3;-- External memory bank address width.

constant C_MEMCTRL_AWIDTH      : integer := 30;
constant C_MEMCTRL_DWIDTH      : integer := C5_P0_DATA_PORT_SIZE;

constant C_MEMCTRL_CH0_DWIDTH  : integer := C5_P0_DATA_PORT_SIZE;
constant C_MEMCTRL_CH0_BEWIDTH : integer := C5_P0_MASK_SIZE;
constant C_MEMCTRL_CH1_DWIDTH  : integer := C5_P1_DATA_PORT_SIZE;
constant C_MEMCTRL_CH1_BEWIDTH : integer := C5_P1_MASK_SIZE;

--Memory interface types
type TMEMCTRL_phy_out is record
a     : std_logic_vector(C5_MEM_ADDR_WIDTH-1 downto 0);
ba    : std_logic_vector(C5_MEM_BANKADDR_WIDTH-1 downto 0);
ras_n : std_logic;
cas_n : std_logic;
we_n  : std_logic;
dm    : std_logic;
udm   : std_logic;
odt   : std_logic;
cke   : std_logic;
ck    : std_logic;
ck_n  : std_logic;
end record;

type TMEMCTRL_phy_inout is record
dq    : std_logic_vector(C5_NUM_DQ_PINS-1 downto 0);
udqs  : std_logic;
udqs_n: std_logic;
rzq   : std_logic;
zio   : std_logic;
dqs   : std_logic;
dqs_n : std_logic;
end record;

type TMEMCTRL_status is record
rdy   : std_logic_vector(C_MEM_BANK_COUNT-1 downto 0);
end record;

type TMEMCTRL_sysin is record
clk   : std_logic;
rst   : std_logic;
end record;

type TMEMCTRL_sysout is record
clk   : std_logic;
end record;

-- Types for memory interface
type TMEMCTRL_phy_outs   is array(0 to C_MEM_BANK_COUNT_MAX-1) of TMEMCTRL_phy_out  ;
type TMEMCTRL_phy_inouts is array(0 to C_MEM_BANK_COUNT_MAX-1) of TMEMCTRL_phy_inout;

Type TMemINBank  is array (0 to C_MEM_BANK_COUNT-1) of TMemINCh;
Type TMemOUTBank is array (0 to C_MEM_BANK_COUNT-1) of TMemOUTCh;



component mem_ctrl
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
end component;


end;
