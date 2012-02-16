-------------------------------------------------------------------------
-- Company     : Linkos
-- Engineer    : Golovachenko Victor
--
-- Create Date : 13.10.2011 15:15:44
-- Module Name : prj_cfg
--
-- Description : Конфигурирование проекта HSCAM (ОТЛАДКА НА РАБОЧЕЙ ПЛАТЕ!!!!!)
--
-- Revision:
-- Revision 0.01 - File Created
--
-------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;

package prj_cfg is

--//Тип используемой платы
constant C_PCFG_BOARD                  : string:="HSCAM";

constant C_PCFG_FRPIX                  : integer:=110;--1280;
constant C_PCFG_FRROW                  : integer:=8;--1024;
constant C_PCFG_FR_PIXTOTAL            : integer:=32;

--//Конфигурирование модулей:
--//cfg Memory Controller
constant C_PCFG_MEMCTRL_BANK_COUNT     : integer:=2; --//max 1

--//cfg HDD
constant C_PCFG_HDD_USE                : string:="ON";
constant C_PCFG_HDD_DBG                : string:="OFF";
constant C_PCFG_HDD_DBGCS              : string:="ON";
constant C_PCFG_HDD_COUNT              : integer:=4;
constant C_PCFG_HDD_RAMBUF_SIZE        : integer:=28;--256MB : Определяется как 2 в степени G_HDD_RAMBUF_SIZE
constant C_PCFG_HDD_GT_DBUS            : integer:=32;--Настройка шины данных GT (RocketIO)
constant C_PCFG_HDD_FPGA_TYPE          : integer:=3; --0/1/2/3 - "V5_GTP"/"V5_GTX"/"V6_GTX"/"S6_GTPA"
constant C_PCFG_HDD_SH_MAIN_NUM        : integer:=0; --определяем индекс GT модуля от которого будем брать частоту для тактирования sata_dcm.vhd
constant C_PCFG_HDD_SATA_GEN_DEFAULT   : integer:=1; --0/1 - SATAI/II
constant C_PCFG_HDD_RAID_DWIDTH        : integer:=128;

end prj_cfg;
