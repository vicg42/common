-------------------------------------------------------------------------
-- Company     : Linkos
-- Engineer    : Golovachenko Victor
--
-- Create Date : 29.03.2012 13:12:10
-- Module Name : mem_ctrl
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
use ieee.numeric_std.all;
use ieee.std_logic_arith.ext;

library unisim;
use unisim.vcomponents.all;

library work;
use work.mem_ctrl_pkg.all;
use work.mem_wr_pkg.all;

entity mem_ctrl is
generic(
G_SIM : string:= "OFF"
);
port(
------------------------------------
--User Post
------------------------------------
p_in_mem       : in    TMemINBank;
p_out_mem      : out   TMemOUTBank;

------------------------------------
--Memory physical interface
------------------------------------
p_out_phymem   : out   TMEMCTRL_phy_outs;
p_inout_phymem : inout TMEMCTRL_phy_inouts;

------------------------------------
--Memory status
------------------------------------
p_out_status   : out   TMEMCTRL_status;

------------------------------------
--System
------------------------------------
p_out_sys      : out   TMEMCTRL_sysout;
p_in_sys       : in    TMEMCTRL_sysin
);
end;

architecture synth of mem_ctrl is

type TSAXI_ID_t is array (0 to C_MEM_BANK_COUNT-1) of std_logic_vector(C_AXIM_IDWIDTH-1 downto 0);
signal i_saxi_bid : TSAXI_ID_t;
signal i_saxi_rid : TSAXI_ID_t;
signal i_clk      : std_logic_vector(C_MEM_BANK_COUNT-1 downto 0);
signal g_sys_clkout: std_logic_vector(C_MEM_BANK_COUNT-1 downto 0);
signal i_rst_n : std_logic;
signal ui_clk_sync_rst: std_logic_vector(C_MEM_BANK_COUNT-1 downto 0);
signal i_aresetn      : std_logic_vector(C_MEM_BANK_COUNT-1 downto 0);
signal i_mmcm_locked   : std_logic_vector(C_MEM_BANK_COUNT-1 downto 0);
signal i_calib_complete: std_logic_vector(C_MEM_BANK_COUNT-1 downto 0);

signal tst_mmcm_locked    : std_logic;
signal tst_calib_complete : std_logic;
signal tst_ui_clk_sync_rst : std_logic;
signal tst_in_sys_rst      : std_logic;
signal tst_status_rdy      : std_logic;

--MAIN
begin

p_out_sys.clk<=g_sys_clkout(0);

gen_bank : for i in 0 to C_MEM_BANK_COUNT-1 generate

p_out_mem(i).axiw.rid<=EXT(i_saxi_bid(i), p_out_mem(i).axiw.rid'length); --p_out_saxi_bid(i)<=EXT(i_saxi_bid(i), p_out_saxi_bid(i)'length);
p_out_mem(i).axir.rid<=EXT(i_saxi_rid(i), p_out_mem(i).axir.rid'length); --p_out_saxi_rid(i)<=EXT(i_saxi_rid(i), p_out_saxi_rid(i)'length);
p_out_mem(i).clk<=i_clk(i);

p_out_mem(i).rstn <= ui_clk_sync_rst(i);
i_aresetn(i) <= not ui_clk_sync_rst(i);

m_mem_core : mem_ctrl_core_axi
port map(
ui_clk_sync_rst=> ui_clk_sync_rst(i),--p_out_mem(i).rstn,--aresetn       => p_out_mem(i).rstn,
ui_clk         => g_sys_clkout(i),  --s_axi_clk     => i_clk(i),


--// AXI Slave Interface:
--s_axi_clk     => p_out_mem(i).clk, --p_out_saxi_clk(i),
--s_axi_rstn    => p_out_mem(i).rstn,--p_out_saxi_rstn(i),

--// Write Address Ports
s_axi_awid     => p_in_mem (i).axiw.aid(C_AXIM_IDWIDTH-1 downto 0),--p_in_saxi_awid(i)(G_AXI_IDWIDTH-1 downto 0),
s_axi_awaddr   => p_in_mem (i).axiw.adr(C_AXI_AWIDTH-1 downto 0)  ,--p_in_saxi_awaddr(i)(G_AXI_AWIDTH-1 downto 0),
s_axi_awlen    => p_in_mem (i).axiw.trnlen                        ,--p_in_saxi_awlen(i),
s_axi_awsize   => p_in_mem (i).axiw.dbus                          ,--p_in_saxi_awsize(i),
s_axi_awburst  => p_in_mem (i).axiw.burst                         ,--p_in_saxi_awburst(i),
s_axi_awlock   => p_in_mem (i).axiw.lock                          ,--p_in_saxi_awlock(i),--(0 downto 0),
s_axi_awcache  => p_in_mem (i).axiw.cache                         ,--p_in_saxi_awcache(i),
s_axi_awprot   => p_in_mem (i).axiw.prot                          ,--p_in_saxi_awprot(i),
s_axi_awqos    => p_in_mem (i).axiw.qos                           ,--p_in_saxi_awqos(i),
s_axi_awvalid  => p_in_mem (i).axiw.avalid                        ,--p_in_saxi_awvalid(i),
s_axi_awready  => p_out_mem(i).axiw.aready                        ,--p_out_saxi_awready(i),
--// Write Data Ports
s_axi_wdata    => p_in_mem (i).axiw.data(C_AXI_DWIDTH-1 downto 0) ,--p_in_saxi_wdata(i)(G_AXI_DWIDTH-1 downto 0),
s_axi_wstrb    => p_in_mem (i).axiw.dbe(C_AXI_DWIDTH/8-1 downto 0),--p_in_saxi_wstrb(i)(G_AXI_DWIDTH/8-1 downto 0),
s_axi_wlast    => p_in_mem (i).axiw.dlast                         ,--p_in_saxi_wlast(i),
s_axi_wvalid   => p_in_mem (i).axiw.dvalid                        ,--p_in_saxi_wvalid(i),
s_axi_wready   => p_out_mem(i).axiw.wready                        ,--p_out_saxi_wready(i),
--// Write Response Ports
s_axi_bid      => i_saxi_bid(i)(C_AXIM_IDWIDTH-1 downto 0)        ,
s_axi_bresp    => p_out_mem(i).axiw.resp                          ,--p_out_saxi_bresp(i),
s_axi_bvalid   => p_out_mem(i).axiw.rvalid                        ,--p_out_saxi_bvalid(i),
s_axi_bready   => p_in_mem (i).axiw.rready                        ,--p_in_saxi_bready(i),
--// Read Address Ports
s_axi_arid     => p_in_mem (i).axir.aid(C_AXIM_IDWIDTH-1 downto 0),--p_in_saxi_arid(i)(G_AXI_IDWIDTH-1 downto 0),
s_axi_araddr   => p_in_mem (i).axir.adr(C_AXI_AWIDTH-1 downto 0)  ,--p_in_saxi_araddr(i)(G_AXI_AWIDTH-1 downto 0),
s_axi_arlen    => p_in_mem (i).axir.trnlen                        ,--p_in_saxi_arlen(i),
s_axi_arsize   => p_in_mem (i).axir.dbus                          ,--p_in_saxi_arsize(i),
s_axi_arburst  => p_in_mem (i).axir.burst                         ,--p_in_saxi_arburst(i),
s_axi_arlock   => p_in_mem (i).axir.lock                          ,--p_in_saxi_arlock(i),--(0 downto 0),
s_axi_arcache  => p_in_mem (i).axir.cache                         ,--p_in_saxi_arcache(i),
s_axi_arprot   => p_in_mem (i).axir.prot                          ,--p_in_saxi_arprot(i),
s_axi_arqos    => p_in_mem (i).axir.qos                           ,--p_in_saxi_arqos(i),
s_axi_arvalid  => p_in_mem (i).axir.avalid                        ,--p_in_saxi_arvalid(i),
s_axi_arready  => p_out_mem(i).axir.aready                        ,--p_out_saxi_arready(i),
--// Read Data Ports
s_axi_rid      => i_saxi_rid(i)(C_AXIM_IDWIDTH-1 downto 0)        ,
s_axi_rdata    => p_out_mem(i).axir.data(C_AXI_DWIDTH-1 downto 0) ,--p_out_saxi_rdata(i)(G_AXI_DWIDTH-1 downto 0),
s_axi_rresp    => p_out_mem(i).axir.resp                          ,--p_out_saxi_rresp(i),
s_axi_rlast    => p_out_mem(i).axir.dlast                         ,--p_out_saxi_rlast(i),
s_axi_rvalid   => p_out_mem(i).axir.dvalid                        ,--p_out_saxi_rvalid(i),
s_axi_rready   => p_in_mem (i).axir.rready                        ,--p_in_saxi_rready(i),

-- DDR3 Physical Interface
ddr3_dq         => p_inout_phymem(i).dq   ,--inout  [DQ_WIDTH-1:0]
ddr3_addr       => p_out_phymem  (i).a    ,--output [ROW_WIDTH-1:0]
ddr3_ba         => p_out_phymem  (i).ba   ,--output [BANK_WIDTH-1:0]
ddr3_ras_n      => p_out_phymem  (i).ras_n,--output
ddr3_cas_n      => p_out_phymem  (i).cas_n,--output
ddr3_we_n       => p_out_phymem  (i).we_n ,--output
ddr3_reset_n    => p_out_phymem  (i).rst_n,--output
ddr3_cs_n       => p_out_phymem  (i).cs_n ,--output [(CS_WIDTH*nCS_PER_RANK)-1:0]
ddr3_odt        => p_out_phymem  (i).odt  ,--output [(CS_WIDTH*nCS_PER_RANK)-1:0]
ddr3_cke        => p_out_phymem  (i).cke  ,--output [CKE_WIDTH-1:0]
ddr3_dm         => p_out_phymem  (i).dm   ,--output [DM_WIDTH-1:0]
ddr3_dqs_p      => p_inout_phymem(i).dqs_p,--inout  [DQS_WIDTH-1:0]
ddr3_dqs_n      => p_inout_phymem(i).dqs_n,--inout  [DQS_WIDTH-1:0]
ddr3_ck_p       => p_out_phymem  (i).ck_p ,--output [CK_WIDTH-1:0]
ddr3_ck_n       => p_out_phymem  (i).ck_n ,--output [CK_WIDTH-1:0]
--sda             => open,--p_inout_phymem(i).sda  ,--inout
--scl             => open,--p_out_phymem  (i).scl  ,--out

--AXI CTRL port
s_axi_ctrl_awvalid => '0',
s_axi_ctrl_awready => open,
s_axi_ctrl_awaddr  => (others=>'0'),
s_axi_ctrl_wvalid  => '0',
s_axi_ctrl_wready  => open,
s_axi_ctrl_wdata   => (others=>'0'),
s_axi_ctrl_bvalid  => open,
s_axi_ctrl_bready  => '1',
s_axi_ctrl_bresp   => open,
s_axi_ctrl_arvalid => '0',
s_axi_ctrl_arready => open,
s_axi_ctrl_araddr  => (others=>'0'),
s_axi_ctrl_rvalid  => open,
s_axi_ctrl_rready  => '1',
s_axi_ctrl_rdata   => open,
s_axi_ctrl_rresp   => open,

interrupt          => open,

--Status
init_calib_complete=> p_out_status.rdy(i),--i_calib_complete(i),--
app_ecc_multiple_err => open,

mmcm_locked         => i_mmcm_locked(i),

aresetn             => i_aresetn(i),
app_sr_req          => '0',
app_sr_active       => open,
app_ref_req         => '0',
app_ref_ack         => open,
app_zq_req          => '0',
app_zq_ack          => open,

device_temp_i       => (others=>'0'),

--System
--sys_clkout      => open,--g_sys_clkout(i),
sys_clk_i       => p_in_sys.clk    ,--input   ,    //single ended system clocks
clk_ref_i       => p_in_sys.ref_clk,--input   ,     //single ended iodelayctrl clk
sys_rst         => p_in_sys.rst     --input
);

end generate gen_bank;

--process(g_sys_clkout)
--begin
--  if rising_edge(g_sys_clkout(0)) then
--    tst_mmcm_locked <= i_mmcm_locked(0);
--    tst_calib_complete <= i_calib_complete(0);
--    tst_ui_clk_sync_rst <= ui_clk_sync_rst(0);
--    tst_in_sys_rst <= p_in_sys.rst;
--
--tst_status_rdy <= tst_calib_complete and (tst_mmcm_locked)
--                    and (not tst_ui_clk_sync_rst) and (not tst_in_sys_rst);
--  end if;
--end process;
--
--p_out_status.rdy(0) <= tst_status_rdy;


--END MAIN
end;

