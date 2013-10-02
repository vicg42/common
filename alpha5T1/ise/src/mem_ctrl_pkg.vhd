-------------------------------------------------------------------------
-- Company     : Linkos
-- Engineer    : Golovachenko Victor
--
-- Create Date : 17.10.2011 10:47:52
-- Module Name : mem_ctrl_pkg.vhd
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
use work.memif.all;
use work.mem_wr_pkg.all;

package mem_ctrl_pkg is

constant C_AXI_AWIDTH      : integer:=32;
constant C_AXIM_DWIDTH     : integer:=C_PCGF_PCIE_DWIDTH;
constant C_MEM_ARB_CH_COUNT  : integer := C_PCFG_MEMARB_CH_COUNT;

constant C_MEMCTRL_CFG_MODE_REG_COUNT  : integer:=3;--//32 bit

----//Настройки для 32Bit шины хоста
constant C_MEMCTRL_ADDR_WIDTH  : natural :=32;
constant C_MEMCTRL_DATA_WIDTH  : natural :=32;

--//Настройки чипов памяти подключенной к mem_ctrl.vhd
constant C_MEM_BANK0       : bank_t  := (enable => true, ra_width => 19, rc_width => 22, rd_width => 32);--//SDRAM DDR-II (chip0)
constant C_MEM_BANK1       : bank_t  := (enable => true, ra_width => 19, rc_width => 22, rd_width => 32);--//SDRAM DDR-II (chip1)
constant C_MEM_BANK2       : bank_t  := (enable => true, ra_width => 24, rc_width => 9,  rd_width => 16);--//SSRAM DDR-II
constant C_MEM_BANK3       : bank_t  := no_bank;
constant C_MEM_BANK4       : bank_t  := no_bank;
constant C_MEM_BANK5       : bank_t  := no_bank;
constant C_MEM_BANK6       : bank_t  := no_bank;
constant C_MEM_BANK7       : bank_t  := no_bank;
constant C_MEM_BANK8       : bank_t  := no_bank;
constant C_MEM_BANK9       : bank_t  := no_bank;
constant C_MEM_BANK10      : bank_t  := no_bank;
constant C_MEM_BANK11      : bank_t  := no_bank;
constant C_MEM_BANK12      : bank_t  := no_bank;
constant C_MEM_BANK13      : bank_t  := no_bank;
constant C_MEM_BANK14      : bank_t  := no_bank;
constant C_MEM_BANK15      : bank_t  := no_bank;
constant C_MEM_NUM_RAMCLK  : natural := 1;

constant max_num_bank      : natural := 16;
constant max_data_width    : natural := 128;                -- Maximum data width used by any bank
constant max_be_width      : natural := max_data_width / 8; -- Maximum byte enable width used by any bank
constant max_address_width : natural := 32;                 -- Maximum address width required for addressing any bank
constant tag_width         : natural := 2;                  -- Change this if 2 tag bits is insufficient in your application


constant C_MEM_BANK_COUNT    : integer := C_PCFG_MEMCTRL_BANK_COUNT;

-- Used for address signal to a memory port
type address_vector_t is array(natural range <>) of std_logic_vector(max_address_width - 1 downto 0);

-- Used for 'din' and 'dout' signals to and from a memory port
type be_vector_t is array(natural range <>) of std_logic_vector(max_be_width - 1 downto 0);

-- Used for single bit signals such as 'ready' from a memory port
type control_vector_t is array(natural range <>) of std_logic;

-- Used for 'd' and 'q' signals to and from a memory port
type data_vector_t is array(natural range <>) of std_logic_vector(max_data_width - 1 downto 0);

-- Used for 'tag' and 'qtag' signals to and from a memory port
type tag_vector_t is array(natural range <>) of std_logic_vector(tag_width - 1 downto 0);


type TMEMCTRL_status is record
rdy   : std_logic_vector(0 downto 0);
trained : std_logic_vector(15 downto 0);
end record;

type TMEMCTRL_sysin is record
ref_clk: std_logic;
clk    : std_logic;
rst    : std_logic;
end record;

type TMEMCTRL_sysout is record
gusrclk: std_logic_vector(0 downto 0);
clk   : std_logic;
end record;

type TMEMCTRL_phy_outs is record
ra0   : std_logic_vector(C_MEM_BANK0.ra_width - 1 downto 0);
end record;

type TMEMCTRL_phy_inouts is record
rc0   : std_logic_vector(C_MEM_BANK0.rc_width - 1 downto 0);
rd0   : std_logic_vector(C_MEM_BANK0.rd_width - 1 downto 0);
end record;

--Type TMemINBank is array (0 to C_MEMCH_COUNT_MAX-1) of TMemIN;
--Type TMemOUTBank is array (0 to C_MEMCH_COUNT_MAX-1) of TMemOUT;
Type TMemINBank is array (0 to 8-1) of TMemIN;
Type TMemOUTBank is array (0 to 8-1) of TMemOUT;

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


component mem_ctrl
generic(
G_SIM : string:="OFF"
);
port(
------------------------------------
--User Post
------------------------------------
p_in_mem       : in    TMemINBank;--TMemIN;--
p_out_mem      : out   TMemOUTBank;--TMemOUT;--

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
