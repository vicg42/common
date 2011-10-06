------------------------------------------------------------------------
-- Company     : Linkos
-- Engineer    : Golovachenko Victor
--
-- Create Date : 05.09.2011 10:45:48
-- Module Name : sata_testgen_pkg
--
-- Description : Константы/Типы данных/
--               используемые в sata_tstgen
--
-- Revision:
-- Revision 0.01 - File Created
--
-------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_arith.all;

package sata_testgen_pkg is

type THDDTstGen is record
con2rambuf : std_logic;
tesing_on  : std_logic;
tesing_spd : std_logic_vector(7 downto 0);
start      : std_logic;
stop       : std_logic;
clr_err    : std_logic;
td_zero    : std_logic;
end record;

component sata_testgen
generic(
G_SCRAMBLER : string:="OFF"
);
port(
---------------------------------
--USR
---------------------------------
p_in_gen_cfg   : in   THDDTstGen;

p_out_rdy      : out  std_logic;
p_out_hwon     : out  std_logic;

p_out_tdata    : out  std_logic_vector(31 downto 0);
p_out_tdata_en : out  std_logic;

--------------------------------
--System
--------------------------------
p_in_clk       : in   std_logic;
p_in_rst       : in   std_logic
);
end component;


end sata_testgen_pkg;


package body sata_testgen_pkg is

---------------------------------------------------------
--Функции
---------------------------------------------------------


end sata_testgen_pkg;


