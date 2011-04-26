-------------------------------------------------------------------------
-- Company     : Linkos
-- Engineer    : Golovachenko Victor
--
-- Create Date : 25.11.2008 18:38
-- Module Name : vrgb2yuv_main2_tb
--
-- Назначение/Описание :
--    Проверка работы
--
-- Revision:
-- Revision 0.01 - File Created
--
-------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_misc.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_textio.all;

--use work.vicg_common_pkg.all;

library std;
use std.textio.all;

library unisim;
use unisim.vcomponents.all;

entity vrgb2yuv_main_tb is
generic(
G_DWIDTH : integer:=8  --//Возможные значения 32, 8
);
end vrgb2yuv_main_tb;

architecture behavior of vrgb2yuv_main_tb is

constant i_clk_period : TIME := 6.6 ns; --150MHz


component vrgb2yuv_main
generic(
G_DWIDTH : integer:=32;  --//Возможные значения 32, 8
G_SIM : string:="OFF"
);
port
(
-------------------------------
-- Управление
-------------------------------
p_in_cfg_bypass            : in    std_logic;                    --//0/1 - Upstream Port -> Downstream Port Обрабатывать/Не обрабатывать

--//--------------------------
--//Upstream Port (входные данные)
--//--------------------------
--p_in_upp_clk               : in    std_logic;
p_in_upp_data              : in    std_logic_vector((32*4)-1 downto 0);
p_in_upp_wd                : in    std_logic;                    --//Запись данных в модуль vyuv2rgb_main.vhd
p_out_upp_rdy_n            : out   std_logic;                    --//0 - Модуль vyuv2rgb_main.vhd готов к приему данных

--//--------------------------
--//Downstream Port (результат)
--//--------------------------
--p_in_dwnp_clk              : in    std_logic;
p_in_dwnp_rdy_n            : in    std_logic;                    --//0 - порт приемника готов к приему даннвх
p_out_dwnp_wd              : out   std_logic;                    --//Запись данных в приемник
p_out_dwnp_data            : out   std_logic_vector((32*4)-1 downto 0);

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

component vyuv2rgb_main
generic(
G_DWIDTH : integer:=32;  --//Возможные значения 32, 8
G_SIM : string:="OFF"
);
port
(
-------------------------------
-- Управление
-------------------------------
p_in_cfg_bypass            : in    std_logic;                    --//0/1 - Upstream Port -> Downstream Port Обрабатывать/Не обрабатывать

--//--------------------------
--//Upstream Port (входные данные)
--//--------------------------
--p_in_upp_clk               : in    std_logic;
p_in_upp_data              : in    std_logic_vector((32*4)-1 downto 0);
p_in_upp_wd                : in    std_logic;                    --//Запись данных в модуль vyuv2rgb_main.vhd
p_out_upp_rdy_n            : out   std_logic;                    --//0 - Модуль vyuv2rgb_main.vhd готов к приему данных

--//--------------------------
--//Downstream Port (результат)
--//--------------------------
--p_in_dwnp_clk              : in    std_logic;
p_in_dwnp_rdy_n            : in    std_logic;                    --//0 - порт приемника готов к приему даннвх
p_out_dwnp_wd              : out   std_logic;                    --//Запись данных в приемник
p_out_dwnp_data            : out   std_logic_vector((32*4)-1 downto 0);

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

signal p_in_clk                       : std_logic := '0';
signal p_in_rst                       : std_logic := '0';

signal p_in_cfg_bypass                : std_logic;
--signal p_in_cfg_colorfst              : std_logic_vector(1 downto 0); --//0/1/2 - R/G/B
signal p_in_cfg_pix_count             : std_logic_vector(15 downto 0);
signal p_in_cfg_row_count             : std_logic_vector(15 downto 0);

signal tst_upp_data                   : std_logic_vector(32*4-1 downto 0);
signal tst_upp_wd                     : std_logic;
signal p_out_upp_rdy_n                : std_logic;

signal tst_dwnp_data                  : std_logic_vector(32*4-1 downto 0);
signal tst_dwnp_wd                    : std_logic;
signal p_in_dwnp_rdy_n                : std_logic;

signal p_in_tst_ctrl                  : std_logic_vector(31 downto 0);

signal i_yuv2rgb_rdy_n                : std_logic;
signal i_drgb2yuv_wd                  : std_logic;
signal i_drgb2yuv_data                : std_logic_vector(32*4-1 downto 0);

--type TPixColor is record
--r : std_logic_vector(7 downto 0);
--g : std_logic_vector(7 downto 0);
--b :
--end record;
Type TPixColor is array (0 to 2) of std_logic_vector(7 downto 0);
signal i_pixin                        : TPixColor;

Type TPixOUT is array (0 to G_DWIDTH/8-1) of TPixColor;
signal i_pixout                       : TPixOUT;

--Main
begin



m_vrgb2yuv: vrgb2yuv_main
generic map(
G_DWIDTH => G_DWIDTH,
G_SIM => "ON"
)
port map
(
-------------------------------
-- Управление
-------------------------------
p_in_cfg_bypass            => p_in_cfg_bypass,


--//--------------------------
--//Upstream Port
--//--------------------------
p_in_upp_data              => tst_upp_data,
p_in_upp_wd                => tst_upp_wd,
p_out_upp_rdy_n            => p_out_upp_rdy_n,

--//--------------------------
--//Downstream Port
--//--------------------------
p_in_dwnp_rdy_n            => i_yuv2rgb_rdy_n,
p_out_dwnp_wd              => i_drgb2yuv_wd,
p_out_dwnp_data            => i_drgb2yuv_data,

-------------------------------
--Технологический
-------------------------------
p_in_tst_ctrl              => p_in_tst_ctrl,--"00000000000000000000000000000000",
p_out_tst                  => open,

-------------------------------
--System
-------------------------------
p_in_clk            => p_in_clk,
p_in_rst            => p_in_rst
);

m_vyuv2rgb: vyuv2rgb_main
generic map(
G_DWIDTH => G_DWIDTH,
G_SIM => "ON"
)
port map
(
-------------------------------
-- Управление
-------------------------------
p_in_cfg_bypass            => p_in_cfg_bypass,


--//--------------------------
--//Upstream Port
--//--------------------------
p_in_upp_data              => i_drgb2yuv_data,
p_in_upp_wd                => i_drgb2yuv_wd,
p_out_upp_rdy_n            => i_yuv2rgb_rdy_n,

--//--------------------------
--//Downstream Port
--//--------------------------
p_in_dwnp_rdy_n            => p_in_dwnp_rdy_n,
p_out_dwnp_wd              => tst_dwnp_wd,
p_out_dwnp_data            => tst_dwnp_data,

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

--//---------------------------------------------------------------------------------------------------------
--//   |           Red                   |           Green                 |           Blue                  |
--//---------------------------------------------------------------------------------------------------------
i_pixin<=(CONV_STD_LOGIC_VECTOR(10#000#, 8),CONV_STD_LOGIC_VECTOR(10#008#, 8),CONV_STD_LOGIC_VECTOR(10#016#, 8)),
         (CONV_STD_LOGIC_VECTOR(10#001#, 8),CONV_STD_LOGIC_VECTOR(10#001#, 8),CONV_STD_LOGIC_VECTOR(10#016#, 8)) after 2.0 us,
         (CONV_STD_LOGIC_VECTOR(10#002#, 8),CONV_STD_LOGIC_VECTOR(10#009#, 8),CONV_STD_LOGIC_VECTOR(10#017#, 8)) after 2.2 us,
         (CONV_STD_LOGIC_VECTOR(10#003#, 8),CONV_STD_LOGIC_VECTOR(10#003#, 8),CONV_STD_LOGIC_VECTOR(10#017#, 8)) after 2.4 us,
         (CONV_STD_LOGIC_VECTOR(10#004#, 8),CONV_STD_LOGIC_VECTOR(10#004#, 8),CONV_STD_LOGIC_VECTOR(10#018#, 8)) after 2.6 us,
         (CONV_STD_LOGIC_VECTOR(10#005#, 8),CONV_STD_LOGIC_VECTOR(10#011#, 8),CONV_STD_LOGIC_VECTOR(10#018#, 8)) after 2.8 us,
         (CONV_STD_LOGIC_VECTOR(10#006#, 8),CONV_STD_LOGIC_VECTOR(10#006#, 8),CONV_STD_LOGIC_VECTOR(10#019#, 8)) after 3.0 us,
         (CONV_STD_LOGIC_VECTOR(10#007#, 8),CONV_STD_LOGIC_VECTOR(10#013#, 8),CONV_STD_LOGIC_VECTOR(10#019#, 8)) after 3.2 us,
         (CONV_STD_LOGIC_VECTOR(10#016#, 8),CONV_STD_LOGIC_VECTOR(10#032#, 8),CONV_STD_LOGIC_VECTOR(10#064#, 8)) after 3.4 us,
         (CONV_STD_LOGIC_VECTOR(10#016#, 8),CONV_STD_LOGIC_VECTOR(10#032#, 8),CONV_STD_LOGIC_VECTOR(10#064#, 8)) after 3.6 us,
         (CONV_STD_LOGIC_VECTOR(10#016#, 8),CONV_STD_LOGIC_VECTOR(10#032#, 8),CONV_STD_LOGIC_VECTOR(10#064#, 8)) after 3.8 us,
         (CONV_STD_LOGIC_VECTOR(10#016#, 8),CONV_STD_LOGIC_VECTOR(10#032#, 8),CONV_STD_LOGIC_VECTOR(10#064#, 8)) after 4.0 us;



--//----------------------------------------------------------
--//
--//----------------------------------------------------------
p_in_tst_ctrl(0)<=OR_reduce(i_pixout(0)(0)) or OR_reduce(i_pixout(0)(1)) or OR_reduce(i_pixout(0)(2));

p_in_dwnp_rdy_n<='0';

tst_upp_wd<='0','1' after 1.5 us;


gen_w8 : if G_DWIDTH=8 generate
begin

tst_upp_data(7 downto 0)<=i_pixin(0);--i_red;
tst_upp_data(15 downto 8)<=i_pixin(1);--i_green;
tst_upp_data(23 downto 16)<=i_pixin(2);--i_blue;
tst_upp_data(127 downto 24)<=(others=>'0');

i_pixout(0)(0)<=tst_dwnp_data(7 downto 0);--i_red;
i_pixout(0)(1)<=tst_dwnp_data(15 downto 8);--i_green;
i_pixout(0)(2)<=tst_dwnp_data(23 downto 16);--i_blue;

end generate gen_w8;


gen_w32 : if G_DWIDTH=32 generate
begin
tst_upp_data(7 downto 0)<=i_pixin(0);--i_red;
tst_upp_data(15 downto 8)<=i_pixin(1);--i_green;
tst_upp_data(23 downto 16)<=i_pixin(2);--i_blue;
tst_upp_data(31 downto 24)<=(others=>'0');

tst_upp_data(39 downto 32)<=i_pixin(0);--i_red;
tst_upp_data(47 downto 40)<=i_pixin(1);--i_green;
tst_upp_data(55 downto 48)<=i_pixin(2);--i_blue;
tst_upp_data(63 downto 56)<=(others=>'0');

tst_upp_data(71 downto 64)<=i_pixin(0);--i_red;
tst_upp_data(79 downto 72)<=i_pixin(1);--i_green;
tst_upp_data(87 downto 80)<=i_pixin(2);--i_blue;
tst_upp_data(95 downto 88)<=(others=>'0');

tst_upp_data(103 downto 96)<=i_pixin(0);--i_red;
tst_upp_data(111 downto 104)<=i_pixin(1);--i_green;
tst_upp_data(119 downto 112)<=i_pixin(2);--i_blue;
tst_upp_data(127 downto 120)<=(others=>'0');


i_pixout(0)(0)<=tst_dwnp_data(7 downto 0);--i_red;
i_pixout(0)(1)<=tst_dwnp_data(15 downto 8);--i_green;
i_pixout(0)(2)<=tst_dwnp_data(23 downto 16);--i_blue;

i_pixout(1)(0)<=tst_dwnp_data(39 downto 32);--i_red;
i_pixout(1)(1)<=tst_dwnp_data(47 downto 40);--i_green;
i_pixout(1)(2)<=tst_dwnp_data(55 downto 48);--i_blue;

i_pixout(2)(0)<=tst_dwnp_data(71 downto 64);--i_red;
i_pixout(2)(1)<=tst_dwnp_data(79 downto 72);--i_green;
i_pixout(2)(2)<=tst_dwnp_data(87 downto 80);--i_blue;

i_pixout(3)(0)<=tst_dwnp_data(103 downto 96);--i_red;
i_pixout(3)(1)<=tst_dwnp_data(111 downto 104);--i_green;
i_pixout(3)(2)<=tst_dwnp_data(119 downto 112);--i_blue;

end generate gen_w32;

--End Main
end;
