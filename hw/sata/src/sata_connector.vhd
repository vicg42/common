-------------------------------------------------------------------------
-- Company     : Linkos
-- Engineer    : Golovachenko Victor
--
-- Create Date : 31.03.2011 10:41:13
-- Module Name : sata_connector
--
-- Назначение : Согласующие буфера между модулем SATA_HOST и пользовательскими буферами.
--              ВАЖНО: держим буфера в сбросе пока не установится соединение c HDD (Link Esatblish)
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
use work.sata_unit_pkg.all;

entity sata_connector is
generic(
G_SATAH_CH_COUNT : integer:=1;    --//Кол-во портов SATA используемых в модуле
G_DBG            : string :="OFF";--//
G_SIM            : string :="OFF" --//В боевом проекте обязательно должно быть "OFF" - моделирование
);
port(
--------------------------------------------------
--Связь с модулем sata_raid.vhd
--------------------------------------------------
p_in_uap_clk            : in    std_logic;

--//CMDFIFO
p_in_uap_cxd            : in    TBus16_GTCH;
p_in_uap_cxd_sof_n      : in    std_logic_vector(C_GTCH_COUNT_MAX-1 downto 0);
p_in_uap_cxd_eof_n      : in    std_logic_vector(C_GTCH_COUNT_MAX-1 downto 0);
p_in_uap_cxd_src_rdy_n  : in    std_logic_vector(C_GTCH_COUNT_MAX-1 downto 0);

--//TXFIFO
p_in_uap_txd            : in    TBus32_GTCH;
p_in_uap_txd_wr         : in    std_logic_vector(C_GTCH_COUNT_MAX-1 downto 0);

--//RXFIFO
p_out_uap_rxd           : out   TBus32_GTCH;
p_in_uap_rxd_rd         : in    std_logic_vector(C_GTCH_COUNT_MAX-1 downto 0);

--------------------------------------------------
--Связь с модулем sata_host.vhd
--------------------------------------------------
p_in_sh_clk             : in    std_logic_vector(C_GTCH_COUNT_MAX-1 downto 0);

--//CMDFIFO
p_out_sh_cxd            : out   TBus16_GTCH;
p_out_sh_cxd_eof_n      : out   std_logic_vector(C_GTCH_COUNT_MAX-1 downto 0);
p_out_sh_cxd_src_rdy_n  : out   std_logic_vector(C_GTCH_COUNT_MAX-1 downto 0);

--//TXFIFO
p_out_sh_txd            : out   TBus32_GTCH;
p_in_sh_txd_rd          : in    std_logic_vector(C_GTCH_COUNT_MAX-1 downto 0);

--//RXFIFO
p_in_sh_rxd             : in    TBus32_GTCH;
p_in_sh_rxd_wr          : in    std_logic_vector(C_GTCH_COUNT_MAX-1 downto 0);

--------------------------------------------------
--//Статусы
--------------------------------------------------
p_out_txbuf_status      : out   TTxBufStatus_GTCH;
p_out_rxbuf_status      : out   TRxBufStatus_GTCH;

--------------------------------------------------
--Технологические сигналы
--------------------------------------------------
p_in_tst                : in    std_logic_vector(31 downto 0);
p_out_tst               : out   std_logic_vector(31 downto 0);

--------------------------------------------------
--System
--------------------------------------------------
p_in_rst                : in    std_logic_vector(C_GTCH_COUNT_MAX-1 downto 0)
);
end sata_connector;

architecture behavioral of sata_connector is

signal i_txbuf_wrcount         : TBus04_GTCH;
signal i_txbuf_empty           : std_logic_vector(G_SATAH_CH_COUNT-1 downto 0);
signal i_cmdbuf_empty          : std_logic_vector(G_SATAH_CH_COUNT-1 downto 0);
signal i_cmdbuf_wr             : std_logic_vector(G_SATAH_CH_COUNT-1 downto 0);
signal i_cmdbuf_rd             : std_logic_vector(G_SATAH_CH_COUNT-1 downto 0);

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



gen_ch0_only : if C_GTCH_COUNT_MAX=2 and G_SATAH_CH_COUNT=1 generate
p_out_uap_rxd(C_GTCH_COUNT_MAX-1)<=(others=>'0');

--//CMDFIFO
p_out_sh_cxd(C_GTCH_COUNT_MAX-1)<=(others=>'0');
p_out_sh_cxd_eof_n(C_GTCH_COUNT_MAX-1)<='0';
p_out_sh_cxd_src_rdy_n(C_GTCH_COUNT_MAX-1)<='0';

--//TXFIFO
p_out_sh_txd(C_GTCH_COUNT_MAX-1)<=(others=>'0');

--//Статусы
p_out_txbuf_status(C_GTCH_COUNT_MAX-1).full<='0';
p_out_txbuf_status(C_GTCH_COUNT_MAX-1).pfull<='0';
p_out_txbuf_status(C_GTCH_COUNT_MAX-1).empty<='0';
p_out_txbuf_status(C_GTCH_COUNT_MAX-1).aempty<='0';

p_out_rxbuf_status(C_GTCH_COUNT_MAX-1).full<='0';
p_out_rxbuf_status(C_GTCH_COUNT_MAX-1).pfull<='0';
p_out_rxbuf_status(C_GTCH_COUNT_MAX-1).empty<='0';

end generate gen_ch0_only;


gen_ch : for i in 0 to G_SATAH_CH_COUNT-1 generate

--//----------------------------
--//Согласующие буфера:
--//----------------------------
p_out_sh_cxd_src_rdy_n(i)<=i_cmdbuf_empty(i);
i_cmdbuf_wr(i)<=not p_in_uap_cxd_src_rdy_n(i);
i_cmdbuf_rd(i)<=not i_cmdbuf_empty(i);

m_cmdbuf : sata_cmdfifo
port map(
din         => p_in_uap_cxd(i),
wr_en       => i_cmdbuf_wr(i),
wr_clk      => p_in_uap_clk,

dout        => p_out_sh_cxd(i),
rd_en       => i_cmdbuf_rd(i),
rd_clk      => p_in_sh_clk(i),

full        => open,
empty       => i_cmdbuf_empty(i),

rst         => p_in_rst(i)
);

m_txbuf : sata_txfifo
port map(
din        => p_in_uap_txd(i),
wr_en      => p_in_uap_txd_wr(i),
wr_clk     => p_in_uap_clk,

dout       => p_out_sh_txd(i),
rd_en      => p_in_sh_txd_rd(i),
rd_clk     => p_in_sh_clk(i),

full        => p_out_txbuf_status(i).full,
prog_full   => open,--p_out_txbuf_status(i).pfull,
almost_full => open,--p_out_txbuf_status(i).pfull,
empty       => i_txbuf_empty(i),--p_out_txbuf_status(i).empty,
almost_empty=> p_out_txbuf_status(i).aempty,
rd_data_count => p_out_txbuf_status(i).rdcount,
wr_data_count => i_txbuf_wrcount(i),--p_out_txbuf_status(i).wrcount,

rst        => p_in_rst(i)
);

process(p_in_rst(i),p_in_uap_clk)
begin
  if p_in_rst(i)='1' then
    p_out_txbuf_status(i).pfull<='0';
  elsif p_in_uap_clk'event and p_in_uap_clk='1' then
    if i_txbuf_wrcount(i)>="1101" then
    p_out_txbuf_status(i).pfull<='1';
    elsif i_txbuf_wrcount(i)<="0111" then --elsif i_txbuf_wrcount(i)<"1101" then --
    p_out_txbuf_status(i).pfull<='0';
    end if;
  end if;
end process;
p_out_txbuf_status(i).empty<=i_txbuf_empty(i);

m_rxbuf : sata_rxfifo
port map(
din        => p_in_sh_rxd(i),
wr_en      => p_in_sh_rxd_wr(i),
wr_clk     => p_in_sh_clk(i),

dout       => p_out_uap_rxd(i),
rd_en      => p_in_uap_rxd_rd(i),
rd_clk     => p_in_uap_clk,

full        => p_out_rxbuf_status(i).full,
prog_full   => p_out_rxbuf_status(i).pfull,
--almost_full => i_txbuf_afull(0),
empty       => p_out_rxbuf_status(i).empty,
--almost_empty=> i_rxbuf_aempty(0),
wr_data_count => p_out_rxbuf_status(i).wrcount,

rst        => p_in_rst(i)
);


end generate gen_ch;

--END MAIN
end behavioral;
