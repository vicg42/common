-------------------------------------------------------------------------
-- Company     : Linkos
-- Engineer    : Golovachenko Victor
--
-- Create Date : 25.11.2008 18:38
-- Module Name : vpcolor_main_tb
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

entity vpcolor_main_tb is
end vpcolor_main_tb;

architecture behavior of vpcolor_main_tb is

constant i_clk_period : TIME := 6.6 ns; --150MHz

component vpcolor_main
port
(
-------------------------------
-- Управление
-------------------------------
p_in_cfg_bypass            : in    std_logic;

p_in_cfg_coeram_num        : in    std_logic_vector(1 downto 0);
p_in_cfg_acoe              : in    std_logic_vector(6 downto 0);
p_in_cfg_acoe_ld           : in    std_logic;
p_in_cfg_dcoe              : in    std_logic_vector(15 downto 0);
p_out_cfg_dcoe             : out   std_logic_vector(15 downto 0);
p_in_cfg_dcoe_wr           : in    std_logic;
p_in_cfg_dcoe_rd           : in    std_logic;
p_in_cfg_coe_wrclk         : in    std_logic;

--//--------------------------
--//Upstream Port
--//--------------------------
--p_in_upp_clk               : in    std_logic;
p_in_upp_data              : in    std_logic_vector(31 downto 0);
p_in_upp_wd                : in    std_logic;
p_out_upp_rdy_n            : out   std_logic;

--//--------------------------
--//Downstream Port
--//--------------------------
--p_in_dwnp_clk              : in    std_logic;
p_out_dwnp_data            : out   std_logic_vector(31 downto 0);
p_out_dwnp_wd              : out   std_logic;
p_in_dwnp_rdy_n            : in    std_logic;

-------------------------------
--Технологический
-------------------------------
p_out_tst                  : out   std_logic_vector(7 downto 0);

-------------------------------
--System
-------------------------------
p_in_clk            : in    std_logic;
p_in_rst            : in    std_logic
);
end component;

component vpcolor_fifo
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

signal p_in_cfg_coeram_num            : std_logic_vector(1 downto 0);
signal p_in_cfg_acoe                  : std_logic_vector(6 downto 0);
signal p_in_cfg_acoe_ld               : std_logic;
signal p_in_cfg_dcoe                  : std_logic_vector(15 downto 0);
signal p_out_cfg_dcoe                 : std_logic_vector(15 downto 0);
signal p_in_cfg_dcoe_wr               : std_logic;
signal p_in_cfg_dcoe_rd               : std_logic;
signal p_in_cfg_coe_wrclk             : std_logic;

signal tst_data_out                   : std_logic_vector(31 downto 0);
signal p_in_upp_wd                    : std_logic;
signal p_out_upp_rdy_n                : std_logic;

signal p_out_dwnp_data                : std_logic_vector(31 downto 0);
signal p_out_dwnp_wd                  : std_logic;
signal p_in_dwnp_rdy_n                : std_logic;

signal tst_mnl_pix_count              : std_logic_vector(15 downto 0);
signal tst_mnl_row_count              : std_logic_vector(15 downto 0);
signal tst_mnl_puase_count            : std_logic_vector(15 downto 0);

signal tst_stop                       : std_logic;
signal tst_puse_count                 : std_logic_vector(15 downto 0);
signal tst_row_count                  : std_logic_vector(15 downto 0);
signal tst_pix_count                  : std_logic_vector(15 downto 0);
signal tst_data                       : std_logic_vector(7 downto 0);
signal mnl_write_testdata             : std_logic;

signal tst_mnl_coe_count              : std_logic_vector(7 downto 0);
signal tst_coe_count                  : std_logic_vector(7 downto 0);
signal mnl_write_coedata              : std_logic;
signal mnl_dwnp_rdy_n                 : std_logic;

signal i_fifo_result_dout             : std_logic_vector(31 downto 0);
signal i_fifo_result_rd               : std_logic;
signal i_fifo_result_empty            : std_logic;
signal i_fifo_result_full             : std_logic;
signal mnl_fifo_result_rd             : std_logic;

signal tmp_cfg_dcoe_wr                : std_logic;

signal i_sel_coe_dw                   : std_logic;
signal i_dwnp_rdy_n                   : std_logic;

signal tst_dwnp_count                 : std_logic_vector(31 downto 0);

--Main
begin



m_vpcolor: vpcolor_main
port map
(
-------------------------------
-- Управление
-------------------------------
p_in_cfg_bypass            => p_in_cfg_bypass,

p_in_cfg_coeram_num        => p_in_cfg_coeram_num,
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
p_in_upp_data              => tst_data_out,
p_in_upp_wd                => p_in_upp_wd,
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

m_fifo_result : vpcolor_fifo
port map
(
din         => p_out_dwnp_data,
wr_en       => p_out_dwnp_wd,
--wr_clk      => p_in_upp_clk,

dout        => i_fifo_result_dout,
rd_en       => i_fifo_result_rd,
--rd_clk      => p_in_dwnp_clk,

empty       => i_fifo_result_empty,
full        => open,
almost_full => i_fifo_result_full,

clk         => p_in_clk,
rst         => p_in_rst
);

clk_in_generator : process
begin
  p_in_clk<='0';
  wait for i_clk_period/2;
  p_in_clk<='1';
  wait for i_clk_period/2;
end process;


p_in_rst<='1','0' after 1 us;

p_in_cfg_bypass<='0';--//0/1 - Инткрполяция/1 дулирование


--//Конфигурируем генератор тестровых данных:
tst_mnl_pix_count  <=CONV_STD_LOGIC_VECTOR(16#08#, tst_mnl_pix_count'length);   --//Кол-во пикселей
tst_mnl_row_count  <=CONV_STD_LOGIC_VECTOR(16#02#, tst_mnl_row_count'length);   --//Кол-во строк
tst_mnl_puase_count<=CONV_STD_LOGIC_VECTOR(16#0#, tst_mnl_puase_count'length); --//Пауза между строками


--//Загрузка BRAM коэфициентами
tst_mnl_coe_count <=CONV_STD_LOGIC_VECTOR(10#128#, tst_mnl_coe_count'length); --//

--p_in_dwnp_rdy_n<='0';--
p_in_dwnp_rdy_n<=i_dwnp_rdy_n;--
--p_in_dwnp_rdy_n<=i_fifo_result_full;

p_in_cfg_coeram_num<=CONV_STD_LOGIC_VECTOR(10#00#, p_in_cfg_coeram_num'length); --//

mnl_write_coedata <='0','0' after 1.5 us;
mnl_write_testdata<='0','1' after 2.5 us;


p_in_cfg_acoe    <=(others=>'0');
p_in_cfg_acoe_ld <='0';
p_in_cfg_dcoe_rd <='0';
p_in_cfg_coe_wrclk<=p_in_clk;

mnl_dwnp_rdy_n<='0',
                '1' after 2.5 us, '0' after 2.65654 us,
                '1' after 2.685 us, '1' after 2.6987 us,
                '1' after 2.8 us, '0' after 2.987 us,
                '1' after 3.0 us, '0' after 3.1234 us,
                '1' after 3.3 us, '0' after 3.68 us,
                '1' after 3.698 us, '0' after 3.7008 us,
                '1' after 3.71234 us, '0' after 3.71456 us,
                '1' after 3.91 us,'0' after 3.96 us,
                '1' after 4.0 us, '0' after 4.0678 us;

mnl_fifo_result_rd<='0',
                     '1' after 3.1 us, '0' after 3.15654 us,
                     '1' after 3.285 us, '1' after 3.2987 us,
                     '1' after 3.8 us, '0' after 3.987 us,
                     '1' after 4.0 us, '0' after 4.1234 us;

--//Генератор тестовых данных
process(p_in_rst,p_in_clk)
  variable GUI_line : LINE;--Строка дл_ вывода в ModelSim
begin
  if p_in_rst='1' then
    tst_stop<='0';
    tst_row_count<=(others=>'0');
    tst_puse_count<=(others=>'0');
    tst_pix_count<=(others=>'0');
    tst_data<=CONV_STD_LOGIC_VECTOR(16#8#, tst_data'length); --//
    tst_data_out<=(others=>'0');
    p_in_upp_wd<='0';
    i_dwnp_rdy_n<='0';
    i_fifo_result_rd<='0';
  elsif p_in_clk'event and p_in_clk='1' then
    i_dwnp_rdy_n<=mnl_dwnp_rdy_n;

    i_fifo_result_rd<=mnl_fifo_result_rd and not i_fifo_result_empty;

    if mnl_write_testdata='1' then

      if p_out_upp_rdy_n='0' then

        if tst_pix_count=tst_mnl_pix_count then
--          tst_data<=CONV_STD_LOGIC_VECTOR(16#0#, tst_data'length); --//

          if tst_row_count=tst_mnl_row_count-1 then
            p_in_upp_wd<='0';
          else
            if tst_puse_count=tst_mnl_puase_count then
              tst_row_count<=tst_row_count+1;
              tst_pix_count<=(others=>'0');
              tst_puse_count<=(others=>'0');
            else
              p_in_upp_wd<='0';
              tst_puse_count<=tst_puse_count+1;
            end if;
          end if;

        else
          tst_pix_count<=tst_pix_count+1;
          p_in_upp_wd<='1';

--          tst_data<=tst_data+4;
--          tst_data_out(7 downto 0)  <=tst_data;
--          tst_data_out(15 downto 8) <=tst_data+1;
--          tst_data_out(23 downto 16)<=tst_data+2;
--          tst_data_out(31 downto 24)<=tst_data+3;

          tst_data<=tst_data+8;
          tst_data_out(7 downto 0)  <=tst_data;
          tst_data_out(15 downto 8) <=tst_data+2;
          tst_data_out(23 downto 16)<=tst_data+4;
          tst_data_out(31 downto 24)<=tst_data+6;

--          write(GUI_line, string'("TEST DATA 2DW ("));
--          hwrite(GUI_line, tst_dwnp_count);
--          write(GUI_line, string'(") : 0x"));
--          hwrite(GUI_line, tst_data_out);
--          writeline(output, GUI_line);--Выводим строку GUI_line в ModelSim

        end if;
      else
        p_in_upp_wd<='0';
      end if;
    else
      p_in_upp_wd<='0';
    end if;
  end if;
end process;


--//Запись коэфициентов в RAM модуля
process(p_in_rst,p_in_clk)
  variable GUI_line : LINE;--Строка дл_ вывода в ModelSim
  variable var_trig : std_logic;
begin
  if p_in_rst='1' then
    tst_coe_count<=(others=>'0');
    p_in_cfg_dcoe<=(others=>'0');
    p_in_cfg_dcoe_wr<='0';
    tmp_cfg_dcoe_wr<='0';

    var_trig:='0';
    i_sel_coe_dw<='0';
  elsif p_in_clk'event and p_in_clk='1' then
    if mnl_write_coedata='1' then

      if tst_coe_count=tst_mnl_coe_count then
        p_in_cfg_dcoe_wr<='0';
      else

        tmp_cfg_dcoe_wr<='1';

        if tmp_cfg_dcoe_wr='1' then
          p_in_cfg_dcoe_wr<='1';
          var_trig:=not var_trig;
          i_sel_coe_dw<=var_trig;
        end if;

          p_in_cfg_dcoe<=p_in_cfg_dcoe+1;

          tst_coe_count<=tst_coe_count+1;

          write(GUI_line, string'("COE 2DW ("));
          hwrite(GUI_line, tst_coe_count);
          write(GUI_line, string'(") : 0x"));
          hwrite(GUI_line, p_in_cfg_dcoe);
          writeline(output, GUI_line);--Выводим строку GUI_line в ModelSim
      end if;


    end if;
  end if;
end process;



process(p_in_rst,p_in_clk)
  variable GUI_line : LINE;--Строка дл_ вывода в ModelSim
begin
  if p_in_rst='1' then
    tst_dwnp_count<=(others=>'0');
  elsif p_in_clk'event and p_in_clk='1' then

--    if p_out_dwnp_wd='1' then
--        tst_dwnp_count<=tst_dwnp_count+1;
--
--        write(GUI_line, string'("Result 2DW ("));
--        hwrite(GUI_line, tst_dwnp_count);
--        write(GUI_line, string'(") : 0x"));
--        hwrite(GUI_line, p_out_dwnp_data);
--        writeline(output, GUI_line);--Выводим строку GUI_line в ModelSim
--
--    end if;

    if i_fifo_result_rd='1' then
        tst_dwnp_count<=tst_dwnp_count+1;

        write(GUI_line, string'("Result 2DW ("));
        hwrite(GUI_line, tst_dwnp_count);
        write(GUI_line, string'(") : 0x"));
        hwrite(GUI_line, i_fifo_result_dout);
        writeline(output, GUI_line);--Выводим строку GUI_line в ModelSim

    end if;

  end if;
end process;

--End Main
end;
