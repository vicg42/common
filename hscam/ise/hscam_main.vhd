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
use ieee.std_logic_misc.all;
use ieee.std_logic_unsigned.all;

library unisim;
use unisim.vcomponents.all;

library work;
use work.vicg_common_pkg.all;
use work.prj_cfg.all;
use work.prj_def.all;
use work.cfgdev_pkg.all;
use work.sata_glob_pkg.all;
use work.dsn_hdd_pkg.all;

entity hscam_main is
generic(
G_SIM             : string:="OFF"
);
port
(
--------------------------------------------------
--Технологический порт
--------------------------------------------------
pin_out_TP         : out   std_logic_vector(7 downto 0);
pin_in_SW          : in    std_logic_vector(3 downto 0);
pin_out_led        : out   std_logic_vector(7 downto 0);

pin_inout_ftdi_d   : inout std_logic_vector(7 downto 0);
pin_out_ftdi_rd_n  : out   std_logic;
pin_out_ftdi_wr_n  : out   std_logic;
pin_in_ftdi_txe_n  : in    std_logic;
pin_in_ftdi_rxf_n  : in    std_logic;
pin_in_ftdi_pwren_n: in    std_logic;

--------------------------------------------------
--Image Sensor
--------------------------------------------------
pin_in_ims_ra      : in    std_logic_vector(7 downto 0); --//Row Addr
pin_in_ims_d       : in    std_logic_vector(99 downto 0);--//DATA
pin_out_ims_dren   : out   std_logic;                    --//DATA_READ_EN_N
pin_out_ims_ldsh   : out   std_logic;                    --//LD_SHFT_N
pin_in_ims_cldone  : in    std_logic;                    --//CAL_DONE_N
pin_out_ims_clstart: out   std_logic;                    --//CAL_STRT_N
pin_in_ims_rdone   : in    std_logic;                    --//ROW_DONE_N
pin_out_ims_rstart : out   std_logic;                    --//ROW_STRT_N
pin_out_ims_dark   : out   std_logic;                    --//DARK_OFF_EN_N
pin_out_ims_stby   : out   std_logic;                    --//STANDBY_N
pin_out_ims_lrst   : out   std_logic;                    --//LRST_N
pin_out_ims_pg     : out   std_logic;                    --//PG_N
pin_out_ims_tx     : out   std_logic;                    --//TX_N
pin_out_ims_pclk   : out   std_logic;                    --//PIXEL_CLK_OUT
pin_in_ims_sclk    : in    std_logic;                    --//Sys Clk

pin_out_ims_en     : out   std_logic;                    --//Сигнал на схеме EN
pin_out_ims_tec_p  : out   std_logic;                    --//Сигнал на схеме TEC+
pin_out_ims_tec_n  : out   std_logic;                    --//Сигнал на схеме TEC-
pin_inout_ims_sda  : inout std_logic;                    --//Сигнал на схеме SDA
pin_out_ims_scl    : out   std_logic;                    --//Сигнал на схеме SCL

--------------------------------------------------
--Camera Link
--------------------------------------------------
pin_out_cl_xp      : out   std_logic_vector(3 downto 0); --//X(x)_p
pin_out_cl_xn      : out   std_logic_vector(3 downto 0); --//X(x)_n
pin_out_cl_xclk_p  : out   std_logic;
pin_out_cl_xclk_n  : out   std_logic;

pin_in_cl_cc_p     : in    std_logic_vector(4 downto 1); --//CC(x)_p
pin_in_cl_cc_n     : in    std_logic_vector(4 downto 1); --//CC(x)_n
pin_out_cl_tx_p    : out   std_logic;                    --//Грубо говоря UART для управления камерой:
pin_out_cl_tx_n    : out   std_logic;                    --//UART/TX (Camera -> FG)
pin_in_cl_rx_p     : in    std_logic;                    --//UART/RX (Camera <- FG)
pin_in_cl_rx_n     : in    std_logic;

--------------------------------------------------
--RAM
--------------------------------------------------
mcb5_dram_dq       : in std_logic_vector(15 downto 0);
mcb5_dram_a        : in std_logic_vector(12 downto 0);
mcb5_dram_ba       : in std_logic_vector(3 downto 0);
mcb5_dram_dqs      : in std_logic;
mcb5_dram_dqs_n    : in std_logic;
mcb5_dram_ck       : in std_logic;
mcb5_dram_ck_n     : in std_logic;
mcb5_dram_cke      : in std_logic;
mcb5_dram_ras_n    : in std_logic;
mcb5_dram_cas_n    : in std_logic;
mcb5_dram_we_n     : in std_logic;
mcb5_dram_odt      : in std_logic;
mcb5_dram_reset_n  : in std_logic;
mcb5_dram_dm       : in std_logic;
mcb5_rzq           : in std_logic;
c5_sys_clk_p       : in std_logic;
c5_sys_clk_n       : in std_logic;
c5_sys_rst_i       : in std_logic;

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
--Reference clock
--------------------------------------------------
pin_in_refclk_n    : in    std_logic;
pin_in_refclk_p    : in    std_logic
);
end entity;

architecture struct of hscam_main is

component camctrl_main
port (
p_out_TP         : out   std_logic_vector(7 downto 0);
p_in_SW          : in    std_logic_vector(3 downto 0);

p_in_ims_ra      : in    std_logic_vector(7 downto 0);
p_in_ims_d       : in    std_logic_vector(99 downto 0);
p_out_ims_dren   : out   std_logic;
p_out_ims_ldsh   : out   std_logic;
p_in_ims_cldone  : in    std_logic;
p_out_ims_clstart: out   std_logic;
p_in_ims_rdone   : in    std_logic;
p_out_ims_rstart : out   std_logic;
p_out_ims_dark   : out   std_logic;
p_out_ims_stby   : out   std_logic;
p_out_ims_lrst   : out   std_logic;
p_out_ims_pg     : out   std_logic;
p_out_ims_tx     : out   std_logic;
p_out_ims_pclk   : out   std_logic;
p_in_ims_sclk    : in    std_logic;

p_out_ims_en     : out   std_logic;
p_out_ims_tec_p  : out   std_logic;
p_out_ims_tec_n  : out   std_logic;
p_inout_ims_sda  : inout std_logic;
p_out_ims_scl    : out   std_logic;
);
end component;

component hdd_main
generic(
G_MODULE_USE : string:="ON";
G_HDD_COUNT  : integer:=1;
G_DBGCS      : string:="OFF";
G_SIM        : string:="OFF"
);
port
(
--------------------------------------------------
--SATA Driver
--------------------------------------------------
p_out_sata_txn            : out   std_logic_vector((C_SH_GTCH_COUNT_MAX*C_SH_COUNT_MAX(G_HDD_COUNT-1))-1 downto 0);
p_out_sata_txp            : out   std_logic_vector((C_SH_GTCH_COUNT_MAX*C_SH_COUNT_MAX(G_HDD_COUNT-1))-1 downto 0);
p_in_sata_rxn             : in    std_logic_vector((C_SH_GTCH_COUNT_MAX*C_SH_COUNT_MAX(G_HDD_COUNT-1))-1 downto 0);
p_in_sata_rxp             : in    std_logic_vector((C_SH_GTCH_COUNT_MAX*C_SH_COUNT_MAX(G_HDD_COUNT-1))-1 downto 0);

p_in_sata_refclk          : in    std_logic_vector(C_SH_COUNT_MAX(G_HDD_COUNT-1)-1 downto 0);
p_out_sata_refclkout      : out   std_logic;

---------------------------------------------------------------------------
--Технологический порт
---------------------------------------------------------------------------
p_in_tst                 : in    std_logic_vector(31 downto 0);
p_out_tst                : out   std_logic_vector(31 downto 0);

--------------------------------------------------
--System
--------------------------------------------------
p_in_clk              : in    std_logic;
p_in_rst              : in    std_logic
);
end component;


signal i_refclk                         : std_logic;
signal g_refclk                         : std_logic;

signal i_hdd_gt_refclk150               : std_logic_vector(C_SH_COUNT_MAX(C_PCFG_HDD_COUNT-1)-1 downto 0);
signal g_hdd_gt_refclkout               : std_logic;


--MAIN
begin


--***********************************************************
--          Установка частот проекта:
--***********************************************************
ibufg_refclk : IBUFGDS port map(I  => pin_in_refclk_p, IB => pin_in_refclk_n, O  => i_refclk);
bufg_refclk  : BUFG    port map(I  => i_refclk, O  => g_refclk);

--//Input 150MHz reference clock for SATA
gen_sata_gt : for i in 0 to C_SH_COUNT_MAX(C_PCFG_HDD_COUNT-1)-1 generate
ibufds_hdd_gt_refclk : IBUFDS port map(I  => pin_in_sata_clk_p(i), IB => pin_in_sata_clk_n(i), O  => i_hdd_gt_refclk150(i));
end generate gen_sata_gt;


--***********************************************************
-- Модуль HDD:
--***********************************************************
m_hdd : hdd_main
generic map(
G_MODULE_USE=> C_PCFG_HDD_USE,
G_HDD_COUNT => C_PCFG_HDD_COUNT,
G_DBGCS     => C_PCFG_HDD_DBGCS,
G_SIM       => G_SIM
);
port(
--------------------------------------------------
--SATA Driver
--------------------------------------------------
p_out_sata_txn        => pin_out_sata_txn,
p_out_sata_txp        => pin_out_sata_txp,
p_in_sata_rxn         => pin_in_sata_rxn,
p_in_sata_rxp         => pin_in_sata_rxp,

p_in_sata_refclk      => i_hdd_gt_refclk150,
p_out_sata_refclkout  => g_hdd_gt_refclkout,

--------------------------------------------------
--Технологический порт
--------------------------------------------------
p_in_tst              => "00000000000000000000000000000000",
p_out_tst             => open,

--------------------------------------------------
--System
--------------------------------------------------
p_in_clk              => g_refclk
p_in_rst              => '0'
);


--***********************************************************
-- Модуль управления Image Sensor:
--***********************************************************
m_camctrl : camctrl_main
port map (
p_out_TP         => pin_out_TP         ,
p_in_SW          => pin_in_SW          ,

p_in_ims_ra      => pin_in_ims_ra      ,
p_in_ims_d       => pin_in_ims_d       ,
p_out_ims_dren   => pin_out_ims_dren   ,
p_out_ims_ldsh   => pin_out_ims_ldsh   ,
p_in_ims_cldone  => pin_in_ims_cldone  ,
p_out_ims_clstart=> pin_out_ims_clstart,
p_in_ims_rdone   => pin_in_ims_rdone   ,
p_out_ims_rstart => pin_out_ims_rstart ,
p_out_ims_dark   => pin_out_ims_dark   ,
p_out_ims_stby   => pin_out_ims_stby   ,
p_out_ims_lrst   => pin_out_ims_lrst   ,
p_out_ims_pg     => pin_out_ims_pg     ,
p_out_ims_tx     => pin_out_ims_tx     ,
p_out_ims_pclk   => pin_out_ims_pclk   ,
p_in_ims_sclk    => pin_in_ims_sclk    ,

p_out_ims_en     => pin_out_ims_en     ,
p_out_ims_tec_p  => pin_out_ims_tec_p  ,
p_out_ims_tec_n  => pin_out_ims_tec_n  ,
p_inout_ims_sda  => pin_inout_ims_sda  ,
p_out_ims_scl    => pin_out_ims_scl
);



--END MAIN
end architecture;
