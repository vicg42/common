-------------------------------------------------------------------------
-- Company     : Linkos
-- Engineer    : Golovachenko Victor
--
-- Create Date : 2010.07
-- Module Name : vscaler_main
--
-- Назначение/Описание :
--  Модуль принимает входное изображения (Upstream Port),
--  производит масштабирование(Управление/Конфигурирование) и
--  выдает преобразовное изображение в выходной порт (Downstream Port)
--
--  Upstream Port(Вх. данные)
--  Downstream Port(Вых. данные)
--
--  Краевые эфекты только в случае увеличения со сглаживанием:
--    x2 - первых 2-а пикселя в строке + 2-е первые строки
--    x4 - первых 4-е пикселя в строке + 4-е первые строки
--  выходных данных
--
--  Натройка работы модуля:
--  1. Выбрать режим работы модуля. Порт p_in_cfg_bypass - 0/1:
--     Upstream Port -> Downstream Port Обрабатывать/Не обрабатывать
--  2. Назначить размер входного кадра порты p_in_cfg_pix_count/p_in_cfg_row_count
--  3. Выбор типа сглаживания (Билинейная интерполяция/ Дублирование пиксел)
--     порт p_in_cfg_zoom_type
--  4. Выбор Масштаба порт p_in_cfg_zoom - UP: x2,x4; DOWN: x2,x4 или Bypass: 1:1
--
--  Формат входных/выходных данных:
--  Frame - Gray                              Frame - Color
--    p_in_upp_data(7...0) ----- Pix(N)         p_in_upp_data(7...0) ----- R
--    p_in_upp_data(15...8) ---- Pix(N+1)       p_in_upp_data(15...8) ---- G
--    p_in_upp_data(23...16) --- Pix(N+2)       p_in_upp_data(23...16) --- B
--    p_in_upp_data(31...24) --- Pix(N+3)       p_in_upp_data(31...24) --- 0xFF
--
--  Интерполяция:
--  ZoomUp x2:          ZoomUp x4:
--  01 02 01            01 02 03 04 03 02 01
--  02 04 02  x  1/4    02 04 06 08 06 04 02
--  01 02 01            03 06 09 12 09 06 03
--                      04 08 12 16 12 08 04  x  1/16
--                      03 06 09 12 09 06 03
--                      02 04 06 08 06 04 02
--                      01 02 03 04 03 02 01
--
-- ВАЖНО!!!: Значачения подоваемые на p_in_cfg_pix_count
--           обрабатываемый кадр (Gray), p_in_cfg_pix_count = (Кол-во пиксел в строке входного кадра) /4
--           обрабатываемый кадр (Color), p_in_cfg_pix_count = (Кол-во пиксел в строке входного кадра)
--
-- Revision:
-- Revision 0.01 - File Created (Реализация Интерполяции желает лучшего!!!!)
-- Revision 2.00 - add 30.11.10
--                 Пределал проект. За основу взята rev 0.01, но доработана с
--                 учетом примера от Xilix s3esk_video_line_stores.pdf (см. какалог ..\Scaler\doc)
--                 Добавил работу с цветом.
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

entity vscaler_main is
generic(
G_USE_COLOR : string:="OFF"  --//Если "OFF", то использование порта p_in_cfg_color ЗАПРЕЩЕНО!!!,т.е
                             --//должен быть p_in_cfg_color='0'
                             --//Кроме того Режим "ON" использут больше ресурсов FPGA чем режим "OFF"
);
port
(
-------------------------------
-- Управление
-------------------------------
--//Конфигурирование
p_in_cfg_color      : in    std_logic;                    --//1 - работа с цветным кадром.
p_in_cfg_zoom_type  : in    std_logic;                    --//0/1 - Инткрполяция/ дублирование
p_in_cfg_zoom       : in    std_logic_vector(3 downto 0); --//(3 downto 2): 0/1/2 - bypass/ZoomDown/ZoomUp
                                                          --//(1 downto 0): 1/2 - x2/x4
p_in_cfg_pix_count  : in    std_logic_vector(15 downto 0);--//
p_in_cfg_row_count  : in    std_logic_vector(15 downto 0);--//
p_in_cfg_init       : in    std_logic;                    --//Инициализация. Сброс счетчика адреса BRAM

--//Статус
p_out_cfg_zoom_done : out   std_logic;                    --//Масштабирование выполнено

--//Доступ к RAM коэфициентов
p_in_cfg_acoe       : in    std_logic_vector(8 downto 0); --//Адрес COERAM
p_in_cfg_acoe_ld    : in    std_logic;                    --//Установка адреса
p_in_cfg_dcoe       : in    std_logic_vector(15 downto 0);--//Данные
p_out_cfg_dcoe      : out   std_logic_vector(15 downto 0);
p_in_cfg_dcoe_wr    : in    std_logic;                    --//Запись в COERAM
p_in_cfg_dcoe_rd    : in    std_logic;                    --//Чтение из COERAM
p_in_cfg_coe_wrclk  : in    std_logic;

--//--------------------------
--//Upstream Port (Связь с источником данных)
--//--------------------------
--p_in_upp_clk        : in    std_logic;
p_in_upp_data       : in    std_logic_vector(31 downto 0);
p_in_upp_wd         : in    std_logic;
p_out_upp_rdy_n     : out   std_logic;                    --//0/1 - Модуль готов принимать вх. данные/ Не готов к приему вх. данных

--//--------------------------
--//Downstream Port (Связь с приемником данных)
--//--------------------------
--p_in_dwnp_clk       : in    std_logic;
p_out_dwnp_data     : out   std_logic_vector(31 downto 0);
p_out_dwnp_wd       : out   std_logic;
p_in_dwnp_rdy_n     : in    std_logic;                    --//0/1 - Принимающая сторона готова к приему данных/ НЕ готова

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
end vscaler_main;

architecture behavioral of vscaler_main is

constant C_VSACL_ZOOM_SIZE_x2  : std_logic_vector(1 downto 0):="01";
constant C_VSACL_ZOOM_SIZE_x4  : std_logic_vector(1 downto 0):="10";

constant C_VSACL_CALC_LINE_COUNT     : integer:=4;

constant C_VSACL_MATRIX_COUNT        : integer:=selval(10#03#,10#01#, strcmp(G_USE_COLOR,"ON"));--//ON/OFF - 3/1
constant C_VSACL_SR_BLINE_DLY_DWIDTH : integer:=(8 * C_VSACL_MATRIX_COUNT);

constant dly : time := 1 ps;

component vscale_bram
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

component vscale_bram_coef
port (
addra: in  std_logic_vector(5 downto 0);--(8 downto 0);
dina : in  std_logic_vector(15 downto 0);
douta: out std_logic_vector(15 downto 0);
ena  : in  std_logic;
wea  : in  std_logic_vector(0 downto 0);
clka : in  std_logic;
rsta : in  std_logic;

addrb: in  std_logic_vector(4 downto 0);--(7 downto 0);
dinb : in  std_logic_vector(31 downto 0);
doutb: out std_logic_vector(31 downto 0);
enb  : in  std_logic;
web  : in  std_logic_vector(0 downto 0);
clkb : in  std_logic;
rstb : in  std_logic
);
end component;

--signal i_clk                             : std_logic;
signal i_upp_rdy_n_out                   : std_logic;

signal i_coebuf_awrite                   : std_logic_vector(5 downto 0);--(8 downto 0);
signal i_coebuf_wr                       : std_logic_vector(0 downto 0);
signal i_coebuf_aread                    : std_logic_vector(4 downto 0);--(7 downto 0);
signal i_coebuf_rd                       : std_logic;
signal i_coebuf_dout                     : std_logic_vector(31 downto 0);
signal tmp_coebuf_dout                   : std_logic_vector(31 downto 0);

signal i_lbufs_adra                      : std_logic_vector(9 downto 0);
type TArryLBufByte is array (0 to C_VSACL_CALC_LINE_COUNT-1) of std_logic_vector(31 downto 0);
type TArryLBufByte2 is array (1 to C_VSACL_CALC_LINE_COUNT-1) of std_logic_vector(31 downto 0);
signal i_lbufs_douta                     : TArryLBufByte;
signal i_lbufs_doutb                     : TArryLBufByte2;
signal i_lbufs_dout                      : TArryLBufByte;
signal i_lbuf_ena                        : std_logic_vector(0 downto 0);
signal i_lbuf_enb                        : std_logic;
signal tmp_lbuf_ena                      : std_logic;
signal tmp_lbuf_enb                      : std_logic;

signal i_zoom_up_on                      : std_logic;
signal i_zoom_dwn_on                     : std_logic;
signal i_cfg_bypass                      : std_logic;
signal i_zoom_size                       : std_logic_vector(1 downto 0);
signal i_zoom_size_x2                    : std_logic;
signal i_zoom_size_x4                    : std_logic;
signal i_zoom_work_done_out              : std_logic;

signal i_zoom_cnt_init                   : std_logic_vector(1 downto 0);
signal i_zoom_cnt_pix                    : std_logic_vector(1 downto 0);
signal i_zoom_cnt_row                    : std_logic_vector(1 downto 0);

signal i_byte_cnt_init                   : std_logic_vector(1 downto 0);
signal i_byte_cnt                        : std_logic_vector(i_byte_cnt_init'range);
signal i_pix_cnt                         : std_logic_vector(p_in_cfg_pix_count'length-1 downto 0);
signal i_row_cnt                         : std_logic_vector(1 downto 0);--std_logic_vector(p_in_cfg_row_count'length-1 downto 0);

signal sr_byteline_ld                    : std_logic_vector(0 to 0);
signal sr_byteline_en                    : std_logic_vector(0 to 0);

type TSrByte is array (C_VSACL_CALC_LINE_COUNT-1 downto 0) of std_logic_vector(7 downto 0);
type TSrLine is array (0 to C_VSACL_CALC_LINE_COUNT-1) of TSrByte;
signal sr_byteline                       : TSrLine;
type TSrAByte is array (0 to C_VSACL_CALC_LINE_COUNT-2) of std_logic_vector(C_VSACL_SR_BLINE_DLY_DWIDTH-1 downto 0);
type TSrALine is array (0 to C_VSACL_CALC_LINE_COUNT-1) of TSrAByte;
signal sr_byteline_dly                   : TSrALine;
type TSrALineFst is array (0 to C_VSACL_CALC_LINE_COUNT-1) of std_logic_vector(C_VSACL_SR_BLINE_DLY_DWIDTH-1 downto 0);
signal sr_byteline_dlyfst                : TSrALineFst;

type TArrayPixs is array (0 to C_VSACL_CALC_LINE_COUNT-1) of std_logic_vector(7 downto 0);
type TMatrix is array (0 to C_VSACL_CALC_LINE_COUNT-1) of TArrayPixs;
type TMatrixs is array (0 to C_VSACL_MATRIX_COUNT-1) of TMatrix;
signal i_matrix                          : TMatrixs;

type TCalc16 is array (0 to C_VSACL_MATRIX_COUNT-1) of std_logic_vector(15 downto 0);
type TCalc8 is array (0 to C_VSACL_MATRIX_COUNT-1) of std_logic_vector(7 downto 0);
type TCalc9 is array (0 to C_VSACL_MATRIX_COUNT-1) of std_logic_vector(8 downto 0);
type TCalc10 is array (0 to C_VSACL_MATRIX_COUNT-1) of std_logic_vector(9 downto 0);
type TCalc11 is array (0 to C_VSACL_MATRIX_COUNT-1) of std_logic_vector(10 downto 0);
signal i_pix0_line0_mult                 : TCalc16;
signal i_pix1_line0_mult                 : TCalc16;
signal i_pix2_line0_dly                  : TCalc8;
signal i_pix3_line0_dly                  : TCalc8;

signal i_pix0_line1_mult                 : TCalc16;
signal i_pix1_line1_mult                 : TCalc16;
signal i_pix2_line1_dly                  : TCalc8;
signal i_pix3_line1_dly                  : TCalc8;

signal i_pix0_line2_dly                  : TCalc8;
signal i_pix1_line2_dly                  : TCalc8;
signal i_pix2_line2_dly                  : TCalc8;
signal i_pix3_line2_dly                  : TCalc8;

signal i_pix0_line3_dly                  : TCalc8;
signal i_pix1_line3_dly                  : TCalc8;
signal i_pix2_line3_dly                  : TCalc8;
signal i_pix3_line3_dly                  : TCalc8;

signal i_pix01_sum_line0                 : TCalc16;
signal i_pix01_sum_line1                 : TCalc16;
signal i_pix01_sum_line2                 : TCalc9;
signal i_pix01_sum_line3                 : TCalc9;

signal i_pix23_sum_line0                 : TCalc9;
signal i_pix23_sum_line1                 : TCalc9;
signal i_pix23_sum_line2                 : TCalc9;
signal i_pix23_sum_line3                 : TCalc9;

signal i_pix01_line01_sum                : TCalc16;
signal i_pix01_line01_sum_dly1           : TCalc16;
signal i_pix01_line01_sum_dly2           : TCalc16;
signal i_pix01_line23_sum                : TCalc10;

signal i_pix23_line01_sum                : TCalc10;
signal i_pix23_line23_sum                : TCalc10;

signal i_pix0123_line01_sum              : TCalc16;
signal i_pix0123_line23_sum              : TCalc11;

signal i_pix0123_line0123_sum            : TCalc16;

signal i_mcalc_result_sum                : TCalc16;
signal i_mcalc_result                    : TCalc16;
signal i_mcalc_result_out                : std_logic_vector(31 downto 0):=(others=>'0');

signal sr_result_en_fst                  : std_logic;
signal sr_result_en                      : std_logic_vector(0 to 7);
signal sr_result_en2                     : std_logic_vector(0 to 1);

signal sr_result_byte_fst                : std_logic_vector(1 downto 0);
type TSrResultByte is array (0 to 7) of std_logic_vector(1 downto 0);
signal sr_result_byte                    : TSrResultByte;
signal sr_result_byte_en_fst             : std_logic;
signal sr_result_byte_en                 : std_logic_vector(0 to 7);

signal i_result_out                      : std_logic_vector(31 downto 0);
signal i_result_en_out                   : std_logic;

type TDbgSrPix is array (0 to 6) of std_logic_vector(7 downto 0);
type TDbgSrPixs is array (0 to C_VSACL_MATRIX_COUNT-1) of TDbgSrPix;
signal dbg_sr_pix                       : TDbgSrPixs;



--MAIN
begin



--//----------------------------------
--//Технологические сигналы
--//----------------------------------
process(p_in_rst,p_in_clk)
begin
  if p_in_rst='1' then
    p_out_tst(31 downto 1)<=(others=>'0');
  elsif p_in_clk'event and p_in_clk='1' then

    for i in 0 to C_VSACL_MATRIX_COUNT-1 loop
    p_out_tst(0)<=OR_reduce(dbg_sr_pix(i)(6));
    end loop;
--
--    p_out_tst(1)<='0';

  end if;
end process;
--p_out_tst(31 downto 0)<=(others=>'0');



p_out_cfg_zoom_done<='0';--i_zoom_work_done_out;


--//----------------------------------------------
--//Связь с Upstream Port
--//----------------------------------------------
p_out_upp_rdy_n <=p_in_dwnp_rdy_n or OR_reduce(i_zoom_cnt_row) or i_upp_rdy_n_out;-- when i_cfg_bypass='0' else p_in_dwnp_rdy_n;


--//-----------------------------
--//Вывод результата
--//-----------------------------
--add 2010.11.10
p_out_dwnp_data <=EXT(i_result_out, p_out_dwnp_data'length) when i_cfg_bypass='0' else p_in_upp_data;
p_out_dwnp_wd   <=i_result_en_out when i_cfg_bypass='0' else p_in_upp_wd;



--//-----------------------------
--//Инициализация
--//-----------------------------
i_zoom_up_on  <=p_in_cfg_zoom(3);
i_zoom_dwn_on <=p_in_cfg_zoom(2);
i_cfg_bypass <=not OR_reduce(p_in_cfg_zoom(3 downto 2));

i_zoom_size<=p_in_cfg_zoom(1 downto 0);

i_zoom_size_x2<='1' when i_zoom_size=C_VSACL_ZOOM_SIZE_x2 else '0';
i_zoom_size_x4<='1' when i_zoom_size=C_VSACL_ZOOM_SIZE_x4 else '0';

i_zoom_cnt_init<="11" when i_zoom_up_on='1' and i_zoom_size_x4='1' else
                 "01" when i_zoom_up_on='1' and i_zoom_size_x2='1' else
                 "00";

--i_byte_cnt_init<="11" when p_in_cfg_color='0' else (others=>'0');--//Счетчик байт. Необходим для опреденения байта в DW
i_byte_cnt_init(0)<=not p_in_cfg_color;
i_byte_cnt_init(1)<=not p_in_cfg_color;




--//XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
--//RAM Строк видео информации
--//XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
--//Запись данных в буфера(BRAM) строк
tmp_lbuf_ena<=p_in_upp_wd;
tmp_lbuf_enb<=i_zoom_up_on and not OR_reduce(i_zoom_cnt_pix) and not OR_reduce(i_byte_cnt) and OR_reduce(i_zoom_cnt_row);
i_lbuf_ena(0)<=not p_in_dwnp_rdy_n and tmp_lbuf_ena;
i_lbuf_enb   <=not p_in_dwnp_rdy_n and tmp_lbuf_enb;


--//Буфера строк:
--//lineN : Текущая строка
i_lbufs_douta(0)<=p_in_upp_data;

--//lineN-1 : Предыдущая строка
m_buf0 : vscale_bram
port map
(
--//READ FIRST
addra=> i_lbufs_adra,
dina => p_in_upp_data,
douta=> i_lbufs_douta(1),
ena  => i_lbuf_ena(0),
wea  => i_lbuf_ena,
clka => p_in_clk,
rsta => p_in_rst,

--//WRITE FIRST
addrb=> i_lbufs_adra,--"0000000000",
dinb => "00000000000000000000000000000000",
doutb=> i_lbufs_doutb(1),
enb  => i_lbuf_enb,
web  => "0",
clkb => p_in_clk,
rstb => p_in_rst
);

--//lineN-2 : Предыдущая строка
m_buf1 : vscale_bram
port map
(
--//READ FIRST
addra=> i_lbufs_adra,
dina => i_lbufs_douta(1),
douta=> i_lbufs_douta(2),
ena  => i_lbuf_ena(0),
wea  => i_lbuf_ena,
clka => p_in_clk,
rsta => p_in_rst,

--//WRITE FIRST
addrb=> i_lbufs_adra,--"0000000000",
dinb => "00000000000000000000000000000000",
doutb=> i_lbufs_doutb(2),
enb  => i_lbuf_enb,
web  => "0",
clkb => p_in_clk,
rstb => p_in_rst
);

--//lineN-3 : Предыдущая строка
m_buf2 : vscale_bram
port map
(
--//READ FIRST
addra=> i_lbufs_adra,
dina => i_lbufs_douta(2),
douta=> i_lbufs_douta(3),
ena  => i_lbuf_ena(0),
wea  => i_lbuf_ena,
clka => p_in_clk,
rsta => p_in_rst,

--//WRITE FIRST
addrb=> i_lbufs_adra,--"0000000000",
dinb => "00000000000000000000000000000000",
doutb=> i_lbufs_doutb(3),
enb  => i_lbuf_enb,
web  => "0",
clkb => p_in_clk,
rstb => p_in_rst
);

--//------------------------------
--//RAM Коэфициентов
--//------------------------------
--//Запись коефициентов
i_coebuf_wr(0)<=p_in_cfg_dcoe_wr;
process(p_in_rst,p_in_cfg_coe_wrclk)
begin
  if p_in_rst='1' then
    i_coebuf_awrite<=(others=>'0');
  elsif p_in_cfg_coe_wrclk'event and p_in_cfg_coe_wrclk='1' then

    if p_in_cfg_acoe_ld='1' then
      i_coebuf_awrite(5 downto 0)<=p_in_cfg_acoe(5 downto 0);
    elsif p_in_cfg_dcoe_wr='1' or p_in_cfg_dcoe_rd='1' then
      i_coebuf_awrite<=i_coebuf_awrite+1;
    end if;
  end if;
end process;

--//Чтение коефициентов
i_coebuf_rd<=not p_in_dwnp_rdy_n and not p_in_cfg_dcoe_wr;

i_coebuf_aread(4)<=i_zoom_up_on and i_zoom_size_x4;
i_coebuf_aread(3 downto 2)<=i_zoom_cnt_row;
i_coebuf_aread(1 downto 0)<=i_zoom_cnt_pix;

m_coef : vscale_bram_coef
port map
(
addra=> i_coebuf_awrite(5 downto 0),
dina => p_in_cfg_dcoe,
douta=> p_out_cfg_dcoe,
ena  => '1',
wea  => i_coebuf_wr,
clka => p_in_cfg_coe_wrclk,
rsta => p_in_rst,

addrb=> i_coebuf_aread,
dinb => "00000000000000000000000000000000",
doutb=> tmp_coebuf_dout,
enb  => i_coebuf_rd,
web  => "0",
clkb => p_in_clk,
rstb => p_in_rst
);

--//Если режим ZoomUp со сглаживанием, то i_coebuf_dout<=tmp_coebuf_dout;
--//Если режим ZoomDown со сглаживанием, то i_coebuf_dout<=CONV_STD_LOGIC_VECTOR(16#01010101#, 32);
--//Если режим ZoomUp/Down с дублированием, то i_coebuf_dout<=CONV_STD_LOGIC_VECTOR(16#00000001#, 32);

i_coebuf_dout(0) <=tmp_coebuf_dout(0) or ((p_in_cfg_zoom_type and i_zoom_up_on) or i_zoom_dwn_on);
gen1_coe : for x in 1 to 7 generate
i_coebuf_dout(0*8 + x) <= tmp_coebuf_dout(0*8 + x) and (not p_in_cfg_zoom_type);
end generate gen1_coe;

i_coebuf_dout(8) <=(tmp_coebuf_dout(8) and not p_in_cfg_zoom_type) or (i_zoom_dwn_on and not p_in_cfg_zoom_type);
gen2_coe : for x in 1 to 7 generate
i_coebuf_dout(1*8 + x) <= tmp_coebuf_dout(1*8 + x) and (not p_in_cfg_zoom_type);
end generate gen2_coe;

i_coebuf_dout(16)<=(tmp_coebuf_dout(16) and not p_in_cfg_zoom_type) or (i_zoom_dwn_on and not p_in_cfg_zoom_type);
gen3_coe : for x in 1 to 7 generate
i_coebuf_dout(2*8 + x) <= tmp_coebuf_dout(2*8 + x) and (not p_in_cfg_zoom_type);
end generate gen3_coe;

i_coebuf_dout(24)<=(tmp_coebuf_dout(24) and not p_in_cfg_zoom_type) or (i_zoom_dwn_on and not p_in_cfg_zoom_type);
gen4_coe : for x in 1 to 7 generate
i_coebuf_dout(3*8 + x) <= tmp_coebuf_dout(3*8 + x) and (not p_in_cfg_zoom_type);
end generate gen4_coe;


--//XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
--//Управление приемом данных с Upstream Port
--//XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
process(p_in_rst,p_in_clk)
begin
  if p_in_rst='1' then
    i_lbufs_adra<=(others=>'0');
    i_byte_cnt<=(others=>'0');
    i_zoom_cnt_pix<=(others=>'0');
    i_zoom_cnt_row<=(others=>'0');
    i_pix_cnt<=(others=>'0');
    i_row_cnt<=(others=>'0');
    i_upp_rdy_n_out<='0';

  elsif p_in_clk'event and p_in_clk='1' then

    if i_cfg_bypass='1' or p_in_cfg_init='1' then
      i_lbufs_adra<=(others=>'0');
      i_byte_cnt<=(others=>'0');
      i_zoom_cnt_pix<=(others=>'0');
      i_zoom_cnt_row<=(others=>'0');
      i_pix_cnt<=(others=>'0');
      i_row_cnt<=(others=>'0');
      i_upp_rdy_n_out<='0';

    else
      --//Обработка кадра ВКЛ.
        if p_in_dwnp_rdy_n='0' then

            if p_in_upp_wd='1' then
              --//Прием нового входного DWORD
              i_upp_rdy_n_out<='1';--//Запрещаем запись входных данных в буфер строки на
                                   --//время обработки

              i_zoom_cnt_pix<=i_zoom_cnt_pix + i_zoom_up_on;
              i_byte_cnt<=i_byte_cnt + (not p_in_cfg_color and i_zoom_dwn_on);

            else
              if i_upp_rdy_n_out='1' then

                --//Обработка входных данных
                if i_zoom_cnt_pix=i_zoom_cnt_init then
                  i_zoom_cnt_pix<=(others=>'0');

                  if i_byte_cnt=i_byte_cnt_init then
                    i_byte_cnt<=(others=>'0');

                    if i_lbufs_adra=p_in_cfg_pix_count(i_lbufs_adra'range)-2 then
                      i_lbufs_adra<=(others=>'0');
                    else
                      i_lbufs_adra<=i_lbufs_adra+1;
                    end if;

                    if i_zoom_dwn_on='1' then
                      i_upp_rdy_n_out<='0';
                    elsif OR_reduce(i_zoom_cnt_row)='0' then
                      i_upp_rdy_n_out<='0';
                    end if;

                    if i_pix_cnt=p_in_cfg_pix_count-1 then
                      i_pix_cnt<=(others=>'0');

                      if i_zoom_cnt_row=i_zoom_cnt_init then
                        i_zoom_cnt_row<=(others=>'0');

                        i_row_cnt<=i_row_cnt + 1;
--                        if i_row_cnt=p_in_cfg_row_count-1 then
--                          i_row_cnt<=(others=>'0');
--                        else
--                          i_row_cnt<=i_row_cnt + 1;
--                        end if;
                      else
                        i_zoom_cnt_row<=i_zoom_cnt_row+1;
                      end if;

                    else
                      i_pix_cnt<=i_pix_cnt + 1;
                    end if;
                  else
                    i_byte_cnt<=i_byte_cnt + (not p_in_cfg_color);--//Ведем подсчет байт входного DWORD
                  end if;

                else
                  i_zoom_cnt_pix<=i_zoom_cnt_pix+1;
                end if;


              elsif OR_reduce(i_zoom_cnt_row)='1' then
                --//Обработка данных записаных в буфера строк
                if i_zoom_cnt_pix=i_zoom_cnt_init then
                  i_zoom_cnt_pix<=(others=>'0');

                  if i_byte_cnt=i_byte_cnt_init then
                    i_byte_cnt<=(others=>'0');

                    if OR_reduce(i_zoom_cnt_row)='0' then
                      i_upp_rdy_n_out<='0';
                    end if;

                    if i_pix_cnt=p_in_cfg_pix_count-1 then
                      i_pix_cnt<=(others=>'0');

                      if i_zoom_cnt_row=i_zoom_cnt_init then
                        i_zoom_cnt_row<=(others=>'0');

                        i_row_cnt<=i_row_cnt + 1;
--                        if i_row_cnt=p_in_cfg_row_count-1 then
--                          i_row_cnt<=(others=>'0');
--                        else
--                          i_row_cnt<=i_row_cnt + 1;
--                        end if;
                      else
                        i_zoom_cnt_row<=i_zoom_cnt_row+1;
                      end if;

                    else
                      if i_lbufs_adra=p_in_cfg_pix_count(i_lbufs_adra'range)-2 then
                        i_lbufs_adra<=(others=>'0');
                      else
                        i_lbufs_adra<=i_lbufs_adra+1;
                      end if;
                      i_pix_cnt<=i_pix_cnt + 1;
                    end if;
                  else
                    i_byte_cnt<=i_byte_cnt + (not p_in_cfg_color);--//Ведем подсчет байт входного DWORD
                  end if;

                else
                  i_zoom_cnt_pix<=i_zoom_cnt_pix+1;
                end if;

              end if;--//if i_upp_rdy_n_out='1' then

            end if;--//if p_in_upp_wd='1' then

        end if;--//if p_in_dwnp_rdy_n='0' then

    end if;

  end if;
end process;



--//XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
--//Линии задержек
--//XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX

--//Готовим сигналы для линии задержки:
--//Счетчик байт результат (необходим при работе с Gray Image)
sr_result_byte_fst<=i_byte_cnt(0) & i_zoom_cnt_pix(0) when p_in_cfg_color='0' and i_zoom_up_on='1'  and i_zoom_size_x2='1' else
                    i_zoom_cnt_pix                    when p_in_cfg_color='0' and i_zoom_up_on='1'  and i_zoom_size_x4='1' else
                    i_pix_cnt(0) & i_byte_cnt(1)      when p_in_cfg_color='0' and i_zoom_dwn_on='1' and i_zoom_size_x2='1' else
                    i_pix_cnt(1) & i_pix_cnt(0);--       when p_in_cfg_color='0' and i_zoom_dwn_on='1' and i_zoom_size_x4='1' else

--//Разрешение Счетчика байт результат (необходим при работе с Gray Image)
sr_result_byte_en_fst<=(not p_in_cfg_color and
                         (  i_zoom_up_on or
                           (i_zoom_dwn_on and i_zoom_size_x2 and i_row_cnt(0) and i_byte_cnt(0)) or
                           (i_zoom_dwn_on and i_zoom_size_x4 and AND_reduce(i_row_cnt(1 downto 0)) and AND_reduce(i_byte_cnt) )
                          )
                        );

--Разрешение выдачи результата
sr_result_en_fst<=(not p_in_cfg_color and
                    (
                      (i_zoom_up_on  and AND_reduce(sr_result_byte_fst)) or
                      (i_zoom_dwn_on and AND_reduce(sr_result_byte_fst) and sr_result_byte_en_fst)
                    )
                  ) or
                  (   p_in_cfg_color and
                      (
                        (i_zoom_up_on  and (tmp_lbuf_ena or tmp_lbuf_enb or OR_reduce(i_zoom_cnt_pix))) or
                        (i_zoom_dwn_on and i_zoom_size_x2 and i_row_cnt(0) and i_pix_cnt(0) and tmp_lbuf_ena) or
                        (i_zoom_dwn_on and i_zoom_size_x4 and AND_reduce(i_row_cnt(1 downto 0)) and AND_reduce(i_pix_cnt(1 downto 0)) and tmp_lbuf_ena)
                      )
                  );

--//линии задержки
process(p_in_rst,p_in_clk)
begin
  if p_in_rst='1' then

    sr_result_byte_en<=(others=>'0');
    for i in 0 to 7 loop
    sr_result_byte(i)<=(others=>'0');
    end loop;

    sr_result_en<=(others=>'0');
    sr_result_en2<=(others=>'0');

  elsif p_in_clk'event and p_in_clk='1' then
  if p_in_dwnp_rdy_n='0' then

      --//Кол-во тактов задержки = кол-ву операций вычислений:
      --//В общем случае может меняться в зависимости от кол-ва операций вычислений
      sr_result_en<=sr_result_en_fst & sr_result_en(0 to 6);

      sr_result_byte_en<=sr_result_byte_en_fst & sr_result_byte_en(0 to 6);
      sr_result_byte<=sr_result_byte_fst & sr_result_byte(0 to 6);

      --//Формирование и выдача результата
--      sr_result_en2(0)<=sr_result_en(6) & sr_result_en2(0 to 1);
      sr_result_en2(0)<=sr_result_en(6);
      sr_result_en2(1)<=sr_result_en2(0);

  end if;--//if p_in_dwnp_rdy_n='0' then
  end if;
end process;



--//XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
--//Формирование матрицы вычислений
--//XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
sr_byteline_ld(0)<=tmp_lbuf_ena or (tmp_lbuf_enb and i_zoom_up_on);
sr_byteline_en(0)<=not p_in_cfg_color and ((i_zoom_up_on and not OR_reduce(i_zoom_cnt_pix)) or (i_zoom_dwn_on and OR_reduce(i_byte_cnt)));

gen_srfst0 : for x in 0 to C_VSACL_CALC_LINE_COUNT-1 generate
  gen_srfst1 : for i in 0 to C_VSACL_MATRIX_COUNT-1 generate
    sr_byteline_dlyfst(x)(8*(i+1)-1 downto 8*i)<=sr_byteline(x)(i);
  end generate gen_srfst1;
end generate gen_srfst0;

i_lbufs_dout(0)<=i_lbufs_douta(1) when i_zoom_up_on='1' and OR_reduce(i_zoom_cnt_row)='1' and OR_reduce(i_pix_cnt)='0' else
                 i_lbufs_doutb(1) when i_zoom_up_on='1' and OR_reduce(i_zoom_cnt_row)='1' and OR_reduce(i_pix_cnt)='1' else
                 i_lbufs_douta(0);

i_lbufs_dout(1)<=i_lbufs_douta(2) when i_zoom_up_on='1' and OR_reduce(i_zoom_cnt_row)='1' and OR_reduce(i_pix_cnt)='0' else
                 i_lbufs_doutb(2) when i_zoom_up_on='1' and OR_reduce(i_zoom_cnt_row)='1' and OR_reduce(i_pix_cnt)='1' else
                 i_lbufs_douta(1);

i_lbufs_dout(2)<=i_lbufs_douta(2);
i_lbufs_dout(3)<=i_lbufs_douta(3);

process(p_in_rst,p_in_clk)
begin
  if p_in_rst='1' then
      for y in 0 to C_VSACL_CALC_LINE_COUNT-1 loop
        for i in 0 to C_VSACL_CALC_LINE_COUNT-1 loop
          sr_byteline(y)(i)<=(others=>'0');
        end loop;
      end loop;
      for y in 0 to C_VSACL_CALC_LINE_COUNT-1 loop
        for i in 0 to C_VSACL_CALC_LINE_COUNT-2 loop
          sr_byteline_dly(y)(i)<=(others=>'0');
        end loop;
      end loop;
  elsif p_in_clk'event and p_in_clk='1' then
  if p_in_dwnp_rdy_n='0' then
      if sr_byteline_ld(0)='1' then
      --//Загрузка нового DW для матрицы вычислений
        for y in 0 to C_VSACL_CALC_LINE_COUNT-1 loop
          for i in 0 to C_VSACL_CALC_LINE_COUNT-1 loop
            sr_byteline(y)(i)<=i_lbufs_dout(y)(8*(i+1)-1 downto 8*i);
          end loop;
        end loop;
      else
        if sr_byteline_en(0)='1' then
          --//закачка байт в матрицу вычислений (Сдвиг байт DW)
          for y in 0 to 2 loop
            sr_byteline(y)<="00000000"&sr_byteline(y)(3 downto 1);
          end loop;
        end if;
      end if;

      --//Сдвиговый регистр на 3-и точки
      --//Необходим для формирования матрицы вычислений
      for y in 0 to C_VSACL_CALC_LINE_COUNT-1 loop
        if sr_byteline_ld(0)='1' or sr_byteline_en(0)='1' then
          sr_byteline_dly(y)<=sr_byteline_dlyfst(y) & sr_byteline_dly(y)(0 to 1);
        end if;
      end loop;
  end if;--//if p_in_dwnp_rdy_n='0'
  end if;
end process;



--//XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
--//Вычисления
--//XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
gen_mcalc : for i in 0 to C_VSACL_MATRIX_COUNT-1 generate

--//Матрица вычислений
gen_matrix : for x in 0 to C_VSACL_CALC_LINE_COUNT-1 generate
begin
--//где - i_matrix(i)(Индекс строки)(Индекс Пикселя)
--// i=0 - обработка R компонента цветного изображения или для черно/белого изображения
--// i=1 - обработка G компонента цветного изображения
--// i=2 - обработка B компонента цветного изображения
i_matrix(i)(x)(0)<=sr_byteline(x)(i);
i_matrix(i)(x)(1)<=sr_byteline_dly(x)(0)(8*(i+1)-1 downto 8*i);
i_matrix(i)(x)(2)<=sr_byteline_dly(x)(1)(8*(i+1)-1 downto 8*i);
i_matrix(i)(x)(3)<=sr_byteline_dly(x)(2)(8*(i+1)-1 downto 8*i);
end generate gen_matrix;


--//Вычисления
process(p_in_rst,p_in_clk)
begin
  if p_in_rst='1' then
    --//Умножение на коэф.
    i_pix0_line0_mult(i)<=(others=>'0');
    i_pix1_line0_mult(i)<=(others=>'0');
    i_pix2_line0_dly(i)<=(others=>'0');
    i_pix3_line0_dly(i)<=(others=>'0');

    i_pix0_line1_mult(i)<=(others=>'0');
    i_pix1_line1_mult(i)<=(others=>'0');
    i_pix2_line1_dly(i)<=(others=>'0');
    i_pix3_line1_dly(i)<=(others=>'0');

    i_pix0_line2_dly(i)<=(others=>'0');
    i_pix1_line2_dly(i)<=(others=>'0');
    i_pix2_line2_dly(i)<=(others=>'0');
    i_pix3_line2_dly(i)<=(others=>'0');

    i_pix0_line3_dly(i)<=(others=>'0');
    i_pix1_line3_dly(i)<=(others=>'0');
    i_pix2_line3_dly(i)<=(others=>'0');
    i_pix3_line3_dly(i)<=(others=>'0');

    --//Сумммы
    i_pix01_sum_line0(i)<=(others=>'0');
    i_pix01_sum_line1(i)<=(others=>'0');
    i_pix01_sum_line2(i)<=(others=>'0');
    i_pix01_sum_line3(i)<=(others=>'0');

    i_pix23_sum_line0(i)<=(others=>'0');
    i_pix23_sum_line1(i)<=(others=>'0');
    i_pix23_sum_line2(i)<=(others=>'0');
    i_pix23_sum_line3(i)<=(others=>'0');

    i_pix01_line01_sum(i)<=(others=>'0');
    i_pix01_line01_sum_dly1(i)<=(others=>'0');
    i_pix01_line01_sum_dly2(i)<=(others=>'0');
    i_pix01_line23_sum(i)<=(others=>'0');

    i_pix23_line01_sum(i)<=(others=>'0');
    i_pix23_line23_sum(i)<=(others=>'0');

    i_pix0123_line01_sum(i)<=(others=>'0');
    i_pix0123_line23_sum(i)<=(others=>'0');

    i_pix0123_line0123_sum(i)<=(others=>'0');

    i_mcalc_result_sum(i)<=(others=>'0');
    i_mcalc_result(i)<=(others=>'0');

    dbg_sr_pix(i)(0)<=(others=>'0');
    dbg_sr_pix(i)(1)<=(others=>'0');
    dbg_sr_pix(i)(2)<=(others=>'0');
    dbg_sr_pix(i)(3)<=(others=>'0');
    dbg_sr_pix(i)(4)<=(others=>'0');
    dbg_sr_pix(i)(5)<=(others=>'0');
    dbg_sr_pix(i)(6)<=(others=>'0');

  elsif p_in_clk'event and p_in_clk='1' then
  if p_in_dwnp_rdy_n='0' then

    --//Умножение на коэф.
    --//dly0
    i_pix0_line0_mult(i)<=i_matrix(i)(0)(0)(7 downto 0)*i_coebuf_dout(7 downto 0);
    i_pix1_line0_mult(i)<=i_matrix(i)(0)(1)(7 downto 0)*i_coebuf_dout(15 downto 8);
    i_pix2_line0_dly(i) <=i_matrix(i)(0)(2);
    i_pix3_line0_dly(i) <=i_matrix(i)(0)(3);

    i_pix0_line1_mult(i)<=i_matrix(i)(1)(0)(7 downto 0)*i_coebuf_dout(23 downto 16);
    i_pix1_line1_mult(i)<=i_matrix(i)(1)(1)(7 downto 0)*i_coebuf_dout(31 downto 24);
    i_pix2_line1_dly(i) <=i_matrix(i)(1)(2);
    i_pix3_line1_dly(i) <=i_matrix(i)(1)(3);

    i_pix0_line2_dly(i)<=i_matrix(i)(2)(0);
    i_pix1_line2_dly(i)<=i_matrix(i)(2)(1);
    i_pix2_line2_dly(i)<=i_matrix(i)(2)(2);
    i_pix3_line2_dly(i)<=i_matrix(i)(2)(3);

    i_pix0_line3_dly(i)<=i_matrix(i)(3)(0);
    i_pix1_line3_dly(i)<=i_matrix(i)(3)(1);
    i_pix2_line3_dly(i)<=i_matrix(i)(3)(2);
    i_pix3_line3_dly(i)<=i_matrix(i)(3)(3);

    dbg_sr_pix(i)(0)<=i_matrix(i)(0)(0);

    --//Сумммы
    --//dly1
    i_pix01_sum_line0(i)<=EXT(i_pix0_line0_mult(i), i_pix01_sum_line0(i)'length) + EXT(i_pix1_line0_mult(i), i_pix01_sum_line0(i)'length);--//mult + mult
    i_pix01_sum_line1(i)<=EXT(i_pix0_line1_mult(i), i_pix01_sum_line1(i)'length) + EXT(i_pix1_line1_mult(i), i_pix01_sum_line1(i)'length);--//mult + mult
    i_pix01_sum_line2(i)<=EXT(i_pix0_line2_dly(i), i_pix01_sum_line2(i)'length) + EXT(i_pix1_line2_dly(i), i_pix01_sum_line2(i)'length);
    i_pix01_sum_line3(i)<=EXT(i_pix0_line3_dly(i), i_pix01_sum_line3(i)'length) + EXT(i_pix1_line3_dly(i), i_pix01_sum_line3(i)'length);

    i_pix23_sum_line0(i)<=EXT(i_pix2_line0_dly(i), i_pix23_sum_line0(i)'length) + EXT(i_pix3_line0_dly(i), i_pix23_sum_line0(i)'length);
    i_pix23_sum_line1(i)<=EXT(i_pix2_line1_dly(i), i_pix23_sum_line1(i)'length) + EXT(i_pix3_line1_dly(i), i_pix23_sum_line1(i)'length);
    i_pix23_sum_line2(i)<=EXT(i_pix2_line2_dly(i), i_pix23_sum_line2(i)'length) + EXT(i_pix3_line2_dly(i), i_pix23_sum_line2(i)'length);
    i_pix23_sum_line3(i)<=EXT(i_pix2_line3_dly(i), i_pix23_sum_line3(i)'length) + EXT(i_pix3_line3_dly(i), i_pix23_sum_line3(i)'length);

    dbg_sr_pix(i)(1)<=dbg_sr_pix(i)(0);

    --//dly2
    i_pix01_line01_sum(i)<=EXT(i_pix01_sum_line0(i), i_pix01_line01_sum(i)'length) + EXT(i_pix01_sum_line1(i), i_pix01_line01_sum(i)'length);--//mult + mult
    i_pix01_line23_sum(i)<=EXT(i_pix01_sum_line2(i), i_pix01_line23_sum(i)'length) + EXT(i_pix01_sum_line3(i), i_pix01_line23_sum(i)'length);

    i_pix23_line01_sum(i)<=EXT(i_pix23_sum_line0(i), i_pix23_line01_sum(i)'length) + EXT(i_pix23_sum_line1(i), i_pix23_line01_sum(i)'length);
    i_pix23_line23_sum(i)<=EXT(i_pix23_sum_line2(i), i_pix23_line23_sum(i)'length) + EXT(i_pix23_sum_line3(i), i_pix23_line23_sum(i)'length);

    dbg_sr_pix(i)(2)<=dbg_sr_pix(i)(1);

    --//dly3
    i_pix01_line01_sum_dly1(i)<=i_pix01_line01_sum(i);

    i_pix0123_line01_sum(i)<=EXT(i_pix01_line01_sum(i), i_pix0123_line01_sum(i)'length) + EXT(i_pix23_line01_sum(i), i_pix0123_line01_sum(i)'length);
    i_pix0123_line23_sum(i)<=EXT(i_pix01_line23_sum(i), i_pix0123_line23_sum(i)'length) + EXT(i_pix23_line23_sum(i), i_pix0123_line23_sum(i)'length);

    dbg_sr_pix(i)(3)<=dbg_sr_pix(i)(2);

    --//dly4
    i_pix01_line01_sum_dly2(i)<=i_pix01_line01_sum_dly1(i);

    i_pix0123_line0123_sum(i)<=EXT(i_pix0123_line01_sum(i), i_pix0123_line0123_sum(i)'length) + EXT(i_pix0123_line23_sum(i), i_pix0123_line0123_sum(i)'length);

    dbg_sr_pix(i)(4)<=dbg_sr_pix(i)(3);

    --//Результат:
    --//1. Выбор результирующей суммы
    --//dly5
    if (p_in_cfg_zoom_type='0' and i_zoom_dwn_on='1' and i_zoom_size_x4='1') then
      i_mcalc_result_sum(i)<=EXT(i_pix0123_line0123_sum(i), i_mcalc_result_sum(i)'length);
    else
      i_mcalc_result_sum(i)<=EXT(i_pix01_line01_sum_dly2(i), i_mcalc_result_sum(i)'length);
    end if;

    dbg_sr_pix(i)(5)<=dbg_sr_pix(i)(4);

    --//2. Деление
    --//dly6
    if   (i_zoom_up_on='1'  and i_zoom_size_x2='1' and p_in_cfg_zoom_type='0') or
         (i_zoom_dwn_on='1' and i_zoom_size_x2='1' and p_in_cfg_zoom_type='0') then
      --//Деление на 4
      --//(в случае режима уменьшения - среднее арифметическое)
      i_mcalc_result(i)<="00"&i_mcalc_result_sum(i)(15 downto 2);

    elsif (i_zoom_up_on='1'  and i_zoom_size_x4='1' and p_in_cfg_zoom_type='0') or
          (i_zoom_dwn_on='1' and i_zoom_size_x4='1' and p_in_cfg_zoom_type='0') then
      --//Деление на 16
      --//(в случае режима уменьшения - среднее арифметическое)
      i_mcalc_result(i)<="0000"&i_mcalc_result_sum(i)(15 downto 4);

    else
      i_mcalc_result(i)<=i_mcalc_result_sum(i)(15 downto 0);
    end if;

    dbg_sr_pix(i)(6)<=dbg_sr_pix(i)(5);

  end if;--//if p_in_dwnp_rdy_n='0' then
  end if;
end process;

i_mcalc_result_out(8*(i+1)-1 downto 8*i)<=i_mcalc_result(i)(7 downto 0);

end generate gen_mcalc;



--//XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
--//Формирование результата
--//XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
process(p_in_rst,p_in_clk)
begin
  if p_in_rst='1' then
    i_result_out<=(others=>'0');

  elsif p_in_clk'event and p_in_clk='1' then
  if p_in_dwnp_rdy_n='0' then

    if p_in_cfg_color='0' then
    --//Gray Image
        if sr_result_byte_en(7)='1' then
          case sr_result_byte(7) is
            when "00" => i_result_out(7 downto 0)  <=i_mcalc_result_out(7 downto 0);
            when "01" => i_result_out(15 downto 8) <=i_mcalc_result_out(7 downto 0);
            when "10" => i_result_out(23 downto 16)<=i_mcalc_result_out(7 downto 0);
            when "11" => i_result_out(31 downto 24)<=i_mcalc_result_out(7 downto 0);
            when others => i_result_out(7 downto 0)<=i_mcalc_result_out(7 downto 0);
          end case;
        end if;
    else
    --//Color Image
      i_result_out(7 downto 0)  <=i_mcalc_result_out(7 downto 0);
      i_result_out(15 downto 8) <=i_mcalc_result_out(15 downto 8);
      i_result_out(23 downto 16)<=i_mcalc_result_out(23 downto 16);
      i_result_out(31 downto 24)<=(others=>'1');
    end if;
  end if;--//if p_in_dwnp_rdy_n='0' then
  end if;
end process;

i_result_en_out<=not p_in_dwnp_rdy_n and sr_result_en2(1);

--END MAIN
end behavioral;

