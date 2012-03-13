-------------------------------------------------------------------------
-- Company     : Linkos
-- Engineer    : Golovachenko Victor
--
-- Create Date : 17.01.2012 12:27:16
-- Module Name : vin_hdd
--
-- Назначение/Описание :
--   Прием видеоданных для записи на HDD
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

entity vin_hdd is
generic(
G_VBUF_OWIDTH : integer:=32;
G_VSYN_ACTIVE : std_logic:='1'
);
port(
--Вх. видеопоток
p_in_vd            : in   std_logic_vector((10*8*2)-1 downto 0);--(99 downto 0);
p_in_vs            : in   std_logic;
p_in_hs            : in   std_logic;
p_in_vclk          : in   std_logic;

p_out_vfr_prm      : out  TFrXY;

--Вых. видеобуфера
p_out_vbufin_d     : out  std_logic_vector(G_VBUF_OWIDTH-1 downto 0);
p_in_vbufin_rd     : in   std_logic;
p_out_vbufin_empty : out  std_logic;
p_out_vbufin_full  : out  std_logic;
p_in_vbufin_wrclk  : in   std_logic;
p_in_vbufin_rdclk  : in   std_logic;

--Технологический
p_in_tst           : in    std_logic_vector(31 downto 0);
p_out_tst          : out   std_logic_vector(31 downto 0);

--System
p_in_rst           : in   std_logic
);
end vin_hdd;

architecture behavioral of vin_hdd is

constant CI_BUF_COUNT : integer:=5;

component vin_bufhdd
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

component hdd_rambuf_infifo
port(
din    : in std_logic_vector(31 downto 0);
wr_en  : in std_logic;
wr_clk : in std_logic;

dout   : out std_logic_vector(G_VBUF_OWIDTH-1 downto 0);
rd_en  : in std_logic;
rd_clk : in std_logic;

empty  : out std_logic;
full   : out std_logic;
prog_full     : out std_logic;
rd_data_count : out std_logic_vector(3 downto 0);
--data_count : out std_logic_vector(3 downto 0);

--clk    : in std_logic;
rst    : in std_logic
);
end component;

--signal i_vd                : std_logic_vector(p_in_vd'length-(10*2)-1 downto 0):=(others=>'0');
--signal i_vd_save           : std_logic_vector(p_in_vd'length-(10*2)-1 downto 0):=(others=>'0');
--signal i_bufi_din_vector    : std_logic_vector((i_vd'length*2)-1 downto 0);
signal i_bufi_cnt           : integer range 0 to CI_BUF_COUNT;
signal i_bufi_wr_en         : std_logic:='0';
signal i_bufi_wr            : std_logic;
signal i_bufi_rd            : std_logic_vector(CI_BUF_COUNT-1 downto 0);
type TBufData  is array (0 to CI_BUF_COUNT-1) of std_logic_vector(31 downto 0);
signal i_bufi_din           : TBufData;
signal i_bufi_dout          : TBufData;
signal i_bufi_empty         : std_logic_vector(CI_BUF_COUNT-1 downto 0);
signal i_bufi_full          : std_logic_vector(CI_BUF_COUNT-1 downto 0);
signal i_bufo_din           : std_logic_vector(31 downto 0);
signal i_bufo_wr            : std_logic;



--MAIN
begin

--//----------------------------------
--//Технологические сигналы
--//----------------------------------
p_out_tst(0)<=i_bufo_wr;
p_out_tst(1)<=i_bufi_wr;
p_out_tst(2)<=i_bufi_wr_en;
p_out_tst(3)<=OR_reduce(i_bufi_full);
p_out_tst(31 downto 4)<=(others=>'0');

p_out_vfr_prm.pix<=CONV_STD_LOGIC_VECTOR(C_PCFG_FRPIX, p_out_vfr_prm.pix'length);
p_out_vfr_prm.row<=CONV_STD_LOGIC_VECTOR(C_PCFG_FRROW, p_out_vfr_prm.row'length);

--//BUFI - Запись:
----//Берем 8 старших бит из пердолгаемых 10 бит на 1Pixel
--gen_vd : for i in 1 to 10 generate
--i_vd((8*i)-1 downto 8*(i-1))<=p_in_vd((10*i)-1 downto (10*i)-8);
--process(p_in_vclk)
--begin
--  if p_in_vclk'event and p_in_vclk='1' then
--    i_vd_save((8*i)-1 downto 8*(i-1))<=i_vd((8*i)-1 downto 8*(i-1));
--  end if;
--end process;
--end generate gen_vd;
--
--i_bufi_din_vector<=i_vd & i_vd_save;

process(p_in_rst,p_in_vclk)
begin
  if p_in_rst='1' then
    i_bufi_wr<='0';
    i_bufi_wr_en<='0';

  elsif p_in_vclk'event and p_in_vclk='1' then

    if p_in_vs=G_VSYN_ACTIVE then
      i_bufi_wr_en<='1';
    end if;

    if i_bufi_wr_en='1' and p_in_vs/=G_VSYN_ACTIVE and p_in_hs/=G_VSYN_ACTIVE then
      i_bufi_wr<=not i_bufi_wr;
    else
      i_bufi_wr<='0';
    end if;
  end if;
end process;

--//Буфера:
gen_bufi : for i in 0 to CI_BUF_COUNT-1 generate

i_bufi_din(i)<=p_in_vd(32*(i+1)-1 downto 32*i);--i_bufi_din_vector(32*(i+1)-1 downto 32*i);

m_bufi : vin_bufhdd
port map(
din    => i_bufi_din(i),
wr_en  => i_bufi_wr,
wr_clk => p_in_vclk,

dout   => i_bufi_dout(i)(31 downto 0),
rd_en  => i_bufi_rd(i),
rd_clk => p_in_vbufin_wrclk,

full   => i_bufi_full(i),
empty  => i_bufi_empty(i),

rst    => p_in_rst
);

i_bufi_rd(i)<=i_bufo_wr when i_bufi_cnt=i else '0';

end generate gen_bufi;

--//BUFI - Чтение:
process(p_in_rst,p_in_vbufin_wrclk)
begin
  if p_in_rst='1' then
    i_bufi_cnt<=0;
  elsif p_in_vbufin_wrclk'event and p_in_vbufin_wrclk='1' then
    if i_bufo_wr='1' then
      if i_bufi_cnt=CI_BUF_COUNT-1 then
        i_bufi_cnt<=0;
      else
        i_bufi_cnt<=i_bufi_cnt + 1;
      end if;
    end if;
  end if;
end process;

i_bufo_wr<=not AND_reduce(i_bufi_empty);

i_bufo_din<=i_bufi_dout(4) when i_bufi_cnt=4 else
            i_bufi_dout(3) when i_bufi_cnt=3 else
            i_bufi_dout(2) when i_bufi_cnt=2 else
            i_bufi_dout(1) when i_bufi_cnt=1 else
            i_bufi_dout(0);-- when i_bufi_cnt=0;

m_bufo : hdd_rambuf_infifo
port map(
din       => i_bufo_din,
wr_en     => i_bufo_wr,
wr_clk    => p_in_vbufin_wrclk,

dout      => p_out_vbufin_d,
rd_en     => p_in_vbufin_rd,
rd_clk    => p_in_vbufin_rdclk,

empty     => p_out_vbufin_empty,
full      => p_out_vbufin_full,
prog_full => open,
rd_data_count => open,
--data_count => p_out_vbufin_wrcnt,

--clk       => p_in_vbufin_rdclk,
rst       => p_in_rst
);


--END MAIN
end behavioral;
