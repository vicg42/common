-------------------------------------------------------------------------
-- Company     : Linkos
-- Engineer    : Golovachenko Victor
--
-- Create Date : 10.10.2011 9:44:24
-- Module Name : axi_memctrl_tb
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
use ieee.std_logic_unsigned.all;
use ieee.std_logic_misc.all;

library work;
use work.ddr3_sdram_pkg.all;
use work.mem_ctrl_pkg.all;
use work.mem_wr_pkg.all;
use work.vicg_common_pkg.all;
use work.pcie_pkg.all;
use work.prj_def.all;

entity axi_memory_ctrl_tb is
generic(
G_AXI_MUX : string :="ON"
);
end axi_memory_ctrl_tb;

architecture test of axi_memory_ctrl_tb is

-- Clock periods
constant CLK_250_PERIOD : time :=  4.00 ns;    -- 250 MHz
constant CLK_200_PERIOD : time :=  5.00 ns;    -- 200 MHz
constant CLK_150_PERIOD : time :=  6.67 ns;    -- 150 MHz
constant CLK_166_PERIOD : time :=  6.00 ns;    -- 166 MHz
constant CLK_125_PERIOD : time :=  8.00 ns;    -- 125 MHz
constant CLK_100_PERIOD : time := 10.00 ns;    -- 100 MHz
constant CLK_80_PERIOD  : time := 12.50 ns;    --  80 MHz

-- Clock frequencies in MHz (truncated division)
constant CLK_250_FREQ   : natural := 1 us / CLK_250_PERIOD;
constant CLK_200_FREQ   : natural := 1 us / CLK_200_PERIOD;
constant CLK_150_FREQ   : natural := 1 us / CLK_150_PERIOD;
constant CLK_166_FREQ   : natural := 1 us / CLK_166_PERIOD;
constant CLK_125_FREQ   : natural := 1 us / CLK_125_PERIOD;
constant CLK_100_FREQ   : natural := 1 us / CLK_100_PERIOD;
constant CLK_80_FREQ    : natural := 1 us / CLK_80_PERIOD;

-- DDR3 component model
constant TB_DDR3_1G_PART : part_t := MT41J64M16_187E;
constant TB_DDR3_2G_PART : part_t := MT47J128M16_187E;

-- Select DDR3 part for board simulation
constant TB_DDR3_PART : part_t := TB_DDR3_1G_PART;

constant TB_DDR3_ROW  : natural := TB_DDR3_PART.part_size.arow_width;
constant TB_DDR3_COL  : natural := TB_DDR3_PART.part_size.acol_width;
constant TB_DDR3_BANK : natural := TB_DDR3_PART.part_size.bank_width;

-- MIG interface address width = Bank(3)+Row(13/14)+Col(10) and convert to byte addressing (+2)
constant TB_DDR3_BYTE_ADDR_WIDTH    : natural := TB_DDR3_BANK + TB_DDR3_ROW + TB_DDR3_COL + 2;
constant TB_DDR3_16_BYTE_ADDR_WIDTH : natural := TB_DDR3_BYTE_ADDR_WIDTH - 4;


-- Ram banks to instantiate
constant DDR3_ST_BANK     : natural range 0 to MEM_BANKS-1 := 0;
constant DDR3_MODEL_BANKS : natural range 0 to MEM_BANKS   := DDR3_BANKS;

-- DDR3 RAM part (information only)
signal ddr3_part : part_t := TB_DDR3_PART;

---- Test clocks
signal clk_250MHz : std_logic:='1';
signal clk_200MHz : std_logic:='1';
signal clk_125MHz : std_logic:='1';
signal clk_100MHz : std_logic:='1';
signal clk_80MHz  : std_logic:='1';

component pcie2mem_ctrl
generic(
G_MEM_AWIDTH     : integer:=32;
G_MEM_DWIDTH     : integer:=32;
G_MEM_BANK_M_BIT : integer:=29;
G_MEM_BANK_L_BIT : integer:=28;
G_DBG            : string :="OFF"
);
port(
-------------------------------
--Управление
-------------------------------
p_in_ctrl         : in    TPce2Mem_Ctrl;
p_out_status      : out   TPce2Mem_Status;

p_in_txd          : in    std_logic_vector(31 downto 0);
p_in_txd_wr       : in    std_logic;
p_out_txbuf_full  : out   std_logic;

p_out_rxd         : out   std_logic_vector(31 downto 0);
p_in_rxd_rd       : in    std_logic;
p_out_rxbuf_empty : out   std_logic;

p_in_hclk         : in    std_logic;

-------------------------------
--Связь с mem_ctrl
-------------------------------
p_out_mem         : out   TMemIN;
p_in_mem          : in    TMemOUT;

-------------------------------
--Технологический
-------------------------------
p_in_tst          : in    std_logic_vector(31 downto 0);
p_out_tst         : out   std_logic_vector(31 downto 0);

-------------------------------
--System
-------------------------------
p_in_clk          : in    std_logic;
p_in_rst          : in    std_logic
);
end component;

component clocks
port(
-- Reset output
p_out_pll_rst      : out   std_logic;
-- Clock outputs
p_out_pll_gclkin   : out   std_logic;
p_out_pll_mem_clk  : out   std_logic;
p_out_pll_tmr_clk  : out   std_logic;
--p_out_pll_reg_clk  : out   std_logic;

-- Clock pins
p_in_clk           : in    std_logic
);
end component;

component axi_memory_ctrl_ch_test
generic(
G_ACT        : integer:=0;
G_TADDR      : integer:=1;
G_TDATA      : integer:=1;
G_RQ_DATA    : integer:=1;
G_TRNLEN_WR  : integer:=1;
G_TRNLEN_RD  : integer:=1;
G_DWIDTH     : integer:=32
);
port
(
-------------------------------
-- Конфигурирование
-------------------------------
p_out_cfg_mem_adr     : out   std_logic_vector(31 downto 0);
p_out_cfg_mem_trn_len : out   std_logic_vector(15 downto 0);
p_out_cfg_mem_dlen_rq : out   std_logic_vector(15 downto 0);
p_out_cfg_mem_wr      : out   std_logic;
p_out_cfg_mem_start   : out   std_logic;
p_in_cfg_mem_done     : in    std_logic;

p_in_mem_init_done    : in    std_logic;

-------------------------------
-- Связь с пользовательскими буферами
-------------------------------
--//usr_buf->mem
p_out_usr_txbuf_din   : out   std_logic_vector(G_DWIDTH-1 downto 0);
p_out_usr_txbuf_wr    : out   std_logic;
p_in_usr_txbuf_full   : in    std_logic;

--//usr_buf<-mem
p_in_usr_rxbuf_dout  : in   std_logic_vector(G_DWIDTH-1 downto 0);
p_out_usr_rxbuf_rd   : out  std_logic;
p_in_usr_rxbuf_empty : in   std_logic;

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

-- Test results
--signal top_comp : top_comp_t;
--signal top_pass : top_pass_t;

signal test_complete : boolean := false;
signal test_passed   : boolean := true;


-- DDR3 signals
signal p_out_mem_addr   : mem_addr_out_t;
signal p_out_mem_ctrl   : mem_ctrl_out_t;
signal p_inout_mem_data : mem_data_inout_t;
signal p_out_mem_clk    : mem_clk_out_t;

------------------
-- Reset signal --
------------------
signal g_host_clk : std_logic;
signal i_rst : std_logic;

-------------------
-- Clock signals --
-------------------
signal i_refclk200MHz   : std_logic;

signal i_pll_pri_clk    : std_logic;
signal i_pll_reg_clk    : std_logic;
signal i_pll_mem_clk    : std_logic;
signal i_pll_ref_clk    : std_logic;


signal i_memctrl_ready   : std_logic:='0';
-- Memory status
signal i_mem_if_rdy     : mem_if_rdy_array_t;
signal i_mem_if_stat    : mem_if_stat_array_t;
signal i_mem_if_err     : mem_if_err_array_t;

-- Debug info
signal i_mem_if_err_info : mem_if_debug_array_t;

--signal i_host_mem_ctrl                  : TPce2Mem_Ctrl;
--signal i_host_mem_status                : TPce2Mem_Status;
type TPce2Mem_Ctrls is array (0 to 3) of TPce2Mem_Ctrl;
type TPce2Mem_Statuss is array (0 to 3) of TPce2Mem_Status;
signal i_host_mem_ctrl                  : TPce2Mem_Ctrls;
signal i_host_mem_status                : TPce2Mem_Statuss;

signal i_host_memin                     : TMemIN;
signal i_host_memout                    : TMemOUT;
signal i_host_mem_tst_out               : std_logic_vector(31 downto 0);
--signal i_host_mem_rst                   : std_logic;
signal i_host_mem_rst                   : std_logic_vector(3 downto 0);

signal i_arb_memin                      : TMemIN;
signal i_arb_memout                     : TMemOUT;
signal i_arb_mem_tst_out                : std_logic_vector(31 downto 0);

signal i_memin_ch                       : TMemINCh;
signal i_memout_ch                      : TMemOUTCh;
signal i_memin_bank                     : TMemINBank;
signal i_memout_bank                    : TMemOUTBank;

type Tumem_adr is array (0 to 3) of std_logic_vector(31 downto 0);
type Tumem_trn_len is array (0 to 3) of std_logic_vector(15 downto 0);
type Tumem_dlen_rq is array (0 to 3) of std_logic_vector(15 downto 0);
type Tdata is array (0 to 3) of std_logic_vector(C_HDEV_DWIDTH-1 downto 0);

signal i_umem_adr        : Tumem_adr;
signal i_umem_trn_len    : Tumem_trn_len;
signal i_umem_dlen_rq    : Tumem_dlen_rq;
signal i_umem_wr        : std_logic_vector(3 downto 0);
signal i_umem_start     : std_logic_vector(3 downto 0);
signal i_umem_done      : std_logic_vector(3 downto 0);

signal i_utxbuf_din      : Tdata;
signal i_utxbuf_dout     : Tdata;
signal i_utxbuf_wr      : std_logic_vector(3 downto 0);
signal i_utxbuf_rd      : std_logic_vector(3 downto 0);
signal i_utxbuf_empty    : std_logic_vector(3 downto 0);
signal i_utxbuf_full     : std_logic_vector(3 downto 0);

signal i_urxbuf_din     : Tdata;
signal i_urxbuf_dout     : Tdata;
signal i_urxbuf_wr      : std_logic_vector(3 downto 0);
signal i_urxbuf_rd      : std_logic_vector(3 downto 0);
signal i_urxbuf_empty    : std_logic_vector(3 downto 0);
signal i_urxbuf_full    : std_logic_vector(3 downto 0);


type TTestData  is array (0 to 3) of integer;
------------------------------------------------------------------------------
--ARBITR CHANEL:                      |    0    |   1     |    2    |    3    |
------------------------------------------------------------------------------
constant C_TEST_ACTION   : TTestData:=(    2   ,    2    ,     2   ,     0    );--0:WRITE 1:READ 2:ALL 3:NULL
constant C_TEST_DATA     : TTestData:=(16#0001#, 16#0041#, 16#0081#, 16#00C1# );
constant C_TEST_ADDR     : TTestData:=(16#0010#, 16#0010#, 16#0400#, 16#0800# );
constant C_TEST_RQ_DATA  : TTestData:=(10#0012#, 10#0012#, 10#0012#, 10#0012# );
constant C_TEST_TRNLEN_WR: TTestData:=(10#0005#, 10#0007#, 10#0008#, 10#0008# );
constant C_TEST_TRNLEN_RD: TTestData:=(10#0003#, 10#0006#, 10#0008#, 10#0008# );

--MAIN
begin


---------------------
-- Clock Generator
---------------------
clk_250MHz <= not clk_250MHz after CLK_250_PERIOD / 2;
clk_200MHz <= not clk_200MHz after CLK_200_PERIOD / 2;
clk_125MHz <= not clk_125MHz after CLK_125_PERIOD / 2;
clk_100MHz <= not clk_100MHz after CLK_100_PERIOD / 2;
clk_80MHz  <= not clk_80MHz  after CLK_80_PERIOD / 2;



---------------------
-- Clock interface --
---------------------
--//PLL
m_clocks : clocks
port map(
-- Reset output
p_out_pll_rst     => i_rst,
-- Clock outputs
p_out_pll_gclkin  => i_pll_ref_clk,
p_out_pll_mem_clk => i_pll_mem_clk,
p_out_pll_tmr_clk => open,--g_pll_tmr_clk,
--p_out_pll_reg_clk =>

-- Clock pins
p_in_clk          => clk_200MHz
);


g_host_clk<=clk_125MHz;

gen_maxi : for i in 0 to 3 generate

m_maxi_test : axi_memory_ctrl_ch_test
generic map(
G_ACT        => C_TEST_ACTION(i),
G_TADDR      => C_TEST_ADDR(i),
G_TDATA      => C_TEST_DATA(i),
G_RQ_DATA    => C_TEST_RQ_DATA(i),
G_TRNLEN_WR  => C_TEST_TRNLEN_WR(i),
G_TRNLEN_RD  => C_TEST_TRNLEN_RD(i),
G_DWIDTH     => C_HDEV_DWIDTH
)
port map(
-------------------------------
-- Конфигурирование
-------------------------------
p_out_cfg_mem_adr     => i_umem_adr    (i),
p_out_cfg_mem_trn_len => i_umem_trn_len(i),
p_out_cfg_mem_dlen_rq => i_umem_dlen_rq(i),
p_out_cfg_mem_wr      => i_umem_wr    (i),
p_out_cfg_mem_start   => i_umem_start (i),
p_in_cfg_mem_done     => i_umem_done  (i),

p_in_mem_init_done    => i_memctrl_ready,

-------------------------------
-- Связь с пользовательскими буферами
-------------------------------
--//usr_buf->mem
p_out_usr_txbuf_din   => i_utxbuf_din  (i),
p_out_usr_txbuf_wr    => i_utxbuf_wr  (i),
p_in_usr_txbuf_full   => i_utxbuf_full (i),

--//usr_buf<-mem
p_in_usr_rxbuf_dout   => i_urxbuf_dout(i),
p_out_usr_rxbuf_rd    => i_urxbuf_rd  (i),
p_in_usr_rxbuf_empty  => i_urxbuf_empty(i),

-------------------------------
--Технологические сигналы
-------------------------------
p_in_tst             => (others=>'0'),
p_out_tst            => open,

-------------------------------
--System
-------------------------------
p_in_clk             => g_host_clk,
p_in_rst             => i_host_mem_rst(i) --i_rst
);

i_umem_done  (i)<=i_host_mem_status(i).done;

i_host_mem_ctrl(i).dir       <=i_umem_wr    (i);
i_host_mem_ctrl(i).start     <=i_umem_start (i);
i_host_mem_ctrl(i).adr       <=i_umem_adr    (i);                  --//Byte
i_host_mem_ctrl(i).req_len   <=i_umem_dlen_rq(i)(15 downto 0)&"00";--//Byte
i_host_mem_ctrl(i).trnwr_len <=i_umem_trn_len(i)(7 downto 0);      --//DWord
i_host_mem_ctrl(i).trnrd_len <=i_umem_trn_len(i)(7 downto 0);      --//DWord

--Связь модуля dsn_host c ОЗУ
m_host2mem : pcie2mem_ctrl
generic map(
G_MEM_AWIDTH     => C_HREG_MEM_ADR_LAST_BIT,
G_MEM_DWIDTH     => C_HDEV_DWIDTH,
G_MEM_BANK_M_BIT => C_HREG_MEM_ADR_BANK_M_BIT,
G_MEM_BANK_L_BIT => C_HREG_MEM_ADR_BANK_L_BIT,
G_DBG            => "OFF"
)
port map(
-------------------------------------------------------
--Управление
-------------------------------------------------------
p_in_ctrl         => i_host_mem_ctrl(i),
p_out_status      => i_host_mem_status(i),

p_in_txd          => i_utxbuf_din  (i),
p_in_txd_wr       => i_utxbuf_wr  (i),
p_out_txbuf_full  => i_utxbuf_full (i),

p_out_rxd         => i_urxbuf_dout (i),
p_in_rxd_rd       => i_urxbuf_rd  (i),
p_out_rxbuf_empty => i_urxbuf_empty(i),

p_in_hclk         => g_host_clk,

-------------------------------------------------------
--Связь с mem_ctrl
-------------------------------------------------------
p_out_mem         => i_memin_ch(i), --i_host_memin(i),
p_in_mem          => i_memout_ch(i), --i_host_memout(i),

-------------------------------
--Технологический
-------------------------------
p_in_tst          => (others=>'0'),
p_out_tst         => open,--i_host_mem_tst_out,

-------------------------------
--System
-------------------------------
p_in_clk          => i_memout_bank(0).clk,
p_in_rst          => i_host_mem_rst(i) --i_host_mem_rst
);

i_host_mem_rst(i)<=not i_memout_ch(i).rstn;

end generate gen_maxi;

--i_host_mem_rst<=not i_memctrl_ready;


--//Арбитр контроллера памяти
m_mem_arb : mem_arb
generic map(
G_CH_COUNT   => 2, --selval(10#04#,10#03#, strcmp(C_PCFG_TRC_USE,"ON")),--selval2(10#05#,10#04#,10#04#,10#03#, strcmp(C_PCFG_HDD_USE,"ON"),strcmp(C_PCFG_TRC_USE,"ON")),
G_MEM_AWIDTH => C_AXI_AWIDTH, --C_HREG_MEM_ADR_LAST_BIT,
G_MEM_DWIDTH => C_HDEV_DWIDTH
)
port map(
-------------------------------
--Связь с пользователями ОЗУ
-------------------------------
p_in_memch  => i_memin_ch,
p_out_memch => i_memout_ch,

-------------------------------
--Связь с mem_ctrl.vhd
-------------------------------
p_out_mem   => i_arb_memin,
p_in_mem    => i_arb_memout,

-------------------------------
--Технологический
-------------------------------
p_in_tst    => (others=>'0'),
p_out_tst   => open, --i_arb_mem_tst_out,

-------------------------------
--System
-------------------------------
p_in_clk    => i_memout_bank(0).clk,
p_in_rst    => i_memctrl_ready --i_host_mem_rst
);


--//Подключаем арбитра ОЗУ к соотв банку
i_memin_bank(0)<=i_arb_memin;
i_arb_memout   <=i_memout_bank(0);


-- Instantiate target UUT
m_mem_ctrl : mem_ctrl
generic map(
G_SIM => "ON"
)
port map(
-- User Post
p_in_mem   => i_memin_bank,
p_out_mem  => i_memout_bank,

-- DDR3 clocking
ddr3_rst        => i_rst,            -- in    std_logic
ddr3_ref_clk    => i_pll_ref_clk,    -- in    std_logic
ddr3_clk        => i_pll_mem_clk,    -- in    std_logic
-- Memory status
mem_if_rdy      => i_mem_if_rdy ,    -- out   mem_if_rdy_array_t
mem_if_stat     => i_mem_if_stat,    -- out   mem_if_stat_array_t
mem_if_err      => i_mem_if_err ,    -- out   mem_if_err_array_t
-- Memory physical interface
mem_addr_out    => p_out_mem_addr  , -- out   mem_addr_out_t
mem_ctrl_out    => p_out_mem_ctrl  , -- out   mem_ctrl_out_t
mem_data_inout  => p_inout_mem_data, -- inout mem_data_inout_t
mem_clk_out     => p_out_mem_clk   , -- out   mem_clk_out_t
-- Debug info
mem_if_err_info => i_mem_if_err_info -- out   mem_if_debug_array_t
);

i_memctrl_ready<=i_mem_if_rdy(0);-- or i_mem_if_rdy(0) or i_rst;





----------------------------
-- DDR3 SDRAM Bank Models --
----------------------------
ddr3_model_g : for n in DDR3_ST_BANK to (DDR3_ST_BANK+DDR3_MODEL_BANKS-1) generate
  -- Instantiate LS data RAM model
  ddr3_sdram_bank_ls_i : ddr3_sdram
  generic map(
    message_level  => 0,            -- natural;
    part           => TB_DDR3_PART, -- part_t;
    short_init_dly => true)         -- boolean);
  port map(
    ck             => p_out_mem_clk.ddr3_clk_out(n).clk_p(0),                    -- in    std_logic;
    ck_l           => p_out_mem_clk.ddr3_clk_out(n).clk_n(0),                    -- in    std_logic;
    reset_l        => p_out_mem_ctrl.ddr3_ctrl_out(n).reset_l,                   -- in    std_logic;
    cke            => p_out_mem_ctrl.ddr3_ctrl_out(n).cke(0),                    -- in    std_logic;
    cs_l           => p_out_mem_ctrl.ddr3_ctrl_out(n).cs_l(0),                   -- in    std_logic;
    ras_l          => p_out_mem_ctrl.ddr3_ctrl_out(n).ras_l,                     -- in    std_logic;
    cas_l          => p_out_mem_ctrl.ddr3_ctrl_out(n).cas_l,                     -- in    std_logic;
    we_l           => p_out_mem_ctrl.ddr3_ctrl_out(n).we_l,                      -- in    std_logic;
    odt            => p_out_mem_ctrl.ddr3_ctrl_out(n).odt(0),                    -- in    std_logic;
    dm             => p_out_mem_ctrl.ddr3_ctrl_out(n).dm(1 downto 0),            -- in    std_logic_vector(part.part_size.data_bytes-1 downto 0);
    ba             => p_out_mem_ctrl.ddr3_ctrl_out(n).ba,                        -- in    std_logic_vector(part.part_size.bank_width-1 downto 0);
    a              => p_out_mem_addr.ddr3_addr_out(n).a(TB_DDR3_ROW-1 downto 0), -- in    std_logic_vector(part.part_size.arow_width-1 downto 0);
    dq             => p_inout_mem_data.ddr3_data_inout(n).dq(15 downto 0),       -- inout std_logic_vector(part.part_size.data_width-1 downto 0);
    dqs            => p_inout_mem_data.ddr3_data_inout(n).dqs_p(1 downto 0),     -- inout std_logic_vector(part.part_size.data_bytes-1 downto 0);
    dqs_l          => p_inout_mem_data.ddr3_data_inout(n).dqs_n(1 downto 0)      -- inout std_logic_vector(part.part_size.data_bytes-1 downto 0);
  );

  -- Instantiate MS data RAM model
  ddr3_sdram_bank_ms_i : ddr3_sdram
  generic map(
    message_level  => 0,            -- natural;
    part           => TB_DDR3_PART, -- part_t;
    short_init_dly => true)         -- boolean);
  port map(
    ck             => p_out_mem_clk.ddr3_clk_out(n).clk_p(0),                    -- in    std_logic;
    ck_l           => p_out_mem_clk.ddr3_clk_out(n).clk_n(0),                    -- in    std_logic;
    reset_l        => p_out_mem_ctrl.ddr3_ctrl_out(n).reset_l,                   -- in    std_logic;
    cke            => p_out_mem_ctrl.ddr3_ctrl_out(n).cke(0),                    -- in    std_logic;
    cs_l           => p_out_mem_ctrl.ddr3_ctrl_out(n).cs_l(0),                   -- in    std_logic;
    ras_l          => p_out_mem_ctrl.ddr3_ctrl_out(n).ras_l,                     -- in    std_logic;
    cas_l          => p_out_mem_ctrl.ddr3_ctrl_out(n).cas_l,                     -- in    std_logic;
    we_l           => p_out_mem_ctrl.ddr3_ctrl_out(n).we_l,                      -- in    std_logic;
    odt            => p_out_mem_ctrl.ddr3_ctrl_out(n).odt(0),                    -- in    std_logic;
    dm             => p_out_mem_ctrl.ddr3_ctrl_out(n).dm(3 downto 2),            -- in    std_logic_vector(part.part_size.data_bytes-1 downto 0);
    ba             => p_out_mem_ctrl.ddr3_ctrl_out(n).ba,                        -- in    std_logic_vector(part.part_size.bank_width-1 downto 0);
    a              => p_out_mem_addr.ddr3_addr_out(n).a(TB_DDR3_ROW-1 downto 0), -- in    std_logic_vector(part.part_size.arow_width-1 downto 0);
    dq             => p_inout_mem_data.ddr3_data_inout(n).dq(31 downto 16),      -- inout std_logic_vector(part.part_size.data_width-1 downto 0);
    dqs            => p_inout_mem_data.ddr3_data_inout(n).dqs_p(3 downto 2),     -- inout std_logic_vector(part.part_size.data_bytes-1 downto 0);
    dqs_l          => p_inout_mem_data.ddr3_data_inout(n).dqs_n(3 downto 2)      -- inout std_logic_vector(part.part_size.data_bytes-1 downto 0);
  );
end generate;

end test;









--
--i_umem_done  (0)<=i_host_mem_status.done;
--
--i_host_mem_ctrl.dir       <=i_umem_wr    (0);
--i_host_mem_ctrl.start     <=i_umem_start (0);
--i_host_mem_ctrl.adr       <=i_umem_adr    (0);                  --//Byte
--i_host_mem_ctrl.req_len   <=i_umem_dlen_rq(0)(15 downto 0)&"00";--//Byte
--i_host_mem_ctrl.trnwr_len <=i_umem_trn_len(0)(7 downto 0);      --//DWord
--i_host_mem_ctrl.trnrd_len <=i_umem_trn_len(0)(7 downto 0);      --//DWord
--
----Связь модуля dsn_host c ОЗУ
--m_host2mem : pcie2mem_ctrl
--generic map(
--G_MEM_AWIDTH     => C_HREG_MEM_ADR_LAST_BIT,
--G_MEM_DWIDTH     => C_HDEV_DWIDTH,
--G_MEM_BANK_M_BIT => C_HREG_MEM_ADR_BANK_M_BIT,
--G_MEM_BANK_L_BIT => C_HREG_MEM_ADR_BANK_L_BIT,
--G_DBG            => "OFF"
--)
--port map(
---------------------------------------------------------
----Управление
---------------------------------------------------------
--p_in_ctrl         => i_host_mem_ctrl,
--p_out_status      => i_host_mem_status,
--
--p_in_txd          => i_utxbuf_din  (0),
--p_in_txd_wr       => i_utxbuf_wr  (0),
--p_out_txbuf_full  => i_utxbuf_full (0),
--
--p_out_rxd         => i_urxbuf_dout (0),
--p_in_rxd_rd       => i_urxbuf_rd  (0),
--p_out_rxbuf_empty => i_urxbuf_empty(0),
--
--p_in_hclk         => g_host_clk,
--
---------------------------------------------------------
----Связь с mem_ctrl
---------------------------------------------------------
--p_out_mem         => i_host_memin,
--p_in_mem          => i_host_memout,
--
---------------------------------
----Технологический
---------------------------------
--p_in_tst          => (others=>'0'),
--p_out_tst         => open,--i_host_mem_tst_out,
--
---------------------------------
----System
---------------------------------
--p_in_clk          => i_memout_bank(0).clk,
--p_in_rst          => i_host_mem_rst
--);


----//Подключаем устройства к арбитру ОЗУ
--i_memin_ch(0) <= i_host_memin;
--i_host_memout <= i_memout_ch(0);

--i_memin_ch(1) <= i_vctrlwr_memin;
--i_vctrlwr_memout <= i_memout_ch(1);
--
--i_memin_ch(2) <= i_vctrlrd_memin;
--i_vctrlrd_memout <= i_memout_ch(2);
--
----gen_ch34sel0 : if (strcmp(C_PCFG_HDD_USE,"ON")  and strcmp(C_PCFG_TRC_USE,"ON")) or
----                (strcmp(C_PCFG_HDD_USE,"OFF") and strcmp(C_PCFG_TRC_USE,"OFF")) or
----                (strcmp(C_PCFG_HDD_USE,"ON")  and strcmp(C_PCFG_TRC_USE,"OFF")) generate
------CH3
----i_memin_ch(3)<= i_hdd_memin;
----i_hdd_memout    <= i_memout_ch(3);
----
------CH4
----i_memin_ch(4)<= i_trc_memin;
----i_trc_memout    <= i_memout_ch(4);
----
----end generate gen_chs34el0;
----
----gen_ch34sel1 : if (strcmp(C_PCFG_HDD_USE,"OFF") and strcmp(C_PCFG_TRC_USE,"ON")) generate
----CH3
--i_memin_ch(3) <= i_trc_memin;
--i_trc_memout     <= i_memout_ch(3);
--
------CH4
----i_memin_ch(4)<= i_hdd_memin;
----i_hdd_memout    <= i_memout_ch(4);
----
----end generate gen_ch34sel1;