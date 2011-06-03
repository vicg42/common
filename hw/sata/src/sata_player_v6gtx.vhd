-------------------------------------------------------------------------
-- Company     : Linkos
-- Engineer    : Golovachenko Victor
--
-- Create Date : 03.04.2011 11:49:15
-- Module Name : sata_player_gt
--
-- Назначение/Описание :
--   1. Связь компонента GTX(gig tx/rx) c sata_host.vhd
--
-- Revision:
-- Revision 0.01 - File Created
--
--------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_arith.all;

library unisim;
use unisim.vcomponents.all;

library work;
use work.vicg_common_pkg.all;
use work.sata_pkg.all;

entity sata_player_gt is
generic
(
G_GT_CH_COUNT: integer := 2;
G_GT_DBUS    : integer := 16;
G_SIM        : string  := "OFF"
);
port
(
---------------------------------------------------------------------------
--Usr Cfg
---------------------------------------------------------------------------
p_in_spd               : in    TSpdCtrl_GTCH;
p_in_sys_dcm_gclk2div  : in    std_logic;--//dcm_clk0 /2
p_in_sys_dcm_gclk      : in    std_logic;--//dcm_clk0
p_in_sys_dcm_gclk2x    : in    std_logic;--//dcm_clk0 x 2

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
p_in_txelecidle        : in    std_logic_vector(C_GTCH_COUNT_MAX-1 downto 0); --//Разрешение передачи OOB сигналов
p_in_txcomstart        : in    std_logic_vector(C_GTCH_COUNT_MAX-1 downto 0); --//Начать передачу OOB сигнала
p_in_txcomtype         : in    std_logic_vector(C_GTCH_COUNT_MAX-1 downto 0); --//Выбор типа OOB сигнала
p_in_txdata            : in    TBus32_GTCH;                                   --//поток данных для передатчика DUAL_GTP
p_in_txcharisk         : in    TBus04_GTCH;                                   --//признак наличия упр.символов на порту txdata

p_in_txreset           : in    std_logic_vector(C_GTCH_COUNT_MAX-1 downto 0); --//Сброс передатчика
p_out_txbufstatus      : out   TBus02_GTCH;

---------------------------------------------------------------------------
--Receiver
---------------------------------------------------------------------------
p_in_rxcdrreset        : in    std_logic_vector(C_GTCH_COUNT_MAX-1 downto 0); --//Сброс GT RxPCS + PMA
p_in_rxreset           : in    std_logic_vector(C_GTCH_COUNT_MAX-1 downto 0); --//Сброс GT RxPCS
p_out_rxelecidle       : out   std_logic_vector(C_GTCH_COUNT_MAX-1 downto 0); --//Обнаружение приемником OOB сигнала
p_out_rxstatus         : out   TBus03_GTCH;                                    --//Тип обнаруженного OOB сигнала
p_out_rxdata           : out   TBus32_GTCH;                                    --//поток данных от приемника DUAL_GTP
p_out_rxcharisk        : out   TBus04_GTCH;                                    --//признак наличия упр.символов в rxdata
p_out_rxdisperr        : out   TBus04_GTCH;                                    --//Ошибка паритета в принятом данном
p_out_rxnotintable     : out   TBus04_GTCH;                                    --//
p_out_rxbyteisaligned  : out   std_logic_vector(C_GTCH_COUNT_MAX-1 downto 0);  --//Данные выровнены по байтам

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
p_in_rst               : in    std_logic
);
end sata_player_gt;

architecture behavioral of sata_player_gt is

--//1 - только для случая G_GT_DBUS=8
--//2 - для всех других случаев. Выравниваение по чётной границе. см Figure 7-15: Comma Alignment Boundaries ,
--      ug196_Virtex-5 FPGA RocketIO GTP Transceiver User Guide.pdf
constant C_GTP_ALIGN_COMMA_WORD    : integer := selval(1, 2, cmpval(G_GT_DBUS, 8));
constant C_GTP_DATAWIDTH           : std_logic_vector(0 downto 0):=CONV_STD_LOGIC_VECTOR(selval(0, 1, cmpval(G_GT_DBUS, 8)), 1);

signal i_refclkin                  : std_logic_vector(1 downto 0);
signal i_txcomsas                  : std_logic;
signal i_txcominit                 : std_logic;
signal i_txcomwake                 : std_logic;
signal i_txcom_finish              : std_logic;
signal i_rxcominit                 : std_logic;
signal i_rxcomwake                 : std_logic;

signal i_rxplllkdet                : std_logic;
signal i_rxreset_done              : std_logic;
signal i_txplllkdet                : std_logic;
signal i_txreset_done              : std_logic;

signal i_rxelecidle                : std_logic_vector(C_GTCH_COUNT_MAX-1 downto 0);

signal i_spdclk_sel                : std_logic_vector(C_GTCH_COUNT_MAX-1 downto 0);
signal g_gtp_usrclk                : std_logic_vector(C_GTCH_COUNT_MAX-1 downto 0);
signal g_gtp_usrclk2               : std_logic_vector(C_GTCH_COUNT_MAX-1 downto 0);


signal i_txelecidle_in             : std_logic_vector(C_GTCH_COUNT_MAX-1 downto 0);
signal i_txcomstart_in             : std_logic_vector(C_GTCH_COUNT_MAX-1 downto 0);
signal i_txcomtype_in              : std_logic_vector(C_GTCH_COUNT_MAX-1 downto 0);
signal i_txdata_in                 : TBus32_GTCH;
signal i_txcharisk_in              : TBus04_GTCH;

signal i_txreset_in                : std_logic_vector(C_GTCH_COUNT_MAX-1 downto 0);
signal i_txbufstatus_out           : TBus02_GTCH;

signal i_rxcdrreset_in             : std_logic_vector(C_GTCH_COUNT_MAX-1 downto 0);
signal i_rxreset_in                : std_logic_vector(C_GTCH_COUNT_MAX-1 downto 0);

signal i_rxstatus_out              : TBus03_GTCH;
signal i_rxdata_out                : TBus32_GTCH;
signal i_rxcharisk_out             : TBus04_GTCH;
signal i_rxdisperr_out             : TBus04_GTCH;
signal i_rxnotintable_out          : TBus04_GTCH;
signal i_rxbyteisaligned_out       : std_logic_vector(C_GTCH_COUNT_MAX-1 downto 0);

signal i_rxbufreset_in             : std_logic_vector(C_GTCH_COUNT_MAX-1 downto 0);
signal i_rxbufstatus_out           : TBus03_GTCH;


attribute keep : string;
attribute keep of g_gtp_usrclk : signal is "true";


--MAIN
begin


--#########################################
--//Выбор тактовых частот для работы SATA
--#########################################
gen_ch : for i in 0 to G_GT_CH_COUNT-1 generate

i_spdclk_sel(i)<='0' when p_in_spd(i).sata_ver=CONV_STD_LOGIC_VECTOR(C_FSATA_GEN2, p_in_spd(i).sata_ver'length) else '1';

--//------------------------------
--//GT: ШИНА ДАНЫХ=8bit
--//------------------------------
gen_gtp_w8 : if G_GT_DBUS=8 generate
m_bufg_usrclk2 : BUFGMUX_CTRL
port map
(
S  => i_spdclk_sel(i),
I0 => p_in_sys_dcm_gclk2x,  --//S=0 - SATA Generation 2 (3Gb/s)
I1 => p_in_sys_dcm_gclk,    --//S=1 - SATA Generation 1 (1.5Gb/s)
O  => g_gtp_usrclk2(i)
);
g_gtp_usrclk(i)<=g_gtp_usrclk2(i);
end generate gen_gtp_w8;

--//------------------------------
--//GT: ШИНА ДАНЫХ=16bit
--//------------------------------
gen_gtp_w16 : if G_GT_DBUS=16 generate
m_bufg_usrclk2 : BUFGMUX_CTRL
port map
(
S  => i_spdclk_sel(i),
I0 => p_in_sys_dcm_gclk,    --//S=0 - SATA Generation 2 (3Gb/s)
I1 => p_in_sys_dcm_gclk2div,--//S=1 - SATA Generation 1 (1.5Gb/s)
O  => g_gtp_usrclk2(i)
);
m_bufg_usrclk : BUFGMUX_CTRL
port map
(
S  => i_spdclk_sel(i),
I0 => p_in_sys_dcm_gclk2x,  --//S=0 - SATA Generation 2 (3Gb/s)
I1 => p_in_sys_dcm_gclk,    --//S=1 - SATA Generation 1 (1.5Gb/s)
O  => g_gtp_usrclk(i)
);
end generate gen_gtp_w16;

--//------------------------------
--//GT: ШИНА ДАНЫХ=32bit
--//------------------------------
gen_gtp_w32 : if G_GT_DBUS=32 generate
m_bufg_usrclk2 : BUFGMUX_CTRL
port map
(
S  => i_spdclk_sel(i),
I0 => p_in_sys_dcm_gclk,    --//S=0 - SATA Generation 2 (3Gb/s)
I1 => p_in_sys_dcm_gclk2div,--//S=1 - SATA Generation 1 (1.5Gb/s)
O  => g_gtp_usrclk2(i)
);
m_bufg_usrclk : BUFGMUX_CTRL
port map
(
S  => i_spdclk_sel(i),
I0 => p_in_sys_dcm_gclk2x,  --//S=0 - SATA Generation 2 (3Gb/s)
I1 => p_in_sys_dcm_gclk,    --//S=1 - SATA Generation 1 (1.5Gb/s)
O  => g_gtp_usrclk(i)
);
end generate gen_gtp_w32;

p_out_usrclk2(i)<=g_gtp_usrclk2(i);


process(g_gtp_usrclk2(i))
begin
  if g_gtp_usrclk2(i)'event and g_gtp_usrclk2(i)='1' then
      p_out_resetdone(i)      <=i_rxreset_done and i_txreset_done;

      i_txelecidle_in(i)      <=p_in_txelecidle(i);
      i_txcomstart_in(i)      <=p_in_txcomstart(i);
      i_txcomtype_in(i)       <=p_in_txcomtype(i);
      i_txdata_in(i)(31 downto 0)  <=p_in_txdata(i)(31 downto 0);
      i_txcharisk_in(i)(3 downto 0)<=p_in_txcharisk(i)(3 downto 0);

      i_txreset_in(i)         <=p_in_txreset(i);
      p_out_txbufstatus(i)    <=i_txbufstatus_out(i);

      i_rxcdrreset_in(i)      <=p_in_rxcdrreset(i);
      i_rxreset_in(i)         <=p_in_rxreset(i);
      p_out_rxelecidle(i)     <=i_rxelecidle(i);
--      p_out_rxstatus(i)       <=i_rxstatus_out(i);
      p_out_rxstatus(i)(2)<=i_rxcominit;
      p_out_rxstatus(i)(1)<=i_rxcomwake;
      p_out_rxstatus(i)(0)<=i_txcom_finish;

      p_out_rxdata(i)(31 downto 0)     <=i_rxdata_out(i)(31 downto 0);
      p_out_rxcharisk(i)(3 downto 0)   <=i_rxcharisk_out(i)(3 downto 0);
      p_out_rxdisperr(i)(3 downto 0)   <=i_rxdisperr_out(i)(3 downto 0);
      p_out_rxnotintable(i)(3 downto 0)<=i_rxnotintable_out(i)(3 downto 0);
      p_out_rxbyteisaligned(i)         <=i_rxbyteisaligned_out(i);

      i_rxbufreset_in(i)      <=p_in_rxbufreset(i);
      p_out_rxbufstatus(i)    <=i_rxbufstatus_out(i);
  end if;
end process;

end generate gen_ch;



--//###########################
--//Gig Tx/Rx
--//###########################
i_txcomsas <=i_txcomstart_in(0) and not i_txcomtype_in(0);
i_txcominit<='0';
i_txcomwake<=i_txcomstart_in(0) and i_txcomtype_in(0);

p_out_plllock<=i_txplllkdet and i_rxplllkdet;


i_refclkin <= ('0' & p_in_refclkin);

m_gt : GTXE1
generic map
(
--_______________________ Simulation-Only Attributes ___________________

SIM_RECEIVER_DETECT_PASS   =>      (TRUE),

SIM_GTXRESET_SPEEDUP       =>      1,--(GTX_SIM_GTXRESET_SPEEDUP),

SIM_TX_ELEC_IDLE_LEVEL     =>      ("X"),

SIM_VERSION                =>      ("2.0"),
SIM_TXREFCLK_SOURCE        =>      ("000"),
SIM_RXREFCLK_SOURCE        =>      ("000"),


----------------------------TX PLL----------------------------
TX_CLK_SOURCE                           =>     "RXPLL",--(GTX_TX_CLK_SOURCE),
TX_OVERSAMPLE_MODE                      =>     (FALSE),
TXPLL_COM_CFG                           =>     (x"21680a"),
TXPLL_CP_CFG                            =>     (x"0D"),
TXPLL_DIVSEL_FB                         =>     (2),
TXPLL_DIVSEL_OUT                        =>     (1),
TXPLL_DIVSEL_REF                        =>     (1),
TXPLL_DIVSEL45_FB                       =>     (5),
TXPLL_LKDET_CFG                         =>     ("111"),
TX_CLK25_DIVIDER                        =>     (6),
TXPLL_SATA                              =>     ("01"),
TX_TDCC_CFG                             =>     ("11"),
PMA_CAS_CLK_EN                          =>     (FALSE),
POWER_SAVE                              =>     "0000110100",--(GTX_POWER_SAVE)

-------------------------TX Interface-------------------------
GEN_TXUSRCLK                            =>     (TRUE),
TX_DATA_WIDTH                           =>     (20),
TX_USRCLK_CFG                           =>     (x"00"),
TXOUTCLK_CTRL                           =>     ("TXOUTCLKPMA_DIV2"),
TXOUTCLK_DLY                            =>     ("0000000000"),

--------------TX Buffering and Phase Alignment----------------
TX_PMADATA_OPT                          =>     ('0'),
PMA_TX_CFG                              =>     (x"80082"),
TX_BUFFER_USE                           =>     (TRUE),
TX_BYTECLK_CFG                          =>     (x"00"),
TX_EN_RATE_RESET_BUF                    =>     (TRUE),
TX_XCLK_SEL                             =>     ("TXOUT"),
TX_DLYALIGN_CTRINC                      =>     ("0100"),
TX_DLYALIGN_LPFINC                      =>     ("0110"),
TX_DLYALIGN_MONSEL                      =>     ("000"),
TX_DLYALIGN_OVRDSETTING                 =>     ("10000000"),

-------------------------TX Gearbox---------------------------
GEARBOX_ENDEC                           =>     ("000"),
TXGEARBOX_USE                           =>     (FALSE),

----------------TX Driver and OOB Signalling------------------
TX_DRIVE_MODE                           =>     ("DIRECT"),
TX_IDLE_ASSERT_DELAY                    =>     ("100"),
TX_IDLE_DEASSERT_DELAY                  =>     ("010"),
TXDRIVE_LOOPBACK_HIZ                    =>     (FALSE),
TXDRIVE_LOOPBACK_PD                     =>     (FALSE),

--------------TX Pipe Control for PCI Express/SATA------------
COM_BURST_VAL                           =>     ("1111"),

------------------TX Attributes for PCI Express---------------
TX_DEEMPH_0                             =>     ("11010"),
TX_DEEMPH_1                             =>     ("10000"),
TX_MARGIN_FULL_0                        =>     ("1001110"),
TX_MARGIN_FULL_1                        =>     ("1001001"),
TX_MARGIN_FULL_2                        =>     ("1000101"),
TX_MARGIN_FULL_3                        =>     ("1000010"),
TX_MARGIN_FULL_4                        =>     ("1000000"),
TX_MARGIN_LOW_0                         =>     ("1000110"),
TX_MARGIN_LOW_1                         =>     ("1000100"),
TX_MARGIN_LOW_2                         =>     ("1000010"),
TX_MARGIN_LOW_3                         =>     ("1000000"),
TX_MARGIN_LOW_4                         =>     ("1000000"),

----------------------------RX PLL----------------------------
RX_OVERSAMPLE_MODE                      =>     (FALSE),
RXPLL_COM_CFG                           =>     (x"21680a"),
RXPLL_CP_CFG                            =>     (x"0D"),
RXPLL_DIVSEL_FB                         =>     (2),
RXPLL_DIVSEL_OUT                        =>     (1),
RXPLL_DIVSEL_REF                        =>     (1),
RXPLL_DIVSEL45_FB                       =>     (5),
RXPLL_LKDET_CFG                         =>     ("111"),
RX_CLK25_DIVIDER                        =>     (6),

-------------------------RX Interface-------------------------
GEN_RXUSRCLK                            =>     (TRUE),
RX_DATA_WIDTH                           =>     (20),
RXRECCLK_CTRL                           =>     ("RXRECCLKPMA_DIV2"),
RXRECCLK_DLY                            =>     ("0000000000"),
RXUSRCLK_DLY                            =>     (x"0000"),

----------RX Driver,OOB signalling,Coupling and Eq.,CDR-------
AC_CAP_DIS                              =>     (TRUE),
CDR_PH_ADJ_TIME                         =>     ("10100"),
OOBDETECT_THRESHOLD                     =>     ("111"),
PMA_CDR_SCAN                            =>     (x"640404C"),
PMA_RX_CFG                              =>     (x"05ce049"),
RCV_TERM_GND                            =>     (FALSE),
RCV_TERM_VTTRX                          =>     (TRUE),
RX_EN_IDLE_HOLD_CDR                     =>     (FALSE),
RX_EN_IDLE_RESET_FR                     =>     (TRUE),
RX_EN_IDLE_RESET_PH                     =>     (TRUE),
TX_DETECT_RX_CFG                        =>     (x"1832"),
TERMINATION_CTRL                        =>     ("00000"),
TERMINATION_OVRD                        =>     (FALSE),
CM_TRIM                                 =>     ("01"),
PMA_RXSYNC_CFG                          =>     (x"00"),
PMA_CFG                                 =>     (x"0040000040000000003"),
BGTEST_CFG                              =>     ("00"),
BIAS_CFG                                =>     (x"00000"),

--------------RX Decision Feedback Equalizer(DFE)-------------
DFE_CAL_TIME                            =>     ("01100"),
DFE_CFG                                 =>     ("00011011"),
RX_EN_IDLE_HOLD_DFE                     =>     (TRUE),
RX_EYE_OFFSET                           =>     (x"4C"),
RX_EYE_SCANMODE                         =>     ("00"),

-------------------------PRBS Detection-----------------------
RXPRBSERR_LOOPBACK                      =>     ('0'),

------------------Comma Detection and Alignment---------------
ALIGN_COMMA_WORD                        =>     C_GTP_ALIGN_COMMA_WORD,--//############################### add vicg
COMMA_10B_ENABLE                        =>     ("1111111111"),
COMMA_DOUBLE                            =>     (FALSE),
DEC_MCOMMA_DETECT                       =>     (TRUE),
DEC_PCOMMA_DETECT                       =>     (TRUE),
DEC_VALID_COMMA_ONLY                    =>     (FALSE),
MCOMMA_10B_VALUE                        =>     ("1010000011"),
MCOMMA_DETECT                           =>     (TRUE),
PCOMMA_10B_VALUE                        =>     ("0101111100"),
PCOMMA_DETECT                           =>     (TRUE),
RX_DECODE_SEQ_MATCH                     =>     (TRUE),
RX_SLIDE_AUTO_WAIT                      =>     (5),
RX_SLIDE_MODE                           =>     ("OFF"),
SHOW_REALIGN_COMMA                      =>     (FALSE),

-----------------RX Loss-of-sync State Machine----------------
RX_LOS_INVALID_INCR                     =>     (8),
RX_LOS_THRESHOLD                        =>     (128),
RX_LOSS_OF_SYNC_FSM                     =>     (FALSE),

-------------------------RX Gearbox---------------------------
RXGEARBOX_USE                           =>     (FALSE),

-------------RX Elastic Buffer and Phase alignment------------
RX_BUFFER_USE                           =>     (TRUE),
RX_EN_IDLE_RESET_BUF                    =>     (TRUE),
RX_EN_MODE_RESET_BUF                    =>     (TRUE),
RX_EN_RATE_RESET_BUF                    =>     (TRUE),
RX_EN_REALIGN_RESET_BUF                 =>     (FALSE),
RX_EN_REALIGN_RESET_BUF2                =>     (FALSE),
RX_FIFO_ADDR_MODE                       =>     ("FULL"),
RX_IDLE_HI_CNT                          =>     ("1000"),
RX_IDLE_LO_CNT                          =>     ("0000"),
RX_XCLK_SEL                             =>     ("RXREC"),
RX_DLYALIGN_CTRINC                      =>     ("1110"),
RX_DLYALIGN_EDGESET                     =>     ("00010"),
RX_DLYALIGN_LPFINC                      =>     ("1110"),
RX_DLYALIGN_MONSEL                      =>     ("000"),
RX_DLYALIGN_OVRDSETTING                 =>     ("10000000"),

------------------------Clock Correction----------------------
CLK_COR_ADJ_LEN                         =>     (4),
CLK_COR_DET_LEN                         =>     (4),
CLK_COR_INSERT_IDLE_FLAG                =>     (FALSE),
CLK_COR_KEEP_IDLE                       =>     (FALSE),
CLK_COR_MAX_LAT                         =>     (20),
CLK_COR_MIN_LAT                         =>     (14),
CLK_COR_PRECEDENCE                      =>     (TRUE),
CLK_COR_REPEAT_WAIT                     =>     (0),
CLK_COR_SEQ_1_1                         =>     ("0110111100"),
CLK_COR_SEQ_1_2                         =>     ("0001001010"),
CLK_COR_SEQ_1_3                         =>     ("0001001010"),
CLK_COR_SEQ_1_4                         =>     ("0001111011"),
CLK_COR_SEQ_1_ENABLE                    =>     ("1111"),
CLK_COR_SEQ_2_1                         =>     ("0100000000"),
CLK_COR_SEQ_2_2                         =>     ("0100000000"),
CLK_COR_SEQ_2_3                         =>     ("0100000000"),
CLK_COR_SEQ_2_4                         =>     ("0100000000"),
CLK_COR_SEQ_2_ENABLE                    =>     ("1111"),
CLK_COR_SEQ_2_USE                       =>     (FALSE),
CLK_CORRECT_USE                         =>     (TRUE),

------------------------Channel Bonding----------------------
CHAN_BOND_1_MAX_SKEW                    =>     (1),
CHAN_BOND_2_MAX_SKEW                    =>     (1),
CHAN_BOND_KEEP_ALIGN                    =>     (FALSE),
CHAN_BOND_SEQ_1_1                       =>     ("0000000000"),
CHAN_BOND_SEQ_1_2                       =>     ("0000000000"),
CHAN_BOND_SEQ_1_3                       =>     ("0000000000"),
CHAN_BOND_SEQ_1_4                       =>     ("0000000000"),
CHAN_BOND_SEQ_1_ENABLE                  =>     ("1111"),
CHAN_BOND_SEQ_2_1                       =>     ("0000000000"),
CHAN_BOND_SEQ_2_2                       =>     ("0000000000"),
CHAN_BOND_SEQ_2_3                       =>     ("0000000000"),
CHAN_BOND_SEQ_2_4                       =>     ("0000000000"),
CHAN_BOND_SEQ_2_CFG                     =>     ("00000"),
CHAN_BOND_SEQ_2_ENABLE                  =>     ("1111"),
CHAN_BOND_SEQ_2_USE                     =>     (FALSE),
CHAN_BOND_SEQ_LEN                       =>     (1),
PCI_EXPRESS_MODE                        =>     (FALSE),

-------------RX Attributes for PCI Express/SATA/SAS----------
SAS_MAX_COMSAS                          =>     (52),
SAS_MIN_COMSAS                          =>     (40),
SATA_BURST_VAL                          =>     ("101"),
SATA_IDLE_VAL                           =>     ("101"),
SATA_MAX_BURST                          =>     (7),
SATA_MAX_INIT                           =>     (22),
SATA_MAX_WAKE                           =>     (7),
SATA_MIN_BURST                          =>     (4),
SATA_MIN_INIT                           =>     (12),
SATA_MIN_WAKE                           =>     (4),
TRANS_TIME_FROM_P2                      =>     (x"03c"),
TRANS_TIME_NON_P2                       =>     (x"19"),
TRANS_TIME_RATE                         =>     (x"ff"),
TRANS_TIME_TO_P2                        =>     (x"064")


)
port map
(
              ------------------------ Loopback and Powerdown Ports ----------------------
LOOPBACK                        =>      "000",
RXPOWERDOWN                     =>      "00",
TXPOWERDOWN                     =>      "00",
-------------- Receive Ports - 64b66b and 64b67b Gearbox Ports -------------
RXDATAVALID                     =>      open,
RXGEARBOXSLIP                   =>      '0',
RXHEADER                        =>      open,
RXHEADERVALID                   =>      open,
RXSTARTOFSEQ                    =>      open,
----------------------- Receive Ports - 8b10b Decoder ----------------------
RXCHARISCOMMA(3 downto 2)       =>      open,
RXCHARISCOMMA(1 downto 0)       =>      open,
RXCHARISK(3 downto 2)           =>      i_rxcharisk_out(0)(3 downto 2),--------------p_out_rxcharisk(0)(3 downto 2),--//############################### add vicg
RXCHARISK(1 downto 0)           =>      i_rxcharisk_out(0)(1 downto 0),--------------p_out_rxcharisk(0)(1 downto 0),--//############################### add vicg
RXDEC8B10BUSE                   =>      '1',
RXDISPERR(3 downto 2)           =>      i_rxdisperr_out(0)(3 downto 2),--------------p_out_rxdisperr(0)(3 downto 2),--//############################### add vicg
RXDISPERR(1 downto 0)           =>      i_rxdisperr_out(0)(1 downto 0),--------------p_out_rxdisperr(0)(1 downto 0),--//############################### add vicg
RXNOTINTABLE(3 downto 2)        =>      i_rxnotintable_out(0)(3 downto 2),-----------p_out_rxnotintable(0)(3 downto 2),--//############################### add vicg
RXNOTINTABLE(1 downto 0)        =>      i_rxnotintable_out(0)(1 downto 0),-----------p_out_rxnotintable(0)(1 downto 0),--//############################### add vicg
RXRUNDISP                       =>      open,
USRCODEERR                      =>      '0',
------------------- Receive Ports - Channel Bonding Ports ------------------
RXCHANBONDSEQ                   =>      open,
RXCHBONDI                       =>      "0000",
RXCHBONDLEVEL                   =>      "000",
RXCHBONDMASTER                  =>      '0',
RXCHBONDO                       =>      open,
RXCHBONDSLAVE                   =>      '0',
RXENCHANSYNC                    =>      '0',
------------------- Receive Ports - Clock Correction Ports -----------------
RXCLKCORCNT                     =>      open,--RXCLKCORCNT_OUT,
--------------- Receive Ports - Comma Detection and Alignment --------------
RXBYTEISALIGNED                 =>      i_rxbyteisaligned_out(0),---------------------------p_out_rxbyteisaligned(0),--//############################### add vicg
RXBYTEREALIGN                   =>      open,
RXCOMMADET                      =>      open,
RXCOMMADETUSE                   =>      '1',
RXENMCOMMAALIGN                 =>      '1',--RXENMCOMMAALIGN_IN,
RXENPCOMMAALIGN                 =>      '1',--RXENPCOMMAALIGN_IN,
RXSLIDE                         =>      '0',
----------------------- Receive Ports - PRBS Detection ---------------------
PRBSCNTRESET                    =>      '0',
RXENPRBSTST                     =>      "000",
RXPRBSERR                       =>      open,
------------------- Receive Ports - RX Data Path interface -----------------
RXDATA                          =>      i_rxdata_out(0),-----------------------------p_out_rxdata(0),--//############################### add vicg
RXRECCLK                        =>      open,--RXRECCLK_OUT,
RXRECCLKPCS                     =>      open,
RXRESET                         =>      i_rxreset_in(0),-----------------------------p_in_rxreset(0),--//############################### add vicg
RXUSRCLK                        =>      g_gtp_usrclk(0),--//############################### add vicg
RXUSRCLK2                       =>      g_gtp_usrclk2(0),--//############################### add vicg
------------ Receive Ports - RX Decision Feedback Equalizer(DFE) -----------
DFECLKDLYADJ                    =>      "000000",
DFECLKDLYADJMON                 =>      open,
DFEDLYOVRD                      =>      '1',
DFEEYEDACMON                    =>      open,
DFESENSCAL                      =>      open,
DFETAP1                         =>      "00000",
DFETAP1MONITOR                  =>      open,
DFETAP2                         =>      "00000",
DFETAP2MONITOR                  =>      open,
DFETAP3                         =>      "0000",
DFETAP3MONITOR                  =>      open,
DFETAP4                         =>      "0000",
DFETAP4MONITOR                  =>      open,
DFETAPOVRD                      =>      '1',
------- Receive Ports - RX Driver,OOB signalling,Coupling and Eq.,CDR ------
GATERXELECIDLE                  =>      '0',
IGNORESIGDET                    =>      '0',
RXCDRRESET                      =>      i_rxcdrreset_in(0),----------------------------------------------//############################### add vicg
RXELECIDLE                      =>      i_rxelecidle(0),-----------------------------p_out_rxelecidle(0),--//############################### add vicg
RXEQMIX(9 downto 3)             =>      "0000000",
RXEQMIX(2 downto 0)             =>      "111",--RXEQMIX_IN,
RXN                             =>      p_in_rxn(0),--//############################### add vicg
RXP                             =>      p_in_rxp(0),--//############################### add vicg
-------- Receive Ports - RX Elastic Buffer and Phase Alignment Ports -------
RXBUFRESET                      =>      i_rxbufreset_in(0),----------------------------------------------//############################### add vicg
RXBUFSTATUS                     =>      i_rxbufstatus_out(0),----------------------------------------------//############################### add vicg
RXCHANISALIGNED                 =>      open,
RXCHANREALIGN                   =>      open,
RXDLYALIGNDISABLE               =>      '0',
RXDLYALIGNMONENB                =>      '0',
RXDLYALIGNMONITOR               =>      open,
RXDLYALIGNOVERRIDE              =>      '1',
RXDLYALIGNRESET                 =>      '0',
RXDLYALIGNSWPPRECURB            =>      '1',
RXDLYALIGNUPDSW                 =>      '0',
RXENPMAPHASEALIGN               =>      '0',
RXPMASETPHASE                   =>      '0',
RXSTATUS                        =>      open,--RXSTATUS_OUT,
--------------- Receive Ports - RX Loss-of-sync State Machine --------------
RXLOSSOFSYNC                    =>      open,
---------------------- Receive Ports - RX Oversampling ---------------------
RXENSAMPLEALIGN                 =>      '0',
RXOVERSAMPLEERR                 =>      open,
------------------------ Receive Ports - RX PLL Ports ----------------------
GREFCLKRX                       =>      '0',--GREFCLKRX_IN,
GTXRXRESET                      =>      p_in_rst,--//############################### add vicg
MGTREFCLKRX                     =>      i_refclkin,--//############################### add vicg
NORTHREFCLKRX                   =>      "00",--NORTHREFCLKRX_IN,
PERFCLKRX                       =>      '0',--PERFCLKRX_IN,
PLLRXRESET                      =>      '0',--PLLRXRESET_IN,
RXPLLLKDET                      =>      i_rxplllkdet,--RXPLLLKDET_OUT,--//############################### add vicg
RXPLLLKDETEN                    =>      '1',
RXPLLPOWERDOWN                  =>      '0',
RXPLLREFSELDY                   =>      "000",--RXPLLREFSELDY_IN,
RXRATE                          =>      "00",
RXRATEDONE                      =>      open,
RXRESETDONE                     =>      i_rxreset_done,--RXRESETDONE_OUT,--//############################### add vicg
SOUTHREFCLKRX                   =>      "00",--SOUTHREFCLKRX_IN,
-------------- Receive Ports - RX Pipe Control for PCI Express -------------
PHYSTATUS                       =>      open,
RXVALID                         =>      open,
----------------- Receive Ports - RX Polarity Control Ports ----------------
RXPOLARITY                      =>      '0',
--------------------- Receive Ports - RX Ports for SATA --------------------
COMINITDET                      =>      i_rxcominit,--//############################### add vicg
COMSASDET                       =>      open,--COMSASDET_OUT,--//############################### add vicg
COMWAKEDET                      =>      i_rxcomwake,--//############################### add vicg
------------- Shared Ports - Dynamic Reconfiguration Port (DRP) ------------
DADDR                           =>      p_in_drpaddr(7 downto 0),--//############################### add vicg
DCLK                            =>      p_in_drpclk,--//############################### add vicg
DEN                             =>      p_in_drpen,--//############################### add vicg
DI                              =>      p_in_drpdi,--//############################### add vicg
DRDY                            =>      p_out_drprdy,--//############################### add vicg
DRPDO                           =>      p_out_drpdo,--//############################### add vicg
DWE                             =>      p_in_drpwe,--//############################### add vicg

-------------- Transmit Ports - 64b66b and 64b67b Gearbox Ports ------------
TXGEARBOXREADY                  =>      open,
TXHEADER                        =>      "000",
TXSEQUENCE                      =>      "0000000",
TXSTARTSEQ                      =>      '0',
---------------- Transmit Ports - 8b10b Encoder Control Ports --------------
TXBYPASS8B10B                   =>      "0000",
TXCHARDISPMODE                  =>      "0000",
TXCHARDISPVAL                   =>      "0000",
TXCHARISK(3 downto 2)           =>      i_txcharisk_in(0)(3 downto 2),---------------------------p_in_txcharisk(0)(3 downto 2),--//############################### add vicg
TXCHARISK(1 downto 0)           =>      i_txcharisk_in(0)(1 downto 0),---------------------------p_in_txcharisk(0)(1 downto 0),--//############################### add vicg
TXENC8B10BUSE                   =>      '1',
TXKERR                          =>      open,
TXRUNDISP                       =>      open,
------------------------- Transmit Ports - GTX Ports -----------------------
GTXTEST                         =>      "1000000000000",
MGTREFCLKFAB                    =>      open,
TSTCLK0                         =>      '0',
TSTCLK1                         =>      '0',
TSTIN                           =>      "11111111111111111111",
TSTOUT                          =>      open,
------------------ Transmit Ports - TX Data Path interface -----------------
TXDATA                          =>      i_txdata_in(0),-----------------------------p_in_txdata(0),--//############################### add vicg
TXOUTCLK                        =>      p_out_refclkout,--//############################### add vicg
TXOUTCLKPCS                     =>      open,
TXRESET                         =>      i_txreset_in(0),----------------------------p_in_txreset(0),--//############################### add vicg
TXUSRCLK                        =>      g_gtp_usrclk(0),--//############################### add vicg
TXUSRCLK2                       =>      g_gtp_usrclk2(0),--//############################### add vicg
---------------- Transmit Ports - TX Driver and OOB signaling --------------
TXBUFDIFFCTRL                   =>      "100",
TXDIFFCTRL                      =>      "0000",
TXINHIBIT                       =>      '0',
TXN                             =>      p_out_txn(0),--//############################### add vicg
TXP                             =>      p_out_txp(0),--//############################### add vicg
TXPOSTEMPHASIS                  =>      "00000",
--------------- Transmit Ports - TX Driver and OOB signalling --------------
TXPREEMPHASIS                   =>      "0000",
----------- Transmit Ports - TX Elastic Buffer and Phase Alignment ---------
TXBUFSTATUS                     =>      i_txbufstatus_out(0),--------------------------------//############################### add vicg
-------- Transmit Ports - TX Elastic Buffer and Phase Alignment Ports ------
TXDLYALIGNDISABLE               =>      '1',
TXDLYALIGNMONENB                =>      '0',
TXDLYALIGNMONITOR               =>      open,
TXDLYALIGNOVERRIDE              =>      '0',
TXDLYALIGNRESET                 =>      '0',
TXDLYALIGNUPDSW                 =>      '1',
TXENPMAPHASEALIGN               =>      '0',
TXPMASETPHASE                   =>      '0',
----------------------- Transmit Ports - TX PLL Ports ----------------------
GREFCLKTX                       =>      '0',--GREFCLKTX_IN,
GTXTXRESET                      =>      p_in_rst,--//############################### add vicg
MGTREFCLKTX                     =>      i_refclkin,--//############################### add vicg
NORTHREFCLKTX                   =>      "00",--NORTHREFCLKTX_IN,
PERFCLKTX                       =>      '0',--PERFCLKTX_IN,
PLLTXRESET                      =>      '0',--//############################### add vicg
SOUTHREFCLKTX                   =>      "00",--SOUTHREFCLKTX_IN,
TXPLLLKDET                      =>      i_txplllkdet,
TXPLLLKDETEN                    =>      '1',
TXPLLPOWERDOWN                  =>      '0',
TXPLLREFSELDY                   =>      "000",--TXPLLREFSELDY_IN,
TXRATE                          =>      "00",
TXRATEDONE                      =>      open,
TXRESETDONE                     =>      i_txreset_done,--TXRESETDONE_OUT,
--------------------- Transmit Ports - TX PRBS Generator -------------------
TXENPRBSTST                     =>      "000",
TXPRBSFORCEERR                  =>      '0',
-------------------- Transmit Ports - TX Polarity Control ------------------
TXPOLARITY                      =>      '0',
----------------- Transmit Ports - TX Ports for PCI Express ----------------
TXDEEMPH                        =>      '0',
TXDETECTRX                      =>      '0',
TXELECIDLE                      =>      i_txelecidle_in(0),-----------------------------------------p_in_txelecidle(0),--//############################### add vicg
TXMARGIN                        =>      "000",
TXPDOWNASYNCH                   =>      '0',
TXSWING                         =>      '0',
--------------------- Transmit Ports - TX Ports for SATA -------------------
COMFINISH                       =>      i_txcom_finish,--//############################### add vicg
TXCOMINIT                       =>      i_txcominit,--//############################### add vicg
TXCOMSAS                        =>      i_txcomsas,--//############################### add vicg
TXCOMWAKE                       =>      i_txcomwake --//############################### add vicg
);


--END MAIN
end behavioral;
