-------------------------------------------------------------------------
-- Company     : Linkos
-- Engineer    : Golovachenko Victor
--
-- Create Date : 20.01.2011 11:43:14
-- Module Name : hdd_simple_main
--
-- Назначение/Описание :
--
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

---- synopsys translate_off
--library unisim;
--use unisim.vcomponents.all;
---- synopsys translate_on
Library UNISIM;
use UNISIM.vcomponents.all;

library work;
use work.vicg_common_pkg.all;
use work.prj_cfg.all;
use work.prj_def.all;
use work.sata_pkg.all;
use work.sata_sim_lite_pkg.all;
use work.sata_raid_pkg.all;
use work.dsn_hdd_pkg.all;

entity hdd_simple_main is
generic
(
G_SIM        : string:="OFF"
);
port
(
--------------------------------------------------
--Светодиоды (Для платы ML505)
--------------------------------------------------
pin_out_led                      : out   std_logic_vector(7 downto 0);
pin_out_led_C                    : out   std_logic;
pin_out_led_E                    : out   std_logic;
pin_out_led_N                    : out   std_logic;
pin_out_led_S                    : out   std_logic;
pin_out_led_W                    : out   std_logic;

pin_out_TP                       : out   std_logic_vector(7 downto 0);

pin_in_btn_C                     : in    std_logic;
pin_in_btn_E                     : in    std_logic;
pin_in_btn_N                     : in    std_logic;
pin_in_btn_S                     : in    std_logic;
pin_in_btn_W                     : in    std_logic;

--------------------------------------------------
-- Local bus
--------------------------------------------------
lreset_l              : in    std_logic;
lclk                  : in    std_logic;
--lwrite                : in    std_logic;
--lads_l                : in    std_logic;
--lblast_l              : in    std_logic;
--lbe_l                 : in    std_logic_vector(32/8-1 downto 0);--(3 downto 0);
--lad                   : inout std_logic_vector(32-1 downto 0);--(31 downto 0);
--lbterm_l              : inout std_logic;
--lready_l              : inout std_logic;
--fholda                : in    std_logic;
--finto_l               : out   std_logic;

--------------------------------------------------
--SATA
--------------------------------------------------
pin_out_sata_txn      : out   std_logic_vector((C_GTCH_COUNT_MAX*C_SH_COUNT_MAX(C_HDD_COUNT-1))-1 downto 0);
pin_out_sata_txp      : out   std_logic_vector((C_GTCH_COUNT_MAX*C_SH_COUNT_MAX(C_HDD_COUNT-1))-1 downto 0);
pin_in_sata_rxn       : in    std_logic_vector((C_GTCH_COUNT_MAX*C_SH_COUNT_MAX(C_HDD_COUNT-1))-1 downto 0);
pin_in_sata_rxp       : in    std_logic_vector((C_GTCH_COUNT_MAX*C_SH_COUNT_MAX(C_HDD_COUNT-1))-1 downto 0);
pin_in_sata_clk_n     : in    std_logic_vector(C_SH_COUNT_MAX(C_HDD_COUNT-1)-1 downto 0);
pin_in_sata_clk_p     : in    std_logic_vector(C_SH_COUNT_MAX(C_HDD_COUNT-1)-1 downto 0);

--------------------------------------------------
-- Reference clock 200MHz
--------------------------------------------------
refclk_n              : in    std_logic;
refclk_p              : in    std_logic
);
end entity;

architecture struct of hdd_simple_main is

--component ROC generic (WIDTH : Time := 500 ns); port (O : out std_ulogic := '1'); end component;
component IBUFDS            port(I : in  std_logic; IB : in  std_logic; O  : out std_logic);end component;
component IBUFGDS_LVPECL_25 port(I : in  std_logic; IB : in  std_logic; O  : out std_logic);end component;
component BUFG              port(I : in  std_logic; O  : out std_logic);end component;

component dbgcs_iconx1
  PORT (
    CONTROL0 : INOUT STD_LOGIC_VECTOR(35 DOWNTO 0));
--    CONTROL1 : INOUT STD_LOGIC_VECTOR(35 DOWNTO 0));

end component;

component dbgcs_sata_layer
  PORT (
    CONTROL : INOUT STD_LOGIC_VECTOR(35 DOWNTO 0);
    CLK : IN STD_LOGIC;
    DATA : IN STD_LOGIC_VECTOR(122 DOWNTO 0);
    TRIG0 : IN STD_LOGIC_VECTOR(41 DOWNTO 0)
    );
end component;

--component dbgcs_sata_rambuf
--  PORT (
--    CONTROL : INOUT STD_LOGIC_VECTOR(35 DOWNTO 0);
--    CLK : IN STD_LOGIC;
--    DATA : IN STD_LOGIC_VECTOR(104 DOWNTO 0);
--    TRIG0 : IN STD_LOGIC_VECTOR(11 DOWNTO 0)
--    );
--end component;

component fpga_test_01
generic(
G_BLINK_T05   : integer:=10#125#; -- 1/2 периода мигания светодиода.(время в ms)
G_CLK_T05us   : integer:=10#1000# -- кол-во периодов частоты порта p_in_clk
                                  -- укладывающиеся в 1/2 периода 1us
);
port
(
p_out_test_led : out   std_logic;--//мигание сведодиода
p_out_test_done: out   std_logic;--//сигнал переходи в '1' через 3 сек.

p_out_1us      : out   std_logic;
p_out_1ms      : out   std_logic;
-------------------------------
--System
-------------------------------
p_in_clk       : in    std_logic;
p_in_rst       : in    std_logic
);
end component;

signal i_dbgcs_sh0_layer                : std_logic_vector(35 downto 0);
--signal i_dbgcs_hdd_rambuf               : std_logic_vector(35 downto 0);

signal i_usr_rst                        : std_logic;
signal rst_sys_n                        : std_logic;
--signal rst_sys                          : std_logic;

signal i_refclk200MHz                   : std_logic;

signal g_host_clk                       : std_logic;
signal i_dsn_hdd_rst                    : std_logic;
signal i_hdd_gt_refclk150               : std_logic_vector(C_SH_COUNT_MAX(C_HDD_COUNT-1)-1 downto 0);
signal g_hdd_gt_refclkout               : std_logic;
signal i_hdd_gt_plldet                  : std_logic;
signal i_hdd_dcm_lock                   : std_logic;

signal i_hdd_rbuf_cfg                   : THDDRBufCfg;
signal i_hdd_rbuf_status                : THDDRBufStatus;

signal i_hdd_txdata                     : std_logic_vector(31 downto 0);
signal i_hdd_txdata_wd                  : std_logic;
signal i_hdd_txbuf_full                 : std_logic;

signal i_hdd_rxdata                     : std_logic_vector(31 downto 0);
signal i_hdd_rxdata_rd                  : std_logic;
signal i_hdd_rxbuf_empty                : std_logic;

signal i_hdd_cfg_rxdata                 : std_logic_vector(15 downto 0);

signal i_cfgdev_adr                     : std_logic_vector(7 downto 0);
signal i_cfgdev_adr_ld                  : std_logic;
signal i_cfgdev_adr_fifo                : std_logic;
signal i_cfgdev_txdata                  : std_logic_vector(15 downto 0);
signal i_dev_cfg_wd                     : std_logic_vector(C_CFGDEV_COUNT-1 downto 0);
signal i_dev_cfg_rd                     : std_logic_vector(C_CFGDEV_COUNT-1 downto 0);
signal i_dev_cfg_done                   : std_logic_vector(C_CFGDEV_COUNT-1 downto 0);

signal i_hdd_module_rdy                 : std_logic;
signal i_hdd_module_error               : std_logic;
signal i_hdd_busy                       : std_logic;
signal i_hdd_hirq                       : std_logic;
signal i_hdd_done                       : std_logic;

signal i_hdd_dbgcs                      : TSH_dbgcs_exp;
--signal i_hddrambuf_dbgcs                : TSH_ila;
--signal i_hdd_rambuf_dbgcs               : TSH_ila;

signal i_hdd_sim_gtp_txdata             : TBus32_SHCountMax;
signal i_hdd_sim_gtp_txcharisk          : TBus04_SHCountMax;
signal i_hdd_sim_gtp_txcomstart         : std_logic_vector(C_HDD_COUNT_MAX-1 downto 0);
signal i_hdd_sim_gtp_rxdata             : TBus32_SHCountMax;
signal i_hdd_sim_gtp_rxcharisk          : TBus04_SHCountMax;
signal i_hdd_sim_gtp_rxstatus           : TBus03_SHCountMax;
signal i_hdd_sim_gtp_rxelecidle         : std_logic_vector(C_HDD_COUNT_MAX-1 downto 0);
signal i_hdd_sim_gtp_rxdisperr          : TBus04_SHCountMax;
signal i_hdd_sim_gtp_rxnotintable       : TBus04_SHCountMax;
signal i_hdd_sim_gtp_rxbyteisaligned    : std_logic_vector(C_HDD_COUNT_MAX-1 downto 0);
signal i_hdd_sim_gtp_sim_rst            : std_logic_vector(C_HDD_COUNT_MAX-1 downto 0);
signal i_hdd_sim_gtp_sim_clk            : std_logic_vector(C_HDD_COUNT_MAX-1 downto 0);

signal i_hdd_dbgled                     : THDDLed_SHCountMax;

signal i_hdd_tst_out                    : std_logic_vector(31 downto 0);

signal i_test01_led                     : std_logic;

signal sr_hdd_cmd_start                 : std_logic_vector(0 to 6);

signal tst_clr                          : std_logic;


--//MAIN
begin



--***********************************************************
--//RESET модулей
--***********************************************************
rst_sys_n <= lreset_l;
i_dsn_hdd_rst <=not rst_sys_n or i_usr_rst;--

--***********************************************************
--          Установка частот проекта:
--***********************************************************
--//Input 200MHz reference clock for IDELAY / ODELAY elements
ibufg_refclk : IBUFGDS_LVPECL_25 port map(I  => refclk_p, IB => refclk_n, O  => i_refclk200MHz);
bufg_refclk  : BUFG              port map(I  => i_refclk200MHz, O  => g_host_clk);

--//Input 150MHz reference clock for SATA
gen_sata_gt : for i in 0 to C_SH_COUNT_MAX(C_HDD_COUNT-1)-1 generate
ibufds_hdd_gt_refclk : IBUFDS port map(I  => pin_in_sata_clk_p(i), IB => pin_in_sata_clk_n(i), O  => i_hdd_gt_refclk150(i));
end generate gen_sata_gt;


--***********************************************************
--Проект Накопителя - dsn_hdd.vhd
--***********************************************************
gen_satah: for i in 0 to C_HDD_COUNT_MAX-1 generate
i_hdd_sim_gtp_rxdata(i)<=(others=>'0');
i_hdd_sim_gtp_rxcharisk(i)<=(others=>'0');
i_hdd_sim_gtp_rxstatus(i)<=(others=>'0');
i_hdd_sim_gtp_rxelecidle(i)<='0';
i_hdd_sim_gtp_rxdisperr(i)<=(others=>'0');
i_hdd_sim_gtp_rxnotintable(i)<=(others=>'0');
i_hdd_sim_gtp_rxbyteisaligned(i)<='0';
end generate gen_satah;

m_hdd : dsn_hdd
generic map
(
G_MODULE_USE=> C_USE_HDD,
G_HDD_COUNT => C_HDD_COUNT,
G_GT_DBUS   => C_HDD_GT_DBUS,
G_DBG       => C_DBG_HDD,
G_DBGCS     => G_DBGCS_HDD,
G_SIM       => G_SIM
)
port map
(
-------------------------------
-- Конфигурирование модуля dsn_hdd.vhd (p_in_cfg_clk domain)
-------------------------------
p_in_cfg_clk          => g_host_clk,

p_in_cfg_adr          => i_cfgdev_adr,
p_in_cfg_adr_ld       => i_cfgdev_adr_ld,
p_in_cfg_adr_fifo     => i_cfgdev_adr_fifo,

p_in_cfg_txdata       => i_cfgdev_txdata,
p_in_cfg_wd           => i_dev_cfg_wd(C_CFGDEV_HDD),

p_out_cfg_rxdata      => i_hdd_cfg_rxdata,
p_in_cfg_rd           => i_dev_cfg_rd(C_CFGDEV_HDD),

p_in_cfg_done         => i_dev_cfg_done(C_CFGDEV_HDD),
p_in_cfg_rst          => i_dsn_hdd_rst,

-------------------------------
-- STATUS модуля dsn_hdd.vhd
-------------------------------
p_out_hdd_rdy         => i_hdd_module_rdy,
p_out_hdd_error       => i_hdd_module_error,
p_out_hdd_busy        => i_hdd_busy,
p_out_hdd_irq         => i_hdd_hirq,
p_out_hdd_done        => i_hdd_done,

-------------------------------
-- Связь с Источниками/Приемниками данных накопителя
-------------------------------
p_out_rbuf_cfg        => i_hdd_rbuf_cfg,
p_in_rbuf_status      => i_hdd_rbuf_status,

p_in_hdd_txd          => i_hdd_txdata,
p_in_hdd_txd_wr       => i_hdd_txdata_wd,
p_out_hdd_txbuf_full  => i_hdd_txbuf_full,

p_out_hdd_rxd         => i_hdd_rxdata,
p_in_hdd_rxd_rd       => i_hdd_rxdata_rd,
p_out_hdd_rxbuf_empty => i_hdd_rxbuf_empty,

--------------------------------------------------
--Sata Driver
--------------------------------------------------
p_out_sata_txn        => pin_out_sata_txn,
p_out_sata_txp        => pin_out_sata_txp,
p_in_sata_rxn         => pin_in_sata_rxn,
p_in_sata_rxp         => pin_in_sata_rxp,

p_in_sata_refclk      => i_hdd_gt_refclk150,
p_out_sata_refclkout  => g_hdd_gt_refclkout,
p_out_sata_gt_plldet  => i_hdd_gt_plldet,
p_out_sata_dcm_lock   => i_hdd_dcm_lock,

---------------------------------------------------------------------------
--Технологический порт
---------------------------------------------------------------------------
p_in_tst              => "00000000000000000000000000000000",
p_out_tst             => i_hdd_tst_out,

--------------------------------------------------
--//Debug/Sim
--------------------------------------------------
p_out_dbgcs                 => i_hdd_dbgcs,
p_out_dbgled                => i_hdd_dbgled,

p_out_sim_gtp_txdata        => i_hdd_sim_gtp_txdata,
p_out_sim_gtp_txcharisk     => i_hdd_sim_gtp_txcharisk,
p_out_sim_gtp_txcomstart    => i_hdd_sim_gtp_txcomstart,
p_in_sim_gtp_rxdata         => i_hdd_sim_gtp_rxdata,
p_in_sim_gtp_rxcharisk      => i_hdd_sim_gtp_rxcharisk,
p_in_sim_gtp_rxstatus       => i_hdd_sim_gtp_rxstatus,
p_in_sim_gtp_rxelecidle     => i_hdd_sim_gtp_rxelecidle,
p_in_sim_gtp_rxdisperr      => i_hdd_sim_gtp_rxdisperr,
p_in_sim_gtp_rxnotintable   => i_hdd_sim_gtp_rxnotintable,
p_in_sim_gtp_rxbyteisaligned=> i_hdd_sim_gtp_rxbyteisaligned,
p_out_gtp_sim_rst           => i_hdd_sim_gtp_sim_rst,
p_out_gtp_sim_clk           => i_hdd_sim_gtp_sim_clk,

--------------------------------------------------
--System
--------------------------------------------------
p_in_clk           => lclk,
p_in_rst           => i_dsn_hdd_rst
);


i_hdd_rbuf_status.rdy  <='0';
i_hdd_rbuf_status.err  <=pin_in_btn_E or pin_in_btn_W;
i_hdd_rbuf_status.done <=pin_in_btn_E and pin_in_btn_W;


--//----------------------------------
--//Технологические сигналы
--//----------------------------------
i_usr_rst<=pin_in_btn_N;

tst_clr<=OR_reduce(i_hdd_rxdata) or OR_reduce(i_hdd_cfg_rxdata) or i_hdd_txbuf_full or i_hdd_rxbuf_empty or
        i_hdd_gt_plldet or i_hdd_hirq or i_hdd_done or i_hdd_module_rdy or i_hdd_module_error or
        i_hdd_rbuf_cfg.bufrst or i_hdd_rbuf_cfg.errclr or i_hdd_rbuf_cfg.dmacfg.wr_start or
        i_hdd_rbuf_cfg.dmacfg.sw_mode or i_hdd_rbuf_cfg.dmacfg.hw_mode or OR_reduce(i_hdd_rbuf_cfg.mem_trn) or OR_reduce(i_hdd_rbuf_cfg.mem_adr);

--//J5 /pin2
pin_out_TP(0)<=OR_reduce(i_hdd_tst_out) or pin_in_btn_C or pin_in_btn_E;
--//J6
pin_out_TP(1)<='0';
pin_out_TP(2)<='0';
pin_out_TP(3)<='0';
pin_out_TP(4)<='0';
pin_out_TP(5)<='0';
pin_out_TP(6)<='0';
pin_out_TP(7)<='0';


--Светодиоды
pin_out_led_E<=i_hdd_gt_plldet and i_hdd_dcm_lock;
pin_out_led_N<=i_dsn_hdd_rst;
pin_out_led_S<=i_test01_led;
pin_out_led_W<=i_hdd_dbgled(0).spd(1) when pin_in_btn_W='0' else i_hdd_dbgled(1).spd(1);
pin_out_led_C<=i_hdd_dbgled(0).spd(0) when pin_in_btn_W='0' else i_hdd_dbgled(1).spd(0);


pin_out_led(0)<=i_hdd_busy when pin_in_btn_S='0' else tst_clr;
pin_out_led(1)<='0';
pin_out_led(2)<=i_hdd_dbgled(1).err;
pin_out_led(3)<=i_hdd_dbgled(1).rdy;

pin_out_led(4)<=i_hdd_dbgled(1).link;
pin_out_led(5)<=i_hdd_dbgled(0).err;
pin_out_led(6)<=i_hdd_dbgled(0).rdy;
pin_out_led(7)<=i_hdd_dbgled(0).link;



m_test01: fpga_test_01
generic map(
G_BLINK_T05   =>10#250#, -- 1/2 периода мигания светодиода.(время в ms)
G_CLK_T05us   =>10#75#   -- 05us - 150MHz
)
port map
(
p_out_test_led => i_test01_led,
p_out_test_done=> open,

p_out_1us      => open,
p_out_1ms      => open,
-------------------------------
--System
-------------------------------
p_in_clk       => g_hdd_gt_refclkout,
p_in_rst       => i_dsn_hdd_rst
);


gen_txd: for i in 0 to i_hdd_txdata'length-1 generate
i_hdd_txdata(i)<=pin_in_btn_W xor pin_in_btn_S;
end generate gen_txd;

i_hdd_txdata_wd<=pin_in_btn_S;
i_hdd_rxdata_rd<=pin_in_btn_E;


i_dev_cfg_done(C_CFGDEV_HDD)<='0';
i_dev_cfg_rd(C_CFGDEV_HDD)<=pin_in_btn_E;
i_cfgdev_adr<=i_cfgdev_txdata(i_cfgdev_adr'range);
i_cfgdev_adr_ld<='1' when i_cfgdev_txdata=(i_cfgdev_txdata'range =>'0') else '0';
i_cfgdev_adr_fifo<='1';

process(i_dsn_hdd_rst,g_host_clk)
begin
  if i_dsn_hdd_rst='1' then
    sr_hdd_cmd_start<=(others=>'0');
    i_cfgdev_txdata<=(others=>'0');
    i_dev_cfg_wd<=(others=>'0');

  elsif g_host_clk'event and g_host_clk='1' then
    sr_hdd_cmd_start<=pin_in_btn_C & sr_hdd_cmd_start(0 to 5);

    if sr_hdd_cmd_start(5)='1' and sr_hdd_cmd_start(6)='0' then
      i_dev_cfg_wd(C_CFGDEV_HDD)<='1';

    elsif i_dev_cfg_wd(C_CFGDEV_HDD)='1' then
      if i_cfgdev_txdata=CONV_STD_LOGIC_VECTOR(C_USRAPP_CMDPKT_SIZE_WORD-1, i_cfgdev_txdata'length) then
        i_cfgdev_txdata<=(others=>'0');
        i_dev_cfg_wd(C_CFGDEV_HDD)<='0';
      else
        i_cfgdev_txdata<=i_cfgdev_txdata + 1;
      end if;

    end if;
  end if;
end process;


gen_dbgcs : if strcmp(G_DBGCS_HDD,"ON") generate

m_dbgcs_icon : dbgcs_iconx1
port map(
CONTROL0 => i_dbgcs_sh0_layer --
--CONTROL1 => i_dbgcs_hdd_rambuf
--CONTROL2 => i_hdd_dbgcs.raid,
);

m_dbgcs_sh0_layer : dbgcs_sata_layer
port map
(
CONTROL => i_dbgcs_sh0_layer,
CLK     => i_hdd_dbgcs.sh(0).layer.clk,
DATA    => i_hdd_dbgcs.sh(0).layer.data(122 downto 0),
TRIG0   => i_hdd_dbgcs.sh(0).layer.trig0(41 downto 0)
);

--m_dbgcs_hddrambuf : dbgcs_sata_rambuf
--port map
--(
--CONTROL => i_dbgcs_hdd_rambuf,
--CLK     => i_hdd_dbgcs.sh(0).layer.clk,
--DATA    => i_hddrambuf_dbgcs.data(104 downto 0),
--TRIG0   => i_hddrambuf_dbgcs.trig0(11 downto 0)
--);
--
--i_hddrambuf_dbgcs.trig0<=(others=>'0');
--i_hddrambuf_dbgcs.data<=(others=>'0');

--m_dbgcs_sh0_spd : sata_dbgcs_spd
--port map
--(
--CONTROL => i_dbgcs_sh0_spd,
--CLK     => i_hdd_dbgcs.sh(0).spd.clk,
--DATA    => i_hdd_dbgcs.sh(0).spd.data(122 downto 0),
--TRIG0   => i_hdd_dbgcs.sh(0).spd.trig0(41 downto 0)
--);
--m_dbgcs_sh0_raid : sata_dbgcs_raid
--port map
--(
--CONTROL => i_dbgcs_sh0_spd,
--CLK     => i_hdd_dbgcs.raid.clk,
--DATA    => i_hdd_dbgcs.raid.data(122 downto 0),
--TRIG0   => i_hdd_dbgcs.raid.trig0(41 downto 0)
--);

end generate gen_dbgcs;

end architecture;
