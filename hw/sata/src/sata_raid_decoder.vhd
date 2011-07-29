-------------------------------------------------------------------------
-- Company     : Linkos
-- Engineer    : Golovachenko Victor
--
-- Create Date : 02.04.2011 9:49:46
-- Module Name : sata_raid_decoder
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

library work;
use work.vicg_common_pkg.all;
use work.sata_glob_pkg.all;
use work.sata_pkg.all;
use work.sata_raid_pkg.all;
use work.sata_unit_pkg.all;

entity sata_raid_decoder is
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
p_out_raid              : out   TRaid;
p_out_sh_num            : out   std_logic_vector(2 downto 0);
p_in_sh_mask            : in    std_logic_vector(G_HDD_COUNT-1 downto 0);

p_in_usr_cxd            : in    std_logic_vector(15 downto 0);
p_in_usr_cxd_sof_n      : in    std_logic;
p_in_usr_cxd_eof_n      : in    std_logic;
p_in_usr_cxd_src_rdy_n  : in    std_logic;

p_in_sh_hdd             : in    std_logic_vector(2 downto 0);

p_in_usr_txd            : in    std_logic_vector(31 downto 0);
p_in_usr_txd_wr         : in    std_logic;
p_out_usr_txbuf_full    : out   std_logic;

p_out_usr_rxd           : out   std_logic_vector(31 downto 0);
p_in_usr_rxd_rd         : in    std_logic;
p_out_usr_rxbuf_empty   : out   std_logic;


--------------------------------------------------
--Связь с модулями sata_host.vhd
--------------------------------------------------
p_out_sh_cxd            : out   TBus16_SHCountMax;
p_out_sh_cxd_sof_n      : out   std_logic_vector(C_HDD_COUNT_MAX-1 downto 0);
p_out_sh_cxd_eof_n      : out   std_logic_vector(C_HDD_COUNT_MAX-1 downto 0);
p_out_sh_cxd_src_rdy_n  : out   std_logic_vector(C_HDD_COUNT_MAX-1 downto 0);

p_out_sh_txd            : out   TBus32_SHCountMax;
p_out_sh_txd_wr         : out   std_logic_vector(C_HDD_COUNT_MAX-1 downto 0);

p_in_sh_rxd             : in    TBus32_SHCountMax;
p_out_sh_rxd_rd         : out   std_logic_vector(C_HDD_COUNT_MAX-1 downto 0);

p_in_sh_txbuf_status    : in    TTxBufStatus_SHCountMax;
p_in_sh_rxbuf_status    : in    TRxBufStatus_SHCountMax;

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
end sata_raid_decoder;

architecture behavioral of sata_raid_decoder is



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



--//###################################
--//
--//###################################
gen_hddon : for i in 0 to G_HDD_COUNT-1 generate
--//используемые HDD:
--//Передача командного пакета
p_out_sh_cxd_sof_n(i)<=p_in_usr_cxd_sof_n when p_in_sh_mask(i)='1' else '1';
p_out_sh_cxd_eof_n(i)<=p_in_usr_cxd_eof_n when p_in_sh_mask(i)='1' else '1';
p_out_sh_cxd_src_rdy_n(i)<=p_in_usr_cxd_src_rdy_n when p_in_sh_mask(i)='1' else '1';
p_out_sh_cxd(i)<=p_in_usr_cxd;

--//Чтение из RxBUF
p_out_sh_rxd_rd(i)<=p_in_usr_rxd_rd when p_in_sh_hdd=CONV_STD_LOGIC_VECTOR(i, p_in_sh_hdd'length) else '0';

--//запись d TxBUF
process(p_in_rst,p_in_clk)
begin
  if p_in_rst='1' then
    p_out_sh_txd(i)<=(others=>'0');
    p_out_sh_txd_wr(i)<='0';
  elsif p_in_clk'event and p_in_clk='1' then
    p_out_sh_txd(i)<=p_in_usr_txd;
    if p_in_sh_hdd=CONV_STD_LOGIC_VECTOR(i, p_in_sh_hdd'length) then
      p_out_sh_txd_wr(i)<=p_in_usr_txd_wr;
    else
      p_out_sh_txd_wr(i)<='0';
    end if;
  end if;
end process;

end generate gen_hddon;

gen_hddoff_en : if G_HDD_COUNT/=C_HDD_COUNT_MAX  generate
--//НЕ используемые HDD:
gen_hddoff : for i in G_HDD_COUNT to C_HDD_COUNT_MAX-1 generate
p_out_sh_cxd_sof_n(i)<='1';
p_out_sh_cxd_eof_n(i)<='1';
p_out_sh_cxd_src_rdy_n(i)<='1';
p_out_sh_cxd(i)<=(others=>'0');
p_out_sh_rxd_rd(i)<='0';
p_out_sh_txd(i)<=(others=>'0');
p_out_sh_txd_wr(i)<='0';
end generate gen_hddoff;
end generate gen_hddoff_en;



--//###################################
--//
--//###################################
--//----------------------------------
--//RAID params
--//----------------------------------
gen_raidon : if G_HDD_COUNT>1  generate
p_out_raid.used<=AND_reduce(p_in_sh_mask(G_HDD_COUNT-1 downto 0));
p_out_raid.hddcount<=CONV_STD_LOGIC_VECTOR(G_HDD_COUNT-1, p_out_raid.hddcount'length);
end generate gen_raidon;


--//----------------------------------
--//HDDCOUNT=1
--//----------------------------------
gen_hddcount1 : if G_HDD_COUNT=1  generate
p_out_usr_txbuf_full<=p_in_sh_txbuf_status(0).pfull when p_in_sh_hdd=CONV_STD_LOGIC_VECTOR(16#00#, p_in_sh_hdd'length) else '1';

p_out_usr_rxbuf_empty<=p_in_sh_rxbuf_status(0).empty;
p_out_usr_rxd<=p_in_sh_rxd(0);

p_out_sh_num<=CONV_STD_LOGIC_VECTOR(16#00#, p_out_sh_num'length);
p_out_raid.used<='0';
p_out_raid.hddcount<=(others=>'0');
end generate gen_hddcount1;


--//----------------------------------
--//HDDCOUNT=2
--//----------------------------------
gen_hddcount2 : if G_HDD_COUNT=2  generate
p_out_usr_txbuf_full<=p_in_sh_txbuf_status(0).pfull when p_in_sh_hdd=CONV_STD_LOGIC_VECTOR(16#00#, p_in_sh_hdd'length) else
                      p_in_sh_txbuf_status(1).pfull;

p_out_usr_rxbuf_empty<=p_in_sh_rxbuf_status(0).empty when p_in_sh_hdd=CONV_STD_LOGIC_VECTOR(16#00#, p_in_sh_hdd'length) else
                       p_in_sh_rxbuf_status(1).empty;

p_out_usr_rxd<=p_in_sh_rxd(0) when p_in_sh_hdd=CONV_STD_LOGIC_VECTOR(16#00#, p_in_sh_hdd'length) else
               p_in_sh_rxd(1);

p_out_sh_num<=CONV_STD_LOGIC_VECTOR(16#00#, p_out_sh_num'length) when p_in_sh_mask=CONV_STD_LOGIC_VECTOR(16#01#, p_in_sh_mask'length) else
              CONV_STD_LOGIC_VECTOR(16#01#, p_out_sh_num'length);

end generate gen_hddcount2;


--//----------------------------------
--//HDDCOUNT=3
--//----------------------------------
gen_hddcount3 : if G_HDD_COUNT=3  generate
p_out_usr_txbuf_full<=p_in_sh_txbuf_status(0).pfull when p_in_sh_hdd=CONV_STD_LOGIC_VECTOR(16#00#, p_in_sh_hdd'length) else
                      p_in_sh_txbuf_status(1).pfull when p_in_sh_hdd=CONV_STD_LOGIC_VECTOR(16#01#, p_in_sh_hdd'length) else
                      p_in_sh_txbuf_status(2).pfull;

p_out_usr_rxbuf_empty<=p_in_sh_rxbuf_status(0).empty when p_in_sh_hdd=CONV_STD_LOGIC_VECTOR(16#00#, p_in_sh_hdd'length) else
                       p_in_sh_rxbuf_status(1).empty when p_in_sh_hdd=CONV_STD_LOGIC_VECTOR(16#01#, p_in_sh_hdd'length) else
                       p_in_sh_rxbuf_status(2).empty;

p_out_usr_rxd<=p_in_sh_rxd(0) when p_in_sh_hdd=CONV_STD_LOGIC_VECTOR(16#00#, p_in_sh_hdd'length) else
               p_in_sh_rxd(1) when p_in_sh_hdd=CONV_STD_LOGIC_VECTOR(16#01#, p_in_sh_hdd'length) else
               p_in_sh_rxd(2);

p_out_sh_num<=CONV_STD_LOGIC_VECTOR(16#00#, p_out_sh_num'length) when p_in_sh_mask=CONV_STD_LOGIC_VECTOR(16#01#, p_in_sh_mask'length) else
              CONV_STD_LOGIC_VECTOR(16#01#, p_out_sh_num'length) when p_in_sh_mask=CONV_STD_LOGIC_VECTOR(16#02#, p_in_sh_mask'length) else
              CONV_STD_LOGIC_VECTOR(16#02#, p_out_sh_num'length);

end generate gen_hddcount3;


--//----------------------------------
--//HDDCOUNT=4
--//----------------------------------
gen_hddcount4 : if G_HDD_COUNT=4  generate
p_out_usr_txbuf_full<=p_in_sh_txbuf_status(0).pfull when p_in_sh_hdd=CONV_STD_LOGIC_VECTOR(16#00#, p_in_sh_hdd'length) else
                      p_in_sh_txbuf_status(1).pfull when p_in_sh_hdd=CONV_STD_LOGIC_VECTOR(16#01#, p_in_sh_hdd'length) else
                      p_in_sh_txbuf_status(2).pfull when p_in_sh_hdd=CONV_STD_LOGIC_VECTOR(16#02#, p_in_sh_hdd'length) else
                      p_in_sh_txbuf_status(3).pfull;

p_out_usr_rxbuf_empty<=p_in_sh_rxbuf_status(0).empty when p_in_sh_hdd=CONV_STD_LOGIC_VECTOR(16#00#, p_in_sh_hdd'length) else
                       p_in_sh_rxbuf_status(1).empty when p_in_sh_hdd=CONV_STD_LOGIC_VECTOR(16#01#, p_in_sh_hdd'length) else
                       p_in_sh_rxbuf_status(2).empty when p_in_sh_hdd=CONV_STD_LOGIC_VECTOR(16#02#, p_in_sh_hdd'length) else
                       p_in_sh_rxbuf_status(3).empty;

p_out_usr_rxd<=p_in_sh_rxd(0) when p_in_sh_hdd=CONV_STD_LOGIC_VECTOR(16#00#, p_in_sh_hdd'length) else
               p_in_sh_rxd(1) when p_in_sh_hdd=CONV_STD_LOGIC_VECTOR(16#01#, p_in_sh_hdd'length) else
               p_in_sh_rxd(2) when p_in_sh_hdd=CONV_STD_LOGIC_VECTOR(16#02#, p_in_sh_hdd'length) else
               p_in_sh_rxd(3);

p_out_sh_num<=CONV_STD_LOGIC_VECTOR(16#00#, p_out_sh_num'length) when p_in_sh_mask=CONV_STD_LOGIC_VECTOR(16#01#, p_in_sh_mask'length) else
              CONV_STD_LOGIC_VECTOR(16#01#, p_out_sh_num'length) when p_in_sh_mask=CONV_STD_LOGIC_VECTOR(16#02#, p_in_sh_mask'length) else
              CONV_STD_LOGIC_VECTOR(16#02#, p_out_sh_num'length) when p_in_sh_mask=CONV_STD_LOGIC_VECTOR(16#04#, p_in_sh_mask'length) else
              CONV_STD_LOGIC_VECTOR(16#03#, p_out_sh_num'length);

end generate gen_hddcount4;


--//----------------------------------
--//HDDCOUNT=5
--//----------------------------------
gen_hddcount5 : if G_HDD_COUNT=5  generate
p_out_usr_txbuf_full<=p_in_sh_txbuf_status(0).pfull when p_in_sh_hdd=CONV_STD_LOGIC_VECTOR(16#00#, p_in_sh_hdd'length) else
                      p_in_sh_txbuf_status(1).pfull when p_in_sh_hdd=CONV_STD_LOGIC_VECTOR(16#01#, p_in_sh_hdd'length) else
                      p_in_sh_txbuf_status(2).pfull when p_in_sh_hdd=CONV_STD_LOGIC_VECTOR(16#02#, p_in_sh_hdd'length) else
                      p_in_sh_txbuf_status(3).pfull when p_in_sh_hdd=CONV_STD_LOGIC_VECTOR(16#03#, p_in_sh_hdd'length) else
                      p_in_sh_txbuf_status(4).pfull;

p_out_usr_rxbuf_empty<=p_in_sh_rxbuf_status(0).empty when p_in_sh_hdd=CONV_STD_LOGIC_VECTOR(16#00#, p_in_sh_hdd'length) else
                       p_in_sh_rxbuf_status(1).empty when p_in_sh_hdd=CONV_STD_LOGIC_VECTOR(16#01#, p_in_sh_hdd'length) else
                       p_in_sh_rxbuf_status(2).empty when p_in_sh_hdd=CONV_STD_LOGIC_VECTOR(16#02#, p_in_sh_hdd'length) else
                       p_in_sh_rxbuf_status(3).empty when p_in_sh_hdd=CONV_STD_LOGIC_VECTOR(16#03#, p_in_sh_hdd'length) else
                       p_in_sh_rxbuf_status(4).empty;

p_out_usr_rxd<=p_in_sh_rxd(0) when p_in_sh_hdd=CONV_STD_LOGIC_VECTOR(16#00#, p_in_sh_hdd'length) else
               p_in_sh_rxd(1) when p_in_sh_hdd=CONV_STD_LOGIC_VECTOR(16#01#, p_in_sh_hdd'length) else
               p_in_sh_rxd(2) when p_in_sh_hdd=CONV_STD_LOGIC_VECTOR(16#02#, p_in_sh_hdd'length) else
               p_in_sh_rxd(3) when p_in_sh_hdd=CONV_STD_LOGIC_VECTOR(16#03#, p_in_sh_hdd'length) else
               p_in_sh_rxd(4);


p_out_sh_num<=CONV_STD_LOGIC_VECTOR(16#00#, p_out_sh_num'length) when p_in_sh_mask=CONV_STD_LOGIC_VECTOR(16#01#, p_in_sh_mask'length) else
              CONV_STD_LOGIC_VECTOR(16#01#, p_out_sh_num'length) when p_in_sh_mask=CONV_STD_LOGIC_VECTOR(16#02#, p_in_sh_mask'length) else
              CONV_STD_LOGIC_VECTOR(16#02#, p_out_sh_num'length) when p_in_sh_mask=CONV_STD_LOGIC_VECTOR(16#04#, p_in_sh_mask'length) else
              CONV_STD_LOGIC_VECTOR(16#03#, p_out_sh_num'length) when p_in_sh_mask=CONV_STD_LOGIC_VECTOR(16#08#, p_in_sh_mask'length) else
              CONV_STD_LOGIC_VECTOR(16#04#, p_out_sh_num'length);

end generate gen_hddcount5;


--//----------------------------------
--//HDDCOUNT=6
--//----------------------------------
gen_hddcount6 : if G_HDD_COUNT=6  generate
p_out_usr_txbuf_full<=p_in_sh_txbuf_status(0).pfull when p_in_sh_hdd=CONV_STD_LOGIC_VECTOR(16#00#, p_in_sh_hdd'length) else
                      p_in_sh_txbuf_status(1).pfull when p_in_sh_hdd=CONV_STD_LOGIC_VECTOR(16#01#, p_in_sh_hdd'length) else
                      p_in_sh_txbuf_status(2).pfull when p_in_sh_hdd=CONV_STD_LOGIC_VECTOR(16#02#, p_in_sh_hdd'length) else
                      p_in_sh_txbuf_status(3).pfull when p_in_sh_hdd=CONV_STD_LOGIC_VECTOR(16#03#, p_in_sh_hdd'length) else
                      p_in_sh_txbuf_status(4).pfull when p_in_sh_hdd=CONV_STD_LOGIC_VECTOR(16#04#, p_in_sh_hdd'length) else
                      p_in_sh_txbuf_status(5).pfull;

p_out_usr_rxbuf_empty<=p_in_sh_rxbuf_status(0).empty when p_in_sh_hdd=CONV_STD_LOGIC_VECTOR(16#00#, p_in_sh_hdd'length) else
                       p_in_sh_rxbuf_status(1).empty when p_in_sh_hdd=CONV_STD_LOGIC_VECTOR(16#01#, p_in_sh_hdd'length) else
                       p_in_sh_rxbuf_status(2).empty when p_in_sh_hdd=CONV_STD_LOGIC_VECTOR(16#02#, p_in_sh_hdd'length) else
                       p_in_sh_rxbuf_status(3).empty when p_in_sh_hdd=CONV_STD_LOGIC_VECTOR(16#03#, p_in_sh_hdd'length) else
                       p_in_sh_rxbuf_status(4).empty when p_in_sh_hdd=CONV_STD_LOGIC_VECTOR(16#04#, p_in_sh_hdd'length) else
                       p_in_sh_rxbuf_status(5).empty;

p_out_usr_rxd<=p_in_sh_rxd(0) when p_in_sh_hdd=CONV_STD_LOGIC_VECTOR(16#00#, p_in_sh_hdd'length) else
               p_in_sh_rxd(1) when p_in_sh_hdd=CONV_STD_LOGIC_VECTOR(16#01#, p_in_sh_hdd'length) else
               p_in_sh_rxd(2) when p_in_sh_hdd=CONV_STD_LOGIC_VECTOR(16#02#, p_in_sh_hdd'length) else
               p_in_sh_rxd(3) when p_in_sh_hdd=CONV_STD_LOGIC_VECTOR(16#03#, p_in_sh_hdd'length) else
               p_in_sh_rxd(4) when p_in_sh_hdd=CONV_STD_LOGIC_VECTOR(16#04#, p_in_sh_hdd'length) else
               p_in_sh_rxd(5);

p_out_sh_num<=CONV_STD_LOGIC_VECTOR(16#00#, p_out_sh_num'length) when p_in_sh_mask=CONV_STD_LOGIC_VECTOR(16#01#, p_in_sh_mask'length) else
              CONV_STD_LOGIC_VECTOR(16#01#, p_out_sh_num'length) when p_in_sh_mask=CONV_STD_LOGIC_VECTOR(16#02#, p_in_sh_mask'length) else
              CONV_STD_LOGIC_VECTOR(16#02#, p_out_sh_num'length) when p_in_sh_mask=CONV_STD_LOGIC_VECTOR(16#04#, p_in_sh_mask'length) else
              CONV_STD_LOGIC_VECTOR(16#03#, p_out_sh_num'length) when p_in_sh_mask=CONV_STD_LOGIC_VECTOR(16#08#, p_in_sh_mask'length) else
              CONV_STD_LOGIC_VECTOR(16#04#, p_out_sh_num'length) when p_in_sh_mask=CONV_STD_LOGIC_VECTOR(16#16#, p_in_sh_mask'length) else
              CONV_STD_LOGIC_VECTOR(16#05#, p_out_sh_num'length);

end generate gen_hddcount6;


--//----------------------------------
--//HDDCOUNT=7
--//----------------------------------
gen_hddcount7 : if G_HDD_COUNT=7  generate
p_out_usr_txbuf_full<=p_in_sh_txbuf_status(0).pfull when p_in_sh_hdd=CONV_STD_LOGIC_VECTOR(16#00#, p_in_sh_hdd'length) else
                      p_in_sh_txbuf_status(1).pfull when p_in_sh_hdd=CONV_STD_LOGIC_VECTOR(16#01#, p_in_sh_hdd'length) else
                      p_in_sh_txbuf_status(2).pfull when p_in_sh_hdd=CONV_STD_LOGIC_VECTOR(16#02#, p_in_sh_hdd'length) else
                      p_in_sh_txbuf_status(3).pfull when p_in_sh_hdd=CONV_STD_LOGIC_VECTOR(16#03#, p_in_sh_hdd'length) else
                      p_in_sh_txbuf_status(4).pfull when p_in_sh_hdd=CONV_STD_LOGIC_VECTOR(16#04#, p_in_sh_hdd'length) else
                      p_in_sh_txbuf_status(5).pfull when p_in_sh_hdd=CONV_STD_LOGIC_VECTOR(16#05#, p_in_sh_hdd'length) else
                      p_in_sh_txbuf_status(6).pfull;

p_out_usr_rxbuf_empty<=p_in_sh_rxbuf_status(0).empty when p_in_sh_hdd=CONV_STD_LOGIC_VECTOR(16#00#, p_in_sh_hdd'length) else
                       p_in_sh_rxbuf_status(1).empty when p_in_sh_hdd=CONV_STD_LOGIC_VECTOR(16#01#, p_in_sh_hdd'length) else
                       p_in_sh_rxbuf_status(2).empty when p_in_sh_hdd=CONV_STD_LOGIC_VECTOR(16#02#, p_in_sh_hdd'length) else
                       p_in_sh_rxbuf_status(3).empty when p_in_sh_hdd=CONV_STD_LOGIC_VECTOR(16#03#, p_in_sh_hdd'length) else
                       p_in_sh_rxbuf_status(4).empty when p_in_sh_hdd=CONV_STD_LOGIC_VECTOR(16#04#, p_in_sh_hdd'length) else
                       p_in_sh_rxbuf_status(5).empty when p_in_sh_hdd=CONV_STD_LOGIC_VECTOR(16#05#, p_in_sh_hdd'length) else
                       p_in_sh_rxbuf_status(6).empty;

p_out_usr_rxd<=p_in_sh_rxd(0) when p_in_sh_hdd=CONV_STD_LOGIC_VECTOR(16#00#, p_in_sh_hdd'length) else
               p_in_sh_rxd(1) when p_in_sh_hdd=CONV_STD_LOGIC_VECTOR(16#01#, p_in_sh_hdd'length) else
               p_in_sh_rxd(2) when p_in_sh_hdd=CONV_STD_LOGIC_VECTOR(16#02#, p_in_sh_hdd'length) else
               p_in_sh_rxd(3) when p_in_sh_hdd=CONV_STD_LOGIC_VECTOR(16#03#, p_in_sh_hdd'length) else
               p_in_sh_rxd(4) when p_in_sh_hdd=CONV_STD_LOGIC_VECTOR(16#04#, p_in_sh_hdd'length) else
               p_in_sh_rxd(5) when p_in_sh_hdd=CONV_STD_LOGIC_VECTOR(16#05#, p_in_sh_hdd'length) else
               p_in_sh_rxd(6);

p_out_sh_num<=CONV_STD_LOGIC_VECTOR(16#00#, p_out_sh_num'length) when p_in_sh_mask=CONV_STD_LOGIC_VECTOR(16#01#, p_in_sh_mask'length) else
              CONV_STD_LOGIC_VECTOR(16#01#, p_out_sh_num'length) when p_in_sh_mask=CONV_STD_LOGIC_VECTOR(16#02#, p_in_sh_mask'length) else
              CONV_STD_LOGIC_VECTOR(16#02#, p_out_sh_num'length) when p_in_sh_mask=CONV_STD_LOGIC_VECTOR(16#04#, p_in_sh_mask'length) else
              CONV_STD_LOGIC_VECTOR(16#03#, p_out_sh_num'length) when p_in_sh_mask=CONV_STD_LOGIC_VECTOR(16#08#, p_in_sh_mask'length) else
              CONV_STD_LOGIC_VECTOR(16#04#, p_out_sh_num'length) when p_in_sh_mask=CONV_STD_LOGIC_VECTOR(16#16#, p_in_sh_mask'length) else
              CONV_STD_LOGIC_VECTOR(16#05#, p_out_sh_num'length) when p_in_sh_mask=CONV_STD_LOGIC_VECTOR(16#20#, p_in_sh_mask'length) else
              CONV_STD_LOGIC_VECTOR(16#06#, p_out_sh_num'length);

end generate gen_hddcount7;


--//----------------------------------
--//HDDCOUNT=8
--//----------------------------------
gen_hddcount8 : if G_HDD_COUNT=8  generate
p_out_usr_txbuf_full<=p_in_sh_txbuf_status(0).pfull when p_in_sh_hdd=CONV_STD_LOGIC_VECTOR(16#00#, p_in_sh_hdd'length) else
                      p_in_sh_txbuf_status(1).pfull when p_in_sh_hdd=CONV_STD_LOGIC_VECTOR(16#01#, p_in_sh_hdd'length) else
                      p_in_sh_txbuf_status(2).pfull when p_in_sh_hdd=CONV_STD_LOGIC_VECTOR(16#02#, p_in_sh_hdd'length) else
                      p_in_sh_txbuf_status(3).pfull when p_in_sh_hdd=CONV_STD_LOGIC_VECTOR(16#03#, p_in_sh_hdd'length) else
                      p_in_sh_txbuf_status(4).pfull when p_in_sh_hdd=CONV_STD_LOGIC_VECTOR(16#04#, p_in_sh_hdd'length) else
                      p_in_sh_txbuf_status(5).pfull when p_in_sh_hdd=CONV_STD_LOGIC_VECTOR(16#05#, p_in_sh_hdd'length) else
                      p_in_sh_txbuf_status(6).pfull when p_in_sh_hdd=CONV_STD_LOGIC_VECTOR(16#06#, p_in_sh_hdd'length) else
                      p_in_sh_txbuf_status(7).pfull;

p_out_usr_rxbuf_empty<=p_in_sh_rxbuf_status(0).empty when p_in_sh_hdd=CONV_STD_LOGIC_VECTOR(16#00#, p_in_sh_hdd'length) else
                       p_in_sh_rxbuf_status(1).empty when p_in_sh_hdd=CONV_STD_LOGIC_VECTOR(16#01#, p_in_sh_hdd'length) else
                       p_in_sh_rxbuf_status(2).empty when p_in_sh_hdd=CONV_STD_LOGIC_VECTOR(16#02#, p_in_sh_hdd'length) else
                       p_in_sh_rxbuf_status(3).empty when p_in_sh_hdd=CONV_STD_LOGIC_VECTOR(16#03#, p_in_sh_hdd'length) else
                       p_in_sh_rxbuf_status(4).empty when p_in_sh_hdd=CONV_STD_LOGIC_VECTOR(16#04#, p_in_sh_hdd'length) else
                       p_in_sh_rxbuf_status(5).empty when p_in_sh_hdd=CONV_STD_LOGIC_VECTOR(16#05#, p_in_sh_hdd'length) else
                       p_in_sh_rxbuf_status(6).empty when p_in_sh_hdd=CONV_STD_LOGIC_VECTOR(16#06#, p_in_sh_hdd'length) else
                       p_in_sh_rxbuf_status(7).empty;

p_out_usr_rxd<=p_in_sh_rxd(0) when p_in_sh_hdd=CONV_STD_LOGIC_VECTOR(16#00#, p_in_sh_hdd'length) else
               p_in_sh_rxd(1) when p_in_sh_hdd=CONV_STD_LOGIC_VECTOR(16#01#, p_in_sh_hdd'length) else
               p_in_sh_rxd(2) when p_in_sh_hdd=CONV_STD_LOGIC_VECTOR(16#02#, p_in_sh_hdd'length) else
               p_in_sh_rxd(3) when p_in_sh_hdd=CONV_STD_LOGIC_VECTOR(16#03#, p_in_sh_hdd'length) else
               p_in_sh_rxd(4) when p_in_sh_hdd=CONV_STD_LOGIC_VECTOR(16#04#, p_in_sh_hdd'length) else
               p_in_sh_rxd(5) when p_in_sh_hdd=CONV_STD_LOGIC_VECTOR(16#05#, p_in_sh_hdd'length) else
               p_in_sh_rxd(6) when p_in_sh_hdd=CONV_STD_LOGIC_VECTOR(16#06#, p_in_sh_hdd'length) else
               p_in_sh_rxd(7);

p_out_sh_num<=CONV_STD_LOGIC_VECTOR(16#00#, p_out_sh_num'length) when p_in_sh_mask=CONV_STD_LOGIC_VECTOR(16#01#, p_in_sh_mask'length) else
              CONV_STD_LOGIC_VECTOR(16#01#, p_out_sh_num'length) when p_in_sh_mask=CONV_STD_LOGIC_VECTOR(16#02#, p_in_sh_mask'length) else
              CONV_STD_LOGIC_VECTOR(16#02#, p_out_sh_num'length) when p_in_sh_mask=CONV_STD_LOGIC_VECTOR(16#04#, p_in_sh_mask'length) else
              CONV_STD_LOGIC_VECTOR(16#03#, p_out_sh_num'length) when p_in_sh_mask=CONV_STD_LOGIC_VECTOR(16#08#, p_in_sh_mask'length) else
              CONV_STD_LOGIC_VECTOR(16#04#, p_out_sh_num'length) when p_in_sh_mask=CONV_STD_LOGIC_VECTOR(16#16#, p_in_sh_mask'length) else
              CONV_STD_LOGIC_VECTOR(16#05#, p_out_sh_num'length) when p_in_sh_mask=CONV_STD_LOGIC_VECTOR(16#20#, p_in_sh_mask'length) else
              CONV_STD_LOGIC_VECTOR(16#06#, p_out_sh_num'length) when p_in_sh_mask=CONV_STD_LOGIC_VECTOR(16#40#, p_in_sh_mask'length) else
              CONV_STD_LOGIC_VECTOR(16#07#, p_out_sh_num'length);

end generate gen_hddcount8;

--END MAIN
end behavioral;
