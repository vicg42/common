-------------------------------------------------------------------------
-- Company     : Linkos
-- Engineer    : Golovachenko Victor
--
-- Create Date : 03/02/2010
-- Module Name : vereskm_main_tb
--
-- Назначение/Описание : Моделирование проекта Veresk_M
--
--
-- Revision:
-- Revision 0.01 - File Created
--
-------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_misc.all;

library std;
use std.textio.all;

library plxsim;
use plxsim.plxsim.all;

library work;
use work.vicg_common_pkg.all;
use work.memif.all;
use work.memif_sim.all;
use work.prj_cfg.all;
use work.prj_def.all;
use work.sata_pkg.all;
use work.vereskm_pkg.all;
use work.memory_ctrl_pkg.all;
use work.dsn_video_ctrl_pkg.all;
use work.dsn_track_pkg.all;
use work.dsn_track_nik_pkg.all;


entity vereskm_main_tb is
end vereskm_main_tb;

architecture behav of vereskm_main_tb is

constant C_HREG_DEV_CTRL_DEV_ADDR_SIZE : integer:=(C_HREG_DEV_CTRL_DEV_ADDR_MSB_BIT-C_HREG_DEV_CTRL_DEV_ADDR_LSB_BIT +1);

constant C_LBUS_32BIT            : natural := 2;
constant C_LBUS_64BIT            : natural := 3;
constant C_LBUS_DATA_BITS        : natural := C_LBUS_32BIT;

constant C_VM_USR_REG_BAR        : std_logic_vector :=X"00000080";--:=X"00000200";
constant C_VM_USR_REG_BCOUNT     : integer :=4;--8


constant C_MULTBURST_ON          : boolean:=true;
constant C_MULTBURST_OFF         : boolean:=false;

constant C_WRITE                 : std_logic:='0';
constant C_READ                  : std_logic:='1';

constant C_FIFO_OFF              : std_logic:='0';
constant C_FIFO_ON               : std_logic:='1';

--    constant period:     time     := 30 ns;
--    constant priorities : integer_vector_t(0 to 0) := (others => 0);

constant refclk_period : time := 5 ns;
constant lclk_period : time := 15 ns;
constant mclka_period : time := 3.75 ns; -- 266.67MHz clock frequency at memory chips

constant num_agent : natural := 1;

constant priorities : integer_vector_t(0 to num_agent - 1) := (others => 0);

constant bank0      : bank_t := C_MEM_BANK0;--(enable => true, ra_width => 19, rc_width => 22, rd_width => 32);
constant bank1      : bank_t := C_MEM_BANK1;--(enable => true, ra_width => 19, rc_width => 22, rd_width => 32);
constant bank2      : bank_t := C_MEM_BANK2;--(enable => true, ra_width => 24, rc_width => 9, rd_width => 16);
constant bank3      : bank_t := C_MEM_BANK3;--no_bank;
constant bank4      : bank_t := C_MEM_BANK4;--no_bank;
constant bank5      : bank_t := C_MEM_BANK5;--no_bank;
constant bank6      : bank_t := C_MEM_BANK6;--no_bank;
constant bank7      : bank_t := C_MEM_BANK7;--no_bank;
constant bank8      : bank_t := C_MEM_BANK8;--no_bank;
constant bank9      : bank_t := C_MEM_BANK9;--no_bank;
constant bank10     : bank_t := C_MEM_BANK10;--no_bank;
constant bank11     : bank_t := C_MEM_BANK11;--no_bank;
constant bank12     : bank_t := C_MEM_BANK12;--no_bank;
constant bank13     : bank_t := C_MEM_BANK13;--no_bank;
constant bank14     : bank_t := C_MEM_BANK14;--no_bank;
constant bank15     : bank_t := C_MEM_BANK15;--no_bank;
constant num_ramclk : natural:= C_MEM_NUM_RAMCLK;--1;

signal lclk, mclk:         std_logic := '1';
signal lreset_l:           std_logic := '0';
signal lbe_l:              std_logic_vector(C_FHOST_DBUS/8-1 downto 0) := (others => 'Z');
signal lad:                std_logic_vector(C_FHOST_DBUS-1 downto 0) := (others => 'Z');
signal lwrite:             std_logic := '0';
signal lads_l:             std_logic := '1';
signal l64_l :             std_logic := 'Z';
signal lblast_l:           std_logic := '1';
signal lbterm_l:           std_logic := 'Z';
signal lready_l:           std_logic := 'Z';
signal lhold, lholda:      std_logic_vector(num_agent - 1 downto 0);
signal fholda:             std_logic := '0';
signal finto_l:            std_logic;

signal mclka_p : std_logic := '1';
signal mclka_n : std_logic := '0';
signal refclk_p : std_logic := '1';
signal refclk_n : std_logic := '0';
signal ra0 : std_logic_vector(bank0.ra_width - 1 downto 0) := (others => 'Z');
signal rc0 : std_logic_vector(bank0.rc_width - 1 downto 0) := (others => 'Z');
signal rd0 : std_logic_vector(bank0.rd_width - 1 downto 0) := (others => 'Z');
signal ra1 : std_logic_vector(bank1.ra_width - 1 downto 0) := (others => 'Z');
signal rc1 : std_logic_vector(bank1.rc_width - 1 downto 0) := (others => 'Z');
signal rd1 : std_logic_vector(bank1.rd_width - 1 downto 0) := (others => 'Z');
signal ra2 : std_logic_vector(bank2.ra_width - 1 downto 0) := (others => 'Z');
signal rc2 : std_logic_vector(bank2.rc_width - 1 downto 0) := (others => 'Z');
signal rd2 : std_logic_vector(bank2.rd_width - 1 downto 0) := (others => 'Z');
signal ra3 : std_logic_vector(bank3.ra_width - 1 downto 0) := (others => 'Z');
signal rc3 : std_logic_vector(bank3.rc_width - 1 downto 0) := (others => 'Z');
signal rd3 : std_logic_vector(bank3.rd_width - 1 downto 0) := (others => 'Z');
signal ra4 : std_logic_vector(bank4.ra_width - 1 downto 0) := (others => 'Z');
signal rc4 : std_logic_vector(bank4.rc_width - 1 downto 0) := (others => 'Z');
signal rd4 : std_logic_vector(bank4.rd_width - 1 downto 0) := (others => 'Z');
signal ra5 : std_logic_vector(bank5.ra_width - 1 downto 0) := (others => 'Z');
signal rc5 : std_logic_vector(bank5.rc_width - 1 downto 0) := (others => 'Z');
signal rd5 : std_logic_vector(bank5.rd_width - 1 downto 0) := (others => 'Z');
signal ra6 : std_logic_vector(bank6.ra_width - 1 downto 0) := (others => 'Z');
signal rc6 : std_logic_vector(bank6.rc_width - 1 downto 0) := (others => 'Z');
signal rd6 : std_logic_vector(bank6.rd_width - 1 downto 0) := (others => 'Z');
signal ra7 : std_logic_vector(bank7.ra_width - 1 downto 0) := (others => 'Z');
signal rc7 : std_logic_vector(bank7.rc_width - 1 downto 0) := (others => 'Z');
signal rd7 : std_logic_vector(bank7.rd_width - 1 downto 0) := (others => 'Z');
signal ra8 : std_logic_vector(bank8.ra_width - 1 downto 0) := (others => 'Z');
signal rc8 : std_logic_vector(bank8.rc_width - 1 downto 0) := (others => 'Z');
signal rd8 : std_logic_vector(bank8.rd_width - 1 downto 0) := (others => 'Z');
signal ra9 : std_logic_vector(bank9.ra_width - 1 downto 0) := (others => 'Z');
signal rc9 : std_logic_vector(bank9.rc_width - 1 downto 0) := (others => 'Z');
signal rd9 : std_logic_vector(bank9.rd_width - 1 downto 0) := (others => 'Z');
signal ra10 : std_logic_vector(bank10.ra_width - 1 downto 0) := (others => 'Z');
signal rc10 : std_logic_vector(bank10.rc_width - 1 downto 0) := (others => 'Z');
signal rd10 : std_logic_vector(bank10.rd_width - 1 downto 0) := (others => 'Z');
signal ra11 : std_logic_vector(bank11.ra_width - 1 downto 0) := (others => 'Z');
signal rc11 : std_logic_vector(bank11.rc_width - 1 downto 0) := (others => 'Z');
signal rd11 : std_logic_vector(bank11.rd_width - 1 downto 0) := (others => 'Z');
signal ra12 : std_logic_vector(bank12.ra_width - 1 downto 0) := (others => 'Z');
signal rc12 : std_logic_vector(bank12.rc_width - 1 downto 0) := (others => 'Z');
signal rd12 : std_logic_vector(bank12.rd_width - 1 downto 0) := (others => 'Z');
signal ra13 : std_logic_vector(bank13.ra_width - 1 downto 0) := (others => 'Z');
signal rc13 : std_logic_vector(bank13.rc_width - 1 downto 0) := (others => 'Z');
signal rd13 : std_logic_vector(bank13.rd_width - 1 downto 0) := (others => 'Z');
signal ra14 : std_logic_vector(bank14.ra_width - 1 downto 0) := (others => 'Z');
signal rc14 : std_logic_vector(bank14.rc_width - 1 downto 0) := (others => 'Z');
signal rd14 : std_logic_vector(bank14.rd_width - 1 downto 0) := (others => 'Z');
signal ra15 : std_logic_vector(bank15.ra_width - 1 downto 0) := (others => 'Z');
signal rc15 : std_logic_vector(bank15.rc_width - 1 downto 0) := (others => 'Z');
signal rd15 : std_logic_vector(bank15.rd_width - 1 downto 0) := (others => 'Z');
signal ramclk : std_logic_vector(num_ramclk - 1 downto 0);

signal ra0_ram : std_logic_vector(bank0.ra_width - 1 downto 0) := (others => 'Z');
signal rc0_ram : std_logic_vector(bank0.rc_width - 1 downto 0) := (others => 'Z');
signal rd0_ram : std_logic_vector(bank0.rd_width - 1 downto 0) := (others => 'Z');
signal ra1_ram : std_logic_vector(bank1.ra_width - 1 downto 0) := (others => 'Z');
signal rc1_ram : std_logic_vector(bank1.rc_width - 1 downto 0) := (others => 'Z');
signal rd1_ram : std_logic_vector(bank1.rd_width - 1 downto 0) := (others => 'Z');
signal ra2_ram : std_logic_vector(bank2.ra_width - 1 downto 0) := (others => 'Z');
signal rc2_ram : std_logic_vector(bank2.rc_width - 1 downto 0) := (others => 'Z');
signal rd2_ram : std_logic_vector(bank2.rd_width - 1 downto 0) := (others => 'Z');

signal bus_in : locbus_in_t;
signal bus_out : locbus_out_t := init_locbus_out;

signal logic0, logic1 : std_logic;

signal i_pciexp_txp   : std_logic_vector(C_PCIEXPRESS_LINK_WIDTH-1 downto 0);
signal i_pciexp_txn   : std_logic_vector(C_PCIEXPRESS_LINK_WIDTH-1 downto 0);
signal i_pciexp_rxp   : std_logic_vector(C_PCIEXPRESS_LINK_WIDTH-1 downto 0);
signal i_pciexp_rxn   : std_logic_vector(C_PCIEXPRESS_LINK_WIDTH-1 downto 0);
signal i_pciexp_sys_clk_p       : std_logic;
signal i_pciexp_sys_clk_n       : std_logic;

signal cor_sys_reset_n : std_logic := '1';
signal cor_sys_clk_p : std_logic;
signal cor_sys_clk_n : std_logic;
signal dsport_sys_clk_p : std_logic;
signal dsport_sys_clk_n : std_logic;

signal cor_pci_exp_txn : std_logic_vector((1 - 1) downto 0);
signal cor_pci_exp_txp : std_logic_vector((1 - 1) downto 0);
signal cor_pci_exp_rxn : std_logic_vector((1 - 1) downto 0);
signal cor_pci_exp_rxp : std_logic_vector((1 - 1) downto 0);

signal i_eth_txp   : std_logic_vector(1 downto 0);
signal i_eth_txn   : std_logic_vector(1 downto 0);
signal i_eth_rxp   : std_logic_vector(1 downto 0);
signal i_eth_rxn   : std_logic_vector(1 downto 0);
signal mgtclk_p      : std_logic;
signal mgtclk_n      : std_logic;

procedure report_message(
    str : in string)
is
    variable msg : line;
begin
    write(msg, str);
    writeline(output, msg);
end;


--************************************************************
--     Proc : writeNowToScreen
--     Inputs : Text String
--     Outputs : None
--     Description : Displays current simulation time and text string to
--          standard output.
--   *************************************************************

procedure writeNowToScreen (

  text_string                 : in string

) is

  variable L      : line;

begin

  write (L, String'("[ "));
  write (L, now);
  write (L, String'(" ] : "));
  write (L, text_string);
  writeline (output, L);

end writeNowToScreen;

--component xilinx_pci_exp_1_lane_downstream_port
--
--port  (
--
--  sys_clk_p : in std_logic;
--  sys_clk_n : in std_logic;
--  sys_reset_n : in std_logic;
--
--  pci_exp_rxn : in std_logic_vector((1 - 1) downto 0);
--  pci_exp_rxp : in std_logic_vector((1 - 1) downto 0);
--  pci_exp_txn : out std_logic_vector((1 - 1) downto 0);
--  pci_exp_txp : out std_logic_vector((1 - 1) downto 0)
--
--);
--
--end component;
--
--
--component sys_clk_gen_ds
--generic (
--
--  CLK_FREQ: INTEGER := 250
--
--);
--port (
--
--  sys_clk_p : out std_logic;
--  sys_clk_n : out std_logic
--
--);
--end component;


--    component HY5PS121621F
----        generic(
----            TimingCheckFlag : boolean := TRUE;
----            PUSCheckFlag : boolean := FALSE;
----            Part_Number : PART_NUM_TYPE := B400);
--        port(
--            DQ    :  inout   std_logic_vector(15 downto 0) := (others => 'Z');
--            LDQS  :  inout   std_logic := 'Z';
--            LDQSB :  inout   std_logic := 'Z';
--            UDQS  :  inout   std_logic := 'Z';
--            UDQSB :  inout   std_logic := 'Z';
--            LDM   :  in      std_logic;
--            WEB   :  in      std_logic;
--            CASB  :  in      std_logic;
--            RASB  :  in      std_logic;
--            CSB   :  in      std_logic;
--            BA    :  in      std_logic_vector(1 downto 0);
--            ADDR  :  in      std_logic_vector(12 downto 0);
--            CKE   :  in      std_logic;
--            CLK   :  in      std_logic;
--            CLKB  :  in      std_logic;
--            UDM   :  in      std_logic);
--    end component;



component vereskm_main
generic
(
G_SIM_HOST   : string:="OFF";
G_SIM_PCIEXP : std_logic:='0';
G_DBG_PCIEXP : string:="OFF";
G_SIM        : string:="ON"
);
port
(
--------------------------------------------------
--Светодиоды (Для платы ML505)
--------------------------------------------------
pin_out_led       : out   std_logic_vector(7 downto 0);
pin_out_led_C     : out   std_logic;
pin_out_led_E     : out   std_logic;
pin_out_led_N     : out   std_logic;
pin_out_led_S     : out   std_logic;
pin_out_led_W     : out   std_logic;

pin_out_TP        : out   std_logic_vector(7 downto 0);

pin_in_btn_C      : in    std_logic;
pin_in_btn_E      : in    std_logic;
pin_in_btn_N      : in    std_logic;
pin_in_btn_S      : in    std_logic;
pin_in_btn_W      : in    std_logic;

pin_out_ddr2_cke1 : out   std_logic;
pin_out_ddr2_cs1  : out   std_logic;
pin_out_ddr2_odt1 : out   std_logic;

--------------------------------------------------
--Memory banks (up to 16 supported by this design)
--------------------------------------------------
ra0               : out   std_logic_vector(C_MEM_BANK0.ra_width - 1 downto 0);
rc0               : inout std_logic_vector(C_MEM_BANK0.rc_width - 1 downto 0);
rd0               : inout std_logic_vector(C_MEM_BANK0.rd_width - 1 downto 0);
ra1               : out   std_logic_vector(C_MEM_BANK1.ra_width - 1 downto 0);
rc1               : inout std_logic_vector(C_MEM_BANK1.rc_width - 1 downto 0);
rd1               : inout std_logic_vector(C_MEM_BANK1.rd_width - 1 downto 0);
ra2               : out   std_logic_vector(C_MEM_BANK2.ra_width - 1 downto 0);
rc2               : inout std_logic_vector(C_MEM_BANK2.rc_width - 1 downto 0);
rd2               : inout std_logic_vector(C_MEM_BANK2.rd_width - 1 downto 0);
ra3               : out   std_logic_vector(C_MEM_BANK3.ra_width - 1 downto 0);
rc3               : inout std_logic_vector(C_MEM_BANK3.rc_width - 1 downto 0);
rd3               : inout std_logic_vector(C_MEM_BANK3.rd_width - 1 downto 0);
ra4               : out   std_logic_vector(C_MEM_BANK4.ra_width - 1 downto 0);
rc4               : inout std_logic_vector(C_MEM_BANK4.rc_width - 1 downto 0);
rd4               : inout std_logic_vector(C_MEM_BANK4.rd_width - 1 downto 0);
ra5               : out   std_logic_vector(C_MEM_BANK5.ra_width - 1 downto 0);
rc5               : inout std_logic_vector(C_MEM_BANK5.rc_width - 1 downto 0);
rd5               : inout std_logic_vector(C_MEM_BANK5.rd_width - 1 downto 0);
ra6               : out   std_logic_vector(C_MEM_BANK6.ra_width - 1 downto 0);
rc6               : inout std_logic_vector(C_MEM_BANK6.rc_width - 1 downto 0);
rd6               : inout std_logic_vector(C_MEM_BANK6.rd_width - 1 downto 0);
ra7               : out   std_logic_vector(C_MEM_BANK7.ra_width - 1 downto 0);
rc7               : inout std_logic_vector(C_MEM_BANK7.rc_width - 1 downto 0);
rd7               : inout std_logic_vector(C_MEM_BANK7.rd_width - 1 downto 0);
ra8               : out   std_logic_vector(C_MEM_BANK8.ra_width - 1 downto 0);
rc8               : inout std_logic_vector(C_MEM_BANK8.rc_width - 1 downto 0);
rd8               : inout std_logic_vector(C_MEM_BANK8.rd_width - 1 downto 0);
ra9               : out   std_logic_vector(C_MEM_BANK9.ra_width - 1 downto 0);
rc9               : inout std_logic_vector(C_MEM_BANK9.rc_width - 1 downto 0);
rd9               : inout std_logic_vector(C_MEM_BANK9.rd_width - 1 downto 0);
ra10              : out   std_logic_vector(C_MEM_BANK10.ra_width - 1 downto 0);
rc10              : inout std_logic_vector(C_MEM_BANK10.rc_width - 1 downto 0);
rd10              : inout std_logic_vector(C_MEM_BANK10.rd_width - 1 downto 0);
ra11              : out   std_logic_vector(C_MEM_BANK11.ra_width - 1 downto 0);
rc11              : inout std_logic_vector(C_MEM_BANK11.rc_width - 1 downto 0);
rd11              : inout std_logic_vector(C_MEM_BANK11.rd_width - 1 downto 0);
ra12              : out   std_logic_vector(C_MEM_BANK12.ra_width - 1 downto 0);
rc12              : inout std_logic_vector(C_MEM_BANK12.rc_width - 1 downto 0);
rd12              : inout std_logic_vector(C_MEM_BANK12.rd_width - 1 downto 0);
ra13              : out   std_logic_vector(C_MEM_BANK13.ra_width - 1 downto 0);
rc13              : inout std_logic_vector(C_MEM_BANK13.rc_width - 1 downto 0);
rd13              : inout std_logic_vector(C_MEM_BANK13.rd_width - 1 downto 0);
ra14              : out   std_logic_vector(C_MEM_BANK14.ra_width - 1 downto 0);
rc14              : inout std_logic_vector(C_MEM_BANK14.rc_width - 1 downto 0);
rd14              : inout std_logic_vector(C_MEM_BANK14.rd_width - 1 downto 0);
ra15              : out   std_logic_vector(C_MEM_BANK15.ra_width - 1 downto 0);
rc15              : inout std_logic_vector(C_MEM_BANK15.rc_width - 1 downto 0);
rd15              : inout std_logic_vector(C_MEM_BANK15.rd_width - 1 downto 0);
ramclko           : out   std_logic_vector(C_MEM_NUM_RAMCLK - 1 downto 0);

--------------------------------------------------
--Ethernet
--------------------------------------------------
pin_out_sfp_tx_dis    : out  std_logic;                      --//SFP - TX DISABLE
pin_in_sfp_sd         : in   std_logic;                      --//SFP - SD signal detect

pin_out_eth_txp       : out   std_logic_vector(1 downto 0);
pin_out_eth_txn       : out   std_logic_vector(1 downto 0);
pin_in_eth_rxp        : in    std_logic_vector(1 downto 0);
pin_in_eth_rxn        : in    std_logic_vector(1 downto 0);
pin_in_eth_clk_p      : in    std_logic;
pin_in_eth_clk_n      : in    std_logic;

pin_out_gt_X0Y6_txp   : out  std_logic_vector(1 downto 0);
pin_out_gt_X0Y6_txn   : out  std_logic_vector(1 downto 0);
pin_in_gt_X0Y6_rxp    : in   std_logic_vector(1 downto 0);
pin_in_gt_X0Y6_rxn    : in   std_logic_vector(1 downto 0);
pin_in_gt_X0Y6_clk_p  : in   std_logic;
pin_in_gt_X0Y6_clk_n  : in   std_logic;

--------------------------------------------------
--PCI-EXPRESS
--------------------------------------------------
pin_out_pciexp_txp    : out   std_logic_vector(C_PCIEXPRESS_LINK_WIDTH-1 downto 0);
pin_out_pciexp_txn    : out   std_logic_vector(C_PCIEXPRESS_LINK_WIDTH-1 downto 0);
pin_in_pciexp_rxp     : in    std_logic_vector(C_PCIEXPRESS_LINK_WIDTH-1 downto 0);
pin_in_pciexp_rxn     : in    std_logic_vector(C_PCIEXPRESS_LINK_WIDTH-1 downto 0);
pin_in_pciexp_clk_p   : in    std_logic;
pin_in_pciexp_clk_n   : in    std_logic;

--------------------------------------------------
--SATA
--------------------------------------------------
pin_out_sata_txn      : out   std_logic_vector(1 downto 0);
pin_out_sata_txp      : out   std_logic_vector(1 downto 0);
pin_in_sata_rxn       : in    std_logic_vector(1 downto 0);
pin_in_sata_rxp       : in    std_logic_vector(1 downto 0);
pin_in_sata_clk_n     : in    std_logic;
pin_in_sata_clk_p     : in    std_logic;

--------------------------------------------------
-- Local bus
--------------------------------------------------
lreset_l              : in    std_logic;
lclk                  : in    std_logic;
lwrite                : in    std_logic;
lads_l                : in    std_logic;
lblast_l              : in    std_logic;
lbe_l                 : in    std_logic_vector(C_FHOST_DBUS/8-1 downto 0);--(3 downto 0);
lad                   : inout std_logic_vector(C_FHOST_DBUS-1 downto 0);--(31 downto 0);
lbterm_l              : inout std_logic;
lready_l              : inout std_logic;
fholda                : in    std_logic;
finto_l               : out   std_logic;

--------------------------------------------------
-- Тактовые сигналы
--------------------------------------------------
--//Тактовый сигнала с программируемого генератора
--//подается на RocketIO GTP №112(GTP_DUAL_X0Y4)
--//пины GTP выходят на разъем XRM (см. Doc / adm-xrc-5t1 user manual.pdf /Table 11  XRM Interface - MGT Links)
--//Частота для SATA
--mclkb_n           : in    std_logic;
--mclkb_p           : in    std_logic;

----//Тактовый сигнала с программируемого генератора
----//подается на RocketIO GTP №122 (GTP_DUAL_X0Y1)
----//пины GTP выходят на разъем XMС (см. Doc / adm-xrc-5t1 user manual.pdf /Table 14  XMC P15 Connections )
--mclka_n           : in    std_logic;
--mclka_p           : in    std_logic;

-- Reference clock 200MHz
refclk_n          : in    std_logic;
refclk_p          : in    std_logic
);
end component;

function f_ConvertAdr(x : integer) return integer is
begin
return x*4;
end f_ConvertAdr;

procedure wait_cycles(constant n : in natural; signal   k : in std_logic)is
begin
for i in 0 to n - 1 loop
  wait until k'event and k = '1';
end loop;
wait for 1 ns;
end;

procedure p_SendCfgPkt(
constant WR       : in   std_logic;
constant FIFO     : in   std_logic;
constant NumDev   : in   integer;
constant NumReg   : in   integer;
constant DataSize : in   integer;
constant devctrl  : in   std_logic_vector(31 downto 0);
         usr_data : in   byte_vector_t(0 to 127);
signal   bus_in   : in   locbus_in_t;
signal   bus_out  : out  locbus_out_t
)is
  variable val32 : std_logic_vector(31 downto 0);
  variable val16 : std_logic_vector(15 downto 0);
  variable data : byte_vector_t(0 to 127);
  variable be : byte_enable_t(0 to 127);
  variable n : natural;
  variable tmp_devctrl: std_logic_vector(31 downto 0);
  variable var_DataSize : integer;
begin

be := (others => '1');
tmp_devctrl:=devctrl;
var_DataSize:=DataSize;

--//-----------------------------------------
--//Передаем заголовок командного пакета
--//-----------------------------------------
val16:=CONV_STD_LOGIC_VECTOR(NumDev, 8)&WR&FIFO&"000000";
data(0)(7 downto 0) := val16(7 downto 0);
data(1)(7 downto 0) := val16(15 downto 8);
data(2)(7 downto 0) := (others=>'0');
data(3)(7 downto 0) := (others=>'0');

val16:=CONV_STD_LOGIC_VECTOR(var_DataSize, 8)&CONV_STD_LOGIC_VECTOR(NumReg, 8);
data(4)(7 downto 0) := val16(7 downto 0);
data(5)(7 downto 0) := val16(15 downto 8);
data(6)(7 downto 0) := (others=>'0');
data(7)(7 downto 0) := (others=>'0');


if WR=C_WRITE then
--//-----------------------------------------
--//Передаем данные
--//-----------------------------------------
for i in 0 to var_DataSize-1 loop
data(4*i+8)(7 downto 0) := usr_data(4*i+0)(7 downto 0);
data(4*i+9)(7 downto 0) := usr_data(4*i+1)(7 downto 0);
data(4*i+10)(7 downto 0):= usr_data(4*i+2)(7 downto 0);
data(4*i+11)(7 downto 0):= usr_data(4*i+3)(7 downto 0);
end loop;
else
var_DataSize:=0;
end if;

--//-----------------------------------------
--//Формируем подтверждение записи в TXBUF модуля cfgdev.vhd
--//-----------------------------------------
plxsim_write_const(C_LBUS_DATA_BITS, C_MULTBURST_ON, X"00200000", be(0 to (7+(4*var_DataSize))), data(0 to (7+(4*var_DataSize))), n, bus_in, bus_out);
tmp_devctrl(C_HREG_DEV_CTRL_DEV_DIN_RDY_BIT):='1';
data(0 to 3) :=conv_byte_vector(tmp_devctrl);
tmp_devctrl(C_HREG_DEV_CTRL_DEV_DIN_RDY_BIT):='0';
data(4 to 7) :=conv_byte_vector(tmp_devctrl);
plxsim_write_const(C_LBUS_DATA_BITS, C_MULTBURST_ON, (C_VM_USR_REG_BAR+CONV_STD_LOGIC_VECTOR(C_HOST_REG_DEV_CTRL*C_VM_USR_REG_BCOUNT, 32)), be(0 to 7), data(0 to 7), n, bus_in, bus_out);

end;





procedure p_SendMasDATA(
constant DataSize : in   integer;
constant devctrl  : in   std_logic_vector(31 downto 0);
         usr_data : in   byte_vector_t(0 to 127);
signal   bus_in   : in   locbus_in_t;
signal   bus_out  : out  locbus_out_t
)is
  variable val32 : std_logic_vector(31 downto 0);
  variable val16 : std_logic_vector(15 downto 0);
  variable data : byte_vector_t(0 to 127);
  variable be : byte_enable_t(0 to 127);
  variable n : natural;
  variable tmp_devctrl: std_logic_vector(31 downto 0);
begin

be := (others => '1');
tmp_devctrl:=devctrl;

--//-----------------------------------------
--//Передаем данные
--//-----------------------------------------
for i in 0 to DataSize-1 loop
data(4*i+0)(7 downto 0):= usr_data(4*i+0)(7 downto 0);
data(4*i+1)(7 downto 0):= usr_data(4*i+1)(7 downto 0);
data(4*i+2)(7 downto 0):= usr_data(4*i+2)(7 downto 0);
data(4*i+3)(7 downto 0):= usr_data(4*i+3)(7 downto 0);
end loop;

--//-----------------------------------------
--//Формируем подтверждение записи в TXBUF модуля cfgdev.vhd
--//-----------------------------------------
plxsim_write_const(C_LBUS_DATA_BITS, C_MULTBURST_ON, X"00200000", be(0 to (4*DataSize)-1), data(0 to (4*DataSize)-1), n, bus_in, bus_out);
tmp_devctrl(C_HREG_DEV_CTRL_DEV_DIN_RDY_BIT):='1';
data(0 to 3) :=conv_byte_vector(tmp_devctrl);
tmp_devctrl(C_HREG_DEV_CTRL_DEV_DIN_RDY_BIT):='0';
data(4 to 7) :=conv_byte_vector(tmp_devctrl);
plxsim_write_const(C_LBUS_DATA_BITS, C_MULTBURST_ON, (C_VM_USR_REG_BAR+CONV_STD_LOGIC_VECTOR(C_HOST_REG_DEV_CTRL*C_VM_USR_REG_BCOUNT, 32)), be(0 to 7), data(0 to 7), n, bus_in, bus_out);

end;


begin

logic0 <= '0';
logic1 <= '1';

--    lclk <= not lclk after lclk_period / 2;

refclk_p <= not refclk_p after refclk_period / 2;
refclk_n <= not refclk_n after refclk_period / 2;

lclk <= not lclk after lclk_period / 2;

mclka_p <= not mclka_p after mclka_period / 2;
mclka_n <= not mclka_n after mclka_period / 2;

lreset_l <= transport '1' after 500 ns;--50 ns;
BOARD_INIT : process
begin
  writeNowToScreen(String'("System Reset Asserted..."));

  cor_sys_reset_n <= '0';
  for i in 0 to (500 - 1) loop
    wait until (cor_sys_clk_p'event and cor_sys_clk_p = '1');
  end loop;

  writeNowToScreen(String'("System Reset De-asserted..."));
  cor_sys_reset_n <= '1';
  wait;
end process BOARD_INIT;

lads_l <= 'H';
l64_l <= 'H';
lblast_l <= 'H';
lready_l <= 'H';
lbterm_l <= 'H';
lwrite <= 'H';



stimulate: process
--  variable data : byte_vector_t(0 to 127);
--  variable be : byte_enable_t(0 to 127);
--  variable n : natural;

  variable data : byte_vector_t(0 to 127);
  variable data_usr : byte_vector_t(0 to 127);
  variable be : byte_enable_t(0 to 127);
  variable n : natural;
  variable val32 : std_logic_vector(31 downto 0);
  type TUser_Reg is array (0 to 127) of std_logic_vector(31 downto 0);
  variable User_Reg: TUser_Reg;

  variable tag : natural;
  variable remaining : natural := 64;--tsf_size;
  variable chunk : natural;
  variable trans : natural;
  variable offset: natural;
  variable datasize: integer;
  variable PktDataIdx: integer;
  variable i_dev_ctrl  : std_logic_vector(31 downto 0);

  variable i_FrameSize  : std_logic_vector(63 downto 0);

  variable tmp_32vector  : std_logic_vector(31 downto 0);
  variable PixLen  : std_logic_vector(31 downto 0);
  variable RowLen  : std_logic_vector(31 downto 0);
  variable Pix8bit: std_logic;
  variable FrTxD_2DW_cnt: std_logic;
  variable TstData_02ver : std_logic;
  variable AutoVCH_Change: std_logic;

  variable Trc_MemWR_trn_len : std_logic_vector(7 downto 0);
  variable Trc_MemRD_trn_len : std_logic_vector(7 downto 0);
  variable TrcChParams :TTrackParams;
  variable TrcWorkOn :std_logic;
  variable TrcRegTST0 : std_logic_vector(15 downto 0);

  variable TrcNik_MemWR_trn_len : std_logic_vector(7 downto 0);
  variable TrcNik_MemRD_trn_len : std_logic_vector(7 downto 0);
  variable TrcNikChParams : TTrcNikParams;
  variable TrcNikWorkOn :std_logic;
  variable TrcNikRegTST0 : std_logic_vector(15 downto 0);
  variable TrcNikIP_Count : integer;

  variable VctrlChParams :TVctrlChParams;
  variable Vctrl_MemWR_trn_len : std_logic_vector(7 downto 0);
  variable Vctrl_MemRD_trn_len : std_logic_vector(7 downto 0);
  variable swt_dsntesting_to_ethtxbuf: std_logic;
  variable swt_ethtxbuf_to_vdbufrxd: std_logic;
  variable swt_ethtxbuf_to_hddbuf: std_logic;
  variable eth_usrtxpkt_size: integer:=0;

  variable VctrlRegTST0 : std_logic_vector(15 downto 0);

  variable swt_fmask0_eth_vctrl: std_logic_vector(15 downto 0);
  variable swt_fmask1_eth_vctrl: std_logic_vector(15 downto 0);
  variable swt_fmask2_eth_vctrl: std_logic_vector(15 downto 0);
  variable swt_fmask_eth_hdd: std_logic;
  variable swt_fmask_eth_host: std_logic;

  variable hdd_cfg_rambuf_adr: std_logic_vector(31 downto 0);
  variable hdd_cfg_rambuf_size: std_logic_vector(31 downto 0);
  variable hdd_cfg_rambuf_level: std_logic_vector(15 downto 0);
  variable hdd_cfg_rambuf_fifo_size: std_logic_vector(15 downto 0);
  variable hdd_cfg_rambuf_ctrl: std_logic_vector(15 downto 0);

  variable hdd_SectorCount: integer;
  variable hdd_mask: integer;

  variable track_read_01_start: integer;
  variable track_read_01_end: integer;

  variable vctrl_read_01_start: integer;
  variable vctrl_read_01_end: integer;

  variable vctrl_read_02_start: integer;
  variable vctrl_read_02_end: integer;

begin
  wait for 0.6 us;

  plxsim_wait_cycles(16, bus_in);
  i_dev_ctrl:=(others=>'0');
  tmp_32vector:=(others=>'0');

  be := (others => '1');

  for i in 0 to 127 loop
    data(i)(7 downto 0) := "00000000";
    User_Reg(i):=(others=>'0');
  end loop;

  plxsim_request_bus(true, bus_in, bus_out);

  data(0 to 3) :=conv_byte_vector(X"00001000");
  data(4 to 7) :=conv_byte_vector(X"0000AAAA");
  plxsim_write_const(C_LBUS_DATA_BITS, C_MULTBURST_OFF, (C_VM_USR_REG_BAR+CONV_STD_LOGIC_VECTOR(C_HOST_REG_TST0*C_VM_USR_REG_BCOUNT, 32)), be(0 to 7), data(0 to 7), n, bus_in, bus_out);

  wait_cycles(10, lclk);



  --------------------------------
  --//Параметры модуля HDD
  --------------------------------
  hdd_cfg_rambuf_adr:=(others=>'0');
  hdd_cfg_rambuf_size:=(others=>'0');
  hdd_cfg_rambuf_level:=(others=>'0');
  hdd_cfg_rambuf_fifo_size:=(others=>'0');
  hdd_cfg_rambuf_ctrl:=(others=>'0');

  hdd_SectorCount:=16#40#;
  hdd_mask:=1;

  --//Конфигурирование RAMBUF HDD
  --//Адрес буфера в ОЗУ
  hdd_cfg_rambuf_adr:=CONV_STD_LOGIC_VECTOR(16#4000000#, hdd_cfg_rambuf_adr'length);--//В байтах
  --//Размер буфера в ОЗУ
  hdd_cfg_rambuf_size:=CONV_STD_LOGIC_VECTOR(16#4000000#, hdd_cfg_rambuf_size'length);--//В байтах
  --//Уровень RAMBUF. Если данных в буфере больше этого уровня увеличиваем размер
  --//транзакции чтения ОЗУ
  hdd_cfg_rambuf_level:=CONV_STD_LOGIC_VECTOR(16#0000800#, hdd_cfg_rambuf_level'length);--//В DWORD
  --//Размер согласующего FIFO в модуле dsn_sata.vhd
  hdd_cfg_rambuf_fifo_size:=CONV_STD_LOGIC_VECTOR(16#0001000#, hdd_cfg_rambuf_fifo_size'length);--//В DWORD

--(C_DSN_HDD_REG_CTRLL_OVERFLOW_DET_BIT)
  --//размер одиночной транзакции (в DWORD) для записи/чтения
--  hdd_cfg_rambuf_ctrl(C_DSN_HDD_REG_RBUF_CTRL_TRNMEM_MSB_BIT downto C_DSN_HDD_REG_RBUF_CTRL_TRNMEM_LSB_BIT):=CONV_STD_LOGIC_VECTOR(16#40#, C_DSN_HDD_REG_RBUF_CTRL_TRNMEM_MSB_BIT-C_DSN_HDD_REG_RBUF_CTRL_TRNMEM_LSB_BIT+1);
  hdd_cfg_rambuf_ctrl(C_DSN_HDD_REG_RBUF_CTRL_TEST_BIT) :='1';--//Режим тестирования
  hdd_cfg_rambuf_ctrl(C_DSN_HDD_REG_RBUF_CTRL_STOP_BIT) :='0';--//Перевод модуля HDD_RAMBUF в исходное состояние
                                                            --//Для коректного выолнения перехода в исходное состояние нельзя обрывать входной поток данных

  --------------------------------
  --//Параметры модуля Коммутатора
  --------------------------------
  swt_dsntesting_to_ethtxbuf:='1';--//1/0 On/Off - dsn_testing подсоеденить к swt/ethtxbuf
  swt_ethtxbuf_to_vdbufrxd  :='0';--//1/0 On/Off - swt/ethtxbuf подсоеденить к swt/vdbufrxd
  swt_ethtxbuf_to_hddbuf    :='0';--//1/0 On/Off - swt/ethtxbuf подсоеденить к swt/hdd

  --Маска(1)-[15:8];  Маска(0)-[7:0]
  swt_fmask0_eth_vctrl(7 downto 0) :=CONV_STD_LOGIC_VECTOR(16#01#, 8);--//Разрешение прохождения пакетов направление Eth-VCTRL
  swt_fmask0_eth_vctrl(15 downto 8):=CONV_STD_LOGIC_VECTOR(16#11#, 8);--//Разрешение прохождения пакетов направление Eth-VCTRL
  swt_fmask1_eth_vctrl(7 downto 0) :=CONV_STD_LOGIC_VECTOR(16#21#, 8);--//Разрешение прохождения пакетов направление Eth-VCTRL
  swt_fmask1_eth_vctrl(15 downto 8):=CONV_STD_LOGIC_VECTOR(16#00#, 8);--//Разрешение прохождения пакетов направление Eth-VCTRL
  swt_fmask2_eth_vctrl:=(others=>'0');

  swt_fmask_eth_hdd  :='1';--//Разрешение прохождения пакетов направление Eth-HDD
  swt_fmask_eth_host :='0';--//Разрешение прохождения пакетов направление Eth-HOST


  --------------------------------
  --//Параметры модуля Тестирования
  --------------------------------
  TstData_02ver :='0';--//передовать вместо видео информации счетчик. Начинается с 1
  FrTxD_2DW_cnt :='0';--//передовать вместо видео информации счетчик. Начинается с 1
  AutoVCH_Change:='0';--//Изменение номерка видеоканала - 1/0 auto/mnl
  Pix8bit :='1';--//1 пиксель = 8 бит
  PixLen  :=CONV_STD_LOGIC_VECTOR(10#128#, 32);--(10#20#, 32);--
  RowLen  :=CONV_STD_LOGIC_VECTOR(10#016#, 32);
  --0x584  - 1412pix


  --------------------------------
  --//Параметры модуля VCTRL
  --------------------------------
  Vctrl_MemWR_trn_len :=CONV_STD_LOGIC_VECTOR(16#40#, 8); --//размер одиночной транзакции ОЗУ WRITE (DWORD)
  Vctrl_MemRD_trn_len :=CONV_STD_LOGIC_VECTOR(16#40#, 8); --//размер одиночной транзакции ОЗУ READ (DWORD)

  --//Парамеры одинаковы для всех 3-ех видеоканалов
  VctrlChParams(0).mem_addr_wr       :=CONV_STD_LOGIC_VECTOR(16#000#, 32);
  VctrlChParams(0).mem_addr_rd       :=CONV_STD_LOGIC_VECTOR(16#000#, 32);
  VctrlChParams(0).fr_subsampling    :=CONV_STD_LOGIC_VECTOR(16#000#, 2); --//Прореживание
  VctrlChParams(0).fr_size.skip.pix  :=CONV_STD_LOGIC_VECTOR(10#000#, 16);--//Начало активной зоны кадра X - значен. должно быть кратено 4
  VctrlChParams(0).fr_size.skip.row  :=CONV_STD_LOGIC_VECTOR(10#000#, 16);--//Начало активной зоны кадра Y
  VctrlChParams(0).fr_size.activ.pix :=CONV_STD_LOGIC_VECTOR(10#128#, 16);--//Размер активной зоны кадра X - значен. должно быть кратено 4
  VctrlChParams(0).fr_size.activ.row :=CONV_STD_LOGIC_VECTOR(10#008#, 16);--//Размер активной зоны кадра Y
  VctrlChParams(0).fr_mirror.pix     :='0';
  VctrlChParams(0).fr_mirror.row     :='1';
  VctrlChParams(0).fr_color_fst      :=CONV_STD_LOGIC_VECTOR(16#01#, 2);--//Первый пиксель 0/1/2 - R/G/B
  VctrlChParams(0).fr_color          :='0'; --// 1/0 - Есть/Нет цвета
  VctrlChParams(0).fr_pcolor         :='0'; --// 1/0 - Вкл/Выкл
--  VctrlChParams(0).fr_zooming_up     :=CONV_STD_LOGIC_VECTOR(16#00#, 2);

  VctrlRegTST0:=(others=>'0');
--  VctrlRegTST0(C_DSN_VCTRL_REG_TST0_DBG_PICTURE_BIT):='0';
--  VctrlRegTST0(C_DSN_VCTRL_REG_TST0_SKIPFR_CNT_CLR_BIT):='0';


  --------------------------------
  --//Параметры модуля TRACK_NIK
  --------------------------------
  TrcNik_MemWR_trn_len :=CONV_STD_LOGIC_VECTOR(16#88#, 8); --//размер одиночной транзакции ОЗУ WRITE (DWORD)
  TrcNik_MemRD_trn_len :=CONV_STD_LOGIC_VECTOR(16#80#, 8); --//размер одиночной транзакции ОЗУ READ (DWORD)

  TrcNikChParams(0).mem_arbuf:=(others=>'0');
  TrcNikChParams(0).mem_arbuf(C_DSN_VCTRL_MEM_VCH_MSB_BIT downto C_DSN_VCTRL_MEM_VCH_LSB_BIT):=CONV_STD_LOGIC_VECTOR(C_DSN_TRC_MEM_VCH, C_DSN_VCTRL_MEM_VCH_MSB_BIT - C_DSN_VCTRL_MEM_VCH_LSB_BIT +1);
  TrcNikChParams(0).mem_arbuf(C_DSN_VCTRL_MEM_VCH_LSB_BIT-1 downto 0):=(others=>'0');

  --//Интервальные уровни
  TrcNikChParams(0).ip(0).p1:=CONV_STD_LOGIC_VECTOR(16#00#, TrcNikChParams(0).ip(0).p1'length);
  TrcNikChParams(0).ip(0).p2:=CONV_STD_LOGIC_VECTOR(16#FF#, TrcNikChParams(0).ip(0).p1'length);
  TrcNikChParams(0).ip(1).p1:=CONV_STD_LOGIC_VECTOR(16#42#, TrcNikChParams(0).ip(0).p1'length);
  TrcNikChParams(0).ip(1).p2:=CONV_STD_LOGIC_VECTOR(16#FA#, TrcNikChParams(0).ip(0).p1'length);
  TrcNikChParams(0).ip(2).p1:=CONV_STD_LOGIC_VECTOR(16#10#, TrcNikChParams(0).ip(0).p1'length);
  TrcNikChParams(0).ip(2).p2:=CONV_STD_LOGIC_VECTOR(16#C0#, TrcNikChParams(0).ip(0).p1'length);
  TrcNikChParams(0).ip(3).p1:=CONV_STD_LOGIC_VECTOR(16#20#, TrcNikChParams(0).ip(0).p1'length);
  TrcNikChParams(0).ip(3).p2:=CONV_STD_LOGIC_VECTOR(16#BF#, TrcNikChParams(0).ip(0).p1'length);

  TrcNikChParams(0).opt:=(others=>'0');

  TrcNikIP_Count:=2;--//Кол-во обрабатываемых интервальных порогов
  TrcNikChParams(0).opt(C_DSN_TRCNIK_REG_OPT_SOBEL_CTRL_MULT_BIT):='1';
  TrcNikChParams(0).opt(C_DSN_TRCNIK_REG_OPT_SOBEL_CTRL_DIV_BIT):='0';
  TrcNikChParams(0).opt(C_DSN_TRCNIK_REG_OPT_DBG_IP_MSB_BIT downto C_DSN_TRCNIK_REG_OPT_DBG_IP_LSB_BIT):=CONV_STD_LOGIC_VECTOR(TrcNikIP_Count, C_DSN_TRCNIK_REG_OPT_DBG_IP_MSB_BIT-C_DSN_TRCNIK_REG_OPT_DBG_IP_LSB_BIT+1);

  TrcNikWorkOn:='1';--//Запуск работы

  TrcNikRegTST0:=(others=>'0');
  TrcNikRegTST0(C_DSN_TRC_REG_TST0_DIS_WRRESULT_BIT):='1'; --//1/0 - запретить/разрешить запись в выходной буфер m_trcbufo модкля dsn_track.vhd
--  TrcNikRegTST0(C_DSN_TRCNIK_REG_TST0_SOBEL_CTRL_DIV_BIT):='0';--//1/0 - dx/2 и dy/2 /нет делений
--  TrcNikRegTST0(C_DSN_TRCNIK_REG_TST0_SOBEL_CTRL_MULT_BIT):='1';--//1/0 - точная грубая апроксимация формуля (dx^2 + dy^2)^0.5
  TrcNikRegTST0(C_DSN_TRCNIK_REG_TST0_COLOR_DIS_BIT):='0';  --
--  TrcNikRegTST0(C_DSN_TRCNIK_REG_TST0_COLOR_DBG_BIT):='0';  --

--  --------------------------------
--  --//Параметры модуля TRACK
--  --------------------------------
--  Trc_MemWR_trn_len :=CONV_STD_LOGIC_VECTOR(16#80#, 8); --//размер одиночной транзакции ОЗУ WRITE (DWORD)
--  Trc_MemRD_trn_len :=CONV_STD_LOGIC_VECTOR(16#80#, 8); --//размер одиночной транзакции ОЗУ READ (DWORD)
--
--  TrcChParams(0).win.skip.pix:=CONV_STD_LOGIC_VECTOR(16#04#, TrcChParams(0).win.skip.pix'length);--//Начало активной зоны кадра X - значен. должно быть кратено 4
--  TrcChParams(0).win.skip.row:=CONV_STD_LOGIC_VECTOR(16#00#, TrcChParams(0).win.skip.row'length);
--  TrcChParams(0).win.activ.pix:=CONV_STD_LOGIC_VECTOR(16#08#, TrcChParams(0).win.activ.pix'length);--//Начало активной зоны кадра X - значен. должно быть кратено 4
--  TrcChParams(0).win.activ.row:=CONV_STD_LOGIC_VECTOR(16#04#, TrcChParams(0).win.activ.row'length);
--  TrcChParams(0).threshold:=CONV_STD_LOGIC_VECTOR(16#5A#, TrcChParams(0).threshold'length);
--
----  TrcChParams(0).fr_zoom_type:='0';
----  TrcChParams(0).fr_zoom:=CONV_STD_LOGIC_VECTOR(16#000#, TrcChParams(0).fr_zoom'length);
--
--  TrcChParams(0).mem_atbuf:=(others=>'0');
--  TrcChParams(0).mem_atbuf(C_DSN_VCTRL_MEM_VCH_MSB_BIT downto C_DSN_VCTRL_MEM_VCH_LSB_BIT):=CONV_STD_LOGIC_VECTOR(C_DSN_TRC_MEM_VCH, C_DSN_VCTRL_MEM_VCH_MSB_BIT - C_DSN_VCTRL_MEM_VCH_LSB_BIT +1);
--  TrcChParams(0).mem_atbuf(C_DSN_VCTRL_MEM_VFRAME_MSB_BIT downto C_DSN_VCTRL_MEM_VFRAME_LSB_BIT):=CONV_STD_LOGIC_VECTOR(C_DSN_TRC_MEM_VFR_TBUF, C_DSN_VCTRL_MEM_VFRAME_MSB_BIT-C_DSN_VCTRL_MEM_VFRAME_LSB_BIT+1);
--
--  TrcChParams(0).mem_aebuf:=(others=>'0');
--  TrcChParams(0).mem_aebuf(C_DSN_VCTRL_MEM_VCH_MSB_BIT downto C_DSN_VCTRL_MEM_VCH_LSB_BIT):=CONV_STD_LOGIC_VECTOR(C_DSN_TRC_MEM_VCH, C_DSN_VCTRL_MEM_VCH_MSB_BIT - C_DSN_VCTRL_MEM_VCH_LSB_BIT +1);
--  TrcChParams(0).mem_aebuf(C_DSN_VCTRL_MEM_VFRAME_MSB_BIT downto C_DSN_VCTRL_MEM_VFRAME_LSB_BIT):=CONV_STD_LOGIC_VECTOR(C_DSN_TRC_MEM_VFR_EBUF, C_DSN_VCTRL_MEM_VFRAME_MSB_BIT-C_DSN_VCTRL_MEM_VFRAME_LSB_BIT+1);
--
--  TrcWorkOn:='1';--//Запуск работы
--
--  TrcRegTST0:=(others=>'0');
--  TrcRegTST0(C_DSN_TRC_REG_TST0_TRCZONE_MNL_BIT):='0';   --//1/0 - Зона слежения=из параметров dsn_track.vhd / Зона слежения=VCTRL/FR_ACTIVE
--  TrcRegTST0(C_DSN_TRC_REG_TST0_DIS_WRRESULT_BIT):='0';  --//1/0 - запретить/разрешить запись в выходной буфер m_trcbufo модкля dsn_track.vhd
--  TrcRegTST0(C_DSN_TRC_REG_TST0_DIS_WRTBUF_BIT):='0';    --//1/0 -запретить/разрешить запись в RAM/TRACK/TBUF
--  TrcRegTST0(C_DSN_TRC_REG_TST0_TRCWIN_DIN_SEL_BIT):='0';--//1/0 - на вход модуля trc_win Чистые/Обработаные Собелом видео данные
--  TrcRegTST0(C_DSN_TRC_REG_TST0_TBUF_CLR_BIT):='0';      --//1 - Очистка буфера RAM/TRACK/TBUF (буфера эталона и видео соответственно)


--//Чтение данных модуля Track
  track_read_01_start:=5000;--//
  track_read_01_end  :=1400;--//

--//Чтения данных VCTRL 15us
  vctrl_read_01_start:=600;--//начало чтения Хостом модуля VCTRL
  vctrl_read_01_end  :=100;--//имитация формирования сигнала nxt_fr

--//Чтения данных VCTRL 60us
  vctrl_read_02_start:=1000;--//начало чтения Хостом модуля VCTRL
  vctrl_read_02_end  :=200; --//имитация формирования сигнала nxt_fr

--  ----------------------------------------------------------------------------------------
--  ----------------------------------------------------
--  --// Тестрование записи/чтения коэфициенитов в модуль DSN_VCTRL/VSCALE
--  --//Begin
--  i_dev_ctrl(C_HREG_DEV_CTRL_DEV_ADDR_MSB_BIT downto C_HREG_DEV_CTRL_DEV_ADDR_LSB_BIT):=CONV_STD_LOGIC_VECTOR(C_HDEV_CFG_DBUF, C_HREG_DEV_CTRL_DEV_ADDR_SIZE);
--  data(0 to 3) :=conv_byte_vector(i_dev_ctrl);
--  plxsim_write_const(C_LBUS_DATA_BITS, C_MULTBURST_OFF, (C_VM_USR_REG_BAR+CONV_STD_LOGIC_VECTOR(C_HOST_REG_DEV_CTRL*C_VM_USR_REG_BCOUNT, 32)), be(0 to 3), data(0 to 3), n, bus_in, bus_out);
--
--  --//ЗАПИСЬ
--  --//Готовим значения регистров:
--  User_Reg(0):=(others=>'0');
--  User_Reg(0)(C_DSN_VCTRL_REG_CTRL_RAMCOE_ADDR_BIT):='1'; --//будем устонавливать начальный адрес BRAM
--  User_Reg(0)(C_DSN_VCTRL_REG_CTRL_SET_BIT):='1';
--
--  datasize:=1;
--  for y in 0 to datasize - 1 loop
--    for i in 0 to 4 - 1 loop
--      data((y*4)+i)(7 downto 0) := User_Reg(y)(8*(i+1)-1 downto 8*i);
--    end loop;
--  end loop;
--
--  p_SendCfgPkt(C_WRITE, C_FIFO_OFF, C_CFGDEV_VCTRL, C_DSN_VCTRL_REG_CTRL_L, datasize, i_dev_ctrl, data, bus_in, bus_out);
--
--  --//Готовим значения:
--  User_Reg(0)(15 downto 0):=CONV_STD_LOGIC_VECTOR(0, 16);
--
--  datasize:=1;
--  for y in 0 to datasize - 1 loop
--    for i in 0 to 4 - 1 loop
--      data((y*4)+i)(7 downto 0) := User_Reg(y)(8*(i+1)-1 downto 8*i);
--    end loop;
--  end loop;
--
--  p_SendCfgPkt(C_WRITE, C_FIFO_OFF, C_CFGDEV_VCTRL, C_DSN_VCTRL_REG_PRM_DATA_LSB, datasize, i_dev_ctrl, data, bus_in, bus_out);
--
--
--  --//Готовим значения регистров:
--  User_Reg(0):=(others=>'0');
--  User_Reg(0)(C_DSN_VCTRL_REG_CTRL_RAMCOE_DATA_BIT):='1'; --//будем писать данные в BRAM
--  User_Reg(0)(C_DSN_VCTRL_REG_CTRL_SET_BIT):='1';
--
--  datasize:=1;
--  for y in 0 to datasize - 1 loop
--    for i in 0 to 4 - 1 loop
--      data((y*4)+i)(7 downto 0) := User_Reg(y)(8*(i+1)-1 downto 8*i);
--    end loop;
--  end loop;
--
--  p_SendCfgPkt(C_WRITE, C_FIFO_OFF, C_CFGDEV_VCTRL, C_DSN_VCTRL_REG_CTRL_L, datasize, i_dev_ctrl, data, bus_in, bus_out);
--
--  --//Готовим значения:
--  for i in 0 to 15 loop
--    User_Reg(i)(15 downto 0):=CONV_STD_LOGIC_VECTOR((i+1), 16);
--  end loop;
--
--  datasize:=16;
--  for y in 0 to datasize - 1 loop
--    for i in 0 to 4 - 1 loop
--      data((y*4)+i)(7 downto 0) := User_Reg(y)(8*(i+1)-1 downto 8*i);
--    end loop;
--  end loop;
--
--  p_SendCfgPkt(C_WRITE, C_FIFO_ON, C_CFGDEV_VCTRL, C_DSN_VCTRL_REG_PRM_DATA_LSB, datasize, i_dev_ctrl, data, bus_in, bus_out);
--
--  wait_cycles(10, lclk);
--
--  --//ЧТЕНИЕ
--  --//Готовим значения регистров:
--  User_Reg(0):=(others=>'0');
--  User_Reg(0)(C_DSN_VCTRL_REG_CTRL_RAMCOE_ADDR_BIT):='1'; --//будем устонавливать начальный адрес BRAM
--  User_Reg(0)(C_DSN_VCTRL_REG_CTRL_SET_BIT):='1';
--
--  datasize:=1;
--  for y in 0 to datasize - 1 loop
--    for i in 0 to 4 - 1 loop
--      data((y*4)+i)(7 downto 0) := User_Reg(y)(8*(i+1)-1 downto 8*i);
--    end loop;
--  end loop;
--
--  p_SendCfgPkt(C_WRITE, C_FIFO_OFF, C_CFGDEV_VCTRL, C_DSN_VCTRL_REG_CTRL_L, datasize, i_dev_ctrl, data, bus_in, bus_out);
--
--  --//Готовим значения для BRAM:
--  User_Reg(0)(15 downto 0):=CONV_STD_LOGIC_VECTOR(4, 16);
--
--  datasize:=1;
--  for y in 0 to datasize - 1 loop
--    for i in 0 to 4 - 1 loop
--      data((y*4)+i)(7 downto 0) := User_Reg(y)(8*(i+1)-1 downto 8*i);
--    end loop;
--  end loop;
--
--  p_SendCfgPkt(C_WRITE, C_FIFO_OFF, C_CFGDEV_VCTRL, C_DSN_VCTRL_REG_PRM_DATA_LSB, datasize, i_dev_ctrl, data, bus_in, bus_out);
--
--  --//Готовим значения регистров:
--  User_Reg(0):=(others=>'0');
--  User_Reg(0)(C_DSN_VCTRL_REG_CTRL_RAMCOE_DATA_BIT):='1'; --//будем читать данные в BRAM
--  User_Reg(0)(C_DSN_VCTRL_REG_CTRL_SET_BIT):='0';
--
--  datasize:=1;
--  for y in 0 to datasize - 1 loop
--    for i in 0 to 4 - 1 loop
--      data((y*4)+i)(7 downto 0) := User_Reg(y)(8*(i+1)-1 downto 8*i);
--    end loop;
--  end loop;
--
--  p_SendCfgPkt(C_WRITE, C_FIFO_OFF, C_CFGDEV_VCTRL, C_DSN_VCTRL_REG_CTRL_L, datasize, i_dev_ctrl, data, bus_in, bus_out);
--
--  --//Чтение :
--  datasize:=16;
--  p_SendCfgPkt(C_READ, C_FIFO_ON, C_CFGDEV_VCTRL, C_DSN_VCTRL_REG_PRM_DATA_LSB, datasize, i_dev_ctrl, data, bus_in, bus_out);
--
--  wait_cycles(400000, lclk);
--  --// Тестрование записи/чтения коэфициенитов в модуль DSN_VCTRL/VSCALE
--  --//End
--  ----------------------------------------------------
--  ----------------------------------------------------------------------------------------








  ----------------------------------------------------------------------------------------
  ----------------------------------------------------
  --// Настройка модуля DSN_TIMER.VHD
  --//Begin
  i_dev_ctrl(C_HREG_DEV_CTRL_DEV_ADDR_MSB_BIT downto C_HREG_DEV_CTRL_DEV_ADDR_LSB_BIT):=CONV_STD_LOGIC_VECTOR(C_HDEV_CFG_DBUF, C_HREG_DEV_CTRL_DEV_ADDR_SIZE);
  data(0 to 3) :=conv_byte_vector(i_dev_ctrl);
  plxsim_write_const(C_LBUS_DATA_BITS, C_MULTBURST_OFF, (C_VM_USR_REG_BAR+CONV_STD_LOGIC_VECTOR(C_HOST_REG_DEV_CTRL*C_VM_USR_REG_BCOUNT, 32)), be(0 to 3), data(0 to 3), n, bus_in, bus_out);

  --//Готовим значения регистров:
  User_Reg(0)(15 downto 0):=CONV_STD_LOGIC_VECTOR(16#0020#, 16);  --//C_DSN_TMR_REG_CMP_L
  User_Reg(1)(15 downto 0):=CONV_STD_LOGIC_VECTOR(16#0000#, 16);  --//C_DSN_TMR_REG_CMP_M

  datasize:=2;
  for y in 0 to datasize - 1 loop
    for i in 0 to 4 - 1 loop
      data((y*4)+i)(7 downto 0) := User_Reg(y)(8*(i+1)-1 downto 8*i);
    end loop;
  end loop;

  p_SendCfgPkt(C_WRITE, C_FIFO_OFF, C_CFGDEV_TMR, C_DSN_TMR_REG_CMP_L, datasize, i_dev_ctrl, data, bus_in, bus_out);

  --//Готовим значения регистров:
  User_Reg(0)(15 downto 0):=(others=>'0');  --//C_DSN_TMR_REG_CTRL
  User_Reg(0)(C_DSN_TMR_REG_CTRL_EN_BIT):='1';
  datasize:=1;
  for y in 0 to datasize - 1 loop
    for i in 0 to 4 - 1 loop
      data((y*4)+i)(7 downto 0) := User_Reg(y)(8*(i+1)-1 downto 8*i);
    end loop;
  end loop;

  p_SendCfgPkt(C_WRITE, C_FIFO_OFF, C_CFGDEV_TMR, C_DSN_TMR_REG_CTRL, datasize, i_dev_ctrl, data, bus_in, bus_out);

  wait_cycles(4, lclk);
  --// Настройка модуля DSN_TIMER.VHD
  --//End
  ----------------------------------------------------
  ----------------------------------------------------------------------------------------

  ----------------------------------------------------------------------------------------
  ----------------------------------------------------
  --// Настройка модуля DSN_SWITCH.VHD
  --//Begin
  i_dev_ctrl(C_HREG_DEV_CTRL_DEV_ADDR_MSB_BIT downto C_HREG_DEV_CTRL_DEV_ADDR_LSB_BIT):=CONV_STD_LOGIC_VECTOR(C_HDEV_CFG_DBUF, C_HREG_DEV_CTRL_DEV_ADDR_SIZE);
  data(0 to 3) :=conv_byte_vector(i_dev_ctrl);
  plxsim_write_const(C_LBUS_DATA_BITS, C_MULTBURST_OFF, (C_VM_USR_REG_BAR+CONV_STD_LOGIC_VECTOR(C_HOST_REG_DEV_CTRL*C_VM_USR_REG_BCOUNT, 32)), be(0 to 3), data(0 to 3), n, bus_in, bus_out);


  --//Готовим значения регистров:
  --//C_DSN_SWT_REG_CTRL_L
  User_Reg(0)(15 downto 0):=CONV_STD_LOGIC_VECTOR(16#5555#, 16);
  User_Reg(1)(15 downto 0):=CONV_STD_LOGIC_VECTOR(16#AAAA#, 16);

  datasize:=2;
  for y in 0 to datasize - 1 loop
    for i in 0 to 4 - 1 loop
      data((y*4)+i)(7 downto 0) := User_Reg(y)(8*(i+1)-1 downto 8*i);
    end loop;
  end loop;

  p_SendCfgPkt(C_WRITE, C_FIFO_OFF, C_CFGDEV_SWT, C_DSN_SWT_REG_TST0, datasize, i_dev_ctrl, data, bus_in, bus_out);

--  datasize:=2;
--  p_SendCfgPkt(C_READ, C_FIFO_OFF, C_CFGDEV_SWT, C_DSN_SWT_REG_TST0, datasize, i_dev_ctrl, data, bus_in, bus_out);
--
--  wait_cycles(4000000, lclk);

  --//Готовим значения регистров:
  --//C_DSN_SWT_REG_CTRL_L
  User_Reg(0):=(others=>'0');
  User_Reg(0)(C_DSN_SWT_REG_CTRL_TSTDSN_TO_ETHTX_BIT):='0';

  datasize:=1;
  for y in 0 to datasize - 1 loop
    for i in 0 to 4 - 1 loop
      data((y*4)+i)(7 downto 0) := User_Reg(y)(8*(i+1)-1 downto 8*i);
    end loop;
  end loop;

  p_SendCfgPkt(C_WRITE, C_FIFO_OFF, C_CFGDEV_SWT, C_DSN_SWT_REG_CTRL_L, datasize, i_dev_ctrl, data, bus_in, bus_out);

  --//C_DSN_SWT_REG_FMASK_ETHG_HOST
  User_Reg(0)(0):=swt_fmask_eth_host; --//Маска(1)-[15:8];  Маска(0)-[7:0]
  User_Reg(0)(15 downto 1):=(others=>'0'); --//Маска(1)-[15:8];  Маска(0)-[7:0]
  User_Reg(1)(15 downto 0):=(others=>'0'); --//Маска(3)-[15:8];  Маска(2)-[7:0]
  User_Reg(2)(15 downto 0):=(others=>'0'); --//Маска(5)-[15:8];  Маска(4)-[7:0]

  datasize:=3;
  for y in 0 to datasize - 1 loop
    for i in 0 to 4 - 1 loop
      data((y*4)+i)(7 downto 0) := User_Reg(y)(8*(i+1)-1 downto 8*i);
    end loop;
  end loop;

  p_SendCfgPkt(C_WRITE, C_FIFO_OFF, C_CFGDEV_SWT, C_DSN_SWT_REG_FMASK_ETHG_HOST, datasize, i_dev_ctrl, data, bus_in, bus_out);

  wait_cycles(4, lclk);

  --//C_DSN_SWT_REG_FMASK_ETHG_HDD
  User_Reg(0)(15 downto 0):=CONV_STD_LOGIC_VECTOR(16#0000#, 16); --//Маска(1)-[15:8];  Маска(0)-[7:0]
  User_Reg(1)(15 downto 0):=CONV_STD_LOGIC_VECTOR(16#0000#, 16); --//Маска(3)-[15:8];  Маска(2)-[7:0]
  User_Reg(2)(15 downto 0):=CONV_STD_LOGIC_VECTOR(16#0000#, 16); --//Маска(5)-[15:8];  Маска(4)-[7:0]

  datasize:=3;
  for y in 0 to datasize - 1 loop
    for i in 0 to 4 - 1 loop
      data((y*4)+i)(7 downto 0) := User_Reg(y)(8*(i+1)-1 downto 8*i);
    end loop;
  end loop;

  p_SendCfgPkt(C_WRITE, C_FIFO_OFF, C_CFGDEV_SWT, C_DSN_SWT_REG_FMASK_ETHG_HDD, datasize, i_dev_ctrl, data, bus_in, bus_out);

  wait_cycles(4, lclk);

  --//C_DSN_SWT_REG_FMASK_ETHG_VCTRL
  User_Reg(0)(15 downto 0):=CONV_STD_LOGIC_VECTOR(16#0000#, 16); --//Маска(1)-[15:8];  Маска(0)-[7:0]
  User_Reg(1)(15 downto 0):=CONV_STD_LOGIC_VECTOR(16#0000#, 16); --//Маска(3)-[15:8];  Маска(2)-[7:0]
  User_Reg(2)(15 downto 0):=CONV_STD_LOGIC_VECTOR(16#0000#, 16); --//Маска(5)-[15:8];  Маска(4)-[7:0]

  datasize:=3;
  for y in 0 to datasize - 1 loop
    for i in 0 to 4 - 1 loop
      data((y*4)+i)(7 downto 0) := User_Reg(y)(8*(i+1)-1 downto 8*i);
    end loop;
  end loop;

  p_SendCfgPkt(C_WRITE, C_FIFO_OFF, C_CFGDEV_SWT, C_DSN_SWT_REG_FMASK_ETHG_VCTRL, datasize, i_dev_ctrl, data, bus_in, bus_out);

  wait_cycles(4, lclk);
  --// Настройка модуля DSN_SWITCH.VHD
  --//End
  ----------------------------------------------------
  ----------------------------------------------------------------------------------------

  ----------------------------------------------------------------------------------------
  ----------------------------------------------------
  --// Настройка модуля DSN_ETH.VHD
  --//Begin
  i_dev_ctrl(C_HREG_DEV_CTRL_DEV_ADDR_MSB_BIT downto C_HREG_DEV_CTRL_DEV_ADDR_LSB_BIT):=CONV_STD_LOGIC_VECTOR(C_HDEV_CFG_DBUF, C_HREG_DEV_CTRL_DEV_ADDR_SIZE);
  data(0 to 3) :=conv_byte_vector(i_dev_ctrl);
  plxsim_write_const(C_LBUS_DATA_BITS, C_MULTBURST_OFF, (C_VM_USR_REG_BAR+CONV_STD_LOGIC_VECTOR(C_HOST_REG_DEV_CTRL*C_VM_USR_REG_BCOUNT, 32)), be(0 to 3), data(0 to 3), n, bus_in, bus_out);

  --//Готовим значения регистров:
  User_Reg(0)(15 downto 0):=CONV_STD_LOGIC_VECTOR(10#0#, 16); --//C_DSN_ETHG_REG_CTRL_L
  User_Reg(0)(C_DSN_ETHG_REG_CTRL_GTP_NORTH_MUX_CNG_BIT):='0';--//Тестируем запись этого бита

  datasize:=1;
  for y in 0 to datasize - 1 loop
    for i in 0 to 4 - 1 loop
      data((y*4)+i)(7 downto 0) := User_Reg(y)(8*(i+1)-1 downto 8*i);
    end loop;
  end loop;

  p_SendCfgPkt(C_WRITE, C_FIFO_OFF, C_CFGDEV_ETHG, C_DSN_ETHG_REG_CTRL_L, datasize, i_dev_ctrl, data, bus_in, bus_out);

  wait_cycles(4, lclk);

  --//Готовим значения регистров:
  User_Reg(0)(15 downto 0):=CONV_STD_LOGIC_VECTOR(10#0#, 16);  --//C_DSN_ETHG_REG_MAC_USRCTRL
--  User_Reg(0)(C_DSN_ETHG_REG_MAC_TX_PATRN_SIZE_MSB_BIT downto C_DSN_ETHG_REG_MAC_TX_PATRN_SIZE_LSB_BIT):=CONV_STD_LOGIC_VECTOR(10#12#, 4);--(10#14#, 4);--//C_DSN_ETHG_REG_TX_PATRN_PARAM
--  User_Reg(0)(C_DSN_ETHG_REG_MAC_RX_PATRN_SIZE_MSB_BIT downto C_DSN_ETHG_REG_MAC_RX_PATRN_SIZE_LSB_BIT):=CONV_STD_LOGIC_VECTOR(10#12#, 4);--(10#14#, 4);--//C_DSN_ETHG_REG_TX_PATRN_PARAM
----  User_Reg(0)(C_DSN_ETHG_REG_MAC_RX_SWAP_BYTE_BIT):='0';--//Старшим байтом вперед
--  User_Reg(0)(C_DSN_ETHG_REG_MAC_RX_SWAP_BYTE_BIT):='0';--//Младшим байтом вперед
--  User_Reg(0)(C_DSN_ETHG_REG_MAC_RX_PADDING_CLR_DIS_BIT):='0';--//Запрещение


--  User_Reg(1)(15 downto 0):=CONV_STD_LOGIC_VECTOR(16#0001#, 16);  --//C_DSN_ETHG_REG_TX_PATRN0 - MAC DST (MULTICAST)
--  User_Reg(2)(15 downto 0):=CONV_STD_LOGIC_VECTOR(16#015E#, 16);  --//C_DSN_ETHG_REG_TX_PATRN1
--  User_Reg(3)(15 downto 0):=CONV_STD_LOGIC_VECTOR(16#0B01#, 16);  --//C_DSN_ETHG_REG_TX_PATRN2
--  User_Reg(1)(15 downto 0):=CONV_STD_LOGIC_VECTOR(16#FFFF#, 16);  --//C_DSN_ETHG_REG_TX_PATRN0 - MAC DST (BROADCAST)
--  User_Reg(2)(15 downto 0):=CONV_STD_LOGIC_VECTOR(16#FFFF#, 16);  --//C_DSN_ETHG_REG_TX_PATRN1
--  User_Reg(3)(15 downto 0):=CONV_STD_LOGIC_VECTOR(16#FFFF#, 16);  --//C_DSN_ETHG_REG_TX_PATRN2
  User_Reg(1)(15 downto 0):=CONV_STD_LOGIC_VECTOR(16#B5B6#, 16);  --//C_DSN_ETHG_REG_TX_PATRN0 - MAC DST
  User_Reg(2)(15 downto 0):=CONV_STD_LOGIC_VECTOR(16#B3B4#, 16);  --//C_DSN_ETHG_REG_TX_PATRN1
  User_Reg(3)(15 downto 0):=CONV_STD_LOGIC_VECTOR(16#B1B2#, 16);  --//C_DSN_ETHG_REG_TX_PATRN2
  User_Reg(4)(15 downto 0):=CONV_STD_LOGIC_VECTOR(16#B5B6#, 16);  --//C_DSN_ETHG_REG_TX_PATRN3 - MAC SRC
  User_Reg(5)(15 downto 0):=CONV_STD_LOGIC_VECTOR(16#B3B4#, 16);  --//C_DSN_ETHG_REG_TX_PATRN4
  User_Reg(6)(15 downto 0):=CONV_STD_LOGIC_VECTOR(16#B1B2#, 16);  --//C_DSN_ETHG_REG_TX_PATRN5
  User_Reg(7)(15 downto 0):=CONV_STD_LOGIC_VECTOR(16#0D0C#, 16);  --//C_DSN_ETHG_REG_TX_PATRN6 - MAC Length/Type

  datasize:=8;
  for y in 0 to datasize - 1 loop
    for i in 0 to 4 - 1 loop
      data((y*4)+i)(7 downto 0) := User_Reg(y)(8*(i+1)-1 downto 8*i);
    end loop;
  end loop;

  p_SendCfgPkt(C_WRITE, C_FIFO_OFF, C_CFGDEV_ETHG, C_DSN_ETHG_REG_MAC_USRCTRL, datasize, i_dev_ctrl, data, bus_in, bus_out);

  wait_cycles(4, lclk);
  --// Настройка модуля DSN_ETH.VHD
  --//End
  ----------------------------------------------------
  ----------------------------------------------------------------------------------------

  ----------------------------------------------------------------------------------------
  ----------------------------------------------------
  --// Запись в буфер SWT HOST-Eth TX
  --//Begin
  i_dev_ctrl(C_HREG_DEV_CTRL_DEV_ADDR_MSB_BIT downto C_HREG_DEV_CTRL_DEV_ADDR_LSB_BIT):=CONV_STD_LOGIC_VECTOR(C_HDEV_ETHG_DBUF, C_HREG_DEV_CTRL_DEV_ADDR_SIZE);
  data(0 to 3) :=conv_byte_vector(i_dev_ctrl);
  plxsim_write_const(C_LBUS_DATA_BITS, C_MULTBURST_OFF, (C_VM_USR_REG_BAR+CONV_STD_LOGIC_VECTOR(C_HOST_REG_DEV_CTRL*C_VM_USR_REG_BCOUNT, 32)), be(0 to 3), data(0 to 3), n, bus_in, bus_out);

  eth_usrtxpkt_size:=7;    --//Размер передоваемых данных(txdata) (в байтах)
  User_Reg(0)(15 downto  0):=CONV_STD_LOGIC_VECTOR(eth_usrtxpkt_size, 16);    --//Размер передоваемых данных(txdata) (в байтах)
  User_Reg(0)(31 downto 16):=CONV_STD_LOGIC_VECTOR(16#0201#, 16);    --//txdata
  User_Reg(1)(31 downto 0 ):=CONV_STD_LOGIC_VECTOR(16#06050403#, 32);--//txdata
  User_Reg(2)(31 downto 0 ):=CONV_STD_LOGIC_VECTOR(16#0A090807#, 32);--//txdata

  eth_usrtxpkt_size:=8;    --//Размер передоваемых данных(txdata) (в байтах)
  User_Reg(3)(15 downto  0):=CONV_STD_LOGIC_VECTOR(eth_usrtxpkt_size, 16);    --//Размер передоваемых данных(txdata) (в байтах)
  User_Reg(3)(31 downto 16):=CONV_STD_LOGIC_VECTOR(16#0807#, 16);    --//txdata
  User_Reg(4)(31 downto 0 ):=CONV_STD_LOGIC_VECTOR(16#0C0B0A09#, 32);--//txdata
  User_Reg(5)(31 downto 0 ):=CONV_STD_LOGIC_VECTOR(16#1211100D#, 32);--//txdata

  datasize:=6;
  for y in 0 to datasize - 1 loop
    for i in 0 to 4 - 1 loop
      data((y*4)+i)(7 downto 0) := User_Reg(y)(8*(i+1)-1 downto 8*i);
    end loop;
  end loop;
  p_SendMasDATA(datasize, i_dev_ctrl, data, bus_in, bus_out);



  wait_cycles(128, lclk);
  --// Запись в буфер SWT HOST-Eth TX
  --//End
  ----------------------------------------------------
  ----------------------------------------------------------------------------------------



  ----------------------------------------------------------------------------------------
  ----------------------------------------------------
  --// Настройка модуля DSN_SWITCH.VHD
  --//Begin
  i_dev_ctrl(C_HREG_DEV_CTRL_DEV_ADDR_MSB_BIT downto C_HREG_DEV_CTRL_DEV_ADDR_LSB_BIT):=CONV_STD_LOGIC_VECTOR(C_HDEV_CFG_DBUF, C_HREG_DEV_CTRL_DEV_ADDR_SIZE);
  data(0 to 3) :=conv_byte_vector(i_dev_ctrl);
  plxsim_write_const(C_LBUS_DATA_BITS, C_MULTBURST_OFF, (C_VM_USR_REG_BAR+CONV_STD_LOGIC_VECTOR(C_HOST_REG_DEV_CTRL*C_VM_USR_REG_BCOUNT, 32)), be(0 to 3), data(0 to 3), n, bus_in, bus_out);

  --//Готовим значения регистров:
  --//C_DSN_SWT_REG_CTRL_L
  User_Reg(0):=(others=>'0');
  User_Reg(0)(C_DSN_SWT_REG_CTRL_TSTDSN_TO_ETHTX_BIT)   :=swt_dsntesting_to_ethtxbuf;
  User_Reg(0)(C_DSN_SWT_REG_CTRL_TSTDSN_TO_VCTRL_BUFIN_BIT):=swt_ethtxbuf_to_vdbufrxd;
  User_Reg(0)(C_DSN_SWT_REG_CTRL_TSTDSN_TO_HDDBUF_BIT):=swt_ethtxbuf_to_hddbuf;

  datasize:=1;
  for y in 0 to datasize - 1 loop
    for i in 0 to 4 - 1 loop
      data((y*4)+i)(7 downto 0) := User_Reg(y)(8*(i+1)-1 downto 8*i);
    end loop;
  end loop;

  p_SendCfgPkt(C_WRITE, C_FIFO_OFF, C_CFGDEV_SWT, C_DSN_SWT_REG_CTRL_L, datasize, i_dev_ctrl, data, bus_in, bus_out);


  --//C_DSN_SWT_REG_FMASK_ETHG_HOST
  User_Reg(0)(0):=swt_fmask_eth_host; --//Маска(1)-[15:8];  Маска(0)-[7:0]
  User_Reg(0)(15 downto 1):=(others=>'0'); --//Маска(1)-[15:8];  Маска(0)-[7:0]
  User_Reg(1)(15 downto 0):=(others=>'0'); --//Маска(3)-[15:8];  Маска(2)-[7:0]
  User_Reg(2)(15 downto 0):=(others=>'0'); --//Маска(5)-[15:8];  Маска(4)-[7:0]

  datasize:=3;
  for y in 0 to datasize - 1 loop
    for i in 0 to 4 - 1 loop
      data((y*4)+i)(7 downto 0) := User_Reg(y)(8*(i+1)-1 downto 8*i);
    end loop;
  end loop;

  p_SendCfgPkt(C_WRITE, C_FIFO_OFF, C_CFGDEV_SWT, C_DSN_SWT_REG_FMASK_ETHG_HOST, datasize, i_dev_ctrl, data, bus_in, bus_out);

  wait_cycles(4, lclk);

  --//C_DSN_SWT_REG_FMASK_ETHG_HDD
  User_Reg(0)(0):=swt_fmask_eth_hdd; --//Маска(1)-[15:8];  Маска(0)-[7:0]
  User_Reg(0)(15 downto 1):=(others=>'0'); --//Маска(1)-[15:8];  Маска(0)-[7:0]
  User_Reg(1)(15 downto 0):=(others=>'0'); --//Маска(3)-[15:8];  Маска(2)-[7:0]
  User_Reg(2)(15 downto 0):=(others=>'0'); --//Маска(5)-[15:8];  Маска(4)-[7:0]

  datasize:=3;
  for y in 0 to datasize - 1 loop
    for i in 0 to 4 - 1 loop
      data((y*4)+i)(7 downto 0) := User_Reg(y)(8*(i+1)-1 downto 8*i);
    end loop;
  end loop;

  p_SendCfgPkt(C_WRITE, C_FIFO_OFF, C_CFGDEV_SWT, C_DSN_SWT_REG_FMASK_ETHG_HDD, datasize, i_dev_ctrl, data, bus_in, bus_out);

  wait_cycles(4, lclk);

  --//C_DSN_SWT_REG_FMASK_ETHG_VCTRL
  User_Reg(0)(15 downto 0):=swt_fmask0_eth_vctrl; --//Маска(1)-[15:8];  Маска(0)-[7:0]
  User_Reg(1)(15 downto 0):=swt_fmask1_eth_vctrl; --//Маска(3)-[15:8];  Маска(2)-[7:0]
  User_Reg(2)(15 downto 0):=swt_fmask2_eth_vctrl; --//Маска(5)-[15:8];  Маска(4)-[7:0]

  datasize:=3;
  for y in 0 to datasize - 1 loop
    for i in 0 to 4 - 1 loop
      data((y*4)+i)(7 downto 0) := User_Reg(y)(8*(i+1)-1 downto 8*i);
    end loop;
  end loop;

  p_SendCfgPkt(C_WRITE, C_FIFO_OFF, C_CFGDEV_SWT, C_DSN_SWT_REG_FMASK_ETHG_VCTRL, datasize, i_dev_ctrl, data, bus_in, bus_out);

  wait_cycles(4, lclk);


  wait_cycles(4, lclk);
  --// Настройка модуля DSN_SWITCH.VHD
  --//End
  ----------------------------------------------------
  ----------------------------------------------------------------------------------------



  ----------------------------------------------------------------------------------------
  ----------------------------------------------------
  --// Настройка модуля DSN_TESTING.VHD
  --//Begin
  i_dev_ctrl(C_HREG_DEV_CTRL_DEV_ADDR_MSB_BIT downto C_HREG_DEV_CTRL_DEV_ADDR_LSB_BIT):=CONV_STD_LOGIC_VECTOR(C_HDEV_CFG_DBUF, C_HREG_DEV_CTRL_DEV_ADDR_SIZE);
  data(0 to 3) :=conv_byte_vector(i_dev_ctrl);
  plxsim_write_const(C_LBUS_DATA_BITS, C_MULTBURST_OFF, (C_VM_USR_REG_BAR+CONV_STD_LOGIC_VECTOR(C_HOST_REG_DEV_CTRL*C_VM_USR_REG_BCOUNT, 32)), be(0 to 3), data(0 to 3), n, bus_in, bus_out);

  --//Готовим значения регистров:
--constant C_DSN_TSTING_REG_CTRLM_FRAME_MOVE_LSB_BIT: integer:=0;
--constant C_DSN_TSTING_REG_CTRLM_FRAME_MOVE_MSB_BIT: integer:=6;
  User_Reg(0)(15 downto 0):=CONV_STD_LOGIC_VECTOR(16#01#, 16);  --//C_DSN_TSTING_REG_CTRL_M (Framve Move)

  datasize:=1;
  for y in 0 to datasize - 1 loop
    for i in 0 to 4 - 1 loop
      data((y*4)+i)(7 downto 0) := User_Reg(y)(8*(i+1)-1 downto 8*i);
    end loop;
  end loop;

  p_SendCfgPkt(C_WRITE, C_FIFO_OFF, C_CFGDEV_TESTING, C_DSN_TSTING_REG_CTRL_M, datasize, i_dev_ctrl, data, bus_in, bus_out);

--  if Pix8bit='1' then
--    User_Reg(0)(15 downto 0):=("00"&PixLen(15 downto 2))-1;  --//C_DSN_TSTING_REG_PIX
--  else
--    User_Reg(0)(15 downto 0):=PixLen(15 downto 0)-1;  --//C_DSN_TSTING_REG_PIX
--  end if;
--
--  User_Reg(1)(15 downto 0):=RowLen(15 downto 0)-1;  --//C_DSN_TSTING_REG_ROW

  if Pix8bit='1' then
    User_Reg(0)(15 downto 0):=("00"&PixLen(15 downto 2));  --//C_DSN_TSTING_REG_PIX
  else
    User_Reg(0)(15 downto 0):=PixLen(15 downto 0);  --//C_DSN_TSTING_REG_PIX
  end if;

  User_Reg(1)(15 downto 0):=RowLen(15 downto 0);  --//C_DSN_TSTING_REG_ROW

  i_FrameSize:=(CONV_STD_LOGIC_VECTOR(16#00#, 16)&(User_Reg(0)(15 downto 0)+1)) * (CONV_STD_LOGIC_VECTOR(16#00#, 16)&(User_Reg(1)(15 downto 0)+1));

  User_Reg(2)(15 downto 0):=i_FrameSize(15 downto 0);           --//C_DSN_TSTING_REG_FRAME_SIZE_LSB
  User_Reg(3)(15 downto 0):=i_FrameSize(31 downto 16);          --//C_DSN_TSTING_REG_FRAME_SIZE_MSB
  User_Reg(4)(15 downto 0):=User_Reg(0)(15 downto 0)+1;--PixLen(15 downto 0);--CONV_STD_LOGIC_VECTOR(16#80#, 16);  --//C_DSN_TSTING_REG_PKTLEN - Len Payload(Без учета длинны заголовка)
  User_Reg(5)(15 downto 0):=CONV_STD_LOGIC_VECTOR(16#00#, 16);  --//C_DSN_TSTING_REG_ROW_SEND_TIME_DLY
  User_Reg(6)(15 downto 0):=CONV_STD_LOGIC_VECTOR(16#02#, 16);  --//C_DSN_TSTING_REG_FR_SEND_TIME_DLY

  datasize:=7;
  for y in 0 to datasize - 1 loop
    for i in 0 to 4 - 1 loop
      data((y*4)+i)(7 downto 0) := User_Reg(y)(8*(i+1)-1 downto 8*i);
    end loop;
  end loop;

  p_SendCfgPkt(C_WRITE, C_FIFO_OFF, C_CFGDEV_TESTING, C_DSN_TSTING_REG_PIX, datasize, i_dev_ctrl, data, bus_in, bus_out);


  User_Reg(0)(15 downto 0):=CONV_STD_LOGIC_VECTOR(10#0000#, 16);  --//C_DSN_TSTING_REG_COLOR_LSB
  User_Reg(1)(15 downto 0):=CONV_STD_LOGIC_VECTOR(10#0000#, 16);  --//C_DSN_TSTING_REG_COLOR_MSB

  datasize:=2;
  for y in 0 to datasize - 1 loop
    for i in 0 to 4 - 1 loop
      data((y*4)+i)(7 downto 0) := User_Reg(y)(8*(i+1)-1 downto 8*i);
    end loop;
  end loop;

  p_SendCfgPkt(C_WRITE, C_FIFO_OFF, C_CFGDEV_TESTING, C_DSN_TSTING_REG_COLOR_LSB, datasize, i_dev_ctrl, data, bus_in, bus_out);

  wait_cycles(4, lclk);
  --// Настройка модуля DSN_TESTING.VHD
  --//End
  ----------------------------------------------------
  ----------------------------------------------------------------------------------------

  ----------------------------------------------------------------------------------------
  ----------------------------------------------------
  --// Настройка модуля DSN_VIDEO_CTRL.VHD
  --//Begin
  i_dev_ctrl(C_HREG_DEV_CTRL_DEV_ADDR_MSB_BIT downto C_HREG_DEV_CTRL_DEV_ADDR_LSB_BIT):=CONV_STD_LOGIC_VECTOR(C_HDEV_CFG_DBUF, C_HREG_DEV_CTRL_DEV_ADDR_SIZE);
  data(0 to 3) :=conv_byte_vector(i_dev_ctrl);
  plxsim_write_const(C_LBUS_DATA_BITS, C_MULTBURST_OFF, (C_VM_USR_REG_BAR+CONV_STD_LOGIC_VECTOR(C_HOST_REG_DEV_CTRL*C_VM_USR_REG_BCOUNT, 32)), be(0 to 3), data(0 to 3), n, bus_in, bus_out);


  --//Установка C_DSN_VCTRL_REG_MEM_TRN_LEN
  --//Готовим значения регистров:
  User_Reg(0)(7 downto 0) :=Vctrl_MemWR_trn_len;--CONV_STD_LOGIC_VECTOR(16#10#, 8); --//WRITE
  User_Reg(0)(15 downto 8):=Vctrl_MemRD_trn_len;--CONV_STD_LOGIC_VECTOR(16#10#, 8); --//READ

  datasize:=1;
  for y in 0 to datasize - 1 loop
    for i in 0 to 4 - 1 loop
      data((y*4)+i)(7 downto 0) := User_Reg(y)(8*(i+1)-1 downto 8*i);
    end loop;
  end loop;

  p_SendCfgPkt(C_WRITE, C_FIFO_OFF, C_CFGDEV_VCTRL, C_DSN_VCTRL_REG_MEM_TRN_LEN, datasize, i_dev_ctrl, data, bus_in, bus_out);


  --//Параметры VCH0
  --//Установка адреса записи в ОЗУ
  --//Готовим значения регистров:
  User_Reg(0)(15 downto 0):=VctrlChParams(0).mem_addr_wr(15 downto 0);--;--CONV_STD_LOGIC_VECTOR(16#0000#, 16);  --//C_DSN_VCTRL_REG_PRM_DATA_LSB
  User_Reg(1)(15 downto 0):=VctrlChParams(0).mem_addr_wr(31 downto 16);--;--CONV_STD_LOGIC_VECTOR(16#0000#, 16);  --//C_DSN_VCTRL_REG_PRM_DATA_MSB
--  User_Reg(0)(15 downto 0):=EXT(VctrlChParams(0).mem_addr_wr, 16);
--  User_Reg(1)(15 downto 0):=(Others=>'0');

  datasize:=2;
  for y in 0 to datasize - 1 loop
    for i in 0 to 4 - 1 loop
      data((y*4)+i)(7 downto 0) := User_Reg(y)(8*(i+1)-1 downto 8*i);
    end loop;
  end loop;

  p_SendCfgPkt(C_WRITE, C_FIFO_OFF, C_CFGDEV_VCTRL, C_DSN_VCTRL_REG_PRM_DATA_LSB, datasize, i_dev_ctrl, data, bus_in, bus_out);

  --//Готовим значения регистров:
  User_Reg(0)(C_DSN_VCTRL_REG_CTRL_CH_IDX_MSB_BIT downto C_DSN_VCTRL_REG_CTRL_CH_IDX_LSB_BIT)  :=CONV_STD_LOGIC_VECTOR(16#00#, C_DSN_VCTRL_REG_CTRL_CH_IDX_MSB_BIT-C_DSN_VCTRL_REG_CTRL_CH_IDX_LSB_BIT+1);
  User_Reg(0)(C_DSN_VCTRL_REG_CTRL_PRM_IDX_MSB_BIT downto C_DSN_VCTRL_REG_CTRL_PRM_IDX_LSB_BIT):=CONV_STD_LOGIC_VECTOR(C_DSN_VCTRL_PRM_MEM_ADDR_WR, C_DSN_VCTRL_REG_CTRL_PRM_IDX_MSB_BIT-C_DSN_VCTRL_REG_CTRL_PRM_IDX_LSB_BIT+1);
  User_Reg(0)(C_DSN_VCTRL_REG_CTRL_SET_BIT):='1';

  datasize:=1;
  for y in 0 to datasize - 1 loop
    for i in 0 to 4 - 1 loop
      data((y*4)+i)(7 downto 0) := User_Reg(y)(8*(i+1)-1 downto 8*i);
    end loop;
  end loop;

  p_SendCfgPkt(C_WRITE, C_FIFO_OFF, C_CFGDEV_VCTRL, C_DSN_VCTRL_REG_CTRL_L, datasize, i_dev_ctrl, data, bus_in, bus_out);

  --//Установка адреса чтния в ОЗУ
  --//Готовим значения регистров:
  User_Reg(0)(15 downto 0):=VctrlChParams(0).mem_addr_rd(15 downto 0);--(15 downto 0);--CONV_STD_LOGIC_VECTOR(16#0000#, 16);  --//C_DSN_VCTRL_REG_PRM_DATA_LSB
  User_Reg(1)(15 downto 0):=VctrlChParams(0).mem_addr_rd(31 downto 16);--(31 downto 16);--CONV_STD_LOGIC_VECTOR(16#0100#, 16);  --//C_DSN_VCTRL_REG_PRM_DATA_MSB

  datasize:=2;
  for y in 0 to datasize - 1 loop
    for i in 0 to 4 - 1 loop
      data((y*4)+i)(7 downto 0) := User_Reg(y)(8*(i+1)-1 downto 8*i);
    end loop;
  end loop;

  p_SendCfgPkt(C_WRITE, C_FIFO_OFF, C_CFGDEV_VCTRL, C_DSN_VCTRL_REG_PRM_DATA_LSB, datasize, i_dev_ctrl, data, bus_in, bus_out);

  --//Готовим значения регистров:
  User_Reg(0)(C_DSN_VCTRL_REG_CTRL_CH_IDX_MSB_BIT downto C_DSN_VCTRL_REG_CTRL_CH_IDX_LSB_BIT)  :=CONV_STD_LOGIC_VECTOR(16#00#, C_DSN_VCTRL_REG_CTRL_CH_IDX_MSB_BIT-C_DSN_VCTRL_REG_CTRL_CH_IDX_LSB_BIT+1);
  User_Reg(0)(C_DSN_VCTRL_REG_CTRL_PRM_IDX_MSB_BIT downto C_DSN_VCTRL_REG_CTRL_PRM_IDX_LSB_BIT):=CONV_STD_LOGIC_VECTOR(C_DSN_VCTRL_PRM_MEM_ADDR_RD, C_DSN_VCTRL_REG_CTRL_PRM_IDX_MSB_BIT-C_DSN_VCTRL_REG_CTRL_PRM_IDX_LSB_BIT+1);
  User_Reg(0)(C_DSN_VCTRL_REG_CTRL_SET_BIT):='1';

  datasize:=1;
  for y in 0 to datasize - 1 loop
    for i in 0 to 4 - 1 loop
      data((y*4)+i)(7 downto 0) := User_Reg(y)(8*(i+1)-1 downto 8*i);
    end loop;
  end loop;

  p_SendCfgPkt(C_WRITE, C_FIFO_OFF, C_CFGDEV_VCTRL, C_DSN_VCTRL_REG_CTRL_L, datasize, i_dev_ctrl, data, bus_in, bus_out);

  --//Установка FR_OPTIONS
  --//Готовим значения регистров:
  User_Reg(0):=(others=>'0');
--  User_Reg(0)(1 downto 0):=VctrlChParams(0).fr_subsampling.pix;--CONV_STD_LOGIC_VECTOR(10#00#, 2);  --//Pix
  User_Reg(0)(3 downto 2):=VctrlChParams(0).fr_subsampling;--.row;--CONV_STD_LOGIC_VECTOR(10#00#, 2);  --//Row
  User_Reg(0)(4)         :=VctrlChParams(0).fr_mirror.pix;
  User_Reg(0)(5)         :=VctrlChParams(0).fr_mirror.row;
  User_Reg(0)(6)         :=VctrlChParams(0).fr_color_fst(0);
  User_Reg(0)(7)         :=VctrlChParams(0).fr_color_fst(1);
  User_Reg(0)(8)         :=VctrlChParams(0).fr_pcolor;
  User_Reg(0)(14)        :=VctrlChParams(0).fr_color;

  datasize:=1;
  for y in 0 to datasize - 1 loop
    for i in 0 to 4 - 1 loop
      data((y*4)+i)(7 downto 0) := User_Reg(y)(8*(i+1)-1 downto 8*i);
    end loop;
  end loop;

  p_SendCfgPkt(C_WRITE, C_FIFO_OFF, C_CFGDEV_VCTRL, C_DSN_VCTRL_REG_PRM_DATA_LSB, datasize, i_dev_ctrl, data, bus_in, bus_out);

  --//Готовим значения регистров:
  User_Reg(0)(C_DSN_VCTRL_REG_CTRL_CH_IDX_MSB_BIT downto C_DSN_VCTRL_REG_CTRL_CH_IDX_LSB_BIT)  :=CONV_STD_LOGIC_VECTOR(16#00#, C_DSN_VCTRL_REG_CTRL_CH_IDX_MSB_BIT-C_DSN_VCTRL_REG_CTRL_CH_IDX_LSB_BIT+1);
  User_Reg(0)(C_DSN_VCTRL_REG_CTRL_PRM_IDX_MSB_BIT downto C_DSN_VCTRL_REG_CTRL_PRM_IDX_LSB_BIT):=CONV_STD_LOGIC_VECTOR(C_DSN_VCTRL_PRM_FR_OPTIONS, C_DSN_VCTRL_REG_CTRL_PRM_IDX_MSB_BIT-C_DSN_VCTRL_REG_CTRL_PRM_IDX_LSB_BIT+1);
  User_Reg(0)(C_DSN_VCTRL_REG_CTRL_SET_BIT):='1';

  datasize:=1;
  for y in 0 to datasize - 1 loop
    for i in 0 to 4 - 1 loop
      data((y*4)+i)(7 downto 0) := User_Reg(y)(8*(i+1)-1 downto 8*i);
    end loop;
  end loop;

  p_SendCfgPkt(C_WRITE, C_FIFO_OFF, C_CFGDEV_VCTRL, C_DSN_VCTRL_REG_CTRL_L, datasize, i_dev_ctrl, data, bus_in, bus_out);


  --//Установка FR_ZONE_SKIP
  --//Готовим значения регистров:
  User_Reg(0)(15 downto 0):=VctrlChParams(0).fr_size.skip.pix;--CONV_STD_LOGIC_VECTOR(10#0008#, 16);  --//Pix
  User_Reg(1)(15 downto 0):=VctrlChParams(0).fr_size.skip.row;--CONV_STD_LOGIC_VECTOR(10#0000#, 16);  --//Row

  if Pix8bit='1' then
  User_Reg(0)(15 downto 0):="00"&User_Reg(0)(15 downto 2);  --//fr_zone_skip.pix/4 (для кадра 1Pix=8bit)
  else
  User_Reg(0)(15 downto 0):=User_Reg(0)(15 downto 0);  --//fr_zone_skip.pix/1
  end if;

  datasize:=2;
  for y in 0 to datasize - 1 loop
    for i in 0 to 4 - 1 loop
      data((y*4)+i)(7 downto 0) := User_Reg(y)(8*(i+1)-1 downto 8*i);
    end loop;
  end loop;

  p_SendCfgPkt(C_WRITE, C_FIFO_OFF, C_CFGDEV_VCTRL, C_DSN_VCTRL_REG_PRM_DATA_LSB, datasize, i_dev_ctrl, data, bus_in, bus_out);

  --//Готовим значения регистров:
  User_Reg(0)(C_DSN_VCTRL_REG_CTRL_CH_IDX_MSB_BIT downto C_DSN_VCTRL_REG_CTRL_CH_IDX_LSB_BIT)  :=CONV_STD_LOGIC_VECTOR(16#00#, C_DSN_VCTRL_REG_CTRL_CH_IDX_MSB_BIT-C_DSN_VCTRL_REG_CTRL_CH_IDX_LSB_BIT+1);
  User_Reg(0)(C_DSN_VCTRL_REG_CTRL_PRM_IDX_MSB_BIT downto C_DSN_VCTRL_REG_CTRL_PRM_IDX_LSB_BIT):=CONV_STD_LOGIC_VECTOR(C_DSN_VCTRL_PRM_FR_ZONE_SKIP, C_DSN_VCTRL_REG_CTRL_PRM_IDX_MSB_BIT-C_DSN_VCTRL_REG_CTRL_PRM_IDX_LSB_BIT+1);
  User_Reg(0)(C_DSN_VCTRL_REG_CTRL_SET_BIT):='1';

  datasize:=1;
  for y in 0 to datasize - 1 loop
    for i in 0 to 4 - 1 loop
      data((y*4)+i)(7 downto 0) := User_Reg(y)(8*(i+1)-1 downto 8*i);
    end loop;
  end loop;

  p_SendCfgPkt(C_WRITE, C_FIFO_OFF, C_CFGDEV_VCTRL, C_DSN_VCTRL_REG_CTRL_L, datasize, i_dev_ctrl, data, bus_in, bus_out);

  --//Установка FR_ZONE_ACTIVE
  --//Готовим значения регистров:
  User_Reg(0)(15 downto 0):=VctrlChParams(0).fr_size.activ.pix;--CONV_STD_LOGIC_VECTOR(10#056#, 16);  --//Pix
  User_Reg(1)(15 downto 0):=VctrlChParams(0).fr_size.activ.row;--CONV_STD_LOGIC_VECTOR(10#000#, 16);  --//Row

  if Pix8bit='1' then
  User_Reg(0)(15 downto 0):="00"&User_Reg(0)(15 downto 2);  --// fr_zone_active.pix/4 (для кадра 1Pix=8bit)
  else
  User_Reg(0)(15 downto 0):=User_Reg(0)(15 downto 0);  --// fr_zone_active.pix/1
  end if;

  datasize:=2;
  for y in 0 to datasize - 1 loop
    for i in 0 to 4 - 1 loop
      data((y*4)+i)(7 downto 0) := User_Reg(y)(8*(i+1)-1 downto 8*i);
    end loop;
  end loop;

  p_SendCfgPkt(C_WRITE, C_FIFO_OFF, C_CFGDEV_VCTRL, C_DSN_VCTRL_REG_PRM_DATA_LSB, datasize, i_dev_ctrl, data, bus_in, bus_out);

  --//Готовим значения регистров:
  User_Reg(0)(C_DSN_VCTRL_REG_CTRL_CH_IDX_MSB_BIT downto C_DSN_VCTRL_REG_CTRL_CH_IDX_LSB_BIT)  :=CONV_STD_LOGIC_VECTOR(16#00#, C_DSN_VCTRL_REG_CTRL_CH_IDX_MSB_BIT-C_DSN_VCTRL_REG_CTRL_CH_IDX_LSB_BIT+1);
  User_Reg(0)(C_DSN_VCTRL_REG_CTRL_PRM_IDX_MSB_BIT downto C_DSN_VCTRL_REG_CTRL_PRM_IDX_LSB_BIT):=CONV_STD_LOGIC_VECTOR(C_DSN_VCTRL_PRM_FR_ZONE_ACTIVE, C_DSN_VCTRL_REG_CTRL_PRM_IDX_MSB_BIT-C_DSN_VCTRL_REG_CTRL_PRM_IDX_LSB_BIT+1);
  User_Reg(0)(C_DSN_VCTRL_REG_CTRL_SET_BIT):='1';

  datasize:=1;
  for y in 0 to datasize - 1 loop
    for i in 0 to 4 - 1 loop
      data((y*4)+i)(7 downto 0) := User_Reg(y)(8*(i+1)-1 downto 8*i);
    end loop;
  end loop;

  p_SendCfgPkt(C_WRITE, C_FIFO_OFF, C_CFGDEV_VCTRL, C_DSN_VCTRL_REG_CTRL_L, datasize, i_dev_ctrl, data, bus_in, bus_out);



  --//Параметры VCH1
  --//Установка адреса записи в ОЗУ
  --//Готовим значения регистров:
  User_Reg(0)(15 downto 0):=VctrlChParams(0).mem_addr_wr(15 downto 0);--;--CONV_STD_LOGIC_VECTOR(16#0000#, 16);  --//C_DSN_VCTRL_REG_PRM_DATA_LSB
  User_Reg(1)(15 downto 0):=VctrlChParams(0).mem_addr_wr(31 downto 16);--;--CONV_STD_LOGIC_VECTOR(16#0000#, 16);  --//C_DSN_VCTRL_REG_PRM_DATA_MSB
--  User_Reg(0)(15 downto 0):=EXT(VctrlChParams(0).mem_addr_wr, 16);
--  User_Reg(1)(15 downto 0):=(Others=>'0');


  datasize:=2;
  for y in 0 to datasize - 1 loop
    for i in 0 to 4 - 1 loop
      data((y*4)+i)(7 downto 0) := User_Reg(y)(8*(i+1)-1 downto 8*i);
    end loop;
  end loop;

  p_SendCfgPkt(C_WRITE, C_FIFO_OFF, C_CFGDEV_VCTRL, C_DSN_VCTRL_REG_PRM_DATA_LSB, datasize, i_dev_ctrl, data, bus_in, bus_out);

  --//Готовим значения регистров:
  User_Reg(0)(C_DSN_VCTRL_REG_CTRL_CH_IDX_MSB_BIT downto C_DSN_VCTRL_REG_CTRL_CH_IDX_LSB_BIT)  :=CONV_STD_LOGIC_VECTOR(16#01#, C_DSN_VCTRL_REG_CTRL_CH_IDX_MSB_BIT-C_DSN_VCTRL_REG_CTRL_CH_IDX_LSB_BIT+1);
  User_Reg(0)(C_DSN_VCTRL_REG_CTRL_PRM_IDX_MSB_BIT downto C_DSN_VCTRL_REG_CTRL_PRM_IDX_LSB_BIT):=CONV_STD_LOGIC_VECTOR(C_DSN_VCTRL_PRM_MEM_ADDR_WR, C_DSN_VCTRL_REG_CTRL_PRM_IDX_MSB_BIT-C_DSN_VCTRL_REG_CTRL_PRM_IDX_LSB_BIT+1);
  User_Reg(0)(C_DSN_VCTRL_REG_CTRL_SET_BIT):='1';

  datasize:=1;
  for y in 0 to datasize - 1 loop
    for i in 0 to 4 - 1 loop
      data((y*4)+i)(7 downto 0) := User_Reg(y)(8*(i+1)-1 downto 8*i);
    end loop;
  end loop;

  p_SendCfgPkt(C_WRITE, C_FIFO_OFF, C_CFGDEV_VCTRL, C_DSN_VCTRL_REG_CTRL_L, datasize, i_dev_ctrl, data, bus_in, bus_out);

  --//Установка адреса чтния в ОЗУ
  --//Готовим значения регистров:
  User_Reg(0)(15 downto 0):=VctrlChParams(0).mem_addr_rd(15 downto 0);--CONV_STD_LOGIC_VECTOR(16#0000#, 16);  --//C_DSN_VCTRL_REG_PRM_DATA_LSB
  User_Reg(1)(15 downto 0):=VctrlChParams(0).mem_addr_rd(31 downto 16);--CONV_STD_LOGIC_VECTOR(16#0100#, 16);  --//C_DSN_VCTRL_REG_PRM_DATA_MSB

  datasize:=2;
  for y in 0 to datasize - 1 loop
    for i in 0 to 4 - 1 loop
      data((y*4)+i)(7 downto 0) := User_Reg(y)(8*(i+1)-1 downto 8*i);
    end loop;
  end loop;

  p_SendCfgPkt(C_WRITE, C_FIFO_OFF, C_CFGDEV_VCTRL, C_DSN_VCTRL_REG_PRM_DATA_LSB, datasize, i_dev_ctrl, data, bus_in, bus_out);

  --//Готовим значения регистров:
  User_Reg(0)(C_DSN_VCTRL_REG_CTRL_CH_IDX_MSB_BIT downto C_DSN_VCTRL_REG_CTRL_CH_IDX_LSB_BIT)  :=CONV_STD_LOGIC_VECTOR(16#01#, C_DSN_VCTRL_REG_CTRL_CH_IDX_MSB_BIT-C_DSN_VCTRL_REG_CTRL_CH_IDX_LSB_BIT+1);
  User_Reg(0)(C_DSN_VCTRL_REG_CTRL_PRM_IDX_MSB_BIT downto C_DSN_VCTRL_REG_CTRL_PRM_IDX_LSB_BIT):=CONV_STD_LOGIC_VECTOR(C_DSN_VCTRL_PRM_MEM_ADDR_RD, C_DSN_VCTRL_REG_CTRL_PRM_IDX_MSB_BIT-C_DSN_VCTRL_REG_CTRL_PRM_IDX_LSB_BIT+1);
  User_Reg(0)(C_DSN_VCTRL_REG_CTRL_SET_BIT):='1';

  datasize:=1;
  for y in 0 to datasize - 1 loop
    for i in 0 to 4 - 1 loop
      data((y*4)+i)(7 downto 0) := User_Reg(y)(8*(i+1)-1 downto 8*i);
    end loop;
  end loop;

  p_SendCfgPkt(C_WRITE, C_FIFO_OFF, C_CFGDEV_VCTRL, C_DSN_VCTRL_REG_CTRL_L, datasize, i_dev_ctrl, data, bus_in, bus_out);

  --//Установка FR_OPTIONS
  --//Готовим значения регистров:
  User_Reg(0):=(others=>'0');
--  User_Reg(0)(1 downto 0):=VctrlChParams(0).fr_subsampling.pix;--CONV_STD_LOGIC_VECTOR(10#00#, 2);  --//Pix
  User_Reg(0)(3 downto 2):=VctrlChParams(0).fr_subsampling;--.row;--CONV_STD_LOGIC_VECTOR(10#00#, 2);  --//Row
  User_Reg(0)(4)         :=VctrlChParams(0).fr_mirror.pix;
  User_Reg(0)(5)         :=VctrlChParams(0).fr_mirror.row;
  User_Reg(0)(6)         :=VctrlChParams(0).fr_color_fst(0);
  User_Reg(0)(7)         :=VctrlChParams(0).fr_color_fst(1);
  User_Reg(0)(8)         :=VctrlChParams(0).fr_pcolor;
  User_Reg(0)(14)        :=VctrlChParams(0).fr_color;

  datasize:=1;
  for y in 0 to datasize - 1 loop
    for i in 0 to 4 - 1 loop
      data((y*4)+i)(7 downto 0) := User_Reg(y)(8*(i+1)-1 downto 8*i);
    end loop;
  end loop;

  p_SendCfgPkt(C_WRITE, C_FIFO_OFF, C_CFGDEV_VCTRL, C_DSN_VCTRL_REG_PRM_DATA_LSB, datasize, i_dev_ctrl, data, bus_in, bus_out);

  --//Готовим значения регистров:
  User_Reg(0)(C_DSN_VCTRL_REG_CTRL_CH_IDX_MSB_BIT downto C_DSN_VCTRL_REG_CTRL_CH_IDX_LSB_BIT)  :=CONV_STD_LOGIC_VECTOR(16#01#, C_DSN_VCTRL_REG_CTRL_CH_IDX_MSB_BIT-C_DSN_VCTRL_REG_CTRL_CH_IDX_LSB_BIT+1);
  User_Reg(0)(C_DSN_VCTRL_REG_CTRL_PRM_IDX_MSB_BIT downto C_DSN_VCTRL_REG_CTRL_PRM_IDX_LSB_BIT):=CONV_STD_LOGIC_VECTOR(C_DSN_VCTRL_PRM_FR_OPTIONS, C_DSN_VCTRL_REG_CTRL_PRM_IDX_MSB_BIT-C_DSN_VCTRL_REG_CTRL_PRM_IDX_LSB_BIT+1);
  User_Reg(0)(C_DSN_VCTRL_REG_CTRL_SET_BIT):='1';

  datasize:=1;
  for y in 0 to datasize - 1 loop
    for i in 0 to 4 - 1 loop
      data((y*4)+i)(7 downto 0) := User_Reg(y)(8*(i+1)-1 downto 8*i);
    end loop;
  end loop;

  p_SendCfgPkt(C_WRITE, C_FIFO_OFF, C_CFGDEV_VCTRL, C_DSN_VCTRL_REG_CTRL_L, datasize, i_dev_ctrl, data, bus_in, bus_out);


  --//Установка FR_ZONE_SKIP
  --//Готовим значения регистров:
  User_Reg(0)(15 downto 0):=VctrlChParams(0).fr_size.skip.pix;--CONV_STD_LOGIC_VECTOR(10#0008#, 16);  --//Pix
  User_Reg(1)(15 downto 0):=VctrlChParams(0).fr_size.skip.row;--CONV_STD_LOGIC_VECTOR(10#0000#, 16);  --//Row

  if Pix8bit='1' then
  User_Reg(0)(15 downto 0):="00"&User_Reg(0)(15 downto 2);  --//fr_zone_skip.pix/4 (для кадра 1Pix=8bit)
  else
  User_Reg(0)(15 downto 0):=User_Reg(0)(15 downto 0);  --//fr_zone_skip.pix/1
  end if;

  datasize:=2;
  for y in 0 to datasize - 1 loop
    for i in 0 to 4 - 1 loop
      data((y*4)+i)(7 downto 0) := User_Reg(y)(8*(i+1)-1 downto 8*i);
    end loop;
  end loop;

  p_SendCfgPkt(C_WRITE, C_FIFO_OFF, C_CFGDEV_VCTRL, C_DSN_VCTRL_REG_PRM_DATA_LSB, datasize, i_dev_ctrl, data, bus_in, bus_out);

  --//Готовим значения регистров:
  User_Reg(0)(C_DSN_VCTRL_REG_CTRL_CH_IDX_MSB_BIT downto C_DSN_VCTRL_REG_CTRL_CH_IDX_LSB_BIT)  :=CONV_STD_LOGIC_VECTOR(16#01#, C_DSN_VCTRL_REG_CTRL_CH_IDX_MSB_BIT-C_DSN_VCTRL_REG_CTRL_CH_IDX_LSB_BIT+1);
  User_Reg(0)(C_DSN_VCTRL_REG_CTRL_PRM_IDX_MSB_BIT downto C_DSN_VCTRL_REG_CTRL_PRM_IDX_LSB_BIT):=CONV_STD_LOGIC_VECTOR(C_DSN_VCTRL_PRM_FR_ZONE_SKIP, C_DSN_VCTRL_REG_CTRL_PRM_IDX_MSB_BIT-C_DSN_VCTRL_REG_CTRL_PRM_IDX_LSB_BIT+1);
  User_Reg(0)(C_DSN_VCTRL_REG_CTRL_SET_BIT):='1';

  datasize:=1;
  for y in 0 to datasize - 1 loop
    for i in 0 to 4 - 1 loop
      data((y*4)+i)(7 downto 0) := User_Reg(y)(8*(i+1)-1 downto 8*i);
    end loop;
  end loop;

  p_SendCfgPkt(C_WRITE, C_FIFO_OFF, C_CFGDEV_VCTRL, C_DSN_VCTRL_REG_CTRL_L, datasize, i_dev_ctrl, data, bus_in, bus_out);

  --//Установка FR_ZONE_ACTIVE
  --//Готовим значения регистров:
  User_Reg(0)(15 downto 0):=VctrlChParams(0).fr_size.activ.pix;--CONV_STD_LOGIC_VECTOR(10#056#, 16);  --//Pix
  User_Reg(1)(15 downto 0):=VctrlChParams(0).fr_size.activ.row;--CONV_STD_LOGIC_VECTOR(10#000#, 16);  --//Row

  if Pix8bit='1' then
  User_Reg(0)(15 downto 0):="00"&User_Reg(0)(15 downto 2);  --// fr_zone_active.pix/4 (для кадра 1Pix=8bit)
  else
  User_Reg(0)(15 downto 0):=User_Reg(0)(15 downto 0);  --// fr_zone_active.pix/1
  end if;

  datasize:=2;
  for y in 0 to datasize - 1 loop
    for i in 0 to 4 - 1 loop
      data((y*4)+i)(7 downto 0) := User_Reg(y)(8*(i+1)-1 downto 8*i);
    end loop;
  end loop;

  p_SendCfgPkt(C_WRITE, C_FIFO_OFF, C_CFGDEV_VCTRL, C_DSN_VCTRL_REG_PRM_DATA_LSB, datasize, i_dev_ctrl, data, bus_in, bus_out);

  --//Готовим значения регистров:
  User_Reg(0)(C_DSN_VCTRL_REG_CTRL_CH_IDX_MSB_BIT downto C_DSN_VCTRL_REG_CTRL_CH_IDX_LSB_BIT)  :=CONV_STD_LOGIC_VECTOR(16#01#, C_DSN_VCTRL_REG_CTRL_CH_IDX_MSB_BIT-C_DSN_VCTRL_REG_CTRL_CH_IDX_LSB_BIT+1);
  User_Reg(0)(C_DSN_VCTRL_REG_CTRL_PRM_IDX_MSB_BIT downto C_DSN_VCTRL_REG_CTRL_PRM_IDX_LSB_BIT):=CONV_STD_LOGIC_VECTOR(C_DSN_VCTRL_PRM_FR_ZONE_ACTIVE, C_DSN_VCTRL_REG_CTRL_PRM_IDX_MSB_BIT-C_DSN_VCTRL_REG_CTRL_PRM_IDX_LSB_BIT+1);
  User_Reg(0)(C_DSN_VCTRL_REG_CTRL_SET_BIT):='1';

  datasize:=1;
  for y in 0 to datasize - 1 loop
    for i in 0 to 4 - 1 loop
      data((y*4)+i)(7 downto 0) := User_Reg(y)(8*(i+1)-1 downto 8*i);
    end loop;
  end loop;

  p_SendCfgPkt(C_WRITE, C_FIFO_OFF, C_CFGDEV_VCTRL, C_DSN_VCTRL_REG_CTRL_L, datasize, i_dev_ctrl, data, bus_in, bus_out);




  --//Параметры VCH2
  --//Установка адреса записи в ОЗУ
  --//Готовим значения регистров:
  User_Reg(0)(15 downto 0):=VctrlChParams(0).mem_addr_wr(15 downto 0);--;--CONV_STD_LOGIC_VECTOR(16#0000#, 16);  --//C_DSN_VCTRL_REG_PRM_DATA_LSB
  User_Reg(1)(15 downto 0):=VctrlChParams(0).mem_addr_wr(31 downto 16);--;--CONV_STD_LOGIC_VECTOR(16#0000#, 16);  --//C_DSN_VCTRL_REG_PRM_DATA_MSB
--  User_Reg(0)(15 downto 0):=EXT(VctrlChParams(0).mem_addr_wr, 16);
--  User_Reg(1)(15 downto 0):=(Others=>'0');

  datasize:=2;
  for y in 0 to datasize - 1 loop
    for i in 0 to 4 - 1 loop
      data((y*4)+i)(7 downto 0) := User_Reg(y)(8*(i+1)-1 downto 8*i);
    end loop;
  end loop;

  p_SendCfgPkt(C_WRITE, C_FIFO_OFF, C_CFGDEV_VCTRL, C_DSN_VCTRL_REG_PRM_DATA_LSB, datasize, i_dev_ctrl, data, bus_in, bus_out);

  --//Готовим значения регистров:
  User_Reg(0)(C_DSN_VCTRL_REG_CTRL_CH_IDX_MSB_BIT downto C_DSN_VCTRL_REG_CTRL_CH_IDX_LSB_BIT)  :=CONV_STD_LOGIC_VECTOR(16#02#, C_DSN_VCTRL_REG_CTRL_CH_IDX_MSB_BIT-C_DSN_VCTRL_REG_CTRL_CH_IDX_LSB_BIT+1);
  User_Reg(0)(C_DSN_VCTRL_REG_CTRL_PRM_IDX_MSB_BIT downto C_DSN_VCTRL_REG_CTRL_PRM_IDX_LSB_BIT):=CONV_STD_LOGIC_VECTOR(C_DSN_VCTRL_PRM_MEM_ADDR_WR, C_DSN_VCTRL_REG_CTRL_PRM_IDX_MSB_BIT-C_DSN_VCTRL_REG_CTRL_PRM_IDX_LSB_BIT+1);
  User_Reg(0)(C_DSN_VCTRL_REG_CTRL_SET_BIT):='1';

  datasize:=1;
  for y in 0 to datasize - 1 loop
    for i in 0 to 4 - 1 loop
      data((y*4)+i)(7 downto 0) := User_Reg(y)(8*(i+1)-1 downto 8*i);
    end loop;
  end loop;

  p_SendCfgPkt(C_WRITE, C_FIFO_OFF, C_CFGDEV_VCTRL, C_DSN_VCTRL_REG_CTRL_L, datasize, i_dev_ctrl, data, bus_in, bus_out);

  --//Установка адреса чтния в ОЗУ
  --//Готовим значения регистров:
  User_Reg(0)(15 downto 0):=VctrlChParams(0).mem_addr_rd(15 downto 0);--CONV_STD_LOGIC_VECTOR(16#0000#, 16);  --//C_DSN_VCTRL_REG_PRM_DATA_LSB
  User_Reg(1)(15 downto 0):=VctrlChParams(0).mem_addr_rd(31 downto 16);--CONV_STD_LOGIC_VECTOR(16#0100#, 16);  --//C_DSN_VCTRL_REG_PRM_DATA_MSB

  datasize:=2;
  for y in 0 to datasize - 1 loop
    for i in 0 to 4 - 1 loop
      data((y*4)+i)(7 downto 0) := User_Reg(y)(8*(i+1)-1 downto 8*i);
    end loop;
  end loop;

  p_SendCfgPkt(C_WRITE, C_FIFO_OFF, C_CFGDEV_VCTRL, C_DSN_VCTRL_REG_PRM_DATA_LSB, datasize, i_dev_ctrl, data, bus_in, bus_out);

  --//Готовим значения регистров:
  User_Reg(0)(C_DSN_VCTRL_REG_CTRL_CH_IDX_MSB_BIT downto C_DSN_VCTRL_REG_CTRL_CH_IDX_LSB_BIT)  :=CONV_STD_LOGIC_VECTOR(16#01#, C_DSN_VCTRL_REG_CTRL_CH_IDX_MSB_BIT-C_DSN_VCTRL_REG_CTRL_CH_IDX_LSB_BIT+1);
  User_Reg(0)(C_DSN_VCTRL_REG_CTRL_PRM_IDX_MSB_BIT downto C_DSN_VCTRL_REG_CTRL_PRM_IDX_LSB_BIT):=CONV_STD_LOGIC_VECTOR(C_DSN_VCTRL_PRM_MEM_ADDR_RD, C_DSN_VCTRL_REG_CTRL_PRM_IDX_MSB_BIT-C_DSN_VCTRL_REG_CTRL_PRM_IDX_LSB_BIT+1);
  User_Reg(0)(C_DSN_VCTRL_REG_CTRL_SET_BIT):='1';

  datasize:=1;
  for y in 0 to datasize - 1 loop
    for i in 0 to 4 - 1 loop
      data((y*4)+i)(7 downto 0) := User_Reg(y)(8*(i+1)-1 downto 8*i);
    end loop;
  end loop;

  p_SendCfgPkt(C_WRITE, C_FIFO_OFF, C_CFGDEV_VCTRL, C_DSN_VCTRL_REG_CTRL_L, datasize, i_dev_ctrl, data, bus_in, bus_out);

  --//Установка FR_OPTIONS
  --//Готовим значения регистров:
  User_Reg(0):=(others=>'0');
--  User_Reg(0)(1 downto 0):=VctrlChParams(0).fr_subsampling.pix;--CONV_STD_LOGIC_VECTOR(10#00#, 2);  --//Pix
  User_Reg(0)(3 downto 2):=VctrlChParams(0).fr_subsampling;--.row;--CONV_STD_LOGIC_VECTOR(10#00#, 2);  --//Row
  User_Reg(0)(4)         :=VctrlChParams(0).fr_mirror.pix;
  User_Reg(0)(5)         :=VctrlChParams(0).fr_mirror.row;
  User_Reg(0)(6)         :=VctrlChParams(0).fr_color_fst(0);
  User_Reg(0)(7)         :=VctrlChParams(0).fr_color_fst(1);
  User_Reg(0)(8)         :=VctrlChParams(0).fr_pcolor;
  User_Reg(0)(14)        :=VctrlChParams(0).fr_color;

  datasize:=1;
  for y in 0 to datasize - 1 loop
    for i in 0 to 4 - 1 loop
      data((y*4)+i)(7 downto 0) := User_Reg(y)(8*(i+1)-1 downto 8*i);
    end loop;
  end loop;

  p_SendCfgPkt(C_WRITE, C_FIFO_OFF, C_CFGDEV_VCTRL, C_DSN_VCTRL_REG_PRM_DATA_LSB, datasize, i_dev_ctrl, data, bus_in, bus_out);

  --//Готовим значения регистров:
  User_Reg(0)(C_DSN_VCTRL_REG_CTRL_CH_IDX_MSB_BIT downto C_DSN_VCTRL_REG_CTRL_CH_IDX_LSB_BIT)  :=CONV_STD_LOGIC_VECTOR(16#02#, C_DSN_VCTRL_REG_CTRL_CH_IDX_MSB_BIT-C_DSN_VCTRL_REG_CTRL_CH_IDX_LSB_BIT+1);
  User_Reg(0)(C_DSN_VCTRL_REG_CTRL_PRM_IDX_MSB_BIT downto C_DSN_VCTRL_REG_CTRL_PRM_IDX_LSB_BIT):=CONV_STD_LOGIC_VECTOR(C_DSN_VCTRL_PRM_FR_OPTIONS, C_DSN_VCTRL_REG_CTRL_PRM_IDX_MSB_BIT-C_DSN_VCTRL_REG_CTRL_PRM_IDX_LSB_BIT+1);
  User_Reg(0)(C_DSN_VCTRL_REG_CTRL_SET_BIT):='1';

  datasize:=1;
  for y in 0 to datasize - 1 loop
    for i in 0 to 4 - 1 loop
      data((y*4)+i)(7 downto 0) := User_Reg(y)(8*(i+1)-1 downto 8*i);
    end loop;
  end loop;

  p_SendCfgPkt(C_WRITE, C_FIFO_OFF, C_CFGDEV_VCTRL, C_DSN_VCTRL_REG_CTRL_L, datasize, i_dev_ctrl, data, bus_in, bus_out);


  --//Установка FR_ZONE_SKIP
  --//Готовим значения регистров:
  User_Reg(0)(15 downto 0):=VctrlChParams(0).fr_size.skip.pix;--CONV_STD_LOGIC_VECTOR(10#0008#, 16);  --//Pix
  User_Reg(1)(15 downto 0):=VctrlChParams(0).fr_size.skip.row;--CONV_STD_LOGIC_VECTOR(10#0000#, 16);  --//Row

  if Pix8bit='1' then
  User_Reg(0)(15 downto 0):="00"&User_Reg(0)(15 downto 2);  --//fr_zone_skip.pix/4 (для кадра 1Pix=8bit)
  else
  User_Reg(0)(15 downto 0):=User_Reg(0)(15 downto 0);  --//fr_zone_skip.pix/1
  end if;

  datasize:=2;
  for y in 0 to datasize - 1 loop
    for i in 0 to 4 - 1 loop
      data((y*4)+i)(7 downto 0) := User_Reg(y)(8*(i+1)-1 downto 8*i);
    end loop;
  end loop;

  p_SendCfgPkt(C_WRITE, C_FIFO_OFF, C_CFGDEV_VCTRL, C_DSN_VCTRL_REG_PRM_DATA_LSB, datasize, i_dev_ctrl, data, bus_in, bus_out);

  --//Готовим значения регистров:
  User_Reg(0)(C_DSN_VCTRL_REG_CTRL_CH_IDX_MSB_BIT downto C_DSN_VCTRL_REG_CTRL_CH_IDX_LSB_BIT)  :=CONV_STD_LOGIC_VECTOR(16#02#, C_DSN_VCTRL_REG_CTRL_CH_IDX_MSB_BIT-C_DSN_VCTRL_REG_CTRL_CH_IDX_LSB_BIT+1);
  User_Reg(0)(C_DSN_VCTRL_REG_CTRL_PRM_IDX_MSB_BIT downto C_DSN_VCTRL_REG_CTRL_PRM_IDX_LSB_BIT):=CONV_STD_LOGIC_VECTOR(C_DSN_VCTRL_PRM_FR_ZONE_SKIP, C_DSN_VCTRL_REG_CTRL_PRM_IDX_MSB_BIT-C_DSN_VCTRL_REG_CTRL_PRM_IDX_LSB_BIT+1);
  User_Reg(0)(C_DSN_VCTRL_REG_CTRL_SET_BIT):='1';

  datasize:=1;
  for y in 0 to datasize - 1 loop
    for i in 0 to 4 - 1 loop
      data((y*4)+i)(7 downto 0) := User_Reg(y)(8*(i+1)-1 downto 8*i);
    end loop;
  end loop;

  p_SendCfgPkt(C_WRITE, C_FIFO_OFF, C_CFGDEV_VCTRL, C_DSN_VCTRL_REG_CTRL_L, datasize, i_dev_ctrl, data, bus_in, bus_out);

  --//Установка FR_ZONE_ACTIVE
  --//Готовим значения регистров:
  User_Reg(0)(15 downto 0):=VctrlChParams(0).fr_size.activ.pix;--CONV_STD_LOGIC_VECTOR(10#056#, 16);  --//Pix
  User_Reg(1)(15 downto 0):=VctrlChParams(0).fr_size.activ.row;--CONV_STD_LOGIC_VECTOR(10#000#, 16);  --//Row

  if Pix8bit='1' then
  User_Reg(0)(15 downto 0):="00"&User_Reg(0)(15 downto 2);  --// fr_zone_active.pix/4 (для кадра 1Pix=8bit)
  else
  User_Reg(0)(15 downto 0):=User_Reg(0)(15 downto 0);  --// fr_zone_active.pix/1
  end if;

  datasize:=2;
  for y in 0 to datasize - 1 loop
    for i in 0 to 4 - 1 loop
      data((y*4)+i)(7 downto 0) := User_Reg(y)(8*(i+1)-1 downto 8*i);
    end loop;
  end loop;

  p_SendCfgPkt(C_WRITE, C_FIFO_OFF, C_CFGDEV_VCTRL, C_DSN_VCTRL_REG_PRM_DATA_LSB, datasize, i_dev_ctrl, data, bus_in, bus_out);

  --//Готовим значения регистров:
  User_Reg(0)(C_DSN_VCTRL_REG_CTRL_CH_IDX_MSB_BIT downto C_DSN_VCTRL_REG_CTRL_CH_IDX_LSB_BIT)  :=CONV_STD_LOGIC_VECTOR(16#02#, C_DSN_VCTRL_REG_CTRL_CH_IDX_MSB_BIT-C_DSN_VCTRL_REG_CTRL_CH_IDX_LSB_BIT+1);
  User_Reg(0)(C_DSN_VCTRL_REG_CTRL_PRM_IDX_MSB_BIT downto C_DSN_VCTRL_REG_CTRL_PRM_IDX_LSB_BIT):=CONV_STD_LOGIC_VECTOR(C_DSN_VCTRL_PRM_FR_ZONE_ACTIVE, C_DSN_VCTRL_REG_CTRL_PRM_IDX_MSB_BIT-C_DSN_VCTRL_REG_CTRL_PRM_IDX_LSB_BIT+1);
  User_Reg(0)(C_DSN_VCTRL_REG_CTRL_SET_BIT):='1';

  datasize:=1;
  for y in 0 to datasize - 1 loop
    for i in 0 to 4 - 1 loop
      data((y*4)+i)(7 downto 0) := User_Reg(y)(8*(i+1)-1 downto 8*i);
    end loop;
  end loop;

  p_SendCfgPkt(C_WRITE, C_FIFO_OFF, C_CFGDEV_VCTRL, C_DSN_VCTRL_REG_CTRL_L, datasize, i_dev_ctrl, data, bus_in, bus_out);



  --//Готовим значения регистров:
  User_Reg(0):=(others=>'0');
  User_Reg(0)(15 downto 0):=VctrlRegTST0;

  datasize:=1;
  for y in 0 to datasize - 1 loop
    for i in 0 to 4 - 1 loop
      data((y*4)+i)(7 downto 0) := User_Reg(y)(8*(i+1)-1 downto 8*i);
    end loop;
  end loop;

  p_SendCfgPkt(C_WRITE, C_FIFO_OFF, C_CFGDEV_VCTRL, C_DSN_VCTRL_REG_TST0, datasize, i_dev_ctrl, data, bus_in, bus_out);



  wait_cycles(4, lclk);
  --// Настройка модуля DSN_VIDEO_CTRL.VHD
  --//End
  ----------------------------------------------------
  ----------------------------------------------------------------------------------------

  ----------------------------------------------------------------------------------------
  ----------------------------------------------------
  --// Настройка модуля DSN_ETH.VHD
  --//Begin
  i_dev_ctrl(C_HREG_DEV_CTRL_DEV_ADDR_MSB_BIT downto C_HREG_DEV_CTRL_DEV_ADDR_LSB_BIT):=CONV_STD_LOGIC_VECTOR(C_HDEV_CFG_DBUF, C_HREG_DEV_CTRL_DEV_ADDR_SIZE);
  data(0 to 3) :=conv_byte_vector(i_dev_ctrl);
  plxsim_write_const(C_LBUS_DATA_BITS, C_MULTBURST_OFF, (C_VM_USR_REG_BAR+CONV_STD_LOGIC_VECTOR(C_HOST_REG_DEV_CTRL*C_VM_USR_REG_BCOUNT, 32)), be(0 to 3), data(0 to 3), n, bus_in, bus_out);

  --//Готовим значения регистров:
--  constant C_DSN_ETHG_REG_TX_PATRN_SIZE_LSB_BIT : integer:=0;--//constant C_PKT_MARKER_PATTERN_SIZE_LSB_BIT : integer:=0;
--  constant C_DSN_ETHG_REG_TX_PATRN_SIZE_MSB_BIT : integer:=3;--//constant C_PKT_MARKER_PATTERN_SIZE_MSB_BIT : integer:=3;
--  constant C_DSN_ETHG_REG_RX_PATRN_SIZE_LSB_BIT : integer:=4;--//constant C_PKT_MARKER_PATTERN_SIZE_LSB_BIT : integer:=0;
--  constant C_DSN_ETHG_REG_RX_PATRN_SIZE_MSB_BIT : integer:=7;--//constant C_PKT_MARKER_PATTERN_SIZE_MSB_BIT : integer:=3;
  User_Reg(0)(15 downto 0):=CONV_STD_LOGIC_VECTOR(10#0#, 16);  --//C_DSN_ETHG_REG_TX_PATRN_PARAM
--  User_Reg(0)(C_DSN_ETHG_REG_MAC_TX_PATRN_SIZE_MSB_BIT downto C_DSN_ETHG_REG_MAC_TX_PATRN_SIZE_LSB_BIT):=CONV_STD_LOGIC_VECTOR(10#12#, 4);--(10#14#, 4);--//C_DSN_ETHG_REG_TX_PATRN_PARAM
--  User_Reg(0)(C_DSN_ETHG_REG_MAC_RX_PATRN_SIZE_MSB_BIT downto C_DSN_ETHG_REG_MAC_RX_PATRN_SIZE_LSB_BIT):=CONV_STD_LOGIC_VECTOR(10#12#, 4);--(10#14#, 4);--//C_DSN_ETHG_REG_TX_PATRN_PARAM
--  User_Reg(0)(C_DSN_ETHG_REG_MAC_RX_PADDING_CLR_DIS_BIT):='0';--//Запрещение

  User_Reg(1)(15 downto 0):=CONV_STD_LOGIC_VECTOR(16#D1D0#, 16);  --//C_DSN_ETHG_REG_TX_PATRN0 - MAC DST
  User_Reg(2)(15 downto 0):=CONV_STD_LOGIC_VECTOR(16#D3D2#, 16);  --//C_DSN_ETHG_REG_TX_PATRN1
  User_Reg(3)(15 downto 0):=CONV_STD_LOGIC_VECTOR(16#D5D4#, 16);  --//C_DSN_ETHG_REG_TX_PATRN2
  User_Reg(4)(15 downto 0):=CONV_STD_LOGIC_VECTOR(16#D1D0#, 16);  --//C_DSN_ETHG_REG_TX_PATRN3 - MAC SRC
  User_Reg(5)(15 downto 0):=CONV_STD_LOGIC_VECTOR(16#D3D2#, 16);  --//C_DSN_ETHG_REG_TX_PATRN4
  User_Reg(6)(15 downto 0):=CONV_STD_LOGIC_VECTOR(16#D5D4#, 16);  --//C_DSN_ETHG_REG_TX_PATRN5
  User_Reg(7)(15 downto 0):=CONV_STD_LOGIC_VECTOR(16#0D0C#, 16);  --//C_DSN_ETHG_REG_TX_PATRN6 - MAC Length/Type

  datasize:=8;
  for y in 0 to datasize - 1 loop
    for i in 0 to 4 - 1 loop
      data((y*4)+i)(7 downto 0) := User_Reg(y)(8*(i+1)-1 downto 8*i);
    end loop;
  end loop;

  p_SendCfgPkt(C_WRITE, C_FIFO_OFF, C_CFGDEV_ETHG, C_DSN_ETHG_REG_MAC_USRCTRL, datasize, i_dev_ctrl, data, bus_in, bus_out);

  wait_cycles(4, lclk);
  --// Настройка модуля DSN_ETH.VHD
  --//End
  ----------------------------------------------------
  ----------------------------------------------------------------------------------------

  ----------------------------------------------------------------------------------------
  ----------------------------------------------------
  --// Настройка модуля DSN_TRACK_NIK.VHD
  --//Begin
  i_dev_ctrl(C_HREG_DEV_CTRL_DEV_ADDR_MSB_BIT downto C_HREG_DEV_CTRL_DEV_ADDR_LSB_BIT):=CONV_STD_LOGIC_VECTOR(C_HDEV_CFG_DBUF, C_HREG_DEV_CTRL_DEV_ADDR_SIZE);
  data(0 to 3) :=conv_byte_vector(i_dev_ctrl);
  plxsim_write_const(C_LBUS_DATA_BITS, C_MULTBURST_OFF, (C_VM_USR_REG_BAR+CONV_STD_LOGIC_VECTOR(C_HOST_REG_DEV_CTRL*C_VM_USR_REG_BCOUNT, 32)), be(0 to 3), data(0 to 3), n, bus_in, bus_out);

  --//Установка C_DSN_TRCNIK_REG_MEM_TRN_LEN
  --//Готовим значения регистров:
  User_Reg(0)(7 downto 0) :=TrcNik_MemWR_trn_len;--//WRITE
  User_Reg(0)(15 downto 8):=TrcNik_MemRD_trn_len;--//READ

  datasize:=1;
  for y in 0 to datasize - 1 loop
    for i in 0 to 4 - 1 loop
      data((y*4)+i)(7 downto 0) := User_Reg(y)(8*(i+1)-1 downto 8*i);
    end loop;
  end loop;

  p_SendCfgPkt(C_WRITE, C_FIFO_OFF, C_CFGDEV_TRACK_NIK, C_DSN_TRCNIK_REG_MEM_TRN_LEN, datasize, i_dev_ctrl, data, bus_in, bus_out);

  --//Готовим значения регистров:
  User_Reg(0):=(others=>'0');
  User_Reg(0)(15 downto 0):=TrcNikRegTST0;

  datasize:=1;
  for y in 0 to datasize - 1 loop
    for i in 0 to 4 - 1 loop
      data((y*4)+i)(7 downto 0) := User_Reg(y)(8*(i+1)-1 downto 8*i);
    end loop;
  end loop;

  p_SendCfgPkt(C_WRITE, C_FIFO_OFF, C_CFGDEV_TRACK_NIK, C_DSN_TRCNIK_REG_TST0, datasize, i_dev_ctrl, data, bus_in, bus_out);


  --//Установка параметров слежения
  --//Готовим значения регистров:
  User_Reg(0)(7 downto 0) :=TrcNikChParams(0).ip(0).p1;
  User_Reg(0)(15 downto 8):=TrcNikChParams(0).ip(0).p2;
  User_Reg(1)(7 downto 0) :=TrcNikChParams(0).ip(1).p1;
  User_Reg(1)(15 downto 8):=TrcNikChParams(0).ip(1).p2;
  User_Reg(2)(7 downto 0) :=TrcNikChParams(0).ip(2).p1;
  User_Reg(2)(15 downto 8):=TrcNikChParams(0).ip(2).p2;
  User_Reg(3)(7 downto 0) :=TrcNikChParams(0).ip(3).p1;
  User_Reg(3)(15 downto 8):=TrcNikChParams(0).ip(3).p2;
  User_Reg(4)(7 downto 0) :=(others=>'0');--TrcNikChParams(0).ip(4).p1;
  User_Reg(4)(15 downto 8):=(others=>'0');--TrcNikChParams(0).ip(4).p2;
  User_Reg(5)(7 downto 0) :=(others=>'0');--TrcNikChParams(0).ip(5).p1;
  User_Reg(5)(15 downto 8):=(others=>'0');--TrcNikChParams(0).ip(5).p2;
  User_Reg(6)(7 downto 0) :=(others=>'0');--TrcNikChParams(0).ip(6).p1;
  User_Reg(6)(15 downto 8):=(others=>'0');--TrcNikChParams(0).ip(6).p2;
  User_Reg(7)(7 downto 0) :=(others=>'0');--TrcNikChParams(0).ip(7).p1;
  User_Reg(7)(15 downto 8):=(others=>'0');--TrcNikChParams(0).ip(7).p2;
  User_Reg(8)(15 downto 0):=TrcNikChParams(0).opt;
  User_Reg(9)(15 downto 0):=TrcNikChParams(0).mem_arbuf(15 downto 0);
  User_Reg(10)(15 downto 0):=TrcNikChParams(0).mem_arbuf(31 downto 16);
  User_Reg(11):=(others=>'0');
  User_Reg(12):=(others=>'0');
  User_Reg(13):=(others=>'0');
  User_Reg(14):=(others=>'0');
  User_Reg(15):=(others=>'0');

  --//Установка C_DSN_TRC_REG_CTRL_L
  User_Reg(16):=(others=>'0');
  User_Reg(16)(C_DSN_TRCNIK_REG_CTRL_CH_MSB_BIT downto C_DSN_TRCNIK_REG_CTRL_CH_LSB_BIT):=CONV_STD_LOGIC_VECTOR(16#00#, C_DSN_TRCNIK_REG_CTRL_CH_MSB_BIT-C_DSN_TRCNIK_REG_CTRL_CH_LSB_BIT+1);
  User_Reg(16)(C_DSN_TRCNIK_REG_CTRL_SET_BIT):='0';
  User_Reg(16)(C_DSN_TRCNIK_REG_CTRL_WORK_BIT):=TrcNikWorkOn;

  datasize:=17;
  for y in 0 to datasize - 1 loop
    for i in 0 to 4 - 1 loop
      data((y*4)+i)(7 downto 0) := User_Reg(y)(8*(i+1)-1 downto 8*i);
    end loop;
  end loop;

  p_SendCfgPkt(C_WRITE, C_FIFO_OFF, C_CFGDEV_TRACK_NIK, C_DSN_TRCNIK_REG_IP0, datasize, i_dev_ctrl, data, bus_in, bus_out);

  wait_cycles(4, lclk);

  --// Настройка модуля DSN_TRACK_NIK.VHD
  --//End
  ----------------------------------------------------
  ----------------------------------------------------------------------------------------

--  ----------------------------------------------------------------------------------------
--  ----------------------------------------------------
--  --// Настройка модуля DSN_TRACK.VHD
--  --//Begin
--  i_dev_ctrl(C_HREG_DEV_CTRL_DEV_ADDR_MSB_BIT downto C_HREG_DEV_CTRL_DEV_ADDR_LSB_BIT):=CONV_STD_LOGIC_VECTOR(C_HDEV_CFG_DBUF, C_HREG_DEV_CTRL_DEV_ADDR_SIZE);
--  data(0 to 3) :=conv_byte_vector(i_dev_ctrl);
--  plxsim_write_const(C_LBUS_DATA_BITS, C_MULTBURST_OFF, (C_VM_USR_REG_BAR+CONV_STD_LOGIC_VECTOR(C_HOST_REG_DEV_CTRL*C_VM_USR_REG_BCOUNT, 32)), be(0 to 3), data(0 to 3), n, bus_in, bus_out);
--
--  --//Установка C_DSN_TRC_REG_MEM_TRN_LEN
--  --//Готовим значения регистров:
--  User_Reg(0)(7 downto 0) :=Trc_MemWR_trn_len; --//WRITE
--  User_Reg(0)(15 downto 8):=Trc_MemRD_trn_len; --//READ
--
--  datasize:=1;
--  for y in 0 to datasize - 1 loop
--    for i in 0 to 4 - 1 loop
--      data((y*4)+i)(7 downto 0) := User_Reg(y)(8*(i+1)-1 downto 8*i);
--    end loop;
--  end loop;
--
--  p_SendCfgPkt(C_WRITE, C_FIFO_OFF, C_CFGDEV_TRACK, C_DSN_TRC_REG_MEM_TRN_LEN, datasize, i_dev_ctrl, data, bus_in, bus_out);
--
--  --//Готовим значения регистров:
--  User_Reg(0):=(others=>'0');
--  User_Reg(0)(15 downto 0):=TrcRegTST0;
--
--  datasize:=1;
--  for y in 0 to datasize - 1 loop
--    for i in 0 to 4 - 1 loop
--      data((y*4)+i)(7 downto 0) := User_Reg(y)(8*(i+1)-1 downto 8*i);
--    end loop;
--  end loop;
--
--  p_SendCfgPkt(C_WRITE, C_FIFO_OFF, C_CFGDEV_TRACK, C_DSN_TRC_REG_TST0, datasize, i_dev_ctrl, data, bus_in, bus_out);
--
--  --//Установка параметров слежения
--  --//Готовим значения регистров:
--  if Pix8bit='1' then
--       User_Reg(0)(15 downto 0):="00"&TrcChParams(0).win.skip.pix(15 downto 2);  --// fr_zone_active.pix/4 (для кадра 1Pix=8bit)
--  else User_Reg(0)(15 downto 0):=TrcChParams(0).win.skip.pix;  --// fr_zone_active.pix/1
--  end if;
--  User_Reg(1)(15 downto 0):=TrcChParams(0).win.skip.row;
--
--  if Pix8bit='1' then
--       User_Reg(2)(15 downto 0):="00"&TrcChParams(0).win.activ.pix(15 downto 2);  --// fr_zone_active.pix/4 (для кадра 1Pix=8bit)
--  else User_Reg(2)(15 downto 0):=TrcChParams(0).win.activ.pix(15 downto 0);  --// fr_zone_active.pix/1
--  end if;
--  User_Reg(3)(15 downto 0):=TrcChParams(0).win.activ.row;
--
--  User_Reg(4)(15 downto 0):=EXT(TrcChParams(0).threshold, 16);
--
--  User_Reg(5):=(others=>'0');
----  User_Reg(5)(12 downto 9):=TrcChParams(0).fr_zoom;
----  User_Reg(5)(13)         :=TrcChParams(0).fr_zoom_type;
--  User_Reg(6):=(others=>'0');
--
--  User_Reg(7)(15 downto 0):=TrcChParams(0).mem_atbuf(15 downto 0);
--  User_Reg(8)(15 downto 0):=TrcChParams(0).mem_atbuf(31 downto 16);
--  User_Reg(9)(15 downto 0):=TrcChParams(0).mem_aebuf(15 downto 0);
--  User_Reg(10)(15 downto 0):=TrcChParams(0).mem_aebuf(31 downto 16);
--  User_Reg(11):=(others=>'0');
--  User_Reg(12):=(others=>'0');
--  User_Reg(13):=(others=>'0');
--  User_Reg(14):=(others=>'0');
--  User_Reg(15):=(others=>'0');
--
--  --//Установка C_DSN_TRC_REG_CTRL_L
--  User_Reg(16):=(others=>'0');
--  User_Reg(16)(C_DSN_TRC_REG_CTRL_CH_IDX_MSB_BIT downto C_DSN_TRC_REG_CTRL_CH_IDX_LSB_BIT)  :=CONV_STD_LOGIC_VECTOR(16#00#, C_DSN_TRC_REG_CTRL_CH_IDX_MSB_BIT-C_DSN_TRC_REG_CTRL_CH_IDX_LSB_BIT+1);
----  User_Reg(16)(C_DSN_TRC_REG_CTRL_PRM_IDX_MSB_BIT downto C_DSN_TRC_REG_CTRL_PRM_IDX_LSB_BIT):=CONV_STD_LOGIC_VECTOR(C_DSN_TRC_PRM_WIN, C_DSN_TRC_REG_CTRL_PRM_IDX_MSB_BIT-C_DSN_TRC_REG_CTRL_PRM_IDX_LSB_BIT+1);
----  User_Reg(16)(C_DSN_TRC_REG_CTRL_SET_BIT):='1';
--  User_Reg(16)(C_DSN_TRC_REG_CTRL_WORK_BIT):=TrcWorkOn;
--
--  datasize:=17;
--  for y in 0 to datasize - 1 loop
--    for i in 0 to 4 - 1 loop
--      data((y*4)+i)(7 downto 0) := User_Reg(y)(8*(i+1)-1 downto 8*i);
--    end loop;
--  end loop;
--
--  p_SendCfgPkt(C_WRITE, C_FIFO_OFF, C_CFGDEV_TRACK, C_DSN_TRC_REG_WIN_SKIP_LSB, datasize, i_dev_ctrl, data, bus_in, bus_out);
--
--  wait_cycles(4, lclk);
--
--  --// Настройка модуля DSN_TRACK.VHD
--  --//End
--  ----------------------------------------------------
--  ----------------------------------------------------------------------------------------
--
----  ----------------------------------------------------------------------------------------
----  ----------------------------------------------------
----  --// Запуск работы модуля DSN_TRACK.VHD
----  --//Begin
----  i_dev_ctrl(C_HREG_DEV_CTRL_DEV_ADDR_MSB_BIT downto C_HREG_DEV_CTRL_DEV_ADDR_LSB_BIT):=CONV_STD_LOGIC_VECTOR(C_HDEV_CFG_DBUF, C_HREG_DEV_CTRL_DEV_ADDR_SIZE);
----  data(0 to 3) :=conv_byte_vector(i_dev_ctrl);
----  plxsim_write_const(C_LBUS_DATA_BITS, C_MULTBURST_OFF, (C_VM_USR_REG_BAR+CONV_STD_LOGIC_VECTOR(C_HOST_REG_DEV_CTRL*C_VM_USR_REG_BCOUNT, 32)), be(0 to 3), data(0 to 3), n, bus_in, bus_out);
----
----
----  --//Готовим значения регистров:
----  User_Reg(0)(C_DSN_TRC_REG_CTRL_CH_IDX_MSB_BIT downto C_DSN_TRC_REG_CTRL_CH_IDX_LSB_BIT)  :=CONV_STD_LOGIC_VECTOR(16#00#, C_DSN_TRC_REG_CTRL_CH_IDX_MSB_BIT-C_DSN_TRC_REG_CTRL_CH_IDX_LSB_BIT+1);
----  User_Reg(0)(C_DSN_TRC_REG_CTRL_PRM_IDX_MSB_BIT downto C_DSN_TRC_REG_CTRL_PRM_IDX_LSB_BIT):=(others=>'0');
----  User_Reg(0)(C_DSN_TRC_REG_CTRL_SET_BIT):='0';
----  User_Reg(0)(C_DSN_TRC_REG_CTRL_WORK_BIT):='1';
----
----  datasize:=1;
----  for y in 0 to datasize - 1 loop
----    for i in 0 to 4 - 1 loop
----      data((y*4)+i)(7 downto 0) := User_Reg(y)(8*(i+1)-1 downto 8*i);
----    end loop;
----  end loop;
----
----  p_SendCfgPkt(C_WRITE, C_FIFO_OFF, C_CFGDEV_TRACK, C_DSN_TRC_REG_CTRL_L, datasize, i_dev_ctrl, data, bus_in, bus_out);
----
----  wait_cycles(4, lclk);
----  --// Запуск работы модуля DSN_TRACK.VHD
----  --//End
----  ----------------------------------------------------
----  ----------------------------------------------------------------------------------------



  ----------------------------------------------------------------------------------------
  ----------------------------------------------------
  --// Конфигурирование RAMBUF Накопителя
  --//Begin
  i_dev_ctrl(C_HREG_DEV_CTRL_DEV_ADDR_MSB_BIT downto C_HREG_DEV_CTRL_DEV_ADDR_LSB_BIT):=CONV_STD_LOGIC_VECTOR(C_HDEV_CFG_DBUF, C_HREG_DEV_CTRL_DEV_ADDR_SIZE);
  data(0 to 3) :=conv_byte_vector(i_dev_ctrl);
  plxsim_write_const(C_LBUS_DATA_BITS, C_MULTBURST_OFF, (C_VM_USR_REG_BAR+CONV_STD_LOGIC_VECTOR(C_HOST_REG_DEV_CTRL*C_VM_USR_REG_BCOUNT, 32)), be(0 to 3), data(0 to 3), n, bus_in, bus_out);

  --//
  User_Reg(0)(15 downto 0):=hdd_cfg_rambuf_adr(15 downto 0);
  User_Reg(1)(15 downto 0):=hdd_cfg_rambuf_adr(31 downto 16);

  datasize:=2;
  for y in 0 to datasize - 1 loop
    for i in 0 to 4 - 1 loop
      data((y*4)+i)(7 downto 0) := User_Reg(y)(8*(i+1)-1 downto 8*i);
    end loop;
  end loop;

  p_SendCfgPkt(C_WRITE, C_FIFO_OFF, C_CFGDEV_HDD, C_DSN_HDD_REG_RBUF_ADR_L, datasize, i_dev_ctrl, data, bus_in, bus_out);
  wait_cycles(4, lclk);

--  --//
--  User_Reg(0)(15 downto 0):=hdd_cfg_rambuf_size(15 downto 0);
--  User_Reg(1)(15 downto 0):=hdd_cfg_rambuf_size(31 downto 16);
--
--  datasize:=2;
--  for y in 0 to datasize - 1 loop
--    for i in 0 to 4 - 1 loop
--      data((y*4)+i)(7 downto 0) := User_Reg(y)(8*(i+1)-1 downto 8*i);
--    end loop;
--  end loop;
--
--  p_SendCfgPkt(C_WRITE, C_FIFO_OFF, C_CFGDEV_HDD, C_DSN_HDD_REG_RBUF_SIZE_L, datasize, i_dev_ctrl, data, bus_in, bus_out);
--  wait_cycles(4, lclk);
--  --//
--  User_Reg(0)(15 downto 0):=hdd_cfg_rambuf_level(15 downto 0);
--
--  datasize:=1;
--  for y in 0 to datasize - 1 loop
--    for i in 0 to 4 - 1 loop
--      data((y*4)+i)(7 downto 0) := User_Reg(y)(8*(i+1)-1 downto 8*i);
--    end loop;
--  end loop;
--
--  p_SendCfgPkt(C_WRITE, C_FIFO_OFF, C_CFGDEV_HDD, C_DSN_HDD_REG_RBUF_LEVEL, datasize, i_dev_ctrl, data, bus_in, bus_out);
--  wait_cycles(4, lclk);
--
--  --//
--  User_Reg(0)(15 downto 0):=hdd_cfg_rambuf_fifo_size(15 downto 0);
--
--  datasize:=1;
--  for y in 0 to datasize - 1 loop
--    for i in 0 to 4 - 1 loop
--      data((y*4)+i)(7 downto 0) := User_Reg(y)(8*(i+1)-1 downto 8*i);
--    end loop;
--  end loop;
--
--  p_SendCfgPkt(C_WRITE, C_FIFO_OFF, C_CFGDEV_HDD, C_DSN_HDD_REG_RBUF_FIFO_SIZE, datasize, i_dev_ctrl, data, bus_in, bus_out);
--  wait_cycles(4, lclk);

  --//
  User_Reg(0)(15 downto 0):=hdd_cfg_rambuf_ctrl;

  datasize:=1;
  for y in 0 to datasize - 1 loop
    for i in 0 to 4 - 1 loop
      data((y*4)+i)(7 downto 0) := User_Reg(y)(8*(i+1)-1 downto 8*i);
    end loop;
  end loop;

  p_SendCfgPkt(C_WRITE, C_FIFO_OFF, C_CFGDEV_HDD, C_DSN_HDD_REG_RBUF_CTRL_L, datasize, i_dev_ctrl, data, bus_in, bus_out);
  wait_cycles(4, lclk);
  --// Конфигурирование RAMBUF Накопителя
  --//End
  ----------------------------------------------------
  ----------------------------------------------------------------------------------------

  ----------------------------------------------------------------------------------------
  ----------------------------------------------------
  --// Запись командного пакета в Накопитель
  --//Begin
  i_dev_ctrl(C_HREG_DEV_CTRL_DEV_ADDR_MSB_BIT downto C_HREG_DEV_CTRL_DEV_ADDR_LSB_BIT):=CONV_STD_LOGIC_VECTOR(C_HDEV_CFG_DBUF, C_HREG_DEV_CTRL_DEV_ADDR_SIZE);
  data(0 to 3) :=conv_byte_vector(i_dev_ctrl);
  plxsim_write_const(C_LBUS_DATA_BITS, C_MULTBURST_OFF, (C_VM_USR_REG_BAR+CONV_STD_LOGIC_VECTOR(C_HOST_REG_DEV_CTRL*C_VM_USR_REG_BCOUNT, 32)), be(0 to 3), data(0 to 3), n, bus_in, bus_out);


  --//Формируем командный пакет для накопителя
  --//поле user_ctrl
  User_Reg(0):=(others=>'0');
--  User_Reg(0)(C_TRLR_REG_USER_CTRL_MODE_MSB_BIT downto C_TRLR_REG_USER_CTRL_MODE_LSB_BIT):=CONV_STD_LOGIC_VECTOR(C_TRLR_REG_USER_CTRL_MODE_HW, (C_TRLR_REG_USER_CTRL_MODE_MSB_BIT - C_TRLR_REG_USER_CTRL_MODE_LSB_BIT+1));
--  User_Reg(0)(C_TRLR_REG_USER_CTRL_SATA_CS_MASK_MSB_BIT downto C_TRLR_REG_USER_CTRL_SATA_CS_MASK_LSB_BIT):=CONV_STD_LOGIC_VECTOR(hdd_mask, (C_TRLR_REG_USER_CTRL_SATA_CS_MASK_MSB_BIT - C_TRLR_REG_USER_CTRL_SATA_CS_MASK_LSB_BIT+1));

  User_Reg(1)(15 downto 0):=CONV_STD_LOGIC_VECTOR(16#01#, 16);                 --//поле feature
  User_Reg(2)(15 downto 0):=CONV_STD_LOGIC_VECTOR(16#02#, 16);                 --//поле lba
  User_Reg(3)(15 downto 0):=CONV_STD_LOGIC_VECTOR(16#03#, 16);                 --//поле lba
  User_Reg(4)(15 downto 0):=CONV_STD_LOGIC_VECTOR(16#04#, 16);                 --//поле lba
  User_Reg(5)(15 downto 0):=CONV_STD_LOGIC_VECTOR(hdd_SectorCount, 16);                 --//поле SectorCount
  User_Reg(6)(15 downto 0):=CONV_STD_LOGIC_VECTOR(C_ATA_CMD_WRITE_DMA_EXT, 16);--//поле Command

  datasize:=7;
  for y in 0 to datasize - 1 loop
    for i in 0 to 4 - 1 loop
      data((y*4)+i)(7 downto 0) := User_Reg(y)(8*(i+1)-1 downto 8*i);
    end loop;
  end loop;

  p_SendCfgPkt(C_WRITE, C_FIFO_ON, C_CFGDEV_HDD, C_DSN_HDD_REG_CMDFIFO, datasize, i_dev_ctrl, data, bus_in, bus_out);

  wait_cycles(4, lclk);
  --// Запись командного пакета в Накопитель
  --//End
  ----------------------------------------------------
  ----------------------------------------------------------------------------------------


  ----------------------------------------------------------------------------------------
  ----------------------------------------------------
  --// Пуск модуля DSN_TESTING.VHD
  --//Begin
  i_dev_ctrl(C_HREG_DEV_CTRL_DEV_ADDR_MSB_BIT downto C_HREG_DEV_CTRL_DEV_ADDR_LSB_BIT):=CONV_STD_LOGIC_VECTOR(C_HDEV_CFG_DBUF, C_HREG_DEV_CTRL_DEV_ADDR_SIZE);
  data(0 to 3) :=conv_byte_vector(i_dev_ctrl);
  plxsim_write_const(C_LBUS_DATA_BITS, C_MULTBURST_OFF, (C_VM_USR_REG_BAR+CONV_STD_LOGIC_VECTOR(C_HOST_REG_DEV_CTRL*C_VM_USR_REG_BCOUNT, 32)), be(0 to 3), data(0 to 3), n, bus_in, bus_out);

  --//Готовим значения регистров:
  --//C_DSN_TSTING_REG_T05_US
  User_Reg(0):=(others=>'0');
  User_Reg(0):=CONV_STD_LOGIC_VECTOR(10, User_Reg(0)'length);

  datasize:=1;
  for y in 0 to datasize - 1 loop
    for i in 0 to 4 - 1 loop
      data((y*4)+i)(7 downto 0) := User_Reg(y)(8*(i+1)-1 downto 8*i);
    end loop;
  end loop;

  p_SendCfgPkt(C_WRITE, C_FIFO_OFF, C_CFGDEV_TESTING, C_DSN_TSTING_REG_T05_US, datasize, i_dev_ctrl, data, bus_in, bus_out);
  wait_cycles(4, lclk);


  --//Готовим значения регистров:
  --//C_DSN_TSTING_REG_CTRL_L
  User_Reg(0):=(others=>'0');
  User_Reg(0)(C_DSN_TSTING_REG_CTRL_MODE_MSB_BIT downto C_DSN_TSTING_REG_CTRL_MODE_LSB_BIT):=CONV_STD_LOGIC_VECTOR(C_DSN_TSTING_MODE_SEND_TXD_STREAM, (C_DSN_TSTING_REG_CTRL_MODE_MSB_BIT-C_DSN_TSTING_REG_CTRL_MODE_LSB_BIT+1));
--  User_Reg(0)(C_DSN_TSTING_REG_CTRL_MODE_MSB_BIT downto C_DSN_TSTING_REG_CTRL_MODE_LSB_BIT):=CONV_STD_LOGIC_VECTOR(C_DSN_TSTING_MODE_SEND_TXD_SINGL, (C_DSN_TSTING_REG_CTRL_MODE_MSB_BIT-C_DSN_TSTING_REG_CTRL_MODE_LSB_BIT+1));
  User_Reg(0)(C_DSN_TSTING_REG_CTRL_START_BIT):='1';
  User_Reg(0)(C_DSN_TSTING_REG_CTRL_FRAME_GRAY_BIT):=Pix8bit;
  User_Reg(0)(C_DSN_TSTING_REG_CTRL_FRTXD_2DW_CNT_BIT):=FrTxD_2DW_cnt;
  User_Reg(0)(C_DSN_TSTING_REG_CTRL_FRAME_TSTDATA_2_BIT):=TstData_02ver;
  User_Reg(0)(C_DSN_TSTING_REG_CTRL_FRAME_CH_AUTO_BIT):=AutoVCH_Change;

  datasize:=1;
  for y in 0 to datasize - 1 loop
    for i in 0 to 4 - 1 loop
      data((y*4)+i)(7 downto 0) := User_Reg(y)(8*(i+1)-1 downto 8*i);
    end loop;
  end loop;

  p_SendCfgPkt(C_WRITE, C_FIFO_OFF, C_CFGDEV_TESTING, C_DSN_TSTING_REG_CTRL_L, datasize, i_dev_ctrl, data, bus_in, bus_out);
  wait_cycles(80, lclk);
  --// Пуск модуля DSN_TESTING.VHD
  --//End
  ----------------------------------------------------
  ----------------------------------------------------------------------------------------



  ----------------------------------------------------------------------------------------
  ----------------------------------------------------
  --// Чтение Данных Track
  --//Begin
  wait_cycles(track_read_01_start, lclk);


  wait_cycles(track_read_01_end, lclk);

  i_dev_ctrl:=(others=>'0');
--  i_dev_ctrl(C_HREG_GCTRL0_RDDONE_TRC_BIT):='1';
  i_dev_ctrl(C_HREG_GCTRL0_RDDONE_TRCNIK_BIT):='1';

  data(0 to 3) :=conv_byte_vector(i_dev_ctrl);
  plxsim_write_const(C_LBUS_DATA_BITS, C_MULTBURST_OFF, (C_VM_USR_REG_BAR+CONV_STD_LOGIC_VECTOR(C_HOST_REG_GLOB_CTRL0*C_VM_USR_REG_BCOUNT, 32)), be(0 to 3), data(0 to 3), n, bus_in, bus_out);


  wait_cycles(4, lclk);

  --// Чтение Данных Track
  --//End
  ----------------------------------------------------
  ----------------------------------------------------------------------------------------

  ----------------------------------------------------------------------------------------
  ----------------------------------------------------
  --// Чтения VIDEO
  --//Begin
  wait_cycles(vctrl_read_01_start, lclk);

  i_dev_ctrl(C_HREG_DEV_CTRL_DEV_ADDR_MSB_BIT downto C_HREG_DEV_CTRL_DEV_ADDR_LSB_BIT):=CONV_STD_LOGIC_VECTOR(C_HDEV_VCH_DBUF, C_HREG_DEV_CTRL_DEV_ADDR_SIZE);
  i_dev_ctrl(C_HREG_DEV_CTRL_DEV_VCH_MSB_BIT downto C_HREG_DEV_CTRL_DEV_VCH_LSB_BIT):=CONV_STD_LOGIC_VECTOR(0, C_HREG_DEV_CTRL_DEV_VCH_MSB_BIT-C_HREG_DEV_CTRL_DEV_VCH_LSB_BIT+1);
  i_dev_ctrl(C_HREG_DEV_CTRL_DEV_TRN_START_BIT):='1';

  data(0 to 3) :=conv_byte_vector(i_dev_ctrl);
  plxsim_write_const(C_LBUS_DATA_BITS, C_MULTBURST_OFF, (C_VM_USR_REG_BAR+CONV_STD_LOGIC_VECTOR(C_HOST_REG_DEV_CTRL*C_VM_USR_REG_BCOUNT, 32)), be(0 to 3), data(0 to 3), n, bus_in, bus_out);

  i_dev_ctrl(C_HREG_DEV_CTRL_DEV_VCH_MSB_BIT downto C_HREG_DEV_CTRL_DEV_VCH_LSB_BIT):=CONV_STD_LOGIC_VECTOR(0, C_HREG_DEV_CTRL_DEV_VCH_MSB_BIT-C_HREG_DEV_CTRL_DEV_VCH_LSB_BIT+1);
  i_dev_ctrl(C_HREG_DEV_CTRL_DEV_TRN_START_BIT):='0';

  wait_cycles(vctrl_read_01_end, lclk);

  i_dev_ctrl:=(others=>'0');
  i_dev_ctrl(C_HREG_GCTRL0_RDDONE_VCTRL_BIT):='1';

  data(0 to 3) :=conv_byte_vector(i_dev_ctrl);
  plxsim_write_const(C_LBUS_DATA_BITS, C_MULTBURST_OFF, (C_VM_USR_REG_BAR+CONV_STD_LOGIC_VECTOR(C_HOST_REG_GLOB_CTRL0*C_VM_USR_REG_BCOUNT, 32)), be(0 to 3), data(0 to 3), n, bus_in, bus_out);

  wait_cycles(4, lclk);

  --// Чтения VIDEO
  --//End
  ----------------------------------------------------
  ----------------------------------------------------------------------------------------

  ----------------------------------------------------------------------------------------
  ----------------------------------------------------
  --// Чтения VIDEO
  --//Begin
  wait_cycles(vctrl_read_02_start, lclk);

  i_dev_ctrl(C_HREG_DEV_CTRL_DEV_ADDR_MSB_BIT downto C_HREG_DEV_CTRL_DEV_ADDR_LSB_BIT):=CONV_STD_LOGIC_VECTOR(C_HDEV_VCH_DBUF, C_HREG_DEV_CTRL_DEV_ADDR_SIZE);
  i_dev_ctrl(C_HREG_DEV_CTRL_DEV_VCH_MSB_BIT downto C_HREG_DEV_CTRL_DEV_VCH_LSB_BIT):=CONV_STD_LOGIC_VECTOR(0, C_HREG_DEV_CTRL_DEV_VCH_MSB_BIT-C_HREG_DEV_CTRL_DEV_VCH_LSB_BIT+1);
  i_dev_ctrl(C_HREG_DEV_CTRL_DEV_TRN_START_BIT):='1';

  data(0 to 3) :=conv_byte_vector(i_dev_ctrl);
  plxsim_write_const(C_LBUS_DATA_BITS, C_MULTBURST_OFF, (C_VM_USR_REG_BAR+CONV_STD_LOGIC_VECTOR(C_HOST_REG_DEV_CTRL*C_VM_USR_REG_BCOUNT, 32)), be(0 to 3), data(0 to 3), n, bus_in, bus_out);

  i_dev_ctrl(C_HREG_DEV_CTRL_DEV_VCH_MSB_BIT downto C_HREG_DEV_CTRL_DEV_VCH_LSB_BIT):=CONV_STD_LOGIC_VECTOR(0, C_HREG_DEV_CTRL_DEV_VCH_MSB_BIT-C_HREG_DEV_CTRL_DEV_VCH_LSB_BIT+1);
  i_dev_ctrl(C_HREG_DEV_CTRL_DEV_TRN_START_BIT):='0';

  wait_cycles(vctrl_read_02_end, lclk);

  i_dev_ctrl:=(others=>'0');
  i_dev_ctrl(C_HREG_GCTRL0_RDDONE_VCTRL_BIT):='1';

  data(0 to 3) :=conv_byte_vector(i_dev_ctrl);
  plxsim_write_const(C_LBUS_DATA_BITS, C_MULTBURST_OFF, (C_VM_USR_REG_BAR+CONV_STD_LOGIC_VECTOR(C_HOST_REG_GLOB_CTRL0*C_VM_USR_REG_BCOUNT, 32)), be(0 to 3), data(0 to 3), n, bus_in, bus_out);

  wait_cycles(4, lclk);

  --// Чтения VIDEO
  --//End
  ----------------------------------------------------
  ----------------------------------------------------------------------------------------


--  ----------------------------------------------------------------------------------------
--  ----------------------------------------------------
--  --// Стоп модуля DSN_TESTING.VHD
--  --//Begin
--  i_dev_ctrl(C_HREG_DEV_CTRL_DEV_ADDR_MSB_BIT downto C_HREG_DEV_CTRL_DEV_ADDR_LSB_BIT):=CONV_STD_LOGIC_VECTOR(C_HDEV_CFG_DBUF, C_HREG_DEV_CTRL_DEV_ADDR_SIZE);
--  data(0 to 3) :=conv_byte_vector(i_dev_ctrl);
--  plxsim_write_const(C_LBUS_DATA_BITS, C_MULTBURST_OFF, (C_VM_USR_REG_BAR+CONV_STD_LOGIC_VECTOR(C_HOST_REG_DEV_CTRL*C_VM_USR_REG_BCOUNT, 32)), be(0 to 3), data(0 to 3), n, bus_in, bus_out);
--
--  --//Готовим значения регистров:
--  --//C_DSN_TSTING_REG_CTRL_L
--  User_Reg(0):=(others=>'0');
--  User_Reg(0)(C_DSN_TSTING_REG_CTRL_MODE_MSB_BIT downto C_DSN_TSTING_REG_CTRL_MODE_LSB_BIT):=CONV_STD_LOGIC_VECTOR(C_DSN_TSTING_MODE_SEND_TXD_STREAM, (C_DSN_TSTING_REG_CTRL_MODE_MSB_BIT-C_DSN_TSTING_REG_CTRL_MODE_LSB_BIT+1));
----  User_Reg(0)(C_DSN_TSTING_REG_CTRL_MODE_MSB_BIT downto C_DSN_TSTING_REG_CTRL_MODE_LSB_BIT):=CONV_STD_LOGIC_VECTOR(C_DSN_TSTING_MODE_SEND_TXD_SINGL, (C_DSN_TSTING_REG_CTRL_MODE_MSB_BIT-C_DSN_TSTING_REG_CTRL_MODE_LSB_BIT+1));
--  User_Reg(0)(C_DSN_TSTING_REG_CTRL_START_BIT):='0';
--
--  datasize:=1;
--  for y in 0 to datasize - 1 loop
--    for i in 0 to 4 - 1 loop
--      data((y*4)+i)(7 downto 0) := User_Reg(y)(8*(i+1)-1 downto 8*i);
--    end loop;
--  end loop;
--
--  p_SendCfgPkt(C_WRITE, C_FIFO_OFF, C_CFGDEV_TESTING, C_DSN_TSTING_REG_CTRL_L, datasize, i_dev_ctrl, data, bus_in, bus_out);
--  wait_cycles(4, lclk);
--  --// Стоп модуля DSN_TESTING.VHD
--  --//End
--  ----------------------------------------------------
--  ----------------------------------------------------------------------------------------

--  ----------------------------------------------------------------------------------------
--  ----------------------------------------------------
--  --// Настройка модуля DSN_VPROC.VHD
--  --//Begin
--  i_dev_ctrl(C_HREG_DEV_CTRL_DEV_ADDR_MSB_BIT downto C_HREG_DEV_CTRL_DEV_ADDR_LSB_BIT):=CONV_STD_LOGIC_VECTOR(C_HDEV_CFG_DBUF, C_HREG_DEV_CTRL_DEV_ADDR_SIZE);
--  data(0 to 3) :=conv_byte_vector(i_dev_ctrl);
--  plxsim_write_const(C_LBUS_DATA_BITS, C_MULTBURST_OFF, (C_VM_USR_REG_BAR+CONV_STD_LOGIC_VECTOR(C_HOST_REG_DEV_CTRL*C_VM_USR_REG_BCOUNT, 32)), be(0 to 3), data(0 to 3), n, bus_in, bus_out);
--
--  --//Установка MEM_TRN
--  --//Готовим значения регистров:
--  User_Reg(0)(15 downto 0):=CONV_STD_LOGIC_VECTOR(16#0004#, 16);  --//C_DSN_VPROC_REG_PRM_DATA_LSB
--  User_Reg(1)(15 downto 0):=CONV_STD_LOGIC_VECTOR(16#0010#, 16);  --//C_DSN_VPROC_REG_PRM_DATA_MSB
--
--  datasize:=2;
--  for y in 0 to datasize - 1 loop
--    for i in 0 to 4 - 1 loop
--      data((y*4)+i)(7 downto 0) := User_Reg(y)(8*(i+1)-1 downto 8*i);
--    end loop;
--  end loop;
--
--  p_SendCfgPkt(C_WRITE, C_FIFO_OFF, C_CFGDEV_VPRC_ADR, C_DSN_VPROC_REG_PRM_DATA_LSB, datasize, i_dev_ctrl, data, bus_in, bus_out);
--
--  --//Готовим значения регистров:
--  User_Reg(0)(C_DSN_VPROC_REG_CTRL_CH_IDX_MSB_BIT downto C_DSN_VPROC_REG_CTRL_CH_IDX_LSB_BIT):=CONV_STD_LOGIC_VECTOR(16#00#, C_DSN_VPROC_REG_CTRL_CH_IDX_MSB_BIT-C_DSN_VPROC_REG_CTRL_CH_IDX_LSB_BIT+1);
--  User_Reg(0)(C_DSN_VPROC_REG_CTRL_PRM_IDX_MSB_BIT downto C_DSN_VPROC_REG_CTRL_PRM_IDX_LSB_BIT):=CONV_STD_LOGIC_VECTOR(C_DSN_VPROC_PARAM_MEM_TRN, C_DSN_VPROC_REG_CTRL_PRM_IDX_MSB_BIT-C_DSN_VPROC_REG_CTRL_PRM_IDX_LSB_BIT+1);
--  User_Reg(0)(C_DSN_VPROC_REG_CTRL_SET_BIT):='1';
--
--  datasize:=1;
--  for y in 0 to datasize - 1 loop
--    for i in 0 to 4 - 1 loop
--      data((y*4)+i)(7 downto 0) := User_Reg(y)(8*(i+1)-1 downto 8*i);
--    end loop;
--  end loop;
--
--  p_SendCfgPkt(C_WRITE, C_FIFO_OFF, C_CFGDEV_VPRC_ADR, C_DSN_VPROC_REG_CTRL_L, datasize, i_dev_ctrl, data, bus_in, bus_out);
--
--
--
--
--  --//Готовим значения регистров:
--  User_Reg(0)(15 downto 0):=(others=>'0');
--  User_Reg(0)(C_DSN_VPROC_REG_CTRL_WORK_BIT):='1';  --//C_DSN_VPROC_REG_CTRL_L
--
--  datasize:=1;
--  for y in 0 to datasize - 1 loop
--    for i in 0 to 4 - 1 loop
--      data((y*4)+i)(7 downto 0) := User_Reg(y)(8*(i+1)-1 downto 8*i);
--    end loop;
--  end loop;
--
--  p_SendCfgPkt(C_WRITE, C_FIFO_OFF, C_CFGDEV_VPRC_ADR, C_DSN_VPROC_REG_CTRL_L, datasize, i_dev_ctrl, data, bus_in, bus_out);
--
--  wait_cycles(4, lclk);
--  --// Настройка модуля DSN_VPROC.VHD
--  --//End
--  ----------------------------------------------------
--  ----------------------------------------------------------------------------------------




  ----------------------------------------------------------------------------------------
  ----------------------------------------------------
  --// Чтение буфера HOST_VIDEOOUT
  --//Begin
  i_dev_ctrl(C_HREG_DEV_CTRL_DEV_ADDR_MSB_BIT downto C_HREG_DEV_CTRL_DEV_ADDR_LSB_BIT):=CONV_STD_LOGIC_VECTOR(C_HDEV_VCH_DBUF, C_HREG_DEV_CTRL_DEV_ADDR_SIZE);
  data(0 to 3) :=conv_byte_vector(i_dev_ctrl);
  plxsim_write_const(C_LBUS_DATA_BITS, C_MULTBURST_OFF, (C_VM_USR_REG_BAR+CONV_STD_LOGIC_VECTOR(C_HOST_REG_DEV_CTRL*C_VM_USR_REG_BCOUNT, 32)), be(0 to 3), data(0 to 3), n, bus_in, bus_out);

  tag := 0;
  val32 := X"00000001";
  remaining:=1*10#32#;--+32;--//Кол-во в байтах
  offset:=0;
  while remaining /= 0 loop
      chunk := 10#1024#;
      if chunk > remaining then
        chunk := remaining;
      end if;

      plxsim_read_const(C_LBUS_DATA_BITS, C_MULTBURST_OFF, X"00200000", be(0 to chunk - 1), data(0 to chunk - 1), n, bus_in, bus_out);
      remaining := remaining - n;
      tag := tag + (n / 4);
  end loop;
  --// Чтение буфера HOST_VIDEOOUT
  --//End
  ----------------------------------------------------
  ----------------------------------------------------------------------------------------

  wait_cycles(800000, lclk);



  ----------------------------------------------------------------------------------------
  ----------------------------------------------------
  --// Loop Back FIFO EthG
  --//Begin
  ----------------------------------------------------
  i_dev_ctrl(C_HREG_DEV_CTRL_DEV_ADDR_MSB_BIT downto C_HREG_DEV_CTRL_DEV_ADDR_LSB_BIT):=CONV_STD_LOGIC_VECTOR(C_HDEV_CFG_DBUF, C_HREG_DEV_CTRL_DEV_ADDR_SIZE);
  data(0 to 3) :=conv_byte_vector(i_dev_ctrl);
  plxsim_write_const(C_LBUS_DATA_BITS, C_MULTBURST_OFF, (C_VM_USR_REG_BAR+CONV_STD_LOGIC_VECTOR(C_HOST_REG_DEV_CTRL*C_VM_USR_REG_BCOUNT, 32)), be(0 to 3), data(0 to 3), n, bus_in, bus_out);
--
--//Write CFGPkt
--//1. Настройка модуля DSN_SWITCH.vhd
  datasize:=1;
  val32:=(others=>'0');
  val32(C_DSN_SWT_REG_CTRL_ETHTXD_LOOPBACK_BIT):='1';
  for i in 0 to 4 - 1 loop
    data(i)(7 downto 0) := val32(8*(i+1)-1 downto 8*i);
  end loop;

  p_SendCfgPkt(C_WRITE, C_FIFO_OFF, C_CFGDEV_SWT, C_DSN_SWT_REG_CTRL_L, datasize, i_dev_ctrl, data, bus_in, bus_out);


  i_dev_ctrl(C_HREG_DEV_CTRL_DEV_ADDR_MSB_BIT downto C_HREG_DEV_CTRL_DEV_ADDR_LSB_BIT):=CONV_STD_LOGIC_VECTOR(C_HDEV_ETHG_DBUF, C_HREG_DEV_CTRL_DEV_ADDR_SIZE);
  i_dev_ctrl(C_HREG_DEV_CTRL_DEV_DIN_RDY_BIT):='0';
  data(0 to 3) :=conv_byte_vector(i_dev_ctrl);
  plxsim_write_const(C_LBUS_DATA_BITS, C_MULTBURST_OFF, (C_VM_USR_REG_BAR+CONV_STD_LOGIC_VECTOR(C_HOST_REG_DEV_CTRL*C_VM_USR_REG_BCOUNT, 32)), be(0 to 3), data(0 to 3), n, bus_in, bus_out);

--//Write DATA to TXFIFO-EthG
  tag := 0;
  val32 := X"00000001";
  remaining:=1*32;--//Сколько данных передовать.( Кол-во в байтах)
  offset:=0;
  while remaining /= 0 loop
      chunk := 10#32#;--//Размер пакета данных
      if chunk > remaining then
        chunk := remaining;
      end if;

      for i in 0 to chunk / 4 - 1 loop
        data(4 * i to 4 * (i + 1) - 1) := conv_byte_vector(val32 + tag + i);
      end loop;

      --//Ждем запроса от модуля vereskm_main.vhd на работу в demand-mode DMA
      plxsim_write_const(C_LBUS_DATA_BITS, C_MULTBURST_OFF, X"00200000", be(0 to chunk - 1), data(0 to chunk - 1), n, bus_in, bus_out);
--      plxsim_write(C_LBUS_DATA_BITS, C_MULTBURST_ON, (C_VM_USR_REG_BAR+CONV_STD_LOGIC_VECTOR(C_HOST_REG_DEV_DATA*C_VM_USR_REG_BCOUNT, 32)), be(0 to chunk - 1), data(0 to chunk - 1), n, bus_in, bus_out);
      remaining := remaining - n;
      tag := tag + (n / 4);
  end loop;

  i_dev_ctrl(C_HREG_DEV_CTRL_DEV_ADDR_MSB_BIT downto C_HREG_DEV_CTRL_DEV_ADDR_LSB_BIT):=CONV_STD_LOGIC_VECTOR(C_HDEV_ETHG_DBUF, C_HREG_DEV_CTRL_DEV_ADDR_SIZE);
  i_dev_ctrl(C_HREG_DEV_CTRL_DEV_DIN_RDY_BIT):='1';
  data(0 to 3) :=conv_byte_vector(i_dev_ctrl);
  plxsim_write_const(C_LBUS_DATA_BITS, C_MULTBURST_OFF, (C_VM_USR_REG_BAR+CONV_STD_LOGIC_VECTOR(C_HOST_REG_DEV_CTRL*C_VM_USR_REG_BCOUNT, 32)), be(0 to 3), data(0 to 3), n, bus_in, bus_out);

  i_dev_ctrl(C_HREG_DEV_CTRL_DEV_ADDR_MSB_BIT downto C_HREG_DEV_CTRL_DEV_ADDR_LSB_BIT):=CONV_STD_LOGIC_VECTOR(C_HDEV_ETHG_DBUF, C_HREG_DEV_CTRL_DEV_ADDR_SIZE);
  i_dev_ctrl(C_HREG_DEV_CTRL_DEV_DIN_RDY_BIT):='0';
  data(0 to 3) :=conv_byte_vector(i_dev_ctrl);
   plxsim_write_const(C_LBUS_DATA_BITS, C_MULTBURST_OFF, (C_VM_USR_REG_BAR+CONV_STD_LOGIC_VECTOR(C_HOST_REG_DEV_CTRL*C_VM_USR_REG_BCOUNT, 32)), be(0 to 3), data(0 to 3), n, bus_in, bus_out);

--//Read FIFO_ETHG
  tag := 0;
  val32 := X"00000001";
  remaining:=1*10#32#;--+32;--//Кол-во в байтах
  offset:=0;
  while remaining /= 0 loop
      chunk := 10#32#;
      if chunk > remaining then
        chunk := remaining;
      end if;

--     plxsim_read_const(C_LBUS_DATA_BITS, C_MULTBURST_OFF, (C_VM_USR_REG_BAR+CONV_STD_LOGIC_VECTOR(C_HOST_REG_DEV_DATA*C_VM_USR_REG_BCOUNT, 32)), be(0 to chunk - 1), data(0 to chunk - 1), n, bus_in, bus_out);
--      plxsim_write_const(C_LBUS_DATA_BITS, C_MULTBURST_OFF, X"00200000", be(0 to chunk - 1), data(0 to chunk - 1), n, bus_in, bus_out);
      plxsim_read_const(C_LBUS_DATA_BITS, C_MULTBURST_OFF, X"00200000", be(0 to chunk - 1), data(0 to chunk - 1), n, bus_in, bus_out);
      remaining := remaining - n;
      tag := tag + (n / 4);
  end loop;
  --// End Loop Back FIFO EthG
  wait_cycles(16, lclk);
  ----------------------------------------------------
  --// Loop Back FIFO EthG
  --//End
  ----------------------------------------------------
  ----------------------------------------------------------------------------------------


--//Write RAM
  --//Уст. адрес C_HDEV_CFG_DBUF
  i_dev_ctrl(C_HREG_DEV_CTRL_DEV_ADDR_MSB_BIT downto C_HREG_DEV_CTRL_DEV_ADDR_LSB_BIT):=CONV_STD_LOGIC_VECTOR(C_HDEV_MEM_DBUF, C_HREG_DEV_CTRL_DEV_ADDR_SIZE);
  data(0 to 3) :=conv_byte_vector(i_dev_ctrl);
  plxsim_write_const(C_LBUS_DATA_BITS, C_MULTBURST_OFF, (C_VM_USR_REG_BAR+CONV_STD_LOGIC_VECTOR(C_HOST_REG_DEV_CTRL*C_VM_USR_REG_BCOUNT, 32)), be(0 to 3), data(0 to 3), n, bus_in, bus_out);

  tag := 0;
  val32 := X"00000001";
  remaining:=1*16;--//Сколько данных передовать.( Кол-во в байтах)
  offset:=0;
  while remaining /= 0 loop
      chunk := 10#16#;--//Размер пакета данных
      if chunk > remaining then
        chunk := remaining;
      end if;

      for i in 0 to chunk / 4 - 1 loop
        data(4 * i to 4 * (i + 1) - 1) := conv_byte_vector(val32 + tag + i);
      end loop;

      --//Ждем запроса от модуля vereskm_main.vhd на работу в demand-mode DMA
      plxsim_write(C_LBUS_DATA_BITS, C_MULTBURST_ON, X"00200000", be(0 to chunk - 1), data(0 to chunk - 1), n, bus_in, bus_out);
      remaining := remaining - n;
      tag := tag + (n / 4);
  end loop;
  wait_cycles(4, lclk);

  ----------------------------------------------------------------------------------------
  ----------------------------------------------------
  --// Тестирование модуля dsn_video_ctrl.vhd
  --// (Запись данных в DRAM)
  --//Begin
  ----------------------------------------------------
  --//Уст. адрес C_HDEV_CFG_DBUF
  i_dev_ctrl(C_HREG_DEV_CTRL_DEV_ADDR_MSB_BIT downto C_HREG_DEV_CTRL_DEV_ADDR_LSB_BIT):=CONV_STD_LOGIC_VECTOR(C_HDEV_CFG_DBUF, C_HREG_DEV_CTRL_DEV_ADDR_SIZE);
  data(0 to 3) :=conv_byte_vector(i_dev_ctrl);
  plxsim_write_const(C_LBUS_DATA_BITS, C_MULTBURST_OFF, (C_VM_USR_REG_BAR+CONV_STD_LOGIC_VECTOR(C_HOST_REG_DEV_CTRL*C_VM_USR_REG_BCOUNT, 32)), be(0 to 3), data(0 to 3), n, bus_in, bus_out);

--//Write CFGPkt
--//1. Настройка модуля DSN_SWITCH.vhd
  datasize:=1;
  val32:=(others=>'0');
  val32(C_DSN_SWT_REG_CTRL_ETHTXD_LOOPBACK_BIT):='0';
  for i in 0 to 4 - 1 loop
    data(i)(7 downto 0) := val32(8*(i+1)-1 downto 8*i);
  end loop;
  p_SendCfgPkt(C_WRITE, C_FIFO_OFF, C_CFGDEV_SWT, C_DSN_SWT_REG_CTRL_L, datasize, i_dev_ctrl, data, bus_in, bus_out);


----//Write CFGPkt
----//2. Настройка модуля DSN_VCTRL.vhd
--  datasize:=1;
--  val32:=(others=>'0');
--  val32(15 downto 0):=CONV_STD_LOGIC_VECTOR(16#0000#, 16);
--  for i in 0 to 4 - 1 loop
--    data(i)(7 downto 0) := val32(8*(i+1)-1 downto 8*i);
--  end loop;
--  p_SendCfgPkt(C_WRITE, C_FIFO_OFF, C_CFGDEV_VCTRL, C_DSN_VCTRL_REG_MEM_ADDR_VCH0_LSB, datasize, i_dev_ctrl, data, bus_in, bus_out);
--
--  datasize:=1;
--  val32:=(others=>'0');
--  val32(15 downto 0):=CONV_STD_LOGIC_VECTOR(16#1000#, 16);
--  for i in 0 to 4 - 1 loop
--    data(i)(7 downto 0) := val32(8*(i+1)-1 downto 8*i);
--  end loop;
--  p_SendCfgPkt(C_WRITE, C_FIFO_OFF, C_CFGDEV_VCTRL, C_DSN_VCTRL_REG_MEM_ADDR_VCH0_LSB, datasize, i_dev_ctrl, data, bus_in, bus_out);

--  datasize:=1;
--  val32:=(others=>'0');
--  val32(15 downto 0):=CONV_STD_LOGIC_VECTOR(16#0300#, 16);
--  for i in 0 to 4 - 1 loop
--    data(i)(7 downto 0) := val32(8*(i+1)-1 downto 8*i);
--  end loop;
--  p_SendCfgPkt(C_WRITE, C_FIFO_OFF, C_CFGDEV_VCTRL, C_DSN_VCTRL_REG_MEM_CTRL_LSB, datasize, i_dev_ctrl, data, bus_in, bus_out);
--
--  datasize:=1;
--  val32:=(others=>'0');
--  val32(15 downto 0):=CONV_STD_LOGIC_VECTOR(16#0000#, 16);
--  for i in 0 to 4 - 1 loop
--    data(i)(7 downto 0) := val32(8*(i+1)-1 downto 8*i);
--  end loop;
--  p_SendCfgPkt(C_WRITE, C_FIFO_OFF, C_CFGDEV_VCTRL, C_DSN_VCTRL_REG_MEM_CTRL_MSB, datasize, i_dev_ctrl, data, bus_in, bus_out);

--//Write CFGPkt
--//Начать операцию
  datasize:=1;
  val32:=(others=>'0');
  val32(15 downto 0):=CONV_STD_LOGIC_VECTOR(16#0001#, 16);
  for i in 0 to 4 - 1 loop
    data(i)(7 downto 0) := val32(8*(i+1)-1 downto 8*i);
  end loop;
  p_SendCfgPkt(C_WRITE, C_FIFO_OFF, C_CFGDEV_VCTRL, C_DSN_VCTRL_REG_CTRL_L, datasize, i_dev_ctrl, data, bus_in, bus_out);


  i_dev_ctrl(C_HREG_DEV_CTRL_DEV_ADDR_MSB_BIT downto C_HREG_DEV_CTRL_DEV_ADDR_LSB_BIT):=CONV_STD_LOGIC_VECTOR(C_HDEV_ETHG_DBUF, C_HREG_DEV_CTRL_DEV_ADDR_SIZE);
  i_dev_ctrl(C_HREG_DEV_CTRL_DEV_DIN_RDY_BIT):='0';
  data(0 to 3) :=conv_byte_vector(i_dev_ctrl);
  plxsim_write_const(C_LBUS_DATA_BITS, C_MULTBURST_OFF, (C_VM_USR_REG_BAR+CONV_STD_LOGIC_VECTOR(C_HOST_REG_DEV_CTRL*C_VM_USR_REG_BCOUNT, 32)), be(0 to 3), data(0 to 3), n, bus_in, bus_out);

--//Write DATA to TXFIFO-EthG
  tag := 0;
  val32 := X"00000001";
  remaining:=2*128;--//Сколько данных передовать.( Кол-во в байтах)
  offset:=0;
  while remaining /= 0 loop
      chunk := 10#128#;--//Размер пакета данных
      if chunk > remaining then
        chunk := remaining;
      end if;

      for i in 0 to chunk / 4 - 1 loop
        data(4 * i to 4 * (i + 1) - 1) := conv_byte_vector(val32 + tag + i);
      end loop;

      --//Ждем запроса от модуля vereskm_main.vhd на работу в demand-mode DMA
      plxsim_write_const(C_LBUS_DATA_BITS, C_MULTBURST_ON, X"00200000", be(0 to chunk - 1), data(0 to chunk - 1), n, bus_in, bus_out);
--      plxsim_write(C_LBUS_DATA_BITS, C_MULTBURST_ON, (C_VM_USR_REG_BAR+CONV_STD_LOGIC_VECTOR(C_HOST_REG_DEV_DATA*C_VM_USR_REG_BCOUNT, 32)), be(0 to chunk - 1), data(0 to chunk - 1), n, bus_in, bus_out);
      remaining := remaining - n;
      tag := tag + (n / 4);
  end loop;

  i_dev_ctrl(C_HREG_DEV_CTRL_DEV_DIN_RDY_BIT):='1';
  data(0 to 3) :=conv_byte_vector(i_dev_ctrl);
  plxsim_write_const(C_LBUS_DATA_BITS, C_MULTBURST_OFF, (C_VM_USR_REG_BAR+CONV_STD_LOGIC_VECTOR(C_HOST_REG_DEV_CTRL*C_VM_USR_REG_BCOUNT, 32)), be(0 to 3), data(0 to 3), n, bus_in, bus_out);

  i_dev_ctrl(C_HREG_DEV_CTRL_DEV_DIN_RDY_BIT):='0';
  data(0 to 3) :=conv_byte_vector(i_dev_ctrl);
  plxsim_write_const(C_LBUS_DATA_BITS, C_MULTBURST_OFF, (C_VM_USR_REG_BAR+CONV_STD_LOGIC_VECTOR(C_HOST_REG_DEV_CTRL*C_VM_USR_REG_BCOUNT, 32)), be(0 to 3), data(0 to 3), n, bus_in, bus_out);

  --// End Loop Back FIFO EthG
  wait_cycles(16, lclk);
  ----------------------------------------------------
  --// Тестирование модуля dsn_video_ctrl.vhd
  --// (Запись данных в DRAM)
  --//End
  ----------------------------------------------------
  ----------------------------------------------------------------------------------------






  ----------------------------------------------------------------------------------------
  ----------------------------------------------------
  --// Чтение регистров модуля тестирования
  --//Begin
  ----------------------------------------------------
  i_dev_ctrl(C_HREG_DEV_CTRL_DEV_ADDR_MSB_BIT downto C_HREG_DEV_CTRL_DEV_ADDR_LSB_BIT):=CONV_STD_LOGIC_VECTOR(C_HDEV_CFG_DBUF, C_HREG_DEV_CTRL_DEV_ADDR_SIZE);
  data(0 to 3) :=conv_byte_vector(i_dev_ctrl);
--  data(4 to 7) :=conv_byte_vector(X"DDDDCCCC");
  plxsim_write_const(C_LBUS_DATA_BITS, C_MULTBURST_OFF, (C_VM_USR_REG_BAR+CONV_STD_LOGIC_VECTOR(C_HOST_REG_DEV_CTRL*C_VM_USR_REG_BCOUNT, 32)), be(0 to 3), data(0 to 3), n, bus_in, bus_out);
--
--//Write CFGPkt
--//1. Настройка модуля DSN_SWITCH.vhd
--//Set ветвление данных EthG<->Host
--  --//1-WORD
--  data(0)(7 downto 0) := C_READ & C_FIFO_OFF & "000000";
--  data(1)(7 downto 0) := CONV_STD_LOGIC_VECTOR(C_CFGDEV_TESTING, 8);
--  --//2-WORD
--  data(2)(7 downto 0) := CONV_STD_LOGIC_VECTOR(C_DSN_TSTING_REG_PIX, 8);
--  data(3)(7 downto 0) := CONV_STD_LOGIC_VECTOR((4), 8);
--  --//3-WORD
--  data(4)(7 downto 0) := CONV_STD_LOGIC_VECTOR(16#A5#, 8);--
--  data(5)(7 downto 0) := CONV_STD_LOGIC_VECTOR(16#A6#, 8);--
--  --//4-WORD
--  data(6)(7 downto 0) := CONV_STD_LOGIC_VECTOR(16#A7#, 8);--
--  data(7)(7 downto 0) := CONV_STD_LOGIC_VECTOR(16#A8#, 8);--

  --//1-WORD
  data(0)(7 downto 0) := C_READ & C_FIFO_OFF & "000000";
  data(1)(7 downto 0) := CONV_STD_LOGIC_VECTOR(C_CFGDEV_TESTING, 8);
  --//2-WORD
  data(2)(7 downto 0) := CONV_STD_LOGIC_VECTOR(16#0#, 8);--
  data(3)(7 downto 0) := CONV_STD_LOGIC_VECTOR(16#0#, 8);--
  --//3-WORD
  data(4)(7 downto 0) := CONV_STD_LOGIC_VECTOR(C_DSN_TSTING_REG_ROW, 8);
  data(5)(7 downto 0) := CONV_STD_LOGIC_VECTOR((4), 8);
  --//3-WORD
  data(6)(7 downto 0) := CONV_STD_LOGIC_VECTOR(16#0#, 8);--
  data(7)(7 downto 0) := CONV_STD_LOGIC_VECTOR(16#0#, 8);--

  plxsim_write_const(C_LBUS_DATA_BITS, C_MULTBURST_ON, X"00200000", be(0 to 7), data(0 to 7), n, bus_in, bus_out);

  i_dev_ctrl(C_HREG_DEV_CTRL_DEV_DIN_RDY_BIT):='1';
  data(0 to 3) :=conv_byte_vector(i_dev_ctrl);
  data(4 to 7) :=conv_byte_vector(X"00000000");

  i_dev_ctrl(C_HREG_DEV_CTRL_DEV_DIN_RDY_BIT):='0';
  data(8 to 11) :=conv_byte_vector(i_dev_ctrl);
  data(12 to 15) :=conv_byte_vector(X"00000000");
  plxsim_write_const(C_LBUS_DATA_BITS, C_MULTBURST_ON, (C_VM_USR_REG_BAR+CONV_STD_LOGIC_VECTOR(C_HOST_REG_DEV_CTRL*C_VM_USR_REG_BCOUNT, 32)), be(0 to 15), data(0 to 15), n, bus_in, bus_out);


  wait_cycles(16, lclk);

--//Read FIFO_ETHG
  tag := 0;
  val32 := X"00000001";
  remaining:=1*10#16#;--+32;--//Кол-во в байтах
  offset:=0;
  while remaining /= 0 loop
      chunk := 10#16#;
      if chunk > remaining then
        chunk := remaining;
      end if;

      plxsim_read_const(C_LBUS_DATA_BITS, C_MULTBURST_OFF, X"00200000", be(0 to chunk - 1), data(0 to chunk - 1), n, bus_in, bus_out);
--      plxsim_read_const(C_LBUS_DATA_BITS, C_MULTBURST_OFF, (C_VM_USR_REG_BAR+CONV_STD_LOGIC_VECTOR(C_HOST_REG_DEV_DATA*C_VM_USR_REG_BCOUNT, 32)), be(0 to chunk - 1), data(0 to chunk - 1), n, bus_in, bus_out);
--      plxsim_write_const(C_LBUS_DATA_BITS, C_MULTBURST_ON, (C_VM_USR_REG_BAR+CONV_STD_LOGIC_VECTOR(C_HOST_REG_DEV_CTRL*C_VM_USR_REG_BCOUNT, 32)), be(0 to 7), data(0 to 7), n, bus_in, bus_out);
      remaining := remaining - n;
      tag := tag + (n / 4);
  end loop;
  ----------------------------------------------------
  --// Чтение регистров модуля тестирования
  --//End
  ----------------------------------------------------
  ----------------------------------------------------------------------------------------













----//Set CTRL
--datasize:=1;
--val32:=CONV_STD_LOGIC_VECTOR(0, 16)&CONV_STD_LOGIC_VECTOR(16#32#, 16);
--for i in 0 to 4 - 1 loop
--  data(i)(7 downto 0) := val32(8*(i+1)-1 downto 8*i);
--end loop;
--
--p_SendCfgPkt(C_WRITE,
--             C_FIFO_OFF,
--             C_CFGDEV_TESTING,
--             C_DSN_TSTING_REG_CTRL_L,
--             datasize,
--             data,
--             bus_in,
--             bus_out);
--val32:=CONV_STD_LOGIC_VECTOR(0, 16)&CONV_STD_LOGIC_VECTOR(16#22#, 16);
--for i in 0 to 4 - 1 loop
--  data(i)(7 downto 0) := val32(8*(i+1)-1 downto 8*i);
--end loop;
--
--p_SendCfgPkt(C_WRITE,
--             C_FIFO_OFF,
--             C_CFGDEV_TESTING,
--             C_DSN_TSTING_REG_CTRL_L,
--             datasize,
--             data,
--             bus_in,
--             bus_out);
--
----//Read FIFO_ETHG
--tag := 0;
--val32 := X"00000001";
--remaining:=1*10#32#;--+32;--//Кол-во в байтах
--offset:=0;
--while remaining /= 0 loop
--    chunk := 10#32#;
--    if chunk > remaining then
--      chunk := remaining;
--    end if;
--
--    plxsim_read_const(C_LBUS_DATA_BITS, C_MULTBURST_OFF, (C_VM_USR_REG_BAR+CONV_STD_LOGIC_VECTOR(C_HOST_REG_ETHG_DFIFO*C_VM_USR_REG_BCOUNT, 32)), be(0 to chunk - 1), data(0 to chunk - 1), n, bus_in, bus_out);
--    remaining := remaining - n;
--    tag := tag + (n / 4);
--end loop;


  wait_cycles(8, lclk);

--//Write RAM
  tag := 0;
  val32 := X"00000001";
  remaining:=4*64;--//Сколько данных передовать.( Кол-во в байтах)
  offset:=0;
  while remaining /= 0 loop
      chunk := 10#48#;--//Размер пакета данных
      if chunk > remaining then
        chunk := remaining;
      end if;

      for i in 0 to chunk / 4 - 1 loop
        data(4 * i to 4 * (i + 1) - 1) := conv_byte_vector(val32 + tag + i);
      end loop;

      --//Ждем запроса от модуля vereskm_main.vhd на работу в demand-mode DMA
      plxsim_write(C_LBUS_DATA_BITS, C_MULTBURST_ON, X"00200000", be(0 to chunk - 1), data(0 to chunk - 1), n, bus_in, bus_out);
      remaining := remaining - n;
      tag := tag + (n / 4);
  end loop;
  wait_cycles(4, lclk);


--  -- Write a pattern to the registers
--  data(0 to 7) := conv_byte_vector(X"0000040100000181");--00000300");
--  plxsim_write_const(C_LBUS_32b, C_MULTBURST_OFF, X"00000200"+f_ConvertAdr(C_HOST_REG_DEVCFG_DFIFO), be(0 to 7), data(0 to 7), n, bus_in, bus_out);
--  data(0 to 7) := conv_byte_vector(X"00000001");
--  plxsim_write_const(C_LBUS_32b, C_MULTBURST_OFF, X"00000200"+f_ConvertAdr(C_HOST_REG_DEVCFG_DFIFO), be(0 to 7), data(0 to 7), n, bus_in, bus_out);
--  data(0 to 7) := conv_byte_vector(X"00000003");
--  plxsim_write_const(C_LBUS_32b, C_MULTBURST_OFF, X"00000200"+f_ConvertAdr(C_HOST_REG_DEVCFG_DFIFO), be(0 to 7), data(0 to 7), n, bus_in, bus_out);
--
----  data(0 to 7) := conv_byte_vector(X"0000000000000001");
----  plxsim_write_const(C_LBUS_32b, C_MULTBURST_OFF, C_BAR_VERESKM, be(0 to 7), data(0 to 7), n, bus_in, bus_out);
----
----  plxsim_read_const(C_LBUS_32b, C_MULTBURST_OFF, X"0000030C", be(0 to 7), data(0 to 7), n, bus_in, bus_out);
----  plxsim_read_const(C_LBUS_32b, C_MULTBURST_OFF, X"00000310", be(0 to 7), data(0 to 7), n, bus_in, bus_out);
--
--  -- Read back the registers
--  -- Write a pattern to the registers
--  data(0 to 7) := conv_byte_vector(X"0000040100000181");
--  plxsim_write_const(C_LBUS_32b, C_MULTBURST_OFF, X"00000300", be(0 to 7), data(0 to 7), n, bus_in, bus_out);
----  data(0 to 7) := conv_byte_vector(X"0000000200000001");
----  plxsim_write_const(2, true, X"00000200", be(0 to 7), data(0 to 7), n, bus_in, bus_out);
----  data(0 to 7) := conv_byte_vector(X"0000000400000003");
----  plxsim_write_const(2, true, X"00000200", be(0 to 7), data(0 to 7), n, bus_in, bus_out);
--
--  data(0 to 7) := conv_byte_vector(X"0000000000000001");
--  plxsim_write_const(2, C_MULTBURST_OFF, X"00000204", be(0 to 7), data(0 to 7), n, bus_in, bus_out);
--
--  plxsim_wait_cycles(4, bus_in);
--
--  plxsim_read_const(2, C_MULTBURST_OFF, X"00000300", be(0 to 7), data(0 to 7), n, bus_in, bus_out);
--  plxsim_read_const(2, C_MULTBURST_OFF, X"00000300", be(0 to 7), data(0 to 7), n, bus_in, bus_out);
--  plxsim_read_const(2, C_MULTBURST_OFF, X"00000300", be(0 to 7), data(0 to 7), n, bus_in, bus_out);
--
--  plxsim_read_const(2, C_MULTBURST_OFF, X"0000030C", be(0 to 7), data(0 to 7), n, bus_in, bus_out);
--  plxsim_read_const(2, true, X"00000310", be(0 to 7), data(0 to 7), n, bus_in, bus_out);
--
--  plxsim_request_bus(false, bus_in, bus_out);







  i_dev_ctrl(C_HREG_DEV_CTRL_DEV_ADDR_MSB_BIT downto C_HREG_DEV_CTRL_DEV_ADDR_LSB_BIT):=CONV_STD_LOGIC_VECTOR(C_HDEV_MEM_DBUF, C_HREG_DEV_CTRL_DEV_ADDR_SIZE);
  data(0 to 3) :=conv_byte_vector(i_dev_ctrl);
  plxsim_write_const(C_LBUS_DATA_BITS, C_MULTBURST_OFF, (C_VM_USR_REG_BAR+CONV_STD_LOGIC_VECTOR(C_HOST_REG_DEV_CTRL*C_VM_USR_REG_BCOUNT, 32)), be(0 to 3), data(0 to 3), n, bus_in, bus_out);

--//Write RAM
  tag := 0;
  val32 := X"00000001";
  remaining:=4*32;--//Сколько данных передовать.( Кол-во в байтах)
  offset:=0;
  while remaining /= 0 loop
      chunk := 10#32#;--//Размер пакета данных
      if chunk > remaining then
        chunk := remaining;
      end if;

      for i in 0 to chunk / 4 - 1 loop
        data(4 * i to 4 * (i + 1) - 1) := conv_byte_vector(val32 + tag + i);
      end loop;

      --//Ждем запроса от модуля vereskm_main.vhd на работу в demand-mode DMA
      plxsim_write(C_LBUS_DATA_BITS, C_MULTBURST_ON, X"00200000", be(0 to chunk - 1), data(0 to chunk - 1), n, bus_in, bus_out);
      remaining := remaining - n;
      tag := tag + (n / 4);
  end loop;
  wait_cycles(64, lclk);

  report_message("Simulation of SIMPLE complete");

  wait;
end process;

--    UUT : simple
--        port map(
--            lclk           => lclk,
--            lreset_l       => lreset_l,
--            lwrite         => lwrite,
--            lads_l         => lads_l,
--            lblast_l       => lblast_l,
--            lbterm_l       => lbterm_l,
--            lad            => lad,
--            lready_l       => lready_l,
--            lbe_l          => lbe_l,
--            fholda         => fholda);


-- Drive GTX_CLK at 125 MHz
p_mgtclk : process
begin
  mgtclk_p <= '0';
  wait for 10 ns;
  loop
      wait for 4 ns;
      mgtclk_p <= '1';
      wait for 4 ns;
      mgtclk_p <= '0';
  end loop;
end process p_mgtclk;

-- Drive Gigabit Transceiver differential clock with 125MHz
mgtclk_n <= not mgtclk_p;


i_eth_rxp<=i_eth_txp;
i_eth_rxn<=i_eth_txn;

i_pciexp_txp <=CONV_STD_LOGIC_VECTOR(0, C_PCIEXPRESS_LINK_WIDTH);
i_pciexp_txn <=CONV_STD_LOGIC_VECTOR(0, C_PCIEXPRESS_LINK_WIDTH);



--DSPORT_INST : xilinx_pci_exp_1_lane_downstream_port port map (
--
--  sys_clk_p => dsport_sys_clk_p,
--  sys_clk_n => dsport_sys_clk_n,
--  sys_reset_n => cor_sys_reset_n,
--
--  pci_exp_rxn => cor_pci_exp_txn,
--  pci_exp_rxp => cor_pci_exp_txp,
--  pci_exp_txn => cor_pci_exp_rxn,
--  pci_exp_txp => cor_pci_exp_rxp
--
--);
--
--sys_clk_gen_ds_inst : sys_clk_gen_ds
--generic map (CLK_FREQ => 250)
--port map (
--
--  sys_clk_p => dsport_sys_clk_p,
--  sys_clk_n => dsport_sys_clk_n
--
--);
--
--
--sys_clk_gen_cor_inst : sys_clk_gen_ds
--generic map (CLK_FREQ => 100)
--port map (
--
--  sys_clk_p => cor_sys_clk_p,
--  sys_clk_n => cor_sys_clk_n
--
--);



fpga : vereskm_main
generic map
(
G_SIM_HOST        => "ON",
G_SIM_PCIEXP      => '1',
G_DBG_PCIEXP      => "OFF",
G_SIM             => "ON"
)
port map
(
--------------------------------------------------
--Светодиоды (Для платы ML505)
--------------------------------------------------
pin_out_led           => open,
pin_out_led_C         => open,
pin_out_led_E         => open,
pin_out_led_N         => open,
pin_out_led_S         => open,
pin_out_led_W         => open,

pin_out_TP            => open,

pin_in_btn_C          => '0',
pin_in_btn_E          => '0',
pin_in_btn_N          => '0',
pin_in_btn_S          => '0',
pin_in_btn_W          => '0',

pin_out_ddr2_cke1     => open,
pin_out_ddr2_cs1      => open,
pin_out_ddr2_odt1     => open,

--------------------------------------------------
--Ethernet
--------------------------------------------------
pin_out_sfp_tx_dis    => open,
pin_in_sfp_sd         => '0',

pin_out_eth_txp       => i_eth_txp,
pin_out_eth_txn       => i_eth_txn,
pin_in_eth_rxp        => i_eth_rxp,
pin_in_eth_rxn        => i_eth_rxn,
pin_in_eth_clk_p      => mgtclk_p,
pin_in_eth_clk_n      => mgtclk_n,

pin_out_gt_X0Y6_txp   => open,
pin_out_gt_X0Y6_txn   => open,
pin_in_gt_X0Y6_rxp    => "11",
pin_in_gt_X0Y6_rxn    => "00",
pin_in_gt_X0Y6_clk_p  => mgtclk_p,
pin_in_gt_X0Y6_clk_n  => mgtclk_n,

--------------------------------------------------
--PCI-EXPRESS
--------------------------------------------------
pin_out_pciexp_txp    => i_pciexp_txp,--cor_pci_exp_txp,--
pin_out_pciexp_txn    => i_pciexp_txn,--cor_pci_exp_txn,--
pin_in_pciexp_rxp     => i_pciexp_rxp,--cor_pci_exp_rxp,--
pin_in_pciexp_rxn     => i_pciexp_rxn,--cor_pci_exp_rxn,--
pin_in_pciexp_clk_p   => mgtclk_p,--cor_sys_clk_p,--mclka_n,--
pin_in_pciexp_clk_n   => mgtclk_n,--cor_sys_clk_n,--mclka_p,--

--------------------------------------------------
--Driver
--------------------------------------------------
pin_out_sata_txn      => open,
pin_out_sata_txp      => open,
pin_in_sata_rxn       =>"11",
pin_in_sata_rxp       =>"11",

pin_in_sata_clk_n     => mclka_n,
pin_in_sata_clk_p     => mclka_p,


lclk       => lclk,
lreset_l   => lreset_l,--cor_sys_reset_n,--
lads_l     => lads_l,
lblast_l   => lblast_l,
lbe_l      => lbe_l,
lwrite     => lwrite,
lad        => lad,
lbterm_l   => lbterm_l,
lready_l   => lready_l,
fholda     => fholda,
finto_l    => finto_l,

--mclka_p    => mclka_p,
--mclka_n    => mclka_n,

refclk_p   => refclk_p,
refclk_n   => refclk_n,

ra0        => ra0,
rc0        => rc0,
rd0        => rd0,
ra1        => ra1,
rc1        => rc1,
rd1        => rd1,
ra2        => ra2,
rc2        => rc2,
rd2        => rd2,
ra3        => ra3,
rc3        => rc3,
rd3        => rd3,
ra4        => ra4,
rc4        => rc4,
rd4        => rd4,
ra5        => ra5,
rc5        => rc5,
rd5        => rd5,
ra6        => ra6,
rc6        => rc6,
rd6        => rd6,
ra7        => ra7,
rc7        => rc7,
rd7        => rd7,
ra8        => ra8,
rc8        => rc8,
rd8        => rd8,
ra9        => ra9,
rc9        => rc9,
rd9        => rd9,
ra10       => ra10,
rc10       => rc10,
rd10       => rd10,
ra11       => ra11,
rc11       => rc11,
rd11       => rd11,
ra12       => ra12,
rc12       => rc12,
rd12       => rd12,
ra13       => ra13,
rc13       => rc13,
rd13       => rd13,
ra14       => ra14,
rc14       => rc14,
rd14       => rd14,
ra15       => ra15,
rc15       => rc15,
rd15       => rd15,
ramclko    => ramclk);


    trace_model_0 : ddr2sdram_trace_model
        generic map(
            max_bank_width => 3,
            max_addr_width => 16,
            num_phys_bank => 1,
            dq_width => bank0.rd_width,
            k_width => 2,
            cke_width => 1,
            odt_width => 1,
            registered => false,
            t_trace_k => 0.5 ns,
            t_trace_ctl => 0.5 ns,
            t_trace_dm => 0.5 ns,
            t_trace_dq => 0.5 ns,
            t_trace_dqs => 0.5 ns)
        port map(
            mk => rc0(13 downto 12),
            mk_l => rc0(15 downto 14),
            mcke => rc0(16 downto 16),
            modt => rc0(17 downto 17),
            mwe_l => rc0(18),
            mcas_l => rc0(19),
            mras_l => rc0(20),
            mcs_l => rc0(21 downto 21),
            mba => ra0(18 downto 16),
            ma => ra0(15 downto 0),
            mdq => rd0,
            mdm => rc0(3 downto 0),
            mdqs => rc0(7 downto 4),
            mdqs_l => rc0(11 downto 8),
            dk => rc0_ram(13 downto 12),
            dk_l => rc0_ram(15 downto 14),
            dcke => rc0_ram(16 downto 16),
            dodt => rc0_ram(17 downto 17),
            dwe_l => rc0_ram(18),
            dcas_l => rc0_ram(19),
            dras_l => rc0_ram(20),
            dcs_l => rc0_ram(21 downto 21),
            dba => ra0_ram(18 downto 16),
            da => ra0_ram(15 downto 0),
            ddq => rd0_ram,
            ddm => rc0_ram(3 downto 0),
            ddqs => rc0_ram(7 downto 4),
            ddqs_l => rc0_ram(11 downto 8));

--    mem_model_0 : for i in 0 to 1 generate
--        chip0 : HY5PS121621F
----            generic map(
----                Part_Number => B533)
--            port map(
--                DQ => rd0_ram(16 * (i + 1) - 1 downto 16 * i),
--                LDM => rc0_ram(2 * i + 0),
--                LDQS => rc0_ram(2 * i + 4),
--                LDQSB => rc0_ram(2 * i + 8),
--                UDM => rc0_ram(2 * i + 1),
--                UDQS => rc0_ram(2 * i + 5),
--                UDQSB => rc0_ram(2 * i + 9),
--                WEB => rc0_ram(18),
--                CASB => rc0_ram(19),
--                RASB => rc0_ram(20),
--                CSB => rc0_ram(21),
--                BA => ra0_ram(17 downto 16),
--                ADDR => ra0_ram(12 downto 0),
--                CKE => rc0_ram(16),
--                CLK => rc0_ram(i + 12),
--                CLKB => rc0_ram(i + 14));
--    end generate;

    trace_model_1 : ddr2sdram_trace_model
        generic map(
            max_bank_width => 3,
            max_addr_width => 16,
            num_phys_bank => 1,
            dq_width => bank1.rd_width,
            k_width => 2,
            cke_width => 1,
            odt_width => 1,
            registered => false,
            t_trace_k => 0.5 ns,
            t_trace_ctl => 0.5 ns,
            t_trace_dm => 0.5 ns,
            t_trace_dq => 0.5 ns,
            t_trace_dqs => 0.5 ns)
        port map(
            mk => rc1(13 downto 12),
            mk_l => rc1(15 downto 14),
            mcke => rc1(16 downto 16),
            modt => rc1(17 downto 17),
            mwe_l => rc1(18),
            mcas_l => rc1(19),
            mras_l => rc1(20),
            mcs_l => rc1(21 downto 21),
            mba => ra1(18 downto 16),
            ma => ra1(15 downto 0),
            mdq => rd1,
            mdm => rc1(3 downto 0),
            mdqs => rc1(7 downto 4),
            mdqs_l => rc1(11 downto 8),
            dk => rc1_ram(13 downto 12),
            dk_l => rc1_ram(15 downto 14),
            dcke => rc1_ram(16 downto 16),
            dodt => rc1_ram(17 downto 17),
            dwe_l => rc1_ram(18),
            dcas_l => rc1_ram(19),
            dras_l => rc1_ram(20),
            dcs_l => rc1_ram(21 downto 21),
            dba => ra1_ram(18 downto 16),
            da => ra1_ram(15 downto 0),
            ddq => rd1_ram,
            ddm => rc1_ram(3 downto 0),
            ddqs => rc1_ram(7 downto 4),
            ddqs_l => rc1_ram(11 downto 8));
--
--    mem_model_1 : for i in 0 to 1 generate
--        chip0 : HY5PS121621F
----            generic map(
----                Part_Number => B533)
--            port map(
--                DQ => rd1_ram(16 * (i + 1) - 1 downto 16 * i),
--                LDM => rc1_ram(2 * i + 0),
--                LDQS => rc1_ram(2 * i + 4),
--                LDQSB => rc1_ram(2 * i + 8),
--                UDM => rc1_ram(2 * i + 1),
--                UDQS => rc1_ram(2 * i + 5),
--                UDQSB => rc1_ram(2 * i + 9),
--                WEB => rc1_ram(18),
--                CASB => rc1_ram(19),
--                RASB => rc1_ram(20),
--                CSB => rc1_ram(21),
--                BA => ra1_ram(17 downto 16),
--                ADDR => ra1_ram(12 downto 0),
--                CKE => rc1_ram(16),
--                CLK => rc1_ram(i + 12),
--                CLKB => rc1_ram(i + 14));
--    end generate;

    trace_model_2 : ddr2sram_trace_model
        generic map(
            a_width => bank2.ra_width,
            dq_width => bank2.rd_width,
            t_trace_k => 1.0 ns,
            t_trace_c => 1.0 ns,
            t_trace_cq => 1.0 ns,
            t_trace_a => 1.0 ns,
            t_trace_ctl => 1.0 ns,
            t_trace_dq => 1.0 ns)
        port map(
            mk => rc2(4),
            mk_l => rc2(5),
            mc => rc2(4),
            mc_l => rc2(5),
            mld_l => rc2(2),
            mw_l => rc2(3),
            mbwe_l => rc2(1 downto 0),
            mdq => rd2,
            mcq => rc2(6),
            mcq_l => rc2(7),
            ma => ra2,
            dk => rc2_ram(4),
            dk_l => rc2_ram(5),
            dc => open,
            dc_l => open,
            dld_l => rc2_ram(2),
            dw_l => rc2_ram(3),
            dbwe_l => rc2_ram(1 downto 0),
            ddq => rd2_ram,
            dcq => rc2_ram(6),
            dcq_l => rc2_ram(7),
            da => ra2_ram);

    mem_model_2 : ddr2sram_model
        generic map(
            burst_order => 1,
            a_width => 24,
            dq_width => 16)
        port map(
            k => rc2_ram(4),
            k_l => rc2_ram(5),
            c => rc2_ram(4),
            c_l => rc2_ram(5),
            ld_l => rc2_ram(2),
            w_l => rc2_ram(3),
            bwe_l => rc2_ram(1 downto 0),
            dq => rd2_ram,
            cq => rc2_ram(6),
            cq_l => rc2_ram(7),
            a => ra2_ram);




--//32BIT
  gen_lbus_32bit : if C_FHOST_DBUS=32 generate

  arb_0 : locbus_arb
      generic map(
          n_arb       => num_agent,
          priority    => priorities)
      port map(
          lclk        => lclk,
          lreset_l    => lreset_l,
          lhold       => lhold,
          lholda      => lholda);

  agent_0 : locbus_agent_mux32
      port map(
          lclk        => lclk,
          lreset_l    => lreset_l,
          lads_l      => lads_l,
          lad         => lad,
          lbe_l       => lbe_l,
          lblast_l    => lblast_l,
          lbterm_l    => lbterm_l,
          lready_l    => lready_l,
          lwrite      => lwrite,
          lhold       => lhold(0),
          lholda      => lholda(0),
          bus_in      => bus_in,
          bus_out     => bus_out);

  lbpcheck_0 : lbpcheck
      generic map(
          multiplexed => true,
          wide        => false)
      port map(
          lclk        => lclk,
          lreset_l    => lreset_l,
          lads_l      => lads_l,
          l64_l       => lads_l,
          la          => lad(31 downto 2),
          lad_lo      => lad,
          lad_hi      => lad,
          lbe_lo_l    => lbe_l,
          lbe_hi_l    => lbe_l,
          lwrite      => lwrite,
          lblast_l    => lblast_l,
          lready_l    => lready_l,
          lbterm_l    => lbterm_l);

  --//Конец блока "gen_lbus_32bit"
  end generate gen_lbus_32bit;

--//64BIT
  gen_lbus_64bit : if C_FHOST_DBUS=64 generate
    agent_ds : locbus_agent_mux64
        port map(
            lclk        => lclk,
            lreset_l    => lreset_l,
            lads_l      => lads_l,
            lad         => lad,
            lbe_l       => lbe_l,
            lblast_l    => lblast_l,
            lbterm_l    => lbterm_l,
            lready_l    => lready_l,
            lwrite      => lwrite,
            lhold       => lhold(0),
            lholda      => lholda(0),
            bus_in      => bus_in,
            bus_out     => bus_out);

    arb_0 : locbus_arb
        generic map(
            n_arb       => num_agent,
            priority    => priorities)
        port map(
            lclk        => lclk,
            lreset_l    => lreset_l,
            lhold       => lhold,
            lholda      => lholda);

    lbpcheck_0 : lbpcheck
        generic map(
            multiplexed => true,
            wide        => true)
        port map(
            lclk        => lclk,
            lreset_l    => lreset_l,
            lads_l      => lads_l,
            l64_l       => l64_l,
            la          => lad(31 downto 2),
            lad_lo      => lad(31 downto 0),
            lad_hi      => lad(63 downto 32),
            lbe_lo_l    => lbe_l(3 downto 0),
            lbe_hi_l    => lbe_l(7 downto 4),
            lwrite      => lwrite,
            lblast_l    => lblast_l,
            lready_l    => lready_l,
            lbterm_l    => lbterm_l);

  --//Конец блока "gen_lbus_64bit"
  end generate gen_lbus_64bit;

end behav;


--  val32:=CONV_STD_LOGIC_VECTOR(0, 16)&CONV_STD_LOGIC_VECTOR(C_CFGDEV_SWT, 8)&'0'&'0'&"000000";
--  PktDataIdx:=0;
----  for i in PktDataIdx*8 to (4*(PktDataIdx+1)) / 4 - 1 loop
----  for i in 0 to 4-1 loop
----    data(4 * i to 4 * (i + 1) - 1) := conv_byte_vector(val32 + tag + i);
--    data(0 to 31) := conv_byte_vector(val32);
----  end loop;
--
--  datasize:=1;
--  val32:=CONV_STD_LOGIC_VECTOR(0, 16)&CONV_STD_LOGIC_VECTOR(datasize, 8)&CONV_STD_LOGIC_VECTOR(C_DSN_SWT_REG_CTRL_L, 8);
--  PktDataIdx:=1;
--  data(32 to 63) := conv_byte_vector(val32);
----  for i in 4 to 8 - 1 loop
----    data(4 * i to 4 * (i + 1) - 1) := val32(4 * i downto 4 * (i + 1) - 1);--conv_byte_vector(val32);--conv_byte_vector(val32+ i);
----  end loop;
--
--  datasize:=1;
--  val32:=CONV_STD_LOGIC_VECTOR(0, 16)&CONV_STD_LOGIC_VECTOR(C_DSN_SWT_REG_CTRL_ETHTXD_LOOPBACK_BIT, 16);
--  PktDataIdx:=2;
----  for i in 8 to 12 - 1 loop
----    data(4 * i to 4 * (i + 1) - 1) := val32(4 * i downto 4 * (i + 1) - 1);--conv_byte_vector(val32(4 * i downto 4 * (i + 1) - 1));--conv_byte_vector(val32+ i);
--  data(64 to 95) := conv_byte_vector(val32);
----  end loop;
--
--  chunk:=12;
--  plxsim_write_const(C_LBUS_DATA_BITS, C_MULTBURST_ON, (C_VM_USR_REG_BAR+CONV_STD_LOGIC_VECTOR(C_HOST_REG_DEVCFG_DFIFO*8, 32)), be(0 to chunk - 1), data(0 to chunk - 1), n, bus_in, bus_out);