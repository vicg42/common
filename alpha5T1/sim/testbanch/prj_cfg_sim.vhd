-------------------------------------------------------------------------
-- Company     : Telemix
-- Engineer    : Golovachenko Victor
--
-- Create Date : 27.01.2011 16:46:59
-- Module Name : prj_cfg
--
-- Description : Конфигурирование проекта Veresk_M (ДЛЯ МОДЕЛИРОВАНИЯ !!!!)
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
constant C_BOARD_USE                         : string:="ALPHA_DATA";

--//Управление использованием модулей проекта:
constant C_USE_TRACK                         : string:="ON";
constant C_USE_ETH                           : string:="ON";
constant C_USE_HDD                           : string:="ON";

constant C_DBG_HDD                           : string:="ON";
constant G_DBG_ETH                           : string:="ON";

constant G_DBGCS_HDD                         : string:="OFF";

--//Конфигурирование модулей:
--//cfg Memory Controller
constant C_MEMCTRL_BANK_COUNT                : integer:=1; --//max 3

--//cfg HDD
constant C_HDD_COUNT                         : integer:=2;
constant C_HDD_RAMBUF_SIZE                   : integer:=25;--//32MB : Определяется как 2 в степени G_HDD_RAMBUF_SIZE
constant C_HDD_GT_DBUS                       : integer:=16;--//Настройка шины данных GT (RocketIO)

--//cfg PCI-Express
constant C_PCIEXPRESS_RST_FROM_SLOT          : integer:=0;--0/1 - Использовать сброс сгенеренный в проекта/с стота PCI-Express
constant C_PCIEXPRESS_LINK_WIDTH             : integer:=1;--При изменении кол-ва линий
                                                          --Необходимо перегенерить ядро PCI-Express, для чего вызвать проект core_gen
                                                          --..board_xxx\src\pci_express\core_gen\pci_express.cgp


--//cfg VCTRL
constant C_DSN_VCTRL_VCH_COUNT               : integer:=3;
constant C_DSN_VCTRL_SIMPLE                  : string:="OFF";

--//cfg clkfx - DCM LocalBus
constant C_LBUSDCM_CLKFX_M                   : integer:=4;

end prj_cfg;


package body prj_cfg is

end prj_cfg;

