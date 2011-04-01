-------------------------------------------------------------------------
-- Company     : Linkos
-- Engineer    : Golovachenko Victor
--
-- Create Date : 31.03.2011 18:27:25
-- Module Name : dsn_raid_main
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
use work.sata_raid_pkg.all;

entity dsn_raid_main is
generic
(
G_HDD_COUNT     : integer:=2;    --//Кол-во sata устр-в (min/max - 1/8)
G_GTP_DBUS      : integer:=16;
G_DBG           : string :="OFF";
G_SIM           : string :="OFF"
);
port
(
--------------------------------------------------
--Sata Driver
--------------------------------------------------
p_out_sata_txn              : out   std_logic_vector((C_GTP_CH_COUNT_MAX*C_SATAHOST_COUNT_MAX(G_HDD_COUNT-1))-1 downto 0);
p_out_sata_txp              : out   std_logic_vector((C_GTP_CH_COUNT_MAX*C_SATAHOST_COUNT_MAX(G_HDD_COUNT-1))-1 downto 0);
p_in_sata_rxn               : in    std_logic_vector((C_GTP_CH_COUNT_MAX*C_SATAHOST_COUNT_MAX(G_HDD_COUNT-1))-1 downto 0);
p_in_sata_rxp               : in    std_logic_vector((C_GTP_CH_COUNT_MAX*C_SATAHOST_COUNT_MAX(G_HDD_COUNT-1))-1 downto 0);

p_in_sata_refclk            : in    std_logic_vector((C_SATAHOST_COUNT_MAX(G_HDD_COUNT-1))-1 downto 0);

--------------------------------------------------
--Связь с модулем dsn_hdd.vhd
--------------------------------------------------
p_in_usr_ctrl               : in    std_logic_vector(31 downto 0);
p_out_usr_status            : out   TUsrStatus;

--//Связь с CMDFIFO
p_in_usr_cxd                : in    std_logic_vector(15 downto 0);
p_out_usr_cxd_rd            : out   std_logic;
p_in_usr_cxbuf_empty        : in    std_logic;

--//Связь с TxFIFO
p_in_usr_txd                : in    std_logic_vector(31 downto 0);
p_out_usr_txd_rd            : out   std_logic;
p_in_usr_txbuf_empty        : in    std_logic;

--//Связь с RxFIFO
p_out_usr_rxd               : out   std_logic_vector(31 downto 0);
p_out_usr_rxd_wr            : out   std_logic;


--------------------------------------------------
--Моделирование/Отладка - в рабочем проекте не используется
--------------------------------------------------
p_out_sim_gtp_txdata        : out   TBus16_SataCountMax;
p_out_sim_gtp_txcharisk     : out   TBus02_SataCountMax;
p_in_sim_gtp_rxdata         : in    TBus16_SataCountMax;
p_in_sim_gtp_rxcharisk      : in    TBus02_SataCountMax;
p_in_sim_gtp_rxstatus       : in    TBus03_SataCountMax;
p_in_sim_gtp_rxelecidle     : in    std_logic_vector(C_SATA_COUNT_MAX-1 downto 0);
p_in_sim_gtp_rxdisperr      : in    TBus02_SataCountMax;
p_in_sim_gtp_rxnotintable   : in    TBus02_SataCountMax;
p_in_sim_gtp_rxbyteisaligned: in    std_logic_vector(C_SATA_COUNT_MAX-1 downto 0);
p_out_gtp_sim_rst           : out   std_logic_vector(C_SATA_COUNT_MAX-1 downto 0);
p_out_gtp_sim_clk           : out   std_logic_vector(C_SATA_COUNT_MAX-1 downto 0);

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
end dsn_raid_main;

architecture behavioral of dsn_raid_main is

--//Определяет какое кол-во каналов использеустся конкретным модуем sata_host.vhd в зависиости от G_HDD_COUNT
--//Где C_SATAHOST_CH_COUNT=(индекс модуля sata_host)(мах количество каналов в одном GTP)(количество sata в raid)
constant C_SATAHOST_CH_COUNT : T8x08SataSel:=(
C_GTP0_CH_COUNT,
C_GTP1_CH_COUNT,
C_GTP2_CH_COUNT,
C_GTP3_CH_COUNT,
C_GTP4_CH_COUNT,
C_GTP5_CH_COUNT,
C_GTP6_CH_COUNT,
C_GTP7_CH_COUNT
);


signal i_sh_gtp_refclkout          : std_logic_vector(C_SATAHOST_COUNT_MAX(G_HDD_COUNT-1)-1 downto 0);
signal i_sh_dcm_rst                : std_logic_vector(C_SATAHOST_COUNT_MAX(G_HDD_COUNT-1)-1 downto 0);
signal g_sh_dcm_clkin              : std_logic;
signal g_sh_dcm_clk2div            : std_logic;
signal g_sh_dcm_clk                : std_logic;
signal g_sh_dcm_clk2x              : std_logic;
signal i_sh_dcm_lock               : std_logic;


signal i_sh_status                 : TALStatusGtpCh_SataCountMax;
signal i_sh_ctrl                   : TALCtrlGtpCh_SataCountMax;
--//cmdfifo
signal i_u_cxd                     : TBus16GtpCh_SataCountMax;
signal i_u_cxd_sof_n               : TBusGtpCh_SataCountMax;
signal i_u_cxd_eof_n               : TBusGtpCh_SataCountMax;
signal i_u_cxd_src_rdy_n           : TBusGtpCh_SataCountMax;
signal i_sh_cxd                    : TBus16GtpCh_SataCountMax;
signal i_sh_cxd_eof_n              : TBusGtpCh_SataCountMax;
signal i_sh_cxd_src_rdy_n          : TBusGtpCh_SataCountMax;
--//txfifo
signal i_u_txd                     : TBus32GtpCh_SataCountMax;
signal i_u_txd_wr                  : TBusGtpCh_SataCountMax;
signal i_sh_txd                    : TBus32GtpCh_SataCountMax;
signal i_sh_txd_rd                 : TBusGtpCh_SataCountMax;
--//rxfifo
signal i_u_rxd                     : TBus32GtpCh_SataCountMax;
signal i_u_rxd_rd                  : TBusGtpCh_SataCountMax;
signal i_sh_rxd                    : TBus32GtpCh_SataCountMax;
signal i_sh_rxd_wr                 : TBusGtpCh_SataCountMax;
--//stausfifo
signal i_txbuf_status              : TTxBufStatusGtpCh_SataCountMax;
signal i_rxbuf_status              : TRxBufStatusGtpCh_SataCountMax;

signal i_sh_clkout                 : TBusGtpCh_SataCountMax;
signal i_uap_status                : TALStatus_SataCountMax;
signal i_uap_ctrl                  : TALCtrl_SataCountMax;

signal i_uap_cxd                   : TBus16_SataCountMax;
signal i_uap_cxd_sof_n             : std_logic_vector(C_SATA_COUNT_MAX-1 downto 0);
signal i_uap_cxd_eof_n             : std_logic_vector(C_SATA_COUNT_MAX-1 downto 0);
signal i_uap_cxd_src_rdy_n         : std_logic_vector(C_SATA_COUNT_MAX-1 downto 0);

signal i_uap_txd                   : TBus32_SataCountMax;
signal i_uap_txd_wr                : std_logic_vector(C_SATA_COUNT_MAX-1 downto 0);

signal i_uap_rxd                   : TBus32_SataCountMax;
signal i_uap_rxd_rd                : std_logic_vector(C_SATA_COUNT_MAX-1 downto 0);
signal i_uap_txbuf_status          : TTxBufStatus_SataCountMax;
signal i_uap_rxbuf_status          : TRxBufStatus_SataCountMax;

signal i_sim_gtp_txdata            : TBus16GtpCh_SataCountMax;
signal i_sim_gtp_txcharisk         : TBus02GtpCh_SataCountMax;
signal i_sim_gtp_rxdata            : TBus16GtpCh_SataCountMax;
signal i_sim_gtp_rxcharisk         : TBus02GtpCh_SataCountMax;
signal i_sim_gtp_rxstatus          : TBus03GtpCh_SataCountMax;
signal i_sim_gtp_rxelecidle        : TBusGtpCh_SataCountMax;
signal i_sim_gtp_rxdisperr         : TBus02GtpCh_SataCountMax;
signal i_sim_gtp_rxnotintable      : TBus02GtpCh_SataCountMax;
signal i_sim_gtp_rxbyteisaligned   : TBusGtpCh_SataCountMax;
signal i_sim_gtp_rst               : TBusGtpCh_SataCountMax;
signal i_sim_gtp_clk               : TBusGtpCh_SataCountMax;

signal tst_sh_in                   : TBus32_SataCountMax;
signal tst_sh_out                  : TBus32_SataCountMax;


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


--//#############################################
--//RAID контроллер
--//#############################################
m_raid_ctrl : sata_raid
generic map
(
G_HDD_COUNT => G_HDD_COUNT,
G_DBG       => G_DBG,
G_SIM       => G_SIM
)
port map
(
--------------------------------------------------
--Связь с модулем dsn_hdd.vhd
--------------------------------------------------
p_in_usr_ctrl           => p_in_usr_ctrl,
p_out_usr_status        => p_out_usr_status,

--//cmdbuf
p_in_usr_cxd            => p_in_usr_cxd,
p_out_usr_cxd_rd        => p_out_usr_cxd_rd,
p_in_usr_cxbuf_empty    => p_in_usr_cxbuf_empty,

--//txbuf
p_in_usr_txd            => p_in_usr_txd,
p_out_usr_txd_rd        => p_out_usr_txd_rd,
p_in_usr_txbuf_empty    => p_in_usr_txbuf_empty,

--//rxbuf
p_out_usr_rxd           => p_out_usr_rxd,
p_out_usr_rxd_wr        => p_out_usr_rxd_wr,

--------------------------------------------------
--Связь с модулями sata_host.vhd
--------------------------------------------------
p_in_uap_status         => i_uap_status,
p_out_uap_ctrl          => i_uap_ctrl,
--/cmdbuf
p_out_uap_cxd           => i_uap_cxd,
p_out_uap_cxd_sof_n     => i_uap_cxd_sof_n,
p_out_uap_cxd_eof_n     => i_uap_cxd_eof_n,
p_out_uap_cxd_src_rdy_n => i_uap_cxd_src_rdy_n,
--/txbuf
p_out_uap_txd           => i_uap_txd,
p_out_uap_txd_wr        => i_uap_txd_wr,
--/rxbuf
p_in_uap_rxd            => i_uap_rxd,
p_out_uap_rxd_rd        => i_uap_rxd_rd,
--/bufstatus
p_in_uap_txbuf_status   => i_uap_txbuf_status,
p_in_uap_rxbuf_status   => i_uap_rxbuf_status,

--------------------------------------------------
--Технологические сигналы
--------------------------------------------------
p_in_tst                => p_in_tst,
p_out_tst               => p_out_tst,

p_in_sh_tst             => tst_sh_out,
p_out_sh_tst            => tst_sh_in,

--------------------------------------------------
--System
--------------------------------------------------
p_in_clk                => p_in_clk,
p_in_rst                => p_in_rst
);



--//#############################################
--//Генерация частот для модулей sata_host.vhd
--//#############################################
bufg_sata : BUFG port map (I => i_sh_gtp_refclkout(C_SATAHOST_MAIN_NUM), O => g_sh_dcm_clkin);

m_dcm_sata : sata_dcm
port map
(
p_out_dcm_gclk0  => g_sh_dcm_clk,
p_out_dcm_gclk2x => g_sh_dcm_clk2x,
p_out_dcm_gclkdv => g_sh_dcm_clk2div,

p_out_dcmlock    => i_sh_dcm_lock,

p_in_clk         => g_sh_dcm_clkin, --//150MHz
p_in_rst         => i_sh_dcm_rst(C_SATAHOST_MAIN_NUM)
);


--//#############################################
--//Размножение модулей sata_host.vhd
--//#############################################
gen_satah : for sh_idx in 0 to C_SATAHOST_COUNT_MAX(G_HDD_COUNT-1)-1 generate

--//сигналы для связи с sata_raid.vhd
gen_satah_ch : for ch_idx in 0 to C_GTP_CH_COUNT_MAX-1 generate

--//статусы и управление модулем sata_host.vhd
i_uap_status(C_GTP_CH_COUNT_MAX*sh_idx+ch_idx)<=i_sh_status(sh_idx)(ch_idx);
i_sh_ctrl(sh_idx)(ch_idx)<=i_uap_ctrl(C_GTP_CH_COUNT_MAX*sh_idx+ch_idx);

--//cmdbuf
i_u_cxd(sh_idx)(ch_idx)<=i_uap_cxd(C_GTP_CH_COUNT_MAX*sh_idx+ch_idx);
i_u_cxd_sof_n(sh_idx)(ch_idx)<=i_uap_cxd_sof_n(C_GTP_CH_COUNT_MAX*sh_idx+ch_idx);
i_u_cxd_eof_n(sh_idx)(ch_idx)<=i_uap_cxd_eof_n(C_GTP_CH_COUNT_MAX*sh_idx+ch_idx);
i_u_cxd_src_rdy_n(sh_idx)(ch_idx)<=i_uap_cxd_src_rdy_n(C_GTP_CH_COUNT_MAX*sh_idx+ch_idx);

--//txbuf
i_u_txd(sh_idx)(ch_idx)<=i_uap_txd(C_GTP_CH_COUNT_MAX*sh_idx+ch_idx);
i_u_txd_wr(sh_idx)(ch_idx)<=i_uap_txd_wr(C_GTP_CH_COUNT_MAX*sh_idx+ch_idx);

--//rxbuf
i_uap_rxd(C_GTP_CH_COUNT_MAX*sh_idx+ch_idx)<=i_u_rxd(sh_idx)(ch_idx);
i_u_rxd_rd(sh_idx)(ch_idx)<=i_uap_rxd_rd(C_GTP_CH_COUNT_MAX*sh_idx+ch_idx);

--//bufstatus
i_uap_txbuf_status(C_GTP_CH_COUNT_MAX*sh_idx+ch_idx)<=i_txbuf_status(sh_idx)(ch_idx);
i_uap_rxbuf_status(C_GTP_CH_COUNT_MAX*sh_idx+ch_idx)<=i_rxbuf_status(sh_idx)(ch_idx);

--//Моделирование
p_out_gtp_sim_rst(C_GTP_CH_COUNT_MAX*sh_idx+ch_idx)<=i_sim_gtp_rst(sh_idx)(ch_idx);
p_out_gtp_sim_clk(C_GTP_CH_COUNT_MAX*sh_idx+ch_idx)<=i_sim_gtp_clk(sh_idx)(ch_idx);

p_out_sim_gtp_txdata(C_GTP_CH_COUNT_MAX*sh_idx+ch_idx)<=i_sim_gtp_txdata(sh_idx)(ch_idx);
p_out_sim_gtp_txcharisk(C_GTP_CH_COUNT_MAX*sh_idx+ch_idx)<=i_sim_gtp_txcharisk(sh_idx)(ch_idx);

i_sim_gtp_rxdata(sh_idx)(ch_idx)<=p_in_sim_gtp_rxdata(C_GTP_CH_COUNT_MAX*sh_idx+ch_idx);
i_sim_gtp_rxcharisk(sh_idx)(ch_idx)<=p_in_sim_gtp_rxcharisk(C_GTP_CH_COUNT_MAX*sh_idx+ch_idx);
i_sim_gtp_rxstatus(sh_idx)(ch_idx)<=p_in_sim_gtp_rxstatus(C_GTP_CH_COUNT_MAX*sh_idx+ch_idx);
i_sim_gtp_rxelecidle(sh_idx)(ch_idx)<=p_in_sim_gtp_rxelecidle(C_GTP_CH_COUNT_MAX*sh_idx+ch_idx);
i_sim_gtp_rxdisperr(sh_idx)(ch_idx)<=p_in_sim_gtp_rxdisperr(C_GTP_CH_COUNT_MAX*sh_idx+ch_idx);
i_sim_gtp_rxnotintable(sh_idx)(ch_idx)<=p_in_sim_gtp_rxnotintable(C_GTP_CH_COUNT_MAX*sh_idx+ch_idx);
i_sim_gtp_rxbyteisaligned(sh_idx)(ch_idx)<=p_in_sim_gtp_rxbyteisaligned(C_GTP_CH_COUNT_MAX*sh_idx+ch_idx);

end generate gen_satah_ch;



--//Согласующие буфера между sata_raid.vhd <-> sata_host.vhd:
m_satah_buf : sata_connector
generic map
(
G_SATAH_CH_COUNT  => C_SATAHOST_CH_COUNT(sh_idx)(C_GTP_CH_COUNT_MAX-1)(G_HDD_COUNT-1),
G_DBG             => G_DBG,
G_SIM             => G_SIM
)
port map
(
--------------------------------------------------
--Связь с модулем
--------------------------------------------------
p_in_uap_clk            => p_in_clk,

--//CMDFIFO
p_in_uap_cxd            => i_u_cxd(sh_idx),
p_in_uap_cxd_sof_n      => i_u_cxd_sof_n(sh_idx),
p_in_uap_cxd_eof_n      => i_u_cxd_eof_n(sh_idx),
p_in_uap_cxd_src_rdy_n  => i_u_cxd_src_rdy_n(sh_idx),

--//TXFIFO
p_in_uap_txd            => i_u_txd(sh_idx),
p_in_uap_txd_wr         => i_u_txd_wr(sh_idx),

--//RXFIFO
p_out_uap_rxd           => i_u_rxd(sh_idx),
p_in_uap_rxd_rd         => i_u_rxd_rd(sh_idx),

--------------------------------------------------
--Связь с модулем sata_host.vhd
--------------------------------------------------
p_in_sh_clk             => i_sh_clkout(sh_idx),

--//CMDFIFO
p_out_sh_cxd            => i_sh_cxd(sh_idx),
p_out_sh_cxd_eof_n      => i_sh_cxd_eof_n(sh_idx),
p_out_sh_cxd_src_rdy_n  => i_sh_cxd_src_rdy_n(sh_idx),

--//Связь с TXFIFO
p_out_sh_txd            => i_sh_txd(sh_idx),
p_in_sh_txd_rd          => i_sh_txd_rd(sh_idx),

--//Связь с RXFIFO
p_in_sh_rxd             => i_sh_rxd(sh_idx),
p_in_sh_rxd_wr          => i_sh_rxd_wr(sh_idx),

--------------------------------------------------
--//Статусы
--------------------------------------------------
p_out_txbuf_status      => i_txbuf_status(sh_idx),
p_out_rxbuf_status      => i_rxbuf_status(sh_idx),

--------------------------------------------------
--Технологические сигналы
--------------------------------------------------
p_in_tst                => "00000000000000000000000000000000",
p_out_tst               => open,

--------------------------------------------------
--System
--------------------------------------------------
p_in_rst                => p_in_rst
);


--//SATA Контроллер
m_satah : sata_host
generic map
(
G_SATAH_COUNT_MAX => C_SATAHOST_COUNT_MAX(G_HDD_COUNT-1),
G_SATAH_NUM       => sh_idx,
G_SATAH_CH_COUNT  => C_SATAHOST_CH_COUNT(sh_idx)(C_GTP_CH_COUNT_MAX-1)(G_HDD_COUNT-1),
G_GTP_DBUS        => G_GTP_DBUS,
G_DBG             => G_DBG,
G_SIM             => G_SIM
)
port map
(
--------------------------------------------------
--Sata Driver
--------------------------------------------------
p_out_sata_txn              => p_out_sata_txn(((C_GTP_CH_COUNT_MAX*(sh_idx+1))-1) downto (C_GTP_CH_COUNT_MAX*sh_idx)),
p_out_sata_txp              => p_out_sata_txp(((C_GTP_CH_COUNT_MAX*(sh_idx+1))-1) downto (C_GTP_CH_COUNT_MAX*sh_idx)),
p_in_sata_rxn               => p_in_sata_rxn(((C_GTP_CH_COUNT_MAX*(sh_idx+1))-1) downto (C_GTP_CH_COUNT_MAX*sh_idx)),
p_in_sata_rxp               => p_in_sata_rxp(((C_GTP_CH_COUNT_MAX*(sh_idx+1))-1) downto (C_GTP_CH_COUNT_MAX*sh_idx)),

--------------------------------------------------
--Связь с USERAPP Layer
--------------------------------------------------
p_out_usrfifo_clkout        => i_sh_clkout(sh_idx),
p_out_status                => i_sh_status(sh_idx),
p_in_ctrl                   => i_sh_ctrl(sh_idx),

--//Связь с CMDFIFO
p_in_cmdfifo_dout           => i_sh_cxd(sh_idx),
p_in_cmdfifo_eof_n          => i_sh_cxd_eof_n(sh_idx),
p_in_cmdfifo_src_rdy_n      => i_sh_cxd_src_rdy_n(sh_idx),
p_out_cmdfifo_dst_rdy_n     => open,


--//Связь с TXFIFO
p_in_txbuf_dout             => i_sh_txd(sh_idx),
p_out_txbuf_rd              => i_sh_txd_rd(sh_idx),
p_in_txbuf_status           => i_txbuf_status(sh_idx),

--//Связь с RXFIFO
p_out_rxbuf_din             => i_sh_rxd(sh_idx),
p_out_rxbuf_wd              => i_sh_rxd_wr(sh_idx),
p_in_rxbuf_status           => i_rxbuf_status(sh_idx),

--------------------------------------------------
--Технологические сигналы
--------------------------------------------------
p_in_tst                    => tst_sh_in(sh_idx),
p_out_tst                   => tst_sh_out(sh_idx),

--------------------------------------------------
--Моделирование/Отладка - в рабочем проекте не используется
--------------------------------------------------
--//Моделирование
p_out_sim_gtp_txdata        => i_sim_gtp_txdata(sh_idx),
p_out_sim_gtp_txcharisk     => i_sim_gtp_txcharisk(sh_idx),
p_in_sim_gtp_rxdata         => i_sim_gtp_rxdata(sh_idx),
p_in_sim_gtp_rxcharisk      => i_sim_gtp_rxcharisk(sh_idx),
p_in_sim_gtp_rxstatus       => i_sim_gtp_rxstatus(sh_idx),
p_in_sim_gtp_rxelecidle     => i_sim_gtp_rxelecidle(sh_idx),
p_in_sim_gtp_rxdisperr      => i_sim_gtp_rxdisperr(sh_idx),
p_in_sim_gtp_rxnotintable   => i_sim_gtp_rxnotintable(sh_idx),
p_in_sim_gtp_rxbyteisaligned=> i_sim_gtp_rxbyteisaligned(sh_idx),
p_out_sim_rst               => i_sim_gtp_rst(sh_idx),
p_out_sim_clk               => i_sim_gtp_clk(sh_idx),

--------------------------------------------------
--System
--------------------------------------------------
p_in_sys_dcm_gclk2div       => g_sh_dcm_clk2div,
p_in_sys_dcm_gclk           => g_sh_dcm_clk,
p_in_sys_dcm_gclk2x         => g_sh_dcm_clk2x,
p_in_sys_dcm_lock           => i_sh_dcm_lock,
p_out_sys_dcm_rst           => i_sh_dcm_rst(sh_idx),

p_in_gtp_drpclk             => g_sh_dcm_clk2div,
p_out_gtp_refclk            => i_sh_gtp_refclkout(sh_idx),
p_in_gtp_refclk             => p_in_sata_refclk(sh_idx),
p_in_rst                    => p_in_rst
);

end generate gen_satah;


--END MAIN
end behavioral;
