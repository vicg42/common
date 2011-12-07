-------------------------------------------------------------------------
-- Company     : Linkos
-- Engineer    : Golovachenko Victor
--
-- Create Date : 27.01.2011 16:46:55
-- Module Name : prj_cfg
--
-- Description : Конфигурирование проекта Veresk_M (ОТЛАДКА НА ПЛАТЕ ML505!!!!!)
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
constant C_PCFG_BOARD                  : string:="ML505";

--//Конфигурирование модулей:
--//cfg Memory Controller
constant C_PCFG_MEMCTRL_BANK_COUNT     : integer:=1; --//max 1
constant C_PCFG_MEMCTRL_BANK_SIZE      : integer:=5; --//max 7: 0-8MB, 1-16MB, 2-32MB, ... 6-256MB, 7-512MB

--//cfg TMR
--constant C_PCFG_TMR_CLK_PERIOD         : integer:=0; --//0-100MHz

--//cfg HDD
constant C_PCFG_HDD_USE                : string:="OFF";
--constant C_PCFG_HDD_DBG                : string:="OFF";
--constant C_PCFG_HDD_DBGCS              : string:="ON";
--constant C_PCFG_HDD_COUNT              : integer:=1;
--constant C_PCFG_HDD_RAMBUF_SIZE        : integer:=25;--//32MB : Определяется как 2 в степени G_HDD_RAMBUF_SIZE
--constant C_PCFG_HDD_GT_DBUS            : integer:=16;--//Настройка шины данных GT (RocketIO)

--//cfg PCI-Express
constant C_PCGF_PCIE_RST_SEL           : integer:=1;--0/1 - Использовать сброс сгенеренный в проекте/с стота PCI-Express
constant C_PCGF_PCIE_LINK_WIDTH        : integer:=1;--При изменении кол-ва линий необходимо перегенерить ядро PCI-Express

--//cfg VCTRL
constant C_PCFG_VCTRL_VCH_COUNT        : integer:=3; --//max 4
constant C_PCFG_VCTRL_SIMPLE           : string:="ON";

--//cfg ETH
constant C_PCFG_ETH_USE                : string:="ON";
constant C_PCFG_ETH_DBG                : string:="OFF";
constant C_PCFG_ETH_GTCH_COUNT_MAX     : integer:=2; --Кол-во каналов в одном GT(RocketIO) модуле

--//cfg TRACKER
constant C_PCFG_TRC_USE                : string:="OFF";

--//cfg clkfx - DCM LocalBus
constant C_PCFG_LBUSDCM_CLKFX_M        : integer:=2;

end prj_cfg;

