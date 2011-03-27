-------------------------------------------------------------------------
-- Company     : Linkos
-- Engineer    : Golovachenko Victor
--
-- Create Date : 13.02.2011 13:26:02
-- Module Name : sata_llayer
--
-- Назначение :
--   Link Layer:
--   1. Организация протокола обмена с устро-вом на уровне SATA примитивов,
--      согласно спецификации SATA для уровня Link Layer
--     (см. пп 9.6 Serial ATA Specification v2.5 (2005-10-27).pdf)
--   2. Прием RxFRAME от PHY уровня, Де-скремблирование RxFRAME, подсчет CRC и выдача RxDATA транспортному уровню.
--   3. Чтение TxDATA из транспортного уровня, расчет CRC, формирование TxFRAME, скремблирование TxFRAME.
--
--      Rx/TxFRAME - SOF+Rx/TxDATA+CRC+EOF
--
-- Revision:
-- Revision 13.02.2011 - File Created
--
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

entity sata_llayer is
generic
(
--G_GTP_DBUS : integer := 16;
G_DBG      : string  := "OFF";
G_SIM      : string  := "OFF"
);
port
(
--------------------------------------------------
--Связь с Transport Layer
--------------------------------------------------
p_in_ctrl               : in    std_logic_vector(C_LLCTRL_LAST_BIT downto 0);--//Константы см. sata_pkg.vhd/поле - Link Layer/Управление/Map:
p_out_status            : out   std_logic_vector(C_LLSTAT_LAST_BIT downto 0);--//Константы см. sata_pkg.vhd/поле - Link Layer/Статусы/Map:

p_in_txd_close          : in    std_logic;                    --//Закрыть передоваемый frame (0/1 -закрыть фрейм/(не закрывать -продолжать передачу данных))
p_in_txd                : in    std_logic_vector(31 downto 0);--//Данные из TX буфера транспортного уровня
p_out_txd_rd            : out   std_logic;                    --//Разрешение чтения данных TX буфера трансп. уровня
p_in_txd_status         : in    TTxBufStatus;                 --//Структуры см. sata_pkg.vhd/поле - Типы

p_out_rxd               : out   std_logic_vector(31 downto 0);--//Данные в RX буфер транспортного уровня
p_out_rxd_wr            : out   std_logic;                    --//Разрешение записи данных в RX буфер трансп. уровня
p_in_rxd_status         : in    TRxBufStatus;                 --//Структуры см. sata_pkg.vhd/поле - Типы

--------------------------------------------------
--Связь с Phy Layer
--------------------------------------------------
p_in_phy_rdy            : in    std_logic;

p_in_phy_rxtype         : in    std_logic_vector(C_TDATA_EN downto C_TSYNC);--//Константы см. sata_pkg.vhd/поле - PHY Layer/номера примитивов
p_in_phy_rxd            : in    std_logic_vector(31 downto 0);

p_out_phy_txd           : out   std_logic_vector(31 downto 0);
p_out_phy_txreq         : out   std_logic_vector(7 downto 0);
p_in_phy_txrdy_n        : in    std_logic;

p_in_phy_sync           : in    std_logic;

--------------------------------------------------
--Технологические сигналы
--------------------------------------------------
p_in_tst                : in    std_logic_vector(31 downto 0);
p_out_tst               : out   std_logic_vector(31 downto 0);

--------------------------------------------------
--System
--------------------------------------------------
p_in_clk               : in    std_logic;--
p_in_rst               : in    std_logic
);
end sata_llayer;

architecture behavioral of sata_llayer is

type fsm_state is
(
--------------------------------------------
-- Link idle states.
--------------------------------------------
S_L_RESET,
S_L_IDLE,
S_L_SyncEscape,
S_L_NoCommErr,
S_L_NoComm,
--S_L_SendAlign,

----------------------------------------------
---- Link transfer states.
----------------------------------------------
S_LT_H_SendChkRdy,
S_LT_SendSOF,
S_LT_SendData,
S_LT_SendCRC,
S_LT_SendEOF,
S_LT_Wait,
S_LT_RcvrHold,
S_LT_SendHold,

--------------------------------------------
-- Link reciever states.
--------------------------------------------
S_LR_RcvChkRdy,
S_LR_RcvWaitFifo,
S_LR_RcvData,
S_LR_Hold,
S_LR_SendHold,
S_LR_RcvEOF,
S_LR_GoodCRC,
S_LR_GoodEnd,
S_LR_BadEnd

);
signal fsm_llayer_cs: fsm_state;


signal i_status                    : std_logic_vector(C_LLSTAT_LAST_BIT downto 0);

signal i_init_work                 : std_logic;--//Подготовка скрамблера и CRC к работе

signal i_srambler_en_rx            : std_logic;
signal i_srambler_en_tx            : std_logic;
signal i_srambler_en               : std_logic;
signal i_srambler_en_dly           : std_logic;
signal i_srambler_out              : std_logic_vector(31 downto 0);

signal i_crc_en                    : std_logic;
signal i_crc_in                    : std_logic_vector(31 downto 0);
signal i_crc_out                   : std_logic_vector(31 downto 0);

signal i_rcv_en                    : std_logic;--//управление приемом данных
signal i_rcv_work                  : std_logic;
signal sr_rxdata_fst               : std_logic_vector(31 downto 0);
type TDlySrD is array (0 to 1) of std_logic_vector(31 downto 0);
signal i_rxd_out                   : std_logic_vector(31 downto 0);
signal i_rxd_en_out                : std_logic;
signal i_rxp                       : std_logic_vector(C_TX_RDY downto C_THOLD);--//флаги принятых примитивов
signal i_return                    : std_logic;

signal i_txd_en                    : std_logic;
signal i_txd_out                   : std_logic_vector(31 downto 0);

signal i_txr_ip                    : std_logic;--//Сигнализирует что был выставлен запрос на передачу примитива R_IP
signal i_txreq                     : std_logic_vector(p_out_phy_txreq'range);--//Запрос на передачу данных/примитивов

signal i_txp_cnt                   : std_logic_vector(1 downto 0);--//счетчик переданых примитивов.
                                                                  --//Необходим для определения когда отправлять примитив CONT

signal i_trn_term                  : std_logic;--//Закрываю транзакцию передачи данных по причине приема приема примитива DMAT
                                               --//Для передоваемого FRAME подставляю CRC,EOF

signal i_tmr                       : std_logic_vector(7 downto 0);--//timer

signal i_tl_check_done             : std_logic;--//Обнаружил сигнал завершения проверки Transport Layer
signal i_tl_check_ok               : std_logic;--//Результат проверки принятых данных Transport Layer

signal tst_val                     : std_logic;
signal tst_ll_rxp                  : TSimLLRxP;
signal tst_ll_ctrl                 : TSimLLCtrl;
signal tst_ll_status               : TSimLLStatus;
signal tst_fms_cs                  : std_logic_vector(4 downto 0);
signal tst_fms_cs_dly              : std_logic_vector(tst_fms_cs'range);


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

tst_fms_cs<=CONV_STD_LOGIC_VECTOR(16#01#, tst_fms_cs'length) when fsm_llayer_cs=S_L_IDLE else
            CONV_STD_LOGIC_VECTOR(16#02#, tst_fms_cs'length) when fsm_llayer_cs=S_L_SyncEscape else
            CONV_STD_LOGIC_VECTOR(16#03#, tst_fms_cs'length) when fsm_llayer_cs=S_L_NoCommErr else
            CONV_STD_LOGIC_VECTOR(16#04#, tst_fms_cs'length) when fsm_llayer_cs=S_L_NoComm else
            CONV_STD_LOGIC_VECTOR(16#05#, tst_fms_cs'length) when fsm_llayer_cs=S_LT_H_SendChkRdy else
            CONV_STD_LOGIC_VECTOR(16#06#, tst_fms_cs'length) when fsm_llayer_cs=S_LT_SendSOF else
            CONV_STD_LOGIC_VECTOR(16#07#, tst_fms_cs'length) when fsm_llayer_cs=S_LT_SendData else
            CONV_STD_LOGIC_VECTOR(16#08#, tst_fms_cs'length) when fsm_llayer_cs=S_LT_SendCRC else
            CONV_STD_LOGIC_VECTOR(16#09#, tst_fms_cs'length) when fsm_llayer_cs=S_LT_SendEOF else
            CONV_STD_LOGIC_VECTOR(16#0A#, tst_fms_cs'length) when fsm_llayer_cs=S_LT_Wait else
            CONV_STD_LOGIC_VECTOR(16#0B#, tst_fms_cs'length) when fsm_llayer_cs=S_LT_RcvrHold else
            CONV_STD_LOGIC_VECTOR(16#0C#, tst_fms_cs'length) when fsm_llayer_cs=S_LT_SendHold else
            CONV_STD_LOGIC_VECTOR(16#0D#, tst_fms_cs'length) when fsm_llayer_cs=S_LR_RcvChkRdy else
            CONV_STD_LOGIC_VECTOR(16#0E#, tst_fms_cs'length) when fsm_llayer_cs=S_LR_RcvWaitFifo else
            CONV_STD_LOGIC_VECTOR(16#0F#, tst_fms_cs'length) when fsm_llayer_cs=S_LR_RcvData else
            CONV_STD_LOGIC_VECTOR(16#10#, tst_fms_cs'length) when fsm_llayer_cs=S_LR_Hold else
            CONV_STD_LOGIC_VECTOR(16#11#, tst_fms_cs'length) when fsm_llayer_cs=S_LR_SendHold else
            CONV_STD_LOGIC_VECTOR(16#12#, tst_fms_cs'length) when fsm_llayer_cs=S_LR_RcvEOF else
            CONV_STD_LOGIC_VECTOR(16#13#, tst_fms_cs'length) when fsm_llayer_cs=S_LR_GoodCRC else
            CONV_STD_LOGIC_VECTOR(16#14#, tst_fms_cs'length) when fsm_llayer_cs=S_LR_GoodEnd else
            CONV_STD_LOGIC_VECTOR(16#15#, tst_fms_cs'length) when fsm_llayer_cs=S_LR_BadEnd else
            CONV_STD_LOGIC_VECTOR(16#00#, tst_fms_cs'length) ; --//when fsm_llayer_cs=S_L_RESET else

end generate gen_dbg_on;



--//#########################################
--//Статусы
--//#########################################
gen_report : for i in 0 to C_LLSTAT_LAST_BIT  generate
p_out_status(i)<=i_status(i);
end generate gen_report;


--//#########################################
--//Прием данных из PHY уровня
--//#########################################
lrxd_descrambler:process(p_in_rst,p_in_clk)
begin
  if p_in_rst='1' then
    sr_rxdata_fst<=(others=>'0');
  elsif p_in_clk'event and p_in_clk='1' then
    if p_in_phy_sync='1' then
      if p_in_phy_rxtype(C_TDATA_EN)='1' then
        for i in 0 to 31 loop
          sr_rxdata_fst(i)<=p_in_phy_rxd(i) xor i_srambler_out(i);--//De-scrambling
        end loop;
      end if;
    end if;
  end if;
end process lrxd_descrambler;

--//Принятые данные (без CRC)
i_rxd_en_out<=i_srambler_en_rx and i_rcv_work;
lrxd_out:process(p_in_rst,p_in_clk)
begin
  if p_in_rst='1' then
    i_rxd_out<=(others=>'0');
    p_out_rxd_wr<='0';
  elsif p_in_clk'event and p_in_clk='1' then

    i_srambler_en_dly<=i_srambler_en;
    if i_srambler_en_dly='1' then
      i_rxd_out<=sr_rxdata_fst;
    end if;

    p_out_rxd_wr<=i_rxd_en_out;

  end if;
end process lrxd_out;

p_out_rxd<=i_rxd_out;


--//Transport Layer выдает результаты проверки принимаемых данных.
--//необходимы для выдачи соответствующего примитива R_OK/R_ERR
process(p_in_rst,p_in_clk)
begin
  if p_in_rst='1' then
    i_tl_check_done<='0';
    i_tl_check_ok<='0';
  elsif p_in_clk'event and p_in_clk='1' then

    if fsm_llayer_cs=S_LR_GoodCRC then
      --//Жду результатов проверки Transport Layer
      if p_in_ctrl(C_LCTRL_TL_CHECK_DONE_BIT)='1' then
        if p_in_ctrl(C_LCTRL_TL_CHECK_ERR_BIT)='0' then
          i_tl_check_ok<='1';
        end if;
        i_tl_check_done<='1';
      end if;
    else
      i_tl_check_done<='0';
      i_tl_check_ok<='0';
    end if;

  end if;
end process;



--//#########################################
--//Передача данных в PHY уровень
--//#########################################
p_out_phy_txreq<=i_txreq;


--//Чтение данных из буфера передачи
p_out_txd_rd<=p_in_phy_sync and not p_in_phy_txrdy_n when fsm_llayer_cs=S_LT_SendData else '0';

i_txd_out<=i_crc_out when fsm_llayer_cs=S_LT_SendCRC else p_in_txd;

gen_txd : for i in 0 to 31  generate
p_out_phy_txd(i)<=i_txd_out(i) xor i_srambler_out(i);--//Scrambling
end generate gen_txd;


process(p_in_rst,p_in_clk)
begin
  if p_in_rst='1' then
    i_tmr<=(others=>'0');
  elsif p_in_clk'event and p_in_clk='1' then

    if fsm_llayer_cs/=S_LT_SendHold then
      i_tmr<=(others=>'0');
    else
      if p_in_phy_sync='1' and p_in_txd_status.empty='0' then
        --//Обнаружи что в Tx буфере появились данные.
        --//Делаем небольшую задежку перед возобновлением передачи
        --//для того чтобы в буфере накопилось побольше данных
        --//Значение задержки задается в sata_pkg.vhd - C_LL_TXDATA_RETURN_TMR
          i_tmr<=i_tmr + 1;
      end if;
    end if;

  end if;
end process;



--//----------------------------
--//Генерация масок скремблера согласно спецификации SATA
--//(см. пп 9.5.1 Serial ATA Specification v2.5 (2005-10-27).pdf)
--//----------------------------
i_srambler_en_rx<=(p_in_phy_sync and p_in_phy_rxtype(C_TDATA_EN) and i_rcv_en and not i_rxp(C_TCONT));
i_srambler_en_tx<=(p_in_phy_sync and not p_in_phy_txrdy_n and (i_txd_en or i_trn_term));
i_srambler_en<=i_srambler_en_rx or i_srambler_en_tx;

m_scrambler : sata_scrambler
generic map
(
G_INIT_VAL   => 16#F0F6#
)
port map
(
p_in_SOF     => i_init_work,
p_in_en      => i_srambler_en,
p_out_result => i_srambler_out,

-----------------
--System
-----------------
--p_in_clk_en  => p_in_clk_en,
p_in_clk     => p_in_clk,
p_in_rst     => p_in_rst
);


--//----------------------------
--//Расчет CRC согласно спецификации SATA
--//(см. пп 9.5 Serial ATA Specification v2.5 (2005-10-27).pdf)
--//----------------------------
i_crc_in<=i_txd_out when fsm_llayer_cs=S_LT_SendData or fsm_llayer_cs=S_LT_SendCRC or i_trn_term='1' else i_rxd_out;
i_crc_en<=i_srambler_en_tx or i_rxd_en_out;

m_crc : sata_crc
generic map
(
G_INIT_VAL    => 16#52325032#
)
port map
(
p_in_SOF      => i_init_work,
--  p_in_EOF  => '0',
p_in_en       => i_crc_en,
p_in_data     => i_crc_in,
p_out_crc     => i_crc_out,

-----------------
--System
-----------------
--p_in_clk_en   => p_in_clk_en,
p_in_clk      => p_in_clk,
p_in_rst      => p_in_rst
);



--//#########################################
--//Link Layer - Автомат управления
--//Реализует управление согласно спецификации SATA
--//(см. пп 9.6 Serial ATA Specification v2.5 (2005-10-27).pdf)
--//#########################################
lfsm:process(p_in_rst,p_in_clk)
begin

if p_in_rst='1' then

  fsm_llayer_cs<= S_L_RESET;

  i_status<=(others=>'0');

  i_init_work<='0';

  i_txreq<=(others=>'0');
  i_txp_cnt<=(others=>'0');
  i_txd_en<='0';

  i_txr_ip<='0';

  i_rxp<=(others=>'0');
  i_rcv_en<='0';
  i_rcv_work<='0';

  i_return<='0';

  i_trn_term<='0';

elsif p_in_clk'event and p_in_clk='1' then
--if clk_en='1' then

  case fsm_llayer_cs is

    --$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
    --$$$$$$$$$$$$ Link IDLE states $$$$$$$$$$$$
    --$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
    --------------------------------------------
    -- Link idle. STATE: S_L_RESET
    --------------------------------------------
    when S_L_RESET =>
      i_status<=(others=>'0');

      i_init_work<='0';

      i_txreq<=CONV_STD_LOGIC_VECTOR(C_TALIGN, 8);
      i_txp_cnt<=(others=>'0');
      i_txd_en<='0';

      i_rcv_en<='0';
      i_rcv_work<='0';
      i_rxp<=(others=>'0');

      fsm_llayer_cs <= S_L_NoComm;

    --------------------------------------------
    -- Link idle. STATE: S_L_IDLE /(x00 код на порту p_out_tst_fms_cs)
    --------------------------------------------
    when S_L_IDLE =>

      i_status(C_LSTAT_RxDONE)<='0';

      i_status(C_LSTAT_RxOK)<='0';
      i_status(C_LSTAT_RxERR_CRC)<='0';
      i_status(C_LSTAT_RxERR_IDLE)<='0';
      i_status(C_LSTAT_RxERR_ABORT)<='0';

      i_status(C_LSTAT_TxOK)<='0';
      i_status(C_LSTAT_TxERR_CRC)<='0';
      i_status(C_LSTAT_TxERR_IDLE)<='0';
      i_status(C_LSTAT_TxERR_ABORT)<='0';

      if p_in_phy_rdy='0' then
      --//Связь с утройством оборвана
        fsm_llayer_cs <= S_L_NoCommErr;

      else
          if p_in_phy_sync='1' then
            i_rcv_work<='0';
            i_txr_ip<='0';

            if p_in_phy_rxtype(C_TX_RDY)='1' then
            --Уст-во готово к передаче данных
                if p_in_phy_txrdy_n='0' then
                  if i_txp_cnt/=CONV_STD_LOGIC_VECTOR(3, i_txp_cnt'length) then
                    if i_txp_cnt=CONV_STD_LOGIC_VECTOR(2, i_txp_cnt'length) then
                      i_txreq<=CONV_STD_LOGIC_VECTOR(C_TCONT, i_txreq'length);
                      i_txp_cnt<=i_txp_cnt + 1;
                    else
                      i_txreq<=CONV_STD_LOGIC_VECTOR(C_TSYNC, i_txreq'length);
                      i_txp_cnt<=i_txp_cnt+1;
                    end if;
                  else
                    i_txreq<=CONV_STD_LOGIC_VECTOR(C_TNONE, i_txreq'length);
                  end if;
                end if;

                i_rxp(C_TX_RDY)<='1';
                fsm_llayer_cs <= S_LR_RcvWaitFifo;

            elsif p_in_ctrl(C_LCTRL_TxSTART_BIT)='1' then
            --Запрос на передачу данных
                if p_in_phy_txrdy_n='0' then
                  if i_txp_cnt/=CONV_STD_LOGIC_VECTOR(3, i_txp_cnt'length) then
                    i_txreq<=CONV_STD_LOGIC_VECTOR(C_TSYNC, i_txreq'length);
                  else
                    i_txreq<=CONV_STD_LOGIC_VECTOR(C_TNONE, i_txreq'length);
                  end if;
                end if;

                i_txp_cnt<=(others=>'0');
                fsm_llayer_cs <= S_LT_H_SendChkRdy;

            else
                if p_in_phy_txrdy_n='0' then
                  if i_txp_cnt/=CONV_STD_LOGIC_VECTOR(3, i_txp_cnt'length) then
                    if i_txp_cnt=CONV_STD_LOGIC_VECTOR(2, i_txp_cnt'length) then
                      i_txreq<=CONV_STD_LOGIC_VECTOR(C_TCONT, i_txreq'length);
                      i_txp_cnt<=i_txp_cnt + 1;
                    else
                      i_txreq<=CONV_STD_LOGIC_VECTOR(C_TSYNC, i_txreq'length);
                      i_txp_cnt<=i_txp_cnt+1;
                    end if;
                  else
                    i_txreq<=CONV_STD_LOGIC_VECTOR(C_TNONE, i_txreq'length);
                  end if;
                end if;

            end if;

          end if;--//if p_in_phy_sync='1' then
      end if;--//if p_in_phy_rdy='0' then
      --//when S_L_IDLE =>


    --------------------------------------------
    -- Link idle. STATE: S_L_SyncEscape
    --------------------------------------------
    when S_L_SyncEscape =>

      if p_in_phy_rdy='0' then
      --//Связь с утройством оборвана
        fsm_llayer_cs <= S_L_NoCommErr;

      else
        if p_in_phy_sync='1' then

          i_init_work<='0';

          i_txd_en<='0';
          i_txr_ip<='0';

          i_rcv_en<='0';
          i_rcv_work<='0';

          if p_in_phy_rxtype(C_TX_RDY)='1' or p_in_phy_rxtype(C_TSYNC)='1' then
              i_rxp<=(others=>'0');

              if p_in_phy_txrdy_n='0' then
                if i_txp_cnt/=CONV_STD_LOGIC_VECTOR(3, i_txp_cnt'length) then
                  if i_txp_cnt=CONV_STD_LOGIC_VECTOR(2, i_txp_cnt'length) then
                    i_txreq<=CONV_STD_LOGIC_VECTOR(C_TCONT, i_txreq'length);
                    i_txp_cnt<=i_txp_cnt + 1;
                  else
                    i_txreq<=CONV_STD_LOGIC_VECTOR(C_TSYNC, i_txreq'length);
                    i_txp_cnt<=i_txp_cnt+1;
                  end if;
                else
                  i_txreq<=CONV_STD_LOGIC_VECTOR(C_TNONE, i_txreq'length);
                end if;
              end if;

              fsm_llayer_cs <= S_L_IDLE;
          else

              if p_in_phy_txrdy_n='0' then
                if i_txp_cnt/=CONV_STD_LOGIC_VECTOR(3, i_txp_cnt'length) then
                  if i_txp_cnt=CONV_STD_LOGIC_VECTOR(2, i_txp_cnt'length) then
                    i_txreq<=CONV_STD_LOGIC_VECTOR(C_TCONT, i_txreq'length);
                    i_txp_cnt<=i_txp_cnt + 1;
                  else
                    i_txreq<=CONV_STD_LOGIC_VECTOR(C_TSYNC, i_txreq'length);
                    i_txp_cnt<=i_txp_cnt+1;
                  end if;
                else
                  i_txreq<=CONV_STD_LOGIC_VECTOR(C_TNONE, i_txreq'length);
                end if;
              end if;

          end if;

        end if;--//if p_in_phy_sync='1' then
      end if;--//if p_in_phy_rdy='0' then
      --//when S_L_SyncEscape =>

    --------------------------------------------
    -- Link idle. STATE: S_L_NoCommErr
    --------------------------------------------
    when S_L_NoCommErr =>

      i_status<=(others=>'0');

      i_init_work<='0';

      i_txreq<=CONV_STD_LOGIC_VECTOR(C_TALIGN, 8);
      i_txp_cnt<=(others=>'0');
      i_txd_en<='0';

      i_rxp<=(others=>'0');
      i_rcv_en<='0';
      i_rcv_work<='0';

      fsm_llayer_cs <= S_L_NoComm;

    --------------------------------------------
    -- Link idle. STATE: S_L_NoComm
    --------------------------------------------
    when S_L_NoComm =>

      if p_in_phy_rdy='1' then
      --Связь с утройством установлена
        if p_in_phy_sync='1' then
          fsm_llayer_cs <= S_L_IDLE;
        end if;
      end if;

--      --------------------------------------------
--      -- Link idle. STATE: S_L_SendAlign
--      --------------------------------------------
--      when S_L_SendAlign =>
--
--        --1. Связь с утройством не установлена или оборвана
--        if p_in_phy_rdy='0' then
--          i_txreq<=CONV_STD_LOGIC_VECTOR(C_TALIGN, 8);
--
--          fsm_llayer_cs <= S_L_NoCommErr;
--
--        --Связь установлена
--        else
--          fsm_llayer_cs <= S_L_IDLE;
--        end if;




    --$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
    --$$$$$$$$ Link transfer states $$$$$$$$$$$$
    --$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
    --------------------------------------------
    -- Link transfer. STATE: S_LT_H_SendChkRdy
    --------------------------------------------
    when S_LT_H_SendChkRdy =>

      if p_in_phy_rdy='0' then
      --//Связь с утройством оборвана
        fsm_llayer_cs <= S_L_NoCommErr;

      else
        if p_in_phy_sync='1' then

          if p_in_phy_rxtype(C_TX_RDY)='1' then
          --//Уст-во готово к передаче данных
              if p_in_phy_txrdy_n='0' then
                if i_txp_cnt/=CONV_STD_LOGIC_VECTOR(3, i_txp_cnt'length) then
                  if i_txp_cnt=CONV_STD_LOGIC_VECTOR(2, i_txp_cnt'length) then
                    i_txreq<=CONV_STD_LOGIC_VECTOR(C_TCONT, i_txreq'length);
                    i_txp_cnt<=i_txp_cnt + 1;
                  else
                    i_txreq<=CONV_STD_LOGIC_VECTOR(C_TX_RDY, i_txreq'length);
                    i_txp_cnt<=i_txp_cnt+1;
                  end if;
                else
                  i_txreq<=CONV_STD_LOGIC_VECTOR(C_TNONE, i_txreq'length);
                end if;
              end if;

              i_rxp(C_TX_RDY)<='1';
              fsm_llayer_cs <= S_LR_RcvWaitFifo;

          elsif p_in_phy_rxtype(C_TR_RDY)='1' then
          --//Уст-во готово к приему данных
              if p_in_phy_txrdy_n='0' then
                if i_txp_cnt/=CONV_STD_LOGIC_VECTOR(3, i_txp_cnt'length) then
                  i_txreq<=CONV_STD_LOGIC_VECTOR(C_TX_RDY, i_txreq'length);
                else
                  i_txreq<=CONV_STD_LOGIC_VECTOR(C_TNONE, i_txreq'length);
                end if;
              end if;

              i_txp_cnt<=(others=>'0');
              i_init_work<='1';--//Инициализация модулей CRC,Scrambler
              fsm_llayer_cs <= S_LT_SendSOF;

          else

              if p_in_phy_txrdy_n='0' then
                if i_txp_cnt/=CONV_STD_LOGIC_VECTOR(3, i_txp_cnt'length) then
                  if i_txp_cnt=CONV_STD_LOGIC_VECTOR(2, i_txp_cnt'length) then
                    i_txreq<=CONV_STD_LOGIC_VECTOR(C_TCONT, i_txreq'length);
                    i_txp_cnt<=i_txp_cnt + 1;
                  else
                    i_txreq<=CONV_STD_LOGIC_VECTOR(C_TX_RDY, i_txreq'length);
                    i_txp_cnt<=i_txp_cnt+1;
                  end if;
                else
                  i_txreq<=CONV_STD_LOGIC_VECTOR(C_TNONE, i_txreq'length);
                end if;
              end if;

          end if;

        end if;--//if p_in_phy_sync='1' then
      end if;--//if p_in_phy_rdy='0' then
      --//when S_LT_H_SendChkRdy =>


    --------------------------------------------
    -- Link transfer. STATE: S_LT_SendSOF
    --------------------------------------------
    when S_LT_SendSOF =>

      if p_in_phy_rdy='0' then
      --//Связь с утройством оборвана
        fsm_llayer_cs <= S_L_NoCommErr;

      else
        if p_in_phy_sync='1' then

          i_init_work<='0';--//Инициализация модулей CRC,Scrambler

          if p_in_phy_rxtype(C_TSYNC)='1' then
          --//Уст-во переывает текущую транзакию
              if p_in_phy_txrdy_n='0' then
                i_txreq<=CONV_STD_LOGIC_VECTOR(C_TSOF, i_txreq'length);
              end if;

              i_status(C_LSTAT_TxERR_ABORT)<='1';--//Информ. Транспорный уровень
              fsm_llayer_cs <= S_L_IDLE;

          else
              if p_in_phy_txrdy_n='0' then
                i_txreq<=CONV_STD_LOGIC_VECTOR(C_TSOF, i_txreq'length);
                fsm_llayer_cs <= S_LT_SendData;
              end if;

          end if;

        end if;--//if p_in_phy_sync='1' then
      end if;--//if p_in_phy_rdy='0' then
      --//when S_LT_SendSOF =>


    --------------------------------------------
    -- Link transfer. STATE: S_LT_SendData
    --------------------------------------------
    when S_LT_SendData =>

      if p_in_phy_rdy='0' then
      --//Связь с утройством оборвана
          fsm_llayer_cs <= S_L_NoCommErr;

      else
        if p_in_phy_sync='1' then

          if p_in_ctrl(C_LCTRL_TRN_ESCAPE_BIT)='1' then
          --//Транспортный уровень хочет прервать текущую операцию
              i_txreq<=CONV_STD_LOGIC_VECTOR(C_TDATA_EN, i_txreq'length);
              i_txp_cnt<=(others=>'0');
              fsm_llayer_cs <= S_L_SyncEscape;

          elsif p_in_phy_rxtype(C_TSYNC)='1' then
          --//Уст-во переывает текущую транзакию
              i_txreq<=CONV_STD_LOGIC_VECTOR(C_TDATA_EN, i_txreq'length);
              i_txp_cnt<=(others=>'0');
              i_status(C_LSTAT_TxERR_ABORT)<='1';--//Информ. Транспорный уровень
              i_txd_en<='0';
              fsm_llayer_cs <= S_L_IDLE;

          elsif p_in_phy_rxtype(C_TDMAT)='1' then
          --//Уст-во просит завершить текущую транзакию
              if p_in_phy_txrdy_n='0' then
                i_txreq<=CONV_STD_LOGIC_VECTOR(C_TDATA_EN, i_txreq'length);
                i_txp_cnt<=(others=>'0');
                i_rxp(C_TDMAT)<='1';
                fsm_llayer_cs <= S_LT_SendCRC;
              end if;

          elsif p_in_phy_rxtype(C_THOLD)='1' and p_in_txd_close ='0' then
          --//Устройство присит приостановить передачу данных
          --//Передача данных НЕ ЗАКОНЧЕНА!!!
              i_txd_en<='0';
              if p_in_phy_rxtype(C_THOLD)='1' then
                i_rxp(C_TCONT)<='0';
                i_rxp(C_THOLD)<='1';
              end if;
              fsm_llayer_cs <= S_LT_RcvrHold;

          else

              if CONV_INTEGER(p_in_phy_rxtype(C_TPMNAK downto C_TSOF))/= 0 then
              --//Принял некий примимив, но не SYNC, DMAT, HOLD
                if p_in_phy_rxtype(C_TCONT)='1' then
                  i_rxp(C_TCONT)<='1';
                else
                  i_rxp<=(others=>'0');
                end if;
              end if;

              i_txreq<=CONV_STD_LOGIC_VECTOR(C_TDATA_EN, i_txreq'length);
              i_txp_cnt<=(others=>'0');

              if p_in_txd_close='1' then
              --Передача данных ЗАКОНЧЕНА!!!
                  if p_in_phy_txrdy_n='0' then
                    fsm_llayer_cs <= S_LT_SendCRC;
                  end if;

              elsif p_in_txd_status.aempty='1' then
              --Передача данных НЕ ЗАКОНЧЕНА!!!, буфер Tx почти пуст
              --перходим к сигнализации устройству о приостановке передачи до появления данных
                  i_txd_en<='0';
                  fsm_llayer_cs <= S_LT_SendHold;

              else

                  if p_in_phy_txrdy_n='0' then
                    i_txd_en<='1';
                  end if;

              end if;

          end if;

        end if;--//if p_in_phy_sync='1' then
      end if; --//if p_in_phy_rdy='0' then
      --//when S_LT_SendData =>

    --------------------------------------------
    -- Link transfer. STATE: S_LT_SendHold
    --------------------------------------------
    when S_LT_SendHold =>

      if p_in_phy_rdy='0' then
      --//Связь с утройством оборвана
          fsm_llayer_cs <= S_L_NoCommErr;

      else
        if p_in_phy_sync='1' then

          if p_in_ctrl(C_LCTRL_TRN_ESCAPE_BIT)='1' then
          --//Транспортный уровень хочет прервать текущую операцию
              if p_in_phy_txrdy_n='0' then
                if i_txp_cnt/=CONV_STD_LOGIC_VECTOR(3, i_txp_cnt'length) then
                  i_txreq<=CONV_STD_LOGIC_VECTOR(C_THOLD, i_txreq'length);
                else
                  i_txreq<=CONV_STD_LOGIC_VECTOR(C_TNONE, i_txreq'length);
                end if;
              end if;

              i_txp_cnt<=(others=>'0');
              fsm_llayer_cs <= S_L_SyncEscape;

          elsif p_in_phy_rxtype(C_TSYNC)='1' then
          --//Уст-во переывает текущую транзакию
              if p_in_phy_txrdy_n='0' then
                if i_txp_cnt/=CONV_STD_LOGIC_VECTOR(3, i_txp_cnt'length) then
                  i_txreq<=CONV_STD_LOGIC_VECTOR(C_THOLD, i_txreq'length);
                else
                  i_txreq<=CONV_STD_LOGIC_VECTOR(C_TNONE, i_txreq'length);
                end if;
              end if;

              i_rxp<=(others=>'0');
              i_txp_cnt<=(others=>'0');
              i_status(C_LSTAT_TxERR_ABORT)<='1';--//Информ. Транспорный уровень
              fsm_llayer_cs <= S_L_IDLE;

          elsif p_in_phy_rxtype(C_TDMAT)='1' then
          --//Уст-во просит завершить текущую транзакию
              if p_in_phy_txrdy_n='0' then
                  if i_trn_term='1' then
                    i_trn_term<='0';
                    i_txreq<=CONV_STD_LOGIC_VECTOR(C_TDATA_EN, i_txreq'length);
                    fsm_llayer_cs <= S_LT_SendCRC;

                  else
                    i_trn_term<='1';
                    i_txreq<=CONV_STD_LOGIC_VECTOR(C_THOLD, i_txreq'length);
                    i_txp_cnt<=(others=>'0');

                  end if;

              else
                  if i_txp_cnt/=CONV_STD_LOGIC_VECTOR(3, i_txp_cnt'length) then
                    i_txreq<=CONV_STD_LOGIC_VECTOR(C_THOLD, i_txreq'length);
                  else
                    i_txreq<=CONV_STD_LOGIC_VECTOR(C_TNONE, i_txreq'length);
                  end if;

              end if;

              i_rxp(C_TDMAT)<='1';
              i_rxp(C_THOLD)<='0';
              i_rxp(C_TCONT)<='0';

          elsif p_in_phy_rxtype(C_TCONT)='1' then
          --//ВАЖНО!!! - все последующие данные будут аналогичны приему предыдущего примитива
              if p_in_phy_txrdy_n='0' then
                if i_txp_cnt/=CONV_STD_LOGIC_VECTOR(3, i_txp_cnt'length) then
                  if i_txp_cnt=CONV_STD_LOGIC_VECTOR(2, i_txp_cnt'length) then
                    i_txreq<=CONV_STD_LOGIC_VECTOR(C_TCONT, i_txreq'length);
                    i_txp_cnt<=i_txp_cnt + 1;
                  else
                    i_txreq<=CONV_STD_LOGIC_VECTOR(C_THOLD, i_txreq'length);
                    i_txp_cnt<=i_txp_cnt+1;
                  end if;
                else
                  i_txreq<=CONV_STD_LOGIC_VECTOR(C_TNONE, i_txreq'length);
                end if;
              end if;

              i_rxp(C_TCONT)<='1';

          elsif CONV_INTEGER(p_in_phy_rxtype(C_TPMNAK downto C_TSOF))/= 0 and p_in_phy_rxtype(C_THOLD)='0' then
          --//Принял некий примимив, но не SYNC, DMAT, CONT, HOLD
              if i_tmr>=CONV_STD_LOGIC_VECTOR(C_LL_TXDATA_RETURN_TMR, i_tmr'length) or p_in_txd_close='1' then
                  --//Переход к передаче данных
                  if p_in_phy_txrdy_n='0' then

                    i_txreq<=CONV_STD_LOGIC_VECTOR(C_THOLD, i_txreq'length);
                    i_txp_cnt<=(others=>'0');
                    i_txd_en<='1';
                    fsm_llayer_cs <= S_LT_SendData;
                  end if;

              else
                  --Ждем пока в TXBUF буфере накопятся данные
                  if p_in_phy_txrdy_n='0' then
                    if i_txp_cnt/=CONV_STD_LOGIC_VECTOR(3, i_txp_cnt'length) then
                      if i_txp_cnt=CONV_STD_LOGIC_VECTOR(2, i_txp_cnt'length) then
                        i_txreq<=CONV_STD_LOGIC_VECTOR(C_TCONT, i_txreq'length);
                        i_txp_cnt<=i_txp_cnt + 1;
                      else
                        i_txreq<=CONV_STD_LOGIC_VECTOR(C_THOLD, i_txreq'length);
                        i_txp_cnt<=i_txp_cnt+1;
                      end if;
                    else
                      i_txreq<=CONV_STD_LOGIC_VECTOR(C_TNONE, i_txreq'length);
                    end if;
                  end if;

              end if;

              i_rxp<=(others=>'0');

          elsif p_in_phy_rxtype(C_THOLD)='1' or (i_rxp(C_THOLD)='1' and i_rxp(C_TCONT)='1') then
          --//Принял примитив HOLD - Уст-во сигнализирует отложить передачу данных
              if i_tmr>=CONV_STD_LOGIC_VECTOR(C_LL_TXDATA_RETURN_TMR, i_tmr'length) or p_in_txd_close='1' then
                  if p_in_txd_close='1' then
                  --//Передача данных закончена
                      if p_in_phy_txrdy_n='0' then

                        i_txreq<=CONV_STD_LOGIC_VECTOR(C_THOLD, i_txreq'length);
                        i_txp_cnt<=(others=>'0');
                        i_txd_en<='1';
                        fsm_llayer_cs <= S_LT_SendData;
                      end if;

                  else
                      if p_in_phy_txrdy_n='0' then
                        if i_txp_cnt/=CONV_STD_LOGIC_VECTOR(3, i_txp_cnt'length) then
                          if i_txp_cnt=CONV_STD_LOGIC_VECTOR(2, i_txp_cnt'length) then
                            i_txreq<=CONV_STD_LOGIC_VECTOR(C_THOLD, i_txreq'length);
                          end if;
                        else
                          i_txreq<=CONV_STD_LOGIC_VECTOR(C_TNONE, i_txreq'length);
                        end if;
                      end if;

                      i_txp_cnt<=(others=>'0');
                      fsm_llayer_cs <= S_LT_RcvrHold;
                  end if;

              else

                  --Ждем пока в TXBUF буфере накопятся данные
                  if p_in_phy_txrdy_n='0' then
                    if i_txp_cnt/=CONV_STD_LOGIC_VECTOR(3, i_txp_cnt'length) then
                      if i_txp_cnt=CONV_STD_LOGIC_VECTOR(2, i_txp_cnt'length) then
                        i_txreq<=CONV_STD_LOGIC_VECTOR(C_TCONT, i_txreq'length);
                        i_txp_cnt<=i_txp_cnt + 1;
                      else
                        i_txreq<=CONV_STD_LOGIC_VECTOR(C_THOLD, i_txreq'length);
                        i_txp_cnt<=i_txp_cnt+1;
                      end if;
                    else
                      i_txreq<=CONV_STD_LOGIC_VECTOR(C_TNONE, i_txreq'length);
                    end if;
                  end if;

              end if;

              if p_in_phy_rxtype(C_THOLD)='1' then
                i_rxp(C_TCONT)<='0';
                i_rxp(C_THOLD)<='1';
              end if;

          else

              if i_tmr>=CONV_STD_LOGIC_VECTOR(C_LL_TXDATA_RETURN_TMR, i_tmr'length) or p_in_txd_close='1' then
                  --//Переход к передаче данных
                  if p_in_phy_txrdy_n='0' then

                    i_txreq<=CONV_STD_LOGIC_VECTOR(C_THOLD, i_txreq'length);
                    i_txp_cnt<=(others=>'0');
                    i_txd_en<='1';
                    fsm_llayer_cs <= S_LT_SendData;
                  end if;

              else
                  --Ждем пока в TXBUF буфере накопятся данные
                  if p_in_phy_txrdy_n='0' then
                    if i_txp_cnt/=CONV_STD_LOGIC_VECTOR(3, i_txp_cnt'length) then
                      if i_txp_cnt=CONV_STD_LOGIC_VECTOR(2, i_txp_cnt'length) then
                        i_txreq<=CONV_STD_LOGIC_VECTOR(C_TCONT, i_txreq'length);
                        i_txp_cnt<=i_txp_cnt + 1;
                      else
                        i_txreq<=CONV_STD_LOGIC_VECTOR(C_THOLD, i_txreq'length);
                        i_txp_cnt<=i_txp_cnt+1;
                      end if;
                    else
                      i_txreq<=CONV_STD_LOGIC_VECTOR(C_TNONE, i_txreq'length);
                    end if;
                  end if;

              end if;

          end if;

        end if;--//if p_in_phy_sync='1' then
      end if;--//if p_in_phy_rdy='0' then
      --//when S_LT_SendHold =>


    --------------------------------------------
    -- Link transfer. STATE: S_LT_RcvrHold
    --------------------------------------------
    when S_LT_RcvrHold =>

      if p_in_phy_rdy='0' then
      --//Связь с утройством оборвана
          fsm_llayer_cs <= S_L_NoCommErr;

      else
        if p_in_phy_sync='1' then

          if p_in_ctrl(C_LCTRL_TRN_ESCAPE_BIT)='1' then
          --//Транспортный уровень хочет прервать текущую операцию
              if p_in_phy_txrdy_n='0' then
                if i_txp_cnt/=CONV_STD_LOGIC_VECTOR(3, i_txp_cnt'length) then
                  i_txreq<=CONV_STD_LOGIC_VECTOR(C_THOLDA, i_txreq'length);
                else
                  i_txreq<=CONV_STD_LOGIC_VECTOR(C_TNONE, i_txreq'length);
                end if;
              end if;

              i_txp_cnt<=(others=>'0');
              fsm_llayer_cs <= S_L_SyncEscape;

          elsif p_in_phy_rxtype(C_TSYNC)='1' then
          --//Уст-во переывает текущую транзакию
              if p_in_phy_txrdy_n='0' then
                if i_txp_cnt/=CONV_STD_LOGIC_VECTOR(3, i_txp_cnt'length) then
                  i_txreq<=CONV_STD_LOGIC_VECTOR(C_THOLDA, i_txreq'length);
                else
                  i_txreq<=CONV_STD_LOGIC_VECTOR(C_TNONE, i_txreq'length);
                end if;
              end if;

              i_rxp<=(others=>'0');
              i_txp_cnt<=(others=>'0');
              i_status(C_LSTAT_TxERR_ABORT)<='1';--//Информ. Транспорный уровень
              fsm_llayer_cs <= S_L_IDLE;

          elsif p_in_phy_rxtype(C_TDMAT)='1' then
          --//Уст-во просит завершить текущую транзакию
              if p_in_phy_txrdy_n='0' then
                  if i_trn_term='1' then
                    i_trn_term<='0';
                    i_txreq<=CONV_STD_LOGIC_VECTOR(C_TDATA_EN, i_txreq'length);
                    fsm_llayer_cs <= S_LT_SendCRC;

                  else
                    i_trn_term<='1';
                    i_txreq<=CONV_STD_LOGIC_VECTOR(C_THOLDA, i_txreq'length);
                    i_txp_cnt<=(others=>'0');

                  end if;

              else
                  if i_txp_cnt/=CONV_STD_LOGIC_VECTOR(3, i_txp_cnt'length) then
                    i_txreq<=CONV_STD_LOGIC_VECTOR(C_THOLDA, i_txreq'length);
                  else
                    i_txreq<=CONV_STD_LOGIC_VECTOR(C_TNONE, i_txreq'length);
                  end if;

              end if;

              i_rxp(C_TDMAT)<='1';
              i_rxp(C_THOLD)<='0';
              i_rxp(C_TCONT)<='0';

          elsif i_return='1' then
          --//Возвращаюсь к передаче данных
            if p_in_phy_txrdy_n='0' then
              i_txreq<=CONV_STD_LOGIC_VECTOR(C_THOLDA, i_txreq'length);
              i_txp_cnt<=(others=>'0');
              i_txd_en<='1';
              i_return<='0';
              fsm_llayer_cs <= S_LT_SendData;
            end if;

          elsif p_in_phy_rxtype(C_TCONT)='1' then
          --//ВАЖНО!!! - все последующие данные будут аналогичны приему предыдущего примитива
              if p_in_phy_txrdy_n='0' then
                if i_txp_cnt/=CONV_STD_LOGIC_VECTOR(3, i_txp_cnt'length) then
                  if i_txp_cnt=CONV_STD_LOGIC_VECTOR(2, i_txp_cnt'length) then
                    i_txreq<=CONV_STD_LOGIC_VECTOR(C_TCONT, i_txreq'length);
                    i_txp_cnt<=i_txp_cnt + 1;
                  else
                    i_txreq<=CONV_STD_LOGIC_VECTOR(C_THOLDA, i_txreq'length);
                    i_txp_cnt<=i_txp_cnt+1;
                  end if;
                else
                  i_txreq<=CONV_STD_LOGIC_VECTOR(C_TNONE, i_txreq'length);
                end if;
              end if;

              i_rxp(C_TCONT)<='1';

          elsif CONV_INTEGER(p_in_phy_rxtype(C_TPMNAK downto C_TSOF))/=0 and p_in_phy_rxtype(C_THOLD)='0' then
          --//Принял некий примимив, но не SYNC, DMAT, CONT, HOLD
              if p_in_phy_txrdy_n='0' then
                i_txreq<=CONV_STD_LOGIC_VECTOR(C_THOLDA, i_txreq'length);
                i_txp_cnt<=(others=>'0');
                i_txd_en<='1';
                i_return<='0';
                fsm_llayer_cs <= S_LT_SendData;
              else
                i_return<='1';
              end if;

              i_rxp<=(others=>'0');

          elsif p_in_phy_rxtype(C_THOLD)='1' or (i_rxp(C_THOLD)='1' and i_rxp(C_TCONT)='1') then
          --//Принял примитив HOLD - Уст-во сигнализирует отложить передачу данных
              if p_in_txd_close='1' then
              --//Передача данных закончена
                  if p_in_phy_txrdy_n='0' then
                    i_txreq<=CONV_STD_LOGIC_VECTOR(C_THOLDA, i_txreq'length);
                    i_txp_cnt<=(others=>'0');
                    i_txd_en<='1';
                    fsm_llayer_cs <= S_LT_SendData;
                  end if;

              else
                  if p_in_phy_txrdy_n='0' then
                    if i_txp_cnt/=CONV_STD_LOGIC_VECTOR(3, i_txp_cnt'length) then
                      if i_txp_cnt=CONV_STD_LOGIC_VECTOR(2, i_txp_cnt'length) then
                        i_txreq<=CONV_STD_LOGIC_VECTOR(C_TCONT, i_txreq'length);
                        i_txp_cnt<=i_txp_cnt + 1;
                      else
                        i_txreq<=CONV_STD_LOGIC_VECTOR(C_THOLDA, i_txreq'length);
                        i_txp_cnt<=i_txp_cnt+1;
                      end if;
                    else
                      i_txreq<=CONV_STD_LOGIC_VECTOR(C_TNONE, i_txreq'length);
                    end if;
                  end if;
              end if;

              if p_in_phy_rxtype(C_THOLD)='1' then
                i_rxp(C_TCONT)<='0';
                i_rxp(C_THOLD)<='1';
              end if;

          else

              if p_in_phy_txrdy_n='0' then
                if i_txp_cnt/=CONV_STD_LOGIC_VECTOR(3, i_txp_cnt'length) then
                  if i_txp_cnt=CONV_STD_LOGIC_VECTOR(2, i_txp_cnt'length) then
                    i_txreq<=CONV_STD_LOGIC_VECTOR(C_TCONT, i_txreq'length);
                    i_txp_cnt<=i_txp_cnt + 1;
                  else
                    i_txreq<=CONV_STD_LOGIC_VECTOR(C_THOLDA, i_txreq'length);
                    i_txp_cnt<=i_txp_cnt+1;
                  end if;
                else
                  i_txreq<=CONV_STD_LOGIC_VECTOR(C_TNONE, i_txreq'length);
                end if;
              end if;

          end if;

        end if;--//if p_in_phy_sync='1' then
      end if;--if p_in_phy_rdy='0' then
      --//when S_LT_RcvrHold =>


    --------------------------------------------
    -- Link transfer. STATE: S_LT_SendCRC
    --------------------------------------------
    when S_LT_SendCRC =>

      if p_in_phy_rdy='0' then
      --//Связь с утройством оборвана
          fsm_llayer_cs <= S_L_NoCommErr;

      else
        if p_in_phy_sync='1' then

          if p_in_phy_rxtype(C_TSYNC)='1' then
          --//Уст-во переывает текущую транзакию
            i_rxp<=(others=>'0');
            i_txd_en<='0';
            i_txreq<=CONV_STD_LOGIC_VECTOR(C_TEOF, i_txreq'length);
            i_txp_cnt<=(others=>'0');
            i_status(C_LSTAT_TxERR_ABORT)<='1';--//Информ. Транспорный уровень
            fsm_llayer_cs <= S_L_IDLE;

          else

            if p_in_phy_txrdy_n='0' then
              if i_rxp(C_TDMAT)='1' then
                i_status(C_LSTAT_TxDMAT)<='1';--//Информ. Транспорный уровень
              end if;
              i_rxp<=(others=>'0');
              i_txd_en<='0';
              i_txreq<=CONV_STD_LOGIC_VECTOR(C_TEOF, i_txreq'length);
              i_txp_cnt<=(others=>'0');

              fsm_llayer_cs <= S_LT_SendEOF;
            end if;

          end if;

        end if;--//if p_in_phy_sync='1' then
      end if;--//if p_in_phy_rdy='0' then
      --//when S_LT_SendCRC =>

    --------------------------------------------
    -- Link transfer. STATE: S_LT_SendEOF
    --------------------------------------------
    when S_LT_SendEOF =>

      if p_in_phy_rdy='0' then
      --//Связь с утройством оборвана
          fsm_llayer_cs <= S_L_NoCommErr;

      else
        if p_in_phy_sync='1' then

          i_status(C_LSTAT_TxDMAT)<='0';

          if p_in_phy_rxtype(C_TSYNC)='1' then
          --//Уст-во переывает текущую транзакию
              i_txreq<=CONV_STD_LOGIC_VECTOR(C_TWTRM, i_txreq'length);
              i_status(C_LSTAT_TxERR_ABORT)<='1';--//Информ. Транспорный уровень
              fsm_llayer_cs <= S_L_IDLE;

          else

            if p_in_phy_txrdy_n='0' then
              i_txp_cnt<=i_txp_cnt+1;
            end if;

            i_txreq<=CONV_STD_LOGIC_VECTOR(C_TWTRM, i_txreq'length);
            fsm_llayer_cs <= S_LT_Wait;

          end if;

        end if;--//if p_in_phy_sync='1' then
      end if;--//if p_in_phy_rdy='0' then
      --//when S_LT_SendEOF =>

    --------------------------------------------
    -- Link transfer. STATE: S_LT_Wait
    --------------------------------------------
    when S_LT_Wait =>

      if p_in_phy_rdy='0' then
      --//Связь с утройством оборвана
          fsm_llayer_cs <= S_L_NoCommErr;

      else
        if p_in_phy_sync='1' then

          if p_in_phy_rxtype(C_TSYNC)='1' then
          --//Уст-во переывает текущую транзакию
              if p_in_phy_txrdy_n='0' then
                if i_txp_cnt/=CONV_STD_LOGIC_VECTOR(3, i_txp_cnt'length) then
                  i_txreq<=CONV_STD_LOGIC_VECTOR(C_TWTRM, i_txreq'length);
                else
                  i_txreq<=CONV_STD_LOGIC_VECTOR(C_TNONE, i_txreq'length);
                end if;
              end if;

              i_txp_cnt<=(others=>'0');
              i_status(C_LSTAT_TxERR_ABORT)<='1';--//Информ. Транспорный уровень
              fsm_llayer_cs <= S_L_IDLE;

          elsif p_in_phy_rxtype(C_TR_OK)='1' then
          --//Проверка устройством CRC - ОК!!!
              if p_in_phy_txrdy_n='0' then
                if i_txp_cnt/=CONV_STD_LOGIC_VECTOR(3, i_txp_cnt'length) then
                  i_txreq<=CONV_STD_LOGIC_VECTOR(C_TWTRM, i_txreq'length);
                else
                  i_txreq<=CONV_STD_LOGIC_VECTOR(C_TNONE, i_txreq'length);
                end if;
              end if;

              i_txp_cnt<=(others=>'0');
              i_status(C_LSTAT_TxOK)<='1';--//Информ. Транспорный уровень.
              fsm_llayer_cs <= S_L_IDLE;

          elsif p_in_phy_rxtype(C_TR_ERR)='1' then
          --//Проверка устройством CRC - ERROR!!!
              if p_in_phy_txrdy_n='0' then
                if i_txp_cnt/=CONV_STD_LOGIC_VECTOR(3, i_txp_cnt'length) then
                  i_txreq<=CONV_STD_LOGIC_VECTOR(C_TWTRM, i_txreq'length);
                else
                  i_txreq<=CONV_STD_LOGIC_VECTOR(C_TNONE, i_txreq'length);
                end if;
              end if;

              i_txp_cnt<=(others=>'0');
              i_status(C_LSTAT_TxERR_CRC)<='1';--//Информ. Транспорный уровень.
              fsm_llayer_cs <= S_L_IDLE;

          else

              if p_in_phy_txrdy_n='0' then
                if i_txp_cnt/=CONV_STD_LOGIC_VECTOR(3, i_txp_cnt'length) then
                  if i_txp_cnt=CONV_STD_LOGIC_VECTOR(2, i_txp_cnt'length) then
                    i_txreq<=CONV_STD_LOGIC_VECTOR(C_TCONT, i_txreq'length);
                    i_txp_cnt<=i_txp_cnt + 1;
                  else
                    i_txreq<=CONV_STD_LOGIC_VECTOR(C_TWTRM, i_txreq'length);
                    i_txp_cnt<=i_txp_cnt+1;
                  end if;
                else
                  i_txreq<=CONV_STD_LOGIC_VECTOR(C_TNONE, i_txreq'length);
                end if;
              end if;

          end if;

        end if;--//if p_in_phy_sync='1' then
      end if;--//if p_in_phy_rdy='0' then
      --//when S_LT_Wait =>





    --$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
    --$$$$$$$$ Link reciever states $$$$$$$$$$$$
    --$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
    --------------------------------------------
    -- Link recieve. STATE: S_LR_RcvWaitFifo
    --------------------------------------------
    when S_LR_RcvWaitFifo =>

      if p_in_phy_rdy='0' then
      --//Связь с утройством оборвана
        fsm_llayer_cs <= S_L_NoCommErr;

      else
        if p_in_phy_sync='1' then

          if p_in_phy_rxtype(C_TCONT)='1' then
          --//ВАЖНО!!! - все последующие данные будут аналогичны приему предыдущего примитива
              if p_in_phy_txrdy_n='0' then
                if i_txp_cnt/=CONV_STD_LOGIC_VECTOR(3, i_txp_cnt'length) then
                  if i_txp_cnt=CONV_STD_LOGIC_VECTOR(2, i_txp_cnt'length) then
                      i_txreq<=CONV_STD_LOGIC_VECTOR(C_TCONT, i_txreq'length);
                      i_txp_cnt<=i_txp_cnt + 1;
                  else
                    i_txreq<=CONV_STD_LOGIC_VECTOR(C_TSYNC, i_txreq'length);
                    i_txp_cnt<=i_txp_cnt+1;
                  end if;
                else
                  i_txreq<=CONV_STD_LOGIC_VECTOR(C_TNONE, i_txreq'length);
                end if;
              end if;

              i_rxp(C_TCONT)<='1';

          elsif CONV_INTEGER(p_in_phy_rxtype(C_TPMNAK downto C_TSOF))/= 0 and p_in_phy_rxtype(C_TX_RDY)='0' then
          --//ERROR!!! - Принял ошибочный примитив для этого сотояния автомата
              if p_in_phy_txrdy_n='0' then
                if i_txp_cnt/=CONV_STD_LOGIC_VECTOR(3, i_txp_cnt'length) then
                  i_txreq<=CONV_STD_LOGIC_VECTOR(C_TSYNC, i_txreq'length);
                else
                  i_txreq<=CONV_STD_LOGIC_VECTOR(C_TNONE, i_txreq'length);
                end if;
              end if;

              i_rxp<=(others=>'0');
              i_txp_cnt<=(others=>'0');
              i_status(C_LSTAT_RxERR_IDLE)<='1';--//Информ. Транспорный уровень
              fsm_llayer_cs <= S_L_IDLE;

          elsif p_in_phy_rxtype(C_TX_RDY)='1' or (i_rxp(C_TX_RDY)='1' and i_rxp(C_TCONT)='1') then
          --//Уст-во готово к передаче данных
              if p_in_phy_txrdy_n='0' then

                  if p_in_rxd_status.empty='1' then
                  --//RXBUF буфер готов к приему данных
                      if p_in_phy_txrdy_n='0' then
                        if i_txp_cnt/=CONV_STD_LOGIC_VECTOR(3, i_txp_cnt'length) then
                          i_txreq<=CONV_STD_LOGIC_VECTOR(C_TSYNC, i_txreq'length);
                        else
                          i_txreq<=CONV_STD_LOGIC_VECTOR(C_TNONE, i_txreq'length);
                        end if;
                      end if;

                      i_txp_cnt<=(others=>'0');
                      i_init_work<='1';--//Инициализация модулей CRC,Scrambler
                      fsm_llayer_cs <= S_LR_RcvChkRdy;

                  else

                      if i_txp_cnt/=CONV_STD_LOGIC_VECTOR(3, i_txp_cnt'length) then
                        if i_txp_cnt=CONV_STD_LOGIC_VECTOR(2, i_txp_cnt'length) then
                          i_txreq<=CONV_STD_LOGIC_VECTOR(C_TCONT, i_txreq'length);
                          i_txp_cnt<=i_txp_cnt + 1;
                        else
                          i_txreq<=CONV_STD_LOGIC_VECTOR(C_TSYNC, i_txreq'length);
                          i_txp_cnt<=i_txp_cnt+1;
                        end if;
                      else
                        i_txreq<=CONV_STD_LOGIC_VECTOR(C_TNONE, i_txreq'length);
                      end if;

                  end if;--//if p_in_rxd_status.empty='1' then

              end if;--//if p_in_phy_txrdy_n='0' then

              if p_in_phy_rxtype(C_TX_RDY)='1' then
                i_rxp(C_TCONT)<='0';
                i_rxp(C_TX_RDY)<='1';
              end if;

          else
              if p_in_phy_txrdy_n='0' then
                if i_txp_cnt/=CONV_STD_LOGIC_VECTOR(3, i_txp_cnt'length) then
                  if i_txp_cnt=CONV_STD_LOGIC_VECTOR(2, i_txp_cnt'length) then
                    i_txreq<=CONV_STD_LOGIC_VECTOR(C_TCONT, i_txreq'length);
                    i_txp_cnt<=i_txp_cnt + 1;
                  else
                    i_txreq<=CONV_STD_LOGIC_VECTOR(C_TSYNC, i_txreq'length);
                    i_txp_cnt<=i_txp_cnt+1;
                  end if;
                else
                  i_txreq<=CONV_STD_LOGIC_VECTOR(C_TNONE, i_txreq'length);
                end if;
              end if;

          end if;

        end if;--//if p_in_phy_sync='1' then
      end if;--//if p_in_phy_rdy='0' then
      --//when S_LR_RcvWaitFifo =>

    --------------------------------------------
    -- Link recieve. STATE: S_LR_RcvChkRdy
    --------------------------------------------
    when S_LR_RcvChkRdy =>

      if p_in_phy_rdy='0' then
      --//Связь с утройством оборвана
        fsm_llayer_cs <= S_L_NoCommErr;

      else
        if p_in_phy_sync='1' then

          i_init_work<='0';--//Инициализация модулей CRC,Scrambler

          if p_in_phy_rxtype(C_TCONT)='1' then
          --//ВАЖНО!!! - все последующие данные будут аналогичны приему предыдущего примитива
              if p_in_phy_txrdy_n='0' then
                if i_txp_cnt/=CONV_STD_LOGIC_VECTOR(3, i_txp_cnt'length) then
                  if i_txp_cnt=CONV_STD_LOGIC_VECTOR(2, i_txp_cnt'length) then
                      i_txreq<=CONV_STD_LOGIC_VECTOR(C_TCONT, i_txreq'length);
                      i_txp_cnt<=i_txp_cnt + 1;
                  else
                    i_txreq<=CONV_STD_LOGIC_VECTOR(C_TR_RDY, i_txreq'length);
                    i_txp_cnt<=i_txp_cnt+1;
                  end if;
                else
                  i_txreq<=CONV_STD_LOGIC_VECTOR(C_TNONE, i_txreq'length);
                end if;
              end if;

              i_rxp(C_TCONT)<='1';

          elsif p_in_phy_rxtype(C_TSOF)='1' then
          --//FRAME START
              if p_in_phy_txrdy_n='0' then
                if i_txp_cnt/=CONV_STD_LOGIC_VECTOR(3, i_txp_cnt'length) then
                  i_txreq<=CONV_STD_LOGIC_VECTOR(C_TR_RDY, i_txreq'length);
                else
                  i_txreq<=CONV_STD_LOGIC_VECTOR(C_TNONE, i_txreq'length);
                end if;
              end if;

              i_rxp<=(others=>'0');
              i_txp_cnt<=(others=>'0');
              i_rcv_en<='1';
              i_status(C_LSTAT_RxSTART)<='1';--//Информ. Транспорный уровень
              fsm_llayer_cs <= S_LR_RcvData;

          elsif CONV_INTEGER(p_in_phy_rxtype(C_TPMNAK downto C_TSOF))/= 0 and p_in_phy_rxtype(C_TX_RDY)='0' then
          --//ERROR!!! - Принял ошибочный примитив для этого сотояния автомата
              if p_in_phy_txrdy_n='0' then
                if i_txp_cnt/=CONV_STD_LOGIC_VECTOR(3, i_txp_cnt'length) then
                  i_txreq<=CONV_STD_LOGIC_VECTOR(C_TR_RDY, i_txreq'length);
                else
                  i_txreq<=CONV_STD_LOGIC_VECTOR(C_TNONE, i_txreq'length);
                end if;
              end if;

              i_rxp<=(others=>'0');
              i_txp_cnt<=(others=>'0');
              i_status(C_LSTAT_RxERR_IDLE)<='1';--//Информ. Транспорный уровень
              fsm_llayer_cs <= S_L_IDLE;

          elsif p_in_phy_rxtype(C_TX_RDY)='1' or (i_rxp(C_TX_RDY)='1' and i_rxp(C_TCONT)='1') then
          --//Уст-во готово к передаче данных
              if p_in_phy_txrdy_n='0' then
                if i_txp_cnt/=CONV_STD_LOGIC_VECTOR(3, i_txp_cnt'length) then
                  if i_txp_cnt=CONV_STD_LOGIC_VECTOR(2, i_txp_cnt'length) then
                    i_txreq<=CONV_STD_LOGIC_VECTOR(C_TCONT, i_txreq'length);
                    i_txp_cnt<=i_txp_cnt + 1;
                  else
                    i_txreq<=CONV_STD_LOGIC_VECTOR(C_TR_RDY, i_txreq'length);
                    i_txp_cnt<=i_txp_cnt+1;
                  end if;
                else
                  i_txreq<=CONV_STD_LOGIC_VECTOR(C_TNONE, i_txreq'length);
                end if;
              end if;

              if p_in_phy_rxtype(C_TX_RDY)='1' then
                i_rxp(C_TCONT)<='0';
                i_rxp(C_TX_RDY)<='1';
              end if;

          else
              if p_in_phy_txrdy_n='0' then
                if i_txp_cnt/=CONV_STD_LOGIC_VECTOR(3, i_txp_cnt'length) then
                  if i_txp_cnt=CONV_STD_LOGIC_VECTOR(2, i_txp_cnt'length) then
                    i_txreq<=CONV_STD_LOGIC_VECTOR(C_TCONT, i_txreq'length);
                    i_txp_cnt<=i_txp_cnt + 1;
                  else
                    i_txreq<=CONV_STD_LOGIC_VECTOR(C_TR_RDY, i_txreq'length);
                    i_txp_cnt<=i_txp_cnt+1;
                  end if;
                else
                  i_txreq<=CONV_STD_LOGIC_VECTOR(C_TNONE, i_txreq'length);
                end if;
              end if;

          end if;

        end if;--//if p_in_phy_sync='1' then
      end if;--//if p_in_phy_rdy='0' then
      --//when S_LR_RcvChkRdy =>

    --------------------------------------------
    -- Link recieve. STATE: S_LR_RcvData
    --------------------------------------------
    when S_LR_RcvData =>

      if p_in_phy_rdy='0' then
      --//Связь с утройством оборвана
          fsm_llayer_cs <= S_L_NoCommErr;

      else
        if p_in_phy_sync='1' then

          i_status(C_LSTAT_RxSTART)<='0';

          if p_in_ctrl(C_LCTRL_TRN_ESCAPE_BIT)='1' then
          --//Транспортный уровень хочет прервать текущую операцию
              if p_in_phy_txrdy_n='0' then
                if i_txp_cnt/=CONV_STD_LOGIC_VECTOR(3, i_txp_cnt'length) then
                  i_txreq<=CONV_STD_LOGIC_VECTOR(C_TR_IP, i_txreq'length);
                else
                  i_txreq<=CONV_STD_LOGIC_VECTOR(C_TNONE, i_txreq'length);
                end if;
              end if;

              i_rxp<=(others=>'0');
              i_txp_cnt<=(others=>'0');
              i_rcv_en<='0';
              fsm_llayer_cs <= S_L_SyncEscape;

          elsif p_in_phy_rxtype(C_TSYNC)='1' then
          --//Уст-во переывает текущую транзакию
              if p_in_phy_txrdy_n='0' then
                if i_txp_cnt/=CONV_STD_LOGIC_VECTOR(3, i_txp_cnt'length) then
                  i_txreq<=CONV_STD_LOGIC_VECTOR(C_TR_IP, i_txreq'length);
                else
                  i_txreq<=CONV_STD_LOGIC_VECTOR(C_TNONE, i_txreq'length);
                end if;
              end if;

              i_rxp<=(others=>'0');
              i_txp_cnt<=(others=>'0');
              i_status(C_LSTAT_RxERR_ABORT)<='1';--//Информ. Транспорный уровень
              i_rcv_en<='0';
              fsm_llayer_cs <= S_L_IDLE;

          elsif p_in_phy_rxtype(C_TWTRM)='1' then
          --//ERROR!!! - прият примитив WTRM, но небыло приема EOF
              if p_in_phy_txrdy_n='0' then
                if i_txp_cnt/=CONV_STD_LOGIC_VECTOR(3, i_txp_cnt'length) then
                  i_txreq<=CONV_STD_LOGIC_VECTOR(C_TR_IP, i_txreq'length);
                else
                  i_txreq<=CONV_STD_LOGIC_VECTOR(C_TNONE, i_txreq'length);
                end if;
              end if;

              i_rxp<=(others=>'0');
              i_txp_cnt<=(others=>'0');
              i_rcv_en<='0';
              fsm_llayer_cs <= S_LR_BadEnd;

          elsif p_in_phy_rxtype(C_TEOF)='1' then
          --//FRAME END
              if p_in_phy_txrdy_n='0' then
                if i_txp_cnt/=CONV_STD_LOGIC_VECTOR(3, i_txp_cnt'length) then
                  if i_txp_cnt=CONV_STD_LOGIC_VECTOR(2, i_txp_cnt'length) then
                    i_txreq<=CONV_STD_LOGIC_VECTOR(C_TCONT, i_txreq'length);
                    i_txp_cnt<=i_txp_cnt + 1;
                  else
                    i_txreq<=CONV_STD_LOGIC_VECTOR(C_TR_IP, i_txreq'length);
                    i_txp_cnt<=i_txp_cnt+1;
                  end if;
                else
                  i_txreq<=CONV_STD_LOGIC_VECTOR(C_TNONE, i_txreq'length);
                end if;

                i_txr_ip<='1';
              end if;

              i_rxp<=(others=>'0');
              i_rcv_en<='0';
              fsm_llayer_cs <= S_LR_RcvEOF;

          elsif p_in_phy_rxtype(C_THOLD)='1' then
          --//Устро-во синализирует что передача отложена
              if p_in_phy_txrdy_n='0' then
                if i_txp_cnt/=CONV_STD_LOGIC_VECTOR(3, i_txp_cnt'length) then
                  i_txreq<=CONV_STD_LOGIC_VECTOR(C_TR_IP, i_txreq'length);
                else
                  i_txreq<=CONV_STD_LOGIC_VECTOR(C_TNONE, i_txreq'length);
                end if;

                i_txr_ip<='1';
              end if;

              i_rxp<=(others=>'0');
              i_txp_cnt<=(others=>'0');
              i_rcv_en<='0';
              fsm_llayer_cs <= S_LR_SendHold;

          elsif CONV_INTEGER(p_in_phy_rxtype(C_TPMNAK downto C_TSOF))/= 0 or i_rxp(C_TCONT)='1' then
          --//Принял некий примимив, но не SYNC, C_TWTRM, EOF, C_THOLD
              if p_in_phy_txrdy_n='0' then
                if i_txp_cnt/=CONV_STD_LOGIC_VECTOR(3, i_txp_cnt'length) then
                  if i_txp_cnt=CONV_STD_LOGIC_VECTOR(2, i_txp_cnt'length) then
                    i_txreq<=CONV_STD_LOGIC_VECTOR(C_TCONT, i_txreq'length);
                    i_txp_cnt<=i_txp_cnt + 1;
                  else
                    i_txreq<=CONV_STD_LOGIC_VECTOR(C_TR_IP, i_txreq'length);
                    i_txp_cnt<=i_txp_cnt+1;
                  end if;
                else
                  i_txreq<=CONV_STD_LOGIC_VECTOR(C_TNONE, i_txreq'length);
                end if;

                i_txr_ip<='1';
              end if;

              if p_in_phy_rxtype(C_TCONT)='1' then
              --//ВАЖНО!!! - все последующие данные будут аналогичны приему предыдущего примитива
                i_rxp(C_TCONT)<='1';

              elsif CONV_INTEGER(p_in_phy_rxtype(C_TPMNAK downto C_TSOF))/= 0 then
                i_rxp(C_TCONT)<='0';
                i_rcv_en<='1';

              end if;

          elsif p_in_phy_rxtype(C_TDATA_EN)='1' then
          --//Принимаю данные от уст-ва
              i_rcv_work<='1';

              if p_in_phy_txrdy_n='0' then

                  if p_in_rxd_status.pfull='1' then
                  --//RXBUF не готов к приему данных
                  --//Сигнализирую уст-ву приостановить передачу данных
                      if p_in_phy_txrdy_n='0' then
                        if i_txp_cnt/=CONV_STD_LOGIC_VECTOR(3, i_txp_cnt'length) then
                          i_txreq<=CONV_STD_LOGIC_VECTOR(C_TR_IP, i_txreq'length);
                        else
                          i_txreq<=CONV_STD_LOGIC_VECTOR(C_TNONE, i_txreq'length);
                        end if;

                        i_txr_ip<='1';
                      end if;

                      i_rxp(C_TCONT)<='0';
                      i_rxp(C_THOLD)<='0';
                      i_txp_cnt<=(others=>'0');
                      fsm_llayer_cs <= S_LR_Hold;

                  else
                  --//RXBUF готов к приему данных
                      i_rcv_en<='1';

                      if p_in_phy_txrdy_n='0' then
                        if i_txp_cnt/=CONV_STD_LOGIC_VECTOR(3, i_txp_cnt'length) then
                          if i_txp_cnt=CONV_STD_LOGIC_VECTOR(2, i_txp_cnt'length) then
                            i_txreq<=CONV_STD_LOGIC_VECTOR(C_TCONT, i_txreq'length);
                            i_txp_cnt<=i_txp_cnt + 1;
                          else
                            i_txreq<=CONV_STD_LOGIC_VECTOR(C_TR_IP, i_txreq'length);
                            i_txp_cnt<=i_txp_cnt+1;
                          end if;
                        else
                          i_txreq<=CONV_STD_LOGIC_VECTOR(C_TNONE, i_txreq'length);
                        end if;

                        i_txr_ip<='1';

                      end if;

                  end if;
              end if;--//if p_in_phy_txrdy_n='0' then

          else

              if p_in_phy_txrdy_n='0' then
                if i_txp_cnt/=CONV_STD_LOGIC_VECTOR(3, i_txp_cnt'length) then
                  if i_txp_cnt=CONV_STD_LOGIC_VECTOR(2, i_txp_cnt'length) then
                    i_txreq<=CONV_STD_LOGIC_VECTOR(C_TCONT, i_txreq'length);
                    i_txp_cnt<=i_txp_cnt + 1;
                  else
                    i_txreq<=CONV_STD_LOGIC_VECTOR(C_TR_IP, i_txreq'length);
                    i_txp_cnt<=i_txp_cnt+1;
                  end if;
                else
                  i_txreq<=CONV_STD_LOGIC_VECTOR(C_TNONE, i_txreq'length);
                end if;

                i_txr_ip<='1';

              end if;

          end if;

        end if;--//if p_in_phy_sync='1' then
      end if;--//if p_in_phy_rdy='0' then
      --//when S_LR_RcvData =>

    --------------------------------------------
    -- Link recieve. STATE: S_LR_Hold (Отправка примитва HOLD)
    --------------------------------------------
    when S_LR_Hold =>

      if p_in_phy_rdy='0' then
      --//Связь с утройством оборвана
        fsm_llayer_cs <= S_L_NoCommErr;

      else
          if p_in_phy_sync='1' then

            if p_in_ctrl(C_LCTRL_TRN_ESCAPE_BIT)='1' then
            --//Транспортный уровень хочет прервать текущую операцию
                if p_in_phy_txrdy_n='0' then
                  if i_txp_cnt/=CONV_STD_LOGIC_VECTOR(3, i_txp_cnt'length) then
                    i_txreq<=CONV_STD_LOGIC_VECTOR(C_THOLD, i_txreq'length);
                  else
                    i_txreq<=CONV_STD_LOGIC_VECTOR(C_TNONE, i_txreq'length);
                  end if;
                end if;

                i_rxp<=(others=>'0');
                i_txp_cnt<=(others=>'0');
                i_rcv_en<='0';
                fsm_llayer_cs <= S_L_SyncEscape;

            elsif p_in_phy_rxtype(C_TSYNC)='1' then
            --//Уст-во переывает текущую транзакию
                if p_in_phy_txrdy_n='0' then
                  if i_txp_cnt/=CONV_STD_LOGIC_VECTOR(3, i_txp_cnt'length) then
                    i_txreq<=CONV_STD_LOGIC_VECTOR(C_THOLD, i_txreq'length);
                  else
                    i_txreq<=CONV_STD_LOGIC_VECTOR(C_TNONE, i_txreq'length);
                  end if;
                end if;

                i_rxp<=(others=>'0');
                i_txp_cnt<=(others=>'0');
                i_status(C_LSTAT_RxERR_ABORT)<='1';--//Информ. Транспорный уровень
                i_rcv_en<='0';
                fsm_llayer_cs <= S_L_IDLE;

            elsif p_in_phy_rxtype(C_TEOF)='1' then
            --//FRAME END
                if p_in_phy_txrdy_n='0' then
                  if i_txp_cnt/=CONV_STD_LOGIC_VECTOR(3, i_txp_cnt'length) then
                    i_txreq<=CONV_STD_LOGIC_VECTOR(C_THOLD, i_txreq'length);
                  else
                    i_txreq<=CONV_STD_LOGIC_VECTOR(C_TNONE, i_txreq'length);
                  end if;
                end if;

                i_rxp<=(others=>'0');
                i_txp_cnt<=(others=>'0');
                i_rcv_en<='0';
                fsm_llayer_cs <= S_LR_RcvEOF;

            elsif p_in_phy_rxtype(C_TCONT)='1' then
            --//ВАЖНО!!! - все последующие данные будут аналогичны приему предыдущего примитива
                if p_in_phy_txrdy_n='0' then
                  if i_txp_cnt/=CONV_STD_LOGIC_VECTOR(3, i_txp_cnt'length) then
                    if i_txp_cnt=CONV_STD_LOGIC_VECTOR(2, i_txp_cnt'length) then
                        i_txreq<=CONV_STD_LOGIC_VECTOR(C_TCONT, i_txreq'length);
                        i_txp_cnt<=i_txp_cnt + 1;
                    else
                      i_txreq<=CONV_STD_LOGIC_VECTOR(C_THOLD, i_txreq'length);
                      i_txp_cnt<=i_txp_cnt+1;
                    end if;
                  else
                    i_txreq<=CONV_STD_LOGIC_VECTOR(C_TNONE, i_txreq'length);
                  end if;

                  i_txr_ip<='0';
                end if;

                i_rxp(C_TCONT)<='1';
                i_rcv_en<='0';

--            elsif (CONV_INTEGER(p_in_phy_rxtype(C_TPMNAK downto C_TSOF))/= 0 and p_in_phy_rxtype(C_THOLD)='0') or (i_rxp(C_TCONT)='1' and i_rxp(C_THOLD)='0') then
            elsif CONV_INTEGER(p_in_phy_rxtype(C_TPMNAK downto C_TSOF))/= 0 and p_in_phy_rxtype(C_THOLD)='0' then
            --//Принял некий примимив, но не SYNC, EOF, CONT, HOLD
                if p_in_rxd_status.empty='1' then
                --RXBUF готов к приему данных
                    if p_in_phy_txrdy_n='0' then
                      if i_txp_cnt/=CONV_STD_LOGIC_VECTOR(3, i_txp_cnt'length) then
                        i_txreq<=CONV_STD_LOGIC_VECTOR(C_THOLD, i_txreq'length);
                      else
                        i_txreq<=CONV_STD_LOGIC_VECTOR(C_TNONE, i_txreq'length);
                      end if;
                    end if;

                    i_txp_cnt<=(others=>'0');
                    fsm_llayer_cs <= S_LR_RcvData;

                else
                    if p_in_phy_txrdy_n='0' then
                      if i_txp_cnt/=CONV_STD_LOGIC_VECTOR(3, i_txp_cnt'length) then
                        if i_txp_cnt=CONV_STD_LOGIC_VECTOR(2, i_txp_cnt'length) then
                            i_txreq<=CONV_STD_LOGIC_VECTOR(C_TCONT, i_txreq'length);
                            i_txp_cnt<=i_txp_cnt + 1;
                        else
                          i_txreq<=CONV_STD_LOGIC_VECTOR(C_THOLD, i_txreq'length);
                          i_txp_cnt<=i_txp_cnt+1;
                        end if;
                      else
                        i_txreq<=CONV_STD_LOGIC_VECTOR(C_TNONE, i_txreq'length);
                      end if;

                      i_txr_ip<='0';
                    end if;

                end if;

                i_rxp<=(others=>'0');
                i_rcv_en<='1';

            elsif p_in_phy_rxtype(C_THOLD)='1' or (i_rxp(C_THOLD)='1' and i_rxp(C_TCONT)='1') then
            --//Устро-во синализирует что передача отложена
                if p_in_rxd_status.empty='1' then
                --//Ждем пока будет готов RxBUF
                    if p_in_phy_txrdy_n='0' then
                      if i_txp_cnt/=CONV_STD_LOGIC_VECTOR(3, i_txp_cnt'length) then
                        i_txreq<=CONV_STD_LOGIC_VECTOR(C_THOLD, i_txreq'length);
                      else
                        i_txreq<=CONV_STD_LOGIC_VECTOR(C_TNONE, i_txreq'length);
                      end if;
                    end if;

                    i_txp_cnt<=(others=>'0');
                    fsm_llayer_cs <= S_LR_SendHold;

                else

                    if p_in_phy_txrdy_n='0' then
                      if i_txp_cnt/=CONV_STD_LOGIC_VECTOR(3, i_txp_cnt'length) then
                        if i_txp_cnt=CONV_STD_LOGIC_VECTOR(2, i_txp_cnt'length) then
                            i_txreq<=CONV_STD_LOGIC_VECTOR(C_TCONT, i_txreq'length);
                            i_txp_cnt<=i_txp_cnt + 1;
                        else
                          i_txreq<=CONV_STD_LOGIC_VECTOR(C_THOLD, i_txreq'length);
                          i_txp_cnt<=i_txp_cnt+1;
                        end if;
                      else
                        i_txreq<=CONV_STD_LOGIC_VECTOR(C_TNONE, i_txreq'length);
                      end if;
                    end if;
                end if;

                if p_in_phy_rxtype(C_THOLD)='1' then
                  i_rxp(C_TCONT)<='0';
                  i_rxp(C_THOLD)<='1';
                end if;

            else

                if p_in_rxd_status.empty='1' then
                --RXBUF готов к приему данных
                    if p_in_phy_txrdy_n='0' then
                      if i_txp_cnt/=CONV_STD_LOGIC_VECTOR(3, i_txp_cnt'length) then
                        i_txreq<=CONV_STD_LOGIC_VECTOR(C_THOLD, i_txreq'length);
                      else
                        i_txreq<=CONV_STD_LOGIC_VECTOR(C_TNONE, i_txreq'length);
                      end if;
                    end if;

                    i_txp_cnt<=(others=>'0');
                    if (i_rxp(C_THOLD)='1' and i_rxp(C_TCONT)='1') then
                    --//Был прием примитива HOLD - Устро-во синализирует что передача отложена
                      fsm_llayer_cs <= S_LR_SendHold;

                    else
                    --//Возвращаемся к приему данных
                      fsm_llayer_cs <= S_LR_RcvData;
                    end if;

                else

                    if p_in_phy_txrdy_n='0' then
                      if i_txp_cnt/=CONV_STD_LOGIC_VECTOR(3, i_txp_cnt'length) then
                        if i_txp_cnt=CONV_STD_LOGIC_VECTOR(2, i_txp_cnt'length) then
                            i_txreq<=CONV_STD_LOGIC_VECTOR(C_TCONT, i_txreq'length);
                            i_txp_cnt<=i_txp_cnt + 1;
                        else
                          i_txreq<=CONV_STD_LOGIC_VECTOR(C_THOLD, i_txreq'length);
                          i_txp_cnt<=i_txp_cnt+1;
                        end if;
                      else
                        i_txreq<=CONV_STD_LOGIC_VECTOR(C_TNONE, i_txreq'length);
                      end if;

                      i_txr_ip<='0';
                    end if;

                end if;

            end if;

          end if;--//if p_in_phy_sync='1' then
      end if;--//if p_in_phy_rdy='0' then
      --//when S_LR_Hold =>


    --------------------------------------------
    -- Link recieve. STATE: S_LR_SendHold (Прием примитва HOLD)
    --------------------------------------------
    when S_LR_SendHold =>

      if p_in_phy_rdy='0' then
      --//Связь с утройством оборвана
        fsm_llayer_cs <= S_L_NoCommErr;

      else
          if p_in_phy_sync='1' then

            if p_in_ctrl(C_LCTRL_TRN_ESCAPE_BIT)='1' then
            --//Транспортный уровень хочет прервать текущую операцию
                if p_in_phy_txrdy_n='0' then
                  if i_txp_cnt/=CONV_STD_LOGIC_VECTOR(3, i_txp_cnt'length) then
                    i_txreq<=CONV_STD_LOGIC_VECTOR(C_THOLDA, i_txreq'length);
                  else
                    i_txreq<=CONV_STD_LOGIC_VECTOR(C_TNONE, i_txreq'length);
                  end if;
                end if;

                i_rxp<=(others=>'0');
                i_txp_cnt<=(others=>'0');
                i_rcv_en<='0';
                fsm_llayer_cs <= S_L_SyncEscape;

            elsif p_in_phy_rxtype(C_TSYNC)='1' then
            --//Уст-во переывает текущую транзакию
                if p_in_phy_txrdy_n='0' then
                  if i_txp_cnt/=CONV_STD_LOGIC_VECTOR(3, i_txp_cnt'length) then
                    i_txreq<=CONV_STD_LOGIC_VECTOR(C_THOLDA, i_txreq'length);
                  else
                    i_txreq<=CONV_STD_LOGIC_VECTOR(C_TNONE, i_txreq'length);
                  end if;
                end if;

                i_rxp<=(others=>'0');
                i_txp_cnt<=(others=>'0');
                i_status(C_LSTAT_RxERR_ABORT)<='1';--//Информ. Транспорный уровень
                i_rcv_en<='0';
                fsm_llayer_cs <= S_L_IDLE;

            elsif p_in_phy_rxtype(C_TEOF)='1' then
            --//FRAME END
                if p_in_phy_txrdy_n='0' then
                  if i_txp_cnt/=CONV_STD_LOGIC_VECTOR(3, i_txp_cnt'length) then
                    i_txreq<=CONV_STD_LOGIC_VECTOR(C_THOLDA, i_txreq'length);
                  else
                    i_txreq<=CONV_STD_LOGIC_VECTOR(C_TNONE, i_txreq'length);
                  end if;
                end if;

                i_rxp<=(others=>'0');
                i_txp_cnt<=(others=>'0');
                i_rcv_en<='0';
                fsm_llayer_cs <= S_LR_RcvEOF;

            elsif p_in_phy_rxtype(C_TCONT)='1' then
            --//ВАЖНО!!! - все последующие данные будут аналогичны приему предыдущего примитива
                if p_in_phy_txrdy_n='0' then
                  if i_txp_cnt/=CONV_STD_LOGIC_VECTOR(3, i_txp_cnt'length) then
                    if i_txp_cnt=CONV_STD_LOGIC_VECTOR(2, i_txp_cnt'length) then
                      i_txreq<=CONV_STD_LOGIC_VECTOR(C_TCONT, i_txreq'length);
                      i_txp_cnt<=i_txp_cnt + 1;
                    else
                      i_txreq<=CONV_STD_LOGIC_VECTOR(C_THOLDA, i_txreq'length);
                      i_txp_cnt<=i_txp_cnt+1;
                    end if;
                  else
                    i_txreq<=CONV_STD_LOGIC_VECTOR(C_TNONE, i_txreq'length);
                  end if;
                end if;

                i_rxp(C_TCONT)<='1';
                i_rcv_en<='0';

            elsif p_in_phy_rxtype(C_THOLD)='1' or (i_rxp(C_THOLD)='1' and i_rxp(C_TCONT)='1') then
            --//Устро-во синализирует что передача отложена
                if p_in_phy_txrdy_n='0' then
                  if i_txp_cnt/=CONV_STD_LOGIC_VECTOR(3, i_txp_cnt'length) then
                    if i_txp_cnt=CONV_STD_LOGIC_VECTOR(2, i_txp_cnt'length) then
                      i_txreq<=CONV_STD_LOGIC_VECTOR(C_TCONT, i_txreq'length);
                      i_txp_cnt<=i_txp_cnt + 1;
                    else
                      i_txreq<=CONV_STD_LOGIC_VECTOR(C_THOLDA, i_txreq'length);
                      i_txp_cnt<=i_txp_cnt+1;
                    end if;
                  else
                    i_txreq<=CONV_STD_LOGIC_VECTOR(C_TNONE, i_txreq'length);
                  end if;

                  i_txr_ip<='0';
                end if;

                if p_in_phy_rxtype(C_THOLD)='1' then
                  i_rxp(C_TCONT)<='0';
                  i_rxp(C_THOLD)<='1';
                  i_rcv_en<='1';
                end if;

            elsif p_in_phy_rxtype(C_TDATA_EN)='1' and i_rxp(C_TCONT)='0' then
            --//Принял некией DWORD, но не SYNC, EOF, CONT, HOLD
            --//Возвращаемся к приему данных
                if p_in_phy_txrdy_n='0' then
                  if i_txp_cnt/=CONV_STD_LOGIC_VECTOR(3, i_txp_cnt'length) then
                    i_txreq<=CONV_STD_LOGIC_VECTOR(C_THOLDA, i_txreq'length);
                  else
                    i_txreq<=CONV_STD_LOGIC_VECTOR(C_TNONE, i_txreq'length);
                  end if;
                end if;

                i_rxp<=(others=>'0');
                i_txp_cnt<=(others=>'0');
                i_rcv_work<='1';
                fsm_llayer_cs <= S_LR_RcvData;

            else

                if p_in_phy_txrdy_n='0' then
                  if i_txp_cnt/=CONV_STD_LOGIC_VECTOR(3, i_txp_cnt'length) then
                    if i_txp_cnt=CONV_STD_LOGIC_VECTOR(2, i_txp_cnt'length) then
                      i_txreq<=CONV_STD_LOGIC_VECTOR(C_TCONT, i_txreq'length);
                      i_txp_cnt<=i_txp_cnt + 1;
                    else
                      i_txreq<=CONV_STD_LOGIC_VECTOR(C_THOLDA, i_txreq'length);
                      i_txp_cnt<=i_txp_cnt+1;
                    end if;
                  else
                    i_txreq<=CONV_STD_LOGIC_VECTOR(C_TNONE, i_txreq'length);
                  end if;

                  i_txr_ip<='0';
                end if;

            end if;

          end if;--//if p_in_phy_sync='1' then
      end if;--if p_in_phy_rdy='0' then
      --//when S_LR_SendHold =>

    --------------------------------------------
    -- Link recieve. STATE: S_LR_RcvEOF
    --------------------------------------------
    when S_LR_RcvEOF =>

      if p_in_phy_rdy='0' then
      --//Связь с утройством оборвана
        fsm_llayer_cs <= S_L_NoCommErr;

      else
        if p_in_phy_sync='1' then

            i_rcv_work<='0';

            if p_in_phy_txrdy_n='0' then

                if i_txr_ip='0' then
                    if i_txp_cnt/=CONV_STD_LOGIC_VECTOR(3, i_txp_cnt'length) then
                      if i_txp_cnt=CONV_STD_LOGIC_VECTOR(2, i_txp_cnt'length) then
                        i_txreq<=CONV_STD_LOGIC_VECTOR(C_TCONT, i_txreq'length);
                        i_txp_cnt<=i_txp_cnt + 1;
                      else
                        i_txreq<=CONV_STD_LOGIC_VECTOR(C_TR_IP, i_txreq'length);
                        i_txp_cnt<=i_txp_cnt+1;
                      end if;
                    else
                      i_txreq<=CONV_STD_LOGIC_VECTOR(C_TNONE, i_txreq'length);
                    end if;

                else
                    if i_txp_cnt/=CONV_STD_LOGIC_VECTOR(3, i_txp_cnt'length) then
                      i_txreq<=CONV_STD_LOGIC_VECTOR(C_TR_IP, i_txreq'length);
                    else
                      i_txreq<=CONV_STD_LOGIC_VECTOR(C_TNONE, i_txreq'length);
                    end if;

                end if;

                --//Анализ принятого/расчтаного CRC
                if i_crc_out=i_rxd_out then

                    i_status(C_LSTAT_RxOK)<='1';--//Информ. Транспорный уровень
                    fsm_llayer_cs <= S_LR_GoodCRC;

                else

                    i_status(C_LSTAT_RxERR_CRC)<='1';--//Информ. Транспорный уровень
                    fsm_llayer_cs <= S_LR_BadEnd;

                end if;

            end if;--//if p_in_phy_txrdy_n='0' then

        end if;--//if p_in_phy_sync='1' then
      end if;--//if p_in_phy_rdy='0' then
      --//when S_LR_RcvEOF =>

    --------------------------------------------
    -- Link recieve. STATE: S_LR_GoodCRC
    --------------------------------------------
    when S_LR_GoodCRC =>

      if p_in_phy_rdy='0' then
      --//Связь с утройством оборвана
        fsm_llayer_cs <= S_L_NoCommErr;

      else
        if p_in_phy_sync='1' then

            if p_in_phy_rxtype(C_TSYNC)='1' then
            --//Уст-во переывает текущую транзакию

                if p_in_phy_txrdy_n='0' then
                  if i_txp_cnt/=CONV_STD_LOGIC_VECTOR(3, i_txp_cnt'length) then
                    i_txreq<=CONV_STD_LOGIC_VECTOR(C_TR_IP, i_txreq'length);
                  else
                    i_txreq<=CONV_STD_LOGIC_VECTOR(C_TNONE, i_txreq'length);
                  end if;
                end if;

                i_txp_cnt<=(others=>'0');
                i_status(C_LSTAT_RxERR_ABORT)<='1';--//Информ. Транспорный уровень
                fsm_llayer_cs <= S_L_IDLE;

            else

                if i_tl_check_done='1' then
                  if p_in_phy_txrdy_n='0' then
                      if i_txp_cnt/=CONV_STD_LOGIC_VECTOR(3, i_txp_cnt'length) then
                        i_txreq<=CONV_STD_LOGIC_VECTOR(C_TR_IP, i_txreq'length);
                      else
                        i_txreq<=CONV_STD_LOGIC_VECTOR(C_TNONE, i_txreq'length);
                      end if;

                      i_txp_cnt<=(others=>'0');

                      --//Жду подтверждения от Транспортного уровня
                      if i_tl_check_ok='1' then
                        fsm_llayer_cs <= S_LR_GoodEnd;

                      else
                        fsm_llayer_cs <= S_LR_BadEnd;

                      end if;

                  end if;

                else
                    if i_txp_cnt/=CONV_STD_LOGIC_VECTOR(3, i_txp_cnt'length) then
                      if i_txp_cnt=CONV_STD_LOGIC_VECTOR(2, i_txp_cnt'length) then
                        i_txreq<=CONV_STD_LOGIC_VECTOR(C_TCONT, i_txreq'length);
                        i_txp_cnt<=i_txp_cnt + 1;
                      else
                        i_txreq<=CONV_STD_LOGIC_VECTOR(C_TR_IP, i_txreq'length);
                        i_txp_cnt<=i_txp_cnt+1;
                      end if;
                    else
                      i_txreq<=CONV_STD_LOGIC_VECTOR(C_TNONE, i_txreq'length);
                    end if;

                end if;

            end if;

        end if;--//if p_in_phy_sync='1' then
      end if;--//if p_in_phy_rdy='0' then
      --//when S_LR_GoodCRC =>

    --------------------------------------------
    -- Link recieve. STATE: S_LR_GoodEnd
    --------------------------------------------
    when S_LR_GoodEnd =>

      if p_in_phy_rdy='0' then
      --//Связь с утройством оборвана
        fsm_llayer_cs <= S_L_NoCommErr;

      else
        if p_in_phy_sync='1' then

            --//Жду от устройства примитив SYNC
            if p_in_phy_rxtype(C_TSYNC)='1' then

                if p_in_phy_txrdy_n='0' then
                  if i_txp_cnt/=CONV_STD_LOGIC_VECTOR(3, i_txp_cnt'length) then
                    i_txreq<=CONV_STD_LOGIC_VECTOR(C_TR_OK, i_txreq'length);
                  else
                    i_txreq<=CONV_STD_LOGIC_VECTOR(C_TNONE, i_txreq'length);
                  end if;
                end if;

                i_txp_cnt<=(others=>'0');
                i_status(C_LSTAT_RxDONE)<='1';--//Информ. Транспорный уровень
                fsm_llayer_cs <= S_L_IDLE;

            else

                if p_in_phy_txrdy_n='0' then
                  if i_txp_cnt/=CONV_STD_LOGIC_VECTOR(3, i_txp_cnt'length) then
                    if i_txp_cnt=CONV_STD_LOGIC_VECTOR(2, i_txp_cnt'length) then
                        i_txreq<=CONV_STD_LOGIC_VECTOR(C_TCONT, i_txreq'length);
                        i_txp_cnt<=i_txp_cnt + 1;
                    else
                      i_txreq<=CONV_STD_LOGIC_VECTOR(C_TR_OK, i_txreq'length);
                      i_txp_cnt<=i_txp_cnt+1;
                    end if;
                  else
                    i_txreq<=CONV_STD_LOGIC_VECTOR(C_TNONE, i_txreq'length);
                  end if;
                end if;
            end if;

        end if;--//if p_in_phy_sync='1' then
      end if;--//f p_in_phy_rdy='0' then
      --//when S_LR_GoodEnd =>

    --------------------------------------------
    -- Link recieve. STATE: S_LR_BadEnd
    --------------------------------------------
    when S_LR_BadEnd =>

      if p_in_phy_rdy='0' then
      --//Связь с утройством оборвана
        fsm_llayer_cs <= S_L_NoCommErr;

      else
        if p_in_phy_sync='1' then

            if p_in_phy_rxtype(C_TSYNC)='1' then

                if p_in_phy_txrdy_n='0' then
                  if i_txp_cnt/=CONV_STD_LOGIC_VECTOR(3, i_txp_cnt'length) then
                    i_txreq<=CONV_STD_LOGIC_VECTOR(C_TR_ERR, i_txreq'length);
                  else
                    i_txreq<=CONV_STD_LOGIC_VECTOR(C_TNONE, i_txreq'length);
                  end if;
                end if;

                i_txp_cnt<=(others=>'0');
                i_status(C_LSTAT_RxDONE)<='1';--//Информ. Транспорный уровень
                fsm_llayer_cs <= S_L_IDLE;

            else

                if p_in_phy_txrdy_n='0' then
                  if i_txp_cnt/=CONV_STD_LOGIC_VECTOR(3, i_txp_cnt'length) then
                    if i_txp_cnt=CONV_STD_LOGIC_VECTOR(2, i_txp_cnt'length) then
                        i_txreq<=CONV_STD_LOGIC_VECTOR(C_TCONT, i_txreq'length);
                        i_txp_cnt<=i_txp_cnt + 1;
                    else
                      i_txreq<=CONV_STD_LOGIC_VECTOR(C_TR_ERR, i_txreq'length);
                      i_txp_cnt<=i_txp_cnt+1;
                    end if;
                  else
                    i_txreq<=CONV_STD_LOGIC_VECTOR(C_TNONE, i_txreq'length);
                  end if;
                end if;
            end if;

        end if;--//if p_in_phy_sync='1' then
      end if;--//f p_in_phy_rdy='0' then
      --//when S_LR_BadEnd =>


  end case;
--end if;
end if;
end process lfsm;


--//Только для моделирования (удобства алализа данных при моделироании)
gen_sim_on : if strcmp(G_SIM,"ON") generate

tst_ll_rxp.dmat<=i_rxp(C_TDMAT);
tst_ll_rxp.hold<=i_rxp(C_THOLD);
tst_ll_rxp.xrdy<=i_rxp(C_TX_RDY);
tst_ll_rxp.cont<=i_rxp(C_TCONT);

tst_ll_ctrl.trn_escape<=p_in_ctrl(C_LCTRL_TRN_ESCAPE_BIT);
tst_ll_ctrl.txstart<=p_in_ctrl(C_LCTRL_TxSTART_BIT );
tst_ll_ctrl.tl_check_err<=p_in_ctrl(C_LCTRL_TL_CHECK_ERR_BIT);
tst_ll_ctrl.tl_check_done<=p_in_ctrl(C_LCTRL_TL_CHECK_DONE_BIT);

tst_ll_status.rxok<=i_status(C_LSTAT_RxOK);
tst_ll_status.rxdmat<=i_status(C_LSTAT_RxDMAT);
tst_ll_status.rxstart<=i_status(C_LSTAT_RxSTART);
tst_ll_status.rxdone<=i_status(C_LSTAT_RxDONE);
tst_ll_status.rxerr_crc<=i_status(C_LSTAT_RxERR_CRC);
tst_ll_status.rxerr_idle<=i_status(C_LSTAT_RxERR_IDLE);
tst_ll_status.rxerr_abort<=i_status(C_LSTAT_RxERR_ABORT);
tst_ll_status.txok<=i_status(C_LSTAT_TxOK);
tst_ll_status.txdmat<=i_status(C_LSTAT_TxDMAT);
tst_ll_status.txerr_crc<=i_status(C_LSTAT_TxERR_CRC);
tst_ll_status.txerr_idle<=i_status(C_LSTAT_TxERR_IDLE);
tst_ll_status.txerr_abort<=i_status(C_LSTAT_TxERR_ABORT);

process(tst_ll_rxp,tst_ll_ctrl,tst_ll_status)
begin
  if tst_ll_rxp.dmat='1' or
     tst_ll_ctrl.txstart='1' or
      tst_ll_status.rxok='1' then
    tst_val<='1';
  else
    tst_val<='0';
  end if;
end process;

end generate gen_sim_on;

gen_sim_off : if strcmp(G_SIM,"OFF") generate
tst_val<='0';
end generate gen_sim_off;

--END MAIN
end behavioral;

