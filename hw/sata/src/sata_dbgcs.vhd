-------------------------------------------------------------------------
-- Company     : Linkos
-- Engineer    : Golovachenko Victor
--
-- Create Date : 06.05.2011 17:49:18
-- Module Name : sata_dbgcs
--
-- Назначение : Формирование отладочных сигналов для передачи в модуль
--              ILA (ChipScope).
--
--              Структурная схема передачи отладочных сигналов:
--               PC              FPGA
--                          |
--             Analizator <-|<- ICON <-> ILA <- отладочные сигналы
--                          |   (модули ICON,ILA генерируются с помощью Core_Gen)
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

library work;
use work.vicg_common_pkg.all;
use work.sata_glob_pkg.all;
use work.sata_pkg.all;
use work.sata_sim_lite_pkg.all;
use work.sata_unit_pkg.all;

entity sata_dbgcs is
generic(
G_DBG : string:="OFF";
G_SIM : string:="OFF"
);
port(
--------------------------------------------------
--Связь с СhipScope ICON
--------------------------------------------------
p_out_dbgcs_ila   : out   TSH_ila;

--------------------------------------------------
--USR
--------------------------------------------------
p_in_ctrl         : in    std_logic_vector(C_USR_GCTRL_LAST_BIT downto 0);

p_in_dbg          : in    TSH_dbgport;
p_in_alstatus     : in    TALStatus;
p_in_phy_txreq    : in    std_logic_vector(7 downto 0);
p_in_phy_rxtype   : in    std_logic_vector(C_TDATA_EN downto C_TALIGN);
p_in_phy_rxdata   : in    std_logic_vector(31 downto 0);
p_in_phy_sync     : in    std_logic;

p_in_reg_hold     : in    TRegHold;
p_in_reg_update   : in    TRegShadowUpdate;

p_in_ll_rxd       : in    std_logic_vector(31 downto 0);
p_in_ll_rxd_wr    : in    std_logic;
p_in_ll_txd       : in    std_logic_vector(31 downto 0);
p_in_ll_txd_rd    : in    std_logic;

--Tranceiver
p_in_txelecidle     : in    std_logic;
p_in_txcomstart     : in    std_logic;
p_in_txcomtype      : in    std_logic;
p_in_txdata         : in    std_logic_vector(31 downto 0);
p_in_txcharisk      : in    std_logic_vector(3 downto 0);

p_in_txreset        : in    std_logic;
p_in_txbufstatus    : in    std_logic_vector(1 downto 0);

--Receiver
p_in_rxcdrreset     : in    std_logic;
p_in_rxreset        : in    std_logic;
p_in_rxelecidle     : in    std_logic;
p_in_rxstatus       : in    std_logic_vector(2 downto 0);
p_in_rxdata         : in    std_logic_vector(31 downto 0);
p_in_rxcharisk      : in    std_logic_vector(3 downto 0);
p_in_rxdisperr      : in    std_logic_vector(3 downto 0);
p_in_rxnotintable   : in    std_logic_vector(3 downto 0);
p_in_rxbyteisaligned: in    std_logic;

p_in_rxbufreset     : in    std_logic;
p_in_rxbufstatus    : in    std_logic_vector(2 downto 0);

--------------------------------------------------
--Технологические сигналы
--------------------------------------------------
p_out_tst         : out   std_logic_vector(31 downto 0);

--------------------------------------------------
--System
--------------------------------------------------
p_in_clk          : in    std_logic;
p_in_rst          : in    std_logic
);
end sata_dbgcs;

architecture behavioral of sata_dbgcs is

signal i_dbgcs_trig00              : std_logic_vector(41 downto 0);
signal i_dbgcs_data                : std_logic_vector(170 downto 0);--(122 downto 0);

signal i_fsm_ploob                 : std_logic_vector(3 downto 0);
signal i_fsm_llayer                : std_logic_vector(4 downto 0);
signal i_fsm_tlayer                : std_logic_vector(4 downto 0);

--signal tst_sync                    : std_logic;
--signal tst_det_rip                 : std_logic;

signal sr_ipf_bit                  : std_logic_vector(1 downto 0);
signal i_ipf_bit_det               : std_logic;

signal i_tst_cnt                   : std_logic_vector(15 downto 0):=(others=>'0');
signal tst_trm_timeout             : std_logic_vector(7 downto 0):=(others=>'0');


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
end generate gen_dbg_on;


--//-----------------------------
--//Инициализация
--//-----------------------------
process(p_in_clk)
begin
if p_in_clk'event and p_in_clk='1' then
sr_ipf_bit(0)<=p_in_alstatus.ipf;
sr_ipf_bit(1)<=sr_ipf_bit(0);
i_ipf_bit_det<=sr_ipf_bit(0) and not sr_ipf_bit(1);


i_dbgcs_trig00(18 downto 0)<=p_in_phy_rxtype(C_TDATA_EN downto C_TALIGN);

i_dbgcs_trig00(19)<=p_in_alstatus.serror(C_ASERR_P_ERR_BIT) or
                    p_in_alstatus.serror(C_ASERR_C_ERR_BIT) or
                    p_in_alstatus.serror(C_ASERR_I_ERR_BIT) or
                    p_in_alstatus.atastatus(C_ATA_STATUS_ERR_BIT);

i_dbgcs_trig00(20)<=p_in_alstatus.sstatus(C_ASSTAT_DET_BIT_L+1);--//C_PSTAT_DET_ESTABLISH_ON_BIT
i_dbgcs_trig00(21)<=p_in_alstatus.sstatus(C_ASSTAT_DET_BIT_L+0);--//C_PSTAT_DET_DEV_ON_BIT

i_dbgcs_trig00(22)<=p_in_alstatus.serror(C_ASERR_F_DIAG_BIT);--: integer:=25;--//Transport Layer:  CRC-OK, but FISTYPE/FISLEN ERROR
i_dbgcs_trig00(23)<=p_in_alstatus.serror(C_ASERR_T_DIAG_BIT);--: integer:=24;--//if p_in_ll_status(C_LSTAT_RxERR_ABORT)='1' or p_in_ll_status(C_LSTAT_TxERR_ABORT)='1' then
i_dbgcs_trig00(24)<=p_in_alstatus.serror(C_ASERR_S_DIAG_BIT);--: integer:=23;--//if p_in_ll_status(C_LSTAT_RxERR_IDLE)='1' or p_in_ll_status(C_LSTAT_TxERR_IDLE)='1' then
i_dbgcs_trig00(25)<=i_ipf_bit_det;--tst_sync;--p_in_alstatus.serror(C_ASERR_C_DIAG_BIT);--: integer:=21;--//Link Layer: --//CRC ERROR


i_dbgcs_trig00(29 downto 26)<=i_fsm_ploob(3 downto 0);
i_dbgcs_trig00(34 downto 30)<=i_fsm_llayer(4 downto 0);
i_dbgcs_trig00(39 downto 35)<=i_fsm_tlayer(4 downto 0);
i_dbgcs_trig00(40)<=tst_trm_timeout(7);--p_in_dbg.tlayer.other_status.fdir_bit;
i_dbgcs_trig00(41)<=p_in_dbg.tlayer.other_status.fpiosetup;





i_dbgcs_data(18 downto 0)<=p_in_phy_rxtype(C_TDATA_EN downto C_TALIGN);

i_dbgcs_data(22 downto 19)<=i_fsm_ploob(3 downto 0);
i_dbgcs_data(27 downto 23)<=i_fsm_llayer(4 downto 0);
i_dbgcs_data(32 downto 28)<=i_fsm_tlayer(4 downto 0);

--//detect error
i_dbgcs_data(33)<=p_in_alstatus.serror(C_ASERR_P_ERR_BIT) or
                  p_in_alstatus.serror(C_ASERR_C_ERR_BIT) or
                  p_in_alstatus.serror(C_ASERR_I_ERR_BIT) or
                  p_in_alstatus.atastatus(C_ATA_STATUS_ERR_BIT);


i_dbgcs_data(34)<=p_in_dbg.alayer.cmd_busy;              --p_in_alstatus.sstatus(C_ASSTAT_DET_BIT_L+1);--//C_PSTAT_DET_ESTABLISH_ON_BIT
i_dbgcs_data(35)<=p_in_dbg.tlayer.other_status.fpiosetup;--p_in_alstatus.sstatus(C_ASSTAT_DET_BIT_L+0);--//C_PSTAT_DET_DEV_ON_BIT

i_dbgcs_data(36)<=p_in_alstatus.serror(C_ASERR_F_DIAG_BIT);--: integer:=25;--//Transport Layer:  CRC-OK, but FISTYPE/FISLEN ERROR
i_dbgcs_data(37)<=p_in_alstatus.serror(C_ASERR_T_DIAG_BIT);--: integer:=24;--//if p_in_ll_status(C_LSTAT_RxERR_ABORT)='1' or p_in_ll_status(C_LSTAT_TxERR_ABORT)='1' then
i_dbgcs_data(38)<=p_in_alstatus.serror(C_ASERR_S_DIAG_BIT);--: integer:=23;--//if p_in_ll_status(C_LSTAT_RxERR_IDLE)='1' or p_in_ll_status(C_LSTAT_TxERR_IDLE)='1' then
i_dbgcs_data(39)<=p_in_alstatus.serror(C_ASERR_H_DIAG_BIT);--: integer:=22;--//Link Layer: --//1/0 - CRC ERROR on (send FIS/rcv FIS)
i_dbgcs_data(40)<=p_in_alstatus.serror(C_ASERR_C_DIAG_BIT);--: integer:=21;--//Link Layer: --//CRC ERROR
i_dbgcs_data(41)<=p_in_alstatus.serror(C_ASERR_D_DIAG_BIT);--: integer:=20;--//if p_in_pl_status(C_PSTAT_DET_ESTABLISH_ON_BIT)='1' and p_in_pl_status(C_PRxSTAT_ERR_DISP_BIT)='1' then
i_dbgcs_data(42)<=p_in_alstatus.serror(C_ASERR_B_DIAG_BIT);--: integer:=19;--//if p_in_pl_status(C_PSTAT_DET_ESTABLISH_ON_BIT)='1' and p_in_pl_status(C_PRxSTAT_ERR_NOTINTABLE_BIT)='1' then

i_dbgcs_data(43)<=p_in_dbg.player.tx.txalign;
i_dbgcs_data(44)<=p_in_phy_txreq(0);
i_dbgcs_data(45)<=p_in_phy_txreq(1);
i_dbgcs_data(46)<=p_in_phy_txreq(2);
i_dbgcs_data(47)<=p_in_phy_txreq(3);
i_dbgcs_data(48)<=p_in_phy_txreq(4);

i_dbgcs_data(49)<=p_in_ll_rxd_wr;
i_dbgcs_data(81 downto 50)<=p_in_ll_rxd(31 downto 0);--p_in_phy_rxdata;--p_in_ll_txd(31 downto 0);--
--i_dbgcs_data(65 downto 50)<=p_in_ll_rxd(15 downto 0);

i_dbgcs_data(89 downto 82)<=p_in_rxdata( 7 downto 0); --p_in_ll_txd(15 downto 0);--
i_dbgcs_data(97 downto 90)<=p_in_rxdata(15 downto 8); --p_in_ll_txd(15 downto 0);--
i_dbgcs_data(98)          <=p_in_dbg.llayer.rxbuf_status.pfull;--p_in_rxcharisk(0);--
i_dbgcs_data(99)          <=p_in_dbg.llayer.txbuf_status.full;--p_in_rxcharisk(1);--

i_dbgcs_data(107 downto 100)<=p_in_txdata( 7 downto 0);--p_in_dbg.tlayer.other_status.dcnt;--i_tst_cnt;--
i_dbgcs_data(115 downto 108)<=p_in_txdata(15 downto 8);--p_in_dbg.tlayer.other_status.dcnt;--i_tst_cnt;--

i_dbgcs_data(116)<=p_in_ll_txd_rd;
i_dbgcs_data(117)<=p_in_dbg.llayer.txd_close;

i_dbgcs_data(118)<=p_in_dbg.llayer.txbuf_status.aempty; --p_in_txcharisk(0);--
i_dbgcs_data(119)<=p_in_dbg.llayer.txbuf_status.empty;  --p_in_txcharisk(1);--
i_dbgcs_data(120)<=p_in_alstatus.ipf;--p_in_dbg.tlayer.other_status.irq;
i_dbgcs_data(121)<=p_in_dbg.tlayer.other_status.firq_bit;
i_dbgcs_data(122)<=p_in_alstatus.atastatus(C_ATA_STATUS_BUSY_BIT);


i_dbgcs_data(123)<=p_in_dbg.alayer.opt.err_clr;
i_dbgcs_data(131 downto 124)<=p_in_alstatus.atastatus;--ATA reg
i_dbgcs_data(139 downto 132)<=p_in_reg_hold.status;--tlayer
--i_dbgcs_data(147 downto 140)<=p_in_reg_hold.e_status;--tlayer
i_dbgcs_data(141 downto 140)<=p_in_txbufstatus(1 downto 0);
i_dbgcs_data(147 downto 142)<=(others=>'0');

i_dbgcs_data(148)<=p_in_reg_update.fd2h;  --//Обновление Shadow Reg по приему FIS_DEV2HOST
i_dbgcs_data(149)<=p_in_reg_update.fpio;  --//Обновление Shadow Reg по приему FIS_PIOSETUP
i_dbgcs_data(150)<=p_in_reg_update.fpio_e;--//Обновление Shadow Reg в результате корректного завершения АТА комманды
i_dbgcs_data(151)<=p_in_reg_update.fsdb;  --//Обновление Shadow Reg по приему FIS_SetDevice_Bits

i_dbgcs_data(152)<=p_in_rxcharisk(0);--p_in_dbg.alayer.opt.link_up;
i_dbgcs_data(153)<=p_in_rxcharisk(1);--p_in_dbg.alayer.opt.link_break;
i_dbgcs_data(154)<=p_in_rxcharisk(2);--p_in_dbg.alayer.opt.reg_shadow_wr_done;
i_dbgcs_data(155)<=p_in_rxcharisk(3);--p_in_dbg.alayer.opt.reg_shadow_wr;

i_dbgcs_data(156)<=p_in_phy_sync;
i_dbgcs_data(159 downto 157)<=p_in_rxbufstatus;--(others=>'0');

i_dbgcs_data(160)<=p_in_alstatus.sstatus(C_ASSTAT_DET_BIT_L+1);--//C_PSTAT_DET_ESTABLISH_ON_BIT
i_dbgcs_data(161)<=p_in_alstatus.sstatus(C_ASSTAT_DET_BIT_L+0);--//C_PSTAT_DET_DEV_ON_BIT
i_dbgcs_data(162)<=p_in_txelecidle;
i_dbgcs_data(163)<=p_in_rxelecidle;
i_dbgcs_data(164)<=p_in_txcomstart;
i_dbgcs_data(165)<=p_in_txcomtype;

i_dbgcs_data(166)<=p_in_txreset;
i_dbgcs_data(167)<=p_in_rxcdrreset;
i_dbgcs_data(168)<=p_in_rxreset;
i_dbgcs_data(169)<=p_in_rxbufreset;
i_dbgcs_data(170)<=p_in_rxbyteisaligned;

end if;
end process;

--process(p_in_rst,p_in_clk)
--begin
--  if p_in_rst='1' then
--      tst_sync<='0';
--      tst_det_rip<='0';
--  elsif p_in_clk'event and p_in_clk='1' then
--    if tst_det_rip='1' and p_in_phy_rxtype(C_THOLD)='1' then
--      tst_sync<='1';
--      tst_det_rip<='0';
--    elsif tst_det_rip='1' and p_in_phy_rxtype(C_TR_IP)='1' then
--      tst_sync<='0';
--      tst_det_rip<='0';
--    elsif p_in_dbg.llayer.fsm=S_LT_RcvrHold and p_in_phy_rxtype(C_TR_IP)='1' then
--      tst_sync<='0';
--      tst_det_rip<='1';
--    end if;
--  end if;
--end process;

process(p_in_clk)
begin
if p_in_clk'event and p_in_clk='1' then

  if p_in_dbg.tlayer.ctrl.ata_command='1' then
    i_tst_cnt<=(others=>'0');
  else
    if p_in_dbg.tlayer.other_status.altxbuf_rd='1' or p_in_dbg.tlayer.other_status.alrxbuf_wr='1' then
      i_tst_cnt<=i_tst_cnt + 1;
    end if;
  end if;


  --llayer/=S_LT_SendHold
  if i_dbgcs_data(27 downto 23)=CONV_STD_LOGIC_VECTOR(16#0C#, 5) then
    tst_trm_timeout<=tst_trm_timeout + 1;
  else
    tst_trm_timeout<=(others=>'0');
  end if;
end if;
end process;


i_fsm_ploob<=CONV_STD_LOGIC_VECTOR(16#01#, i_fsm_ploob'length) when p_in_dbg.player.oob.fsm=S_HR_COMRESET_DONE  else
             CONV_STD_LOGIC_VECTOR(16#02#, i_fsm_ploob'length) when p_in_dbg.player.oob.fsm=S_HR_AwaitCOMINIT   else
             CONV_STD_LOGIC_VECTOR(16#03#, i_fsm_ploob'length) when p_in_dbg.player.oob.fsm=S_HR_COMWAKE        else
             CONV_STD_LOGIC_VECTOR(16#04#, i_fsm_ploob'length) when p_in_dbg.player.oob.fsm=S_HR_COMWAKE_DONE   else
             CONV_STD_LOGIC_VECTOR(16#05#, i_fsm_ploob'length) when p_in_dbg.player.oob.fsm=S_HR_AwaitCOMWAKE   else
             CONV_STD_LOGIC_VECTOR(16#06#, i_fsm_ploob'length) when p_in_dbg.player.oob.fsm=S_HR_AwaitNoCOMWAKE else
             CONV_STD_LOGIC_VECTOR(16#07#, i_fsm_ploob'length) when p_in_dbg.player.oob.fsm=S_HR_AwaitAlign     else
             CONV_STD_LOGIC_VECTOR(16#08#, i_fsm_ploob'length) when p_in_dbg.player.oob.fsm=S_HR_SendAlign      else
             CONV_STD_LOGIC_VECTOR(16#09#, i_fsm_ploob'length) when p_in_dbg.player.oob.fsm=S_HR_Connect        else
             CONV_STD_LOGIC_VECTOR(16#0A#, i_fsm_ploob'length) when p_in_dbg.player.oob.fsm=S_HR_COMRESET       else
             CONV_STD_LOGIC_VECTOR(16#0B#, i_fsm_ploob'length) when p_in_dbg.player.oob.fsm=S_HR_AwaitNoCOMINIT else
             CONV_STD_LOGIC_VECTOR(16#0C#, i_fsm_ploob'length) when p_in_dbg.player.oob.fsm=S_HR_Calibrate      else
             CONV_STD_LOGIC_VECTOR(16#0D#, i_fsm_ploob'length) when p_in_dbg.player.oob.fsm=S_HR_Disconnect     else
             CONV_STD_LOGIC_VECTOR(16#00#, i_fsm_ploob'length); --//when p_in_dbg.player.oob.fsm=S_HR_IDLE


i_fsm_llayer<=CONV_STD_LOGIC_VECTOR(16#01#, i_fsm_llayer'length) when p_in_dbg.llayer.fsm=S_L_IDLE          else
              CONV_STD_LOGIC_VECTOR(16#02#, i_fsm_llayer'length) when p_in_dbg.llayer.fsm=S_L_SyncEscape    else
              CONV_STD_LOGIC_VECTOR(16#03#, i_fsm_llayer'length) when p_in_dbg.llayer.fsm=S_L_NoCommErr     else
              CONV_STD_LOGIC_VECTOR(16#04#, i_fsm_llayer'length) when p_in_dbg.llayer.fsm=S_L_NoComm        else
              CONV_STD_LOGIC_VECTOR(16#05#, i_fsm_llayer'length) when p_in_dbg.llayer.fsm=S_LT_H_SendChkRdy else
              CONV_STD_LOGIC_VECTOR(16#06#, i_fsm_llayer'length) when p_in_dbg.llayer.fsm=S_LT_SendSOF      else
              CONV_STD_LOGIC_VECTOR(16#07#, i_fsm_llayer'length) when p_in_dbg.llayer.fsm=S_LT_SendData     else
              CONV_STD_LOGIC_VECTOR(16#08#, i_fsm_llayer'length) when p_in_dbg.llayer.fsm=S_LT_SendCRC      else
              CONV_STD_LOGIC_VECTOR(16#09#, i_fsm_llayer'length) when p_in_dbg.llayer.fsm=S_LT_SendEOF      else
              CONV_STD_LOGIC_VECTOR(16#0A#, i_fsm_llayer'length) when p_in_dbg.llayer.fsm=S_LT_Wait         else
              CONV_STD_LOGIC_VECTOR(16#0B#, i_fsm_llayer'length) when p_in_dbg.llayer.fsm=S_LT_RcvrHold     else
              CONV_STD_LOGIC_VECTOR(16#0C#, i_fsm_llayer'length) when p_in_dbg.llayer.fsm=S_LT_SendHold     else
              CONV_STD_LOGIC_VECTOR(16#0D#, i_fsm_llayer'length) when p_in_dbg.llayer.fsm=S_LR_RcvChkRdy    else
              CONV_STD_LOGIC_VECTOR(16#0E#, i_fsm_llayer'length) when p_in_dbg.llayer.fsm=S_LR_RcvWaitFifo  else
              CONV_STD_LOGIC_VECTOR(16#0F#, i_fsm_llayer'length) when p_in_dbg.llayer.fsm=S_LR_RcvData      else
              CONV_STD_LOGIC_VECTOR(16#10#, i_fsm_llayer'length) when p_in_dbg.llayer.fsm=S_LR_Hold         else
              CONV_STD_LOGIC_VECTOR(16#11#, i_fsm_llayer'length) when p_in_dbg.llayer.fsm=S_LR_SendHold     else
              CONV_STD_LOGIC_VECTOR(16#12#, i_fsm_llayer'length) when p_in_dbg.llayer.fsm=S_LR_RcvEOF       else
              CONV_STD_LOGIC_VECTOR(16#13#, i_fsm_llayer'length) when p_in_dbg.llayer.fsm=S_LR_GoodCRC      else
              CONV_STD_LOGIC_VECTOR(16#14#, i_fsm_llayer'length) when p_in_dbg.llayer.fsm=S_LR_GoodEnd      else
              CONV_STD_LOGIC_VECTOR(16#15#, i_fsm_llayer'length) when p_in_dbg.llayer.fsm=S_LR_BadEnd       else
              CONV_STD_LOGIC_VECTOR(16#00#, i_fsm_llayer'length) ; --//when p_in_dbg.llayer.fsm=S_L_RESET else


i_fsm_tlayer<=CONV_STD_LOGIC_VECTOR(16#01#, i_fsm_tlayer'length) when p_in_dbg.tlayer.fsm=S_HT_ChkTyp              else
              CONV_STD_LOGIC_VECTOR(16#02#, i_fsm_tlayer'length) when p_in_dbg.tlayer.fsm=S_HT_CmdFIS              else
              CONV_STD_LOGIC_VECTOR(16#03#, i_fsm_tlayer'length) when p_in_dbg.tlayer.fsm=S_HT_CmdTransStatus      else
              CONV_STD_LOGIC_VECTOR(16#04#, i_fsm_tlayer'length) when p_in_dbg.tlayer.fsm=S_HT_RegFIS              else
              CONV_STD_LOGIC_VECTOR(16#05#, i_fsm_tlayer'length) when p_in_dbg.tlayer.fsm=S_HT_RegTransStatus      else
              CONV_STD_LOGIC_VECTOR(16#06#, i_fsm_tlayer'length) when p_in_dbg.tlayer.fsm=S_HT_PS_FIS              else
              CONV_STD_LOGIC_VECTOR(16#07#, i_fsm_tlayer'length) when p_in_dbg.tlayer.fsm=S_HT_PIOOTrans1          else
              CONV_STD_LOGIC_VECTOR(16#08#, i_fsm_tlayer'length) when p_in_dbg.tlayer.fsm=S_HT_PIOOTrans2          else
              CONV_STD_LOGIC_VECTOR(16#09#, i_fsm_tlayer'length) when p_in_dbg.tlayer.fsm=S_HT_PIOEnd              else
              CONV_STD_LOGIC_VECTOR(16#0A#, i_fsm_tlayer'length) when p_in_dbg.tlayer.fsm=S_HT_PIOITrans1          else
              CONV_STD_LOGIC_VECTOR(16#0B#, i_fsm_tlayer'length) when p_in_dbg.tlayer.fsm=S_HT_PIOITrans2          else
              CONV_STD_LOGIC_VECTOR(16#0C#, i_fsm_tlayer'length) when p_in_dbg.tlayer.fsm=S_HT_DMA_FIS             else
              CONV_STD_LOGIC_VECTOR(16#0D#, i_fsm_tlayer'length) when p_in_dbg.tlayer.fsm=S_HT_DMAOTrans1          else
              CONV_STD_LOGIC_VECTOR(16#0E#, i_fsm_tlayer'length) when p_in_dbg.tlayer.fsm=S_HT_DMAOTrans2          else
              CONV_STD_LOGIC_VECTOR(16#0F#, i_fsm_tlayer'length) when p_in_dbg.tlayer.fsm=S_HT_DMAEnd              else
              CONV_STD_LOGIC_VECTOR(16#10#, i_fsm_tlayer'length) when p_in_dbg.tlayer.fsm=S_HT_DMAITrans           else
--              CONV_STD_LOGIC_VECTOR(16#11#, i_fsm_tlayer'length) when p_in_dbg.tlayer.fsm=S_HT_DmaSetupFIS         else
--              CONV_STD_LOGIC_VECTOR(16#12#, i_fsm_tlayer'length) when p_in_dbg.tlayer.fsm=S_HT_DmaSetupTransStatus else
              CONV_STD_LOGIC_VECTOR(16#13#, i_fsm_tlayer'length) when p_in_dbg.tlayer.fsm=S_HT_DS_FIS              else
              CONV_STD_LOGIC_VECTOR(16#14#, i_fsm_tlayer'length) when p_in_dbg.tlayer.fsm=S_HT_CtrlFIS             else
              CONV_STD_LOGIC_VECTOR(16#15#, i_fsm_tlayer'length) when p_in_dbg.tlayer.fsm=S_HT_CtrlTransStatus     else
              CONV_STD_LOGIC_VECTOR(16#16#, i_fsm_tlayer'length) when p_in_dbg.tlayer.fsm=S_HT_DB_FIS              else
              CONV_STD_LOGIC_VECTOR(16#17#, i_fsm_tlayer'length) when p_in_dbg.tlayer.fsm=S_HT_Dev_Bits            else
              CONV_STD_LOGIC_VECTOR(16#18#, i_fsm_tlayer'length) when p_in_dbg.tlayer.fsm=S_HT_RcvBIST             else
              CONV_STD_LOGIC_VECTOR(16#19#, i_fsm_tlayer'length) when p_in_dbg.tlayer.fsm=S_HT_BISTTrans1          else
              CONV_STD_LOGIC_VECTOR(16#00#, i_fsm_tlayer'length) ; --//when p_in_dbg.tlayer.fsm=S_IDLE else



p_out_dbgcs_ila.clk   <=p_in_clk;
p_out_dbgcs_ila.trig0 <=EXT(i_dbgcs_trig00, p_out_dbgcs_ila.trig0'length);
p_out_dbgcs_ila.data  <=EXT(i_dbgcs_data, p_out_dbgcs_ila.data'length);


--END MAIN
end behavioral;

