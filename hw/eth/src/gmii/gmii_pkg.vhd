------------------------------------------------------------------------
-- Company     : Linkos
-- Engineer    : Golovachenko Victor
--
-- Create Date : 22.05.2012 17:53:28
-- Module Name : gmii_pkg
--
-- Description : Константы/Типы данных/
--
-- Revision:
-- Revision 0.01 - File Created
--
-------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_arith.all;

library work;
use work.vicg_common_pkg.all;

package gmii_pkg is

---------------------------------------------------------
--Типы
---------------------------------------------------------
constant C_GTCH_COUNT_MAX :integer:=2;


--//-------------------------------------------------
--//PHY Layer
--//-------------------------------------------------

--тип символа в 8b/10b
constant C_CHAR_K: std_logic:='1';
constant C_CHAR_D: std_logic:='0';

--коды 8b/10b
constant C_K23_7 : std_logic_vector(7 downto 0):=CONV_STD_LOGIC_VECTOR(16#F7#, 8);
constant C_K27_7 : std_logic_vector(7 downto 0):=CONV_STD_LOGIC_VECTOR(16#FB#, 8);
constant C_K28_1 : std_logic_vector(7 downto 0):=CONV_STD_LOGIC_VECTOR(16#3C#, 8);--comma
constant C_K28_5 : std_logic_vector(7 downto 0):=CONV_STD_LOGIC_VECTOR(16#BC#, 8);--comma
constant C_K28_7 : std_logic_vector(7 downto 0):=CONV_STD_LOGIC_VECTOR(16#FC#, 8);--comma
constant C_K29_7 : std_logic_vector(7 downto 0):=CONV_STD_LOGIC_VECTOR(16#FD#, 8);
constant C_K30_7 : std_logic_vector(7 downto 0):=CONV_STD_LOGIC_VECTOR(16#FE#, 8);

constant C_D2_2  : std_logic_vector(7 downto 0):=CONV_STD_LOGIC_VECTOR(16#42#, 8);
constant C_D5_6  : std_logic_vector(7 downto 0):=CONV_STD_LOGIC_VECTOR(16#C5#, 8);
constant C_D16_2 : std_logic_vector(7 downto 0):=CONV_STD_LOGIC_VECTOR(16#50#, 8);
constant C_D21_5 : std_logic_vector(7 downto 0):=CONV_STD_LOGIC_VECTOR(16#B5#, 8);


--примитивы
constant C_PDAT_I1  : std_logic_vector(15 downto 0):=C_D5_6 &C_K28_5;--//IDLE1
constant C_PDAT_I2  : std_logic_vector(15 downto 0):=C_D16_2&C_K28_5;--//IDLE2
constant C_PDAT_C1  : std_logic_vector(15 downto 0):=C_D21_5&C_K28_5;--//Configuration1
constant C_PDAT_C2  : std_logic_vector(15 downto 0):=C_D2_2 &C_K28_5;--//Configuration2
constant C_PDAT_R   : std_logic_vector(7 downto 0) :=C_K23_7        ;--//Carrier_extend
constant C_PDAT_S   : std_logic_vector(7 downto 0) :=C_K27_7        ;--//Start of packet
constant C_PDAT_T   : std_logic_vector(7 downto 0) :=C_K29_7        ;--//End of packet
constant C_PDAT_V   : std_logic_vector(7 downto 0) :=C_K30_7        ;--//Error propagation


---------------------------------------------------------
--Типы
---------------------------------------------------------
type TBus02_GTCH is array (0 to C_GTCH_COUNT_MAX-1) of std_logic_vector (1 downto 0);
type TBus03_GTCH is array (0 to C_GTCH_COUNT_MAX-1) of std_logic_vector (2 downto 0);
type TBus04_GTCH is array (0 to C_GTCH_COUNT_MAX-1) of std_logic_vector (3 downto 0);
type TBus07_GTCH is array (0 to C_GTCH_COUNT_MAX-1) of std_logic_vector (6 downto 0);
type TBus08_GTCH is array (0 to C_GTCH_COUNT_MAX-1) of std_logic_vector (7 downto 0);
type TBus16_GTCH is array (0 to C_GTCH_COUNT_MAX-1) of std_logic_vector (15 downto 0);
type TBus21_GTCH is array (0 to C_GTCH_COUNT_MAX-1) of std_logic_vector (20 downto 0);
type TBus32_GTCH is array (0 to C_GTCH_COUNT_MAX-1) of std_logic_vector (31 downto 0);


type TETH_ila is record
clk   : std_logic;
trig0 : std_logic_vector(63 downto 0);
data  : std_logic_vector(180 downto 0);
end record;


---------------------------------------------------------
--Прототипы функций
---------------------------------------------------------


end gmii_pkg;

