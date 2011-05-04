-------------------------------------------------------------------------
-- Company     : Telemix
-- Engineer    : Golovachenko Victor
--
-- Create Date : 03.05.2011 16:39:31
-- Module Name : dsn_ethg_pkg
--
-- Description :
--
-- Revision:
-- Revision 0.01 - File Created
--
-------------------------------------------------------------------------
library ieee;
use ieee.STD_LOGIC_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_arith.all;

library work;
use work.vicg_common_pkg.all;

package dsn_ethg_pkg is

component dsn_ethg
generic
(
G_MODULE_USE : string:="ON";
G_DBG        : string:="OFF";
G_SIM        : string:="OFF"
);
port
(
-------------------------------
-- Конфигурирование модуля dsn_ethg.vhd (host_clk domain)
-------------------------------
p_in_cfg_clk           : in   std_logic;                    --//

p_in_cfg_adr           : in   std_logic_vector(7 downto 0); --//
p_in_cfg_adr_ld        : in   std_logic;                    --//
p_in_cfg_adr_fifo      : in   std_logic;                    --//

p_in_cfg_txdata        : in   std_logic_vector(15 downto 0);--//
p_in_cfg_wd            : in   std_logic;                    --//

p_out_cfg_rxdata       : out  std_logic_vector(15 downto 0);--//
p_in_cfg_rd            : in   std_logic;                    --//

p_in_cfg_done          : in   std_logic;                    --//
p_in_cfg_rst           : in   std_logic;

-------------------------------
-- STATUS модуля dsn_ethg.vhd
-------------------------------
p_out_eth_rdy          : out  std_logic;                    --//
p_out_eth_error        : out  std_logic;                    --//
p_out_eth_gt_plllkdet  : out  std_logic;                    --//

p_out_sfp_tx_dis       : out  std_logic;                    --//SFP - TX DISABLE
p_in_sfp_sd            : in   std_logic;                    --//SFP - SD signal detect

-------------------------------
-- Связь с буферами модуля dsn_switch.vhd
-------------------------------
p_out_eth_rxbuf_din    : out  std_logic_vector(31 downto 0);
p_out_eth_rxbuf_wr     : out  std_logic;
p_in_eth_rxbuf_full    : in   std_logic;
p_out_eth_rxd_sof      : out  std_logic;
p_out_eth_rxd_eof      : out  std_logic;

p_in_eth_txbuf_dout    : in   std_logic_vector(31 downto 0);
p_out_eth_txbuf_rd     : out  std_logic;
p_in_eth_txbuf_empty   : in   std_logic;
p_in_eth_txd_rdy       : in   std_logic;

--------------------------------------------------
--ETH Driver
--------------------------------------------------
p_out_eth_gt_txp       : out   std_logic_vector(1 downto 0);
p_out_eth_gt_txn       : out   std_logic_vector(1 downto 0);
p_in_eth_gt_rxp        : in    std_logic_vector(1 downto 0);
p_in_eth_gt_rxn        : in    std_logic_vector(1 downto 0);

p_in_eth_gt_refclk     : in    std_logic;
p_out_eth_gt_refclkout : out   std_logic;
p_in_eth_gt_drpclk     : in    std_logic;

-------------------------------
--Технологический
-------------------------------
p_in_tst               : in    std_logic_vector(31 downto 0);
p_out_tst              : out   std_logic_vector(31 downto 0);

-------------------------------
--System
-------------------------------
p_in_rst               : in    std_logic
);
end component;


end dsn_ethg_pkg;


package body dsn_ethg_pkg is

end dsn_ethg_pkg;

