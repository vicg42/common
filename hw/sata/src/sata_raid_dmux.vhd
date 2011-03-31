-------------------------------------------------------------------------
-- Company     : Linkos
-- Engineer    : Golovachenko Victor
--
-- Create Date : 31.03.2011 18:27:12
-- Module Name : sata_raid_dmux
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

entity sata_raid_dmux is
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
--//Связь с TxFIFO
p_in_usr_txd            : in    std_logic_vector(31 downto 0);
p_out_usr_txd_rd        : out   std_logic;
p_in_usr_txbuf_empty    : in    std_logic;

--//Связь с RxFIFO
p_out_usr_rxd           : out   std_logic_vector(31 downto 0);
p_out_usr_rxd_wr        : out   std_logic;

--------------------------------------------------
--Связь с модулями sata_host.vhd
--------------------------------------------------
p_out_sh_tx_dst_adr     : out   std_logic_vector(2 downto 0);
p_out_sh_txd            : out   std_logic_vector(31 downto 0);
p_out_sh_txd_wr         : out   std_logic;
--p_in_sh_txbuf_full      : in    std_logic;

p_out_sh_rx_src_adr     : out   std_logic_vector(2 downto 0);
p_in_sh_rxd             : in    std_logic_vector(31 downto 0);
p_out_sh_rxd_rd         : out   std_logic;
p_in_sh_rxbuf_empty     : in    std_logic;

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
end sata_raid_dmux;

architecture behavioral of sata_raid_dmux is



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





--------------------------------------------------
--UserTxBUF <-> SataHostTxBUF
--------------------------------------------------
p_out_usr_txd_rd<=not p_in_usr_txbuf_empty;

p_out_sh_txd<=p_in_usr_txd;
p_out_sh_txd_wr<=not p_in_usr_txbuf_empty;

--p_in_sh_txbuf_full      : in    std_logic;

p_out_sh_tx_dst_adr<=p_in_tst(10 downto 8);




--------------------------------------------------
--UserRxBUF <-> SataHostRxBUF
--------------------------------------------------
p_out_usr_rxd<=p_in_sh_rxd;
p_out_usr_rxd_wr<= not p_in_sh_rxbuf_empty;

p_out_sh_rxd_rd<= not p_in_sh_rxbuf_empty;

p_out_sh_rx_src_adr<=p_in_tst(2 downto 0);


--END MAIN
end behavioral;
