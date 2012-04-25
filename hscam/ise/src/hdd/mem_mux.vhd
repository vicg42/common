-------------------------------------------------------------------------
-- Company     : Linkos
-- Engineer    : Golovachenko Victor
--
-- Create Date : 23.04.2012 12:36:40
-- Module Name : mem_mux
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
use work.mem_wr_pkg.all;

entity mem_mux is
generic(
G_MEM_HDD   :integer:=0;
G_MEM_VCTRL :integer:=1;
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

architecture behavioral of mem_mux is

signal i_memout_null            : TMemOUT;


--//MAIN
begin

--//Инициализация
i_memout_null.req_en   <='0';
i_memout_null.rxd      <=(others=>'0');

i_memout_null.cmdbuf_full   <='0';
i_memout_null.cmdbuf_empty  <='1';
i_memout_null.cmdbuf_err    <='0';

i_memout_null.txbuf_full    <='0';
i_memout_null.txbuf_empty   <='0';
i_memout_null.txbuf_wrcount <=(others=>'0');
i_memout_null.txbuf_err     <='0';
i_memout_null.txbuf_underrun<='0';

i_memout_null.rxbuf_full    <='0';
i_memout_null.rxbuf_empty   <='1';
i_memout_null.rxbuf_rdcount <=(others=>'0');
i_memout_null.rxbuf_err     <='0';
i_memout_null.rxbuf_overflow<='0';


--//Ver0
p_out_mem(G_MEM_VCTRL)(0)<=p_in_memwr_v;
p_out_memwr_v <= p_in_mem(G_MEM_VCTRL)(0);

p_out_mem(G_MEM_VCTRL)(1)<=p_in_memrd_v;
p_out_memrd_v <= p_in_mem(G_MEM_VCTRL)(1);

p_out_mem(G_MEM_HDD)(0)<=p_in_memwr_h;
p_out_memwr_h <= p_in_mem(G_MEM_HDD)(0);

p_out_mem(G_MEM_HDD)(1)<=p_in_memrd_h;
p_out_memrd_h <= p_in_mem(G_MEM_HDD)(1);



--      --Bank|CH
--p_out_mem(0)(0)<=p_in_memwr_v when p_in_sel='1' else p_in_memwr_h;
--p_out_memwr_v <= p_in_mem(0)(0) when p_in_sel='1' else i_memout_null;
--
--p_out_mem(0)(1)<=p_in_memrd_v when p_in_sel='1' else p_in_memrd_h;
--p_out_memrd_v <= p_in_mem(0)(1) when p_in_sel='1' else i_memout_null;
--
--p_out_mem(1)(0)<=p_in_memwr_v;
--p_out_mem(1)(1)<=p_in_memrd_v;
--
------CH WRITE                                    --Bank|CH
----p_out_memwr           => i_mem_in_bank (CI_MEM_VCTRL)(0),--: out   TMemIN;
----p_in_memwr            => i_mem_out_bank(CI_MEM_VCTRL)(0),--: in    TMemOUT;
------CH READ
----p_out_memrd           => i_mem_in_bank (CI_MEM_VCTRL)(1),--: out   TMemIN;
----p_in_memrd            => i_mem_out_bank(CI_MEM_VCTRL)(1),--: in    TMemOUT;


--//END MAIN
end behavioral;
