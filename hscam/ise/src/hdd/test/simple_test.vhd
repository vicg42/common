-------------------------------------------------------------------------
-- Company     : Linkos
-- Engineer    : Golovachenko Victor
--
-- Create Date : 20.01.2011 11:43:14
-- Module Name : simple_test
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

Library UNISIM;
use UNISIM.vcomponents.all;

library work;
use work.vicg_common_pkg.all;
use work.cfgdev_pkg.all;

entity simple_test is
generic(
G_IF  : string:="FTDI";
G_SIM : string:="OFF"
);
port(
--------------------------------------------------
--DBG
--------------------------------------------------
pin_out_led_C         : out   std_logic;
pin_out_led_E         : out   std_logic;
pin_out_led_N         : out   std_logic;
pin_out_led_S         : out   std_logic;
pin_out_led_W         : out   std_logic;

pin_in_btn_C          : in    std_logic;
pin_in_btn_E          : in    std_logic;
pin_in_btn_N          : in    std_logic;
pin_in_btn_S          : in    std_logic;
pin_in_btn_W          : in    std_logic;

pin_out_uart0_tx      : out   std_logic;
pin_in_uart0_rx       : in    std_logic;

pin_out_led           : out   std_logic_vector(7 downto 0);
pin_out_TP            : out   std_logic_vector(7 downto 0);

pin_inout_ftdi_d      : inout std_logic_vector(7 downto 0);
pin_out_ftdi_rd_n     : out   std_logic;
pin_out_ftdi_wr_n     : out   std_logic;
pin_in_ftdi_txe_n     : in    std_logic;
pin_in_ftdi_rxf_n     : in    std_logic;
pin_in_ftdi_pwren_n   : in    std_logic;

--------------------------------------------------
-- Reference clock
--------------------------------------------------
pin_in_refclk_n       : in    std_logic;
pin_in_refclk_p       : in    std_logic;

--------------------------------------------------
--SATA
--------------------------------------------------
pin_out_sata_txn      : out   std_logic_vector(1 downto 0);
pin_out_sata_txp      : out   std_logic_vector(1 downto 0);
pin_in_sata_rxn       : in    std_logic_vector(1 downto 0);
pin_in_sata_rxp       : in    std_logic_vector(1 downto 0);
pin_in_sata_clk_n     : in    std_logic_vector(0 downto 0);
pin_in_sata_clk_p     : in    std_logic_vector(0 downto 0)
);
end entity;

architecture struct of simple_test is

component s6_gt_mclk
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
end component;

component fpga_test_01
generic(
G_BLINK_T05   : integer:=10#125#; -- 1/2 периода мигания светодиода.(время в ms)
G_CLK_T05us   : integer:=10#1000# -- кол-во периодов частоты порта p_in_clk
                                  -- укладывающиеся в 1/2 периода 1us
);
port(
p_out_test_led : out   std_logic;--//мигание сведодиода
p_out_test_done: out   std_logic;--//сигнал переходи в '1' через 3 сек.

p_out_1us      : out   std_logic;
p_out_1ms      : out   std_logic;
-------------------------------
--System
-------------------------------
p_in_clk       : in    std_logic;
p_in_rst       : in    std_logic
);
end component;

signal i_sys_rst_cnt                    : std_logic_vector(5 downto 0):=(others=>'0');
signal i_sys_rst                        : std_logic;

signal i_cfg_rst                        : std_logic;
signal i_dev_adr                        : std_logic_vector(C_CFGPKT_DADR_M_BIT-C_CFGPKT_DADR_L_BIT downto 0);
signal i_cfg_adr                        : std_logic_vector(C_CFGPKT_RADR_M_BIT-C_CFGPKT_RADR_L_BIT downto 0);
signal i_cfg_adr_ld                     : std_logic;
signal i_cfg_adr_fifo                   : std_logic;
signal i_cfg_wd                         : std_logic;
signal i_cfg_rd                         : std_logic;
signal i_cfg_txd                        : std_logic_vector(15 downto 0);
signal i_cfg_rxd                        : std_logic_vector(15 downto 0);
signal i_cfg_txrdy                      : std_logic;
signal i_cfg_rxrdy                      : std_logic;
signal i_cfg_done                       : std_logic;
signal i_cfg_buf_rst                    : std_logic;
signal i_cfg_tstout                     : std_logic_vector(31 downto 0);

signal i_cfg_adr_cnt                    : std_logic_vector(7 downto 0);
signal i_reg0                           : std_logic_vector(i_cfg_rxd'range);
signal i_reg1                           : std_logic_vector(i_cfg_rxd'range);
signal i_reg2                           : std_logic_vector(i_cfg_rxd'range);
signal i_reg3                           : std_logic_vector(i_cfg_rxd'range);

signal i_hdd_gt_refclk150               : std_logic_vector(0 downto 0);
signal i_hdd_gt_refclkout               : std_logic;
signal g_hdd_gt_refclkout               : std_logic;

signal i_test01_led                     : std_logic;
signal i_test02_led                     : std_logic;
signal i_usr_refclk150                  : std_logic;
signal g_usr_refclk150                  : std_logic;
signal t_usr_refclk150                  : std_logic;


--//MAIN
begin

process(g_usr_refclk150)
begin
  if g_usr_refclk150'event and g_usr_refclk150 = '1' then
    if i_sys_rst_cnt(i_sys_rst_cnt'high) = '0' then
      i_sys_rst_cnt <= i_sys_rst_cnt + 1;
    end if;
  end if;
end process;

i_sys_rst <= i_sys_rst_cnt(i_sys_rst_cnt'high - 1);
i_cfg_rst <= i_sys_rst;

m_ibufds_refclk : IBUFDS port map (I => pin_in_refclk_p, IB => pin_in_refclk_n, O => i_usr_refclk150);
m_bufio2_refclk : BUFIO2 port map (I => i_usr_refclk150, DIVCLK => t_usr_refclk150, IOCLK => open, SERDESSTROBE => open );
m_bufg_refclk   : BUFG   port map (I => t_usr_refclk150, O => g_usr_refclk150);

gen_sata_gt : for i in 0 to 1-1 generate
  m_ibufds : IBUFDS port map(I  => pin_in_sata_clk_p(i), IB => pin_in_sata_clk_n(i), O => i_hdd_gt_refclk150(i));
end generate gen_sata_gt;

m_hdd : s6_gt_mclk
generic map(
G_SIM  => G_SIM
)
port map(
p_out_txn => pin_out_sata_txn(1 downto 0),
p_out_txp => pin_out_sata_txp(1 downto 0),
p_in_rxn  => pin_in_sata_rxn(1 downto 0),
p_in_rxp  => pin_in_sata_rxp(1 downto 0),
clkin     => i_hdd_gt_refclk150(0),
clkout    => i_hdd_gt_refclkout
);

m_bufg_gt_refclkout : BUFG port map (I => i_hdd_gt_refclkout, O => g_hdd_gt_refclkout);

m_satapll : PLL_ADV
generic map(
BANDWIDTH          => "OPTIMIZED",
CLKIN1_PERIOD      => 6.6, --150MHz
CLKIN2_PERIOD      => 6.6,
CLKOUT0_DIVIDE     => 1, --clk0 = ((150MHz * 4)/1) /1 = 150MHz
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
CLKFBOUT_MULT      => 4,
CLKFBOUT_PHASE     => 0.0,
REF_JITTER         => 0.005000
)
port map(
CLKFBIN          => i_satapll_clkfb,
CLKINSEL         => '1',
CLKIN1           => g_hdd_gt_refclkout,
CLKIN2           => '0',
DADDR            => (others => '0'),
DCLK             => '0',
DEN              => '0',
DI               => (others => '0'),
DWE              => '0',
REL              => '0',
RST              => i_sys_rst,
CLKFBDCM         => open,
CLKFBOUT         => i_satapll_clkfb,
CLKOUTDCM0       => open,
CLKOUTDCM1       => open,
CLKOUTDCM2       => open,
CLKOUTDCM3       => open,
CLKOUTDCM4       => open,
CLKOUTDCM5       => open,
CLKOUT0          => i_satapll_clkout(0),
CLKOUT1          => open,
CLKOUT2          => open,
CLKOUT3          => open,
CLKOUT4          => open,
CLKOUT5          => open,
DO               => open,
DRDY             => open,
LOCKED           => open,--i_usrpll_lock
);

pin_out_uart0_tx <= pin_in_uart0_rx;

pin_out_led_E<=pin_in_btn_E;
pin_out_led_N<=pin_in_btn_N;
pin_out_led_S<=pin_in_btn_S;
pin_out_led_W<=pin_in_btn_W;
pin_out_led_C<=pin_in_btn_C;

--HDD LEDs:
--SATA0 (На плате SATA1)
pin_out_led(2)<=i_test01_led;
pin_out_led(4)<=i_test02_led;
pin_out_TP(0) <=i_test01_led;
pin_out_TP(1) <=i_test02_led;

--SATA1 (На плате SATA0)
pin_out_led(3)<=i_test01_led;
pin_out_led(5)<=i_test02_led;
pin_out_TP(2) <=i_test01_led;
pin_out_TP(3) <=i_test02_led;

--SATA2 (На плате SATA3)
pin_out_led(0)<=i_test01_led;
pin_out_led(7)<=i_test02_led;
pin_out_TP(4) <=i_test01_led;
pin_out_TP(5) <=i_test02_led;

--SATA3 (На плате SATA2)
pin_out_led(1)<=i_test01_led;
pin_out_led(6)<=i_test02_led;
pin_out_TP(6) <=i_test01_led;
pin_out_TP(7) <=i_test02_led;


m_test01: fpga_test_01
generic map(
G_BLINK_T05   =>10#250#, -- 1/2 периода мигания светодиода.(время в ms)
G_CLK_T05us   =>10#75#   -- 05us - 150MHz
)
port map(
p_out_test_led => i_test01_led,
p_out_test_done=> open,

p_out_1us      => open,
p_out_1ms      => open,
-------------------------------
--System
-------------------------------
p_in_clk       => g_usr_refclk150,
p_in_rst       => i_sys_rst
);

m_test02: fpga_test_01
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
p_in_clk       => g_hdd_gt_refclkout,
p_in_rst       => i_sys_rst
);


m_test03: fpga_test_01
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
p_in_clk       => i_satapll_clkout(0),,
p_in_rst       => i_sys_rst
);


m_cfgdev : cfgdev_ftdi
port map(
-------------------------------
--Связь с FTDI
-------------------------------
p_inout_ftdi_d       => pin_inout_ftdi_d,
p_out_ftdi_rd_n      => pin_out_ftdi_rd_n,
p_out_ftdi_wr_n      => pin_out_ftdi_wr_n,
p_in_ftdi_txe_n      => pin_in_ftdi_txe_n,
p_in_ftdi_rxf_n      => pin_in_ftdi_rxf_n,
p_in_ftdi_pwren_n    => pin_in_ftdi_pwren_n,

-------------------------------
--
-------------------------------
p_out_module_rdy     => open,
p_out_module_error   => open,

-------------------------------
--Запись/Чтение конфигурационных параметров уст-ва
-------------------------------
p_out_cfg_dadr       => i_dev_adr,
p_out_cfg_radr       => i_cfg_adr,
p_out_cfg_radr_ld    => i_cfg_adr_ld,
p_out_cfg_radr_fifo  => i_cfg_adr_fifo,
p_out_cfg_wr         => i_cfg_wd,
p_out_cfg_rd         => i_cfg_rd,
p_out_cfg_txdata     => i_cfg_txd,
p_in_cfg_rxdata      => i_cfg_rxd,
p_in_cfg_txrdy       => '1',--i_cfg_txrdy,
p_in_cfg_rxrdy       => '1',--i_cfg_rxrdy,

p_out_cfg_done       => open,--i_cfg_done,
p_in_cfg_clk         => g_usr_refclk150,

-------------------------------
--Технологический
-------------------------------
p_in_tst             => (others=>'0'),
p_out_tst            => i_cfg_tstout,

-------------------------------
--System
-------------------------------
p_in_rst => i_cfg_rst
);


--//Счетчик адреса регистров
process(i_cfg_rst,g_usr_refclk150)
begin
  if i_cfg_rst='1' then
    i_cfg_adr_cnt<=(others=>'0');
  elsif g_usr_refclk150'event and g_usr_refclk150='1' then
    if i_cfg_adr_ld='1' and i_dev_adr=CONV_STD_LOGIC_VECTOR(0, i_dev_adr'length) then
      i_cfg_adr_cnt<=i_cfg_adr(7 downto 0);
    else
      if i_cfg_adr_fifo='0' and (i_cfg_wd='1' or i_cfg_rd='1') then
        i_cfg_adr_cnt<=i_cfg_adr_cnt+1;
      end if;
    end if;
  end if;
end process;

--//Запись регистров
process(i_cfg_rst,g_usr_refclk150)
begin
  if i_cfg_rst='1' then
    i_reg0<=(others=>'0');
    i_reg1<=(others=>'0');
    i_reg2<=(others=>'0');
    i_reg3<=(others=>'0');

  elsif g_usr_refclk150'event and g_usr_refclk150='1' then

    if i_cfg_wd='1' then
        if    i_cfg_adr_cnt=CONV_STD_LOGIC_VECTOR(0, i_cfg_adr_cnt'length) then i_reg0<=i_cfg_txd(i_reg0'high downto 0);
        elsif i_cfg_adr_cnt=CONV_STD_LOGIC_VECTOR(1, i_cfg_adr_cnt'length) then i_reg1<=i_cfg_txd(i_reg1'high downto 0);
        elsif i_cfg_adr_cnt=CONV_STD_LOGIC_VECTOR(2, i_cfg_adr_cnt'length) then i_reg2<=i_cfg_txd(i_reg2'high downto 0);
        elsif i_cfg_adr_cnt=CONV_STD_LOGIC_VECTOR(3, i_cfg_adr_cnt'length) then i_reg3<=i_cfg_txd(i_reg3'high downto 0);

        end if;
    end if;

  end if;
end process;

--//Чтение регистров
process(i_cfg_rst,g_usr_refclk150)
  variable rxd : std_logic_vector(i_cfg_rxd'range);
begin
  if i_cfg_rst='1' then
      rxd:=(others=>'0');
    i_cfg_rxd<=(others=>'0');
  elsif g_usr_refclk150'event and g_usr_refclk150='1' then
    rxd:=(others=>'0');

    if i_cfg_rd='1' then
        if    i_cfg_adr_cnt=CONV_STD_LOGIC_VECTOR(0, i_cfg_adr_cnt'length) then rxd:=EXT(i_reg0, rxd'length);
        elsif i_cfg_adr_cnt=CONV_STD_LOGIC_VECTOR(1, i_cfg_adr_cnt'length) then rxd:=EXT(i_reg1, rxd'length);
        elsif i_cfg_adr_cnt=CONV_STD_LOGIC_VECTOR(2, i_cfg_adr_cnt'length) then rxd:=EXT(i_reg2, rxd'length);
        elsif i_cfg_adr_cnt=CONV_STD_LOGIC_VECTOR(3, i_cfg_adr_cnt'length) then rxd:=EXT(i_reg3, rxd'length);

        end if;

        i_cfg_rxd<=rxd;

    end if;--//if p_in_cfg_rd='1' then
  end if;
end process;





end architecture;
