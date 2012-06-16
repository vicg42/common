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


signal i_buf_din          : std_logic_vector(G_VBUF_IWIDTH-1 downto 0);
signal i_buf_wr           : std_logic;
signal i_buf_rd           : std_logic;
signal i_buf_rd_en        : std_logic;
signal i_buf_empty        : std_logic;

signal i_pix_en           : std_logic;


--MAIN
begin


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
i_buf_rd<=i_pix_en and i_buf_rd_en;

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

dout   => p_out_vd,
rd_en  => i_buf_rd,
rd_clk => p_in_vclk,

full      => open,--p_out_vbufo_full,
empty     => i_buf_empty,
prog_full => p_out_vbufo_full,

rst    => p_in_rst
);

p_out_vbufo_empty<=i_buf_empty;

--END MAIN
end behavioral;
