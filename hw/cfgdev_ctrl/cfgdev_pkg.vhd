-------------------------------------------------------------------------
-- Company     : Telemix
-- Engineer    : Golovachenko Victor
--
-- Create Date : 10/26/2007
-- Module Name : cfgdev_pkg
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

package cfgdev_pkg is

--//���-�� ��������� � ��������� ������:
constant C_CFGPKT_HEADER_DW_COUNT            : integer:=2;

--//HEADER(0)/ Bit map:
--constant C_CFGPKT_RESERV_BIT                 : integer:=0 .. 5;
constant C_CFGPKT_FIFO_BIT                   : integer:=6;
constant C_CFGPKT_WR_BIT                     : integer:=7;
constant C_CFGPKT_NUMDEV_LSB_BIT             : integer:=8;
constant C_CFGPKT_NUMDEV_MSB_BIT             : integer:=15;

--//HEADER(1)/ Bit map:
constant C_CFGPKT_NUMREG_LSB_BIT             : integer:=0;
constant C_CFGPKT_NUMREG_MSB_BIT             : integer:=7;
constant C_CFGPKT_DLEN_LSB_BIT               : integer:=8;
constant C_CFGPKT_DLEN_MSB_BIT               : integer:=15;


--//C_CFGPKT_WR_BIT/ Bit Map:
constant C_CFGPKT_ACT_WD                     : std_logic:='0';
constant C_CFGPKT_ACT_RD                     : std_logic:='1';


component cfgdev_txfifo
port
(
din         : IN  std_logic_vector(31 downto 0);
wr_en       : IN  std_logic;
wr_clk      : IN  std_logic;

dout        : OUT std_logic_vector(31 downto 0);
rd_en       : IN  std_logic;
rd_clk      : IN  std_logic;

empty       : OUT std_logic;
full        : OUT std_logic;

--clk         : IN  std_logic;
rst         : IN  std_logic
);
end component;

component cfgdev_rxfifo
port
(
din         : IN  std_logic_vector(31 downto 0);
wr_en       : IN  std_logic;
wr_clk      : IN  std_logic;

dout        : OUT std_logic_vector(31 downto 0);
rd_en       : IN  std_logic;
rd_clk      : IN  std_logic;

empty       : OUT std_logic;
full        : OUT std_logic;

--clk         : IN  std_logic;
rst         : IN  std_logic
);
end component;

component cfgdev
port
(
-------------------------------
--����� � ������
-------------------------------
p_in_host_clk         : in   std_logic;

p_out_module_rdy      : out  std_logic;
p_out_module_error    : out  std_logic;

p_out_host_rxbuf_rdy  : out  std_logic;
p_out_host_rxdata     : out  std_logic_vector(31 downto 0);
p_in_host_rd          : in  std_logic;

p_out_host_txbuf_rdy  : out  std_logic;
p_in_host_txdata      : in   std_logic_vector(31 downto 0);
p_in_host_wd          : in   std_logic;
p_in_host_txdata_rdy  : in   std_logic;

-------------------------------
--������/������ ���������������� ���������� ���-��
-------------------------------
p_out_dev_adr         : out  std_logic_vector(7 downto 0);
p_out_cfg_adr         : out  std_logic_vector(7 downto 0);
p_out_cfg_adr_ld      : out  std_logic;
p_out_cfg_adr_fifo    : out  std_logic;
p_out_cfg_wd          : out  std_logic;
p_out_cfg_rd          : out  std_logic;
p_out_cfg_txdata      : out  std_logic_vector(15 downto 0);
p_in_cfg_rxdata       : in   std_logic_vector(15 downto 0);

p_out_cfg_done        : out  std_logic;
p_out_cfg_rx_set_irq  : out  std_logic;
p_in_cfg_clk          : in   std_logic;

-------------------------------
--���������������
-------------------------------
p_out_tst             : out   std_logic_vector(31 downto 0);

-------------------------------
--System
-------------------------------
p_in_rst     : in    std_logic
);
end component;


component cfgdev_uart is
generic(
G_BAUDCNT_VAL: integer:=64
);
port
(
-------------------------------
--����� � UART
-------------------------------
p_out_uart_tx        : out    std_logic;
p_in_uart_rx         : in     std_logic;
p_in_uart_refclk     : in     std_logic;

-------------------------------
--
-------------------------------
p_out_module_rdy     : out    std_logic;
p_out_module_error   : out    std_logic;

-------------------------------
--������/������ ���������������� ���������� ���-��
-------------------------------
p_out_dev_adr        : out    std_logic_vector(7 downto 0);
p_out_cfg_adr        : out    std_logic_vector(7 downto 0);
p_out_cfg_adr_ld     : out    std_logic;
p_out_cfg_adr_fifo   : out    std_logic;
p_out_cfg_wd         : out    std_logic;
p_out_cfg_rd         : out    std_logic;
p_out_cfg_txdata     : out    std_logic_vector(15 downto 0);
p_in_cfg_rxdata      : in     std_logic_vector(15 downto 0);
p_in_cfg_txrdy       : in     std_logic;
p_in_cfg_rxrdy       : in     std_logic;

--p_out_cfg_rx_set_irq : out    std_logic;
p_out_cfg_done       : out    std_logic;
p_in_cfg_clk         : in     std_logic;

-------------------------------
--���������������
-------------------------------
p_in_tst             : in     std_logic_vector(31 downto 0);
p_out_tst            : out    std_logic_vector(31 downto 0);

-------------------------------
--System
-------------------------------
p_in_rst             : in     std_logic
);
end component;


component cfgdev_ftdi is
port
(
-------------------------------
--����� � FTDI
-------------------------------
p_inout_ftdi_d       : inout  std_logic_vector(7 downto 0);
p_out_ftdi_rd_n      : out    std_logic;
p_out_ftdi_wr_n      : out    std_logic;
p_in_ftdi_txe_n      : in     std_logic;
p_in_ftdi_rxf_n      : in     std_logic;
p_in_ftdi_pwren_n    : in     std_logic;

-------------------------------
--
-------------------------------
p_out_module_rdy     : out    std_logic;
p_out_module_error   : out    std_logic;

-------------------------------
--������/������ ���������������� ���������� ���-��
-------------------------------
p_out_dev_adr        : out    std_logic_vector(7 downto 0);
p_out_cfg_adr        : out    std_logic_vector(7 downto 0);
p_out_cfg_adr_ld     : out    std_logic;
p_out_cfg_adr_fifo   : out    std_logic;
p_out_cfg_wd         : out    std_logic;
p_out_cfg_rd         : out    std_logic;
p_out_cfg_txdata     : out    std_logic_vector(15 downto 0);
p_in_cfg_rxdata      : in     std_logic_vector(15 downto 0);
p_in_cfg_txrdy       : in     std_logic;
p_in_cfg_rxrdy       : in     std_logic;

--p_out_cfg_rx_set_irq : out    std_logic;
p_out_cfg_done       : out    std_logic;
p_in_cfg_clk         : in     std_logic;

-------------------------------
--���������������
-------------------------------
p_in_tst             : in     std_logic_vector(31 downto 0);
p_out_tst            : out    std_logic_vector(31 downto 0);

-------------------------------
--System
-------------------------------
p_in_rst             : in     std_logic
);
end component;


end cfgdev_pkg;


package body cfgdev_pkg is

end cfgdev_pkg;

