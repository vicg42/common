-------------------------------------------------------------------------
-- Company     : Linkos
-- Engineer    : Golovachenko Victor
--
-- Create Date : 06.05.2011 17:49:18
-- Module Name : sata_dbgcs
--
-- Назначение :
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

library work;
use work.vicg_common_pkg.all;
use work.sata_unit_pkg.all;
use work.sata_pkg.all;
use work.sata_sim_lite_pkg.all;

entity sata_dbgcs is
generic
(
G_DBG      : string  := "OFF";
G_SIM      : string  := "OFF"
);
port
(
p_in_ctrl       : in   std_logic_vector(C_USR_GCTRL_LAST_BIT downto 0);

p_in_dbg        : in   TSH_dbgport;
p_in_alstatus   : in   TALStatus;
p_in_phy_txreq  : in   std_logic_vector(7 downto 0);
p_in_phy_rxtype : in   std_logic_vector(C_TDATA_EN downto C_TALIGN);
p_in_phy_rxdata : in   std_logic_vector(31 downto 0);
p_in_phy_sync   : in   std_logic;

p_in_ll_rxd     : in   std_logic_vector(31 downto 0);
p_in_ll_rxd_wr  : in   std_logic;

p_in_gt_rxdata    : in std_logic_vector(31 downto 0);
p_in_gt_rxcharisk : in std_logic_vector(3 downto 0);

--------------------------------------------------
--Технологические сигналы
--------------------------------------------------
p_out_tst       : out   std_logic_vector(31 downto 0);

--------------------------------------------------
--System
--------------------------------------------------
p_in_clk : in    std_logic;
p_in_rst : in    std_logic
);
end sata_dbgcs;

architecture behavioral of sata_dbgcs is

--signal i_dbgcs_ctrl                : std_logic_vector(35 downto 0);
--signal i_dbgcs_trig00              : std_logic_vector(39 downto 0);
signal tst_dbgcs_data               : std_logic_vector(115 downto 0);
signal tst_dbgcs_data_dly           : std_logic_vector(tst_dbgcs_data'range);


signal i_fsm_ploob                 : std_logic_vector(3 downto 0);
signal i_fsm_llayer                : std_logic_vector(4 downto 0);
signal i_fsm_tlayer                : std_logic_vector(4 downto 0);

--MAIN
begin

gen_dbg_off : if strcmp(G_DBG,"OFF") generate
p_out_tst(31 downto 0)<=(others=>'0');
end generate gen_dbg_off;

gen_dbg_on : if strcmp(G_DBG,"ON") generate

tstout:process(p_in_rst,p_in_clk)
begin
  if p_in_rst='1' then
    tst_dbgcs_data_dly<=(others=>'0');
    p_out_tst(31 downto 1)<=(others=>'0');
  elsif p_in_clk'event and p_in_clk='1' then

    tst_dbgcs_data_dly<=tst_dbgcs_data;
    p_out_tst(0)<=OR_reduce(tst_dbgcs_data_dly);

  end if;
end process tstout;

end generate gen_dbg_on;

--
--m_dbgcs_icon : sata_dbgcs_icon
--port map
--(
--CONTROL0 => i_dbgcs_ctrl
--);
--
--m_dbgcs_ila : sata_dbgcs_ila
--port map
--(
--CONTROL => i_dbgcs_ctrl,
--CLK     => p_in_clk,
--DATA    => tst_dbgcs_data,
--TRIG0   => i_dbgcs_trig00
--);

--//-----------------------------
--//Инициализация
--//-----------------------------
tst_dbgcs_data(18 downto 0)<=p_in_phy_rxtype(C_TDATA_EN downto C_TALIGN);

tst_dbgcs_data(22 downto 19)<=i_fsm_ploob(3 downto 0);
tst_dbgcs_data(27 downto 23)<=i_fsm_llayer(4 downto 0);
tst_dbgcs_data(32 downto 28)<=i_fsm_tlayer(4 downto 0);

--//detect error
tst_dbgcs_data(33)<=p_in_alstatus.SError(C_ASERR_P_ERR_BIT) or
                    p_in_alstatus.SError(C_ASERR_C_ERR_BIT) or
                    p_in_alstatus.SError(C_ASERR_I_ERR_BIT) or
                    p_in_alstatus.ATAStatus(C_ATA_STATUS_ERR_BIT);


tst_dbgcs_data(34)<=p_in_alstatus.SError(C_ASERR_DET_M_BIT); --: integer:=27;--//C_PSTAT_DET_ESTABLISH_ON_BIT
tst_dbgcs_data(35)<=p_in_alstatus.SError(C_ASERR_DET_L_BIT); --: integer:=26;--//C_PSTAT_DET_DEV_ON_BIT

tst_dbgcs_data(36)<=p_in_alstatus.SError(C_ASERR_F_DIAG_BIT);--: integer:=25;--//Transport Layer:  CRC-OK, but FISTYPE/FISLEN ERROR
tst_dbgcs_data(37)<=p_in_alstatus.SError(C_ASERR_T_DIAG_BIT);--: integer:=24;--//if p_in_ll_status(C_LSTAT_RxERR_ABORT)='1' or p_in_ll_status(C_LSTAT_TxERR_ABORT)='1' then
tst_dbgcs_data(38)<=p_in_alstatus.SError(C_ASERR_S_DIAG_BIT);--: integer:=23;--//if p_in_ll_status(C_LSTAT_RxERR_IDLE)='1' or p_in_ll_status(C_LSTAT_TxERR_IDLE)='1' then
tst_dbgcs_data(39)<=p_in_alstatus.SError(C_ASERR_H_DIAG_BIT);--: integer:=22;--//Link Layer: --//1/0 - CRC ERROR on (send FIS/rcv FIS)
tst_dbgcs_data(40)<=p_in_alstatus.SError(C_ASERR_C_DIAG_BIT);--: integer:=21;--//Link Layer: --//CRC ERROR
tst_dbgcs_data(41)<=p_in_alstatus.SError(C_ASERR_D_DIAG_BIT);--: integer:=20;--//if p_in_pl_status(C_PSTAT_DET_ESTABLISH_ON_BIT)='1' and p_in_pl_status(C_PRxSTAT_ERR_DISP_BIT)='1' then
tst_dbgcs_data(42)<=p_in_alstatus.SError(C_ASERR_B_DIAG_BIT);--: integer:=19;--//if p_in_pl_status(C_PSTAT_DET_ESTABLISH_ON_BIT)='1' and p_in_pl_status(C_PRxSTAT_ERR_NOTINTABLE_BIT)='1' then


tst_dbgcs_data(43)<=p_in_dbg.player.tx.txalign;
tst_dbgcs_data(44)<=p_in_phy_txreq(0);
tst_dbgcs_data(45)<=p_in_phy_txreq(1);
tst_dbgcs_data(46)<=p_in_phy_txreq(2);
tst_dbgcs_data(47)<=p_in_phy_txreq(3);
tst_dbgcs_data(48)<=p_in_phy_txreq(4);

tst_dbgcs_data(49)<=p_in_ll_rxd_wr;
tst_dbgcs_data(81 downto 50)<=p_in_ll_rxd(31 downto 0);

tst_dbgcs_data(97 downto 82)<=p_in_gt_rxdata(15 downto 0);
tst_dbgcs_data(99 downto 98)<=p_in_gt_rxcharisk(1 downto 0);

tst_dbgcs_data(115 downto 100)<=p_in_dbg.player.tx.txd(15 downto 0);



i_dbgcs_trig00(18 downto 0)<=p_in_phy_rxtype(C_TDATA_EN downto C_TALIGN);

i_dbgcs_trig00(19)<=p_in_alstatus.SError(C_ASERR_P_ERR_BIT) or
                    p_in_alstatus.SError(C_ASERR_C_ERR_BIT) or
                    p_in_alstatus.SError(C_ASERR_I_ERR_BIT) or
                    p_in_alstatus.ATAStatus(C_ATA_STATUS_ERR_BIT);

i_dbgcs_trig00(20)<=p_in_alstatus.SError(C_ASERR_DET_M_BIT); --: integer:=27;--//C_PSTAT_DET_ESTABLISH_ON_BIT
i_dbgcs_trig00(21)<=p_in_alstatus.SError(C_ASERR_DET_L_BIT); --: integer:=26;--//C_PSTAT_DET_DEV_ON_BIT

i_dbgcs_trig00(22)<=p_in_alstatus.SError(C_ASERR_F_DIAG_BIT);--: integer:=25;--//Transport Layer:  CRC-OK, but FISTYPE/FISLEN ERROR
i_dbgcs_trig00(23)<=p_in_alstatus.SError(C_ASERR_T_DIAG_BIT);--: integer:=24;--//if p_in_ll_status(C_LSTAT_RxERR_ABORT)='1' or p_in_ll_status(C_LSTAT_TxERR_ABORT)='1' then
i_dbgcs_trig00(24)<=p_in_alstatus.SError(C_ASERR_S_DIAG_BIT);--: integer:=23;--//if p_in_ll_status(C_LSTAT_RxERR_IDLE)='1' or p_in_ll_status(C_LSTAT_TxERR_IDLE)='1' then
i_dbgcs_trig00(25)<=p_in_alstatus.SError(C_ASERR_C_DIAG_BIT);--: integer:=21;--//Link Layer: --//CRC ERROR


i_dbgcs_trig00(29 downto 26)<=i_fsm_ploob(3 downto 0);
i_dbgcs_trig00(34 downto 30)<=i_fsm_llayer(4 downto 0);
i_dbgcs_trig00(39 downto 35)<=i_fsm_tlayer(4 downto 0);



i_fsm_ploob<=CONV_STD_LOGIC_VECTOR(16#01#, i_fsm_ploob'length) when fsm_ploob_cs=S_HR_COMRESET_DONE else
             CONV_STD_LOGIC_VECTOR(16#02#, i_fsm_ploob'length) when fsm_ploob_cs=S_HR_AwaitCOMINIT else
             CONV_STD_LOGIC_VECTOR(16#03#, i_fsm_ploob'length) when fsm_ploob_cs=S_HR_COMWAKE else
             CONV_STD_LOGIC_VECTOR(16#04#, i_fsm_ploob'length) when fsm_ploob_cs=S_HR_COMWAKE_DONE else
             CONV_STD_LOGIC_VECTOR(16#05#, i_fsm_ploob'length) when fsm_ploob_cs=S_HR_AwaitCOMWAKE else
             CONV_STD_LOGIC_VECTOR(16#06#, i_fsm_ploob'length) when fsm_ploob_cs=S_HR_AwaitNoCOMWAKE else
             CONV_STD_LOGIC_VECTOR(16#07#, i_fsm_ploob'length) when fsm_ploob_cs=S_HR_AwaitAlign else
             CONV_STD_LOGIC_VECTOR(16#08#, i_fsm_ploob'length) when fsm_ploob_cs=S_HR_SendAlign else
             CONV_STD_LOGIC_VECTOR(16#09#, i_fsm_ploob'length) when fsm_ploob_cs=S_HR_Ready else
             CONV_STD_LOGIC_VECTOR(16#0A#, i_fsm_ploob'length) when fsm_ploob_cs=S_HR_COMRESET else
             CONV_STD_LOGIC_VECTOR(16#0B#, i_fsm_ploob'length) when fsm_ploob_cs=S_HR_AwaitNoCOMINIT else
             CONV_STD_LOGIC_VECTOR(16#0C#, i_fsm_ploob'length) when fsm_ploob_cs=S_HR_Calibrate else
             CONV_STD_LOGIC_VECTOR(16#00#, i_fsm_ploob'length); --//when fsm_ploob_cs=S_HR_IDLE

i_fsm_llayer<=CONV_STD_LOGIC_VECTOR(16#01#, i_fsm_llayer'length) when p_in_dbg.llayer.fsm=S_L_IDLE else
              CONV_STD_LOGIC_VECTOR(16#02#, i_fsm_llayer'length) when p_in_dbg.llayer.fsm=S_L_SyncEscape else
              CONV_STD_LOGIC_VECTOR(16#03#, i_fsm_llayer'length) when p_in_dbg.llayer.fsm=S_L_NoCommErr else
              CONV_STD_LOGIC_VECTOR(16#04#, i_fsm_llayer'length) when p_in_dbg.llayer.fsm=S_L_NoComm else
              CONV_STD_LOGIC_VECTOR(16#05#, i_fsm_llayer'length) when p_in_dbg.llayer.fsm=S_LT_H_SendChkRdy else
              CONV_STD_LOGIC_VECTOR(16#06#, i_fsm_llayer'length) when p_in_dbg.llayer.fsm=S_LT_SendSOF else
              CONV_STD_LOGIC_VECTOR(16#07#, i_fsm_llayer'length) when p_in_dbg.llayer.fsm=S_LT_SendData else
              CONV_STD_LOGIC_VECTOR(16#08#, i_fsm_llayer'length) when p_in_dbg.llayer.fsm=S_LT_SendCRC else
              CONV_STD_LOGIC_VECTOR(16#09#, i_fsm_llayer'length) when p_in_dbg.llayer.fsm=S_LT_SendEOF else
              CONV_STD_LOGIC_VECTOR(16#0A#, i_fsm_llayer'length) when p_in_dbg.llayer.fsm=S_LT_Wait else
              CONV_STD_LOGIC_VECTOR(16#0B#, i_fsm_llayer'length) when p_in_dbg.llayer.fsm=S_LT_RcvrHold else
              CONV_STD_LOGIC_VECTOR(16#0C#, i_fsm_llayer'length) when p_in_dbg.llayer.fsm=S_LT_SendHold else
              CONV_STD_LOGIC_VECTOR(16#0D#, i_fsm_llayer'length) when p_in_dbg.llayer.fsm=S_LR_RcvChkRdy else
              CONV_STD_LOGIC_VECTOR(16#0E#, i_fsm_llayer'length) when p_in_dbg.llayer.fsm=S_LR_RcvWaitFifo else
              CONV_STD_LOGIC_VECTOR(16#0F#, i_fsm_llayer'length) when p_in_dbg.llayer.fsm=S_LR_RcvData else
              CONV_STD_LOGIC_VECTOR(16#10#, i_fsm_llayer'length) when p_in_dbg.llayer.fsm=S_LR_Hold else
              CONV_STD_LOGIC_VECTOR(16#11#, i_fsm_llayer'length) when p_in_dbg.llayer.fsm=S_LR_SendHold else
              CONV_STD_LOGIC_VECTOR(16#12#, i_fsm_llayer'length) when p_in_dbg.llayer.fsm=S_LR_RcvEOF else
              CONV_STD_LOGIC_VECTOR(16#13#, i_fsm_llayer'length) when p_in_dbg.llayer.fsm=S_LR_GoodCRC else
              CONV_STD_LOGIC_VECTOR(16#14#, i_fsm_llayer'length) when p_in_dbg.llayer.fsm=S_LR_GoodEnd else
              CONV_STD_LOGIC_VECTOR(16#15#, i_fsm_llayer'length) when p_in_dbg.llayer.fsm=S_LR_BadEnd else
              CONV_STD_LOGIC_VECTOR(16#00#, i_fsm_llayer'length) ; --//when p_in_dbg.llayer.fsm=S_L_RESET else

i_fsm_tlayer<=CONV_STD_LOGIC_VECTOR(16#01#, i_fsm_tlayer'length) when p_in_dbg.tlayer.fsm=S_HT_ChkTyp else
              CONV_STD_LOGIC_VECTOR(16#02#, i_fsm_tlayer'length) when p_in_dbg.tlayer.fsm=S_HT_CmdFIS else
              CONV_STD_LOGIC_VECTOR(16#03#, i_fsm_tlayer'length) when p_in_dbg.tlayer.fsm=S_HT_CmdTransStatus else
              CONV_STD_LOGIC_VECTOR(16#04#, i_fsm_tlayer'length) when p_in_dbg.tlayer.fsm=S_HT_RegFIS else
              CONV_STD_LOGIC_VECTOR(16#05#, i_fsm_tlayer'length) when p_in_dbg.tlayer.fsm=S_HT_RegTransStatus else
              CONV_STD_LOGIC_VECTOR(16#06#, i_fsm_tlayer'length) when p_in_dbg.tlayer.fsm=S_HT_PS_FIS else
              CONV_STD_LOGIC_VECTOR(16#07#, i_fsm_tlayer'length) when p_in_dbg.tlayer.fsm=S_HT_PIOOTrans1 else
              CONV_STD_LOGIC_VECTOR(16#08#, i_fsm_tlayer'length) when p_in_dbg.tlayer.fsm=S_HT_PIOOTrans2 else
              CONV_STD_LOGIC_VECTOR(16#09#, i_fsm_tlayer'length) when p_in_dbg.tlayer.fsm=S_HT_PIOEnd else
              CONV_STD_LOGIC_VECTOR(16#0A#, i_fsm_tlayer'length) when p_in_dbg.tlayer.fsm=S_HT_PIOITrans1 else
              CONV_STD_LOGIC_VECTOR(16#0B#, i_fsm_tlayer'length) when p_in_dbg.tlayer.fsm=S_HT_PIOITrans2 else
              CONV_STD_LOGIC_VECTOR(16#0C#, i_fsm_tlayer'length) when p_in_dbg.tlayer.fsm=S_HT_DMA_FIS else
              CONV_STD_LOGIC_VECTOR(16#0D#, i_fsm_tlayer'length) when p_in_dbg.tlayer.fsm=S_HT_DMAOTrans1 else
              CONV_STD_LOGIC_VECTOR(16#0E#, i_fsm_tlayer'length) when p_in_dbg.tlayer.fsm=S_HT_DMAOTrans2 else
              CONV_STD_LOGIC_VECTOR(16#0F#, i_fsm_tlayer'length) when p_in_dbg.tlayer.fsm=S_HT_DMAEnd else
              CONV_STD_LOGIC_VECTOR(16#10#, i_fsm_tlayer'length) when p_in_dbg.tlayer.fsm=S_HT_DMAITrans else
              CONV_STD_LOGIC_VECTOR(16#11#, i_fsm_tlayer'length) when p_in_dbg.tlayer.fsm=S_HT_DmaSetupFIS else
              CONV_STD_LOGIC_VECTOR(16#12#, i_fsm_tlayer'length) when p_in_dbg.tlayer.fsm=S_HT_DmaSetupTransStatus else
              CONV_STD_LOGIC_VECTOR(16#13#, i_fsm_tlayer'length) when p_in_dbg.tlayer.fsm=S_HT_DS_FIS else
              CONV_STD_LOGIC_VECTOR(16#14#, i_fsm_tlayer'length) when p_in_dbg.tlayer.fsm=S_HT_CtrlFIS else
              CONV_STD_LOGIC_VECTOR(16#15#, i_fsm_tlayer'length) when p_in_dbg.tlayer.fsm=S_HT_CtrlTransStatus else
              CONV_STD_LOGIC_VECTOR(16#16#, i_fsm_tlayer'length) when p_in_dbg.tlayer.fsm=S_HT_DB_FIS else
              CONV_STD_LOGIC_VECTOR(16#17#, i_fsm_tlayer'length) when p_in_dbg.tlayer.fsm=S_HT_Dev_Bits else
              CONV_STD_LOGIC_VECTOR(16#18#, i_fsm_tlayer'length) when p_in_dbg.tlayer.fsm=S_HT_RcvBIST else
              CONV_STD_LOGIC_VECTOR(16#19#, i_fsm_tlayer'length) when p_in_dbg.tlayer.fsm=S_HT_BISTTrans1 else
              CONV_STD_LOGIC_VECTOR(16#00#, i_fsm_tlayer'length) ; --//when p_in_dbg.tlayer.fsm=S_IDLE else




--END MAIN
end behavioral;

