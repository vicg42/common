-------------------------------------------------------------------------
-- Company     : Linkos
-- Engineer    : Golovachenko Victor
--
-- Create Date : 17.01.2012 12:27:16
-- Module Name : vout
--
-- Назначение/Описание :
--   Вывод видео
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

entity vout is
generic(
G_VBUF_IWIDTH : integer:=32;
G_VBUF_OWIDTH : integer:=32;
G_VSYN_ACTIVE : std_logic:='1'
);
port(
--Вых. видеопоток
p_out_vd         : out  std_logic_vector(G_VBUF_OWIDTH-1 downto 0);
p_in_vs          : in   std_logic;
p_in_hs          : in   std_logic;
p_in_vclk        : in   std_logic;

--Вх. видеопоток
p_in_vd          : in   std_logic_vector(G_VBUF_IWIDTH-1 downto 0);
p_in_vd_wr       : in   std_logic;
p_in_hd          : in   std_logic_vector(G_VBUF_IWIDTH-1 downto 0);
p_in_hd_wr       : in   std_logic;
p_in_sel         : in   std_logic;

p_out_vbufo_full : out  std_logic;
p_out_vbufo_empty: out  std_logic;
p_in_vbufo_wrclk : in   std_logic;

--Технологический
p_in_tst         : in   std_logic_vector(31 downto 0);
p_out_tst        : out  std_logic_vector(31 downto 0);

--System
p_in_rst         : in   std_logic
);
end vout;

architecture behavioral of vout is

component vout_buf
port(
din       : in  std_logic_vector(G_VBUF_IWIDTH-1 downto 0);
wr_en     : in  std_logic;
wr_clk    : in  std_logic;

dout      : out std_logic_vector(G_VBUF_OWIDTH-1 downto 0);
rd_en     : in  std_logic;
rd_clk    : in  std_logic;

full      : out std_logic;
prog_full : out std_logic;
empty     : out std_logic;

rst       : in  std_logic
);
end component;

signal i_buf_dout         : std_logic_vector(p_out_vd'range);
signal i_buf_din          : std_logic_vector(G_VBUF_IWIDTH-1 downto 0);
signal i_buf_wr           : std_logic;
signal i_buf_rd           : std_logic;
signal i_buf_rd_en        : std_logic;
signal i_buf_empty        : std_logic;

signal i_pix_en           : std_logic;

signal sr_sel             : std_logic_vector(0 to 1):=(others=>'0');
signal sr_vs              : std_logic_vector(0 to 1):=(others=>'0');
signal i_vs               : std_logic;
signal i_vs_edge          : std_logic;
signal i_hd_mrk_cnt       : std_logic_vector(2 downto 0);
signal i_hd_mrk           : std_logic;
signal i_hd_vden          : std_logic;

--MAIN
begin

--Технологические сигналы
p_out_tst(0)<=i_hd_mrk;
p_out_tst(1)<=i_buf_rd_en;
p_out_tst(2)<=i_vs_edge;
p_out_tst(3)<=i_hd_vden;
p_out_tst(31 downto 4)<=(others=>'0');

--Синхронизация чтения буфера
process(p_in_rst,p_in_vclk)
begin
  if p_in_rst='1' then
    i_buf_rd_en<='0';
  elsif p_in_vclk'event and p_in_vclk='1' then
    if p_in_vs=G_VSYN_ACTIVE and i_buf_empty='0' then
      i_buf_rd_en<='1';
    end if;
  end if;
end process;

--Управление буфером
i_pix_en<='1' when p_in_hs/=G_VSYN_ACTIVE and p_in_vs/=G_VSYN_ACTIVE else '0';
i_buf_rd<=i_pix_en and i_buf_rd_en when p_in_sel='0' else i_pix_en and i_buf_rd_en and i_hd_vden;

i_buf_wr <=p_in_hd_wr when p_in_sel='1' else p_in_vd_wr;
i_buf_din(63 downto 48)<=p_in_hd(47 downto 32) when p_in_sel='1' else p_in_vd(47 downto 32);--(15 downto  0)
i_buf_din(47 downto 32)<=p_in_hd(63 downto 48) when p_in_sel='1' else p_in_vd(63 downto 48);--(31 downto 16)
i_buf_din(31 downto 16)<=p_in_hd(15 downto  0) when p_in_sel='1' else p_in_vd(15 downto  0);--(47 downto 32)
i_buf_din(15 downto  0)<=p_in_hd(31 downto 16) when p_in_sel='1' else p_in_vd(31 downto 16);--(63 downto 48)

m_buf : vout_buf
port map(
din    => i_buf_din,
wr_en  => i_buf_wr,
wr_clk => p_in_vbufo_wrclk,

dout   => i_buf_dout,
rd_en  => i_buf_rd,
rd_clk => p_in_vclk,

full      => open,--p_out_vbufo_full,
empty     => i_buf_empty,
prog_full => p_out_vbufo_full,

rst    => p_in_rst
);

p_out_vbufo_empty<=i_buf_empty;

p_out_vd<=(EXT(i_hd_mrk_cnt,8)&EXT(i_hd_mrk_cnt,8)) when i_hd_mrk='1' else i_buf_dout;

i_vs<='1' when p_in_vs=G_VSYN_ACTIVE else '0';
i_vs_edge<=sr_vs(0) and not sr_vs(1);

process(p_in_vclk)
begin
  if p_in_vclk'event and p_in_vclk='1' then
    sr_sel<=(p_in_sel and i_buf_rd_en) & sr_sel(0 to 0);
    sr_vs<=i_vs & sr_vs(0 to 0);
  end if;
end process;

process(p_in_rst,p_in_vclk)
begin
  if p_in_rst='1' then
    i_hd_mrk_cnt<=(others=>'0');
    i_hd_mrk<='0';
    i_hd_vden<='0';

  elsif p_in_vclk'event and p_in_vclk='1' then

    if i_hd_mrk='0' then
        if sr_sel(0)='1' and sr_sel(1)='0' then
          i_hd_mrk<='1';--Разрешение выдачи маркера перед выводом записаного видео
        end if;
    else
        if i_vs_edge='1' then
          if i_hd_mrk_cnt=CONV_STD_LOGIC_VECTOR(4, i_hd_mrk_cnt'length) then
            i_hd_mrk<='0';
            i_hd_vden<='1';--Разрешение выдачи записаного видео
            i_hd_mrk_cnt<=(others=>'0');
          else
            i_hd_mrk_cnt<=i_hd_mrk_cnt+1;
          end if;
        end if;
    end if;

  end if;
end process;


--END MAIN
end behavioral;
