-------------------------------------------------------------------------
-- Company     : Linkos
-- Engineer    : Golovachenko Victor
--
-- Create Date : 10.10.2011 15:55:15
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

  -- DDR3 bank reset
  -- Comment from coregen MIG3.6 DDR3 SDRAM interface
  -- iodelay_ctrl block
  -- # of clock cycles to delay deassertion of reset. Needs to be a fairly
  -- high number not so much for metastability protection, but to give time
  -- for reset (i.e. stable clock cycles) to propagate through all state
  -- machines and to all control signals (i.e. not all control signals have
  -- resets, instead they rely on base state logic being reset, and the effect
  -- of that reset propagating through the logic). Need this because we may not
  -- be getting stable clock cycles while reset asserted (i.e. since reset
  -- depends on DCM lock status)
  -- COMMENTED, RC, 01/13/09 - causes pack error in MAP w/ larger #
  constant RST_SYNC_NUM : integer := 15;

  signal rst_ref        : std_logic;
  signal rst_ref_sync_r : std_logic_vector(RST_SYNC_NUM-1 downto 0);

  -- DDR3 bank infrastructure signals
  signal iodelay_ctrl_rdy : std_logic;

  -- DDR3 attributes
  attribute IODELAY_GROUP : string;
  attribute IODELAY_GROUP of idelayctrl_i : label is MIG_V3_6_CLOCKS.IODELAY_GRP;

  attribute syn_maxfan : integer;
  attribute syn_maxfan of rst_ref_sync_r : signal is 10;

  type TSAXI_ID_t is array (0 to DDR3_BANKS-1) of std_logic_vector(C_AXIM_IDWIDTH-1 downto 0);
  signal i_saxi_bid : TSAXI_ID_t;
  signal i_saxi_rid : TSAXI_ID_t;
  signal i_clk      : std_logic_vector(DDR3_BANKS-1 downto 0);

begin

  --*****************************************************************
  -- IDELAYCTRL reset
  -- This assumes an external clock signal driving the IDELAYCTRL
  -- blocks. Otherwise, if a PLL drives IDELAYCTRL, then the PLL
  -- lock signal will need to be incorporated in this.
  --*****************************************************************

  process(p_in_sys.rst,p_in_sys.ref_clk)
  begin
    if (p_in_sys.rst = '1') then
      rst_ref_sync_r <= (others => '1');
    elsif rising_edge(p_in_sys.ref_clk) then
      rst_ref_sync_r <= std_logic_vector(unsigned(rst_ref_sync_r) sll 1);
    end if;
  end process;

  rst_ref <= rst_ref_sync_r(RST_SYNC_NUM-1);

  idelayctrl_i : IDELAYCTRL
  port map (
    RDY    => iodelay_ctrl_rdy,  -- out
    REFCLK => p_in_sys.ref_clk,      -- in
    RST    => rst_ref);          -- in

  p_out_sys.clk<=i_clk(0);

  ddr3_if_g : for n in 0 to DDR3_BANKS-1 generate

    p_out_mem(n).axiw.rid<=EXT(i_saxi_bid(n), p_out_mem(n).axiw.rid'length); --p_out_saxi_bid(n)<=EXT(i_saxi_bid(n), p_out_saxi_bid(n)'length);
    p_out_mem(n).axir.rid<=EXT(i_saxi_rid(n), p_out_mem(n).axir.rid'length); --p_out_saxi_rid(n)<=EXT(i_saxi_rid(n), p_out_saxi_rid(n)'length);
    p_out_mem(n).clk<=i_clk(n);

    ddr3_if_bank_i : memory_ctrl_core
    generic map(
      G_SIM          => G_SIM,
      G_AXI_IDWIDTH  => C_AXIM_IDWIDTH,
      G_AXI_AWIDTH   => C_AXI_AWIDTH,
      G_AXI_DWIDTH   => C_AXIM_DWIDTH,
      G_AXI_SUPPORTS_NARROW_BURST => C_AXI_SUPPORTS_NARROW_BURST,
      G_AXI_REG_EN0  => C_AXI_REG_EN0,
      G_AXI_REG_EN1  => C_AXI_REG_EN1,
      bank => n  -- integer range 0 to DDR3_BANKS-1 := 0)
      )
    port map(
      --// AXI Slave Interface:
      p_out_saxi_clk     => i_clk(n), --p_out_mem(n).clk, --p_out_saxi_clk(n),
      p_out_saxi_rstn    => p_out_mem(n).rstn,--p_out_saxi_rstn(n),
      --// Write Address Ports
      p_in_saxi_awid     => p_in_mem(n).axiw.aid(C_AXIM_IDWIDTH-1 downto 0), --p_in_saxi_awid(n)(C_AXIM_IDWIDTH-1 downto 0),
      p_in_saxi_awaddr   => p_in_mem(n).axiw.adr(C_AXI_AWIDTH-1 downto 0),  --p_in_saxi_awaddr(n)(C_AXI_AWIDTH-1 downto 0),
      p_in_saxi_awlen    => p_in_mem(n).axiw.trnlen ,                       --p_in_saxi_awlen(n),
      p_in_saxi_awsize   => p_in_mem(n).axiw.dbus   ,                       --p_in_saxi_awsize(n),
      p_in_saxi_awburst  => p_in_mem(n).axiw.burst  ,                       --p_in_saxi_awburst(n),
      p_in_saxi_awlock   => p_in_mem(n).axiw.lock   ,                       --p_in_saxi_awlock(n),--(0 downto 0),
      p_in_saxi_awcache  => p_in_mem(n).axiw.cache  ,                       --p_in_saxi_awcache(n),
      p_in_saxi_awprot   => p_in_mem(n).axiw.prot   ,                       --p_in_saxi_awprot(n),
      p_in_saxi_awqos    => p_in_mem(n).axiw.qos    ,                       --p_in_saxi_awqos(n),
      p_in_saxi_awvalid  => p_in_mem(n).axiw.avalid ,                       --p_in_saxi_awvalid(n),
      p_out_saxi_awready => p_out_mem(n).axiw.aready,                       --p_out_saxi_awready(n),
      --// Write Data Ports
      p_in_saxi_wdata    => p_in_mem(n).axiw.data(C_AXIM_DWIDTH-1 downto 0), --p_in_saxi_wdata(n)(C_AXIM_DWIDTH-1 downto 0),
      p_in_saxi_wstrb    => p_in_mem(n).axiw.dbe(C_AXIM_DWIDTH/8-1 downto 0),--p_in_saxi_wstrb(n)(C_AXIM_DWIDTH/8-1 downto 0),
      p_in_saxi_wlast    => p_in_mem(n).axiw.dlast  ,                       --p_in_saxi_wlast(n),
      p_in_saxi_wvalid   => p_in_mem(n).axiw.dvalid ,                       --p_in_saxi_wvalid(n),
      p_out_saxi_wready  => p_out_mem(n).axiw.wready,                       --p_out_saxi_wready(n),
      --// Write Response Ports
      p_out_saxi_bid     => i_saxi_bid(n)(C_AXIM_IDWIDTH-1 downto 0),
      p_out_saxi_bresp   => p_out_mem(n).axiw.resp  ,                       --p_out_saxi_bresp(n),
      p_out_saxi_bvalid  => p_out_mem(n).axiw.rvalid,                       --p_out_saxi_bvalid(n),
      p_in_saxi_bready   => p_in_mem(n).axiw.rready ,                       --p_in_saxi_bready(n),
      --// Read Address Ports
      p_in_saxi_arid     => p_in_mem(n).axir.aid(C_AXIM_IDWIDTH-1 downto 0), --p_in_saxi_arid(n)(C_AXIM_IDWIDTH-1 downto 0),
      p_in_saxi_araddr   => p_in_mem(n).axir.adr(C_AXI_AWIDTH-1 downto 0),  --p_in_saxi_araddr(n)(C_AXI_AWIDTH-1 downto 0),
      p_in_saxi_arlen    => p_in_mem(n).axir.trnlen ,                       --p_in_saxi_arlen(n),
      p_in_saxi_arsize   => p_in_mem(n).axir.dbus   ,                       --p_in_saxi_arsize(n),
      p_in_saxi_arburst  => p_in_mem(n).axir.burst  ,                       --p_in_saxi_arburst(n),
      p_in_saxi_arlock   => p_in_mem(n).axir.lock   ,                       --p_in_saxi_arlock(n),--(0 downto 0),
      p_in_saxi_arcache  => p_in_mem(n).axir.cache  ,                       --p_in_saxi_arcache(n),
      p_in_saxi_arprot   => p_in_mem(n).axir.prot   ,                       --p_in_saxi_arprot(n),
      p_in_saxi_arqos    => p_in_mem(n).axir.qos    ,                       --p_in_saxi_arqos(n),
      p_in_saxi_arvalid  => p_in_mem(n).axir.avalid ,                       --p_in_saxi_arvalid(n),
      p_out_saxi_arready => p_out_mem(n).axir.aready,                       --p_out_saxi_arready(n),
      --// Read Data Ports
      p_out_saxi_rid     => i_saxi_rid(n)(C_AXIM_IDWIDTH-1 downto 0),
      p_out_saxi_rdata   => p_out_mem(n).axir.data(C_AXIM_DWIDTH-1 downto 0),--p_out_saxi_rdata(n)(C_AXIM_DWIDTH-1 downto 0),
      p_out_saxi_rresp   => p_out_mem(n).axir.resp  ,                       --p_out_saxi_rresp(n),
      p_out_saxi_rlast   => p_out_mem(n).axir.dlast ,                       --p_out_saxi_rlast(n),
      p_out_saxi_rvalid  => p_out_mem(n).axir.dvalid,                       --p_out_saxi_rvalid(n),
      p_in_saxi_rready   => p_in_mem(n).axir.rready ,                       --p_in_saxi_rready(n),

      -- DDR3 Clocking
      ddr3_rst              => p_in_sys.rst,                          -- in    std_logic
      ddr3_ref_clk          => p_in_sys.ref_clk,                      -- in    std_logic
      ddr3_clk              => p_in_sys.clk,                          -- in    std_logic
      ddr3_iodelay_ctrl_rdy => iodelay_ctrl_rdy,                  -- in    std_logic
      -- DDR3 Status
      ddr3_if_rdy           => p_out_status.rdy(n),                     -- out   std_logic
      ddr3_if_stat          => p_out_status.stat(n),                    -- out   std_logic_vector(3 downto 0)
      ddr3_if_err           => p_out_status.err(n),                     -- out   std_logic_vector(3 downto 0)
      -- DDR3 Physical Interface
      ddr3_addr_out         => p_out_phymem.adr   (n), --mem_addr_out.ddr3_addr_out(n),     -- out   ddr3_addr_out_t
      ddr3_ctrl_out         => p_out_phymem.ctrl  (n),--mem_ctrl_out.ddr3_ctrl_out(n),     -- out   ddr3_ctrl_out_t
      ddr3_data_inout       => p_inout_phymem.data(n),--mem_data_inout.ddr3_data_inout(n), -- inout ddr3_data_inout_t
      ddr3_clk_out          => p_out_phymem.clk   (n),--mem_clk_out.ddr3_clk_out(n),       -- out   ddr3_clk_out_t
      -- DDR3 Interface Error info
      ddr3_if_debug         => p_out_status.err_info(n));               -- out   std_logic_vector(31 downto 0))
  end generate;

end;

----// AXI Slave Interface:
--p_out_saxi_clk     : out   std_logic_vector(0 to DDR3_BANKS-1);
--p_out_saxi_rstn    : out   std_logic_vector(0 to DDR3_BANKS-1);
----// Write Address Ports
--p_in_saxi_awid     : in    TAXI_id_width;
--p_in_saxi_awaddr   : in    TAXI_addr_width;
--p_in_saxi_awlen    : in    TAXI_bus08_width;
--p_in_saxi_awsize   : in    TAXI_bus03_width;
--p_in_saxi_awburst  : in    TAXI_bus02_width;
--p_in_saxi_awlock   : in    TAXI_bus01_width;--TAXI_bus02_width;
--p_in_saxi_awcache  : in    TAXI_bus04_width;
--p_in_saxi_awprot   : in    TAXI_bus03_width;
--p_in_saxi_awqos    : in    TAXI_bus04_width;
--p_in_saxi_awvalid  : in    std_logic_vector(0 to DDR3_BANKS-1);
--p_out_saxi_awready : out   std_logic_vector(0 to DDR3_BANKS-1);
----// Write Data Ports
--p_in_saxi_wdata    : in    TAXI_data_width;
--p_in_saxi_wstrb    : in    TAXI_databe_width;
--p_in_saxi_wlast    : in    std_logic_vector(0 to DDR3_BANKS-1);
--p_in_saxi_wvalid   : in    std_logic_vector(0 to DDR3_BANKS-1);
--p_out_saxi_wready  : out   std_logic_vector(0 to DDR3_BANKS-1);
----// Write Response Ports
--p_out_saxi_bid     : out   TAXI_id_width;
--p_out_saxi_bresp   : out   TAXI_bus02_width;
--p_out_saxi_bvalid  : out   std_logic_vector(0 to DDR3_BANKS-1);
--p_in_saxi_bready   : in    std_logic_vector(0 to DDR3_BANKS-1);
----// Read Address Ports
--p_in_saxi_arid     : in    TAXI_id_width;
--p_in_saxi_araddr   : in    TAXI_addr_width;
--p_in_saxi_arlen    : in    TAXI_bus08_width;
--p_in_saxi_arsize   : in    TAXI_bus03_width;
--p_in_saxi_arburst  : in    TAXI_bus02_width;
--p_in_saxi_arlock   : in    TAXI_bus01_width;--TAXI_bus02_width;
--p_in_saxi_arcache  : in    TAXI_bus04_width;
--p_in_saxi_arprot   : in    TAXI_bus03_width;
--p_in_saxi_arqos    : in    TAXI_bus04_width;
--p_in_saxi_arvalid  : in    std_logic_vector(0 to DDR3_BANKS-1);
--p_out_saxi_arready : out   std_logic_vector(0 to DDR3_BANKS-1);
----// Read Data Ports
--p_out_saxi_rid     : out   TAXI_id_width;
--p_out_saxi_rdata   : out   TAXI_data_width;
--p_out_saxi_rresp   : out   TAXI_bus02_width;
--p_out_saxi_rlast   : out   std_logic_vector(0 to DDR3_BANKS-1);
--p_out_saxi_rvalid  : out   std_logic_vector(0 to DDR3_BANKS-1);
--p_in_saxi_rready   : in    std_logic_vector(0 to DDR3_BANKS-1);
