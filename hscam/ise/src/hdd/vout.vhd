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

use work.video_ctrl_pkg.all;

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
p_out_vsync      : out  TVSync;

--Технологический
p_in_tst         : in   std_logic_vector(31 downto 0);
p_out_tst        : out  std_logic_vector(31 downto 0);

--System
p_in_rst         : in   std_logic
);
end vout;

architecture behavioral of vout is

component vout_bufi
port(
din    : in  std_logic_vector(G_VBUF_IWIDTH-1 downto 0);
wr_en  : in  std_logic;
--wr_clk : in  std_logic;

dout   : out std_logic_vector(G_VBUF_IWIDTH-1 downto 0);
rd_en  : in  std_logic;
--rd_clk : in  std_logic;

full   : out std_logic;
prog_full : out std_logic;
empty  : out std_logic;

clk    : in  std_logic;
srst   : in  std_logic
);
end component;

component vout_bufo
port(
din       : in  std_logic_vector(G_VBUF_IWIDTH-1 downto 0);
wr_en     : in  std_logic;
wr_clk    : in  std_logic;

dout      : out std_logic_vector(G_VBUF_OWIDTH-1 downto 0);
rd_en     : in  std_logic;
rd_clk    : in  std_logic;

full      : out std_logic;
empty     : out std_logic;

rst       : in  std_logic
);
end component;

signal i_bufi_dout        : std_logic_vector(G_VBUF_IWIDTH-1 downto 0);
signal i_bufi_rd          : std_logic;
signal i_buf_dout         : std_logic_vector(p_out_vd'range);
signal i_buf_din          : std_logic_vector(G_VBUF_IWIDTH-1 downto 0);
signal i_buf_wr           : std_logic;
signal i_buf_rd           : std_logic;
signal i_buf_rd_en        : std_logic;
signal i_buf_empty        : std_logic;
signal i_bufo_full        : std_logic;
signal i_pix_en           : std_logic;

signal sr_sel             : std_logic_vector(0 to 1):=(others=>'0');
signal sr_vs              : std_logic_vector(0 to 1):=(others=>'0');
signal i_vs               : std_logic;
signal i_vs_edge          : std_logic;
signal i_hd_mrk_cnt       : std_logic_vector(2 downto 0);
signal i_hd_mrk           : std_logic;
signal i_hd_vden          : std_logic;

signal i_vsync            : TVSync;

--MAIN
begin

--Технологические сигналы
p_out_tst(0)<=i_hd_mrk;
p_out_tst(1)<=i_buf_rd_en;
p_out_tst(2)<=i_vs_edge;
p_out_tst(3)<=i_hd_vden;
p_out_tst(4)<=not sr_vs(0) and sr_vs(1);
p_out_tst(31 downto 5)<=(others=>'0');

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
i_buf_din(64+(64*0)-1 downto 48+(64*0))<=p_in_hd(48+(64*0)-1 downto 32+(64*0)) when p_in_sel='1' else p_in_vd(48+(64*0)-1 downto 32+(64*0));--(15 downto  0)
i_buf_din(48+(64*0)-1 downto 32+(64*0))<=p_in_hd(64+(64*0)-1 downto 48+(64*0)) when p_in_sel='1' else p_in_vd(64+(64*0)-1 downto 48+(64*0));--(31 downto 16)
i_buf_din(32+(64*0)-1 downto 16+(64*0))<=p_in_hd(16+(64*0)-1 downto  0+(64*0)) when p_in_sel='1' else p_in_vd(16+(64*0)-1 downto  0+(64*0));--(47 downto 32)
i_buf_din(16+(64*0)-1 downto  0+(64*0))<=p_in_hd(32+(64*0)-1 downto 16+(64*0)) when p_in_sel='1' else p_in_vd(32+(64*0)-1 downto 16+(64*0));--(63 downto 48)

--i_buf_din(64+(64*1)-1 downto 48+(64*1))<=p_in_hd(48+(64*1)-1 downto 32+(64*1)) when p_in_sel='1' else p_in_vd(48+(64*1)-1 downto 32+(64*1));--(15 downto  0)
--i_buf_din(48+(64*1)-1 downto 32+(64*1))<=p_in_hd(64+(64*1)-1 downto 48+(64*1)) when p_in_sel='1' else p_in_vd(64+(64*1)-1 downto 48+(64*1));--(31 downto 16)
--i_buf_din(32+(64*1)-1 downto 16+(64*1))<=p_in_hd(16+(64*1)-1 downto  0+(64*1)) when p_in_sel='1' else p_in_vd(16+(64*1)-1 downto  0+(64*1));--(47 downto 32)
--i_buf_din(16+(64*1)-1 downto  0+(64*1))<=p_in_hd(32+(64*1)-1 downto 16+(64*1)) when p_in_sel='1' else p_in_vd(32+(64*1)-1 downto 16+(64*1));--(63 downto 48)

m_bufi : vout_bufi
port map(
din    => i_buf_din,
wr_en  => i_buf_wr,
--wr_clk => p_in_vbufo_wrclk,

dout   => i_bufi_dout,
rd_en  => i_bufi_rd,
--rd_clk => p_in_vclk,

full      => open,
empty     => i_buf_empty,
prog_full => p_out_vbufo_full,

clk     => p_in_vbufo_wrclk,
srst    => p_in_rst
);

i_bufi_rd<=not i_buf_empty and not i_bufo_full;

m_bufo : vout_bufo
port map(
din    => i_bufi_dout,
wr_en  => i_bufi_rd,
wr_clk => p_in_vbufo_wrclk,

dout   => i_buf_dout,
rd_en  => i_buf_rd,
rd_clk => p_in_vclk,

full   => i_bufo_full,
empty  => open,

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

--Пересинхронизация КСИ,CСИ
process(p_in_vbufo_wrclk)
begin
  if p_in_vbufo_wrclk'event and p_in_vbufo_wrclk='1' then
    if p_in_vs=G_VSYN_ACTIVE then
      i_vsync.v<='1';
    else
      i_vsync.v<='0';
    end if;

    if p_in_hs=G_VSYN_ACTIVE then
      i_vsync.h<='1';
    else
      i_vsync.h<='0';
    end if;
  end if;
end process;

p_out_vsync<=i_vsync;

--END MAIN
end behavioral;
