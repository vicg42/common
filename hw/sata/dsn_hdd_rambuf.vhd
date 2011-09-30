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
G_MODULE_USE           : string:="ON";
G_RAMBUF_SIZE          : integer:=23; --//(в BYTE). Определяется как 2 в степени G_RAMBUF_SIZE
G_DBGCS                : string:="OFF";
G_SIM                  : string:="OFF"
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
p_in_vbuf_wrcnt       : in    std_logic_vector(3 downto 0);

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

--//selval(true, false , select(true/false) );
constant CI_SECTOR_SIZE_BYTE : integer:=selval(C_SECTOR_SIZE_BYTE, C_SIM_SECTOR_SIZE_DWORD*4, strcmp(G_SIM, "OFF"));


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
S_HW_MEMR_CHECK,

S_HW_MEMA_CHECK1,
S_HW_MEMA_CHECK2,
S_HW_MEMA_CHECK3,

S_HW_MEM_START,
S_HW_MEM_WORK,
S_HW_FULL_CHECK,

S_HWLOG_WAIT_TRNDONE,
S_HWLOG_MEM_START,
S_HWLOG_MEM_WORK

);
signal fsm_rambuf_cs                   : fsm_state;

signal i_clr_err                       : std_logic;
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

signal i_vbuf_pfull                    : std_logic;
signal i_vbuf_wrcnt                    : std_logic_vector(p_in_vbuf_wrcnt'range);
signal i_hdd_txbuf_pfull               : std_logic;

signal i_mem_adr                       : std_logic_vector(31 downto 0);--//(BYTE)
signal i_mem_lenreq                    : std_logic_vector(15 downto 0);--//Размер запрашиваемых данных (DWORD)
signal i_mem_lentrn                    : std_logic_vector(15 downto 0);--//Размер одиночной транзакции
signal i_mem_dir                       : std_logic;
signal i_mem_start                     : std_logic;
signal i_mem_done                      : std_logic;

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
signal tst_rambuf_pfull                : std_logic:='0';
signal tst_fsm_cs                      : std_logic_vector(4 downto 0);
signal sr_hw_work                      : std_logic_vector(0 to 1):=(others=>'0');
signal tst_hw_stop                     : std_logic:='0';
signal tst_mem_ctrl_out                : std_logic_vector(31 downto 0);
signal tst_timeout_cnt                 : std_logic_vector(11 downto 0);
signal tst_timeout                     : std_logic;


--MAIN
begin



gen_use_on : if strcmp(G_MODULE_USE,"ON") generate

--//----------------------------------
--//Технологические сигналы
--//----------------------------------
p_out_tst<=(others=>'0');


--//----------------------------------------------
--//Статусы
--//----------------------------------------------
p_out_rbuf_status.err<=i_err_det.rambuf_full or i_err_det.vinbuf_full;
p_out_rbuf_status.err_type<=i_err_det;
p_out_rbuf_status.done<=i_rambuf_done;
p_out_rbuf_status.hwlog_size<=i_wr_ptr;
--p_out_rbuf_status.rdy<='0';

--//Сброс/детектирование переполнения потокового буфера +
--//входного видео буфера
process(p_in_rst,p_in_clk)
begin
  if p_in_rst='1' then
    i_err_det.vinbuf_full<='0';
    i_err_det.rambuf_full<='0';
  elsif p_in_clk'event and p_in_clk='1' then

    if i_clr_err='1' then
      i_err_det.rambuf_full<='0';
    elsif i_rambuf_full='1' and
          (p_in_rbuf_cfg.dmacfg.sw_mode='1' or p_in_rbuf_cfg.dmacfg.hw_mode='1') then
      i_err_det.rambuf_full<='1';
    end if;

    if i_clr_err='1' then
      i_err_det.vinbuf_full<='0';
    elsif p_in_vbuf_full='1' and
          (p_in_rbuf_cfg.dmacfg.sw_mode='1' or p_in_rbuf_cfg.dmacfg.hw_mode='1') then
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
    elsif p_in_rbuf_cfg.dmacfg.atadone='1' then
      i_atadone<='1';
    end if;
  end if;
end process;


process(p_in_rst,p_in_clk)
begin
  if p_in_rst='1' then

    i_clr_err<='0';

    i_vbuf_pfull<='0';
    i_vbuf_wrcnt<=(others=>'0');

    i_hdd_txbuf_pfull<='0';

    i_hw_measure<='0';
    sr_hw_trn_done<=(others=>'0');
    i_hw_trn_done<='0';
    for i in 0 to i_hw_log_d'length-1 loop
    i_hw_log_d(i)<=(others=>'0');
    end loop;

  elsif p_in_clk'event and p_in_clk='1' then

    i_clr_err<=p_in_rbuf_cfg.dmacfg.clr_err;

    i_vbuf_wrcnt<=p_in_vbuf_wrcnt;
    i_vbuf_pfull<=p_in_vbuf_pfull;

    i_hdd_txbuf_pfull<=p_in_hdd_txbuf_pfull;

    i_hw_measure<=p_in_rbuf_cfg.hwlog.measure;
    sr_hw_trn_done<=i_hw_measure & sr_hw_trn_done(0 to 0);
    i_hw_trn_done<=not sr_hw_trn_done(0) and sr_hw_trn_done(1);

    i_hw_log_d(0)<=p_in_rbuf_cfg.hwlog.tdly;
--    i_hw_log_d(0)<=p_in_rbuf_cfg.hwlog.twork;

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
begin
  if p_in_rst='1' then
      update_addr:=(others=>'0');

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

  elsif p_in_clk'event and p_in_clk='1' then

    case fsm_rambuf_cs is

      --//####################################
      --//Исходное состояние
      --//####################################
      when S_IDLE =>

        i_rambuf_done<='0';

        if p_in_rbuf_cfg.tstgen.tesing_on='1' and p_in_rbuf_cfg.tstgen.con2rambuf='0' then

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
                i_ptr<=(others=>'0');

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
          if i_hdd_txbuf_pfull='0' then
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
      --//Выбор операции
      --//----------------------------------------------
      --//WRITE
      when S_HW_MEMW_CHECK =>

        if p_in_rbuf_cfg.dmacfg.hw_mode='0' then
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
              i_mem_dir<=C_MEMCTRLCHWR_WRITE;
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
            if i_rambuf_dcnt>CONV_STD_LOGIC_VECTOR(512, i_rambuf_dcnt'length) then
               i_lenreq<=CONV_STD_LOGIC_VECTOR(512, i_lenreq'length);
            else
               i_lenreq<=i_rambuf_dcnt(15 downto 0);
            end if;

            if i_rd_ptr(G_RAMBUF_SIZE)='1' then
              --//Закольцовываю указатель RAMBUF
              i_rd_ptr<=(others=>'0');
            end if;

            i_mem_dir<=C_MEMCTRLCHWR_READ;
            fsm_rambuf_cs <= S_HW_MEMA_CHECK1;--//Переход к анализу кол-ва операций с ОЗУ

        else
          fsm_rambuf_cs <= S_HW_MEMW_CHECK;--//Переход к анализу ЗАПИСИ
        end if;


      --//----------------------------------------------
      --//Анализ кол-ва операций(Action) с ОЗУ
      --//----------------------------------------------
      when S_HW_MEMA_CHECK1 =>

        --//т.к. i_ptr (BYTE), а i_lenreq(DWORD)
        if i_mem_dir=C_MEMCTRLCHWR_WRITE then
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
        if i_mem_dir=C_MEMCTRLCHWR_WRITE then
            if i_wr_ptr(G_RAMBUF_SIZE)='1' then
              --//Закольцовываю указатель RAMBUF
              i_wr_ptr<=(others=>'0');
              i_mem_adr<=p_in_rbuf_cfg.mem_adr;
            else
              i_mem_adr<=i_wr_ptr + p_in_rbuf_cfg.mem_adr;
            end if;
        else
            if i_rd_ptr(G_RAMBUF_SIZE)='1' then
              --//Закольцовываю указатель RAMBUF
              i_rd_ptr<=(others=>'0');
              i_mem_adr<=p_in_rbuf_cfg.mem_adr;
            else
              i_mem_adr<=i_rd_ptr + p_in_rbuf_cfg.mem_adr;
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

--        i_mem_dir<=C_MEMCTRLCHWR_WRITE;
        if p_in_rbuf_cfg.dmacfg.hw_mode='0' then
        --//HW mode - DONE!!!
          fsm_rambuf_cs <= S_IDLE;
        else
          i_mem_start<='1';
          fsm_rambuf_cs <= S_HW_MEM_WORK;
        end if;

      when S_HW_MEM_WORK =>

        i_mem_start<='0';

        --//Формируем значение для обнавления адреса ОЗУ.
        --//это действие необходимо т.к. значение i_mem_lenreq в DWORD, а
        --//значение i_wr_ptr должно быть в BYTE
        update_addr(1 downto 0) :=(others=>'0');
        update_addr(i_mem_lenreq'length+1 downto 2):=i_mem_lenreq;

        if i_mem_done='1' then
        --//Операция выполнена:
          --//Обновляем указатель + уровень данных в буфере
          if i_mem_dir=C_MEMCTRLCHWR_WRITE then
              i_wr_ptr<=i_wr_ptr + EXT(update_addr, i_wr_ptr'length);
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
              i_rd_ptr<=i_rd_ptr + EXT(update_addr, i_rd_ptr'length);
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
          i_rambuf_full<='1';
          i_rambuf_dcnt<=CONV_STD_LOGIC_VECTOR(pwr(2,G_RAMBUF_SIZE-2), i_rambuf_dcnt'length);
        end if;

        fsm_rambuf_cs <= S_HW_MEMR_CHECK;--//Переход к анализу ЧТЕНИЯ


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
        i_mem_lentrn<=CONV_STD_LOGIC_VECTOR(i_hw_log_d'length, i_mem_lenreq'length);
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
p_out_tst                  => tst_mem_ctrl_out,

-------------------------------
--System
-------------------------------
p_in_clk            => p_in_clk,
p_in_rst            => p_in_rst
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

p_out_dbgcs.clk<=p_in_clk;

p_out_dbgcs.trig0(4 downto  0)  <=tst_fsm_cs(4 downto 0);
p_out_dbgcs.trig0(5)            <='0'; ------------------//зарезервировано для i_hdd_mem_ce;
p_out_dbgcs.trig0(6)            <='0'; ------------------//зарезервировано для i_hdd_mem_cw;
p_out_dbgcs.trig0(7)            <=i_err_det.rambuf_full or i_err_det.vinbuf_full;
p_out_dbgcs.trig0(8)            <=i_err_det.rambuf_full;
p_out_dbgcs.trig0(9)            <=i_err_det.vinbuf_full;
p_out_dbgcs.trig0(10)           <=p_in_hdd_txbuf_full;
p_out_dbgcs.trig0(11)           <=i_hdd_txbuf_pfull;--p_in_hdd_txbuf_pfull;
p_out_dbgcs.trig0(12)           <=tst_hw_stop;
p_out_dbgcs.trig0(13)           <=tst_rambuf_pfull;
p_out_dbgcs.trig0(14)           <=i_mem_dir;
p_out_dbgcs.trig0(15)           <=i_vbuf_wrcnt(0);
p_out_dbgcs.trig0(16)           <=i_vbuf_wrcnt(1);
p_out_dbgcs.trig0(17)           <=i_vbuf_wrcnt(2);
p_out_dbgcs.trig0(18)           <=i_vbuf_wrcnt(3);
p_out_dbgcs.trig0(19)           <=i_doble_act;
p_out_dbgcs.trig0(20)           <=i_vbuf_pfull;
p_out_dbgcs.trig0(29 downto 21)<=(others=>'0');------------------//зарезервировано
p_out_dbgcs.trig0(30)           <=tst_timeout;
p_out_dbgcs.trig0(31)           <='0';
p_out_dbgcs.trig0(32)           <='0';
p_out_dbgcs.trig0(33)           <='0';
p_out_dbgcs.trig0(34)           <='0';
p_out_dbgcs.trig0(35)           <=i_clr_err;
p_out_dbgcs.trig0(63 downto 36) <=(others=>'0');


p_out_dbgcs.data(0)<='0'; ------------------//зарезервировано для i_hdd_mem_ce;
p_out_dbgcs.data(1)<='0'; ------------------//зарезервировано для i_hdd_mem_cw;
p_out_dbgcs.data(2)<='0'; ------------------//зарезервировано для i_mem_arb1_rd; ;
p_out_dbgcs.data(3)<='0'; ------------------//зарезервировано для i_mem_arb1_wr; ;
p_out_dbgcs.data(4)<='0'; ------------------//зарезервировано для i_mem_arb1_term;
p_out_dbgcs.data(9 downto 5)     <=tst_fsm_cs(4 downto 0);
p_out_dbgcs.data(10)             <=i_err_det.vinbuf_full;
p_out_dbgcs.data(11)             <=i_err_det.rambuf_full;
p_out_dbgcs.data(12)             <=tst_rambuf_empty;
p_out_dbgcs.data(13)             <=p_in_vbuf_empty;
p_out_dbgcs.data(14)             <=p_in_hdd_rxbuf_empty;
p_out_dbgcs.data(15)             <=p_in_rbuf_cfg.dmacfg.atacmdw;
p_out_dbgcs.data(16)             <=p_in_rbuf_cfg.dmacfg.hw_mode;
p_out_dbgcs.data(17)             <=p_in_hdd_txbuf_full;
p_out_dbgcs.data(18)             <=i_doble_act;
p_out_dbgcs.data(19)             <='0';------------------//зарезервировано для tst_swt_hdd_vbuf_wr
p_out_dbgcs.data(23 downto 20)   <=i_vbuf_wrcnt;
p_out_dbgcs.data(24)             <=i_usr_rxbuf_empty;
p_out_dbgcs.data(25)             <=i_mem_start;
p_out_dbgcs.data(29 downto 26)   <=tst_mem_ctrl_out(5 downto 2);--//memory_ctrl_ch_wr/fsm(0)
p_out_dbgcs.data(30)             <=p_in_mem_re;
p_out_dbgcs.data(31)             <=p_in_mem_wpf;
p_out_dbgcs.data(63 downto 32)   <=i_rambuf_dcnt(31 downto 0);
p_out_dbgcs.data(73 downto 64)   <=i_mem_lenreq(9 downto 0);
p_out_dbgcs.data(83 downto 74)   <=i_mem_lentrn(9 downto 0);
p_out_dbgcs.data(87 downto 84)   <=(others=>'0');
p_out_dbgcs.data(88)             <='0';
p_out_dbgcs.data(89)             <='0';
p_out_dbgcs.data(103 downto 90)  <=(others=>'0');
p_out_dbgcs.data(119 downto 104) <=(others=>'0');
p_out_dbgcs.data(135 downto 120) <=(others=>'0');-------------------//зарезервировано
p_out_dbgcs.data(151 downto 136) <=tst_mem_ctrl_out(31 downto 16);--//memory_ctrl_ch_wr/i_mem_trn_len
p_out_dbgcs.data(166 downto 152) <=(others=>'0');------------------//зарезервировано
p_out_dbgcs.data(171)             <=i_hdd_txbuf_pfull;--p_in_hdd_txbuf_pfull;


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
            CONV_STD_LOGIC_VECTOR(16#00#,tst_fsm_cs'length); --//when fsm_rambuf_cs=S_IDLE          else


process(p_in_rst,p_in_clk)
begin
if p_in_rst='1' then
  tst_timeout_cnt<=(others=>'0');
  tst_timeout<='0';

  sr_hw_work<=(others=>'0');
  tst_hw_stop<='0';

  tst_rambuf_pfull<='0';
  tst_rambuf_empty<='1';

elsif p_in_clk'event and p_in_clk='1' then


--  if tst_mem_ctrl_out(5 downto 2)=CONV_STD_LOGIC_VECTOR(6, 4) then  --//memory_ctrl_ch_wr/fsm=S_MEM_TRN
  if fsm_rambuf_cs=S_HW_MEM_WORK and i_mem_dir=C_MEMCTRLCHWR_READ then
    if tst_timeout_cnt>CONV_STD_LOGIC_VECTOR(650, tst_timeout_cnt'length) then
      tst_timeout<='1';
    else
      tst_timeout_cnt<=tst_timeout_cnt + 1;
      tst_timeout<='0';
    end if;
  else
    tst_timeout_cnt<=(others=>'0');
    tst_timeout<='0';
  end if;

  sr_hw_work<=p_in_rbuf_cfg.dmacfg.hw_mode & sr_hw_work(0 to 0);
  tst_hw_stop<=not sr_hw_work(0) and sr_hw_work(1);

  if i_rambuf_dcnt=(i_rambuf_dcnt'range =>'0') then
    tst_rambuf_empty<='1';
  else
    tst_rambuf_empty<='0';
  end if;

  if i_rambuf_dcnt>=CONV_STD_LOGIC_VECTOR(pwr(2, 10), i_rambuf_dcnt'length) then
    tst_rambuf_pfull<='1';
  else
    tst_rambuf_pfull<='0';
  end if;


end if;
end process;


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

p_out_tst(0)<=OR_reduce(p_in_vbuf_dout) or p_in_vbuf_empty or OR_reduce(p_in_vbuf_wrcnt) or
              OR_reduce(p_in_hdd_rxd) or p_in_hdd_rxbuf_empty or p_in_hdd_txbuf_full;
p_out_tst(31 downto 1) <= (others=>'0');

end generate gen_use_off;

--END MAIN
end behavioral;


