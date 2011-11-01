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

---- synopsys translate_off
--library unisim;
--use unisim.vcomponents.all;
---- synopsys translate_on
Library UNISIM;
use UNISIM.vcomponents.all;

library work;
use work.vicg_common_pkg.all;
use work.prj_cfg.all;
use work.prj_def.all;
use work.cfgdev_pkg.all;
use work.sata_glob_pkg.all;
use work.dsn_hdd_pkg.all;

entity hdd_test_main is
generic
(
G_IF  : string:="UART";
G_SIM : string:="OFF"
);
port
(
--------------------------------------------------
--Светодиоды (Для платы ML505)
--------------------------------------------------
pin_out_led           : out   std_logic_vector(7 downto 0);
pin_out_led_C         : out   std_logic;
pin_out_led_E         : out   std_logic;
pin_out_led_N         : out   std_logic;
pin_out_led_S         : out   std_logic;
pin_out_led_W         : out   std_logic;

pin_out_TP            : out   std_logic_vector(7 downto 0);

pin_in_btn_C          : in    std_logic;
pin_in_btn_E          : in    std_logic;
pin_in_btn_N          : in    std_logic;
pin_in_btn_S          : in    std_logic;
pin_in_btn_W          : in    std_logic;

pin_out_uart0_tx      : out   std_logic;
pin_in_uart0_rx       : in    std_logic;

pin_inout_ftdi_d      : inout  std_logic_vector(7 downto 0);
pin_out_ftdi_rd_n     : out    std_logic;
pin_out_ftdi_wr_n     : out    std_logic;
pin_in_ftdi_txe_n     : in     std_logic;
pin_in_ftdi_rxf_n     : in     std_logic;
pin_in_ftdi_pwren_n   : in     std_logic;

--------------------------------------------------
--SATA
--------------------------------------------------
pin_out_sata_txn      : out   std_logic_vector((C_SH_GTCH_COUNT_MAX*C_SH_COUNT_MAX(C_HDD_COUNT-1))-1 downto 0);
pin_out_sata_txp      : out   std_logic_vector((C_SH_GTCH_COUNT_MAX*C_SH_COUNT_MAX(C_HDD_COUNT-1))-1 downto 0);
pin_in_sata_rxn       : in    std_logic_vector((C_SH_GTCH_COUNT_MAX*C_SH_COUNT_MAX(C_HDD_COUNT-1))-1 downto 0);
pin_in_sata_rxp       : in    std_logic_vector((C_SH_GTCH_COUNT_MAX*C_SH_COUNT_MAX(C_HDD_COUNT-1))-1 downto 0);
pin_in_sata_clk_n     : in    std_logic_vector(C_SH_COUNT_MAX(C_HDD_COUNT-1)-1 downto 0);
pin_in_sata_clk_p     : in    std_logic_vector(C_SH_COUNT_MAX(C_HDD_COUNT-1)-1 downto 0);

--------------------------------------------------
-- Reset
--------------------------------------------------
pin_in_rst            : in    std_logic;

--------------------------------------------------
-- Reference clock
--------------------------------------------------
pin_in_refclk_n       : in    std_logic;
pin_in_refclk_p       : in    std_logic
);
end entity;

architecture struct of hdd_test_main is

--component ROC generic (WIDTH : Time := 500 ns); port (O : out std_ulogic := '1'); end component;
component IBUFDS            port(I : in  std_logic; IB : in  std_logic; O  : out std_logic);end component;
component IBUFGDS_LVPECL_25 port(I : in  std_logic; IB : in  std_logic; O  : out std_logic);end component;
component BUFG              port(I : in  std_logic; O  : out std_logic);end component;

--component dbgcs_iconx1
--  PORT (
--    CONTROL0 : INOUT STD_LOGIC_VECTOR(35 DOWNTO 0));
----    CONTROL1 : INOUT STD_LOGIC_VECTOR(35 DOWNTO 0));
--
--end component;

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

component hdd_ram_hfifo
port
(
din         : in std_logic_vector(31 downto 0);
wr_en       : in std_logic;
wr_clk      : in std_logic;

dout        : out std_logic_vector(31 downto 0);
rd_en       : in std_logic;
rd_clk      : in std_logic;

full        : out std_logic;
almost_full : out std_logic;
empty       : out std_logic;

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
port
(
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

component lbus_dcm
generic(
G_CLKFX_DIV  : integer:=1;
G_CLKFX_MULT : integer:=2
);
port(
p_out_gclkin : out   std_logic;
p_out_clk0   : out   std_logic;
p_out_clkfx  : out   std_logic;
--p_out_clkdiv : out   std_logic;
--p_out_clk2x  : out   std_logic;
p_out_locked : out   std_logic;

p_in_clk     : in    std_logic;
p_in_rst     : in    std_logic
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

signal i_usr_rst                        : std_logic;
signal rst_sys_n                        : std_logic;
--signal rst_sys                          : std_logic;

signal i_dcm_rst_cnt                    : std_logic_vector(5 downto 0);
signal i_dcm_rst                        : std_logic;

signal g_uart_refclk                    : std_logic;
signal i_refclk                         : std_logic;
signal g_host_clk                       : std_logic;

signal i_hdd_module_rst                 : std_logic;
signal i_hdd_gt_refclk150               : std_logic_vector(C_SH_COUNT_MAX(C_HDD_COUNT-1)-1 downto 0);
signal g_hdd_gt_refclkout               : std_logic;
signal i_hdd_gt_plldet                  : std_logic;
signal i_hdd_dcm_lock                   : std_logic;

signal i_hdd_rbuf_cfg                   : THDDRBufCfg;
signal i_hdd_rbuf_status                : THDDRBufStatus;

signal i_hdd_txdata                     : std_logic_vector(31 downto 0);
signal i_hdd_txdata_wd                  : std_logic;
signal i_hdd_txbuf_full                 : std_logic;
signal i_hdd_txbuf_pfull                : std_logic;
signal i_hdd_txbuf_empty                : std_logic;

signal i_hdd_rxdata                     : std_logic_vector(31 downto 0);
signal i_hdd_rxdata_rd                  : std_logic;
signal i_hdd_rxbuf_empty                : std_logic;
signal i_hdd_rxbuf_pempty               : std_logic;

signal i_dev_adr                        : std_logic_vector(C_CFGPKT_DADR_M_BIT-C_CFGPKT_DADR_L_BIT downto 0);
signal i_cfg_adr                        : std_logic_vector(C_CFGPKT_RADR_M_BIT-C_CFGPKT_RADR_L_BIT downto 0);
signal i_cfg_adr_ld                     : std_logic;
signal i_cfg_adr_fifo                   : std_logic;
signal i_cfg_wd                         : std_logic;
signal i_cfg_rd                         : std_logic;
signal i_cfg_txdata                     : std_logic_vector(15 downto 0);
signal i_cfg_rxdata                     : std_logic_vector(15 downto 0);
signal i_cfg_txrdy                      : std_logic;
signal i_cfg_rxrdy                      : std_logic;
signal i_cfg_done                       : std_logic;
signal i_cfg_buf_rst                    : std_logic;
signal i_cfg_tstout                     : std_logic_vector(31 downto 0);
signal i_cfghdd_rxdata                  : std_logic_vector(i_cfg_rxdata'range);
signal i_cfgt_rxdata                    : std_logic_vector(i_cfg_rxdata'range);
signal i_ram_txbuf_full                 : std_logic;
signal i_ram_txbuf_afull                : std_logic;
signal i_ram_txbuf_empty                : std_logic;
signal i_ram_rxbuf_full                 : std_logic;
signal i_ram_rxbuf_afull                : std_logic;
signal i_ram_rxbuf_empty                : std_logic;

signal i_hdd_module_rdy                 : std_logic;
signal i_hdd_module_error               : std_logic;
signal i_hdd_busy                       : std_logic;
signal i_hdd_hirq                       : std_logic;
signal i_hdd_done                       : std_logic;

signal i_hdd_dbgcs                      : TSH_dbgcs_exp;
--signal i_hddrambuf_dbgcs                : TSH_ila;
--signal i_hdd_rambuf_dbgcs               : TSH_ila;

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

signal i_hdd_dbgled                     : THDDLed_SHCountMax;

signal i_hdd_tst_in                     : std_logic_vector(31 downto 0);
signal i_hdd_tst_out                    : std_logic_vector(31 downto 0);

signal i_test01_led                     : std_logic;
signal i_test02_led                     : std_logic;

signal i_cfg_adr_cnt                    : std_logic_vector(7 downto 0);
signal i_reg0                           : std_logic_vector(i_cfg_rxdata'range);
signal i_reg1                           : std_logic_vector(i_cfg_rxdata'range);
signal i_reg2                           : std_logic_vector(i_cfg_rxdata'range);
signal i_reg3                           : std_logic_vector(i_cfg_rxdata'range);
signal i_reg4                           : std_logic_vector(i_cfg_rxdata'range);

--signal tst_ram_rxbuf_rdcnt              : std_logic_vector(i_cfg_rxdata'range);



--//MAIN
begin



--***********************************************************
--//RESET модулей
--***********************************************************
rst_sys_n <= pin_in_rst;
i_hdd_module_rst <=not rst_sys_n or i_usr_rst;--
i_cfg_buf_rst<=not rst_sys_n or i_usr_rst or i_hdd_rbuf_cfg.dmacfg.clr_err;

process(rst_sys_n, g_host_clk)
begin
  if rst_sys_n = '0' then
    i_dcm_rst_cnt <= (others => '0');
  elsif g_host_clk'event and g_host_clk = '1' then
    if i_dcm_rst_cnt(i_dcm_rst_cnt'high) = '0' then
      i_dcm_rst_cnt <= i_dcm_rst_cnt + 1;
    end if;
  end if;
end process;

i_dcm_rst <= i_dcm_rst_cnt(i_dcm_rst_cnt'high - 1);


--***********************************************************
--          Установка частот проекта:
--***********************************************************
--//Input reference clock for IDELAY / ODELAY elements
ibufg_refclk : IBUFGDS_LVPECL_25 port map(I  => pin_in_refclk_p, IB => pin_in_refclk_n, O => i_refclk);
bufg_refclk  : BUFG              port map(I  => i_refclk, O  => g_host_clk);

--//Input 150MHz reference clock for SATA
gen_sata_gt : for i in 0 to C_SH_COUNT_MAX(C_HDD_COUNT-1)-1 generate
ibufds_hdd_gt_refclk : IBUFDS port map(I  => pin_in_sata_clk_p(i), IB => pin_in_sata_clk_n(i), O => i_hdd_gt_refclk150(i));
end generate gen_sata_gt;


--***********************************************************
--Модуль конфигурирования устр-в
--***********************************************************
gen_fdi : if strcmp(G_IF,"FTDI") generate

pin_out_uart0_tx <= pin_in_uart0_rx;

m_cfgdev : cfgdev_ftdi
port map
(
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
p_out_cfg_txdata     => i_cfg_txdata,
p_in_cfg_rxdata      => i_cfg_rxdata,
p_in_cfg_txrdy       => i_cfg_txrdy,
p_in_cfg_rxrdy       => i_cfg_rxrdy,

p_out_cfg_done       => i_cfg_done,
p_in_cfg_clk         => g_host_clk,

-------------------------------
--Технологический
-------------------------------
p_in_tst             => "00000000000000000000000000000000",
p_out_tst            => i_cfg_tstout,

-------------------------------
--System
-------------------------------
p_in_rst => i_dcm_rst
);
end generate gen_fdi;

gen_uart : if strcmp(G_IF,"UART") generate

pin_inout_ftdi_d<=pin_in_ftdi_rxf_n &
                 pin_in_ftdi_pwren_n & "000000" when pin_in_ftdi_txe_n='1' else (others=> 'Z');

pin_out_ftdi_rd_n<=OR_reduce(pin_inout_ftdi_d(3 downto 0));
pin_out_ftdi_wr_n<=OR_reduce(pin_inout_ftdi_d(7 downto 4));


m_cfgdev : cfgdev_uart
generic map(
G_BAUDCNT_VAL => 81       --//G_BAUDCNT_VAL = Fuart_refclk/(16 * UART_BAUDRATE)
                           --//Например: Fuart_refclk=40MHz, UART_BAUDRATE=115200
                           --//
                           --// 40000000/(16 *115200)=21,701 - округляем до ближайшего цеого, т.е = 22
)
port map
(
-------------------------------
--Связь с UART
-------------------------------
p_out_uart_tx        => pin_out_uart0_tx,
p_in_uart_rx         => pin_in_uart0_rx,
p_in_uart_refclk     => g_uart_refclk,

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
p_out_cfg_txdata     => i_cfg_txdata,
p_in_cfg_rxdata      => i_cfg_rxdata,
p_in_cfg_txrdy       => i_cfg_txrdy,
p_in_cfg_rxrdy       => i_cfg_rxrdy,

p_out_cfg_done       => i_cfg_done,
p_in_cfg_clk         => g_host_clk,

-------------------------------
--Технологический
-------------------------------
p_in_tst             => "00000000000000000000000000000000",
p_out_tst            => i_cfg_tstout,

-------------------------------
--System
-------------------------------
p_in_rst => i_dcm_rst
);
end generate gen_uart;

i_cfg_rxdata<=i_cfghdd_rxdata  when i_dev_adr(3 downto 0)=CONV_STD_LOGIC_VECTOR(C_CFGDEV_HDD, 4) else
              i_cfgt_rxdata;


--***********************************************************
--Проект Накопителя - dsn_hdd.vhd
--***********************************************************
m_hdd : dsn_hdd
generic map
(
G_MODULE_USE=> C_USE_HDD,
G_HDD_COUNT => C_HDD_COUNT,
G_GT_DBUS   => C_HDD_GT_DBUS,
G_DBG       => C_DBG_HDD,
G_DBGCS     => C_DBGCS_HDD,
G_SIM       => G_SIM
)
port map
(
-------------------------------
-- Конфигурирование модуля dsn_hdd.vhd (p_in_cfg_clk domain)
-------------------------------
p_in_cfg_if           => C_HDD_CFGIF_UART,
p_in_cfg_clk          => g_host_clk,

p_in_cfg_adr          => i_cfg_adr(7 downto 0),
p_in_cfg_adr_ld       => i_cfg_adr_ld,
p_in_cfg_adr_fifo     => i_cfg_adr_fifo,

p_in_cfg_txdata       => i_cfg_txdata,
p_in_cfg_wd           => i_cfg_wd,
p_out_cfg_txrdy       => i_cfg_txrdy,

p_out_cfg_rxdata      => i_cfghdd_rxdata,
p_in_cfg_rd           => i_cfg_rd,
p_out_cfg_rxrdy       => i_cfg_rxrdy,

p_in_cfg_done         => i_cfg_done,
p_in_cfg_rst          => i_dcm_rst,

-------------------------------
-- STATUS модуля dsn_hdd.vhd
-------------------------------
p_out_hdd_rdy         => i_hdd_module_rdy,
p_out_hdd_error       => i_hdd_module_error,
p_out_hdd_busy        => i_hdd_busy,
p_out_hdd_irq         => i_hdd_hirq,
p_out_hdd_done        => i_hdd_done,

-------------------------------
-- Связь с Источниками/Приемниками данных накопителя
-------------------------------
p_out_rbuf_cfg        => i_hdd_rbuf_cfg,
p_in_rbuf_status      => i_hdd_rbuf_status,

p_in_hdd_txd          => i_hdd_txdata,
p_in_hdd_txd_wr       => i_hdd_txdata_wd,
p_out_hdd_txbuf_pfull => i_hdd_txbuf_pfull,
p_out_hdd_txbuf_full  => i_hdd_txbuf_full,
p_out_hdd_txbuf_empty => i_hdd_txbuf_empty,

p_out_hdd_rxd         => i_hdd_rxdata,
p_in_hdd_rxd_rd       => i_hdd_rxdata_rd,
p_out_hdd_rxbuf_empty => i_hdd_rxbuf_empty,
p_out_hdd_rxbuf_pempty=> i_hdd_rxbuf_pempty,

--------------------------------------------------
--Sata Driver
--------------------------------------------------
p_out_sata_txn        => pin_out_sata_txn,
p_out_sata_txp        => pin_out_sata_txp,
p_in_sata_rxn         => pin_in_sata_rxn,
p_in_sata_rxp         => pin_in_sata_rxp,

p_in_sata_refclk      => i_hdd_gt_refclk150,
p_out_sata_refclkout  => g_uart_refclk,
p_out_sata_gt_plldet  => i_hdd_gt_plldet,
p_out_sata_dcm_lock   => i_hdd_dcm_lock,

---------------------------------------------------------------------------
--Технологический порт
---------------------------------------------------------------------------
p_in_tst              => i_hdd_tst_in,
p_out_tst             => i_hdd_tst_out,

--------------------------------------------------
--//Debug/Sim
--------------------------------------------------
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

--------------------------------------------------
--System
--------------------------------------------------
p_in_clk           => g_host_clk,
p_in_rst           => i_hdd_module_rst
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
i_hdd_rbuf_status.err_type.vinbuf_full<='0';
i_hdd_rbuf_status.err_type.rambuf_full<='0';
i_hdd_rbuf_status.done <='0';
i_hdd_rbuf_status.hwlog_size<=(others=>'0');


--//RAM<-CFG
m_ram_txbuf : hdd_ram_hfifo
port map
(
din         => i_hdd_rbuf_cfg.ram_wr_i.din,
wr_en       => i_hdd_rbuf_cfg.ram_wr_i.wr,
wr_clk      => i_hdd_rbuf_cfg.ram_wr_i.clk,

dout        => i_hdd_txdata,
rd_en       => i_hdd_txdata_wd,
rd_clk      => g_host_clk,

full        => i_ram_txbuf_full,
almost_full => i_ram_txbuf_afull,
empty       => i_ram_txbuf_empty,

--clk         => p_in_clk,
rst         => i_cfg_buf_rst
);

i_hdd_txdata_wd<= not i_ram_txbuf_empty and not i_hdd_txbuf_pfull;
i_hdd_rbuf_status.ram_wr_o.wr_rdy<= not i_ram_txbuf_afull;

--//RAM->CFG
m_ram_rxbuf : hdd_ram_hfifo
port map
(
din         => i_hdd_rxdata,
wr_en       => i_hdd_rxdata_rd,
wr_clk      => g_host_clk,

dout        => i_hdd_rbuf_status.ram_wr_o.dout,
rd_en       => i_hdd_rbuf_cfg.ram_wr_i.rd,
rd_clk      => i_hdd_rbuf_cfg.ram_wr_i.clk,

full        => i_ram_rxbuf_full,
almost_full => i_ram_rxbuf_afull,
empty       => i_ram_rxbuf_empty,

--clk         => p_in_clk,
rst         => i_cfg_buf_rst
);

i_hdd_rxdata_rd<= not i_hdd_rxbuf_empty and not i_ram_rxbuf_afull;
i_hdd_rbuf_status.ram_wr_o.rd_rdy<= not i_ram_rxbuf_empty;



--//----------------------------------
--//Технологические сигналы
--//----------------------------------
i_usr_rst<=pin_in_btn_N;
i_hdd_tst_in(0)<=pin_in_btn_W;
i_hdd_tst_in(31 downto 1)<=(others=>'0');

--//J5 /pin2
pin_out_TP(0)<=pin_in_btn_C or pin_in_btn_E or
               pin_in_btn_S;-- or OR_reduce(i_cfg_tstout);-- or OR_reduce(i_hdd_tst_out) or
--//J6
pin_out_TP(1)<=i_test01_led;
pin_out_TP(2)<=i_test02_led;
pin_out_TP(3)<='0';
pin_out_TP(4)<='0';
pin_out_TP(5)<='0';
pin_out_TP(6)<='0';
pin_out_TP(7)<='0';


--Светодиоды
pin_out_led_E<=i_test01_led;
pin_out_led_N<=i_hdd_busy or i_hdd_module_rst;
pin_out_led_S<=i_test02_led;
pin_out_led_W<=i_hdd_dbgled(0).spd(1) when pin_in_btn_W='0' else i_hdd_dbgled(1).spd(1);
pin_out_led_C<=i_hdd_dbgled(0).spd(0) when pin_in_btn_W='0' else i_hdd_dbgled(1).spd(0);

pin_out_led(0)<=i_hdd_dbgled(1).busy;--i_hdd_dcm_lock; --
pin_out_led(1)<=i_hdd_dbgled(1).err; --i_hdd_gt_plldet;--
pin_out_led(2)<=i_hdd_dbgled(1).rdy; --i_test01_led;   --
pin_out_led(3)<=i_hdd_dbgled(1).link;--i_test02_led;   --

pin_out_led(4)<=i_hdd_dbgled(0).busy;
pin_out_led(5)<=i_hdd_dbgled(0).err;
pin_out_led(6)<=i_hdd_dbgled(0).rdy;
pin_out_led(7)<=i_hdd_dbgled(0).link;



m_test01: fpga_test_01
generic map(
G_BLINK_T05   =>10#250#, -- 1/2 периода мигания светодиода.(время в ms)
G_CLK_T05us   =>10#75#   -- 05us - 150MHz
)
port map
(
p_out_test_led => i_test01_led,
p_out_test_done=> open,

p_out_1us      => open,
p_out_1ms      => open,
-------------------------------
--System
-------------------------------
p_in_clk       => g_uart_refclk,
p_in_rst       => i_hdd_module_rst
);

m_test02: fpga_test_01
generic map(
G_BLINK_T05   =>10#250#, -- 1/2 периода мигания светодиода.(время в ms)
G_CLK_T05us   =>10#75#   -- 05us - 150MHz
)
port map
(
p_out_test_led => i_test02_led,
p_out_test_done=> open,

p_out_1us      => open,
p_out_1ms      => open,
-------------------------------
--System
-------------------------------
p_in_clk       => g_host_clk,
p_in_rst       => i_hdd_module_rst
);



gen_dbgcs : if strcmp(C_DBGCS_HDD,"ON") generate

m_dbgcs_icon : dbgcs_iconx2
port map(
CONTROL0 => i_dbgcs_hdd_raid,
CONTROL1 => i_dbgcs_cfg
);

--m_dbgcs_icon : dbgcs_iconx3
--port map(
--CONTROL0 => i_dbgcs_sh0_spd,
--CONTROL1 => i_dbgcs_hdd0_layer,
--CONTROL2 => i_dbgcs_hdd1_layer
--);


----//### HDD0_SPD: ########
--m_dbgcs_sh0_spd : dbgcs_sata_layer
--port map
--(
--CONTROL => i_dbgcs_sh0_spd,
--CLK     => i_hdd_dbgcs.sh(0).spd.clk,
--DATA    => i_hdd_dbgcs.sh(0).spd.data(122 downto 0),
--TRIG0   => i_hdd_dbgcs.sh(0).spd.trig0(41 downto 0)
--);

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


--//### HDD_RAID: ########
m_dbgcs_sh0_raid : dbgcs_sata_raid
port map
(
CONTROL => i_dbgcs_hdd_raid,
CLK     => i_hdd_dbgcs.raid.clk,
DATA    => i_hddraid_dbgcs.data(172 downto 0),--(122 downto 0),
TRIG0   => i_hddraid_dbgcs.trig0(41 downto 0)
);

--//-------- TRIG: ------------------
i_hddraid_dbgcs.trig0(18 downto 0)<=i_hdd_dbgcs.raid.trig0(18 downto 0);
i_hddraid_dbgcs.trig0(19)<='0';--tst_trm_timeout(10);--

--//SH0
i_hddraid_dbgcs.trig0(24 downto 20)<=i_hdd_dbgcs.sh(0).layer.trig0(34 downto 30);--llayer
i_hddraid_dbgcs.trig0(29 downto 25)<=i_hdd_dbgcs.sh(0).layer.trig0(39 downto 35);--tlayer
--//SH1
i_hddraid_dbgcs.trig0(34 downto 30)<=i_hdd_dbgcs.sh(1).layer.trig0(34 downto 30);--llayer
i_hddraid_dbgcs.trig0(39 downto 35)<=i_hdd_dbgcs.sh(1).layer.trig0(39 downto 35);--tlayer

i_hddraid_dbgcs.trig0(40)<=i_hdd_txbuf_empty;
i_hddraid_dbgcs.trig0(41)<=i_hdd_txbuf_pfull;


--//-------- VIEW: ------------------
i_hddraid_dbgcs.data(28 downto 0)<=i_hdd_dbgcs.raid.data(28 downto 0);
i_hddraid_dbgcs.data(29)<=i_hdd_txbuf_pfull;

--//SH0
i_hddraid_dbgcs.data(34 downto 30)<=i_hdd_dbgcs.sh(0).layer.trig0(34 downto 30);--llayer
i_hddraid_dbgcs.data(39 downto 35)<=i_hdd_dbgcs.sh(0).layer.trig0(39 downto 35);--tlayer
i_hddraid_dbgcs.data(55 downto 40)<=i_hdd_dbgcs.sh(0).layer.data(115 downto 100);--tst_cnt
----i_hddraid_dbgcs.data(55 downto 40)<=i_hdd_dbgcs.sh(0).layer.data(65 downto 50);--p_in_ll_rxd(15 downto 0);--llayer->tlayer
--i_hddraid_dbgcs.data(55 downto 40)<=i_hdd_dbgcs.sh(0).layer.data(97 downto 82);--p_in_ll_txd(15 downto 0);--llayer<-tlayer
i_hddraid_dbgcs.data(56)          <=i_hdd_dbgcs.sh(0).layer.data(49);--p_in_ll_rxd_wr; --llayer->tlayer
i_hddraid_dbgcs.data(57)          <=i_hdd_dbgcs.sh(0).layer.data(116);--p_in_ll_txd_rd; --llayer<-tlayer
i_hddraid_dbgcs.data(58)          <=i_hdd_dbgcs.sh(0).layer.data(118);--<=p_in_dbg.llayer.txbuf_status.aempty; --p_in_gt_txcharisk(0);
i_hddraid_dbgcs.data(59)          <=i_hdd_dbgcs.sh(0).layer.data(119);--<=p_in_dbg.llayer.txbuf_status.empty; --p_in_gt_txcharisk(1);
i_hddraid_dbgcs.data(60)          <=i_hdd_dbgcs.sh(0).layer.data(98);--<=p_in_dbg.llayer.rxbuf_status.pfull; --p_in_gt_rxcharisk(0);
i_hddraid_dbgcs.data(61)          <=i_hdd_dbgcs.sh(0).layer.data(99);--<=p_in_dbg.llayer.txbuf_status.pfull; --p_in_gt_rxcharisk(1);
i_hddraid_dbgcs.data(62)          <=i_hdd_dbgcs.sh(0).layer.data(117);--<=p_in_dbg.llayer.txd_close;

--//SH1
i_hddraid_dbgcs.data(67 downto 63)<=i_hdd_dbgcs.sh(1).layer.trig0(34 downto 30);--llayer
i_hddraid_dbgcs.data(72 downto 68)<=i_hdd_dbgcs.sh(1).layer.trig0(39 downto 35);--tlayer
i_hddraid_dbgcs.data(88 downto 73)<=i_hdd_dbgcs.sh(1).layer.data(115 downto 100);--tst_cnt
----i_hddraid_dbgcs.data(88 downto 73)<=i_hdd_dbgcs.sh(1).layer.data(65 downto 50);--p_in_ll_rxd(15 downto 0);--llayer->tlayer
--i_hddraid_dbgcs.data(88 downto 73)<=i_hdd_dbgcs.sh(1).layer.data(97 downto 82);--p_in_ll_txd(15 downto 0);--llayer<-tlayer
i_hddraid_dbgcs.data(89)          <=i_hdd_dbgcs.sh(1).layer.data(49);--p_in_ll_rxd_wr; --llayer->tlayer
i_hddraid_dbgcs.data(90)          <=i_hdd_dbgcs.sh(1).layer.data(116);--p_in_ll_txd_rd; --llayer<-tlayer
i_hddraid_dbgcs.data(91)          <=i_hdd_dbgcs.sh(1).layer.data(118);--<=p_in_dbg.llayer.txbuf_status.aempty; --p_in_gt_txcharisk(0);
i_hddraid_dbgcs.data(92)          <=i_hdd_dbgcs.sh(1).layer.data(119);--<=p_in_dbg.llayer.txbuf_status.empty; --p_in_gt_txcharisk(1);
i_hddraid_dbgcs.data(93)          <=i_hdd_dbgcs.sh(1).layer.data(98);--<=p_in_dbg.llayer.rxbuf_status.pfull; --p_in_gt_rxcharisk(0);
i_hddraid_dbgcs.data(94)          <=i_hdd_dbgcs.sh(1).layer.data(99);--<=p_in_dbg.llayer.txbuf_status.pfull; --p_in_gt_rxcharisk(1);
i_hddraid_dbgcs.data(95)          <=i_hdd_done;--i_hdd_rambuf_dbgcs.data(3);--i_hdd_dbgcs.sh(1).layer.data(117);--<=p_in_dbg.llayer.txd_close;

--//RAMBUF
i_hddraid_dbgcs.data(103 downto 100)<=(others=>'0');
i_hddraid_dbgcs.data(104)<=i_hdd_txbuf_empty;
i_hddraid_dbgcs.data(105)<=i_hdd_rxbuf_empty;
i_hddraid_dbgcs.data(106)<=i_hdd_txdata_wd;--RAM->HDD
i_hddraid_dbgcs.data(107)<=i_hdd_rxdata_rd;--RAM<-HDD
i_hddraid_dbgcs.data(108)<=i_ram_rxbuf_empty;
i_hddraid_dbgcs.data(140 downto 109)<=i_hdd_txdata(31 downto 0);--RAM->HDD
i_hddraid_dbgcs.data(172 downto 141)<=i_hdd_rxdata(31 downto 0);--RAM<-HDD


--process(i_hdd_rambuf_dbgcs.clk)
--begin
--if i_hdd_rambuf_dbgcs.clk'event and i_hdd_rambuf_dbgcs.clk='1' then
--  tst_sh0_llayer<=i_hdd_dbgcs.sh(0).layer.trig0(34 downto 30);--llayer
--  tst_sh1_llayer<=i_hdd_dbgcs.sh(1).layer.trig0(34 downto 30);--llayer
--
--  if tst_sh0_llayer=CONV_STD_LOGIC_VECTOR(16#0C#, tst_sh0_llayer'length) or
--     tst_sh1_llayer=CONV_STD_LOGIC_VECTOR(16#0C#, tst_sh1_llayer'length) or
--     tst_sh0_llayer=CONV_STD_LOGIC_VECTOR(16#13#, tst_sh0_llayer'length) or
--     tst_sh1_llayer=CONV_STD_LOGIC_VECTOR(16#13#, tst_sh1_llayer'length) then
--    tst_trm_timeout<=tst_trm_timeout + 1;
--  else
--    tst_trm_timeout<=(others=>'0');
--  end if;
--end if;
--end process;


----//### CFG: ########
m_dbgcs_cfg : dbgcs_sata_layer
port map
(
CONTROL => i_dbgcs_cfg,
CLK     => i_cfg_dbgcs.clk,
DATA    => i_cfg_dbgcs.data(122 downto 0),
TRIG0   => i_cfg_dbgcs.trig0(41 downto 0)
);

i_cfg_dbgcs.clk<=g_host_clk;

--//-------- TRIG: ------------------
i_cfg_dbgcs.trig0(0)<=i_cfg_adr_ld;
i_cfg_dbgcs.trig0(1)<=i_cfg_wd;
i_cfg_dbgcs.trig0(2)<=i_cfg_rd;
i_cfg_dbgcs.trig0(3)<=i_cfg_done;
i_cfg_dbgcs.trig0(4)<=i_cfg_txrdy;
i_cfg_dbgcs.trig0(5)<=i_cfg_rxrdy;
i_cfg_dbgcs.trig0(13 downto 6)<=i_cfg_adr(7 downto 0);
i_cfg_dbgcs.trig0(17 downto 14)<=i_cfg_tstout(9 downto 6);
i_cfg_dbgcs.trig0(18)<=i_ram_txbuf_afull;
i_cfg_dbgcs.trig0(19)<=i_ram_txbuf_empty;
i_cfg_dbgcs.trig0(20)<=i_ram_rxbuf_afull;
i_cfg_dbgcs.trig0(21)<=i_ram_rxbuf_empty;
i_cfg_dbgcs.trig0(22)<=i_hdd_txbuf_empty;

--//-------- VIEW: ------------------
i_cfg_dbgcs.data(0)<=i_cfg_adr_ld;
i_cfg_dbgcs.data(1)<=i_cfg_wd;
i_cfg_dbgcs.data(2)<=i_cfg_rd;
i_cfg_dbgcs.data(3)<=i_cfg_done;
i_cfg_dbgcs.data(4)<=i_cfg_txrdy;
i_cfg_dbgcs.data(5)<=i_cfg_rxrdy;
i_cfg_dbgcs.data(13 downto 6)<=i_cfg_adr(7 downto 0);
i_cfg_dbgcs.data(29 downto 14)<=i_cfg_txdata;
i_cfg_dbgcs.data(45 downto 30)<=i_cfg_rxdata;
i_cfg_dbgcs.data(49 downto 46)<=i_cfg_tstout(9 downto 6);
i_cfg_dbgcs.data(50)<=i_ram_txbuf_afull;
i_cfg_dbgcs.data(51)<=i_ram_txbuf_empty;
i_cfg_dbgcs.data(52)<=i_ram_rxbuf_afull;
i_cfg_dbgcs.data(53)<=i_ram_rxbuf_empty;
i_cfg_dbgcs.data(54)<=i_hdd_rbuf_cfg.ram_wr_i.rd;
i_cfg_dbgcs.data(55)<=i_hdd_txbuf_empty;
i_cfg_dbgcs.data(87 downto 56)<=i_hdd_rbuf_status.ram_wr_o.dout;
i_cfg_dbgcs.data(103 downto 88)<=(others=>'0');--tst_ram_rxbuf_rdcnt;


--process(i_hdd_module_rst,i_hdd_rbuf_cfg.ram_wr_i.clk)
--begin
--  if i_hdd_module_rst='1' then
--    tst_ram_rxbuf_rdcnt<=(others=>'0');
--  elsif i_hdd_rbuf_cfg.ram_wr_i.clk'event and i_hdd_rbuf_cfg.ram_wr_i.clk='1' then
--
--    if i_hdd_rbuf_cfg.dmacfg.clr_err='1' then
--      tst_ram_rxbuf_rdcnt<=(others=>'0');
--    elsif i_hdd_rbuf_cfg.ram_wr_i.rd='1' then
--      tst_ram_rxbuf_rdcnt<=tst_ram_rxbuf_rdcnt + 1;
--    end if;
--  end if;
--end process;


end generate gen_dbgcs;



--//Счетчик адреса регистров
process(i_hdd_module_rst,g_host_clk)
begin
  if i_hdd_module_rst='1' then
    i_cfg_adr_cnt<=(others=>'0');
  elsif g_host_clk'event and g_host_clk='1' then
    if i_cfg_adr_ld='1' and i_dev_adr=CONV_STD_LOGIC_VECTOR(0, i_dev_adr'length) then
      i_cfg_adr_cnt<=i_cfg_adr(7 downto 0);
    else
      if i_cfg_adr_fifo='0' and (i_cfg_wd='1' or i_cfg_rd='1') then
        i_cfg_adr_cnt<=i_cfg_adr_cnt+1;
      end if;
    end if;
  end if;
end process;

--//Запись регистров
process(i_hdd_module_rst,g_host_clk)
begin
  if i_hdd_module_rst='1' then
    i_reg0<=(others=>'0');
    i_reg1<=(others=>'0');
    i_reg2<=(others=>'0');
    i_reg3<=(others=>'0');
    i_reg4<=(others=>'0');

  elsif g_host_clk'event and g_host_clk='1' then

    if i_cfg_wd='1' then
        if    i_cfg_adr_cnt=CONV_STD_LOGIC_VECTOR(0, i_cfg_adr_cnt'length) then i_reg0<=i_cfg_txdata(i_reg0'high downto 0);
        elsif i_cfg_adr_cnt=CONV_STD_LOGIC_VECTOR(1, i_cfg_adr_cnt'length) then i_reg1<=i_cfg_txdata(i_reg1'high downto 0);
        elsif i_cfg_adr_cnt=CONV_STD_LOGIC_VECTOR(2, i_cfg_adr_cnt'length) then i_reg2<=i_cfg_txdata(i_reg2'high downto 0);
        elsif i_cfg_adr_cnt=CONV_STD_LOGIC_VECTOR(3, i_cfg_adr_cnt'length) then i_reg3<=i_cfg_txdata(i_reg3'high downto 0);
        elsif i_cfg_adr_cnt=CONV_STD_LOGIC_VECTOR(4, i_cfg_adr_cnt'length) then i_reg4<=i_cfg_txdata(i_reg4'high downto 0);

        end if;
    end if;

  end if;
end process;

--//Чтение регистров
process(i_hdd_module_rst,g_host_clk)
  variable rxd : std_logic_vector(i_cfg_rxdata'range);
begin
  if i_hdd_module_rst='1' then
      rxd:=(others=>'0');
    i_cfgt_rxdata<=(others=>'0');
  elsif g_host_clk'event and g_host_clk='1' then
    rxd:=(others=>'0');

    if i_cfg_rd='1' then
        if    i_cfg_adr_cnt=CONV_STD_LOGIC_VECTOR(0, i_cfg_adr_cnt'length) then rxd:=EXT(i_reg0, rxd'length);
        elsif i_cfg_adr_cnt=CONV_STD_LOGIC_VECTOR(1, i_cfg_adr_cnt'length) then rxd:=EXT(i_reg1, rxd'length);
        elsif i_cfg_adr_cnt=CONV_STD_LOGIC_VECTOR(2, i_cfg_adr_cnt'length) then rxd:=EXT(i_reg2, rxd'length);
        elsif i_cfg_adr_cnt=CONV_STD_LOGIC_VECTOR(3, i_cfg_adr_cnt'length) then rxd:=EXT(i_reg3, rxd'length);
        elsif i_cfg_adr_cnt=CONV_STD_LOGIC_VECTOR(4, i_cfg_adr_cnt'length) then rxd:=EXT(i_reg4, rxd'length);

        end if;

        i_cfgt_rxdata<=rxd;

    end if;--//if p_in_cfg_rd='1' then
  end if;
end process;

end architecture;
