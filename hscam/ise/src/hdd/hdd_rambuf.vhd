-------------------------------------------------------------------------
-- Company     : Linkos
-- Engineer    : Golovachenko Victor
--
-- Create Date : 28.04.2011 17:34:40
-- Module Name : dsn_hdd_rambuf
--
-- Назначение/Описание :
--  Буферизация данных для HDD через ОЗУ
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
use work.vicg_common_pkg.all;
use work.mem_wr_pkg.all;
use work.sata_glob_pkg.all;
use work.sata_pkg.all;
use work.sata_raid_pkg.all;
use work.sata_testgen_pkg.all;
use work.sata_sim_lite_pkg.all;
use work.dsn_hdd_pkg.all;

entity dsn_hdd_rambuf is
generic(
G_MODULE_USE  : string:="ON";
G_RAMBUF_SIZE : integer:=23; --//(в BYTE). Определяется как 2 в степени G_RAMBUF_SIZE
G_DBGCS       : string:="OFF";
G_SIM         : string:="OFF";
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

----------------------------
--Связь с буфером видеоданных
----------------------------
p_in_vbuf_dout        : in    std_logic_vector(31 downto 0);
p_out_vbuf_rd         : out   std_logic;
p_in_vbuf_empty       : in    std_logic;
p_in_vbuf_full        : in    std_logic;
p_in_vbuf_pfull       : in    std_logic;
p_in_vbuf_wrcnt       : in    std_logic_vector(3 downto 0);

----------------------------
--Связь с модулем HDD
----------------------------
p_out_hdd_txd         : out   std_logic_vector(31 downto 0);
p_out_hdd_txd_wr      : out   std_logic;
p_in_hdd_txbuf_pfull  : in    std_logic;
p_in_hdd_txbuf_full   : in    std_logic;
p_in_hdd_txbuf_empty  : in    std_logic;

p_in_hdd_rxd          : in    std_logic_vector(31 downto 0);
p_out_hdd_rxd_rd      : out   std_logic;
p_in_hdd_rxbuf_empty  : in    std_logic;
p_in_hdd_rxbuf_pempty : in    std_logic;

---------------------------------
-- Связь с mem_ctrl.vhd
---------------------------------
--p_out_mem             : out   TMemIN;
--p_in_mem              : in    TMemOUT;
--CH WRITE
p_out_memwr           : out   TMemIN;
p_in_memwr            : in    TMemOUT;
--CH READ
p_out_memrd           : out   TMemIN;
p_in_memrd            : in    TMemOUT;

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
end dsn_hdd_rambuf;

architecture behavioral of dsn_hdd_rambuf is

--//selval(true, false , select(true/false) );
constant CI_SECTOR_SIZE_BYTE : integer:=selval(C_SECTOR_SIZE_BYTE, C_SIM_SECTOR_SIZE_DWORD*4, strcmp(G_SIM, "OFF"));

-- Small delay for simulation purposes.
constant dly : time := 1 ps;

component hdd_ram_hfifo_tx
port(
din         : in std_logic_vector(15 downto 0);
wr_en       : in std_logic;
wr_clk      : in std_logic;

dout        : out std_logic_vector(31 downto 0);
rd_en       : in std_logic;
rd_clk      : in std_logic;

full        : out std_logic;
almost_full : out std_logic;
empty       : out std_logic;

--clk         : in std_logic;
rst         : in std_logic
);
end component;

component hdd_ram_hfifo_rx
port(
din         : in std_logic_vector(31 downto 0);
wr_en       : in std_logic;
wr_clk      : in std_logic;

dout        : out std_logic_vector(15 downto 0);
rd_en       : in std_logic;
rd_clk      : in std_logic;

full        : out std_logic;
almost_full : out std_logic;
prog_full   : out std_logic;
empty       : out std_logic;

--clk         : in std_logic;
rst         : in std_logic
);
end component;

type fsm_state is (
S_IDLE,

S_SW_WAIT,
S_SW_MEM_CHECK,
S_SW_MEM_START,
S_SW_MEM_WORK,

S_HW_MEMW_CHECK,
S_HW_MEMR_CHECK,

S_HW_MEMA_CHECK1,
S_HW_MEMA_CHECK2,
S_HW_MEMA_CHECK3,

S_HW_MEM_START,
S_HW_MEM_WORK,
S_HW_FULL_CHECK,

S_HWLOG_WAIT_TRNDONE,
S_HWLOG_MEM_START,
S_HWLOG_MEM_WORK,

S_CR_MEM_START,
S_CR_MEM_WORK
);
signal fsm_rambuf_cs                   : fsm_state;

signal i_rbuf_cfg                      : TDMAcfg;
signal i_hwlog                         : THWLog;
signal i_tstgen                        : THDDTstGen;

signal i_err_det                       : THDDRBufErrDetect;

signal i_hddcnt                        : std_logic_vector(2 downto 0);

signal i_doble_act                     : std_logic;--//Кол-во операций с ОЗУ для текущего размера данных
signal i_doble_act_cnt                 : std_logic;--//Индекс операции
signal i_ptr                           : std_logic_vector(31 downto 0);--//(BYTE)
signal i_ptr_tmpa2                     : std_logic_vector(31 downto 0);--//(BYTE)
signal i_lenreq_a2                     : std_logic_vector(15 downto 0);--//(DWORD)
signal i_lenreq_a1                     : std_logic_vector(15 downto 0);--//(DWORD)
signal i_lenreq                        : std_logic_vector(15 downto 0);--//(DWORD)

signal i_wr_lentrn                     : std_logic_vector(15 downto 0);--//(DWORD)
signal i_rd_lentrn                     : std_logic_vector(15 downto 0);--//(DWORD)
signal i_wr_ptr                        : std_logic_vector(31 downto 0);--//(BYTE)
signal i_rd_ptr                        : std_logic_vector(31 downto 0);--//(BYTE)

signal i_rambuf_dcnt                   : std_logic_vector(31 downto 0);--//(DWORD) - счтечик данных в RAMBUF
signal i_rambuf_done                   : std_logic;
signal i_rambuf_full                   : std_logic;

signal i_vbuf_pfull                    : std_logic:='0';
signal i_vbuf_wrcnt                    : std_logic_vector(p_in_vbuf_wrcnt'range):=(others=>'0');
signal i_hdd_txbuf_pfull               : std_logic:='0';

signal i_mem_adr_update                : std_logic_vector(31 downto 0);--//(BYTE)
signal i_mem_adr                       : std_logic_vector(31 downto 0);--//(BYTE)
signal i_mem_lenreq                    : std_logic_vector(15 downto 0);--//Размер запрашиваемых данных (DWORD)
signal i_mem_lentrn                    : std_logic_vector(15 downto 0);--//Размер одиночной транзакции
signal i_mem_dir                       : std_logic;
signal i_mem_start                     : std_logic;
signal i_mem_done                      : std_logic;
signal i_mem_wrstart,i_mem_rdstart     : std_logic;
signal i_mem_wrdone,i_mem_rddone       : std_logic;

signal i_atacmd_scount                 : std_logic_vector(15 downto 0);
signal i_atacmd_dcount_byte            : std_logic_vector(i_atacmd_scount'length + log2(CI_SECTOR_SIZE_BYTE)-1 downto 0);
signal i_atacmd_dcount_dw              : std_logic_vector(i_atacmd_dcount_byte'range);
signal i_atadone                       : std_logic;

signal i_mem_din_1tmp                  : std_logic_vector(31 downto 0);
signal i_mem_din_2tmp                  : std_logic_vector(31 downto 0);
signal i_mem_din_rdy_1tmp              : std_logic;
signal i_mem_din_rdy_2tmp              : std_logic;
signal i_mem_din                       : std_logic_vector(31 downto 0);
signal i_mem_din_rdy                   : std_logic;
signal i_mem_din_rd                    : std_logic;
signal i_mem_dout                      : std_logic_vector(31 downto 0);
signal i_mem_dout_wr                   : std_logic;
signal i_mem_dout_wrdy                 : std_logic;

signal sr_hwlog_atatrn                 : std_logic_vector(0 to 1);
signal i_hwlog_atatrn_done             : std_logic;
type THWlogData is array (0 to 0) of std_logic_vector(31 downto 0);
signal i_hwlog_d                       : THWlogData;
signal i_hw_p0                         : std_logic_vector(11 downto 0):=(others=>'0');
signal i_hw_p1                         : std_logic_vector(3 downto 0):=(others=>'0');

--CFG<->RAM
signal sr_cr_start                     : std_logic_vector(0 to 2);
signal i_cr_start                      : std_logic;
signal i_cr_buf_rst                    : std_logic;
signal i_cr_txbuf_dout                 : std_logic_vector(31 downto 0);
signal i_cr_txbuf_rd                   : std_logic;
signal i_cr_txbuf_empty                : std_logic;
signal i_cr_txbuf_full                 : std_logic;
signal i_cr_rxbuf_wr                   : std_logic;
signal i_cr_rxbuf_empty                : std_logic;
signal i_cr_rxbuf_full                 : std_logic;


signal tst_rambuf_empty                : std_logic;
signal tst_rambuf_pfull                : std_logic:='0';
signal tst_fsm_cs                      : std_logic_vector(4 downto 0);
signal sr_hw_work                      : std_logic_vector(0 to 1):=(others=>'0');
signal tst_hw_stop                     : std_logic:='0';
signal tst_mem_ctrl_out                : std_logic_vector(31 downto 0);
signal tst_timeout_cnt                 : std_logic_vector(11 downto 0);
signal tst_timeout                     : std_logic;
signal tst_vbuf_wrcnt_max              : std_logic_vector(i_vbuf_wrcnt'range);
signal tst_rambuf_dcnt_max             : std_logic_vector(i_rambuf_dcnt'range);
signal tst_rambuf_dcnt_max_clr         : std_logic;

signal tst_vwr_out                     : std_logic_vector(31 downto 0);
signal tst_vrd_out                     : std_logic_vector(31 downto 0);


--MAIN
begin


gen_use_on : if strcmp(G_MODULE_USE,"ON") generate

--//----------------------------------
--//Технологические сигналы
--//----------------------------------
p_out_tst(4 downto 0)  <=tst_vwr_out(4 downto 0);
p_out_tst(9 downto 5)  <=tst_vrd_out(4 downto 0);
p_out_tst(11 downto 10)<=(others=>'0');
p_out_tst(13 downto 12)<=(others=>'0');
p_out_tst(14)          <=i_cr_start;
p_out_tst(15)          <='0';

p_out_tst(16)          <=tst_vwr_out(5);
p_out_tst(17)          <=tst_vrd_out(5);
p_out_tst(18)          <=tst_vwr_out(6);
p_out_tst(19)          <=tst_vrd_out(6);
p_out_tst(20)          <=i_cr_txbuf_rd;
p_out_tst(21)          <=i_cr_rxbuf_wr;
p_out_tst(22)          <=i_cr_txbuf_empty;
p_out_tst(23)          <=i_cr_rxbuf_empty;
p_out_tst(24)          <=i_cr_txbuf_full;
p_out_tst(25)          <=i_cr_rxbuf_full;
p_out_tst(30 downto 26)<=tst_fsm_cs;
p_out_tst(31)<='0';

tst_fsm_cs<=CONV_STD_LOGIC_VECTOR(16#01#,tst_fsm_cs'length) when fsm_rambuf_cs=S_SW_WAIT            else
            CONV_STD_LOGIC_VECTOR(16#02#,tst_fsm_cs'length) when fsm_rambuf_cs=S_SW_MEM_CHECK       else
            CONV_STD_LOGIC_VECTOR(16#03#,tst_fsm_cs'length) when fsm_rambuf_cs=S_SW_MEM_START       else
            CONV_STD_LOGIC_VECTOR(16#04#,tst_fsm_cs'length) when fsm_rambuf_cs=S_SW_MEM_WORK        else
            CONV_STD_LOGIC_VECTOR(16#05#,tst_fsm_cs'length) when fsm_rambuf_cs=S_HW_MEMW_CHECK      else
            CONV_STD_LOGIC_VECTOR(16#06#,tst_fsm_cs'length) when fsm_rambuf_cs=S_HW_MEMR_CHECK      else
            CONV_STD_LOGIC_VECTOR(16#07#,tst_fsm_cs'length) when fsm_rambuf_cs=S_HW_MEMA_CHECK1     else
            CONV_STD_LOGIC_VECTOR(16#08#,tst_fsm_cs'length) when fsm_rambuf_cs=S_HW_MEMA_CHECK2     else
            CONV_STD_LOGIC_VECTOR(16#09#,tst_fsm_cs'length) when fsm_rambuf_cs=S_HW_MEMA_CHECK3     else
            CONV_STD_LOGIC_VECTOR(16#0A#,tst_fsm_cs'length) when fsm_rambuf_cs=S_HW_MEM_START       else
            CONV_STD_LOGIC_VECTOR(16#0B#,tst_fsm_cs'length) when fsm_rambuf_cs=S_HW_MEM_WORK        else
            CONV_STD_LOGIC_VECTOR(16#0C#,tst_fsm_cs'length) when fsm_rambuf_cs=S_HW_FULL_CHECK      else
            CONV_STD_LOGIC_VECTOR(16#0D#,tst_fsm_cs'length) when fsm_rambuf_cs=S_HWLOG_WAIT_TRNDONE else
            CONV_STD_LOGIC_VECTOR(16#0E#,tst_fsm_cs'length) when fsm_rambuf_cs=S_HWLOG_MEM_START    else
            CONV_STD_LOGIC_VECTOR(16#0F#,tst_fsm_cs'length) when fsm_rambuf_cs=S_HWLOG_MEM_WORK     else
            CONV_STD_LOGIC_VECTOR(16#10#,tst_fsm_cs'length) when fsm_rambuf_cs=S_CR_MEM_START       else
            CONV_STD_LOGIC_VECTOR(16#11#,tst_fsm_cs'length) when fsm_rambuf_cs=S_CR_MEM_WORK        else
            CONV_STD_LOGIC_VECTOR(16#00#,tst_fsm_cs'length); --//when fsm_rambuf_cs=S_IDLE          else


--//----------------------------------------------
--//Инициализация
--//----------------------------------------------
i_cr_buf_rst <= p_in_rst or i_rbuf_cfg.clr_err;

process(p_in_clk)
begin
  if p_in_clk'event and p_in_clk='1' then
    i_vbuf_wrcnt<=p_in_vbuf_wrcnt;
    i_vbuf_pfull<=p_in_vbuf_pfull;
    i_hdd_txbuf_pfull<=p_in_hdd_txbuf_pfull;

    i_rbuf_cfg<=p_in_rbuf_cfg.dmacfg;
    i_hwlog<=p_in_rbuf_cfg.hwlog;

    i_tstgen.tesing_on<=p_in_rbuf_cfg.tstgen.tesing_on;
    i_tstgen.con2rambuf<=p_in_rbuf_cfg.tstgen.con2rambuf;

    i_hw_p0<=p_in_rbuf_cfg.usr(11 downto 0);
    i_hw_p1<=p_in_rbuf_cfg.usr(15 downto 12);
  end if;
end process;

i_hwlog_d(0)<=i_hwlog.tdly;
--i_hwlog_d(0)<=i_hwlog.twork;


--//----------------------------------------------
--//Статусы
--//----------------------------------------------
p_out_rbuf_status.err<=i_err_det.rambuf_full or i_err_det.vinbuf_full;
p_out_rbuf_status.err_type<=i_err_det;
p_out_rbuf_status.done<=i_rambuf_done;
p_out_rbuf_status.hwlog_size<=i_wr_ptr;

p_out_rbuf_status.ram_wr_o.wr_rdy <= not i_cr_txbuf_full;--//RAM<-CFG
p_out_rbuf_status.ram_wr_o.rd_rdy <= not i_cr_rxbuf_empty;--//RAM->CFG


--//Сброс/детектирование переполнения потокового буфера +
--//входного видео буфера
process(p_in_rst,p_in_clk)
begin
  if p_in_rst='1' then
    i_err_det.vinbuf_full<='0';
    i_err_det.rambuf_full<='0';
  elsif p_in_clk'event and p_in_clk='1' then

    if i_rbuf_cfg.clr_err='1' then
      i_err_det.rambuf_full<='0';
    elsif i_rambuf_full='1' and
          (i_rbuf_cfg.sw_mode='1' or i_rbuf_cfg.hw_mode='1') then
      i_err_det.rambuf_full<='1';
    end if;

    if i_rbuf_cfg.clr_err='1' then
      i_err_det.vinbuf_full<='0';
    elsif p_in_vbuf_full='1' and
          (i_rbuf_cfg.sw_mode='1' or i_rbuf_cfg.hw_mode='1') then
      i_err_det.vinbuf_full<='1';
    end if;

  end if;
end process;

--//Обнаружение сигнала - АТА команда завершена
process(p_in_rst,p_in_clk)
begin
  if p_in_rst='1' then
    i_atadone<='0';
  elsif p_in_clk'event and p_in_clk='1' then
    if fsm_rambuf_cs=S_IDLE then
      i_atadone<='0';
    elsif i_rbuf_cfg.atadone='1' then
      i_atadone<='1';
    end if;
  end if;
end process;

process(p_in_rst,p_in_clk)
begin
  if p_in_rst='1' then
    sr_hwlog_atatrn<=(others=>'0');
    i_hwlog_atatrn_done<='0';
  elsif p_in_clk'event and p_in_clk='1' then
    sr_hwlog_atatrn<=i_hwlog.measure & sr_hwlog_atatrn(0 to 0);
    i_hwlog_atatrn_done<=not sr_hwlog_atatrn(0) and sr_hwlog_atatrn(1);
  end if;
end process;


--//----------------------------------------------
--//Автомат управления записю/чтение данных ОЗУ
--//----------------------------------------------
i_atacmd_dcount_byte<=i_atacmd_scount&CONV_STD_LOGIC_VECTOR(0, log2(CI_SECTOR_SIZE_BYTE));
i_atacmd_dcount_dw<=("00"&i_atacmd_dcount_byte(i_atacmd_dcount_byte'high downto 2));

gen_memd8 : if G_MEM_DWIDTH=8 generate
i_mem_adr_update<=(CONV_STD_LOGIC_VECTOR(0, (i_mem_adr'length - i_mem_lentrn'length)) & i_mem_lentrn);
end generate gen_memd8;

gen_memd_more8 : if G_MEM_DWIDTH>8 generate
i_mem_adr_update<=(CONV_STD_LOGIC_VECTOR(0, (i_mem_adr'length - i_mem_lentrn'length - log2(G_MEM_DWIDTH/8))) & i_mem_lentrn & CONV_STD_LOGIC_VECTOR(0,log2(G_MEM_DWIDTH/8)) );
end generate gen_memd_more8;

--//Логика работы автомата
process(p_in_rst,p_in_clk)
begin
  if p_in_rst='1' then

    fsm_rambuf_cs <= S_IDLE;
    i_hddcnt<=(others=>'0');

    i_doble_act<='0';
    i_doble_act_cnt<='0';
    i_ptr<=(others=>'0');
    i_ptr_tmpa2<=(others=>'0');
    i_lenreq_a2<=(others=>'0');
    i_lenreq_a1<=(others=>'0');

    i_rambuf_dcnt<=(others=>'0');
    i_rambuf_done<='0';
    i_rambuf_full<='0';

    i_lenreq<=(others=>'0');

    i_wr_lentrn<=(others=>'0');
    i_rd_lentrn<=(others=>'0');
    i_wr_ptr<=(others=>'0');
    i_rd_ptr<=(others=>'0');

    i_mem_adr<=(others=>'0');
    i_mem_lentrn<=(others=>'0');
    i_mem_lenreq<=(others=>'0');
    i_mem_dir<='0';
    i_mem_start<='0';

    i_atacmd_scount<=(others=>'0');

    tst_rambuf_dcnt_max_clr<='0';
    tst_rambuf_pfull<='0';

  elsif p_in_clk'event and p_in_clk='1' then

    case fsm_rambuf_cs is

      --//####################################
      --//Исходное состояние
      --//####################################
      when S_IDLE =>

        i_rambuf_done<='0';

        i_wr_lentrn<="00000000"&p_in_rbuf_cfg.mem_trn(7 downto 0); --Размер одиночной транзакций ОЗУ (DWORD)
        i_rd_lentrn<="00000000"&p_in_rbuf_cfg.mem_trn(15 downto 8);

        i_hddcnt<=(others=>'0');
        i_rambuf_dcnt<=(others=>'0');
        i_ptr<=(others=>'0');
        i_wr_ptr<=(others=>'0');
        i_rd_ptr<=(others=>'0');

        if i_cr_start='1' then
          --//RAM<->CFG
          fsm_rambuf_cs <= S_CR_MEM_START;

        elsif i_tstgen.tesing_on='1' and i_tstgen.con2rambuf='0' then
          if i_rbuf_cfg.hw_mode='1' and i_hwlog.log_on='1' then
          --//Начало работы режима HW + HWLOG=ON
            fsm_rambuf_cs <= S_HWLOG_WAIT_TRNDONE;
          else
            fsm_rambuf_cs <= S_IDLE;
          end if;

        elsif i_rbuf_cfg.armed='1' then
          --//Готовим контроллер ОЗУ:
          i_atacmd_scount<=i_rbuf_cfg.scount;

          if i_rbuf_cfg.sw_mode='1' and i_rbuf_cfg.scount/=(i_rbuf_cfg.scount'range =>'0') then
            fsm_rambuf_cs <= S_SW_WAIT;

          elsif i_rbuf_cfg.hw_mode='1' then
            tst_rambuf_dcnt_max_clr<='1';
            fsm_rambuf_cs <= S_HW_MEMW_CHECK;

          else
            fsm_rambuf_cs <= S_IDLE;
          end if;
        end if;

      --//####################################
      --//Режим работы SW
      --//####################################
      --//Ждем сигнала запуска
      when S_SW_WAIT =>

        i_rambuf_dcnt(15 downto 0)<=i_atacmd_dcount_dw(15 downto 0);

        if i_rbuf_cfg.atacmdw='1' then
        --//RAM->HDD
          i_mem_lenreq<=i_rd_lentrn;
          i_mem_lentrn<=i_rd_lentrn;--//размер одиночной транзакции.(Устанавливается программно)
          i_mem_dir<=C_MEMWR_READ;
          fsm_rambuf_cs <= S_SW_MEM_CHECK;

        elsif p_in_hdd_rxbuf_pempty='0' or i_atadone='1' then
        --//RAM<-HDD
          i_mem_lenreq<=i_wr_lentrn;
          i_mem_lentrn<=i_wr_lentrn;--//размер одиночной транзакции.(Устанавливается программно)
          i_mem_dir<=C_MEMWR_WRITE;
          fsm_rambuf_cs <= S_SW_MEM_CHECK;
        end if;

      --//Проверка окончания записи/чтения
      when S_SW_MEM_CHECK =>

        if i_rambuf_dcnt(15 downto 0)=(i_rambuf_dcnt'range =>'0') then
          if i_rbuf_cfg.raid.used='0' then
          --//Работа с одним HDD
            i_rambuf_done<='1';
            fsm_rambuf_cs <= S_IDLE;
          else
          --//Работа с RAID
            if i_hddcnt=i_rbuf_cfg.raid.hddcount then
              i_rambuf_done<='1';
              fsm_rambuf_cs <= S_IDLE;
            else
              i_rambuf_dcnt(15 downto 0)<=i_atacmd_dcount_dw(15 downto 0);
              i_hddcnt<=i_hddcnt + 1;
              fsm_rambuf_cs <= S_SW_MEM_START;
            end if;
          end if;

        else

          if i_rambuf_dcnt(15 downto 0)<=i_mem_lenreq then
            i_mem_lenreq<=i_rambuf_dcnt(15 downto 0);
          end if;

          fsm_rambuf_cs <= S_SW_MEM_START;
        end if;

      --//Запуск mem транзакции
      when S_SW_MEM_START =>

        --//Check HDD_FIFO
        if i_mem_dir=C_MEMWR_WRITE then
        --//RAM<-HDD
        --//Ждем когда в hdd_rxbuf накопится данные
          if p_in_hdd_rxbuf_pempty='0' or i_atadone='1' then
            i_mem_adr<=i_wr_ptr + p_in_rbuf_cfg.mem_adr;--ptr + base_adr
            i_mem_start<='1';
            fsm_rambuf_cs <= S_SW_MEM_WORK;
          end if;

        else
        --//RAM->HDD
        --//Ждем когда в hdd_txbuf можно будет передовать данные
          if i_hdd_txbuf_pfull='0' then
            i_mem_adr<=i_wr_ptr + p_in_rbuf_cfg.mem_adr;--ptr + base_adr
            i_mem_start<='1';
            fsm_rambuf_cs <= S_SW_MEM_WORK;
          end if;

        end if;

      --//Отработка mem транзакции
      when S_SW_MEM_WORK =>

        i_mem_start<='0';
        if i_mem_done='1' then
          i_wr_ptr<=i_wr_ptr + i_mem_adr_update;
          i_rambuf_dcnt<=i_rambuf_dcnt - EXT(i_mem_lenreq, i_rambuf_dcnt'length);
          fsm_rambuf_cs <= S_SW_MEM_CHECK;
        end if;


      --//####################################
      --//Режим работы HW
      --//####################################
      --//----------------------------------------------
      --//Выбор операции
      --//----------------------------------------------
      --//WRITE
      when S_HW_MEMW_CHECK =>
        tst_rambuf_dcnt_max_clr<='0';
        tst_rambuf_pfull<='0';

        if i_rbuf_cfg.hw_mode='0' then
        --//HW mode - DONE!!!
          fsm_rambuf_cs <= S_IDLE;

        else
          if i_vbuf_pfull='1' then
              --//Назначаем размер данных которые будем записывать в RAMBUF
              if i_vbuf_wrcnt>CONV_STD_LOGIC_VECTOR(7, i_vbuf_wrcnt'length) then
                i_lenreq<=CONV_STD_LOGIC_VECTOR(512, i_lenreq'length);

              elsif i_vbuf_wrcnt>CONV_STD_LOGIC_VECTOR(5, i_vbuf_wrcnt'length) then
                i_lenreq<=CONV_STD_LOGIC_VECTOR(256, i_lenreq'length);

              elsif i_vbuf_wrcnt>CONV_STD_LOGIC_VECTOR(3, i_vbuf_wrcnt'length) then
                i_lenreq<=CONV_STD_LOGIC_VECTOR(128, i_lenreq'length);

              else
                i_lenreq<=i_wr_lentrn;
              end if;

              if i_wr_ptr(G_RAMBUF_SIZE)='1' then
                --//Закольцовываю указатель RAMBUF
                i_wr_ptr<=(others=>'0');
              end if;
              i_mem_dir<=C_MEMWR_WRITE;
              fsm_rambuf_cs <= S_HW_MEMA_CHECK1;--//Переход к анализу кол-ва операций с ОЗУ

          else
            --//Еще не накопилось нужное кол-во данных для записи!!!
            fsm_rambuf_cs <= S_HW_MEMR_CHECK;--//Переход к анализу ЧТЕНИЯ
          end if;
        end if;

      --//READ
      when S_HW_MEMR_CHECK =>

        i_rambuf_full<='0';

        if i_hdd_txbuf_pfull='0' and i_rambuf_dcnt/=(i_rambuf_dcnt'range =>'0') then

            --//Назначаем размер данных которые будем вычитывать из RAMBUF
            if i_rambuf_dcnt>EXT(i_hw_p0,i_rambuf_dcnt'length) then
              if i_vbuf_wrcnt>i_hw_p1 then
              i_lenreq<=CONV_STD_LOGIC_VECTOR(512, i_lenreq'length);
              else
              i_lenreq<=EXT(i_hw_p0, i_lenreq'length);
              end if;
              tst_rambuf_pfull<='1';

            else
               i_lenreq<=i_rambuf_dcnt(15 downto 0);
            end if;

            if i_rd_ptr(G_RAMBUF_SIZE)='1' then
              --//Закольцовываю указатель RAMBUF
              i_rd_ptr<=(others=>'0');
            end if;

            i_mem_dir<=C_MEMWR_READ;
            fsm_rambuf_cs <= S_HW_MEMA_CHECK1;--//Переход к анализу кол-ва операций с ОЗУ

        else
          fsm_rambuf_cs <= S_HW_MEMW_CHECK;--//Переход к анализу ЗАПИСИ
        end if;


      --//----------------------------------------------
      --//Анализ кол-ва операций(Action) с ОЗУ
      --//----------------------------------------------
      when S_HW_MEMA_CHECK1 =>

        tst_rambuf_pfull<='0';

        --//т.к. i_ptr (BYTE), а i_lenreq(DWORD)
        if i_mem_dir=C_MEMWR_WRITE then
        i_ptr<=i_wr_ptr + ("00000000"&"00000000"&i_lenreq(13 downto 0)&"00");
        else
        i_ptr<=i_rd_ptr + ("00000000"&"00000000"&i_lenreq(13 downto 0)&"00");
        end if;
        fsm_rambuf_cs <= S_HW_MEMA_CHECK2;

      when S_HW_MEMA_CHECK2 =>

        --//Анализируем какое кол-во операций с ОЗУ нужно для
        --//установленого размера данных
        if i_ptr <= CONV_STD_LOGIC_VECTOR(pwr(2,G_RAMBUF_SIZE), i_ptr'length) then
          --//1 операция
          i_doble_act<='0';
          i_lenreq_a1<=i_lenreq;
          fsm_rambuf_cs <= S_HW_MEM_START;--//Переход к ЗАПИСИ/ЧТЕНИЯ ОЗУ

        else
          --//2 операции
          i_doble_act<='1';
          i_ptr_tmpa2<=i_ptr - CONV_STD_LOGIC_VECTOR(pwr(2,G_RAMBUF_SIZE), i_ptr'length);
          fsm_rambuf_cs <= S_HW_MEMA_CHECK3;
        end if;

      when S_HW_MEMA_CHECK3 =>

        i_lenreq_a2<="00"&i_ptr_tmpa2(15 downto 2); --//т.к. i_ptr_tmpa2 (BYTE), а i_lenreq_a2(DWORD)
        i_lenreq_a1<=i_lenreq - ("00"&i_ptr_tmpa2(15 downto 2));
        fsm_rambuf_cs <= S_HW_MEM_START;--//Переход к ЗАПИСИ/ЧТЕНИЯ ОЗУ


      --//------------------------------------
      --//Запись/Чтение ОЗУ
      --//------------------------------------
      when S_HW_MEM_START =>

        --//Update ADDR RAMBUF
        if i_mem_dir=C_MEMWR_WRITE then
            if i_wr_ptr(G_RAMBUF_SIZE)='1' then
              --//Закольцовываю указатель RAMBUF
              i_wr_ptr<=(others=>'0');
              i_mem_adr<=p_in_rbuf_cfg.mem_adr;
            else
              i_mem_adr<=i_wr_ptr + p_in_rbuf_cfg.mem_adr;--ptr + base_adr
            end if;
        else
            if i_rd_ptr(G_RAMBUF_SIZE)='1' then
              --//Закольцовываю указатель RAMBUF
              i_rd_ptr<=(others=>'0');
              i_mem_adr<=p_in_rbuf_cfg.mem_adr;
            else
              i_mem_adr<=i_rd_ptr + p_in_rbuf_cfg.mem_adr;--ptr + base_adr
            end if;
        end if;

        if i_doble_act_cnt='0' then
          i_mem_lenreq<=i_lenreq_a1;
          i_mem_lentrn<=i_lenreq_a1;
--          if i_doble_act='1' then
--          i_mem_lentrn<=i_lenreq_a1;
--          else
--          i_mem_lentrn<=i_lenreq;--//i_wr_lentrn; --//размер одиночной транзакции
--          end if;
        else
          i_mem_lenreq<=i_lenreq_a2;
          i_mem_lentrn<=i_lenreq_a2;
        end if;

        if i_rbuf_cfg.hw_mode='0' then
        --//HW mode - DONE!!!
          fsm_rambuf_cs <= S_IDLE;
        else
          i_mem_start<='1';
          fsm_rambuf_cs <= S_HW_MEM_WORK;
        end if;

      when S_HW_MEM_WORK =>

        i_mem_start<='0';
        if i_mem_done='1' then

          --//Обновляем указатель + уровень данных в буфере
          if i_mem_dir=C_MEMWR_WRITE then
              i_wr_ptr<=i_wr_ptr + i_mem_adr_update;
              i_rambuf_dcnt<=i_rambuf_dcnt + EXT(i_mem_lenreq, i_rambuf_dcnt'length);

              if i_doble_act='0' then
              fsm_rambuf_cs <= S_HW_FULL_CHECK;
              else
                if i_doble_act_cnt='1' then
                  i_doble_act_cnt<='0';
                  fsm_rambuf_cs <= S_HW_FULL_CHECK;
                else
                  i_doble_act_cnt<='1';
                  fsm_rambuf_cs <= S_HW_MEM_START;
                end if;
              end if;
          else
              i_rd_ptr<=i_rd_ptr + i_mem_adr_update;
              i_rambuf_dcnt<=i_rambuf_dcnt - EXT(i_mem_lenreq, i_rambuf_dcnt'length);

              if i_doble_act='0' then
              fsm_rambuf_cs <= S_HW_MEMW_CHECK;--//Переход к анализу ЗАПИСИ
              else
                if i_doble_act_cnt='1' then
                  i_doble_act_cnt<='0';
                  fsm_rambuf_cs <= S_HW_MEMW_CHECK;--//Переход к анализу ЗАПИСИ
                else
                  i_doble_act_cnt<='1';
                  fsm_rambuf_cs <= S_HW_MEM_START;
                end if;
              end if;
          end if;

        end if;

      when S_HW_FULL_CHECK =>

        if i_rambuf_dcnt>CONV_STD_LOGIC_VECTOR(pwr(2,G_RAMBUF_SIZE-2), i_rambuf_dcnt'length) then
          i_rd_ptr<=i_wr_ptr;
          i_rambuf_full<='1';
          i_rambuf_dcnt<=CONV_STD_LOGIC_VECTOR(pwr(2,G_RAMBUF_SIZE-2), i_rambuf_dcnt'length);
        end if;

        fsm_rambuf_cs <= S_HW_MEMR_CHECK;--//Переход к анализу ЧТЕНИЯ



      --//####################################
      --//HWLOG
      --//####################################
      --//Ждем завершение текущей транзакции
      when S_HWLOG_WAIT_TRNDONE =>

        if i_rbuf_cfg.hw_mode='0' then
          fsm_rambuf_cs <= S_IDLE;
        else
          if i_hwlog_atatrn_done='1' then
            fsm_rambuf_cs <= S_HWLOG_MEM_START;
          end if;
        end if;

      --//Ведем LOG
      when S_HWLOG_MEM_START =>

        i_mem_adr<=i_wr_ptr + p_in_rbuf_cfg.mem_adr;--ptr + base_adr
        i_mem_lenreq<=CONV_STD_LOGIC_VECTOR(i_hwlog_d'length, i_mem_lenreq'length);
        i_mem_lentrn<=CONV_STD_LOGIC_VECTOR(i_hwlog_d'length, i_mem_lenreq'length);
        i_mem_dir<=C_MEMWR_WRITE;
        i_mem_start<='1';
        fsm_rambuf_cs <= S_HWLOG_MEM_WORK;

      --//Отработка mem транзакции
      when S_HWLOG_MEM_WORK =>

        i_mem_start<='0';
        if i_mem_done='1' then
          i_wr_ptr<=i_wr_ptr + i_mem_adr_update;
          fsm_rambuf_cs <= S_HWLOG_WAIT_TRNDONE;
        end if;



      --//####################################
      --//CFG<->RAM
      --//####################################
      when S_CR_MEM_START =>

        i_mem_adr<=p_in_rbuf_cfg.mem_adr;
        i_mem_lenreq<=p_in_rbuf_cfg.ram_wr_i.reqlen; --//DW
        i_mem_start<='1';

        if p_in_rbuf_cfg.ram_wr_i.dir='1' then
          --RAM<-CFG
          i_mem_lentrn<=i_wr_lentrn; --//размер одиночной транзакции.(Устанавливается программно)
          i_mem_dir<=C_MEMWR_WRITE;
        else
          --RAM->CFG
          i_mem_lentrn<=i_rd_lentrn; --//размер одиночной транзакции.(Устанавливается программно)
          i_mem_dir<=C_MEMWR_READ;
        end if;

        fsm_rambuf_cs <= S_CR_MEM_WORK;

      when S_CR_MEM_WORK =>

        i_mem_start<='0';
        if i_mem_done='1' then
          fsm_rambuf_cs <= S_IDLE;
        end if;

    end case;
  end if;
end process;



--//------------------------------------------------------
--//Модуль записи/чтения данных ОЗУ (mem_ctrl.vhd)
--//------------------------------------------------------
p_out_vbuf_rd <=i_rbuf_cfg.hw_mode and i_mem_din_rd and not p_in_rbuf_cfg.ram_wr_i.sel;

p_out_hdd_rxd_rd<=i_rbuf_cfg.sw_mode and i_mem_din_rd and not p_in_rbuf_cfg.ram_wr_i.sel;

--//to RAM
i_mem_din_rdy_1tmp<=p_in_hdd_rxbuf_empty when i_rbuf_cfg.sw_mode='1' else p_in_vbuf_empty;
i_mem_din_1tmp    <=p_in_hdd_rxd         when i_rbuf_cfg.sw_mode='1' else p_in_vbuf_dout;

i_mem_din_rdy_2tmp<= i_mem_din_rdy_1tmp when i_hwlog.log_on='0' else '0';
i_mem_din_2tmp    <= i_mem_din_1tmp     when i_hwlog.log_on='0' else i_hwlog_d(0);

i_mem_din_rdy<= i_mem_din_rdy_2tmp when p_in_rbuf_cfg.ram_wr_i.sel='0' else i_cr_txbuf_empty;
i_mem_din    <= i_mem_din_2tmp     when p_in_rbuf_cfg.ram_wr_i.sel='0' else i_cr_txbuf_dout;

--//from RAM
p_out_hdd_txd<=i_mem_dout;
p_out_hdd_txd_wr<=i_mem_dout_wr and not p_in_rbuf_cfg.ram_wr_i.sel;
i_mem_dout_wrdy <= p_in_hdd_txbuf_full when p_in_rbuf_cfg.ram_wr_i.sel='0' else i_cr_rxbuf_full;


i_mem_done<=i_mem_wrdone or i_mem_rddone;
i_mem_wrstart<=i_mem_start when i_mem_dir=C_MEMWR_WRITE else '0';
i_mem_rdstart<=i_mem_start when i_mem_dir=C_MEMWR_READ  else '0';

m_wr : mem_wr
generic map(
G_MEM_BANK_M_BIT => G_MEM_BANK_M_BIT,
G_MEM_BANK_L_BIT => G_MEM_BANK_L_BIT,
G_MEM_AWIDTH     => G_MEM_AWIDTH,
G_MEM_DWIDTH     => G_MEM_DWIDTH
)
port map(
-------------------------------
-- Конфигурирование
-------------------------------
p_in_cfg_mem_adr     => i_mem_adr,
p_in_cfg_mem_trn_len => i_mem_lentrn,
p_in_cfg_mem_dlen_rq => i_mem_lenreq,
p_in_cfg_mem_wr      => i_mem_dir,
p_in_cfg_mem_start   => i_mem_wrstart,
p_out_cfg_mem_done   => i_mem_wrdone,

-------------------------------
-- Связь с пользовательскими буферами
-------------------------------
p_in_usr_txbuf_dout  => i_mem_din,
p_out_usr_txbuf_rd   => i_mem_din_rd,
p_in_usr_txbuf_empty => i_mem_din_rdy,

p_out_usr_rxbuf_din  => open,
p_out_usr_rxbuf_wd   => open,
p_in_usr_rxbuf_full  => '0',

---------------------------------
-- Связь с mem_ctrl.vhd
---------------------------------
p_out_mem            => p_out_memwr,
p_in_mem             => p_in_memwr,

-------------------------------
--System
-------------------------------
p_in_tst             => (others=>'0'),
p_out_tst            => tst_vwr_out,

p_in_clk             => p_in_clk,
p_in_rst             => p_in_rst
);

m_rd : mem_wr
generic map(
G_MEM_BANK_M_BIT => G_MEM_BANK_M_BIT,
G_MEM_BANK_L_BIT => G_MEM_BANK_L_BIT,
G_MEM_AWIDTH     => G_MEM_AWIDTH,
G_MEM_DWIDTH     => G_MEM_DWIDTH
)
port map
(
-------------------------------
-- Конфигурирование
-------------------------------
p_in_cfg_mem_adr     => i_mem_adr,
p_in_cfg_mem_trn_len => i_mem_lentrn,
p_in_cfg_mem_dlen_rq => i_mem_lenreq,
p_in_cfg_mem_wr      => i_mem_dir,
p_in_cfg_mem_start   => i_mem_rdstart,
p_out_cfg_mem_done   => i_mem_rddone,

-------------------------------
-- Связь с пользовательскими буферами
-------------------------------
p_in_usr_txbuf_dout  => "00000000000000000000000000000000",
p_out_usr_txbuf_rd   => open,
p_in_usr_txbuf_empty => '0',

p_out_usr_rxbuf_din  => i_mem_dout,
p_out_usr_rxbuf_wd   => i_mem_dout_wr,
p_in_usr_rxbuf_full  => i_mem_dout_wrdy,

---------------------------------
-- Связь с mem_ctrl.vhd
---------------------------------
p_out_mem            => p_out_memrd,
p_in_mem             => p_in_memrd,

-------------------------------
--System
-------------------------------
p_in_tst             => (others=>'0'),
p_out_tst            => tst_vrd_out,

p_in_clk             => p_in_clk,
p_in_rst             => p_in_rst
);


--//--------------------------------------------------
--//Запись/чтение ОЗУ через модуль CFG
--//--------------------------------------------------
process(p_in_rst,p_in_clk)
begin
  if p_in_rst='1' then
    sr_cr_start<=(others=>'0');
    i_cr_start<='0';
  elsif p_in_clk'event and p_in_clk='1' then
    sr_cr_start<=p_in_rbuf_cfg.ram_wr_i.start & sr_cr_start(0 to 1);
    i_cr_start<=sr_cr_start(1) and not sr_cr_start(2);
  end if;
end process;

i_cr_txbuf_rd<=i_mem_din_rd and p_in_rbuf_cfg.ram_wr_i.sel;
i_cr_rxbuf_wr<=i_mem_dout_wr and p_in_rbuf_cfg.ram_wr_i.sel;

--//RAM<-CFG
m_cr_txbuf : hdd_ram_hfifo_tx
port map(
din         => p_in_rbuf_cfg.ram_wr_i.din,
wr_en       => p_in_rbuf_cfg.ram_wr_i.wr,
wr_clk      => p_in_rbuf_cfg.ram_wr_i.clk,

dout        => i_cr_txbuf_dout,
rd_en       => i_cr_txbuf_rd,
rd_clk      => p_in_clk,

full        => open,
almost_full => i_cr_txbuf_full,
empty       => i_cr_txbuf_empty,

--clk         => p_in_clk,
rst         => i_cr_buf_rst
);

--//RAM->CFG
m_cr_rxbuf : hdd_ram_hfifo_rx
port map(
din         => i_mem_dout,
wr_en       => i_cr_rxbuf_wr,
wr_clk      => p_in_clk,

dout        => p_out_rbuf_status.ram_wr_o.dout,
rd_en       => p_in_rbuf_cfg.ram_wr_i.rd,
rd_clk      => p_in_rbuf_cfg.ram_wr_i.clk,

full        => open,
almost_full => open,
prog_full   => i_cr_rxbuf_full,
empty       => i_cr_rxbuf_empty,

--clk         => p_in_clk,
rst         => i_cr_buf_rst
);


--//----------------------------------
--//DBG: ChipScoupe
--//----------------------------------
gen_dbgcs_off : if strcmp(G_DBGCS,"OFF") generate
p_out_dbgcs.clk<='0';
p_out_dbgcs.trig0<=(others=>'0');
p_out_dbgcs.data<=(others=>'0');
end generate gen_dbgcs_off;

gen_dbgcs_on : if strcmp(G_DBGCS,"ON") generate
--
--p_out_dbgcs.clk<=p_in_clk;
--
--p_out_dbgcs.trig0(4 downto  0)  <=tst_fsm_cs(4 downto 0);
--p_out_dbgcs.trig0(5)            <='0'; ------------------//зарезервировано для i_hdd_mem_ce;
--p_out_dbgcs.trig0(6)            <='0'; ------------------//зарезервировано для i_hdd_mem_cw;
--p_out_dbgcs.trig0(7)            <=i_err_det.rambuf_full or i_err_det.vinbuf_full;
--p_out_dbgcs.trig0(8)            <=i_err_det.rambuf_full;
--p_out_dbgcs.trig0(9)            <=i_err_det.vinbuf_full;
--p_out_dbgcs.trig0(10)           <=p_in_hdd_txbuf_full;
--p_out_dbgcs.trig0(11)           <=i_hdd_txbuf_pfull;--p_in_hdd_txbuf_pfull;
--p_out_dbgcs.trig0(12)           <=tst_hw_stop;
--p_out_dbgcs.trig0(13)           <=tst_rambuf_pfull;
--p_out_dbgcs.trig0(14)           <=i_mem_dir;
--p_out_dbgcs.trig0(15)           <=i_vbuf_wrcnt(0);
--p_out_dbgcs.trig0(16)           <=i_vbuf_wrcnt(1);
--p_out_dbgcs.trig0(17)           <=i_vbuf_wrcnt(2);
--p_out_dbgcs.trig0(18)           <=i_vbuf_wrcnt(3);
--p_out_dbgcs.trig0(19)           <=i_doble_act;
--p_out_dbgcs.trig0(20)           <=i_vbuf_pfull;
--p_out_dbgcs.trig0(29 downto 21)<=(others=>'0');------------------//зарезервировано
--p_out_dbgcs.trig0(30)           <=tst_timeout;
--p_out_dbgcs.trig0(31)           <='0';
--p_out_dbgcs.trig0(32)           <='0';
--p_out_dbgcs.trig0(33)           <='0';
--p_out_dbgcs.trig0(34)           <='0';
--p_out_dbgcs.trig0(35)           <=i_rbuf_cfg.clr_err;
--p_out_dbgcs.trig0(63 downto 36) <=(others=>'0');
--
--
--p_out_dbgcs.data(0)<='0'; ------------------//зарезервировано для i_hdd_mem_ce;
--p_out_dbgcs.data(1)<='0'; ------------------//зарезервировано для i_hdd_mem_cw;
--p_out_dbgcs.data(2)<='0'; ------------------//зарезервировано для i_mem_arb1_rd; ;
--p_out_dbgcs.data(3)<='0'; ------------------//зарезервировано для i_mem_arb1_wr; ;
--p_out_dbgcs.data(4)<='0'; ------------------//зарезервировано для i_mem_arb1_term;
--p_out_dbgcs.data(9 downto 5)     <=tst_fsm_cs(4 downto 0);
--p_out_dbgcs.data(10)             <=i_err_det.vinbuf_full;
--p_out_dbgcs.data(11)             <=i_err_det.rambuf_full;
--p_out_dbgcs.data(12)             <=tst_rambuf_empty;
--p_out_dbgcs.data(13)             <=p_in_vbuf_empty;
--p_out_dbgcs.data(14)             <=p_in_hdd_rxbuf_empty;
--p_out_dbgcs.data(15)             <=i_rbuf_cfg.atacmdw;
--p_out_dbgcs.data(16)             <=i_rbuf_cfg.hw_mode;
--p_out_dbgcs.data(17)             <=p_in_hdd_txbuf_full;
--p_out_dbgcs.data(18)             <=i_doble_act;
--p_out_dbgcs.data(19)             <='0';------------------//зарезервировано для tst_swt_hdd_vbuf_wr
--p_out_dbgcs.data(23 downto 20)   <=i_vbuf_wrcnt;
--p_out_dbgcs.data(24)             <=i_mem_din_rdy;
--p_out_dbgcs.data(25)             <=i_mem_start;
--p_out_dbgcs.data(29 downto 26)   <=tst_mem_ctrl_out(5 downto 2);--//mem_wr/fsm(0)
--p_out_dbgcs.data(30)             <=p_in_mem.buf_re;
--p_out_dbgcs.data(31)             <=p_in_mem.buf_wpf;
--p_out_dbgcs.data(63 downto 32)   <=i_rambuf_dcnt(31 downto 0);
--p_out_dbgcs.data(75 downto 64)   <=i_mem_lenreq(11 downto 0);
--p_out_dbgcs.data(87 downto 76)   <=i_mem_lentrn(11 downto 0);
----p_out_dbgcs.data(87 downto 84)   <=(others=>'0');
--p_out_dbgcs.data(88)             <='0';
--p_out_dbgcs.data(89)             <='0';
--p_out_dbgcs.data(99 downto 90)   <=(others=>'0');
--p_out_dbgcs.data(115 downto 100) <=tst_rambuf_dcnt_max(15 downto 0);
--p_out_dbgcs.data(119 downto 116) <=tst_vbuf_wrcnt_max;
--p_out_dbgcs.data(135 downto 120) <=(others=>'0');-------------------//зарезервировано
--p_out_dbgcs.data(151 downto 136) <=tst_mem_ctrl_out(31 downto 16);--//mem_wr/i_mem_trn_len
--p_out_dbgcs.data(154 downto 152) <=(others=>'0');------------------//зарезервировано
--p_out_dbgcs.data(166 downto 155) <=tst_rambuf_dcnt_max(27 downto 16);
--p_out_dbgcs.data(171)            <=i_hdd_txbuf_pfull;--p_in_hdd_txbuf_pfull;
--

--tst_fsm_cs<=CONV_STD_LOGIC_VECTOR(16#01#,tst_fsm_cs'length) when fsm_rambuf_cs=S_SW_WAIT            else
--            CONV_STD_LOGIC_VECTOR(16#02#,tst_fsm_cs'length) when fsm_rambuf_cs=S_SW_MEM_CHECK       else
--            CONV_STD_LOGIC_VECTOR(16#03#,tst_fsm_cs'length) when fsm_rambuf_cs=S_SW_MEM_START       else
--            CONV_STD_LOGIC_VECTOR(16#04#,tst_fsm_cs'length) when fsm_rambuf_cs=S_SW_MEM_WORK        else
--            CONV_STD_LOGIC_VECTOR(16#05#,tst_fsm_cs'length) when fsm_rambuf_cs=S_HW_MEMW_CHECK      else
--            CONV_STD_LOGIC_VECTOR(16#06#,tst_fsm_cs'length) when fsm_rambuf_cs=S_HW_MEMR_CHECK      else
--            CONV_STD_LOGIC_VECTOR(16#07#,tst_fsm_cs'length) when fsm_rambuf_cs=S_HW_MEMA_CHECK1     else
--            CONV_STD_LOGIC_VECTOR(16#08#,tst_fsm_cs'length) when fsm_rambuf_cs=S_HW_MEMA_CHECK2     else
--            CONV_STD_LOGIC_VECTOR(16#09#,tst_fsm_cs'length) when fsm_rambuf_cs=S_HW_MEMA_CHECK3     else
--            CONV_STD_LOGIC_VECTOR(16#0A#,tst_fsm_cs'length) when fsm_rambuf_cs=S_HW_MEM_START       else
--            CONV_STD_LOGIC_VECTOR(16#0B#,tst_fsm_cs'length) when fsm_rambuf_cs=S_HW_MEM_WORK        else
--            CONV_STD_LOGIC_VECTOR(16#0C#,tst_fsm_cs'length) when fsm_rambuf_cs=S_HW_FULL_CHECK      else
--            CONV_STD_LOGIC_VECTOR(16#0D#,tst_fsm_cs'length) when fsm_rambuf_cs=S_HWLOG_WAIT_TRNDONE else
--            CONV_STD_LOGIC_VECTOR(16#0E#,tst_fsm_cs'length) when fsm_rambuf_cs=S_HWLOG_MEM_START    else
--            CONV_STD_LOGIC_VECTOR(16#0F#,tst_fsm_cs'length) when fsm_rambuf_cs=S_HWLOG_MEM_WORK     else
--            CONV_STD_LOGIC_VECTOR(16#10#,tst_fsm_cs'length) when fsm_rambuf_cs=S_CR_MEM_START       else
--            CONV_STD_LOGIC_VECTOR(16#11#,tst_fsm_cs'length) when fsm_rambuf_cs=S_CR_MEM_WORK        else
--            CONV_STD_LOGIC_VECTOR(16#00#,tst_fsm_cs'length); --//when fsm_rambuf_cs=S_IDLE          else
--
--
--process(p_in_rst,p_in_clk)
--begin
--if p_in_rst='1' then
--  tst_timeout_cnt<=(others=>'0');
--  tst_timeout<='0';
--
--  sr_hw_work<=(others=>'0');
--  tst_hw_stop<='0';
--  tst_rambuf_dcnt_max<=(others=>'0');
--  tst_vbuf_wrcnt_max<=(others=>'0');
----  tst_rambuf_pfull<='0';
--  tst_rambuf_empty<='1';
--
--elsif p_in_clk'event and p_in_clk='1' then
--
--
----  if tst_mem_ctrl_out(5 downto 2)=CONV_STD_LOGIC_VECTOR(6, 4) then  --//mem_wr/fsm=S_MEM_TRN
--  if fsm_rambuf_cs=S_HW_MEM_WORK and i_mem_dir=C_MEMWR_READ then
--    if tst_timeout_cnt>CONV_STD_LOGIC_VECTOR(650, tst_timeout_cnt'length) then
--      tst_timeout<='1';
--    else
--      tst_timeout_cnt<=tst_timeout_cnt + 1;
--      tst_timeout<='0';
--    end if;
--  else
--    tst_timeout_cnt<=(others=>'0');
--    tst_timeout<='0';
--  end if;
--
--  sr_hw_work<=i_rbuf_cfg.hw_mode & sr_hw_work(0 to 0);
--  tst_hw_stop<=not sr_hw_work(0) and sr_hw_work(1);
--
--  if i_rambuf_dcnt=(i_rambuf_dcnt'range =>'0') then
--    tst_rambuf_empty<='1';
--  else
--    tst_rambuf_empty<='0';
--  end if;
--
--  if tst_rambuf_dcnt_max_clr='1' then
--    tst_rambuf_dcnt_max<=(others=>'0');
--    tst_vbuf_wrcnt_max<=(others=>'0');
--  else
--    if i_rambuf_dcnt>tst_rambuf_dcnt_max then
--      tst_rambuf_dcnt_max<=i_rambuf_dcnt;
--    end if;
--    if i_vbuf_wrcnt>tst_vbuf_wrcnt_max then
--      tst_vbuf_wrcnt_max<=i_vbuf_wrcnt;
--    end if;
--  end if;
--
--end if;
--end process;


end generate gen_dbgcs_on;

end generate gen_use_on;


gen_use_off : if strcmp(G_MODULE_USE,"OFF") generate

p_out_dbgcs.clk<='0';
p_out_dbgcs.trig0<=(others=>'0');
p_out_dbgcs.data<=(others=>'0');

p_out_rbuf_status.err<='0';
p_out_rbuf_status.err_type.vinbuf_full<='0';
p_out_rbuf_status.err_type.rambuf_full<='0';
p_out_rbuf_status.done<='0';
p_out_rbuf_status.hwlog_size<=(others=>'0');

p_out_vbuf_rd <= not p_in_vbuf_empty;

p_out_hdd_txd <= p_in_vbuf_dout;
p_out_hdd_txd_wr <= not p_in_vbuf_empty;


p_out_hdd_rxd_rd<='0';

p_out_tst(0)<=OR_reduce(p_in_vbuf_dout) or p_in_vbuf_empty or OR_reduce(p_in_vbuf_wrcnt) or
              OR_reduce(p_in_hdd_rxd) or p_in_hdd_rxbuf_empty or p_in_hdd_txbuf_full;
p_out_tst(31 downto 1) <= (others=>'0');

end generate gen_use_off;


--END MAIN
end behavioral;

