-------------------------------------------------------------------------
-- Company     : Linkos
-- Engineer    : Golovachenko Victor
--
-- Create Date : 18.01.2012 17:24:28
-- Module Name : hdd_main
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

library unisim;
use unisim.vcomponents.all;

library work;
use work.vicg_common_pkg.all;
use work.usrif_cfg.all;
use work.prj_cfg.all;
use work.cfgdev_pkg.all;
use work.sata_glob_pkg.all;
use work.dsn_hdd_pkg.all;
use work.hdd_main_unit_pkg.all;
use work.video_ctrl_pkg.all;
use work.mem_ctrl_pkg.all;
use work.sata_testgen_pkg.all;

entity hdd_main is
generic(
G_VSYN_ACTIVE : std_logic:='0';
G_VOUT_DWIDTH : integer:=16;
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

p_out_TP            : out   std_logic_vector(7 downto 0); --вывод на контрольные точки платы
p_out_led           : out   std_logic_vector(7 downto 0)  --выход на свтодиоды платы
);
end entity;

architecture struct of hdd_main is

component dbgcs_iconx1
  PORT (
    CONTROL0 : INOUT STD_LOGIC_VECTOR(35 DOWNTO 0));

end component;

component dbgcs_iconx2
  PORT (
    CONTROL0 : INOUT STD_LOGIC_VECTOR(35 DOWNTO 0);
    CONTROL1 : INOUT STD_LOGIC_VECTOR(35 DOWNTO 0));

end component;

component dbgcs_iconx3
  PORT (
    CONTROL0 : INOUT STD_LOGIC_VECTOR(35 DOWNTO 0);
    CONTROL1 : INOUT STD_LOGIC_VECTOR(35 DOWNTO 0);
    CONTROL2 : INOUT STD_LOGIC_VECTOR(35 DOWNTO 0));

end component;

component dbgcs_sata_layer
  PORT (
    CONTROL : INOUT STD_LOGIC_VECTOR(35 DOWNTO 0);
    CLK : IN STD_LOGIC;
    DATA : IN STD_LOGIC_VECTOR(122 DOWNTO 0);
    TRIG0 : IN STD_LOGIC_VECTOR(41 DOWNTO 0)
    );
end component;

component dbgcs_sata_raid
  PORT (
    CONTROL : INOUT STD_LOGIC_VECTOR(35 DOWNTO 0);
    CLK : IN STD_LOGIC;
    DATA : IN STD_LOGIC_VECTOR(172 downto 0); --(122 DOWNTO 0);
    TRIG0 : IN STD_LOGIC_VECTOR(41 DOWNTO 0)
    );
end component;

signal i_dbgcs_sh0_spd                  : std_logic_vector(35 downto 0);
signal i_dbgcs_hdd0_layer               : std_logic_vector(35 downto 0);
signal i_dbgcs_hdd1_layer               : std_logic_vector(35 downto 0);
signal i_dbgcs_hdd_raid                 : std_logic_vector(35 downto 0);
signal i_dbgcs_vctrl                    : std_logic_vector(35 downto 0);

signal i_hdd0layer_dbgcs                : TSH_ila;
signal i_hdd1layer_dbgcs                : TSH_ila;
signal i_hddraid_dbgcs                  : TSH_ila;
signal i_vctrl_dbgcs                    : TSH_ila;
signal dbgcs_hdd_rambuf_out             : TSH_ila;

--component clock is
--generic(
--G_USRCLK_COUNT : integer:=1
--);
--port(
--p_out_gusrclk  : out std_logic_vector(G_USRCLK_COUNT-1 downto 0);
--p_out_pll_lock : out std_logic;
--
--p_in_clk       : in  std_logic;
--p_in_rst       : in  std_logic
--);
--end component;

function sel_memphy(x: integer) return integer is
begin
  if x = 0 then
    return 1;
  else
    return 0;
  end if;
end function sel_memphy;

constant CI_MEM_VCTRL      : integer:=C_PCFG_VCTRL_MEMBANK_NUM;
constant CI_MEM_HDD        : integer:=C_PCFG_HDD_MEMBANK_NUM;

constant CI_MEM_BANK_M_BIT : integer:=C_MEMCTRL_AWIDTH+1;
constant CI_MEM_BANK_L_BIT : integer:=C_MEMCTRL_AWIDTH+1;
constant CI_MEM_AWIDTH     : integer:=32;
constant CI_MEM_DWIDTH     : integer:=C_MEMCTRL_DWIDTH;

signal i_vfr_prm                        : TFrXY;
signal i_vctrl_mem_trn_len              : std_logic_vector(15 downto 0);

signal i_vin_vs_hdd                     : std_logic;
signal i_vin_hs_hdd                     : std_logic;
signal i_vdi                            : std_logic_vector((10*8)-1 downto 0):=(others=>'0');
signal i_vdi_save                       : std_logic_vector((10*8)-1 downto 0):=(others=>'0');
signal i_vdi_vector                     : std_logic_vector((10*8*2)-1 downto 0);

signal i_vbufo_dout                     : std_logic_vector(G_VOUT_DWIDTH-1 downto 0);
signal i_vbufo_full                     : std_logic;
signal i_vbufo_pfull                    : std_logic;
signal i_vbufo_empty                    : std_logic;

signal i_vctrl_bufi_dout                : std_logic_vector(CI_MEM_DWIDTH-1 downto 0);
signal i_vctrl_bufi_rd                  : std_logic;
signal i_vctrl_bufi_full                : std_logic;
signal i_vctrl_bufi_empty               : std_logic;
signal i_vctrl_bufo_din                 : std_logic_vector(CI_MEM_DWIDTH-1 downto 0);
signal i_vctrl_bufo_wr                  : std_logic;

signal i_hdd_bufi_dout                  : std_logic_vector(CI_MEM_DWIDTH-1 downto 0);
signal i_hdd_bufi_rd                    : std_logic;
signal i_hdd_bufi_empty                 : std_logic;
signal i_hdd_bufi_full                  : std_logic;
--signal i_hdd_bufi_wrcnt                 : std_logic_vector(3 downto 0);
signal i_hdd_bufo_din                   : std_logic_vector(CI_MEM_DWIDTH-1 downto 0);
signal i_hdd_bufo_wr                    : std_logic;

signal i_mem_ctrl_status                : TMEMCTRL_status;
signal i_mem_ctrl_sysin                 : TMEMCTRL_sysin;
signal i_mem_ctrl_sysout                : TMEMCTRL_sysout;

signal i_mem_in_bank                    : TMemINBank;
signal i_mem_out_bank                   : TMemOUTBank;
signal i_mem_in                         : TMemINBank;
signal i_mem_out                        : TMemOUTBank;

signal i_phymem_out                     : TMEMCTRL_phy_outs;
signal i_phymem_inout                   : TMEMCTRL_phy_inouts;

--signal i_usrpll_rst                     : std_logic;
--signal i_usrpll_lock                    : std_logic;
--signal g_usrpll_clkout                  : std_logic_vector(5 downto 0);
signal g_hclk                           : std_logic;
signal g_hdd_clk                        : std_logic;
signal g_vbufi_wrclk                    : std_logic;

signal sr_hdd_hr                        : std_logic_vector(0 to 1);
signal i_hdd_hr_start                   : std_logic;
signal i_hdd_hr_stop                    : std_logic;

signal i_hdd_bufi_rst                   : std_logic;
signal i_vctrl_bufi_rst                 : std_logic;
signal i_vbufo_rst                      : std_logic;
signal i_hdd_rambuf_rst                 : std_logic;
signal i_vctrl_rst                      : std_logic;
signal i_sys_rst_cnt                    : std_logic_vector(5 downto 0):=(others=>'0');
signal i_sys_rst                        : std_logic:='0';
signal g_sata_refclkout                 : std_logic;

signal i_hdd_rst                        : std_logic;
signal i_hdd_gt_refclk150               : std_logic_vector(C_SH_COUNT_MAX(C_PCFG_HDD_COUNT-1)-1 downto 0);
signal g_hdd_gt_refclkout               : std_logic;
--signal i_hdd_gt_plldet                  : std_logic;
signal i_hdd_dcm_lock                   : std_logic;
--signal g_hdd_dcm_gclk75M                : std_logic;
signal g_hdd_dcm_gclk300M               : std_logic;
signal g_hdd_dcm_gclk150M               : std_logic;

signal i_hdd_rbuf_cfg                   : THDDRBufCfg;
signal i_hdd_rbuf_status                : THDDRBufStatus;

signal i_hdd_txbuf_di                   : std_logic_vector(CI_MEM_DWIDTH-1 downto 0);
signal i_hdd_txbuf_wr                   : std_logic;
signal i_hdd_txbuf_full                 : std_logic;
signal i_hdd_txbuf_pfull                : std_logic;
signal i_hdd_txbuf_empty                : std_logic;

signal i_hdd_rxbuf_do                   : std_logic_vector(CI_MEM_DWIDTH-1 downto 0);
signal i_hdd_rxbuf_rd                   : std_logic;
signal i_hdd_rxbuf_empty                : std_logic;
signal i_hdd_rxbuf_pempty               : std_logic;

signal i_hdd_tst_den                    : std_logic;
signal i_hdd_tst_den_tmp                : std_logic;

--signal i_cfg_tstout                     : std_logic_vector(31 downto 0);
signal i_cfg_rst                        : std_logic;
signal g_cfg_clk                        : std_logic;
signal i_cfg_adr                        : std_logic_vector(C_CFGPKT_RADR_M_BIT-C_CFGPKT_RADR_L_BIT downto 0);
signal i_cfg_adr_ld                     : std_logic;
signal i_cfg_adr_fifo                   : std_logic;
signal i_cfg_wr                         : std_logic;
signal i_cfg_rd                         : std_logic;
signal i_cfg_txd                        : std_logic_vector(15 downto 0);
signal i_cfg_rxd                        : std_logic_vector(15 downto 0);
signal i_cfg_txrdy                      : std_logic;
signal i_cfg_rxrdy                      : std_logic;
signal i_cfg_done                       : std_logic;

signal i_hdd_module_rdy                 : std_logic;
signal i_hdd_module_error               : std_logic;
signal i_hdd_busy                       : std_logic;
--signal i_hdd_hirq                       : std_logic;
--signal i_hdd_done                       : std_logic;

signal i_hdd_dbgcs                      : TSH_dbgcs_exp;
signal i_hdd_dbgled                     : THDDLed_SHCountMax;

signal i_hdd_sim_gt_txdata              : TBus32_SHCountMax;
signal i_hdd_sim_gt_txcharisk           : TBus04_SHCountMax;
signal i_hdd_sim_gt_txcomstart          : std_logic_vector(C_HDD_COUNT_MAX-1 downto 0);
signal i_hdd_sim_gt_rxdata              : TBus32_SHCountMax;
signal i_hdd_sim_gt_rxcharisk           : TBus04_SHCountMax;
signal i_hdd_sim_gt_rxstatus            : TBus03_SHCountMax;
signal i_hdd_sim_gt_rxelecidle          : std_logic_vector(C_HDD_COUNT_MAX-1 downto 0);
signal i_hdd_sim_gt_rxdisperr           : TBus04_SHCountMax;
signal i_hdd_sim_gt_rxnotintable        : TBus04_SHCountMax;
signal i_hdd_sim_gt_rxbyteisaligned     : std_logic_vector(C_HDD_COUNT_MAX-1 downto 0);
signal i_hdd_sim_gt_sim_rst             : std_logic_vector(C_HDD_COUNT_MAX-1 downto 0);
signal i_hdd_sim_gt_sim_clk             : std_logic_vector(C_HDD_COUNT_MAX-1 downto 0);
signal i_hdd_tst_in                     : std_logic_vector(31 downto 0);
signal i_hdd_tst_out                    : std_logic_vector(31 downto 0);

signal tst_hdd_rambuf_in                : std_logic_vector(31 downto 0);

signal i_test01_led                     : std_logic;
--signal i_test02_led                     : std_logic;

signal tst_hdd_bufi_out                 : std_logic_vector(31 downto 0);
signal tst_hdd_rambuf_out               : std_logic_vector(31 downto 0);
signal tst_vctrl_bufi_out               : std_logic_vector(31 downto 0);
signal tst_vctrl_out                    : std_logic_vector(31 downto 0);

signal tst_hdd_bufi_full                : std_logic:='0';
signal tst_hdd_bufi_empty               : std_logic:='1';

signal tst_cntbase                      : std_logic_vector(7 downto 0);
signal tst_spd                          : std_logic_vector(7 downto 0);
signal tst_shim_hs                      : std_logic;
signal tst_shim_vs_cnt                  : std_logic_vector(7 downto 0);
signal tst_sr_shim_hs                   : std_logic_vector(0 to 1);
signal tst_vs_hdd,tst_hs_hdd            : std_logic;

type TDtest   is array(0 to 9) of std_logic_vector(7 downto 0);
signal tst_vin_data                     : TDtest;
signal tst_vin_d                        : std_logic_vector(79 downto 0):=(others=>'0');
signal tst_vbufo_dout                   : std_logic_vector(G_VOUT_DWIDTH-1 downto 0):=(others=>'0');
signal tst_mem_err                      : std_logic;


--//MAIN
begin


--***********************************************************
--STATUS
--***********************************************************
p_out_hdd_rdy<=i_hdd_module_rdy and AND_reduce(i_mem_ctrl_status.rdy);
p_out_hdd_err<=i_hdd_module_error;

i_hdd_tst_in(23 downto  0)<=(others=>'0');
i_hdd_tst_in(31 downto 24)<=CONV_STD_LOGIC_VECTOR(C_PCFG_HSCAM_HDD_VERSION, 8);


--***********************************************************
--CLOCKs
--***********************************************************
i_mem_ctrl_sysin.clk<=g_hdd_dcm_gclk300M;
--частота для переписывания данных внутренних буферов для модулей m_vctrl_bufi,m_hdd_bufi
g_vbufi_wrclk<=i_mem_ctrl_sysout.gusrclk(0);
--частота работы с ОЗУ
g_hclk<=i_mem_ctrl_sysout.gusrclk(1);

g_cfg_clk<=g_sata_refclkout;


--***********************************************************
--RESET
--***********************************************************
process(g_sata_refclkout)
begin
  if g_sata_refclkout'event and g_sata_refclkout = '1' then
    if i_sys_rst_cnt(i_sys_rst_cnt'high) = '0' then
      i_sys_rst_cnt <= i_sys_rst_cnt + 1;
    end if;
  end if;
end process;

i_mem_ctrl_sysin.rst <= not i_hdd_dcm_lock;
i_sys_rst <= i_sys_rst_cnt(i_sys_rst_cnt'high - 1);
i_cfg_rst <= i_sys_rst;
i_hdd_rst <= i_sys_rst or i_hdd_rbuf_cfg.grst_hdd;
i_vctrl_rst<=i_sys_rst or not i_mem_ctrl_sysout.pll_lock;--(AND_reduce(i_mem_ctrl_status.rdy));
i_vctrl_bufi_rst<=i_vctrl_rst or i_hdd_rbuf_cfg.grst_vch;
i_hdd_rambuf_rst<=i_vctrl_rst;
i_vbufo_rst <= i_vctrl_rst or i_hdd_hr_start or i_hdd_hr_stop;

process(i_vctrl_rst,g_hclk)
begin
  if i_vctrl_rst='1' then
    sr_hdd_hr<=(others=>'0');
    i_hdd_hr_start<='0';
    i_hdd_hr_stop<='0';
  elsif g_hclk'event and g_hclk='1' then
    sr_hdd_hr<=i_hdd_rbuf_cfg.dmacfg.hm_r & sr_hdd_hr(0 to 0);
    i_hdd_hr_start<=    sr_hdd_hr(0) and not sr_hdd_hr(1);
    i_hdd_hr_stop <=not sr_hdd_hr(0) and     sr_hdd_hr(1);
  end if;
end process;

process(i_hdd_rambuf_rst,g_hclk)
begin
  if i_hdd_rambuf_rst='1' then
    i_hdd_bufi_rst<='1';
  elsif g_hclk'event and g_hclk='1' then
    if (i_hdd_rbuf_cfg.dmacfg.hm_w='1' and i_hdd_rbuf_cfg.tstgen.tesing_on='0') or
       (i_hdd_rbuf_cfg.dmacfg.hm_w='1' and i_hdd_rbuf_cfg.tstgen.tesing_on='1' and i_hdd_rbuf_cfg.tstgen.con2rambuf='1') then
      if i_hdd_rbuf_cfg.dmacfg.atacmdw='1' then
        i_hdd_bufi_rst<='0';
      end if;
    else
      i_hdd_bufi_rst<='1';
    end if;
  end if;
end process;


--***********************************************************
--VIDEO IN
--***********************************************************
--//Берем 8 старших бит из пердолгаемых 10 бит на 1Pixel
gen_vd : for i in 1 to 10 generate
i_vdi((8*i)-1 downto 8*(i-1))<=p_in_vd((8*i)-1 downto (8*i)-8) when i_hdd_rbuf_cfg.tstgen.tesing_on='0' else tst_vin_d((8*i)-1 downto (8*i)-8);
process(p_in_vin_clk)
begin
  if p_in_vin_clk'event and p_in_vin_clk='1' then
    i_vdi_save((8*i)-1 downto 8*(i-1))<=i_vdi((8*i)-1 downto 8*(i-1));
  end if;
end process;
end generate gen_vd;

i_vdi_vector<=i_vdi & i_vdi_save;

gen_vctrl_on : if strcmp(C_PCFG_VCTRL_USE,"ON") generate
--Video Input
m_vctrl_bufi : vin_hdd
generic map(
G_VBUF_OWIDTH => CI_MEM_DWIDTH,
G_VSYN_ACTIVE => G_VSYN_ACTIVE,
G_EXTSYN      => "OFF"
)
port map(
--Вх. видеопоток
p_in_vd            => i_vdi_vector,
p_in_vs            => p_in_vin_vs,
p_in_hs            => p_in_vin_hs,
p_in_vclk          => p_in_vin_clk,
p_in_ext_syn       => p_in_ext_syn,

p_out_vfr_prm      => i_vfr_prm,

--Вых. видеопоток
p_out_vbufin_d     => i_vctrl_bufi_dout,
p_in_vbufin_rd     => i_vctrl_bufi_rd,
p_out_vbufin_empty => i_vctrl_bufi_empty,
p_out_vbufin_full  => i_vctrl_bufi_full,
p_in_vbufin_wrclk  => g_vbufi_wrclk,
p_in_vbufin_rdclk  => g_hclk,

--Технологический
p_in_tst           => (others=>'0'),
p_out_tst          => tst_vctrl_bufi_out,

--System
p_in_rst           => i_vctrl_bufi_rst
);

i_vctrl_mem_trn_len( 7 downto 0)<=CONV_STD_LOGIC_VECTOR(C_PCFG_VCTRL_MEMWR_TRN_LEN, 8);
i_vctrl_mem_trn_len(15 downto 8)<=CONV_STD_LOGIC_VECTOR(C_PCFG_VCTRL_MEMRD_TRN_LEN, 8);

m_vctrl : video_ctrl
generic map(
G_SIM => G_SIM,
G_MEM_BANK_M_BIT => CI_MEM_BANK_M_BIT,
G_MEM_BANK_L_BIT => CI_MEM_BANK_L_BIT,
G_MEM_AWIDTH => CI_MEM_AWIDTH,
G_MEM_DWIDTH => CI_MEM_DWIDTH
)
port map(
-------------------------------
--
-------------------------------
p_in_vfr_prm         => i_vfr_prm,
p_in_mem_trn_len     => i_vctrl_mem_trn_len,
p_in_vch_off         => i_hdd_rbuf_cfg.grst_vch,
p_in_vrd_off         => i_hdd_rbuf_cfg.dmacfg.hm_r,

----------------------------
--Связь с вх/вых видеобуферами
----------------------------
--in
p_in_vbufin_d         => i_vctrl_bufi_dout,
p_out_vbufin_rd       => i_vctrl_bufi_rd,
p_in_vbufin_empty     => i_vctrl_bufi_empty,
--out
p_out_vbufout_d       => i_vctrl_bufo_din,
p_out_vbufout_wr      => i_vctrl_bufo_wr,
p_in_vbufout_full     => i_vbufo_pfull,

---------------------------------
--Связь с mem_ctrl.vhd
---------------------------------
--CH WRITE
p_out_memwr           => i_mem_in (0)(C_MEMCH_WR),--TMemIN ;
p_in_memwr            => i_mem_out(0)(C_MEMCH_WR),--TMemOUT;
--CH READ
p_out_memrd           => i_mem_in (0)(C_MEMCH_RD),--TMemIN ;
p_in_memrd            => i_mem_out(0)(C_MEMCH_RD),--TMemOUT;

-------------------------------
--Технологический
-------------------------------
p_out_tst             => tst_vctrl_out,

-------------------------------
--System
-------------------------------
p_in_clk              => g_hclk,
p_in_rst              => i_vctrl_rst
);

end generate gen_vctrl_on;

gen_vctrl_off : if strcmp(C_PCFG_VCTRL_USE,"OFF") generate
i_vctrl_bufi_empty<='1';
i_vctrl_bufo_din<=(others=>'0');
i_vctrl_bufo_wr<='0';

end generate gen_vctrl_off;


--***********************************************************
--VIDEO BUFOUT
--***********************************************************
p_out_vd<=i_vbufo_dout;

m_vbufo : vout
generic map(
G_VBUF_IWIDTH => CI_MEM_DWIDTH,
G_VBUF_OWIDTH => G_VOUT_DWIDTH,
G_VSYN_ACTIVE => G_VSYN_ACTIVE
)
port map(
p_out_vd         => i_vbufo_dout,--p_out_vd,
p_in_vs          => p_in_vout_vs,
p_in_hs          => p_in_vout_hs,
p_in_vclk        => p_in_vout_clk,

p_in_vd          => i_vctrl_bufo_din,
p_in_vd_wr       => i_vctrl_bufo_wr,
p_in_hd          => i_hdd_bufo_din,
p_in_hd_wr       => i_hdd_bufo_wr,
p_in_sel         => i_hdd_rbuf_cfg.dmacfg.hm_r,

p_out_vbufo_full => i_vbufo_full,
p_out_vbufo_pfull=> i_vbufo_pfull,
p_out_vbufo_empty=> i_vbufo_empty,
p_in_vbufo_wrclk => g_hclk,

p_in_rst         => i_vbufo_rst
);


--***********************************************************
--Контроллер ОЗУ
--***********************************************************
m_mem_mux : mem_mux
generic map(
G_MEMBANK_0 => CI_MEM_HDD,
G_MEMBANK_1 => CI_MEM_VCTRL,
G_SIM => G_SIM
)
port map(
------------------------------------
--Управление
------------------------------------
p_in_sel      => tst_hdd_rambuf_out(12),

------------------------------------
--VCTRL
------------------------------------
p_in_memwr_v  => i_mem_in (0)(C_MEMCH_WR),--TMemIN;
p_out_memwr_v => i_mem_out(0)(C_MEMCH_WR),--TMemOUT;

p_in_memrd_v  => i_mem_in (0)(C_MEMCH_RD),--TMemIN;
p_out_memrd_v => i_mem_out(0)(C_MEMCH_RD),--TMemOUT;

------------------------------------
--HDD
------------------------------------
p_in_memwr_h  => i_mem_in (1)(C_MEMCH_WR),--TMemIN;
p_out_memwr_h => i_mem_out(1)(C_MEMCH_WR),--TMemOUT;

p_in_memrd_h  => i_mem_in (1)(C_MEMCH_RD),--TMemIN;
p_out_memrd_h => i_mem_out(1)(C_MEMCH_RD),--TMemOUT;

------------------------------------
--MEM_CTRL
------------------------------------
p_out_mem     => i_mem_in_bank,  --TMemINBank;
p_in_mem      => i_mem_out_bank, --TMemOUTBank;

------------------------------------
--System
------------------------------------
p_in_sys      => i_mem_ctrl_sysin
);


m_mem_ctrl : mem_ctrl
generic map(
G_SIM => G_SIM
)
port map(
------------------------------------
--User Post
------------------------------------
p_in_mem        => i_mem_in_bank, --TMemINBank;
p_out_mem       => i_mem_out_bank,--TMemOUTBank;

------------------------------------
--Memory physical interface
------------------------------------
p_out_phymem    => i_phymem_out,
p_inout_phymem  => i_phymem_inout,

------------------------------------
--Memory status
------------------------------------
p_out_status    => i_mem_ctrl_status,

-----------------------------------
--Sim
-----------------------------------
p_out_sim_mem   => p_out_sim_mem,
p_in_sim_mem    => p_in_sim_mem,

------------------------------------
--System
------------------------------------
p_out_sys       => i_mem_ctrl_sysout,
p_in_sys        => i_mem_ctrl_sysin
);

p_out_mcb5_a        <= i_phymem_out  (C_PCFG_MEMPHY_SET).a     ;
p_out_mcb5_ba       <= i_phymem_out  (C_PCFG_MEMPHY_SET).ba    ;
p_out_mcb5_ras_n    <= i_phymem_out  (C_PCFG_MEMPHY_SET).ras_n ;
p_out_mcb5_cas_n    <= i_phymem_out  (C_PCFG_MEMPHY_SET).cas_n ;
p_out_mcb5_we_n     <= i_phymem_out  (C_PCFG_MEMPHY_SET).we_n  ;
p_out_mcb5_odt      <= i_phymem_out  (C_PCFG_MEMPHY_SET).odt   ;
p_out_mcb5_cke      <= i_phymem_out  (C_PCFG_MEMPHY_SET).cke   ;
p_out_mcb5_dm       <= i_phymem_out  (C_PCFG_MEMPHY_SET).dm    ;
p_out_mcb5_udm      <= i_phymem_out  (C_PCFG_MEMPHY_SET).udm   ;
p_out_mcb5_ck       <= i_phymem_out  (C_PCFG_MEMPHY_SET).ck    ;
p_out_mcb5_ck_n     <= i_phymem_out  (C_PCFG_MEMPHY_SET).ck_n  ;
p_inout_mcb5_dq     <= i_phymem_inout(C_PCFG_MEMPHY_SET).dq    ;
p_inout_mcb5_udqs   <= i_phymem_inout(C_PCFG_MEMPHY_SET).udqs  ;
p_inout_mcb5_udqs_n <= i_phymem_inout(C_PCFG_MEMPHY_SET).udqs_n;
p_inout_mcb5_dqs    <= i_phymem_inout(C_PCFG_MEMPHY_SET).dqs   ;
p_inout_mcb5_dqs_n  <= i_phymem_inout(C_PCFG_MEMPHY_SET).dqs_n ;
p_inout_mcb5_rzq    <= i_phymem_inout(C_PCFG_MEMPHY_SET).rzq   ;
p_inout_mcb5_zio    <= i_phymem_inout(C_PCFG_MEMPHY_SET).zio   ;

p_out_mcb1_a        <= i_phymem_out  (sel_memphy(C_PCFG_MEMPHY_SET)).a     ;
p_out_mcb1_ba       <= i_phymem_out  (sel_memphy(C_PCFG_MEMPHY_SET)).ba    ;
p_out_mcb1_ras_n    <= i_phymem_out  (sel_memphy(C_PCFG_MEMPHY_SET)).ras_n ;
p_out_mcb1_cas_n    <= i_phymem_out  (sel_memphy(C_PCFG_MEMPHY_SET)).cas_n ;
p_out_mcb1_we_n     <= i_phymem_out  (sel_memphy(C_PCFG_MEMPHY_SET)).we_n  ;
p_out_mcb1_odt      <= i_phymem_out  (sel_memphy(C_PCFG_MEMPHY_SET)).odt   ;
p_out_mcb1_cke      <= i_phymem_out  (sel_memphy(C_PCFG_MEMPHY_SET)).cke   ;
p_out_mcb1_dm       <= i_phymem_out  (sel_memphy(C_PCFG_MEMPHY_SET)).dm    ;
p_out_mcb1_udm      <= i_phymem_out  (sel_memphy(C_PCFG_MEMPHY_SET)).udm   ;
p_out_mcb1_ck       <= i_phymem_out  (sel_memphy(C_PCFG_MEMPHY_SET)).ck    ;
p_out_mcb1_ck_n     <= i_phymem_out  (sel_memphy(C_PCFG_MEMPHY_SET)).ck_n  ;
p_inout_mcb1_dq     <= i_phymem_inout(sel_memphy(C_PCFG_MEMPHY_SET)).dq    ;
p_inout_mcb1_udqs   <= i_phymem_inout(sel_memphy(C_PCFG_MEMPHY_SET)).udqs  ;
p_inout_mcb1_udqs_n <= i_phymem_inout(sel_memphy(C_PCFG_MEMPHY_SET)).udqs_n;
p_inout_mcb1_dqs    <= i_phymem_inout(sel_memphy(C_PCFG_MEMPHY_SET)).dqs   ;
p_inout_mcb1_dqs_n  <= i_phymem_inout(sel_memphy(C_PCFG_MEMPHY_SET)).dqs_n ;
p_inout_mcb1_rzq    <= i_phymem_inout(sel_memphy(C_PCFG_MEMPHY_SET)).rzq   ;
p_inout_mcb1_zio    <= i_phymem_inout(sel_memphy(C_PCFG_MEMPHY_SET)).zio   ;


--***********************************************************
--Проект Накопителя - dsn_hdd.vhd
--***********************************************************
gen_sata_gt : for i in 0 to C_SH_COUNT_MAX(C_PCFG_HDD_COUNT-1)-1 generate
  m_ibufds : IBUFDS port map(I  => p_in_sata_clk_p(i), IB => p_in_sata_clk_n(i), O => i_hdd_gt_refclk150(i));
end generate gen_sata_gt;

m_hdd : dsn_hdd
generic map(
G_MEM_DWIDTH => CI_MEM_DWIDTH,
G_RAID_DWIDTH=> C_PCFG_HDD_RAID_DWIDTH,
G_MODULE_USE=> C_PCFG_HDD_USE,
G_HDD_COUNT => C_PCFG_HDD_COUNT,
G_GT_DBUS   => C_PCFG_HDD_GT_DBUS,
G_DBG       => C_PCFG_HDD_DBG,
G_DBGCS     => C_PCFG_HDD_DBGCS,
G_SIM       => G_SIM
)
port map(
-------------------------------
--Конфигурирование модуля dsn_hdd.vhd (p_in_cfg_clk domain)
-------------------------------
p_in_cfg_clk          => g_cfg_clk,

p_in_cfg_adr          => i_cfg_adr(7 downto 0),
p_in_cfg_adr_ld       => i_cfg_adr_ld,
p_in_cfg_adr_fifo     => i_cfg_adr_fifo,

p_in_cfg_txdata       => i_cfg_txd,
p_in_cfg_wd           => i_cfg_wr,
p_out_cfg_txrdy       => i_cfg_txrdy,

p_out_cfg_rxdata      => i_cfg_rxd,
p_in_cfg_rd           => i_cfg_rd,
p_out_cfg_rxrdy       => i_cfg_rxrdy,

p_in_cfg_done         => i_cfg_done,
p_in_cfg_rst          => i_cfg_rst,

-------------------------------
--STATUS модуля dsn_hdd.vhd
-------------------------------
p_out_hdd_rdy         => i_hdd_module_rdy,
p_out_hdd_error       => i_hdd_module_error,
p_out_hdd_busy        => i_hdd_busy,
p_out_hdd_irq         => open,--i_hdd_hirq,
p_out_hdd_done        => open,--i_hdd_done,

-------------------------------
--Связь с Источниками/Приемниками данных накопителя
-------------------------------
p_out_rbuf_cfg        => i_hdd_rbuf_cfg,
p_in_rbuf_status      => i_hdd_rbuf_status,

p_in_hdd_txd_wrclk    => g_hclk,
p_in_hdd_txd          => i_hdd_txbuf_di,
p_in_hdd_txd_wr       => i_hdd_txbuf_wr,
p_out_hdd_txbuf_pfull => i_hdd_txbuf_pfull,
p_out_hdd_txbuf_full  => i_hdd_txbuf_full,
p_out_hdd_txbuf_empty => i_hdd_txbuf_empty,

p_in_hdd_rxd_rdclk    => g_hclk,
p_out_hdd_rxd         => i_hdd_rxbuf_do,
p_in_hdd_rxd_rd       => i_hdd_rxbuf_rd,
p_out_hdd_rxbuf_empty => i_hdd_rxbuf_empty,
p_out_hdd_rxbuf_pempty=> i_hdd_rxbuf_pempty,

-------------------------------
--Sata Driver
-------------------------------
p_out_sata_txn        => p_out_sata_txn,
p_out_sata_txp        => p_out_sata_txp,
p_in_sata_rxn         => p_in_sata_rxn,
p_in_sata_rxp         => p_in_sata_rxp,

p_in_sata_refclk      => i_hdd_gt_refclk150,
p_out_sata_refclkout  => g_sata_refclkout,
p_out_sata_gt_plldet  => open,--i_hdd_gt_plldet,
p_out_sata_dcm_lock   => i_hdd_dcm_lock,
p_out_sata_dcm_gclk2div=> open,--g_hdd_dcm_gclk75M,
p_out_sata_dcm_gclk2x => g_hdd_dcm_gclk300M,
p_out_sata_dcm_gclk0  => g_hdd_dcm_gclk150M,

-------------------------------
--Технологический порт
-------------------------------
p_in_tst              => i_hdd_tst_in,
p_out_tst             => i_hdd_tst_out,

-------------------------------
--Debug/Sim
-------------------------------
p_out_dbgcs                 => i_hdd_dbgcs,
p_out_dbgled                => i_hdd_dbgled,

p_out_sim_gt_txdata         => i_hdd_sim_gt_txdata,         --open,--
p_out_sim_gt_txcharisk      => i_hdd_sim_gt_txcharisk,      --open,--
p_out_sim_gt_txcomstart     => i_hdd_sim_gt_txcomstart,     --open,--
p_in_sim_gt_rxdata          => i_hdd_sim_gt_rxdata,
p_in_sim_gt_rxcharisk       => i_hdd_sim_gt_rxcharisk,
p_in_sim_gt_rxstatus        => i_hdd_sim_gt_rxstatus,
p_in_sim_gt_rxelecidle      => i_hdd_sim_gt_rxelecidle,
p_in_sim_gt_rxdisperr       => i_hdd_sim_gt_rxdisperr,
p_in_sim_gt_rxnotintable    => i_hdd_sim_gt_rxnotintable,
p_in_sim_gt_rxbyteisaligned => i_hdd_sim_gt_rxbyteisaligned,
p_out_gt_sim_rst            => i_hdd_sim_gt_sim_rst,        --open,--
p_out_gt_sim_clk            => i_hdd_sim_gt_sim_clk,        --open,--

-------------------------------
--System
-------------------------------
p_in_clk           => g_hclk,
p_in_rst           => i_hdd_rst
);

--gen_satah: for i in 0 to C_HDD_COUNT_MAX-1 generate
--i_hdd_sim_gt_rxdata(i)<=(others=>'0');
--i_hdd_sim_gt_rxcharisk(i)<=(others=>'0');
--i_hdd_sim_gt_rxstatus(i)<=(others=>'0');
--i_hdd_sim_gt_rxelecidle(i)<='0';
--i_hdd_sim_gt_rxdisperr(i)<=(others=>'0');
--i_hdd_sim_gt_rxnotintable(i)<=(others=>'0');
--i_hdd_sim_gt_rxbyteisaligned(i)<='0';
--end generate gen_satah;
p_out_sim_hdd_busy<=i_hdd_busy;
p_out_sim_gt_txdata         <= i_hdd_sim_gt_txdata    ;     --open,--
p_out_sim_gt_txcharisk      <= i_hdd_sim_gt_txcharisk ;     --open,--
p_out_sim_gt_txcomstart     <= i_hdd_sim_gt_txcomstart;     --open,--
i_hdd_sim_gt_rxdata         <= p_in_sim_gt_rxdata         ;
i_hdd_sim_gt_rxcharisk      <= p_in_sim_gt_rxcharisk      ;
i_hdd_sim_gt_rxstatus       <= p_in_sim_gt_rxstatus       ;
i_hdd_sim_gt_rxelecidle     <= p_in_sim_gt_rxelecidle     ;
i_hdd_sim_gt_rxdisperr      <= p_in_sim_gt_rxdisperr      ;
i_hdd_sim_gt_rxnotintable   <= p_in_sim_gt_rxnotintable   ;
i_hdd_sim_gt_rxbyteisaligned<= p_in_sim_gt_rxbyteisaligned;
p_out_gt_sim_rst            <= i_hdd_sim_gt_sim_rst;        --open,--
p_out_gt_sim_clk            <= i_hdd_sim_gt_sim_clk;        --open,--



gen_hdd_on : if strcmp(C_PCFG_HDD_USE,"ON") generate

m_hdd_rambuf : dsn_hdd_rambuf
generic map(
G_MODULE_USE => C_PCFG_HDD_USE,
G_RAMBUF_SIZE=> C_PCFG_HDD_RAMBUF_SIZE,
G_DBGCS      => C_PCFG_HDD_DBGCS,
G_SIM        => G_SIM,
G_USE_2CH    => "ON",
G_MEM_BANK_M_BIT => CI_MEM_BANK_M_BIT,
G_MEM_BANK_L_BIT => CI_MEM_BANK_L_BIT,
G_MEM_AWIDTH => CI_MEM_AWIDTH,
G_MEM_DWIDTH => CI_MEM_DWIDTH
)
port map(
-------------------------------
-- Конфигурирование
-------------------------------
p_in_rbuf_cfg         => i_hdd_rbuf_cfg,
p_out_rbuf_status     => i_hdd_rbuf_status,
p_in_lentrn_exp       => '0',

----------------------------
--Связь с буфером видеоданных
----------------------------
p_in_bufi_dout        => i_hdd_bufi_dout,
p_out_bufi_rd         => i_hdd_bufi_rd,
p_in_bufi_empty       => i_hdd_bufi_empty,
p_in_bufi_full        => i_hdd_bufi_full,
p_in_bufi_pfull       => '0',--i_hdd_bufi_pfull,
p_in_bufi_wrcnt       => (others=>'0'),--i_hdd_bufi_wrcnt,

p_out_bufo_din        => i_hdd_bufo_din,
p_out_bufo_wr         => i_hdd_bufo_wr,
p_in_bufo_full        => i_vbufo_pfull,
p_in_bufo_empty       => i_vbufo_empty,

----------------------------
--Связь с модулем HDD
----------------------------
p_out_hdd_txd         => i_hdd_txbuf_di,
p_out_hdd_txd_wr      => i_hdd_txbuf_wr,
p_in_hdd_txbuf_pfull  => i_hdd_txbuf_pfull,
p_in_hdd_txbuf_full   => i_hdd_txbuf_full,
p_in_hdd_txbuf_empty  => i_hdd_txbuf_empty,

p_in_hdd_rxd          => i_hdd_rxbuf_do,
p_out_hdd_rxd_rd      => i_hdd_rxbuf_rd,
p_in_hdd_rxbuf_empty  => i_hdd_rxbuf_empty,
p_in_hdd_rxbuf_pempty => i_hdd_rxbuf_pempty,

---------------------------------
-- Связь с mem_ctrl.vhd
---------------------------------
p_out_memch0          => i_mem_in (1)(C_MEMCH_WR),--TMemIN ;
p_in_memch0           => i_mem_out(1)(C_MEMCH_WR),--TMemOUT;

p_out_memch1          => i_mem_in (1)(C_MEMCH_RD),--TMemIN ;
p_in_memch1           => i_mem_out(1)(C_MEMCH_RD),--TMemOUT;

-------------------------------
--Технологический
-------------------------------
p_in_tst              => tst_hdd_rambuf_in,
p_out_tst             => tst_hdd_rambuf_out,
p_out_dbgcs           => dbgcs_hdd_rambuf_out,

-------------------------------
--System
-------------------------------
p_in_clk              => g_hclk,
p_in_rst              => i_hdd_rambuf_rst
);

m_hdd_bufi : vin_hdd
generic map (
G_VBUF_OWIDTH => CI_MEM_DWIDTH,
G_VSYN_ACTIVE => G_VSYN_ACTIVE,
G_EXTSYN      => "ON"
)
port map(
--Вх. видеопоток
p_in_vd            => i_vdi_vector,
p_in_vs            => i_vin_vs_hdd,--p_in_vin_vs,
p_in_hs            => i_vin_hs_hdd,--p_in_vin_hs,
p_in_vclk          => p_in_vin_clk,
p_in_ext_syn       => p_in_ext_syn,

p_out_vfr_prm      => open,--i_vfr_prm,

--Вых. видеопоток
p_out_vbufin_d     => i_hdd_bufi_dout,
p_in_vbufin_rd     => i_hdd_bufi_rd,
p_out_vbufin_empty => i_hdd_bufi_empty,
p_out_vbufin_full  => i_hdd_bufi_full,
p_in_vbufin_wrclk  => g_vbufi_wrclk,
p_in_vbufin_rdclk  => g_hclk,

--Технологический
p_in_tst           => (others=>'0'),
p_out_tst          => tst_hdd_bufi_out,

--System
p_in_rst           => i_hdd_bufi_rst
);

tst_hdd_rambuf_in(0)<=AND_reduce(i_mem_ctrl_status.rdy);
tst_hdd_rambuf_in(31 downto 1)<=(others=>'0');

end generate gen_hdd_on;

gen_hdd_off : if strcmp(C_PCFG_HDD_USE,"OFF") generate

i_hdd_rbuf_status.err<='0';
i_hdd_rbuf_status.err_type.bufi_full<='0';
i_hdd_rbuf_status.err_type.rambuf_full<='0';
i_hdd_rbuf_status.done<='0';
i_hdd_rbuf_status.hwlog_size<=(others=>'0');

i_hdd_rbuf_status.ram_wr_o.wr_rdy <='1';
i_hdd_rbuf_status.ram_wr_o.rd_rdy <='1';
i_hdd_rbuf_status.ram_wr_o.dout <=(others=>'0');

i_hdd_txbuf_di<=(others=>'0');
i_hdd_txbuf_wr<='0';
i_hdd_rxbuf_rd<='0';

i_hdd_bufo_din<=(others=>'0');
i_hdd_bufo_wr<='0';

end generate gen_hdd_off;


--***********************************************************
--Интерфейс управления модулем
--***********************************************************
gen_ftdi : if strcmp(C_HSCAM_USRIF,"FTDI") generate

gen_sim_off : if strcmp(G_SIM,"OFF") generate
m_cfg_ftdi : cfgdev_ftdi
port map(
-------------------------------
--Связь с FTDI
-------------------------------
p_inout_ftdi_d       => p_inout_ftdi_d,
p_out_ftdi_rd_n      => p_out_ftdi_rd_n,
p_out_ftdi_wr_n      => p_out_ftdi_wr_n,
p_in_ftdi_txe_n      => p_in_ftdi_txe_n,
p_in_ftdi_rxf_n      => p_in_ftdi_rxf_n,
p_in_ftdi_pwren_n    => p_in_ftdi_pwren_n,

-------------------------------
--
-------------------------------
p_out_module_rdy     => open,
p_out_module_error   => open,

-------------------------------
--Запись/Чтение конфигурационных параметров уст-ва
-------------------------------
p_out_cfg_dadr       => open,
p_out_cfg_radr       => i_cfg_adr,
p_out_cfg_radr_ld    => i_cfg_adr_ld,
p_out_cfg_radr_fifo  => i_cfg_adr_fifo,
p_out_cfg_wr         => i_cfg_wr,
p_out_cfg_rd         => i_cfg_rd,
p_out_cfg_txdata     => i_cfg_txd,
p_in_cfg_rxdata      => i_cfg_rxd,
p_in_cfg_txrdy       => i_cfg_txrdy,
p_in_cfg_rxrdy       => i_cfg_rxrdy,

p_out_cfg_done       => i_cfg_done,
p_in_cfg_clk         => g_cfg_clk,

-------------------------------
--Технологический
-------------------------------
p_in_tst             => (others=>'0'),
p_out_tst            => open,--i_cfg_tstout,

-------------------------------
--System
-------------------------------
p_in_rst => i_sys_rst
);
end generate gen_sim_off;

gen_sim_on : if strcmp(G_SIM,"ON") generate
p_out_sim_cfg_clk    <= g_cfg_clk;
p_out_sim_cfg_rxdata <= i_cfg_rxd;
p_out_sim_cfg_txrdy  <= i_cfg_txrdy;
p_out_sim_cfg_rxrdy  <= i_cfg_rxrdy;

i_cfg_adr      <= EXT(p_in_sim_cfg_adr, i_cfg_adr'length);
i_cfg_adr_ld   <= p_in_sim_cfg_adr_ld;
i_cfg_adr_fifo <= p_in_sim_cfg_adr_fifo;
i_cfg_wr       <= p_in_sim_cfg_wd;
i_cfg_rd       <= p_in_sim_cfg_rd;
i_cfg_txd      <= p_in_sim_cfg_txdata;
i_cfg_done     <= p_in_sim_cfg_done;

p_inout_ftdi_d<=(others=>'Z');
p_out_ftdi_rd_n<='1';
p_out_ftdi_wr_n<='1';
end generate gen_sim_on;

p_out_usr_status(0)<=p_in_usr_rx_rd;
p_out_usr_status(1)<=p_in_usr_tx_wr;
p_out_usr_status(p_out_usr_status'length-1 downto 2)<=(others=>'0');
p_out_usr_rxd<=p_in_usr_txd;
end generate gen_ftdi;

gen_host : if strcmp(C_HSCAM_USRIF,"HOST") generate
m_cfg_host : cfgdev_host
generic map(
G_HOST_DWIDTH => 16
)
port map(
-------------------------------
--Связь с Хостом
-------------------------------
p_out_host_rxrdy     => p_out_usr_status(0),--p_out_usr_rx_rdy,
p_out_host_rxd       => p_out_usr_rxd,
p_in_host_rd         => p_in_usr_rx_rd,

p_out_host_txrdy     => p_out_usr_status(1),--p_out_usr_tx_rdy,
p_in_host_txd        => p_in_usr_txd,
p_in_host_wr         => p_in_usr_tx_wr,

p_out_host_irq       => open,
p_in_host_clk        => p_in_usr_clk,

-------------------------------
--
-------------------------------
p_out_module_rdy     => open,
p_out_module_error   => open,

-------------------------------
--Запись/Чтение конфигурационных параметров уст-ва
-------------------------------
p_out_cfg_dadr       => open,
p_out_cfg_radr       => i_cfg_adr,
p_out_cfg_radr_ld    => i_cfg_adr_ld,
p_out_cfg_radr_fifo  => i_cfg_adr_fifo,
p_out_cfg_wr         => i_cfg_wr,
p_out_cfg_rd         => i_cfg_rd,
p_out_cfg_txdata     => i_cfg_txd,
p_in_cfg_rxdata      => i_cfg_rxd,
p_in_cfg_txrdy       => i_cfg_txrdy,
p_in_cfg_rxrdy       => i_cfg_rxrdy,

p_out_cfg_done       => i_cfg_done,
p_in_cfg_clk         => g_cfg_clk,

-------------------------------
--Технологический
-------------------------------
p_in_tst             => (others=>'0'),
p_out_tst            => open,--i_cfg_tst_out,

-------------------------------
--System
-------------------------------
p_in_rst => i_cfg_rst
);
p_out_usr_status(p_out_usr_status'length-1 downto 2)<=(others=>'0');
end generate gen_host;


--***********************************************************
--Технологические сигналы
--***********************************************************
m_blink1 : fpga_test_01
generic map(
G_BLINK_T05   =>10#250#, -- 1/2 периода мигания светодиода.(время в ms)
G_CLK_T05us   =>10#75#   -- 05us - 150MHz
)
port map(
p_out_test_led => i_test01_led,
p_out_test_done=> open,

p_out_1us      => open,
p_out_1ms      => open,
-------------------------------
--System
-------------------------------
p_in_clk       => g_hdd_dcm_gclk150M,--g_sata_refclkout,
p_in_rst       => i_sys_rst
);

--HDD LEDs:
--SATA0 (На плате SATA1)
p_out_led(2)<=i_hdd_dbgled(0).wr  when i_hdd_dbgled(0).err='0' else i_hdd_dbgled(0).link;
p_out_led(4)<=i_hdd_dbgled(0).rdy when i_hdd_dbgled(0).err='0' else i_test01_led;
p_out_TP(0) <=i_test01_led;
p_out_TP(1) <=i_hdd_dbgled(0).busy;

--SATA1 (На плате SATA0)
p_out_led(3)<=i_hdd_dbgled(1).wr  when i_hdd_dbgled(1).err='0' else i_hdd_dbgled(1).link;
p_out_led(5)<=i_hdd_dbgled(1).rdy when i_hdd_dbgled(1).err='0' else i_test01_led;
p_out_TP(2) <='0';--p_in_tst(2);--зарезервировано!!!
p_out_TP(3) <=i_hdd_dbgled(1).busy;

--SATA2 (На плате SATA3)
p_out_led(0)<=i_hdd_dbgled(2).wr  when i_hdd_dbgled(2).err='0' else i_hdd_dbgled(2).link;
p_out_led(7)<=i_hdd_dbgled(2).rdy when i_hdd_dbgled(2).err='0' else i_test01_led;
p_out_TP(4) <=not i_vctrl_bufi_empty when tst_mem_err='0' else  i_test01_led;
p_out_TP(5) <=i_hdd_dbgled(2).busy;

--SATA3 (На плате SATA2)
p_out_led(1)<=i_hdd_dbgled(3).wr  when i_hdd_dbgled(3).err='0' else i_hdd_dbgled(3).link;
p_out_led(6)<=i_hdd_dbgled(3).rdy when i_hdd_dbgled(3).err='0' else i_test01_led;
p_out_TP(6) <=AND_reduce(i_mem_ctrl_status.rdy);
p_out_TP(7) <=i_hdd_dbgled(3).busy;

tst_mem_err<=i_mem_out_bank(CI_MEM_HDD)(C_MEMCH_WR).txbuf_err or i_mem_out_bank(CI_MEM_HDD)(C_MEMCH_WR).txbuf_underrun or i_mem_out_bank(CI_MEM_HDD)(C_MEMCH_WR).cmdbuf_err or
             i_mem_out_bank(CI_MEM_HDD)(C_MEMCH_RD).rxbuf_err or i_mem_out_bank(CI_MEM_HDD)(C_MEMCH_RD).rxbuf_overflow or i_mem_out_bank(CI_MEM_HDD)(C_MEMCH_RD).cmdbuf_err or
             i_mem_out_bank(CI_MEM_VCTRL)(C_MEMCH_WR).txbuf_err or i_mem_out_bank(CI_MEM_VCTRL)(C_MEMCH_WR).txbuf_underrun or i_mem_out_bank(CI_MEM_VCTRL)(C_MEMCH_WR).cmdbuf_err or
             i_mem_out_bank(CI_MEM_VCTRL)(C_MEMCH_RD).rxbuf_err or i_mem_out_bank(CI_MEM_VCTRL)(C_MEMCH_RD).rxbuf_overflow or i_mem_out_bank(CI_MEM_VCTRL)(C_MEMCH_RD).cmdbuf_err;

--//GenTest->RAMBUF - Эмуляция входного потока данных(можно регулировать скорость потока)
tst_spd<=CONV_STD_LOGIC_VECTOR(255, tst_spd'length) when i_hdd_rbuf_cfg.tstgen.tesing_spd=CONV_STD_LOGIC_VECTOR(0, 8) else
         i_hdd_rbuf_cfg.tstgen.tesing_spd;
process(i_vctrl_rst,p_in_vin_clk)
begin
  if i_vctrl_rst='1' then
    tst_cntbase<=(others=>'0');
    tst_shim_hs<='0';
    tst_shim_vs_cnt<=(others=>'0');
    tst_sr_shim_hs<=(others=>'0');
  elsif p_in_vin_clk'event and p_in_vin_clk='1' then
    if tst_cntbase=tst_spd then
      tst_shim_hs<='0';
    elsif tst_cntbase=(tst_cntbase'range => '0') then
      tst_shim_hs<='1';
    else
    end if;

    tst_cntbase<=tst_cntbase+1;

    tst_sr_shim_hs<=tst_shim_hs & tst_sr_shim_hs(0 to 0);
    if tst_sr_shim_hs(0)='0' and tst_sr_shim_hs(1)='1' then
      tst_shim_vs_cnt<=tst_shim_vs_cnt + 1;
    end if;
  end if;
end process;

tst_vs_hdd<=not tst_shim_hs when tst_shim_vs_cnt=CONV_STD_LOGIC_VECTOR(250, tst_shim_vs_cnt'length) else '1';
tst_hs_hdd<=tst_shim_hs;

i_vin_vs_hdd<=tst_vs_hdd when i_hdd_rbuf_cfg.tstgen.tesing_on='1' else p_in_vin_vs;
i_vin_hs_hdd<=tst_hs_hdd when i_hdd_rbuf_cfg.tstgen.tesing_on='1' else p_in_vin_hs;

gen_tstvd : for i in 1 to 10 generate
process(i_vctrl_rst,p_in_vin_clk)
begin
  if i_vctrl_rst='1' then
    tst_vin_data(i-1)<=CONV_STD_LOGIC_VECTOR(i, tst_vin_data(i-1)'length);
  elsif p_in_vin_clk'event and p_in_vin_clk='1' then
    if i_hdd_rbuf_cfg.tstgen.tesing_on='1' then
      if i_vin_vs_hdd=G_VSYN_ACTIVE or i_vin_hs_hdd=G_VSYN_ACTIVE then
        tst_vin_data(i-1)<=CONV_STD_LOGIC_VECTOR(i-1, tst_vin_data(i-1)'length);
      else
        tst_vin_data(i-1)<=tst_vin_data(i-1) + CONV_STD_LOGIC_VECTOR(10, tst_vin_data(i-1)'length);
      end if;
    end if;
  end if;
end process;

tst_vin_d((8*i)-1 downto (8*i)-8)<=tst_vin_data(i-1);
end generate gen_tstvd;

--p_out_tst( 7 downto 0)<=i_hdd_rbuf_cfg.tstgen.tesing_spd;
--p_out_tst( 8)<=i_hdd_rbuf_cfg.tstgen.tesing_on;
--p_out_tst(31 downto 9)<=(others=>'0');


--//### ChipScope DBG: ########
gen_hdd_dbgcs : if strcmp(C_PCFG_HDD_DBGCS,"ON") generate

gen_sh_dbgcs : if strcmp(C_PCFG_HDD_SH_DBGCS,"ON") generate
m_dbgcs_icon : dbgcs_iconx3
port map(
CONTROL0 => i_dbgcs_sh0_spd,
CONTROL1 => i_dbgcs_hdd0_layer,
CONTROL2 => i_dbgcs_hdd1_layer
);

--//### DBG HDD0_SPD: ########
m_dbgcs_sh0_spd : dbgcs_sata_layer
port map
(
CONTROL => i_dbgcs_sh0_spd,
CLK     => i_hdd_dbgcs.sh(0).spd.clk,
DATA    => i_hdd_dbgcs.sh(0).spd.data(122 downto 0),
TRIG0   => i_hdd_dbgcs.sh(0).spd.trig0(41 downto 0)
);

--//### DBG HDD0: ########
m_dbgcs_hdd0_layer : dbgcs_sata_raid --dbgcs_sata_layer
port map
(
CONTROL => i_dbgcs_hdd0_layer,
CLK     => i_hdd_dbgcs.sh(0).layer.clk,
DATA    => i_hdd_dbgcs.sh(0).layer.data(172 downto 0),--(122 downto 0),
TRIG0   => i_hdd0layer_dbgcs.trig0(41 downto 0)
);

i_hdd0layer_dbgcs.trig0(19 downto 0)<=i_hdd_dbgcs.sh(0).layer.trig0(19 downto 0);--llayer
i_hdd0layer_dbgcs.trig0(20)<=i_hdd_dbgcs.sh(0).layer.data(160);--<=p_in_alstatus.sstatus(C_ASSTAT_DET_BIT_L+1);--//C_PSTAT_DET_ESTABLISH_ON_BIT
i_hdd0layer_dbgcs.trig0(21)<=i_hdd_dbgcs.sh(0).layer.data(161);--<=p_in_alstatus.sstatus(C_ASSTAT_DET_BIT_L+0);--//C_PSTAT_DET_DEV_ON_BIT
i_hdd0layer_dbgcs.trig0(22)<=i_hdd_dbgcs.sh(0).layer.data(162);--<=p_in_txelecidle;
i_hdd0layer_dbgcs.trig0(23)<=i_hdd_dbgcs.sh(0).layer.data(163);--<=p_in_rxelecidle;
i_hdd0layer_dbgcs.trig0(24)<=i_hdd_dbgcs.sh(0).layer.data(164);--<=p_in_txcomstart;
i_hdd0layer_dbgcs.trig0(25)<=i_hdd_dbgcs.sh(0).layer.data(167);--<=p_in_rxcdrreset;
i_hdd0layer_dbgcs.trig0(41 downto 26)<=i_hdd_dbgcs.sh(0).layer.trig0(41 downto 26);--llayer

--//### DBG HDD1: ########
gen_hdd1 : if C_PCFG_HDD_COUNT=1 generate
m_dbgcs_hdd1_layer : dbgcs_sata_raid --dbgcs_sata_layer
port map
(
CONTROL => i_dbgcs_hdd1_layer,
CLK     => i_hdd_dbgcs.sh(0).layer.clk,
DATA    => i_hdd_dbgcs.sh(0).layer.data(172 downto 0),--(122 downto 0),
TRIG0   => i_hdd1layer_dbgcs.trig0(41 downto 0)
);

i_hdd1layer_dbgcs.trig0(19 downto 0)<=i_hdd_dbgcs.sh(0).layer.trig0(19 downto 0);--llayer
i_hdd1layer_dbgcs.trig0(20)<=i_hdd_dbgcs.sh(0).layer.data(160);--<=p_in_alstatus.sstatus(C_ASSTAT_DET_BIT_L+1);--//C_PSTAT_DET_ESTABLISH_ON_BIT
i_hdd1layer_dbgcs.trig0(21)<=i_hdd_dbgcs.sh(0).layer.data(161);--<=p_in_alstatus.sstatus(C_ASSTAT_DET_BIT_L+0);--//C_PSTAT_DET_DEV_ON_BIT
i_hdd1layer_dbgcs.trig0(22)<=i_hdd_dbgcs.sh(0).layer.data(162);--<=p_in_txelecidle;
i_hdd1layer_dbgcs.trig0(23)<=i_hdd_dbgcs.sh(0).layer.data(163);--<=p_in_rxelecidle;
i_hdd1layer_dbgcs.trig0(24)<=i_hdd_dbgcs.sh(0).layer.data(164);--<=p_in_txcomstart;
i_hdd1layer_dbgcs.trig0(25)<=i_hdd_dbgcs.sh(0).layer.data(167);--<=p_in_rxcdrreset;
i_hdd1layer_dbgcs.trig0(41 downto 26)<=i_hdd_dbgcs.sh(0).layer.trig0(41 downto 26);--llayer
end generate gen_hdd1;

gen_hdd2 : if C_PCFG_HDD_COUNT>1 generate
m_dbgcs_hdd1_layer : dbgcs_sata_raid --dbgcs_sata_layer
port map
(
CONTROL => i_dbgcs_hdd1_layer,
CLK     => i_hdd_dbgcs.sh(1).layer.clk,
DATA    => i_hdd_dbgcs.sh(1).layer.data(172 downto 0),--(122 downto 0),
TRIG0   => i_hdd1layer_dbgcs.trig0(41 downto 0)
);

i_hdd1layer_dbgcs.trig0(19 downto 0)<=i_hdd_dbgcs.sh(1).layer.trig0(19 downto 0);--llayer
i_hdd1layer_dbgcs.trig0(20)<=i_hdd_dbgcs.sh(1).layer.data(160);--<=p_in_alstatus.sstatus(C_ASSTAT_DET_BIT_L+1);--//C_PSTAT_DET_ESTABLISH_ON_BIT
i_hdd1layer_dbgcs.trig0(21)<=i_hdd_dbgcs.sh(1).layer.data(161);--<=p_in_alstatus.sstatus(C_ASSTAT_DET_BIT_L+0);--//C_PSTAT_DET_DEV_ON_BIT
i_hdd1layer_dbgcs.trig0(22)<=i_hdd_dbgcs.sh(1).layer.data(162);--<=p_in_txelecidle;
i_hdd1layer_dbgcs.trig0(23)<=i_hdd_dbgcs.sh(1).layer.data(163);--<=p_in_rxelecidle;
i_hdd1layer_dbgcs.trig0(24)<=i_hdd_dbgcs.sh(1).layer.data(164);--<=p_in_txcomstart;
i_hdd1layer_dbgcs.trig0(25)<=i_hdd_dbgcs.sh(1).layer.data(167);--<=p_in_rxcdrreset;
i_hdd1layer_dbgcs.trig0(41 downto 26)<=i_hdd_dbgcs.sh(1).layer.trig0(41 downto 26);--llayer
end generate gen_hdd2;

end generate gen_sh_dbgcs;


gen_raid_dbgcs : if strcmp(C_PCFG_HDD_RAID_DBGCS,"ON") generate
--//### DGB HDD_RAID: ########
m_dbgcs_icon : dbgcs_iconx1
port map(
CONTROL0 => i_dbgcs_hdd_raid
);

m_dbgcs_sh0_raid : dbgcs_sata_raid
port map(
CONTROL => i_dbgcs_hdd_raid,
CLK     => i_hdd_dbgcs.raid.clk,
DATA    => i_hddraid_dbgcs.data(172 downto 0),
TRIG0   => i_hddraid_dbgcs.trig0(41 downto 0)
);

--//-------- TRIG: ------------------
i_hddraid_dbgcs.trig0(11 downto 0)<=i_hdd_dbgcs.raid.trig0(11 downto 0);
i_hddraid_dbgcs.trig0(12)<=i_mem_out_bank(CI_MEM_HDD)(C_MEMCH_WR).txbuf_err or i_mem_out_bank(CI_MEM_HDD)(C_MEMCH_WR).txbuf_underrun or i_mem_out_bank(CI_MEM_HDD)(C_MEMCH_WR).cmdbuf_err; --tst_hdd_bufi_out(1);--i_buf_wr;;--;--
i_hddraid_dbgcs.trig0(13)<=i_mem_out_bank(CI_MEM_HDD)(C_MEMCH_RD).rxbuf_err or i_mem_out_bank(CI_MEM_HDD)(C_MEMCH_RD).rxbuf_overflow or i_mem_out_bank(CI_MEM_HDD)(C_MEMCH_RD).cmdbuf_err; --tst_hdd_bufi_out(2);--i_buf_wr_en;
i_hddraid_dbgcs.trig0(14)<=tst_hdd_bufi_empty;
i_hddraid_dbgcs.trig0(15)<=i_vbufo_rst;--i_vbufo_empty and tst_hdd_rambuf_out(22);--i_hdd_dbgcs.raid.trig0(15);
i_hddraid_dbgcs.trig0(16)<=i_vbufo_empty and tst_hdd_rambuf_out(22) and not p_in_vout_vs;--i_hdd_txbuf_pfull;
i_hddraid_dbgcs.trig0(17)<=tst_hdd_bufi_full or i_hdd_rbuf_status.err_type.rambuf_full or i_hdd_rbuf_status.err_type.bufi_full or i_vbufo_full;
--i_hddraid_dbgcs.trig0(18)<=i_hdd_dbgcs.raid.trig0(18);
--i_hddraid_dbgcs.trig0(19)<=i_hdd_txbuf_full;-- or tst_hdd_bufi_out(3);--i_hdd_rbuf_status.err;
i_hddraid_dbgcs.trig0(18)<=tst_hdd_rambuf_out(23);--<=i_memr_start_hm_r;  --i_hdd_dbgcs.sh(2).layer.data(49);--p_in_ll_rxd_wr; --llayer->tlayer
i_hddraid_dbgcs.trig0(19)<=tst_hdd_rambuf_out(25);--<=i_memw_stop_hm_r;   --i_hdd_dbgcs.sh(2).layer.data(116);--p_in_ll_txd_rd; --llayer<-tlayer

--//SH0
i_hddraid_dbgcs.trig0(24 downto 20)<=i_hdd_dbgcs.sh(0).layer.trig0(34 downto 30);--llayer
i_hddraid_dbgcs.trig0(29 downto 25)<=i_hdd_dbgcs.sh(0).layer.trig0(39 downto 35);--tlayer
--//SH1
gen_hdd1 : if C_PCFG_HDD_COUNT=1 generate
i_hddraid_dbgcs.trig0(34 downto 30)<=i_hdd_dbgcs.sh(0).layer.trig0(34 downto 30);--llayer
i_hddraid_dbgcs.trig0(39 downto 35)<=i_hdd_dbgcs.sh(0).layer.trig0(39 downto 35);--tlayer
end generate gen_hdd1;
gen_hdd2 : if C_PCFG_HDD_COUNT>1 generate
i_hddraid_dbgcs.trig0(34 downto 30)<=i_hdd_dbgcs.sh(1).layer.trig0(34 downto 30);--llayer
i_hddraid_dbgcs.trig0(39 downto 35)<=i_hdd_dbgcs.sh(1).layer.trig0(39 downto 35);--tlayer
end generate gen_hdd2;

i_hddraid_dbgcs.trig0(40)<=i_hdd_rbuf_status.err_type.rambuf_full;
i_hddraid_dbgcs.trig0(41)<=i_hdd_rbuf_status.err_type.bufi_full;


--//-------- VIEW: ------------------
i_hddraid_dbgcs.data(28 downto 0)<=i_hdd_dbgcs.raid.data(28 downto 0);
i_hddraid_dbgcs.data(29)<=i_hdd_bufi_rst;

--//SH0
i_hddraid_dbgcs.data(34 downto 30)<=i_hdd_dbgcs.sh(0).layer.trig0(34 downto 30);--llayer
i_hddraid_dbgcs.data(39 downto 35)<=i_hdd_dbgcs.sh(0).layer.trig0(39 downto 35);--tlayer
i_hddraid_dbgcs.data(55 downto 40)<=tst_vbufo_dout(15 downto 0);--i_hdd_dbgcs.sh(0).layer.data(65 downto 50);
i_hddraid_dbgcs.data(56)          <=i_vbufo_empty;--i_hdd_dbgcs.sh(0).layer.data(49);--p_in_ll_rxd_wr; --llayer->tlayer
i_hddraid_dbgcs.data(57)          <=i_vbufo_pfull;--i_hdd_dbgcs.sh(0).layer.data(116);--p_in_ll_txd_rd; --llayer<-tlayer
i_hddraid_dbgcs.data(58)          <=i_vbufo_full;--i_hdd_dbgcs.sh(0).layer.data(118);--<=p_in_dbg.llayer.txbuf_status.aempty;
i_hddraid_dbgcs.data(59)          <=i_hdd_dbgcs.sh(0).layer.data(119);--<=p_in_dbg.llayer.txbuf_status.empty;
i_hddraid_dbgcs.data(60)          <='0';--i_hdd_dbgcs.sh(0).layer.data(98);--<=p_in_dbg.llayer.rxbuf_status.pfull;
i_hddraid_dbgcs.data(61)          <=i_hdd_dbgcs.sh(0).layer.data(99);--<=p_in_dbg.llayer.txbuf_status.pfull;
i_hddraid_dbgcs.data(62)          <='0';--i_hdd_dbgcs.sh(0).layer.data(117);--<=p_in_dbg.llayer.txd_close;

--//SH1
gen_hdd11 : if C_PCFG_HDD_COUNT=1 generate
i_hddraid_dbgcs.data(67 downto 63)<=i_hdd_dbgcs.sh(0).layer.trig0(34 downto 30);--llayer
i_hddraid_dbgcs.data(72 downto 68)<=i_hdd_dbgcs.sh(0).layer.trig0(39 downto 35);--tlayer
i_hddraid_dbgcs.data(88 downto 73)<=i_hdd_dbgcs.sh(0).layer.data(65 downto 50);
i_hddraid_dbgcs.data(89)          <='0';--i_hdd_dbgcs.sh(0).layer.data(49);--p_in_ll_rxd_wr; --llayer->tlayer
i_hddraid_dbgcs.data(90)          <='0';--i_hdd_dbgcs.sh(0).layer.data(116);--p_in_ll_txd_rd; --llayer<-tlayer
i_hddraid_dbgcs.data(91)          <='0';--i_hdd_dbgcs.sh(0).layer.data(118);--<=p_in_dbg.llayer.txbuf_status.aempty;
i_hddraid_dbgcs.data(92)          <=i_hdd_dbgcs.sh(0).layer.data(119);--<=p_in_dbg.llayer.txbuf_status.empty;
i_hddraid_dbgcs.data(93)          <='0';--i_hdd_dbgcs.sh(0).layer.data(98);--<=p_in_dbg.llayer.rxbuf_status.pfull;
i_hddraid_dbgcs.data(94)          <=i_hdd_dbgcs.sh(0).layer.data(99);--<=p_in_dbg.llayer.txbuf_status.pfull;
i_hddraid_dbgcs.data(95)          <='0';--i_hdd_dbgcs.sh(0).layer.data(117);--<=p_in_dbg.llayer.txd_close;
end generate gen_hdd11;
gen_hdd21 : if C_PCFG_HDD_COUNT>1 generate
i_hddraid_dbgcs.data(67 downto 63)<=i_hdd_dbgcs.sh(1).layer.trig0(34 downto 30);--llayer
i_hddraid_dbgcs.data(72 downto 68)<=i_hdd_dbgcs.sh(1).layer.trig0(39 downto 35);--tlayer
i_hddraid_dbgcs.data(88 downto 73)<=i_hdd_dbgcs.sh(1).layer.data(65 downto 50);
i_hddraid_dbgcs.data(89)          <='0';--i_hdd_dbgcs.sh(1).layer.data(49);--p_in_ll_rxd_wr; --llayer->tlayer
i_hddraid_dbgcs.data(90)          <='0';--i_hdd_dbgcs.sh(1).layer.data(116);--p_in_ll_txd_rd; --llayer<-tlayer
i_hddraid_dbgcs.data(91)          <='0';--i_hdd_dbgcs.sh(1).layer.data(118);--<=p_in_dbg.llayer.txbuf_status.aempty;
i_hddraid_dbgcs.data(92)          <=i_hdd_dbgcs.sh(1).layer.data(119);--<=p_in_dbg.llayer.txbuf_status.empty;
i_hddraid_dbgcs.data(93)          <='0';--i_hdd_dbgcs.sh(1).layer.data(98);--<=p_in_dbg.llayer.rxbuf_status.pfull;
i_hddraid_dbgcs.data(94)          <=i_hdd_dbgcs.sh(1).layer.data(99);--<=p_in_dbg.llayer.txbuf_status.pfull;
i_hddraid_dbgcs.data(95)          <='0';--i_hdd_dbgcs.sh(1).layer.data(117);--<=p_in_dbg.llayer.txd_close;
end generate gen_hdd21;

--//
i_hddraid_dbgcs.data(96) <=tst_hdd_bufi_out(2);--i_buf_wr_en;
i_hddraid_dbgcs.data(97) <=p_in_vout_vs when i_hdd_rbuf_cfg.dmacfg.hm_r='1' else i_vin_vs_hdd;--p_in_vin_vs;
i_hddraid_dbgcs.data(98) <=p_in_vout_hs when i_hdd_rbuf_cfg.dmacfg.hm_r='1' else i_vin_hs_hdd;--p_in_vin_hs;

i_hddraid_dbgcs.data(99) <=tst_hdd_bufi_empty;
i_hddraid_dbgcs.data(100)<=tst_hdd_bufi_full;
i_hddraid_dbgcs.data(101)<=tst_hdd_bufi_out(3);--<=OR_reduce(i_bufi_full);

i_hddraid_dbgcs.data(102)<=i_hdd_txbuf_pfull;
i_hddraid_dbgcs.data(103)<=i_hdd_txbuf_full;
i_hddraid_dbgcs.data(104)<=i_hdd_txbuf_empty;

i_hddraid_dbgcs.data(105)<=i_hdd_rxbuf_empty;

i_hddraid_dbgcs.data(106)<=i_hdd_rbuf_status.err_type.rambuf_full;
i_hddraid_dbgcs.data(107)<=i_hdd_rbuf_status.err_type.bufi_full;
i_hddraid_dbgcs.data(108)<=tst_hdd_rambuf_out(11);--<=tst_rambuf_empty;

--//SH2
i_hddraid_dbgcs.data(113 downto 109)<=i_hdd_dbgcs.sh(2).layer.trig0(34 downto 30);--llayer
i_hddraid_dbgcs.data(118 downto 114)<=i_hdd_dbgcs.sh(2).layer.trig0(39 downto 35);--tlayer
i_hddraid_dbgcs.data(124 downto 119)<=(others=>'0');--i_hdd_dbgcs.sh(2).layer.data(55 downto 50);--(65 downto 50);
i_hddraid_dbgcs.data(125)           <=tst_hdd_rambuf_out(24);--<=i_memw_start_hm_r;  --i_hdd_dbgcs.sh(2).layer.data(49);--p_in_ll_rxd_wr; --llayer->tlayer
i_hddraid_dbgcs.data(126)           <=tst_hdd_rambuf_out(25);--<=i_memw_stop_hm_r;   --i_hdd_dbgcs.sh(2).layer.data(116);--p_in_ll_txd_rd; --llayer<-tlayer
i_hddraid_dbgcs.data(127)           <='0';          --i_hdd_dbgcs.sh(2).layer.data(118);--<=p_in_dbg.llayer.txbuf_status.aempty;
i_hddraid_dbgcs.data(128)           <=i_hdd_dbgcs.sh(2).layer.data(119);--<=p_in_dbg.llayer.txbuf_status.empty;
i_hddraid_dbgcs.data(129)           <='0';          --i_hdd_dbgcs.sh(2).layer.data(98);--<=p_in_dbg.llayer.rxbuf_status.pfull;
i_hddraid_dbgcs.data(130)           <=i_hdd_dbgcs.sh(2).layer.data(99);--<=p_in_dbg.llayer.txbuf_status.pfull;
i_hddraid_dbgcs.data(131)           <='0';          --i_hdd_dbgcs.sh(2).layer.data(117);--<=p_in_dbg.llayer.txd_close;




--//SH3
i_hddraid_dbgcs.data(136 downto 132)<=i_hdd_dbgcs.sh(3).layer.trig0(34 downto 30);--llayer
i_hddraid_dbgcs.data(137)           <=i_hdd_dbgcs.measure.data(0);--i_dly_on(0);
i_hddraid_dbgcs.data(142 downto 138)<=i_hdd_dbgcs.sh(3).layer.trig0(39 downto 35);--tlayer
i_hddraid_dbgcs.data(148 downto 143)<=(others=>'0');--i_hdd_dbgcs.sh(3).layer.data(55 downto 50);--(65 downto 50);
i_hddraid_dbgcs.data(149)           <=tst_hdd_rambuf_out(23);--<=i_memr_start_hm_r          --i_hdd_dbgcs.sh(3).layer.data(49);--p_in_ll_rxd_wr; --llayer->tlayer
i_hddraid_dbgcs.data(150)           <='0';          --i_hdd_dbgcs.sh(3).layer.data(116);--p_in_ll_txd_rd; --llayer<-tlayer
i_hddraid_dbgcs.data(151)           <='0';          --i_hdd_dbgcs.sh(3).layer.data(118);--<=p_in_dbg.llayer.txbuf_status.aempty;
i_hddraid_dbgcs.data(152)           <=i_hdd_dbgcs.sh(3).layer.data(119);--<=p_in_dbg.llayer.txbuf_status.empty;
i_hddraid_dbgcs.data(153)           <='0';          --i_hdd_dbgcs.sh(3).layer.data(98);--<=p_in_dbg.llayer.rxbuf_status.pfull;
i_hddraid_dbgcs.data(154)           <=i_hdd_dbgcs.sh(3).layer.data(99);--<=p_in_dbg.llayer.txbuf_status.pfull;
i_hddraid_dbgcs.data(155)           <='0';          --i_hdd_dbgcs.sh(3).layer.data(117);--<=p_in_dbg.llayer.txd_close;

i_hddraid_dbgcs.data(156)<=i_mem_in_bank (CI_MEM_HDD)(C_MEMCH_WR).cmd_wr        ;--cmd for wr
i_hddraid_dbgcs.data(157)<=i_mem_in_bank (CI_MEM_HDD)(C_MEMCH_WR).txd_wr        ;
i_hddraid_dbgcs.data(158)<=i_mem_out_bank(CI_MEM_HDD)(C_MEMCH_WR).txbuf_err     ;
i_hddraid_dbgcs.data(159)<=i_mem_out_bank(CI_MEM_HDD)(C_MEMCH_WR).txbuf_underrun;
i_hddraid_dbgcs.data(160)<=i_mem_out_bank(CI_MEM_HDD)(C_MEMCH_WR).cmdbuf_err    ;
i_hddraid_dbgcs.data(161)<=i_mem_in_bank (CI_MEM_HDD)(C_MEMCH_RD).cmd_wr        ;--cmd for rd
i_hddraid_dbgcs.data(162)<=i_mem_in_bank (CI_MEM_HDD)(C_MEMCH_RD).rxd_rd        ;
i_hddraid_dbgcs.data(163)<=i_mem_out_bank(CI_MEM_HDD)(C_MEMCH_RD).rxbuf_err     ;
i_hddraid_dbgcs.data(164)<=i_mem_out_bank(CI_MEM_HDD)(C_MEMCH_RD).rxbuf_overflow;
i_hddraid_dbgcs.data(165)<=i_mem_out_bank(CI_MEM_HDD)(C_MEMCH_RD).cmdbuf_err    ;

i_hddraid_dbgcs.data(168 downto 166)<=tst_hdd_rambuf_out(9 downto 7);--mem_rd/fsm_cs
i_hddraid_dbgcs.data(171 downto 169)<=tst_hdd_rambuf_out(4 downto 2);--mem_wr/fsm_cs
i_hddraid_dbgcs.data(172)<=tst_hdd_rambuf_out(13);-- <=i_hm_w_padding;

process(i_hdd_dbgcs.raid.clk)
begin
  if i_hdd_dbgcs.raid.clk'event and i_hdd_dbgcs.raid.clk='1' then
    tst_hdd_bufi_empty<=i_hdd_bufi_empty;
    tst_hdd_bufi_full<=i_hdd_bufi_full;
    tst_vbufo_dout<=i_vbufo_dout;
  end if;
end process;

end generate gen_raid_dbgcs;
end generate gen_hdd_dbgcs;

gen_vctrl_dbgcs : if strcmp(C_PCFG_VCTRL_DBGCS,"ON") generate

--//### DBG VCTRL: ########
m_dbgcs_icon : dbgcs_iconx1
port map(
CONTROL0 => i_dbgcs_vctrl
);

m_dbgcs_sh0_raid : dbgcs_sata_raid
port map(
CONTROL => i_dbgcs_vctrl,
CLK     => g_hclk,
DATA    => i_vctrl_dbgcs.data(172 downto 0),
TRIG0   => i_vctrl_dbgcs.trig0(41 downto 0)
);

--//-------- TRIG: ------------------
i_vctrl_dbgcs.trig0(0)            <=tst_vctrl_out(0)         ;--vwriter(0)<=p_in_cfg_mem_start;
i_vctrl_dbgcs.trig0(1)            <=tst_vctrl_out(1)         ;--vwriter(1)<=i_mem_done;
i_vctrl_dbgcs.trig0(4 downto 2)   <=tst_vctrl_out(4 downto 2);--vwriter(4 downto 2)<=tst_fsm_cs;
i_vctrl_dbgcs.trig0(5)            <=tst_vctrl_out(5)         ;--vreader(0)<=p_in_cfg_mem_start;
i_vctrl_dbgcs.trig0(6)            <=tst_vctrl_out(6)         ;--vreader(1)<=i_mem_done;
i_vctrl_dbgcs.trig0(9 downto 7)   <=tst_vctrl_out(9 downto 7);--vreader(4 downto 2)<=tst_fsm_cs;
i_vctrl_dbgcs.trig0(10)           <=tst_vctrl_out(14)        ;--  <=i_vwr_fr_rdy(0);
i_vctrl_dbgcs.trig0(11)           <=tst_vctrl_out(15)        ;--  <=i_vrd_hold(0);
i_vctrl_dbgcs.trig0(12)           <=p_in_vin_vs;
i_vctrl_dbgcs.trig0(13)           <=p_in_vin_hs;
i_vctrl_dbgcs.trig0(14)           <=p_in_vout_vs;
i_vctrl_dbgcs.trig0(15)           <=p_in_vout_hs;
i_vctrl_dbgcs.trig0(16)           <=i_mem_out_bank(CI_MEM_VCTRL)(C_MEMCH_WR).txbuf_err or i_mem_out_bank(CI_MEM_VCTRL)(C_MEMCH_WR).txbuf_underrun or i_mem_out_bank(CI_MEM_VCTRL)(C_MEMCH_WR).cmdbuf_err; --tst_hdd_bufi_out(1);--i_buf_wr;;--
i_vctrl_dbgcs.trig0(17)           <=i_mem_out_bank(CI_MEM_VCTRL)(C_MEMCH_RD).rxbuf_err or i_mem_out_bank(CI_MEM_VCTRL)(C_MEMCH_RD).rxbuf_overflow or i_mem_out_bank(CI_MEM_VCTRL)(C_MEMCH_RD).cmdbuf_err; --tst_hdd_bufi_out(2);--i_buf_wr_en;--
i_vctrl_dbgcs.trig0(18)           <=i_vbufo_empty;   --
i_vctrl_dbgcs.trig0(19)           <=i_vctrl_bufi_full;--err: bufi overflow
i_vctrl_dbgcs.trig0(20)           <=i_vbufo_empty or i_vbufo_full or i_vctrl_bufi_full or tst_vctrl_bufi_out(3);
i_vctrl_dbgcs.trig0(21)           <=tst_vctrl_out(22);--i_vrd_fr_rddone;--
i_vctrl_dbgcs.trig0(22)           <=i_vbufo_full;
i_vctrl_dbgcs.trig0(23)           <=i_vctrl_bufi_rst;
i_vctrl_dbgcs.trig0(24)           <=tst_vctrl_out(23);--<=i_vch_off;
i_vctrl_dbgcs.trig0(41 downto 25) <=(others=>'0');


--//-------- VIEW: ------------------
i_vctrl_dbgcs.data(0)             <=tst_vctrl_out(0)         ;--vwriter(0)<=p_in_cfg_mem_start;
i_vctrl_dbgcs.data(1)             <=tst_vctrl_out(1)         ;--vwriter(1)<=i_mem_done;
i_vctrl_dbgcs.data(4 downto 2)    <=tst_vctrl_out(4 downto 2);--vwriter(4 downto 2)<=tst_fsm_cs;
i_vctrl_dbgcs.data(5)             <=tst_vctrl_out(5)         ;--vreader(0)<=p_in_cfg_mem_start;
i_vctrl_dbgcs.data(6)             <=tst_vctrl_out(6)         ;--vreader(1)<=i_mem_done;
i_vctrl_dbgcs.data(9 downto 7)    <=tst_vctrl_out(9 downto 7);--vreader(4 downto 2)<=tst_fsm_cs;
i_vctrl_dbgcs.data(10)            <=tst_vctrl_out(14)        ;--  <=i_vwr_fr_rdy(0);/ram_start
i_vctrl_dbgcs.data(11)            <=tst_vctrl_out(15)        ;--  <=i_vrd_hold(0);
i_vctrl_dbgcs.data(13 downto 12)  <=tst_vctrl_out(11 downto 10);--<=i_vbuf_wr(0);
i_vctrl_dbgcs.data(15 downto 14)  <=tst_vctrl_out(13 downto 12);--<=i_vbuf_rd(0);
i_vctrl_dbgcs.data(16)            <=tst_vctrl_out(22);        --<=i_vrd_fr_rddone;--
i_vctrl_dbgcs.data(17)            <=i_vctrl_bufi_rst;--i_vctrl_rst;
i_vctrl_dbgcs.data(18)            <=p_in_vin_vs;
i_vctrl_dbgcs.data(19)            <=p_in_vin_hs;
i_vctrl_dbgcs.data(20)            <=p_in_vout_vs;
i_vctrl_dbgcs.data(21)            <=p_in_vout_hs;

i_vctrl_dbgcs.data(27 downto 22)  <=(others=>'0');--i_mem_in_bank (CI_MEM_VCTRL)(C_MEMCH_WR).cmd_bl       ;
i_vctrl_dbgcs.data(28)            <=i_mem_in_bank (CI_MEM_VCTRL)(C_MEMCH_WR).cmd_wr        ;
i_vctrl_dbgcs.data(29)            <=i_mem_in_bank (CI_MEM_VCTRL)(C_MEMCH_WR).txd_wr        ;
i_vctrl_dbgcs.data(30)            <='0';
i_vctrl_dbgcs.data(31)            <=i_mem_out_bank(CI_MEM_VCTRL)(C_MEMCH_WR).txbuf_err     ;
i_vctrl_dbgcs.data(32)            <=i_mem_out_bank(CI_MEM_VCTRL)(C_MEMCH_WR).txbuf_underrun;
i_vctrl_dbgcs.data(33)            <=i_mem_out_bank(CI_MEM_VCTRL)(C_MEMCH_WR).cmdbuf_err    ;--i_mem_out_bank(CI_MEM_VCTRL)(C_MEMCH_WR).txbuf_empty  ;
i_vctrl_dbgcs.data(40 downto 34)  <=(others=>'0');--i_mem_out_bank(CI_MEM_VCTRL)(C_MEMCH_WR).txbuf_wrcount;
i_vctrl_dbgcs.data(46 downto 41)  <=(others=>'0');--i_mem_in_bank (CI_MEM_VCTRL)(C_MEMCH_RD).cmd_bl       ;
i_vctrl_dbgcs.data(47)            <=i_mem_in_bank (CI_MEM_VCTRL)(C_MEMCH_RD).cmd_wr        ;
i_vctrl_dbgcs.data(48)            <=i_mem_in_bank (CI_MEM_VCTRL)(C_MEMCH_RD).rxd_rd        ;
i_vctrl_dbgcs.data(49)            <='0';
i_vctrl_dbgcs.data(50)            <=i_mem_out_bank(CI_MEM_VCTRL)(C_MEMCH_RD).rxbuf_err     ;
i_vctrl_dbgcs.data(51)            <=i_mem_out_bank(CI_MEM_VCTRL)(C_MEMCH_RD).rxbuf_overflow;
i_vctrl_dbgcs.data(52)            <=i_mem_out_bank(CI_MEM_VCTRL)(C_MEMCH_RD).cmdbuf_err    ;--i_mem_out_bank(CI_MEM_VCTRL)(C_MEMCH_RD).rxbuf_empty  ;
i_vctrl_dbgcs.data(59 downto 53)  <=(others=>'0');--i_mem_out_bank(CI_MEM_VCTRL)(C_MEMCH_RD).rxbuf_rdcount;

i_vctrl_dbgcs.data(60)            <=i_vbufo_full;
i_vctrl_dbgcs.data(61)            <=i_vbufo_empty;
i_vctrl_dbgcs.data(62)            <=i_vctrl_bufi_full;
i_vctrl_dbgcs.data(63)            <=i_vctrl_bufi_empty;
i_vctrl_dbgcs.data(64)            <=i_vbufo_pfull;
i_vctrl_dbgcs.data(65)            <=tst_vctrl_bufi_out(3);--OR_reduce(i_bufi_full);

i_vctrl_dbgcs.data(66)            <=tst_vctrl_out(23);-- <=tst_vwr_out(5);-- <=i_padding;
i_vctrl_dbgcs.data(67)            <='0';--tst_vctrl_out(24);-- <=tst_vwr_out(6);-- <=i_vbufin_rd_rdy_n;

i_vctrl_dbgcs.data(71 downto 68)  <=(others=>'0');--tst_vctrl_out(28 downto 25);--write <=tst_fsmstate;;

i_vctrl_dbgcs.data(72)            <='0';--i_hdd_rbuf_cfg.dmacfg.hm_r;

i_vctrl_dbgcs.data(74 downto 73)  <=(others=>'0');
i_vctrl_dbgcs.data(75)            <='0';--tst_hdd_rambuf_out(10);--<=tst_hw_stop;
i_vctrl_dbgcs.data(76)            <='0';--tst_hdd_rambuf_out(11);--<=tst_rambuf_empty;
i_vctrl_dbgcs.data(77)            <='0';
i_vctrl_dbgcs.data(78)            <='0';
i_vctrl_dbgcs.data(79)            <='0';
i_vctrl_dbgcs.data(95 downto 80)  <=(others=>'0');

i_vctrl_dbgcs.data(96)            <='0';--tst_vctrl_out(16);--<=tst_vwr_out(5);--<=i_mem_cmden;
i_vctrl_dbgcs.data(97)            <='0';--tst_vctrl_out(17);--<=tst_vrd_out(5);--<=i_mem_cmden;
i_vctrl_dbgcs.data(98)            <='0';
i_vctrl_dbgcs.data(99)            <='0';

i_vctrl_dbgcs.data(131 downto 100) <=(others=>'0');--i_mem_in_bank (CI_MEM_VCTRL)(C_MEMCH_WR).txd(31 downto 0);--i_vctrl_bufi_dout
i_vctrl_dbgcs.data(163 downto 132) <=(others=>'0');--i_mem_out_bank(CI_MEM_VCTRL)(C_MEMCH_RD).rxd(31 downto 0);--i_vctrl_bufo_din;--Rx

i_vctrl_dbgcs.data(164)            <='0';
i_vctrl_dbgcs.data(165)            <='0';
i_vctrl_dbgcs.data(166)            <='0';
i_vctrl_dbgcs.data(167)            <='0';
i_vctrl_dbgcs.data(168)            <='0';
i_vctrl_dbgcs.data(169)            <='0';
i_vctrl_dbgcs.data(170)            <='0';
i_vctrl_dbgcs.data(171)            <='0';
i_vctrl_dbgcs.data(172)            <='0';

end generate gen_vctrl_dbgcs;

--END MAIN
end architecture;
