-------------------------------------------------------------------------
-- Company     : Telemix
-- Engineer    : Golovachenko Victor
--
-- Create Date : 04.11.2011 10:48:05
-- Module Name : pcie_pkg
--
-- Description :
--
-- Revision:
-- Revision 0.01 - File Created
--
-------------------------------------------------------------------------
library ieee;
use ieee.STD_LOGIC_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_arith.all;

library work;
use work.vicg_common_pkg.all;

package pcie_pkg is

type TPce2Mem_Ctrl is record
dir       : std_logic;
start     : std_logic;
adr       : std_logic_vector(31 downto 0);--//адрес в BYTE
req_len   : std_logic_vector(17 downto 0);--//значение в BYTE. max 128KB
trnwr_len : std_logic_vector(7 downto 0); --//значение в DWORD
trnrd_len : std_logic_vector(7 downto 0); --//значение в DWORD
end record;

type TPce2Mem_Status is record
done    : std_logic;
end record;


--component pcie2mem_ctrl
--generic(
--G_MEMCTRL_AWIDTH : integer:=32;
--G_MEMCTRL_DWIDTH : integer:=32;
--G_MEM_BANK_M_BIT : integer:=29;
--G_MEM_BANK_L_BIT : integer:=28;
--G_DBG            : string :="OFF"
--);
--port(
---------------------------------------------------------
----Связь с mem_ctrl
---------------------------------------------------------
--p_out_memarb_req  : out   std_logic;
--p_in_memarb_en    : in    std_logic;
--
--p_out_mem_bank1h  : out   std_logic_vector(15 downto 0);
--p_out_mem_ce      : out   std_logic;
--p_out_mem_cw      : out   std_logic;
--p_out_mem_rd      : out   std_logic;
--p_out_mem_wr      : out   std_logic;
--p_out_mem_term    : out   std_logic;
--p_out_mem_adr     : out   std_logic_vector(G_MEMCTRL_AWIDTH - 1 downto 0);
--p_out_mem_be      : out   std_logic_vector(G_MEMCTRL_DWIDTH / 8 - 1 downto 0);
--p_out_mem_din     : out   std_logic_vector(G_MEMCTRL_DWIDTH - 1 downto 0);
--p_in_mem_dout     : in    std_logic_vector(G_MEMCTRL_DWIDTH - 1 downto 0);
--
--p_in_mem_wf       : in    std_logic;
--p_in_mem_wpf      : in    std_logic;
--p_in_mem_re       : in    std_logic;
--p_in_mem_rpe      : in    std_logic;
--
--p_out_mem_clk     : out   std_logic;
--
---------------------------------------------------------
----Управление
---------------------------------------------------------
--p_in_ctrl         : in    TPce2Mem_Ctrl;
--p_out_status      : out   TPce2Mem_Status;
--
--p_in_txd          : in    std_logic_vector(31 downto 0);
--p_in_txd_wr       : in    std_logic;
--p_out_txbuf_full  : out   std_logic;
--
--p_out_rxd         : out   std_logic_vector(31 downto 0);
--p_in_rxd_rd       : in    std_logic;
--p_out_rxbuf_empty : out   std_logic;
--
--p_in_hclk         : in    std_logic;
--
---------------------------------
----Технологический
---------------------------------
--p_in_tst          : in    std_logic_vector(31 downto 0);
--p_out_tst         : out   std_logic_vector(31 downto 0);
--
---------------------------------
----System
---------------------------------
--p_in_clk          : in    std_logic;
--p_in_rst          : in    std_logic
--);
--end component;



end pcie_pkg;


package body pcie_pkg is

end pcie_pkg;






