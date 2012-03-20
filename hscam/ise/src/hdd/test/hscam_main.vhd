-------------------------------------------------------------------------
-- Company     : Linkos
-- Engineer    : Golovachenko Victor + Kukla Anatol
--
-- Create Date : 26.10.2011 16:40:26
-- Module Name : hscam_main
--
-- Назначение/Описание :
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

library unisim;
use unisim.vcomponents.all;

entity hscam_main is
generic(
G_VOUT_DWIDTH : integer:=32;
G_VSYN_ACTIVE : std_logic:='1';
G_SIM : string:="OFF"
);
port
(
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
--Технологический порт
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
G_VOUT_DWIDTH : integer:=32;
G_VSYN_ACTIVE : std_logic:='1';
G_SIM : string:="OFF"
);
port(
--------------------------------------------------
--VideoIN
--------------------------------------------------
p_in_vd       : in   std_logic_vector(99 downto 0);
p_in_vin_vs   : in   std_logic;
p_in_vin_hs   : in   std_logic;
p_in_vin_clk  : in   std_logic;

--------------------------------------------------
--VideoOUT
--------------------------------------------------
p_out_vd      : out  std_logic_vector(G_VOUT_DWIDTH-1 downto 0);
p_in_vout_vs  : in   std_logic;
p_in_vout_hs  : in   std_logic;
p_in_vout_clk : in   std_logic;

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
p_in_sata_clk_n     : in    std_logic_vector(C_SH_COUNT_MAX(C_PCFG_HDD_COUNT-1)-1 downto 0);                      --std_logic_vector(0 downto 0);
p_in_sata_clk_p     : in    std_logic_vector(C_SH_COUNT_MAX(C_PCFG_HDD_COUNT-1)-1 downto 0);                      --std_logic_vector(0 downto 0);

--------------------------------------------------
--Статус модуля
--------------------------------------------------
p_out_module_rdy    : out   std_logic;--Модуль готов к работе
p_out_module_err    : out   std_logic;--Ошибки в работе

--------------------------------------------------
--Управление модулем
--------------------------------------------------
p_in_clk            : in    std_logic;                    --частота тактирования p_in_txd/rxd/tx_wr/rx_rd
p_in_txd            : in    std_logic_vector(15 downto 0);
p_in_tx_wr          : in    std_logic;                    --строб записи txdata
p_out_rxd           : out   std_logic_vector(15 downto 0);
p_in_rx_rd          : in    std_logic;                    --строб чтения rxdata
p_out_tx_rdy        : out   std_logic;                    --Статус txbuf
p_out_rx_rdy        : out   std_logic;                    --Статус rxbuf

p_in_ftdi_sel       : in    std_logic;                    --Управление модулем через USB

--------------------------------------------------
--System
--------------------------------------------------
p_in_grefclk        : in    std_logic;

--------------------------------------------------
--Технологический порт
--------------------------------------------------
--Интрефейс с USB(FTDI)
p_inout_ftdi_d      : inout std_logic_vector(7 downto 0);
p_out_ftdi_rd_n     : out   std_logic;
p_out_ftdi_wr_n     : out   std_logic;
p_in_ftdi_txe_n     : in    std_logic;
p_in_ftdi_rxf_n     : in    std_logic;
p_in_ftdi_pwren_n   : in    std_logic;

--
p_in_tst            : in    std_logic_vector(31 downto 0);
p_out_tst           : out   std_logic_vector(31 downto 0);

p_out_TP            : out   std_logic_vector(7 downto 0); --вывод на контрольные точки платы
p_out_led           : out   std_logic_vector(7 downto 0)  --выход на свтодиоды платы
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
signal i_usrpll_clkout                : std_logic_vector(0 downto 0);
signal g_usrpll_clkout                : std_logic_vector(0 downto 0);
signal i_usrpll_lock                  : std_logic;

signal i_vtg_rst                      : std_logic;
type TDtest   is array(0 to 9) of std_logic_vector(7 downto 0);
signal i_tdata                        : TDtest;

signal i_vin_d                        : std_logic_vector(99 downto 0):=(others=>'0');
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

signal tst_out                        : std_logic_vector(31 downto 0);
signal tst_in                         : std_logic_vector(31 downto 0);
signal i_test02_led                   : std_logic;
signal i_cntbase                      : std_logic_vector(7 downto 0);
signal i_spd                          : std_logic_vector(7 downto 0);
signal i_shim_hs                      : std_logic;
--signal i_shim_vs                      : std_logic;
signal i_shim_vs_cnt                  : std_logic_vector(7 downto 0);
signal sr_shim_hs                     : std_logic_vector(0 to 1);

signal tmp_vs                         : std_logic;
signal tmp_hs                         : std_logic;

signal i_rx_rdy,i_tx_rdy              : std_logic;
signal i_rxd,i_txd                    : std_logic_vector(15 downto 0);



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
CLKOUT0_DIVIDE     => 9, --clk0 = ((125MHz * 5)/1) /9 = 69.4MHz
CLKOUT1_DIVIDE     => 3,
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
DIVCLK_DIVIDE      => 1,
CLKFBOUT_MULT      => 5,
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
CLKOUT1          => open,
CLKOUT2          => open,
CLKOUT3          => open,
CLKOUT4          => open,
CLKOUT5          => open,
DO               => open,
DRDY             => open,
LOCKED           => i_usrpll_lock
);

--gen_clk : for i in 0 to 0 generate
m_bufg : BUFG port map(I => i_usrpll_clkout(0), O => g_usrpll_clkout(0) );
--end generate gen_clk;

i_sys_rst <= '0';

m_blink2 : fpga_test_01
generic map(
G_BLINK_T05   =>10#250#, -- 1/2 периода мигания светодиода.(время в ms)
G_CLK_T05us   =>10#75#   -- 05us - 150MHz
)
port map(
p_out_test_led => i_test02_led,
p_out_test_done=> open,

p_out_1us      => open,
p_out_1ms      => open,
-------------------------------
--System
-------------------------------
p_in_clk       => g_usr_refclk150, --p_in_grefclk,
p_in_rst       => i_sys_rst
);

i_vtg_rst <=i_sys_rst;
i_vin_clk <=g_usrpll_clkout(0);
i_vout_clk<=g_usrpll_clkout(0);

--Генератор тестовых данных (Вертикальные полоски!!!)
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

i_vin_d((10*i)-8-1 downto (10*i)-10)<=(others=>'0');
i_vin_d((10*i)-1 downto (10*i)-8)<=i_tdata(i-1);
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

--//Регулировка потока тестовых данных
i_spd<=CONV_STD_LOGIC_VECTOR(255, i_spd'length) when tst_out(7 downto 0)=CONV_STD_LOGIC_VECTOR(0, 8) else tst_out(7 downto 0);
process(i_usrpll_lock,i_vin_clk)
begin
  if i_usrpll_lock='0' then
    i_cntbase<=(others=>'0');
--    i_shim_vs<=G_VSYN_ACTIVE;
    i_shim_hs<='0';
    i_shim_vs_cnt<=(others=>'0');
    sr_shim_hs<=(others=>'0');
  elsif i_vin_clk'event and i_vin_clk='1' then
    if i_cntbase=i_spd then
      i_shim_hs<='0';
--      i_shim_vs<=not G_VSYN_ACTIVE;
    elsif i_cntbase=(i_cntbase'range => '0') then
      i_shim_hs<='1';
--      i_shim_vs<=G_VSYN_ACTIVE;
    else
--      i_shim_vs<=not G_VSYN_ACTIVE;
    end if;

    i_cntbase<=i_cntbase+1;

    sr_shim_hs<=i_shim_hs & sr_shim_hs(0 to 0);
    if sr_shim_hs(0)='0' and sr_shim_hs(1)='1' then
      i_shim_vs_cnt<=i_shim_vs_cnt + 1;
    end if;
--    if i_shim_vs=G_VSYN_ACTIVE then
--      i_shim_vs_cnt<=i_shim_vs_cnt + 1;
--    end if;
  end if;
end process;

--tst_in(0)<=    i_shim_vs when i_shim_vs_cnt=CONV_STD_LOGIC_VECTOR(250, i_shim_vs_cnt'length) else '0';--i_vin_vs;--
--tst_in(1)<=not i_shim_hs;                                                                             --i_vin_hs;--
tmp_vs<=    i_shim_hs when i_shim_vs_cnt=CONV_STD_LOGIC_VECTOR(250, i_shim_vs_cnt'length) else '0';--i_vin_vs;--
tmp_hs<=not i_shim_hs;

tst_in(0)<=tmp_vs when tst_out(8)='1' else i_vin_vs;
tst_in(1)<=tmp_hs when tst_out(8)='1' else i_vin_hs;
tst_in(2)<=i_test02_led;
tst_in(31 downto 3)<=(others=>'0');


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


pin_out_TP2(0)<=OR_reduce(i_vout_d) or OR_reduce(i_rxd) or i_tx_rdy or i_rx_rdy;
pin_out_TP2(1)<='0';

gen_tx: for i in 0 to 15 generate
i_txd(i)<=pin_in_SW(1);
end generate gen_tx;


--***********************************************************
-- Модуль HDD:
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
p_in_vd       => i_vin_d,
p_in_vin_vs   => tst_in(0),--i_vin_vs,
p_in_vin_hs   => tst_in(1),--i_vin_hs,
p_in_vin_clk  => i_vin_clk,

--------------------------------------------------
--VideoOUT
--------------------------------------------------
p_out_vd      => i_vout_d,
p_in_vout_vs  => i_vout_vs,
p_in_vout_hs  => i_vout_hs,
p_in_vout_clk => i_vout_clk,

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

--------------------------------------------------
--Статус модуля
--------------------------------------------------
p_out_module_rdy    => open,
p_out_module_err    => open,

--------------------------------------------------
--Управление модулем
--------------------------------------------------
p_in_clk            => g_usr_refclk150,
p_in_txd            => i_txd,
p_in_tx_wr          => pin_in_SW(2),
p_out_rxd           => i_rxd,
p_in_rx_rd          => pin_in_SW(3),
p_out_tx_rdy        => i_tx_rdy,
p_out_rx_rdy        => i_rx_rdy,

p_in_ftdi_sel       => pin_in_SW(0),

--------------------------------------------------
--System
--------------------------------------------------
p_in_grefclk        => g_usr_refclk150,

--------------------------------------------------
--Технологический порт
--------------------------------------------------
p_inout_ftdi_d      => pin_inout_ftdi_d,
p_out_ftdi_rd_n     => pin_out_ftdi_rd_n,
p_out_ftdi_wr_n     => pin_out_ftdi_wr_n,
p_in_ftdi_txe_n     => pin_in_ftdi_txe_n,
p_in_ftdi_rxf_n     => pin_in_ftdi_rxf_n,
p_in_ftdi_pwren_n   => pin_in_ftdi_pwren_n,

p_in_tst            => tst_in,
p_out_tst           => tst_out,

p_out_TP            => pin_out_TP,
p_out_led           => pin_out_led
);



--END MAIN
end architecture;
