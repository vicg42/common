-------------------------------------------------------------------------
-- Company     : Linkos
-- Engineer    : Golovachenko Victor
--
-- Create Date : 21.01.2012 13:40:16
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

library work;
use work.vicg_common_pkg.all;
use work.mem_ctrl_pkg.all;

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
--Sim
------------------------------------
p_out_sim_mem  : out   TMemINBank;
p_in_sim_mem   : in    TMemOUTBank;

------------------------------------
--System
------------------------------------
p_out_sys      : out   TMEMCTRL_sysout;
p_in_sys       : in    TMEMCTRL_sysin
);
end mem_ctrl;

architecture arc of mem_ctrl is


constant C5_SIMULATION : string := selstring("FALSE","TRUE", strcmp(G_SIM, "OFF"));

component memc5_infrastructure is
    generic (
      C_RST_ACT_LOW        : integer;
      C_INPUT_CLK_TYPE     : string;
      C_CLKOUT0_DIVIDE     : integer;
      C_CLKOUT1_DIVIDE     : integer;
      C_CLKOUT2_DIVIDE     : integer;
      C_CLKOUT3_DIVIDE     : integer;
      C_CLKFBOUT_MULT      : integer;
      C_DIVCLK_DIVIDE      : integer;
      C_INCLK_PERIOD       : integer

      );
    port (
      p_out_locked    : out std_logic;
      p_out_gusrclk   : out std_logic_vector(1 downto 0);
      sys_clk_p                              : in    std_logic;
      sys_clk_n                              : in    std_logic;
      sys_clk                                : in    std_logic;
      sys_rst_i                              : in    std_logic;
      clk0                                   : out   std_logic;
      rst0                                   : out   std_logic;
      async_rst                              : out   std_logic;
      sysclk_2x                              : out   std_logic;
      sysclk_2x_180                          : out   std_logic;
      pll_ce_0                               : out   std_logic;
      pll_ce_90                              : out   std_logic;
      pll_lock                               : out   std_logic;
      mcb_drp_clk                            : out   std_logic

      );
  end component;







   constant C5_CLKOUT0_DIVIDE       : integer := 1; --c5_sysclk_2x
   constant C5_CLKOUT1_DIVIDE       : integer := 1; --c5_sysclk_2x_180
   constant C5_CLKOUT2_DIVIDE       : integer := 16;--p_out_pll_gclkusr
   constant C5_CLKOUT3_DIVIDE       : integer := 8; --c5_mcb_drp_clk
   constant C5_CLKFBOUT_MULT        : integer := 2;
   constant C5_DIVCLK_DIVIDE        : integer := 1;

   constant C5_INCLK_PERIOD         : integer := ((C5_MEMCLK_PERIOD * C5_CLKFBOUT_MULT) / (C5_DIVCLK_DIVIDE * C5_CLKOUT0_DIVIDE * 2));

--   constant C5_CLKOUT0_DIVIDE       : integer := C_MEMPLL_CLKOUT0_DIVIDE;
--   constant C5_CLKOUT1_DIVIDE       : integer := C_MEMPLL_CLKOUT1_DIVIDE;
--   constant C5_CLKOUT2_DIVIDE       : integer := C_MEMPLL_CLKOUT2_DIVIDE;
--   constant C5_CLKOUT3_DIVIDE       : integer := C_MEMPLL_CLKOUT3_DIVIDE;
--   constant C5_CLKFBOUT_MULT        : integer := C_MEMPLL_CLKFBOUT_MULT ;
--   constant C5_DIVCLK_DIVIDE        : integer := C_MEMPLL_DIVCLK_DIVIDE ;
--
--   constant C5_INCLK_PERIOD         : integer := C5_MEMCLK_PERIOD;--((C5_MEMCLK_PERIOD * C5_CLKFBOUT_MULT) / (C5_DIVCLK_DIVIDE * C5_CLKOUT0_DIVIDE * 2));



  signal  c5_sys_clk_p                             : std_logic;
  signal  c5_sys_clk_n                             : std_logic;
  signal  c5_async_rst                             : std_logic;
  signal  c5_sysclk_2x                             : std_logic;
  signal  c5_sysclk_2x_180                         : std_logic;
  signal  c5_pll_ce_0                              : std_logic;
  signal  c5_pll_ce_90                             : std_logic;
  signal  c5_pll_lock                              : std_logic;
  signal  c5_mcb_drp_clk                           : std_logic;
  signal  c5_cmp_error                             : std_logic;
  signal  c5_cmp_data_valid                        : std_logic;
  signal  c5_vio_modify_enable                     : std_logic;
  signal  c5_error_status                          : std_logic_vector(191 downto 0);
  signal  c5_vio_data_mode_value                   : std_logic_vector(2 downto 0);
  signal  c5_vio_addr_mode_value                   : std_logic_vector(2 downto 0);
  signal  c5_cmp_data                              : std_logic_vector(31 downto 0);
  signal  c5_selfrefresh_enter                     : std_logic;
  signal  c5_selfrefresh_mode                      : std_logic;



begin


c5_sys_clk_p <= '0';
c5_sys_clk_n <= '0';
--c5_selfrefresh_enter <= '0';
memc5_infrastructure_inst : memc5_infrastructure
generic map(
C_RST_ACT_LOW     => C5_RST_ACT_LOW,--0,--
C_INPUT_CLK_TYPE  => C5_INPUT_CLK_TYPE,
C_CLKOUT0_DIVIDE  => C5_CLKOUT0_DIVIDE,
C_CLKOUT1_DIVIDE  => C5_CLKOUT1_DIVIDE,
C_CLKOUT2_DIVIDE  => C5_CLKOUT2_DIVIDE,
C_CLKOUT3_DIVIDE  => C5_CLKOUT3_DIVIDE,
C_CLKFBOUT_MULT   => C5_CLKFBOUT_MULT,
C_DIVCLK_DIVIDE   => C5_DIVCLK_DIVIDE,
C_INCLK_PERIOD    => C5_INCLK_PERIOD
)
port map(
p_out_locked    => p_out_sys.pll_lock,
p_out_gusrclk   => p_out_sys.gusrclk,
sys_clk_p         => c5_sys_clk_p,
sys_clk_n         => c5_sys_clk_n,
sys_clk           => p_in_sys.clk,--c5_sys_clk,
sys_rst_i         => p_in_sys.rst,--c5_sys_rst_i,
clk0              => p_out_sys.clk,--open,-- C5_CLKOUT2_DIVIDE,
rst0              => open,--c5_rst0,
async_rst         => c5_async_rst,
sysclk_2x         => c5_sysclk_2x,
sysclk_2x_180     => c5_sysclk_2x_180,
pll_ce_0          => c5_pll_ce_0,
pll_ce_90         => c5_pll_ce_90,
pll_lock          => c5_pll_lock,
mcb_drp_clk       => c5_mcb_drp_clk
);


-- wrapper instantiation
gen_bank : for i in 0 to C_MEM_BANK_COUNT-1 generate


p_inout_phymem(i).dq     <=(others=>'Z'); --mcb5_dram_dq     : inout std_logic_vector((C_NUM_DQ_PINS-1) downto 0);
p_out_phymem  (i).a      <=(others=>'0'); --mcb5_dram_a      : out   std_logic_vector((C_MEM_ADDR_WIDTH-1) downto 0);
p_out_phymem  (i).ba     <=(others=>'0'); --mcb5_dram_ba     : out   std_logic_vector((C_MEM_BANKADDR_WIDTH-1) downto 0);
p_out_phymem  (i).ras_n  <='0';           --mcb5_dram_ras_n  : out   std_logic;
p_out_phymem  (i).cas_n  <='0';           --mcb5_dram_cas_n  : out   std_logic;
p_out_phymem  (i).we_n   <='0';           --mcb5_dram_we_n   : out   std_logic;
p_out_phymem  (i).odt    <='0';           --mcb5_dram_odt    : out   std_logic;
p_out_phymem  (i).cke    <='0';           --mcb5_dram_cke    : out   std_logic;
p_out_phymem  (i).dm     <='0';           --mcb5_dram_dm     : out   std_logic;
p_inout_phymem(i).udqs   <='Z';           --mcb5_dram_udqs   : inout std_logic;
p_inout_phymem(i).udqs_n <='Z';           --mcb5_dram_udqs_n : inout std_logic;
p_inout_phymem(i).rzq    <='Z';           --mcb5_rzq         : inout std_logic;
p_inout_phymem(i).zio    <='Z';           --mcb5_zio         : inout std_logic;
p_out_phymem  (i).udm    <='0';           --mcb5_dram_udm    : out   std_logic;
p_inout_phymem(i).dqs    <='Z';           --mcb5_dram_dqs    : inout std_logic;
p_inout_phymem(i).dqs_n  <='Z';           --mcb5_dram_dqs_n  : inout std_logic;
p_out_phymem  (i).ck     <='0';           --mcb5_dram_ck     : out   std_logic;
p_out_phymem  (i).ck_n   <='0';           --mcb5_dram_ck_n   : out   std_logic;


--//CH0
p_out_sim_mem (i)(0).clk    <= p_in_mem (i)(0).clk   ;
p_out_sim_mem (i)(0).cmd_wr <= p_in_mem (i)(0).cmd_wr;
p_out_sim_mem (i)(0).cmd_i  <= p_in_mem (i)(0).cmd_i ;
p_out_sim_mem (i)(0).cmd_bl <= p_in_mem (i)(0).cmd_bl;
p_out_sim_mem (i)(0).adr(C_MEMCTRL_AWIDTH-1 downto 0)<=p_in_mem (i)(0).adr(C_MEMCTRL_AWIDTH-1 downto 0);

p_out_mem(i)(0).cmdbuf_empty<= p_in_sim_mem(i)(0).cmdbuf_empty;
p_out_mem(i)(0).cmdbuf_full <= p_in_sim_mem(i)(0).cmdbuf_full ;

p_out_sim_mem (i)(0).txd_wr                                     <= p_in_mem (i)(0).txd_wr;
p_out_sim_mem (i)(0).txd_be(C_MEMCTRL_CH0_BEWIDTH - 1 downto 0) <= p_in_mem (i)(0).txd_be(C_MEMCTRL_CH0_BEWIDTH - 1 downto 0);
p_out_sim_mem (i)(0).txd(C_MEMCTRL_CH0_DWIDTH - 1 downto 0)     <= p_in_mem (i)(0).txd(C_MEMCTRL_CH0_DWIDTH - 1 downto 0);

p_out_mem(i)(0).txbuf_full    <=p_in_sim_mem(i)(0).txbuf_full     ;
p_out_mem(i)(0).txbuf_empty   <=p_in_sim_mem(i)(0).txbuf_empty    ;
p_out_mem(i)(0).txbuf_wrcount <=p_in_sim_mem(i)(0).txbuf_wrcount  ;
p_out_mem(i)(0).txbuf_underrun<=p_in_sim_mem(i)(0).txbuf_underrun ;
p_out_mem(i)(0).txbuf_err     <=p_in_sim_mem(i)(0).txbuf_err      ;

p_out_sim_mem (i)(0).rxd_rd <= p_in_mem (i)(0).rxd_rd;

p_out_mem(i)(0).rxd(C_MEMCTRL_CH0_DWIDTH - 1 downto 0)<=p_in_sim_mem(i)(0).rxd(C_MEMCTRL_CH0_DWIDTH - 1 downto 0) ;
p_out_mem(i)(0).rxbuf_full                            <=p_in_sim_mem(i)(0).rxbuf_full                             ;
p_out_mem(i)(0).rxbuf_empty                           <=p_in_sim_mem(i)(0).rxbuf_empty                            ;
p_out_mem(i)(0).rxbuf_rdcount                         <=p_in_sim_mem(i)(0).rxbuf_rdcount                          ;
p_out_mem(i)(0).rxbuf_overflow                        <=p_in_sim_mem(i)(0).rxbuf_overflow                         ;
p_out_mem(i)(0).rxbuf_err                             <=p_in_sim_mem(i)(0).rxbuf_err                              ;

--//CH1
p_out_sim_mem (i)(1).clk    <= p_in_mem (i)(1).clk   ;
p_out_sim_mem (i)(1).cmd_wr <= p_in_mem (i)(1).cmd_wr;
p_out_sim_mem (i)(1).cmd_i  <= p_in_mem (i)(1).cmd_i ;
p_out_sim_mem (i)(1).cmd_bl <= p_in_mem (i)(1).cmd_bl;
p_out_sim_mem (i)(1).adr(C_MEMCTRL_AWIDTH-1 downto 0)<=p_in_mem (i)(1).adr(C_MEMCTRL_AWIDTH-1 downto 0);

p_out_mem(i)(1).cmdbuf_empty<= p_in_sim_mem(i)(1).cmdbuf_empty;
p_out_mem(i)(1).cmdbuf_full <= p_in_sim_mem(i)(1).cmdbuf_full ;

p_out_sim_mem (i)(1).txd_wr                                     <= p_in_mem (i)(1).txd_wr;
p_out_sim_mem (i)(1).txd_be(C_MEMCTRL_CH0_BEWIDTH - 1 downto 0) <= p_in_mem (i)(1).txd_be(C_MEMCTRL_CH0_BEWIDTH - 1 downto 0);
p_out_sim_mem (i)(1).txd(C_MEMCTRL_CH0_DWIDTH - 1 downto 0)     <= p_in_mem (i)(1).txd(C_MEMCTRL_CH0_DWIDTH - 1 downto 0);

p_out_mem(i)(1).txbuf_full    <=p_in_sim_mem(i)(1).txbuf_full     ;
p_out_mem(i)(1).txbuf_empty   <=p_in_sim_mem(i)(1).txbuf_empty    ;
p_out_mem(i)(1).txbuf_wrcount <=p_in_sim_mem(i)(1).txbuf_wrcount  ;
p_out_mem(i)(1).txbuf_underrun<=p_in_sim_mem(i)(1).txbuf_underrun ;
p_out_mem(i)(1).txbuf_err     <=p_in_sim_mem(i)(1).txbuf_err      ;

p_out_sim_mem (i)(1).rxd_rd <= p_in_mem (i)(1).rxd_rd;

p_out_mem(i)(1).rxd(C_MEMCTRL_CH0_DWIDTH - 1 downto 0)<=p_in_sim_mem(i)(1).rxd(C_MEMCTRL_CH0_DWIDTH - 1 downto 0) ;
p_out_mem(i)(1).rxbuf_full                            <=p_in_sim_mem(i)(1).rxbuf_full                             ;
p_out_mem(i)(1).rxbuf_empty                           <=p_in_sim_mem(i)(1).rxbuf_empty                            ;
p_out_mem(i)(1).rxbuf_rdcount                         <=p_in_sim_mem(i)(1).rxbuf_rdcount                          ;
p_out_mem(i)(1).rxbuf_overflow                        <=p_in_sim_mem(i)(1).rxbuf_overflow                         ;
p_out_mem(i)(1).rxbuf_err                             <=p_in_sim_mem(i)(1).rxbuf_err                              ;


p_out_status.rdy(i)<=c5_pll_lock;

--p_out_mem(i).rxd<=(others=>'0');
--p_out_mem(i).rxbuf_full<='1';
--p_out_mem(i).rxbuf_empty<='1';
--p_out_mem(i).rxbuf_rdcount<=(others=>'0');
--p_out_mem(i).rxbuf_overflow<='0';
--p_out_mem(i).rxbuf_err<='0';
--
--p_out_mem(i).txbuf_full<='1';
--p_out_mem(i).txbuf_empty<='1';
--p_out_mem(i).txbuf_wrcount<=(others=>'0');
--p_out_mem(i).txbuf_underrun<='0';
--p_out_mem(i).txbuf_err<='0';

end generate gen_bank;


gen_bank2_null : if C_MEM_BANK_COUNT=1 generate
p_out_phymem  (1).a        <= (others=>'Z');
p_out_phymem  (1).ba       <= (others=>'Z');
p_out_phymem  (1).ras_n    <= 'Z';
p_out_phymem  (1).cas_n    <= 'Z';
p_out_phymem  (1).we_n     <= 'Z';
p_out_phymem  (1).odt      <= 'Z';
p_out_phymem  (1).cke      <= 'Z';
p_out_phymem  (1).dm       <= 'Z';
p_out_phymem  (1).udm      <= 'Z';
p_out_phymem  (1).ck       <= 'Z';
p_out_phymem  (1).ck_n     <= 'Z';
p_inout_phymem(1).dq     <= (others=>'Z');
p_inout_phymem(1).udqs   <= 'Z';
p_inout_phymem(1).udqs_n <= 'Z';
p_inout_phymem(1).dqs    <= 'Z';
p_inout_phymem(1).dqs_n  <= 'Z';
p_inout_phymem(1).rzq    <= 'Z';
p_inout_phymem(1).zio    <= 'Z';

end generate gen_bank2_null;


end  arc;
