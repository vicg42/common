-------------------------------------------------------------------------
-- Company     : Linkos
-- Engineer    : Golovachenko Victor
--
-- Create Date : 18.01.2012 17:24:28
-- Module Name : hdd_main
--
-- Назначение/Описание :
--
-- Управление модулем hdd через порт p_in_cam_ctrl (биты и коды команд см. hdd_main_cfg.vhd) :
-- Выдача видео: VCH_ON
-- Остановка видео: VCH_OFF
-- Запись видео: VCH_OFF + HDD_WR
-- Чтение видео: VCH_OFF + HDD_RD
-- Тест HDD: VCH_OFF + HDD_TEST
-- Остановка записи/чтения/теста: HDD_STOP
-- Изменение частоты кадров камера: VCH_OFF + VCH_ON с новым параметром fps
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
use work.prj_cfg.all;
use work.cfgdev_pkg.all;
use work.sata_glob_pkg.all;
use work.dsn_hdd_pkg.all;
use work.hdd_main_unit_pkg.all;
use work.video_ctrl_pkg.all;
use work.mem_ctrl_pkg.all;
use work.sata_pkg.all;


entity hdd_main is
generic(
G_SIM : string:="OFF"
);
port(
--------------------------------------------------
--VideoIN
--------------------------------------------------
p_in_vd             : in   std_logic_vector(C_PCFG_VIN_DWIDTH-1 downto 0);
p_in_vin_vs         : in   std_logic;--Строб кадровой синхронизации (КСИ)
p_in_vin_hs         : in   std_logic;--Строб строчной синхронизации (ССИ)
p_in_vin_clk        : in   std_logic;--Пиксельная частота
p_in_ext_syn        : in   std_logic;--Внешняя синхронизация записи

--------------------------------------------------
--VideoOUT
--------------------------------------------------
p_out_vd            : out  std_logic_vector(C_PCFG_VOUT_DWIDTH-1 downto 0);
p_in_vout_vs        : in   std_logic;--Строб кадровой синхронизации (КСИ)
p_in_vout_hs        : in   std_logic;--Строб строчной синхронизации (ССИ)
p_in_vout_clk       : in   std_logic;--Пиксельная частота

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
p_in_usr_clk        : in    std_logic; --частота тактирования p_in_usr_txd/rxd/tx_wr/rx_rd
p_in_usr_tx_wr      : in    std_logic;
p_in_usr_rx_rd      : in    std_logic;
p_in_usr_txd        : in    std_logic_vector(15 downto 0);--HOST->HDD
p_out_usr_rxd       : out   std_logic_vector(15 downto 0);--HOST<-HDD
p_out_usr_status    : out   std_logic_vector(7  downto 0);

--Управление от модуля camemra.v
p_in_cam_ctrl       : in    std_logic_vector(15 downto 0);

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
--p_in_tst                    : in    std_logic_vector(31 downto 0);

--------------------------------------------------
--Технологический порт
--------------------------------------------------
----Интрефейс с USB(FTDI)
--p_inout_ftdi_d      : inout std_logic_vector(7 downto 0);
--p_out_ftdi_rd_n     : out   std_logic;
--p_out_ftdi_wr_n     : out   std_logic;
--p_in_ftdi_txe_n     : in    std_logic;
--p_in_ftdi_rxf_n     : in    std_logic;
--p_in_ftdi_pwren_n   : in    std_logic;

p_out_TP            : out   std_logic_vector(7 downto 0); --вывод на контрольные точки платы
p_out_led           : out   std_logic_vector(7 downto 0)  --выход на свтодиоды платы
);
end entity;

architecture struct of hdd_main is

component gt_clkbuf is
port(
p_in_clkp  : in    std_logic;
p_in_clkn  : in    std_logic;
p_out_clk  : out   std_logic;
p_in_opt   : in    std_logic_vector(3 downto 0);
p_out_opt  : out   std_logic_vector(3 downto 0)
);
end component;

function sel_memphy(x: integer) return integer is
begin
  if x = 0 then
    return 1;
  else
    return 0;
  end if;
end function sel_memphy;

constant CI_MEMOPT         : integer:=selval(1, 2, strcmp(C_PCFG_MEMOPT, "OFF"));
constant CI_MEM_BANK_M_BIT : integer:=C_MEMCTRL_AWIDTH+1;
constant CI_MEM_BANK_L_BIT : integer:=C_MEMCTRL_AWIDTH+1;
constant CI_MEM_AWIDTH     : integer:=32;
constant CI_MEM_DWIDTH     : integer:=C_MEMCTRL_DWIDTH * CI_MEMOPT;

constant CI_SLBA_DEFAULT   : integer:=16#00000000#;--Start LBA
constant CI_ELBA_DEFAULT   : integer:=16#1DC00000#;--End LBA  (SizeHDD*1GB)/512=(238*C_1GB)/512;
constant CI_SCOUNT_DEFAULT : integer:=selval(1,1024, strcmp(G_SIM,"ON"));


type TCfgFSM_state is (
S_IDLE,
S_HDD_ELBA,
S_HDD_DLY0,
S_HDD_CMD,
S_HDD_DLY1,
S_HDD_DONE
);
signal fsm_hddctrl                      : TCfgFSM_state;

type TPktD is array (0 to C_HDDPKT_DCOUNT-1) of std_logic_vector(15 downto 0);
signal i_hdd_pkt_d                      : TPktD;
signal i_hdd_pkt_dcnt                   : std_logic_vector(6 downto 0);
signal i_hdd_pkt_wr                     : std_logic;
signal i_hdd_pkt                        : std_logic_vector(15 downto 0);

signal i_hdd_cmd_wr                     : std_logic;
signal i_hdd_cmd_test                   : std_logic;
signal i_hdd_cmd_clr_err                : std_logic;
signal i_hdd_cmd_clr_err_cnt            : std_logic_vector(3 downto 0);
signal i_hdd_clr_err                    : std_logic;
signal i_hdd_msk                        : std_logic_vector(C_HDDPKT_SATA_CS_M_BIT-C_HDDPKT_SATA_CS_L_BIT downto 0);
signal i_hdd_raid_cmd                   : std_logic_vector(C_HDDPKT_RAIDCMD_M_BIT-C_HDDPKT_RAIDCMD_L_BIT downto 0);
signal i_hdd_sata_cmd                   : std_logic_vector(C_HDDPKT_SATACMD_M_BIT-C_HDDPKT_SATACMD_L_BIT downto 0);
signal i_hdd_cmd_ata                    : std_logic_vector(7 downto 0);
signal i_hdd_lba                        : std_logic_vector(47 downto 0);
signal i_hdd_lba_bp                     : std_logic_vector(47 downto 0);
signal i_hdd_lba_bp_out                 : std_logic_vector(47 downto 0);

signal i_usr_status                     : std_logic_vector(1 downto 0);
signal i_vfr_prm                        : TFrXY;
signal i_cam_ctrl                       : std_logic_vector(31 downto 0);
signal i_cam_ctrl_hdd                   : std_logic_vector(C_CAM_CTRL_HDD_MODE_M_BIT-C_CAM_CTRL_HDD_MODE_L_BIT downto 0);
signal i_cam_ctrl_fps                   : std_logic_vector(C_CAM_CTRL_MODE_FPS_M_BIT-C_CAM_CTRL_MODE_FPS_L_BIT downto 0);
type TSrCamCtrlHdd is array (0 to 1) of std_logic_vector(i_cam_ctrl_hdd'range);
signal sr_cam_ctrl_hdd                  : TSrCamCtrlHdd;
signal i_cam_ctrl_vch_on                : std_logic;

signal i_vin_d                          : std_logic_vector(C_PCFG_VIN_DWIDTH-1 downto 0);
signal i_vin_vs                         : std_logic;
signal i_vin_hs                         : std_logic;
signal sr_vin_vs                        : std_logic_vector(0 to 2);
signal i_vin_vs_fedge                   : std_logic;
signal i_vin_vs_redge                   : std_logic;

signal i_vbufi_ext_sync                 : std_logic;
signal i_vbufi_vsync                    : TVSync;
signal i_vbufi_rd                       : std_logic_vector(1 downto 0);
signal i_vbufi_dout                     : std_logic_vector(CI_MEM_DWIDTH-1 downto 0);
signal i_vbufi_full                     : std_logic;
signal i_vbufi_empty                    : std_logic;

signal i_vbufo_dout                     : std_logic_vector(C_PCFG_VOUT_DWIDTH-1 downto 0);
signal i_vbufo_full                     : std_logic;
signal i_vbufo_empty                    : std_logic;
signal i_vbufo_vsync                    : TVSync;

signal i_vctrl_bufo_din                 : std_logic_vector(CI_MEM_DWIDTH-1 downto 0);
signal i_vctrl_bufo_wr                  : std_logic;
signal i_vctrl_vwr_off                  : std_logic;
signal i_vctrl_vrd_off                  : std_logic;

signal i_hdd_bufo_din                   : std_logic_vector(CI_MEM_DWIDTH-1 downto 0);
signal i_hdd_bufo_wr                    : std_logic;

signal i_mem_ctrl_status                : TMEMCTRL_status;
signal i_mem_ctrl_sysin                 : TMEMCTRL_sysin;
signal i_mem_ctrl_sysout                : TMEMCTRL_sysout;

signal i_mem_in_bank                    : TMemINBank;
signal i_mem_out_bank                   : TMemOUTBank;
signal i_mem_in                         : TMemINBank;
signal i_mem_out                        : TMemOUTBank;
signal i_mem_mux_sel                    : std_logic;
signal i_phymem_out                     : TMEMCTRL_phy_outs;
signal i_phymem_inout                   : TMEMCTRL_phy_inouts;

signal g_hclk                           : std_logic;
signal g_vbufi_wrclk                    : std_logic;
signal g_cfg_clk                        : std_logic;

signal sr_hdd_hr                        : std_logic_vector(0 to 1);
signal sr_vch_rst                       : std_logic_vector(0 to 1);
signal i_vbufi_rst                      : std_logic;
signal i_vbufo_rst                      : std_logic;
signal i_vctrl_rst                      : std_logic;
signal i_hdd_rambuf_rst                 : std_logic;
signal i_sys_rst_cnt                    : std_logic_vector(5 downto 0):=(others=>'0');
signal i_sys_rst                        : std_logic;
signal i_sys_rst2                       : std_logic;
signal i_hdd_rst                        : std_logic;
signal i_cfg_rst                        : std_logic;

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
signal i_cfg_sel                        : std_logic;

signal g_sata_refclkout                 : std_logic;
signal i_hdd_gt_refclk150               : std_logic_vector(C_SH_COUNT_MAX(C_PCFG_HDD_COUNT-1)-1 downto 0);
signal i_hdd_dcm_lock                   : std_logic;
signal g_hdd_dcm_gclk300M               : std_logic;
signal g_hdd_dcm_gclk150M               : std_logic;

signal i_hdd_rbuf_cfg                   : THDDRBufCfg;
signal i_hdd_rbuf_status                : THDDRBufStatus;

signal i_hdd_txbuf_di                   : std_logic_vector(CI_MEM_DWIDTH-1 downto 0);
signal i_hdd_txbuf_wr                   : std_logic;
signal i_hdd_txbuf_pfull                : std_logic;

signal i_hdd_rxbuf_do                   : std_logic_vector(CI_MEM_DWIDTH-1 downto 0);
signal i_hdd_rxbuf_rd                   : std_logic;
signal i_hdd_rxbuf_empty                : std_logic;

signal sr_hdd_rdy                       : std_logic_vector(0 to 2);
signal i_hdd_rdy_redge                  : std_logic;
signal i_hdd_rdy                        : std_logic;
signal i_hdd_err                        : std_logic;
signal i_hdd_bsy                        : std_logic;
signal i_hdd_tx_rdy                     : std_logic;
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

signal i_hdd_led_off                    : std_logic;

signal i_test01_led                     : std_logic;
signal i_test02_led                     : std_logic;

signal tst_vbufi_in                     : std_logic_vector(31 downto 0);
signal tst_cfg_tstout                   : std_logic_vector(31 downto 0);
signal tst_vbufo_out                    : std_logic_vector(31 downto 0);
signal tst_vbufi_out                    : std_logic_vector(31 downto 0);
signal tst_hdd_rambuf_out               : std_logic_vector(31 downto 0);
signal tst_vctrl_out                    : std_logic_vector(31 downto 0);

signal tst_mem_err                      : std_logic;

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
    DATA : IN STD_LOGIC_VECTOR(255 downto 0); --(122 DOWNTO 0);
    TRIG0 : IN STD_LOGIC_VECTOR(49 DOWNTO 0)
    );
end component;

signal i_dbgcs_hwcfg                    : std_logic_vector(35 downto 0);
signal i_dbgcs_sh0_spd                  : std_logic_vector(35 downto 0);
signal i_dbgcs_hdd0_layer               : std_logic_vector(35 downto 0);
signal i_dbgcs_hdd1_layer               : std_logic_vector(35 downto 0);
signal i_dbgcs_hdd_raid                 : std_logic_vector(35 downto 0);
signal i_dbgcs_vctrl                    : std_logic_vector(35 downto 0);
signal i_dbgcs_vin                      : std_logic_vector(35 downto 0);
signal i_dbgcs_vout                     : std_logic_vector(35 downto 0);
signal i_vout_dbgcs                     : TSH_ila;
signal i_hdd0layer_dbgcs                : TSH_ila;
signal i_hdd1layer_dbgcs                : TSH_ila;
signal i_hddraid_dbgcs                  : TSH_ila;

signal tst_vin_vs_edge_i                : std_logic:='0';
signal tst_vin_vs_edge2_i               : std_logic:='0';
signal sr_hddbufi_rst                   : std_logic_vector(0 to 1):=(others=>'0');
signal tst_hddbufi_rst_fedge            : std_logic:='0';
signal tst_hddbufi_rst_redge            : std_logic:='0';
signal tst_fsm_hddctrl                  : std_logic_vector(2 downto 0);
--signal tst_start_wr                     : std_logic;



--//MAIN
begin


--***********************************************************
--STATUS
--***********************************************************
p_out_usr_status(0)<=i_usr_status(0);--i_usr_rx_rdy (HOST<-HDD)
p_out_usr_status(1)<=i_usr_status(1);--i_usr_tx_rdy (HOST->HDD)
p_out_usr_status(2)<=i_hdd_rdy and AND_reduce(i_mem_ctrl_status.rdy);
p_out_usr_status(3)<=i_hdd_err;
p_out_usr_status(4)<=i_hdd_bsy and not i_hdd_err;
p_out_usr_status(7 downto 5)<=CONV_STD_LOGIC_VECTOR(C_PCFG_HDD_COUNT, 3);


--***********************************************************
--Инициализация
--***********************************************************
i_mem_mux_sel<=tst_hdd_rambuf_out(12);
i_vctrl_vwr_off <=sr_vch_rst(1) or not i_cam_ctrl(C_CAM_CTRL_HDD_VDOUT_BIT);
i_vctrl_vrd_off <=sr_vch_rst(0) or not i_cam_ctrl(C_CAM_CTRL_HDD_VDOUT_BIT);

i_vbufi_ext_sync<=p_in_ext_syn or i_cam_ctrl_vch_on;

tst_vbufi_in(0)<='1' when i_cam_ctrl_fps=CONV_STD_LOGIC_VECTOR(C_CAM_CTRL_480FPS, i_cam_ctrl_fps'length) and
                          (i_hdd_rbuf_cfg.dmacfg.hm_w='1' and i_hdd_cmd_test='0') else '0';
tst_vbufi_in(tst_vbufi_in'length-1 downto 1)<=CONV_STD_LOGIC_VECTOR(0, tst_vbufi_in'length-1);

i_vin_vs<=p_in_vin_vs;
i_vin_hs<=p_in_vin_hs;
i_vin_d <=p_in_vd;
p_out_vd<=(others=>'0') when i_hdd_rbuf_cfg.dmacfg.hm_w='1' else i_vbufo_dout;

i_hdd_tst_in(23 downto  0)<=(others=>'0');
i_hdd_tst_in(31 downto 24)<=CONV_STD_LOGIC_VECTOR(C_PCFG_HSCAM_HDD_VERSION, 8);

i_cam_ctrl<=EXT(p_in_cam_ctrl, i_cam_ctrl'length);
i_cam_ctrl_fps<=i_cam_ctrl(C_CAM_CTRL_MODE_FPS_M_BIT downto C_CAM_CTRL_MODE_FPS_L_BIT);

i_hdd_led_off<=i_cam_ctrl(C_CAM_CTRL_HDD_LEDOFF_BIT);
i_sys_rst2<=i_cam_ctrl(C_CAM_CTRL_HDD_RST_BIT);


--***********************************************************
--CLOCK
--***********************************************************
i_mem_ctrl_sysin.clk<=g_hdd_dcm_gclk300M;
--частота для переписывания данных внутренних буферов модулей m_vctrl_bufi, m_hdd_bufi
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
i_sys_rst <= i_sys_rst_cnt(i_sys_rst_cnt'high - 1) or i_sys_rst2;
i_cfg_rst <= i_sys_rst;
i_hdd_rst <= i_sys_rst;
i_vctrl_rst<=i_sys_rst or not i_mem_ctrl_sysout.pll_lock;
i_hdd_rambuf_rst<=i_vctrl_rst;
i_vbufo_rst<=i_vctrl_rst or XOR_reduce(sr_hdd_hr(0 to 1)) or XOR_reduce(sr_vch_rst(0 to 1));
i_vbufi_rst<=(i_hdd_rbuf_cfg.dmacfg.hm_w and not i_hdd_tx_rdy and not i_hdd_cmd_test) or XOR_reduce(sr_vch_rst(0 to 1));

--формирую сигналы для управления сбросами вх/вых видео буферов
process(i_vctrl_rst,g_hclk)
begin
  if i_vctrl_rst='1' then
    sr_hdd_hr<=(others=>'0');
    sr_vch_rst(1)<='1';
  elsif g_hclk'event and g_hclk='1' then
    sr_hdd_hr(0)<=i_hdd_rbuf_cfg.dmacfg.hm_r;
    sr_hdd_hr(1)<=sr_hdd_hr(0);
    sr_vch_rst(1)<=sr_vch_rst(0);
  end if;
end process;
sr_vch_rst(0)<=not i_cam_ctrl_vch_on;

process(i_hdd_rambuf_rst,g_hclk)
begin
  if i_hdd_rambuf_rst='1' then
    i_hdd_tx_rdy<='0';
  elsif g_hclk'event and g_hclk='1' then
    if i_hdd_rbuf_cfg.dmacfg.hm_w='0' then
      i_hdd_tx_rdy<='0';
    else
      if i_hdd_rbuf_cfg.dmacfg.hm_w='1' then
          if i_hdd_rbuf_cfg.dmacfg.atacmdw='1' then
            i_hdd_tx_rdy<='1';
          end if;
      end if;
    end if;
  end if;
end process;


--***********************************************************
--Команды управления
--***********************************************************
i_hdd_pkt_d(0)(C_HDDPKT_SATA_CS_M_BIT downto C_HDDPKT_SATA_CS_L_BIT)<=i_hdd_msk;
i_hdd_pkt_d(0)(C_HDDPKT_RAIDCMD_M_BIT downto C_HDDPKT_RAIDCMD_L_BIT)<=i_hdd_raid_cmd;
i_hdd_pkt_d(0)(C_HDDPKT_RAIDCMD_M_BIT+1)<='0';
i_hdd_pkt_d(0)(C_HDDPKT_SATACMD_M_BIT downto C_HDDPKT_SATACMD_L_BIT)<=i_hdd_sata_cmd;
i_hdd_pkt_d(0)(C_HDDPKT_SATACMD_M_BIT+1)<='0';
i_hdd_pkt_d(1)<=(others=>'0');
i_hdd_pkt_d(2)<=i_hdd_lba(16*(0+1)-1 downto 16*0);
i_hdd_pkt_d(3)<=i_hdd_lba(16*(1+1)-1 downto 16*1);
i_hdd_pkt_d(4)<=i_hdd_lba(16*(2+1)-1 downto 16*2);
i_hdd_pkt_d(5)<=CONV_STD_LOGIC_VECTOR(CI_SCOUNT_DEFAULT, i_hdd_pkt_d(5)'length);
i_hdd_pkt_d(6)<=CONV_STD_LOGIC_VECTOR(16#40#, i_hdd_pkt_d(6)'length);
i_hdd_pkt_d(7)<=EXT(i_hdd_cmd_ata, i_hdd_pkt_d(7)'length);
i_hdd_pkt_d(8)<=CONV_STD_LOGIC_VECTOR(16#01#, i_hdd_pkt_d(8)'length);

process(i_vctrl_rst,g_hclk)
begin
  if i_vctrl_rst='1' then
    for i in 0 to sr_cam_ctrl_hdd'length-1 loop
    sr_cam_ctrl_hdd(i)<=(others=>'0');
    end loop;
    i_cam_ctrl_hdd<=(others=>'0');
    sr_hdd_rdy<=(others=>'0');
  elsif g_hclk'event and g_hclk='1' then
    i_cam_ctrl_hdd<=i_cam_ctrl(C_CAM_CTRL_HDD_MODE_M_BIT downto C_CAM_CTRL_HDD_MODE_L_BIT);
    sr_cam_ctrl_hdd<=i_cam_ctrl_hdd & sr_cam_ctrl_hdd(0 to 0);
    sr_hdd_rdy<=(i_hdd_rdy and AND_reduce(i_mem_ctrl_status.rdy)) & sr_hdd_rdy(0 to 1);
  end if;
end process;

i_hdd_rdy_redge<=sr_hdd_rdy(1) and not sr_hdd_rdy(2);

--Сброс ошибок HDD
process(i_vctrl_rst,g_hclk)
begin
  if i_vctrl_rst='1' then
    i_hdd_cmd_clr_err_cnt<=(others=>'0');
    i_hdd_cmd_clr_err<='0';
  elsif g_hclk'event and g_hclk='1' then
    if i_hdd_clr_err='1' or i_hdd_rdy_redge='1' then
      i_hdd_cmd_clr_err_cnt<=(others=>'0');
      i_hdd_cmd_clr_err<='1';
    elsif i_hdd_cmd_clr_err_cnt=CONV_STD_LOGIC_VECTOR(16#F#, i_hdd_cmd_clr_err_cnt'length) then
      i_hdd_cmd_clr_err_cnt<=(others=>'0');
      i_hdd_cmd_clr_err<='0';
    elsif i_hdd_cmd_clr_err='1' then
      i_hdd_cmd_clr_err_cnt<=i_hdd_cmd_clr_err_cnt + 1;
    end if;
  end if;
end process;

process(i_vctrl_rst,g_hclk)
begin
  if i_vctrl_rst='1' then

    fsm_hddctrl<=S_IDLE;

    i_hdd_pkt_dcnt<=(others=>'0');
    i_hdd_pkt_wr<='0';
    i_hdd_pkt<=(others=>'0');

    i_hdd_cmd_wr<='0';
    i_hdd_cmd_test<='0';
    i_hdd_clr_err<='0';

    i_hdd_msk<=(others=>'0');
    i_hdd_raid_cmd<=(others=>'0');
    i_hdd_sata_cmd<=(others=>'0');
    i_hdd_lba<=(others=>'0');
    i_hdd_lba_bp<=CONV_STD_LOGIC_VECTOR(CI_ELBA_DEFAULT, i_hdd_lba_bp'length);
    i_hdd_cmd_ata<=(others=>'0');

    i_cam_ctrl_vch_on<='0';

  elsif g_hclk'event and g_hclk='1' then

    case fsm_hddctrl is

      --------------------------------
      --Анализ принятой команды
      --------------------------------
      when S_IDLE =>

        i_hdd_msk<=(others=>'0');
        i_hdd_raid_cmd<=CONV_STD_LOGIC_VECTOR(C_RAIDCMD_LBAEND, i_hdd_raid_cmd'length);
        i_hdd_sata_cmd<=CONV_STD_LOGIC_VECTOR(C_SATACMD_NULL, i_hdd_sata_cmd'length);
        i_hdd_cmd_ata<=(others=>'0');
        i_hdd_pkt_dcnt<=(others=>'0');

        if sr_cam_ctrl_hdd(0)/=sr_cam_ctrl_hdd(1) then
            if    sr_cam_ctrl_hdd(0)=CONV_STD_LOGIC_VECTOR(C_CAM_CTRL_HDD_WR, sr_cam_ctrl_hdd(0)'length) then
              i_hdd_lba<=CONV_STD_LOGIC_VECTOR(CI_ELBA_DEFAULT, i_hdd_lba'length);
              i_hdd_cmd_wr<='1';
              fsm_hddctrl<= S_HDD_ELBA;

            elsif sr_cam_ctrl_hdd(0)=CONV_STD_LOGIC_VECTOR(C_CAM_CTRL_HDD_RD, sr_cam_ctrl_hdd(0)'length) then
              i_hdd_lba<=i_hdd_lba_bp;
              i_hdd_cmd_wr<='0';
              fsm_hddctrl<= S_HDD_ELBA;

            elsif sr_cam_ctrl_hdd(0)=CONV_STD_LOGIC_VECTOR(C_CAM_CTRL_HDD_TEST, sr_cam_ctrl_hdd(0)'length) then
              i_hdd_lba<=CONV_STD_LOGIC_VECTOR(CI_ELBA_DEFAULT, i_hdd_lba'length);
              i_hdd_cmd_test<='1';
              i_hdd_cmd_wr<='1';
              fsm_hddctrl<= S_HDD_ELBA;

            elsif sr_cam_ctrl_hdd(0)=CONV_STD_LOGIC_VECTOR(C_CAM_CTRL_VCH_ON, sr_cam_ctrl_hdd(0)'length) then
              i_cam_ctrl_vch_on<='1';

            elsif sr_cam_ctrl_hdd(0)=CONV_STD_LOGIC_VECTOR(C_CAM_CTRL_VCH_OFF, sr_cam_ctrl_hdd(0)'length) then
              i_cam_ctrl_vch_on<='0';
              i_hdd_clr_err<='1';

            end if;
        else
          i_hdd_cmd_wr<='0';
          i_hdd_clr_err<='0';
        end if;

      --------------------------------
      --Установка конечного адреса LBA
      --------------------------------
      when S_HDD_ELBA =>

        for i in 0 to i_hdd_pkt_d'length-1 loop
          if i_hdd_pkt_dcnt=i then
            i_hdd_pkt<=i_hdd_pkt_d(i);
          end if;
        end loop;

        if i_hdd_pkt_dcnt=CONV_STD_LOGIC_VECTOR(i_hdd_pkt_d'length-1, i_hdd_pkt_dcnt'length) then
          i_hdd_pkt_dcnt<=(others=>'0');
          fsm_hddctrl<= S_HDD_DLY0;
        else
          i_hdd_pkt_wr<='1';
          i_hdd_pkt_dcnt<=i_hdd_pkt_dcnt + 1;
        end if;

      when S_HDD_DLY0 =>

        i_hdd_pkt_wr<='0';
        if i_hdd_pkt_dcnt=CONV_STD_LOGIC_VECTOR(16#F#, i_hdd_pkt_dcnt'length) then
          i_hdd_pkt_dcnt<=(others=>'0');
          for i in 0 to C_PCFG_HDD_COUNT-1 loop
          i_hdd_msk(i)<='1';
          end loop;
          i_hdd_raid_cmd<=CONV_STD_LOGIC_VECTOR(C_RAIDCMD_HW, i_hdd_raid_cmd'length);
          i_hdd_sata_cmd<=CONV_STD_LOGIC_VECTOR(C_SATACMD_ATACOMMAND, i_hdd_sata_cmd'length);
          i_hdd_lba<=CONV_STD_LOGIC_VECTOR(CI_SLBA_DEFAULT, i_hdd_lba'length);

          if i_hdd_cmd_wr='1' then
          i_hdd_cmd_ata<=CONV_STD_LOGIC_VECTOR(C_ATA_CMD_WRITE_DMA_EXT, i_hdd_cmd_ata'length);
          else
          i_hdd_cmd_ata<=CONV_STD_LOGIC_VECTOR(C_ATA_CMD_READ_DMA_EXT, i_hdd_cmd_ata'length);
          end if;

          fsm_hddctrl<= S_HDD_CMD;
        else
          i_hdd_pkt_dcnt<=i_hdd_pkt_dcnt + 1;
        end if;

      --------------------------------
      --Установка АТА команды
      --------------------------------
      when S_HDD_CMD =>

        for i in 0 to i_hdd_pkt_d'length-1 loop
          if i_hdd_pkt_dcnt=i then
            i_hdd_pkt<=i_hdd_pkt_d(i);
          end if;
        end loop;

        if i_hdd_pkt_dcnt=CONV_STD_LOGIC_VECTOR(i_hdd_pkt_d'length-1, i_hdd_pkt_dcnt'length) then
          i_hdd_pkt_dcnt<=(others=>'0');
          fsm_hddctrl<= S_HDD_DLY1;
        else
          i_hdd_pkt_wr<='1';
          i_hdd_pkt_dcnt<=i_hdd_pkt_dcnt + 1;
        end if;

      when S_HDD_DLY1 =>

        i_hdd_pkt_wr<='0';
        if i_hdd_pkt_dcnt=CONV_STD_LOGIC_VECTOR(80, i_hdd_pkt_dcnt'length) then
          i_hdd_pkt_dcnt<=(others=>'0');
          fsm_hddctrl<= S_HDD_DONE;
        else
          i_hdd_pkt_dcnt<=i_hdd_pkt_dcnt + 1;
        end if;


      --------------------------------
      --Анализ завершения работы HDD
      --------------------------------
      when S_HDD_DONE =>

        if i_hdd_bsy='0' or i_hdd_err='1' then
          if i_hdd_err='0' then
            i_hdd_clr_err<='1';
          end if;
          i_hdd_lba_bp<=i_hdd_lba_bp_out;
          i_hdd_cmd_test<='0';
          fsm_hddctrl<= S_IDLE;

        elsif sr_cam_ctrl_hdd(0)/=sr_cam_ctrl_hdd(1) then
          if sr_cam_ctrl_hdd(0)=CONV_STD_LOGIC_VECTOR(C_CAM_CTRL_HDD_STOP, sr_cam_ctrl_hdd(0)'length) then
            i_hdd_msk<=(others=>'0');
            i_hdd_raid_cmd<=CONV_STD_LOGIC_VECTOR(C_RAIDCMD_STOP, i_hdd_raid_cmd'length);
            i_hdd_sata_cmd<=CONV_STD_LOGIC_VECTOR(C_SATACMD_NULL, i_hdd_sata_cmd'length);
            fsm_hddctrl<= S_HDD_CMD;
          end if;
        end if;

    end case;

  end if;
end process;


--***********************************************************
--VIDEO IN
--***********************************************************
m_bufi : vin
generic map(
G_VBUF_IWIDTH => C_PCFG_VIN_DWIDTH,
G_VBUF_OWIDTH => CI_MEM_DWIDTH,
G_VSYN_ACTIVE => C_PCFG_VSYN_ACTIVE
)
port map(
--Вх. видеопоток
p_in_vd            => i_vin_d,
p_in_vs            => i_vin_vs,
p_in_hs            => i_vin_hs,
p_in_vclk          => p_in_vin_clk,
p_in_ext_syn       => i_vbufi_ext_sync,

p_out_vfr_prm      => i_vfr_prm,

--Вых. видеопоток
p_out_vsync        => i_vbufi_vsync,
p_out_vbufi_d      => i_vbufi_dout,
p_in_vbufi_rd      => OR_reduce(i_vbufi_rd),--i_vbufi_rd,
p_out_vbufi_empty  => i_vbufi_empty,
p_out_vbufi_full   => i_vbufi_full,
p_in_vbufi_wrclk   => g_vbufi_wrclk,
p_in_vbufi_rdclk   => g_hclk,

--Технологический
p_in_tst           => tst_vbufi_in,
p_out_tst          => tst_vbufi_out,

--System
p_in_rst           => i_vbufi_rst
);


--***********************************************************
--Выдача видео на монитор
--***********************************************************
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
p_in_vfr_prm      => i_vfr_prm,
p_in_mem_trn_len  => i_hdd_rbuf_cfg.mem_trn,
p_in_vwr_off      => i_vctrl_vwr_off,
p_in_vrd_off      => i_vctrl_vrd_off,

----------------------------
--Связь с вх/вых видеобуферами
----------------------------
--in
p_in_vbufi_s      => i_vbufi_vsync,
p_in_vbufi_d      => i_vbufi_dout,
p_out_vbufi_rd    => i_vbufi_rd(0),
p_in_vbufi_empty  => i_vbufi_empty,
--out
p_in_vbufo_s      => i_vbufo_vsync,
p_out_vbufo_d     => i_vctrl_bufo_din,
p_out_vbufo_wr    => i_vctrl_bufo_wr,
p_in_vbufo_full   => i_vbufo_full,

---------------------------------
--Связь с mem_ctrl.vhd
---------------------------------
--CH WRITE
p_out_memwr       => i_mem_in (0)(C_MEMCH_WR),--TMemIN ;
p_in_memwr        => i_mem_out(0)(C_MEMCH_WR),--TMemOUT;
--CH READ
p_out_memrd       => i_mem_in (0)(C_MEMCH_RD),--TMemIN ;
p_in_memrd        => i_mem_out(0)(C_MEMCH_RD),--TMemOUT;

-------------------------------
--Технологический
-------------------------------
p_out_tst         => tst_vctrl_out,

-------------------------------
--System
-------------------------------
p_in_clk          => g_hclk,
p_in_rst          => i_vctrl_rst
);


--***********************************************************
--VIDEO BUFOUT
--***********************************************************
m_bufo : vout
generic map(
G_VBUF_IWIDTH => CI_MEM_DWIDTH,
G_VBUF_OWIDTH => C_PCFG_VOUT_DWIDTH,
G_VSYN_ACTIVE => C_PCFG_VSYN_ACTIVE
)
port map(
--Вых. видеопоток
p_out_vd         => i_vbufo_dout,--p_out_vd,
p_in_vs          => p_in_vout_vs,
p_in_hs          => p_in_vout_hs,
p_in_vclk        => p_in_vout_clk,

--Вх. видеопоток
p_in_vd          => i_vctrl_bufo_din,
p_in_vd_wr       => i_vctrl_bufo_wr,
p_in_hd          => i_hdd_bufo_din,
p_in_hd_wr       => i_hdd_bufo_wr,
p_in_sel         => i_hdd_rbuf_cfg.dmacfg.hm_r,

p_out_vbufo_full => i_vbufo_full,
p_out_vbufo_empty=> i_vbufo_empty,
p_in_vbufo_wrclk => g_hclk,
p_out_vsync      => i_vbufo_vsync,

--Технологический
p_in_tst         => (others=>'0'),
p_out_tst        => tst_vbufo_out,

--System
p_in_rst         => i_vbufo_rst
);



--***********************************************************
--Контроллер ОЗУ
--***********************************************************
m_mem_mux : mem_mux
generic map(
G_MEMBANK_0 => C_PCFG_MEMBANK_0,
G_MEMBANK_1 => C_PCFG_MEMBANK_1,
G_SIM => G_SIM
)
port map(
------------------------------------
--Управление
------------------------------------
p_in_sel      => i_mem_mux_sel,

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
  m_ibufds : gt_clkbuf
  port map(
  p_in_clkp  => p_in_sata_clk_p(i),
  p_in_clkn  => p_in_sata_clk_n(i),
  p_out_clk  => i_hdd_gt_refclk150(i),
  p_in_opt   => (others=>'0'),
  p_out_opt  => open
  );
end generate gen_sata_gt;

m_hdd : dsn_hdd
generic map(
G_MEM_DWIDTH => CI_MEM_DWIDTH,
G_RAID_DWIDTH=> C_PCFG_HDD_RAID_DWIDTH,
G_MODULE_USE => "ON",
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
p_out_hdd_rdy         => i_hdd_rdy,
p_out_hdd_error       => i_hdd_err,
p_out_hdd_busy        => i_hdd_bsy,
p_out_hdd_lba_bp      => i_hdd_lba_bp_out,
p_in_hdd_test         => i_hdd_cmd_test,
p_in_hdd_clr_err      => i_hdd_cmd_clr_err,

-------------------------------
--Связь с Источниками/Приемниками данных накопителя
-------------------------------
p_out_rbuf_cfg        => i_hdd_rbuf_cfg,
p_in_rbuf_status      => i_hdd_rbuf_status,

p_in_sh_cxd           => i_hdd_pkt,
p_in_sh_cxd_wr        => i_hdd_pkt_wr,

p_in_hdd_txd_wrclk    => g_hclk,
p_in_hdd_txd          => i_hdd_txbuf_di,
p_in_hdd_txd_wr       => i_hdd_txbuf_wr,
p_out_hdd_txbuf_pfull => i_hdd_txbuf_pfull,
--p_out_hdd_txbuf_full  => i_hdd_txbuf_full,
--p_out_hdd_txbuf_empty => i_hdd_txbuf_empty,

p_in_hdd_rxd_rdclk    => g_hclk,
p_out_hdd_rxd         => i_hdd_rxbuf_do,
p_in_hdd_rxd_rd       => i_hdd_rxbuf_rd,
p_out_hdd_rxbuf_empty => i_hdd_rxbuf_empty,
--p_out_hdd_rxbuf_pempty=> i_hdd_rxbuf_pempty,

-------------------------------
--Sata Driver
-------------------------------
p_out_sata_txn        => p_out_sata_txn,
p_out_sata_txp        => p_out_sata_txp,
p_in_sata_rxn         => p_in_sata_rxn,
p_in_sata_rxp         => p_in_sata_rxp,

p_in_sata_refclk      => i_hdd_gt_refclk150,
p_out_sata_refclkout  => g_sata_refclkout,
p_out_sata_gt_plldet  => open,
p_out_sata_dcm_lock   => i_hdd_dcm_lock,
p_out_sata_dcm_gclk2div=> open,
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
p_out_sim_hdd_busy          <= i_hdd_bsy;
p_out_sim_gt_txdata         <= i_hdd_sim_gt_txdata        ; --open,--
p_out_sim_gt_txcharisk      <= i_hdd_sim_gt_txcharisk     ; --open,--
p_out_sim_gt_txcomstart     <= i_hdd_sim_gt_txcomstart    ; --open,--
i_hdd_sim_gt_rxdata         <= p_in_sim_gt_rxdata         ;
i_hdd_sim_gt_rxcharisk      <= p_in_sim_gt_rxcharisk      ;
i_hdd_sim_gt_rxstatus       <= p_in_sim_gt_rxstatus       ;
i_hdd_sim_gt_rxelecidle     <= p_in_sim_gt_rxelecidle     ;
i_hdd_sim_gt_rxdisperr      <= p_in_sim_gt_rxdisperr      ;
i_hdd_sim_gt_rxnotintable   <= p_in_sim_gt_rxnotintable   ;
i_hdd_sim_gt_rxbyteisaligned<= p_in_sim_gt_rxbyteisaligned;
p_out_gt_sim_rst            <= i_hdd_sim_gt_sim_rst       ; --open,--
p_out_gt_sim_clk            <= i_hdd_sim_gt_sim_clk       ; --open,--


m_hdd_rambuf : dsn_hdd_rambuf
generic map(
G_MEMOPT     => C_PCFG_MEMOPT,
G_MODULE_USE => "ON",
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
p_in_bufi_dout        => i_vbufi_dout,
p_out_bufi_rd         => i_vbufi_rd(1),
p_in_bufi_empty       => i_vbufi_empty,
p_in_bufi_full        => i_vbufi_full,
p_in_bufi_pfull       => '0',
p_in_bufi_wrcnt       => (others=>'0'),

p_out_bufo_din        => i_hdd_bufo_din,
p_out_bufo_wr         => i_hdd_bufo_wr,
p_in_bufo_full        => i_vbufo_full,
p_in_bufo_empty       => i_vbufo_empty,

----------------------------
--Связь с модулем HDD
----------------------------
p_out_hdd_txd         => i_hdd_txbuf_di,
p_out_hdd_txd_wr      => i_hdd_txbuf_wr,
p_in_hdd_txbuf_pfull  => i_hdd_txbuf_pfull,
p_in_hdd_txbuf_full   => '0',--i_hdd_txbuf_full,
p_in_hdd_txbuf_empty  => '0',--i_hdd_txbuf_empty,

p_in_hdd_rxd          => i_hdd_rxbuf_do,
p_out_hdd_rxd_rd      => i_hdd_rxbuf_rd,
p_in_hdd_rxbuf_empty  => i_hdd_rxbuf_empty,
p_in_hdd_rxbuf_pempty => '0',--i_hdd_rxbuf_pempty,

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
p_in_tst              => (others=>'0'),
p_out_tst             => tst_hdd_rambuf_out,
p_out_dbgcs           => open,

-------------------------------
--System
-------------------------------
p_in_clk              => g_hclk,
p_in_rst              => i_hdd_rambuf_rst
);


--***********************************************************
--Интерфейс управления модулем
--***********************************************************
gen_cfg_sim_off : if strcmp(G_SIM,"OFF") generate

m_usrif : hdd_usrif
generic map(
C_USRIF => "HOST",
C_CFG_DBGCS => "OFF",
G_SIM => G_SIM
)
port map(
-------------------------------------------------
--Порт управления модулем + Статусы
--------------------------------------------------
--Управление HDD от camera.v
p_in_usr_clk         => p_in_usr_clk,
p_in_usr_tx_wr       => p_in_usr_tx_wr,
p_in_usr_rx_rd       => p_in_usr_rx_rd,
p_in_usr_txd         => p_in_usr_txd,
p_out_usr_rxd        => p_out_usr_rxd,
p_out_usr_status     => i_usr_status,

-------------------------------
--связь с DSN_HDD.VHD
-------------------------------
p_out_cfg_adr        => i_cfg_adr,
p_out_cfg_adr_ld     => i_cfg_adr_ld,
p_out_cfg_adr_fifo   => i_cfg_adr_fifo,
p_out_cfg_wr         => i_cfg_wr,
p_out_cfg_rd         => i_cfg_rd,
p_out_cfg_txdata     => i_cfg_txd,
p_in_cfg_rxdata      => i_cfg_rxd,
p_in_cfg_txrdy       => i_cfg_txrdy,
p_in_cfg_rxrdy       => i_cfg_rxrdy,

p_out_cfg_done       => i_cfg_done,

p_in_cfg_clk         => g_cfg_clk,
p_in_cfg_rst         => i_cfg_rst,

-------------------------------
--Технологический
-------------------------------
p_in_tst             => (others=>'0'),
p_out_tst            => tst_cfg_tstout
);
end generate gen_cfg_sim_off;

gen_cfg_sim_on : if strcmp(G_SIM,"ON") generate
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

end generate gen_cfg_sim_on;



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
p_in_clk       => g_hdd_dcm_gclk150M,
p_in_rst       => i_sys_rst
);

m_blink2 : fpga_test_01
generic map(
G_BLINK_T05   =>10#250#, -- 1/2 периода мигания светодиода.(время в ms)
G_CLK_T05us   =>10#75#   -- 05us - 150MHz
)
port map(
p_out_test_led => i_test02_led,
p_out_test_done=> open,

p_out_1us      => open,
p_out_1ms      => open,
-------------------------------
--System
-------------------------------
p_in_clk       => p_in_vin_clk,
p_in_rst       => i_sys_rst
);

--HDD LEDs:
--SATA0 (На плате SATA1)
p_out_led(2)<=(((i_hdd_dbgled(0).wr  and not i_hdd_dbgled(0).err) or (i_hdd_dbgled(0).link and i_hdd_dbgled(0).err)) and not i_hdd_led_off);
p_out_led(4)<=(((i_hdd_dbgled(0).rdy and not i_hdd_dbgled(0).err) or (i_test01_led         and i_hdd_dbgled(0).err)) and not i_hdd_led_off);
p_out_TP(0) <=i_test01_led;
p_out_TP(1) <=i_hdd_dbgled(0).busy;

--SATA1 (На плате SATA0)
p_out_led(3)<=(((i_hdd_dbgled(1).wr  and not i_hdd_dbgled(1).err) or (i_hdd_dbgled(1).link and i_hdd_dbgled(1).err)) and not i_hdd_led_off);
p_out_led(5)<=(((i_hdd_dbgled(1).rdy and not i_hdd_dbgled(1).err) or (i_test01_led         and i_hdd_dbgled(1).err)) and not i_hdd_led_off);
p_out_TP(2) <=i_test02_led;
p_out_TP(3) <=i_hdd_dbgled(1).busy;

--SATA2 (На плате SATA3)
p_out_led(0)<=(((i_hdd_dbgled(2).wr  and not i_hdd_dbgled(2).err) or (i_hdd_dbgled(2).link and i_hdd_dbgled(2).err)) and not i_hdd_led_off);
p_out_led(7)<=(((i_hdd_dbgled(2).rdy and not i_hdd_dbgled(2).err) or (i_test01_led         and i_hdd_dbgled(2).err)) and not i_hdd_led_off);
p_out_TP(4) <=(not i_vbufi_empty and not i_vctrl_vwr_off) when tst_mem_err='0' else  i_test01_led;
p_out_TP(5) <=i_hdd_dbgled(2).busy;

--SATA3 (На плате SATA2)
p_out_led(1)<=(((i_hdd_dbgled(3).wr  and not i_hdd_dbgled(3).err) or (i_hdd_dbgled(3).link and i_hdd_dbgled(3).err)) and not i_hdd_led_off);
p_out_led(6)<=(((i_hdd_dbgled(3).rdy and not i_hdd_dbgled(3).err) or (i_test01_led         and i_hdd_dbgled(3).err)) and not i_hdd_led_off);
p_out_TP(6) <=AND_reduce(i_mem_ctrl_status.rdy);
p_out_TP(7) <=i_hdd_dbgled(3).busy;

tst_mem_err<=i_mem_out_bank(C_PCFG_MEMBANK_0)(C_MEMCH_WR).txbuf_err or i_mem_out_bank(C_PCFG_MEMBANK_0)(C_MEMCH_WR).txbuf_underrun or
             i_mem_out_bank(C_PCFG_MEMBANK_0)(C_MEMCH_RD).rxbuf_err or i_mem_out_bank(C_PCFG_MEMBANK_0)(C_MEMCH_RD).rxbuf_overflow or
             i_mem_out_bank(C_PCFG_MEMBANK_1)(C_MEMCH_WR).txbuf_err or i_mem_out_bank(C_PCFG_MEMBANK_1)(C_MEMCH_WR).txbuf_underrun or
             i_mem_out_bank(C_PCFG_MEMBANK_1)(C_MEMCH_RD).rxbuf_err or i_mem_out_bank(C_PCFG_MEMBANK_1)(C_MEMCH_RD).rxbuf_overflow;




--################################################
--ChipScope DBG:
--################################################
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
DATA    => i_hdd_dbgcs.sh(0).layer.data(255 downto 0),--(122 downto 0),
TRIG0   => i_hdd0layer_dbgcs.trig0(49 downto 0)
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
DATA    => i_hdd_dbgcs.sh(0).layer.data(255 downto 0),--(122 downto 0),
TRIG0   => i_hdd1layer_dbgcs.trig0(49 downto 0)
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
DATA    => i_hdd_dbgcs.sh(1).layer.data(255 downto 0),--(122 downto 0),
TRIG0   => i_hdd1layer_dbgcs.trig0(49 downto 0)
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
m_dbgcs_icon : dbgcs_iconx2
port map(
CONTROL0 => i_dbgcs_hdd_raid,
CONTROL1 => i_dbgcs_hwcfg
);

--m_dbgcs_hwcfg : dbgcs_sata_layer
--port map
--(
--CONTROL => i_dbgcs_hwcfg,
--CLK     => i_hdd_dbgcs.hwcfg.clk,
--DATA    => i_hdd_dbgcs.hwcfg.data(122 downto 0),
--TRIG0   => i_hdd_dbgcs.hwcfg.trig0(41 downto 0)
--);
m_dbgcs_hwcfg : dbgcs_sata_layer
port map
(
CONTROL => i_dbgcs_hwcfg,
CLK     => p_in_vin_clk,--p_in_vout_clk,
DATA    => i_vout_dbgcs.data(122 downto 0),
TRIG0   => i_vout_dbgcs.trig0(41 downto 0)
);
--//-------- TRIG: ------------------
i_vout_dbgcs.trig0(0)<='0';
i_vout_dbgcs.trig0(1)<=p_in_vout_hs;
i_vout_dbgcs.trig0(2)<=tst_vbufo_out(0);--i_hd_mrk;
i_vout_dbgcs.trig0(3)<=tst_vbufo_out(1);--i_buf_rd_en;
i_vout_dbgcs.trig0(4)<=tst_vbufo_out(2);--i_vs_edge
i_vout_dbgcs.trig0(5)<=tst_vbufo_out(3);--i_hd_vden
i_vout_dbgcs.trig0(6)<=i_vbufo_empty;
i_vout_dbgcs.trig0(7)<=p_in_vout_vs;
i_vout_dbgcs.trig0(8)<=p_in_ext_syn;

i_vout_dbgcs.trig0(9)<=i_vin_hs;
i_vout_dbgcs.trig0(10)<=i_vin_vs;
i_vout_dbgcs.trig0(11)<=i_vbufi_empty;
i_vout_dbgcs.trig0(12)<=tst_vbufi_out(5);--i_det_ext_syn;
i_vout_dbgcs.trig0(13)<=tst_vbufi_out(2);--i_bufi_wr_en;
i_vout_dbgcs.trig0(14)<=i_vin_vs_fedge;
i_vout_dbgcs.trig0(15)<=i_vin_vs_redge;
i_vout_dbgcs.trig0(16)<=tst_vbufo_out(4);--i_vs_edge2
i_vout_dbgcs.trig0(17)<=i_hdd_rbuf_cfg.dmacfg.hw_mode;

i_vout_dbgcs.trig0(i_vout_dbgcs.trig0'high downto 18)<=(others=>'0');


--//-------- VIEW: ------------------
i_vout_dbgcs.data(15 downto 0)<=i_vbufo_dout(15 downto 0);
i_vout_dbgcs.data(16)<=p_in_vout_vs;
i_vout_dbgcs.data(17)<=p_in_vout_hs;
i_vout_dbgcs.data(18)<=tst_vbufo_out(0);--i_hd_mrk;
i_vout_dbgcs.data(19)<=tst_vbufo_out(1);--i_buf_rd_en;
i_vout_dbgcs.data(20)<=tst_vbufo_out(2);--i_vs_edge
i_vout_dbgcs.data(21)<=tst_vbufo_out(3);--i_hd_vden
i_vout_dbgcs.data(22)<=i_vbufo_empty;
i_vout_dbgcs.data(23)<=p_in_ext_syn;
i_vout_dbgcs.data(26 downto 24)<=i_cam_ctrl(15 downto 13);

i_vout_dbgcs.data(27)<=i_vin_hs;
i_vout_dbgcs.data(28)<=i_vin_vs;
i_vout_dbgcs.data(29)<=i_vbufi_empty;
i_vout_dbgcs.data(30)<=tst_vbufi_out(5);--i_det_ext_syn;
i_vout_dbgcs.data(31)<=tst_vbufi_out(2);--i_bufi_wr_en;

i_vout_dbgcs.data(44 downto 32)<=i_cam_ctrl(12 downto 0);

i_vout_dbgcs.data(45)<=i_vbufi_ext_sync;
i_vout_dbgcs.data(46)<='0';

i_vout_dbgcs.data(i_vout_dbgcs.data'high downto 47)<=(others=>'0');


m_dbgcs_sh0_raid : dbgcs_sata_raid
port map(
CONTROL => i_dbgcs_hdd_raid,
CLK     => i_hdd_dbgcs.raid.clk,
DATA    => i_hddraid_dbgcs.data(255 downto 0),
TRIG0   => i_hddraid_dbgcs.trig0(49 downto 0)
);

--//-------- TRIG: ------------------
i_hddraid_dbgcs.trig0(11 downto 0)<=i_hdd_dbgcs.raid.trig0(11 downto 0);
i_hddraid_dbgcs.trig0(12)<=i_mem_out_bank(C_PCFG_MEMBANK_0)(C_MEMCH_WR).txbuf_err or i_mem_out_bank(C_PCFG_MEMBANK_0)(C_MEMCH_WR).txbuf_underrun;
i_hddraid_dbgcs.trig0(13)<=i_mem_out_bank(C_PCFG_MEMBANK_0)(C_MEMCH_RD).rxbuf_err or i_mem_out_bank(C_PCFG_MEMBANK_0)(C_MEMCH_RD).rxbuf_overflow;
i_hddraid_dbgcs.trig0(14)<=    sr_vch_rst(0) and  not sr_vch_rst(1);--tst_redge;
i_hddraid_dbgcs.trig0(15)<=not sr_vch_rst(0) and      sr_vch_rst(1);--tst_fedge;
i_hddraid_dbgcs.trig0(16)<=i_hdd_dbgcs.raid.trig0(16);--p_in_usr_cxd_wr;
i_hddraid_dbgcs.trig0(17)<=i_hdd_rbuf_status.err_type.rambuf_full or i_hdd_rbuf_status.err_type.bufi_full or
                           (i_hdd_rbuf_cfg.dmacfg.hm_w and i_vbufi_full) or (i_hdd_rbuf_cfg.dmacfg.hm_r and i_vbufo_empty);
i_hddraid_dbgcs.trig0(18)<=i_hdd_dbgcs.raid.trig0(18);--dev_done
i_hddraid_dbgcs.trig0(19)<=i_vbufi_empty;

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
i_hddraid_dbgcs.trig0(41)<=p_in_vout_hs;
i_hddraid_dbgcs.trig0(42)<=i_hdd_rbuf_cfg.dmacfg.hm_w and OR_reduce(i_vbufi_rd);--start hdd_wr
i_hddraid_dbgcs.trig0(43)<=i_hdd_rbuf_cfg.dmacfg.hm_r and i_hdd_bufo_wr;--start hdd_rd
i_hddraid_dbgcs.trig0(44)<=i_hdd_dbgcs.raid.trig0(17);--i_cmdpkt_get_done
i_hddraid_dbgcs.trig0(45)<=i_hdd_dbgcs.raid.trig0(16);--p_in_usr_cxd_wr;
i_hddraid_dbgcs.trig0(46)<=tst_hddbufi_rst_fedge;
i_hddraid_dbgcs.trig0(47)<=tst_hddbufi_rst_redge;
i_hddraid_dbgcs.trig0(48)<=tst_vctrl_out(14);--i_vwr_fr_rdy
i_hddraid_dbgcs.trig0(49)<=i_mem_in_bank (C_PCFG_MEMBANK_0)(C_MEMCH_WR).txd_wr or i_mem_in_bank (C_PCFG_MEMBANK_0)(C_MEMCH_RD).rxd_rd;


--//-------- VIEW: ------------------
i_hddraid_dbgcs.data(28 downto 0)<=i_hdd_dbgcs.raid.data(28 downto 0);
i_hddraid_dbgcs.data(29)<=(i_vbufo_rst or i_vbufi_rst);

--//SH0
i_hddraid_dbgcs.data(34 downto 30)<=i_hdd_dbgcs.sh(0).layer.trig0(34 downto 30);--llayer
i_hddraid_dbgcs.data(39 downto 35)<=i_hdd_dbgcs.sh(0).layer.trig0(39 downto 35);--tlayer
i_hddraid_dbgcs.data(55 downto 40)<=i_hdd_dbgcs.sh(0).layer.data(65 downto 50);--tst_vbufo_dout(15 downto 0);-- i_hdd_bufo_din(7 downto 0)&tst_vbufo_dout(7  downto 0);--
i_hddraid_dbgcs.data(56)          <=i_vbufo_empty;--i_hdd_dbgcs.sh(0).layer.data(49);--p_in_ll_rxd_wr; --llayer->tlayer
i_hddraid_dbgcs.data(57)          <=i_vbufo_full;--i_hdd_dbgcs.sh(0).layer.data(116);--p_in_ll_txd_rd; --llayer<-tlayer
i_hddraid_dbgcs.data(58)          <='0';--i_hdd_dbgcs.sh(0).layer.data(118);--<=p_in_dbg.llayer.txbuf_status.aempty;
i_hddraid_dbgcs.data(59)          <=i_hdd_dbgcs.sh(0).layer.data(119);--<=p_in_dbg.llayer.txbuf_status.empty;
i_hddraid_dbgcs.data(60)          <=tst_vbufi_out(5);--i_det_ext_syn; --i_hdd_dbgcs.sh(0).layer.data(98);--<=p_in_dbg.llayer.rxbuf_status.pfull;
i_hddraid_dbgcs.data(61)          <=i_hdd_dbgcs.sh(0).layer.data(99);--<=p_in_dbg.llayer.txbuf_status.pfull;
i_hddraid_dbgcs.data(62)          <='0';--i_hdd_dbgcs.sh(0).layer.data(117);--<=p_in_dbg.llayer.txd_close;

--//SH1
gen_hdd11 : if C_PCFG_HDD_COUNT=1 generate
i_hddraid_dbgcs.data(67 downto 63)<=i_hdd_dbgcs.sh(0).layer.trig0(34 downto 30);--llayer
i_hddraid_dbgcs.data(72 downto 68)<=i_hdd_dbgcs.sh(0).layer.trig0(39 downto 35);--tlayer
i_hddraid_dbgcs.data(88 downto 73)<=i_hdd_dbgcs.sh(0).layer.data(81 downto 66);--i_hdd_dbgcs.sh(0).layer.data(65 downto 50);
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
i_hddraid_dbgcs.data(88 downto 73)<=i_hdd_dbgcs.sh(0).layer.data(81 downto 66);--i_hdd_rxbuf_do(7 downto 0)&i_hdd_txbuf_di(7 downto 0);--i_hdd_dbgcs.sh(1).layer.data(65 downto 50);
i_hddraid_dbgcs.data(89)          <=p_in_vout_hs;--i_hdd_dbgcs.sh(1).layer.data(49);--p_in_ll_rxd_wr; --llayer->tlayer
i_hddraid_dbgcs.data(90)          <=p_in_vout_vs;--i_hdd_dbgcs.sh(1).layer.data(116);--p_in_ll_txd_rd; --llayer<-tlayer
i_hddraid_dbgcs.data(91)          <='0';--i_hdd_dbgcs.sh(1).layer.data(118);--<=p_in_dbg.llayer.txbuf_status.aempty;
i_hddraid_dbgcs.data(92)          <=i_hdd_dbgcs.sh(1).layer.data(119);--<=p_in_dbg.llayer.txbuf_status.empty;
i_hddraid_dbgcs.data(93)          <='0';--i_hdd_dbgcs.sh(1).layer.data(98);--<=p_in_dbg.llayer.rxbuf_status.pfull;
i_hddraid_dbgcs.data(94)          <=i_hdd_dbgcs.sh(1).layer.data(99);--<=p_in_dbg.llayer.txbuf_status.pfull;
i_hddraid_dbgcs.data(95)          <='0';--i_hdd_dbgcs.sh(1).layer.data(117);--<=p_in_dbg.llayer.txd_close;
end generate gen_hdd21;

--//
i_hddraid_dbgcs.data(96) <=tst_vbufi_out(2);--i_bufi_wr_en;
i_hddraid_dbgcs.data(97) <=i_vin_vs;
i_hddraid_dbgcs.data(98) <=i_vin_hs;

i_hddraid_dbgcs.data(99) <=i_vbufi_empty;
i_hddraid_dbgcs.data(100)<=i_vbufi_full;
i_hddraid_dbgcs.data(101)<=tst_vbufi_out(3);--OR_reduce(i_bufi_full);

i_hddraid_dbgcs.data(102)<=i_hdd_txbuf_pfull;
i_hddraid_dbgcs.data(103)<='0';--i_hdd_txbuf_full;
i_hddraid_dbgcs.data(104)<=i_hdd_dbgcs.raid.data(21);--i_hdd_txbuf_empty;

i_hddraid_dbgcs.data(105)<=i_hdd_rxbuf_empty;

i_hddraid_dbgcs.data(106)<=i_hdd_rbuf_status.err_type.rambuf_full;
i_hddraid_dbgcs.data(107)<=i_hdd_rbuf_status.err_type.bufi_full;
i_hddraid_dbgcs.data(108)<=tst_hdd_rambuf_out(11);--tst_rambuf_empty;

--//SH2
i_hddraid_dbgcs.data(113 downto 109)<=i_hdd_dbgcs.sh(2).layer.trig0(34 downto 30);--llayer
i_hddraid_dbgcs.data(118 downto 114)<=i_hdd_dbgcs.sh(2).layer.trig0(39 downto 35);--tlayer
i_hddraid_dbgcs.data(124 downto 119)<=i_hdd_dbgcs.raid.data(135 downto 130);--i_hdd_dbgcs.sh(2).layer.data(55 downto 50);--(65 downto 50);
i_hddraid_dbgcs.data(125)           <=tst_hdd_rambuf_out(24);--<=i_memr_stop;  --i_hdd_dbgcs.sh(2).layer.data(49);--p_in_ll_rxd_wr; --llayer->tlayer
i_hddraid_dbgcs.data(126)           <=tst_hdd_rambuf_out(25);--<=i_memw_start;   --i_hdd_dbgcs.sh(2).layer.data(116);--p_in_ll_txd_rd; --llayer<-tlayer
i_hddraid_dbgcs.data(127)           <=tst_fsm_hddctrl(0);          --i_hdd_dbgcs.sh(2).layer.data(118);--<=p_in_dbg.llayer.txbuf_status.aempty;
i_hddraid_dbgcs.data(128)           <=i_hdd_dbgcs.sh(2).layer.data(119);--<=p_in_dbg.llayer.txbuf_status.empty;
i_hddraid_dbgcs.data(129)           <=i_mem_mux_sel;--i_hdd_dbgcs.sh(2).layer.data(98);--<=p_in_dbg.llayer.rxbuf_status.pfull;
i_hddraid_dbgcs.data(130)           <=i_hdd_dbgcs.sh(2).layer.data(99);--<=p_in_dbg.llayer.txbuf_status.pfull;
i_hddraid_dbgcs.data(131)           <=tst_fsm_hddctrl(1); --i_hdd_dbgcs.sh(2).layer.data(117);--<=p_in_dbg.llayer.txd_close;

--//SH3
i_hddraid_dbgcs.data(136 downto 132)<=i_hdd_dbgcs.sh(3).layer.trig0(34 downto 30);--llayer
i_hddraid_dbgcs.data(137)           <=i_hdd_dbgcs.measure.data(0);--i_dly_on(0);
i_hddraid_dbgcs.data(142 downto 138)<=i_hdd_dbgcs.sh(3).layer.trig0(39 downto 35);--tlayer
i_hddraid_dbgcs.data(148 downto 143)<=i_hdd_dbgcs.raid.data(141 downto 136);--i_hdd_dbgcs.sh(3).layer.data(55 downto 50);--(65 downto 50);
i_hddraid_dbgcs.data(149)           <=tst_hdd_rambuf_out(23);--<=i_memr_start_hm_r          --i_hdd_dbgcs.sh(3).layer.data(49);--p_in_ll_rxd_wr; --llayer->tlayer
i_hddraid_dbgcs.data(150)           <=i_hdd_dbgcs.raid.data(142);--i_hdd_dbgcs.sh(3).layer.data(116);--p_in_ll_txd_rd; --llayer<-tlayer
i_hddraid_dbgcs.data(151)           <=tst_fsm_hddctrl(2);--i_hdd_dbgcs.sh(3).layer.data(118);--<=p_in_dbg.llayer.txbuf_status.aempty;
i_hddraid_dbgcs.data(152)           <=i_hdd_dbgcs.sh(3).layer.data(119);--<=p_in_dbg.llayer.txbuf_status.empty;
i_hddraid_dbgcs.data(153)           <=tst_vctrl_out(14);--i_vwr_fr_rdy  --i_hdd_dbgcs.sh(3).layer.data(98);--<=p_in_dbg.llayer.rxbuf_status.pfull;
i_hddraid_dbgcs.data(154)           <=i_hdd_dbgcs.sh(3).layer.data(99);--<=p_in_dbg.llayer.txbuf_status.pfull;
i_hddraid_dbgcs.data(155)           <=sr_hddbufi_rst(0);--i_hdd_dbgcs.sh(3).layer.data(117);--<=p_in_dbg.llayer.txd_close;

i_hddraid_dbgcs.data(156)<=i_mem_in_bank (C_PCFG_MEMBANK_0)(C_MEMCH_WR).cmd_wr        ;
i_hddraid_dbgcs.data(157)<=i_mem_in_bank (C_PCFG_MEMBANK_0)(C_MEMCH_WR).txd_wr        ;
i_hddraid_dbgcs.data(158)<=i_mem_out_bank(C_PCFG_MEMBANK_0)(C_MEMCH_WR).txbuf_err     ;
i_hddraid_dbgcs.data(159)<=i_mem_out_bank(C_PCFG_MEMBANK_0)(C_MEMCH_WR).txbuf_underrun;
i_hddraid_dbgcs.data(160)<=i_vctrl_vwr_off;
i_hddraid_dbgcs.data(161)<=i_mem_in_bank (C_PCFG_MEMBANK_0)(C_MEMCH_RD).cmd_wr        ;
i_hddraid_dbgcs.data(162)<=i_mem_in_bank (C_PCFG_MEMBANK_0)(C_MEMCH_RD).rxd_rd        ;
i_hddraid_dbgcs.data(163)<=i_mem_out_bank(C_PCFG_MEMBANK_0)(C_MEMCH_RD).rxbuf_err     ;
i_hddraid_dbgcs.data(164)<=i_mem_out_bank(C_PCFG_MEMBANK_0)(C_MEMCH_RD).rxbuf_overflow;
i_hddraid_dbgcs.data(165)<=i_hdd_tst_out(5);--i_sh_cxbuf_empty

i_hddraid_dbgcs.data(168 downto 166)<=tst_hdd_rambuf_out(9 downto 7);--mem_rd/fsm_cs
i_hddraid_dbgcs.data(171 downto 169)<=tst_hdd_rambuf_out(4 downto 2);--mem_wr/fsm_cs
i_hddraid_dbgcs.data(172)<=tst_hdd_rambuf_out(13);--rambuf/padding
i_hddraid_dbgcs.data(204 downto 173)<=(i_hdd_rbuf_status.hwlog_size(28 downto 0)&"000");--i_mem_in_bank (C_PCFG_MEMBANK_0)(C_MEMCH_WR).txd(31 downto 0); --
i_hddraid_dbgcs.data(236 downto 205)<=i_mem_out_bank(C_PCFG_MEMBANK_0)(C_MEMCH_RD).rxd(31 downto 0);
i_hddraid_dbgcs.data(239 downto 237)<=tst_vctrl_out(26 downto 24);--vwriter/fsm
i_hddraid_dbgcs.data(242 downto 240)<=tst_vctrl_out(30 downto 28);--vreader/fsm
i_hddraid_dbgcs.data(245 downto 243)<=tst_vctrl_out(4 downto 2);--vwriter/mem_wr/fsm_cs
i_hddraid_dbgcs.data(248 downto 246)<=tst_vctrl_out(9 downto 7);--vreader/mem_wr/fsm_cs
i_hddraid_dbgcs.data(249)<=tst_vctrl_out(27);--vwriter/padding
i_hddraid_dbgcs.data(250)<=tst_vctrl_out(31);--vreader/padding
i_hddraid_dbgcs.data(251)<=i_mem_out_bank(C_PCFG_MEMBANK_0)(C_MEMCH_WR).txbuf_full;
i_hddraid_dbgcs.data(252)<=i_mem_out_bank(C_PCFG_MEMBANK_0)(C_MEMCH_RD).rxbuf_empty;
i_hddraid_dbgcs.data(255 downto 253)<=i_hdd_dbgcs.raid.data(145 downto 143);

process(i_hdd_dbgcs.raid.clk)
begin
  if i_hdd_dbgcs.raid.clk'event and i_hdd_dbgcs.raid.clk='1' then

    sr_vin_vs<=p_in_vin_vs & sr_vin_vs(0 to 1);
    i_vin_vs_fedge<=    sr_vin_vs(1) and not sr_vin_vs(2);
    i_vin_vs_redge<=not sr_vin_vs(1) and     sr_vin_vs(2);

    sr_hddbufi_rst<=((i_hdd_rbuf_cfg.dmacfg.hm_w and not i_hdd_tx_rdy) or i_hdd_rbuf_cfg.dmacfg.hm_r) & sr_hddbufi_rst(0 to 0);
    tst_hddbufi_rst_fedge<=not sr_hddbufi_rst(0) and     sr_hddbufi_rst(1);--falling edge
    tst_hddbufi_rst_redge<=    sr_hddbufi_rst(0) and not sr_hddbufi_rst(1);--rissing edge

--    if sr_vch_rst(0)='0' and sr_vch_rst(1)='1' then
--      tst_start_wr<='1';
--    elsif i_vbufi_empty='0' then
--      tst_start_wr<='0';
--    end if;
  end if;
end process;

tst_fsm_hddctrl<=CONV_STD_LOGIC_VECTOR(16#01#, tst_fsm_hddctrl'length) when fsm_hddctrl=S_HDD_ELBA    else
                 CONV_STD_LOGIC_VECTOR(16#02#, tst_fsm_hddctrl'length) when fsm_hddctrl=S_HDD_DLY0    else
                 CONV_STD_LOGIC_VECTOR(16#03#, tst_fsm_hddctrl'length) when fsm_hddctrl=S_HDD_CMD     else
                 CONV_STD_LOGIC_VECTOR(16#04#, tst_fsm_hddctrl'length) when fsm_hddctrl=S_HDD_DLY1    else
                 CONV_STD_LOGIC_VECTOR(16#05#, tst_fsm_hddctrl'length) when fsm_hddctrl=S_HDD_DONE    else
                 CONV_STD_LOGIC_VECTOR(16#00#, tst_fsm_hddctrl'length) ; --//when fsm_hddctrl=S_IDLE else

end generate gen_raid_dbgcs;
end generate gen_hdd_dbgcs;



--END MAIN
end architecture;
