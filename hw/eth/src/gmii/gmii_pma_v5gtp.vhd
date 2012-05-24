-------------------------------------------------------------------------
-- Company     : Linkos
-- Engineer    : Golovachenko Victor
--
-- Create Date : 22.05.2012 11:55:44
-- Module Name : gmii_pma
--
-- Назначение/Описание :
--
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
use work.gmii_pkg.all;

entity gmii_pma is
generic(
G_GT_NUM      : integer:=0;
G_GT_CH_COUNT : integer:=2;
G_GT_DBUS     : integer:=8;
G_SIM         : string :="OFF"
);
port(
---------------------------------------------------------------------------
--Usr Cfg
---------------------------------------------------------------------------
--p_in_sys_dcm_gclk2div  : in    std_logic;--//dcm_clk0 /2
--p_in_sys_dcm_gclk      : in    std_logic;--//dcm_clk0
--p_in_sys_dcm_gclk2x    : in    std_logic;--//dcm_clk0 x 2

p_out_usrclk2          : out   std_logic_vector(C_GTCH_COUNT_MAX-1 downto 0); --//Тактирование модулей sata_host.vhd
p_out_resetdone        : out   std_logic_vector(C_GTCH_COUNT_MAX-1 downto 0);

---------------------------------------------------------------------------
--Driver(Сигналы подоваемые на разъем)
---------------------------------------------------------------------------
p_out_txn              : out   std_logic_vector(C_GTCH_COUNT_MAX-1 downto 0);
p_out_txp              : out   std_logic_vector(C_GTCH_COUNT_MAX-1 downto 0);
p_in_rxn               : in    std_logic_vector(C_GTCH_COUNT_MAX-1 downto 0);
p_in_rxp               : in    std_logic_vector(C_GTCH_COUNT_MAX-1 downto 0);

---------------------------------------------------------------------------
--Tranceiver
---------------------------------------------------------------------------
p_in_txdata            : in    TBus32_GTCH;                                   --//поток данных для передатчика DUAL_GTP
p_in_txcharisk         : in    TBus04_GTCH;                                   --//признак наличия упр.символов на порту txdata
p_in_txchadipmode      : in    TBus02_GTCH;
p_in_txchadipval       : in    TBus02_GTCH;

p_in_txreset           : in    std_logic_vector(C_GTCH_COUNT_MAX-1 downto 0); --//Сброс передатчика
p_out_txbufstatus      : out   TBus02_GTCH;

---------------------------------------------------------------------------
--Receiver
---------------------------------------------------------------------------
p_in_rxreset           : in    std_logic_vector(C_GTCH_COUNT_MAX-1 downto 0); --//Сброс GT RxPCS
p_out_rxstatus         : out   TBus03_GTCH;                                   --//Тип обнаруженного OOB сигнала
p_out_rxdata           : out   TBus32_GTCH;                                   --//поток данных от приемника DUAL_GTP
p_out_rxcharisk        : out   TBus04_GTCH;                                   --//признак наличия упр.символов в rxdata
p_out_rxdisperr        : out   TBus04_GTCH;                                   --//Ошибка паритета в принятом данном
p_out_rxnotintable     : out   TBus04_GTCH;                                   --//
p_out_rxbyteisaligned  : out   std_logic_vector(C_GTCH_COUNT_MAX-1 downto 0); --//Данные выровнены по байтам

p_in_rxbufreset        : in    std_logic_vector(C_GTCH_COUNT_MAX-1 downto 0);
p_out_rxbufstatus      : out   TBus03_GTCH;

----------------------------------------------------------------------------
--System
----------------------------------------------------------------------------
--Порт динамическаго конфигурирования DUAL_GTP
p_in_drpclk            : in    std_logic;
p_in_drpaddr           : in    std_logic_vector(7 downto 0);
p_in_drpen             : in    std_logic;
p_in_drpwe             : in    std_logic;
p_in_drpdi             : in    std_logic_vector(15 downto 0);
p_out_drpdo            : out   std_logic_vector(15 downto 0);
p_out_drprdy           : out   std_logic;

p_out_plllock          : out   std_logic;--//Захват частоты PLL DUAL_GTP
p_out_refclkout        : out   std_logic;--//Фактически дублирование p_in_refclkin. см. стр.68. ug196.pdf

p_in_refclkin          : in    std_logic;--//Опорнач частоа для работы DUAL_GTP

--p_in_optrefclksel      : in    std_logic_vector(3 downto 0);
--p_in_optrefclk         : in    std_logic_vector(3 downto 0);
--p_out_optrefclk        : out   std_logic_vector(3 downto 0);

p_in_rst               : in    std_logic
);
end gmii_pma;

architecture behavioral of gmii_pma is

--//1 - только для случая G_GT_DBUS=8
--//2 - для всех других случаев. Выравниваение по чётной границе. см Figure 7-15: Comma Alignment Boundaries ,
--      ug196_Virtex-5 FPGA RocketIO GTP Transceiver User Guide.pdf
constant CI_PLL_DIV                : integer := 2;
constant CI_GTP_ALIGN_COMMA_WORD   : integer := 1;
constant CI_GTP_DATAWIDTH          : std_logic_vector(0 downto 0):=CONV_STD_LOGIC_VECTOR(selval(0, 1, cmpval(G_GT_DBUS, 8)), 1);
constant CI_8B10BUSE               : std_logic:='1';--0/1 - bypassed/enabled for 8B/10B decoder(encoder)
constant CI_INTDATAWIDTH           : std_logic:='1';--Подробнее см.стр.190 в ug196.pdf

signal i_rxenelecidleresetb        : std_logic;
signal i_rxelecidle                : std_logic_vector(C_GTCH_COUNT_MAX-1 downto 0);
signal i_resetdone                 : std_logic_vector(C_GTCH_COUNT_MAX-1 downto 0);
signal i_rxelecidlereset           : std_logic_vector(C_GTCH_COUNT_MAX-1 downto 0);

signal i_refclkout                 : std_logic;
signal g_gtp_usrclk                : std_logic_vector(C_GTCH_COUNT_MAX-1 downto 0);
signal g_gtp_usrclk2               : std_logic_vector(C_GTCH_COUNT_MAX-1 downto 0);

signal i_txdata_in                 : TBus32_GTCH;
signal i_txcharisk_in              : TBus04_GTCH;
signal i_txchadipmode_in           : TBus02_GTCH;
signal i_txchadipval_in            : TBus02_GTCH;

signal i_txreset_in                : std_logic_vector(C_GTCH_COUNT_MAX-1 downto 0);
signal i_txbufstatus_out           : TBus02_GTCH;

signal i_rxreset_in                : std_logic_vector(C_GTCH_COUNT_MAX-1 downto 0);

signal i_rxstatus_out              : TBus03_GTCH;
signal i_rxdata_out                : TBus32_GTCH;
signal i_rxcharisk_out             : TBus04_GTCH;
signal i_rxdisperr_out             : TBus04_GTCH;
signal i_rxnotintable_out          : TBus04_GTCH;
signal i_rxbyteisaligned_out       : std_logic_vector(C_GTCH_COUNT_MAX-1 downto 0);

signal i_rxbufreset_in             : std_logic_vector(C_GTCH_COUNT_MAX-1 downto 0);
signal i_rxbufstatus_out           : TBus03_GTCH;


--attribute keep : string;
--attribute keep of g_gtp_usrclk2 : signal is "true";

--MAIN
begin

--assert G_GT_DBUS>16
--    report "*** sata_player_gt(sata_player_v5gtp.vhd) : illegal values of G_GT_DBUS " & CONV_STRING(G_GT_DBUS)
--    severity failure;


gen_null : for i in 0 to C_GTCH_COUNT_MAX-1 generate
p_out_rxdata(i)(31 downto 16)<=(others=>'0');
p_out_rxcharisk(i)(3 downto 2)<=(others=>'0');
p_out_rxdisperr(i)(3 downto 2)<=(others=>'0');
p_out_rxnotintable(i)(3 downto 2)<=(others=>'0');
end generate gen_null;


gen_gt_ch1 : if G_GT_CH_COUNT=1 generate
i_txdata_in(1)(15 downto 0)  <=(others=>'0');
i_txcharisk_in(1)(1 downto 0)<=(others=>'0');

i_txreset_in(1)         <='0';
p_out_txbufstatus(1)    <=(others=>'0');

i_rxreset_in(1)         <='0';
--p_out_rxelecidle(1)     <='0';
p_out_rxstatus(1)       <=(others=>'0');
p_out_rxdata(1)(15 downto 0)     <=(others=>'0');
p_out_rxcharisk(1)(1 downto 0)   <=(others=>'0');
p_out_rxdisperr(1)(1 downto 0)   <=(others=>'0');
p_out_rxnotintable(1)(1 downto 0)<=(others=>'0');
p_out_rxbyteisaligned(1)<='0';

i_rxbufreset_in(1)      <='0';
p_out_rxbufstatus(1)    <=(others=>'0');


g_gtp_usrclk(1) <=g_gtp_usrclk(0);
g_gtp_usrclk2(1)<=g_gtp_usrclk2(0);

p_out_usrclk2(1)<=g_gtp_usrclk2(0);
p_out_resetdone(1)<='1';

end generate gen_gt_ch1;


--#########################################
--//Выбор тактовых частот для работы SATA
--#########################################
gen_ch : for i in 0 to G_GT_CH_COUNT-1 generate

--//------------------------------
--//GT: ШИНА ДАНЫХ=8bit
--//------------------------------
gen_gt_w8 : if G_GT_DBUS=8 generate
g_gtp_usrclk2(i)<=i_refclkout;--p_in_sys_dcm_gclk;
g_gtp_usrclk(i)<=g_gtp_usrclk2(i);
end generate gen_gt_w8;

----//------------------------------
----//GT: ШИНА ДАНЫХ=32bit
----//------------------------------
--gen_gt_w32 : if G_GT_DBUS=32 generate
--
--end generate gen_gt_w32;


--//------------------------------
p_out_usrclk2(i)<=g_gtp_usrclk2(i);

process(g_gtp_usrclk2(i))
begin
  if g_gtp_usrclk2(i)'event and g_gtp_usrclk2(i)='1' then
      p_out_resetdone(i)      <=i_resetdone(i);

      i_txdata_in(i)(15 downto 0)  <=p_in_txdata(i)(15 downto 0);
      i_txcharisk_in(i)(1 downto 0)<=p_in_txcharisk(i)(1 downto 0);
      i_txchadipmode_in(i)<=p_in_txchadipmode(i);
      i_txchadipval_in(i) <=p_in_txchadipval(i);

      i_txreset_in(i)         <=p_in_txreset(i);
      p_out_txbufstatus(i)    <=i_txbufstatus_out(i);

      i_rxreset_in(i)         <=p_in_rxreset(i);
--      p_out_rxelecidle(i)     <=i_rxelecidle(i);
      p_out_rxstatus(i)       <=i_rxstatus_out(i);

      p_out_rxdata(i)(15 downto 0)     <=i_rxdata_out(i)(15 downto 0);
      p_out_rxcharisk(i)(1 downto 0)   <=i_rxcharisk_out(i)(1 downto 0);
      p_out_rxdisperr(i)(1 downto 0)   <=i_rxdisperr_out(i)(1 downto 0);
      p_out_rxnotintable(i)(1 downto 0)<=i_rxnotintable_out(i)(1 downto 0);
      p_out_rxbyteisaligned(i)         <=i_rxbyteisaligned_out(i);

      i_rxbufreset_in(i)      <=p_in_rxbufreset(i);
      p_out_rxbufstatus(i)    <=i_rxbufstatus_out(i);
  end if;
end process;

i_rxelecidlereset(i)<=i_rxelecidle(i) and i_resetdone(i);

end generate gen_ch;


p_out_refclkout<=g_gtp_usrclk2(0);

--//###########################
--//Gig Tx/Rx
--//###########################
--p_out_optrefclk<=(others=>'0');

i_rxenelecidleresetb <= not (OR_reduce(i_rxelecidlereset(G_GT_CH_COUNT-1 downto 0)));

m_gt : GTP_DUAL
generic map(

--Simulation-Only Attributes
SIM_MODE                    => G_SIM,
SIM_GTPRESET_SPEEDUP        => 1,
SIM_PLL_PERDIV2             => x"14d",
SIM_RECEIVER_DETECT_PASS0   => TRUE,
SIM_RECEIVER_DETECT_PASS1   => TRUE,

--PRBS Detection Attributes
PRBS_ERR_THRESHOLD_0        => x"00000001",
PRBS_ERR_THRESHOLD_1        => x"00000001",

--Tile and PLL Attributes
CLK25_DIVIDER               => 5,
CLKINDC_B                   => TRUE,
OOB_CLK_DIVIDER             => 4,
OVERSAMPLE_MODE             => FALSE,
PLL_DIVSEL_FB               => 2,
PLL_DIVSEL_REF              => 1,
PLL_TXDIVSEL_COMM_OUT       => 1,
TX_SYNC_FILTERB             => 1,

PLL_TXDIVSEL_OUT_0          => CI_PLL_DIV,
PLL_TXDIVSEL_OUT_1          => CI_PLL_DIV,

PLL_RXDIVSEL_OUT_0          => CI_PLL_DIV,
PLL_RXDIVSEL_OUT_1          => CI_PLL_DIV,

PLL_SATA_0                  => FALSE,
PLL_SATA_1                  => FALSE,

--Channel Bonding Attributes
CHAN_BOND_1_MAX_SKEW_0      => 1,
CHAN_BOND_2_MAX_SKEW_0      => 1,
CHAN_BOND_LEVEL_0           => 0,
CHAN_BOND_MODE_0            => "OFF",
CHAN_BOND_SEQ_1_1_0         => "0000000000",
CHAN_BOND_SEQ_1_2_0         => "0000000000",
CHAN_BOND_SEQ_1_3_0         => "0000000000",
CHAN_BOND_SEQ_1_4_0         => "0000000000",
CHAN_BOND_SEQ_1_ENABLE_0    => "0000",
CHAN_BOND_SEQ_2_1_0         => "0000000000",
CHAN_BOND_SEQ_2_2_0         => "0000000000",
CHAN_BOND_SEQ_2_3_0         => "0000000000",
CHAN_BOND_SEQ_2_4_0         => "0000000000",
CHAN_BOND_SEQ_2_ENABLE_0    => "0000",
CHAN_BOND_SEQ_2_USE_0       => FALSE,
CHAN_BOND_SEQ_LEN_0         => 1,
PCI_EXPRESS_MODE_0          => FALSE,

CHAN_BOND_1_MAX_SKEW_1      => 1,
CHAN_BOND_2_MAX_SKEW_1      => 1,
CHAN_BOND_LEVEL_1           => 0,
CHAN_BOND_MODE_1            => "OFF",
CHAN_BOND_SEQ_1_1_1         => "0000000000",
CHAN_BOND_SEQ_1_2_1         => "0000000000",
CHAN_BOND_SEQ_1_3_1         => "0000000000",
CHAN_BOND_SEQ_1_4_1         => "0000000000",
CHAN_BOND_SEQ_1_ENABLE_1    => "0000",
CHAN_BOND_SEQ_2_1_1         => "0000000000",
CHAN_BOND_SEQ_2_2_1         => "0000000000",
CHAN_BOND_SEQ_2_3_1         => "0000000000",
CHAN_BOND_SEQ_2_4_1         => "0000000000",
CHAN_BOND_SEQ_2_ENABLE_1    => "0000",
CHAN_BOND_SEQ_2_USE_1       => FALSE,
CHAN_BOND_SEQ_LEN_1         => 1,
PCI_EXPRESS_MODE_1          => FALSE,

--RX Loss-of-sync State Machine Attributes
RX_LOSS_OF_SYNC_FSM_0       => FALSE,
RX_LOS_INVALID_INCR_0       => 8,
RX_LOS_THRESHOLD_0          => 128,

RX_LOSS_OF_SYNC_FSM_1       => FALSE,
RX_LOS_INVALID_INCR_1       => 8,
RX_LOS_THRESHOLD_1          => 128,

--TX Driver and OOB signalling Attributes
TX_DIFF_BOOST_0             => TRUE,
TX_DIFF_BOOST_1             => TRUE,

--TX Buffering and Phase Alignment Attributes
TX_BUFFER_USE_0             => TRUE,
TX_XCLK_SEL_0               => "TXOUT",
TXRX_INVERT_0               => "00000",

TX_BUFFER_USE_1             => TRUE,
TX_XCLK_SEL_1               => "TXOUT",
TXRX_INVERT_1               => "00000",

--Comma Detection and Alignment Attributes
ALIGN_COMMA_WORD_0          => CI_GTP_ALIGN_COMMA_WORD,
COMMA_10B_ENABLE_0          => "0001111111",
COMMA_DOUBLE_0              => FALSE,
DEC_MCOMMA_DETECT_0         => TRUE,
DEC_PCOMMA_DETECT_0         => TRUE,
DEC_VALID_COMMA_ONLY_0      => FALSE,
MCOMMA_10B_VALUE_0          => "1010000011",
MCOMMA_DETECT_0             => TRUE,
PCOMMA_10B_VALUE_0          => "0101111100",
PCOMMA_DETECT_0             => TRUE,
RX_SLIDE_MODE_0             => "PCS",

ALIGN_COMMA_WORD_1          => CI_GTP_ALIGN_COMMA_WORD,
COMMA_10B_ENABLE_1          => "0001111111",
COMMA_DOUBLE_1              => FALSE,
DEC_MCOMMA_DETECT_1         => TRUE,
DEC_PCOMMA_DETECT_1         => TRUE,
DEC_VALID_COMMA_ONLY_1      => FALSE,
MCOMMA_10B_VALUE_1          => "1010000011",
MCOMMA_DETECT_1             => TRUE,
PCOMMA_10B_VALUE_1          => "0101111100",
PCOMMA_DETECT_1             => TRUE,
RX_SLIDE_MODE_1             => "PCS",

--RX Elastic Buffer and Phase alignment Attributes
RX_BUFFER_USE_0             => TRUE,
RX_XCLK_SEL_0               => "RXREC",

RX_BUFFER_USE_1             => TRUE,
RX_XCLK_SEL_1               => "RXREC",

--Clock Correction Attributes
CLK_CORRECT_USE_0           => TRUE,
CLK_COR_ADJ_LEN_0           => 2,
CLK_COR_DET_LEN_0           => 2,
CLK_COR_INSERT_IDLE_FLAG_0  => FALSE,
CLK_COR_KEEP_IDLE_0         => FALSE,
CLK_COR_MAX_LAT_0           => 18,
CLK_COR_MIN_LAT_0           => 16,
CLK_COR_PRECEDENCE_0        => TRUE,
CLK_COR_REPEAT_WAIT_0       => 0,
CLK_COR_SEQ_1_1_0           => "0110111100",
CLK_COR_SEQ_1_2_0           => "0001010000",
CLK_COR_SEQ_1_3_0           => "0000000000",
CLK_COR_SEQ_1_4_0           => "0000000000",
CLK_COR_SEQ_1_ENABLE_0      => "0011",
CLK_COR_SEQ_2_1_0           => "0110111100",
CLK_COR_SEQ_2_2_0           => "0010110101",
CLK_COR_SEQ_2_3_0           => "0000000000",
CLK_COR_SEQ_2_4_0           => "0000000000",
CLK_COR_SEQ_2_ENABLE_0      => "0011",
CLK_COR_SEQ_2_USE_0         => TRUE,
RX_DECODE_SEQ_MATCH_0       => TRUE,

CLK_CORRECT_USE_1           => TRUE,
CLK_COR_ADJ_LEN_1           => 2,
CLK_COR_DET_LEN_1           => 2,
CLK_COR_INSERT_IDLE_FLAG_1  => FALSE,
CLK_COR_KEEP_IDLE_1         => FALSE,
CLK_COR_MAX_LAT_1           => 18,
CLK_COR_MIN_LAT_1           => 16,
CLK_COR_PRECEDENCE_1        => TRUE,
CLK_COR_REPEAT_WAIT_1       => 0,
CLK_COR_SEQ_1_1_1           => "0110111100",
CLK_COR_SEQ_1_2_1           => "0001010000",
CLK_COR_SEQ_1_3_1           => "0000000000",
CLK_COR_SEQ_1_4_1           => "0000000000",
CLK_COR_SEQ_1_ENABLE_1      => "0011",
CLK_COR_SEQ_2_1_1           => "0110111100",
CLK_COR_SEQ_2_2_1           => "0010110101",
CLK_COR_SEQ_2_3_1           => "0000000000",
CLK_COR_SEQ_2_4_1           => "0000000000",
CLK_COR_SEQ_2_ENABLE_1      => "0011",
CLK_COR_SEQ_2_USE_1         => TRUE,
RX_DECODE_SEQ_MATCH_1       => TRUE,

--RX Driver,OOB signalling,Coupling and Eq,CDR Attributes
AC_CAP_DIS_0                => TRUE,
PMA_CDR_SCAN_0              => x"6c07640",
PMA_RX_CFG_0                => x"09f0088",
RCV_TERM_GND_0              => FALSE,
RCV_TERM_MID_0              => FALSE,
RCV_TERM_VTTRX_0            => FALSE,
TERMINATION_IMP_0           => 50,

AC_CAP_DIS_1                => TRUE,
PMA_CDR_SCAN_1              => x"6c07640",
PMA_RX_CFG_1                => x"09f0088",
RCV_TERM_GND_1              => FALSE,
RCV_TERM_MID_1              => FALSE,
RCV_TERM_VTTRX_1            => FALSE,
TERMINATION_IMP_1           => 50,

PCS_COM_CFG                 => x"1680a0e",
TERMINATION_CTRL            => "10100",
TERMINATION_OVRD            => FALSE,

--RX Attributes for PCI Express/SATA Attributes
OOBDETECT_THRESHOLD_0       => "001",
COM_BURST_VAL_0             => "1111",
RX_STATUS_FMT_0             => "PCIE",
SATA_BURST_VAL_0            => "100",
SATA_IDLE_VAL_0             => "100",
SATA_MAX_BURST_0            => 9,
SATA_MAX_INIT_0             => 27,
SATA_MAX_WAKE_0             => 9,
SATA_MIN_BURST_0            => 5,
SATA_MIN_INIT_0             => 15,
SATA_MIN_WAKE_0             => 5,
TRANS_TIME_FROM_P2_0        => x"0060",
TRANS_TIME_NON_P2_0         => x"0025",
TRANS_TIME_TO_P2_0          => x"0100",

OOBDETECT_THRESHOLD_1       => "001",
COM_BURST_VAL_1             => "1111",
RX_STATUS_FMT_1             => "PCIE",
SATA_BURST_VAL_1            => "100",
SATA_IDLE_VAL_1             => "100",
SATA_MAX_BURST_1            => 9,
SATA_MAX_INIT_1             => 27,
SATA_MAX_WAKE_1             => 9,
SATA_MIN_BURST_1            => 5,
SATA_MIN_INIT_1             => 15,
SATA_MIN_WAKE_1             => 5,
TRANS_TIME_FROM_P2_1        => x"0060",
TRANS_TIME_NON_P2_1         => x"0025",
TRANS_TIME_TO_P2_1          => x"0100"
)
port map(
------- Loopback and Powerdown Ports -------
LOOPBACK0                   => "000",
LOOPBACK1                   => "000",
RXPOWERDOWN0                => "00",
RXPOWERDOWN1                => "00",
TXPOWERDOWN0                => "00",
TXPOWERDOWN1                => "00",
------- Receive Ports - 8b10b Decoder -------
RXCHARISCOMMA0              => open,
RXCHARISCOMMA1              => open,
RXCHARISK0                  => i_rxcharisk_out(0)(1 downto 0),
RXCHARISK1                  => i_rxcharisk_out(1)(1 downto 0),
RXDEC8B10BUSE0              => CI_8B10BUSE,
RXDEC8B10BUSE1              => CI_8B10BUSE,
RXDISPERR0                  => i_rxdisperr_out(0)(1 downto 0),
RXDISPERR1                  => i_rxdisperr_out(1)(1 downto 0),
RXNOTINTABLE0               => i_rxnotintable_out(0)(1 downto 0),
RXNOTINTABLE1               => i_rxnotintable_out(1)(1 downto 0),
RXRUNDISP0                  => open,
RXRUNDISP1                  => open,
------- Receive Ports - Channel Bonding Ports -------
RXCHANBONDSEQ0              => open,
RXCHANBONDSEQ1              => open,
RXCHBONDI0                  => "000",
RXCHBONDI1                  => "000",
RXCHBONDO0                  => open,
RXCHBONDO1                  => open,
RXENCHANSYNC0               => '0',
RXENCHANSYNC1               => '0',
------- Receive Ports - Clock Correction Ports -------
RXCLKCORCNT0                => open,
RXCLKCORCNT1                => open,
------- Receive Ports - Comma Detection and Alignment -------
RXBYTEISALIGNED0            => i_rxbyteisaligned_out(0),
RXBYTEISALIGNED1            => i_rxbyteisaligned_out(1),
RXBYTEREALIGN0              => open,
RXBYTEREALIGN1              => open,
RXCOMMADET0                 => open,
RXCOMMADET1                 => open,
RXCOMMADETUSE0              => '1',
RXCOMMADETUSE1              => '1',
RXENMCOMMAALIGN0            => '1',
RXENMCOMMAALIGN1            => '1',
RXENPCOMMAALIGN0            => '1',
RXENPCOMMAALIGN1            => '1',
RXSLIDE0                    => '0',
RXSLIDE1                    => '0',
------- Receive Ports - PRBS Detection -------
PRBSCNTRESET0               => '0',
PRBSCNTRESET1               => '0',
RXENPRBSTST0                => "00",
RXENPRBSTST1                => "00",
RXPRBSERR0                  => open,
RXPRBSERR1                  => open,
------- Receive Ports - RX Data Path interface -------
RXDATA0                     => i_rxdata_out(0)(15 downto 0),
RXDATA1                     => i_rxdata_out(1)(15 downto 0),
RXDATAWIDTH0                => CI_GTP_DATAWIDTH(0),
RXDATAWIDTH1                => CI_GTP_DATAWIDTH(0),
RXRECCLK0                   => open,
RXRECCLK1                   => open,
RXRESET0                    => i_rxreset_in(0),
RXRESET1                    => i_rxreset_in(1),
RXUSRCLK0                   => g_gtp_usrclk(0),
RXUSRCLK1                   => g_gtp_usrclk(1),
RXUSRCLK20                  => g_gtp_usrclk2(0),
RXUSRCLK21                  => g_gtp_usrclk2(1),
------- Receive Ports - RX Driver,OOB signalling,Coupling and Eq.,CDR -------
RXCDRRESET0                 => '0',
RXCDRRESET1                 => '0',
RXELECIDLE0                 => i_rxelecidle(0),
RXELECIDLE1                 => i_rxelecidle(1),
RXELECIDLERESET0            => i_rxelecidlereset(0),
RXELECIDLERESET1            => i_rxelecidlereset(1),
RXENEQB0                    => '1',
RXENEQB1                    => '1',
RXEQMIX0                    => "00",
RXEQMIX1                    => "00",
RXEQPOLE0                   => "0000",
RXEQPOLE1                   => "0000",
RXN0                        => p_in_rxn(0),
RXN1                        => p_in_rxn(1),
RXP0                        => p_in_rxp(0),
RXP1                        => p_in_rxp(1),
------- Receive Ports - RX Elastic Buffer and Phase Alignment Ports -------
RXBUFRESET0                 => i_rxbufreset_in(0),
RXBUFRESET1                 => i_rxbufreset_in(1),
RXBUFSTATUS0                => i_rxbufstatus_out(0),
RXBUFSTATUS1                => i_rxbufstatus_out(1),
RXCHANISALIGNED0            => open,
RXCHANISALIGNED1            => open,
RXCHANREALIGN0              => open,
RXCHANREALIGN1              => open,
RXPMASETPHASE0              => '0',
RXPMASETPHASE1              => '0',
RXSTATUS0                   => i_rxstatus_out(0),
RXSTATUS1                   => i_rxstatus_out(1),
------- Receive Ports - RX Loss-of-sync State Machine -------
RXLOSSOFSYNC0               => open,
RXLOSSOFSYNC1               => open,
------- Receive Ports - RX Oversampling -------
RXENSAMPLEALIGN0            => '0',
RXENSAMPLEALIGN1            => '0',
RXOVERSAMPLEERR0            => open,
RXOVERSAMPLEERR1            => open,
------- Receive Ports - RX Pipe Control for PCI Express -------------
PHYSTATUS0                  => open,
PHYSTATUS1                  => open,
RXVALID0                    => open,
RXVALID1                    => open,
------- Receive Ports - RX Polarity Control Ports -------
RXPOLARITY0                 => '0',
RXPOLARITY1                 => '0',
------- Shared Ports - Dynamic Reconfiguration Port (DRP) -------
DADDR                       => p_in_drpaddr(6 downto 0),
DCLK                        => p_in_drpclk,
DEN                         => p_in_drpen,
DI                          => p_in_drpdi,
DO                          => p_out_drpdo,
DRDY                        => p_out_drprdy,
DWE                         => p_in_drpwe,
------- Shared Ports - Tile and PLL Ports -------
CLKIN                       => p_in_refclkin,
GTPRESET                    => p_in_rst,
GTPTEST                     => "0000",
INTDATAWIDTH                => CI_INTDATAWIDTH,
PLLLKDET                    => p_out_plllock,
PLLLKDETEN                  => '1',
PLLPOWERDOWN                => '0',
REFCLKOUT                   => i_refclkout,--p_out_refclkout,
REFCLKPWRDNB                => '1',
RESETDONE0                  => i_resetdone(0),
RESETDONE1                  => i_resetdone(1),
RXENELECIDLERESETB          => i_rxenelecidleresetb,--'1',
TXENPMAPHASEALIGN           => '0',
TXPMASETPHASE               => '0',
------- Transmit Ports - 8b10b Encoder Control Ports -------
TXBYPASS8B10B0              => "00",
TXBYPASS8B10B1              => "00",
TXCHARDISPMODE0             => i_txchadipmode_in(0)(1 downto 0),--(0x)
TXCHARDISPMODE1             => i_txchadipmode_in(1)(1 downto 0),--(0x)
TXCHARDISPVAL0              => i_txchadipval_in(0)(1 downto 0),--(0x)
TXCHARDISPVAL1              => i_txchadipval_in(1)(1 downto 0),--(0x)
TXCHARISK0                  => i_txcharisk_in(0)(1 downto 0),
TXCHARISK1                  => i_txcharisk_in(1)(1 downto 0),
TXENC8B10BUSE0              => CI_8B10BUSE,
TXENC8B10BUSE1              => CI_8B10BUSE,
TXKERR0                     => open,
TXKERR1                     => open,
TXRUNDISP0                  => open,
TXRUNDISP1                  => open,
------- Transmit Ports - TX Buffering and Phase Alignment -------
TXBUFSTATUS0                => i_txbufstatus_out(0),
TXBUFSTATUS1                => i_txbufstatus_out(1),
------- Transmit Ports - TX Data Path interface -------
TXDATA0                     => i_txdata_in(0)(15 downto 0),
TXDATA1                     => i_txdata_in(1)(15 downto 0),
TXDATAWIDTH0                => CI_GTP_DATAWIDTH(0),
TXDATAWIDTH1                => CI_GTP_DATAWIDTH(0),
TXOUTCLK0                   => open,
TXOUTCLK1                   => open,
TXRESET0                    => i_txreset_in(0),
TXRESET1                    => i_txreset_in(1),
TXUSRCLK0                   => g_gtp_usrclk(0),
TXUSRCLK1                   => g_gtp_usrclk(1),
TXUSRCLK20                  => g_gtp_usrclk2(0),
TXUSRCLK21                  => g_gtp_usrclk2(1),
------- Transmit Ports - TX Driver and OOB signalling -------
TXBUFDIFFCTRL0              => "000",
TXBUFDIFFCTRL1              => "000",
TXDIFFCTRL0                 => "000",
TXDIFFCTRL1                 => "000",
TXINHIBIT0                  => '0',
TXINHIBIT1                  => '0',
TXN0                        => p_out_txn(0),
TXN1                        => p_out_txn(1),
TXP0                        => p_out_txp(0),
TXP1                        => p_out_txp(1),
TXPREEMPHASIS0              => "000",
TXPREEMPHASIS1              => "000",
------- Transmit Ports - TX PRBS Generator -------
TXENPRBSTST0                => "00",
TXENPRBSTST1                => "00",
------- Transmit Ports - TX Polarity Control -------
TXPOLARITY0                 => '0',
TXPOLARITY1                 => '0',
------- Transmit Ports - TX Ports for PCI Express -------
TXDETECTRX0                 => '0',
TXDETECTRX1                 => '0',
TXELECIDLE0                 => '0',
TXELECIDLE1                 => '0',
------- Transmit Ports - TX Ports for SATA -------
TXCOMSTART0                 => '0',
TXCOMSTART1                 => '0',
TXCOMTYPE0                  => '0',
TXCOMTYPE1                  => '0'

);

--END MAIN
end behavioral;

