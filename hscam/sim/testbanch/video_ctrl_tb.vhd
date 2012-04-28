-------------------------------------------------------------------------
-- Company     : Linkos
-- Engineer    : Golovachenko Victor
--
-- Create Date : 21.01.2012 12:31:12
-- Module Name : video_ctrl_tb
--
-- Назначение/Описание :
--
-- Revision:
-- Revision 0.01 - File Created
-------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

library unisim;
use unisim.vcomponents.all;

library work;
use work.vicg_common_pkg.all;
use work.video_ctrl_pkg.all;
use work.mem_wr_pkg.all;
use work.mem_ctrl_pkg.all;
use work.prj_cfg.all;
--use work.hdd_main_unit_pkg.all;

entity video_ctrl_tb is
generic(
G_VSYN_ACTIVE : std_logic:='0';
G_VOUT_DWIDTH : integer:=16;
G_MEM_AWIDTH  : integer:=32;
G_MEM_DWIDTH  : integer:=64;
G_SIM    : string:="ON"
);
end video_ctrl_tb;

architecture behavioral of video_ctrl_tb is

component vtiming_gen
generic(
G_VSYN_ACTIVE: std_logic:='1';
G_VS_WIDTH   : integer:=32;
G_HS_WIDTH   : integer:=32;
G_PIX_COUNT  : integer:=32;
G_ROW_COUNT  : integer:=32
);
port(
p_out_vs : out  std_logic;
p_out_hs : out  std_logic;

p_in_clk : in   std_logic;
p_in_rst : in   std_logic
);
end component;

component vin_hdd
generic(
G_VBUF_OWIDTH : integer:=32;
G_VSYN_ACTIVE : std_logic:='1';
G_EXTSYN      : string:="OFF"
);
port(
--Вх. видеопоток
p_in_vd            : in   std_logic_vector((10*8*2)-1 downto 0);--(99 downto 0);
p_in_vs            : in   std_logic;
p_in_hs            : in   std_logic;
p_in_vclk          : in   std_logic;
p_in_ext_syn       : in   std_logic;

p_out_vfr_prm      : out  TFrXY;

--Вых. видеобуфера
p_out_vbufin_d     : out  std_logic_vector(G_VBUF_OWIDTH-1 downto 0);
p_in_vbufin_rd     : in   std_logic;
p_out_vbufin_empty : out  std_logic;
p_out_vbufin_full  : out  std_logic;
p_in_vbufin_wrclk  : in   std_logic;
p_in_vbufin_rdclk  : in   std_logic;

--Технологический
p_in_tst           : in    std_logic_vector(31 downto 0);
p_out_tst          : out   std_logic_vector(31 downto 0);

--System
p_in_rst           : in   std_logic
);
end component;

component vout
generic(
G_VBUF_IWIDTH : integer:=32;
G_VBUF_OWIDTH : integer:=32;
G_VSYN_ACTIVE : std_logic:='1'
);
port(
--Вых. видеопоток
p_out_vd         : out  std_logic_vector(G_VBUF_OWIDTH-1 downto 0);
p_in_vs          : in   std_logic;
p_in_hs          : in   std_logic;
p_in_vclk        : in   std_logic;

--Вх. видеобуфера
p_in_vd          : in   std_logic_vector(G_VBUF_IWIDTH-1 downto 0);
p_in_vd_wr       : in   std_logic;
p_in_hd          : in   std_logic_vector(G_VBUF_IWIDTH-1 downto 0);
p_in_hd_wr       : in   std_logic;
p_in_sel         : in   std_logic;

p_out_vbufo_full : out  std_logic;
p_out_vbufo_pfull: out  std_logic;
p_out_vbufo_empty: out  std_logic;
p_in_vbufo_wrclk : in   std_logic;

p_in_rst         : in   std_logic
);
end component;

component video_ctrl
generic(
G_SIM    : string:="OFF";
G_MEM_BANK_M_BIT : integer:=32;
G_MEM_BANK_L_BIT : integer:=31;
G_MEM_AWIDTH : integer:=32;
G_MEM_DWIDTH : integer:=32
);
port(
-------------------------------
--
-------------------------------
p_in_vfr_prm          : in    TFrXY;
p_in_mem_trn_len      : in    std_logic_vector(15 downto 0);
p_in_vch_off          : in    std_logic;
p_in_vrd_off          : in    std_logic;

----------------------------
--Связь с вх/вых видеобуферами
----------------------------
--Вх
p_in_vbufin_d         : in    std_logic_vector(G_MEM_DWIDTH-1 downto 0);
p_out_vbufin_rd       : out   std_logic;
p_in_vbufin_empty     : in    std_logic;
--Вых
p_out_vbufout_d       : out   std_logic_vector(G_MEM_DWIDTH-1 downto 0);
p_out_vbufout_wr      : out   std_logic;
p_in_vbufout_full     : in    std_logic;

---------------------------------
--Связь с mem_ctrl.vhd
---------------------------------
--CH WRITE
p_out_memwr           : out   TMemIN;
p_in_memwr            : in    TMemOUT;
--CH READ
p_out_memrd           : out   TMemIN;
p_in_memrd            : in    TMemOUT;

-------------------------------
--Технологический
-------------------------------
p_out_tst             : out   std_logic_vector(31 downto 0);

-------------------------------
--System
-------------------------------
p_in_clk              : in    std_logic;
p_in_rst              : in    std_logic
);
end component;

component ddr2_model_c5 is
port (
ck      : in    std_logic;
ck_n    : in    std_logic;
cke     : in    std_logic;
cs_n    : in    std_logic;
ras_n   : in    std_logic;
cas_n   : in    std_logic;
we_n    : in    std_logic;
dm_rdqs : inout std_logic_vector((C5_NUM_DQ_PINS/16) downto 0);
ba      : in    std_logic_vector((C5_MEM_BANKADDR_WIDTH - 1) downto 0);
addr    : in    std_logic_vector((C5_MEM_ADDR_WIDTH  - 1) downto 0);
dq      : inout std_logic_vector((C5_NUM_DQ_PINS - 1) downto 0);
dqs     : inout std_logic_vector((C5_NUM_DQ_PINS/16) downto 0);
dqs_n   : inout std_logic_vector((C5_NUM_DQ_PINS/16) downto 0);
rdqs_n  : out   std_logic_vector((C5_NUM_DQ_PINS/16) downto 0);
odt     : in    std_logic
);
end component;

constant C5_CLK_PERIOD_NS    : real := 3300.0 / 1000.0;
constant C5_TCYC_SYS         : real := C5_CLK_PERIOD_NS/2.0;
constant C5_TCYC_SYS_DIV2    : time := C5_TCYC_SYS * 1 ns;

constant C_USRPLL_CLKIN_PERIOD : time := 8 ns;--125MHz
--constant PERIOD_HCLK         : time := 30 * 1 ns;
--constant PERIOD_VBUFI_CLK    : time := 30 * 1 ns;
--constant PERIOD_VIN_CLK      : time := 30 * 1 ns;
--constant PERIOD_VOUT_CLK     : time := 60 * 1 ns;


signal i_rst                 : std_logic;
signal p_in_rst              : std_logic;
signal p_in_clk              : std_logic := '0';

signal p_out_phymem          : TMEMCTRL_phy_outs;
signal p_inout_phymem        : TMEMCTRL_phy_inouts;

type TV01 is array(0 to C_MEM_BANK_COUNT-1) of std_logic_vector(1 downto 0) ;
type TV02 is array(0 to C_MEM_BANK_COUNT-1) of std_logic_vector(2 downto 0) ;
signal mcb5_dram_dqs_vector  : TV01;
signal mcb5_dram_dqs_n_vector: TV01;
signal mcb5_dram_dm_vector   : TV01;
signal mcb5_command          : TV02;
signal mcb5_enable1          : std_logic_vector(C_MEM_BANK_COUNT-1 downto 0);
signal mcb5_enable2          : std_logic_vector(C_MEM_BANK_COUNT-1 downto 0);
signal rzq5                  : std_logic_vector(C_MEM_BANK_COUNT-1 downto 0);
signal zio5                  : std_logic_vector(C_MEM_BANK_COUNT-1 downto 0);

signal i_mem_in_bank         : TMemINBank;
signal i_mem_out_bank        : TMemOUTBank;
signal i_mem_ctrl_status     : TMEMCTRL_status;
signal i_mem_ctrl_sysin      : TMEMCTRL_sysin;
signal i_mem_ctrl_sysout     : TMEMCTRL_sysout;

signal i_vctrl_rst           : std_logic;
signal i_vfr_prm             : TFrXY;
signal i_vctrl_mem_trn_len   : std_logic_vector(15 downto 0);
signal i_hm_r                : std_logic;

signal i_usrpll_clkin                   : std_logic:='0';
signal i_usrpll_clkfb                   : std_logic;
signal i_usrpll_clkout                  : std_logic_vector(1 downto 0);
signal g_usrpll_clkout                  : std_logic_vector(1 downto 0);
signal i_usrpll_lock                    : std_logic;

signal i_vtg_rst                        : std_logic;

signal g_hclk                           : std_logic:='0';
signal g_vbufi_wrclk                    : std_logic:='0';

signal i_vctrl_bufi_rst                 : std_logic;
signal i_vbufo_rst                      : std_logic;

type TDtest   is array(0 to 9) of std_logic_vector(7 downto 0);
signal i_tdata                          : TDtest;
signal p_in_vd                          : std_logic_vector(79 downto 0):=(others=>'0');
signal p_in_vin_vs                      : std_logic;--//Строб кодровой синхронизации
signal p_in_vin_hs                      : std_logic;--//Строб строчной синхронизации
signal p_in_vin_clk                     : std_logic;--//Пиксельная частота
--signal p_in_ext_syn                     : std_logic;--//Внешняя синхронизация записи

signal p_out_vd                         : std_logic_vector(G_VOUT_DWIDTH-1 downto 0);
signal p_in_vout_vs                     : std_logic;--//Строб кодровой синхронизации
signal p_in_vout_hs                     : std_logic;--//Строб строчной синхронизации
signal p_in_vout_clk                    : std_logic;--//Пиксельная частота

signal i_vdi                            : std_logic_vector((10*8)-1 downto 0):=(others=>'0');
signal i_vdi_save                       : std_logic_vector((10*8)-1 downto 0):=(others=>'0');
signal i_vdi_vector                     : std_logic_vector((10*8*2)-1 downto 0);

signal i_vctrl_bufi_dout                : std_logic_vector(G_MEM_DWIDTH-1 downto 0);
signal i_vctrl_bufi_rd                  : std_logic;
signal i_vctrl_bufi_full                : std_logic;
signal i_vctrl_bufi_empty               : std_logic;
signal i_vctrl_bufo_din                 : std_logic_vector(G_MEM_DWIDTH-1 downto 0);
signal i_vctrl_bufo_wr                  : std_logic;

signal i_vbufo_dout                     : std_logic_vector(G_VOUT_DWIDTH-1 downto 0);
signal i_vbufo_full                     : std_logic;
signal i_vbufo_pfull                    : std_logic;
signal i_vbufo_empty                    : std_logic;

signal p_in_sim_mem                     : TMemOUTBank;

--MAIN
begin

-- ========================================================================== --
-- Clocks Generation                                                          --
-- ========================================================================== --
process
begin
  p_in_clk <= not p_in_clk;
  wait for (C5_TCYC_SYS_DIV2);
end process;

process
begin
  i_usrpll_clkin <= not i_usrpll_clkin;
  wait for (C_USRPLL_CLKIN_PERIOD);
end process;

m_usrpll : PLL_ADV
generic map(
BANDWIDTH          => "OPTIMIZED",
CLKIN1_PERIOD      => 8.0, --125MHz
CLKIN2_PERIOD      => 8.0,
CLKOUT0_DIVIDE     => 8, --clk0 = ((125MHz * 21)/5) /8  = 65.625MHz - Clk_Vin
CLKOUT1_DIVIDE     => 9, --clk1 = ((125MHz * 21)/5) /13 = 40.385MHz - Clk_Vout
CLKOUT2_DIVIDE     => 5,
CLKOUT3_DIVIDE     => 9,
CLKOUT4_DIVIDE     => 8,
CLKOUT5_DIVIDE     => 8,
CLKOUT0_PHASE      => 0.000,
CLKOUT1_PHASE      => 0.000,
CLKOUT2_PHASE      => 0.000,
CLKOUT3_PHASE      => 0.000,
CLKOUT4_PHASE      => 0.000,
CLKOUT5_PHASE      => 0.000,
CLKOUT0_DUTY_CYCLE => 0.500,
CLKOUT1_DUTY_CYCLE => 0.500,
CLKOUT2_DUTY_CYCLE => 0.500,
CLKOUT3_DUTY_CYCLE => 0.500,
CLKOUT4_DUTY_CYCLE => 0.500,
CLKOUT5_DUTY_CYCLE => 0.500,
SIM_DEVICE         => "SPARTAN6",
COMPENSATION       => "INTERNAL",--"DCM2PLL",--
DIVCLK_DIVIDE      => 5,
CLKFBOUT_MULT      => 21,
CLKFBOUT_PHASE     => 0.0,
REF_JITTER         => 0.005000
)
port map(
CLKFBIN          => i_usrpll_clkfb,
CLKINSEL         => '1',
CLKIN1           => i_usrpll_clkin,--g_usr_refclk150,
CLKIN2           => '0',
DADDR            => (others => '0'),
DCLK             => '0',
DEN              => '0',
DI               => (others => '0'),
DWE              => '0',
REL              => '0',
RST              => p_in_rst,
CLKFBDCM         => open,
CLKFBOUT         => i_usrpll_clkfb,
CLKOUTDCM0       => open,
CLKOUTDCM1       => open,
CLKOUTDCM2       => open,
CLKOUTDCM3       => open,
CLKOUTDCM4       => open,
CLKOUTDCM5       => open,
CLKOUT0          => p_in_vin_clk,--i_usrpll_clkout(0),
CLKOUT1          => p_in_vout_clk,--i_usrpll_clkout(1),
CLKOUT2          => open,
CLKOUT3          => open,
CLKOUT4          => open,
CLKOUT5          => open,
DO               => open,
DRDY             => open,
LOCKED           => i_usrpll_lock
);

--p_in_vin_clk <=g_usrpll_clkout(0);
--p_in_vout_clk<=g_usrpll_clkout(1);

i_mem_ctrl_sysin.clk<=p_in_clk;

g_hclk<=i_mem_ctrl_sysout.gusrclk(1);

g_vbufi_wrclk<=i_mem_ctrl_sysout.gusrclk(0);


-- ========================================================================== --
-- Reset Generation                                                           --
-- ========================================================================== --
process
begin
  i_rst <= '0';
  wait for 5 us;--200 ns;
  i_rst <= '1';
  wait;
end process;

p_in_rst <= i_rst when (C5_RST_ACT_LOW = 1) else (not i_rst);


i_vtg_rst<=not i_usrpll_lock;

i_mem_ctrl_sysin.rst<=p_in_rst;

i_vctrl_rst<=not i_mem_ctrl_status.rdy(0) or p_in_rst;

i_vctrl_bufi_rst<=i_vctrl_rst;
i_vbufo_rst     <=i_vctrl_rst;
--i_vfr_prm.pix<=CONV_STD_LOGIC_VECTOR(CI_FRPIX, i_vfr_prm.pix'length);
--i_vfr_prm.row<=CONV_STD_LOGIC_VECTOR(CI_FRROW, i_vfr_prm.pix'length);

i_vctrl_mem_trn_len( 7 downto 0)<=CONV_STD_LOGIC_VECTOR(64, 8);--write
i_vctrl_mem_trn_len(15 downto 8)<=CONV_STD_LOGIC_VECTOR(32, 8);--read


--Генератор тестовых данных (Вертикальные полоски!!!)
gen_vtstd : for i in 1 to 10 generate
process(i_vtg_rst,p_in_vin_clk)
begin
  if i_vtg_rst='1' then
    i_tdata(i-1)<=CONV_STD_LOGIC_VECTOR(i, i_tdata(i-1)'length);
  elsif p_in_vin_clk'event and p_in_vin_clk='1' then
    if p_in_vin_vs=G_VSYN_ACTIVE or p_in_vin_hs=G_VSYN_ACTIVE then
      i_tdata(i-1)<=CONV_STD_LOGIC_VECTOR(i-1, i_tdata(i-1)'length);
    else
      i_tdata(i-1)<=i_tdata(i-1) + CONV_STD_LOGIC_VECTOR(10, i_tdata(i-1)'length);
    end if;
  end if;
end process;

p_in_vd((8*i)-1 downto (8*i)-8)<=i_tdata(i-1);
end generate gen_vtstd;

m_vtgen_high : vtiming_gen
generic map(
G_VSYN_ACTIVE=> G_VSYN_ACTIVE,
G_VS_WIDTH   => 32,
G_HS_WIDTH   => 16,
G_PIX_COUNT  => (C_PCFG_FRPIX/10),
G_ROW_COUNT  => C_PCFG_FRROW
)
port map(
p_out_vs => p_in_vin_vs,
p_out_hs => p_in_vin_hs,

p_in_clk => p_in_vin_clk,
p_in_rst => i_vtg_rst
);

m_vtgen_low : vtiming_gen
generic map(
G_VSYN_ACTIVE=> G_VSYN_ACTIVE,
G_VS_WIDTH   => 32,
G_HS_WIDTH   => 8,
G_PIX_COUNT  => (C_PCFG_FRPIX/(G_VOUT_DWIDTH/8)),
G_ROW_COUNT  => C_PCFG_FRROW
)
port map(
p_out_vs => p_in_vout_vs,
p_out_hs => p_in_vout_hs,

p_in_clk => p_in_vout_clk,
p_in_rst => i_vtg_rst
);


--Video Input
--//Берем 8 старших бит из пердолгаемых 10 бит на 1Pixel
gen_vd : for i in 1 to 10 generate
i_vdi((8*i)-1 downto 8*(i-1))<=p_in_vd((8*i)-1 downto (8*i)-8);-- when i_hdd_rbuf_cfg.tstgen.tesing_on='0' else tst_vin_d((8*i)-1 downto (8*i)-8);
process(p_in_vin_clk)
begin
  if p_in_vin_clk'event and p_in_vin_clk='1' then
    i_vdi_save((8*i)-1 downto 8*(i-1))<=i_vdi((8*i)-1 downto 8*(i-1));
  end if;
end process;
end generate gen_vd;

i_vdi_vector<=i_vdi & i_vdi_save;

m_vctrl_bufi : vin_hdd
generic map(
G_VBUF_OWIDTH => G_MEM_DWIDTH,
G_VSYN_ACTIVE => G_VSYN_ACTIVE,
G_EXTSYN      => C_VIN_HDD_EXTSYN
)
port map(
--Вх. видеопоток
p_in_vd            => i_vdi_vector,
p_in_vs            => p_in_vin_vs,
p_in_hs            => p_in_vin_hs,
p_in_vclk          => p_in_vin_clk,
p_in_ext_syn       => '1',--p_in_ext_syn,

p_out_vfr_prm      => i_vfr_prm,

--Вых. видеобуфера
p_out_vbufin_d     => i_vctrl_bufi_dout,
p_in_vbufin_rd     => i_vctrl_bufi_rd,
p_out_vbufin_empty => i_vctrl_bufi_empty,
p_out_vbufin_full  => i_vctrl_bufi_full,
p_in_vbufin_wrclk  => g_vbufi_wrclk,
p_in_vbufin_rdclk  => g_hclk,

--Технологический
p_in_tst           => (others=>'0'),
p_out_tst          => open,

--System
p_in_rst           => i_vctrl_bufi_rst
);

m_vctrl : video_ctrl
generic map(
G_SIM => G_SIM,
G_MEM_BANK_M_BIT => 31,
G_MEM_BANK_L_BIT => 31,
G_MEM_AWIDTH => G_MEM_AWIDTH,
G_MEM_DWIDTH => G_MEM_DWIDTH
)
port map(
-------------------------------
--
-------------------------------
p_in_vfr_prm         => i_vfr_prm,
p_in_mem_trn_len     => i_vctrl_mem_trn_len,
p_in_vch_off         => '0',--i_hdd_rbuf_cfg.grst_vch,
p_in_vrd_off         => '0',--i_hdd_rbuf_cfg.dmacfg.hm_r,

----------------------------
--Связь с вх/вых видеобуферами
----------------------------
--in
p_in_vbufin_d         => i_vctrl_bufi_dout,
p_out_vbufin_rd       => i_vctrl_bufi_rd,
p_in_vbufin_empty     => i_vctrl_bufi_empty,
--out
p_out_vbufout_d       => i_vctrl_bufo_din,
p_out_vbufout_wr      => i_vctrl_bufo_wr,
p_in_vbufout_full     => i_vbufo_pfull,

---------------------------------
--Связь с mem_ctrl.vhd
---------------------------------
--CH WRITE                                    --Bank|CH
p_out_memwr           => i_mem_in_bank (0)(0),--: out   TMemIN;
p_in_memwr            => i_mem_out_bank(0)(0),--: in    TMemOUT;
--CH READ
p_out_memrd           => i_mem_in_bank (0)(1),--: out   TMemIN;
p_in_memrd            => i_mem_out_bank(0)(1),--: in    TMemOUT;

-------------------------------
--Технологический
-------------------------------
p_out_tst             => open,

-------------------------------
--System
-------------------------------
p_in_clk              => g_hclk,
p_in_rst              => i_vctrl_rst
);


m_vbufo : vout
generic map(
G_VBUF_IWIDTH => G_MEM_DWIDTH,
G_VBUF_OWIDTH => G_VOUT_DWIDTH,
G_VSYN_ACTIVE => G_VSYN_ACTIVE
)
port map(
p_out_vd         => i_vbufo_dout,--p_out_vd,
p_in_vs          => p_in_vout_vs,
p_in_hs          => p_in_vout_hs,
p_in_vclk        => p_in_vout_clk,

p_in_vd          => i_vctrl_bufo_din,
p_in_vd_wr       => i_vctrl_bufo_wr,
p_in_hd          => (others=>'0'),--i_hdd_bufo_din,
p_in_hd_wr       => '0',--i_hdd_bufo_wr,
p_in_sel         => '0',--i_hdd_rbuf_cfg.dmacfg.hm_r,

p_out_vbufo_full => i_vbufo_full,
p_out_vbufo_pfull=> i_vbufo_pfull,
p_out_vbufo_empty=> i_vbufo_empty,
p_in_vbufo_wrclk => g_hclk,

p_in_rst         => i_vbufo_rst
);

m_mem_ctrl : mem_ctrl
generic map(
G_SIM => G_SIM
)
port map(
------------------------------------
--User Post
------------------------------------
p_in_mem        => i_mem_in_bank, --TMemINBank;
p_out_mem       => i_mem_out_bank,--TMemOUTBank;

------------------------------------
--Memory physical interface
------------------------------------
p_out_phymem    => p_out_phymem,
p_inout_phymem  => p_inout_phymem,

------------------------------------
--Memory status
------------------------------------
p_out_status    => i_mem_ctrl_status,

-----------------------------------
--Sim
-----------------------------------
p_out_sim_mem   => open,
p_in_sim_mem    => p_in_sim_mem,

------------------------------------
--System
------------------------------------
p_out_sys       => i_mem_ctrl_sysout,
p_in_sys        => i_mem_ctrl_sysin
);




gen_bank : for i in 0 to C_MEM_BANK_COUNT-1 generate
-- ========================================================================== --
-- Memory model instances                                                     --
-- ========================================================================== --
-- The PULLDOWN component is connected to the ZIO signal primarily to avoid the
-- unknown state in simulation. In real hardware, ZIO should be a no connect(NC) pin.

mcb5_command(i) <= (p_out_phymem(i).ras_n & p_out_phymem(i).cas_n & p_out_phymem(i).we_n);

process(p_out_phymem(i).ck)--mcb5_dram_ck)
begin
  if (rising_edge(p_out_phymem(i).ck)) then --if (rising_edge(mcb5_dram_ck)) then
    if (i_rst = '0') then
      mcb5_enable1(i) <= '0';
      mcb5_enable2(i) <= '0';
    elsif (mcb5_command(i) = "100") then
      mcb5_enable2(i) <= '0';
    elsif (mcb5_command(i) = "101") then
      mcb5_enable2(i) <= '1';
    else
      mcb5_enable2(i) <= mcb5_enable2(i);
    end if;
    mcb5_enable1(i)   <= mcb5_enable2(i);
  end if;
end process;

-----------------------------------------------------------------------------
--read
-----------------------------------------------------------------------------
mcb5_dram_dqs_vector(i)(1 downto 0)  <= (p_inout_phymem(i).udqs & p_inout_phymem(i).dqs)     when (mcb5_enable2(i) = '0' and mcb5_enable1(i) = '0') else "ZZ";
mcb5_dram_dqs_n_vector(i)(1 downto 0)<= (p_inout_phymem(i).udqs_n & p_inout_phymem(i).dqs_n) when (mcb5_enable2(i) = '0' and mcb5_enable1(i) = '0') else "ZZ";

-----------------------------------------------------------------------------
--write
-----------------------------------------------------------------------------
p_inout_phymem(i).dqs    <= mcb5_dram_dqs_vector(i)(0)   when (mcb5_enable1(i) = '1') else 'Z';
p_inout_phymem(i).udqs   <= mcb5_dram_dqs_vector(i)(1)   when (mcb5_enable1(i) = '1') else 'Z';
p_inout_phymem(i).dqs_n  <= mcb5_dram_dqs_n_vector(i)(0) when (mcb5_enable1(i) = '1') else 'Z';
p_inout_phymem(i).udqs_n <= mcb5_dram_dqs_n_vector(i)(1) when (mcb5_enable1(i) = '1') else 'Z';

mcb5_dram_dm_vector(i) <= (p_out_phymem(i).udm & p_out_phymem(i).dm);

u_mem_c5 : ddr2_model_c5
port map(
ck        => p_out_phymem(i).ck,    --mcb5_dram_ck,
ck_n      => p_out_phymem(i).ck_n,  --mcb5_dram_ck_n,
cke       => p_out_phymem(i).cke,   --mcb5_dram_cke,
cs_n      => '0',
ras_n     => p_out_phymem(i).ras_n, --mcb5_dram_ras_n,
cas_n     => p_out_phymem(i).cas_n, --mcb5_dram_cas_n,
we_n      => p_out_phymem(i).we_n,  --mcb5_dram_we_n,
dm_rdqs   => mcb5_dram_dm_vector(i),
ba        => p_out_phymem(i).ba,    --mcb5_dram_ba,
addr      => p_out_phymem(i).a,     --mcb5_dram_a,
dq        => p_inout_phymem(i).dq,  --mcb5_dram_dq,
dqs       => mcb5_dram_dqs_vector(i),
dqs_n     => mcb5_dram_dqs_n_vector(i),
rdqs_n    => open,
odt       => p_out_phymem(i).odt    --mcb5_dram_odt
);

zio_pulldown5 : PULLDOWN port map(O => p_inout_phymem(i).zio);--zio5);
rzq_pulldown5 : PULLDOWN port map(O => p_inout_phymem(i).rzq);--rzq5);

end generate gen_bank;


--END MAIN
end behavioral;

