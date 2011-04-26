-------------------------------------------------------------------------
-- Company     : Linkos
-- Engineer    : Golovachenko Victor
--
-- Create Date : 2010.10
-- Module Name : vrgb2ycrcb_main
--
-- Назначение/Описание :
--  Модуль ковертации цветового пространства RGB в YUV
--
--  Y =  0.299*R' + 0.587*G' + 0.114*B'
--  U = -0.147*R' - 0.280*G' + 0.436*B'=0.492*(B' - Y)
--  V =  0.615*R' - 0.515*G' - 0.100*B'=0.877*(R' - Y)
--  док. D:\Help\Book&Doc\Video\color_convert\color_conv.pdf - пп. YUV color space
--
--  Upstream Port(Вх. данные)
--  Downstream Port(Вых. данные)
--
--  Натройка работы модуля:
--  1. Выбрать режим работы модуля. Порт p_in_cfg_bypass - 0/1:
--     Upstream Port -> Downstream Port Обрабатывать/Не обрабатывать
--
-- Revision:
-- Revision 0.01 - File Created
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

entity vrgb2yuv_main is
generic(
G_DWIDTH : integer:=32;--//Возможные значения 32, 8
                       --//Если 32, то
                       --//Плюсы : за 1clk на выходные порты выдаются сразу 4-е обсчитаных семпла, где
                       --//p_in_upp_data(31...0)  = Pix(4*N+0) - (B(7..0)/G(15..8)/R(23..16)/0xFF;
                       --//p_in_upp_data(63...32) = Pix(4*N+1) - (B(7..0)/G(15..8)/R(23..16)/0xFF;
                       --//p_in_upp_data(95...64) = Pix(4*N+2) - (B(7..0)/G(15..8)/R(23..16)/0xFF;
                       --//p_in_upp_data(127...96)= Pix(4*N+3) - (B(7..0)/G(15..8)/R(23..16)/0xFF;
                       --//Минусы: для реализации требуется больше ресурсов FPGA

                       --//Если 8, то
                       --//Плюсы : Более компактная реализация по сравнению с G_DOUT_WIDTH=32
                       --//Минусы:за 1clk на выходные порты выдатся 1 обсчитаных семпл, где
                       --//p_in_upp_data(31...0)  = Pix(N) - (B(7..0)/G(15..8)/R(23..16)/0xFF;
                       --//p_in_upp_data(63...32) = 0;
                       --//p_in_upp_data(95...64) = 0;
                       --//p_in_upp_data(127...96)= 0;
G_SIM : string:="OFF"
);
port
(
-------------------------------
-- Управление
-------------------------------
p_in_cfg_bypass : in    std_logic;  --//0/1 - Upstream Port -> Downstream Port Обрабатывать/Не обрабатывать
p_in_cfg_init   : in    std_logic;

--//--------------------------
--//Upstream Port (входные данные)
--//--------------------------
p_in_upp_data   : in    std_logic_vector((32*4)-1 downto 0);
p_in_upp_wd     : in    std_logic;  --//Запись данных в модуль vrgb2yuv_main.vhd
p_out_upp_rdy_n : out   std_logic;  --//0 - Модуль vrgb2yuv_main.vhd готов к приему данных

--//--------------------------
--//Downstream Port (результат)
--//--------------------------
p_in_dwnp_rdy_n : in    std_logic;  --//0 - порт приемника готов к приему даннвх
p_out_dwnp_wd   : out   std_logic;  --//Запись данных в приемник
p_out_dwnp_data : out   std_logic_vector((32*4)-1 downto 0);

-------------------------------
--Технологический
-------------------------------
p_in_tst        : in    std_logic_vector(31 downto 0);
p_out_tst       : out   std_logic_vector(31 downto 0);

-------------------------------
--System
-------------------------------
p_in_clk        : in    std_logic;
p_in_rst        : in    std_logic
);
end vrgb2yuv_main;

architecture behavioral of vrgb2yuv_main is

--constant dly : time := 1 ps;

constant C_RCOEF : integer:= 306;--//0.299 * 1024
constant C_GCOEF : integer:= 601;--//0.587 * 1024
constant C_BCOEF : integer:= 117;--//0.114 * 1024

constant C_UCOEF : integer:= 504;--//0.492 * 1024
constant C_VCOEF : integer:= 898;--//0.877 * 1024

Type TSrUppWd is array (0 to G_DWIDTH/8-1) of std_logic_vector(6 downto 0);
signal sr_upp_wd                         : TSrUppWd;

Type TPixIn is array (0 to G_DWIDTH/8-1) of std_logic_vector(7 downto 0);
signal i_r                               : TPixIn;
signal i_g                               : TPixIn;
signal i_b                               : TPixIn;

Type TDlyRG is array (0 to 3) of std_logic_vector(i_r(0)'length-1 downto 0);
Type TSrRG is array (0 to G_DWIDTH/8-1) of TDlyRG;
signal sr_r                              : TSrRG;
signal sr_b                              : TSrRG;

Type TPixOut is array (0 to G_DWIDTH/8-1) of std_logic_vector(7 downto 0);
signal i_y                               : TPixOut;
signal i_u                               : TPixOut;
signal i_v                               : TPixOut;

type TCalc1 is array (0 to G_DWIDTH/8-1) of std_logic_vector((2*10)-1 downto 0);
signal i_r_mult                          : TCalc1;
signal i_g_mult                          : TCalc1;
signal i_b_mult                          : TCalc1;
signal i_b_mult_dly                      : TCalc1;
signal i_sum_rg_mult                     : TCalc1;
signal i_sum_rgb_mult                    : TCalc1;

signal i_u_sub                           : TPixOut;
signal i_v_sub                           : TPixOut;

signal i_u_mult                          : TCalc1;
signal i_v_mult                          : TCalc1;

Type TDlyY is array (0 to 2) of std_logic_vector(i_y(0)'length-1 downto 0);
Type TSrY is array (0 to G_DWIDTH/8-1) of TDlyY;
signal sr_y_tmp                          : TSrY;

Type TResult is array (0 to G_DWIDTH/8-1) of std_logic_vector(31 downto 0);
signal i_result                          : TResult;
signal i_result_en                       : std_logic;



--MAIN
begin

--//----------------------------------
--//Технологические сигналы
--//----------------------------------
p_out_tst(31 downto 0)<=(others=>'0');
--process(p_in_rst,p_in_clk)
--begin
--  if p_in_rst='1' then
--    p_out_tst(0)<=(others=>'0');
--
--  elsif p_in_clk'event and p_in_clk='1' then
--
--    p_out_tst(0)<=i_result_en(0);
--
--  end if;
--end process;
--p_out_tst(31 downto 1)<=(others=>'0');


--//----------------------------------------------
--//Связь с Upstream Port
--//----------------------------------------------
p_out_upp_rdy_n<=p_in_dwnp_rdy_n;


--//-----------------------------
--//Вывод результата
--//-----------------------------
p_out_dwnp_wd <=i_result_en when p_in_cfg_bypass='0' else p_in_upp_wd;

gen_w8 : if G_DWIDTH=8 generate
begin
p_out_dwnp_data((32*1)-1 downto (32*0)) <=i_result(0) when p_in_cfg_bypass='0' else p_in_upp_data((32*1)-1 downto (32*0));
p_out_dwnp_data((32*4)-1 downto (32*1)) <=(others=>'0');
end generate gen_w8;

gen_w32 : if G_DWIDTH=32 generate
begin
p_out_dwnp_data((32*1)-1 downto (32*0)) <=i_result(0) when p_in_cfg_bypass='0' else p_in_upp_data((32*1)-1 downto (32*0));
p_out_dwnp_data((32*2)-1 downto (32*1)) <=i_result(1) when p_in_cfg_bypass='0' else p_in_upp_data((32*2)-1 downto (32*1));
p_out_dwnp_data((32*3)-1 downto (32*2)) <=i_result(2) when p_in_cfg_bypass='0' else p_in_upp_data((32*3)-1 downto (32*2));
p_out_dwnp_data((32*4)-1 downto (32*3)) <=i_result(3) when p_in_cfg_bypass='0' else p_in_upp_data((32*4)-1 downto (32*3));
end generate gen_w32;



--//-----------------------------
--//Вычисления
--//-----------------------------
gen_calc : for i in 0 to G_DWIDTH/8-1 generate
begin
--//Выделяем цветовые компоненты
i_b(i)<=EXT(p_in_upp_data((32*i + i_b(i)'length*1)-1 downto 32*i + i_b(i)'length*0), i_b(i)'length);
i_g(i)<=EXT(p_in_upp_data((32*i + i_g(i)'length*2)-1 downto 32*i + i_g(i)'length*1), i_g(i)'length);
i_r(i)<=EXT(p_in_upp_data((32*i + i_r(i)'length*3)-1 downto 32*i + i_r(i)'length*2), i_r(i)'length);

--//Вычисления
process(p_in_rst,p_in_clk)
begin
  if p_in_rst='1' then

    sr_upp_wd(i)<=(others=>'0');
    for y in 0 to 3 loop
    sr_b(i)(y)<=(others=>'0');
    sr_r(i)(y)<=(others=>'0');
    end loop;

    for y in 0 to 2 loop
    sr_y_tmp(i)(y)<=(others=>'0');
    end loop;

    i_r_mult(i)<=(others=>'0');
    i_g_mult(i)<=(others=>'0');
    i_b_mult(i)<=(others=>'0');
    i_b_mult_dly(i)<=(others=>'0');
    i_sum_rg_mult(i)<=(others=>'0');
    i_sum_rgb_mult(i)<=(others=>'0');
    i_u_sub(i)<=(others=>'0');
    i_v_sub(i)<=(others=>'0');

    i_y(i)<=(others=>'0');
    i_u(i)<=(others=>'0');
    i_v(i)<=(others=>'0');

  elsif p_in_clk'event and p_in_clk='1' then
    if p_in_cfg_init='1' then
      sr_upp_wd(i)<=(others=>'0');
      for y in 0 to 3 loop
      sr_b(i)(y)<=(others=>'0');
      sr_r(i)(y)<=(others=>'0');
      end loop;

      for y in 0 to 2 loop
      sr_y_tmp(i)(y)<=(others=>'0');
      end loop;

      i_r_mult(i)<=(others=>'0');
      i_g_mult(i)<=(others=>'0');
      i_b_mult(i)<=(others=>'0');
      i_b_mult_dly(i)<=(others=>'0');
      i_sum_rg_mult(i)<=(others=>'0');
      i_sum_rgb_mult(i)<=(others=>'0');
      i_u_sub(i)<=(others=>'0');
      i_v_sub(i)<=(others=>'0');

      i_u_mult(i)<=(others=>'0');
      i_v_mult(i)<=(others=>'0');

      i_y(i)<=(others=>'0');
      i_u(i)<=(others=>'0');
      i_v(i)<=(others=>'0');

    else
      if p_in_dwnp_rdy_n='0' then

        --//0
        sr_upp_wd(i)(0)<=p_in_upp_wd and not p_in_cfg_bypass;
        sr_b(i)(0)<=i_b(i);
        sr_r(i)(0)<=i_r(i);

        i_r_mult(i)<=CONV_STD_LOGIC_VECTOR(C_RCOEF, i_r_mult(i)'length/2) * EXT(i_r(i), i_r_mult(i)'length/2);
        i_g_mult(i)<=CONV_STD_LOGIC_VECTOR(C_GCOEF, i_g_mult(i)'length/2) * EXT(i_g(i), i_g_mult(i)'length/2);
        i_b_mult(i)<=CONV_STD_LOGIC_VECTOR(C_BCOEF, i_b_mult(i)'length/2) * EXT(i_b(i), i_b_mult(i)'length/2);

        --//1
        sr_upp_wd(i)(1)<=sr_upp_wd(i)(0);
        sr_b(i)(1)<=sr_b(i)(0);
        sr_r(i)(1)<=sr_r(i)(0);

        i_sum_rg_mult(i)<=i_r_mult(i) + i_g_mult(i);
        i_b_mult_dly(i)<=i_b_mult(i);

        --//2
        sr_upp_wd(i)(2)<=sr_upp_wd(i)(1);
        sr_b(i)(2)<=sr_b(i)(1);
        sr_r(i)(2)<=sr_r(i)(1);

        i_sum_rgb_mult(i)<=i_sum_rg_mult(i) + i_b_mult_dly(i);

        --//3
        sr_upp_wd(i)(3)<=sr_upp_wd(i)(2);
        sr_b(i)(3)<=sr_b(i)(2);
        sr_r(i)(3)<=sr_r(i)(2);

        sr_y_tmp(i)(0)<=i_sum_rgb_mult(i)(8+10-1 downto 10);--//деление на 1024

        --//4
        sr_upp_wd(i)(4)<=sr_upp_wd(i)(3);
        sr_y_tmp(i)(1)<=sr_y_tmp(i)(0);

        if sr_b(i)(3)>sr_y_tmp(i)(0) then
          i_u_sub(i)<=sr_b(i)(3) - sr_y_tmp(i)(0);
        else
          i_u_sub(i)<=sr_y_tmp(i)(0) - sr_b(i)(3);
        end if;

        if sr_r(i)(3)>sr_y_tmp(i)(0) then
          i_v_sub(i)<=sr_r(i)(3) - sr_y_tmp(i)(0);
        else
          i_v_sub(i)<=sr_y_tmp(i)(0) - sr_r(i)(3);
        end if;

        --//5
        sr_upp_wd(i)(5)<=sr_upp_wd(i)(4);
        sr_y_tmp(i)(2)<=sr_y_tmp(i)(1);

        i_u_mult(i)<=CONV_STD_LOGIC_VECTOR(C_UCOEF, i_u_mult(i)'length/2) * EXT(i_u_sub(i), i_u_mult(i)'length/2);
        i_v_mult(i)<=CONV_STD_LOGIC_VECTOR(C_VCOEF, i_v_mult(i)'length/2) * EXT(i_v_sub(i), i_v_mult(i)'length/2);

        --//6
        sr_upp_wd(i)(6)<=sr_upp_wd(i)(5);
        i_y(i)<=sr_y_tmp(i)(2);
        i_u(i)<=i_u_mult(i)(8+10-1 downto 10);--//деление на 1024
        i_v(i)<=i_v_mult(i)(8+10-1 downto 10);--//деление на 1024

      end if;
    end if;
  end if;
end process;

--//Формирую результат:
i_result(i)(i_y(i)'length*1-1 downto i_y(i)'length*0)<=i_y(i)(i_y(i)'length-1 downto 0);
i_result(i)(i_u(i)'length*2-1 downto i_u(i)'length*1)<=i_u(i)(i_u(i)'length-1 downto 0);
i_result(i)(i_v(i)'length*3-1 downto i_v(i)'length*2)<=i_v(i)(i_v(i)'length-1 downto 0);
i_result(i)(31 downto i_v(i)'length*3)<=(others=>'0');

end generate gen_calc;

i_result_en<=sr_upp_wd(0)(6) and not p_in_dwnp_rdy_n;

--END MAIN
end behavioral;
