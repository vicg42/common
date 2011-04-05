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

library std;
use std.textio.all;

library unisim;
use unisim.vcomponents.all;

entity vcoldemosaic_main_tb is
generic(
G_DOUT_WIDTH : integer:=8
);
end vcoldemosaic_main_tb;

architecture behavior of vcoldemosaic_main_tb is

constant i_clk_period : TIME := 6.6 ns; --150MHz


component vcoldemosaic_main
generic(
G_DOUT_WIDTH  : integer:=32;  --//Возможные значения 32, 8
G_SIM : string:="OFF"
);
port
(
-------------------------------
-- Управление
-------------------------------
p_in_cfg_bypass            : in    std_logic;
p_in_cfg_colorfst          : in    std_logic_vector(1 downto 0);
p_in_cfg_pix_count         : in    std_logic_vector(15 downto 0);
p_in_cfg_row_count         : in    std_logic_vector(15 downto 0);
p_in_cfg_init              : in    std_logic;                    --//Инициализация. Сброс счетчика адреса BRAM

--//--------------------------
--//Upstream Port
--//--------------------------
p_in_upp_data              : in    std_logic_vector(31 downto 0);
p_in_upp_wd                : in    std_logic;
p_out_upp_rdy_n            : out   std_logic;

--//--------------------------
--//Downstream Port
--//--------------------------
p_out_dwnp_data            : out   std_logic_vector(127 downto 0);
p_out_dwnp_wd              : out   std_logic;
p_in_dwnp_rdy_n            : in    std_logic;

-------------------------------
--Технологический
-------------------------------
p_out_tst                  : out   std_logic_vector(31 downto 0);

-------------------------------
--System
-------------------------------
p_in_clk            : in    std_logic;
p_in_rst            : in    std_logic
);
end component;

component sim_fifo_v00
port (
din        : IN  std_logic_VECTOR(31 downto 0);
wr_en      : IN  std_logic;

dout       : OUT std_logic_VECTOR(31 downto 0);
rd_en      : IN  std_logic;

empty      : OUT std_logic;
full       : OUT std_logic;
almost_full: OUT std_logic;

clk        : IN  std_logic;
rst        : IN  std_logic
);
end component;

signal p_in_clk                       : std_logic := '0';
signal p_in_rst                       : std_logic := '0';

signal p_in_cfg_bypass                : std_logic;
signal p_in_cfg_colorfst              : std_logic_vector(1 downto 0); --//0/1/2 - R/G/B
signal p_in_cfg_pix_count             : std_logic_vector(15 downto 0);
signal p_in_cfg_row_count             : std_logic_vector(15 downto 0);

signal tst_data_out                   : std_logic_vector(31 downto 0);
signal p_in_upp_wd                    : std_logic;
signal p_out_upp_rdy_n                : std_logic;

signal p_out_dwnp_data                : std_logic_vector(127 downto 0);
signal p_out_dwnp_wd                  : std_logic;
signal p_in_dwnp_rdy_n                : std_logic;

signal i_fifoin_dout                  : std_logic_vector(31 downto 0);
signal i_fifoin_rd                    : std_logic;
signal i_fifoin_empty                 : std_logic;
signal i_fifoin_full                  : std_logic;

signal tst_vfr_count                  : std_logic_vector(7 downto 0);
signal tst_puse_count                 : std_logic_vector(15 downto 0);
signal tst_row_count                  : std_logic_vector(15 downto 0);
signal tst_pix_count                  : std_logic_vector(15 downto 0);
signal tst_data                       : std_logic_vector(7 downto 0);
signal mnl_write_testdata             : std_logic;

signal mnl_use_gen_dwnp_rdy           : std_logic;
signal mnl_dwnp_rdy_n                 : std_logic;
signal i_dwnp_rdy_n                   : std_logic;

signal i_printf_vec                   : std_logic_vector(127 downto 0);

signal tst_dwnp_count                 : std_logic_vector(31 downto 0);
signal tst_dwnp_pix                   : std_logic_vector(p_in_cfg_pix_count'range);
signal tst_dwnp_row                   : std_logic_vector(p_in_cfg_row_count'range);
signal tst_dwnp_fr                    : std_logic_vector(31 downto 0);

signal usr_cfg_fr_count               : std_logic_vector(7 downto 0);
signal usr_cfg_pix_count              : std_logic_vector(15 downto 0);
signal usr_cfg_row_count              : std_logic_vector(15 downto 0);
signal i_upp_wd_en                    : std_logic;
signal i_upp_wd_stop                  : std_logic;

signal tst_mnl_fr_pause               : std_logic_vector(31 downto 0);
signal tst_frpuase_count              : std_logic_vector(31 downto 0);
signal i_upp_frpause                  : std_logic;
signal tst_mnl_row_pause              : std_logic_vector(31 downto 0);
signal tst_rowpause_count             : std_logic_vector(31 downto 0);
signal i_upp_rowpause                 : std_logic;

signal i_srambler_out                 : std_logic_vector(31 downto 0);

--Main
begin


m_vcoldemosaic: vcoldemosaic_main
generic map(
G_DOUT_WIDTH => G_DOUT_WIDTH,
G_SIM => "ON"
)
port map
(
-------------------------------
-- Управление
-------------------------------
p_in_cfg_bypass            => p_in_cfg_bypass,
p_in_cfg_colorfst          => p_in_cfg_colorfst,
p_in_cfg_pix_count         => p_in_cfg_pix_count,
p_in_cfg_row_count         => p_in_cfg_row_count,
p_in_cfg_init              => '0',

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
p_out_tst                  => open,

-------------------------------
--System
-------------------------------
p_in_clk            => p_in_clk,
p_in_rst            => p_in_rst
);

m_fifo_in : sim_fifo_v00
port map
(
din         => tst_data_out,
wr_en       => p_in_upp_wd,
--wr_clk      => p_in_upp_clk,

dout        => i_fifoin_dout,
rd_en       => i_fifoin_rd,
--rd_clk      => p_in_dwnp_clk,

empty       => i_fifoin_empty,
full        => open,
almost_full => i_fifoin_full,

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


--//----------------------------------------------------------
--//Настройка тестирования
--//----------------------------------------------------------
p_in_cfg_bypass<='0';--//0/1 - разрешение работы блока/1 bypss
p_in_cfg_colorfst<=CONV_STD_LOGIC_VECTOR(16#01#, p_in_cfg_colorfst'length); --//0/1/2 - R/G/B

--//Конфигурируем генератор тестровых данных:
usr_cfg_pix_count<=CONV_STD_LOGIC_VECTOR(10#08#, p_in_cfg_pix_count'length); --Тестовый кадр: SIZE-X
usr_cfg_row_count<=CONV_STD_LOGIC_VECTOR(10#08#, p_in_cfg_pix_count'length); --Тестовый кадр: SIZE-Y
usr_cfg_fr_count <=CONV_STD_LOGIC_VECTOR(16#08#, usr_cfg_fr_count'length);   --Кол-во тестовых кодров

tst_mnl_row_pause<=CONV_STD_LOGIC_VECTOR(16#00#, tst_mnl_row_pause'length);  --//Пауза между строками
tst_mnl_fr_pause <=CONV_STD_LOGIC_VECTOR(16#08#, tst_mnl_fr_pause'length);   --//Пауза между кадрами

--// 1/0 Генерировать/НЕ Гненерировать waveform для сигнала p_in_dwnp_rdy_n
mnl_use_gen_dwnp_rdy<='1';





--//----------------------------------------------------------
--//
--//----------------------------------------------------------
gen_w8 : if G_DOUT_WIDTH=8 generate
begin
p_in_cfg_pix_count<="00"&usr_cfg_pix_count(15 downto 2);   --//Кол-во пикселей
p_in_cfg_row_count<=usr_cfg_row_count;   --//Кол-во строк
end generate gen_w8;

gen_w32 : if G_DOUT_WIDTH=32 generate
begin
p_in_cfg_pix_count<=usr_cfg_pix_count;   --//Кол-во пикселей
p_in_cfg_row_count<=usr_cfg_row_count;   --//Кол-во строк
end generate gen_w32;


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
gen0_w8 : if G_DOUT_WIDTH=8 generate
begin

i_printf_vec<=p_out_dwnp_data;

process(p_in_rst,p_in_clk)
  variable GUI_line : LINE;--Строка дл_ вывода в ModelSim
begin
  if p_in_rst='1' then
    tst_dwnp_pix<=(others=>'0');
    tst_dwnp_row<=(others=>'0');
    tst_dwnp_fr<=(others=>'0');
  elsif p_in_clk'event and p_in_clk='1' then

    if p_out_dwnp_wd='1' and p_in_dwnp_rdy_n='0' then
        if tst_dwnp_pix=(tst_dwnp_pix'range=>'0') then
          write(GUI_line, string'("Result: Frame("));
          write(GUI_line, itoa(CONV_INTEGER(tst_dwnp_fr)));--//Выдаем число в DEC
          write(GUI_line, string'(")"));

          write(GUI_line, string'("Line("));
          write(GUI_line, itoa(CONV_INTEGER(tst_dwnp_row)));--//Выдаем число в DEC
          write(GUI_line, string'(") "));
        end if;

        write(GUI_line, itoa(CONV_INTEGER(i_printf_vec(7 downto 0))));--//Выдаем число в DEC
        write(GUI_line, string'(","));
        write(GUI_line, itoa(CONV_INTEGER(i_printf_vec(15 downto 8))));--//Выдаем число в DEC
        write(GUI_line, string'(","));
        write(GUI_line, itoa(CONV_INTEGER(i_printf_vec(23 downto 16))));--//Выдаем число в DEC
        write(GUI_line, string'(","));
        write(GUI_line, itoa(CONV_INTEGER(i_printf_vec(31 downto 24))));--//Выдаем число в DEC
        write(GUI_line, string'(","));

        if tst_dwnp_pix=((p_in_cfg_pix_count(13 downto 0)&"00")-1) then
          tst_dwnp_pix<=(others=>'0');
          if tst_dwnp_row=p_in_cfg_row_count-1 then
            tst_dwnp_row<=(others=>'0');
            tst_dwnp_fr<=tst_dwnp_fr + 1;
          else
            tst_dwnp_row<=tst_dwnp_row+1;
          end if;
          writeline(output, GUI_line);--Выводим строку GUI_line в ModelSim
        else
          tst_dwnp_pix<=tst_dwnp_pix+1;
        end if;
    end if;

  end if;
end process;

end generate gen0_w8;

gen0_w32 : if G_DOUT_WIDTH=32 generate
begin

i_printf_vec<=p_out_dwnp_data;

process(p_in_rst,p_in_clk)
  variable GUI_line : LINE;--Строка дл_ вывода в ModelSim
begin
  if p_in_rst='1' then
    tst_dwnp_pix<=(others=>'0');
    tst_dwnp_row<=(others=>'0');
    tst_dwnp_fr<=(others=>'0');
  elsif p_in_clk'event and p_in_clk='1' then

    if p_out_dwnp_wd='1' and p_in_dwnp_rdy_n='0' then
        if tst_dwnp_pix=(tst_dwnp_pix'range=>'0') then
          write(GUI_line, string'("Result: Frame("));
          write(GUI_line, itoa(CONV_INTEGER(tst_dwnp_fr)));--//Выдаем число в DEC
          write(GUI_line, string'(")"));

          write(GUI_line, string'("Line("));
          write(GUI_line, itoa(CONV_INTEGER(tst_dwnp_row)));--//Выдаем число в DEC
          write(GUI_line, string'(") "));

        end if;

        write(GUI_line, itoa(CONV_INTEGER(i_printf_vec(7 downto 0))));--//Выдаем число в DEC
        write(GUI_line, string'(","));
        write(GUI_line, itoa(CONV_INTEGER(i_printf_vec(15 downto 8))));--//Выдаем число в DEC
        write(GUI_line, string'(","));
        write(GUI_line, itoa(CONV_INTEGER(i_printf_vec(23 downto 16))));--//Выдаем число в DEC
        write(GUI_line, string'(","));
        write(GUI_line, itoa(CONV_INTEGER(i_printf_vec(31 downto 24))));--//Выдаем число в DEC
        write(GUI_line, string'(","));

        write(GUI_line, itoa(CONV_INTEGER(i_printf_vec(39 downto 32))));--//Выдаем число в DEC
        write(GUI_line, string'(","));
        write(GUI_line, itoa(CONV_INTEGER(i_printf_vec(47 downto 40))));--//Выдаем число в DEC
        write(GUI_line, string'(","));
        write(GUI_line, itoa(CONV_INTEGER(i_printf_vec(55 downto 48))));--//Выдаем число в DEC
        write(GUI_line, string'(","));
        write(GUI_line, itoa(CONV_INTEGER(i_printf_vec(63 downto 56))));--//Выдаем число в DEC
        write(GUI_line, string'(","));

        write(GUI_line, itoa(CONV_INTEGER(i_printf_vec(71 downto 64))));--//Выдаем число в DEC
        write(GUI_line, string'(","));
        write(GUI_line, itoa(CONV_INTEGER(i_printf_vec(79 downto 72))));--//Выдаем число в DEC
        write(GUI_line, string'(","));
        write(GUI_line, itoa(CONV_INTEGER(i_printf_vec(87 downto 80))));--//Выдаем число в DEC
        write(GUI_line, string'(","));
        write(GUI_line, itoa(CONV_INTEGER(i_printf_vec(95 downto 88))));--//Выдаем число в DEC
        write(GUI_line, string'(","));

        write(GUI_line, itoa(CONV_INTEGER(i_printf_vec(103 downto 96))));--//Выдаем число в DEC
        write(GUI_line, string'(","));
        write(GUI_line, itoa(CONV_INTEGER(i_printf_vec(111 downto 104))));--//Выдаем число в DEC
        write(GUI_line, string'(","));
        write(GUI_line, itoa(CONV_INTEGER(i_printf_vec(119 downto 112))));--//Выдаем число в DEC
        write(GUI_line, string'(","));
        write(GUI_line, itoa(CONV_INTEGER(i_printf_vec(127 downto 120))));--//Выдаем число в DEC
        write(GUI_line, string'(","));

--        if tst_dwnp_pix=((p_in_cfg_pix_count(13 downto 0)&"00")-1) then
        if tst_dwnp_pix=p_in_cfg_pix_count-1 then
          tst_dwnp_pix<=(others=>'0');
          if tst_dwnp_row=p_in_cfg_row_count-1 then
            tst_dwnp_row<=(others=>'0');
            tst_dwnp_fr<=tst_dwnp_fr + 1;
          else
            tst_dwnp_row<=tst_dwnp_row+1;
          end if;
          writeline(output, GUI_line);--Выводим строку GUI_line в ModelSim
        else
          tst_dwnp_pix<=tst_dwnp_pix+1;
        end if;
    end if;

  end if;
end process;

end generate gen0_w32;


--End Main
end;
