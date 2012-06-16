-------------------------------------------------------------------------
-- Company     : Linkos
-- Engineer    : Golovachenko Victor
--
-- Create Date : 31.03.2011 19:15:18
-- Module Name : dsn_hdd_tb
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

library work;
use work.vicg_common_pkg.all;
use work.prj_cfg.all;
use work.dsn_hdd_reg_def.all;
use work.sata_glob_pkg.all;
use work.sata_pkg.all;
use work.sata_raid_pkg.all;
use work.sata_sim_pkg.all;
use work.sata_sim_lite_pkg.all;
use work.sata_unit_pkg.all;
use work.dsn_hdd_pkg.all;
use work.sata_testgen_pkg.all;
use work.mem_wr_pkg.all;

entity dsn_hdd_tb is
generic(
G_CFG_IF      : std_logic:='1';--//Выбор интерфейса управления:0/1 - PCIEXP/UART
--G_HDD_COUNT   : integer:=2;    --//Кол-во sata устр-в (min/max - 1/8)
--G_GT_DBUS     : integer:=32;
--G_DBGCS       : string :="ON";
--G_DBG         : string :="ON";
G_SIM         : string :="ON";
--G_RAMBUF_SIZE : integer:=11; --//(в BYTE). Определяется как 2 в степени G_HDD_RAMBUF_SIZE
--G_RAID_DWIDTH : integer:=128;
G_MEM_AWIDTH  : integer:=32;
G_MEM_DWIDTH  : integer:=64
);
port(
pin_out_tst: out std_logic
);
end dsn_hdd_tb;

architecture behavior of dsn_hdd_tb is

constant G_GT_DBUS     : integer:=C_PCFG_HDD_GT_DBUS;
constant G_DBGCS       : string :=C_PCFG_HDD_DBGCS;
constant G_DBG         : string :=C_PCFG_HDD_DBG;
constant G_HDD_COUNT   : integer:=C_PCFG_HDD_COUNT;
constant G_RAMBUF_SIZE : integer:=C_PCFG_HDD_RAMBUF_SIZE;
constant G_RAID_DWIDTH : integer:=C_PCFG_HDD_RAID_DWIDTH;

constant CI_SECTOR_SIZE_BYTE : integer:=selval(C_SECTOR_SIZE_BYTE, C_SIM_SECTOR_SIZE_DWORD*4, strcmp(G_SIM, "OFF"));

constant C_CFGCLK_PERIOD         : TIME := 6.6*1 ns;          --Тактирование модуля dsn_hdd/wr управляющих регистров
constant C_SATA_GT_REFCLK_PERIOD : TIME := 6.6 ns;--150MHz
constant C_HCLK_PERIOD           : TIME := 8.3 ns;--120MHz; --Тактирование модуля dsn_hdd/логика работы
constant C_VBUF_WRCLK_PERIOD     : TIME := 12.3 ns;--120MHz; 3.6 ns;

component hdd_rambuf_infifo
port (
din    : in std_logic_vector(31 downto 0);
wr_en  : in std_logic;
wr_clk : in std_logic;

dout   : out std_logic_vector(G_MEM_DWIDTH-1 downto 0);
rd_en  : in std_logic;
rd_clk : in std_logic;

empty  : out std_logic;
full   : out std_logic;
prog_full     : out std_logic;
--wr_data_count : out std_logic_vector(3 downto 0);
rd_data_count : out std_logic_vector(3 downto 0);

rst    : in std_logic
);
end component;

component dsn_hdd_rambuf
generic(
G_MODULE_USE  : string:="ON";
G_RAMBUF_SIZE : integer:=23; --//(в BYTE). Определяется как 2 в степени G_RAMBUF_SIZE
G_DBGCS       : string:="OFF";
G_SIM         : string:="OFF";
G_USE_2CH     : string:="ON";
G_MEM_BANK_M_BIT : integer:=31;
G_MEM_BANK_L_BIT : integer:=31;
G_MEM_AWIDTH  : integer:=32;
G_MEM_DWIDTH  : integer:=32
);
port(
-------------------------------
-- Конфигурирование
-------------------------------
p_in_rbuf_cfg         : in    THDDRBufCfg;   --Конфигурирование RAMBUF
p_out_rbuf_status     : out   THDDRBufStatus;--Статусы RAMBUF
p_in_lentrn_exp       : in    std_logic;

----------------------------
--Связь с буфером видеоданных
----------------------------
p_in_bufi_dout        : in    std_logic_vector(G_MEM_DWIDTH-1 downto 0);
p_out_bufi_rd         : out   std_logic;
p_in_bufi_empty       : in    std_logic;
p_in_bufi_full        : in    std_logic;
p_in_bufi_pfull       : in    std_logic;
p_in_bufi_wrcnt       : in    std_logic_vector(3 downto 0);

p_out_bufo_din        : out   std_logic_vector(G_MEM_DWIDTH-1 downto 0);
p_out_bufo_wr         : out   std_logic;
p_in_bufo_full        : in    std_logic;
p_in_bufo_empty       : in    std_logic;

----------------------------
--Связь с модулем HDD
----------------------------
p_out_hdd_txd         : out   std_logic_vector(G_MEM_DWIDTH-1 downto 0);
p_out_hdd_txd_wr      : out   std_logic;
p_in_hdd_txbuf_pfull  : in    std_logic;
p_in_hdd_txbuf_full   : in    std_logic;
p_in_hdd_txbuf_empty  : in    std_logic;

p_in_hdd_rxd          : in    std_logic_vector(G_MEM_DWIDTH-1 downto 0);
p_out_hdd_rxd_rd      : out   std_logic;
p_in_hdd_rxbuf_empty  : in    std_logic;
p_in_hdd_rxbuf_pempty : in    std_logic;

---------------------------------
-- Связь с mem_ctrl.vhd
---------------------------------
p_out_memch0          : out   TMemIN;
p_in_memch0           : in    TMemOUT;

p_out_memch1          : out   TMemIN;
p_in_memch1           : in    TMemOUT;

-------------------------------
--Технологический
-------------------------------
p_in_tst              : in    std_logic_vector(31 downto 0);
p_out_tst             : out   std_logic_vector(31 downto 0);
p_out_dbgcs           : out   TSH_ila;

-------------------------------
--System
-------------------------------
p_in_clk              : in    std_logic;
p_in_rst              : in    std_logic
);
end component;

signal i_sata_gt_refclkmain       : std_logic_vector((C_SH_COUNT_MAX(G_HDD_COUNT-1))-1 downto 0);
signal g_cfg_clk                  : std_logic;
signal p_in_clk                   : std_logic;
signal i_dsn_hdd_rst              : std_logic:='1';

signal i_tst_mode                 : std_logic;
--signal i_tst_cmd                  : integer;
signal i_sw_mode                  : std_logic;
signal i_sata_cs                  : integer;
signal i_hw_mode_stop             : std_logic;

signal i_sata_txn                 : std_logic_vector((C_GTCH_COUNT_MAX*C_SH_COUNT_MAX(G_HDD_COUNT-1))-1 downto 0);
signal i_sata_txp                 : std_logic_vector((C_GTCH_COUNT_MAX*C_SH_COUNT_MAX(G_HDD_COUNT-1))-1 downto 0);
signal i_sata_rxn                 : std_logic_vector((C_GTCH_COUNT_MAX*C_SH_COUNT_MAX(G_HDD_COUNT-1))-1 downto 0);
signal i_sata_rxp                 : std_logic_vector((C_GTCH_COUNT_MAX*C_SH_COUNT_MAX(G_HDD_COUNT-1))-1 downto 0);
signal i_sata_refclk              : std_logic_vector((C_SH_COUNT_MAX(G_HDD_COUNT-1))-1 downto 0);


signal i_usr_raid_status          : TUsrStatus;
signal i_usr_cxdin                : std_logic_vector(15 downto 0);
signal i_usr_cxd_wr               : std_logic;

signal i_cfgdev_if                : std_logic;
signal i_cfgdev_if_tst            : std_logic;
signal i_cfgdev_adr               : std_logic_vector(7 downto 0);
signal i_cfgdev_adr_ld            : std_logic;
signal i_cfgdev_adr_fifo          : std_logic;
signal i_cfgdev_txdata            : std_logic_vector(15 downto 0);
signal i_cfgdev_rxdata            : std_logic_vector(15 downto 0);
signal i_cfgdev_txrdy             : std_logic;
signal i_cfgdev_rxrdy             : std_logic;
signal i_dev_cfg_wd               : std_logic_vector(C_CFGDEV_COUNT-1 downto 0);
signal i_dev_cfg_rd               : std_logic_vector(C_CFGDEV_COUNT-1 downto 0);
signal i_dev_cfg_done             : std_logic_vector(C_CFGDEV_COUNT-1 downto 0);

signal i_dsnhdd_reg_ctrl_val      : std_logic_vector(15 downto 0);
signal i_dsnhdd_reg_hwstart_dly_val: std_logic_vector(15 downto 0);

signal i_rbuf_cfg                 : THDDRBufCfg;
signal i_rbuf_status              : THDDRBufStatus;
signal i_sh_txd                   : std_logic_vector(G_MEM_DWIDTH-1 downto 0);
signal i_sh_txd_wr                : std_logic;
signal i_sh_txbuf_pfull           : std_logic;
signal i_sh_txbuf_full            : std_logic;
signal i_sh_txbuf_empty           : std_logic;
signal i_sh_rxd                   : std_logic_vector(G_MEM_DWIDTH-1 downto 0);
signal i_sh_rxd_rd                : std_logic;
signal i_sh_rxbuf_pempty          : std_logic;
signal i_sh_rxbuf_empty           : std_logic;

signal i_hdd_rdy                  : std_logic;
signal i_hdd_error                : std_logic;
signal i_hdd_busy                 : std_logic;
signal i_hdd_irq                  : std_logic;
signal i_hdd_done                 : std_logic;

signal i_hdd_sim_gt_txdata            : TBus32_SHCountMax;
signal i_hdd_sim_gt_txcharisk         : TBus04_SHCountMax;
signal i_hdd_sim_gt_txcomstart        : std_logic_vector(C_HDD_COUNT_MAX-1 downto 0);
signal i_hdd_sim_gt_rxdata            : TBus32_SHCountMax;
signal i_hdd_sim_gt_rxcharisk         : TBus04_SHCountMax;
signal i_hdd_sim_gt_rxstatus          : TBus03_SHCountMax;
signal i_hdd_sim_gt_rxelecidle        : std_logic_vector(C_HDD_COUNT_MAX-1 downto 0);
signal i_hdd_sim_gt_rxdisperr         : TBus04_SHCountMax;
signal i_hdd_sim_gt_rxnotintable      : TBus04_SHCountMax;
signal i_hdd_sim_gt_rxbyteisaligned   : std_logic_vector(C_HDD_COUNT_MAX-1 downto 0);
signal i_hdd_sim_gt_rst               : std_logic_vector(C_HDD_COUNT_MAX-1 downto 0);
signal i_hdd_sim_gt_clk               : std_logic_vector(C_HDD_COUNT_MAX-1 downto 0);

signal i_memwr_in                     : TMemIN;
signal i_memwr_out                    : TMemOUT;
signal i_memrd_in                     : TMemIN;
signal i_memrd_out                    : TMemOUT;

signal tst_hdd_out                    : std_logic_vector(31 downto 0);

signal i_tstdata_dwsize               : integer:=0;
signal i_loopback                     : std_logic;
signal sr_cmdbusy                     : std_logic_vector(0 to 1);
signal i_cmddone_det_clr              : std_logic:='0';
signal i_cmddone_det                  : std_logic:='0';
signal i_cmd_data                     : TUsrAppCmdPkt;

type TSimBufData2 is array (0 to 6128) of std_logic_vector(128 downto 0);
signal i_ram_txbuf                    : TSimBufData2;
signal i_ram_txbuf_start              : std_logic:='0';
signal i_testdata_sel                 : std_logic:='0';
signal i_ram_rxbuf                    : TSimBufData2;
signal i_ram_rxbuf_start              : std_logic:='0';

signal i_vbuf_din,i_vbuf_din_in       : std_logic_vector(31 downto 0);
signal i_vbuf_wr,i_vbuf_wr_in         : std_logic;
signal i_vbuf_wrclk                   : std_logic;
signal i_vbuf_dout                    : std_logic_vector(G_MEM_DWIDTH-1 downto 0);
signal i_vbuf_rd                      : std_logic;
signal i_vbuf_full                    : std_logic;
signal i_vbuf_pfull                   : std_logic;
signal i_vbuf_empty                   : std_logic;
signal i_vbuf_wrcnt                   : std_logic_vector(3 downto 0);
signal i_vdata_start                  : std_logic;
signal i_vdata_done                   : std_logic;

signal i_hdd_tst_on,i_hdd_tst_on_tmp  : std_logic;
signal i_hdd_tst_d                    : std_logic_vector(31 downto 0);
signal i_hdd_tst_den                  : std_logic;
signal i_hdd_vbuf_rst                 : std_logic;

signal i_dcntwr                       : integer:=0;

type TSataDevStatusSataCount is array (0 to C_HDD_COUNT_MAX-1) of TSataDevStatus;
signal i_satadev_status               : TSataDevStatusSataCount;
signal i_satadev_ctrl                 : TSataDevCtrl;

type TViewTestCtrl is record
ram_txbuf_start  : std_logic;
ram_txbuf_done   : std_logic;
ram_rxbuf_done   : std_logic;
ram_rxbuf_start  : std_logic;
end record;

signal i_sim_ctrl               : TViewTestCtrl;

signal i_tst_dcnt :integer:=0;

signal i_ltrn_count0  : std_logic;
signal i_ltrn_count1  : std_logic;

signal tst_ramread  : std_logic_vector(4 downto 0):=(others=>'0');

signal i_hdd_tstin : std_logic_vector(31 downto 0);
signal i_hm_r  : std_logic:='0';


--MAIN
begin

pin_out_tst<=i_ltrn_count0 or i_ltrn_count1 when i_tst_dcnt=2 else i_ltrn_count1 or OR_reduce(tst_ramread) or
             OR_reduce(i_cfgdev_rxdata) or i_cfgdev_txrdy or i_cfgdev_rxrdy;

--//RESET
i_dsn_hdd_rst<='1','0' after 1 us;

--//Частоты
gen_refclk_sata : for i in 0 to C_SH_COUNT_MAX(G_HDD_COUNT-1)-1 generate
gen_clk_sata : process
begin
  i_sata_gt_refclkmain(i)<='0';
  wait for C_SATA_GT_REFCLK_PERIOD/2;
  i_sata_gt_refclkmain(i)<='1';
  wait for C_SATA_GT_REFCLK_PERIOD/2;
end process;
end generate gen_refclk_sata;

gen_cfg_clk : process
begin
  g_cfg_clk<='0';
  wait for C_CFGCLK_PERIOD/2;
  g_cfg_clk<='1';
  wait for C_CFGCLK_PERIOD/2;
end process;

gen_hclk : process
begin
  p_in_clk<='0';
  wait for C_HCLK_PERIOD/2;
  p_in_clk<='1';
  wait for C_HCLK_PERIOD/2;
end process;

gen_vbuf_wrclk : process
begin
  i_vbuf_wrclk<='0';
  wait for C_VBUF_WRCLK_PERIOD/2;
  i_vbuf_wrclk<='1';
  wait for C_VBUF_WRCLK_PERIOD/2;
end process;


--//Эмуляция HDD
gen_sata_drv : for i in 0 to (C_SH_COUNT_MAX(G_HDD_COUNT-1))-1 generate
i_sata_rxn<=(others=>'0');
i_sata_rxp<=(others=>'1');
end generate gen_sata_drv;

gen_satad : for i in 0 to G_HDD_COUNT-1 generate
m_sata_dev : sata_dev_model
generic map(
G_DBG_LLAYER => "OFF",
G_GT_DBUS    => G_GT_DBUS
)
port map(
----------------------------
--
----------------------------
p_out_gt_txdata          => i_hdd_sim_gt_rxdata(i),
p_out_gt_txcharisk       => i_hdd_sim_gt_rxcharisk(i),

p_in_gt_txcomstart       => i_hdd_sim_gt_txcomstart(i),

p_in_gt_rxdata           => i_hdd_sim_gt_txdata(i),
p_in_gt_rxcharisk        => i_hdd_sim_gt_txcharisk(i),

p_out_gt_rxstatus        => i_hdd_sim_gt_rxstatus(i),
p_out_gt_rxelecidle      => i_hdd_sim_gt_rxelecidle(i),
p_out_gt_rxdisperr       => i_hdd_sim_gt_rxdisperr(i),
p_out_gt_rxnotintable    => i_hdd_sim_gt_rxnotintable(i),
p_out_gt_rxbyteisaligned => i_hdd_sim_gt_rxbyteisaligned(i),

p_in_ctrl                => i_satadev_ctrl,
p_out_status             => i_satadev_status(i),

--------------------------------------------------
--Технологические сигналы
--------------------------------------------------
p_in_tst                 => (others=>'0'),
p_out_tst                => open,

----------------------------
--System
----------------------------
p_in_clk                 => i_hdd_sim_gt_clk(i),
p_in_rst                 => i_hdd_sim_gt_rst(i)
);
end generate gen_satad;


--//Эмуляция FPGA
i_cfgdev_if<=G_CFG_IF;

m_hdd : dsn_hdd
generic map(
G_MEM_DWIDTH => G_MEM_DWIDTH,
G_RAID_DWIDTH=> G_RAID_DWIDTH,
G_MODULE_USE => "ON",
G_HDD_COUNT  => G_HDD_COUNT,
G_GT_DBUS    => G_GT_DBUS,
G_DBG        => G_DBG,
G_DBGCS      => G_DBGCS,
G_SIM        => G_SIM
)
port map(
--------------------------------------------------
-- Конфигурирование модуля DSN_HDD.VHD (p_in_cfg_clk domain)
--------------------------------------------------
p_in_cfg_clk           => g_cfg_clk,

p_in_cfg_adr           => i_cfgdev_adr,
p_in_cfg_adr_ld        => i_cfgdev_adr_ld,
p_in_cfg_adr_fifo      => i_cfgdev_adr_fifo,

p_in_cfg_txdata        => i_cfgdev_txdata,
p_in_cfg_wd            => i_dev_cfg_wd(C_CFGDEV_HDD),
p_out_cfg_txrdy        => i_cfgdev_txrdy,

p_out_cfg_rxdata       => i_cfgdev_rxdata,
p_in_cfg_rd            => i_dev_cfg_rd(C_CFGDEV_HDD),
p_out_cfg_rxrdy        => i_cfgdev_rxrdy,

p_in_cfg_done          => i_dev_cfg_done(C_CFGDEV_HDD),
p_in_cfg_rst           => i_dsn_hdd_rst,-- i_cfgdev_rst,

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

p_in_hdd_txd_wrclk     => p_in_clk,
p_in_hdd_txd           => i_sh_txd,
p_in_hdd_txd_wr        => i_sh_txd_wr,
p_out_hdd_txbuf_pfull  => i_sh_txbuf_pfull,
p_out_hdd_txbuf_full   => i_sh_txbuf_full,
p_out_hdd_txbuf_empty  => i_sh_txbuf_empty,

p_in_hdd_rxd_rdclk     => p_in_clk,
p_out_hdd_rxd          => i_sh_rxd,
p_in_hdd_rxd_rd        => i_sh_rxd_rd,
p_out_hdd_rxbuf_empty  => i_sh_rxbuf_empty,
p_out_hdd_rxbuf_pempty => i_sh_rxbuf_pempty,

--------------------------------------------------
--SATA Driver
--------------------------------------------------
p_out_sata_txn         => i_sata_txn,
p_out_sata_txp         => i_sata_txp,
p_in_sata_rxn          => i_sata_rxn,
p_in_sata_rxp          => i_sata_rxp,

p_in_sata_refclk       => i_sata_gt_refclkmain,
p_out_sata_refclkout   => open,
p_out_sata_gt_plldet   => open,
p_out_sata_dcm_lock    => open,
p_out_sata_dcm_gclk2div=> open,
p_out_sata_dcm_gclk2x  => open,
p_out_sata_dcm_gclk0   => open,

--------------------------------------------------
--Технологический порт
--------------------------------------------------
p_in_tst               => i_hdd_tstin,
p_out_tst              => tst_hdd_out,

--------------------------------------------------
--Моделирование/Отладка - в рабочем проекте не используется
--------------------------------------------------
p_out_sim_gt_txdata         => i_hdd_sim_gt_txdata,
p_out_sim_gt_txcharisk      => i_hdd_sim_gt_txcharisk,
p_out_sim_gt_txcomstart     => i_hdd_sim_gt_txcomstart,
p_in_sim_gt_rxdata          => i_hdd_sim_gt_rxdata,
p_in_sim_gt_rxcharisk       => i_hdd_sim_gt_rxcharisk,
p_in_sim_gt_rxstatus        => i_hdd_sim_gt_rxstatus,
p_in_sim_gt_rxelecidle      => i_hdd_sim_gt_rxelecidle,
p_in_sim_gt_rxdisperr       => i_hdd_sim_gt_rxdisperr,
p_in_sim_gt_rxnotintable    => i_hdd_sim_gt_rxnotintable,
p_in_sim_gt_rxbyteisaligned => i_hdd_sim_gt_rxbyteisaligned,
p_out_gt_sim_rst            => i_hdd_sim_gt_rst,
p_out_gt_sim_clk            => i_hdd_sim_gt_clk,

p_out_dbgled                => open,

--------------------------------------------------
--System
--------------------------------------------------
p_in_clk               => p_in_clk,
p_in_rst               => i_dsn_hdd_rst
);

m_hdd_rambuf : dsn_hdd_rambuf
generic map(
G_MODULE_USE  => "ON",
G_RAMBUF_SIZE => G_RAMBUF_SIZE, --//(в BYTE). Определяется как 2 в степени G_HDD_RAMBUF_SIZE
G_DBGCS       => "ON",
G_SIM         => "ON", --G_SIM
G_USE_2CH     => "ON",
G_MEM_BANK_M_BIT =>31,
G_MEM_BANK_L_BIT =>31,
G_MEM_AWIDTH  => G_MEM_AWIDTH,
G_MEM_DWIDTH  => G_MEM_DWIDTH
)
port map(
-------------------------------
-- Конфигурирование
-------------------------------
p_in_rbuf_cfg         => i_rbuf_cfg,
p_out_rbuf_status     => i_rbuf_status,
p_in_lentrn_exp       => '0',

--//--------------------------
--//Связь с буфером видеоданных
--//--------------------------
p_in_bufi_dout        => i_vbuf_dout,
p_out_bufi_rd         => i_vbuf_rd,
p_in_bufi_empty       => i_vbuf_empty,
p_in_bufi_full        => i_vbuf_full,
p_in_bufi_pfull       => i_vbuf_pfull,
p_in_bufi_wrcnt       => i_vbuf_wrcnt,

p_out_bufo_din        => open,
p_out_bufo_wr         => open,
p_in_bufo_full        => '0',
p_in_bufo_empty       => '0',

--//--------------------------
--//Связь с модулем HDD
--//--------------------------
p_out_hdd_txd         => i_sh_txd,
p_out_hdd_txd_wr      => i_sh_txd_wr,
p_in_hdd_txbuf_pfull  => i_sh_txbuf_pfull,
p_in_hdd_txbuf_full   => i_sh_txbuf_full,
p_in_hdd_txbuf_empty  => i_sh_txbuf_empty,

p_in_hdd_rxd          => i_sh_rxd,
p_out_hdd_rxd_rd      => i_sh_rxd_rd,
p_in_hdd_rxbuf_empty  => i_sh_rxbuf_empty,
p_in_hdd_rxbuf_pempty => i_sh_rxbuf_pempty,

---------------------------------
-- Связь с mem_ctrl.vhd
---------------------------------
p_out_memch0          => i_memwr_in,  --: out   TMemIN;
p_in_memch0           => i_memwr_out, --: in    TMemOUT

p_out_memch1          => i_memrd_in,  --: out   TMemIN;
p_in_memch1           => i_memrd_out, --: in    TMemOUT

-------------------------------
--Технологический
-------------------------------
p_in_tst              => "00000000000000000000000000000000",
p_out_tst             => open,

-------------------------------
--System
-------------------------------
p_in_clk              => p_in_clk,
p_in_rst              => i_dsn_hdd_rst
);

--//Видео Буфер
m_vbuf : hdd_rambuf_infifo
port map(
din        => i_vbuf_din_in,
wr_en      => i_vbuf_wr_in,
wr_clk     => i_vbuf_wrclk,

dout       => i_vbuf_dout,
rd_en      => i_vbuf_rd,
rd_clk     => p_in_clk,

empty  => i_vbuf_empty,
full   => i_vbuf_full,
prog_full => i_vbuf_pfull,
--wr_data_count => i_vbuf_wrcnt,
rd_data_count => i_vbuf_wrcnt,

rst        => i_hdd_vbuf_rst
);
--i_vbuf_pfull<=i_vbuf_wrcnt(1);

i_memwr_out.req_en<='1';
i_memwr_out.cmdbuf_full<='0';
--i_memwr_out.txbuf_full<='0';
i_memwr_out.rxbuf_empty<='0';

i_memrd_out.req_en<='1';
i_memrd_out.cmdbuf_full<='0';
i_memrd_out.txbuf_full<='0';
i_memrd_out.txbuf_empty<='0';

m_hdd_testgen : sata_testgen
generic map(
G_SCRAMBLER => "ON"
)
port map(
p_in_gen_cfg   => i_rbuf_cfg.tstgen,

p_out_rdy      => i_hdd_tst_on_tmp,

p_out_tdata    => i_hdd_tst_d,
p_out_tdata_en => i_hdd_tst_den,

p_in_clk       => i_vbuf_wrclk,
p_in_rst       => i_dsn_hdd_rst
);

i_hdd_tst_on<=i_hdd_tst_on_tmp and i_rbuf_cfg.tstgen.con2rambuf;
i_hdd_vbuf_rst<=i_dsn_hdd_rst or i_rbuf_cfg.tstgen.clr_err;

i_vbuf_din_in<=i_hdd_tst_d   when i_hdd_tst_on='1' else i_vbuf_din(i_vbuf_din_in'range);
i_vbuf_wr_in <=i_hdd_tst_den when i_hdd_tst_on='1' else (i_vbuf_wr and not i_hm_r);


--//----------------------------------------
--//Моделирование
--//----------------------------------------
--//Выделяем задний фронт из сигнала BUSY модуля m_sata_host.
--//Для детектированя завершения АТА команды
lcmddone:process(i_dsn_hdd_rst,p_in_clk)
begin
  if i_dsn_hdd_rst='1' then

    sr_cmdbusy<=(others=>'0');
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

  wait until i_hdd_sim_gt_clk(0)'event and i_hdd_sim_gt_clk(0) = '1';
  i_satadev_ctrl.atacmd_done<='1';
  wait until i_hdd_sim_gt_clk(0)'event and i_hdd_sim_gt_clk(0) = '1';
  i_satadev_ctrl.atacmd_done<='0';

end process;

i_satadev_ctrl.loopback<=i_loopback;
i_satadev_ctrl.link_establish<=i_hdd_rdy;
i_satadev_ctrl.dbuf_wuse<='1';--//1/0 - использовать модель sata_bufdata.vhd/ не использовать
i_satadev_ctrl.dbuf_ruse<='1';



--//########################################
--//Запись данных в ОЗУ
--//########################################
lmem_trn_wr:process(i_dsn_hdd_rst,p_in_clk)
  variable dcnt : integer:=0;
begin
  if i_dsn_hdd_rst='1' then
      for i in 0 to i_ram_txbuf'high loop
      i_ram_rxbuf(i)<=(others=>'0');
      end loop;
      dcnt:=0;
      i_dcntwr<=0;

  elsif p_in_clk'event and p_in_clk='1' then

    if i_sim_ctrl.ram_rxbuf_start = '1' or i_vdata_start='1' then

      --//Инициализация
      for i in 0 to i_ram_txbuf'high loop
      i_ram_rxbuf(i)<=(others=>'0');
      end loop;
      dcnt:=0;

    else
      if i_memwr_in.txd_wr='1' then
        i_ram_rxbuf(dcnt)(G_MEM_DWIDTH - 1 downto 0)<=i_memwr_in.txd(G_MEM_DWIDTH - 1 downto 0);
        if dcnt=i_ram_rxbuf'length-1 then
          dcnt:=0;
        else
          dcnt:=dcnt + 1;
        end if;
      end if;

    end if;

    i_dcntwr<=dcnt;

  end if;
end process lmem_trn_wr;

process
begin
  i_memwr_out.txbuf_full<='0';

  wait until i_dcntwr=16#0E# and p_in_clk'event and p_in_clk='1';
    i_memwr_out.txbuf_full<='1';
  wait for 200 ns;

  wait until  p_in_clk'event and p_in_clk='1';
    i_memwr_out.txbuf_full<='0';

  wait;
end process;

i_sim_ctrl.ram_rxbuf_done<=i_rbuf_status.done;


--//########################################
--//Чтение данных ОЗУ
--//########################################
lmem_trn_rd:process
  variable memtrn_term: std_logic:='0';
  variable dcnt       : integer;
  variable memrd_trnlen: integer;
  variable srcambler  : std_logic_vector(31 downto 0):=(others=>'0');
  variable GUI_line   : LINE;--Строка для вывода в ModelSim
begin
  tst_ramread<=(others=>'0');
  i_memrd_out.rxd<=CONV_STD_LOGIC_VECTOR(1, i_memrd_out.rxd'length);
  i_memrd_out.rxbuf_empty<='1';
  i_sim_ctrl.ram_txbuf_done<='0';
    memrd_trnlen:=0;
    memtrn_term:='0';
    srcambler:=srambler32_0(CONV_STD_LOGIC_VECTOR(16#1032#, 16));

  while true loop

      wait until i_sim_ctrl.ram_txbuf_start = '1' or i_vdata_start = '1';--//Ждем разрешения чтения данных
          tst_ramread(0)<='1';
          --//Инициализация
          if i_cfgdev_if_tst='0' then
            for i in 0 to i_ram_txbuf'high loop
            i_ram_txbuf(i)<=(others=>'0');
            end loop;
          end if;

          if i_sw_mode='1' and i_cfgdev_if_tst='0' then
            --//Генератор тестовых данных
            for i in 0 to i_ram_txbuf'high loop
              if i_testdata_sel='0' then
                i_ram_txbuf(i)<=CONV_STD_LOGIC_VECTOR(i+1, i_ram_txbuf(i)'length);--счетчик
              else
                i_ram_txbuf(i)(srcambler'range)<=srcambler;--//Random Data
              end if;
              srcambler:=srambler32_0(srcambler(31 downto 16));--//Инкрементация скремблера
            end loop;
          end if;

          wait until p_in_clk'event and p_in_clk='1';
          dcnt:=1;
          i_memrd_out.rxd(G_MEM_DWIDTH - 1 downto 0)<=i_ram_txbuf(0)(G_MEM_DWIDTH - 1 downto 0);

--      if i_sw_mode='1' then
--      --//-------------------------------------
--      --//SW mode
--      --//-------------------------------------
--          --//Чтение данных ОЗУ
--          while dcnt<i_tstdata_dwsize+1 loop
--
--              i_tst_dcnt<=dcnt;
--
--              wait until i_memrd_in.cmd_wr='1' and p_in_clk'event and p_in_clk='1';--//Ждем начала trn_mem_rd
--              i_memrd_out.rxbuf_empty<='0';
--              while memrd_trnlen/=64 loop
--                wait until p_in_clk'event and p_in_clk='1';
--
--                    if i_memrd_in.rxd_rd='1' then
--                      i_memrd_out.rxd(G_MEM_DWIDTH - 1 downto 0)<=i_ram_txbuf(dcnt)(G_MEM_DWIDTH - 1 downto 0);
--                      memrd_trnlen:=memrd_trnlen + 1;
--                      if dcnt=i_ram_txbuf'length-1 then
--                        dcnt:=1;
--                      else
--                        dcnt:=dcnt + 1;
--                      end if;
--                    end if;
--                  end if;
--              end loop;--//while i_memrd_in.term='0' loop
--
--              i_memrd_out.rxbuf_empty<='1';
--                memrd_trnlen:=1;
--          end loop;--//while dcnt<i_tstdata_dwsize+1 loop
--
--      else
      if i_sw_mode='0' then
      --//-------------------------------------
      --//HW mode
      --//-------------------------------------
          --//Чтение данных ОЗУ
          while i_hw_mode_stop='0' loop
              tst_ramread(1)<='1';
              wait until i_memrd_in.cmd_wr='1' and p_in_clk'event and p_in_clk='1';--//Ждем начала trn_mem_rd
              tst_ramread(2)<='1';
              tst_ramread(3)<='1';
              i_memrd_out.rxbuf_empty<='0';
              while memrd_trnlen/=64 loop
                wait until p_in_clk'event and p_in_clk='1';
                    if i_memrd_in.rxd_rd='1' then--//
                      i_memrd_out.rxd(G_MEM_DWIDTH - 1 downto 0)<=i_ram_rxbuf(dcnt)(G_MEM_DWIDTH - 1 downto 0);
                      memrd_trnlen:=memrd_trnlen + 1;
                      if dcnt=i_ram_txbuf'length-1 then
                        dcnt:=1;
                      else
                        dcnt:=dcnt + 1;
                      end if;
                    end if;--//
              end loop;--//while memrd_trnlen/=64 loop

              if dcnt=0 then
                dcnt:=i_ram_txbuf'length-1;
--              else
--                dcnt:=dcnt - 1;
              end if;
              i_memrd_out.rxbuf_empty<='1';
                memrd_trnlen:=0;
          end loop;

--      else
--        wait until p_in_clk'event and p_in_clk='1';
      end if;

      wait until p_in_clk'event and p_in_clk='1';
        i_sim_ctrl.ram_txbuf_done<='1';
      wait until p_in_clk'event and p_in_clk='1';
        i_sim_ctrl.ram_txbuf_done<='0';

  end loop;

  wait;
end process lmem_trn_rd;


--//########################################
--//Запись данных в VBUF
--//########################################
ltxvd:process
  variable dcnt      : integer;
  variable srcambler : std_logic_vector(31 downto 0):=(others=>'0');
  variable GUI_line  : LINE;--Строка для вывода в ModelSim
begin

  i_vbuf_din<=(others=>'0');
  i_vbuf_wr<='0';
  i_vdata_done<='0';
    srcambler:=srambler32_0(CONV_STD_LOGIC_VECTOR(16#1032#, 16));

  while true loop

      --//-------------------------------------
      --//HW mode
      --//-------------------------------------
          wait until i_vdata_start = '1';--//Ждем разрешения записи данных

          --//Инициализация
          dcnt:=0;
          --//Запись данных в TxBuf(m_txbuf)
          lbufd_wr_hw:while i_hw_mode_stop='0' loop

              lmemtrn_wr_hw:while i_vbuf_wrcnt(2)/='1' loop

                    wait until i_vbuf_wrclk'event and i_vbuf_wrclk='1';
                    i_vbuf_wr<='1';
                    if i_testdata_sel='0' then
                      i_vbuf_din<=CONV_STD_LOGIC_VECTOR(dcnt, i_vbuf_din'length);--счетчик
                    else
                      i_vbuf_din<=srcambler;--//Random Data
                    end if;
                    srcambler:=srambler32_0(srcambler(31 downto 16));--//Инкрементация скремблера

                    if dcnt=65535 then
                      dcnt:=0;
                    else
                      dcnt:=dcnt + 1;
                    end if;

                    wait until i_vbuf_wrclk'event and i_vbuf_wrclk='1';
                    i_vbuf_wr<='0';
              end loop lmemtrn_wr_hw;

          wait until p_in_clk'event and p_in_clk='1';

          end loop lbufd_wr_hw;

          wait until p_in_clk'event and p_in_clk='1';
            i_vdata_done<='1';
          wait until p_in_clk'event and p_in_clk='1';
            i_vdata_done<='0';

  end loop;

  wait;
end process ltxvd;




--//########################################
--//Main Ctrl
--//########################################
--//Логика работы автомата управления
lmain_ctrl:process
  type TUsrAppCmdPkt_tmp is array (0 to 9) of std_logic_vector(15 downto 0);
  type TSimCfgCmdPkts is array (0 to 64) of TSimCfgCmdPkt;
  variable cmd_data         : TUsrAppCmdPkt_tmp;
  variable cfgCmdPkt        : TSimCfgCmdPkts;
  variable cmd_write        : std_logic:='0';
  variable cmd_read         : std_logic:='0';
  variable raid_mode        : std_logic:='0';
  variable mnl_sata_cs      : integer;
  variable tst_cmd          : integer:=0;
  variable hw_cmd           : integer:=0;
  variable hw_lba_start     : integer:=0;
  variable hw_lba_end       : integer:=0;
  variable hw_scount        : integer:=0;
  variable string_value     : std_logic_vector(3 downto 0);
  variable GUI_line         : LINE;--Строка для вывода в ModelSim
  variable memwr_lentrn_byte: std_logic_vector(16 + log2(CI_SECTOR_SIZE_BYTE)-1 downto 0);
  variable memwr_lentrn_dw  : std_logic_vector(memwr_lentrn_byte'range);
  variable memrd_lentrn_byte: std_logic_vector(memwr_lentrn_byte'range);
  variable memrd_lentrn_dw  : std_logic_vector(memwr_lentrn_byte'range);

begin

  i_hdd_tstin<=(others=>'0');

  --//---------------------------------------------------
  --/Настраиваем Параметры моделирования:
  --//---------------------------------------------------
  --//настройка RAMBUF: направление RAM->HDD
----  memwr_lentrn_byte:=CONV_STD_LOGIC_VECTOR(CI_SECTOR_SIZE_BYTE, memwr_lentrn_byte'length);
--  memwr_lentrn_byte:=CONV_STD_LOGIC_VECTOR(64, memwr_lentrn_byte'length);
--  memwr_lentrn_dw:=("00"&memwr_lentrn_byte(memwr_lentrn_byte'high downto 2));
  memwr_lentrn_dw:=CONV_STD_LOGIC_VECTOR(64, memwr_lentrn_byte'length);

  --//настройка RAMBUF: направление RAM<-HDD
----  memrd_lentrn_byte:=CONV_STD_LOGIC_VECTOR(CI_SECTOR_SIZE_BYTE, memrd_lentrn_byte'length);
--  memrd_lentrn_byte:=CONV_STD_LOGIC_VECTOR(64, memrd_lentrn_byte'length);
--  memrd_lentrn_dw:=("00"&memrd_lentrn_byte(memrd_lentrn_byte'high downto 2));
  memrd_lentrn_dw:=CONV_STD_LOGIC_VECTOR(64, memrd_lentrn_byte'length);

  --//Выбор режима:
  --C_ATA_CMD_WRITE_SECTORS_EXT;--C_ATA_CMD_WRITE_DMA_EXT;--C_ATA_CMD_READ_SECTORS_EXT;--
  i_testdata_sel<='0'; --//0/1 - Счетчик/Random DATA
  i_sw_mode <='0';--//1/0 - sw_mode/hw_mode
  i_tst_mode<='0';--//режим тестирования
  raid_mode:='1';
--  mnl_sata_cs:=16#03#; --//Только когда выключен режим raid_mode
  i_sata_cs<=16#03#;

  --//Только для режима тестирования
  tst_cmd:=C_ATA_CMD_WRITE_DMA_EXT;--C_ATA_CMD_READ_DMA_EXT;--C_ATA_CMD_READ_SECTORS_EXT;--C_ATA_CMD_WRITE_SECTORS_EXT;--

  --//Только для режима HW(hw_mode)
  hw_scount:=4;
  hw_cmd:=C_ATA_CMD_READ_DMA_EXT;--C_ATA_CMD_WRITE_DMA_EXT; --C_ATA_CMD_WRITE_SECTORS_EXT;--//Только когда выключен режим i_tst_mode
  hw_lba_start:=16#000#;
  hw_lba_end  :=hw_lba_start + (hw_scount * 20);


  if hw_cmd=C_ATA_CMD_READ_DMA_EXT or hw_cmd=C_ATA_CMD_READ_SECTORS_EXT then
    i_hm_r<='1';
  else
    i_hm_r<='0';
  end if;
  i_cfgdev_if_tst<='0';



  --//---------------------------------------------------
  --/Инициализация
  --//---------------------------------------------------
  i_ltrn_count0<='0';
  i_ltrn_count1<='0';

  i_dsnhdd_reg_ctrl_val<=(others=>'0');
--  i_dsnhdd_reg_ctrl_val(C_HDD_REG_CTRLL_TST_ON_BIT)<='0';
--  i_dsnhdd_reg_ctrl_val(C_HDD_REG_CTRLL_TST_GEN2RAMBUF_BIT)<='0';
--  i_dsnhdd_reg_ctrl_val(C_HDD_REG_CTRLL_ERR_STREMBUF_DIS_BIT)<='0'; --1/0 -Disable/Enable
--  i_dsnhdd_reg_ctrl_val(C_HDD_REG_CTRLL_HWLOG_ON_BIT)<='0';
----  i_dsnhdd_reg_ctrl_val(C_HDD_REG_CTRLL_HWSTART_DLY_ON_BIT)<='0';
--  i_dsnhdd_reg_ctrl_val(C_HDD_REG_CTRLL_DBGLED_OFF_BIT)<='0';
--  --//1- min ... 256/0 - max
----  i_dsnhdd_reg_ctrl_val(C_HDD_REG_CTRLL_TST_SPD_M_BIT downto C_HDD_REG_CTRLL_TST_SPD_L_BIT)<=CONV_STD_LOGIC_VECTOR(((2**(C_HDD_REG_CTRLL_TST_SPD_M_BIT-C_HDD_REG_CTRLL_TST_SPD_L_BIT+1))*100)/128, C_HDD_REG_CTRLL_TST_SPD_M_BIT-C_HDD_REG_CTRLL_TST_SPD_L_BIT+1);
--  i_dsnhdd_reg_ctrl_val(C_HDD_REG_CTRLL_TST_SPD_M_BIT downto C_HDD_REG_CTRLL_TST_SPD_L_BIT)<=CONV_STD_LOGIC_VECTOR(250, C_HDD_REG_CTRLL_TST_SPD_M_BIT-C_HDD_REG_CTRLL_TST_SPD_L_BIT+1);

  i_dsnhdd_reg_hwstart_dly_val(11 downto 0)<=CONV_STD_LOGIC_VECTOR(512, 12);--//фиксирования задержка
  i_dsnhdd_reg_hwstart_dly_val(15 downto 12)<=CONV_STD_LOGIC_VECTOR(1, 4);--//фиксирования задержка

--  i_dsnhdd_reg_hwstart_dly_val(3 downto   0)<=CONV_STD_LOGIC_VECTOR(2, 3);--//адаптивная задержка
--  i_dsnhdd_reg_hwstart_dly_val(7 downto   4)<=CONV_STD_LOGIC_VECTOR(3, 4);
--  i_dsnhdd_reg_hwstart_dly_val(11 downto  8)<=CONV_STD_LOGIC_VECTOR(4, 4);
--  i_dsnhdd_reg_hwstart_dly_val(15 downto 12)<=CONV_STD_LOGIC_VECTOR(5, 4);


--  if    G_HDD_COUNT=2 and raid_mode='1' then i_sata_cs<=16#03#;
--  elsif G_HDD_COUNT=3 and raid_mode='1' then i_sata_cs<=16#07#;
--  elsif G_HDD_COUNT=4 and raid_mode='1' then i_sata_cs<=16#0F#;
--  elsif G_HDD_COUNT=5 and raid_mode='1' then i_sata_cs<=16#1F#;
--  elsif G_HDD_COUNT=6 and raid_mode='1' then i_sata_cs<=16#3F#;
--  elsif G_HDD_COUNT=7 and raid_mode='1' then i_sata_cs<=16#7F#;
--  elsif G_HDD_COUNT=8 and raid_mode='1' then i_sata_cs<=16#FF#;
--  else                                       i_sata_cs<=mnl_sata_cs;
--  end if;

  i_hw_mode_stop<='0';

  i_cfgdev_adr<=(others=>'0');
  i_cfgdev_adr_ld<='0';
  i_cfgdev_adr_fifo<='0';
  i_cfgdev_txdata<=(others=>'0');
  i_dev_cfg_wd<=(others=>'0');
  i_dev_cfg_rd<=(others=>'0');
  i_dev_cfg_done<=(others=>'0');

  i_vdata_start<='0';
  i_sim_ctrl.ram_txbuf_start<='0';
  i_sim_ctrl.ram_rxbuf_start<='0';
  i_tstdata_dwsize<=0;
  i_loopback<='0';
  i_cmddone_det_clr<='0';
  for i in 0 to cmd_data'high loop
  cmd_data(i):=(others=>'0');
  end loop;
  for i in 0 to i_cmd_data'high loop
  i_cmd_data(i)<=(others=>'0');
  end loop;
  for i in 0 to cfgCmdPkt'high loop
  cfgCmdPkt(i).usr_ctrl:=(others=>'0');
  cfgCmdPkt(i).command:=C_ATA_CMD_READ_SECTORS_EXT;
  cfgCmdPkt(i).scount:=1;
  cfgCmdPkt(i).lba:=(others=>'0');
  cfgCmdPkt(i).loopback:='0';
  cfgCmdPkt(i).device:=(others=>'0');
  cfgCmdPkt(i).control:=(others=>'0');
  cfgCmdPkt(i).raid_cl:=1;
  end loop;


  wait until i_dsn_hdd_rst='0';
  wait until i_hdd_busy='0';

  --//Конфигурируем RAMBUF
  wait until g_cfg_clk'event and g_cfg_clk='1';
    i_cfgdev_adr<=CONV_STD_LOGIC_VECTOR(C_HDD_REG_RBUF_TRNLEN, i_cfgdev_adr'length);
    i_cfgdev_adr_ld<='1';
    i_cfgdev_adr_fifo<='0';
  wait until g_cfg_clk'event and g_cfg_clk='1';
    i_cfgdev_adr_ld<='0';
    i_cfgdev_adr_fifo<='0';
    i_cfgdev_txdata(7 downto 0) <=memwr_lentrn_dw(7 downto 0);
    i_cfgdev_txdata(15 downto 8)<=memrd_lentrn_dw(7 downto 0);
    i_dev_cfg_wd(C_CFGDEV_HDD)<='1';
  wait until g_cfg_clk'event and g_cfg_clk='1';
    i_dev_cfg_wd(C_CFGDEV_HDD)<='0';
  wait for 0.1 us;
  wait until g_cfg_clk'event and g_cfg_clk='1';
  i_dev_cfg_done(C_CFGDEV_HDD)<='1';
  wait until g_cfg_clk'event and g_cfg_clk='1';
  i_dev_cfg_done(C_CFGDEV_HDD)<='0';

  wait for 0.5 us;

  wait until g_cfg_clk'event and g_cfg_clk='1';
    i_cfgdev_adr<=CONV_STD_LOGIC_VECTOR(C_HDD_REG_RBUF_REQLEN, i_cfgdev_adr'length);
    i_cfgdev_adr_ld<='1';
    i_cfgdev_adr_fifo<='0';
  wait until g_cfg_clk'event and g_cfg_clk='1';
    i_cfgdev_adr_ld<='0';
    i_cfgdev_adr_fifo<='0';
    i_cfgdev_txdata(11 downto 0)<=CONV_STD_LOGIC_VECTOR(1024, 12);
    i_cfgdev_txdata(15 downto 12)<=(others=>'0');
    i_dev_cfg_wd(C_CFGDEV_HDD)<='1';
  wait until g_cfg_clk'event and g_cfg_clk='1';
    i_dev_cfg_wd(C_CFGDEV_HDD)<='0';
  wait for 0.1 us;
  wait until g_cfg_clk'event and g_cfg_clk='1';
  i_dev_cfg_done(C_CFGDEV_HDD)<='1';
  wait until g_cfg_clk'event and g_cfg_clk='1';
  i_dev_cfg_done(C_CFGDEV_HDD)<='0';

  wait for 0.5 us;

--  --//Конфигурируем тестовый режим
--  if i_tst_mode='1' then
  wait until g_cfg_clk'event and g_cfg_clk='1';
    i_cfgdev_adr<=CONV_STD_LOGIC_VECTOR(16#88#, i_cfgdev_adr'length);
    i_cfgdev_adr_ld<='1';
    i_cfgdev_adr_fifo<='0';
  wait until g_cfg_clk'event and g_cfg_clk='1';
    i_cfgdev_adr_ld<='0';
    i_cfgdev_adr_fifo<='0';
    i_cfgdev_txdata<=i_dsnhdd_reg_hwstart_dly_val;
    i_dev_cfg_wd(C_CFGDEV_HDD)<='1';
  wait until g_cfg_clk'event and g_cfg_clk='1';
    i_dev_cfg_wd(C_CFGDEV_HDD)<='0';
--  end if;--//if i_tst_mode='1' then
  wait for 0.1 us;
  wait until g_cfg_clk'event and g_cfg_clk='1';
  i_dev_cfg_done(C_CFGDEV_HDD)<='1';
  wait until g_cfg_clk'event and g_cfg_clk='1';
  i_dev_cfg_done(C_CFGDEV_HDD)<='0';

  wait for 0.5 us;

--  --//Конфигурируем тестовый режим
--  if i_tst_mode='1' then
  wait until g_cfg_clk'event and g_cfg_clk='1';
    i_cfgdev_adr<=CONV_STD_LOGIC_VECTOR(C_HDD_REG_CTRL_L, i_cfgdev_adr'length);
    i_cfgdev_adr_ld<='1';
    i_cfgdev_adr_fifo<='0';
  wait until g_cfg_clk'event and g_cfg_clk='1';
    i_cfgdev_adr_ld<='0';
    i_cfgdev_adr_fifo<='0';
    i_cfgdev_txdata<=i_dsnhdd_reg_ctrl_val;
    i_dev_cfg_wd(C_CFGDEV_HDD)<='1';
  wait until g_cfg_clk'event and g_cfg_clk='1';
    i_dev_cfg_wd(C_CFGDEV_HDD)<='0';
--  end if;--//if i_tst_mode='1' then
  wait for 0.1 us;
  wait until g_cfg_clk'event and g_cfg_clk='1';
  i_dev_cfg_done(C_CFGDEV_HDD)<='1';
  wait until g_cfg_clk'event and g_cfg_clk='1';
  i_dev_cfg_done(C_CFGDEV_HDD)<='0';

  wait for 0.5 us;


  write(GUI_line,string'("HWCFG_CMD: WR"));writeline(output, GUI_line);
--  i_hdd_tstin(23 downto 21)<="001";--WR
--  i_hdd_tstin(23 downto 21)<="010";--RD
--  i_hdd_tstin(23 downto 21)<="011";--STOP
  i_hdd_tstin(23 downto 21)<="100";--TEST

  wait for 20.5 us;

  write(GUI_line,string'("HWCFG_CMD: STOP."));writeline(output, GUI_line);
--  i_hdd_tstin(23 downto 21)<="001";--WR
--  i_hdd_tstin(23 downto 21)<="010";--RD
  i_hdd_tstin(23 downto 21)<="011";--STOP
--  i_hdd_tstin(23 downto 21)<="100";--TEST

  wait for 10.5 us;

  write(GUI_line,string'("HWCFG_CMD: RD"));writeline(output, GUI_line);
--  i_hdd_tstin(23 downto 21)<="001";--WR
  i_hdd_tstin(23 downto 21)<="010";--RD
--  i_hdd_tstin(23 downto 21)<="011";--STOP
--  i_hdd_tstin(23 downto 21)<="100";--TEST

  wait for 20.5 us;

  write(GUI_line,string'("HWCFG_CMD: STOP."));writeline(output, GUI_line);
--  i_hdd_tstin(23 downto 21)<="001";--WR
--  i_hdd_tstin(23 downto 21)<="010";--RD
  i_hdd_tstin(23 downto 21)<="011";--STOP
--  i_hdd_tstin(23 downto 21)<="100";--TEST

  wait for 200.5 us;

--          --//Тестирование записи данных в ОЗУ через CFG
--          if i_cfgdev_if=C_HDD_CFGIF_UART then
--
--            for i in 0 to 24-1 loop
--              wait until g_cfg_clk'event and g_cfg_clk='1';
--                i_cfgdev_adr<=CONV_STD_LOGIC_VECTOR(C_HDD_REG_RBUF_DATA, i_cfgdev_adr'length);
--                i_cfgdev_adr_ld<='1';
--                i_cfgdev_adr_fifo<='0';
--              wait until g_cfg_clk'event and g_cfg_clk='1';
--                i_cfgdev_adr_ld<='0';
--                i_cfgdev_adr_fifo<='1';
--                i_cfgdev_txdata<=CONV_STD_LOGIC_VECTOR(i, i_cfgdev_txdata'length);
--                i_dev_cfg_wd(C_CFGDEV_HDD)<='1';
--              wait until g_cfg_clk'event and g_cfg_clk='1';
--                i_dev_cfg_wd(C_CFGDEV_HDD)<='0';
--              wait for 0.1 us;
--            end loop;
--            wait until g_cfg_clk'event and g_cfg_clk='1';
--            i_dev_cfg_done(C_CFGDEV_HDD)<='1';
--            wait until g_cfg_clk'event and g_cfg_clk='1';
--            i_dev_cfg_done(C_CFGDEV_HDD)<='0';
--
--            write(GUI_line,string'("module DSN_HDD: C_HDD_CFGIF_UART."));writeline(output, GUI_line);
--            wait;
--          end if;

  write(GUI_line,string'("module DSN_HDD: cfg reg - DONE."));writeline(output, GUI_line);

  --//Инициализируем команды которые будут отправлятся:
  if i_sw_mode='0' then
  --//####################
  --//HW mode:
  --//####################
  --//Пакет с командой LBAEND
  cfgCmdPkt(0).usr_ctrl(C_HDDPKT_SATA_CS_M_BIT downto C_HDDPKT_SATA_CS_L_BIT):=CONV_STD_LOGIC_VECTOR(0, C_HDDPKT_SATA_CS_M_BIT-C_HDDPKT_SATA_CS_L_BIT+1);
  cfgCmdPkt(0).usr_ctrl(C_HDDPKT_RAIDCMD_M_BIT downto C_HDDPKT_RAIDCMD_L_BIT):=CONV_STD_LOGIC_VECTOR(C_RAIDCMD_LBAEND, C_HDDPKT_RAIDCMD_M_BIT-C_HDDPKT_RAIDCMD_L_BIT+1);
  cfgCmdPkt(0).usr_ctrl(C_HDDPKT_SATACMD_M_BIT downto C_HDDPKT_SATACMD_L_BIT):=CONV_STD_LOGIC_VECTOR(C_SATACMD_NULL, C_HDDPKT_SATACMD_M_BIT-C_HDDPKT_SATACMD_L_BIT+1);
  cfgCmdPkt(0).command:=0;
  cfgCmdPkt(0).scount:=0;--//Кол-во секторов
  cfgCmdPkt(0).raid_cl:=0;
  cfgCmdPkt(0).lba:=CONV_STD_LOGIC_VECTOR(16#0000#, 16)&CONV_STD_LOGIC_VECTOR(16#0000#, 16)&CONV_STD_LOGIC_VECTOR(hw_lba_end, 16);--//LBA
  cfgCmdPkt(0).loopback:='0';

  --//Пакет с командой HW
  cfgCmdPkt(1).usr_ctrl(C_HDDPKT_SATA_CS_M_BIT downto C_HDDPKT_SATA_CS_L_BIT):=CONV_STD_LOGIC_VECTOR(i_sata_cs, C_HDDPKT_SATA_CS_M_BIT-C_HDDPKT_SATA_CS_L_BIT+1);
  cfgCmdPkt(1).usr_ctrl(C_HDDPKT_RAIDCMD_M_BIT downto C_HDDPKT_RAIDCMD_L_BIT):=CONV_STD_LOGIC_VECTOR(C_RAIDCMD_HW, C_HDDPKT_RAIDCMD_M_BIT-C_HDDPKT_RAIDCMD_L_BIT+1);
  cfgCmdPkt(1).usr_ctrl(C_HDDPKT_SATACMD_M_BIT downto C_HDDPKT_SATACMD_L_BIT):=CONV_STD_LOGIC_VECTOR(C_SATACMD_ATACOMMAND, C_HDDPKT_SATACMD_M_BIT-C_HDDPKT_SATACMD_L_BIT+1);
  if i_tst_mode='0' then
  cfgCmdPkt(1).command:=hw_cmd;
  else
  cfgCmdPkt(1).command:=tst_cmd;--//Режим тестирования
  end if;
  cfgCmdPkt(1).scount:=hw_scount;--//Кол-во секторов
  cfgCmdPkt(1).raid_cl:=1;
  cfgCmdPkt(1).lba:=CONV_STD_LOGIC_VECTOR(16#0000#, 16)&CONV_STD_LOGIC_VECTOR(16#0000#, 16)&CONV_STD_LOGIC_VECTOR(hw_lba_start, 16);--//LBA
  cfgCmdPkt(1).loopback:='0';


  else
  --//####################
  --//SW mode:
  --//####################
  cfgCmdPkt(0).usr_ctrl(C_HDDPKT_SATA_CS_M_BIT downto C_HDDPKT_SATA_CS_L_BIT):=CONV_STD_LOGIC_VECTOR(i_sata_cs, C_HDDPKT_SATA_CS_M_BIT-C_HDDPKT_SATA_CS_L_BIT+1);
  cfgCmdPkt(0).usr_ctrl(C_HDDPKT_RAIDCMD_M_BIT downto C_HDDPKT_RAIDCMD_L_BIT):=CONV_STD_LOGIC_VECTOR(C_RAIDCMD_SW, C_HDDPKT_RAIDCMD_M_BIT-C_HDDPKT_RAIDCMD_L_BIT+1);
  cfgCmdPkt(0).usr_ctrl(C_HDDPKT_SATACMD_M_BIT downto C_HDDPKT_SATACMD_L_BIT):=CONV_STD_LOGIC_VECTOR(C_SATACMD_ATACOMMAND, C_HDDPKT_SATACMD_M_BIT-C_HDDPKT_SATACMD_L_BIT+1);
  cfgCmdPkt(0).command:=C_ATA_CMD_WRITE_DMA_EXT;--C_ATA_CMD_WRITE_SECTORS_EXT;--C_ATA_CMD_READ_SECTORS_EXT;--C_ATA_CMD_NOP;--
  cfgCmdPkt(0).scount:=1;--//Кол-во секторов
  cfgCmdPkt(0).raid_cl:=1;
  cfgCmdPkt(0).lba:=CONV_STD_LOGIC_VECTOR(16#0605#, 16)&CONV_STD_LOGIC_VECTOR(16#0403#, 16)&CONV_STD_LOGIC_VECTOR(16#0201#, 16);--//LBA
  cfgCmdPkt(0).loopback:='1';

  cfgCmdPkt(1).usr_ctrl(C_HDDPKT_SATA_CS_M_BIT downto C_HDDPKT_SATA_CS_L_BIT):=CONV_STD_LOGIC_VECTOR(i_sata_cs, C_HDDPKT_SATA_CS_M_BIT-C_HDDPKT_SATA_CS_L_BIT+1);
  cfgCmdPkt(1).usr_ctrl(C_HDDPKT_RAIDCMD_M_BIT downto C_HDDPKT_RAIDCMD_L_BIT):=CONV_STD_LOGIC_VECTOR(C_RAIDCMD_SW, C_HDDPKT_RAIDCMD_M_BIT-C_HDDPKT_RAIDCMD_L_BIT+1);
  cfgCmdPkt(1).usr_ctrl(C_HDDPKT_SATACMD_M_BIT downto C_HDDPKT_SATACMD_L_BIT):=CONV_STD_LOGIC_VECTOR(C_SATACMD_ATACOMMAND, C_HDDPKT_SATACMD_M_BIT-C_HDDPKT_SATACMD_L_BIT+1);
  cfgCmdPkt(1).command:=C_ATA_CMD_READ_DMA_EXT;--C_ATA_CMD_READ_SECTORS_EXT;--C_ATA_CMD_WRITE_SECTORS_EXT;--
  cfgCmdPkt(1).scount:=1;
  cfgCmdPkt(1).raid_cl:=1;
  cfgCmdPkt(1).lba:=CONV_STD_LOGIC_VECTOR(16#6655#, 16)&CONV_STD_LOGIC_VECTOR(16#4433#, 16)&CONV_STD_LOGIC_VECTOR(16#2211#, 16);--//LBA
  cfgCmdPkt(1).loopback:='1';

  cfgCmdPkt(2).usr_ctrl(C_HDDPKT_SATA_CS_M_BIT downto C_HDDPKT_SATA_CS_L_BIT):=CONV_STD_LOGIC_VECTOR(i_sata_cs, C_HDDPKT_SATA_CS_M_BIT-C_HDDPKT_SATA_CS_L_BIT+1);
  cfgCmdPkt(2).usr_ctrl(C_HDDPKT_RAIDCMD_M_BIT downto C_HDDPKT_RAIDCMD_L_BIT):=CONV_STD_LOGIC_VECTOR(C_RAIDCMD_SW, C_HDDPKT_RAIDCMD_M_BIT-C_HDDPKT_RAIDCMD_L_BIT+1);
  cfgCmdPkt(2).usr_ctrl(C_HDDPKT_SATACMD_M_BIT downto C_HDDPKT_SATACMD_L_BIT):=CONV_STD_LOGIC_VECTOR(C_SATACMD_ATACOMMAND, C_HDDPKT_SATACMD_M_BIT-C_HDDPKT_SATACMD_L_BIT+1);
  cfgCmdPkt(2).command:=C_ATA_CMD_WRITE_SECTORS_EXT;--C_ATA_CMD_WRITE_DMA_EXT;--
  cfgCmdPkt(2).scount:=4;
  cfgCmdPkt(2).raid_cl:=1;
  cfgCmdPkt(2).lba:=CONV_STD_LOGIC_VECTOR(16#0605#, 16)&CONV_STD_LOGIC_VECTOR(16#0403#, 16)&CONV_STD_LOGIC_VECTOR(16#0201#, 16);--//LBA
  cfgCmdPkt(2).loopback:='1';

  cfgCmdPkt(3).usr_ctrl(C_HDDPKT_SATA_CS_M_BIT downto C_HDDPKT_SATA_CS_L_BIT):=CONV_STD_LOGIC_VECTOR(i_sata_cs, C_HDDPKT_SATA_CS_M_BIT-C_HDDPKT_SATA_CS_L_BIT+1);
  cfgCmdPkt(3).usr_ctrl(C_HDDPKT_RAIDCMD_M_BIT downto C_HDDPKT_RAIDCMD_L_BIT):=CONV_STD_LOGIC_VECTOR(C_RAIDCMD_SW, C_HDDPKT_RAIDCMD_M_BIT-C_HDDPKT_RAIDCMD_L_BIT+1);
  cfgCmdPkt(3).usr_ctrl(C_HDDPKT_SATACMD_M_BIT downto C_HDDPKT_SATACMD_L_BIT):=CONV_STD_LOGIC_VECTOR(C_SATACMD_ATACOMMAND, C_HDDPKT_SATACMD_M_BIT-C_HDDPKT_SATACMD_L_BIT+1);
  cfgCmdPkt(3).command:=C_ATA_CMD_READ_SECTORS_EXT;--C_ATA_CMD_WRITE_SECTORS_EXT;--C_ATA_CMD_READ_DMA_EXT;--
  cfgCmdPkt(3).scount:=4;
  cfgCmdPkt(3).raid_cl:=1;
  cfgCmdPkt(3).lba:=CONV_STD_LOGIC_VECTOR(16#0605#, 16)&CONV_STD_LOGIC_VECTOR(16#0403#, 16)&CONV_STD_LOGIC_VECTOR(16#0201#, 16);--//LBA
  cfgCmdPkt(3).loopback:='1';

  cfgCmdPkt(4).usr_ctrl(C_HDDPKT_SATA_CS_M_BIT downto C_HDDPKT_SATA_CS_L_BIT):=CONV_STD_LOGIC_VECTOR(i_sata_cs, C_HDDPKT_SATA_CS_M_BIT-C_HDDPKT_SATA_CS_L_BIT+1);
  cfgCmdPkt(4).usr_ctrl(C_HDDPKT_RAIDCMD_M_BIT downto C_HDDPKT_RAIDCMD_L_BIT):=CONV_STD_LOGIC_VECTOR(C_RAIDCMD_SW, C_HDDPKT_RAIDCMD_M_BIT-C_HDDPKT_RAIDCMD_L_BIT+1);
  cfgCmdPkt(4).usr_ctrl(C_HDDPKT_SATACMD_M_BIT downto C_HDDPKT_SATACMD_L_BIT):=CONV_STD_LOGIC_VECTOR(C_SATACMD_ATACOMMAND, C_HDDPKT_SATACMD_M_BIT-C_HDDPKT_SATACMD_L_BIT+1);
  cfgCmdPkt(4).command:=C_ATA_CMD_WRITE_DMA_EXT;--
  cfgCmdPkt(4).scount:=4;
  cfgCmdPkt(4).lba:=CONV_STD_LOGIC_VECTOR(16#0605#, 16)&CONV_STD_LOGIC_VECTOR(16#0403#, 16)&CONV_STD_LOGIC_VECTOR(16#0201#, 16);--//LBA
  cfgCmdPkt(4).loopback:='1';

  cfgCmdPkt(5).usr_ctrl(C_HDDPKT_SATA_CS_M_BIT downto C_HDDPKT_SATA_CS_L_BIT):=CONV_STD_LOGIC_VECTOR(i_sata_cs, C_HDDPKT_SATA_CS_M_BIT-C_HDDPKT_SATA_CS_L_BIT+1);
  cfgCmdPkt(5).usr_ctrl(C_HDDPKT_RAIDCMD_M_BIT downto C_HDDPKT_RAIDCMD_L_BIT):=CONV_STD_LOGIC_VECTOR(C_RAIDCMD_SW, C_HDDPKT_RAIDCMD_M_BIT-C_HDDPKT_RAIDCMD_L_BIT+1);
  cfgCmdPkt(5).usr_ctrl(C_HDDPKT_SATACMD_M_BIT downto C_HDDPKT_SATACMD_L_BIT):=CONV_STD_LOGIC_VECTOR(C_SATACMD_ATACOMMAND, C_HDDPKT_SATACMD_M_BIT-C_HDDPKT_SATACMD_L_BIT+1);
  cfgCmdPkt(5).command:=C_ATA_CMD_READ_DMA_EXT;--
  cfgCmdPkt(5).scount:=4;
  cfgCmdPkt(5).lba:=CONV_STD_LOGIC_VECTOR(16#0605#, 16)&CONV_STD_LOGIC_VECTOR(16#0403#, 16)&CONV_STD_LOGIC_VECTOR(16#0201#, 16);--//LBA
  cfgCmdPkt(5).loopback:='1';

  cfgCmdPkt(6).usr_ctrl(C_HDDPKT_SATA_CS_M_BIT downto C_HDDPKT_SATA_CS_L_BIT):=CONV_STD_LOGIC_VECTOR(i_sata_cs, C_HDDPKT_SATA_CS_M_BIT-C_HDDPKT_SATA_CS_L_BIT+1);
  cfgCmdPkt(6).usr_ctrl(C_HDDPKT_RAIDCMD_M_BIT downto C_HDDPKT_RAIDCMD_L_BIT):=CONV_STD_LOGIC_VECTOR(C_RAIDCMD_SW, C_HDDPKT_RAIDCMD_M_BIT-C_HDDPKT_RAIDCMD_L_BIT+1);
  cfgCmdPkt(6).usr_ctrl(C_HDDPKT_SATACMD_M_BIT downto C_HDDPKT_SATACMD_L_BIT):=CONV_STD_LOGIC_VECTOR(C_SATACMD_ATACOMMAND, C_HDDPKT_SATACMD_M_BIT-C_HDDPKT_SATACMD_L_BIT+1);
  cfgCmdPkt(6).command:=C_ATA_CMD_READ_DMA_EXT;--
  cfgCmdPkt(6).scount:=9;
  cfgCmdPkt(6).lba:=CONV_STD_LOGIC_VECTOR(16#0605#, 16)&CONV_STD_LOGIC_VECTOR(16#0403#, 16)&CONV_STD_LOGIC_VECTOR(16#0201#, 16);--//LBA
  cfgCmdPkt(6).loopback:='0';

  cfgCmdPkt(7).usr_ctrl(C_HDDPKT_SATA_CS_M_BIT downto C_HDDPKT_SATA_CS_L_BIT):=CONV_STD_LOGIC_VECTOR(i_sata_cs, C_HDDPKT_SATA_CS_M_BIT-C_HDDPKT_SATA_CS_L_BIT+1);
  cfgCmdPkt(7).usr_ctrl(C_HDDPKT_RAIDCMD_M_BIT downto C_HDDPKT_RAIDCMD_L_BIT):=CONV_STD_LOGIC_VECTOR(C_RAIDCMD_SW, C_HDDPKT_RAIDCMD_M_BIT-C_HDDPKT_RAIDCMD_L_BIT+1);
  cfgCmdPkt(7).usr_ctrl(C_HDDPKT_SATACMD_M_BIT downto C_HDDPKT_SATACMD_L_BIT):=CONV_STD_LOGIC_VECTOR(C_SATACMD_ATACOMMAND, C_HDDPKT_SATACMD_M_BIT-C_HDDPKT_SATACMD_L_BIT+1);
  cfgCmdPkt(7).command:=C_ATA_CMD_READ_DMA_EXT;--
  cfgCmdPkt(7).scount:=9;
  cfgCmdPkt(7).lba:=CONV_STD_LOGIC_VECTOR(16#0605#, 16)&CONV_STD_LOGIC_VECTOR(16#0403#, 16)&CONV_STD_LOGIC_VECTOR(16#0201#, 16);--//LBA
  cfgCmdPkt(7).loopback:='0';

  cfgCmdPkt(8).usr_ctrl(C_HDDPKT_SATA_CS_M_BIT downto C_HDDPKT_SATA_CS_L_BIT):=CONV_STD_LOGIC_VECTOR(i_sata_cs, C_HDDPKT_SATA_CS_M_BIT-C_HDDPKT_SATA_CS_L_BIT+1);
  cfgCmdPkt(8).usr_ctrl(C_HDDPKT_RAIDCMD_M_BIT downto C_HDDPKT_RAIDCMD_L_BIT):=CONV_STD_LOGIC_VECTOR(C_RAIDCMD_SW, C_HDDPKT_RAIDCMD_M_BIT-C_HDDPKT_RAIDCMD_L_BIT+1);
  cfgCmdPkt(8).usr_ctrl(C_HDDPKT_SATACMD_M_BIT downto C_HDDPKT_SATACMD_L_BIT):=CONV_STD_LOGIC_VECTOR(C_SATACMD_ATACOMMAND, C_HDDPKT_SATACMD_M_BIT-C_HDDPKT_SATACMD_L_BIT+1);
  cfgCmdPkt(8).command:=C_ATA_CMD_READ_DMA_EXT;--
  cfgCmdPkt(8).scount:=9;
  cfgCmdPkt(8).lba:=CONV_STD_LOGIC_VECTOR(16#0605#, 16)&CONV_STD_LOGIC_VECTOR(16#0403#, 16)&CONV_STD_LOGIC_VECTOR(16#0201#, 16);--//LBA
  cfgCmdPkt(8).loopback:='0';

  cfgCmdPkt(9).usr_ctrl(C_HDDPKT_SATA_CS_M_BIT downto C_HDDPKT_SATA_CS_L_BIT):=CONV_STD_LOGIC_VECTOR(i_sata_cs, C_HDDPKT_SATA_CS_M_BIT-C_HDDPKT_SATA_CS_L_BIT+1);
  cfgCmdPkt(9).usr_ctrl(C_HDDPKT_RAIDCMD_M_BIT downto C_HDDPKT_RAIDCMD_L_BIT):=CONV_STD_LOGIC_VECTOR(C_RAIDCMD_SW, C_HDDPKT_RAIDCMD_M_BIT-C_HDDPKT_RAIDCMD_L_BIT+1);
  cfgCmdPkt(9).usr_ctrl(C_HDDPKT_SATACMD_M_BIT downto C_HDDPKT_SATACMD_L_BIT):=CONV_STD_LOGIC_VECTOR(C_SATACMD_ATACOMMAND, C_HDDPKT_SATACMD_M_BIT-C_HDDPKT_SATACMD_L_BIT+1);
  cfgCmdPkt(9).command:=C_ATA_CMD_READ_DMA_EXT;--
  cfgCmdPkt(9).scount:=9;
  cfgCmdPkt(9).lba:=CONV_STD_LOGIC_VECTOR(16#0605#, 16)&CONV_STD_LOGIC_VECTOR(16#0403#, 16)&CONV_STD_LOGIC_VECTOR(16#0201#, 16);--//LBA
  cfgCmdPkt(9).loopback:='0';

  cfgCmdPkt(10).usr_ctrl(C_HDDPKT_SATA_CS_M_BIT downto C_HDDPKT_SATA_CS_L_BIT):=CONV_STD_LOGIC_VECTOR(i_sata_cs, C_HDDPKT_SATA_CS_M_BIT-C_HDDPKT_SATA_CS_L_BIT+1);
  cfgCmdPkt(10).usr_ctrl(C_HDDPKT_RAIDCMD_M_BIT downto C_HDDPKT_RAIDCMD_L_BIT):=CONV_STD_LOGIC_VECTOR(C_RAIDCMD_SW, C_HDDPKT_RAIDCMD_M_BIT-C_HDDPKT_RAIDCMD_L_BIT+1);
  cfgCmdPkt(10).usr_ctrl(C_HDDPKT_SATACMD_M_BIT downto C_HDDPKT_SATACMD_L_BIT):=CONV_STD_LOGIC_VECTOR(C_SATACMD_ATACOMMAND, C_HDDPKT_SATACMD_M_BIT-C_HDDPKT_SATACMD_L_BIT+1);
  cfgCmdPkt(10).command:=C_ATA_CMD_READ_DMA_EXT;--
  cfgCmdPkt(10).scount:=9;
  cfgCmdPkt(10).lba:=CONV_STD_LOGIC_VECTOR(16#0605#, 16)&CONV_STD_LOGIC_VECTOR(16#0403#, 16)&CONV_STD_LOGIC_VECTOR(16#0201#, 16);--//LBA
  cfgCmdPkt(10).loopback:='0';

  cfgCmdPkt(11).usr_ctrl(C_HDDPKT_SATA_CS_M_BIT downto C_HDDPKT_SATA_CS_L_BIT):=CONV_STD_LOGIC_VECTOR(i_sata_cs, C_HDDPKT_SATA_CS_M_BIT-C_HDDPKT_SATA_CS_L_BIT+1);
  cfgCmdPkt(11).usr_ctrl(C_HDDPKT_RAIDCMD_M_BIT downto C_HDDPKT_RAIDCMD_L_BIT):=CONV_STD_LOGIC_VECTOR(C_RAIDCMD_SW, C_HDDPKT_RAIDCMD_M_BIT-C_HDDPKT_RAIDCMD_L_BIT+1);
  cfgCmdPkt(11).usr_ctrl(C_HDDPKT_SATACMD_M_BIT downto C_HDDPKT_SATACMD_L_BIT):=CONV_STD_LOGIC_VECTOR(C_SATACMD_ATACOMMAND, C_HDDPKT_SATACMD_M_BIT-C_HDDPKT_SATACMD_L_BIT+1);
  cfgCmdPkt(11).command:=C_ATA_CMD_READ_DMA_EXT;--
  cfgCmdPkt(11).scount:=9;
  cfgCmdPkt(11).lba:=CONV_STD_LOGIC_VECTOR(16#0605#, 16)&CONV_STD_LOGIC_VECTOR(16#0403#, 16)&CONV_STD_LOGIC_VECTOR(16#0201#, 16);--//LBA
  cfgCmdPkt(11).loopback:='0';
  end if;--//if i_sw_mode='0' then



  --//---------------------------------------------------
  --//Отправка команд для модуля dsn_hdd.vhd
  --//---------------------------------------------------
  if cfgCmdPkt(0).usr_ctrl(C_HDDPKT_RAIDCMD_M_BIT downto C_HDDPKT_RAIDCMD_L_BIT)=CONV_STD_LOGIC_VECTOR(C_RAIDCMD_SW, C_HDDPKT_RAIDCMD_M_BIT-C_HDDPKT_RAIDCMD_L_BIT+1) then
      --//##################################
      write(GUI_line,string'("SW mode!!!")); writeline(output, GUI_line);
      --//##################################

      ltrn_count : for idx in 0 to C_SIM_COUNT-1 loop

      i_loopback<=cfgCmdPkt(idx).loopback;

      --//Ждем разрешения загрузки командного пакета
      write(GUI_line,string'("WAIT - i_cmddone_det")); writeline(output, GUI_line);
      wait until p_in_clk'event and p_in_clk='1' and i_cmddone_det='1';
      if i_ltrn_count0='1' then
        i_ltrn_count1<='1';
      end if;

      --//Читаем статусы модуля HDD
      wait until g_cfg_clk'event and g_cfg_clk='1';
      i_cfgdev_adr<=CONV_STD_LOGIC_VECTOR(C_HDD_REG_TEST_TDLY_L, i_cfgdev_adr'length);
      i_cfgdev_adr_ld<='1';
      i_cfgdev_adr_fifo<='0';
      wait until g_cfg_clk'event and g_cfg_clk='1';
      i_cfgdev_adr_ld<='0';
      i_cfgdev_adr_fifo<='0';

      wait until g_cfg_clk'event and g_cfg_clk='1';
      i_dev_cfg_rd(C_CFGDEV_HDD)<='1';
      wait until g_cfg_clk'event and g_cfg_clk='1';
      i_dev_cfg_rd(C_CFGDEV_HDD)<='0';
      wait until g_cfg_clk'event and g_cfg_clk='1';
      i_dev_cfg_rd(C_CFGDEV_HDD)<='1';
      wait until g_cfg_clk'event and g_cfg_clk='1';
      i_dev_cfg_rd(C_CFGDEV_HDD)<='0';

      wait until g_cfg_clk'event and g_cfg_clk='1';
      i_dev_cfg_done(C_CFGDEV_HDD)<='1';
      wait until g_cfg_clk'event and g_cfg_clk='1';
      i_dev_cfg_done(C_CFGDEV_HDD)<='0';


      --//Сброс флага i_cmddone_det
      wait until p_in_clk'event and p_in_clk='1';
      i_cmddone_det_clr<='1';
      wait until p_in_clk'event and p_in_clk='1';
      i_cmddone_det_clr<='0';


      write(GUI_line,string'("NEW ATA COMMAND 1."));writeline(output, GUI_line);

      --//Заполняем CmdPkt
      cmd_data(0):=cfgCmdPkt(idx).usr_ctrl; --//UsrCTRL
      cmd_data(1):=CONV_STD_LOGIC_VECTOR(16#AA55#, 16);--//Feature
      cmd_data(2):=cfgCmdPkt(idx).lba(15 downto  8) & cfgCmdPkt(idx).lba( 7 downto 0);
      cmd_data(3):=cfgCmdPkt(idx).lba(31 downto 24) & cfgCmdPkt(idx).lba(23 downto 16);
      cmd_data(4):=cfgCmdPkt(idx).lba(47 downto 40) & cfgCmdPkt(idx).lba(39 downto 32);
      cmd_data(5):=CONV_STD_LOGIC_VECTOR(cfgCmdPkt(idx).scount, 16);--//SectorCount
      cmd_data(6):=cfgCmdPkt(idx).control & cfgCmdPkt(idx).device;--//Control + Device
      if i_tst_mode='0' then
      cmd_data(7):=CONV_STD_LOGIC_VECTOR(0, 8) & CONV_STD_LOGIC_VECTOR(cfgCmdPkt(idx).command, 8);--//Reserv + ATA Commad
      else
      cmd_data(7):=CONV_STD_LOGIC_VECTOR(0, 8) & CONV_STD_LOGIC_VECTOR(tst_cmd, 8);--//Режим тестирования
      end if;
      cmd_data(8):=CONV_STD_LOGIC_VECTOR(cfgCmdPkt(idx).raid_cl, i_cmd_data(8)'length);--//raid claster

      for i in 0 to i_cmd_data'high loop
      i_cmd_data(i)<=cmd_data(i);
      end loop;

      --//Отправляем HDDPKT
      wait until g_cfg_clk'event and g_cfg_clk='1';
      i_cfgdev_adr<=CONV_STD_LOGIC_VECTOR(C_HDD_REG_CMDFIFO, i_cfgdev_adr'length);
      i_cfgdev_adr_ld<='1';
      i_cfgdev_adr_fifo<='1';
      wait until g_cfg_clk'event and g_cfg_clk='1';
      i_cfgdev_adr_ld<='0';
      i_cfgdev_adr_fifo<='1';
      wait until g_cfg_clk'event and g_cfg_clk='1';
      p_CMDPKT_WRITE(g_cfg_clk,
                    i_cmd_data,
                    i_cfgdev_txdata, i_dev_cfg_wd(C_CFGDEV_HDD));
      wait until g_cfg_clk'event and g_cfg_clk='1';
      i_dev_cfg_done(C_CFGDEV_HDD)<='1';
      wait until g_cfg_clk'event and g_cfg_clk='1';
      i_dev_cfg_done(C_CFGDEV_HDD)<='0';

      --//Вычисляем размер данных которые необходимо записать/прочитать: (в DWORD)
      wait until g_cfg_clk'event and g_cfg_clk='1';
      if cfgCmdPkt(idx).usr_ctrl(C_HDDPKT_SATA_CS_M_BIT downto C_HDDPKT_SATA_CS_L_BIT)=CONV_STD_LOGIC_VECTOR(16#01#, C_HDDPKT_SATA_CS_M_BIT-C_HDDPKT_SATA_CS_L_BIT+1) or
         cfgCmdPkt(idx).usr_ctrl(C_HDDPKT_SATA_CS_M_BIT downto C_HDDPKT_SATA_CS_L_BIT)=CONV_STD_LOGIC_VECTOR(16#02#, C_HDDPKT_SATA_CS_M_BIT-C_HDDPKT_SATA_CS_L_BIT+1) or
         cfgCmdPkt(idx).usr_ctrl(C_HDDPKT_SATA_CS_M_BIT downto C_HDDPKT_SATA_CS_L_BIT)=CONV_STD_LOGIC_VECTOR(16#04#, C_HDDPKT_SATA_CS_M_BIT-C_HDDPKT_SATA_CS_L_BIT+1) or
         cfgCmdPkt(idx).usr_ctrl(C_HDDPKT_SATA_CS_M_BIT downto C_HDDPKT_SATA_CS_L_BIT)=CONV_STD_LOGIC_VECTOR(16#08#, C_HDDPKT_SATA_CS_M_BIT-C_HDDPKT_SATA_CS_L_BIT+1) or
         cfgCmdPkt(idx).usr_ctrl(C_HDDPKT_SATA_CS_M_BIT downto C_HDDPKT_SATA_CS_L_BIT)=CONV_STD_LOGIC_VECTOR(16#10#, C_HDDPKT_SATA_CS_M_BIT-C_HDDPKT_SATA_CS_L_BIT+1) or
         cfgCmdPkt(idx).usr_ctrl(C_HDDPKT_SATA_CS_M_BIT downto C_HDDPKT_SATA_CS_L_BIT)=CONV_STD_LOGIC_VECTOR(16#20#, C_HDDPKT_SATA_CS_M_BIT-C_HDDPKT_SATA_CS_L_BIT+1) or
         cfgCmdPkt(idx).usr_ctrl(C_HDDPKT_SATA_CS_M_BIT downto C_HDDPKT_SATA_CS_L_BIT)=CONV_STD_LOGIC_VECTOR(16#40#, C_HDDPKT_SATA_CS_M_BIT-C_HDDPKT_SATA_CS_L_BIT+1) or
         cfgCmdPkt(idx).usr_ctrl(C_HDDPKT_SATA_CS_M_BIT downto C_HDDPKT_SATA_CS_L_BIT)=CONV_STD_LOGIC_VECTOR(16#80#, C_HDDPKT_SATA_CS_M_BIT-C_HDDPKT_SATA_CS_L_BIT+1) then

        i_tstdata_dwsize<=cfgCmdPkt(idx).scount * C_SIM_SECTOR_SIZE_DWORD;
      else
        i_tstdata_dwsize<=cfgCmdPkt(idx).scount * (C_SIM_SECTOR_SIZE_DWORD * G_HDD_COUNT);
      end if;


      if cfgCmdPkt(idx).command=C_ATA_CMD_WRITE_SECTORS_EXT or cfgCmdPkt(idx).command=C_ATA_CMD_WRITE_DMA_EXT then
      --//Запускаем автомат записи данных
        wait until p_in_clk'event and p_in_clk='1';
        i_sim_ctrl.ram_txbuf_start<=not i_tst_mode;--'1';
        cmd_write:='1';
        wait until p_in_clk'event and p_in_clk='1';
        i_sim_ctrl.ram_txbuf_start<='0';
        --//Ждем когда запишем все данные в TxBUF
        if i_tst_mode='0' then
        wait until i_sim_ctrl.ram_txbuf_done='1';
        end if;
      end if;

      if cfgCmdPkt(idx).command=C_ATA_CMD_READ_SECTORS_EXT or cfgCmdPkt(idx).command=C_ATA_CMD_READ_DMA_EXT then
      --//Запускаем автомат чтния данных
        wait until p_in_clk'event and p_in_clk='1';
        i_sim_ctrl.ram_rxbuf_start<=not i_tst_mode;--'1';
        cmd_read:='1';
        wait until p_in_clk'event and p_in_clk='1';
        i_sim_ctrl.ram_rxbuf_start<='0';
        --//Ждем когда прочитаем все данные из RxBUF
        if i_tst_mode='0' then
        wait until i_sim_ctrl.ram_rxbuf_done='1';
--                      --//Тестирование чтения данных из ОЗУ через CFG
--                      if i_cfgdev_if=C_HDD_CFGIF_UART then
--
--                          wait until p_in_clk'event and p_in_clk='1';
--                           i_cfgdev_if_tst<='1';
--
--                        --//Запускаем автомат чтния данных
--                          wait until p_in_clk'event and p_in_clk='1';
--                          i_sim_ctrl.ram_txbuf_start<=not i_tst_mode;--'1';
--                          wait until p_in_clk'event and p_in_clk='1';
--                          i_sim_ctrl.ram_txbuf_start<='0';
--
--                          wait for 0.5 us;
--
--                          wait until g_cfg_clk'event and g_cfg_clk='1';
--                            i_cfgdev_adr<=CONV_STD_LOGIC_VECTOR(C_HDD_REG_RBUF_DATA, i_cfgdev_adr'length);
--                            i_cfgdev_adr_ld<='1';
--                            i_cfgdev_adr_fifo<='0';
--                          wait until g_cfg_clk'event and g_cfg_clk='1';
--                            i_cfgdev_adr_ld<='0';
--                            i_cfgdev_adr_fifo<='1';
--
--                          for i in 0 to 16*2 -1 loop
--                            wait until g_cfg_clk'event and g_cfg_clk='1';
--                            i_dev_cfg_rd(C_CFGDEV_HDD)<='1';
--                            wait until g_cfg_clk'event and g_cfg_clk='1';
--                            i_dev_cfg_rd(C_CFGDEV_HDD)<='0';
--                            wait for 0.05 us;
--                          end loop;
--
--                          wait until g_cfg_clk'event and g_cfg_clk='1';
--                          i_dev_cfg_done(C_CFGDEV_HDD)<='1';
--                          wait until g_cfg_clk'event and g_cfg_clk='1';
--                          i_dev_cfg_done(C_CFGDEV_HDD)<='0';
--
--                          write(GUI_line,string'("module DSN_HDD: C_HDD_CFGIF_UART."));writeline(output, GUI_line);
--                          wait;
--                      end if;
        end if;
      end if;


      if i_loopback='0' or i_tst_mode='1' then
        write(GUI_line,string'("LOOPBACK DATA: disable")); writeline(output, GUI_line);
        cmd_write:='0';
        cmd_read:='0';

      else

        if cmd_write='1' and cmd_read='1' then
          write(GUI_line,string'("COMPARE DATA: i_ram_txbuf,i_ram_rxbuf")); writeline(output, GUI_line);
          for i in 0 to i_tstdata_dwsize-1 loop

              write(GUI_line,string'(" i_ram_txbuf/i_ram_rxbuf("));write(GUI_line,i);write(GUI_line,string'("): 0x"));
              --write(GUI_line,CONV_INTEGER(i_ram_txbuf(i)));
              for y in 1 to (i_ram_txbuf(i)'length/8)*2 loop --                                                        -- for y in 1 to 8 loop                                             --
              string_value:=i_ram_txbuf(i)((i_ram_txbuf(i)'length-(4*(y-1)))-1 downto (i_ram_txbuf(i)'length-(4*y)));  -- string_value:=i_ram_txbuf(i)((32-(4*(y-1)))-1 downto (32-(4*y)));--
              write(GUI_line,Int2StrHEX(CONV_INTEGER(string_value)));                                                  -- write(GUI_line,Int2StrHEX(CONV_INTEGER(string_value)));          --
              end loop;                                                                                                -- end loop;                                                        --
              write(GUI_line,string'("/0x"));
              --write(GUI_line,CONV_INTEGER(i_ram_rxbuf(i)));
              for y in 1 to (i_ram_rxbuf(i)'length/8)*2 loop --                                                        -- for y in 1 to 8 loop                                              --
              string_value:=i_ram_rxbuf(i)((i_ram_rxbuf(i)'length-(4*(y-1)))-1 downto (i_ram_rxbuf(i)'length-(4*y)));  -- string_value:=i_ram_rxbuf(i)((32-(4*(y-1)))-1 downto (32-(4*y))); --
              write(GUI_line,Int2StrHEX(CONV_INTEGER(string_value)));                                                  -- write(GUI_line,Int2StrHEX(CONV_INTEGER(string_value)));           --
              end loop;                                                                                                -- end loop;                                                         --
              writeline(output, GUI_line);

            if i_ram_txbuf(i)/=i_ram_rxbuf(i) then
              --//Завершаем модеоирование.
              write(GUI_line,string'("COMPARE DATA:ERROR - i_ram_txbuf("));write(GUI_line,i);write(GUI_line,string'(")/= "));
              write(GUI_line,string'("i_ram_rxbuf("));write(GUI_line,i);write(GUI_line,string'(")"));
              writeline(output, GUI_line);
              p_SIM_STOP("Simulation of STOP: COMPARE DATA:ERROR i_ram_rxbuf/=i_ram_rxbuf");
            end if;
          end loop;

          cmd_write:='0';
          cmd_read:='0';
          write(GUI_line,string'("COMPARE DATA: i_ram_txbuf/i_ram_rxbuf - OK.")); writeline(output, GUI_line);
        end if;
      end if;


      i_ltrn_count0<='1';
      end loop ltrn_count;

  else

      --//##################################
      write(GUI_line,string'("HW mode!!!")); writeline(output, GUI_line);
      --//##################################
      wait until p_in_clk'event and p_in_clk='1' and i_cmddone_det='1';
      if i_ltrn_count0='1' then
        i_ltrn_count1<='1';
      end if;

      --//Сброс флага i_cmddone_det
      wait until p_in_clk'event and p_in_clk='1';
      i_cmddone_det_clr<='1';
      wait until p_in_clk'event and p_in_clk='1';
      i_cmddone_det_clr<='0';


      write(GUI_line,string'("SEND CMDPKT: SET LBA_END."));writeline(output, GUI_line);
      --//Заполняем CmdPkt
      cmd_data(0):=cfgCmdPkt(0).usr_ctrl; --//UsrCTRL
      cmd_data(1):=CONV_STD_LOGIC_VECTOR(16#AA55#, 16);--//Feature
      cmd_data(2):=cfgCmdPkt(0).lba(15 downto  8) & cfgCmdPkt(0).lba( 7 downto 0);
      cmd_data(3):=cfgCmdPkt(0).lba(31 downto 24) & cfgCmdPkt(0).lba(23 downto 16);
      cmd_data(4):=cfgCmdPkt(0).lba(47 downto 40) & cfgCmdPkt(0).lba(39 downto 32);
      cmd_data(5):=CONV_STD_LOGIC_VECTOR(cfgCmdPkt(0).scount, 16);--//SectorCount
      cmd_data(6):=cfgCmdPkt(0).control & cfgCmdPkt(0).device;--//Control + Device
      cmd_data(7):=CONV_STD_LOGIC_VECTOR(0, 8) & CONV_STD_LOGIC_VECTOR(cfgCmdPkt(0).command, 8);--//Reserv + ATA Commad

      for i in 0 to i_cmd_data'high loop
      i_cmd_data(i)<=cmd_data(i);
      end loop;

      --//Отправляем HDDPKT
      wait until g_cfg_clk'event and g_cfg_clk='1';
      i_cfgdev_adr<=CONV_STD_LOGIC_VECTOR(C_HDD_REG_CMDFIFO, i_cfgdev_adr'length);
      i_cfgdev_adr_ld<='1';
      i_cfgdev_adr_fifo<='1';
      wait until g_cfg_clk'event and g_cfg_clk='1';
      i_cfgdev_adr_ld<='0';
      i_cfgdev_adr_fifo<='1';
      wait until g_cfg_clk'event and g_cfg_clk='1';
      p_CMDPKT_WRITE(g_cfg_clk,
                    i_cmd_data,
                    i_cfgdev_txdata, i_dev_cfg_wd(C_CFGDEV_HDD));
      wait until g_cfg_clk'event and g_cfg_clk='1';
      i_dev_cfg_done(C_CFGDEV_HDD)<='1';
      wait until g_cfg_clk'event and g_cfg_clk='1';
      i_dev_cfg_done(C_CFGDEV_HDD)<='0';

      wait for 0.5 us;


      write(GUI_line,string'("SEND CMDPKT: ATA COMAND."));writeline(output, GUI_line);
      --//Заполняем CmdPkt
      cmd_data(0):=cfgCmdPkt(1).usr_ctrl; --//UsrCTRL
      cmd_data(1):=CONV_STD_LOGIC_VECTOR(16#AA55#, 16);--//Feature
      cmd_data(2):=cfgCmdPkt(1).lba(15 downto  8) & cfgCmdPkt(1).lba( 7 downto 0);
      cmd_data(3):=cfgCmdPkt(1).lba(31 downto 24) & cfgCmdPkt(1).lba(23 downto 16);
      cmd_data(4):=cfgCmdPkt(1).lba(47 downto 40) & cfgCmdPkt(1).lba(39 downto 32);
      cmd_data(5):=CONV_STD_LOGIC_VECTOR(cfgCmdPkt(1).scount, 16);--//SectorCount
      cmd_data(6):=cfgCmdPkt(1).control & cfgCmdPkt(1).device;--//Control + Device
      cmd_data(7):=CONV_STD_LOGIC_VECTOR(0, 8) & CONV_STD_LOGIC_VECTOR(cfgCmdPkt(1).command, 8);--//Reserv + ATA Commad
      cmd_data(8):=CONV_STD_LOGIC_VECTOR(cfgCmdPkt(1).raid_cl, i_cmd_data(8)'length);--//raid claster

      for i in 0 to i_cmd_data'high loop
      i_cmd_data(i)<=cmd_data(i);
      end loop;

      --//Отправляем HDDPKT
      wait until g_cfg_clk'event and g_cfg_clk='1';
      i_cfgdev_adr<=CONV_STD_LOGIC_VECTOR(C_HDD_REG_CMDFIFO, i_cfgdev_adr'length);
      i_cfgdev_adr_ld<='1';
      i_cfgdev_adr_fifo<='1';
      wait until g_cfg_clk'event and g_cfg_clk='1';
      i_cfgdev_adr_ld<='0';
      i_cfgdev_adr_fifo<='1';
      wait until g_cfg_clk'event and g_cfg_clk='1';
      p_CMDPKT_WRITE(g_cfg_clk,
                    i_cmd_data,
                    i_cfgdev_txdata, i_dev_cfg_wd(C_CFGDEV_HDD));
      wait until g_cfg_clk'event and g_cfg_clk='1';
      i_dev_cfg_done(C_CFGDEV_HDD)<='1';
      wait until g_cfg_clk'event and g_cfg_clk='1';
      i_dev_cfg_done(C_CFGDEV_HDD)<='0';

      i_tstdata_dwsize<=cfgCmdPkt(1).scount * C_SIM_SECTOR_SIZE_DWORD;--//Назначаем размер данных в DWORD
      wait until p_in_clk'event and p_in_clk='1';

      if cfgCmdPkt(1).command=C_ATA_CMD_WRITE_SECTORS_EXT or cfgCmdPkt(1).command=C_ATA_CMD_WRITE_DMA_EXT or
         cfgCmdPkt(1).command=C_ATA_CMD_READ_SECTORS_EXT or cfgCmdPkt(1).command=C_ATA_CMD_READ_DMA_EXT then
      --//Запускаем автомат записи данных
        wait until p_in_clk'event and p_in_clk='1';
        i_vdata_start<=not i_tst_mode or i_dsnhdd_reg_ctrl_val(C_HDD_REG_CTRLL_TST_GEN2RAMBUF_BIT);--'1';
        cmd_write:='1';
        wait until p_in_clk'event and p_in_clk='1';
        i_vdata_start<='0';

--        --//Ждем когда запишем все данные в TxBUF
--        wait until i_vdata_done='1';
      end if;

      wait for 0.5 us;

      if cfgCmdPkt(1).command=C_ATA_CMD_READ_SECTORS_EXT or cfgCmdPkt(1).command=C_ATA_CMD_READ_DMA_EXT then
      --//Запускаем автомат чтния данных
        wait until p_in_clk'event and p_in_clk='1';
        i_sim_ctrl.ram_rxbuf_start<=not i_tst_mode;--'1';
        cmd_read:='1';
        wait until p_in_clk'event and p_in_clk='1';
        i_sim_ctrl.ram_rxbuf_start<='0';

--        --//Ждем когда прочитаем все данные из RxBUF
--        wait until i_sim_ctrl.ram_rxbuf_done='1';
      end if;

--      wait for 30 us;
--      wait for 50 us;
--      wait for 54 us;
      wait for 60 us;
--      wait for 380 us;

      wait until p_in_clk'event and p_in_clk='1';
      write(GUI_line,string'("SEND CMDPKT: HW STOP."));writeline(output, GUI_line);
      --//Заполняем CmdPkt
      cmd_data(0)(C_HDDPKT_SATA_CS_M_BIT downto C_HDDPKT_SATA_CS_L_BIT):=CONV_STD_LOGIC_VECTOR(i_sata_cs, C_HDDPKT_SATA_CS_M_BIT-C_HDDPKT_SATA_CS_L_BIT+1);
      cmd_data(0)(C_HDDPKT_RAIDCMD_M_BIT downto C_HDDPKT_RAIDCMD_L_BIT):=CONV_STD_LOGIC_VECTOR(C_RAIDCMD_STOP, C_HDDPKT_RAIDCMD_M_BIT-C_HDDPKT_RAIDCMD_L_BIT+1);
      cmd_data(0)(C_HDDPKT_SATACMD_M_BIT downto C_HDDPKT_SATACMD_L_BIT):=CONV_STD_LOGIC_VECTOR(C_SATACMD_NULL, C_HDDPKT_SATACMD_M_BIT-C_HDDPKT_SATACMD_L_BIT+1);
      cmd_data(1):=(others=>'0');--CONV_STD_LOGIC_VECTOR(16#AA55#, 16);--//Feature
      cmd_data(2):=(others=>'0');--cfgCmdPkt(0).lba(15 downto  8) & cfgCmdPkt(0).lba( 7 downto 0);
      cmd_data(3):=(others=>'0');--cfgCmdPkt(0).lba(31 downto 24) & cfgCmdPkt(0).lba(23 downto 16);
      cmd_data(4):=(others=>'0');--cfgCmdPkt(0).lba(47 downto 40) & cfgCmdPkt(0).lba(39 downto 32);
      cmd_data(5):=(others=>'0');--CONV_STD_LOGIC_VECTOR(cfgCmdPkt(0).scount, 16);--//SectorCount
      cmd_data(6):=(others=>'0');--cfgCmdPkt(1).control & cfgCmdPkt(0).device;--//Control + Device
      cmd_data(7):=(others=>'0');--CONV_STD_LOGIC_VECTOR(0, 8) & CONV_STD_LOGIC_VECTOR(cfgCmdPkt(1).command, 8);--//Reserv + ATA Commad
      cmd_data(8):=CONV_STD_LOGIC_VECTOR(cfgCmdPkt(1).raid_cl, i_cmd_data(8)'length);--//raid claster

      for i in 0 to i_cmd_data'high loop
      i_cmd_data(i)<=cmd_data(i);
      end loop;

--      i_tstdata_dwsize<=cfgCmdPkt(0).scount * C_SIM_SECTOR_SIZE_DWORD;--//Назначаем размер данных в DWORD

      --//Отправляем HDDPKT
      wait until g_cfg_clk'event and g_cfg_clk='1';
      i_cfgdev_adr<=CONV_STD_LOGIC_VECTOR(C_HDD_REG_CMDFIFO, i_cfgdev_adr'length);
      i_cfgdev_adr_ld<='1';
      i_cfgdev_adr_fifo<='1';
      wait until g_cfg_clk'event and g_cfg_clk='1';
      i_cfgdev_adr_ld<='0';
      i_cfgdev_adr_fifo<='1';
      wait until g_cfg_clk'event and g_cfg_clk='1';
      p_CMDPKT_WRITE(g_cfg_clk,
                    i_cmd_data,
                    i_cfgdev_txdata, i_dev_cfg_wd(C_CFGDEV_HDD));
      wait until g_cfg_clk'event and g_cfg_clk='1';
      i_dev_cfg_done(C_CFGDEV_HDD)<='1';
      wait until g_cfg_clk'event and g_cfg_clk='1';
      i_dev_cfg_done(C_CFGDEV_HDD)<='0';

      write(GUI_line,string'("HW STOP!!!"));writeline(output, GUI_line);

      wait for 1 us;


  end if;--//if cfgCmdPkt(0).usr_ctrl(C_HDDPKT_RAIDCMD_M_BIT downto C_HDDPKT_RAIDCMD_L_BIT)/=CONV_STD_LOGIC_VECTOR(C_RAIDCMD_SW


  write(GUI_line,string'("HW/WAIT - i_cmddone_det")); writeline(output, GUI_line);
  wait until p_in_clk'event and p_in_clk='1' and i_cmddone_det='1';

  wait for 1 us;

  write(GUI_line,string'("HW - CLR_ERR/BUF")); writeline(output, GUI_line);
  --//CLR_ERR/BUF = '1'
  wait until g_cfg_clk'event and g_cfg_clk='1';
    i_cfgdev_adr<=CONV_STD_LOGIC_VECTOR(C_HDD_REG_CTRL_L, i_cfgdev_adr'length);
    i_cfgdev_adr_ld<='1';
    i_cfgdev_adr_fifo<='0';
  wait until g_cfg_clk'event and g_cfg_clk='1';
    i_cfgdev_adr_ld<='0';
    i_cfgdev_adr_fifo<='0';
    i_cfgdev_txdata<=i_dsnhdd_reg_ctrl_val;
    i_cfgdev_txdata(C_HDD_REG_CTRLL_ERR_CLR_BIT)<='1';
    i_dev_cfg_wd(C_CFGDEV_HDD)<='1';
  wait until g_cfg_clk'event and g_cfg_clk='1';
    i_dev_cfg_wd(C_CFGDEV_HDD)<='0';

  wait for 1 us;

  --//CLR_ERR/BUF = '0'
  wait until g_cfg_clk'event and g_cfg_clk='1';
    i_cfgdev_adr<=CONV_STD_LOGIC_VECTOR(C_HDD_REG_CTRL_L, i_cfgdev_adr'length);
    i_cfgdev_adr_ld<='1';
    i_cfgdev_adr_fifo<='0';
  wait until g_cfg_clk'event and g_cfg_clk='1';
    i_cfgdev_adr_ld<='0';
    i_cfgdev_adr_fifo<='0';
    i_cfgdev_txdata<=i_dsnhdd_reg_ctrl_val;
    i_cfgdev_txdata(C_HDD_REG_CTRLL_ERR_CLR_BIT)<='0';
    i_dev_cfg_wd(C_CFGDEV_HDD)<='1';
  wait until g_cfg_clk'event and g_cfg_clk='1';
    i_dev_cfg_wd(C_CFGDEV_HDD)<='0';

  wait for 10 us;

  --//Завершаем модеоирование.
  p_SIM_STOP("Simulation of SIMPLE complete");


  wait;
end process lmain_ctrl;


--END MAIN
end;
