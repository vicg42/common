--
-- mclk_gtp_wrap.vhd - Wrapper for a GTP_DUAL instance that bypasses the
--                     GTP_DUAL and provides just the clock out from the
--                     instance, given an MGT reference clock input
--                     signal.
--
-------------------------------------------------------------------------
-- Company     : Linkos
-- Engineer    : Golovachenko Victor
--
-- Create Date : 06.12.2011 18:40:54
-- Module Name : s6_gt_mclk
--
-- Назначение/Описание :
-- Выдача опорной частоты GT
--
-- Revision:
-- Revision 0.01 - File Created
--
-------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library unisim;
use unisim.vcomponents.all;

library work;
use work.vicg_common_pkg.all;

entity s6_gt_mclk is
generic(
G_SIM     : string:="OFF"
);
port(
p_out_txn : out   std_logic_vector(1 downto 0);
p_out_txp : out   std_logic_vector(1 downto 0);
p_in_rxn  : in    std_logic_vector(1 downto 0);
p_in_rxp  : in    std_logic_vector(1 downto 0);
clkin     : in    std_logic;
clkout    : out   std_logic
);
end entity;

architecture sparnat6_only of s6_gt_mclk is

signal i_gtpclkout0                 : std_logic_vector(1 downto 0);
signal rxchariscomma0_float_i       : std_logic_vector(3 downto 0);
signal rxcharisk0_float_i           : std_logic_vector(3 downto 0);
signal rxdisperr0_float_i           : std_logic_vector(3 downto 0);
signal rxnotintable0_float_i        : std_logic_vector(3 downto 0);

signal i_gtpclkout1                 : std_logic_vector(1 downto 0);
signal rxchariscomma1_float_i       : std_logic_vector(3 downto 0);
signal rxcharisk1_float_i           : std_logic_vector(3 downto 0);
signal rxdisperr1_float_i           : std_logic_vector(3 downto 0);
signal rxnotintable1_float_i        : std_logic_vector(3 downto 0);


begin

gen_sim_on : if strcmp(G_SIM,"ON") generate
p_out_txn<=p_in_rxn;
p_out_txp<=p_in_rxp;

clkout<=clkin;
end generate gen_sim_on;


gen_sim_off : if strcmp(G_SIM,"OFF") generate

m_buffio2 : BUFIO2 port map (DIVCLK => clkout, IOCLK => open, SERDESSTROBE => open, I => i_gtpclkout0(0) );

m_gt : GTPA1_DUAL
generic map(
--_______________________ Simulation-Only Attributes ___________________

SIM_RECEIVER_DETECT_PASS    =>      (TRUE),
SIM_TX_ELEC_IDLE_LEVEL      =>      ("Z"),
SIM_VERSION                 =>      ("2.0"),

SIM_REFCLK0_SOURCE          =>      ("000"),
SIM_REFCLK1_SOURCE          =>      ("000"),

SIM_GTPRESET_SPEEDUP        =>      1,--(TILE_SIM_GTPRESET_SPEEDUP),
CLK25_DIVIDER_0             =>      6,
CLK25_DIVIDER_1             =>      6,
PLL_DIVSEL_FB_0             =>      2,
PLL_DIVSEL_FB_1             =>      2,
PLL_DIVSEL_REF_0            =>      1,
PLL_DIVSEL_REF_1            =>      1,


--PLL Attributes
CLKINDC_B_0                             =>     (TRUE),
CLKRCV_TRST_0                           =>     (TRUE),
OOB_CLK_DIVIDER_0                       =>     (6),
PLL_COM_CFG_0                           =>     (x"21680a"),
PLL_CP_CFG_0                            =>     (x"00"),
PLL_RXDIVSEL_OUT_0                      =>     (1),
PLL_SATA_0                              =>     (FALSE),
PLL_SOURCE_0                            =>     ("PLL0"),
PLL_TXDIVSEL_OUT_0                      =>     (1),
PLLLKDET_CFG_0                          =>     ("111"),

--
CLKINDC_B_1                             =>     (TRUE),
CLKRCV_TRST_1                           =>     (TRUE),
OOB_CLK_DIVIDER_1                       =>     (6),
PLL_COM_CFG_1                           =>     (x"21680a"),
PLL_CP_CFG_1                            =>     (x"00"),
PLL_RXDIVSEL_OUT_1                      =>     (1),
PLL_SATA_1                              =>     (FALSE),
PLL_SOURCE_1                            =>     ("PLL1"),
PLL_TXDIVSEL_OUT_1                      =>     (1),
PLLLKDET_CFG_1                          =>     ("111"),
PMA_COM_CFG_EAST                        =>     (x"000008000"),
PMA_COM_CFG_WEST                        =>     (x"00000a000"),
TST_ATTR_0                              =>     (x"00000000"),
TST_ATTR_1                              =>     (x"00000000"),

--TX Interface Attributes
CLK_OUT_GTP_SEL_0                       =>     ("REFCLKPLL0"),--("TXOUTCLK0"),
TX_TDCC_CFG_0                           =>     ("11"),
CLK_OUT_GTP_SEL_1                       =>     ("REFCLKPLL1"),--("TXOUTCLK1"),
TX_TDCC_CFG_1                           =>     ("11"),

--TX Buffer and Phase Alignment Attributes
PMA_TX_CFG_0                            =>     (x"00082"),
TX_BUFFER_USE_0                         =>     (TRUE),
TX_XCLK_SEL_0                           =>     ("TXOUT"),
TXRX_INVERT_0                           =>     ("011"),
PMA_TX_CFG_1                            =>     (x"00082"),
TX_BUFFER_USE_1                         =>     (TRUE),
TX_XCLK_SEL_1                           =>     ("TXOUT"),
TXRX_INVERT_1                           =>     ("011"),

--TX Driver and OOB signalling Attributes
CM_TRIM_0                               =>     ("00"),
TX_IDLE_DELAY_0                         =>     ("011"),
CM_TRIM_1                               =>     ("00"),
TX_IDLE_DELAY_1                         =>     ("011"),

--TX PIPE/SATA Attributes
COM_BURST_VAL_0                         =>     ("1111"),
COM_BURST_VAL_1                         =>     ("1111"),

--RX Driver,OOB signalling,Coupling and Eq,CDR Attributes
AC_CAP_DIS_0                            =>     (FALSE),
OOBDETECT_THRESHOLD_0                   =>     ("110"),
PMA_CDR_SCAN_0                          =>     (x"6404040"),
PMA_RX_CFG_0                            =>     (x"05ce089"),
PMA_RXSYNC_CFG_0                        =>     (x"00"),
RCV_TERM_GND_0                          =>     (FALSE),
RCV_TERM_VTTRX_0                        =>     (TRUE),
RXEQ_CFG_0                              =>     ("01111011"),
TERMINATION_CTRL_0                      =>     ("10100"),
TERMINATION_OVRD_0                      =>     (FALSE),
TX_DETECT_RX_CFG_0                      =>     (x"1832"),
AC_CAP_DIS_1                            =>     (FALSE),
OOBDETECT_THRESHOLD_1                   =>     ("110"),
PMA_CDR_SCAN_1                          =>     (x"6404040"),
PMA_RX_CFG_1                            =>     (x"05ce089"),
PMA_RXSYNC_CFG_1                        =>     (x"00"),
RCV_TERM_GND_1                          =>     (FALSE),
RCV_TERM_VTTRX_1                        =>     (TRUE),
RXEQ_CFG_1                              =>     ("01111011"),
TERMINATION_CTRL_1                      =>     ("10100"),
TERMINATION_OVRD_1                      =>     (FALSE),
TX_DETECT_RX_CFG_1                      =>     (x"1832"),

--PRBS Detection Attributes
RXPRBSERR_LOOPBACK_0                    =>     ('0'),
RXPRBSERR_LOOPBACK_1                    =>     ('0'),

--Comma Detection and Alignment Attributes
ALIGN_COMMA_WORD_0                      =>     (1),
COMMA_10B_ENABLE_0                      =>     ("1111111111"),
DEC_MCOMMA_DETECT_0                     =>     (TRUE),
DEC_PCOMMA_DETECT_0                     =>     (TRUE),
DEC_VALID_COMMA_ONLY_0                  =>     (FALSE),
MCOMMA_10B_VALUE_0                      =>     ("1010000011"),
MCOMMA_DETECT_0                         =>     (TRUE),
PCOMMA_10B_VALUE_0                      =>     ("0101111100"),
PCOMMA_DETECT_0                         =>     (TRUE),
RX_SLIDE_MODE_0                         =>     ("PCS"),
ALIGN_COMMA_WORD_1                      =>     (1),
COMMA_10B_ENABLE_1                      =>     ("1111111111"),
DEC_MCOMMA_DETECT_1                     =>     (TRUE),
DEC_PCOMMA_DETECT_1                     =>     (TRUE),
DEC_VALID_COMMA_ONLY_1                  =>     (FALSE),
MCOMMA_10B_VALUE_1                      =>     ("1010000011"),
MCOMMA_DETECT_1                         =>     (TRUE),
PCOMMA_10B_VALUE_1                      =>     ("0101111100"),
PCOMMA_DETECT_1                         =>     (TRUE),
RX_SLIDE_MODE_1                         =>     ("PCS"),

--RX Loss-of-sync State Machine Attributes
RX_LOS_INVALID_INCR_0                   =>     (8),
RX_LOS_THRESHOLD_0                      =>     (128),
RX_LOSS_OF_SYNC_FSM_0                   =>     (FALSE),
RX_LOS_INVALID_INCR_1                   =>     (8),
RX_LOS_THRESHOLD_1                      =>     (128),
RX_LOSS_OF_SYNC_FSM_1                   =>     (FALSE),

--RX Elastic Buffer and Phase alignment Attributes
RX_BUFFER_USE_0                         =>     (TRUE),
RX_EN_IDLE_RESET_BUF_0                  =>     (TRUE),
RX_IDLE_HI_CNT_0                        =>     ("1000"),
RX_IDLE_LO_CNT_0                        =>     ("0000"),
RX_XCLK_SEL_0                           =>     ("RXREC"),
RX_BUFFER_USE_1                         =>     (TRUE),
RX_EN_IDLE_RESET_BUF_1                  =>     (TRUE),
RX_IDLE_HI_CNT_1                        =>     ("1000"),
RX_IDLE_LO_CNT_1                        =>     ("0000"),
RX_XCLK_SEL_1                           =>     ("RXREC"),

--Clock Correction Attributes
CLK_COR_ADJ_LEN_0                       =>     (4),
CLK_COR_DET_LEN_0                       =>     (4),
CLK_COR_INSERT_IDLE_FLAG_0              =>     (FALSE),
CLK_COR_KEEP_IDLE_0                     =>     (FALSE),
CLK_COR_MAX_LAT_0                       =>     (18),
CLK_COR_MIN_LAT_0                       =>     (16),
CLK_COR_PRECEDENCE_0                    =>     (TRUE),
CLK_COR_REPEAT_WAIT_0                   =>     (0),
CLK_COR_SEQ_1_1_0                       =>     ("0110111100"),
CLK_COR_SEQ_1_2_0                       =>     ("0001001010"),
CLK_COR_SEQ_1_3_0                       =>     ("0001001010"),
CLK_COR_SEQ_1_4_0                       =>     ("0001111011"),
CLK_COR_SEQ_1_ENABLE_0                  =>     ("1111"),
CLK_COR_SEQ_2_1_0                       =>     ("0100000000"),
CLK_COR_SEQ_2_2_0                       =>     ("0000000000"),
CLK_COR_SEQ_2_3_0                       =>     ("0000000000"),
CLK_COR_SEQ_2_4_0                       =>     ("0000000000"),
CLK_COR_SEQ_2_ENABLE_0                  =>     ("0000"),
CLK_COR_SEQ_2_USE_0                     =>     (FALSE),
CLK_CORRECT_USE_0                       =>     (TRUE),
RX_DECODE_SEQ_MATCH_0                   =>     (TRUE),
CLK_COR_ADJ_LEN_1                       =>     (4),
CLK_COR_DET_LEN_1                       =>     (4),
CLK_COR_INSERT_IDLE_FLAG_1              =>     (FALSE),
CLK_COR_KEEP_IDLE_1                     =>     (FALSE),
CLK_COR_MAX_LAT_1                       =>     (18),
CLK_COR_MIN_LAT_1                       =>     (16),
CLK_COR_PRECEDENCE_1                    =>     (TRUE),
CLK_COR_REPEAT_WAIT_1                   =>     (0),
CLK_COR_SEQ_1_1_1                       =>     ("0110111100"),
CLK_COR_SEQ_1_2_1                       =>     ("0001001010"),
CLK_COR_SEQ_1_3_1                       =>     ("0001001010"),
CLK_COR_SEQ_1_4_1                       =>     ("0001111011"),
CLK_COR_SEQ_1_ENABLE_1                  =>     ("1111"),
CLK_COR_SEQ_2_1_1                       =>     ("0100000000"),
CLK_COR_SEQ_2_2_1                       =>     ("0000000000"),
CLK_COR_SEQ_2_3_1                       =>     ("0000000000"),
CLK_COR_SEQ_2_4_1                       =>     ("0000000000"),
CLK_COR_SEQ_2_ENABLE_1                  =>     ("0000"),
CLK_COR_SEQ_2_USE_1                     =>     (FALSE),
CLK_CORRECT_USE_1                       =>     (TRUE),
RX_DECODE_SEQ_MATCH_1                   =>     (TRUE),

--Channel Bonding Attributes
CHAN_BOND_1_MAX_SKEW_0                  =>     (1),
CHAN_BOND_2_MAX_SKEW_0                  =>     (1),
CHAN_BOND_KEEP_ALIGN_0                  =>     (FALSE),
CHAN_BOND_SEQ_1_1_0                     =>     ("0000000000"),
CHAN_BOND_SEQ_1_2_0                     =>     ("0000000000"),
CHAN_BOND_SEQ_1_3_0                     =>     ("0000000000"),
CHAN_BOND_SEQ_1_4_0                     =>     ("0000000000"),
CHAN_BOND_SEQ_1_ENABLE_0                =>     ("0000"),
CHAN_BOND_SEQ_2_1_0                     =>     ("0000000000"),
CHAN_BOND_SEQ_2_2_0                     =>     ("0000000000"),
CHAN_BOND_SEQ_2_3_0                     =>     ("0000000000"),
CHAN_BOND_SEQ_2_4_0                     =>     ("0000000000"),
CHAN_BOND_SEQ_2_ENABLE_0                =>     ("0000"),
CHAN_BOND_SEQ_2_USE_0                   =>     (FALSE),
CHAN_BOND_SEQ_LEN_0                     =>     (1),
RX_EN_MODE_RESET_BUF_0                  =>     (TRUE),
CHAN_BOND_1_MAX_SKEW_1                  =>     (1),
CHAN_BOND_2_MAX_SKEW_1                  =>     (1),
CHAN_BOND_KEEP_ALIGN_1                  =>     (FALSE),
CHAN_BOND_SEQ_1_1_1                     =>     ("0000000000"),
CHAN_BOND_SEQ_1_2_1                     =>     ("0000000000"),
CHAN_BOND_SEQ_1_3_1                     =>     ("0000000000"),
CHAN_BOND_SEQ_1_4_1                     =>     ("0000000000"),
CHAN_BOND_SEQ_1_ENABLE_1                =>     ("0000"),
CHAN_BOND_SEQ_2_1_1                     =>     ("0000000000"),
CHAN_BOND_SEQ_2_2_1                     =>     ("0000000000"),
CHAN_BOND_SEQ_2_3_1                     =>     ("0000000000"),
CHAN_BOND_SEQ_2_4_1                     =>     ("0000000000"),
CHAN_BOND_SEQ_2_ENABLE_1                =>     ("0000"),
CHAN_BOND_SEQ_2_USE_1                   =>     (FALSE),
CHAN_BOND_SEQ_LEN_1                     =>     (1),
RX_EN_MODE_RESET_BUF_1                  =>     (TRUE),

--RX PCI Express Attributes
CB2_INH_CC_PERIOD_0                     =>     (8),
CDR_PH_ADJ_TIME_0                       =>     ("01010"),
PCI_EXPRESS_MODE_0                      =>     (FALSE),
RX_EN_IDLE_HOLD_CDR_0                   =>     (FALSE),
RX_EN_IDLE_RESET_FR_0                   =>     (TRUE),
RX_EN_IDLE_RESET_PH_0                   =>     (TRUE),
RX_STATUS_FMT_0                         =>     ("SATA"),
TRANS_TIME_FROM_P2_0                    =>     (x"03c"),
TRANS_TIME_NON_P2_0                     =>     (x"19"),
TRANS_TIME_TO_P2_0                      =>     (x"064"),
CB2_INH_CC_PERIOD_1                     =>     (8),
CDR_PH_ADJ_TIME_1                       =>     ("01010"),
PCI_EXPRESS_MODE_1                      =>     (FALSE),
RX_EN_IDLE_HOLD_CDR_1                   =>     (FALSE),
RX_EN_IDLE_RESET_FR_1                   =>     (TRUE),
RX_EN_IDLE_RESET_PH_1                   =>     (TRUE),
RX_STATUS_FMT_1                         =>     ("SATA"),
TRANS_TIME_FROM_P2_1                    =>     (x"03c"),
TRANS_TIME_NON_P2_1                     =>     (x"19"),
TRANS_TIME_TO_P2_1                      =>     (x"064"),

--RX SATA Attributes
SATA_BURST_VAL_0                        =>     ("100"),
SATA_IDLE_VAL_0                         =>     ("100"),
SATA_MAX_BURST_0                        =>     (7),
SATA_MAX_INIT_0                         =>     (22),
SATA_MAX_WAKE_0                         =>     (7),
SATA_MIN_BURST_0                        =>     (4),
SATA_MIN_INIT_0                         =>     (12),
SATA_MIN_WAKE_0                         =>     (4),
SATA_BURST_VAL_1                        =>     ("100"),
SATA_IDLE_VAL_1                         =>     ("100"),
SATA_MAX_BURST_1                        =>     (7),
SATA_MAX_INIT_1                         =>     (22),
SATA_MAX_WAKE_1                         =>     (7),
SATA_MIN_BURST_1                        =>     (4),
SATA_MIN_INIT_1                         =>     (12),
SATA_MIN_WAKE_1                         =>     (4)
)
port map(
------------------------ Loopback and Powerdown Ports ----------------------
LOOPBACK0                       =>      "000",
LOOPBACK1                       =>      "000",
RXPOWERDOWN0                    =>      "00",
RXPOWERDOWN1                    =>      "00",
TXPOWERDOWN0                    =>      "00",
TXPOWERDOWN1                    =>      "00",
--------------------------------- PLL Ports --------------------------------
CLK00                           =>      clkin,
CLK01                           =>      '0',--clkin,
CLK10                           =>      '0',--clkin,
CLK11                           =>      '0',--clkin,
CLKINEAST0                      =>      '0',
CLKINEAST1                      =>      '0',
CLKINWEST0                      =>      '0',
CLKINWEST1                      =>      '0',
GCLK00                          =>      '0',
GCLK01                          =>      '0',
GCLK10                          =>      '0',
GCLK11                          =>      '0',
GTPRESET0                       =>      '0',
GTPRESET1                       =>      '0',
GTPTEST0                        =>      "00010000",
GTPTEST1                        =>      "00010000",
INTDATAWIDTH0                   =>      '1',
INTDATAWIDTH1                   =>      '1',
PLLCLK00                        =>      '0',
PLLCLK01                        =>      '0',
PLLCLK10                        =>      '0',
PLLCLK11                        =>      '0',
PLLLKDET0                       =>      open,
PLLLKDET1                       =>      open,
PLLLKDETEN0                     =>      '1',
PLLLKDETEN1                     =>      '1',
PLLPOWERDOWN0                   =>      '0',
PLLPOWERDOWN1                   =>      '0',
REFCLKOUT0                      =>      open,
REFCLKOUT1                      =>      open,
REFCLKPLL0                      =>      open,
REFCLKPLL1                      =>      open,
REFCLKPWRDNB0                   =>      '1',
REFCLKPWRDNB1                   =>      '1',
REFSELDYPLL0                    =>      "000",
REFSELDYPLL1                    =>      "000",
RESETDONE0                      =>      open,
RESETDONE1                      =>      open,
TSTCLK0                         =>      '0',
TSTCLK1                         =>      '0',
TSTIN0                          =>      "000000000000",
TSTIN1                          =>      "000000000000",
TSTOUT0                         =>      open,
TSTOUT1                         =>      open,
----------------------- Receive Ports - 8b10b Decoder ----------------------
RXCHARISCOMMA0(3 downto 2)      =>      rxchariscomma0_float_i(3 downto 2),
RXCHARISCOMMA0(1 downto 0)      =>      rxchariscomma0_float_i(1 downto 0),
RXCHARISCOMMA1(3 downto 2)      =>      rxchariscomma1_float_i(3 downto 2),
RXCHARISCOMMA1(1 downto 0)      =>      rxchariscomma1_float_i(1 downto 0),
RXCHARISK0(3 downto 2)          =>      rxcharisk0_float_i(3 downto 2),
RXCHARISK0(1 downto 0)          =>      rxcharisk0_float_i(1 downto 0),
RXCHARISK1(3 downto 2)          =>      rxcharisk1_float_i(3 downto 2),
RXCHARISK1(1 downto 0)          =>      rxcharisk1_float_i(1 downto 0),
RXDEC8B10BUSE0                  =>      '1',
RXDEC8B10BUSE1                  =>      '1',
RXDISPERR0(3 downto 2)          =>      rxdisperr0_float_i(3 downto 2),
RXDISPERR0(1 downto 0)          =>      rxdisperr0_float_i(1 downto 0),
RXDISPERR1(3 downto 2)          =>      rxdisperr1_float_i(3 downto 2),
RXDISPERR1(1 downto 0)          =>      rxdisperr1_float_i(1 downto 0),
RXNOTINTABLE0(3 downto 2)       =>      rxnotintable0_float_i(3 downto 2),
RXNOTINTABLE0(1 downto 0)       =>      rxnotintable0_float_i(1 downto 0),
RXNOTINTABLE1(3 downto 2)       =>      rxnotintable1_float_i(3 downto 2),
RXNOTINTABLE1(1 downto 0)       =>      rxnotintable1_float_i(1 downto 0),
RXRUNDISP0                      =>      open,
RXRUNDISP1                      =>      open,
USRCODEERR0                     =>      '0',
USRCODEERR1                     =>      '0',
---------------------- Receive Ports - Channel Bonding ---------------------
RXCHANBONDSEQ0                  =>      open,
RXCHANBONDSEQ1                  =>      open,
RXCHANISALIGNED0                =>      open,
RXCHANISALIGNED1                =>      open,
RXCHANREALIGN0                  =>      open,
RXCHANREALIGN1                  =>      open,
RXCHBONDI                       =>      "000",
RXCHBONDMASTER0                 =>      '0',
RXCHBONDMASTER1                 =>      '0',
RXCHBONDO                       =>      open,
RXCHBONDSLAVE0                  =>      '0',
RXCHBONDSLAVE1                  =>      '0',
RXENCHANSYNC0                   =>      '0',
RXENCHANSYNC1                   =>      '0',
---------------------- Receive Ports - Clock Correction --------------------
RXCLKCORCNT0                    =>      open,
RXCLKCORCNT1                    =>      open,
--------------- Receive Ports - Comma Detection and Alignment --------------
RXBYTEISALIGNED0                =>      open,
RXBYTEISALIGNED1                =>      open,
RXBYTEREALIGN0                  =>      open,
RXBYTEREALIGN1                  =>      open,
RXCOMMADET0                     =>      open,
RXCOMMADET1                     =>      open,
RXCOMMADETUSE0                  =>      '1',
RXCOMMADETUSE1                  =>      '1',
RXENMCOMMAALIGN0                =>      '1',
RXENMCOMMAALIGN1                =>      '1',
RXENPCOMMAALIGN0                =>      '1',
RXENPCOMMAALIGN1                =>      '1',
RXSLIDE0                        =>      '0',
RXSLIDE1                        =>      '0',
----------------------- Receive Ports - PRBS Detection ---------------------
PRBSCNTRESET0                   =>      '0',
PRBSCNTRESET1                   =>      '0',
RXENPRBSTST0                    =>      "000",
RXENPRBSTST1                    =>      "000",
RXPRBSERR0                      =>      open,
RXPRBSERR1                      =>      open,
------------------- Receive Ports - RX Data Path interface -----------------
RXDATA0                         =>      open,
RXDATA1                         =>      open,
RXDATAWIDTH0                    =>      "00",
RXDATAWIDTH1                    =>      "00",
RXRECCLK0                       =>      open,
RXRECCLK1                       =>      open,
RXRESET0                        =>      '0',
RXRESET1                        =>      '0',
RXUSRCLK0                       =>      '0',
RXUSRCLK1                       =>      '0',
RXUSRCLK20                      =>      '0',
RXUSRCLK21                      =>      '0',
------- Receive Ports - RX Driver,OOB signalling,Coupling and Eq.,CDR ------
GATERXELECIDLE0                 =>      '0',
GATERXELECIDLE1                 =>      '0',
IGNORESIGDET0                   =>      '0',
IGNORESIGDET1                   =>      '0',
RCALINEAST                      =>      "00000",
RCALINWEST                      =>      "00000",
RCALOUTEAST                     =>      open,
RCALOUTWEST                     =>      open,
RXCDRRESET0                     =>      '0',
RXCDRRESET1                     =>      '0',
RXELECIDLE0                     =>      open,
RXELECIDLE1                     =>      open,
RXEQMIX0                        =>      "00",
RXEQMIX1                        =>      "00",
RXN0                            =>      p_in_rxn(0),
RXN1                            =>      p_in_rxn(1),
RXP0                            =>      p_in_rxp(0),
RXP1                            =>      p_in_rxp(1),
----------- Receive Ports - RX Elastic Buffer and Phase Alignment ----------
RXBUFRESET0                     =>      '0',
RXBUFRESET1                     =>      '0',
RXBUFSTATUS0                    =>      open,
RXBUFSTATUS1                    =>      open,
RXENPMAPHASEALIGN0              =>      '0',
RXENPMAPHASEALIGN1              =>      '0',
RXPMASETPHASE0                  =>      '0',
RXPMASETPHASE1                  =>      '0',
RXSTATUS0                       =>      open,
RXSTATUS1                       =>      open,
--------------- Receive Ports - RX Loss-of-sync State Machine --------------
RXLOSSOFSYNC0                   =>      open,
RXLOSSOFSYNC1                   =>      open,
-------------- Receive Ports - RX Pipe Control for PCI Express -------------
PHYSTATUS0                      =>      open,
PHYSTATUS1                      =>      open,
RXVALID0                        =>      open,
RXVALID1                        =>      open,
-------------------- Receive Ports - RX Polarity Control -------------------
RXPOLARITY0                     =>      '0',
RXPOLARITY1                     =>      '0',
------------- Shared Ports - Dynamic Reconfiguration Port (DRP) ------------
DADDR                           =>      "00000000",
DCLK                            =>      '0',
DEN                             =>      '0',
DI                              =>      "0000000000000000",
DRDY                            =>      open,
DRPDO                           =>      open,
DWE                             =>      '0',
---------------------------- TX/RX Datapath Ports --------------------------
GTPCLKFBEAST                    =>      open,
GTPCLKFBSEL0EAST                =>      "10",
GTPCLKFBSEL0WEST                =>      "00",
GTPCLKFBSEL1EAST                =>      "11",
GTPCLKFBSEL1WEST                =>      "01",
GTPCLKFBWEST                    =>      open,
GTPCLKOUT0                      =>      i_gtpclkout0(1 downto 0),
GTPCLKOUT1                      =>      i_gtpclkout1(1 downto 0),
------------------- Transmit Ports - 8b10b Encoder Control -----------------
TXBYPASS8B10B0                  =>      "0000",
TXBYPASS8B10B1                  =>      "0000",
TXCHARDISPMODE0                 =>      "0000",
TXCHARDISPMODE1                 =>      "0000",
TXCHARDISPVAL0                  =>      "0000",
TXCHARDISPVAL1                  =>      "0000",
TXCHARISK0(3 downto 2)          =>      "00",
TXCHARISK0(1 downto 0)          =>      "00",
TXCHARISK1(3 downto 2)          =>      "00",
TXCHARISK1(1 downto 0)          =>      "00",
TXENC8B10BUSE0                  =>      '1',
TXENC8B10BUSE1                  =>      '1',
TXKERR0                         =>      open,
TXKERR1                         =>      open,
TXRUNDISP0                      =>      open,
TXRUNDISP1                      =>      open,
--------------- Transmit Ports - TX Buffer and Phase Alignment -------------
TXBUFSTATUS0                    =>      open,
TXBUFSTATUS1                    =>      open,
TXENPMAPHASEALIGN0              =>      '0',
TXENPMAPHASEALIGN1              =>      '0',
TXPMASETPHASE0                  =>      '0',
TXPMASETPHASE1                  =>      '0',
------------------ Transmit Ports - TX Data Path interface -----------------
TXDATA0                         =>      "00000000000000000000000000000000",
TXDATA1                         =>      "00000000000000000000000000000000",
TXDATAWIDTH0                    =>      "00",
TXDATAWIDTH1                    =>      "00",
TXOUTCLK0                       =>      open,
TXOUTCLK1                       =>      open,
TXRESET0                        =>      '0',
TXRESET1                        =>      '0',
TXUSRCLK0                       =>      '0',
TXUSRCLK1                       =>      '0',
TXUSRCLK20                      =>      '0',
TXUSRCLK21                      =>      '0',
--------------- Transmit Ports - TX Driver and OOB signalling --------------
TXBUFDIFFCTRL0                  =>      "101",
TXBUFDIFFCTRL1                  =>      "101",
TXDIFFCTRL0                     =>      "0111",
TXDIFFCTRL1                     =>      "0111",
TXINHIBIT0                      =>      '0',
TXINHIBIT1                      =>      '0',
TXN0                            =>      p_out_txn(0),
TXN1                            =>      p_out_txn(1),
TXP0                            =>      p_out_txp(0),
TXP1                            =>      p_out_txp(1),
TXPREEMPHASIS0                  =>      "010",
TXPREEMPHASIS1                  =>      "010",
--------------------- Transmit Ports - TX PRBS Generator -------------------
TXENPRBSTST0                    =>      "000",
TXENPRBSTST1                    =>      "000",
TXPRBSFORCEERR0                 =>      '0',
TXPRBSFORCEERR1                 =>      '0',
-------------------- Transmit Ports - TX Polarity Control ------------------
TXPOLARITY0                     =>      '0',
TXPOLARITY1                     =>      '0',
----------------- Transmit Ports - TX Ports for PCI Express ----------------
TXDETECTRX0                     =>      '0',
TXDETECTRX1                     =>      '0',
TXELECIDLE0                     =>      '0',
TXELECIDLE1                     =>      '0',
TXPDOWNASYNCH0                  =>      '0',
TXPDOWNASYNCH1                  =>      '0',
--------------------- Transmit Ports - TX Ports for SATA -------------------
TXCOMSTART0                     =>      '0',
TXCOMSTART1                     =>      '0',
TXCOMTYPE0                      =>      '0',
TXCOMTYPE1                      =>      '0'

);

end generate gen_sim_off;


end architecture;
