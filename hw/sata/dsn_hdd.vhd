-------------------------------------------------------------------------
-- Company     : Linkos
-- Engineer    : Golovachenko Victor
--
-- Create Date : 10/26/2007
-- Module Name : dsn_hdd
--
-- Назначение/Описание :
--  Запись/Чтение регистров устройств
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

library work;
use work.prj_def.all;
use work.vicg_common_pkg.all;
use work.sata_glob_pkg.all;
use work.sata_pkg.all;
use work.sata_sim_lite_pkg.all;
use work.sata_raid_pkg.all;
use work.dsn_hdd_pkg.all;
use work.sata_unit_pkg.all;
use work.sata_testgen_pkg.all;

entity dsn_hdd is
generic(
G_MODULE_USE : string:="ON";
G_HDD_COUNT  : integer:=1;
G_GT_DBUS    : integer:=16;
G_DBG        : string:="OFF";
G_DBGCS      : string:="OFF";
G_SIM        : string:="OFF"
);
port(
-------------------------------
-- Конфигурирование модуля DSN_HDD.VHD (p_in_cfg_clk domain)
-------------------------------
p_in_cfg_if               : in   std_logic;                      --//Выбор интерфейса управления:0/1 - PCIEXP/UART
p_in_cfg_clk              : in   std_logic;                      --//

p_in_cfg_adr              : in   std_logic_vector(7 downto 0);   --//
p_in_cfg_adr_ld           : in   std_logic;                      --//
p_in_cfg_adr_fifo         : in   std_logic;                      --//

p_in_cfg_txdata           : in   std_logic_vector(15 downto 0);  --//
p_in_cfg_wd               : in   std_logic;                      --//
p_out_cfg_txrdy           : out  std_logic;                      --//

p_out_cfg_rxdata          : out  std_logic_vector(15 downto 0);  --//
p_in_cfg_rd               : in   std_logic;                      --//
p_out_cfg_rxrdy           : out  std_logic;                      --//

p_in_cfg_done             : in   std_logic;                      --//
p_in_cfg_rst              : in   std_logic;

-------------------------------
-- STATUS модуля DSN_HDD.VHD
-------------------------------
p_out_hdd_rdy             : out  std_logic;                      --//
p_out_hdd_error           : out  std_logic;                      --//
p_out_hdd_busy            : out  std_logic;                      --//
p_out_hdd_irq             : out  std_logic;                      --//
p_out_hdd_done            : out  std_logic;                      --//

-------------------------------
-- Связь с Источниками/Приемниками данных накопителя
-------------------------------
p_out_rbuf_cfg            : out  THDDRBufCfg;                    --//Конфигурирование RAMBUF
p_in_rbuf_status          : in   THDDRBufStatus;                 --//Статусы RAMBUF

p_in_hdd_txd_wrclk        : in   std_logic;                      --//
p_in_hdd_txd              : in   std_logic_vector(31 downto 0);  --//
p_in_hdd_txd_wr           : in   std_logic;                      --//
p_out_hdd_txbuf_pfull     : out  std_logic;                      --//
p_out_hdd_txbuf_full      : out  std_logic;                      --//
p_out_hdd_txbuf_empty     : out  std_logic;                      --//

p_in_hdd_rxd_rdclk        : in   std_logic;                      --//
p_out_hdd_rxd             : out  std_logic_vector(31 downto 0);  --//
p_in_hdd_rxd_rd           : in   std_logic;                      --//
p_out_hdd_rxbuf_empty     : out  std_logic;                      --//
p_out_hdd_rxbuf_pempty    : out  std_logic;                      --//

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

---------------------------------------------------------------------------
--Технологический порт
---------------------------------------------------------------------------
p_in_tst                  : in    std_logic_vector(31 downto 0);
p_out_tst                 : out   std_logic_vector(31 downto 0);

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
end dsn_hdd;

architecture behavioral of dsn_hdd is

component mclk_gtp_wrap
generic(
G_SIM     : string:="OFF"
);
port(
p_out_txn : out   std_logic_vector(1 downto 0);
p_out_txp : out   std_logic_vector(1 downto 0);
p_in_rxn  : in    std_logic_vector(1 downto 0);
p_in_rxp  : in    std_logic_vector(1 downto 0);
clkin     : in    std_logic;
clkout    : out   std_logic
);
end component;

component hdd_cmdfifo
port(
din         : in std_logic_vector(15 downto 0);
wr_en       : in std_logic;
wr_clk      : in std_logic;

dout        : out std_logic_vector(15 downto 0);
rd_en       : in std_logic;
rd_clk      : in std_logic;

full        : out std_logic;
empty       : out std_logic;

--clk         : in std_logic;
rst         : in std_logic
);
end component ;

component hdd_txfifo
port(
din         : in std_logic_vector(p_in_hdd_txd'range);
wr_en       : in std_logic;
wr_clk      : in std_logic;

dout        : out std_logic_vector(p_in_hdd_txd'range);
rd_en       : in std_logic;
rd_clk      : in std_logic;

full        : out std_logic;
almost_full : out std_logic;
empty       : out std_logic;
prog_full   : out std_logic;

--clk         : in std_logic;
rst         : in std_logic
);
end component;

component hdd_rxfifo
port(
din         : in std_logic_vector(p_out_hdd_rxd'range);
wr_en       : in std_logic;
wr_clk      : in std_logic;

dout        : out std_logic_vector(p_out_hdd_rxd'range);
rd_en       : in std_logic;
rd_clk      : in std_logic;

full        : out std_logic;
almost_full : out std_logic;
empty       : out std_logic;
prog_empty  : out std_logic;

--clk         : in std_logic;
rst         : in std_logic
);
end component;

signal i_cfg_adr_cnt                    : std_logic_vector(7 downto 0);

signal h_reg_ctrl_l                     : std_logic_vector(C_HDD_REG_CTRLL_LAST_BIT downto 0):=(others=>'0');
signal h_reg_hwstart_dly                : std_logic_vector(15 downto 0):=(others=>'0');
signal h_reg_rbuf_adr                   : std_logic_vector(31 downto 0):=(others=>'0');
signal h_reg_rbuf_trnlen                : std_logic_vector(15 downto 0):=(others=>'0');
signal h_reg_rbuf_reqlen                : std_logic_vector(15 downto 0):=(others=>'0');
signal h_reg_rbuf_ctrl                  : std_logic_vector(C_HDD_REG_RBUF_CTRL_LAST_BIT downto 0):=(others=>'0');

signal i_reg_ctrl_l                     : std_logic_vector(h_reg_ctrl_l'range):=(others=>'0');
signal i_reg_rbuf_ctrl                  : std_logic_vector(h_reg_rbuf_ctrl'range):=(others=>'0');
signal i_reg_hwstart_dly                : std_logic_vector(h_reg_hwstart_dly'range):=(others=>'0');
signal i_buf_rst                        : std_logic;

--signal i_hdd_txd                        : std_logic_vector(p_in_hdd_txd'range);
signal i_hdd_txd_wr                     : std_logic;
signal i_hdd_rxd_rd                     : std_logic;

signal i_sata_gt_refclk                 : std_logic_vector(C_SH_COUNT_MAX(G_HDD_COUNT-1)-1 downto 0);
signal i_sh_ctrl                        : std_logic_vector(C_USR_GCTRL_LAST_BIT downto 0);
signal i_sh_status                      : TUsrStatus;
signal i_sh_measure                     : TMeasureStatus;
type TChStatus is array (0 to C_HDD_COUNT_MAX-1) of std_logic_vector(31 downto 0);
signal i_sh_status_ch                   : TChStatus;

signal sr_sh_busy                       : std_logic_vector(0 to 1);
signal i_sh_busy                        : std_logic;
signal i_sh_done                        : std_logic;
signal i_sh_atadone_ack                 : std_logic;

type THDDBufChk_state is (
S_IDLE,
S_CHEK_BUF,
S_WAIT_HW_DONE,
S_CHEK_BUF_DONE
);
signal fsm_state_cs                     : THDDBufChk_state;

signal i_sh_cxd                         : std_logic_vector(15 downto 0);
signal i_sh_cxd_wr                      : std_logic;
signal i_sh_cxd_rd                      : std_logic;
signal i_sh_cxbuf_empty                 : std_logic;
signal i_sh_txd,i_sh_txd_tmp            : std_logic_vector(31 downto 0);
signal i_sh_txd_rd                      : std_logic;
signal i_sh_txbuf_empty                 : std_logic;
signal i_sh_txbuf_empty_tmp             : std_logic;
signal i_sh_rxd                         : std_logic_vector(31 downto 0);
signal i_sh_rxd_wr                      : std_logic;
signal i_sh_rxbuf_full                  : std_logic;

signal i_sh_rxbuf_empty                 : std_logic;
signal sr_sh_rxbuf_empty                : std_logic_vector(0 downto 0);

signal i_sh_sim_gt_txdata               : TBus32_SHCountMax;
signal i_sh_sim_gt_txcharisk            : TBus04_SHCountMax;
signal i_sh_sim_gt_txcomstart           : std_logic_vector(C_HDD_COUNT_MAX-1 downto 0);
signal i_sh_sim_gt_rxdata               : TBus32_SHCountMax;
signal i_sh_sim_gt_rxcharisk            : TBus04_SHCountMax;
signal i_sh_sim_gt_rxstatus             : TBus03_SHCountMax;
signal i_sh_sim_gt_rxelecidle           : std_logic_vector(C_HDD_COUNT_MAX-1 downto 0);
signal i_sh_sim_gt_rxdisperr            : TBus04_SHCountMax;
signal i_sh_sim_gt_rxnotintable         : TBus04_SHCountMax;
signal i_sh_sim_gt_rxbyteisaligned      : std_logic_vector(C_HDD_COUNT_MAX-1 downto 0);
signal i_sh_sim_gt_sim_rst              : std_logic_vector(C_HDD_COUNT_MAX-1 downto 0);
signal i_sh_sim_gt_sim_clk              : std_logic_vector(C_HDD_COUNT_MAX-1 downto 0);

signal i_tstgen                         : THDDTstGen;
signal i_testing_on,i_testing_on_tmp    : std_logic;
signal i_testing_den                    : std_logic;
signal i_testing_d                      : std_logic_vector(31 downto 0);

signal i_ram_d_wcnt                     : std_logic:='0';
signal i_ram_din                        : std_logic_vector(15 downto 0):=(others=>'0');
signal i_ram_dout                       : std_logic_vector(15 downto 0):=(others=>'0');
signal sr_ram_rd_rdy                    : std_logic:='0';

signal tst_out                          : std_logic_vector(2 downto 0);
signal tst_hdd_out                      : std_logic_vector(31 downto 0);


--MAIN
begin


--//--------------------------------------------------
--//Конфигурирование модуля DSN_HDD.VHD
--//--------------------------------------------------
--//Счетчик адреса регистров
process(p_in_cfg_rst,p_in_cfg_clk)
begin
  if p_in_cfg_rst='1' then
    i_cfg_adr_cnt<=(others=>'0');
  elsif p_in_cfg_clk'event and p_in_cfg_clk='1' then
    if p_in_cfg_adr_ld='1' then
      i_cfg_adr_cnt<=p_in_cfg_adr;
    else
      if p_in_cfg_adr_fifo='0' and (p_in_cfg_wd='1' or p_in_cfg_rd='1') then
        i_cfg_adr_cnt<=i_cfg_adr_cnt+1;
      end if;
    end if;
  end if;
end process;

--//Запись регистров
process(p_in_cfg_rst,p_in_cfg_clk)
begin
  if p_in_cfg_rst='1' then
    h_reg_ctrl_l<=(others=>'0');
    h_reg_hwstart_dly<=(others=>'0');
    h_reg_rbuf_adr<=(others=>'0');
    h_reg_rbuf_trnlen<=(others=>'0');
    h_reg_rbuf_reqlen<=(others=>'0');
    h_reg_rbuf_ctrl<=(others=>'0');

  elsif p_in_cfg_clk'event and p_in_cfg_clk='1' then

    if p_in_cfg_wd='1' then
        if    i_cfg_adr_cnt=CONV_STD_LOGIC_VECTOR(C_HDD_REG_CTRL_L, i_cfg_adr_cnt'length) then h_reg_ctrl_l<=p_in_cfg_txdata(h_reg_ctrl_l'range);
        elsif i_cfg_adr_cnt=CONV_STD_LOGIC_VECTOR(C_HDD_REG_HWSTART_DLY, i_cfg_adr_cnt'length) then h_reg_hwstart_dly<=p_in_cfg_txdata(h_reg_hwstart_dly'range);

        elsif i_cfg_adr_cnt=CONV_STD_LOGIC_VECTOR(C_HDD_REG_RBUF_ADR_L, i_cfg_adr_cnt'length) then h_reg_rbuf_adr(15 downto 0)<=p_in_cfg_txdata;
        elsif i_cfg_adr_cnt=CONV_STD_LOGIC_VECTOR(C_HDD_REG_RBUF_ADR_M, i_cfg_adr_cnt'length) then h_reg_rbuf_adr(31 downto 16)<=p_in_cfg_txdata;
        elsif i_cfg_adr_cnt=CONV_STD_LOGIC_VECTOR(C_HDD_REG_RBUF_TRNLEN, i_cfg_adr_cnt'length) then h_reg_rbuf_trnlen<=p_in_cfg_txdata;
        elsif i_cfg_adr_cnt=CONV_STD_LOGIC_VECTOR(C_HDD_REG_RBUF_REQLEN, i_cfg_adr_cnt'length) then h_reg_rbuf_reqlen<=p_in_cfg_txdata;
        elsif i_cfg_adr_cnt=CONV_STD_LOGIC_VECTOR(C_HDD_REG_RBUF_CTRL, i_cfg_adr_cnt'length) then h_reg_rbuf_ctrl<=p_in_cfg_txdata(h_reg_rbuf_ctrl'range);

        end if;
    end if;

  end if;
end process;

--//Чтение регистров
process(p_in_cfg_rst,p_in_cfg_clk)
  variable rxd : std_logic_vector(p_out_cfg_rxdata'range);
begin
  if p_in_cfg_rst='1' then
      rxd:=(others=>'0');
    p_out_cfg_rxdata<=(others=>'0');
  elsif p_in_cfg_clk'event and p_in_cfg_clk='1' then
    rxd:=(others=>'0');

    if p_in_cfg_rd='1' then
        if    i_cfg_adr_cnt=CONV_STD_LOGIC_VECTOR(C_HDD_REG_CTRL_L, i_cfg_adr_cnt'length) then rxd(h_reg_ctrl_l'range):=h_reg_ctrl_l;
        elsif i_cfg_adr_cnt=CONV_STD_LOGIC_VECTOR(C_HDD_REG_HWSTART_DLY, i_cfg_adr_cnt'length) then rxd:=h_reg_hwstart_dly;

        elsif i_cfg_adr_cnt=CONV_STD_LOGIC_VECTOR(C_HDD_REG_LBA_BPOINT_L, i_cfg_adr_cnt'length)   then rxd:=i_sh_status.lba_bp(15 downto 0);
        elsif i_cfg_adr_cnt=CONV_STD_LOGIC_VECTOR(C_HDD_REG_LBA_BPOINT_MID, i_cfg_adr_cnt'length) then rxd:=i_sh_status.lba_bp(31 downto 16);
        elsif i_cfg_adr_cnt=CONV_STD_LOGIC_VECTOR(C_HDD_REG_LBA_BPOINT_M, i_cfg_adr_cnt'length)   then rxd:=i_sh_status.lba_bp(47 downto 32);

        elsif i_cfg_adr_cnt=CONV_STD_LOGIC_VECTOR(C_HDD_REG_TEST_TDLY_L, i_cfg_adr_cnt'length)  then rxd:=i_sh_measure.tdly(15 downto 0);
        elsif i_cfg_adr_cnt=CONV_STD_LOGIC_VECTOR(C_HDD_REG_TEST_TDLY_M, i_cfg_adr_cnt'length)  then rxd:=i_sh_measure.tdly(31 downto 16);
        elsif i_cfg_adr_cnt=CONV_STD_LOGIC_VECTOR(C_HDD_REG_TEST_TWORK_L, i_cfg_adr_cnt'length) then rxd:=i_sh_measure.twork(15 downto 0);
        elsif i_cfg_adr_cnt=CONV_STD_LOGIC_VECTOR(C_HDD_REG_TEST_TWORK_M, i_cfg_adr_cnt'length) then rxd:=i_sh_measure.twork(31 downto 16);

        elsif i_cfg_adr_cnt=CONV_STD_LOGIC_VECTOR(C_HDD_REG_STATUS_L, i_cfg_adr_cnt'length) then
            rxd(3 downto 0):=i_sh_status.hdd_count(3 downto 0);
            rxd(4):=i_sh_status.dev_rdy;
            rxd(5):=i_sh_status.dev_err;
            rxd(6):=i_sh_status.dev_bsy;
            rxd(7):=i_sh_done;
            rxd(8):=p_in_rbuf_status.err_type.rambuf_full;
            rxd(9):=p_in_rbuf_status.err_type.vinbuf_full;

        elsif i_cfg_adr_cnt=CONV_STD_LOGIC_VECTOR(C_HDD_REG_STATUS_M, i_cfg_adr_cnt'length) then rxd:=EXT(i_sh_status.ch_err, 8)&EXT(i_sh_status.ch_rdy, 8);

        elsif i_cfg_adr_cnt(i_cfg_adr_cnt'high downto 4)=CONV_STD_LOGIC_VECTOR(16#01#, i_cfg_adr_cnt'length - 4) then
        --//Статусы SATA каналов, регистры C_HDD_REG_STATUS_SATAxx_L/M - адреса 0x10...0x1F
          for i in 0 to G_HDD_COUNT-1 loop
            if i_cfg_adr_cnt(3 downto 1)=i then
              if i_cfg_adr_cnt(0)='0' then
                rxd:=i_sh_status_ch(i)(15 downto 0);
              else
                rxd:=i_sh_status_ch(i)(31 downto 16);
              end if;
            end if;
          end loop;

        elsif i_cfg_adr_cnt=CONV_STD_LOGIC_VECTOR(C_HDD_REG_HWLOG_SIZE_L, i_cfg_adr_cnt'length) then rxd:=p_in_rbuf_status.hwlog_size(15 downto 0);
        elsif i_cfg_adr_cnt=CONV_STD_LOGIC_VECTOR(C_HDD_REG_HWLOG_SIZE_M, i_cfg_adr_cnt'length) then rxd:=p_in_rbuf_status.hwlog_size(31 downto 16);

        elsif i_cfg_adr_cnt=CONV_STD_LOGIC_VECTOR(C_HDD_REG_RBUF_ADR_L, i_cfg_adr_cnt'length) then rxd:=h_reg_rbuf_adr(15 downto 0);
        elsif i_cfg_adr_cnt=CONV_STD_LOGIC_VECTOR(C_HDD_REG_RBUF_ADR_M, i_cfg_adr_cnt'length) then rxd:=h_reg_rbuf_adr(31 downto 16);
        elsif i_cfg_adr_cnt=CONV_STD_LOGIC_VECTOR(C_HDD_REG_RBUF_TRNLEN, i_cfg_adr_cnt'length) then rxd:=h_reg_rbuf_trnlen;
        elsif i_cfg_adr_cnt=CONV_STD_LOGIC_VECTOR(C_HDD_REG_RBUF_REQLEN, i_cfg_adr_cnt'length) then rxd:=h_reg_rbuf_reqlen;
        elsif i_cfg_adr_cnt=CONV_STD_LOGIC_VECTOR(C_HDD_REG_RBUF_CTRL, i_cfg_adr_cnt'length) then rxd(h_reg_rbuf_ctrl'range):=h_reg_rbuf_ctrl;
        elsif i_cfg_adr_cnt=CONV_STD_LOGIC_VECTOR(C_HDD_REG_RBUF_DATA, i_cfg_adr_cnt'length) then
            rxd:=p_in_rbuf_status.ram_wr_o.dout(rxd'range);

        end if;

        p_out_cfg_rxdata<=rxd;

    end if;--//if p_in_cfg_rd='1' then
  end if;
end process;

p_out_cfg_txrdy<=p_in_rbuf_status.ram_wr_o.wr_rdy when p_in_cfg_adr_fifo='1' and i_cfg_adr_cnt=CONV_STD_LOGIC_VECTOR(C_HDD_REG_RBUF_DATA, i_cfg_adr_cnt'length) else '1';
p_out_cfg_rxrdy<=p_in_rbuf_status.ram_wr_o.rd_rdy when p_in_cfg_adr_fifo='1' and i_cfg_adr_cnt=CONV_STD_LOGIC_VECTOR(C_HDD_REG_RBUF_DATA, i_cfg_adr_cnt'length) else '1';


--//Запись командного пакета
i_sh_cxd_wr <=p_in_cfg_wd  when p_in_cfg_adr_fifo='1' and i_cfg_adr_cnt=CONV_STD_LOGIC_VECTOR(C_HDD_REG_CMDFIFO, i_cfg_adr_cnt'length) else '0';

process(p_in_clk)
begin
  if p_in_clk'event and p_in_clk='1' then
    i_reg_ctrl_l<=h_reg_ctrl_l;
    i_reg_rbuf_ctrl<=h_reg_rbuf_ctrl;
    i_reg_hwstart_dly<=h_reg_hwstart_dly;
  end if;
end process;

i_tstgen.con2rambuf<=i_reg_ctrl_l(C_HDD_REG_CTRLL_TST_GEN2RAMBUF_BIT);
i_tstgen.tesing_on <=i_reg_ctrl_l(C_HDD_REG_CTRLL_TST_ON_BIT);
i_tstgen.tesing_spd<=i_reg_ctrl_l(C_HDD_REG_CTRLL_TST_SPD_M_BIT downto C_HDD_REG_CTRLL_TST_SPD_L_BIT);
i_tstgen.start<=i_sh_status.dmacfg.tstgen_start;
i_tstgen.stop<=i_sh_status.dmacfg.hw_mode;
i_tstgen.clr_err<=i_sh_ctrl(C_USR_GCTRL_ERR_CLR_BIT);
i_tstgen.td_zero<=i_reg_ctrl_l(C_HDD_REG_CTRLL_TST_GEND0_BIT);

i_sh_ctrl(C_USR_GCTRL_HWLOG_ON_BIT)  <=i_reg_ctrl_l(C_HDD_REG_CTRLL_HWLOG_ON_BIT);
i_sh_ctrl(C_USR_GCTRL_TST_ON_BIT)    <=i_tstgen.tesing_on;
i_sh_ctrl(C_USR_GCTRL_ERR_CLR_BIT)   <=i_reg_ctrl_l(C_HDD_REG_CTRLL_ERR_CLR_BIT) or p_in_tst(0);
i_sh_ctrl(C_USR_GCTRL_ERR_STREAMBUF_BIT)<=p_in_rbuf_status.err and not i_reg_ctrl_l(C_HDD_REG_CTRLL_ERR_STREMBUF_DIS_BIT);
i_sh_ctrl(C_USR_GCTRL_MEASURE_TXHOLD_DIS_BIT)<=i_reg_ctrl_l(C_HDD_REG_CTRLL_MEASURE_TXHOLD_DIS_BIT);
i_sh_ctrl(C_USR_GCTRL_MEASURE_RXHOLD_DIS_BIT)<='0';
i_sh_ctrl(C_USR_GCTRL_HWSTART_DLY_ON_BIT)<=i_reg_ctrl_l(C_HDD_REG_CTRLL_HWSTART_DLY_ON_BIT);

i_sh_ctrl(C_USR_GCTRL_HWSTART_DLY_FIX_BIT)<='0';
i_sh_ctrl(C_USR_GCTRL_HWSTART_DLY_M_BIT downto C_USR_GCTRL_HWSTART_DLY_L_BIT)<=(others=>'0');


--//Формирую значения для регистров C_HDD_REG_STATUS_SATAxx_L/M
gen_status_ch : for i in 0 to G_HDD_COUNT-1 generate

i_sh_status_ch(i)(0)<=i_sh_status.ch_serror(i)(C_ASERR_I_ERR_BIT);

i_sh_status_ch(i)(8 downto 1)<=i_sh_status.ch_ataerror(i);--//ATA ERROR (COD)

i_sh_status_ch(i)(9)<=i_sh_status.ch_serror(i)(C_ASERR_C_ERR_BIT);
i_sh_status_ch(i)(10)<=i_sh_status.ch_serror(i)(C_ASERR_P_ERR_BIT);

i_sh_status_ch(i)(11)<=i_sh_status.ch_atastatus(i)(C_ATA_STATUS_ERR_BIT);--ATA ERROR (Flag)
i_sh_status_ch(i)(15 downto 12)<=(others=>'0');

i_sh_status_ch(i)(16)<=i_sh_status.ch_serror(i)(C_ASERR_N_DIAG_BIT);--//PHY Layer:if (i_link_establish_change='1' and i_usrmode(C_USRCMD_SET_SATA1)='0' and i_usrmode(C_USRCMD_SET_SATA2)='0') then
i_sh_status_ch(i)(17)<=i_sh_status.ch_serror(i)(C_ASERR_I_DIAG_BIT);--//не использую
i_sh_status_ch(i)(18)<=i_sh_status.ch_serror(i)(C_ASERR_W_DIAG_BIT);--//PHY Layer:if p_in_pl_status(C_PSTAT_COMWAKE_RCV_BIT)='1' then
i_sh_status_ch(i)(19)<=i_sh_status.ch_serror(i)(C_ASERR_B_DIAG_BIT);--//PHY Layer:if p_in_pl_status(C_PSTAT_DET_ESTABLISH_ON_BIT)='1' and p_in_pl_status(C_PRxSTAT_ERR_NOTINTABLE_BIT)='1' then
i_sh_status_ch(i)(20)<=i_sh_status.ch_serror(i)(C_ASERR_D_DIAG_BIT);--//PHY Layer:if p_in_pl_status(C_PSTAT_DET_ESTABLISH_ON_BIT)='1' and p_in_pl_status(C_PRxSTAT_ERR_DISP_BIT)='1' then
i_sh_status_ch(i)(21)<=i_sh_status.ch_serror(i)(C_ASERR_C_DIAG_BIT);--//Link Layer: --//CRC ERROR
i_sh_status_ch(i)(22)<=i_sh_status.ch_serror(i)(C_ASERR_H_DIAG_BIT);--//Link Layer: --//1/0 - CRC ERROR on (send FIS/rcv FIS)
i_sh_status_ch(i)(23)<=i_sh_status.ch_serror(i)(C_ASERR_S_DIAG_BIT);--//Link Layer:if p_in_ll_status(C_LSTAT_RxERR_IDLE)='1' or p_in_ll_status(C_LSTAT_TxERR_IDLE)='1' then
i_sh_status_ch(i)(24)<=i_sh_status.ch_serror(i)(C_ASERR_T_DIAG_BIT);--//Link Layer:if p_in_ll_status(C_LSTAT_RxERR_ABORT)='1' or p_in_ll_status(C_LSTAT_TxERR_ABORT)='1' then
i_sh_status_ch(i)(25)<=i_sh_status.ch_serror(i)(C_ASERR_F_DIAG_BIT);--//Transport Layer: FIS CRC-OK, but FISTYPE/FISLEN ERROR

i_sh_status_ch(i)(26)<=i_sh_status.ch_sstatus(i)(C_ASSTAT_DET_BIT_L+0);--//PHY Layer: C_PSTAT_DET_DEV_ON_BIT
i_sh_status_ch(i)(27)<=i_sh_status.ch_sstatus(i)(C_ASSTAT_DET_BIT_L+1);--//PHY Layer: C_PSTAT_DET_ESTABLISH_ON_BIT
i_sh_status_ch(i)(30 downto 28)<=i_sh_status.ch_sstatus(i)(C_ASSTAT_SPD_BIT_L+2 downto C_ASSTAT_SPD_BIT_L);----//PHY Layer: SATA speed negatiation
i_sh_status_ch(i)(31)<=i_sh_status.ch_sstatus(i)(C_ASSTAT_IPM_BIT_L);--//

end generate gen_status_ch;

gen_nomax : if G_HDD_COUNT/=C_HDD_COUNT_MAX generate
gen_null: for i in G_HDD_COUNT to C_HDD_COUNT_MAX-1 generate
i_sh_status_ch(i)<=(others=>'0');
end generate gen_null;
end generate gen_nomax;

--//Настройка/Управление RAM буфером
p_out_rbuf_cfg.mem_trn<=h_reg_rbuf_trnlen;
p_out_rbuf_cfg.mem_adr<=h_reg_rbuf_adr;
p_out_rbuf_cfg.dmacfg <=i_sh_status.dmacfg;
p_out_rbuf_cfg.tstgen <=i_tstgen;
p_out_rbuf_cfg.hwlog  <=i_sh_measure.hwlog;
p_out_rbuf_cfg.usr    <=EXT(i_reg_hwstart_dly, p_out_rbuf_cfg.usr'length);

--Доступ к ОЗУ через CFG
p_out_rbuf_cfg.ram_wr_i.clk<=p_in_cfg_clk;
p_out_rbuf_cfg.ram_wr_i.din<=p_in_cfg_txdata;
p_out_rbuf_cfg.ram_wr_i.wr<=p_in_cfg_wd when p_in_cfg_adr_fifo='1' and i_cfg_adr_cnt=CONV_STD_LOGIC_VECTOR(C_HDD_REG_RBUF_DATA, i_cfg_adr_cnt'length) else '0';
p_out_rbuf_cfg.ram_wr_i.rd<=p_in_cfg_rd when p_in_cfg_adr_fifo='1' and i_cfg_adr_cnt=CONV_STD_LOGIC_VECTOR(C_HDD_REG_RBUF_DATA, i_cfg_adr_cnt'length) else '0';
p_out_rbuf_cfg.ram_wr_i.reqlen<=h_reg_rbuf_reqlen;
p_out_rbuf_cfg.ram_wr_i.dir  <=i_reg_rbuf_ctrl(C_HDD_REG_RBUF_CTRL_DIR);
p_out_rbuf_cfg.ram_wr_i.start<=i_reg_rbuf_ctrl(C_HDD_REG_RBUF_CTRL_START);
p_out_rbuf_cfg.ram_wr_i.sel  <=i_reg_rbuf_ctrl(C_HDD_REG_RBUF_CTRL_CFG2RAM);

p_out_rbuf_cfg.usrif<=p_in_cfg_if;--//Интерфейс управления
p_out_rbuf_cfg.greset<=i_reg_rbuf_ctrl(C_HDD_REG_RBUF_CTRL_GRESET);

--//Статусы модуля
p_out_hdd_rdy  <=i_sh_status.dev_rdy;
p_out_hdd_error<=i_sh_status.dev_err;
p_out_hdd_busy <=i_sh_busy;
p_out_hdd_irq  <=not i_sh_busy;--i_sh_irq_width;
p_out_hdd_done <=i_sh_done;



--//############################
--//USE - ON (использовать в проекте)
--//############################
gen_use_on : if strcmp(G_MODULE_USE,"ON") generate

--//----------------------------------
--//Технологические сигналы
--//----------------------------------
gen_dbg_off : if strcmp(G_DBG,"OFF") generate
tst_out(2 downto 0)<=(others=>'0');
end generate gen_dbg_off;

gen_dbg_on : if strcmp(G_DBG,"ON") generate
ltstout:process(p_in_rst,p_in_clk)
begin
  if p_in_rst='1' then
    tst_out(1 downto 0)<=(others=>'0');
  elsif p_in_clk'event and p_in_clk='1' then
    tst_out(0)<=tst_hdd_out(0);
    tst_out(1)<=tst_hdd_out(1);--//i_sata_module_rst(0);
  end if;
end process ltstout;
tst_out(2)<=tst_hdd_out(3);--//i_tst_measure_out(0);
end generate gen_dbg_on;

p_out_tst(2 downto 0)<=tst_out;
p_out_tst(3)<=i_hdd_txd_wr;--//hdd_txbuf
p_out_tst(4)<=i_hdd_rxd_rd;--//hdd_rxbuf
p_out_tst(5)<=i_tstgen.tesing_on;
p_out_tst(6)<=OR_reduce(i_sh_status.ch_bsy(G_HDD_COUNT-1 downto 0));
p_out_tst(7)<=i_reg_rbuf_ctrl(C_HDD_REG_RBUF_CTRL_CFG2RAM);
p_out_tst(8)<=i_ram_d_wcnt;
p_out_tst(31 downto 9)<=(others=>'0');


--//Логика управления статусами модуля DSN_HDD.VHD
process(p_in_rst,p_in_clk)
begin
  if p_in_rst='1' then
    sr_sh_rxbuf_empty<=(others=>'1');
    sr_sh_busy<=(others=>'0');
    i_sh_busy<='0';

    fsm_state_cs<= S_IDLE;
    i_sh_atadone_ack<='0';
    i_sh_done<='0';

  elsif p_in_clk'event and p_in_clk='1' then

    sr_sh_rxbuf_empty(0)<=i_sh_rxbuf_empty;

    if i_sh_ctrl(C_USR_GCTRL_ERR_CLR_BIT)='1' then
      sr_sh_busy<=(others=>'0');
      i_sh_busy<='0';

      fsm_state_cs<= S_IDLE;
      i_sh_atadone_ack<='0';
      i_sh_done<='0';

    else
        --//Формируем сигнал BUSY
        sr_sh_busy<=i_sh_status.dev_bsy & sr_sh_busy(0 to 0);
        if sr_sh_busy(0)='1' and sr_sh_busy(1)='0' then
          i_sh_busy<='1';
        elsif i_sh_atadone_ack='1' then
          i_sh_busy<='0';
        end if;

        case fsm_state_cs is

          when S_IDLE =>

            if i_sh_status.dmacfg.atacmdnew='1' then
            --//Сброс флага выполнения предыдущей команды
              i_sh_done<='0';
            end if;

            if i_sh_status.dmacfg.hw_mode='1' then
               fsm_state_cs<= S_WAIT_HW_DONE;

            elsif sr_sh_busy(0)='0' and sr_sh_busy(1)='1' then
              --//Ловим задний фронт сигнала АТА BUSY
              fsm_state_cs<= S_CHEK_BUF;
            end if;

          when S_CHEK_BUF =>
            --//Ждем пока из буферов уйдут все данные
--            if (sr_sh_rxbuf_empty(0)='1' and i_sh_txbuf_empty='1') or i_tstgen.tesing_on='1' then
              i_sh_atadone_ack<='1';--//Подтверждение завершения АТА команды
              i_sh_done<='1';

              fsm_state_cs<= S_CHEK_BUF_DONE;
--            end if;

          when S_WAIT_HW_DONE =>
            if sr_sh_busy(0)='0' and sr_sh_busy(1)='1' then
            --//Ловим задний фронт сигнала АТА BUSY
              i_sh_atadone_ack<='1';--//Подтверждение завершения АТА команды
              i_sh_done<='1';

              fsm_state_cs<= S_CHEK_BUF_DONE;
            end if;

          when S_CHEK_BUF_DONE =>
            i_sh_atadone_ack<='0';
            fsm_state_cs<= S_IDLE;
        end case;

    end if;
  end if;
end process;


m_cmdfifo : hdd_cmdfifo
port map(
din         => p_in_cfg_txdata,
wr_en       => i_sh_cxd_wr,
wr_clk      => p_in_cfg_clk,

dout        => i_sh_cxd,
rd_en       => i_sh_cxd_rd,
rd_clk      => p_in_clk,

full        => open,
empty       => i_sh_cxbuf_empty,

--clk         => p_in_clk,
rst         => i_buf_rst
);

i_sh_cxd_rd<=not i_sh_cxbuf_empty;

m_txfifo : hdd_txfifo
port map(
din         => p_in_hdd_txd,
wr_en       => i_hdd_txd_wr,
wr_clk      => p_in_hdd_txd_wrclk,

dout        => i_sh_txd_tmp,
rd_en       => i_sh_txd_rd,
rd_clk      => p_in_clk,

full        => open,
almost_full => p_out_hdd_txbuf_full,
empty       => i_sh_txbuf_empty_tmp,
prog_full   => p_out_hdd_txbuf_pfull,

--clk         => p_in_clk,
rst         => i_buf_rst
);

p_out_hdd_txbuf_empty<=i_sh_txbuf_empty;
i_hdd_txd_wr<=p_in_hdd_txd_wr and not i_testing_on;

i_sh_txd        <=i_sh_txd_tmp         when i_testing_on='0' else i_testing_d;
i_sh_txbuf_empty<=i_sh_txbuf_empty_tmp when i_testing_on='0' else not i_testing_den;

m_rxfifo : hdd_rxfifo
port map(
din         => i_sh_rxd,
wr_en       => i_sh_rxd_wr,
wr_clk      => p_in_clk,

dout        => p_out_hdd_rxd,
rd_en       => i_hdd_rxd_rd,
rd_clk      => p_in_hdd_rxd_rdclk,

full        => open,
almost_full => i_sh_rxbuf_full,
empty       => i_sh_rxbuf_empty,
prog_empty  => p_out_hdd_rxbuf_pempty,

--clk         => p_in_clk,
rst         => i_buf_rst
);

i_buf_rst<=p_in_rst or i_sh_ctrl(C_USR_GCTRL_ERR_CLR_BIT);
p_out_hdd_rxbuf_empty<=i_sh_rxbuf_empty;
i_hdd_rxd_rd<=p_in_hdd_rxd_rd or i_testing_on;


--//
i_testing_on<=i_testing_on_tmp and not i_tstgen.con2rambuf;

m_testgen : sata_testgen
generic map(
G_SCRAMBLER => "OFF"
)
port map(
p_in_gen_cfg   => i_tstgen,

p_out_rdy      => i_testing_on_tmp,
p_out_hwon     => open,

p_out_tdata    => i_testing_d,
p_out_tdata_en => i_testing_den,

p_in_clk       => p_in_clk,
p_in_rst       => p_in_rst
);


--//SATA
m_dsn_sata : dsn_raid_main
generic map(
G_HDD_COUNT => G_HDD_COUNT,
G_GT_DBUS   => G_GT_DBUS,
G_DBG       => G_DBG,
G_DBGCS     => G_DBGCS,
G_SIM       => G_SIM
)
port map(
--------------------------------------------------
--Sata Driver
--------------------------------------------------
p_out_sata_txn              => p_out_sata_txn,
p_out_sata_txp              => p_out_sata_txp,
p_in_sata_rxn               => p_in_sata_rxn,
p_in_sata_rxp               => p_in_sata_rxp,

p_in_sata_refclk            => p_in_sata_refclk,
p_out_sata_refclkout        => p_out_sata_refclkout,
p_out_sata_gt_plldet        => p_out_sata_gt_plldet,
p_out_sata_dcm_lock         => p_out_sata_dcm_lock,
p_out_sata_dcm_gclk2div     => p_out_sata_dcm_gclk2div,
p_out_sata_dcm_gclk2x       => p_out_sata_dcm_gclk2x,
p_out_sata_dcm_gclk0        => p_out_sata_dcm_gclk0,

--------------------------------------------------
--Связь с модулем dsn_hdd.vhd
--------------------------------------------------
p_in_usr_ctrl               => i_sh_ctrl,
p_out_usr_status            => i_sh_status,
p_out_measure               => i_sh_measure,

--//cmdpkt
p_in_usr_cxd                => i_sh_cxd,
p_in_usr_cxd_wr             => i_sh_cxd_rd,

--//txfifo
p_in_usr_txd                => i_sh_txd,
p_out_usr_txd_rd            => i_sh_txd_rd,
p_in_usr_txbuf_empty        => i_sh_txbuf_empty,

--//rxfifo
p_out_usr_rxd               => i_sh_rxd,
p_out_usr_rxd_wr            => i_sh_rxd_wr,
p_in_usr_rxbuf_full         => i_sh_rxbuf_full,

--------------------------------------------------
--//Debug/Sim
--------------------------------------------------
p_out_dbgcs                 => p_out_dbgcs,

p_out_sim_gt_txdata        => i_sh_sim_gt_txdata,
p_out_sim_gt_txcharisk     => i_sh_sim_gt_txcharisk,
p_out_sim_gt_txcomstart    => i_sh_sim_gt_txcomstart,
p_in_sim_gt_rxdata         => i_sh_sim_gt_rxdata,
p_in_sim_gt_rxcharisk      => i_sh_sim_gt_rxcharisk,
p_in_sim_gt_rxstatus       => i_sh_sim_gt_rxstatus,
p_in_sim_gt_rxelecidle     => i_sh_sim_gt_rxelecidle,
p_in_sim_gt_rxdisperr      => i_sh_sim_gt_rxdisperr,
p_in_sim_gt_rxnotintable   => i_sh_sim_gt_rxnotintable,
p_in_sim_gt_rxbyteisaligned=> i_sh_sim_gt_rxbyteisaligned,
p_out_gt_sim_rst           => i_sh_sim_gt_sim_rst,
p_out_gt_sim_clk           => i_sh_sim_gt_sim_clk,

--------------------------------------------------
--Технологические сигналы
--------------------------------------------------
p_in_tst                    => (others=>'0'),--tst_hdd_in,
p_out_tst                   => tst_hdd_out,
--------------------------------------------------
--System
--------------------------------------------------
p_in_clk                => p_in_clk,
p_in_rst                => p_in_rst
);

gen_hdd: for i in 0 to G_HDD_COUNT-1 generate
--p_out_dbgled(i).link<=i_sh_status.ch_sstatus(i)(C_ASSTAT_DET_BIT_L+0); --//Флаг C_PSTAT_DET_DEV_ON_BIT): Уст-во обнаружено
p_out_dbgled(i).link<=i_sh_status.ch_sstatus(i)(C_ASSTAT_DET_BIT_L+1); --//Флаг C_PSTAT_DET_ESTABLISH_ON_BIT: Уст-во обнаружено + Соединение установлено
p_out_dbgled(i).rdy<=i_sh_status.ch_rdy(i);--//Флаг C_ASSTAT_IPM_BIT_L: Уст-во обнаружено + Соединение установлено + сигнатура получена
p_out_dbgled(i).err<=i_sh_status.ch_err(i);
p_out_dbgled(i).busy<=i_sh_status.ch_bsy(i);
p_out_dbgled(i).spd<=i_sh_status.ch_sstatus(i)(C_ASSTAT_SPD_BIT_L+1 downto C_ASSTAT_SPD_BIT_L);--//Скорость соединения 1/2/3 - SATA-I/II/III
p_out_dbgled(i).dly<=i_sh_measure.dly;
end generate gen_hdd;

gen_nomax : if G_HDD_COUNT/=C_HDD_COUNT_MAX generate
gen_null: for i in G_HDD_COUNT to C_HDD_COUNT_MAX-1 generate
p_out_dbgled(i).link<='0';
p_out_dbgled(i).rdy<='0';
p_out_dbgled(i).err<='0';
p_out_dbgled(i).busy<='0';
p_out_dbgled(i).spd<=(others=>'0');
p_out_dbgled(i).dly<='0';
end generate gen_null;
end generate gen_nomax;

p_out_sim_gt_txdata        <= i_sh_sim_gt_txdata;
p_out_sim_gt_txcharisk     <= i_sh_sim_gt_txcharisk;
p_out_sim_gt_txcomstart    <= i_sh_sim_gt_txcomstart;
i_sh_sim_gt_rxdata         <= p_in_sim_gt_rxdata;
i_sh_sim_gt_rxcharisk      <= p_in_sim_gt_rxcharisk;
i_sh_sim_gt_rxstatus       <= p_in_sim_gt_rxstatus;
i_sh_sim_gt_rxelecidle     <= p_in_sim_gt_rxelecidle;
i_sh_sim_gt_rxdisperr      <= p_in_sim_gt_rxdisperr;
i_sh_sim_gt_rxnotintable   <= p_in_sim_gt_rxnotintable;
i_sh_sim_gt_rxbyteisaligned<= p_in_sim_gt_rxbyteisaligned;
p_out_gt_sim_rst           <= i_sh_sim_gt_sim_rst;
p_out_gt_sim_clk           <= i_sh_sim_gt_sim_clk;


end generate gen_use_on;




--//############################
--//USE - OFF (выбросить из проекта)
--//############################
gen_use_off : if strcmp(G_MODULE_USE,"OFF") generate

p_out_tst<=(others=>'0');
tst_hdd_out<=(others=>'0');


gen_satah : for sh_idx in 0 to C_SH_COUNT_MAX(G_HDD_COUNT-1)-1 generate

m_sata_gt : mclk_gtp_wrap
generic map(
G_SIM => G_SIM
)
port map(
p_out_txn => p_out_sata_txn(((C_SH_GTCH_COUNT_MAX*(sh_idx+1))-1) downto (C_SH_GTCH_COUNT_MAX*sh_idx)),
p_out_txp => p_out_sata_txp(((C_SH_GTCH_COUNT_MAX*(sh_idx+1))-1) downto (C_SH_GTCH_COUNT_MAX*sh_idx)),
p_in_rxn  => p_in_sata_rxn(((C_SH_GTCH_COUNT_MAX*(sh_idx+1))-1) downto (C_SH_GTCH_COUNT_MAX*sh_idx)),
p_in_rxp  => p_in_sata_rxp(((C_SH_GTCH_COUNT_MAX*(sh_idx+1))-1) downto (C_SH_GTCH_COUNT_MAX*sh_idx)),
clkin     => p_in_sata_refclk(sh_idx),
clkout    => i_sata_gt_refclk(sh_idx)
);

end generate gen_satah;

p_out_sata_refclkout<=i_sata_gt_refclk(0);
p_out_sata_gt_plldet<='1';
p_out_sata_dcm_lock<='1';

gen_null: for i in 0 to C_HDD_COUNT_MAX-1 generate
p_out_sim_gt_txdata(i)    <=(others=>'0');
p_out_sim_gt_txcharisk(i) <=(others=>'0');
p_out_sim_gt_txcomstart(i)<='0';
p_out_gt_sim_rst(i)       <='0';
p_out_gt_sim_clk(i)       <='0';

i_sh_status.ch_bsy(i)<='0';
i_sh_status.ch_rdy(i)<='0';
i_sh_status.ch_err(i)<='0';
i_sh_status.ch_ataerror(i)<=(others=>'0');
i_sh_status.ch_atastatus(i)<=(others=>'0');
i_sh_status.ch_serror(i)<=(others=>'0');
i_sh_status.ch_sstatus(i)<=(others=>'0');
i_sh_status.ch_usr(i)<=(others=>'0');

p_out_dbgled(i).link<='0';
p_out_dbgled(i).rdy<='0';
p_out_dbgled(i).err<='0';
p_out_dbgled(i).busy<='0';
p_out_dbgled(i).spd<=(others=>'0');
p_out_dbgled(i).dly<='0';

end generate gen_null;

i_sh_status.dev_bsy<='0';
i_sh_status.dev_rdy <='0';
i_sh_status.dev_err <='0';
i_sh_status.usr <=(others=>'0');
i_sh_status.lba_bp <=(others=>'0');

i_sh_measure.tdly  <=(others=>'0');
i_sh_measure.twork <=(others=>'0');

p_out_hdd_txbuf_full<=i_sh_cxd_wr;
p_out_hdd_txbuf_pfull<=i_sh_cxd_wr;

process(p_in_rst,i_sata_gt_refclk(0))
begin
  if p_in_rst='1' then
    i_sh_rxd<=(others=>'0');

  elsif i_sata_gt_refclk(0)'event and i_sata_gt_refclk(0)='1' then
    i_sh_rxd<=EXT(p_in_cfg_txdata, i_sh_rxd'length);
  end if;
end process;

p_out_hdd_rxd <=i_sh_rxd;
p_out_hdd_rxbuf_empty<=i_sh_cxd_wr;
--p_out_hdd_rxbuf_pempty<=i_sh_cxd_wr;


i_sh_atadone_ack<='0';
i_sh_done<='0';


end generate gen_use_off;

--END MAIN
end behavioral;
