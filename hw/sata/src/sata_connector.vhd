-------------------------------------------------------------------------
-- Company     : Linkos
-- Engineer    : Golovachenko Victor
--
-- Create Date : 31.03.2011 10:41:13
-- Module Name : sata_connector
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

entity sata_connector is
generic
(
G_SATAH_CH_COUNT : integer:=1;    --//Кол-во портов SATA используемых в модуле
G_DBG            : string :="OFF";--//
G_SIM            : string :="OFF" --//В боевом проекте обязательно должно быть "OFF" - моделирование
);
port
(
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
p_in_sh_status          : in    TALStatus_GTCH;

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
p_in_rst                : in    std_logic
);
end sata_connector;

architecture behavioral of sata_connector is

signal i_buf_rst              : std_logic_vector(C_GTCH_COUNT_MAX-1 downto 0);

--MAIN
begin

--//----------------------------------
--//Технологические сигналы
--//----------------------------------
gen_dbg_off : if strcmp(G_DBG,"OFF") generate
p_out_tst(31 downto 0)<=(others=>'0');
end generate gen_dbg_off;

gen_dbg_on : if strcmp(G_DBG,"ON") generate
--ltstout:process(p_in_rst,p_in_uap_clk)
--begin
--  if p_in_rst='1' then
--    tst_fms_cs_dly<=(others=>'0');
--    p_out_tst(31 downto 1)<=(others=>'0');
--  elsif p_in_uap_clk'event and p_in_uap_clk='1' then
--
--    tst_fms_cs_dly<=tst_fms_cs;
--    p_out_tst(0)<=OR_reduce(tst_fms_cs_dly);
--  end if;
--end process ltstout;
p_out_tst(31 downto 0)<=(others=>'0');
end generate gen_dbg_on;



gen_ch0_only : if C_GTCH_COUNT_MAX=2 and G_SATAH_CH_COUNT=1 generate
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

i_buf_rst(i)<=not p_in_sh_status(i).SStatus(C_ASSTAT_DET_BIT_L+1);--//Link Establish

--//----------------------------
--//Согласующие буфера:
--//----------------------------
m_cmdbuf : ll_fifo
generic map(
MEM_TYPE        => 0,           -- 0 choose BRAM, 1 choose Distributed RAM
BRAM_MACRO_NUM  => 1,           -- Memory Depth(Кол-во элементов BRAM (1BRAM-4kB). For BRAM only - Allowed: 1, 2, 4, 8, 16
DRAM_DEPTH      => 16,          -- Memory Depth. For DRAM only

WR_REM_WIDTH    => 1,           -- Remainder width of write data
WR_DWIDTH       => 16,          -- FIFO write data width,
                                   -- Acceptable values are 8, 16, 32, 64, 128.

RD_REM_WIDTH    => 1,           -- Remainder width of read data
RD_DWIDTH       => 16,          -- FIFO read data width,
                                   -- Acceptable values are 8, 16, 32, 64, 128.

USE_LENGTH      => false,       -- Length FIFO option
glbtm           => 1 ns         -- Global timing delay for simulation
)
port map
(
-- Interface to downstream user application
data_out               => p_out_sh_cxd(i),
rem_out                => open,--ll_rcmdpkt_rem,
sof_out_n              => open,--p_out_sh_cxd_sof_n(i),
eof_out_n              => p_out_sh_cxd_eof_n(i),
src_rdy_out_n          => p_out_sh_cxd_src_rdy_n(i),
dst_rdy_in_n           => '0',

read_clock_in          => p_in_sh_clk(i),

-- Interface to upstream user application
data_in                => p_in_uap_cxd(i),
rem_in                 => "0",
sof_in_n               => p_in_uap_cxd_sof_n(i),
eof_in_n               => p_in_uap_cxd_eof_n(i),
src_rdy_in_n           => p_in_uap_cxd_src_rdy_n(i),
dst_rdy_out_n          => open,--p_out_wcmdpkt_dst_rdy_n,

write_clock_in         => p_in_uap_clk,

-- FIFO status signals
fifostatus_out         => open,

-- Length Status
len_rdy_out            => open,
len_out                => open,
len_err_out            => open,

-- Reset
areset_in              => i_buf_rst(i)
);

m_txbuf : sata_txfifo
port map
(
din        => p_in_uap_txd(i),
wr_en      => p_in_uap_txd_wr(i),
wr_clk     => p_in_uap_clk,

dout       => p_out_sh_txd(i),
rd_en      => p_in_sh_txd_rd(i),
rd_clk     => p_in_sh_clk(i),

full        => p_out_txbuf_status(i).full,
prog_full   => p_out_txbuf_status(i).pfull,
--almost_full => i_txbuf_afull(0),
empty       => p_out_txbuf_status(i).empty,
almost_empty=> p_out_txbuf_status(i).aempty,

rst        => i_buf_rst(i)
);

m_rxbuf : sata_rxfifo
port map
(
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

rst        => i_buf_rst(i)
);
end generate gen_ch;

--END MAIN
end behavioral;
