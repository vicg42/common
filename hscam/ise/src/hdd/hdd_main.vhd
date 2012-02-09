-------------------------------------------------------------------------
-- Company     : Linkos
-- Engineer    : Golovachenko Victor + Kukla Anatol
--
-- Create Date : 18.01.2012 17:24:28
-- Module Name : hdd_main
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
use ieee.std_logic_arith.all;
use ieee.std_logic_misc.all;
use ieee.std_logic_unsigned.all;

library unisim;
use unisim.vcomponents.all;

library work;
use work.vicg_common_pkg.all;
use work.prj_cfg.all;
use work.cfgdev_pkg.all;
use work.sata_glob_pkg.all;
use work.dsn_hdd_pkg.all;
use work.hdd_main_unit_pkg.all;
use work.video_ctrl_pkg.all;
use work.mem_ctrl_pkg.all;

entity hdd_main is
generic(
G_VSYN_ACTIVE : std_logic:='1';
G_VOUT_DWIDTH : integer:=32;
G_SIM : string:="OFF"
);
port(
--------------------------------------------------
--VideoIN
--------------------------------------------------
p_in_vd       : in   std_logic_vector(99 downto 0);
p_in_vin_vs   : in   std_logic;
p_in_vin_hs   : in   std_logic;
p_in_vin_clk  : in   std_logic;

--------------------------------------------------
--VideoOUT
--------------------------------------------------
p_out_vd      : out  std_logic_vector(G_VOUT_DWIDTH-1 downto 0);
p_in_vout_vs  : in   std_logic;
p_in_vout_hs  : in   std_logic;
p_in_vout_clk : in   std_logic;

--------------------------------------------------
--RAM
--------------------------------------------------
p_out_mcb5_a        : out   std_logic_vector(12 downto 0);
p_out_mcb5_ba       : out   std_logic_vector(2 downto 0) ;
p_out_mcb5_ras_n    : out   std_logic;
p_out_mcb5_cas_n    : out   std_logic;
p_out_mcb5_we_n     : out   std_logic;
p_out_mcb5_odt      : out   std_logic;
p_out_mcb5_cke      : out   std_logic;
p_out_mcb5_dm       : out   std_logic;
p_out_mcb5_udm      : out   std_logic;
p_out_mcb5_ck       : out   std_logic;
p_out_mcb5_ck_n     : out   std_logic;
p_inout_mcb5_dq     : inout std_logic_vector(15 downto 0);
p_inout_mcb5_udqs   : inout std_logic;
p_inout_mcb5_udqs_n : inout std_logic;
p_inout_mcb5_dqs    : inout std_logic;
p_inout_mcb5_dqs_n  : inout std_logic;
p_inout_mcb5_rzq    : inout std_logic;
p_inout_mcb5_zio    : inout std_logic;

p_out_mcb1_a        : out   std_logic_vector(12 downto 0);
p_out_mcb1_ba       : out   std_logic_vector(2 downto 0) ;
p_out_mcb1_ras_n    : out   std_logic;
p_out_mcb1_cas_n    : out   std_logic;
p_out_mcb1_we_n     : out   std_logic;
p_out_mcb1_odt      : out   std_logic;
p_out_mcb1_cke      : out   std_logic;
p_out_mcb1_dm       : out   std_logic;
p_out_mcb1_udm      : out   std_logic;
p_out_mcb1_ck       : out   std_logic;
p_out_mcb1_ck_n     : out   std_logic;
p_inout_mcb1_dq     : inout std_logic_vector(15 downto 0);
p_inout_mcb1_udqs   : inout std_logic;
p_inout_mcb1_udqs_n : inout std_logic;
p_inout_mcb1_dqs    : inout std_logic;
p_inout_mcb1_dqs_n  : inout std_logic;
p_inout_mcb1_rzq    : inout std_logic;
p_inout_mcb1_zio    : inout std_logic;

--------------------------------------------------
--SATA
--------------------------------------------------
p_out_sata_txn      : out   std_logic_vector((C_SH_GTCH_COUNT_MAX*C_SH_COUNT_MAX(C_PCFG_HDD_COUNT-1))-1 downto 0);--std_logic_vector(3 downto 0);
p_out_sata_txp      : out   std_logic_vector((C_SH_GTCH_COUNT_MAX*C_SH_COUNT_MAX(C_PCFG_HDD_COUNT-1))-1 downto 0);--std_logic_vector(3 downto 0);
p_in_sata_rxn       : in    std_logic_vector((C_SH_GTCH_COUNT_MAX*C_SH_COUNT_MAX(C_PCFG_HDD_COUNT-1))-1 downto 0);--std_logic_vector(3 downto 0);
p_in_sata_rxp       : in    std_logic_vector((C_SH_GTCH_COUNT_MAX*C_SH_COUNT_MAX(C_PCFG_HDD_COUNT-1))-1 downto 0);--std_logic_vector(3 downto 0);
p_in_sata_clk_n     : in    std_logic_vector(C_SH_COUNT_MAX(C_PCFG_HDD_COUNT-1)-1 downto 0);                      --std_logic_vector(0 downto 0);
p_in_sata_clk_p     : in    std_logic_vector(C_SH_COUNT_MAX(C_PCFG_HDD_COUNT-1)-1 downto 0);                      --std_logic_vector(0 downto 0);

--------------------------------------------------
--System
--------------------------------------------------
p_out_hdd_grefclk150M : out   std_logic;

p_out_hdd_dcm_lock    : out   std_logic;
p_out_hdd_dcm_gclk75M : out   std_logic;
p_out_hdd_dcm_gclk300M: out   std_logic;
p_out_hdd_dcm_gclk150M: out   std_logic;

p_out_usrpll_lock     : out   std_logic;
p_out_usrpll_gclk1    : out   std_logic;

--------------------------------------------------
--Технологический порт
--------------------------------------------------
p_inout_ftdi_d   : inout std_logic_vector(7 downto 0);
p_out_ftdi_rd_n  : out   std_logic;
p_out_ftdi_wr_n  : out   std_logic;
p_in_ftdi_txe_n  : in    std_logic;
p_in_ftdi_rxf_n  : in    std_logic;
p_in_ftdi_pwren_n: in    std_logic;

p_out_TP         : out   std_logic_vector(7 downto 0);
p_out_led        : out   std_logic_vector(7 downto 0)
);
end entity;

architecture struct of hdd_main is

component dbgcs_iconx1
  PORT (
    CONTROL0 : INOUT STD_LOGIC_VECTOR(35 DOWNTO 0));
--    CONTROL1 : INOUT STD_LOGIC_VECTOR(35 DOWNTO 0));

end component;

component dbgcs_iconx2
  PORT (
    CONTROL0 : INOUT STD_LOGIC_VECTOR(35 DOWNTO 0);
    CONTROL1 : INOUT STD_LOGIC_VECTOR(35 DOWNTO 0));

end component;

component dbgcs_iconx3
  PORT (
    CONTROL0 : INOUT STD_LOGIC_VECTOR(35 DOWNTO 0);
    CONTROL1 : INOUT STD_LOGIC_VECTOR(35 DOWNTO 0);
    CONTROL2 : INOUT STD_LOGIC_VECTOR(35 DOWNTO 0));

end component;

component dbgcs_sata_layer
  PORT (
    CONTROL : INOUT STD_LOGIC_VECTOR(35 DOWNTO 0);
    CLK : IN STD_LOGIC;
    DATA : IN STD_LOGIC_VECTOR(122 DOWNTO 0);
    TRIG0 : IN STD_LOGIC_VECTOR(41 DOWNTO 0)
    );
end component;

component dbgcs_sata_raid
  PORT (
    CONTROL : INOUT STD_LOGIC_VECTOR(35 DOWNTO 0);
    CLK : IN STD_LOGIC;
    DATA : IN STD_LOGIC_VECTOR(172 downto 0); --(122 DOWNTO 0);
    TRIG0 : IN STD_LOGIC_VECTOR(41 DOWNTO 0)
    );
end component;

component dbgcs_sata_rbuf
  PORT (
    CONTROL : INOUT STD_LOGIC_VECTOR(35 DOWNTO 0);
    CLK : IN STD_LOGIC;
    DATA : IN STD_LOGIC_VECTOR(136 downto 0); --(122 DOWNTO 0);
    TRIG0 : IN STD_LOGIC_VECTOR(41 DOWNTO 0)
    );
end component;

signal i_dbgcs_sh0_spd                  : std_logic_vector(35 downto 0);
signal i_dbgcs_hdd0_layer               : std_logic_vector(35 downto 0);
signal i_dbgcs_hdd1_layer               : std_logic_vector(35 downto 0);
signal i_dbgcs_hdd_raid                 : std_logic_vector(35 downto 0);
signal i_dbgcs_cfg                      : std_logic_vector(35 downto 0);
signal i_dbgcs_hdd_rbuf                 : std_logic_vector(35 downto 0);

signal i_hdd0layer_dbgcs                : TSH_ila;
signal i_hdd1layer_dbgcs                : TSH_ila;
signal i_cfg_dbgcs                      : TSH_ila;
signal i_hddraid_dbgcs                  : TSH_ila;

component clock is
generic(
G_USRCLK_COUNT : integer:=1
);
port(
p_out_gusrclk  : out std_logic_vector(G_USRCLK_COUNT-1 downto 0);
p_out_pll_lock : out std_logic;

p_in_clk       : in  std_logic;
p_in_rst       : in  std_logic
);
end component;

constant CI_MEM_BANK_M_BIT : integer:=C_MEMCTRL_AWIDTH+1;
constant CI_MEM_BANK_L_BIT : integer:=C_MEMCTRL_AWIDTH+1;
constant CI_MEM_AWIDTH     : integer:=32;
constant CI_MEM_DWIDTH     : integer:=C_MEMCTRL_DWIDTH;

signal i_vfr_prm                        : TFrXY;

signal i_vbufin_dout                    : std_logic_vector(CI_MEM_DWIDTH-1 downto 0);
signal i_vbufin_rd                      : std_logic;
signal i_vbufin_empty                   : std_logic;
signal i_vbufout_din                    : std_logic_vector(CI_MEM_DWIDTH-1 downto 0);
signal i_vbufout_wr                     : std_logic;
signal i_vbufout_full                   : std_logic;
signal i_hdd_vbufin_dout                : std_logic_vector(CI_MEM_DWIDTH-1 downto 0);
signal i_hdd_vbufin_rd                  : std_logic;
signal i_hdd_vbufin_empty               : std_logic;
signal i_hdd_vbufin_full                : std_logic;
signal i_hdd_vbufin_pfull               : std_logic;
signal i_hdd_vbufin_wrcnt               : std_logic_vector(3 downto 0);
signal i_hbufout_din                    : std_logic_vector(CI_MEM_DWIDTH-1 downto 0);
signal i_hbufout_wr                     : std_logic;
signal i_hbufout_sel                    : std_logic;

signal i_mem_ctrl_rst                   : std_logic;
signal i_mem_ctrl_rdy                   : std_logic_vector(C_MEM_BANK_COUNT-1 downto 0);
signal i_memch0_in_bank                 : TMemINBank;
signal i_memch0_out_bank                : TMemOUTBank;
signal i_memch1_in_bank                 : TMemINBank;
signal i_memch1_out_bank                : TMemOUTBank;

signal i_phymem_out                     : TRam_outs;
signal i_phymem_inout                   : TRam_inouts;

signal i_usrpll_rst                     : std_logic;
signal i_usrpll_lock                    : std_logic;
signal g_usrpll_clkout                  : std_logic_vector(5 downto 0);
signal g_memclkin                       : std_logic;
signal g_hclk                           : std_logic;
signal g_hdd_clk                        : std_logic;
signal g_vbuf_iclk                      : std_logic;

signal i_hdd_rambuf_rst                 : std_logic;
signal i_vctrl_rst                      : std_logic;
signal i_sys_rst_cnt                    : std_logic_vector(5 downto 0):=(others=>'0');
signal i_sys_rst                        : std_logic:='0';
signal g_sata_refclkout                 : std_logic;

signal i_hdd_rst                        : std_logic;
signal i_hdd_gt_refclk150               : std_logic_vector(C_SH_COUNT_MAX(C_PCFG_HDD_COUNT-1)-1 downto 0);
signal g_hdd_gt_refclkout               : std_logic;
signal i_hdd_gt_plldet                  : std_logic;
signal i_hdd_dcm_lock                   : std_logic;
signal g_hdd_dcm_gclk75M                : std_logic;
signal g_hdd_dcm_gclk300M               : std_logic;
signal g_hdd_dcm_gclk150M               : std_logic;

signal i_hdd_rbuf_cfg                   : THDDRBufCfg;
signal i_hdd_rbuf_status                : THDDRBufStatus;

signal i_hdd_txdata                     : std_logic_vector(CI_MEM_DWIDTH-1 downto 0);
signal i_hdd_txdata_wd                  : std_logic;
signal i_hdd_txbuf_full                 : std_logic;
signal i_hdd_txbuf_pfull                : std_logic;
signal i_hdd_txbuf_empty                : std_logic;

signal i_hdd_rxdata                     : std_logic_vector(CI_MEM_DWIDTH-1 downto 0);
signal i_hdd_rxdata_rd                  : std_logic;
signal i_hdd_rxbuf_empty                : std_logic;
signal i_hdd_rxbuf_pempty               : std_logic;

signal i_dev_adr                        : std_logic_vector(C_CFGPKT_DADR_M_BIT-C_CFGPKT_DADR_L_BIT downto 0);
signal i_cfg_adr                        : std_logic_vector(C_CFGPKT_RADR_M_BIT-C_CFGPKT_RADR_L_BIT downto 0);
signal i_cfg_adr_ld                     : std_logic;
signal i_cfg_adr_fifo                   : std_logic;
signal i_cfg_wd                         : std_logic;
signal i_cfg_rd                         : std_logic;
signal i_cfg_txd                        : std_logic_vector(15 downto 0);
signal i_cfg_rxd                        : std_logic_vector(15 downto 0);
signal i_cfg_txrdy                      : std_logic;
signal i_cfg_rxrdy                      : std_logic;
signal i_cfg_done                       : std_logic;
signal g_cfg_clk                        : std_logic;
--signal i_cfg_tstout                     : std_logic_vector(31 downto 0);

signal i_hdd_module_rdy                 : std_logic;
signal i_hdd_module_error               : std_logic;
signal i_hdd_busy                       : std_logic;
--signal i_hdd_hirq                       : std_logic;
signal i_hdd_done                       : std_logic;

signal i_hdd_dbgcs                      : TSH_dbgcs_exp;
signal i_hdd_dbgled                     : THDDLed_SHCountMax;

--signal i_hdd_sim_gt_txdata              : TBus32_SHCountMax;
--signal i_hdd_sim_gt_txcharisk           : TBus04_SHCountMax;
--signal i_hdd_sim_gt_txcomstart          : std_logic_vector(C_HDD_COUNT_MAX-1 downto 0);
signal i_hdd_sim_gt_rxdata              : TBus32_SHCountMax;
signal i_hdd_sim_gt_rxcharisk           : TBus04_SHCountMax;
signal i_hdd_sim_gt_rxstatus            : TBus03_SHCountMax;
signal i_hdd_sim_gt_rxelecidle          : std_logic_vector(C_HDD_COUNT_MAX-1 downto 0);
signal i_hdd_sim_gt_rxdisperr           : TBus04_SHCountMax;
signal i_hdd_sim_gt_rxnotintable        : TBus04_SHCountMax;
signal i_hdd_sim_gt_rxbyteisaligned     : std_logic_vector(C_HDD_COUNT_MAX-1 downto 0);
--signal i_hdd_sim_gt_sim_rst             : std_logic_vector(C_HDD_COUNT_MAX-1 downto 0);
--signal i_hdd_sim_gt_sim_clk             : std_logic_vector(C_HDD_COUNT_MAX-1 downto 0);
--signal i_hdd_tst_in                     : std_logic_vector(31 downto 0);
signal i_hdd_tst_out                    : std_logic_vector(31 downto 0);

signal i_test01_led                     : std_logic;
signal i_test02_led                     : std_logic;

signal tst_vin_hdd_out                  : std_logic_vector(31 downto 0);
signal tst_hdd_rambuf_out               : std_logic_vector(31 downto 0);
signal tst_vctrl_out                    : std_logic_vector(31 downto 0);
signal sr_vctrl_rst                     : std_logic_vector(1 downto 0):=(others=>'0');
signal tst_syn                          : std_logic:='0';

signal tst_vin_vs                       : std_logic;
signal tst_vin_hs                       : std_logic;
signal tst_vout_vs                      : std_logic;
signal tst_vout_hs                      : std_logic;

signal t_vbufin_rd                      : std_logic;
signal t_vbufin_empty                   : std_logic;


signal i_tmrout_en                      : std_logic:='0';
signal i_tmrout_cnt                     : std_logic_vector(15 downto 0):=(others=>'0');
signal i_tmrout,sr_tmrout               : std_logic:='0';
signal i_tmrout_det                     : std_logic:='0';


--//MAIN
begin


--***********************************************************
--
--***********************************************************
p_out_hdd_grefclk150M<=g_sata_refclkout;

p_out_hdd_dcm_lock    <=i_hdd_dcm_lock;
p_out_hdd_dcm_gclk75M <=g_hdd_dcm_gclk75M;
p_out_hdd_dcm_gclk300M<=g_hdd_dcm_gclk300M;
p_out_hdd_dcm_gclk150M<=g_hdd_dcm_gclk150M;

p_out_usrpll_lock<=i_usrpll_lock;

i_usrpll_rst<=not i_hdd_dcm_lock;

m_usrpll : clock
generic map(
G_USRCLK_COUNT => 3
)
port map(
p_out_gusrclk  => g_usrpll_clkout(3-1 downto 0),
p_out_pll_lock => i_usrpll_lock,

p_in_clk       => g_sata_refclkout,
p_in_rst       => i_usrpll_rst
);

g_memclkin<=g_usrpll_clkout(0);

p_out_usrpll_gclk1<=g_usrpll_clkout(1);

g_cfg_clk<=g_hdd_dcm_gclk75M;--g_hdd_dcm_gclk300M;--g_usrpll_clkout(2); --g_sata_refclkout;--g_sata_refclkout;--
g_hdd_clk<=g_hdd_dcm_gclk75M;--g_usrpll_clkout(2); --g_sata_refclkout;--g_sata_refclkout;--g_sata_refclkout;

--частота переписывания данных внутренних буферов для модулей vin_cam,vin_hdd
g_vbuf_iclk<=g_hdd_dcm_gclk300M;
--частота работы с ОЗУ
g_hclk   <=g_hdd_dcm_gclk75M;--g_usrpll_clkout(2); --g_sata_refclkout;--g_sata_refclkout;--g_memclkin;--


--***********************************************************
--RESET
--***********************************************************
process(g_sata_refclkout)
begin
  if g_sata_refclkout'event and g_sata_refclkout = '1' then
    if i_sys_rst_cnt(i_sys_rst_cnt'high) = '0' then
      i_sys_rst_cnt <= i_sys_rst_cnt + 1;
    end if;
  end if;
end process;

i_sys_rst <= i_sys_rst_cnt(i_sys_rst_cnt'high - 1);
i_hdd_rst <= i_sys_rst or i_hdd_rbuf_cfg.greset;
i_vctrl_rst<= i_sys_rst or not (AND_reduce(i_mem_ctrl_rdy)) or (i_hbufout_sel and i_hdd_rbuf_cfg.dmacfg.clr_err);
i_hdd_rambuf_rst<=i_sys_rst or not (AND_reduce(i_mem_ctrl_rdy)) ;
i_mem_ctrl_rst <= not i_usrpll_lock;



--***********************************************************
--VIDEO IN/OUT
--***********************************************************
--Video Input
m_vin_cam : vin_cam
generic map(
G_VBUF_OWIDTH => CI_MEM_DWIDTH,
G_VSYN_ACTIVE => G_VSYN_ACTIVE
)
port map(
p_in_vd            => p_in_vd,
p_in_vs            => p_in_vin_vs,
p_in_hs            => p_in_vin_hs,
p_in_vclk          => p_in_vin_clk,

p_out_vfr_prm      => i_vfr_prm,

p_out_vbufin_d     => i_vbufin_dout,
p_in_vbufin_rd     => i_vbufin_rd,
p_out_vbufin_empty => i_vbufin_empty,
p_in_vbufin_rdclk  => g_hclk,
p_in_vbufin_wrclk  => g_vbuf_iclk,

p_in_tst           => (others=>'0'),
p_out_tst          => open,

p_in_rst           => i_vctrl_rst
);

--Video Output
m_vout : vout
generic map(
G_VBUF_IWIDTH => CI_MEM_DWIDTH,
G_VBUF_OWIDTH => G_VOUT_DWIDTH,
G_VSYN_ACTIVE => G_VSYN_ACTIVE
)
port map(
p_out_vd           => p_out_vd,
p_in_vs            => p_in_vout_vs,
p_in_hs            => p_in_vout_hs,
p_in_vclk          => p_in_vout_clk,

p_in_vbufout_d     => i_vbufout_din,
p_in_vbufout_wr    => i_vbufout_wr,
p_out_vbufout_full => i_vbufout_full,
p_in_vbufout_wrclk => g_hclk,

p_in_hbufout_d     => i_hbufout_din,
p_in_hbufout_wr    => i_hbufout_wr,
p_in_hsel          => i_hbufout_sel,

p_in_rst           => i_vctrl_rst
);

m_vctrl : video_ctrl
generic map(
G_SIM => G_SIM,
G_MEM_BANK_M_BIT => CI_MEM_BANK_M_BIT,
G_MEM_BANK_L_BIT => CI_MEM_BANK_L_BIT,
G_MEM_AWIDTH => CI_MEM_AWIDTH,
G_MEM_DWIDTH => CI_MEM_DWIDTH
)
port map(
-------------------------------
--
-------------------------------
p_in_vfr_prm         => i_vfr_prm,

----------------------------
--Связь с вх/вых видеобуферами
----------------------------
--in
p_in_vbufin_d         => i_vbufin_dout,
p_out_vbufin_rd       => i_vbufin_rd,
p_in_vbufin_empty     => i_vbufin_empty,
--out
p_out_vbufout_d       => i_vbufout_din,
p_out_vbufout_wr      => i_vbufout_wr,
p_in_vbufout_full     => i_vbufout_full,

---------------------------------
--Связь с mem_ctrl.vhd
---------------------------------
--CH WRITE
p_out_memwr           => i_memch0_in_bank (0),--: out   TMemIN;
p_in_memwr            => i_memch0_out_bank(0),--: in    TMemOUT;
--CH READ
p_out_memrd           => i_memch1_in_bank (0),--: out   TMemIN;
p_in_memrd            => i_memch1_out_bank(0),--: in    TMemOUT;

-------------------------------
--Технологический
-------------------------------
p_out_tst             => tst_vctrl_out,

-------------------------------
--System
-------------------------------
p_in_clk              => g_hclk,
p_in_rst              => i_vctrl_rst
);


--***********************************************************
--Контроллер ОЗУ
--***********************************************************
m_mem_ctrl : mem_ctrl
generic map(
G_SIM => G_SIM
)
port map(
------------------------------------
--User Post
------------------------------------
p_in_memch0     => i_memch0_in_bank, --TMemINBank;
p_out_memch0    => i_memch0_out_bank,--TMemOUTBank;

p_in_memch1     => i_memch1_in_bank, --TMemINBank;
p_out_memch1    => i_memch1_out_bank,--TMemOUTBank;

------------------------------------
--Memory physical interface
------------------------------------
p_out_phymem    => i_phymem_out,
p_inout_phymem  => i_phymem_inout,

------------------------------------
--Memory status
------------------------------------
p_out_mem_rdy   => i_mem_ctrl_rdy,

------------------------------------
--System
------------------------------------
p_out_pll_gclkusr => open,
--c5_rst0         : out   std_logic;
p_in_clk        => g_memclkin,
p_in_rst        => i_mem_ctrl_rst
);

p_out_mcb5_a        <= i_phymem_out  (0).a;
p_out_mcb5_ba       <= i_phymem_out  (0).ba;
p_out_mcb5_ras_n    <= i_phymem_out  (0).ras_n;
p_out_mcb5_cas_n    <= i_phymem_out  (0).cas_n;
p_out_mcb5_we_n     <= i_phymem_out  (0).we_n;
p_out_mcb5_odt      <= i_phymem_out  (0).odt;
p_out_mcb5_cke      <= i_phymem_out  (0).cke;
p_out_mcb5_dm       <= i_phymem_out  (0).dm;
p_out_mcb5_udm      <= i_phymem_out  (0).udm;
p_out_mcb5_ck       <= i_phymem_out  (0).ck;
p_out_mcb5_ck_n     <= i_phymem_out  (0).ck_n;
p_inout_mcb5_dq     <= i_phymem_inout(0).dq;
p_inout_mcb5_udqs   <= i_phymem_inout(0).udqs;
p_inout_mcb5_udqs_n <= i_phymem_inout(0).udqs_n;
p_inout_mcb5_dqs    <= i_phymem_inout(0).dqs;
p_inout_mcb5_dqs_n  <= i_phymem_inout(0).dqs_n;
p_inout_mcb5_rzq    <= i_phymem_inout(0).rzq;
p_inout_mcb5_zio    <= i_phymem_inout(0).zio;

p_out_mcb1_a        <= i_phymem_out  (1).a;
p_out_mcb1_ba       <= i_phymem_out  (1).ba;
p_out_mcb1_ras_n    <= i_phymem_out  (1).ras_n;
p_out_mcb1_cas_n    <= i_phymem_out  (1).cas_n;
p_out_mcb1_we_n     <= i_phymem_out  (1).we_n;
p_out_mcb1_odt      <= i_phymem_out  (1).odt;
p_out_mcb1_cke      <= i_phymem_out  (1).cke;
p_out_mcb1_dm       <= i_phymem_out  (1).dm;
p_out_mcb1_udm      <= i_phymem_out  (1).udm;
p_out_mcb1_ck       <= i_phymem_out  (1).ck;
p_out_mcb1_ck_n     <= i_phymem_out  (1).ck_n;
p_inout_mcb1_dq     <= i_phymem_inout(1).dq;
p_inout_mcb1_udqs   <= i_phymem_inout(1).udqs;
p_inout_mcb1_udqs_n <= i_phymem_inout(1).udqs_n;
p_inout_mcb1_dqs    <= i_phymem_inout(1).dqs;
p_inout_mcb1_dqs_n  <= i_phymem_inout(1).dqs_n;
p_inout_mcb1_rzq    <= i_phymem_inout(1).rzq;
p_inout_mcb1_zio    <= i_phymem_inout(1).zio;


--***********************************************************
--Проект Накопителя - dsn_hdd.vhd
--***********************************************************
gen_sata_gt : for i in 0 to C_SH_COUNT_MAX(C_PCFG_HDD_COUNT-1)-1 generate
  ibufds_hdd_gt_refclk : IBUFDS port map(I  => p_in_sata_clk_p(i), IB => p_in_sata_clk_n(i), O => i_hdd_gt_refclk150(i));
end generate gen_sata_gt;

m_hdd : dsn_hdd
generic map(
G_MEM_DWIDTH => CI_MEM_DWIDTH,
G_RAID_DWIDTH=> C_PCFG_HDD_RAID_DWIDTH,
G_MODULE_USE=> C_PCFG_HDD_USE,
G_HDD_COUNT => C_PCFG_HDD_COUNT,
G_GT_DBUS   => C_PCFG_HDD_GT_DBUS,
G_DBG       => C_PCFG_HDD_DBG,
G_DBGCS     => C_PCFG_HDD_DBGCS,
G_SIM       => G_SIM
)
port map(
-------------------------------
--Конфигурирование модуля dsn_hdd.vhd (p_in_cfg_clk domain)
-------------------------------
p_in_cfg_if           => C_HDD_CFGIF_UART,
p_in_cfg_clk          => g_cfg_clk,

p_in_cfg_adr          => i_cfg_adr(7 downto 0),
p_in_cfg_adr_ld       => i_cfg_adr_ld,
p_in_cfg_adr_fifo     => i_cfg_adr_fifo,

p_in_cfg_txdata       => i_cfg_txd,
p_in_cfg_wd           => i_cfg_wd,
p_out_cfg_txrdy       => i_cfg_txrdy,

p_out_cfg_rxdata      => i_cfg_rxd,
p_in_cfg_rd           => i_cfg_rd,
p_out_cfg_rxrdy       => i_cfg_rxrdy,

p_in_cfg_done         => i_cfg_done,
p_in_cfg_rst          => i_sys_rst,

-------------------------------
--STATUS модуля dsn_hdd.vhd
-------------------------------
p_out_hdd_rdy         => i_hdd_module_rdy,
p_out_hdd_error       => i_hdd_module_error,
p_out_hdd_busy        => i_hdd_busy,
p_out_hdd_irq         => open, --i_hdd_hirq,
p_out_hdd_done        => i_hdd_done,

-------------------------------
--Связь с Источниками/Приемниками данных накопителя
-------------------------------
p_out_rbuf_cfg        => i_hdd_rbuf_cfg,
p_in_rbuf_status      => i_hdd_rbuf_status,

--p_in_hdd_txd_wrclk    => g_hclk,
p_in_hdd_txd          => i_hdd_txdata,
p_in_hdd_txd_wr       => i_hdd_txdata_wd,
p_out_hdd_txbuf_pfull => i_hdd_txbuf_pfull,
p_out_hdd_txbuf_full  => i_hdd_txbuf_full,
p_out_hdd_txbuf_empty => i_hdd_txbuf_empty,

--p_in_hdd_rxd_rdclk    => g_hclk,
p_out_hdd_rxd         => i_hdd_rxdata,
p_in_hdd_rxd_rd       => i_hdd_rxdata_rd,
p_out_hdd_rxbuf_empty => i_hdd_rxbuf_empty,
p_out_hdd_rxbuf_pempty=> i_hdd_rxbuf_pempty,

-------------------------------
--Sata Driver
-------------------------------
p_out_sata_txn        => p_out_sata_txn,
p_out_sata_txp        => p_out_sata_txp,
p_in_sata_rxn         => p_in_sata_rxn,
p_in_sata_rxp         => p_in_sata_rxp,

p_in_sata_refclk      => i_hdd_gt_refclk150,
p_out_sata_refclkout  => g_sata_refclkout,
p_out_sata_gt_plldet  => i_hdd_gt_plldet,
p_out_sata_dcm_lock   => i_hdd_dcm_lock,
p_out_sata_dcm_gclk2div=> g_hdd_dcm_gclk75M,
p_out_sata_dcm_gclk2x  => g_hdd_dcm_gclk300M,
p_out_sata_dcm_gclk0   => g_hdd_dcm_gclk150M,

-------------------------------
--Технологический порт
-------------------------------
p_in_tst              => (others=>'0'),--i_hdd_tst_in,
p_out_tst             => i_hdd_tst_out,

-------------------------------
--Debug/Sim
-------------------------------
p_out_dbgcs                 => i_hdd_dbgcs,
p_out_dbgled                => i_hdd_dbgled,

p_out_sim_gt_txdata         => open,--i_hdd_sim_gt_txdata,
p_out_sim_gt_txcharisk      => open,--i_hdd_sim_gt_txcharisk,
p_out_sim_gt_txcomstart     => open,--i_hdd_sim_gt_txcomstart,
p_in_sim_gt_rxdata          => i_hdd_sim_gt_rxdata,
p_in_sim_gt_rxcharisk       => i_hdd_sim_gt_rxcharisk,
p_in_sim_gt_rxstatus        => i_hdd_sim_gt_rxstatus,
p_in_sim_gt_rxelecidle      => i_hdd_sim_gt_rxelecidle,
p_in_sim_gt_rxdisperr       => i_hdd_sim_gt_rxdisperr,
p_in_sim_gt_rxnotintable    => i_hdd_sim_gt_rxnotintable,
p_in_sim_gt_rxbyteisaligned => i_hdd_sim_gt_rxbyteisaligned,
p_out_gt_sim_rst            => open,--i_hdd_sim_gt_sim_rst,
p_out_gt_sim_clk            => open,--i_hdd_sim_gt_sim_clk,

-------------------------------
--System
-------------------------------
p_in_clk           => g_hdd_clk,
p_in_rst           => i_hdd_rst
);

gen_satah: for i in 0 to C_HDD_COUNT_MAX-1 generate
i_hdd_sim_gt_rxdata(i)<=(others=>'0');
i_hdd_sim_gt_rxcharisk(i)<=(others=>'0');
i_hdd_sim_gt_rxstatus(i)<=(others=>'0');
i_hdd_sim_gt_rxelecidle(i)<='0';
i_hdd_sim_gt_rxdisperr(i)<=(others=>'0');
i_hdd_sim_gt_rxnotintable(i)<=(others=>'0');
i_hdd_sim_gt_rxbyteisaligned(i)<='0';
end generate gen_satah;

m_vin_hdd : vin_hdd
generic map (
G_VBUF_OWIDTH => CI_MEM_DWIDTH,
G_VSYN_ACTIVE => G_VSYN_ACTIVE
)
port map(
--Вх. видеопоток
p_in_vd            => p_in_vd,
p_in_vs            => p_in_vin_vs,
p_in_hs            => p_in_vin_hs,
p_in_vclk          => p_in_vin_clk,

--Вых. видеобуфера
p_in_vbufin_wrclk  => g_vbuf_iclk,
p_in_vbufin_rdclk  => g_hclk,

p_out_vbufin_d     => i_hdd_vbufin_dout,
p_in_vbufin_rd     => i_hdd_vbufin_rd,
p_out_vbufin_empty => i_hdd_vbufin_empty,
p_out_vbufin_full  => i_hdd_vbufin_full,
p_out_vbufin_pfull => i_hdd_vbufin_pfull,
p_out_vbufin_wrcnt => i_hdd_vbufin_wrcnt,

p_in_hdd_tstgen    => i_hdd_rbuf_cfg.tstgen,

--Технологический
p_in_tst           => (others=>'0'),
p_out_tst          => tst_vin_hdd_out,

--System
p_in_rst           => i_hdd_rambuf_rst
);

m_hdd_rambuf : dsn_hdd_rambuf
generic map(
G_MODULE_USE => C_PCFG_HDD_USE,
G_RAMBUF_SIZE=> C_PCFG_HDD_RAMBUF_SIZE,
G_DBGCS      => C_PCFG_HDD_DBGCS,
G_SIM        => G_SIM,
G_USE_2CH    => "ON",
G_MEM_BANK_M_BIT => CI_MEM_BANK_M_BIT,
G_MEM_BANK_L_BIT => CI_MEM_BANK_L_BIT,
G_MEM_AWIDTH => CI_MEM_AWIDTH,
G_MEM_DWIDTH => CI_MEM_DWIDTH
)
port map(
-------------------------------
-- Конфигурирование
-------------------------------
p_in_rbuf_cfg         => i_hdd_rbuf_cfg,
p_out_rbuf_status     => i_hdd_rbuf_status,
p_in_lentrn_exp       => '0',

----------------------------
--Связь с буфером видеоданных
----------------------------
p_in_vbuf_dout        => i_hdd_vbufin_dout,
p_out_vbuf_rd         => i_hdd_vbufin_rd,
p_in_vbuf_empty       => i_hdd_vbufin_empty,
p_in_vbuf_full        => i_hdd_vbufin_full,
p_in_vbuf_pfull       => i_hdd_vbufin_pfull,
p_in_vbuf_wrcnt       => i_hdd_vbufin_wrcnt,

p_out_vbufo_sel       => i_hbufout_sel,
p_out_vbufo_din       => i_hbufout_din,
p_out_vbufo_wr        => i_hbufout_wr,
p_in_vbufo_full       => i_vbufout_full,

----------------------------
--Связь с модулем HDD
----------------------------
p_out_hdd_txd         => i_hdd_txdata,
p_out_hdd_txd_wr      => i_hdd_txdata_wd,
p_in_hdd_txbuf_pfull  => i_hdd_txbuf_pfull,
p_in_hdd_txbuf_full   => i_hdd_txbuf_full,
p_in_hdd_txbuf_empty  => i_hdd_txbuf_empty,

p_in_hdd_rxd          => i_hdd_rxdata,
p_out_hdd_rxd_rd      => i_hdd_rxdata_rd,
p_in_hdd_rxbuf_empty  => i_hdd_rxbuf_empty,
p_in_hdd_rxbuf_pempty => i_hdd_rxbuf_pempty,

---------------------------------
-- Связь с mem_ctrl.vhd
---------------------------------
p_out_memch0          => i_memch0_in_bank (1),--: out   TMemIN;
p_in_memch0           => i_memch0_out_bank(1),--: in    TMemOUT;

p_out_memch1          => i_memch1_in_bank (1),--: out   TMemIN;
p_in_memch1           => i_memch1_out_bank(1),--: in    TMemOUT;

-------------------------------
--Технологический
-------------------------------
p_in_tst              => i_hdd_tst_out,
p_out_tst             => tst_hdd_rambuf_out,
p_out_dbgcs           => open,

-------------------------------
--System
-------------------------------
p_in_clk              => g_hclk,
p_in_rst              => i_hdd_rambuf_rst
);



--***********************************************************
--Технологические сигналы
--***********************************************************
m_blink : fpga_test_01
generic map(
G_BLINK_T05   =>10#250#, -- 1/2 периода мигания светодиода.(время в ms)
G_CLK_T05us   =>10#75#   -- 05us - 150MHz
)
port map(
p_out_test_led => i_test01_led,
p_out_test_done=> open,

p_out_1us      => open,
p_out_1ms      => open,
-------------------------------
--System
-------------------------------
p_in_clk       => g_sata_refclkout,
p_in_rst       => i_sys_rst
);


m_cfg : cfgdev_ftdi
port map(
-------------------------------
--Связь с FTDI
-------------------------------
p_inout_ftdi_d       => p_inout_ftdi_d,
p_out_ftdi_rd_n      => p_out_ftdi_rd_n,
p_out_ftdi_wr_n      => p_out_ftdi_wr_n,
p_in_ftdi_txe_n      => p_in_ftdi_txe_n,
p_in_ftdi_rxf_n      => p_in_ftdi_rxf_n,
p_in_ftdi_pwren_n    => p_in_ftdi_pwren_n,

-------------------------------
--
-------------------------------
p_out_module_rdy     => open,
p_out_module_error   => open,

-------------------------------
--Запись/Чтение конфигурационных параметров уст-ва
-------------------------------
p_out_cfg_dadr       => i_dev_adr,
p_out_cfg_radr       => i_cfg_adr,
p_out_cfg_radr_ld    => i_cfg_adr_ld,
p_out_cfg_radr_fifo  => i_cfg_adr_fifo,
p_out_cfg_wr         => i_cfg_wd,
p_out_cfg_rd         => i_cfg_rd,
p_out_cfg_txdata     => i_cfg_txd,
p_in_cfg_rxdata      => i_cfg_rxd,
p_in_cfg_txrdy       => i_cfg_txrdy,
p_in_cfg_rxrdy       => i_cfg_rxrdy,

p_out_cfg_done       => i_cfg_done,
p_in_cfg_clk         => g_cfg_clk,

-------------------------------
--Технологический
-------------------------------
p_in_tst             => (others=>'0'),
p_out_tst            => open,--i_cfg_tstout,

-------------------------------
--System
-------------------------------
p_in_rst => i_sys_rst
);

--HDD LEDs:
--SATA0 (На плате SATA1)
p_out_led(2)<=i_hdd_dbgled(0).link;
p_out_led(4)<=i_hdd_dbgled(0).rdy when i_hdd_dbgled(0).err='0' else i_test01_led;
p_out_TP(0) <=i_hdd_dbgled(0).wr;
p_out_TP(1) <=i_hdd_dbgled(0).busy;

--SATA1 (На плате SATA0)
p_out_led(3)<=i_hdd_dbgled(1).link;
p_out_led(5)<=i_hdd_dbgled(1).rdy when i_hdd_dbgled(1).err='0' else i_test01_led;
p_out_TP(2) <=i_hdd_dbgled(1).wr;
p_out_TP(3) <=i_hdd_dbgled(1).busy;

--SATA2 (На плате SATA3)
p_out_led(0)<=i_hdd_dbgled(2).link;
p_out_led(7)<=i_hdd_dbgled(2).rdy when i_hdd_dbgled(2).err='0' else i_test01_led;
p_out_TP(4) <=i_hdd_dbgled(2).wr;
p_out_TP(5) <=i_hdd_dbgled(2).busy;

--SATA3 (На плате SATA2)
p_out_led(1)<=i_hdd_dbgled(3).link;
p_out_led(6)<=i_hdd_dbgled(3).rdy when i_hdd_dbgled(3).err='0' else i_test01_led;
p_out_TP(6) <=i_hdd_dbgled(3).wr;
p_out_TP(7) <=i_hdd_dbgled(3).busy;




gen_dbgcs : if strcmp(C_PCFG_HDD_DBGCS,"ON") generate

--m_dbgcs_icon : dbgcs_iconx3
--port map(
--CONTROL0 => i_dbgcs_sh0_spd,
--CONTROL1 => i_dbgcs_hdd0_layer,
--CONTROL2 => i_dbgcs_hdd1_layer
--);
--
--
----//### HDD0_SPD: ########
--m_dbgcs_sh0_spd : dbgcs_sata_layer
--port map
--(
--CONTROL => i_dbgcs_sh0_spd,
--CLK     => i_hdd_dbgcs.sh(0).spd.clk,
--DATA    => i_hdd_dbgcs.sh(0).spd.data(122 downto 0),
--TRIG0   => i_hdd_dbgcs.sh(0).spd.trig0(41 downto 0)
--);
--
----//### HDD0: ########
--m_dbgcs_hdd0_layer : dbgcs_sata_raid --dbgcs_sata_layer
--port map
--(
--CONTROL => i_dbgcs_hdd0_layer,
--CLK     => i_hdd_dbgcs.sh(0).layer.clk,
--DATA    => i_hdd_dbgcs.sh(0).layer.data(172 downto 0),--(122 downto 0),
--TRIG0   => i_hdd0layer_dbgcs.trig0(41 downto 0)
--);
--
--i_hdd0layer_dbgcs.trig0(19 downto 0)<=i_hdd_dbgcs.sh(0).layer.trig0(19 downto 0);--llayer
--i_hdd0layer_dbgcs.trig0(20)<=i_hdd_dbgcs.sh(0).layer.data(160);--<=p_in_alstatus.sstatus(C_ASSTAT_DET_BIT_L+1);--//C_PSTAT_DET_ESTABLISH_ON_BIT
--i_hdd0layer_dbgcs.trig0(21)<=i_hdd_dbgcs.sh(0).layer.data(161);--<=p_in_alstatus.sstatus(C_ASSTAT_DET_BIT_L+0);--//C_PSTAT_DET_DEV_ON_BIT
--i_hdd0layer_dbgcs.trig0(22)<=i_hdd_dbgcs.sh(0).layer.data(162);--<=p_in_txelecidle;
--i_hdd0layer_dbgcs.trig0(23)<=i_hdd_dbgcs.sh(0).layer.data(163);--<=p_in_rxelecidle;
--i_hdd0layer_dbgcs.trig0(24)<=i_hdd_dbgcs.sh(0).layer.data(164);--<=p_in_txcomstart;
--i_hdd0layer_dbgcs.trig0(25)<=i_hdd_dbgcs.sh(0).layer.data(167);--<=p_in_rxcdrreset;
--i_hdd0layer_dbgcs.trig0(41 downto 26)<=i_hdd_dbgcs.sh(0).layer.trig0(41 downto 26);--llayer
--
----//### HDD1: ########
--gen_hdd1 : if C_PCFG_HDD_COUNT=1 generate
--m_dbgcs_hdd1_layer : dbgcs_sata_raid --dbgcs_sata_layer
--port map
--(
--CONTROL => i_dbgcs_hdd1_layer,
--CLK     => i_hdd_dbgcs.sh(0).layer.clk,
--DATA    => i_hdd_dbgcs.sh(0).layer.data(172 downto 0),--(122 downto 0),
--TRIG0   => i_hdd1layer_dbgcs.trig0(41 downto 0)
--);
--
--i_hdd1layer_dbgcs.trig0(19 downto 0)<=i_hdd_dbgcs.sh(0).layer.trig0(19 downto 0);--llayer
--i_hdd1layer_dbgcs.trig0(20)<=i_hdd_dbgcs.sh(0).layer.data(160);--<=p_in_alstatus.sstatus(C_ASSTAT_DET_BIT_L+1);--//C_PSTAT_DET_ESTABLISH_ON_BIT
--i_hdd1layer_dbgcs.trig0(21)<=i_hdd_dbgcs.sh(0).layer.data(161);--<=p_in_alstatus.sstatus(C_ASSTAT_DET_BIT_L+0);--//C_PSTAT_DET_DEV_ON_BIT
--i_hdd1layer_dbgcs.trig0(22)<=i_hdd_dbgcs.sh(0).layer.data(162);--<=p_in_txelecidle;
--i_hdd1layer_dbgcs.trig0(23)<=i_hdd_dbgcs.sh(0).layer.data(163);--<=p_in_rxelecidle;
--i_hdd1layer_dbgcs.trig0(24)<=i_hdd_dbgcs.sh(0).layer.data(164);--<=p_in_txcomstart;
--i_hdd1layer_dbgcs.trig0(25)<=i_hdd_dbgcs.sh(0).layer.data(167);--<=p_in_rxcdrreset;
--i_hdd1layer_dbgcs.trig0(41 downto 26)<=i_hdd_dbgcs.sh(0).layer.trig0(41 downto 26);--llayer
--end generate gen_hdd1;
--
--gen_hdd2 : if C_PCFG_HDD_COUNT=2 generate
--m_dbgcs_hdd1_layer : dbgcs_sata_raid --dbgcs_sata_layer
--port map
--(
--CONTROL => i_dbgcs_hdd1_layer,
--CLK     => i_hdd_dbgcs.sh(1).layer.clk,
--DATA    => i_hdd_dbgcs.sh(1).layer.data(172 downto 0),--(122 downto 0),
--TRIG0   => i_hdd1layer_dbgcs.trig0(41 downto 0)
--);
--
--i_hdd1layer_dbgcs.trig0(19 downto 0)<=i_hdd_dbgcs.sh(1).layer.trig0(19 downto 0);--llayer
--i_hdd1layer_dbgcs.trig0(20)<=i_hdd_dbgcs.sh(1).layer.data(160);--<=p_in_alstatus.sstatus(C_ASSTAT_DET_BIT_L+1);--//C_PSTAT_DET_ESTABLISH_ON_BIT
--i_hdd1layer_dbgcs.trig0(21)<=i_hdd_dbgcs.sh(1).layer.data(161);--<=p_in_alstatus.sstatus(C_ASSTAT_DET_BIT_L+0);--//C_PSTAT_DET_DEV_ON_BIT
--i_hdd1layer_dbgcs.trig0(22)<=i_hdd_dbgcs.sh(1).layer.data(162);--<=p_in_txelecidle;
--i_hdd1layer_dbgcs.trig0(23)<=i_hdd_dbgcs.sh(1).layer.data(163);--<=p_in_rxelecidle;
--i_hdd1layer_dbgcs.trig0(24)<=i_hdd_dbgcs.sh(1).layer.data(164);--<=p_in_txcomstart;
--i_hdd1layer_dbgcs.trig0(25)<=i_hdd_dbgcs.sh(1).layer.data(167);--<=p_in_rxcdrreset;
--i_hdd1layer_dbgcs.trig0(41 downto 26)<=i_hdd_dbgcs.sh(1).layer.trig0(41 downto 26);--llayer
--end generate gen_hdd2;
--
--gen_hdd3 : if C_PCFG_HDD_COUNT>2 generate
--m_dbgcs_hdd1_layer : dbgcs_sata_raid --dbgcs_sata_layer
--port map
--(
--CONTROL => i_dbgcs_hdd1_layer,
--CLK     => i_hdd_dbgcs.sh(2).layer.clk,
--DATA    => i_hdd_dbgcs.sh(2).layer.data(172 downto 0),--(122 downto 0),
--TRIG0   => i_hdd1layer_dbgcs.trig0(41 downto 0)
--);
--
--i_hdd1layer_dbgcs.trig0(19 downto 0)<=i_hdd_dbgcs.sh(2).layer.trig0(19 downto 0);--llayer
--i_hdd1layer_dbgcs.trig0(20)<=i_hdd_dbgcs.sh(2).layer.data(160);--<=p_in_alstatus.sstatus(C_ASSTAT_DET_BIT_L+1);--//C_PSTAT_DET_ESTABLISH_ON_BIT
--i_hdd1layer_dbgcs.trig0(21)<=i_hdd_dbgcs.sh(2).layer.data(161);--<=p_in_alstatus.sstatus(C_ASSTAT_DET_BIT_L+0);--//C_PSTAT_DET_DEV_ON_BIT
--i_hdd1layer_dbgcs.trig0(22)<=i_hdd_dbgcs.sh(2).layer.data(162);--<=p_in_txelecidle;
--i_hdd1layer_dbgcs.trig0(23)<=i_hdd_dbgcs.sh(2).layer.data(163);--<=p_in_rxelecidle;
--i_hdd1layer_dbgcs.trig0(24)<=i_hdd_dbgcs.sh(2).layer.data(164);--<=p_in_txcomstart;
--i_hdd1layer_dbgcs.trig0(25)<=i_hdd_dbgcs.sh(2).layer.data(167);--<=p_in_rxcdrreset;
--i_hdd1layer_dbgcs.trig0(41 downto 26)<=i_hdd_dbgcs.sh(2).layer.trig0(41 downto 26);--llayer
----
----m_dbgcs_hdd1_layer : dbgcs_sata_raid --dbgcs_sata_layer
----port map
----(
----CONTROL => i_dbgcs_hdd1_layer,
----CLK     => i_hdd_dbgcs.sh(3).layer.clk,
----DATA    => i_hdd_dbgcs.sh(3).layer.data(172 downto 0),--(122 downto 0),
----TRIG0   => i_hdd1layer_dbgcs.trig0(41 downto 0)
----);
----
----i_hdd1layer_dbgcs.trig0(19 downto 0)<=i_hdd_dbgcs.sh(3).layer.trig0(19 downto 0);--llayer
----i_hdd1layer_dbgcs.trig0(20)<=i_hdd_dbgcs.sh(3).layer.data(160);--<=p_in_alstatus.sstatus(C_ASSTAT_DET_BIT_L+1);--//C_PSTAT_DET_ESTABLISH_ON_BIT
----i_hdd1layer_dbgcs.trig0(21)<=i_hdd_dbgcs.sh(3).layer.data(161);--<=p_in_alstatus.sstatus(C_ASSTAT_DET_BIT_L+0);--//C_PSTAT_DET_DEV_ON_BIT
----i_hdd1layer_dbgcs.trig0(22)<=i_hdd_dbgcs.sh(3).layer.data(162);--<=p_in_txelecidle;
----i_hdd1layer_dbgcs.trig0(23)<=i_hdd_dbgcs.sh(3).layer.data(163);--<=p_in_rxelecidle;
----i_hdd1layer_dbgcs.trig0(24)<=i_hdd_dbgcs.sh(3).layer.data(164);--<=p_in_txcomstart;
----i_hdd1layer_dbgcs.trig0(25)<=i_hdd_dbgcs.sh(3).layer.data(167);--<=p_in_rxcdrreset;
----i_hdd1layer_dbgcs.trig0(41 downto 26)<=i_hdd_dbgcs.sh(3).layer.trig0(41 downto 26);--llayer
--end generate gen_hdd3;


--//### HDD_RAID: ########
m_dbgcs_icon : dbgcs_iconx1
port map(
CONTROL0 => i_dbgcs_hdd_raid
);

m_dbgcs_sh0_raid : dbgcs_sata_raid
port map(
CONTROL => i_dbgcs_hdd_raid,
CLK     => i_hdd_dbgcs.raid.clk,
DATA    => i_hddraid_dbgcs.data(172 downto 0),--(122 downto 0),
TRIG0   => i_hddraid_dbgcs.trig0(41 downto 0)
);

--//-------- TRIG: ------------------
--i_hddraid_dbgcs.trig0(12)<=i_memch0_out_bank(1).txbuf_err or i_memch0_out_bank (1).txbuf_underrun or i_memch0_out_bank (1).cmdbuf_err;
--i_hddraid_dbgcs.trig0(13)<=i_memch1_out_bank(1).rxbuf_err or i_memch1_out_bank (1).rxbuf_overflow or i_memch1_out_bank (1).cmdbuf_err;
--i_hddraid_dbgcs.trig0(14)<='0';

i_hddraid_dbgcs.trig0(18 downto 0)<=i_hdd_dbgcs.raid.trig0(18 downto 0);
i_hddraid_dbgcs.trig0(19)<=i_tmrout_det;--i_hdd_rbuf_status.err;--i_hdd_tst_out(5);--<=i_sh_cxd_rd;

--//SH0
i_hddraid_dbgcs.trig0(24 downto 20)<=i_hdd_dbgcs.sh(0).layer.trig0(34 downto 30);--llayer
i_hddraid_dbgcs.trig0(29 downto 25)<=i_hdd_dbgcs.sh(0).layer.trig0(39 downto 35);--tlayer
--//SH1
i_hddraid_dbgcs.trig0(34 downto 30)<=i_hdd_dbgcs.sh(1).layer.trig0(34 downto 30);--llayer
i_hddraid_dbgcs.trig0(39 downto 35)<=i_hdd_dbgcs.sh(1).layer.trig0(39 downto 35);--tlayer

i_hddraid_dbgcs.trig0(40)<=i_hdd_txbuf_empty;--i_memch1_out_bank(1).rxbuf_err or i_memch1_out_bank (1).rxbuf_overflow or i_memch1_out_bank (1).cmdbuf_err;--
i_hddraid_dbgcs.trig0(41)<=i_hdd_txbuf_full;--i_hdd_txbuf_pfull;


--//-------- VIEW: ------------------
i_hddraid_dbgcs.data(28 downto 0)<=i_hdd_dbgcs.raid.data(28 downto 0);
i_hddraid_dbgcs.data(29)<=i_hdd_txbuf_pfull;

--//SH0
i_hddraid_dbgcs.data(34 downto 30)<=i_hdd_dbgcs.sh(0).layer.trig0(34 downto 30);--llayer
i_hddraid_dbgcs.data(39 downto 35)<=i_hdd_dbgcs.sh(0).layer.trig0(39 downto 35);--tlayer
i_hddraid_dbgcs.data(55 downto 40)<=i_hdd_dbgcs.sh(0).layer.data(65 downto 50);
i_hddraid_dbgcs.data(56)          <='0';--i_hdd_dbgcs.sh(0).layer.data(49);--p_in_ll_rxd_wr; --llayer->tlayer
i_hddraid_dbgcs.data(57)          <='0';--i_hdd_dbgcs.sh(0).layer.data(116);--p_in_ll_txd_rd; --llayer<-tlayer
i_hddraid_dbgcs.data(58)          <='0';--i_hdd_dbgcs.sh(0).layer.data(118);--<=p_in_dbg.llayer.txbuf_status.aempty;
i_hddraid_dbgcs.data(59)          <=i_hdd_dbgcs.sh(0).layer.data(119);--<=p_in_dbg.llayer.txbuf_status.empty;
i_hddraid_dbgcs.data(60)          <='0';--i_hdd_dbgcs.sh(0).layer.data(98);--<=p_in_dbg.llayer.rxbuf_status.pfull;
i_hddraid_dbgcs.data(61)          <='0';--i_hdd_dbgcs.sh(0).layer.data(99);--<=p_in_dbg.llayer.txbuf_status.pfull;
i_hddraid_dbgcs.data(62)          <='0';--i_hdd_dbgcs.sh(0).layer.data(117);--<=p_in_dbg.llayer.txd_close;

--//SH1
i_hddraid_dbgcs.data(67 downto 63)<=i_hdd_dbgcs.sh(1).layer.trig0(34 downto 30);--llayer
i_hddraid_dbgcs.data(72 downto 68)<=i_hdd_dbgcs.sh(1).layer.trig0(39 downto 35);--tlayer
i_hddraid_dbgcs.data(88 downto 73)<=i_hdd_dbgcs.sh(1).layer.data(65 downto 50);
i_hddraid_dbgcs.data(89)          <='0';--i_hdd_dbgcs.sh(1).layer.data(49);--p_in_ll_rxd_wr; --llayer->tlayer
i_hddraid_dbgcs.data(90)          <='0';--i_hdd_dbgcs.sh(1).layer.data(116);--p_in_ll_txd_rd; --llayer<-tlayer
i_hddraid_dbgcs.data(91)          <='0';--i_hdd_dbgcs.sh(1).layer.data(118);--<=p_in_dbg.llayer.txbuf_status.aempty;
i_hddraid_dbgcs.data(92)          <=i_hdd_dbgcs.sh(1).layer.data(119);--<=p_in_dbg.llayer.txbuf_status.empty;
i_hddraid_dbgcs.data(93)          <='0';--i_hdd_dbgcs.sh(1).layer.data(98);--<=p_in_dbg.llayer.rxbuf_status.pfull;
i_hddraid_dbgcs.data(94)          <=i_hdd_dbgcs.sh(1).layer.data(99);--<=p_in_dbg.llayer.txbuf_status.pfull;
i_hddraid_dbgcs.data(95)          <='0';--i_hdd_dbgcs.sh(1).layer.data(117);--<=p_in_dbg.llayer.txd_close;

--//RAMBUF
i_hddraid_dbgcs.data(103 downto 100)<=tst_hdd_rambuf_out(29 downto 26);--<=tst_fsm_cs;
i_hddraid_dbgcs.data(104)<=i_hdd_txbuf_empty;
i_hddraid_dbgcs.data(105)<=i_hdd_rxbuf_empty;
i_hddraid_dbgcs.data(106)<=i_hdd_rbuf_status.err_type.rambuf_full;--i_hdd_txdata_wd;--RAM->HDD
i_hddraid_dbgcs.data(107)<=i_hdd_rbuf_status.err_type.vinbuf_full;--i_hdd_rxdata_rd;--RAM<-HDD
i_hddraid_dbgcs.data(108)<=tst_hdd_rambuf_out(11);--<=tst_rambuf_empty;
--i_hddraid_dbgcs.data(140 downto 109)<=i_hdd_dbgcs.raid.data(161 downto 130);--i_usr_rxd;--RAM<-HDD
--i_hddraid_dbgcs.data(172 downto 141)<=i_hdd_rxdata(31 downto 0);--RAM<-HDD

--//SH2
i_hddraid_dbgcs.data(113 downto 109)<=(others=>'0');--i_hdd_dbgcs.sh(2).layer.trig0(34 downto 30);--llayer
i_hddraid_dbgcs.data(118 downto 114)<=(others=>'0');--i_hdd_dbgcs.sh(2).layer.trig0(39 downto 35);--tlayer
i_hddraid_dbgcs.data(124 downto 119)<=(others=>'0');--i_hdd_dbgcs.sh(2).layer.data(55 downto 50);--(65 downto 50);
i_hddraid_dbgcs.data(125)           <='0';          --i_hdd_dbgcs.sh(2).layer.data(49);--p_in_ll_rxd_wr; --llayer->tlayer
i_hddraid_dbgcs.data(126)           <='0';          --i_hdd_dbgcs.sh(2).layer.data(116);--p_in_ll_txd_rd; --llayer<-tlayer
i_hddraid_dbgcs.data(127)           <='0';          --i_hdd_dbgcs.sh(2).layer.data(118);--<=p_in_dbg.llayer.txbuf_status.aempty;
i_hddraid_dbgcs.data(128)           <='0';          --i_hdd_dbgcs.sh(2).layer.data(119);--<=p_in_dbg.llayer.txbuf_status.empty;
i_hddraid_dbgcs.data(129)           <='0';          --i_hdd_dbgcs.sh(2).layer.data(98);--<=p_in_dbg.llayer.rxbuf_status.pfull;
i_hddraid_dbgcs.data(130)           <='0';          --i_hdd_dbgcs.sh(2).layer.data(99);--<=p_in_dbg.llayer.txbuf_status.pfull;
i_hddraid_dbgcs.data(131)           <='0';          --i_hdd_dbgcs.sh(2).layer.data(117);--<=p_in_dbg.llayer.txd_close;

--//SH3
--i_hddraid_dbgcs.data(138 downto 132)<=i_memch1_out_bank(1).rxbuf_rdcount;--(6 downto 0);
--i_hddraid_dbgcs.data(142 downto 139)<=(others=>'0');
i_hddraid_dbgcs.data(136 downto 132)<=(others=>'0');--i_hdd_dbgcs.sh(3).layer.trig0(34 downto 30);--llayer
i_hddraid_dbgcs.data(142 downto 138)<=(others=>'0');--i_hdd_dbgcs.sh(3).layer.trig0(39 downto 35);--tlayer
i_hddraid_dbgcs.data(148 downto 143)<=(others=>'0');--i_hdd_dbgcs.sh(3).layer.data(55 downto 50);--(65 downto 50);
i_hddraid_dbgcs.data(149)           <='0';          --i_hdd_dbgcs.sh(3).layer.data(49);--p_in_ll_rxd_wr; --llayer->tlayer
i_hddraid_dbgcs.data(150)           <='0';          --i_hdd_dbgcs.sh(3).layer.data(116);--p_in_ll_txd_rd; --llayer<-tlayer
i_hddraid_dbgcs.data(151)           <='0';          --i_hdd_dbgcs.sh(3).layer.data(118);--<=p_in_dbg.llayer.txbuf_status.aempty;
i_hddraid_dbgcs.data(152)           <='0';          --i_hdd_dbgcs.sh(3).layer.data(119);--<=p_in_dbg.llayer.txbuf_status.empty;
i_hddraid_dbgcs.data(153)           <='0';          --i_hdd_dbgcs.sh(3).layer.data(98);--<=p_in_dbg.llayer.rxbuf_status.pfull;
i_hddraid_dbgcs.data(154)           <='0';          --i_hdd_dbgcs.sh(3).layer.data(99);--<=p_in_dbg.llayer.txbuf_status.pfull;
i_hddraid_dbgcs.data(155)           <='0';          --i_hdd_dbgcs.sh(3).layer.data(117);--<=p_in_dbg.llayer.txd_close;

i_hddraid_dbgcs.data(156)<=i_memch0_in_bank (1).cmd_wr;--cmd for wr
i_hddraid_dbgcs.data(157)<=i_memch0_in_bank (1).txd_wr;
i_hddraid_dbgcs.data(158)<=i_memch1_in_bank (1).cmd_wr;--cmd for rd
i_hddraid_dbgcs.data(159)<=i_memch1_in_bank (1).rxd_rd;
i_hddraid_dbgcs.data(160)<='0';--i_memch0_out_bank(1).txbuf_err or i_memch0_out_bank (1).txbuf_underrun or i_memch0_out_bank (1).cmdbuf_err;
i_hddraid_dbgcs.data(161)<='0';--i_memch1_out_bank(1).rxbuf_err or i_memch1_out_bank (1).rxbuf_overflow or i_memch1_out_bank (1).cmdbuf_err;


i_hddraid_dbgcs.data(162)<='0';--i_hdd_vbufin_empty;--i_memch1_out_bank(1).cmdbuf_full;
i_hddraid_dbgcs.data(163)<='0';--i_hdd_vbufin_full;--i_memch1_out_bank(1).cmdbuf_empty;
i_hddraid_dbgcs.data(164)<='0';--tst_hdd_rambuf_out(14);-- <=i_mem_dir;
i_hddraid_dbgcs.data(165)<=i_memch1_out_bank(1).rxbuf_empty;
--i_hddraid_dbgcs.data(166)<='0';--i_memch1_out_bank(1).rxbuf_err;
--i_hddraid_dbgcs.data(167)<='0';--i_memch1_out_bank(1).rxbuf_overflow;
--i_hddraid_dbgcs.data(168)<='0';--i_memch1_out_bank(1).cmdbuf_err;
i_hddraid_dbgcs.data(168 downto 166)<=tst_hdd_rambuf_out(9 downto 7);--mem_rd/fsm_cs

process(i_hdd_dbgcs.raid.clk)
begin
  if i_hdd_dbgcs.raid.clk'event and i_hdd_dbgcs.raid.clk='1' then
    if i_hdd_rbuf_cfg.dmacfg.clr_err='1' then
      i_tmrout_en<='0';
    elsif i_hdd_rbuf_cfg.dmacfg.hw_mode='1' and
       (i_memch0_in_bank (1).cmd_wr='1' or i_memch1_in_bank (1).cmd_wr='1') then
       i_tmrout_en<='1';
    end if;
  end if;
end process;

process(i_hdd_dbgcs.raid.clk)
begin
  if i_hdd_dbgcs.raid.clk'event and i_hdd_dbgcs.raid.clk='1' then
    if i_tmrout_en='0' then
     i_tmrout_cnt<=(others=>'0');
     i_tmrout<='0';
    else
      if i_memch0_in_bank (1).cmd_wr='1' or i_memch0_in_bank (1).txd_wr='1' or
         i_memch1_in_bank (1).cmd_wr='1' or i_memch1_in_bank (1).rxd_rd='1' then

         i_tmrout_cnt<=(others=>'0');
         i_tmrout<='0';
      else
        if i_tmrout_cnt=i_hdd_rbuf_cfg.usr(15 downto 0) then
          i_tmrout_cnt<=i_tmrout_cnt;
          i_tmrout<='1';
        else
          i_tmrout_cnt<=i_tmrout_cnt + 1;
        end if;
      end if;
    end if;
  end if;
end process;

process(i_hdd_dbgcs.raid.clk)
begin
  if i_hdd_dbgcs.raid.clk'event and i_hdd_dbgcs.raid.clk='1' then
    sr_tmrout<=i_tmrout;
    i_tmrout_det<=i_tmrout and not sr_tmrout;
  end if;
end process;

end generate gen_dbgcs;




--m_dbgcs_icon : dbgcs_iconx1
--port map(
--CONTROL0 => i_dbgcs_hdd_rbuf
--);
--
--m_dbgcs_rbuf : dbgcs_sata_rbuf
--port map(
--CONTROL => i_dbgcs_hdd_rbuf,
--CLK     => g_hclk,--i_hdd_dbgcs.raid.clk,
--DATA    => i_hddraid_dbgcs.data(136 downto 0),--(122 downto 0),
--TRIG0   => i_hddraid_dbgcs.trig0(41 downto 0)
--);
--
----//-------- TRIG: ------------------
--i_hddraid_dbgcs.trig0(0)            <=tst_hdd_rambuf_out(0)         ;--tst_vctrl_out(0)         ;--vwriter(0)<=p_in_cfg_mem_start;
--i_hddraid_dbgcs.trig0(1)            <=tst_hdd_rambuf_out(5)         ;--tst_vctrl_out(5)         ;--vreader(0)<=p_in_cfg_mem_start;
--i_hddraid_dbgcs.trig0(4 downto 2)   <=tst_hdd_rambuf_out(4 downto 2);--tst_vctrl_out(4 downto 2);--vwriter(4 downto 2)<=tst_fsm_cs;
--i_hddraid_dbgcs.trig0(7 downto 5)   <=tst_hdd_rambuf_out(9 downto 7);--tst_vctrl_out(9 downto 7);--vreader(4 downto 2)<=tst_fsm_cs;
--i_hddraid_dbgcs.trig0(12 downto 8)  <=tst_hdd_rambuf_out(30 downto 26);--<=tst_fsm_cs;
--i_hddraid_dbgcs.trig0(13)           <=tst_hdd_rambuf_out(10);--<=tst_hw_stop;
--i_hddraid_dbgcs.trig0(14)           <=i_hdd_rbuf_status.err;--<=i_err_det.rambuf_full or i_err_det.vinbuf_full;
--i_hddraid_dbgcs.trig0(15)           <=i_hdd_txbuf_pfull;
--i_hddraid_dbgcs.trig0(16)           <=i_hdd_txbuf_full;
--i_hddraid_dbgcs.trig0(17)           <=i_hdd_txbuf_empty;
--i_hddraid_dbgcs.trig0(18)           <=i_hdd_rxbuf_empty;
--i_hddraid_dbgcs.trig0(19)           <=i_hdd_rbuf_cfg.dmacfg.atadone;--'0';--i_hdd_rxbuf_pempty;,
--i_hddraid_dbgcs.trig0(20)           <='0';--tst_hdd_rambuf_out(11);--<=tst_rambuf_empty;
--
--i_hddraid_dbgcs.trig0(21)           <=i_memch1_in_bank (1).rxd_rd       ;
--i_hddraid_dbgcs.trig0(22)           <=i_memch0_in_bank (1).txd_wr       ;
--i_hddraid_dbgcs.trig0(23)           <=i_memch0_out_bank(1).cmdbuf_full  ;
--i_hddraid_dbgcs.trig0(24)           <=i_memch0_out_bank(1).txbuf_full   ;
--i_hddraid_dbgcs.trig0(25)           <='0';--i_memch0_out_bank(1).txbuf_err;
--i_hddraid_dbgcs.trig0(26)           <='0';--i_memch0_out_bank(1).txbuf_underrun;
--i_hddraid_dbgcs.trig0(27)           <=i_memch1_out_bank(1).cmdbuf_full  ;
--i_hddraid_dbgcs.trig0(28)           <=i_memch1_out_bank(1).rxbuf_full   ;
--i_hddraid_dbgcs.trig0(29)           <='0';--i_memch1_out_bank(1).rxbuf_err;
--i_hddraid_dbgcs.trig0(30)           <='0';--i_memch1_out_bank(1).rxbuf_overflow;
--i_hddraid_dbgcs.trig0(31)           <=tst_syn;
--
----//-------- VIEW: ------------------
--i_hddraid_dbgcs.data(0)             <=tst_hdd_rambuf_out(0)         ;--tst_vctrl_out(0)         ;--vwriter(0)<=p_in_cfg_mem_start;
--i_hddraid_dbgcs.data(1)             <=tst_hdd_rambuf_out(5)         ;--tst_vctrl_out(5)         ;--vreader(0)<=p_in_cfg_mem_start;
--i_hddraid_dbgcs.data(4 downto 2)    <=tst_hdd_rambuf_out(4 downto 2);--tst_vctrl_out(4 downto 2);--vwriter(4 downto 2)<=tst_fsm_cs;
--i_hddraid_dbgcs.data(7 downto 5)    <=tst_hdd_rambuf_out(9 downto 7);--tst_vctrl_out(9 downto 7);--vreader(4 downto 2)<=tst_fsm_cs;
--i_hddraid_dbgcs.data(12 downto 8)   <=tst_hdd_rambuf_out(30 downto 26);--<=tst_fsm_cs;
--i_hddraid_dbgcs.data(13)            <=i_hdd_rbuf_status.err_type.vinbuf_full;
--i_hddraid_dbgcs.data(14)            <=i_hdd_rbuf_status.err_type.rambuf_full;
--i_hddraid_dbgcs.data(15)            <=i_hdd_txbuf_pfull;
--i_hddraid_dbgcs.data(16)            <=i_hdd_txbuf_full;
--i_hddraid_dbgcs.data(17)            <=i_hdd_txbuf_empty;
--i_hddraid_dbgcs.data(18)            <=i_hdd_rxbuf_empty;
--i_hddraid_dbgcs.data(19)            <=i_hdd_rxbuf_pempty;
--i_hddraid_dbgcs.data(20)            <=tst_hdd_rambuf_out(11);--<=tst_rambuf_empty;
--
--i_hddraid_dbgcs.data(26 downto 21)  <=i_memch0_in_bank (1).cmd_bl       ;--: std_logic_vector(5 downto 0);
--i_hddraid_dbgcs.data(27)            <=i_memch0_in_bank (1).cmd_wr       ;--: std_logic;
--i_hddraid_dbgcs.data(28)            <=i_memch0_out_bank(1).cmdbuf_full  ;--: std_logic;
--i_hddraid_dbgcs.data(29)            <=i_memch0_out_bank(1).cmdbuf_empty ;--: std_logic;
--i_hddraid_dbgcs.data(30)            <=i_memch0_in_bank (1).txd_wr       ;--: std_logic;
--i_hddraid_dbgcs.data(31)            <=i_memch0_out_bank(1).txbuf_full   ;--: std_logic;
--i_hddraid_dbgcs.data(32)            <=i_memch0_out_bank(1).txbuf_empty  ;--: std_logic;
--i_hddraid_dbgcs.data(39 downto 33)  <=i_memch0_out_bank(1).txbuf_wrcount;--: std_logic_vector(6 downto 0);
--i_hddraid_dbgcs.data(40)            <=i_memch0_out_bank(1).txbuf_err;
--i_hddraid_dbgcs.data(41)            <=i_memch0_out_bank(1).txbuf_underrun;
--
--i_hddraid_dbgcs.data(47 downto 42)  <=i_memch1_in_bank (1).cmd_bl       ;--: std_logic_vector(5 downto 0);
--i_hddraid_dbgcs.data(48)            <=i_memch1_in_bank (1).cmd_wr       ;--: std_logic;
--i_hddraid_dbgcs.data(49)            <=i_memch1_out_bank(1).cmdbuf_full  ;--: std_logic;
--i_hddraid_dbgcs.data(50)            <=i_memch1_out_bank(1).cmdbuf_empty ;--: std_logic;
--i_hddraid_dbgcs.data(51)            <=i_memch1_in_bank (1).rxd_rd       ;--: std_logic;
--i_hddraid_dbgcs.data(52)            <=i_memch1_out_bank(1).rxbuf_full   ;--: std_logic;
--i_hddraid_dbgcs.data(53)            <=i_memch1_out_bank(1).rxbuf_empty  ;--: std_logic;
--i_hddraid_dbgcs.data(60 downto 54)  <=i_memch1_out_bank(1).rxbuf_rdcount;--: std_logic_vector(6 downto 0);
--i_hddraid_dbgcs.data(61)            <=i_memch1_out_bank(1).rxbuf_err;
--i_hddraid_dbgcs.data(62)            <=i_memch1_out_bank(1).rxbuf_overflow;
--
--i_hddraid_dbgcs.data(95 downto 64) <=i_memch0_in_bank (1).txd(31 downto 0);--i_vbufin_dout
--i_hddraid_dbgcs.data(127 downto 96)<=i_memch1_out_bank(1).rxd(31 downto 0);--i_vbufout_din;--Rx
--
--i_hddraid_dbgcs.data(128)          <=i_hdd_rbuf_cfg.dmacfg.hw_mode;
--i_hddraid_dbgcs.data(129)          <=i_hdd_rbuf_cfg.dmacfg.sw_mode;
--i_hddraid_dbgcs.data(130)          <=i_hdd_rbuf_cfg.tstgen.tesing_on;
--i_hddraid_dbgcs.data(131)          <=i_hdd_rbuf_cfg.tstgen.con2rambuf;
--i_hddraid_dbgcs.data(132)          <=tst_vin_hdd_out(0);--g_buf_rd;
--
--i_hddraid_dbgcs.data(133)          <=i_hdd_tst_out(3);--<=i_sh_txd_rd;--//dsn_hdd_txbuf
--i_hddraid_dbgcs.data(134)          <=i_hdd_tst_out(4);--<=i_sh_rxd_wr;--//dsn_hdd_rxbuf
--
--
--
--
--process(g_hclk)
--begin
--  if g_hclk'event and g_hclk='1' then
--    sr_vctrl_rst(0)<=i_vctrl_rst;
--    sr_vctrl_rst(1)<=sr_vctrl_rst(0);
--    tst_syn<=not sr_vctrl_rst(0) and sr_vctrl_rst(1);
--
----    tst_vin_vs <=p_in_vin_vs ;--   : in   std_logic;
----    tst_vin_hs <=p_in_vin_hs ;--   : in   std_logic;
----    tst_vout_vs<=p_in_vout_vs;--   : in   std_logic;
----    tst_vout_hs<=p_in_vout_hs;--   : in   std_logic;
--  end if;
--end process;



----m_dbgcs_icon : dbgcs_iconx2
----port map(
----CONTROL0 => i_dbgcs_hdd_raid,
----CONTROL1 => i_dbgcs_cfg
----);
--m_dbgcs_icon : dbgcs_iconx1
--port map(
--CONTROL0 => i_dbgcs_hdd_raid
--);
--
--m_dbgcs_sh0_raid : dbgcs_sata_raid
--port map(
--CONTROL => i_dbgcs_hdd_raid,
--CLK     => g_hclk,--i_hdd_dbgcs.raid.clk,
--DATA    => i_hddraid_dbgcs.data(172 downto 0),--(122 downto 0),
--TRIG0   => i_hddraid_dbgcs.trig0(41 downto 0)
--);
--
----//-------- TRIG: ------------------
--i_hddraid_dbgcs.trig0(0)            <=tst_hdd_rambuf_out(0)         ;--tst_vctrl_out(0)         ;--vwriter(0)<=p_in_cfg_mem_start;
--i_hddraid_dbgcs.trig0(1)            <=tst_hdd_rambuf_out(1)         ;--tst_vctrl_out(1)         ;--vwriter(1)<=i_mem_done;
--i_hddraid_dbgcs.trig0(4 downto 2)   <=tst_hdd_rambuf_out(4 downto 2);--tst_vctrl_out(4 downto 2);--vwriter(4 downto 2)<=tst_fsm_cs;
--i_hddraid_dbgcs.trig0(5)            <=tst_hdd_rambuf_out(5)         ;--tst_vctrl_out(5)         ;--vreader(0)<=p_in_cfg_mem_start;
--i_hddraid_dbgcs.trig0(6)            <=tst_hdd_rambuf_out(6)         ;--tst_vctrl_out(6)         ;--vreader(1)<=i_mem_done;
--i_hddraid_dbgcs.trig0(9 downto 7)   <=tst_hdd_rambuf_out(9 downto 7);--tst_vctrl_out(9 downto 7);--vreader(4 downto 2)<=tst_fsm_cs;
--i_hddraid_dbgcs.trig0(10)           <=tst_hdd_rambuf_out(14)        ;--tst_vctrl_out(14)        ;--  <=i_vwr_fr_rdy(0);
--i_hddraid_dbgcs.trig0(11)           <=tst_hdd_rambuf_out(15)        ;--tst_vctrl_out(15)        ;--  <=i_vrd_hold(0);
--i_hddraid_dbgcs.trig0(12)           <=p_in_vin_vs;--   : in   std_logic;
--i_hddraid_dbgcs.trig0(13)           <=p_in_vin_hs;--   : in   std_logic;
--i_hddraid_dbgcs.trig0(14)           <=p_in_vout_vs;--   : in   std_logic;
--i_hddraid_dbgcs.trig0(15)           <=p_in_vout_hs;--   : in   std_logic;
--
--i_hddraid_dbgcs.trig0(16)           <=i_memch0_in_bank(0).cmd_wr;-- : std_logic;
--i_hddraid_dbgcs.trig0(17)           <=i_memch1_in_bank(0).cmd_wr;-- : std_logic;
--i_hddraid_dbgcs.trig0(18)           <=tst_syn;
--i_hddraid_dbgcs.trig0(19)           <=tst_hdd_rambuf_out(20);--i_ram_txbuf_rd;
--i_hddraid_dbgcs.trig0(20)           <=tst_hdd_rambuf_out(21);--i_ram_rxbuf_wr;
--i_hddraid_dbgcs.trig0(21)           <=tst_hdd_rambuf_out(24);--<=i_ram_txbuf_afull;--
--i_hddraid_dbgcs.trig0(22)           <=tst_hdd_rambuf_out(25);--<=i_ram_rxbuf_afull;--
--
--i_hddraid_dbgcs.trig0(23)           <=i_memch0_out_bank(1).cmdbuf_full  ;
--i_hddraid_dbgcs.trig0(24)           <=i_memch0_out_bank(1).txbuf_full   ;
--i_hddraid_dbgcs.trig0(25)           <=i_memch0_out_bank(1).txbuf_err;
--i_hddraid_dbgcs.trig0(26)           <=i_memch0_out_bank(1).txbuf_underrun;
--i_hddraid_dbgcs.trig0(27)           <=i_memch1_out_bank(1).cmdbuf_full  ;
--i_hddraid_dbgcs.trig0(28)           <=i_memch1_out_bank(1).rxbuf_full   ;
--i_hddraid_dbgcs.trig0(29)           <=i_memch1_out_bank(1).rxbuf_err;
--i_hddraid_dbgcs.trig0(30)           <=i_memch1_out_bank(1).rxbuf_overflow;
--
--i_hddraid_dbgcs.trig0(31)           <=tst_hdd_rambuf_out(10);--<=tst_hw_stop;
--i_hddraid_dbgcs.trig0(32)           <=tst_hdd_rambuf_out(11);--<=tst_rambuf_empty;
--i_hddraid_dbgcs.trig0(33)           <=i_hdd_rbuf_status.err;--<=i_err_det.rambuf_full or i_err_det.vinbuf_full;
--
--
----//-------- VIEW: ------------------
--i_hddraid_dbgcs.data(0)             <=tst_hdd_rambuf_out(0)         ;--tst_vctrl_out(0)         ;--vwriter(0)<=p_in_cfg_mem_start;
--i_hddraid_dbgcs.data(1)             <=tst_hdd_rambuf_out(1)         ;--tst_vctrl_out(1)         ;--vwriter(1)<=i_mem_done;
--i_hddraid_dbgcs.data(4 downto 2)    <=tst_hdd_rambuf_out(4 downto 2);--tst_vctrl_out(4 downto 2);--vwriter(4 downto 2)<=tst_fsm_cs;
--i_hddraid_dbgcs.data(5)             <=tst_hdd_rambuf_out(5)         ;--tst_vctrl_out(5)         ;--vreader(0)<=p_in_cfg_mem_start;
--i_hddraid_dbgcs.data(6)             <=tst_hdd_rambuf_out(6)         ;--tst_vctrl_out(6)         ;--vreader(1)<=i_mem_done;
--i_hddraid_dbgcs.data(9 downto 7)    <=tst_hdd_rambuf_out(9 downto 7);--tst_vctrl_out(9 downto 7);--vreader(4 downto 2)<=tst_fsm_cs;
--i_hddraid_dbgcs.data(10)            <=tst_hdd_rambuf_out(14)        ;--tst_vctrl_out(14)        ;--  <=i_vwr_fr_rdy(0);/ram_start
--i_hddraid_dbgcs.data(11)            <=tst_hdd_rambuf_out(15)        ;--tst_vctrl_out(15)        ;--  <=i_vrd_hold(0);
--i_hddraid_dbgcs.data(13 downto 12)  <=tst_vctrl_out(11 downto 10);--<=i_vbuf_wr(0);
--i_hddraid_dbgcs.data(15 downto 14)  <=tst_vctrl_out(13 downto 12);--<=i_vbuf_rd(0);
--i_hddraid_dbgcs.data(16)            <=i_vbufin_empty;
--i_hddraid_dbgcs.data(17)            <=i_vbufout_full;
--i_hddraid_dbgcs.data(18)            <=tst_vin_vs; --   : in   std_logic;
--i_hddraid_dbgcs.data(19)            <=tst_vin_hs; --   : in   std_logic;
--i_hddraid_dbgcs.data(20)            <=tst_vout_vs;--   : in   std_logic;
--i_hddraid_dbgcs.data(21)            <=tst_vout_hs;--   : in   std_logic;
--
--i_hddraid_dbgcs.data(27 downto 22)  <=i_memch0_in_bank (1).cmd_bl       ;--: std_logic_vector(5 downto 0);
--i_hddraid_dbgcs.data(28)            <=i_memch0_in_bank (1).cmd_wr       ;--: std_logic;
--i_hddraid_dbgcs.data(29)            <=i_memch0_out_bank(1).cmdbuf_full  ;--: std_logic;
--i_hddraid_dbgcs.data(30)            <=i_memch0_out_bank(1).cmdbuf_empty ;--: std_logic;
--i_hddraid_dbgcs.data(31)            <=i_memch0_in_bank (1).txd_wr       ;--: std_logic;
--i_hddraid_dbgcs.data(32)            <=i_memch0_out_bank(1).txbuf_full   ;--: std_logic;
--i_hddraid_dbgcs.data(33)            <=i_memch0_out_bank(1).txbuf_empty  ;--: std_logic;
--i_hddraid_dbgcs.data(40 downto 34)  <=i_memch0_out_bank(1).txbuf_wrcount;--: std_logic_vector(6 downto 0);
--i_hddraid_dbgcs.data(46 downto 41)  <=i_memch1_in_bank (1).cmd_bl       ;--: std_logic_vector(5 downto 0);
--i_hddraid_dbgcs.data(47)            <=i_memch1_in_bank (1).cmd_wr       ;--: std_logic;
--i_hddraid_dbgcs.data(48)            <=i_memch1_out_bank(1).cmdbuf_full  ;--: std_logic;
--i_hddraid_dbgcs.data(49)            <=i_memch1_out_bank(1).cmdbuf_empty ;--: std_logic;
--i_hddraid_dbgcs.data(50)            <=i_memch1_in_bank (1).rxd_rd       ;--: std_logic;
--i_hddraid_dbgcs.data(51)            <=i_memch1_out_bank(1).rxbuf_full   ;--: std_logic;
--i_hddraid_dbgcs.data(52)            <=i_memch1_out_bank(1).rxbuf_empty  ;--: std_logic;
--i_hddraid_dbgcs.data(59 downto 53)  <=i_memch1_out_bank(1).rxbuf_rdcount;--: std_logic_vector(6 downto 0);
--
--i_hddraid_dbgcs.data(60)            <=tst_hdd_rambuf_out(22);--i_ram_txbuf_empty;
--i_hddraid_dbgcs.data(61)            <=tst_hdd_rambuf_out(23);--i_ram_rxbuf_empty;
--i_hddraid_dbgcs.data(62)            <=i_vctrl_rst;
--i_hddraid_dbgcs.data(63)            <=tst_syn;
--
--i_hddraid_dbgcs.data(69 downto 64)  <=tst_vctrl_out(21 downto 16);--<=tst_vwr_out(21 downto 16);--i_mem_trn_len;
--i_hddraid_dbgcs.data(74 downto 70)  <=tst_hdd_rambuf_out(30 downto 26);--<=tst_fsm_cs;
--i_hddraid_dbgcs.data(75)            <=tst_hdd_rambuf_out(10);--<=tst_hw_stop;
--i_hddraid_dbgcs.data(76)            <=tst_hdd_rambuf_out(11);--<=tst_rambuf_empty;
--i_hddraid_dbgcs.data(77)            <=i_hdd_rbuf_status.err;--<=i_err_det.rambuf_full or i_err_det.vinbuf_full;
--i_hddraid_dbgcs.data(78)            <=i_hdd_rbuf_status.err_type.vinbuf_full;
--i_hddraid_dbgcs.data(79)            <=i_hdd_rbuf_status.err_type.rambuf_full;
--i_hddraid_dbgcs.data(95 downto 80)  <=(others=>'0');
--
----i_hddraid_dbgcs.data(95 downto 64)  <=i_hdd_vbufin_dout;--i_vin_dout;--(others=>'0');
--i_hddraid_dbgcs.data(96)            <='0';--tst_vctrl_out(16);--<=tst_vwr_out(5);--<=i_mem_cmden;
--i_hddraid_dbgcs.data(97)            <='0';--tst_vctrl_out(17);--<=tst_vrd_out(5);--<=i_mem_cmden;
--i_hddraid_dbgcs.data(98)            <=tst_hdd_rambuf_out(24);--<=i_ram_txbuf_afull;--tst_vctrl_out(18);--<=tst_vwr_out(6);--<=i_mem_trn_work;
--i_hddraid_dbgcs.data(99)            <=tst_hdd_rambuf_out(25);--<=i_ram_rxbuf_afull;--tst_vctrl_out(19);--<=tst_vrd_out(6);--<=i_mem_trn_work;
--
--i_hddraid_dbgcs.data(131 downto 100) <=i_memch0_in_bank (1).txd(31 downto 0) ;--i_vbufin_dout
--i_hddraid_dbgcs.data(163 downto 132) <=i_memch1_out_bank(1).rxd(31 downto 0);--i_vbufout_din;--Rx
--
--i_hddraid_dbgcs.data(164)            <=tst_hdd_rambuf_out(21);--i_ram_rxbuf_wr;
--i_hddraid_dbgcs.data(165)            <=tst_hdd_rambuf_out(20);--i_ram_txbuf_rd;
--i_hddraid_dbgcs.data(166)            <=i_vbufin_rd;--t_vbufin_rd;
--i_hddraid_dbgcs.data(167)            <=i_hdd_vbufin_rd;
--i_hddraid_dbgcs.data(168)            <=i_memch0_out_bank(1).txbuf_err;
--i_hddraid_dbgcs.data(169)            <=i_memch0_out_bank(1).txbuf_underrun;
--i_hddraid_dbgcs.data(170)            <=i_memch1_out_bank(1).rxbuf_err;
--i_hddraid_dbgcs.data(171)            <=i_memch1_out_bank(1).rxbuf_overflow;
--
--
--process(g_hclk)
--begin
--  if g_hclk'event and g_hclk='1' then
--    sr_vctrl_rst(0)<=i_vctrl_rst;
--    sr_vctrl_rst(1)<=sr_vctrl_rst(0);
--    tst_syn<=not sr_vctrl_rst(0) and sr_vctrl_rst(1);
--
--    tst_vin_vs <=p_in_vin_vs ;--   : in   std_logic;
--    tst_vin_hs <=p_in_vin_hs ;--   : in   std_logic;
--    tst_vout_vs<=p_in_vout_vs;--   : in   std_logic;
--    tst_vout_hs<=p_in_vout_hs;--   : in   std_logic;
--  end if;
--end process;



--m_dbgcs_cfg : dbgcs_sata_raid
--port map(
--CONTROL => i_dbgcs_cfg,
--CLK     => i_hdd_rbuf_cfg.ram_wr_i.clk,--i_hdd_dbgcs.raid.clk,
--DATA    => i_cfg_dbgcs.data(172 downto 0),--(122 downto 0),
--TRIG0   => i_cfg_dbgcs.trig0(41 downto 0)
--);
--
----//-------- TRIG: ------------------
--i_cfg_dbgcs.trig0(0)             <=i_cfg_adr_ld   ;
--i_cfg_dbgcs.trig0(1)             <=i_cfg_adr_fifo ;
--i_cfg_dbgcs.trig0(2)             <=i_cfg_wd       ;
--i_cfg_dbgcs.trig0(5)             <=i_cfg_rd       ;
--i_cfg_dbgcs.trig0(6)             <=i_cfg_txrdy    ;
--i_cfg_dbgcs.trig0(7)             <=i_cfg_rxrdy    ;
--i_cfg_dbgcs.trig0(13 downto 8)   <=i_cfg_adr(5 downto 0);
--i_cfg_dbgcs.trig0(14)            <='0';
--i_cfg_dbgcs.trig0(15)            <='0';
--i_cfg_dbgcs.trig0(16)            <=tst_hdd_rambuf_out(22);--i_ram_txbuf_empty;
--i_cfg_dbgcs.trig0(17)            <=tst_hdd_rambuf_out(23);--i_ram_rxbuf_empty;
--i_cfg_dbgcs.trig0(18)            <=tst_hdd_rambuf_out(24);--<=i_ram_txbuf_afull;--
--i_cfg_dbgcs.trig0(19)            <=tst_hdd_rambuf_out(25);--<=i_ram_rxbuf_afull;--
--
----//-------- VIEW: ------------------
--i_cfg_dbgcs.data(0)             <=i_cfg_adr_ld   ;
--i_cfg_dbgcs.data(1)             <=i_cfg_adr_fifo ;
--i_cfg_dbgcs.data(2)             <=i_cfg_wd       ;
--i_cfg_dbgcs.data(5)             <=i_cfg_rd       ;
--i_cfg_dbgcs.data(6)             <=i_cfg_txrdy    ;
--i_cfg_dbgcs.data(7)             <=i_cfg_rxrdy    ;
--i_cfg_dbgcs.data(13 downto 8)   <=i_cfg_adr(5 downto 0);
--
--i_cfg_dbgcs.data(14)            <=i_hdd_tst_out(8);--<=i_ram_d_wcnt;
--i_cfg_dbgcs.data(15)            <='0';
--
--i_cfg_dbgcs.data(31 downto 16)  <=i_cfg_txd;
--i_cfg_dbgcs.data(47 downto 32)  <=i_cfg_rxd;
--
--i_cfg_dbgcs.data(48)            <=i_hdd_rbuf_cfg.ram_wr_i.wr;
--i_cfg_dbgcs.data(49)            <=tst_hdd_rambuf_out(22);--i_ram_txbuf_empty;
--i_cfg_dbgcs.data(50)            <=tst_hdd_rambuf_out(24);--<=i_ram_txbuf_afull;--
--
--i_cfg_dbgcs.data(51)            <=i_hdd_rbuf_cfg.ram_wr_i.rd;
--i_cfg_dbgcs.data(52)            <=tst_hdd_rambuf_out(23);--i_ram_rxbuf_empty;
--i_cfg_dbgcs.data(53)            <=tst_hdd_rambuf_out(25);--<=i_ram_rxbuf_afull;--
--
--i_cfg_dbgcs.data(63 downto 54)  <=(others=>'0');
--
--i_cfg_dbgcs.data(79 downto 64)  <=i_hdd_rbuf_status.ram_wr_o.dout(15 downto 0);
--i_cfg_dbgcs.data(95 downto 80)  <=(others=>'0');--i_hdd_rbuf_status.ram_wr_o.dout(31 downto 16);
--
--i_cfg_dbgcs.data(172 downto 96) <=(others=>'0');





--END MAIN
end architecture;
