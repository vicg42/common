--------------------------------------------------------------------------------
-- Engineer: Golovachenko V. (vicg@hotmail.ru)
-- Create Date: 10.02.2005
-- Design Name: TVS.vhd
-- Component Name: TVS
-- Revision: ver.03
--  change ver.03 - Ввел сигналы управления блоком точного позицианирования кадра TV (TVADJUST)
--                - Изменил кол-во строк в плое TV. Теперь в поле 288 строк. Раньше было 287
--------------------------------------------------------------------------------
--
--                      ____________________________________________
--             ________|                                            |_______
--    |       |                                                             |
--    |       |                                                             |
--    |_______|                                                             |
--
--    |<-CCИ->|<------>|<------------------------------------------>|<------>
--     4.7мкс   5.8мкс                   52мкс                       1.53мкс
--                     |<--->|                                |<--->|
--                     подстройка (var1)                       подстройка (var2)

--  Notes: в ТВ сигнале в одном поле 288 строк, а во втором 287!!!!!
--         а одна строка делится по 0.5 между 1 и 2  полем.
--         Всего получается 288+0.5+287+0.5=576 строк в кадре.
--
--  Поэтому чтоб сомпонент был гибче сделал возможность выбора кол-ва активных строк как в 1-ом поле так и 2-ом!!!!!
--
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity TVS is
generic
(
----значения отладки
--  N_ROW  : integer:=65;--Кол-во строк в кадре. (312.5 строк в одном поле)
--  N_H2   : integer:=32;--т.е. 64us/2=32us (удвоеная частота строк)
--  W2_32us: integer:=5; --т.е. 2.32 us
--  W4_7us : integer:=10; --т.е. 4.7 us
--  W1_53us: integer:=2; --т.е. 1.53 us
--  W5_8us : integer:=11; --т.е. 5.8 us
--  var1   : integer:=2;  --продстройка
--  var2   : integer:=2   --продстройка

----Все значения относительно clk=12.5MHz (Активных строк/пиксел - 577/640)
----Проверено на Starter Kit SPARTAN-3.
--  N_ROW  : integer:=625;--Кол-во строк в кадре. (312.5 строк в одном поле)
--  N_H2   : integer:=400;--т.е. 64us/2=32us (удвоеная частота строк)
--  W2_32us: integer:=29;--т.е. 2.32 us
--  W4_7us : integer:=59;--т.е. 4.7 us
--  W1_53us: integer:=19; --т.е. 1.53 us
--  W5_8us : integer:=73; --т.е. 5.8 us
--  var1   : integer:=4;  --продстройка
--  var2   : integer:=5   --продстройка

--Все значения относительно clk=15MHz (Активных строк/пиксел - 574/768)
--Проверено на Starter Kit SPARTAN-3.
N_ROW  : integer:=625;--Кол-во строк в кадре. (312.5 строк в одном поле)
N_H2   : integer:=480;--т.е. 64us/2=32us (удвоеная частота строк)
W2_32us: integer:=35; --т.е. 2.32 us
W4_7us : integer:=71; --т.е. 4.7 us
W1_53us: integer:=23; --т.е. 1.53 us
W5_8us : integer:=87; --т.е. 5.8 us
var1   : integer:=6;   --продстройка
var2   : integer:=6    --продстройка
);
port(
--EN_ADJUST  : out std_logic;
--LOAD_ADJUST: out std_logic;

--    KGI   : out std_logic;
p_out_tv_kci   : out std_logic;
p_out_tv_ssi   : out std_logic;--Синхросмесь. Стандартный TV сигнал
p_out_tv_field : out std_logic;--Поле TV сигнала (Четные/Нечетные строки)
p_out_den      : out std_logic;--Активная часть строки.(Разрешение вывода пиксел)

p_in_clk_en: in std_logic;
p_in_clk   : in std_logic;
p_in_rst   : in std_logic;
);
end TVS;

architecture behavior of TVS is

signal cnt_2H  : std_logic_vector(8 downto 0);--integer range 0 to 511;--счетчик удвоенной строки
signal cnt_N2H : std_logic_vector(9 downto 0);--integer range 0 to 1023;--Счетчик кол-ва удвоеных строк
signal cnt_N2H5: std_logic_vector(6 downto 0);--integer range 0 to 127;--кол-во 5раз удвоенных строк
signal cnt_2H5 : std_logic_vector(2 downto 0);--integer range 0 to 7;
signal H2,H2SHT1,H2SHT2,H2SHT3,H2SHT4,H2SHT5: std_logic;

signal EUR: std_logic;
--  signal EAR: std_logic;
signal KCI_int: std_logic;
--  signal KGI: std_logic;
signal SelH: std_logic;
signal Fiald_int: std_logic;

--  Для тестирования кол-ва строк в кадре и пиксел в строке!!!!!!
--  signal test_pix: integer:=0;--  Тестовый счетчик. Тестирует кол-во пиксел в строке
--  signal test_row: integer:=0;--  Тестовый счетчик. Тестирует кол-во строк в кадре
--  signal APRT: std_logic;

--  MAIN
begin

p_out_tv_field<=Fiald_int;
p_out_tv_kci<=KCI_int;

process(p_in_rst,clk)
variable a : std_logic;
variable b : std_logic;
begin
  if p_in_rst='1' then
    cnt_2H<=(others=>'0');--0;
    cnt_N2H<=CONV_STD_LOGIC_VECTOR((N_ROW-2), 10);
    cnt_2H5<=CONV_STD_LOGIC_VECTOR(3, 3);
    cnt_N2H5<=CONV_STD_LOGIC_VECTOR(((N_ROW/5)-1), 7);
    H2SHT3<='0';
    H2SHT2<='0';
    H2SHT1<='0';
    H2<='0';

    a:='0';
    SelH<='0';

    Fiald_int<='0';
    b:='0';

    EUR<='0';
--      EAR<='0';
    KCI_int<='0';
--      KGI<='0';

  elsif clk'event and clk='1' then
  if p_in_clk_en='1' then
    if cnt_2H=CONV_STD_LOGIC_VECTOR(N_H2-1, 9) then
      --Формируем сигнал удвоенной частоты строк
      H2<='1';
      cnt_2H<=(others=>'0');--0;

      a:= not a;
      SelH<=a;

      --Подсчитываем 5 импульсов удвоенной частоты строк
      if cnt_2H5=CONV_STD_LOGIC_VECTOR(4, 3) then
        cnt_2H5<=(others=>'0');--0;

        --Подсчитываем кол-во раз по 5 импульсов удвоенной частоты строк
        if cnt_N2H5=CONV_STD_LOGIC_VECTOR(((N_ROW/5)-1), 7) then
          cnt_N2H5<=(others=>'0');--0;
          KCI_int<='0';
          --Формируем разрешение для формирования уравнивающих импульсов
          EUR<='1';
          --Формируем разрешение для формирования кадрового гасящего импульса
--            KGI<='1';

        elsif cnt_N2H5="0000000" then
          --Формируем сигнал поля
          b:=not b;
          Fiald_int<=b;

          --Формируем кадовый синхро импульс
          KCI_int<='1';
          cnt_N2H5<=cnt_N2H5+1;

        elsif cnt_N2H5=CONV_STD_LOGIC_VECTOR(1, 7) then
          --Формируем кадовый синхро импульс
          KCI_int<='0';
          cnt_N2H5<=cnt_N2H5+1;

        elsif cnt_N2H5=CONV_STD_LOGIC_VECTOR(2, 7) then
          --Запрещаем разрешение для формирования уравнивающих импульсов
          EUR<='0';

          cnt_N2H5<=cnt_N2H5+1;

--          elsif cnt_N2H5=CONV_STD_LOGIC_VECTOR(9, 7) then
--            --Запрещаем разрешение для формирования кадрового гасящего импульса
--            KGI<='0';
--            cnt_N2H5<=cnt_N2H5+1;

        else
          cnt_N2H5<=cnt_N2H5+1;

        end if;

      else
        cnt_2H5<=cnt_2H5+1;

      end if;

      --Посчитываем кол-во удвоенных строк
      if cnt_N2H=CONV_STD_LOGIC_VECTOR((N_ROW-1), 10) then
        cnt_N2H<=(others=>'0');--0;

      else
        cnt_N2H<=cnt_N2H+1;

      end if;

--Формирование импульсов сдвинутых на оределенные величины относительно H2
    elsif cnt_2H=CONV_STD_LOGIC_VECTOR((W2_32us-1), 9) then
      --Формируем сдвинутый сигнал относительно H2
      --на 0+2,3мкс
        H2SHT1<='1';
        H2SHT2<='0';
        H2SHT3<='0';
        H2SHT4<='0';
        H2SHT5<='0';
        H2<='0';
        cnt_2H<=cnt_2H+1;

    elsif cnt_2H=CONV_STD_LOGIC_VECTOR((N_H2-(W4_7us-1)), 9) then
      --Формируем сдвинутый сигнал относительно H2
      --на 0-4,7мкс
        H2SHT1<='0';
        H2SHT2<='1';
        H2SHT3<='0';
        H2SHT4<='0';
        H2SHT5<='0';
        H2<='0';
        cnt_2H<=cnt_2H+1;

    elsif cnt_2H=CONV_STD_LOGIC_VECTOR((W4_7us-1), 9) then
      --Формируем сдвинутый сигнал относительно H2
      --на 0+4,7мкс
        H2SHT1<='0';
        H2SHT2<='0';
        H2SHT3<='1';
        H2SHT4<='0';
        H2SHT5<='0';
        H2<='0';
        cnt_2H<=cnt_2H+1;

    elsif cnt_2H=CONV_STD_LOGIC_VECTOR(((W4_7us-1)+(W5_8us-1)+var1), 9) then
      --Формируем сдвинутый сигнал относительно H2
      --на 0+4,7мкс+5,8мкс+6(clk)
        H2SHT1<='0';
        H2SHT2<='0';
        H2SHT3<='0';
        H2SHT4<='1';
        H2SHT5<='0';
        H2<='0';
        cnt_2H<=cnt_2H+1;

    elsif cnt_2H=CONV_STD_LOGIC_VECTOR((N_H2-W1_53us-1-var2), 9) then
      --Формируем сдвинутый сигнал относительно H2
      --на 0-1,53мкс-6(clk)
        H2SHT1<='0';
        H2SHT2<='0';
        H2SHT3<='0';
        H2SHT4<='0';
        H2SHT5<='1';
        H2<='0';
        cnt_2H<=cnt_2H+1;
    else
        H2SHT1<='0';
        H2SHT2<='0';
        H2SHT3<='0';
        H2SHT4<='0';
        H2SHT5<='0';
        H2<='0';
        cnt_2H<=cnt_2H+1;
    end if;
  end if;
  end if;
end process;

--Формируем TV сигнал (синхросмесь)
process(p_in_rst,clk)
variable a : std_logic;
begin
  if p_in_rst='1' then
    a:= '0';
    p_out_tv_ssi<='0';
  elsif clk'event and clk='1' then
  if p_in_clk_en='1' then
        --формируем ССИ в строке
    if ((H2='1' or H2SHT3='1') and SelH='1' and EUR='0')  or
      --формируем уравнивающие импульсы вне КСИ
       ((H2='1' or H2SHT1='1') and EUR='1' and KCI_int='0') or
        --формируем уравнивающие импульсы внутри КСИ
       ((H2='1' or H2SHT2='1') and EUR='1' and KCI_int='1') then
      a:= not a;
      p_out_tv_ssi<=not a;
    end if;
  end if;
  end if;
end process;

--Формируем Активную часть строки
process(p_in_rst,clk)
  variable a : std_logic;
begin
  if p_in_rst='1' then
    a:= '0';
    p_out_den<='0';

  elsif clk'event and clk='1' then
  if p_in_clk_en='1' then
    if ((H2SHT4='1' and SelH='1') or (H2SHT5='1'  and SelH='0')) then
      --Выбираем кол-во активных строк в 1-ом и 2-ом поле
      --В 1-ом поле ТВ сигнала 287 строк
--        if (Fiald_int='1' and (cnt_N2H>CONV_STD_LOGIC_VECTOR(50, 10) and cnt_N2H<=CONV_STD_LOGIC_VECTOR(624, 10))) or
--           (Fiald_int='0' and (cnt_N2H>CONV_STD_LOGIC_VECTOR(49, 10) and cnt_N2H<=CONV_STD_LOGIC_VECTOR(623, 10))) then
      --В 1-ом поле ТВ сигнала 288 строк
      if (Fiald_int='1' and (cnt_N2H>CONV_STD_LOGIC_VECTOR(48, 10) and cnt_N2H<=CONV_STD_LOGIC_VECTOR(624, 10))) or
         (Fiald_int='0' and (cnt_N2H>CONV_STD_LOGIC_VECTOR(47, 10) and cnt_N2H<=CONV_STD_LOGIC_VECTOR(623, 10))) then
      --Test
--        if (Fiald_int='1' and (cnt_N2H>CONV_STD_LOGIC_VECTOR(24, 10) and cnt_N2H<=CONV_STD_LOGIC_VECTOR(64, 10))) or
--           (Fiald_int='0' and (cnt_N2H>CONV_STD_LOGIC_VECTOR(23, 10) and cnt_N2H<=CONV_STD_LOGIC_VECTOR(63, 10))) then
        a:= not a;
        p_out_den<=not a;

        --Для тестирования кол-ва строк в кадре и пиксел в строке!!!!!!
--          APRT<=not a;

      end if;
    end if;
  end if;
  end if;
end process;


----Формируем сигналы для подстройки строки
--process(p_in_rst,clk)
--begin
--  if p_in_rst='1' then
--    LOAD_ADJUST<='0';
--    EN_ADJUST<='0';
--
--  elsif clk'event and clk='1' then
--  if p_in_clk_en='1' then
--
----      if (Fiald_int='1' and cnt_N2H=CONV_STD_LOGIC_VECTOR(51, 10)) or (Fiald_int='0' and cnt_N2H=CONV_STD_LOGIC_VECTOR(50, 10)) then
--    if (Fiald_int='1' and cnt_N2H=CONV_STD_LOGIC_VECTOR(49, 10)) or (Fiald_int='0' and cnt_N2H=CONV_STD_LOGIC_VECTOR(48, 10)) then
--      EN_ADJUST<='1';
--    elsif cnt_N2H=CONV_STD_LOGIC_VECTOR(0, 10) then
--      EN_ADJUST<='0';
--    end if;
--
----      if (Fiald_int='1' and cnt_N2H=CONV_STD_LOGIC_VECTOR(51, 10)) or (Fiald_int='0' and cnt_N2H=CONV_STD_LOGIC_VECTOR(50, 10)) then
--    if (Fiald_int='1' and cnt_N2H=CONV_STD_LOGIC_VECTOR(49, 10)) or (Fiald_int='0' and cnt_N2H=CONV_STD_LOGIC_VECTOR(48, 10)) then
--      LOAD_ADJUST<='1';
--    else
--      LOAD_ADJUST<='0';
--    end if;
--
--  end if;
--  end if;
--end process;


--  *********************************************************************************
--  ************* Тестируем кол-во строк в кадре и пиксел в строке ******************
--  *********************************************************************************
--  process(p_in_rst,clk)
--  begin
--    if p_in_rst='1' then
--      test_pix<=0;
--    elsif clk'event and clk='1' then
--      if APRT='1' then
--        test_pix<=test_pix+1;
--      else
--        test_pix<=0;
--      end if;
--    end if;
--  end process;

--  process(KCI_int,APRT)
--  begin
--    if KCI_int='1' then
--      test_row<=0;
--    elsif APRT'event and APRT='1' then
--      test_row<=test_row+1;
--    end if;
--  end process;

--  END MAIN
end behavior;
