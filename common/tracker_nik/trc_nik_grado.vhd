-------------------------------------------------------------------------
-- Company     : Linkos
-- Engineer    : Golovachenko Victor
--
-- Create Date : 05.12.2010 18:11:07
-- Module Name : trc_nik_grado
--
-- Назначение/Описание :
--  Модуль реализует вычисление направления(ориентации) градиента яркости.
--  Градиент яркости вычисяется модулем vsobel_main.vhd
--
-- Revision:
-- Revision 0.01 - File Created
-- Revision 0.02 - add 22.01.2011 17:31:58
--                 Корректировка размличных неточностей
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
use work.dsn_track_nik_pkg.all;

entity trc_nik_grado is
generic(
G_USE_WDATIN : integer:=32; --//Сколько бит входных данных использовать. 32, 8
G_SIM        : string:="OFF"
);
port
(
-------------------------------
-- Управление
-------------------------------
p_in_ctrl        : in    std_logic_vector(1 downto 0);

--//--------------------------
--//Upstream Port (входные данные)
--//--------------------------
p_in_upp_dxm     : in    std_logic_vector((8*4)-1 downto 0);--//dx - модуль
p_in_upp_dym     : in    std_logic_vector((8*4)-1 downto 0);--//dy - модуль

p_in_upp_dxs     : in    std_logic_vector((11*4)-1 downto 0);--//dx - знаковые значения
p_in_upp_dys     : in    std_logic_vector((11*4)-1 downto 0);--//dy - знаковые значения

p_in_upp_grad    : in    std_logic_vector((8*4)-1 downto 0);--//Градиент яркости (Амплетуда)
p_in_upp_data    : in    std_logic_vector((8*4)-1 downto 0);--//Значение пиксела

p_in_upp_wd      : in    std_logic;                    --//Запись данных в модуль trc_nik_grado.vhd
p_out_upp_rdy_n  : out   std_logic;                    --//0 - Модуль trc_nik_grado.vhd готов к приему данных

--//--------------------------
--//Downstream Port (результат)
--//--------------------------
p_out_dwnp_data  : out   std_logic_vector((8*4)-1 downto 0);--//Значение пиксела
p_out_dwnp_grada : out   std_logic_vector((8*4)-1 downto 0);--//Градиент яркости (Амплетуда)
p_out_dwnp_grado : out   std_logic_vector((8*4)-1 downto 0);--//Градиент яркости (Ориентация/Напровление)

p_out_dwnp_wd    : out   std_logic;                    --//Запись данных в приемник
p_in_dwnp_rdy_n  : in    std_logic;                    --//0 - порт приемника готов к приему даннвх

-------------------------------
--Технологический
-------------------------------
p_in_tst         : in    std_logic_vector(31 downto 0);
p_out_tst        : out   std_logic_vector(31 downto 0);

-------------------------------
--System
-------------------------------
p_in_clk         : in    std_logic;
p_in_rst         : in    std_logic
);
end trc_nik_grado;

architecture behavioral of trc_nik_grado is

component trc_nik_ramang
port (
addra : in   std_logic_vector(15 downto 0);
dina  : in   std_logic_vector(5 downto 0);
douta : out  std_logic_vector(5 downto 0);
ena   : in   std_logic;
wea   : in   std_logic_vector(0 downto 0);
clka  : in   std_logic;
rsta  : in   std_logic
);
end component;

component trc_nik_mult
port (
a   : in  std_logic_vector(10 downto 0);
b   : in  std_logic_vector(10 downto 0);
p   : out std_logic_vector(21 downto 0);
ce  : in  std_logic;
clk : in  std_logic
);
end component;

Type TTrcNikW11 is array (0 to 2) of std_logic_vector(10 downto 0);
Type TTrcNikSrAW11 is array (0 to G_USE_WDATIN/8 - 1) of TTrcNikW11;

Type TTrcNikW8 is array (0 to 4) of std_logic_vector(7 downto 0);
Type TTrcNikSrAW8 is array (0 to G_USE_WDATIN/8 - 1) of TTrcNikW8;

Type TTrcNikW6 is array (0 to 2) of std_logic_vector(5 downto 0);
Type TTrcNikSrAW6 is array (0 to G_USE_WDATIN/8 - 1) of TTrcNikW6;


Type TTrcNikAW32 is array (0 to G_USE_WDATIN/8 - 1) of std_logic_vector(31 downto 0);
Type TTrcNikAW22 is array (0 to G_USE_WDATIN/8 - 1) of std_logic_vector(21 downto 0);
Type TTrcNikAW16 is array (0 to G_USE_WDATIN/8 - 1) of std_logic_vector(15 downto 0);
Type TTrcNikAW11 is array (0 to G_USE_WDATIN/8 - 1) of std_logic_vector(10 downto 0);
Type TTrcNikAW9 is array (0 to G_USE_WDATIN/8 - 1) of std_logic_vector(8 downto 0);
Type TTrcNikAW8 is array (0 to G_USE_WDATIN/8 - 1) of std_logic_vector(7 downto 0);
Type TTrcNikAW6 is array (0 to G_USE_WDATIN/8 - 1) of std_logic_vector(5 downto 0);
Type TTrcNikAW3 is array (0 to G_USE_WDATIN/8 - 1) of std_logic_vector(2 downto 0);

signal i_sel_ang                     : std_logic_vector(1 downto 0);
signal i_coe_mult                    : std_logic_vector(10 downto 0);

signal i_data                        : TTrcNikAW8;
signal i_grada                       : TTrcNikAW8;
signal i_dxs                         : TTrcNikAW11;
signal i_dys                         : TTrcNikAW11;
signal i_dxm                         : TTrcNikAW8;
signal i_dym                         : TTrcNikAW8;

signal i_buf_adr                     : TTrcNikAW16;
signal i_buf_dout                    : TTrcNikAW6;
signal i_buf_ena                     : std_logic_vector(0 to G_USE_WDATIN/8 - 1);

signal sr_dxs                        : TTrcNikSrAW11;
signal sr_dys                        : TTrcNikSrAW11;
signal sr_buf_dout                   : TTrcNikSrAW6;
signal sr_data                       : TTrcNikSrAW8;
signal sr_grada                      : TTrcNikSrAW8;
signal sr_upp_wd                     : std_logic_vector(0 to 4);

signal tmp_dys_mult                  : TTrcNikAW22;
signal tmp_dxs_mult                  : TTrcNikAW22;
signal i_dxs_mult                    : TTrcNikAW22;
signal i_dys_mult                    : TTrcNikAW22;
signal i_dxs_mult_div                : TTrcNikAW22;
signal i_dys_mult_div                : TTrcNikAW22;
signal i_dxs_mult_rem                : TTrcNikAW3;
signal i_dys_mult_rem                : TTrcNikAW3;
signal i_dxs_mult_nresult            : TTrcNikAW11;
signal i_dys_mult_nresult            : TTrcNikAW11;
signal i_dxs_result                  : TTrcNikAW11;
signal i_dys_result                  : TTrcNikAW11;

signal i_grado                       : TTrcNikAW9;

signal v_logic0                      : std_logic_vector(9 downto 0);


--MAIN
begin


--//----------------------------------
--//Технологические сигналы
--//----------------------------------
--process(p_in_rst,p_in_clk)
--begin
--  if p_in_rst='1' then
--    p_out_tst(0)<='0';
--
--  elsif p_in_clk'event and p_in_clk='1' then
--
--    p_out_tst(0)<=OR_reduce(tst_fsmvbuf_cstate_dly) or tst_timeout_cnt(8);-- or
--
--  end if;
--end process;
--p_out_tst(31 downto 1)<=(others=>'0');
p_out_tst(31 downto 0)<=(others=>'0');



--//-----------------------------
--//Инициализация
--//-----------------------------
v_logic0<=(others=>'0');

i_sel_ang<=p_in_ctrl(1 downto 0);--//Выбор вариантов расчета




--//XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
--//Вычисления
--//XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
--//Линия задержки сигнала записи входных данных
process(p_in_rst,p_in_clk)
begin
  if p_in_rst='1' then
    sr_upp_wd<=(others=>'0');
  elsif p_in_clk'event and p_in_clk='1' then
    sr_upp_wd<=p_in_upp_wd & sr_upp_wd(0 to 3);
  end if;
end process;

--//
gen_calc : for i in 0 to G_USE_WDATIN/8 - 1 generate

--//------------------------------------
--//СТАДИЯ-0
--//------------------------------------
i_data(i)<=p_in_upp_data(8*(i + 1) - 1 downto 8*i);
i_grada(i)<=p_in_upp_grad(8*(i + 1) - 1 downto 8*i);
i_dxs(i) <=p_in_upp_dxs(11*(i + 1) - 1 downto 11*i);
i_dys(i) <=p_in_upp_dys(11*(i + 1) - 1 downto 11*i);
i_dxm(i) <=p_in_upp_dxm(8*(i + 1) - 1 downto 8*i);
i_dym(i) <=p_in_upp_dym(8*(i + 1) - 1 downto 8*i);

--//Чтние таблицы базовых углов.
--//Необходима для вычислени направления градиента яркости
i_buf_adr(i)<=i_dym(i)&i_dxm(i);
i_buf_ena(i)<=p_in_upp_wd;

m_ramangle :trc_nik_ramang
port map(
addra => i_buf_adr(i),
dina  => "000000",
douta => i_buf_dout(i),
ena   => i_buf_ena(i),
wea   => "0",
clka  => p_in_clk,
rsta  => p_in_rst
);

--//Линия задержек
process(p_in_rst,p_in_clk)
begin
  if p_in_rst='1' then
    sr_data(i)(0)<=(others=>'0');
    sr_grada(i)(0)<=(others=>'0');
    sr_dxs(i)(0)<=(others=>'0');
    sr_dys(i)(0)<=(others=>'0');
  elsif p_in_clk'event and p_in_clk='1' then
    if p_in_upp_wd='1' then
      sr_data(i)(0)<=i_data(i);
      sr_grada(i)(0)<=i_grada(i);
      sr_dxs(i)(0)<=i_dxs(i);
      sr_dys(i)(0)<=i_dys(i);
    end if;
  end if;
end process;

--//Уножение на масштабирующий коэфициент: Value * 0.625 = (Value *5)/8
--//Сначала уножжаем на 5, затем делим на 8 (см. ниже)
i_coe_mult<=CONV_STD_LOGIC_VECTOR(10#05#, i_coe_mult'length);
m_dxs_mult : trc_nik_mult
port map (
a   => i_coe_mult,
b   => i_dxs(i),        --//bit(10)- знак!!!
p   => tmp_dxs_mult(i),
ce  => p_in_upp_wd,
clk => p_in_clk
);

m_dys_mult : trc_nik_mult
port map (
a   => i_coe_mult,
b   => i_dys(i),        --//bit(10)- знак!!!
p   => tmp_dys_mult(i),
ce  => p_in_upp_wd,
clk => p_in_clk
);

--//------------------------------------
--//СТАДИЯ-1
--//------------------------------------
--//Деление на 8 результата умножения
i_dxs_mult(i)(21 downto 20)<=tmp_dxs_mult(i)(21 downto 20); --//Знак
i_dxs_mult(i)(19 downto 0) <=tmp_dxs_mult(i)(19) & tmp_dxs_mult(i)(19) & tmp_dxs_mult(i)(19) & tmp_dxs_mult(i)(19 downto 3);
i_dxs_mult_rem(i)(2 downto 0)<=tmp_dxs_mult(i)(2 downto 0); --//Остаток деления

i_dys_mult(i)(21 downto 20)<=tmp_dys_mult(i)(21 downto 20); --//Знак
i_dys_mult(i)(19 downto 0) <=tmp_dys_mult(i)(19) & tmp_dys_mult(i)(19) & tmp_dys_mult(i)(19) & tmp_dys_mult(i)(19 downto 3);
i_dys_mult_rem(i)(2 downto 0)<=tmp_dys_mult(i)(2 downto 0); --//Остаток деления

process(p_in_rst,p_in_clk)
begin
  if p_in_rst='1' then
    sr_data(i)(1)<=(others=>'0');
    sr_grada(i)(1)<=(others=>'0');
    sr_dxs(i)(1)<=(others=>'0');
    sr_dys(i)(1)<=(others=>'0');

    sr_buf_dout(i)(0)<=(others=>'0');

    i_dxs_mult_div(i)<=(others=>'0');
    i_dys_mult_div(i)<=(others=>'0');

  elsif p_in_clk'event and p_in_clk='1' then

    if sr_upp_wd(0)='1' then
        sr_data(i)(1)<=sr_data(i)(0);
        sr_grada(i)(1)<=sr_grada(i)(0);
        sr_dxs(i)(1)<=sr_dxs(i)(0);
        sr_dys(i)(1)<=sr_dys(i)(0);

        sr_buf_dout(i)(0)<=i_buf_dout(i);--//add 22.01.2011 17:31:58


        if i_dxs_mult(i)(20)='1' then
        --//Если число отрицательное, то корректируем целую часть после деления
        --//Иначе будет округление до большего целого.(1.25 -> 2; 1.5 -> 2)
            i_dxs_mult_div(i)(21 downto 20)<=i_dxs_mult(i)(21 downto 20);
            i_dxs_mult_div(i)(19 downto 0)<=i_dxs_mult(i)(19 downto 0) + OR_reduce(i_dxs_mult_rem(i));
        else
        --//Иначе выдаем текущее значение
          i_dxs_mult_div(i)<=i_dxs_mult(i);
        end if;

        if i_dys_mult(i)(20)='1' then
        --//Если число отрицательное, то корректируем целую часть после деления
        --//Иначе будет округление до большего целого.(1.25 -> 2; 1.5 -> 2)
            i_dys_mult_div(i)(21 downto 20)<=i_dys_mult(i)(21 downto 20);
            i_dys_mult_div(i)(19 downto 0)<=i_dys_mult(i)(19 downto 0) + OR_reduce(i_dys_mult_rem(i));
        else
        --//Иначе выдаем текущее значение
          i_dys_mult_div(i)<=i_dys_mult(i);
        end if;

    end if;--//if sr_upp_wd(0)='1' then
  end if;
end process;


--//------------------------------------
--//СТАДИЯ-2
--//------------------------------------
--//Нормирование результата умножения
process(p_in_rst,p_in_clk)
begin
  if p_in_rst='1' then
    sr_data(i)(2)<=(others=>'0');
    sr_grada(i)(2)<=(others=>'0');
    sr_dxs(i)(2)<=(others=>'0');
    sr_dys(i)(2)<=(others=>'0');

    sr_buf_dout(i)(1)<=(others=>'0');

    i_dxs_mult_nresult(i)<=(others=>'0');
    i_dys_mult_nresult(i)<=(others=>'0');

  elsif p_in_clk'event and p_in_clk='1' then

    if sr_upp_wd(1)='1' then
        sr_data(i)(2)<=sr_data(i)(1);
        sr_grada(i)(2)<=sr_grada(i)(1);
        sr_dxs(i)(2)<=sr_dxs(i)(1);
        sr_dys(i)(2)<=sr_dys(i)(1);

        sr_buf_dout(i)(1)<=sr_buf_dout(i)(0);

        if (i_dxs_mult_div(i)(20)='0' and i_dxs_mult_div(i)(19 downto 0)>("000000000000"&"11111111")) then
        --//Если значение > +255, то производим принудительное присвоение значений +255
            i_dxs_mult_nresult(i)(10)<='0';
            i_dxs_mult_nresult(i)(9 downto 0)<="0011111111";

        elsif (i_dxs_mult_div(i)(20)='1' and i_dxs_mult_div(i)(19 downto 0)<("111111111111"&"00000000")) then
        --//Если -255 > значение , то производим принудительное присвоение значений -255
            i_dxs_mult_nresult(i)(10)<='1';
            --i_dxs_mult_nresult(i)(9 downto 0)<="1100000000";
            i_dxs_mult_nresult(i)(9 downto 0)<="1100000001";--//add 22.01.2011 17:31:58
        else
        --//Иначе выдаем текущее значение
          i_dxs_mult_nresult(i)(10)<=i_dxs_mult_div(i)(20); --//Знак
          --i_dxs_mult_nresult(i)(9 downto 0)<=i_dxs_mult_div(i)(17 downto 8);
          i_dxs_mult_nresult(i)(9 downto 0)<=i_dxs_mult_div(i)(9 downto 0);--//add 22.01.2011 17:31:58
        end if;


        if (i_dys_mult_div(i)(20)='0' and i_dys_mult_div(i)(19 downto 0)>("000000000000"&"11111111")) then
        --//Если значение > +255, то производим принудительное присвоение значений +255
            i_dys_mult_nresult(i)(10)<='0';
            i_dys_mult_nresult(i)(9 downto 0)<="0011111111";

        elsif (i_dys_mult_div(i)(20)='1' and i_dys_mult_div(i)(19 downto 0)<("111111111111"&"00000000")) then
        --//Если -255 > значение , то производим принудительное присвоение значений -255
            i_dys_mult_nresult(i)(10)<='1';
            --i_dys_mult_nresult(i)(9 downto 0)<="1100000000";
            i_dys_mult_nresult(i)(9 downto 0)<="1100000001";--//add 22.01.2011 17:31:58
        else
        --//Иначе выдаем текущее значение
          i_dys_mult_nresult(i)(10)<=i_dys_mult_div(i)(20); --//Знак
          --i_dys_mult_nresult(i)(9 downto 0)<=i_dys_mult_div(i)(17 downto 8);
          i_dys_mult_nresult(i)(9 downto 0)<=i_dys_mult_div(i)(9 downto 0);--//add 22.01.2011 17:31:58
        end if;

    end if;--//if sr_upp_wd(1)='1' then
  end if;
end process;


--//------------------------------------
--//СТАДИЯ-3
--//------------------------------------
--//Анализ знаковых значений dX, dY и принятие решения:
--//выдовать истенные значения dX, dY или отмасштабированые
process(p_in_rst,p_in_clk)
begin
  if p_in_rst='1' then
    sr_data(i)(3)<=(others=>'0');
    sr_grada(i)(3)<=(others=>'0');

    sr_buf_dout(i)(2)<=(others=>'0');

    i_dxs_result(i)<=(others=>'0');
    i_dys_result(i)<=(others=>'0');

  elsif p_in_clk'event and p_in_clk='1' then

    if sr_upp_wd(2)='1' then
      sr_data(i)(3)<=sr_data(i)(2);
      sr_grada(i)(3)<=sr_grada(i)(2);

      sr_buf_dout(i)(2)<=sr_buf_dout(i)(1);

      if (sr_dxs(i)(2)(10)='0' and sr_dxs(i)(2)(9 downto 0)>"0011111111") or
         (sr_dxs(i)(2)(10)='1' and sr_dxs(i)(2)(9 downto 0)<"1100000000") or
         (sr_dys(i)(2)(10)='0' and sr_dys(i)(2)(9 downto 0)>"0011111111") or
         (sr_dys(i)(2)(10)='1' and sr_dys(i)(2)(9 downto 0)<"1100000000") then
      --//Если -255 > значение > +255, то подстовляем
      --//нормированый результат уножения на масштабирующий коэфициент (0.625)
        i_dxs_result(i)<=i_dxs_mult_nresult(i);
        i_dys_result(i)<=i_dys_mult_nresult(i);
      else
        i_dxs_result(i)<=sr_dxs(i)(2);
        i_dys_result(i)<=sr_dys(i)(2);
      end if;

    end if;--//if sr_upp_wd(2)='1' then

  end if;
end process;


--//------------------------------------
--//СТАДИЯ-4
--//------------------------------------
--//Выбор направления/ориентации градиента яркости.
process(p_in_rst,p_in_clk)
begin
  if p_in_rst='1' then

    sr_data(i)(4)<=(others=>'0');
    sr_grada(i)(4)<=(others=>'0');
    i_grado(i)<=(others=>'0');

  elsif p_in_clk'event and p_in_clk='1' then

    if sr_upp_wd(3)='1' then

        sr_data(i)(4)<=sr_data(i)(3);
        sr_grada(i)(4)<=sr_grada(i)(3);

        if i_sel_ang="00" then
        --//--------------------------
        --//Вариант Никифорова - 03.06.2011
        --//--------------------------

            if i_dxs_result(i)(9 downto 0)=v_logic0 and i_dys_result(i)(9 downto 0)=v_logic0 then
            --dX=0, dY=0
              i_grado(i)<=CONV_STD_LOGIC_VECTOR(10#00#, i_grado(i)'length);

            elsif i_dxs_result(i)(9 downto 0)=v_logic0 and i_dys_result(i)(10)='0' then
            --dX=0, dY>0
              i_grado(i)<=CONV_STD_LOGIC_VECTOR(10#192#, i_grado(i)'length);

            elsif i_dxs_result(i)(9 downto 0)=v_logic0 and i_dys_result(i)(10)='1' then
            --dX=0, dY<0
              i_grado(i)<=CONV_STD_LOGIC_VECTOR(10#64#, i_grado(i)'length);

            elsif i_dxs_result(i)(10)='0' and i_dys_result(i)(9 downto 0)=v_logic0 then
            --dX>0, dY=0
              i_grado(i)<=CONV_STD_LOGIC_VECTOR(10#128#, i_grado(i)'length);

            elsif i_dxs_result(i)(10)='1' and i_dys_result(i)(9 downto 0)=v_logic0 then
            --dX<0, dY=0
              i_grado(i)<=CONV_STD_LOGIC_VECTOR(10#00#, i_grado(i)'length);

            elsif i_dxs_result(i)(10)='0' and i_dys_result(i)(10)='0' then
            --dY>0, dX>0
              i_grado(i)<=CONV_STD_LOGIC_VECTOR(10#128#, i_grado(i)'length) + EXT(sr_buf_dout(i)(2), i_grado(i)'length);

            elsif i_dxs_result(i)(10)='1' and i_dys_result(i)(10)='0' then
            --dY>0, dX<0
              i_grado(i)<=CONV_STD_LOGIC_VECTOR(10#256#, i_grado(i)'length) - EXT(sr_buf_dout(i)(2), i_grado(i)'length);

            elsif i_dxs_result(i)(10)='1' and i_dys_result(i)(10)='1' then
            --dX<0, dY<0
              i_grado(i)<=EXT(sr_buf_dout(i)(2), i_grado(i)'length);

            elsif i_dxs_result(i)(10)='0' and i_dys_result(i)(10)='1' then
            --dY<0, dX>0
              i_grado(i)<=CONV_STD_LOGIC_VECTOR(10#128#, i_grado(i)'length) - EXT(sr_buf_dout(i)(2), i_grado(i)'length);

            end if;


        elsif i_sel_ang="01" then
        --//--------------------------
        --//Из ТЗ. Вариант 2
        --//--------------------------

            if i_dxs_result(i)(9 downto 0)=v_logic0 and i_dys_result(i)(9 downto 0)=v_logic0 then
            --dX=0, dY=0
              i_grado(i)<=CONV_STD_LOGIC_VECTOR(10#00#, i_grado(i)'length);

            elsif i_dxs_result(i)(9 downto 0)=v_logic0 and i_dys_result(i)(10)='0' then
            --dX=0, dY>0
              i_grado(i)<=CONV_STD_LOGIC_VECTOR(10#192#, i_grado(i)'length);

            elsif i_dxs_result(i)(10)='0' and i_dys_result(i)(10)='0' then
            --dX>0, dY>0
              i_grado(i)<=CONV_STD_LOGIC_VECTOR(10#256#, i_grado(i)'length) - EXT(sr_buf_dout(i)(2), i_grado(i)'length);

            elsif i_dxs_result(i)(10)='1' and (i_dys_result(i)(10)='0' or i_dys_result(i)(9 downto 0)=v_logic0) then
            --dX<0, dY>=0
              i_grado(i)<=CONV_STD_LOGIC_VECTOR(10#128#, i_grado(i)'length) + EXT(sr_buf_dout(i)(2), i_grado(i)'length);

            elsif i_dxs_result(i)(9 downto 0)=v_logic0 and i_dys_result(i)(10)='1' then
            --dX=0, dY<0
              i_grado(i)<=CONV_STD_LOGIC_VECTOR(10#64#, i_grado(i)'length);

            elsif i_dxs_result(i)(10)='1' and i_dys_result(i)(10)='1' then
            --dX<0, dY<0
              i_grado(i)<=CONV_STD_LOGIC_VECTOR(10#128#, i_grado(i)'length) - EXT(sr_buf_dout(i)(2), i_grado(i)'length);

            elsif i_dxs_result(i)(10)='0' and (i_dys_result(i)(10)='1' or i_dys_result(i)(9 downto 0)=v_logic0) then
            --dX>0, dY<=0
              i_grado(i)<=EXT(sr_buf_dout(i)(2), i_grado(i)'length);

            end if;


        --//--------------------------
        --//Из ТЗ. Вариант 1
        --//--------------------------
        elsif i_sel_ang="10" then
            if i_dxs_result(i)(9 downto 0)=v_logic0 and i_dys_result(i)(9 downto 0)=v_logic0 then
            --dX=0, dY=0
              i_grado(i)<=CONV_STD_LOGIC_VECTOR(10#00#, i_grado(i)'length);

            elsif i_dxs_result(i)(9 downto 0)=v_logic0 and i_dys_result(i)(10)='0' then
            --dX=0, dY>0
              i_grado(i)<=CONV_STD_LOGIC_VECTOR(10#64#, i_grado(i)'length);

            elsif i_dxs_result(i)(9 downto 0)=v_logic0 and i_dys_result(i)(10)='1' then
            --dX=0, dY<0
              i_grado(i)<=CONV_STD_LOGIC_VECTOR(10#192#, i_grado(i)'length);

            elsif i_dxs_result(i)(10)='0' and (i_dys_result(i)(10)='1' or i_dys_result(i)(9 downto 0)=v_logic0) then
            --dX>0, dY<=0
              i_grado(i)<=CONV_STD_LOGIC_VECTOR(10#128#, i_grado(i)'length) + EXT(sr_buf_dout(i)(2), i_grado(i)'length);

            elsif i_dxs_result(i)(10)='1' and (i_dys_result(i)(10)='0' or i_dys_result(i)(9 downto 0)=v_logic0) then
            --dX<0, dY>=0
              i_grado(i)<=EXT(sr_buf_dout(i)(2), i_grado(i)'length);

            elsif i_dxs_result(i)(10)='1' and i_dys_result(i)(10)='1' then
            --dX<0, dY<0
              i_grado(i)<=CONV_STD_LOGIC_VECTOR(10#256#, i_grado(i)'length) - EXT(sr_buf_dout(i)(2), i_grado(i)'length);

            elsif i_dxs_result(i)(10)='0' and i_dys_result(i)(10)='0' then
            --dX>0, dY>0
              i_grado(i)<=CONV_STD_LOGIC_VECTOR(10#128#, i_grado(i)'length) - EXT(sr_buf_dout(i)(2), i_grado(i)'length);

            end if;


        end if;--//if i_sel_ang="00" then
    end if;--//if sr_upp_wd(3)='1' then

  end if;
end process;


end generate gen_calc;



--//XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
--//Выдача результата
--//XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
p_out_upp_rdy_n<=p_in_dwnp_rdy_n;

p_out_dwnp_wd<=sr_upp_wd(4);

gen_result : for i in 0 to G_USE_WDATIN/8 - 1 generate
--p_out_dwnp_data(8*(i + 1) - 1 downto 8*i) <=  p_in_upp_data(8*(i + 1) - 1 downto 8*i);
--p_out_dwnp_grada(8*(i + 1) - 1 downto 8*i) <= p_in_upp_grad(8*(i + 1) - 1 downto 8*i);
--p_out_dwnp_grado(8*(i + 1) - 1 downto 8*i) <= (others=>'0');

p_out_dwnp_data(8*(i + 1) - 1 downto 8*i)<= sr_data(i)(4);
p_out_dwnp_grada(8*(i + 1) - 1 downto 8*i)<= sr_grada(i)(4);
p_out_dwnp_grado(8*(i + 1) - 1 downto 8*i) <= i_grado(i)(7 downto 0);
end generate gen_result;

gen8 : if G_USE_WDATIN=8 generate
p_out_dwnp_data((8*4)-1 downto 8)<=(others=>'0');
p_out_dwnp_grada((8*4)-1 downto 8)<=(others=>'0');
p_out_dwnp_grado((8*4)-1 downto 8)<=(others=>'0');
end generate gen8;


--END MAIN
end behavioral;

