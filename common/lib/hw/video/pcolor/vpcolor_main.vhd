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
--                 Теперь:                                         а раньше было:
--                    (7..0)  =B                                   (7..0)  =R
--                    (15..8) =G                                   (15..8) =G
--                    (23..16)=R                                   (23..16)=B
--                    (31..24)=0xFF (прозрачность - альфа канал)   (31..24)=0xFF
--
-- Revision 1.00 - add 11.02.2011 18:58:37
--                 Переделал обработку входных данных.
-------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_misc.all;
use ieee.std_logic_unsigned.all;

library unisim;
use unisim.vcomponents.all;

entity vpcolor_main is
port(
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
port(
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
port(
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
port(
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


signal i_upp_rdy_n_out                   : std_logic;

signal sr_upp_data                       : std_logic_vector(31 downto 0);

signal i_byte_cnt_init                   : std_logic_vector(1 downto 0);
signal i_byte_cnt                        : std_logic_vector(1 downto 0);

signal i_result_out                      : std_logic_vector(31 downto 0);
signal i_result_en_out                   : std_logic;
signal sr_result_en                      : std_logic_vector(0 to 0);

signal i_bram_read                       : std_logic;
signal i_r_dout                          : std_logic_vector(7 downto 0);
signal i_g_dout                          : std_logic_vector(7 downto 0);
signal i_b_dout                          : std_logic_vector(7 downto 0);

signal i_coebuf_awrite                   : std_logic_vector(6 downto 0);
signal i_wr_rbuf                         : std_logic_vector(0 downto 0);
signal i_wr_gbuf                         : std_logic_vector(0 downto 0);
signal i_wr_bbuf                         : std_logic_vector(0 downto 0);
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
--    p_out_tst(0)<=;
--
--  end if;
--end process;
p_out_tst(31 downto 0)<=(others=>'0');



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
p_out_dwnp_data <=i_result_out    when p_in_cfg_bypass='0' else p_in_upp_data;
p_out_dwnp_wd   <=i_result_en_out when p_in_cfg_bypass='0' else p_in_upp_wd;


--//------------------------------------
--//Управление чтением входных данных
--//------------------------------------
process(p_in_rst,p_in_clk)
begin
  if p_in_rst='1' then
    i_upp_rdy_n_out<='0';

    i_byte_cnt<=(others=>'0');
    sr_upp_data<=(others=>'0');

  elsif p_in_clk'event and p_in_clk='1' then

    if p_in_cfg_bypass='1' then
      i_upp_rdy_n_out<='0';

    else
        --//Обработка кадра ВКЛ.
        if p_in_dwnp_rdy_n='0' then

            --//-----------------------------
            --//Обработка входных данных:
            --//-----------------------------
              if p_in_upp_wd='1' then
                --//Прием нового входного DWORD
                i_upp_rdy_n_out<='1';--//Запрещаем запись входных данных в буфер строки на
                                     --//время обработки всех байт входного DWORD

                sr_upp_data<=p_in_upp_data;

              else
                  if i_upp_rdy_n_out='1' then
                  --//Обработка байт входного DWORD
                    if i_byte_cnt=i_byte_cnt_init then
                      i_byte_cnt<=(others=>'0');
                      i_upp_rdy_n_out<='0';
                    else
                      i_byte_cnt<=i_byte_cnt+1;--//Ведем подсчет байт входного DWORD
                    end if;

                    sr_upp_data<="00000000"&sr_upp_data(31 downto 8);
                  end if;--//if i_upp_rdy_n_out='1'
              end if;--//if p_in_upp_wd='1' then


        end if;--//if p_in_dwnp_rdy_n='0' then
    end if;--//if p_in_cfg_bypass='1'then
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

        sr_result_en(0)<=i_upp_rdy_n_out;

    end if;--//if p_in_dwnp_rdy_n='0' then
  end if;
end process;


--//------------------------------------------------------
--//RAM
--//------------------------------------------------------
--//Чтение данных BRAM
i_bram_read<=not p_in_dwnp_rdy_n and i_upp_rdy_n_out;

--//Запись данных в BRAM
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
port map(
--//запись
addra=> i_coebuf_awrite,
dina => p_in_cfg_dcoe,
douta=> i_rcoe_dout,
ena  => '1',
wea  => i_wr_rbuf,
clka => p_in_cfg_coe_wrclk,
rsta => p_in_rst,

--//чтние
addrb=> sr_upp_data(7 downto 0),
dinb => "00000000",
doutb=> i_r_dout,
enb  => i_bram_read,
web  => "0",
clkb => p_in_clk,
rstb => p_in_rst
);

m_green_bram : vpcolor_gbram
port map(
--//запись
addra=> i_coebuf_awrite,
dina => p_in_cfg_dcoe,
douta=> i_gcoe_dout,
ena  => '1',
wea  => i_wr_gbuf,
clka => p_in_cfg_coe_wrclk,
rsta => p_in_rst,

--//чтние
addrb=> sr_upp_data(7 downto 0),
dinb => "00000000",
doutb=> i_g_dout,
enb  => i_bram_read,
web  => "0",
clkb => p_in_clk,
rstb => p_in_rst
);

m_blue_bram : vpcolor_bbram
port map(
--//запись
addra=> i_coebuf_awrite,
dina => p_in_cfg_dcoe,
douta=> i_bcoe_dout,
ena  => '1',
wea  => i_wr_bbuf,
clka => p_in_cfg_coe_wrclk,
rsta => p_in_rst,

--//чтние
addrb=> sr_upp_data(7 downto 0),
dinb => "00000000",
doutb=> i_b_dout,
enb  => i_bram_read,
web  => "0",
clkb => p_in_clk,
rstb => p_in_rst
);

--//Формирую результат:
--//COLOR:
--//           ALPHA     |  RED     |  GREEN   |  BLUE   |
i_result_out<="11111111" & i_r_dout & i_g_dout & i_b_dout;

i_result_en_out<=sr_result_en(0) and not p_in_dwnp_rdy_n;

--END MAIN
end behavioral;


