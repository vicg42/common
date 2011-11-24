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
use ieee.STD_LOGIC_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_arith.all;

package prj_cfg is

--//Тип используемой платы
constant C_PCFG_BOARD                  : string:="HSCAM";
constant G_IF                          : string:="FTDI";--//Тип интерфейса управления HDD
--//Конфигурирование модулей:
--//cfg Memory Controller
constant C_PCFG_MEMCTRL_BANK_COUNT     : integer:=1; --//max 1

--//cfg HDD
constant C_PCFG_HDD_USE                : string:="ON";
constant C_PCFG_HDD_DBG                : string:="OFF";
constant C_PCFG_HDD_DBGCS              : string:="ON";
constant C_PCFG_HDD_COUNT              : integer:=1;
constant C_PCFG_HDD_RAMBUF_SIZE        : integer:=25;--//32MB : Определяется как 2 в степени G_HDD_RAMBUF_SIZE
constant C_PCFG_HDD_GT_DBUS            : integer:=16;--//Настройка шины данных GT (RocketIO)


end prj_cfg;

