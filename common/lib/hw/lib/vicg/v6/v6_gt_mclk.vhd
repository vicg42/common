--
-- mclk_gtp_wrap.vhd - Wrapper for a GTP_DUAL instance that bypasses the
--                     GTP_DUAL and provides just the clock out from the
--                     instance, given an MGT reference clock input
--                     signal.
--
-- Modules defined:
--
--    mclk_gtp_wrap       GTP_DUAL wrapper providing output clock
--
-- This module can be used to input MCLKA and/or MCLKB and serves a similar
-- purpose to an IBUFG on the following model(s):
--
--   o ADM-XRC-5T1
--

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library unisim;
use unisim.vcomponents.all;

library work;
use work.vicg_common_pkg.all;

entity mclk_gtp_wrap is
generic(
G_SIM  : string:="OFF"
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

architecture virtex6_only of mclk_gtp_wrap is

signal i_refclkin                  : std_logic_vector(1 downto 0);

signal rxchariscomma_float_i       : std_logic_vector(3 downto 0);
signal rxcharisk_float_i           : std_logic_vector(3 downto 0);
signal rxdisperr_float_i           : std_logic_vector(3 downto 0);
signal rxnotintable_float_i        : std_logic_vector(3 downto 0);

begin

gen_sim_on : if strcmp(G_SIM,"ON") generate
p_out_txn<=p_in_rxn;
p_out_txp<=p_in_rxp;

clkout<=clkin;
end generate gen_sim_on;

p_out_txn(1)<='0';
p_out_txp(1)<='0';

gen_sim_off : if strcmp(G_SIM,"OFF") generate

i_refclkin <= ('0' & clkin);

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
TXOUTCLK_CTRL                           =>     ("TXOUTCLKPMA_DIV1"),
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
RXRECCLK_CTRL                           =>     ("RXRECCLKPMA_DIV1"),
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
ALIGN_COMMA_WORD                        =>     1,
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
RXCHARISCOMMA(3 downto 2)       =>      rxchariscomma_float_i(3 downto 2),
RXCHARISCOMMA(1 downto 0)       =>      rxchariscomma_float_i(1 downto 0),
RXCHARISK(3 downto 2)           =>      rxcharisk_float_i(3 downto 2),
RXCHARISK(1 downto 0)           =>      rxcharisk_float_i(1 downto 0),
RXDEC8B10BUSE                   =>      '1',
RXDISPERR(3 downto 2)           =>      rxdisperr_float_i(3 downto 2),
RXDISPERR(1 downto 0)           =>      rxdisperr_float_i(1 downto 0),
RXNOTINTABLE(3 downto 2)        =>      rxnotintable_float_i(3 downto 2),
RXNOTINTABLE(1 downto 0)        =>      rxnotintable_float_i(1 downto 0),
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
RXBYTEISALIGNED                 =>      open,
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
RXDATA                          =>      open,
RXRECCLK                        =>      open,--RXRECCLK_OUT,
RXRECCLKPCS                     =>      open,
RXRESET                         =>      '0',
RXUSRCLK                        =>      '0',
RXUSRCLK2                       =>      '0',
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
RXCDRRESET                      =>      '0',
RXELECIDLE                      =>      open,
RXEQMIX(9 downto 3)             =>      "0000000",
RXEQMIX(2 downto 0)             =>      "111",--RXEQMIX_IN,
RXN                             =>      p_in_rxn(0),--//############################### add vicg
RXP                             =>      p_in_rxp(0),--//############################### add vicg
-------- Receive Ports - RX Elastic Buffer and Phase Alignment Ports -------
RXBUFRESET                      =>      '0',
RXBUFSTATUS                     =>      open,
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
GTXRXRESET                      =>      '0',
MGTREFCLKRX                     =>      "00",
NORTHREFCLKRX                   =>      "00",--NORTHREFCLKRX_IN,
PERFCLKRX                       =>      '0',--PERFCLKRX_IN,
PLLRXRESET                      =>      '0',--PLLRXRESET_IN,
RXPLLLKDET                      =>      open,
RXPLLLKDETEN                    =>      '1',
RXPLLPOWERDOWN                  =>      '0',
RXPLLREFSELDY                   =>      "000",--RXPLLREFSELDY_IN,
RXRATE                          =>      "00",
RXRATEDONE                      =>      open,
RXRESETDONE                     =>      open,
SOUTHREFCLKRX                   =>      "00",--SOUTHREFCLKRX_IN,
-------------- Receive Ports - RX Pipe Control for PCI Express -------------
PHYSTATUS                       =>      open,
RXVALID                         =>      open,
----------------- Receive Ports - RX Polarity Control Ports ----------------
RXPOLARITY                      =>      '0',
--------------------- Receive Ports - RX Ports for SATA --------------------
COMINITDET                      =>      open,
COMSASDET                       =>      open,
COMWAKEDET                      =>      open,
------------- Shared Ports - Dynamic Reconfiguration Port (DRP) ------------
DADDR                           =>      "00000000",
DCLK                            =>      '0',
DEN                             =>      '0',
DI                              =>      "0000000000000000",
DRDY                            =>      open,
DRPDO                           =>      open,
DWE                             =>      '0',

-------------- Transmit Ports - 64b66b and 64b67b Gearbox Ports ------------
TXGEARBOXREADY                  =>      open,
TXHEADER                        =>      "000",
TXSEQUENCE                      =>      "0000000",
TXSTARTSEQ                      =>      '0',
---------------- Transmit Ports - 8b10b Encoder Control Ports --------------
TXBYPASS8B10B                   =>      "0000",
TXCHARDISPMODE                  =>      "0000",
TXCHARDISPVAL                   =>      "0000",
TXCHARISK(3 downto 2)           =>      "00",
TXCHARISK(1 downto 0)           =>      "00",
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
TXDATA                          =>      "00000000000000000000000000000000",
TXOUTCLK                        =>      clkout,--//############################### add vicg
TXOUTCLKPCS                     =>      open,
TXRESET                         =>      '0',
TXUSRCLK                        =>      '0',
TXUSRCLK2                       =>      '0',
---------------- Transmit Ports - TX Driver and OOB signaling --------------
TXBUFDIFFCTRL                   =>      "100",
TXDIFFCTRL                      =>      "0000",
TXINHIBIT                       =>      '0',
TXN                             =>      p_out_txn(0),
TXP                             =>      p_out_txp(0),
TXPOSTEMPHASIS                  =>      "00000",
--------------- Transmit Ports - TX Driver and OOB signalling --------------
TXPREEMPHASIS                   =>      "0000",
----------- Transmit Ports - TX Elastic Buffer and Phase Alignment ---------
TXBUFSTATUS                     =>      open,
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
GREFCLKTX                       =>      '0',
GTXTXRESET                      =>      '0',
MGTREFCLKTX                     =>      i_refclkin,
NORTHREFCLKTX                   =>      "00",--NORTHREFCLKTX_IN,
PERFCLKTX                       =>      '0',--PERFCLKTX_IN,
PLLTXRESET                      =>      '0',
SOUTHREFCLKTX                   =>      "00",--SOUTHREFCLKTX_IN,
TXPLLLKDET                      =>      open,
TXPLLLKDETEN                    =>      '1',
TXPLLPOWERDOWN                  =>      '0',
TXPLLREFSELDY                   =>      "000",--TXPLLREFSELDY_IN,
TXRATE                          =>      "00",
TXRATEDONE                      =>      open,
TXRESETDONE                     =>      open,
--------------------- Transmit Ports - TX PRBS Generator -------------------
TXENPRBSTST                     =>      "000",
TXPRBSFORCEERR                  =>      '0',
-------------------- Transmit Ports - TX Polarity Control ------------------
TXPOLARITY                      =>      '0',
----------------- Transmit Ports - TX Ports for PCI Express ----------------
TXDEEMPH                        =>      '0',
TXDETECTRX                      =>      '0',
TXELECIDLE                      =>      '0',
TXMARGIN                        =>      "000",
TXPDOWNASYNCH                   =>      '0',
TXSWING                         =>      '0',
--------------------- Transmit Ports - TX Ports for SATA -------------------
COMFINISH                       =>      open,
TXCOMINIT                       =>      '0',
TXCOMSAS                        =>      '0',
TXCOMWAKE                       =>      '0'
);

end generate gen_sim_off;


end virtex6_only;
