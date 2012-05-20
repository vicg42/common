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
use ieee.numeric_std.all;
use ieee.std_logic_arith.all;

package prj_cfg is

--//Версия реализации
constant C_PCFG_HSCAM_HDD_VERSION      : integer:=16#05#; --Верисия модуля контроллера HDD для проекта HSCAM

--//Тип используемой платы
constant C_PCFG_BOARD                  : string:="HSCAM";

--//Конфигурирование модулей:
constant C_VIN_HDD_EXTSYN              : string:="OFF";
constant C_PCFG_VINBUF_ONE             : string:="ON";--ON/OFF - один вх видеобуфер для VCTRL и HDD/ для VCTRL и HDD отдельные вх. видео буфера

--//cfg CFG
constant C_PCFG_CFG_DBGCS              : string:="OFF";

--//cfg VCTRL
constant C_PCFG_VCTRL_USE              : string:="ON";
constant C_PCFG_VCTRL_DBGCS            : string:="OFF";
constant C_PCFG_VCTRL_MEMWR_TRN_LEN    : integer:=16#40#;
constant C_PCFG_VCTRL_MEMRD_TRN_LEN    : integer:=16#40#;
constant C_PCFG_FRPIX                  : integer:=1280;--1280;--
constant C_PCFG_FRROW                  : integer:=4;--1024;--

--//cfg Memory Controller
constant C_PCFG_MEMOPT                 : string:="OFF";--//ON - только если используется mem_mux_v3.vhd
constant C_PCFG_MEMCTRL_BANK_COUNT     : integer:=2; --//max 2
constant C_PCFG_MEMBANK_1              : integer:=1;
constant C_PCFG_MEMBANK_0              : integer:=0;
constant C_PCFG_MEMPHY_SET             : integer:=0;--0 - (MEMBANK0<->MCB5; MEMBANK1<->MCB1)
                                                    --1 - (MEMBANK0<->MCB1; MEMBANK1<->MCB5)

--//cfg HDD
constant C_PCFG_HDD_USE                : string:="ON";
constant C_PCFG_HDD_DBG                : string:="ON";
constant C_PCFG_HDD_DBGCS              : string:="OFF";
constant C_PCFG_HDD_SH_DBGCS           : string:="OFF";
constant C_PCFG_HDD_RAID_DBGCS         : string:="OFF";
constant C_PCFG_HDD_COUNT              : integer:=2;
constant C_PCFG_HDD_RAMBUF_SIZE        : integer:=11;--28;-- : Определяется как 2 в степени G_HDD_RAMBUF_SIZE
constant C_PCFG_HDD_GT_DBUS            : integer:=32;--Настройка шины данных GT (RocketIO)
constant C_PCFG_HDD_FPGA_TYPE          : integer:=3; --0/1/2/3 - "V5_GTP"/"V5_GTX"/"V6_GTX"/"S6_GTPA"
constant C_PCFG_HDD_SH_MAIN_NUM        : integer:=0; --определяем индекс GT модуля от которого будем брать частоту для тактирования sata_dcm.vhd
constant C_PCFG_HDD_SATA_GEN_DEFAULT   : integer:=1; --0/1 - SATAI/II
constant C_PCFG_HDD_RAID_DWIDTH        : integer:=64;

constant C_CFGDEV_HDD             : integer:=16#05#;
constant C_CFGDEV_COUNT           : integer:=7;

end prj_cfg;

