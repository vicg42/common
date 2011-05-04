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
use work.sata_pkg.all;

entity sata_player_gtsim is
generic
(
G_GTP_DBUS             : integer   := 16;   --//
G_SIM                  : string    := "OFF"
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
p_in_rst               : in    std_logic
);
end sata_player_gtsim;

architecture RTL of sata_player_gtsim is

signal i_spdclk_sel                : std_logic_vector(C_GTCH_COUNT_MAX-1 downto 0);
signal g_gtp_usrclk                : std_logic_vector(C_GTCH_COUNT_MAX-1 downto 0);
signal g_gtp_usrclk2               : std_logic_vector(C_GTCH_COUNT_MAX-1 downto 0);


--MAIN
begin

gen_ch : for i in 0 to C_GTCH_COUNT_MAX-1 generate

i_spdclk_sel(i)<='0' when p_in_spd(i).sata_ver=CONV_STD_LOGIC_VECTOR(C_FSATA_GEN2, p_in_spd(i).sata_ver'length) else '1';

--//Выбор тактовых частот для работы SATA-I/II
gen_gtp_w8 : if G_GTP_DBUS=8 generate
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

gen_gtp_w16 : if G_GTP_DBUS=16 generate
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

p_out_usrclk2(i)<=g_gtp_usrclk2(i);
end generate gen_ch;


p_out_drpdo<="1000"&"0000"&"0000"&"0100";
p_out_drprdy<='1';

p_out_plllock<= not p_in_rst;
p_out_refclkout<=p_in_refclkin;

--END MAIN
end RTL;
