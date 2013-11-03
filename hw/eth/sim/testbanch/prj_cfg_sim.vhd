-------------------------------------------------------------------------
-- Company     : Linkos
-- Engineer    : Golovachenko Victor
--
-- Create Date : 27.01.2011 16:46:48
-- Module Name : prj_cfg
--
-- Description : Конфигурирование проекта VERESK
--
-- Revision:
-- Revision 0.01 - File Created
--
-------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;

package prj_cfg is

--//Тип используемой платы
constant C_PCFG_BOARD                  : string:="ML505";

----//Конфигурирование модулей:
----//cfg Memory Controller
--constant C_PCFG_MEMCTRL_BANK_COUNT     : integer:=1; --//max 1
--constant C_PCFG_MEMCTRL_BANK_SIZE      : integer:=4; --//max 7: 0-8MB, 1-16MB, 2-32MB, 3-64MB, 4-128MB, ...
--
----//cfg PCI-Express
--constant C_PCGF_PCIE_RST_SEL           : integer:=1;--0/1 - Использовать сброс сгенеренный в проекте/с стота PCI-Express
--constant C_PCGF_PCIE_LINK_WIDTH        : integer:=1;--При изменении кол-ва линий необходимо перегенерить ядро PCI-Express
--
----//cfg VCTRL
--constant C_PCFG_VCTRL_VCH_COUNT        : integer:=1; --//max 6

constant C_PCFG_ETH_GTCH_COUNT_MAX     : integer:=1;
--cfg ETH
constant C_PCFG_ETH_USE                : string:="ON";
constant C_PCFG_ETH_DBG                : string:="OFF";
constant C_PCFG_ETH_COUNT              : integer:=1;--Кол-во каналов
constant C_PCFG_ETH_PHY_SEL            : integer:=0;--0/3 - FIBER/COPPER_GMII
constant C_PCFG_ETH_USR_DWIDTH         : integer:=64;
constant C_PCFG_ETH_PHY_DWIDTH         : integer:=64;
constant C_PCFG_ETH_MAC_LEN_SWAP       : integer:=1; --1/0 Поле Length/Type первый мл./ст. байт (0 - по стандарту!!! 1 - как в проекте Вереск)

end prj_cfg;

