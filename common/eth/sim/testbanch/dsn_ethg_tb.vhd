-------------------------------------------------------------------------
-- Company     : Linkos
-- Engineer    : Golovachenko Victor
--
-- Create Date : 31.03.2011 19:15:18
-- Module Name : dsn_ethg_tb
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
use work.prj_def.all;
use work.dsn_ethg_pkg.all;

entity dsn_ethg_tb is
generic
(
C_USE_ETH       : string :="ON";
G_DBG           : string :="ON";
G_SIM           : string :="ON"
);
end dsn_ethg_tb;

architecture behavior of dsn_ethg_tb is

constant C_ETH_GT_REFCLK_PERIOD : TIME := 6.6 ns; --150MHz
constant C_ETH_GT_DRPCLK_PERIOD : TIME := 6.6*8 ns;
constant C_CFG_PERIOD           : TIME := 6.6*5 ns;

signal g_host_clk                 : std_logic;
signal i_eth0_gtp_refclk_125MHz   : std_logic;
signal g_ethg_swt_bufclk          : std_logic;
signal g_pciexp_gtp_refclkout     : std_logic;
signal i_eth_rst                  : std_logic;

signal pin_out_eth_gtp_txp        : std_logic_vector(1 downto 0);
signal pin_out_eth_gtp_txn        : std_logic_vector(1 downto 0);
signal pin_in_eth_gtp_rxp         : std_logic_vector(1 downto 0);
signal pin_in_eth_gtp_rxn         : std_logic_vector(1 downto 0);

signal i_cfgdev_rst               : std_logic;
signal i_cfgdev_adr               : std_logic_vector(7 downto 0);
signal i_cfgdev_adr_ld            : std_logic;
signal i_cfgdev_adr_fifo          : std_logic;
signal i_cfgdev_txdata            : std_logic_vector(15 downto 0);
signal i_dev_cfg_wd               : std_logic_vector(C_CFGDEV_COUNT-1 downto 0);
signal i_dev_cfg_rd               : std_logic_vector(C_CFGDEV_COUNT-1 downto 0);
signal i_dev_cfg_done             : std_logic_vector(C_CFGDEV_COUNT-1 downto 0);
signal i_eth_cfg_rxdata           : std_logic_vector(15 downto 0);

signal i_eth_module_rdy           : std_logic;                    --//
signal i_eth_module_error         : std_logic;                    --//
signal i_eth_module_gtp_plllkdet  : std_logic;                    --//

signal pin_out_sfp_tx_dis         : std_logic;                    --//SFP - TX DISABLE
signal pin_in_sfp_sd              : std_logic;                    --//SFP - SD signal detect

signal i_eth0_rxbuf_din           : std_logic_vector(31 downto 0);
signal i_eth0_rxbuf_wd            : std_logic;
signal i_eth0_rxbuf_full          : std_logic;
signal i_eth0_rxdata_sof          : std_logic;
signal i_eth0_rxdata_rdy          : std_logic;

signal i_eth0_txbuf_dout          : std_logic_vector(31 downto 0);
signal i_eth0_txbuf_rd            : std_logic;
signal i_eth0_txbuf_empty         : std_logic;
signal i_eth0_txdata_rdy          : std_logic;

signal i_eth_tst_out              : std_logic_vector(31 downto 0);


--MAIN
begin


--
--pin_in_eth_gtp_rxn<=(others=>'0');
--pin_in_eth_gtp_rxp<=(others=>'1');



m_eth : dsn_ethg
generic map
(
G_MODULE_USE => C_USE_ETH,
G_DBG        => G_DBG,
G_SIM        => G_SIM
)
port map
(
-------------------------------
-- Конфигурирование модуля dsn_ethg.vhd (host_clk domain)
-------------------------------
p_in_cfg_clk          => g_host_clk,

p_in_cfg_adr          => i_cfgdev_adr,
p_in_cfg_adr_ld       => i_cfgdev_adr_ld,
p_in_cfg_adr_fifo     => i_cfgdev_adr_fifo,

p_in_cfg_txdata       => i_cfgdev_txdata,
p_in_cfg_wd           => i_dev_cfg_wd(C_CFGDEV_ETH),

p_out_cfg_rxdata      => i_eth_cfg_rxdata,
p_in_cfg_rd           => i_dev_cfg_rd(C_CFGDEV_ETH),

p_in_cfg_done         => i_dev_cfg_done(C_CFGDEV_ETH),
p_in_cfg_rst          => i_cfgdev_rst,

-------------------------------
-- STATUS модуля dsn_ethg.vhd
-------------------------------
p_out_eth_rdy          => i_eth_module_rdy,
p_out_eth_error        => i_eth_module_error,
p_out_eth_gt_plllkdet  => i_eth_module_gtp_plllkdet,

p_out_sfp_tx_dis       => pin_out_sfp_tx_dis,
p_in_sfp_sd            => pin_in_sfp_sd,

-------------------------------
-- Связь с буферами модуля dsn_switch.vhd
-------------------------------
p_out_eth_rxbuf_din    => i_eth0_rxbuf_din,
p_out_eth_rxbuf_wr     => i_eth0_rxbuf_wd,
p_in_eth_rxbuf_full    => i_eth0_rxbuf_full,
p_out_eth_rxd_sof      => i_eth0_rxdata_sof,
p_out_eth_rxd_eof      => i_eth0_rxdata_rdy,

p_in_eth_txbuf_dout    => i_eth0_txbuf_dout,
p_out_eth_txbuf_rd     => i_eth0_txbuf_rd,
p_in_eth_txbuf_empty   => i_eth0_txbuf_empty,
p_in_eth_txd_rdy       => i_eth0_txdata_rdy,

--------------------------------------------------
--ETH Driver
--------------------------------------------------
p_out_eth_gt_txp       => pin_out_eth_gtp_txp,
p_out_eth_gt_txn       => pin_out_eth_gtp_txn,
p_in_eth_gt_rxp        => pin_out_eth_gtp_txp,--pin_in_eth_gtp_rxp,
p_in_eth_gt_rxn        => pin_out_eth_gtp_txn,--pin_in_eth_gtp_rxn,

p_in_eth_gt_refclk     => i_eth0_gtp_refclk_125MHz,
p_out_eth_gt_refclkout => g_ethg_swt_bufclk,
p_in_eth_gt_drpclk     => g_pciexp_gtp_refclkout,--g_hdd_dcm_clkin,--g_gtp_X0Y6_refclkout,--

-------------------------------
--Технологический
-------------------------------
p_in_tst               => "00000000000000000000000000000000",
p_out_tst              => i_eth_tst_out,

-------------------------------
--System
-------------------------------
p_in_rst               => i_eth_rst
);



gen_eth_gt_refclk : process
begin
  i_eth0_gtp_refclk_125MHz<='0';
  wait for C_ETH_GT_REFCLK_PERIOD/2;
  i_eth0_gtp_refclk_125MHz<='1';
  wait for C_ETH_GT_REFCLK_PERIOD/2;
end process;

gen_eth_gt_drpclk : process
begin
  g_pciexp_gtp_refclkout<='0';
  wait for C_ETH_GT_DRPCLK_PERIOD/2;
  g_pciexp_gtp_refclkout<='1';
  wait for C_ETH_GT_DRPCLK_PERIOD/2;
end process;

gen_cfg_clk : process
begin
  g_host_clk<='0';
  wait for C_CFG_PERIOD/2;
  g_host_clk<='1';
  wait for C_CFG_PERIOD/2;
end process;

i_eth_rst<='1','0' after 1 us;
i_cfgdev_rst<='1','0' after 1 us;



--//########################################
--//Main Ctrl
--//########################################



--END MAIN
end;



