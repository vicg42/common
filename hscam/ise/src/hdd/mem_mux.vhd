-------------------------------------------------------------------------
-- Company     : Linkos
-- Engineer    : Golovachenko Victor
--
-- Create Date : 23.04.2012 12:36:40
-- Module Name : mem_mux
--
-- Назначение/Описание :
-- Доступ пользовательских модулей к контроллеру ОЗУ
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
use work.mem_ctrl_pkg.all;
use work.mem_wr_pkg.all;

entity mem_mux is
generic(
G_MEMBANK_0 :integer:=0;
G_MEMBANK_1 :integer:=1;
G_SIM : string:= "OFF"
);
port(
------------------------------------
--Управление
------------------------------------
p_in_sel      : in    std_logic;

------------------------------------
--VCTRL
------------------------------------
p_in_memwr_v  : in    TMemIN;
p_out_memwr_v : out   TMemOUT;

p_in_memrd_v  : in    TMemIN;
p_out_memrd_v : out   TMemOUT;

------------------------------------
--HDD
------------------------------------
p_in_memwr_h  : in    TMemIN;
p_out_memwr_h : out   TMemOUT;

p_in_memrd_h  : in    TMemIN;
p_out_memrd_h : out   TMemOUT;

------------------------------------
--MEM_CTRL
------------------------------------
p_out_mem     : out   TMemINBank;
p_in_mem      : in    TMemOUTBank;

------------------------------------
--System
------------------------------------
p_in_sys      : in    TMEMCTRL_sysin
);
end mem_mux;

--//##################################
--//для RAMBUF - свой MCB, а для VCTRL - свой MCB
--//##################################
architecture arch0 of mem_mux is

--//MAIN_arch0
begin

p_out_mem(G_MEMBANK_0)(C_MEMCH_WR)<=p_in_memwr_h;
p_out_memwr_h <= p_in_mem(G_MEMBANK_0)(C_MEMCH_WR);

p_out_mem(G_MEMBANK_0)(C_MEMCH_RD)<=p_in_memrd_h;
p_out_memrd_h <= p_in_mem(G_MEMBANK_0)(C_MEMCH_RD);

p_out_mem(G_MEMBANK_1)(C_MEMCH_WR)<=p_in_memwr_v;
p_out_memwr_v <= p_in_mem(G_MEMBANK_1)(C_MEMCH_WR);

p_out_mem(G_MEMBANK_1)(C_MEMCH_RD)<=p_in_memrd_v;
p_out_memrd_v <= p_in_mem(G_MEMBANK_1)(C_MEMCH_RD);

--//END MAIN_arch0
end arch0;
