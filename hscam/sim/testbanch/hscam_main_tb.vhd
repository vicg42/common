-------------------------------------------------------------------------
-- Company     : Linkos
-- Engineer    : Golovachenko Victor
--
-- Create Date : 21.01.2012 12:31:12
-- Module Name : hscam_main_tb
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

library unisim;
use unisim.vcomponents.all;

library work;
use work.vicg_common_pkg.all;
use work.video_ctrl_pkg.all;
use work.mem_wr_pkg.all;
use work.mem_ctrl_pkg.all;
use work.prj_cfg.all;
use work.sata_glob_pkg.all;

entity hscam_main_tb is
generic(
G_SIM    : string:="ON"
);
end hscam_main_tb;

architecture behavioral of hscam_main_tb is

component hscam_main
generic(
G_VOUT_DWIDTH : integer:=16;
G_VSYN_ACTIVE : std_logic:='0';
G_SIM : string:="OFF"
);
port(
--------------------------------------------------
--SATA
--------------------------------------------------
pin_out_sata_txn   : out   std_logic_vector((C_SH_GTCH_COUNT_MAX*C_SH_COUNT_MAX(C_PCFG_HDD_COUNT-1))-1 downto 0);
pin_out_sata_txp   : out   std_logic_vector((C_SH_GTCH_COUNT_MAX*C_SH_COUNT_MAX(C_PCFG_HDD_COUNT-1))-1 downto 0);
pin_in_sata_rxn    : in    std_logic_vector((C_SH_GTCH_COUNT_MAX*C_SH_COUNT_MAX(C_PCFG_HDD_COUNT-1))-1 downto 0);
pin_in_sata_rxp    : in    std_logic_vector((C_SH_GTCH_COUNT_MAX*C_SH_COUNT_MAX(C_PCFG_HDD_COUNT-1))-1 downto 0);
pin_in_sata_clk_n  : in    std_logic_vector(C_SH_COUNT_MAX(C_PCFG_HDD_COUNT-1)-1 downto 0);
pin_in_sata_clk_p  : in    std_logic_vector(C_SH_COUNT_MAX(C_PCFG_HDD_COUNT-1)-1 downto 0);

--------------------------------------------------
--RAM
--------------------------------------------------
pin_out_mcb1_a        : out   std_logic_vector(12 downto 0);--(C5_MEM_ADDR_WIDTH-1 downto 0);
pin_out_mcb1_ba       : out   std_logic_vector(2 downto 0) ;--(C5_MEM_BANKADDR_WIDTH-1 downto 0);
pin_out_mcb1_ras_n    : out   std_logic;
pin_out_mcb1_cas_n    : out   std_logic;
pin_out_mcb1_we_n     : out   std_logic;
pin_out_mcb1_odt      : out   std_logic;
pin_out_mcb1_cke      : out   std_logic;
pin_out_mcb1_dm       : out   std_logic;
pin_out_mcb1_udm      : out   std_logic;
pin_out_mcb1_ck       : out   std_logic;
pin_out_mcb1_ck_n     : out   std_logic;
pin_inout_mcb1_dq     : inout std_logic_vector(15 downto 0);--(C5_NUM_DQ_PINS-1 downto 0);
pin_inout_mcb1_udqs   : inout std_logic;
pin_inout_mcb1_udqs_n : inout std_logic;
pin_inout_mcb1_dqs    : inout std_logic;
pin_inout_mcb1_dqs_n  : inout std_logic;
pin_inout_mcb1_rzq    : inout std_logic;
pin_inout_mcb1_zio    : inout std_logic;

pin_out_mcb5_a        : out   std_logic_vector(12 downto 0);--(C5_MEM_ADDR_WIDTH-1 downto 0);
pin_out_mcb5_ba       : out   std_logic_vector(2 downto 0) ;--(C5_MEM_BANKADDR_WIDTH-1 downto 0);
pin_out_mcb5_ras_n    : out   std_logic;
pin_out_mcb5_cas_n    : out   std_logic;
pin_out_mcb5_we_n     : out   std_logic;
pin_out_mcb5_odt      : out   std_logic;
pin_out_mcb5_cke      : out   std_logic;
pin_out_mcb5_dm       : out   std_logic;
pin_out_mcb5_udm      : out   std_logic;
pin_out_mcb5_ck       : out   std_logic;
pin_out_mcb5_ck_n     : out   std_logic;
pin_inout_mcb5_dq     : inout std_logic_vector(15 downto 0);--(C5_NUM_DQ_PINS-1 downto 0);
pin_inout_mcb5_udqs   : inout std_logic;
pin_inout_mcb5_udqs_n : inout std_logic;
pin_inout_mcb5_dqs    : inout std_logic;
pin_inout_mcb5_dqs_n  : inout std_logic;
pin_inout_mcb5_rzq    : inout std_logic;
pin_inout_mcb5_zio    : inout std_logic;

--------------------------------------------------
-- Reference clock
--------------------------------------------------
pin_in_refclk_n       : in    std_logic;
pin_in_refclk_p       : in    std_logic;

--------------------------------------------------
--Технологический порт
--------------------------------------------------
pin_inout_ftdi_d   : inout std_logic_vector(7 downto 0);
pin_out_ftdi_rd_n  : out   std_logic;
pin_out_ftdi_wr_n  : out   std_logic;
pin_in_ftdi_txe_n  : in    std_logic;
pin_in_ftdi_rxf_n  : in    std_logic;
pin_in_ftdi_pwren_n: in    std_logic;

pin_out_TP2        : out   std_logic_vector(1 downto 0);
pin_in_SW          : in    std_logic_vector(3 downto 0);
pin_out_TP         : out   std_logic_vector(7 downto 0);
pin_out_led        : out   std_logic_vector(7 downto 0)
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

constant C5_CLK_PERIOD_NS   : real := 6600.0 / 1000.0; --constant C5_CLK_PERIOD_NS   : real := 3200.0 / 1000.0;
constant C5_TCYC_SYS        : real := C5_CLK_PERIOD_NS/2.0;
constant C5_TCYC_SYS_DIV2   : time := C5_TCYC_SYS * 1 ns;

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

signal i_refclk_p            : std_logic:='0';
signal i_refclk_n            : std_logic:='1';

signal i_sataclk             : std_logic_vector(C_SH_COUNT_MAX(C_PCFG_HDD_COUNT-1)-1 downto 0):=(others=> '0');
signal i_sataclk_n           : std_logic_vector(C_SH_COUNT_MAX(C_PCFG_HDD_COUNT-1)-1 downto 0):=(others=> '1');


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

gen_sata_clk : for i in 0 to C_SH_COUNT_MAX(C_PCFG_HDD_COUNT-1)-1 generate
i_sataclk(i)  <=    p_in_clk;
i_sataclk_n(i)<=not p_in_clk;
end generate gen_sata_clk;

i_refclk_n<=    p_in_clk;
i_refclk_p<=not p_in_clk;


-- ========================================================================== --
-- Reset Generation                                                           --
-- ========================================================================== --
process
begin
  i_rst <= '0';
  wait for 3 us;--200 ns;
  i_rst <= '1';
  wait;
end process;

p_in_rst <= i_rst when (C5_RST_ACT_LOW = 1) else (not i_rst);


m_hscam_main : hscam_main
generic map(
G_VOUT_DWIDTH => 16,
G_VSYN_ACTIVE => '0',
G_SIM => G_SIM
)
port map(
--------------------------------------------------
--SATA
--------------------------------------------------
pin_out_sata_txn   => open,
pin_out_sata_txp   => open,
pin_in_sata_rxn    => (others=>'0'),
pin_in_sata_rxp    => (others=>'0'),
pin_in_sata_clk_n  => i_sataclk,
pin_in_sata_clk_p  => i_sataclk_n,

--------------------------------------------------
--RAM
--------------------------------------------------
pin_out_mcb5_a        => p_out_phymem  (1).a     ,
pin_out_mcb5_ba       => p_out_phymem  (1).ba    ,
pin_out_mcb5_ras_n    => p_out_phymem  (1).ras_n ,
pin_out_mcb5_cas_n    => p_out_phymem  (1).cas_n ,
pin_out_mcb5_we_n     => p_out_phymem  (1).we_n  ,
pin_out_mcb5_odt      => p_out_phymem  (1).odt   ,
pin_out_mcb5_cke      => p_out_phymem  (1).cke   ,
pin_out_mcb5_dm       => p_out_phymem  (1).dm    ,
pin_out_mcb5_udm      => p_out_phymem  (1).udm   ,
pin_out_mcb5_ck       => p_out_phymem  (1).ck    ,
pin_out_mcb5_ck_n     => p_out_phymem  (1).ck_n  ,
pin_inout_mcb5_dq     => p_inout_phymem(1).dq    ,
pin_inout_mcb5_udqs   => p_inout_phymem(1).udqs  ,
pin_inout_mcb5_udqs_n => p_inout_phymem(1).udqs_n,
pin_inout_mcb5_dqs    => p_inout_phymem(1).dqs   ,
pin_inout_mcb5_dqs_n  => p_inout_phymem(1).dqs_n ,
pin_inout_mcb5_rzq    => p_inout_phymem(1).rzq   ,
pin_inout_mcb5_zio    => p_inout_phymem(1).zio   ,

pin_out_mcb1_a        => p_out_phymem  (0).a     ,
pin_out_mcb1_ba       => p_out_phymem  (0).ba    ,
pin_out_mcb1_ras_n    => p_out_phymem  (0).ras_n ,
pin_out_mcb1_cas_n    => p_out_phymem  (0).cas_n ,
pin_out_mcb1_we_n     => p_out_phymem  (0).we_n  ,
pin_out_mcb1_odt      => p_out_phymem  (0).odt   ,
pin_out_mcb1_cke      => p_out_phymem  (0).cke   ,
pin_out_mcb1_dm       => p_out_phymem  (0).dm    ,
pin_out_mcb1_udm      => p_out_phymem  (0).udm   ,
pin_out_mcb1_ck       => p_out_phymem  (0).ck    ,
pin_out_mcb1_ck_n     => p_out_phymem  (0).ck_n  ,
pin_inout_mcb1_dq     => p_inout_phymem(0).dq    ,
pin_inout_mcb1_udqs   => p_inout_phymem(0).udqs  ,
pin_inout_mcb1_udqs_n => p_inout_phymem(0).udqs_n,
pin_inout_mcb1_dqs    => p_inout_phymem(0).dqs   ,
pin_inout_mcb1_dqs_n  => p_inout_phymem(0).dqs_n ,
pin_inout_mcb1_rzq    => p_inout_phymem(0).rzq   ,
pin_inout_mcb1_zio    => p_inout_phymem(0).zio   ,

--------------------------------------------------
-- Reference clock
--------------------------------------------------
pin_in_refclk_n    => i_refclk_n,
pin_in_refclk_p    => i_refclk_p,

--------------------------------------------------
--Технологический порт
--------------------------------------------------
pin_inout_ftdi_d   => open,
pin_out_ftdi_rd_n  => open,
pin_out_ftdi_wr_n  => open,
pin_in_ftdi_txe_n  => '1',
pin_in_ftdi_rxf_n  => '1',
pin_in_ftdi_pwren_n=> '1',

pin_out_TP2        => open,
pin_in_SW          => "0000",
pin_out_TP         => open,
pin_out_led        => open
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

