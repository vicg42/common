--------------------------------------------------------------------------------
-- Engineer: Golovachenko V. (vicg@hotmail.ru)
-- Create Date: 10.02.2005
-- Design Name: tv_gen.vhd
-- Component Name: tv_gen
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
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tv_gen is
generic
(
----значения отладки
--N_ROW  : integer:=65;--Кол-во строк в кадре. (312.5 строк в одном поле)
--N_H2   : integer:=32;--т.е. 64us/2=32us (удвоеная частота строк)
--W2_32us: integer:=5; --т.е. 2.32 us
--W4_7us : integer:=10; --т.е. 4.7 us
--W1_53us: integer:=2; --т.е. 1.53 us
--W5_8us : integer:=11; --т.е. 5.8 us
--var1   : integer:=2;  --продстройка
--var2   : integer:=2   --продстройка

--Все значения относительно p_in_clk=12.5MHz (Активных строк/пиксел - 577/640)
--Проверено на Starter Kit SPARTAN-3.
N_ROW  : integer:=625;--Кол-во строк в кадре. (312.5 строк в одном поле)
N_H2   : integer:=400;--т.е. 64us/2=32us (удвоеная частота строк)
W2_32us: integer:=29;--т.е. 2.32 us
W4_7us : integer:=59;--т.е. 4.7 us
W1_53us: integer:=19; --т.е. 1.53 us
W5_8us : integer:=73; --т.е. 5.8 us
var1   : integer:=4;  --продстройка
var2   : integer:=5   --продстройка

----Все значения относительно p_in_clk=15MHz (Активных строк/пиксел - 574/768)
----Проверено на Starter Kit SPARTAN-3.
--N_ROW  : integer:=625;--Кол-во строк в кадре. (312.5 строк в одном поле)
--N_H2   : integer:=480;--т.е. 64us/2=32us (удвоеная частота строк)
--W2_32us: integer:=35; --т.е. 2.32 us
--W4_7us : integer:=71; --т.е. 4.7 us
--W1_53us: integer:=23; --т.е. 1.53 us
--W5_8us : integer:=87; --т.е. 5.8 us
--var1   : integer:=6;   --продстройка
--var2   : integer:=6    --продстройка
);
port(
--EN_ADJUST  : out std_logic;
--LOAD_ADJUST: out std_logic;

--p_out_tv_kgi   : out std_logic;
p_out_tv_kci   : out std_logic;
p_out_tv_ssi   : out std_logic;--Синхросмесь. Стандартный TV сигнал
p_out_tv_field : out std_logic;--Поле TV сигнала (Четные/Нечетные строки)
p_out_den      : out std_logic;--Активная часть строки.(Разрешение вывода пиксел)

p_in_clk_en: in std_logic;
p_in_clk   : in std_logic;
p_in_rst   : in std_logic
);
end entity tv_gen;

architecture behavior of tv_gen is

signal i_cnt_2H   : unsigned(9 downto 0) := (others => '0');--integer range 0 to 1023;--счетчик удвоенной строки
signal i_cnt_N2H  : unsigned(9 downto 0) := (others => '0');--integer range 0 to 1023;--Счетчик кол-ва удвоеных строк
signal i_cnt_N2H5 : unsigned(6 downto 0) := (others => '0');--integer range 0 to 127;--кол-во 5раз удвоенных строк
signal i_cnt_2H5  : unsigned(2 downto 0) := (others => '0');--integer range 0 to 7;
signal i_H2       : std_logic;
signal i_H2SHT1   : std_logic;
signal i_H2SHT2   : std_logic;
signal i_H2SHT3   : std_logic;
signal i_H2SHT4   : std_logic;
signal i_H2SHT5   : std_logic;
signal i_EUR      : std_logic;
signal i_kci      : std_logic;
signal i_SelH     : std_logic;
signal i_field    : std_logic;
signal i_pixen    : std_logic;
--signal i_kgi      : std_logic;
--signal EAR      : std_logic;
--Для тестирования кол-ва строк в кадре и пиксел в строке!!!!!!
--signal test_pix: integer:=0;--  Тестовый счетчик. Тестирует кол-во пиксел в строке
--signal test_row: integer:=0;--  Тестовый счетчик. Тестирует кол-во строк в кадре
--signal APRT: std_logic;


begin --architecture behavior

p_out_tv_field <= i_field;
p_out_tv_kci <= i_kci;

process(p_in_rst, p_in_clk)
variable a : std_logic;
variable b : std_logic;
begin
  if p_in_rst = '1' then
    i_cnt_2H <= (others=>'0');
    i_cnt_N2H <= TO_UNSIGNED((N_ROW-2), i_cnt_N2H'length);
    i_cnt_2H5 <= TO_UNSIGNED(3, i_cnt_2H5'length);
    i_cnt_N2H5 <= TO_UNSIGNED(((N_ROW/5)-1), i_cnt_N2H5'length);
    i_H2SHT3 <= '0';
    i_H2SHT2 <= '0';
    i_H2SHT1 <= '0';
    i_H2 <= '0';

    a := '0';
    i_SelH <= '0';

    i_field <= '0';
    b := '0';

    i_EUR <= '0';
--      EAR <= '0';
    i_kci <= '0';
--      i_kgi <= '0';

  elsif rising_edge(p_in_clk) then
  if p_in_clk_en = '1' then
    if i_cnt_2H = TO_UNSIGNED(N_H2-1, i_cnt_2H'length) then
      --Формируем сигнал удвоенной частоты строк
      i_H2 <= '1';
      i_cnt_2H <= (others=>'0');

      a:= not a;
      i_SelH<=a;

      --Подсчитываем 5 импульсов удвоенной частоты строк
      if i_cnt_2H5 = TO_UNSIGNED(4, i_cnt_2H5'length) then
        i_cnt_2H5 <= (others=>'0');

        --Подсчитываем кол-во раз по 5 импульсов удвоенной частоты строк
        if i_cnt_N2H5 = TO_UNSIGNED(((N_ROW/5)-1), i_cnt_N2H5'length) then
          i_cnt_N2H5 <= (others=>'0');
          i_kci <= '0';
          --Формируем разрешение для формирования уравнивающих импульсов
          i_EUR <= '1';
          --Формируем разрешение для формирования кадрового гасящего импульса
--            i_kgi <= '1';

        elsif i_cnt_N2H5 = (i_cnt_N2H5'range => '0') then
          --Формируем сигнал поля
          b:=not b;
          i_field<=b;

          --Формируем кадовый синхро импульс
          i_kci <= '1';
          i_cnt_N2H5 <= i_cnt_N2H5 + 1;

        elsif i_cnt_N2H5 = TO_UNSIGNED(1, i_cnt_N2H5'length) then
          --Формируем кадовый синхро импульс
          i_kci <= '0';
          i_cnt_N2H5 <= i_cnt_N2H5 + 1;

        elsif i_cnt_N2H5 = TO_UNSIGNED(2, i_cnt_N2H5'length) then
          --Запрещаем разрешение для формирования уравнивающих импульсов
          i_EUR <= '0';

          i_cnt_N2H5 <= i_cnt_N2H5 + 1;

--          elsif i_cnt_N2H5 = TO_UNSIGNED(9, i_cnt_N2H5'length) then
--            --Запрещаем разрешение для формирования кадрового гасящего импульса
--            i_kgi <= '0';
--            i_cnt_N2H5 <= i_cnt_N2H5 + 1;

        else
          i_cnt_N2H5 <= i_cnt_N2H5 + 1;

        end if;

      else
        i_cnt_2H5 <= i_cnt_2H5 + 1;

      end if;

      --Посчитываем кол-во удвоенных строк
      if i_cnt_N2H = TO_UNSIGNED((N_ROW-1), i_cnt_N2H'length) then
        i_cnt_N2H <= (others=>'0');

      else
        i_cnt_N2H <= i_cnt_N2H + 1;

      end if;

--Формирование импульсов сдвинутых на оределенные величины относительно i_H2
    elsif i_cnt_2H = TO_UNSIGNED((W2_32us-1), i_cnt_2H'length) then
      --Формируем сдвинутый сигнал относительно i_H2
      --на 0+2,3мкс
        i_H2SHT1 <= '1';
        i_H2SHT2 <= '0';
        i_H2SHT3 <= '0';
        i_H2SHT4 <= '0';
        i_H2SHT5 <= '0';
        i_H2 <= '0';
        i_cnt_2H <= i_cnt_2H + 1;

    elsif i_cnt_2H = TO_UNSIGNED((N_H2-(W4_7us-1)), i_cnt_2H'length) then
      --Формируем сдвинутый сигнал относительно i_H2
      --на 0-4,7мкс
        i_H2SHT1 <= '0';
        i_H2SHT2 <= '1';
        i_H2SHT3 <= '0';
        i_H2SHT4 <= '0';
        i_H2SHT5 <= '0';
        i_H2 <= '0';
        i_cnt_2H <= i_cnt_2H + 1;

    elsif i_cnt_2H = TO_UNSIGNED((W4_7us-1), i_cnt_2H'length) then
      --Формируем сдвинутый сигнал относительно i_H2
      --на 0+4,7мкс
        i_H2SHT1 <= '0';
        i_H2SHT2 <= '0';
        i_H2SHT3 <= '1';
        i_H2SHT4 <= '0';
        i_H2SHT5 <= '0';
        i_H2 <= '0';
        i_cnt_2H <= i_cnt_2H + 1;

    elsif i_cnt_2H = TO_UNSIGNED(((W4_7us-1)+(W5_8us-1)+var1), i_cnt_2H'length) then
      --Формируем сдвинутый сигнал относительно i_H2
      --на 0+4,7мкс+5,8мкс+6(p_in_clk)
        i_H2SHT1 <= '0';
        i_H2SHT2 <= '0';
        i_H2SHT3 <= '0';
        i_H2SHT4 <= '1';
        i_H2SHT5 <= '0';
        i_H2 <= '0';
        i_cnt_2H <= i_cnt_2H + 1;

    elsif i_cnt_2H = TO_UNSIGNED((N_H2-W1_53us-1-var2), i_cnt_2H'length) then
      --Формируем сдвинутый сигнал относительно i_H2
      --на 0-1,53мкс-6(p_in_clk)
        i_H2SHT1 <= '0';
        i_H2SHT2 <= '0';
        i_H2SHT3 <= '0';
        i_H2SHT4 <= '0';
        i_H2SHT5 <= '1';
        i_H2 <= '0';
        i_cnt_2H <= i_cnt_2H + 1;
    else
        i_H2SHT1 <= '0';
        i_H2SHT2 <= '0';
        i_H2SHT3 <= '0';
        i_H2SHT4 <= '0';
        i_H2SHT5 <= '0';
        i_H2 <= '0';
        i_cnt_2H <= i_cnt_2H + 1;
    end if;
  end if;
  end if;
end process;

--Формируем TV сигнал (синхросмесь)
process(p_in_rst, p_in_clk)
variable a : std_logic;
begin
  if p_in_rst = '1' then
    a := '0';
    p_out_tv_ssi <= '0';
  elsif rising_edge(p_in_clk) then
  if p_in_clk_en = '1' then
        --формируем ССИ в строке
    if ((i_H2 = '1' or i_H2SHT3 = '1') and i_SelH = '1' and i_EUR = '0')  or
      --формируем уравнивающие импульсы вне КСИ
       ((i_H2 = '1' or i_H2SHT1 = '1') and i_EUR = '1' and i_kci = '0') or
        --формируем уравнивающие импульсы внутри КСИ
       ((i_H2 = '1' or i_H2SHT2 = '1') and i_EUR = '1' and i_kci = '1') then
      a:= not a;
      p_out_tv_ssi <= not a;
    end if;
  end if;
  end if;
end process;

--Формируем Активную часть строки
process(p_in_rst, p_in_clk)
  variable a : std_logic;
begin
  if p_in_rst = '1' then
    a:= '0';
    i_pixen <= '0';

  elsif rising_edge(p_in_clk) then
  if p_in_clk_en = '1' then
    if ((i_H2SHT4 = '1' and i_SelH = '1') or (i_H2SHT5 = '1'  and i_SelH = '0')) then
      --Выбираем кол-во активных строк в 1-ом и 2-ом поле
      --В 1-ом поле ТВ сигнала 287 строк
--        if (i_field = '1' and (i_cnt_N2H > TO_UNSIGNED(50, i_cnt_N2H'length) and i_cnt_N2H <= TO_UNSIGNED(624, i_cnt_N2H'length))) or
--           (i_field = '0' and (i_cnt_N2H > TO_UNSIGNED(49, i_cnt_N2H'length) and i_cnt_N2H <= TO_UNSIGNED(623, i_cnt_N2H'length))) then
      --В 1-ом поле ТВ сигнала 288 строк
      if (i_field = '1' and (i_cnt_N2H > TO_UNSIGNED(48, i_cnt_N2H'length) and i_cnt_N2H <= TO_UNSIGNED(624, i_cnt_N2H'length))) or
         (i_field = '0' and (i_cnt_N2H > TO_UNSIGNED(47, i_cnt_N2H'length) and i_cnt_N2H <= TO_UNSIGNED(623, i_cnt_N2H'length))) then
      --Test
--        if (i_field = '1' and (i_cnt_N2H > TO_UNSIGNED(24, i_cnt_N2H'length) and i_cnt_N2H <= TO_UNSIGNED(64, i_cnt_N2H'length))) or
--           (i_field = '0' and (i_cnt_N2H > TO_UNSIGNED(23, i_cnt_N2H'length) and i_cnt_N2H <= TO_UNSIGNED(63, i_cnt_N2H'length))) then
        a:= not a;
        i_pixen <= not a;

        --Для тестирования кол-ва строк в кадре и пиксел в строке!!!!!!
--          APRT<=not a;

      end if;
    end if;
  end if;
  end if;
end process;

p_out_den <= i_pixen;


----Формируем сигналы для подстройки строки
--process(p_in_rst, p_in_clk)
--begin
--  if p_in_rst = '1' then
--    LOAD_ADJUST <= '0';
--    EN_ADJUST <= '0';
--
--  elsif rising_edge(p_in_clk) then
--  if p_in_clk_en = '1' then
--
----      if (i_field = '1' and i_cnt_N2H = TO_UNSIGNED(51, i_cnt_N2H'length)) or (i_field = '0' and i_cnt_N2H = TO_UNSIGNED(50, i_cnt_N2H'length)) then
--    if (i_field = '1' and i_cnt_N2H = TO_UNSIGNED(49, i_cnt_N2H'length)) or (i_field = '0' and i_cnt_N2H = TO_UNSIGNED(48, i_cnt_N2H'length)) then
--      EN_ADJUST <= '1';
--    elsif i_cnt_N2H = TO_UNSIGNED(0, i_cnt_N2H'length) then
--      EN_ADJUST <= '0';
--    end if;
--
----      if (i_field = '1' and i_cnt_N2H = TO_UNSIGNED(51, i_cnt_N2H'length)) or (i_field = '0' and i_cnt_N2H = TO_UNSIGNED(50, i_cnt_N2H'length)) then
--    if (i_field = '1' and i_cnt_N2H = TO_UNSIGNED(49, i_cnt_N2H'length)) or (i_field = '0' and i_cnt_N2H = TO_UNSIGNED(48, i_cnt_N2H'length)) then
--      LOAD_ADJUST <= '1';
--    else
--      LOAD_ADJUST <= '0';
--    end if;
--
--  end if;
--  end if;
--end process;


--  *********************************************************************************
--  ************* Тестируем кол-во строк в кадре и пиксел в строке ******************
--  *********************************************************************************
--  process(p_in_rst, p_in_clk)
--  begin
--    if p_in_rst = '1' then
--      test_pix <= 0;
--    elsif rising_edge(p_in_clk) then
--      if APRT = '1' then
--        test_pix <= test_pix + 1;
--      else
--        test_pix <= 0;
--      end if;
--    end if;
--  end process;

--  process(i_kci,APRT)
--  begin
--    if i_kci = '1' then
--      test_row <= 0;
--    elsif APRT'event and APRT = '1' then
--      test_row <= test_row + 1;
--    end if;
--  end process;

end architecture behavior;
