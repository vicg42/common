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
G_VSYN_ACTIVE : std_logic:='1'
);
port(
--Вых. видеопоток
p_out_vd          : out  std_logic_vector(31 downto 0);
p_in_vs           : in   std_logic;
p_in_hs           : in   std_logic;
p_in_vclk         : in   std_logic;

--Вх. видеобуфера
p_in_vbufout_d    : in   std_logic_vector(31 downto 0);
p_in_vbufout_wr   : in   std_logic;
p_out_vbufout_full: out  std_logic;
p_in_vbufout_wrclk: in   std_logic;

p_in_rst          : in   std_logic
);
end vout;

architecture behavioral of vout is

component vout_buf
port(
din       : in  std_logic_vector(31 downto 0);
wr_en     : in  std_logic;
wr_clk    : in  std_logic;

dout      : out std_logic_vector(31 downto 0);
rd_en     : in  std_logic;
rd_clk    : in  std_logic;

full      : out std_logic;
prog_full : out std_logic;
empty     : out std_logic;

rst       : in  std_logic
);
end component;


signal i_buf_rd            : std_logic;

--MAIN
begin

i_buf_rd<='1' when p_in_hs/=G_VSYN_ACTIVE and p_in_vs/=G_VSYN_ACTIVE else '0';

m_buf : vout_buf
port map(
din    => p_in_vbufout_d,
wr_en  => p_in_vbufout_wr,
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
