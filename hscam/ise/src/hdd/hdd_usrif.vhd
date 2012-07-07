-------------------------------------------------------------------------
-- Company     : Linkos
-- Engineer    : Golovachenko Victor
--
-- Create Date : 13.06.2012 17:42:07
-- Module Name : hdd_usrif
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
use work.cfgdev_pkg.all;

entity hdd_usrif is
generic(
C_USRIF : string:="FTDI";
C_CFG_DBGCS : string:="OFF";
G_SIM   : string:="OFF"
);
port(
-------------------------------------------------
--Порт управления модулем + Статусы
--------------------------------------------------
--Управление HDD от camera.v
p_in_usr_clk        : in    std_logic;                    --частота тактирования p_in_usr_txd/rxd/tx_wr/rx_rd
p_in_usr_tx_wr      : in    std_logic;                    --строб записи txd
p_in_usr_rx_rd      : in    std_logic;                    --строб чтения rxd
p_in_usr_txd        : in    std_logic_vector(15 downto 0);
p_out_usr_rxd       : out   std_logic_vector(15 downto 0);
p_out_usr_status    : out   std_logic_vector(1  downto 0);--(0) - usr_rx_rdy
                                                          --(1) - usr_tx_rdy

-------------------------------
--связь с DSN_HDD.VHD
-------------------------------
p_out_cfg_adr       : out  std_logic_vector(15 downto 0);
p_out_cfg_adr_ld    : out  std_logic;
p_out_cfg_adr_fifo  : out  std_logic;

p_out_cfg_txdata    : out  std_logic_vector(15 downto 0);
p_out_cfg_wr        : out  std_logic;
p_in_cfg_txrdy      : in   std_logic;

p_in_cfg_rxdata     : in   std_logic_vector(15 downto 0);
p_out_cfg_rd        : out  std_logic;
p_in_cfg_rxrdy      : in   std_logic;

p_out_cfg_done      : out  std_logic;

p_in_cfg_clk        : in   std_logic;
p_in_cfg_rst        : in   std_logic;

-------------------------------
--Технологический
-------------------------------
p_in_tst            : in   std_logic_vector(31 downto 0);
p_out_tst           : out  std_logic_vector(31 downto 0)
);
end entity;

architecture struct of hdd_usrif is


--//MAIN
begin


m_host : cfgdev_host
generic map(
G_HOST_DWIDTH => 16,
G_DBG => C_CFG_DBGCS
)
port map(
-------------------------------
--Связь с Хостом
-------------------------------
p_out_host_rxrdy     => p_out_usr_status(0),--p_out_usr_rx_rdy,
p_out_host_rxd       => p_out_usr_rxd,
p_in_host_rd         => p_in_usr_rx_rd,

p_out_host_txrdy     => p_out_usr_status(1),--p_out_usr_tx_rdy,
p_in_host_txd        => p_in_usr_txd,
p_in_host_wr         => p_in_usr_tx_wr,

p_out_host_irq       => open,
p_in_host_clk        => p_in_usr_clk,

-------------------------------
--
-------------------------------
p_out_module_rdy     => open,
p_out_module_error   => open,

-------------------------------
--Запись/Чтение конфигурационных параметров уст-ва
-------------------------------
p_out_cfg_dadr       => open,
p_out_cfg_radr       => p_out_cfg_adr,
p_out_cfg_radr_ld    => p_out_cfg_adr_ld,
p_out_cfg_radr_fifo  => p_out_cfg_adr_fifo,
p_out_cfg_wr         => p_out_cfg_wr,
p_out_cfg_rd         => p_out_cfg_rd,
p_out_cfg_txdata     => p_out_cfg_txdata,
p_in_cfg_rxdata      => p_in_cfg_rxdata,
p_in_cfg_txrdy       => p_in_cfg_txrdy,
p_in_cfg_rxrdy       => p_in_cfg_rxrdy,

p_out_cfg_done       => p_out_cfg_done,
p_in_cfg_clk         => p_in_cfg_clk,

-------------------------------
--Технологический
-------------------------------
p_in_tst             => (others=>'0'),
p_out_tst            => p_out_tst,

-------------------------------
--System
-------------------------------
p_in_rst => p_in_cfg_rst
);



--END MAIN
end architecture;
