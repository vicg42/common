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

use work.sata_testgen_pkg.all;

entity vin_hdd is
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

--Вых. видеобуфера
p_in_vbufin_rdclk  : in   std_logic;

p_out_vbufin_d     : out  std_logic_vector(G_VBUF_OWIDTH-1 downto 0);
p_in_vbufin_rd     : in   std_logic;
p_out_vbufin_empty : out  std_logic;
p_out_vbufin_full  : out  std_logic;
p_out_vbufin_pfull : out  std_logic;
p_out_vbufin_wrcnt : out  std_logic_vector(3 downto 0);

p_in_hdd_tstgen    : in   THDDTstGen;

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
--wr_clk : in std_logic;

dout   : out std_logic_vector(G_VBUF_OWIDTH-1 downto 0);
rd_en  : in std_logic;
--rd_clk : in std_logic;

empty  : out std_logic;
full   : out std_logic;
prog_full     : out std_logic;
--rd_data_count : out std_logic_vector(3 downto 0);
data_count : out std_logic_vector(3 downto 0);

clk    : in std_logic;
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
signal i_buf_empty         : std_logic_vector(CI_BUF_COUNT-1 downto 0):=(others=>'1');
signal i_buf_full          : std_logic_vector(CI_BUF_COUNT-1 downto 0):=(others=>'0');
signal g_buf_dout          : std_logic_vector(31 downto 0);
signal g_buf_rd            : std_logic;

signal sr_hdd_hw_work      : std_logic;
signal syn_start           : std_logic;

signal i_hdd_tst_on_tmp    : std_logic;
signal i_hdd_hw_work       : std_logic;
signal i_hdd_tst_d         : std_logic_vector(31 downto 0);
signal i_hdd_tst_den       : std_logic;
signal i_hdd_tst_on        : std_logic;
signal i_hdd_vbuf_rst      : std_logic;
signal i_hdd_vbuf_din      : std_logic_vector(31 downto 0);
signal i_hdd_vbuf_wr       : std_logic;
signal i_vbufin_full       : std_logic;


--MAIN
begin

--//----------------------------------
--//Технологические сигналы
--//----------------------------------
p_out_tst(0)<=g_buf_rd;
p_out_tst(31 downto 1)<=(others=>'0');


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
    sr_hdd_hw_work<='0';
    syn_start<='0';
  elsif p_in_vclk'event and p_in_vclk='1' then

    sr_hdd_hw_work<=i_hdd_hw_work and not i_hdd_tst_on;
    if sr_hdd_hw_work='1' and p_in_vs=G_VSYN_ACTIVE then
      syn_start<='1';
    else
      syn_start<='0';
    end if;

    if p_in_vs=G_VSYN_ACTIVE or p_in_hs=G_VSYN_ACTIVE or syn_start='0' then
      i_buf_wr<='0';
    else
      i_buf_wr<=not i_buf_wr;
    end if;
  end if;
end process;

--//Буфера:
gen_buf : for i in 0 to CI_BUF_COUNT-1 generate

i_buf_din(i)<=i_buf_din_vector(32*(i+1)-1 downto 32*i);

m_buf : vin_bufhdd
port map(
din    => i_buf_din(i),
wr_en  => i_buf_wr,
wr_clk => p_in_vclk,

dout   => i_buf_dout(i)(31 downto 0),
rd_en  => i_buf_rd(i),
rd_clk => p_in_vbufin_rdclk,

full   => i_buf_full(i),
empty  => i_buf_empty(i),

rst    => i_hdd_vbuf_rst
);

i_buf_rd(i)<=g_buf_rd when i_buf_cnt=i else '0';

end generate gen_buf;

--//Чтение:
process(p_in_rst,p_in_vbufin_rdclk)
begin
  if p_in_rst='1' then
    i_buf_cnt<=0;
  elsif p_in_vbufin_rdclk'event and p_in_vbufin_rdclk='1' then
    if g_buf_rd='1' then
      if i_buf_cnt=CI_BUF_COUNT-1 then
        i_buf_cnt<=0;
      else
        i_buf_cnt<=i_buf_cnt + 1;
      end if;
    end if;
  end if;
end process;

g_buf_dout<=i_buf_dout(4) when i_buf_cnt=4 else
            i_buf_dout(3) when i_buf_cnt=3 else
            i_buf_dout(2) when i_buf_cnt=2 else
            i_buf_dout(1) when i_buf_cnt=1 else
            i_buf_dout(0);-- when i_buf_cnt=0;

g_buf_rd<=not OR_reduce(i_buf_empty);


m_hdd_testgen : sata_testgen
generic map(
G_SCRAMBLER => "ON"
)
port map(
p_in_gen_cfg   => p_in_hdd_tstgen,

p_out_rdy      => i_hdd_tst_on,
p_out_hwon     => i_hdd_hw_work,

p_out_tdata    => i_hdd_tst_d,
p_out_tdata_en => i_hdd_tst_den,

p_in_clk       => p_in_vbufin_rdclk,
p_in_rst       => p_in_rst
);

i_hdd_vbuf_rst<=p_in_rst or p_in_hdd_tstgen.clr_err;

--//Выбор данных для модуля dsn_hdd.vhd
i_hdd_vbuf_din<=i_hdd_tst_d   when i_hdd_tst_on='1' and p_in_hdd_tstgen.con2rambuf='1' else g_buf_dout;
i_hdd_vbuf_wr <=i_hdd_tst_den when i_hdd_tst_on='1' and p_in_hdd_tstgen.con2rambuf='1' else g_buf_rd;

m_bufout : hdd_rambuf_infifo
port map(
din       => i_hdd_vbuf_din,
wr_en     => i_hdd_vbuf_wr,
--wr_clk    => p_in_vbufin_rdclk,

dout      => p_out_vbufin_d,
rd_en     => p_in_vbufin_rd,
--rd_clk    => p_in_hdd_vbuf_rdclk,

empty     => p_out_vbufin_empty,
full      => i_vbufin_full,
prog_full => p_out_vbufin_pfull,
--rd_data_count => p_out_vbufin_wrcnt,
data_count => p_out_vbufin_wrcnt,

clk       => p_in_vbufin_rdclk,
rst       => i_hdd_vbuf_rst
);

p_out_vbufin_full<=i_vbufin_full when i_hdd_tst_on='1' and p_in_hdd_tstgen.con2rambuf='1' else (AND_reduce(i_buf_full) and i_vbufin_full);

--END MAIN
end behavioral;
