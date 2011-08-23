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
use work.sata_glob_pkg.all;
use work.sata_pkg.all;

package sata_raid_pkg is

type TRaid is record
used     : std_logic;
hddcount : std_logic_vector(2 downto 0);
end record;

type THDDTstGen is record
con2rambuf : std_logic;
tesing_on  : std_logic;
tesing_spd : std_logic_vector(7 downto 0);
end record;

type TDMAcfg is record
sw_mode  : std_logic;--//Режим работы
hw_mode  : std_logic;
armed    : std_logic;--//Взводим модуль RAMBUF (готовность к работе)
atacmdnew: std_logic;
atacmdw  : std_logic;--//Пуск операции FPGA->HDD
atadone  : std_logic;
error    : std_logic;
clr_err  : std_logic;
raid     : TRaid;
scount   : std_logic_vector(15 downto 0);
--tstgen   : THDDTstGen;
end record;

type TUsrStatus is record
dmacfg       : TDMAcfg;
hdd_count    : std_logic_vector(3 downto 0);
dev_rdy      : std_logic;
dev_bsy      : std_logic;
dev_err      : std_logic;
dev_ipf      : std_logic;
ch_bsy       : std_logic_vector(C_HDD_COUNT_MAX-1 downto 0);
ch_rdy       : std_logic_vector(C_HDD_COUNT_MAX-1 downto 0);
ch_err       : std_logic_vector(C_HDD_COUNT_MAX-1 downto 0);
ch_ipf       : std_logic_vector(C_HDD_COUNT_MAX-1 downto 0);
ch_ataerror  : TATAError_SHCountMax;
ch_atastatus : TATAStatus_SHCountMax;
ch_serror    : TSError_SHCountMax;
ch_sstatus   : TSStatus_SHCountMax;
ch_usr       : TBus32_SHCountMax;
usr          : std_logic_vector(31 downto 0);
lba_bp       : std_logic_vector(47 downto 0);--//Break Point
end record;


component sata_testgen
port(
p_in_rbuf_cfg  : in   TDMAcfg;
p_in_buffull   : in   std_logic;

p_out_rdy      : out  std_logic;
p_out_err      : out  std_logic;

p_out_tdata    : out  std_logic_vector(31 downto 0);
p_out_tdata_en : out  std_logic;

p_in_clk       : in   std_logic;
p_in_rst       : in   std_logic
);
end component;


end sata_raid_pkg;


package body sata_raid_pkg is

---------------------------------------------------------
--Функции
---------------------------------------------------------


end sata_raid_pkg;


