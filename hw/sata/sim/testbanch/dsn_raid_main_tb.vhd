-------------------------------------------------------------------------
-- Company     : Linkos
-- Engineer    : Golovachenko Victor
--
-- Create Date : 31.03.2011 19:15:18
-- Module Name : dsn_raid_main_tb
--
-- Description : Моделирование работы модуля dsn_raid_main.vhd
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

use ieee.std_logic_textio.all;
use std.textio.all;

library unisim;
use unisim.vcomponents.all;

use work.vicg_common_pkg.all;
use work.sata_unit_pkg.all;
use work.sata_pkg.all;
use work.sata_sim_pkg.all;
use work.sata_sim_lite_pkg.all;

entity dsn_raid_main_tb is
generic
(
G_HDD_COUNT     : integer:=1;    --//Кол-во sata устр-в (min/max - 1/8)
G_GTP_DBUS      : integer:=16;
G_DBG           : string :="ON";
G_SIM           : string :="ON"
);
end dsn_raid_main_tb;

architecture behavior of dsn_raid_main_tb is

constant C_SATACLK_PERIOD : TIME := 6.6 ns; --150MHz
constant C_USRCLK_PERIOD  : TIME := 6.6*8 ns;

signal i_sata_clk                 : std_logic;
signal p_in_clk                   : std_logic;
signal p_in_rst                   : std_logic;

signal i_sata_txn                 : std_logic_vector((C_GTP_CH_COUNT_MAX*C_SATAHOST_COUNT_MAX(G_HDD_COUNT-1))-1 downto 0);
signal i_sata_txp                 : std_logic_vector((C_GTP_CH_COUNT_MAX*C_SATAHOST_COUNT_MAX(G_HDD_COUNT-1))-1 downto 0);
signal i_sata_rxn                 : std_logic_vector((C_GTP_CH_COUNT_MAX*C_SATAHOST_COUNT_MAX(G_HDD_COUNT-1))-1 downto 0);
signal i_sata_rxp                 : std_logic_vector((C_GTP_CH_COUNT_MAX*C_SATAHOST_COUNT_MAX(G_HDD_COUNT-1))-1 downto 0);
signal i_sata_refclk              : std_logic_vector((C_SATAHOST_COUNT_MAX(G_HDD_COUNT-1))-1 downto 0);

signal p_in_usr_ctrl              : std_logic_vector(31 downto 0);

signal i_usr_cxdin                : std_logic_vector(15 downto 0);
signal i_usr_cxdout               : std_logic_vector(15 downto 0);
signal i_usr_cxd_wr               : std_logic;
signal i_usr_cxd_rd               : std_logic;
signal i_usr_cxbuf_empty          : std_logic;

signal i_usr_txdin                : std_logic_vector(31 downto 0);
signal i_usr_txdout               : std_logic_vector(31 downto 0);
signal i_usr_txd_wr               : std_logic;
signal i_usr_txd_rd               : std_logic;
signal i_usr_txbuf_empty          : std_logic;
signal i_usr_rxdin                : std_logic_vector(31 downto 0);
signal i_usr_rxdout               : std_logic_vector(31 downto 0);
signal i_usr_rxd_wr               : std_logic;
signal i_usr_rxd_rd               : std_logic;


signal i_sim_gtp_txdata           : TBus16_SataCountMax;
signal i_sim_gtp_txcharisk        : TBus02_SataCountMax;
signal i_sim_gtp_rxdata           : TBus16_SataCountMax;
signal i_sim_gtp_rxcharisk        : TBus02_SataCountMax;
signal i_sim_gtp_rxstatus         : TBus03_SataCountMax;
signal i_sim_gtp_rxelecidle       : std_logic_vector(C_SATA_COUNT_MAX-1 downto 0);
signal i_sim_gtp_rxdisperr        : TBus02_SataCountMax;
signal i_sim_gtp_rxnotintable     : TBus02_SataCountMax;
signal i_sim_gtp_rxbyteisaligned  : std_logic_vector(C_SATA_COUNT_MAX-1 downto 0);
signal i_sim_gtp_rst              : std_logic_vector(C_SATA_COUNT_MAX-1 downto 0);
signal i_sim_gtp_clk              : std_logic_vector(C_SATA_COUNT_MAX-1 downto 0);


signal i_satadev_ctrl             : TSataDevCtrl;



--Main
begin


m_cxbuf : sata_cmdfifo
port map
(
din        => i_usr_cxdin,
wr_en      => i_usr_cxd_wr,
wr_clk     => p_in_clk,

dout       => i_usr_cxdout,
rd_en      => i_usr_cxd_rd,
rd_clk     => p_in_clk,

full       => open,
empty      => i_usr_cxbuf_empty,

rst        => p_in_rst
);


m_txbuf : sata_txfifo
port map
(
din        => i_usr_txdin,
wr_en      => i_usr_txd_wr,
wr_clk     => p_in_clk,

dout       => i_usr_txdout,
rd_en      => i_usr_txd_rd,
rd_clk     => p_in_clk,

full        => open,
prog_full   => open,
--almost_full => i_txbuf_afull,
empty       => i_usr_txbuf_empty,
almost_empty=> open,

rst        => p_in_rst
);

m_rxbuf : sata_rxfifo
port map
(
din        => i_usr_rxdin,
wr_en      => i_usr_rxd_wr,
wr_clk     => p_in_clk,

dout       => i_usr_rxdout,
rd_en      => i_usr_rxd_rd,
rd_clk     => p_in_clk,

full        => open,
prog_full   => open,
--almost_full => open,
empty       => open,
--almost_empty=> open,

rst        => p_in_rst
);


gen_sata_drv : for i in 0 to (C_SATAHOST_COUNT_MAX(G_HDD_COUNT-1))-1 generate
i_sata_rxn<=(others=>'0');
i_sata_rxp<=(others=>'1');
i_sata_refclk(i)<=i_sata_clk;
end generate gen_sata_drv;


m_raid : dsn_raid_main
generic map
(
G_HDD_COUNT       => G_HDD_COUNT,
G_GTP_DBUS        => G_GTP_DBUS,
G_DBG             => G_DBG,
G_SIM             => G_SIM
)
port map
(
---------------------------------------------------------------------------
--Sata Driver
---------------------------------------------------------------------------
p_out_sata_txn              => i_sata_txn,
p_out_sata_txp              => i_sata_txp,
p_in_sata_rxn               => i_sata_rxn,
p_in_sata_rxp               => i_sata_rxp,

p_in_sata_refclk            => i_sata_refclk,

--------------------------------------------------
--Связь с модулем dsn_hdd.vhd
--------------------------------------------------
p_in_usr_ctrl               => p_in_usr_ctrl,

--//Связь с CMDFIFO
p_in_usr_cxd                => i_usr_cxdout,
p_out_usr_cxd_rd            => i_usr_cxd_rd,
p_in_usr_cxbuf_empty        => i_usr_cxbuf_empty,

--//Связь с TxFIFO
p_in_usr_txd                => i_usr_txdout,
p_out_usr_txd_rd            => i_usr_txd_rd,
p_in_usr_txbuf_empty        => i_usr_txbuf_empty,

--//Связь с RxFIFO
p_out_usr_rxd               => i_usr_rxdin,
p_out_usr_rxd_wr            => i_usr_rxd_wr,


--------------------------------------------------
--Моделирование/Отладка - в рабочем проекте не используется
--------------------------------------------------
p_out_sim_gtp_txdata        => i_sim_gtp_rxdata,
p_out_sim_gtp_txcharisk     => i_sim_gtp_rxcharisk,
p_in_sim_gtp_rxdata         => i_sim_gtp_txdata,
p_in_sim_gtp_rxcharisk      => i_sim_gtp_txcharisk,

p_in_sim_gtp_rxstatus       => i_sim_gtp_rxstatus,
p_in_sim_gtp_rxelecidle     => i_sim_gtp_rxelecidle,
p_in_sim_gtp_rxdisperr      => i_sim_gtp_rxdisperr,
p_in_sim_gtp_rxnotintable   => i_sim_gtp_rxnotintable,
p_in_sim_gtp_rxbyteisaligned=> i_sim_gtp_rxbyteisaligned,
p_out_gtp_sim_rst           => i_sim_gtp_rst,
p_out_gtp_sim_clk           => i_sim_gtp_clk,

--------------------------------------------------
--Технологические сигналы
--------------------------------------------------
p_in_tst                => "00000000000000000000000000000000",
p_out_tst               => open,

--------------------------------------------------
--System
--------------------------------------------------
p_in_clk                => p_in_clk,
p_in_rst                => p_in_rst
);


gen_satad : for i in 0 to G_HDD_COUNT-1 generate

m_sata_dev : sata_dev_model
generic map
(
G_DBG_LLAYER => "OFF",
G_GTP_DBUS   => G_GTP_DBUS
)
port map
(
----------------------------
--
----------------------------
p_out_gtp_txdata            => i_sim_gtp_txdata(i),
p_out_gtp_txcharisk         => i_sim_gtp_txcharisk(i),

p_in_gtp_rxdata             => i_sim_gtp_rxdata(i),
p_in_gtp_rxcharisk          => i_sim_gtp_rxcharisk(i),

p_out_gtp_rxstatus          => i_sim_gtp_rxstatus(i),
p_out_gtp_rxelecidle        => i_sim_gtp_rxelecidle(i),
p_out_gtp_rxdisperr         => i_sim_gtp_rxdisperr(i),
p_out_gtp_rxnotintable      => i_sim_gtp_rxnotintable(i),
p_out_gtp_rxbyteisaligned   => i_sim_gtp_rxbyteisaligned(i),

p_in_ctrl                   => i_satadev_ctrl,

--------------------------------------------------
--Технологические сигналы
--------------------------------------------------
p_in_tst                   => "00000000000000000000000000000000",
p_out_tst                  => open,

----------------------------
--System
----------------------------
p_in_clk                   => i_sim_gtp_clk(i),
p_in_rst                   => i_sim_gtp_rst(i)
);

end generate gen_satad;


gen_clk_sata : process
begin
  i_sata_clk<='0';
  wait for C_SATACLK_PERIOD/2;
  i_sata_clk<='1';
  wait for C_SATACLK_PERIOD/2;
end process;

gen_clk_usr : process
begin
  p_in_clk<='0';
  wait for C_USRCLK_PERIOD/2;
  p_in_clk<='1';
  wait for C_USRCLK_PERIOD/2;
end process;

p_in_rst<='1','0' after 1 us;



--//########################################
--//Main Ctrl
--//########################################

p_in_usr_ctrl<=(others=>'0');




--End Main
end;



