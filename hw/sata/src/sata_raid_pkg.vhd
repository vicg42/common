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

library work;
use work.vicg_common_pkg.all;
use work.sata_pkg.all;

package sata_raid_pkg is


--//
type TUsrSErrorSHCountMax is array (0 to C_HDD_COUNT_MAX-1) of std_logic_vector(C_ALSERR_LAST_BIT downto 0);

type TRaid is record
used     : std_logic;
hddcount : std_logic_vector(2 downto 0);
end record;

type TDMAcfg is record
start    : std_logic;
sw_mode  : std_logic;
hw_mode  : std_logic;
tst_mode : std_logic;
wr_start : std_logic;
error    : std_logic;
raid     : TRaid;
scount   : std_logic_vector(15 downto 0);
end record;

type TUsrStatus is record
dmacfg   : TDMAcfg;
hdd_count: std_logic_vector(3 downto 0);
dev_rdy  : std_logic;
dev_busy : std_logic;
dev_err  : std_logic;
ch_busy  : std_logic_vector(C_HDD_COUNT_MAX-1 downto 0);
ch_drdy  : std_logic_vector(C_HDD_COUNT_MAX-1 downto 0);
ch_err   : std_logic_vector(C_HDD_COUNT_MAX-1 downto 0);
SError   : TUsrSErrorSHCountMax;
usr      : std_logic_vector(31 downto 0);
ch_usr   : TBus32_SHCountMax;
lba_bp   : std_logic_vector(47 downto 0);
end record;


--//-------------------------------------------------
--//RAMBUF
--//-------------------------------------------------
--//Статусы/Map:
type THDDRBufStatus is record
rdy  : std_logic;
err  : std_logic;
done : std_logic;
end record;

type THDDRBufCfg is record
mem_trn : std_logic_vector(15 downto 0);
mem_adr : std_logic_vector(31 downto 0);
dmacfg  : TDMAcfg;
bufrst  : std_logic;
end record;
end sata_raid_pkg;


package body sata_raid_pkg is

---------------------------------------------------------
--Функции
---------------------------------------------------------


end sata_raid_pkg;


