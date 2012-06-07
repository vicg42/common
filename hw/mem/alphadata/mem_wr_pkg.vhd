-------------------------------------------------------------------------
-- Company     : Linkos
-- Engineer    : Golovachenko Victor
--
-- Create Date : 17.10.2011 10:46:45
-- Module Name : mem_wr_pkg.vhd
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
use work.vicg_common_pkg.all;
use work.mem_glob_pkg.all;

package mem_wr_pkg is

type TMemIN is record
req      : std_logic;
bank     : std_logic_vector(3 downto 0);
ce       : std_logic;
cw       : std_logic;
rd       : std_logic;
wr       : std_logic;
term     : std_logic;
adr      : std_logic_vector(C_MEMWR_AWIDTH_MAX - 1 downto 0);
dbe      : std_logic_vector(C_MEMWR_DWIDTH_MAX / 8 - 1 downto 0);
data     : std_logic_vector(C_MEMWR_DWIDTH_MAX - 1 downto 0);
clk      : std_logic;
rstn     : std_logic;
end record;

type TMemOUT is record
req_en   : std_logic;
data     : std_logic_vector(C_MEMWR_DWIDTH_MAX - 1 downto 0);
--buf_wf   : std_logic;
buf_wpf  : std_logic;
buf_re   : std_logic;
--buf_rpe  : std_logic;
clk      : std_logic;
rstn     : std_logic;
end record;

Type TMemINCh is array (0 to C_MEMCH_COUNT_MAX-1) of TMemIN;
Type TMemOUTCh is array (0 to C_MEMCH_COUNT_MAX-1) of TMemOUT;

--//Режимы работы - запись/чтение
constant C_MEMWR_WRITE   : std_logic:='1';
constant C_MEMWR_READ    : std_logic:='0';

component mem_wr
generic(
G_MEM_BANK_M_BIT : integer:=29;
G_MEM_BANK_L_BIT : integer:=28;
G_MEM_AWIDTH     : integer:=32;
G_MEM_DWIDTH     : integer:=32
);
port(
-------------------------------
-- Конфигурирование
-------------------------------
p_in_cfg_mem_adr     : in    std_logic_vector(31 downto 0);
p_in_cfg_mem_trn_len : in    std_logic_vector(15 downto 0);
p_in_cfg_mem_dlen_rq : in    std_logic_vector(15 downto 0);
p_in_cfg_mem_wr      : in    std_logic;
p_in_cfg_mem_start   : in    std_logic;
p_out_cfg_mem_done   : out   std_logic;

-------------------------------
-- Связь с пользовательскими буферами
-------------------------------
--//usr_buf->mem
p_in_usr_txbuf_dout  : in    std_logic_vector(G_MEM_DWIDTH-1 downto 0);
p_out_usr_txbuf_rd   : out   std_logic;
p_in_usr_txbuf_empty : in    std_logic;

--//usr_buf<-mem
p_out_usr_rxbuf_din  : out   std_logic_vector(G_MEM_DWIDTH-1 downto 0);
p_out_usr_rxbuf_wd   : out   std_logic;
p_in_usr_rxbuf_full  : in    std_logic;

---------------------------------
-- Связь с mem_ctrl.vhd
---------------------------------
p_out_mem            : out   TMemIN;
p_in_mem             : in    TMemOUT;

-------------------------------
--Технологические сигналы
-------------------------------
p_in_tst             : in    std_logic_vector(31 downto 0);
p_out_tst            : out   std_logic_vector(31 downto 0);

-------------------------------
--System
-------------------------------
p_in_clk             : in    std_logic;
p_in_rst             : in    std_logic
);
end component;


end;
