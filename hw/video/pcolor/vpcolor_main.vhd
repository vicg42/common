-------------------------------------------------------------------------
-- Company     : Linkos
-- Engineer    : Golovachenko Victor
--
-- Create Date : 2010.07
-- Module Name : vpcolor_main
--
-- Назначение/Описание :
--
--  Модуль реализует перобразование черно-белого изображения в цветное.
--
--  Upstream Port(Вх. данные)
--  Downstream Port(Вых. данные)
--
--  Если p_in_cfg_bypass='0', Формат выходных данных
--  (7..0)  =B
--  (15..8) =G
--  (23..16)=R
--  (31..24)=0xFF (прозрачность - альфа канал)
--
--  Если p_in_cfg_bypass='1', на выходной порт подаетутся данные с входного порта.
--
--  Натройка работы модуля:
--  1. Выбрать режим работы модуля. Порт p_in_cfg_bypass - 0/1:
--     Upstream Port -> Downstream Port Обрабатывать/Не обрабатывать
--
-- Revision:
-- Revision 0.01 - File Created
-- Revision 0.02 - add 10.02.2011 15:42:10
--                 Поменял порядок цветовых каналов в выходных данных, потому что было неправильно
--                 Теперь:(7..0)  =B                                а раньше было:(7..0)  =R
--                        (15..8) =G                                              (15..8) =G
--                        (23..16)=R                                              (23..16)=B
--                        (31..24)=0xFF (прозрачность - альфа канал)              (31..24)=0xFF (прозрачность - альфа канал)
-------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_misc.all;
use ieee.std_logic_unsigned.all;

library unisim;
use unisim.vcomponents.all;

--library work;
--use work.prj_def.all;

entity vpcolor_main is
port
(
-------------------------------
-- Управление
-------------------------------
p_in_cfg_bypass     : in    std_logic;                    --//0/1 - Upstream Port -> Downstream Port Обрабатывать/Не обрабатывать

p_in_cfg_coeram_num : in    std_logic_vector(1 downto 0);
p_in_cfg_acoe       : in    std_logic_vector(6 downto 0);
p_in_cfg_acoe_ld    : in    std_logic;
p_in_cfg_dcoe       : in    std_logic_vector(15 downto 0);
p_out_cfg_dcoe      : out   std_logic_vector(15 downto 0);
p_in_cfg_dcoe_wr    : in    std_logic;
p_in_cfg_dcoe_rd    : in    std_logic;
p_in_cfg_coe_wrclk  : in    std_logic;

--//--------------------------
--//Upstream Port
--//--------------------------
--p_in_upp_clk        : in    std_logic;
p_in_upp_data       : in    std_logic_vector(31 downto 0);
p_in_upp_wd         : in    std_logic;                    --//Запись данных в модуль vpcolor_main.vhd
p_out_upp_rdy_n     : out   std_logic;                    --//0 - Модуль vpcolor_main.vhd готов к приему данных

--//--------------------------
--//Downstream Port
--//--------------------------
--p_in_dwnp_clk       : in    std_logic;
p_out_dwnp_data     : out   std_logic_vector(31 downto 0);
p_out_dwnp_wd       : out   std_logic;                    --//Запись данных в приемник
p_in_dwnp_rdy_n     : in    std_logic;                    --//0 - порт приемника готов к приему даннвх

-------------------------------
--Технологический
-------------------------------
p_in_tst            : in    std_logic_vector(31 downto 0);
p_out_tst           : out   std_logic_vector(31 downto 0);

-------------------------------
--System
-------------------------------
p_in_clk            : in    std_logic;
p_in_rst            : in    std_logic
);
end vpcolor_main;

architecture behavioral of vpcolor_main is

constant dly : time := 1 ps;

component vpcolor_rbram
port (
addra: in  std_logic_vector(6 downto 0);
dina : in  std_logic_vector(15 downto 0);
douta: out std_logic_vector(15 downto 0);
ena  : in  std_logic;
wea  : in  std_logic_vector(0 downto 0);
clka : in  std_logic;
rsta : in  std_logic;

addrb: in  std_logic_vector(7 downto 0);
dinb : in  std_logic_vector(7 downto 0);
doutb: out std_logic_vector(7 downto 0);
enb  : in  std_logic;
web  : in  std_logic_vector(0 downto 0);
clkb : in  std_logic;
rstb : in  std_logic
);
end component;

component vpcolor_gbram
port (
addra: in  std_logic_vector(6 downto 0);
dina : in  std_logic_vector(15 downto 0);
douta: out std_logic_vector(15 downto 0);
ena  : in  std_logic;
wea  : in  std_logic_vector(0 downto 0);
clka : in  std_logic;
rsta : in  std_logic;

addrb: in  std_logic_vector(7 downto 0);
dinb : in  std_logic_vector(7 downto 0);
doutb: out std_logic_vector(7 downto 0);
enb  : in  std_logic;
web  : in  std_logic_vector(0 downto 0);
clkb : in  std_logic;
rstb : in  std_logic
);
end component;

component vpcolor_bbram
port (
addra: in  std_logic_vector(6 downto 0);
dina : in  std_logic_vector(15 downto 0);
douta: out std_logic_vector(15 downto 0);
ena  : in  std_logic;
wea  : in  std_logic_vector(0 downto 0);
clka : in  std_logic;
rsta : in  std_logic;

addrb: in  std_logic_vector(7 downto 0);
dinb : in  std_logic_vector(7 downto 0);
doutb: out std_logic_vector(7 downto 0);
enb  : in  std_logic;
web  : in  std_logic_vector(0 downto 0);
clkb : in  std_logic;
rstb : in  std_logic
);
end component;

component vpcolor_fifo
port (
din        : in  std_logic_vector(31 downto 0);
wr_en      : in  std_logic;

dout       : out std_logic_vector(31 downto 0);
rd_en      : in  std_logic;

empty      : out std_logic;
full       : out std_logic;
almost_full: out std_logic;

clk        : in  std_logic;
rst        : in  std_logic
);
end component;

signal i_dwnp_rdy_n                      : std_logic;

signal i_fifo_empty                      : std_logic;
signal i_fifo_dout                       : std_logic_vector(31 downto 0);
signal i_fifo_rd                         : std_logic;
signal i_fsm_fifo_rd                     : std_logic;
signal i_fifo_read_en_n                  : std_logic;

type fsm_state is
(
S_READ_INDATA,
S_CONVERTION
);
signal fsm_state_cs: fsm_state;

type TArrayInDW is array (3 downto 0) of std_logic_vector(7 downto 0);
signal sr_indw                           : TArrayInDW;

signal i_byte_cnt                        : std_logic_vector(1 downto 0);

signal i_wr_rbuf                         : std_logic_vector(0 downto 0);
signal i_wr_gbuf                         : std_logic_vector(0 downto 0);
signal i_wr_bbuf                         : std_logic_vector(0 downto 0);
signal i_result_out                      : std_logic_vector(31 downto 0);
signal i_result_out_en                   : std_logic;
signal i_result_out_en_dly               : std_logic;
signal i_bram_rd_en                      : std_logic;

signal i_coebuf_awrite                   : std_logic_vector(6 downto 0);
signal i_rcoe_dout                       : std_logic_vector(15 downto 0);
signal i_gcoe_dout                       : std_logic_vector(15 downto 0);
signal i_bcoe_dout                       : std_logic_vector(15 downto 0);




--MAIN
begin

--//----------------------------------
--//Технологические сигналы
--//----------------------------------
--process(p_in_rst,p_in_clk)
--begin
--  if p_in_rst='1' then
--    p_out_tst(31 downto 0)<=(others=>'0');
--
--  elsif p_in_clk'event and p_in_clk='1' then
--
--    p_out_tst(0)<=OR_reduce(i_zoom_work_done_dly) or OR_reduce(i_lbufs_dout(0)) or i_lbufs_dout_en;
--
--  end if;
--end process;
p_out_tst(31 downto 0)<=(others=>'0');


--//-----------------------------
--//Входной буфер
--//-----------------------------
m_fifo_in : vpcolor_fifo
port map
(
din         => p_in_upp_data,
wr_en       => p_in_upp_wd,
--wr_clk      => p_in_upp_clk,

dout        => i_fifo_dout,
rd_en       => i_fifo_rd,
--rd_clk      => p_in_dwnp_clk,

empty       => i_fifo_empty,
full        => open,
almost_full => p_out_upp_rdy_n,

clk         => p_in_clk,
rst         => p_in_rst
);

i_fifo_rd <=i_fsm_fifo_rd when p_in_cfg_bypass='0' else not i_fifo_empty and not p_in_dwnp_rdy_n;


--//-----------------------------
--//Вывод результата
--//-----------------------------
p_out_dwnp_data <=i_result_out                                when p_in_cfg_bypass='0' else i_fifo_dout;
p_out_dwnp_wd   <=i_result_out_en_dly and not p_in_dwnp_rdy_n when p_in_cfg_bypass='0' else i_fifo_rd;



--//-----------------------------
--//Инициализация
--//-----------------------------

i_dwnp_rdy_n<=p_in_dwnp_rdy_n or p_in_cfg_bypass;
i_bram_rd_en<=not i_dwnp_rdy_n and i_result_out_en;

--//------------------------------------
--//Автомат:
--//Управление чтением входного буфера/ записью/чтением буферов строк/ чтением коэфициентов
--//------------------------------------
i_fsm_fifo_rd<=not i_fifo_empty and not i_fifo_read_en_n and not i_dwnp_rdy_n;

--//Логика работы автомата
process(p_in_rst,p_in_clk)
begin
  if p_in_rst='1' then

    fsm_state_cs <= S_READ_INDATA;

    i_fifo_read_en_n<='0';
    i_result_out_en<='0';
    for i in 0 to 3 loop
      sr_indw(i)<=(others=>'0');
    end loop;
    i_byte_cnt<=(others=>'0');

  elsif p_in_clk'event and p_in_clk='1' then
  if i_dwnp_rdy_n='0' then

    case fsm_state_cs is

      --//------------------------------------
      --//Запись данных строки в буфер
      --//------------------------------------
      when S_READ_INDATA =>
        i_result_out_en<='0';

        if i_fifo_empty='0' then
          if i_fifo_read_en_n='0' then
              i_fifo_read_en_n<='1';--//ЗАПРЕЩАЕМ чтение данных.
              i_result_out_en<='1';

              --//Готовим данные для сдвигового регистра
              for i in 0 to 3 loop
                sr_indw(i)<=i_fifo_dout(8*(i+1)-1 downto 8*i);
              end loop;

              i_byte_cnt<=CONV_STD_LOGIC_VECTOR(10#3#, i_byte_cnt'length);
              fsm_state_cs <= S_CONVERTION;
           end if;
        end if;

      --//------------------------------------
      --//Обработка данных записаных в буфер
      --//------------------------------------
      when S_CONVERTION =>

        if i_byte_cnt=(i_byte_cnt'range=>'0') then
          i_fifo_read_en_n<='0';--//РАЗРЕШАЕМ чтение данных.
          i_result_out_en<='0';
          fsm_state_cs <= S_READ_INDATA;
        else
          i_byte_cnt<=i_byte_cnt-1;
        end if;

        --//Сдвигавй регистр входных данных
        sr_indw<="00000000"&sr_indw(3 downto 1);

    end case;
  end if;--  //if i_dwnp_rdy_n='0' then
  end if;
end process;

process(p_in_rst,p_in_clk)
begin
  if p_in_rst='1' then
    i_result_out_en_dly<='0';
  elsif p_in_clk'event and p_in_clk='1' then
  if i_dwnp_rdy_n='0' then
      i_result_out_en_dly<=i_result_out_en;
  end if;--  //if i_dwnp_rdy_n='0' then
  end if;
end process;


--//------------------------------------------------------
--//RAM
--//------------------------------------------------------
--//Запись данных в буфера строк
process(p_in_rst,p_in_cfg_coe_wrclk)
begin
  if p_in_rst='1' then
    i_coebuf_awrite<=(others=>'0');
  elsif p_in_cfg_coe_wrclk'event and p_in_cfg_coe_wrclk='1' then

    if p_in_cfg_acoe_ld='1' then
      i_coebuf_awrite<=p_in_cfg_acoe;
    elsif p_in_cfg_dcoe_wr='1' or p_in_cfg_dcoe_rd='1' then
      i_coebuf_awrite<=i_coebuf_awrite+1;
    end if;
  end if;
end process;

i_wr_rbuf(0)<=p_in_cfg_dcoe_wr when p_in_cfg_coeram_num="00" else '0';
i_wr_gbuf(0)<=p_in_cfg_dcoe_wr when p_in_cfg_coeram_num="01" else '0';
i_wr_bbuf(0)<=p_in_cfg_dcoe_wr when p_in_cfg_coeram_num="10" else '0';

p_out_cfg_dcoe<=i_rcoe_dout when p_in_cfg_coeram_num="00" else
                i_gcoe_dout when p_in_cfg_coeram_num="01" else
                i_bcoe_dout;


m_read_bram : vpcolor_rbram
port map
(
--//запись
addra=> i_coebuf_awrite,
dina => p_in_cfg_dcoe,
douta=> i_rcoe_dout,
ena  => '1',
wea  => i_wr_rbuf,
clka => p_in_cfg_coe_wrclk,
rsta => p_in_rst,

--//чтние
addrb=> sr_indw(0),
dinb => "00000000",
doutb=> i_result_out(23 downto 16),
enb  => i_bram_rd_en,
web  => "0",
clkb => p_in_clk,
rstb => p_in_rst
);

m_green_bram : vpcolor_gbram
port map
(
--//запись
addra=> i_coebuf_awrite,
dina => p_in_cfg_dcoe,
douta=> i_gcoe_dout,
ena  => '1',
wea  => i_wr_gbuf,
clka => p_in_cfg_coe_wrclk,
rsta => p_in_rst,

--//чтние
addrb=> sr_indw(0),
dinb => "00000000",
doutb=> i_result_out(15 downto 8),
enb  => i_bram_rd_en,
web  => "0",
clkb => p_in_clk,
rstb => p_in_rst
);

m_blue_bram : vpcolor_bbram
port map
(
--//запись
addra=> i_coebuf_awrite,
dina => p_in_cfg_dcoe,
douta=> i_bcoe_dout,
ena  => '1',
wea  => i_wr_bbuf,
clka => p_in_cfg_coe_wrclk,
rsta => p_in_rst,

--//чтние
addrb=> sr_indw(0),
dinb => "00000000",
doutb=> i_result_out(7 downto 0),
enb  => i_bram_rd_en,
web  => "0",
clkb => p_in_clk,
rstb => p_in_rst
);

i_result_out(31 downto 24)<=(others=>'1');

--END MAIN
end behavioral;


