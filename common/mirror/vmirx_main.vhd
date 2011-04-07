-------------------------------------------------------------------------
-- Company     : Linkos
-- Engineer    : Golovachenko Victor
--
-- Create Date : 2010.07
-- Module Name : vmirx_main
--
-- Назначение/Описание :
--  Модуль реализует отзеркаливание строки видео инфомации по оси X
--
--  Если отзеркаливание ВЫКЛ. то всеравно выдача данных в выходной порт
--  идет через внутренний промежуточный буфер (m_bufline)
--
--  Натройка работы модуля:
--  1. Выбрать режим работы модуля. Порт p_in_cfg_mirx - 0/1:
--     Вкл./Выкл отзеркаливание строки видеоданных.
--  2. Назначить размер входного кадра порт p_in_cfg_pix_count
--
--
-- Revision:
-- Revision 0.01 - File Created
-- Revision 0.02 - --//add 19.01.2011 10:29:40
--                 ввел сигнал i_read_en для исправление колиизии BRAM
--                 collision detected: A write address: 0000000101, B read address: 0000000101
--                 Обнаружено при моделировании.
--                 + Легкие причесывания
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
--use work.prj_def.all;

entity vmirx_main is
port
(
-------------------------------
-- Управление
-------------------------------
p_in_cfg_mirx       : in    std_logic;                    --//1/0 - Вкл./Выкл отзеркаливание строки видеоданных
p_in_cfg_pix_count  : in    std_logic_vector(15 downto 0);--//Кол-во пиксел/4 т.к p_in_upp_data=32bit

p_out_cfg_mirx_done : out   std_logic;                    --//Обработка завершена.

--//--------------------------
--//Upstream Port (входные данные)
--//--------------------------
--p_in_upp_clk        : in    std_logic;
p_in_upp_data       : in    std_logic_vector(31 downto 0);
p_in_upp_wd         : in    std_logic;                    --//Запись данных в модуль vmirx_main.vhd
p_out_upp_rdy_n     : out   std_logic;                    --//0 - Модуль vmirx_main.vhd готов к приему данных

--//--------------------------
--//Downstream Port (результат)
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
end vmirx_main;

architecture behavioral of vmirx_main is

constant dly : time := 1 ps;

component vmirx_bram
port
(
addra: in  std_logic_vector(9 downto 0);
dina : in  std_logic_vector(31 downto 0);
douta: out std_logic_vector(31 downto 0);
ena  : in  std_logic;
wea  : in  std_logic_vector(0 downto 0);
clka : in  std_logic;
rsta : in  std_logic;

addrb: in  std_logic_vector(9 downto 0);
dinb : in  std_logic_vector(31 downto 0);
doutb: out std_logic_vector(31 downto 0);
enb  : in  std_logic;
web  : in  std_logic_vector(0 downto 0);
clkb : in  std_logic;
rstb : in  std_logic
);
end component;


signal i_upp_data                        : std_logic_vector(31 downto 0);
signal i_upp_data_swap                   : std_logic_vector(31 downto 0);
signal i_upp_wd                          : std_logic;

type fsm_state is
(
S_WRITE_BUFLINE,
S_READ_BUFLINE_SOF,
S_READ_BUFLINE,
S_READ_BUFLINE_EOF
);
signal fsm_state_cs: fsm_state;

signal i_pix_count                       : std_logic_vector(p_in_cfg_pix_count'high downto 0);
signal i_mirx_done                       : std_logic;

signal i_tmpbuf_addra                    : std_logic_vector(i_pix_count'range);--(9 downto 0);
signal i_tmpbuf_din                      : std_logic_vector(31 downto 0);
signal i_tmpbuf_dout                     : std_logic_vector(31 downto 0);
signal i_tmpbuf_dir                      : std_logic;
signal i_tmpbuf_ena                      : std_logic;
signal i_tmpbuf_enb                      : std_logic;
signal i_read_en                         : std_logic;--//add 19.01.2011 10:29:40


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


--//----------------------------------------------
--//Связь с Upstream Port
--//----------------------------------------------
i_upp_data <=p_in_upp_data;
i_upp_wd   <=p_in_upp_wd;

p_out_upp_rdy_n <=i_tmpbuf_dir;

--//-----------------------------
--//Вывод результата
--//-----------------------------
p_out_dwnp_data <=i_tmpbuf_dout;
p_out_dwnp_wd   <=not p_in_dwnp_rdy_n and i_tmpbuf_dir;


--//-----------------------------
--//Инициализация
--//-----------------------------
i_pix_count<=p_in_cfg_pix_count;


--//-----------------------------
--//Статус
--//-----------------------------
p_out_cfg_mirx_done <=i_mirx_done;


--//------------------------------------
--//Запись/Чтение Буфера строки
--//------------------------------------
process(p_in_rst,p_in_clk)
begin
  if p_in_rst='1' then

    fsm_state_cs <= S_WRITE_BUFLINE;

    i_tmpbuf_dir<='0';
    i_tmpbuf_addra<=(others=>'0');
    i_mirx_done<='1';
    i_read_en<='0';--//add 19.01.2011 10:29:40

  elsif p_in_clk'event and p_in_clk='1' then

    case fsm_state_cs is

      --//------------------------------------
      --//Запись данных строки в буфер
      --//------------------------------------
      when S_WRITE_BUFLINE =>
        i_mirx_done<='0';

        if i_upp_wd='1' then
          if i_tmpbuf_addra=i_pix_count-1 then
            if p_in_cfg_mirx='0' then
              i_tmpbuf_addra<=(others=>'0');
            end if;
            i_read_en<='1';--//add 19.01.2011 10:29:40

            fsm_state_cs <= S_READ_BUFLINE_SOF;
          else
            i_tmpbuf_addra<=i_tmpbuf_addra+1;
          end if;
        end if;

      --//------------------------------------
      --//
      --//------------------------------------
      when S_READ_BUFLINE_SOF =>
        i_tmpbuf_dir<='1';--//Переключаемся на чтение m_row_buf

        if p_in_cfg_mirx='0' then
          i_tmpbuf_addra<=i_tmpbuf_addra+1;
        else
          i_tmpbuf_addra<=i_tmpbuf_addra-1;
        end if;
        fsm_state_cs <= S_READ_BUFLINE;

      --//------------------------------------
      --//Чтение данных из буфера строки
      --//------------------------------------
      when S_READ_BUFLINE =>

        if p_in_dwnp_rdy_n='0' then

            --//Отзеркаливание по Х: ЕСТЬ
            if (p_in_cfg_mirx='0' and i_tmpbuf_addra=i_pix_count-1) or
               (p_in_cfg_mirx='1' and i_tmpbuf_addra=(i_tmpbuf_addra'range => '0')) then

              fsm_state_cs <=S_READ_BUFLINE_EOF;
            else
              if p_in_cfg_mirx='0' then
                i_tmpbuf_addra<=i_tmpbuf_addra+1;
              else
                i_tmpbuf_addra<=i_tmpbuf_addra-1;
              end if;
            end if;

        end if;

      --//------------------------------------
      --//
      --//------------------------------------
      when S_READ_BUFLINE_EOF =>
        if p_in_dwnp_rdy_n='0' then
          i_mirx_done<='1';
          i_tmpbuf_dir<='0';--/Переключаемся на Запись m_row_buf
          i_read_en<='0';--//add 19.01.2011 10:29:40
          if p_in_cfg_mirx='0' then
            i_tmpbuf_addra<=(others=>'0');
          end if;
          fsm_state_cs <= S_WRITE_BUFLINE;
        end if;
    end case;

  end if;
end process;


--//Если Отзеркаливание ЕСТЬ, то для 1Pix=8Bit
i_upp_data_swap(7 downto 0)  <=i_upp_data(31 downto 24);
i_upp_data_swap(15 downto 8) <=i_upp_data(23 downto 16);
i_upp_data_swap(23 downto 16)<=i_upp_data(15 downto 8);
i_upp_data_swap(31 downto 24)<=i_upp_data(7 downto 0);

--//Запись данных
i_tmpbuf_din<=i_upp_data_swap when p_in_cfg_mirx='1' else i_upp_data;
i_tmpbuf_ena<=not i_tmpbuf_dir and i_upp_wd;

--//Чтение данных
i_tmpbuf_enb<=(not p_in_dwnp_rdy_n or not i_tmpbuf_dir) and i_read_en;--//add 19.01.2011 10:29:40

--//БУФЕР НА СТРОКУ
m_bufline : vmirx_bram
port map
(
addra => i_tmpbuf_addra(9 downto 0),
dina  => i_tmpbuf_din,
douta => open,
ena   => i_tmpbuf_ena,
wea   => "1",
clka  => p_in_clk,
rsta  => p_in_rst,

addrb => i_tmpbuf_addra(9 downto 0),
dinb  => "00000000000000000000000000000000",
doutb => i_tmpbuf_dout,
enb   => i_tmpbuf_enb,
web   => "0",
clkb  => p_in_clk,
rstb  => p_in_rst
);


--END MAIN
end behavioral;

