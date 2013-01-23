-------------------------------------------------------------------------
-- Company     : Linkos
-- Engineer    : Golovachenko Victor
--
-- Create Date : 16.01.2013 13:02:51
-- Module Name : prj_cfg
--
-- Description : Конфигурирование модуля HDD для проекта HSCAM
--
-- Revision:
-- Revision 0.01 - File Created
--
-------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;

package prj_cfg is

--//Версия реализации
constant C_PCFG_HSCAM_PCIE_VERSION     : integer:=16#002#; --Версия прошивки

--//Тип используемой платы
constant C_PCFG_BOARD                  : string:="HSCAM";

--//Конфигурирование модулей:
--//cfg Memory Controller
constant C_PCFG_MEMCTRL_BANK_COUNT     : integer:=1; --//max 1
constant C_PCFG_MEMCTRL_BANK_SIZE      : integer:=5; --//max 7: 0-8MB, 1-16MB, 2-32MB, 3-64MB, 4-128MB, ...

--//cfg PCI-Express
constant C_PCGF_PCIE_RST_SEL           : integer:=1;--0/1 - Использовать сброс сгенеренный в проекте/с стота PCI-Express
constant C_PCGF_PCIE_LINK_WIDTH        : integer:=1;--При изменении кол-ва линий необходимо перегенерить ядро PCI-Express

--//cfg VCTRL
constant C_PCFG_VCTRL_DBGCS            : string:="ON";
constant C_PCFG_VCTRL_VCH_COUNT        : integer:=1; --//max 6

--//cfg ETH
constant C_PCFG_ETH_USE                : string:="ON";

--//Bitmap порта p_in_cam_ctrl
constant C_CAM_CTRL_MODE_FPS_L_BIT     : integer:=0; --Управление входным потоком видео данных
constant C_CAM_CTRL_MODE_FPS_M_BIT     : integer:=1;
constant C_CAM_CTRL_TST_PATTERN_BIT    : integer:=7; --Тестовый кадр
constant C_CAM_CTRL_HDD_VDOUT_BIT      : integer:=9; --1/0 - вывод данных от модуля hdd_main.vhd/camera.v
constant C_CAM_CTRL_HDD_LEDOFF_BIT     : integer:=11;--Вкл/Выкл светодиодов HDD
constant C_CAM_CTRL_HDD_RST_BIT        : integer:=12;--Сброс модуля hdd_main.vhd
constant C_CAM_CTRL_HDD_MODE_L_BIT     : integer:=13;--Команды модуля hdd_main.vhd
constant C_CAM_CTRL_HDD_MODE_M_BIT     : integer:=15;

--Коды управления входным потоком видео данных
constant C_CAM_CTRL_60FPS              : integer:=0;
constant C_CAM_CTRL_120FPS             : integer:=1;
constant C_CAM_CTRL_240FPS             : integer:=2;
constant C_CAM_CTRL_480FPS             : integer:=3;

--Коды команд модуля hdd_main.vhd
constant C_CAM_CTRL_HDD_WR             : integer:=1;
constant C_CAM_CTRL_HDD_RD             : integer:=2;
constant C_CAM_CTRL_HDD_STOP           : integer:=3;
constant C_CAM_CTRL_HDD_TEST           : integer:=4;
constant C_CAM_CTRL_VCH_OFF            : integer:=5;
constant C_CAM_CTRL_VCH_ON             : integer:=6;
constant C_CAM_CTRL_CFGFTDI            : integer:=7;

constant C_PCFG_VBUF_IWIDTH : integer := 80;
constant C_PCFG_VBUF_OWIDTH : integer := 32;


end prj_cfg;
