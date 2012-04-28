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
--//Один MCB для RAMBUF и  VCTRL.
--//p_in_sel - Выбор кому работать с MCB
--//##################################
architecture arch1 of mem_mux is

--//MAIN_arch1
begin

--//--------------------------------
--//CH WR:
--//--------------------------------
p_out_mem(G_MEMBANK_0)(C_MEMCH_WR).req      <= p_in_memwr_h.req      when p_in_sel='1' else p_in_memwr_v.req     ;
p_out_mem(G_MEMBANK_0)(C_MEMCH_WR).req_type <= p_in_memwr_h.req_type when p_in_sel='1' else p_in_memwr_v.req_type;
p_out_mem(G_MEMBANK_0)(C_MEMCH_WR).bank     <= p_in_memwr_h.bank     when p_in_sel='1' else p_in_memwr_v.bank    ;
p_out_mem(G_MEMBANK_0)(C_MEMCH_WR).cmd_i    <= p_in_memwr_h.cmd_i    when p_in_sel='1' else p_in_memwr_v.cmd_i   ;
p_out_mem(G_MEMBANK_0)(C_MEMCH_WR).cmd_bl   <= p_in_memwr_h.cmd_bl   when p_in_sel='1' else p_in_memwr_v.cmd_bl  ;
p_out_mem(G_MEMBANK_0)(C_MEMCH_WR).cmd_wr   <= p_in_memwr_h.cmd_wr   when p_in_sel='1' else p_in_memwr_v.cmd_wr  ;
p_out_mem(G_MEMBANK_0)(C_MEMCH_WR).rxd_rd   <= p_in_memwr_h.rxd_rd   when p_in_sel='1' else p_in_memwr_v.rxd_rd  ;
p_out_mem(G_MEMBANK_0)(C_MEMCH_WR).txd_wr   <= p_in_memwr_h.txd_wr   when p_in_sel='1' else p_in_memwr_v.txd_wr  ;
p_out_mem(G_MEMBANK_0)(C_MEMCH_WR).adr      <= p_in_memwr_h.adr      when p_in_sel='1' else p_in_memwr_v.adr     ;
p_out_mem(G_MEMBANK_0)(C_MEMCH_WR).txd_be   <= p_in_memwr_h.txd_be   when p_in_sel='1' else p_in_memwr_v.txd_be  ;
p_out_mem(G_MEMBANK_0)(C_MEMCH_WR).txd      <= p_in_memwr_h.txd      when p_in_sel='1' else p_in_memwr_v.txd     ;
p_out_mem(G_MEMBANK_0)(C_MEMCH_WR).clk      <= p_in_memwr_h.clk;

--//HDD:
p_out_memwr_h.req_en         <= p_in_mem(G_MEMBANK_0)(C_MEMCH_WR).req_en        ;
p_out_memwr_h.rxd            <= p_in_mem(G_MEMBANK_0)(C_MEMCH_WR).rxd           ;

p_out_memwr_h.cmdbuf_full    <= p_in_mem(G_MEMBANK_0)(C_MEMCH_WR).cmdbuf_full   ;
p_out_memwr_h.cmdbuf_empty   <= p_in_mem(G_MEMBANK_0)(C_MEMCH_WR).cmdbuf_empty  ;
p_out_memwr_h.cmdbuf_err     <= p_in_mem(G_MEMBANK_0)(C_MEMCH_WR).cmdbuf_err    ;

p_out_memwr_h.txbuf_full     <= p_in_mem(G_MEMBANK_0)(C_MEMCH_WR).txbuf_full    ;
p_out_memwr_h.txbuf_empty    <= p_in_mem(G_MEMBANK_0)(C_MEMCH_WR).txbuf_empty   ;
p_out_memwr_h.txbuf_wrcount  <= p_in_mem(G_MEMBANK_0)(C_MEMCH_WR).txbuf_wrcount ;
p_out_memwr_h.txbuf_err      <= p_in_mem(G_MEMBANK_0)(C_MEMCH_WR).txbuf_err     ;
p_out_memwr_h.txbuf_underrun <= p_in_mem(G_MEMBANK_0)(C_MEMCH_WR).txbuf_underrun;

p_out_memwr_h.rxbuf_full     <= p_in_mem(G_MEMBANK_0)(C_MEMCH_WR).rxbuf_full    ;
p_out_memwr_h.rxbuf_empty    <= p_in_mem(G_MEMBANK_0)(C_MEMCH_WR).rxbuf_empty   ;
p_out_memwr_h.rxbuf_rdcount  <= p_in_mem(G_MEMBANK_0)(C_MEMCH_WR).rxbuf_rdcount ;
p_out_memwr_h.rxbuf_err      <= p_in_mem(G_MEMBANK_0)(C_MEMCH_WR).rxbuf_err     ;
p_out_memwr_h.rxbuf_overflow <= p_in_mem(G_MEMBANK_0)(C_MEMCH_WR).rxbuf_overflow;

--//VCTRL:
p_out_memwr_v.req_en         <= p_in_mem(G_MEMBANK_0)(C_MEMCH_WR).req_en        ;
p_out_memwr_v.rxd            <= p_in_mem(G_MEMBANK_0)(C_MEMCH_WR).rxd           ;

p_out_memwr_v.cmdbuf_full    <= p_in_mem(G_MEMBANK_0)(C_MEMCH_WR).cmdbuf_full   ;
p_out_memwr_v.cmdbuf_empty   <= p_in_mem(G_MEMBANK_0)(C_MEMCH_WR).cmdbuf_empty  ;
p_out_memwr_v.cmdbuf_err     <= p_in_mem(G_MEMBANK_0)(C_MEMCH_WR).cmdbuf_err    ;

p_out_memwr_v.txbuf_full     <= p_in_mem(G_MEMBANK_0)(C_MEMCH_WR).txbuf_full    ;
p_out_memwr_v.txbuf_empty    <= p_in_mem(G_MEMBANK_0)(C_MEMCH_WR).txbuf_empty   ;
p_out_memwr_v.txbuf_wrcount  <= p_in_mem(G_MEMBANK_0)(C_MEMCH_WR).txbuf_wrcount ;
p_out_memwr_v.txbuf_err      <= p_in_mem(G_MEMBANK_0)(C_MEMCH_WR).txbuf_err     ;
p_out_memwr_v.txbuf_underrun <= p_in_mem(G_MEMBANK_0)(C_MEMCH_WR).txbuf_underrun;

p_out_memwr_v.rxbuf_full     <= p_in_mem(G_MEMBANK_0)(C_MEMCH_WR).rxbuf_full    ;
p_out_memwr_v.rxbuf_empty    <= p_in_mem(G_MEMBANK_0)(C_MEMCH_WR).rxbuf_empty   ;
p_out_memwr_v.rxbuf_rdcount  <= p_in_mem(G_MEMBANK_0)(C_MEMCH_WR).rxbuf_rdcount ;
p_out_memwr_v.rxbuf_err      <= p_in_mem(G_MEMBANK_0)(C_MEMCH_WR).rxbuf_err     ;
p_out_memwr_v.rxbuf_overflow <= p_in_mem(G_MEMBANK_0)(C_MEMCH_WR).rxbuf_overflow;


--//--------------------------------
--//CH RD:
--//--------------------------------
p_out_mem(G_MEMBANK_0)(C_MEMCH_RD).req      <= p_in_memrd_h.req      when p_in_sel='1' else p_in_memrd_v.req     ;
p_out_mem(G_MEMBANK_0)(C_MEMCH_RD).req_type <= p_in_memrd_h.req_type when p_in_sel='1' else p_in_memrd_v.req_type;
p_out_mem(G_MEMBANK_0)(C_MEMCH_RD).bank     <= p_in_memrd_h.bank     when p_in_sel='1' else p_in_memrd_v.bank    ;
p_out_mem(G_MEMBANK_0)(C_MEMCH_RD).cmd_i    <= p_in_memrd_h.cmd_i    when p_in_sel='1' else p_in_memrd_v.cmd_i   ;
p_out_mem(G_MEMBANK_0)(C_MEMCH_RD).cmd_bl   <= p_in_memrd_h.cmd_bl   when p_in_sel='1' else p_in_memrd_v.cmd_bl  ;
p_out_mem(G_MEMBANK_0)(C_MEMCH_RD).cmd_wr   <= p_in_memrd_h.cmd_wr   when p_in_sel='1' else p_in_memrd_v.cmd_wr  ;
p_out_mem(G_MEMBANK_0)(C_MEMCH_RD).rxd_rd   <= p_in_memrd_h.rxd_rd   when p_in_sel='1' else p_in_memrd_v.rxd_rd  ;
p_out_mem(G_MEMBANK_0)(C_MEMCH_RD).txd_wr   <= p_in_memrd_h.txd_wr   when p_in_sel='1' else p_in_memrd_v.txd_wr  ;
p_out_mem(G_MEMBANK_0)(C_MEMCH_RD).adr      <= p_in_memrd_h.adr      when p_in_sel='1' else p_in_memrd_v.adr     ;
p_out_mem(G_MEMBANK_0)(C_MEMCH_RD).txd_be   <= p_in_memrd_h.txd_be   when p_in_sel='1' else p_in_memrd_v.txd_be  ;
p_out_mem(G_MEMBANK_0)(C_MEMCH_RD).txd      <= p_in_memrd_h.txd      when p_in_sel='1' else p_in_memrd_v.txd     ;
p_out_mem(G_MEMBANK_0)(C_MEMCH_RD).clk      <= p_in_memrd_h.clk;

--//HDD:
p_out_memrd_h.req_en         <= p_in_mem(G_MEMBANK_0)(C_MEMCH_RD).req_en        ;
p_out_memrd_h.rxd            <= p_in_mem(G_MEMBANK_0)(C_MEMCH_RD).rxd           ;

p_out_memrd_h.cmdbuf_full    <= p_in_mem(G_MEMBANK_0)(C_MEMCH_RD).cmdbuf_full   ;
p_out_memrd_h.cmdbuf_empty   <= p_in_mem(G_MEMBANK_0)(C_MEMCH_RD).cmdbuf_empty  ;
p_out_memrd_h.cmdbuf_err     <= p_in_mem(G_MEMBANK_0)(C_MEMCH_RD).cmdbuf_err    ;

p_out_memrd_h.txbuf_full     <= p_in_mem(G_MEMBANK_0)(C_MEMCH_RD).txbuf_full    ;
p_out_memrd_h.txbuf_empty    <= p_in_mem(G_MEMBANK_0)(C_MEMCH_RD).txbuf_empty   ;
p_out_memrd_h.txbuf_wrcount  <= p_in_mem(G_MEMBANK_0)(C_MEMCH_RD).txbuf_wrcount ;
p_out_memrd_h.txbuf_err      <= p_in_mem(G_MEMBANK_0)(C_MEMCH_RD).txbuf_err     ;
p_out_memrd_h.txbuf_underrun <= p_in_mem(G_MEMBANK_0)(C_MEMCH_RD).txbuf_underrun;

p_out_memrd_h.rxbuf_full     <= p_in_mem(G_MEMBANK_0)(C_MEMCH_RD).rxbuf_full    ;
p_out_memrd_h.rxbuf_empty    <= p_in_mem(G_MEMBANK_0)(C_MEMCH_RD).rxbuf_empty   ;
p_out_memrd_h.rxbuf_rdcount  <= p_in_mem(G_MEMBANK_0)(C_MEMCH_RD).rxbuf_rdcount ;
p_out_memrd_h.rxbuf_err      <= p_in_mem(G_MEMBANK_0)(C_MEMCH_RD).rxbuf_err     ;
p_out_memrd_h.rxbuf_overflow <= p_in_mem(G_MEMBANK_0)(C_MEMCH_RD).rxbuf_overflow;

--//VCTRL:
p_out_memrd_v.req_en         <= p_in_mem(G_MEMBANK_0)(C_MEMCH_RD).req_en        ;
p_out_memrd_v.rxd            <= p_in_mem(G_MEMBANK_0)(C_MEMCH_RD).rxd           ;

p_out_memrd_v.cmdbuf_full    <= p_in_mem(G_MEMBANK_0)(C_MEMCH_RD).cmdbuf_full   ;
p_out_memrd_v.cmdbuf_empty   <= p_in_mem(G_MEMBANK_0)(C_MEMCH_RD).cmdbuf_empty  ;
p_out_memrd_v.cmdbuf_err     <= p_in_mem(G_MEMBANK_0)(C_MEMCH_RD).cmdbuf_err    ;

p_out_memrd_v.txbuf_full     <= p_in_mem(G_MEMBANK_0)(C_MEMCH_RD).txbuf_full    ;
p_out_memrd_v.txbuf_empty    <= p_in_mem(G_MEMBANK_0)(C_MEMCH_RD).txbuf_empty   ;
p_out_memrd_v.txbuf_wrcount  <= p_in_mem(G_MEMBANK_0)(C_MEMCH_RD).txbuf_wrcount ;
p_out_memrd_v.txbuf_err      <= p_in_mem(G_MEMBANK_0)(C_MEMCH_RD).txbuf_err     ;
p_out_memrd_v.txbuf_underrun <= p_in_mem(G_MEMBANK_0)(C_MEMCH_RD).txbuf_underrun;

p_out_memrd_v.rxbuf_full     <= p_in_mem(G_MEMBANK_0)(C_MEMCH_RD).rxbuf_full    ;
p_out_memrd_v.rxbuf_empty    <= p_in_mem(G_MEMBANK_0)(C_MEMCH_RD).rxbuf_empty   ;
p_out_memrd_v.rxbuf_rdcount  <= p_in_mem(G_MEMBANK_0)(C_MEMCH_RD).rxbuf_rdcount ;
p_out_memrd_v.rxbuf_err      <= p_in_mem(G_MEMBANK_0)(C_MEMCH_RD).rxbuf_err     ;
p_out_memrd_v.rxbuf_overflow <= p_in_mem(G_MEMBANK_0)(C_MEMCH_RD).rxbuf_overflow;


--//END MAIN_arch1
end arch1;
