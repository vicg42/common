------------------------------------------------------------------------
-- Company     : Linkos
-- Engineer    : Golovachenko Victor
--
-- Create Date : 01.04.2011 12:39:49
-- Module Name : sata_raid_pkg
--
-- Description : Константы/Типы данных/
--               используемые в sata_raid
--
-- Revision:
-- Revision 0.01 - File Created
--
-------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_arith.all;

use work.vicg_common_pkg.all;
use work.sata_pkg.all;

package sata_raid_pkg is


--//
type TUsrSErrorSHCountMax is array (0 to C_HDD_COUNT_MAX-1) of std_logic_vector(C_ALSERR_LAST_BIT downto 0);

type TUsrStatus is record
glob_hdd_count : std_logic_vector(3 downto 0);
glob_busy: std_logic;
glob_drdy: std_logic;
glob_err : std_logic;
ch_busy  : std_logic_vector(C_HDD_COUNT_MAX-1 downto 0);
ch_drdy  : std_logic_vector(C_HDD_COUNT_MAX-1 downto 0);
ch_err   : std_logic_vector(C_HDD_COUNT_MAX-1 downto 0);
SError   : TUsrSErrorSHCountMax;
glob_usr : std_logic_vector(31 downto 0);
ch_usr   : TBus32_SHCountMax;
end record;

type TRaid is record
used     : std_logic;
hddcount : std_logic_vector(2 downto 0);
end record;




end sata_raid_pkg;


package body sata_raid_pkg is

---------------------------------------------------------
--Функции
---------------------------------------------------------


end sata_raid_pkg;


