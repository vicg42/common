-------------------------------------------------------------------------
-- Company     : Linkos
-- Engineer    : Golovachenko Victor
--
-- Create Date : 20.01.2011 11:43:14
-- Module Name : memory_ctrl_core
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
use ieee.std_logic_unsigned.all;

Library UNISIM;
use UNISIM.vcomponents.all;

library work;
use work.mem_ctrl_pkg.all;

entity memory_ctrl_core is
generic(
G_SIM          : string:= "OFF";
G_AXI_IDWIDTH  : integer:= 4;
G_AXI_AWIDTH   : integer:= 32;
G_AXI_DWIDTH   : integer:= 32;
G_AXI_SUPPORTS_NARROW_BURST: integer:= 1;
G_AXI_REG_EN0  : integer:= 0;
G_AXI_REG_EN1  : integer:= 0;
bank : in    integer range 0 to DDR3_BANKS-1 := 0);
port(
--// AXI Slave Interface:
p_out_saxi_clk     : out   std_logic;
p_out_saxi_rstn    : out   std_logic;
--// Write Address Ports
p_in_saxi_awid     : in    std_logic_vector(G_AXI_IDWIDTH-1 downto 0);
p_in_saxi_awaddr   : in    std_logic_vector(G_AXI_AWIDTH-1 downto 0);
p_in_saxi_awlen    : in    std_logic_vector(7 downto 0);
p_in_saxi_awsize   : in    std_logic_vector(2 downto 0);
p_in_saxi_awburst  : in    std_logic_vector(1 downto 0);
p_in_saxi_awlock   : in    std_logic_vector(0 downto 0);
p_in_saxi_awcache  : in    std_logic_vector(3 downto 0);
p_in_saxi_awprot   : in    std_logic_vector(2 downto 0);
p_in_saxi_awqos    : in    std_logic_vector(3 downto 0);
p_in_saxi_awvalid  : in    std_logic;
p_out_saxi_awready : out   std_logic;
--// Write Data Ports
p_in_saxi_wdata    : in    std_logic_vector(G_AXI_DWIDTH-1 downto 0);
p_in_saxi_wstrb    : in    std_logic_vector(G_AXI_DWIDTH/8-1 downto 0);
p_in_saxi_wlast    : in    std_logic;
p_in_saxi_wvalid   : in    std_logic;
p_out_saxi_wready  : out   std_logic;
--// Write Response Ports
p_out_saxi_bid     : out   std_logic_vector(G_AXI_IDWIDTH-1 downto 0);
p_out_saxi_bresp   : out   std_logic_vector(1 downto 0);
p_out_saxi_bvalid  : out   std_logic;
p_in_saxi_bready   : in    std_logic;
--// Read Address Ports
p_in_saxi_arid     : in    std_logic_vector(G_AXI_IDWIDTH-1 downto 0);
p_in_saxi_araddr   : in    std_logic_vector(G_AXI_AWIDTH-1 downto 0);
p_in_saxi_arlen    : in    std_logic_vector(7 downto 0);
p_in_saxi_arsize   : in    std_logic_vector(2 downto 0);
p_in_saxi_arburst  : in    std_logic_vector(1 downto 0);
p_in_saxi_arlock   : in    std_logic_vector(0 downto 0);
p_in_saxi_arcache  : in    std_logic_vector(3 downto 0);
p_in_saxi_arprot   : in    std_logic_vector(2 downto 0);
p_in_saxi_arqos    : in    std_logic_vector(3 downto 0);
p_in_saxi_arvalid  : in    std_logic;
p_out_saxi_arready : out   std_logic;
--// Read Data Ports
p_out_saxi_rid     : out   std_logic_vector(G_AXI_IDWIDTH-1 downto 0);
p_out_saxi_rdata   : out   std_logic_vector(G_AXI_DWIDTH-1 downto 0);
p_out_saxi_rresp   : out   std_logic_vector(1 downto 0);
p_out_saxi_rlast   : out   std_logic;
p_out_saxi_rvalid  : out   std_logic;
p_in_saxi_rready   : in    std_logic;

-- Memory interface
ddr3_rst              : in    std_logic;
ddr3_ref_clk          : in    std_logic;
ddr3_clk              : in    std_logic;
ddr3_iodelay_ctrl_rdy : in    std_logic;

-- Memory status
ddr3_if_rdy           : out   std_logic;
ddr3_if_stat          : out   std_logic_vector(3 downto 0);
ddr3_if_err           : out   std_logic_vector(3 downto 0);

-- Physical memory interface
ddr3_addr_out         : out   ddr3_addr_out_t;
ddr3_ctrl_out         : out   ddr3_ctrl_out_t;
ddr3_data_inout       : inout ddr3_data_inout_t;
ddr3_clk_out          : out   ddr3_clk_out_t;
-- Debug info
ddr3_if_debug         : out   std_logic_vector(31 downto 0)
);
end;


architecture synth of memory_ctrl_core is

  -- MIG v3.6 infrasructure
  component infrastructure
  generic(
    TCQ             : integer;
    CLK_PERIOD      : integer;
    nCK_PER_CLK     : integer;
    CLKFBOUT_MULT_F : integer;
    DIVCLK_DIVIDE   : integer;
    CLKOUT_DIVIDE   : integer;
    RST_ACT_LOW     : integer);
  port(
    clk_mem          : out std_logic;
    clk              : out std_logic;
    clk_rd_base      : out std_logic;
    rstdiv0          : out std_logic;
    mmcm_clk         : in  std_logic;
    sys_rst          : in  std_logic;
    iodelay_ctrl_rdy : in  std_logic;
    PSDONE           : out std_logic;
    PSEN             : in  std_logic;
    PSINCDEC         : in  std_logic);
  end component;

  -- Constants for MIG simulation options
  constant MIG_V3_6_SIM_BYPASS_INIT_CAL : string := conv_sim_bypass_init_cal(G_SIM);--(TARGET_USE);
  constant MIG_V3_6_SIM_INIT_OPTION     : string := conv_sim_init_option(G_SIM);--(TARGET_USE);
  constant MIG_V3_6_SIM_CAL_OPTION      : string := conv_sim_cal_option(G_SIM);--(TARGET_USE);

  -- Constants for MIG generic defaults
  constant PAYLOAD_WIDTH_D : natural := MIG_V3_6_COMMON.PAYLOAD_WIDTH;
  constant ROW_WIDTH_D     : natural := MIG_V3_6_COMMON.ROW_WIDTH;
  constant COL_WIDTH_D     : natural := MIG_V3_6_COMMON.COL_WIDTH;
  constant BANK_WIDTH_D    : natural := MIG_V3_6_COMMON.BANK_WIDTH;
  constant ADDR_WIDTH_D    : natural := MIG_V3_6_COMMON.ADDR_WIDTH;
  constant DQS_WIDTH_D     : natural := MIG_V3_6_COMMON.DQS_WIDTH;
  constant DQS_CNT_WIDTH_D : natural := MIG_V3_6_COMMON.DQS_CNT_WIDTH;
  constant DQ_WIDTH_D      : natural := MIG_V3_6_COMMON.DQ_WIDTH;
  constant TCQ_D           : natural := MIG_V3_6_COMMON.TCQ;

  constant SYSCLK_PERIOD : integer := MIG_V3_6_CLOCKS.tCK * MIG_V3_6_CLOCKS.nCK_PER_CLK;

  -- memc_ui_top types
  subtype app_addr_t     is std_logic_vector(ADDR_WIDTH_D-1 downto 0);
  subtype app_wdf_data_t is std_logic_vector((4*PAYLOAD_WIDTH_D)-1 downto 0);
  subtype app_wdf_mask_t is std_logic_vector((4*PAYLOAD_WIDTH_D)/8-1 downto 0);
  subtype app_cmd_t      is std_logic_vector(2 downto 0);
  subtype app_rd_data_t  is std_logic_vector((4*PAYLOAD_WIDTH_D)-1 downto 0);

  signal mig_rst           : std_logic;
  signal mig_ddr3_if_clk0  : std_logic;
  signal mig_ddr3_if_clk1  : std_logic;
  signal mig_ddr3_if_clk2  : std_logic;
  signal mig_ddr3_if_clk3  : std_logic;
  signal mig_clk_mem       : std_logic;
  signal mig_clk_rd_base   : std_logic;
  signal pd_psdone         : std_logic;
  signal pd_psen           : std_logic;
  signal pd_psincdec       : std_logic;
  signal dfi_init_complete : std_logic;

  -- memc_ui_top signals
  signal app_sz            : std_logic;
  signal app_wdf_wren      : std_logic;
  signal app_wdf_data      : app_wdf_data_t;
  signal app_wdf_mask      : app_wdf_mask_t;
  signal app_wdf_end       : std_logic;
  signal app_addr          : app_addr_t;
  signal app_cmd           : app_cmd_t;
  signal app_en            : std_logic;
  signal app_rdy           : std_logic;
  signal app_wdf_rdy       : std_logic;
  signal app_rd_data       : app_rd_data_t;
  signal app_rd_data_valid : std_logic;

  -- Debug types
  subtype dqs_width_1_t   is std_logic_vector(1*DQS_WIDTH_D-1 downto 0);
  subtype dqs_width_2_t   is std_logic_vector(2*DQS_WIDTH_D-1 downto 0);
  subtype dqs_width_3_t   is std_logic_vector(3*DQS_WIDTH_D-1 downto 0);
  subtype dqs_width_5_t   is std_logic_vector(5*DQS_WIDTH_D-1 downto 0);
  subtype dqs_cnt_width_t is std_logic_vector(DQS_CNT_WIDTH_D-1 downto 0);
  subtype dq_width_4_t    is std_logic_vector(4*DQ_WIDTH_D-1 downto 0);

  -- Debug input signals
  signal dbg_dec_cpt               : std_logic       := '0';
  signal dbg_dec_rd_dqs            : std_logic       := '0';
  signal dbg_dec_rd_fps            : std_logic       := '0';
  signal dbg_inc_cpt               : std_logic       := '0';
  signal dbg_inc_dec_sel           : dqs_cnt_width_t := (others => '0');
  signal dbg_inc_rd_dqs            : std_logic       := '0';
  signal dbg_inc_rd_fps            : std_logic       := '0';
  signal dbg_pd_off                : std_logic       := '0';
  signal dbg_pd_maintain_off       : std_logic       := '0';
  signal dbg_pd_maintain_0_only    : std_logic       := '0';
  signal dbg_wr_dq_tap_set         : dqs_width_5_t   := (others => '0');
  signal dbg_wr_dqs_tap_set        : dqs_width_5_t   := (others => '0');
  signal dbg_wr_tap_set_en         : std_logic       := '0';

  -- Debug output signals
  signal dbg_cpt_first_edge_cnt    : dqs_width_5_t;
  signal dbg_cpt_second_edge_cnt   : dqs_width_5_t;
  signal dbg_cpt_tap_cnt           : dqs_width_5_t;
  signal dbg_dq_tap_cnt            : dqs_width_5_t;
  signal dbg_dqs_tap_cnt           : dqs_width_5_t;
  signal dbg_rd_active_dly         : std_logic_vector(4 downto 0);
  signal dbg_rd_bitslip_cnt        : dqs_width_3_t;
  signal dbg_rd_clkdly_cnt         : dqs_width_2_t;
  signal dbg_rddata                : dq_width_4_t;
  signal dbg_rdlvl_done            : std_logic_vector(1 downto 0);
  signal dbg_rdlvl_err             : std_logic_vector(1 downto 0);
  signal dbg_rdlvl_start           : std_logic_vector(1 downto 0);
  signal dbg_wl_dqs_inverted       : dqs_width_1_t;
  signal dbg_wl_odelay_dq_tap_cnt  : dqs_width_5_t;
  signal dbg_wl_odelay_dqs_tap_cnt : dqs_width_5_t;
  signal dbg_wr_calib_clk_delay    : dqs_width_2_t;
  signal dbg_wrlvl_done            : std_logic;
  signal dbg_wrlvl_err             : std_logic;
  signal dbg_wrlvl_start           : std_logic;

  attribute keep : string;
--  attribute keep of mig_ddr3_if_clk0 : signal is "true";
  attribute keep of mig_ddr3_if_clk1 : signal is "true";
  attribute keep of mig_ddr3_if_clk2 : signal is "true";
  attribute keep of mig_ddr3_if_clk3 : signal is "true";

begin

  -- Check MIG interface address widths
  assert not(DDR3_BANK_ROW_WIDTH /= MIG_V3_6_COMMON.ROW_WIDTH)
    report "(ddr3_if_bank): MIG ROW_WIDTH /= target_inc_pkg DDR3_BANK_ROW_WIDTH"
    severity failure;

  -- Should be Rank(1)+Bank(3)+Row(13/14)+Col(10) and remove Rank (-1) and convert to byte addressing (+2)
  assert not(DDR3_BYTE_ADDR_WIDTH /= (MIG_V3_6_COMMON.ADDR_WIDTH - 1 + 2))
    report "(ddr3_if_bank): MIG ADDR_WIDTH /= target_inc_pkg DDR3_BYTE_ADDR_WIDTH"
    severity failure;

  assert not(DDR3_BANK_DATA_WIDTH /= MIG_V3_6_COMMON.DQ_WIDTH)
    report "(ddr3_if_bank): MIG DQ_WIDTH /= target_inc_pkg DDR3_BANK_DATA_WIDTH"
    severity failure;

  -- Instantiate DDR3 MIG bank 0 core
  bank0_g : if (bank = 0) generate

  memc_ui_top_i : entity work.c0_memc_ui_top(arch_c0_memc_ui_top)
  generic map(
    ADDR_CMD_MODE       => MIG_V3_6_COMMON.ADDR_CMD_MODE,
    BANK_WIDTH          => MIG_V3_6_COMMON.BANK_WIDTH,
    CK_WIDTH            => MIG_V3_6_COMMON.CK_WIDTH,
    CKE_WIDTH           => MIG_V3_6_COMMON.CKE_WIDTH,
    nCK_PER_CLK         => MIG_V3_6_CLOCKS.nCK_PER_CLK,
    COL_WIDTH           => MIG_V3_6_COMMON.COL_WIDTH,
    CS_WIDTH            => MIG_V3_6_COMMON.CS_WIDTH,
    DM_WIDTH            => MIG_V3_6_COMMON.DM_WIDTH,
    nCS_PER_RANK        => MIG_V3_6_COMMON.nCS_PER_RANK,
    DEBUG_PORT          => MIG_V3_6_COMMON.DEBUG_PORT,
    IODELAY_GRP         => MIG_V3_6_CLOCKS.IODELAY_GRP,
    DQ_WIDTH            => MIG_V3_6_COMMON.DQ_WIDTH,
    DQS_WIDTH           => MIG_V3_6_COMMON.DQS_WIDTH,
    DQS_CNT_WIDTH       => MIG_V3_6_COMMON.DQS_CNT_WIDTH,
    ORDERING            => MIG_V3_6_COMMON.ORDERING,
    OUTPUT_DRV          => MIG_V3_6_COMMON.OUTPUT_DRV,
    PHASE_DETECT        => MIG_V3_6_COMMON.PHASE_DETECT,
    RANK_WIDTH          => MIG_V3_6_COMMON.RANK_WIDTH,
    REFCLK_FREQ         => MIG_V3_6_CLOCKS.REFCLK_FREQ,
    REG_CTRL            => MIG_V3_6_COMMON.REG_CTRL,
    ROW_WIDTH           => MIG_V3_6_COMMON.ROW_WIDTH,
    RTT_NOM             => MIG_V3_6_COMMON.RTT_NOM,
    RTT_WR              => MIG_V3_6_COMMON.RTT_WR,
    SIM_BYPASS_INIT_CAL => MIG_V3_6_SIM_BYPASS_INIT_CAL,
    SIM_CAL_OPTION      => MIG_V3_6_SIM_CAL_OPTION,
    SIM_INIT_OPTION     => MIG_V3_6_SIM_INIT_OPTION,
    WRLVL               => MIG_V3_6_COMMON.WRLVL,
    nDQS_COL0           => MIG_V3_6_BANK01.nDQS_COL0,
    nDQS_COL1           => MIG_V3_6_BANK01.nDQS_COL1,
    nDQS_COL2           => MIG_V3_6_BANK01.nDQS_COL2,
    nDQS_COL3           => MIG_V3_6_BANK01.nDQS_COL3,
    DQS_LOC_COL0        => MIG_V3_6_BANK01.DQS_LOC_COL0,
    DQS_LOC_COL1        => MIG_V3_6_BANK01.DQS_LOC_COL1,
    DQS_LOC_COL2        => MIG_V3_6_BANK01.DQS_LOC_COL2,
    DQS_LOC_COL3        => MIG_V3_6_BANK01.DQS_LOC_COL3,
    BURST_MODE          => MIG_V3_6_COMMON.BURST_MODE,
    BM_CNT_WIDTH        => MIG_V3_6_COMMON.BM_CNT_WIDTH,
    tCK                 => MIG_V3_6_CLOCKS.tCK,
    tPRDI               => MIG_V3_6_COMMON.tPRDI,
    tREFI               => MIG_V3_6_COMMON.tREFI,
    tZQI                => MIG_V3_6_COMMON.tZQI,
    tRFC                => MIG_V3_6_COMMON.tRFC,
    ADDR_WIDTH          => MIG_V3_6_COMMON.ADDR_WIDTH,
    TCQ                 => MIG_V3_6_COMMON.TCQ,
    ECC_TEST            => MIG_V3_6_COMMON.ECC_TEST,
    PAYLOAD_WIDTH       => MIG_V3_6_COMMON.PAYLOAD_WIDTH,

    G_AXI_IDWIDTH              =>G_AXI_IDWIDTH  ,
    G_AXI_AWIDTH               =>G_AXI_AWIDTH   ,
    G_AXI_DWIDTH               =>G_AXI_DWIDTH   ,
    G_AXI_SUPPORTS_NARROW_BURST=>G_AXI_SUPPORTS_NARROW_BURST,
    G_AXI_REG_EN0              =>G_AXI_REG_EN0  ,
    G_AXI_REG_EN1              =>G_AXI_REG_EN1
    )
  port map(
    clk                       => mig_ddr3_if_clk0,           -- in    std_logic
    clk_mem                   => mig_clk_mem,                -- in    std_logic
    clk_rd_base               => mig_clk_rd_base,            -- in    std_logic
    rst                       => mig_rst,                    -- in    std_logic
    ddr_addr                  => ddr3_addr_out.a,            -- out   std_logic_vector(ROW_WIDTH-1 downto 0)
    ddr_ba                    => ddr3_ctrl_out.ba,           -- out   std_logic_vector(BANK_WIDTH-1 downto 0)
    ddr_cas_n                 => ddr3_ctrl_out.cas_l,        -- out   std_logic
    ddr_ck_n                  => ddr3_clk_out.clk_n,         -- out   std_logic_vector(CK_WIDTH-1 downto 0)
    ddr_ck                    => ddr3_clk_out.clk_p,         -- out   std_logic_vector(CK_WIDTH-1 downto 0)
    ddr_cke                   => ddr3_ctrl_out.cke,          -- out   std_logic_vector(CKE_WIDTH-1 downto 0)
    ddr_cs_n                  => ddr3_ctrl_out.cs_l,         -- out   std_logic_vector(CS_WIDTH*nCS_PER_RANK-1 downto 0)
    ddr_dm                    => ddr3_ctrl_out.dm,           -- out   std_logic_vector(DM_WIDTH-1 downto 0)
    ddr_odt                   => ddr3_ctrl_out.odt,          -- out   std_logic_vector(CS_WIDTH*nCS_PER_RANK-1 downto 0)
    ddr_ras_n                 => ddr3_ctrl_out.ras_l,        -- out   std_logic
    ddr_reset_n               => ddr3_ctrl_out.reset_l,      -- out   std_logic
    ddr_parity                => open,                       -- out   std_logic
    ddr_we_n                  => ddr3_ctrl_out.we_l,         -- out   std_logic
    ddr_dq                    => ddr3_data_inout.dq,         -- inout std_logic_vector(DQ_WIDTH-1 downto 0)
    ddr_dqs_n                 => ddr3_data_inout.dqs_n,      -- inout std_logic_vector(DQS_WIDTH-1 downto 0)
    ddr_dqs                   => ddr3_data_inout.dqs_p,      -- inout std_logic_vector(DQS_WIDTH-1 downto 0)

    pd_PSEN                   => pd_psen,                    -- out   std_logic
    pd_PSINCDEC               => pd_psincdec,                -- out   std_logic
    pd_PSDONE                 => pd_psdone,                  -- in    std_logic
    dfi_init_complete         => dfi_init_complete,          -- out   std_logic
--    bank_mach_next            => open,                       -- out   std_logic_vector(BM_CNT_WIDTH-1 downto 0)
--    app_ecc_multiple_err      => open,                       -- out   std_logic_vector(3 downto 0)
--    app_rd_data               => app_rd_data,                -- out   std_logic_vector(APP_DATA_WIDTH-1 downto 0)
--    app_rd_data_end           => open,                       -- out   std_logic
--    app_rd_data_valid         => app_rd_data_valid,          -- out   std_logic
--    app_rdy                   => app_rdy,                    -- out   std_logic
--    app_wdf_rdy               => app_wdf_rdy,                -- out   std_logic
--    app_addr                  => app_addr,                   -- in    std_logic_vector(ADDR_WIDTH-1 downto 0)
--    app_cmd                   => app_cmd,                    -- in    std_logic_vector(2 downto 0)
--    app_en                    => app_en,                     -- in    std_logic
--    app_hi_pri                => '0',                        -- in    std_logic
--    app_sz                    => app_sz,                     -- in    std_logic
--    app_wdf_data              => app_wdf_data,               -- in    std_logic_vector(APP_DATA_WIDTH-1 downto 0)
--    app_wdf_end               => app_wdf_end,                -- in    std_logic
--    app_wdf_mask              => app_wdf_mask,               -- in    std_logic_vector(APP_MASK_WIDTH-1 downto 0)
--    app_wdf_wren              => app_wdf_wren,               -- in    std_logic

    --// AXI Slave Interface:
    p_out_saxi_clk     => p_out_saxi_clk    ,
    p_out_saxi_rstn    => p_out_saxi_rstn   ,
    --// Write Address Ports
    p_in_saxi_awid     => p_in_saxi_awid    ,
    p_in_saxi_awaddr   => p_in_saxi_awaddr  ,
    p_in_saxi_awlen    => p_in_saxi_awlen   ,
    p_in_saxi_awsize   => p_in_saxi_awsize  ,
    p_in_saxi_awburst  => p_in_saxi_awburst ,
    p_in_saxi_awlock   => p_in_saxi_awlock  ,
    p_in_saxi_awcache  => p_in_saxi_awcache ,
    p_in_saxi_awprot   => p_in_saxi_awprot  ,
    p_in_saxi_awqos    => p_in_saxi_awqos   ,
    p_in_saxi_awvalid  => p_in_saxi_awvalid ,
    p_out_saxi_awready => p_out_saxi_awready,
    --// Write Data Ports
    p_in_saxi_wdata    => p_in_saxi_wdata   ,
    p_in_saxi_wstrb    => p_in_saxi_wstrb   ,
    p_in_saxi_wlast    => p_in_saxi_wlast   ,
    p_in_saxi_wvalid   => p_in_saxi_wvalid  ,
    p_out_saxi_wready  => p_out_saxi_wready ,
    --// Write Response Ports
    p_out_saxi_bid     => p_out_saxi_bid    ,
    p_out_saxi_bresp   => p_out_saxi_bresp  ,
    p_out_saxi_bvalid  => p_out_saxi_bvalid ,
    p_in_saxi_bready   => p_in_saxi_bready  ,
    --// Read Address Ports
    p_in_saxi_arid     => p_in_saxi_arid    ,
    p_in_saxi_araddr   => p_in_saxi_araddr  ,
    p_in_saxi_arlen    => p_in_saxi_arlen   ,
    p_in_saxi_arsize   => p_in_saxi_arsize  ,
    p_in_saxi_arburst  => p_in_saxi_arburst ,
    p_in_saxi_arlock   => p_in_saxi_arlock  ,
    p_in_saxi_arcache  => p_in_saxi_arcache ,
    p_in_saxi_arprot   => p_in_saxi_arprot  ,
    p_in_saxi_arqos    => p_in_saxi_arqos   ,
    p_in_saxi_arvalid  => p_in_saxi_arvalid ,
    p_out_saxi_arready => p_out_saxi_arready,
    --// Read Data Ports
    p_out_saxi_rid     => p_out_saxi_rid    ,
    p_out_saxi_rdata   => p_out_saxi_rdata  ,
    p_out_saxi_rresp   => p_out_saxi_rresp  ,
    p_out_saxi_rlast   => p_out_saxi_rlast  ,
    p_out_saxi_rvalid  => p_out_saxi_rvalid ,
    p_in_saxi_rready   => p_in_saxi_rready  ,

    dbg_wr_dqs_tap_set        => dbg_wr_dqs_tap_set,         -- in    std_logic_vector(5*DQS_WIDTH-1 downto 0)
    dbg_wr_dq_tap_set         => dbg_wr_dq_tap_set,          -- in    std_logic_vector(5*DQS_WIDTH-1 downto 0)
    dbg_wr_tap_set_en         => dbg_wr_tap_set_en,          -- in    std_logic
    dbg_wrlvl_start           => dbg_wrlvl_start,            -- out   std_logic
    dbg_wrlvl_done            => dbg_wrlvl_done,             -- out   std_logic
    dbg_wrlvl_err             => dbg_wrlvl_err,              -- out   std_logic
    dbg_wl_dqs_inverted       => dbg_wl_dqs_inverted,        -- out   std_logic_vector(DQS_WIDTH-1 downto 0)
    dbg_wr_calib_clk_delay    => dbg_wr_calib_clk_delay,     -- out   std_logic_vector(2*DQS_WIDTH-1 downto 0)
    dbg_wl_odelay_dqs_tap_cnt => dbg_wl_odelay_dqs_tap_cnt,  -- out   std_logic_vector(5*DQS_WIDTH-1 downto 0)
    dbg_wl_odelay_dq_tap_cnt  => dbg_wl_odelay_dq_tap_cnt,   -- out   std_logic_vector(5*DQS_WIDTH-1 downto 0)
    dbg_rdlvl_start           => dbg_rdlvl_start,            -- out   std_logic_vector(1 downto 0)
    dbg_rdlvl_done            => dbg_rdlvl_done,             -- out   std_logic_vector(1 downto 0)
    dbg_rdlvl_err             => dbg_rdlvl_err,              -- out   std_logic_vector(1 downto 0)
    dbg_cpt_tap_cnt           => dbg_cpt_tap_cnt,            -- out   std_logic_vector(5*DQS_WIDTH-1 downto 0)
    dbg_cpt_first_edge_cnt    => dbg_cpt_first_edge_cnt,     -- out   std_logic_vector(5*DQS_WIDTH-1 downto 0)
    dbg_cpt_second_edge_cnt   => dbg_cpt_second_edge_cnt,    -- out   std_logic_vector(5*DQS_WIDTH-1 downto 0)
    dbg_rd_bitslip_cnt        => dbg_rd_bitslip_cnt,         -- out   std_logic_vector(3*DQS_WIDTH-1 downto 0)
    dbg_rd_clkdly_cnt         => dbg_rd_clkdly_cnt,          -- out   std_logic_vector(2*DQS_WIDTH-1 downto 0)
    dbg_rd_active_dly         => dbg_rd_active_dly,          -- out   std_logic_vector(4 downto 0)
    dbg_pd_off                => dbg_pd_off,                 -- in    std_logic
    dbg_pd_maintain_off       => dbg_pd_maintain_off,        -- in    std_logic
    dbg_pd_maintain_0_only    => dbg_pd_maintain_0_only,     -- in    std_logic
    dbg_inc_cpt               => dbg_inc_cpt,                -- in    std_logic
    dbg_dec_cpt               => dbg_dec_cpt,                -- in    std_logic
    dbg_inc_rd_dqs            => dbg_inc_rd_dqs,             -- in    std_logic
    dbg_dec_rd_dqs            => dbg_dec_rd_dqs,             -- in    std_logic
    dbg_inc_dec_sel           => dbg_inc_dec_sel,            -- in    std_logic_vector(DQS_CNT_WIDTH-1 downto 0)
    dbg_inc_rd_fps            => dbg_inc_rd_fps,             -- in    std_logic
    dbg_dec_rd_fps            => dbg_dec_rd_fps,             -- in    std_logic
    dbg_dqs_tap_cnt           => dbg_dqs_tap_cnt,            -- out   std_logic_vector(5*DQS_WIDTH-1 downto 0)
    dbg_dq_tap_cnt            => dbg_dq_tap_cnt,             -- out   std_logic_vector(5*DQS_WIDTH-1 downto 0)
    dbg_rddata                => dbg_rddata);                -- out   std_logic_vector(4*DQ_WIDTH-1 downto 0)

    -- DDR3 MIG clock generation
    infrastructure_i : infrastructure
      generic map(
      TCQ             => MIG_V3_6_COMMON.TCQ,              -- integer := 100
      CLK_PERIOD      => SYSCLK_PERIOD,                    -- integer := 3000
      nCK_PER_CLK     => MIG_V3_6_CLOCKS.nCK_PER_CLK,      -- integer := 2
      CLKFBOUT_MULT_F => MIG_V3_6_CLOCKS.CLKFBOUT_MULT_F,  -- integer := 2
      DIVCLK_DIVIDE   => MIG_V3_6_CLOCKS.DIVCLK_DIVIDE,    -- integer := 1
      CLKOUT_DIVIDE   => MIG_V3_6_CLOCKS.CLKOUT_DIVIDE,    -- integer := 2
      RST_ACT_LOW     => MIG_V3_6_CLOCKS.RST_ACT_LOW)      -- integer := 1
    port map(
      -- Clock inputs
      mmcm_clk         => ddr3_clk,         -- in    std_logic
      -- System reset input
      sys_rst          => ddr3_rst,         -- in    std_logic
      -- MMCM/IDELAYCTRL Lock status
      iodelay_ctrl_rdy => ddr3_iodelay_ctrl_rdy, -- in    std_logic
      -- Clock outputs
      clk_mem          => mig_clk_mem,      -- out   std_logic
      clk              => mig_ddr3_if_clk0, -- out   std_logic
      clk_rd_base      => mig_clk_rd_base,  -- out   std_logic
      -- Reset outputs
      rstdiv0          => mig_rst,          -- out   std_logic
      -- Phase Shift Interface
      PSDONE           => pd_psdone,        -- out   std_logic
      PSEN             => pd_psen,          -- in    std_logic
      PSINCDEC         => pd_psincdec);     -- in    std_logic

      process(mig_ddr3_if_clk0)
      begin
        if rising_edge(mig_ddr3_if_clk0) then
          -- Connect ready
          ddr3_if_rdy <= dfi_init_complete;
        end if;
      end process;

  end generate bank0_g;


  -- Instantiate DDR3 MIG bank 1 core
  bank1_g : if (bank = 1) generate

    memc_ui_top_i : entity work.c1_memc_ui_top(arch_c1_memc_ui_top)
    generic map(
      ADDR_CMD_MODE       => MIG_V3_6_COMMON.ADDR_CMD_MODE,
      BANK_WIDTH          => MIG_V3_6_COMMON.BANK_WIDTH,
      CK_WIDTH            => MIG_V3_6_COMMON.CK_WIDTH,
      CKE_WIDTH           => MIG_V3_6_COMMON.CKE_WIDTH,
      nCK_PER_CLK         => MIG_V3_6_CLOCKS.nCK_PER_CLK,
      COL_WIDTH           => MIG_V3_6_COMMON.COL_WIDTH,
      CS_WIDTH            => MIG_V3_6_COMMON.CS_WIDTH,
      DM_WIDTH            => MIG_V3_6_COMMON.DM_WIDTH,
      nCS_PER_RANK        => MIG_V3_6_COMMON.nCS_PER_RANK,
      DEBUG_PORT          => MIG_V3_6_COMMON.DEBUG_PORT,
      IODELAY_GRP         => MIG_V3_6_CLOCKS.IODELAY_GRP,
      DQ_WIDTH            => MIG_V3_6_COMMON.DQ_WIDTH,
      DQS_WIDTH           => MIG_V3_6_COMMON.DQS_WIDTH,
      DQS_CNT_WIDTH       => MIG_V3_6_COMMON.DQS_CNT_WIDTH,
      ORDERING            => MIG_V3_6_COMMON.ORDERING,
      OUTPUT_DRV          => MIG_V3_6_COMMON.OUTPUT_DRV,
      PHASE_DETECT        => MIG_V3_6_COMMON.PHASE_DETECT,
      RANK_WIDTH          => MIG_V3_6_COMMON.RANK_WIDTH,
      REFCLK_FREQ         => MIG_V3_6_CLOCKS.REFCLK_FREQ,
      REG_CTRL            => MIG_V3_6_COMMON.REG_CTRL,
      ROW_WIDTH           => MIG_V3_6_COMMON.ROW_WIDTH,
      RTT_NOM             => MIG_V3_6_COMMON.RTT_NOM,
      RTT_WR              => MIG_V3_6_COMMON.RTT_WR,
      SIM_BYPASS_INIT_CAL => MIG_V3_6_SIM_BYPASS_INIT_CAL,
      SIM_CAL_OPTION      => MIG_V3_6_SIM_CAL_OPTION,
      SIM_INIT_OPTION     => MIG_V3_6_SIM_INIT_OPTION,
      WRLVL               => MIG_V3_6_COMMON.WRLVL,
      nDQS_COL0           => MIG_V3_6_BANK01.nDQS_COL0,
      nDQS_COL1           => MIG_V3_6_BANK01.nDQS_COL1,
      nDQS_COL2           => MIG_V3_6_BANK01.nDQS_COL2,
      nDQS_COL3           => MIG_V3_6_BANK01.nDQS_COL3,
      DQS_LOC_COL0        => MIG_V3_6_BANK01.DQS_LOC_COL0,
      DQS_LOC_COL1        => MIG_V3_6_BANK01.DQS_LOC_COL1,
      DQS_LOC_COL2        => MIG_V3_6_BANK01.DQS_LOC_COL2,
      DQS_LOC_COL3        => MIG_V3_6_BANK01.DQS_LOC_COL3,
      BURST_MODE          => MIG_V3_6_COMMON.BURST_MODE,
      BM_CNT_WIDTH        => MIG_V3_6_COMMON.BM_CNT_WIDTH,
      tCK                 => MIG_V3_6_CLOCKS.tCK,
      tPRDI               => MIG_V3_6_COMMON.tPRDI,
      tREFI               => MIG_V3_6_COMMON.tREFI,
      tZQI                => MIG_V3_6_COMMON.tZQI,
      tRFC                => MIG_V3_6_COMMON.tRFC,
      ADDR_WIDTH          => MIG_V3_6_COMMON.ADDR_WIDTH,
      TCQ                 => MIG_V3_6_COMMON.TCQ,
      ECC_TEST            => MIG_V3_6_COMMON.ECC_TEST,
      PAYLOAD_WIDTH       => MIG_V3_6_COMMON.PAYLOAD_WIDTH,

      G_AXI_IDWIDTH              =>G_AXI_IDWIDTH  ,
      G_AXI_AWIDTH               =>G_AXI_AWIDTH   ,
      G_AXI_DWIDTH               =>G_AXI_DWIDTH   ,
      G_AXI_SUPPORTS_NARROW_BURST=>G_AXI_SUPPORTS_NARROW_BURST,
      G_AXI_REG_EN0              =>G_AXI_REG_EN0  ,
      G_AXI_REG_EN1              =>G_AXI_REG_EN1
      )
    port map(
      clk                       => mig_ddr3_if_clk1,           -- in    std_logic
      clk_mem                   => mig_clk_mem,                -- in    std_logic
      clk_rd_base               => mig_clk_rd_base,            -- in    std_logic
      rst                       => mig_rst,                    -- in    std_logic
      ddr_addr                  => ddr3_addr_out.a,            -- out   std_logic_vector(ROW_WIDTH-1 downto 0)
      ddr_ba                    => ddr3_ctrl_out.ba,           -- out   std_logic_vector(BANK_WIDTH-1 downto 0)
      ddr_cas_n                 => ddr3_ctrl_out.cas_l,        -- out   std_logic
      ddr_ck_n                  => ddr3_clk_out.clk_n,         -- out   std_logic_vector(CK_WIDTH-1 downto 0)
      ddr_ck                    => ddr3_clk_out.clk_p,         -- out   std_logic_vector(CK_WIDTH-1 downto 0)
      ddr_cke                   => ddr3_ctrl_out.cke,          -- out   std_logic_vector(CKE_WIDTH-1 downto 0)
      ddr_cs_n                  => ddr3_ctrl_out.cs_l,         -- out   std_logic_vector(CS_WIDTH*nCS_PER_RANK-1 downto 0)
      ddr_dm                    => ddr3_ctrl_out.dm,           -- out   std_logic_vector(DM_WIDTH-1 downto 0)
      ddr_odt                   => ddr3_ctrl_out.odt,          -- out   std_logic_vector(CS_WIDTH*nCS_PER_RANK-1 downto 0)
      ddr_ras_n                 => ddr3_ctrl_out.ras_l,        -- out   std_logic
      ddr_reset_n               => ddr3_ctrl_out.reset_l,      -- out   std_logic
      ddr_parity                => open,                       -- out   std_logic
      ddr_we_n                  => ddr3_ctrl_out.we_l,         -- out   std_logic
      ddr_dq                    => ddr3_data_inout.dq,         -- inout std_logic_vector(DQ_WIDTH-1 downto 0)
      ddr_dqs_n                 => ddr3_data_inout.dqs_n,      -- inout std_logic_vector(DQS_WIDTH-1 downto 0)
      ddr_dqs                   => ddr3_data_inout.dqs_p,      -- inout std_logic_vector(DQS_WIDTH-1 downto 0)

      pd_PSEN                   => pd_psen,                    -- out   std_logic
      pd_PSINCDEC               => pd_psincdec,                -- out   std_logic
      pd_PSDONE                 => pd_psdone,                  -- in    std_logic
      dfi_init_complete         => dfi_init_complete,          -- out   std_logic
--      bank_mach_next            => open,                       -- out   std_logic_vector(BM_CNT_WIDTH-1 downto 0)
--      app_ecc_multiple_err      => open,                       -- out   std_logic_vector(3 downto 0)
--      app_rd_data               => app_rd_data,                -- out   std_logic_vector(APP_DATA_WIDTH-1 downto 0)
--      app_rd_data_end           => open,                       -- out   std_logic
--      app_rd_data_valid         => app_rd_data_valid,          -- out   std_logic
--      app_rdy                   => app_rdy,                    -- out   std_logic
--      app_wdf_rdy               => app_wdf_rdy,                -- out   std_logic
--      app_addr                  => app_addr,                   -- in    std_logic_vector(ADDR_WIDTH-1 downto 0)
--      app_cmd                   => app_cmd,                    -- in    std_logic_vector(2 downto 0)
--      app_en                    => app_en,                     -- in    std_logic
--      app_hi_pri                => '0',                        -- in    std_logic
--      app_sz                    => app_sz,                     -- in    std_logic
--      app_wdf_data              => app_wdf_data,               -- in    std_logic_vector(APP_DATA_WIDTH-1 downto 0)
--      app_wdf_end               => app_wdf_end,                -- in    std_logic
--      app_wdf_mask              => app_wdf_mask,               -- in    std_logic_vector(APP_MASK_WIDTH-1 downto 0)
--      app_wdf_wren              => app_wdf_wren,               -- in    std_logic

      --// AXI Slave Interface:
      p_out_saxi_clk     => p_out_saxi_clk    ,
      p_out_saxi_rstn    => p_out_saxi_rstn   ,
      --// Write Address Ports
      p_in_saxi_awid     => p_in_saxi_awid    ,
      p_in_saxi_awaddr   => p_in_saxi_awaddr  ,
      p_in_saxi_awlen    => p_in_saxi_awlen   ,
      p_in_saxi_awsize   => p_in_saxi_awsize  ,
      p_in_saxi_awburst  => p_in_saxi_awburst ,
      p_in_saxi_awlock   => p_in_saxi_awlock  ,
      p_in_saxi_awcache  => p_in_saxi_awcache ,
      p_in_saxi_awprot   => p_in_saxi_awprot  ,
      p_in_saxi_awqos    => p_in_saxi_awqos   ,
      p_in_saxi_awvalid  => p_in_saxi_awvalid ,
      p_out_saxi_awready => p_out_saxi_awready,
      --// Write Data Ports
      p_in_saxi_wdata    => p_in_saxi_wdata   ,
      p_in_saxi_wstrb    => p_in_saxi_wstrb   ,
      p_in_saxi_wlast    => p_in_saxi_wlast   ,
      p_in_saxi_wvalid   => p_in_saxi_wvalid  ,
      p_out_saxi_wready  => p_out_saxi_wready ,
      --// Write Response Ports
      p_out_saxi_bid     => p_out_saxi_bid    ,
      p_out_saxi_bresp   => p_out_saxi_bresp  ,
      p_out_saxi_bvalid  => p_out_saxi_bvalid ,
      p_in_saxi_bready   => p_in_saxi_bready  ,
      --// Read Address Ports
      p_in_saxi_arid     => p_in_saxi_arid    ,
      p_in_saxi_araddr   => p_in_saxi_araddr  ,
      p_in_saxi_arlen    => p_in_saxi_arlen   ,
      p_in_saxi_arsize   => p_in_saxi_arsize  ,
      p_in_saxi_arburst  => p_in_saxi_arburst ,
      p_in_saxi_arlock   => p_in_saxi_arlock  ,
      p_in_saxi_arcache  => p_in_saxi_arcache ,
      p_in_saxi_arprot   => p_in_saxi_arprot  ,
      p_in_saxi_arqos    => p_in_saxi_arqos   ,
      p_in_saxi_arvalid  => p_in_saxi_arvalid ,
      p_out_saxi_arready => p_out_saxi_arready,
      --// Read Data Ports
      p_out_saxi_rid     => p_out_saxi_rid    ,
      p_out_saxi_rdata   => p_out_saxi_rdata  ,
      p_out_saxi_rresp   => p_out_saxi_rresp  ,
      p_out_saxi_rlast   => p_out_saxi_rlast  ,
      p_out_saxi_rvalid  => p_out_saxi_rvalid ,
      p_in_saxi_rready   => p_in_saxi_rready  ,

      dbg_wr_dqs_tap_set        => dbg_wr_dqs_tap_set,         -- in    std_logic_vector(5*DQS_WIDTH-1 downto 0)
      dbg_wr_dq_tap_set         => dbg_wr_dq_tap_set,          -- in    std_logic_vector(5*DQS_WIDTH-1 downto 0)
      dbg_wr_tap_set_en         => dbg_wr_tap_set_en,          -- in    std_logic
      dbg_wrlvl_start           => dbg_wrlvl_start,            -- out   std_logic
      dbg_wrlvl_done            => dbg_wrlvl_done,             -- out   std_logic
      dbg_wrlvl_err             => dbg_wrlvl_err,              -- out   std_logic
      dbg_wl_dqs_inverted       => dbg_wl_dqs_inverted,        -- out   std_logic_vector(DQS_WIDTH-1 downto 0)
      dbg_wr_calib_clk_delay    => dbg_wr_calib_clk_delay,     -- out   std_logic_vector(2*DQS_WIDTH-1 downto 0)
      dbg_wl_odelay_dqs_tap_cnt => dbg_wl_odelay_dqs_tap_cnt,  -- out   std_logic_vector(5*DQS_WIDTH-1 downto 0)
      dbg_wl_odelay_dq_tap_cnt  => dbg_wl_odelay_dq_tap_cnt,   -- out   std_logic_vector(5*DQS_WIDTH-1 downto 0)
      dbg_rdlvl_start           => dbg_rdlvl_start,            -- out   std_logic_vector(1 downto 0)
      dbg_rdlvl_done            => dbg_rdlvl_done,             -- out   std_logic_vector(1 downto 0)
      dbg_rdlvl_err             => dbg_rdlvl_err,              -- out   std_logic_vector(1 downto 0)
      dbg_cpt_tap_cnt           => dbg_cpt_tap_cnt,            -- out   std_logic_vector(5*DQS_WIDTH-1 downto 0)
      dbg_cpt_first_edge_cnt    => dbg_cpt_first_edge_cnt,     -- out   std_logic_vector(5*DQS_WIDTH-1 downto 0)
      dbg_cpt_second_edge_cnt   => dbg_cpt_second_edge_cnt,    -- out   std_logic_vector(5*DQS_WIDTH-1 downto 0)
      dbg_rd_bitslip_cnt        => dbg_rd_bitslip_cnt,         -- out   std_logic_vector(3*DQS_WIDTH-1 downto 0)
      dbg_rd_clkdly_cnt         => dbg_rd_clkdly_cnt,          -- out   std_logic_vector(2*DQS_WIDTH-1 downto 0)
      dbg_rd_active_dly         => dbg_rd_active_dly,          -- out   std_logic_vector(4 downto 0)
      dbg_pd_off                => dbg_pd_off,                 -- in    std_logic
      dbg_pd_maintain_off       => dbg_pd_maintain_off,        -- in    std_logic
      dbg_pd_maintain_0_only    => dbg_pd_maintain_0_only,     -- in    std_logic
      dbg_inc_cpt               => dbg_inc_cpt,                -- in    std_logic
      dbg_dec_cpt               => dbg_dec_cpt,                -- in    std_logic
      dbg_inc_rd_dqs            => dbg_inc_rd_dqs,             -- in    std_logic
      dbg_dec_rd_dqs            => dbg_dec_rd_dqs,             -- in    std_logic
      dbg_inc_dec_sel           => dbg_inc_dec_sel,            -- in    std_logic_vector(DQS_CNT_WIDTH-1 downto 0)
      dbg_inc_rd_fps            => dbg_inc_rd_fps,             -- in    std_logic
      dbg_dec_rd_fps            => dbg_dec_rd_fps,             -- in    std_logic
      dbg_dqs_tap_cnt           => dbg_dqs_tap_cnt,            -- out   std_logic_vector(5*DQS_WIDTH-1 downto 0)
      dbg_dq_tap_cnt            => dbg_dq_tap_cnt,             -- out   std_logic_vector(5*DQS_WIDTH-1 downto 0)
      dbg_rddata                => dbg_rddata);                -- out   std_logic_vector(4*DQ_WIDTH-1 downto 0)

      -- DDR3 MIG clock generation
      infrastructure_i : infrastructure
        generic map(
        TCQ             => MIG_V3_6_COMMON.TCQ,              -- integer := 100
        CLK_PERIOD      => SYSCLK_PERIOD,                    -- integer := 3000
        nCK_PER_CLK     => MIG_V3_6_CLOCKS.nCK_PER_CLK,      -- integer := 2
        CLKFBOUT_MULT_F => MIG_V3_6_CLOCKS.CLKFBOUT_MULT_F,  -- integer := 2
        DIVCLK_DIVIDE   => MIG_V3_6_CLOCKS.DIVCLK_DIVIDE,    -- integer := 1
        CLKOUT_DIVIDE   => MIG_V3_6_CLOCKS.CLKOUT_DIVIDE,    -- integer := 2
        RST_ACT_LOW     => MIG_V3_6_CLOCKS.RST_ACT_LOW)      -- integer := 1
      port map(
        -- Clock inputs
        mmcm_clk         => ddr3_clk,         -- in    std_logic
        -- System reset input
        sys_rst          => ddr3_rst,         -- in    std_logic
        -- MMCM/IDELAYCTRL Lock status
        iodelay_ctrl_rdy => ddr3_iodelay_ctrl_rdy, -- in    std_logic
        -- Clock outputs
        clk_mem          => mig_clk_mem,      -- out   std_logic
        clk              => mig_ddr3_if_clk1, -- out   std_logic
        clk_rd_base      => mig_clk_rd_base,  -- out   std_logic
        -- Reset outputs
        rstdiv0          => mig_rst,          -- out   std_logic
        -- Phase Shift Interface
        PSDONE           => pd_psdone,        -- out   std_logic
        PSEN             => pd_psen,          -- in    std_logic
        PSINCDEC         => pd_psincdec);     -- in    std_logic

    process(mig_ddr3_if_clk1)
    begin
      if rising_edge(mig_ddr3_if_clk1) then
        -- Connect ready
        ddr3_if_rdy <= dfi_init_complete;
      end if;
    end process;
  end generate bank1_g;

  -- Instantiate DDR3 MIG bank 2 core
  bank2_g : if (bank = 2) generate

    memc_ui_top_i : entity work.c2_memc_ui_top(arch_c2_memc_ui_top)
    generic map(
      ADDR_CMD_MODE       => MIG_V3_6_COMMON.ADDR_CMD_MODE,
      BANK_WIDTH          => MIG_V3_6_COMMON.BANK_WIDTH,
      CK_WIDTH            => MIG_V3_6_COMMON.CK_WIDTH,
      CKE_WIDTH           => MIG_V3_6_COMMON.CKE_WIDTH,
      nCK_PER_CLK         => MIG_V3_6_CLOCKS.nCK_PER_CLK,
      COL_WIDTH           => MIG_V3_6_COMMON.COL_WIDTH,
      CS_WIDTH            => MIG_V3_6_COMMON.CS_WIDTH,
      DM_WIDTH            => MIG_V3_6_COMMON.DM_WIDTH,
      nCS_PER_RANK        => MIG_V3_6_COMMON.nCS_PER_RANK,
      DEBUG_PORT          => MIG_V3_6_COMMON.DEBUG_PORT,
      IODELAY_GRP         => MIG_V3_6_CLOCKS.IODELAY_GRP,
      DQ_WIDTH            => MIG_V3_6_COMMON.DQ_WIDTH,
      DQS_WIDTH           => MIG_V3_6_COMMON.DQS_WIDTH,
      DQS_CNT_WIDTH       => MIG_V3_6_COMMON.DQS_CNT_WIDTH,
      ORDERING            => MIG_V3_6_COMMON.ORDERING,
      OUTPUT_DRV          => MIG_V3_6_COMMON.OUTPUT_DRV,
      PHASE_DETECT        => MIG_V3_6_COMMON.PHASE_DETECT,
      RANK_WIDTH          => MIG_V3_6_COMMON.RANK_WIDTH,
      REFCLK_FREQ         => MIG_V3_6_CLOCKS.REFCLK_FREQ,
      REG_CTRL            => MIG_V3_6_COMMON.REG_CTRL,
      ROW_WIDTH           => MIG_V3_6_COMMON.ROW_WIDTH,
      RTT_NOM             => MIG_V3_6_COMMON.RTT_NOM,
      RTT_WR              => MIG_V3_6_COMMON.RTT_WR,
      SIM_BYPASS_INIT_CAL => MIG_V3_6_SIM_BYPASS_INIT_CAL,
      SIM_CAL_OPTION      => MIG_V3_6_SIM_CAL_OPTION,
      SIM_INIT_OPTION     => MIG_V3_6_SIM_INIT_OPTION,
      WRLVL               => MIG_V3_6_COMMON.WRLVL,
      nDQS_COL0           => MIG_V3_6_BANK2.nDQS_COL0,
      nDQS_COL1           => MIG_V3_6_BANK2.nDQS_COL1,
      nDQS_COL2           => MIG_V3_6_BANK2.nDQS_COL2,
      nDQS_COL3           => MIG_V3_6_BANK2.nDQS_COL3,
      DQS_LOC_COL0        => MIG_V3_6_BANK2.DQS_LOC_COL0,
      DQS_LOC_COL1        => MIG_V3_6_BANK2.DQS_LOC_COL1,
      DQS_LOC_COL2        => MIG_V3_6_BANK2.DQS_LOC_COL2,
      DQS_LOC_COL3        => MIG_V3_6_BANK2.DQS_LOC_COL3,
      BURST_MODE          => MIG_V3_6_COMMON.BURST_MODE,
      BM_CNT_WIDTH        => MIG_V3_6_COMMON.BM_CNT_WIDTH,
      tCK                 => MIG_V3_6_CLOCKS.tCK,
      tPRDI               => MIG_V3_6_COMMON.tPRDI,
      tREFI               => MIG_V3_6_COMMON.tREFI,
      tZQI                => MIG_V3_6_COMMON.tZQI,
      tRFC                => MIG_V3_6_COMMON.tRFC,
      ADDR_WIDTH          => MIG_V3_6_COMMON.ADDR_WIDTH,
      TCQ                 => MIG_V3_6_COMMON.TCQ,
      ECC_TEST            => MIG_V3_6_COMMON.ECC_TEST,
      PAYLOAD_WIDTH       => MIG_V3_6_COMMON.PAYLOAD_WIDTH,

      G_AXI_IDWIDTH              =>G_AXI_IDWIDTH  ,
      G_AXI_AWIDTH               =>G_AXI_AWIDTH   ,
      G_AXI_DWIDTH               =>G_AXI_DWIDTH   ,
      G_AXI_SUPPORTS_NARROW_BURST=>G_AXI_SUPPORTS_NARROW_BURST,
      G_AXI_REG_EN0              =>G_AXI_REG_EN0  ,
      G_AXI_REG_EN1              =>G_AXI_REG_EN1
      )
    port map(
      clk                       => mig_ddr3_if_clk2,           -- in    std_logic
      clk_mem                   => mig_clk_mem,                -- in    std_logic
      clk_rd_base               => mig_clk_rd_base,            -- in    std_logic
      rst                       => mig_rst,                    -- in    std_logic
      ddr_addr                  => ddr3_addr_out.a,            -- out   std_logic_vector(ROW_WIDTH-1 downto 0)
      ddr_ba                    => ddr3_ctrl_out.ba,           -- out   std_logic_vector(BANK_WIDTH-1 downto 0)
      ddr_cas_n                 => ddr3_ctrl_out.cas_l,        -- out   std_logic
      ddr_ck_n                  => ddr3_clk_out.clk_n,         -- out   std_logic_vector(CK_WIDTH-1 downto 0)
      ddr_ck                    => ddr3_clk_out.clk_p,         -- out   std_logic_vector(CK_WIDTH-1 downto 0)
      ddr_cke                   => ddr3_ctrl_out.cke,          -- out   std_logic_vector(CKE_WIDTH-1 downto 0)
      ddr_cs_n                  => ddr3_ctrl_out.cs_l,         -- out   std_logic_vector(CS_WIDTH*nCS_PER_RANK-1 downto 0)
      ddr_dm                    => ddr3_ctrl_out.dm,           -- out   std_logic_vector(DM_WIDTH-1 downto 0)
      ddr_odt                   => ddr3_ctrl_out.odt,          -- out   std_logic_vector(CS_WIDTH*nCS_PER_RANK-1 downto 0)
      ddr_ras_n                 => ddr3_ctrl_out.ras_l,        -- out   std_logic
      ddr_reset_n               => ddr3_ctrl_out.reset_l,      -- out   std_logic
      ddr_parity                => open,                       -- out   std_logic
      ddr_we_n                  => ddr3_ctrl_out.we_l,         -- out   std_logic
      ddr_dq                    => ddr3_data_inout.dq,         -- inout std_logic_vector(DQ_WIDTH-1 downto 0)
      ddr_dqs_n                 => ddr3_data_inout.dqs_n,      -- inout std_logic_vector(DQS_WIDTH-1 downto 0)
      ddr_dqs                   => ddr3_data_inout.dqs_p,      -- inout std_logic_vector(DQS_WIDTH-1 downto 0)

      pd_PSEN                   => pd_psen,                    -- out   std_logic
      pd_PSINCDEC               => pd_psincdec,                -- out   std_logic
      pd_PSDONE                 => pd_psdone,                  -- in    std_logic
      dfi_init_complete         => dfi_init_complete,          -- out   std_logic
--      bank_mach_next            => open,                       -- out   std_logic_vector(BM_CNT_WIDTH-1 downto 0)
--      app_ecc_multiple_err      => open,                       -- out   std_logic_vector(3 downto 0)
--      app_rd_data               => app_rd_data,                -- out   std_logic_vector(APP_DATA_WIDTH-1 downto 0)
--      app_rd_data_end           => open,                       -- out   std_logic
--      app_rd_data_valid         => app_rd_data_valid,          -- out   std_logic
--      app_rdy                   => app_rdy,                    -- out   std_logic
--      app_wdf_rdy               => app_wdf_rdy,                -- out   std_logic
--      app_addr                  => app_addr,                   -- in    std_logic_vector(ADDR_WIDTH-1 downto 0)
--      app_cmd                   => app_cmd,                    -- in    std_logic_vector(2 downto 0)
--      app_en                    => app_en,                     -- in    std_logic
--      app_hi_pri                => '0',                        -- in    std_logic
--      app_sz                    => app_sz,                     -- in    std_logic
--      app_wdf_data              => app_wdf_data,               -- in    std_logic_vector(APP_DATA_WIDTH-1 downto 0)
--      app_wdf_end               => app_wdf_end,                -- in    std_logic
--      app_wdf_mask              => app_wdf_mask,               -- in    std_logic_vector(APP_MASK_WIDTH-1 downto 0)
--      app_wdf_wren              => app_wdf_wren,               -- in    std_logic

      --// AXI Slave Interface:
      p_out_saxi_clk     => p_out_saxi_clk    ,
      p_out_saxi_rstn    => p_out_saxi_rstn   ,
      --// Write Address Ports
      p_in_saxi_awid     => p_in_saxi_awid    ,
      p_in_saxi_awaddr   => p_in_saxi_awaddr  ,
      p_in_saxi_awlen    => p_in_saxi_awlen   ,
      p_in_saxi_awsize   => p_in_saxi_awsize  ,
      p_in_saxi_awburst  => p_in_saxi_awburst ,
      p_in_saxi_awlock   => p_in_saxi_awlock  ,
      p_in_saxi_awcache  => p_in_saxi_awcache ,
      p_in_saxi_awprot   => p_in_saxi_awprot  ,
      p_in_saxi_awqos    => p_in_saxi_awqos   ,
      p_in_saxi_awvalid  => p_in_saxi_awvalid ,
      p_out_saxi_awready => p_out_saxi_awready,
      --// Write Data Ports
      p_in_saxi_wdata    => p_in_saxi_wdata   ,
      p_in_saxi_wstrb    => p_in_saxi_wstrb   ,
      p_in_saxi_wlast    => p_in_saxi_wlast   ,
      p_in_saxi_wvalid   => p_in_saxi_wvalid  ,
      p_out_saxi_wready  => p_out_saxi_wready ,
      --// Write Response Ports
      p_out_saxi_bid     => p_out_saxi_bid    ,
      p_out_saxi_bresp   => p_out_saxi_bresp  ,
      p_out_saxi_bvalid  => p_out_saxi_bvalid ,
      p_in_saxi_bready   => p_in_saxi_bready  ,
      --// Read Address Ports
      p_in_saxi_arid     => p_in_saxi_arid    ,
      p_in_saxi_araddr   => p_in_saxi_araddr  ,
      p_in_saxi_arlen    => p_in_saxi_arlen   ,
      p_in_saxi_arsize   => p_in_saxi_arsize  ,
      p_in_saxi_arburst  => p_in_saxi_arburst ,
      p_in_saxi_arlock   => p_in_saxi_arlock  ,
      p_in_saxi_arcache  => p_in_saxi_arcache ,
      p_in_saxi_arprot   => p_in_saxi_arprot  ,
      p_in_saxi_arqos    => p_in_saxi_arqos   ,
      p_in_saxi_arvalid  => p_in_saxi_arvalid ,
      p_out_saxi_arready => p_out_saxi_arready,
      --// Read Data Ports
      p_out_saxi_rid     => p_out_saxi_rid    ,
      p_out_saxi_rdata   => p_out_saxi_rdata  ,
      p_out_saxi_rresp   => p_out_saxi_rresp  ,
      p_out_saxi_rlast   => p_out_saxi_rlast  ,
      p_out_saxi_rvalid  => p_out_saxi_rvalid ,
      p_in_saxi_rready   => p_in_saxi_rready  ,

      dbg_wr_dqs_tap_set        => dbg_wr_dqs_tap_set,         -- in    std_logic_vector(5*DQS_WIDTH-1 downto 0)
      dbg_wr_dq_tap_set         => dbg_wr_dq_tap_set,          -- in    std_logic_vector(5*DQS_WIDTH-1 downto 0)
      dbg_wr_tap_set_en         => dbg_wr_tap_set_en,          -- in    std_logic
      dbg_wrlvl_start           => dbg_wrlvl_start,            -- out   std_logic
      dbg_wrlvl_done            => dbg_wrlvl_done,             -- out   std_logic
      dbg_wrlvl_err             => dbg_wrlvl_err,              -- out   std_logic
      dbg_wl_dqs_inverted       => dbg_wl_dqs_inverted,        -- out   std_logic_vector(DQS_WIDTH-1 downto 0)
      dbg_wr_calib_clk_delay    => dbg_wr_calib_clk_delay,     -- out   std_logic_vector(2*DQS_WIDTH-1 downto 0)
      dbg_wl_odelay_dqs_tap_cnt => dbg_wl_odelay_dqs_tap_cnt,  -- out   std_logic_vector(5*DQS_WIDTH-1 downto 0)
      dbg_wl_odelay_dq_tap_cnt  => dbg_wl_odelay_dq_tap_cnt,   -- out   std_logic_vector(5*DQS_WIDTH-1 downto 0)
      dbg_rdlvl_start           => dbg_rdlvl_start,            -- out   std_logic_vector(1 downto 0)
      dbg_rdlvl_done            => dbg_rdlvl_done,             -- out   std_logic_vector(1 downto 0)
      dbg_rdlvl_err             => dbg_rdlvl_err,              -- out   std_logic_vector(1 downto 0)
      dbg_cpt_tap_cnt           => dbg_cpt_tap_cnt,            -- out   std_logic_vector(5*DQS_WIDTH-1 downto 0)
      dbg_cpt_first_edge_cnt    => dbg_cpt_first_edge_cnt,     -- out   std_logic_vector(5*DQS_WIDTH-1 downto 0)
      dbg_cpt_second_edge_cnt   => dbg_cpt_second_edge_cnt,    -- out   std_logic_vector(5*DQS_WIDTH-1 downto 0)
      dbg_rd_bitslip_cnt        => dbg_rd_bitslip_cnt,         -- out   std_logic_vector(3*DQS_WIDTH-1 downto 0)
      dbg_rd_clkdly_cnt         => dbg_rd_clkdly_cnt,          -- out   std_logic_vector(2*DQS_WIDTH-1 downto 0)
      dbg_rd_active_dly         => dbg_rd_active_dly,          -- out   std_logic_vector(4 downto 0)
      dbg_pd_off                => dbg_pd_off,                 -- in    std_logic
      dbg_pd_maintain_off       => dbg_pd_maintain_off,        -- in    std_logic
      dbg_pd_maintain_0_only    => dbg_pd_maintain_0_only,     -- in    std_logic
      dbg_inc_cpt               => dbg_inc_cpt,                -- in    std_logic
      dbg_dec_cpt               => dbg_dec_cpt,                -- in    std_logic
      dbg_inc_rd_dqs            => dbg_inc_rd_dqs,             -- in    std_logic
      dbg_dec_rd_dqs            => dbg_dec_rd_dqs,             -- in    std_logic
      dbg_inc_dec_sel           => dbg_inc_dec_sel,            -- in    std_logic_vector(DQS_CNT_WIDTH-1 downto 0)
      dbg_inc_rd_fps            => dbg_inc_rd_fps,             -- in    std_logic
      dbg_dec_rd_fps            => dbg_dec_rd_fps,             -- in    std_logic
      dbg_dqs_tap_cnt           => dbg_dqs_tap_cnt,            -- out   std_logic_vector(5*DQS_WIDTH-1 downto 0)
      dbg_dq_tap_cnt            => dbg_dq_tap_cnt,             -- out   std_logic_vector(5*DQS_WIDTH-1 downto 0)
      dbg_rddata                => dbg_rddata);                -- out   std_logic_vector(4*DQ_WIDTH-1 downto 0)

      -- DDR3 MIG clock generation
      infrastructure_i : infrastructure
        generic map(
        TCQ             => MIG_V3_6_COMMON.TCQ,              -- integer := 100
        CLK_PERIOD      => SYSCLK_PERIOD,                    -- integer := 3000
        nCK_PER_CLK     => MIG_V3_6_CLOCKS.nCK_PER_CLK,      -- integer := 2
        CLKFBOUT_MULT_F => MIG_V3_6_CLOCKS.CLKFBOUT_MULT_F,  -- integer := 2
        DIVCLK_DIVIDE   => MIG_V3_6_CLOCKS.DIVCLK_DIVIDE,    -- integer := 1
        CLKOUT_DIVIDE   => MIG_V3_6_CLOCKS.CLKOUT_DIVIDE,    -- integer := 2
        RST_ACT_LOW     => MIG_V3_6_CLOCKS.RST_ACT_LOW)      -- integer := 1
      port map(
        -- Clock inputs
        mmcm_clk         => ddr3_clk,         -- in    std_logic
        -- System reset input
        sys_rst          => ddr3_rst,         -- in    std_logic
        -- MMCM/IDELAYCTRL Lock status
        iodelay_ctrl_rdy => ddr3_iodelay_ctrl_rdy, -- in    std_logic
        -- Clock outputs
        clk_mem          => mig_clk_mem,      -- out   std_logic
        clk              => mig_ddr3_if_clk2, -- out   std_logic
        clk_rd_base      => mig_clk_rd_base,  -- out   std_logic
        -- Reset outputs
        rstdiv0          => mig_rst,          -- out   std_logic
        -- Phase Shift Interface
        PSDONE           => pd_psdone,        -- out   std_logic
        PSEN             => pd_psen,          -- in    std_logic
        PSINCDEC         => pd_psincdec);     -- in    std_logic

    process(mig_ddr3_if_clk2)
    begin
      if rising_edge(mig_ddr3_if_clk2) then
        -- Connect ready
        ddr3_if_rdy <= dfi_init_complete;
      end if;
    end process;
  end generate bank2_g;

  -- Instantiate DDR3 MIG bank 3 core
  bank3_g : if (bank = 3) generate

    memc_ui_top_i : entity work.c3_memc_ui_top(arch_c3_memc_ui_top)
    generic map(
      ADDR_CMD_MODE       => MIG_V3_6_COMMON.ADDR_CMD_MODE,
      BANK_WIDTH          => MIG_V3_6_COMMON.BANK_WIDTH,
      CK_WIDTH            => MIG_V3_6_COMMON.CK_WIDTH,
      CKE_WIDTH           => MIG_V3_6_COMMON.CKE_WIDTH,
      nCK_PER_CLK         => MIG_V3_6_CLOCKS.nCK_PER_CLK,
      COL_WIDTH           => MIG_V3_6_COMMON.COL_WIDTH,
      CS_WIDTH            => MIG_V3_6_COMMON.CS_WIDTH,
      DM_WIDTH            => MIG_V3_6_COMMON.DM_WIDTH,
      nCS_PER_RANK        => MIG_V3_6_COMMON.nCS_PER_RANK,
      DEBUG_PORT          => MIG_V3_6_COMMON.DEBUG_PORT,
      IODELAY_GRP         => MIG_V3_6_CLOCKS.IODELAY_GRP,
      DQ_WIDTH            => MIG_V3_6_COMMON.DQ_WIDTH,
      DQS_WIDTH           => MIG_V3_6_COMMON.DQS_WIDTH,
      DQS_CNT_WIDTH       => MIG_V3_6_COMMON.DQS_CNT_WIDTH,
      ORDERING            => MIG_V3_6_COMMON.ORDERING,
      OUTPUT_DRV          => MIG_V3_6_COMMON.OUTPUT_DRV,
      PHASE_DETECT        => MIG_V3_6_COMMON.PHASE_DETECT,
      RANK_WIDTH          => MIG_V3_6_COMMON.RANK_WIDTH,
      REFCLK_FREQ         => MIG_V3_6_CLOCKS.REFCLK_FREQ,
      REG_CTRL            => MIG_V3_6_COMMON.REG_CTRL,
      ROW_WIDTH           => MIG_V3_6_COMMON.ROW_WIDTH,
      RTT_NOM             => MIG_V3_6_COMMON.RTT_NOM,
      RTT_WR              => MIG_V3_6_COMMON.RTT_WR,
      SIM_BYPASS_INIT_CAL => MIG_V3_6_SIM_BYPASS_INIT_CAL,
      SIM_CAL_OPTION      => MIG_V3_6_SIM_CAL_OPTION,
      SIM_INIT_OPTION     => MIG_V3_6_SIM_INIT_OPTION,
      WRLVL               => MIG_V3_6_COMMON.WRLVL,
      nDQS_COL0           => MIG_V3_6_BANK3.nDQS_COL0,
      nDQS_COL1           => MIG_V3_6_BANK3.nDQS_COL1,
      nDQS_COL2           => MIG_V3_6_BANK3.nDQS_COL2,
      nDQS_COL3           => MIG_V3_6_BANK3.nDQS_COL3,
      DQS_LOC_COL0        => MIG_V3_6_BANK3.DQS_LOC_COL0,
      DQS_LOC_COL1        => MIG_V3_6_BANK3.DQS_LOC_COL1,
      DQS_LOC_COL2        => MIG_V3_6_BANK3.DQS_LOC_COL2,
      DQS_LOC_COL3        => MIG_V3_6_BANK3.DQS_LOC_COL3,
      BURST_MODE          => MIG_V3_6_COMMON.BURST_MODE,
      BM_CNT_WIDTH        => MIG_V3_6_COMMON.BM_CNT_WIDTH,
      tCK                 => MIG_V3_6_CLOCKS.tCK,
      tPRDI               => MIG_V3_6_COMMON.tPRDI,
      tREFI               => MIG_V3_6_COMMON.tREFI,
      tZQI                => MIG_V3_6_COMMON.tZQI,
      tRFC                => MIG_V3_6_COMMON.tRFC,
      ADDR_WIDTH          => MIG_V3_6_COMMON.ADDR_WIDTH,
      TCQ                 => MIG_V3_6_COMMON.TCQ,
      ECC_TEST            => MIG_V3_6_COMMON.ECC_TEST,
      PAYLOAD_WIDTH       => MIG_V3_6_COMMON.PAYLOAD_WIDTH,

      G_AXI_IDWIDTH              =>G_AXI_IDWIDTH  ,
      G_AXI_AWIDTH               =>G_AXI_AWIDTH   ,
      G_AXI_DWIDTH               =>G_AXI_DWIDTH   ,
      G_AXI_SUPPORTS_NARROW_BURST=>G_AXI_SUPPORTS_NARROW_BURST,
      G_AXI_REG_EN0              =>G_AXI_REG_EN0  ,
      G_AXI_REG_EN1              =>G_AXI_REG_EN1
      )
    port map(
      clk                       => mig_ddr3_if_clk3,           -- in    std_logic
      clk_mem                   => mig_clk_mem,                -- in    std_logic
      clk_rd_base               => mig_clk_rd_base,            -- in    std_logic
      rst                       => mig_rst,                    -- in    std_logic
      ddr_addr                  => ddr3_addr_out.a,            -- out   std_logic_vector(ROW_WIDTH-1 downto 0)
      ddr_ba                    => ddr3_ctrl_out.ba,           -- out   std_logic_vector(BANK_WIDTH-1 downto 0)
      ddr_cas_n                 => ddr3_ctrl_out.cas_l,        -- out   std_logic
      ddr_ck_n                  => ddr3_clk_out.clk_n,         -- out   std_logic_vector(CK_WIDTH-1 downto 0)
      ddr_ck                    => ddr3_clk_out.clk_p,         -- out   std_logic_vector(CK_WIDTH-1 downto 0)
      ddr_cke                   => ddr3_ctrl_out.cke,          -- out   std_logic_vector(CKE_WIDTH-1 downto 0)
      ddr_cs_n                  => ddr3_ctrl_out.cs_l,         -- out   std_logic_vector(CS_WIDTH*nCS_PER_RANK-1 downto 0)
      ddr_dm                    => ddr3_ctrl_out.dm,           -- out   std_logic_vector(DM_WIDTH-1 downto 0)
      ddr_odt                   => ddr3_ctrl_out.odt,          -- out   std_logic_vector(CS_WIDTH*nCS_PER_RANK-1 downto 0)
      ddr_ras_n                 => ddr3_ctrl_out.ras_l,        -- out   std_logic
      ddr_reset_n               => ddr3_ctrl_out.reset_l,      -- out   std_logic
      ddr_parity                => open,                       -- out   std_logic
      ddr_we_n                  => ddr3_ctrl_out.we_l,         -- out   std_logic
      ddr_dq                    => ddr3_data_inout.dq,         -- inout std_logic_vector(DQ_WIDTH-1 downto 0)
      ddr_dqs_n                 => ddr3_data_inout.dqs_n,      -- inout std_logic_vector(DQS_WIDTH-1 downto 0)
      ddr_dqs                   => ddr3_data_inout.dqs_p,      -- inout std_logic_vector(DQS_WIDTH-1 downto 0)

      pd_PSEN                   => pd_psen,                    -- out   std_logic
      pd_PSINCDEC               => pd_psincdec,                -- out   std_logic
      pd_PSDONE                 => pd_psdone,                  -- in    std_logic
      dfi_init_complete         => dfi_init_complete,          -- out   std_logic
--      bank_mach_next            => open,                       -- out   std_logic_vector(BM_CNT_WIDTH-1 downto 0)
--      app_ecc_multiple_err      => open,                       -- out   std_logic_vector(3 downto 0)
--      app_rd_data               => app_rd_data,                -- out   std_logic_vector(APP_DATA_WIDTH-1 downto 0)
--      app_rd_data_end           => open,                       -- out   std_logic
--      app_rd_data_valid         => app_rd_data_valid,          -- out   std_logic
--      app_rdy                   => app_rdy,                    -- out   std_logic
--      app_wdf_rdy               => app_wdf_rdy,                -- out   std_logic
--      app_addr                  => app_addr,                   -- in    std_logic_vector(ADDR_WIDTH-1 downto 0)
--      app_cmd                   => app_cmd,                    -- in    std_logic_vector(2 downto 0)
--      app_en                    => app_en,                     -- in    std_logic
--      app_hi_pri                => '0',                        -- in    std_logic
--      app_sz                    => app_sz,                     -- in    std_logic
--      app_wdf_data              => app_wdf_data,               -- in    std_logic_vector(APP_DATA_WIDTH-1 downto 0)
--      app_wdf_end               => app_wdf_end,                -- in    std_logic
--      app_wdf_mask              => app_wdf_mask,               -- in    std_logic_vector(APP_MASK_WIDTH-1 downto 0)
--      app_wdf_wren              => app_wdf_wren,               -- in    std_logic

      --// AXI Slave Interface:
      p_out_saxi_clk     => p_out_saxi_clk    ,
      p_out_saxi_rstn    => p_out_saxi_rstn   ,
      --// Write Address Ports
      p_in_saxi_awid     => p_in_saxi_awid    ,
      p_in_saxi_awaddr   => p_in_saxi_awaddr  ,
      p_in_saxi_awlen    => p_in_saxi_awlen   ,
      p_in_saxi_awsize   => p_in_saxi_awsize  ,
      p_in_saxi_awburst  => p_in_saxi_awburst ,
      p_in_saxi_awlock   => p_in_saxi_awlock  ,
      p_in_saxi_awcache  => p_in_saxi_awcache ,
      p_in_saxi_awprot   => p_in_saxi_awprot  ,
      p_in_saxi_awqos    => p_in_saxi_awqos   ,
      p_in_saxi_awvalid  => p_in_saxi_awvalid ,
      p_out_saxi_awready => p_out_saxi_awready,
      --// Write Data Ports
      p_in_saxi_wdata    => p_in_saxi_wdata   ,
      p_in_saxi_wstrb    => p_in_saxi_wstrb   ,
      p_in_saxi_wlast    => p_in_saxi_wlast   ,
      p_in_saxi_wvalid   => p_in_saxi_wvalid  ,
      p_out_saxi_wready  => p_out_saxi_wready ,
      --// Write Response Ports
      p_out_saxi_bid     => p_out_saxi_bid    ,
      p_out_saxi_bresp   => p_out_saxi_bresp  ,
      p_out_saxi_bvalid  => p_out_saxi_bvalid ,
      p_in_saxi_bready   => p_in_saxi_bready  ,
      --// Read Address Ports
      p_in_saxi_arid     => p_in_saxi_arid    ,
      p_in_saxi_araddr   => p_in_saxi_araddr  ,
      p_in_saxi_arlen    => p_in_saxi_arlen   ,
      p_in_saxi_arsize   => p_in_saxi_arsize  ,
      p_in_saxi_arburst  => p_in_saxi_arburst ,
      p_in_saxi_arlock   => p_in_saxi_arlock  ,
      p_in_saxi_arcache  => p_in_saxi_arcache ,
      p_in_saxi_arprot   => p_in_saxi_arprot  ,
      p_in_saxi_arqos    => p_in_saxi_arqos   ,
      p_in_saxi_arvalid  => p_in_saxi_arvalid ,
      p_out_saxi_arready => p_out_saxi_arready,
      --// Read Data Ports
      p_out_saxi_rid     => p_out_saxi_rid    ,
      p_out_saxi_rdata   => p_out_saxi_rdata  ,
      p_out_saxi_rresp   => p_out_saxi_rresp  ,
      p_out_saxi_rlast   => p_out_saxi_rlast  ,
      p_out_saxi_rvalid  => p_out_saxi_rvalid ,
      p_in_saxi_rready   => p_in_saxi_rready  ,

      dbg_wr_dqs_tap_set        => dbg_wr_dqs_tap_set,         -- in    std_logic_vector(5*DQS_WIDTH-1 downto 0)
      dbg_wr_dq_tap_set         => dbg_wr_dq_tap_set,          -- in    std_logic_vector(5*DQS_WIDTH-1 downto 0)
      dbg_wr_tap_set_en         => dbg_wr_tap_set_en,          -- in    std_logic
      dbg_wrlvl_start           => dbg_wrlvl_start,            -- out   std_logic
      dbg_wrlvl_done            => dbg_wrlvl_done,             -- out   std_logic
      dbg_wrlvl_err             => dbg_wrlvl_err,              -- out   std_logic
      dbg_wl_dqs_inverted       => dbg_wl_dqs_inverted,        -- out   std_logic_vector(DQS_WIDTH-1 downto 0)
      dbg_wr_calib_clk_delay    => dbg_wr_calib_clk_delay,     -- out   std_logic_vector(2*DQS_WIDTH-1 downto 0)
      dbg_wl_odelay_dqs_tap_cnt => dbg_wl_odelay_dqs_tap_cnt,  -- out   std_logic_vector(5*DQS_WIDTH-1 downto 0)
      dbg_wl_odelay_dq_tap_cnt  => dbg_wl_odelay_dq_tap_cnt,   -- out   std_logic_vector(5*DQS_WIDTH-1 downto 0)
      dbg_rdlvl_start           => dbg_rdlvl_start,            -- out   std_logic_vector(1 downto 0)
      dbg_rdlvl_done            => dbg_rdlvl_done,             -- out   std_logic_vector(1 downto 0)
      dbg_rdlvl_err             => dbg_rdlvl_err,              -- out   std_logic_vector(1 downto 0)
      dbg_cpt_tap_cnt           => dbg_cpt_tap_cnt,            -- out   std_logic_vector(5*DQS_WIDTH-1 downto 0)
      dbg_cpt_first_edge_cnt    => dbg_cpt_first_edge_cnt,     -- out   std_logic_vector(5*DQS_WIDTH-1 downto 0)
      dbg_cpt_second_edge_cnt   => dbg_cpt_second_edge_cnt,    -- out   std_logic_vector(5*DQS_WIDTH-1 downto 0)
      dbg_rd_bitslip_cnt        => dbg_rd_bitslip_cnt,         -- out   std_logic_vector(3*DQS_WIDTH-1 downto 0)
      dbg_rd_clkdly_cnt         => dbg_rd_clkdly_cnt,          -- out   std_logic_vector(2*DQS_WIDTH-1 downto 0)
      dbg_rd_active_dly         => dbg_rd_active_dly,          -- out   std_logic_vector(4 downto 0)
      dbg_pd_off                => dbg_pd_off,                 -- in    std_logic
      dbg_pd_maintain_off       => dbg_pd_maintain_off,        -- in    std_logic
      dbg_pd_maintain_0_only    => dbg_pd_maintain_0_only,     -- in    std_logic
      dbg_inc_cpt               => dbg_inc_cpt,                -- in    std_logic
      dbg_dec_cpt               => dbg_dec_cpt,                -- in    std_logic
      dbg_inc_rd_dqs            => dbg_inc_rd_dqs,             -- in    std_logic
      dbg_dec_rd_dqs            => dbg_dec_rd_dqs,             -- in    std_logic
      dbg_inc_dec_sel           => dbg_inc_dec_sel,            -- in    std_logic_vector(DQS_CNT_WIDTH-1 downto 0)
      dbg_inc_rd_fps            => dbg_inc_rd_fps,             -- in    std_logic
      dbg_dec_rd_fps            => dbg_dec_rd_fps,             -- in    std_logic
      dbg_dqs_tap_cnt           => dbg_dqs_tap_cnt,            -- out   std_logic_vector(5*DQS_WIDTH-1 downto 0)
      dbg_dq_tap_cnt            => dbg_dq_tap_cnt,             -- out   std_logic_vector(5*DQS_WIDTH-1 downto 0)
      dbg_rddata                => dbg_rddata);                -- out   std_logic_vector(4*DQ_WIDTH-1 downto 0)

      -- DDR3 MIG clock generation
      infrastructure_i : infrastructure
        generic map(
        TCQ             => MIG_V3_6_COMMON.TCQ,              -- integer := 100
        CLK_PERIOD      => SYSCLK_PERIOD,                    -- integer := 3000
        nCK_PER_CLK     => MIG_V3_6_CLOCKS.nCK_PER_CLK,      -- integer := 2
        CLKFBOUT_MULT_F => MIG_V3_6_CLOCKS.CLKFBOUT_MULT_F,  -- integer := 2
        DIVCLK_DIVIDE   => MIG_V3_6_CLOCKS.DIVCLK_DIVIDE,    -- integer := 1
        CLKOUT_DIVIDE   => MIG_V3_6_CLOCKS.CLKOUT_DIVIDE,    -- integer := 2
        RST_ACT_LOW     => MIG_V3_6_CLOCKS.RST_ACT_LOW)      -- integer := 1
      port map(
        -- Clock inputs
        mmcm_clk         => ddr3_clk,         -- in    std_logic
        -- System reset input
        sys_rst          => ddr3_rst,         -- in    std_logic
        -- MMCM/IDELAYCTRL Lock status
        iodelay_ctrl_rdy => ddr3_iodelay_ctrl_rdy, -- in    std_logic
        -- Clock outputs
        clk_mem          => mig_clk_mem,      -- out   std_logic
        clk              => mig_ddr3_if_clk3, -- out   std_logic
        clk_rd_base      => mig_clk_rd_base,  -- out   std_logic
        -- Reset outputs
        rstdiv0          => mig_rst,          -- out   std_logic
        -- Phase Shift Interface
        PSDONE           => pd_psdone,        -- out   std_logic
        PSEN             => pd_psen,          -- in    std_logic
        PSINCDEC         => pd_psincdec);     -- in    std_logic

    process(mig_ddr3_if_clk3)
    begin
      if rising_edge(mig_ddr3_if_clk3) then
        -- Connect ready
        ddr3_if_rdy <= dfi_init_complete;
      end if;
    end process;
  end generate bank3_g;

  -- Connect status
  ddr3_if_stat(0) <= dbg_wrlvl_done;
  ddr3_if_stat(1) <= dbg_rdlvl_done(0);
  ddr3_if_stat(2) <= dbg_rdlvl_done(1);
  ddr3_if_stat(3) <= dfi_init_complete;
  -- Connect error
  ddr3_if_err(0)  <= dbg_wrlvl_err;
  ddr3_if_err(1)  <= dbg_rdlvl_err(0);
  ddr3_if_err(2)  <= dbg_rdlvl_err(1);
  ddr3_if_err(3)  <= mig_rst;

end;
