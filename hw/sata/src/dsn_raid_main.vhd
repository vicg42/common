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

library work;
use work.vicg_common_pkg.all;
use work.sata_glob_pkg.all;
use work.sata_pkg.all;
use work.sata_sim_lite_pkg.all;
use work.sata_raid_pkg.all;
use work.sata_unit_pkg.all;

entity dsn_raid_main is
generic(
G_HDD_COUNT : integer:=2;    --//Кол-во sata устр-в (min/max - 1/8)
G_GT_DBUS   : integer:=16;
G_DBG       : string :="OFF";
G_DBGCS     : string :="OFF";--//
G_SIM       : string :="OFF"
);
port(
--------------------------------------------------
--Sata Driver
--------------------------------------------------
p_out_sata_txn              : out   std_logic_vector((C_GTCH_COUNT_MAX*C_SH_COUNT_MAX(G_HDD_COUNT-1))-1 downto 0);
p_out_sata_txp              : out   std_logic_vector((C_GTCH_COUNT_MAX*C_SH_COUNT_MAX(G_HDD_COUNT-1))-1 downto 0);
p_in_sata_rxn               : in    std_logic_vector((C_GTCH_COUNT_MAX*C_SH_COUNT_MAX(G_HDD_COUNT-1))-1 downto 0);
p_in_sata_rxp               : in    std_logic_vector((C_GTCH_COUNT_MAX*C_SH_COUNT_MAX(G_HDD_COUNT-1))-1 downto 0);

p_in_sata_refclk            : in    std_logic_vector(C_SH_COUNT_MAX(G_HDD_COUNT-1)-1 downto 0);
p_out_sata_refclkout        : out   std_logic;
p_out_sata_gt_plldet        : out   std_logic;
p_out_sata_dcm_lock         : out   std_logic;

--------------------------------------------------
--Связь с модулем dsn_hdd.vhd
--------------------------------------------------
p_in_usr_ctrl               : in    std_logic_vector(C_USR_GCTRL_LAST_BIT downto 0);
p_out_usr_status            : out   TUsrStatus;
p_out_measure               : out   TMeasureStatus;

--//cmdpkt
p_in_usr_cxd                : in    std_logic_vector(15 downto 0);
p_in_usr_cxd_wr             : in    std_logic;

--//txfifo
p_in_usr_txd                : in    std_logic_vector(31 downto 0);
p_out_usr_txd_rd            : out   std_logic;
p_in_usr_txbuf_empty        : in    std_logic;

--//rxfifo
p_out_usr_rxd               : out   std_logic_vector(31 downto 0);
p_out_usr_rxd_wr            : out   std_logic;
p_in_usr_rxbuf_full         : in    std_logic;

--------------------------------------------------
--//Debug/Sim
--------------------------------------------------
p_out_dbgcs                 : out   TSH_dbgcs_exp;

p_out_sim_gt_txdata         : out   TBus32_SHCountMax;
p_out_sim_gt_txcharisk      : out   TBus04_SHCountMax;
p_out_sim_gt_txcomstart     : out   std_logic_vector(C_HDD_COUNT_MAX-1 downto 0);
p_in_sim_gt_rxdata          : in    TBus32_SHCountMax;
p_in_sim_gt_rxcharisk       : in    TBus04_SHCountMax;
p_in_sim_gt_rxstatus        : in    TBus03_SHCountMax;
p_in_sim_gt_rxelecidle      : in    std_logic_vector(C_HDD_COUNT_MAX-1 downto 0);
p_in_sim_gt_rxdisperr       : in    TBus04_SHCountMax;
p_in_sim_gt_rxnotintable    : in    TBus04_SHCountMax;
p_in_sim_gt_rxbyteisaligned : in    std_logic_vector(C_HDD_COUNT_MAX-1 downto 0);
p_out_gt_sim_rst            : out   std_logic_vector(C_HDD_COUNT_MAX-1 downto 0);
p_out_gt_sim_clk            : out   std_logic_vector(C_HDD_COUNT_MAX-1 downto 0);

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

constant CI_SIM_T05us : integer:=8;--//Только для моделирования

--//Определяет какое кол-во каналов использеустся конкретным модуем sata_host.vhd в зависиости от G_HDD_COUNT
--//Где C_SH_CH_COUNT=(индекс модуля sata_host)(мах количество каналов в одном GTP)(количество sata в raid)
constant C_SH_CH_COUNT : T8x08SHCountSel:=(
C_GT0_CH_COUNT,
C_GT1_CH_COUNT,
C_GT2_CH_COUNT,
C_GT3_CH_COUNT,
C_GT4_CH_COUNT,
C_GT5_CH_COUNT,
C_GT6_CH_COUNT,
C_GT7_CH_COUNT
);

signal i_usr_status                : TUsrStatus;
signal g_refclkout                 : std_logic;

signal i_sh_gt_pllkdet             : std_logic_vector(C_SH_COUNT_MAX(G_HDD_COUNT-1)-1 downto 0);
signal i_sh_gt_refclkout           : std_logic_vector(C_SH_COUNT_MAX(G_HDD_COUNT-1)-1 downto 0);
signal i_sh_dcm_rst                : std_logic_vector(C_SH_COUNT_MAX(G_HDD_COUNT-1)-1 downto 0);
signal g_sh_dcm_clk2div            : std_logic;
signal g_sh_dcm_clk                : std_logic;
signal g_sh_dcm_clk2x              : std_logic;
signal i_sh_dcm_lock               : std_logic;

signal i_sh_gt_optrefclksel        : T04_SHCountMax;
signal i_sh_gt_optrefclkin         : T04_SHCountMax;
signal i_sh_gt_optrefclkout        : T04_SHCountMax;

signal i_sh_buf_rst                : TBusGTCH_SHCountMax;
signal i_sh_status                 : TALStatusGTCH_SHCountMax;
signal i_sh_ctrl                   : TALCtrlGTCH_SHCountMax;

signal i_measure_dev_busy          : std_logic;
signal i_measure_sh_status         : TMeasureALStatus_SHCountMax;
signal i_measure_status_out        : TMeasureStatus;
--signal i_hw_work                   : std_logic;
--signal i_hw_start                  : std_logic;
--signal i_hw_start_dly              : std_logic;

--//cmdfifo
signal i_u_cxd                     : TBus16GTCH_SHCountMax;
signal i_u_cxd_sof_n               : TBusGTCH_SHCountMax;
signal i_u_cxd_eof_n               : TBusGTCH_SHCountMax;
signal i_u_cxd_src_rdy_n           : TBusGTCH_SHCountMax;
signal i_sh_cxd                    : TBus16GTCH_SHCountMax;
signal i_sh_cxd_eof_n              : TBusGTCH_SHCountMax;
signal i_sh_cxd_src_rdy_n          : TBusGTCH_SHCountMax;
--//txfifo
signal i_u_txd                     : TBus32GTCH_SHCountMax;
signal i_u_txd_wr                  : TBusGTCH_SHCountMax;
signal i_sh_txd                    : TBus32GTCH_SHCountMax;
signal i_sh_txd_rd                 : TBusGTCH_SHCountMax;
--//rxfifo
signal i_u_rxd                     : TBus32GTCH_SHCountMax;
signal i_u_rxd_rd                  : TBusGTCH_SHCountMax;
signal i_sh_rxd                    : TBus32GTCH_SHCountMax;
signal i_sh_rxd_wr                 : TBusGTCH_SHCountMax;
--//stausfifo
signal i_txbuf_status              : TTxBufStatusGTCH_SHCountMax;
signal i_rxbuf_status              : TRxBufStatusGTCH_SHCountMax;

signal i_sh_clkout                 : TBusGTCH_SHCountMax;
signal i_uap_status                : TALStatus_SHCountMax;
signal i_uap_ctrl                  : TALCtrl_SHCountMax;

signal i_uap_cxd                   : TBus16_SHCountMax;
signal i_uap_cxd_sof_n             : std_logic_vector(C_HDD_COUNT_MAX-1 downto 0);
signal i_uap_cxd_eof_n             : std_logic_vector(C_HDD_COUNT_MAX-1 downto 0);
signal i_uap_cxd_src_rdy_n         : std_logic_vector(C_HDD_COUNT_MAX-1 downto 0);

signal i_uap_txd                   : TBus32_SHCountMax;
signal i_uap_txd_wr                : std_logic_vector(C_HDD_COUNT_MAX-1 downto 0);

signal i_uap_rxd                   : TBus32_SHCountMax;
signal i_uap_rxd_rd                : std_logic_vector(C_HDD_COUNT_MAX-1 downto 0);
signal i_uap_txbuf_status          : TTxBufStatus_SHCountMax;
signal i_uap_rxbuf_status          : TRxBufStatus_SHCountMax;

signal i_sim_gt_txdata             : TBus32GTCH_SHCountMax;
signal i_sim_gt_txcharisk          : TBus04GTCH_SHCountMax;
signal i_sim_gt_txcomstart         : TBusGTCH_SHCountMax;
signal i_sim_gt_rxdata             : TBus32GTCH_SHCountMax;
signal i_sim_gt_rxcharisk          : TBus04GTCH_SHCountMax;
signal i_sim_gt_rxstatus           : TBus03GTCH_SHCountMax;
signal i_sim_gt_rxelecidle         : TBusGTCH_SHCountMax;
signal i_sim_gt_rxdisperr          : TBus04GTCH_SHCountMax;
signal i_sim_gt_rxnotintable       : TBus04GTCH_SHCountMax;
signal i_sim_gt_rxbyteisaligned    : TBusGTCH_SHCountMax;
signal i_sim_gt_rst                : TBusGTCH_SHCountMax;
signal i_sim_gt_clk                : TBusGTCH_SHCountMax;

signal i_tst_sh_in                 : TBus32GTCH_SHCountMax;
signal i_tst_sh_out                : TBus32GTCH_SHCountMax;
signal i_dbg_sh_out                : TSH_dbgport_GTCH_SHCountMax;
signal i_dbgcs_sh_out              : TSH_dbgcs_GTCH_SHCountMax;

signal i_uap_tst_sh_in             : TBus32_SHCountMax;
signal i_uap_tst_sh_out            : TBus32_SHCountMax;
signal i_dbg_satah                 : TSH_dbgport_SHCountMax;
signal i_dbgcs_satah               : TSH_dbgcs_SHCountMax;
signal i_dbgcs_raid                : TSH_ila;
signal i_dbgcs_measure             : TSH_ila;
--signal i_dbgcs_hwstart_dly         : TSH_ila;

signal i_tst_measure_out           : std_logic_vector(31 downto 0);
signal i_tst_raidctrl_out          : std_logic_vector(31 downto 0);
signal i_tst_val                   : std_logic:='0';

attribute keep : string;
attribute keep of g_refclkout: signal is "true";
attribute keep of g_sh_dcm_clk: signal is "true";
attribute keep of g_sh_dcm_clk2x: signal is "true";
attribute keep of g_sh_dcm_clk2div: signal is "true";


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
p_out_tst(0)<=i_tst_raidctrl_out(0);
p_out_tst(1)<=i_uap_tst_sh_out(0)(1);
p_out_tst(2)<=i_tst_val;
p_out_tst(3)<=i_tst_measure_out(0);
p_out_tst(31 downto 4)<=(others=>'0');
end generate gen_dbg_on;


---##############################
-- Debug/Sim
---##############################
--//Только для моделирования (удобства алализа данных при моделироании)
gen_sim_on: if strcmp(G_SIM,"ON") generate

process(i_dbg_satah)
begin
  if i_dbg_satah(0).alayer.signature='1' then
    i_tst_val<='1';
  else
    i_tst_val<='0';
  end if;
end process;

end generate gen_sim_on;


----//#############################################
----//Задержка аппаратного запуска
----//#############################################
--m_hwstart : sata_hwstart_ctrl
--generic map
--(
--G_T05us     => selval(75, CI_SIM_T05us, strcmp(G_SIM, "OFF")), --//для частоты 150MHz
--G_DBGCS     => G_DBGCS,
--G_DBG       => G_DBG,
--G_SIM       => G_SIM
--)
--port map
--(
----------------------------------------------------
----
----------------------------------------------------
--p_in_ctrl      => p_in_usr_ctrl,
--
----------------------------------------------------
----Связь с модулям sata_raid.vhd
----------------------------------------------------
--p_in_hw_work   => i_hw_work,
--p_in_hw_start  => i_hw_start,
--p_out_hw_start => i_hw_start_dly,
--
--p_in_sh_cmddone=> i_usr_status.dmacfg.atadone,
--p_in_mstatus   => i_measure_status_out,
--
----------------------------------------------------
----Технологические сигналы
----------------------------------------------------
--p_in_tst       => p_in_tst,
--p_out_tst      => open,
--p_out_dbgcs    => i_dbgcs_hwstart_dly,
--
----------------------------------------------------
----System
----------------------------------------------------
--p_in_clk       => g_refclkout,--//150MHz
--p_in_rst       => p_in_rst
--);


--//#############################################
--//Измерение задержек
--//#############################################
m_measure : sata_measure
generic map(
G_T05us     => selval(75, CI_SIM_T05us, strcmp(G_SIM, "OFF")), --//для частоты 150MHz
G_HDD_COUNT => G_HDD_COUNT,
G_DBGCS     => G_DBGCS,
G_DBG       => G_DBG,
G_SIM       => G_SIM
)
port map(
--------------------------------------------------
--Связь с модулем dsn_hdd.vhd
--------------------------------------------------
p_in_ctrl      => p_in_usr_ctrl,
p_out_status   => i_measure_status_out,

--------------------------------------------------
--Связь с модулям sata_host.vhd
--------------------------------------------------
p_in_sh_busy   => i_usr_status.ch_bsy,
p_in_dev_busy  => i_measure_dev_busy,
p_in_sh_status => i_measure_sh_status,

--------------------------------------------------
--Технологические сигналы
--------------------------------------------------
p_in_tst       => p_in_tst,
p_out_tst      => i_tst_measure_out,
p_out_dbgcs    => i_dbgcs_measure,

--------------------------------------------------
--System
--------------------------------------------------
p_in_clk       => g_refclkout,--//150MHz
p_in_rst       => p_in_rst
);

i_measure_dev_busy<=i_usr_status.dev_bsy and i_usr_status.dev_rdy;

p_out_measure<=i_measure_status_out;


--//#############################################
--//RAID контроллер
--//#############################################
m_raid_ctrl : sata_raid
generic map(
G_HDD_COUNT => G_HDD_COUNT,
G_DBGCS     => G_DBGCS,
G_DBG       => G_DBG,
G_SIM       => G_SIM
)
port map(
--------------------------------------------------
--Связь с модулем dsn_hdd.vhd
--------------------------------------------------
p_in_usr_ctrl           => p_in_usr_ctrl,
p_out_usr_status        => i_usr_status,

--//ctrl - hw start
p_out_hw_work           => open,--i_hw_work,
p_out_hw_start          => open,--i_hw_start,
p_in_hw_start           => '0', --i_hw_start_dly,

--//cmdpkt
p_in_usr_cxd            => p_in_usr_cxd,
p_in_usr_cxd_wr         => p_in_usr_cxd_wr,

--//txbuf
p_in_usr_txd            => p_in_usr_txd,
p_out_usr_txd_rd        => p_out_usr_txd_rd,
p_in_usr_txbuf_empty    => p_in_usr_txbuf_empty,

--//rxbuf
p_out_usr_rxd           => p_out_usr_rxd,
p_out_usr_rxd_wr        => p_out_usr_rxd_wr,
p_in_usr_rxbuf_full     => p_in_usr_rxbuf_full,

--------------------------------------------------
--Связь с модулями sata_host.vhd
--------------------------------------------------
p_in_sh_status          => i_uap_status,
p_out_sh_ctrl           => i_uap_ctrl,
--/cmdbuf
p_out_sh_cxd            => i_uap_cxd,
p_out_sh_cxd_sof_n      => i_uap_cxd_sof_n,
p_out_sh_cxd_eof_n      => i_uap_cxd_eof_n,
p_out_sh_cxd_src_rdy_n  => i_uap_cxd_src_rdy_n,
--/txbuf
p_out_sh_txd            => i_uap_txd,
p_out_sh_txd_wr         => i_uap_txd_wr,
--/rxbuf
p_in_sh_rxd             => i_uap_rxd,
p_out_sh_rxd_rd         => i_uap_rxd_rd,
--/bufstatus
p_in_sh_txbuf_status    => i_uap_txbuf_status,
p_in_sh_rxbuf_status    => i_uap_rxbuf_status,

--------------------------------------------------
--Технологические сигналы
--------------------------------------------------
p_in_tst                => p_in_tst,
p_out_tst               => i_tst_raidctrl_out,
p_out_dbgcs             => i_dbgcs_raid,

p_in_sh_tst             => i_uap_tst_sh_out,
p_out_sh_tst            => i_uap_tst_sh_in,

--------------------------------------------------
--System
--------------------------------------------------
p_in_clk                => p_in_clk,
p_in_rst                => p_in_rst
);


--//#############################################
--//
--//#############################################
p_out_usr_status<=i_usr_status;

p_out_sata_refclkout<=g_refclkout;
p_out_sata_gt_plldet<=AND_reduce(i_sh_gt_pllkdet(C_SH_COUNT_MAX(G_HDD_COUNT-1)-1 downto 0));
p_out_sata_dcm_lock<=i_sh_dcm_lock;

p_out_dbgcs.sh<=i_dbgcs_satah;
p_out_dbgcs.raid<=i_dbgcs_raid;
p_out_dbgcs.measure<=i_dbgcs_measure;
--p_out_dbgcs.hwstart_dly<=i_dbgcs_hwstart_dly;


--//#############################################
--//Тактирование модулей sata_host.vhd
--//#############################################
i_sh_dcm_rst(C_SH_MAIN_NUM)<=not i_sh_gt_pllkdet(C_SH_MAIN_NUM); --//сброс sata_dcm

m_dcm : sata_dcm
generic map(
G_GT_DBUS => G_GT_DBUS
)
port map(
p_out_dcm_gclk0  => g_sh_dcm_clk,
p_out_dcm_gclk2x => g_sh_dcm_clk2x,
p_out_dcm_gclkdv => g_sh_dcm_clk2div,

p_out_dcmlock    => i_sh_dcm_lock,

p_out_refclkout  => g_refclkout,
p_in_clk         => i_sh_gt_refclkout(C_SH_MAIN_NUM), --//150MHz
p_in_rst         => i_sh_dcm_rst(C_SH_MAIN_NUM)
);

m_gt_clkmux : sata_player_gt_clkmux
generic map(
G_HDD_COUNT  => G_HDD_COUNT,
G_SIM        => G_SIM
)
port map(
p_out_optrefclksel => i_sh_gt_optrefclksel,
p_out_optrefclk    => i_sh_gt_optrefclkin,
p_in_optrefclk     => i_sh_gt_optrefclkout
);



--//#############################################
--//Размножение модулей sata_host.vhd
--//#############################################
gen_satah : for sh_idx in 0 to C_SH_COUNT_MAX(G_HDD_COUNT-1)-1 generate

--//сигналы для связи с sata_raid.vhd
gen_satah_ch : for ch_idx in 0 to C_GTCH_COUNT_MAX-1 generate

--//Для модуля измерения
i_measure_sh_status(C_GTCH_COUNT_MAX*sh_idx+ch_idx).usr<=i_sh_status(sh_idx)(ch_idx).usr;

--//Сброс sata_connector
i_sh_buf_rst(sh_idx)(ch_idx)<=p_in_rst or
                              p_in_usr_ctrl(C_USR_GCTRL_ERR_CLR_BIT) or
                              not i_sh_status(sh_idx)(ch_idx).sstatus(C_ASSTAT_DET_BIT_L+1);--//Link Establish

--//статусы и управление модулем sata_host.vhd
i_uap_status(C_GTCH_COUNT_MAX*sh_idx+ch_idx)<=i_sh_status(sh_idx)(ch_idx);
i_sh_ctrl(sh_idx)(ch_idx)<=i_uap_ctrl(C_GTCH_COUNT_MAX*sh_idx+ch_idx);

--//cmdbuf
i_u_cxd(sh_idx)(ch_idx)<=i_uap_cxd(C_GTCH_COUNT_MAX*sh_idx+ch_idx);
i_u_cxd_sof_n(sh_idx)(ch_idx)<=i_uap_cxd_sof_n(C_GTCH_COUNT_MAX*sh_idx+ch_idx);
i_u_cxd_eof_n(sh_idx)(ch_idx)<=i_uap_cxd_eof_n(C_GTCH_COUNT_MAX*sh_idx+ch_idx);
i_u_cxd_src_rdy_n(sh_idx)(ch_idx)<=i_uap_cxd_src_rdy_n(C_GTCH_COUNT_MAX*sh_idx+ch_idx);

--//txbuf
i_u_txd(sh_idx)(ch_idx)<=i_uap_txd(C_GTCH_COUNT_MAX*sh_idx+ch_idx);
i_u_txd_wr(sh_idx)(ch_idx)<=i_uap_txd_wr(C_GTCH_COUNT_MAX*sh_idx+ch_idx);

--//rxbuf
i_uap_rxd(C_GTCH_COUNT_MAX*sh_idx+ch_idx)<=i_u_rxd(sh_idx)(ch_idx);
i_u_rxd_rd(sh_idx)(ch_idx)<=i_uap_rxd_rd(C_GTCH_COUNT_MAX*sh_idx+ch_idx);

--//bufstatus
i_uap_txbuf_status(C_GTCH_COUNT_MAX*sh_idx+ch_idx)<=i_txbuf_status(sh_idx)(ch_idx);
i_uap_rxbuf_status(C_GTCH_COUNT_MAX*sh_idx+ch_idx)<=i_rxbuf_status(sh_idx)(ch_idx);

i_tst_sh_in(sh_idx)(ch_idx)<=i_uap_tst_sh_in(C_GTCH_COUNT_MAX*sh_idx+ch_idx);
i_uap_tst_sh_out(C_GTCH_COUNT_MAX*sh_idx+ch_idx)<=i_tst_sh_out(sh_idx)(ch_idx);


--//Debug/Sim
i_dbgcs_satah(C_GTCH_COUNT_MAX*sh_idx+ch_idx).spd<=i_dbgcs_sh_out(sh_idx)(ch_idx).spd;
i_dbgcs_satah(C_GTCH_COUNT_MAX*sh_idx+ch_idx).layer<=i_dbgcs_sh_out(sh_idx)(ch_idx).layer;

i_dbg_satah(C_GTCH_COUNT_MAX*sh_idx+ch_idx).alayer<=i_dbg_sh_out(sh_idx)(ch_idx).alayer;
i_dbg_satah(C_GTCH_COUNT_MAX*sh_idx+ch_idx).tlayer<=i_dbg_sh_out(sh_idx)(ch_idx).tlayer;
i_dbg_satah(C_GTCH_COUNT_MAX*sh_idx+ch_idx).llayer<=i_dbg_sh_out(sh_idx)(ch_idx).llayer;
i_dbg_satah(C_GTCH_COUNT_MAX*sh_idx+ch_idx).player<=i_dbg_sh_out(sh_idx)(ch_idx).player;

i_dbg_satah(C_GTCH_COUNT_MAX*sh_idx+ch_idx).txbuf.din<=i_u_txd(sh_idx)(ch_idx);
i_dbg_satah(C_GTCH_COUNT_MAX*sh_idx+ch_idx).txbuf.dout<=i_sh_txd(sh_idx)(ch_idx);
i_dbg_satah(C_GTCH_COUNT_MAX*sh_idx+ch_idx).txbuf.wr<=i_u_txd_wr(sh_idx)(ch_idx);
i_dbg_satah(C_GTCH_COUNT_MAX*sh_idx+ch_idx).txbuf.rd<=i_sh_txd_rd(sh_idx)(ch_idx);
i_dbg_satah(C_GTCH_COUNT_MAX*sh_idx+ch_idx).txbuf.status<=i_txbuf_status(sh_idx)(ch_idx);

i_dbg_satah(C_GTCH_COUNT_MAX*sh_idx+ch_idx).rxbuf.din<=i_sh_rxd(sh_idx)(ch_idx);
i_dbg_satah(C_GTCH_COUNT_MAX*sh_idx+ch_idx).rxbuf.dout<=i_u_rxd(sh_idx)(ch_idx);
i_dbg_satah(C_GTCH_COUNT_MAX*sh_idx+ch_idx).rxbuf.wr<=i_sh_rxd_wr(sh_idx)(ch_idx);
i_dbg_satah(C_GTCH_COUNT_MAX*sh_idx+ch_idx).rxbuf.rd<=i_u_rxd_rd(sh_idx)(ch_idx);
i_dbg_satah(C_GTCH_COUNT_MAX*sh_idx+ch_idx).rxbuf.status<=i_rxbuf_status(sh_idx)(ch_idx);


p_out_gt_sim_rst(C_GTCH_COUNT_MAX*sh_idx+ch_idx)<=i_sim_gt_rst(sh_idx)(ch_idx);
p_out_gt_sim_clk(C_GTCH_COUNT_MAX*sh_idx+ch_idx)<=i_sim_gt_clk(sh_idx)(ch_idx);

p_out_sim_gt_txdata(C_GTCH_COUNT_MAX*sh_idx+ch_idx)<=i_sim_gt_txdata(sh_idx)(ch_idx);
p_out_sim_gt_txcharisk(C_GTCH_COUNT_MAX*sh_idx+ch_idx)<=i_sim_gt_txcharisk(sh_idx)(ch_idx);
p_out_sim_gt_txcomstart(C_GTCH_COUNT_MAX*sh_idx+ch_idx)<=i_sim_gt_txcomstart(sh_idx)(ch_idx);

i_sim_gt_rxdata(sh_idx)(ch_idx)<=p_in_sim_gt_rxdata(C_GTCH_COUNT_MAX*sh_idx+ch_idx);
i_sim_gt_rxcharisk(sh_idx)(ch_idx)<=p_in_sim_gt_rxcharisk(C_GTCH_COUNT_MAX*sh_idx+ch_idx);
i_sim_gt_rxstatus(sh_idx)(ch_idx)<=p_in_sim_gt_rxstatus(C_GTCH_COUNT_MAX*sh_idx+ch_idx);
i_sim_gt_rxelecidle(sh_idx)(ch_idx)<=p_in_sim_gt_rxelecidle(C_GTCH_COUNT_MAX*sh_idx+ch_idx);
i_sim_gt_rxdisperr(sh_idx)(ch_idx)<=p_in_sim_gt_rxdisperr(C_GTCH_COUNT_MAX*sh_idx+ch_idx);
i_sim_gt_rxnotintable(sh_idx)(ch_idx)<=p_in_sim_gt_rxnotintable(C_GTCH_COUNT_MAX*sh_idx+ch_idx);
i_sim_gt_rxbyteisaligned(sh_idx)(ch_idx)<=p_in_sim_gt_rxbyteisaligned(C_GTCH_COUNT_MAX*sh_idx+ch_idx);

end generate gen_satah_ch;



--//Согласующие буфера между sata_raid.vhd <-> sata_host.vhd:
m_satah_buf : sata_connector
generic map(
G_SATAH_CH_COUNT  => C_SH_CH_COUNT(sh_idx)(C_GTCH_COUNT_MAX-1)(G_HDD_COUNT-1),
G_DBG             => G_DBG,
G_SIM             => G_SIM
)
port map(
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
p_in_sh_status          => i_sh_status(sh_idx),

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
p_in_rst                => i_sh_buf_rst(sh_idx)
);


--//SATA Контроллер
m_satah : sata_host
generic map(
G_SATAH_COUNT_MAX => C_SH_COUNT_MAX(G_HDD_COUNT-1),
G_SATAH_NUM       => sh_idx,
G_SATAH_CH_COUNT  => C_SH_CH_COUNT(sh_idx)(C_GTCH_COUNT_MAX-1)(G_HDD_COUNT-1),
G_GT_DBUS         => G_GT_DBUS,
G_DBG             => G_DBG,
G_DBGCS           => G_DBGCS,
G_SIM             => G_SIM
)
port map(
--------------------------------------------------
--Sata Driver
--------------------------------------------------
p_out_sata_txn              => p_out_sata_txn(((C_GTCH_COUNT_MAX*(sh_idx+1))-1) downto (C_GTCH_COUNT_MAX*sh_idx)),
p_out_sata_txp              => p_out_sata_txp(((C_GTCH_COUNT_MAX*(sh_idx+1))-1) downto (C_GTCH_COUNT_MAX*sh_idx)),
p_in_sata_rxn               => p_in_sata_rxn(((C_GTCH_COUNT_MAX*(sh_idx+1))-1) downto (C_GTCH_COUNT_MAX*sh_idx)),
p_in_sata_rxp               => p_in_sata_rxp(((C_GTCH_COUNT_MAX*(sh_idx+1))-1) downto (C_GTCH_COUNT_MAX*sh_idx)),

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
--p_out_cmdfifo_dst_rdy_n     => open,

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
p_in_tst                    => i_tst_sh_in(sh_idx),
p_out_tst                   => i_tst_sh_out(sh_idx),

--------------------------------------------------
--//Debug/Sim
--------------------------------------------------
p_out_dbg                   => i_dbg_sh_out(sh_idx),
p_out_dbgcs                 => i_dbgcs_sh_out(sh_idx),

p_out_sim_gt_txdata         => i_sim_gt_txdata(sh_idx),
p_out_sim_gt_txcharisk      => i_sim_gt_txcharisk(sh_idx),
p_out_sim_gt_txcomstart     => i_sim_gt_txcomstart(sh_idx),
p_in_sim_gt_rxdata          => i_sim_gt_rxdata(sh_idx),
p_in_sim_gt_rxcharisk       => i_sim_gt_rxcharisk(sh_idx),
p_in_sim_gt_rxstatus        => i_sim_gt_rxstatus(sh_idx),
p_in_sim_gt_rxelecidle      => i_sim_gt_rxelecidle(sh_idx),
p_in_sim_gt_rxdisperr       => i_sim_gt_rxdisperr(sh_idx),
p_in_sim_gt_rxnotintable    => i_sim_gt_rxnotintable(sh_idx),
p_in_sim_gt_rxbyteisaligned => i_sim_gt_rxbyteisaligned(sh_idx),
p_out_sim_rst               => i_sim_gt_rst(sh_idx),
p_out_sim_clk               => i_sim_gt_clk(sh_idx),

--------------------------------------------------
--System
--------------------------------------------------
p_in_sys_dcm_gclk2div       => g_sh_dcm_clk2div,
p_in_sys_dcm_gclk           => g_sh_dcm_clk,
p_in_sys_dcm_gclk2x         => g_sh_dcm_clk2x,
p_in_sys_dcm_lock           => i_sh_dcm_lock,

p_out_gt_pllkdet            => i_sh_gt_pllkdet(sh_idx),
p_out_gt_refclk             => i_sh_gt_refclkout(sh_idx),
p_in_gt_drpclk              => g_sh_dcm_clk2div,--g_refclkout,
p_in_gt_refclk              => p_in_sata_refclk(sh_idx),

p_in_optrefclksel           => i_sh_gt_optrefclksel(sh_idx),
p_in_optrefclk              => i_sh_gt_optrefclkin(sh_idx),
p_out_optrefclk             => i_sh_gt_optrefclkout(sh_idx),

p_in_rst                    => p_in_rst
);

end generate gen_satah;


--END MAIN
end behavioral;
