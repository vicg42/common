-------------------------------------------------------------------------
-- Company     : Linkos
-- Engineer    : Golovachenko Victor
--
-- Create Date : 17.10.2011 11:30:12
-- Module Name : memory_ctrl_ch_wr_pkg
--
-- Description :
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

library work;
use work.axi_glob_pkg.all;

package memory_ctrl_ch_wr_pkg is

constant C_MEMCTRLCHWR_WRITE   : std_logic:='1';
constant C_MEMCTRLCHWR_READ    : std_logic:='0';

component memory_ctrl_ch_wr
generic(
G_AXI_ID_WIDTH   : integer:=4;
G_AXI_IDWR_NUM   : integer:=1;
G_AXI_IDRD_NUM   : integer:=2;
G_AXI_ADDR_WIDTH : integer:=32;
G_AXI_DATA_WIDTH : integer:=32;
G_MEM_BANK_M_BIT : integer:=29;
G_MEM_BANK_L_BIT : integer:=28
);
port(
-------------------------------
-- Конфигурирование
-------------------------------
p_in_cfg_mem_adr     : in    std_logic_vector(31 downto 0);
p_in_cfg_mem_trn_len : in    std_logic_vector(15 downto 0);
p_in_cfg_mem_dlen_rq : in    std_logic_vector(15 downto 0);
p_in_cfg_mem_wr      : in    std_logic;
p_in_cfg_mem_start   : in    std_logic;
p_out_cfg_mem_done   : out   std_logic;

-------------------------------
-- Связь с пользовательскими буферами
-------------------------------
--//usr_buf->mem
p_in_usr_txbuf_dout  : in    std_logic_vector(G_AXI_ADDR_WIDTH-1 downto 0);
p_out_usr_txbuf_rd   : out   std_logic;
p_in_usr_txbuf_empty : in    std_logic;

--//usr_buf<-mem
p_out_usr_rxbuf_din  : out   std_logic_vector(G_AXI_ADDR_WIDTH-1 downto 0);
p_out_usr_rxbuf_wd   : out   std_logic;
p_in_usr_rxbuf_full  : in    std_logic;

---------------------------------
-- Связь с memory_ctrl.vhd
---------------------------------
--//AXI Master Interface:
--//WRAddr Ports(usr_buf->mem)
p_out_maxi_awid      : out   std_logic_vector(C_AXI_ID_WIDTH_MAX-1 downto 0);
p_out_maxi_awaddr    : out   std_logic_vector(G_AXI_ADDR_WIDTH-1 downto 0);
p_out_maxi_awlen     : out   std_logic_vector(7 downto 0);--(15 downto 0);
p_out_maxi_awsize    : out   std_logic_vector(2 downto 0);
p_out_maxi_awburst   : out   std_logic_vector(1 downto 0);
p_out_maxi_awlock    : out   std_logic_vector(0 downto 0);--(1 downto 0);
p_out_maxi_awcache   : out   std_logic_vector(3 downto 0);
p_out_maxi_awprot    : out   std_logic_vector(2 downto 0);
p_out_maxi_awqos     : out   std_logic_vector(3 downto 0);
p_out_maxi_awvalid   : out   std_logic;
p_in_maxi_awready    : in    std_logic;
--//WRData Ports
p_out_maxi_wdata     : out   std_logic_vector(G_AXI_DATA_WIDTH-1 downto 0);
p_out_maxi_wstrb     : out   std_logic_vector(G_AXI_DATA_WIDTH/8-1 downto 0);
p_out_maxi_wlast     : out   std_logic;
p_out_maxi_wvalid    : out   std_logic;
p_in_maxi_wready     : in    std_logic;
--//WRResponse Ports
p_in_maxi_bid        : in    std_logic_vector(C_AXI_ID_WIDTH_MAX-1 downto 0);
p_in_maxi_bresp      : in    std_logic_vector(1 downto 0);
p_in_maxi_bvalid     : in    std_logic;
p_out_maxi_bready    : out   std_logic;

--//RDAddr Ports(usr_buf<-mem)
p_out_maxi_arid      : out   std_logic_vector(C_AXI_ID_WIDTH_MAX-1 downto 0);
p_out_maxi_araddr    : out   std_logic_vector(G_AXI_ADDR_WIDTH-1 downto 0);
p_out_maxi_arlen     : out   std_logic_vector(7 downto 0);--(15 downto 0);
p_out_maxi_arsize    : out   std_logic_vector(2 downto 0);
p_out_maxi_arburst   : out   std_logic_vector(1 downto 0);
p_out_maxi_arlock    : out   std_logic_vector(0 downto 0);--(1 downto 0);
p_out_maxi_arcache   : out   std_logic_vector(3 downto 0);
p_out_maxi_arprot    : out   std_logic_vector(2 downto 0);
p_out_maxi_arqos     : out   std_logic_vector(3 downto 0);
p_out_maxi_arvalid   : out   std_logic;
p_in_maxi_arready    : in    std_logic;
--//RDData Ports
p_in_maxi_rid        : in    std_logic_vector(C_AXI_ID_WIDTH_MAX-1 downto 0);
p_in_maxi_rdata      : in    std_logic_vector(G_AXI_DATA_WIDTH-1 downto 0);
p_in_maxi_rresp      : in    std_logic_vector(1 downto 0);
p_in_maxi_rlast      : in    std_logic;
p_in_maxi_rvalid     : in    std_logic;
p_out_maxi_rready    : out   std_logic;

-------------------------------
--Технологические сигналы
-------------------------------
p_in_tst             : in    std_logic_vector(31 downto 0);
p_out_tst            : out   std_logic_vector(31 downto 0);

-------------------------------
--System
-------------------------------
p_in_clk             : in    std_logic;
p_in_rst             : in    std_logic
);
end component;

end;
