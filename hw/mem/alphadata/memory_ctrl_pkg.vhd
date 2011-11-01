-------------------------------------------------------------------------
-- Company     : Linkos
-- Engineer    : Golovachenko Victor
--
-- Create Date : 17.10.2011 10:47:52
-- Module Name : memory_ctrl_pkg.vhd
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
use work.memif.all;

package memory_ctrl_pkg is

constant C_MEMCTRL_CFG_MODE_REG_COUNT  : integer:=3;--//32 bit

----//Настройки для 32Bit шины хоста
constant C_MEMCTRL_ADDR_WIDTH  : natural :=32;
constant C_MEMCTRL_DATA_WIDTH  : natural :=32;

--//Настройки чипов памяти подключенной к memory_ctrl.vhd
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

component memory_ch_arbitr
generic(
G_CH_COUNT : integer:=4
);
port
(
-------------------------------
-- Связь с CH0
-------------------------------
p_in_ch0_req     : in    std_logic;
p_out_ch0_en     : out   std_logic;

p_in_ch0_bank1h  : in    std_logic_vector(15 downto 0);
p_in_ch0_ce      : in    std_logic;
p_in_ch0_cw      : in    std_logic;
p_in_ch0_rd      : in    std_logic;
p_in_ch0_wr      : in    std_logic;
p_in_ch0_term    : in    std_logic;
p_in_ch0_adr     : in    std_logic_vector(C_MEMCTRL_ADDR_WIDTH - 1 downto 0);
p_in_ch0_be      : in    std_logic_vector(C_MEMCTRL_DATA_WIDTH / 8 - 1 downto 0);
p_in_ch0_din     : in    std_logic_vector(C_MEMCTRL_DATA_WIDTH - 1 downto 0);
p_out_ch0_dout   : out   std_logic_vector(C_MEMCTRL_DATA_WIDTH - 1 downto 0);

p_out_ch0_wf     : out   std_logic;
p_out_ch0_wpf    : out   std_logic;
p_out_ch0_re     : out   std_logic;
p_out_ch0_rpe    : out   std_logic;

-------------------------------
-- Связь с CH1
-------------------------------
p_in_ch1_req     : in    std_logic;
p_out_ch1_en     : out   std_logic;

p_in_ch1_bank1h  : in    std_logic_vector(15 downto 0);
p_in_ch1_ce      : in    std_logic;
p_in_ch1_cw      : in    std_logic;
p_in_ch1_rd      : in    std_logic;
p_in_ch1_wr      : in    std_logic;
p_in_ch1_term    : in    std_logic;
p_in_ch1_adr     : in    std_logic_vector(C_MEMCTRL_ADDR_WIDTH - 1 downto 0);
p_in_ch1_be      : in    std_logic_vector(C_MEMCTRL_DATA_WIDTH / 8 - 1 downto 0);
p_in_ch1_din     : in    std_logic_vector(C_MEMCTRL_DATA_WIDTH - 1 downto 0);
p_out_ch1_dout   : out   std_logic_vector(C_MEMCTRL_DATA_WIDTH - 1 downto 0);

p_out_ch1_wf     : out   std_logic;
p_out_ch1_wpf    : out   std_logic;
p_out_ch1_re     : out   std_logic;
p_out_ch1_rpe    : out   std_logic;

-------------------------------
-- Связь с CH2
-------------------------------
p_in_ch2_req     : in    std_logic;
p_out_ch2_en     : out   std_logic;

p_in_ch2_bank1h  : in    std_logic_vector(15 downto 0);
p_in_ch2_ce      : in    std_logic;
p_in_ch2_cw      : in    std_logic;
p_in_ch2_rd      : in    std_logic;
p_in_ch2_wr      : in    std_logic;
p_in_ch2_term    : in    std_logic;
p_in_ch2_adr     : in    std_logic_vector(C_MEMCTRL_ADDR_WIDTH - 1 downto 0);
p_in_ch2_be      : in    std_logic_vector(C_MEMCTRL_DATA_WIDTH / 8 - 1 downto 0);
p_in_ch2_din     : in    std_logic_vector(C_MEMCTRL_DATA_WIDTH - 1 downto 0);
p_out_ch2_dout   : out   std_logic_vector(C_MEMCTRL_DATA_WIDTH - 1 downto 0);

p_out_ch2_wf     : out   std_logic;
p_out_ch2_wpf    : out   std_logic;
p_out_ch2_re     : out   std_logic;
p_out_ch2_rpe    : out   std_logic;

-------------------------------
-- Связь с CH3
-------------------------------
p_in_ch3_req     : in    std_logic;
p_out_ch3_en     : out   std_logic;

p_in_ch3_bank1h  : in    std_logic_vector(15 downto 0);
p_in_ch3_ce      : in    std_logic;
p_in_ch3_cw      : in    std_logic;
p_in_ch3_rd      : in    std_logic;
p_in_ch3_wr      : in    std_logic;
p_in_ch3_term    : in    std_logic;
p_in_ch3_adr     : in    std_logic_vector(C_MEMCTRL_ADDR_WIDTH - 1 downto 0);
p_in_ch3_be      : in    std_logic_vector(C_MEMCTRL_DATA_WIDTH / 8 - 1 downto 0);
p_in_ch3_din     : in    std_logic_vector(C_MEMCTRL_DATA_WIDTH - 1 downto 0);
p_out_ch3_dout   : out   std_logic_vector(C_MEMCTRL_DATA_WIDTH - 1 downto 0);

p_out_ch3_wf     : out   std_logic;
p_out_ch3_wpf    : out   std_logic;
p_out_ch3_re     : out   std_logic;
p_out_ch3_rpe    : out   std_logic;


---------------------------------
-- Связь с memory_ctrl.vhd
---------------------------------
p_out_mem_clk    : out   std_logic;

p_out_mem_bank1h : out   std_logic_vector(15 downto 0);
p_out_mem_ce     : out   std_logic;
p_out_mem_cw     : out   std_logic;
p_out_mem_rd     : out   std_logic;
p_out_mem_wr     : out   std_logic;
p_out_mem_term   : out   std_logic;
p_out_mem_adr    : out   std_logic_vector(C_MEMCTRL_ADDR_WIDTH - 1 downto 0);
p_out_mem_be     : out   std_logic_vector(C_MEMCTRL_DATA_WIDTH / 8 - 1 downto 0);
p_out_mem_din    : out   std_logic_vector(C_MEMCTRL_DATA_WIDTH - 1 downto 0);
p_in_mem_dout    : in    std_logic_vector(C_MEMCTRL_DATA_WIDTH - 1 downto 0);

p_in_mem_wf      : in    std_logic;
p_in_mem_wpf     : in    std_logic;
p_in_mem_re      : in    std_logic;
p_in_mem_rpe     : in    std_logic;

-------------------------------
--Технологический
-------------------------------
p_in_tst         : in    std_logic_vector(31 downto 0);
p_out_tst        : out   std_logic_vector(31 downto 0);

-------------------------------
--System
-------------------------------
p_in_clk         : in    std_logic;
p_in_rst         : in    std_logic
);
end component;


component memory_ctrl
  generic
  (
    G_BANK_COUNT  : in    integer;

    bank0         : in    bank_t;
    bank1         : in    bank_t;
    bank2         : in    bank_t;
    bank3         : in    bank_t;
    bank4         : in    bank_t;
    bank5         : in    bank_t;
    bank6         : in    bank_t;
    bank7         : in    bank_t;
    bank8         : in    bank_t;
    bank9         : in    bank_t;
    bank10        : in    bank_t;
    bank11        : in    bank_t;
    bank12        : in    bank_t;
    bank13        : in    bank_t;
    bank14        : in    bank_t;
    bank15        : in    bank_t;
    num_ramclk    : in    natural
  );
  port
  (
    -----------------------------
    --System
    -----------------------------
    rst           : in    std_logic;

    memclk0       : in    std_logic;
    memclk45      : in    std_logic;
    memclk2x0     : in    std_logic;
    memclk2x90    : in    std_logic;
    memrst        : in    std_logic;

    -----------------------------
    -- Configuration
    -----------------------------
    bank_reg      : in    std_logic_vector(3 downto 0);
    mode_reg      : in    std_logic_vector(511 downto 0);
--    locked        : out   std_logic_vector(7 downto 0);
    trained       : out   std_logic_vector(15 downto 0);

    -----------------------------
    -- User channel 0
    -----------------------------
    usr0_clk      : in    std_logic;
    --Управление
    usr0_bank1h   : in    std_logic_vector(15 downto 0);
    usr0_ce       : in    std_logic;
    usr0_cw       : in    std_logic;
    usr0_term     : in    std_logic;
    usr0_rd       : in    std_logic;
    usr0_wr       : in    std_logic;
    usr0_adr      : in    std_logic_vector(C_MEMCTRL_ADDR_WIDTH - 1 downto 0);
    usr0_be       : in    std_logic_vector(C_MEMCTRL_DATA_WIDTH / 8 - 1 downto 0);
    usr0_din      : in    std_logic_vector(C_MEMCTRL_DATA_WIDTH - 1 downto 0);
    usr0_dout     : out   std_logic_vector(C_MEMCTRL_DATA_WIDTH - 1 downto 0);
    --TX/RXBUF STATUS
    usr0_wf       : out   std_logic;
    usr0_wpf      : out   std_logic;
    usr0_re       : out   std_logic;
    usr0_rpe      : out   std_logic;

    -----------------------------
    -- User channel 1
    -----------------------------
    usr1_clk      : in    std_logic;
    --Управление
    usr1_bank1h  : in    std_logic_vector(15 downto 0);
    usr1_ce       : in    std_logic;
    usr1_cw       : in    std_logic;
    usr1_term     : in    std_logic;
    usr1_rd       : in    std_logic;
    usr1_wr       : in    std_logic;
    usr1_adr      : in    std_logic_vector(C_MEMCTRL_ADDR_WIDTH - 1 downto 0);
    usr1_be       : in    std_logic_vector(C_MEMCTRL_DATA_WIDTH / 8 - 1 downto 0);
    usr1_din      : in    std_logic_vector(C_MEMCTRL_DATA_WIDTH - 1 downto 0);
    usr1_dout     : out   std_logic_vector(C_MEMCTRL_DATA_WIDTH - 1 downto 0);
    --TX/RXBUF STATUS
    usr1_wf       : out   std_logic;
    usr1_wpf      : out   std_logic;
    usr1_re       : out   std_logic;
    usr1_rpe      : out   std_logic;

    -----------------------------
    -- To/from FPGA memory pins
    -----------------------------
    ra0           : out   std_logic_vector(bank0.ra_width - 1 downto 0);
    rc0           : inout std_logic_vector(bank0.rc_width - 1 downto 0);
    rd0           : inout std_logic_vector(bank0.rd_width - 1 downto 0);
    ra1           : out   std_logic_vector(bank1.ra_width - 1 downto 0);
    rc1           : inout std_logic_vector(bank1.rc_width - 1 downto 0);
    rd1           : inout std_logic_vector(bank1.rd_width - 1 downto 0);
    ra2           : out   std_logic_vector(bank2.ra_width - 1 downto 0);
    rc2           : inout std_logic_vector(bank2.rc_width - 1 downto 0);
    rd2           : inout std_logic_vector(bank2.rd_width - 1 downto 0);
    ra3           : out   std_logic_vector(bank3.ra_width - 1 downto 0);
    rc3           : inout std_logic_vector(bank3.rc_width - 1 downto 0);
    rd3           : inout std_logic_vector(bank3.rd_width - 1 downto 0);
    ra4           : out   std_logic_vector(bank4.ra_width - 1 downto 0);
    rc4           : inout std_logic_vector(bank4.rc_width - 1 downto 0);
    rd4           : inout std_logic_vector(bank4.rd_width - 1 downto 0);
    ra5           : out   std_logic_vector(bank5.ra_width - 1 downto 0);
    rc5           : inout std_logic_vector(bank5.rc_width - 1 downto 0);
    rd5           : inout std_logic_vector(bank5.rd_width - 1 downto 0);
    ra6           : out   std_logic_vector(bank6.ra_width - 1 downto 0);
    rc6           : inout std_logic_vector(bank6.rc_width - 1 downto 0);
    rd6           : inout std_logic_vector(bank6.rd_width - 1 downto 0);
    ra7           : out   std_logic_vector(bank7.ra_width - 1 downto 0);
    rc7           : inout std_logic_vector(bank7.rc_width - 1 downto 0);
    rd7           : inout std_logic_vector(bank7.rd_width - 1 downto 0);
    ra8           : out   std_logic_vector(bank8.ra_width - 1 downto 0);
    rc8           : inout std_logic_vector(bank8.rc_width - 1 downto 0);
    rd8           : inout std_logic_vector(bank8.rd_width - 1 downto 0);
    ra9           : out   std_logic_vector(bank9.ra_width - 1 downto 0);
    rc9           : inout std_logic_vector(bank9.rc_width - 1 downto 0);
    rd9           : inout std_logic_vector(bank9.rd_width - 1 downto 0);
    ra10          : out   std_logic_vector(bank10.ra_width - 1 downto 0);
    rc10          : inout std_logic_vector(bank10.rc_width - 1 downto 0);
    rd10          : inout std_logic_vector(bank10.rd_width - 1 downto 0);
    ra11          : out   std_logic_vector(bank11.ra_width - 1 downto 0);
    rc11          : inout std_logic_vector(bank11.rc_width - 1 downto 0);
    rd11          : inout std_logic_vector(bank11.rd_width - 1 downto 0);
    ra12          : out   std_logic_vector(bank12.ra_width - 1 downto 0);
    rc12          : inout std_logic_vector(bank12.rc_width - 1 downto 0);
    rd12          : inout std_logic_vector(bank12.rd_width - 1 downto 0);
    ra13          : out   std_logic_vector(bank13.ra_width - 1 downto 0);
    rc13          : inout std_logic_vector(bank13.rc_width - 1 downto 0);
    rd13          : inout std_logic_vector(bank13.rd_width - 1 downto 0);
    ra14          : out   std_logic_vector(bank14.ra_width - 1 downto 0);
    rc14          : inout std_logic_vector(bank14.rc_width - 1 downto 0);
    rd14          : inout std_logic_vector(bank14.rd_width - 1 downto 0);
    ra15          : out   std_logic_vector(bank15.ra_width - 1 downto 0);
    rc15          : inout std_logic_vector(bank15.rc_width - 1 downto 0);
    rd15          : inout std_logic_vector(bank15.rd_width - 1 downto 0);
    ramclki       : in    std_logic_vector(num_ramclk - 1 downto 0);
    ramclko       : out   std_logic_vector(num_ramclk - 1 downto 0)
  );
end component;

end;
