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

library work;
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
G_HDD_COUNT     : integer:=2;    --//Кол-во sata устр-в (min/max - 1/8)
G_GT_DBUS       : integer:=16;
G_DBG           : string :="ON";
G_SIM           : string :="ON"
);
end vereskm_hdd_tb;

architecture behavior of vereskm_hdd_tb is

constant CI_SECTOR_SIZE_BYTE : integer:=selval(C_SECTOR_SIZE_BYTE, C_SIM_SECTOR_SIZE_DWORD*4, strcmp(G_SIM, "OFF"));

constant C_SATACLK_PERIOD    : TIME := 6.6 ns; --150MHz
constant C_USRCLK_PERIOD     : TIME := 3.6 ns;--6.6*10 ns;--
constant C_HOSTCLK_PERIOD    : TIME := 6.6*6 ns;
constant C_VBUF_WRCLK_PERIOD : TIME := 6.6*2 ns;

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
p_in_hdd_txbuf_empty  : in    std_logic;

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

signal i_sata_gt_refclkmain      : std_logic_vector((C_SH_COUNT_MAX(G_HDD_COUNT-1))-1 downto 0);
signal g_host_clk                 : std_logic;
signal p_in_clk                   : std_logic;
signal i_dsn_hdd_rst              : std_logic:='1';

signal i_tst_mode                 : std_logic;
signal i_tst_command              : integer;
signal i_sw_mode                  : std_logic;
signal i_sw_sata_cs               : integer;
signal i_hw_mode                  : std_logic;
signal i_hw_sata_cs               : integer;
signal i_hw_mode_stop             : std_logic;

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

signal i_dsnhdd_reg_ctrl_write    : std_logic;
signal i_dsnhdd_reg_ctrl_val      : std_logic_vector(15 downto 0);

signal i_rbuf_cfg                 : THDDRBufCfg;
signal i_rbuf_status              : THDDRBufStatus;

signal i_sh_txd                   : std_logic_vector(31 downto 0);
signal i_sh_txd_wr                : std_logic;
signal i_sh_txbuf_full            : std_logic;
signal i_sh_txbuf_empty           : std_logic;
signal i_sh_rxd                   : std_logic_vector(31 downto 0);
signal i_sh_rxd_rd                : std_logic;
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

signal tst_hdd_out                    : std_logic_vector(31 downto 0);

signal i_tstdata_dwsize               : integer:=0;
signal i_loopback                     : std_logic;
signal sr_cmdbusy                     : std_logic_vector(0 to 1);
signal i_cmddone_det_clr              : std_logic:='0';
signal i_cmddone_det                  : std_logic:='0';
signal i_cmd_data                     : TUsrAppCmdPkt;
signal i_cmd_wrstart                  : std_logic:='0';
signal i_cmd_wrdone                   : std_logic:='0';
signal i_ram_txbuf                    : TSimBufData;
signal i_ram_txbuf_start              : std_logic:='0';
signal i_ram_txbuf_done               : std_logic:='0';
signal i_ram_txbuf_fillselect         : std_logic:='0';
signal i_ram_rxbuf                    : TSimBufData;
signal i_ram_rxbuf_start              : std_logic:='0';
signal i_ram_rxbuf_done               : std_logic:='0';

signal i_vbuf_din                     : std_logic_vector(31 downto 0);
signal i_vbuf_wr                      : std_logic;
signal i_vbuf_wrclk                   : std_logic;
signal i_vbuf_dout                    : std_logic_vector(31 downto 0);
signal i_vbuf_rd                      : std_logic;
signal i_vbuf_full                    : std_logic;
signal i_vbuf_pfull                   : std_logic;
signal i_vbuf_empty                   : std_logic;
signal i_vbuf_wrcount                 : std_logic_vector(3 downto 0);
signal i_vdata_start                  : std_logic;
signal i_vdata_done                   : std_logic;


type TSataDevStatusSataCount is array (0 to C_HDD_COUNT_MAX-1) of TSataDevStatus;
signal i_satadev_status               : TSataDevStatusSataCount;
signal i_satadev_ctrl                 : TSataDevCtrl;



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
G_GT_DBUS    => G_GT_DBUS
)
port map
(
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
p_in_tst                 => "00000000000000000000000000000000",
p_out_tst                => open,

----------------------------
--System
----------------------------
p_in_clk                 => i_hdd_sim_gt_clk(i),
p_in_rst                 => i_hdd_sim_gt_rst(i)
);

end generate gen_satad;


gen_refclk_sata : for i in 0 to C_SH_COUNT_MAX(G_HDD_COUNT-1)-1 generate
gen_clk_sata : process
begin
  i_sata_gt_refclkmain(i)<='0';
  wait for C_SATACLK_PERIOD/2;
  i_sata_gt_refclkmain(i)<='1';
  wait for C_SATACLK_PERIOD/2;
end process;
end generate gen_refclk_sata;


gen_host_clk : process
begin
  g_host_clk<='0';
  wait for C_HOSTCLK_PERIOD/2;
  g_host_clk<='1';
  wait for C_HOSTCLK_PERIOD/2;
end process;

gen_clk_usr : process
begin
  p_in_clk<='0';
  wait for C_USRCLK_PERIOD/2;
  p_in_clk<='1';
  wait for C_USRCLK_PERIOD/2;
end process;

gen_vbuf_wrclk : process
begin
  i_vbuf_wrclk<='0';
  wait for C_VBUF_WRCLK_PERIOD/2;
  i_vbuf_wrclk<='1';
  wait for C_VBUF_WRCLK_PERIOD/2;
end process;


i_dsn_hdd_rst<='1','0' after 1 us;


m_hdd : dsn_hdd
generic map
(
G_MODULE_USE => "ON",--
G_HDD_COUNT  => G_HDD_COUNT,
G_GT_DBUS    => G_GT_DBUS,
G_DBG        => G_DBG,
G_DBGCS      => "OFF",
G_SIM        => G_SIM
)
port map
(
--------------------------------------------------
-- Конфигурирование модуля DSN_HDD.VHD (p_in_cfg_clk domain)
--------------------------------------------------
p_in_cfg_clk           => g_host_clk,

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

p_in_hdd_txd           => i_sh_txd,
p_in_hdd_txd_wr        => i_sh_txd_wr,
p_out_hdd_txbuf_full   => i_sh_txbuf_full,
p_out_hdd_txbuf_empty  => i_sh_txbuf_empty,

p_out_hdd_rxd          => i_sh_rxd,
p_in_hdd_rxd_rd        => i_sh_rxd_rd,
p_out_hdd_rxbuf_empty  => i_sh_rxbuf_empty,

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

--------------------------------------------------
--Технологический порт
--------------------------------------------------
p_in_tst               => "00000000000000000000000000000000",--tst_hdd_in,
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
p_in_vbuf_dout        => i_vbuf_dout,
p_out_vbuf_rd         => i_vbuf_rd,
p_in_vbuf_empty       => i_vbuf_empty,
p_in_vbuf_full        => i_vbuf_full,
p_in_vbuf_pfull       => i_vbuf_pfull,

--//--------------------------
--//Связь с модулем HDD
--//--------------------------
p_out_hdd_txd         => i_sh_txd,
p_out_hdd_txd_wr      => i_sh_txd_wr,
p_in_hdd_txbuf_full   => i_sh_txbuf_full,
p_in_hdd_txbuf_empty  => i_vbuf_empty,

p_in_hdd_rxd          => i_sh_rxd,
p_out_hdd_rxd_rd      => i_sh_rxd_rd,
p_in_hdd_rxbuf_empty  => i_sh_rxbuf_empty,

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
p_in_clk              => p_in_clk,
p_in_rst              => i_dsn_hdd_rst
);


--//Видео Буфер
m_vbuf : sata_rxfifo
port map
(
din        => i_vbuf_din,
wr_en      => i_vbuf_wr,
wr_clk     => i_vbuf_wrclk,

dout       => i_vbuf_dout,
rd_en      => i_vbuf_rd,
rd_clk     => p_in_clk,

full        => i_vbuf_full,
prog_full   => open,
empty       => i_vbuf_empty,
wr_data_count => i_vbuf_wrcount,

rst        => i_dsn_hdd_rst
);
i_vbuf_pfull<=i_vbuf_wrcount(1);


i_hdd_mem_wf <='0';
i_hdd_mem_wpf<='0';
i_hdd_mem_rpe<='0';







p_in_usr_ctrl<=(others=>'0');


--//Выделяем задний фронт из сигнала BUSY модуля m_sata_host.
--//Для детектированя завершения АТА команды
lcmddone:process(i_dsn_hdd_rst,p_in_clk)
begin
  if i_dsn_hdd_rst='1' then

    sr_cmdbusy<=(others=>'0');--sr_cmdbusy<=(others=>'1');
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
--//Программирование модуля dsn_hdd
--//########################################
ltxcmd:process
variable GUI_line : LINE;--Строка для вывода в ModelSim
variable memwr_lentrn_byte: std_logic_vector(16 + log2(CI_SECTOR_SIZE_BYTE)-1 downto 0);
variable memwr_lentrn_dw  : std_logic_vector(memwr_lentrn_byte'range);
variable memrd_lentrn_byte: std_logic_vector(memwr_lentrn_byte'range);
variable memrd_lentrn_dw  : std_logic_vector(memwr_lentrn_byte'range);
begin

  --//Инициализация:
  --//настройка RAMBUF: направление RAM<-HDD
  memwr_lentrn_byte:=CONV_STD_LOGIC_VECTOR(CI_SECTOR_SIZE_BYTE, memwr_lentrn_byte'length);
--  memwr_lentrn_byte:=CONV_STD_LOGIC_VECTOR(1*4, memwr_lentrn_byte'length);
  memwr_lentrn_dw:=("00"&memwr_lentrn_byte(memwr_lentrn_byte'high downto 2));

  --//настройка RAMBUF: направление RAM->HDD
  memrd_lentrn_byte:=CONV_STD_LOGIC_VECTOR(CI_SECTOR_SIZE_BYTE, memrd_lentrn_byte'length);
  memrd_lentrn_dw:=("00"&memrd_lentrn_byte(memrd_lentrn_byte'high downto 2));

  i_cmd_wrdone<='0';

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

  wait until g_host_clk'event and g_host_clk='1';
    i_cfgdev_adr<=CONV_STD_LOGIC_VECTOR(C_DSN_HDD_REG_RBUF_CTRL_L, i_cfgdev_adr'length);
    i_cfgdev_adr_ld<='1';
    i_cfgdev_adr_fifo<='0';
  wait until g_host_clk'event and g_host_clk='1';
    i_cfgdev_adr_ld<='0';
    i_cfgdev_adr_fifo<='0';
    i_cfgdev_txdata(7 downto 0) <=memwr_lentrn_dw(7 downto 0);
    i_cfgdev_txdata(15 downto 8)<=memrd_lentrn_dw(7 downto 0);
    i_dev_cfg_wd(C_CFGDEV_HDD)<='1';

  wait until g_host_clk'event and g_host_clk='1';
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

      wait until g_host_clk'event and g_host_clk='1';
        if i_dsnhdd_reg_ctrl_write='0' then
        i_cfgdev_adr<=CONV_STD_LOGIC_VECTOR(C_DSN_HDD_REG_CMDFIFO, i_cfgdev_adr'length);
        else
        i_cfgdev_adr<=CONV_STD_LOGIC_VECTOR(C_DSN_HDD_REG_CTRL_L, i_cfgdev_adr'length);
        end if;

        i_cfgdev_adr_ld<='1';
        i_cfgdev_adr_fifo<=not i_dsnhdd_reg_ctrl_write;
      wait until g_host_clk'event and g_host_clk='1';
        i_cfgdev_adr_ld<='0';
        i_cfgdev_adr_fifo<=not i_dsnhdd_reg_ctrl_write;

      if i_dsnhdd_reg_ctrl_write='0' then
        wait until g_host_clk'event and g_host_clk='1';
          p_CMDPKT_WRITE(g_host_clk,
                        i_cmd_data,
                        i_cfgdev_txdata, i_dev_cfg_wd(C_CFGDEV_HDD));
      else
        wait until g_host_clk'event and g_host_clk='1';
        i_cfgdev_txdata<=i_dsnhdd_reg_ctrl_val;
        i_dev_cfg_wd(C_CFGDEV_HDD)<='1';
        wait until g_host_clk'event and g_host_clk='1';
        i_dev_cfg_wd(C_CFGDEV_HDD)<='0';
      end if;

      wait until g_host_clk'event and g_host_clk='1';
        i_dev_cfg_done(C_CFGDEV_HDD)<='1';
      wait until g_host_clk'event and g_host_clk='1';
        i_dev_cfg_done(C_CFGDEV_HDD)<='0';

      wait until p_in_clk'event and p_in_clk='1';
        i_cmd_wrdone<='1';
      wait until p_in_clk'event and p_in_clk='1';
        i_cmd_wrdone<='0';

  end loop ltxcmdloop;

  wait;
end process ltxcmd;

--i_cmd_wrdone<=i_dev_cfg_done(C_CFGDEV_HDD);



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

  elsif p_in_clk'event and p_in_clk='1' then

    if i_ram_rxbuf_start = '1' or i_vdata_start='1' then

      --//Инициализация
      for i in 0 to i_ram_txbuf'high loop
      i_ram_rxbuf(i)<=(others=>'0');
      end loop;
      dcnt:=0;

    else
      if i_hdd_mem_wr='1' then
        i_ram_rxbuf(dcnt)<=i_hdd_mem_din;
        if dcnt=i_ram_rxbuf'length-1 then
          dcnt:=0;
        else
          dcnt:=dcnt + 1;
        end if;
      end if;

    end if;
  end if;
end process lmem_trn_wr;

i_ram_rxbuf_done<=i_rbuf_status.done;


--//########################################
--//Чтение данных ОЗУ
--//########################################
lmem_trn_rd:process
variable memtrn_term: std_logic:='0';
variable dcnt      : integer;
variable srcambler : std_logic_vector(31 downto 0):=(others=>'0');
variable GUI_line  : LINE;--Строка для вывода в ModelSim
begin

  i_hdd_mem_dout<=(others=>'0');
  i_hdd_mem_re<='1';
  i_ram_txbuf_done<='0';

   memtrn_term:='0';

  --//Инициализация генератора рандомных данных
  srcambler:=srambler32_0(CONV_STD_LOGIC_VECTOR(16#1032#, 16));

  while true loop

      wait until i_ram_txbuf_start = '1' or i_vdata_start = '1';--//Ждем разрешения чтения данных

          --//Инициализация
          for i in 0 to i_ram_txbuf'high loop
          i_ram_txbuf(i)<=(others=>'0');
          end loop;

          --//Генератор тестовых данных
          for i in 0 to i_ram_txbuf'high loop
            if i_ram_txbuf_fillselect='0' then
              i_ram_txbuf(i)<=CONV_STD_LOGIC_VECTOR(i+1, i_ram_txbuf(i)'length);--счетчик
            else
              i_ram_txbuf(i)<=srcambler;--//Random Data
            end if;
            srcambler:=srambler32_0(srcambler(31 downto 16));--//Инкрементация скремблера
          end loop;

          dcnt:=0;

      if i_sw_mode='1' then
      --//-------------------------------------
      --//SW mode
      --//-------------------------------------
          --//Чтение данных ОЗУ
          while dcnt/=i_tstdata_dwsize loop

              wait until i_hdd_mem_ce='1' and i_hdd_mem_cw='0' and p_in_clk'event and p_in_clk='1';--//Ждем начала trn_mem_rd

              while i_hdd_mem_term='0' loop

                wait until p_in_clk'event and p_in_clk='1';
                  if i_hdd_mem_term='0' then
                    i_hdd_mem_re<='0';
                    i_hdd_mem_dout<=i_ram_txbuf(dcnt);
                    if dcnt=i_ram_txbuf'length-1 then
                      dcnt:=0;
                    else
                      dcnt:=dcnt + 1;
                    end if;
                  end if;
              end loop;
              dcnt:=dcnt - 1;
              i_hdd_mem_re<='1';
          end loop;

      elsif i_hw_mode='1' then
      --//-------------------------------------
      --//HW mode
      --//-------------------------------------
          --//Чтение данных ОЗУ
          while i_hw_mode_stop='0' loop

              wait until i_hdd_mem_ce='1' and i_hdd_mem_cw='0' and p_in_clk'event and p_in_clk='1';--//Ждем начала trn_mem_rd

              while i_hdd_mem_term='0' loop
                wait until p_in_clk'event and p_in_clk='1';
                  if i_hdd_mem_term='0' then
                    i_hdd_mem_re<='0';
                    i_hdd_mem_dout<=i_ram_rxbuf(dcnt);
                    if dcnt=i_ram_txbuf'length-1 then
                      dcnt:=0;
                    else
                      dcnt:=dcnt + 1;
                    end if;
                  end if;
              end loop;

              if dcnt=0 then
                dcnt:=i_ram_txbuf'length-1;
              else
                dcnt:=dcnt - 1;
              end if;
              i_hdd_mem_re<='1';
          end loop;

      else
        wait until p_in_clk'event and p_in_clk='1';
      end if;

      wait until p_in_clk'event and p_in_clk='1';
        i_ram_txbuf_done<='1';
      wait until p_in_clk'event and p_in_clk='1';
        i_ram_txbuf_done<='0';

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

  --//Инициализация генератора рандомных данных
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

              lmemtrn_wr_hw:while i_vbuf_wrcount(2)/='1' loop

                    wait until i_vbuf_wrclk'event and i_vbuf_wrclk='1';
                    i_vbuf_wr<='1';
                    if i_ram_txbuf_fillselect='0' then
                      i_vbuf_din<=CONV_STD_LOGIC_VECTOR(dcnt, i_hdd_mem_dout'length);--счетчик
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

type TSimCfgCmdPkts is array (0 to 64) of TSimCfgCmdPkt;
variable cfgCmdPkt : TSimCfgCmdPkts;
variable cmd_write : std_logic:='0';
variable cmd_read  : std_logic:='0';
variable cmddone_det: std_logic:='0';


variable string_value : std_logic_vector(3 downto 0);
variable GUI_line  : LINE;--Строка для вывода в ModelSim

begin

  --//---------------------------------------------------
  --/Инициализация
  --//---------------------------------------------------
  i_tst_mode<='1';
      i_tst_command<=C_ATA_CMD_WRITE_DMA_EXT;--C_ATA_CMD_READ_DMA_EXT;--;C_ATA_CMD_READ_SECTORS_EXT;--C_ATA_CMD_WRITE_SECTORS_EXT;--
      i_dsnhdd_reg_ctrl_val<=(others=>'0');
      i_dsnhdd_reg_ctrl_val(C_DSN_HDD_REG_CTRLL_CLR_ERR_BIT)<='0';
      i_dsnhdd_reg_ctrl_val(C_DSN_HDD_REG_CTRLL_CLR_BUF_BIT)<='0';
      i_dsnhdd_reg_ctrl_val(C_DSN_HDD_REG_CTRLL_TST_ON_BIT)<='1';
      i_dsnhdd_reg_ctrl_val(C_DSN_HDD_REG_CTRLL_TST_RANDOM_BIT)<='0';
      i_dsnhdd_reg_ctrl_val(C_DSN_HDD_REG_CTRLL_OVERFLOW_DET_BIT)<='0';
      i_dsnhdd_reg_ctrl_val(C_DSN_HDD_REG_CTRLL_MEASURE_BUSY_ONLY_BIT)<='0';
      i_dsnhdd_reg_ctrl_val(C_DSN_HDD_REG_CTRLL_MEASURE_TXHOLD_DIS_BIT)<='0';
      i_dsnhdd_reg_ctrl_val(C_DSN_HDD_REG_CTRLL_MEASURE_RXHOLD_DIS_BIT)<='0';
      i_dsnhdd_reg_ctrl_val(C_DSN_HDD_REG_CTRLL_TST_GEN2RAMBUF_BIT)<='0';
      i_dsnhdd_reg_ctrl_val(C_DSN_HDD_REG_CTRLL_TST_GENTDATA_BIT)<='0';

  i_sw_mode<='1';
  i_sw_sata_cs<=16#01#;

  i_hw_mode<='0';
  i_hw_sata_cs<=16#03#;
  i_hw_mode_stop<='0';

  i_cmd_wrstart<='0';
  i_ram_txbuf_start<='0';
  i_ram_rxbuf_start<='0';
  i_tstdata_dwsize<=0;
  i_loopback<='0';
  i_cmddone_det_clr<='0';
  i_dsn_hdd_regcfg_start<='0';
  i_dsnhdd_reg_ctrl_write<='0';

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
  end loop;

  wait until i_dsn_hdd_rst='0';

  wait until i_hdd_busy='0';

  wait until p_in_clk'event and p_in_clk='1';
  i_dsn_hdd_regcfg_start<='1';
  wait until p_in_clk'event and p_in_clk='1';
  i_dsn_hdd_regcfg_start<='0';

  wait until p_in_clk'event and p_in_clk='1' and i_dsn_hdd_regcfg_done='1';
  write(GUI_line,string'("module DSN_HDD: cfg reg - DONE."));writeline(output, GUI_line);

  i_ram_txbuf_fillselect<='0'; --//0/1 - Счетчик/Random DATA

  --//Инициализируем команды которые будут отправлятся:
  if i_sw_mode='1' and i_hw_mode='1' then
  --//Завершаем модеоирование.
  p_SIM_STOP("ERROR - testbanch i_sw_mode='1' and i_hw_mode='1'");


  elsif i_sw_mode='0' and i_hw_mode='1' then
  --//####################
  --//HW mode:
  --//####################
  cfgCmdPkt(0).usr_ctrl(C_CMDPKT_SATA_CS_M_BIT downto C_CMDPKT_SATA_CS_L_BIT):=CONV_STD_LOGIC_VECTOR(0, C_CMDPKT_SATA_CS_M_BIT-C_CMDPKT_SATA_CS_L_BIT+1);
  cfgCmdPkt(0).usr_ctrl(C_CMDPKT_RAIDCMD_M_BIT downto C_CMDPKT_RAIDCMD_L_BIT):=CONV_STD_LOGIC_VECTOR(C_RAIDCMD_LBAEND, C_CMDPKT_RAIDCMD_M_BIT-C_CMDPKT_RAIDCMD_L_BIT+1);
  cfgCmdPkt(0).usr_ctrl(C_CMDPKT_SATACMD_M_BIT downto C_CMDPKT_SATACMD_L_BIT):=CONV_STD_LOGIC_VECTOR(C_SATACMD_NULL, C_CMDPKT_SATACMD_M_BIT-C_CMDPKT_SATACMD_L_BIT+1);
  cfgCmdPkt(0).command:=0;
  cfgCmdPkt(0).scount:=0;--//Кол-во секторов
  cfgCmdPkt(0).lba:=CONV_STD_LOGIC_VECTOR(16#0000#, 16)&CONV_STD_LOGIC_VECTOR(16#0000#, 16)&CONV_STD_LOGIC_VECTOR(16#010#, 16);--//LBA
  cfgCmdPkt(0).loopback:='0';

  cfgCmdPkt(1).usr_ctrl(C_CMDPKT_SATA_CS_M_BIT downto C_CMDPKT_SATA_CS_L_BIT):=CONV_STD_LOGIC_VECTOR(i_hw_sata_cs, C_CMDPKT_SATA_CS_M_BIT-C_CMDPKT_SATA_CS_L_BIT+1);
  cfgCmdPkt(1).usr_ctrl(C_CMDPKT_RAIDCMD_M_BIT downto C_CMDPKT_RAIDCMD_L_BIT):=CONV_STD_LOGIC_VECTOR(C_RAIDCMD_HW, C_CMDPKT_RAIDCMD_M_BIT-C_CMDPKT_RAIDCMD_L_BIT+1);
  cfgCmdPkt(1).usr_ctrl(C_CMDPKT_SATACMD_M_BIT downto C_CMDPKT_SATACMD_L_BIT):=CONV_STD_LOGIC_VECTOR(C_SATACMD_ATACOMMAND, C_CMDPKT_SATACMD_M_BIT-C_CMDPKT_SATACMD_L_BIT+1);
  cfgCmdPkt(1).command:=C_ATA_CMD_WRITE_DMA_EXT;--C_ATA_CMD_READ_DMA_EXT;--
  cfgCmdPkt(1).scount:=2;--//Кол-во секторов
  cfgCmdPkt(1).lba:=CONV_STD_LOGIC_VECTOR(16#0000#, 16)&CONV_STD_LOGIC_VECTOR(16#0000#, 16)&CONV_STD_LOGIC_VECTOR(16#000#, 16);--//LBA
  cfgCmdPkt(1).loopback:='0';


  elsif i_sw_mode='1' and i_hw_mode='0' then
  --//####################
  --//SW mode:
  --//####################
  cfgCmdPkt(0).usr_ctrl(C_CMDPKT_SATA_CS_M_BIT downto C_CMDPKT_SATA_CS_L_BIT):=CONV_STD_LOGIC_VECTOR(i_sw_sata_cs, C_CMDPKT_SATA_CS_M_BIT-C_CMDPKT_SATA_CS_L_BIT+1);
  cfgCmdPkt(0).usr_ctrl(C_CMDPKT_RAIDCMD_M_BIT downto C_CMDPKT_RAIDCMD_L_BIT):=CONV_STD_LOGIC_VECTOR(C_RAIDCMD_SW, C_CMDPKT_RAIDCMD_M_BIT-C_CMDPKT_RAIDCMD_L_BIT+1);
  cfgCmdPkt(0).usr_ctrl(C_CMDPKT_SATACMD_M_BIT downto C_CMDPKT_SATACMD_L_BIT):=CONV_STD_LOGIC_VECTOR(C_SATACMD_ATACOMMAND, C_CMDPKT_SATACMD_M_BIT-C_CMDPKT_SATACMD_L_BIT+1);
  cfgCmdPkt(0).command:=C_ATA_CMD_WRITE_DMA_EXT;--;C_ATA_CMD_READ_SECTORS_EXT;--C_ATA_CMD_WRITE_SECTORS_EXT;--;C_ATA_CMD_NOP;--
  cfgCmdPkt(0).scount:=6;--//Кол-во секторов
  cfgCmdPkt(0).lba:=CONV_STD_LOGIC_VECTOR(16#0605#, 16)&CONV_STD_LOGIC_VECTOR(16#0403#, 16)&CONV_STD_LOGIC_VECTOR(16#0201#, 16);--//LBA
  cfgCmdPkt(0).loopback:='1';

  cfgCmdPkt(1).usr_ctrl(C_CMDPKT_SATA_CS_M_BIT downto C_CMDPKT_SATA_CS_L_BIT):=CONV_STD_LOGIC_VECTOR(i_sw_sata_cs, C_CMDPKT_SATA_CS_M_BIT-C_CMDPKT_SATA_CS_L_BIT+1);
  cfgCmdPkt(1).usr_ctrl(C_CMDPKT_RAIDCMD_M_BIT downto C_CMDPKT_RAIDCMD_L_BIT):=CONV_STD_LOGIC_VECTOR(C_RAIDCMD_SW, C_CMDPKT_RAIDCMD_M_BIT-C_CMDPKT_RAIDCMD_L_BIT+1);
  cfgCmdPkt(1).usr_ctrl(C_CMDPKT_SATACMD_M_BIT downto C_CMDPKT_SATACMD_L_BIT):=CONV_STD_LOGIC_VECTOR(C_SATACMD_ATACOMMAND, C_CMDPKT_SATACMD_M_BIT-C_CMDPKT_SATACMD_L_BIT+1);
  cfgCmdPkt(1).command:=C_ATA_CMD_READ_DMA_EXT;--C_ATA_CMD_WRITE_SECTORS_EXT;--C_ATA_CMD_READ_SECTORS_EXT;--
  cfgCmdPkt(1).scount:=6;
  cfgCmdPkt(1).lba:=CONV_STD_LOGIC_VECTOR(16#6655#, 16)&CONV_STD_LOGIC_VECTOR(16#4433#, 16)&CONV_STD_LOGIC_VECTOR(16#2211#, 16);--//LBA
  cfgCmdPkt(1).loopback:='1';
  end if;

  cfgCmdPkt(2).usr_ctrl(C_CMDPKT_SATA_CS_M_BIT downto C_CMDPKT_SATA_CS_L_BIT):=CONV_STD_LOGIC_VECTOR(i_sw_sata_cs, C_CMDPKT_SATA_CS_M_BIT-C_CMDPKT_SATA_CS_L_BIT+1);
  cfgCmdPkt(2).usr_ctrl(C_CMDPKT_RAIDCMD_M_BIT downto C_CMDPKT_RAIDCMD_L_BIT):=CONV_STD_LOGIC_VECTOR(C_RAIDCMD_SW, C_CMDPKT_RAIDCMD_M_BIT-C_CMDPKT_RAIDCMD_L_BIT+1);
  cfgCmdPkt(2).usr_ctrl(C_CMDPKT_SATACMD_M_BIT downto C_CMDPKT_SATACMD_L_BIT):=CONV_STD_LOGIC_VECTOR(C_SATACMD_ATACOMMAND, C_CMDPKT_SATACMD_M_BIT-C_CMDPKT_SATACMD_L_BIT+1);
  cfgCmdPkt(2).command:=C_ATA_CMD_WRITE_SECTORS_EXT;--C_ATA_CMD_WRITE_DMA_EXT;--
  cfgCmdPkt(2).scount:=6;
  cfgCmdPkt(2).lba:=CONV_STD_LOGIC_VECTOR(16#0605#, 16)&CONV_STD_LOGIC_VECTOR(16#0403#, 16)&CONV_STD_LOGIC_VECTOR(16#0201#, 16);--//LBA
  cfgCmdPkt(2).loopback:='0';

  cfgCmdPkt(3).usr_ctrl(C_CMDPKT_SATA_CS_M_BIT downto C_CMDPKT_SATA_CS_L_BIT):=CONV_STD_LOGIC_VECTOR(i_sw_sata_cs, C_CMDPKT_SATA_CS_M_BIT-C_CMDPKT_SATA_CS_L_BIT+1);
  cfgCmdPkt(3).usr_ctrl(C_CMDPKT_RAIDCMD_M_BIT downto C_CMDPKT_RAIDCMD_L_BIT):=CONV_STD_LOGIC_VECTOR(C_RAIDCMD_SW, C_CMDPKT_RAIDCMD_M_BIT-C_CMDPKT_RAIDCMD_L_BIT+1);
  cfgCmdPkt(3).usr_ctrl(C_CMDPKT_SATACMD_M_BIT downto C_CMDPKT_SATACMD_L_BIT):=CONV_STD_LOGIC_VECTOR(C_SATACMD_ATACOMMAND, C_CMDPKT_SATACMD_M_BIT-C_CMDPKT_SATACMD_L_BIT+1);
  cfgCmdPkt(3).command:=C_ATA_CMD_WRITE_SECTORS_EXT;--C_ATA_CMD_READ_SECTORS_EXT;--C_ATA_CMD_READ_DMA_EXT;--
  cfgCmdPkt(3).scount:=6;
  cfgCmdPkt(3).lba:=CONV_STD_LOGIC_VECTOR(16#0605#, 16)&CONV_STD_LOGIC_VECTOR(16#0403#, 16)&CONV_STD_LOGIC_VECTOR(16#0201#, 16);--//LBA
  cfgCmdPkt(3).loopback:='0';

  cfgCmdPkt(4).usr_ctrl(C_CMDPKT_SATA_CS_M_BIT downto C_CMDPKT_SATA_CS_L_BIT):=CONV_STD_LOGIC_VECTOR(i_sw_sata_cs, C_CMDPKT_SATA_CS_M_BIT-C_CMDPKT_SATA_CS_L_BIT+1);
  cfgCmdPkt(4).usr_ctrl(C_CMDPKT_RAIDCMD_M_BIT downto C_CMDPKT_RAIDCMD_L_BIT):=CONV_STD_LOGIC_VECTOR(C_RAIDCMD_SW, C_CMDPKT_RAIDCMD_M_BIT-C_CMDPKT_RAIDCMD_L_BIT+1);
  cfgCmdPkt(4).usr_ctrl(C_CMDPKT_SATACMD_M_BIT downto C_CMDPKT_SATACMD_L_BIT):=CONV_STD_LOGIC_VECTOR(C_SATACMD_ATACOMMAND, C_CMDPKT_SATACMD_M_BIT-C_CMDPKT_SATACMD_L_BIT+1);
  cfgCmdPkt(4).command:=C_ATA_CMD_WRITE_DMA_EXT;--
  cfgCmdPkt(4).scount:=9;
  cfgCmdPkt(4).lba:=CONV_STD_LOGIC_VECTOR(16#0605#, 16)&CONV_STD_LOGIC_VECTOR(16#0403#, 16)&CONV_STD_LOGIC_VECTOR(16#0201#, 16);--//LBA
  cfgCmdPkt(4).loopback:='1';

  cfgCmdPkt(5).usr_ctrl(C_CMDPKT_SATA_CS_M_BIT downto C_CMDPKT_SATA_CS_L_BIT):=CONV_STD_LOGIC_VECTOR(i_sw_sata_cs, C_CMDPKT_SATA_CS_M_BIT-C_CMDPKT_SATA_CS_L_BIT+1);
  cfgCmdPkt(5).usr_ctrl(C_CMDPKT_RAIDCMD_M_BIT downto C_CMDPKT_RAIDCMD_L_BIT):=CONV_STD_LOGIC_VECTOR(C_RAIDCMD_SW, C_CMDPKT_RAIDCMD_M_BIT-C_CMDPKT_RAIDCMD_L_BIT+1);
  cfgCmdPkt(5).usr_ctrl(C_CMDPKT_SATACMD_M_BIT downto C_CMDPKT_SATACMD_L_BIT):=CONV_STD_LOGIC_VECTOR(C_SATACMD_ATACOMMAND, C_CMDPKT_SATACMD_M_BIT-C_CMDPKT_SATACMD_L_BIT+1);
  cfgCmdPkt(5).command:=C_ATA_CMD_READ_DMA_EXT;--
  cfgCmdPkt(5).scount:=9;
  cfgCmdPkt(5).lba:=CONV_STD_LOGIC_VECTOR(16#0605#, 16)&CONV_STD_LOGIC_VECTOR(16#0403#, 16)&CONV_STD_LOGIC_VECTOR(16#0201#, 16);--//LBA
  cfgCmdPkt(5).loopback:='1';

  cfgCmdPkt(6).usr_ctrl(C_CMDPKT_SATA_CS_M_BIT downto C_CMDPKT_SATA_CS_L_BIT):=CONV_STD_LOGIC_VECTOR(i_sw_sata_cs, C_CMDPKT_SATA_CS_M_BIT-C_CMDPKT_SATA_CS_L_BIT+1);
  cfgCmdPkt(6).usr_ctrl(C_CMDPKT_RAIDCMD_M_BIT downto C_CMDPKT_RAIDCMD_L_BIT):=CONV_STD_LOGIC_VECTOR(C_RAIDCMD_SW, C_CMDPKT_RAIDCMD_M_BIT-C_CMDPKT_RAIDCMD_L_BIT+1);
  cfgCmdPkt(6).usr_ctrl(C_CMDPKT_SATACMD_M_BIT downto C_CMDPKT_SATACMD_L_BIT):=CONV_STD_LOGIC_VECTOR(C_SATACMD_ATACOMMAND, C_CMDPKT_SATACMD_M_BIT-C_CMDPKT_SATACMD_L_BIT+1);
  cfgCmdPkt(6).command:=C_ATA_CMD_READ_DMA_EXT;--
  cfgCmdPkt(6).scount:=9;
  cfgCmdPkt(6).lba:=CONV_STD_LOGIC_VECTOR(16#0605#, 16)&CONV_STD_LOGIC_VECTOR(16#0403#, 16)&CONV_STD_LOGIC_VECTOR(16#0201#, 16);--//LBA
  cfgCmdPkt(6).loopback:='0';

  cfgCmdPkt(7).usr_ctrl(C_CMDPKT_SATA_CS_M_BIT downto C_CMDPKT_SATA_CS_L_BIT):=CONV_STD_LOGIC_VECTOR(i_sw_sata_cs, C_CMDPKT_SATA_CS_M_BIT-C_CMDPKT_SATA_CS_L_BIT+1);
  cfgCmdPkt(7).usr_ctrl(C_CMDPKT_RAIDCMD_M_BIT downto C_CMDPKT_RAIDCMD_L_BIT):=CONV_STD_LOGIC_VECTOR(C_RAIDCMD_SW, C_CMDPKT_RAIDCMD_M_BIT-C_CMDPKT_RAIDCMD_L_BIT+1);
  cfgCmdPkt(7).usr_ctrl(C_CMDPKT_SATACMD_M_BIT downto C_CMDPKT_SATACMD_L_BIT):=CONV_STD_LOGIC_VECTOR(C_SATACMD_ATACOMMAND, C_CMDPKT_SATACMD_M_BIT-C_CMDPKT_SATACMD_L_BIT+1);
  cfgCmdPkt(7).command:=C_ATA_CMD_READ_DMA_EXT;--
  cfgCmdPkt(7).scount:=9;
  cfgCmdPkt(7).lba:=CONV_STD_LOGIC_VECTOR(16#0605#, 16)&CONV_STD_LOGIC_VECTOR(16#0403#, 16)&CONV_STD_LOGIC_VECTOR(16#0201#, 16);--//LBA
  cfgCmdPkt(7).loopback:='0';

  cfgCmdPkt(8).usr_ctrl(C_CMDPKT_SATA_CS_M_BIT downto C_CMDPKT_SATA_CS_L_BIT):=CONV_STD_LOGIC_VECTOR(i_sw_sata_cs, C_CMDPKT_SATA_CS_M_BIT-C_CMDPKT_SATA_CS_L_BIT+1);
  cfgCmdPkt(8).usr_ctrl(C_CMDPKT_RAIDCMD_M_BIT downto C_CMDPKT_RAIDCMD_L_BIT):=CONV_STD_LOGIC_VECTOR(C_RAIDCMD_SW, C_CMDPKT_RAIDCMD_M_BIT-C_CMDPKT_RAIDCMD_L_BIT+1);
  cfgCmdPkt(8).usr_ctrl(C_CMDPKT_SATACMD_M_BIT downto C_CMDPKT_SATACMD_L_BIT):=CONV_STD_LOGIC_VECTOR(C_SATACMD_ATACOMMAND, C_CMDPKT_SATACMD_M_BIT-C_CMDPKT_SATACMD_L_BIT+1);
  cfgCmdPkt(8).command:=C_ATA_CMD_READ_DMA_EXT;--
  cfgCmdPkt(8).scount:=9;
  cfgCmdPkt(8).lba:=CONV_STD_LOGIC_VECTOR(16#0605#, 16)&CONV_STD_LOGIC_VECTOR(16#0403#, 16)&CONV_STD_LOGIC_VECTOR(16#0201#, 16);--//LBA
  cfgCmdPkt(8).loopback:='0';

  cfgCmdPkt(9).usr_ctrl(C_CMDPKT_SATA_CS_M_BIT downto C_CMDPKT_SATA_CS_L_BIT):=CONV_STD_LOGIC_VECTOR(i_sw_sata_cs, C_CMDPKT_SATA_CS_M_BIT-C_CMDPKT_SATA_CS_L_BIT+1);
  cfgCmdPkt(9).usr_ctrl(C_CMDPKT_RAIDCMD_M_BIT downto C_CMDPKT_RAIDCMD_L_BIT):=CONV_STD_LOGIC_VECTOR(C_RAIDCMD_SW, C_CMDPKT_RAIDCMD_M_BIT-C_CMDPKT_RAIDCMD_L_BIT+1);
  cfgCmdPkt(9).usr_ctrl(C_CMDPKT_SATACMD_M_BIT downto C_CMDPKT_SATACMD_L_BIT):=CONV_STD_LOGIC_VECTOR(C_SATACMD_ATACOMMAND, C_CMDPKT_SATACMD_M_BIT-C_CMDPKT_SATACMD_L_BIT+1);
  cfgCmdPkt(9).command:=C_ATA_CMD_READ_DMA_EXT;--
  cfgCmdPkt(9).scount:=9;
  cfgCmdPkt(9).lba:=CONV_STD_LOGIC_VECTOR(16#0605#, 16)&CONV_STD_LOGIC_VECTOR(16#0403#, 16)&CONV_STD_LOGIC_VECTOR(16#0201#, 16);--//LBA
  cfgCmdPkt(9).loopback:='0';

  cfgCmdPkt(10).usr_ctrl(C_CMDPKT_SATA_CS_M_BIT downto C_CMDPKT_SATA_CS_L_BIT):=CONV_STD_LOGIC_VECTOR(i_sw_sata_cs, C_CMDPKT_SATA_CS_M_BIT-C_CMDPKT_SATA_CS_L_BIT+1);
  cfgCmdPkt(10).usr_ctrl(C_CMDPKT_RAIDCMD_M_BIT downto C_CMDPKT_RAIDCMD_L_BIT):=CONV_STD_LOGIC_VECTOR(C_RAIDCMD_SW, C_CMDPKT_RAIDCMD_M_BIT-C_CMDPKT_RAIDCMD_L_BIT+1);
  cfgCmdPkt(10).usr_ctrl(C_CMDPKT_SATACMD_M_BIT downto C_CMDPKT_SATACMD_L_BIT):=CONV_STD_LOGIC_VECTOR(C_SATACMD_ATACOMMAND, C_CMDPKT_SATACMD_M_BIT-C_CMDPKT_SATACMD_L_BIT+1);
  cfgCmdPkt(10).command:=C_ATA_CMD_READ_DMA_EXT;--
  cfgCmdPkt(10).scount:=9;
  cfgCmdPkt(10).lba:=CONV_STD_LOGIC_VECTOR(16#0605#, 16)&CONV_STD_LOGIC_VECTOR(16#0403#, 16)&CONV_STD_LOGIC_VECTOR(16#0201#, 16);--//LBA
  cfgCmdPkt(10).loopback:='0';

  cfgCmdPkt(11).usr_ctrl(C_CMDPKT_SATA_CS_M_BIT downto C_CMDPKT_SATA_CS_L_BIT):=CONV_STD_LOGIC_VECTOR(i_sw_sata_cs, C_CMDPKT_SATA_CS_M_BIT-C_CMDPKT_SATA_CS_L_BIT+1);
  cfgCmdPkt(11).usr_ctrl(C_CMDPKT_RAIDCMD_M_BIT downto C_CMDPKT_RAIDCMD_L_BIT):=CONV_STD_LOGIC_VECTOR(C_RAIDCMD_SW, C_CMDPKT_RAIDCMD_M_BIT-C_CMDPKT_RAIDCMD_L_BIT+1);
  cfgCmdPkt(11).usr_ctrl(C_CMDPKT_SATACMD_M_BIT downto C_CMDPKT_SATACMD_L_BIT):=CONV_STD_LOGIC_VECTOR(C_SATACMD_ATACOMMAND, C_CMDPKT_SATACMD_M_BIT-C_CMDPKT_SATACMD_L_BIT+1);
  cfgCmdPkt(11).command:=C_ATA_CMD_READ_DMA_EXT;--
  cfgCmdPkt(11).scount:=9;
  cfgCmdPkt(11).lba:=CONV_STD_LOGIC_VECTOR(16#0605#, 16)&CONV_STD_LOGIC_VECTOR(16#0403#, 16)&CONV_STD_LOGIC_VECTOR(16#0201#, 16);--//LBA
  cfgCmdPkt(11).loopback:='0';




  --//---------------------------------------------------
  --//Отработка команд командного пакета
  --//---------------------------------------------------
  if cfgCmdPkt(0).usr_ctrl(C_CMDPKT_RAIDCMD_M_BIT downto C_CMDPKT_RAIDCMD_L_BIT)=CONV_STD_LOGIC_VECTOR(C_RAIDCMD_SW, C_CMDPKT_RAIDCMD_M_BIT-C_CMDPKT_RAIDCMD_L_BIT+1) then
      --//##################################
      write(GUI_line,string'("SW mode!!!")); writeline(output, GUI_line);
      --//##################################

      ltrn_count : for idx in 0 to C_SIM_COUNT-1 loop

      i_loopback<=cfgCmdPkt(idx).loopback;

      --//Ждем разрешения загрузки командного пакета
      wait until p_in_clk'event and p_in_clk='1' and i_cmddone_det='1';

      --//Сброс флага i_cmddone_det
      wait until p_in_clk'event and p_in_clk='1';
      i_cmddone_det_clr<='1';
      wait until p_in_clk'event and p_in_clk='1';
      i_cmddone_det_clr<='0';


      if i_tst_mode='1' then
      write(GUI_line,string'("TST_MODE - ON."));writeline(output, GUI_line);
        --//Конфигурируем тестовый режим
        wait until p_in_clk'event and p_in_clk='1';
        i_dsnhdd_reg_ctrl_write<='1';
        wait until p_in_clk'event and p_in_clk='1';
        i_cmd_wrstart<='1';
        wait until p_in_clk'event and p_in_clk='1';
        i_cmd_wrstart<='0';

          --//Ждем отправки подтверждения записи командного пакета
        wait until i_cmd_wrdone='1';
        wait until p_in_clk'event and p_in_clk='1';
        i_dsnhdd_reg_ctrl_write<='0';
      end if;--if i_tst_mode='1' then


      write(GUI_line,string'("NEW ATA COMMAND 1."));writeline(output, GUI_line);

      --//Заполняем CmdPkt
      i_cmd_data(0)<=cfgCmdPkt(idx).usr_ctrl; --//UsrCTRL
      i_cmd_data(1)<=CONV_STD_LOGIC_VECTOR(16#AA55#, 16);--//Feature
      i_cmd_data(2)<=cfgCmdPkt(idx).lba(15 downto  8) & cfgCmdPkt(idx).lba( 7 downto 0);
      i_cmd_data(3)<=cfgCmdPkt(idx).lba(31 downto 24) & cfgCmdPkt(idx).lba(23 downto 16);
      i_cmd_data(4)<=cfgCmdPkt(idx).lba(47 downto 40) & cfgCmdPkt(idx).lba(39 downto 32);
      i_cmd_data(5)<=CONV_STD_LOGIC_VECTOR(cfgCmdPkt(idx).scount, 16);--//SectorCount
      i_cmd_data(6)<=cfgCmdPkt(idx).control & cfgCmdPkt(idx).device;--//Control + Device
      if i_tst_mode='0' then
      i_cmd_data(7)<=CONV_STD_LOGIC_VECTOR(0, 8) & CONV_STD_LOGIC_VECTOR(cfgCmdPkt(idx).command, 8);--//Reserv + ATA Commad
      else
      i_cmd_data(7)<=CONV_STD_LOGIC_VECTOR(0, 8) & CONV_STD_LOGIC_VECTOR(i_tst_command, 8);--//Reserv + ATA Commad
      end if;


      if cfgCmdPkt(idx).usr_ctrl(C_CMDPKT_SATA_CS_M_BIT downto C_CMDPKT_SATA_CS_L_BIT)=CONV_STD_LOGIC_VECTOR(1, C_CMDPKT_SATA_CS_M_BIT-C_CMDPKT_SATA_CS_L_BIT+1) or
         cfgCmdPkt(idx).usr_ctrl(C_CMDPKT_SATA_CS_M_BIT downto C_CMDPKT_SATA_CS_L_BIT)=CONV_STD_LOGIC_VECTOR(2, C_CMDPKT_SATA_CS_M_BIT-C_CMDPKT_SATA_CS_L_BIT+1) or
         cfgCmdPkt(idx).usr_ctrl(C_CMDPKT_SATA_CS_M_BIT downto C_CMDPKT_SATA_CS_L_BIT)=CONV_STD_LOGIC_VECTOR(4, C_CMDPKT_SATA_CS_M_BIT-C_CMDPKT_SATA_CS_L_BIT+1) or
         cfgCmdPkt(idx).usr_ctrl(C_CMDPKT_SATA_CS_M_BIT downto C_CMDPKT_SATA_CS_L_BIT)=CONV_STD_LOGIC_VECTOR(5, C_CMDPKT_SATA_CS_M_BIT-C_CMDPKT_SATA_CS_L_BIT+1) or
         cfgCmdPkt(idx).usr_ctrl(C_CMDPKT_SATA_CS_M_BIT downto C_CMDPKT_SATA_CS_L_BIT)=CONV_STD_LOGIC_VECTOR(6, C_CMDPKT_SATA_CS_M_BIT-C_CMDPKT_SATA_CS_L_BIT+1) or
         cfgCmdPkt(idx).usr_ctrl(C_CMDPKT_SATA_CS_M_BIT downto C_CMDPKT_SATA_CS_L_BIT)=CONV_STD_LOGIC_VECTOR(7, C_CMDPKT_SATA_CS_M_BIT-C_CMDPKT_SATA_CS_L_BIT+1) then

          i_tstdata_dwsize<=cfgCmdPkt(idx).scount * C_SIM_SECTOR_SIZE_DWORD;--//Назначаем размер данных в DWORD

      elsif cfgCmdPkt(idx).usr_ctrl(C_CMDPKT_SATA_CS_M_BIT downto C_CMDPKT_SATA_CS_L_BIT)=CONV_STD_LOGIC_VECTOR(16#03#, C_CMDPKT_SATA_CS_M_BIT-C_CMDPKT_SATA_CS_L_BIT+1) then
      --//RAID HDDx2
          i_tstdata_dwsize<=cfgCmdPkt(idx).scount * C_SIM_SECTOR_SIZE_DWORD * 2;--//Назначаем размер данных в DWORD

      elsif cfgCmdPkt(idx).usr_ctrl(C_CMDPKT_SATA_CS_M_BIT downto C_CMDPKT_SATA_CS_L_BIT)=CONV_STD_LOGIC_VECTOR(16#07#, C_CMDPKT_SATA_CS_M_BIT-C_CMDPKT_SATA_CS_L_BIT+1) then
      --//RAID HDDx3
          i_tstdata_dwsize<=cfgCmdPkt(idx).scount * C_SIM_SECTOR_SIZE_DWORD * 3;--//Назначаем размер данных в DWORD

      elsif cfgCmdPkt(idx).usr_ctrl(C_CMDPKT_SATA_CS_M_BIT downto C_CMDPKT_SATA_CS_L_BIT)=CONV_STD_LOGIC_VECTOR(16#0F#, C_CMDPKT_SATA_CS_M_BIT-C_CMDPKT_SATA_CS_L_BIT+1) then
      --//RAID HDDx4
          i_tstdata_dwsize<=cfgCmdPkt(idx).scount * C_SIM_SECTOR_SIZE_DWORD * 4;--//Назначаем размер данных в DWORD

      end if;

      wait until p_in_clk'event and p_in_clk='1';
      i_cmd_wrstart<='1';
      wait until p_in_clk'event and p_in_clk='1';
      i_cmd_wrstart<='0';


      --//Ждем отправки подтверждения записи командного пакета
      wait until i_cmd_wrdone='1';


      --//Запускаем автомат записи командного пакета
      if i_tst_mode='0' then
            if cfgCmdPkt(idx).command=C_ATA_CMD_WRITE_SECTORS_EXT or cfgCmdPkt(idx).command=C_ATA_CMD_WRITE_DMA_EXT then
            --//Запускаем автомат записи данных
              wait until p_in_clk'event and p_in_clk='1';
              i_ram_txbuf_start<='1';
              cmd_write:='1';

              wait until p_in_clk'event and p_in_clk='1';
              i_ram_txbuf_start<='0';

              --//Ждем когда запишем все данные в TxBUF
              wait until i_ram_txbuf_done='1';
            end if;

            if cfgCmdPkt(idx).command=C_ATA_CMD_READ_SECTORS_EXT or cfgCmdPkt(idx).command=C_ATA_CMD_READ_DMA_EXT then
            --//Запускаем автомат чтния данных
              wait until p_in_clk'event and p_in_clk='1';
              i_ram_rxbuf_start<='1';
              cmd_read:='1';

              wait until p_in_clk'event and p_in_clk='1';
              i_ram_rxbuf_start<='0';

              --//Ждем когда прочитаем все данные из RxBUF
              wait until i_ram_rxbuf_done='1';
            end if;
      end if;--if i_tst_mode='0' then


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
              for y in 1 to 8 loop
              string_value:=i_ram_txbuf(i)((32-(4*(y-1)))-1 downto (32-(4*y)));
              write(GUI_line,Int2StrHEX(CONV_INTEGER(string_value)));
              end loop;
              write(GUI_line,string'("/0x"));
              --write(GUI_line,CONV_INTEGER(i_ram_rxbuf(i)));
              for y in 1 to 8 loop
              string_value:=i_ram_rxbuf(i)((32-(4*(y-1)))-1 downto (32-(4*y)));
              write(GUI_line,Int2StrHEX(CONV_INTEGER(string_value)));
              end loop;
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

      end loop ltrn_count;

  else
      --//##################################
      write(GUI_line,string'("HW mode!!!")); writeline(output, GUI_line);
      --//##################################


      write(GUI_line,string'("SEND CMDPKT: SET LBA_END."));writeline(output, GUI_line);
      --//Заполняем CmdPkt
      i_cmd_data(0)<=cfgCmdPkt(0).usr_ctrl; --//UsrCTRL
      i_cmd_data(1)<=CONV_STD_LOGIC_VECTOR(16#AA55#, 16);--//Feature
      i_cmd_data(2)<=cfgCmdPkt(0).lba(15 downto  8) & cfgCmdPkt(0).lba( 7 downto 0);
      i_cmd_data(3)<=cfgCmdPkt(0).lba(31 downto 24) & cfgCmdPkt(0).lba(23 downto 16);
      i_cmd_data(4)<=cfgCmdPkt(0).lba(47 downto 40) & cfgCmdPkt(0).lba(39 downto 32);
      i_cmd_data(5)<=CONV_STD_LOGIC_VECTOR(cfgCmdPkt(0).scount, 16);--//SectorCount
      i_cmd_data(6)<=cfgCmdPkt(0).control & cfgCmdPkt(0).device;--//Control + Device
      i_cmd_data(7)<=CONV_STD_LOGIC_VECTOR(0, 8) & CONV_STD_LOGIC_VECTOR(cfgCmdPkt(0).command, 8);--//Reserv + ATA Commad

      i_tstdata_dwsize<=cfgCmdPkt(0).scount * C_SIM_SECTOR_SIZE_DWORD;--//Назначаем размер данных в DWORD

      --//Запускаем автомат записи командного пакета
      wait until p_in_clk'event and p_in_clk='1';
      i_cmd_wrstart<='1';
      wait until p_in_clk'event and p_in_clk='1';
      i_cmd_wrstart<='0';

      --//Ждем отправки подтверждения записи командного пакета
      wait until i_cmd_wrdone='1';


      write(GUI_line,string'("SEND CMDPKT: ATA COMAND."));writeline(output, GUI_line);
      --//Заполняем CmdPkt
      i_cmd_data(0)<=cfgCmdPkt(1).usr_ctrl; --//UsrCTRL
      i_cmd_data(1)<=CONV_STD_LOGIC_VECTOR(16#AA55#, 16);--//Feature
      i_cmd_data(2)<=cfgCmdPkt(1).lba(15 downto  8) & cfgCmdPkt(1).lba( 7 downto 0);
      i_cmd_data(3)<=cfgCmdPkt(1).lba(31 downto 24) & cfgCmdPkt(1).lba(23 downto 16);
      i_cmd_data(4)<=cfgCmdPkt(1).lba(47 downto 40) & cfgCmdPkt(1).lba(39 downto 32);
      i_cmd_data(5)<=CONV_STD_LOGIC_VECTOR(cfgCmdPkt(1).scount, 16);--//SectorCount
      i_cmd_data(6)<=cfgCmdPkt(1).control & cfgCmdPkt(1).device;--//Control + Device
      if i_tst_mode='0' then
      i_cmd_data(7)<=CONV_STD_LOGIC_VECTOR(0, 8) & CONV_STD_LOGIC_VECTOR(cfgCmdPkt(1).command, 8);--//Reserv + ATA Commad
      else
      i_cmd_data(7)<=CONV_STD_LOGIC_VECTOR(0, 8) & CONV_STD_LOGIC_VECTOR(i_tst_command, 8);--//Reserv + ATA Commad
      end if;

      i_tstdata_dwsize<=cfgCmdPkt(1).scount * C_SIM_SECTOR_SIZE_DWORD;--//Назначаем размер данных в DWORD

      --//Запускаем автомат записи командного пакета
      wait until p_in_clk'event and p_in_clk='1';
      i_cmd_wrstart<='1';
      wait until p_in_clk'event and p_in_clk='1';
      i_cmd_wrstart<='0';

      --//Ждем отправки подтверждения записи командного пакета
      wait until i_cmd_wrdone='1';

      wait for 0.01 us;

      wait until p_in_clk'event and p_in_clk='1';

      if i_tst_mode='0' then
            if cfgCmdPkt(1).command=C_ATA_CMD_WRITE_SECTORS_EXT or cfgCmdPkt(1).command=C_ATA_CMD_WRITE_DMA_EXT then
            --//Запускаем автомат записи данных
              wait until p_in_clk'event and p_in_clk='1';
              i_vdata_start<='1';
              cmd_write:='1';

              wait until p_in_clk'event and p_in_clk='1';
              i_vdata_start<='0';

      --        --//Ждем когда запишем все данные в TxBUF
      --        wait until i_vdata_done='1';
            end if;

            if cfgCmdPkt(1).command=C_ATA_CMD_READ_SECTORS_EXT or cfgCmdPkt(1).command=C_ATA_CMD_READ_DMA_EXT then
            --//Запускаем автомат чтния данных
              wait until p_in_clk'event and p_in_clk='1';
              i_ram_rxbuf_start<='1';
              cmd_read:='1';

              wait until p_in_clk'event and p_in_clk='1';
              i_ram_rxbuf_start<='0';

      --        --//Ждем когда прочитаем все данные из RxBUF
      --        wait until i_ram_rxbuf_done='1';
            end if;
      else
        --//Конфигурируем тестовый режим
        wait until p_in_clk'event and p_in_clk='1';
        i_dsnhdd_reg_ctrl_write<='1';
        wait until p_in_clk'event and p_in_clk='1';
        i_cmd_wrstart<='1';
        wait until p_in_clk'event and p_in_clk='1';
        i_cmd_wrstart<='0';

          --//Ждем отправки подтверждения записи командного пакета
        wait until i_cmd_wrdone='1';
        wait until p_in_clk'event and p_in_clk='1';
        i_dsnhdd_reg_ctrl_write<='0';

      end if;--if i_tst_mode='0' then


      wait for 30 us;
      wait until p_in_clk'event and p_in_clk='1';
      write(GUI_line,string'("SEND CMDPKT: HW STOP."));writeline(output, GUI_line);
      --//Заполняем CmdPkt
      i_cmd_data(0)<=cfgCmdPkt(0).usr_ctrl; --//UsrCTRL
      i_cmd_data(0)(C_CMDPKT_RAIDCMD_M_BIT downto C_CMDPKT_RAIDCMD_L_BIT)<=CONV_STD_LOGIC_VECTOR(C_RAIDCMD_STOP, C_CMDPKT_RAIDCMD_M_BIT-C_CMDPKT_RAIDCMD_L_BIT+1);
      i_cmd_data(1)<=CONV_STD_LOGIC_VECTOR(16#AA55#, 16);--//Feature
      i_cmd_data(2)<=cfgCmdPkt(0).lba(15 downto  8) & cfgCmdPkt(0).lba( 7 downto 0);
      i_cmd_data(3)<=cfgCmdPkt(0).lba(31 downto 24) & cfgCmdPkt(0).lba(23 downto 16);
      i_cmd_data(4)<=cfgCmdPkt(0).lba(47 downto 40) & cfgCmdPkt(0).lba(39 downto 32);
      i_cmd_data(5)<=CONV_STD_LOGIC_VECTOR(cfgCmdPkt(0).scount, 16);--//SectorCount
      i_cmd_data(6)<=cfgCmdPkt(1).control & cfgCmdPkt(0).device;--//Control + Device
      i_cmd_data(7)<=CONV_STD_LOGIC_VECTOR(0, 8) & CONV_STD_LOGIC_VECTOR(cfgCmdPkt(1).command, 8);--//Reserv + ATA Commad

      i_tstdata_dwsize<=cfgCmdPkt(0).scount * C_SIM_SECTOR_SIZE_DWORD;--//Назначаем размер данных в DWORD

      --//Запускаем автомат записи командного пакета
      wait until p_in_clk'event and p_in_clk='1';
      i_cmd_wrstart<='1';
      wait until p_in_clk'event and p_in_clk='1';
      i_cmd_wrstart<='0';

      --//Ждем отправки подтверждения записи командного пакета
      wait until i_cmd_wrdone='1';
      i_hw_mode_stop<='1';

      wait until i_ram_txbuf_done='1';
      write(GUI_line,string'("HW STOP!!!"));writeline(output, GUI_line);

      wait for 10 us;


  end if;--//if cfgCmdPkt(0).usr_ctrl(C_CMDPKT_RAIDCMD_M_BIT downto C_CMDPKT_RAIDCMD_L_BIT)/=CONV_STD_LOGIC_VECTOR(C_RAIDCMD_SW

  wait for 2 us;

  --//Завершаем модеоирование.
  p_SIM_STOP("Simulation of SIMPLE complete");


  wait;
end process lmain_ctrl;
--END MAIN
end;



