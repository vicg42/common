-------------------------------------------------------------------------
-- Company     : Linkos
-- Engineer    : Golovachenko Victor
--
-- Create Date : 17.10.2011 10:46:45
-- Module Name : memory_ctrl_ch_wr_pkg.vhd
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
use work.memory_ctrl_pkg.all;

package memory_ctrl_ch_wr_pkg is

--//Режимы работы - запись/чтение
constant C_MEMCTRLCHWR_WRITE   : std_logic:='1';
constant C_MEMCTRLCHWR_READ    : std_logic:='0';

component memory_ctrl_ch_wr
generic(
G_MEM_BANK_M_BIT : integer:=29;
G_MEM_BANK_L_BIT : integer:=28
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
p_in_usr_txbuf_dout  : in    std_logic_vector(C_MEMCTRL_DATA_WIDTH - 1 downto 0);
p_out_usr_txbuf_rd   : out   std_logic;
p_in_usr_txbuf_empty : in    std_logic;

--//usr_buf<-mem
p_out_usr_rxbuf_din  : out   std_logic_vector(C_MEMCTRL_DATA_WIDTH - 1 downto 0);
p_out_usr_rxbuf_wd   : out   std_logic;
p_in_usr_rxbuf_full  : in    std_logic;

---------------------------------
-- Связь с memory_ctrl.vhd
---------------------------------
p_out_memarb_req     : out   std_logic;
p_in_memarb_en       : in    std_logic;

p_out_mem_bank1h     : out   std_logic_vector(15 downto 0);
p_out_mem_ce         : out   std_logic;
p_out_mem_cw         : out   std_logic;
p_out_mem_rd         : out   std_logic;
p_out_mem_wr         : out   std_logic;
p_out_mem_term       : out   std_logic;
p_out_mem_adr        : out   std_logic_vector(C_MEMCTRL_ADDR_WIDTH - 1 downto 0);
p_out_mem_be         : out   std_logic_vector(C_MEMCTRL_DATA_WIDTH / 8 - 1 downto 0);
p_out_mem_din        : out   std_logic_vector(C_MEMCTRL_DATA_WIDTH - 1 downto 0);
p_in_mem_dout        : in    std_logic_vector(C_MEMCTRL_DATA_WIDTH - 1 downto 0);

p_in_mem_wf          : in    std_logic;
p_in_mem_wpf         : in    std_logic;
p_in_mem_re          : in    std_logic;
p_in_mem_rpe         : in    std_logic;

p_out_mem_clk        : out   std_logic;

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
