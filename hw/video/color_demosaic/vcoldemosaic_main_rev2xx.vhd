-------------------------------------------------------------------------
-- Company     : Linkos
-- Engineer    : Golovachenko Victor
--
-- Create Date : 2010.07
-- Module Name : vcoldemosaic_main
--
-- Назначение/Описание :
--  Модуль реализует Билинейную интерполяцию цвета Фильтра Байера.
--
--  Upstream Port(Вх. данные) - данные Фильтра Байера
--  Downstream Port(Вых. данные) - Интерполированные данные Фильтра Байера (т.е. RGB)
--
--  Краевые эфекты: первых 2-а пикселя в строке + первых 2-е строки
--  выходных данных
--
--  Натройка работы модуля:
--  1. Выбрать режим работы модуля. Порт p_in_cfg_bypass - 0/1:
--     Upstream Port -> Downstream Port Обрабатывать/Не обрабатывать
--  2. Назначить размер входного кадра порты p_in_cfg_pix_count/p_in_cfg_row_count
--  3. Назначить первый цветовой компонент входного кадра фильтра Байера :0/1/2 - R/G/B
--     порт p_in_cfg_colorfst
--
-- Revision:
-- Revision 0.01 - File Created
-- Revision 0.02 - add 2010.11.14 коррекитровка управления приема входных данных.
--                 выкинуль всекие мудреные сигнала, которые как оказалось были совершенно ненужны.
--                 в результате получилось очень даже красиво :)
-- Revision 2.00 - add 2010.11.26
--                 Добавил generic - G_DOUT_WIDTH + и соответствующие изменения в связи с этим
--                 Изменил управление Буферами строк и логику формирования матрц вычислений.
--                 Теперь сделано по примеру от Xilix s3esk_video_line_stores.pdf (см. какалог ..\Sobel\doc)
-- Revision 2.01 - add 19.04.2011 10:59:55
--                 Поменял порядок цветовых каналов в выходных данных, (чтобы было как в vcoldemosaic_main_rev3xx.vhd)
--                 Теперь:(7..0)  =B                                 а раньше было:(7..0)  =R
--                        (15..8) =G                                               (15..8) =G
--                        (23..16)=R                                               (23..16)=B
--                        (31..24)=0xFF (прозрачность - альфа канал)               (31..24)=0xFF (прозрачность - альфа канал)
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
--use work.prj_def.all;

entity vcoldemosaic_main is
generic(
G_DOUT_WIDTH : integer:=32;  --//Возможные значения 32, 8

                             --//Если 32, то
                             --//Плюсы : за 1clk на выходные порты выдаются сразу 4-е обсчитаных семпла, где
                             --//p_out_dwnp_grad(31...0)  = Pix(4*N+0) - (R(7..0)/G(15..8)/B(23..16)/0xFF;
                             --//p_out_dwnp_grad(63...32) = Pix(4*N+1) - (R(7..0)/G(15..8)/B(23..16)/0xFF;
                             --//p_out_dwnp_grad(95...64) = Pix(4*N+2) - (R(7..0)/G(15..8)/B(23..16)/0xFF;
                             --//p_out_dwnp_grad(127...96)= Pix(4*N+3) - (R(7..0)/G(15..8)/B(23..16)/0xFF;
                             --//Минусы: для реализации требуется больше ресурсов FPGA

                             --//Если 8, то
                             --//Плюсы : Более компактная реализация по сравнению с G_DOUT_WIDTH=32
                             --//Минусы:за 1clk на выходные порты выдатся 1 обсчитаных семпл, где
                             --//p_out_dwnp_grad(31...0)  = Pix(N) - (R(7..0)/G(15..8)/B(23..16)/0xFF;
                             --//p_out_dwnp_grad(63...32) = 0;
                             --//p_out_dwnp_grad(95...64) = 0;
                             --//p_out_dwnp_grad(127...96)= 0;
G_SIM : string:="OFF"
);
port
(
-------------------------------
-- Управление
-------------------------------
p_in_cfg_bypass    : in    std_logic;                    --//0/1 - Upstream Port -> Downstream Port Обрабатывать/Не обрабатывать
p_in_cfg_colorfst  : in    std_logic_vector(1 downto 0); --//Первый пиксель 0/1/2 - R/G/B
p_in_cfg_pix_count : in    std_logic_vector(15 downto 0);--//Кол-во пиксел/4 т.к p_in_upp_data=32bit
p_in_cfg_row_count : in    std_logic_vector(15 downto 0);--//Кол-во строк
p_in_cfg_init      : in    std_logic;                    --//Инициализация. Сброс счетчика адреса BRAM

--//--------------------------
--//Upstream Port (входные данные)
--//--------------------------
p_in_upp_data      : in    std_logic_vector(31 downto 0);--//данные Фильтра Байера
p_in_upp_wd        : in    std_logic;                    --//Запись данных в модуль vcoldemosaic_main.vhd
p_out_upp_rdy_n    : out   std_logic;                    --//0 - Модуль vcoldemosaic_main.vhd готов к приему данных

--//--------------------------
--//Downstream Port (результат)
--//--------------------------
p_out_dwnp_data    : out   std_logic_vector(127 downto 0);--//RGB + байт прозрачности
p_out_dwnp_wd      : out   std_logic;                     --//Запись данных в приемник
p_in_dwnp_rdy_n    : in    std_logic;                     --//0 - порт приемника готов к приему даннвх

-------------------------------
--Технологический
-------------------------------
p_in_tst           : in    std_logic_vector(31 downto 0);
p_out_tst          : out   std_logic_vector(31 downto 0);

-------------------------------
--System
-------------------------------
p_in_clk           : in    std_logic;
p_in_rst           : in    std_logic
);
end vcoldemosaic_main;

architecture behavioral of vcoldemosaic_main is

constant dly : time := 1 ps;

component vcoldemosaic_bram
port
(
--//read first
addra: in  std_logic_vector(9 downto 0);
dina : in  std_logic_vector(31 downto 0);
douta: out std_logic_vector(31 downto 0);
ena  : in  std_logic;
wea  : in  std_logic_vector(0 downto 0);
clka : in  std_logic;
rsta : in  std_logic;

--//write first
addrb: in  std_logic_vector(9 downto 0);
dinb : in  std_logic_vector(31 downto 0);
doutb: out std_logic_vector(31 downto 0);
enb  : in  std_logic;
web  : in  std_logic_vector(0 downto 0);
clkb : in  std_logic;
rstb : in  std_logic
);
end component;


signal i_upp_rdy_n_out                   : std_logic;

signal i_lbufs_adra                      : std_logic_vector(9 downto 0);
signal tmp_lbufs_awrite                  : std_logic_vector(i_lbufs_adra'range);
type TArryLBufByte is array (0 to 2) of std_logic_vector(31 downto 0);
signal i_lbufs_dout                      : TArryLBufByte;
signal i_lbufs_dout_dly                  : TArryLBufByte;
signal i_lbuf_ena                        : std_logic_vector(0 downto 0);

signal i_byte_cnt_init                   : std_logic_vector(1 downto 0);
signal i_byte_cnt                        : std_logic_vector(1 downto 0);
type TSrByteIn is array (0 to 3) of std_logic_vector(1 downto 0);
signal sr_byte_cnt                       : TSrByteIn;

signal i_pix_cnt                         : std_logic_vector(p_in_cfg_pix_count'length-1 downto 0);
--signal i_row_cnt                         : std_logic_vector(p_in_cfg_row_count'length-1 downto 0);
signal i_row_evod                        : std_logic;

signal sr_row_evod                       : std_logic_vector(0 to 3);
signal sr_pix_evod                       : std_logic_vector(0 to 3);
signal sel_row_evod                      : std_logic_vector(0 to 3);
signal sel_pix_evod                      : std_logic_vector(0 to 3);

signal sr_result_en_fst                  : std_logic_vector(0 to 3);
signal sr_result_en                      : std_logic_vector(0 to 4);

signal sr_byteline_ld                    : std_logic_vector(0 to 0);
signal sr_byteline_en                    : std_logic_vector(0 to 0);
type TSrByte is array (3 downto 0) of std_logic_vector(7 downto 0);
type TSrLine is array (0 to 2) of TSrByte;
signal sr_byteline                       : TSrLine;
type TSrByteDly is array (0 to 1) of std_logic_vector(7 downto 0);
type TSrLineDly is array (0 to 2) of TSrByteDly;
signal sr_byteline_dly                   : TSrLineDly;

type TArrayPixs is array (0 to 2) of std_logic_vector(7 downto 0);
type TMatrix is array (0 to 2) of TArrayPixs;
type TMatrixs is array (0 to G_DOUT_WIDTH/8-1) of TMatrix;
signal i_matrix                          : TMatrixs;

type TCalc00 is array (0 to G_DOUT_WIDTH/8-1) of std_logic_vector(7 downto 0);
type TCalc0 is array (0 to G_DOUT_WIDTH/8-1) of std_logic_vector(8 downto 0);
signal i_sum_pix1_line1_dly              : TCalc00;
signal i_sum_pix02_line0                 : TCalc0;
signal i_sum_pix02_line2                 : TCalc0;
signal i_sum_pix02_line1                 : TCalc0;
signal i_sum_pix1_line02                 : TCalc0;

type TCalc1 is array (0 to G_DOUT_WIDTH/8-1) of std_logic_vector(9 downto 0);
signal i_sum1_result                     : TCalc1;
signal i_sum4_result0                    : TCalc1;
signal i_sum4_result1                    : TCalc1;
signal i_sum2_result0                    : TCalc1;
signal i_sum2_result1                    : TCalc1;

type TCalc20 is array (0 to G_DOUT_WIDTH/8-1) of std_logic_vector(1 downto 0);
signal i_sum_result_sel                  : TCalc20;
type TCalc2 is array (0 to G_DOUT_WIDTH/8-1) of std_logic_vector(23 downto 0);
signal i_pix_result                      : TCalc2;

type TCalc3 is array (0 to G_DOUT_WIDTH/8-1) of std_logic_vector(31 downto 0);
signal i_result_out                      : TCalc3;
signal i_result_en_out                   : std_logic;

type TSrPixOut is array (0 to 3) of std_logic_vector(7 downto 0);
type TSrPixOuts is array (0 to G_DOUT_WIDTH/8-1) of TSrPixOut;
signal sr_pix                            : TSrPixOuts;


--MAIN
begin

--//----------------------------------
--//Технологические сигналы
--//----------------------------------
process(p_in_rst,p_in_clk)
begin
  if p_in_rst='1' then
    p_out_tst(31 downto 2)<=(others=>'0');
  elsif p_in_clk'event and p_in_clk='1' then
    for i in 0 to G_DOUT_WIDTH/8-1 loop
    p_out_tst(0)<=OR_reduce(sr_pix(i)(3));
    end loop;

    p_out_tst(1)<=OR_reduce(i_byte_cnt);
  end if;
end process;
--p_out_tst(31 downto 0)<=(others=>'0');



--//------------------------------------------------------
--//RAM Строк видео информации
--//------------------------------------------------------
--//Запись данных в буфера(BRAM) строк
i_lbufs_adra<=tmp_lbufs_awrite;

i_lbuf_ena(0) <=p_in_upp_wd and not p_in_dwnp_rdy_n;

--//Буфера строк:
--//lineN : Текущая строка
i_lbufs_dout(0)<=p_in_upp_data;

--//lineN-1 : Предыдущая строка
m_buf0 : vcoldemosaic_bram
port map
(
--//READ FIRST
addra=> i_lbufs_adra,
dina => p_in_upp_data,
douta=> i_lbufs_dout(1),
ena  => i_lbuf_ena(0),
wea  => i_lbuf_ena,
clka => p_in_clk,
rsta => p_in_rst,

--//WRITE FIRST
addrb=> "0000000000",
dinb => "00000000000000000000000000000000",
doutb=> open,
enb  => '0',
web  => "0",
clkb => p_in_clk,
rstb => p_in_rst
);

--//lineN-2 : Предыдущая строка
m_buf1 : vcoldemosaic_bram
port map
(
--//READ FIRST
addra=> i_lbufs_adra,
dina => i_lbufs_dout(1),
douta=> i_lbufs_dout(2),
ena  => i_lbuf_ena(0),
wea  => i_lbuf_ena,
clka => p_in_clk,
rsta => p_in_rst,

--//WRITE FIRST
addrb=> "0000000000",
dinb => "00000000000000000000000000000000",
doutb=> open,
enb  => '0',
web  => "0",
clkb => p_in_clk,
rstb => p_in_rst
);


--//XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
--//Управление буферами + формирование мотрицы вычислений
--//для режима 1clk=4-е выходных sample
--//XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
gen_w32 : if G_DOUT_WIDTH=32 generate
begin

--//-----------------------------
--//Инициализация
--//-----------------------------
--i_byte_cnt_init<="11";


--//----------------------------------------------
--//Связь с Upstream Port
--//----------------------------------------------
p_out_upp_rdy_n <= p_in_dwnp_rdy_n;


--//-----------------------------
--//Вывод результата
--//-----------------------------
p_out_dwnp_wd <= i_result_en_out when p_in_cfg_bypass='0' else p_in_upp_wd;

p_out_dwnp_data(32*(0 + 1) - 1 downto 32*0) <= i_result_out(0) when p_in_cfg_bypass='0' else p_in_upp_data(32*(0 + 1) - 1 downto 32*0);
gen0_w32byte : for i in 1 to 3 generate
p_out_dwnp_data(32*(i + 1) - 1 downto 32*i) <= i_result_out(i);
end generate gen0_w32byte;


--//----------------------------------------------
--//Управление приемом данных с Upstream Port
--//----------------------------------------------
process(p_in_rst,p_in_clk)
begin
  if p_in_rst='1' then
    i_upp_rdy_n_out<='0';

    tmp_lbufs_awrite<=(others=>'0');
    i_pix_cnt<=(others=>'0');
    i_row_evod<='0';

  elsif p_in_clk'event and p_in_clk='1' then

    if p_in_cfg_bypass='1' or p_in_cfg_init='1' then
      tmp_lbufs_awrite<=(others=>'0');
      i_pix_cnt<=(others=>'0');
      i_row_evod<='0';

    else
      --//Обработка кадра ВКЛ.
        if p_in_dwnp_rdy_n='0' then

            if p_in_upp_wd='1' then
              --//Прием нового входного DWORD

                  if tmp_lbufs_awrite=p_in_cfg_pix_count(tmp_lbufs_awrite'range)-2 then
                    tmp_lbufs_awrite<=(others=>'0');
                  else
                    tmp_lbufs_awrite<=tmp_lbufs_awrite+1;
                  end if;

                  if i_pix_cnt=p_in_cfg_pix_count-1 then
                    i_pix_cnt<=(others=>'0');
                    i_row_evod<=not i_row_evod;--//Чет/НеЧет строка

                  else
                    i_pix_cnt<=i_pix_cnt+1;--//Ведем подсчет пикселей
                  end if;

            end if;
        end if;--//if p_in_dwnp_rdy_n='0' then

    end if;

  end if;
end process;

--//------------------------------------------------------
--//Линии задержек
--//------------------------------------------------------
process(p_in_rst,p_in_clk)
begin
  if p_in_rst='1' then

    sr_result_en<=(others=>'0');

  elsif p_in_clk'event and p_in_clk='1' then
  if p_in_dwnp_rdy_n='0' then

      --//Кол-во тактов задержки = кол-ву операций вычислений:
      --//В общем случае может меняться в зависимости от кол-ва операций вычислений
      sr_result_en<=p_in_upp_wd & sr_result_en(0 to 3);

  end if;--//if p_in_dwnp_rdy_n='0' then
  end if;
end process;

sr_byteline_ld(0)<=p_in_upp_wd;


--//------------------------------------------------------
--//Формирование матрицы вычислений
--//------------------------------------------------------
process(p_in_rst,p_in_clk)
begin
  if p_in_rst='1' then
    for y in 0 to 2 loop
      for i in 0 to 3 loop
        sr_byteline(y)(i)<=(others=>'0');
      end loop;

      for i in 0 to 1 loop
        sr_byteline_dly(y)(i)<=(others=>'0');
      end loop;
    end loop;
  elsif p_in_clk'event and p_in_clk='1' then
  if p_in_dwnp_rdy_n='0' then

      if sr_byteline_ld(0)='1'then
          for y in 0 to 2 loop
            for i in 0 to 3 loop
              sr_byteline(y)(i)<=i_lbufs_dout(y)(8*(i+1)-1 downto 8*i);
            end loop;

            for i in 0 to 1 loop
              sr_byteline_dly(y)(i)<=sr_byteline(y)(i+2);
            end loop;
          end loop;
      end if;

  end if;--//if p_in_dwnp_rdy_n='0'
  end if;
end process;

--//Матрица вычислений
--//где - i_matrix(Индекс выходного семпла)(Индекс строки)(Индекс Пикселя)
gen_matrix0 : for i in 0 to 2 generate
begin
--//где - i_matrix(0)(Индекс строки)(Индекс Пикселя)
i_matrix(0)(2-i)(2)<=sr_byteline(i)(0);
i_matrix(0)(2-i)(1)<=sr_byteline_dly(i)(1);
i_matrix(0)(2-i)(0)<=sr_byteline_dly(i)(0);
end generate gen_matrix0;

gen_matrix1 : for i in 0 to 2 generate
begin
--//где - i_matrix(0)(Индекс строки)(Индекс Пикселя)
i_matrix(1)(2-i)(2)<=sr_byteline(i)(1);
i_matrix(1)(2-i)(1)<=sr_byteline(i)(0);
i_matrix(1)(2-i)(0)<=sr_byteline_dly(i)(1);
end generate gen_matrix1;

gen_matrix2 : for i in 0 to 2 generate
begin
--//где - i_matrix(0)(Индекс строки)(Индекс Пикселя)
i_matrix(2)(2-i)(2)<=sr_byteline(i)(2);
i_matrix(2)(2-i)(1)<=sr_byteline(i)(1);
i_matrix(2)(2-i)(0)<=sr_byteline(i)(0);
end generate gen_matrix2;

gen_matrix3 : for i in 0 to 2 generate
begin
--//где - i_matrix(0)(Индекс строки)(Индекс Пикселя)
i_matrix(3)(2-i)(2)<=sr_byteline(i)(3);
i_matrix(3)(2-i)(1)<=sr_byteline(i)(2);
i_matrix(3)(2-i)(0)<=sr_byteline(i)(1);
end generate gen_matrix3;


--//Готовимся к выбору результата расчетов:
process(p_in_rst,p_in_clk)
begin
  if p_in_rst='1' then

    sr_row_evod<=(others=>'0');
    sr_pix_evod<=(others=>'0');

  elsif p_in_clk'event and p_in_clk='1' then
  if p_in_dwnp_rdy_n='0' then

      sr_pix_evod<=i_pix_cnt(0) & sr_pix_evod(0 to 2);
      sr_row_evod<=i_row_evod & sr_row_evod(0 to 2);

  end if;--//if p_in_dwnp_rdy_n='0' then
  end if;
end process;

sel_row_evod(0)<= sr_row_evod(3);
sel_pix_evod(0)<= sr_pix_evod(3);

sel_row_evod(1)<= sr_row_evod(3);
sel_pix_evod(1)<= not sr_pix_evod(3);

sel_row_evod(2)<= sr_row_evod(3);
sel_pix_evod(2)<= sr_pix_evod(3);

sel_row_evod(3)<= sr_row_evod(3);
sel_pix_evod(3)<= not sr_pix_evod(3);

end generate gen_w32;




--//XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
--//Управление буферами + формирование мотрицы вычислений
--//для режима 1clk=1выходной sample
--//XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
gen_w8 : if G_DOUT_WIDTH=8 generate
begin
--//-----------------------------
--//Инициализация
--//-----------------------------
i_byte_cnt_init<="11";


--//----------------------------------------------
--//Связь с Upstream Port
--//----------------------------------------------
p_out_upp_rdy_n <=p_in_dwnp_rdy_n or i_upp_rdy_n_out;


--//-----------------------------
--//Вывод результата
--//-----------------------------
p_out_dwnp_data <=EXT(i_result_out(0), p_out_dwnp_data'length) when p_in_cfg_bypass='0' else EXT(p_in_upp_data, p_out_dwnp_data'length);
p_out_dwnp_wd   <=i_result_en_out when p_in_cfg_bypass='0' else p_in_upp_wd;


--//----------------------------------------------
--//Управление приемом данных с Upstream Port
--//----------------------------------------------
process(p_in_rst,p_in_clk)
begin
  if p_in_rst='1' then
    i_upp_rdy_n_out<='0';

    tmp_lbufs_awrite<=(others=>'0');
    i_byte_cnt<=(others=>'0');
    i_pix_cnt<=(others=>'0');
    i_row_evod<='0';

  elsif p_in_clk'event and p_in_clk='1' then

    if p_in_cfg_bypass='1' or p_in_cfg_init='1' then
      tmp_lbufs_awrite<=(others=>'0');
      i_pix_cnt<=(others=>'0');
      i_byte_cnt<=(others=>'0');
      i_upp_rdy_n_out<='0';
      i_row_evod<='0';

    else
      --//Обработка кадра ВКЛ.
        if p_in_dwnp_rdy_n='0' then

            if p_in_upp_wd='1' then
              --//Прием нового входного DWORD
              i_upp_rdy_n_out<='1';--//Запрещаем запись входных данных в буфер строки на
                                   --//время обработки всех байт входного DWORD

              i_byte_cnt<=i_byte_cnt+1;--//Ведем подсчет байт входного DWORD

            else
              if i_upp_rdy_n_out='1' then
              --//Обработка байт входного DWORD
                if i_byte_cnt=i_byte_cnt_init then
                  i_byte_cnt<=(others=>'0');
                  i_upp_rdy_n_out<='0';

                  if tmp_lbufs_awrite=p_in_cfg_pix_count(tmp_lbufs_awrite'range)-2 then
                    tmp_lbufs_awrite<=(others=>'0');
                  else
                    tmp_lbufs_awrite<=tmp_lbufs_awrite+1;
                  end if;

                  if i_pix_cnt=p_in_cfg_pix_count-1 then
                    i_pix_cnt<=(others=>'0');
                    i_row_evod<=not i_row_evod;--//Чет/НеЧет строка

                  else
                    i_pix_cnt<=i_pix_cnt+1;--//Ведем подсчет пикселей
                  end if;
                else
                  i_byte_cnt<=i_byte_cnt+1;--//Ведем подсчет байт входного DWORD
                end if;
              end if;
            end if;
        end if;--//if p_in_dwnp_rdy_n='0' then

    end if;

  end if;
end process;

--//------------------------------------------------------
--//Линии задержек
--//------------------------------------------------------
process(p_in_rst,p_in_clk)
begin
  if p_in_rst='1' then

    sr_result_en<=(others=>'0');

  elsif p_in_clk'event and p_in_clk='1' then
  if p_in_dwnp_rdy_n='0' then

      --//Кол-во тактов задержки = кол-ву операций вычислений:
      --//В общем случае может меняться в зависимости от кол-ва операций вычислений
      sr_result_en<=(p_in_upp_wd or OR_reduce(i_byte_cnt)) & sr_result_en(0 to 3);

  end if;--//if p_in_dwnp_rdy_n='0' then
  end if;
end process;

sr_byteline_en(0)<=OR_reduce(i_byte_cnt);
sr_byteline_ld(0)<=p_in_upp_wd;


--//------------------------------------------------------
--//Формирование матрицы вычислений
--//------------------------------------------------------
process(p_in_rst,p_in_clk)
begin
  if p_in_rst='1' then
      for y in 0 to 2 loop
        for i in 0 to 3 loop
          sr_byteline(y)(i)<=(others=>'0');
        end loop;
      end loop;
      for y in 0 to 2 loop
        for i in 0 to 1 loop
          sr_byteline_dly(y)(i)<=(others=>'0');
        end loop;
      end loop;
  elsif p_in_clk'event and p_in_clk='1' then
  if p_in_dwnp_rdy_n='0' then
      if sr_byteline_ld(0)='1'then
      --//Загрузка нового 2DW для матрицы вычислений
        for y in 0 to 2 loop
          for i in 0 to 3 loop
            sr_byteline(y)(i)<=i_lbufs_dout(y)(8*(i+1)-1 downto 8*i);
          end loop;
        end loop;
      else
        if sr_byteline_en(0)='1'then
          --//закачка байт в матрицу вычислений (Сдвиг байт 2DW для 3-ех строк)
          for y in 0 to 2 loop
            sr_byteline(y)<="00000000"&sr_byteline(y)(3 downto 1);
          end loop;
        end if;
      end if;

      --//Сдвиговый регистр на 2-и точки для 3-ех строк
      --//Необходим для формирования матрицы вычислений
      for y in 0 to 2 loop
        if (sr_byteline_ld(0)='1' or sr_byteline_en(0)='1') then
          sr_byteline_dly(y)(0)<=sr_byteline(y)(0);
          sr_byteline_dly(y)(1)<=sr_byteline_dly(y)(0);
        end if;
      end loop;
  end if;--//if p_in_dwnp_rdy_n='0'
  end if;
end process;

--//Матрица вычислений
gen_matrix : for i in 0 to 2 generate
begin
--//где - i_matrix(Индекс строки)(Индекс Пикселя)
i_matrix(0)(2-i)(2)<=sr_byteline(i)(0);
i_matrix(0)(2-i)(1)<=sr_byteline_dly(i)(0);
i_matrix(0)(2-i)(0)<=sr_byteline_dly(i)(1);
end generate gen_matrix;

--//Готовимся к выбору результата расчетов:
process(p_in_rst,p_in_clk)
begin
  if p_in_rst='1' then

    sr_row_evod<=(others=>'0');
    sr_pix_evod<=(others=>'0');

  elsif p_in_clk'event and p_in_clk='1' then
  if p_in_dwnp_rdy_n='0' then

      sr_pix_evod<=i_byte_cnt(0) & sr_pix_evod(0 to 2);
      sr_row_evod<=i_row_evod & sr_row_evod(0 to 2);

  end if;--//if p_in_dwnp_rdy_n='0' then
  end if;
end process;

--//Формирование сигнала i_sum_result_sel
sel_row_evod(0)<= sr_row_evod(3);
sel_pix_evod(0)<= sr_pix_evod(3);

sel_row_evod(sel_row_evod'high downto 1)<=(others=>'0');
sel_pix_evod(sel_pix_evod'high downto 1)<=(others=>'0');

end generate gen_w8;





--//XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
--//Вычисления
--//XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
gen_mcalc : for i in 0 to G_DOUT_WIDTH/8-1 generate

--//------------------------------------------------------
--//Вычисления
--//------------------------------------------------------
process(p_in_rst,p_in_clk)
begin
  if p_in_rst='1' then

    i_sum_pix02_line0(i)<=(others=>'0');
    i_sum_pix02_line2(i)<=(others=>'0');
    i_sum_pix02_line1(i)<=(others=>'0');
    i_sum_pix1_line02(i)<=(others=>'0');
    i_sum_pix1_line1_dly(i)<=(others=>'0');

    i_sum4_result0(i)<=(others=>'0');
    i_sum4_result1(i)<=(others=>'0');
    i_sum2_result0(i)<=(others=>'0');
    i_sum2_result1(i)<=(others=>'0');
    i_sum1_result(i)<=(others=>'0');

    sr_pix(i)(0)<=(others=>'0');
    sr_pix(i)(1)<=(others=>'0');

  elsif p_in_clk'event and p_in_clk='1' then
  if p_in_dwnp_rdy_n='0' then
    --//------------------------------------------
    --//Сумммы
    --//------------------------------------------
    i_sum_pix02_line0(i)<=EXT(i_matrix(i)(0)(0), i_sum_pix02_line0(i)'length) + EXT(i_matrix(i)(0)(2), i_sum_pix02_line0(i)'length);
    i_sum_pix02_line2(i)<=EXT(i_matrix(i)(2)(0), i_sum_pix02_line2(i)'length) + EXT(i_matrix(i)(2)(2), i_sum_pix02_line2(i)'length);

    i_sum_pix02_line1(i)<=EXT(i_matrix(i)(1)(0), i_sum_pix02_line1(i)'length) + EXT(i_matrix(i)(1)(2), i_sum_pix02_line1(i)'length);
    i_sum_pix1_line02(i)<=EXT(i_matrix(i)(0)(1), i_sum_pix1_line02(i)'length) + EXT(i_matrix(i)(2)(1), i_sum_pix1_line02(i)'length);

    i_sum_pix1_line1_dly(i)<=i_matrix(i)(1)(1);

    sr_pix(i)(0)<=i_matrix(i)(2)(2);

    --//Где 0/X - занчищие/не занчищие значения матрицы в вычислений
    --//0 X 0
    --//X X X
    --//0 X 0
    i_sum4_result0(i)<=EXT(i_sum_pix02_line0(i), i_sum4_result0(i)'length) + EXT(i_sum_pix02_line2(i), i_sum4_result0(i)'length);

    --//X 0 X
    --//0 X 0
    --//X 0 X
    i_sum4_result1(i)<=EXT(i_sum_pix02_line1(i), i_sum4_result1(i)'length) + EXT(i_sum_pix1_line02(i), i_sum4_result1(i)'length);

    --//X X X
    --//0 X 0
    --//X X X
    i_sum2_result0(i)<=EXT(i_sum_pix02_line1(i), i_sum2_result0(i)'length);

    --//X 0 X
    --//X X X
    --//X 0 X
    i_sum2_result1(i)<=EXT(i_sum_pix1_line02(i), i_sum2_result1(i)'length);

    --//X X X
    --//X 0 X
    --//X X X
    i_sum1_result(i)<=EXT(i_sum_pix1_line1_dly(i), i_sum1_result(i)'length);

    sr_pix(i)(1)<=sr_pix(i)(0);

  end if;--//if p_in_dwnp_rdy_n='0' then
  end if;
end process;

--//------------------------------------------
--//Результат:
--//------------------------------------------
--//Выбор результата в зависимости от перевого компонента фильтра Байера
i_sum_result_sel(i)<=(not sel_row_evod(i))&(not sel_pix_evod(i)) when p_in_cfg_colorfst="10" else
                          sel_row_evod(i) &(not sel_pix_evod(i)) when p_in_cfg_colorfst="01" else
                          sel_row_evod(i) &     sel_pix_evod(i); --when p_in_cfg_colorfst="00" else

process(p_in_rst,p_in_clk)
begin
  if p_in_rst='1' then
    i_pix_result(i)(23 downto 0)<=(others=>'0');
    sr_pix(i)(2)<=(others=>'0');

  elsif p_in_clk'event and p_in_clk='1' then
  if p_in_dwnp_rdy_n='0' then

    if    i_sum_result_sel(i)="00" then
      --//0 X 0
      --//X X X
      --//0 X 0
      i_pix_result(i)(7 downto 0)<=i_sum4_result0(i)(9 downto 2);--//R

      --//X 0 X
      --//0 X 0
      --//X 0 X
      i_pix_result(i)(15 downto 8)<=i_sum4_result1(i)(9 downto 2);--//G

      --//X X X
      --//X 0 X
      --//X X X
      i_pix_result(i)(23 downto 16)<=i_sum1_result(i)(7 downto 0);--//B

    elsif i_sum_result_sel(i)="01" then
      --//X 0 X
      --//X X X
      --//X 0 X
      i_pix_result(i)(7 downto 0)<=i_sum2_result1(i)(8 downto 1);--//R

      --//X X X
      --//X 0 X
      --//X X X
      i_pix_result(i)(15 downto 8)<=i_sum1_result(i)(7 downto 0);--//G

      --//X X X
      --//0 X 0
      --//X X X
      i_pix_result(i)(23 downto 16)<=i_sum2_result0(i)(8 downto 1);--//B

    elsif i_sum_result_sel(i)="10" then
      --//X X X
      --//0 X 0
      --//X X X
      i_pix_result(i)(7 downto 0)<=i_sum2_result0(i)(8 downto 1);--//R

      --//X X X
      --//X 0 X
      --//X X X
      i_pix_result(i)(15 downto 8)<=i_sum1_result(i)(7 downto 0);--//G

      --//X 0 X
      --//X X X
      --//X 0 X
      i_pix_result(i)(23 downto 16)<=i_sum2_result1(i)(8 downto 1);--//B

    else
      --//X X X
      --//X 0 X
      --//X X X
      i_pix_result(i)(7 downto 0)<=i_sum1_result(i)(7 downto 0);--//R

      --//X 0 X
      --//0 X 0
      --//X 0 X
      i_pix_result(i)(15 downto 8)<=i_sum4_result1(i)(9 downto 2);--//G

      --//0 X 0
      --//X X X
      --//0 X 0
      i_pix_result(i)(23 downto 16)<=i_sum4_result0(i)(9 downto 2);--//B
    end if;

    sr_pix(i)(2)<=sr_pix(i)(1);

  end if;--//if p_in_dwnp_rdy_n='0' then
  end if;
end process;
--end generate gen_sim_off;


--//------------------------------------------------------
--//Выдача результат в Downstream Port
--//------------------------------------------------------
--i_result_en_out<=sr_result_en(4) and not p_in_dwnp_rdy_n;

process(p_in_rst,p_in_clk)
begin
  if p_in_rst='1' then
    i_result_out(i)(23 downto 0)<=(others=>'0');
    i_result_out(i)(31 downto 24)<=(others=>'1');--//Байт прозрачности

    sr_pix(i)(3)<=(others=>'0');

  elsif p_in_clk'event and p_in_clk='1' then
    if p_in_dwnp_rdy_n='0' then

        i_result_out(i)(7 downto 0)<=i_pix_result(i)(23 downto 16);--//B
        i_result_out(i)(15 downto 8)<=i_pix_result(i)(15 downto 8);--//G
        i_result_out(i)(23 downto 16)<=i_pix_result(i)(7 downto 0);--//R

        sr_pix(i)(3)<=sr_pix(i)(2);

    end if;--//if p_in_dwnp_rdy_n='0' then
  end if;
end process;

end generate gen_mcalc;

i_result_en_out<=sr_result_en(4) and not p_in_dwnp_rdy_n;


--END MAIN
end behavioral;


