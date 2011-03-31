-------------------------------------------------------------------------
-- Company     : Linkos
-- Engineer    : Golovachenko Victor
--
-- Create Date : 31.03.2011 18:27:17
-- Module Name : sata_raid_ctrl
--
-- Назначение :
--
-- Revision:
-- Revision 0.01 - File Created
--
--
-------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_misc.all;
use ieee.std_logic_unsigned.all;

library unisim;
use unisim.vcomponents.all;

use work.vicg_common_pkg.all;
use work.sata_unit_pkg.all;
use work.sata_pkg.all;

entity sata_raid_ctrl is
generic
(
G_HDD_COUNT : integer:=1;    --//Кол-во sata устр-в (min/max - 1/8)
G_DBG       : string :="OFF";
G_SIM       : string :="OFF"
);
port
(
--------------------------------------------------
--Связь с модулем dsn_hdd.vhd
--------------------------------------------------
p_in_usr_ctrl           : in    std_logic_vector(31 downto 0);

p_in_usr_cxd            : in    std_logic_vector(15 downto 0);
p_out_usr_cxd_rd        : out   std_logic;
p_in_usr_cxbuf_empty    : in    std_logic;

--------------------------------------------------
--Связь с модулями sata_host.vhd
--------------------------------------------------
p_out_sh_cxd            : out   std_logic_vector(15 downto 0);
p_out_sh_cxd_sof_n      : out   std_logic;
p_out_sh_cxd_eof_n      : out   std_logic;
p_out_sh_cxd_src_rdy_n  : out   std_logic;
p_out_sh_mask           : out   std_logic_vector(7 downto 0);

--------------------------------------------------
--Технологические сигналы
--------------------------------------------------
p_in_tst                : in    std_logic_vector(31 downto 0);
p_out_tst               : out   std_logic_vector(31 downto 0);

--------------------------------------------------
--System
--------------------------------------------------
p_in_clk                : in    std_logic;
p_in_rst                : in    std_logic
);
end sata_raid_ctrl;

architecture behavioral of sata_raid_ctrl is



--MAIN
begin

--//----------------------------------
--//Технологические сигналы
--//----------------------------------
gen_dbg_off : if strcmp(G_DBG,"OFF") generate
p_out_tst(31 downto 0)<=(others=>'0');
end generate gen_dbg_off;

gen_dbg_on : if strcmp(G_DBG,"ON") generate
--ltstout:process(p_in_rst,p_in_clk)
--begin
--  if p_in_rst='1' then
--    tst_fms_cs_dly<=(others=>'0');
--    p_out_tst(31 downto 1)<=(others=>'0');
--  elsif p_in_clk'event and p_in_clk='1' then
--
--    tst_fms_cs_dly<=tst_fms_cs;
--    p_out_tst(0)<=OR_reduce(tst_fms_cs_dly);
--  end if;
--end process ltstout;
p_out_tst(31 downto 0)<=(others=>'0');
end generate gen_dbg_on;



p_out_usr_cxd_rd<=not p_in_usr_cxbuf_empty;

p_out_sh_cxd<=p_in_usr_cxd;
p_out_sh_cxd_sof_n<=not p_in_usr_cxbuf_empty;
p_out_sh_cxd_eof_n<=not p_in_usr_cxbuf_empty;
p_out_sh_cxd_src_rdy_n<=not p_in_usr_cxbuf_empty;

p_out_sh_mask<=p_in_usr_ctrl(7 downto 0);


--END MAIN
end behavioral;
