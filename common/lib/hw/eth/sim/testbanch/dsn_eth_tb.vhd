-------------------------------------------------------------------------
-- Company     : Linkos
-- Engineer    : Golovachenko Victor
--
-- Create Date : 31.03.2011 19:15:18
-- Module Name : dsn_eth_tb
--
-- Description : Моделирование работы модуля dsn_hdd.vhd
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

use ieee.std_logic_textio.all;
use std.textio.all;

library unisim;
use unisim.vcomponents.all;

library work;
use work.vicg_common_pkg.all;
use work.prj_cfg.all;
--use work.prj_def.all;
--use work.cfgdev_pkg.all;
use work.eth_phypin_pkg.all;
use work.eth_pkg.all;
use work.dsn_eth_pkg.all;

entity dsn_eth_tb is
generic
(
C_PCFG_ETH_USE       : string :="ON";
G_DBG           : string :="ON";
G_SIM           : string :="ON"
);
--port(
----------------------------------------------------
----Ethernet
----------------------------------------------------
--pin_out_ethphy      : out   TEthPhyPinOUT;
--pin_in_ethphy       : in    TEthPhyPinIN
--);
end dsn_eth_tb;

architecture behavior of dsn_eth_tb is

component eth_bram_prm
port(
p_out_cfg_adr      : out  std_logic_vector(7 downto 0);
p_out_cfg_adr_ld   : out  std_logic;
p_out_cfg_adr_fifo : out  std_logic;

p_out_cfg_txdata   : out  std_logic_vector(15 downto 0);
p_out_cfg_wr       : out  std_logic;

p_in_clk  : in  std_logic;
p_in_rst  : in  std_logic
);
end component;

component host_vbuf
  PORT (
    rst : IN STD_LOGIC;
    wr_clk : IN STD_LOGIC;
    rd_clk : IN STD_LOGIC;
    din : IN STD_LOGIC_VECTOR(64 - 1 DOWNTO 0);
    wr_en : IN STD_LOGIC;
    rd_en : IN STD_LOGIC;
    dout : OUT STD_LOGIC_VECTOR(64 - 1 DOWNTO 0);
    full : OUT STD_LOGIC;
    empty : OUT STD_LOGIC;
    prog_full : OUT STD_LOGIC
  );
END component;

constant C_ETH_GT_REFCLK_PERIOD : TIME := 6.6 ns; --150MHz
constant C_ETH_GT_DRPCLK_PERIOD : TIME := 6.6*8 ns;
constant C_CFG_PERIOD           : TIME := 6.6*5 ns;

signal g_host_clk                 : std_logic;

signal pin_out_eth_gtp_txp        : std_logic_vector(1 downto 0);
signal pin_out_eth_gtp_txn        : std_logic_vector(1 downto 0);
signal pin_in_eth_gtp_rxp         : std_logic_vector(1 downto 0);
signal pin_in_eth_gtp_rxn         : std_logic_vector(1 downto 0);

signal i_cfgdev_rst               : std_logic;
signal i_cfgdev_adr               : std_logic_vector(7 downto 0);
signal i_cfgdev_adr_ld            : std_logic;
signal i_cfgdev_adr_fifo          : std_logic;
signal i_cfgdev_txdata            : std_logic_vector(15 downto 0);
signal i_dev_cfg_wd               : std_logic;--_vector(C_CFGDEV_COUNT-1 downto 0);
signal i_dev_cfg_rd               : std_logic;--_vector(C_CFGDEV_COUNT-1 downto 0);
signal i_dev_cfg_done             : std_logic;--_vector(C_CFGDEV_COUNT-1 downto 0);
signal i_eth_cfg_rxdata           : std_logic_vector(15 downto 0);


signal i_eth_refclk125                  : std_logic;
signal i_eth_rst                        : std_logic;
signal i_eth_out                        : TEthOUTs;
signal i_eth_in                         : TEthINs;
signal i_ethphy_out                     : TEthPhyOUT;
signal i_ethphy_in                      : TEthPhyIN;
--signal i_eth_tst_out                    : std_logic_vector(31 downto 0);
signal dbg_eth_out                      : TEthDBG;

signal i_eth_tst_out              : std_logic_vector(31 downto 0);

signal i_data                : std_logic_vector(63 downto 0);
signal i_data_wr             : std_logic;


--MAIN
begin


--Модуль настройки параметров работы dsn_eth.vhd
m_eth_prm : eth_bram_prm
port map(
p_out_cfg_adr      => i_cfgdev_adr,
p_out_cfg_adr_ld   => i_cfgdev_adr_ld,
p_out_cfg_adr_fifo => i_cfgdev_adr_fifo,

p_out_cfg_txdata   => i_cfgdev_txdata,
p_out_cfg_wr       => i_dev_cfg_wd,

p_in_clk  => g_host_clk,
p_in_rst  => i_eth_rst
);


m_eth : dsn_eth
generic map(
G_ETH.gtch_count_max  => C_PCFG_ETH_GTCH_COUNT_MAX,
G_ETH.usrbuf_dwidth   => 64,--32,
G_ETH.phy_dwidth      => 64,--8,
G_ETH.phy_select      => C_PCFG_ETH_PHY_SEL,
G_ETH.mac_length_swap => 1, --1/0 Поле Length/Type первый мл./ст. байт (0 - по стандарту!!! 1 - как в проекте Вереск)
G_MODULE_USE => "ON",--C_PCFG_ETH_USE,
G_DBG        => "ON",--C_PCFG_ETH_DBG,
G_SIM        => "ON" --G_SIM
)
port map
(
-------------------------------
--Конфигурирование
-------------------------------
p_in_cfg_clk          => g_host_clk,

p_in_cfg_adr          => i_cfgdev_adr,
p_in_cfg_adr_ld       => i_cfgdev_adr_ld,
p_in_cfg_adr_fifo     => i_cfgdev_adr_fifo,

p_in_cfg_txdata       => i_cfgdev_txdata,
p_in_cfg_wd           => i_dev_cfg_wd,

p_out_cfg_rxdata      => i_eth_cfg_rxdata,
p_in_cfg_rd           => i_dev_cfg_rd,

p_in_cfg_done         => i_dev_cfg_done,
p_in_cfg_rst          => i_eth_rst,

-------------------------------
--Связь с UsrBuf
-------------------------------
p_out_eth             => i_eth_out,
p_in_eth              => i_eth_in,

--------------------------------------------------
--ETH Driver
--------------------------------------------------
p_out_ethphy          => i_ethphy_out,
p_in_ethphy           => i_ethphy_in,

-------------------------------
--Технологический
-------------------------------
p_out_dbg         => open,
p_in_tst          => (others=>'0'),
p_out_tst         => i_eth_tst_out,

-------------------------------
--System
-------------------------------
p_in_rst          => i_eth_rst
);


gen_eth_gt_refclk : process
begin
  i_eth_refclk125 <= '0';
  wait for C_ETH_GT_REFCLK_PERIOD/2;
  i_eth_refclk125 <= '1';
  wait for C_ETH_GT_REFCLK_PERIOD/2;
end process;

gen_cfg_clk : process
begin
  g_host_clk <= '0';
  wait for C_CFG_PERIOD/2;
  g_host_clk <= '1';
  wait for C_CFG_PERIOD/2;
end process;

i_eth_rst <= '1','0' after 1 us;


--pin_out_ethphy <= i_ethphy_out.pin;
--i_ethphy_in.pin <= pin_in_ethphy;

i_ethphy_in.opt(C_ETHPHY_OPTIN_REFCLK_IODELAY_BIT) <= '0';--g_usrclk(0);
i_ethphy_in.opt(32) <= '0';--g_usrclk(6);
i_ethphy_in.opt(33) <= '0';
i_ethphy_in.opt(34) <= '0';--g_usrclk(2);--clkdrp


i_ethphy_in.clk<=i_eth_refclk125;


i_ethphy_in.pin.fiber.rxp <= i_ethphy_out.pin.fiber.txp;
i_ethphy_in.pin.fiber.rxn <= i_ethphy_out.pin.fiber.txn;

i_ethphy_in.pin.fiber.clk_p <= i_eth_refclk125;
i_ethphy_in.pin.fiber.clk_n <= not i_eth_refclk125;

i_ethphy_in.pin.fiber.sfp_sd <= '0';
i_ethphy_in.pin.fiber.sfp_txfault <= '0';

i_ethphy_in.clk <= i_eth_refclk125;

----//########################################
----//Main Ctrl
----//########################################
--gen_eth_ch : for i in 0 to 1 generate
--
--process
--begin
--
--i_eth_in(i).txbuf.dout(31 downto 0) <= (others=>'0');
--i_eth_in(i).txbuf.rd <= '0';
--i_eth_in(i).txbuf.empty <= '1';
--
--wait for 2 us;
--
--wait until rising_edge(i_ethphy_in.clk);
--i_eth_in(i).txbuf.dout(15 downto 0) <= CONV_STD_LOGIC_VECTOR(14, 16);
--i_eth_in(i).txbuf.dout(31 downto 16) <= CONV_STD_LOGIC_VECTOR(16#0201#, 16);
--i_eth_in(i).txbuf.empty <= '0';
--
--wait until rising_edge(i_ethphy_in.clk) and i_eth_out(i).txbuf.rd = '1';
--i_eth_in(i).txbuf.empty <= '1';
--
--wait until rising_edge(i_ethphy_in.clk);
--i_eth_in(i).txbuf.dout(31 downto 0) <= CONV_STD_LOGIC_VECTOR(16#06050403#, 32);
--i_eth_in(i).txbuf.empty <= '0';
--
--wait until rising_edge(i_ethphy_in.clk) and i_eth_out(i).txbuf.rd = '1';
--i_eth_in(i).txbuf.empty <= '1';
--
--wait until rising_edge(i_ethphy_in.clk);
--i_eth_in(i).txbuf.dout(31 downto 0) <= CONV_STD_LOGIC_VECTOR(16#0A090807#, 32);
--i_eth_in(i).txbuf.empty <= '0';
--
--wait until rising_edge(i_ethphy_in.clk) and i_eth_out(i).txbuf.rd = '1';
--i_eth_in(i).txbuf.empty <= '1';
--
--wait until rising_edge(i_ethphy_in.clk);
--i_eth_in(i).txbuf.dout(31 downto 0) <= CONV_STD_LOGIC_VECTOR(16#0E0D0C0B#, 32);
--i_eth_in(i).txbuf.empty <= '0';
--
--wait until rising_edge(i_ethphy_in.clk) and i_eth_out(i).txbuf.rd = '1';
--i_eth_in(i).txbuf.empty <= '1';
--
--wait until rising_edge(i_ethphy_in.clk);
--i_eth_in(i).txbuf.dout(31 downto 0) <= CONV_STD_LOGIC_VECTOR(16#0302010F#, 32);
--i_eth_in(i).txbuf.empty <= '0';
--
--wait until rising_edge(i_ethphy_in.clk) and i_eth_out(i).txbuf.rd = '1';
--i_eth_in(i).txbuf.empty <= '1';
--
--wait;
--
--end process;
--
--end generate;--gen_eth_ch



--//########################################
--//Main Ctrl
--//########################################
--gen_eth_ch : for i in 0 to C_PCFG_ETH_GTCH_COUNT_MAX - 1 generate
--
--process
--begin
--
--i_eth_in(i).txbuf.dout <= (others=>'0');
--i_eth_in(i).txbuf.rd <= '0';
--i_eth_in(i).txbuf.empty <= '1';
--
--wait for 12 us;
--
--wait until rising_edge(i_ethphy_in.clk);
--i_eth_in(i).txbuf.dout((8 * 2) - 1 downto 8 * 0) <= CONV_STD_LOGIC_VECTOR(16#0E#, 16);
--i_eth_in(i).txbuf.dout((8 * 4) - 1 downto 8 * 2) <= CONV_STD_LOGIC_VECTOR(16#0201#, 16);
--i_eth_in(i).txbuf.dout((8 * 6) - 1 downto 8 * 4) <= CONV_STD_LOGIC_VECTOR(16#0403#, 16);
--i_eth_in(i).txbuf.dout((8 * 8) - 1 downto 8 * 6) <= CONV_STD_LOGIC_VECTOR(16#0605#, 16);
--i_eth_in(i).txbuf.empty <= '0';
--
--wait until rising_edge(i_ethphy_in.clk) and i_eth_out(i).txbuf.rd = '1';
----i_eth_in(i).txbuf.empty <= '0';
--
----wait until rising_edge(i_ethphy_in.clk);
--i_eth_in(i).txbuf.dout((8 * 2) - 1 downto 8 * 0) <= CONV_STD_LOGIC_VECTOR(16#0807#, 16);
--i_eth_in(i).txbuf.dout((8 * 4) - 1 downto 8 * 2) <= CONV_STD_LOGIC_VECTOR(16#0A09#, 16);
--i_eth_in(i).txbuf.dout((8 * 6) - 1 downto 8 * 4) <= CONV_STD_LOGIC_VECTOR(16#0C0B#, 16);
--i_eth_in(i).txbuf.dout((8 * 8) - 1 downto 8 * 6) <= CONV_STD_LOGIC_VECTOR(16#0E0D#, 16);
--i_eth_in(i).txbuf.empty <= '0';
--
--wait until rising_edge(i_ethphy_in.clk) and i_eth_out(i).txbuf.rd = '1';
--i_eth_in(i).txbuf.empty <= '1';
--
----wait until rising_edge(i_ethphy_in.clk);
----i_eth_in(i).txbuf.dout(31 downto 0) <= CONV_STD_LOGIC_VECTOR(16#0A090807#, 32);
----i_eth_in(i).txbuf.empty <= '0';
----
----wait until rising_edge(i_ethphy_in.clk) and i_eth_out(i).txbuf.rd = '1';
----i_eth_in(i).txbuf.empty <= '1';
----
----wait until rising_edge(i_ethphy_in.clk);
----i_eth_in(i).txbuf.dout(31 downto 0) <= CONV_STD_LOGIC_VECTOR(16#0E0D0C0B#, 32);
----i_eth_in(i).txbuf.empty <= '0';
----
----wait until rising_edge(i_ethphy_in.clk) and i_eth_out(i).txbuf.rd = '1';
----i_eth_in(i).txbuf.empty <= '1';
----
----wait until rising_edge(i_ethphy_in.clk);
----i_eth_in(i).txbuf.dout(31 downto 0) <= CONV_STD_LOGIC_VECTOR(16#0302010F#, 32);
----i_eth_in(i).txbuf.empty <= '0';
----
----wait until rising_edge(i_ethphy_in.clk) and i_eth_out(i).txbuf.rd = '1';
----i_eth_in(i).txbuf.empty <= '1';
--
--wait;
--
--end process;
--
--end generate;--gen_eth_ch


process
begin
  i_data <= (others=>'0');
  i_data_wr <= '0';

  wait for 12 us;

  wait until i_ethphy_in.clk'event and i_ethphy_in.clk = '1';
  i_data_wr <= '1';
  i_data(31 downto 0)  <= CONV_STD_LOGIC_VECTOR(16#0201#, 16) & CONV_STD_LOGIC_VECTOR(16#02#, 16);
  i_data(63 downto 32) <= CONV_STD_LOGIC_VECTOR(16#0605#, 16) & CONV_STD_LOGIC_VECTOR(16#0403#, 16);

--  wait until i_clk'event and i_clk = '1';
--  i_data_wr <= '0';
--
--  wait for 200 ns;
--
--  wait until i_ethphy_in.clk'event and i_ethphy_in.clk = '1';
--  i_data_wr <= '1';
--  i_data(31 downto 0)  <= CONV_STD_LOGIC_VECTOR(16#0A09#, 16) & CONV_STD_LOGIC_VECTOR(16#0807#, 16);
--  i_data(63 downto 32) <= CONV_STD_LOGIC_VECTOR(16#0E0D#, 16) & CONV_STD_LOGIC_VECTOR(16#0C0B#, 16);
--
--  wait until i_clk'event and i_clk = '1';
--  i_data_wr <= '1';
--  i_data(31 downto 0)  <= CONV_STD_LOGIC_VECTOR(16#1211#, 16) & CONV_STD_LOGIC_VECTOR(16#100F#, 16);
--  i_data(63 downto 32) <= CONV_STD_LOGIC_VECTOR(16#1615#, 16) & CONV_STD_LOGIC_VECTOR(16#1413#, 16);
--
--  wait until i_clk'event and i_clk = '1';
--  i_data_wr <= '0';
--
--  wait for 200 ns;
--
--  wait until i_clk'event and i_clk = '1';
--  i_data_wr <= '1';
--  i_data(31 downto 0)  <= CONV_STD_LOGIC_VECTOR(16#1A19#, 16) & CONV_STD_LOGIC_VECTOR(16#1817#, 16);
--  i_data(63 downto 32) <= CONV_STD_LOGIC_VECTOR(16#1E1D#, 16) & CONV_STD_LOGIC_VECTOR(16#1C1B#, 16);
--
--  wait until i_clk'event and i_clk = '1';
--  i_data_wr <= '1';
--  i_data(31 downto 0)  <= CONV_STD_LOGIC_VECTOR(16#2221#, 16) & CONV_STD_LOGIC_VECTOR(16#201F#, 16);
--  i_data(63 downto 32) <= CONV_STD_LOGIC_VECTOR(16#2625#, 16) & CONV_STD_LOGIC_VECTOR(16#2423#, 16);
--
--  wait until i_clk'event and i_clk = '1';
--  i_data_wr <= '0';
--
--  wait for 200 ns;
--
--  wait until i_clk'event and i_clk = '1';
--  i_data_wr <= '1';
--  i_data(31 downto 0)  <= CONV_STD_LOGIC_VECTOR(16#2A29#, 16) & CONV_STD_LOGIC_VECTOR(16#2827#, 16);
--  i_data(63 downto 32) <= CONV_STD_LOGIC_VECTOR(16#2E2D#, 16) & CONV_STD_LOGIC_VECTOR(16#2C2B#, 16);

  wait until i_ethphy_in.clk'event and i_ethphy_in.clk = '1';
  i_data_wr <= '0';

  wait;
end process;


m_buf : host_vbuf
port map(
din => i_data,
wr_en => i_data_wr,
wr_clk => i_ethphy_in.clk,

rd_en => i_eth_out(0).txbuf.rd,
dout => i_eth_in(0).txbuf.dout,
rd_clk => i_ethphy_out.clk,

full => open,
empty => i_eth_in(0).txbuf.empty,
prog_full => open,

rst => i_eth_rst
);

--END MAIN
end;



