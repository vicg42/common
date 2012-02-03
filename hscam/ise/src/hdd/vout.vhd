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
p_out_vd          : out  std_logic_vector(G_VBUF_OWIDTH-1 downto 0);
p_in_vs           : in   std_logic;
p_in_hs           : in   std_logic;
p_in_vclk         : in   std_logic;

--Вх. видеобуфера
p_in_vbufout_d    : in   std_logic_vector(G_VBUF_IWIDTH-1 downto 0);
p_in_vbufout_wr   : in   std_logic;
p_out_vbufout_full: out  std_logic;
p_in_vbufout_wrclk: in   std_logic;

p_in_hbufout_d    : in   std_logic_vector(G_VBUF_IWIDTH-1 downto 0);
p_in_hbufout_wr   : in   std_logic;
p_in_hsel         : in   std_logic;

p_in_rst          : in   std_logic
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


signal i_vbufout_d         : std_logic_vector(G_VBUF_IWIDTH-1 downto 0);
signal i_vbufout_wr        : std_logic;

signal i_buf_rd_en         : std_logic;
signal i_buf_rd_tmp        : std_logic;
signal i_buf_rd            : std_logic;


--MAIN
begin

i_vbufout_d<=p_in_hbufout_d when p_in_hsel='1' else p_in_vbufout_d;
i_vbufout_wr<=p_in_hbufout_wr when p_in_hsel='1' else p_in_vbufout_wr;

i_buf_rd_tmp<='1' when p_in_hs/=G_VSYN_ACTIVE and p_in_vs/=G_VSYN_ACTIVE else '0';

process(p_in_rst,p_in_vclk)
begin
  if p_in_rst='1' then
    i_buf_rd_en<='0';
  elsif p_in_vclk'event and p_in_vclk='1' then
    if p_in_hs=G_VSYN_ACTIVE then
      i_buf_rd_en<='1';
    end if;
  end if;
end process;

i_buf_rd<=i_buf_rd_tmp and i_buf_rd_en;

m_buf : vout_buf
port map(
din    => i_vbufout_d,
wr_en  => i_vbufout_wr,
wr_clk => p_in_vbufout_wrclk,

dout   => p_out_vd,
rd_en  => i_buf_rd,
rd_clk => p_in_vclk,

full      => open,
empty     => open,
prog_full => p_out_vbufout_full,

rst    => p_in_rst
);


--END MAIN
end behavioral;
