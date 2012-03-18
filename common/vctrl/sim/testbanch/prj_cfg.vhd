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
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

package prj_cfg is

--//Тип используемой платы
constant C_PCFG_BOARD                  : string:="ML505";

--//Конфигурирование модулей:
--//cfg Memory Controller
constant C_PCFG_MEMCTRL_BANK_COUNT     : integer:=1; --//max 1
constant C_PCFG_MEMCTRL_BANK_SIZE      : integer:=4; --//max 7: 0-8MB, 1-16MB, 2-32MB, 3-64MB, 4-128MB, ...

--//cfg TMR
--constant C_PCFG_TMR_CLK_PERIOD         : integer:=0; --//0-100MHz

--//cfg HDD
constant C_PCFG_HDD_USE                : string:="OFF";
constant C_PCFG_HDD_DBG                : string:="OFF";
constant C_PCFG_HDD_DBGCS              : string:="ON";
constant C_PCFG_HDD_COUNT              : integer:=1;
constant C_PCFG_HDD_RAMBUF_SIZE        : integer:=25;--//32MB : Определяется как 2 в степени G_HDD_RAMBUF_SIZE
constant C_PCFG_HDD_GT_DBUS            : integer:=16;--//Настройка шины данных GT (RocketIO)
constant C_PCFG_HDD_FPGA_TYPE          : integer:=0; --0/1/2/3 - "V5_GTP"/"V5_GTX"/"V6_GTX"/"S6_GTPA"
constant C_PCFG_HDD_SH_MAIN_NUM        : integer:=0; --определяем индекс GT модуля от которого будем брать частоту для тактирования sata_dcm.vhd

--//cfg PCI-Express
constant C_PCGF_PCIE_RST_SEL           : integer:=1;--0/1 - Использовать сброс сгенеренный в проекте/с стота PCI-Express
constant C_PCGF_PCIE_LINK_WIDTH        : integer:=1;--При изменении кол-ва линий необходимо перегенерить ядро PCI-Express

--//cfg VCTRL
constant C_PCFG_VCTRL_VCH_COUNT        : integer:=6; --//max 6
constant C_PCFG_VCTRL_SIMPLE           : string:="ON";

--//cfg ETH
constant C_PCFG_ETH_USE                : string:="ON";
constant C_PCFG_ETH_DBG                : string:="OFF";
constant C_PCFG_ETH_GTCH_COUNT_MAX     : integer:=2;
constant C_PCFG_ETH_PHY_DWIDTH         : integer:=8;
constant C_PCFG_ETH_PHY_SEL            : integer:=0; --0/1/2/3 - Fiber/RGMII/SGMII/GMII - Константы для интерфейсов см. eth_pkg.vhd


--//cfg TRACKER
constant C_PCFG_TRC_USE                : string:="OFF";

--//cfg clkfx - DCM LocalBus
constant C_PCFG_LBUSDCM_CLKFX_M        : integer:=2;

end prj_cfg;

