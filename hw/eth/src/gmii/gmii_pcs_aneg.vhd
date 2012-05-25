-------------------------------------------------------------------------
-- Company     : Linkos
-- Engineer    : Golovachenko Victor
--
-- Create Date : 22.05.2012 11:55:44
-- Module Name : gmii_pcs_aneg
--
-- Назначение/Описание :
--
--
--
-------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_misc.all;
use ieee.std_logic_unsigned.all;

library work;
use work.vicg_common_pkg.all;
use work.gmii_pkg.all;

entity gmii_pcs_aneg is
generic(
G_GT_DBUS : integer:=8;
G_DBG : string:="OFF";
G_SIM : string:="OFF"
);
port(
--------------------------------------
--
--------------------------------------
p_in_ctrl    : in    std_logic_vector(15 downto 0);

--------------------------------------
--
--------------------------------------
p_out_xmit   : out   std_logic_vector(3 downto 0);
p_in_rxcfg   : in    std_logic_vector(15 downto 0);
p_out_txcfg  : out   std_logic_vector(15 downto 0);

--------------------------------------
--Технологические сигналы
--------------------------------------
p_in_tst     : in    std_logic_vector(31 downto 0);
p_out_tst    : out   std_logic_vector(31 downto 0);

--------------------------------------
--SYSTEM
--------------------------------------
p_in_clk     : in    std_logic;
p_in_rst     : in    std_logic
);
end gmii_pcs_aneg;

architecture behavioral of gmii_pcs_aneg is



--MAIN
begin

--//----------------------------------
--//Технологические сигналы
--//----------------------------------
gen_dbg_off : if strcmp(G_DBG,"OFF") generate
p_out_tst(31 downto 0)<=(others=>'0');
end generate gen_dbg_off;

gen_dbg_on : if strcmp(G_DBG,"ON") generate
p_out_tst(31 downto 0)<=(others=>'0');
end generate gen_dbg_on;


p_out_xmit <= CONV_STD_LOGIC_VECTOR(C_PCS_XMIT_DATA, p_out_xmit'length);



--END MAIN
end behavioral;

