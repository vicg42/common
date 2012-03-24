-------------------------------------------------------------------------
-- Company     : Linkos
-- Engineer    : Golovachenko Victor
--
-- Create Date : 05.03.2011 13:10:01
-- Module Name : sata_tlayer
--
-- Назначение :
--   Transport Layer:
--   1. Организация протокола обмена с устро-вом на уровне FIS,
--      согласно спецификации SATA для уровня Transport Layer
--     (см. пп 10.4 Serial ATA Specification v2.5 (2005-10-27).pdf)
--
-- Revision:
-- Revision 0.01 - 25.11.2008 - Начало работы над проектом SATA
-- Revision 1.00 - Полная переделка проекта
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

entity sata_tlayer is
generic(
G_DBG : string:="OFF";
G_SIM : string:="OFF"
);
port(
--------------------------------------------------
--Связь с USRAPP Layer
--------------------------------------------------
--//Связь с TXFIFO
p_in_txfifo_dout    : in    std_logic_vector(31 downto 0);
p_out_txfifo_rd     : out   std_logic;
p_in_txfifo_status  : in    TTxBufStatus;                 --//Структуры см. sata_pkg.vhd/поле - Типы

--//Связь с RXFIFO
p_out_rxfifo_din    : out   std_logic_vector(31 downto 0);
p_out_rxfifo_wd     : out   std_logic;
p_in_rxfifo_status  : in    TRxBufStatus;                 --//Структуры см. sata_pkg.vhd/поле - Типы

--------------------------------------------------
--Связь с APP Layer
--------------------------------------------------
p_in_tl_ctrl        : in    std_logic_vector(C_TLCTRL_LAST_BIT downto 0);--//Константы см. sata_pkg.vhd/поле - Transport Layer/Управление/Map:
p_out_tl_status     : out   std_logic_vector(C_TLSTAT_LAST_BIT downto 0);--//Константы см. sata_pkg.vhd/поле - Transport Layer/Статусы/Map:

p_out_reg_fpdma     : out   TRegFPDMASetup;               --//Структуры см. sata_pkg.vhd/поле - Типы
p_in_reg_shadow     : in    TRegShadow;
p_out_reg_hold      : out   TRegHold;
p_out_reg_update    : out   TRegShadowUpdate;

--------------------------------------------------
--Связь с Link Layer
--------------------------------------------------
p_out_ll_ctrl       : out   std_logic_vector(C_LLCTRL_LAST_BIT downto 0);
p_in_ll_status      : in    std_logic_vector(C_LLSTAT_LAST_BIT downto 0);

p_out_ll_txd_close  : out   std_logic;                    --//
p_out_ll_txd        : out   std_logic_vector(31 downto 0);--//
p_in_ll_txd_rd      : in    std_logic;                    --//
p_out_ll_txd_status : out   TTxBufStatus;                 --//Структуры см. sata_pkg.vhd/поле - Типы

p_in_ll_rxd         : in    std_logic_vector(31 downto 0);--//
p_in_ll_rxd_wr      : in    std_logic;                    --//
p_out_ll_rxd_status : out   TRxBufStatus;                 --//Структуры см. sata_pkg.vhd/поле - Типы

--------------------------------------------------
--Связь с PHY Layer
--------------------------------------------------
--p_in_pl_ctrl        : in    std_logic_vector(C_PLCTRL_LAST_BIT downto 0);
p_in_pl_status      : in    std_logic_vector(C_PLSTAT_LAST_BIT downto 0);

--------------------------------------------------
--Технологические сигналы
--------------------------------------------------
p_in_tst            : in    std_logic_vector(31 downto 0);
p_out_tst           : out   std_logic_vector(31 downto 0);
p_out_dbg           : out   TTL_dbgport;

--------------------------------------------------
--System
--------------------------------------------------
p_in_clk            : in    std_logic;
p_in_rst            : in    std_logic
);
end sata_tlayer;

architecture behavioral of sata_tlayer is

constant CI_SECTOR_SIZE_BYTE   : integer:=selval(C_SECTOR_SIZE_BYTE, C_SIM_SECTOR_SIZE_DWORD*4, strcmp(G_SIM, "OFF"));
constant CI_FR_DWORD_COUNT_MAX : integer:=selval(C_FR_DWORD_COUNT_MAX, C_SIM_FR_DWORD_COUNT_MAX, strcmp(G_SIM, "OFF"));

signal fsm_tlayer_cs               : TTL_fsm_state;

signal i_scount                    : std_logic_vector(15 downto 0);
signal i_scount_byte               : std_logic_vector(i_scount'length + log2(CI_SECTOR_SIZE_BYTE)-1 downto 0);

signal i_reg_hold                  : TRegHold;
signal i_reg_update                : TRegShadowUpdate;
signal i_reg_fpdma                 : TRegFPDMASetup;

signal i_ll_ctrl                   : std_logic_vector(C_LLCTRL_LAST_BIT downto 0);--//Управление для Link Layer
signal i_ll_state_illegal          : std_logic;                                   --//Ошибки при переходе из одного состояния в другое
                                                                                  --//автомата управления LInk Layer
signal i_tl_status                 : std_logic_vector(C_TLSTAT_LAST_BIT downto 0);--//Статусы Transport Layer

signal i_fdir_bit                  : std_logic;--//Прием/Передача FISDATA
signal i_fpiosetup                 : std_logic;--//Сигнализация о приеме FIS_PIOSETUP
signal i_fdone                     : std_logic;--//
signal i_fdata_tx_en               : std_logic;--//Передача FISDATA
signal i_fdata_txd_en              : std_logic;--//0/1 - FISDATA(header)/FISDATA(data)
signal i_fdata_close               : std_logic;--//Закрыть FISDATA
signal i_fdcnt                     : std_logic_vector(3 downto 0);--//Счетчик dword send/rcv FIS
signal i_fh2d                      : std_logic_vector(31 downto 0);--//Регистр выдачи FIS_HOST2DEV
signal i_fh2d_close                : std_logic;                    --//Закрыть FIS_HOST2DEV
signal i_fh2d_tx_en                : std_logic;                    --//Сигнализирует что идет передача FIS_HOST2DEV
signal i_fauto_activate_bit        : std_logic;
--signal i_fdmasetup_tx_en           : std_logic;                    --//Сигнализирует что идет передача FIS_DMASETUP
--signal i_fbist_pattern             : std_logic_vector(7 downto 0);
--signal i_fbist_rxd                 : std_logic_vector(31 downto 0);

signal i_trn_err_cnt               : std_logic_vector(1 downto 0);--//Сколько раз Link Layer сигнализировал о TxERR_CRC при повторной попытке отправить FIS_HOST2DEV
signal i_trn_repeat                : std_logic;                   --//Повтор отправки FIS_HOST2DEV.

signal i_dma_trncount_byte         : std_logic_vector(31 downto 0);
signal i_dma_trncount_dw           : std_logic_vector(31 downto 0);--//Размер транзакции(DWORD) режим DMA
signal i_dma_txd                   : std_logic;                    --//Сигнализирует что идет передача в режиме DMA
signal i_dma_dcnt                  : std_logic_vector(31 downto 0);--//Счетчик dword в режиме DMA

signal i_piosetup_trncount_byte   : std_logic_vector(15 downto 0);--//Размер транзакции(BYTE) режим PIO
signal i_piosetup_trncount_dw     : std_logic_vector(15 downto 0);--//Размер транзакции(DWORD) режим PIO

signal i_rxd_en                    : std_logic;--//Разрешение выдачи данных в порт p_out_rxfifo_wd
signal i_rxd_err                   : std_logic;
type TDlySrD is array (0 to 0) of std_logic_vector(31 downto 0);
signal sr_llrxd                    : TDlySrD;                 --//Линия задержки данных/разрешения данных с порта p_in_ll_rxd/p_in_ll_rxd_wr
signal sr_llrxd_en                 : std_logic_vector(0 to 0);
signal sr_ll_status_rcv_done       : std_logic;

signal i_txfifo_pfull              : std_logic;



--MAIN
begin

--//----------------------------------
--//Технологические сигналы
--//----------------------------------
gen_dbg_off : if strcmp(G_DBG,"OFF") generate
p_out_tst(31 downto 0)<=(others=>'0');
end generate gen_dbg_off;

gen_dbg_on : if strcmp(G_DBG,"ON") generate

p_out_tst(31 downto 0)<=(others=>'0');
--tstout:process(p_in_rst,p_in_clk)
--begin
--  if p_in_rst='1' then
--    p_out_tst(0 downto 0)<=(others=>'0');
--  elsif p_in_clk'event and p_in_clk='1' then
----    p_out_tst(0)<='0';
--  end if;
--end process tstout;
--p_out_tst(31 downto 1)<=(others=>'0');

end generate gen_dbg_on;



--------------------------------------------------
--Связь с USRAPP Layer
--------------------------------------------------
p_out_txfifo_rd<=p_in_ll_txd_rd and i_fdata_tx_en and not i_fdata_close;

p_out_rxfifo_din<=p_in_ll_rxd;
p_out_rxfifo_wd<=p_in_ll_rxd_wr and i_rxd_en;


--------------------------------------------------
--Связь с Application Layer
--------------------------------------------------
p_out_tl_status<=i_tl_status;

p_out_reg_hold<=i_reg_hold;
p_out_reg_update<=i_reg_update;
p_out_reg_fpdma<=i_reg_fpdma;


--------------------------------------------------
--Связь с Link Layer
--------------------------------------------------
p_out_ll_ctrl<=i_ll_ctrl;--//Управление LINK уровнем

--//Моделирование:
gen_bufstatus_sim_on : if strcmp(G_SIM,"ON") generate
p_out_ll_rxd_status.pfull<=p_in_rxfifo_status.wrcount(1);
end generate gen_bufstatus_sim_on;
--//Рабочий вариант:
gen_bufstatus_off : if strcmp(G_SIM,"OFF") generate
--//Один разряд fifo_status.xxcount = 256/16 + зависит от глубины самого FIFO
p_out_ll_rxd_status.pfull<=    p_in_rxfifo_status.wrcount(3) and not p_in_rxfifo_status.wrcount(2) and
                           not p_in_rxfifo_status.wrcount(1) and     p_in_rxfifo_status.wrcount(0);
end generate gen_bufstatus_off;

p_out_ll_rxd_status.full<=p_in_rxfifo_status.full;
p_out_ll_rxd_status.empty<=not OR_reduce(p_in_rxfifo_status.wrcount);
p_out_ll_rxd_status.wrcount<=p_in_rxfifo_status.wrcount;

p_out_ll_txd_status.full<=p_in_txfifo_status.pfull;
p_out_ll_txd_status.pfull<=i_txfifo_pfull;
p_out_ll_txd_status.aempty<=p_in_txfifo_status.aempty and not(i_fh2d_tx_en);
p_out_ll_txd_status.empty <=p_in_txfifo_status.empty  and not(i_fh2d_tx_en);
p_out_ll_txd_status.rdcount<=p_in_txfifo_status.rdcount;
--p_out_ll_txd_status.wrcount<=p_in_txfifo_status.wrcount;

i_txfifo_pfull<=OR_reduce(p_in_txfifo_status.rdcount);

p_out_ll_txd <=p_in_txfifo_dout when i_fdata_txd_en='1' else i_fh2d;

p_out_ll_txd_close <=i_fh2d_close or i_fdata_close;

i_fdata_close<='1' when ( i_fpiosetup='1' and i_fdata_txd_en='1' and i_dma_dcnt=EXT(i_piosetup_trncount_dw, i_dma_dcnt'length) ) or
                        ( i_dma_txd='1'   and i_fdata_txd_en='1' and (i_dma_dcnt=i_dma_trncount_dw or OR_reduce(i_dma_dcnt(log2(CI_FR_DWORD_COUNT_MAX)-1 downto 0))='0') ) else
               '0';

--//-----------------------------
--//Инициализация
--//-----------------------------
--//Размер транзакции в режиме PIO
i_piosetup_trncount_byte<=i_reg_hold.tsf_count;
i_piosetup_trncount_dw<="00"&i_piosetup_trncount_byte(15 downto 2);

--//Размер транзакции в режиме DMA
i_scount<=p_in_reg_shadow.scount_exp&p_in_reg_shadow.scount;
i_scount_byte<=i_scount&CONV_STD_LOGIC_VECTOR(0, log2(CI_SECTOR_SIZE_BYTE));

i_dma_trncount_byte<=EXT(i_scount_byte, i_dma_trncount_byte'length);
i_dma_trncount_dw<="00"&i_dma_trncount_byte(31 downto 2);

i_ll_state_illegal<=not p_in_pl_status(C_PSTAT_DET_ESTABLISH_ON_BIT) or
                        p_in_ll_status(C_LSTAT_RxERR_IDLE) or
                        p_in_ll_status(C_LSTAT_RxERR_ABORT) or
                        p_in_ll_status(C_LSTAT_TxERR_IDLE) or
                        p_in_ll_status(C_LSTAT_TxERR_ABORT) ;



--//-----------------------------
--//Линии задержек
--//-----------------------------
lsr_ll : process(p_in_clk)
begin
  if p_in_clk'event and p_in_clk='1' then
    sr_llrxd(0)<=p_in_ll_rxd;
    sr_llrxd_en(0)<=p_in_ll_rxd_wr;
    sr_ll_status_rcv_done<=p_in_ll_status(C_LSTAT_RxOK) or p_in_ll_status(C_LSTAT_RxERR_CRC);
  end if;
end process lsr_ll;

process(p_in_rst,p_in_clk)
begin
  if p_in_rst='1' then
    i_dma_dcnt<=(others=>'0');
  elsif p_in_clk'event and p_in_clk='1' then
    if i_ll_state_illegal='1' or fsm_tlayer_cs=S_HT_DMAEnd or fsm_tlayer_cs=S_HT_PIOEnd then
      i_dma_dcnt<=(others=>'0');
    elsif p_in_ll_txd_rd='1' and i_fdata_tx_en='1' and i_fdata_close='0' and (i_dma_txd='1' or i_fpiosetup='1') then
      i_dma_dcnt<=i_dma_dcnt + 1;
    end if;
  end if;
end process;

--//#########################################
--//Transport Layer - Автомат управления
--//Реализует управление согласно спецификации SATA
--//(см. пп 10.4 Serial ATA Specification v2.5 (2005-10-27).pdf)
--//#########################################
lfsm : process(p_in_rst,p_in_clk)
begin

if p_in_rst='1' then

  fsm_tlayer_cs<= S_IDLE;

  i_ll_ctrl<=(others=>'0');
  i_tl_status<=(others=>'0');

  i_fdir_bit<='0';
  i_fpiosetup<='0';
  i_fdone<='0';
  i_fdata_tx_en<='0';
  i_fdata_txd_en<='0';
  i_fh2d<=(others=>'0');
  i_fh2d_close<='0';
  i_fh2d_tx_en<='0';
  i_fdcnt<=(others=>'0');
  i_fauto_activate_bit<='0';
--  i_fdmasetup_tx_en<='0';
--  i_fbist_pattern<=(others=>'0');
--  i_fbist_rxd<=(others=>'0');

--  i_dma_dcnt<=(others=>'0');
  i_dma_txd<='0';

  i_reg_fpdma.dir<='0';
  i_reg_fpdma.addr<=(others=>'0');
  i_reg_fpdma.offset<=(others=>'0');
  i_reg_fpdma.trncount_byte<=(others=>'0');

  i_reg_hold.device<=(others=>'0');
  i_reg_hold.status<=(others=>'0');
  i_reg_hold.error<=(others=>'0');
  i_reg_hold.lba_low<=(others=>'0');
  i_reg_hold.lba_low_exp<=(others=>'0');
  i_reg_hold.lba_mid<=(others=>'0');
  i_reg_hold.lba_mid_exp<=(others=>'0');
  i_reg_hold.lba_high<=(others=>'0');
  i_reg_hold.lba_high_exp<=(others=>'0');
  i_reg_hold.scount<=(others=>'0');
  i_reg_hold.scount_exp<=(others=>'0');
  i_reg_hold.e_status<=(others=>'0');
  i_reg_hold.tsf_count<=(others=>'0');
  i_reg_hold.sb_error<=(others=>'0');
  i_reg_hold.sb_status<=(others=>'0');

  i_reg_update.fd2h<='0';
  i_reg_update.fpio<='0';
  i_reg_update.fpio_e<='0';
  i_reg_update.fsdb<='0';

  i_rxd_en<='0';
  i_rxd_err<='0';

  i_trn_err_cnt<=(others=>'0');
  i_trn_repeat<='0';

elsif p_in_clk'event and p_in_clk='1' then

  case fsm_tlayer_cs is

    --$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
    --//Transport IDLE states
    --$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
    when S_IDLE =>

      i_reg_update.fd2h<='0';
      i_reg_update.fpio<='0';
      i_reg_update.fpio_e<='0';
      i_reg_update.fsdb<='0';

      i_tl_status(C_TSTAT_TxERR_CRC_REPEAT_BIT)<='0';
      i_tl_status(C_TSTAT_RxFISTYPE_ERR_BIT)<='0';
      i_tl_status(C_TSTAT_RxFISLEN_ERR_BIT)<='0';

      i_ll_ctrl(C_LCTRL_TL_CHECK_ERR_BIT)<='0';
      i_ll_ctrl(C_LCTRL_TL_CHECK_DONE_BIT)<='0';

      i_fdata_txd_en<='0';
      i_fdata_tx_en<='0';
      i_fdone<='0';

      if p_in_ll_status(C_LSTAT_RxSTART)='1' then
      --//Link Layer сигнализирует о начале прием данных от SATA устройста
        i_tl_status(C_TSTAT_TxFISHOST2DEV_BIT)<='0';

        i_fh2d_tx_en<='0';
--        i_fdmasetup_tx_en<='0';
        fsm_tlayer_cs <= S_HT_ChkTyp;

      elsif i_fpiosetup='1' and i_fdir_bit=C_DIR_H2D then
        i_tl_status(C_TSTAT_TxFISHOST2DEV_BIT)<='0';

        i_fh2d_tx_en<='0';
--        i_fdmasetup_tx_en<='0';
        if i_txfifo_pfull='1' then
        --//Ждем когда в TxBUF накопятся данные для предачи
          i_ll_ctrl(C_LCTRL_TxSTART_BIT)<='1';
          i_tl_status(C_TSTAT_FSMTxD_ON_BIT)<='1';
          fsm_tlayer_cs <= S_HT_PIOOTrans2;
        end if;

      elsif p_in_tl_ctrl(C_TCTRL_RCOMMAND_WR_BIT)='1' or i_trn_repeat='1' then
      --//FIS_REG_HOST2DEV : Передача  - ATA command
        if p_in_tl_ctrl(C_TCTRL_RCOMMAND_WR_BIT)='1' then
          i_trn_err_cnt<=(others=>'0');
        end if;

        i_ll_ctrl(C_LCTRL_TxSTART_BIT)<='1';
        i_tl_status(C_TSTAT_TxFISHOST2DEV_BIT)<='1';

        i_fh2d_tx_en<='1';
--        i_fdmasetup_tx_en<='0';
        fsm_tlayer_cs <= S_HT_CmdFIS;

      elsif p_in_tl_ctrl(C_TCTRL_RCONTROL_WR_BIT)='1' or i_trn_repeat='1' then
      --//FIS_REG_HOST2DEV : Передача  - ATA control
        if p_in_tl_ctrl(C_TCTRL_RCONTROL_WR_BIT)='1' then
          i_trn_err_cnt<=(others=>'0');
        end if;

        i_ll_ctrl(C_LCTRL_TxSTART_BIT)<='1';
        i_tl_status(C_TSTAT_TxFISHOST2DEV_BIT)<='1';

        i_fh2d_tx_en<='1';
--        i_fdmasetup_tx_en<='0';
        fsm_tlayer_cs <= S_HT_CtrlFIS;

--      elsif p_in_tl_ctrl(C_TCTRL_DMASETUP_WR_BIT)='1' then
--      --//FIS_DMA_SETUP : Передача
--        i_ll_ctrl(C_LCTRL_TxSTART_BIT)<='1';
--        i_fdmasetup_tx_en<='1';
--        fsm_tlayer_cs <= S_HT_DmaSetupFIS;

      else
        i_tl_status(C_TSTAT_TxFISHOST2DEV_BIT)<='0';

        i_fh2d_tx_en<='0';
--        i_fdmasetup_tx_en<='0';

      end if;

    --//------------------------------------------
    --//Прием данных: Проверка FIS Type
    --//------------------------------------------
    when S_HT_ChkTyp =>

      if i_ll_state_illegal='1' then
        fsm_tlayer_cs <= S_IDLE;

      else

        if i_ll_ctrl(C_LCTRL_TL_CHECK_ERR_BIT)='1' then
            --//Тип принимаемого FIS не определен.
            --//Ждем завершения приема данных
            if sr_ll_status_rcv_done='1' then--if p_in_ll_status(C_LSTAT_RxOK)='1' or p_in_ll_status(C_LSTAT_RxERR_CRC)='1' then

                i_tl_status(C_TSTAT_RxFISTYPE_ERR_BIT)<='1';
                i_ll_ctrl(C_LCTRL_TL_CHECK_DONE_BIT)<='1';--//Сигнал Link уровню отправить примитив подтверждения R_ERR/R_OK
                fsm_tlayer_cs <= S_IDLE;

            end if;

        else
          --//Анализируем тип принимаемого FIS
          if p_in_ll_rxd_wr='1' then

              if p_in_ll_rxd(7 downto 0)=CONV_STD_LOGIC_VECTOR(C_FIS_REG_DEV2HOST, 8) then
                  fsm_tlayer_cs <= S_HT_RegFIS;

              elsif p_in_ll_rxd(7 downto 0)=CONV_STD_LOGIC_VECTOR(C_FIS_PIOSETUP, 8) then
                  fsm_tlayer_cs <= S_HT_PS_FIS;

              elsif p_in_ll_rxd(7 downto 0)=CONV_STD_LOGIC_VECTOR(C_FIS_DMA_ACTIVATE, 8) then
                  i_fdir_bit<=C_DIR_H2D;
                  i_fdcnt<=i_fdcnt + 1;
                  fsm_tlayer_cs <= S_HT_DMA_FIS;

              elsif p_in_ll_rxd(7 downto 0)=CONV_STD_LOGIC_VECTOR(C_FIS_DATA, 8) then
                  i_rxd_en<='1';

                  if i_fpiosetup='1' and i_fdir_bit=C_DIR_D2H then
                  --//Прием данных в режиме PIO
                    i_tl_status(C_TSTAT_FSMRxD_ON_BIT)<='1';
                    fsm_tlayer_cs <= S_HT_PIOITrans1;

                  else
                  --//Прием данных в режиме DMA
                    i_fdir_bit<=C_DIR_D2H;
                    i_tl_status(C_TSTAT_FSMRxD_ON_BIT)<='1';
                    fsm_tlayer_cs <= S_HT_DMAITrans;

                  end if;

              elsif p_in_ll_rxd(7 downto 0)=CONV_STD_LOGIC_VECTOR(C_FIS_DMASETUP, 8) then
                  fsm_tlayer_cs <= S_HT_DS_FIS;

              elsif p_in_ll_rxd(7 downto 0)=CONV_STD_LOGIC_VECTOR(C_FIS_SET_DEV_BITS, 8) then
                  fsm_tlayer_cs <= S_HT_DB_FIS;

              elsif p_in_ll_rxd(7 downto 0)=CONV_STD_LOGIC_VECTOR(C_FIS_BIST_ACTIVATE, 8) then
                  fsm_tlayer_cs <= S_HT_RcvBIST;

              else
                --//Не один из типов FIS не распознан!!!
                i_ll_ctrl(C_LCTRL_TL_CHECK_ERR_BIT)<='1';

              end if;

           end if;

        end if;--//if p_in_ll_rxd_wr='1' then
      end if;--//if i_ll_state_illegal


    --//-------------------------------------------
    --//FIS_REG_HOST2DEV: Передача ATA command
    --//-------------------------------------------
    when S_HT_CmdFIS =>

      if i_ll_state_illegal='1' then
        i_ll_ctrl(C_LCTRL_TxSTART_BIT)<='0';
        fsm_tlayer_cs <= S_IDLE;

      else

        if p_in_ll_txd_rd='1' then
            i_ll_ctrl(C_LCTRL_TxSTART_BIT)<='0';

            if i_fdcnt(2 downto 0)=CONV_STD_LOGIC_VECTOR(10#00#, 3) then
              i_fh2d(8*(0+1)-1 downto 8*0)<=CONV_STD_LOGIC_VECTOR(C_FIS_REG_HOST2DEV, 8);

              i_fh2d(8*1+3 downto 8*1+0)<=(others=>'0');--//PM Port
              i_fh2d(8*1+4)<='0';--//Reseved
              i_fh2d(8*1+5)<='0';--//Reseved
              i_fh2d(8*1+6)<='0';--//Reseved
              i_fh2d(8*1+7)<='1';--//C-bit=1 - Обновление Command Register

              i_fh2d(8*(2+1)-1 downto 8*2)<=p_in_reg_shadow.command;
              i_fh2d(8*(3+1)-1 downto 8*3)<=p_in_reg_shadow.feature;

            elsif i_fdcnt(2 downto 0)=CONV_STD_LOGIC_VECTOR(10#01#, 3) then
              i_fh2d(8*(0+1)-1 downto 8*0)<=p_in_reg_shadow.lba_low(7 downto 0);
              i_fh2d(8*(1+1)-1 downto 8*1)<=p_in_reg_shadow.lba_mid(7 downto 0);
              i_fh2d(8*(2+1)-1 downto 8*2)<=p_in_reg_shadow.lba_high(7 downto 0);
              i_fh2d(8*(3+1)-1 downto 8*3)<=p_in_reg_shadow.device;

            elsif i_fdcnt(2 downto 0)=CONV_STD_LOGIC_VECTOR(10#02#, 3) then
              i_fh2d(8*(0+1)-1 downto 8*0)<=p_in_reg_shadow.lba_low_exp;
              i_fh2d(8*(1+1)-1 downto 8*1)<=p_in_reg_shadow.lba_mid_exp;
              i_fh2d(8*(2+1)-1 downto 8*2)<=p_in_reg_shadow.lba_high_exp;
              i_fh2d(8*(3+1)-1 downto 8*3)<=p_in_reg_shadow.feature_exp;

            elsif i_fdcnt(2 downto 0)=CONV_STD_LOGIC_VECTOR(10#03#, 3) then
              i_fh2d(8*(0+1)-1 downto 8*0)<=p_in_reg_shadow.scount;
              i_fh2d(8*(1+1)-1 downto 8*1)<=p_in_reg_shadow.scount_exp;
              i_fh2d(8*(2+1)-1 downto 8*2)<=(others=>'0');
              i_fh2d(8*(3+1)-1 downto 8*3)<=p_in_reg_shadow.control;

            elsif i_fdcnt(2 downto 0)=CONV_STD_LOGIC_VECTOR(10#04#, 3) then
              i_fh2d<=(others=>'0');

            end if;

            if i_fdcnt(2 downto 0)=CONV_STD_LOGIC_VECTOR(C_FIS_REG_HOST2DEV_DWSIZE-1, 3) then
            --//Передал все данные
              i_fh2d_close<='1';
              i_fdcnt<=(others=>'0');
              fsm_tlayer_cs <= S_HT_CmdTransStatus;

            else
              i_fdcnt<=i_fdcnt + 1;
            end if;

        end if;

      end if;--//if i_ll_state_illegal='1' then

    --//------------------------------------------
    --//FIS_REG_HOST2DEV: Передача ATA command
    --//------------------------------------------
    when S_HT_CmdTransStatus =>

      if i_ll_state_illegal='1' then
        i_fh2d_close<='0';
        fsm_tlayer_cs <= S_IDLE;

      else
          if p_in_ll_txd_rd='1' then
            i_fh2d_close<='0';
          end if;

          if p_in_ll_status(C_LSTAT_TxERR_CRC)='1' then

            if i_trn_err_cnt=(i_trn_err_cnt'range => '1') then
              i_trn_repeat<='0';
              i_tl_status(C_TSTAT_TxERR_CRC_REPEAT_BIT)<='1';
            else
              i_trn_err_cnt<=i_trn_err_cnt + 1;
              i_trn_repeat<='1';
            end if;

            fsm_tlayer_cs <= S_IDLE;

          elsif p_in_ll_status(C_LSTAT_TxOK)='1' then

            i_trn_err_cnt<=(others=>'0');
            i_trn_repeat<='0';
            fsm_tlayer_cs <= S_IDLE;

          end if;

      end if;--//if i_ll_state_illegal='1' then


    --//-------------------------------------------
    --//FIS_REG_HOST2DEV: Передача ATA Control
    --//-------------------------------------------
    when S_HT_CtrlFIS =>

      if i_ll_state_illegal='1' then
        i_ll_ctrl(C_LCTRL_TxSTART_BIT)<='0';
        fsm_tlayer_cs <= S_IDLE;

      else

        if p_in_ll_txd_rd='1' then
            i_ll_ctrl(C_LCTRL_TxSTART_BIT)<='0';

            if i_fdcnt(2 downto 0)=CONV_STD_LOGIC_VECTOR(10#00#, 3) then
              i_fh2d(8*(0+1)-1 downto 8*0)<=CONV_STD_LOGIC_VECTOR(C_FIS_REG_HOST2DEV, 8);

              i_fh2d(8*1+3 downto 8*1+0)<=(others=>'0');--//PM Port
              i_fh2d(8*1+4)<='0';--//Reseved
              i_fh2d(8*1+5)<='0';--//Reseved
              i_fh2d(8*1+6)<='0';--//Reseved
              i_fh2d(8*1+7)<='0';--//C-bit=0 - Обновление Device Control Register

              i_fh2d(8*(2+1)-1 downto 8*2)<=p_in_reg_shadow.command;
              i_fh2d(8*(3+1)-1 downto 8*3)<=p_in_reg_shadow.feature;

            elsif i_fdcnt(2 downto 0)=CONV_STD_LOGIC_VECTOR(10#01#, 3) then
              i_fh2d(8*(0+1)-1 downto 8*0)<=p_in_reg_shadow.lba_low(7 downto 0);
              i_fh2d(8*(1+1)-1 downto 8*1)<=p_in_reg_shadow.lba_mid(7 downto 0);
              i_fh2d(8*(2+1)-1 downto 8*2)<=p_in_reg_shadow.lba_high(7 downto 0);
              i_fh2d(8*(3+1)-1 downto 8*3)<=p_in_reg_shadow.device;

            elsif i_fdcnt(2 downto 0)=CONV_STD_LOGIC_VECTOR(10#02#, 3) then
              i_fh2d(8*(0+1)-1 downto 8*0)<=p_in_reg_shadow.lba_low_exp;
              i_fh2d(8*(1+1)-1 downto 8*1)<=p_in_reg_shadow.lba_mid_exp;
              i_fh2d(8*(2+1)-1 downto 8*2)<=p_in_reg_shadow.lba_high_exp;
              i_fh2d(8*(3+1)-1 downto 8*3)<=p_in_reg_shadow.feature_exp;

            elsif i_fdcnt(2 downto 0)=CONV_STD_LOGIC_VECTOR(10#03#, 3) then
              i_fh2d(8*(0+1)-1 downto 8*0)<=p_in_reg_shadow.scount;
              i_fh2d(8*(1+1)-1 downto 8*1)<=p_in_reg_shadow.scount_exp;
              i_fh2d(8*(2+1)-1 downto 8*2)<=(others=>'0');
              i_fh2d(8*(3+1)-1 downto 8*3)<=p_in_reg_shadow.control;

            elsif i_fdcnt(2 downto 0)=CONV_STD_LOGIC_VECTOR(10#04#, 3) then
              i_fh2d<=(others=>'0');

            end if;

            if i_fdcnt(2 downto 0)=CONV_STD_LOGIC_VECTOR(C_FIS_REG_HOST2DEV_DWSIZE-1, 3) then
            --//Передал все данные
              i_fh2d_close<='1';
              i_fdcnt<=(others=>'0');
              fsm_tlayer_cs <= S_HT_CtrlTransStatus;

            else
              i_fdcnt<=i_fdcnt + 1;
            end if;

        end if;

      end if;--//if i_ll_state_illegal='1' then

    --//------------------------------------------
    --//FIS_REG_HOST2DEV: Передача ATA Control
    --//------------------------------------------
    when S_HT_CtrlTransStatus =>

      if i_ll_state_illegal='1' then
        i_fh2d_close<='0';
        fsm_tlayer_cs <= S_IDLE;

      else
          if p_in_ll_txd_rd='1' then
            i_fh2d_close<='0';
          end if;

          if p_in_ll_status(C_LSTAT_TxERR_CRC)='1' then

            if i_trn_err_cnt=(i_trn_err_cnt'range => '1') then
              i_trn_repeat<='0';
              i_tl_status(C_TSTAT_TxERR_CRC_REPEAT_BIT)<='1';
            else
              i_trn_err_cnt<=i_trn_err_cnt + 1;
              i_trn_repeat<='1';
            end if;

            fsm_tlayer_cs <= S_IDLE;

          elsif p_in_ll_status(C_LSTAT_TxOK)='1' then

            i_trn_err_cnt<=(others=>'0');
            i_trn_repeat<='0';
            fsm_tlayer_cs <= S_IDLE;

          end if;

      end if;--//if i_ll_state_illegal='1' then


    --//------------------------------------------
    --//FIS_REG_DEV2HOST: прием данных
    --//------------------------------------------
    when S_HT_RegFIS =>

      if i_ll_state_illegal='1' then
        i_fdcnt<=(others=>'0');
        fsm_tlayer_cs <= S_IDLE;

      else

        if sr_ll_status_rcv_done='1' then--if p_in_ll_status(C_LSTAT_RxOK)='1' or p_in_ll_status(C_LSTAT_RxERR_CRC)='1' then
        --//Прием данных завершен
            if i_fdcnt(2 downto 0)/=CONV_STD_LOGIC_VECTOR(C_FIS_REG_DEV2HOST_DWSIZE, 3) then
              i_ll_ctrl(C_LCTRL_TL_CHECK_ERR_BIT)<='1';
            end if;

            i_fdcnt<=(others=>'0');
            fsm_tlayer_cs <= S_HT_RegTransStatus;

        elsif sr_llrxd_en(0)='1' then
        --//Прием содержимого FIS

            if i_fdcnt(2 downto 0)=CONV_STD_LOGIC_VECTOR(10#00#, 3) then
              i_fdir_bit<=sr_llrxd(0)(C_FIS_DIR_BIT+8);
              i_tl_status(C_TSTAT_FIS_I_BIT)<=sr_llrxd(0)(C_FIS_INT_BIT+8);

              i_reg_hold.status <= sr_llrxd(0)(8*(2+1)-1 downto 8*2);
              i_reg_hold.error <= sr_llrxd(0)(8*(3+1)-1 downto 8*3);

            elsif i_fdcnt(2 downto 0)=CONV_STD_LOGIC_VECTOR(10#01#, 3) then
              i_reg_hold.lba_low <= sr_llrxd(0)(8*(0+1)-1 downto 8*0);
              i_reg_hold.lba_mid <= sr_llrxd(0)(8*(1+1)-1 downto 8*1);
              i_reg_hold.lba_high <= sr_llrxd(0)(8*(2+1)-1 downto 8*2);
              i_reg_hold.device <= sr_llrxd(0)(8*(3+1)-1 downto 8*3);

            elsif i_fdcnt(2 downto 0)=CONV_STD_LOGIC_VECTOR(10#02#, 3) then
              i_reg_hold.lba_low_exp <= sr_llrxd(0)(8*(0+1)-1 downto 8*0);
              i_reg_hold.lba_mid_exp <= sr_llrxd(0)(8*(1+1)-1 downto 8*1);
              i_reg_hold.lba_high_exp <= sr_llrxd(0)(8*(2+1)-1 downto 8*2);

            elsif i_fdcnt(2 downto 0)=CONV_STD_LOGIC_VECTOR(10#03#, 3) then
              i_reg_hold.scount <= sr_llrxd(0)(8*(0+1)-1 downto 8*0);
              i_reg_hold.scount_exp <= sr_llrxd(0)(8*(1+1)-1 downto 8*1);
              i_reg_hold.e_status <= sr_llrxd(0)(8*(3+1)-1 downto 8*3);

            elsif i_fdcnt(2 downto 0)=CONV_STD_LOGIC_VECTOR(10#04#, 3) then
              i_reg_hold.tsf_count(7 downto 0) <= sr_llrxd(0)(8*(0+1)-1 downto 8*0);
              i_reg_hold.tsf_count(15 downto 8) <= sr_llrxd(0)(8*(1+1)-1 downto 8*1);

            end if;

            i_fdcnt<=i_fdcnt + 1;

        end if;--//if sr_llrxd_en(0)='1' then
      end if;--//if i_ll_state_illegal

    --//------------------------------------------
    --//FIS_REG_DEV2HOST: завершение обработки
    --//------------------------------------------
    when S_HT_RegTransStatus =>

      if i_ll_state_illegal='1' then
        fsm_tlayer_cs <= S_IDLE;

      else

          if p_in_ll_status(C_LSTAT_RxOK)='1' then
          --//CRC - OK!
            if i_ll_ctrl(C_LCTRL_TL_CHECK_ERR_BIT)='1' then
            --//FIS Length - ERROR!
              i_tl_status(C_TSTAT_RxFISLEN_ERR_BIT)<='1';
            else
              i_reg_update.fd2h<='1';
--              i_dma_dcnt<=(others=>'0');
            end if;

            i_ll_ctrl(C_LCTRL_TL_CHECK_DONE_BIT)<='1';--//Сигнал Link уровню отправить примитив подтверждения R_ERR/R_OK

          end if;

          fsm_tlayer_cs <= S_IDLE;

      end if;--//if i_ll_state_illegal


    --//------------------------------------------
    --//FIS_SET_DEVICE_BITS: прием данных
    --//------------------------------------------
    when S_HT_DB_FIS =>

      if i_ll_state_illegal='1' then
        i_fdcnt<=(others=>'0');
        fsm_tlayer_cs <= S_IDLE;

      else

        if sr_ll_status_rcv_done='1' then--if p_in_ll_status(C_LSTAT_RxOK)='1' or p_in_ll_status(C_LSTAT_RxERR_CRC)='1' then
        --//Прием данных завершен
            if i_fdcnt(2 downto 0)/=CONV_STD_LOGIC_VECTOR(C_FIS_SET_DEV_BITS_DWSIZE, 3) then
              i_ll_ctrl(C_LCTRL_TL_CHECK_ERR_BIT)<='1';
            end if;

            i_fdcnt<=(others=>'0');
            fsm_tlayer_cs <= S_HT_Dev_Bits;

        elsif sr_llrxd_en(0)='1' then
        --//Прием содержимого FIS

            if i_fdcnt(2 downto 0)=CONV_STD_LOGIC_VECTOR(10#00#, 3) then
              i_tl_status(C_TSTAT_FIS_I_BIT)<=sr_llrxd(0)(C_FIS_INT_BIT+8);

              i_reg_hold.sb_status <= sr_llrxd(0)(8*(2+1)-1 downto 8*2);
              i_reg_hold.sb_error <= sr_llrxd(0)(8*(3+1)-1 downto 8*3);

            end if;

            i_fdcnt<=i_fdcnt + 1;

        end if;--//if sr_llrxd_en(0)='1' then
      end if;--//if i_ll_state_illegal

    --//------------------------------------------
    --//FIS_SET_DEVICE_BITS: завершение обработки
    --//------------------------------------------
    when S_HT_Dev_Bits =>

      if i_ll_state_illegal='1' then
        fsm_tlayer_cs <= S_IDLE;

      else

          if p_in_ll_status(C_LSTAT_RxOK)='1' then
          --//CRC - OK!
            if i_ll_ctrl(C_LCTRL_TL_CHECK_ERR_BIT)='1' then
            --//FIS Length - ERROR!
              i_tl_status(C_TSTAT_RxFISLEN_ERR_BIT)<='1';
            else
              i_reg_update.fsdb<='1';
            end if;

            i_ll_ctrl(C_LCTRL_TL_CHECK_DONE_BIT)<='1';--//Сигнал Link уровню отправить примитив подтверждения R_ERR/R_OK

          end if;

          fsm_tlayer_cs <= S_IDLE;

      end if;--//if i_ll_state_illegal


    --//------------------------------------------
    --//FIS_BIST_ACTIVATE: прием данных
    --//------------------------------------------
    when S_HT_RcvBIST =>

      if i_ll_state_illegal='1' then
        i_fdcnt<=(others=>'0');
        fsm_tlayer_cs <= S_IDLE;

      else

        if sr_ll_status_rcv_done='1' then--if p_in_ll_status(C_LSTAT_RxOK)='1' or p_in_ll_status(C_LSTAT_RxERR_CRC)='1' then
        --//Прием данных завершен
            if i_fdcnt(2 downto 0)/=CONV_STD_LOGIC_VECTOR(C_FIS_BIST_ACTIVATE_DWSIZE, 3) then
              i_ll_ctrl(C_LCTRL_TL_CHECK_ERR_BIT)<='1';
            end if;

            i_fdcnt<=(others=>'0');
            fsm_tlayer_cs <= S_HT_BISTTrans1;

        elsif sr_llrxd_en(0)='1' then
        --//Прием содержимого FIS

--            if i_fdcnt(2 downto 0)=CONV_STD_LOGIC_VECTOR(10#00#, 3) then
--
--              i_fbist_pattern <= sr_llrxd(0)(8*(2+1)-1 downto 8*2);
--
--            elsif i_fdcnt(2 downto 0)=CONV_STD_LOGIC_VECTOR(10#01#, 3) then
--
--              i_fbist_rxd <= sr_llrxd(0)(8*(3+1)-1 downto 8*2);
--
--            elsif i_fdcnt(2 downto 0)=CONV_STD_LOGIC_VECTOR(10#03#, 3) then
--
--              i_fbist_rxd <= sr_llrxd(0)(8*(3+1)-1 downto 8*2);
--
--            end if;

            i_fdcnt<=i_fdcnt + 1;

        end if;--//if sr_llrxd_en(0)='1' then
      end if;--//if i_ll_state_illegal

    --//------------------------------------------
    --//FIS_BIST_ACTIVATE: завершение обработки
    --//------------------------------------------
    when S_HT_BISTTrans1 =>

      if i_ll_state_illegal='1' then
        fsm_tlayer_cs <= S_IDLE;

      else

          if p_in_ll_status(C_LSTAT_RxOK)='1' then
          --//CRC - OK!
            if i_ll_ctrl(C_LCTRL_TL_CHECK_ERR_BIT)='1' then
            --//FIS Length - ERROR!
              i_tl_status(C_TSTAT_RxFISLEN_ERR_BIT)<='1';
            end if;

            i_ll_ctrl(C_LCTRL_TL_CHECK_DONE_BIT)<='1';--//Сигнал Link уровню отправить примитив подтверждения R_ERR/R_OK

          end if;

          fsm_tlayer_cs <= S_IDLE;

      end if;--//if i_ll_state_illegal



    --$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
    -- //Обработчик Команд в режиме PIO
    --$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
    --//------------------------------------------
    --//Режим PIO / Прием FIS_PIOSETUP
    --//------------------------------------------
    when S_HT_PS_FIS =>

      if i_ll_state_illegal='1' then
        i_fdcnt<=(others=>'0');
        i_fpiosetup<='0';
        fsm_tlayer_cs <= S_IDLE;

      else

        if sr_ll_status_rcv_done='1' then--if p_in_ll_status(C_LSTAT_RxOK)='1' or p_in_ll_status(C_LSTAT_RxERR_CRC)='1' then
        --//Прием данных завершен
            if p_in_ll_status(C_LSTAT_RxOK)='1' then
            --//CRC - OK!
              if i_fdcnt(2 downto 0)=CONV_STD_LOGIC_VECTOR(C_FIS_PIOSETUP_DWSIZE, 3) then
              --//FIS Length - OK!
                i_fpiosetup<='1';

                if i_fdir_bit=C_DIR_H2D then
                --//Передача данных (FPGA -> HDD)
                  i_tl_status(C_TSTAT_DWR_START_BIT)<='1';
                  fsm_tlayer_cs <= S_HT_PIOOTrans1;
                else
                --//Прием данных (FPGA <- HDD)
                  fsm_tlayer_cs <= S_IDLE;
                end if;

              else
                i_ll_ctrl(C_LCTRL_TL_CHECK_ERR_BIT)<='1';
                fsm_tlayer_cs <= S_IDLE;

              end if;

              i_ll_ctrl(C_LCTRL_TL_CHECK_DONE_BIT)<='1';--//Сигнал Link уровню отправить примитив подтверждения R_ERR/R_OK

            else
              fsm_tlayer_cs <= S_IDLE;
            end if;

            i_fdcnt<=(others=>'0');

        elsif sr_llrxd_en(0)='1' then
        --//Прием содержимого FIS

            if i_fdcnt(2 downto 0)=CONV_STD_LOGIC_VECTOR(10#00#, 3) then
              i_fdir_bit<=sr_llrxd(0)(C_FIS_DIR_BIT+8);
              i_tl_status(C_TSTAT_FIS_I_BIT)<=sr_llrxd(0)(C_FIS_INT_BIT+8);

              i_reg_hold.status <= sr_llrxd(0)(8*(2+1)-1 downto 8*2);
              i_reg_hold.error <= sr_llrxd(0)(8*(3+1)-1 downto 8*3);

            elsif i_fdcnt(2 downto 0)=CONV_STD_LOGIC_VECTOR(10#01#, 3) then
              i_reg_hold.lba_low <= sr_llrxd(0)(8*(0+1)-1 downto 8*0);
              i_reg_hold.lba_mid <= sr_llrxd(0)(8*(1+1)-1 downto 8*1);
              i_reg_hold.lba_high <= sr_llrxd(0)(8*(2+1)-1 downto 8*2);
              i_reg_hold.device <= sr_llrxd(0)(8*(3+1)-1 downto 8*3);

            elsif i_fdcnt(2 downto 0)=CONV_STD_LOGIC_VECTOR(10#02#, 3) then
              i_reg_hold.lba_low_exp <= sr_llrxd(0)(8*(0+1)-1 downto 8*0);
              i_reg_hold.lba_mid_exp <= sr_llrxd(0)(8*(1+1)-1 downto 8*1);
              i_reg_hold.lba_high_exp <= sr_llrxd(0)(8*(2+1)-1 downto 8*2);

            elsif i_fdcnt(2 downto 0)=CONV_STD_LOGIC_VECTOR(10#03#, 3) then
              i_reg_hold.scount <= sr_llrxd(0)(8*(0+1)-1 downto 8*0);
              i_reg_hold.scount_exp <= sr_llrxd(0)(8*(1+1)-1 downto 8*1);
              i_reg_hold.e_status <= sr_llrxd(0)(8*(3+1)-1 downto 8*3);

            elsif i_fdcnt(2 downto 0)=CONV_STD_LOGIC_VECTOR(10#04#, 3) then
              i_reg_hold.tsf_count(7 downto 0) <= sr_llrxd(0)(8*(0+1)-1 downto 8*0);
              i_reg_hold.tsf_count(15 downto 8) <= sr_llrxd(0)(8*(1+1)-1 downto 8*1);

            end if;

            i_fdcnt<=i_fdcnt + 1;

        end if;--//if sr_llrxd_en(0)='1' then

      end if;--//if i_ll_state_illegal

    --//------------------------------------------
    --//Режим PIO / Прием FIS_PIOSETUP
    --//------------------------------------------
    when S_HT_PIOOTrans1 =>

      i_tl_status(C_TSTAT_DWR_START_BIT)<='0';
      i_reg_update.fpio<='1';
      fsm_tlayer_cs <= S_IDLE;--fsm_tlayer_cs <= S_HT_PIOOTrans2;


    --//------------------------------------------
    --//Режим PIO / Передача данных (FPGA -> HDD)
    --//------------------------------------------
    when S_HT_PIOOTrans2 =>

      i_fdcnt<=(others=>'0');
      if i_ll_state_illegal='1' then
        i_ll_ctrl(C_LCTRL_TxSTART_BIT)<='0';
        i_fpiosetup<='0';
        i_tl_status(C_TSTAT_FSMTxD_ON_BIT)<='0';
        fsm_tlayer_cs <= S_IDLE;

      else
        if p_in_ll_status(C_LSTAT_TxDMAT)='1' then
        --//ABORT!!!
        --//Link Layer сигнализирует о приеме примитива DMAT
            i_ll_ctrl(C_LCTRL_TxSTART_BIT)<='0';

--            i_fdcnt<=(others=>'0');
            i_fdata_txd_en<='0';
            i_fdata_tx_en<='0';
            fsm_tlayer_cs<=S_HT_PIOEnd;

        elsif p_in_ll_txd_rd='1' then
        --//Отправка FISDATA
            i_ll_ctrl(C_LCTRL_TxSTART_BIT)<='0';

            if i_fdata_tx_en='0' then
            --//Заголовок
                i_fdata_tx_en<='1';--//Заголовок FISDATA передан
                i_fh2d<=CONV_STD_LOGIC_VECTOR(C_FIS_DATA, i_fh2d'length);

            else
            --//Данные
                if i_dma_dcnt=EXT(i_piosetup_trncount_dw, i_dma_dcnt'length) then --if i_fdcnt=EXT(i_piosetup_trncount_dw, i_fdcnt'length) then
--                  i_fdcnt<=(others=>'0');
                  i_fdata_txd_en<='0';
                  i_fdata_tx_en<='0';
                  fsm_tlayer_cs<=S_HT_PIOEnd;

                else
                  i_fdata_txd_en<='1';
--                  i_fdcnt<=i_fdcnt + 1;
                end if;
            end if;

        end if;--//if p_in_ll_txd_rd='1' then
      end if;--//if i_ll_state_illegal


    --//------------------------------------------
    --//Режим PIO / Завершение команды
    --//------------------------------------------
    when S_HT_PIOEnd =>

      if i_ll_state_illegal='1' then
        i_fpiosetup<='0';
        i_tl_status(C_TSTAT_FSMTxD_ON_BIT)<='0';
        i_tl_status(C_TSTAT_FSMRxD_ON_BIT)<='0';
        fsm_tlayer_cs <= S_IDLE;

      else

          if i_fdir_bit=C_DIR_D2H then
          --Прием данных (FPGA <- HDD)

              if i_rxd_err='0' then
                i_reg_update.fpio_e<='1';
                i_ll_ctrl(C_LCTRL_TL_CHECK_DONE_BIT)<='1';--//Сигнал Link уровню отправить примитив подтверждения R_ERR/R_OK
              end if;

              i_fpiosetup<='0';
              i_tl_status(C_TSTAT_FSMTxD_ON_BIT)<='0';
              i_tl_status(C_TSTAT_FSMRxD_ON_BIT)<='0';
              fsm_tlayer_cs <= S_IDLE;

          else
          --Передача данных (FPGA -> HDD)
              if p_in_ll_status(C_LSTAT_TxERR_CRC)='1' then

                i_fpiosetup<='0';
                i_tl_status(C_TSTAT_FSMTxD_ON_BIT)<='0';
                i_tl_status(C_TSTAT_FSMRxD_ON_BIT)<='0';
                fsm_tlayer_cs <= S_IDLE;

              elsif p_in_ll_status(C_LSTAT_TxOK)='1' then

                i_fpiosetup<='0';
                i_reg_update.fpio_e<='1';
                i_tl_status(C_TSTAT_FSMTxD_ON_BIT)<='0';
                i_tl_status(C_TSTAT_FSMRxD_ON_BIT)<='0';
                fsm_tlayer_cs <= S_IDLE;

              end if;

          end if;

      end if;--//if i_ll_state_illegal

    --//------------------------------------------
    --//Режим PIO / Прием данных (FPGA <- HDD)
    --//------------------------------------------
    when S_HT_PIOITrans1 =>

      if i_ll_state_illegal='1' then
        i_fpiosetup<='0';
        i_rxd_en<='0';
        i_tl_status(C_TSTAT_FSMRxD_ON_BIT)<='0';
        fsm_tlayer_cs <= S_IDLE;

      else
          i_reg_update.fpio<='1';
          fsm_tlayer_cs <= S_HT_PIOITrans2;

      end if;--//if i_ll_state_illegal

    --//------------------------------------------
    --//Режим PIO / Прием данных (FPGA <- HDD)
    --//-----------------------------------------
    when S_HT_PIOITrans2 =>

      i_reg_update.fpio<='0';

      if i_ll_state_illegal='1' then
        i_fpiosetup<='0';
        i_rxd_en<='0';
        i_tl_status(C_TSTAT_FSMRxD_ON_BIT)<='0';
        fsm_tlayer_cs <= S_IDLE;

      else

          if sr_ll_status_rcv_done='1' then--if p_in_ll_status(C_LSTAT_RxOK)='1' or p_in_ll_status(C_LSTAT_RxERR_CRC)='1' then
          --//Прием данных завершен
              i_rxd_en<='0';

              if p_in_ll_status(C_LSTAT_RxERR_CRC)='1' then
                i_rxd_err<='1';
              elsif p_in_ll_status(C_LSTAT_RxOK)='1' then
                i_rxd_err<='0';
              end if;

              fsm_tlayer_cs <= S_HT_PIOEnd;

          end if;

      end if;--//if i_ll_state_illegal



    --$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
    -- //Обработчик Команд в режиме DMA
    --$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
--    --//-------------------------------------------
--    --//FIS_DMASETUP: Передача
--    --//-------------------------------------------
--    when S_HT_DmaSetupFIS =>
--
--      if i_ll_state_illegal='1' or p_in_ll_status(C_LSTAT_RxSTART)='1' then
--      --//Link Layer сигнализирует о ошибках в работе автомата или о начале прием данных от SATA устройста
--        i_ll_ctrl(C_LCTRL_TxSTART_BIT)<='0';
--        fsm_tlayer_cs <= S_IDLE;
--
--      else
--
--        if p_in_ll_txd_rd='1' then
--            i_ll_ctrl(C_LCTRL_TxSTART_BIT)<='0';
--
--            if i_fdcnt(2 downto 0)=CONV_STD_LOGIC_VECTOR(10#00#, 3) then
--              i_fh2d(8*(0+1)-1 downto 8*0)<=CONV_STD_LOGIC_VECTOR(C_FIS_DMASETUP, 8);
--
--              i_fh2d(8*1+3 downto 8*1+0)<=(others=>'0');--//PM Port
--              i_fh2d(8*1+4)<='0';--//Reseved
--              i_fh2d(8*1+5)<=i_reg_fpdma.dir;--//Direction
--              i_fh2d(8*1+6)<='0';--//Interrupt
--              i_fh2d(8*1+7)<='0';--//Auto-Activate
--
--              i_fh2d(8*(2+1)-1 downto 8*2)<=(others=>'0');
--              i_fh2d(8*(3+1)-1 downto 8*3)<=(others=>'0');
--
--            elsif i_fdcnt(2 downto 0)=CONV_STD_LOGIC_VECTOR(10#01#, 3) then
--              i_fh2d(31 downto 0)<=i_reg_fpdma.addr(31 downto 0);
--
--            elsif i_fdcnt(2 downto 0)=CONV_STD_LOGIC_VECTOR(10#02#, 3) then
--              i_fh2d(31 downto 0)<=i_reg_fpdma.addr(63 downto 32);
--
--            elsif i_fdcnt(2 downto 0)=CONV_STD_LOGIC_VECTOR(10#03#, 3) then
--              i_fh2d(31 downto 0)<=(others=>'0');
--
--            elsif i_fdcnt(2 downto 0)=CONV_STD_LOGIC_VECTOR(10#04#, 3) then
--              i_fh2d(31 downto 0)<=i_reg_fpdma.offset;
--
--            elsif i_fdcnt(2 downto 0)=CONV_STD_LOGIC_VECTOR(10#05#, 3) then
--              i_fh2d(31 downto 0)<=i_reg_fpdma.trncount_byte;
--
--            elsif i_fdcnt(2 downto 0)=CONV_STD_LOGIC_VECTOR(10#06#, 3) then
--              i_fh2d(31 downto 0)<=(others=>'0');
--
--            end if;
--
--            if i_fdcnt(2 downto 0)=CONV_STD_LOGIC_VECTOR(C_FIS_DMASETUP_DWSIZE-1, 3) then
--            --//Передал все данные
--              i_fh2d_close<='1';
--              i_fdcnt<=(others=>'0');
--              fsm_tlayer_cs <= S_HT_DmaSetupTransStatus;
--
--            else
--              i_fdcnt<=i_fdcnt + 1;
--            end if;
--
--        end if;
--
--      end if;--//if i_ll_state_illegal='1' then
--
--    --//------------------------------------------
--    --//FIS_DMASETUP: Передача
--    --//------------------------------------------
--    when S_HT_DmaSetupTransStatus =>
--
--      if i_ll_state_illegal='1' then
--        i_fh2d_close<='0';
--        fsm_tlayer_cs <= S_IDLE;
--
--      else
--          if p_in_ll_txd_rd='1' then
--            i_fh2d_close<='0';
--          end if;
--
--          if p_in_ll_status(C_LSTAT_TxERR_CRC)='1' then
--
--            fsm_tlayer_cs <= S_IDLE;
--
--          elsif p_in_ll_status(C_LSTAT_TxOK)='1' then
--
--            fsm_tlayer_cs <= S_IDLE;
--
--          end if;
--
--      end if;--//if i_ll_state_illegal='1' then


    --//------------------------------------------
    --//FIS_DMASETUP: Прием
    --//------------------------------------------
    when S_HT_DS_FIS =>

      if i_ll_state_illegal='1' then
        i_fdcnt<=(others=>'0');
        i_fauto_activate_bit<='0';
        fsm_tlayer_cs <= S_IDLE;

      else

        if sr_ll_status_rcv_done='1' then--if p_in_ll_status(C_LSTAT_RxOK)='1' or p_in_ll_status(C_LSTAT_RxERR_CRC)='1' then
        --//Прием данных завершен
            if p_in_ll_status(C_LSTAT_RxOK)='1' then
            --//CRC - OK!
              if i_fdcnt(2 downto 0)=CONV_STD_LOGIC_VECTOR(C_FIS_DMASETUP_DWSIZE, 3) then
              --//FIS length - OK!
                  if i_fdir_bit=C_DIR_H2D and i_fauto_activate_bit='1' then
                  --//Передача данных (FPGA -> HDD)
--                    i_reg_fpdma.dir<=C_DIR_H2D;
                    fsm_tlayer_cs <= S_HT_DMAOTrans2;
                  else
                  --//Прием данных (FPGA <- HDD)
--                    i_reg_fpdma.dir<=C_DIR_D2H;
                    fsm_tlayer_cs <= S_IDLE;
                  end if;

              else
                i_ll_ctrl(C_LCTRL_TL_CHECK_ERR_BIT)<='1';
                fsm_tlayer_cs <= S_IDLE;

              end if;

              i_ll_ctrl(C_LCTRL_TL_CHECK_DONE_BIT)<='1';--//Сигнал Link уровню отправить примитив подтверждения R_ERR/R_OK

            else
              fsm_tlayer_cs <= S_IDLE;
            end if;

            i_fdcnt<=(others=>'0');

        elsif sr_llrxd_en(0)='1' then
        --//Прием содержимого FIS

--            if i_fdcnt(2 downto 0)=CONV_STD_LOGIC_VECTOR(10#00#, 3) then
--              i_fdir_bit <= sr_llrxd(0)(C_FIS_DIR_BIT+8);
--              i_fauto_activate_bit <= sr_llrxd(0)(C_FIS_AUTO_ACTIVATE_BIT+8);
--
--            elsif i_fdcnt(2 downto 0)=CONV_STD_LOGIC_VECTOR(10#01#, 3) then
--              i_reg_fpdma.addr(31 downto 0)<=sr_llrxd(0);
--
--            elsif i_fdcnt(2 downto 0)=CONV_STD_LOGIC_VECTOR(10#02#, 3) then
--              i_reg_fpdma.addr(63 downto 32)<=sr_llrxd(0);
--
--            elsif i_fdcnt(2 downto 0)=CONV_STD_LOGIC_VECTOR(10#04#, 3) then
--              i_reg_fpdma.offset(31 downto 0)<=sr_llrxd(0);
--
--            elsif i_fdcnt(2 downto 0)=CONV_STD_LOGIC_VECTOR(10#05#, 3) then
--              i_reg_fpdma.trncount_byte <= sr_llrxd(0);
--
--            end if;

            i_fdcnt<=i_fdcnt + 1;

        end if;--//if sr_llrxd_en(0)='1' then

      end if;--//if i_ll_state_illegal


    --//------------------------------------------
    --//Режим DMA / Прием FIS DMA ACTIVATE
    --//------------------------------------------
    when S_HT_DMA_FIS =>

      if i_ll_state_illegal='1' then
        i_fdcnt<=(others=>'0');
        fsm_tlayer_cs <= S_IDLE;

      else

        if sr_ll_status_rcv_done='1' then--if p_in_ll_status(C_LSTAT_RxOK)='1' or p_in_ll_status(C_LSTAT_RxERR_CRC)='1' then
        --//Прием данных завершен
          if p_in_ll_status(C_LSTAT_RxOK)='1' then
          --//CRC - OK!
            if i_fdcnt(2 downto 0)=CONV_STD_LOGIC_VECTOR(C_FIS_DMA_ACTIVATE_DWSIZE, 3) then
            --//FIS length - OK!
              i_tl_status(C_TSTAT_DWR_START_BIT)<='1';
              fsm_tlayer_cs <= S_HT_DMAOTrans1;

            else
              i_ll_ctrl(C_LCTRL_TL_CHECK_ERR_BIT)<='1';
              fsm_tlayer_cs <= S_IDLE;

            end if;

            i_ll_ctrl(C_LCTRL_TL_CHECK_DONE_BIT)<='1';--//Сигнал Link уровню отправить примитив подтверждения R_ERR/R_OK

          else
            fsm_tlayer_cs <= S_IDLE;
          end if;

          i_fdcnt<=(others=>'0');

        elsif p_in_ll_rxd_wr='1' then
        --//Прием содержимого FIS
          i_fdcnt<=i_fdcnt + 1;

        end if;

      end if;--//if i_ll_state_illegal

    --//------------------------------------------
    --//Режим DMA / Передача данных
    --//------------------------------------------
    when S_HT_DMAOTrans1 =>

      i_tl_status(C_TSTAT_DWR_START_BIT)<='0';

      if i_ll_state_illegal='1' then
        fsm_tlayer_cs <= S_IDLE;

      else
          i_ll_ctrl(C_LCTRL_TL_CHECK_DONE_BIT)<='0';

          if i_txfifo_pfull='1' then
          --//Ждем когда в TxBUF накопятся данные для предачи
            i_ll_ctrl(C_LCTRL_TxSTART_BIT)<='1';
            i_dma_txd<='1';
            i_tl_status(C_TSTAT_FSMTxD_ON_BIT)<='1';
            fsm_tlayer_cs <= S_HT_DMAOTrans2;

          end if;

      end if;--//if i_ll_state_illegal

    --//------------------------------------------
    --//Режим DMA / Передача данных
    --//------------------------------------------
    when  S_HT_DMAOTrans2 =>

      if i_ll_state_illegal='1' then
        i_ll_ctrl(C_LCTRL_TxSTART_BIT)<='0';
        i_dma_txd<='0';
        i_tl_status(C_TSTAT_FSMTxD_ON_BIT)<='0';
        fsm_tlayer_cs <= S_IDLE;

      else

        i_ll_ctrl(C_LCTRL_TL_CHECK_DONE_BIT)<='0';

        if p_in_ll_status(C_LSTAT_TxDMAT)='1' then
        --//ABORT!!!
        --//Link Layer сигнализирует о приеме примитива DMAT
          i_ll_ctrl(C_LCTRL_TxSTART_BIT)<='0';

          i_fdata_txd_en<='0';
          i_fdata_tx_en<='0';
          i_fdone<='0';
          fsm_tlayer_cs<=S_HT_DMAEnd;

        elsif i_fdone='0' then
            --//Отправка FISDATA
            if p_in_ll_txd_rd='1' then

                i_ll_ctrl(C_LCTRL_TxSTART_BIT)<='0';

                if i_fdata_tx_en='0' then
                --//Заголовок
                    i_fdata_tx_en<='1';--//Заголовок FISDATA передан
                    i_fh2d<=CONV_STD_LOGIC_VECTOR(C_FIS_DATA, i_fh2d'length);

                else
                --//Данные
                    if i_fdata_txd_en='1' and (i_dma_dcnt=i_dma_trncount_dw or OR_reduce(i_dma_dcnt(log2(CI_FR_DWORD_COUNT_MAX)-1 downto 0))='0') then
                      if i_dma_dcnt=i_dma_trncount_dw then
                      --//Передал все данные
                        i_fdata_txd_en<='0';
                        i_fdata_tx_en<='0';
                        fsm_tlayer_cs<=S_HT_DMAEnd;
                      else
                      --//Переходим к следующей транзакции передачи данных
                        i_fdone<='1';
                      end if;

                    else
                      i_fdata_txd_en<='1';
--                      i_dma_dcnt<=i_dma_dcnt + 1;
                    end if;

                end if;--//if i_fdata_txd_en='0' then
            end if;--//if p_in_ll_txd_rd='1' then

        else
          --//Ждем нотации от Link Layer
            if p_in_ll_status(C_LSTAT_TxERR_CRC)='1' or p_in_ll_status(C_LSTAT_TxOK)='1' then
              i_dma_txd<='0';
              i_fdata_txd_en<='0';
              i_fdata_tx_en<='0';
              i_fdone<='0';
              i_tl_status(C_TSTAT_FSMTxD_ON_BIT)<='0';
              fsm_tlayer_cs <= S_IDLE;

            end if;

        end if;--//if if p_in_ll_status

      end if;--//if i_ll_state_illegal


    --//------------------------------------------
    --//Режим DMA / Завершение команды
    --//------------------------------------------
    when S_HT_DMAEnd =>

      if i_ll_state_illegal='1' then
        i_dma_txd<='0';
        i_tl_status(C_TSTAT_FSMTxD_ON_BIT)<='0';
        i_tl_status(C_TSTAT_FSMRxD_ON_BIT)<='0';
        fsm_tlayer_cs <= S_IDLE;

      else

          if i_fdir_bit=C_DIR_D2H then
          --Прием данных (FPGA <- HDD)
              if i_rxd_err='0' then
                i_ll_ctrl(C_LCTRL_TL_CHECK_DONE_BIT)<='1';--//Сигнал Link уровню отправить примитив подтверждения R_ERR/R_OK
              end if;

              i_tl_status(C_TSTAT_FSMTxD_ON_BIT)<='0';
              i_tl_status(C_TSTAT_FSMRxD_ON_BIT)<='0';
              fsm_tlayer_cs <= S_IDLE;

          else
          --Передача данных (FPGA -> HDD)
--              if i_dma_dcnt=i_dma_trncount_dw then
--              --//Передал все данные
--                i_dma_dcnt<=(others=>'0');
--              end if;

              if p_in_ll_status(C_LSTAT_TxERR_CRC)='1' then
                i_dma_txd<='0';
                i_tl_status(C_TSTAT_FSMTxD_ON_BIT)<='0';
                i_tl_status(C_TSTAT_FSMRxD_ON_BIT)<='0';
                fsm_tlayer_cs <= S_IDLE;

              elsif p_in_ll_status(C_LSTAT_TxOK)='1' then
                i_dma_txd<='0';
                i_tl_status(C_TSTAT_FSMTxD_ON_BIT)<='0';
                i_tl_status(C_TSTAT_FSMRxD_ON_BIT)<='0';
                fsm_tlayer_cs <= S_IDLE;

              end if;

          end if;

      end if;--//if i_ll_state_illegal

    --//------------------------------------------
    --//Режим DMA / Прием данных
    --//------------------------------------------
    when S_HT_DMAITrans =>

      if i_ll_state_illegal='1' then
        i_rxd_en<='0';
        i_tl_status(C_TSTAT_FSMRxD_ON_BIT)<='0';
        fsm_tlayer_cs <= S_IDLE;

      else

          if sr_ll_status_rcv_done='1' then--if p_in_ll_status(C_LSTAT_RxOK)='1' or p_in_ll_status(C_LSTAT_RxERR_CRC)='1' then
          --//Прием данных завершен
              i_rxd_en<='0';

              if p_in_ll_status(C_LSTAT_RxERR_CRC)='1' then
                i_rxd_err<='1';
              elsif p_in_ll_status(C_LSTAT_RxOK)='1' then
                i_rxd_err<='0';
              end if;

              fsm_tlayer_cs <= S_HT_DMAEnd;

          end if;

      end if;--//if i_ll_state_illegal

  end case;

end if;
end process lfsm;



--//-----------------------------------
--//Debug/Sim
--//-----------------------------------
--gen_sim_on : if strcmp(G_SIM,"ON") generate

p_out_dbg.fsm<=fsm_tlayer_cs;

p_out_dbg.ctrl.ata_command<=p_in_tl_ctrl(C_TCTRL_RCOMMAND_WR_BIT);
p_out_dbg.ctrl.ata_control<=p_in_tl_ctrl(C_TCTRL_RCONTROL_WR_BIT);

p_out_dbg.status.txfh2d_en<=i_tl_status(C_TSTAT_TxFISHOST2DEV_BIT);
p_out_dbg.status.rxfistype_err<=i_tl_status(C_TSTAT_RxFISTYPE_ERR_BIT);
p_out_dbg.status.rxfislen_err<=i_tl_status(C_TSTAT_RxFISLEN_ERR_BIT);
p_out_dbg.status.txerr_crc_repeat<=i_tl_status(C_TSTAT_TxERR_CRC_REPEAT_BIT);
p_out_dbg.status.dma_wrstart<=i_tl_status(C_TSTAT_DWR_START_BIT);

p_out_dbg.dmatrn_sizedw<=EXT(i_dma_trncount_dw, p_out_dbg.dmatrn_sizedw'length);
p_out_dbg.dmatrn_dcnt<=EXT(i_dma_dcnt, p_out_dbg.dmatrn_dcnt'length);
p_out_dbg.piotrn_sizedw<=EXT(i_piosetup_trncount_dw, p_out_dbg.piotrn_sizedw'length);


p_out_dbg.other_status.firq_bit<=i_tl_status(C_TSTAT_FIS_I_BIT);
p_out_dbg.other_status.fdir_bit<=i_fdir_bit;
p_out_dbg.other_status.fpiosetup<=i_fpiosetup;
p_out_dbg.other_status.dcnt     <=EXT(i_fdcnt, p_out_dbg.other_status.dcnt'length);--i_fdcnt(15 downto 0);
p_out_dbg.other_status.altxbuf_rd<=p_in_ll_txd_rd and i_fdata_tx_en and not i_fdata_close;
p_out_dbg.other_status.alrxbuf_wr<=p_in_ll_rxd_wr and i_rxd_en;


--end generate gen_sim_on;

--END MAIN
end behavioral;
