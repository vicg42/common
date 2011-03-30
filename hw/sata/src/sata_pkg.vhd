------------------------------------------------------------------------
-- Company     : Linkos
-- Engineer    : Golovachenko Victor
--
-- Create Date : 07.02.2011 10:47:04
-- Module Name : sata_pkg
--
-- Description : Константы/Типы данных/
--               используемые в проекте SATA
--
-- Revision:
-- Revision 0.01 - File Created
--
-------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_arith.all;

use work.vicg_common_pkg.all;

package sata_pkg is

---------------------------------------------------------
--Типы
---------------------------------------------------------
type TInt_SataArray02 is array (0 to 1) of integer;
type TInt_SataArray03 is array (0 to 2) of integer;
type TInt_SataArray04 is array (0 to 3) of integer;
type TInt_SataArray05 is array (0 to 4) of integer;
type TInt_SataArray06 is array (0 to 5) of integer;

---------------------------------------------------------
--Константы
---------------------------------------------------------
constant C_GTP_CH_COUNT_MAX      : integer:=2;
constant C_DUAL_GTP_COUNT_MAX    : integer:=3;
constant C_SATA_COUNT_MAX        : integer:=C_DUAL_GTP_COUNT_MAX*C_GTP_CH_COUNT_MAX;

--//Кол-во модулей sata_host.vhd в зависимости от параметра:generic:G_HDD_COUNT (модуля sata_dsn.vhd)
constant C_SATA_HOST_MODULE_COUNT  : TInt_SataArray06:=(1,1,2,2,3,3);
--//Кол-во используемх каналов sata в модуле sata_host.vhd с определенным индексом
--//(G_SATA_MODULE_xx_СH_COUNT - где хх - индекс модуля sata_host.vhd)
--//в зависимости от параметра:generic:G_HDD_COUNT (модуля sata_dsn.vhd)
constant C_SATA_HOST_MODULE_0_CH_COUNT : TInt_SataArray06:=(1,2,2,2,2,2);
constant C_SATA_HOST_MODULE_1_CH_COUNT : TInt_SataArray06:=(0,0,1,2,2,2);
constant C_SATA_HOST_MODULE_2_CH_COUNT : TInt_SataArray06:=(0,0,0,0,1,2);



--//-------------------------------------------------
--//User Application Layer
--//-------------------------------------------------
--//Размер командного пакета в WORD
constant C_USRAPP_CMDPKT_SIZE_WORD        : integer:=10#07#;

--//User CMD Pkt :
--//Поле UsrCtrl/Map:
constant C_CMDPKT_USRHDD_NUM_L_BIT        : integer:=0;
constant C_CMDPKT_USRHDD_NUM_M_BIT        : integer:=7;
constant C_CMDPKT_USRMODE_SW_BIT          : integer:=8;
constant C_CMDPKT_USRMODE_HW_BIT          : integer:=9;
constant C_CMDPKT_USRMODE_TSTR_BIT        : integer:=10;
constant C_CMDPKT_USRMODE_TSTW_BIT        : integer:=11;
constant C_CMDPKT_USRCMD_L_BIT            : integer:=12;
constant C_CMDPKT_USRCMD_M_BIT            : integer:=14;

--//C_CMDPKT_USRCMD/Map:
constant C_USRCMD_ATACONTROL              : integer:=0;
constant C_USRCMD_ATACOMMAND              : integer:=1;
constant C_USRCMD_FPDMA_W                 : integer:=2;
constant C_USRCMD_FPDMA_R                 : integer:=3;
constant C_USRCMD_SET_SATA1               : integer:=4;
constant C_USRCMD_SET_SATA2               : integer:=5;
constant C_USRCMD_COUNT                   : integer:=C_USRCMD_SET_SATA2+1;


--//-------------------------------------------------
--//Application Layer
--//-------------------------------------------------
--//Размер командного пакета в WORD
constant C_TRLR_CMDPKT_SIZE              : integer:=C_USRAPP_CMDPKT_SIZE_WORD-1;

--//Регистр C_REG_ATA_COMMAND/ Commad Map:
constant C_ATA_CMD_IDENTIFY_DEV          : integer:=16#EC#;
constant C_ATA_CMD_IDENTIFY_PACKET_DEV   : integer:=16#A1#;
constant C_ATA_CMD_NOP                   : integer:=16#00#;
constant C_ATA_CMD_WRITE_SECTORS_EXT     : integer:=16#34#;--//PIO Write
constant C_ATA_CMD_READ_SECTORS_EXT      : integer:=16#24#;--//PIO Read
constant C_ATA_CMD_WRITE_DMA_EXT         : integer:=16#35#;--//DMA Write
constant C_ATA_CMD_READ_DMA_EXT          : integer:=16#25#;--//DMA Read

--//Регистр C_REG_ATA_STATUS/Bit Map:
constant C_REG_ATA_STATUS_BUSY_BIT       : integer:=7;--уст-во занято
constant C_REG_ATA_STATUS_DRDY_BIT       : integer:=6;--уст-во готово к принятию комманд
constant C_REG_ATA_STATUS_DRQ_BIT        : integer:=3;--уст-во готово к обмену данными
constant C_REG_ATA_STATUS_ERR_BIT        : integer:=0;--ошибка

--//Регистр C_REG_ATA_DEV_CONTROL/Bit Map:
constant C_REG_ATA_DEV_CONTROL_nIEN_BIT  : integer:=1;--маскирование сигнала переывания(0/1 - разрешено/запрещено)
constant C_REG_ATA_DEV_CONTROL_SRST_BIT  : integer:=2;--
constant C_IRQ_ON                        : std_logic:='0';
constant C_IRQ_OFF                       : std_logic:='1';

--//Регистр C_REG_ATA_DEVICE/Bit Map:
constant C_REG_ATA_DEVICE_LBA_BIT        : integer:=6;--Режим адресации. 1/0 - LBA/CHS (линейная/трехмерная). В нашем случае применяем только LBA!!!

--//Регистр C_REG_ATA_ERROR/Bit Map:
constant C_REG_ATA_ERROR_ABRT_BIT        : integer:=2;--command aborted


--//Register / Adress Map:
constant C_ALREG_USRCTRL                  : integer:=16#000000#;
constant C_ALREG_FEATURE                  : integer:=16#000001#;
constant C_ALREG_LBA_LOW                  : integer:=16#000002#;
constant C_ALREG_LBA_MID                  : integer:=16#000003#;
constant C_ALREG_LBA_HIGH                 : integer:=16#000004#;
constant C_ALREG_SECTOR_COUNT             : integer:=16#000005#;
constant C_ALREG_COMMAND                  : integer:=16#000006#;-- + C_ALREG_DEV_CONTROL
constant C_ALREG_DEVICE                   : integer:=16#000007#;


--//Управление/Map:
constant C_ACTRL_ERR_CLR_BIT              : integer:=0;--//Сброс ошибок SError
constant C_ALCTRL_LAST_BIT                : integer:=C_ACTRL_ERR_CLR_BIT;

--//Статусы/Map:
--//Поле - SStatus/Map:
--//Более подробно см. d1532v3r4b ATA-ATAPI-7.pdf п.п.19.2.1
constant C_ASSTAT_DET_BIT_L              : integer:=0;
constant C_ASSTAT_DET_BIT_M              : integer:=3;
constant C_ASSTAT_SPD_BIT_L              : integer:=4;
constant C_ASSTAT_SPD_BIT_M              : integer:=7;
constant C_ASSTAT_IPM_BIT_L              : integer:=8;
constant C_ASSTAT_IPM_BIT_M              : integer:=11;
constant C_ASSTAT_RESERV_BIT             : integer:=12;
constant C_ALSSTAT_LAST_BIT              : integer:=C_ASSTAT_RESERV_BIT;

--//SStatus/DET/Map:
constant C_ASSTAT_DET_NODEV              : integer:=0;
constant C_ASSTAT_DET_DEVICE             : integer:=1;
constant C_ASSTAT_DET_LINK_ESTABLISH     : integer:=3;


--//Поле - SError/Map:
--//Более подробно см. d1532v3r4b ATA-ATAPI-7.pdf п.п.19.2.2
constant C_ASERR_I_ERR_BIT               : integer:=0;
--constant C_ASERR_M_ERR_BIT               : integer:=1;
--constant C_ASERR_T_ERR_BIT               : integer:=8;
constant C_ASERR_C_ERR_BIT               : integer:=9;
constant C_ASERR_P_ERR_BIT               : integer:=10;
--constant C_ASERR_E_ERR_BIT               : integer:=11;

constant C_ASERR_N_DIAG_BIT              : integer:=16;
constant C_ASERR_I_DIAG_BIT              : integer:=17;
constant C_ASERR_W_DIAG_BIT              : integer:=18;
constant C_ASERR_B_DIAG_BIT              : integer:=19;
constant C_ASERR_D_DIAG_BIT              : integer:=20;
constant C_ASERR_C_DIAG_BIT              : integer:=21;
constant C_ASERR_H_DIAG_BIT              : integer:=22;
constant C_ASERR_S_DIAG_BIT              : integer:=23;
constant C_ASERR_T_DIAG_BIT              : integer:=24;
constant C_ASERR_F_DIAG_BIT              : integer:=25;

constant C_ASERR_RESERV_BIT              : integer:=31;
constant C_ALSERR_LAST_BIT               : integer:=C_ASERR_RESERV_BIT;

--//Поле - User/Map:
constant C_AUSER_BUSY_BIT                : integer:=0;
constant C_AUSER_RESERV_BIT              : integer:=1;
constant C_ALUSER_LAST_BIT               : integer:=C_AUSER_RESERV_BIT;


--//-------------------------------------------------
--//Transport Layer
--//-------------------------------------------------
--//Управление/Map:
constant C_TCTRL_DMASETUP_WR_BIT         : integer:=16#00#;
constant C_TCTRL_RCOMMAND_WR_BIT         : integer:=16#01#;
constant C_TCTRL_RCONTROL_WR_BIT         : integer:=16#02#;
constant C_TLCTRL_LAST_BIT               : integer:=C_TCTRL_RCONTROL_WR_BIT;

--//Статусы/Map:
constant C_TSTAT_RxFISTYPE_ERR_BIT       : integer:=0;--//Transport Layer не смог определить тип принятого пакета
constant C_TSTAT_RxFISLEN_ERR_BIT        : integer:=1;--//
constant C_TSTAT_TxERR_CRC_REPEAT_BIT    : integer:=2;--//Было сделано несколько попыток отправить FIS_H2D, но каждый раз получал от Link Layer C_LSTAT_TxERR_CRC
constant C_TSTAT_TxFISHOST2DEV_BIT       : integer:=3;--//Сигнализируем что идет передача FIS_HOST2DEV
constant C_TLSTAT_LAST_BIT               : integer:=C_TSTAT_TxFISHOST2DEV_BIT;

--//FIS Type:
constant C_FIS_REG_HOST2DEV              : integer:=16#27#;
constant C_FIS_REG_DEV2HOST              : integer:=16#34#;
constant C_FIS_DMA_ACTIVATE              : integer:=16#39#;
constant C_FIS_DMASETUP                  : integer:=16#41#;
constant C_FIS_DATA                      : integer:=16#46#;
constant C_FIS_BIST_ACTIVATE             : integer:=16#58#;
constant C_FIS_PIOSETUP                  : integer:=16#5F#;
constant C_FIS_SET_DEV_BITS              : integer:=16#A1#;
constant C_FIS_RESERV0                   : integer:=16#A6#;
constant C_FIS_RESERV1                   : integer:=16#B8#;
constant C_FIS_RESERV2                   : integer:=16#BF#;
constant C_FIS_VENDOR_SPEC0              : integer:=16#C7#;
constant C_FIS_VENDOR_SPEC1              : integer:=16#D4#;
constant C_FIS_RESERV3                   : integer:=16#D9#;

--//FIS Bit Map:
constant C_FIS_DIR_BIT                   : integer:=16#05#;
constant C_FIS_INT_BIT                   : integer:=16#06#;
constant C_FIS_AUTO_ACTIVATE_BIT         : integer:=16#07#;
constant C_DIR_H2D                       : std_logic:='0';
constant C_DIR_D2H                       : std_logic:='1';

--//FIS Length:
constant C_FIS_REG_HOST2DEV_DWSIZE       : integer:=5;
constant C_FIS_REG_DEV2HOST_DWSIZE       : integer:=5;
constant C_FIS_DMA_ACTIVATE_DWSIZE       : integer:=1;
constant C_FIS_DMASETUP_DWSIZE           : integer:=7;
constant C_FIS_BIST_ACTIVATE_DWSIZE      : integer:=3;
constant C_FIS_PIOSETUP_DWSIZE           : integer:=5;
constant C_FIS_SET_DEV_BITS_DWSIZE       : integer:=2;


--//-------------------------------------------------
--//Link Layer
--//-------------------------------------------------
--//Управление/Map:
constant C_LCTRL_TxSTART_BIT              : integer:=16#00#;--//Transport Layer готов начать передачу данных
constant C_LCTRL_TRN_ESCAPE_BIT           : integer:=16#01#;--//Transport Layer хочет оборвать текущую транзакцию
constant C_LCTRL_TL_CHECK_ERR_BIT         : integer:=16#02#;--//Transport Layer сигнализирует что распознал ошибки при проверке принимаемых данных: FITYPE_ERR, FISLEN_ERR
constant C_LCTRL_TL_CHECK_DONE_BIT        : integer:=16#03#;--//Transport Layer завершил проверку принимаемых данных
--constant C_LCTRL_PARTIAL_BIT             : integer:=16#04#;
--constant C_LCTRL_SLUMBER_BIT             : integer:=16#05#;
constant C_LLCTRL_LAST_BIT                 : integer:=C_LCTRL_TL_CHECK_DONE_BIT;

--//Статусы/Map:
constant C_LSTAT_RxOK                     : integer:=0;--//Прием пакета - ОК
constant C_LSTAT_RxSTART                  : integer:=1;--//Прием пакета - Link Layer обнаружил SOF - начал прием данных
constant C_LSTAT_RxERR_CRC                : integer:=2;--//Прием пакета - ошибка: CRC
constant C_LSTAT_RxERR_IDLE               : integer:=3;--//Прием пакета - ошибка: Принял примитив которого не ожидал
constant C_LSTAT_RxERR_ABORT              : integer:=4;--//Прием пакета - ошибка: Принял примитив SYNC
constant C_LSTAT_TxOK                     : integer:=5;--//Отправка пакета - ОК
constant C_LSTAT_TxDMAT                   : integer:=6;--//Отправка пакета - Принял примитив DMA - Terminate
constant C_LSTAT_TxERR_CRC                : integer:=7;--//Отправка пакета - ошибка: CRC
constant C_LSTAT_TxERR_IDLE               : integer:=8;--//Отправка пакета - ошибка: Принял примитив которого не ожидал
constant C_LSTAT_TxERR_ABORT              : integer:=9;--//Отправка пакета - ошибка: Принял примитив SYNC
constant C_LLSTAT_LAST_BIT                : integer:=C_LSTAT_TxERR_ABORT;

--//Задержка возврашения к передаче данных их состояния S_LT_SendHold автомата управления Link Layer
constant C_LL_TXDATA_RETURN_TMR          : integer:=20;


--//-------------------------------------------------
--//PHY Layer
--//-------------------------------------------------
--//PHY Layer /Reciver
--//Статусы/Map:
constant C_PRxSTAT_ERR_DISP_BIT          : integer:=0;--//Ошибка - received with a disparity error.
constant C_PRxSTAT_ERR_NOTINTABLE_BIT    : integer:=1;--//Ошибка - indicates that RXDATA is the result of an illegal 8B/10B code
constant C_PRxSTAT_LAST_BIT              : integer:=C_PRxSTAT_ERR_NOTINTABLE_BIT;

--//Управление/Map:
constant C_PCTRL_SPD_BIT_L               : integer:=0;
constant C_PCTRL_SPD_BIT_M               : integer:=1;
constant C_PLCTRL_LAST_BIT               : integer:=C_PCTRL_SPD_BIT_M;

--//Статусы/Map:
constant C_PSTAT_DET_DEV_ON_BIT          : integer:=C_PRxSTAT_LAST_BIT + 1;--//Детектирование: 0/1 - Устройство не обнаружено/обнаружено но соединение не установлено!!
constant C_PSTAT_DET_ESTABLISH_ON_BIT    : integer:=C_PRxSTAT_LAST_BIT + 2;--//Детектирование: 0/1 - Соединение с устройством не установлено/установлено (можно работать)
constant C_PSTAT_SPD_BIT_L               : integer:=C_PRxSTAT_LAST_BIT + 3;--//Cкорость соединения: "00"/"01"/"10" -  не согласована/Gen1/Gen2
constant C_PSTAT_SPD_BIT_M               : integer:=C_PRxSTAT_LAST_BIT + 4;
constant C_PSTAT_COMWAKE_RCV_BIT         : integer:=C_PRxSTAT_LAST_BIT + 5;--//0/1 - Сигнал COMWAKE от устойства не принят/принят
constant C_PLSTAT_LAST_BIT               : integer:=C_PSTAT_COMWAKE_RCV_BIT;


--//sata_player_tx.vhd
--//Отправка примитива ALIGN
constant C_ALIGN_TMR                     : integer:=256;--//Таймер отправки примимтива ALIGN (только четные значения!!!)
constant C_ALIGN_BURST                   : integer:=2;  --//Кол-во отправляемых примитивов за один раз (только четные значения!!!)

--//Размер сеткора в BYTE
constant C_SECTOR_SIZE_BYTE              : integer:=512;
--max кол-во Dword в FISDATA между SOF и EOF, исключая FISTYPE и CRC
constant C_FR_DWORD_COUNT_MAX            : integer:=2048;

--//sata_player_oob.vhd
constant C_OOB_TIMEOUT                   : integer:=10#66000#; --=880us на 75MHz

--//Версии спецификации SATA
--//ВАЖНО: изменив эти константы, нужно будет руками править файлы sata_spd_ctrl.vhd sata_host.vhd
constant C_FSATA_GEN1 : integer:=0;
constant C_FSATA_GEN2 : integer:=1;
constant C_FSATA_GEN_COUNT : integer:=2;


--тип символа в 8b/10b
constant C_CHAR_K: std_logic:='1';
constant C_CHAR_D: std_logic:='0';

--коды 8b/10b
constant C_K28_5 : std_logic_vector(7 downto 0):=CONV_STD_LOGIC_VECTOR(16#BC#, 8);
constant C_K28_3 : std_logic_vector(7 downto 0):=CONV_STD_LOGIC_VECTOR(16#7C#, 8);

constant C_D10_2 : std_logic_vector(7 downto 0):=CONV_STD_LOGIC_VECTOR(16#4A#, 8);
constant C_D10_5 : std_logic_vector(7 downto 0):=CONV_STD_LOGIC_VECTOR(16#AA#, 8);
constant C_D21_1 : std_logic_vector(7 downto 0):=CONV_STD_LOGIC_VECTOR(16#35#, 8);
constant C_D21_2 : std_logic_vector(7 downto 0):=CONV_STD_LOGIC_VECTOR(16#55#, 8);
constant C_D21_3 : std_logic_vector(7 downto 0):=CONV_STD_LOGIC_VECTOR(16#75#, 8);
constant C_D21_4 : std_logic_vector(7 downto 0):=CONV_STD_LOGIC_VECTOR(16#95#, 8);
constant C_D21_5 : std_logic_vector(7 downto 0):=CONV_STD_LOGIC_VECTOR(16#B5#, 8);
constant C_D21_6 : std_logic_vector(7 downto 0):=CONV_STD_LOGIC_VECTOR(16#D5#, 8);
constant C_D21_7 : std_logic_vector(7 downto 0):=CONV_STD_LOGIC_VECTOR(16#F5#, 8);
constant C_D22_1 : std_logic_vector(7 downto 0):=CONV_STD_LOGIC_VECTOR(16#36#, 8);
constant C_D22_2 : std_logic_vector(7 downto 0):=CONV_STD_LOGIC_VECTOR(16#56#, 8);
constant C_D23_0 : std_logic_vector(7 downto 0):=CONV_STD_LOGIC_VECTOR(16#17#, 8);
constant C_D23_1 : std_logic_vector(7 downto 0):=CONV_STD_LOGIC_VECTOR(16#37#, 8);
constant C_D23_2 : std_logic_vector(7 downto 0):=CONV_STD_LOGIC_VECTOR(16#57#, 8);
constant C_D24_2 : std_logic_vector(7 downto 0):=CONV_STD_LOGIC_VECTOR(16#58#, 8);
constant C_D25_4 : std_logic_vector(7 downto 0):=CONV_STD_LOGIC_VECTOR(16#99#, 8);
constant C_D27_3 : std_logic_vector(7 downto 0):=CONV_STD_LOGIC_VECTOR(16#7B#, 8);

--примитивы SATA
constant C_PDAT_ALIGN  : std_logic_vector(31 downto 0):=C_D27_3&C_D10_2&C_D10_2&C_K28_5;
constant C_PDAT_SOF    : std_logic_vector(31 downto 0):=C_D23_1&C_D23_1&C_D21_5&C_K28_3;
constant C_PDAT_EOF    : std_logic_vector(31 downto 0):=C_D21_6&C_D21_6&C_D21_5&C_K28_3;
constant C_PDAT_DMAT   : std_logic_vector(31 downto 0):=C_D22_1&C_D22_1&C_D21_5&C_K28_3;
constant C_PDAT_CONT   : std_logic_vector(31 downto 0):=C_D25_4&C_D25_4&C_D10_5&C_K28_3;
constant C_PDAT_SYNC   : std_logic_vector(31 downto 0):=C_D21_5&C_D21_5&C_D21_4&C_K28_3;
constant C_PDAT_HOLD   : std_logic_vector(31 downto 0):=C_D21_6&C_D21_6&C_D10_5&C_K28_3;
constant C_PDAT_HOLDA  : std_logic_vector(31 downto 0):=C_D21_4&C_D21_4&C_D10_5&C_K28_3;
constant C_PDAT_X_RDY  : std_logic_vector(31 downto 0):=C_D23_2&C_D23_2&C_D21_5&C_K28_3;
constant C_PDAT_R_RDY  : std_logic_vector(31 downto 0):=C_D10_2&C_D10_2&C_D21_4&C_K28_3;
constant C_PDAT_R_IP   : std_logic_vector(31 downto 0):=C_D21_2&C_D21_2&C_D21_5&C_K28_3;
constant C_PDAT_R_OK   : std_logic_vector(31 downto 0):=C_D21_1&C_D21_1&C_D21_5&C_K28_3;
constant C_PDAT_R_ERR  : std_logic_vector(31 downto 0):=C_D22_2&C_D22_2&C_D21_5&C_K28_3;
constant C_PDAT_WTRM   : std_logic_vector(31 downto 0):=C_D24_2&C_D24_2&C_D21_5&C_K28_3;
constant C_PDAT_PMREQ_P: std_logic_vector(31 downto 0):=C_D23_0&C_D23_0&C_D21_5&C_K28_3;
constant C_PDAT_PMREQ_S: std_logic_vector(31 downto 0):=C_D21_3&C_D21_3&C_D21_4&C_K28_3;
constant C_PDAT_PMACK  : std_logic_vector(31 downto 0):=C_D21_4&C_D21_4&C_D21_4&C_K28_3;
constant C_PDAT_PMNAK  : std_logic_vector(31 downto 0):=C_D21_7&C_D21_7&C_D21_4&C_K28_3;

constant C_PDAT_TPRM   : std_logic_vector(3 downto 0):=C_CHAR_D&C_CHAR_D&C_CHAR_D&C_CHAR_K;
constant C_PDAT_TDATA  : std_logic_vector(3 downto 0):=C_CHAR_D&C_CHAR_D&C_CHAR_D&C_CHAR_D;


--//Номера примитивов
--//Модуль приема --- это номер бита на порту p_out_rxtype
--//Модуль передачи - это номер примитивов
constant C_TALIGN   : integer:=0;
constant C_TSYNC    : integer:=1;
constant C_TSOF     : integer:=2;
constant C_TEOF     : integer:=3;
constant C_THOLDA   : integer:=4;
constant C_THOLD    : integer:=5;
constant C_TCONT    : integer:=6;
constant C_TDMAT    : integer:=7;
constant C_TX_RDY   : integer:=8;
constant C_TR_RDY   : integer:=9;
constant C_TR_IP    : integer:=10;
constant C_TR_OK    : integer:=11;
constant C_TR_ERR   : integer:=12;
constant C_TWTRM    : integer:=13;
constant C_TPMREQ_P : integer:=14;
constant C_TPMREQ_S : integer:=15;
constant C_TPMACK   : integer:=16;
constant C_TPMNAK   : integer:=17;
constant C_TDATA_EN : integer:=18;--//Данные
constant C_TD10_2   : integer:=19;
constant C_TNONE    : integer:=20;


---------------------------------------------------------
--Типы
---------------------------------------------------------
type TBus32_Array4 is array (0 to 3) of std_logic_vector(31 downto 0);

type TBus02_GtpCh is array (0 to C_GTP_CH_COUNT_MAX-1) of std_logic_vector (1 downto 0);
type TBus03_GtpCh is array (0 to C_GTP_CH_COUNT_MAX-1) of std_logic_vector (2 downto 0);
type TBus04_GtpCh is array (0 to C_GTP_CH_COUNT_MAX-1) of std_logic_vector (3 downto 0);
type TBus05_GtpCh is array (0 to C_GTP_CH_COUNT_MAX-1) of std_logic_vector (4 downto 0);
type TBus06_GtpCh is array (0 to C_GTP_CH_COUNT_MAX-1) of std_logic_vector (5 downto 0);
type TBus07_GtpCh is array (0 to C_GTP_CH_COUNT_MAX-1) of std_logic_vector (6 downto 0);
type TBus08_GtpCh is array (0 to C_GTP_CH_COUNT_MAX-1) of std_logic_vector (7 downto 0);
type TBus09_GtpCh is array (0 to C_GTP_CH_COUNT_MAX-1) of std_logic_vector (8 downto 0);
type TBus10_GtpCh is array (0 to C_GTP_CH_COUNT_MAX-1) of std_logic_vector (9 downto 0);
type TBus11_GtpCh is array (0 to C_GTP_CH_COUNT_MAX-1) of std_logic_vector (10 downto 0);
type TBus16_GtpCh is array (0 to C_GTP_CH_COUNT_MAX-1) of std_logic_vector (15 downto 0);
type TBus19_GtpCh is array (0 to C_GTP_CH_COUNT_MAX-1) of std_logic_vector (18 downto 0);
type TBus21_GtpCh is array (0 to C_GTP_CH_COUNT_MAX-1) of std_logic_vector (20 downto 0);
type TBus32_GtpCh is array (0 to C_GTP_CH_COUNT_MAX-1) of std_logic_vector (31 downto 0);
type TBus48_GtpCh is array (0 to C_GTP_CH_COUNT_MAX-1) of std_logic_vector (47 downto 0);

type TBus01_GtpDualCount is array (0 to C_DUAL_GTP_COUNT_MAX-1) of std_logic_vector (0 downto 0);
type TBus02_GtpDualCount is array (0 to C_DUAL_GTP_COUNT_MAX-1) of std_logic_vector (1 downto 0);
type TBus04_GtpDualCount is array (0 to C_DUAL_GTP_COUNT_MAX-1) of std_logic_vector (3 downto 0);
type TBus06_GtpDualCount is array (0 to C_DUAL_GTP_COUNT_MAX-1) of std_logic_vector (5 downto 0);
type TBus08_GtpDualCount is array (0 to C_DUAL_GTP_COUNT_MAX-1) of std_logic_vector (7 downto 0);
type TBus16_GtpDualCount is array (0 to C_DUAL_GTP_COUNT_MAX-1) of std_logic_vector (15 downto 0);
type TBus32_GtpDualCount is array (0 to C_DUAL_GTP_COUNT_MAX-1) of std_logic_vector (31 downto 0);
type TBus36_GtpDualCount is array (0 to C_DUAL_GTP_COUNT_MAX-1) of std_logic_vector (35 downto 0);
type TBus48_GtpDualCount is array (0 to C_DUAL_GTP_COUNT_MAX-1) of std_logic_vector (47 downto 0);

type TBus16_GtpDualCountGtpCh  is array (0 to C_DUAL_GTP_COUNT_MAX-1) of TBus16_GtpCh;
type TBus32_GtpDualCountGtpCh  is array (0 to C_DUAL_GTP_COUNT_MAX-1) of TBus32_GtpCh;
type TBus48_GtpDualCountGtpCh  is array (0 to C_DUAL_GTP_COUNT_MAX-1) of TBus48_GtpCh;

type TBus2_SataCount  is array (0 to C_SATA_COUNT_MAX-1) of std_logic_vector(1 downto 0);
type TBus3_SataCount  is array (0 to C_SATA_COUNT_MAX-1) of std_logic_vector(2 downto 0);
type TBus4_SataCount  is array (0 to C_SATA_COUNT_MAX-1) of std_logic_vector(3 downto 0);
type TBus8_SataCount  is array (0 to C_SATA_COUNT_MAX-1) of std_logic_vector(7 downto 0);
type TBus16_SataCount is array (0 to C_SATA_COUNT_MAX-1) of std_logic_vector(15 downto 0);
type TBus32_SataCount is array (0 to C_SATA_COUNT_MAX-1) of std_logic_vector(31 downto 0);
type TBus48_SataCount is array (0 to C_SATA_COUNT_MAX-1) of std_logic_vector(47 downto 0);


--//
type TUsrCmdPkt is record
ctrl         : std_logic_vector(15 downto 0);
feature      : std_logic_vector(7 downto 0);
feature_exp  : std_logic_vector(7 downto 0);
lba_low      : std_logic_vector(7 downto 0);
lba_low_exp  : std_logic_vector(7 downto 0);
lba_mid      : std_logic_vector(7 downto 0);
lba_mid_exp  : std_logic_vector(7 downto 0);
lba_high     : std_logic_vector(7 downto 0);
lba_high_exp : std_logic_vector(7 downto 0);
scount       : std_logic_vector(7 downto 0);
scount_exp   : std_logic_vector(7 downto 0);
command      : std_logic_vector(7 downto 0);
reserv       : std_logic_vector(7 downto 0);
end record;


--//
type TRegHold is record
device       : std_logic_vector(7 downto 0);
status       : std_logic_vector(7 downto 0);
error        : std_logic_vector(7 downto 0);
lba_low      : std_logic_vector(7 downto 0);
lba_low_exp  : std_logic_vector(7 downto 0);
lba_mid      : std_logic_vector(7 downto 0);
lba_mid_exp  : std_logic_vector(7 downto 0);
lba_high     : std_logic_vector(7 downto 0);
lba_high_exp : std_logic_vector(7 downto 0);
scount       : std_logic_vector(7 downto 0);
scount_exp   : std_logic_vector(7 downto 0);
e_status     : std_logic_vector(7 downto 0);
tsf_count    : std_logic_vector(15 downto 0);
sb_error     : std_logic_vector(7 downto 0);
sb_status    : std_logic_vector(7 downto 0);
end record;

--//
type TRegShadow is record
command      : std_logic_vector(7 downto 0);
status       : std_logic_vector(7 downto 0);
error        : std_logic_vector(7 downto 0);
device       : std_logic_vector(7 downto 0);
control      : std_logic_vector(7 downto 0);
lba_low      : std_logic_vector(7 downto 0);
lba_low_exp  : std_logic_vector(7 downto 0);
lba_mid      : std_logic_vector(7 downto 0);
lba_mid_exp  : std_logic_vector(7 downto 0);
lba_high     : std_logic_vector(7 downto 0);
lba_high_exp : std_logic_vector(7 downto 0);
scount       : std_logic_vector(7 downto 0);
scount_exp   : std_logic_vector(7 downto 0);
feature      : std_logic_vector(7 downto 0);
feature_exp  : std_logic_vector(7 downto 0);
end record;

type TRegShadowUpdate is record
fd2h      : std_logic;--//Обновление Shadow Reg по приему FIS_DEV2HOST
fpio      : std_logic;--//Обновление Shadow Reg по приему FIS_PIOSETUP
fpio_e    : std_logic;--//Обновление Shadow Reg в результате корректного завершения АТА комманды
fsdb      : std_logic;--//Обновление Shadow Reg по приему FIS_SetDevice_Bits
end record;

type TRegDMASetup is record
dir           : std_logic;--//1/0 - FPGA->HDD/FPGA<-HDD
addr_l        : std_logic_vector(31 downto 0);
addr_m        : std_logic_vector(31 downto 0);
offset        : std_logic_vector(31 downto 0);
end record;

type TRegDMA is record
fpdma         : TRegDMASetup;
trncount_byte : std_logic_vector(31 downto 0);
end record;

--//
type TALStatus is record
ATAStatus : std_logic_vector(7 downto 0);
ATAError  : std_logic_vector(7 downto 0);
SStatus   : std_logic_vector(C_ALSSTAT_LAST_BIT downto 0);
SError    : std_logic_vector(C_ALSERR_LAST_BIT downto 0);
Usr       : std_logic_vector(C_ALUSER_LAST_BIT downto 0);
end record;

type TTxBufStatus is record
pfull   : std_logic;--//prog full
aempty  : std_logic;--//almost empty
empty   : std_logic;--//empty
end record;

type TRxBufStatus is record
pfull   : std_logic;--//prog full
empty   : std_logic;--//empty
end record;

type TSpdCtrl is record
change   : std_logic;
sata_ver : std_logic_vector(C_PCTRL_SPD_BIT_M downto C_PCTRL_SPD_BIT_L);
end record;

type TSpdCtrl_GtpCh is array (0 to C_GTP_CH_COUNT_MAX-1) of TSpdCtrl;

type TPLStat_GtpCh is array (0 to C_GTP_CH_COUNT_MAX-1) of std_logic_vector(C_PLSTAT_LAST_BIT downto 0);
type TLLStat_GtpCh is array (0 to C_GTP_CH_COUNT_MAX-1) of std_logic_vector(C_LLSTAT_LAST_BIT downto 0);
type TTLStat_GtpCh is array (0 to C_GTP_CH_COUNT_MAX-1) of std_logic_vector(C_TLSTAT_LAST_BIT downto 0);

type TPLCtrl_GtpCh is array (0 to C_GTP_CH_COUNT_MAX-1) of std_logic_vector(C_PLCTRL_LAST_BIT downto 0);
type TLLCtrl_GtpCh is array (0 to C_GTP_CH_COUNT_MAX-1) of std_logic_vector(C_LLCTRL_LAST_BIT downto 0);
type TTLCtrl_GtpCh is array (0 to C_GTP_CH_COUNT_MAX-1) of std_logic_vector(C_TLCTRL_LAST_BIT downto 0);
type TALCtrl_GtpCh is array (0 to C_GTP_CH_COUNT_MAX-1) of std_logic_vector(C_ALCTRL_LAST_BIT downto 0);

type TTxBufStatus_GtpCh is array (0 to C_GTP_CH_COUNT_MAX-1) of TTxBufStatus;
type TRxBufStatus_GtpCh is array (0 to C_GTP_CH_COUNT_MAX-1) of TRxBufStatus;

type TRegHold_GtpCh is array (0 to C_GTP_CH_COUNT_MAX-1) of TRegHold;
type TRegDMA_GtpCh is array (0 to C_GTP_CH_COUNT_MAX-1) of TRegDMA;
type TRegShadow_GtpCh is array (0 to C_GTP_CH_COUNT_MAX-1) of TRegShadow;
type TRegShadowUpdate_GtpCh is array (0 to C_GTP_CH_COUNT_MAX-1) of TRegShadowUpdate;
type TALStatus_GtpCh is array (0 to C_GTP_CH_COUNT_MAX-1) of TALStatus;


---------------------------------------------------------
--Прототипы функций
---------------------------------------------------------


end sata_pkg;


package body sata_pkg is

---------------------------------------------------------
--Функции
---------------------------------------------------------


end sata_pkg;


