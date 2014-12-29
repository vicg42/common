-------------------------------------------------------------------------
-- Company     : Linkos
-- Engineer    : Golovachenko Victor
--
-- Create Date : 24.12.2014 15:07:49
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

--HEADER(0)/ Bit map:
constant C_CFGPKT_WR_BIT        : integer := 0;
constant C_CFGPKT_FIFO_BIT      : integer := 1; --0/1 - FIFO/Registers(auto increment)
constant C_CFGPKT_DADR_L_BIT    : integer := 2; --fpga device number
constant C_CFGPKT_DADR_M_BIT    : integer := 5;

--HEADER(1)/ Register adress
--HEADER(2)/ Data Length

constant C_CFGPKTH_DCOUNT : integer := 3;--packet header

--C_CFGPKT_WR_BIT/ Bit Map:
constant C_CFGPKT_WR            : std_logic := '0';
constant C_CFGPKT_RD            : std_logic := '1';


component cfgdev_host
generic(
G_DBG : string := "OFF";
G_HOST_DWIDTH : integer := 32;
G_CFG_DWIDTH : integer := 16
);
port(
-------------------------------
--HOST
-------------------------------
--host -> dev
p_in_htxbuf_di       : in   std_logic_vector(G_HOST_DWIDTH - 1 downto 0);
p_in_htxbuf_wr       : in   std_logic;
p_out_htxbuf_full    : out  std_logic;
p_out_htxbuf_empty   : out  std_logic;

--host <- dev
p_out_hrxbuf_do      : out  std_logic_vector(G_HOST_DWIDTH - 1 downto 0);
p_in_hrxbuf_rd       : in   std_logic;
p_out_hrxbuf_full    : out  std_logic;
p_out_hrxbuf_empty   : out  std_logic;

p_out_hirq           : out  std_logic;
p_in_hclk            : in   std_logic;

-------------------------------
--CFG
-------------------------------
p_out_cfg_dadr       : out    std_logic_vector(C_CFGPKT_DADR_M_BIT - C_CFGPKT_DADR_L_BIT downto 0); --dev number
p_out_cfg_radr       : out    std_logic_vector(G_CFG_DWIDTH - 1 downto 0); --adr register
p_out_cfg_radr_ld    : out    std_logic;
p_out_cfg_radr_fifo  : out    std_logic;
p_out_cfg_wr         : out    std_logic;
p_out_cfg_rd         : out    std_logic;
p_out_cfg_txdata     : out    std_logic_vector(G_CFG_DWIDTH - 1 downto 0);
p_in_cfg_txbuf_full  : in     std_logic;
p_in_cfg_txbuf_empty : in     std_logic;
p_in_cfg_rxdata      : in     std_logic_vector(G_CFG_DWIDTH - 1 downto 0);
p_in_cfg_rxbuf_full  : in     std_logic;
p_in_cfg_rxbuf_empty : in     std_logic;
p_out_cfg_done       : out    std_logic;
p_in_cfg_clk         : in     std_logic;

-------------------------------
--DBG
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
