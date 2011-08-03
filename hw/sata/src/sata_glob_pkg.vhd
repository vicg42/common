------------------------------------------------------------------------
-- Company     : Linkos
-- Engineer    : Golovachenko Victor
--
-- Create Date : 28.07.2011 16:03:04
-- Module Name : sata_glob_pkg
--
-- Description : Глобальные Константы/Типы данных/
--               Используется вместе с модуля dsn_hdd_pkg.vhd + dsn_hdd.vhd
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

package sata_glob_pkg is

---------------------------------------------------------
--Типы
---------------------------------------------------------
type TSH_04GTCHCount is array (0 to 3) of integer;
type TSH_08Count is array (0 to 7) of integer;
type TSH_08CountSel is array (0 to 1) of TSH_08Count;


---------------------------------------------------------
--User Cfg
---------------------------------------------------------
--//Назначаем тип FPGA:
--//0 - "V5_GTP"
--//1 - "V5_GTX"
--//2 - "V6_GTX"
--//3 - "S6_GTPA"
constant C_SH_FPGA_TYPE      : integer:=0;
constant C_SH_MAIN_NUM       : integer:=0; --//определяем индекс GT модуля от которого будем брать частоту для тактирования sata_dcm.vhd


---------------------------------------------------------
--Константы
---------------------------------------------------------
--//мах кол-во HDD:
constant C_HDD_COUNT_MAX     : integer:=8;--//

--//Кол-во каналов в одном модуле GT:
constant C_SH_GTCH_COUNT_MAX_SEL: TSH_04GTCHCount:=(2, 2, 1, 2);--//Мax кол-во каналов для одного компонента GT(gig tx/rx)
constant C_SH_GTCH_COUNT_MAX    : integer:=C_SH_GTCH_COUNT_MAX_SEL(C_SH_FPGA_TYPE);


--//Общее кол-во модулей GT:
---------------------------------------------------------------------------
--//G_HDD_COUNT - значения:               | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 |
---------------------------------------------------------------------------
constant C_SH_2CGT_COUNT   : TSH_08Count:=(  1,  1,  2,  2,  3,  3,  4,  4 );--//Для GT с двумя каналами(DUAL)
constant C_SH_1CGT_COUNT   : TSH_08Count:=(  1,  2,  3,  4,  5,  6,  7,  8 );--//Для GT c одним каналом
constant C_SH_GT_COUNT_SEL : TSH_08CountSel:=(C_SH_1CGT_COUNT, C_SH_2CGT_COUNT);

constant C_SH_COUNT_MAX    : TSH_08Count:=C_SH_GT_COUNT_SEL(C_SH_GTCH_COUNT_MAX-1);



---------------------------------------------------------
--Типы
---------------------------------------------------------
type TBus32_SHCountMax is array (0 to C_HDD_COUNT_MAX-1) of std_logic_vector(31 downto 0);
type TBus16_SHCountMax is array (0 to C_HDD_COUNT_MAX-1) of std_logic_vector(15 downto 0);
type TBus02_SHCountMax is array (0 to C_HDD_COUNT_MAX-1) of std_logic_vector(1 downto 0);
type TBus03_SHCountMax is array (0 to C_HDD_COUNT_MAX-1) of std_logic_vector(2 downto 0);
type TBus04_SHCountMax is array (0 to C_HDD_COUNT_MAX-1) of std_logic_vector(3 downto 0);



---------------------------------------------------------
--DBG
---------------------------------------------------------
type TSH_ila is record
clk   : std_logic;
trig0 : std_logic_vector(63 downto 0);
data  : std_logic_vector(180 downto 0);
end record;

type TSH_dbgcs is record
spd   : TSH_ila;
layer : TSH_ila;
end record;

type TSH_dbgcs_GTCH is array (0 to C_SH_GTCH_COUNT_MAX-1) of TSH_dbgcs;
type TSH_dbgcs_GTCH_SHCountMax is array (0 to C_SH_COUNT_MAX(C_HDD_COUNT_MAX-1)-1) of TSH_dbgcs_GTCH;

type TSH_dbgcs_SHCountMax is array (0 to C_HDD_COUNT_MAX-1) of TSH_dbgcs;

type TSH_dbgcs_exp is record
sh    : TSH_dbgcs_SHCountMax;
raid  : TSH_ila;
measure : TSH_ila;
end record;


---------------------------------------------------------
--Прототипы функций
---------------------------------------------------------


end sata_glob_pkg;


package body sata_glob_pkg is

---------------------------------------------------------
--Функции
---------------------------------------------------------


end sata_glob_pkg;


