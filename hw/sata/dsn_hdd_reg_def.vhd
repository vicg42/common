-------------------------------------------------------------------------
-- Company     : Linkos
-- Engineer    : Golovachenko Victor
--
-- Create Date : 28.01.2012 10:30:56
-- Module Name : dsn_hdd_reg_def
--
-- Description : Регистры модуля dsn_hdd.vhd
--
-- Revision:
-- Revision 0.01 - File Created
--
-------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;

package dsn_hdd_reg_def is

constant C_HDD_VERSION                        : integer:=16#00C#;

constant C_HDD_REG_CTRL_L                     : integer:=16#000#;
constant C_HDD_REG_CTRL_M                     : integer:=16#001#;
constant C_HDD_REG_STATUS_L                   : integer:=16#002#;
constant C_HDD_REG_STATUS_M                   : integer:=16#003#;

constant C_HDD_REG_LBA_BPOINT_L               : integer:=16#004#;
constant C_HDD_REG_LBA_BPOINT_MID             : integer:=16#005#;
constant C_HDD_REG_LBA_BPOINT_M               : integer:=16#006#;

constant C_HDD_REG_TEST_TWORK_L               : integer:=16#007#;
constant C_HDD_REG_TEST_TWORK_M               : integer:=16#008#;
constant C_HDD_REG_TEST_TDLY_L                : integer:=16#009#;
constant C_HDD_REG_TEST_TDLY_M                : integer:=16#00A#;

constant C_HDD_REG_HWLOG_SIZE_L               : integer:=16#00B#;
constant C_HDD_REG_HWLOG_SIZE_M               : integer:=16#00C#;

constant C_HDD_REG_STATUS_SATA0_L             : integer:=16#010#;
constant C_HDD_REG_STATUS_SATA0_M             : integer:=16#011#;
constant C_HDD_REG_STATUS_SATA1_L             : integer:=16#012#;
constant C_HDD_REG_STATUS_SATA1_M             : integer:=16#013#;
constant C_HDD_REG_STATUS_SATA2_L             : integer:=16#014#;
constant C_HDD_REG_STATUS_SATA2_M             : integer:=16#015#;
constant C_HDD_REG_STATUS_SATA3_L             : integer:=16#016#;
constant C_HDD_REG_STATUS_SATA3_M             : integer:=16#017#;
constant C_HDD_REG_STATUS_SATA4_L             : integer:=16#018#;
constant C_HDD_REG_STATUS_SATA4_M             : integer:=16#019#;
constant C_HDD_REG_STATUS_SATA5_L             : integer:=16#01A#;
constant C_HDD_REG_STATUS_SATA5_M             : integer:=16#01B#;
constant C_HDD_REG_STATUS_SATA6_L             : integer:=16#01C#;
constant C_HDD_REG_STATUS_SATA6_M             : integer:=16#01D#;
constant C_HDD_REG_STATUS_SATA7_L             : integer:=16#01E#;
constant C_HDD_REG_STATUS_SATA7_M             : integer:=16#01F#;

constant C_HDD_REG_CMDFIFO                    : integer:=16#020#;

constant C_HDD_REG_RBUF_ADR_L                 : integer:=16#021#;
constant C_HDD_REG_RBUF_ADR_M                 : integer:=16#022#;
constant C_HDD_REG_RBUF_TRNLEN                : integer:=16#023#;--//(15..8)(7..0) - trn_mem_rd;trn_mem_wr, бывший HDD_REG_RBUF_CTRL
constant C_HDD_REG_RBUF_DATA                  : integer:=16#024#;
constant C_HDD_REG_RBUF_REQLEN                : integer:=16#025#;--//data length request, бывший HDD_REG_ATADLY
constant C_HDD_REG_VERSION                    : integer:=16#027#;--//Версия контроллера dsn_hdd
constant C_HDD_REG_TP0                        : integer:=16#028#;


--//Register C_HDD_REG_CTRL_L / Bit Map:
constant C_HDD_REG_CTRLL_ERR_CLR_BIT            : integer:=0;--//Сброс ошибок
constant C_HDD_REG_CTRLL_TST_ON_BIT             : integer:=1;--//Вкл/Выкл режима измерения задержек
constant C_HDD_REG_CTRLL_TST_GEN2RAMBUF_BIT     : integer:=2;
constant C_HDD_REG_CTRLL_MEASURE_TXHOLD_DIS_BIT : integer:=3;
constant C_HDD_REG_CTRLL_TST_GEND0_BIT          : integer:=4;--//TestGen/Data=0
constant C_HDD_REG_CTRLL_TST_SPD_L_BIT          : integer:=5;
constant C_HDD_REG_CTRLL_TST_SPD_M_BIT          : integer:=12;
constant C_HDD_REG_CTRLL_ERR_STREMBUF_DIS_BIT   : integer:=13;
constant C_HDD_REG_CTRLL_HWLOG_ON_BIT           : integer:=14;
constant C_HDD_REG_CTRLL_DBGLED_OFF_BIT         : integer:=15;
constant C_HDD_REG_CTRLL_LAST_BIT               : integer:=C_HDD_REG_CTRLL_DBGLED_OFF_BIT;

--//Register C_HDD_REG_CTRL_M / Bit Map:
constant C_HDD_REG_CTRLM_GRESET                 : integer:=0;
constant C_HDD_REG_CTRLM_DIR                    : integer:=1; --0/1 - READ/WRITE
constant C_HDD_REG_CTRLM_START                  : integer:=2; --Пуск операции с ОЗУ через CFG
constant C_HDD_REG_CTRLM_CFG2RAM                : integer:=3; --Подключение CFG для работы с ОЗУ(write/read)
constant C_HDD_REG_CTRLM_VCH_EN_BIT             : integer:=4;
constant C_HDD_REG_CTRLM_LAST_BIT               : integer:=C_HDD_REG_CTRLM_VCH_EN_BIT;


end dsn_hdd_reg_def;
