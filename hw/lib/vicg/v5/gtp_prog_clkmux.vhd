-------------------------------------------------------------------------
-- Company     : Linkos
-- Engineer    : Golovachenko Victor
--
-- Create Date : 03/04/2010
-- Module Name : gtp_prog_clkmux
--
-- ����������/�������� : �������������������� GTP, � ������ �������������� CLKIN - ����� ��������� ������� �������
--                       ��� RocketIO + �������������������� ��������� ������� ������� ������� �� ���. clk �����. GTP
--
-- Revision:
-- Revision 0.01 - File Created
--
-------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- synopsys translate_off
library unisim;
use unisim.vcomponents.all;
-- synopsys translate_on

library work;

entity gtp_prog_clkmux is
generic(
G_CLKIN_CHANGE             : std_logic := '0';--//'1'/'0' - ����������/������ ��������� ��������� �������������� CLKIN
G_CLKSOUTH_CHANGE          : std_logic := '0';--//'1'/'0' - ����������/������ ��������� ��������� �������������� CLKSOUTH
G_CLKNORTH_CHANGE          : std_logic := '0';--//'1'/'0' - ����������/������ ��������� ��������� �������������� CLKNORTH

G_CLKIN_MUX_VAL            : std_logic_vector(2 downto 0):="011"; --//�������� ��� �������������� CLKIN
G_CLKSOUTH_MUX_VAL         : std_logic := '0';                    --//�������� ��� �������������� CLKSOUTH
G_CLKNORTH_MUX_VAL         : std_logic := '0'                     --//�������� ��� �������������� CLKNORTH
);
port(
p_in_drp_rst      : in    std_logic;
p_in_drp_clk      : in    std_logic;

p_out_txp         : out   std_logic_vector(1 downto 0);
p_out_txn         : out   std_logic_vector(1 downto 0);
p_in_rxp          : in    std_logic_vector(1 downto 0);
p_in_rxn          : in    std_logic_vector(1 downto 0);

p_in_clkin        : in    std_logic;
p_out_refclkout   : out   std_logic
);
end gtp_prog_clkmux;

architecture behavioral of gtp_prog_clkmux is

--component BUFG port(I : in  std_logic; O  : out std_logic);end component;

component gtp_drp_ctrl
generic
(
G_USE_USRCTLR      : integer   := 0;

G_CLKIN_CHANGE     : std_logic := '0';
G_CLKSOUTH_CHANGE  : std_logic := '0';
G_CLKNORTH_CHANGE  : std_logic := '0';

G_CLKIN_MUX_VAL    : std_logic_vector(2 downto 0):="011";
G_CLKSOUTH_MUX_VAL : std_logic := '0';
G_CLKNORTH_MUX_VAL : std_logic := '0'
);
port
(
p_in_usr_ctrl     : in    std_logic_vector(31 downto 0);

--------------------------------------------------
--RocketIO
--------------------------------------------------
p_out_gtp_drpclk  : out   std_logic;
p_out_gtp_drpaddr : out   std_logic_vector(6 downto 0);--Dynamic Reconfiguration Port (DRP)
p_out_gtp_drpen   : out   std_logic;
p_out_gtp_drpwe   : out   std_logic;
p_out_gtp_drpdi   : out   std_logic_vector(15 downto 0);
p_in_gtp_drpdo    : in    std_logic_vector(15 downto 0);
p_in_gtp_drprdy   : in    std_logic;

p_out_gtp_rst     : out   std_logic;

--------------------------------------------------
--��������������� �������
--------------------------------------------------
p_out_tst         : out   std_logic_vector(31 downto 0);

--------------------------------------------------
--SYSTEM
--------------------------------------------------
p_in_clk          : in    std_logic;--
p_in_rst          : in    std_logic --
);
end component;

signal i_gtp_drpclk        : std_logic;
signal i_gtp_drpaddr       : std_logic_vector(6 downto 0);
signal i_gtp_drpen         : std_logic;
signal i_gtp_drpwe         : std_logic;
signal i_gtp_drpdi         : std_logic_vector(15 downto 0);
signal i_gtp_drpdo         : std_logic_vector(15 downto 0);
signal i_gtp_drprdy        : std_logic;

signal i_gtp_rst           : std_logic;
--signal i_gtp_prog_clkmux     : std_logic;

component GTP_DUAL is
    generic(
        -- synthesis translate_off
        SIM_RECEIVER_DETECT_PASS0  : boolean;
        SIM_RECEIVER_DETECT_PASS1  : boolean;
        SIM_GTPRESET_SPEEDUP       : integer;
        -- synthesis translate_on
        AC_CAP_DIS_0               : boolean;
        AC_CAP_DIS_1               : boolean;
        ALIGN_COMMA_WORD_0         : integer;
        ALIGN_COMMA_WORD_1         : integer;
        CHAN_BOND_1_MAX_SKEW_0     : integer;
        CHAN_BOND_1_MAX_SKEW_1     : integer;
        CHAN_BOND_2_MAX_SKEW_0     : integer;
        CHAN_BOND_2_MAX_SKEW_1     : integer;
        CHAN_BOND_LEVEL_0          : integer;
        CHAN_BOND_LEVEL_1          : integer;
        CHAN_BOND_MODE_0           : string;
        CHAN_BOND_MODE_1           : string;
        CHAN_BOND_SEQ_2_USE_0      : boolean;
        CHAN_BOND_SEQ_2_USE_1      : boolean;
        CHAN_BOND_SEQ_LEN_0        : integer;
        CHAN_BOND_SEQ_LEN_1        : integer;
        CLK25_DIVIDER              : integer;
        CLKINDC_B                  : boolean;
        CLK_CORRECT_USE_0          : boolean;
        CLK_CORRECT_USE_1          : boolean;
        CLK_COR_ADJ_LEN_0          : integer;
        CLK_COR_ADJ_LEN_1          : integer;
        CLK_COR_DET_LEN_0          : integer;
        CLK_COR_DET_LEN_1          : integer;
        CLK_COR_INSERT_IDLE_FLAG_0 : boolean;
        CLK_COR_INSERT_IDLE_FLAG_1 : boolean;
        CLK_COR_KEEP_IDLE_0        : boolean;
        CLK_COR_KEEP_IDLE_1        : boolean;
        CLK_COR_MAX_LAT_0          : integer;
        CLK_COR_MAX_LAT_1          : integer;
        CLK_COR_MIN_LAT_0          : integer;
        CLK_COR_MIN_LAT_1          : integer;
        CLK_COR_PRECEDENCE_0       : boolean;
        CLK_COR_PRECEDENCE_1       : boolean;
        CLK_COR_REPEAT_WAIT_0      : integer;
        CLK_COR_REPEAT_WAIT_1      : integer;
        CLK_COR_SEQ_2_USE_0        : boolean;
        CLK_COR_SEQ_2_USE_1        : boolean;
        COMMA_DOUBLE_0             : boolean;
        COMMA_DOUBLE_1             : boolean;
        DEC_MCOMMA_DETECT_0        : boolean;
        DEC_MCOMMA_DETECT_1        : boolean;
        DEC_PCOMMA_DETECT_0        : boolean;
        DEC_PCOMMA_DETECT_1        : boolean;
        DEC_VALID_COMMA_ONLY_0     : boolean;
        DEC_VALID_COMMA_ONLY_1     : boolean;
        MCOMMA_DETECT_0            : boolean;
        MCOMMA_DETECT_1            : boolean;
        OOB_CLK_DIVIDER            : integer;
        OVERSAMPLE_MODE            : boolean;
        PCI_EXPRESS_MODE_0         : boolean;
        PCI_EXPRESS_MODE_1         : boolean;
        PCOMMA_DETECT_0            : boolean;
        PCOMMA_DETECT_1            : boolean;
        PLL_DIVSEL_FB              : integer;
        PLL_DIVSEL_REF             : integer;
        PLL_RXDIVSEL_OUT_0         : integer;
        PLL_RXDIVSEL_OUT_1         : integer;
        PLL_SATA_0                 : boolean;
        PLL_SATA_1                 : boolean;
        PLL_TXDIVSEL_COMM_OUT      : integer;
        PLL_TXDIVSEL_OUT_0         : integer;
        PLL_TXDIVSEL_OUT_1         : integer;
        RCV_TERM_GND_0             : boolean;
        RCV_TERM_GND_1             : boolean;
        RCV_TERM_MID_0             : boolean;
        RCV_TERM_MID_1             : boolean;
        RCV_TERM_VTTRX_0           : boolean;
        RCV_TERM_VTTRX_1           : boolean;
        RX_BUFFER_USE_0            : boolean;
        RX_BUFFER_USE_1            : boolean;
        RX_DECODE_SEQ_MATCH_0      : boolean;
        RX_DECODE_SEQ_MATCH_1      : boolean;
        RX_LOSS_OF_SYNC_FSM_0      : boolean;
        RX_LOSS_OF_SYNC_FSM_1      : boolean;
        RX_LOS_INVALID_INCR_0      : integer;
        RX_LOS_INVALID_INCR_1      : integer;
        RX_LOS_THRESHOLD_0         : integer;
        RX_LOS_THRESHOLD_1         : integer;
        RX_SLIDE_MODE_0            : string;
        RX_SLIDE_MODE_1            : string;
        RX_STATUS_FMT_0            : string;
        RX_STATUS_FMT_1            : string;
        RX_XCLK_SEL_0              : string;
        RX_XCLK_SEL_1              : string;
        SATA_MAX_BURST_0           : integer;
        SATA_MAX_BURST_1           : integer;
        SATA_MAX_INIT_0            : integer;
        SATA_MAX_INIT_1            : integer;
        SATA_MAX_WAKE_0            : integer;
        SATA_MAX_WAKE_1            : integer;
        SATA_MIN_BURST_0           : integer;
        SATA_MIN_BURST_1           : integer;
        SATA_MIN_INIT_0            : integer;
        SATA_MIN_INIT_1            : integer;
        SATA_MIN_WAKE_0            : integer;
        SATA_MIN_WAKE_1            : integer;
        TERMINATION_IMP_0          : integer;
        TERMINATION_IMP_1          : integer;
        TERMINATION_OVRD           : boolean;
        TX_BUFFER_USE_0            : boolean;
        TX_BUFFER_USE_1            : boolean;
        TX_DIFF_BOOST_0            : boolean;
        TX_DIFF_BOOST_1            : boolean;
        TX_SYNC_FILTERB            : integer;
        TX_XCLK_SEL_0              : string;
        TX_XCLK_SEL_1              : string;
        CHAN_BOND_SEQ_1_1_0        : bit_vector(9 downto 0);
        CHAN_BOND_SEQ_1_1_1        : bit_vector(9 downto 0);
        CHAN_BOND_SEQ_1_2_0        : bit_vector(9 downto 0);
        CHAN_BOND_SEQ_1_2_1        : bit_vector(9 downto 0);
        CHAN_BOND_SEQ_1_3_0        : bit_vector(9 downto 0);
        CHAN_BOND_SEQ_1_3_1        : bit_vector(9 downto 0);
        CHAN_BOND_SEQ_1_4_0        : bit_vector(9 downto 0);
        CHAN_BOND_SEQ_1_4_1        : bit_vector(9 downto 0);
        CHAN_BOND_SEQ_1_ENABLE_0   : bit_vector(3 downto 0);
        CHAN_BOND_SEQ_1_ENABLE_1   : bit_vector(3 downto 0);
        CHAN_BOND_SEQ_2_1_0        : bit_vector(9 downto 0);
        CHAN_BOND_SEQ_2_1_1        : bit_vector(9 downto 0);
        CHAN_BOND_SEQ_2_2_0        : bit_vector(9 downto 0);
        CHAN_BOND_SEQ_2_2_1        : bit_vector(9 downto 0);
        CHAN_BOND_SEQ_2_3_0        : bit_vector(9 downto 0);
        CHAN_BOND_SEQ_2_3_1        : bit_vector(9 downto 0);
        CHAN_BOND_SEQ_2_4_0        : bit_vector(9 downto 0);
        CHAN_BOND_SEQ_2_4_1        : bit_vector(9 downto 0);
        CHAN_BOND_SEQ_2_ENABLE_0   : bit_vector(3 downto 0);
        CHAN_BOND_SEQ_2_ENABLE_1   : bit_vector(3 downto 0);
        CLK_COR_SEQ_1_1_0          : bit_vector(9 downto 0);
        CLK_COR_SEQ_1_1_1          : bit_vector(9 downto 0);
        CLK_COR_SEQ_1_2_0          : bit_vector(9 downto 0);
        CLK_COR_SEQ_1_2_1          : bit_vector(9 downto 0);
        CLK_COR_SEQ_1_3_0          : bit_vector(9 downto 0);
        CLK_COR_SEQ_1_3_1          : bit_vector(9 downto 0);
        CLK_COR_SEQ_1_4_0          : bit_vector(9 downto 0);
        CLK_COR_SEQ_1_4_1          : bit_vector(9 downto 0);
        CLK_COR_SEQ_1_ENABLE_0     : bit_vector(3 downto 0);
        CLK_COR_SEQ_1_ENABLE_1     : bit_vector(3 downto 0);
        CLK_COR_SEQ_2_1_0          : bit_vector(9 downto 0);
        CLK_COR_SEQ_2_1_1          : bit_vector(9 downto 0);
        CLK_COR_SEQ_2_2_0          : bit_vector(9 downto 0);
        CLK_COR_SEQ_2_2_1          : bit_vector(9 downto 0);
        CLK_COR_SEQ_2_3_0          : bit_vector(9 downto 0);
        CLK_COR_SEQ_2_3_1          : bit_vector(9 downto 0);
        CLK_COR_SEQ_2_4_0          : bit_vector(9 downto 0);
        CLK_COR_SEQ_2_4_1          : bit_vector(9 downto 0);
        CLK_COR_SEQ_2_ENABLE_0     : bit_vector(3 downto 0);
        CLK_COR_SEQ_2_ENABLE_1     : bit_vector(3 downto 0);
        COMMA_10B_ENABLE_0         : bit_vector(9 downto 0);
        COMMA_10B_ENABLE_1         : bit_vector(9 downto 0);
        COM_BURST_VAL_0            : bit_vector(3 downto 0);
        COM_BURST_VAL_1            : bit_vector(3 downto 0);
        MCOMMA_10B_VALUE_0         : bit_vector(9 downto 0);
        MCOMMA_10B_VALUE_1         : bit_vector(9 downto 0);
        OOBDETECT_THRESHOLD_0      : bit_vector(2 downto 0);
        OOBDETECT_THRESHOLD_1      : bit_vector(2 downto 0);
        PCOMMA_10B_VALUE_0         : bit_vector(9 downto 0);
        PCOMMA_10B_VALUE_1         : bit_vector(9 downto 0);
        PMA_CDR_SCAN_0             : bit_vector(26 downto 0);
        PMA_CDR_SCAN_1             : bit_vector(26 downto 0);
        PMA_RX_CFG_0               : bit_vector(24 downto 0);
        PMA_RX_CFG_1               : bit_vector(24 downto 0);
        PRBS_ERR_THRESHOLD_0       : bit_vector(31 downto 0);
        PRBS_ERR_THRESHOLD_1       : bit_vector(31 downto 0);
        SATA_BURST_VAL_0           : bit_vector(2 downto 0);
        SATA_BURST_VAL_1           : bit_vector(2 downto 0);
        SATA_IDLE_VAL_0            : bit_vector(2 downto 0);
        SATA_IDLE_VAL_1            : bit_vector(2 downto 0);
        TERMINATION_CTRL           : bit_vector(4 downto 0);
        TRANS_TIME_FROM_P2_0       : bit_vector(15 downto 0);
        TRANS_TIME_FROM_P2_1       : bit_vector(15 downto 0);
        TRANS_TIME_NON_P2_0        : bit_vector(15 downto 0);
        TRANS_TIME_NON_P2_1        : bit_vector(15 downto 0);
        TRANS_TIME_TO_P2_0         : bit_vector(15 downto 0);
        TRANS_TIME_TO_P2_1         : bit_vector(15 downto 0);
        TXRX_INVERT_0              : bit_vector(4 downto 0);
        TXRX_INVERT_1              : bit_vector(4 downto 0));
    port(
        DO                         : out std_logic_vector(15 downto 0);
        DRDY                       : out std_logic;
        PHYSTATUS0                 : out std_logic;
        PHYSTATUS1                 : out std_logic;
        PLLLKDET                   : out std_logic;
        REFCLKOUT                  : out std_logic;
        RESETDONE0                 : out std_logic;
        RESETDONE1                 : out std_logic;
        RXBUFSTATUS0               : out std_logic_vector(2 downto 0);
        RXBUFSTATUS1               : out std_logic_vector(2 downto 0);
        RXBYTEISALIGNED0           : out std_logic;
        RXBYTEISALIGNED1           : out std_logic;
        RXBYTEREALIGN0             : out std_logic;
        RXBYTEREALIGN1             : out std_logic;
        RXCHANBONDSEQ0             : out std_logic;
        RXCHANBONDSEQ1             : out std_logic;
        RXCHANISALIGNED0           : out std_logic;
        RXCHANISALIGNED1           : out std_logic;
        RXCHANREALIGN0             : out std_logic;
        RXCHANREALIGN1             : out std_logic;
        RXCHARISCOMMA0             : out std_logic_vector(1 downto 0);
        RXCHARISCOMMA1             : out std_logic_vector(1 downto 0);
        RXCHARISK0                 : out std_logic_vector(1 downto 0);
        RXCHARISK1                 : out std_logic_vector(1 downto 0);
        RXCHBONDO0                 : out std_logic_vector(2 downto 0);
        RXCHBONDO1                 : out std_logic_vector(2 downto 0);
        RXCLKCORCNT0               : out std_logic_vector(2 downto 0);
        RXCLKCORCNT1               : out std_logic_vector(2 downto 0);
        RXCOMMADET0                : out std_logic;
        RXCOMMADET1                : out std_logic;
        RXDATA0                    : out std_logic_vector(15 downto 0);
        RXDATA1                    : out std_logic_vector(15 downto 0);
        RXDISPERR0                 : out std_logic_vector(1 downto 0);
        RXDISPERR1                 : out std_logic_vector(1 downto 0);
        RXELECIDLE0                : out std_logic;
        RXELECIDLE1                : out std_logic;
        RXLOSSOFSYNC0              : out std_logic_vector(1 downto 0);
        RXLOSSOFSYNC1              : out std_logic_vector(1 downto 0);
        RXNOTINTABLE0              : out std_logic_vector(1 downto 0);
        RXNOTINTABLE1              : out std_logic_vector(1 downto 0);
        RXOVERSAMPLEERR0           : out std_logic;
        RXOVERSAMPLEERR1           : out std_logic;
        RXPRBSERR0                 : out std_logic;
        RXPRBSERR1                 : out std_logic;
        RXRECCLK0                  : out std_logic;
        RXRECCLK1                  : out std_logic;
        RXRUNDISP0                 : out std_logic_vector(1 downto 0);
        RXRUNDISP1                 : out std_logic_vector(1 downto 0);
        RXSTATUS0                  : out std_logic_vector(2 downto 0);
        RXSTATUS1                  : out std_logic_vector(2 downto 0);
        RXVALID0                   : out std_logic;
        RXVALID1                   : out std_logic;
        TXBUFSTATUS0               : out std_logic_vector(1 downto 0);
        TXBUFSTATUS1               : out std_logic_vector(1 downto 0);
        TXKERR0                    : out std_logic_vector(1 downto 0);
        TXKERR1                    : out std_logic_vector(1 downto 0);
        TXN0                       : out std_logic; --inout std_logic;
        TXN1                       : out std_logic; --inout std_logic;
        TXOUTCLK0                  : out std_logic;
        TXOUTCLK1                  : out std_logic;
        TXP0                       : out std_logic; --inout std_logic;
        TXP1                       : out std_logic; --inout std_logic;
        TXRUNDISP0                 : out std_logic_vector(1 downto 0);
        TXRUNDISP1                 : out std_logic_vector(1 downto 0);
        CLKIN                      : in std_logic;
        DADDR                      : in std_logic_vector(6 downto 0);
        DCLK                       : in std_logic;
        DEN                        : in std_logic;
        DI                         : in std_logic_vector(15 downto 0);
        DWE                        : in std_logic;
        GTPRESET                   : in std_logic;
        INTDATAWIDTH               : in std_logic;
        LOOPBACK0                  : in std_logic_vector(2 downto 0);
        LOOPBACK1                  : in std_logic_vector(2 downto 0);
        PLLLKDETEN                 : in std_logic;
        PLLPOWERDOWN               : in std_logic;
        PRBSCNTRESET0              : in std_logic;
        PRBSCNTRESET1              : in std_logic;
        REFCLKPWRDNB               : in std_logic;
        RXBUFRESET0                : in std_logic;
        RXBUFRESET1                : in std_logic;
        RXCDRRESET0                : in std_logic;
        RXCDRRESET1                : in std_logic;
        RXCHBONDI0                 : in std_logic_vector(2 downto 0);
        RXCHBONDI1                 : in std_logic_vector(2 downto 0);
        RXCOMMADETUSE0             : in std_logic;
        RXCOMMADETUSE1             : in std_logic;
        RXDATAWIDTH0               : in std_logic;
        RXDATAWIDTH1               : in std_logic;
        RXDEC8B10BUSE0             : in std_logic;
        RXDEC8B10BUSE1             : in std_logic;
        RXENCHANSYNC0              : in std_logic;
        RXENCHANSYNC1              : in std_logic;
        RXENEQB0                   : in std_logic;
        RXENEQB1                   : in std_logic;
        RXENMCOMMAALIGN0           : in std_logic;
        RXENMCOMMAALIGN1           : in std_logic;
        RXENPCOMMAALIGN0           : in std_logic;
        RXENPCOMMAALIGN1           : in std_logic;
        RXENPRBSTST0               : in std_logic_vector(1 downto 0);
        RXENPRBSTST1               : in std_logic_vector(1 downto 0);
        RXENSAMPLEALIGN0           : in std_logic;
        RXENSAMPLEALIGN1           : in std_logic;
        RXEQMIX0                   : in std_logic_vector(1 downto 0);
        RXEQMIX1                   : in std_logic_vector(1 downto 0);
        RXEQPOLE0                  : in std_logic_vector(3 downto 0);
        RXEQPOLE1                  : in std_logic_vector(3 downto 0);
        RXN0                       : in std_logic;
        RXN1                       : in std_logic;
        RXP0                       : in std_logic;
        RXP1                       : in std_logic;
        RXPMASETPHASE0             : in std_logic;
        RXPMASETPHASE1             : in std_logic;
        RXPOLARITY0                : in std_logic;
        RXPOLARITY1                : in std_logic;
        RXPOWERDOWN0               : in std_logic_vector(1 downto 0);
        RXPOWERDOWN1               : in std_logic_vector(1 downto 0);
        RXRESET0                   : in std_logic;
        RXRESET1                   : in std_logic;
        RXSLIDE0                   : in std_logic;
        RXSLIDE1                   : in std_logic;
        RXUSRCLK0                  : in std_logic;
        RXUSRCLK1                  : in std_logic;
        RXUSRCLK20                 : in std_logic;
        RXUSRCLK21                 : in std_logic;
        RXELECIDLERESET0           : in std_logic;
        RXELECIDLERESET1           : in std_logic;
        RXENELECIDLERESETB         : in std_logic;
        TXBUFDIFFCTRL0             : in std_logic_vector(2 downto 0);
        TXBUFDIFFCTRL1             : in std_logic_vector(2 downto 0);
        TXBYPASS8B10B0             : in std_logic_vector(1 downto 0);
        TXBYPASS8B10B1             : in std_logic_vector(1 downto 0);
        TXCHARDISPMODE0            : in std_logic_vector(1 downto 0);
        TXCHARDISPMODE1            : in std_logic_vector(1 downto 0);
        TXCHARDISPVAL0             : in std_logic_vector(1 downto 0);
        TXCHARDISPVAL1             : in std_logic_vector(1 downto 0);
        TXCHARISK0                 : in std_logic_vector(1 downto 0);
        TXCHARISK1                 : in std_logic_vector(1 downto 0);
        TXCOMSTART0                : in std_logic;
        TXCOMSTART1                : in std_logic;
        TXCOMTYPE0                 : in std_logic;
        TXCOMTYPE1                 : in std_logic;
        TXDATA0                    : in std_logic_vector(15 downto 0);
        TXDATA1                    : in std_logic_vector(15 downto 0);
        TXDATAWIDTH0               : in std_logic;
        TXDATAWIDTH1               : in std_logic;
        TXDETECTRX0                : in std_logic;
        TXDETECTRX1                : in std_logic;
        TXDIFFCTRL0                : in std_logic_vector(2 downto 0);
        TXDIFFCTRL1                : in std_logic_vector(2 downto 0);
        TXELECIDLE0                : in std_logic;
        TXELECIDLE1                : in std_logic;
        TXENC8B10BUSE0             : in std_logic;
        TXENC8B10BUSE1             : in std_logic;
        TXENPMAPHASEALIGN          : in std_logic;
        TXENPRBSTST0               : in std_logic_vector(1 downto 0);
        TXENPRBSTST1               : in std_logic_vector(1 downto 0);
        TXINHIBIT0                 : in std_logic;
        TXINHIBIT1                 : in std_logic;
        TXPMASETPHASE              : in std_logic;
        TXPOLARITY0                : in std_logic;
        TXPOLARITY1                : in std_logic;
        TXPOWERDOWN0               : in std_logic_vector(1 downto 0);
        TXPOWERDOWN1               : in std_logic_vector(1 downto 0);
        TXPREEMPHASIS0             : in std_logic_vector(2 downto 0);
        TXPREEMPHASIS1             : in std_logic_vector(2 downto 0);
        TXRESET0                   : in std_logic;
        TXRESET1                   : in std_logic;
        TXUSRCLK0                  : in std_logic;
        TXUSRCLK1                  : in std_logic;
        TXUSRCLK20                 : in std_logic;
        TXUSRCLK21                 : in std_logic;
        GTPTEST                    : in std_logic_vector(3 downto 0));
end component GTP_DUAL;


--//MAIN
begin

m_gt : GTP_DUAL
generic map (
-- synthesis translate_off
SIM_RECEIVER_DETECT_PASS0  =>   TRUE,
SIM_RECEIVER_DETECT_PASS1  =>   TRUE,
SIM_GTPRESET_SPEEDUP       =>   1,
-- synthesis translate_on
AC_CAP_DIS_0               =>   FALSE,
AC_CAP_DIS_1               =>   FALSE,
ALIGN_COMMA_WORD_0         =>   1,
ALIGN_COMMA_WORD_1         =>   1,
CHAN_BOND_1_MAX_SKEW_0     =>   1,
CHAN_BOND_1_MAX_SKEW_1     =>   1,
CHAN_BOND_2_MAX_SKEW_0     =>   1,
CHAN_BOND_2_MAX_SKEW_1     =>   1,
CHAN_BOND_LEVEL_0          =>   0,
CHAN_BOND_LEVEL_1          =>   0,
CHAN_BOND_MODE_0           =>   "OFF",
CHAN_BOND_MODE_1           =>   "OFF",
CHAN_BOND_SEQ_2_USE_0      =>   FALSE,
CHAN_BOND_SEQ_2_USE_1      =>   FALSE,
CHAN_BOND_SEQ_LEN_0        =>   4,
CHAN_BOND_SEQ_LEN_1        =>   4,
CLK25_DIVIDER              =>   4,
CLKINDC_B                  =>   TRUE,
CLK_CORRECT_USE_0          =>   TRUE,
CLK_CORRECT_USE_1          =>   TRUE,
CLK_COR_ADJ_LEN_0          =>   1,
CLK_COR_ADJ_LEN_1          =>   1,
CLK_COR_DET_LEN_0          =>   1,
CLK_COR_DET_LEN_1          =>   1,
CLK_COR_INSERT_IDLE_FLAG_0 =>   FALSE,
CLK_COR_INSERT_IDLE_FLAG_1 =>   FALSE,
CLK_COR_KEEP_IDLE_0        =>   FALSE,
CLK_COR_KEEP_IDLE_1        =>   FALSE,
CLK_COR_MAX_LAT_0          =>   18,
CLK_COR_MAX_LAT_1          =>   18,
CLK_COR_MIN_LAT_0          =>   16,
CLK_COR_MIN_LAT_1          =>   16,
CLK_COR_PRECEDENCE_0       =>   TRUE,
CLK_COR_PRECEDENCE_1       =>   TRUE,
CLK_COR_REPEAT_WAIT_0      =>   5,
CLK_COR_REPEAT_WAIT_1      =>   5,
CLK_COR_SEQ_2_USE_0        =>   FALSE,
CLK_COR_SEQ_2_USE_1        =>   FALSE,
COMMA_DOUBLE_0             =>   FALSE,
COMMA_DOUBLE_1             =>   FALSE,
DEC_MCOMMA_DETECT_0        =>   TRUE,
DEC_MCOMMA_DETECT_1        =>   TRUE,
DEC_PCOMMA_DETECT_0        =>   TRUE,
DEC_PCOMMA_DETECT_1        =>   TRUE,
DEC_VALID_COMMA_ONLY_0     =>   TRUE,
DEC_VALID_COMMA_ONLY_1     =>   TRUE,
MCOMMA_DETECT_0            =>   TRUE,
MCOMMA_DETECT_1            =>   TRUE,
OOB_CLK_DIVIDER            =>   4,
OVERSAMPLE_MODE            =>   FALSE,
PCI_EXPRESS_MODE_0         =>   TRUE,
PCI_EXPRESS_MODE_1         =>   TRUE,
PCOMMA_DETECT_0            =>   TRUE,
PCOMMA_DETECT_1            =>   TRUE,
PLL_DIVSEL_FB              =>   5,
PLL_DIVSEL_REF             =>   2,
PLL_RXDIVSEL_OUT_0         =>   1,
PLL_RXDIVSEL_OUT_1         =>   1,
PLL_SATA_0                 =>   FALSE,
PLL_SATA_1                 =>   FALSE,
PLL_TXDIVSEL_COMM_OUT      =>   1,
PLL_TXDIVSEL_OUT_0         =>   1,
PLL_TXDIVSEL_OUT_1         =>   1,
RCV_TERM_GND_0             =>   TRUE,
RCV_TERM_GND_1             =>   TRUE,
RCV_TERM_MID_0             =>   TRUE,
RCV_TERM_MID_1             =>   TRUE,
RCV_TERM_VTTRX_0           =>   FALSE,
RCV_TERM_VTTRX_1           =>   FALSE,
RX_BUFFER_USE_0            =>   TRUE,
RX_BUFFER_USE_1            =>   TRUE,
RX_DECODE_SEQ_MATCH_0      =>   TRUE,
RX_DECODE_SEQ_MATCH_1      =>   TRUE,
RX_LOSS_OF_SYNC_FSM_0      =>   FALSE,
RX_LOSS_OF_SYNC_FSM_1      =>   FALSE,
RX_LOS_INVALID_INCR_0      =>   8,
RX_LOS_INVALID_INCR_1      =>   8,
RX_LOS_THRESHOLD_0         =>   128,
RX_LOS_THRESHOLD_1         =>   128,
RX_SLIDE_MODE_0            =>   "PCS",
RX_SLIDE_MODE_1            =>   "PCS",
RX_STATUS_FMT_0            =>   "PCIE",
RX_STATUS_FMT_1            =>   "PCIE",
RX_XCLK_SEL_0              =>   "RXREC",
RX_XCLK_SEL_1              =>   "RXREC",
SATA_MAX_BURST_0           =>   7,
SATA_MAX_BURST_1           =>   7,
SATA_MAX_INIT_0            =>   22,
SATA_MAX_INIT_1            =>   22,
SATA_MAX_WAKE_0            =>   7,
SATA_MAX_WAKE_1            =>   7,
SATA_MIN_BURST_0           =>   4,
SATA_MIN_BURST_1           =>   4,
SATA_MIN_INIT_0            =>   12,
SATA_MIN_INIT_1            =>   12,
SATA_MIN_WAKE_0            =>   4,
SATA_MIN_WAKE_1            =>   4,
TERMINATION_IMP_0          =>   50,
TERMINATION_IMP_1          =>   50,
TERMINATION_OVRD           =>   FALSE,
TX_BUFFER_USE_0            =>   TRUE,
TX_BUFFER_USE_1            =>   TRUE,
TX_DIFF_BOOST_0            =>   TRUE,
TX_DIFF_BOOST_1            =>   TRUE,
TX_SYNC_FILTERB            =>   1,
TX_XCLK_SEL_0              =>   "TXOUT",
TX_XCLK_SEL_1              =>   "TXOUT",
CHAN_BOND_SEQ_1_1_0        =>   "0001001010",
CHAN_BOND_SEQ_1_1_1        =>   "0001001010",
CHAN_BOND_SEQ_1_2_0        =>   "0001001010",
CHAN_BOND_SEQ_1_2_1        =>   "0001001010",
CHAN_BOND_SEQ_1_3_0        =>   "0001001010",
CHAN_BOND_SEQ_1_3_1        =>   "0001001010",
CHAN_BOND_SEQ_1_4_0        =>   "0110111100",
CHAN_BOND_SEQ_1_4_1        =>   "0110111100",
CHAN_BOND_SEQ_1_ENABLE_0   =>   "1111",
CHAN_BOND_SEQ_1_ENABLE_1   =>   "1111",
CHAN_BOND_SEQ_2_1_0        =>   "0110111100",
CHAN_BOND_SEQ_2_1_1        =>   "0110111100",
CHAN_BOND_SEQ_2_2_0        =>   "0100111100",
CHAN_BOND_SEQ_2_2_1        =>   "0100111100",
CHAN_BOND_SEQ_2_3_0        =>   "0100111100",
CHAN_BOND_SEQ_2_3_1        =>   "0100111100",
CHAN_BOND_SEQ_2_4_0        =>   "0100111100",
CHAN_BOND_SEQ_2_4_1        =>   "0100111100",
CHAN_BOND_SEQ_2_ENABLE_0   =>   "1111",
CHAN_BOND_SEQ_2_ENABLE_1   =>   "1111",
CLK_COR_SEQ_1_1_0          =>   "0100011100",
CLK_COR_SEQ_1_1_1          =>   "0100011100",
CLK_COR_SEQ_1_2_0          =>   "0000000000",
CLK_COR_SEQ_1_2_1          =>   "0000000000",
CLK_COR_SEQ_1_3_0          =>   "0000000000",
CLK_COR_SEQ_1_3_1          =>   "0000000000",
CLK_COR_SEQ_1_4_0          =>   "0000000000",
CLK_COR_SEQ_1_4_1          =>   "0000000000",
CLK_COR_SEQ_1_ENABLE_0     =>   "1111",
CLK_COR_SEQ_1_ENABLE_1     =>   "1111",
CLK_COR_SEQ_2_1_0          =>   "0000000000",
CLK_COR_SEQ_2_1_1          =>   "0000000000",
CLK_COR_SEQ_2_2_0          =>   "0000000000",
CLK_COR_SEQ_2_2_1          =>   "0000000000",
CLK_COR_SEQ_2_3_0          =>   "0000000000",
CLK_COR_SEQ_2_3_1          =>   "0000000000",
CLK_COR_SEQ_2_4_0          =>   "0000000000",
CLK_COR_SEQ_2_4_1          =>   "0000000000",
CLK_COR_SEQ_2_ENABLE_0     =>   "1111",
CLK_COR_SEQ_2_ENABLE_1     =>   "1111",
COMMA_10B_ENABLE_0         =>   "1111111111",
COMMA_10B_ENABLE_1         =>   "1111111111",
COM_BURST_VAL_0            =>   "1111",
COM_BURST_VAL_1            =>   "1111",
MCOMMA_10B_VALUE_0         =>   "1010000011",
MCOMMA_10B_VALUE_1         =>   "1010000011",
OOBDETECT_THRESHOLD_0      =>   "010",
OOBDETECT_THRESHOLD_1      =>   "010",
PCOMMA_10B_VALUE_0         =>   "0101111100",
PCOMMA_10B_VALUE_1         =>   "0101111100",
PMA_CDR_SCAN_0             =>   "110110000001000000001000000",--x"6C08040"
PMA_CDR_SCAN_1             =>   "110110000001000000001000000",--x"6C08040"
PMA_RX_CFG_0               =>   "0110111001110000010001001" ,--x"0DCE089"
PMA_RX_CFG_1               =>   "0110111001110000010001001" ,--x"0DCE089"
PRBS_ERR_THRESHOLD_0       =>   x"00000001",
PRBS_ERR_THRESHOLD_1       =>   x"00000001",
SATA_BURST_VAL_0           =>   "100",
SATA_BURST_VAL_1           =>   "100",
SATA_IDLE_VAL_0            =>   "011",
SATA_IDLE_VAL_1            =>   "011",
TERMINATION_CTRL           =>   "10100",
TRANS_TIME_FROM_P2_0       =>   x"003C",
TRANS_TIME_FROM_P2_1       =>   x"003C",
TRANS_TIME_NON_P2_0        =>   x"0019",
TRANS_TIME_NON_P2_1        =>   x"0019",
TRANS_TIME_TO_P2_0         =>   x"0064",
TRANS_TIME_TO_P2_1         =>   x"0064",
TXRX_INVERT_0              =>   "00000",
TXRX_INVERT_1              =>   "00000")
port map (
-- GTP_DUAL outputs
PHYSTATUS0                 =>      open,
PHYSTATUS1                 =>      open,
PLLLKDET                   =>      open,
RESETDONE0                 =>      open,
RESETDONE1                 =>      open,
RXBUFSTATUS0               =>      open,
RXBUFSTATUS1               =>      open,
RXBYTEISALIGNED0           =>      open,
RXBYTEISALIGNED1           =>      open,
RXBYTEREALIGN0             =>      open,
RXBYTEREALIGN1             =>      open,
RXCHANBONDSEQ0             =>      open,
RXCHANBONDSEQ1             =>      open,
RXCHANISALIGNED0           =>      open,
RXCHANISALIGNED1           =>      open,
RXCHANREALIGN0             =>      open,
RXCHANREALIGN1             =>      open,
RXCHARISCOMMA0             =>      open,
RXCHARISCOMMA1             =>      open,
RXCHARISK0                 =>      open,
RXCHARISK1                 =>      open,
RXCHBONDO0                 =>      open,
RXCHBONDO1                 =>      open,
RXCLKCORCNT0               =>      open,
RXCLKCORCNT1               =>      open,
RXCOMMADET0                =>      open,
RXCOMMADET1                =>      open,
RXDATA0                    =>      open,
RXDATA1                    =>      open,
RXDISPERR0                 =>      open,
RXDISPERR1                 =>      open,
RXELECIDLE0                =>      open,
RXELECIDLE1                =>      open,
RXLOSSOFSYNC0              =>      open,
RXLOSSOFSYNC1              =>      open,
RXNOTINTABLE0              =>      open,
RXNOTINTABLE1              =>      open,
RXOVERSAMPLEERR0           =>      open,
RXOVERSAMPLEERR1           =>      open,
RXPRBSERR0                 =>      open,
RXPRBSERR1                 =>      open,
RXRECCLK0                  =>      open,
RXRECCLK1                  =>      open,
RXRUNDISP0                 =>      open,
RXRUNDISP1                 =>      open,
RXSTATUS0                  =>      open,
RXSTATUS1                  =>      open,
RXVALID0                   =>      open,
RXVALID1                   =>      open,
TXBUFSTATUS0               =>      open,
TXBUFSTATUS1               =>      open,
TXKERR0                    =>      open,
TXKERR1                    =>      open,
TXN0                       =>      p_out_txn(0),
TXN1                       =>      p_out_txn(1),
TXOUTCLK0                  =>      open,
TXOUTCLK1                  =>      open,
TXP0                       =>      p_out_txp(0),
TXP1                       =>      p_out_txp(1),
TXRUNDISP0                 =>      open,
TXRUNDISP1                 =>      open,

-- GTP_DUAL inputs
INTDATAWIDTH               =>      '1',
LOOPBACK0                  =>      "000",
LOOPBACK1                  =>      "000",
PLLLKDETEN                 =>      '1',
PLLPOWERDOWN               =>      '1',
PRBSCNTRESET0              =>      '0',
PRBSCNTRESET1              =>      '0',
REFCLKPWRDNB               =>      '1',
RXBUFRESET0                =>      '0',
RXBUFRESET1                =>      '0',
RXCDRRESET0                =>      '0',
RXCDRRESET1                =>      '0',
RXCHBONDI0                 =>      "000",
RXCHBONDI1                 =>      "000",
RXCOMMADETUSE0             =>      '1',
RXCOMMADETUSE1             =>      '1',
RXDATAWIDTH0               =>      '0',
RXDATAWIDTH1               =>      '0',
RXDEC8B10BUSE0             =>      '1',
RXDEC8B10BUSE1             =>      '1',
RXENCHANSYNC0              =>      '0',
RXENCHANSYNC1              =>      '0',
RXENEQB0                   =>      '1',
RXENEQB1                   =>      '1',
RXENMCOMMAALIGN0           =>      '1',
RXENMCOMMAALIGN1           =>      '1',
RXENPCOMMAALIGN0           =>      '1',
RXENPCOMMAALIGN1           =>      '1',
RXENPRBSTST0               =>      "00",
RXENPRBSTST1               =>      "00",
RXENSAMPLEALIGN0           =>      '0',
RXENSAMPLEALIGN1           =>      '0',
RXEQMIX0                   =>      "01",
RXEQMIX1                   =>      "01",
RXEQPOLE0                  =>      "0000",
RXEQPOLE1                  =>      "0000",
RXN0                       =>      p_in_rxn(0),
RXN1                       =>      p_in_rxn(1),
RXP0                       =>      p_in_rxp(0),
RXP1                       =>      p_in_rxp(1),
RXPMASETPHASE0             =>      '0',
RXPMASETPHASE1             =>      '0',
RXPOLARITY0                =>      '0',
RXPOLARITY1                =>      '0',
RXPOWERDOWN0               =>      "11",   -- lowest power state
RXPOWERDOWN1               =>      "11",   -- lowest power state
RXRESET0                   =>      '0',
RXRESET1                   =>      '0',
RXSLIDE0                   =>      '0',
RXSLIDE1                   =>      '0',
RXUSRCLK0                  =>      '0',
RXUSRCLK1                  =>      '0',
RXUSRCLK20                 =>      '0',
RXUSRCLK21                 =>      '0',
RXELECIDLERESET0           =>      '0',
RXELECIDLERESET1           =>      '0',
RXENELECIDLERESETB         =>      '0',
TXBUFDIFFCTRL0             =>      "000",
TXBUFDIFFCTRL1             =>      "000",
TXBYPASS8B10B0             =>      "00",
TXBYPASS8B10B1             =>      "00",
TXCHARDISPMODE0            =>      "00",
TXCHARDISPMODE1            =>      "00",
TXCHARDISPVAL0             =>      "00",
TXCHARDISPVAL1             =>      "00",
TXCHARISK0                 =>      "00",
TXCHARISK1                 =>      "00",
TXCOMSTART0                =>      '0',
TXCOMSTART1                =>      '0',
TXCOMTYPE0                 =>      '0',
TXCOMTYPE1                 =>      '0',
TXDATA0                    =>      x"0000",
TXDATA1                    =>      x"0000",
TXDATAWIDTH0               =>      '0',
TXDATAWIDTH1               =>      '0',
TXDETECTRX0                =>      '0',
TXDETECTRX1                =>      '0',
TXDIFFCTRL0                =>      "000",
TXDIFFCTRL1                =>      "000",
TXELECIDLE0                =>      '0',
TXELECIDLE1                =>      '0',
TXENC8B10BUSE0             =>      '1',
TXENC8B10BUSE1             =>      '1',
TXENPMAPHASEALIGN          =>      '0',
TXENPRBSTST0               =>      "00",
TXENPRBSTST1               =>      "00",
TXINHIBIT0                 =>      '0',
TXINHIBIT1                 =>      '0',
TXPMASETPHASE              =>      '0',
TXPOLARITY0                =>      '0',
TXPOLARITY1                =>      '0',
TXPOWERDOWN0               =>      "11",   -- lowest power state
TXPOWERDOWN1               =>      "11",   -- lowest power state
TXPREEMPHASIS0             =>      "111",
TXPREEMPHASIS1             =>      "111",
TXRESET0                   =>      '0',
TXRESET1                   =>      '0',
TXUSRCLK0                  =>      '0',
TXUSRCLK1                  =>      '0',
TXUSRCLK20                 =>      '0',
TXUSRCLK21                 =>      '0',
GTPTEST                    =>      "0000",

--//DRP
DADDR                      =>      i_gtp_drpaddr,
DCLK                       =>      i_gtp_drpclk,
DEN                        =>      i_gtp_drpen,
DI                         =>      i_gtp_drpdi,
DWE                        =>      i_gtp_drpwe,
DO                         =>      i_gtp_drpdo,
DRDY                       =>      i_gtp_drprdy,

GTPRESET                   =>      i_gtp_rst,--'0',
REFCLKOUT                  =>      p_out_refclkout,
CLKIN                      =>      p_in_clkin
);

--//������������ ���������� ������� �������� DUAL_GTP_X0Y6
m_gtp_drp_ctrl : gtp_drp_ctrl
generic map
(
G_USE_USRCTLR      =>  0,

G_CLKIN_CHANGE     => G_CLKIN_CHANGE,
G_CLKSOUTH_CHANGE  => G_CLKSOUTH_CHANGE,
G_CLKNORTH_CHANGE  => G_CLKNORTH_CHANGE,

G_CLKIN_MUX_VAL    => G_CLKIN_MUX_VAL,
G_CLKSOUTH_MUX_VAL => G_CLKSOUTH_MUX_VAL,
G_CLKNORTH_MUX_VAL => G_CLKNORTH_MUX_VAL
)
port map
(
p_in_usr_ctrl     => "00000000000000000000000000000000",

--------------------------------------------------
--RocketIO
--------------------------------------------------
p_out_gtp_drpclk  => i_gtp_drpclk,
p_out_gtp_drpaddr => i_gtp_drpaddr,
p_out_gtp_drpen   => i_gtp_drpen,
p_out_gtp_drpwe   => i_gtp_drpwe,
p_out_gtp_drpdi   => i_gtp_drpdi,
p_in_gtp_drpdo    => i_gtp_drpdo,
p_in_gtp_drprdy   => i_gtp_drprdy,

p_out_gtp_rst     => i_gtp_rst,

--------------------------------------------------
--��������������� �������
--------------------------------------------------
p_out_tst         => open,

--------------------------------------------------
--SYSTEM
--------------------------------------------------
p_in_clk          => p_in_drp_clk,
p_in_rst          => p_in_drp_rst
);


--//END MAIN
end architecture;
