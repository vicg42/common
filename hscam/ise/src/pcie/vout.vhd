-------------------------------------------------------------------------
-- Company     : Linkos
-- Engineer    : Golovachenko Victor
--
-- Create Date : 21.01.2014 18:44:51
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
p_in_vclk_en     : in   std_logic;

--Вх. видеопоток
p_in_vbufo_di    : in   std_logic_vector(G_VBUF_IWIDTH-1 downto 0);
p_in_vbufo_wr    : in   std_logic;
p_in_vbufo_wrclk : in   std_logic;
p_out_vbufo_full : out  std_logic;
p_out_vbufo_empty: out  std_logic;
p_in_vbufo_en    : in   std_logic;

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
din    : in  std_logic_vector(G_VBUF_IWIDTH - 1 downto 0);
wr_en  : in  std_logic;
--wr_clk : in  std_logic;

dout   : out std_logic_vector(G_VBUF_IWIDTH - 1 downto 0);
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
din       : in  std_logic_vector(G_VBUF_IWIDTH - 1 downto 0);
wr_en     : in  std_logic;
wr_clk    : in  std_logic;

dout      : out std_logic_vector(G_VBUF_OWIDTH - 1 downto 0);
rd_en     : in  std_logic;
rd_clk    : in  std_logic;

full      : out std_logic;
empty     : out std_logic;

rst       : in  std_logic
);
end component;

signal i_bufi_dout        : std_logic_vector(G_VBUF_IWIDTH - 1 downto 0);
signal i_bufi_rd          : std_logic;
signal i_buf_dout         : std_logic_vector(p_out_vd'range);
signal i_buf_din          : std_logic_vector(G_VBUF_IWIDTH - 1 downto 0);
signal i_buf_wr           : std_logic;
signal i_buf_rd           : std_logic;
signal i_buf_empty        : std_logic;
signal i_bufo_full        : std_logic;
signal i_pix_en           : std_logic;


--MAIN
begin

--Технологические сигналы
p_out_tst(0) <= '0';
p_out_tst(1) <= '0';
p_out_tst(2) <= '0';
p_out_tst(3) <= '0';
p_out_tst(4) <= '0';
p_out_tst(31 downto 5) <= (others=>'0');


--128bit
i_buf_din((16 * 8) - 1 downto (16 * 7)) <= p_in_vbufo_di((16 * 7) - 1 downto (16 * 6));
i_buf_din((16 * 7) - 1 downto (16 * 6)) <= p_in_vbufo_di((16 * 8) - 1 downto (16 * 7));
i_buf_din((16 * 6) - 1 downto (16 * 5)) <= p_in_vbufo_di((16 * 5) - 1 downto (16 * 4));
i_buf_din((16 * 5) - 1 downto (16 * 4)) <= p_in_vbufo_di((16 * 6) - 1 downto (16 * 5));
i_buf_din((16 * 4) - 1 downto (16 * 3)) <= p_in_vbufo_di((16 * 3) - 1 downto (16 * 2));
i_buf_din((16 * 3) - 1 downto (16 * 2)) <= p_in_vbufo_di((16 * 4) - 1 downto (16 * 3));
i_buf_din((16 * 2) - 1 downto (16 * 1)) <= p_in_vbufo_di((16 * 1) - 1 downto (16 * 0));
i_buf_din((16 * 1) - 1 downto (16 * 0)) <= p_in_vbufo_di((16 * 2) - 1 downto (16 * 1));

m_bufi : vout_bufi
port map(
din    => i_buf_din,
wr_en  => p_in_vbufo_wr,

dout   => i_bufi_dout,
rd_en  => i_bufi_rd,

full      => open,
empty     => i_buf_empty,
prog_full => p_out_vbufo_full,

clk     => p_in_vbufo_wrclk,
srst    => p_in_rst
);

i_bufi_rd <= not i_buf_empty and not i_bufo_full;

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

i_pix_en <= '1' when p_in_hs /= G_VSYN_ACTIVE and p_in_vs /= G_VSYN_ACTIVE else '0';
i_buf_rd <= p_in_vclk_en and i_pix_en and p_in_vbufo_en;

p_out_vbufo_empty <= i_buf_empty;

p_out_vd <= i_buf_dout;


--END MAIN
end behavioral;
