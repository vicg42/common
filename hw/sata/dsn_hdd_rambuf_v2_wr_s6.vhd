-------------------------------------------------------------------------
-- Company     : Linkos
-- Engineer    : Golovachenko Victor
--
-- Create Date : 09.02.2012 10:53:25
-- Module Name : hdd_rambuf_wr
--
-- Назначение/Описание :
--  Запись/Чтение данных ОЗУ.
--  Модуль реализует кольцевой буфер.
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
use work.vicg_common_pkg.all;
use work.mem_wr_pkg.all;

entity hdd_rambuf_wr is
generic(
G_RAMBUF_SIZE    : integer:=23;--//(в BYTE). Определяется как 2 в степени G_RAMBUF_SIZE
G_MEM_BANK_M_BIT : integer:=29;--//биты(мл. ст.) определяющие банк ОЗУ. Относится в порту p_in_cfg_mem_adr
G_MEM_BANK_L_BIT : integer:=28;
G_MEM_AWIDTH     : integer:=32;
G_MEM_DWIDTH     : integer:=32
);
port(
-------------------------------
--Конфигурирование
-------------------------------
p_in_cfg_mem_adr     : in    std_logic_vector(31 downto 0);--//Адрес ОЗУ (в BYTE)
p_in_cfg_mem_trn_len : in    std_logic_vector(15 downto 0);--//Размер одиночной MEM_TRN
p_in_cfg_mem_dlen_rq : in    std_logic_vector(15 downto 0);--//Размер запрашиваемых данных записи/чтения
p_in_cfg_mem_wr      : in    std_logic;                    --//Тип операции
p_in_cfg_mem_start   : in    std_logic;                    --//START
p_out_cfg_mem_done   : out   std_logic;                    --//Строб: Операции завершена
p_in_cfg_mem_stop    : in    std_logic;                    --//STOP
p_in_cfg_idle        : in    std_logic;                    --//IDLE

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
end hdd_rambuf_wr;

architecture behavioral of hdd_rambuf_wr is

-- Small delay for simulation purposes.
constant dly : time := 1 ps;

type fsm_state is (
S_IDLE,
S_MEM_NXT_START,
S_MEM_TRN_START,
S_MEM_TRN,
S_MEM_TRN_END,
S_MEM_WAIT
);
signal fsm_state_cs        : fsm_state;

signal i_mem_adr           : std_logic_vector(G_MEM_BANK_L_BIT-1 downto 0);
signal i_mem_adr_update    : std_logic_vector(G_MEM_BANK_L_BIT-1 downto 0);
signal i_mem_adr_offset    : std_logic_vector(G_MEM_BANK_L_BIT-1 downto 0);
signal i_mem_adr_out       : std_logic_vector(G_MEM_BANK_L_BIT-1 downto 0);
signal i_mem_dir           : std_logic;
signal i_mem_wr            : std_logic;
signal i_mem_rd            : std_logic;
signal i_mem_trn_work      : std_logic;
signal i_mem_trn_len       : std_logic_vector(p_out_mem.cmd_bl'length downto 0);
signal i_mem_trn_dcnt      : std_logic_vector(p_out_mem.cmd_bl'length downto 0);
signal i_mem_done          : std_logic;
signal i_mem_cmden         : std_logic;
signal i_mem_cmdwr         : std_logic;
signal i_mem_cmdbl         : std_logic_vector(p_in_cfg_mem_trn_len'range);

signal tst_fsm_cs          : std_logic_vector(2 downto 0);


--MAIN
begin

--//----------------------------------
--//Технологические сигналы
--//----------------------------------
--p_out_tst<=(others=>'0');
p_out_tst(0)<=p_in_cfg_mem_start;
p_out_tst(1)<=i_mem_done;
p_out_tst(4 downto 2)<=tst_fsm_cs;
p_out_tst(5)<=i_mem_cmden;
p_out_tst(6)<=i_mem_trn_work;
p_out_tst(7)<='1' when fsm_state_cs=S_IDLE else '0';
p_out_tst(15 downto 8)<=(others=>'0');
p_out_tst(21 downto 16)<=i_mem_trn_dcnt(5 downto 0);
p_out_tst(31 downto 22)<=(others=>'0');

tst_fsm_cs<=CONV_STD_LOGIC_VECTOR(16#01#,tst_fsm_cs'length) when fsm_state_cs=S_MEM_TRN_START         else
            CONV_STD_LOGIC_VECTOR(16#02#,tst_fsm_cs'length) when fsm_state_cs=S_MEM_TRN               else
            CONV_STD_LOGIC_VECTOR(16#03#,tst_fsm_cs'length) when fsm_state_cs=S_MEM_TRN_END           else
            CONV_STD_LOGIC_VECTOR(16#04#,tst_fsm_cs'length) when fsm_state_cs=S_MEM_WAIT              else
            CONV_STD_LOGIC_VECTOR(16#05#,tst_fsm_cs'length) when fsm_state_cs=S_MEM_NXT_START         else
            CONV_STD_LOGIC_VECTOR(16#00#,tst_fsm_cs'length); --//when fsm_state_cs=S_IDLE               else


--//-----------------------------
--//Связь с пользовательскими буферами
--//-----------------------------
p_out_usr_txbuf_rd <=i_mem_wr after dly;

p_out_usr_rxbuf_wd <=i_mem_rd;
p_out_usr_rxbuf_din<=p_in_mem.rxd(p_out_usr_rxbuf_din'range);


--//----------------------------------------------
--//Связь с контроллером памяти
--//----------------------------------------------
p_out_mem.clk   <=p_in_clk;
p_out_mem.req   <='0';
p_out_mem.req_type<=i_mem_dir;
p_out_mem.bank  <=(others=>'0');
p_out_mem.cmd_i <=C_MEM_CMD_WR_WITH_PRECHARGE when i_mem_dir=C_MEMWR_WRITE else C_MEM_CMD_RD_WITH_PRECHARGE;
p_out_mem.cmd_bl<=i_mem_cmdbl(p_out_mem.cmd_bl'range);--Размер одинойчной транзакции: MIN/MAX - 0/63 (соответствует 1 и 64)
p_out_mem.cmd_wr<=i_mem_cmdwr;
p_out_mem.txd_wr<=i_mem_wr;
p_out_mem.rxd_rd<=i_mem_rd;
p_out_mem.txd_be<=(others=>'0');
p_out_mem.adr   <=EXT(i_mem_adr_out, p_out_mem.adr'length);
p_out_mem.txd   <=EXT(p_in_usr_txbuf_dout, p_out_mem.txd'length);

i_mem_adr_out<=i_mem_adr + i_mem_adr_offset;

--//----------------------------------------------
--//Автомат записи/чтения данных ОЗУ
--//----------------------------------------------
--Текущая операция выполнена
p_out_cfg_mem_done<=i_mem_done;

--Стробы записи/чтения ОЗУ
i_mem_rd<=i_mem_trn_work and not p_in_mem.rxbuf_empty and not p_in_usr_rxbuf_full when i_mem_dir=C_MEMWR_READ else '0';
i_mem_wr<=i_mem_trn_work and not p_in_mem.txbuf_full and not p_in_usr_txbuf_empty when i_mem_dir=C_MEMWR_WRITE else '0';
i_mem_cmdwr<=(i_mem_cmden and not p_in_mem.cmdbuf_full);

process(p_in_rst,p_in_clk)
begin
  if p_in_rst='1' then
    i_mem_cmden<='0';
  elsif p_in_clk'event and p_in_clk='1' then
    if i_mem_cmden='0' then
      if i_mem_dir=C_MEMWR_WRITE then
        if fsm_state_cs=S_MEM_TRN then
          if i_mem_wr='1' and i_mem_trn_dcnt=i_mem_trn_len - 1  then
            i_mem_cmden<='1';
          end if;
        end if;
      else
        if fsm_state_cs=S_MEM_TRN_START then
          i_mem_cmden<='1';
        end if;
      end if;
    else
      if i_mem_cmdwr='1' then
        i_mem_cmden<='0';
      end if;
    end if;
  end if;
end process;

gen_memd8 : if G_MEM_DWIDTH=8 generate
i_mem_adr_update<=(CONV_STD_LOGIC_VECTOR(0, (i_mem_adr'length - i_mem_trn_len'length)) & i_mem_trn_len);
end generate gen_memd8;

gen_memd_more8 : if G_MEM_DWIDTH>8 generate
i_mem_adr_update<=(CONV_STD_LOGIC_VECTOR(0, (i_mem_adr'length - i_mem_trn_len'length - log2(G_MEM_DWIDTH/8))) & i_mem_trn_len & CONV_STD_LOGIC_VECTOR(0,log2(G_MEM_DWIDTH/8)) );
end generate gen_memd_more8;


--Логика работы автомата
process(p_in_rst,p_in_clk)
begin
  if p_in_rst='1' then

    fsm_state_cs <= S_IDLE;
    i_mem_adr_offset<=(others=>'0');
    i_mem_adr<=(others=>'0');
    i_mem_dir<='0';
    i_mem_trn_work<='0';
    i_mem_done<='0';

    i_mem_trn_len<=(others=>'0');
    i_mem_cmdbl<=(others=>'0');

  elsif p_in_clk'event and p_in_clk='1' then

    case fsm_state_cs is

      when S_IDLE =>

      --------------------------------------
      --Ждем сигнала запуска операции
      --------------------------------------
        if p_in_cfg_mem_start='1' then
          i_mem_adr_offset<=p_in_cfg_mem_adr(G_MEM_BANK_L_BIT-1 downto 0);
          i_mem_adr<=(others=>'0');
          i_mem_dir<=p_in_cfg_mem_wr;
          i_mem_trn_len<=p_in_cfg_mem_trn_len(i_mem_trn_len'range); --ВАЖНО: из предоставляемых 16 разрядов
                                                                    --беру только диапозон p_out_mem.cmd_bl'range
          i_mem_cmdbl <= p_in_cfg_mem_trn_len - 1;
          fsm_state_cs <= S_MEM_TRN_START;
        end if;

      --------------------------------------
      --Ждем сигнала запуска операции или перевода в исходное состояние
      --------------------------------------
      when S_MEM_NXT_START =>

        if i_mem_adr(G_RAMBUF_SIZE)='1' then
          i_mem_adr<=(others=>'0');
        end if;

        i_mem_done<='0';

        if p_in_cfg_idle='1' then
          if p_in_mem.cmdbuf_empty='1' and p_in_mem.rxbuf_empty='1' and p_in_mem.txbuf_empty='1' then
            fsm_state_cs <= S_IDLE;
          end if;
        elsif p_in_cfg_mem_start='1' then
          fsm_state_cs <= S_MEM_TRN_START;
        end if;

      ------------------------------------------------
      --
      ------------------------------------------------
      when S_MEM_TRN_START =>

        i_mem_trn_work<='1';
        fsm_state_cs <= S_MEM_TRN;

      ------------------------------------------------
      --Запись/Чтение данных ОЗУ
      ------------------------------------------------
      when S_MEM_TRN =>

        if i_mem_adr(G_RAMBUF_SIZE)='1' then
          i_mem_adr<=(others=>'0');
        end if;

        i_mem_done<='0';
        if i_mem_wr='1' or i_mem_rd='1' then
          if i_mem_trn_dcnt=i_mem_trn_len - 1 then
            i_mem_trn_work<='0';
            fsm_state_cs <= S_MEM_TRN_END;
          end if;
        end if;

      ------------------------------------------------
      --Анализ завершения текущей транзакции write/read ОЗУ
      ------------------------------------------------
      when S_MEM_TRN_END =>

        if (i_mem_cmdwr='1' and i_mem_dir=C_MEMWR_WRITE) or i_mem_dir=C_MEMWR_READ then
          i_mem_done<='1';

          if i_mem_adr(G_RAMBUF_SIZE)='1' then
            i_mem_adr<=(others=>'0');
          else
            i_mem_adr<=i_mem_adr + i_mem_adr_update;
          end if;

          if p_in_cfg_mem_stop='1' then
            fsm_state_cs <= S_MEM_NXT_START;
          else
            if i_mem_dir=C_MEMWR_READ then
              fsm_state_cs <= S_MEM_WAIT;
            else
              i_mem_trn_work<='1';
              fsm_state_cs <= S_MEM_TRN;
            end if;
          end if;
        end if;

      ------------------------------------------------
      --
      ------------------------------------------------
      when S_MEM_WAIT =>

        if i_mem_adr(G_RAMBUF_SIZE)='1' then
          i_mem_adr<=(others=>'0');
        end if;

        i_mem_done<='0';

        if i_mem_done='0' then
          if p_in_cfg_mem_stop='1' then
            fsm_state_cs <= S_MEM_NXT_START;

          elsif p_in_usr_rxbuf_full='0' then
            i_mem_trn_work<='1';
            fsm_state_cs <= S_MEM_TRN_START;
          end if;
        end if;

    end case;
  end if;
end process;

process(p_in_rst,p_in_clk)
begin
  if p_in_rst='1' then
    i_mem_trn_dcnt<=(others=>'0');
  elsif p_in_clk'event and p_in_clk='1' then
    if i_mem_trn_work='0' then
      i_mem_trn_dcnt<=(others=>'0');
    else
      if i_mem_wr='1' or i_mem_rd='1' then
        i_mem_trn_dcnt<=i_mem_trn_dcnt + 1;
      end if;
    end if;
  end if;
end process;


--END MAIN
end behavioral;
