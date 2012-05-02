-------------------------------------------------------------------------
-- Company     : Linkos
-- Engineer    : Golovachenko Victor
--
-- Create Date : 24.04.2012 13:38:03
-- Module Name : hdd_main_tb
--
-- Назначение/Описание :
--
-- Revision:
-- Revision 0.01 - File Created
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
use work.video_ctrl_pkg.all;
use work.mem_wr_pkg.all;
use work.mem_ctrl_pkg.all;
use work.prj_cfg.all;
use work.sata_glob_pkg.all;
use work.sata_pkg.all;
use work.sata_raid_pkg.all;
use work.sata_sim_pkg.all;
use work.sata_sim_lite_pkg.all;
use work.sata_unit_pkg.all;
use work.dsn_hdd_reg_def.all;

entity hdd_main_tb is
generic(
G_MEM_AWIDTH  : integer:=32;
G_MEM_DWIDTH  : integer:=64;

G_VOUT_DWIDTH : integer:=16;
G_VSYN_ACTIVE : std_logic:='0';
G_SIM    : string:="ON"
);
port(
p_out_tst : out std_logic
);
end hdd_main_tb;

architecture behavioral of hdd_main_tb is

-- Small delay for simulation purposes.
constant dly : time := 1 ps;

constant G_GT_DBUS     : integer:=C_PCFG_HDD_GT_DBUS;
constant G_DBGCS       : string :=C_PCFG_HDD_DBGCS;
constant G_DBG         : string :=C_PCFG_HDD_DBG;
constant G_HDD_COUNT   : integer:=C_PCFG_HDD_COUNT;
constant G_RAMBUF_SIZE : integer:=C_PCFG_HDD_RAMBUF_SIZE;
constant G_RAID_DWIDTH : integer:=C_PCFG_HDD_RAID_DWIDTH;

constant C_VIN_CLK_PERIOD        : TIME := 9.3 ns;
constant C_VOUT_CLK_PERIOD       : TIME := 6.3 ns;
constant C_SATA_GT_REFCLK_PERIOD : TIME := 6.6 ns;--150MHz

constant CI_MEM_VCTRL   : integer:=C_PCFG_MEMBANK_1;
constant CI_MEM_HDD     : integer:=C_PCFG_MEMBANK_0;


constant CI_HDD_MEMWR_TRN_SIZE : integer:=64;
constant CI_HDD_MEMRD_TRN_SIZE : integer:=64;

constant CI_VCTRL_MEMWR_TRN_SIZE : integer:=64;
constant CI_VCTRL_MEMRD_TRN_SIZE : integer:=64;

constant CI_SECTOR_SIZE_BYTE : integer:=selval(C_SECTOR_SIZE_BYTE, C_SIM_SECTOR_SIZE_DWORD*4, strcmp(G_SIM, "OFF"));

constant C_CFGDEV_COUNT :integer:=1;
constant C_CFGDEV_HDD   :integer:=0;

component vtiming_gen
generic(
G_VSYN_ACTIVE: std_logic:='1';
G_VS_WIDTH   : integer:=32;
G_HS_WIDTH   : integer:=32;
G_PIX_COUNT  : integer:=32;
G_ROW_COUNT  : integer:=32
);
port(
p_out_vs : out  std_logic;
p_out_hs : out  std_logic;

p_in_clk : in   std_logic;
p_in_rst : in   std_logic
);
end component;

component hdd_main
generic(
G_VOUT_DWIDTH : integer:=16;
G_VSYN_ACTIVE : std_logic:='0';
G_SIM         : string:="OFF"
);
port(
--------------------------------------------------
--VideoIN
--------------------------------------------------
p_in_vd             : in   std_logic_vector((10*8)-1 downto 0);
p_in_vin_vs         : in   std_logic;--//Строб кодровой синхронизации
p_in_vin_hs         : in   std_logic;--//Строб строчной синхронизации
p_in_vin_clk        : in   std_logic;--//Пиксельная частота
p_in_ext_syn        : in   std_logic;--//Внешняя синхронизация записи

--------------------------------------------------
--VideoOUT
--------------------------------------------------
p_out_vd            : out  std_logic_vector(G_VOUT_DWIDTH-1 downto 0);
p_in_vout_vs        : in   std_logic;--//Строб кодровой синхронизации
p_in_vout_hs        : in   std_logic;--//Строб строчной синхронизации
p_in_vout_clk       : in   std_logic;--//Пиксельная частота

--------------------------------------------------
--RAM
--------------------------------------------------
p_out_mcb5_a        : out   std_logic_vector(12 downto 0);
p_out_mcb5_ba       : out   std_logic_vector(2 downto 0) ;
p_out_mcb5_ras_n    : out   std_logic;
p_out_mcb5_cas_n    : out   std_logic;
p_out_mcb5_we_n     : out   std_logic;
p_out_mcb5_odt      : out   std_logic;
p_out_mcb5_cke      : out   std_logic;
p_out_mcb5_dm       : out   std_logic;
p_out_mcb5_udm      : out   std_logic;
p_out_mcb5_ck       : out   std_logic;
p_out_mcb5_ck_n     : out   std_logic;
p_inout_mcb5_dq     : inout std_logic_vector(15 downto 0);
p_inout_mcb5_udqs   : inout std_logic;
p_inout_mcb5_udqs_n : inout std_logic;
p_inout_mcb5_dqs    : inout std_logic;
p_inout_mcb5_dqs_n  : inout std_logic;
p_inout_mcb5_rzq    : inout std_logic;
p_inout_mcb5_zio    : inout std_logic;

p_out_mcb1_a        : out   std_logic_vector(12 downto 0);
p_out_mcb1_ba       : out   std_logic_vector(2 downto 0) ;
p_out_mcb1_ras_n    : out   std_logic;
p_out_mcb1_cas_n    : out   std_logic;
p_out_mcb1_we_n     : out   std_logic;
p_out_mcb1_odt      : out   std_logic;
p_out_mcb1_cke      : out   std_logic;
p_out_mcb1_dm       : out   std_logic;
p_out_mcb1_udm      : out   std_logic;
p_out_mcb1_ck       : out   std_logic;
p_out_mcb1_ck_n     : out   std_logic;
p_inout_mcb1_dq     : inout std_logic_vector(15 downto 0);
p_inout_mcb1_udqs   : inout std_logic;
p_inout_mcb1_udqs_n : inout std_logic;
p_inout_mcb1_dqs    : inout std_logic;
p_inout_mcb1_dqs_n  : inout std_logic;
p_inout_mcb1_rzq    : inout std_logic;
p_inout_mcb1_zio    : inout std_logic;

--------------------------------------------------
--SATA
--------------------------------------------------
p_out_sata_txn      : out   std_logic_vector((C_SH_GTCH_COUNT_MAX*C_SH_COUNT_MAX(C_PCFG_HDD_COUNT-1))-1 downto 0);--std_logic_vector(3 downto 0);
p_out_sata_txp      : out   std_logic_vector((C_SH_GTCH_COUNT_MAX*C_SH_COUNT_MAX(C_PCFG_HDD_COUNT-1))-1 downto 0);--std_logic_vector(3 downto 0);
p_in_sata_rxn       : in    std_logic_vector((C_SH_GTCH_COUNT_MAX*C_SH_COUNT_MAX(C_PCFG_HDD_COUNT-1))-1 downto 0);--std_logic_vector(3 downto 0);
p_in_sata_rxp       : in    std_logic_vector((C_SH_GTCH_COUNT_MAX*C_SH_COUNT_MAX(C_PCFG_HDD_COUNT-1))-1 downto 0);--std_logic_vector(3 downto 0);
p_in_sata_clk_n     : in    std_logic_vector(C_SH_COUNT_MAX(C_PCFG_HDD_COUNT-1)-1 downto 0);                      --std_logic_vector(1 downto 0);
p_in_sata_clk_p     : in    std_logic_vector(C_SH_COUNT_MAX(C_PCFG_HDD_COUNT-1)-1 downto 0);                      --std_logic_vector(1 downto 0);

-------------------------------------------------
--Порт управления модулем + Статусы
--------------------------------------------------
--Интерфейс управления модулем
p_in_usr_clk        : in    std_logic;                    --частота тактирования p_in_usr_txd/rxd/tx_wr/rx_rd
p_in_usr_tx_wr      : in    std_logic;                    --строб записи txd
p_in_usr_rx_rd      : in    std_logic;                    --строб чтения rxd
p_in_usr_txd        : in    std_logic_vector(15 downto 0);
p_out_usr_rxd       : out   std_logic_vector(15 downto 0);
p_out_usr_status    : out   std_logic_vector(15 downto 0);

--Статусы модуля
p_out_hdd_rdy       : out   std_logic;--Модуль готов к работе
p_out_hdd_err       : out   std_logic;--Ошибки в работе

--------------------------------------------------
--Sim
--------------------------------------------------
p_out_sim_cfg_clk           : out  std_logic;
p_in_sim_cfg_adr            : in   std_logic_vector(7 downto 0);
p_in_sim_cfg_adr_ld         : in   std_logic;
p_in_sim_cfg_adr_fifo       : in   std_logic;
p_in_sim_cfg_txdata         : in   std_logic_vector(15 downto 0);
p_in_sim_cfg_wd             : in   std_logic;
p_out_sim_cfg_txrdy         : out  std_logic;
p_out_sim_cfg_rxdata        : out  std_logic_vector(15 downto 0);
p_in_sim_cfg_rd             : in   std_logic;
p_out_sim_cfg_rxrdy         : out  std_logic;
p_in_sim_cfg_done           : in   std_logic;
p_in_sim_cfg_rst            : in   std_logic;

p_out_sim_hdd_busy          : out   std_logic;
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

p_out_sim_mem               : out   TMemINBank;
p_in_sim_mem                : in    TMemOUTBank;

--------------------------------------------------
--Технологический порт
--------------------------------------------------
--Интрефейс с USB(FTDI)
p_inout_ftdi_d      : inout std_logic_vector(7 downto 0);
p_out_ftdi_rd_n     : out   std_logic;
p_out_ftdi_wr_n     : out   std_logic;
p_in_ftdi_txe_n     : in    std_logic;
p_in_ftdi_rxf_n     : in    std_logic;
p_in_ftdi_pwren_n   : in    std_logic;

----
--p_in_tst            : in    std_logic_vector(31 downto 0);
--p_out_tst           : out   std_logic_vector(31 downto 0);

p_out_TP            : out   std_logic_vector(7 downto 0); --вывод на контрольные точки платы
p_out_led           : out   std_logic_vector(7 downto 0)  --выход на свтодиоды платы
);
end component;



constant C5_CLK_PERIOD_NS   : real := 6600.0 / 1000.0; --constant C5_CLK_PERIOD_NS   : real := 3200.0 / 1000.0;
constant C5_TCYC_SYS        : real := C5_CLK_PERIOD_NS/2.0;
constant C5_TCYC_SYS_DIV2   : time := C5_TCYC_SYS * 1 ns;

signal i_rst                 : std_logic;
signal p_in_rst              : std_logic;
signal p_in_clk              : std_logic := '0';

signal p_out_phymem          : TMEMCTRL_phy_outs;
signal p_inout_phymem        : TMEMCTRL_phy_inouts;

type TV01 is array(0 to C_MEM_BANK_COUNT-1) of std_logic_vector(1 downto 0) ;
type TV02 is array(0 to C_MEM_BANK_COUNT-1) of std_logic_vector(2 downto 0) ;
signal mcb5_dram_dqs_vector  : TV01;
signal mcb5_dram_dqs_n_vector: TV01;
signal mcb5_dram_dm_vector   : TV01;
signal mcb5_command          : TV02;
signal mcb5_enable1          : std_logic_vector(C_MEM_BANK_COUNT-1 downto 0);
signal mcb5_enable2          : std_logic_vector(C_MEM_BANK_COUNT-1 downto 0);
signal rzq5                  : std_logic_vector(C_MEM_BANK_COUNT-1 downto 0);
signal zio5                  : std_logic_vector(C_MEM_BANK_COUNT-1 downto 0);


signal i_tst_mode                 : std_logic;
--signal i_tst_cmd                  : integer;
signal i_sw_mode                  : std_logic;
signal i_sata_cs                  : integer;
signal i_hw_mode_stop             : std_logic;
signal i_hm_r  : std_logic:='0';

signal i_tstdata_dwsize               : integer:=0;
signal i_loopback                     : std_logic;
signal i_dsn_hdd_rst                  : std_logic;

signal i_hdd_rdy                      : std_logic;
signal i_hdd_busy                     : std_logic;

signal sr_cmdbusy                     : std_logic_vector(0 to 1);
signal i_cmddone_det_clr              : std_logic:='0';
signal i_cmddone_det                  : std_logic:='0';
signal i_cmd_data                     : TUsrAppCmdPkt;

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

signal i_sata_txn                     : std_logic_vector((C_GTCH_COUNT_MAX*C_SH_COUNT_MAX(G_HDD_COUNT-1))-1 downto 0);
signal i_sata_txp                     : std_logic_vector((C_GTCH_COUNT_MAX*C_SH_COUNT_MAX(G_HDD_COUNT-1))-1 downto 0);
signal i_sata_rxn                     : std_logic_vector((C_GTCH_COUNT_MAX*C_SH_COUNT_MAX(G_HDD_COUNT-1))-1 downto 0);
signal i_sata_rxp                     : std_logic_vector((C_GTCH_COUNT_MAX*C_SH_COUNT_MAX(G_HDD_COUNT-1))-1 downto 0);
signal i_sataclk_p                    : std_logic_vector((C_SH_COUNT_MAX(G_HDD_COUNT-1))-1 downto 0);
signal i_sataclk_n                    : std_logic_vector((C_SH_COUNT_MAX(G_HDD_COUNT-1))-1 downto 0);
signal i_sata_gt_refclkmain           : std_logic_vector((C_SH_COUNT_MAX(G_HDD_COUNT-1))-1 downto 0);

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


signal i_cfgdev_if                : std_logic;
signal i_cfgdev_if_tst            : std_logic;
signal g_cfg_clk                  : std_logic;
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

signal i_dsnhdd_reg_ctrl_l_val      : std_logic_vector(15 downto 0);
signal i_dsnhdd_reg_ctrl_m_val      : std_logic_vector(15 downto 0);
signal i_dsnhdd_reg_hwstart_dly_val: std_logic_vector(15 downto 0);

type TSimRAM is array (0 to 6128) of std_logic_vector(G_MEM_DWIDTH downto 0);
type TSimRAMBanks is array (0 to 1) of TSimRAM;
signal i_ram_rd_fst                       : std_logic_vector(1 downto 0);
--signal i_ram_txbuf                    : TSimRAM;
signal i_ram_txbuf_start              : std_logic:='0';
signal i_testdata_sel                 : std_logic:='0';
--signal i_ram_rxbuf                    : TSimRAMBanks;
signal i_ram_rxbuf_start              : std_logic:='0';
signal i_ram                          : TSimRAMBanks;
--signal i_ram_cntwr                    : integer range 0 to 6128;
--signal i_ram_cntrd                    : integer range 0 to 6128;

type TSimRAMdcnfwr is array (0 to 1) of integer;
signal i_ram_cntwr                    : TSimRAMdcnfwr;
signal i_ram_cntrd                    : TSimRAMdcnfwr;

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

signal i_ltrn_count0                  : std_logic;
signal i_ltrn_count1                  : std_logic;

signal i_sim_mem_in                   : TMemINBank;
signal i_sim_mem_out                  : TMemOUTBank;

type TDtest   is array(0 to 9) of std_logic_vector(7 downto 0);
signal i_tdata                        : TDtest;
signal i_vin_d                        : std_logic_vector(79 downto 0):=(others=>'0');
signal i_vin_vs                       : std_logic;
signal i_vin_hs                       : std_logic;
signal i_vin_clk                      : std_logic;

signal i_vout_vs                      : std_logic;
signal i_vout_hs                      : std_logic;
signal i_vout_clk                     : std_logic;



--MAIN
begin

-- ==========================================================================
-- Clocks/Reset Generation
-- ==========================================================================
process
begin
  p_in_clk <= not p_in_clk;
  wait for (C5_TCYC_SYS_DIV2);
end process;

gen_sata_clk : for i in 0 to C_SH_COUNT_MAX(C_PCFG_HDD_COUNT-1)-1 generate
gen_clk_sata : process
begin
  i_sata_gt_refclkmain(i)<='0';
  wait for C_SATA_GT_REFCLK_PERIOD/2;
  i_sata_gt_refclkmain(i)<='1';
  wait for C_SATA_GT_REFCLK_PERIOD/2;
end process;

i_sataclk_p(i)<=    i_sata_gt_refclkmain(i);
i_sataclk_n(i)<=not i_sata_gt_refclkmain(i);
end generate gen_sata_clk;


gen_vin_clk : process
begin
  i_vin_clk<='0';
  wait for C_VIN_CLK_PERIOD/2;
  i_vin_clk<='1';
  wait for C_VIN_CLK_PERIOD/2;
end process;

gen_vout_clk : process
begin
  i_vout_clk<='0';
  wait for C_VOUT_CLK_PERIOD/2;
  i_vout_clk<='1';
  wait for C_VOUT_CLK_PERIOD/2;
end process;

p_in_rst <= '1','0' after 3 us;
i_dsn_hdd_rst<=p_in_rst;



-- ==========================================================================
--
-- ==========================================================================
--Генератор тестовых данных (Вертикальные полоски!!!)
gen_vd : for i in 1 to 10 generate
process(p_in_rst,i_vin_clk)
begin
  if p_in_rst='1' then
    i_tdata(i-1)<=CONV_STD_LOGIC_VECTOR(i, i_tdata(i-1)'length);
  elsif i_vin_clk'event and i_vin_clk='1' then
    if i_vin_vs=G_VSYN_ACTIVE or i_vin_hs=G_VSYN_ACTIVE then
      i_tdata(i-1)<=CONV_STD_LOGIC_VECTOR(i-1, i_tdata(i-1)'length);
    else
      i_tdata(i-1)<=i_tdata(i-1) + CONV_STD_LOGIC_VECTOR(10, i_tdata(i-1)'length);
    end if;
  end if;
end process;

i_vin_d((8*i)-1 downto (8*i)-8)<=i_tdata(i-1);
end generate gen_vd;

m_vtgen_high : vtiming_gen
generic map(
G_VSYN_ACTIVE=> G_VSYN_ACTIVE,
G_VS_WIDTH   => 32,
G_HS_WIDTH   => 16,
G_PIX_COUNT  => (C_PCFG_FRPIX/10),
G_ROW_COUNT  => C_PCFG_FRROW
)
port map(
p_out_vs => i_vin_vs,
p_out_hs => i_vin_hs,

p_in_clk => i_vin_clk,
p_in_rst => p_in_rst
);

m_vtgen_low : vtiming_gen
generic map(
G_VSYN_ACTIVE=> G_VSYN_ACTIVE,
G_VS_WIDTH   => 32,
G_HS_WIDTH   => 8,
G_PIX_COUNT  => (C_PCFG_FRPIX/(G_VOUT_DWIDTH/8)),
G_ROW_COUNT  => C_PCFG_FRROW
)
port map(
p_out_vs => i_vout_vs,
p_out_hs => i_vout_hs,

p_in_clk => i_vout_clk,
p_in_rst => p_in_rst
);

m_hdd : hdd_main
generic map(
G_VOUT_DWIDTH => G_VOUT_DWIDTH,
G_VSYN_ACTIVE => G_VSYN_ACTIVE,
G_SIM => G_SIM
)
port map(
--------------------------------------------------
--VideoIN
--------------------------------------------------
p_in_vd             => i_vin_d,
p_in_vin_vs         => i_vin_vs,--tst_in(0),--
p_in_vin_hs         => i_vin_hs,--tst_in(1),--
p_in_vin_clk        => i_vin_clk,
p_in_ext_syn        => '1',

--------------------------------------------------
--VideoOUT
--------------------------------------------------
p_out_vd            => open,
p_in_vout_vs        => i_vout_vs,
p_in_vout_hs        => i_vout_hs,
p_in_vout_clk       => i_vout_clk,

--------------------------------------------------
--RAM
--------------------------------------------------
p_out_mcb5_a        => open,--p_out_phymem  (1).a     ,
p_out_mcb5_ba       => open,--p_out_phymem  (1).ba    ,
p_out_mcb5_ras_n    => open,--p_out_phymem  (1).ras_n ,
p_out_mcb5_cas_n    => open,--p_out_phymem  (1).cas_n ,
p_out_mcb5_we_n     => open,--p_out_phymem  (1).we_n  ,
p_out_mcb5_odt      => open,--p_out_phymem  (1).odt   ,
p_out_mcb5_cke      => open,--p_out_phymem  (1).cke   ,
p_out_mcb5_dm       => open,--p_out_phymem  (1).dm    ,
p_out_mcb5_udm      => open,--p_out_phymem  (1).udm   ,
p_out_mcb5_ck       => open,--p_out_phymem  (1).ck    ,
p_out_mcb5_ck_n     => open,--p_out_phymem  (1).ck_n  ,
p_inout_mcb5_dq     => open,--p_inout_phymem(1).dq    ,
p_inout_mcb5_udqs   => open,--p_inout_phymem(1).udqs  ,
p_inout_mcb5_udqs_n => open,--p_inout_phymem(1).udqs_n,
p_inout_mcb5_dqs    => open,--p_inout_phymem(1).dqs   ,
p_inout_mcb5_dqs_n  => open,--p_inout_phymem(1).dqs_n ,
p_inout_mcb5_rzq    => open,--p_inout_phymem(1).rzq   ,
p_inout_mcb5_zio    => open,--p_inout_phymem(1).zio   ,

p_out_mcb1_a        => open,--p_out_phymem  (0).a     ,
p_out_mcb1_ba       => open,--p_out_phymem  (0).ba    ,
p_out_mcb1_ras_n    => open,--p_out_phymem  (0).ras_n ,
p_out_mcb1_cas_n    => open,--p_out_phymem  (0).cas_n ,
p_out_mcb1_we_n     => open,--p_out_phymem  (0).we_n  ,
p_out_mcb1_odt      => open,--p_out_phymem  (0).odt   ,
p_out_mcb1_cke      => open,--p_out_phymem  (0).cke   ,
p_out_mcb1_dm       => open,--p_out_phymem  (0).dm    ,
p_out_mcb1_udm      => open,--p_out_phymem  (0).udm   ,
p_out_mcb1_ck       => open,--p_out_phymem  (0).ck    ,
p_out_mcb1_ck_n     => open,--p_out_phymem  (0).ck_n  ,
p_inout_mcb1_dq     => open,--p_inout_phymem(0).dq    ,
p_inout_mcb1_udqs   => open,--p_inout_phymem(0).udqs  ,
p_inout_mcb1_udqs_n => open,--p_inout_phymem(0).udqs_n,
p_inout_mcb1_dqs    => open,--p_inout_phymem(0).dqs   ,
p_inout_mcb1_dqs_n  => open,--p_inout_phymem(0).dqs_n ,
p_inout_mcb1_rzq    => open,--p_inout_phymem(0).rzq   ,
p_inout_mcb1_zio    => open,--p_inout_phymem(0).zio   ,

--------------------------------------------------
--SATA
--------------------------------------------------
p_out_sata_txn   => i_sata_txn,
p_out_sata_txp   => i_sata_txp,
p_in_sata_rxn    => i_sata_rxn,
p_in_sata_rxp    => i_sata_rxp,
p_in_sata_clk_n  => i_sataclk_p,
p_in_sata_clk_p  => i_sataclk_n,

-------------------------------------------------
--Порт управления модулем + Статусы
--------------------------------------------------
--Интерфейс управления модулем
p_in_usr_clk        => '0',
p_in_usr_tx_wr      => '0',
p_in_usr_rx_rd      => '0',
p_in_usr_txd        => (others=>'0'),
p_out_usr_rxd       => open,
p_out_usr_status    => open,

--Статусы модуля
p_out_hdd_rdy       => i_hdd_rdy,
p_out_hdd_err       => open,

--------------------------------------------------
--Sim
--------------------------------------------------
p_out_sim_cfg_clk           => g_cfg_clk,
p_in_sim_cfg_adr            => i_cfgdev_adr,
p_in_sim_cfg_adr_ld         => i_cfgdev_adr_ld,
p_in_sim_cfg_adr_fifo       => i_cfgdev_adr_fifo,
p_in_sim_cfg_txdata         => i_cfgdev_txdata,
p_in_sim_cfg_wd             => i_dev_cfg_wd(C_CFGDEV_HDD),
p_out_sim_cfg_txrdy         => i_cfgdev_txrdy,
p_out_sim_cfg_rxdata        => i_cfgdev_rxdata,
p_in_sim_cfg_rd             => i_dev_cfg_rd(C_CFGDEV_HDD),
p_out_sim_cfg_rxrdy         => i_cfgdev_rxrdy,
p_in_sim_cfg_done           => i_dev_cfg_done(C_CFGDEV_HDD),
p_in_sim_cfg_rst            => i_dsn_hdd_rst,-- i_cfgdev_rst,

p_out_sim_hdd_busy          => i_hdd_busy,
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

p_out_sim_mem               => i_sim_mem_in,
p_in_sim_mem                => i_sim_mem_out,

--------------------------------------------------
--Технологический порт
--------------------------------------------------
p_inout_ftdi_d   => open,
p_out_ftdi_rd_n  => open,
p_out_ftdi_wr_n  => open,
p_in_ftdi_txe_n  => '1',
p_in_ftdi_rxf_n  => '1',
p_in_ftdi_pwren_n=> '1',

p_out_TP         => open,
p_out_led        => open
);



--gen_bank : for i in 0 to C_MEM_BANK_COUNT-1 generate
---- ========================================================================== --
---- Memory model instances                                                     --
---- ========================================================================== --
---- The PULLDOWN component is connected to the ZIO signal primarily to avoid the
---- unknown state in simulation. In real hardware, ZIO should be a no connect(NC) pin.
--
--mcb5_command(i) <= (p_out_phymem(i).ras_n & p_out_phymem(i).cas_n & p_out_phymem(i).we_n);
--
--process(p_out_phymem(i).ck)--mcb5_dram_ck)
--begin
--  if (rising_edge(p_out_phymem(i).ck)) then --if (rising_edge(mcb5_dram_ck)) then
--    if (i_rst = '0') then
--      mcb5_enable1(i) <= '0';
--      mcb5_enable2(i) <= '0';
--    elsif (mcb5_command(i) = "100") then
--      mcb5_enable2(i) <= '0';
--    elsif (mcb5_command(i) = "101") then
--      mcb5_enable2(i) <= '1';
--    else
--      mcb5_enable2(i) <= mcb5_enable2(i);
--    end if;
--    mcb5_enable1(i)   <= mcb5_enable2(i);
--  end if;
--end process;
--
-------------------------------------------------------------------------------
----read
-------------------------------------------------------------------------------
--mcb5_dram_dqs_vector(i)(1 downto 0)  <= (p_inout_phymem(i).udqs & p_inout_phymem(i).dqs)     when (mcb5_enable2(i) = '0' and mcb5_enable1(i) = '0') else "ZZ";
--mcb5_dram_dqs_n_vector(i)(1 downto 0)<= (p_inout_phymem(i).udqs_n & p_inout_phymem(i).dqs_n) when (mcb5_enable2(i) = '0' and mcb5_enable1(i) = '0') else "ZZ";
--
-------------------------------------------------------------------------------
----write
-------------------------------------------------------------------------------
--p_inout_phymem(i).dqs    <= mcb5_dram_dqs_vector(i)(0)   when (mcb5_enable1(i) = '1') else 'Z';
--p_inout_phymem(i).udqs   <= mcb5_dram_dqs_vector(i)(1)   when (mcb5_enable1(i) = '1') else 'Z';
--p_inout_phymem(i).dqs_n  <= mcb5_dram_dqs_n_vector(i)(0) when (mcb5_enable1(i) = '1') else 'Z';
--p_inout_phymem(i).udqs_n <= mcb5_dram_dqs_n_vector(i)(1) when (mcb5_enable1(i) = '1') else 'Z';
--
--mcb5_dram_dm_vector(i) <= (p_out_phymem(i).udm & p_out_phymem(i).dm);
--
--u_mem_c5 : ddr2_model_c5
--port map(
--ck        => p_out_phymem(i).ck,    --mcb5_dram_ck,
--ck_n      => p_out_phymem(i).ck_n,  --mcb5_dram_ck_n,
--cke       => p_out_phymem(i).cke,   --mcb5_dram_cke,
--cs_n      => '0',
--ras_n     => p_out_phymem(i).ras_n, --mcb5_dram_ras_n,
--cas_n     => p_out_phymem(i).cas_n, --mcb5_dram_cas_n,
--we_n      => p_out_phymem(i).we_n,  --mcb5_dram_we_n,
--dm_rdqs   => mcb5_dram_dm_vector(i),
--ba        => p_out_phymem(i).ba,    --mcb5_dram_ba,
--addr      => p_out_phymem(i).a,     --mcb5_dram_a,
--dq        => p_inout_phymem(i).dq,  --mcb5_dram_dq,
--dqs       => mcb5_dram_dqs_vector(i),
--dqs_n     => mcb5_dram_dqs_n_vector(i),
--rdqs_n    => open,
--odt       => p_out_phymem(i).odt    --mcb5_dram_odt
--);
--
--zio_pulldown5 : PULLDOWN port map(O => p_inout_phymem(i).zio);--zio5);
--rzq_pulldown5 : PULLDOWN port map(O => p_inout_phymem(i).rzq);--rzq5);
--
--end generate gen_bank;


--//--------------------------------
--//Эмуляция HDD
--//--------------------------------
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
p_in_tst                 => "00000000000000000000000000000000",
p_out_tst                => open,

----------------------------
--System
----------------------------
p_in_clk                 => i_hdd_sim_gt_clk(i),
p_in_rst                 => i_hdd_sim_gt_rst(i)
);
end generate gen_satad;

--//Выделяем задний фронт из сигнала BUSY модуля m_sata_host.
--//Для детектированя завершения АТА команды
process(i_dsn_hdd_rst,p_in_clk)
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
end process;

process
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


p_out_tst<='1' when i_ram_cntrd(CI_MEM_HDD)=2 else '0';

--//########################################
--//ОЗУ : HDD
--//########################################
i_sim_mem_out(CI_MEM_HDD)(C_MEMCH_WR).req_en      <='1';
i_sim_mem_out(CI_MEM_HDD)(C_MEMCH_WR).cmdbuf_full <='0';
--i_sim_mem_out(CI_MEM_HDD)(C_MEMCH_WR).txbuf_full  <='0';
i_sim_mem_out(CI_MEM_HDD)(C_MEMCH_WR).rxbuf_empty <='0';

i_sim_mem_out(CI_MEM_HDD)(C_MEMCH_RD).req_en      <='1';
i_sim_mem_out(CI_MEM_HDD)(C_MEMCH_RD).cmdbuf_full <='0';
i_sim_mem_out(CI_MEM_HDD)(C_MEMCH_RD).txbuf_full  <='0';
i_sim_mem_out(CI_MEM_HDD)(C_MEMCH_RD).txbuf_empty <='0';

-------------------------------------
--Запись данных в ОЗУ : HDD
-------------------------------------
process
begin
  i_sim_mem_out(CI_MEM_HDD)(C_MEMCH_WR).txbuf_full<='0';

  wait until i_ram_cntwr(CI_MEM_HDD)=16#0E# and i_sim_mem_in(CI_MEM_HDD)(C_MEMCH_WR).clk'event and i_sim_mem_in(CI_MEM_HDD)(C_MEMCH_WR).clk='1';
    i_sim_mem_out(CI_MEM_HDD)(C_MEMCH_WR).txbuf_full<='1';
  wait for 200 ns;

  wait until  i_sim_mem_in(CI_MEM_HDD)(C_MEMCH_WR).clk'event and i_sim_mem_in(CI_MEM_HDD)(C_MEMCH_WR).clk='1';
    i_sim_mem_out(CI_MEM_HDD)(C_MEMCH_WR).txbuf_full<='0';

  wait;
end process;

process(i_hdd_rdy,i_sim_mem_in(CI_MEM_HDD)(C_MEMCH_WR).clk)
  variable dcnt : integer:=0;
begin
  if i_hdd_rdy='0' then
    for i in 0 to i_ram(CI_MEM_HDD)'high loop
    i_ram(CI_MEM_HDD)(i)<=(others=>'0');
    end loop;
    dcnt:=0;
    i_ram_cntwr(CI_MEM_HDD)<=0;
    i_sim_mem_out(CI_MEM_HDD)(C_MEMCH_WR).txbuf_empty <='1';

  elsif i_sim_mem_in(CI_MEM_HDD)(C_MEMCH_WR).clk'event and i_sim_mem_in(CI_MEM_HDD)(C_MEMCH_WR).clk='1' then

    if i_sim_mem_in(CI_MEM_HDD)(C_MEMCH_WR).txd_wr='1' then

        i_ram(CI_MEM_HDD)(dcnt)(G_MEM_DWIDTH - 1 downto 0)<=i_sim_mem_in(CI_MEM_HDD)(C_MEMCH_WR).txd(G_MEM_DWIDTH - 1 downto 0);-- after dly;

        if dcnt=i_ram(CI_MEM_HDD)'length-1 then
          dcnt:=0;
        else
          dcnt:=dcnt + 1;
        end if;

        i_sim_mem_out(CI_MEM_HDD)(C_MEMCH_WR).txbuf_empty <='0';
    end if;

    i_ram_cntwr(CI_MEM_HDD)<=dcnt;

  end if;
end process;


-------------------------------------
--Чтение данных ОЗУ : HDD
-------------------------------------
process
  variable dcnt : integer:=0;
  variable mem_trnlen : integer:=0;
begin
  i_sim_mem_out(CI_MEM_HDD)(C_MEMCH_RD).rxbuf_empty<='1';
  i_ram_cntrd(CI_MEM_HDD)<=dcnt;
  i_ram_rd_fst(CI_MEM_HDD)<='1';

  wait until i_hdd_rdy='1' and i_sim_mem_in(CI_MEM_HDD)(C_MEMCH_RD).clk'event and i_sim_mem_in(CI_MEM_HDD)(C_MEMCH_RD).clk='1';

    i_sim_mem_out(CI_MEM_HDD)(C_MEMCH_RD).rxd(G_MEM_DWIDTH - 1 downto 0)<=i_ram(CI_MEM_HDD)(0)(G_MEM_DWIDTH - 1 downto 0);
    i_sim_mem_out(CI_MEM_HDD)(C_MEMCH_RD).rxbuf_empty<='1';
      mem_trnlen:=0;
      dcnt:=0;

  while true loop

      wait until i_sim_mem_in(CI_MEM_HDD)(C_MEMCH_RD).cmd_wr='1' and i_sim_mem_in(CI_MEM_HDD)(C_MEMCH_RD).clk'event and i_sim_mem_in(CI_MEM_HDD)(C_MEMCH_RD).clk='1';

      if i_ram_rd_fst(CI_MEM_HDD)='1' then
          i_sim_mem_out(CI_MEM_HDD)(C_MEMCH_RD).rxd(G_MEM_DWIDTH - 1 downto 0)<=i_ram(CI_MEM_HDD)(dcnt)(G_MEM_DWIDTH - 1 downto 0);
          if dcnt=i_ram(CI_MEM_HDD)'length-1 then
            dcnt:=0;
          else
            dcnt:=dcnt + 1;
          end if;
          i_ram_rd_fst(CI_MEM_HDD)<='0';
      end if;
      i_ram_cntrd(CI_MEM_HDD)<=dcnt;

      wait until i_sim_mem_in(CI_MEM_HDD)(C_MEMCH_RD).clk'event and i_sim_mem_in(CI_MEM_HDD)(C_MEMCH_RD).clk='1';

      i_sim_mem_out(CI_MEM_HDD)(C_MEMCH_RD).rxbuf_empty<='0';

      while mem_trnlen/=CI_HDD_MEMRD_TRN_SIZE loop

          wait until i_sim_mem_in(CI_MEM_HDD)(C_MEMCH_RD).clk'event and i_sim_mem_in(CI_MEM_HDD)(C_MEMCH_RD).clk='1';

          if i_sim_mem_in(CI_MEM_HDD)(C_MEMCH_RD).rxd_rd='1' then

            i_sim_mem_out(CI_MEM_HDD)(C_MEMCH_RD).rxd(G_MEM_DWIDTH - 1 downto 0)<=i_ram(CI_MEM_HDD)(dcnt)(G_MEM_DWIDTH - 1 downto 0);
            if dcnt=i_ram(CI_MEM_HDD)'length-1 then
              dcnt:=0;
            else
              dcnt:=dcnt + 1;
            end if;

            mem_trnlen:=mem_trnlen + 1;
            i_ram_cntrd(CI_MEM_HDD)<=dcnt;
          end if;
      end loop;--//mem_trnlen/=CI_HDD_MEMRD_TRN_SIZE

      i_sim_mem_out(CI_MEM_HDD)(C_MEMCH_RD).rxbuf_empty<='1';
        mem_trnlen:=0;

  end loop;--//while true loop

  wait;
end process;



--//########################################
--//ОЗУ : VCTRL
--//########################################
i_sim_mem_out(CI_MEM_VCTRL)(C_MEMCH_WR).req_en      <='1';
i_sim_mem_out(CI_MEM_VCTRL)(C_MEMCH_WR).cmdbuf_full <='0';
--i_sim_mem_out(CI_MEM_VCTRL)(C_MEMCH_WR).txbuf_full  <='0';
i_sim_mem_out(CI_MEM_VCTRL)(C_MEMCH_WR).rxbuf_empty <='0';

i_sim_mem_out(CI_MEM_VCTRL)(C_MEMCH_RD).req_en      <='1';
i_sim_mem_out(CI_MEM_VCTRL)(C_MEMCH_RD).cmdbuf_full <='0';
i_sim_mem_out(CI_MEM_VCTRL)(C_MEMCH_RD).txbuf_full  <='0';
i_sim_mem_out(CI_MEM_VCTRL)(C_MEMCH_RD).txbuf_empty <='0';

-------------------------------------
--Запись данных в ОЗУ : VCTRL
-------------------------------------
process
begin
  i_sim_mem_out(CI_MEM_VCTRL)(C_MEMCH_WR).txbuf_full<='0';

  wait until i_ram_cntwr(CI_MEM_VCTRL)=16#12# and i_sim_mem_in(CI_MEM_VCTRL)(C_MEMCH_WR).clk'event and i_sim_mem_in(CI_MEM_VCTRL)(C_MEMCH_WR).clk='1';
    i_sim_mem_out(CI_MEM_VCTRL)(C_MEMCH_WR).txbuf_full<='1';
  wait for 200 ns;

  wait until  i_sim_mem_in(CI_MEM_VCTRL)(C_MEMCH_WR).clk'event and i_sim_mem_in(CI_MEM_VCTRL)(C_MEMCH_WR).clk='1';
    i_sim_mem_out(CI_MEM_VCTRL)(C_MEMCH_WR).txbuf_full<='0';

  wait;
end process;

process(i_hdd_rdy,i_sim_mem_in(CI_MEM_VCTRL)(C_MEMCH_WR).clk)
  variable dcnt : integer:=0;
begin
  if i_hdd_rdy='0' then
    for i in 0 to i_ram(CI_MEM_VCTRL)'high loop
    i_ram(CI_MEM_VCTRL)(i)<=(others=>'0');
    end loop;
    dcnt:=0;
    i_ram_cntwr(CI_MEM_VCTRL)<=0;
    i_sim_mem_out(CI_MEM_VCTRL)(C_MEMCH_WR).txbuf_empty <='1';

  elsif i_sim_mem_in(CI_MEM_VCTRL)(C_MEMCH_WR).clk'event and i_sim_mem_in(CI_MEM_VCTRL)(C_MEMCH_WR).clk='1' then

    if i_sim_mem_in(CI_MEM_VCTRL)(C_MEMCH_WR).txd_wr='1' then

        i_ram(CI_MEM_VCTRL)(dcnt)(G_MEM_DWIDTH - 1 downto 0)<=i_sim_mem_in(CI_MEM_VCTRL)(C_MEMCH_WR).txd(G_MEM_DWIDTH - 1 downto 0);

        if dcnt=i_ram(CI_MEM_VCTRL)'length-1 then
          dcnt:=0;
        else
          dcnt:=dcnt + 1;
        end if;

        i_sim_mem_out(CI_MEM_VCTRL)(C_MEMCH_WR).txbuf_empty <='0';
    end if;

    i_ram_cntwr(CI_MEM_VCTRL)<=dcnt;

  end if;
end process;


-------------------------------------
--Чтение данных ОЗУ : VCTRL
-------------------------------------
process
  variable dcnt : integer:=0;
  variable mem_trnlen : integer:=0;
begin

  i_sim_mem_out(CI_MEM_VCTRL)(C_MEMCH_RD).rxbuf_empty<='1';
  i_ram_cntrd(CI_MEM_VCTRL)<=0;

  wait until i_hdd_rdy='1' and i_sim_mem_in(CI_MEM_VCTRL)(C_MEMCH_RD).clk'event and i_sim_mem_in(CI_MEM_VCTRL)(C_MEMCH_RD).clk='1';

    i_sim_mem_out(CI_MEM_VCTRL)(C_MEMCH_RD).rxd(G_MEM_DWIDTH - 1 downto 0)<=i_ram(CI_MEM_VCTRL)(0)(G_MEM_DWIDTH - 1 downto 0);
    i_sim_mem_out(CI_MEM_VCTRL)(C_MEMCH_RD).rxbuf_empty<='1';
      mem_trnlen:=0;
      dcnt:=0;

  while true loop

      i_sim_mem_out(CI_MEM_VCTRL)(C_MEMCH_RD).rxd(G_MEM_DWIDTH - 1 downto 0)<=i_ram(CI_MEM_VCTRL)(dcnt)(G_MEM_DWIDTH - 1 downto 0);

      wait until i_sim_mem_in(CI_MEM_VCTRL)(C_MEMCH_RD).cmd_wr='1' and i_sim_mem_in(CI_MEM_VCTRL)(C_MEMCH_RD).clk'event and i_sim_mem_in(CI_MEM_VCTRL)(C_MEMCH_RD).clk='1';
      i_sim_mem_out(CI_MEM_VCTRL)(C_MEMCH_RD).rxd(G_MEM_DWIDTH - 1 downto 0)<=i_ram(CI_MEM_VCTRL)(dcnt)(G_MEM_DWIDTH - 1 downto 0);

      wait until i_sim_mem_in(CI_MEM_VCTRL)(C_MEMCH_RD).clk'event and i_sim_mem_in(CI_MEM_VCTRL)(C_MEMCH_RD).clk='1';

      i_sim_mem_out(CI_MEM_VCTRL)(C_MEMCH_RD).rxd(G_MEM_DWIDTH - 1 downto 0)<=i_ram(CI_MEM_VCTRL)(dcnt)(G_MEM_DWIDTH - 1 downto 0);
      i_sim_mem_out(CI_MEM_VCTRL)(C_MEMCH_RD).rxbuf_empty<='0';

      while mem_trnlen/=CI_VCTRL_MEMRD_TRN_SIZE loop

          wait until i_sim_mem_in(CI_MEM_VCTRL)(C_MEMCH_RD).clk'event and i_sim_mem_in(CI_MEM_VCTRL)(C_MEMCH_RD).clk='1';

          if i_sim_mem_in(CI_MEM_VCTRL)(C_MEMCH_RD).rxd_rd='1' then

            i_sim_mem_out(CI_MEM_VCTRL)(C_MEMCH_RD).rxd(G_MEM_DWIDTH - 1 downto 0)<=i_ram(CI_MEM_VCTRL)(dcnt)(G_MEM_DWIDTH - 1 downto 0);
            if dcnt=i_ram(CI_MEM_VCTRL)'length-1 then
              dcnt:=0;
            else
              dcnt:=dcnt + 1;
            end if;

            mem_trnlen:=mem_trnlen + 1;
            i_ram_cntrd(CI_MEM_VCTRL)<=dcnt;
          end if;
      end loop;--//mem_trnlen/=CI_VCTRL_MEMRD_TRN_SIZE loop

      i_sim_mem_out(CI_MEM_VCTRL)(C_MEMCH_RD).rxbuf_empty<='1';
        mem_trnlen:=0;

  end loop;--//while true loop

  wait;
end process;





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

  --//---------------------------------------------------
  --/Настраиваем Параметры моделирования:
  --//---------------------------------------------------
  --//настройка RAMBUF: направление RAM->HDD
----  memwr_lentrn_byte:=CONV_STD_LOGIC_VECTOR(CI_SECTOR_SIZE_BYTE, memwr_lentrn_byte'length);
--  memwr_lentrn_byte:=CONV_STD_LOGIC_VECTOR(64, memwr_lentrn_byte'length);
--  memwr_lentrn_dw:=("00"&memwr_lentrn_byte(memwr_lentrn_byte'high downto 2));
  memwr_lentrn_dw:=CONV_STD_LOGIC_VECTOR(CI_HDD_MEMWR_TRN_SIZE, memwr_lentrn_dw'length);

  --//настройка RAMBUF: направление RAM<-HDD
----  memrd_lentrn_byte:=CONV_STD_LOGIC_VECTOR(CI_SECTOR_SIZE_BYTE, memrd_lentrn_byte'length);
--  memrd_lentrn_byte:=CONV_STD_LOGIC_VECTOR(64, memrd_lentrn_byte'length);
--  memrd_lentrn_dw:=("00"&memrd_lentrn_byte(memrd_lentrn_byte'high downto 2));
  memrd_lentrn_dw:=CONV_STD_LOGIC_VECTOR(CI_HDD_MEMRD_TRN_SIZE, memrd_lentrn_dw'length);

  --//Выбор режима:
  --C_ATA_CMD_WRITE_SECTORS_EXT;--C_ATA_CMD_WRITE_DMA_EXT;--C_ATA_CMD_READ_SECTORS_EXT;--
  i_testdata_sel<='0'; --//0/1 - Счетчик/Random DATA
  i_sw_mode <='0';--//1/0 - sw_mode/hw_mode
  i_tst_mode<='0';--//режим тестирования
  raid_mode:='1';
--  mnl_sata_cs:=16#03#; --//Только когда выключен режим raid_mode
  i_sata_cs<=16#0F#;--16#03#;

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

  i_dsnhdd_reg_ctrl_m_val<=(others=>'0');
  i_dsnhdd_reg_ctrl_m_val(C_HDD_REG_CTRLM_VCH_EN_BIT)<='1';

  i_dsnhdd_reg_ctrl_l_val<=(others=>'0');
  i_dsnhdd_reg_ctrl_l_val(C_HDD_REG_CTRLL_TST_ON_BIT)<='1';
  i_dsnhdd_reg_ctrl_l_val(C_HDD_REG_CTRLL_TST_GEN2RAMBUF_BIT)<='1';
  i_dsnhdd_reg_ctrl_l_val(C_HDD_REG_CTRLL_ERR_STREMBUF_DIS_BIT)<='0'; --1/0 -Disable/Enable
  i_dsnhdd_reg_ctrl_l_val(C_HDD_REG_CTRLL_HWLOG_ON_BIT)<='0';
  i_dsnhdd_reg_ctrl_l_val(C_HDD_REG_CTRLL_TST_GEND0_BIT)<='1';
--  i_dsnhdd_reg_ctrl_l_val(C_HDD_REG_CTRLL_HWSTART_DLY_ON_BIT)<='0';
  i_dsnhdd_reg_ctrl_l_val(C_HDD_REG_CTRLL_DBGLED_OFF_BIT)<='0';
  --//1- min ... 256/0 - max
--  i_dsnhdd_reg_ctrl_l_val(C_HDD_REG_CTRLL_TST_SPD_M_BIT downto C_HDD_REG_CTRLL_TST_SPD_L_BIT)<=CONV_STD_LOGIC_VECTOR(((2**(C_HDD_REG_CTRLL_TST_SPD_M_BIT-C_HDD_REG_CTRLL_TST_SPD_L_BIT+1))*100)/128, C_HDD_REG_CTRLL_TST_SPD_M_BIT-C_HDD_REG_CTRLL_TST_SPD_L_BIT+1);
  i_dsnhdd_reg_ctrl_l_val(C_HDD_REG_CTRLL_TST_SPD_M_BIT downto C_HDD_REG_CTRLL_TST_SPD_L_BIT)<=CONV_STD_LOGIC_VECTOR(250, C_HDD_REG_CTRLL_TST_SPD_M_BIT-C_HDD_REG_CTRLL_TST_SPD_L_BIT+1);

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


  wait until g_cfg_clk'event and g_cfg_clk='1';
    i_cfgdev_adr<=CONV_STD_LOGIC_VECTOR(C_HDD_REG_CTRL_M, i_cfgdev_adr'length);
    i_cfgdev_adr_ld<='1';
    i_cfgdev_adr_fifo<='0';
  wait until g_cfg_clk'event and g_cfg_clk='1';
    i_cfgdev_adr_ld<='0';
    i_cfgdev_adr_fifo<='0';
    i_cfgdev_txdata<=i_dsnhdd_reg_ctrl_m_val;
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
    i_cfgdev_txdata<=i_dsnhdd_reg_ctrl_l_val;
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

--      else
--
--        if cmd_write='1' and cmd_read='1' then
--          write(GUI_line,string'("COMPARE DATA: i_ram_txbuf,i_ram_rxbuf")); writeline(output, GUI_line);
--          for i in 0 to i_tstdata_dwsize-1 loop
--
--              write(GUI_line,string'(" i_ram_txbuf/i_ram_rxbuf("));write(GUI_line,i);write(GUI_line,string'("): 0x"));
--              --write(GUI_line,CONV_INTEGER(i_ram_txbuf(i)));
--              for y in 1 to (i_ram_txbuf(i)'length/8)*2 loop --                                                        -- for y in 1 to 8 loop                                             --
--              string_value:=i_ram_txbuf(i)((i_ram_txbuf(i)'length-(4*(y-1)))-1 downto (i_ram_txbuf(i)'length-(4*y)));  -- string_value:=i_ram_txbuf(i)((32-(4*(y-1)))-1 downto (32-(4*y)));--
--              write(GUI_line,Int2StrHEX(CONV_INTEGER(string_value)));                                                  -- write(GUI_line,Int2StrHEX(CONV_INTEGER(string_value)));          --
--              end loop;                                                                                                -- end loop;                                                        --
--              write(GUI_line,string'("/0x"));
--              --write(GUI_line,CONV_INTEGER(i_ram_rxbuf(i)));
--              for y in 1 to (i_ram_rxbuf(i)'length/8)*2 loop --                                                        -- for y in 1 to 8 loop                                              --
--              string_value:=i_ram_rxbuf(i)((i_ram_rxbuf(i)'length-(4*(y-1)))-1 downto (i_ram_rxbuf(i)'length-(4*y)));  -- string_value:=i_ram_rxbuf(i)((32-(4*(y-1)))-1 downto (32-(4*y))); --
--              write(GUI_line,Int2StrHEX(CONV_INTEGER(string_value)));                                                  -- write(GUI_line,Int2StrHEX(CONV_INTEGER(string_value)));           --
--              end loop;                                                                                                -- end loop;                                                         --
--              writeline(output, GUI_line);
--
--            if i_ram_txbuf(i)/=i_ram_rxbuf(i) then
--              --//Завершаем модеоирование.
--              write(GUI_line,string'("COMPARE DATA:ERROR - i_ram_txbuf("));write(GUI_line,i);write(GUI_line,string'(")/= "));
--              write(GUI_line,string'("i_ram_rxbuf("));write(GUI_line,i);write(GUI_line,string'(")"));
--              writeline(output, GUI_line);
--              p_SIM_STOP("Simulation of STOP: COMPARE DATA:ERROR i_ram_rxbuf/=i_ram_rxbuf");
--            end if;
--          end loop;
--
--          cmd_write:='0';
--          cmd_read:='0';
--          write(GUI_line,string'("COMPARE DATA: i_ram_txbuf/i_ram_rxbuf - OK.")); writeline(output, GUI_line);
--        end if;
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
        i_vdata_start<=not i_tst_mode or i_dsnhdd_reg_ctrl_l_val(C_HDD_REG_CTRLL_TST_GEN2RAMBUF_BIT);--'1';
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
    i_cfgdev_txdata<=i_dsnhdd_reg_ctrl_l_val;
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
    i_cfgdev_txdata<=i_dsnhdd_reg_ctrl_l_val;
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
end behavioral;

