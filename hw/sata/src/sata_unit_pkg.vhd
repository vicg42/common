------------------------------------------------------------------------
-- Company     : Linkos
-- Engineer    : Golovachenko Victor
--
-- Create Date : 18.03.2011 19:08:01
-- Module Name : sata_unit_pkg
--
-- Description : Объеяление прототипо модулей используемых в прокете SATA
--
-- Revision:
-- Revision 0.01 - File Created
--
-------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_arith.all;

library work;
use work.vicg_common_pkg.all;
use work.sata_glob_pkg.all;
use work.sata_pkg.all;
use work.sata_sim_lite_pkg.all;
use work.sata_raid_pkg.all;

package sata_unit_pkg is

component sata_dbgcs
generic(
G_DBG : string:="OFF";
G_SIM : string:="OFF"
);
port(
--------------------------------------------------
--Связь с СhipScope ICON
--------------------------------------------------
p_out_dbgcs_ila   : out  TSH_ila;

--------------------------------------------------
--USR
--------------------------------------------------
p_in_ctrl         : in   std_logic_vector(C_USR_GCTRL_LAST_BIT downto 0);

p_in_dbg          : in   TSH_dbgport;
p_in_alstatus     : in   TALStatus;
p_in_phy_txreq    : in   std_logic_vector(7 downto 0);
p_in_phy_rxtype   : in   std_logic_vector(C_TDATA_EN downto C_TALIGN);
p_in_phy_rxdata   : in   std_logic_vector(31 downto 0);
p_in_phy_sync     : in   std_logic;

p_in_reg_hold     : in    TRegHold;
p_in_reg_update   : in    TRegShadowUpdate;

p_in_ll_rxd       : in   std_logic_vector(31 downto 0);
p_in_ll_rxd_wr    : in   std_logic;
p_in_ll_txd       : in   std_logic_vector(31 downto 0);
p_in_ll_txd_rd    : in   std_logic;

--Tranceiver
p_in_txelecidle     : in    std_logic;
p_in_txcomstart     : in    std_logic;
p_in_txcomtype      : in    std_logic;
p_in_txdata         : in    std_logic_vector(31 downto 0);
p_in_txcharisk      : in    std_logic_vector(3 downto 0);

p_in_txreset        : in    std_logic;
p_in_txbufstatus    : in    std_logic_vector(1 downto 0);

--Receiver
p_in_rxcdrreset     : in    std_logic;
p_in_rxreset        : in    std_logic;
p_in_rxelecidle     : in    std_logic;
p_in_rxstatus       : in    std_logic_vector(2 downto 0);
p_in_rxdata         : in    std_logic_vector(31 downto 0);
p_in_rxcharisk      : in    std_logic_vector(3 downto 0);
p_in_rxdisperr      : in    std_logic_vector(3 downto 0);
p_in_rxnotintable   : in    std_logic_vector(3 downto 0);
p_in_rxbyteisaligned: in    std_logic;

p_in_rxbufreset     : in    std_logic;
p_in_rxbufstatus    : in    std_logic_vector(2 downto 0);

--------------------------------------------------
--Технологические сигналы
--------------------------------------------------
p_out_tst         : out   std_logic_vector(31 downto 0);

--------------------------------------------------
--System
--------------------------------------------------
p_in_clk          : in    std_logic;
p_in_rst          : in    std_logic
);
end component;

component sata_dcm
generic (
G_GT_DBUS : integer:=16
);
port(
p_out_dcm_gclk0  : out   std_logic;
p_out_dcm_gclk2x : out   std_logic;
p_out_dcm_gclkdv : out   std_logic;
p_out_dcm_clk2x  : out   std_logic;
p_out_dcmlock    : out   std_logic;

p_out_refclkout  : out   std_logic;
p_in_clk         : in    std_logic;
p_in_rst         : in    std_logic
);
end component;

component sata_player_gt_clkmux
generic(
G_HDD_COUNT : integer:=0;
G_SIM       : string :="OFF"
);
port(
p_out_optrefclksel : out   T04_SHCountMax;
p_out_optrefclk    : out   T04_SHCountMax;
p_in_optrefclk     : in    T04_SHCountMax
);
end component;

component sata_cmdfifo
port(
din    : in  std_logic_vector(15 downto 0);
wr_en  : in  std_logic;
wr_clk : in  std_logic;

dout   : out std_logic_vector(15 downto 0);
rd_en  : in  std_logic;
rd_clk : in  std_logic;

full   : out std_logic;
empty  : out std_logic;

rst    : in  std_logic
);
end component;

component sata_txfifo
port(
din         : in std_logic_vector(31 downto 0);
wr_en       : in std_logic;
wr_clk      : in std_logic;

dout        : out std_logic_vector(31 downto 0);
rd_en       : in std_logic;
rd_clk      : in std_logic;

full        : out std_logic;
prog_full   : out std_logic;
almost_full : out std_logic;
empty       : out std_logic;
almost_empty: out std_logic;
rd_data_count : out std_logic_vector(3 downto 0);
wr_data_count : out std_logic_vector(3 downto 0);

rst         : in std_logic
);
end component;

component sata_rxfifo
port(
din        : in std_logic_vector(31 downto 0);
wr_en      : in std_logic;
wr_clk     : in std_logic;

dout       : out std_logic_vector(31 downto 0);
rd_en      : in std_logic;
rd_clk     : in std_logic;

full        : out std_logic;
prog_full   : out std_logic;
--almost_full : out std_logic;
empty       : out std_logic;
--almost_empty: out std_logic;
wr_data_count : out std_logic_vector(3 downto 0);

rst        : in std_logic
);
end component;

component sata_scrambler
generic(
G_INIT_VAL : integer:=16#FFFF#
);
port(
p_in_SOF      : in    std_logic;
p_in_en       : in    std_logic;
p_out_result  : out   std_logic_vector(31 downto 0);

--------------------------------------------------
--System
--------------------------------------------------
--p_in_clk_en   : in    std_logic;
p_in_clk      : in    std_logic;
p_in_rst      : in    std_logic
);
end component;

component sata_crc
generic(
G_INIT_VAL : integer:=16#52325032#
);
port(
p_in_SOF      : in    std_logic;
--p_in_EOF      : in    std_logic;
p_in_en       : in    std_logic;
p_in_data     : in    std_logic_vector(31 downto 0);
p_out_crc     : out   std_logic_vector(31 downto 0);

--------------------------------------------------
--System
--------------------------------------------------
--p_in_clk_en   : in    std_logic;
p_in_clk      : in    std_logic;
p_in_rst      : in    std_logic
);
end component;

component sata_player_tx
generic(
G_SATAH_NUM : integer:=0;
G_GT_CH_NUM : integer:=0;
G_GT_DBUS : integer:=16;
G_DBG     : string :="OFF";
G_SIM     : string :="OFF"
);
port(
--------------------------------------------------
--
--------------------------------------------------
--p_in_rxalign        : in    std_logic;
p_in_linkup         : in    std_logic;
p_in_dev_detect     : in    std_logic;
p_in_d10_2_send_dis : in    std_logic;
p_in_sync           : in    std_logic;
p_in_txreq          : in    std_logic_vector(7 downto 0);
p_in_txd            : in    std_logic_vector(31 downto 0);
p_out_rdy_n         : out   std_logic;

--------------------------------------------------
--RocketIO Transmiter (Назначение портов см. sata_player_gt.vhd)
--------------------------------------------------
p_out_gt_txdata     : out   std_logic_vector(31 downto 0);
p_out_gt_txcharisk  : out   std_logic_vector(3 downto 0);

p_out_gt_txreset    : out   std_logic;
p_in_gt_txbufstatus : in    std_logic_vector(1 downto 0);

--------------------------------------------------
--Технологические сигналы
--------------------------------------------------
p_in_tst            : in    std_logic_vector(31 downto 0);
p_out_tst           : out   std_logic_vector(31 downto 0);
p_out_dbg           : out   TPLtx_dbgport;

--------------------------------------------------
--System
--------------------------------------------------
p_in_clk            : in    std_logic;
p_in_rst            : in    std_logic
);
end component;

component sata_player_rx
generic(
G_GT_DBUS : integer:=16;
G_DBG     : string :="OFF";
G_SIM     : string :="OFF"
);
port(
--------------------------------------------------
--
--------------------------------------------------
p_in_dev_detect         : in    std_logic;
p_out_rxd               : out   std_logic_vector(31 downto 0);
p_out_rxtype            : out   std_logic_vector(C_TDATA_EN downto C_TALIGN);
p_out_rxerr             : out   std_logic_vector(C_PRxSTAT_LAST_BIT downto 0);

--------------------------------------------------
--RocketIO Receiver (Описание портов см. sata_player_gt.vhd)
--------------------------------------------------
p_in_gt_rxdata          : in    std_logic_vector(31 downto 0);
p_in_gt_rxcharisk       : in    std_logic_vector(3 downto 0);
p_in_gt_rxdisperr       : in    std_logic_vector(3 downto 0);
p_in_gt_rxnotintable    : in    std_logic_vector(3 downto 0);
p_in_gt_rxbyteisaligned : in    std_logic;

p_in_gt_rxbufstatus     : in    std_logic_vector(2 downto 0);
p_out_gt_rxbufreset     : out   std_logic;

--------------------------------------------------
--Технологические сигналы
--------------------------------------------------
p_in_tst                : in    std_logic_vector(31 downto 0);
p_out_tst               : out   std_logic_vector(31 downto 0);
p_out_dbg               : out   TPLrx_dbgport;

--------------------------------------------------
--System
--------------------------------------------------
p_in_clk                : in    std_logic;
p_in_rst                : in    std_logic
);
end component;

component sata_player_oob
generic(
G_GT_DBUS : integer:=16;
G_DBG     : string :="OFF";
G_SIM     : string :="OFF"
);
port(
--------------------------------------------------
--
--------------------------------------------------
p_in_ctrl           : in    std_logic_vector(C_PLCTRL_LAST_BIT downto 0);
p_out_status        : out   std_logic_vector(C_PLSTAT_LAST_BIT downto 0);

p_in_primitive_det  : in    std_logic_vector(C_TPMNAK downto C_TALIGN);
p_out_d10_2_senddis : out   std_logic;

--------------------------------------------------
--RocketIO Receiver
--------------------------------------------------
p_out_gt_rst        : out   std_logic;

p_out_gt_txelecidle : out   std_logic;
p_out_gt_txcomstart : out   std_logic;
p_out_gt_txcomtype  : out   std_logic;

p_in_gt_rxelecidle  : in    std_logic;
p_in_gt_rxstatus    : in    std_logic_vector(2 downto 0);

--------------------------------------------------
--Технологические сигналы
--------------------------------------------------
p_in_tst            : in    std_logic_vector(31 downto 0);
p_out_tst           : out   std_logic_vector(31 downto 0);
p_out_dbg           : out   TPLoob_dbgport;

--------------------------------------------------
--System
--------------------------------------------------
p_in_tmrclk         : in    std_logic;
p_in_clk            : in    std_logic;
p_in_rst            : in    std_logic
);
end component;

component sata_alayer
generic(
G_DBG : string:="OFF";
G_SIM : string:="OFF"
);
port(
--------------------------------------------------
--Связь с USR APP Layer
--------------------------------------------------
p_in_ctrl               : in    std_logic_vector(C_USR_GCTRL_LAST_BIT downto 0);
p_out_status            : out   TALStatus;

--//Связь с CMDFIFO
p_in_cmdfifo_dout       : in    std_logic_vector(15 downto 0);
p_in_cmdfifo_eof_n      : in    std_logic;
p_in_cmdfifo_src_rdy_n  : in    std_logic;
--p_out_cmdfifo_dst_rdy_n : out   std_logic;

--------------------------------------------------
--Связь с Transport/Link/PHY Layer
--------------------------------------------------
p_out_spd_ctrl          : out   TSpdCtrl;
p_out_tl_ctrl           : out   std_logic_vector(C_TLCTRL_LAST_BIT downto 0);
p_in_tl_status          : in    std_logic_vector(C_TLSTAT_LAST_BIT downto 0);
p_in_ll_status          : in    std_logic_vector(C_LLSTAT_LAST_BIT downto 0);
p_in_pl_status          : in    std_logic_vector(C_PLSTAT_LAST_BIT downto 0);

p_in_reg_fpdma          : in    TRegFPDMASetup;
p_out_reg_shadow        : out   TRegShadow;
p_in_reg_hold           : in    TRegHold;
p_in_reg_update         : in    TRegShadowUpdate;

--------------------------------------------------
--Технологические сигналы
--------------------------------------------------
p_in_tst                : in    std_logic_vector(31 downto 0);
p_out_tst               : out   std_logic_vector(31 downto 0);
p_out_dbg               : out   TAL_dbgport;

--------------------------------------------------
--System
--------------------------------------------------
p_in_clk                : in    std_logic;
p_in_rst                : in    std_logic
);
end component;

component sata_tlayer
generic(
G_DBG : string:="OFF";
G_SIM : string:="OFF"
);
port(
--------------------------------------------------
--Связь с USRAPP Layer
--------------------------------------------------
--//Связь с TXFIFO
p_in_txfifo_dout     : in    std_logic_vector(31 downto 0);
p_out_txfifo_rd      : out   std_logic;
p_in_txfifo_status   : in    TTxBufStatus;

--//Связь с RXFIFO
p_out_rxfifo_din     : out   std_logic_vector(31 downto 0);
p_out_rxfifo_wd      : out   std_logic;
p_in_rxfifo_status   : in    TRxBufStatus;

--------------------------------------------------
--Связь с APP Layer
--------------------------------------------------
p_in_tl_ctrl         : in    std_logic_vector(C_TLCTRL_LAST_BIT downto 0);
p_out_tl_status      : out   std_logic_vector(C_TLSTAT_LAST_BIT downto 0);

p_out_reg_fpdma      : out   TRegFPDMASetup;
p_in_reg_shadow      : in    TRegShadow;
p_out_reg_hold       : out   TRegHold;
p_out_reg_update     : out   TRegShadowUpdate;

--------------------------------------------------
--Связь с Link Layer
--------------------------------------------------
p_out_ll_ctrl        : out   std_logic_vector(C_LLCTRL_LAST_BIT downto 0);
p_in_ll_status       : in    std_logic_vector(C_LLSTAT_LAST_BIT downto 0);

p_out_ll_txd_close   : out   std_logic;
p_out_ll_txd         : out   std_logic_vector(31 downto 0);
p_in_ll_txd_rd       : in    std_logic;
p_out_ll_txd_status  : out   TTxBufStatus;

p_in_ll_rxd          : in    std_logic_vector(31 downto 0);
p_in_ll_rxd_wr       : in    std_logic;
p_out_ll_rxd_status  : out   TRxBufStatus;

--------------------------------------------------
--Связь с PHY Layer
--------------------------------------------------
--p_in_pl_ctrl         : in    std_logic_vector(C_PLCTRL_LAST_BIT downto 0);
p_in_pl_status       : in    std_logic_vector(C_PLSTAT_LAST_BIT downto 0);

--------------------------------------------------
--Технологические сигналы
--------------------------------------------------
p_in_tst             : in    std_logic_vector(31 downto 0);
p_out_tst            : out   std_logic_vector(31 downto 0);
p_out_dbg            : out   TTL_dbgport;

--------------------------------------------------
--System
--------------------------------------------------
p_in_clk             : in    std_logic;
p_in_rst             : in    std_logic
);
end component;

component sata_llayer
generic(
G_DBG : string:="OFF";
G_SIM : string:="OFF"
);
port(
--------------------------------------------------
--Связь с Transport Layer
--------------------------------------------------
p_in_ctrl        : in    std_logic_vector(C_LLCTRL_LAST_BIT downto 0);
p_out_status     : out   std_logic_vector(C_LLSTAT_LAST_BIT downto 0);

p_in_txd_close   : in    std_logic;
p_in_txd         : in    std_logic_vector(31 downto 0);
p_out_txd_rd     : out   std_logic;
p_in_txd_status  : in    TTxBufStatus;

p_out_rxd        : out   std_logic_vector(31 downto 0);
p_out_rxd_wr     : out   std_logic;
p_in_rxd_status  : in    TRxBufStatus;

--------------------------------------------------
--Связь с Phy Layer
--------------------------------------------------
p_in_phy_status  : in    std_logic_vector(C_PLSTAT_LAST_BIT downto 0);
p_in_phy_sync    : in    std_logic;

p_in_phy_rxtype  : in    std_logic_vector(C_TDATA_EN downto C_TSYNC);
p_in_phy_rxd     : in    std_logic_vector(31 downto 0);

p_out_phy_txd    : out   std_logic_vector(31 downto 0);
p_out_phy_txreq  : out   std_logic_vector(7 downto 0);
p_in_phy_txrdy_n : in    std_logic;

--------------------------------------------------
--Технологические сигналы
--------------------------------------------------
p_in_tst         : in    std_logic_vector(31 downto 0);
p_out_tst        : out   std_logic_vector(31 downto 0);
p_out_dbg        : out   TLL_dbgport;

--------------------------------------------------
--System
--------------------------------------------------
p_in_clk         : in    std_logic;--
p_in_rst         : in    std_logic
);
end component;

component sata_player
generic(
G_SATAH_NUM : integer:=0;
G_GT_CH_NUM : integer:=0;
G_GT_DBUS : integer:=16;
G_DBG     : string :="OFF";
G_SIM     : string :="OFF"
);
port(
--------------------------------------------------
--Связь с Link Layer
--------------------------------------------------
p_in_ctrl               : in    std_logic_vector(C_PLCTRL_LAST_BIT downto 0);
p_out_status            : out   std_logic_vector(C_PLSTAT_LAST_BIT downto 0);

p_in_phy_txd            : in    std_logic_vector(31 downto 0);
p_in_phy_txreq          : in    std_logic_vector(7 downto 0);
p_out_phy_txrdy_n       : out   std_logic;

p_out_phy_rxtype        : out   std_logic_vector(C_TDATA_EN downto C_TALIGN);
p_out_phy_rxdata        : out   std_logic_vector(31 downto 0);

p_out_phy_sync          : out   std_logic;

--------------------------------------------------
--Связь с RocketIO (Описание портов см. sata_player_gt.vhd)
--------------------------------------------------
p_out_gt_rst            : out   std_logic;

--RocketIO Tranceiver
p_out_gt_txelecidle     : out   std_logic;
p_out_gt_txcomstart     : out   std_logic;
p_out_gt_txcomtype      : out   std_logic;
p_out_gt_txdata         : out   std_logic_vector(31 downto 0);
p_out_gt_txcharisk      : out   std_logic_vector(3 downto 0);

p_out_gt_txreset        : out   std_logic;
p_in_gt_txbufstatus     : in    std_logic_vector(1 downto 0);

--RocketIO Receiver
p_in_gt_rxelecidle      : in    std_logic;
p_in_gt_rxstatus        : in    std_logic_vector(2 downto 0);
p_in_gt_rxdata          : in    std_logic_vector(31 downto 0);
p_in_gt_rxcharisk       : in    std_logic_vector(3 downto 0);
p_in_gt_rxdisperr       : in    std_logic_vector(3 downto 0);
p_in_gt_rxnotintable    : in    std_logic_vector(3 downto 0);
p_in_gt_rxbyteisaligned : in    std_logic;

p_in_gt_rxbufstatus     : in    std_logic_vector(2 downto 0);
p_out_gt_rxbufreset     : out   std_logic;

--------------------------------------------------
--Технологические сигналы
--------------------------------------------------
p_in_tst                : in    std_logic_vector(31 downto 0);
p_out_tst               : out   std_logic_vector(31 downto 0);
p_out_dbg               : out   TPL_dbgport;

--------------------------------------------------
--System
--------------------------------------------------
p_in_tmrclk             : in    std_logic;
p_in_clk                : in    std_logic;
p_in_rst                : in    std_logic
);
end component;

component sata_player_gtsim
generic(
G_SATAH_NUM   : integer:=0;
G_GT_CH_COUNT : integer:=2;
G_GT_DBUS     : integer:=16;
G_SIM         : string :="OFF"
);
port(
---------------------------------------------------------------------------
--Usr Cfg
---------------------------------------------------------------------------
p_in_spd              : in    TSpdCtrl_GTCH;
p_in_sys_dcm_gclk2div : in    std_logic;
p_in_sys_dcm_gclk     : in    std_logic;
p_in_sys_dcm_gclk2x   : in    std_logic;

p_out_usrclk2         : out   std_logic_vector(C_GTCH_COUNT_MAX-1 downto 0);

----------------------------------------------------------------------------
--System
----------------------------------------------------------------------------
--Порт динамическаго конфигурирования DUAL_GTP
p_out_drpdo           : out   std_logic_vector(15 downto 0);
p_out_drprdy          : out   std_logic;

p_out_plllock         : out   std_logic;
p_out_refclkout       : out   std_logic;

p_in_refclkin         : in    std_logic;

p_in_optrefclksel     : in    std_logic_vector(3 downto 0);
p_in_optrefclk        : in    std_logic_vector(3 downto 0);
p_out_optrefclk       : out   std_logic_vector(3 downto 0);

p_in_rst              : in    std_logic
);
end component;

component sata_player_gt
generic(
G_SATAH_NUM   : integer:=0;
G_GT_CH_COUNT : integer:=2;
G_GT_DBUS     : integer:=16;
G_SIM         : string :="OFF"
);
port(
---------------------------------------------------------------------------
--Usr Cfg
---------------------------------------------------------------------------
p_in_spd               : in    TSpdCtrl_GTCH;
p_in_sys_dcm_gclk2div  : in    std_logic;
p_in_sys_dcm_gclk      : in    std_logic;
p_in_sys_dcm_gclk2x    : in    std_logic;

p_out_usrclk2          : out   std_logic_vector(C_GTCH_COUNT_MAX-1 downto 0);
p_out_resetdone        : out   std_logic_vector(C_GTCH_COUNT_MAX-1 downto 0);

--------------------------------------------------
--Driver
--------------------------------------------------
p_out_txn              : out   std_logic_vector(C_GTCH_COUNT_MAX-1 downto 0);
p_out_txp              : out   std_logic_vector(C_GTCH_COUNT_MAX-1 downto 0);
p_in_rxn               : in    std_logic_vector(C_GTCH_COUNT_MAX-1 downto 0);
p_in_rxp               : in    std_logic_vector(C_GTCH_COUNT_MAX-1 downto 0);

--------------------------------------------------
--Tranceiver
--------------------------------------------------
p_in_txelecidle        : in    std_logic_vector(C_GTCH_COUNT_MAX-1 downto 0);
p_in_txcomstart        : in    std_logic_vector(C_GTCH_COUNT_MAX-1 downto 0);
p_in_txcomtype         : in    std_logic_vector(C_GTCH_COUNT_MAX-1 downto 0);
p_in_txdata            : in    TBus32_GTCH;
p_in_txcharisk         : in    TBus04_GTCH;

p_in_txreset           : in    std_logic_vector(C_GTCH_COUNT_MAX-1 downto 0);
p_out_txbufstatus      : out   TBus02_GTCH;

--------------------------------------------------
--Receiver
--------------------------------------------------
p_in_rxcdrreset        : in    std_logic_vector(C_GTCH_COUNT_MAX-1 downto 0);
p_in_rxreset           : in    std_logic_vector(C_GTCH_COUNT_MAX-1 downto 0);
p_out_rxelecidle       : out   std_logic_vector(C_GTCH_COUNT_MAX-1 downto 0);
p_out_rxstatus         : out   TBus03_GTCH;
p_out_rxdata           : out   TBus32_GTCH;
p_out_rxcharisk        : out   TBus04_GTCH;
p_out_rxdisperr        : out   TBus04_GTCH;
p_out_rxnotintable     : out   TBus04_GTCH;
p_out_rxbyteisaligned  : out   std_logic_vector(C_GTCH_COUNT_MAX-1 downto 0);

p_in_rxbufreset        : in    std_logic_vector(C_GTCH_COUNT_MAX-1 downto 0);
p_out_rxbufstatus      : out   TBus03_GTCH;

--------------------------------------------------
--System
--------------------------------------------------
p_in_drpclk            : in    std_logic;
p_in_drpaddr           : in    std_logic_vector(7 downto 0);
p_in_drpen             : in    std_logic;
p_in_drpwe             : in    std_logic;
p_in_drpdi             : in    std_logic_vector(15 downto 0);
p_out_drpdo            : out   std_logic_vector(15 downto 0);
p_out_drprdy           : out   std_logic;

p_out_plllock          : out   std_logic;
p_out_refclkout        : out   std_logic;

p_in_refclkin          : in    std_logic;

p_in_optrefclksel      : in    std_logic_vector(3 downto 0);
p_in_optrefclk         : in    std_logic_vector(3 downto 0);
p_out_optrefclk        : out   std_logic_vector(3 downto 0);

p_in_rst               : in    std_logic
);
end component;

component sata_speed_ctrl
generic(
G_SATAH_COUNT_MAX : integer:=1;
G_SATAH_NUM       : integer:=0;
G_SATAH_CH_COUNT  : integer:=1;
G_DBG             : string :="OFF";
G_DBGCS           : string :="OFF";
G_SIM             : string :="OFF"
);
port(
--------------------------------------------------
--
--------------------------------------------------
p_in_ctrl           : in    TSpdCtrl_GTCH;
p_out_phy_spd       : out   TSpdCtrl_GTCH;
p_out_phy_layer_rst : out   std_logic_vector(C_GTCH_COUNT_MAX-1 downto 0);

p_in_phy_linkup     : in    std_logic_vector(C_GTCH_COUNT_MAX-1 downto 0);
p_in_gt_pll_lock    : in    std_logic;
p_in_usr_dcm_lock   : in    std_logic;

--------------------------------------------------
--Связь с GTP
--------------------------------------------------
p_out_gt_drpaddr    : out   std_logic_vector(7 downto 0);
p_out_gt_drpen      : out   std_logic;
p_out_gt_drpwe      : out   std_logic;
p_out_gt_drpdi      : out   std_logic_vector(15 downto 0);
p_in_gt_drpdo       : in    std_logic_vector(15 downto 0);
p_in_gt_drprdy      : in    std_logic;

p_out_gt_ch_rst     : out   std_logic_vector(C_GTCH_COUNT_MAX-1 downto 0);
p_in_gt_resetdone   : in    std_logic_vector(C_GTCH_COUNT_MAX-1 downto 0);

--------------------------------------------------
--Технологические сигналы
--------------------------------------------------
p_in_tst            : in    std_logic_vector(31 downto 0);
p_out_tst           : out   std_logic_vector(31 downto 0);
p_out_dbgcs_ila     : out   TSH_ila;

--------------------------------------------------
--System
--------------------------------------------------
p_in_clk            : in    std_logic;
p_in_rst            : in    std_logic
);
end component;


component sata_host
generic(
G_SATAH_COUNT_MAX : integer:=1;
G_SATAH_NUM       : integer:=0;
G_SATAH_CH_COUNT  : integer:=1;
G_GT_DBUS         : integer:=16;
G_DBG             : string :="OFF";
G_DBGCS           : string :="OFF";
G_SIM             : string :="OFF"
);
port(
--------------------------------------------------
--Sata Driver
--------------------------------------------------
p_out_sata_txn              : out   std_logic_vector(C_GTCH_COUNT_MAX-1 downto 0);
p_out_sata_txp              : out   std_logic_vector(C_GTCH_COUNT_MAX-1 downto 0);
p_in_sata_rxn               : in    std_logic_vector(C_GTCH_COUNT_MAX-1 downto 0);
p_in_sata_rxp               : in    std_logic_vector(C_GTCH_COUNT_MAX-1 downto 0);

--------------------------------------------------
--Связь с USERAPP Layer
--------------------------------------------------
p_out_usrfifo_clkout        : out   std_logic_vector(C_GTCH_COUNT_MAX-1 downto 0);
p_out_status                : out   TALStatus_GTCH;
p_in_ctrl                   : in    TALCtrl_GTCH;

--//Связь с CMDFIFO
p_in_cmdfifo_dout           : in    TBus16_GTCH;
p_in_cmdfifo_eof_n          : in    std_logic_vector(C_GTCH_COUNT_MAX-1 downto 0);
p_in_cmdfifo_src_rdy_n      : in    std_logic_vector(C_GTCH_COUNT_MAX-1 downto 0);
--p_out_cmdfifo_dst_rdy_n     : out   std_logic_vector(C_GTCH_COUNT_MAX-1 downto 0);

--//Связь с TXFIFO
p_in_txbuf_dout             : in    TBus32_GTCH;
p_out_txbuf_rd              : out   std_logic_vector(C_GTCH_COUNT_MAX-1 downto 0);
p_in_txbuf_status           : in    TTxBufStatus_GTCH;

--//Связь с RXFIFO
p_out_rxbuf_din             : out   TBus32_GTCH;
p_out_rxbuf_wd              : out   std_logic_vector(C_GTCH_COUNT_MAX-1 downto 0);
p_in_rxbuf_status           : in    TRxBufStatus_GTCH;

--------------------------------------------------
--Технологические сигналы
--------------------------------------------------
p_in_tst                    : in    TBus32_GTCH;
p_out_tst                   : out   TBus32_GTCH;

--------------------------------------------------
--//Debug/Sim
--------------------------------------------------
p_out_dbg                   : out   TSH_dbgport_GTCH;
p_out_dbgcs                 : out   TSH_dbgcs_GTCH;

p_out_sim_gt_txdata         : out   TBus32_GTCH;
p_out_sim_gt_txcharisk      : out   TBus04_GTCH;
p_out_sim_gt_txcomstart     : out   std_logic_vector(C_GTCH_COUNT_MAX-1 downto 0);
p_in_sim_gt_rxdata          : in    TBus32_GTCH;
p_in_sim_gt_rxcharisk       : in    TBus04_GTCH;
p_in_sim_gt_rxstatus        : in    TBus03_GTCH;
p_in_sim_gt_rxelecidle      : in    std_logic_vector(C_GTCH_COUNT_MAX-1 downto 0);
p_in_sim_gt_rxdisperr       : in    TBus04_GTCH;
p_in_sim_gt_rxnotintable    : in    TBus04_GTCH;
p_in_sim_gt_rxbyteisaligned : in    std_logic_vector(C_GTCH_COUNT_MAX-1 downto 0);
p_out_sim_rst               : out   std_logic_vector(C_GTCH_COUNT_MAX-1 downto 0);
p_out_sim_clk               : out   std_logic_vector(C_GTCH_COUNT_MAX-1 downto 0);

--------------------------------------------------
--System
--------------------------------------------------
p_in_sys_dcm_gclk2div       : in    std_logic;
p_in_sys_dcm_gclk           : in    std_logic;
p_in_sys_dcm_gclk2x         : in    std_logic;
p_in_sys_dcm_lock           : in    std_logic;

p_out_gt_pllkdet            : out   std_logic;
p_out_gt_refclk             : out   std_logic;
p_in_gt_drpclk              : in    std_logic;
p_in_gt_refclk              : in    std_logic;

p_in_optrefclksel           : in    std_logic_vector(3 downto 0);
p_in_optrefclk              : in    std_logic_vector(3 downto 0);
p_out_optrefclk             : out   std_logic_vector(3 downto 0);

p_in_rst                    : in    std_logic
);
end component;


component sata_connector
generic(
G_SATAH_CH_COUNT : integer:=1;
G_DBG            : string :="OFF";
G_SIM            : string :="OFF"
);
port(
--------------------------------------------------
--Связь с модулем sata_raid.vhd
--------------------------------------------------
p_in_uap_clk            : in    std_logic;

--//CMDFIFO
p_in_uap_cxd            : in    TBus16_GTCH;
p_in_uap_cxd_sof_n      : in    std_logic_vector(C_GTCH_COUNT_MAX-1 downto 0);
p_in_uap_cxd_eof_n      : in    std_logic_vector(C_GTCH_COUNT_MAX-1 downto 0);
p_in_uap_cxd_src_rdy_n  : in    std_logic_vector(C_GTCH_COUNT_MAX-1 downto 0);

--//TXFIFO
p_in_uap_txd            : in    TBus32_GTCH;
p_in_uap_txd_wr         : in    std_logic_vector(C_GTCH_COUNT_MAX-1 downto 0);

--//RXFIFO
p_out_uap_rxd           : out   TBus32_GTCH;
p_in_uap_rxd_rd         : in    std_logic_vector(C_GTCH_COUNT_MAX-1 downto 0);

--------------------------------------------------
--Связь с модулем sata_host.vhd
--------------------------------------------------
p_in_sh_clk             : in    std_logic_vector(C_GTCH_COUNT_MAX-1 downto 0);
--p_in_sh_status          : in    TALStatus_GTCH;

--//CMDFIFO
p_out_sh_cxd            : out   TBus16_GTCH;
p_out_sh_cxd_eof_n      : out   std_logic_vector(C_GTCH_COUNT_MAX-1 downto 0);
p_out_sh_cxd_src_rdy_n  : out   std_logic_vector(C_GTCH_COUNT_MAX-1 downto 0);

--//TXFIFO
p_out_sh_txd            : out   TBus32_GTCH;
p_in_sh_txd_rd          : in    std_logic_vector(C_GTCH_COUNT_MAX-1 downto 0);

--//RXFIFO
p_in_sh_rxd             : in    TBus32_GTCH;
p_in_sh_rxd_wr          : in    std_logic_vector(C_GTCH_COUNT_MAX-1 downto 0);

--------------------------------------------------
--//Статусы
--------------------------------------------------
p_out_txbuf_status      : out   TTxBufStatus_GTCH;
p_out_rxbuf_status      : out   TRxBufStatus_GTCH;

--------------------------------------------------
--Технологические сигналы
--------------------------------------------------
p_in_tst                : in    std_logic_vector(31 downto 0);
p_out_tst               : out   std_logic_vector(31 downto 0);

--------------------------------------------------
--System
--------------------------------------------------
p_in_rst                : in    std_logic_vector(C_GTCH_COUNT_MAX-1 downto 0)
);
end component;

component sata_raid_ctrl
generic(
G_RAID_DWIDTH : integer:=32;
G_HDD_COUNT : integer:=1;
G_DBGCS     : string :="OFF";
G_DBG       : string :="OFF";
G_SIM       : string :="OFF"
);
port(
--------------------------------------------------
--Связь с модулем dsn_hdd.vhd
--------------------------------------------------
p_in_usr_ctrl           : in    std_logic_vector(C_USR_GCTRL_LAST_BIT downto 0);
p_out_usr_status        : out   TUsrStatus;

--//cmdpkt
p_in_usr_cxd            : in    std_logic_vector(15 downto 0);
p_in_usr_cxd_wr         : in    std_logic;

--//txfifo
p_in_usr_txd            : in    std_logic_vector(G_RAID_DWIDTH-1 downto 0);
p_out_usr_txd_rd        : out   std_logic;
p_in_usr_txbuf_empty    : in    std_logic;

--//rxfifo
p_out_usr_rxd           : out   std_logic_vector(G_RAID_DWIDTH-1 downto 0);
p_out_usr_rxd_wr        : out   std_logic;
p_in_usr_rxbuf_full     : in    std_logic;

--------------------------------------------------
--Связь с модулями sata_host.vhd
--------------------------------------------------
p_in_sh_status          : in    TALStatus_SHCountMax;
p_out_sh_ctrl           : out   TALCtrl_SHCountMax;

p_in_raid               : in    TRaid;
p_in_sh_num             : in    std_logic_vector(2 downto 0);
p_out_sh_hdd            : out   std_logic_vector(2 downto 0);
p_out_sh_mask           : out   std_logic_vector(G_HDD_COUNT-1 downto 0);
p_out_sh_padding        : out   std_logic;

p_out_sh_cxd            : out   std_logic_vector(15 downto 0);
p_out_sh_cxd_sof_n      : out   std_logic;
p_out_sh_cxd_eof_n      : out   std_logic;
p_out_sh_cxd_src_rdy_n  : out   std_logic;

p_out_sh_txd            : out   std_logic_vector(G_RAID_DWIDTH-1 downto 0);
p_out_sh_txd_wr         : out   std_logic;
p_in_sh_txbuf_full      : in    std_logic;

p_in_sh_rxd             : in    std_logic_vector(G_RAID_DWIDTH-1 downto 0);
p_out_sh_rxd_rd         : out   std_logic;
p_in_sh_rxbuf_empty     : in    std_logic;

--------------------------------------------------
--Технологические сигналы
--------------------------------------------------
p_in_tst                : in    std_logic_vector(31 downto 0);
p_out_tst               : out   std_logic_vector(31 downto 0);
p_out_dbgcs             : out   TSH_ila;

p_in_sh_tst             : in    TBus32_SHCountMax;
p_out_sh_tst            : out   TBus32_SHCountMax;

--------------------------------------------------
--System
--------------------------------------------------
p_in_clk                : in    std_logic;
p_in_rst                : in    std_logic
);
end component;


component sata_raid_decoder
generic(
G_RAID_DWIDTH : integer:=32;
G_HDD_COUNT : integer:=1;
G_DBG       : string :="OFF";
G_SIM       : string :="OFF"
);
port(
--------------------------------------------------
--Связь с модулем dsn_hdd.vhd
--------------------------------------------------
p_out_raid              : out   TRaid;
p_out_sh_num            : out   std_logic_vector(2 downto 0);
p_in_sh_hdd             : in    std_logic_vector(2 downto 0);
p_in_sh_mask            : in    std_logic_vector(G_HDD_COUNT-1 downto 0);
p_in_sh_padding         : in    std_logic;

p_in_usr_cxd            : in    std_logic_vector(15 downto 0);
p_in_usr_cxd_sof_n      : in    std_logic;
p_in_usr_cxd_eof_n      : in    std_logic;
p_in_usr_cxd_src_rdy_n  : in    std_logic;

p_in_usr_txd            : in    std_logic_vector(G_RAID_DWIDTH-1 downto 0);
p_in_usr_txd_wr         : in    std_logic;
p_out_usr_txbuf_full    : out   std_logic;

p_out_usr_rxd           : out   std_logic_vector(G_RAID_DWIDTH-1 downto 0);
p_in_usr_rxd_rd         : in    std_logic;
p_out_usr_rxbuf_empty   : out   std_logic;

--------------------------------------------------
--Связь с модулями sata_host.vhd
--------------------------------------------------
p_out_sh_cxd            : out   TBus16_SHCountMax;
p_out_sh_cxd_sof_n      : out   std_logic_vector(C_HDD_COUNT_MAX-1 downto 0);
p_out_sh_cxd_eof_n      : out   std_logic_vector(C_HDD_COUNT_MAX-1 downto 0);
p_out_sh_cxd_src_rdy_n  : out   std_logic_vector(C_HDD_COUNT_MAX-1 downto 0);

p_out_sh_txd            : out   TBus32_SHCountMax;
p_out_sh_txd_wr         : out   std_logic_vector(C_HDD_COUNT_MAX-1 downto 0);

p_in_sh_rxd             : in    TBus32_SHCountMax;
p_out_sh_rxd_rd         : out   std_logic_vector(C_HDD_COUNT_MAX-1 downto 0);

p_in_sh_txbuf_status    : in    TTxBufStatus_SHCountMax;
p_in_sh_rxbuf_status    : in    TRxBufStatus_SHCountMax;

--------------------------------------------------
--Технологические сигналы
--------------------------------------------------
p_in_tst                : in    std_logic_vector(31 downto 0);
p_out_tst               : out   std_logic_vector(31 downto 0);

--------------------------------------------------
--System
--------------------------------------------------
p_in_clk                : in    std_logic;
p_in_rst                : in    std_logic
);
end component;


component sata_raid
generic(
G_RAID_DWIDTH : integer:=32;
G_HDD_COUNT : integer:=1;    --//Кол-во sata устр-в (min/max - 1/8)
G_DBGCS     : string :="OFF";
G_DBG       : string :="OFF";
G_SIM       : string :="OFF"
);
port(
--------------------------------------------------
--Связь с модулем dsn_hdd.vhd
--------------------------------------------------
p_in_usr_ctrl           : in    std_logic_vector(C_USR_GCTRL_LAST_BIT downto 0);
p_out_usr_status        : out   TUsrStatus;

--//cmdpkt
p_in_usr_cxd            : in    std_logic_vector(15 downto 0);
p_in_usr_cxd_wr         : in    std_logic;

--//txfifo
p_in_usr_txd            : in    std_logic_vector(G_RAID_DWIDTH-1 downto 0);
p_out_usr_txd_rd        : out   std_logic;
p_in_usr_txbuf_empty    : in    std_logic;

--//rxfifo
p_out_usr_rxd           : out   std_logic_vector(G_RAID_DWIDTH-1 downto 0);
p_out_usr_rxd_wr        : out   std_logic;
p_in_usr_rxbuf_full     : in    std_logic;

--------------------------------------------------
--Связь с модулями sata_host.vhd
--------------------------------------------------
p_in_sh_status          : in    TALStatus_SHCountMax;
p_out_sh_ctrl           : out   TALCtrl_SHCountMax;

p_out_sh_cxd            : out   TBus16_SHCountMax;
p_out_sh_cxd_sof_n      : out   std_logic_vector(C_HDD_COUNT_MAX-1 downto 0);
p_out_sh_cxd_eof_n      : out   std_logic_vector(C_HDD_COUNT_MAX-1 downto 0);
p_out_sh_cxd_src_rdy_n  : out   std_logic_vector(C_HDD_COUNT_MAX-1 downto 0);

p_out_sh_txd            : out   TBus32_SHCountMax;
p_out_sh_txd_wr         : out   std_logic_vector(C_HDD_COUNT_MAX-1 downto 0);

p_in_sh_rxd             : in    TBus32_SHCountMax;
p_out_sh_rxd_rd         : out   std_logic_vector(C_HDD_COUNT_MAX-1 downto 0);

p_in_sh_txbuf_status    : in    TTxBufStatus_SHCountMax;
p_in_sh_rxbuf_status    : in    TRxBufStatus_SHCountMax;

--------------------------------------------------
--Технологические сигналы
--------------------------------------------------
p_in_tst                : in    std_logic_vector(31 downto 0);
p_out_tst               : out   std_logic_vector(31 downto 0);
p_out_dbgcs             : out   TSH_ila;

p_in_sh_tst             : in    TBus32_SHCountMax;
p_out_sh_tst            : out   TBus32_SHCountMax;

--------------------------------------------------
--System
--------------------------------------------------
p_in_clk                : in    std_logic;
p_in_rst                : in    std_logic
);
end component;

component sata_hwstart_ctrl
generic(
G_T05us     : integer:=1;
G_DBGCS     : string :="OFF";
G_DBG       : string :="OFF";
G_SIM       : string :="OFF"
);
port(
--------------------------------------------------
--
--------------------------------------------------
p_in_ctrl      : in    std_logic_vector(C_USR_GCTRL_LAST_BIT downto 0);

--------------------------------------------------
--Связь с модулям sata_raid.vhd
--------------------------------------------------
p_in_hw_work   : in    std_logic;
p_in_hw_start  : in    std_logic;
p_out_hw_start : out   std_logic;

p_in_sh_cmddone: in    std_logic;
p_in_mstatus   : in    TMeasureStatus;

--------------------------------------------------
--Технологические сигналы
--------------------------------------------------
p_in_tst       : in    std_logic_vector(31 downto 0);
p_out_tst      : out   std_logic_vector(31 downto 0);
p_out_dbgcs    : out   TSH_ila;

--------------------------------------------------
--System
--------------------------------------------------
p_in_clk       : in    std_logic;
p_in_rst       : in    std_logic
);
end component;

component sata_measure
generic(
G_T05us     : integer:=1;
G_HDD_COUNT : integer:=1;
G_DBGCS     : string :="OFF";
G_DBG       : string :="OFF";
G_SIM       : string :="OFF"
);
port(
--------------------------------------------------
--Связь с модулем dsn_hdd.vhd
--------------------------------------------------
p_in_ctrl      : in    std_logic_vector(C_USR_GCTRL_LAST_BIT downto 0);
p_out_status   : out   TMeasureStatus;

--------------------------------------------------
--Связь с модулям sata_host.vhd
--------------------------------------------------
p_in_sh_busy   : in    std_logic_vector(C_HDD_COUNT_MAX-1 downto 0);
p_in_dev_busy  : in    std_logic;
p_in_sh_status : in    TMeasureALStatus_SHCountMax;

--------------------------------------------------
--Технологические сигналы
--------------------------------------------------
p_in_tst       : in    std_logic_vector(31 downto 0);
p_out_tst      : out   std_logic_vector(31 downto 0);
p_out_dbgcs    : out   TSH_ila;

--------------------------------------------------
--System
--------------------------------------------------
p_in_clk       : in    std_logic;
p_in_rst       : in    std_logic
);
end component;

component dsn_raid_main
generic(
G_RAID_DWIDTH : integer:=32;
G_HDD_COUNT : integer:=2;
G_GT_DBUS   : integer:=16;
G_DBG       : string :="OFF";
G_DBGCS     : string :="OFF";
G_SIM       : string :="OFF"
);
port(
--------------------------------------------------
--Sata Driver
--------------------------------------------------
p_out_sata_txn              : out   std_logic_vector((C_GTCH_COUNT_MAX*C_SH_COUNT_MAX(G_HDD_COUNT-1))-1 downto 0);
p_out_sata_txp              : out   std_logic_vector((C_GTCH_COUNT_MAX*C_SH_COUNT_MAX(G_HDD_COUNT-1))-1 downto 0);
p_in_sata_rxn               : in    std_logic_vector((C_GTCH_COUNT_MAX*C_SH_COUNT_MAX(G_HDD_COUNT-1))-1 downto 0);
p_in_sata_rxp               : in    std_logic_vector((C_GTCH_COUNT_MAX*C_SH_COUNT_MAX(G_HDD_COUNT-1))-1 downto 0);

p_in_sata_refclk            : in    std_logic_vector(C_SH_COUNT_MAX(G_HDD_COUNT-1)-1 downto 0);
p_out_sata_refclkout        : out   std_logic;
p_out_sata_gt_plldet        : out   std_logic;
p_out_sata_dcm_lock         : out   std_logic;
p_out_sata_dcm_gclk2div     : out   std_logic;
p_out_sata_dcm_gclk2x       : out   std_logic;
p_out_sata_dcm_gclk0        : out   std_logic;

--------------------------------------------------
--Связь с модулем dsn_hdd.vhd
--------------------------------------------------
p_in_usr_ctrl               : in    std_logic_vector(C_USR_GCTRL_LAST_BIT downto 0);
p_out_usr_status            : out   TUsrStatus;
p_out_measure               : out   TMeasureStatus;

--//cmdpkt
p_in_usr_cxd                : in    std_logic_vector(15 downto 0);
p_in_usr_cxd_wr             : in    std_logic;

--//txfifo
p_in_usr_txd                : in    std_logic_vector(G_RAID_DWIDTH-1 downto 0);
p_out_usr_txd_rd            : out   std_logic;
p_in_usr_txbuf_empty        : in    std_logic;

--//rxfifo
p_out_usr_rxd               : out   std_logic_vector(G_RAID_DWIDTH-1 downto 0);
p_out_usr_rxd_wr            : out   std_logic;
p_in_usr_rxbuf_full         : in    std_logic;

--------------------------------------------------
--//Debug/Sim
--------------------------------------------------
p_out_dbgcs                 : out   TSH_dbgcs_exp;

p_out_sim_gt_txdata         : out   TBus32_SHCountMax;
p_out_sim_gt_txcharisk      : out   TBus04_SHCountMax;
p_out_sim_gt_txcomstart     : out   std_logic_vector(C_HDD_COUNT_MAX-1 downto 0);
p_in_sim_gt_rxdata          : in    TBus32_SHCountMax;
p_in_sim_gt_rxcharisk       : in    TBus04_SHCountMax;
p_in_sim_gt_rxstatus        : in    TBus03_SHCountMax;
p_in_sim_gt_rxelecidle      : in    std_logic_vector(C_HDD_COUNT_MAX-1 downto 0);
p_in_sim_gt_rxdisperr       : in    TBus04_SHCountMax;
p_in_sim_gt_rxnotintable    : in    TBus04_SHCountMax;
p_in_sim_gt_rxbyteisaligned : in    std_logic_vector(C_HDD_COUNT_MAX-1 downto 0);
p_out_gt_sim_rst            : out   std_logic_vector(C_HDD_COUNT_MAX-1 downto 0);
p_out_gt_sim_clk            : out   std_logic_vector(C_HDD_COUNT_MAX-1 downto 0);

--------------------------------------------------
--Технологические сигналы
--------------------------------------------------
p_in_tst                : in    std_logic_vector(31 downto 0);
p_out_tst               : out   std_logic_vector(31 downto 0);

--------------------------------------------------
--System
--------------------------------------------------
p_in_clk                : in    std_logic;
p_in_rst                : in    std_logic
);
end component;

end sata_unit_pkg;


package body sata_unit_pkg is



end sata_unit_pkg;


