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

--//Конфигурирование модулей:
--//cfg Memory Controller
constant C_PCFG_MEMCTRL_BANK_COUNT     : integer:=1; --//max 1
constant C_PCFG_MEMCTRL_BANK_SIZE      : integer:=5; --//max 7: 0-8MB, 1-16MB, 2-32MB, ... 6-256MB, 7-512MB

--//cfg TMR
--constant C_PCFG_TMR_CLK_PERIOD         : integer:=0; --//0-100MHz

--//cfg HDD
constant C_PCFG_HDD_USE                : string:="ON";
constant C_PCFG_HDD_DBG                : string:="OFF";
constant C_PCFG_HDD_DBGCS              : string:="OFF";
constant C_PCFG_HDD_IFCTRL             : string:="FTDI";--Тип интерфейса управления HDD "FTDI"/"UART"
constant C_PCFG_HDD_COUNT              : integer:=1;
constant C_PCFG_HDD_RAMBUF_SIZE        : integer:=25;--32MB : Определяется как 2 в степени G_HDD_RAMBUF_SIZE
constant C_PCFG_HDD_GT_DBUS            : integer:=16;--Настройка шины данных GT (RocketIO)
constant C_PCFG_HDD_FPGA_TYPE          : integer:=3; --0/1/2/3 - "V5_GTP"/"V5_GTX"/"V6_GTX"/"S6_GTPA"
constant C_PCFG_HDD_SH_MAIN_NUM        : integer:=0; --определяем индекс GT модуля от которого будем брать частоту для тактирования sata_dcm.vhd

--//cfg VCTRL
constant C_PCFG_VCTRL_VCH_COUNT        : integer:=4; --//max 4
constant C_PCFG_VCTRL_SIMPLE           : string:="ON";

end prj_cfg;

