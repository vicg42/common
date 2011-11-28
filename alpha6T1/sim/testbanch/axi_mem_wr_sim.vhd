-------------------------------------------------------------------------
-- Company     : Linkos
-- Engineer    : Golovachenko Victor
--
-- Create Date : 14.10.2011 10:02:57
-- Module Name : axi_memory_ctrl_ch_wr
--
-- Назначение/Описание :
--  Запись/Чтение данных ОЗУ
--
-- Revision:
-- Revision 0.01 - File Created
--
-------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

use ieee.std_logic_textio.all;
use std.textio.all;

library unisim;
use unisim.vcomponents.all;

library work;
use work.vicg_common_pkg.all;
use work.mem_wr_pkg.all;

entity axi_memory_ctrl_ch_test is
generic(
G_ACT        : integer:=0;
G_TADDR      : integer:=1;
G_TDATA      : integer:=1;
G_RQ_DATA    : integer:=1;
G_TRNLEN_WR  : integer:=1;
G_TRNLEN_RD  : integer:=1;
G_DWIDTH     : integer:=32
);
port
(
-------------------------------
-- Конфигурирование
-------------------------------
p_out_cfg_mem_adr     : out   std_logic_vector(31 downto 0);--//Адрес ОЗУ (в BYTE)
p_out_cfg_mem_trn_len : out   std_logic_vector(15 downto 0);--//Размер одиночной MEM_TRN (в DWORD)
p_out_cfg_mem_dlen_rq : out   std_logic_vector(15 downto 0);--//Размер запрашиваемых данных записи/чтения (в DWORD)
p_out_cfg_mem_wr      : out   std_logic;                    --//Тип операции (1/0 - запись/чтение)
p_out_cfg_mem_start   : out   std_logic;                    --//Строб: Пуск операции
p_in_cfg_mem_done     : in    std_logic;                    --//Строб: Операции завершена

p_in_mem_init_done    : in    std_logic;

-------------------------------
-- Связь с пользовательскими буферами
-------------------------------
--//usr_buf->mem
p_out_usr_txbuf_din   : out   std_logic_vector(G_DWIDTH-1 downto 0);
p_out_usr_txbuf_wr    : out   std_logic;
p_in_usr_txbuf_full   : in    std_logic;

--//usr_buf<-mem
p_in_usr_rxbuf_dout  : in   std_logic_vector(G_DWIDTH-1 downto 0);
p_out_usr_rxbuf_rd   : out  std_logic;
p_in_usr_rxbuf_empty : in   std_logic;

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
end axi_memory_ctrl_ch_test;

architecture behavioral of axi_memory_ctrl_ch_test is

signal i_cfg_mem_adr       : integer:=0;
signal i_cfg_mem_trn_len   : integer:=0;
signal i_cfg_mem_dlen_rq   : integer:=0;
signal i_cfg_mem_wr        : std_logic;
signal i_cfg_mem_start     : std_logic;

type TSimBufData is array (0 to 1024) of std_logic_vector(31 downto 0);
signal i_txbuf             : TSimBufData;
signal i_rxbuf             : TSimBufData;

signal i_usr_rxbuf_empty   : std_logic:='1';
signal i_usr_rxbuf_rd      : std_logic;

signal i_txbuf_dout        : std_logic_vector(p_out_usr_txbuf_din'range):=CONV_STD_LOGIC_VECTOR(16#01#, p_out_usr_txbuf_din'length);


--MAIN
begin

--//----------------------------------
--//Технологические сигналы
--//----------------------------------
p_out_tst<=(others=>'0');


--//---------------------------------------------------
--//TXBUF
--//---------------------------------------------------
process
  variable dcnt: integer:=0;
  variable trncnt: integer:=0;
begin
  trncnt:=0;
  for i in 0 to i_txbuf'high loop
    i_txbuf(i)<=CONV_STD_LOGIC_VECTOR(G_TDATA+i, i_txbuf(i)'length);--счетчик
  end loop;
  dcnt:=0;
  p_out_usr_txbuf_din<=(others=>'0');
  p_out_usr_txbuf_wr<='0';

--  wait until p_in_clk'event and p_in_clk='1' and p_in_mem_init_done='1' and p_in_rst='0';
--  p_out_usr_txbuf_din<=i_txbuf(0);
--  dcnt:=1;
  dcnt:=0;

  while true loop

      wait until p_in_clk'event and p_in_clk='1' and i_cfg_mem_start='1' and i_cfg_mem_wr=C_MEMWR_WRITE;
      trncnt:=i_cfg_mem_dlen_rq;
      wait until p_in_clk'event and p_in_clk='1';

      while trncnt/=0 loop

        wait until p_in_clk'event and p_in_clk='1';
            if p_in_usr_txbuf_full='0' then
              p_out_usr_txbuf_din<=i_txbuf(dcnt);
              p_out_usr_txbuf_wr<='1';
              trncnt:=trncnt - 1;
              if dcnt=i_txbuf'length-1 then
                dcnt:=1;
              else
                dcnt:=dcnt + 1;
              end if;
            else
              p_out_usr_txbuf_wr<='0';
            end if;
      end loop;--//trncnt/=CONV_STD_LOGIC_VECTOR(0, trncnt'length) loop

      wait until p_in_clk'event and p_in_clk='1';
      p_out_usr_txbuf_wr<='0';
  end loop;

end process;


--//---------------------------------------------------
--//RXBUF
--//---------------------------------------------------
process(p_in_rst,p_in_clk)
  variable dcnt: integer:=0;
begin
  if p_in_rst='1' then
    for i in 0 to i_rxbuf'high loop
      i_rxbuf(i)<=(others=>'0');
    end loop;
    dcnt:=0;
  elsif p_in_clk'event and p_in_clk='1' then

    if i_usr_rxbuf_rd='1' then
      i_rxbuf(dcnt)<=p_in_usr_rxbuf_dout;
      dcnt:=dcnt+1;
    end if;
  end if;
end process;

i_usr_rxbuf_rd<=not p_in_usr_rxbuf_empty;
p_out_usr_rxbuf_rd<=i_usr_rxbuf_rd;

--//---------------------------------------------------
--//Логика работы
--//---------------------------------------------------
p_out_cfg_mem_adr     <=CONV_STD_LOGIC_VECTOR(i_cfg_mem_adr    , p_out_cfg_mem_adr'length);
p_out_cfg_mem_trn_len <=CONV_STD_LOGIC_VECTOR(i_cfg_mem_trn_len, p_out_cfg_mem_trn_len'length);
p_out_cfg_mem_dlen_rq <=CONV_STD_LOGIC_VECTOR(i_cfg_mem_dlen_rq, p_out_cfg_mem_dlen_rq'length);
p_out_cfg_mem_wr      <=i_cfg_mem_wr   ;
p_out_cfg_mem_start   <=i_cfg_mem_start;

process
  variable string_value : std_logic_vector(3 downto 0);
  variable GUI_line     : LINE;--Строка для вывода в ModelSim
begin

  --//---------------------------------------------------
  --/Инициализация
  --//---------------------------------------------------
  i_cfg_mem_adr     <=0;
  i_cfg_mem_trn_len <=0;
  i_cfg_mem_dlen_rq <=0;
  i_cfg_mem_wr      <='0';
  i_cfg_mem_start   <='0';

  wait until p_in_clk'event and p_in_clk='1' and p_in_mem_init_done='1' and p_in_rst='0';
  wait for 200 ns;


--  for i in 8 downto 1 loop

  if (G_ACT=0) or (G_ACT=2) then
    --//---------------------------------------------------
    --//WRITE
    --//---------------------------------------------------
    wait until p_in_clk'event and p_in_clk='1';
    i_cfg_mem_adr     <=G_TADDR;    --16#00#;
    i_cfg_mem_dlen_rq <=G_RQ_DATA;  --16#08#;
    i_cfg_mem_trn_len <=G_TRNLEN_WR;--16#01#;
    i_cfg_mem_wr      <=C_MEMWR_WRITE;

    wait until p_in_clk'event and p_in_clk='1';
    i_cfg_mem_start   <='1';
    wait until p_in_clk'event and p_in_clk='1';
    i_cfg_mem_start   <='0';

    wait for 1 us;

    wait until p_in_clk'event and p_in_clk='1' and p_in_cfg_mem_done='1';
    wait for 200 ns;
  end if;

  if (G_ACT=1) or (G_ACT=2) then
    --//---------------------------------------------------
    --//READ
    --//---------------------------------------------------
    wait until p_in_clk'event and p_in_clk='1';
    i_cfg_mem_adr     <=G_TADDR;    --16#00#;
    i_cfg_mem_dlen_rq <=G_RQ_DATA;  --16#08#;
    i_cfg_mem_trn_len <=G_TRNLEN_RD;--16#01#;
    i_cfg_mem_wr      <=C_MEMWR_READ;

    wait until p_in_clk'event and p_in_clk='1';
    i_cfg_mem_start   <='1';
    wait until p_in_clk'event and p_in_clk='1';
    i_cfg_mem_start   <='0';

    wait for 1 us;

    wait until p_in_clk'event and p_in_clk='1' and p_in_cfg_mem_done='1';
    wait for 200 ns;
    end if;
--  end loop;

--  --//---------------------------------------------------
--  --//COMPARE
--  --//---------------------------------------------------
--  wait for 1 us;
--  for i in 0 to i_cfg_mem_dlen_rq-1 loop
--    write(GUI_line,string'(" i_txbuf/i_rxbuf("));write(GUI_line,i);write(GUI_line,string'("): 0x"));
--    for y in 1 to 8 loop
--    string_value:=i_txbuf(i)((32-(4*(y-1)))-1 downto (32-(4*y)));
--    write(GUI_line,Int2StrHEX(CONV_INTEGER(string_value)));
--    end loop;
--    write(GUI_line,string'("/0x"));
--
--    for y in 1 to 8 loop
--    string_value:=i_rxbuf(i)((32-(4*(y-1)))-1 downto (32-(4*y)));
--    write(GUI_line,Int2StrHEX(CONV_INTEGER(string_value)));
--    end loop;
--    writeline(output, GUI_line);
--
--    if i_txbuf(i)/=i_rxbuf(i) then
--      --//Завершаем модеоирование.
--      write(GUI_line,string'("COMPARE DATA:ERROR - i_txbuf("));write(GUI_line,i);write(GUI_line,string'(")/= "));
--      write(GUI_line,string'("i_rxbuf("));write(GUI_line,i);write(GUI_line,string'(")"));
--      writeline(output, GUI_line);
--      p_SIM_STOP("Simulation of STOP: COMPARE DATA:ERROR i_txbuf/=i_rxbuf");
--    end if;
--  end loop;
--
--  write(GUI_line,string'("COMPARE DATA: i_ram_txbuf/i_ram_rxbuf - OK.")); writeline(output, GUI_line);

  wait;
end process;


--END MAIN
end behavioral;

