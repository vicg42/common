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

library work;
use work.vicg_common_pkg.all;
use work.sata_glob_pkg.all;
use work.sata_pkg.all;
use work.sata_raid_pkg.all;
use work.sata_unit_pkg.all;

entity sata_raid_decoder is
generic(
G_RAID_DWIDTH : integer:=32;
G_HDD_COUNT : integer:=1;    --//Кол-во sata устр-в (min/max - 1/8)
G_DBG       : string :="OFF";
G_SIM       : string :="OFF"
);
port(
--------------------------------------------------
--Связь с модулем dsn_hdd.vhd
--------------------------------------------------
p_out_raid              : out   TRaid;
p_out_sh_num            : out   std_logic_vector(2 downto 0);
p_in_sh_mask            : in    std_logic_vector(G_HDD_COUNT-1 downto 0);
p_in_sh_hdd             : in    std_logic_vector(2 downto 0);
p_in_sh_padding         : in    std_logic;

p_in_usr_cxd            : in    std_logic_vector(15 downto 0);
p_in_usr_cxd_sof_n      : in    std_logic;
p_in_usr_cxd_eof_n      : in    std_logic;
p_in_usr_cxd_src_rdy_n  : in    std_logic;

p_in_usr_txd            : in    std_logic_vector(G_RAID_DWIDTH-1 downto 0);
p_in_usr_txd_wr         : in    std_logic;
p_out_usr_txbuf_full    : out   std_logic;

p_out_usr_rxd           : out   std_logic_vector(G_RAID_DWIDTH-1 downto 0);
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

signal i_sh_rxd_rd     : std_logic_vector(G_HDD_COUNT-1 downto 0);
signal i_sh_txd_wr     : std_logic_vector(G_HDD_COUNT-1 downto 0);
signal i_sh_txbuf_full : std_logic_vector(G_HDD_COUNT-1 downto 0);
signal i_sh_rxbuf_empty: std_logic_vector(G_HDD_COUNT-1 downto 0);

signal tst_hdd_wr      : std_logic_vector(G_HDD_COUNT-1 downto 0);--Активность записи/чтения соотвествующего HDD

--MAIN
begin

--//----------------------------------
--//Технологические сигналы
--//----------------------------------
p_out_tst(7 downto 0)<=(others=>'0');
p_out_tst(15 downto 8)<=EXT(tst_hdd_wr, 8);
p_out_tst(31 downto 16)<=(others=>'0');



--//###################################
--//
--//###################################
gen_hddon : for i in 0 to G_HDD_COUNT-1 generate
tst_hdd_wr(i)<=(p_in_usr_txd_wr or p_in_usr_rxd_rd) and p_in_sh_mask(i);

--//dsn_hdd_cmdbuf -> sh_cmdbuf
p_out_sh_cxd_sof_n(i)    <=p_in_usr_cxd_sof_n     or not p_in_sh_mask(i);
p_out_sh_cxd_eof_n(i)    <=p_in_usr_cxd_eof_n     or not p_in_sh_mask(i);
p_out_sh_cxd_src_rdy_n(i)<=p_in_usr_cxd_src_rdy_n or not p_in_sh_mask(i);
p_out_sh_cxd(i)<=p_in_usr_cxd;

--//dsn_hdd_rxbuf <- sh_rxbuf
p_out_sh_rxd_rd(i)<=(p_in_usr_rxd_rd and p_in_sh_mask(i)) or p_in_sh_padding;

p_out_usr_rxd(32*(i+1)-1 downto 32*i)<=p_in_sh_rxd(i);
i_sh_rxbuf_empty(i)<=p_in_sh_rxbuf_status(i).empty and p_in_sh_mask(i);

--//dsn_hdd_txbuf -> sh_txbuf
process(p_in_rst,p_in_clk)
begin
  if p_in_rst='1' then
    p_out_sh_txd(i)<=(others=>'0');
    i_sh_txbuf_full(i)<='0';
    i_sh_txd_wr(i)<='0';
  elsif p_in_clk'event and p_in_clk='1' then
    p_out_sh_txd(i)<=p_in_usr_txd(32*(i+1)-1 downto 32*i);
    i_sh_txbuf_full(i)<=p_in_sh_txbuf_status(i).pfull and p_in_sh_mask(i);
    if p_in_sh_mask(i)='1' then
      i_sh_txd_wr(i)<=p_in_usr_txd_wr;
    else
      i_sh_txd_wr(i)<='0';
    end if;
  end if;
end process;

p_out_sh_txd_wr(i)<=i_sh_txd_wr(i) or p_in_sh_padding;

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


p_out_usr_txbuf_full<=OR_reduce(i_sh_txbuf_full);
p_out_usr_rxbuf_empty<=OR_reduce(i_sh_rxbuf_empty);

p_out_sh_num<=(others=>'0');

p_out_raid.used<='0';
p_out_raid.hddcount<=CONV_STD_LOGIC_VECTOR(G_HDD_COUNT-1, p_out_raid.hddcount'length);


--END MAIN
end behavioral;
