-------------------------------------------------------------------------
-- Company     : Linkos
-- Engineer    : Golovachenko Victor
--
-- Create Date : 03.03.2011 9:26:27
-- Module Name : sata_dev_model
--
-- Description :
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

library unisim;
use unisim.vcomponents.all;

use work.vicg_common_pkg.all;
use work.sata_pkg.all;
use work.sata_sim_pkg.all;
use work.sata_sim_lite_pkg.all;


entity sata_dev_model is
generic
(
G_DBG_LLAYER : string := "OFF";--//"ON" - только для использования тестбанча sata_player_tb.vhd, иначе "OFF"!!!
G_GTP_DBUS   : integer:= 16
);
port
(
----------------------------
--
----------------------------
p_out_gtp_txdata            : out   std_logic_vector(15 downto 0);
p_out_gtp_txcharisk         : out   std_logic_vector(1 downto 0);

p_in_gtp_rxdata             : in    std_logic_vector(15 downto 0);
p_in_gtp_rxcharisk          : in    std_logic_vector(1 downto 0);

p_out_gtp_rxstatus          : out   std_logic_vector(2 downto 0);
p_out_gtp_rxelecidle        : out   std_logic;

p_in_ctrl                   : in    TSataDevCtrl;

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
end sata_dev_model;

architecture behavior of sata_dev_model is

--type TFIS_D2H_LENERR is array (0 to 5) of std_logic_vector(31 downto 0);
--constant C_FIS_D2H_SIGNATURE : TFIS_D2H_LENERR:=(
--  CONV_STD_LOGIC_VECTOR(16#00500034#, 32),
--  CONV_STD_LOGIC_VECTOR(16#00000001#, 32),
--  CONV_STD_LOGIC_VECTOR(16#00000000#, 32),
--  CONV_STD_LOGIC_VECTOR(16#00000001#, 32),
--  CONV_STD_LOGIC_VECTOR(16#00000000#, 32), --//FISLEN - OK
--  CONV_STD_LOGIC_VECTOR(16#00000000#, 32)  --//FISLEN - ERROR
--);

constant C_FIS_D2H_SIGNATURE : TFIS_D2H:=(
  CONV_STD_LOGIC_VECTOR(16#00500034#, 32),
  CONV_STD_LOGIC_VECTOR(16#00000001#, 32),
  CONV_STD_LOGIC_VECTOR(16#00000000#, 32),
  CONV_STD_LOGIC_VECTOR(16#00000001#, 32),
  CONV_STD_LOGIC_VECTOR(16#00000000#, 32)
);

type TPrmtvCnt is array (C_TALIGN to C_TDATA_EN) of integer;

signal i_usropt_in                  : TInUsrOpt;
signal i_usropt_out,i_usropt2_out   : TOutUsrOpt;

signal i_usropt_in2                 : TInUsrOpt;
signal i_usropt_in3                 : TInUsrOpt;

signal i_txsrcambler             : std_logic_vector(31 downto 0);
signal i_txalign_timer           : std_logic_vector(i_usropt_in.tx.primitive.align.timer'range);
signal i_txalign_timer_en        : std_logic;
signal i_txalign_start           : std_logic;

type TSrDataW8 is array (0 to 2) of std_logic_vector(7 downto 0);
signal sr_gtp_rxdata              : TSrDataW8;
type TSrDtypeW8 is array (0 to 2) of std_logic;
signal sr_gtp_rxcharisk           : TSrDtypeW8;

type TSrDataW16 is array (0 to 0) of std_logic_vector(15 downto 0);
signal sr2_gtp_rxdata             : TSrDataW16;
type TSrDtypeW16 is array (0 to 0) of std_logic_vector(1 downto 0);
signal sr2_gtp_rxcharisk          : TSrDtypeW16;

signal i_rxalign_det              : std_logic;
signal i_rxcharisk                : std_logic_vector(3 downto 0);
signal i_rxd                      : std_logic_vector(31 downto 0);
signal i_rxd_out                  : std_logic_vector(31 downto 0);
signal i_rxcrc_calc               : std_logic_vector(31 downto 0);
type TSrCRC is array (0 to 1) of std_logic_vector(31 downto 0);
signal sr_rxcrc_calc              : TSrCRC;
signal i_rxd_sync                 : std_logic_vector(selval(1, 0, cmpval(G_GTP_DBUS, 8)) downto 0);
signal i_rcv_name                 : string(1 to 7);
signal i_rcv_allname              : string(1 to 7);
signal i_rxp_sof                  : std_logic;
signal i_rxp_eof                  : std_logic;
signal i_rxp_align                : std_logic;
signal i_rxp_cont                 : std_logic;
signal i_rxp_hold_cnt             : integer;
signal i_rxp_holda_cnt            : integer;
signal i_rxp_err_pcont            : std_logic;
signal i_rxdw_cnt                 : integer:=0;
signal i_rxfis_type_cheked        : std_logic;
signal i_rxfistype                : TFISDet;
signal i_rxfistype_error          : std_logic;
signal i_rxfis                    : std_logic;
signal i_rxprmtv_err_cnt          : std_logic_vector(C_TALIGN to C_TDATA_EN):=(others=>'0');
signal i_rxprmtv_det              : std_logic_vector(C_TALIGN to C_TDATA_EN):=(others=>'0');
signal i_rxprmtv_cnt              : TPrmtvCnt;

signal i_rxfis_dcnt_sync          : integer:=0;
signal i_rxfis_dcnt               : integer:=0;

signal i_rxbuffer                 : TSimBufData;
signal i_rxbuffer_cnt_en          : std_logic:='0';
signal i_rxbuffer_cnt             : integer:=0;

signal i_action                   : TAction;
signal i_reg_shadow               : TRegShadow;
signal i_crc_checking             : std_logic_vector(31 downto 0);

signal i_dbuf_clk                 : std_logic;
signal i_dbuf_ctrl                : TSimDBufCtrl;
signal i_dbuf_status              : TSimDBufStatus;
signal i_dbuf_wr                  : std_logic:='0';
signal tstdbuf_out                : std_logic_vector(31 downto 0):=(others=>'0');

signal i_atacmd_scount   : std_logic_vector(15 downto 0):=(others=>'0');
signal i_atacmd_dwcount : integer:=0;

signal tst_dbuf_wused : std_logic;
signal tst_dbuf_wen : std_logic;
signal tst_rxp_cont : std_logic:='0';
signal rxd_without_pcont_cnt     : integer:=0;
signal tst_rxd_without_pcont_cnt : integer:=0;
signal tst_rxfis_en : std_logic;



--MAIN
begin

--//----------------------------------
--//Технологические сигналы
--//----------------------------------
p_out_tst(0)<=OR_reduce(i_crc_checking) or tst_dbuf_wused or tst_dbuf_wen or tst_rxp_cont or tst_rxfis_en;

p_out_tst(1)<='0' when i_rcv_allname="ALIGN  " and i_rcv_name="ALIGN  " else i_usropt_out.dbuf.sync and i_usropt_in.rx.detect.prmtv.sof;
p_out_tst(2)<='1' when i_rxprmtv_cnt(6)=5 or i_rxbuffer_cnt=7 or tst_rxd_without_pcont_cnt=7 else OR_reduce(tstdbuf_out);

p_out_tst(31 downto 3)<=(others=>'0');

tst_dbuf_wused<=i_usropt_in.dbuf.wused;
tst_dbuf_wen<=i_usropt_in.dbuf.wen;



--//#########################################
--//OOB signaling
--//#########################################
p_out_gtp_rxelecidle <='0','1' after 1 us, '0' after 4.5 us;
p_out_gtp_rxstatus <="001","100" after 2.5 us, "101" after 3.0 us, "010" after 4.0 us, "000" after 4.5 us;


--//#########################################
--//Инициализация
--//#########################################
i_usropt_in.gtp_dbus<=G_GTP_DBUS;
i_usropt_in.console_on<=1;

i_usropt_in.tx.primitive.align.timer<=i_txalign_timer;
i_usropt_in.tx.primitive.align.en<=i_rxalign_det;
i_usropt_in.tx.primitive.align.start<=i_txalign_start;
i_usropt_in.tx.primitive.comp.srcambler<=i_txsrcambler;

i_usropt_in.rx.dname<=i_rcv_name;
i_usropt_in.rx.rcv_dwcount<=i_rxdw_cnt;
i_usropt_in.rx.fisdata<=i_rxd_out;
--i_usropt_in.rx.crc_calc<=i_crc_checking;
i_usropt_in.rx.crc_calc<=sr_rxcrc_calc(1);--OK  sr_rxcrc_calc(0);--ERR
i_usropt_in.rx.detect.prmtv.sof<=i_rxp_sof;
i_usropt_in.rx.detect.prmtv.eof<=i_rxp_eof;
i_usropt_in.rx.detect.prmtv.cont<=i_rxp_cont;
i_usropt_in.rx.detect.prmtv.align<=i_rxp_align;
i_usropt_in.rx.detect.rcvfis<=i_rxfis;
i_usropt_in.rx.detect.fistype<=i_rxfistype;
i_usropt_in.rx.detect.error.pcont<=i_rxp_err_pcont;
i_usropt_in.rx.detect.error.fistype<=i_rxfistype_error;
i_usropt_in.rx.detect.error.prmvt_count<=OR_reduce(i_rxprmtv_err_cnt);

i_usropt_in.rx.bufdata<=i_rxbuffer;
i_usropt_in.loopback<=p_in_ctrl.loopback;

i_usropt_in.dbuf.trnsize<=0;
i_usropt_in.dbuf.clk<='0';
i_usropt_in.dbuf.wused<=p_in_ctrl.dbuf_wuse;--//Разрешение записи данных в буфер dbuf
i_usropt_in.dbuf.wstart<='0';
i_usropt_in.dbuf.wen<=i_dbuf_status.rx.en;--//управление записью данных в dbuf
i_usropt_in.dbuf.wdone<=i_dbuf_status.rx.done;--//сигнализация о завершении вычитки данных
i_usropt_in.dbuf.wdone_clr<='0';

i_usropt_in.dbuf.rused<=p_in_ctrl.dbuf_ruse;--;
i_usropt_in.dbuf.rstart<='0';
i_usropt_in.dbuf.rdone<='0';
i_usropt_in.dbuf.rdone_clr<='0';
i_usropt_in.dbuf.ren<='0';
i_usropt_in.dbuf.din<=i_rxbuffer;
i_usropt_in.dbuf.dout<=i_rxbuffer;



i_usropt_in.reg_shadow<=i_reg_shadow;
i_usropt_in.action<=i_action;


i_usropt_in2.gtp_dbus<=i_usropt_in.gtp_dbus;
i_usropt_in2.tx<=i_usropt_in.tx;
i_usropt_in2.rx<=i_usropt_in.rx;

i_usropt_in3.gtp_dbus<=i_usropt_in.gtp_dbus;
i_usropt_in3.tx<=i_usropt_in.tx;
i_usropt_in3.rx<=i_usropt_in.rx;



--//#########################################
--//Детектирование ошибок
--//#########################################
--process
--begin
--    wait until p_in_ctrl.link_establish='1' and i_rxp_err_pcont='1';
--    ----//ОШИБКА!!! - передача данных без отправки примитва CONT
--    wait for 1.0 us;
--    --//Завершаем модеоирование.
--    p_SIM_STOP("Simulation of STOP: ERROR - i_rxp_err_pcont - Send Data Without primitiv CONT");
--
--    wait;
--end process;

process
begin
    wait until p_in_ctrl.link_establish='1' and i_rxfistype_error='1';

    wait for 0.5 us;
    --//Завершаем модеоирование.
    p_SIM_STOP("Simulation of STOP: ERROR - i_rxfistype_error");

    wait;
end process;

process
begin
    wait until p_in_ctrl.link_establish='1' and i_rxprmtv_err_cnt/=(i_rxprmtv_err_cnt'range => '0');

--      i_rxprmtv_err_cnt(i):='1'; --//ОШИБКА!!! - Кол-во примитива отправленых перед преимитивом CONT = 1. А должно быть минимум 2
--      i_rxprmtv_err_cnt(C_TCONT):='1'; --//ОШИБКА!!! - Принял в подряд больше 1 примитива CONT
--
    wait for 0.5 us;
    --//Завершаем модеоирование.
    p_SIM_STOP("Simulation of STOP: ERROR - i_rxprmtv_err_cnt");

    wait;
end process;




--//#########################################
--//Генератор data random
--//#########################################
process(p_in_rst,p_in_clk)
begin
  if p_in_rst='1' then
    i_txsrcambler<=srambler32_0(CONV_STD_LOGIC_VECTOR(16#5032#, 16));
  elsif p_in_clk'event and p_in_clk='1' then
    i_txsrcambler<=srambler32_0(i_txsrcambler(31 downto 16));
  end if;
end process;



--//#########################################
--//Синхронизация
--//#########################################
sim_sync: process(p_in_rst,p_in_clk)
begin
  if p_in_rst='1' then
      i_txalign_timer<=(others=>'0');
      i_txalign_start<='0';
  elsif p_in_clk'event and p_in_clk='1' then
    if i_txalign_timer_en='1' then
      if i_txalign_timer=CONV_STD_LOGIC_VECTOR(C_SIM_SATADEV_TMR_ALIGN-1, i_txalign_timer'length) then
        i_txalign_timer<=(others=>'0');
      else
        i_txalign_timer<=i_txalign_timer + 1;
      end if;

      if i_txalign_timer=CONV_STD_LOGIC_VECTOR(0, i_txalign_timer'length) or i_txalign_timer=CONV_STD_LOGIC_VECTOR(1, i_txalign_timer'length) or
         i_txalign_timer=CONV_STD_LOGIC_VECTOR(2, i_txalign_timer'length) or i_txalign_timer=CONV_STD_LOGIC_VECTOR(3, i_txalign_timer'length) then
        i_txalign_start<='1';
      else
        i_txalign_start<='0';
      end if;

    else
      i_txalign_timer<=(others=>'0');
      i_txalign_start<='0';
    end if;
  end if;
end process sim_sync;



--//#########################################
--//Эмуляция HDD - Прием данных
--//#########################################
--GTP: ШИНА ДАНЫХ=8bit
gen_dbus8 : if G_GTP_DBUS=8 generate
  sim_get : process(p_in_rst,p_in_clk)
  begin
    if p_in_rst='1' then
      for i in 0 to 2 loop
        sr_gtp_rxdata(i)<=(others=>'0');
        sr_gtp_rxcharisk(i)<='0';
      end loop;
    elsif p_in_clk'event and p_in_clk='1' then
        sr_gtp_rxdata<=p_in_gtp_rxdata(7 downto 0) & sr_gtp_rxdata(0 to 1);
        sr_gtp_rxcharisk<=p_in_gtp_rxcharisk(0) & sr_gtp_rxcharisk(0 to 1);
    end if;
  end process sim_get;
  i_rxd<=p_in_gtp_rxdata(7 downto 0) & sr_gtp_rxdata(0) & sr_gtp_rxdata(1) & sr_gtp_rxdata(2);
  i_rxcharisk<=p_in_gtp_rxcharisk(0) & sr_gtp_rxcharisk(0) & sr_gtp_rxcharisk(1) & sr_gtp_rxcharisk(2);
end generate gen_dbus8;


--GTP: ШИНА ДАНЫХ=16bit
gen_dbus16 : if G_GTP_DBUS=16 generate
  sim_get : process(p_in_rst,p_in_clk)
  begin
    if p_in_rst='1' then
      for i in 0 to 0 loop
        sr2_gtp_rxdata(i)<=(others=>'0');
        sr2_gtp_rxcharisk(i)<=(others=>'0');
      end loop;
    elsif p_in_clk'event and p_in_clk='1' then
        sr2_gtp_rxdata(0)<=p_in_gtp_rxdata(15 downto 0);
        sr2_gtp_rxcharisk(0)<=p_in_gtp_rxcharisk(1 downto 0);
    end if;
  end process sim_get;
  i_rxd<=p_in_gtp_rxdata(15 downto 8) & p_in_gtp_rxdata(7 downto 0) & sr2_gtp_rxdata(0)(15 downto 8) & sr2_gtp_rxdata(0)(7 downto 0);
  i_rxcharisk<=p_in_gtp_rxcharisk(1) & p_in_gtp_rxcharisk(0) & sr2_gtp_rxcharisk(0)(1) & sr2_gtp_rxcharisk(0)(0);
end generate gen_dbus16;



--//-----------------------------------------------
--//Ищем ошибки в пинимаемом потоке данных!!!
--//-----------------------------------------------
sim_rxerror: process(p_in_rst,p_in_clk)
variable rxp_cont : std_logic;
variable rxfis    : std_logic;
variable rxfis_en : std_logic;
--variable rxd_without_pcont_cnt: integer:=0;

variable rxprmtv_cnt     : TPrmtvCnt;
variable rxprmtv_det     : std_logic_vector(C_TALIGN to C_TDATA_EN):=(others=>'0');
variable rxprmtv_err_cnt : std_logic_vector(C_TALIGN to C_TDATA_EN):=(others=>'0');

begin
if p_in_rst='1' then
  rxp_cont:='0';
  for i in C_TALIGN to C_TDATA_EN loop
  rxprmtv_cnt(i):=0;
  rxprmtv_det(i):='0';
  rxprmtv_err_cnt(i):='0';
  i_rxprmtv_err_cnt(i)<='0';
  i_rxprmtv_det(i)<='0';
  i_rxprmtv_cnt(i)<=0;
  end loop;

--  rxd_without_pcont_cnt:=0;

  rxfis:='0';
  rxfis_en:='0';

  i_rxp_holda_cnt<=0;
  i_rxp_hold_cnt<=0;
  i_rcv_allname<=C_PNAME_STR(C_TNONE);
  i_rxp_err_pcont<='0';
  i_rxfis<='0';
  i_rxp_align<='0';
  i_rxp_cont<='0';

  i_rxfis_dcnt<=0;
  i_rxfis_dcnt_sync<=0;
  tst_rxp_cont<='0';
  tst_rxd_without_pcont_cnt<=0;
  rxd_without_pcont_cnt<=0;
  tst_rxfis_en<='0';

elsif p_in_clk'event and p_in_clk='1' then

  if    i_rxd=C_PDAT_ALIGN and i_rxcharisk=C_PDAT_TPRM then i_rcv_allname<=C_PNAME_STR(C_TALIGN); i_rxp_align<='1'; i_rxp_cont<='0';
    for i in C_TALIGN to C_TPMNAK loop
      rxprmtv_err_cnt(i):='0';
    end loop;

  elsif i_rxd=C_PDAT_SOF and i_rxcharisk=C_PDAT_TPRM then i_rcv_allname<=C_PNAME_STR(C_TSOF); rxp_cont:='0'; i_rxp_align<='0'; i_rxp_cont<='0';
    for i in C_TALIGN to C_TPMNAK loop
      if i=C_TSOF then
        rxprmtv_det(i):='1';
        rxprmtv_cnt(i):=rxprmtv_cnt(i) + 1;
      else
        rxprmtv_det(i):='0';
        rxprmtv_cnt(i):=0;
      end if;
      rxprmtv_err_cnt(i):='0';
    end loop;
    rxd_without_pcont_cnt<=0;
    rxfis_en:='1';
    rxfis:='1';

  elsif i_rxd=C_PDAT_EOF and i_rxcharisk=C_PDAT_TPRM then i_rcv_allname<=C_PNAME_STR(C_TEOF); rxp_cont:='0'; i_rxp_align<='0'; i_rxp_cont<='0';
    for i in C_TALIGN to C_TPMNAK loop
      if i=C_TEOF then
        rxprmtv_det(i):='1';
        rxprmtv_cnt(i):=rxprmtv_cnt(i) + 1;
      else
        rxprmtv_det(i):='0';
        rxprmtv_cnt(i):=0;
      end if;
      rxprmtv_err_cnt(i):='0';
    end loop;
    rxd_without_pcont_cnt<=0;
    rxfis_en:='0';
    rxfis:='0';

  elsif i_rxd=C_PDAT_DMAT and i_rxcharisk=C_PDAT_TPRM then i_rcv_allname<=C_PNAME_STR(C_TDMAT); rxp_cont:='0'; i_rxp_align<='0'; i_rxp_cont<='0';
    for i in C_TALIGN to C_TPMNAK loop
      if i=C_TDMAT then
        rxprmtv_det(i):='1';
        rxprmtv_cnt(i):=rxprmtv_cnt(i) + 1;
      else
        rxprmtv_det(i):='0';
        rxprmtv_cnt(i):=0;
      end if;
      rxprmtv_err_cnt(i):='0';
    end loop;
    rxd_without_pcont_cnt<=0;

  elsif i_rxd=C_PDAT_CONT and i_rxcharisk=C_PDAT_TPRM then i_rcv_allname<=C_PNAME_STR(C_TCONT); rxp_cont:='1'; i_rxp_align<='0'; i_rxp_cont<='1';
    for i in C_TALIGN to C_TPMNAK loop
      if rxprmtv_det(i)='1' then
        if rxprmtv_cnt(i)=1 then
          rxprmtv_err_cnt(i):='1'; --//ОШИБКА!!! - Кол-во примитива отправленых перед преимитивом CONT = 1. А должно быть минимум 2
        end if;
      end if;
    end loop;

    if rxprmtv_cnt(C_TCONT)>1 then
      rxprmtv_err_cnt(C_TCONT):='1'; --//ОШИБКА!!! - Принял в подряд больше 1 примитива CONT
    else
      rxprmtv_cnt(C_TCONT):=rxprmtv_cnt(C_TCONT) + 1;
    end if;
    rxd_without_pcont_cnt<=0;

  elsif i_rxd=C_PDAT_SYNC and i_rxcharisk=C_PDAT_TPRM then i_rcv_allname<=C_PNAME_STR(C_TSYNC); rxp_cont:='0'; i_rxp_align<='0'; i_rxp_cont<='0';
    for i in C_TALIGN to C_TPMNAK loop
      if i=C_TSYNC then
        rxprmtv_det(i):='1';
        rxprmtv_cnt(i):=rxprmtv_cnt(i) + 1;
      else
        rxprmtv_det(i):='0';
        rxprmtv_cnt(i):=0;
      end if;
      rxprmtv_err_cnt(i):='0';
    end loop;
    rxd_without_pcont_cnt<=0;
    rxfis_en:='0';
    rxfis:='0';

  elsif i_rxd=C_PDAT_HOLD and i_rxcharisk=C_PDAT_TPRM then i_rcv_allname<=C_PNAME_STR(C_THOLD); i_rxp_align<='0'; i_rxp_cont<='0';
    for i in C_TALIGN to C_TPMNAK loop
      if i=C_THOLD then
        rxprmtv_det(i):='1';
        rxprmtv_cnt(i):=rxprmtv_cnt(i) + 1;
      else
        rxprmtv_det(i):='0';
        rxprmtv_cnt(i):=0;
      end if;
      rxprmtv_err_cnt(i):='0';
    end loop;

    i_rxp_holda_cnt<=0;
    if rxfis='1' then
        if (i_rxp_hold_cnt=2 and rxp_cont='1') or i_rxp_hold_cnt>3 then
          rxfis_en:='1';
        else
          rxfis_en:='0';
          i_rxp_hold_cnt<=i_rxp_hold_cnt + 1;
        end if;
    else
      rxfis_en:='0';
      i_rxp_hold_cnt<=0;
    end if;
    rxd_without_pcont_cnt<=0;
    rxp_cont:='0';

  elsif i_rxd=C_PDAT_HOLDA   and i_rxcharisk=C_PDAT_TPRM then i_rcv_allname<=C_PNAME_STR(C_THOLDA);  i_rxp_align<='0'; i_rxp_cont<='0';
    for i in C_TALIGN to C_TPMNAK loop
      if i=C_THOLDA then
        rxprmtv_det(i):='1';
        rxprmtv_cnt(i):=rxprmtv_cnt(i) + 1;
      else
        rxprmtv_det(i):='0';
        rxprmtv_cnt(i):=0;
      end if;
      rxprmtv_err_cnt(i):='0';
    end loop;

    i_rxp_hold_cnt<=0;
    if rxfis='1' then
        if (i_rxp_holda_cnt=2 and rxp_cont='1') or i_rxp_holda_cnt>3 then
          rxfis_en:='1';
        else
          rxfis_en:='0';
          i_rxp_holda_cnt<=i_rxp_holda_cnt + 1;
        end if;
    else
      rxfis_en:='0';
      i_rxp_holda_cnt<=0;
    end if;
    rxd_without_pcont_cnt<=0;
    rxp_cont:='0';

  elsif i_rxd=C_PDAT_X_RDY   and i_rxcharisk=C_PDAT_TPRM then i_rcv_allname<=C_PNAME_STR(C_TX_RDY); rxp_cont:='0'; i_rxp_align<='0'; i_rxp_cont<='0';
    for i in C_TALIGN to C_TPMNAK loop
      if i=C_TX_RDY then
        rxprmtv_det(i):='1';
        rxprmtv_cnt(i):=rxprmtv_cnt(i) + 1;
      else
        rxprmtv_det(i):='0';
        rxprmtv_cnt(i):=0;
      end if;
      rxprmtv_err_cnt(i):='0';
    end loop;
    rxd_without_pcont_cnt<=0;

  elsif i_rxd=C_PDAT_R_RDY   and i_rxcharisk=C_PDAT_TPRM then i_rcv_allname<=C_PNAME_STR(C_TR_RDY); rxp_cont:='0'; i_rxp_align<='0'; i_rxp_cont<='0';
    for i in C_TALIGN to C_TPMNAK loop
      if i=C_TR_RDY then
        rxprmtv_det(i):='1';
        rxprmtv_cnt(i):=rxprmtv_cnt(i) + 1;
      else
        rxprmtv_det(i):='0';
        rxprmtv_cnt(i):=0;
      end if;
      rxprmtv_err_cnt(i):='0';
    end loop;
    rxd_without_pcont_cnt<=0;

  elsif i_rxd=C_PDAT_R_IP    and i_rxcharisk=C_PDAT_TPRM then i_rcv_allname<=C_PNAME_STR(C_TR_IP); rxp_cont:='0'; i_rxp_align<='0'; i_rxp_cont<='0';
    for i in C_TALIGN to C_TPMNAK loop
      if i=C_TR_IP then
        rxprmtv_det(i):='1';
        rxprmtv_cnt(i):=rxprmtv_cnt(i) + 1;
      else
        rxprmtv_det(i):='0';
        rxprmtv_cnt(i):=0;
      end if;
      rxprmtv_err_cnt(i):='0';
    end loop;
    rxd_without_pcont_cnt<=0;

  elsif i_rxd=C_PDAT_R_OK    and i_rxcharisk=C_PDAT_TPRM then i_rcv_allname<=C_PNAME_STR(C_TR_OK); rxp_cont:='0'; i_rxp_align<='0'; i_rxp_cont<='0';
    for i in C_TALIGN to C_TPMNAK loop
      if i=C_TR_OK then
        rxprmtv_det(i):='1';
        rxprmtv_cnt(i):=rxprmtv_cnt(i) + 1;
      else
        rxprmtv_det(i):='0';
        rxprmtv_cnt(i):=0;
      end if;
      rxprmtv_err_cnt(i):='0';
    end loop;
    rxd_without_pcont_cnt<=0;

  elsif i_rxd=C_PDAT_R_ERR   and i_rxcharisk=C_PDAT_TPRM then i_rcv_allname<=C_PNAME_STR(C_TR_ERR); rxp_cont:='0'; i_rxp_align<='0'; i_rxp_cont<='0';
    for i in C_TALIGN to C_TPMNAK loop
      if i=C_TR_ERR then
        rxprmtv_det(i):='1';
        rxprmtv_cnt(i):=rxprmtv_cnt(i) + 1;
      else
        rxprmtv_det(i):='0';
        rxprmtv_cnt(i):=0;
      end if;
      rxprmtv_err_cnt(i):='0';
    end loop;
    rxd_without_pcont_cnt<=0;

  elsif i_rxd=C_PDAT_WTRM    and i_rxcharisk=C_PDAT_TPRM then i_rcv_allname<=C_PNAME_STR(C_TWTRM); rxp_cont:='0'; i_rxp_align<='0'; i_rxp_cont<='0';
    for i in C_TALIGN to C_TPMNAK loop
      if i=C_TWTRM then
        rxprmtv_det(i):='1';
        rxprmtv_cnt(i):=rxprmtv_cnt(i) + 1;
      else
        rxprmtv_det(i):='0';
        rxprmtv_cnt(i):=0;
      end if;
      rxprmtv_err_cnt(i):='0';
    end loop;
    rxd_without_pcont_cnt<=0;

  elsif i_rxd=C_PDAT_PMREQ_P and i_rxcharisk=C_PDAT_TPRM then i_rcv_allname<=C_PNAME_STR(C_TPMREQ_P); rxp_cont:='0'; i_rxp_align<='0'; i_rxp_cont<='0';
    for i in C_TALIGN to C_TPMNAK loop
      if i=C_TPMREQ_P then
        rxprmtv_det(i):='1';
        rxprmtv_cnt(i):=rxprmtv_cnt(i) + 1;
      else
        rxprmtv_det(i):='0';
        rxprmtv_cnt(i):=0;
      end if;
      rxprmtv_err_cnt(i):='0';
    end loop;
    rxd_without_pcont_cnt<=0;

  elsif i_rxd=C_PDAT_PMREQ_S and i_rxcharisk=C_PDAT_TPRM then i_rcv_allname<=C_PNAME_STR(C_TPMREQ_S); rxp_cont:='0'; i_rxp_align<='0'; i_rxp_cont<='0';
    for i in C_TALIGN to C_TPMNAK loop
      if i=C_TPMREQ_S then
        rxprmtv_det(i):='1';
        rxprmtv_cnt(i):=rxprmtv_cnt(i) + 1;
      else
        rxprmtv_det(i):='0';
        rxprmtv_cnt(i):=0;
      end if;
      rxprmtv_err_cnt(i):='0';
    end loop;
    rxd_without_pcont_cnt<=0;

  elsif i_rxd=C_PDAT_PMACK   and i_rxcharisk=C_PDAT_TPRM then i_rcv_allname<=C_PNAME_STR(C_TPMACK); rxp_cont:='0'; i_rxp_align<='0'; i_rxp_cont<='0';
    for i in C_TALIGN to C_TPMNAK loop
      if i=C_TPMACK then
        rxprmtv_det(i):='1';
        rxprmtv_cnt(i):=rxprmtv_cnt(i) + 1;
      else
        rxprmtv_det(i):='0';
        rxprmtv_cnt(i):=0;
      end if;
      rxprmtv_err_cnt(i):='0';
    end loop;
    rxd_without_pcont_cnt<=0;

  elsif i_rxd=C_PDAT_PMNAK   and i_rxcharisk=C_PDAT_TPRM then i_rcv_allname<=C_PNAME_STR(C_TPMNAK); rxp_cont:='0'; i_rxp_align<='0'; i_rxp_cont<='0';
    for i in C_TALIGN to C_TPMNAK loop
      if i=C_TPMNAK then
        rxprmtv_det(i):='1';
        rxprmtv_cnt(i):=rxprmtv_cnt(i) + 1;
      else
        rxprmtv_det(i):='0';
        rxprmtv_cnt(i):=0;
      end if;
      rxprmtv_err_cnt(i):='0';
    end loop;
    rxd_without_pcont_cnt<=0;

  elsif i_rxd=C_D10_2&C_D10_2&C_D10_2&C_D10_2 and i_rxcharisk=C_PDAT_TDATA then i_rcv_allname<=C_PNAME_STR(C_TD10_2); rxp_cont:='0'; i_rxp_align<='0'; i_rxp_cont<='0';
    for i in C_TALIGN to C_TPMNAK loop
        rxprmtv_det(i):='0';
        rxprmtv_cnt(i):=0;
        rxprmtv_err_cnt(i):='0';
    end loop;
    i_rxp_err_pcont<='0';
    rxd_without_pcont_cnt<=0;

  elsif i_rxcharisk=C_PDAT_TDATA then i_rcv_allname<=C_PNAME_STR(C_TDATA_EN);  i_rxp_align<='0'; i_rxp_cont<='0';
    for i in C_TALIGN to C_TPMNAK loop
        rxprmtv_det(i):='0';
        rxprmtv_cnt(i):=0;
        rxprmtv_err_cnt(i):='0';
    end loop;

      if rxfis_en='1' then
      --//Прием FIS
         i_rxp_hold_cnt<=0;
         i_rxp_holda_cnt<=0;
         i_rxp_err_pcont<='0';

      else
          if tst_rxp_cont='0' then
            if rxd_without_pcont_cnt>=1 then
              i_rxp_err_pcont<='1'; --//ОШИБКА!!! - передача данных без отправки примитва CONT
            else
              i_rxp_err_pcont<='0';
              rxd_without_pcont_cnt<=rxd_without_pcont_cnt + 1;
            end if;
          else
            i_rxp_err_pcont<='0';
            rxd_without_pcont_cnt<=0;
          end if;
      end if;

  end if;

  i_rxprmtv_err_cnt<=rxprmtv_err_cnt;
  i_rxprmtv_det<=rxprmtv_det;
  i_rxprmtv_cnt<=rxprmtv_cnt;

  tst_rxfis_en<=rxfis_en;
  tst_rxp_cont<=rxp_cont;
  tst_rxd_without_pcont_cnt<=rxd_without_pcont_cnt;

  i_rxfis<=rxfis;
  if i_rxfis='1' then
    if i_rxfis_dcnt_sync=4 then
      i_rxfis_dcnt<=i_rxfis_dcnt+1;
      i_rxfis_dcnt_sync<=0;
    else
      i_rxfis_dcnt_sync<=i_rxfis_dcnt_sync + 1;
    end if;
  else
    i_rxfis_dcnt_sync<=0;
    i_rxfis_dcnt<=0;
  end if;

end if;
end process sim_rxerror;

--process(p_in_rst,p_in_clk)
--begin
--if p_in_rst='1' then
--elsif p_in_clk'event and p_in_clk='1' then
--  if i_rxcharisk=C_PDAT_TDATA then
--
--      if i_rxfis='1' then
--      --//Прием FIS
--         i_rxp_hold_cnt<=0;
--         i_rxp_err_pcont<='0';
--
--      else
--          if tst_rxp_cont='0' then
--            if rxd_without_pcont_cnt>=1 then
--              i_rxp_err_pcont<='1'; --//ОШИБКА!!! - передача данных без отправки примитва CONT
--            else
--              i_rxp_err_pcont<='0';
--              rxd_without_pcont_cnt<=rxd_without_pcont_cnt + 1;
--            end if;
--          else
--            i_rxp_err_pcont<='0';
--            rxd_without_pcont_cnt<=0;
--          end if;
--      end if;
--
--  end if;
--end if;
--end process;

--//---------------------------------------
--//Примем данных FIS
--//---------------------------------------
sim_rxfis: process(p_in_rst,p_in_clk)
variable rxp_cont : std_logic:='0';
variable rxp_dname_save : string(1 to 7):=C_PNAME_STR(C_TNONE);

variable rxsrcambler : std_logic_vector(31 downto 0):=(others=>'0');
variable rxcrc_calc  : std_logic_vector(31 downto 0):=(others=>'0');
variable rxd_out     : std_logic_vector(31 downto 0):=(others=>'0');
variable fh2d_cbit   : std_logic:='0';

variable string_value : std_logic_vector(3 downto 0);
variable GUI_line : LINE;--Строка дл_ вывода в ModelSim

begin
if p_in_rst='1' then
  rxp_cont:='0';
  rxp_dname_save:=C_PNAME_STR(C_TNONE);
  rxsrcambler:=(others=>'0');
  rxcrc_calc:=(others=>'0');
  rxd_out:=(others=>'0');
  fh2d_cbit:='0';

  i_rxd_out<=(others=>'0');
  i_rxd_sync<=(others=>'0');
  for i in 0 to sr_rxcrc_calc'high loop
  sr_rxcrc_calc(i)<=(others=>'0');
  end loop;
  i_rxp_sof<='0';
  i_rxp_eof<='0';
  i_rxdw_cnt<=0;
  i_rxfistype.h2d<='0';
  i_rxfistype.data<='0';
  i_rxfistype_error<='0';
  i_rxfis_type_cheked<='0';

  for i in 0 to i_rxbuffer'high loop
  i_rxbuffer(i)<=(others=>'0');
  end loop;

  i_reg_shadow.command<=(others=>'0');
  i_reg_shadow.status(C_REG_ATA_STATUS_BUSY_BIT-1 downto 0)<=(others=>'0');
  i_reg_shadow.status(C_REG_ATA_STATUS_BUSY_BIT)<='1';
  i_reg_shadow.error<=(others=>'0');
  i_reg_shadow.device<=(others=>'0');
  i_reg_shadow.control<=(others=>'0');
  i_reg_shadow.lba_low<=(others=>'0');
  i_reg_shadow.lba_low_exp<=(others=>'0');
  i_reg_shadow.lba_mid<=(others=>'0');
  i_reg_shadow.lba_mid_exp<=(others=>'0');
  i_reg_shadow.lba_high<=(others=>'0');
  i_reg_shadow.lba_high_exp<=(others=>'0');
  i_reg_shadow.scount<=(others=>'0');
  i_reg_shadow.scount_exp<=(others=>'0');
  i_reg_shadow.feature<=(others=>'0');
  i_reg_shadow.feature_exp<=(others=>'0');

  i_action.ata_command<='0';
  i_action.ata_control<='0';
  i_action.dir<='0';
  i_action.piomode<='0';
  i_action.dmamode<='0';

  i_usropt_in2.console_on<=0;
  i_rxbuffer_cnt_en<='0';
  i_rxbuffer_cnt<=0;
--  i_dbuf_wr<='0';

elsif p_in_clk'event and p_in_clk='1' then

--  if    i_rxd=C_PDAT_ALIGN   and i_rxcharisk=C_PDAT_TPRM then i_rcv_name<=C_PNAME_STR(C_TALIGN);
  if    i_rxd=C_PDAT_SOF     and i_rxcharisk=C_PDAT_TPRM then i_rxp_eof<='0'; rxp_cont:='0'; i_rcv_name<=C_PNAME_STR(C_TSOF); rxp_dname_save:=C_PNAME_STR(C_TSOF);
    rxcrc_calc:=CONV_STD_LOGIC_VECTOR(16#52325032#, rxcrc_calc'length);
    rxsrcambler:=srambler32_0(CONV_STD_LOGIC_VECTOR(16#F0F6#, 16));
    i_rxd_sync<=(others=>'0');
    i_rxp_eof<='0';
    i_rxp_sof<='1';
    i_rxdw_cnt<=0;

    i_rxfistype.h2d<='0';
    i_rxfistype.data<='0';
    i_rxfistype_error<='0';

    i_rxfis_type_cheked<='0';

    i_action.ata_command<='0';
    i_action.ata_control<='0';

  elsif i_rxd=C_PDAT_EOF     and i_rxcharisk=C_PDAT_TPRM then i_rxp_sof<='0'; rxp_cont:='0'; i_rcv_name<=C_PNAME_STR(C_TEOF); rxp_dname_save:=C_PNAME_STR(C_TEOF);
    i_rxp_eof<='1';
    i_rxbuffer_cnt_en<='0';

    if i_rxfistype.h2d='1' then
      if fh2d_cbit='1' then
        i_action.ata_command<='1';
        i_action.ata_control<='0';

      else
        i_action.ata_command<='0';
        i_action.ata_control<='1';
      end if;
    end if;

  elsif i_rxd=C_PDAT_DMAT    and i_rxcharisk=C_PDAT_TPRM then i_rxp_sof<='0'; rxp_cont:='0'; i_rcv_name<=C_PNAME_STR(C_TDMAT); rxp_dname_save:=C_PNAME_STR(C_TDMAT);

  elsif i_rxd=C_PDAT_CONT    and i_rxcharisk=C_PDAT_TPRM then i_rxp_sof<='0'; rxp_cont:='1'; i_rcv_name<=rxp_dname_save; --i_rcv_name<=C_PNAME_STR(C_TCONT);

  elsif i_rxd=C_PDAT_SYNC    and i_rxcharisk=C_PDAT_TPRM then i_rxp_sof<='0'; rxp_cont:='0'; i_rcv_name<=C_PNAME_STR(C_TSYNC); rxp_dname_save:=C_PNAME_STR(C_TSYNC);
    i_rxp_eof<='0';
    i_rxfistype.h2d<='0';
    i_rxfistype.data<='0';
    i_rxfis_type_cheked<='0';
    i_usropt_in2.console_on<=1;

  elsif i_rxd=C_PDAT_HOLD    and i_rxcharisk=C_PDAT_TPRM then               rxp_cont:='0'; i_rcv_name<=C_PNAME_STR(C_THOLD); rxp_dname_save:=C_PNAME_STR(C_THOLD);
  elsif i_rxd=C_PDAT_HOLDA   and i_rxcharisk=C_PDAT_TPRM then i_rxp_sof<='0'; rxp_cont:='0'; i_rcv_name<=C_PNAME_STR(C_THOLDA); rxp_dname_save:=C_PNAME_STR(C_THOLDA);
  elsif i_rxd=C_PDAT_X_RDY   and i_rxcharisk=C_PDAT_TPRM then i_rxp_sof<='0'; rxp_cont:='0'; i_rcv_name<=C_PNAME_STR(C_TX_RDY); rxp_dname_save:=C_PNAME_STR(C_TX_RDY);
  elsif i_rxd=C_PDAT_R_RDY   and i_rxcharisk=C_PDAT_TPRM then i_rxp_sof<='0'; rxp_cont:='0'; i_rcv_name<=C_PNAME_STR(C_TR_RDY); rxp_dname_save:=C_PNAME_STR(C_TR_RDY);
  elsif i_rxd=C_PDAT_R_IP    and i_rxcharisk=C_PDAT_TPRM then i_rxp_sof<='0'; rxp_cont:='0'; i_rcv_name<=C_PNAME_STR(C_TR_IP); rxp_dname_save:=C_PNAME_STR(C_TR_IP);
  elsif i_rxd=C_PDAT_R_OK    and i_rxcharisk=C_PDAT_TPRM then i_rxp_sof<='0'; rxp_cont:='0'; i_rcv_name<=C_PNAME_STR(C_TR_OK); rxp_dname_save:=C_PNAME_STR(C_TR_OK);
  elsif i_rxd=C_PDAT_R_ERR   and i_rxcharisk=C_PDAT_TPRM then i_rxp_sof<='0'; rxp_cont:='0'; i_rcv_name<=C_PNAME_STR(C_TR_ERR); rxp_dname_save:=C_PNAME_STR(C_TR_ERR);
  elsif i_rxd=C_PDAT_WTRM    and i_rxcharisk=C_PDAT_TPRM then i_rxp_sof<='0'; rxp_cont:='0'; i_rcv_name<=C_PNAME_STR(C_TWTRM); rxp_dname_save:=C_PNAME_STR(C_TWTRM);
  elsif i_rxd=C_PDAT_PMREQ_P and i_rxcharisk=C_PDAT_TPRM then i_rxp_sof<='0'; rxp_cont:='0'; i_rcv_name<=C_PNAME_STR(C_TPMREQ_P); rxp_dname_save:=C_PNAME_STR(C_TPMREQ_P);
  elsif i_rxd=C_PDAT_PMREQ_S and i_rxcharisk=C_PDAT_TPRM then i_rxp_sof<='0'; rxp_cont:='0'; i_rcv_name<=C_PNAME_STR(C_TPMREQ_S); rxp_dname_save:=C_PNAME_STR(C_TPMREQ_S);
  elsif i_rxd=C_PDAT_PMACK   and i_rxcharisk=C_PDAT_TPRM then i_rxp_sof<='0'; rxp_cont:='0'; i_rcv_name<=C_PNAME_STR(C_TPMACK); rxp_dname_save:=C_PNAME_STR(C_TPMACK);
  elsif i_rxd=C_PDAT_PMNAK   and i_rxcharisk=C_PDAT_TPRM then i_rxp_sof<='0'; rxp_cont:='0'; i_rcv_name<=C_PNAME_STR(C_TPMNAK); rxp_dname_save:=C_PNAME_STR(C_TPMNAK);

  elsif i_rxd=C_D10_2&C_D10_2&C_D10_2&C_D10_2 and i_rxcharisk=C_PDAT_TDATA then
    i_rxd_sync<=(others=>'0');
    i_rxp_eof<='0';
    i_rxp_sof<='1';
    i_rxdw_cnt<=0;

    i_rxfistype.h2d<='0';
    i_rxfistype.data<='0';
    i_rxfistype_error<='0';

    i_rxfis_type_cheked<='0';

    i_action.ata_command<='0';
    i_action.ata_control<='0';

  elsif  rxp_cont='0'         and i_rxcharisk=C_PDAT_TDATA then i_rcv_name<=C_PNAME_STR(C_TDATA_EN);

    if i_rxd_sync=(i_rxd_sync'range =>'1') then
        --//------------------------------
        --//Декодирование и подсчет CRC принятых данных
        --//------------------------------
        --//Де-Скремблирование данных
        for x in 0 to 31 loop
        i_rxd_out(x)<=i_rxd(x) xor rxsrcambler(x);
        rxd_out(x):=i_rxd(x) xor rxsrcambler(x);
        end loop;
        --//Расчет CRC
        rxcrc_calc:=crc32_0( rxd_out, rxcrc_calc);

        --//Расператка принятых данных
        p_print_txrxd(i_rxd, rxsrcambler, rxcrc_calc, rxd_out, i_usropt_in2);
--        p_print_txrxd(i_rxd, rxsrcambler, sr_rxcrc_calc(1), i_rxd_out, i_usropt_in2);

        --//Инкрементация скремблера
        rxsrcambler:=srambler32_0(rxsrcambler(31 downto 16));
        sr_rxcrc_calc<=rxcrc_calc & sr_rxcrc_calc(0 to 0);

        --//------------------------------
        --//Аализ принятых данных
        --//------------------------------
        if i_rxfis_type_cheked='0' then
        --//Определяем тип принимаемого FIS
            if rxd_out(7 downto 0)=CONV_STD_LOGIC_VECTOR(C_FIS_REG_HOST2DEV, 8) then
              i_rxfistype.h2d<='1';
              i_rxfistype.data<='0';
              i_rxfistype_error<='0';
            elsif rxd_out(7 downto 0)=CONV_STD_LOGIC_VECTOR(C_FIS_DATA, 8) then
              i_rxfistype.h2d<='0';
              i_rxfistype.data<='1';
              i_rxfistype_error<='0';
            else
              i_rxfistype.h2d<='0';
              i_rxfistype.data<='0';
              i_rxfistype_error<='1';
            end if;
        else
          if i_rxfistype.h2d='1' then
          --//Примем FIS_HOST2DEV
            if i_rxdw_cnt=0 then
              fh2d_cbit:=i_rxd_out(8*1+7);

              if fh2d_cbit='1' then
              i_reg_shadow.command<=i_rxd_out(8*(2+1)-1 downto 8*2);

                if i_rxd_out(8*(2+1)-1 downto 8*2)=CONV_STD_LOGIC_VECTOR(C_ATA_CMD_WRITE_SECTORS_EXT, 8) or
                   i_rxd_out(8*(2+1)-1 downto 8*2)=CONV_STD_LOGIC_VECTOR(C_ATA_CMD_READ_SECTORS_EXT, 8) then
                    if i_rxd_out(8*(2+1)-1 downto 8*2)=CONV_STD_LOGIC_VECTOR(C_ATA_CMD_WRITE_SECTORS_EXT, 8) then
                      i_action.dir<=C_DIR_H2D;
                    else
                      i_action.dir<=C_DIR_D2H;
                    end if;
                    i_action.piomode<='1';
                    i_action.dmamode<='0';

                elsif i_rxd_out(8*(2+1)-1 downto 8*2)=CONV_STD_LOGIC_VECTOR(C_ATA_CMD_WRITE_DMA_EXT, 8) or
                      i_rxd_out(8*(2+1)-1 downto 8*2)=CONV_STD_LOGIC_VECTOR(C_ATA_CMD_READ_DMA_EXT, 8) then
                    if i_rxd_out(8*(2+1)-1 downto 8*2)=CONV_STD_LOGIC_VECTOR(C_ATA_CMD_WRITE_DMA_EXT, 8) then
                      i_action.dir<=C_DIR_H2D;
                    else
                      i_action.dir<=C_DIR_D2H;
                    end if;
                    i_action.piomode<='0';
                    i_action.dmamode<='1';

                else
                  i_action.piomode<='0';
                  i_action.dmamode<='0';
                end if;
              end if;

              i_reg_shadow.feature<=i_rxd_out(8*(3+1)-1 downto 8*3);

            elsif i_rxdw_cnt=1 then
              i_reg_shadow.lba_low<=i_rxd_out(8*(0+1)-1 downto 8*0);
              i_reg_shadow.lba_mid<=i_rxd_out(8*(1+1)-1 downto 8*1);
              i_reg_shadow.lba_high<=i_rxd_out(8*(2+1)-1 downto 8*2);
              i_reg_shadow.device<=i_rxd_out(8*(3+1)-1 downto 8*3);

            elsif i_rxdw_cnt=2 then
              i_reg_shadow.lba_low_exp<=i_rxd_out(8*(0+1)-1 downto 8*0);
              i_reg_shadow.lba_mid_exp<=i_rxd_out(8*(1+1)-1 downto 8*1);
              i_reg_shadow.lba_high_exp<=i_rxd_out(8*(2+1)-1 downto 8*2);
              i_reg_shadow.feature_exp<=i_rxd_out(8*(3+1)-1 downto 8*3);

            elsif i_rxdw_cnt=3 then
              i_reg_shadow.scount<=i_rxd_out(8*(0+1)-1 downto 8*0);
              i_reg_shadow.scount_exp<=i_rxd_out(8*(1+1)-1 downto 8*1);

              if fh2d_cbit='0' then
              i_reg_shadow.control<=i_rxd_out(8*(3+1)-1 downto 8*3);
              end if;

            end if;--//if i_rxdw_cnt

            i_rxdw_cnt<=i_rxdw_cnt + 1;

          elsif i_rxfistype.data='1' then
          --//Примем FIS_DATA

            i_rxbuffer_cnt_en<='1';
            i_rxdw_cnt<=i_rxdw_cnt + 1;

          end if;--//if i_rxfistype.h2d='1' then
        end if;--//if i_rxfis_type_cheked='0' then

        i_rxfis_type_cheked<='1';
    end if;

    i_rxd_sync<=i_rxd_sync + 1;

  end if;


  --//Запись данных FISDATA буфер приема
  if p_in_ctrl.atacmd_done='1' then
    i_rxbuffer_cnt<=0;
  elsif rxp_cont='0' and i_rxcharisk=C_PDAT_TDATA then
    if i_rxd_sync=(i_rxd_sync'range =>'1') then
      if i_rxfistype.data='1' then
        if i_rxbuffer_cnt_en='1' and p_in_ctrl.dbuf_wuse='0' then
          i_rxbuffer(i_rxbuffer_cnt)<=i_usropt_in.rx.fisdata;
          i_rxbuffer_cnt<=i_rxbuffer_cnt + 1;
        end if;
      end if;
    end if;
  end if;

end if;
end process sim_rxfis;




--//#########################################
--//Эмуляция HDD - Отправка данных данных
--//#########################################
gen_dbg_llayer_off : if strcmp(G_DBG_LLAYER,"OFF") generate

i_dbuf_wr<=OR_reduce(i_rxd_sync) and i_rxfistype.data and i_rxbuffer_cnt_en and p_in_ctrl.dbuf_wuse;

m_databuf : sata_sim_dbuf
port map
(
----------------------------
--
----------------------------
p_in_data    => i_usropt_in.rx.fisdata,
p_in_wr      => i_dbuf_wr,
p_in_wclk    => p_in_clk,

p_out_data   => tstdbuf_out,
p_in_rd      => p_in_tst(0),
p_in_rclk    => p_in_clk,

p_out_status => i_dbuf_status,
p_in_ctrl    => i_dbuf_ctrl,

--------------------------------------------------
--Технологические сигналы
--------------------------------------------------
p_in_tst     => "00000000000000000000000000000000",
p_out_tst    => open,

----------------------------
--System
----------------------------
p_in_rst  => p_in_rst
);

i_dbuf_ctrl.trnsize<=i_atacmd_dwcount;
i_dbuf_ctrl.clk<=i_usropt_out.dbuf.clk;
i_dbuf_ctrl.wused<=i_usropt_out.dbuf.wused;
i_dbuf_ctrl.wstart<=i_usropt_out.dbuf.wstart;
i_dbuf_ctrl.wdone<=i_usropt_out.dbuf.wdone;
i_dbuf_ctrl.wdone_clr<=i_usropt_out.dbuf.wdone_clr;
i_dbuf_ctrl.wen<=i_usropt_out.dbuf.wen;
i_dbuf_ctrl.rused<=i_usropt_out.dbuf.rused;
i_dbuf_ctrl.rstart<=i_usropt_out.dbuf.rstart;
i_dbuf_ctrl.rdone<=i_usropt_out.dbuf.rdone;
i_dbuf_ctrl.rdone_clr<=i_usropt_out.dbuf.rdone_clr;
i_dbuf_ctrl.ren<=i_usropt_out.dbuf.ren;
i_dbuf_ctrl.din<=i_usropt_out.dbuf.din;
i_dbuf_ctrl.dout<=i_usropt_out.dbuf.dout;

i_atacmd_scount<=i_reg_shadow.scount_exp&i_reg_shadow.scount;
i_atacmd_dwcount<=CONV_INTEGER(i_atacmd_scount)*C_SIM_SECTOR_SIZE_DWORD;

sim_send1: process

  variable txsrcambler : std_logic_vector(31 downto 0);
  variable txcrc       : std_logic_vector(31 downto 0);
  variable txd         : TSimBufData;                     --//Массиив данных для передачи
  variable txd_out     : std_logic_vector(31 downto 0);--//Скремблировыные данные
  variable txfis_size  : integer;
  variable txdata_size_byte : integer;
  variable txcomp_cnt  : integer;--//Счетчик по значению которого отправляем примитив CONT

  variable usr_dwsize : integer;

  --variable fis_data : TFIS_DATA;
  variable fis_d2h           : TFIS_D2H;
  variable fis_pioSetup      : TFIS_PIOSETUP;
  variable fis_dmaSetup      : TFIS_DMASETUP;
  variable fis_dmaActivate   : TFIS_DMA_Activate;
  variable fis_SetDeviceBits : TFIS_SetDeviceBits;
  variable fis_BISTActivate  : TFIS_BIST_Activate;

  variable usropt : TInUsrOpt;

  variable vusropt     : TOutUsrOpt;
  variable string_value : std_logic_vector(3 downto 0);
  variable GUI_line : LINE;--Строка дл_ вывода в ModelSim


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


  p_out_gtp_txdata <=(others=>'0');
  p_out_gtp_txcharisk<=(others=>'0');
  i_txalign_timer_en<='0';
  i_rxalign_det<='0';

  txcomp_cnt:=0;

  i_usropt_in3.console_on<=0;--//1/0 - выодить/не выводить в консоль распечатку данных генерации i_crc_checking
  i_crc_checking<=(others=>'0');

  usr_dwsize:=8;

  wait for 5.5 us;

  write(GUI_line,string'("CHECKING: Start"));writeline(output, GUI_line);
  txcrc:=CONV_STD_LOGIC_VECTOR(16#52325032#, txcrc'length);
  txsrcambler:=srambler32_0(CONV_STD_LOGIC_VECTOR(16#F0F6#, 16));

  txfis_size:=usr_dwsize;--
  txd(0):=(others=>'0');
  txd(0)(8*(0+1)-1 downto 8*0):=CONV_STD_LOGIC_VECTOR(C_FIS_DATA, 8);
  for i in 1 to txfis_size loop
  --//Заполняем данные счетчиком (BYTE)
  txd(i)(8*(3+1)-1 downto 8*0):=CONV_STD_LOGIC_VECTOR(i, 32);
  end loop;

  for i in 0 to txfis_size loop
  --//Скремблирование данных
  for x in 0 to 31 loop
  txd_out(x):=txd(i)(x) xor txsrcambler(x);
  end loop;
  --//Расчет CRC
  txcrc:=crc32_0(txd(i), txcrc);
  --//Вывод данных в консоль ModelSim
  p_print_txrxd(txd(i), txsrcambler, txcrc, txd_out, i_usropt_in3);
  --//Инкрементация скремблера
  txsrcambler:=srambler32_0(txsrcambler(31 downto 16));
  end loop;

  --//Скремблирование данных
  for x in 0 to 31 loop
  txd_out(x):=txcrc(x) xor txsrcambler(x);
  end loop;
  p_print_txrxd(txcrc, txsrcambler, txcrc, txd_out, i_usropt_in3);

  i_crc_checking<=txcrc;

  writeline(output, GUI_line);

  write(GUI_line,string'("CHECKING: Done."));writeline(output, GUI_line);
  write(GUI_line,string'(" "));writeline(output, GUI_line);
  txcrc:=CONV_STD_LOGIC_VECTOR(16#52325032#, txcrc'length);
  txsrcambler:=srambler32_0(CONV_STD_LOGIC_VECTOR(16#F0F6#, 16));



  --//--------------------------------
  --//Установка соединения
  --//--------------------------------
  while i_rcv_allname/="ALIGN  " loop
    p_SetData(p_in_clk,
              C_PDAT_ALIGN, C_CHAR_K,
              p_out_gtp_txdata, p_out_gtp_txcharisk,
              i_usropt_in, vusropt, i_usropt_out);
  end loop;

  for i in 0 to 7 loop
    p_SetData(p_in_clk,
              C_PDAT_ALIGN, C_CHAR_K,
              p_out_gtp_txdata, p_out_gtp_txcharisk,
              i_usropt_in, vusropt, i_usropt_out);
  end loop;

  i_rxalign_det<='1';

  for i in 0 to 2 loop
    p_SetData(p_in_clk,
              C_PDAT_SYNC, C_CHAR_K,
              p_out_gtp_txdata, p_out_gtp_txcharisk,
              i_usropt_in, vusropt, i_usropt_out);
  end loop;
  p_SetData(p_in_clk,
            C_PDAT_CONT, C_CHAR_K,
            p_out_gtp_txdata, p_out_gtp_txcharisk,
            i_usropt_in, vusropt, i_usropt_out);

  i_txalign_timer_en<='1';

  write(GUI_line,string'("Wait ESTABLISH ...."));writeline(output, GUI_line);
  while i_rcv_name/="SYNC   " loop
      p_SetData(p_in_clk,
                i_txsrcambler, C_CHAR_D,
                p_out_gtp_txdata, p_out_gtp_txcharisk,
                i_usropt_in, vusropt, i_usropt_out);
  end loop;

  write(GUI_line,string'("ESTABLISH - OK!"));writeline(output, GUI_line);



  --//--------------------------------
  --//Отправка данных: FIS_DEV2HOST (Signature)
  --//--------------------------------
  --//Инициализация FIS:
  txfis_size:=C_FIS_D2H_SIGNATURE'high;
  for i in 0 to txfis_size loop
  txd(i):=C_FIS_D2H_SIGNATURE(i);
  end loop;
  write(GUI_line,string'("FPGA<-HDD(Signature): Begin"));writeline(output, GUI_line);
  p_SendFIS(p_in_clk,
            txd, txfis_size,
            p_out_gtp_txdata, p_out_gtp_txcharisk,
            i_usropt_in,i_usropt_out);
  write(GUI_line,string'("FPGA<-HDD(Signature): End"));writeline(output, GUI_line);


  p_SetSYNC(p_in_clk,
            p_out_gtp_txdata, p_out_gtp_txcharisk,
            i_usropt_in, i_usropt_out);



  lcmdwork : for idx in 0 to C_SIM_COUNT-1 loop
  --//--------------------------------
  --//Прием : FIS_HOST2DEV (получаем команду от хоста)
  --//--------------------------------
  write(GUI_line,string'("FIS_HOST2DEV /Rcv Start."));writeline(output, GUI_line);
  p_GetFIS(p_in_clk,
           p_out_gtp_txdata, p_out_gtp_txcharisk,
           i_usropt_in,i_usropt_out);
  write(GUI_line,string'("FIS_HOST2DEV /Rcv Done."));writeline(output, GUI_line);

  p_SetSYNC(p_in_clk,
            p_out_gtp_txdata, p_out_gtp_txcharisk,
            i_usropt_in, i_usropt_out);

  --//Отрабатываем принятую команду
  p_COMMAND_ACTIVATE(p_in_clk,
                     p_out_gtp_txdata, p_out_gtp_txcharisk,
                     i_usropt_in,i_usropt_out);

  end loop lcmdwork;

  p_SetSYNC(p_in_clk,
            p_out_gtp_txdata, p_out_gtp_txcharisk,
            i_usropt_in, i_usropt_out);

--  --//Завершаем модеоирование.
--  p_SIM_STOP("Simulation of SIMPLE complete");

  wait;
end process sim_send1;

end generate gen_dbg_llayer_off;




gen_dbg_llayer_on : if strcmp(G_DBG_LLAYER,"ON") generate


i_dbuf_status.rx.full<='0';
i_dbuf_status.rx.empty<='0';
i_dbuf_status.rx.done<='0';
i_dbuf_status.rx.en<='0';

i_dbuf_status.tx.full<='0';
i_dbuf_status.tx.empty<='0';
i_dbuf_status.tx.done<='0';
i_dbuf_status.tx.en<='0';


sim_send2: process

  variable txsrcambler : std_logic_vector(31 downto 0):=(others=>'0');
  variable txcrc       : std_logic_vector(31 downto 0):=(others=>'0');
  variable txd         : TSimBufData;
  variable txd_out     : std_logic_vector(31 downto 0):=(others=>'0');--//Скремблировыные данные
  variable txfis_size  : integer:=0;
  variable txdata_size_byte : integer:=0;
  variable txcomp_cnt  : integer:=0;--//Счетчик по значению которого отправляем примитив COMP
  variable txcomp_cnt1 : integer:=0;
  variable txcomp_cnt2 : integer:=0;
  variable txcomp_cnt3 : integer:=0;

  variable usr_dwsize : integer:=0;
  variable dcnt  : integer:=0;

  --variable fis_data          : TFIS_DATA;
  variable fis_d2h           : TFIS_D2H;
  variable fis_pioSetup      : TFIS_PIOSETUP;
  variable fis_dmaSetup      : TFIS_DMASETUP;
  variable fis_dmaActivate   : TFIS_DMA_Activate;
  variable fis_SetDeviceBits : TFIS_SetDeviceBits;
  variable fis_BISTActivate  : TFIS_BIST_Activate;

  variable usropt : TInUsrOpt;

  variable vusropt     : TOutUsrOpt;
  variable string_value : std_logic_vector(3 downto 0);
  variable GUI_line : LINE;--Строка дл_ вывода в ModelSim


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

  p_out_gtp_txdata <=(others=>'0');
  p_out_gtp_txcharisk<=(others=>'0');
  i_txalign_timer_en<='0';
  i_rxalign_det<='0';

  txcomp_cnt:=0;

  for i in 0 to txd'high loop
  txd(i):=(others=>'0');
  end loop;

  i_usropt_in3.console_on<=0;--//1/0 - выодить/не выводить в консоль распечатку данных генерации i_crc_checking
  i_crc_checking<=(others=>'0');

  usr_dwsize:=8;

  wait for 5.5 us;

  write(GUI_line,string'("CHECKING: Start"));writeline(output, GUI_line);
  txcrc:=CONV_STD_LOGIC_VECTOR(16#52325032#, txcrc'length);
  txsrcambler:=srambler32_0(CONV_STD_LOGIC_VECTOR(16#F0F6#, 16));

  txfis_size:=usr_dwsize;--
  txd(0):=(others=>'0');
  txd(0)(8*(0+1)-1 downto 8*0):=CONV_STD_LOGIC_VECTOR(C_FIS_DATA, 8);
  for i in 1 to txfis_size loop
  --//Заполняем данные счетчиком (DWORD)
  txd(i)(8*(3+1)-1 downto 8*0):=CONV_STD_LOGIC_VECTOR(i, 32);
  end loop;

  for i in 0 to txfis_size loop
  --//Скремблирование данных
  for x in 0 to 31 loop
  txd_out(x):=txd(i)(x) xor txsrcambler(x);
  end loop;
  --//Расчет CRC
  txcrc:=crc32_0(txd(i), txcrc);
  --//Вывод данных в консоль ModelSim
  p_print_txrxd(txd(i), txsrcambler, txcrc, txd_out, i_usropt_in3);
  --//Инкрементация скремблера
  txsrcambler:=srambler32_0(txsrcambler(31 downto 16));
  end loop;

  --//Скремблирование данных
  for x in 0 to 31 loop
  txd_out(x):=txcrc(x) xor txsrcambler(x);
  end loop;
  p_print_txrxd(txcrc, txsrcambler, txcrc, txd_out, i_usropt_in3);

  i_crc_checking<=txcrc;

  writeline(output, GUI_line);

  write(GUI_line,string'("CHECKING: Done."));writeline(output, GUI_line);
  write(GUI_line,string'(" "));writeline(output, GUI_line);
  txcrc:=CONV_STD_LOGIC_VECTOR(16#52325032#, txcrc'length);
  txsrcambler:=srambler32_0(CONV_STD_LOGIC_VECTOR(16#F0F6#, 16));



  --//--------------------------------
  --//Установка соединения
  --//--------------------------------
  while i_rcv_allname/="ALIGN  " loop
    p_SetData(p_in_clk,
              C_PDAT_ALIGN, C_CHAR_K,
              p_out_gtp_txdata, p_out_gtp_txcharisk,
              i_usropt_in, vusropt, i_usropt2_out);
  end loop;

  for i in 0 to 7 loop
    p_SetData(p_in_clk,
              C_PDAT_ALIGN, C_CHAR_K,
              p_out_gtp_txdata, p_out_gtp_txcharisk,
              i_usropt_in, vusropt, i_usropt2_out);
  end loop;

  i_rxalign_det<='1';

  for i in 0 to 2 loop
    p_SetData(p_in_clk,
              C_PDAT_SYNC, C_CHAR_K,
              p_out_gtp_txdata, p_out_gtp_txcharisk,
              i_usropt_in, vusropt, i_usropt2_out);
  end loop;
  p_SetData(p_in_clk,
            C_PDAT_CONT, C_CHAR_K,
            p_out_gtp_txdata, p_out_gtp_txcharisk,
            i_usropt_in, vusropt, i_usropt2_out);

  i_txalign_timer_en<='1';

  write(GUI_line,string'("Wait ESTABLISH ...."));writeline(output, GUI_line);
  while i_rcv_name/="SYNC   " loop
      p_SetData(p_in_clk,
                i_txsrcambler, C_CHAR_D,
                p_out_gtp_txdata, p_out_gtp_txcharisk,
                i_usropt_in, vusropt, i_usropt2_out);
  end loop;

  write(GUI_line,string'("ESTABLISH - OK!"));writeline(output, GUI_line);



--  --//--------------------------------
--  --//Отправка данных: FIS_DEV2HOST (Signature)
--  --//--------------------------------
--  --//Инициализация FIS:
--  txfis_size:=C_FIS_D2H_SIGNATURE'high;
--  for i in 0 to txfis_size loop
--  txd(i):=C_FIS_D2H_SIGNATURE(i);
--  end loop;
--  write(GUI_line,string'("FPGA<-HDD(Signature): Begin"));writeline(output, GUI_line);
--  p_SendFIS(p_in_clk,
--            txd, txfis_size,
--            p_out_gtp_txdata, p_out_gtp_txcharisk,
--            i_usropt_in, i_usropt2_out);
--  write(GUI_line,string'("FPGA<-HDD(Signature): End"));writeline(output, GUI_line);
--
--
--  p_SetSYNC(p_in_clk,
--            p_out_gtp_txdata, p_out_gtp_txcharisk,
--            i_usropt_in, i_usropt2_out);



  --//-----------------------------------------------------------
  --//Отладка приема данных SATA хостом. FPGA<-HDD . TEST01
  --//-----------------------------------------------------------
  --//Инициализация:
  txcrc:=CONV_STD_LOGIC_VECTOR(16#52325032#, txcrc'length);
  txsrcambler:=srambler32_0(CONV_STD_LOGIC_VECTOR(16#F0F6#, 16));

  txfis_size:=20;--
  txd(0):=(others=>'0');
  txd(0)(8*(0+1)-1 downto 8*0):=CONV_STD_LOGIC_VECTOR(C_FIS_DATA, 8);
  for i in 1 to txd'high loop
  --//Заполняем данные счетчиком (DWORD)
  txd(i)(8*(3+1)-1 downto 8*0):=CONV_STD_LOGIC_VECTOR(i, 32);
  end loop;

  write(GUI_line,string'("FIS_DATA /Send Start/UserData Size(DWORD) "));write(GUI_line, txfis_size);writeline(output, GUI_line);
  p_SendFIS(p_in_clk,
            txd, txfis_size,
            p_out_gtp_txdata, p_out_gtp_txcharisk,
            i_usropt_in, i_usropt2_out);
  write(GUI_line,string'("FIS_DATA /Send Done. "));writeline(output, GUI_line);


  for i in 0 to 1 loop
    p_SetData(p_in_clk,
              C_PDAT_SYNC, C_CHAR_K,
              p_out_gtp_txdata, p_out_gtp_txcharisk,
              i_usropt_in, vusropt, i_usropt2_out);
  end loop;

  p_SetData(p_in_clk,
            C_PDAT_CONT, C_CHAR_K,
            p_out_gtp_txdata, p_out_gtp_txcharisk,
            i_usropt_in, vusropt, i_usropt2_out);


  --//--------------------------------
  --//Прием : FIS_DATA
  --//--------------------------------
  txcomp_cnt:=1;
  --//Жду когда ХОСТ будет готов к передаче данных
  write(GUI_line,string'("Wait X_RDY(Host rdy send data) ...."));writeline(output, GUI_line);
  while i_usropt_in.rx.dname/="X_RDY  " loop
        if txcomp_cnt/=3 then
            if txcomp_cnt=2 then
              p_SetData(p_in_clk, C_PDAT_CONT, C_CHAR_K, p_out_gtp_txdata, p_out_gtp_txcharisk, i_usropt_in, vusropt, i_usropt2_out);
            else
              p_SetData(p_in_clk, C_PDAT_SYNC, C_CHAR_K, p_out_gtp_txdata, p_out_gtp_txcharisk, i_usropt_in, vusropt, i_usropt2_out);
                txcomp_cnt:=txcomp_cnt + 1;
            end if;
        else
            p_SetData(p_in_clk, i_usropt_in.tx.primitive.comp.srcambler, C_CHAR_D, p_out_gtp_txdata, p_out_gtp_txcharisk, i_usropt_in, vusropt, i_usropt2_out);
        end if;
  end loop;
  txcomp_cnt:=0;
  --//Жду начала FIS_DATA
  write(GUI_line,string'("RCV X_RDY. Wait SOF ...."));writeline(output, GUI_line);
  lwait_sof :while i_usropt_in.rx.detect.prmtv.sof='0' loop

      if txcomp_cnt/=3 then
          if txcomp_cnt=2 then
            p_SetData(p_in_clk, C_PDAT_CONT, C_CHAR_K, p_out_gtp_txdata, p_out_gtp_txcharisk, i_usropt_in, vusropt, i_usropt2_out);
            txcomp_cnt:=txcomp_cnt + 1;
          else
            p_SetData(p_in_clk, C_PDAT_R_RDY, C_CHAR_K, p_out_gtp_txdata, p_out_gtp_txcharisk, i_usropt_in, vusropt, i_usropt2_out);
            txcomp_cnt:=txcomp_cnt + 1;
          end if;
      else
          p_SetData(p_in_clk, i_usropt_in.tx.primitive.comp.srcambler, C_CHAR_D, p_out_gtp_txdata, p_out_gtp_txcharisk, i_usropt_in, vusropt, i_usropt2_out);
      end if;
--      write(GUI_line,string'("...."));writeline(output, GUI_line);
  end loop lwait_sof;

txcomp_cnt:=0;
txcomp_cnt1:=0;
txcomp_cnt2:=0;
txcomp_cnt3:=0;
write(GUI_line,string'("RCV DATA. Wait EOF ...."));writeline(output, GUI_line);

--//-------------------------------------------------
--//Моделируем отправку устройством примитива DMAT!!
--//-------------------------------------------------
lrxd :while i_usropt_in.rx.detect.prmtv.eof='0' and i_usropt_in.rx.dname/="SYNC   " loop
--//Прием FIS_DATA
if txcomp_cnt3>16#0C# then
  write(GUI_line,string'("RCV DATA./SEND DMAT"));writeline(output, GUI_line);
  p_SetData(p_in_clk, C_PDAT_DMAT, C_CHAR_K, p_out_gtp_txdata, p_out_gtp_txcharisk, i_usropt_in, vusropt, i_usropt2_out);

else
  if i_usropt_in.dbuf.wused='1' and i_usropt_in.dbuf.wen='0' then
      txcomp_cnt1:=0;
      txcomp_cnt2:=0;
      if txcomp_cnt/=3 then
          if txcomp_cnt=2 then
            p_SetData(p_in_clk, C_PDAT_CONT, C_CHAR_K, p_out_gtp_txdata, p_out_gtp_txcharisk, i_usropt_in, vusropt, i_usropt2_out);
            write(GUI_line,string'("RCV DATA./BUF_WDDISALE -> SEND HOLD/CONT"));writeline(output, GUI_line);
          else
            p_SetData(p_in_clk, C_PDAT_HOLD, C_CHAR_K, p_out_gtp_txdata, p_out_gtp_txcharisk, i_usropt_in, vusropt, i_usropt2_out);
            write(GUI_line,string'("RCV DATA./BUF_WDDISALE -> SEND HOLD"));writeline(output, GUI_line);
          end if;
          txcomp_cnt:=txcomp_cnt + 1;
      else
          p_SetData(p_in_clk, i_usropt_in.tx.primitive.comp.srcambler, C_CHAR_D, p_out_gtp_txdata, p_out_gtp_txcharisk, i_usropt_in, vusropt, i_usropt2_out);
      end if;

  else

      txcomp_cnt:=0;
      if i_usropt_in.rx.dname="HOLD   " then
          txcomp_cnt2:=0;
          if txcomp_cnt1/=3 then
              if txcomp_cnt1=2 then
                p_SetData(p_in_clk, C_PDAT_CONT, C_CHAR_K, p_out_gtp_txdata, p_out_gtp_txcharisk, i_usropt_in, vusropt, i_usropt2_out);
                write(GUI_line,string'("RCV DATA./RCV HOLD -> SEND HOLDA/CONT"));writeline(output, GUI_line);
              else
                p_SetData(p_in_clk, C_PDAT_HOLDA, C_CHAR_K, p_out_gtp_txdata, p_out_gtp_txcharisk, i_usropt_in, vusropt, i_usropt2_out);
                write(GUI_line,string'("RCV DATA./RCV HOLD -> SEND HOLDA"));writeline(output, GUI_line);
              end if;
              txcomp_cnt1:=txcomp_cnt1 + 1;
          else
              p_SetData(p_in_clk, i_usropt_in.tx.primitive.comp.srcambler, C_CHAR_D, p_out_gtp_txdata, p_out_gtp_txcharisk, i_usropt_in, vusropt, i_usropt2_out);
          end if;
      else
          txcomp_cnt1:=0;
          if txcomp_cnt2/=3 then
              if txcomp_cnt2=2 then
                p_SetData(p_in_clk, C_PDAT_CONT, C_CHAR_K, p_out_gtp_txdata, p_out_gtp_txcharisk, i_usropt_in, vusropt, i_usropt2_out);
              else
                p_SetData(p_in_clk, C_PDAT_R_IP, C_CHAR_K, p_out_gtp_txdata, p_out_gtp_txcharisk, i_usropt_in, vusropt, i_usropt2_out);
              end if;
              txcomp_cnt2:=txcomp_cnt2 + 1;
          else
              p_SetData(p_in_clk, i_usropt_in.tx.primitive.comp.srcambler, C_CHAR_D, p_out_gtp_txdata, p_out_gtp_txcharisk, i_usropt_in, vusropt, i_usropt2_out);
          end if;
      end if;

  end if;
end if;
  txcomp_cnt3:=txcomp_cnt3 + 1;

end loop lrxd;

----//-------------------------------------------------
----//Моделируем отправку устройством примитива SYNC!!
----//-------------------------------------------------
--lrxd :while i_usropt_in.rx.detect.prmtv.eof='0' and i_usropt_in.rx.dname/="SYNC   " loop
----//Прием FIS_DATA
--if txcomp_cnt3>16#0C# then
--  write(GUI_line,string'("RCV DATA./SEND SYNC"));writeline(output, GUI_line);
--  p_SetData(p_in_clk, C_PDAT_SYNC, C_CHAR_K, p_out_gtp_txdata, p_out_gtp_txcharisk, i_usropt_in, vusropt, i_usropt2_out);
--
--else
--  if i_usropt_in.dbuf.wused='1' and i_usropt_in.dbuf.wen='0' then
--      txcomp_cnt1:=0;
--      txcomp_cnt2:=0;
--      if txcomp_cnt/=3 then
--          if txcomp_cnt=2 then
--            p_SetData(p_in_clk, C_PDAT_CONT, C_CHAR_K, p_out_gtp_txdata, p_out_gtp_txcharisk, i_usropt_in, vusropt, i_usropt2_out);
--            write(GUI_line,string'("RCV DATA./BUF_WDDISALE -> SEND HOLD/CONT"));writeline(output, GUI_line);
--          else
--            p_SetData(p_in_clk, C_PDAT_HOLD, C_CHAR_K, p_out_gtp_txdata, p_out_gtp_txcharisk, i_usropt_in, vusropt, i_usropt2_out);
--            write(GUI_line,string'("RCV DATA./BUF_WDDISALE -> SEND HOLD"));writeline(output, GUI_line);
--          end if;
--          txcomp_cnt:=txcomp_cnt + 1;
--      else
--          p_SetData(p_in_clk, i_usropt_in.tx.primitive.comp.srcambler, C_CHAR_D, p_out_gtp_txdata, p_out_gtp_txcharisk, i_usropt_in, vusropt, i_usropt2_out);
--      end if;
--
--  else
--
--      txcomp_cnt:=0;
--      if i_usropt_in.rx.dname="HOLD   " then
--          txcomp_cnt2:=0;
--          if txcomp_cnt1/=3 then
--              if txcomp_cnt1=2 then
--                p_SetData(p_in_clk, C_PDAT_CONT, C_CHAR_K, p_out_gtp_txdata, p_out_gtp_txcharisk, i_usropt_in, vusropt, i_usropt2_out);
--                write(GUI_line,string'("RCV DATA./RCV HOLD -> SEND HOLDA/CONT"));writeline(output, GUI_line);
--              else
--                p_SetData(p_in_clk, C_PDAT_HOLDA, C_CHAR_K, p_out_gtp_txdata, p_out_gtp_txcharisk, i_usropt_in, vusropt, i_usropt2_out);
--                write(GUI_line,string'("RCV DATA./RCV HOLD -> SEND HOLDA"));writeline(output, GUI_line);
--              end if;
--              txcomp_cnt1:=txcomp_cnt1 + 1;
--          else
--              p_SetData(p_in_clk, i_usropt_in.tx.primitive.comp.srcambler, C_CHAR_D, p_out_gtp_txdata, p_out_gtp_txcharisk, i_usropt_in, vusropt, i_usropt2_out);
--          end if;
--      else
--          txcomp_cnt1:=0;
--          if txcomp_cnt2/=3 then
--              if txcomp_cnt2=2 then
--                p_SetData(p_in_clk, C_PDAT_CONT, C_CHAR_K, p_out_gtp_txdata, p_out_gtp_txcharisk, i_usropt_in, vusropt, i_usropt2_out);
--              else
--                p_SetData(p_in_clk, C_PDAT_R_IP, C_CHAR_K, p_out_gtp_txdata, p_out_gtp_txcharisk, i_usropt_in, vusropt, i_usropt2_out);
--              end if;
--              txcomp_cnt2:=txcomp_cnt2 + 1;
--          else
--              p_SetData(p_in_clk, i_usropt_in.tx.primitive.comp.srcambler, C_CHAR_D, p_out_gtp_txdata, p_out_gtp_txcharisk, i_usropt_in, vusropt, i_usropt2_out);
--          end if;
--      end if;
--
--  end if;
--end if;
--  txcomp_cnt3:=txcomp_cnt3 + 1;
--
--end loop lrxd;

--//-------------------------------------------------
--//Моделируем нормальный прием данных
--//-------------------------------------------------
--lrxd :while i_usropt_in.rx.detect.prmtv.eof='0' and i_usropt_in.rx.dname/="SYNC   " loop
----//Прием FIS_DATA
--  if i_usropt_in.dbuf.wused='1' and i_usropt_in.dbuf.wen='0' then
--      txcomp_cnt1:=0;
--      txcomp_cnt2:=0;
--      if txcomp_cnt/=3 then
--          if txcomp_cnt=2 then
--            p_SetData(p_in_clk, C_PDAT_CONT, C_CHAR_K, p_out_gtp_txdata, p_out_gtp_txcharisk, i_usropt_in, vusropt, i_usropt2_out);
--            write(GUI_line,string'("RCV DATA./BUF_WDDISALE -> SEND HOLD/CONT"));writeline(output, GUI_line);
--          else
--            p_SetData(p_in_clk, C_PDAT_HOLD, C_CHAR_K, p_out_gtp_txdata, p_out_gtp_txcharisk, i_usropt_in, vusropt, i_usropt2_out);
--            write(GUI_line,string'("RCV DATA./BUF_WDDISALE -> SEND HOLD"));writeline(output, GUI_line);
--          end if;
--          txcomp_cnt:=txcomp_cnt + 1;
--      else
--          p_SetData(p_in_clk, i_usropt_in.tx.primitive.comp.srcambler, C_CHAR_D, p_out_gtp_txdata, p_out_gtp_txcharisk, i_usropt_in, vusropt, i_usropt2_out);
--      end if;
--
--  else
--
--      txcomp_cnt:=0;
--      if i_usropt_in.rx.dname="HOLD   " then
--          txcomp_cnt2:=0;
--          if txcomp_cnt1/=3 then
--              if txcomp_cnt1=2 then
--                p_SetData(p_in_clk, C_PDAT_CONT, C_CHAR_K, p_out_gtp_txdata, p_out_gtp_txcharisk, i_usropt_in, vusropt, i_usropt2_out);
--                write(GUI_line,string'("RCV DATA./RCV HOLD -> SEND HOLDA/CONT"));writeline(output, GUI_line);
--              else
--                p_SetData(p_in_clk, C_PDAT_HOLDA, C_CHAR_K, p_out_gtp_txdata, p_out_gtp_txcharisk, i_usropt_in, vusropt, i_usropt2_out);
--                write(GUI_line,string'("RCV DATA./RCV HOLD -> SEND HOLDA"));writeline(output, GUI_line);
--              end if;
--              txcomp_cnt1:=txcomp_cnt1 + 1;
--          else
--              p_SetData(p_in_clk, i_usropt_in.tx.primitive.comp.srcambler, C_CHAR_D, p_out_gtp_txdata, p_out_gtp_txcharisk, i_usropt_in, vusropt, i_usropt2_out);
--          end if;
--      else
--          txcomp_cnt1:=0;
--          if txcomp_cnt2/=3 then
--              if txcomp_cnt2=2 then
--                p_SetData(p_in_clk, C_PDAT_CONT, C_CHAR_K, p_out_gtp_txdata, p_out_gtp_txcharisk, i_usropt_in, vusropt, i_usropt2_out);
--              else
--                p_SetData(p_in_clk, C_PDAT_R_IP, C_CHAR_K, p_out_gtp_txdata, p_out_gtp_txcharisk, i_usropt_in, vusropt, i_usropt2_out);
--              end if;
--              txcomp_cnt2:=txcomp_cnt2 + 1;
--          else
--              p_SetData(p_in_clk, i_usropt_in.tx.primitive.comp.srcambler, C_CHAR_D, p_out_gtp_txdata, p_out_gtp_txcharisk, i_usropt_in, vusropt, i_usropt2_out);
--          end if;
--      end if;
--
--  end if;
--
--end loop lrxd;
txcomp_cnt:=0;
--//Проверка CRC
if i_usropt_in.rx.dname/="SYNC   " then
    write(GUI_line,string'("RCV EOF. CHECKING CRC..."));writeline(output, GUI_line);
    if i_usropt_in.rx.fisdata=i_usropt_in.rx.crc_calc then
      write(GUI_line,string'("CRC - OK. Wait SYNC..."));writeline(output, GUI_line);
      while i_usropt_in.rx.dname/="SYNC   " loop
          if txcomp_cnt/=3 then
              if txcomp_cnt=2 then
                p_SetData(p_in_clk, C_PDAT_CONT, C_CHAR_K, p_out_gtp_txdata, p_out_gtp_txcharisk, i_usropt_in, vusropt, i_usropt2_out);
              else
                p_SetData(p_in_clk, C_PDAT_R_OK, C_CHAR_K, p_out_gtp_txdata, p_out_gtp_txcharisk, i_usropt_in, vusropt, i_usropt2_out);
              end if;
              txcomp_cnt:=txcomp_cnt + 1;
          else
              p_SetData(p_in_clk, i_usropt_in.tx.primitive.comp.srcambler, C_CHAR_D, p_out_gtp_txdata, p_out_gtp_txcharisk, i_usropt_in, vusropt, i_usropt2_out);
          end if;
          write(GUI_line,string'("..."));writeline(output, GUI_line);
      end loop;
      txcomp_cnt:=0;

    else

        write(GUI_line,string'("CRC - FAILED. Wait SYNC..."));writeline(output, GUI_line);
        while i_usropt_in.rx.dname/="SYNC   " loop
            if txcomp_cnt/=3 then
                if txcomp_cnt=2 then
                  p_SetData(p_in_clk, C_PDAT_CONT, C_CHAR_K, p_out_gtp_txdata, p_out_gtp_txcharisk, i_usropt_in, vusropt, i_usropt2_out);
                else
                  p_SetData(p_in_clk, C_PDAT_R_ERR, C_CHAR_K, p_out_gtp_txdata, p_out_gtp_txcharisk, i_usropt_in, vusropt, i_usropt2_out);
                end if;
                txcomp_cnt:=txcomp_cnt + 1;
            else
                p_SetData(p_in_clk, i_usropt_in.tx.primitive.comp.srcambler, C_CHAR_D, p_out_gtp_txdata, p_out_gtp_txcharisk, i_usropt_in, vusropt, i_usropt2_out);
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


  for i in 0 to 1 loop
    p_SetData(p_in_clk,
              C_PDAT_SYNC, C_CHAR_K,
              p_out_gtp_txdata, p_out_gtp_txcharisk,
              i_usropt_in, vusropt, i_usropt2_out);
  end loop;

  p_SetData(p_in_clk,
            C_PDAT_CONT, C_CHAR_K,
            p_out_gtp_txdata, p_out_gtp_txcharisk,
            i_usropt_in, vusropt, i_usropt2_out);

  write(GUI_line,string'("RCV FIS_DATA Done."));writeline(output, GUI_line);

--  wait;--//Для использования кода который написан ниже, нужно закомнтировать эту строку!!!!





  --//-----------------------------------------------------------
  --//Отладка приема данных SATA хостом. FPGA<-HDD . TEST00
  --//-----------------------------------------------------------
    --//Отправляем Хосту X_RDY (Готов к передаче данных)
    for i in 0 to 1 loop
      p_SetData(p_in_clk,
                C_PDAT_X_RDY, C_CHAR_K,
                p_out_gtp_txdata, p_out_gtp_txcharisk,
                i_usropt_in, vusropt, i_usropt2_out);
    end loop;

    p_SetData(p_in_clk,
              C_PDAT_CONT, C_CHAR_K,
              p_out_gtp_txdata, p_out_gtp_txcharisk,
              i_usropt_in, vusropt, i_usropt2_out);

    --//Ждем от Хоста R_RDY (готов к приему данных)
    write(GUI_line,string'("Wait R_RDY ...."));writeline(output, GUI_line);
    while i_rcv_name/="R_RDY  " loop
        p_SetData(p_in_clk,
                  i_txsrcambler, C_CHAR_D,
                  p_out_gtp_txdata, p_out_gtp_txcharisk,
                  i_usropt_in, vusropt, i_usropt2_out);
    end loop;
    write(GUI_line,string'("RCV R_RDY"));writeline(output, GUI_line);



    --//--------------------------------
    --//Отправка данных:
    --//--------------------------------
    --//Инициализация:
    txcrc:=CONV_STD_LOGIC_VECTOR(16#52325032#, txcrc'length);
    txsrcambler:=srambler32_0(CONV_STD_LOGIC_VECTOR(16#F0F6#, 16));

    txfis_size:=usr_dwsize;--
    txd(0):=(others=>'0');
    txd(0)(8*(0+1)-1 downto 8*0):=CONV_STD_LOGIC_VECTOR(C_FIS_DATA, 8);
    for i in 1 to txd'high loop
    --//Заполняем данные счетчиком (DWORD)
    txd(i)(8*(3+1)-1 downto 8*0):=CONV_STD_LOGIC_VECTOR(i, 32);
    end loop;

    --//SOF
      p_SetData(p_in_clk, C_PDAT_SOF, C_CHAR_K, p_out_gtp_txdata, p_out_gtp_txcharisk, i_usropt_in, vusropt, i_usropt2_out);

--            --//Имитация примитива ALIGN
--            p_SetData(p_in_clk, C_PDAT_ALIGN, C_CHAR_K, p_out_gtp_txdata, p_out_gtp_txcharisk, i_usropt_in, vusropt, i_usropt2_out);
--            p_SetData(p_in_clk, C_PDAT_ALIGN, C_CHAR_K, p_out_gtp_txdata, p_out_gtp_txcharisk, i_usropt_in, vusropt, i_usropt2_out);

            --//Имитация сигнала HOLD от hdd
            p_SetData(p_in_clk,
                      C_PDAT_HOLD, C_CHAR_K,
                      p_out_gtp_txdata, p_out_gtp_txcharisk,
                      i_usropt_in, vusropt, i_usropt2_out);
            p_SetData(p_in_clk,
                      C_PDAT_HOLD, C_CHAR_K,
                      p_out_gtp_txdata, p_out_gtp_txcharisk,
                      i_usropt_in, vusropt, i_usropt2_out);
            p_SetData(p_in_clk,
                      C_PDAT_CONT, C_CHAR_K,
                      p_out_gtp_txdata, p_out_gtp_txcharisk,
                      i_usropt_in, vusropt, i_usropt2_out);
            for i in 0 to 2 loop
            p_SetData(p_in_clk,
                      i_txsrcambler, C_CHAR_D,
                      p_out_gtp_txdata, p_out_gtp_txcharisk,
                      i_usropt_in, vusropt, i_usropt2_out);
            end loop;
            p_SetData(p_in_clk,
                      C_PDAT_HOLD, C_CHAR_K,
                      p_out_gtp_txdata, p_out_gtp_txcharisk,
                      i_usropt_in, vusropt, i_usropt2_out);

    --//user DATA
      for i in 0 to 8 loop
        if i_rcv_name="HOLD   " then
            while i_rcv_name/="R_IP   " loop
                if txcomp_cnt/=3 then
                    if txcomp_cnt=2 then
                      p_SetData(p_in_clk, C_PDAT_CONT, C_CHAR_K, p_out_gtp_txdata, p_out_gtp_txcharisk, i_usropt_in, vusropt, i_usropt2_out);
                    else
                      p_SetData(p_in_clk, C_PDAT_HOLDA, C_CHAR_K, p_out_gtp_txdata, p_out_gtp_txcharisk, i_usropt_in, vusropt, i_usropt2_out);
                        txcomp_cnt:=txcomp_cnt + 1;
                    end if;
                else
                    p_SetData(p_in_clk, i_txsrcambler, C_CHAR_D, p_out_gtp_txdata, p_out_gtp_txcharisk, i_usropt_in, vusropt, i_usropt2_out);
                end if;
            end loop;
        end if;
        txcomp_cnt:=0;

        --//Расчет CRC
        txcrc:=crc32_0( txd(i), txcrc);

        --//Скремблирование данных
        for x in 0 to 31 loop
        txd_out(x):=txd(i)(x) xor txsrcambler(x);
        end loop;
        --//Отправка пользовательского DW
        p_SetData(p_in_clk, txd_out, C_CHAR_D, p_out_gtp_txdata, p_out_gtp_txcharisk, i_usropt_in, vusropt, i_usropt2_out);  p_print_txrxd(txd(i), txsrcambler, txcrc, txd_out, i_usropt_in);

        --//Инкрементация скремблера
        txsrcambler:=srambler32_0(txsrcambler(31 downto 16));
      end loop;

            --//Имитация сигнала HOLD от hdd
            p_SetData(p_in_clk,
                      C_PDAT_HOLD, C_CHAR_K,
                      p_out_gtp_txdata, p_out_gtp_txcharisk,
                      i_usropt_in, vusropt, i_usropt2_out);
            p_SetData(p_in_clk,
                      C_PDAT_HOLD, C_CHAR_K,
                      p_out_gtp_txdata, p_out_gtp_txcharisk,
                      i_usropt_in, vusropt, i_usropt2_out);
            p_SetData(p_in_clk,
                      C_PDAT_CONT, C_CHAR_K,
                      p_out_gtp_txdata, p_out_gtp_txcharisk,
                      i_usropt_in, vusropt, i_usropt2_out);
            for i in 0 to 2 loop
            p_SetData(p_in_clk,
                      i_txsrcambler, C_CHAR_D,
                      p_out_gtp_txdata, p_out_gtp_txcharisk,
                      i_usropt_in, vusropt, i_usropt2_out);
            end loop;

--                --//Имитация примитива ALIGN
--                p_SetData(p_in_clk, C_PDAT_ALIGN, C_CHAR_K, p_out_gtp_txdata, p_out_gtp_txcharisk, i_usropt_in, vusropt, i_usropt2_out);
--                p_SetData(p_in_clk, C_PDAT_ALIGN, C_CHAR_K, p_out_gtp_txdata, p_out_gtp_txcharisk, i_usropt_in, vusropt, i_usropt2_out);

--            p_SetData(p_in_clk,
--                      C_PDAT_HOLD, C_CHAR_K,
--                      p_out_gtp_txdata, p_out_gtp_txcharisk,
--                      i_usropt_in, vusropt, i_usropt2_out);


            --//Имитация сигнала HOLD от hdd
            for i in 0 to 6 loop
            p_SetData(p_in_clk,
                      C_PDAT_HOLD, C_CHAR_K,
                      p_out_gtp_txdata, p_out_gtp_txcharisk,
                      i_usropt_in, vusropt, i_usropt2_out);
            end loop;

--                --//Имитация примитива ALIGN
--                p_SetData(p_in_clk, C_PDAT_ALIGN, C_CHAR_K, p_out_gtp_txdata, p_out_gtp_txcharisk, i_usropt_in, vusropt, i_usropt2_out);
--                p_SetData(p_in_clk, C_PDAT_ALIGN, C_CHAR_K, p_out_gtp_txdata, p_out_gtp_txcharisk, i_usropt_in, vusropt, i_usropt2_out);

    --//user DATA
      for i in 9 to 10 loop
        if i_rcv_name="HOLD   " then
            while i_rcv_name/="R_IP   " loop
                if txcomp_cnt/=3 then
                    if txcomp_cnt=2 then
                      p_SetData(p_in_clk, C_PDAT_CONT, C_CHAR_K, p_out_gtp_txdata, p_out_gtp_txcharisk, i_usropt_in, vusropt, i_usropt2_out);
                    else
                      p_SetData(p_in_clk, C_PDAT_HOLDA, C_CHAR_K, p_out_gtp_txdata, p_out_gtp_txcharisk, i_usropt_in, vusropt, i_usropt2_out);
                        txcomp_cnt:=txcomp_cnt + 1;
                    end if;
                else
                    p_SetData(p_in_clk, i_txsrcambler, C_CHAR_D, p_out_gtp_txdata, p_out_gtp_txcharisk, i_usropt_in, vusropt, i_usropt2_out);
                end if;
            end loop;
        end if;
        txcomp_cnt:=0;

        --//Расчет CRC
        txcrc:=crc32_0( txd(i), txcrc);

        --//Скремблирование данных
        for x in 0 to 31 loop
        txd_out(x):=txd(i)(x) xor txsrcambler(x);
        end loop;
        --//Отправка пользовательского DW
        p_SetData(p_in_clk, txd_out, C_CHAR_D, p_out_gtp_txdata, p_out_gtp_txcharisk, i_usropt_in, vusropt, i_usropt2_out);  p_print_txrxd(txd(i), txsrcambler, txcrc, txd_out, i_usropt_in);

--        if i=2 or i=4 then
--                --//Имитация примитива ALIGN
--                p_SetData(p_in_clk, C_PDAT_ALIGN, C_CHAR_K, p_out_gtp_txdata, p_out_gtp_txcharisk, i_usropt_in, vusropt, i_usropt2_out);
--                p_SetData(p_in_clk, C_PDAT_ALIGN, C_CHAR_K, p_out_gtp_txdata, p_out_gtp_txcharisk, i_usropt_in, vusropt, i_usropt2_out);
--        end if;

        --//Инкрементация скремблера
        txsrcambler:=srambler32_0(txsrcambler(31 downto 16));
      end loop;


            --//Имитация сигнала HOLD от hdd
            p_SetData(p_in_clk,
                      C_PDAT_HOLD, C_CHAR_K,
                      p_out_gtp_txdata, p_out_gtp_txcharisk,
                      i_usropt_in, vusropt, i_usropt2_out);
            p_SetData(p_in_clk,
                      C_PDAT_HOLD, C_CHAR_K,
                      p_out_gtp_txdata, p_out_gtp_txcharisk,
                      i_usropt_in, vusropt, i_usropt2_out);
            p_SetData(p_in_clk,
                      C_PDAT_CONT, C_CHAR_K,
                      p_out_gtp_txdata, p_out_gtp_txcharisk,
                      i_usropt_in, vusropt, i_usropt2_out);
            for i in 0 to 4 loop
            p_SetData(p_in_clk,
                      i_txsrcambler, C_CHAR_D,
                      p_out_gtp_txdata, p_out_gtp_txcharisk,
                      i_usropt_in, vusropt, i_usropt2_out);
            end loop;
            p_SetData(p_in_clk,
                      C_PDAT_HOLD, C_CHAR_K,
                      p_out_gtp_txdata, p_out_gtp_txcharisk,
                      i_usropt_in, vusropt, i_usropt2_out);

    --//user DATA
      for i in 11 to 15 loop
        if i_rcv_name="HOLD   " then
            while i_rcv_name/="R_IP   " loop
                if txcomp_cnt/=3 then
                    if txcomp_cnt=2 then
                      p_SetData(p_in_clk, C_PDAT_CONT, C_CHAR_K, p_out_gtp_txdata, p_out_gtp_txcharisk, i_usropt_in, vusropt, i_usropt2_out);
                    else
                      p_SetData(p_in_clk, C_PDAT_HOLDA, C_CHAR_K, p_out_gtp_txdata, p_out_gtp_txcharisk, i_usropt_in, vusropt, i_usropt2_out);
                        txcomp_cnt:=txcomp_cnt + 1;
                    end if;
                else
                    p_SetData(p_in_clk, i_txsrcambler, C_CHAR_D, p_out_gtp_txdata, p_out_gtp_txcharisk, i_usropt_in, vusropt, i_usropt2_out);
                end if;
            end loop;
        end if;
        txcomp_cnt:=0;

        --//Расчет CRC
        txcrc:=crc32_0( txd(i), txcrc);

        --//Скремблирование данных
        for x in 0 to 31 loop
        txd_out(x):=txd(i)(x) xor txsrcambler(x);
        end loop;
        --//Отправка пользовательского DW
        p_SetData(p_in_clk, txd_out, C_CHAR_D, p_out_gtp_txdata, p_out_gtp_txcharisk, i_usropt_in, vusropt, i_usropt2_out);  p_print_txrxd(txd(i), txsrcambler, txcrc, txd_out, i_usropt_in);

        --//Инкрементация скремблера
        txsrcambler:=srambler32_0(txsrcambler(31 downto 16));
      end loop;

            --//Имитация сигнала HOLD от hdd
            p_SetData(p_in_clk,
                      C_PDAT_HOLD, C_CHAR_K,
                      p_out_gtp_txdata, p_out_gtp_txcharisk,
                      i_usropt_in, vusropt, i_usropt2_out);
            p_SetData(p_in_clk,
                      C_PDAT_HOLD, C_CHAR_K,
                      p_out_gtp_txdata, p_out_gtp_txcharisk,
                      i_usropt_in, vusropt, i_usropt2_out);
            p_SetData(p_in_clk,
                      C_PDAT_CONT, C_CHAR_K,
                      p_out_gtp_txdata, p_out_gtp_txcharisk,
                      i_usropt_in, vusropt, i_usropt2_out);
            for i in 0 to 3 loop
            p_SetData(p_in_clk,
                      i_txsrcambler, C_CHAR_D,
                      p_out_gtp_txdata, p_out_gtp_txcharisk,
                      i_usropt_in, vusropt, i_usropt2_out);
            end loop;
            p_SetData(p_in_clk,
                      C_PDAT_HOLD, C_CHAR_K,
                      p_out_gtp_txdata, p_out_gtp_txcharisk,
                      i_usropt_in, vusropt, i_usropt2_out);

    --//user DATA
      for i in 16 to 19 loop
        if i_rcv_name="HOLD   " then
            while i_rcv_name/="R_IP   " loop
                if txcomp_cnt/=3 then
                    if txcomp_cnt=2 then
                      p_SetData(p_in_clk, C_PDAT_CONT, C_CHAR_K, p_out_gtp_txdata, p_out_gtp_txcharisk, i_usropt_in, vusropt, i_usropt2_out);
                    else
                      p_SetData(p_in_clk, C_PDAT_HOLDA, C_CHAR_K, p_out_gtp_txdata, p_out_gtp_txcharisk, i_usropt_in, vusropt, i_usropt2_out);
                        txcomp_cnt:=txcomp_cnt + 1;
                    end if;
                else
                    p_SetData(p_in_clk, i_txsrcambler, C_CHAR_D, p_out_gtp_txdata, p_out_gtp_txcharisk, i_usropt_in, vusropt, i_usropt2_out);
                end if;
            end loop;
        end if;
        txcomp_cnt:=0;

        --//Расчет CRC
        txcrc:=crc32_0( txd(i), txcrc);

        --//Скремблирование данных
        for x in 0 to 31 loop
        txd_out(x):=txd(i)(x) xor txsrcambler(x);
        end loop;
        --//Отправка пользовательского DW
        p_SetData(p_in_clk, txd_out, C_CHAR_D, p_out_gtp_txdata, p_out_gtp_txcharisk, i_usropt_in, vusropt, i_usropt2_out);  p_print_txrxd(txd(i), txsrcambler, txcrc, txd_out, i_usropt_in);

        --//Инкрементация скремблера
        txsrcambler:=srambler32_0(txsrcambler(31 downto 16));
      end loop;

            --//Имитация сигнала HOLD от hdd
            p_SetData(p_in_clk,
                      C_PDAT_HOLD, C_CHAR_K,
                      p_out_gtp_txdata, p_out_gtp_txcharisk,
                      i_usropt_in, vusropt, i_usropt2_out);

--                --//Имитация примитива ALIGN
--                p_SetData(p_in_clk, C_PDAT_ALIGN, C_CHAR_K, p_out_gtp_txdata, p_out_gtp_txcharisk, i_usropt_in, vusropt, i_usropt2_out);
--                p_SetData(p_in_clk, C_PDAT_ALIGN, C_CHAR_K, p_out_gtp_txdata, p_out_gtp_txcharisk, i_usropt_in, vusropt, i_usropt2_out);

            p_SetData(p_in_clk,
                      C_PDAT_HOLD, C_CHAR_K,
                      p_out_gtp_txdata, p_out_gtp_txcharisk,
                      i_usropt_in, vusropt, i_usropt2_out);

--                --//Имитация примитива ALIGN
--                p_SetData(p_in_clk, C_PDAT_ALIGN, C_CHAR_K, p_out_gtp_txdata, p_out_gtp_txcharisk, i_usropt_in, vusropt, i_usropt2_out);
--                p_SetData(p_in_clk, C_PDAT_ALIGN, C_CHAR_K, p_out_gtp_txdata, p_out_gtp_txcharisk, i_usropt_in, vusropt, i_usropt2_out);

            p_SetData(p_in_clk,
                      C_PDAT_CONT, C_CHAR_K,
                      p_out_gtp_txdata, p_out_gtp_txcharisk,
                      i_usropt_in, vusropt, i_usropt2_out);

                --//Имитация примитива ALIGN
                p_SetData(p_in_clk, C_PDAT_ALIGN, C_CHAR_K, p_out_gtp_txdata, p_out_gtp_txcharisk, i_usropt_in, vusropt, i_usropt2_out);
                p_SetData(p_in_clk, C_PDAT_ALIGN, C_CHAR_K, p_out_gtp_txdata, p_out_gtp_txcharisk, i_usropt_in, vusropt, i_usropt2_out);

            for i in 0 to 3 loop
            p_SetData(p_in_clk,
                      i_txsrcambler, C_CHAR_D,
                      p_out_gtp_txdata, p_out_gtp_txcharisk,
                      i_usropt_in, vusropt, i_usropt2_out);
            end loop;

--                --//Имитация примитива ALIGN
--                p_SetData(p_in_clk, C_PDAT_ALIGN, C_CHAR_K, p_out_gtp_txdata, p_out_gtp_txcharisk, i_usropt_in, vusropt, i_usropt2_out);
--                p_SetData(p_in_clk, C_PDAT_ALIGN, C_CHAR_K, p_out_gtp_txdata, p_out_gtp_txcharisk, i_usropt_in, vusropt, i_usropt2_out);

            p_SetData(p_in_clk,
                      C_PDAT_HOLD, C_CHAR_K,
                      p_out_gtp_txdata, p_out_gtp_txcharisk,
                      i_usropt_in, vusropt, i_usropt2_out);

    --//CRC
      if i_rcv_name="HOLD   " then
          while i_rcv_name/="R_IP   " loop
              if txcomp_cnt/=3 then
                  if txcomp_cnt=2 then
                    p_SetData(p_in_clk, C_PDAT_CONT, C_CHAR_K, p_out_gtp_txdata, p_out_gtp_txcharisk, i_usropt_in, vusropt, i_usropt2_out);
                  else
                    p_SetData(p_in_clk, C_PDAT_HOLDA, C_CHAR_K, p_out_gtp_txdata, p_out_gtp_txcharisk, i_usropt_in, vusropt, i_usropt2_out);
                      txcomp_cnt:=txcomp_cnt + 1;
                  end if;
              else
                  p_SetData(p_in_clk, i_txsrcambler, C_CHAR_D, p_out_gtp_txdata, p_out_gtp_txcharisk, i_usropt_in, vusropt, i_usropt2_out);
              end if;
          end loop;
      end if;
      txcomp_cnt:=0;
      --//Скремблирование данных
      for x in 0 to 31 loop
      txd_out(x):=txcrc(x) xor txsrcambler(x);
      end loop;
      p_print_txrxd(txcrc, txsrcambler, txcrc, txd_out, i_usropt_in);
      p_SetData(p_in_clk, txd_out, C_CHAR_D, p_out_gtp_txdata, p_out_gtp_txcharisk, i_usropt_in, vusropt, i_usropt2_out);

--            --//Имитация примитива ALIGN
--            p_SetData(p_in_clk, C_PDAT_ALIGN, C_CHAR_K, p_out_gtp_txdata, p_out_gtp_txcharisk, i_usropt_in, vusropt, i_usropt2_out);
--            p_SetData(p_in_clk, C_PDAT_ALIGN, C_CHAR_K, p_out_gtp_txdata, p_out_gtp_txcharisk, i_usropt_in, vusropt, i_usropt2_out);

            --//Имитация сигнала HOLD от hdd
            p_SetData(p_in_clk,
                      C_PDAT_HOLD, C_CHAR_K,
                      p_out_gtp_txdata, p_out_gtp_txcharisk,
                      i_usropt_in, vusropt, i_usropt2_out);
            p_SetData(p_in_clk,
                      C_PDAT_HOLD, C_CHAR_K,
                      p_out_gtp_txdata, p_out_gtp_txcharisk,
                      i_usropt_in, vusropt, i_usropt2_out);
            p_SetData(p_in_clk,
                      C_PDAT_CONT, C_CHAR_K,
                      p_out_gtp_txdata, p_out_gtp_txcharisk,
                      i_usropt_in, vusropt, i_usropt2_out);
            for i in 0 to 2 loop
            p_SetData(p_in_clk,
                      i_txsrcambler, C_CHAR_D,
                      p_out_gtp_txdata, p_out_gtp_txcharisk,
                      i_usropt_in, vusropt, i_usropt2_out);
            end loop;
            p_SetData(p_in_clk,
                      C_PDAT_HOLD, C_CHAR_K,
                      p_out_gtp_txdata, p_out_gtp_txcharisk,
                      i_usropt_in, vusropt, i_usropt2_out);

    --//EOF
      if i_rcv_name="HOLD   " then
          while i_rcv_name/="R_IP   " loop
              if txcomp_cnt/=3 then
                  if txcomp_cnt=2 then
                    p_SetData(p_in_clk, C_PDAT_CONT, C_CHAR_K, p_out_gtp_txdata, p_out_gtp_txcharisk, i_usropt_in, vusropt, i_usropt2_out);
                  else
                    p_SetData(p_in_clk, C_PDAT_HOLDA, C_CHAR_K, p_out_gtp_txdata, p_out_gtp_txcharisk, i_usropt_in, vusropt, i_usropt2_out);
                      txcomp_cnt:=txcomp_cnt + 1;
                  end if;
              else
                  p_SetData(p_in_clk, i_txsrcambler, C_CHAR_D, p_out_gtp_txdata, p_out_gtp_txcharisk, i_usropt_in, vusropt, i_usropt2_out);
              end if;
          end loop;
      end if;
      txcomp_cnt:=0;
      p_SetData(p_in_clk, C_PDAT_EOF, C_CHAR_K, p_out_gtp_txdata, p_out_gtp_txcharisk, i_usropt_in, vusropt, i_usropt2_out);

--            --//Имитация примитива ALIGN
--            p_SetData(p_in_clk, C_PDAT_ALIGN, C_CHAR_K, p_out_gtp_txdata, p_out_gtp_txcharisk, i_usropt_in, vusropt, i_usropt2_out);
--            p_SetData(p_in_clk, C_PDAT_ALIGN, C_CHAR_K, p_out_gtp_txdata, p_out_gtp_txcharisk, i_usropt_in, vusropt, i_usropt2_out);

  write(GUI_line,string'("Wait R_OK/R_ERR ...."));writeline(output, GUI_line);
  while (i_rcv_name/="R_OK   " and  i_rcv_name/="R_ERR  ") loop
      p_SetDW(p_in_clk,
              C_PDAT_WTRM, C_CHAR_K,
              p_out_gtp_txdata, p_out_gtp_txcharisk,
              i_usropt_in, vusropt, i_usropt2_out);
  end loop;
  if i_rcv_name="R_OK   " then
    write(GUI_line,string'("RCV R_OK"));writeline(output, GUI_line);
  else
    write(GUI_line,string'("RCV R_ERR"));writeline(output, GUI_line);
  end if;


  for i in 0 to 2 loop
    p_SetData(p_in_clk,
              C_PDAT_SYNC, C_CHAR_K,
              p_out_gtp_txdata, p_out_gtp_txcharisk,
              i_usropt_in, vusropt, i_usropt2_out);
  end loop;

  p_SetData(p_in_clk,
            C_PDAT_CONT, C_CHAR_K,
            p_out_gtp_txdata, p_out_gtp_txcharisk,
            i_usropt_in, vusropt, i_usropt2_out);





--  --//--------------------------------
--  --//Отладка передачи данных SATA хостом. FPGA->HDD
--  --//--------------------------------
--  while i_rcv_name/="X_RDY  " loop
--
--      p_SetData(p_in_clk,
--                i_txsrcambler, C_CHAR_D,
--                p_out_gtp_txdata, p_out_gtp_txcharisk,
--                i_usropt_in, vusropt, i_usropt2_out);
--  end loop;
--
--  while i_rcv_name/="SOF    " loop
--
--    p_SetData(p_in_clk, C_PDAT_R_RDY, C_CHAR_K, p_out_gtp_txdata, p_out_gtp_txcharisk, i_usropt_in, vusropt, i_usropt2_out);
--
--  end loop;

  --//Завершаем модеоирование.
  p_SIM_STOP("Simulation of SIMPLE complete");

  wait;
end process sim_send2;

end generate gen_dbg_llayer_on;

--End MAIN
end;


