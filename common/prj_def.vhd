-------------------------------------------------------------------------
-- Company     : Telemix
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

package prj_def is

constant C_ON        : std_logic:='1';
constant C_OFF       : std_logic:='0';
constant C_YES       : std_logic:='1';
constant C_NO        : std_logic:='0';

--Верси прошивки FPGA
--//15..3 - ver; 3..0 - rev
constant C_FPGA_FIRMWARE_VERSION             : integer:=16#0329#;

--//Модуль Хоста
constant C_FHOST_DBUS                        : integer:=32;--//Шина данных модуля dsn_host.vhd (нельзя изменять!!!)

--//VCTRL
constant C_VIDEO_PKT_HEADER_SIZE             : integer:=5;

--//--------------------------------------------------------------
--//HOST
--//--------------------------------------------------------------
--//--------------------------------------------------------------
--//Регистры модуля dsn_host.vhd: (max count HREG - 0x1F)
--//--------------------------------------------------------------
constant C_HREG_FIRMWARE                        : integer:=16#00#;--//Версия прошивки FPGA
constant C_HREG_GCTRL                           : integer:=16#01#;--//Глобальное управление
constant C_HREG_DMAPRM_ADR                      : integer:=16#02#;--//Адрес буфера выдленого в памяти PC драйвером PCI-Express
constant C_HREG_DMAPRM_LEN                      : integer:=16#03#;--//Размер буфера(в байтах) выдленого в памяти PC драйвером PCI-Express
constant C_HREG_DEV_CTRL                        : integer:=16#04#;--//Управление устр-вами подключенными к модулю dsn_host.vhd
constant C_HREG_DEV_STATUS                      : integer:=16#05#;--//Статусы устройств подключенных к модулю dsn_host.vhd
constant C_HREG_DEV_DATA                        : integer:=16#06#;--//Регистр данных (для случая когда не используетя DMA транзакция)
constant C_HREG_IRQ_CTRL                        : integer:=16#07#;--//Прерывания: управление(wr only) + статусы(rd only)
constant C_HREG_MEM_ADR                         : integer:=16#08#;--//Адрес ОЗУ подключенного к FPGA
--constant C_HREG_RESERV                          : integer:=16#09#;
constant C_HREG_VCTRL_FRMRK                     : integer:=16#0A#;--//Маркер вычитаного видеокадра
constant C_HREG_VCTRL_FRERR                     : integer:=16#0B#;--//
constant C_HREG_TRCNIK_DSIZE                    : integer:=16#0C#;--//
constant C_HREG_PCIE_CTRL                       : integer:=16#0D#;--//Инф + Тюнинг("тонкая" настройка) PCI-Express
--constant C_HREG_RESERV                          : integer:=16#0A#...;
constant C_HREG_TST0                            : integer:=16#1C#;--//Тестовые регистры
constant C_HREG_TST1                            : integer:=16#1D#;
constant C_HREG_TST2                            : integer:=16#1E#;
--constant C_HREG_TST3                            : integer:=16#1F#;



--//Register C_HREG_FIRMWARE / Bit Map:
constant C_HREG_FRMWARE_LAST_BIT                : integer:=15;--//

--//Register C_HREG_GCTRL / Bit Map:
constant C_HREG_GCTRL_RST_ALL_BIT               : integer:=0;--//Сбросы устройств
constant C_HREG_GCTRL_RST_MEM_BIT               : integer:=1;--//
constant C_HREG_GCTRL_RST_ETH_BIT               : integer:=2;--//
constant C_HREG_GCTRL_RDDONE_VCTRL_BIT          : integer:=3;--//Чтение завершено
constant C_HREG_GCTRL_RDDONE_TRCNIK_BIT         : integer:=4;--//
constant C_HREG_GCTRL_LAST_BIT                  : integer:=C_HREG_GCTRL_RDDONE_TRCNIK_BIT;


--//Register C_HREG_DEV_CTRL / Bit Map:
constant C_HREG_DEV_CTRL_TRN_START_BIT          : integer:=0; --//(Передний фронт)Запуск текущей операции
constant C_HREG_DEV_CTRL_DRDY_BIT               : integer:=1; --//(Драйвером не используется)
constant C_HREG_DEV_CTRL_TRN_DIR_BIT            : integer:=2; --//1/0 – Чтение/Запись данных в пользовательское устройство
constant C_HREG_DEV_CTRL_ADR_L_BIT              : integer:=3; --//Номер пользовательского устройства:(C_HDEV_xxx)
constant C_HREG_DEV_CTRL_ADR_M_BIT              : integer:=6; --//
constant C_HREG_DEV_CTRL_DMABUF_NUM_L_BIT       : integer:=7; --//Стартовый номер буфера с параметрами PCIE_DMA
constant C_HREG_DEV_CTRL_DMABUF_NUM_M_BIT       : integer:=14;--//
constant C_HREG_DEV_CTRL_DMABUF_COUNT_L_BIT     : integer:=15;--//Общее кол-во буфера с параметрами PCIE_DMA
constant C_HREG_DEV_CTRL_DMABUF_COUNT_M_BIT     : integer:=22;--//
constant C_HREG_DEV_CTRL_VCH_L_BIT              : integer:=23;--//Номер видео канала
constant C_HREG_DEV_CTRL_VCH_M_BIT              : integer:=25;--//
constant C_HREG_DEV_CTRL_LAST_BIT               : integer:=C_HREG_DEV_CTRL_VCH_M_BIT;--//Max 31

--//Поле C_HREG_DEV_CTRL_ADR - Номера пользовательского устройств:
constant C_HDEV_CFG_DBUF                        : integer:=0;--//Буфера RX/TX CFG
constant C_HDEV_ETH_DBUF                        : integer:=1;--//Буфера RX/TX ETH
constant C_HDEV_MEM_DBUF                        : integer:=2;--//ОЗУ
constant C_HDEV_VCH_DBUF                        : integer:=3;--//Буфер Видеоинформации
constant C_HDEV_COUNT                           : integer:=4+1;


--//Register C_HOST_REG_STATUS_DEV / Bit Map:
constant C_HREG_DEV_STATUS_INT_ACT_BIT          : integer:=0; --//Не используется драйвером
constant C_HREG_DEV_STATUS_PCIE_ERR_BIT         : integer:=1; --//Не используется драйвером
constant C_HREG_DEV_STATUS_PCIE_DMAWR_DONE_BIT  : integer:=2; --//Не используется драйвером
constant C_HREG_DEV_STATUS_PCIE_DMARD_DONE_BIT  : integer:=3; --//Не используется драйвером
constant C_HREG_DEV_STATUS_DMA_BUSY_BIT         : integer:=4; --//PCIE_DMA
constant C_HREG_DEV_STATUS_CFG_RDY_BIT          : integer:=5; --//CFG
constant C_HREG_DEV_STATUS_CFG_RXRDY_BIT        : integer:=6;
constant C_HREG_DEV_STATUS_CFG_TXRDY_BIT        : integer:=7;
constant C_HREG_DEV_STATUS_ETH_RDY_BIT          : integer:=8; --//ETH
constant C_HREG_DEV_STATUS_ETH_CARIER_BIT       : integer:=9;
constant C_HREG_DEV_STATUS_ETH_RXRDY_BIT        : integer:=10;
constant C_HREG_DEV_STATUS_ETH_TXRDY_BIT        : integer:=11;
constant C_HREG_DEV_STATUS_MEMCTRL_RDY_BIT      : integer:=12;--//
constant C_HREG_DEV_STATUS_TRCNIK_DRDY_BIT      : integer:=13;--//
--constant RESERV                                 : integer:=14;
--constant RESERV                                 : integer:=15;
constant C_HREG_DEV_STATUS_VCH0_FRRDY_BIT       : integer:=16;--//
constant C_HREG_DEV_STATUS_VCH1_FRRDY_BIT       : integer:=17;
constant C_HREG_DEV_STATUS_VCH2_FRRDY_BIT       : integer:=18;
constant C_HREG_DEV_STATUS_VCH3_FRRDY_BIT       : integer:=19;
constant C_HREG_DEV_STATUS_LAST_BIT             : integer:=C_HREG_DEV_STATUS_VCH3_FRRDY_BIT;


--//Register C_HREG_IRQ_CTRL / Bit Map:
constant C_HREG_IRQ_NUM_L_WBIT                  : integer:=0; --//Номер источника прерывания
constant C_HREG_IRQ_NUM_M_WBIT                  : integer:=3; --//
constant C_HREG_IRQ_EN_WBIT                     : integer:=5; --//Разрешение прерывания от соответствующего источника
constant C_HREG_IRQ_DIS_WBIT                    : integer:=6; --//Зпрещение прерывания от соответствующего источника
constant C_HREG_IRQ_CLR_WBIT                    : integer:=7; --//Сброс статуса активности соотв. источника прерывания
constant C_HREG_IRQ_LAST_WBIT                   : integer:=C_HREG_IRQ_CLR_WBIT;

constant C_HREG_IRQ_STATUS_L_RBIT               : integer:=16;--//Статус активности прерывания от соотв. источника
constant C_HREG_IRQ_STATUS_M_RBIT               : integer:=31;--//

--//Поле C_HREG_IRQ_NUM - Номера источников прерываний:
constant C_HIRQ_PCIE_DMA                        : integer:=16#00#;
constant C_HIRQ_CFG_RX                          : integer:=16#01#;
constant C_HIRQ_ETH_RX                          : integer:=16#02#;
constant C_HIRQ_TMR0                            : integer:=16#03#;
constant C_HIRQ_TRCNIK                          : integer:=16#04#;
constant C_HIRQ_VCH0                            : integer:=16#05#;
constant C_HIRQ_VCH1                            : integer:=16#06#;
constant C_HIRQ_VCH2                            : integer:=16#07#;
--constant C_HIRQ_VCH3                            : integer:=16#08#;
constant C_HIRQ_COUNT                           : integer:=C_HIRQ_VCH2+1;--//Текущее кол-во источников прерываний
constant C_HIRQ_COUNT_MAX                       : integer:=16;--//Максимальное кол-во источников перываний.


--//Register C_HREG_MEM_ADR / Bit Map:
constant C_HREG_MEM_ADR_OFFSET_L_BIT            : integer:=0;
constant C_HREG_MEM_ADR_OFFSET_M_BIT            : integer:=27;
constant C_HREG_MEM_ADR_BANK_L_BIT              : integer:=28;
constant C_HREG_MEM_ADR_BANK_M_BIT              : integer:=29;
constant C_HREG_MEM_ADR_LAST_BIT                : integer:=C_HREG_MEM_ADR_BANK_M_BIT;


--//Register C_HREG_PCIE_CTRL / Bit Map:
constant C_HREG_PCIE_CTRL_REQ_LINK_L_BIT        : integer:=0;
constant C_HREG_PCIE_CTRL_REQ_LINK_M_BIT        : integer:=5;
constant C_HREG_PCIE_CTRL_NEG_LINK_L_BIT        : integer:=6; --//исользуется Максом
constant C_HREG_PCIE_CTRL_NEG_LINK_M_BIT        : integer:=11;--//исользуется Максом
constant C_HREG_PCIE_CTRL_REQ_MAX_PAYLOAD_L_BIT : integer:=12;--//исользуется Максом
constant C_HREG_PCIE_CTRL_REQ_MAX_PAYLOAD_M_BIT : integer:=14;--//исользуется Максом
constant C_HREG_PCIE_CTRL_NEG_MAX_PAYLOAD_L_BIT : integer:=15;--//исользуется Максом
constant C_HREG_PCIE_CTRL_NEG_MAX_PAYLOAD_M_BIT : integer:=17;--//исользуется Максом
constant C_HREG_PCIE_CTRL_NEG_MAX_RD_REQ_L_BIT  : integer:=18;--//исользуется Максом
constant C_HREG_PCIE_CTRL_NEG_MAX_RD_REQ_M_BIT  : integer:=20;--//исользуется Максом

constant C_HREG_PCIE_CTRL_MSI_EN_BIT            : integer:=21;
constant C_HREG_PCIE_CTRL_PHANT_FUNC_BIT        : integer:=22;
constant C_HREG_PCIE_CTRL_NOSNOOP_BIT           : integer:=23;
constant C_HREG_PCIE_CTRL_DMA_RD_NOSNOOP_BIT    : integer:=23;
constant C_HREG_PCIE_CTRL_CPLD_MALFORMED_BIT    : integer:=24;
constant C_HREG_PCIE_CTRL_TAG_EXT_EN_BIT        : integer:=25;

constant C_HREG_PCIE_CTRL_CPL_STREAMING_BIT     : integer:=26;--//исользуется Максом
constant C_HREG_PCIE_CTRL_METRING_BIT           : integer:=27;--//исользуется Максом
constant C_HREG_PCIE_CTRL_TRN_RNP_OK_BIT        : integer:=28;
constant C_HREG_PCIE_CTRL_DMA_RD_RELEX_ORDER_BIT: integer:=29;
constant C_HREG_PCIE_CTRL_DMA_WD_RELEX_ORDER_BIT: integer:=30;
constant C_HREG_PCIE_CTRL_DMA_WD_NOSNOOP_BIT    : integer:=31;

constant C_HREG_PCIE_CTRL_LAST_BIT              : integer:=C_HREG_PCIE_CTRL_DMA_WD_NOSNOOP_BIT;


--//Порт модуля dsn_host.vhd / Bit Map:
constant C_DEV_FLAG_TXFIFO_PFULL_BIT            : integer:=0;
constant C_DEV_FLAG_RXFIFO_EMPTY_BIT            : integer:=1;
constant C_DEV_FLAG_LAST_BIT                    : integer:=C_DEV_FLAG_RXFIFO_EMPTY_BIT;

--//сигнал i_dev_txdata_rdy_mask / Bit Map:
constant C_HREG_DRDY_ETHG_BIT                   : integer:=C_HDEV_ETH_DBUF;



--//--------------------------------------------------------------
--//Модуль конфигурирования (cfgdev.vhd)
--//--------------------------------------------------------------
--//Адреса устройсв доступных через модуль cfgdev.vhd
--//Device Address map:
constant C_CFGDEV_SWT                               : integer:=16#00#;
constant C_CFGDEV_ETHG                              : integer:=16#01#;
constant C_CFGDEV_VCTRL                             : integer:=16#02#;
constant C_CFGDEV_TMR                               : integer:=16#03#;
constant C_CFGDEV_TRCNIK                            : integer:=16#04#;
constant C_CFGDEV_HDD                               : integer:=16#05#;
constant C_CFGDEV_TESTING                           : integer:=16#06#;

constant C_CFGDEV_COUNT                             : integer:=16#06# + 1;



--//--------------------------------------------------------------
--//Регистры модуля dsn_timer.vhd
--//--------------------------------------------------------------
constant C_DSN_TMR_REG_CTRL                         : integer:=16#000#;
constant C_DSN_TMR_REG_CMP_L                        : integer:=16#001#;
constant C_DSN_TMR_REG_CMP_M                        : integer:=16#002#;

--//Bit Maps:
--//Register C_DSN_TMR_REG_CTRL / Bit Map:
constant C_DSN_TMR_REG_CTRL_IDX_LSB_BIT             : integer:=0;
constant C_DSN_TMR_REG_CTRL_IDX_MSB_BIT             : integer:=1;
constant C_DSN_TMR_REG_CTRL_EN_BIT                  : integer:=2;
constant C_DSN_TMR_REG_CTRL_DIS_BIT                 : integer:=3;

constant C_DSN_TMR_REG_CTRL_STATUS_EN_LSB_BIT       : integer:=0;
constant C_DSN_TMR_REG_CTRL_STATUS_EN_MSB_BIT       : integer:=3;

constant C_DSN_TMR_REG_CTRL_LAST_BIT                : integer:=C_DSN_TMR_REG_CTRL_DIS_BIT;

--//Определяем кол-во таймеров в dsn_timer.vhd
constant C_DSN_TMR_COUNT_TMR                        : integer:=16#001#;



--//--------------------------------------------------------------
--//Регистры модуля dsn_switch.vhd
--//--------------------------------------------------------------
--//Register MAP:
constant C_DSN_SWT_REG_CTRL_L                       : integer:=16#00#;
--constant C_DSN_SWT_REG_CTRL_M                       : integer:=16#01#;
constant C_DSN_SWT_REG_TST0                         : integer:=16#02#;
constant C_DSN_SWT_REG_FMASK_ETHG_HOST              : integer:=16#08#;
constant C_DSN_SWT_REG_FMASK_ETHG_HDD               : integer:=16#10#;--//C_DSN_SWT_REG_FMASK_ETHG_HOST + C_DSN_SWT_FMASK_MAX_COUNT
constant C_DSN_SWT_REG_FMASK_ETHG_VCTRL             : integer:=16#18#;--//C_DSN_SWT_REG_FMASK_ETHG_HDD + C_DSN_SWT_FMASK_MAX_COUNT


--//Bit Maps:
--//Register C_DSN_SWT_REG_CTRL / Bit Map:
constant C_DSN_SWT_REG_CTRL_ETHTXD_LOOPBACK_BIT     : integer:=0;
constant C_DSN_SWT_REG_CTRL_RST_ETH_BUFS_BIT        : integer:=1;
constant C_DSN_SWT_REG_CTRL_RST_VCTRL_BUFS_BIT      : integer:=3;
constant C_DSN_SWT_REG_CTRL_ETHTXBUF_2_VBUFIN_BIT   : integer:=4;
constant C_DSN_SWT_REG_CTRL_ETHTXBUF_2_HDDBUF_BIT   : integer:=5;
constant C_DSN_SWT_REG_CTRL_TSTDSN_2_ETHTXBUF_BIT   : integer:=6;
constant C_DSN_SWT_REG_CTRL_LAST_BIT                : integer:=C_DSN_SWT_REG_CTRL_TSTDSN_2_ETHTXBUF_BIT;


--//Register C_DSN_SWT_REG_TST0 / Bit Map:
constant C_DSN_SWT_REG_TST0_LAST_BIT                : integer:=7;


--//Register C_DSN_SWT_REG_FMASK_XXX /:
constant C_DSN_SWT_ETHG_HOST_FMASK_COUNT            : integer:=16#03#;--//Кол-во масок для фильтрации пакетов в направлении ETH-HOST
constant C_DSN_SWT_ETHG_HDD_FMASK_COUNT             : integer:=16#03#;--//Кол-во масок для фильтрации пакетов в направлении ETH-HDD
constant C_DSN_SWT_ETHG_VCTRL_FMASK_COUNT           : integer:=16#03#;--//Кол-во масок для фильтрации пакетов в направлении ETH-VCTRL


constant C_DSN_SWT_FMASK_MAX_COUNT                  : integer:=16#08#;--//Мах возможное кол-во масок для блока фильтрации пакетов
Type TEthFmaskGet is array (0 to C_DSN_SWT_FMASK_MAX_COUNT-1) of integer;
----------------------------------------------------------------------------------------
--//C_DSN_SWT_ETHG_xxx_FMASK_COUNT - значения:         | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 |
----------------------------------------------------------------------------------------
constant C_DSN_SWT_GET_FMASK_REG_COUNT : TEthFmaskGet:=( 1,  1,  2,  2,  3,  3,  4,  4 );
Type TEthFmask is array (0 to C_DSN_SWT_FMASK_MAX_COUNT-1) of std_logic_vector(7 downto 0);
--Маска фильтрации (7...0), где
-- 3..0 - тип пакета
-- 7..4 - подтип пакета




--//--------------------------------------------------------------
--//Регистры модуля dsn_hdd.vhd
--//--------------------------------------------------------------
constant C_DSN_HDD_REG_CTRL_L                       : integer:=16#000#;
constant C_DSN_HDD_REG_HWSTART_DLY                  : integer:=16#001#;
constant C_DSN_HDD_REG_STATUS_L                     : integer:=16#002#;
constant C_DSN_HDD_REG_STATUS_M                     : integer:=16#003#;

constant C_DSN_HDD_REG_LBA_BPOINT_LSB               : integer:=16#004#;
constant C_DSN_HDD_REG_LBA_BPOINT_MID               : integer:=16#005#;
constant C_DSN_HDD_REG_LBA_BPOINT_MSB               : integer:=16#006#;

constant C_DSN_HDD_REG_TEST_TWORK_L                 : integer:=16#007#;
constant C_DSN_HDD_REG_TEST_TWORK_M                 : integer:=16#008#;
constant C_DSN_HDD_REG_TEST_TDLY_L                  : integer:=16#009#;
constant C_DSN_HDD_REG_TEST_TDLY_M                  : integer:=16#00A#;

constant C_DSN_HDD_REG_HWLOG_SIZE_L                 : integer:=16#00B#;
constant C_DSN_HDD_REG_HWLOG_SIZE_M                 : integer:=16#00C#;

constant C_DSN_HDD_REG_STATUS_SATA0_L               : integer:=16#010#;
constant C_DSN_HDD_REG_STATUS_SATA0_M               : integer:=16#011#;
constant C_DSN_HDD_REG_STATUS_SATA1_L               : integer:=16#012#;
constant C_DSN_HDD_REG_STATUS_SATA1_M               : integer:=16#013#;
constant C_DSN_HDD_REG_STATUS_SATA2_L               : integer:=16#014#;
constant C_DSN_HDD_REG_STATUS_SATA2_M               : integer:=16#015#;
constant C_DSN_HDD_REG_STATUS_SATA3_L               : integer:=16#016#;
constant C_DSN_HDD_REG_STATUS_SATA3_M               : integer:=16#017#;
constant C_DSN_HDD_REG_STATUS_SATA4_L               : integer:=16#018#;
constant C_DSN_HDD_REG_STATUS_SATA4_M               : integer:=16#019#;
constant C_DSN_HDD_REG_STATUS_SATA5_L               : integer:=16#01A#;
constant C_DSN_HDD_REG_STATUS_SATA5_M               : integer:=16#01B#;
constant C_DSN_HDD_REG_STATUS_SATA6_L               : integer:=16#01C#;
constant C_DSN_HDD_REG_STATUS_SATA6_M               : integer:=16#01D#;
constant C_DSN_HDD_REG_STATUS_SATA7_L               : integer:=16#01E#;
constant C_DSN_HDD_REG_STATUS_SATA7_M               : integer:=16#01F#;

constant C_DSN_HDD_REG_CMDFIFO                      : integer:=16#020#;

constant C_DSN_HDD_REG_RBUF_ADR_L                   : integer:=16#021#;
constant C_DSN_HDD_REG_RBUF_ADR_M                   : integer:=16#022#;
constant C_DSN_HDD_REG_RBUF_CTRL_L                  : integer:=16#023#;
constant C_DSN_HDD_REG_RBUF_DATA                    : integer:=16#024#;
constant C_DSN_HDD_REG_CTRL_M                       : integer:=16#025#;


--//Bit Maps:
--//Register C_DSN_HDD_REG_CTRL_L / Bit Map:
constant C_DSN_HDD_REG_CTRLL_ERR_CLR_BIT            : integer:=0;--//Сброс ошибок
constant C_DSN_HDD_REG_CTRLL_TST_ON_BIT             : integer:=1;--//Вкл/Выкл режима измерения задержек
constant C_DSN_HDD_REG_CTRLL_TST_GEN2RAMBUF_BIT     : integer:=2;
constant C_DSN_HDD_REG_CTRLL_MEASURE_TXHOLD_DIS_BIT : integer:=3;
constant C_DSN_HDD_REG_CTRLL_TST_GEND0_BIT          : integer:=4;--//TestGen/Data=0
constant C_DSN_HDD_REG_CTRLL_TST_SPD_L_BIT          : integer:=5;
constant C_DSN_HDD_REG_CTRLL_TST_SPD_M_BIT          : integer:=12;
constant C_DSN_HDD_REG_CTRLL_ERR_STREMBUF_DIS_BIT   : integer:=13;
constant C_DSN_HDD_REG_CTRLL_HWLOG_ON_BIT           : integer:=14;
constant C_DSN_HDD_REG_CTRLL_HWSTART_DLY_ON_BIT     : integer:=15;
constant C_DSN_HDD_REG_CTRLL_LAST_BIT               : integer:=C_DSN_HDD_REG_CTRLL_HWSTART_DLY_ON_BIT;

--//Register C_DSN_HDD_REG_RBUF_ADR / Bit Map:
constant C_DSN_HDD_REG_RBUF_ADR_OFFSET_LSB_BIT      : integer:=C_HREG_MEM_ADR_OFFSET_L_BIT;
constant C_DSN_HDD_REG_RBUF_ADR_OFFSET_MSB_BIT      : integer:=C_HREG_MEM_ADR_OFFSET_M_BIT;
constant C_DSN_HDD_REG_RBUF_ADR_BANK_LSB_BIT        : integer:=C_HREG_MEM_ADR_BANK_L_BIT;
constant C_DSN_HDD_REG_RBUF_ADR_BANK_MSB_BIT        : integer:=C_HREG_MEM_ADR_BANK_M_BIT;
constant C_DSN_HDD_REG_RBUF_LAST_BIT                : integer:=C_DSN_HDD_REG_RBUF_ADR_BANK_MSB_BIT;

--//Register C_DSN_HDD_REG_RBUF_CTRL_L / Bit Map:
--constant C_DSN_HDD_REG_RBUF_CTRL_L                  : integer:=7..0;--trn_mem_wr
--constant C_DSN_HDD_REG_RBUF_CTRL_L                  : integer:=15..8;--trn_mem_rd

--//Register C_DSN_HDD_REG_HW_START_DLY / Bit Map:

--//Register C_DSN_HDD_REG_CTRL_M / Bit Map:
constant C_DSN_HDD_REG_CTRLM_RAMWR_DONE             : integer:=0;
constant C_DSN_HDD_REG_CTRLM_LAST_BIT               : integer:=C_DSN_HDD_REG_CTRLM_RAMWR_DONE;



--//--------------------------------------------------------------
--//Регистры модуля dsn_ethg.vhd
--//--------------------------------------------------------------
constant C_DSN_ETHG_REG_CTRL_L                      : integer:=16#000#;
--constant C_DSN_ETHG_REG_CTRL_M                      : integer:=16#001#;
constant C_DSN_ETHG_REG_TST0                        : integer:=16#002#;
--constant C_DSN_ETHG_REG_TST1                        : integer:=16#003#;
constant C_DSN_ETHG_REG_MAC_USRCTRL                 : integer:=16#004#;
constant C_DSN_ETHG_REG_MAC_PATRN0                  : integer:=16#005#;
constant C_DSN_ETHG_REG_MAC_PATRN1                  : integer:=16#006#;
constant C_DSN_ETHG_REG_MAC_PATRN2                  : integer:=16#007#;
constant C_DSN_ETHG_REG_MAC_PATRN3                  : integer:=16#008#;
constant C_DSN_ETHG_REG_MAC_PATRN4                  : integer:=16#009#;
constant C_DSN_ETHG_REG_MAC_PATRN5                  : integer:=16#00A#;
constant C_DSN_ETHG_REG_MAC_PATRN6                  : integer:=16#00B#;
--constant C_DSN_ETHG_REG_MAC_PATRN7                  : integer:=16#00C#;

--//Bit Maps:
--//Register C_DSN_ETHG_REG_MAC_USRCTRL / Bit Map:

--//Register C_DSN_ETHG_REG_CTRL_L / Bit Map:
constant C_DSN_ETHG_REG_CTRL_SFP_TX_DISABLE_BIT     : integer:=3; --//Выключение передатчика на SFP

constant C_DSN_ETHG_REG_CTRL_GTP_CLKIN_MUX_VLSB_BIT : integer:=8; --//Значение для перепрограм. мультиплексора CLKIN RocketIO ETH
constant C_DSN_ETHG_REG_CTRL_GTP_CLKIN_MUX_VMSB_BIT : integer:=10; --//
constant C_DSN_ETHG_REG_CTRL_GTP_SOUTH_MUX_VAL_BIT  : integer:=11; --//Значение для перепрограм. мультиплексора CLKSOUTH RocketIO ETH
constant C_DSN_ETHG_REG_CTRL_GTP_NORTH_MUX_VAL_BIT  : integer:=12; --//Значение для перепрограм. мультиплексора CLKNORTH RocketIO ETH
constant C_DSN_ETHG_REG_CTRL_GTP_CLKIN_MUX_CNG_BIT  : integer:=13; --//1- перепрограммирование мультиплексора CLKIN RocketIO ETH
constant C_DSN_ETHG_REG_CTRL_GTP_SOUTH_MUX_CNG_BIT  : integer:=14; --//1- перепрограммирование мультиплексора CLKSOUTH RocketIO ETH
constant C_DSN_ETHG_REG_CTRL_GTP_NORTH_MUX_CNG_BIT  : integer:=15; --//1- перепрограммирование мультиплексора CLKNORTH RocketIO ETH



--//--------------------------------------------------------------
--//Регистры модуля dsn_video_ctrl.vhd
--//--------------------------------------------------------------
constant C_DSN_VCTRL_REG_CTRL_L                     : integer:=16#000#;
--constant C_DSN_VCTRL_REG_CTRL_M                     : integer:=16#001#;
constant C_DSN_VCTRL_REG_TST0                       : integer:=16#002#;
constant C_DSN_VCTRL_REG_TST1                       : integer:=16#003#;
constant C_DSN_VCTRL_REG_PRM_DATA_LSB               : integer:=16#004#;
constant C_DSN_VCTRL_REG_PRM_DATA_MSB               : integer:=16#005#;
constant C_DSN_VCTRL_REG_MEM_TRN_LEN                : integer:=16#006#;


--//Bit Maps:
--//Register C_DSN_VCTRL_REG_CTRL / Bit Map:
constant C_DSN_VCTRL_REG_CTRL_CH_IDX_LSB_BIT        : integer:=0;
constant C_DSN_VCTRL_REG_CTRL_CH_IDX_MSB_BIT        : integer:=3;
constant C_DSN_VCTRL_REG_CTRL_PRM_IDX_LSB_BIT       : integer:=4;
constant C_DSN_VCTRL_REG_CTRL_PRM_IDX_MSB_BIT       : integer:=6;
constant C_DSN_VCTRL_REG_CTRL_SET_BIT               : integer:=7;
constant C_DSN_VCTRL_REG_CTRL_SET_IDLE_BIT          : integer:=8;
constant C_DSN_VCTRL_REG_CTRL_RAMCOE_ADDR_BIT       : integer:=9;
constant C_DSN_VCTRL_REG_CTRL_RAMCOE_DATA_BIT       : integer:=10;
constant C_DSN_VCTRL_REG_CTRL_RAMCOE_NUM_LSB_BIT    : integer:=11;
constant C_DSN_VCTRL_REG_CTRL_RAMCOE_NUM_MSB_BIT    : integer:=14;
constant C_DSN_VCTRL_REG_CTRL_LAST_BIT              : integer:=C_DSN_VCTRL_REG_CTRL_RAMCOE_NUM_MSB_BIT;

constant C_DSN_VCTRL_REG_CTRL_RAMCOE_SCALE_NUM      : integer:=0;
constant C_DSN_VCTRL_REG_CTRL_RAMCOE_P_COLR_NUM     : integer:=1;
constant C_DSN_VCTRL_REG_CTRL_RAMCOE_P_COLG_NUM     : integer:=2;
constant C_DSN_VCTRL_REG_CTRL_RAMCOE_P_COLB_NUM     : integer:=3;
constant C_DSN_VCTRL_REG_CTRL_RAMCOE_GAMMA_GRAY_NUM : integer:=4;
constant C_DSN_VCTRL_REG_CTRL_RAMCOE_GAMMA_COLR_NUM : integer:=5;
constant C_DSN_VCTRL_REG_CTRL_RAMCOE_GAMMA_COLG_NUM : integer:=6;
constant C_DSN_VCTRL_REG_CTRL_RAMCOE_GAMMA_COLB_NUM : integer:=7;

--//Режимы установок параметров:
constant C_DSN_VCTRL_PRM_MEM_ADDR_WR                : integer:=0;--//Базовый адрес буфера записи видео
constant C_DSN_VCTRL_PRM_MEM_ADDR_RD                : integer:=1;--//Базовый адрес буфера чтения видео
constant C_DSN_VCTRL_PRM_FR_ZONE_SKIP               : integer:=2;
constant C_DSN_VCTRL_PRM_FR_ZONE_ACTIVE             : integer:=3;
constant C_DSN_VCTRL_PRM_FR_OPTIONS                 : integer:=4;
--//Мах кол-во режимов установок параметров:
constant C_DSN_VCTRL_PRM_MAX_COUNT                  : integer:=4+1;--C_DSN_VCTRL_REG_CTRL_PRM_IDX_MSB_BIT-C_DSN_VCTRL_REG_CTRL_PRM_IDX_LSB_BIT+1;


--//Register VCTRL_REG_MEM_ADDR / Bit Map:
constant C_DSN_VCTRL_REG_MEM_ADR_OFFSET_LSB_BIT     : integer:=C_HREG_MEM_ADR_OFFSET_L_BIT;
constant C_DSN_VCTRL_REG_MEM_ADR_OFFSET_MSB_BIT     : integer:=C_HREG_MEM_ADR_OFFSET_M_BIT;
constant C_DSN_VCTRL_REG_MEM_ADR_BANK_LSB_BIT       : integer:=C_HREG_MEM_ADR_BANK_L_BIT;
constant C_DSN_VCTRL_REG_MEM_ADR_BANK_MSB_BIT       : integer:=C_HREG_MEM_ADR_BANK_M_BIT;
constant C_DSN_VCTRL_REG_MEM_LAST_BIT               : integer:=C_DSN_VCTRL_REG_MEM_ADR_BANK_MSB_BIT;

--//Как поделена память ОЗУ для записи/чтение видеоинформации:
--//                                                : integer:=0; --//Пиксели видеокадра(VLINE_LSB-1...0)
constant C_DSN_VCTRL_MEM_VLINE_LSB_BIT              : integer:=11;--//Строки видеокадра (MSB...LSB)
constant C_DSN_VCTRL_MEM_VLINE_MSB_BIT              : integer:=21;
constant C_DSN_VCTRL_MEM_VFRAME_LSB_BIT             : integer:=22;--//Номер кадра видео канала (MSB...LSB)
constant C_DSN_VCTRL_MEM_VFRAME_MSB_BIT             : integer:=23;--//
constant C_DSN_VCTRL_MEM_VCH_LSB_BIT                : integer:=24;--//Номер видео канала (MSB...LSB) (мах кол-во видео каналов=4)
constant C_DSN_VCTRL_MEM_VCH_MSB_BIT                : integer:=25;

--//Мах кол-во видеобуферов (кадры):
constant C_DSN_VCTRL_VBUF_MAX_COUNT                 : integer:=4;

--//Мах кол-во каналов видео: (необходимо учитывать C_DSN_VCTRL_MEM_VCH_xxx_BIT )
--constant C_DSN_VCTRL_VCH_COUNT                      : integer:=C_DSN_VCTRL_VCH_COUNT_USE;
constant C_DSN_VCTRL_VCH_MAX_COUNT                  : integer:=4;


--//Register C_DSN_VCTRL_REG_TST0 / Bit Map:
constant C_DSN_VCTRL_REG_TST0_DBG_TBUFRD_BIT        : integer:=0;--//Отладка модуля слежения - отображение содержимого RAM/TRACK/TBUF
constant C_DSN_VCTRL_REG_TST0_DBG_EBUFRD_BIT        : integer:=1;--//Отладка модуля слежения - отображение содержимого RAM/TRACK/EBUF
constant C_DSN_VCTRL_REG_TST0_DBG_SOBEL_BIT         : integer:=2;--//1/0 - Отладка модуля собела Выдача Grad/Video
constant C_DSN_VCTRL_REG_TST0_DBG_DIS_DEMCOLOR_BIT  : integer:=5;--//1/0 - Запретить работу модуля vcoldemosaic_main.vhd
constant C_DSN_VCTRL_REG_TST0_DBG_DCOUNT_BIT        : integer:=6;--//1 - Вместо данных строки вставляется счетчик
constant C_DSN_VCTRL_REG_TST0_DBG_PICTURE_BIT       : integer:=7;--//Запрещаю запись видео в ОЗУ + запрещаю инкрементацию счетчика vbuf,
                                                                 --//при бит(7)=1 - vbuf=0
constant C_DSN_VCTRL_REG_TST0_SKIPFR_CNT_CLR_BIT    : integer:=8;--//При 1 - происходит сброс счетчиков пропущеных кадров tst_vfrskip,
                                                                 --//При 0 - нет
constant C_DSN_VCTRL_REG_TST0_DBG_RDHOLD_BIT        : integer:=10;--//Эмуляция захвата видеобуфера модулем чтения
constant C_DSN_VCTRL_REG_TST0_DBG_TRCHOLD_BIT       : integer:=11;--//Эмуляция захвата видеобуфера модулем слежения
constant C_DSN_VCTRL_REG_TST0_LAST_BIT              : integer:=12;



--//--------------------------------------------------------------
--//Регистры модуля dsn_track_nik.vhd
--//--------------------------------------------------------------
constant C_DSN_TRCNIK_REG_IP0                       : integer:=16#000#;
constant C_DSN_TRCNIK_REG_IP1                       : integer:=16#001#;
constant C_DSN_TRCNIK_REG_IP2                       : integer:=16#002#;
constant C_DSN_TRCNIK_REG_IP3                       : integer:=16#003#;
constant C_DSN_TRCNIK_REG_IP4                       : integer:=16#004#;
constant C_DSN_TRCNIK_REG_IP5                       : integer:=16#005#;
constant C_DSN_TRCNIK_REG_IP6                       : integer:=16#006#;
constant C_DSN_TRCNIK_REG_IP7                       : integer:=16#007#;
constant C_DSN_TRCNIK_REG_OPT                       : integer:=16#008#;
constant C_DSN_TRCNIK_REG_MEM_RBUF_LSB              : integer:=16#009#;--//Базовый адрес буфера результата
constant C_DSN_TRCNIK_REG_MEM_RBUF_MSB              : integer:=16#00A#;

constant C_DSN_TRCNIK_REG_CTRL_L                    : integer:=16#010#;
--constant C_DSN_TRCNIK_REG_CTRL_M                    : integer:=16#011#;
constant C_DSN_TRCNIK_REG_MEM_TRN_LEN               : integer:=16#012#;
constant C_DSN_TRCNIK_REG_TST0                      : integer:=16#013#;
--constant C_DSN_TRCNIK_REG_TST1                      : integer:=16#014#;


--//Каналы слежения = кол-ву видео каналов
--//ВАЖНО: пока сделано жестко для 1-го канала
constant C_DSN_TRCNIK_CH_COUNT                      : integer:=1;--//Текщее кол-во
constant C_DSN_TRCNIK_CH_MAX_COUNT                  : integer:=3;--//Мах кол-во

--/Интервальные пороги
constant C_DSN_TRCNIK_IP_COUNT                      : integer:=8;--//Текущее кол-во
constant C_DSN_TRCNIK_IP_MAX_COUNT                  : integer:=8;--//Мах кол-во


--//Register C_DSN_TRCNIK_REG_MEM_ADDR / Bit Map:
constant C_DSN_TRCNIK_REG_MEM_ADR_OFFSET_LSB_BIT    : integer:=C_HREG_MEM_ADR_OFFSET_L_BIT;
constant C_DSN_TRCNIK_REG_MEM_ADR_OFFSET_MSB_BIT    : integer:=C_HREG_MEM_ADR_OFFSET_M_BIT;
constant C_DSN_TRCNIK_REG_MEM_ADR_BANK_LSB_BIT      : integer:=C_HREG_MEM_ADR_BANK_L_BIT;
constant C_DSN_TRCNIK_REG_MEM_ADR_BANK_MSB_BIT      : integer:=C_HREG_MEM_ADR_BANK_M_BIT;
constant C_DSN_TRCNIK_REG_MEM_LAST_BIT              : integer:=C_DSN_TRCNIK_REG_MEM_ADR_BANK_MSB_BIT;


--//Bit Maps:
--//Register C_DSN_TRCNIK_REG_CTRL / Bit Map:
constant C_DSN_TRCNIK_REG_CTRL_CH_LSB_BIT           : integer:=0;
constant C_DSN_TRCNIK_REG_CTRL_CH_MSB_BIT           : integer:=3;
constant C_DSN_TRCNIK_REG_CTRL_SET_BIT              : integer:=7;
constant C_DSN_TRCNIK_REG_CTRL_WORK_BIT             : integer:=9;
constant C_DSN_TRCNIK_REG_CTRL_LAST_BIT             : integer:=C_DSN_TRCNIK_REG_CTRL_WORK_BIT;


--//Register C_DSN_TRCNIK_REG_OPT / Bit Map:
constant C_DSN_TRCNIK_REG_OPT_SOBEL_CTRL_MULT_BIT   : integer:=0;--//1/0 - точная грубая апроксимация формуля (dx^2 + dy^2)^0.5
constant C_DSN_TRCNIK_REG_OPT_SOBEL_CTRL_DIV_BIT    : integer:=1;--//1/0 - dx/2 и dy/2 /нет делений
constant C_DSN_TRCNIK_REG_OPT_DBG_IP_LSB_BIT        : integer:=2;--//Отладка работы Пороговых интревалов (Рабочее кол-во ИП)
constant C_DSN_TRCNIK_REG_OPT_DBG_IP_MSB_BIT        : integer:=5;--//
constant C_DSN_TRCNIK_REG_OPT_ANG_LSB_BIT           : integer:=6;--//Выбор вариантов расчета направления градиента яркости
constant C_DSN_TRCNIK_REG_OPT_ANG_MSB_BIT           : integer:=7;--//(пока реализовано 2-а, мах 4)
constant C_DSN_TRCNIK_REG_OPT_LAST_BIT              : integer:=C_DSN_TRCNIK_REG_OPT_ANG_MSB_BIT;


--//Register C_DSN_TRCNIK_REG_TST0 / Bit Map:
constant C_DSN_TRCNIK_REG_TST0_COLOR_DIS_BIT        : integer:=3;--//1/0 - Запрерить/разрешить работу модуля vcoldemosaic_main.vhd в ядре модуля слежения
constant C_DSN_TRCNIK_REG_TST0_COLOR_DBG_BIT        : integer:=4;--//отладка модуля vcoldemosaic_main.vhd 0/1 - выкл/вкл
constant C_DSN_TRCNKI_REG_TST0_LAST_BIT             : integer:=C_DSN_TRCNIK_REG_TST0_COLOR_DBG_BIT;

--//--------------------------------------------------------------
--//Регистры модуля dsn_testing.vhd
--//--------------------------------------------------------------
constant C_DSN_TSTING_REG_CTRL_L                    : integer:=16#000#;
constant C_DSN_TSTING_REG_CTRL_M                    : integer:=16#001#;
constant C_DSN_TSTING_REG_TST0                      : integer:=16#002#;
constant C_DSN_TSTING_REG_T05_US                    : integer:=16#003#;--
constant C_DSN_TSTING_REG_PIX                       : integer:=16#004#;
constant C_DSN_TSTING_REG_ROW                       : integer:=16#005#;
--constant C_DSN_TSTING_REG_FRAME_SIZE_LSB            : integer:=16#006#;
--constant C_DSN_TSTING_REG_FRAME_SIZE_MSB            : integer:=16#007#;
--constant C_DSN_TSTING_REG_PKTLEN                    : integer:=16#008#;
constant C_DSN_TSTING_REG_ROW_SEND_TIME_DLY         : integer:=16#009#;
constant C_DSN_TSTING_REG_FR_SEND_TIME_DLY          : integer:=16#00A#;

constant C_DSN_TSTING_REG_TXBUF_FULL_CNT            : integer:=16#00B#;

constant C_DSN_TSTING_REG_COLOR_LSB                 : integer:=16#00C#;
constant C_DSN_TSTING_REG_COLOR_MSB                 : integer:=16#00D#;

--//Bit Maps:
--//Register C_DSN_TSTING_REG_CTRL / Bit Map:
constant C_DSN_TSTING_REG_CTRL_MODE_LSB_BIT         : integer:=0;
constant C_DSN_TSTING_REG_CTRL_MODE_MSB_BIT         : integer:=3;
constant C_DSN_TSTING_REG_CTRL_START_BIT            : integer:=4;
constant C_DSN_TSTING_REG_CTRL_FRTXD_2DW_CNT_BIT    : integer:=5;
constant C_DSN_TSTING_REG_CTRL_FRAME_GRAY_BIT       : integer:=6;--//1Pix=8bit
constant C_DSN_TSTING_REG_CTRL_FRAME_SET_MNL_BIT    : integer:=7;
constant C_DSN_TSTING_REG_CTRL_FRAME_CH_AUTO_BIT    : integer:=8;
constant C_DSN_TSTING_REG_CTRL_FRAME_CH_LSB_BIT     : integer:=9;
constant C_DSN_TSTING_REG_CTRL_FRAME_CH_MSB_BIT     : integer:=10;
constant C_DSN_TSTING_REG_CTRL_FRAME_DIAGONAL_BIT   : integer:=11;
constant C_DSN_TSTING_REG_CTRL_FRAME_TSTDATA_2_BIT  : integer:=12;
--constant C_DSN_TSTING_REG_CTRL_FRAME_START_SYNC_BIT: integer:=13;

constant C_DSN_TSTING_REG_CTRLM_FRAME_MOVE_LSB_BIT  : integer:=0;
constant C_DSN_TSTING_REG_CTRLM_FRAME_MOVE_MSB_BIT  : integer:=6;

--//Поле C_DSN_TSTING_REG_CTRL_MODE:
--//Код - 0x00 - ниего не выполнять
constant C_DSN_TSTING_MODE_SEND_TXD_STREAM          : integer:=1;
constant C_DSN_TSTING_MODE_SEND_TXD_SINGL           : integer:=2;



end prj_def;


package body prj_def is

end prj_def;

