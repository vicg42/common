-------------------------------------------------------------------------
-- Company     : Linkos
-- Engineer    : Golovachenko Victor
--
-- Create Date : 10/26/2007
-- Module Name : prj_def
--
-- Description :
--
-- Revision:
-- Revision 0.01 - File Created
--
-------------------------------------------------------------------------
library ieee;
use ieee.STD_LOGIC_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_arith.all;

library work;
use work.vicg_common_pkg.all;
use work.prj_cfg.all;

package prj_def is

--Версия прошивки FPGA
constant C_FPGA_FIRMWARE_VERSION : integer:=16#0003#;--Распологается в C_CFGDEV_TESTING/рег. 0x00

--//VCTRL
constant C_VIDEO_PKT_HEADER_SIZE : integer:=5;--DWORD

--//HOST
constant C_HDEV_DWIDTH           : integer:=32;--шина портов


--//--------------------------------------------------------------
--//Модуль конфигурирования (cfgdev.vhd)
--//--------------------------------------------------------------
--//Адреса устройств доступных через модуль cfgdev.vhd
--//Device Address map:
constant C_CFGDEV_SWT                         : integer:=16#00#;
constant C_CFGDEV_ETH                         : integer:=16#01#;
constant C_CFGDEV_VCTRL                       : integer:=16#02#;
constant C_CFGDEV_TMR                         : integer:=16#03#;
--constant RESERV                               : integer:=16#04#;
constant C_CFGDEV_HDD                         : integer:=16#05#;
constant C_CFGDEV_TESTING                     : integer:=16#06#;
constant C_CFGDEV_COUNT                       : integer:=C_CFGDEV_TESTING + 1;
constant C_CFGDEV_COUNT_MAX                   : integer:=256;--Определяется константами C_CFGPKT_DADR_M/L_BIT в cfgdev_pkg.vhd


--//--------------------------------------------------------------
--//Регистры модуля dsn_eth.vhd
--//--------------------------------------------------------------
constant C_ETH_REG_CTRL                       : integer:=16#000#;
constant C_ETH_REG_MAC_PATRN0                 : integer:=16#001#;--DST MAC
constant C_ETH_REG_MAC_PATRN1                 : integer:=16#002#;
constant C_ETH_REG_MAC_PATRN2                 : integer:=16#003#;
constant C_ETH_REG_MAC_PATRN3                 : integer:=16#004#;--SRC MAC
constant C_ETH_REG_MAC_PATRN4                 : integer:=16#005#;
constant C_ETH_REG_MAC_PATRN5                 : integer:=16#006#;
constant C_ETH_REG_IP_PATRN0                  : integer:=16#007#;--DST IP
constant C_ETH_REG_IP_PATRN1                  : integer:=16#008#;
constant C_ETH_REG_IP_PATRN2                  : integer:=16#009#;--SRC IP
constant C_ETH_REG_IP_PATRN3                  : integer:=16#00A#;
constant C_ETH_REG_PORT_PATRN0                : integer:=16#00B#;--DST PORT
constant C_ETH_REG_PORT_PATRN1                : integer:=16#00C#;--SRC PORT


--//--------------------------------------------------------------
--//Регистры модуля dsn_video_ctrl.vhd
--//--------------------------------------------------------------
constant C_VCTRL_REG_CTRL                     : integer:=16#000#;
constant C_VCTRL_REG_DATA_L                   : integer:=16#001#;
constant C_VCTRL_REG_DATA_M                   : integer:=16#002#;
constant C_VCTRL_REG_MEM_CTRL                 : integer:=16#003#;--(15..8)(7..0) - trn_mem_rd;trn_mem_wr
constant C_VCTRL_REG_TST0                     : integer:=16#004#;


--//Register C_VCTRL_REG_CTRL / Bit Map:
constant C_VCTRL_REG_CTRL_VCH_L_BIT           : integer:=0; --Номер видео канала
constant C_VCTRL_REG_CTRL_VCH_M_BIT           : integer:=3;
constant C_VCTRL_REG_CTRL_PRM_L_BIT           : integer:=4; --Номер парамера
constant C_VCTRL_REG_CTRL_PRM_M_BIT           : integer:=6;
constant C_VCTRL_REG_CTRL_SET_BIT             : integer:=7;
constant C_VCTRL_REG_CTRL_SET_IDLE_BIT        : integer:=8;
constant C_VCTRL_REG_CTRL_RAMCOE_ADR_BIT      : integer:=9;
constant C_VCTRL_REG_CTRL_RAMCOE_DATA_BIT     : integer:=10;
constant C_VCTRL_REG_CTRL_RAMCOE_L_BIT        : integer:=11;--Номер RAMCOE
constant C_VCTRL_REG_CTRL_RAMCOE_M_BIT        : integer:=14;
constant C_VCTRL_REG_CTRL_LAST_BIT            : integer:=C_VCTRL_REG_CTRL_RAMCOE_M_BIT;

--//Индексы для поля VCTRL_REG_CTRL_RAMCOENUM:
constant C_VCTRL_RAMCOE_SCALE                 : integer:=0;
constant C_VCTRL_RAMCOE_PCOLR                 : integer:=1;
constant C_VCTRL_RAMCOE_PCOLG                 : integer:=2;
constant C_VCTRL_RAMCOE_PCOLB                 : integer:=3;
constant C_VCTRL_RAMCOE_GAMMA_GRAY            : integer:=4;
constant C_VCTRL_RAMCOE_GAMMA_COLR            : integer:=5;
constant C_VCTRL_RAMCOE_GAMMA_COLG            : integer:=6;
constant C_VCTRL_RAMCOE_GAMMA_COLB            : integer:=7;

--//Индексы для поля VCTRL_REG_CTRL_PRMNUM:
constant C_VCTRL_PRM_MEM_ADR_WR               : integer:=0;--Базовый адрес буфера записи видео
constant C_VCTRL_PRM_MEM_ADR_RD               : integer:=1;--Базовый адрес буфера чтения видео
constant C_VCTRL_PRM_FR_ZONE_SKIP             : integer:=2;
constant C_VCTRL_PRM_FR_ZONE_ACTIVE           : integer:=3;
constant C_VCTRL_PRM_FR_OPTIONS               : integer:=4;
--//Мах кол-во режимов установок параметров:
constant C_VCTRL_PRM_COUNT_MAX                : integer:=pwr(2, (C_VCTRL_REG_CTRL_PRM_M_BIT-C_VCTRL_REG_CTRL_PRM_L_BIT+1));


--//Register VCTRL_REG_MEM_ADDR / Bit Map:
constant C_VCTRL_REG_MEM_ADR_BANK_L_BIT       : integer:=31;
constant C_VCTRL_REG_MEM_ADR_BANK_M_BIT       : integer:=31;
constant C_VCTRL_REG_MEM_LAST_BIT             : integer:=C_VCTRL_REG_MEM_ADR_BANK_M_BIT;

--//Memory map for video: (max frame size: 2048x2048)
--//                                          : integer:=0; --Пиксели видеокадра(VLINE_LSB-1...0)
constant C_VCTRL_MEM_VLINE_L_BIT              : integer:=C_PCFG_VCTRL_MEM_VLINE_L_BIT;--Строки видеокадра (MSB...LSB)
constant C_VCTRL_MEM_VLINE_M_BIT              : integer:=C_PCFG_VCTRL_MEM_VLINE_M_BIT;
constant C_VCTRL_MEM_VFR_L_BIT                : integer:=C_PCFG_VCTRL_MEM_VFR_L_BIT  ;--Номер кадра (MSB...LSB) - Видеобуфера
constant C_VCTRL_MEM_VFR_M_BIT                : integer:=C_PCFG_VCTRL_MEM_VFR_M_BIT  ;
constant C_VCTRL_MEM_VCH_L_BIT                : integer:=C_PCFG_VCTRL_MEM_VCH_L_BIT  ;--Номер видео канала (MSB...LSB)
constant C_VCTRL_MEM_VCH_M_BIT                : integer:=C_PCFG_VCTRL_MEM_VCH_M_BIT  ;

--//Мах кол-во видео каналов:
constant C_VCTRL_VCH_COUNT                    : integer:=C_PCFG_VCTRL_VCH_COUNT;
constant C_VCTRL_VCH_COUNT_MAX                : integer:=pwr(2, (C_VCTRL_MEM_VCH_M_BIT-C_VCTRL_MEM_VCH_L_BIT+1));


--//Register C_VCTRL_REG_TST0 / Bit Map:
constant C_VCTRL_REG_TST0_DBG_TBUFRD_BIT      : integer:=0;--Отладка модуля слежения - отображение содержимого RAM/TRACK/TBUF
constant C_VCTRL_REG_TST0_DBG_EBUFRD_BIT      : integer:=1;--Отладка модуля слежения - отображение содержимого RAM/TRACK/EBUF
constant C_VCTRL_REG_TST0_DBG_SOBEL_BIT       : integer:=2;--1/0 - Отладка модуля собела Выдача Grad/Video
constant C_VCTRL_REG_TST0_DBG_ROTRIGHT_BIT    : integer:=3;--Поворот на 90 вправо
constant C_VCTRL_REG_TST0_DBG_ROTLEFT_BIT     : integer:=4;--Поворот на 90 влево
constant C_VCTRL_REG_TST0_DBG_DIS_DEMCOLOR_BIT: integer:=5;--1/0 - Запретить работу модуля vcoldemosaic_main.vhd
constant C_VCTRL_REG_TST0_DBG_DCOUNT_BIT      : integer:=6;--1 - Вместо данных строки вставляется счетчик
constant C_VCTRL_REG_TST0_DBG_PICTURE_BIT     : integer:=7;--Запрещаю запись видео в ОЗУ + запрещаю инкрементацию счетчика vbuf,
                                                           --при бит(7)=1 - vbuf=0
constant C_VCTRL_REG_TST0_SKIPFR_CNT_CLR_BIT  : integer:=8;--При 1 - происходит сброс счетчиков пропущеных кадров tst_vfrskip,
                                                           --При 0 - нет
--constant RESERV                               : integer:=9;
constant C_VCTRL_REG_TST0_DBG_RDHOLD_BIT      : integer:=10;--Эмуляция захвата видеобуфера модулем чтения
constant C_VCTRL_REG_TST0_DBG_TRCHOLD_BIT     : integer:=11;--Эмуляция захвата видеобуфера модулем слежения
constant C_VCTRL_REG_TST0_LAST_BIT            : integer:=C_VCTRL_REG_TST0_DBG_TRCHOLD_BIT;



end prj_def;


package body prj_def is

end prj_def;

