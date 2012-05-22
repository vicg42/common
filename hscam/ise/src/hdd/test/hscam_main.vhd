-------------------------------------------------------------------------
-- Company     : Linkos
-- Engineer    : Golovachenko Victor + Kukla Anatol
--
-- Create Date : 26.10.2011 16:40:26
-- Module Name : hscam_main
--
-- ����������/�������� :
--
--
-- Revision:
-- Revision 0.01 - File Created
--
-------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_misc.all;

library work;
use work.prj_cfg.all;
use work.sata_glob_pkg.all;
use work.hdd_main_unit_pkg.all;
use work.mem_ctrl_pkg.all;

library unisim;
use unisim.vcomponents.all;

entity hscam_main is
generic(
G_VOUT_DWIDTH : integer:=16;
G_VSYN_ACTIVE : std_logic:='0';
G_SIM : string:="OFF"
);
port(
--------------------------------------------------
--SATA
--------------------------------------------------
pin_out_sata_txn   : out   std_logic_vector((C_SH_GTCH_COUNT_MAX*C_SH_COUNT_MAX(C_PCFG_HDD_COUNT-1))-1 downto 0);
pin_out_sata_txp   : out   std_logic_vector((C_SH_GTCH_COUNT_MAX*C_SH_COUNT_MAX(C_PCFG_HDD_COUNT-1))-1 downto 0);
pin_in_sata_rxn    : in    std_logic_vector((C_SH_GTCH_COUNT_MAX*C_SH_COUNT_MAX(C_PCFG_HDD_COUNT-1))-1 downto 0);
pin_in_sata_rxp    : in    std_logic_vector((C_SH_GTCH_COUNT_MAX*C_SH_COUNT_MAX(C_PCFG_HDD_COUNT-1))-1 downto 0);
pin_in_sata_clk_n  : in    std_logic_vector(C_SH_COUNT_MAX(C_PCFG_HDD_COUNT-1)-1 downto 0);
pin_in_sata_clk_p  : in    std_logic_vector(C_SH_COUNT_MAX(C_PCFG_HDD_COUNT-1)-1 downto 0);

--------------------------------------------------
--RAM
--------------------------------------------------
pin_out_mcb5_a        : out   std_logic_vector(12 downto 0);
pin_out_mcb5_ba       : out   std_logic_vector(2 downto 0) ;
pin_out_mcb5_ras_n    : out   std_logic;
pin_out_mcb5_cas_n    : out   std_logic;
pin_out_mcb5_we_n     : out   std_logic;
pin_out_mcb5_odt      : out   std_logic;
pin_out_mcb5_cke      : out   std_logic;
pin_out_mcb5_dm       : out   std_logic;
pin_out_mcb5_udm      : out   std_logic;
pin_out_mcb5_ck       : out   std_logic;
pin_out_mcb5_ck_n     : out   std_logic;
pin_inout_mcb5_dq     : inout std_logic_vector(15 downto 0);
pin_inout_mcb5_udqs   : inout std_logic;
pin_inout_mcb5_udqs_n : inout std_logic;
pin_inout_mcb5_dqs    : inout std_logic;
pin_inout_mcb5_dqs_n  : inout std_logic;
pin_inout_mcb5_rzq    : inout std_logic;
pin_inout_mcb5_zio    : inout std_logic;

pin_out_mcb1_a        : out   std_logic_vector(12 downto 0);
pin_out_mcb1_ba       : out   std_logic_vector(2 downto 0) ;
pin_out_mcb1_ras_n    : out   std_logic;
pin_out_mcb1_cas_n    : out   std_logic;
pin_out_mcb1_we_n     : out   std_logic;
pin_out_mcb1_odt      : out   std_logic;
pin_out_mcb1_cke      : out   std_logic;
pin_out_mcb1_dm       : out   std_logic;
pin_out_mcb1_udm      : out   std_logic;
pin_out_mcb1_ck       : out   std_logic;
pin_out_mcb1_ck_n     : out   std_logic;
pin_inout_mcb1_dq     : inout std_logic_vector(15 downto 0);
pin_inout_mcb1_udqs   : inout std_logic;
pin_inout_mcb1_udqs_n : inout std_logic;
pin_inout_mcb1_dqs    : inout std_logic;
pin_inout_mcb1_dqs_n  : inout std_logic;
pin_inout_mcb1_rzq    : inout std_logic;
pin_inout_mcb1_zio    : inout std_logic;

--------------------------------------------------
-- Reference clock
--------------------------------------------------
pin_in_refclk_n       : in    std_logic;
pin_in_refclk_p       : in    std_logic;

--------------------------------------------------
--��������������� ����
--------------------------------------------------
pin_inout_ftdi_d   : inout std_logic_vector(7 downto 0);
pin_out_ftdi_rd_n  : out   std_logic;
pin_out_ftdi_wr_n  : out   std_logic;
pin_in_ftdi_txe_n  : in    std_logic;
pin_in_ftdi_rxf_n  : in    std_logic;
pin_in_ftdi_pwren_n: in    std_logic;

pin_out_TP2        : out   std_logic_vector(1 downto 0);
pin_in_SW          : in    std_logic_vector(3 downto 0);
pin_out_TP         : out   std_logic_vector(7 downto 0);
pin_out_led        : out   std_logic_vector(7 downto 0)
);
end entity;

architecture struct of hscam_main is

component hdd_main
generic(
G_VOUT_DWIDTH : integer:=16;
G_VSYN_ACTIVE : std_logic:='0';
G_SIM         : string:="OFF"
);
port(
--------------------------------------------------
--VideoIN
--------------------------------------------------
p_in_vd             : in   std_logic_vector((10*8)-1 downto 0);
p_in_vin_vs         : in   std_logic;--//����� �������� �������������
p_in_vin_hs         : in   std_logic;--//����� �������� �������������
p_in_vin_clk        : in   std_logic;--//���������� �������
p_in_ext_syn        : in   std_logic;--//������� ������������� ������

--------------------------------------------------
--VideoOUT
--------------------------------------------------
p_out_vd            : out  std_logic_vector(G_VOUT_DWIDTH-1 downto 0);
p_in_vout_vs        : in   std_logic;--//����� �������� �������������
p_in_vout_hs        : in   std_logic;--//����� �������� �������������
p_in_vout_clk       : in   std_logic;--//���������� �������

--------------------------------------------------
--RAM
--------------------------------------------------
p_out_mcb5_a        : out   std_logic_vector(12 downto 0);
p_out_mcb5_ba       : out   std_logic_vector(2 downto 0) ;
p_out_mcb5_ras_n    : out   std_logic;
p_out_mcb5_cas_n    : out   std_logic;
p_out_mcb5_we_n     : out   std_logic;
p_out_mcb5_odt      : out   std_logic;
p_out_mcb5_cke      : out   std_logic;
p_out_mcb5_dm       : out   std_logic;
p_out_mcb5_udm      : out   std_logic;
p_out_mcb5_ck       : out   std_logic;
p_out_mcb5_ck_n     : out   std_logic;
p_inout_mcb5_dq     : inout std_logic_vector(15 downto 0);
p_inout_mcb5_udqs   : inout std_logic;
p_inout_mcb5_udqs_n : inout std_logic;
p_inout_mcb5_dqs    : inout std_logic;
p_inout_mcb5_dqs_n  : inout std_logic;
p_inout_mcb5_rzq    : inout std_logic;
p_inout_mcb5_zio    : inout std_logic;

p_out_mcb1_a        : out   std_logic_vector(12 downto 0);
p_out_mcb1_ba       : out   std_logic_vector(2 downto 0) ;
p_out_mcb1_ras_n    : out   std_logic;
p_out_mcb1_cas_n    : out   std_logic;
p_out_mcb1_we_n     : out   std_logic;
p_out_mcb1_odt      : out   std_logic;
p_out_mcb1_cke      : out   std_logic;
p_out_mcb1_dm       : out   std_logic;
p_out_mcb1_udm      : out   std_logic;
p_out_mcb1_ck       : out   std_logic;
p_out_mcb1_ck_n     : out   std_logic;
p_inout_mcb1_dq     : inout std_logic_vector(15 downto 0);
p_inout_mcb1_udqs   : inout std_logic;
p_inout_mcb1_udqs_n : inout std_logic;
p_inout_mcb1_dqs    : inout std_logic;
p_inout_mcb1_dqs_n  : inout std_logic;
p_inout_mcb1_rzq    : inout std_logic;
p_inout_mcb1_zio    : inout std_logic;

--------------------------------------------------
--SATA
--------------------------------------------------
p_out_sata_txn      : out   std_logic_vector((C_SH_GTCH_COUNT_MAX*C_SH_COUNT_MAX(C_PCFG_HDD_COUNT-1))-1 downto 0);--std_logic_vector(3 downto 0);
p_out_sata_txp      : out   std_logic_vector((C_SH_GTCH_COUNT_MAX*C_SH_COUNT_MAX(C_PCFG_HDD_COUNT-1))-1 downto 0);--std_logic_vector(3 downto 0);
p_in_sata_rxn       : in    std_logic_vector((C_SH_GTCH_COUNT_MAX*C_SH_COUNT_MAX(C_PCFG_HDD_COUNT-1))-1 downto 0);--std_logic_vector(3 downto 0);
p_in_sata_rxp       : in    std_logic_vector((C_SH_GTCH_COUNT_MAX*C_SH_COUNT_MAX(C_PCFG_HDD_COUNT-1))-1 downto 0);--std_logic_vector(3 downto 0);
p_in_sata_clk_n     : in    std_logic_vector(C_SH_COUNT_MAX(C_PCFG_HDD_COUNT-1)-1 downto 0);                      --std_logic_vector(1 downto 0);
p_in_sata_clk_p     : in    std_logic_vector(C_SH_COUNT_MAX(C_PCFG_HDD_COUNT-1)-1 downto 0);                      --std_logic_vector(1 downto 0);

-------------------------------------------------
--���� ���������� ������� + �������
--------------------------------------------------
--��������� ���������� �������
p_in_usr_clk        : in    std_logic;                    --������� ������������ p_in_usr_txd/rxd/tx_wr/rx_rd
p_in_usr_tx_wr      : in    std_logic;                    --����� ������ txd
p_in_usr_rx_rd      : in    std_logic;                    --����� ������ rxd
p_in_usr_txd        : in    std_logic_vector(15 downto 0);
p_out_usr_rxd       : out   std_logic_vector(15 downto 0);
p_out_usr_status    : out   std_logic_vector(7  downto 0);

--������� ������
p_out_hdd_rdy       : out   std_logic;--������ ����� � ������
p_out_hdd_err       : out   std_logic;--������ � ������

--------------------------------------------------
--Sim
--------------------------------------------------
p_out_sim_cfg_clk           : out  std_logic;
p_in_sim_cfg_adr            : in   std_logic_vector(7 downto 0);
p_in_sim_cfg_adr_ld         : in   std_logic;
p_in_sim_cfg_adr_fifo       : in   std_logic;
p_in_sim_cfg_txdata         : in   std_logic_vector(15 downto 0);
p_in_sim_cfg_wd             : in   std_logic;
p_out_sim_cfg_txrdy         : out  std_logic;
p_out_sim_cfg_rxdata        : out  std_logic_vector(15 downto 0);
p_in_sim_cfg_rd             : in   std_logic;
p_out_sim_cfg_rxrdy         : out  std_logic;
p_in_sim_cfg_done           : in   std_logic;
p_in_sim_cfg_rst            : in   std_logic;

p_out_sim_hdd_busy          : out   std_logic;
p_out_sim_gt_txdata         : out   TBus32_SHCountMax;
p_out_sim_gt_txcharisk      : out   TBus04_SHCountMax;
p_out_sim_gt_txcomstart     : out   std_logic_vector(C_HDD_COUNT_MAX-1 downto 0);
p_in_sim_gt_rxdata          : in    TBus32_SHCountMax;
p_in_sim_gt_rxcharisk       : in    TBus04_SHCountMax;
p_in_sim_gt_rxstatus        : in    TBus03_SHCountMax;
p_in_sim_gt_rxelecidle      : in    std_logic_vector(C_HDD_COUNT_MAX-1 downto 0);
p_in_sim_gt_rxdisperr       : in    TBus04_SHCountMax;
p_in_sim_gt_rxnotintable    : in    TBus04_SHCountMax;
p_in_sim_gt_rxbyteisaligned : in    std_logic_vector(C_HDD_COUNT_MAX-1 downto 0);
p_out_gt_sim_rst            : out   std_logic_vector(C_HDD_COUNT_MAX-1 downto 0);
p_out_gt_sim_clk            : out   std_logic_vector(C_HDD_COUNT_MAX-1 downto 0);

p_out_sim_mem               : out   TMemINBank;
p_in_sim_mem                : in    TMemOUTBank;

--------------------------------------------------
--��������������� ����
--------------------------------------------------
--��������� � USB(FTDI)
p_inout_ftdi_d      : inout std_logic_vector(7 downto 0);
p_out_ftdi_rd_n     : out   std_logic;
p_out_ftdi_wr_n     : out   std_logic;
p_in_ftdi_txe_n     : in    std_logic;
p_in_ftdi_rxf_n     : in    std_logic;
p_in_ftdi_pwren_n   : in    std_logic;

p_out_TP            : out   std_logic_vector(7 downto 0); --����� �� ����������� ����� �����
p_out_led           : out   std_logic_vector(7 downto 0)  --����� �� ��������� �����
);
end component;

component vtiming_gen
generic(
G_VSYN_ACTIVE: std_logic:='1';
G_VS_WIDTH   : integer:=32;
G_HS_WIDTH   : integer:=32;
G_PIX_COUNT  : integer:=32;
G_ROW_COUNT  : integer:=32
);
port(
p_out_vs : out  std_logic;
p_out_hs : out  std_logic;

p_in_clk : in   std_logic;
p_in_rst : in   std_logic
);
end component;

--signal i_sys_rst_cnt                  : std_logic_vector(5 downto 0):=(others=>'0');
signal i_sys_rst                      : std_logic:='0';

signal i_usrpll_clkfb                 : std_logic;
signal i_usrpll_clkout                : std_logic_vector(1 downto 0);
signal g_usrpll_clkout                : std_logic_vector(1 downto 0);
signal i_usrpll_lock                  : std_logic;

signal i_vtg_rst                      : std_logic;
type TDtest   is array(0 to 9) of std_logic_vector(7 downto 0);
signal i_tdata                        : TDtest;

signal i_vin_d                        : std_logic_vector(79 downto 0):=(others=>'0');
signal i_vin_vs                       : std_logic;
signal i_vin_hs                       : std_logic;
signal i_vin_clk                      : std_logic;

signal i_vout_d                       : std_logic_vector(G_VOUT_DWIDTH-1 downto 0);
signal i_vout_vs                      : std_logic;
signal i_vout_hs                      : std_logic;
signal i_vout_clk                     : std_logic;

signal i_usr_refclk150                : std_logic;
signal g_usr_refclk150                : std_logic;
signal t_usr_refclk150                : std_logic;

signal i_out_TP                       : std_logic_vector(7 downto 0);
signal tst_out                        : std_logic_vector(31 downto 0);
signal tst_in                         : std_logic_vector(31 downto 0);
signal i_test02_led                   : std_logic;

signal i_usr_status                   : std_logic_vector(7  downto 0);
signal i_usr_rxd,i_usr_txd            : std_logic_vector(15 downto 0);

signal i_hdd_rdy,i_hdd_err            : std_logic;


--signal i_hdd_sim_gt_txdata            : TBus32_SHCountMax;
--signal i_hdd_sim_gt_txcharisk         : TBus04_SHCountMax;
--signal i_hdd_sim_gt_txcomstart        : std_logic_vector(C_HDD_COUNT_MAX-1 downto 0);
signal i_hdd_sim_gt_rxdata            : TBus32_SHCountMax;
signal i_hdd_sim_gt_rxcharisk         : TBus04_SHCountMax;
signal i_hdd_sim_gt_rxstatus          : TBus03_SHCountMax;
signal i_hdd_sim_gt_rxelecidle        : std_logic_vector(C_HDD_COUNT_MAX-1 downto 0);
signal i_hdd_sim_gt_rxdisperr         : TBus04_SHCountMax;
signal i_hdd_sim_gt_rxnotintable      : TBus04_SHCountMax;
signal i_hdd_sim_gt_rxbyteisaligned   : std_logic_vector(C_HDD_COUNT_MAX-1 downto 0);
--signal i_hdd_sim_gt_sim_rst           : std_logic_vector(C_HDD_COUNT_MAX-1 downto 0);
--signal i_hdd_sim_gt_sim_clk           : std_logic_vector(C_HDD_COUNT_MAX-1 downto 0);

signal i_sim_mem_out                  : TMemOUTBank;


--MAIN
begin

m_ibufds_refclk : IBUFDS port map (I => pin_in_refclk_p, IB => pin_in_refclk_n, O => i_usr_refclk150);
m_bufio2_refclk : BUFIO2 port map (I => i_usr_refclk150, DIVCLK => t_usr_refclk150, IOCLK => open, SERDESSTROBE => open );
m_bufg_refclk   : BUFG   port map (I => t_usr_refclk150, O => g_usr_refclk150);

m_usrpll : PLL_ADV
generic map(
BANDWIDTH          => "OPTIMIZED",
CLKIN1_PERIOD      => 8.0, --125MHz
CLKIN2_PERIOD      => 8.0,
CLKOUT0_DIVIDE     => 8, --clk0 = ((125MHz * 21)/5) /8  = 65.625MHz - Clk_Vin
CLKOUT1_DIVIDE     => 9, --clk1 = ((125MHz * 21)/5) /13 = 40.385MHz - Clk_Vout
CLKOUT2_DIVIDE     => 5,
CLKOUT3_DIVIDE     => 9,
CLKOUT4_DIVIDE     => 8,
CLKOUT5_DIVIDE     => 8,
CLKOUT0_PHASE      => 0.000,
CLKOUT1_PHASE      => 0.000,
CLKOUT2_PHASE      => 0.000,
CLKOUT3_PHASE      => 0.000,
CLKOUT4_PHASE      => 0.000,
CLKOUT5_PHASE      => 0.000,
CLKOUT0_DUTY_CYCLE => 0.500,
CLKOUT1_DUTY_CYCLE => 0.500,
CLKOUT2_DUTY_CYCLE => 0.500,
CLKOUT3_DUTY_CYCLE => 0.500,
CLKOUT4_DUTY_CYCLE => 0.500,
CLKOUT5_DUTY_CYCLE => 0.500,
SIM_DEVICE         => "SPARTAN6",
COMPENSATION       => "INTERNAL",--"DCM2PLL",--
DIVCLK_DIVIDE      => 5,
CLKFBOUT_MULT      => 21,
CLKFBOUT_PHASE     => 0.0,
REF_JITTER         => 0.005000
)
port map(
CLKFBIN          => i_usrpll_clkfb,
CLKINSEL         => '1',
CLKIN1           => t_usr_refclk150,--g_usr_refclk150,
CLKIN2           => '0',
DADDR            => (others => '0'),
DCLK             => '0',
DEN              => '0',
DI               => (others => '0'),
DWE              => '0',
REL              => '0',
RST              => i_sys_rst,
CLKFBDCM         => open,
CLKFBOUT         => i_usrpll_clkfb,
CLKOUTDCM0       => open,
CLKOUTDCM1       => open,
CLKOUTDCM2       => open,
CLKOUTDCM3       => open,
CLKOUTDCM4       => open,
CLKOUTDCM5       => open,
CLKOUT0          => i_usrpll_clkout(0),
CLKOUT1          => i_usrpll_clkout(1),
CLKOUT2          => open,
CLKOUT3          => open,
CLKOUT4          => open,
CLKOUT5          => open,
DO               => open,
DRDY             => open,
LOCKED           => i_usrpll_lock
);

gen_clk : for i in 0 to i_usrpll_clkout'length-1 generate
m_bufg : BUFG port map(I => i_usrpll_clkout(i), O => g_usrpll_clkout(i) );
end generate gen_clk;

i_sys_rst <= '0';

--m_blink2 : fpga_test_01
--generic map(
--G_BLINK_T05   =>10#250#, -- 1/2 ������� ������� ����������.(����� � ms)
--G_CLK_T05us   =>10#75#   -- 05us - 150MHz
--)
--port map(
--p_out_test_led => i_test02_led,
--p_out_test_done=> open,
--
--p_out_1us      => open,
--p_out_1ms      => open,
---------------------------------
----System
---------------------------------
--p_in_clk       => g_usr_refclk150, --p_in_grefclk,
--p_in_rst       => i_sys_rst
--);

i_vtg_rst <=i_sys_rst;
i_vin_clk <=g_usrpll_clkout(0);
i_vout_clk<=g_usrpll_clkout(1);

--��������� �������� ������ (������������ �������!!!)
gen_vd : for i in 1 to 10 generate
process(i_vtg_rst,i_vin_clk)
begin
  if i_vtg_rst='1' then
    i_tdata(i-1)<=CONV_STD_LOGIC_VECTOR(i, i_tdata(i-1)'length);
  elsif i_vin_clk'event and i_vin_clk='1' then
    if i_vin_vs=G_VSYN_ACTIVE or i_vin_hs=G_VSYN_ACTIVE then
      i_tdata(i-1)<=CONV_STD_LOGIC_VECTOR(i-1, i_tdata(i-1)'length);
    else
      i_tdata(i-1)<=i_tdata(i-1) + CONV_STD_LOGIC_VECTOR(10, i_tdata(i-1)'length);
    end if;
  end if;
end process;

i_vin_d((8*i)-1 downto (8*i)-8)<=i_tdata(i-1);
end generate gen_vd;

m_vtgen_high : vtiming_gen
generic map(
G_VSYN_ACTIVE=> G_VSYN_ACTIVE,
G_VS_WIDTH   => 32,
G_HS_WIDTH   => 16,
G_PIX_COUNT  => (C_PCFG_FRPIX/10),
G_ROW_COUNT  => C_PCFG_FRROW
)
port map(
p_out_vs => i_vin_vs,
p_out_hs => i_vin_hs,

p_in_clk => i_vin_clk,
p_in_rst => i_vtg_rst
);

m_vtgen_low : vtiming_gen
generic map(
G_VSYN_ACTIVE=> G_VSYN_ACTIVE,
G_VS_WIDTH   => 32,
G_HS_WIDTH   => 8,
G_PIX_COUNT  => (C_PCFG_FRPIX/(G_VOUT_DWIDTH/8)),
G_ROW_COUNT  => C_PCFG_FRROW
)
port map(
p_out_vs => i_vout_vs,
p_out_hs => i_vout_hs,

p_in_clk => i_vout_clk,
p_in_rst => i_vtg_rst
);


pin_out_TP(1 downto 0)<=i_out_TP(1 downto 0);
pin_out_TP(2)<=i_out_TP(2);--i_test02_led;
pin_out_TP(7 downto 3)<=i_out_TP(7 downto 3);

pin_out_TP2(0)<=OR_reduce(i_vout_d) or OR_reduce(i_usr_rxd) or i_usr_status(0) or i_usr_status(1) or pin_in_SW(0) or i_hdd_rdy or i_hdd_err;
pin_out_TP2(1)<='0';

gen_tx: for i in 0 to 15 generate
i_usr_txd(i)<=pin_in_SW(1);
end generate gen_tx;


--***********************************************************
-- ������ HDD:
--***********************************************************
m_hdd : hdd_main
generic map(
G_VOUT_DWIDTH => G_VOUT_DWIDTH,
G_VSYN_ACTIVE => G_VSYN_ACTIVE,
G_SIM => G_SIM
)
port map(
--------------------------------------------------
--VideoIN
--------------------------------------------------
p_in_vd             => i_vin_d,
p_in_vin_vs         => i_vin_vs,--tst_in(0),--
p_in_vin_hs         => i_vin_hs,--tst_in(1),--
p_in_vin_clk        => i_vin_clk,
p_in_ext_syn        => '1',

--------------------------------------------------
--VideoOUT
--------------------------------------------------
p_out_vd            => i_vout_d,
p_in_vout_vs        => i_vout_vs,
p_in_vout_hs        => i_vout_hs,
p_in_vout_clk       => i_vout_clk,

--------------------------------------------------
--RAM
--------------------------------------------------
p_out_mcb5_a        => pin_out_mcb5_a       ,
p_out_mcb5_ba       => pin_out_mcb5_ba      ,
p_out_mcb5_ras_n    => pin_out_mcb5_ras_n   ,
p_out_mcb5_cas_n    => pin_out_mcb5_cas_n   ,
p_out_mcb5_we_n     => pin_out_mcb5_we_n    ,
p_out_mcb5_odt      => pin_out_mcb5_odt     ,
p_out_mcb5_cke      => pin_out_mcb5_cke     ,
p_out_mcb5_dm       => pin_out_mcb5_dm      ,
p_out_mcb5_udm      => pin_out_mcb5_udm     ,
p_out_mcb5_ck       => pin_out_mcb5_ck      ,
p_out_mcb5_ck_n     => pin_out_mcb5_ck_n    ,
p_inout_mcb5_dq     => pin_inout_mcb5_dq    ,
p_inout_mcb5_udqs   => pin_inout_mcb5_udqs  ,
p_inout_mcb5_udqs_n => pin_inout_mcb5_udqs_n,
p_inout_mcb5_dqs    => pin_inout_mcb5_dqs   ,
p_inout_mcb5_dqs_n  => pin_inout_mcb5_dqs_n ,
p_inout_mcb5_rzq    => pin_inout_mcb5_rzq   ,
p_inout_mcb5_zio    => pin_inout_mcb5_zio   ,

p_out_mcb1_a        => pin_out_mcb1_a       ,
p_out_mcb1_ba       => pin_out_mcb1_ba      ,
p_out_mcb1_ras_n    => pin_out_mcb1_ras_n   ,
p_out_mcb1_cas_n    => pin_out_mcb1_cas_n   ,
p_out_mcb1_we_n     => pin_out_mcb1_we_n    ,
p_out_mcb1_odt      => pin_out_mcb1_odt     ,
p_out_mcb1_cke      => pin_out_mcb1_cke     ,
p_out_mcb1_dm       => pin_out_mcb1_dm      ,
p_out_mcb1_udm      => pin_out_mcb1_udm     ,
p_out_mcb1_ck       => pin_out_mcb1_ck      ,
p_out_mcb1_ck_n     => pin_out_mcb1_ck_n    ,
p_inout_mcb1_dq     => pin_inout_mcb1_dq    ,
p_inout_mcb1_udqs   => pin_inout_mcb1_udqs  ,
p_inout_mcb1_udqs_n => pin_inout_mcb1_udqs_n,
p_inout_mcb1_dqs    => pin_inout_mcb1_dqs   ,
p_inout_mcb1_dqs_n  => pin_inout_mcb1_dqs_n ,
p_inout_mcb1_rzq    => pin_inout_mcb1_rzq   ,
p_inout_mcb1_zio    => pin_inout_mcb1_zio   ,

--------------------------------------------------
--SATA Driver
--------------------------------------------------
p_out_sata_txn      => pin_out_sata_txn,
p_out_sata_txp      => pin_out_sata_txp,
p_in_sata_rxn       => pin_in_sata_rxn,
p_in_sata_rxp       => pin_in_sata_rxp,
p_in_sata_clk_n     => pin_in_sata_clk_n,
p_in_sata_clk_p     => pin_in_sata_clk_p,

-------------------------------------------------
--���� ���������� ������� + �������
--------------------------------------------------
--��������� ���������� �������
p_in_usr_clk        => g_usr_refclk150,
p_in_usr_tx_wr      => pin_in_SW(2),
p_in_usr_rx_rd      => pin_in_SW(3),
p_in_usr_txd        => i_usr_txd,
p_out_usr_rxd       => i_usr_rxd,
p_out_usr_status    => i_usr_status,

--������� ������
p_out_hdd_rdy       => i_hdd_rdy,
p_out_hdd_err       => i_hdd_err,

--------------------------------------------------
--Sim
--------------------------------------------------
p_out_sim_cfg_clk           => open,
p_in_sim_cfg_adr            => "00000000",
p_in_sim_cfg_adr_ld         => '0',
p_in_sim_cfg_adr_fifo       => '0',
p_in_sim_cfg_txdata         => "0000000000000000",
p_in_sim_cfg_wd             => '0',
p_out_sim_cfg_txrdy         => open,
p_out_sim_cfg_rxdata        => open,
p_in_sim_cfg_rd             => '0',
p_out_sim_cfg_rxrdy         => open,
p_in_sim_cfg_done           => '0',
p_in_sim_cfg_rst            => '0',

p_out_sim_hdd_busy          => open,
p_out_sim_gt_txdata         => open,
p_out_sim_gt_txcharisk      => open,
p_out_sim_gt_txcomstart     => open,
p_in_sim_gt_rxdata          => i_hdd_sim_gt_rxdata,
p_in_sim_gt_rxcharisk       => i_hdd_sim_gt_rxcharisk,
p_in_sim_gt_rxstatus        => i_hdd_sim_gt_rxstatus,
p_in_sim_gt_rxelecidle      => i_hdd_sim_gt_rxelecidle,
p_in_sim_gt_rxdisperr       => i_hdd_sim_gt_rxdisperr,
p_in_sim_gt_rxnotintable    => i_hdd_sim_gt_rxnotintable,
p_in_sim_gt_rxbyteisaligned => i_hdd_sim_gt_rxbyteisaligned,
p_out_gt_sim_rst            => open,
p_out_gt_sim_clk            => open,

p_out_sim_mem               => open,
p_in_sim_mem                => i_sim_mem_out,

--------------------------------------------------
--��������������� ����
--------------------------------------------------
p_inout_ftdi_d      => pin_inout_ftdi_d,
p_out_ftdi_rd_n     => pin_out_ftdi_rd_n,
p_out_ftdi_wr_n     => pin_out_ftdi_wr_n,
p_in_ftdi_txe_n     => pin_in_ftdi_txe_n,
p_in_ftdi_rxf_n     => pin_in_ftdi_rxf_n,
p_in_ftdi_pwren_n   => pin_in_ftdi_pwren_n,

p_out_TP            => i_out_TP,
p_out_led           => pin_out_led
);

--gen_satah: for i in 0 to C_HDD_COUNT_MAX-1 generate
--i_hdd_sim_gt_rxdata(i)<=(others=>'0');
--i_hdd_sim_gt_rxcharisk(i)<=(others=>'0');
--i_hdd_sim_gt_rxstatus(i)<=(others=>'0');
--i_hdd_sim_gt_rxelecidle(i)<='0';
--i_hdd_sim_gt_rxdisperr(i)<=(others=>'0');
--i_hdd_sim_gt_rxnotintable(i)<=(others=>'0');
--i_hdd_sim_gt_rxbyteisaligned(i)<='0';
--end generate gen_satah;




--END MAIN
end architecture;
