-------------------------------------------------------------------------
-- Company     : Linkos
-- Engineer    : Golovachenko Victor
--
-- Create Date : 20.01.2011 11:43:14
-- Module Name : hdd_test_main
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

entity hdd_test_main is
generic(
G_SIM : string:="OFF"
);
port(
--------------------------------------------------
--DBG
--------------------------------------------------
pin_out_led_C         : out   std_logic;
pin_out_led_E         : out   std_logic;
pin_out_led_N         : out   std_logic;
pin_out_led_S         : out   std_logic;
pin_out_led_W         : out   std_logic;

pin_in_btn_C          : in    std_logic;
pin_in_btn_E          : in    std_logic;
pin_in_btn_N          : in    std_logic;
pin_in_btn_S          : in    std_logic;
pin_in_btn_W          : in    std_logic;

pin_out_uart0_tx      : out   std_logic;
pin_in_uart0_rx       : in    std_logic;

pin_out_led           : out   std_logic_vector(7 downto 0);
pin_out_TP            : out   std_logic_vector(7 downto 0);

pin_inout_ftdi_d      : inout std_logic_vector(7 downto 0);
pin_out_ftdi_rd_n     : out   std_logic;
pin_out_ftdi_wr_n     : out   std_logic;
pin_in_ftdi_txe_n     : in    std_logic;
pin_in_ftdi_rxf_n     : in    std_logic;
pin_in_ftdi_pwren_n   : in    std_logic;

--------------------------------------------------
-- Reference clock
--------------------------------------------------
pin_in_refclk_n       : in    std_logic;
pin_in_refclk_p       : in    std_logic;

--------------------------------------------------
--SATA
--------------------------------------------------
pin_out_sata_txn      : out   std_logic_vector((C_SH_GTCH_COUNT_MAX*C_SH_COUNT_MAX(C_PCFG_HDD_COUNT-1))-1 downto 0);
pin_out_sata_txp      : out   std_logic_vector((C_SH_GTCH_COUNT_MAX*C_SH_COUNT_MAX(C_PCFG_HDD_COUNT-1))-1 downto 0);
pin_in_sata_rxn       : in    std_logic_vector((C_SH_GTCH_COUNT_MAX*C_SH_COUNT_MAX(C_PCFG_HDD_COUNT-1))-1 downto 0);
pin_in_sata_rxp       : in    std_logic_vector((C_SH_GTCH_COUNT_MAX*C_SH_COUNT_MAX(C_PCFG_HDD_COUNT-1))-1 downto 0);
pin_in_sata_clk_n     : in    std_logic_vector(C_SH_COUNT_MAX(C_PCFG_HDD_COUNT-1)-1 downto 0);
pin_in_sata_clk_p     : in    std_logic_vector(C_SH_COUNT_MAX(C_PCFG_HDD_COUNT-1)-1 downto 0)
);
end entity;

architecture struct of hdd_test_main is

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

signal i_dbgcs_sh0_spd                  : std_logic_vector(35 downto 0);
signal i_dbgcs_hdd0_layer               : std_logic_vector(35 downto 0);
signal i_dbgcs_hdd1_layer               : std_logic_vector(35 downto 0);
signal i_dbgcs_hdd_raid                 : std_logic_vector(35 downto 0);
signal i_dbgcs_cfg                      : std_logic_vector(35 downto 0);

signal i_hdd0layer_dbgcs                : TSH_ila;
signal i_hdd1layer_dbgcs                : TSH_ila;
signal i_cfg_dbgcs                      : TSH_ila;
signal i_hddraid_dbgcs                  : TSH_ila;

--constant CI_MEM_BANK_M_BIT : integer:=C_MEMCTRL_AWIDTH+1;
--constant CI_MEM_BANK_L_BIT : integer:=C_MEMCTRL_AWIDTH+1;
constant CI_MEM_AWIDTH     : integer:=32;
constant CI_MEM_DWIDTH     : integer:=C_PCFG_MEM_DWIDTH;--C_MEMCTRL_DWIDTH;

component hdd_ram_hfifo_tx
port(
din         : in std_logic_vector(15 downto 0);
wr_en       : in std_logic;
wr_clk      : in std_logic;

dout        : out std_logic_vector(CI_MEM_DWIDTH-1 downto 0);
rd_en       : in std_logic;
rd_clk      : in std_logic;

full        : out std_logic;
almost_full : out std_logic;
empty       : out std_logic;
prog_full   : out std_logic;

--clk         : in std_logic;
rst         : in std_logic
);
end component;

component hdd_ram_hfifo_rx
port(
din         : in std_logic_vector(CI_MEM_DWIDTH-1 downto 0);
wr_en       : in std_logic;
wr_clk      : in std_logic;

dout        : out std_logic_vector(15 downto 0);
rd_en       : in std_logic;
rd_clk      : in std_logic;

full        : out std_logic;
almost_full : out std_logic;
empty       : out std_logic;
prog_full   : out std_logic;

--clk         : in std_logic;
rst         : in std_logic
);
end component;

component fpga_test_01
generic(
G_BLINK_T05   : integer:=10#125#; -- 1/2 периода мигания светодиода.(время в ms)
G_CLK_T05us   : integer:=10#1000# -- кол-во периодов частоты порта p_in_clk
                                  -- укладывающиеся в 1/2 периода 1us
);
port(
p_out_test_led : out   std_logic;--//мигание сведодиода
p_out_test_done: out   std_logic;--//сигнал переходи в '1' через 3 сек.

p_out_1us      : out   std_logic;
p_out_1ms      : out   std_logic;
-------------------------------
--System
-------------------------------
p_in_clk       : in    std_logic;
p_in_rst       : in    std_logic
);
end component;

signal i_sys_rst_cnt                    : std_logic_vector(5 downto 0):=(others=>'0');
signal i_sys_rst                        : std_logic:='0';
signal i_usr_rst                        : std_logic:='0';
signal g_cfg_clk                        : std_logic:='0';
signal g_hdd_clk                        : std_logic:='0';

signal g_sata_refclkout                 : std_logic;
signal i_hdd_rst                        : std_logic;
signal i_hdd_gt_refclk150               : std_logic_vector(C_SH_COUNT_MAX(C_PCFG_HDD_COUNT-1)-1 downto 0);
signal i_hdd_gt_plldet                  : std_logic;
signal i_hdd_dcm_lock                   : std_logic;
--signal g_hdd_dcm_gclk75M                : std_logic;
--signal g_hdd_dcm_gclk300M               : std_logic;
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
signal i_hdd_tst_in                     : std_logic_vector(31 downto 0);
signal i_hdd_tst_out                    : std_logic_vector(31 downto 0);

signal i_ram_txbuf_full                 : std_logic;
signal i_ram_txbuf_empty                : std_logic;
signal i_ram_rxbuf_full                 : std_logic;
signal i_ram_rxbuf_empty                : std_logic;
signal i_ram_reset_buf                  : std_logic;

signal i_test01_led                     : std_logic;
signal i_test02_led                     : std_logic;
signal i_usr_refclk150                  : std_logic;
signal g_usr_refclk150                  : std_logic;
signal t_usr_refclk150                  : std_logic;

signal tst_sh_txbuf_empty               : std_logic_vector(2 downto 0);
signal tst_sh_txbuf_empty_err           : std_logic;

--//MAIN
begin


--***********************************************************
--Частоты
--***********************************************************
g_cfg_clk<=g_usr_refclk150;
g_hdd_clk<=g_usr_refclk150;--g_hdd_dcm_gclk150M;

m_ibufds_refclk : IBUFDS port map (I => pin_in_refclk_p, IB => pin_in_refclk_n, O => i_usr_refclk150);
m_bufio2_refclk : BUFIO2 port map (I => i_usr_refclk150, DIVCLK => t_usr_refclk150, IOCLK => open, SERDESSTROBE => open );
m_bufg_refclk   : BUFG   port map (I => t_usr_refclk150, O => g_usr_refclk150);


--***********************************************************
--RESET
--***********************************************************
process(g_usr_refclk150)
begin
  if g_usr_refclk150'event and g_usr_refclk150 = '1' then
    if i_sys_rst_cnt(i_sys_rst_cnt'high) = '0' then
      i_sys_rst_cnt <= i_sys_rst_cnt + 1;
    end if;
  end if;
end process;

i_sys_rst <= i_sys_rst_cnt(i_sys_rst_cnt'high - 1);
i_hdd_rst <= i_sys_rst or i_hdd_rbuf_cfg.grst_hdd;
i_ram_reset_buf<=i_hdd_rst or i_hdd_rbuf_cfg.dmacfg.clr_err;


--***********************************************************
--Проект Накопителя - dsn_hdd.vhd
--***********************************************************
gen_sata_gt : for i in 0 to C_SH_COUNT_MAX(C_PCFG_HDD_COUNT-1)-1 generate
  m_ibufds : IBUFDS port map(I  => pin_in_sata_clk_p(i), IB => pin_in_sata_clk_n(i), O => i_hdd_gt_refclk150(i));
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

p_in_hdd_txd_wrclk    => g_hdd_clk,
p_in_hdd_txd          => i_hdd_txdata,
p_in_hdd_txd_wr       => i_hdd_txdata_wd,
p_out_hdd_txbuf_pfull => i_hdd_txbuf_pfull,
p_out_hdd_txbuf_full  => i_hdd_txbuf_full,
p_out_hdd_txbuf_empty => i_hdd_txbuf_empty,

p_in_hdd_rxd_rdclk    => g_hdd_clk,
p_out_hdd_rxd         => i_hdd_rxdata,
p_in_hdd_rxd_rd       => i_hdd_rxdata_rd,
p_out_hdd_rxbuf_empty => i_hdd_rxbuf_empty,
p_out_hdd_rxbuf_pempty=> i_hdd_rxbuf_pempty,

-------------------------------
--Sata Driver
-------------------------------
p_out_sata_txn        => pin_out_sata_txn,
p_out_sata_txp        => pin_out_sata_txp,
p_in_sata_rxn         => pin_in_sata_rxn,
p_in_sata_rxp         => pin_in_sata_rxp,

p_in_sata_refclk      => i_hdd_gt_refclk150,
p_out_sata_refclkout  => g_sata_refclkout,
p_out_sata_gt_plldet  => i_hdd_gt_plldet,
p_out_sata_dcm_lock   => i_hdd_dcm_lock,
p_out_sata_dcm_gclk2div=> open,--g_hdd_dcm_gclk75M,
p_out_sata_dcm_gclk2x  => open,--g_hdd_dcm_gclk300M,
p_out_sata_dcm_gclk0   => g_hdd_dcm_gclk150M,

-------------------------------
--Технологический порт
-------------------------------
p_in_tst              => i_hdd_tst_in,
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

i_hdd_rbuf_status.err<='0';
i_hdd_rbuf_status.err_type.bufi_full<='0';
i_hdd_rbuf_status.err_type.rambuf_full<='0';
i_hdd_rbuf_status.done <='0';
i_hdd_rbuf_status.hwlog_size<=(others=>'0');


--***********************************************************
--CFG<->HDD
--***********************************************************
--HDD<-CFG
m_txbuf : hdd_ram_hfifo_tx
port map(
din         => i_hdd_rbuf_cfg.ram_wr_i.din,
wr_en       => i_hdd_rbuf_cfg.ram_wr_i.wr,
wr_clk      => i_hdd_rbuf_cfg.ram_wr_i.clk,

dout        => i_hdd_txdata,
rd_en       => i_hdd_txdata_wd,
rd_clk      => g_hdd_clk,

full        => open,
almost_full => open,
empty       => i_ram_txbuf_empty,
prog_full   => i_ram_txbuf_full,

--clk         => p_in_clk,
rst         => i_ram_reset_buf
);

i_hdd_txdata_wd<=not i_ram_txbuf_empty and not i_ram_txbuf_full;
i_hdd_rbuf_status.ram_wr_o.wr_rdy<= not i_ram_txbuf_full;

--HDD->CFG
m_rxbuf : hdd_ram_hfifo_rx
port map(
din         => i_hdd_rxdata,
wr_en       => i_hdd_rxdata_rd,
wr_clk      => g_hdd_clk,

dout        => i_hdd_rbuf_status.ram_wr_o.dout,
rd_en       => i_hdd_rbuf_cfg.ram_wr_i.rd,
rd_clk      => i_hdd_rbuf_cfg.ram_wr_i.clk,

full        => open,
almost_full => open,
empty       => i_ram_rxbuf_empty,
prog_full   => i_ram_rxbuf_full,

--clk         => p_in_clk,
rst         => i_ram_reset_buf
);

i_hdd_rxdata_rd<=not i_hdd_rxbuf_empty and not i_ram_rxbuf_full;
i_hdd_rbuf_status.ram_wr_o.rd_rdy<= not i_ram_rxbuf_empty;


--***********************************************************
--Технологические сигналы
--***********************************************************
m_test01: fpga_test_01
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
p_in_clk       => g_hdd_dcm_gclk150M,
p_in_rst       => i_sys_rst
);

m_test02: fpga_test_01
generic map(
G_BLINK_T05   =>10#250#, -- 1/2 периода мигания светодиода.(время в ms)
G_CLK_T05us   =>10#75#   -- 05us - 150MHz
)
port map(
p_out_test_led => i_test02_led,
p_out_test_done=> open,

p_out_1us      => open,
p_out_1ms      => open,
-------------------------------
--System
-------------------------------
p_in_clk       => g_usr_refclk150,
p_in_rst       => i_sys_rst
);

gen_hscam : if strcmp(C_PCFG_BOARD,"HSCAM") generate
--Модуль конфигурирования устр-в
pin_out_uart0_tx <= pin_in_uart0_rx;

m_cfgdev : cfgdev_ftdi
port map(
-------------------------------
--Связь с FTDI
-------------------------------
p_inout_ftdi_d       => pin_inout_ftdi_d,
p_out_ftdi_rd_n      => pin_out_ftdi_rd_n,
p_out_ftdi_wr_n      => pin_out_ftdi_wr_n,
p_in_ftdi_txe_n      => pin_in_ftdi_txe_n,
p_in_ftdi_rxf_n      => pin_in_ftdi_rxf_n,
p_in_ftdi_pwren_n    => pin_in_ftdi_pwren_n,

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

--i_usr_rst<=i_grst_mnl(0);
i_hdd_tst_in(31 downto 0)<=(others=>'0');

pin_out_led_E<=pin_in_btn_E;--'0';--
pin_out_led_N<=pin_in_btn_N;--'0';--
pin_out_led_S<=pin_in_btn_S;--'0';--
pin_out_led_W<=pin_in_btn_W;--'0';--
pin_out_led_C<=pin_in_btn_C;--'0';--

--HDD LEDs:
--SATA0 (На плате SATA1)
pin_out_led(2)<=i_hdd_dbgled(0).wr  when i_hdd_dbgled(0).err='0' else i_hdd_dbgled(0).link;
pin_out_led(4)<=i_hdd_dbgled(0).rdy when i_hdd_dbgled(0).err='0' else i_test01_led;
pin_out_TP(0) <=i_test01_led;
pin_out_TP(1) <=i_hdd_dbgled(0).busy;

--SATA1 (На плате SATA0)
pin_out_led(3)<=i_hdd_dbgled(1).wr  when i_hdd_dbgled(1).err='0' else i_hdd_dbgled(1).link;
pin_out_led(5)<=i_hdd_dbgled(1).rdy when i_hdd_dbgled(1).err='0' else i_test01_led;
pin_out_TP(2) <=i_test02_led;
pin_out_TP(3) <=i_hdd_dbgled(1).busy;

--SATA2 (На плате SATA3)
pin_out_led(0)<=i_hdd_dbgled(2).wr  when i_hdd_dbgled(2).err='0' else i_hdd_dbgled(2).link;
pin_out_led(7)<=i_hdd_dbgled(2).rdy when i_hdd_dbgled(2).err='0' else i_test01_led;
pin_out_TP(4) <=i_hdd_dcm_lock;
pin_out_TP(5) <=i_hdd_dbgled(2).busy;

--SATA3 (На плате SATA2)
pin_out_led(1)<=i_hdd_dbgled(3).wr  when i_hdd_dbgled(3).err='0' else i_hdd_dbgled(3).link;
pin_out_led(6)<=i_hdd_dbgled(3).rdy when i_hdd_dbgled(3).err='0' else i_test01_led;
pin_out_TP(6) <='0';
pin_out_TP(7) <=i_hdd_dbgled(3).busy;

end generate gen_hscam;


gen_ml505 : if strcmp(C_PCFG_BOARD,"ML505") generate
--Модуль конфигурирования устр-в
gen_ftdi_d : for i in 0 to pin_inout_ftdi_d'length-1 generate
obuft_ftdi_d : OBUFT port map (O => pin_inout_ftdi_d(i), I => '0', T => '1');
end generate gen_ftdi_d;
pin_out_ftdi_rd_n<='1';
pin_out_ftdi_wr_n<='1';

m_cfgdev : cfgdev_uart
generic map(
G_BAUDCNT_VAL => 81   --p_in_uart_refclk=150Mhz - UART_BAUDRATE=115200
--G_BAUDCNT_VAL => 108  --p_in_uart_refclk=200Mhz - UART_BAUDRATE=115200

--//G_BAUDCNT_VAL = Частота порта p_in_uart_refclk/(16 * UART_BAUDRATE)
--//Например: Fuart_refclk=40MHz, UART_BAUDRATE=115200
--//40000000/(16 *115200)=21,701 - округляем до ближайшего цеого, т.е = 22
)
port map(
-------------------------------
--Связь с UART
-------------------------------
p_out_uart_tx        => pin_out_uart0_tx,
p_in_uart_rx         => pin_in_uart0_rx,
p_in_uart_refclk     => g_usr_refclk150,

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
p_out_tst            => open,--i_cfg_tstout(31 downto 0),

-------------------------------
--System
-------------------------------
p_in_rst => i_sys_rst
);

i_hdd_tst_in(31 downto 0)<=(others=>'0');

--//J5 /pin2
pin_out_TP(0)<='0';
--//J6
pin_out_TP(7 downto 1)<=(others=>'0');

--
pin_out_led_E<=i_test01_led;
pin_out_led_N<=pin_in_btn_N;
pin_out_led_S<=pin_in_btn_S;
pin_out_led_W<=pin_in_btn_W;
pin_out_led_C<=pin_in_btn_C;

--HDD LEDs:
pin_out_led(0)<=i_hdd_dbgled(1).busy;
pin_out_led(1)<=i_hdd_dbgled(1).wr;
pin_out_led(2)<=i_hdd_dbgled(1).rdy when i_hdd_dbgled(1).err='0' else i_test01_led;
pin_out_led(3)<=i_hdd_dbgled(1).link;

pin_out_led(4)<=i_hdd_dbgled(0).busy;
pin_out_led(5)<=i_hdd_dbgled(0).wr;
pin_out_led(6)<=i_hdd_dbgled(0).rdy when i_hdd_dbgled(0).err='0' else i_test01_led;
pin_out_led(7)<=i_hdd_dbgled(0).link;

end generate gen_ml505;


gen_dbgcs : if strcmp(C_PCFG_HDD_DBGCS,"ON") generate

gen_sh_dbgcs : if strcmp(C_PCFG_HDD_SH_DBGCS,"ON") generate
m_dbgcs_icon : dbgcs_iconx3
port map(
CONTROL0 => i_dbgcs_sh0_spd,
CONTROL1 => i_dbgcs_hdd0_layer,
CONTROL2 => i_dbgcs_hdd1_layer
);

--//### HDD0_SPD: ########
m_dbgcs_sh0_spd : dbgcs_sata_layer
port map
(
CONTROL => i_dbgcs_sh0_spd,
CLK     => i_hdd_dbgcs.sh(0).spd.clk,
DATA    => i_hdd_dbgcs.sh(0).spd.data(122 downto 0),
TRIG0   => i_hdd_dbgcs.sh(0).spd.trig0(41 downto 0)
);

--//### HDD0: ########
m_dbgcs_hdd0_layer : dbgcs_sata_raid --dbgcs_sata_layer
port map
(
CONTROL => i_dbgcs_hdd0_layer,
CLK     => i_hdd_dbgcs.sh(0).layer.clk,
DATA    => i_hdd_dbgcs.sh(0).layer.data(172 downto 0),--(122 downto 0),
TRIG0   => i_hdd0layer_dbgcs.trig0(41 downto 0)
);

i_hdd0layer_dbgcs.trig0(19 downto 0)<=i_hdd_dbgcs.sh(0).layer.trig0(19 downto 0);--llayer
i_hdd0layer_dbgcs.trig0(20)<=i_hdd_dbgcs.sh(0).layer.data(160);--<=p_in_alstatus.sstatus(C_ASSTAT_DET_BIT_L+1);--//C_PSTAT_DET_ESTABLISH_ON_BIT
i_hdd0layer_dbgcs.trig0(21)<=i_hdd_dbgcs.sh(0).layer.data(161);--<=p_in_alstatus.sstatus(C_ASSTAT_DET_BIT_L+0);--//C_PSTAT_DET_DEV_ON_BIT
i_hdd0layer_dbgcs.trig0(22)<=i_hdd_dbgcs.sh(0).layer.data(162);--<=p_in_txelecidle;
i_hdd0layer_dbgcs.trig0(23)<=i_hdd_dbgcs.sh(0).layer.data(163);--<=p_in_rxelecidle;
i_hdd0layer_dbgcs.trig0(24)<=i_hdd_dbgcs.sh(0).layer.data(164);--<=p_in_txcomstart;
i_hdd0layer_dbgcs.trig0(25)<=i_hdd_dbgcs.sh(0).layer.data(167);--<=p_in_rxcdrreset;
i_hdd0layer_dbgcs.trig0(41 downto 26)<=i_hdd_dbgcs.sh(0).layer.trig0(41 downto 26);--llayer

--//### HDD1: ########
gen_hdd1 : if C_PCFG_HDD_COUNT=1 generate
m_dbgcs_hdd1_layer : dbgcs_sata_raid --dbgcs_sata_layer
port map
(
CONTROL => i_dbgcs_hdd1_layer,
CLK     => i_hdd_dbgcs.sh(0).layer.clk,
DATA    => i_hdd_dbgcs.sh(0).layer.data(172 downto 0),--(122 downto 0),
TRIG0   => i_hdd1layer_dbgcs.trig0(41 downto 0)
);

i_hdd1layer_dbgcs.trig0(19 downto 0)<=i_hdd_dbgcs.sh(0).layer.trig0(19 downto 0);--llayer
i_hdd1layer_dbgcs.trig0(20)<=i_hdd_dbgcs.sh(0).layer.data(160);--<=p_in_alstatus.sstatus(C_ASSTAT_DET_BIT_L+1);--//C_PSTAT_DET_ESTABLISH_ON_BIT
i_hdd1layer_dbgcs.trig0(21)<=i_hdd_dbgcs.sh(0).layer.data(161);--<=p_in_alstatus.sstatus(C_ASSTAT_DET_BIT_L+0);--//C_PSTAT_DET_DEV_ON_BIT
i_hdd1layer_dbgcs.trig0(22)<=i_hdd_dbgcs.sh(0).layer.data(162);--<=p_in_txelecidle;
i_hdd1layer_dbgcs.trig0(23)<=i_hdd_dbgcs.sh(0).layer.data(163);--<=p_in_rxelecidle;
i_hdd1layer_dbgcs.trig0(24)<=i_hdd_dbgcs.sh(0).layer.data(164);--<=p_in_txcomstart;
i_hdd1layer_dbgcs.trig0(25)<=i_hdd_dbgcs.sh(0).layer.data(167);--<=p_in_rxcdrreset;
i_hdd1layer_dbgcs.trig0(41 downto 26)<=i_hdd_dbgcs.sh(0).layer.trig0(41 downto 26);--llayer
end generate gen_hdd1;

gen_hdd2 : if C_PCFG_HDD_COUNT=2 generate
m_dbgcs_hdd1_layer : dbgcs_sata_raid --dbgcs_sata_layer
port map
(
CONTROL => i_dbgcs_hdd1_layer,
CLK     => i_hdd_dbgcs.sh(1).layer.clk,
DATA    => i_hdd_dbgcs.sh(1).layer.data(172 downto 0),--(122 downto 0),
TRIG0   => i_hdd1layer_dbgcs.trig0(41 downto 0)
);

i_hdd1layer_dbgcs.trig0(19 downto 0)<=i_hdd_dbgcs.sh(1).layer.trig0(19 downto 0);--llayer
i_hdd1layer_dbgcs.trig0(20)<=i_hdd_dbgcs.sh(1).layer.data(160);--<=p_in_alstatus.sstatus(C_ASSTAT_DET_BIT_L+1);--//C_PSTAT_DET_ESTABLISH_ON_BIT
i_hdd1layer_dbgcs.trig0(21)<=i_hdd_dbgcs.sh(1).layer.data(161);--<=p_in_alstatus.sstatus(C_ASSTAT_DET_BIT_L+0);--//C_PSTAT_DET_DEV_ON_BIT
i_hdd1layer_dbgcs.trig0(22)<=i_hdd_dbgcs.sh(1).layer.data(162);--<=p_in_txelecidle;
i_hdd1layer_dbgcs.trig0(23)<=i_hdd_dbgcs.sh(1).layer.data(163);--<=p_in_rxelecidle;
i_hdd1layer_dbgcs.trig0(24)<=i_hdd_dbgcs.sh(1).layer.data(164);--<=p_in_txcomstart;
i_hdd1layer_dbgcs.trig0(25)<=i_hdd_dbgcs.sh(1).layer.data(167);--<=p_in_rxcdrreset;
i_hdd1layer_dbgcs.trig0(41 downto 26)<=i_hdd_dbgcs.sh(1).layer.trig0(41 downto 26);--llayer
end generate gen_hdd2;

gen_hdd3 : if C_PCFG_HDD_COUNT>2 generate
m_dbgcs_hdd1_layer : dbgcs_sata_raid --dbgcs_sata_layer
port map
(
CONTROL => i_dbgcs_hdd1_layer,
CLK     => i_hdd_dbgcs.sh(2).layer.clk,
DATA    => i_hdd_dbgcs.sh(2).layer.data(172 downto 0),--(122 downto 0),
TRIG0   => i_hdd1layer_dbgcs.trig0(41 downto 0)
);

i_hdd1layer_dbgcs.trig0(19 downto 0)<=i_hdd_dbgcs.sh(2).layer.trig0(19 downto 0);--llayer
i_hdd1layer_dbgcs.trig0(20)<=i_hdd_dbgcs.sh(2).layer.data(160);--<=p_in_alstatus.sstatus(C_ASSTAT_DET_BIT_L+1);--//C_PSTAT_DET_ESTABLISH_ON_BIT
i_hdd1layer_dbgcs.trig0(21)<=i_hdd_dbgcs.sh(2).layer.data(161);--<=p_in_alstatus.sstatus(C_ASSTAT_DET_BIT_L+0);--//C_PSTAT_DET_DEV_ON_BIT
i_hdd1layer_dbgcs.trig0(22)<=i_hdd_dbgcs.sh(2).layer.data(162);--<=p_in_txelecidle;
i_hdd1layer_dbgcs.trig0(23)<=i_hdd_dbgcs.sh(2).layer.data(163);--<=p_in_rxelecidle;
i_hdd1layer_dbgcs.trig0(24)<=i_hdd_dbgcs.sh(2).layer.data(164);--<=p_in_txcomstart;
i_hdd1layer_dbgcs.trig0(25)<=i_hdd_dbgcs.sh(2).layer.data(167);--<=p_in_rxcdrreset;
i_hdd1layer_dbgcs.trig0(41 downto 26)<=i_hdd_dbgcs.sh(2).layer.trig0(41 downto 26);--llayer

end generate gen_hdd3;
end generate gen_sh_dbgcs;


gen_raid_dbgcs : if strcmp(C_PCFG_HDD_RAID_DBGCS,"ON") generate
--//### DGB HDD_RAID: ########
m_dbgcs_icon : dbgcs_iconx1
port map(
CONTROL0 => i_dbgcs_hdd_raid
);

m_dbgcs_sh0_raid : dbgcs_sata_raid
port map(
CONTROL => i_dbgcs_hdd_raid,
CLK     => i_hdd_dbgcs.raid.clk,
DATA    => i_hddraid_dbgcs.data(172 downto 0),
TRIG0   => i_hddraid_dbgcs.trig0(41 downto 0)
);

--//-------- TRIG: ------------------
i_hddraid_dbgcs.trig0(11 downto 0)<=i_hdd_dbgcs.raid.trig0(11 downto 0);
i_hddraid_dbgcs.trig0(12)<=AND_reduce(tst_sh_txbuf_empty);
i_hddraid_dbgcs.trig0(13)<=tst_sh_txbuf_empty_err;
i_hddraid_dbgcs.trig0(14)<='0';
i_hddraid_dbgcs.trig0(15)<=i_hdd_dbgcs.raid.trig0(15);
i_hddraid_dbgcs.trig0(16)<=i_hdd_txbuf_pfull;
i_hddraid_dbgcs.trig0(17)<='0';
i_hddraid_dbgcs.trig0(18)<=i_hdd_dbgcs.raid.trig0(18);
i_hddraid_dbgcs.trig0(19)<=i_hdd_txbuf_full;

--//SH0
i_hddraid_dbgcs.trig0(24 downto 20)<=i_hdd_dbgcs.sh(0).layer.trig0(34 downto 30);--llayer
i_hddraid_dbgcs.trig0(29 downto 25)<=i_hdd_dbgcs.sh(0).layer.trig0(39 downto 35);--tlayer
--//SH1
gen_hdd1 : if C_PCFG_HDD_COUNT=1 generate
i_hddraid_dbgcs.trig0(34 downto 30)<=i_hdd_dbgcs.sh(0).layer.trig0(34 downto 30);--llayer
i_hddraid_dbgcs.trig0(39 downto 35)<=i_hdd_dbgcs.sh(0).layer.trig0(39 downto 35);--tlayer
end generate gen_hdd1;
gen_hdd2 : if C_PCFG_HDD_COUNT>1 generate
i_hddraid_dbgcs.trig0(34 downto 30)<=i_hdd_dbgcs.sh(1).layer.trig0(34 downto 30);--llayer
i_hddraid_dbgcs.trig0(39 downto 35)<=i_hdd_dbgcs.sh(1).layer.trig0(39 downto 35);--tlayer
end generate gen_hdd2;

i_hddraid_dbgcs.trig0(40)<='0';
i_hddraid_dbgcs.trig0(41)<=i_hdd_dbgcs.sh(0).layer.data(99) or
                           i_hdd_dbgcs.sh(1).layer.data(99) or
                           i_hdd_dbgcs.sh(2).layer.data(99) or
                           i_hdd_dbgcs.sh(3).layer.data(99);
                           --<=p_in_dbg.llayer.txbuf_status.pfull;


--//-------- VIEW: ------------------
i_hddraid_dbgcs.data(28 downto 0)<=i_hdd_dbgcs.raid.data(28 downto 0);
i_hddraid_dbgcs.data(29)<='0';

--//SH0
i_hddraid_dbgcs.data(34 downto 30)<=i_hdd_dbgcs.sh(0).layer.trig0(34 downto 30);--llayer
i_hddraid_dbgcs.data(39 downto 35)<=i_hdd_dbgcs.sh(0).layer.trig0(39 downto 35);--tlayer
i_hddraid_dbgcs.data(45 downto 40)<=i_hdd_dbgcs.sh(0).layer.data(55 downto 50);
i_hddraid_dbgcs.data(55 downto 46)<=(others=>'0');--i_hdd_dbgcs.sh(0).layer.data(65 downto 56);
i_hddraid_dbgcs.data(56)          <='0';--i_hdd_dbgcs.sh(0).layer.data(49);--p_in_ll_rxd_wr; --llayer->tlayer
i_hddraid_dbgcs.data(57)          <='0';--i_hdd_dbgcs.sh(0).layer.data(116);--p_in_ll_txd_rd; --llayer<-tlayer
i_hddraid_dbgcs.data(58)          <='0';--i_hdd_dbgcs.sh(0).layer.data(118);--<=p_in_dbg.llayer.txbuf_status.aempty;
i_hddraid_dbgcs.data(59)          <=i_hdd_dbgcs.sh(0).layer.data(119);--<=p_in_dbg.llayer.txbuf_status.empty;
i_hddraid_dbgcs.data(60)          <='0';--i_hdd_dbgcs.sh(0).layer.data(98);--<=p_in_dbg.llayer.rxbuf_status.pfull;
i_hddraid_dbgcs.data(61)          <=i_hdd_dbgcs.sh(0).layer.data(99);--<=p_in_dbg.llayer.txbuf_status.pfull;
i_hddraid_dbgcs.data(62)          <='0';--i_hdd_dbgcs.sh(0).layer.data(117);--<=p_in_dbg.llayer.txd_close;

--//SH1
gen_hdd11 : if C_PCFG_HDD_COUNT=1 generate
i_hddraid_dbgcs.data(67 downto 63)<=i_hdd_dbgcs.sh(0).layer.trig0(34 downto 30);--llayer
i_hddraid_dbgcs.data(72 downto 68)<=i_hdd_dbgcs.sh(0).layer.trig0(39 downto 35);--tlayer
i_hddraid_dbgcs.data(78 downto 73)<=i_hdd_dbgcs.sh(0).layer.data(55 downto 50);
i_hddraid_dbgcs.data(88 downto 79)<=(others=>'0');--i_hdd_dbgcs.sh(0).layer.data(65 downto 56);
i_hddraid_dbgcs.data(89)          <='0';--i_hdd_dbgcs.sh(0).layer.data(49);--p_in_ll_rxd_wr; --llayer->tlayer
i_hddraid_dbgcs.data(90)          <='0';--i_hdd_dbgcs.sh(0).layer.data(116);--p_in_ll_txd_rd; --llayer<-tlayer
i_hddraid_dbgcs.data(91)          <='0';--i_hdd_dbgcs.sh(0).layer.data(118);--<=p_in_dbg.llayer.txbuf_status.aempty;
i_hddraid_dbgcs.data(92)          <=i_hdd_dbgcs.sh(0).layer.data(119);--<=p_in_dbg.llayer.txbuf_status.empty;
i_hddraid_dbgcs.data(93)          <='0';--i_hdd_dbgcs.sh(0).layer.data(98);--<=p_in_dbg.llayer.rxbuf_status.pfull;
i_hddraid_dbgcs.data(94)          <=i_hdd_dbgcs.sh(0).layer.data(99);--<=p_in_dbg.llayer.txbuf_status.pfull;
i_hddraid_dbgcs.data(95)          <='0';--i_hdd_dbgcs.sh(0).layer.data(117);--<=p_in_dbg.llayer.txd_close;
end generate gen_hdd11;
gen_hdd21 : if C_PCFG_HDD_COUNT>1 generate
i_hddraid_dbgcs.data(67 downto 63)<=i_hdd_dbgcs.sh(1).layer.trig0(34 downto 30);--llayer
i_hddraid_dbgcs.data(72 downto 68)<=i_hdd_dbgcs.sh(1).layer.trig0(39 downto 35);--tlayer
i_hddraid_dbgcs.data(78 downto 73)<=i_hdd_dbgcs.sh(1).layer.data(55 downto 50);
i_hddraid_dbgcs.data(88 downto 79)<=(others=>'0');--i_hdd_dbgcs.sh(1).layer.data(65 downto 56);
i_hddraid_dbgcs.data(89)          <='0';--i_hdd_dbgcs.sh(1).layer.data(49);--p_in_ll_rxd_wr; --llayer->tlayer
i_hddraid_dbgcs.data(90)          <='0';--i_hdd_dbgcs.sh(1).layer.data(116);--p_in_ll_txd_rd; --llayer<-tlayer
i_hddraid_dbgcs.data(91)          <='0';--i_hdd_dbgcs.sh(1).layer.data(118);--<=p_in_dbg.llayer.txbuf_status.aempty;
i_hddraid_dbgcs.data(92)          <=i_hdd_dbgcs.sh(1).layer.data(119);--<=p_in_dbg.llayer.txbuf_status.empty;
i_hddraid_dbgcs.data(93)          <='0';--i_hdd_dbgcs.sh(1).layer.data(98);--<=p_in_dbg.llayer.rxbuf_status.pfull;
i_hddraid_dbgcs.data(94)          <=i_hdd_dbgcs.sh(1).layer.data(99);--<=p_in_dbg.llayer.txbuf_status.pfull;
i_hddraid_dbgcs.data(95)          <='0';--i_hdd_dbgcs.sh(1).layer.data(117);--<=p_in_dbg.llayer.txd_close;
end generate gen_hdd21;

--//
i_hddraid_dbgcs.data(96) <='0';--
i_hddraid_dbgcs.data(97) <='0';--
i_hddraid_dbgcs.data(98) <='0';--

i_hddraid_dbgcs.data(99) <='0';--
i_hddraid_dbgcs.data(100)<='0';--
i_hddraid_dbgcs.data(101)<='0';--

i_hddraid_dbgcs.data(102)<=i_hdd_txbuf_pfull;
i_hddraid_dbgcs.data(103)<=i_hdd_txbuf_full;
i_hddraid_dbgcs.data(104)<=i_hdd_txbuf_empty;

i_hddraid_dbgcs.data(105)<=i_hdd_rxbuf_empty;

i_hddraid_dbgcs.data(106)<='0';
i_hddraid_dbgcs.data(107)<='0';
i_hddraid_dbgcs.data(108)<='0';

--//SH2
i_hddraid_dbgcs.data(113 downto 109)<=i_hdd_dbgcs.sh(2).layer.trig0(34 downto 30);--llayer
i_hddraid_dbgcs.data(118 downto 114)<=i_hdd_dbgcs.sh(2).layer.trig0(39 downto 35);--tlayer
i_hddraid_dbgcs.data(124 downto 119)<=i_hdd_dbgcs.sh(2).layer.data(55 downto 50);--(65 downto 50);
i_hddraid_dbgcs.data(125)           <='0';          --i_hdd_dbgcs.sh(2).layer.data(49);--p_in_ll_rxd_wr; --llayer->tlayer
i_hddraid_dbgcs.data(126)           <='0';          --i_hdd_dbgcs.sh(2).layer.data(116);--p_in_ll_txd_rd; --llayer<-tlayer
i_hddraid_dbgcs.data(127)           <='0';          --i_hdd_dbgcs.sh(2).layer.data(118);--<=p_in_dbg.llayer.txbuf_status.aempty;
i_hddraid_dbgcs.data(128)           <=i_hdd_dbgcs.sh(2).layer.data(119);--<=p_in_dbg.llayer.txbuf_status.empty;
i_hddraid_dbgcs.data(129)           <='0';          --i_hdd_dbgcs.sh(2).layer.data(98);--<=p_in_dbg.llayer.rxbuf_status.pfull;
i_hddraid_dbgcs.data(130)           <=i_hdd_dbgcs.sh(2).layer.data(99);--<=p_in_dbg.llayer.txbuf_status.pfull;
i_hddraid_dbgcs.data(131)           <='0';          --i_hdd_dbgcs.sh(2).layer.data(117);--<=p_in_dbg.llayer.txd_close;

--//SH3
i_hddraid_dbgcs.data(136 downto 132)<=i_hdd_dbgcs.sh(3).layer.trig0(34 downto 30);--llayer
i_hddraid_dbgcs.data(137)           <='0';
i_hddraid_dbgcs.data(142 downto 138)<=i_hdd_dbgcs.sh(3).layer.trig0(39 downto 35);--tlayer
i_hddraid_dbgcs.data(148 downto 143)<=i_hdd_dbgcs.sh(3).layer.data(55 downto 50);--(65 downto 50);
i_hddraid_dbgcs.data(149)           <='0';          --i_hdd_dbgcs.sh(3).layer.data(49);--p_in_ll_rxd_wr; --llayer->tlayer
i_hddraid_dbgcs.data(150)           <='0';          --i_hdd_dbgcs.sh(3).layer.data(116);--p_in_ll_txd_rd; --llayer<-tlayer
i_hddraid_dbgcs.data(151)           <='0';          --i_hdd_dbgcs.sh(3).layer.data(118);--<=p_in_dbg.llayer.txbuf_status.aempty;
i_hddraid_dbgcs.data(152)           <=i_hdd_dbgcs.sh(3).layer.data(119);--<=p_in_dbg.llayer.txbuf_status.empty;
i_hddraid_dbgcs.data(153)           <='0';          --i_hdd_dbgcs.sh(3).layer.data(98);--<=p_in_dbg.llayer.rxbuf_status.pfull;
i_hddraid_dbgcs.data(154)           <=i_hdd_dbgcs.sh(3).layer.data(99);--<=p_in_dbg.llayer.txbuf_status.pfull;
i_hddraid_dbgcs.data(155)           <='0';          --i_hdd_dbgcs.sh(3).layer.data(117);--<=p_in_dbg.llayer.txd_close;

i_hddraid_dbgcs.data(156)<='0';--cmd for wr
i_hddraid_dbgcs.data(157)<='0';
i_hddraid_dbgcs.data(158)<='0';
i_hddraid_dbgcs.data(159)<='0';
i_hddraid_dbgcs.data(160)<='0';
i_hddraid_dbgcs.data(161)<='0';--cmd for rd
i_hddraid_dbgcs.data(162)<='0';
i_hddraid_dbgcs.data(163)<='0';
i_hddraid_dbgcs.data(164)<='0';
i_hddraid_dbgcs.data(165)<='0';

i_hddraid_dbgcs.data(168 downto 166)<=(others=>'0');
i_hddraid_dbgcs.data(171 downto 169)<=(others=>'0');
i_hddraid_dbgcs.data(172)<='0';



tst_sh_txbuf_empty(0)<=i_hdd_dbgcs.sh(1).layer.data(119);
tst_sh_txbuf_empty(1)<=i_hdd_dbgcs.sh(2).layer.data(119);
tst_sh_txbuf_empty(2)<=i_hdd_dbgcs.sh(3).layer.data(119);

tst_sh_txbuf_empty_err<='1' when tst_sh_txbuf_empty/=(tst_sh_txbuf_empty'range =>'0') and
                                 tst_sh_txbuf_empty/=(tst_sh_txbuf_empty'range =>'1') else '0';

end generate gen_raid_dbgcs;

end generate gen_dbgcs;




end architecture;

