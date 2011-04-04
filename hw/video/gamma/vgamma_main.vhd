-------------------------------------------------------------------------
-- Company     : Linkos
-- Engineer    : Golovachenko Victor
--
-- Create Date : 2010.07
-- Module Name : vgamma_main
--
-- Назначение/Описание :
--  Запись/Чтение регистров устройств
--
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

library unisim;
use unisim.vcomponents.all;

--library work;
--use work.vicg_common_pkg.all;
--use work.prj_def.all;

entity vgamma_main is
port
(
-------------------------------
-- Управление
-------------------------------
p_in_cfg_color             : in    std_logic;

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
p_out_tst                  : out   std_logic_vector(31 downto 0);

-------------------------------
--System
-------------------------------
p_in_clk            : in    std_logic;
p_in_rst            : in    std_logic
);
end vgamma_main;

architecture behavioral of vgamma_main is

constant dly : time := 1 ps;

component vgamma_bram_gray
port (
addra: IN  std_logic_VECTOR(6 downto 0);
dina : IN  std_logic_VECTOR(15 downto 0);
douta: OUT std_logic_VECTOR(15 downto 0);
ena  : IN  std_logic;
wea  : IN  std_logic_VECTOR(0 downto 0);
clka : IN  std_logic;
rsta : IN  std_logic;

addrb: IN  std_logic_VECTOR(7 downto 0);
dinb : IN  std_logic_VECTOR(7 downto 0);
doutb: OUT std_logic_VECTOR(7 downto 0);
enb  : IN  std_logic;
web  : IN  std_logic_VECTOR(0 downto 0);
clkb : IN  std_logic;
rstb : IN  std_logic
);
end component;

component vgamma_bram_rcol
port (
addra: IN  std_logic_VECTOR(6 downto 0);
dina : IN  std_logic_VECTOR(15 downto 0);
douta: OUT std_logic_VECTOR(15 downto 0);
ena  : IN  std_logic;
wea  : IN  std_logic_VECTOR(0 downto 0);
clka : IN  std_logic;
rsta : IN  std_logic;

addrb: IN  std_logic_VECTOR(7 downto 0);
dinb : IN  std_logic_VECTOR(7 downto 0);
doutb: OUT std_logic_VECTOR(7 downto 0);
enb  : IN  std_logic;
web  : IN  std_logic_VECTOR(0 downto 0);
clkb : IN  std_logic;
rstb : IN  std_logic
);
end component;

component vgamma_bram_gcol
port (
addra: IN  std_logic_VECTOR(6 downto 0);
dina : IN  std_logic_VECTOR(15 downto 0);
douta: OUT std_logic_VECTOR(15 downto 0);
ena  : IN  std_logic;
wea  : IN  std_logic_VECTOR(0 downto 0);
clka : IN  std_logic;
rsta : IN  std_logic;

addrb: IN  std_logic_VECTOR(7 downto 0);
dinb : IN  std_logic_VECTOR(7 downto 0);
doutb: OUT std_logic_VECTOR(7 downto 0);
enb  : IN  std_logic;
web  : IN  std_logic_VECTOR(0 downto 0);
clkb : IN  std_logic;
rstb : IN  std_logic
);
end component;

component vgamma_bram_bcol
port (
addra: IN  std_logic_VECTOR(6 downto 0);
dina : IN  std_logic_VECTOR(15 downto 0);
douta: OUT std_logic_VECTOR(15 downto 0);
ena  : IN  std_logic;
wea  : IN  std_logic_VECTOR(0 downto 0);
clka : IN  std_logic;
rsta : IN  std_logic;

addrb: IN  std_logic_VECTOR(7 downto 0);
dinb : IN  std_logic_VECTOR(7 downto 0);
doutb: OUT std_logic_VECTOR(7 downto 0);
enb  : IN  std_logic;
web  : IN  std_logic_VECTOR(0 downto 0);
clkb : IN  std_logic;
rstb : IN  std_logic
);
end component;

--signal i_clk                             : std_logic;

signal i_dwnp_wd                         : std_logic;

signal i_gray_out                        : std_logic_vector(31 downto 0);
signal i_color_out                       : std_logic_vector(31 downto 0);

signal i_coebuf_awrite                   : std_logic_vector(6 downto 0);
signal i_bufgray_wr                      : std_logic_vector(0 downto 0);
signal i_bufcolr_wr                      : std_logic_vector(0 downto 0);
signal i_bufcolg_wr                      : std_logic_vector(0 downto 0);
signal i_bufcolb_wr                      : std_logic_vector(0 downto 0);
signal i_bufgray_hout                    : std_logic_vector(16*(3+1)-1 downto 16*0);
signal i_bufcolr_hout                    : std_logic_vector(15 downto 0);
signal i_bufcolg_hout                    : std_logic_vector(15 downto 0);
signal i_bufcolb_hout                    : std_logic_vector(15 downto 0);



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


--//-----------------------------
--//Вывод результата
--//-----------------------------
p_out_dwnp_data <=i_gray_out when p_in_cfg_color='0' else i_color_out;
p_out_dwnp_wd   <=i_dwnp_wd;

p_out_upp_rdy_n <=p_in_dwnp_rdy_n;

process(p_in_rst,p_in_clk)
begin
  if p_in_rst='1' then
    i_dwnp_wd<='0';
  elsif p_in_clk'event and p_in_clk='1' then
--  if i_dwnp_rdy_n='0' then
    i_dwnp_wd<=p_in_upp_wd;
--  end if;
  end if;
end process;


--//------------------------------------------------------
--//RAM
--//------------------------------------------------------
--//Запись данных в буфера строк
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

i_bufgray_wr(0)<=p_in_cfg_dcoe_wr when p_in_cfg_coeram_num="00" else '0';
i_bufcolr_wr(0)<=p_in_cfg_dcoe_wr when p_in_cfg_coeram_num="01" else '0';
i_bufcolg_wr(0)<=p_in_cfg_dcoe_wr when p_in_cfg_coeram_num="10" else '0';
i_bufcolb_wr(0)<=p_in_cfg_dcoe_wr when p_in_cfg_coeram_num="11" else '0';

p_out_cfg_dcoe<=i_bufgray_hout(15 downto 0) when p_in_cfg_coeram_num="00" else
                i_bufcolr_hout when p_in_cfg_coeram_num="01" else
                i_bufcolg_hout when p_in_cfg_coeram_num="10" else
                i_bufcolb_hout;-- when p_in_cfg_coeram_num="11" else


gen_gamma_gray : for i in 0 to 3 generate
begin
m_ram : vgamma_bram_gray
port map
(
--//запись
addra=> i_coebuf_awrite,
dina => p_in_cfg_dcoe,
douta=> i_bufgray_hout(16*(i+1)-1 downto 16*i),
ena  => '1',
wea  => i_bufgray_wr,
clka => p_in_cfg_coe_wrclk,
rsta => p_in_rst,

--//чтние
addrb=> p_in_upp_data(8*(i+1)-1 downto 8*i),
dinb => "00000000",
doutb=> i_gray_out(8*(i+1)-1 downto 8*i),
enb  => '1',
web  => "0",
clkb => p_in_clk,
rstb => p_in_rst
);
end generate gen_gamma_gray;

m_gamma_rcol : vgamma_bram_rcol
port map
(
--//запись
addra=> i_coebuf_awrite,
dina => p_in_cfg_dcoe,
douta=> i_bufcolr_hout(15 downto 0),
ena  => '1',
wea  => i_bufcolr_wr,
clka => p_in_cfg_coe_wrclk,
rsta => p_in_rst,

--//чтние
addrb=> p_in_upp_data(7 downto 0),
dinb => "00000000",
doutb=> i_color_out(7 downto 0),
enb  => '1',
web  => "0",
clkb => p_in_clk,
rstb => p_in_rst
);

m_gamma_gcol : vgamma_bram_gcol
port map
(
--//запись
addra=> i_coebuf_awrite,
dina => p_in_cfg_dcoe,
douta=> i_bufcolg_hout(15 downto 0),
ena  => '1',
wea  => i_bufcolg_wr,
clka => p_in_cfg_coe_wrclk,
rsta => p_in_rst,

--//чтние
addrb=> p_in_upp_data(15 downto 8),
dinb => "00000000",
doutb=> i_color_out(15 downto 8),
enb  => '1',
web  => "0",
clkb => p_in_clk,
rstb => p_in_rst
);

m_gamma_bcol : vgamma_bram_bcol
port map
(
--//запись
addra=> i_coebuf_awrite,
dina => p_in_cfg_dcoe,
douta=> i_bufcolb_hout(15 downto 0),
ena  => '1',
wea  => i_bufcolb_wr,
clka => p_in_cfg_coe_wrclk,
rsta => p_in_rst,

--//чтние
addrb=> p_in_upp_data(23 downto 16),
dinb => "00000000",
doutb=> i_color_out(23 downto 16),
enb  => '1',
web  => "0",
clkb => p_in_clk,
rstb => p_in_rst
);


i_color_out(31 downto 24)<=(others=>'0');

--END MAIN
end behavioral;


