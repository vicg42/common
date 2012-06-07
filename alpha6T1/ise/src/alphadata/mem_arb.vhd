-------------------------------------------------------------------------
-- Company     : Linkos
-- Engineer    : Golovachenko Victor
--
-- Create Date : 2010.09
-- Module Name : mem_arb
--
-- Назначение/Описание :
--  Арбитр достпупа к ОЗУ
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
use work.mem_glob_pkg.all;
use work.mem_wr_pkg.all;
use work.mem_ctrl_pkg.all;

entity mem_arb is
generic(
G_CH_COUNT   : integer:=4;
G_MEM_AWIDTH : integer:=32;
G_MEM_DWIDTH : integer:=32
);
port(
-------------------------------
--Связь с пользователями ОЗУ
-------------------------------
p_in_memch  : in   TMemINCh;
p_out_memch : out  TMemOUTCh;

-------------------------------
--Связь с mem_ctrl.vhd
-------------------------------
p_out_mem   : out   TMemIN;
p_in_mem    : in    TMemOUT;

-------------------------------
--Технологический
-------------------------------
p_in_tst    : in    std_logic_vector(31 downto 0);
p_out_tst   : out   std_logic_vector(31 downto 0);

-------------------------------
--System
-------------------------------
p_in_clk    : in    std_logic;
p_in_rst    : in    std_logic
);
end mem_arb;

architecture behavioral of mem_arb is

type TMemIDWR_Set is record
axiw_id : std_logic_vector(C_MEMWR_IDWIDTH_MAX-1 downto 0);
axir_id : std_logic_vector(C_MEMWR_IDWIDTH_MAX-1 downto 0);
end record;
Type TMemChIDWR_Set is array (0 to C_MEMCH_COUNT_MAX-1) of TMemIDWR_Set;
signal i_set_memch : TMemChIDWR_Set;

type TMemIDWR_Get is record
axiw_rid : std_logic_vector(C_AXIS_IDWIDTH-1 downto 0);
axir_rid : std_logic_vector(C_AXIS_IDWIDTH-1 downto 0);
end record;
Type TMemChIDWR_Get is array (0 to C_MEMCH_COUNT_MAX-1) of TMemIDWR_Get;
signal i_get_memch : TMemChIDWR_Get;

signal i_in_memch           : TMemINCh;
signal i_out_memch          : TMemOUTCh;
signal i_rstn               : std_logic;

--MAIN
begin

--//----------------------------------
--//Технологические сигналы
--//----------------------------------
p_out_tst(31 downto 0)<=(others=>'0');




--//--------------------------------------------------
--//Связь с контроллером памяти mem_ctrl.vhd
--//--------------------------------------------------
i_rstn<=not p_in_rst;

gen_chcount_1 : if G_CH_COUNT=1 generate

p_out_mem <= p_in_memch(0);
p_out_memch(0) <= p_in_mem;

end generate gen_chcount_1;


gen_chcount_3 : if G_CH_COUNT=3 generate

gen_idch : for i in 0 to G_CH_COUNT-1 generate
i_set_memch(i).axiw_id<=CONV_STD_LOGIC_VECTOR(2*i+0, i_set_memch(i).axiw_id'length);
i_set_memch(i).axir_id<=CONV_STD_LOGIC_VECTOR(2*i+1, i_set_memch(i).axir_id'length);

--Response ID
p_out_memch(i).axiw.rid<=EXT(i_get_memch(i).axiw_rid, p_out_memch(i).axiw.rid'length);
p_out_memch(i).axir.rid<=EXT(i_get_memch(i).axir_rid, p_out_memch(i).axir.rid'length);
end generate gen_idch;

m_arb: mem_achcount3
port map(
INTERCONNECT_ACLK    => p_in_clk,                                           --: IN STD_LOGIC;
INTERCONNECT_ARESETN => i_rstn,                                             --: IN STD_LOGIC;

S00_AXI_ARESET_OUT_N => p_out_memch(0).rstn,                                --: OUT STD_LOGIC;
S00_AXI_ACLK         => p_in_memch (0).clk,                                 --: IN STD_LOGIC;
S00_AXI_AWID         => i_set_memch(0).axiw_id(C_AXIS_IDWIDTH-1 downto 0),  --: IN STD_LOGIC_VECTOR(3 DOWNTO 0);
S00_AXI_AWADDR       => p_in_memch (0).axiw.adr(G_MEM_AWIDTH-1 downto 0),   --: IN STD_LOGIC_VECTOR(31 DOWNTO 0);
S00_AXI_AWLEN        => p_in_memch (0).axiw.trnlen(7 downto 0),             --: IN STD_LOGIC_VECTOR(7 DOWNTO 0);
S00_AXI_AWSIZE       => p_in_memch (0).axiw.dbus(2 downto 0),               --: IN STD_LOGIC_VECTOR(2 DOWNTO 0);
S00_AXI_AWBURST      => p_in_memch (0).axiw.burst(1 downto 0),              --: IN STD_LOGIC_VECTOR(1 DOWNTO 0);
S00_AXI_AWLOCK       => p_in_memch (0).axiw.lock(0),                        --: IN STD_LOGIC;
S00_AXI_AWCACHE      => p_in_memch (0).axiw.cache(3 downto 0),              --: IN STD_LOGIC_VECTOR(3 DOWNTO 0);
S00_AXI_AWPROT       => p_in_memch (0).axiw.prot(2 downto 0),               --: IN STD_LOGIC_VECTOR(2 DOWNTO 0);
S00_AXI_AWQOS        => p_in_memch (0).axiw.qos(3 downto 0),                --: IN STD_LOGIC_VECTOR(3 DOWNTO 0);
S00_AXI_AWVALID      => p_in_memch (0).axiw.avalid,                         --: IN STD_LOGIC;
S00_AXI_AWREADY      => p_out_memch(0).axiw.aready,                         --: OUT STD_LOGIC;
S00_AXI_WDATA        => p_in_memch (0).axiw.data(G_MEM_DWIDTH-1 downto 0),  --: IN STD_LOGIC_VECTOR(31 DOWNTO 0);
S00_AXI_WSTRB        => p_in_memch (0).axiw.dbe(G_MEM_DWIDTH/8-1 downto 0), --: IN STD_LOGIC_VECTOR(3 DOWNTO 0);
S00_AXI_WLAST        => p_in_memch (0).axiw.dlast,                          --: IN STD_LOGIC;
S00_AXI_WVALID       => p_in_memch (0).axiw.dvalid,                         --: IN STD_LOGIC;
S00_AXI_WREADY       => p_out_memch(0).axiw.wready,                         --: OUT STD_LOGIC;
S00_AXI_BID          => i_get_memch(0).axiw_rid(C_AXIS_IDWIDTH-1 downto 0), --: OUT STD_LOGIC_VECTOR(3 DOWNTO 0)
S00_AXI_BRESP        => p_out_memch(0).axiw.resp(1 downto 0),               --: OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
S00_AXI_BVALID       => p_out_memch(0).axiw.rvalid,                         --: OUT STD_LOGIC;
S00_AXI_BREADY       => p_in_memch (0).axiw.rready,                         --: IN STD_LOGIC;
S00_AXI_ARID         => i_set_memch(0).axir_id(C_AXIS_IDWIDTH-1 downto 0),  --: IN STD_LOGIC_VECTOR(3 DOWNTO 0);
S00_AXI_ARADDR       => p_in_memch (0).axir.adr(G_MEM_AWIDTH-1 downto 0),   --: IN STD_LOGIC_VECTOR(31 DOWNTO 0);
S00_AXI_ARLEN        => p_in_memch (0).axir.trnlen(7 downto 0),             --: IN STD_LOGIC_VECTOR(7 DOWNTO 0);
S00_AXI_ARSIZE       => p_in_memch (0).axir.dbus(2 downto 0),               --: IN STD_LOGIC_VECTOR(2 DOWNTO 0);
S00_AXI_ARBURST      => p_in_memch (0).axir.burst(1 downto 0),              --: IN STD_LOGIC_VECTOR(1 DOWNTO 0);
S00_AXI_ARLOCK       => p_in_memch (0).axir.lock(0),                        --: IN STD_LOGIC;
S00_AXI_ARCACHE      => p_in_memch (0).axir.cache(3 downto 0),              --: IN STD_LOGIC_VECTOR(3 DOWNTO 0);
S00_AXI_ARPROT       => p_in_memch (0).axir.prot(2 downto 0),               --: IN STD_LOGIC_VECTOR(2 DOWNTO 0);
S00_AXI_ARQOS        => p_in_memch (0).axir.qos(3 downto 0),                --: IN STD_LOGIC_VECTOR(3 DOWNTO 0);
S00_AXI_ARVALID      => p_in_memch (0).axir.avalid,                         --: IN STD_LOGIC;
S00_AXI_ARREADY      => p_out_memch(0).axir.aready,                         --: OUT STD_LOGIC;
S00_AXI_RID          => i_get_memch(0).axir_rid(C_AXIS_IDWIDTH-1 downto 0), --: OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
S00_AXI_RDATA        => p_out_memch(0).axir.data(G_MEM_DWIDTH-1 downto 0),  --: OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
S00_AXI_RRESP        => p_out_memch(0).axir.resp(1 downto 0),               --: OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
S00_AXI_RLAST        => p_out_memch(0).axir.dlast,                          --: OUT STD_LOGIC;
S00_AXI_RVALID       => p_out_memch(0).axir.dvalid,                         --: OUT STD_LOGIC;
S00_AXI_RREADY       => p_in_memch (0).axir.rready,                         --: IN STD_LOGIC;

S01_AXI_ARESET_OUT_N => p_out_memch(1).rstn,                                --: OUT STD_LOGIC;
S01_AXI_ACLK         => p_in_memch (1).clk,                                 --: IN STD_LOGIC;
S01_AXI_AWID         => i_set_memch(1).axiw_id(C_AXIS_IDWIDTH-1 downto 0),  --: IN STD_LOGIC_VECTOR(3 DOWNTO 0);
S01_AXI_AWADDR       => p_in_memch (1).axiw.adr(G_MEM_AWIDTH-1 downto 0),   --: IN STD_LOGIC_VECTOR(31 DOWNTO 0);
S01_AXI_AWLEN        => p_in_memch (1).axiw.trnlen(7 downto 0),             --: IN STD_LOGIC_VECTOR(7 DOWNTO 0);
S01_AXI_AWSIZE       => p_in_memch (1).axiw.dbus(2 downto 0),               --: IN STD_LOGIC_VECTOR(2 DOWNTO 0);
S01_AXI_AWBURST      => p_in_memch (1).axiw.burst(1 downto 0),              --: IN STD_LOGIC_VECTOR(1 DOWNTO 0);
S01_AXI_AWLOCK       => p_in_memch (1).axiw.lock(0),                        --: IN STD_LOGIC;
S01_AXI_AWCACHE      => p_in_memch (1).axiw.cache(3 downto 0),              --: IN STD_LOGIC_VECTOR(3 DOWNTO 0);
S01_AXI_AWPROT       => p_in_memch (1).axiw.prot(2 downto 0),               --: IN STD_LOGIC_VECTOR(2 DOWNTO 0);
S01_AXI_AWQOS        => p_in_memch (1).axiw.qos(3 downto 0),                --: IN STD_LOGIC_VECTOR(3 DOWNTO 0);
S01_AXI_AWVALID      => p_in_memch (1).axiw.avalid,                         --: IN STD_LOGIC;
S01_AXI_AWREADY      => p_out_memch(1).axiw.aready,                         --: OUT STD_LOGIC;
S01_AXI_WDATA        => p_in_memch (1).axiw.data(G_MEM_DWIDTH-1 downto 0),  --: IN STD_LOGIC_VECTOR(31 DOWNTO 0);
S01_AXI_WSTRB        => p_in_memch (1).axiw.dbe(G_MEM_DWIDTH/8-1 downto 0), --: IN STD_LOGIC_VECTOR(3 DOWNTO 0);
S01_AXI_WLAST        => p_in_memch (1).axiw.dlast,                          --: IN STD_LOGIC;
S01_AXI_WVALID       => p_in_memch (1).axiw.dvalid,                         --: IN STD_LOGIC;
S01_AXI_WREADY       => p_out_memch(1).axiw.wready,                         --: OUT STD_LOGIC;
S01_AXI_BID          => i_get_memch(1).axiw_rid(C_AXIS_IDWIDTH-1 downto 0), --: OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
S01_AXI_BRESP        => p_out_memch(1).axiw.resp(1 downto 0),               --: OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
S01_AXI_BVALID       => p_out_memch(1).axiw.rvalid,                         --: OUT STD_LOGIC;
S01_AXI_BREADY       => p_in_memch (1).axiw.rready,                         --: IN STD_LOGIC;
S01_AXI_ARID         => i_set_memch(1).axir_id(C_AXIS_IDWIDTH-1 downto 0),  --: IN STD_LOGIC_VECTOR(3 DOWNTO 0);
S01_AXI_ARADDR       => p_in_memch (1).axir.adr(G_MEM_AWIDTH-1 downto 0),   --: IN STD_LOGIC_VECTOR(31 DOWNTO 0);
S01_AXI_ARLEN        => p_in_memch (1).axir.trnlen(7 downto 0),             --: IN STD_LOGIC_VECTOR(7 DOWNTO 0);
S01_AXI_ARSIZE       => p_in_memch (1).axir.dbus(2 downto 0),               --: IN STD_LOGIC_VECTOR(2 DOWNTO 0);
S01_AXI_ARBURST      => p_in_memch (1).axir.burst(1 downto 0),              --: IN STD_LOGIC_VECTOR(1 DOWNTO 0);
S01_AXI_ARLOCK       => p_in_memch (1).axir.lock(0),                        --: IN STD_LOGIC;
S01_AXI_ARCACHE      => p_in_memch (1).axir.cache(3 downto 0),              --: IN STD_LOGIC_VECTOR(3 DOWNTO 0);
S01_AXI_ARPROT       => p_in_memch (1).axir.prot(2 downto 0),               --: IN STD_LOGIC_VECTOR(2 DOWNTO 0);
S01_AXI_ARQOS        => p_in_memch (1).axir.qos(3 downto 0),                --: IN STD_LOGIC_VECTOR(3 DOWNTO 0);
S01_AXI_ARVALID      => p_in_memch (1).axir.avalid,                         --: IN STD_LOGIC;
S01_AXI_ARREADY      => p_out_memch(1).axir.aready,                         --: OUT STD_LOGIC;
S01_AXI_RID          => i_get_memch(1).axir_rid(C_AXIS_IDWIDTH-1 downto 0), --: OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
S01_AXI_RDATA        => p_out_memch(1).axir.data(G_MEM_DWIDTH-1 downto 0),  --: OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
S01_AXI_RRESP        => p_out_memch(1).axir.resp(1 downto 0),               --: OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
S01_AXI_RLAST        => p_out_memch(1).axir.dlast,                          --: OUT STD_LOGIC;
S01_AXI_RVALID       => p_out_memch(1).axir.dvalid,                         --: OUT STD_LOGIC;
S01_AXI_RREADY       => p_in_memch (1).axir.rready,                         --: IN STD_LOGIC;

S02_AXI_ARESET_OUT_N => p_out_memch(2).rstn,                                --: OUT STD_LOGIC;
S02_AXI_ACLK         => p_in_memch (2).clk,                                 --: IN STD_LOGIC;
S02_AXI_AWID         => i_set_memch(2).axiw_id(C_AXIS_IDWIDTH-1 downto 0),  --: IN STD_LOGIC_VECTOR(3 DOWNTO 0);
S02_AXI_AWADDR       => p_in_memch (2).axiw.adr(G_MEM_AWIDTH-1 downto 0),   --: IN STD_LOGIC_VECTOR(31 DOWNTO 0);
S02_AXI_AWLEN        => p_in_memch (2).axiw.trnlen(7 downto 0),             --: IN STD_LOGIC_VECTOR(7 DOWNTO 0);
S02_AXI_AWSIZE       => p_in_memch (2).axiw.dbus(2 downto 0),               --: IN STD_LOGIC_VECTOR(2 DOWNTO 0);
S02_AXI_AWBURST      => p_in_memch (2).axiw.burst(1 downto 0),              --: IN STD_LOGIC_VECTOR(1 DOWNTO 0);
S02_AXI_AWLOCK       => p_in_memch (2).axiw.lock(0),                        --: IN STD_LOGIC;
S02_AXI_AWCACHE      => p_in_memch (2).axiw.cache(3 downto 0),              --: IN STD_LOGIC_VECTOR(3 DOWNTO 0);
S02_AXI_AWPROT       => p_in_memch (2).axiw.prot(2 downto 0),               --: IN STD_LOGIC_VECTOR(2 DOWNTO 0);
S02_AXI_AWQOS        => p_in_memch (2).axiw.qos(3 downto 0),                --: IN STD_LOGIC_VECTOR(3 DOWNTO 0);
S02_AXI_AWVALID      => p_in_memch (2).axiw.avalid,                         --: IN STD_LOGIC;
S02_AXI_AWREADY      => p_out_memch(2).axiw.aready,                         --: OUT STD_LOGIC;
S02_AXI_WDATA        => p_in_memch (2).axiw.data(G_MEM_DWIDTH-1 downto 0),  --: IN STD_LOGIC_VECTOR(31 DOWNTO 0);
S02_AXI_WSTRB        => p_in_memch (2).axiw.dbe(G_MEM_DWIDTH/8-1 downto 0), --: IN STD_LOGIC_VECTOR(3 DOWNTO 0);
S02_AXI_WLAST        => p_in_memch (2).axiw.dlast,                          --: IN STD_LOGIC;
S02_AXI_WVALID       => p_in_memch (2).axiw.dvalid,                         --: IN STD_LOGIC;
S02_AXI_WREADY       => p_out_memch(2).axiw.wready,                         --: OUT STD_LOGIC;
S02_AXI_BID          => i_get_memch(2).axiw_rid(C_AXIS_IDWIDTH-1 downto 0), --: OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
S02_AXI_BRESP        => p_out_memch(2).axiw.resp(1 downto 0),               --: OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
S02_AXI_BVALID       => p_out_memch(2).axiw.rvalid,                         --: OUT STD_LOGIC;
S02_AXI_BREADY       => p_in_memch (2).axiw.rready,                         --: IN STD_LOGIC;
S02_AXI_ARID         => i_set_memch(2).axir_id(C_AXIS_IDWIDTH-1 downto 0),  --: IN STD_LOGIC_VECTOR(3 DOWNTO 0);
S02_AXI_ARADDR       => p_in_memch (2).axir.adr(G_MEM_AWIDTH-1 downto 0),   --: IN STD_LOGIC_VECTOR(31 DOWNTO 0);
S02_AXI_ARLEN        => p_in_memch (2).axir.trnlen(7 downto 0),             --: IN STD_LOGIC_VECTOR(7 DOWNTO 0);
S02_AXI_ARSIZE       => p_in_memch (2).axir.dbus(2 downto 0),               --: IN STD_LOGIC_VECTOR(2 DOWNTO 0);
S02_AXI_ARBURST      => p_in_memch (2).axir.burst(1 downto 0),              --: IN STD_LOGIC_VECTOR(1 DOWNTO 0);
S02_AXI_ARLOCK       => p_in_memch (2).axir.lock(0),                        --: IN STD_LOGIC;
S02_AXI_ARCACHE      => p_in_memch (2).axir.cache(3 downto 0),              --: IN STD_LOGIC_VECTOR(3 DOWNTO 0);
S02_AXI_ARPROT       => p_in_memch (2).axir.prot(2 downto 0),               --: IN STD_LOGIC_VECTOR(2 DOWNTO 0);
S02_AXI_ARQOS        => p_in_memch (2).axir.qos(3 downto 0),                --: IN STD_LOGIC_VECTOR(3 DOWNTO 0);
S02_AXI_ARVALID      => p_in_memch (2).axir.avalid,                         --: IN STD_LOGIC;
S02_AXI_ARREADY      => p_out_memch(2).axir.aready,                         --: OUT STD_LOGIC;
S02_AXI_RID          => i_get_memch(2).axir_rid(C_AXIS_IDWIDTH-1 downto 0), --: OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
S02_AXI_RDATA        => p_out_memch(2).axir.data(G_MEM_DWIDTH-1 downto 0),  --: OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
S02_AXI_RRESP        => p_out_memch(2).axir.resp(1 downto 0),               --: OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
S02_AXI_RLAST        => p_out_memch(2).axir.dlast,                          --: OUT STD_LOGIC;
S02_AXI_RVALID       => p_out_memch(2).axir.dvalid,                         --: OUT STD_LOGIC;
S02_AXI_RREADY       => p_in_memch (2).axir.rready,                         --: IN STD_LOGIC;

M00_AXI_ARESET_OUT_N => open, --p_out_mem.rstn,                             --: OUT STD_LOGIC;
M00_AXI_ACLK         => p_in_mem.clk,                                       --: IN STD_LOGIC;
M00_AXI_AWID         => p_out_mem.axiw.aid(C_AXIM_IDWIDTH-1 downto 0),      --: OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
M00_AXI_AWADDR       => p_out_mem.axiw.adr(G_MEM_AWIDTH-1 downto 0),        --: OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
M00_AXI_AWLEN        => p_out_mem.axiw.trnlen(7 downto 0),                  --: OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
M00_AXI_AWSIZE       => p_out_mem.axiw.dbus(2 downto 0),                    --: OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
M00_AXI_AWBURST      => p_out_mem.axiw.burst(1 downto 0),                   --: OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
M00_AXI_AWLOCK       => p_out_mem.axiw.lock(0),                             --: OUT STD_LOGIC;
M00_AXI_AWCACHE      => p_out_mem.axiw.cache(3 downto 0),                   --: OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
M00_AXI_AWPROT       => p_out_mem.axiw.prot(2 downto 0),                    --: OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
M00_AXI_AWQOS        => p_out_mem.axiw.qos(3 downto 0),                     --: OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
M00_AXI_AWVALID      => p_out_mem.axiw.avalid,                              --: OUT STD_LOGIC;
M00_AXI_AWREADY      => p_in_mem.axiw.aready,                               --: IN STD_LOGIC;
M00_AXI_WDATA        => p_out_mem.axiw.data(G_MEM_DWIDTH-1 downto 0),       --: OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
M00_AXI_WSTRB        => p_out_mem.axiw.dbe(G_MEM_DWIDTH/8-1 downto 0),      --: OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
M00_AXI_WLAST        => p_out_mem.axiw.dlast,                               --: OUT STD_LOGIC;
M00_AXI_WVALID       => p_out_mem.axiw.dvalid,                              --: OUT STD_LOGIC;
M00_AXI_WREADY       => p_in_mem.axiw.wready,                               --: IN STD_LOGIC;
M00_AXI_BID          => p_in_mem.axiw.rid(C_AXIM_IDWIDTH-1 downto 0),       --: IN STD_LOGIC_VECTOR(7 DOWNTO 0);
M00_AXI_BRESP        => p_in_mem.axiw.resp(1 downto 0),                     --: IN STD_LOGIC_VECTOR(1 DOWNTO 0);
M00_AXI_BVALID       => p_in_mem.axiw.rvalid,                               --: IN STD_LOGIC;
M00_AXI_BREADY       => p_out_mem.axiw.rready,                              --: OUT STD_LOGIC;
M00_AXI_ARID         => p_out_mem.axir.aid(C_AXIM_IDWIDTH-1 downto 0),      --: OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
M00_AXI_ARADDR       => p_out_mem.axir.adr(G_MEM_AWIDTH-1 downto 0),        --: OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
M00_AXI_ARLEN        => p_out_mem.axir.trnlen(7 downto 0),                  --: OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
M00_AXI_ARSIZE       => p_out_mem.axir.dbus(2 downto 0),                    --: OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
M00_AXI_ARBURST      => p_out_mem.axir.burst(1 downto 0),                   --: OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
M00_AXI_ARLOCK       => p_out_mem.axir.lock(0),                             --: OUT STD_LOGIC;
M00_AXI_ARCACHE      => p_out_mem.axir.cache(3 downto 0),                   --: OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
M00_AXI_ARPROT       => p_out_mem.axir.prot(2 downto 0),                    --: OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
M00_AXI_ARQOS        => p_out_mem.axir.qos(3 downto 0),                     --: OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
M00_AXI_ARVALID      => p_out_mem.axir.avalid,                              --: OUT STD_LOGIC;
M00_AXI_ARREADY      => p_in_mem.axir.aready,                               --: IN STD_LOGIC;
M00_AXI_RID          => p_in_mem.axir.rid(C_AXIM_IDWIDTH-1 downto 0),       --: IN STD_LOGIC_VECTOR(7 DOWNTO 0);
M00_AXI_RDATA        => p_in_mem.axir.data(G_MEM_DWIDTH-1 downto 0),        --: IN STD_LOGIC_VECTOR(31 DOWNTO 0);
M00_AXI_RRESP        => p_in_mem.axir.resp(1 downto 0),                     --: IN STD_LOGIC_VECTOR(1 DOWNTO 0);
M00_AXI_RLAST        => p_in_mem.axir.dlast,                                --: IN STD_LOGIC;
M00_AXI_RVALID       => p_in_mem.axir.dvalid,                               --: IN STD_LOGIC;
M00_AXI_RREADY       => p_out_mem.axir.rready                               --: OUT STD_LOGIC
);

end generate gen_chcount_3;


gen_chcount_4 : if G_CH_COUNT=4 generate

gen_idch : for i in 0 to G_CH_COUNT-1 generate
i_set_memch(i).axiw_id<=CONV_STD_LOGIC_VECTOR(2*i+0, i_set_memch(i).axiw_id'length);
i_set_memch(i).axir_id<=CONV_STD_LOGIC_VECTOR(2*i+1, i_set_memch(i).axir_id'length);

--Response ID
p_out_memch(i).axiw.rid<=EXT(i_get_memch(i).axiw_rid, p_out_memch(i).axiw.rid'length);
p_out_memch(i).axir.rid<=EXT(i_get_memch(i).axir_rid, p_out_memch(i).axir.rid'length);
end generate gen_idch;

m_arb: mem_achcount4
port map(
INTERCONNECT_ACLK    => p_in_clk,                                           --: IN STD_LOGIC;
INTERCONNECT_ARESETN => i_rstn,                                             --: IN STD_LOGIC;

S00_AXI_ARESET_OUT_N => p_out_memch(0).rstn,                                --: OUT STD_LOGIC;
S00_AXI_ACLK         => p_in_memch (0).clk,                                 --: IN STD_LOGIC;
S00_AXI_AWID         => i_set_memch(0).axiw_id(C_AXIS_IDWIDTH-1 downto 0),  --: IN STD_LOGIC_VECTOR(3 DOWNTO 0);
S00_AXI_AWADDR       => p_in_memch (0).axiw.adr(G_MEM_AWIDTH-1 downto 0),   --: IN STD_LOGIC_VECTOR(31 DOWNTO 0);
S00_AXI_AWLEN        => p_in_memch (0).axiw.trnlen(7 downto 0),             --: IN STD_LOGIC_VECTOR(7 DOWNTO 0);
S00_AXI_AWSIZE       => p_in_memch (0).axiw.dbus(2 downto 0),               --: IN STD_LOGIC_VECTOR(2 DOWNTO 0);
S00_AXI_AWBURST      => p_in_memch (0).axiw.burst(1 downto 0),              --: IN STD_LOGIC_VECTOR(1 DOWNTO 0);
S00_AXI_AWLOCK       => p_in_memch (0).axiw.lock(0),                        --: IN STD_LOGIC;
S00_AXI_AWCACHE      => p_in_memch (0).axiw.cache(3 downto 0),              --: IN STD_LOGIC_VECTOR(3 DOWNTO 0);
S00_AXI_AWPROT       => p_in_memch (0).axiw.prot(2 downto 0),               --: IN STD_LOGIC_VECTOR(2 DOWNTO 0);
S00_AXI_AWQOS        => p_in_memch (0).axiw.qos(3 downto 0),                --: IN STD_LOGIC_VECTOR(3 DOWNTO 0);
S00_AXI_AWVALID      => p_in_memch (0).axiw.avalid,                         --: IN STD_LOGIC;
S00_AXI_AWREADY      => p_out_memch(0).axiw.aready,                         --: OUT STD_LOGIC;
S00_AXI_WDATA        => p_in_memch (0).axiw.data(G_MEM_DWIDTH-1 downto 0),  --: IN STD_LOGIC_VECTOR(31 DOWNTO 0);
S00_AXI_WSTRB        => p_in_memch (0).axiw.dbe(G_MEM_DWIDTH/8-1 downto 0), --: IN STD_LOGIC_VECTOR(3 DOWNTO 0);
S00_AXI_WLAST        => p_in_memch (0).axiw.dlast,                          --: IN STD_LOGIC;
S00_AXI_WVALID       => p_in_memch (0).axiw.dvalid,                         --: IN STD_LOGIC;
S00_AXI_WREADY       => p_out_memch(0).axiw.wready,                         --: OUT STD_LOGIC;
S00_AXI_BID          => i_get_memch(0).axiw_rid(C_AXIS_IDWIDTH-1 downto 0), --: OUT STD_LOGIC_VECTOR(3 DOWNTO 0)
S00_AXI_BRESP        => p_out_memch(0).axiw.resp(1 downto 0),               --: OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
S00_AXI_BVALID       => p_out_memch(0).axiw.rvalid,                         --: OUT STD_LOGIC;
S00_AXI_BREADY       => p_in_memch (0).axiw.rready,                         --: IN STD_LOGIC;
S00_AXI_ARID         => i_set_memch(0).axir_id(C_AXIS_IDWIDTH-1 downto 0),  --: IN STD_LOGIC_VECTOR(3 DOWNTO 0);
S00_AXI_ARADDR       => p_in_memch (0).axir.adr(G_MEM_AWIDTH-1 downto 0),   --: IN STD_LOGIC_VECTOR(31 DOWNTO 0);
S00_AXI_ARLEN        => p_in_memch (0).axir.trnlen(7 downto 0),             --: IN STD_LOGIC_VECTOR(7 DOWNTO 0);
S00_AXI_ARSIZE       => p_in_memch (0).axir.dbus(2 downto 0),               --: IN STD_LOGIC_VECTOR(2 DOWNTO 0);
S00_AXI_ARBURST      => p_in_memch (0).axir.burst(1 downto 0),              --: IN STD_LOGIC_VECTOR(1 DOWNTO 0);
S00_AXI_ARLOCK       => p_in_memch (0).axir.lock(0),                        --: IN STD_LOGIC;
S00_AXI_ARCACHE      => p_in_memch (0).axir.cache(3 downto 0),              --: IN STD_LOGIC_VECTOR(3 DOWNTO 0);
S00_AXI_ARPROT       => p_in_memch (0).axir.prot(2 downto 0),               --: IN STD_LOGIC_VECTOR(2 DOWNTO 0);
S00_AXI_ARQOS        => p_in_memch (0).axir.qos(3 downto 0),                --: IN STD_LOGIC_VECTOR(3 DOWNTO 0);
S00_AXI_ARVALID      => p_in_memch (0).axir.avalid,                         --: IN STD_LOGIC;
S00_AXI_ARREADY      => p_out_memch(0).axir.aready,                         --: OUT STD_LOGIC;
S00_AXI_RID          => i_get_memch(0).axir_rid(C_AXIS_IDWIDTH-1 downto 0), --: OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
S00_AXI_RDATA        => p_out_memch(0).axir.data(G_MEM_DWIDTH-1 downto 0),  --: OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
S00_AXI_RRESP        => p_out_memch(0).axir.resp(1 downto 0),               --: OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
S00_AXI_RLAST        => p_out_memch(0).axir.dlast,                          --: OUT STD_LOGIC;
S00_AXI_RVALID       => p_out_memch(0).axir.dvalid,                         --: OUT STD_LOGIC;
S00_AXI_RREADY       => p_in_memch (0).axir.rready,                         --: IN STD_LOGIC;

S01_AXI_ARESET_OUT_N => p_out_memch(1).rstn,                                --: OUT STD_LOGIC;
S01_AXI_ACLK         => p_in_memch (1).clk,                                 --: IN STD_LOGIC;
S01_AXI_AWID         => i_set_memch(1).axiw_id(C_AXIS_IDWIDTH-1 downto 0),  --: IN STD_LOGIC_VECTOR(3 DOWNTO 0);
S01_AXI_AWADDR       => p_in_memch (1).axiw.adr(G_MEM_AWIDTH-1 downto 0),   --: IN STD_LOGIC_VECTOR(31 DOWNTO 0);
S01_AXI_AWLEN        => p_in_memch (1).axiw.trnlen(7 downto 0),             --: IN STD_LOGIC_VECTOR(7 DOWNTO 0);
S01_AXI_AWSIZE       => p_in_memch (1).axiw.dbus(2 downto 0),               --: IN STD_LOGIC_VECTOR(2 DOWNTO 0);
S01_AXI_AWBURST      => p_in_memch (1).axiw.burst(1 downto 0),              --: IN STD_LOGIC_VECTOR(1 DOWNTO 0);
S01_AXI_AWLOCK       => p_in_memch (1).axiw.lock(0),                        --: IN STD_LOGIC;
S01_AXI_AWCACHE      => p_in_memch (1).axiw.cache(3 downto 0),              --: IN STD_LOGIC_VECTOR(3 DOWNTO 0);
S01_AXI_AWPROT       => p_in_memch (1).axiw.prot(2 downto 0),               --: IN STD_LOGIC_VECTOR(2 DOWNTO 0);
S01_AXI_AWQOS        => p_in_memch (1).axiw.qos(3 downto 0),                --: IN STD_LOGIC_VECTOR(3 DOWNTO 0);
S01_AXI_AWVALID      => p_in_memch (1).axiw.avalid,                         --: IN STD_LOGIC;
S01_AXI_AWREADY      => p_out_memch(1).axiw.aready,                         --: OUT STD_LOGIC;
S01_AXI_WDATA        => p_in_memch (1).axiw.data(G_MEM_DWIDTH-1 downto 0),  --: IN STD_LOGIC_VECTOR(31 DOWNTO 0);
S01_AXI_WSTRB        => p_in_memch (1).axiw.dbe(G_MEM_DWIDTH/8-1 downto 0), --: IN STD_LOGIC_VECTOR(3 DOWNTO 0);
S01_AXI_WLAST        => p_in_memch (1).axiw.dlast,                          --: IN STD_LOGIC;
S01_AXI_WVALID       => p_in_memch (1).axiw.dvalid,                         --: IN STD_LOGIC;
S01_AXI_WREADY       => p_out_memch(1).axiw.wready,                         --: OUT STD_LOGIC;
S01_AXI_BID          => i_get_memch(1).axiw_rid(C_AXIS_IDWIDTH-1 downto 0), --: OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
S01_AXI_BRESP        => p_out_memch(1).axiw.resp(1 downto 0),               --: OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
S01_AXI_BVALID       => p_out_memch(1).axiw.rvalid,                         --: OUT STD_LOGIC;
S01_AXI_BREADY       => p_in_memch (1).axiw.rready,                         --: IN STD_LOGIC;
S01_AXI_ARID         => i_set_memch(1).axir_id(C_AXIS_IDWIDTH-1 downto 0),  --: IN STD_LOGIC_VECTOR(3 DOWNTO 0);
S01_AXI_ARADDR       => p_in_memch (1).axir.adr(G_MEM_AWIDTH-1 downto 0),   --: IN STD_LOGIC_VECTOR(31 DOWNTO 0);
S01_AXI_ARLEN        => p_in_memch (1).axir.trnlen(7 downto 0),             --: IN STD_LOGIC_VECTOR(7 DOWNTO 0);
S01_AXI_ARSIZE       => p_in_memch (1).axir.dbus(2 downto 0),               --: IN STD_LOGIC_VECTOR(2 DOWNTO 0);
S01_AXI_ARBURST      => p_in_memch (1).axir.burst(1 downto 0),              --: IN STD_LOGIC_VECTOR(1 DOWNTO 0);
S01_AXI_ARLOCK       => p_in_memch (1).axir.lock(0),                        --: IN STD_LOGIC;
S01_AXI_ARCACHE      => p_in_memch (1).axir.cache(3 downto 0),              --: IN STD_LOGIC_VECTOR(3 DOWNTO 0);
S01_AXI_ARPROT       => p_in_memch (1).axir.prot(2 downto 0),               --: IN STD_LOGIC_VECTOR(2 DOWNTO 0);
S01_AXI_ARQOS        => p_in_memch (1).axir.qos(3 downto 0),                --: IN STD_LOGIC_VECTOR(3 DOWNTO 0);
S01_AXI_ARVALID      => p_in_memch (1).axir.avalid,                         --: IN STD_LOGIC;
S01_AXI_ARREADY      => p_out_memch(1).axir.aready,                         --: OUT STD_LOGIC;
S01_AXI_RID          => i_get_memch(1).axir_rid(C_AXIS_IDWIDTH-1 downto 0), --: OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
S01_AXI_RDATA        => p_out_memch(1).axir.data(G_MEM_DWIDTH-1 downto 0),  --: OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
S01_AXI_RRESP        => p_out_memch(1).axir.resp(1 downto 0),               --: OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
S01_AXI_RLAST        => p_out_memch(1).axir.dlast,                          --: OUT STD_LOGIC;
S01_AXI_RVALID       => p_out_memch(1).axir.dvalid,                         --: OUT STD_LOGIC;
S01_AXI_RREADY       => p_in_memch (1).axir.rready,                         --: IN STD_LOGIC;

S02_AXI_ARESET_OUT_N => p_out_memch(2).rstn,                                --: OUT STD_LOGIC;
S02_AXI_ACLK         => p_in_memch (2).clk,                                 --: IN STD_LOGIC;
S02_AXI_AWID         => i_set_memch(2).axiw_id(C_AXIS_IDWIDTH-1 downto 0),  --: IN STD_LOGIC_VECTOR(3 DOWNTO 0);
S02_AXI_AWADDR       => p_in_memch (2).axiw.adr(G_MEM_AWIDTH-1 downto 0),   --: IN STD_LOGIC_VECTOR(31 DOWNTO 0);
S02_AXI_AWLEN        => p_in_memch (2).axiw.trnlen(7 downto 0),             --: IN STD_LOGIC_VECTOR(7 DOWNTO 0);
S02_AXI_AWSIZE       => p_in_memch (2).axiw.dbus(2 downto 0),               --: IN STD_LOGIC_VECTOR(2 DOWNTO 0);
S02_AXI_AWBURST      => p_in_memch (2).axiw.burst(1 downto 0),              --: IN STD_LOGIC_VECTOR(1 DOWNTO 0);
S02_AXI_AWLOCK       => p_in_memch (2).axiw.lock(0),                        --: IN STD_LOGIC;
S02_AXI_AWCACHE      => p_in_memch (2).axiw.cache(3 downto 0),              --: IN STD_LOGIC_VECTOR(3 DOWNTO 0);
S02_AXI_AWPROT       => p_in_memch (2).axiw.prot(2 downto 0),               --: IN STD_LOGIC_VECTOR(2 DOWNTO 0);
S02_AXI_AWQOS        => p_in_memch (2).axiw.qos(3 downto 0),                --: IN STD_LOGIC_VECTOR(3 DOWNTO 0);
S02_AXI_AWVALID      => p_in_memch (2).axiw.avalid,                         --: IN STD_LOGIC;
S02_AXI_AWREADY      => p_out_memch(2).axiw.aready,                         --: OUT STD_LOGIC;
S02_AXI_WDATA        => p_in_memch (2).axiw.data(G_MEM_DWIDTH-1 downto 0),  --: IN STD_LOGIC_VECTOR(31 DOWNTO 0);
S02_AXI_WSTRB        => p_in_memch (2).axiw.dbe(G_MEM_DWIDTH/8-1 downto 0), --: IN STD_LOGIC_VECTOR(3 DOWNTO 0);
S02_AXI_WLAST        => p_in_memch (2).axiw.dlast,                          --: IN STD_LOGIC;
S02_AXI_WVALID       => p_in_memch (2).axiw.dvalid,                         --: IN STD_LOGIC;
S02_AXI_WREADY       => p_out_memch(2).axiw.wready,                         --: OUT STD_LOGIC;
S02_AXI_BID          => i_get_memch(2).axiw_rid(C_AXIS_IDWIDTH-1 downto 0), --: OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
S02_AXI_BRESP        => p_out_memch(2).axiw.resp(1 downto 0),               --: OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
S02_AXI_BVALID       => p_out_memch(2).axiw.rvalid,                         --: OUT STD_LOGIC;
S02_AXI_BREADY       => p_in_memch (2).axiw.rready,                         --: IN STD_LOGIC;
S02_AXI_ARID         => i_set_memch(2).axir_id(C_AXIS_IDWIDTH-1 downto 0),  --: IN STD_LOGIC_VECTOR(3 DOWNTO 0);
S02_AXI_ARADDR       => p_in_memch (2).axir.adr(G_MEM_AWIDTH-1 downto 0),   --: IN STD_LOGIC_VECTOR(31 DOWNTO 0);
S02_AXI_ARLEN        => p_in_memch (2).axir.trnlen(7 downto 0),             --: IN STD_LOGIC_VECTOR(7 DOWNTO 0);
S02_AXI_ARSIZE       => p_in_memch (2).axir.dbus(2 downto 0),               --: IN STD_LOGIC_VECTOR(2 DOWNTO 0);
S02_AXI_ARBURST      => p_in_memch (2).axir.burst(1 downto 0),              --: IN STD_LOGIC_VECTOR(1 DOWNTO 0);
S02_AXI_ARLOCK       => p_in_memch (2).axir.lock(0),                        --: IN STD_LOGIC;
S02_AXI_ARCACHE      => p_in_memch (2).axir.cache(3 downto 0),              --: IN STD_LOGIC_VECTOR(3 DOWNTO 0);
S02_AXI_ARPROT       => p_in_memch (2).axir.prot(2 downto 0),               --: IN STD_LOGIC_VECTOR(2 DOWNTO 0);
S02_AXI_ARQOS        => p_in_memch (2).axir.qos(3 downto 0),                --: IN STD_LOGIC_VECTOR(3 DOWNTO 0);
S02_AXI_ARVALID      => p_in_memch (2).axir.avalid,                         --: IN STD_LOGIC;
S02_AXI_ARREADY      => p_out_memch(2).axir.aready,                         --: OUT STD_LOGIC;
S02_AXI_RID          => i_get_memch(2).axir_rid(C_AXIS_IDWIDTH-1 downto 0), --: OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
S02_AXI_RDATA        => p_out_memch(2).axir.data(G_MEM_DWIDTH-1 downto 0),  --: OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
S02_AXI_RRESP        => p_out_memch(2).axir.resp(1 downto 0),               --: OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
S02_AXI_RLAST        => p_out_memch(2).axir.dlast,                          --: OUT STD_LOGIC;
S02_AXI_RVALID       => p_out_memch(2).axir.dvalid,                         --: OUT STD_LOGIC;
S02_AXI_RREADY       => p_in_memch (2).axir.rready,                         --: IN STD_LOGIC;

S03_AXI_ARESET_OUT_N => p_out_memch(3).rstn,                                --: OUT STD_LOGIC;
S03_AXI_ACLK         => p_in_memch (3).clk,                                 --: IN STD_LOGIC;
S03_AXI_AWID         => i_set_memch(3).axiw_id(C_AXIS_IDWIDTH-1 downto 0),  --: IN STD_LOGIC_VECTOR(3 DOWNTO 0);
S03_AXI_AWADDR       => p_in_memch (3).axiw.adr(G_MEM_AWIDTH-1 downto 0),   --: IN STD_LOGIC_VECTOR(31 DOWNTO 0);
S03_AXI_AWLEN        => p_in_memch (3).axiw.trnlen(7 downto 0),             --: IN STD_LOGIC_VECTOR(7 DOWNTO 0);
S03_AXI_AWSIZE       => p_in_memch (3).axiw.dbus(2 downto 0),               --: IN STD_LOGIC_VECTOR(2 DOWNTO 0);
S03_AXI_AWBURST      => p_in_memch (3).axiw.burst(1 downto 0),              --: IN STD_LOGIC_VECTOR(1 DOWNTO 0);
S03_AXI_AWLOCK       => p_in_memch (3).axiw.lock(0),                        --: IN STD_LOGIC;
S03_AXI_AWCACHE      => p_in_memch (3).axiw.cache(3 downto 0),              --: IN STD_LOGIC_VECTOR(3 DOWNTO 0);
S03_AXI_AWPROT       => p_in_memch (3).axiw.prot(2 downto 0),               --: IN STD_LOGIC_VECTOR(2 DOWNTO 0);
S03_AXI_AWQOS        => p_in_memch (3).axiw.qos(3 downto 0),                --: IN STD_LOGIC_VECTOR(3 DOWNTO 0);
S03_AXI_AWVALID      => p_in_memch (3).axiw.avalid,                         --: IN STD_LOGIC;
S03_AXI_AWREADY      => p_out_memch(3).axiw.aready,                         --: OUT STD_LOGIC;
S03_AXI_WDATA        => p_in_memch (3).axiw.data(G_MEM_DWIDTH-1 downto 0),  --: IN STD_LOGIC_VECTOR(31 DOWNTO 0);
S03_AXI_WSTRB        => p_in_memch (3).axiw.dbe(G_MEM_DWIDTH/8-1 downto 0), --: IN STD_LOGIC_VECTOR(3 DOWNTO 0);
S03_AXI_WLAST        => p_in_memch (3).axiw.dlast,                          --: IN STD_LOGIC;
S03_AXI_WVALID       => p_in_memch (3).axiw.dvalid,                         --: IN STD_LOGIC;
S03_AXI_WREADY       => p_out_memch(3).axiw.wready,                         --: OUT STD_LOGIC;
S03_AXI_BID          => i_get_memch(3).axiw_rid(C_AXIS_IDWIDTH-1 downto 0), --: OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
S03_AXI_BRESP        => p_out_memch(3).axiw.resp(1 downto 0),               --: OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
S03_AXI_BVALID       => p_out_memch(3).axiw.rvalid,                         --: OUT STD_LOGIC;
S03_AXI_BREADY       => p_in_memch (3).axiw.rready,                         --: IN STD_LOGIC;
S03_AXI_ARID         => i_set_memch(3).axir_id(C_AXIS_IDWIDTH-1 downto 0),  --: IN STD_LOGIC_VECTOR(3 DOWNTO 0);
S03_AXI_ARADDR       => p_in_memch (3).axir.adr(G_MEM_AWIDTH-1 downto 0),   --: IN STD_LOGIC_VECTOR(31 DOWNTO 0);
S03_AXI_ARLEN        => p_in_memch (3).axir.trnlen(7 downto 0),             --: IN STD_LOGIC_VECTOR(7 DOWNTO 0);
S03_AXI_ARSIZE       => p_in_memch (3).axir.dbus(2 downto 0),               --: IN STD_LOGIC_VECTOR(2 DOWNTO 0);
S03_AXI_ARBURST      => p_in_memch (3).axir.burst(1 downto 0),              --: IN STD_LOGIC_VECTOR(1 DOWNTO 0);
S03_AXI_ARLOCK       => p_in_memch (3).axir.lock(0),                        --: IN STD_LOGIC;
S03_AXI_ARCACHE      => p_in_memch (3).axir.cache(3 downto 0),              --: IN STD_LOGIC_VECTOR(3 DOWNTO 0);
S03_AXI_ARPROT       => p_in_memch (3).axir.prot(2 downto 0),               --: IN STD_LOGIC_VECTOR(2 DOWNTO 0);
S03_AXI_ARQOS        => p_in_memch (3).axir.qos(3 downto 0),                --: IN STD_LOGIC_VECTOR(3 DOWNTO 0);
S03_AXI_ARVALID      => p_in_memch (3).axir.avalid,                         --: IN STD_LOGIC;
S03_AXI_ARREADY      => p_out_memch(3).axir.aready,                         --: OUT STD_LOGIC;
S03_AXI_RID          => i_get_memch(3).axir_rid(C_AXIS_IDWIDTH-1 downto 0), --: OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
S03_AXI_RDATA        => p_out_memch(3).axir.data(G_MEM_DWIDTH-1 downto 0),  --: OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
S03_AXI_RRESP        => p_out_memch(3).axir.resp(1 downto 0),               --: OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
S03_AXI_RLAST        => p_out_memch(3).axir.dlast,                          --: OUT STD_LOGIC;
S03_AXI_RVALID       => p_out_memch(3).axir.dvalid,                         --: OUT STD_LOGIC;
S03_AXI_RREADY       => p_in_memch (3).axir.rready,                         --: IN STD_LOGIC;

M00_AXI_ARESET_OUT_N => open, --p_out_mem.rstn,                             --: OUT STD_LOGIC;
M00_AXI_ACLK         => p_in_mem.clk,                                       --: IN STD_LOGIC;
M00_AXI_AWID         => p_out_mem.axiw.aid(C_AXIM_IDWIDTH-1 downto 0),      --: OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
M00_AXI_AWADDR       => p_out_mem.axiw.adr(G_MEM_AWIDTH-1 downto 0),        --: OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
M00_AXI_AWLEN        => p_out_mem.axiw.trnlen(7 downto 0),                  --: OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
M00_AXI_AWSIZE       => p_out_mem.axiw.dbus(2 downto 0),                    --: OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
M00_AXI_AWBURST      => p_out_mem.axiw.burst(1 downto 0),                   --: OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
M00_AXI_AWLOCK       => p_out_mem.axiw.lock(0),                             --: OUT STD_LOGIC;
M00_AXI_AWCACHE      => p_out_mem.axiw.cache(3 downto 0),                   --: OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
M00_AXI_AWPROT       => p_out_mem.axiw.prot(2 downto 0),                    --: OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
M00_AXI_AWQOS        => p_out_mem.axiw.qos(3 downto 0),                     --: OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
M00_AXI_AWVALID      => p_out_mem.axiw.avalid,                              --: OUT STD_LOGIC;
M00_AXI_AWREADY      => p_in_mem.axiw.aready,                               --: IN STD_LOGIC;
M00_AXI_WDATA        => p_out_mem.axiw.data(G_MEM_DWIDTH-1 downto 0),       --: OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
M00_AXI_WSTRB        => p_out_mem.axiw.dbe(G_MEM_DWIDTH/8-1 downto 0),      --: OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
M00_AXI_WLAST        => p_out_mem.axiw.dlast,                               --: OUT STD_LOGIC;
M00_AXI_WVALID       => p_out_mem.axiw.dvalid,                              --: OUT STD_LOGIC;
M00_AXI_WREADY       => p_in_mem.axiw.wready,                               --: IN STD_LOGIC;
M00_AXI_BID          => p_in_mem.axiw.rid(C_AXIM_IDWIDTH-1 downto 0),       --: IN STD_LOGIC_VECTOR(7 DOWNTO 0);
M00_AXI_BRESP        => p_in_mem.axiw.resp(1 downto 0),                     --: IN STD_LOGIC_VECTOR(1 DOWNTO 0);
M00_AXI_BVALID       => p_in_mem.axiw.rvalid,                               --: IN STD_LOGIC;
M00_AXI_BREADY       => p_out_mem.axiw.rready,                              --: OUT STD_LOGIC;
M00_AXI_ARID         => p_out_mem.axir.aid(C_AXIM_IDWIDTH-1 downto 0),      --: OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
M00_AXI_ARADDR       => p_out_mem.axir.adr(G_MEM_AWIDTH-1 downto 0),        --: OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
M00_AXI_ARLEN        => p_out_mem.axir.trnlen(7 downto 0),                  --: OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
M00_AXI_ARSIZE       => p_out_mem.axir.dbus(2 downto 0),                    --: OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
M00_AXI_ARBURST      => p_out_mem.axir.burst(1 downto 0),                   --: OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
M00_AXI_ARLOCK       => p_out_mem.axir.lock(0),                             --: OUT STD_LOGIC;
M00_AXI_ARCACHE      => p_out_mem.axir.cache(3 downto 0),                   --: OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
M00_AXI_ARPROT       => p_out_mem.axir.prot(2 downto 0),                    --: OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
M00_AXI_ARQOS        => p_out_mem.axir.qos(3 downto 0),                     --: OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
M00_AXI_ARVALID      => p_out_mem.axir.avalid,                              --: OUT STD_LOGIC;
M00_AXI_ARREADY      => p_in_mem.axir.aready,                               --: IN STD_LOGIC;
M00_AXI_RID          => p_in_mem.axir.rid(C_AXIM_IDWIDTH-1 downto 0),       --: IN STD_LOGIC_VECTOR(7 DOWNTO 0);
M00_AXI_RDATA        => p_in_mem.axir.data(G_MEM_DWIDTH-1 downto 0),        --: IN STD_LOGIC_VECTOR(31 DOWNTO 0);
M00_AXI_RRESP        => p_in_mem.axir.resp(1 downto 0),                     --: IN STD_LOGIC_VECTOR(1 DOWNTO 0);
M00_AXI_RLAST        => p_in_mem.axir.dlast,                                --: IN STD_LOGIC;
M00_AXI_RVALID       => p_in_mem.axir.dvalid,                               --: IN STD_LOGIC;
M00_AXI_RREADY       => p_out_mem.axir.rready                               --: OUT STD_LOGIC
);

end generate gen_chcount_4;


--END MAIN
end behavioral;



--gen_chcount_3 : if G_CH_COUNT/=1 generate
--
--gen_idch : for i in 0 to 4 generate
--i_set_memch(i).axiw_id<=CONV_STD_LOGIC_VECTOR(2*i+0, i_set_memch(i).axiw_id'length);
--i_set_memch(i).axir_id<=CONV_STD_LOGIC_VECTOR(2*i+1, i_set_memch(i).axir_id'length);
--
----Response ID
--p_out_memch(i).axiw.rid<=EXT(i_get_memch(i).axiw_rid, p_out_memch(i).axiw.rid'length);
--p_out_memch(i).axir.rid<=EXT(i_get_memch(i).axir_rid, p_out_memch(i).axir.rid'length);
--end generate gen_idch;
--
--
--gen_ch : for i in 0 to G_CH_COUNT-1 generate
--i_in_memch(i).clk <=p_in_memch(i).clk ;
--i_in_memch(i).rstn<=p_in_memch(i).rstn;
--
--i_in_memch(i).axiw.aid    <=p_in_memch(i).axiw.aid    ;
--i_in_memch(i).axiw.adr    <=p_in_memch(i).axiw.adr    ;
--i_in_memch(i).axiw.trnlen <=p_in_memch(i).axiw.trnlen ;
--i_in_memch(i).axiw.dbus   <=p_in_memch(i).axiw.dbus   ;
--i_in_memch(i).axiw.burst  <=p_in_memch(i).axiw.burst  ;
--i_in_memch(i).axiw.lock   <=p_in_memch(i).axiw.lock   ;
--i_in_memch(i).axiw.cache  <=p_in_memch(i).axiw.cache  ;
--i_in_memch(i).axiw.prot   <=p_in_memch(i).axiw.prot   ;
--i_in_memch(i).axiw.qos    <=p_in_memch(i).axiw.qos    ;
--i_in_memch(i).axiw.avalid <=p_in_memch(i).axiw.avalid ;
--i_in_memch(i).axiw.data   <=p_in_memch(i).axiw.data   ;
--i_in_memch(i).axiw.dbe    <=p_in_memch(i).axiw.dbe    ;
--i_in_memch(i).axiw.dlast  <=p_in_memch(i).axiw.dlast  ;
--i_in_memch(i).axiw.dvalid <=p_in_memch(i).axiw.dvalid ;
--i_in_memch(i).axiw.rready <=p_in_memch(i).axiw.rready ;
--p_out_memch(i).axiw.aready <=i_out_memch(i).axiw.aready;
--p_out_memch(i).axiw.wready <=i_out_memch(i).axiw.wready;
----p_out_memch(i).axiw.rid    <=i_out_memch(i).axiw.rid;
--p_out_memch(i).axiw.resp   <=i_out_memch(i).axiw.resp;
--p_out_memch(i).axiw.rvalid <=i_out_memch(i).axiw.rvalid;
--
--i_in_memch(i).axir.aid    <=p_in_memch(i).axir.aid    ;
--i_in_memch(i).axir.adr    <=p_in_memch(i).axir.adr    ;
--i_in_memch(i).axir.trnlen <=p_in_memch(i).axir.trnlen ;
--i_in_memch(i).axir.dbus   <=p_in_memch(i).axir.dbus   ;
--i_in_memch(i).axir.burst  <=p_in_memch(i).axir.burst  ;
--i_in_memch(i).axir.lock   <=p_in_memch(i).axir.lock   ;
--i_in_memch(i).axir.cache  <=p_in_memch(i).axir.cache  ;
--i_in_memch(i).axir.prot   <=p_in_memch(i).axir.prot   ;
--i_in_memch(i).axir.qos    <=p_in_memch(i).axir.qos    ;
--i_in_memch(i).axir.avalid <=p_in_memch(i).axir.avalid ;
--i_in_memch(i).axir.rready <=p_in_memch(i).axir.rready ;
--p_out_memch(i).axir.aready <=i_out_memch(i).axir.aready;
----p_out_memch(i).axir.rid    <=i_out_memch(i).axir.rid;
--p_out_memch(i).axir.data   <=i_out_memch(i).axir.data;
--p_out_memch(i).axir.resp   <=i_out_memch(i).axir.resp;
--p_out_memch(i).axir.dlast  <=i_out_memch(i).axir.dlast;
--p_out_memch(i).axir.dvalid <=i_out_memch(i).axir.dvalid;
--
--p_out_memch(i).clk  <=i_out_memch(i).clk;
--p_out_memch(i).rstn <=i_out_memch(i).rstn;
--
--end generate gen_ch;
--
--
--gen_nomax : if G_CH_COUNT/=4 generate
--gen_ch : for i in G_CH_COUNT to 4 generate
--i_in_memch(i).clk <=p_in_memch(i).clk ;
--i_in_memch(i).rstn<=p_in_memch(i).rstn;
--
--i_in_memch(i).axiw.aid    <=p_in_memch(i).axiw.aid    ;
--i_in_memch(i).axiw.adr    <=(others=>'0');
--i_in_memch(i).axiw.trnlen <=(others=>'0');
--i_in_memch(i).axiw.dbus   <=(others=>'0');--CONV_STD_LOGIC_VECTOR(2, i_in_memch(i).axiw.dbus'length);
--i_in_memch(i).axiw.burst  <=(others=>'0');--//0/1 - Fixed( FIFO-type)/INCR (Normal sequential memory)
--i_in_memch(i).axiw.lock   <=(others=>'0');
--i_in_memch(i).axiw.cache  <=(others=>'0');
--i_in_memch(i).axiw.prot   <=(others=>'0');
--i_in_memch(i).axiw.qos    <=(others=>'0');
--i_in_memch(i).axiw.avalid <='0';
--i_in_memch(i).axiw.data   <=(others=>'0');
--i_in_memch(i).axiw.dbe    <=(others=>'0');
--i_in_memch(i).axiw.dlast  <='0';
--i_in_memch(i).axiw.dvalid <='0';
--i_in_memch(i).axiw.rready <='0';
--p_out_memch(i).axiw.aready <=i_out_memch(i).axiw.aready;
--p_out_memch(i).axiw.wready <=i_out_memch(i).axiw.wready;
----p_out_memch(i).axiw.rid    <=i_out_memch(i).axiw.rid;
--p_out_memch(i).axiw.resp   <=i_out_memch(i).axiw.resp;
--p_out_memch(i).axiw.rvalid <=i_out_memch(i).axiw.rvalid;
--
--i_in_memch(i).axir.aid    <=p_in_memch(i).axir.aid    ;
--i_in_memch(i).axir.adr    <=(others=>'0');
--i_in_memch(i).axir.trnlen <=(others=>'0');
--i_in_memch(i).axir.dbus   <=(others=>'0');--CONV_STD_LOGIC_VECTOR(2, i_in_memch(i).axir.dbus'length);
--i_in_memch(i).axir.burst  <=(others=>'0');--//0/1 - Fixed( FIFO-type)/INCR (Normal sequential memory)
--i_in_memch(i).axir.lock   <=(others=>'0');
--i_in_memch(i).axir.cache  <=(others=>'0');
--i_in_memch(i).axir.prot   <=(others=>'0');
--i_in_memch(i).axir.qos    <=(others=>'0');
--i_in_memch(i).axir.avalid <='0';
--i_in_memch(i).axir.rready <='0';
--p_out_memch(i).axir.aready <=i_out_memch(i).axir.aready;
----p_out_memch(i).axir.rid    <=i_out_memch(i).axir.rid;
--p_out_memch(i).axir.data   <=i_out_memch(i).axir.data;
--p_out_memch(i).axir.resp   <=i_out_memch(i).axir.resp;
--p_out_memch(i).axir.dlast  <=i_out_memch(i).axir.dlast;
--p_out_memch(i).axir.dvalid <=i_out_memch(i).axir.dvalid;
--
--p_out_memch(i).clk  <=i_out_memch(i).clk;
--p_out_memch(i).rstn <=i_out_memch(i).rstn;
--
--end generate gen_ch;
--end generate gen_nomax;
--
--
--m_arb: mem_achcount4
--port map(
--INTERCONNECT_ACLK    => p_in_clk,                                           --: IN STD_LOGIC;
--INTERCONNECT_ARESETN => i_rstn,                                             --: IN STD_LOGIC;
--
--S00_AXI_ARESET_OUT_N => i_out_memch(0).rstn,                                --: OUT STD_LOGIC;
--S00_AXI_ACLK         => i_in_memch (0).clk,                                 --: IN STD_LOGIC;
--S00_AXI_AWID         => i_set_memch(0).axiw_id(C_AXIS_IDWIDTH-1 downto 0),  --: IN STD_LOGIC_VECTOR(3 DOWNTO 0);
--S00_AXI_AWADDR       => i_in_memch (0).axiw.adr(G_MEM_AWIDTH-1 downto 0),   --: IN STD_LOGIC_VECTOR(31 DOWNTO 0);
--S00_AXI_AWLEN        => i_in_memch (0).axiw.trnlen(7 downto 0),             --: IN STD_LOGIC_VECTOR(7 DOWNTO 0);
--S00_AXI_AWSIZE       => i_in_memch (0).axiw.dbus(2 downto 0),               --: IN STD_LOGIC_VECTOR(2 DOWNTO 0);
--S00_AXI_AWBURST      => i_in_memch (0).axiw.burst(1 downto 0),              --: IN STD_LOGIC_VECTOR(1 DOWNTO 0);
--S00_AXI_AWLOCK       => i_in_memch (0).axiw.lock(0),                        --: IN STD_LOGIC;
--S00_AXI_AWCACHE      => i_in_memch (0).axiw.cache(3 downto 0),              --: IN STD_LOGIC_VECTOR(3 DOWNTO 0);
--S00_AXI_AWPROT       => i_in_memch (0).axiw.prot(2 downto 0),               --: IN STD_LOGIC_VECTOR(2 DOWNTO 0);
--S00_AXI_AWQOS        => i_in_memch (0).axiw.qos(3 downto 0),                --: IN STD_LOGIC_VECTOR(3 DOWNTO 0);
--S00_AXI_AWVALID      => i_in_memch (0).axiw.avalid,                         --: IN STD_LOGIC;
--S00_AXI_AWREADY      => i_out_memch(0).axiw.aready,                         --: OUT STD_LOGIC;
--S00_AXI_WDATA        => i_in_memch (0).axiw.data(G_MEM_DWIDTH-1 downto 0),  --: IN STD_LOGIC_VECTOR(31 DOWNTO 0);
--S00_AXI_WSTRB        => i_in_memch (0).axiw.dbe(G_MEM_DWIDTH/8-1 downto 0), --: IN STD_LOGIC_VECTOR(3 DOWNTO 0);
--S00_AXI_WLAST        => i_in_memch (0).axiw.dlast,                          --: IN STD_LOGIC;
--S00_AXI_WVALID       => i_in_memch (0).axiw.dvalid,                         --: IN STD_LOGIC;
--S00_AXI_WREADY       => i_out_memch(0).axiw.wready,                         --: OUT STD_LOGIC;
--S00_AXI_BID          => i_get_memch(0).axiw_rid(C_AXIS_IDWIDTH-1 downto 0), --: OUT STD_LOGIC_VECTOR(3 DOWNTO 0)
--S00_AXI_BRESP        => i_out_memch(0).axiw.resp(1 downto 0),               --: OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
--S00_AXI_BVALID       => i_out_memch(0).axiw.rvalid,                         --: OUT STD_LOGIC;
--S00_AXI_BREADY       => i_in_memch (0).axiw.rready,                         --: IN STD_LOGIC;
--S00_AXI_ARID         => i_set_memch(0).axir_id(C_AXIS_IDWIDTH-1 downto 0),  --: IN STD_LOGIC_VECTOR(3 DOWNTO 0);
--S00_AXI_ARADDR       => i_in_memch (0).axir.adr(G_MEM_AWIDTH-1 downto 0),   --: IN STD_LOGIC_VECTOR(31 DOWNTO 0);
--S00_AXI_ARLEN        => i_in_memch (0).axir.trnlen(7 downto 0),             --: IN STD_LOGIC_VECTOR(7 DOWNTO 0);
--S00_AXI_ARSIZE       => i_in_memch (0).axir.dbus(2 downto 0),               --: IN STD_LOGIC_VECTOR(2 DOWNTO 0);
--S00_AXI_ARBURST      => i_in_memch (0).axir.burst(1 downto 0),              --: IN STD_LOGIC_VECTOR(1 DOWNTO 0);
--S00_AXI_ARLOCK       => i_in_memch (0).axir.lock(0),                        --: IN STD_LOGIC;
--S00_AXI_ARCACHE      => i_in_memch (0).axir.cache(3 downto 0),              --: IN STD_LOGIC_VECTOR(3 DOWNTO 0);
--S00_AXI_ARPROT       => i_in_memch (0).axir.prot(2 downto 0),               --: IN STD_LOGIC_VECTOR(2 DOWNTO 0);
--S00_AXI_ARQOS        => i_in_memch (0).axir.qos(3 downto 0),                --: IN STD_LOGIC_VECTOR(3 DOWNTO 0);
--S00_AXI_ARVALID      => i_in_memch (0).axir.avalid,                         --: IN STD_LOGIC;
--S00_AXI_ARREADY      => i_out_memch(0).axir.aready,                         --: OUT STD_LOGIC;
--S00_AXI_RID          => i_get_memch(0).axir_rid(C_AXIS_IDWIDTH-1 downto 0), --: OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
--S00_AXI_RDATA        => i_out_memch(0).axir.data(G_MEM_DWIDTH-1 downto 0),  --: OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
--S00_AXI_RRESP        => i_out_memch(0).axir.resp(1 downto 0),               --: OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
--S00_AXI_RLAST        => i_out_memch(0).axir.dlast,                          --: OUT STD_LOGIC;
--S00_AXI_RVALID       => i_out_memch(0).axir.dvalid,                         --: OUT STD_LOGIC;
--S00_AXI_RREADY       => i_in_memch (0).axir.rready,                         --: IN STD_LOGIC;
--
--S01_AXI_ARESET_OUT_N => i_out_memch(1).rstn,                                --: OUT STD_LOGIC;
--S01_AXI_ACLK         => i_in_memch (1).clk,                                 --: IN STD_LOGIC;
--S01_AXI_AWID         => i_set_memch(1).axiw_id(C_AXIS_IDWIDTH-1 downto 0),  --: IN STD_LOGIC_VECTOR(3 DOWNTO 0);
--S01_AXI_AWADDR       => i_in_memch (1).axiw.adr(G_MEM_AWIDTH-1 downto 0),   --: IN STD_LOGIC_VECTOR(31 DOWNTO 0);
--S01_AXI_AWLEN        => i_in_memch (1).axiw.trnlen(7 downto 0),             --: IN STD_LOGIC_VECTOR(7 DOWNTO 0);
--S01_AXI_AWSIZE       => i_in_memch (1).axiw.dbus(2 downto 0),               --: IN STD_LOGIC_VECTOR(2 DOWNTO 0);
--S01_AXI_AWBURST      => i_in_memch (1).axiw.burst(1 downto 0),              --: IN STD_LOGIC_VECTOR(1 DOWNTO 0);
--S01_AXI_AWLOCK       => i_in_memch (1).axiw.lock(0),                        --: IN STD_LOGIC;
--S01_AXI_AWCACHE      => i_in_memch (1).axiw.cache(3 downto 0),              --: IN STD_LOGIC_VECTOR(3 DOWNTO 0);
--S01_AXI_AWPROT       => i_in_memch (1).axiw.prot(2 downto 0),               --: IN STD_LOGIC_VECTOR(2 DOWNTO 0);
--S01_AXI_AWQOS        => i_in_memch (1).axiw.qos(3 downto 0),                --: IN STD_LOGIC_VECTOR(3 DOWNTO 0);
--S01_AXI_AWVALID      => i_in_memch (1).axiw.avalid,                         --: IN STD_LOGIC;
--S01_AXI_AWREADY      => i_out_memch(1).axiw.aready,                         --: OUT STD_LOGIC;
--S01_AXI_WDATA        => i_in_memch (1).axiw.data(G_MEM_DWIDTH-1 downto 0),  --: IN STD_LOGIC_VECTOR(31 DOWNTO 0);
--S01_AXI_WSTRB        => i_in_memch (1).axiw.dbe(G_MEM_DWIDTH/8-1 downto 0), --: IN STD_LOGIC_VECTOR(3 DOWNTO 0);
--S01_AXI_WLAST        => i_in_memch (1).axiw.dlast,                          --: IN STD_LOGIC;
--S01_AXI_WVALID       => i_in_memch (1).axiw.dvalid,                         --: IN STD_LOGIC;
--S01_AXI_WREADY       => i_out_memch(1).axiw.wready,                         --: OUT STD_LOGIC;
--S01_AXI_BID          => i_get_memch(1).axiw_rid(C_AXIS_IDWIDTH-1 downto 0), --: OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
--S01_AXI_BRESP        => i_out_memch(1).axiw.resp(1 downto 0),               --: OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
--S01_AXI_BVALID       => i_out_memch(1).axiw.rvalid,                         --: OUT STD_LOGIC;
--S01_AXI_BREADY       => i_in_memch (1).axiw.rready,                         --: IN STD_LOGIC;
--S01_AXI_ARID         => i_set_memch(1).axir_id(C_AXIS_IDWIDTH-1 downto 0),  --: IN STD_LOGIC_VECTOR(3 DOWNTO 0);
--S01_AXI_ARADDR       => i_in_memch (1).axir.adr(G_MEM_AWIDTH-1 downto 0),   --: IN STD_LOGIC_VECTOR(31 DOWNTO 0);
--S01_AXI_ARLEN        => i_in_memch (1).axir.trnlen(7 downto 0),             --: IN STD_LOGIC_VECTOR(7 DOWNTO 0);
--S01_AXI_ARSIZE       => i_in_memch (1).axir.dbus(2 downto 0),               --: IN STD_LOGIC_VECTOR(2 DOWNTO 0);
--S01_AXI_ARBURST      => i_in_memch (1).axir.burst(1 downto 0),              --: IN STD_LOGIC_VECTOR(1 DOWNTO 0);
--S01_AXI_ARLOCK       => i_in_memch (1).axir.lock(0),                        --: IN STD_LOGIC;
--S01_AXI_ARCACHE      => i_in_memch (1).axir.cache(3 downto 0),              --: IN STD_LOGIC_VECTOR(3 DOWNTO 0);
--S01_AXI_ARPROT       => i_in_memch (1).axir.prot(2 downto 0),               --: IN STD_LOGIC_VECTOR(2 DOWNTO 0);
--S01_AXI_ARQOS        => i_in_memch (1).axir.qos(3 downto 0),                --: IN STD_LOGIC_VECTOR(3 DOWNTO 0);
--S01_AXI_ARVALID      => i_in_memch (1).axir.avalid,                         --: IN STD_LOGIC;
--S01_AXI_ARREADY      => i_out_memch(1).axir.aready,                         --: OUT STD_LOGIC;
--S01_AXI_RID          => i_get_memch(1).axir_rid(C_AXIS_IDWIDTH-1 downto 0), --: OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
--S01_AXI_RDATA        => i_out_memch(1).axir.data(G_MEM_DWIDTH-1 downto 0),  --: OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
--S01_AXI_RRESP        => i_out_memch(1).axir.resp(1 downto 0),               --: OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
--S01_AXI_RLAST        => i_out_memch(1).axir.dlast,                          --: OUT STD_LOGIC;
--S01_AXI_RVALID       => i_out_memch(1).axir.dvalid,                         --: OUT STD_LOGIC;
--S01_AXI_RREADY       => i_in_memch (1).axir.rready,                         --: IN STD_LOGIC;
--
--S02_AXI_ARESET_OUT_N => i_out_memch(2).rstn,                                --: OUT STD_LOGIC;
--S02_AXI_ACLK         => i_in_memch (2).clk,                                 --: IN STD_LOGIC;
--S02_AXI_AWID         => i_set_memch(2).axiw_id(C_AXIS_IDWIDTH-1 downto 0),  --: IN STD_LOGIC_VECTOR(3 DOWNTO 0);
--S02_AXI_AWADDR       => i_in_memch (2).axiw.adr(G_MEM_AWIDTH-1 downto 0),   --: IN STD_LOGIC_VECTOR(31 DOWNTO 0);
--S02_AXI_AWLEN        => i_in_memch (2).axiw.trnlen(7 downto 0),             --: IN STD_LOGIC_VECTOR(7 DOWNTO 0);
--S02_AXI_AWSIZE       => i_in_memch (2).axiw.dbus(2 downto 0),               --: IN STD_LOGIC_VECTOR(2 DOWNTO 0);
--S02_AXI_AWBURST      => i_in_memch (2).axiw.burst(1 downto 0),              --: IN STD_LOGIC_VECTOR(1 DOWNTO 0);
--S02_AXI_AWLOCK       => i_in_memch (2).axiw.lock(0),                        --: IN STD_LOGIC;
--S02_AXI_AWCACHE      => i_in_memch (2).axiw.cache(3 downto 0),              --: IN STD_LOGIC_VECTOR(3 DOWNTO 0);
--S02_AXI_AWPROT       => i_in_memch (2).axiw.prot(2 downto 0),               --: IN STD_LOGIC_VECTOR(2 DOWNTO 0);
--S02_AXI_AWQOS        => i_in_memch (2).axiw.qos(3 downto 0),                --: IN STD_LOGIC_VECTOR(3 DOWNTO 0);
--S02_AXI_AWVALID      => i_in_memch (2).axiw.avalid,                         --: IN STD_LOGIC;
--S02_AXI_AWREADY      => i_out_memch(2).axiw.aready,                         --: OUT STD_LOGIC;
--S02_AXI_WDATA        => i_in_memch (2).axiw.data(G_MEM_DWIDTH-1 downto 0),  --: IN STD_LOGIC_VECTOR(31 DOWNTO 0);
--S02_AXI_WSTRB        => i_in_memch (2).axiw.dbe(G_MEM_DWIDTH/8-1 downto 0), --: IN STD_LOGIC_VECTOR(3 DOWNTO 0);
--S02_AXI_WLAST        => i_in_memch (2).axiw.dlast,                          --: IN STD_LOGIC;
--S02_AXI_WVALID       => i_in_memch (2).axiw.dvalid,                         --: IN STD_LOGIC;
--S02_AXI_WREADY       => i_out_memch(2).axiw.wready,                         --: OUT STD_LOGIC;
--S02_AXI_BID          => i_get_memch(2).axiw_rid(C_AXIS_IDWIDTH-1 downto 0), --: OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
--S02_AXI_BRESP        => i_out_memch(2).axiw.resp(1 downto 0),               --: OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
--S02_AXI_BVALID       => i_out_memch(2).axiw.rvalid,                         --: OUT STD_LOGIC;
--S02_AXI_BREADY       => i_in_memch (2).axiw.rready,                         --: IN STD_LOGIC;
--S02_AXI_ARID         => i_set_memch(2).axir_id(C_AXIS_IDWIDTH-1 downto 0),  --: IN STD_LOGIC_VECTOR(3 DOWNTO 0);
--S02_AXI_ARADDR       => i_in_memch (2).axir.adr(G_MEM_AWIDTH-1 downto 0),   --: IN STD_LOGIC_VECTOR(31 DOWNTO 0);
--S02_AXI_ARLEN        => i_in_memch (2).axir.trnlen(7 downto 0),             --: IN STD_LOGIC_VECTOR(7 DOWNTO 0);
--S02_AXI_ARSIZE       => i_in_memch (2).axir.dbus(2 downto 0),               --: IN STD_LOGIC_VECTOR(2 DOWNTO 0);
--S02_AXI_ARBURST      => i_in_memch (2).axir.burst(1 downto 0),              --: IN STD_LOGIC_VECTOR(1 DOWNTO 0);
--S02_AXI_ARLOCK       => i_in_memch (2).axir.lock(0),                        --: IN STD_LOGIC;
--S02_AXI_ARCACHE      => i_in_memch (2).axir.cache(3 downto 0),              --: IN STD_LOGIC_VECTOR(3 DOWNTO 0);
--S02_AXI_ARPROT       => i_in_memch (2).axir.prot(2 downto 0),               --: IN STD_LOGIC_VECTOR(2 DOWNTO 0);
--S02_AXI_ARQOS        => i_in_memch (2).axir.qos(3 downto 0),                --: IN STD_LOGIC_VECTOR(3 DOWNTO 0);
--S02_AXI_ARVALID      => i_in_memch (2).axir.avalid,                         --: IN STD_LOGIC;
--S02_AXI_ARREADY      => i_out_memch(2).axir.aready,                         --: OUT STD_LOGIC;
--S02_AXI_RID          => i_get_memch(2).axir_rid(C_AXIS_IDWIDTH-1 downto 0), --: OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
--S02_AXI_RDATA        => i_out_memch(2).axir.data(G_MEM_DWIDTH-1 downto 0),  --: OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
--S02_AXI_RRESP        => i_out_memch(2).axir.resp(1 downto 0),               --: OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
--S02_AXI_RLAST        => i_out_memch(2).axir.dlast,                          --: OUT STD_LOGIC;
--S02_AXI_RVALID       => i_out_memch(2).axir.dvalid,                         --: OUT STD_LOGIC;
--S02_AXI_RREADY       => i_in_memch (2).axir.rready,                         --: IN STD_LOGIC;
--
--S03_AXI_ARESET_OUT_N => i_out_memch(3).rstn,                                --: OUT STD_LOGIC;
--S03_AXI_ACLK         => i_in_memch (3).clk,                                 --: IN STD_LOGIC;
--S03_AXI_AWID         => i_set_memch(3).axiw_id(C_AXIS_IDWIDTH-1 downto 0),  --: IN STD_LOGIC_VECTOR(3 DOWNTO 0);
--S03_AXI_AWADDR       => i_in_memch (3).axiw.adr(G_MEM_AWIDTH-1 downto 0),   --: IN STD_LOGIC_VECTOR(31 DOWNTO 0);
--S03_AXI_AWLEN        => i_in_memch (3).axiw.trnlen(7 downto 0),             --: IN STD_LOGIC_VECTOR(7 DOWNTO 0);
--S03_AXI_AWSIZE       => i_in_memch (3).axiw.dbus(2 downto 0),               --: IN STD_LOGIC_VECTOR(2 DOWNTO 0);
--S03_AXI_AWBURST      => i_in_memch (3).axiw.burst(1 downto 0),              --: IN STD_LOGIC_VECTOR(1 DOWNTO 0);
--S03_AXI_AWLOCK       => i_in_memch (3).axiw.lock(0),                        --: IN STD_LOGIC;
--S03_AXI_AWCACHE      => i_in_memch (3).axiw.cache(3 downto 0),              --: IN STD_LOGIC_VECTOR(3 DOWNTO 0);
--S03_AXI_AWPROT       => i_in_memch (3).axiw.prot(2 downto 0),               --: IN STD_LOGIC_VECTOR(2 DOWNTO 0);
--S03_AXI_AWQOS        => i_in_memch (3).axiw.qos(3 downto 0),                --: IN STD_LOGIC_VECTOR(3 DOWNTO 0);
--S03_AXI_AWVALID      => i_in_memch (3).axiw.avalid,                         --: IN STD_LOGIC;
--S03_AXI_AWREADY      => i_out_memch(3).axiw.aready,                         --: OUT STD_LOGIC;
--S03_AXI_WDATA        => i_in_memch (3).axiw.data(G_MEM_DWIDTH-1 downto 0),  --: IN STD_LOGIC_VECTOR(31 DOWNTO 0);
--S03_AXI_WSTRB        => i_in_memch (3).axiw.dbe(G_MEM_DWIDTH/8-1 downto 0), --: IN STD_LOGIC_VECTOR(3 DOWNTO 0);
--S03_AXI_WLAST        => i_in_memch (3).axiw.dlast,                          --: IN STD_LOGIC;
--S03_AXI_WVALID       => i_in_memch (3).axiw.dvalid,                         --: IN STD_LOGIC;
--S03_AXI_WREADY       => i_out_memch(3).axiw.wready,                         --: OUT STD_LOGIC;
--S03_AXI_BID          => i_get_memch(3).axiw_rid(C_AXIS_IDWIDTH-1 downto 0), --: OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
--S03_AXI_BRESP        => i_out_memch(3).axiw.resp(1 downto 0),               --: OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
--S03_AXI_BVALID       => i_out_memch(3).axiw.rvalid,                         --: OUT STD_LOGIC;
--S03_AXI_BREADY       => i_in_memch (3).axiw.rready,                         --: IN STD_LOGIC;
--S03_AXI_ARID         => i_set_memch(3).axir_id(C_AXIS_IDWIDTH-1 downto 0),  --: IN STD_LOGIC_VECTOR(3 DOWNTO 0);
--S03_AXI_ARADDR       => i_in_memch (3).axir.adr(G_MEM_AWIDTH-1 downto 0),   --: IN STD_LOGIC_VECTOR(31 DOWNTO 0);
--S03_AXI_ARLEN        => i_in_memch (3).axir.trnlen(7 downto 0),             --: IN STD_LOGIC_VECTOR(7 DOWNTO 0);
--S03_AXI_ARSIZE       => i_in_memch (3).axir.dbus(2 downto 0),               --: IN STD_LOGIC_VECTOR(2 DOWNTO 0);
--S03_AXI_ARBURST      => i_in_memch (3).axir.burst(1 downto 0),              --: IN STD_LOGIC_VECTOR(1 DOWNTO 0);
--S03_AXI_ARLOCK       => i_in_memch (3).axir.lock(0),                        --: IN STD_LOGIC;
--S03_AXI_ARCACHE      => i_in_memch (3).axir.cache(3 downto 0),              --: IN STD_LOGIC_VECTOR(3 DOWNTO 0);
--S03_AXI_ARPROT       => i_in_memch (3).axir.prot(2 downto 0),               --: IN STD_LOGIC_VECTOR(2 DOWNTO 0);
--S03_AXI_ARQOS        => i_in_memch (3).axir.qos(3 downto 0),                --: IN STD_LOGIC_VECTOR(3 DOWNTO 0);
--S03_AXI_ARVALID      => i_in_memch (3).axir.avalid,                         --: IN STD_LOGIC;
--S03_AXI_ARREADY      => i_out_memch(3).axir.aready,                         --: OUT STD_LOGIC;
--S03_AXI_RID          => i_get_memch(3).axir_rid(C_AXIS_IDWIDTH-1 downto 0), --: OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
--S03_AXI_RDATA        => i_out_memch(3).axir.data(G_MEM_DWIDTH-1 downto 0),  --: OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
--S03_AXI_RRESP        => i_out_memch(3).axir.resp(1 downto 0),               --: OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
--S03_AXI_RLAST        => i_out_memch(3).axir.dlast,                          --: OUT STD_LOGIC;
--S03_AXI_RVALID       => i_out_memch(3).axir.dvalid,                         --: OUT STD_LOGIC;
--S03_AXI_RREADY       => i_in_memch (3).axir.rready,                         --: IN STD_LOGIC;
--
--M00_AXI_ARESET_OUT_N => open, --p_out_mem.rstn,                             --: OUT STD_LOGIC;
--M00_AXI_ACLK         => p_in_mem.clk,                                       --: IN STD_LOGIC;
--M00_AXI_AWID         => p_out_mem.axiw.aid(C_AXIM_IDWIDTH-1 downto 0),      --: OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
--M00_AXI_AWADDR       => p_out_mem.axiw.adr(G_MEM_AWIDTH-1 downto 0),        --: OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
--M00_AXI_AWLEN        => p_out_mem.axiw.trnlen(7 downto 0),                  --: OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
--M00_AXI_AWSIZE       => p_out_mem.axiw.dbus(2 downto 0),                    --: OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
--M00_AXI_AWBURST      => p_out_mem.axiw.burst(1 downto 0),                   --: OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
--M00_AXI_AWLOCK       => p_out_mem.axiw.lock(0),                             --: OUT STD_LOGIC;
--M00_AXI_AWCACHE      => p_out_mem.axiw.cache(3 downto 0),                   --: OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
--M00_AXI_AWPROT       => p_out_mem.axiw.prot(2 downto 0),                    --: OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
--M00_AXI_AWQOS        => p_out_mem.axiw.qos(3 downto 0),                     --: OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
--M00_AXI_AWVALID      => p_out_mem.axiw.avalid,                              --: OUT STD_LOGIC;
--M00_AXI_AWREADY      => p_in_mem.axiw.aready,                               --: IN STD_LOGIC;
--M00_AXI_WDATA        => p_out_mem.axiw.data(G_MEM_DWIDTH-1 downto 0),       --: OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
--M00_AXI_WSTRB        => p_out_mem.axiw.dbe(G_MEM_DWIDTH/8-1 downto 0),      --: OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
--M00_AXI_WLAST        => p_out_mem.axiw.dlast,                               --: OUT STD_LOGIC;
--M00_AXI_WVALID       => p_out_mem.axiw.dvalid,                              --: OUT STD_LOGIC;
--M00_AXI_WREADY       => p_in_mem.axiw.wready,                               --: IN STD_LOGIC;
--M00_AXI_BID          => p_in_mem.axiw.rid(C_AXIM_IDWIDTH-1 downto 0),       --: IN STD_LOGIC_VECTOR(7 DOWNTO 0);
--M00_AXI_BRESP        => p_in_mem.axiw.resp(1 downto 0),                     --: IN STD_LOGIC_VECTOR(1 DOWNTO 0);
--M00_AXI_BVALID       => p_in_mem.axiw.rvalid,                               --: IN STD_LOGIC;
--M00_AXI_BREADY       => p_out_mem.axiw.rready,                              --: OUT STD_LOGIC;
--M00_AXI_ARID         => p_out_mem.axir.aid(C_AXIM_IDWIDTH-1 downto 0),      --: OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
--M00_AXI_ARADDR       => p_out_mem.axir.adr(G_MEM_AWIDTH-1 downto 0),        --: OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
--M00_AXI_ARLEN        => p_out_mem.axir.trnlen(7 downto 0),                  --: OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
--M00_AXI_ARSIZE       => p_out_mem.axir.dbus(2 downto 0),                    --: OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
--M00_AXI_ARBURST      => p_out_mem.axir.burst(1 downto 0),                   --: OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
--M00_AXI_ARLOCK       => p_out_mem.axir.lock(0),                             --: OUT STD_LOGIC;
--M00_AXI_ARCACHE      => p_out_mem.axir.cache(3 downto 0),                   --: OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
--M00_AXI_ARPROT       => p_out_mem.axir.prot(2 downto 0),                    --: OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
--M00_AXI_ARQOS        => p_out_mem.axir.qos(3 downto 0),                     --: OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
--M00_AXI_ARVALID      => p_out_mem.axir.avalid,                              --: OUT STD_LOGIC;
--M00_AXI_ARREADY      => p_in_mem.axir.aready,                               --: IN STD_LOGIC;
--M00_AXI_RID          => p_in_mem.axir.rid(C_AXIM_IDWIDTH-1 downto 0),       --: IN STD_LOGIC_VECTOR(7 DOWNTO 0);
--M00_AXI_RDATA        => p_in_mem.axir.data(G_MEM_DWIDTH-1 downto 0),        --: IN STD_LOGIC_VECTOR(31 DOWNTO 0);
--M00_AXI_RRESP        => p_in_mem.axir.resp(1 downto 0),                     --: IN STD_LOGIC_VECTOR(1 DOWNTO 0);
--M00_AXI_RLAST        => p_in_mem.axir.dlast,                                --: IN STD_LOGIC;
--M00_AXI_RVALID       => p_in_mem.axir.dvalid,                               --: IN STD_LOGIC;
--M00_AXI_RREADY       => p_out_mem.axir.rready                               --: OUT STD_LOGIC
--);
--
--end generate gen_chcount_3;