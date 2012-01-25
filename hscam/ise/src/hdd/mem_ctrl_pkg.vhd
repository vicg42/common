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
use work.prj_cfg.all;
use work.vicg_common_pkg.all;
use work.mem_wr_pkg.all;

package mem_ctrl_pkg is

-- Define maximum number of memory banks
constant C_MEM_BANK_COUNT    : integer := C_PCFG_MEMCTRL_BANK_COUNT;
constant C_MEM_BANK_COUNT_MAX: integer := 2;


constant C5_P0_MASK_SIZE         : integer := 4;
constant C5_P0_DATA_PORT_SIZE    : integer := 32;
constant C5_P1_MASK_SIZE         : integer := 4;
constant C5_P1_DATA_PORT_SIZE    : integer := 32;
constant C5_MEMCLK_PERIOD        : integer := 3300;--3200;-- Memory data transfer clock period.
constant C5_RST_ACT_LOW          : integer := 0;-- # = 1 for active low reset,-- # = 0 for active high reset.
constant C5_INPUT_CLK_TYPE       : string := "SINGLE_ENDED"; -- input clock type DIFFERENTIAL or SINGLE_ENDED.
constant C5_CALIB_SOFT_IP        : string := "TRUE";-- # = TRUE, Enables the soft calibration logic,-- # = FALSE, Disables the soft calibration logic.
constant C5_MEM_ADDR_ORDER       : string := "BANK_ROW_COLUMN";-- ROW_BANK_COLUMN or BANK_ROW_COLUMN.
constant C5_NUM_DQ_PINS          : integer := 16;-- External memory data width.
constant C5_MEM_ADDR_WIDTH       : integer := 13;-- External memory address width.
constant C5_MEM_BANKADDR_WIDTH   : integer := 3;-- External memory bank address width.


--Memory interface types
type TRam_out is record
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

type TRam_inout is record
dq    : std_logic_vector(C5_NUM_DQ_PINS-1 downto 0);
udqs  : std_logic;
udqs_n: std_logic;
rzq   : std_logic;
zio   : std_logic;
dqs   : std_logic;
dqs_n : std_logic;
end record;

-- Types for memory interface
type TRam_outs   is array(0 to C_MEM_BANK_COUNT_MAX-1) of TRam_out  ;
type TRam_inouts is array(0 to C_MEM_BANK_COUNT_MAX-1) of TRam_inout;

type TRam_rdy    is array(0 to C_MEM_BANK_COUNT-1) of std_logic;

Type TMemINBank  is array (0 to C_MEM_BANK_COUNT-1) of TMemIN;
Type TMemOUTBank is array (0 to C_MEM_BANK_COUNT-1) of TMemOUT;



component mem_ctrl
generic(
G_SIM : string:= "OFF"
);
port(
------------------------------------
--User Post
------------------------------------
p_in_memch0     : in    TMemINBank;
p_out_memch0    : out   TMemOUTBank;

p_in_memch1     : in    TMemINBank;
p_out_memch1    : out   TMemOUTBank;

------------------------------------
--Memory physical interface
------------------------------------
p_out_phymem    : out   TRam_outs  ;
p_inout_phymem  : inout TRam_inouts;

------------------------------------
--Memory status
------------------------------------
p_out_mem_rdy   : out   std_logic_vector(C_MEM_BANK_COUNT-1 downto 0);

------------------------------------
--System
------------------------------------
p_out_pll_gclkusr : out   std_logic;
--c5_rst0         : out   std_logic;
p_in_clk        : in    std_logic;
p_in_rst        : in    std_logic
);
end component;


end;
