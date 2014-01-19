-------------------------------------------------------------------------
-- Company     : Linkos
-- Engineer    : Golovachenko Victor
--
-- Create Date : 2010.06
-- Module Name : mem_wr
--
-- Назначение/Описание :
--  Запись/Чтение данных ОЗУ
--
-- p_in_cfg_mem_dlen_rq (total request size)  : <--------------------------------->
-- p_in_cfg_mem_trn_len (size one transaction): <-----> <-----> <-----> ... <----->
--
-------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

library work;
use work.vicg_common_pkg.all;
use work.mem_wr_pkg.all;

entity mem_wr is
generic(
G_USR_OPT        : std_logic_vector(3 downto 0):=(others=>'0');
G_MEM_BANK_M_BIT : integer:=29;--биты(мл. ст.) определяющие банк ОЗУ. Относится в порту p_in_cfg_mem_adr
G_MEM_BANK_L_BIT : integer:=28;
G_MEM_AWIDTH     : integer:=32;
G_MEM_DWIDTH     : integer:=32
);
port(
-------------------------------
--Конфигурирование
-------------------------------
p_in_cfg_mem_adr     : in    std_logic_vector(31 downto 0);--Адрес ОЗУ (в BYTE)
p_in_cfg_mem_trn_len : in    std_logic_vector(15 downto 0);--Размер одиночной MEM_TRN (в DWORD)
p_in_cfg_mem_dlen_rq : in    std_logic_vector(15 downto 0);--Размер запрашиваемых данных записи/чтения (в DWORD)
p_in_cfg_mem_wr      : in    std_logic;                    --Тип операции
p_in_cfg_mem_start   : in    std_logic;                    --Строб: Пуск операции
p_out_cfg_mem_done   : out   std_logic;                    --Строб: Операции завершена

-------------------------------
--Связь с пользовательскими буферами
-------------------------------
--usr_buf->mem
p_in_usr_txbuf_dout  : in    std_logic_vector(G_MEM_DWIDTH-1 downto 0);
p_out_usr_txbuf_rd   : out   std_logic;
p_in_usr_txbuf_empty : in    std_logic;

--usr_buf<-mem
p_out_usr_rxbuf_din  : out   std_logic_vector(G_MEM_DWIDTH-1 downto 0);
p_out_usr_rxbuf_wd   : out   std_logic;
p_in_usr_rxbuf_full  : in    std_logic;

---------------------------------
--Связь с mem_ctrl.vhd
---------------------------------
p_out_mem            : out   TMemIN;
p_in_mem             : in    TMemOUT;

-------------------------------
--Технологические сигналы
-------------------------------
p_in_tst             : in    std_logic_vector(31 downto 0);
p_out_tst            : out   std_logic_vector(31 downto 0);

-------------------------------
--System
-------------------------------
p_in_clk             : in    std_logic;
p_in_rst             : in    std_logic
);
end mem_wr;

architecture behavioral of mem_wr is

type fsm_state is (
S_IDLE,
S_MEM_REMAIN_SIZE_CALC,
S_MEM_TRN_LEN_CALC,
S_MEM_WAIT_RQ_EN,
S_MEM_TRN_START,
S_MEM_TRN_START_DONE,
S_MEM_TRN,
S_MEM_TRN_END,
S_WAIT,
S_EXIT
);
signal fsm_state_cs        : fsm_state;

signal i_mem_req           : std_logic;--Запрос на захват ОЗУ
signal i_mem_bank          : std_logic_vector(p_out_mem.bank'range);
signal i_mem_adr           : std_logic_vector(G_MEM_BANK_L_BIT-1 downto 0);
signal i_mem_dir           : std_logic;
signal i_mem_ce            : std_logic;
signal i_mem_wr            : std_logic;
signal i_mem_rd            : std_logic;
signal i_mem_term          : std_logic;
signal i_mem_dlen_remain   : std_logic_vector(p_in_cfg_mem_dlen_rq'length-1 downto 0);
signal i_mem_dlen_used     : std_logic_vector(p_in_cfg_mem_dlen_rq'length-1 downto 0);
signal i_mem_trn_work      : std_logic;
signal i_mem_trn_len       : std_logic_vector(p_in_cfg_mem_trn_len'length-1 downto 0);
signal i_mem_done          : std_logic;

signal sr_mem_ce           : std_logic;
signal sr_mem_wr           : std_logic;
signal sr_mem_term         : std_logic;
signal sr_usr_txbuf_dout   : std_logic_vector(p_in_usr_txbuf_dout'range);

signal tst_fsm_cs          : std_logic_vector(3 downto 0);


--MAIN
begin

------------------------------------
--Технологические сигналы
------------------------------------
--p_out_tst<=(others=>'0');
p_out_tst(0)<=i_mem_term;
p_out_tst(1)<=sr_mem_term;
p_out_tst(5 downto 2)<=tst_fsm_cs;
p_out_tst(15 downto 6)<=(others=>'0');
p_out_tst(31 downto 16)<=i_mem_trn_len;

tst_fsm_cs<=CONV_STD_LOGIC_VECTOR(16#01#,tst_fsm_cs'length) when fsm_state_cs=S_MEM_REMAIN_SIZE_CALC  else
            CONV_STD_LOGIC_VECTOR(16#02#,tst_fsm_cs'length) when fsm_state_cs=S_MEM_TRN_LEN_CALC      else
            CONV_STD_LOGIC_VECTOR(16#03#,tst_fsm_cs'length) when fsm_state_cs=S_MEM_WAIT_RQ_EN        else
            CONV_STD_LOGIC_VECTOR(16#04#,tst_fsm_cs'length) when fsm_state_cs=S_MEM_TRN_START         else
            CONV_STD_LOGIC_VECTOR(16#05#,tst_fsm_cs'length) when fsm_state_cs=S_MEM_TRN_START_DONE    else
            CONV_STD_LOGIC_VECTOR(16#06#,tst_fsm_cs'length) when fsm_state_cs=S_MEM_TRN               else
            CONV_STD_LOGIC_VECTOR(16#07#,tst_fsm_cs'length) when fsm_state_cs=S_MEM_TRN_END           else
            CONV_STD_LOGIC_VECTOR(16#08#,tst_fsm_cs'length) when fsm_state_cs=S_WAIT                  else
            CONV_STD_LOGIC_VECTOR(16#09#,tst_fsm_cs'length) when fsm_state_cs=S_EXIT                  else
            CONV_STD_LOGIC_VECTOR(16#00#,tst_fsm_cs'length); --when fsm_state_cs=S_IDLE               else


-------------------------------
--Связь с пользовательскими буферами
-------------------------------
p_out_usr_txbuf_rd <= i_mem_wr;

process(p_in_rst,p_in_clk)
begin
  if p_in_rst='1' then
    p_out_usr_rxbuf_wd <='0';
    p_out_usr_rxbuf_din<=(others=>'0');
  elsif p_in_clk'event and p_in_clk='1' then
    p_out_usr_rxbuf_wd <=i_mem_rd;
    p_out_usr_rxbuf_din<=p_in_mem.data(p_out_usr_rxbuf_din'range);
  end if;
end process;


------------------------------------------------
--Связь с контроллером памяти
------------------------------------------------
p_out_mem.clk <=p_in_clk;
p_out_mem.req <=i_mem_req;
p_out_mem.ce  <=i_mem_ce when i_mem_dir=C_MEMWR_READ else sr_mem_ce;
p_out_mem.cw  <=i_mem_dir;
p_out_mem.wr  <=sr_mem_wr;
p_out_mem.rd  <=i_mem_rd;
p_out_mem.term<=i_mem_term when i_mem_dir=C_MEMWR_READ else sr_mem_term;
p_out_mem.bank<=i_mem_bank;
p_out_mem.adr <=EXT(i_mem_adr(i_mem_adr'high downto 2), p_out_mem.adr'length);
p_out_mem.data<=EXT(sr_usr_txbuf_dout, p_out_mem.data'length);
p_out_mem.dbe <=(others=>'1');

process(p_in_rst,p_in_clk)
begin
  if p_in_rst='1' then

    i_mem_term<='0';
    sr_mem_ce<='0';
    sr_mem_wr<='0';
    sr_mem_term<='0';
    sr_usr_txbuf_dout<=(others=>'0');

  elsif p_in_clk'event and p_in_clk='1' then

    --Формируем сигнал остановки текущей операции(write/read) ОЗУ
    if i_mem_dir=C_MEMWR_READ then
      if i_mem_rd='1' and i_mem_trn_len=(i_mem_trn_len'range => '0') then
        i_mem_term<='1';
      else
        i_mem_term<='0';
      end if;

    else
      if (i_mem_wr='1' or fsm_state_cs=S_MEM_TRN_START_DONE) and i_mem_trn_len=CONV_STD_LOGIC_VECTOR(1, i_mem_trn_len'length) then
        i_mem_term<='1';
      elsif i_mem_wr='1' and i_mem_trn_len=(i_mem_trn_len'range => '0') then
        i_mem_term<='0';
      end if;
    end if;

    sr_mem_ce<=i_mem_ce;
    sr_mem_wr<=i_mem_wr;
    sr_mem_term<=i_mem_term and i_mem_wr;
    sr_usr_txbuf_dout<=p_in_usr_txbuf_dout;

  end if;
end process;


------------------------------------------------
--Автомат записи/чтения данных ОЗУ
------------------------------------------------
--Текущая операция выполнена
p_out_cfg_mem_done<=i_mem_done;

--Стробы записи/чтения ОЗУ
i_mem_rd<=i_mem_trn_work and not p_in_mem.buf_re  and not p_in_usr_rxbuf_full  when i_mem_dir=C_MEMWR_READ  else '0';
i_mem_wr<=i_mem_trn_work and not p_in_mem.buf_wpf and not p_in_usr_txbuf_empty when i_mem_dir=C_MEMWR_WRITE else '0';

--Логика работы автомата
process(p_in_rst,p_in_clk)
  variable update_addr: std_logic_vector(i_mem_trn_len'length+1 downto 0);
begin
  if p_in_rst='1' then

    fsm_state_cs <= S_IDLE;
      update_addr:=(others=>'0');

    i_mem_req<='0';
    i_mem_bank<=(others=>'0');
    i_mem_adr<=(others=>'0');
    i_mem_ce<='0';
    i_mem_dir<='0';
    i_mem_dlen_remain<=(others=>'0');
    i_mem_dlen_used<=(others=>'0');
    i_mem_trn_len<=(others=>'0');
    i_mem_trn_work<='0';
    i_mem_done<='0';

  elsif p_in_clk'event and p_in_clk='1' then

    case fsm_state_cs is

      when S_IDLE =>

        i_mem_done<='0';
      --------------------------------------
      --Ждем сигнала запуска операции
      --------------------------------------
        if p_in_cfg_mem_start='1' then
          i_mem_adr<=p_in_cfg_mem_adr(G_MEM_BANK_L_BIT-1 downto 0);
          i_mem_dir <=p_in_cfg_mem_wr;

          --Назначаем банк ОЗУ
          for i in 0 to i_mem_bank'high loop
            if p_in_cfg_mem_adr(G_MEM_BANK_M_BIT downto G_MEM_BANK_L_BIT)= i then
              i_mem_bank(i) <= '1';
            else
              i_mem_bank(i) <= '0';
            end if;
          end loop;

          fsm_state_cs <= S_MEM_REMAIN_SIZE_CALC;
        end if;

      --------------------------------------
      --Расчитываем сколько данных запрашиваемых пользователем осталось в работе
      --------------------------------------
      when S_MEM_REMAIN_SIZE_CALC =>

        i_mem_dlen_remain <= EXT(p_in_cfg_mem_dlen_rq, p_in_cfg_mem_dlen_rq'length) - EXT(i_mem_dlen_used, p_in_cfg_mem_dlen_rq'length);
        fsm_state_cs <= S_MEM_TRN_LEN_CALC;

      --------------------------------------
      --Назначаем размер транзакции write/read ОЗУ
      --------------------------------------
      when S_MEM_TRN_LEN_CALC =>

        if i_mem_dlen_remain >= EXT(p_in_cfg_mem_trn_len, p_in_cfg_mem_dlen_rq'length) then
          i_mem_trn_len <= p_in_cfg_mem_trn_len;
        else
          i_mem_trn_len <= i_mem_dlen_remain(i_mem_trn_len'high downto 0);
        end if;

        i_mem_req<='1';--Запрос на захват ОЗУ
        fsm_state_cs <= S_MEM_WAIT_RQ_EN;--S_MEM_TRN_START;

      --------------------------------------
      --Ждем разрешения захвата ОЗУ
      --------------------------------------
      when S_MEM_WAIT_RQ_EN =>

        if p_in_mem.req_en='1' then
          fsm_state_cs <= S_MEM_TRN_START;
        end if;

      --------------------------------------
      --Готовимся к записи/чтению ОЗУ
      --------------------------------------
      when S_MEM_TRN_START =>

        if i_mem_dir=C_MEMWR_WRITE then
          if p_in_mem.buf_wpf='0'then
            i_mem_ce<='1';
            fsm_state_cs <= S_MEM_TRN_START_DONE;
          end if;
        else
          i_mem_ce<='1';
          fsm_state_cs <= S_MEM_TRN_START_DONE;
        end if;

      --------------------------------------
      --Пуск транзакции write/read ОЗУ
      --------------------------------------
      when S_MEM_TRN_START_DONE =>

        i_mem_trn_len<=i_mem_trn_len-1;
        i_mem_ce<='0';
        i_mem_trn_work<='1';
        fsm_state_cs <= S_MEM_TRN;

      ------------------------------------------------
      --Запись/Чтение данных ОЗУ
      ------------------------------------------------
      when S_MEM_TRN =>

        if i_mem_wr='1' or i_mem_rd='1' then
          i_mem_dlen_used<=i_mem_dlen_used+1;

          if i_mem_trn_len=(i_mem_trn_len'range => '0') then
            i_mem_trn_len<=(others=>'0');
            i_mem_trn_work<='0';
            fsm_state_cs <= S_MEM_TRN_END;
          else
            i_mem_trn_len<=i_mem_trn_len-1;
          end if;
        end if;

      ------------------------------------------------
      --Анализ завершения текущей транзакции write/read ОЗУ
      ------------------------------------------------
      when S_MEM_TRN_END =>

        --Вычисляем значение для обнавления адреса ОЗУ
        update_addr(1 downto 0):=(others=>'0');--Если p_in_cfg_mem_trn_len в DW
        update_addr(i_mem_trn_len'length+1 downto 2):=p_in_cfg_mem_trn_len;

        if p_in_cfg_mem_dlen_rq=i_mem_dlen_used then
          fsm_state_cs <= S_EXIT;
        else
          --Вычисляем следующий адрес ОЗУ
          i_mem_adr<=i_mem_adr + EXT(update_addr, i_mem_adr'length);

          fsm_state_cs <= S_WAIT;--S_MEM_REMAIN_SIZE_CALC;
        end if;

      ------------------------------------------------
      --Переход к следующей транзакции write/read ОЗУ
      ------------------------------------------------
      when S_WAIT =>

        if i_mem_dir=C_MEMWR_READ then
          if p_in_mem.buf_re='1'then
            i_mem_req<='0';
            fsm_state_cs <= S_MEM_REMAIN_SIZE_CALC;
          end if;
        else
          i_mem_req<='0';
          fsm_state_cs <= S_MEM_REMAIN_SIZE_CALC;
        end if;

      ------------------------------------------------
      --Переходим к выполнению следующей операции
      ------------------------------------------------
      when S_EXIT =>

        i_mem_dlen_used<=(others=>'0');

        if i_mem_dir=C_MEMWR_READ then
          if p_in_mem.buf_re='1'then
            i_mem_done<='1';
            i_mem_req<='0';
            fsm_state_cs <= S_IDLE;
          end if;
        else
          i_mem_done<='1';
          i_mem_req<='0';
          fsm_state_cs <= S_IDLE;
        end if;

    end case;
  end if;
end process;

--END MAIN
end behavioral;

