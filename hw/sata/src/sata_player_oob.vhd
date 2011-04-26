-------------------------------------------------------------------------
-- Company     : Linkos
-- Engineer    : Golovachenko Victor
--
-- Create Date : 25/11/2008
-- Module Name : sata_player_oob
--
-- Назначение/Описание :
--   1. Обнаружение и установление соединения с SATA уст-вом.
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
use work.sata_pkg.all;
use work.sata_sim_lite_pkg.all;

entity sata_player_oob is
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
p_in_ctrl              : in    std_logic_vector(C_PLCTRL_LAST_BIT downto 0);--//Константы см. sata_pkg.vhd/поле - PHY Layer/Управление/Map:
p_out_status           : out   std_logic_vector(C_PLSTAT_LAST_BIT downto 0);--//Константы см. sata_pkg.vhd/поле - PHY Layer/Статусы/Map

p_in_primitive_det     : in    std_logic_vector(C_TPMNAK downto C_TALIGN);--//Константы см. sata_pkg.vhd/поле - PHY Layer/номера примитивов
p_out_d10_2_senddis    : out   std_logic;                    --//Запрещение передачи кода D10.2

--------------------------------------------------
--RocketIO Receiver
--------------------------------------------------
p_out_gtp_txelecidle   : out   std_logic;                    --//TX electircal idel
p_out_gtp_txcomstart   : out   std_logic;                    --//TX OOB enable
p_out_gtp_txcomtype    : out   std_logic;                    --//TX OOB type select

p_in_gtp_rxelecidle    : in    std_logic;                    --//RX electrical idle
p_in_gtp_rxstatus      : in    std_logic_vector(2 downto 0); --//RX OOB type

p_out_gtp_rst          : out   std_logic;                    --//Сброс Tx/Rx PCM

--------------------------------------------------
--Технологические сигналы
--------------------------------------------------
p_in_tst               : in    std_logic_vector(31 downto 0);
p_out_tst              : out   std_logic_vector(31 downto 0);
p_out_dbg              : out   TPLoob_dbgport;

--------------------------------------------------
--System
--------------------------------------------------
p_in_tmrclk            : in    std_logic;--//Тактирование таймера timeout. Частота должна быть 75MHz!!!
p_in_clk               : in    std_logic;
p_in_rst               : in    std_logic
);
end sata_player_oob;

architecture behavioral of sata_player_oob is

signal fsm_ploob_cs             : TPLoob_fsm_state;

signal i_gtp_txelecidle         : std_logic;
signal i_gtp_txcomstart         : std_logic;
signal i_gtp_txcomtype          : std_logic;
signal i_gtp_pcm_rst            : std_logic;

signal i_tmr                    : std_logic_vector(17 downto 0);--//timer-timeout
signal i_tmrout                 : std_logic;                    --//timeout - clk domane p_in_tmrclk

signal i_timeout                : std_logic;                    --//timeout - clk domane p_in_clk
signal i_timer_rst_n            : std_logic;                    --//Сброс таймера timqout


signal i_status                 : std_logic_vector(C_PLSTAT_LAST_BIT downto 0);

signal i_d10_2_senddis          : std_logic;
signal i_rx_prmt_cnt            : std_logic_vector(1 downto 0);


signal tst_val                  : std_logic;
signal tst_pl_ctrl              : TSimPLCtrl;
signal tst_pl_status            : TSimPLStatus;
signal tst_fms_cs               : std_logic_vector(3 downto 0);
signal tst_fms_cs_dly           : std_logic_vector(tst_fms_cs'range);


--MAIN
begin

--//----------------------------------
--//Технологические сигналы
--//----------------------------------
gen_dbg_off : if strcmp(G_DBG,"OFF") generate
p_out_tst(31 downto 0)<=(others=>'0');
end generate gen_dbg_off;

gen_dbg_on : if strcmp(G_DBG,"ON") generate
ltstout:process(p_in_rst,p_in_clk)
begin
  if p_in_rst='1' then
    tst_fms_cs_dly<=(others=>'0');
    p_out_tst(31 downto 1)<=(others=>'0');
  elsif p_in_clk'event and p_in_clk='1' then

    tst_fms_cs_dly<=tst_fms_cs;
    p_out_tst(0)<=tst_val or OR_reduce(tst_fms_cs_dly);

  end if;
end process ltstout;

tst_fms_cs<=CONV_STD_LOGIC_VECTOR(16#01#, tst_fms_cs'length) when fsm_ploob_cs=S_HR_COMRESET_DONE else
            CONV_STD_LOGIC_VECTOR(16#02#, tst_fms_cs'length) when fsm_ploob_cs=S_HR_AwaitCOMINIT else
            CONV_STD_LOGIC_VECTOR(16#03#, tst_fms_cs'length) when fsm_ploob_cs=S_HR_COMWAKE else
            CONV_STD_LOGIC_VECTOR(16#04#, tst_fms_cs'length) when fsm_ploob_cs=S_HR_COMWAKE_DONE else
            CONV_STD_LOGIC_VECTOR(16#05#, tst_fms_cs'length) when fsm_ploob_cs=S_HR_AwaitCOMWAKE else
            CONV_STD_LOGIC_VECTOR(16#06#, tst_fms_cs'length) when fsm_ploob_cs=S_HR_AwaitNoCOMWAKE else
            CONV_STD_LOGIC_VECTOR(16#07#, tst_fms_cs'length) when fsm_ploob_cs=S_HR_AwaitAlign else
            CONV_STD_LOGIC_VECTOR(16#08#, tst_fms_cs'length) when fsm_ploob_cs=S_HR_SendAlign else
            CONV_STD_LOGIC_VECTOR(16#09#, tst_fms_cs'length) when fsm_ploob_cs=S_HR_Ready else
            CONV_STD_LOGIC_VECTOR(16#00#, tst_fms_cs'length); --//when fsm_ploob_cs=S_HR_COMRESET

end generate gen_dbg_on;



--//----------------------------------
--//Связь с main PHY Layer
--//----------------------------------
p_out_d10_2_senddis<= i_d10_2_senddis;

p_out_status<=i_status;

p_out_gtp_txelecidle<= i_gtp_txelecidle;
p_out_gtp_txcomstart<= i_gtp_txcomstart;
p_out_gtp_txcomtype <= i_gtp_txcomtype;

p_out_gtp_rst<=i_gtp_pcm_rst;

--//--------------------------------------------------
--//timer-timeout(ВАЖНО: тактирование от 75MHz)
--//--------------------------------------------------
ltimeout:process(p_in_rst,i_timer_rst_n,p_in_tmrclk)
begin
  if p_in_rst='1' or i_timer_rst_n='0' then
    i_tmr<=(others=>'0');
    i_tmrout<='0';
  elsif p_in_tmrclk'event and p_in_tmrclk='1' then

    i_tmr<=i_tmr+1;

    if i_tmr=CONV_STD_LOGIC_VECTOR(C_OOB_TIMEOUT, i_tmr'length) then
      i_tmrout<='1';
    end if;

  end if;
end process ltimeout;


--//--------------------------------------------------
--//Автомат управления:
--//Реализуюет процедуру установления соединения с SATA устройством
--//--------------------------------------------------
lfsm:process(p_in_rst,p_in_clk)
begin
  if p_in_rst='1' then
    fsm_ploob_cs <= S_HR_COMRESET;

    i_gtp_txcomstart<='0';
    i_gtp_txcomtype <='0';
    i_gtp_txelecidle<='1';
    i_gtp_pcm_rst<='0';

    i_status<=(others=>'0');
    i_d10_2_senddis<='0';

    i_timer_rst_n<='0';
    i_timeout<='0';
    i_rx_prmt_cnt<=(others=>'0');

  elsif p_in_clk'event and p_in_clk='1' then

    i_timeout<=i_tmrout;

    case fsm_ploob_cs is

      --//-------------------------------
      --//Отправка сигнала COMRESET
      --//-------------------------------
      when S_HR_COMRESET =>

        i_gtp_txelecidle<='1';
        i_d10_2_senddis<='0';
        i_status<=(others=>'0');

        i_gtp_txcomstart<='1';--//Запуск отправки сигналов COMRESET
        i_gtp_txcomtype <='0';
        fsm_ploob_cs <= S_HR_COMRESET_DONE;

      when S_HR_COMRESET_DONE =>

        i_gtp_txcomstart<='0';

        if p_in_gtp_rxstatus(0)='1' then
        --//Жду завершиения отправки сигналов COMRESET
          i_timer_rst_n<='1';
          fsm_ploob_cs <= S_HR_AwaitCOMINIT;
        end if;


      --//-------------------------------
      --//Жду от устройства сигнал COMINIT
      --//-------------------------------
      when S_HR_AwaitCOMINIT =>

        if p_in_gtp_rxelecidle='1' and p_in_gtp_rxstatus = "100" then
            --Обнаружил сигнал COMINIT
            i_timer_rst_n<='0';
            fsm_ploob_cs <= S_HR_COMWAKE;

        else
          if i_timeout='1' then
            i_timer_rst_n<='0';
            fsm_ploob_cs <= S_HR_COMRESET;
          end if;
        end if;


      --//-------------------------------
      --//Отправка сигнала COMWAKE
      --//-------------------------------
      when S_HR_COMWAKE =>

          i_gtp_txcomstart<='1';--//Вкл. сигнал COMWAKE
          i_gtp_txcomtype <='1';
          fsm_ploob_cs <= S_HR_COMWAKE_DONE;

      when S_HR_COMWAKE_DONE =>

        i_gtp_txcomstart<='0';

        if p_in_gtp_rxstatus(0)='1' then
        --//Жду завершиения отправки сигналов COMWAKE
          i_timer_rst_n<='1';
          fsm_ploob_cs <= S_HR_AwaitCOMWAKE;
        end if;


      --//-------------------------------
      --//Жду от устройства сигнал COMWAKE
      --//-------------------------------
      when S_HR_AwaitCOMWAKE =>

        if p_in_gtp_rxelecidle='1' and p_in_gtp_rxstatus = "010" then
            --Обнаружил сигнал COMWAKE
            i_timer_rst_n<='0';
            i_status(C_PSTAT_COMWAKE_RCV_BIT)<='1';
            fsm_ploob_cs <= S_HR_AwaitNoCOMWAKE;
        else
          if i_timeout='1' then
            i_timer_rst_n<='0';
            fsm_ploob_cs <= S_HR_COMRESET;
          end if;
        end if;


      --//-------------------------------
      --//Жду пока окончится передача OOB сигнала
      --//-------------------------------
      when S_HR_AwaitNoCOMWAKE =>

        if p_in_gtp_rxelecidle='0' and p_in_gtp_rxstatus(2 downto 0)="000" then
            i_gtp_txelecidle<='0';
            i_timer_rst_n<='0';
            --//Прерхожу к ожиданию приема от устройства ALING примитива, а сам
            --//в это время отпрапвляю D10.2 код
            i_gtp_pcm_rst<='1';
            i_status(C_PSTAT_DET_DEV_ON_BIT)<='1';
            fsm_ploob_cs <= S_HR_AwaitAlign;
        else
            if i_timeout='1' then
              fsm_ploob_cs <= S_HR_COMRESET;
              i_timer_rst_n<='0';
            else
              i_timer_rst_n<='1';
            end if;
        end if;


      --//-------------------------------
      --//Жду от устройства ALIGN примитив
      --//-------------------------------
      when S_HR_AwaitAlign =>

        i_gtp_pcm_rst<='0';

        if p_in_gtp_rxelecidle='0' then

            if p_in_primitive_det(C_TALIGN)='1' then
                --Принял ALIGN Primitive
                i_d10_2_senddis<='1';--Как только сигнал установится в '1'
                                     --начнется отправка ALIGN Primitive
                i_timer_rst_n<='0';
                fsm_ploob_cs <= S_HR_SendAlign;
            else
                if i_timeout='1' then
                  i_timer_rst_n<='0';
                  fsm_ploob_cs <= S_HR_COMRESET;
                else
                  i_timer_rst_n<='1';
                end if;
            end if;
        else
          i_timer_rst_n<='0';
          fsm_ploob_cs <= S_HR_COMRESET;
        end if;


      --//-------------------------------
      --//Отправка устройству ALIGN примитива
      --//-------------------------------
      when S_HR_SendAlign =>

        if p_in_gtp_rxelecidle='0' then

            if i_timeout='1' then
              i_timer_rst_n<='0';
              fsm_ploob_cs <= S_HR_COMRESET;

            else

              i_timer_rst_n<='1';

              if p_in_primitive_det(C_TALIGN)='1' then
                i_rx_prmt_cnt<=(others=>'0');

              elsif CONV_INTEGER(p_in_primitive_det)/=0 then

                if (i_rx_prmt_cnt=CONV_STD_LOGIC_VECTOR(3-1, i_rx_prmt_cnt'length)) then
                  --Если принял вподряд 3 НЕ AILGN примитива, то
                  --считаю что соединение установлено

                  i_status(C_PSTAT_DET_ESTABLISH_ON_BIT)<='1';
                  i_status(C_PSTAT_SPD_BIT_M downto C_PSTAT_SPD_BIT_L)<=p_in_ctrl(C_PCTRL_SPD_BIT_M downto C_PCTRL_SPD_BIT_L);

                  fsm_ploob_cs <= S_HR_Ready;
                else
                  i_rx_prmt_cnt<=i_rx_prmt_cnt+1;
                end if;
              end if;
            end if;
        else
          i_timer_rst_n<='0';
          fsm_ploob_cs <= S_HR_COMRESET;
        end if;


      --//-------------------------------
      --//Установка соединения запершена
      --//-------------------------------
      when S_HR_Ready =>

        i_timer_rst_n<='0';
        if p_in_gtp_rxelecidle = '1' then
          fsm_ploob_cs <= S_HR_COMRESET;
        end if;

    end case;

  end if;
end process lfsm;


--//Только для моделирования (удобства алализа данных при моделироании)
gen_sim_on : if strcmp(G_SIM,"ON") generate

tst_pl_ctrl.speed<=p_in_ctrl(C_PCTRL_SPD_BIT_M downto C_PCTRL_SPD_BIT_L);

tst_pl_status.dev_detect<=i_status(C_PSTAT_DET_DEV_ON_BIT);
tst_pl_status.link_establish<=i_status(C_PSTAT_DET_ESTABLISH_ON_BIT);
tst_pl_status.speed<=i_status(C_PSTAT_SPD_BIT_M downto C_PSTAT_SPD_BIT_L);
tst_pl_status.rcv_comwake<=i_status(C_PSTAT_COMWAKE_RCV_BIT);

process(tst_pl_ctrl,tst_pl_status)
begin
  if tst_pl_ctrl.speed(C_PCTRL_SPD_BIT_L)='1' or
     tst_pl_status.link_establish='1' then
    tst_val<='1';
  else
    tst_val<='0';
  end if;
end process;

p_out_dbg.stat<=tst_pl_status;
p_out_dbg.fsm<=fsm_ploob_cs;

end generate gen_sim_on;


--END MAIN
end behavioral;
