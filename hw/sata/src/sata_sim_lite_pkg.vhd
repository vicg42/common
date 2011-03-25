------------------------------------------------------------------------
-- Company     : Linkos
-- Engineer    : Golovachenko Victor
--
-- Create Date : 17.03.2011 9:30:04
-- Module Name : sata_sim_lite_pkg
--
-- Description : Константы используемые в модулях при параметре gerenic G_SIM="ON"
--
-- Revision:
-- Revision 0.01 - File Created
--
-------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_misc.all;
use ieee.std_logic_unsigned.all;

use ieee.std_logic_textio.all;
use std.textio.all;

use work.vicg_common_pkg.all;
use work.sata_pkg.all;

package sata_sim_lite_pkg is

---------------------------------------------------------
--Константы
---------------------------------------------------------
constant C_SIM_SATAHOST_TMR_ALIGN : integer:=12;--//Переиод отправки BURST ALIGN для sata_host.vhd

constant C_SIM_SECTOR_SIZE_DWORD  : integer:=32;                       --//Размер сеткора в Dword
constant C_SIM_FR_DWORD_COUNT_MAX : integer:=C_SIM_SECTOR_SIZE_DWORD*2;--//max кол-во Dword в FISDATA между SOF и EOF, исключая FISTYPE и CRC


--строковые имена примитивов - при моделировании облегчает контроль передоваемых/принимаемых примитивов
type TString_SataArray21 is array (0 to 20) of string(1 to 7);
constant C_PNAME_STR : TString_SataArray21:=
(
"ALIGN  ",
"SOF    ",
"EOF    ",
"SYNC   ",
"HOLDA  ",
"DMAT   ",
"HOLD   ",
"CONT   ",
"X_RDY  ",
"R_RDY  ",
"R_IP   ",
"R_OK   ",
"R_ERR  ",
"WTRM   ",
"PMREQ_P",
"PMREQ_S",
"PMACK  ",
"PMNAK  ",
"DATA   ",
"D10_2  ",
"NONE   "
);

--//Структуры используемые при моделировании - облегчает контроль за сигналами соответстующих уровней
--//Application Layer
type TSimALStatus is record
cmd_name    : string(1 to 23);
cmd_busy    : std_logic;
signature   : std_logic;
end record;

--//Transport Layer
type TSimTLCtrl is record
ata_command : std_logic;
ata_control : std_logic;
fpdma       : std_logic;
end record;

type TSimTLStatus is record
txfh2d_en        : std_logic;
rxfistype_err    : std_logic;
rxfislen_err     : std_logic;
txerr_crc_repeat : std_logic;
usr_busy         : std_logic;
end record;

--//Link Layer
type TSimLLCtrl is record
trn_escape   : std_logic;
txstart      : std_logic;
tl_check_err : std_logic;
tl_check_done: std_logic;
end record;

type TSimLLStatus is record
rxok        : std_logic;
rxdmat      : std_logic;
rxstart     : std_logic;
rxdone      : std_logic;
rxerr_crc   : std_logic;
rxerr_idle  : std_logic;
rxerr_abort : std_logic;
txok        : std_logic;
txdmat      : std_logic;
txerr_crc   : std_logic;
txerr_idle  : std_logic;
txerr_abort : std_logic;
end record;

type TSimLLRxP is record
dmat: std_logic;
hold: std_logic;
xrdy: std_logic;
cont: std_logic;
end record;

--//PHY Layer
type TSimPLCtrl is record
speed          : std_logic_vector(C_PCTRL_SPD_BIT_M-C_PCTRL_SPD_BIT_L downto 0);
end record;

type TSimPLStatus is record
dev_detect     : std_logic;
link_establish : std_logic;
speed          : std_logic_vector(C_PSTAT_SPD_BIT_M-C_PSTAT_SPD_BIT_L downto 0);
rcv_comwake    : std_logic;
end record;

type TSimPLTxStatus is record
req_name    : string(1 to 7);
suspend_en     : std_logic;
suspend_phold  : std_logic;
suspend_pholda : std_logic;
suspend_psof   : std_logic;
end record;

end sata_sim_lite_pkg;



package body sata_sim_lite_pkg is


end sata_sim_lite_pkg;


