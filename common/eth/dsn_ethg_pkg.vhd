-------------------------------------------------------------------------
-- Company     : Telemix
-- Engineer    : Golovachenko Victor
--
-- Create Date : 10/26/2007
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
--use work.vicg_common_pkg.all;
--use work.memory_ctrl_pkg.all;
--use work.prj_def.all;

package dsn_ethg_pkg is

component dsn_ethg
generic
(
G_MODULE_USE           : string:="ON"
);
port
(
-------------------------------
-- Конфигурирование модуля dsn_ethg.vhd (host_clk domain)
-------------------------------
p_in_cfg_clk          : in   std_logic;                      --//

p_in_cfg_adr          : in   std_logic_vector(7 downto 0);  --//
p_in_cfg_adr_ld       : in   std_logic;                     --//
p_in_cfg_adr_fifo     : in   std_logic;                     --//

p_in_cfg_txdata       : in   std_logic_vector(15 downto 0);  --//
p_in_cfg_wd           : in   std_logic;                      --//

p_out_cfg_rxdata      : out  std_logic_vector(15 downto 0);  --//
p_in_cfg_rd           : in   std_logic;                      --//

p_in_cfg_done         : in   std_logic;                      --//
p_in_cfg_rst          : in   std_logic;

-------------------------------
-- STATUS модуля dsn_ethg.vhd
-------------------------------
p_out_eth_rdy         : out  std_logic;                      --//
p_out_eth_error       : out  std_logic;                      --//
p_out_eth_gtp_plllkdet: out  std_logic;                      --//

-------------------------------
-- Связь с буферами модуля dsn_switch.vhd
-------------------------------
p_out_eth0_bufclk           : out  std_logic;

p_out_eth0_rxdata_rdy       : out  std_logic;
p_out_eth0_rxdata_sof       : out  std_logic;
p_out_eth0_rxbuf_din        : out  std_logic_vector(31 downto 0);
p_out_eth0_rxbuf_wd         : out  std_logic;
p_in_eth0_rxbuf_empty       : in   std_logic;
p_in_eth0_rxbuf_full        : in   std_logic;

p_in_eth0_txdata_rdy        : in   std_logic;
p_in_eth0_txbuf_dout        : in   std_logic_vector(31 downto 0);
p_out_eth0_txbuf_rd         : out  std_logic;
p_in_eth0_txbuf_empty       : in   std_logic;
p_in_eth0_txbuf_empty_almost: in   std_logic;

-------------------------------
-- EthG Drive
-------------------------------
--//Связь с внешиним приемопередатчиком
p_out_eth0_gtp_txp         : out   std_logic;
p_out_eth0_gtp_txn         : out   std_logic;
p_in_eth0_gtp_rxp          : in    std_logic;
p_in_eth0_gtp_rxn          : in    std_logic;

p_in_eth0_clkref           : in    std_logic;                      --//

p_out_eth1_gtp_txp         : out   std_logic;
p_out_eth1_gtp_txn         : out   std_logic;
p_in_eth1_gtp_rxp          : in    std_logic;
p_in_eth1_gtp_rxn          : in    std_logic;

p_out_sfp_tx_dis           : out   std_logic;
p_in_sfp_sd                : in    std_logic;

-------------------------------
--Технологический
-------------------------------
p_out_tst                  : out   std_logic_vector(31 downto 0);

-------------------------------
--System
-------------------------------
p_out_eth0_sync_acq_status : out   std_logic;
p_in_gtp_drp_clk           : in    std_logic;

p_in_rst        : in    std_logic
);
end component;


end dsn_ethg_pkg;


package body dsn_ethg_pkg is

end dsn_ethg_pkg;

