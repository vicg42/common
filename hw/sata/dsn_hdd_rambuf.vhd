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
-- Revision 0.02 - Добавлена обработка ситуации когда уровень данных в RAMBUF >= порогу C_HDD_RAMBUF_PFULL, а
--                 указатель чтения rd_prt находится почти в конце RAMBUF. В этом случае произвадим чтение данных
--                 из RAMBUF в 2-а этапа:
--                 1. Сначала вычитываем i_rd_lentrn_dbl данных
--                 2. Потом вычитываем i_rd_lentrn_dbl_remain данных
--                 (подробности см. ниже .Логика управления автоматом записи/чтения ОЗУ)
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
use work.prj_def.all;
use work.memory_ctrl_pkg.all;
use work.sata_glob_pkg.all;
use work.sata_pkg.all;
use work.sata_sim_lite_pkg.all;
use work.dsn_hdd_pkg.all;

entity dsn_hdd_rambuf is
generic
(
G_MODULE_USE      : string:="ON";
G_HDD_RAMBUF_SIZE : integer:=23; --//(в BYTE). Определяется как 2 в степени G_HDD_RAMBUF_SIZE
G_DBGCS           : string:="OFF";
G_SIM             : string:="OFF"
);
port
(
-------------------------------
-- Конфигурирование
-------------------------------
p_in_rbuf_cfg         : in    THDDRBufCfg;   --//Конфигурирование RAMBUF
p_out_rbuf_status     : out   THDDRBufStatus;--//Статусы RAMBUF

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
p_in_hdd_txbuf_pfull  : in    std_logic;
p_in_hdd_txbuf_full   : in    std_logic;
p_in_hdd_txbuf_empty  : in    std_logic;

p_in_hdd_rxd          : in    std_logic_vector(31 downto 0);
p_out_hdd_rxd_rd      : out   std_logic;
p_in_hdd_rxbuf_empty  : in    std_logic;
p_in_hdd_rxbuf_pempty : in    std_logic;

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
p_out_dbgcs           : out   TSH_ila;

-------------------------------
--System
-------------------------------
p_in_clk              : in    std_logic;
p_in_rst              : in    std_logic
);
end dsn_hdd_rambuf;

architecture behavioral of dsn_hdd_rambuf is

constant CI_SECTOR_SIZE_BYTE : integer:=selval(C_SECTOR_SIZE_BYTE, C_SIM_SECTOR_SIZE_DWORD*4, strcmp(G_SIM, "OFF"));

constant C_HDD_TXSTREAM_FIFO_DEPTH : integer:=16#1000#;--//DWORD
constant C_HDD_RAMBUF_PFULL        : integer:=10;--//Program FULL level - 2**10 = 1024(0x400) - (в DWORD)
                                                 --//Если данных в RAMBUF накопилось >= значению порога, то
                                                 --//размер одиночной транзакции чтения ОЗУ увеличиваем до размера порога,
                                                 --//иначе чтение ведем размером транзакции по умолчанию

-- Small delay for simulation purposes.
constant dly : time := 1 ps;

type fsm_state is
(
S_IDLE,

S_SW_WAIT,
S_SW_MEM_CHECK,
S_SW_MEM_START,
S_SW_MEM_WORK,

S_HW_MEMW_CHECK,
S_HW_MEMW_START,
S_HW_MEMW_WORK,
S_HW_MEMR_CHECK,
S_HW_MEMR_CHECK2,
S_HW_MEMR_CHECK3,
S_HW_MEMR_START,
S_HW_MEMR_WORK,
S_HW_MEMR_START2,

S_HWLOG_WAIT_TRNDONE,
S_HWLOG_MEM_START,
S_HWLOG_MEM_WORK
);
signal fsm_rambuf_cs                   : fsm_state;

signal i_hddcnt                        : std_logic_vector(2 downto 0);

signal i_rd_lentrn_dbl                 : std_logic_vector(15 downto 0);--//(в DWORD)
signal i_rd_lentrn_dbl_remain          : std_logic_vector(15 downto 0);--//(в DWORD)

signal i_dwnport_remain                : std_logic_vector(15 downto 0);--//(в DWORD)
signal i_dnwport_dcnt                  : std_logic_vector(15 downto 0);--//(в DWORD)

signal i_wr_lentrn                     : std_logic_vector(15 downto 0);--//(в DWORD)
signal i_rd_lentrn                     : std_logic_vector(15 downto 0);--//(в DWORD)
signal i_wr_ptr                        : std_logic_vector(31 downto 0);--//Адрес в BYTE
signal i_rd_ptr                        : std_logic_vector(31 downto 0);--//Адрес в BYTE

signal i_rambuf_dcnt                   : std_logic_vector(31 downto 0);--//(в DWORD): std_logic_vector(G_HDD_RAMBUF_SIZE-2 downto 0);--//(в DWORD)
signal i_rambuf_done                   : std_logic;
signal i_rambuf_full                   : std_logic;
signal i_rambuf_full_err               : std_logic;

signal i_hdd_txbuf_wr_en               : std_logic;
signal i_hdd_txbuf_empty               : std_logic;

signal i_vbuf_pfull                      : std_logic;

signal i_mem_adr                       : std_logic_vector(31 downto 0);--//Адрес в BYTE
signal i_mem_lenreq                    : std_logic_vector(15 downto 0);--//Размер запрашиваемых данных (в DWORD)
signal i_mem_lentrn                    : std_logic_vector(15 downto 0);--//Размер одиночной транзакции
signal i_mem_dir                       : std_logic;
signal i_mem_start                     : std_logic;
signal i_mem_done                      : std_logic;
signal i_mem_rd_dbl                    : std_logic;

signal i_atacmd_scount                 : std_logic_vector(15 downto 0);
signal i_atacmd_dcount_byte            : std_logic_vector(i_atacmd_scount'length + log2(CI_SECTOR_SIZE_BYTE)-1 downto 0);
signal i_atacmd_dcount_dw              : std_logic_vector(i_atacmd_dcount_byte'range);
signal i_atadone                       : std_logic;

signal i_usr_rxbuf_dout                : std_logic_vector(31 downto 0);
signal i_usr_rxbuf_rd                  : std_logic;
signal i_usr_rxbuf_empty               : std_logic;
signal i_usr_rxbuf_1dout               : std_logic_vector(31 downto 0);
signal i_usr_rxbuf_1empty              : std_logic;


signal i_hw_measure                    : std_logic;
signal sr_hw_trn_done                  : std_logic_vector(0 to 1);
signal i_hw_trn_done                   : std_logic;
type THWlogData is array (0 to 0) of std_logic_vector(31 downto 0);
signal i_hw_log_d                      : THWlogData;

signal tst_rambuf_empty                : std_logic;
signal tst_fast_ramrd                  : std_logic;
signal tst_fsm_cs                      : std_logic_vector(3 downto 0);
--signal tst_fsm_cs_dly                  : std_logic_vector(tst_fsm_cs'range);


--MAIN
begin



gen_use_on : if strcmp(G_MODULE_USE,"ON") generate

--//----------------------------------
--//Технологические сигналы
--//----------------------------------
p_out_tst<=(others=>'0');

--//----------------------------------
--//DBG: ChipScoupe
--//----------------------------------
gen_dbgcs_off : if strcmp(G_DBGCS,"OFF") generate
p_out_dbgcs.clk<='0';
p_out_dbgcs.trig0<=(others=>'0');
p_out_dbgcs.data<=(others=>'0');
end generate gen_dbgcs_off;

gen_dbgcs_on : if strcmp(G_DBGCS,"ON") generate

p_out_dbgcs.clk<=p_in_clk;

p_out_dbgcs.trig0(0)            <=p_in_rbuf_cfg.dmacfg.armed;    --tst_dma_start;
p_out_dbgcs.trig0(1)            <=p_in_rbuf_cfg.dmacfg.atacmdw; --tst_dmasw_start_wr;
p_out_dbgcs.trig0(2)            <=p_in_hdd_rxbuf_empty;          --tst_dmasw_start_rd;
p_out_dbgcs.trig0(3)            <='0'; --//зарезервированио для i_hdd_mem_ce;
p_out_dbgcs.trig0(4)            <='0'; --//зарезервированио для i_hdd_mem_cw;
p_out_dbgcs.trig0(5)            <=i_rambuf_full;
p_out_dbgcs.trig0(6)            <=i_vbuf_pfull;
p_out_dbgcs.trig0(7)            <=tst_fast_ramrd;
p_out_dbgcs.trig0(11 downto  8) <=tst_fsm_cs(3 downto 0);
p_out_dbgcs.trig0(63 downto 12) <=(others=>'0');

p_out_dbgcs.data(0)             <=p_in_rbuf_cfg.dmacfg.armed;    --tst_dma_start;
p_out_dbgcs.data(1)             <=p_in_rbuf_cfg.dmacfg.atacmdw; --tst_dmasw_start_wr;
p_out_dbgcs.data(2)             <=p_in_hdd_rxbuf_empty;          --tst_dmasw_start_rd;
p_out_dbgcs.data(3)             <=i_atadone;
p_out_dbgcs.data(4)             <=tst_rambuf_empty;
p_out_dbgcs.data(5)             <=i_rambuf_full;
p_out_dbgcs.data(6)             <=i_vbuf_pfull;
p_out_dbgcs.data(7)             <=tst_fast_ramrd;
p_out_dbgcs.data(11  downto  8) <=tst_fsm_cs(3 downto 0);
--p_out_dbgcs.data(80  downto  12)<=tst_fsm_cs_dly(3 downto 0);--//зарезервировано для сигналов mem_ctrl
p_out_dbgcs.data(112 downto 81) <=i_rambuf_dcnt(31 downto 0);
p_out_dbgcs.data(128 downto 113)<=i_mem_lenreq(15 downto 0);
p_out_dbgcs.data(136 downto 129)<=i_mem_lentrn(7 downto 0);
--p_out_dbgcs.data(122 downto 105)<=(others=>'0');


tst_fsm_cs<=CONV_STD_LOGIC_VECTOR(16#01#,tst_fsm_cs'length) when fsm_rambuf_cs=S_SW_WAIT           else
            CONV_STD_LOGIC_VECTOR(16#02#,tst_fsm_cs'length) when fsm_rambuf_cs=S_SW_MEM_CHECK      else
            CONV_STD_LOGIC_VECTOR(16#03#,tst_fsm_cs'length) when fsm_rambuf_cs=S_SW_MEM_START      else
            CONV_STD_LOGIC_VECTOR(16#04#,tst_fsm_cs'length) when fsm_rambuf_cs=S_SW_MEM_WORK       else
            CONV_STD_LOGIC_VECTOR(16#05#,tst_fsm_cs'length) when fsm_rambuf_cs=S_HW_MEMW_CHECK     else
            CONV_STD_LOGIC_VECTOR(16#06#,tst_fsm_cs'length) when fsm_rambuf_cs=S_HW_MEMW_START     else
            CONV_STD_LOGIC_VECTOR(16#07#,tst_fsm_cs'length) when fsm_rambuf_cs=S_HW_MEMW_WORK      else
            CONV_STD_LOGIC_VECTOR(16#08#,tst_fsm_cs'length) when fsm_rambuf_cs=S_HW_MEMR_CHECK     else
            CONV_STD_LOGIC_VECTOR(16#09#,tst_fsm_cs'length) when fsm_rambuf_cs=S_HW_MEMR_CHECK2    else
            CONV_STD_LOGIC_VECTOR(16#0A#,tst_fsm_cs'length) when fsm_rambuf_cs=S_HW_MEMR_CHECK3    else
            CONV_STD_LOGIC_VECTOR(16#0B#,tst_fsm_cs'length) when fsm_rambuf_cs=S_HW_MEMR_START     else
            CONV_STD_LOGIC_VECTOR(16#0C#,tst_fsm_cs'length) when fsm_rambuf_cs=S_HW_MEMR_WORK      else
            CONV_STD_LOGIC_VECTOR(16#0D#,tst_fsm_cs'length) when fsm_rambuf_cs=S_HW_MEMR_START2    else
            CONV_STD_LOGIC_VECTOR(16#00#,tst_fsm_cs'length); --//when fsm_rambuf_cs=S_IDLE          else

end generate gen_dbgcs_on;


--//----------------------------------------------
--//Статусы
--//----------------------------------------------
p_out_rbuf_status.err<=i_rambuf_full_err;
p_out_rbuf_status.done<=i_rambuf_done;
p_out_rbuf_status.hwlog_size<=i_wr_ptr;
--p_out_rbuf_status.rdy<='0';

--//Сброс/детектирование переполнения потокового буфера
process(p_in_rst,p_in_clk)
begin
  if p_in_rst='1' then
    i_rambuf_full_err<='0';
  elsif p_in_clk'event and p_in_clk='1' then
    if p_in_rbuf_cfg.dmacfg.clr_err='1' then
      i_rambuf_full_err<='0';
    elsif i_rambuf_full='1' and
          (p_in_rbuf_cfg.dmacfg.sw_mode='1' or p_in_rbuf_cfg.dmacfg.hw_mode='1') then
      i_rambuf_full_err<='1';
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
    elsif p_in_rbuf_cfg.dmacfg.atadone='1' then
      i_atadone<='1';
    end if;
  end if;
end process;

--//----------------------------------------------
--//Автомат управления записю/чтение данных ОЗУ
--//----------------------------------------------
i_atacmd_dcount_byte<=i_atacmd_scount&CONV_STD_LOGIC_VECTOR(0, log2(CI_SECTOR_SIZE_BYTE));
i_atacmd_dcount_dw<=("00"&i_atacmd_dcount_byte(i_atacmd_dcount_byte'high downto 2));

--//Логика работы автомата
process(p_in_rst,p_in_clk)
  variable update_addr: std_logic_vector(i_mem_lenreq'length+1 downto 0);
  variable width32b   : std_logic_vector(31 downto 0);
begin
  if p_in_rst='1' then
      update_addr:=(others=>'0');
      width32b:=(others=>'0');

    fsm_rambuf_cs <= S_IDLE;
    i_hddcnt<=(others=>'0');

    i_rambuf_dcnt<=(others=>'0');
    i_rambuf_done<='0';
    i_rambuf_full<='0';

    i_wr_lentrn<=(others=>'0');
    i_rd_lentrn<=(others=>'0');
    i_rd_lentrn_dbl<=(others=>'0');
    i_rd_lentrn_dbl_remain<=(others=>'0');

    i_wr_ptr<=(others=>'0');
    i_rd_ptr<=(others=>'0');

    i_dnwport_dcnt<=(others=>'0');
    i_dwnport_remain<=(others=>'0');
    i_hdd_txbuf_wr_en<='0';
    i_hdd_txbuf_empty<='1';

    i_mem_adr<=(others=>'0');
    i_mem_lentrn<=(others=>'0');
    i_mem_lenreq<=(others=>'0');
    i_mem_dir<='0';
    i_mem_start<='0';
    i_mem_rd_dbl<='0';

    i_atacmd_scount<=(others=>'0');

    i_vbuf_pfull<='0';

    i_hw_measure<='0';
    sr_hw_trn_done<=(others=>'0');
    i_hw_trn_done<='0';
    for i in 0 to i_hw_log_d'length-1 loop
    i_hw_log_d(i)<=(others=>'0');
    end loop;

    tst_rambuf_empty<='1';
    tst_fast_ramrd<='0';

  elsif p_in_clk'event and p_in_clk='1' then

    i_vbuf_pfull<=p_in_vbuf_pfull;
    i_hdd_txbuf_empty<=p_in_hdd_txbuf_empty;

    i_hw_measure<=p_in_rbuf_cfg.hwlog.measure;
    sr_hw_trn_done<=i_hw_measure & sr_hw_trn_done(0 to 0);
    i_hw_trn_done<=not sr_hw_trn_done(0) and sr_hw_trn_done(1);

    i_hw_log_d(0)<=p_in_rbuf_cfg.hwlog.tdly;
--    i_hw_log_d(0)<=p_in_rbuf_cfg.hwlog.twork;

    case fsm_rambuf_cs is

      --//####################################
      --//Исходное состояние
      --//####################################
      when S_IDLE =>

        i_rambuf_done<='0';
        i_rambuf_full<='0';

        if p_in_rbuf_cfg.tstgen.tesing_on='1' then --and p_in_rbuf_cfg.tstgen.con2rambuf='0' then

            if p_in_rbuf_cfg.dmacfg.hw_mode='1' and p_in_rbuf_cfg.hwlog.log_on='1' then
            --//Начало работы режима HW + HWLOG=ON
              i_wr_ptr<=(others=>'0');
              fsm_rambuf_cs <= S_HWLOG_WAIT_TRNDONE;
            else
              fsm_rambuf_cs <= S_IDLE;
            end if;

        else
            if p_in_rbuf_cfg.dmacfg.armed='1' then
                --//Готовим контроллер ОЗУ:
                --//Указатель записи/чтения
                i_wr_ptr<=(others=>'0');
                i_rd_ptr<=(others=>'0');

                --//Размер одиночной транзакций записи/чтения ОЗУ (DWORD)
                i_wr_lentrn<="00000000"&p_in_rbuf_cfg.mem_trn(7 downto 0);
                i_rd_lentrn<="00000000"&p_in_rbuf_cfg.mem_trn(15 downto 8);

                i_hddcnt<=(others=>'0');
                i_rambuf_dcnt<=(others=>'0');

                i_atacmd_scount<=p_in_rbuf_cfg.dmacfg.scount;

                if p_in_rbuf_cfg.dmacfg.sw_mode='1' and
                   p_in_rbuf_cfg.dmacfg.scount/=(p_in_rbuf_cfg.dmacfg.scount'range =>'0') then

                    fsm_rambuf_cs <= S_SW_WAIT;

                elsif p_in_rbuf_cfg.dmacfg.hw_mode='1' then

                  fsm_rambuf_cs <= S_HW_MEMW_CHECK;

                else
                  fsm_rambuf_cs <= S_IDLE;
                end if;

            else
              fsm_rambuf_cs <= S_IDLE;
            end if;
        end if;

      --//####################################
      --//Режим работы SW
      --//####################################
      --//Ждем сигнала запуска
      when S_SW_WAIT =>

--        i_mem_lenreq<=i_atacmd_dcount_dw(i_mem_lenreq'range);--//размер данных запошеных пользователем
        i_rambuf_dcnt(15 downto 0)<=i_atacmd_dcount_dw(15 downto 0);

        if p_in_rbuf_cfg.dmacfg.atacmdw='1' then
        --//Отрабатываем направление RAM->HDD
          i_mem_lenreq<=i_rd_lentrn;
          i_mem_lentrn<=i_rd_lentrn;    --//размер одиночной транзакции.(Устанавливается программно)
          i_mem_dir<=C_MEMCTRLCHWR_READ;
          fsm_rambuf_cs <= S_SW_MEM_CHECK;

        elsif p_in_hdd_rxbuf_pempty='0' or i_atadone='1' then
        --//Отрабатываем направление RAM<-HDD
          i_mem_lenreq<=i_wr_lentrn;
          i_mem_lentrn<=i_wr_lentrn;    --//размер одиночной транзакции.(Устанавливается программно)
          i_mem_dir<=C_MEMCTRLCHWR_WRITE;
          fsm_rambuf_cs <= S_SW_MEM_CHECK;
        end if;

      --//Проверка окончания записи/чтения
      when S_SW_MEM_CHECK =>

        if i_rambuf_dcnt(15 downto 0)=(i_rambuf_dcnt'range =>'0') then
          if p_in_rbuf_cfg.dmacfg.raid.used='0' then
          --//Работа с одним HDD
            i_rambuf_done<='1';
            fsm_rambuf_cs <= S_IDLE;
          else
          --//Работа с RAID
            if i_hddcnt=p_in_rbuf_cfg.dmacfg.raid.hddcount then
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
        if i_mem_dir=C_MEMCTRLCHWR_WRITE then
        --//RAM<-HDD
        --//Ждем когда в hdd_rxbuf накопится данные
          if p_in_hdd_rxbuf_pempty='0' or i_atadone='1' then
            i_mem_adr<=i_wr_ptr + p_in_rbuf_cfg.mem_adr;--//Update адреса RAMBUF
            i_mem_start<='1';

            fsm_rambuf_cs <= S_SW_MEM_WORK;
          end if;

        else
        --//RAM->HDD
        --//Ждем когда в hdd_txbuf можно будет передовать данные
          if p_in_hdd_txbuf_pfull='0' then
            i_mem_adr<=i_wr_ptr + p_in_rbuf_cfg.mem_adr;--//Update адреса RAMBUF
            i_mem_start<='1';

            fsm_rambuf_cs <= S_SW_MEM_WORK;
          end if;

        end if;

      --//Отработка mem транзакции
      when S_SW_MEM_WORK =>

        i_mem_start<='0';

        update_addr(1 downto 0) :=(others=>'0');
        update_addr(i_mem_lenreq'length+1 downto 2):=i_mem_lenreq;

        if i_mem_done='1' then
          --//Операция выполнена:
          --//Обновляем указатель записи + уровень данных в буфере
          i_wr_ptr<=i_wr_ptr + EXT(update_addr, i_wr_ptr'length);
          i_rambuf_dcnt<=i_rambuf_dcnt - EXT(i_mem_lenreq, i_rambuf_dcnt'length);

          fsm_rambuf_cs <= S_SW_MEM_CHECK;
        end if;


      --//####################################
      --//Режим работы HW
      --//####################################
      --//----------------------------------------------
      --//Анализ и выбор операции
      --//----------------------------------------------
      --//WRITE
      when S_HW_MEMW_CHECK =>

        if i_dnwport_dcnt>=CONV_STD_LOGIC_VECTOR(C_HDD_TXSTREAM_FIFO_DEPTH, i_dnwport_dcnt'length) then
          --//В HDD_TxBUF записано требуемый размер данных
          i_dnwport_dcnt<=(others=>'0');
          i_hdd_txbuf_wr_en<='0';--//Сброс флага разрешение заполнения буфера приемника
        end if;

        if p_in_rbuf_cfg.dmacfg.hw_mode='0' then
        --//Отрабатываю запрос ОСТАНОВКИ
          fsm_rambuf_cs <= S_IDLE;

        else
          if i_vbuf_pfull='0' then
              --//Еще не накопилось нужное кол-во данных!!!
              fsm_rambuf_cs <= S_HW_MEMR_CHECK;--//Переход к ЧТЕНИЮ
          else
              if i_rambuf_dcnt(G_HDD_RAMBUF_SIZE-2)='1' then --//(-2 т.к. значения i_rambuf_dcnt в DWPRD)
                --//RamBuffer/Full - в буфере нет свободного места.
                i_rambuf_full<='1';

                fsm_rambuf_cs <= S_HW_MEMR_CHECK;--//Переход к ЧТЕНИЮ
              else
                fsm_rambuf_cs <= S_HW_MEMW_START;--//Переход к ЗАПИСИ
              end if;
          end if;
        end if;

      --//------------------------------------
      --//Запись данных
      --//------------------------------------
      when S_HW_MEMW_START =>

        if i_wr_ptr(G_HDD_RAMBUF_SIZE)='1' then
          --//Закольцовываю указатель записи RAMBUF
          i_wr_ptr<=(others=>'0');
          i_mem_adr<=p_in_rbuf_cfg.mem_adr;
        else
          --//Update адреса RAMBUF
          i_mem_adr<=i_wr_ptr + p_in_rbuf_cfg.mem_adr;
        end if;

        i_mem_lenreq<=EXT(i_wr_lentrn, i_mem_lenreq'length);
        i_mem_lentrn<=i_wr_lentrn;    --//размер одиночной транзакции
        i_mem_dir<=C_MEMCTRLCHWR_WRITE;
        i_mem_start<='1';
        fsm_rambuf_cs <= S_HW_MEMW_WORK;

      when S_HW_MEMW_WORK =>

        i_mem_start<='0';

        --//Формируем значение для обнавления адреса ОЗУ.
        --//это действие необходимо т.к. значение i_mem_lenreq в DWORD, а
        --//значение i_wr_ptr должно быть в BYTE
        update_addr(1 downto 0) :=(others=>'0');
        update_addr(i_mem_lenreq'length+1 downto 2):=i_mem_lenreq;

        --//Операция выполнена
        if i_mem_done='1' then
          --//Обновляем указатель записи + уровень данных в буфере
          i_wr_ptr<=i_wr_ptr + EXT(update_addr, i_wr_ptr'length);
          i_rambuf_dcnt<=i_rambuf_dcnt + EXT(i_mem_lenreq, i_rambuf_dcnt'length);

          tst_rambuf_empty<='0';
          fsm_rambuf_cs <= S_HW_MEMR_CHECK;--//Переход к ЧТЕНИЮ
        end if;



      --//----------------------------------------------
      --//Анализ и выбор операции
      --//----------------------------------------------
      --//READ
      when S_HW_MEMR_CHECK =>
        --//Вычисляем сколько данных осталось закачать в HDD_TxBUF
        i_dwnport_remain<=CONV_STD_LOGIC_VECTOR(C_HDD_TXSTREAM_FIFO_DEPTH, i_dwnport_remain'length)-i_dnwport_dcnt;

        if i_hdd_txbuf_wr_en='0' then
            if i_hdd_txbuf_empty='1' then
            --//HDD_TxBUF пуст. => прерхожу к его заполнению
              fsm_rambuf_cs <= S_HW_MEMR_CHECK2;
            else
            --//Ждем когда опустошится HDD_TxBUF
              fsm_rambuf_cs <= S_HW_MEMW_CHECK;--//Переход к ЗАПИСИ
            end if;
        else
        --//Есть разрешение на заполнение в HDD_TxBUF
        --//Переходим к его заполнению
          fsm_rambuf_cs <= S_HW_MEMR_CHECK2;
        end if;

      when S_HW_MEMR_CHECK2 =>

        i_hdd_txbuf_wr_en<='1';--//Разрешаем заполнение в HDD_TxBUF

        if i_rambuf_dcnt=(i_rambuf_dcnt'range =>'0') then
        --//RamBuffer/Empty - Нет данных для чтения
          tst_rambuf_empty<='1';
          fsm_rambuf_cs <= S_HW_MEMW_CHECK;--//Переход к ЗАПИСИ
        else
        --//Вычисляем размер данных которые будем вычитывать из RAMBUF

            if i_dwnport_remain>=CONV_STD_LOGIC_VECTOR(pwr(2,C_HDD_RAMBUF_PFULL), i_dwnport_remain'length) then
            --//Если в HDD_TxBUF осталось закачать данных > или = порогу C_HDD_RAMBUF_PFULL. Тогда ...

                if i_rambuf_dcnt>=CONV_STD_LOGIC_VECTOR(pwr(2,C_HDD_RAMBUF_PFULL), i_rambuf_dcnt'length) then
                --//Если уровень данных в RAMBUF > или = порогу C_HDD_RAMBUF_PFULL, то ускоряем процесс вычитки
                --//данных из RAMBUF путем увеличения размера запрашиваемых данных
                  i_rd_lentrn<=CONV_STD_LOGIC_VECTOR(pwr(2,C_HDD_RAMBUF_PFULL), i_rd_lentrn'length);
                  tst_fast_ramrd<='1';
                else
                --//Иначе запашиваем из RAMBUF столько данных сколько есть
                  i_rd_lentrn<=i_rambuf_dcnt(15 downto 0);
                end if;
            else
            --//Если в HDD_TxBUF осталось закачать данных < порога C_HDD_RAMBUF_PFULL. Тогда ...

                if i_rambuf_dcnt>=EXT(i_dwnport_remain, i_rambuf_dcnt'length) then
                --//Если уровень данных в RAMBUF > или = порогу i_dwnport_remain, то ускоряем процесс вычитки
                --//данных из RAMBUF путем увеличения размера запрашиваемых данных
                  i_rd_lentrn<=i_dwnport_remain;
                else
                --//Иначе запашиваем из ОЗУ столько данных сколько есть
                  i_rd_lentrn<=i_rambuf_dcnt(15 downto 0);
                end if;
            end if;

            fsm_rambuf_cs <= S_HW_MEMR_CHECK3;--S_HW_MEMR_START;--//Переход к ЧТЕНИЮ

        end if;

      when S_HW_MEMR_CHECK3 =>
        --//Перевод значения i_rd_lentrn в байты
        update_addr(1 downto 0) :=(others=>'0');
        update_addr(i_mem_lenreq'length+1 downto 2):=i_rd_lentrn;

        --//Анализ выхода за границы RAMBUF при текущем размере i_rd_lentrn
        if i_rd_ptr(G_HDD_RAMBUF_SIZE)='0' then
          if (i_rd_ptr + EXT(update_addr, i_rd_ptr'length))>CONV_STD_LOGIC_VECTOR(pwr(2,G_HDD_RAMBUF_SIZE), i_rd_ptr'length) then
            --//Будет выход за границы буфера.

            i_mem_rd_dbl<='1';--//Делаем двойную вычитку данных

            --//Вычисляем какое кол-во данных нужно чтобы достигнлуть мах границы RAMBUF.
            width32b:=CONV_STD_LOGIC_VECTOR(pwr(2,G_HDD_RAMBUF_SIZE), width32b'length)-i_rd_ptr;
            i_rd_lentrn_dbl<=width32b(17 downto 2);--//т.к. i_rd_lentrn_dbl должно быть представлено в DWORD
          end if;
        end if;

        fsm_rambuf_cs <= S_HW_MEMR_START;--//Переход к ЧТЕНИЮ

      --//----------------------------------------------
      --//Чтение данных
      --//----------------------------------------------
      when S_HW_MEMR_START =>

        tst_fast_ramrd<='0';

        if i_rd_ptr(G_HDD_RAMBUF_SIZE)='1' then
        --//Закольцовываю указатель чтения RAMBUF
          i_rd_ptr<=(others=>'0');
          i_mem_adr<=p_in_rbuf_cfg.mem_adr;
        else
          --//Update адреса RAMBUF
          i_mem_adr<=i_rd_ptr + p_in_rbuf_cfg.mem_adr;
        end if;

        if i_mem_rd_dbl='1' then
          --//Двойное чтение:
          --//Назначаем размер данных чтения RAMBUF чтобы достигнлуть мах границы
          i_mem_lenreq<=i_rd_lentrn_dbl;
          --//Расчет сколько данных осталось
          i_rd_lentrn_dbl_remain<=i_rd_lentrn - i_rd_lentrn_dbl;
        else
          i_mem_lenreq<=i_rd_lentrn;
        end if;
        i_mem_dir<=C_MEMCTRLCHWR_READ;
        i_mem_start<='1';
        fsm_rambuf_cs <= S_HW_MEMR_WORK;

      when S_HW_MEMR_WORK =>

        i_mem_start<='0';

        --//Формируем значение для обнавления адреса ОЗУ.
        --//это действие необходимо т.к. значение i_mem_lenreq в DWORD, а
        --//значение i_wr_ptr должно быть в BYTE
        update_addr(1 downto 0) :=(others=>'0');
        update_addr(i_mem_lenreq'length+1 downto 2):=i_mem_lenreq;

        --//Операция выполнена
        if i_mem_done='1' then
          i_rambuf_full<='0';--//Сброс флага БУФЕР ОЗУ FULL

          --//Обновляем указатель чтения + уровень данных в буфере
          i_rd_ptr<=i_rd_ptr + EXT(update_addr, i_rd_ptr'length);
          i_rambuf_dcnt<=i_rambuf_dcnt - EXT(i_mem_lenreq, i_rambuf_dcnt'length);

          --//Подсчет данных записаных в HDD_TxBUF
          i_dnwport_dcnt<=i_dnwport_dcnt + EXT(i_mem_lenreq, i_dnwport_dcnt'length);

          if i_mem_rd_dbl='1' then
            fsm_rambuf_cs <= S_HW_MEMR_START2;--//Переход к вычитке в 2-а этапа
          else
            fsm_rambuf_cs <= S_HW_MEMW_CHECK;--//Переход к ЗАПИСИ
          end if;

        end if;

      when S_HW_MEMR_START2 =>

        --//Update адреса RAMBUF + указателя чтения
        i_rd_ptr<=(others=>'0');
        i_mem_rd_dbl<='0';--//Сброс флага двойной вычетки

        i_mem_adr<=p_in_rbuf_cfg.mem_adr;
        i_mem_lenreq<=i_rd_lentrn_dbl_remain;
        i_mem_dir<=C_MEMCTRLCHWR_READ;
        i_mem_start<='1';
        fsm_rambuf_cs <= S_HW_MEMR_WORK;



      --//####################################
      --//HWLOG
      --//####################################
      --//Ждем завершение текущей транзакции
      when S_HWLOG_WAIT_TRNDONE =>

        if p_in_rbuf_cfg.dmacfg.hw_mode='0' then
          fsm_rambuf_cs <= S_IDLE;
        else
          if i_hw_trn_done='1' then
            fsm_rambuf_cs <= S_HWLOG_MEM_START;
          end if;
        end if;

      --//Ведем LOG
      when S_HWLOG_MEM_START =>

        i_mem_adr<=i_wr_ptr + p_in_rbuf_cfg.mem_adr;--//Update адреса RAMBUF
        i_mem_lenreq<=CONV_STD_LOGIC_VECTOR(i_hw_log_d'length, i_mem_lenreq'length);
        i_mem_lentrn<=CONV_STD_LOGIC_VECTOR(i_hw_log_d'length, i_mem_lenreq'length); --//размер одиночной транзакции.(Устанавливается программно)
        i_mem_dir<=C_MEMCTRLCHWR_WRITE;
        i_mem_start<='1';

        fsm_rambuf_cs <= S_HWLOG_MEM_WORK;

      --//Отработка mem транзакции
      when S_HWLOG_MEM_WORK =>

        i_mem_start<='0';

        update_addr(1 downto 0) :=(others=>'0');
        update_addr(i_mem_lenreq'length+1 downto 2):=i_mem_lenreq;

        if i_mem_done='1' then
          --//Операция выполнена:
          --//Обновляем указатель записи + уровень данных в буфере
          i_wr_ptr<=i_wr_ptr + EXT(update_addr, i_wr_ptr'length);

          fsm_rambuf_cs <= S_HWLOG_WAIT_TRNDONE;
        end if;


    end case;
  end if;
end process;



--//------------------------------------------------------
--//Модуль записи/чтения данных ОЗУ (memory_ctrl.vhd)
--//------------------------------------------------------
p_out_vbuf_rd <=p_in_rbuf_cfg.dmacfg.hw_mode and i_usr_rxbuf_rd;

p_out_hdd_rxd_rd<=p_in_rbuf_cfg.dmacfg.sw_mode and i_usr_rxbuf_rd;

i_usr_rxbuf_1empty<=p_in_hdd_rxbuf_empty when p_in_rbuf_cfg.dmacfg.sw_mode='1' else p_in_vbuf_empty;
i_usr_rxbuf_1dout <=p_in_hdd_rxd         when p_in_rbuf_cfg.dmacfg.sw_mode='1' else p_in_vbuf_dout;

i_usr_rxbuf_empty<= i_usr_rxbuf_1empty when p_in_rbuf_cfg.hwlog.log_on='0' else '0';
i_usr_rxbuf_dout <= i_usr_rxbuf_1dout  when p_in_rbuf_cfg.hwlog.log_on='0' else i_hw_log_d(0);


m_mem_ctrl_wr : memory_ctrl_ch_wr
generic map(
G_MEM_BANK_MSB_BIT   => C_DSN_HDD_REG_RBUF_ADR_BANK_MSB_BIT,
G_MEM_BANK_LSB_BIT   => C_DSN_HDD_REG_RBUF_ADR_BANK_LSB_BIT
)
port map
(
-------------------------------
-- Конфигурирование
-------------------------------
p_in_cfg_mem_adr           => i_mem_adr,
p_in_cfg_mem_trn_len       => i_mem_lentrn,
p_in_cfg_mem_dlen_rq       => i_mem_lenreq,
p_in_cfg_mem_wr            => i_mem_dir,
p_in_cfg_mem_start         => i_mem_start,
p_out_cfg_mem_done         => i_mem_done,

-------------------------------
-- Связь с пользовательскими буферами
-------------------------------
p_in_usr_txbuf_dout        => i_usr_rxbuf_dout,
p_out_usr_txbuf_rd         => i_usr_rxbuf_rd,
p_in_usr_txbuf_empty       => i_usr_rxbuf_empty,

p_out_usr_rxbuf_din        => p_out_hdd_txd,      --i_usr_txbuf_din, --
p_out_usr_rxbuf_wd         => p_out_hdd_txd_wr,   --i_usr_txbuf_wd,  --
p_in_usr_rxbuf_full        => p_in_hdd_txbuf_full,--i_usr_txbuf_full,--

---------------------------------
-- Связь с memory_ctrl.vhd
---------------------------------
p_out_memarb_req           => p_out_memarb_req,
p_in_memarb_en             => p_in_memarb_en,

p_out_mem_bank1h           => p_out_mem_bank1h,
p_out_mem_ce               => p_out_mem_ce,
p_out_mem_cw               => p_out_mem_cw,
p_out_mem_rd               => p_out_mem_rd,
p_out_mem_wr               => p_out_mem_wr,
p_out_mem_term             => p_out_mem_term,
p_out_mem_adr              => p_out_mem_adr,
p_out_mem_be               => p_out_mem_be,
p_out_mem_din              => p_out_mem_din,
p_in_mem_dout              => p_in_mem_dout,

p_in_mem_wf                => p_in_mem_wf,
p_in_mem_wpf               => p_in_mem_wpf,
p_in_mem_re                => p_in_mem_re,
p_in_mem_rpe               => p_in_mem_rpe,

p_out_mem_clk              => p_out_mem_clk,

-------------------------------
--Технологический
-------------------------------
p_in_tst                   => "00000000000000000000000000000000",
p_out_tst                  => open,

-------------------------------
--System
-------------------------------
p_in_clk            => p_in_clk,
p_in_rst            => p_in_rst
);


end generate gen_use_on;


gen_use_off : if strcmp(G_MODULE_USE,"OFF") generate

p_out_rbuf_status.err<='0';
--p_out_rbuf_status.rdy<='0';
--p_out_rbuf_status.done<='0';

p_out_mem_clk <= p_in_clk;

p_out_mem_bank1h <=(others=>'0');
p_out_mem_ce     <='0';
p_out_mem_cw     <='0';
p_out_mem_rd     <='0';
p_out_mem_wr     <='0';
p_out_mem_term   <='0';
p_out_mem_adr    <=(others=>'0');
p_out_mem_be     <=(others=>'0');
p_out_mem_din    <=(others=>'0');

p_out_memarb_req <='0';

p_out_vbuf_rd <= not p_in_vbuf_empty;

p_out_hdd_txd <= p_in_vbuf_dout;
p_out_hdd_txd_wr <= not p_in_vbuf_empty;


p_out_hdd_rxd_rd<='0';

p_out_tst(0)<=OR_reduce(p_in_vbuf_dout) or p_in_vbuf_empty or
              OR_reduce(p_in_hdd_rxd) or p_in_hdd_rxbuf_empty or p_in_hdd_txbuf_full;
p_out_tst(31 downto 1) <= (others=>'0');

end generate gen_use_off;

--END MAIN
end behavioral;


