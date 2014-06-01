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
use work.vicg_common_pkg.all;

package prj_cfg is

--Тип используемой платы
constant C_PCFG_BOARD                  : string:="HSCAM_PCIE";

--Конфигурирование модулей:
--cfg Memory Controller
constant C_PCFG_MEMCTRL_BANK_COUNT     : integer:=1; --max 1
constant C_PCFG_MEMCTRL_BANK_SIZE      : integer:=7; --max 7: 0-8MB, 1-16MB, 2-32MB, 3-64MB, 4-128MB, ...
constant C_PCFG_MEMARB_CH_COUNT        : integer:=4; --HOST + VCTRL_WR + VCTRL_RD

--cfg PCI-Express
constant C_PCGF_PCIE_RST_SEL           : integer:=1;--0/1 - Использовать сброс сгенеренный в проекте/с стота PCI-Express
constant C_PCGF_PCIE_LINK_WIDTH        : integer:=8;--При изменении кол-ва линий необходимо перегенерить ядро PCI-Express
constant C_PCGF_PCIE_DWIDTH            : integer:=128;

--cfg VCTRL
constant C_PCFG_VCTRL_USR_OPT          : std_logic_vector(7 downto 0):="0000"&"0000";
constant C_PCFG_VCTRL_DBG              : string:="ON";
constant C_PCFG_VCTRL_VBUFI_OWIDTH     : integer:=C_PCGF_PCIE_DWIDTH;
--Memory map for video: (max frame size: 8192x8192)
--                                                   --Пиксели видеокадра(VLINE_LSB-1...0)
constant C_PCFG_VCTRL_MEM_VLINE_L_BIT  : integer:=13;--Строки видеокадра (MSB...LSB)
constant C_PCFG_VCTRL_MEM_VLINE_M_BIT  : integer:=25;
constant C_PCFG_VCTRL_MEM_VFR_L_BIT    : integer:=26;--Номер кадра (MSB...LSB) - Видеобуфера
constant C_PCFG_VCTRL_MEM_VFR_M_BIT    : integer:=28;
constant C_PCFG_VCTRL_MEM_VCH_L_BIT    : integer:=29;--Номер видео канала (MSB...LSB)
constant C_PCFG_VCTRL_MEM_VCH_M_BIT    : integer:=30;

constant C_PCFG_VCTRL_VCH_COUNT        : integer:=1; --max 6

--cfg ETH
constant C_PCFG_ETH_USE                : string:="ON";

--#######
--Bitmap порта p_in_cam_ctrl
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

constant C_PCFG_CCD_DWIDTH             : integer:=80;

constant C_PCFG_VOUT_DWIDTH            : integer:=16;--Шина данных для модуля Толи Кукла

end prj_cfg;
