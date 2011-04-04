------------------------------------------------------------------------
-- Company     : Linkos
-- Engineer    : Golovachenko Victor
--
-- Create Date : 11.03.2011 9:46:50
-- Module Name : sata_sim_pkg
--
-- Description : Константы/Типы данных/Процедуры
--               используемые в при моделировании проекта SATA
--
--               Также включает в себя объявление прототипа модуля sata_dev_model.vhd
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
use work.sata_sim_lite_pkg.all;

package sata_sim_pkg is


---------------------------------------------------------
--Константы
---------------------------------------------------------
constant C_SIM_COUNT              : integer:=4;--//Кол-во проходов симуляции

constant C_SIM_SATADEV_TMR_ALIGN  : integer:=48;--//Переиод отправки BURST ALIGN для sata_dev_model.vhd


---------------------------------------------------------
--Типы
---------------------------------------------------------
type TSimBufData is array (0 to 2048) of std_logic_vector(31 downto 0);

type TUsrAppCmdPkt is array (0 to C_USRAPP_CMDPKT_SIZE_WORD-1) of std_logic_vector(15 downto 0);

type TFIS_H2D           is array (0 to C_FIS_REG_HOST2DEV_DWSIZE-1) of std_logic_vector(31 downto 0);
type TFIS_D2H           is array (0 to C_FIS_REG_DEV2HOST_DWSIZE-1) of std_logic_vector(31 downto 0);
type TFIS_PIOSETUP      is array (0 to C_FIS_PIOSETUP_DWSIZE-1) of std_logic_vector(31 downto 0);
type TFIS_DMASETUP      is array (0 to C_FIS_DMASETUP_DWSIZE-1) of std_logic_vector(31 downto 0);
type TFIS_DMA_Activate  is array (0 to C_FIS_DMA_ACTIVATE_DWSIZE-1) of std_logic_vector(31 downto 0);
type TFIS_SetDeviceBits is array (0 to C_FIS_SET_DEV_BITS_DWSIZE-1) of std_logic_vector(31 downto 0);
type TFIS_BIST_Activate is array (0 to C_FIS_BIST_ACTIVATE_DWSIZE-1) of std_logic_vector(31 downto 0);

type TAlign is record
timer : std_logic_vector(15 downto 0);
en    : std_logic;
start : std_logic;
end record;

type TComp is record
srcambler : std_logic_vector(31 downto 0);
end record;

type TPrimitve is record
align : TAlign;
comp  : TComp;
end record;

type TFISDet is record
h2d   : std_logic;
data  : std_logic;
end record;

type TAction is record
ata_command : std_logic;
ata_control : std_logic;
dir         : std_logic;
piomode     : std_logic;
dmamode     : std_logic;
end record;

type TTx is record
primitive : TPrimitve;
end record;

type TRxDetPrmtv is record
sof : std_logic;
eof : std_logic;
cont: std_logic;
align: std_logic;
end record;

type TRxDetError is record
pcont: std_logic;
fistype: std_logic;
prmvt_count: std_logic;
end record;

type TRxDetect is record
prmtv   : TRxDetPrmtv;
rcvfis  : std_logic;
fistype : TFISDet;
error   : TRxDetError;
end record;


type TSimDBufCtrl is record
trnsize   : integer;
rcnt      : integer;
clk       : std_logic;
wused     : std_logic;
wstart    : std_logic;
wdone     : std_logic;
wdone_clr : std_logic;
wen       : std_logic;
rused     : std_logic;
rstart    : std_logic;
rdone     : std_logic;
rdone_clr : std_logic;
ren       : std_logic;
sync      : std_logic;
din       : TSimBufData;
dout      : TSimBufData;
end record;


type TRx is record
dname     : string(1 to 7);
rcv_dwcount : integer;
fisdata   : std_logic_vector(31 downto 0);
crc_calc  : std_logic_vector(31 downto 0);
detect    : TRxDetect;
bufdata   : TSimBufData;
end record;


type TInUsrOpt is record
gtp_dbus  : integer;
console_on: integer;
tx        : TTx;
rx        : TRx;
reg_shadow: TRegShadow;
action    : TAction;
loopback  : std_logic;--/1/0 - LoopBack принятых данных FISDATA/ Выдача счетика
dbuf      : TSimDBufCtrl;
end record;

type TOutUsrOpt is record
dbuf      : TSimDBufCtrl;
end record;



type TSataDevCtrl is record
atacmd_done : std_logic;
loopback    : std_logic;--/1/0 - LoopBack принятых данных FISDATA/ Выдача счетика
cmd_count   : integer;--//Кол-во отрабатываемых команд
link_establish : std_logic;
dbuf_wuse   : std_logic;
dbuf_ruse   : std_logic;
end record;
type TSataDevCtrl_GTCH is array (0 to C_GTCH_COUNT_MAX-1) of TSataDevCtrl;



type TSimDBufStatusRxTx is record
full  : std_logic;
empty : std_logic;
done  : std_logic;
en    : std_logic;
end record;

type TSimDBufStatus is record
tx : TSimDBufStatusRxTx;
rx : TSimDBufStatusRxTx;
end record;



type TSataDevStatus is record
rcv_allname  : string(1 to 7);
rcv_name     : string(1 to 7);
rcv_cont     : std_logic;
rcv_align    : std_logic;
rcv_error    : TRxDetError;
rcv_rcvfis   : std_logic;
fistype      : TFISDet;
rcv_dwcount  : integer;
rcv_fisdata  : std_logic_vector(31 downto 0);
rcv_crc_calc : std_logic_vector(31 downto 0);
end record;




---------------------------------------------------------
--Прототипы функций/процедур
---------------------------------------------------------
procedure p_print_txrxd (
  p_in_din : in   std_logic_vector(31 downto 0);
  p_in_scrambler : in   std_logic_vector(31 downto 0);
  p_in_crc       : in   std_logic_vector(31 downto 0);
  p_in_dout      : in   std_logic_vector(31 downto 0);

  p_in_usropt    : in    TInUsrOpt
);

--//Базовая операция отправка DW
procedure p_SetDW(
  signal p_in_clk    : in    std_logic;

  constant p_in_d    : in    std_logic_vector(31 downto 0);
  constant p_in_dt   : in    std_logic;

  signal p_out_d     : out   std_logic_vector(31 downto 0);
  signal p_out_dt    : out   std_logic_vector(3 downto 0);

  signal p_in_usropt : in    TInUsrOpt;
  variable vp_in_usropt : in   TOutUsrOpt;
  signal p_out_usropt: out   TOutUsrOpt
);

--//Отправка DW c анализом генерации примитива ALIGN
procedure p_SetData(
  signal p_in_clk      : in    std_logic;

  constant p_in_d      : in    std_logic_vector(31 downto 0);
  constant p_in_dt     : in    std_logic;

  signal   p_out_d     : out   std_logic_vector(31 downto 0);
  signal   p_out_dt    : out   std_logic_vector(3 downto 0);

  signal   p_in_usropt : in    TInUsrOpt;
  variable vp_in_usropt: in    TOutUsrOpt;
  signal   p_out_usropt: out   TOutUsrOpt
);

--//Отправка примитива SYNC c анализом генерации примитива ALIGN
procedure p_SetSYNC(
  signal p_in_clk            : in    std_logic;

  signal p_out_gtp_txdata    : out   std_logic_vector(31 downto 0);
  signal p_out_gtp_txcharisk : out   std_logic_vector(3 downto 0);

  signal p_in_usropt         : in    TInUsrOpt;
  signal p_out_usropt        : out   TOutUsrOpt
);

--//Отправка FIS
procedure p_SendFIS(
  signal p_in_clk            : in    std_logic;

  variable p_in_fis_data     : in    TSimBufData;
  variable p_in_fis_size     : in    integer;

  signal p_out_gtp_txdata    : out   std_logic_vector(31 downto 0);
  signal p_out_gtp_txcharisk : out   std_logic_vector(3 downto 0);

  signal p_in_usropt         : in    TInUsrOpt;
  signal p_out_usropt        : out   TOutUsrOpt
);

--//Прием FIS
procedure p_GetFIS(
  signal p_in_clk            : in    std_logic;

  signal p_out_gtp_txdata    : out   std_logic_vector(31 downto 0);
  signal p_out_gtp_txcharisk : out   std_logic_vector(3 downto 0);

  signal p_in_usropt         : in    TInUsrOpt;
  signal p_out_usropt        : out   TOutUsrOpt
);

-- Процедура ATAPIO_READ
procedure p_ATAPIO_READ(
  signal p_in_clk            : in    std_logic;

  signal p_out_gtp_txdata    : out   std_logic_vector(31 downto 0);
  signal p_out_gtp_txcharisk : out   std_logic_vector(3 downto 0);

  signal p_in_usropt         : in    TInUsrOpt;
  signal p_out_usropt        : out   TOutUsrOpt
);

-- Процедура ATAPIO_WRITE
procedure p_ATAPIO_WRITE(
  signal p_in_clk            : in    std_logic;

  signal p_out_gtp_txdata    : out   std_logic_vector(31 downto 0);
  signal p_out_gtp_txcharisk : out   std_logic_vector(3 downto 0);

  signal p_in_usropt         : in    TInUsrOpt;
  signal p_out_usropt        : out   TOutUsrOpt
);

-- Процедура ATADMA_READ
procedure p_ATADMA_READ(
  signal p_in_clk            : in    std_logic;

  signal p_out_gtp_txdata    : out   std_logic_vector(31 downto 0);
  signal p_out_gtp_txcharisk : out   std_logic_vector(3 downto 0);

  signal p_in_usropt         : in    TInUsrOpt;
  signal p_out_usropt        : out   TOutUsrOpt
);

-- Процедура ATADMA_WRITE
procedure p_ATADMA_WRITE(
  signal p_in_clk            : in    std_logic;

  signal p_out_gtp_txdata    : out   std_logic_vector(31 downto 0);
  signal p_out_gtp_txcharisk : out   std_logic_vector(3 downto 0);

  signal p_in_usropt         : in    TInUsrOpt;
  signal p_out_usropt        : out   TOutUsrOpt
);

-- Процедура p_COMMAND_ACTIVATE (Принимает решение какую команду нужно отрабатыывать)
procedure p_COMMAND_ACTIVATE(
  signal p_in_clk            : in    std_logic;

  signal p_out_gtp_txdata    : out   std_logic_vector(31 downto 0);
  signal p_out_gtp_txcharisk : out   std_logic_vector(3 downto 0);

  signal p_in_usropt         : in    TInUsrOpt;
  signal p_out_usropt        : out   TOutUsrOpt
);

-- Процедура p_CMDPKT_WRITE
procedure p_CMDPKT_WRITE(
  signal p_in_cmdfifo_wrclk  : in    std_logic;

  signal p_in_cmdpkt          : in    TUsrAppCmdPkt;

  signal p_out_cmdfifo_din    : out   std_logic_vector(15 downto 0);
  signal p_out_cmdfifo_wr     : out   std_logic
);


-- Процедура p_BUF_SendFIS
procedure p_BUF_SendFIS(
  signal p_in_clk            : in    std_logic;

  variable p_in_fis_data     : in    TSimBufData;
  variable p_in_fis_size     : in    integer;

  signal p_out_gtp_txdata    : out   std_logic_vector(31 downto 0);
  signal p_out_gtp_txcharisk : out   std_logic_vector(3 downto 0);

  signal p_in_usropt         : in    TInUsrOpt;
  signal p_out_usropt        : out   TOutUsrOpt
);

-- Процедура p_BUF_GetFIS
procedure p_BUF_GetFIS(
  signal p_in_clk            : in    std_logic;

  signal p_out_gtp_txdata    : out   std_logic_vector(31 downto 0);
  signal p_out_gtp_txcharisk : out   std_logic_vector(3 downto 0);

  signal p_in_usropt         : in    TInUsrOpt;
  signal p_out_usropt        : out   TOutUsrOpt
);

-- Процедура p_BUF_ATADMA_READ
procedure p_BUF_ATADMA_READ(
  signal p_in_clk            : in    std_logic;

  signal p_out_gtp_txdata    : out   std_logic_vector(31 downto 0);
  signal p_out_gtp_txcharisk : out   std_logic_vector(3 downto 0);

  signal p_in_usropt         : in    TInUsrOpt;
  signal p_out_usropt        : out   TOutUsrOpt
);

-- Процедура ATADMA_WRITE
procedure p_BUF_ATADMA_WRITE(
  signal p_in_clk            : in    std_logic;

  signal p_out_gtp_txdata    : out   std_logic_vector(31 downto 0);
  signal p_out_gtp_txcharisk : out   std_logic_vector(3 downto 0);

  signal p_in_usropt         : in    TInUsrOpt;
  signal p_out_usropt        : out   TOutUsrOpt
);

-- Процедура p_BUF_ATAPIO_WRITE
procedure p_BUF_ATAPIO_WRITE(
  signal p_in_clk            : in    std_logic;

  signal p_out_gtp_txdata    : out   std_logic_vector(31 downto 0);
  signal p_out_gtp_txcharisk : out   std_logic_vector(3 downto 0);

  signal p_in_usropt         : in    TInUsrOpt;
  signal p_out_usropt        : out   TOutUsrOpt
);


component sata_dev_model
generic
(
G_DBG_LLAYER : string := "OFF";
G_GTP_DBUS   : integer:= 16
);
port
(
----------------------------
--
----------------------------
p_out_gtp_txdata            : out   std_logic_vector(31 downto 0);
p_out_gtp_txcharisk         : out   std_logic_vector(3 downto 0);

p_in_gtp_rxdata             : in    std_logic_vector(31 downto 0);
p_in_gtp_rxcharisk          : in    std_logic_vector(3 downto 0);

p_out_gtp_rxstatus          : out   std_logic_vector(2 downto 0);
p_out_gtp_rxelecidle        : out   std_logic;
p_out_gtp_rxdisperr         : out   std_logic_vector(3 downto 0);
p_out_gtp_rxnotintable      : out   std_logic_vector(3 downto 0);
p_out_gtp_rxbyteisaligned   : out   std_logic;

p_in_ctrl                   : in    TSataDevCtrl;
p_out_status                : out   TSataDevStatus;

--------------------------------------------------
--Технологические сигналы
--------------------------------------------------
p_in_tst                   : in    std_logic_vector(31 downto 0);
p_out_tst                  : out   std_logic_vector(31 downto 0);

----------------------------
--System
----------------------------
p_in_clk                    : in    std_logic;
p_in_rst                    : in    std_logic
);
end component;

component sata_sim_dbuf
port
(
----------------------------
--
----------------------------
p_in_data    : in    std_logic_vector(31 downto 0);
p_in_wr      : in    std_logic;
p_in_wclk    : in    std_logic;

p_out_data   : out   std_logic_vector(31 downto 0);
p_in_rd      : in    std_logic;
p_in_rclk    : in    std_logic;

p_out_status : out   TSimDBufStatus;
p_in_ctrl    : in    TSimDBufCtrl;

p_out_simbuf : out   TSimBufData;

--------------------------------------------------
--Технологические сигналы
--------------------------------------------------
p_in_tst     : in    std_logic_vector(31 downto 0);
p_out_tst    : out   std_logic_vector(31 downto 0);

----------------------------
--System
----------------------------
p_in_rst                    : in    std_logic
);
end component;


end sata_sim_pkg;



package body sata_sim_pkg is

---------------------------------------------------------
--Функции/Процедуры
---------------------------------------------------------

-------------------------------------------------------------------------------
-- Вывод в консоль ModelSim данных
--
-------------------------------------------------------------------------------
procedure p_print_txrxd(
  p_in_din       : in   std_logic_vector(31 downto 0);
  p_in_scrambler : in   std_logic_vector(31 downto 0);
  p_in_crc       : in   std_logic_vector(31 downto 0);
  p_in_dout      : in   std_logic_vector(31 downto 0);

  p_in_usropt    : in    TInUsrOpt
)is

  variable GUI_line : LINE;--Строка дл_ вывода в ModelSim
  variable string_value : std_logic_vector(3 downto 0);

begin

if p_in_usropt.console_on=1 then
  write(GUI_line,string'("DIN 0x"));
  for y in 1 to 8 loop
  string_value:=p_in_din((32-(4*(y-1)))-1 downto (32-(4*y)));
  write(GUI_line,Int2StrHEX(CONV_INTEGER(string_value)));
  end loop;

  write(GUI_line,string'(" / CRC:0x"));
  for y in 1 to 8 loop
  string_value:=p_in_crc((32-(4*(y-1)))-1 downto (32-(4*y)));
  write(GUI_line,Int2StrHEX(CONV_INTEGER(string_value)));
  end loop;

  write(GUI_line,string'(" / Scambler:0x"));
  for y in 1 to 8 loop
  string_value:=p_in_scrambler((32-(4*(y-1)))-1 downto (32-(4*y)));
  write(GUI_line,Int2StrHEX(CONV_INTEGER(string_value)));
  end loop;

  write(GUI_line,string'(" / DOUT:0x"));
  for y in 1 to 8 loop
  string_value:=p_in_dout((32-(4*(y-1)))-1 downto (32-(4*y)));
  write(GUI_line,Int2StrHEX(CONV_INTEGER(string_value)));
  end loop;

  writeline(output, GUI_line);--
end if;
end;--//procedure p_print_txrxd

-------------------------------------------------------------------------------
-- Базовая Процедура отправки DWORD
--
-------------------------------------------------------------------------------
procedure p_SetDW(
  signal p_in_clk    : in    std_logic;

  constant p_in_d    : in    std_logic_vector(31 downto 0);
  constant p_in_dt   : in    std_logic;

  signal p_out_d     : out   std_logic_vector(31 downto 0);
  signal p_out_dt    : out   std_logic_vector(3 downto 0);

  signal p_in_usropt : in    TInUsrOpt;
  variable vp_in_usropt: in   TOutUsrOpt;
  signal p_out_usropt: out   TOutUsrOpt
)is

  type state_type is (
  bs_byte0,
  bs_byte1,
  bs_byte2,
  bs_byte3,
  bs_done
  );
  variable state, n_state : state_type;
  variable byteout   : std_logic_vector(7 downto 0);
  variable tbyteout  : std_logic;

  variable byteout1  : std_logic_vector(7 downto 0);
  variable tbyteout1 : std_logic;

  variable byteout2  : std_logic_vector(7 downto 0);
  variable tbyteout2 : std_logic;

  variable byteout3  : std_logic_vector(7 downto 0);
  variable tbyteout3 : std_logic;

  variable dbuf      : TSimDBufCtrl;

begin

dbuf.trnsize:=0;
dbuf.rcnt:=0;
dbuf.clk:='0';
dbuf.wused:='0';
dbuf.wstart:='0';
dbuf.wdone:='0';
dbuf.wdone_clr:='0';
dbuf.wen:='0';
dbuf.rused:='0';
dbuf.rstart:='0';
dbuf.rdone:='0';
dbuf.rdone_clr:='0';
dbuf.ren:='0';
dbuf.sync:='0';
for i in 0 to dbuf.din'high loop
dbuf.din(i):=(others=>'0');
dbuf.dout(i):=(others=>'0');
end loop;

--//Отправка поьзовательских данных
while state /= bs_done loop
    wait until p_in_clk'event and p_in_clk = '1';

    case state is
        when bs_byte0 =>

             if vp_in_usropt.dbuf.wstart='1' then
               dbuf.wstart:='1';
             end if;
             if vp_in_usropt.dbuf.rstart='1' then
               dbuf.rstart:='1';
             end if;

             if vp_in_usropt.dbuf.wdone_clr='1' then
               dbuf.wdone_clr:='1';
             end if;
             if vp_in_usropt.dbuf.rdone_clr='1' then
               dbuf.rdone_clr:='1';
             end if;

             if p_in_usropt.gtp_dbus=8 then
                byteout  :=p_in_d(7 downto 0);
                tbyteout :=p_in_dt;
                byteout1 :=(others=>'0');
                tbyteout1:='0';
             else
                byteout  :=p_in_d(7 downto 0);
                tbyteout :=p_in_dt;
                byteout1 :=p_in_d(15 downto 8);
                tbyteout1:=C_CHAR_D;
             end if;
             dbuf.sync:='1';

              byteout2 :=(others=>'0');
              tbyteout2:='0';
              byteout3 :=(others=>'0');
              tbyteout3:='0';

             n_state := bs_byte1;

        when bs_byte1 =>

              dbuf.wstart:='0';
              dbuf.wdone_clr:='0';

              dbuf.rstart:='0';
              dbuf.rdone_clr:='0';
              dbuf.sync:='0';

             if p_in_usropt.gtp_dbus=8 then
                byteout  :=p_in_d(15 downto 8);
                tbyteout :=C_CHAR_D;
                byteout1 :=(others=>'0');
                tbyteout1:='0';

                n_state := bs_byte2;

             else
                byteout  :=p_in_d(23 downto 16);
                tbyteout :=C_CHAR_D;
                byteout1 :=p_in_d(31 downto 24);
                tbyteout1:=C_CHAR_D;

                n_state := bs_done;
             end if;

              byteout2 :=(others=>'0');
              tbyteout2:='0';
              byteout3 :=(others=>'0');
              tbyteout3:='0';

        when bs_byte2 =>

              byteout  :=p_in_d(23 downto 16);
              tbyteout :=C_CHAR_D;
              byteout1 :=(others=>'0');
              tbyteout1:='0';

              byteout2 :=(others=>'0');
              tbyteout2:='0';
              byteout3 :=(others=>'0');
              tbyteout3:='0';

              n_state := bs_byte3;

        when bs_byte3 =>

              byteout  :=p_in_d(31 downto 24);
              tbyteout :=C_CHAR_D;
              byteout1 :=(others=>'0');
              tbyteout1:='0';

              byteout2 :=(others=>'0');
              tbyteout2:='0';
              byteout3 :=(others=>'0');
              tbyteout3:='0';

              n_state := bs_done;

        when bs_done => null;

    end case;

    state := n_state;

    p_out_d(7 downto 0) <= byteout;
    p_out_dt(0) <= tbyteout;
    p_out_d(15 downto 8) <= byteout1;
    p_out_dt(1) <= tbyteout1;

    p_out_d(23 downto 16) <= byteout2;
    p_out_dt(2) <= tbyteout2;
    p_out_d(31 downto 24) <= byteout3;
    p_out_dt(3) <= tbyteout3;

--      p_out_usropt.dbuf<=dbuf;

    p_out_usropt.dbuf.trnsize<=dbuf.trnsize;

    p_out_usropt.dbuf.rcnt<=vp_in_usropt.dbuf.rcnt;

    p_out_usropt.dbuf.clk<=dbuf.clk;
    p_out_usropt.dbuf.wused<=dbuf.wused;
    p_out_usropt.dbuf.wstart<=dbuf.wstart;
    p_out_usropt.dbuf.wdone<=dbuf.wdone;
    p_out_usropt.dbuf.wdone_clr<=dbuf.wdone_clr;
    p_out_usropt.dbuf.wen<=dbuf.wen;
    p_out_usropt.dbuf.rused<=dbuf.rused;
    p_out_usropt.dbuf.rstart<=dbuf.rstart;
    p_out_usropt.dbuf.rdone<=dbuf.rdone;
    p_out_usropt.dbuf.rdone_clr<=dbuf.rdone_clr;
    p_out_usropt.dbuf.ren<=dbuf.ren;
    p_out_usropt.dbuf.sync<=dbuf.sync;
    p_out_usropt.dbuf.din<=dbuf.din;
    p_out_usropt.dbuf.dout<=dbuf.dout;

end loop;

end;--//procedure p_SetDW

-------------------------------------------------------------------------------
-- Процедура отправки DWORD c анализом выдачи примитыва ALIGN
--
-------------------------------------------------------------------------------
procedure p_SetData(
  signal p_in_clk      : in    std_logic;

  constant p_in_d      : in    std_logic_vector(31 downto 0);
  constant p_in_dt     : in    std_logic;

  signal   p_out_d     : out   std_logic_vector(31 downto 0);
  signal   p_out_dt    : out   std_logic_vector(3 downto 0);

  signal   p_in_usropt : in    TInUsrOpt;
  variable vp_in_usropt: in    TOutUsrOpt;
  signal   p_out_usropt: out   TOutUsrOpt
)is

  variable txalign : std_logic;

begin

if p_in_usropt.tx.primitive.align.en='0' then
  p_SetDW(p_in_clk, C_PDAT_ALIGN, C_CHAR_K, p_out_d, p_out_dt, p_in_usropt, vp_in_usropt, p_out_usropt);

else
  if p_in_usropt.tx.primitive.align.start='1' then
      for y in 0 to 1 loop
      p_SetDW(p_in_clk, C_PDAT_ALIGN, C_CHAR_K, p_out_d, p_out_dt, p_in_usropt, vp_in_usropt, p_out_usropt);
      end loop;
  end if;

  --//Отправка пользовательских данных
  p_SetDW(p_in_clk, p_in_d, p_in_dt, p_out_d, p_out_dt, p_in_usropt, vp_in_usropt, p_out_usropt);
end if;

end;--//procedure p_SetData




-------------------------------------------------------------------------------
-- Процедура отправки примитива SYNC c анализом выдачи примитыва ALIGN
--
-------------------------------------------------------------------------------
procedure p_SetSYNC(
  signal p_in_clk            : in    std_logic;

  signal p_out_gtp_txdata    : out   std_logic_vector(31 downto 0);
  signal p_out_gtp_txcharisk : out   std_logic_vector(3 downto 0);

  signal p_in_usropt         : in    TInUsrOpt;
  signal p_out_usropt        : out   TOutUsrOpt
)is

  variable vusropt     : TOutUsrOpt;
  variable txcomp_cnt  : integer;
  variable GUI_line    : LINE;--Строка дл_ вывода в ModelSim

begin

vusropt.dbuf.trnsize:=0;
vusropt.dbuf.clk:='0';
vusropt.dbuf.wused:='0';
vusropt.dbuf.wstart:='0';
vusropt.dbuf.wdone:='0';
vusropt.dbuf.wdone_clr:='0';
vusropt.dbuf.wen:='0';
vusropt.dbuf.rused:='0';
vusropt.dbuf.rstart:='0';
vusropt.dbuf.rdone:='0';
vusropt.dbuf.rdone_clr:='0';
vusropt.dbuf.ren:='0';
for i in 0 to vusropt.dbuf.din'high loop
vusropt.dbuf.din(i):=(others=>'0');
vusropt.dbuf.dout(i):=(others=>'0');
end loop;

txcomp_cnt:=1;
while txcomp_cnt/=4 loop
      if txcomp_cnt/=3 then
          if txcomp_cnt=2 then
            p_SetData(p_in_clk, C_PDAT_CONT, C_CHAR_K, p_out_gtp_txdata, p_out_gtp_txcharisk, p_in_usropt, vusropt, p_out_usropt);
          else
            p_SetData(p_in_clk, C_PDAT_SYNC, C_CHAR_K, p_out_gtp_txdata, p_out_gtp_txcharisk, p_in_usropt, vusropt, p_out_usropt);
          end if;
      else
          p_SetData(p_in_clk, p_in_usropt.tx.primitive.comp.srcambler, C_CHAR_D, p_out_gtp_txdata, p_out_gtp_txcharisk, p_in_usropt, vusropt, p_out_usropt);
      end if;
      txcomp_cnt:=txcomp_cnt + 1;
end loop;

end;--//procedure p_SetSYNC



-------------------------------------------------------------------------------
-- Процедура отправки FIS
--
-------------------------------------------------------------------------------
procedure p_SendFIS(
  signal p_in_clk            : in    std_logic;

  variable p_in_fis_data     : in    TSimBufData;
  variable p_in_fis_size     : in    integer;

  signal p_out_gtp_txdata    : out   std_logic_vector(31 downto 0);
  signal p_out_gtp_txcharisk : out   std_logic_vector(3 downto 0);

  signal p_in_usropt         : in    TInUsrOpt;
  signal p_out_usropt        : out   TOutUsrOpt
)is

  variable txsrcambler : std_logic_vector(31 downto 0);
  variable txcrc       : std_logic_vector(31 downto 0);
  variable txd_out     : std_logic_vector(31 downto 0);

  variable err_det     : std_logic;

  variable det_warring : std_logic;

  variable vusropt     : TOutUsrOpt;
  variable txcomp_cnt  : integer;
  variable GUI_line    : LINE;--Строка дл_ вывода в ModelSim

begin

vusropt.dbuf.trnsize:=0;
vusropt.dbuf.clk:='0';
vusropt.dbuf.wused:='0';
vusropt.dbuf.wstart:='0';
vusropt.dbuf.wdone:='0';
vusropt.dbuf.wdone_clr:='0';
vusropt.dbuf.wen:='0';
vusropt.dbuf.rused:='0';
vusropt.dbuf.rstart:='0';
vusropt.dbuf.rdone:='0';
vusropt.dbuf.rdone_clr:='0';
vusropt.dbuf.ren:='0';
for i in 0 to vusropt.dbuf.din'high loop
vusropt.dbuf.din(i):=(others=>'0');
vusropt.dbuf.dout(i):=(others=>'0');
end loop;

txcomp_cnt:=0;
err_det:='0';
det_warring:='0';

--//Отправляем: Готов к передаче данных
--//Ждем готовности к приему данных
write(GUI_line,string'("Wait R_RDY(Host rdy recive data) ...."));writeline(output, GUI_line);
while p_in_usropt.rx.dname/="R_RDY  " loop
      if txcomp_cnt/=3 then
          if txcomp_cnt=2 then
            p_SetData(p_in_clk, C_PDAT_CONT, C_CHAR_K, p_out_gtp_txdata, p_out_gtp_txcharisk, p_in_usropt, vusropt, p_out_usropt);
          else
            p_SetData(p_in_clk, C_PDAT_X_RDY, C_CHAR_K, p_out_gtp_txdata, p_out_gtp_txcharisk, p_in_usropt, vusropt, p_out_usropt);
          end if;
          txcomp_cnt:=txcomp_cnt + 1;
      else
          p_SetData(p_in_clk, p_in_usropt.tx.primitive.comp.srcambler, C_CHAR_D, p_out_gtp_txdata, p_out_gtp_txcharisk, p_in_usropt, vusropt, p_out_usropt);
      end if;
end loop;
--//Инициализация CRC, Scrambler:
write(GUI_line,string'("RCV R_RDY."));writeline(output, GUI_line);
txcrc:=CONV_STD_LOGIC_VECTOR(16#52325032#, txcrc'length);
txsrcambler:=srambler32_0(CONV_STD_LOGIC_VECTOR(16#F0F6#, 16));

--  while p_in_usropt.dbuf.ren='0' loop
--  --//Жду когда из буфера можно будет вычитать данные
--    p_SetData(p_in_clk, p_in_usropt.tx.primitive.comp.srcambler, C_CHAR_D, p_out_gtp_txdata, p_out_gtp_txcharisk, p_in_usropt, vusropt, p_out_usropt);
--  end loop;

--//SOF
p_SetData(p_in_clk, C_PDAT_SOF, C_CHAR_K, p_out_gtp_txdata, p_out_gtp_txcharisk, p_in_usropt, vusropt, p_out_usropt);
--//user DATA
for i in 0 to p_in_fis_size loop

  vusropt.dbuf.rcnt:=i;

--    while p_in_usropt.dbuf.ren='0' loop
--    --//Жду когда из буфера можно будет вычитать данные
--      p_SetData(p_in_clk, C_PDAT_HOLD, C_CHAR_K, p_out_gtp_txdata, p_out_gtp_txcharisk, p_in_usropt, vusropt, p_out_usropt);
--    end loop;

  if p_in_usropt.rx.dname="HOLD   " then
      if det_warring='0' then
        p_SIM_WARNING ("Warrnig. Send FIS_DATA: Rcv - HOLD");
        det_warring:='1';
      end if;
      while p_in_usropt.rx.dname/="R_IP   " loop
          if txcomp_cnt/=3 then
              if txcomp_cnt=2 then
                p_SetData(p_in_clk, C_PDAT_CONT, C_CHAR_K, p_out_gtp_txdata, p_out_gtp_txcharisk, p_in_usropt, vusropt, p_out_usropt);
              else
                p_SetData(p_in_clk, C_PDAT_HOLDA, C_CHAR_K, p_out_gtp_txdata, p_out_gtp_txcharisk, p_in_usropt, vusropt, p_out_usropt);
              end if;
              txcomp_cnt:=txcomp_cnt + 1;
          else
              p_SetData(p_in_clk, p_in_usropt.tx.primitive.comp.srcambler, C_CHAR_D, p_out_gtp_txdata, p_out_gtp_txcharisk, p_in_usropt, vusropt, p_out_usropt);
          end if;
      end loop;
      p_SetData(p_in_clk, C_PDAT_HOLDA, C_CHAR_K, p_out_gtp_txdata, p_out_gtp_txcharisk, p_in_usropt, vusropt, p_out_usropt);
  end if;
  det_warring:='0';
  txcomp_cnt:=0;
  --//Расчет CRC
  txcrc:=crc32_0( p_in_fis_data(i), txcrc);
  --//Скремблирование данных
  for x in 0 to 31 loop
  txd_out(x):=p_in_fis_data(i)(x) xor txsrcambler(x);
  end loop;
  --//Отправка пользовательского DW
  p_SetData(p_in_clk, txd_out, C_CHAR_D, p_out_gtp_txdata, p_out_gtp_txcharisk, p_in_usropt, vusropt, p_out_usropt);  p_print_txrxd(p_in_fis_data(i), txsrcambler, txcrc, txd_out, p_in_usropt);
  --//Инкрементация скремблера
  txsrcambler:=srambler32_0(txsrcambler(31 downto 16));

end loop;
--//CRC
if p_in_usropt.rx.dname="HOLD   " then
    if det_warring='0' then
      p_SIM_WARNING ("Warrnig. Send FIS_DATA: Rcv - HOLD");
      det_warring:='1';
    end if;
    while p_in_usropt.rx.dname/="R_IP   " loop
        if txcomp_cnt/=3 then
            if txcomp_cnt=2 then
              p_SetData(p_in_clk, C_PDAT_CONT, C_CHAR_K, p_out_gtp_txdata, p_out_gtp_txcharisk, p_in_usropt, vusropt, p_out_usropt);
            else
              p_SetData(p_in_clk, C_PDAT_HOLDA, C_CHAR_K, p_out_gtp_txdata, p_out_gtp_txcharisk, p_in_usropt, vusropt, p_out_usropt);
            end if;
            txcomp_cnt:=txcomp_cnt + 1;
        else
            p_SetData(p_in_clk, p_in_usropt.tx.primitive.comp.srcambler, C_CHAR_D, p_out_gtp_txdata, p_out_gtp_txcharisk, p_in_usropt, vusropt, p_out_usropt);
        end if;
    end loop;
end if;
det_warring:='0';
txcomp_cnt:=0;
--//Скремблирование данных
for x in 0 to 31 loop
txd_out(x):=txcrc(x) xor txsrcambler(x);
end loop;
p_print_txrxd(txcrc, txsrcambler, txcrc, txd_out, p_in_usropt);
p_SetData(p_in_clk, txd_out, C_CHAR_D, p_out_gtp_txdata, p_out_gtp_txcharisk, p_in_usropt, vusropt, p_out_usropt);
--//EOF
if p_in_usropt.rx.dname="HOLD   " then
    if det_warring='0' then
      p_SIM_WARNING ("Warrnig. Send FIS_DATA: Rcv - HOLD");
      det_warring:='1';
    end if;
    while p_in_usropt.rx.dname/="R_IP   " loop
        if txcomp_cnt/=3 then
            if txcomp_cnt=2 then
              p_SetData(p_in_clk, C_PDAT_CONT, C_CHAR_K, p_out_gtp_txdata, p_out_gtp_txcharisk, p_in_usropt, vusropt, p_out_usropt);
            else
              p_SetData(p_in_clk, C_PDAT_HOLDA, C_CHAR_K, p_out_gtp_txdata, p_out_gtp_txcharisk, p_in_usropt, vusropt, p_out_usropt);
            end if;
            txcomp_cnt:=txcomp_cnt + 1;
        else
            p_SetData(p_in_clk, p_in_usropt.tx.primitive.comp.srcambler, C_CHAR_D, p_out_gtp_txdata, p_out_gtp_txcharisk, p_in_usropt, vusropt, p_out_usropt);
        end if;
    end loop;
end if;
det_warring:='0';
txcomp_cnt:=0;
p_SetData(p_in_clk, C_PDAT_EOF, C_CHAR_K, p_out_gtp_txdata, p_out_gtp_txcharisk, p_in_usropt, vusropt, p_out_usropt);
write(GUI_line,string'("Wait R_OK/R_ERR ...."));writeline(output, GUI_line);
while (p_in_usropt.rx.dname/="R_OK   " and  p_in_usropt.rx.dname/="R_ERR  ") loop
    p_SetData(p_in_clk,
              C_PDAT_WTRM, C_CHAR_K,
              p_out_gtp_txdata, p_out_gtp_txcharisk,
              p_in_usropt, vusropt, p_out_usropt);
    write(GUI_line,string'("...."));writeline(output, GUI_line);
end loop;
if p_in_usropt.rx.dname="R_OK   " then
  write(GUI_line,string'("RCV R_OK"));writeline(output, GUI_line);
else
  write(GUI_line,string'("RCV R_ERR"));writeline(output, GUI_line);
  err_det:='1';
end if;

--//--------------------------------

if err_det='1' then
  p_SIM_STOP("Simulation Stopped. Send FIS_DATA: Ack CRC - ERR");
end if;

p_SetData(p_in_clk,
          C_PDAT_SYNC, C_CHAR_K,
          p_out_gtp_txdata, p_out_gtp_txcharisk,
          p_in_usropt, vusropt, p_out_usropt);

end;--//procedure p_SendFIS



-------------------------------------------------------------------------------
-- Процедура приема FIS
--
-------------------------------------------------------------------------------
procedure p_GetFIS(
  signal p_in_clk            : in    std_logic;

  signal p_out_gtp_txdata    : out   std_logic_vector(31 downto 0);
  signal p_out_gtp_txcharisk : out   std_logic_vector(3 downto 0);

  signal p_in_usropt         : in    TInUsrOpt;
  signal p_out_usropt        : out   TOutUsrOpt
)is

  variable txsrcambler : std_logic_vector(31 downto 0);
  variable txcrc       : std_logic_vector(31 downto 0);
  variable txd_out     : std_logic_vector(31 downto 0);

  variable txcomp_cnt1 : integer:=0;
  variable txcomp_cnt2 : integer:=0;

  variable vusropt     : TOutUsrOpt;
  variable txcomp_cnt  : integer;
  variable GUI_line    : LINE;--Строка дл_ вывода в ModelSim

begin

vusropt.dbuf.trnsize:=0;
vusropt.dbuf.clk:='0';
vusropt.dbuf.wused:='0';
vusropt.dbuf.wstart:='0';
vusropt.dbuf.wdone:='0';
vusropt.dbuf.wdone_clr:='0';
vusropt.dbuf.wen:='0';
vusropt.dbuf.rused:='0';
vusropt.dbuf.rstart:='0';
vusropt.dbuf.rdone:='0';
vusropt.dbuf.rdone_clr:='0';
vusropt.dbuf.ren:='0';
for i in 0 to vusropt.dbuf.din'high loop
vusropt.dbuf.din(i):=(others=>'0');
vusropt.dbuf.dout(i):=(others=>'0');
end loop;

txcomp_cnt:=1;
--//--------------------------------
--//Прием : FIS_DATA(SATA_HOST->HDD)
--//--------------------------------
--//Жду когда ХОСТ будет готов к передаче данных
write(GUI_line,string'("Wait X_RDY(Host rdy send data) ...."));writeline(output, GUI_line);
while p_in_usropt.rx.dname/="X_RDY  " loop
      if txcomp_cnt/=3 then
          if txcomp_cnt=2 then
            p_SetData(p_in_clk, C_PDAT_CONT, C_CHAR_K, p_out_gtp_txdata, p_out_gtp_txcharisk, p_in_usropt, vusropt, p_out_usropt);
          else
            p_SetData(p_in_clk, C_PDAT_SYNC, C_CHAR_K, p_out_gtp_txdata, p_out_gtp_txcharisk, p_in_usropt, vusropt, p_out_usropt);
          end if;
          txcomp_cnt:=txcomp_cnt + 1;
      else
          p_SetData(p_in_clk, p_in_usropt.tx.primitive.comp.srcambler, C_CHAR_D, p_out_gtp_txdata, p_out_gtp_txcharisk, p_in_usropt, vusropt, p_out_usropt);
      end if;
end loop;
txcomp_cnt:=0;
--//Жду начала FIS_DATA
write(GUI_line,string'("RCV X_RDY. Wait SOF ...."));writeline(output, GUI_line);
lwait_sof :while p_in_usropt.rx.detect.prmtv.sof='0' loop

    if txcomp_cnt/=3 then
        if txcomp_cnt=2 then
          p_SetData(p_in_clk, C_PDAT_CONT, C_CHAR_K, p_out_gtp_txdata, p_out_gtp_txcharisk, p_in_usropt, vusropt, p_out_usropt);
        else
          p_SetData(p_in_clk, C_PDAT_R_RDY, C_CHAR_K, p_out_gtp_txdata, p_out_gtp_txcharisk, p_in_usropt, vusropt, p_out_usropt);
        end if;
        txcomp_cnt:=txcomp_cnt + 1;
    else
        p_SetData(p_in_clk, p_in_usropt.tx.primitive.comp.srcambler, C_CHAR_D, p_out_gtp_txdata, p_out_gtp_txcharisk, p_in_usropt, vusropt, p_out_usropt);
    end if;
--      write(GUI_line,string'("...."));writeline(output, GUI_line);
end loop lwait_sof;
txcomp_cnt:=0;
txcomp_cnt1:=0;
txcomp_cnt2:=0;
write(GUI_line,string'("RCV DATA. Wait EOF ...."));writeline(output, GUI_line);
lrxd :while p_in_usropt.rx.detect.prmtv.eof='0' and p_in_usropt.rx.dname/="SYNC   " loop
--//Прием FIS_DATA
    if p_in_usropt.rx.dname="HOLD   " then
        txcomp_cnt2:=0;
        if txcomp_cnt1/=3 then
            if txcomp_cnt1=2 then
              p_SetData(p_in_clk, C_PDAT_CONT, C_CHAR_K, p_out_gtp_txdata, p_out_gtp_txcharisk, p_in_usropt, vusropt, p_out_usropt);
            else
              p_SetData(p_in_clk, C_PDAT_HOLDA, C_CHAR_K, p_out_gtp_txdata, p_out_gtp_txcharisk, p_in_usropt, vusropt, p_out_usropt);
            end if;
            txcomp_cnt1:=txcomp_cnt1 + 1;
        else
            p_SetData(p_in_clk, p_in_usropt.tx.primitive.comp.srcambler, C_CHAR_D, p_out_gtp_txdata, p_out_gtp_txcharisk, p_in_usropt, vusropt, p_out_usropt);
        end if;
    else
        txcomp_cnt1:=0;
        if txcomp_cnt2/=3 then
            if txcomp_cnt2=2 then
              p_SetData(p_in_clk, C_PDAT_CONT, C_CHAR_K, p_out_gtp_txdata, p_out_gtp_txcharisk, p_in_usropt, vusropt, p_out_usropt);
            else
              p_SetData(p_in_clk, C_PDAT_R_IP, C_CHAR_K, p_out_gtp_txdata, p_out_gtp_txcharisk, p_in_usropt, vusropt, p_out_usropt);

            end if;
            txcomp_cnt2:=txcomp_cnt2 + 1;
        else
            p_SetData(p_in_clk, p_in_usropt.tx.primitive.comp.srcambler, C_CHAR_D, p_out_gtp_txdata, p_out_gtp_txcharisk, p_in_usropt, vusropt, p_out_usropt);
        end if;
    end if;
end loop lrxd;

txcomp_cnt:=0;
txcomp_cnt1:=0;
txcomp_cnt2:=0;
--//Проверка CRC
if p_in_usropt.rx.dname/="SYNC   " then
    write(GUI_line,string'("RCV EOF. CHECKING CRC..."));writeline(output, GUI_line);
    if p_in_usropt.rx.fisdata=p_in_usropt.rx.crc_calc then
      write(GUI_line,string'("CRC - OK. Wait SYNC..."));writeline(output, GUI_line);
      while p_in_usropt.rx.dname/="SYNC   " loop
          if txcomp_cnt/=3 then
              if txcomp_cnt=2 then
                p_SetData(p_in_clk, C_PDAT_CONT, C_CHAR_K, p_out_gtp_txdata, p_out_gtp_txcharisk, p_in_usropt, vusropt, p_out_usropt);
              else
                p_SetData(p_in_clk, C_PDAT_R_OK, C_CHAR_K, p_out_gtp_txdata, p_out_gtp_txcharisk, p_in_usropt, vusropt, p_out_usropt);
              end if;
              txcomp_cnt:=txcomp_cnt + 1;
          else
              p_SetData(p_in_clk, p_in_usropt.tx.primitive.comp.srcambler, C_CHAR_D, p_out_gtp_txdata, p_out_gtp_txcharisk, p_in_usropt, vusropt, p_out_usropt);
          end if;
          write(GUI_line,string'("..."));writeline(output, GUI_line);
      end loop;
      txcomp_cnt:=0;

    else

        write(GUI_line,string'("CRC - FAILED. Wait SYNC..."));writeline(output, GUI_line);
        while p_in_usropt.rx.dname/="SYNC   " loop
            if txcomp_cnt/=3 then
                if txcomp_cnt=2 then
                  p_SetData(p_in_clk, C_PDAT_CONT, C_CHAR_K, p_out_gtp_txdata, p_out_gtp_txcharisk, p_in_usropt, vusropt, p_out_usropt);
                else
                  p_SetData(p_in_clk, C_PDAT_R_ERR, C_CHAR_K, p_out_gtp_txdata, p_out_gtp_txcharisk, p_in_usropt, vusropt, p_out_usropt);
                end if;
                txcomp_cnt:=txcomp_cnt + 1;
            else
                p_SetData(p_in_clk, p_in_usropt.tx.primitive.comp.srcambler, C_CHAR_D, p_out_gtp_txdata, p_out_gtp_txcharisk, p_in_usropt, vusropt, p_out_usropt);
            end if;
            write(GUI_line,string'("..."));writeline(output, GUI_line);
        end loop;
        txcomp_cnt:=0;
        p_SIM_STOP("Simulation Stopped. Recive FIS_DATA: CRC - ERR");

    end if;

else
    write(GUI_line,string'("EROR!!! - RCV SYNC"));writeline(output, GUI_line);
    p_SIM_STOP("Simulation Stopped. Recive FIS_DATA: Until rcv data, detected SYNC - ERR");
end if;

p_SetData(p_in_clk,
          C_PDAT_SYNC, C_CHAR_K,
          p_out_gtp_txdata, p_out_gtp_txcharisk,
          p_in_usropt, vusropt, p_out_usropt);

end;--//procedure p_GetFIS



-------------------------------------------------------------------------------
-- Процедура ATAPIO_READ
--
-------------------------------------------------------------------------------
procedure p_ATAPIO_READ(
  signal p_in_clk            : in    std_logic;

  signal p_out_gtp_txdata    : out   std_logic_vector(31 downto 0);
  signal p_out_gtp_txcharisk : out   std_logic_vector(3 downto 0);

  signal p_in_usropt         : in    TInUsrOpt;
  signal p_out_usropt        : out   TOutUsrOpt
)is

  variable txfis_size      : integer:=0;
  variable txd             : TSimBufData; --//Массиив данных для передачи

  variable trncount_byte   :integer;
  variable scount          : std_logic_vector(15 downto 0);
  variable atacmd_scount   : std_logic_vector(15 downto 0);

  variable tstdata_cnt     : std_logic_vector(31 downto 0);
  variable buf_dcnt        : integer:=0;

  variable fis_d2h           : TFIS_D2H;
  variable fis_pioSetup      : TFIS_PIOSETUP;
  variable fis_dmaSetup      : TFIS_DMASETUP;
  variable fis_dmaActivate   : TFIS_DMA_Activate;
  variable fis_SetDeviceBits : TFIS_SetDeviceBits;
  variable fis_BISTActivate  : TFIS_BIST_Activate;

  variable vusropt     : TOutUsrOpt;
  variable txcomp_cnt  : integer;
  variable GUI_line    : LINE;--Строка дл_ вывода в ModelSim

begin

vusropt.dbuf.trnsize:=0;
vusropt.dbuf.clk:='0';
vusropt.dbuf.wused:='0';
vusropt.dbuf.wstart:='0';
vusropt.dbuf.wdone:='0';
vusropt.dbuf.wdone_clr:='0';
vusropt.dbuf.wen:='0';
vusropt.dbuf.rused:='0';
vusropt.dbuf.rstart:='0';
vusropt.dbuf.rdone:='0';
vusropt.dbuf.rdone_clr:='0';
vusropt.dbuf.ren:='0';
for i in 0 to vusropt.dbuf.din'high loop
vusropt.dbuf.din(i):=(others=>'0');
vusropt.dbuf.dout(i):=(others=>'0');
end loop;

--  txcomp_cnt:=1;
trncount_byte:=C_SIM_SECTOR_SIZE_DWORD*4;

scount:=(others=>'0');
atacmd_scount:=p_in_usropt.reg_shadow.scount_exp&p_in_usropt.reg_shadow.scount;

tstdata_cnt:=CONV_STD_LOGIC_VECTOR(1, tstdata_cnt'length);
buf_dcnt:=0;

write(GUI_line,string'("p_ATAPIO_READ start."));writeline(output, GUI_line);

while scount/=atacmd_scount loop
  --//--------------------------------
  --//FIS_PIOSETUP: FPGA<-HDD
  --//--------------------------------
  write(GUI_line,string'("FIS_PIOSETUP /Send Start. "));writeline(output, GUI_line);
  --//Инициализация FIS:
  txfis_size:=fis_pioSetup'high;
  for i in 0 to txfis_size loop
  txd(i):=(others=>'0');
  end loop;
  txd(0)(8*(0+1)-1 downto 8*0):=CONV_STD_LOGIC_VECTOR(C_FIS_PIOSETUP, 8);
  txd(0)(C_FIS_DIR_BIT+8):=C_DIR_D2H;--//FPGA<-HDD
  txd(0)(C_FIS_INT_BIT+8):='1';

  --Reg: Status
  txd(0)(8*2+C_REG_ATA_STATUS_BUSY_BIT):='0';
  txd(0)(8*2+C_REG_ATA_STATUS_DRQ_BIT) :='1';--Status
  txd(0)(8*2+C_REG_ATA_STATUS_DRDY_BIT):='1';

  --Reg: Error
  txd(0)(8*(3+1)-1 downto 8*3):=CONV_STD_LOGIC_VECTOR(16#00#, 8);

  --Reg: device lba_low/mid/high
  txd(1)(8*(0+1)-1 downto 8*0):=p_in_usropt.reg_shadow.lba_low;
  txd(1)(8*(1+1)-1 downto 8*1):=p_in_usropt.reg_shadow.lba_mid;
  txd(1)(8*(2+1)-1 downto 8*2):=p_in_usropt.reg_shadow.lba_high;
  txd(1)(8*(3+1)-1 downto 8*3):=p_in_usropt.reg_shadow.device;

  txd(2)(8*(0+1)-1 downto 8*0):=p_in_usropt.reg_shadow.lba_low_exp;
  txd(2)(8*(1+1)-1 downto 8*1):=p_in_usropt.reg_shadow.lba_mid_exp;
  txd(2)(8*(2+1)-1 downto 8*2):=p_in_usropt.reg_shadow.lba_high_exp;

  --Reg: scount
  txd(3)(8*(0+1)-1 downto 8*0):=p_in_usropt.reg_shadow.scount;
  txd(3)(8*(1+1)-1 downto 8*1):=p_in_usropt.reg_shadow.scount_exp;

  atacmd_scount:=p_in_usropt.reg_shadow.scount_exp&p_in_usropt.reg_shadow.scount;

  --Reg: E_Status
  if scount=atacmd_scount-1 then
    txd(3)(8*3+C_REG_ATA_STATUS_DRQ_BIT) :='0';
    txd(3)(8*3+C_REG_ATA_STATUS_DRDY_BIT):='1';
  else
    --//Для случая когда atacmd_scount>1
    txd(3)(8*3+C_REG_ATA_STATUS_BUSY_BIT):='1';--E_Status
    txd(3)(8*3+C_REG_ATA_STATUS_DRQ_BIT) :='0';--E_Status
    txd(3)(8*3+C_REG_ATA_STATUS_DRDY_BIT):='1';
  end if;

  --Reg: Transfer Count
  txd(4)(8*(1+1)-1 downto 8*0):=CONV_STD_LOGIC_VECTOR(trncount_byte, 16);--Transfer Count(Byte)

  p_SendFIS(p_in_clk,
            txd, txfis_size,
            p_out_gtp_txdata, p_out_gtp_txcharisk,
            p_in_usropt, p_out_usropt);
  write(GUI_line,string'("FIS_PIOSETUP /Send Done. "));writeline(output, GUI_line);
  --//--------------------------------

  p_SetSYNC(p_in_clk,
            p_out_gtp_txdata, p_out_gtp_txcharisk,
            p_in_usropt, p_out_usropt);

  --//--------------------------------
  --//Отправка данных: FIS_DATA
  --//--------------------------------
  --//Инициализация FIS:
  txfis_size:=trncount_byte/4;
  txd(0):=(others=>'0');
  txd(0)(8*(0+1)-1 downto 8*0):=CONV_STD_LOGIC_VECTOR(C_FIS_DATA, 8);
  for i in 1 to txfis_size loop
  --//Заполняем данные счетчиком (DW)
    if p_in_usropt.loopback='0' then
      txd(i)(8*(3+1)-1 downto 8*0):=tstdata_cnt;--EXT(scount, 32) + i;
      tstdata_cnt:=tstdata_cnt + 1;
    else
      txd(i)(8*(3+1)-1 downto 8*0):=p_in_usropt.rx.bufdata(buf_dcnt);
    end if;
    buf_dcnt:=buf_dcnt + 1;
  end loop;
  write(GUI_line,string'("FIS_DATA /Send Start/UserData Size(Byte). "));write(GUI_line, trncount_byte);writeline(output, GUI_line);
  p_SendFIS(p_in_clk,
            txd, txfis_size,
            p_out_gtp_txdata, p_out_gtp_txcharisk,
            p_in_usropt, p_out_usropt);
  write(GUI_line,string'("FIS_DATA /Send Done. "));writeline(output, GUI_line);
  --//--------------------------------

  p_SetSYNC(p_in_clk,
            p_out_gtp_txdata, p_out_gtp_txcharisk,
            p_in_usropt, p_out_usropt);

  scount:=scount+1;

end loop;

write(GUI_line,string'("p_ATAPIO_READ done."));writeline(output, GUI_line);

end;--//procedure p_ATAPIO_READ



-------------------------------------------------------------------------------
-- Процедура ATAPIO_WRITE
--
-------------------------------------------------------------------------------
procedure p_ATAPIO_WRITE(
  signal p_in_clk            : in    std_logic;

  signal p_out_gtp_txdata    : out   std_logic_vector(31 downto 0);
  signal p_out_gtp_txcharisk : out   std_logic_vector(3 downto 0);

  signal p_in_usropt         : in    TInUsrOpt;
  signal p_out_usropt        : out   TOutUsrOpt
)is

  variable txfis_size      : integer:=0;
  variable txd             : TSimBufData; --//Массиив данных для передачи

  variable trncount_byte   :integer;
  variable scount          : std_logic_vector(15 downto 0);
  variable atacmd_scount   : std_logic_vector(15 downto 0);

  variable tstdata_cnt     : std_logic_vector(31 downto 0);

  --variable fis_data        : TFIS_DATA;
  variable fis_d2h         : TFIS_D2H;
  variable fis_pioSetup    : TFIS_PIOSETUP;
  variable fis_dmaSetup    : TFIS_DMASETUP;
  variable fis_dmaActivate : TFIS_DMA_Activate;

  variable vusropt     : TOutUsrOpt;
  variable txcomp_cnt  : integer;
  variable GUI_line    : LINE;--Строка дл_ вывода в ModelSim

begin

  vusropt.dbuf.trnsize:=0;
  vusropt.dbuf.clk:='0';
  vusropt.dbuf.wused:='0';
  vusropt.dbuf.wstart:='0';
  vusropt.dbuf.wdone:='0';
  vusropt.dbuf.wdone_clr:='0';
  vusropt.dbuf.wen:='0';
  vusropt.dbuf.rused:='0';
  vusropt.dbuf.rstart:='0';
  vusropt.dbuf.rdone:='0';
  vusropt.dbuf.rdone_clr:='0';
  vusropt.dbuf.ren:='0';
  for i in 0 to vusropt.dbuf.din'high loop
  vusropt.dbuf.din(i):=(others=>'0');
  vusropt.dbuf.dout(i):=(others=>'0');
  end loop;

--  txcomp_cnt:=1;
trncount_byte:=C_SIM_SECTOR_SIZE_DWORD*4;

scount:=(others=>'0');
atacmd_scount:=p_in_usropt.reg_shadow.scount_exp&p_in_usropt.reg_shadow.scount;

tstdata_cnt:=CONV_STD_LOGIC_VECTOR(1, tstdata_cnt'length);

write(GUI_line,string'("p_ATAPIO_WRITE start."));writeline(output, GUI_line);

while scount/=atacmd_scount loop
  --//--------------------------------
  --//FIS_PIOSETUP: FPGA<-HDD
  --//--------------------------------
  write(GUI_line,string'("FIS_PIOSETUP /Send Start. "));writeline(output, GUI_line);
  --//Инициализация FIS:
  txfis_size:=fis_pioSetup'high;
  for i in 0 to txfis_size loop
  txd(i):=(others=>'0');
  end loop;
  txd(0)(8*(0+1)-1 downto 8*0):=CONV_STD_LOGIC_VECTOR(C_FIS_PIOSETUP, 8);
  txd(0)(C_FIS_DIR_BIT+8):=C_DIR_H2D;--//FPGA->HDD
  txd(0)(C_FIS_INT_BIT+8):='1';

  --Reg: Status
  txd(0)(8*2+C_REG_ATA_STATUS_BUSY_BIT):='0';
  txd(0)(8*2+C_REG_ATA_STATUS_DRQ_BIT) :='1';--Status
  txd(0)(8*2+C_REG_ATA_STATUS_DRDY_BIT):='1';

  --Reg: Error
  txd(0)(8*(3+1)-1 downto 8*3):=CONV_STD_LOGIC_VECTOR(16#00#, 8);

  --Reg: device lba_low/mid/high
  txd(1)(8*(0+1)-1 downto 8*0):=p_in_usropt.reg_shadow.lba_low;
  txd(1)(8*(1+1)-1 downto 8*1):=p_in_usropt.reg_shadow.lba_mid;
  txd(1)(8*(2+1)-1 downto 8*2):=p_in_usropt.reg_shadow.lba_high;
  txd(1)(8*(3+1)-1 downto 8*3):=p_in_usropt.reg_shadow.device;

  txd(2)(8*(0+1)-1 downto 8*0):=p_in_usropt.reg_shadow.lba_low_exp;
  txd(2)(8*(1+1)-1 downto 8*1):=p_in_usropt.reg_shadow.lba_mid_exp;
  txd(2)(8*(2+1)-1 downto 8*2):=p_in_usropt.reg_shadow.lba_high_exp;

  --Reg: scount
  txd(3)(8*(0+1)-1 downto 8*0):=p_in_usropt.reg_shadow.scount;
  txd(3)(8*(1+1)-1 downto 8*1):=p_in_usropt.reg_shadow.scount_exp;

  atacmd_scount:=p_in_usropt.reg_shadow.scount_exp&p_in_usropt.reg_shadow.scount;

  --Reg: E_Status
  if scount=atacmd_scount-1 then
    txd(3)(8*3+C_REG_ATA_STATUS_DRQ_BIT) :='0';
    txd(3)(8*3+C_REG_ATA_STATUS_DRDY_BIT):='1';
  else
    --//Для случая когда atacmd_scount>1
    txd(3)(8*3+C_REG_ATA_STATUS_BUSY_BIT):='1';--E_Status
    txd(3)(8*3+C_REG_ATA_STATUS_DRQ_BIT) :='0';--E_Status
    txd(3)(8*3+C_REG_ATA_STATUS_DRDY_BIT):='1';
  end if;

  --Reg: Transfer Count
  txd(4)(8*(1+1)-1 downto 8*0):=CONV_STD_LOGIC_VECTOR(trncount_byte, 16);--Transfer Count(Byte)

  p_SendFIS(p_in_clk,
            txd, txfis_size,
            p_out_gtp_txdata, p_out_gtp_txcharisk,
            p_in_usropt, p_out_usropt);
  write(GUI_line,string'("FIS_PIOSETUP /Send Done. "));writeline(output, GUI_line);
  --//--------------------------------

  --//--------------------------------
  --//Прием : FIS_DATA
  --//--------------------------------
  write(GUI_line,string'("FIS_DATA /Rcv Start. "));writeline(output, GUI_line);
  p_GetFIS(p_in_clk,
           p_out_gtp_txdata, p_out_gtp_txcharisk,
           p_in_usropt, p_out_usropt);
  write(GUI_line,string'("FIS_DATA /Rcv Done. "));writeline(output, GUI_line);
  --//--------------------------------

  p_SetSYNC(p_in_clk,
            p_out_gtp_txdata, p_out_gtp_txcharisk,
            p_in_usropt, p_out_usropt);

  scount:=scount+1;

end loop;

write(GUI_line,string'("p_ATAPIO_WRITE done."));writeline(output, GUI_line);

end;--//procedure p_ATAPIO_WRITE



-------------------------------------------------------------------------------
-- Процедура ATADMA_READ
--
-------------------------------------------------------------------------------
procedure p_ATADMA_READ(
  signal p_in_clk            : in    std_logic;

  signal p_out_gtp_txdata    : out   std_logic_vector(31 downto 0);
  signal p_out_gtp_txcharisk : out   std_logic_vector(3 downto 0);

  signal p_in_usropt         : in    TInUsrOpt;
  signal p_out_usropt        : out   TOutUsrOpt
)is

  variable txfis_size      : integer:=0;
  variable txd             : TSimBufData; --//Массиив данных для передачи

  variable trncount_byte   : integer:=0;
  variable scount          : integer:=0;
--  variable scount          : std_logic_vector(15 downto 0):=(others=>'0');
  variable atacmd_scount   : std_logic_vector(15 downto 0):=(others=>'0');
  variable atacmd_dma_dwcount : integer:=0;
  variable tstdata_cnt     : std_logic_vector(31 downto 0):=(others=>'0');
  variable buf_dcnt        : integer:=0;

--  variable fis_data        : TFIS_DATA;
  variable fis_d2h         : TFIS_D2H;
  variable fis_pioSetup    : TFIS_PIOSETUP;
  variable fis_dmaSetup    : TFIS_DMASETUP;
  variable fis_dmaActivate : TFIS_DMA_Activate;

  variable vusropt     : TOutUsrOpt;
  variable txcomp_cnt  : integer;
  variable GUI_line    : LINE;--Строка дл_ вывода в ModelSim

begin

vusropt.dbuf.trnsize:=0;
vusropt.dbuf.clk:='0';
vusropt.dbuf.wused:='0';
vusropt.dbuf.wstart:='0';
vusropt.dbuf.wdone:='0';
vusropt.dbuf.wdone_clr:='0';
vusropt.dbuf.wen:='0';
vusropt.dbuf.rused:='0';
vusropt.dbuf.rstart:='0';
vusropt.dbuf.rdone:='0';
vusropt.dbuf.rdone_clr:='0';
vusropt.dbuf.ren:='0';
for i in 0 to vusropt.dbuf.din'high loop
vusropt.dbuf.din(i):=(others=>'0');
vusropt.dbuf.dout(i):=(others=>'0');
end loop;

--  txcomp_cnt:=1;
trncount_byte:=C_SIM_SECTOR_SIZE_DWORD*4;

scount:=0;--(others=>'0');
atacmd_scount:=p_in_usropt.reg_shadow.scount_exp&p_in_usropt.reg_shadow.scount;

--//Вычисляем какое количество DW должен передать Хосту
atacmd_dma_dwcount:=CONV_INTEGER(atacmd_scount)*C_SIM_SECTOR_SIZE_DWORD;

tstdata_cnt:=CONV_STD_LOGIC_VECTOR(1, tstdata_cnt'length);
buf_dcnt:=0;

write(GUI_line,string'("p_ATADMA_READ start."));writeline(output, GUI_line);

if atacmd_dma_dwcount=0 then
   p_SIM_STOP("Simulation Stopped. p_ATADMA_READ: ERR - atacmd_dma_dwcount=0");
end if;

while atacmd_dma_dwcount/=0 loop

  --//--------------------------------
  --//Отправка данных: FIS_DATA
  --//--------------------------------
  --//Инициализация FIS:
  if atacmd_dma_dwcount>=C_SIM_FR_DWORD_COUNT_MAX then
    txfis_size:=C_SIM_FR_DWORD_COUNT_MAX;
  else
    txfis_size:=atacmd_dma_dwcount;
  end if;
  txd(0):=(others=>'0');
  txd(0)(8*(0+1)-1 downto 8*0):=CONV_STD_LOGIC_VECTOR(C_FIS_DATA, 8);
  for i in 1 to txfis_size loop
  --//Заполняем данные счетчиком (DW)
    if p_in_usropt.loopback='0' then
      txd(i)(8*(3+1)-1 downto 8*0):=tstdata_cnt;--EXT(scount, 32) + i;
      tstdata_cnt:=tstdata_cnt + 1;
    else
      txd(i)(8*(3+1)-1 downto 8*0):=p_in_usropt.rx.bufdata(buf_dcnt);
    end if;
    buf_dcnt:=buf_dcnt+1;
  end loop;
  write(GUI_line,string'("FIS_DATA /Send Start/UserData Size(Byte) "));write(GUI_line, trncount_byte);writeline(output, GUI_line);
  p_SendFIS(p_in_clk,
            txd, txfis_size,
            p_out_gtp_txdata, p_out_gtp_txcharisk,
            p_in_usropt, p_out_usropt);
  write(GUI_line,string'("FIS_DATA /Send Done. "));write(GUI_line, trncount_byte);writeline(output, GUI_line);
  --//--------------------------------

  p_SetSYNC(p_in_clk,
            p_out_gtp_txdata, p_out_gtp_txcharisk,
            p_in_usropt, p_out_usropt);

  atacmd_dma_dwcount:=atacmd_dma_dwcount - txfis_size;

end loop;


--//--------------------------------
--//FIS_DEV2HOST: FPGA<-HDD
--//--------------------------------
write(GUI_line,string'("FIS_REG_DEV2HOSTA /Send Start "));writeline(output, GUI_line);
--//Инициализация FIS:
txfis_size:=fis_d2h'high;
for i in 0 to txfis_size loop
txd(i):=(others=>'0');
end loop;
txd(0)(8*(0+1)-1 downto 8*0):=CONV_STD_LOGIC_VECTOR(C_FIS_REG_DEV2HOST, 8);
txd(0)(C_FIS_INT_BIT+8):='1';

--Reg: Status
txd(0)(8*2+C_REG_ATA_STATUS_BUSY_BIT):='0';
txd(0)(8*2+C_REG_ATA_STATUS_DRDY_BIT):='1';

--Reg: Error
txd(0)(8*(3+1)-1 downto 8*3):=CONV_STD_LOGIC_VECTOR(16#00#, 8);

--Reg: device lba_low/mid/high
txd(1)(8*(0+1)-1 downto 8*0):=p_in_usropt.reg_shadow.lba_low;
txd(1)(8*(1+1)-1 downto 8*1):=p_in_usropt.reg_shadow.lba_mid;
txd(1)(8*(2+1)-1 downto 8*2):=p_in_usropt.reg_shadow.lba_high;
txd(1)(8*(3+1)-1 downto 8*3):=p_in_usropt.reg_shadow.device;

txd(2)(8*(0+1)-1 downto 8*0):=p_in_usropt.reg_shadow.lba_low_exp;
txd(2)(8*(1+1)-1 downto 8*1):=p_in_usropt.reg_shadow.lba_mid_exp;
txd(2)(8*(2+1)-1 downto 8*2):=p_in_usropt.reg_shadow.lba_high_exp;

--Reg: scount
txd(3)(8*(0+1)-1 downto 8*0):=p_in_usropt.reg_shadow.scount;
txd(3)(8*(1+1)-1 downto 8*1):=p_in_usropt.reg_shadow.scount_exp;

p_SendFIS(p_in_clk,
          txd, txfis_size,
          p_out_gtp_txdata, p_out_gtp_txcharisk,
          p_in_usropt, p_out_usropt);

write(GUI_line,string'("FIS_REG_DEV2HOSTA /Send Done. "));writeline(output, GUI_line);
--//--------------------------------

p_SetSYNC(p_in_clk,
          p_out_gtp_txdata, p_out_gtp_txcharisk,
          p_in_usropt, p_out_usropt);

write(GUI_line,string'("p_ATADMA_READ done."));writeline(output, GUI_line);

end;--//procedure p_ATADMA_READ



-------------------------------------------------------------------------------
-- Процедура ATADMA_WRITE
--
-------------------------------------------------------------------------------
procedure p_ATADMA_WRITE(
  signal p_in_clk            : in    std_logic;

  signal p_out_gtp_txdata    : out   std_logic_vector(31 downto 0);
  signal p_out_gtp_txcharisk : out   std_logic_vector(3 downto 0);

  signal p_in_usropt         : in    TInUsrOpt;
  signal p_out_usropt        : out   TOutUsrOpt
)is

  variable txfis_size      : integer:=0;
  variable txd             : TSimBufData; --//Массиив данных для передачи

  variable trncount_byte   : integer:=0;
  variable scount          : integer:=0;
  variable atacmd_scount   : std_logic_vector(15 downto 0):=(others=>'0');
  variable atacmd_dma_dwcount : integer:=0;
  variable rcv_dwcount     : integer:=0;

  variable tstdata_cnt     : std_logic_vector(31 downto 0):=(others=>'0');

--  variable fis_data        : TFIS_DATA;
  variable fis_d2h         : TFIS_D2H;
  variable fis_pioSetup    : TFIS_PIOSETUP;
  variable fis_dmaSetup    : TFIS_DMASETUP;
  variable fis_dmaActivate : TFIS_DMA_Activate;

  variable vusropt     : TOutUsrOpt;
  variable txcomp_cnt  : integer;
  variable GUI_line    : LINE;--Строка дл_ вывода в ModelSim

begin

vusropt.dbuf.trnsize:=0;
vusropt.dbuf.clk:='0';
vusropt.dbuf.wused:='0';
vusropt.dbuf.wstart:='0';
vusropt.dbuf.wdone:='0';
vusropt.dbuf.wdone_clr:='0';
vusropt.dbuf.wen:='0';
vusropt.dbuf.rused:='0';
vusropt.dbuf.rstart:='0';
vusropt.dbuf.rdone:='0';
vusropt.dbuf.rdone_clr:='0';
vusropt.dbuf.ren:='0';
for i in 0 to vusropt.dbuf.din'high loop
vusropt.dbuf.din(i):=(others=>'0');
vusropt.dbuf.dout(i):=(others=>'0');
end loop;

--  txcomp_cnt:=1;
trncount_byte:=C_SIM_SECTOR_SIZE_DWORD*4;

scount:=0;
atacmd_scount:=p_in_usropt.reg_shadow.scount_exp&p_in_usropt.reg_shadow.scount;

--//Вычисляем какое количество DW должен принять от Хоста
atacmd_dma_dwcount:=CONV_INTEGER(atacmd_scount)*C_SIM_SECTOR_SIZE_DWORD;

tstdata_cnt:=CONV_STD_LOGIC_VECTOR(1, tstdata_cnt'length);

write(GUI_line,string'("p_ATADMA_WRITE start."));writeline(output, GUI_line);

if atacmd_dma_dwcount=0 then
   p_SIM_STOP("Simulation Stopped. p_ATADMA_WRITE: ERR - atacmd_dma_dwcount=0");
end if;

while atacmd_dma_dwcount/=0 loop
  --//--------------------------------
  --//FIS_DMA_ACTIVATE: FPGA<-HDD
  --//--------------------------------
  write(GUI_line,string'("FIS_DMA_ACTIVATE /Send Start. "));writeline(output, GUI_line);
  --//Инициализация FIS:
  txfis_size:=fis_dmaActivate'high;
  for i in 0 to txfis_size loop
  txd(i):=(others=>'0');
  end loop;
  txd(0)(8*(0+1)-1 downto 8*0):=CONV_STD_LOGIC_VECTOR(C_FIS_DMA_ACTIVATE, 8);

  p_SendFIS(p_in_clk,
            txd, txfis_size,
            p_out_gtp_txdata, p_out_gtp_txcharisk,
            p_in_usropt, p_out_usropt);
  write(GUI_line,string'("FIS_DMA_ACTIVATE /Send Done. "));writeline(output, GUI_line);
  --//--------------------------------

  --//--------------------------------
  --//Прием : FIS_DATA
  --//--------------------------------
  write(GUI_line,string'("FIS_DATA /Rcv Start. "));writeline(output, GUI_line);
  p_GetFIS(p_in_clk,
           p_out_gtp_txdata, p_out_gtp_txcharisk,
           p_in_usropt, p_out_usropt);
  write(GUI_line,string'("FIS_DATA /Rcv Done. "));writeline(output, GUI_line);
  --//--------------------------------

  p_SetSYNC(p_in_clk,
            p_out_gtp_txdata, p_out_gtp_txcharisk,
            p_in_usropt, p_out_usropt);

  rcv_dwcount:=p_in_usropt.rx.rcv_dwcount-1;--//т.к DW FISTYPE не входит в пользовательские данные

  atacmd_dma_dwcount:=atacmd_dma_dwcount - rcv_dwcount;

end loop;


--//--------------------------------
--//FIS_DEV2HOST: FPGA<-HDD
--//--------------------------------
write(GUI_line,string'("FIS_REG_DEV2HOSTA /Send Start "));writeline(output, GUI_line);
--//Инициализация FIS:
txfis_size:=fis_d2h'high;
for i in 0 to txfis_size loop
txd(i):=(others=>'0');
end loop;
txd(0)(8*(0+1)-1 downto 8*0):=CONV_STD_LOGIC_VECTOR(C_FIS_REG_DEV2HOST, 8);
txd(0)(C_FIS_INT_BIT+8):='1';

--Reg: Status
txd(0)(8*2+C_REG_ATA_STATUS_BUSY_BIT):='0';
txd(0)(8*2+C_REG_ATA_STATUS_DRDY_BIT):='1';

--Reg: Error
txd(0)(8*(3+1)-1 downto 8*3):=CONV_STD_LOGIC_VECTOR(16#00#, 8);

--Reg: device lba_low/mid/high
txd(1)(8*(0+1)-1 downto 8*0):=p_in_usropt.reg_shadow.lba_low;
txd(1)(8*(1+1)-1 downto 8*1):=p_in_usropt.reg_shadow.lba_mid;
txd(1)(8*(2+1)-1 downto 8*2):=p_in_usropt.reg_shadow.lba_high;
txd(1)(8*(3+1)-1 downto 8*3):=p_in_usropt.reg_shadow.device;

txd(2)(8*(0+1)-1 downto 8*0):=p_in_usropt.reg_shadow.lba_low_exp;
txd(2)(8*(1+1)-1 downto 8*1):=p_in_usropt.reg_shadow.lba_mid_exp;
txd(2)(8*(2+1)-1 downto 8*2):=p_in_usropt.reg_shadow.lba_high_exp;

--Reg: scount
txd(3)(8*(0+1)-1 downto 8*0):=p_in_usropt.reg_shadow.scount;
txd(3)(8*(1+1)-1 downto 8*1):=p_in_usropt.reg_shadow.scount_exp;

p_SendFIS(p_in_clk,
          txd, txfis_size,
          p_out_gtp_txdata, p_out_gtp_txcharisk,
          p_in_usropt, p_out_usropt);

write(GUI_line,string'("FIS_REG_DEV2HOSTA /Send Done. "));writeline(output, GUI_line);
--//--------------------------------

p_SetSYNC(p_in_clk,
          p_out_gtp_txdata, p_out_gtp_txcharisk,
          p_in_usropt, p_out_usropt);

write(GUI_line,string'("p_ATADMA_WRITE done."));writeline(output, GUI_line);

end;--//procedure p_ATADMA_WRITE


-------------------------------------------------------------------------------
-- Процедура p_ATACOMMAND
--
-------------------------------------------------------------------------------
procedure p_COMMAND_ACTIVATE(
  signal p_in_clk            : in    std_logic;

  signal p_out_gtp_txdata    : out   std_logic_vector(31 downto 0);
  signal p_out_gtp_txcharisk : out   std_logic_vector(3 downto 0);

  signal p_in_usropt         : in    TInUsrOpt;
  signal p_out_usropt        : out   TOutUsrOpt
)is

  variable GUI_line    : LINE;--Строка дл_ вывода в ModelSim

begin

if p_in_usropt.action.ata_command='1' then

  if p_in_usropt.action.piomode='1' then
      if p_in_usropt.action.dir=C_DIR_H2D then
            if p_in_usropt.dbuf.wused='1' then
            --//Использовать модуль sata_bufdata.vhd
              p_BUF_ATAPIO_WRITE(p_in_clk,
                       p_out_gtp_txdata, p_out_gtp_txcharisk,
                       p_in_usropt, p_out_usropt);
            else
              p_ATAPIO_WRITE(p_in_clk,
                       p_out_gtp_txdata, p_out_gtp_txcharisk,
                       p_in_usropt, p_out_usropt);
            end if;
      else
--              if p_in_usropt.dbuf.rused='1' then
--              --//Использовать модуль sata_bufdata.vhd
--                p_BUF_ATAPIO_READ(p_in_clk,
--                         p_out_gtp_txdata, p_out_gtp_txcharisk,
--                         p_in_usropt, p_out_usropt);
--              else
              p_ATAPIO_READ(p_in_clk,
                       p_out_gtp_txdata, p_out_gtp_txcharisk,
                       p_in_usropt, p_out_usropt);
--              end if;
      end if;

  elsif p_in_usropt.action.dmamode='1' then
      if p_in_usropt.action.dir=C_DIR_H2D then

            if p_in_usropt.dbuf.wused='1' then
            --//Использовать модуль sata_bufdata.vhd
              p_BUF_ATADMA_WRITE(p_in_clk,
                       p_out_gtp_txdata, p_out_gtp_txcharisk,
                       p_in_usropt, p_out_usropt);
            else
              p_ATADMA_WRITE(p_in_clk,
                       p_out_gtp_txdata, p_out_gtp_txcharisk,
                       p_in_usropt, p_out_usropt);
            end if;

      else
--              if p_in_usropt.dbuf.rused='1' then
--              --//Использовать модуль sata_bufdata.vhd
--                p_BUF_ATADMA_READ(p_in_clk,
--                         p_out_gtp_txdata, p_out_gtp_txcharisk,
--                         p_in_usropt, p_out_usropt);
--              else
              p_ATADMA_READ(p_in_clk,
                       p_out_gtp_txdata, p_out_gtp_txcharisk,
                       p_in_usropt, p_out_usropt);
--              end if;
      end if;

  else
    write(GUI_line,string'("BAD MODE"));writeline(output, GUI_line);
    p_SIM_STOP("Simulation Stopped. ERROR - type ATA CMD(PIO/DMA) not detected!!!");

  end if;

else
  write(GUI_line,string'("BAD ACTION"));writeline(output, GUI_line);
  p_SIM_STOP("Simulation Stopped. ERROR - p_in_usropt.action.ata_command='0'");

end if;

end;--//procedure p_COMMAND_ACTIVATE


-------------------------------------------------------------------------------
-- Процедура p_CMDPKT_WRITE
--
-------------------------------------------------------------------------------
procedure p_CMDPKT_WRITE(
  signal p_in_cmdfifo_wrclk   : in    std_logic;

  signal p_in_cmdpkt          : in    TUsrAppCmdPkt;

  signal p_out_cmdfifo_din    : out   std_logic_vector(15 downto 0);
  signal p_out_cmdfifo_wr     : out   std_logic
)is

  variable cmdpkt_cnt  : integer:=0;
  variable GUI_line    : LINE;--Строка дл_ вывода в ModelSim

begin

  --//Запись CmdPkt в CMDFIFO
  cmdpkt_cnt:=0;
  p_out_cmdfifo_wr<='0';

  while cmdpkt_cnt /= C_USRAPP_CMDPKT_SIZE_WORD loop
      wait until p_in_cmdfifo_wrclk'event and p_in_cmdfifo_wrclk = '1';
          p_out_cmdfifo_din<=p_in_cmdpkt(cmdpkt_cnt);
          p_out_cmdfifo_wr<='1';
          cmdpkt_cnt:=cmdpkt_cnt + 1;
  end loop;
  wait until p_in_cmdfifo_wrclk'event and p_in_cmdfifo_wrclk = '1';
  p_out_cmdfifo_wr<='0';


end;--//procedure p_CMDPKT_WRITE









-------------------------------------------------------------------------------
-- Процедура приема FIS
--
-------------------------------------------------------------------------------
procedure p_BUF_GetFIS(
  signal p_in_clk            : in    std_logic;

  signal p_out_gtp_txdata    : out   std_logic_vector(31 downto 0);
  signal p_out_gtp_txcharisk : out   std_logic_vector(3 downto 0);

  signal p_in_usropt         : in    TInUsrOpt;
  signal p_out_usropt        : out   TOutUsrOpt
)is

  variable txsrcambler : std_logic_vector(31 downto 0);
  variable txcrc       : std_logic_vector(31 downto 0);
  variable txd_out     : std_logic_vector(31 downto 0);

  variable txcomp_cnt1 : integer:=0;
  variable txcomp_cnt2 : integer:=0;

  variable vusropt     : TOutUsrOpt;
  variable txcomp_cnt  : integer;
  variable GUI_line    : LINE;--Строка дл_ вывода в ModelSim

begin

vusropt.dbuf.trnsize:=0;
vusropt.dbuf.clk:='0';
vusropt.dbuf.wused:='0';
vusropt.dbuf.wstart:='0';
vusropt.dbuf.wdone:='0';
vusropt.dbuf.wdone_clr:='0';
vusropt.dbuf.wen:='0';
vusropt.dbuf.rused:='0';
vusropt.dbuf.rstart:='0';
vusropt.dbuf.rdone:='0';
vusropt.dbuf.rdone_clr:='0';
vusropt.dbuf.ren:='0';
for i in 0 to vusropt.dbuf.din'high loop
vusropt.dbuf.din(i):=(others=>'0');
vusropt.dbuf.dout(i):=(others=>'0');
end loop;

txcomp_cnt:=1;
--//--------------------------------
--//Прием : FIS_DATA(SATA_HOST->HDD)
--//--------------------------------
--//Жду когда ХОСТ будет готов к передаче данных
write(GUI_line,string'("Wait X_RDY(Host rdy send data) ...."));writeline(output, GUI_line);
while p_in_usropt.rx.dname/="X_RDY  " loop
      if txcomp_cnt/=3 then
          if txcomp_cnt=2 then
            p_SetData(p_in_clk, C_PDAT_CONT, C_CHAR_K, p_out_gtp_txdata, p_out_gtp_txcharisk, p_in_usropt, vusropt, p_out_usropt);
          else
            p_SetData(p_in_clk, C_PDAT_SYNC, C_CHAR_K, p_out_gtp_txdata, p_out_gtp_txcharisk, p_in_usropt, vusropt, p_out_usropt);
              txcomp_cnt:=txcomp_cnt + 1;
          end if;
      else
          p_SetData(p_in_clk, p_in_usropt.tx.primitive.comp.srcambler, C_CHAR_D, p_out_gtp_txdata, p_out_gtp_txcharisk, p_in_usropt, vusropt, p_out_usropt);
      end if;
end loop;
txcomp_cnt:=0;
--//Жду начала FIS_DATA
write(GUI_line,string'("RCV X_RDY. Wait SOF ...."));writeline(output, GUI_line);
lwait_sof :while p_in_usropt.rx.detect.prmtv.sof='0' loop
    if txcomp_cnt/=3 then
        if txcomp_cnt=2 then
          p_SetData(p_in_clk, C_PDAT_CONT, C_CHAR_K, p_out_gtp_txdata, p_out_gtp_txcharisk, p_in_usropt, vusropt, p_out_usropt);
        else
          p_SetData(p_in_clk, C_PDAT_R_RDY, C_CHAR_K, p_out_gtp_txdata, p_out_gtp_txcharisk, p_in_usropt, vusropt, p_out_usropt);
        end if;
        txcomp_cnt:=txcomp_cnt + 1;
    else
        p_SetData(p_in_clk, p_in_usropt.tx.primitive.comp.srcambler, C_CHAR_D, p_out_gtp_txdata, p_out_gtp_txcharisk, p_in_usropt, vusropt, p_out_usropt);
    end if;
end loop lwait_sof;

txcomp_cnt:=0;
txcomp_cnt1:=0;
txcomp_cnt2:=0;
write(GUI_line,string'("RCV DATA. Wait EOF ...."));writeline(output, GUI_line);
lrxd :while p_in_usropt.rx.detect.prmtv.eof='0' and p_in_usropt.rx.dname/="SYNC   " loop
--//Прием FIS_DATA
  if p_in_usropt.dbuf.wused='1' and p_in_usropt.dbuf.wen='0' then
      txcomp_cnt1:=0;
      txcomp_cnt2:=0;
      if txcomp_cnt/=3 then
          if txcomp_cnt=2 then
            p_SetData(p_in_clk, C_PDAT_CONT, C_CHAR_K, p_out_gtp_txdata, p_out_gtp_txcharisk, p_in_usropt, vusropt, p_out_usropt);
            write(GUI_line,string'("RCV DATA./BUF_WDDISALE -> SEND HOLD/CONT"));writeline(output, GUI_line);
          else
            p_SetData(p_in_clk, C_PDAT_HOLD, C_CHAR_K, p_out_gtp_txdata, p_out_gtp_txcharisk, p_in_usropt, vusropt, p_out_usropt);
            write(GUI_line,string'("RCV DATA./BUF_WDDISALE -> SEND HOLD"));writeline(output, GUI_line);
          end if;
          txcomp_cnt:=txcomp_cnt + 1;
      else
          p_SetData(p_in_clk, p_in_usropt.tx.primitive.comp.srcambler, C_CHAR_D, p_out_gtp_txdata, p_out_gtp_txcharisk, p_in_usropt, vusropt, p_out_usropt);
      end if;

  else

      txcomp_cnt:=0;
      if p_in_usropt.rx.dname="HOLD   " then
          txcomp_cnt2:=0;
          if txcomp_cnt1/=3 then
              if txcomp_cnt1=2 then
                p_SetData(p_in_clk, C_PDAT_CONT, C_CHAR_K, p_out_gtp_txdata, p_out_gtp_txcharisk, p_in_usropt, vusropt, p_out_usropt);
                write(GUI_line,string'("RCV DATA./RCV HOLD -> SEND HOLDA/CONT"));writeline(output, GUI_line);
              else
                p_SetData(p_in_clk, C_PDAT_HOLDA, C_CHAR_K, p_out_gtp_txdata, p_out_gtp_txcharisk, p_in_usropt, vusropt, p_out_usropt);
                write(GUI_line,string'("RCV DATA./RCV HOLD -> SEND HOLDA"));writeline(output, GUI_line);
              end if;
              txcomp_cnt1:=txcomp_cnt1 + 1;
          else
              p_SetData(p_in_clk, p_in_usropt.tx.primitive.comp.srcambler, C_CHAR_D, p_out_gtp_txdata, p_out_gtp_txcharisk, p_in_usropt, vusropt, p_out_usropt);
          end if;
      else
          txcomp_cnt1:=0;
          if txcomp_cnt2/=3 then
              if txcomp_cnt2=2 then
                p_SetData(p_in_clk, C_PDAT_CONT, C_CHAR_K, p_out_gtp_txdata, p_out_gtp_txcharisk, p_in_usropt, vusropt, p_out_usropt);
              else
                p_SetData(p_in_clk, C_PDAT_R_IP, C_CHAR_K, p_out_gtp_txdata, p_out_gtp_txcharisk, p_in_usropt, vusropt, p_out_usropt);
              end if;
              txcomp_cnt2:=txcomp_cnt2 + 1;
          else
              p_SetData(p_in_clk, p_in_usropt.tx.primitive.comp.srcambler, C_CHAR_D, p_out_gtp_txdata, p_out_gtp_txcharisk, p_in_usropt, vusropt, p_out_usropt);
          end if;
      end if;

  end if;

end loop lrxd;
txcomp_cnt:=0;
--//Проверка CRC
if p_in_usropt.rx.dname/="SYNC   " then
    write(GUI_line,string'("RCV EOF. CHECKING CRC..."));writeline(output, GUI_line);
    if p_in_usropt.rx.fisdata=p_in_usropt.rx.crc_calc then
      write(GUI_line,string'("CRC - OK. Wait SYNC..."));writeline(output, GUI_line);
      while p_in_usropt.rx.dname/="SYNC   " loop
          if txcomp_cnt/=3 then
              if txcomp_cnt=2 then
                p_SetData(p_in_clk, C_PDAT_CONT, C_CHAR_K, p_out_gtp_txdata, p_out_gtp_txcharisk, p_in_usropt, vusropt, p_out_usropt);
              else
                p_SetData(p_in_clk, C_PDAT_R_OK, C_CHAR_K, p_out_gtp_txdata, p_out_gtp_txcharisk, p_in_usropt, vusropt, p_out_usropt);
              end if;
              txcomp_cnt:=txcomp_cnt + 1;
          else
              p_SetData(p_in_clk, p_in_usropt.tx.primitive.comp.srcambler, C_CHAR_D, p_out_gtp_txdata, p_out_gtp_txcharisk, p_in_usropt, vusropt, p_out_usropt);
          end if;
          write(GUI_line,string'("..."));writeline(output, GUI_line);
      end loop;
      txcomp_cnt:=0;

    else

        write(GUI_line,string'("CRC - FAILED. Wait SYNC..."));writeline(output, GUI_line);
        while p_in_usropt.rx.dname/="SYNC   " loop
            if txcomp_cnt/=3 then
                if txcomp_cnt=2 then
                  p_SetData(p_in_clk, C_PDAT_CONT, C_CHAR_K, p_out_gtp_txdata, p_out_gtp_txcharisk, p_in_usropt, vusropt, p_out_usropt);
                else
                  p_SetData(p_in_clk, C_PDAT_R_ERR, C_CHAR_K, p_out_gtp_txdata, p_out_gtp_txcharisk, p_in_usropt, vusropt, p_out_usropt);
                end if;
                txcomp_cnt:=txcomp_cnt + 1;
            else
                p_SetData(p_in_clk, p_in_usropt.tx.primitive.comp.srcambler, C_CHAR_D, p_out_gtp_txdata, p_out_gtp_txcharisk, p_in_usropt, vusropt, p_out_usropt);
            end if;
            write(GUI_line,string'("..."));writeline(output, GUI_line);
        end loop;
        txcomp_cnt:=0;
        p_SIM_STOP("Simulation Stopped. Recive FIS_DATA: CRC - ERR");

    end if;

else
    write(GUI_line,string'("EROR!!! - RCV SYNC"));writeline(output, GUI_line);
    p_SIM_STOP("Simulation Stopped. Recive FIS_DATA: Until rcv data, detected SYNC - ERR");
end if;

p_SetData(p_in_clk,
          C_PDAT_SYNC, C_CHAR_K,
          p_out_gtp_txdata, p_out_gtp_txcharisk,
          p_in_usropt, vusropt, p_out_usropt);

end;--//procedure p_BUF_GetFIS



-------------------------------------------------------------------------------
-- Процедура отправки FIS
--
-------------------------------------------------------------------------------
procedure p_BUF_SendFIS(
  signal p_in_clk            : in    std_logic;

  variable p_in_fis_data     : in    TSimBufData;
  variable p_in_fis_size     : in    integer;

  signal p_out_gtp_txdata    : out   std_logic_vector(31 downto 0);
  signal p_out_gtp_txcharisk : out   std_logic_vector(3 downto 0);

  signal p_in_usropt         : in    TInUsrOpt;
  signal p_out_usropt        : out   TOutUsrOpt
)is

  variable txsrcambler : std_logic_vector(31 downto 0);
  variable txcrc       : std_logic_vector(31 downto 0);
  variable txd_out     : std_logic_vector(31 downto 0);

  variable err_det     : std_logic;

  variable det_warring : std_logic;

  variable vusropt     : TOutUsrOpt;
  variable txcomp_cnt  : integer;
  variable GUI_line    : LINE;--Строка дл_ вывода в ModelSim

begin

vusropt.dbuf.trnsize:=0;
vusropt.dbuf.rcnt:=0;
vusropt.dbuf.clk:='0';
vusropt.dbuf.wused:='0';
vusropt.dbuf.wstart:='0';
vusropt.dbuf.wdone:='0';
vusropt.dbuf.wdone_clr:='0';
vusropt.dbuf.wen:='0';
vusropt.dbuf.rused:='0';
vusropt.dbuf.rstart:='0';
vusropt.dbuf.rdone:='0';
vusropt.dbuf.rdone_clr:='0';
vusropt.dbuf.ren:='0';
for i in 0 to vusropt.dbuf.din'high loop
vusropt.dbuf.din(i):=(others=>'0');
vusropt.dbuf.dout(i):=(others=>'0');
end loop;

txcomp_cnt:=0;
err_det:='0';
det_warring:='0';

--//Отправляем: Готов к передаче данных
--//Ждем готовности к приему данных
write(GUI_line,string'("Wait R_RDY(Host rdy recive data) ...."));writeline(output, GUI_line);
while p_in_usropt.rx.dname/="R_RDY  " loop
      if txcomp_cnt/=3 then
          if txcomp_cnt=2 then
            p_SetData(p_in_clk, C_PDAT_CONT, C_CHAR_K, p_out_gtp_txdata, p_out_gtp_txcharisk, p_in_usropt, vusropt, p_out_usropt);
          else
            p_SetData(p_in_clk, C_PDAT_X_RDY, C_CHAR_K, p_out_gtp_txdata, p_out_gtp_txcharisk, p_in_usropt, vusropt, p_out_usropt);
          end if;
          txcomp_cnt:=txcomp_cnt + 1;
      else
          p_SetData(p_in_clk, p_in_usropt.tx.primitive.comp.srcambler, C_CHAR_D, p_out_gtp_txdata, p_out_gtp_txcharisk, p_in_usropt, vusropt, p_out_usropt);
      end if;
end loop;
--//Инициализация CRC, Scrambler:
write(GUI_line,string'("RCV R_RDY."));writeline(output, GUI_line);
txcrc:=CONV_STD_LOGIC_VECTOR(16#52325032#, txcrc'length);
txsrcambler:=srambler32_0(CONV_STD_LOGIC_VECTOR(16#F0F6#, 16));

--  while p_in_usropt.dbuf.ren='0' loop
--  --//Жду когда из буфера можно будет вычитать данные
--    p_SetData(p_in_clk, p_in_usropt.tx.primitive.comp.srcambler, C_CHAR_D, p_out_gtp_txdata, p_out_gtp_txcharisk, p_in_usropt, vusropt, p_out_usropt);
--  end loop;

--//SOF
p_SetData(p_in_clk, C_PDAT_SOF, C_CHAR_K, p_out_gtp_txdata, p_out_gtp_txcharisk, p_in_usropt, vusropt, p_out_usropt);
--//user DATA
for i in 0 to p_in_fis_size loop

--    while p_in_usropt.dbuf.ren='0' loop
--    --//Жду когда из буфера можно будет вычитать данные
--      p_SetData(p_in_clk, C_PDAT_HOLD, C_CHAR_K, p_out_gtp_txdata, p_out_gtp_txcharisk, p_in_usropt, vusropt, p_out_usropt);
--    end loop;

  if p_in_usropt.rx.dname="HOLD   " then
      if det_warring='0' then
        p_SIM_WARNING ("Warrnig. Send FIS_DATA: Rcv - HOLD");
        det_warring:='1';
      end if;
      while p_in_usropt.rx.dname/="R_IP   " loop
          if txcomp_cnt/=3 then
              if txcomp_cnt=2 then
                p_SetData(p_in_clk, C_PDAT_CONT, C_CHAR_K, p_out_gtp_txdata, p_out_gtp_txcharisk, p_in_usropt, vusropt, p_out_usropt);
              else
                p_SetData(p_in_clk, C_PDAT_HOLDA, C_CHAR_K, p_out_gtp_txdata, p_out_gtp_txcharisk, p_in_usropt, vusropt, p_out_usropt);
              end if;
              txcomp_cnt:=txcomp_cnt + 1;
          else
              p_SetData(p_in_clk, p_in_usropt.tx.primitive.comp.srcambler, C_CHAR_D, p_out_gtp_txdata, p_out_gtp_txcharisk, p_in_usropt, vusropt, p_out_usropt);
          end if;
      end loop;
  end if;
  det_warring:='0';
  txcomp_cnt:=0;
  --//Расчет CRC
  txcrc:=crc32_0( p_in_fis_data(i), txcrc);
  --//Скремблирование данных
  for x in 0 to 31 loop
  txd_out(x):=p_in_fis_data(i)(x) xor txsrcambler(x);
  end loop;
  --//Отправка пользовательского DW
  p_SetData(p_in_clk, txd_out, C_CHAR_D, p_out_gtp_txdata, p_out_gtp_txcharisk, p_in_usropt, vusropt, p_out_usropt);  p_print_txrxd(p_in_fis_data(i), txsrcambler, txcrc, txd_out, p_in_usropt);
  --//Инкрементация скремблера
  txsrcambler:=srambler32_0(txsrcambler(31 downto 16));
  vusropt.dbuf.rcnt:=i;

end loop;
--//CRC
if p_in_usropt.rx.dname="HOLD   " then
    if det_warring='0' then
      p_SIM_WARNING ("Warrnig. Send FIS_DATA: Rcv - HOLD");
      det_warring:='1';
    end if;
    while p_in_usropt.rx.dname/="R_IP   " loop
        if txcomp_cnt/=3 then
            if txcomp_cnt=2 then
              p_SetData(p_in_clk, C_PDAT_CONT, C_CHAR_K, p_out_gtp_txdata, p_out_gtp_txcharisk, p_in_usropt, vusropt, p_out_usropt);
            else
              p_SetData(p_in_clk, C_PDAT_HOLDA, C_CHAR_K, p_out_gtp_txdata, p_out_gtp_txcharisk, p_in_usropt, vusropt, p_out_usropt);
            end if;
            txcomp_cnt:=txcomp_cnt + 1;
        else
            p_SetData(p_in_clk, p_in_usropt.tx.primitive.comp.srcambler, C_CHAR_D, p_out_gtp_txdata, p_out_gtp_txcharisk, p_in_usropt, vusropt, p_out_usropt);
        end if;
    end loop;
end if;
det_warring:='0';
txcomp_cnt:=0;
--//Скремблирование данных
for x in 0 to 31 loop
txd_out(x):=txcrc(x) xor txsrcambler(x);
end loop;
p_print_txrxd(txcrc, txsrcambler, txcrc, txd_out, p_in_usropt);
p_SetData(p_in_clk, txd_out, C_CHAR_D, p_out_gtp_txdata, p_out_gtp_txcharisk, p_in_usropt, vusropt, p_out_usropt);
--//EOF
if p_in_usropt.rx.dname="HOLD   " then
    if det_warring='0' then
      p_SIM_WARNING ("Warrnig. Send FIS_DATA: Rcv - HOLD");
      det_warring:='1';
    end if;
    while p_in_usropt.rx.dname/="R_IP   " loop
        if txcomp_cnt/=3 then
            if txcomp_cnt=2 then
              p_SetData(p_in_clk, C_PDAT_CONT, C_CHAR_K, p_out_gtp_txdata, p_out_gtp_txcharisk, p_in_usropt, vusropt, p_out_usropt);
            else
              p_SetData(p_in_clk, C_PDAT_HOLDA, C_CHAR_K, p_out_gtp_txdata, p_out_gtp_txcharisk, p_in_usropt, vusropt, p_out_usropt);
            end if;
            txcomp_cnt:=txcomp_cnt + 1;
        else
            p_SetData(p_in_clk, p_in_usropt.tx.primitive.comp.srcambler, C_CHAR_D, p_out_gtp_txdata, p_out_gtp_txcharisk, p_in_usropt, vusropt, p_out_usropt);
        end if;
    end loop;
end if;
det_warring:='0';
txcomp_cnt:=0;
p_SetData(p_in_clk, C_PDAT_EOF, C_CHAR_K, p_out_gtp_txdata, p_out_gtp_txcharisk, p_in_usropt, vusropt, p_out_usropt);
write(GUI_line,string'("Wait R_OK/R_ERR ...."));writeline(output, GUI_line);
while (p_in_usropt.rx.dname/="R_OK   " and  p_in_usropt.rx.dname/="R_ERR  ") loop
    p_SetData(p_in_clk,
              C_PDAT_WTRM, C_CHAR_K,
              p_out_gtp_txdata, p_out_gtp_txcharisk,
              p_in_usropt, vusropt, p_out_usropt);
    write(GUI_line,string'("...."));writeline(output, GUI_line);
end loop;
if p_in_usropt.rx.dname="R_OK   " then
  write(GUI_line,string'("RCV R_OK"));writeline(output, GUI_line);
else
  write(GUI_line,string'("RCV R_ERR"));writeline(output, GUI_line);
  err_det:='1';
end if;

--//--------------------------------

if err_det='1' then
  p_SIM_STOP("Simulation Stopped. Send FIS_DATA: Ack CRC - ERR");
end if;

p_SetData(p_in_clk,
          C_PDAT_SYNC, C_CHAR_K,
          p_out_gtp_txdata, p_out_gtp_txcharisk,
          p_in_usropt, vusropt, p_out_usropt);

end;--//procedure p_BUF_SendFIS



-------------------------------------------------------------------------------
-- Процедура p_BUF_ATADMA_READ
--
-------------------------------------------------------------------------------
procedure p_BUF_ATADMA_READ(
  signal p_in_clk            : in    std_logic;

  signal p_out_gtp_txdata    : out   std_logic_vector(31 downto 0);
  signal p_out_gtp_txcharisk : out   std_logic_vector(3 downto 0);

  signal p_in_usropt         : in    TInUsrOpt;
  signal p_out_usropt        : out   TOutUsrOpt
)is

  variable txfis_size      : integer:=0;
  variable txd             : TSimBufData; --//Массиив данных для передачи

  variable trncount_byte   : integer:=0;
  variable scount          : integer:=0;
  --variable scount          : std_logic_vector(15 downto 0):=(others=>'0');
  variable atacmd_scount   : std_logic_vector(15 downto 0):=(others=>'0');
  variable atacmd_dma_dwcount : integer:=0;
  variable tstdata_cnt     : std_logic_vector(31 downto 0):=(others=>'0');
  variable buf_dcnt        : integer:=0;

  --variable fis_data        : TFIS_DATA;
  variable fis_d2h         : TFIS_D2H;
  variable fis_pioSetup    : TFIS_PIOSETUP;
  variable fis_dmaSetup    : TFIS_DMASETUP;
  variable fis_dmaActivate : TFIS_DMA_Activate;

  variable vusropt     : TOutUsrOpt;
  variable txcomp_cnt  : integer;
  variable GUI_line    : LINE;--Строка дл_ вывода в ModelSim

begin

vusropt.dbuf.trnsize:=0;
vusropt.dbuf.clk:='0';
vusropt.dbuf.wused:='0';
vusropt.dbuf.wstart:='0';
vusropt.dbuf.wdone:='0';
vusropt.dbuf.wdone_clr:='0';
vusropt.dbuf.wen:='0';
vusropt.dbuf.rused:='0';
vusropt.dbuf.rstart:='0';
vusropt.dbuf.rdone:='0';
vusropt.dbuf.rdone_clr:='0';
vusropt.dbuf.ren:='0';
for i in 0 to vusropt.dbuf.din'high loop
vusropt.dbuf.din(i):=(others=>'0');
vusropt.dbuf.dout(i):=(others=>'0');
end loop;

--  txcomp_cnt:=1;
trncount_byte:=C_SIM_SECTOR_SIZE_DWORD*4;

scount:=0;--(others=>'0');
atacmd_scount:=p_in_usropt.reg_shadow.scount_exp&p_in_usropt.reg_shadow.scount;

--//Вычисляем какое количество DW должен передать Хосту
atacmd_dma_dwcount:=CONV_INTEGER(atacmd_scount)*C_SIM_SECTOR_SIZE_DWORD;

tstdata_cnt:=CONV_STD_LOGIC_VECTOR(1, tstdata_cnt'length);
buf_dcnt:=0;

write(GUI_line,string'("p_BUF_ATADMA_READ start."));writeline(output, GUI_line);

if atacmd_dma_dwcount=0 then
   p_SIM_STOP("Simulation Stopped. p_BUF_ATADMA_READ: ERR - atacmd_dma_dwcount=0");
end if;

while atacmd_dma_dwcount/=0 loop

  --//--------------------------------
  --//Отправка данных: FIS_DATA
  --//--------------------------------
  --//Инициализация FIS:
  if atacmd_dma_dwcount>=C_SIM_FR_DWORD_COUNT_MAX then
    txfis_size:=C_SIM_FR_DWORD_COUNT_MAX;
  else
    txfis_size:=atacmd_dma_dwcount;
  end if;

  write(GUI_line,string'("FIS_DATA /Send Start/UserData Size(Byte) "));write(GUI_line, trncount_byte);writeline(output, GUI_line);

  txd:=p_in_usropt.rx.bufdata;

  p_BUF_SendFIS(p_in_clk,
            txd, txfis_size,
            p_out_gtp_txdata, p_out_gtp_txcharisk,
            p_in_usropt, p_out_usropt);
  write(GUI_line,string'("FIS_DATA /Send Done. "));write(GUI_line, trncount_byte);writeline(output, GUI_line);
  --//--------------------------------

  p_SetSYNC(p_in_clk,
            p_out_gtp_txdata, p_out_gtp_txcharisk,
            p_in_usropt, p_out_usropt);

  atacmd_dma_dwcount:=atacmd_dma_dwcount - txfis_size;

end loop;


--//--------------------------------
--//FIS_DEV2HOST: FPGA<-HDD
--//--------------------------------
write(GUI_line,string'("FIS_REG_DEV2HOSTA /Send Start "));writeline(output, GUI_line);
--//Инициализация FIS:
txfis_size:=fis_d2h'high;
for i in 0 to txfis_size loop
txd(i):=(others=>'0');
end loop;
txd(0)(8*(0+1)-1 downto 8*0):=CONV_STD_LOGIC_VECTOR(C_FIS_REG_DEV2HOST, 8);
txd(0)(C_FIS_INT_BIT+8):='1';

--Reg: Status
txd(0)(8*2+C_REG_ATA_STATUS_BUSY_BIT):='0';
txd(0)(8*2+C_REG_ATA_STATUS_DRDY_BIT):='1';

--Reg: Error
txd(0)(8*(3+1)-1 downto 8*3):=CONV_STD_LOGIC_VECTOR(16#00#, 8);

--Reg: device lba_low/mid/high
txd(1)(8*(0+1)-1 downto 8*0):=p_in_usropt.reg_shadow.lba_low;
txd(1)(8*(1+1)-1 downto 8*1):=p_in_usropt.reg_shadow.lba_mid;
txd(1)(8*(2+1)-1 downto 8*2):=p_in_usropt.reg_shadow.lba_high;
txd(1)(8*(3+1)-1 downto 8*3):=p_in_usropt.reg_shadow.device;

txd(2)(8*(0+1)-1 downto 8*0):=p_in_usropt.reg_shadow.lba_low_exp;
txd(2)(8*(1+1)-1 downto 8*1):=p_in_usropt.reg_shadow.lba_mid_exp;
txd(2)(8*(2+1)-1 downto 8*2):=p_in_usropt.reg_shadow.lba_high_exp;

--Reg: scount
txd(3)(8*(0+1)-1 downto 8*0):=p_in_usropt.reg_shadow.scount;
txd(3)(8*(1+1)-1 downto 8*1):=p_in_usropt.reg_shadow.scount_exp;

p_SendFIS(p_in_clk,
          txd, txfis_size,
          p_out_gtp_txdata, p_out_gtp_txcharisk,
          p_in_usropt, p_out_usropt);

write(GUI_line,string'("FIS_REG_DEV2HOSTA /Send Done. "));writeline(output, GUI_line);
--//--------------------------------

p_SetSYNC(p_in_clk,
          p_out_gtp_txdata, p_out_gtp_txcharisk,
          p_in_usropt, p_out_usropt);

write(GUI_line,string'("p_BUF_ATADMA_READ done."));writeline(output, GUI_line);

end;--//procedure p_BUF_ATADMA_READ


-------------------------------------------------------------------------------
-- Процедура p_BUF_ATADMA_WRITE
--
-------------------------------------------------------------------------------
procedure p_BUF_ATADMA_WRITE(
  signal p_in_clk            : in    std_logic;

  signal p_out_gtp_txdata    : out   std_logic_vector(31 downto 0);
  signal p_out_gtp_txcharisk : out   std_logic_vector(3 downto 0);

  signal p_in_usropt         : in    TInUsrOpt;
  signal p_out_usropt        : out   TOutUsrOpt
)is

  variable txfis_size      : integer:=0;
  variable txd             : TSimBufData; --//Массиив данных для передачи

  variable trncount_byte   : integer:=0;
  variable scount          : integer:=0;
  variable atacmd_scount   : std_logic_vector(15 downto 0):=(others=>'0');
  variable atacmd_dma_dwcount : integer:=0;
  variable rcv_dwcount     : integer:=0;

  variable tstdata_cnt     : std_logic_vector(31 downto 0):=(others=>'0');

  variable dbuf            : TSimDBufCtrl;

--  variable fis_data        : TFIS_DATA;
  variable fis_d2h         : TFIS_D2H;
  variable fis_pioSetup    : TFIS_PIOSETUP;
  variable fis_dmaSetup    : TFIS_DMASETUP;
  variable fis_dmaActivate : TFIS_DMA_Activate;

  variable vusropt     : TOutUsrOpt;
  variable txcomp_cnt  : integer;
  variable GUI_line    : LINE;--Строка дл_ вывода в ModelSim

begin

vusropt.dbuf.trnsize:=0;
vusropt.dbuf.clk:='0';
vusropt.dbuf.wused:='0';
vusropt.dbuf.wstart:='0';
vusropt.dbuf.wdone:='0';
vusropt.dbuf.wdone_clr:='0';
vusropt.dbuf.wen:='0';
vusropt.dbuf.rused:='0';
vusropt.dbuf.rstart:='0';
vusropt.dbuf.rdone:='0';
vusropt.dbuf.rdone_clr:='0';
vusropt.dbuf.ren:='0';
for i in 0 to vusropt.dbuf.din'high loop
vusropt.dbuf.din(i):=(others=>'0');
vusropt.dbuf.dout(i):=(others=>'0');
end loop;

--  txcomp_cnt:=1;
trncount_byte:=C_SIM_SECTOR_SIZE_DWORD*4;

scount:=0;
atacmd_scount:=p_in_usropt.reg_shadow.scount_exp&p_in_usropt.reg_shadow.scount;

--//Вычисляем какое количество DW должен принять от Хоста
atacmd_dma_dwcount:=CONV_INTEGER(atacmd_scount)*C_SIM_SECTOR_SIZE_DWORD;

tstdata_cnt:=CONV_STD_LOGIC_VECTOR(1, tstdata_cnt'length);

if atacmd_dma_dwcount=0 then
   p_SIM_STOP("Simulation Stopped. p_BUF_ATADMA_WRITE: ERR - atacmd_dma_dwcount=0");
end if;

write(GUI_line,string'("p_BUF_ATADMA_WRITE start."));writeline(output, GUI_line);

--//Сигнал начать запись в буфер данных
vusropt.dbuf.trnsize:=atacmd_dma_dwcount;
vusropt.dbuf.wstart:=p_in_usropt.dbuf.wused;
p_SetData(p_in_clk, p_in_usropt.tx.primitive.comp.srcambler, C_CHAR_D, p_out_gtp_txdata, p_out_gtp_txcharisk, p_in_usropt, vusropt, p_out_usropt);
vusropt.dbuf.wstart:='0';
p_SetData(p_in_clk, p_in_usropt.tx.primitive.comp.srcambler, C_CHAR_D, p_out_gtp_txdata, p_out_gtp_txcharisk, p_in_usropt, vusropt, p_out_usropt);


while atacmd_dma_dwcount/=0 loop

  --//--------------------------------
  --//FIS_DMA_ACTIVATE: FPGA<-HDD
  --//--------------------------------
  write(GUI_line,string'("FIS_DMA_ACTIVATE /Send Start. "));writeline(output, GUI_line);
  --//Инициализация FIS:
  txfis_size:=fis_dmaActivate'high;
  for i in 0 to txfis_size loop
  txd(i):=(others=>'0');
  end loop;
  txd(0)(8*(0+1)-1 downto 8*0):=CONV_STD_LOGIC_VECTOR(C_FIS_DMA_ACTIVATE, 8);

  p_SendFIS(p_in_clk,
            txd, txfis_size,
            p_out_gtp_txdata, p_out_gtp_txcharisk,
            p_in_usropt, p_out_usropt);
  write(GUI_line,string'("FIS_DMA_ACTIVATE /Send Done. "));writeline(output, GUI_line);
  --//--------------------------------

  --//--------------------------------
  --//Прием : FIS_DATA
  --//--------------------------------
  write(GUI_line,string'("FIS_DATA /Rcv Start. "));writeline(output, GUI_line);
  p_BUF_GetFIS(p_in_clk,
           p_out_gtp_txdata, p_out_gtp_txcharisk,
           p_in_usropt, p_out_usropt);
  write(GUI_line,string'("FIS_DATA /Rcv Done. "));writeline(output, GUI_line);
  --//--------------------------------

  p_SetSYNC(p_in_clk,
            p_out_gtp_txdata, p_out_gtp_txcharisk,
            p_in_usropt, p_out_usropt);

  rcv_dwcount:=p_in_usropt.rx.rcv_dwcount-1;--//т.к DW FISTYPE не входит в пользовательские данные

  atacmd_dma_dwcount:=atacmd_dma_dwcount - rcv_dwcount;

end loop;


--//Ждем завершения записи данных в буфер
dbuf.wdone:='0';
while dbuf.wdone='0' loop
  p_SetData(p_in_clk, p_in_usropt.tx.primitive.comp.srcambler, C_CHAR_D, p_out_gtp_txdata, p_out_gtp_txcharisk, p_in_usropt, vusropt, p_out_usropt);
  dbuf.wdone:=p_in_usropt.dbuf.wdone;
end loop;
--//Сброс флага завершения записи
vusropt.dbuf.wdone_clr:=p_in_usropt.dbuf.wused;
p_SetData(p_in_clk, p_in_usropt.tx.primitive.comp.srcambler, C_CHAR_D, p_out_gtp_txdata, p_out_gtp_txcharisk, p_in_usropt, vusropt, p_out_usropt);
vusropt.dbuf.wdone_clr:='0';
p_SetData(p_in_clk, p_in_usropt.tx.primitive.comp.srcambler, C_CHAR_D, p_out_gtp_txdata, p_out_gtp_txcharisk, p_in_usropt, vusropt, p_out_usropt);

--//--------------------------------
--//FIS_DEV2HOST: FPGA<-HDD
--//--------------------------------
write(GUI_line,string'("FIS_REG_DEV2HOSTA /Send Start "));writeline(output, GUI_line);
--//Инициализация FIS:
txfis_size:=fis_d2h'high;
for i in 0 to txfis_size loop
txd(i):=(others=>'0');
end loop;
txd(0)(8*(0+1)-1 downto 8*0):=CONV_STD_LOGIC_VECTOR(C_FIS_REG_DEV2HOST, 8);
txd(0)(C_FIS_INT_BIT+8):='1';

--Reg: Status
txd(0)(8*2+C_REG_ATA_STATUS_BUSY_BIT):='0';
txd(0)(8*2+C_REG_ATA_STATUS_DRDY_BIT):='1';

--Reg: Error
txd(0)(8*(3+1)-1 downto 8*3):=CONV_STD_LOGIC_VECTOR(16#00#, 8);

--Reg: device lba_low/mid/high
txd(1)(8*(0+1)-1 downto 8*0):=p_in_usropt.reg_shadow.lba_low;
txd(1)(8*(1+1)-1 downto 8*1):=p_in_usropt.reg_shadow.lba_mid;
txd(1)(8*(2+1)-1 downto 8*2):=p_in_usropt.reg_shadow.lba_high;
txd(1)(8*(3+1)-1 downto 8*3):=p_in_usropt.reg_shadow.device;

txd(2)(8*(0+1)-1 downto 8*0):=p_in_usropt.reg_shadow.lba_low_exp;
txd(2)(8*(1+1)-1 downto 8*1):=p_in_usropt.reg_shadow.lba_mid_exp;
txd(2)(8*(2+1)-1 downto 8*2):=p_in_usropt.reg_shadow.lba_high_exp;

--Reg: scount
txd(3)(8*(0+1)-1 downto 8*0):=p_in_usropt.reg_shadow.scount;
txd(3)(8*(1+1)-1 downto 8*1):=p_in_usropt.reg_shadow.scount_exp;

p_SendFIS(p_in_clk,
          txd, txfis_size,
          p_out_gtp_txdata, p_out_gtp_txcharisk,
          p_in_usropt, p_out_usropt);

write(GUI_line,string'("FIS_REG_DEV2HOSTA /Send Done. "));writeline(output, GUI_line);
--//--------------------------------

p_SetSYNC(p_in_clk,
          p_out_gtp_txdata, p_out_gtp_txcharisk,
          p_in_usropt, p_out_usropt);

write(GUI_line,string'("p_BUF_ATADMA_WRITE done."));writeline(output, GUI_line);

end;--//procedure p_BUF_ATADMA_WRITE



-------------------------------------------------------------------------------
-- Процедура p_BUF_ATAPIO_WRITE
--
-------------------------------------------------------------------------------
procedure p_BUF_ATAPIO_WRITE(
  signal p_in_clk            : in    std_logic;

  signal p_out_gtp_txdata    : out   std_logic_vector(31 downto 0);
  signal p_out_gtp_txcharisk : out   std_logic_vector(3 downto 0);

  signal p_in_usropt         : in    TInUsrOpt;
  signal p_out_usropt        : out   TOutUsrOpt
)is

  variable txfis_size      : integer:=0;
  variable txd             : TSimBufData; --//Массиив данных для передачи

  variable trncount_byte   :integer;
  variable scount          : std_logic_vector(15 downto 0);
  variable atacmd_scount   : std_logic_vector(15 downto 0);

  variable dbuf            : TSimDBufCtrl;

  variable tstdata_cnt     : std_logic_vector(31 downto 0);

  --variable fis_data        : TFIS_DATA;
  variable fis_d2h         : TFIS_D2H;
  variable fis_pioSetup    : TFIS_PIOSETUP;
  variable fis_dmaSetup    : TFIS_DMASETUP;
  variable fis_dmaActivate : TFIS_DMA_Activate;

  variable vusropt     : TOutUsrOpt;
  variable txcomp_cnt  : integer;
  variable GUI_line    : LINE;--Строка дл_ вывода в ModelSim

begin

vusropt.dbuf.trnsize:=0;
vusropt.dbuf.clk:='0';
vusropt.dbuf.wused:='0';
vusropt.dbuf.wstart:='0';
vusropt.dbuf.wdone:='0';
vusropt.dbuf.wdone_clr:='0';
vusropt.dbuf.wen:='0';
vusropt.dbuf.rused:='0';
vusropt.dbuf.rstart:='0';
vusropt.dbuf.rdone:='0';
vusropt.dbuf.rdone_clr:='0';
vusropt.dbuf.ren:='0';
for i in 0 to vusropt.dbuf.din'high loop
vusropt.dbuf.din(i):=(others=>'0');
vusropt.dbuf.dout(i):=(others=>'0');
end loop;

--  txcomp_cnt:=1;
trncount_byte:=C_SIM_SECTOR_SIZE_DWORD*4;

scount:=(others=>'0');
atacmd_scount:=p_in_usropt.reg_shadow.scount_exp&p_in_usropt.reg_shadow.scount;

tstdata_cnt:=CONV_STD_LOGIC_VECTOR(1, tstdata_cnt'length);

if CONV_INTEGER(atacmd_scount)=0 then
   p_SIM_STOP("Simulation Stopped. p_BUF_ATAPIO_WRITE: ERR - atacmd_scount=0");
end if;

write(GUI_line,string'("p_BUF_ATAPIO_WRITE start."));writeline(output, GUI_line);

--//Сигнал начать запись в буфер данных
vusropt.dbuf.trnsize:=CONV_INTEGER(atacmd_scount);
vusropt.dbuf.wstart:=p_in_usropt.dbuf.wused;
p_SetData(p_in_clk, p_in_usropt.tx.primitive.comp.srcambler, C_CHAR_D, p_out_gtp_txdata, p_out_gtp_txcharisk, p_in_usropt, vusropt, p_out_usropt);
vusropt.dbuf.wstart:='0';
p_SetData(p_in_clk, p_in_usropt.tx.primitive.comp.srcambler, C_CHAR_D, p_out_gtp_txdata, p_out_gtp_txcharisk, p_in_usropt, vusropt, p_out_usropt);

while scount/=atacmd_scount loop
  --//--------------------------------
  --//FIS_PIOSETUP: FPGA<-HDD
  --//--------------------------------
  write(GUI_line,string'("FIS_PIOSETUP /Send Start. "));writeline(output, GUI_line);
  --//Инициализация FIS:
  txfis_size:=fis_pioSetup'high;
  for i in 0 to txfis_size loop
  txd(i):=(others=>'0');
  end loop;
  txd(0)(8*(0+1)-1 downto 8*0):=CONV_STD_LOGIC_VECTOR(C_FIS_PIOSETUP, 8);
  txd(0)(C_FIS_DIR_BIT+8):=C_DIR_H2D;--//FPGA->HDD
  txd(0)(C_FIS_INT_BIT+8):='1';

  --Reg: Status
  txd(0)(8*2+C_REG_ATA_STATUS_BUSY_BIT):='0';
  txd(0)(8*2+C_REG_ATA_STATUS_DRQ_BIT) :='1';--Status
  txd(0)(8*2+C_REG_ATA_STATUS_DRDY_BIT):='1';

  --Reg: Error
  txd(0)(8*(3+1)-1 downto 8*3):=CONV_STD_LOGIC_VECTOR(16#00#, 8);

  --Reg: device lba_low/mid/high
  txd(1)(8*(0+1)-1 downto 8*0):=p_in_usropt.reg_shadow.lba_low;
  txd(1)(8*(1+1)-1 downto 8*1):=p_in_usropt.reg_shadow.lba_mid;
  txd(1)(8*(2+1)-1 downto 8*2):=p_in_usropt.reg_shadow.lba_high;
  txd(1)(8*(3+1)-1 downto 8*3):=p_in_usropt.reg_shadow.device;

  txd(2)(8*(0+1)-1 downto 8*0):=p_in_usropt.reg_shadow.lba_low_exp;
  txd(2)(8*(1+1)-1 downto 8*1):=p_in_usropt.reg_shadow.lba_mid_exp;
  txd(2)(8*(2+1)-1 downto 8*2):=p_in_usropt.reg_shadow.lba_high_exp;

  --Reg: scount
  txd(3)(8*(0+1)-1 downto 8*0):=p_in_usropt.reg_shadow.scount;
  txd(3)(8*(1+1)-1 downto 8*1):=p_in_usropt.reg_shadow.scount_exp;

  atacmd_scount:=p_in_usropt.reg_shadow.scount_exp&p_in_usropt.reg_shadow.scount;

  --Reg: E_Status
  if scount=atacmd_scount-1 then
    txd(3)(8*3+C_REG_ATA_STATUS_DRQ_BIT) :='0';
    txd(3)(8*3+C_REG_ATA_STATUS_DRDY_BIT):='1';
  else
    --//Для случая когда atacmd_scount>1
    txd(3)(8*3+C_REG_ATA_STATUS_BUSY_BIT):='1';--E_Status
    txd(3)(8*3+C_REG_ATA_STATUS_DRQ_BIT) :='0';--E_Status
    txd(3)(8*3+C_REG_ATA_STATUS_DRDY_BIT):='1';
  end if;

  --Reg: Transfer Count
  txd(4)(8*(1+1)-1 downto 8*0):=CONV_STD_LOGIC_VECTOR(trncount_byte, 16);--Transfer Count(Byte)

  p_SendFIS(p_in_clk,
            txd, txfis_size,
            p_out_gtp_txdata, p_out_gtp_txcharisk,
            p_in_usropt, p_out_usropt);
  write(GUI_line,string'("FIS_PIOSETUP /Send Done. "));writeline(output, GUI_line);
  --//--------------------------------

  --//--------------------------------
  --//Прием : FIS_DATA
  --//--------------------------------
  write(GUI_line,string'("FIS_DATA /Rcv Start. "));writeline(output, GUI_line);
  p_GetFIS(p_in_clk,
           p_out_gtp_txdata, p_out_gtp_txcharisk,
           p_in_usropt, p_out_usropt);
  write(GUI_line,string'("FIS_DATA /Rcv Done. "));writeline(output, GUI_line);
  --//--------------------------------

  p_SetSYNC(p_in_clk,
            p_out_gtp_txdata, p_out_gtp_txcharisk,
            p_in_usropt, p_out_usropt);

  scount:=scount+1;

end loop;

--//Ждем завершения записи данных в буфер
dbuf.wdone:='0';
while dbuf.wdone='0' loop
  p_SetData(p_in_clk, p_in_usropt.tx.primitive.comp.srcambler, C_CHAR_D, p_out_gtp_txdata, p_out_gtp_txcharisk, p_in_usropt, vusropt, p_out_usropt);
  dbuf.wdone:=p_in_usropt.dbuf.wdone;
end loop;
--//Сброс флага завершения записи
vusropt.dbuf.wdone_clr:=p_in_usropt.dbuf.wused;
p_SetData(p_in_clk, p_in_usropt.tx.primitive.comp.srcambler, C_CHAR_D, p_out_gtp_txdata, p_out_gtp_txcharisk, p_in_usropt, vusropt, p_out_usropt);
vusropt.dbuf.wdone_clr:='0';
p_SetData(p_in_clk, p_in_usropt.tx.primitive.comp.srcambler, C_CHAR_D, p_out_gtp_txdata, p_out_gtp_txcharisk, p_in_usropt, vusropt, p_out_usropt);

write(GUI_line,string'("p_BUF_ATAPIO_WRITE done."));writeline(output, GUI_line);

end;--//procedure p_BUF_ATAPIO_WRITE

end sata_sim_pkg;


