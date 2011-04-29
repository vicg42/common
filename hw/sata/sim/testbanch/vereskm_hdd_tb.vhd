-------------------------------------------------------------------------
-- Company     : Linkos
-- Engineer    : Golovachenko Victor
--
-- Create Date : 31.03.2011 19:15:18
-- Module Name : vereskm_hdd_tb
--
-- Description : Моделирование работы модуля dsn_hdd.vhd
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
use work.prj_def.all;
use work.sata_unit_pkg.all;
use work.sata_pkg.all;
use work.sata_raid_pkg.all;
use work.sata_sim_pkg.all;
use work.sata_sim_lite_pkg.all;
use work.dsn_hdd_pkg.all;
use work.memory_ctrl_pkg.all;

entity vereskm_hdd_tb is
generic
(
G_HDD_COUNT     : integer:=1;    --//Кол-во sata устр-в (min/max - 1/8)
G_GTP_DBUS      : integer:=16;
G_DBG           : string :="ON";
G_SIM           : string :="ON"
);
end vereskm_hdd_tb;

architecture behavior of vereskm_hdd_tb is

constant CI_SECTOR_SIZE_BYTE : integer:=selval(C_SECTOR_SIZE_BYTE, C_SIM_SECTOR_SIZE_DWORD*4, strcmp(G_SIM, "OFF"));

constant C_SATACLK_PERIOD : TIME := 6.6 ns; --150MHz
constant C_USRCLK_PERIOD  : TIME := 6.6*8 ns;

component dsn_hdd_rambuf
generic
(
G_MODULE_USE      : string:="ON";
G_HDD_RAMBUF_SIZE : integer:=23; --//(в BYTE). Определяется как 2 в степени G_HDD_RAMBUF_SIZE
G_SIM             : string:="OFF"
);
port
(
-------------------------------
-- Конфигурирование
-------------------------------
p_in_rbuf_cfg         : in    THDDRBufCfg;
p_out_rbuf_status     : out   THDDRBufStatus;--//Модуль находится в исходном состоянии + p_in_vbuf_empty and p_in_dwnp_buf_empty

--//--------------------------
--//Связь с буфером видеоданных
--//--------------------------
p_in_vbuf_dout        : in    std_logic_vector(31 downto 0);
p_out_vbuf_rd         : out   std_logic;
p_in_vbuf_empty       : in    std_logic;
p_in_vbuf_full        : in    std_logic;
p_in_vbuf_pfull       : in    std_logic;

--//--------------------------
--//Связь с модулем HDD
--//--------------------------
p_out_hdd_txd         : out   std_logic_vector(31 downto 0);
p_out_hdd_txd_wr      : out   std_logic;
p_in_hdd_txbuf_full   : in    std_logic;
--p_in_hdd_txbuf_empty  : in    std_logic;

p_in_hdd_rxd          : in    std_logic_vector(31 downto 0);
p_out_hdd_rxd_rd      : out   std_logic;
p_in_hdd_rxbuf_empty  : in    std_logic;

---------------------------------
-- Связь с memory_ctrl.vhd
---------------------------------
p_out_memarb_req      : out   std_logic;                    --//Запрос к арбитру ОЗУ на выполнение транзакции
p_in_memarb_en        : in    std_logic;                    --//Разрешение арбитра

p_out_mem_bank1h      : out   std_logic_vector(15 downto 0);
p_out_mem_ce          : out   std_logic;
p_out_mem_cw          : out   std_logic;
p_out_mem_rd          : out   std_logic;
p_out_mem_wr          : out   std_logic;
p_out_mem_term        : out   std_logic;
p_out_mem_adr         : out   std_logic_vector(C_MEMCTRL_ADDR_WIDTH - 1 downto 0);
p_out_mem_be          : out   std_logic_vector(C_MEMCTRL_DATA_WIDTH / 8 - 1 downto 0);
p_out_mem_din         : out   std_logic_vector(C_MEMCTRL_DATA_WIDTH - 1 downto 0);
p_in_mem_dout         : in    std_logic_vector(C_MEMCTRL_DATA_WIDTH - 1 downto 0);

p_in_mem_wf           : in    std_logic;
p_in_mem_wpf          : in    std_logic;
p_in_mem_re           : in    std_logic;
p_in_mem_rpe          : in    std_logic;

p_out_mem_clk         : out   std_logic;

-------------------------------
--Технологический
-------------------------------
p_in_tst              : in    std_logic_vector(31 downto 0);
p_out_tst             : out   std_logic_vector(31 downto 0);

-------------------------------
--System
-------------------------------
p_in_clk              : in    std_logic;
p_in_rst              : in    std_logic
);
end component;

signal i_sata_gtp_refclkmain      : std_logic;
signal p_in_clk                   : std_logic;
signal i_dsn_hdd_rst              : std_logic:='1';

signal i_sata_txn                 : std_logic_vector((C_GTCH_COUNT_MAX*C_SH_COUNT_MAX(G_HDD_COUNT-1))-1 downto 0);
signal i_sata_txp                 : std_logic_vector((C_GTCH_COUNT_MAX*C_SH_COUNT_MAX(G_HDD_COUNT-1))-1 downto 0);
signal i_sata_rxn                 : std_logic_vector((C_GTCH_COUNT_MAX*C_SH_COUNT_MAX(G_HDD_COUNT-1))-1 downto 0);
signal i_sata_rxp                 : std_logic_vector((C_GTCH_COUNT_MAX*C_SH_COUNT_MAX(G_HDD_COUNT-1))-1 downto 0);
signal i_sata_refclk              : std_logic_vector((C_SH_COUNT_MAX(G_HDD_COUNT-1))-1 downto 0);


signal p_in_usr_ctrl              : std_logic_vector(31 downto 0);

signal i_usr_raid_status          : TUsrStatus;

signal i_usr_cxdin                : std_logic_vector(15 downto 0);
signal i_usr_cxd_wr               : std_logic;

signal i_dsn_hdd_regcfg_start     : std_logic;
signal i_dsn_hdd_regcfg_done      : std_logic;

signal i_cfgdev_adr               : std_logic_vector(7 downto 0);
signal i_cfgdev_adr_ld            : std_logic;
signal i_cfgdev_adr_fifo          : std_logic;
signal i_cfgdev_txdata            : std_logic_vector(15 downto 0);
signal i_dev_cfg_wd               : std_logic_vector(C_CFGDEV_COUNT-1 downto 0);
signal i_dev_cfg_rd               : std_logic_vector(C_CFGDEV_COUNT-1 downto 0);
signal i_dev_cfg_done             : std_logic_vector(C_CFGDEV_COUNT-1 downto 0);

signal i_rbuf_cfg                 : THDDRBufCfg;
signal i_rbuf_status              : THDDRBufStatus;

signal i_usr_txd                  : std_logic_vector(31 downto 0);
signal i_usr_txd_wr               : std_logic;
signal i_usr_txbuf_full           : std_logic;
signal i_usr_rxd                  : std_logic_vector(31 downto 0);
signal i_usr_rxd_rd               : std_logic;
signal i_usr_rxbuf_empty          : std_logic;

signal i_hdd_rdy                  : std_logic;
signal i_hdd_error                : std_logic;
signal i_hdd_busy                 : std_logic;
signal i_hdd_irq                  : std_logic;
signal i_hdd_done                 : std_logic;

signal i_hdd_sim_gtp_txdata           : TBus32_SHCountMax;
signal i_hdd_sim_gtp_txcharisk        : TBus04_SHCountMax;
signal i_hdd_sim_gtp_rxdata           : TBus32_SHCountMax;
signal i_hdd_sim_gtp_rxcharisk        : TBus04_SHCountMax;
signal i_hdd_sim_gtp_rxstatus         : TBus03_SHCountMax;
signal i_hdd_sim_gtp_rxelecidle       : std_logic_vector(C_HDD_COUNT_MAX-1 downto 0);
signal i_hdd_sim_gtp_rxdisperr        : TBus04_SHCountMax;
signal i_hdd_sim_gtp_rxnotintable     : TBus04_SHCountMax;
signal i_hdd_sim_gtp_rxbyteisaligned  : std_logic_vector(C_HDD_COUNT_MAX-1 downto 0);
signal i_hdd_sim_gtp_rst              : std_logic_vector(C_HDD_COUNT_MAX-1 downto 0);
signal i_hdd_sim_gtp_clk              : std_logic_vector(C_HDD_COUNT_MAX-1 downto 0);

signal i_hdd_mem_bank1h               : std_logic_vector(15 downto 0);
signal i_hdd_mem_ce                   : std_logic;
signal i_hdd_mem_cw                   : std_logic;
signal i_hdd_mem_rd                   : std_logic;
signal i_hdd_mem_wr                   : std_logic;
signal i_hdd_mem_term                 : std_logic;
signal i_hdd_mem_adr                  : std_logic_vector(C_MEMCTRL_ADDR_WIDTH - 1 downto 0);
signal i_hdd_mem_be                   : std_logic_vector(C_MEMCTRL_DATA_WIDTH / 8 - 1 downto 0);
signal i_hdd_mem_din                  : std_logic_vector(C_MEMCTRL_DATA_WIDTH - 1 downto 0);
signal i_hdd_mem_dout                 : std_logic_vector(C_MEMCTRL_DATA_WIDTH - 1 downto 0);

signal i_hdd_mem_wf                   : std_logic;
signal i_hdd_mem_wpf                  : std_logic;
signal i_hdd_mem_re                   : std_logic;
signal i_hdd_mem_rpe                  : std_logic;

signal tst_hdd_out                : std_logic_vector(31 downto 0);

signal i_loopback                 : std_logic;
signal sr_cmdbusy                 : std_logic_vector(0 to 1);
signal i_cmddone_det_clr          : std_logic:='0';
signal i_cmddone_det              : std_logic:='0';
signal i_cmd_data                 : TUsrAppCmdPkt;
signal i_cmd_wrstart              : std_logic:='0';
signal i_cmd_wrdone               : std_logic:='0';
signal i_txdata_select            : std_logic:='0';
signal i_txdata                   : TSimBufData;
signal i_txdata_wrstart           : std_logic:='0';
signal i_txdata_wrdone            : std_logic:='0';
signal i_rxdata                   : TSimBufData;
signal i_rxdata_rdstart           : std_logic:='0';
signal i_rxdata_rddone            : std_logic:='0';
signal i_tstdata_dwsize           : integer:=0;

type TSataDevStatusSataCount is array (0 to C_HDD_COUNT_MAX-1) of TSataDevStatus;
signal i_satadev_status           : TSataDevStatusSataCount;
signal i_satadev_ctrl             : TSataDevCtrl;



--MAIN
begin


gen_sata_drv : for i in 0 to (C_SH_COUNT_MAX(G_HDD_COUNT-1))-1 generate
i_sata_rxn<=(others=>'0');
i_sata_rxp<=(others=>'1');
end generate gen_sata_drv;

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
p_out_gtp_txdata          => i_hdd_sim_gtp_rxdata(i),
p_out_gtp_txcharisk       => i_hdd_sim_gtp_rxcharisk(i),

p_in_gtp_rxdata           => i_hdd_sim_gtp_txdata(i),
p_in_gtp_rxcharisk        => i_hdd_sim_gtp_txcharisk(i),

p_out_gtp_rxstatus        => i_hdd_sim_gtp_rxstatus(i),
p_out_gtp_rxelecidle      => i_hdd_sim_gtp_rxelecidle(i),
p_out_gtp_rxdisperr       => i_hdd_sim_gtp_rxdisperr(i),
p_out_gtp_rxnotintable    => i_hdd_sim_gtp_rxnotintable(i),
p_out_gtp_rxbyteisaligned => i_hdd_sim_gtp_rxbyteisaligned(i),

p_in_ctrl                 => i_satadev_ctrl,
p_out_status              => i_satadev_status(i),

--------------------------------------------------
--Технологические сигналы
--------------------------------------------------
p_in_tst                  => "00000000000000000000000000000000",
p_out_tst                 => open,

----------------------------
--System
----------------------------
p_in_clk                  => i_hdd_sim_gtp_clk(i),
p_in_rst                  => i_hdd_sim_gtp_rst(i)
);

end generate gen_satad;


gen_clk_sata : process
begin
  i_sata_gtp_refclkmain<='0';
  wait for C_SATACLK_PERIOD/2;
  i_sata_gtp_refclkmain<='1';
  wait for C_SATACLK_PERIOD/2;
end process;

gen_clk_usr : process
begin
  p_in_clk<='0';
  wait for C_USRCLK_PERIOD/2;
  p_in_clk<='1';
  wait for C_USRCLK_PERIOD/2;
end process;

i_dsn_hdd_rst<='1','0' after 1 us;


m_hdd : dsn_hdd
generic map
(
G_MODULE_USE => "ON",--
G_HDD_COUNT  => G_HDD_COUNT,
G_DBG        => G_DBG,
G_SIM        => G_SIM
)
port map
(
--------------------------------------------------
-- Конфигурирование модуля DSN_HDD.VHD (p_in_cfg_clk domain)
--------------------------------------------------
p_in_cfg_clk           => p_in_clk,--//g_host_clk

p_in_cfg_adr           => i_cfgdev_adr,
p_in_cfg_adr_ld        => i_cfgdev_adr_ld,
p_in_cfg_adr_fifo      => i_cfgdev_adr_fifo,

p_in_cfg_txdata        => i_cfgdev_txdata,
p_in_cfg_wd            => i_dev_cfg_wd(C_CFGDEV_HDD),

p_out_cfg_rxdata       => open,--i_hdd_cfg_rxdata,
p_in_cfg_rd            => i_dev_cfg_rd(C_CFGDEV_HDD),

p_in_cfg_done          => i_dev_cfg_done(C_CFGDEV_HDD),
p_in_cfg_rst           => i_dsn_hdd_rst,-- i_cfgdev_module_rst,

--------------------------------------------------
-- STATUS модуля DSN_HDD.VHD
--------------------------------------------------
p_out_hdd_rdy          => i_hdd_rdy,
p_out_hdd_error        => i_hdd_error,
p_out_hdd_busy         => i_hdd_busy,
p_out_hdd_irq          => i_hdd_irq,
p_out_hdd_done         => i_hdd_done,

--------------------------------------------------
-- Связь с Источниками/Приемниками данных накопителя
--------------------------------------------------
p_out_rbuf_cfg         => i_rbuf_cfg,
p_in_rbuf_status       => i_rbuf_status,

p_in_hdd_txd           => i_usr_txd,
p_in_hdd_txd_wr        => i_usr_txd_wr,
p_out_hdd_txbuf_full   => i_usr_txbuf_full,

p_out_hdd_rxd          => i_usr_rxd,
p_in_hdd_rxd_rd        => i_usr_rxd_rd,
p_out_hdd_rxbuf_empty  => i_usr_rxbuf_empty,

--------------------------------------------------
--SATA Driver
--------------------------------------------------
p_out_sata_txn         => i_sata_txn,
p_out_sata_txp         => i_sata_txp,
p_in_sata_rxn          => i_sata_rxn,
p_in_sata_rxp          => i_sata_rxp,

p_in_sata_refclk       => i_sata_gtp_refclkmain,

--------------------------------------------------
--Технологический порт
--------------------------------------------------
p_in_tst               => "00000000000000000000000000000000",--tst_hdd_in,
p_out_tst              => tst_hdd_out,

--------------------------------------------------
--Моделирование/Отладка - в рабочем проекте не используется
--------------------------------------------------
p_out_sim_gtp_txdata        => i_hdd_sim_gtp_txdata,
p_out_sim_gtp_txcharisk     => i_hdd_sim_gtp_txcharisk,
p_in_sim_gtp_rxdata         => i_hdd_sim_gtp_rxdata,
p_in_sim_gtp_rxcharisk      => i_hdd_sim_gtp_rxcharisk,
p_in_sim_gtp_rxstatus       => i_hdd_sim_gtp_rxstatus,
p_in_sim_gtp_rxelecidle     => i_hdd_sim_gtp_rxelecidle,
p_in_sim_gtp_rxdisperr      => i_hdd_sim_gtp_rxdisperr,
p_in_sim_gtp_rxnotintable   => i_hdd_sim_gtp_rxnotintable,
p_in_sim_gtp_rxbyteisaligned=> i_hdd_sim_gtp_rxbyteisaligned,
p_out_gtp_sim_rst           => i_hdd_sim_gtp_rst,
p_out_gtp_sim_clk           => i_hdd_sim_gtp_clk,

--------------------------------------------------
--System
--------------------------------------------------
p_in_rst               => i_dsn_hdd_rst
);


m_hdd_rambuf : dsn_hdd_rambuf
generic map
(
G_MODULE_USE      => "ON",
G_HDD_RAMBUF_SIZE => 23, --//(в BYTE). Определяется как 2 в степени G_HDD_RAMBUF_SIZE
G_SIM             => G_SIM
)
port map
(
-------------------------------
-- Конфигурирование
-------------------------------
p_in_rbuf_cfg         => i_rbuf_cfg,
p_out_rbuf_status     => i_rbuf_status,

--//--------------------------
--//Связь с буфером видеоданных
--//--------------------------
p_in_vbuf_dout        => "00000000000000000000000000000000",
p_out_vbuf_rd         => open,
p_in_vbuf_empty       => '0',
p_in_vbuf_full        => '0',
p_in_vbuf_pfull       => '0',

--//--------------------------
--//Связь с модулем HDD
--//--------------------------
p_out_hdd_txd         => i_usr_txd,
p_out_hdd_txd_wr      => i_usr_txd_wr,
p_in_hdd_txbuf_full   => i_usr_txbuf_full,
--p_in_hdd_txbuf_empty  : in    std_logic;

p_in_hdd_rxd          => i_usr_rxd,
p_out_hdd_rxd_rd      => i_usr_rxd_rd,
p_in_hdd_rxbuf_empty  => i_usr_rxbuf_empty,

---------------------------------
-- Связь с memory_ctrl.vhd
---------------------------------
p_out_memarb_req      => open,
p_in_memarb_en        => '1',

p_out_mem_bank1h      => i_hdd_mem_bank1h,
p_out_mem_ce          => i_hdd_mem_ce,
p_out_mem_cw          => i_hdd_mem_cw,
p_out_mem_rd          => i_hdd_mem_rd,
p_out_mem_wr          => i_hdd_mem_wr,
p_out_mem_term        => i_hdd_mem_term,
p_out_mem_adr         => i_hdd_mem_adr,
p_out_mem_be          => i_hdd_mem_be,
p_out_mem_din         => i_hdd_mem_din,
p_in_mem_dout         => i_hdd_mem_dout,

p_in_mem_wf           => i_hdd_mem_wf,
p_in_mem_wpf          => i_hdd_mem_wpf,
p_in_mem_re           => i_hdd_mem_re,
p_in_mem_rpe          => i_hdd_mem_rpe,

p_out_mem_clk         => open,

-------------------------------
--Технологический
-------------------------------
p_in_tst              => "00000000000000000000000000000000",
p_out_tst             => open,

-------------------------------
--System
-------------------------------
p_in_clk              => p_in_clk,--//g_host_clk
p_in_rst              => i_dsn_hdd_rst
);

i_hdd_mem_wf <='0';
i_hdd_mem_wpf<='0';
i_hdd_mem_rpe<='0';





--//########################################
--//Main Ctrl
--//########################################

p_in_usr_ctrl<=(others=>'0');


--//Логика работы автомата управления
lmain_ctrl:process

type TCfgCmdPkt is record
usr_ctrl: std_logic_vector(15 downto 0);
command : integer;
scount  : integer;
lba     : std_logic_vector(47 downto 0);
loopback: std_logic;
end record;
type TCfgCmdPkts is array (0 to 64) of TCfgCmdPkt;
variable cfgCmdPkt : TCfgCmdPkts;
variable cmd_write : std_logic:='0';
variable cmd_read  : std_logic:='0';
variable cmddone_det: std_logic:='0';


variable string_value : std_logic_vector(3 downto 0);
variable GUI_line  : LINE;--Строка для вывода в ModelSim

begin

  --//---------------------------------------------------
  --/Инициализация
  --//---------------------------------------------------
  i_cmd_wrstart<='0';
  i_txdata_wrstart<='0';
  i_rxdata_rdstart<='0';
  i_tstdata_dwsize<=0;
  i_loopback<='0';
  i_cmddone_det_clr<='0';
  i_dsn_hdd_regcfg_start<='0';

  for i in 0 to i_cmd_data'high loop
  i_cmd_data(i)<=(others=>'0');
  end loop;

  for i in 0 to cfgCmdPkt'high loop
  cfgCmdPkt(i).usr_ctrl:=(others=>'0');
  cfgCmdPkt(i).command:=C_ATA_CMD_READ_SECTORS_EXT;
  cfgCmdPkt(i).scount:=1;
  cfgCmdPkt(i).lba:=(others=>'0');
  cfgCmdPkt(i).loopback:='0';
  end loop;

  wait until i_dsn_hdd_rst='0';

  wait until p_in_clk'event and p_in_clk='1';
  i_dsn_hdd_regcfg_start<='1';
  wait until p_in_clk'event and p_in_clk='1';
  i_dsn_hdd_regcfg_start<='0';

  wait until i_dsn_hdd_regcfg_done='1';


  i_txdata_select<='1'; --//0/1 - Счетчик/Random DATA

  --//Инициализируем команды которые будут отправлятся:
  cfgCmdPkt(0).usr_ctrl(C_CMDPKT_USRHDD_NUM_M_BIT downto C_CMDPKT_USRHDD_NUM_L_BIT):=CONV_STD_LOGIC_VECTOR(16#01#, C_CMDPKT_USRHDD_NUM_M_BIT-C_CMDPKT_USRHDD_NUM_L_BIT+1);
  cfgCmdPkt(0).usr_ctrl(C_CMDPKT_USRMODE_SW_BIT):='1';
  cfgCmdPkt(0).usr_ctrl(C_CMDPKT_USRMODE_HW_BIT):='0';
  cfgCmdPkt(0).usr_ctrl(C_CMDPKT_USRCMD_M_BIT downto C_CMDPKT_USRCMD_L_BIT):=CONV_STD_LOGIC_VECTOR(C_USRCMD_ATACOMMAND, C_CMDPKT_USRCMD_M_BIT-C_CMDPKT_USRCMD_L_BIT+1);
  cfgCmdPkt(0).command:=C_ATA_CMD_WRITE_SECTORS_EXT;--;C_ATA_CMD_READ_DMA_EXT;--
  cfgCmdPkt(0).scount:=2;--//Кол-во секторов
  cfgCmdPkt(0).lba:=CONV_STD_LOGIC_VECTOR(16#04030201#, 48);--//LBA
  cfgCmdPkt(0).loopback:='1';

  cfgCmdPkt(1).usr_ctrl(C_CMDPKT_USRHDD_NUM_M_BIT downto C_CMDPKT_USRHDD_NUM_L_BIT):=CONV_STD_LOGIC_VECTOR(16#01#, C_CMDPKT_USRHDD_NUM_M_BIT-C_CMDPKT_USRHDD_NUM_L_BIT+1);
  cfgCmdPkt(1).usr_ctrl(C_CMDPKT_USRMODE_SW_BIT):='1';
  cfgCmdPkt(1).usr_ctrl(C_CMDPKT_USRMODE_HW_BIT):='0';
  cfgCmdPkt(1).usr_ctrl(C_CMDPKT_USRCMD_M_BIT downto C_CMDPKT_USRCMD_L_BIT):=CONV_STD_LOGIC_VECTOR(C_USRCMD_ATACOMMAND, C_CMDPKT_USRCMD_M_BIT-C_CMDPKT_USRCMD_L_BIT+1);
  cfgCmdPkt(1).command:=C_ATA_CMD_READ_SECTORS_EXT;--C_ATA_CMD_WRITE_DMA_EXT;--;
  cfgCmdPkt(1).scount:=2;
  cfgCmdPkt(1).lba:=CONV_STD_LOGIC_VECTOR(16#04030201#, 48);
  cfgCmdPkt(1).loopback:='1';

  cfgCmdPkt(2).usr_ctrl(C_CMDPKT_USRHDD_NUM_M_BIT downto C_CMDPKT_USRHDD_NUM_L_BIT):=CONV_STD_LOGIC_VECTOR(16#01#, C_CMDPKT_USRHDD_NUM_M_BIT-C_CMDPKT_USRHDD_NUM_L_BIT+1);
  cfgCmdPkt(2).usr_ctrl(C_CMDPKT_USRMODE_SW_BIT):='1';
  cfgCmdPkt(2).usr_ctrl(C_CMDPKT_USRMODE_HW_BIT):='0';
  cfgCmdPkt(2).usr_ctrl(C_CMDPKT_USRCMD_M_BIT downto C_CMDPKT_USRCMD_L_BIT):=CONV_STD_LOGIC_VECTOR(C_USRCMD_ATACOMMAND, C_CMDPKT_USRCMD_M_BIT-C_CMDPKT_USRCMD_L_BIT+1);
  cfgCmdPkt(2).command:=C_ATA_CMD_WRITE_DMA_EXT;--C_ATA_CMD_WRITE_SECTORS_EXT;
  cfgCmdPkt(2).scount:=3;
  cfgCmdPkt(2).lba:=CONV_STD_LOGIC_VECTOR(16#04030201#, 48);
  cfgCmdPkt(2).loopback:='1';

  cfgCmdPkt(3).usr_ctrl(C_CMDPKT_USRHDD_NUM_M_BIT downto C_CMDPKT_USRHDD_NUM_L_BIT):=CONV_STD_LOGIC_VECTOR(16#01#, C_CMDPKT_USRHDD_NUM_M_BIT-C_CMDPKT_USRHDD_NUM_L_BIT+1);
  cfgCmdPkt(3).usr_ctrl(C_CMDPKT_USRMODE_SW_BIT):='1';
  cfgCmdPkt(3).usr_ctrl(C_CMDPKT_USRMODE_HW_BIT):='0';
  cfgCmdPkt(3).usr_ctrl(C_CMDPKT_USRCMD_M_BIT downto C_CMDPKT_USRCMD_L_BIT):=CONV_STD_LOGIC_VECTOR(C_USRCMD_ATACOMMAND, C_CMDPKT_USRCMD_M_BIT-C_CMDPKT_USRCMD_L_BIT+1);
  cfgCmdPkt(3).command:=C_ATA_CMD_READ_DMA_EXT;--
  cfgCmdPkt(3).scount:=3;
  cfgCmdPkt(3).lba:=CONV_STD_LOGIC_VECTOR(16#04030201#, 48);
  cfgCmdPkt(3).loopback:='1';

  cfgCmdPkt(4).usr_ctrl(C_CMDPKT_USRHDD_NUM_M_BIT downto C_CMDPKT_USRHDD_NUM_L_BIT):=CONV_STD_LOGIC_VECTOR(16#01#, C_CMDPKT_USRHDD_NUM_M_BIT-C_CMDPKT_USRHDD_NUM_L_BIT+1);
  cfgCmdPkt(4).usr_ctrl(C_CMDPKT_USRMODE_SW_BIT):='1';
  cfgCmdPkt(4).usr_ctrl(C_CMDPKT_USRMODE_HW_BIT):='0';
  cfgCmdPkt(4).usr_ctrl(C_CMDPKT_USRCMD_M_BIT downto C_CMDPKT_USRCMD_L_BIT):=CONV_STD_LOGIC_VECTOR(C_USRCMD_ATACOMMAND, C_CMDPKT_USRCMD_M_BIT-C_CMDPKT_USRCMD_L_BIT+1);
  cfgCmdPkt(4).command:=C_ATA_CMD_WRITE_DMA_EXT;--
  cfgCmdPkt(4).scount:=9;
  cfgCmdPkt(4).lba:=CONV_STD_LOGIC_VECTOR(16#04030201#, 48);
  cfgCmdPkt(4).loopback:='1';

  cfgCmdPkt(5).usr_ctrl(C_CMDPKT_USRHDD_NUM_M_BIT downto C_CMDPKT_USRHDD_NUM_L_BIT):=CONV_STD_LOGIC_VECTOR(16#01#, C_CMDPKT_USRHDD_NUM_M_BIT-C_CMDPKT_USRHDD_NUM_L_BIT+1);
  cfgCmdPkt(5).usr_ctrl(C_CMDPKT_USRMODE_SW_BIT):='1';
  cfgCmdPkt(5).usr_ctrl(C_CMDPKT_USRMODE_HW_BIT):='0';
  cfgCmdPkt(5).usr_ctrl(C_CMDPKT_USRCMD_M_BIT downto C_CMDPKT_USRCMD_L_BIT):=CONV_STD_LOGIC_VECTOR(C_USRCMD_ATACOMMAND, C_CMDPKT_USRCMD_M_BIT-C_CMDPKT_USRCMD_L_BIT+1);
  cfgCmdPkt(5).command:=C_ATA_CMD_READ_DMA_EXT;--
  cfgCmdPkt(5).scount:=9;
  cfgCmdPkt(5).lba:=CONV_STD_LOGIC_VECTOR(16#04030201#, 48);
  cfgCmdPkt(5).loopback:='1';

  cfgCmdPkt(6).usr_ctrl(C_CMDPKT_USRHDD_NUM_M_BIT downto C_CMDPKT_USRHDD_NUM_L_BIT):=CONV_STD_LOGIC_VECTOR(16#01#, C_CMDPKT_USRHDD_NUM_M_BIT-C_CMDPKT_USRHDD_NUM_L_BIT+1);
  cfgCmdPkt(6).usr_ctrl(C_CMDPKT_USRMODE_SW_BIT):='1';
  cfgCmdPkt(6).usr_ctrl(C_CMDPKT_USRMODE_HW_BIT):='0';
  cfgCmdPkt(6).usr_ctrl(C_CMDPKT_USRCMD_M_BIT downto C_CMDPKT_USRCMD_L_BIT):=CONV_STD_LOGIC_VECTOR(C_USRCMD_ATACOMMAND, C_CMDPKT_USRCMD_M_BIT-C_CMDPKT_USRCMD_L_BIT+1);
  cfgCmdPkt(6).command:=C_ATA_CMD_READ_DMA_EXT;--
  cfgCmdPkt(6).scount:=9;
  cfgCmdPkt(6).lba:=CONV_STD_LOGIC_VECTOR(16#04030201#, 48);
  cfgCmdPkt(6).loopback:='0';

  cfgCmdPkt(7).usr_ctrl(C_CMDPKT_USRHDD_NUM_M_BIT downto C_CMDPKT_USRHDD_NUM_L_BIT):=CONV_STD_LOGIC_VECTOR(16#01#, C_CMDPKT_USRHDD_NUM_M_BIT-C_CMDPKT_USRHDD_NUM_L_BIT+1);
  cfgCmdPkt(7).usr_ctrl(C_CMDPKT_USRMODE_SW_BIT):='1';
  cfgCmdPkt(7).usr_ctrl(C_CMDPKT_USRMODE_HW_BIT):='0';
  cfgCmdPkt(7).usr_ctrl(C_CMDPKT_USRCMD_M_BIT downto C_CMDPKT_USRCMD_L_BIT):=CONV_STD_LOGIC_VECTOR(C_USRCMD_ATACOMMAND, C_CMDPKT_USRCMD_M_BIT-C_CMDPKT_USRCMD_L_BIT+1);
  cfgCmdPkt(7).command:=C_ATA_CMD_READ_DMA_EXT;--
  cfgCmdPkt(7).scount:=9;
  cfgCmdPkt(7).lba:=CONV_STD_LOGIC_VECTOR(16#04030201#, 48);
  cfgCmdPkt(7).loopback:='0';

  cfgCmdPkt(8).usr_ctrl(C_CMDPKT_USRHDD_NUM_M_BIT downto C_CMDPKT_USRHDD_NUM_L_BIT):=CONV_STD_LOGIC_VECTOR(16#01#, C_CMDPKT_USRHDD_NUM_M_BIT-C_CMDPKT_USRHDD_NUM_L_BIT+1);
  cfgCmdPkt(8).usr_ctrl(C_CMDPKT_USRMODE_SW_BIT):='1';
  cfgCmdPkt(8).usr_ctrl(C_CMDPKT_USRMODE_HW_BIT):='0';
  cfgCmdPkt(8).usr_ctrl(C_CMDPKT_USRCMD_M_BIT downto C_CMDPKT_USRCMD_L_BIT):=CONV_STD_LOGIC_VECTOR(C_USRCMD_ATACOMMAND, C_CMDPKT_USRCMD_M_BIT-C_CMDPKT_USRCMD_L_BIT+1);
  cfgCmdPkt(8).command:=C_ATA_CMD_READ_DMA_EXT;--
  cfgCmdPkt(8).scount:=9;
  cfgCmdPkt(8).lba:=CONV_STD_LOGIC_VECTOR(16#04030201#, 48);
  cfgCmdPkt(8).loopback:='0';

  cfgCmdPkt(9).usr_ctrl(C_CMDPKT_USRHDD_NUM_M_BIT downto C_CMDPKT_USRHDD_NUM_L_BIT):=CONV_STD_LOGIC_VECTOR(16#01#, C_CMDPKT_USRHDD_NUM_M_BIT-C_CMDPKT_USRHDD_NUM_L_BIT+1);
  cfgCmdPkt(9).usr_ctrl(C_CMDPKT_USRMODE_SW_BIT):='1';
  cfgCmdPkt(9).usr_ctrl(C_CMDPKT_USRMODE_HW_BIT):='0';
  cfgCmdPkt(9).usr_ctrl(C_CMDPKT_USRCMD_M_BIT downto C_CMDPKT_USRCMD_L_BIT):=CONV_STD_LOGIC_VECTOR(C_USRCMD_ATACOMMAND, C_CMDPKT_USRCMD_M_BIT-C_CMDPKT_USRCMD_L_BIT+1);
  cfgCmdPkt(9).command:=C_ATA_CMD_READ_DMA_EXT;--
  cfgCmdPkt(9).scount:=9;
  cfgCmdPkt(9).lba:=CONV_STD_LOGIC_VECTOR(16#04030201#, 48);
  cfgCmdPkt(9).loopback:='0';

  cfgCmdPkt(10).usr_ctrl(C_CMDPKT_USRHDD_NUM_M_BIT downto C_CMDPKT_USRHDD_NUM_L_BIT):=CONV_STD_LOGIC_VECTOR(16#01#, C_CMDPKT_USRHDD_NUM_M_BIT-C_CMDPKT_USRHDD_NUM_L_BIT+1);
  cfgCmdPkt(10).usr_ctrl(C_CMDPKT_USRMODE_SW_BIT):='1';
  cfgCmdPkt(10).usr_ctrl(C_CMDPKT_USRMODE_HW_BIT):='0';
  cfgCmdPkt(10).usr_ctrl(C_CMDPKT_USRCMD_M_BIT downto C_CMDPKT_USRCMD_L_BIT):=CONV_STD_LOGIC_VECTOR(C_USRCMD_ATACOMMAND, C_CMDPKT_USRCMD_M_BIT-C_CMDPKT_USRCMD_L_BIT+1);
  cfgCmdPkt(10).command:=C_ATA_CMD_READ_DMA_EXT;--
  cfgCmdPkt(10).scount:=9;
  cfgCmdPkt(10).lba:=CONV_STD_LOGIC_VECTOR(16#04030201#, 48);
  cfgCmdPkt(10).loopback:='0';

  cfgCmdPkt(11).usr_ctrl(C_CMDPKT_USRHDD_NUM_M_BIT downto C_CMDPKT_USRHDD_NUM_L_BIT):=CONV_STD_LOGIC_VECTOR(16#01#, C_CMDPKT_USRHDD_NUM_M_BIT-C_CMDPKT_USRHDD_NUM_L_BIT+1);
  cfgCmdPkt(11).usr_ctrl(C_CMDPKT_USRMODE_SW_BIT):='1';
  cfgCmdPkt(11).usr_ctrl(C_CMDPKT_USRMODE_HW_BIT):='0';
  cfgCmdPkt(11).usr_ctrl(C_CMDPKT_USRCMD_M_BIT downto C_CMDPKT_USRCMD_L_BIT):=CONV_STD_LOGIC_VECTOR(C_USRCMD_ATACOMMAND, C_CMDPKT_USRCMD_M_BIT-C_CMDPKT_USRCMD_L_BIT+1);
  cfgCmdPkt(11).command:=C_ATA_CMD_READ_DMA_EXT;--
  cfgCmdPkt(11).scount:=9;
  cfgCmdPkt(11).lba:=CONV_STD_LOGIC_VECTOR(16#04030201#, 48);
  cfgCmdPkt(11).loopback:='0';




  --//---------------------------------------------------
  --//Отработка команд командного пакета
  --//---------------------------------------------------
  ltrn_count : for idx in 0 to C_SIM_COUNT-1 loop

  i_loopback<=cfgCmdPkt(idx).loopback;

  --//Ждем разрешения загрузки командного пакета
  cmddone_det:='0';
  while cmddone_det='0' loop
      wait until p_in_clk'event and p_in_clk='1';
        cmddone_det:=i_cmddone_det;
  end loop;
  --//Сброс флага i_cmddone_det
  wait until p_in_clk'event and p_in_clk='1';
  i_cmddone_det_clr<='1';
  wait until p_in_clk'event and p_in_clk='1';
  i_cmddone_det_clr<='0';

  write(GUI_line,string'("NEW ATA COMMAND 1."));writeline(output, GUI_line);

  --//Заполняем CmdPkt
  i_cmd_data(0)<=cfgCmdPkt(idx).usr_ctrl; --//UsrCTRL
  i_cmd_data(1)<=CONV_STD_LOGIC_VECTOR(16#AA55#, 16);--//Feature
  i_cmd_data(2)<=cfgCmdPkt(idx).lba(31 downto 24) & cfgCmdPkt(idx).lba(7 downto 0);
  i_cmd_data(3)<=cfgCmdPkt(idx).lba(39 downto 32) & cfgCmdPkt(idx).lba(15 downto 8);
  i_cmd_data(4)<=cfgCmdPkt(idx).lba(47 downto 40) & cfgCmdPkt(idx).lba(23 downto 16);
  i_cmd_data(5)<=CONV_STD_LOGIC_VECTOR(cfgCmdPkt(idx).scount, 16);--//SectorCount
  i_cmd_data(6)<=CONV_STD_LOGIC_VECTOR(0, 8) & CONV_STD_LOGIC_VECTOR(cfgCmdPkt(idx).command, 8);--//Reserv + ATA Commad

  i_tstdata_dwsize<=cfgCmdPkt(idx).scount * C_SIM_SECTOR_SIZE_DWORD;--//Назначаем размер данных в DWORD


  --//Запускаем автомат записи командного пакета
  wait until p_in_clk'event and p_in_clk='1';
  i_cmd_wrstart<='1';
  wait until p_in_clk'event and p_in_clk='1';
  i_cmd_wrstart<='0';


  --//Ждем отправки подтверждения записи командного пакета
  wait until i_cmd_wrdone='1';


  if cfgCmdPkt(idx).command=C_ATA_CMD_WRITE_SECTORS_EXT or cfgCmdPkt(idx).command=C_ATA_CMD_WRITE_DMA_EXT then
  --//Запускаем автомат записи данных
    wait until p_in_clk'event and p_in_clk='1';
    i_txdata_wrstart<='1';
    cmd_write:='1';

    wait until p_in_clk'event and p_in_clk='1';
    i_txdata_wrstart<='0';

    --//Ждем когда запишем все данные в TxBUF
    wait until i_txdata_wrdone='1';
  end if;

  if cfgCmdPkt(idx).command=C_ATA_CMD_READ_SECTORS_EXT or cfgCmdPkt(idx).command=C_ATA_CMD_READ_DMA_EXT then
  --//Запускаем автомат чтния данных
    wait until p_in_clk'event and p_in_clk='1';
    i_rxdata_rdstart<='1';
    cmd_read:='1';

    wait until p_in_clk'event and p_in_clk='1';
    i_rxdata_rdstart<='0';

    --//Ждем когда прочитаем все данные из RxBUF
    wait until i_rxdata_rddone='1';
  end if;


  if i_loopback='0' then
    write(GUI_line,string'("LOOPBACK DATA: disable")); writeline(output, GUI_line);
    cmd_write:='0';
    cmd_read:='0';

  else

    if cmd_write='1' and cmd_read='1' then
      write(GUI_line,string'("COMPARE DATA: i_txdata,i_rxdata")); writeline(output, GUI_line);
      for i in 0 to i_tstdata_dwsize-1 loop

          write(GUI_line,string'(" i_txdata/i_rxdata("));write(GUI_line,i);write(GUI_line,string'("): 0x"));
          --write(GUI_line,CONV_INTEGER(i_txdata(i)));
          for y in 1 to 8 loop
          string_value:=i_txdata(i)((32-(4*(y-1)))-1 downto (32-(4*y)));
          write(GUI_line,Int2StrHEX(CONV_INTEGER(string_value)));
          end loop;
          write(GUI_line,string'("/0x"));
          --write(GUI_line,CONV_INTEGER(i_rxdata(i)));
          for y in 1 to 8 loop
          string_value:=i_rxdata(i)((32-(4*(y-1)))-1 downto (32-(4*y)));
          write(GUI_line,Int2StrHEX(CONV_INTEGER(string_value)));
          end loop;
          writeline(output, GUI_line);

        if i_txdata(i)/=i_rxdata(i) then
          --//Завершаем модеоирование.
          write(GUI_line,string'("COMPARE DATA:ERROR - i_txdata("));write(GUI_line,i);write(GUI_line,string'(")/= "));
          write(GUI_line,string'("i_rxdata("));write(GUI_line,i);write(GUI_line,string'(")"));
          writeline(output, GUI_line);
          p_SIM_STOP("Simulation of STOP: COMPARE DATA:ERROR i_rxdata/=i_rxdata");
        end if;
      end loop;

      cmd_write:='0';
      cmd_read:='0';
      write(GUI_line,string'("COMPARE DATA: i_txdata/i_rxdata - OK.")); writeline(output, GUI_line);
    end if;
  end if;

  end loop ltrn_count;


  wait for 2 us;

  --//Завершаем модеоирование.
  p_SIM_STOP("Simulation of SIMPLE complete");


  wait;
end process lmain_ctrl;


--//Выделяем задний фронт из сигнала BUSY модуля m_sata_host.
--//Для детектированя завершения АТА команды
lcmddone:process(i_dsn_hdd_rst,p_in_clk)
begin
  if i_dsn_hdd_rst='1' then

    sr_cmdbusy<=(others=>'1');
    i_cmddone_det<='0';

  elsif p_in_clk'event and p_in_clk='1' then

    sr_cmdbusy<=i_hdd_busy & sr_cmdbusy(0 to 0);

    if i_cmddone_det_clr='1' then
      i_cmddone_det<='0';
    elsif sr_cmdbusy(1)='1' and sr_cmdbusy(0)='0' then
      i_cmddone_det<='1';
    end if;

  end if;
end process lcmddone;




process
variable GUI_line : LINE;--Строка для вывода в ModelSim
begin

  i_satadev_ctrl.atacmd_done<='0';

  wait until i_cmddone_det_clr='1';

  wait until i_hdd_sim_gtp_clk(0)'event and i_hdd_sim_gtp_clk(0) = '1';
  i_satadev_ctrl.atacmd_done<='1';
  wait until i_hdd_sim_gtp_clk(0)'event and i_hdd_sim_gtp_clk(0) = '1';
  i_satadev_ctrl.atacmd_done<='0';

end process;

i_satadev_ctrl.loopback<=i_loopback;
i_satadev_ctrl.link_establish<=i_hdd_rdy;
i_satadev_ctrl.dbuf_wuse<='1';--//1/0 - использовать модель sata_bufdata.vhd/ не использовать
i_satadev_ctrl.dbuf_ruse<='1';




--//########################################
--//Программирование модуля dsn_hdd
--//########################################
ltxcmd:process
variable GUI_line : LINE;--Строка для вывода в ModelSim
variable mem_lentrn_byte: std_logic_vector(16 + log2(CI_SECTOR_SIZE_BYTE)-1 downto 0);
variable mem_lentrn_dw  : std_logic_vector(mem_lentrn_byte'range);
begin

  --//Инициализация:
  mem_lentrn_byte:=CONV_STD_LOGIC_VECTOR(CI_SECTOR_SIZE_BYTE, mem_lentrn_byte'length);
  mem_lentrn_dw:=("00"&mem_lentrn_byte(mem_lentrn_byte'high downto 2));

  i_cfgdev_adr<=(others=>'0');
  i_cfgdev_adr_ld<='0';
  i_cfgdev_adr_fifo<='0';
  i_cfgdev_txdata<=(others=>'0');
  i_dev_cfg_wd<=(others=>'0');
  i_dev_cfg_rd<=(others=>'0');
  i_dev_cfg_done<=(others=>'0');
  i_dsn_hdd_regcfg_done<='0';

  --//--------------------------
  --//Программирование регистров модуля dsn_hdd:
  --//--------------------------
  wait until i_dsn_hdd_regcfg_start = '1';--//Ждем разрешения кофигурирования регистров модуля dsn_hdd

  wait until p_in_clk'event and p_in_clk='1';
    i_cfgdev_adr<=CONV_STD_LOGIC_VECTOR(C_DSN_HDD_REG_RBUF_CTRL, i_cfgdev_adr'length);
    i_cfgdev_adr_ld<='1';
    i_cfgdev_adr_fifo<='0';
  wait until p_in_clk'event and p_in_clk='1';
    i_cfgdev_adr_ld<='0';
    i_cfgdev_adr_fifo<='0';
    i_cfgdev_txdata(C_DSN_HDD_REG_RBUF_CTRL_TRNMEM_MSB_BIT downto C_DSN_HDD_REG_RBUF_CTRL_TRNMEM_LSB_BIT)<=mem_lentrn_dw(7 downto 0);
    i_dev_cfg_wd(C_CFGDEV_HDD)<='1';

  wait until p_in_clk'event and p_in_clk='1';
    i_dev_cfg_wd(C_CFGDEV_HDD)<='0';
    i_dsn_hdd_regcfg_done<='1';


  --//--------------------------
  --//Отправка HDD_cmdpkt:
  --//--------------------------
  ltxcmdloop:while true loop

      i_cfgdev_adr<=(others=>'0');
      i_cfgdev_adr_ld<='0';
      i_cfgdev_adr_fifo<='0';
      i_cfgdev_txdata<=(others=>'0');
      i_dev_cfg_wd<=(others=>'0');
      i_dev_cfg_rd<=(others=>'0');
      i_dev_cfg_done<=(others=>'0');

      wait until i_cmd_wrstart = '1';--//Ждем разрешения записи данных

      wait until p_in_clk'event and p_in_clk='1';
        i_cfgdev_adr<=CONV_STD_LOGIC_VECTOR(C_DSN_HDD_REG_CMDFIFO, i_cfgdev_adr'length);
        i_cfgdev_adr_ld<='1';
        i_cfgdev_adr_fifo<='1';
      wait until p_in_clk'event and p_in_clk='1';
        i_cfgdev_adr_ld<='0';
        i_cfgdev_adr_fifo<='1';

      wait until p_in_clk'event and p_in_clk='1';
      p_CMDPKT_WRITE(p_in_clk,
                    i_cmd_data,
                    i_cfgdev_txdata, i_dev_cfg_wd(C_CFGDEV_HDD));

      wait until p_in_clk'event and p_in_clk='1';
        i_dev_cfg_done(C_CFGDEV_HDD)<='1';
      wait until p_in_clk'event and p_in_clk='1';
        i_dev_cfg_done(C_CFGDEV_HDD)<='0';

  end loop ltxcmdloop;

  wait;
end process ltxcmd;

i_cmd_wrdone<=i_dev_cfg_done(C_CFGDEV_HDD);


--//########################################
--//Запись данных в TxBUF
--//########################################
ltxd:process
variable memtrn_term: std_logic:='0';
variable dcnt      : integer;
variable srcambler : std_logic_vector(31 downto 0):=(others=>'0');
variable GUI_line  : LINE;--Строка для вывода в ModelSim
begin

  i_hdd_mem_dout<=(others=>'0');
  i_hdd_mem_re<='1';
  i_txdata_wrdone<='0';

   memtrn_term:='0';

  --//Инициализация генератора рандомных данных
  srcambler:=srambler32_0(CONV_STD_LOGIC_VECTOR(16#1032#, 16));

  ltxdloop:while true loop

      wait until i_txdata_wrstart = '1';--//Ждем разрешения записи данных

      --//Инициализация
      for i in 0 to i_txdata'high loop
      i_txdata(i)<=(others=>'0');
      end loop;

      --//Генератор тестовых данных
      for i in 0 to i_txdata'high loop
        if i_txdata_select='0' then
          i_txdata(i)<=CONV_STD_LOGIC_VECTOR(i+1, i_txdata(i)'length);--счетчик
        else
          i_txdata(i)<=srcambler;--//Random Data
        end if;
        srcambler:=srambler32_0(srcambler(31 downto 16));--//Инкрементация скремблера
      end loop;

      dcnt:=0;
      --//Запись данных в TxBuf(m_txbuf)
      lbufd_wr:while dcnt/=i_tstdata_dwsize loop

          wait until i_hdd_mem_ce='1' and i_hdd_mem_cw='0' and p_in_clk'event and p_in_clk='1';--//Ждем разрешения записи данных

          lmemtrn_wr:while i_hdd_mem_term='0' loop

            wait until p_in_clk'event and p_in_clk='1';
              if i_hdd_mem_term='0' then
                i_hdd_mem_re<='0';
                i_hdd_mem_dout<=i_txdata(dcnt);
                dcnt:=dcnt + 1;
              end if;
          end loop lmemtrn_wr;

          dcnt:=dcnt - 1;
          i_hdd_mem_re<='1';

      end loop lbufd_wr;

      wait until p_in_clk'event and p_in_clk='1';
        i_txdata_wrdone<='1';
      wait until p_in_clk'event and p_in_clk='1';
        i_txdata_wrdone<='0';

  end loop ltxdloop;

  wait;
end process ltxd;


--//########################################
--//Чтение данных из RxBUF
--//########################################
--lrxd:process
--variable dcnt : integer:=0;
--variable GUI_line  : LINE;--Строка для вывода в ModelSim
--begin
--
--  i_usr_rxd_rd<='0';
--  i_rxdata_rddone<='0';
--
--  lrxdloop:while true loop
--
--      wait until i_rxdata_rdstart = '1';--//Ждем разрешения чтения данных
--
--      --//Инициализация
--      for i in 0 to i_txdata'high loop
--      i_rxdata(i)<=(others=>'0');
--      end loop;
--
--      dcnt:=0;
--      --//Чтение данных из RxBuf(m_rxbuf)
--      lbufd_rd:while dcnt/=i_tstdata_dwsize loop
--
--          if i_usr_rxbuf_empty='0' then
--
--              wait until p_in_clk'event and p_in_clk='1';
--                  i_usr_rxd_rd<='1';
--                  --//если FIFO - FIRST WORD
--                  i_rxdata(dcnt)<=i_usr_rxd;
--                  dcnt:=dcnt + 1;
--
--              wait until p_in_clk'event and p_in_clk='1';
--                  i_usr_rxd_rd<='0';
--
----              --//если FIFO - STANDART
----              wait until p_in_clk'event and p_in_clk='1';
----                  i_rxdata(dcnt)<=i_usr_rxd;
----                  dcnt:=dcnt + 1;
--          else
--              wait until p_in_clk'event and p_in_clk='1';
--                  i_usr_rxd_rd<='0';
--          end if;
--
--       end loop lbufd_rd;
--
--      wait until p_in_clk'event and p_in_clk='1';
--        i_rxdata_rddone<='1';
--      wait until p_in_clk'event and p_in_clk='1';
--        i_rxdata_rddone<='0';
--
--  end loop lrxdloop;
--
--  wait;
--end process lrxd;

lrxd:process(i_dsn_hdd_rst,p_in_clk)
  variable dcnt : integer:=0;
begin
  if i_dsn_hdd_rst='1' then
      for i in 0 to i_txdata'high loop
      i_rxdata(i)<=(others=>'0');
      end loop;
      dcnt:=0;

  elsif p_in_clk'event and p_in_clk='1' then

    if i_rxdata_rdstart = '1' then

      --//Инициализация
      for i in 0 to i_txdata'high loop
      i_rxdata(i)<=(others=>'0');
      end loop;
      dcnt:=0;

    else
      if i_hdd_mem_wr='1' then
        i_rxdata(dcnt)<=i_hdd_mem_din;
        dcnt:=dcnt + 1;
      end if;

    end if;
  end if;
end process lrxd;

i_rxdata_rddone<=i_rbuf_status.done;

--END MAIN
end;



