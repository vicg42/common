-------------------------------------------------------------------------
-- Company     : Linkos
-- Engineer    : Golovachenko Victor
--
-- Create Date : 23.09.2013 11:46:43
-- Module Name : cfgdev_buf
--
-- Revision:
-- Revision 0.01 - File Created
--
-------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;

entity cfgdev_buf is
generic (
G_DWIDTH : integer := 32
);
port(
din         : in  std_logic_vector(G_DWIDTH - 1 downto 0);
wr_en       : in  std_logic;
wr_clk      : in  std_logic;

dout        : out std_logic_vector(G_DWIDTH - 1 downto 0);
rd_en       : in  std_logic;
rd_clk      : in  std_logic;

empty       : out std_logic;
full        : out std_logic;
prog_full   : out std_logic;

rst         : in  std_logic
);
end cfgdev_buf;

architecture behavioral of cfgdev_buf is

component cfgdev_fifo
port(
din         : in  std_logic_vector(G_DWIDTH - 1 downto 0);
wr_en       : in  std_logic;
--wr_clk      : in  std_logic;

dout        : out std_logic_vector(G_DWIDTH - 1 downto 0);
rd_en       : in  std_logic;
--rd_clk      : in  std_logic;

empty       : out std_logic;
full        : out std_logic;
prog_full   : out std_logic;

clk         : in  std_logic;
rst         : in  std_logic
);
end component;


--MAIN
begin


m_fifo : cfgdev_fifo
port map(
din         => din,
wr_en       => wr_en,
--wr_clk      => ,

dout        => dout,
rd_en       => rd_en,
--rd_clk      => ,

empty       => empty,
full        => full,
prog_full   => prog_full,

clk         => wr_clk,
rst         => rst
);


--END MAIN
end behavioral;
