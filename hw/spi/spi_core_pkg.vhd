-------------------------------------------------------------------------
-- Company     : Yansar
-- Engineer    : Golovachenko Victor
--
-- Create Date : 18.06.2014 14:01:47
-- Module Name : spi_pkg
--
-- Description :
--
-- Revision:
-- Revision 0.01 - File Created
--
-------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;

package spi_pkg is

constant C_SPI_WRITE : std_logic := '1';
constant C_SPI_READ  : std_logic := '0';

type TSPI_pinout is record
sck  : std_logic;
ss_n : std_logic;
mosi : std_logic;--Master OUT, Slave IN
end record;

type TSPI_pinin is record
miso : std_logic;--Master IN, Slave OUT
end record;

end package spi_pkg;
