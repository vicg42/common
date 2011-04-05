-------------------------------------------------------------------------
-- Company     : Linkos
-- Engineer    : Golovachenko Victor
--
-- Create Date : 25.11.2008 18:38
-- Module Name : vscaler_main_tb
--
-- Назначение/Описание :
--    Проверка работы
--
-- Revision:
-- Revision 0.01 - File Created
--
-------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.ALL;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_textio.all;

use work.vicg_common_pkg.all;
use work.test_im_pkg.all;

library std;
use std.textio.all;

library unisim;
use unisim.vcomponents.all;

entity vscaler_main_tb is
generic(
G_USE_COLOR : string:="OFF"  --//"ON"/"OFF"
);
end vscaler_main_tb;

architecture behavior of vscaler_main_tb is

constant i_clk_period : TIME := 6.6 ns; --150MHz


component vscaler_main
generic(
G_USE_COLOR : string:="OFF"  --//
);
port
(
-------------------------------
-- Управление
-------------------------------
p_in_cfg_color             : in    std_logic;
p_in_cfg_zoom_type         : in    std_logic;
p_in_cfg_zoom              : in    std_logic_vector(3 downto 0);
p_in_cfg_pix_count         : in    std_logic_vector(15 downto 0);
p_in_cfg_row_count         : in    std_logic_vector(15 downto 0);
p_in_cfg_init              : in    std_logic;

p_out_cfg_zoom_done        : out   std_logic;

p_in_cfg_acoe              : in    std_logic_vector(8 downto 0);
p_in_cfg_acoe_ld           : in    std_logic;
p_in_cfg_dcoe              : in    std_logic_vector(15 downto 0);
p_out_cfg_dcoe             : out   std_logic_vector(15 downto 0);
p_in_cfg_dcoe_wr           : in    std_logic;
p_in_cfg_dcoe_rd           : in    std_logic;
p_in_cfg_coe_wrclk         : in    std_logic;

--//--------------------------
--//Upstream Port
--//--------------------------
p_in_upp_data              : in    std_logic_vector(31 downto 0);
p_in_upp_wd                : in    std_logic;
p_out_upp_rdy_n            : out   std_logic;

--//--------------------------
--//Downstream Port
--//--------------------------
p_out_dwnp_data            : out   std_logic_vector(31 downto 0);
p_out_dwnp_wd              : out   std_logic;
p_in_dwnp_rdy_n            : in    std_logic;

-------------------------------
--Технологический
-------------------------------
p_in_tst_ctrl              : in    std_logic_vector(31 downto 0);
p_out_tst                  : out   std_logic_vector(31 downto 0);

-------------------------------
--System
-------------------------------
p_in_clk            : in    std_logic;
p_in_rst            : in    std_logic
);
end component;

component vscale_fifo
port (
din        : IN  std_logic_VECTOR(31 downto 0);
wr_en      : IN  std_logic;

dout       : OUT std_logic_VECTOR(31 downto 0);
rd_en      : IN  std_logic;

empty      : OUT std_logic;
full       : OUT std_logic;
almost_full: OUT std_logic;
--prog_full  : OUT std_logic;

clk        : IN  std_logic;
rst        : IN  std_logic
);
end component;

signal p_in_clk                       : std_logic := '0';
signal p_in_rst                       : std_logic := '0';

signal p_in_cfg_init                  : std_logic;
signal p_in_cfg_color                 : std_logic;
signal p_in_cfg_zoom_type             : std_logic;
signal p_in_cfg_zoom                  : std_logic_vector(3 downto 0);
signal p_in_cfg_pix_count             : std_logic_vector(15 downto 0);
signal p_in_cfg_row_count             : std_logic_vector(15 downto 0);

signal p_out_cfg_zoom_done            : std_logic;

signal p_in_cfg_acoe                  : std_logic_vector(8 downto 0);
signal p_in_cfg_acoe_ld               : std_logic;
signal p_in_cfg_dcoe                  : std_logic_vector(15 downto 0);
signal p_out_cfg_dcoe                 : std_logic_vector(15 downto 0);
signal p_in_cfg_dcoe_wr               : std_logic;
signal p_in_cfg_dcoe_rd               : std_logic;
signal p_in_cfg_coe_wrclk             : std_logic;

signal i_fifoin_dout                  : std_logic_vector(31 downto 0);
signal i_fifoin_rd                    : std_logic;
signal i_fifoin_empty                 : std_logic;
signal i_fifoin_full                  : std_logic;

signal tst_data_out                   : std_logic_vector(31 downto 0);
signal p_in_upp_wd                    : std_logic;
signal p_out_upp_rdy_n                : std_logic;

signal p_out_dwnp_data                : std_logic_vector(31 downto 0);
signal p_out_dwnp_wd                  : std_logic;
signal p_in_dwnp_rdy_n                : std_logic;

signal usr_cfg_pix_count              : std_logic_vector(15 downto 0);
signal usr_cfg_row_count              : std_logic_vector(15 downto 0);
signal usr_cfg_fr_count               : std_logic_vector(7 downto 0);

signal tst_vfr_count                  : std_logic_vector(7 downto 0);
signal tst_row_count                  : std_logic_vector(15 downto 0);
signal tst_pix_count                  : std_logic_vector(15 downto 0);
signal tst_data                       : std_logic_vector(7 downto 0);
signal mnl_write_testdata             : std_logic;

signal mnl_use_gen_dwnp_rdy           : std_logic;

signal tst_mnl_coe_count              : std_logic_vector(7 downto 0);
signal tst_coe_count                  : std_logic_vector(7 downto 0);
signal mnl_write_coedata              : std_logic;
signal mnl_write_coedata_ctrl         : std_logic;
signal mnl_dwnp_rdy_n                 : std_logic;

signal i_fifo_result_dout             : std_logic_vector(31 downto 0);
signal i_fifo_result_rd               : std_logic;
signal i_fifo_result_empty            : std_logic;
signal i_fifo_result_full             : std_logic;
signal mnl_fifo_result_rd             : std_logic;

signal tmp_cfg_dcoe_wr                : std_logic;

signal i_sel_coe_dw                   : std_logic;
signal i_dwnp_rdy_n                   : std_logic;

signal i_zoom_up_on                   : std_logic;
signal i_zoom_dwn_on                  : std_logic;
signal i_zoom_size_x2                 : std_logic;
signal i_zoom_size_x4                 : std_logic;

signal tst_dwnp_count                 : std_logic_vector(31 downto 0);
signal dsize_out                      : std_logic;
signal tst_dwnp_pix_max               : std_logic_vector(15 downto 0);
signal tst_dwnp_row_max               : std_logic_vector(15 downto 0);
signal tst_dwnp_pix                   : std_logic_vector(15 downto 0);
signal tst_dwnp_row                   : std_logic_vector(15 downto 0);
signal tst_dwnp_fr                    : std_logic_vector(15 downto 0);
signal tst_dwnp_dcount                : std_logic_vector(31 downto 0);

signal i_upp_wd_en                    : std_logic;
signal i_upp_wd_stop                  : std_logic;

signal tst_mnl_fr_pause               : std_logic_vector(31 downto 0);
signal tst_frpuase_count              : std_logic_vector(31 downto 0);
signal i_upp_frpause                  : std_logic;
signal tst_mnl_row_pause              : std_logic_vector(31 downto 0);
signal tst_rowpause_count             : std_logic_vector(31 downto 0);
signal i_upp_rowpause                 : std_logic;

signal i_srambler_out                 : std_logic_vector(31 downto 0);

signal tst_incr                       : std_logic_vector(p_in_cfg_pix_count'range);

signal adr_image_out                  : std_logic_vector(7 downto 0);
signal tst_image_out                  : std_logic_vector(31 downto 0);

--Main
begin



m_vscaler: vscaler_main
generic map(
G_USE_COLOR => G_USE_COLOR
)
port map
(
-------------------------------
-- Управление
-------------------------------
p_in_cfg_color             => p_in_cfg_color,
p_in_cfg_zoom_type         => p_in_cfg_zoom_type,
p_in_cfg_zoom              => p_in_cfg_zoom,
p_in_cfg_pix_count         => p_in_cfg_pix_count,
p_in_cfg_row_count         => p_in_cfg_row_count,
p_in_cfg_init              => p_in_cfg_init,

p_out_cfg_zoom_done        => p_out_cfg_zoom_done,

p_in_cfg_acoe              => p_in_cfg_acoe,
p_in_cfg_acoe_ld           => p_in_cfg_acoe_ld,
p_in_cfg_dcoe              => p_in_cfg_dcoe,
p_out_cfg_dcoe             => p_out_cfg_dcoe,
p_in_cfg_dcoe_wr           => p_in_cfg_dcoe_wr,
p_in_cfg_dcoe_rd           => p_in_cfg_dcoe_rd,
p_in_cfg_coe_wrclk         => p_in_cfg_coe_wrclk,

--//--------------------------
--//Upstream Port
--//--------------------------
p_in_upp_data              => i_fifoin_dout,
p_in_upp_wd                => i_fifoin_rd,
p_out_upp_rdy_n            => p_out_upp_rdy_n,

--//--------------------------
--//Downstream Port
--//--------------------------
p_out_dwnp_data            => p_out_dwnp_data,
p_out_dwnp_wd              => p_out_dwnp_wd,
p_in_dwnp_rdy_n            => p_in_dwnp_rdy_n,

-------------------------------
--Технологический
-------------------------------
p_in_tst_ctrl              => "00000000000000000000000000000000",
p_out_tst                  => open,

-------------------------------
--System
-------------------------------
p_in_clk            => p_in_clk,
p_in_rst            => p_in_rst
);

m_fifo_in : vscale_fifo
port map
(
din         => tst_image_out,--tst_data_out,--
wr_en       => p_in_upp_wd,
--wr_clk      => p_in_upp_clk,

dout        => i_fifoin_dout,
rd_en       => i_fifoin_rd,
--rd_clk      => p_in_dwnp_clk,

empty       => i_fifoin_empty,
full        => open,
almost_full => i_fifoin_full,
--prog_full   => i_fifoin_full,

clk         => p_in_clk,
rst         => p_in_rst
);

i_fifoin_rd<=not i_fifoin_empty and not p_out_upp_rdy_n;

clk_in_generator : process
begin
  p_in_clk<='0';
  wait for i_clk_period/2;
  p_in_clk<='1';
  wait for i_clk_period/2;
end process;

p_in_rst<='1','0' after 1 us;


p_in_cfg_acoe      <=(others=>'0');
p_in_cfg_acoe_ld   <='0';
p_in_cfg_dcoe      <=(others=>'0');
p_in_cfg_dcoe_wr   <='0';
p_in_cfg_dcoe_rd   <='0';
p_in_cfg_coe_wrclk <=p_in_clk;


--//----------------------------------------------------------
--//Настройка тестирования
--//----------------------------------------------------------
p_in_cfg_init<='0';

--//Конфигурируем работу модуля vscaler_main.vhd:
p_in_cfg_zoom_type<='0';--//0/1 - Инткрполяция/1 дулирование
--//Размер - Увеличение/Уменьшение
i_zoom_size_x2<='1';
i_zoom_size_x4<='0';
--//Увеличение/Уменьшение
i_zoom_up_on  <='1';
i_zoom_dwn_on <='0';

--//Конфигурируем генератор тестровых данных:
usr_cfg_pix_count<=CONV_STD_LOGIC_VECTOR(10#24#, p_in_cfg_pix_count'length); --Тестовый кадр: SIZE-X
usr_cfg_row_count<=CONV_STD_LOGIC_VECTOR(10#16#, p_in_cfg_pix_count'length); --Тестовый кадр: SIZE-Y
usr_cfg_fr_count <=CONV_STD_LOGIC_VECTOR(16#01#, usr_cfg_fr_count'length);   --Кол-во тестовых кодров

tst_mnl_row_pause<=CONV_STD_LOGIC_VECTOR(16#00#, tst_mnl_row_pause'length);  --//Пауза между строками
tst_mnl_fr_pause <=CONV_STD_LOGIC_VECTOR(16#08#, tst_mnl_fr_pause'length);   --//Пауза между кадрами

--// 1/0 Генерировать/НЕ Гненерировать waveform для сигнала p_in_dwnp_rdy_n
mnl_use_gen_dwnp_rdy<='0';




--//Кол-во загружаемых коэфициентов в BRAM
tst_mnl_coe_count <=CONV_STD_LOGIC_VECTOR(10#222#, tst_mnl_coe_count'length); --//

--// 0/1 Использовать коэф. записаные поумолчанию в COERAM / Перезапись COERAM коэфициентами из TestBanch
mnl_write_coedata_ctrl<='0';





--//----------------------------------------------------------
--//
--//----------------------------------------------------------
color_off : if strcmp(G_USE_COLOR,"OFF") generate
begin
p_in_cfg_color<='0';--//0/1 - входные данные Gray/Color
p_in_cfg_pix_count<="00"&usr_cfg_pix_count(15 downto 2);   --//Кол-во пикселей
p_in_cfg_row_count<=usr_cfg_row_count;   --//Кол-во строк
end generate color_off;

color_on : if strcmp(G_USE_COLOR,"ON") generate
begin
p_in_cfg_color<='1';--//0/1 - входные данные Gray/Color
p_in_cfg_pix_count<=usr_cfg_pix_count;   --//Кол-во пикселей
p_in_cfg_row_count<=usr_cfg_row_count;   --//Кол-во строк
end generate color_on;


--0/1/2 - bypass/ZoomDown/ZoomUp
p_in_cfg_zoom(3 downto 2)<=CONV_STD_LOGIC_VECTOR(16#02#, 2) when i_zoom_up_on='1' and i_zoom_dwn_on='0' else
                           CONV_STD_LOGIC_VECTOR(16#01#, 2) when i_zoom_up_on='0' and i_zoom_dwn_on='1' else
                           CONV_STD_LOGIC_VECTOR(16#00#, 2);

--1/2   - x2/x4
p_in_cfg_zoom(1 downto 0)<=CONV_STD_LOGIC_VECTOR(16#02#, 2) when i_zoom_size_x2='0' and i_zoom_size_x4='1' else
                           CONV_STD_LOGIC_VECTOR(16#01#, 2);

mnl_write_coedata <='0',mnl_write_coedata_ctrl after 1.5 us;

mnl_write_testdata<='0','1' after 2.5 us;

--p_in_dwnp_rdy_n<=i_dwnp_rdy_n when mnl_use_gen_dwnp_rdy='1' else '0';
p_in_dwnp_rdy_n<=i_srambler_out(0)when mnl_use_gen_dwnp_rdy='1' else '0';

--//Генератор сигнала p_in_dwnp_rdy_n
process(p_in_rst,p_in_clk)
begin
  if p_in_clk'event and p_in_clk='1' then
    if p_in_rst='1' then
      i_srambler_out<=srambler32_0(CONV_STD_LOGIC_VECTOR(16#52325032#, 16));
    else
      i_srambler_out<=srambler32_0(i_srambler_out(31 downto 16));
    end if;
  end if;
end process;

--//Генератор тестовых данных
adr_image_out(7 downto 0)<=tst_row_count(4 downto 0)&tst_pix_count(2 downto 0);
tst_image_out<=IMAGE_TST00(CONV_INTEGER(adr_image_out));

p_in_upp_wd<=not i_fifoin_full and i_upp_wd_en and not i_upp_wd_stop and not i_upp_frpause and not i_upp_rowpause;
process(p_in_rst,p_in_clk)
  variable GUI_line : LINE;--Строка дл_ вывода в ModelSim
begin
  if p_in_rst='1' then

    tst_frpuase_count<=(others=>'0');
    tst_rowpause_count<=(others=>'0');
    tst_vfr_count<=(others=>'0');
    tst_row_count<=(others=>'0');
    tst_pix_count<=(others=>'0');
    tst_data<=CONV_STD_LOGIC_VECTOR(16#2#, tst_data'length); --//
    tst_data_out<=(others=>'0');
    i_upp_frpause<='0';
    i_upp_rowpause<='0';
    i_upp_wd_en<='0';
    i_upp_wd_stop<='0';
    i_dwnp_rdy_n<='0';

  elsif p_in_clk'event and p_in_clk='1' then
    i_dwnp_rdy_n<=mnl_dwnp_rdy_n;

    if mnl_write_testdata='1' then
      if i_upp_frpause='1' then
        if tst_frpuase_count=tst_mnl_fr_pause then
          tst_frpuase_count<=(others=>'0');
          i_upp_frpause<='0';
        else
          tst_frpuase_count<=tst_frpuase_count + 1;
        end if;

      elsif i_upp_rowpause='1' then
        if tst_rowpause_count=tst_mnl_row_pause then
          tst_rowpause_count<=(others=>'0');
          i_upp_rowpause<='0';
        else
          tst_rowpause_count<=tst_rowpause_count + 1;
        end if;

      elsif i_upp_wd_en='1' then
        if p_in_upp_wd='1' then
          if tst_pix_count=p_in_cfg_pix_count-1 then
           tst_pix_count<=(others=>'0');
              if tst_row_count=p_in_cfg_row_count-1 then
              tst_row_count<=(others=>'0');
                  if tst_vfr_count=usr_cfg_fr_count-1 then
                    tst_row_count<=tst_row_count;
                    tst_pix_count<=tst_pix_count;
                    tst_vfr_count<=tst_vfr_count;
                    i_upp_wd_stop<='1';
                  else
                    tst_vfr_count<=tst_vfr_count + 1;
                    if tst_frpuase_count/=tst_mnl_fr_pause then
                      i_upp_frpause<='1';
                    end if;
                  end if;
              else
                tst_row_count<=tst_row_count+1;

                if tst_rowpause_count/=tst_mnl_row_pause then
                  i_upp_rowpause<='1';
                end if;
              end if;
          else
              tst_pix_count<=tst_pix_count+1;

              tst_data<=tst_data+8;
              tst_data_out(7 downto 0)  <=tst_data;
              tst_data_out(15 downto 8) <=tst_data+2;
              tst_data_out(23 downto 16)<=tst_data+4;
              tst_data_out(31 downto 24)<=tst_data+6;

          end if;--//if tst_pix_count=p_in_cfg_pix_count-1 then
        end if;--//if p_in_upp_wd='0' then
      else
        i_upp_wd_en<='1';
      end if;--//if i_upp_wd_en='0' then
    else
      i_upp_wd_en<='0';
      tst_data_out(7 downto 0)  <=tst_data;
      tst_data_out(15 downto 8) <=tst_data+2;
      tst_data_out(23 downto 16)<=tst_data+4;
      tst_data_out(31 downto 24)<=tst_data+6;
    end if;--//if mnl_write_testdata='1' then

  end if;
end process;




--//Вывод результата в консоль ModelSim:
tst_dwnp_pix_max<=((usr_cfg_pix_count(14 downto 0)&'0'))  when i_zoom_up_on='1'  and i_zoom_size_x2='1' else

                  ((usr_cfg_pix_count(13 downto 0)&"00")) when i_zoom_up_on='1'  and i_zoom_size_x4='1' else

                  (('0'&usr_cfg_pix_count(15 downto 1)))  when i_zoom_dwn_on='1' and i_zoom_size_x2='1' else

                  (("00"&usr_cfg_pix_count(15 downto 2))) when i_zoom_dwn_on='1' and i_zoom_size_x4='1' else

                  (others=>'0');

tst_dwnp_row_max<=((usr_cfg_row_count(14 downto 0)&'0'))  when i_zoom_up_on='1'  and i_zoom_size_x2='1' else

                  ((usr_cfg_row_count(13 downto 0)&"00")) when i_zoom_up_on='1'  and i_zoom_size_x4='1' else

                  (('0'&usr_cfg_row_count(15 downto 1)))  when i_zoom_dwn_on='1' and i_zoom_size_x2='1' else

                  (("00"&usr_cfg_row_count(15 downto 2))) when i_zoom_dwn_on='1' and i_zoom_size_x4='1' else

                  (others=>'0');

process(p_in_rst,p_in_clk)
  variable GUI_line : LINE;--Строка дл_ вывода в ModelSim
begin
  if p_in_rst='1' then
    tst_dwnp_pix<=(others=>'0');
    tst_dwnp_row<=(others=>'0');
    tst_dwnp_fr<=(others=>'0');
    dsize_out<='0';
  elsif p_in_clk'event and p_in_clk='1' then

    if p_out_dwnp_wd='1' and p_in_dwnp_rdy_n='0' then
        if dsize_out='0' then
          write(GUI_line, string'("Result Size: Pix("));
          write(GUI_line, itoa(CONV_INTEGER(tst_dwnp_pix_max)));--//Выдаем число в DEC
          write(GUI_line, string'(") x Line("));
          write(GUI_line, itoa(CONV_INTEGER(tst_dwnp_row_max)));--//Выдаем число в DEC
          write(GUI_line, string'(")"));
          writeline(output, GUI_line);--Выводим строку GUI_line в ModelSim
          dsize_out<='1';
        end if;

        if tst_dwnp_pix=(tst_dwnp_pix'range=>'0') then
          write(GUI_line, string'("Result: Frame("));
          write(GUI_line, itoa(CONV_INTEGER(tst_dwnp_fr)));--//Выдаем число в DEC
          write(GUI_line, string'(")"));

          write(GUI_line, string'("Line("));
          write(GUI_line, itoa(CONV_INTEGER(tst_dwnp_row)));--//Выдаем число в DEC
          write(GUI_line, string'(") "));
        end if;

        write(GUI_line, itoa(CONV_INTEGER(p_out_dwnp_data(7 downto 0))) );--//Выдаем число в DEC
        write(GUI_line, string'(","));

        write(GUI_line, itoa(CONV_INTEGER(p_out_dwnp_data(15 downto 8))) );--//Выдаем число в DEC
        write(GUI_line, string'(","));

        write(GUI_line, itoa(CONV_INTEGER(p_out_dwnp_data(23 downto 16))) );--//Выдаем число в DEC
        write(GUI_line, string'(","));

        write(GUI_line, itoa(CONV_INTEGER(p_out_dwnp_data(31 downto 24))) );--//Выдаем число в DEC
        write(GUI_line, string'(","));

        if tst_dwnp_pix=(tst_dwnp_pix_max - EXT(tst_incr, tst_dwnp_pix'length)) then
          tst_dwnp_pix<=(others=>'0');
          if tst_dwnp_row=tst_dwnp_row_max-1 then
            tst_dwnp_row<=(others=>'0');
            tst_dwnp_fr<=tst_dwnp_fr + 1;
          else
            tst_dwnp_row<=tst_dwnp_row+1;
          end if;
          writeline(output, GUI_line);--Выводим строку GUI_line в ModelSim
        else
          tst_dwnp_pix<=tst_dwnp_pix + EXT(tst_incr, tst_dwnp_pix'length);
        end if;
    end if;

  end if;
end process;

tst_incr<=("00000000"&"0000"&'0'&(not p_in_cfg_color)&'0'&(p_in_cfg_color));


--End Main
end;
