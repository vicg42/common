-------------------------------------------------------------------------
-- Company     : Linkos
-- Engineer    : Golovachenko Victor
--
-- Create Date : 03.04.2011 10:42:20
-- Module Name : sata_player_gtsim
--
-- Назначение/Описание :
--   1. Связь компонента GTP_DUAL с более высоким уровнем (в проекте)
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
use work.sata_glob_pkg.all;
use work.sata_pkg.all;

entity sata_player_gtsim is
generic(
G_SATAH_NUM   : integer:=0;
G_GT_CH_COUNT : integer:=2;
G_GT_DBUS     : integer:=16;
G_SIM         : string :="OFF"
);
port(
---------------------------------------------------------------------------
--Usr Cfg
---------------------------------------------------------------------------
p_in_spd               : in    TSpdCtrl_GTCH;
p_in_sys_dcm_gclk2div  : in    std_logic;--//dcm_clk0 /2
p_in_sys_dcm_gclk      : in    std_logic;--//dcm_clk0
p_in_sys_dcm_gclk2x    : in    std_logic;--//dcm_clk0 x 2

p_out_usrclk2          : out   std_logic_vector(C_GTCH_COUNT_MAX-1 downto 0); --//Тактирование тактирование остальных модулей (RX/TX)DUAL_GTP

----------------------------------------------------------------------------
--System
----------------------------------------------------------------------------
--Порт динамическаго конфигурирования DUAL_GTP
p_out_drpdo            : out   std_logic_vector(15 downto 0);
p_out_drprdy           : out   std_logic;

p_out_plllock          : out   std_logic;--//Захват частоты PLL DUAL_GTP
p_out_refclkout        : out   std_logic;--//Фактически дублирование p_in_refclkin. см. стр.68. ug196.pdf

p_in_refclkin          : in    std_logic;--//Опорнач частоа для работы DUAL_GTP

p_in_optrefclksel      : in    std_logic_vector(3 downto 0);
p_in_optrefclk         : in    std_logic_vector(3 downto 0);
p_out_optrefclk        : out   std_logic_vector(3 downto 0);

p_in_rst               : in    std_logic
);
end sata_player_gtsim;

architecture sim_only of sata_player_gtsim is

signal i_spdclk_sel                : std_logic_vector(C_GTCH_COUNT_MAX-1 downto 0);
signal g_gtp_usrclk                : std_logic_vector(C_GTCH_COUNT_MAX-1 downto 0);
signal g_gtp_usrclk2               : std_logic_vector(C_GTCH_COUNT_MAX-1 downto 0);


--MAIN
begin

--gen_v5gtp : if C_FPGA_TYPE=0 generate
--assert G_GT_DBUS>16
--    report "*** V5 gtp dbus : illegal values of G_GT_DBUS " & CONV_STRING(G_GT_DBUS)
--    severity failure;
--end generate gen_v5gtp;
--
--gen_v6s6 : if C_FPGA_TYPE/=0 generate
--assert G_GT_DBUS>32
--    report "*** V5(GTX),V6,S6 GT dbus : illegal values of G_GT_DBUS " & CONV_STRING(G_GT_DBUS)
--    severity failure;
--end generate gen_v6s6;


gen_gt_ch1 : if G_GT_CH_COUNT=1 generate
g_gtp_usrclk(1) <=g_gtp_usrclk(0);
g_gtp_usrclk2(1)<=g_gtp_usrclk2(0);

p_out_usrclk2(1)<=g_gtp_usrclk2(1);
end generate gen_gt_ch1;


gen_ch : for i in 0 to G_GT_CH_COUNT-1 generate

i_spdclk_sel(i)<='0' when p_in_spd(i).sata_ver=CONV_STD_LOGIC_VECTOR(C_FSATA_GEN2, p_in_spd(i).sata_ver'length) else '1';

--//Выбор тактовых частот для работы SATA-I/II

--//------------------------------
--//GT: ШИНА ДАНЫХ=8bit
--//------------------------------
gen_gtp_w8 : if G_GT_DBUS=8 generate
m_bufg_usrclk2 : BUFGMUX_CTRL
port map(
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
port map(
S  => i_spdclk_sel(i),
I0 => p_in_sys_dcm_gclk,    --//S=0 - SATA Generation 2 (3Gb/s)
I1 => p_in_sys_dcm_gclk2div,--//S=1 - SATA Generation 1 (1.5Gb/s)
O  => g_gtp_usrclk2(i)
);
m_bufg_usrclk : BUFGMUX_CTRL
port map(
S  => i_spdclk_sel(i),
I0 => p_in_sys_dcm_gclk2x,  --//S=0 - SATA Generation 2 (3Gb/s)
I1 => p_in_sys_dcm_gclk,    --//S=1 - SATA Generation 1 (1.5Gb/s)
O  => g_gtp_usrclk(i)
);
end generate gen_gtp_w16;

--//------------------------------
--//GT: ШИНА ДАНЫХ=32bit -----  НУЖНА БОЛЛЕ ТОЧНАЯ РЕАЛИЗАЦИЯ, Т.К. ЭТО ЗАПЛАТКА!!!!
--//------------------------------
gen_gtp_w32 : if G_GT_DBUS=32 generate
m_bufg_usrclk2 : BUFGMUX_CTRL
port map(
S  => i_spdclk_sel(i),
I0 => p_in_sys_dcm_gclk,    --//S=0 - SATA Generation 2 (3Gb/s)
I1 => p_in_sys_dcm_gclk2div,--//S=1 - SATA Generation 1 (1.5Gb/s)
O  => g_gtp_usrclk2(i)
);
m_bufg_usrclk : BUFGMUX_CTRL
port map(
S  => i_spdclk_sel(i),
I0 => p_in_sys_dcm_gclk2x,  --//S=0 - SATA Generation 2 (3Gb/s)
I1 => p_in_sys_dcm_gclk,    --//S=1 - SATA Generation 1 (1.5Gb/s)
O  => g_gtp_usrclk(i)
);
end generate gen_gtp_w32;

p_out_usrclk2(i)<=g_gtp_usrclk2(i);

end generate gen_ch;


p_out_drpdo<="1000"&"0000"&"0000"&"0100";
p_out_drprdy<='1';

p_out_plllock<= not p_in_rst;
p_out_refclkout<=p_in_refclkin;

p_out_optrefclk<=(others=>'0');

--END MAIN
end sim_only;
