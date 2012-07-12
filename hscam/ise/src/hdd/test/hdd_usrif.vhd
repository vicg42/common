-------------------------------------------------------------------------
-- Company     : Linkos
-- Engineer    : Golovachenko Victor
--
-- Create Date : 13.06.2012 17:42:07
-- Module Name : hdd_usrif
--
-- ����������/�������� :
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
--���� ���������� ������� + �������
--------------------------------------------------
p_in_sel            : in    std_logic;

--���������� HDD �� camera.v
p_in_usr_clk        : in    std_logic;                    --������� ������������ p_in_usr_txd/rxd/tx_wr/rx_rd
p_in_usr_tx_wr      : in    std_logic;                    --����� ������ txd
p_in_usr_rx_rd      : in    std_logic;                    --����� ������ rxd
p_in_usr_txd        : in    std_logic_vector(15 downto 0);
p_out_usr_rxd       : out   std_logic_vector(15 downto 0);
p_out_usr_status    : out   std_logic_vector(1  downto 0);--(0) - usr_rx_rdy
                                                          --(1) - usr_tx_rdy
--���������� HDD ����� USB(FTDI)
p_inout_ftdi_d      : inout std_logic_vector(7 downto 0);
p_out_ftdi_rd_n     : out   std_logic;
p_out_ftdi_wr_n     : out   std_logic;
p_in_ftdi_txe_n     : in    std_logic;
p_in_ftdi_rxf_n     : in    std_logic;
p_in_ftdi_pwren_n   : in    std_logic;

-------------------------------
--����� � DSN_HDD.VHD
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
--���������������
-------------------------------
p_in_tst            : in   std_logic_vector(31 downto 0);
p_out_tst           : out  std_logic_vector(31 downto 0)
);
end entity;

architecture struct of hdd_usrif is

signal i_fcfg_tstout        : std_logic_vector(31 downto 0);
signal i_fcfg_adr           : std_logic_vector(C_CFGPKT_RADR_M_BIT-C_CFGPKT_RADR_L_BIT downto 0);
signal i_fcfg_adr_ld        : std_logic;
signal i_fcfg_adr_fifo      : std_logic;
signal i_fcfg_wr            : std_logic;
signal i_fcfg_rd            : std_logic;
signal i_fcfg_txd           : std_logic_vector(15 downto 0);
signal i_fcfg_done          : std_logic;

signal i_hcfg_tstout        : std_logic_vector(31 downto 0);
signal i_hcfg_adr           : std_logic_vector(C_CFGPKT_RADR_M_BIT-C_CFGPKT_RADR_L_BIT downto 0);
signal i_hcfg_adr_ld        : std_logic;
signal i_hcfg_adr_fifo      : std_logic;
signal i_hcfg_wr            : std_logic;
signal i_hcfg_rd            : std_logic;
signal i_hcfg_txd           : std_logic_vector(15 downto 0);
signal i_hcfg_done          : std_logic;


--//MAIN
begin



--######################################
--######################################
--######################################
gen_ftdi : if strcmp(C_USRIF,"FTDI") generate

m_ftdi : cfgdev_ftdi
generic map(
G_DBG => C_CFG_DBGCS
)
port map(
-------------------------------
--����� � FTDI
-------------------------------
p_inout_ftdi_d       => p_inout_ftdi_d,
p_out_ftdi_rd_n      => p_out_ftdi_rd_n,
p_out_ftdi_wr_n      => p_out_ftdi_wr_n,
p_in_ftdi_txe_n      => p_in_ftdi_txe_n,
p_in_ftdi_rxf_n      => p_in_ftdi_rxf_n,
p_in_ftdi_pwren_n    => p_in_ftdi_pwren_n,

-------------------------------
--
-------------------------------
p_out_module_rdy     => open,
p_out_module_error   => open,

-------------------------------
--������/������ ���������������� ���������� ���-��
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
--���������������
-------------------------------
p_in_tst             => (others=>'0'),
p_out_tst            => p_out_tst,

-------------------------------
--System
-------------------------------
p_in_rst => p_in_cfg_rst
);

p_out_usr_status(0)<=p_in_usr_rx_rd;
p_out_usr_status(1)<=p_in_usr_tx_wr;
p_out_usr_rxd<=p_in_usr_txd;
end generate gen_ftdi;


--######################################
--######################################
--######################################
gen_host : if strcmp(C_USRIF,"HOST") generate

m_host : cfgdev_host
generic map(
G_HOST_DWIDTH => 16,
G_DBG => C_CFG_DBGCS
)
port map(
-------------------------------
--����� � ������
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
--������/������ ���������������� ���������� ���-��
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
--���������������
-------------------------------
p_in_tst             => (others=>'0'),
p_out_tst            => p_out_tst,

-------------------------------
--System
-------------------------------
p_in_rst => p_in_cfg_rst
);

p_inout_ftdi_d<=(others=>'Z');
p_out_ftdi_rd_n<='1';
p_out_ftdi_wr_n<='1';
end generate gen_host;


--######################################
--######################################
--######################################
gen_all : if strcmp(C_USRIF,"ALL") generate

m_ftdi : cfgdev_ftdi
generic map(
G_DBG => C_CFG_DBGCS
)
port map(
-------------------------------
--����� � FTDI
-------------------------------
p_inout_ftdi_d       => p_inout_ftdi_d,
p_out_ftdi_rd_n      => p_out_ftdi_rd_n,
p_out_ftdi_wr_n      => p_out_ftdi_wr_n,
p_in_ftdi_txe_n      => p_in_ftdi_txe_n,
p_in_ftdi_rxf_n      => p_in_ftdi_rxf_n,
p_in_ftdi_pwren_n    => p_in_ftdi_pwren_n,

-------------------------------
--
-------------------------------
p_out_module_rdy     => open,
p_out_module_error   => open,

-------------------------------
--������/������ ���������������� ���������� ���-��
-------------------------------
p_out_cfg_dadr       => open,
p_out_cfg_radr       => i_fcfg_adr,
p_out_cfg_radr_ld    => i_fcfg_adr_ld,
p_out_cfg_radr_fifo  => i_fcfg_adr_fifo,
p_out_cfg_wr         => i_fcfg_wr,
p_out_cfg_rd         => i_fcfg_rd,
p_out_cfg_txdata     => i_fcfg_txd,
p_in_cfg_rxdata      => p_in_cfg_rxdata,
p_in_cfg_txrdy       => p_in_cfg_txrdy,
p_in_cfg_rxrdy       => p_in_cfg_rxrdy,

p_out_cfg_done       => i_fcfg_done,
p_in_cfg_clk         => p_in_cfg_clk,

-------------------------------
--���������������
-------------------------------
p_in_tst             => (others=>'0'),
p_out_tst            => i_fcfg_tstout,

-------------------------------
--System
-------------------------------
p_in_rst => p_in_cfg_rst
);

m_host : cfgdev_host
generic map(
G_HOST_DWIDTH => 16,
G_DBG => C_CFG_DBGCS
)
port map(
-------------------------------
--����� � ������
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
--������/������ ���������������� ���������� ���-��
-------------------------------
p_out_cfg_dadr       => open,
p_out_cfg_radr       => i_hcfg_adr,
p_out_cfg_radr_ld    => i_hcfg_adr_ld,
p_out_cfg_radr_fifo  => i_hcfg_adr_fifo,
p_out_cfg_wr         => i_hcfg_wr,
p_out_cfg_rd         => i_hcfg_rd,
p_out_cfg_txdata     => i_hcfg_txd,
p_in_cfg_rxdata      => p_in_cfg_rxdata,
p_in_cfg_txrdy       => p_in_cfg_txrdy,
p_in_cfg_rxrdy       => p_in_cfg_rxrdy,

p_out_cfg_done       => i_hcfg_done,
p_in_cfg_clk         => p_in_cfg_clk,

-------------------------------
--���������������
-------------------------------
p_in_tst             => (others=>'0'),
p_out_tst            => i_hcfg_tstout,

-------------------------------
--System
-------------------------------
p_in_rst => p_in_cfg_rst
);

p_out_cfg_adr     <=i_fcfg_adr      when p_in_sel='0' else i_hcfg_adr      ;
p_out_cfg_adr_ld  <=i_fcfg_adr_ld   when p_in_sel='0' else i_hcfg_adr_ld   ;
p_out_cfg_adr_fifo<=i_fcfg_adr_fifo when p_in_sel='0' else i_hcfg_adr_fifo ;
p_out_cfg_wr      <=i_fcfg_wr       when p_in_sel='0' else i_hcfg_wr       ;
p_out_cfg_rd      <=i_fcfg_rd       when p_in_sel='0' else i_hcfg_rd       ;
p_out_cfg_txdata  <=i_fcfg_txd      when p_in_sel='0' else i_hcfg_txd      ;

p_out_tst(31 downto 0) <=i_fcfg_tstout(31 downto 0) when p_in_sel='0' else i_hcfg_tstout(31 downto 0);
end generate gen_all;


--END MAIN
end architecture;
