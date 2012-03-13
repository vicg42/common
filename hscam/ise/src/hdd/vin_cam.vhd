-------------------------------------------------------------------------
-- Company     : Linkos
-- Engineer    : Golovachenko Victor
--
-- Create Date : 17.01.2012 12:27:16
-- Module Name : vin_cam
--
-- Назначение/Описание :
--   Прием видеоданных для записи в RAM
--
-- Revision:
-- Revision 0.01 - File Created
--
--------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_misc.all;
use ieee.std_logic_unsigned.all;

library work;
use work.prj_cfg.all;
use work.video_ctrl_pkg.all;

entity vin_cam is
generic(
G_VBUF_OWIDTH : integer:=32;
G_VSYN_ACTIVE : std_logic:='1'
);
port(
--Вх. видеопоток
p_in_vd            : in   std_logic_vector(99 downto 0);
p_in_vs            : in   std_logic;
p_in_hs            : in   std_logic;
p_in_vclk          : in   std_logic;

p_out_vfr_prm      : out  TFrXY;

--Вых. видеобуфера
p_out_vbufin_d     : out  std_logic_vector(G_VBUF_OWIDTH-1 downto 0);
p_in_vbufin_rd     : in   std_logic;
p_out_vbufin_empty : out  std_logic;
p_in_vbufin_rdclk  : in   std_logic;
p_in_vbufin_wrclk  : in   std_logic;

--Технологический
p_in_tst           : in    std_logic_vector(31 downto 0);
p_out_tst          : out   std_logic_vector(31 downto 0);

--System
p_in_rst           : in   std_logic
);
end vin_cam;

architecture behavioral of vin_cam is

constant CI_BUF_COUNT : integer:=5;

component vin_bufcam
port(
din    : in  std_logic_vector(31 downto 0);
wr_en  : in  std_logic;
wr_clk : in  std_logic;

dout   : out std_logic_vector(31 downto 0);
rd_en  : in  std_logic;
rd_clk : in  std_logic;

full   : out std_logic;
empty  : out std_logic;

rst    : in  std_logic
);
end component;

component vin_bufout
port(
din    : in std_logic_vector(31 downto 0);
wr_en  : in std_logic;
wr_clk : in std_logic;

dout   : out std_logic_vector(G_VBUF_OWIDTH-1 downto 0);
rd_en  : in std_logic;
rd_clk : in std_logic;

empty  : out std_logic;
full   : out std_logic;

--clk    : in std_logic;
rst    : in std_logic
);
end component;

signal i_vd                : std_logic_vector(p_in_vd'length-(10*2)-1 downto 0):=(others=>'0');
signal i_vd_save           : std_logic_vector(p_in_vd'length-(10*2)-1 downto 0):=(others=>'0');

signal i_buf_cnt           : integer range 0 to CI_BUF_COUNT-1;
signal i_buf_wr_en         : std_logic:='0';
signal i_buf_wr            : std_logic;
signal i_buf_rd            : std_logic_vector(CI_BUF_COUNT-1 downto 0);
signal i_buf_din_vector    : std_logic_vector((i_vd'length*2)-1 downto 0);
type TBufData  is array (0 to CI_BUF_COUNT-1) of std_logic_vector(31 downto 0);
signal i_buf_din           : TBufData;
signal i_buf_dout          : TBufData;
signal i_buf_empty         : std_logic_vector(CI_BUF_COUNT-1 downto 0);
signal i_bufout_din        : std_logic_vector(31 downto 0);
signal i_bufout_wr         : std_logic;


--MAIN
begin

p_out_vfr_prm.pix <=(others=>'0');
p_out_vfr_prm.row <=(others=>'0');
p_out_vfr_prm.total_dw<=CONV_STD_LOGIC_VECTOR(((C_PCFG_FRPIX/(G_VBUF_OWIDTH/8))*C_PCFG_FRROW), p_out_vfr_prm.total_dw'length);

--//Запись:
--//Берем 8 старших бит из пердолгаемых 10 бит на 1Pixel
gen_vd : for i in 1 to 10 generate
i_vd((8*i)-1 downto 8*(i-1))<=p_in_vd((10*i)-1 downto (10*i)-8);
process(p_in_vclk)
begin
  if p_in_vclk'event and p_in_vclk='1' then
    i_vd_save((8*i)-1 downto 8*(i-1))<=i_vd((8*i)-1 downto 8*(i-1));
  end if;
end process;
end generate gen_vd;

i_buf_din_vector<=i_vd & i_vd_save;

process(p_in_rst,p_in_vclk)
begin
  if p_in_rst='1' then
    i_buf_wr<='0';
    i_buf_wr_en<='0';

  elsif p_in_vclk'event and p_in_vclk='1' then

    if p_in_vs=G_VSYN_ACTIVE then
      i_buf_wr_en<='1';
    end if;

    if i_buf_wr_en='1' and p_in_vs/=G_VSYN_ACTIVE and p_in_hs/=G_VSYN_ACTIVE then
      i_buf_wr<=not i_buf_wr;
    else
      i_buf_wr<='0';
    end if;
  end if;
end process;

--//Буфера:
gen_buf : for i in 0 to CI_BUF_COUNT-1 generate

i_buf_din(i)<=i_buf_din_vector(32*(i+1)-1 downto 32*i);

m_buf : vin_bufcam
port map(
din    => i_buf_din(i),
wr_en  => i_buf_wr,
wr_clk => p_in_vclk,

dout   => i_buf_dout(i)(31 downto 0),
rd_en  => i_buf_rd(i),
rd_clk => p_in_vbufin_wrclk,

full   => open,
empty  => i_buf_empty(i),

rst    => p_in_rst
);

i_buf_rd(i)<=i_bufout_wr when i_buf_cnt=i else '0';

end generate gen_buf;

--//Чтение:
process(p_in_rst,p_in_vbufin_wrclk)
begin
  if p_in_rst='1' then
    i_buf_cnt<=0;
  elsif p_in_vbufin_wrclk'event and p_in_vbufin_wrclk='1' then
    if i_bufout_wr='1' then
      if i_buf_cnt=CI_BUF_COUNT-1 then
        i_buf_cnt<=0;
      else
        i_buf_cnt<=i_buf_cnt + 1;
      end if;
    end if;
  end if;
end process;

i_bufout_din<=i_buf_dout(4) when i_buf_cnt=4 else
              i_buf_dout(3) when i_buf_cnt=3 else
              i_buf_dout(2) when i_buf_cnt=2 else
              i_buf_dout(1) when i_buf_cnt=1 else
              i_buf_dout(0);-- when i_buf_cnt=0;

i_bufout_wr<=not AND_reduce(i_buf_empty);

m_bufout : vin_bufout
port map(
din    => i_bufout_din,
wr_en  => i_bufout_wr,
wr_clk => p_in_vbufin_wrclk,

dout   => p_out_vbufin_d,
rd_en  => p_in_vbufin_rd,
rd_clk => p_in_vbufin_rdclk,

empty  => p_out_vbufin_empty,
full   => open,

--clk    : in std_logic;
rst    => p_in_rst
);

--END MAIN
end behavioral;
