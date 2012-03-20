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

--//Кол-во элементов в заголовке пакета:
constant C_CFGPKT_HEADER_DCOUNT     : integer:=3;

--//HEADER(0)/ Bit map:
--constant C_CFGPKT_RESERV_BIT        : integer:=0 .. 5;
constant C_CFGPKT_FIFO_BIT          : integer:=6; --//Тип адресации 1 - FIFO/0 - Регистр(авто инкрементация адреса)
constant C_CFGPKT_WR_BIT            : integer:=7; --//Тип пакета - запись/чтение
constant C_CFGPKT_DADR_L_BIT        : integer:=8; --//Адрес модуля в проекте FPGA
constant C_CFGPKT_DADR_M_BIT        : integer:=15;

--//HEADER(1)/ Bit map:
constant C_CFGPKT_RADR_L_BIT        : integer:=0; --//Адрес начального регистра
constant C_CFGPKT_RADR_M_BIT        : integer:=15;

--//HEADER(2)/ Bit map:
constant C_CFGPKT_DLEN_L_BIT        : integer:=0; --//Кол-во данных для записи/чтения
constant C_CFGPKT_DLEN_M_BIT        : integer:=15;


--//C_CFGPKT_WR_BIT/ Bit Map:
constant C_CFGPKT_WR                : std_logic:='0';
constant C_CFGPKT_RD                : std_logic:='1';


component cfgdev_uart
generic(
G_BAUDCNT_VAL: integer:=64
);
port(
-------------------------------
--Связь с UART
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
--Запись/Чтение конфигурационных параметров уст-ва
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
--Технологический
-------------------------------
p_in_tst             : in     std_logic_vector(31 downto 0);
p_out_tst            : out    std_logic_vector(31 downto 0);

-------------------------------
--System
-------------------------------
p_in_rst             : in     std_logic
);
end component;


component cfgdev_ftdi
port(
-------------------------------
--Связь с FTDI
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
--Запись/Чтение конфигурационных параметров уст-ва
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
--Технологический
-------------------------------
p_in_tst             : in     std_logic_vector(31 downto 0);
p_out_tst            : out    std_logic_vector(31 downto 0);

-------------------------------
--System
-------------------------------
p_in_rst             : in     std_logic
);
end component;


component cfgdev_host
generic(
G_HOST_DWIDTH : integer:=32
);
port(
-------------------------------
--Связь с HOST
-------------------------------
p_out_host_rxrdy     : out  std_logic;
p_out_host_rxd       : out  std_logic_vector(G_HOST_DWIDTH-1 downto 0);
p_in_host_rd         : in   std_logic;

p_out_host_txrdy     : out  std_logic;
p_in_host_txd        : in   std_logic_vector(G_HOST_DWIDTH-1 downto 0);
p_in_host_wr         : in   std_logic;

p_out_host_irq       : out  std_logic;
p_in_host_clk        : in   std_logic;

-------------------------------
--
-------------------------------
p_out_module_rdy     : out    std_logic;
p_out_module_error   : out    std_logic;

-------------------------------
--Запись/Чтение конфигурационных параметров уст-ва
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
--Технологический
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

