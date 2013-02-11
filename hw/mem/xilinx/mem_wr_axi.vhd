-------------------------------------------------------------------------
-- Company     : Linkos
-- Engineer    : Golovachenko Victor
--
-- Create Date : 22.11.2011 10:01:45
-- Module Name : mem_wr (axi)
--
-- Назначение/Описание :
--  Запись/Чтение данных ОЗУ
--
--
-- Revision:
-- Revision 0.01 - File Created
--
-------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

library work;
use work.mem_wr_pkg.all;

entity mem_wr is
generic(
G_MEM_IDW_NUM    : integer:=0;
G_MEM_IDR_NUM    : integer:=1;
G_MEM_BANK_M_BIT : integer:=29;
G_MEM_BANK_L_BIT : integer:=28;
G_MEM_AWIDTH     : integer:=32;
G_MEM_DWIDTH     : integer:=32
);
port(
-------------------------------
--Конфигурирование
-------------------------------
p_in_cfg_mem_adr     : in    std_logic_vector(31 downto 0);--//Адрес ОЗУ (в BYTE)
p_in_cfg_mem_trn_len : in    std_logic_vector(15 downto 0);--//Размер одиночной MEM_TRN (в DWORD)
p_in_cfg_mem_dlen_rq : in    std_logic_vector(15 downto 0);--//Размер запрашиваемых данных записи/чтения (в DWORD)
p_in_cfg_mem_wr      : in    std_logic;                    --//Тип операции
p_in_cfg_mem_start   : in    std_logic;                    --//Строб: Пуск операции
p_out_cfg_mem_done   : out   std_logic;                    --//Строб: Операции завершена

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
S_MEM_SET_RQ,
S_MEM_WAIT_RQ_EN,
S_MEM_TRN_START,
S_MEM_TRN,
S_MEM_TRN_END,
S_EXIT
);
signal fsm_state_cs        : fsm_state;

signal i_mem_adr           : std_logic_vector(G_MEM_BANK_L_BIT-1 downto 0);
signal i_mem_dir           : std_logic;
signal i_mem_wr            : std_logic;
signal i_mem_rd            : std_logic;
signal i_mem_term          : std_logic:='0';
signal i_mem_dlen_remain   : std_logic_vector(p_in_cfg_mem_dlen_rq'range);
signal i_mem_dlen_used     : std_logic_vector(p_in_cfg_mem_dlen_rq'range);
signal i_mem_trn_work      : std_logic;
signal i_mem_trn_len       : std_logic_vector(p_in_cfg_mem_trn_len'range);
signal i_mem_done          : std_logic;

signal i_axiw_rready       : std_logic;
signal i_axiw_avalid       : std_logic;
signal i_axir_avalid       : std_logic;
signal i_axi_trnlen        : std_logic_vector(p_in_cfg_mem_trn_len'range);

signal i_cfg_mem_dlen_rq   : std_logic_vector(p_in_cfg_mem_dlen_rq'range);
signal i_cfg_mem_trn_len   : std_logic_vector(p_in_cfg_mem_trn_len'range);

signal tst_fsm_cs          : std_logic_vector(3 downto 0);


--MAIN
begin

--//----------------------------------
--//Технологические сигналы
--//----------------------------------
p_out_tst(0)<='0';--i_mem_term;
p_out_tst(1)<='0';--sr_mem_term_out;
p_out_tst(5 downto 2)<=tst_fsm_cs;
p_out_tst(15 downto 6)<=(others=>'0');
p_out_tst(31 downto 16)<=i_mem_trn_len;

tst_fsm_cs<=CONV_STD_LOGIC_VECTOR(16#01#,tst_fsm_cs'length) when fsm_state_cs=S_MEM_REMAIN_SIZE_CALC     else
            CONV_STD_LOGIC_VECTOR(16#02#,tst_fsm_cs'length) when fsm_state_cs=S_MEM_TRN_LEN_CALC         else
            CONV_STD_LOGIC_VECTOR(16#03#,tst_fsm_cs'length) when fsm_state_cs=S_MEM_SET_RQ               else
            CONV_STD_LOGIC_VECTOR(16#04#,tst_fsm_cs'length) when fsm_state_cs=S_MEM_WAIT_RQ_EN           else
            CONV_STD_LOGIC_VECTOR(16#05#,tst_fsm_cs'length) when fsm_state_cs=S_MEM_TRN_START            else
            CONV_STD_LOGIC_VECTOR(16#06#,tst_fsm_cs'length) when fsm_state_cs=S_MEM_TRN                  else
            CONV_STD_LOGIC_VECTOR(16#07#,tst_fsm_cs'length) when fsm_state_cs=S_MEM_TRN_END              else
            CONV_STD_LOGIC_VECTOR(16#08#,tst_fsm_cs'length) when fsm_state_cs=S_EXIT                     else
            CONV_STD_LOGIC_VECTOR(16#00#,tst_fsm_cs'length);--when fsm_state_cs=S_IDLE                     else


--//---------------------------
--//Связь с пользовательскими буферами
--//---------------------------
p_out_usr_txbuf_rd <= i_mem_wr;

p_out_usr_rxbuf_wd  <= i_mem_rd;
p_out_usr_rxbuf_din <= p_in_mem.axir.data(p_out_usr_rxbuf_din'range);


--//----------------------------------------------
--//Связь с контроллером памяти
--//----------------------------------------------
p_out_mem.clk        <=p_in_clk;
--WAddr Port(usr_buf->mem)
p_out_mem.axiw.aid   <=CONV_STD_LOGIC_VECTOR(G_MEM_IDW_NUM, p_out_mem.axiw.aid'length);
p_out_mem.axiw.adr   <=EXT(i_mem_adr, p_out_mem.axiw.adr'length);
p_out_mem.axiw.trnlen<=i_axi_trnlen(p_out_mem.axiw.trnlen'range);
p_out_mem.axiw.dbus  <=CONV_STD_LOGIC_VECTOR(G_MEM_DWIDTH/32 + 1, p_out_mem.axiw.dbus'length); --//2/3/... - BusData=32bit/64bit/...
p_out_mem.axiw.burst <=CONV_STD_LOGIC_VECTOR(1, p_out_mem.axiw.burst'length);--//0/1 - Fixed( FIFO-type)/INCR (Normal sequential memory)
p_out_mem.axiw.lock  <=CONV_STD_LOGIC_VECTOR(0, p_out_mem.axiw.lock'length);
p_out_mem.axiw.cache <=CONV_STD_LOGIC_VECTOR(0, p_out_mem.axiw.cache'length);
p_out_mem.axiw.prot  <=CONV_STD_LOGIC_VECTOR(0, p_out_mem.axiw.prot'length);
p_out_mem.axiw.qos   <=CONV_STD_LOGIC_VECTOR(0, p_out_mem.axiw.qos'length);
p_out_mem.axiw.avalid<=i_axiw_avalid;
--WData Port
p_out_mem.axiw.data  <=EXT(p_in_usr_txbuf_dout, p_out_mem.axiw.data'length);
gen_wbe : for i in 0 to p_out_mem.axiw.dbe'length-1 generate
p_out_mem.axiw.dbe(i)<=i_mem_wr;
end generate gen_wbe;
p_out_mem.axiw.dlast <=i_mem_term and i_mem_wr;
p_out_mem.axiw.dvalid<=i_mem_wr;
--WResponse Port
p_out_mem.axiw.rready<=i_axiw_rready;

--RAddr Port(usr_buf<-mem)
p_out_mem.axir.aid   <=CONV_STD_LOGIC_VECTOR(G_MEM_IDR_NUM, p_out_mem.axir.aid'length);
p_out_mem.axir.adr   <=EXT(i_mem_adr, p_out_mem.axir.adr'length);
p_out_mem.axir.trnlen<=i_axi_trnlen(p_out_mem.axir.trnlen'range);
p_out_mem.axir.dbus  <=CONV_STD_LOGIC_VECTOR(G_MEM_DWIDTH/32 + 1, p_out_mem.axir.dbus'length); --//2/3/... - BusData=32bit/64bit/...
p_out_mem.axir.burst <=CONV_STD_LOGIC_VECTOR(1, p_out_mem.axir.burst'length);--//0/1 - Fixed( FIFO-type)/INCR (Normal sequential memory)
p_out_mem.axir.lock  <=CONV_STD_LOGIC_VECTOR(0, p_out_mem.axir.lock'length);
p_out_mem.axir.cache <=CONV_STD_LOGIC_VECTOR(0, p_out_mem.axir.cache'length);
p_out_mem.axir.prot  <=CONV_STD_LOGIC_VECTOR(0, p_out_mem.axir.prot'length);
p_out_mem.axir.qos   <=CONV_STD_LOGIC_VECTOR(0, p_out_mem.axir.qos'length);
p_out_mem.axir.avalid<=i_axir_avalid;
--RData Port
p_out_mem.axir.rready<=i_mem_trn_work and not p_in_usr_rxbuf_full when i_mem_dir=C_MEMWR_READ  else '0';


process(p_in_clk)
begin
  if p_in_clk'event and p_in_clk='1' then

    --Формируем сигнал последнего данного в текущей транзакции записи ОЗУ
    if i_mem_dir=C_MEMWR_WRITE then
      if (i_mem_wr='1' or fsm_state_cs=S_MEM_WAIT_RQ_EN) and i_mem_trn_len=CONV_STD_LOGIC_VECTOR(1, i_mem_trn_len'length) then
        i_mem_term<='1';
      elsif i_mem_wr='1' and i_mem_trn_len=(i_mem_trn_len'range => '0') then
        i_mem_term<='0';
      end if;
    end if;

  end if;
end process;


--//----------------------------------------------
--//Автомат записи/чтения данных ОЗУ
--//----------------------------------------------
--Текущая операция выполнена
p_out_cfg_mem_done<=i_mem_done;

--Стробы записи/чтения ОЗУ
i_mem_rd<=i_mem_trn_work and p_in_mem.axir.dvalid and not p_in_usr_rxbuf_full  when i_mem_dir=C_MEMWR_READ  else '0';
i_mem_wr<=i_mem_trn_work and p_in_mem.axiw.wready and not p_in_usr_txbuf_empty when i_mem_dir=C_MEMWR_WRITE else '0';

--Логика работы автомата
process(p_in_rst,p_in_clk)
  variable update_addr: std_logic_vector(i_mem_trn_len'length + G_MEM_DWIDTH/32 downto 0);
begin
  if p_in_rst='1' then

    fsm_state_cs <= S_IDLE;
      update_addr:=(others=>'0');

    i_mem_adr<=(others=>'0');
    i_mem_dir<='0';
    i_mem_dlen_remain<=(others=>'0');
    i_mem_dlen_used<=(others=>'0');
    i_mem_trn_len<=(others=>'0');
    i_mem_trn_work<='0';
    i_mem_done<='0';

    i_axiw_avalid<='0';
    i_axir_avalid<='0';
    i_axi_trnlen<=(others=>'0');
    i_axiw_rready<='0';

    i_cfg_mem_dlen_rq<=(others=>'0');
    i_cfg_mem_trn_len<=(others=>'0');

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
          i_cfg_mem_dlen_rq<=p_in_cfg_mem_dlen_rq;
          i_cfg_mem_trn_len<=p_in_cfg_mem_trn_len;

          fsm_state_cs <= S_MEM_REMAIN_SIZE_CALC;
        end if;

      --------------------------------------
      --Расчитываем сколько данных запрашиваемых пользователем осталось в работе
      --------------------------------------
      when S_MEM_REMAIN_SIZE_CALC =>

        i_mem_dlen_remain <= EXT(i_cfg_mem_dlen_rq, i_mem_dlen_remain'length) - EXT(i_mem_dlen_used, i_mem_dlen_remain'length);
        fsm_state_cs <= S_MEM_TRN_LEN_CALC;

      --------------------------------------
      --Назначаем размер транзакции write/read ОЗУ
      --------------------------------------
      when S_MEM_TRN_LEN_CALC =>

        if i_mem_dlen_remain >= EXT(i_cfg_mem_trn_len, i_mem_dlen_remain'length) then
          i_mem_trn_len <= i_cfg_mem_trn_len;
          i_axi_trnlen <= i_cfg_mem_trn_len - 1;
        else
          i_mem_trn_len <= i_mem_dlen_remain(i_mem_trn_len'range);
          i_axi_trnlen <= i_mem_dlen_remain(i_axi_trnlen'range) - 1;
        end if;

        fsm_state_cs <= S_MEM_SET_RQ;

      --------------------------------------
      --Сигнализируем что адрес установлен
      --------------------------------------
      when S_MEM_SET_RQ =>

        if i_mem_dir=C_MEMWR_WRITE then
          i_axiw_avalid<='1';
          fsm_state_cs <= S_MEM_WAIT_RQ_EN;
        else
          i_axir_avalid<='1';
          fsm_state_cs <= S_MEM_WAIT_RQ_EN;
        end if;

      --------------------------------------
      --Ждем подтверждения принятия адреса
      --------------------------------------
      when S_MEM_WAIT_RQ_EN =>

        if i_mem_dir=C_MEMWR_WRITE then
          if p_in_mem.axiw.aready='1' then
            i_axiw_avalid<='0';
            fsm_state_cs <= S_MEM_TRN_START;
          end if;
        else
          if p_in_mem.axir.aready='1' then
            i_axir_avalid<='0';
            fsm_state_cs <= S_MEM_TRN_START;
          end if;
        end if;

      --------------------------------------
      --Ждем готовности к приему данных (при C_MEMWR_WRITE)
      --------------------------------------
      when S_MEM_TRN_START =>

        if i_mem_dir=C_MEMWR_WRITE then
          if p_in_mem.axiw.wready='1' then
            i_mem_trn_len<=i_mem_trn_len-1;
            i_mem_trn_work<='1';
            fsm_state_cs <= S_MEM_TRN;
          end if;
        else
            i_mem_trn_len<=i_mem_trn_len-1;
            i_mem_trn_work<='1';
            fsm_state_cs <= S_MEM_TRN;
        end if;

      ------------------------------------------------
      --Запись/Чтение данных ОЗУ
      ------------------------------------------------
      when S_MEM_TRN =>

        if i_mem_wr='1' or i_mem_rd='1' then
          i_mem_dlen_used<=i_mem_dlen_used+1;

          if i_mem_trn_len=(i_mem_trn_len'range => '0') then
            i_mem_trn_len<=(others=>'0');
            i_mem_trn_work<='0';
            if i_mem_dir=C_MEMWR_WRITE then
              i_axiw_rready<='1';
            end if;
            fsm_state_cs <= S_MEM_TRN_END;
          else
            i_mem_trn_len<=i_mem_trn_len-1;
          end if;
        end if;

      ------------------------------------------------
      --Анализ завершения транзакции write/read ОЗУ
      ------------------------------------------------
      when S_MEM_TRN_END =>

        --Вычисляем значение для обнавления адреса ОЗУ
        update_addr(G_MEM_DWIDTH/32 downto 0):=(others=>'0');
        update_addr(update_addr'high downto G_MEM_DWIDTH/32 + 1):=i_cfg_mem_trn_len;

        if (p_in_mem.axiw.rvalid='1' and i_mem_dir=C_MEMWR_WRITE) or i_mem_dir=C_MEMWR_READ then
          i_axiw_rready<='0';

          if i_cfg_mem_dlen_rq=i_mem_dlen_used then
            fsm_state_cs <= S_EXIT;
          else
            --Вычисляем следующий адрес ОЗУ
            i_mem_adr<=i_mem_adr + EXT(update_addr, i_mem_adr'length);

            --Переход к следующей транзакции write/read ОЗУ
            fsm_state_cs <= S_MEM_REMAIN_SIZE_CALC;
          end if;
        end if;

      ------------------------------------------------
      --Переходим к выполнению следующей операции
      ------------------------------------------------
      when S_EXIT =>

        i_mem_dlen_used<=(others=>'0');
        i_mem_done<='1';
        fsm_state_cs <= S_IDLE;

    end case;
  end if;
end process;

--END MAIN
end behavioral;

