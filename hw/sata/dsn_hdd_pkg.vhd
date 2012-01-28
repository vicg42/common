-------------------------------------------------------------------------
-- Company     : Telemix
-- Engineer    : Golovachenko Victor
--
-- Create Date : 10/26/2007
-- Module Name : dsn_hdd_pkg
--
-- Description :
--
-- Revision:
-- Revision 0.01 - File Created
--
-------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;

library work;
use work.sata_glob_pkg.all;
use work.sata_pkg.all;
use work.sata_raid_pkg.all;
use work.sata_testgen_pkg.all;

package dsn_hdd_pkg is

constant C_HDD_CFGIF_PCIEXP : std_logic:='0';
constant C_HDD_CFGIF_UART   : std_logic:='1';


type THDDLed is record
link: std_logic;--//Связь установлена
rdy : std_logic;--//Канал готов к работе
err : std_logic;--//
busy: std_logic;--//
spd : std_logic_vector(1 downto 0);
dly : std_logic;--//
end record;
type THDDLed_SHCountMax is array (0 to C_HDD_COUNT_MAX-1) of THDDLed;


type THDDRBufErrDetect is record
vinbuf_full : std_logic;
rambuf_full : std_logic;
end record;

--//Запись чтение RAM через CFG/Map:
type THDDCfgRAMI is record
clk     : std_logic;
din     : std_logic_vector(15 downto 0);
wr      : std_logic;
rd      : std_logic;

reqlen  : std_logic_vector(15 downto 0);--Кол-во запрашиваемых данных
dir     : std_logic;--1/0 (RAM<-CFG)/(RAM->CFG)
start   : std_logic;--Пуск операции
sel     : std_logic;--Подключение CFG к ОЗУ
end record;

type THDDCfgRAMO is record
dout    : std_logic_vector(15 downto 0);
rd_rdy  : std_logic;
wr_rdy  : std_logic;
end record;

--//Статусы/Map:
type THDDRBufStatus is record
err      : std_logic;
err_type : THDDRBufErrDetect;
done     : std_logic;
hwlog_size : std_logic_vector(31 downto 0);
ram_wr_o : THDDCfgRAMO;
end record;

type THDDRBufCfg is record
mem_trn : std_logic_vector(15 downto 0);
mem_adr : std_logic_vector(31 downto 0);
dmacfg  : TDMAcfg;
tstgen  : THDDTstGen;
hwlog   : THWLog;
usr     : std_logic_vector(31 downto 0);
usrif   : std_logic;         --//Пользовательский интерфейс
ram_wr_i: THDDCfgRAMI;
greset  : std_logic;         --//Глобальный сброс всего кроме CFG
end record;


component dsn_hdd
generic(
G_MODULE_USE : string:="ON";
G_HDD_COUNT  : integer:=2;
G_GT_DBUS    : integer:=16;
G_DBG        : string:="OFF";
G_DBGCS      : string:="OFF";
G_SIM        : string:="OFF"
);
port(
--------------------------------------------------
-- Конфигурирование модуля DSN_HDD.VHD (p_in_cfg_clk domain)
--------------------------------------------------
p_in_cfg_if               : in   std_logic;
p_in_cfg_clk              : in   std_logic;

p_in_cfg_adr              : in   std_logic_vector(7 downto 0);
p_in_cfg_adr_ld           : in   std_logic;
p_in_cfg_adr_fifo         : in   std_logic;

p_in_cfg_txdata           : in   std_logic_vector(15 downto 0);
p_in_cfg_wd               : in   std_logic;
p_out_cfg_txrdy           : out  std_logic;

p_out_cfg_rxdata          : out  std_logic_vector(15 downto 0);
p_in_cfg_rd               : in   std_logic;
p_out_cfg_rxrdy           : out  std_logic;

p_in_cfg_done             : in   std_logic;
p_in_cfg_rst              : in   std_logic;

--------------------------------------------------
-- STATUS модуля DSN_HDD.VHD
--------------------------------------------------
p_out_hdd_rdy             : out  std_logic;
p_out_hdd_error           : out  std_logic;
p_out_hdd_busy            : out  std_logic;
p_out_hdd_irq             : out  std_logic;
p_out_hdd_done            : out  std_logic;

----------------------------------------------------
-- Связь с Источниками/Приемниками данных накопителя
--------------------------------------------------
p_out_rbuf_cfg            : out  THDDRBufCfg;
p_in_rbuf_status          : in   THDDRBufStatus;

p_in_hdd_txd_wrclk        : in   std_logic;
p_in_hdd_txd              : in   std_logic_vector(31 downto 0);
p_in_hdd_txd_wr           : in   std_logic;
p_out_hdd_txbuf_pfull     : out  std_logic;
p_out_hdd_txbuf_full      : out  std_logic;
p_out_hdd_txbuf_empty     : out  std_logic;

p_in_hdd_rxd_rdclk        : in   std_logic;
p_out_hdd_rxd             : out  std_logic_vector(31 downto 0);
p_in_hdd_rxd_rd           : in   std_logic;
p_out_hdd_rxbuf_pempty    : out  std_logic;
p_out_hdd_rxbuf_empty     : out  std_logic;

--------------------------------------------------
--SATA Driver
--------------------------------------------------
p_out_sata_txn            : out   std_logic_vector((C_SH_GTCH_COUNT_MAX*C_SH_COUNT_MAX(G_HDD_COUNT-1))-1 downto 0);
p_out_sata_txp            : out   std_logic_vector((C_SH_GTCH_COUNT_MAX*C_SH_COUNT_MAX(G_HDD_COUNT-1))-1 downto 0);
p_in_sata_rxn             : in    std_logic_vector((C_SH_GTCH_COUNT_MAX*C_SH_COUNT_MAX(G_HDD_COUNT-1))-1 downto 0);
p_in_sata_rxp             : in    std_logic_vector((C_SH_GTCH_COUNT_MAX*C_SH_COUNT_MAX(G_HDD_COUNT-1))-1 downto 0);

p_in_sata_refclk          : in    std_logic_vector(C_SH_COUNT_MAX(G_HDD_COUNT-1)-1 downto 0);
p_out_sata_refclkout      : out   std_logic;
p_out_sata_gt_plldet      : out   std_logic;
p_out_sata_dcm_lock       : out   std_logic;
p_out_sata_dcm_gclk2div   : out   std_logic;
p_out_sata_dcm_gclk2x     : out   std_logic;
p_out_sata_dcm_gclk0      : out   std_logic;

--------------------------------------------------
--Технологический порт
--------------------------------------------------
p_in_tst                 : in    std_logic_vector(31 downto 0);
p_out_tst                : out   std_logic_vector(31 downto 0);

--------------------------------------------------
--//Debug/Sim
--------------------------------------------------
p_out_dbgcs                 : out   TSH_dbgcs_exp;
p_out_dbgled                : out   THDDLed_SHCountMax;

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
--System
--------------------------------------------------
p_in_clk              : in    std_logic;
p_in_rst              : in    std_logic
);
end component;


end dsn_hdd_pkg;
