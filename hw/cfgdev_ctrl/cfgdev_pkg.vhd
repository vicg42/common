-------------------------------------------------------------------------
-- Company     : Linkos
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
use ieee.std_logic_1164.all;


package cfgdev_pkg is

--���-�� ��������� � ��������� ������:
constant C_CFGPKT_HEADER_DCOUNT     : integer:=3;

--HEADER(0)/ Bit map:
--constant C_CFGPKT_RESERV_BIT        : integer:=0 .. 5;
constant C_CFGPKT_FIFO_BIT          : integer:=6; --��� ��������� 1 - FIFO/0 - �������(���� ������������� ������)
constant C_CFGPKT_WR_BIT            : integer:=7; --��� ������ - ������/������
constant C_CFGPKT_DADR_L_BIT        : integer:=8; --����� ������ � ������� FPGA
constant C_CFGPKT_DADR_M_BIT        : integer:=15;

--HEADER(1)/ Bit map:
constant C_CFGPKT_RADR_L_BIT        : integer:=0; --����� ���������� ��������
constant C_CFGPKT_RADR_M_BIT        : integer:=15;

--HEADER(2)/ Bit map:
constant C_CFGPKT_DLEN_L_BIT        : integer:=0; --���-�� ������ ��� ������/������
constant C_CFGPKT_DLEN_M_BIT        : integer:=15;


--C_CFGPKT_WR_BIT/ Bit Map:
constant C_CFGPKT_WR                : std_logic:='0';
constant C_CFGPKT_RD                : std_logic:='1';


component cfgdev_uart
generic(
G_DBG : string:="OFF";
G_BAUDCNT_VAL: integer:=64
);
port(
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
p_out_cfg_dadr       : out    std_logic_vector(C_CFGPKT_DADR_M_BIT - C_CFGPKT_DADR_L_BIT downto 0);
p_out_cfg_radr       : out    std_logic_vector(C_CFGPKT_RADR_M_BIT - C_CFGPKT_RADR_L_BIT downto 0);
p_out_cfg_radr_ld    : out    std_logic;
p_out_cfg_radr_fifo  : out    std_logic;
p_out_cfg_wr         : out    std_logic;
p_out_cfg_rd         : out    std_logic;
p_out_cfg_txdata     : out    std_logic_vector(15 downto 0);
p_in_cfg_rxdata      : in     std_logic_vector(15 downto 0);
p_in_cfg_txrdy       : in     std_logic;
p_in_cfg_rxrdy       : in     std_logic;
p_out_cfg_done       : out    std_logic;
--p_in_cfg_irq         : in     std_logic;

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
end component cfgdev_uart;


component cfgdev_ftdi
generic(
G_DBG : string:="OFF"
);
port(
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
p_out_cfg_dadr       : out    std_logic_vector(C_CFGPKT_DADR_M_BIT - C_CFGPKT_DADR_L_BIT downto 0);
p_out_cfg_radr       : out    std_logic_vector(C_CFGPKT_RADR_M_BIT - C_CFGPKT_RADR_L_BIT downto 0);
p_out_cfg_radr_ld    : out    std_logic;
p_out_cfg_radr_fifo  : out    std_logic;
p_out_cfg_wr         : out    std_logic;
p_out_cfg_rd         : out    std_logic;
p_out_cfg_txdata     : out    std_logic_vector(15 downto 0);
p_in_cfg_rxdata      : in     std_logic_vector(15 downto 0);
p_in_cfg_txrdy       : in     std_logic;
p_in_cfg_rxrdy       : in     std_logic;
p_out_cfg_done       : out    std_logic;
--p_in_cfg_irq         : in     std_logic;

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
end component cfgdev_ftdi;


component cfgdev_host
generic(
G_DBG : string:="OFF";
G_HOST_DWIDTH_H2D : integer := 32;
G_HOST_DWIDTH_D2H : integer := 32;
C_FMODULE_DWIDTH  : integer := 16
);
port(
-------------------------------
--����� � HOST
-------------------------------
--host -> dev
p_in_htxbuf_di       : in   std_logic_vector(G_HOST_DWIDTH_H2D - 1 downto 0);
p_in_htxbuf_wr       : in   std_logic;
p_out_htxbuf_full    : out  std_logic;
p_out_htxbuf_empty   : out  std_logic;

--host <- dev
p_out_hrxbuf_do      : out  std_logic_vector(G_HOST_DWIDTH_H2D - 1 downto 0);
p_in_hrxbuf_rd       : in   std_logic;
p_out_hrxbuf_full    : out  std_logic;
p_out_hrxbuf_empty   : out  std_logic;

p_out_hirq           : out  std_logic;
p_out_herr           : out  std_logic;

p_in_hclk            : in   std_logic;

-------------------------------
--������/������ ���������������� ���������� ���-��
-------------------------------
p_out_cfg_dadr       : out    std_logic_vector(C_CFGPKT_DADR_M_BIT - C_CFGPKT_DADR_L_BIT downto 0);
p_out_cfg_radr       : out    std_logic_vector(C_CFGPKT_RADR_M_BIT - C_CFGPKT_RADR_L_BIT downto 0);
p_out_cfg_radr_ld    : out    std_logic;
p_out_cfg_radr_fifo  : out    std_logic;
p_out_cfg_wr         : out    std_logic;
p_out_cfg_rd         : out    std_logic;
p_out_cfg_txdata     : out    std_logic_vector(C_FMODULE_DWIDTH - 1 downto 0);
p_in_cfg_rxdata      : in     std_logic_vector(C_FMODULE_DWIDTH - 1 downto 0);
p_in_cfg_txrdy       : in     std_logic;
p_in_cfg_rxrdy       : in     std_logic;
p_out_cfg_done       : out    std_logic;
--p_in_cfg_irq         : in     std_logic;

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
end component cfgdev_host;

end package cfgdev_pkg;
