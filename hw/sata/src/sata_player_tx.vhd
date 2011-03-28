-------------------------------------------------------------------------
-- Company     : Linkos
-- Engineer    : Golovachenko Victor
--
-- Create Date : 05.02.2011 14:15:28
-- Module Name : sata_player_tx
--
-- Назначение/Описание :
--   Выдача данных для передатчика RocketIO:
--     - Передача SATA примитивов по запросу с портов p_in_txreq или p_in_d10_2_send_dis
--     - Передача пользовательской информации с порта p_in_txd
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

library unisim;
use unisim.vcomponents.all;

use work.vicg_common_pkg.all;
use work.sata_unit_pkg.all;
use work.sata_pkg.all;
use work.sata_sim_lite_pkg.all;

entity sata_player_tx is
generic
(
G_GTP_DBUS : integer := 16;
G_DBG      : string  := "OFF";
G_SIM      : string  := "OFF"
);
port
(
--------------------------------------------------
--
--------------------------------------------------
p_in_d10_2_send_dis    : in    std_logic;                    --//Запрещение передачи кода D10.2
p_in_sync              : in    std_logic;                    --//
p_in_txreq             : in    std_logic_vector(7 downto 0); --//Запрос на передачу SATA
p_in_txd               : in    std_logic_vector(31 downto 0);--//Данные для передатчика (полезная нагрузка, а не примитивы SATA)
p_out_rdy_n            : out   std_logic;                    --//Готов к загрузке данных для передачи

--------------------------------------------------
--RocketIO Transmiter (Назначение портов см. sata_rocketio.vhd)
--------------------------------------------------
p_out_gtp_txdata       : out   std_logic_vector(15 downto 0);
p_out_gtp_txcharisk    : out   std_logic_vector(1 downto 0);

--------------------------------------------------
--Технологические сигналы
--------------------------------------------------
p_in_tst               : in    std_logic_vector(31 downto 0);
p_out_tst              : out   std_logic_vector(31 downto 0);

--------------------------------------------------
--System
--------------------------------------------------
p_in_clk               : in    std_logic;
p_in_rst               : in    std_logic
);
end sata_player_tx;

architecture behavioral of sata_player_tx is

constant CI_ALIGN_TMR   : integer:=selval(C_ALIGN_TMR, C_SIM_SATAHOST_TMR_ALIGN, strcmp(G_SIM,"OFF"));--//в DW

signal i_align_tmr                : std_logic_vector(10 downto 0);--
signal i_align_txen               : std_logic;
signal i_align_burst_cnt          : std_logic_vector(log2(C_ALIGN_BURST)-1 downto 0);

signal i_suspend                  : std_logic_vector(C_THOLD downto C_TSOF);

signal i_srambler_init            : std_logic;
signal i_srambler_out             : std_logic_vector(31 downto 0);

signal sr_txdata                  : std_logic_vector(31 downto 0);
signal sr_txdtype                 : std_logic_vector(3 downto 0);

type TDly1SrD is array (0 to 3) of std_logic_vector(7 downto 0);
signal sr_ddly                    : TDly1SrD;
type TDly1SrT is array (0 to 3) of std_logic;
signal sr_tdly                    : TDly1SrT;

type TDly2SrD is array (0 to 3) of std_logic_vector(15 downto 0);
signal sr_ddly2                   : TDly2SrD;
type TDly2SrT is array (0 to 3) of std_logic_vector(1 downto 0);
signal sr_tdly2                   : TDly2SrT;


signal tst_pltx_status            : TSimPLTxStatus;
signal tst_val                    : std_logic;
signal dbgtsf_type                : string(1 to 7);


--MAIN
begin

--//----------------------------------
--//Технологические сигналы
--//----------------------------------
gen_dbg_off : if strcmp(G_DBG,"OFF") generate
p_out_tst(0)<=tst_val;
p_out_tst(31 downto 1)<=(others=>'0');
end generate gen_dbg_off;

gen_dbg_on : if strcmp(G_DBG,"ON") generate
--ltstout:process(p_in_rst,p_in_clk)
--begin
--  if p_in_rst='1' then
--    p_out_tst(31 downto 2)<=(others=>'0');
--  elsif p_in_clk'event and p_in_clk='1' then
--    p_out_tst(1)<=tst_synch;
--  end if;
--end process ltstout;
p_out_tst(0)<=tst_val;
p_out_tst(31 downto 1)<=(others=>'0');

end generate gen_dbg_on;



--//-------------------------------------
--//TMR/BURST ALIGN
--//-------------------------------------
lalign:process(p_in_rst,p_in_clk)
begin
  if p_in_rst='1' then
    i_align_tmr<=(others=>'0');
    i_align_burst_cnt<=(others=>'0');
    i_align_txen<='0';
  elsif p_in_clk'event and p_in_clk='1' then
    if p_in_sync='1' then
        --//TMR
        if p_in_d10_2_send_dis='0' or i_align_tmr=CONV_STD_LOGIC_VECTOR(CI_ALIGN_TMR-1, i_align_tmr'length) then
          i_align_tmr<=(others=>'0');
        else
          i_align_tmr<=i_align_tmr+1;
        end if;

        --//ALIGN send enable
        if i_align_tmr=CONV_STD_LOGIC_VECTOR(CI_ALIGN_TMR-1, i_align_tmr'length) then
          i_align_txen<='1';
        elsif i_align_txen='1' and i_align_burst_cnt=CONV_STD_LOGIC_VECTOR(C_ALIGN_BURST-1, i_align_burst_cnt'length) then
          i_align_txen<='0';
        end if;

        --//BURST
        if p_in_d10_2_send_dis='0' or (i_align_txen='1' and i_align_burst_cnt=CONV_STD_LOGIC_VECTOR(C_ALIGN_BURST-1, i_align_burst_cnt'length)) then
          i_align_burst_cnt<=(others=>'0');
        else
          if i_align_txen='1' then
            i_align_burst_cnt<=i_align_burst_cnt+1;
          end if;
        end if;

    end if;--//if p_in_sync='1' then
  end if;
end process lalign;

p_out_rdy_n<=i_align_txen;

--//-------------------------------------
--//Генератор случайных чисел.
--//Используется после отправки примитива CONT
--//-------------------------------------
i_srambler_init<=not p_in_d10_2_send_dis;

m_scrambler : sata_scrambler
generic map
(
G_INIT_VAL   => 16#F0F6#
)
port map
(
p_in_SOF     => i_srambler_init,
p_in_en      => p_in_sync,
p_out_result => i_srambler_out,

--------------------------------------------------
--System
--------------------------------------------------
--p_in_clk_en  => '1',
p_in_clk     => p_in_clk,
p_in_rst     => p_in_rst
);

--//Ждем когда произойдет отложеная передача примитива
lsuspend:process(p_in_rst,p_in_clk)
begin
  if p_in_rst='1' then
    i_suspend<=(others=>'0');

  elsif p_in_clk'event and p_in_clk='1' then
    if p_in_sync='1' then
    --//
        if i_align_txen='1' then
            if i_align_burst_cnt=(i_align_burst_cnt'range =>'0') then

                  --//Запрос на передачу примитива совпал с временем выдачи примитива ALIGN (BURST ALIGN)
                  --//В этом случае запрос на выдачу примитива откладываем на время выдачи (BURST ALIGN)
                  --//т.е. будет отложеная передача примитива
                  if    CONV_INTEGER(p_in_txreq)=C_THOLD  then i_suspend(C_THOLD)<='1';
                  elsif CONV_INTEGER(p_in_txreq)=C_THOLDA then i_suspend(C_THOLDA)<='1';
                  elsif CONV_INTEGER(p_in_txreq)=C_TSOF   then i_suspend(C_TSOF)<='1';
                  elsif CONV_INTEGER(p_in_txreq)=C_TEOF   then i_suspend(C_TEOF)<='1';

                  end if;

            end if;

        else
          i_suspend<=(others=>'0');

        end if;

    end if;
  end if;
end process lsuspend;

--//Передача данных/примитивов
ltxd:process(p_in_rst,p_in_clk)
begin
  if p_in_rst='1' then
    sr_txdata<=(others=>'0');
    sr_txdtype<=(others=>'0');

  elsif p_in_clk'event and p_in_clk='1' then
    if p_in_sync='1' then
    --//Загрузка данных для передачи:
      if p_in_d10_2_send_dis='0' then
      --//Передача D10.2
          sr_txdata<=C_D10_2&C_D10_2&C_D10_2&C_D10_2; sr_txdtype<=C_PDAT_TDATA;

      elsif i_align_txen='1' then
      --//Передача ALIGN
          sr_txdata<=C_PDAT_ALIGN; sr_txdtype<=C_PDAT_TPRM;

      elsif i_suspend/=(i_suspend'range =>'0') then
      --//Передача отложеный примитив
          if i_suspend(C_THOLD)='1' then
            sr_txdata<=C_PDAT_HOLD; sr_txdtype<=C_PDAT_TPRM;

          elsif i_suspend(C_THOLDA)='1' then
            sr_txdata<=C_PDAT_HOLDA; sr_txdtype<=C_PDAT_TPRM;

          elsif i_suspend(C_TSOF)='1' then
            sr_txdata<=C_PDAT_SOF; sr_txdtype<=C_PDAT_TPRM;

          else --if i_suspend(C_TEOF)='1' then
            sr_txdata<=C_PDAT_EOF; sr_txdtype<=C_PDAT_TPRM;

          end if;

      else
      --//Передача по запросу от Link Layer
          case CONV_INTEGER(p_in_txreq) is
            when C_TALIGN   => sr_txdata<=C_PDAT_ALIGN;   sr_txdtype<=C_PDAT_TPRM;
            when C_TSOF     => sr_txdata<=C_PDAT_SOF;     sr_txdtype<=C_PDAT_TPRM;
            when C_TEOF     => sr_txdata<=C_PDAT_EOF;     sr_txdtype<=C_PDAT_TPRM;
            when C_TDMAT    => sr_txdata<=C_PDAT_DMAT;    sr_txdtype<=C_PDAT_TPRM;
            when C_TCONT    => sr_txdata<=C_PDAT_CONT;    sr_txdtype<=C_PDAT_TPRM;
            when C_TSYNC    => sr_txdata<=C_PDAT_SYNC;    sr_txdtype<=C_PDAT_TPRM;
            when C_THOLD    => sr_txdata<=C_PDAT_HOLD;    sr_txdtype<=C_PDAT_TPRM;
            when C_THOLDA   => sr_txdata<=C_PDAT_HOLDA;   sr_txdtype<=C_PDAT_TPRM;
            when C_TX_RDY   => sr_txdata<=C_PDAT_X_RDY;   sr_txdtype<=C_PDAT_TPRM;
            when C_TR_RDY   => sr_txdata<=C_PDAT_R_RDY;   sr_txdtype<=C_PDAT_TPRM;
            when C_TR_IP    => sr_txdata<=C_PDAT_R_IP;    sr_txdtype<=C_PDAT_TPRM;
            when C_TR_OK    => sr_txdata<=C_PDAT_R_OK;    sr_txdtype<=C_PDAT_TPRM;
            when C_TR_ERR   => sr_txdata<=C_PDAT_R_ERR;   sr_txdtype<=C_PDAT_TPRM;
            when C_TWTRM    => sr_txdata<=C_PDAT_WTRM;    sr_txdtype<=C_PDAT_TPRM;
            when C_TPMREQ_P => sr_txdata<=C_PDAT_PMREQ_P; sr_txdtype<=C_PDAT_TPRM;
            when C_TPMREQ_S => sr_txdata<=C_PDAT_PMREQ_S; sr_txdtype<=C_PDAT_TPRM;
            when C_TPMACK   => sr_txdata<=C_PDAT_PMACK;   sr_txdtype<=C_PDAT_TPRM;
            when C_TPMNAK   => sr_txdata<=C_PDAT_PMNAK;   sr_txdtype<=C_PDAT_TPRM;

            when C_TDATA_EN => sr_txdata<=p_in_txd; sr_txdtype<=C_PDAT_TDATA;--Передача данных FRAME

            when others => sr_txdata<=i_srambler_out; sr_txdtype<=C_PDAT_TDATA;--//Передаем Скремблер - в случае если нету ни одного
                                                                               --//из выше перечисленых запросов отправки данных
          end case;
      end if;
    else
        sr_txdata<=sr_txdata(G_GTP_DBUS-1 downto 0) & sr_txdata(31 downto G_GTP_DBUS);
        sr_txdtype<=sr_txdtype(G_GTP_DBUS/8-1 downto 0) & sr_txdtype(3 downto G_GTP_DBUS/8);

    end if;
  end if;
end process ltxd;


--GTP: ШИНА ДАНЫХ=8bit
gen_dbus8 : if G_GTP_DBUS=8 generate

--//Подстройка
ltxd_sr:process(p_in_rst,p_in_clk)
begin
  if p_in_rst='1' then
    for i in 0 to 3 loop
      sr_ddly(i)<=(others=>'0');
      sr_tdly(i)<='0';
    end loop;
  elsif p_in_clk'event and p_in_clk='1' then
    sr_ddly<=sr_txdata(7 downto 0) & sr_ddly(0 to 2);
    sr_tdly<=sr_txdtype(0) & sr_tdly(0 to 2);
  end if;
end process ltxd_sr;

p_out_gtp_txdata(7 downto 0)<=sr_ddly(2);
p_out_gtp_txcharisk(0)<=sr_tdly(2);

p_out_gtp_txdata(15 downto 8)<=(others=>'0');
p_out_gtp_txcharisk(1)<='0';

end generate gen_dbus8;


--GTP: ШИНА ДАНЫХ=16bit
gen_dbus16 : if G_GTP_DBUS=16 generate

----//Подстройка
--ltxd_sr:process(p_in_rst,p_in_clk)
--begin
--  if p_in_rst='1' then
--    for i in 0 to 3 loop
--      sr_ddly2(i)<=(others=>'0');
--      sr_tdly2(i)<=(others=>'0');
--    end loop;
--  elsif p_in_clk'event and p_in_clk='1' then
--    sr_ddly2<=sr_txdata(15 downto 0) & sr_ddly2(0 to 2);
--    sr_tdly2<=sr_txdtype(1 downto 0) & sr_tdly2(0 to 2);
--  end if;
--end process ltxd_sr;

p_out_gtp_txdata<=sr_txdata(15 downto 0);--sr_ddly2(2);
p_out_gtp_txcharisk<=sr_txdtype(1 downto 0);--sr_tdly2(2);

end generate gen_dbus16;



--//Только для моделирования (удобства алализа данных при моделироании)
gen_sim_on : if strcmp(G_SIM,"ON") generate

tst_pltx_status.req_name<=dbgtsf_type;
tst_pltx_status.suspend_phold<=i_suspend(C_THOLD);
tst_pltx_status.suspend_pholda<=i_suspend(C_THOLDA);
tst_pltx_status.suspend_psof<=i_suspend(C_TSOF);
tst_pltx_status.suspend_peof<=i_suspend(C_TEOF);

rq_name: process(p_in_txreq,tst_pltx_status)
begin

  dbgtsf_type<=C_PNAME_STR(CONV_INTEGER(p_in_txreq));

  if dbgtsf_type=C_PNAME_STR(C_TALIGN) and tst_pltx_status.suspend_psof='1' then
    tst_val<='1';
  else
    tst_val<='0';
  end if;
end process rq_name;

end generate gen_sim_on;

gen_sim_off : if strcmp(G_SIM,"OFF") generate
tst_val<='0';
end generate gen_sim_off;

--END MAIN
end behavioral;

