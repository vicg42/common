-------------------------------------------------------------------------
-- Company     : Linkos
-- Engineer    : Golovachenko Victor
--
-- Create Date : 10.02.2011 17:19:48
-- Module Name : sata_player_rx
--
-- Назначение/Описание :
--   1. Обнаружение в данных приемника RocketIO примитивов SATA и пользовательских данных,
--      выдача соответствующего флага на порт p_out_rxtype
--   2. Обнаружение ошибок приема данных
--      выдача соответствующего флага на порт p_out_rxerr
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

library work;
use work.vicg_common_pkg.all;
use work.sata_glob_pkg.all;
use work.sata_pkg.all;
use work.sata_sim_lite_pkg.all;

entity sata_player_rx is
generic(
G_GT_DBUS : integer:=16;
G_DBG     : string :="OFF";
G_SIM     : string :="OFF"
);
port(
--------------------------------------------------
--
--------------------------------------------------
p_in_dev_detect         : in    std_logic;
p_out_rxd               : out   std_logic_vector(31 downto 0);                --//Принятые данные
p_out_rxtype            : out   std_logic_vector(C_TDATA_EN downto C_TALIGN); --//константы см. sata_pkg поле --//Номера примитивов
p_out_rxerr             : out   std_logic_vector(C_PRxSTAT_LAST_BIT downto 0);--//константы см. sata_pkg поле --//PHY Layer /Reciver /Статусы/Map:

--------------------------------------------------
--RocketIO Receiver (Описание портов см. sata_player_gt.vhd)
--------------------------------------------------
p_in_gt_rxdata          : in    std_logic_vector(31 downto 0);
p_in_gt_rxcharisk       : in    std_logic_vector(3 downto 0);
p_in_gt_rxdisperr       : in    std_logic_vector(3 downto 0);
p_in_gt_rxnotintable    : in    std_logic_vector(3 downto 0);
p_in_gt_rxbyteisaligned : in    std_logic;

p_in_gt_rxbufstatus     : in    std_logic_vector(2 downto 0);
p_out_gt_rxbufreset     : out   std_logic;

--------------------------------------------------
--Технологические сигналы
--------------------------------------------------
p_in_tst                : in    std_logic_vector(31 downto 0);
p_out_tst               : out   std_logic_vector(31 downto 0);
p_out_dbg               : out   TPLrx_dbgport;

--------------------------------------------------
--System
--------------------------------------------------
p_in_clk                : in    std_logic;
p_in_rst                : in    std_logic
);
end sata_player_rx;

architecture behavioral of sata_player_rx is

signal i_tmr_rst                 : std_logic_vector(1 downto 0);
signal i_tmr_rst_en              : std_logic;

signal i_gt_rxbufreset           : std_logic;

type TSrDataW8 is array (0 to 2) of std_logic_vector(7 downto 0);
signal sr_rxdata                 : TSrDataW8;

type TSrDtypeW8 is array (0 to 2) of std_logic;
signal sr_rxdtype                : TSrDtypeW8;
signal sr_gt_rxdisperr           : TSrDtypeW8;
signal sr_gt_rxnotintable        : TSrDtypeW8;

signal i_rxdata                  : std_logic_vector(31 downto 0);
signal i_rxdtype                 : std_logic_vector(3 downto 0);
signal i_gt_rxdisperr            : std_logic_vector(3 downto 0);
signal i_gt_rxnotintable         : std_logic_vector(3 downto 0);

signal i_rxdata_out              : std_logic_vector(31 downto 0):=(others=>'0');
signal i_rxdtype_out             : std_logic_vector(C_TDATA_EN downto C_TALIGN):=(others=>'0');
signal i_rcv_error_out           : std_logic_vector(C_PRxSTAT_LAST_BIT downto 0):=(others=>'0');
signal i_rxtype                  : std_logic_vector(C_TDATA_EN downto C_TALIGN):=(others=>'0');
signal i_rxtype1                 : std_logic_vector(C_TPMNAK downto C_TALIGN):=(others=>'0');
signal i_rxtype2                 : std_logic_vector(C_TPMNAK downto C_TALIGN):=(others=>'0');
signal i_rxtype3                 : std_logic_vector(C_TPMNAK downto C_TALIGN):=(others=>'0');
signal i_rxdtype_out0            : std_logic_vector(C_TPMNAK downto C_TALIGN):=(others=>'0');
signal i_rxdtype_out1            : std_logic_vector(C_TPMNAK downto C_TALIGN):=(others=>'0');
signal i_rxdtype_out2            : std_logic_vector(C_TPMNAK downto C_TALIGN):=(others=>'0');
signal i_rxdtype_out3            : std_logic_vector(C_TPMNAK downto C_TALIGN):=(others=>'0');
signal dbgrcv_type               : string(1 to 7);



--MAIN
begin

--//----------------------------------
--//Технологические сигналы
--//----------------------------------
gen_dbg_off : if strcmp(G_DBG,"OFF") generate
p_out_tst(31 downto 0)<=(others=>'0');
end generate gen_dbg_off;

gen_dbg_on : if strcmp(G_DBG,"ON") generate
p_out_tst(0)<=OR_reduce(i_rcv_error_out) or not p_in_gt_rxbyteisaligned or
              i_rcv_error_out(C_PRxSTAT_ERR_DISP_BIT) or i_rcv_error_out(C_PRxSTAT_ERR_NOTINTABLE_BIT);
p_out_tst(31 downto 1)<=(others=>'0');
end generate gen_dbg_on;



--//-----------------------------------
--//Логика работы
--//-----------------------------------
tmr_rst:process(p_in_rst,p_in_clk)
begin
  if p_in_rst='1' then
    i_tmr_rst<=(others=>'0');
  elsif p_in_clk'event and p_in_clk='1' then
    if i_tmr_rst_en='1' then
      i_tmr_rst<=i_tmr_rst+1;
    else
      i_tmr_rst<=(others=>'0');
    end if;
  end if;
end process;

--//Контроль переполнения буфера приемника GT/  RX elastic buffer
process(p_in_rst,p_in_clk)
begin
  if p_in_rst='1' then
    i_tmr_rst_en<='0';
    i_gt_rxbufreset<='0';

  elsif p_in_clk'event and p_in_clk='1' then
    if p_in_dev_detect='0' then
      i_tmr_rst_en<='0';
      i_gt_rxbufreset<='0';
    else
      if i_tmr_rst_en='0' then
        i_gt_rxbufreset<='0';
        if (p_in_gt_rxbufstatus="101" or p_in_gt_rxbufstatus="110") then
        --"101" - underflow
        --"110" - overflow
        --формирую сброс
          i_tmr_rst_en<='1';
        end if;
      else
        i_gt_rxbufreset<='1';
        if i_tmr_rst=CONV_STD_LOGIC_VECTOR(16#02#, i_tmr_rst'length) then
          i_tmr_rst_en<='0';
        end if;
      end if;
    end if;
  end if;
end process;

p_out_gt_rxbufreset<=i_gt_rxbufreset;

process(p_in_clk)
begin
  if p_in_clk'event and p_in_clk='1' then
    i_rxdata_out<=i_rxdata;

    i_rcv_error_out(C_PRxSTAT_ERR_DISP_BIT)<=OR_reduce(i_gt_rxdisperr);
    i_rcv_error_out(C_PRxSTAT_ERR_NOTINTABLE_BIT)<=OR_reduce(i_gt_rxnotintable);

  end if;
end process;

p_out_rxtype<=i_rxdtype_out;
p_out_rxd<=i_rxdata_out;
p_out_rxerr<=i_rcv_error_out;



--//------------------------------
--//GT: ШИНА ДАНЫХ=8bit
--//------------------------------
gen_dbus8 : if G_GT_DBUS=8 generate

lsr_rxd:process(p_in_rst,p_in_clk)
begin
  if p_in_rst='1' then
    for i in 0 to 2 loop
      sr_rxdata(i)<=(others=>'0');
      sr_rxdtype(i)<='0';
      sr_gt_rxdisperr(i)<='0';
      sr_gt_rxnotintable(i)<='0';
    end loop;

  elsif p_in_clk'event and p_in_clk='1' then

      sr_rxdata<=p_in_gt_rxdata(7 downto 0) & sr_rxdata(0 to 1);
      sr_rxdtype<=p_in_gt_rxcharisk(0) & sr_rxdtype(0 to 1);

      sr_gt_rxdisperr<=p_in_gt_rxdisperr(0) & sr_gt_rxdisperr(0 to 1);
      sr_gt_rxnotintable<=p_in_gt_rxnotintable(0) & sr_gt_rxnotintable(0 to 1);

  end if;
end process lsr_rxd;

i_rxdtype<=p_in_gt_rxcharisk(0) & sr_rxdtype(0) & sr_rxdtype(1) & sr_rxdtype(2);
i_rxdata<=p_in_gt_rxdata(7 downto 0) & sr_rxdata(0) & sr_rxdata(1) & sr_rxdata(2);

i_gt_rxdisperr<=p_in_gt_rxdisperr(0) & sr_gt_rxdisperr(0) & sr_gt_rxdisperr(1) & sr_gt_rxdisperr(2);
i_gt_rxnotintable<=p_in_gt_rxnotintable(0) & sr_gt_rxnotintable(0) & sr_gt_rxnotintable(1) & sr_gt_rxnotintable(2);

i_rxtype(C_TALIGN)   <='1' when i_rxdata=C_PDAT_ALIGN   and i_rxdtype=C_PDAT_TPRM   and p_in_gt_rxbyteisaligned='1' else '0';
i_rxtype(C_TSOF)     <='1' when i_rxdata=C_PDAT_SOF     and i_rxdtype=C_PDAT_TPRM                                   else '0';
i_rxtype(C_TEOF)     <='1' when i_rxdata=C_PDAT_EOF     and i_rxdtype=C_PDAT_TPRM                                   else '0';
i_rxtype(C_TDMAT)    <='1' when i_rxdata=C_PDAT_DMAT    and i_rxdtype=C_PDAT_TPRM                                   else '0';
i_rxtype(C_TCONT)    <='1' when i_rxdata=C_PDAT_CONT    and i_rxdtype=C_PDAT_TPRM                                   else '0';
i_rxtype(C_TSYNC)    <='1' when i_rxdata=C_PDAT_SYNC    and i_rxdtype=C_PDAT_TPRM                                   else '0';
i_rxtype(C_THOLD)    <='1' when i_rxdata=C_PDAT_HOLD    and i_rxdtype=C_PDAT_TPRM                                   else '0';
i_rxtype(C_THOLDA)   <='1' when i_rxdata=C_PDAT_HOLDA   and i_rxdtype=C_PDAT_TPRM                                   else '0';
i_rxtype(C_TX_RDY)   <='1' when i_rxdata=C_PDAT_X_RDY   and i_rxdtype=C_PDAT_TPRM                                   else '0';
i_rxtype(C_TR_RDY)   <='1' when i_rxdata=C_PDAT_R_RDY   and i_rxdtype=C_PDAT_TPRM                                   else '0';
i_rxtype(C_TR_IP)    <='1' when i_rxdata=C_PDAT_R_IP    and i_rxdtype=C_PDAT_TPRM                                   else '0';
i_rxtype(C_TR_OK)    <='1' when i_rxdata=C_PDAT_R_OK    and i_rxdtype=C_PDAT_TPRM                                   else '0';
i_rxtype(C_TR_ERR)   <='1' when i_rxdata=C_PDAT_R_ERR   and i_rxdtype=C_PDAT_TPRM                                   else '0';
i_rxtype(C_TWTRM)    <='1' when i_rxdata=C_PDAT_WTRM    and i_rxdtype=C_PDAT_TPRM                                   else '0';
i_rxtype(C_TPMREQ_P) <='1' when i_rxdata=C_PDAT_PMREQ_P and i_rxdtype=C_PDAT_TPRM                                   else '0';
i_rxtype(C_TPMREQ_S) <='1' when i_rxdata=C_PDAT_PMREQ_S and i_rxdtype=C_PDAT_TPRM                                   else '0';
i_rxtype(C_TPMACK)   <='1' when i_rxdata=C_PDAT_PMACK   and i_rxdtype=C_PDAT_TPRM                                   else '0';
i_rxtype(C_TPMNAK)   <='1' when i_rxdata=C_PDAT_PMNAK   and i_rxdtype=C_PDAT_TPRM                                   else '0';
i_rxtype(C_TDATA_EN) <='1' when                             i_rxdtype=C_PDAT_TDATA                                  else '0';

process(p_in_clk)
begin
  if p_in_clk'event and p_in_clk='1' then
    for i in C_TALIGN to C_TDATA_EN-1 loop
      i_rxdtype_out(i)<=i_rxtype(i);-- and not (OR_reduce(i_gt_rxdisperr) or OR_reduce(i_gt_rxnotintable));
    end loop;
    i_rxdtype_out(C_TDATA_EN)<=i_rxtype(C_TDATA_EN);
  end if;
end process;

end generate gen_dbus8;

--//------------------------------
--//GT: ШИНА ДАНЫХ=16bit
--//------------------------------
gen_dbus16 : if G_GT_DBUS=16 generate

lsr_rxd:process(p_in_rst,p_in_clk)
begin
  if p_in_rst='1' then
    for i in 0 to 2 loop
      sr_rxdata(i)<=(others=>'0');
      sr_rxdtype(i)<='0';
      sr_gt_rxdisperr(i)<='0';
      sr_gt_rxnotintable(i)<='0';
    end loop;

  elsif p_in_clk'event and p_in_clk='1' then

      sr_rxdata(0)<=p_in_gt_rxdata(7 downto 0);
      sr_rxdata(1)<=p_in_gt_rxdata(15 downto 8);
      sr_rxdtype(0)<=p_in_gt_rxcharisk(0);
      sr_rxdtype(1)<=p_in_gt_rxcharisk(1);

      sr_gt_rxdisperr(0)<=p_in_gt_rxdisperr(0);
      sr_gt_rxdisperr(1)<=p_in_gt_rxdisperr(1);
      sr_gt_rxnotintable(0)<=p_in_gt_rxnotintable(0);
      sr_gt_rxnotintable(1)<=p_in_gt_rxnotintable(1);

  end if;
end process lsr_rxd;

i_rxdata<=p_in_gt_rxdata(15 downto 8) & p_in_gt_rxdata(7 downto 0) & sr_rxdata(1) & sr_rxdata(0);
i_rxdtype<=p_in_gt_rxcharisk(1) & p_in_gt_rxcharisk(0) & sr_rxdtype(1) & sr_rxdtype(0);

i_gt_rxdisperr<=p_in_gt_rxdisperr(1) & p_in_gt_rxdisperr(0) & sr_gt_rxdisperr(1) & sr_gt_rxdisperr(0);
i_gt_rxnotintable<=p_in_gt_rxnotintable(1) & p_in_gt_rxnotintable(0) & sr_gt_rxnotintable(1) & sr_gt_rxnotintable(0);

i_rxtype(C_TALIGN)   <='1' when i_rxdata=C_PDAT_ALIGN   and i_rxdtype=C_PDAT_TPRM   and p_in_gt_rxbyteisaligned='1' else '0';
i_rxtype(C_TSOF)     <='1' when i_rxdata=C_PDAT_SOF     and i_rxdtype=C_PDAT_TPRM                                   else '0';
i_rxtype(C_TEOF)     <='1' when i_rxdata=C_PDAT_EOF     and i_rxdtype=C_PDAT_TPRM                                   else '0';
i_rxtype(C_TDMAT)    <='1' when i_rxdata=C_PDAT_DMAT    and i_rxdtype=C_PDAT_TPRM                                   else '0';
i_rxtype(C_TCONT)    <='1' when i_rxdata=C_PDAT_CONT    and i_rxdtype=C_PDAT_TPRM                                   else '0';
i_rxtype(C_TSYNC)    <='1' when i_rxdata=C_PDAT_SYNC    and i_rxdtype=C_PDAT_TPRM                                   else '0';
i_rxtype(C_THOLD)    <='1' when i_rxdata=C_PDAT_HOLD    and i_rxdtype=C_PDAT_TPRM                                   else '0';
i_rxtype(C_THOLDA)   <='1' when i_rxdata=C_PDAT_HOLDA   and i_rxdtype=C_PDAT_TPRM                                   else '0';
i_rxtype(C_TX_RDY)   <='1' when i_rxdata=C_PDAT_X_RDY   and i_rxdtype=C_PDAT_TPRM                                   else '0';
i_rxtype(C_TR_RDY)   <='1' when i_rxdata=C_PDAT_R_RDY   and i_rxdtype=C_PDAT_TPRM                                   else '0';
i_rxtype(C_TR_IP)    <='1' when i_rxdata=C_PDAT_R_IP    and i_rxdtype=C_PDAT_TPRM                                   else '0';
i_rxtype(C_TR_OK)    <='1' when i_rxdata=C_PDAT_R_OK    and i_rxdtype=C_PDAT_TPRM                                   else '0';
i_rxtype(C_TR_ERR)   <='1' when i_rxdata=C_PDAT_R_ERR   and i_rxdtype=C_PDAT_TPRM                                   else '0';
i_rxtype(C_TWTRM)    <='1' when i_rxdata=C_PDAT_WTRM    and i_rxdtype=C_PDAT_TPRM                                   else '0';
i_rxtype(C_TPMREQ_P) <='1' when i_rxdata=C_PDAT_PMREQ_P and i_rxdtype=C_PDAT_TPRM                                   else '0';
i_rxtype(C_TPMREQ_S) <='1' when i_rxdata=C_PDAT_PMREQ_S and i_rxdtype=C_PDAT_TPRM                                   else '0';
i_rxtype(C_TPMACK)   <='1' when i_rxdata=C_PDAT_PMACK   and i_rxdtype=C_PDAT_TPRM                                   else '0';
i_rxtype(C_TPMNAK)   <='1' when i_rxdata=C_PDAT_PMNAK   and i_rxdtype=C_PDAT_TPRM                                   else '0';
i_rxtype(C_TDATA_EN) <='1' when                             i_rxdtype=C_PDAT_TDATA                                  else '0';

process(p_in_clk)
begin
  if p_in_clk'event and p_in_clk='1' then
    for i in C_TALIGN to C_TDATA_EN-1 loop
      i_rxdtype_out(i)<=i_rxtype(i);-- and not (OR_reduce(i_gt_rxdisperr) or OR_reduce(i_gt_rxnotintable));
    end loop;
    i_rxdtype_out(C_TDATA_EN)<=i_rxtype(C_TDATA_EN);
  end if;
end process;

end generate gen_dbus16;


--//------------------------------
--//GT: ШИНА ДАНЫХ=32bit
--//------------------------------
gen_dbus32 : if G_GT_DBUS=32 generate

i_rxdata<=p_in_gt_rxdata(31 downto 0);
i_rxdtype<=p_in_gt_rxcharisk(3 downto 0);

i_gt_rxdisperr<=p_in_gt_rxdisperr(3 downto 0);
i_gt_rxnotintable<=p_in_gt_rxnotintable(3 downto 0);

gen_typeout : for i in C_TALIGN to C_TDATA_EN-1 generate
i_rxdtype_out(i)<=i_rxdtype_out0(i);-- or i_rxdtype_out1(i) or i_rxdtype_out2(i) or i_rxdtype_out3(i);
end generate gen_typeout;

process(p_in_clk)
begin
  if p_in_clk'event and p_in_clk='1' then
--    i_rxdtype_out(C_TALIGN)<=p_in_gt_rxbyteisaligned and (i_rxtype(C_TALIGN) or i_rxtype1(C_TALIGN) or i_rxtype2(C_TALIGN) or i_rxtype3(C_TALIGN));
--    for i in C_TALIGN+1 to C_TDATA_EN-1 loop
--      i_rxdtype_out(i)<=i_rxtype(i) or i_rxtype1(i) or i_rxtype2(i) or i_rxtype3(i); --not (OR_reduce(i_gt_rxdisperr) or OR_reduce(i_gt_rxnotintable)) and
--    end loop;

    i_rxdtype_out0(C_TALIGN)<=p_in_gt_rxbyteisaligned and i_rxtype(C_TALIGN);
    for i in C_TALIGN+1 to C_TDATA_EN-1 loop
      i_rxdtype_out0(i)<=i_rxtype(i);
    end loop;

--    i_rxdtype_out1(C_TALIGN)<=p_in_gt_rxbyteisaligned and i_rxtype1(C_TALIGN);
--    for i in C_TALIGN+1 to C_TDATA_EN-1 loop
--      i_rxdtype_out1(i)<=i_rxtype1(i);
--    end loop;
--
--    i_rxdtype_out2(C_TALIGN)<=p_in_gt_rxbyteisaligned and i_rxtype2(C_TALIGN);
--    for i in C_TALIGN+1 to C_TDATA_EN-1 loop
--      i_rxdtype_out2(i)<=i_rxtype2(i);
--    end loop;
--
--    i_rxdtype_out3(C_TALIGN)<=p_in_gt_rxbyteisaligned and i_rxtype3(C_TALIGN);
--    for i in C_TALIGN+1 to C_TDATA_EN-1 loop
--      i_rxdtype_out3(i)<=i_rxtype3(i);
--    end loop;

    i_rxdtype_out(C_TDATA_EN)<=i_rxtype(C_TDATA_EN);
  end if;
end process;

i_rxtype (C_TDATA_EN) <='1' when i_rxdtype=C_PDAT_TDATA else '0';

i_rxtype (C_TALIGN)   <='1' when i_rxdtype=(C_CHAR_D & C_CHAR_D & C_CHAR_D & C_CHAR_K ) and i_rxdata = (C_PDAT_ALIGN  (31 downto 24) & C_PDAT_ALIGN  (23 downto 16) & C_PDAT_ALIGN  (15 downto 8) & C_PDAT_ALIGN  (7 downto 0))  else '0';
i_rxtype (C_TSOF)     <='1' when i_rxdtype=(C_CHAR_D & C_CHAR_D & C_CHAR_D & C_CHAR_K ) and i_rxdata = (C_PDAT_SOF    (31 downto 24) & C_PDAT_SOF    (23 downto 16) & C_PDAT_SOF    (15 downto 8) & C_PDAT_SOF    (7 downto 0))  else '0';
i_rxtype (C_TEOF)     <='1' when i_rxdtype=(C_CHAR_D & C_CHAR_D & C_CHAR_D & C_CHAR_K ) and i_rxdata = (C_PDAT_EOF    (31 downto 24) & C_PDAT_EOF    (23 downto 16) & C_PDAT_EOF    (15 downto 8) & C_PDAT_EOF    (7 downto 0))  else '0';
i_rxtype (C_TDMAT)    <='1' when i_rxdtype=(C_CHAR_D & C_CHAR_D & C_CHAR_D & C_CHAR_K ) and i_rxdata = (C_PDAT_DMAT   (31 downto 24) & C_PDAT_DMAT   (23 downto 16) & C_PDAT_DMAT   (15 downto 8) & C_PDAT_DMAT   (7 downto 0))  else '0';
i_rxtype (C_TCONT)    <='1' when i_rxdtype=(C_CHAR_D & C_CHAR_D & C_CHAR_D & C_CHAR_K ) and i_rxdata = (C_PDAT_CONT   (31 downto 24) & C_PDAT_CONT   (23 downto 16) & C_PDAT_CONT   (15 downto 8) & C_PDAT_CONT   (7 downto 0))  else '0';
i_rxtype (C_TSYNC)    <='1' when i_rxdtype=(C_CHAR_D & C_CHAR_D & C_CHAR_D & C_CHAR_K ) and i_rxdata = (C_PDAT_SYNC   (31 downto 24) & C_PDAT_SYNC   (23 downto 16) & C_PDAT_SYNC   (15 downto 8) & C_PDAT_SYNC   (7 downto 0))  else '0';
i_rxtype (C_THOLD)    <='1' when i_rxdtype=(C_CHAR_D & C_CHAR_D & C_CHAR_D & C_CHAR_K ) and i_rxdata = (C_PDAT_HOLD   (31 downto 24) & C_PDAT_HOLD   (23 downto 16) & C_PDAT_HOLD   (15 downto 8) & C_PDAT_HOLD   (7 downto 0))  else '0';
i_rxtype (C_THOLDA)   <='1' when i_rxdtype=(C_CHAR_D & C_CHAR_D & C_CHAR_D & C_CHAR_K ) and i_rxdata = (C_PDAT_HOLDA  (31 downto 24) & C_PDAT_HOLDA  (23 downto 16) & C_PDAT_HOLDA  (15 downto 8) & C_PDAT_HOLDA  (7 downto 0))  else '0';
i_rxtype (C_TX_RDY)   <='1' when i_rxdtype=(C_CHAR_D & C_CHAR_D & C_CHAR_D & C_CHAR_K ) and i_rxdata = (C_PDAT_X_RDY  (31 downto 24) & C_PDAT_X_RDY  (23 downto 16) & C_PDAT_X_RDY  (15 downto 8) & C_PDAT_X_RDY  (7 downto 0))  else '0';
i_rxtype (C_TR_RDY)   <='1' when i_rxdtype=(C_CHAR_D & C_CHAR_D & C_CHAR_D & C_CHAR_K ) and i_rxdata = (C_PDAT_R_RDY  (31 downto 24) & C_PDAT_R_RDY  (23 downto 16) & C_PDAT_R_RDY  (15 downto 8) & C_PDAT_R_RDY  (7 downto 0))  else '0';
i_rxtype (C_TR_IP)    <='1' when i_rxdtype=(C_CHAR_D & C_CHAR_D & C_CHAR_D & C_CHAR_K ) and i_rxdata = (C_PDAT_R_IP   (31 downto 24) & C_PDAT_R_IP   (23 downto 16) & C_PDAT_R_IP   (15 downto 8) & C_PDAT_R_IP   (7 downto 0))  else '0';
i_rxtype (C_TR_OK)    <='1' when i_rxdtype=(C_CHAR_D & C_CHAR_D & C_CHAR_D & C_CHAR_K ) and i_rxdata = (C_PDAT_R_OK   (31 downto 24) & C_PDAT_R_OK   (23 downto 16) & C_PDAT_R_OK   (15 downto 8) & C_PDAT_R_OK   (7 downto 0))  else '0';
i_rxtype (C_TR_ERR)   <='1' when i_rxdtype=(C_CHAR_D & C_CHAR_D & C_CHAR_D & C_CHAR_K ) and i_rxdata = (C_PDAT_R_ERR  (31 downto 24) & C_PDAT_R_ERR  (23 downto 16) & C_PDAT_R_ERR  (15 downto 8) & C_PDAT_R_ERR  (7 downto 0))  else '0';
i_rxtype (C_TWTRM)    <='1' when i_rxdtype=(C_CHAR_D & C_CHAR_D & C_CHAR_D & C_CHAR_K ) and i_rxdata = (C_PDAT_WTRM   (31 downto 24) & C_PDAT_WTRM   (23 downto 16) & C_PDAT_WTRM   (15 downto 8) & C_PDAT_WTRM   (7 downto 0))  else '0';
i_rxtype (C_TPMREQ_P) <='1' when i_rxdtype=(C_CHAR_D & C_CHAR_D & C_CHAR_D & C_CHAR_K ) and i_rxdata = (C_PDAT_PMREQ_P(31 downto 24) & C_PDAT_PMREQ_P(23 downto 16) & C_PDAT_PMREQ_P(15 downto 8) & C_PDAT_PMREQ_P(7 downto 0))  else '0';
i_rxtype (C_TPMREQ_S) <='1' when i_rxdtype=(C_CHAR_D & C_CHAR_D & C_CHAR_D & C_CHAR_K ) and i_rxdata = (C_PDAT_PMREQ_S(31 downto 24) & C_PDAT_PMREQ_S(23 downto 16) & C_PDAT_PMREQ_S(15 downto 8) & C_PDAT_PMREQ_S(7 downto 0))  else '0';
i_rxtype (C_TPMACK)   <='1' when i_rxdtype=(C_CHAR_D & C_CHAR_D & C_CHAR_D & C_CHAR_K ) and i_rxdata = (C_PDAT_PMACK  (31 downto 24) & C_PDAT_PMACK  (23 downto 16) & C_PDAT_PMACK  (15 downto 8) & C_PDAT_PMACK  (7 downto 0))  else '0';
i_rxtype (C_TPMNAK)   <='1' when i_rxdtype=(C_CHAR_D & C_CHAR_D & C_CHAR_D & C_CHAR_K ) and i_rxdata = (C_PDAT_PMNAK  (31 downto 24) & C_PDAT_PMNAK  (23 downto 16) & C_PDAT_PMNAK  (15 downto 8) & C_PDAT_PMNAK  (7 downto 0))  else '0';

--i_rxtype1(C_TALIGN)   <='1' when i_rxdtype=(C_CHAR_D & C_CHAR_D & C_CHAR_K & C_CHAR_D) and i_rxdata = (C_PDAT_ALIGN  (23 downto 16) & C_PDAT_ALIGN  (15 downto 8) & C_PDAT_ALIGN  (7 downto 0) & C_PDAT_ALIGN  (31 downto 24))  else '0';
--i_rxtype1(C_TSOF)     <='1' when i_rxdtype=(C_CHAR_D & C_CHAR_D & C_CHAR_K & C_CHAR_D) and i_rxdata = (C_PDAT_SOF    (23 downto 16) & C_PDAT_SOF    (15 downto 8) & C_PDAT_SOF    (7 downto 0) & C_PDAT_SOF    (31 downto 24))  else '0';
--i_rxtype1(C_TEOF)     <='1' when i_rxdtype=(C_CHAR_D & C_CHAR_D & C_CHAR_K & C_CHAR_D) and i_rxdata = (C_PDAT_EOF    (23 downto 16) & C_PDAT_EOF    (15 downto 8) & C_PDAT_EOF    (7 downto 0) & C_PDAT_EOF    (31 downto 24))  else '0';
--i_rxtype1(C_TDMAT)    <='1' when i_rxdtype=(C_CHAR_D & C_CHAR_D & C_CHAR_K & C_CHAR_D) and i_rxdata = (C_PDAT_DMAT   (23 downto 16) & C_PDAT_DMAT   (15 downto 8) & C_PDAT_DMAT   (7 downto 0) & C_PDAT_DMAT   (31 downto 24))  else '0';
--i_rxtype1(C_TCONT)    <='1' when i_rxdtype=(C_CHAR_D & C_CHAR_D & C_CHAR_K & C_CHAR_D) and i_rxdata = (C_PDAT_CONT   (23 downto 16) & C_PDAT_CONT   (15 downto 8) & C_PDAT_CONT   (7 downto 0) & C_PDAT_CONT   (31 downto 24))  else '0';
--i_rxtype1(C_TSYNC)    <='1' when i_rxdtype=(C_CHAR_D & C_CHAR_D & C_CHAR_K & C_CHAR_D) and i_rxdata = (C_PDAT_SYNC   (23 downto 16) & C_PDAT_SYNC   (15 downto 8) & C_PDAT_SYNC   (7 downto 0) & C_PDAT_SYNC   (31 downto 24))  else '0';
--i_rxtype1(C_THOLD)    <='1' when i_rxdtype=(C_CHAR_D & C_CHAR_D & C_CHAR_K & C_CHAR_D) and i_rxdata = (C_PDAT_HOLD   (23 downto 16) & C_PDAT_HOLD   (15 downto 8) & C_PDAT_HOLD   (7 downto 0) & C_PDAT_HOLD   (31 downto 24))  else '0';
--i_rxtype1(C_THOLDA)   <='1' when i_rxdtype=(C_CHAR_D & C_CHAR_D & C_CHAR_K & C_CHAR_D) and i_rxdata = (C_PDAT_HOLDA  (23 downto 16) & C_PDAT_HOLDA  (15 downto 8) & C_PDAT_HOLDA  (7 downto 0) & C_PDAT_HOLDA  (31 downto 24))  else '0';
--i_rxtype1(C_TX_RDY)   <='1' when i_rxdtype=(C_CHAR_D & C_CHAR_D & C_CHAR_K & C_CHAR_D) and i_rxdata = (C_PDAT_X_RDY  (23 downto 16) & C_PDAT_X_RDY  (15 downto 8) & C_PDAT_X_RDY  (7 downto 0) & C_PDAT_X_RDY  (31 downto 24))  else '0';
--i_rxtype1(C_TR_RDY)   <='1' when i_rxdtype=(C_CHAR_D & C_CHAR_D & C_CHAR_K & C_CHAR_D) and i_rxdata = (C_PDAT_R_RDY  (23 downto 16) & C_PDAT_R_RDY  (15 downto 8) & C_PDAT_R_RDY  (7 downto 0) & C_PDAT_R_RDY  (31 downto 24))  else '0';
--i_rxtype1(C_TR_IP)    <='1' when i_rxdtype=(C_CHAR_D & C_CHAR_D & C_CHAR_K & C_CHAR_D) and i_rxdata = (C_PDAT_R_IP   (23 downto 16) & C_PDAT_R_IP   (15 downto 8) & C_PDAT_R_IP   (7 downto 0) & C_PDAT_R_IP   (31 downto 24))  else '0';
--i_rxtype1(C_TR_OK)    <='1' when i_rxdtype=(C_CHAR_D & C_CHAR_D & C_CHAR_K & C_CHAR_D) and i_rxdata = (C_PDAT_R_OK   (23 downto 16) & C_PDAT_R_OK   (15 downto 8) & C_PDAT_R_OK   (7 downto 0) & C_PDAT_R_OK   (31 downto 24))  else '0';
--i_rxtype1(C_TR_ERR)   <='1' when i_rxdtype=(C_CHAR_D & C_CHAR_D & C_CHAR_K & C_CHAR_D) and i_rxdata = (C_PDAT_R_ERR  (23 downto 16) & C_PDAT_R_ERR  (15 downto 8) & C_PDAT_R_ERR  (7 downto 0) & C_PDAT_R_ERR  (31 downto 24))  else '0';
--i_rxtype1(C_TWTRM)    <='1' when i_rxdtype=(C_CHAR_D & C_CHAR_D & C_CHAR_K & C_CHAR_D) and i_rxdata = (C_PDAT_WTRM   (23 downto 16) & C_PDAT_WTRM   (15 downto 8) & C_PDAT_WTRM   (7 downto 0) & C_PDAT_WTRM   (31 downto 24))  else '0';
--i_rxtype1(C_TPMREQ_P) <='1' when i_rxdtype=(C_CHAR_D & C_CHAR_D & C_CHAR_K & C_CHAR_D) and i_rxdata = (C_PDAT_PMREQ_P(23 downto 16) & C_PDAT_PMREQ_P(15 downto 8) & C_PDAT_PMREQ_P(7 downto 0) & C_PDAT_PMREQ_P(31 downto 24))  else '0';
--i_rxtype1(C_TPMREQ_S) <='1' when i_rxdtype=(C_CHAR_D & C_CHAR_D & C_CHAR_K & C_CHAR_D) and i_rxdata = (C_PDAT_PMREQ_S(23 downto 16) & C_PDAT_PMREQ_S(15 downto 8) & C_PDAT_PMREQ_S(7 downto 0) & C_PDAT_PMREQ_S(31 downto 24))  else '0';
--i_rxtype1(C_TPMACK)   <='1' when i_rxdtype=(C_CHAR_D & C_CHAR_D & C_CHAR_K & C_CHAR_D) and i_rxdata = (C_PDAT_PMACK  (23 downto 16) & C_PDAT_PMACK  (15 downto 8) & C_PDAT_PMACK  (7 downto 0) & C_PDAT_PMACK  (31 downto 24))  else '0';
--i_rxtype1(C_TPMNAK)   <='1' when i_rxdtype=(C_CHAR_D & C_CHAR_D & C_CHAR_K & C_CHAR_D) and i_rxdata = (C_PDAT_PMNAK  (23 downto 16) & C_PDAT_PMNAK  (15 downto 8) & C_PDAT_PMNAK  (7 downto 0) & C_PDAT_PMNAK  (31 downto 24))  else '0';
--
--i_rxtype2(C_TALIGN)   <='1' when i_rxdtype=(C_CHAR_D & C_CHAR_K & C_CHAR_D & C_CHAR_D) and i_rxdata = (C_PDAT_ALIGN  (15 downto 8) & C_PDAT_ALIGN  (7 downto 0) & C_PDAT_ALIGN  (31 downto 24) & C_PDAT_ALIGN  (23 downto 16))  else '0';
--i_rxtype2(C_TSOF)     <='1' when i_rxdtype=(C_CHAR_D & C_CHAR_K & C_CHAR_D & C_CHAR_D) and i_rxdata = (C_PDAT_SOF    (15 downto 8) & C_PDAT_SOF    (7 downto 0) & C_PDAT_SOF    (31 downto 24) & C_PDAT_SOF    (23 downto 16))  else '0';
--i_rxtype2(C_TEOF)     <='1' when i_rxdtype=(C_CHAR_D & C_CHAR_K & C_CHAR_D & C_CHAR_D) and i_rxdata = (C_PDAT_EOF    (15 downto 8) & C_PDAT_EOF    (7 downto 0) & C_PDAT_EOF    (31 downto 24) & C_PDAT_EOF    (23 downto 16))  else '0';
--i_rxtype2(C_TDMAT)    <='1' when i_rxdtype=(C_CHAR_D & C_CHAR_K & C_CHAR_D & C_CHAR_D) and i_rxdata = (C_PDAT_DMAT   (15 downto 8) & C_PDAT_DMAT   (7 downto 0) & C_PDAT_DMAT   (31 downto 24) & C_PDAT_DMAT   (23 downto 16))  else '0';
--i_rxtype2(C_TCONT)    <='1' when i_rxdtype=(C_CHAR_D & C_CHAR_K & C_CHAR_D & C_CHAR_D) and i_rxdata = (C_PDAT_CONT   (15 downto 8) & C_PDAT_CONT   (7 downto 0) & C_PDAT_CONT   (31 downto 24) & C_PDAT_CONT   (23 downto 16))  else '0';
--i_rxtype2(C_TSYNC)    <='1' when i_rxdtype=(C_CHAR_D & C_CHAR_K & C_CHAR_D & C_CHAR_D) and i_rxdata = (C_PDAT_SYNC   (15 downto 8) & C_PDAT_SYNC   (7 downto 0) & C_PDAT_SYNC   (31 downto 24) & C_PDAT_SYNC   (23 downto 16))  else '0';
--i_rxtype2(C_THOLD)    <='1' when i_rxdtype=(C_CHAR_D & C_CHAR_K & C_CHAR_D & C_CHAR_D) and i_rxdata = (C_PDAT_HOLD   (15 downto 8) & C_PDAT_HOLD   (7 downto 0) & C_PDAT_HOLD   (31 downto 24) & C_PDAT_HOLD   (23 downto 16))  else '0';
--i_rxtype2(C_THOLDA)   <='1' when i_rxdtype=(C_CHAR_D & C_CHAR_K & C_CHAR_D & C_CHAR_D) and i_rxdata = (C_PDAT_HOLDA  (15 downto 8) & C_PDAT_HOLDA  (7 downto 0) & C_PDAT_HOLDA  (31 downto 24) & C_PDAT_HOLDA  (23 downto 16))  else '0';
--i_rxtype2(C_TX_RDY)   <='1' when i_rxdtype=(C_CHAR_D & C_CHAR_K & C_CHAR_D & C_CHAR_D) and i_rxdata = (C_PDAT_X_RDY  (15 downto 8) & C_PDAT_X_RDY  (7 downto 0) & C_PDAT_X_RDY  (31 downto 24) & C_PDAT_X_RDY  (23 downto 16))  else '0';
--i_rxtype2(C_TR_RDY)   <='1' when i_rxdtype=(C_CHAR_D & C_CHAR_K & C_CHAR_D & C_CHAR_D) and i_rxdata = (C_PDAT_R_RDY  (15 downto 8) & C_PDAT_R_RDY  (7 downto 0) & C_PDAT_R_RDY  (31 downto 24) & C_PDAT_R_RDY  (23 downto 16))  else '0';
--i_rxtype2(C_TR_IP)    <='1' when i_rxdtype=(C_CHAR_D & C_CHAR_K & C_CHAR_D & C_CHAR_D) and i_rxdata = (C_PDAT_R_IP   (15 downto 8) & C_PDAT_R_IP   (7 downto 0) & C_PDAT_R_IP   (31 downto 24) & C_PDAT_R_IP   (23 downto 16))  else '0';
--i_rxtype2(C_TR_OK)    <='1' when i_rxdtype=(C_CHAR_D & C_CHAR_K & C_CHAR_D & C_CHAR_D) and i_rxdata = (C_PDAT_R_OK   (15 downto 8) & C_PDAT_R_OK   (7 downto 0) & C_PDAT_R_OK   (31 downto 24) & C_PDAT_R_OK   (23 downto 16))  else '0';
--i_rxtype2(C_TR_ERR)   <='1' when i_rxdtype=(C_CHAR_D & C_CHAR_K & C_CHAR_D & C_CHAR_D) and i_rxdata = (C_PDAT_R_ERR  (15 downto 8) & C_PDAT_R_ERR  (7 downto 0) & C_PDAT_R_ERR  (31 downto 24) & C_PDAT_R_ERR  (23 downto 16))  else '0';
--i_rxtype2(C_TWTRM)    <='1' when i_rxdtype=(C_CHAR_D & C_CHAR_K & C_CHAR_D & C_CHAR_D) and i_rxdata = (C_PDAT_WTRM   (15 downto 8) & C_PDAT_WTRM   (7 downto 0) & C_PDAT_WTRM   (31 downto 24) & C_PDAT_WTRM   (23 downto 16))  else '0';
--i_rxtype2(C_TPMREQ_P) <='1' when i_rxdtype=(C_CHAR_D & C_CHAR_K & C_CHAR_D & C_CHAR_D) and i_rxdata = (C_PDAT_PMREQ_P(15 downto 8) & C_PDAT_PMREQ_P(7 downto 0) & C_PDAT_PMREQ_P(31 downto 24) & C_PDAT_PMREQ_P(23 downto 16))  else '0';
--i_rxtype2(C_TPMREQ_S) <='1' when i_rxdtype=(C_CHAR_D & C_CHAR_K & C_CHAR_D & C_CHAR_D) and i_rxdata = (C_PDAT_PMREQ_S(15 downto 8) & C_PDAT_PMREQ_S(7 downto 0) & C_PDAT_PMREQ_S(31 downto 24) & C_PDAT_PMREQ_S(23 downto 16))  else '0';
--i_rxtype2(C_TPMACK)   <='1' when i_rxdtype=(C_CHAR_D & C_CHAR_K & C_CHAR_D & C_CHAR_D) and i_rxdata = (C_PDAT_PMACK  (15 downto 8) & C_PDAT_PMACK  (7 downto 0) & C_PDAT_PMACK  (31 downto 24) & C_PDAT_PMACK  (23 downto 16))  else '0';
--i_rxtype2(C_TPMNAK)   <='1' when i_rxdtype=(C_CHAR_D & C_CHAR_K & C_CHAR_D & C_CHAR_D) and i_rxdata = (C_PDAT_PMNAK  (15 downto 8) & C_PDAT_PMNAK  (7 downto 0) & C_PDAT_PMNAK  (31 downto 24) & C_PDAT_PMNAK  (23 downto 16))  else '0';
--
--i_rxtype3(C_TALIGN)   <='1' when i_rxdtype=(C_CHAR_K & C_CHAR_D & C_CHAR_D & C_CHAR_D) and i_rxdata = (C_PDAT_ALIGN  (7 downto 0) & C_PDAT_ALIGN  (31 downto 24) & C_PDAT_ALIGN  (23 downto 16) & C_PDAT_ALIGN  (15 downto 8))  else '0';
--i_rxtype3(C_TSOF)     <='1' when i_rxdtype=(C_CHAR_K & C_CHAR_D & C_CHAR_D & C_CHAR_D) and i_rxdata = (C_PDAT_SOF    (7 downto 0) & C_PDAT_SOF    (31 downto 24) & C_PDAT_SOF    (23 downto 16) & C_PDAT_SOF    (15 downto 8))  else '0';
--i_rxtype3(C_TEOF)     <='1' when i_rxdtype=(C_CHAR_K & C_CHAR_D & C_CHAR_D & C_CHAR_D) and i_rxdata = (C_PDAT_EOF    (7 downto 0) & C_PDAT_EOF    (31 downto 24) & C_PDAT_EOF    (23 downto 16) & C_PDAT_EOF    (15 downto 8))  else '0';
--i_rxtype3(C_TDMAT)    <='1' when i_rxdtype=(C_CHAR_K & C_CHAR_D & C_CHAR_D & C_CHAR_D) and i_rxdata = (C_PDAT_DMAT   (7 downto 0) & C_PDAT_DMAT   (31 downto 24) & C_PDAT_DMAT   (23 downto 16) & C_PDAT_DMAT   (15 downto 8))  else '0';
--i_rxtype3(C_TCONT)    <='1' when i_rxdtype=(C_CHAR_K & C_CHAR_D & C_CHAR_D & C_CHAR_D) and i_rxdata = (C_PDAT_CONT   (7 downto 0) & C_PDAT_CONT   (31 downto 24) & C_PDAT_CONT   (23 downto 16) & C_PDAT_CONT   (15 downto 8))  else '0';
--i_rxtype3(C_TSYNC)    <='1' when i_rxdtype=(C_CHAR_K & C_CHAR_D & C_CHAR_D & C_CHAR_D) and i_rxdata = (C_PDAT_SYNC   (7 downto 0) & C_PDAT_SYNC   (31 downto 24) & C_PDAT_SYNC   (23 downto 16) & C_PDAT_SYNC   (15 downto 8))  else '0';
--i_rxtype3(C_THOLD)    <='1' when i_rxdtype=(C_CHAR_K & C_CHAR_D & C_CHAR_D & C_CHAR_D) and i_rxdata = (C_PDAT_HOLD   (7 downto 0) & C_PDAT_HOLD   (31 downto 24) & C_PDAT_HOLD   (23 downto 16) & C_PDAT_HOLD   (15 downto 8))  else '0';
--i_rxtype3(C_THOLDA)   <='1' when i_rxdtype=(C_CHAR_K & C_CHAR_D & C_CHAR_D & C_CHAR_D) and i_rxdata = (C_PDAT_HOLDA  (7 downto 0) & C_PDAT_HOLDA  (31 downto 24) & C_PDAT_HOLDA  (23 downto 16) & C_PDAT_HOLDA  (15 downto 8))  else '0';
--i_rxtype3(C_TX_RDY)   <='1' when i_rxdtype=(C_CHAR_K & C_CHAR_D & C_CHAR_D & C_CHAR_D) and i_rxdata = (C_PDAT_X_RDY  (7 downto 0) & C_PDAT_X_RDY  (31 downto 24) & C_PDAT_X_RDY  (23 downto 16) & C_PDAT_X_RDY  (15 downto 8))  else '0';
--i_rxtype3(C_TR_RDY)   <='1' when i_rxdtype=(C_CHAR_K & C_CHAR_D & C_CHAR_D & C_CHAR_D) and i_rxdata = (C_PDAT_R_RDY  (7 downto 0) & C_PDAT_R_RDY  (31 downto 24) & C_PDAT_R_RDY  (23 downto 16) & C_PDAT_R_RDY  (15 downto 8))  else '0';
--i_rxtype3(C_TR_IP)    <='1' when i_rxdtype=(C_CHAR_K & C_CHAR_D & C_CHAR_D & C_CHAR_D) and i_rxdata = (C_PDAT_R_IP   (7 downto 0) & C_PDAT_R_IP   (31 downto 24) & C_PDAT_R_IP   (23 downto 16) & C_PDAT_R_IP   (15 downto 8))  else '0';
--i_rxtype3(C_TR_OK)    <='1' when i_rxdtype=(C_CHAR_K & C_CHAR_D & C_CHAR_D & C_CHAR_D) and i_rxdata = (C_PDAT_R_OK   (7 downto 0) & C_PDAT_R_OK   (31 downto 24) & C_PDAT_R_OK   (23 downto 16) & C_PDAT_R_OK   (15 downto 8))  else '0';
--i_rxtype3(C_TR_ERR)   <='1' when i_rxdtype=(C_CHAR_K & C_CHAR_D & C_CHAR_D & C_CHAR_D) and i_rxdata = (C_PDAT_R_ERR  (7 downto 0) & C_PDAT_R_ERR  (31 downto 24) & C_PDAT_R_ERR  (23 downto 16) & C_PDAT_R_ERR  (15 downto 8))  else '0';
--i_rxtype3(C_TWTRM)    <='1' when i_rxdtype=(C_CHAR_K & C_CHAR_D & C_CHAR_D & C_CHAR_D) and i_rxdata = (C_PDAT_WTRM   (7 downto 0) & C_PDAT_WTRM   (31 downto 24) & C_PDAT_WTRM   (23 downto 16) & C_PDAT_WTRM   (15 downto 8))  else '0';
--i_rxtype3(C_TPMREQ_P) <='1' when i_rxdtype=(C_CHAR_K & C_CHAR_D & C_CHAR_D & C_CHAR_D) and i_rxdata = (C_PDAT_PMREQ_P(7 downto 0) & C_PDAT_PMREQ_P(31 downto 24) & C_PDAT_PMREQ_P(23 downto 16) & C_PDAT_PMREQ_P(15 downto 8))  else '0';
--i_rxtype3(C_TPMREQ_S) <='1' when i_rxdtype=(C_CHAR_K & C_CHAR_D & C_CHAR_D & C_CHAR_D) and i_rxdata = (C_PDAT_PMREQ_S(7 downto 0) & C_PDAT_PMREQ_S(31 downto 24) & C_PDAT_PMREQ_S(23 downto 16) & C_PDAT_PMREQ_S(15 downto 8))  else '0';
--i_rxtype3(C_TPMACK)   <='1' when i_rxdtype=(C_CHAR_K & C_CHAR_D & C_CHAR_D & C_CHAR_D) and i_rxdata = (C_PDAT_PMACK  (7 downto 0) & C_PDAT_PMACK  (31 downto 24) & C_PDAT_PMACK  (23 downto 16) & C_PDAT_PMACK  (15 downto 8))  else '0';
--i_rxtype3(C_TPMNAK)   <='1' when i_rxdtype=(C_CHAR_K & C_CHAR_D & C_CHAR_D & C_CHAR_D) and i_rxdata = (C_PDAT_PMNAK  (7 downto 0) & C_PDAT_PMNAK  (31 downto 24) & C_PDAT_PMNAK  (23 downto 16) & C_PDAT_PMNAK  (15 downto 8))  else '0';

end generate gen_dbus32;



--//-----------------------------------
--//Debug/Sim
--//-----------------------------------
gen_sim_off : if strcmp(G_SIM,"OFF") generate
p_out_dbg.name<=(others=>'0');
end generate gen_sim_off;

gen_sim_on : if strcmp(G_SIM,"ON") generate

rcv_name: process(p_in_clk)
begin
if p_in_clk'event and p_in_clk='1' then
  if    i_rxdata=C_PDAT_ALIGN   and i_rxdtype=C_PDAT_TPRM  then dbgrcv_type<=C_PNAME_STR(C_TALIGN);
  elsif i_rxdata=C_PDAT_SOF     and i_rxdtype=C_PDAT_TPRM  then dbgrcv_type<=C_PNAME_STR(C_TSOF);
  elsif i_rxdata=C_PDAT_EOF     and i_rxdtype=C_PDAT_TPRM  then dbgrcv_type<=C_PNAME_STR(C_TEOF);
  elsif i_rxdata=C_PDAT_DMAT    and i_rxdtype=C_PDAT_TPRM  then dbgrcv_type<=C_PNAME_STR(C_TDMAT);
  elsif i_rxdata=C_PDAT_CONT    and i_rxdtype=C_PDAT_TPRM  then dbgrcv_type<=C_PNAME_STR(C_TCONT);
  elsif i_rxdata=C_PDAT_SYNC    and i_rxdtype=C_PDAT_TPRM  then dbgrcv_type<=C_PNAME_STR(C_TSYNC);
  elsif i_rxdata=C_PDAT_HOLD    and i_rxdtype=C_PDAT_TPRM  then dbgrcv_type<=C_PNAME_STR(C_THOLD);
  elsif i_rxdata=C_PDAT_HOLDA   and i_rxdtype=C_PDAT_TPRM  then dbgrcv_type<=C_PNAME_STR(C_THOLDA);
  elsif i_rxdata=C_PDAT_X_RDY   and i_rxdtype=C_PDAT_TPRM  then dbgrcv_type<=C_PNAME_STR(C_TX_RDY);
  elsif i_rxdata=C_PDAT_R_RDY   and i_rxdtype=C_PDAT_TPRM  then dbgrcv_type<=C_PNAME_STR(C_TR_RDY);
  elsif i_rxdata=C_PDAT_R_IP    and i_rxdtype=C_PDAT_TPRM  then dbgrcv_type<=C_PNAME_STR(C_TR_IP);
  elsif i_rxdata=C_PDAT_R_OK    and i_rxdtype=C_PDAT_TPRM  then dbgrcv_type<=C_PNAME_STR(C_TR_OK);
  elsif i_rxdata=C_PDAT_R_ERR   and i_rxdtype=C_PDAT_TPRM  then dbgrcv_type<=C_PNAME_STR(C_TR_ERR);
  elsif i_rxdata=C_PDAT_WTRM    and i_rxdtype=C_PDAT_TPRM  then dbgrcv_type<=C_PNAME_STR(C_TWTRM);
  elsif i_rxdata=C_PDAT_PMREQ_P and i_rxdtype=C_PDAT_TPRM  then dbgrcv_type<=C_PNAME_STR(C_TPMREQ_P);
  elsif i_rxdata=C_PDAT_PMREQ_S and i_rxdtype=C_PDAT_TPRM  then dbgrcv_type<=C_PNAME_STR(C_TPMREQ_S);
  elsif i_rxdata=C_PDAT_PMACK   and i_rxdtype=C_PDAT_TPRM  then dbgrcv_type<=C_PNAME_STR(C_TPMACK);
  elsif i_rxdata=C_PDAT_PMNAK   and i_rxdtype=C_PDAT_TPRM  then dbgrcv_type<=C_PNAME_STR(C_TPMNAK);
  elsif                             i_rxdtype=C_PDAT_TDATA then dbgrcv_type<=C_PNAME_STR(C_TDATA_EN);
  end if;

end if;
end process rcv_name;

p_out_dbg.name<=dbgrcv_type;

end generate gen_sim_on;

p_out_dbg.rxd<=i_rxdata_out;



--END MAIN
end behavioral;
