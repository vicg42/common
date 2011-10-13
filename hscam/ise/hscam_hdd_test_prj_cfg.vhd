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
constant C_BOARD_USE                         : string:="ML505";
constant G_IF                                : string:="FTDI";--//Тип интерфейса управления HDD

--//Управление использованием модулей проекта:
constant C_USE_HDD                           : string:="ON";

constant C_DBG_HDD                           : string:="OFF";
constant C_DBGCS_HDD                         : string:="ON";

--//cfg HDD
constant C_HDD_COUNT                         : integer:=2;
constant C_HDD_RAMBUF_SIZE                   : integer:=25;--//32MB : Определяется как 2 в степени G_HDD_RAMBUF_SIZE
constant C_HDD_GT_DBUS                       : integer:=16;--//Настройка шины данных GT (RocketIO)


end prj_cfg;


package body prj_cfg is

end prj_cfg;

