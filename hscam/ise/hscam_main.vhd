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
--Технологический порт
--------------------------------------------------
pin_inout_ftdi_d   : inout std_logic_vector(7 downto 0);
pin_out_ftdi_rd_n  : out   std_logic;
pin_out_ftdi_wr_n  : out   std_logic;
pin_in_ftdi_txe_n  : in    std_logic;
pin_in_ftdi_rxf_n  : in    std_logic;
pin_in_ftdi_pwren_n: in    std_logic;

pin_out_TP2        : out   std_logic_vector(1 downto 0);
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
p_out_sata_txn   : out   std_logic_vector((C_SH_GTCH_COUNT_MAX*C_SH_COUNT_MAX(C_PCFG_HDD_COUNT-1))-1 downto 0);--std_logic_vector(3 downto 0);
p_out_sata_txp   : out   std_logic_vector((C_SH_GTCH_COUNT_MAX*C_SH_COUNT_MAX(C_PCFG_HDD_COUNT-1))-1 downto 0);--std_logic_vector(3 downto 0);
p_in_sata_rxn    : in    std_logic_vector((C_SH_GTCH_COUNT_MAX*C_SH_COUNT_MAX(C_PCFG_HDD_COUNT-1))-1 downto 0);--std_logic_vector(3 downto 0);
p_in_sata_rxp    : in    std_logic_vector((C_SH_GTCH_COUNT_MAX*C_SH_COUNT_MAX(C_PCFG_HDD_COUNT-1))-1 downto 0);--std_logic_vector(3 downto 0);
p_in_sata_clk_n  : in    std_logic_vector(C_SH_COUNT_MAX(C_PCFG_HDD_COUNT-1)-1 downto 0);                      --std_logic_vector(0 downto 0);
p_in_sata_clk_p  : in    std_logic_vector(C_SH_COUNT_MAX(C_PCFG_HDD_COUNT-1)-1 downto 0);                      --std_logic_vector(0 downto 0);

--------------------------------------------------
--System
--------------------------------------------------
p_out_hdd_grefclk150M : out   std_logic;

p_out_hdd_dcm_lock    : out   std_logic;
p_out_hdd_dcm_gclk75M : out   std_logic;
p_out_hdd_dcm_gclk300M: out   std_logic;
p_out_hdd_dcm_gclk150M: out   std_logic;

p_out_usrpll_lock     : out   std_logic;
p_out_usrpll_gclk1    : out   std_logic;

--------------------------------------------------
--Технологический порт
--------------------------------------------------
p_inout_ftdi_d   : inout std_logic_vector(7 downto 0);
p_out_ftdi_rd_n  : out   std_logic;
p_out_ftdi_wr_n  : out   std_logic;
p_in_ftdi_txe_n  : in    std_logic;
p_in_ftdi_rxf_n  : in    std_logic;
p_in_ftdi_pwren_n: in    std_logic;

p_out_TP         : out   std_logic_vector(7 downto 0);
p_out_led        : out   std_logic_vector(7 downto 0)
);
end component;

component vtiming_gen
generic(
G_TVS : integer:=32;
G_THS : integer:=32;
G_PIX_COUNT : integer:=32;
G_ROW_COUNT : integer:=32
);
port(
p_out_vs : out  std_logic;
p_out_hs : out  std_logic;

p_in_clk : in   std_logic;
p_in_rst : in   std_logic
);
end component;

signal i_hdd_grefclk150M              : std_logic;

signal i_hdd_dcm_lock                 : std_logic;
signal i_hdd_dcm_gclk75M              : std_logic;
signal i_hdd_dcm_gclk300M             : std_logic;
signal i_hdd_dcm_gclk150M             : std_logic;

signal i_usrpll_lock                  : std_logic;
signal g_usrpll_clk1                  : std_logic;

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


--MAIN
begin


i_vtg_rst <=not i_hdd_dcm_lock;--i_usrpll_lock;
i_vin_clk <=g_usrpll_clk1;--62.5MHz  i_hdd_dcm_gclk75M;--i_hdd_grefclk150M;--
i_vout_clk<=g_usrpll_clk1;--i_hdd_dcm_gclk300M;--i_hdd_dcm_gclk75M;--i_hdd_grefclk150M;--

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
G_TVS => 32,
G_THS => 16,
G_PIX_COUNT => (C_PCFG_FRPIX/10),
G_ROW_COUNT => C_PCFG_FRROW
)
port map(
p_out_vs => i_vin_vs,
p_out_hs => i_vin_hs,

p_in_clk => i_vin_clk,
p_in_rst => i_vtg_rst
);

m_vtgen_low : vtiming_gen
generic map(
G_TVS => 32,
G_THS => 8,
G_PIX_COUNT => (C_PCFG_FRPIX/32),
G_ROW_COUNT => C_PCFG_FRROW
)
port map(
p_out_vs => i_vout_vs,
p_out_hs => i_vout_hs,

p_in_clk => i_vout_clk,
p_in_rst => i_vtg_rst
);


pin_out_TP2(0)<=OR_reduce(i_vout_d);
pin_out_TP2(1)<='0';


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
p_in_vin_vs   => i_vin_vs,
p_in_vin_hs   => i_vin_hs,
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
--System
--------------------------------------------------
p_out_hdd_grefclk150M => i_hdd_grefclk150M,

p_out_hdd_dcm_lock    => i_hdd_dcm_lock,
p_out_hdd_dcm_gclk75M => i_hdd_dcm_gclk75M,
p_out_hdd_dcm_gclk300M=> i_hdd_dcm_gclk300M,
p_out_hdd_dcm_gclk150M=> i_hdd_dcm_gclk150M,

p_out_usrpll_lock     => i_usrpll_lock,
p_out_usrpll_gclk1    => g_usrpll_clk1,

--------------------------------------------------
--Технологический порт
--------------------------------------------------
p_inout_ftdi_d      => pin_inout_ftdi_d,
p_out_ftdi_rd_n     => pin_out_ftdi_rd_n,
p_out_ftdi_wr_n     => pin_out_ftdi_wr_n,
p_in_ftdi_txe_n     => pin_in_ftdi_txe_n,
p_in_ftdi_rxf_n     => pin_in_ftdi_rxf_n,
p_in_ftdi_pwren_n   => pin_in_ftdi_pwren_n,

p_out_TP            => pin_out_TP,
p_out_led           => pin_out_led
);



--END MAIN
end architecture;
