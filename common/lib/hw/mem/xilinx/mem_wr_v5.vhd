-------------------------------------------------------------------------
-- Company     : Linkos
-- Engineer    : Golovachenko Victor
--
-- Create Date : 21.01.2012 11:44:53
-- Module Name : mem_wr
--
-- Назначение/Описание :
--  Запись/Чтение данных ОЗУ
--
-- p_in_cfg_mem_dlen_rq (total request size)  : <--------------------------------->
-- p_in_cfg_mem_trn_len (size one transaction): <-----> <-----> <-----> ... <----->
--
-------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

library work;
use work.vicg_common_pkg.all;
use work.mem_wr_pkg.all;

entity mem_wr is
generic(
G_MEM_BANK_M_BIT : integer:=29;--//биты(мл. ст.) определяющие банк ОЗУ. Относится в порту p_in_cfg_mem_adr
G_MEM_BANK_L_BIT : integer:=28;
G_MEM_AWIDTH     : integer:=32;
G_MEM_DWIDTH     : integer:=32
);
port(
-------------------------------
--Конфигурирование
-------------------------------
p_in_cfg_mem_adr     : in    std_logic_vector(31 downto 0);--//Адрес ОЗУ (в BYTE)
p_in_cfg_mem_trn_len : in    std_logic_vector(15 downto 0);--//Размер одиночной MEM_TRN (в DWORD)
p_in_cfg_mem_dlen_rq : in    std_logic_vector(15 downto 0);--//Размер запрашиваемых данных записи/чтения (в DWORD)
p_in_cfg_mem_wr      : in    std_logic;                    --//Тип операции
p_in_cfg_mem_start   : in    std_logic;                    --//Строб: Пуск операции
p_out_cfg_mem_done   : out   std_logic;                    --//Строб: Операции завершена

-------------------------------
--Связь с пользовательскими буферами
-------------------------------
--usr_buf->mem
p_in_usr_txbuf_dout  : in    std_logic_vector(G_MEM_DWIDTH-1 downto 0);
p_out_usr_txbuf_rd   : out   std_logic;
p_in_usr_txbuf_empty : in    std_logic;

--usr_buf<-mem
p_out_usr_rxbuf_din  : out   std_logic_vector(G_MEM_DWIDTH-1 downto 0);
p_out_usr_rxbuf_wd   : out   std_logic;
p_in_usr_rxbuf_full  : in    std_logic;

---------------------------------
--Связь с mem_ctrl.vhd
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
end mem_wr;

architecture behavioral of mem_wr is

signal i_mem_req           : std_logic;


--MAIN
begin

--//----------------------------------
--//Технологические сигналы
--//----------------------------------
p_out_tst<=(others=>'0');


--//----------------------------------------------
--//Связь с контроллером памяти
--//----------------------------------------------

p_out_mem.clk <= p_in_clk;
p_out_mem.cmd_req <= i_mem_req;

p_out_mem.cmd_adr <= EXT(p_in_cfg_mem_adr, p_out_mem.adr'length);
p_out_mem.cmd_wr  <= C_MEM_CMD_WR when p_in_cfg_mem_wr=C_MEMWR_WRITE else C_MEM_CMD_RD;
p_out_mem.cmd_bl  <= p_in_cfg_mem_trn_len(p_out_mem.cmd_bl'range);

p_out_mem.utxbuf_dout  <= EXT(p_in_usr_txbuf_dout, p_out_mem.utxbuf_dout'length);
p_out_mem.utxbuf_empty <= p_in_usr_txbuf_empty;

p_out_mem.urxbuf_full  <= p_in_usr_rxbuf_full;


p_out_cfg_mem_done <= p_in_mem.cmd_done;

p_out_usr_txbuf_rd <= p_in_mem.utxbuf_rd;

p_out_usr_rxbuf_din <= p_in_mem.urxbuf_din(p_out_usr_rxbuf_din'range);
p_out_usr_rxbuf_wr  <= p_in_mem.urxbuf_wr;


process(p_in_rst,p_in_clk)
begin
  if p_in_rst='1' then
    i_mem_req<='0';
  elsif p_in_clk'event and p_in_clk='1' then
    if p_in_cfg_mem_start='1' then
      i_mem_req<='1';
    elsif p_in_mem.cmd_done='1' then
      i_mem_req<='0';
    end if;
  end if;
end process;

--END MAIN
end behavioral;
