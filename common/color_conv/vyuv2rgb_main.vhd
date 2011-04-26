-------------------------------------------------------------------------
-- Company     : Linkos
-- Engineer    : Golovachenko Victor
--
-- Create Date : 2010.10
-- Module Name : vyuv2rgb_main
--
-- Назначение/Описание :
--  Модуль ковертации цветового пространства YUV(YCrCb) в RGB
--
--  Модуль базируется на примере Xilinx - xapp931
--
--  Upstream Port(Вх. данные)
--  Downstream Port(Вых. данные)
--
--  Натройка работы модуля:
--  1. Выбрать режим работы модуля. Порт p_in_cfg_bypass - 0/1:
--     Upstream Port -> Downstream Port Обрабатывать/Не обрабатывать
--
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

entity vyuv2rgb_main is
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

--//--------------------------
--//Upstream Port (входные данные)
--//--------------------------
--p_in_upp_clk    : in    std_logic;
p_in_upp_data   : in    std_logic_vector((32*4)-1 downto 0);
p_in_upp_wd     : in    std_logic;  --//Запись данных в модуль vyuv2rgb_main.vhd
p_out_upp_rdy_n : out   std_logic;  --//0 - Модуль vyuv2rgb_main.vhd готов к приему данных

--//--------------------------
--//Downstream Port (результат)
--//--------------------------
--p_in_dwnp_clk   : in    std_logic;
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
end vyuv2rgb_main;

architecture behavioral of vyuv2rgb_main is

--constant dly : time := 1 ps;

constant CC_IWIDTH        : integer:= 8;
constant CC_CWIDTH        : integer:= 13; -- Coefficients are signed, CWIDTH.CWIDTH-2 format
constant CC_MWIDTH        : integer:= 21; -- ONLY FOR NON-V4: Controls bits witheld after mults.
constant CC_OWIDTH        : integer:= 8;  -- OTHERWISE (default) IWIDTH+CWIDTH+1;
constant CC_RGBMAX        : integer:= 255;
constant CC_RGBMIN        : integer:= 0;
constant CC_ACOEF         : integer:= 2872;   --  1.4023   *pow2(CWIDTH-2)
constant CC_BCOEF         : integer:= -1461;  --  -0.7133  *pow2(CWIDTH-2)
constant CC_CCOEF         : integer:= -703;   --  -0.3434  *pow2(CWIDTH-2)
constant CC_DCOEF         : integer:= 3630;   --  1.7724   *pow2(CWIDTH-2)
constant CC_ROFFSET       : integer:= -366592;  -- Should be MWIDTH bits wide
constant CC_GOFFSET       : integer:= 278016;
constant CC_BOFFSET       : integer:= -463616;
constant CC_HAS_CLIP      : integer:= 1;
constant CC_HAS_CLAMP     : integer:= 1;


--constant CC_ACOEF         : integer:= 613; -- 0.29931       * 2048 = 612,98688
--constant CC_BCOEF         : integer:= 233; -- 0.11376953125 * 2048 = 233
--constant CC_CCOEF         : integer:= 1460;-- 0.712890625   * 2048 = 1460
--constant CC_DCOEF         : integer:= 1155;-- 0.56396484375 * 2048 = 1155

--  ACoeff' = 1/CCOEFF                                 = 2048/1460 =1,4027397260273972602739726027397 * 2048 = 2872,810958904109589041095890411
--  BCoeff' = ACOEFF/CCOEFF * (1-ACOEFF-BCOEFF)        = 2048(613/1460) * (1-613-233)=
--  CCoeff' = BCOEFF/DCOEFF * (1-ACOEFF-BCOEFF)
--  DCoeff' = 1/DCOEFF                                 = 2048/1155 =1,7731601731601731601731601731602 * 2048 = 3631,432034632034632034632034632
--  Roffset = Yoffset + Acoeff' * Coffset
--  Goffset = Yoffset + (Bcoeff' + Ccoeff') * Coffset
--  Boffset = Yoffset + Dcoeff' * Coffset

component Xil_YCrCb2RGB
generic (
FAMILY_HAS_MAC: integer:= 1;
FABRIC_ADDS   : integer:= 1;  -- Adders are implemented using logic fabric based adders
IWIDTH        : integer:= 9;
CWIDTH        : integer:= 13; -- Coefficients are signed, CWIDTH.CWIDTH-2 format
MWIDTH        : integer:= 23; -- ONLY FOR NON-V4: Controls bits witheld after mults.
OWIDTH        : integer:= 9;  -- OTHERWISE (default) IWIDTH+CWIDTH+1;
RGBMAX        : integer:= 255;
RGBMIN        : integer:= 0;
ACOEF         : integer:= 2872;   --  1.4023   *pow2(CWIDTH-2)
BCOEF         : integer:= -1461;  --  -0.7133  *pow2(CWIDTH-2)
CCOEF         : integer:= -703;   --  -0.3434  *pow2(CWIDTH-2)
DCOEF         : integer:= 3630;   --  1.7724   *pow2(CWIDTH-2)
ROFFSET       : integer:= -366592; -- Should be MWIDTH bits wide
GOFFSET       : integer:= 278016;
BOFFSET       : integer:= -463616;
HAS_CLIP      : integer:= 1;
HAS_CLAMP     : integer:= 1
);
port (
Y             : in  std_logic_vector(IWIDTH-1 downto 0);--Y  = a(R-G) + G + b(B-G)
Cr            : in  std_logic_vector(IWIDTH-1 downto 0);--Cr = d(R-Y)
Cb            : in  std_logic_vector(IWIDTH-1 downto 0);--Cb = c(B-Y)
R             : out std_logic_vector(OWIDTH-1 downto 0);
G             : out std_logic_vector(OWIDTH-1 downto 0);
B             : out std_logic_vector(OWIDTH-1 downto 0);
V_SYNC_in     : in  std_logic:='0';
H_SYNC_in     : in  std_logic:='0';
PIX_EN_in     : in  std_logic:='1';
V_SYNC_out    : out std_logic;
H_SYNC_out    : out std_logic;
PIX_EN_out    : out std_logic;
clk           : in  std_logic;
ce            : in  std_logic:='1';
sclr          : in  std_logic:='0'
);
end component;

----//core_gen
--component vcg_ycrcb2rgb
--port (
--video_data_in   : IN std_logic_VECTOR(23 downto 0);
--vblank_in       : IN std_logic;
--hblank_in       : IN std_logic;
--active_video_in : IN std_logic;
--
--video_data_out  : OUT std_logic_VECTOR(23 downto 0);
--vblank_out      : OUT std_logic;
--hblank_out      : OUT std_logic;
--active_video_out: OUT std_logic;
--
--ce              : IN std_logic;
--clk             : IN std_logic;
--sclr            : IN std_logic
--);
--end component;

signal ce                                : std_logic;
signal i_pixin_en                        : std_logic;
signal i_pixout_en                       : std_logic_vector(0 to G_DWIDTH/8-1);

Type TPixOut is array (0 to G_DWIDTH/8-1) of std_logic_vector(CC_OWIDTH-1 downto 0);
signal r                                 : TPixOut;
signal g                                 : TPixOut;
signal b                                 : TPixOut;

Type TPixIn is array (0 to G_DWIDTH/8-1) of std_logic_vector(CC_IWIDTH-1 downto 0);
signal y                                 : TPixIn;
signal u                                 : TPixIn;
signal v                                 : TPixIn;

Type TResult is array (0 to G_DWIDTH/8-1) of std_logic_vector(31 downto 0);
signal i_result                          : TResult;
signal i_result_en                       : std_logic_vector(0 to G_DWIDTH/8-1);

Type TPixInCount is array (0 to G_DWIDTH/8-1) of std_logic_vector(23 downto 0);
Type TPixOutCount is array (0 to G_DWIDTH/8-1) of std_logic_vector(23 downto 0);
signal i_pixin                           : TPixInCount;
signal i_pixout                          : TPixOutCount;


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
p_out_upp_rdy_n<=p_in_dwnp_rdy_n;-- when p_in_cfg_bypass='0' else p_in_dwnp_rdy_n;


--//-----------------------------
--//Вывод результата
--//-----------------------------
p_out_dwnp_wd   <=i_result_en(0) when p_in_cfg_bypass='0' else p_in_upp_wd;

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
ce<=not p_in_dwnp_rdy_n;
i_pixin_en<=p_in_upp_wd and not p_in_cfg_bypass;

gen_calc : for i in 0 to G_DWIDTH/8-1 generate
begin

y(i)<=EXT(p_in_upp_data((32*i + CC_IWIDTH*1)-1 downto 32*i + CC_IWIDTH*0), r(i)'length);
u(i)<=EXT(p_in_upp_data((32*i + CC_IWIDTH*2)-1 downto 32*i + CC_IWIDTH*1), g(i)'length);
v(i)<=EXT(p_in_upp_data((32*i + CC_IWIDTH*3)-1 downto 32*i + CC_IWIDTH*2), b(i)'length);

i_result(i)(CC_OWIDTH*1-1 downto CC_OWIDTH*0)<=b(i)(CC_OWIDTH-1 downto 0);
i_result(i)(CC_OWIDTH*2-1 downto CC_OWIDTH*1)<=g(i)(CC_OWIDTH-1 downto 0);
i_result(i)(CC_OWIDTH*3-1 downto CC_OWIDTH*2)<=r(i)(CC_OWIDTH-1 downto 0);
i_result(i)(31 downto CC_OWIDTH*3)<=(others=>'0');

i_result_en(i)<=i_pixout_en(i) and not p_in_dwnp_rdy_n;


m_YUV2RGB : Xil_YCrCb2RGB
generic map(
FAMILY_HAS_MAC=> 0,
FABRIC_ADDS   => 0,
IWIDTH        => CC_IWIDTH,
CWIDTH        => CC_CWIDTH,
MWIDTH        => CC_MWIDTH,
OWIDTH        => CC_OWIDTH,
RGBMAX        => CC_RGBMAX,
RGBMIN        => CC_RGBMIN,
ACOEF         => CC_ACOEF,
BCOEF         => CC_BCOEF,
CCOEF         => CC_CCOEF,
DCOEF         => CC_DCOEF,
ROFFSET       => CC_ROFFSET,
GOFFSET       => CC_GOFFSET,
BOFFSET       => CC_BOFFSET,
HAS_CLIP      => CC_HAS_CLIP,
HAS_CLAMP     => CC_HAS_CLAMP
)
port map(
Y             => y(i),
Cr            => v(i),
Cb            => u(i),
V_SYNC_in     => '0',
H_SYNC_in     => '0',
PIX_EN_in     => i_pixin_en,


R             => r(i),
G             => g(i),
B             => b(i),
V_SYNC_out    => open,
H_SYNC_out    => open,
PIX_EN_out    => i_pixout_en(i),

ce            => ce,
clk           => p_in_clk,
sclr          => p_in_rst
);

----//Core_gen
--i_pixin(i)(7 downto 0)<=y(i);
--i_pixin(i)(15 downto 8)<=v(i);
--i_pixin(i)(23 downto 16)<=u(i);
--
--g(i)<=i_pixout(i)(7 downto 0);
--b(i)<=i_pixout(i)(15 downto 8);
--r(i)<=i_pixout(i)(23 downto 16);
--
--m_YUV2RGB : vcg_ycrcb2rgb
--port map
--(
--video_data_in    => i_pixin(i),
--active_video_in  => i_pixin_en,
--vblank_in        => '0',
--hblank_in        => '0',
--
--video_data_out   => i_pixout(i),
--vblank_out       => open,
--hblank_out       => open,
--active_video_out => i_pixout_en(i),
--
--ce               => ce,
--clk              => p_in_clk,
--sclr             => p_in_rst
--);

end generate gen_calc;

--END MAIN
end behavioral;
