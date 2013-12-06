-------------------------------------------------------------------------
-- Company     : Linkos
-- Engineer    : Golovachenko Victor
--
-- Create Date : 24.09.2012 16:10:45
-- Module Name : dvi_tst_main
--
-- Ќазначение/ќписание :
--
-- Revision:
-- Revision 0.01 - File Created
-------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_misc.all;
use ieee.std_logic_unsigned.all;

library work;
use work.vicg_common_pkg.all;
use work.clocks_pkg.all;

entity dvi_tst_main is
port(
--------------------------------------------------
--“ехнологический порт
--------------------------------------------------
pin_out_led      : out   std_logic_vector(7 downto 0);
pin_out_TP       : out   std_logic_vector(0 downto 0);
pin_in_btn_N     : in    std_logic;

--------------------------------------------------
--DVI
--------------------------------------------------
pin_inout_dvi_sda: inout std_logic;
pin_inout_dvi_scl: inout std_logic;
pin_out_dvi_clk  : out   std_logic_vector(1 downto 0);
pin_out_dvi_d    : out   std_logic_vector(11 downto 0);
pin_out_dvi_de   : out   std_logic;
pin_out_dvi_hs   : out   std_logic;
pin_out_dvi_vs   : out   std_logic;

--------------------------------------------------
--Reference clock
--------------------------------------------------
pin_in_refclk    : in    TRefClkPinIN
);
end dvi_tst_main;

architecture behavioral of dvi_tst_main is

component fpga_test_01
generic(
G_BLINK_T05   : integer:=10#125#; -- 1/2 периода мигани€ светодиода.(врем€ в ms)
G_CLK_T05us   : integer:=10#1000# -- кол-во периодов частоты порта p_in_clk
                                  -- укладывающиес_ в 1/2 периода 1us
);
port(
p_out_test_led : out   std_logic;--мигание сведодиода
p_out_test_done: out   std_logic;--сигнал переходи в '1' через 3 сек.

p_out_1us      : out   std_logic;
p_out_1ms      : out   std_logic;
-------------------------------
--System
-------------------------------
p_in_clk       : in    std_logic;
p_in_rst       : in    std_logic
);
end component;

component clocks
port(
p_out_rst  : out   std_logic;
p_out_gclk : out   std_logic_vector(7 downto 0);

p_in_clkopt: in    std_logic_vector(3 downto 0);
p_in_clk   : in    TRefClkPinIN
);
end component;

component dvi_ctrl
generic(
G_DBG : string := "OFF";
G_SIM : string := "OFF"
);
port(
p_in_ctrl     : in    std_logic_vector(15 downto 0);
p_out_err     : out   std_logic;

--VIN
p_in_vdi      : in    std_logic_vector(31 downto 0);
p_out_vdi_rd  : out   std_logic;
p_out_vdi_clk : out   std_logic;

--VOUT
p_out_clk     : out   std_logic_vector(1 downto 0);
p_out_vd      : out   std_logic_vector(11 downto 0);
p_out_vde     : out   std_logic;
p_out_hs      : out   std_logic;
p_out_vs      : out   std_logic;

--I2C
p_inout_sda   : inout std_logic;
p_inout_scl   : inout std_logic;

--“ехнологический
p_in_tst      : in    std_logic_vector(31 downto 0);
p_out_tst     : out   std_logic_vector(31 downto 0);

--System
p_in_clk      : in    std_logic;
p_in_rst      : in    std_logic
);
end component;

signal g_rst                 : std_logic;
signal i_usrclk_rst          : std_logic;
signal g_usrclk              : std_logic_vector(7 downto 0);

signal i_dvi_ctrl            : std_logic_vector(15 downto 0);
signal i_dvi_err             : std_logic;
signal i_dvi_clk             : std_logic;
signal tst_div_out           : std_logic_vector(31 downto 0);

signal i_test01_led          : std_logic;


attribute keep : string;
attribute keep of i_dvi_clk : signal is "true";


--MAIN
begin

--***********************************************************
--RESET модулей
--***********************************************************
g_rst <= i_usrclk_rst or pin_in_btn_N;


--***********************************************************
--”становка частот проекта:
--***********************************************************
m_clocks : clocks
port map(
p_out_rst  => i_usrclk_rst,
p_out_gclk => g_usrclk,

p_in_clkopt=> (others=>'0'),
p_in_clk   => pin_in_refclk
);

i_dvi_clk <= g_usrclk(2);


--***********************************************************
--
--***********************************************************
i_dvi_ctrl(0) <= '1'; --1/0 - Test pattern/Vin port
i_dvi_ctrl(15 downto 1) <= (others=>'0');

m_dvi : dvi_ctrl
generic map(
G_DBG => "OFF",
G_SIM => "OFF"
)
port map(
p_in_ctrl     => i_dvi_ctrl,
p_out_err     => i_dvi_err,

--VIN
p_in_vdi      => (others=>'0'),
p_out_vdi_rd  => open,
p_out_vdi_clk => open,

--VOUT
p_out_clk     => pin_out_dvi_clk,
p_out_vd      => pin_out_dvi_d  ,
p_out_vde     => pin_out_dvi_de ,
p_out_hs      => pin_out_dvi_hs ,
p_out_vs      => pin_out_dvi_vs ,

--I2C
p_inout_sda   => pin_inout_dvi_sda,
p_inout_scl   => pin_inout_dvi_scl,

--“ехнологический
p_in_tst      => (others=>'0'),
p_out_tst     => tst_div_out,

--System
p_in_clk      => i_dvi_clk,
p_in_rst      => g_rst
);


--#########################################
--DBG
--#########################################
pin_out_TP(0) <= OR_reduce(tst_div_out);

pin_out_led(0) <= i_test01_led;
pin_out_led(1) <= i_dvi_err;
pin_out_led(2) <= '0';
pin_out_led(3) <= '0';
pin_out_led(4) <= '0';
pin_out_led(5) <= '0';
pin_out_led(6) <= '0';
pin_out_led(7) <= '0';

m_gt_03_test: fpga_test_01
generic map(
G_BLINK_T05   =>10#250#,
G_CLK_T05us   =>10#50#
)
port map(
p_out_test_led => i_test01_led,
p_out_test_done=> open,

p_out_1us      => open,
p_out_1ms      => open,
-------------------------------
--System
-------------------------------
p_in_clk       => i_dvi_clk,
p_in_rst       => g_rst
);

--END MAIN
end behavioral;


