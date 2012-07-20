-------------------------------------------------------------------------
-- Company     : Linkos
-- Engineer    : Golovachenko Victor
--
-- Create Date : 13.10.2011 15:15:44
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
constant C_PCFG_HSCAM_HDD_VERSION      : integer:=16#0A#; --Версия модуля hdd_main.vhd

--//Тип используемой платы
constant C_PCFG_BOARD                  : string:="HSCAM";

--//Конфигурирование модулей:
constant C_PCFG_VINBUF_ONE             : string:="ON";--ON/OFF - (один вх. буфер для VCTRL и HDD (запись без одновременной выдачи видео в PC)) /
                                                       --         (VCTRL и HDD имеют отдельные вх. буфера (запись с одновременной выдачей видео в PC)

--//
constant C_PCFG_VSYN_ACTIVE            : std_logic:='0';--Активный уровень для КСИ,ССИ вх/вых видео
constant C_PCFG_VOUT_DWIDTH            : integer:=16;--Шина данных для вых. видео потока
constant C_PCFG_VIN_DWIDTH             : integer:=80;--Шина данных для вх. видео потока

--//cfg CFG
constant C_PCFG_CFG_DBGCS              : string:="OFF";
constant C_PCFG_CFG                    : string:="FTDI";--"HOST"/"FTDI"/"ALL"
                                                       --"HOST" - работа с модулем dsn_hdd.vhd через порты p_in_usr_txd/rxd модуля hdd_main.vhd
                                                       --"FTDI" - работа с модулем dsn_hdd.vhd через порт p_inout_ftdi_d модуля hdd_main.vhd
                                                       --"ALL"  - работа с модулем dsn_hdd.vhd через оба порта "HOST" или "FTDI"

constant C_PCFG_DEFAULT                : std_logic:='0';--0/1 - FTDI/HOST (действительно только при C_PCFG_CFG="ALL")

--//cfg VCTRL
constant C_PCFG_VCTRL_USE              : string:="ON";
constant C_PCFG_FRPIX                  : integer:=1280;
constant C_PCFG_FRROW                  : integer:=1024;

--//cfg Memory Controller
constant C_PCFG_MEMOPT                 : string:="OFF";--ON - только если используется mem_mux_v3.vhd
constant C_PCFG_MEMCTRL_BANK_COUNT     : integer:=2;--max 2
constant C_PCFG_MEMBANK_1              : integer:=1;
constant C_PCFG_MEMBANK_0              : integer:=0;
constant C_PCFG_MEMPHY_SET             : integer:=0;--0 - (MEMBANK0<->MCB5; MEMBANK1<->MCB1)
                                                    --1 - (MEMBANK0<->MCB1; MEMBANK1<->MCB5)

--//cfg HDD
constant C_PCFG_HDD_USE                : string:="ON";
constant C_PCFG_HDD_DBG                : string:="OFF";
constant C_PCFG_HDD_DBGCS              : string:="ON";
constant C_PCFG_HDD_SH_DBGCS           : string:="OFF";
constant C_PCFG_HDD_RAID_DBGCS         : string:="ON";
constant C_PCFG_HDD_COUNT              : integer:=4;
constant C_PCFG_HDD_RAMBUF_SIZE        : integer:=27;--128MB : Определяется как 2 в степени G_HDD_RAMBUF_SIZE
constant C_PCFG_HDD_GT_DBUS            : integer:=32;--Настройка шины данных GT (RocketIO)
constant C_PCFG_HDD_FPGA_TYPE          : integer:=3; --0/1/2/3 - "V5_GTP"/"V5_GTX"/"V6_GTX"/"S6_GTPA"
constant C_PCFG_HDD_SH_MAIN_NUM        : integer:=0; --определяем индекс GT модуля от которого будем брать частоту для тактирования sata_dcm.vhd
constant C_PCFG_HDD_SATA_GEN_DEFAULT   : integer:=0; --0/1 - SATAI/II
constant C_PCFG_HDD_RAID_DWIDTH        : integer:=128;


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

end prj_cfg;
