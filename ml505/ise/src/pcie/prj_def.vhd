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
constant C_FPGA_FIRMWARE_VERSION : integer:=16#034C#;

--//VCTRL
constant C_VIDEO_PKT_HEADER_SIZE : integer:=5;--//DWORD


--//--------------------------------------------------------------
--//Регистры модуля dsn_host.vhd: (max count HREG - 0x1F)
--//--------------------------------------------------------------
constant C_HREG_FIRMWARE                      : integer:=16#00#;--//Версия прошивки FPGA
constant C_HREG_CTRL                          : integer:=16#01#;--//Глобальное управление
constant C_HREG_DMAPRM_ADR                    : integer:=16#02#;--//Адрес буфера выдленого в памяти PC драйвером PCI-Express
constant C_HREG_DMAPRM_LEN                    : integer:=16#03#;--//Размер буфера(в байтах) выдленого в памяти PC драйвером PCI-Express
constant C_HREG_DEV_CTRL                      : integer:=16#04#;--//Управление устр-вами подключенными к модулю dsn_host.vhd
constant C_HREG_DEV_STATUS                    : integer:=16#05#;--//Статусы устройств подключенных к модулю dsn_host.vhd
constant C_HREG_DEV_DATA                      : integer:=16#06#;--//Регистр чтения/записи данных когда не используетя DMA транзакция
constant C_HREG_IRQ                           : integer:=16#07#;--//Прерывания: управление(wr only) + статусы(rd only)
constant C_HREG_MEM_ADR                       : integer:=16#08#;--//Адрес ОЗУ подключенного к FPGA
constant C_HREG_MEM_CTRL                      : integer:=16#09#;
constant C_HREG_VCTRL_FRMRK                   : integer:=16#0A#;--//Маркер вычитаного видеокадра
constant C_HREG_VCTRL_FRERR                   : integer:=16#0B#;--//
constant C_HREG_TIME                          : integer:=16#0C#;--[31]-overday, [30:26]-часы, [25:20]-минуты, [19:14]-секунды, [13:4]-мс, [3:0]-сотни мкс.
constant C_HREG_PCIE                          : integer:=16#0D#;--//Инф + Тюнинг("тонкая" настройка) PCI-Express
constant C_HREG_FUNC                          : integer:=16#0E#;--//Используемые модули проекта FPGA
constant C_HREG_FUNCPRM                       : integer:=16#0F#;--//Информация о модулях
--constant C_HREG_RESERV                        : integer:=...
constant C_HREG_TST0                          : integer:=16#1C#;--//Тестовые регистры
constant C_HREG_TST1                          : integer:=16#1D#;
constant C_HREG_TST2                          : integer:=16#1E#;
--constant C_HREG_TST3                          : integer:=16#1F#;


--//Register C_HREG_FIRMWARE / Bit Map:
constant C_HREG_FRMWARE_LAST_BIT              : integer:=15;


--//Register C_HREG_CTRL / Bit Map:
constant C_HREG_CTRL_RST_ALL_BIT              : integer:=0;--//Сбросы устройств
constant C_HREG_CTRL_RST_MEM_BIT              : integer:=1;--//
constant C_HREG_CTRL_RST_ETH_BIT              : integer:=2;--//
constant C_HREG_CTRL_RDDONE_VCTRL_BIT         : integer:=3;--//Чтение завершено
constant C_HREG_CTRL_RST_PULT_BIT             : integer:=4;--
constant C_HREG_CTRL_RST_EDEV_BIT             : integer:=5;--
constant C_HREG_CTRL_ESYNC_IEDGE_BIT          : integer:=6;--управляющие фронты входов внешней синхронизации (0-rise)
constant C_HREG_CTRL_ESYNC_OEDGE_BIT          : integer:=7;--управляющие фронты выходов на внешнюю синхронизацию (0-rise)
constant C_HREG_CTRL_ESYNC_MODE_L_BIT         : integer:=8;--'10'-внешняя, '01'-PPS, '11','00'-внутренняя синхронизация
constant C_HREG_CTRL_ESYNC_MODE_M_BIT         : integer:=9;--
constant C_HREG_CTRL_TIME_MODE_BIT            : integer:=10;--установка часов (0-сразу и поехали, 1-по сигналу минутки)
constant C_HREG_CTRL_TIME_EN_BIT              : integer:=11;--разрешение работы часов (1-разрешить)
constant C_HREG_CTRL_RST_BUP_BIT              : integer:=12;--//
constant C_HREG_CTRL_RST_VIZIR_BIT            : integer:=13;--//
constant C_HREG_CTRL_BITCLK_VIZIR_BIT         : integer:=14;--//1/0  = bitclk 1MHz/ bitclk 250kHz
constant C_HREG_CTRL_LAST_BIT                 : integer:=C_HREG_CTRL_BITCLK_VIZIR_BIT;


--//Register C_HREG_DEV_CTRL / Bit Map:
constant C_HREG_DEV_CTRL_DRDY_BIT             : integer:=0; --//(Драйвером не используется)
constant C_HREG_DEV_CTRL_DMA_START_BIT        : integer:=1; --//(Передний фронт)Запуск текущей операции
constant C_HREG_DEV_CTRL_DMA_DIR_BIT          : integer:=2; --//1/0 – Чтение/Запись данных пользовательского устройства
constant C_HREG_DEV_CTRL_DMABUF_L_BIT         : integer:=3; --//Стартовый номер буфера с параметрами PCIE_DMA
constant C_HREG_DEV_CTRL_DMABUF_M_BIT         : integer:=10;--//
constant C_HREG_DEV_CTRL_DMABUF_COUNT_L_BIT   : integer:=11;--//Общее кол-во буферов с параметрами PCIE_DMA
constant C_HREG_DEV_CTRL_DMABUF_COUNT_M_BIT   : integer:=18;--//
constant C_HREG_DEV_CTRL_ADR_L_BIT            : integer:=19;--//Номер пользовательского устройства:(C_HDEV_xxx)
constant C_HREG_DEV_CTRL_ADR_M_BIT            : integer:=22;--//
constant C_HREG_DEV_CTRL_VCH_L_BIT            : integer:=23;--//Номер видео канала
constant C_HREG_DEV_CTRL_VCH_M_BIT            : integer:=25;--//
constant C_HREG_DEV_CTRL_LAST_BIT             : integer:=C_HREG_DEV_CTRL_VCH_M_BIT;--//Max 31

--//Поле C_HREG_DEV_CTRL_ADR - Номера пользовательских устройств:
constant C_HDEV_CFG_DBUF                      : integer:=0;--//Буфера RX/TX CFG
constant C_HDEV_ETH_DBUF                      : integer:=1;--//Буфера RX/TX ETH
constant C_HDEV_MEM_DBUF                      : integer:=2;--//ОЗУ
constant C_HDEV_VCH_DBUF                      : integer:=3;--//Буфер Видеоинформации
constant C_HDEV_EDEV_DBUF                     : integer:=4;--External Device (камеры, объективы...)
constant C_HDEV_PULT_DBUF                     : integer:=5;--
constant C_HDEV_VIZIR_DBUF                    : integer:=6;--
constant C_HDEV_BUP_DBUF                      : integer:=7;--Блок управления приводами
constant C_HDEV_COUNT                         : integer:=C_HDEV_BUP_DBUF+1;
constant C_HDEV_COUNT_MAX                     : integer:=pwr(2, (C_HREG_DEV_CTRL_ADR_M_BIT-C_HREG_DEV_CTRL_ADR_L_BIT+1));

--//Register C_HOST_REG_STATUS_DEV / Bit Map:
constant C_HREG_DEV_STATUS_INT_ACT_BIT        : integer:=0; --//Не используется драйвером
constant C_HREG_DEV_STATUS_PCIE_DMAWR_DONE_BIT: integer:=1; --//Не используется драйвером
constant C_HREG_DEV_STATUS_PCIE_DMARD_DONE_BIT: integer:=2; --//Не используется драйвером
constant C_HREG_DEV_STATUS_PCIE_ERR_BIT       : integer:=3; --//Не используется драйвером
constant C_HREG_DEV_STATUS_DMA_BUSY_BIT       : integer:=4; --//PCIE_DMA
constant C_HREG_DEV_STATUS_CFG_RDY_BIT        : integer:=5; --//CFG
constant C_HREG_DEV_STATUS_CFG_RXRDY_BIT      : integer:=6;
constant C_HREG_DEV_STATUS_CFG_TXRDY_BIT      : integer:=7;
constant C_HREG_DEV_STATUS_ETH_RDY_BIT        : integer:=8; --//ETH
constant C_HREG_DEV_STATUS_ETH_LINK_BIT       : integer:=9;
constant C_HREG_DEV_STATUS_ETH_RXRDY_BIT      : integer:=10;
constant C_HREG_DEV_STATUS_ETH_TXRDY_BIT      : integer:=11;
constant C_HREG_DEV_STATUS_MEMCTRL_RDY_BIT    : integer:=12;--//
constant C_HREG_DEV_STATUS_EDEV_TXRDY_BIT     : integer:=13;
constant C_HREG_DEV_STATUS_EDEV_RXRDY_BIT     : integer:=14;
constant C_HREG_DEV_STATUS_EDEV_RXERR_BIT     : integer:=15;
constant C_HREG_DEV_STATUS_VCH0_FRRDY_BIT     : integer:=16;--//
constant C_HREG_DEV_STATUS_VCH1_FRRDY_BIT     : integer:=17;
constant C_HREG_DEV_STATUS_VCH2_FRRDY_BIT     : integer:=18;
constant C_HREG_DEV_STATUS_VCH3_FRRDY_BIT     : integer:=19;
constant C_HREG_DEV_STATUS_VCH4_FRRDY_BIT     : integer:=20;
constant C_HREG_DEV_STATUS_VCH5_FRRDY_BIT     : integer:=21;
constant C_HREG_DEV_STATUS_PULT_TXRDY_BIT     : integer:=22;
constant C_HREG_DEV_STATUS_PULT_RXRDY_BIT     : integer:=23;
constant C_HREG_DEV_STATUS_VIZIR_TXRDY_BIT    : integer:=24;
constant C_HREG_DEV_STATUS_VIZIR_RXRDY_BIT    : integer:=25;
constant C_HREG_DEV_STATUS_VIZIR_RXERR_BIT    : integer:=26;
constant C_HREG_DEV_STATUS_BUP_TXRDY_BIT      : integer:=27;
constant C_HREG_DEV_STATUS_BUP_RXRDY_BIT      : integer:=28;
constant C_HREG_DEV_STATUS_BUP_RXERR_BIT      : integer:=29;
constant C_HREG_DEV_STATUS_LAST_BIT           : integer:=C_HREG_DEV_STATUS_BUP_RXERR_BIT;


--//Register C_HREG_IRQ / Bit Map:
constant C_HREG_IRQ_NUM_L_WBIT                : integer:=0; --//Номер источника прерывания
constant C_HREG_IRQ_NUM_M_WBIT                : integer:=4; --//
constant C_HREG_IRQ_EN_WBIT                   : integer:=13; --//Разрешение прерывания от соответствующего источника
constant C_HREG_IRQ_DIS_WBIT                  : integer:=14; --//Зпрещение прерывания от соответствующего источника
constant C_HREG_IRQ_CLR_WBIT                  : integer:=15; --//Сброс статуса активности соотв. источника прерывания
constant C_HREG_IRQ_LAST_WBIT                 : integer:=C_HREG_IRQ_CLR_WBIT;

constant C_HREG_IRQ_STATUS_L_RBIT             : integer:=0; --//Статус активности прерывания от соотв. источника
constant C_HREG_IRQ_STATUS_M_RBIT             : integer:=31;--//

--//Поле C_HREG_IRQ_NUM - Номера источников прерываний:
constant C_HIRQ_PCIE_DMA                      : integer:=0;
constant C_HIRQ_CFG_RX                        : integer:=1;
constant C_HIRQ_ETH_RX                        : integer:=2;
constant C_HIRQ_EDEV_RX                       : integer:=3;
constant C_HIRQ_PULT_RX                       : integer:=4;
constant C_HIRQ_VCH0                          : integer:=5;
constant C_HIRQ_VCH1                          : integer:=6;
constant C_HIRQ_VCH2                          : integer:=7;
constant C_HIRQ_VCH3                          : integer:=8;
constant C_HIRQ_VCH4                          : integer:=9;
constant C_HIRQ_VCH5                          : integer:=10;
constant C_HIRQ_VIZIR_RX                      : integer:=11;
constant C_HIRQ_BUP_RX                        : integer:=12;
constant C_HIRQ_COUNT                         : integer:=C_HIRQ_BUP_RX+1;
constant C_HIRQ_COUNT_MAX                     : integer:=pwr(2, (C_HREG_IRQ_NUM_M_WBIT-C_HREG_IRQ_NUM_L_WBIT+1));


--//Register C_HREG_MEM_ADR / Bit Map:
constant C_HREG_MEM_ADR_OFFSET_L_BIT          : integer:=0;
constant C_HREG_MEM_ADR_OFFSET_M_BIT          : integer:=29;
constant C_HREG_MEM_ADR_BANK_L_BIT            : integer:=30;
constant C_HREG_MEM_ADR_BANK_M_BIT            : integer:=30;
constant C_HREG_MEM_ADR_LAST_BIT              : integer:=C_HREG_MEM_ADR_BANK_M_BIT;

--//Register C_HREG_MEM_CTRL / Bit Map:
constant C_HREG_MEM_CTRL_TRNWR_L_BIT          : integer:=0;
constant C_HREG_MEM_CTRL_TRNWR_M_BIT          : integer:=7;
constant C_HREG_MEM_CTRL_TRNRD_L_BIT          : integer:=8;
constant C_HREG_MEM_CTRL_TRNRD_M_BIT          : integer:=15;
constant C_HREG_MEM_CTRL_LAST_BIT             : integer:=C_HREG_MEM_CTRL_TRNRD_M_BIT;


--//Register C_HREG_PCIE / Bit Map:
constant C_HREG_PCIE_REQ_LINK_L_RBIT          : integer:=0;
constant C_HREG_PCIE_REQ_LINK_M_RBIT          : integer:=5;
constant C_HREG_PCIE_NEG_LINK_L_RBIT          : integer:=6; --//исользуется Максом
constant C_HREG_PCIE_NEG_LINK_M_RBIT          : integer:=11;--//исользуется Максом
constant C_HREG_PCIE_REQ_MAX_PAYLOAD_L_RBIT   : integer:=12;--//исользуется Максом
constant C_HREG_PCIE_REQ_MAX_PAYLOAD_M_RBIT   : integer:=14;--//исользуется Максом
constant C_HREG_PCIE_NEG_MAX_PAYLOAD_L_BIT    : integer:=15;--//исользуется Максом
constant C_HREG_PCIE_NEG_MAX_PAYLOAD_M_BIT    : integer:=17;--//исользуется Максом
constant C_HREG_PCIE_NEG_MAX_RD_REQ_L_BIT     : integer:=18;--//исользуется Максом
constant C_HREG_PCIE_NEG_MAX_RD_REQ_M_BIT     : integer:=20;--//исользуется Максом
constant C_HREG_PCIE_TAG_EXT_EN_RBIT          : integer:=21;
constant C_HREG_PCIE_PHANT_FUNC_RBIT          : integer:=22;
constant C_HREG_PCIE_NOSNOOP_RBIT             : integer:=23;
--constant RESERV                               : integer:=24;
constant C_HREG_PCIE_CPL_STREAMING_BIT        : integer:=26;--//исользуется Максом
constant C_HREG_PCIE_METRING_BIT              : integer:=27;--//исользуется Максом
constant C_HREG_PCIE_SPEED_TESTING_BIT        : integer:=28;
constant C_HREG_PCIE_LAST_BIT                 : integer:=C_HREG_PCIE_SPEED_TESTING_BIT;


--//Register C_HREG_FUNC / Bit Map:
--//1/0 - используется/не используется в проекте FPGA
constant C_HREG_FUNC_MEM_BIT                  : integer:=0;
constant C_HREG_FUNC_TMR_BIT                  : integer:=1;
constant C_HREG_FUNC_VCTRL_BIT                : integer:=2;
constant C_HREG_FUNC_ETH_BIT                  : integer:=3;
constant C_HREG_FUNC_HDD_BIT                  : integer:=4;
constant C_HREG_FUNC_VRESEK21_BIT             : integer:=5;
constant C_HREG_FUNC_LAST_BIT                 : integer:=C_HREG_FUNC_VRESEK21_BIT;


--//Register C_HREG_FUNCPRM / Bit Map:
constant C_HREG_FUNCPRM_MEMBANK_SIZE_L_BIT    : integer:=0;
constant C_HREG_FUNCPRM_MEMBANK_SIZE_M_BIT    : integer:=2;
constant C_HREG_FUNCPRM_VCTRL_VCH_COUNT_L_BIT : integer:=3;
constant C_HREG_FUNCPRM_VCTRL_VCH_COUNT_M_BIT : integer:=5;
constant C_HREG_FUNCPRM_VCTRL_MIR_BIT         : integer:=6;
constant C_HREG_FUNCPRM_VCTRL_ZOOM_BIT        : integer:=7;
constant C_HREG_FUNCPRM_VCTRL_BAYER_BIT       : integer:=8;
constant C_HREG_FUNCPRM_VCTRL_PCOLOR_BIT      : integer:=9;
constant C_HREG_FUNCPRM_VCTRL_GAMMA_BIT       : integer:=10;
constant C_HREG_FUNCPRM_LAST_BIT              : integer:=C_HREG_FUNCPRM_VCTRL_GAMMA_BIT;


--//Порт модуля dsn_host.vhd /p_out_dev_din/out/ Bit Map:
constant C_HDEV_DWIDTH                        : integer:=64;

--//Порт модуля dsn_host.vhd /p_in_dev_option/ Bit Map:
constant C_HDEV_OPTIN_TXFIFO_PFULL_BIT        : integer:=0;
constant C_HDEV_OPTIN_RXFIFO_EMPTY_BIT        : integer:=1;
constant C_HDEV_OPTIN_MEMTRN_DONE_BIT         : integer:=2;
constant C_HDEV_OPTIN_VCTRL_FRMRK_L_BIT       : integer:=3;
constant C_HDEV_OPTIN_VCTRL_FRMRK_M_BIT       : integer:=34;--C_HDEV_OPTIN_VCTRL_FRMRK_L_BIT + 31;
constant C_HDEV_OPTIN_VCTRL_FRSKIP_L_BIT      : integer:=35;
constant C_HDEV_OPTIN_VCTRL_FRSKIP_M_BIT      : integer:=42;--C_HDEV_OPTIN_VCTRL_FRSKIP_L_BIT + 7;
constant C_HDEV_OPTIN_TIME_L_BIT              : integer:=43;
constant C_HDEV_OPTIN_TIME_M_BIT              : integer:=74;--C_HDEV_OPTIN_TIME_L_BIT + 31
constant C_HDEV_OPTIN_LAST_BIT                : integer:=C_HDEV_OPTIN_TIME_M_BIT;

--//Порт модуля dsn_host.vhd /p_out_dev_option/ Bit Map:
constant C_HDEV_OPTOUT_MEM_ADR_L_BIT          : integer:=0;
constant C_HDEV_OPTOUT_MEM_ADR_M_BIT          : integer:=31;
constant C_HDEV_OPTOUT_MEM_RQLEN_L_BIT        : integer:=32;
constant C_HDEV_OPTOUT_MEM_RQLEN_M_BIT        : integer:=49;--C_HDEV_OPTOUT_MEM_RQLEN_L_BIT + 21 (mem_rqlen - значение в BYTE. max 2MB)
constant C_HDEV_OPTOUT_MEM_TRNWR_LEN_L_BIT    : integer:=50;
constant C_HDEV_OPTOUT_MEM_TRNWR_LEN_M_BIT    : integer:=57;--C_HDEV_OPTOUT_MEM_TRNWR_LEN_L_BIT + 8 (mem_trnwr - значение в DWORD.)
constant C_HDEV_OPTOUT_MEM_TRNRD_LEN_L_BIT    : integer:=58;
constant C_HDEV_OPTOUT_MEM_TRNRD_LEN_M_BIT    : integer:=65;--C_HDEV_OPTOUT_MEM_TRNRD_LEN_L_BIT + 8 (mem_trnrd - значение в DWORD.)
constant C_HDEV_OPTOUT_TIME_L_BIT             : integer:=66;
constant C_HDEV_OPTOUT_TIME_M_BIT             : integer:=97;--C_HDEV_OPTOUT_TIME_L_BIT + 31
constant C_HDEV_OPTOUT_TIME_SET_BIT           : integer:=98;
constant C_HDEV_OPTOUT_LAST_BIT               : integer:=C_HDEV_OPTOUT_TIME_SET_BIT;



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
constant C_CFGDEV_COUNT_MAX                   : integer:=256;--//Определяется константами C_CFGPKT_DADR_M/L_BIT в cfgdev_pkg.vhd



--//--------------------------------------------------------------
--//Регистры модуля dsn_timer.vhd
--//--------------------------------------------------------------
constant C_TMR_REG_CTRL                       : integer:=16#000#;
constant C_TMR_REG_CMP_L                      : integer:=16#001#;
constant C_TMR_REG_CMP_M                      : integer:=16#002#;


--//Register C_TMR_REG_CTRL / Bit Map:
constant C_TMR_REG_CTRL_NUM_L_BIT             : integer:=0;--//Номер таймера
constant C_TMR_REG_CTRL_NUM_M_BIT             : integer:=3;
constant C_TMR_REG_CTRL_EN_BIT                : integer:=14;
constant C_TMR_REG_CTRL_DIS_BIT               : integer:=15;
--constant C_TMR_REG_CTRL_STATUS_EN_L_RBIT      : integer:=0;--//только при чтении рег. C_TMR_REG_CTRL
--constant C_TMR_REG_CTRL_STATUS_EN_M_RBIT      : integer:=xxx;
constant C_TMR_REG_CTRL_LAST_BIT              : integer:=C_TMR_REG_CTRL_DIS_BIT;


--//Определяем кол-во таймеров в dsn_timer.vhd
constant C_TMR_COUNT                          : integer:=6;
constant C_TMR_COUNT_MAX                      : integer:=pwr(2, (C_TMR_REG_CTRL_NUM_M_BIT-C_TMR_REG_CTRL_NUM_L_BIT+1));

constant C_TMR_ETH                            : integer:=0;
constant C_TMR_EDEV                           : integer:=1;
constant C_TMR_PULT                           : integer:=2;
constant C_TMR_BUP                            : integer:=3;
constant C_TMR_VIZIR                          : integer:=4;


--//--------------------------------------------------------------
--//Регистры модуля dsn_switch.vhd
--//--------------------------------------------------------------
constant C_SWT_REG_CTRL                       : integer:=16#07#;
constant C_SWT_REG_FRR_ETHG_HOST              : integer:=16#08#;
constant C_SWT_REG_FRR_ETHG_VCTRL             : integer:=16#10#;--//C_SWT_REG_FRR_ETHG_HDD + C_SWT_FRR_COUNT_MAX
constant C_SWT_REG_FRR_ETHG_HDD               : integer:=16#18#;--//C_SWT_REG_FRR_ETHG_HOST + C_SWT_FRR_COUNT_MAX


--//Register C_SWT_REG_CTRL / Bit Map:
constant C_SWT_REG_CTRL_RST_ETH_BUFS_BIT      : integer:=0;
constant C_SWT_REG_CTRL_RST_VCTRL_BUFS_BIT    : integer:=1;
constant C_SWT_REG_CTRL_TSTDSN_2_ETHTXBUF_BIT : integer:=2;
constant C_SWT_REG_CTRL_LAST_BIT              : integer:=C_SWT_REG_CTRL_TSTDSN_2_ETHTXBUF_BIT;


--//Мах кол-во правил машрутиразции:
constant C_SWT_FRR_COUNT_MAX                  : integer:=8;

--//
constant C_SWT_ETH_HOST_FRR_COUNT             : integer:=3;--//Кол-во правил машрутизации пакетов ETH-HOST
constant C_SWT_ETH_VCTRL_FRR_COUNT            : integer:=C_PCFG_VCTRL_VCH_COUNT;--//Кол-во правил машрутизации пакетов ETH-VCTRL
constant C_SWT_ETH_HDD_FRR_COUNT              : integer:=3;--//Кол-во правил машрутизации пакетов ETH-HDD

Type TEthFRRGet is array (0 to C_SWT_FRR_COUNT_MAX-1) of integer;
----------------------------------------------------------------------------------------
--//C_SWT_ETH_xxx_FRR_COUNT - значения:          | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 |
----------------------------------------------------------------------------------------
constant C_SWT_GET_FMASK_REG_COUNT : TEthFRRGet:=( 1,  1,  2,  2,  3,  3,  4,  4 );
Type TEthFRR is array (0 to C_SWT_FRR_COUNT_MAX-1) of std_logic_vector(7 downto 0);
--Маска фильтрации (7...0), где
-- 3..0 - тип пакета
-- 7..4 - подтип пакета



--//--------------------------------------------------------------
--//Регистры модуля dsn_eth.vhd
--//--------------------------------------------------------------
constant C_ETH_REG_CTRL                       : integer:=16#000#;
constant C_ETH_REG_MAC_PATRN0                 : integer:=16#001#;--//DST MAC
constant C_ETH_REG_MAC_PATRN1                 : integer:=16#002#;
constant C_ETH_REG_MAC_PATRN2                 : integer:=16#003#;
constant C_ETH_REG_MAC_PATRN3                 : integer:=16#004#;--//SRC MAC
constant C_ETH_REG_MAC_PATRN4                 : integer:=16#005#;
constant C_ETH_REG_MAC_PATRN5                 : integer:=16#006#;
constant C_ETH_REG_IP_PATRN0                  : integer:=16#007#;--//DST IP
constant C_ETH_REG_IP_PATRN1                  : integer:=16#008#;
constant C_ETH_REG_IP_PATRN2                  : integer:=16#009#;--//SRC IP
constant C_ETH_REG_IP_PATRN3                  : integer:=16#00A#;
constant C_ETH_REG_PORT_PATRN0                : integer:=16#00B#;--//DST PORT
constant C_ETH_REG_PORT_PATRN1                : integer:=16#00C#;--//SRC PORT


--//--------------------------------------------------------------
--//Регистры модуля dsn_video_ctrl.vhd
--//--------------------------------------------------------------
constant C_VCTRL_REG_CTRL                     : integer:=16#000#;
constant C_VCTRL_REG_DATA_L                   : integer:=16#001#;
constant C_VCTRL_REG_DATA_M                   : integer:=16#002#;
constant C_VCTRL_REG_MEM_CTRL                 : integer:=16#003#;--//(15..8)(7..0) - trn_mem_rd;trn_mem_wr
constant C_VCTRL_REG_TST0                     : integer:=16#004#;


--//Register C_VCTRL_REG_CTRL / Bit Map:
constant C_VCTRL_REG_CTRL_VCH_L_BIT           : integer:=0;--//Номер видео канала
constant C_VCTRL_REG_CTRL_VCH_M_BIT           : integer:=3;
constant C_VCTRL_REG_CTRL_PRM_L_BIT           : integer:=4;--//Номер парамера
constant C_VCTRL_REG_CTRL_PRM_M_BIT           : integer:=6;
constant C_VCTRL_REG_CTRL_SET_BIT             : integer:=7;
constant C_VCTRL_REG_CTRL_SET_IDLE_BIT        : integer:=8;
constant C_VCTRL_REG_CTRL_RAMCOE_ADR_BIT      : integer:=9;
constant C_VCTRL_REG_CTRL_RAMCOE_DATA_BIT     : integer:=10;
constant C_VCTRL_REG_CTRL_RAMCOE_L_BIT        : integer:=11;--//Номер RAMCOE
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
constant C_VCTRL_PRM_MEM_ADR_WR               : integer:=0;--//Базовый адрес буфера записи видео
constant C_VCTRL_PRM_MEM_ADR_RD               : integer:=1;--//Базовый адрес буфера чтения видео
constant C_VCTRL_PRM_FR_ZONE_SKIP             : integer:=2;
constant C_VCTRL_PRM_FR_ZONE_ACTIVE           : integer:=3;
constant C_VCTRL_PRM_FR_OPTIONS               : integer:=4;
--//Мах кол-во режимов установок параметров:
constant C_VCTRL_PRM_COUNT_MAX                : integer:=pwr(2, (C_VCTRL_REG_CTRL_PRM_M_BIT-C_VCTRL_REG_CTRL_PRM_L_BIT+1));


--//Register VCTRL_REG_MEM_ADDR / Bit Map:
constant C_VCTRL_REG_MEM_ADR_OFFSET_L_BIT     : integer:=C_HREG_MEM_ADR_OFFSET_L_BIT;
constant C_VCTRL_REG_MEM_ADR_OFFSET_M_BIT     : integer:=C_HREG_MEM_ADR_OFFSET_M_BIT;
constant C_VCTRL_REG_MEM_ADR_BANK_L_BIT       : integer:=C_HREG_MEM_ADR_BANK_L_BIT;
constant C_VCTRL_REG_MEM_ADR_BANK_M_BIT       : integer:=C_HREG_MEM_ADR_BANK_M_BIT;
constant C_VCTRL_REG_MEM_LAST_BIT             : integer:=C_VCTRL_REG_MEM_ADR_BANK_M_BIT;

--//Как поделена память ОЗУ для записи/чтение видеоинформации:
--//                                          : integer:=0; --//Пиксели видеокадра(VLINE_LSB-1...0)
constant C_VCTRL_MEM_VLINE_L_BIT              : integer:=11;--//Строки видеокадра (MSB...LSB)
constant C_VCTRL_MEM_VLINE_M_BIT              : integer:=21;
constant C_VCTRL_MEM_VFR_L_BIT                : integer:=22;--//Номер кадра (MSB...LSB) - Видеобуфера
constant C_VCTRL_MEM_VFR_M_BIT                : integer:=23;--//
constant C_VCTRL_MEM_VCH_L_BIT                : integer:=24;--//Номер видео канала (MSB...LSB)
constant C_VCTRL_MEM_VCH_M_BIT                : integer:=26;

--//Мах кол-во видео каналов:
constant C_VCTRL_VCH_COUNT                    : integer:=C_PCFG_VCTRL_VCH_COUNT;
constant C_VCTRL_VCH_COUNT_MAX                : integer:=6;--pwr(2, (C_VCTRL_MEM_VCH_M_BIT-C_VCTRL_MEM_VCH_L_BIT+1));


--//Register C_VCTRL_REG_TST0 / Bit Map:
constant C_VCTRL_REG_TST0_DBG_TBUFRD_BIT      : integer:=0;--//Отладка модуля слежения - отображение содержимого RAM/TRACK/TBUF
constant C_VCTRL_REG_TST0_DBG_EBUFRD_BIT      : integer:=1;--//Отладка модуля слежения - отображение содержимого RAM/TRACK/EBUF
constant C_VCTRL_REG_TST0_DBG_SOBEL_BIT       : integer:=2;--//1/0 - Отладка модуля собела Выдача Grad/Video
constant C_VCTRL_REG_TST0_DBG_ROTRIGHT_BIT    : integer:=3;--Поворот на 90 вправо
constant C_VCTRL_REG_TST0_DBG_ROTLEFT_BIT     : integer:=4;--Поворот на 90 влево
constant C_VCTRL_REG_TST0_DBG_DIS_DEMCOLOR_BIT: integer:=5;--//1/0 - Запретить работу модуля vcoldemosaic_main.vhd
constant C_VCTRL_REG_TST0_DBG_DCOUNT_BIT      : integer:=6;--//1 - Вместо данных строки вставляется счетчик
constant C_VCTRL_REG_TST0_DBG_PICTURE_BIT     : integer:=7;--//Запрещаю запись видео в ОЗУ + запрещаю инкрементацию счетчика vbuf,
                                                               --//при бит(7)=1 - vbuf=0
constant C_VCTRL_REG_TST0_SKIPFR_CNT_CLR_BIT  : integer:=8;--//При 1 - происходит сброс счетчиков пропущеных кадров tst_vfrskip,
                                                               --//При 0 - нет
--constant RESERV                               : integer:=9;
constant C_VCTRL_REG_TST0_DBG_RDHOLD_BIT      : integer:=10;--//Эмуляция захвата видеобуфера модулем чтения
constant C_VCTRL_REG_TST0_DBG_TRCHOLD_BIT     : integer:=11;--//Эмуляция захвата видеобуфера модулем слежения
constant C_VCTRL_REG_TST0_LAST_BIT            : integer:=C_VCTRL_REG_TST0_DBG_TRCHOLD_BIT;



end prj_def;


package body prj_def is

end prj_def;

