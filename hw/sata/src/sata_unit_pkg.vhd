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

use work.vicg_common_pkg.all;
use work.sata_pkg.all;

package sata_unit_pkg is

component sata_dcm
port
(
p_out_dcm_gclk0     : out   std_logic;
p_out_dcm_gclk2x    : out   std_logic;
p_out_dcm_gclkdv    : out   std_logic;

p_out_dcmlock       : out   std_logic;

p_in_clk            : in    std_logic;
p_in_rst            : in    std_logic
);
end component;

component ll_fifo
generic (
MEM_TYPE        :       integer := 0;
BRAM_MACRO_NUM  :       integer := 1;
DRAM_DEPTH      :       integer := 16;
WR_DWIDTH       :       integer := 32;
RD_DWIDTH       :       integer := 32;
RD_REM_WIDTH    :       integer := 2;
WR_REM_WIDTH    :       integer := 2;
USE_LENGTH      :       boolean := true;
glbtm           :       time    := 1 ns
);
port
(
-- Reset
areset_in:              in std_logic;

-- clocks
write_clock_in:         in std_logic;
read_clock_in:          in std_logic;

-- Interface to downstream user application
data_out:               out std_logic_vector(0 to RD_DWIDTH-1);
rem_out:                out std_logic_vector(0 to RD_REM_WIDTH-1);
sof_out_n:              out std_logic;
eof_out_n:              out std_logic;
src_rdy_out_n:          out std_logic;
dst_rdy_in_n:           in std_logic;

-- Interface to upstream user application
data_in:                in std_logic_vector(0 to WR_DWIDTH-1);
rem_in:                 in std_logic_vector(0 to WR_REM_WIDTH-1);
sof_in_n:               in std_logic;
eof_in_n:               in std_logic;
src_rdy_in_n:           in std_logic;
dst_rdy_out_n:          out std_logic;

-- FIFO status signals
fifostatus_out:         out std_logic_vector(0 to 3);

-- Length Status
len_rdy_out:            out std_logic;
len_out:                out std_logic_vector(0 to 15);
len_err_out:            out std_logic
);
end component;

component sata_cmdfifo
port
(
din        : IN std_logic_VECTOR(15 downto 0);
wr_en      : IN std_logic;
wr_clk     : IN std_logic;

dout       : OUT std_logic_VECTOR(15 downto 0);
rd_en      : IN std_logic;
rd_clk     : IN std_logic;

full       : OUT std_logic;
empty      : OUT std_logic;

rst        : IN std_logic
);
end component;

component sata_txfifo
port
(
din         : IN std_logic_VECTOR(31 downto 0);
wr_en       : IN std_logic;
wr_clk      : IN std_logic;

dout        : OUT std_logic_VECTOR(31 downto 0);
rd_en       : IN std_logic;
rd_clk      : IN std_logic;

full        : OUT std_logic;
prog_full   : OUT std_logic;
--almost_full : OUT std_logic;
empty       : OUT std_logic;
almost_empty: OUT std_logic;

rst         : IN std_logic
);
end component;

component sata_rxfifo
port
(
din        : IN std_logic_VECTOR(31 downto 0);
wr_en      : IN std_logic;
wr_clk     : IN std_logic;

dout       : OUT std_logic_VECTOR(31 downto 0);
rd_en      : IN std_logic;
rd_clk     : IN std_logic;

full        : OUT std_logic;
prog_full   : OUT std_logic;
--almost_full : OUT std_logic;
empty       : OUT std_logic;
--almost_empty: OUT std_logic;

rst        : IN std_logic
);
end component;

component sata_scrambler
generic
(
G_INIT_VAL : integer := 16#FFFF#
);
port
(
p_in_SOF               : in    std_logic;
p_in_en                : in    std_logic;
p_out_result           : out   std_logic_vector(31 downto 0);

--------------------------------------------------
--System
--------------------------------------------------
--p_in_clk_en            : in    std_logic;
p_in_clk               : in    std_logic;
p_in_rst               : in    std_logic
);
end component;

component sata_crc
generic
(
G_INIT_VAL : integer := 16#52325032#
);
port
(
p_in_SOF               : in    std_logic;
--p_in_EOF               : in    std_logic;
p_in_en                : in    std_logic;
p_in_data              : in    std_logic_vector(31 downto 0);
p_out_crc              : out   std_logic_vector(31 downto 0);

--------------------------------------------------
--System
--------------------------------------------------
--p_in_clk_en            : in    std_logic;
p_in_clk               : in    std_logic;
p_in_rst               : in    std_logic
);
end component;

component sata_player_tx
generic
(
G_GTP_DBUS : integer := 16;
G_DBG      : string  := "OFF";
G_SIM      : string  := "OFF"
);
port
(
--------------------------------------------------
--
--------------------------------------------------
p_in_d10_2_send_dis    : in    std_logic;
p_in_sync              : in    std_logic;
p_in_txreq             : in    std_logic_vector(7 downto 0);
p_in_txd               : in    std_logic_vector(31 downto 0);
p_out_rdy_n            : out   std_logic;

--------------------------------------------------
--RocketIO Transmiter (Назначение портов см. sata_rocketio.vhd)
--------------------------------------------------
--p_in_gtp_pll_lock          : in    std_logic;
p_out_gtp_txdata       : out   std_logic_vector(15 downto 0);
p_out_gtp_txcharisk    : out   std_logic_vector(1 downto 0);
p_out_gtp_txreset      : out   std_logic;
p_in_gtp_txbufstatus   : in    std_logic_vector(1 downto 0);

--------------------------------------------------
--Технологические сигналы
--------------------------------------------------
p_in_tst               : in    std_logic_vector(31 downto 0);
p_out_tst              : out   std_logic_vector(31 downto 0);

--------------------------------------------------
--System
--------------------------------------------------
p_in_clk               : in    std_logic;
p_in_rst               : in    std_logic
);
end component;

component sata_player_rx
generic
(
G_GTP_DBUS : integer := 16;
G_DBG      : string  := "OFF";
G_SIM      : string  := "OFF"
);
port
(
--------------------------------------------------
--
--------------------------------------------------
p_out_rxd                  : out   std_logic_vector(31 downto 0);
p_out_rxtype               : out   std_logic_vector(C_TDATA_EN downto C_TALIGN);

--------------------------------------------------
--RocketIO Receiver (Описание портов см. sata_rocketio.vhd)
--------------------------------------------------
--p_in_gtp_pll_lock          : in    std_logic;
p_out_gtp_rxbufreset       : out   std_logic;
p_in_gtp_rxdata            : in    std_logic_vector(15 downto 0);
p_in_gtp_rxcharisk         : in    std_logic_vector(1 downto 0);
p_in_gtp_rxbufstatus       : in    std_logic_vector(2 downto 0);
p_in_gtp_rxelecidle        : in    std_logic;
p_in_gtp_rxdisperr         : in    std_logic_vector(1 downto 0);
p_in_gtp_rxnotintable      : in    std_logic_vector(1 downto 0);
p_in_gtp_rxbyteisaligned   : in    std_logic;
p_in_gtp_rxbyterealigned   : in    std_logic;

--------------------------------------------------
--Технологические сигналы
--------------------------------------------------
p_in_tst                   : in    std_logic_vector(31 downto 0);
p_out_tst                  : out   std_logic_vector(31 downto 0);

--------------------------------------------------
--System
--------------------------------------------------
p_in_clk               : in    std_logic;
p_in_rst               : in    std_logic
);
end component;

component sata_player_oob
generic
(
G_DBG      : string  := "OFF";
G_SIM      : string  := "OFF"
);
port
(
--------------------------------------------------
--
--------------------------------------------------
p_in_ctrl              : in    std_logic_vector(C_PLCTRL_LAST_BIT downto 0);
p_out_status           : out   std_logic_vector(C_PLSTAT_LAST_BIT downto 0);

p_in_primitive_det     : in    std_logic_vector(C_TPMNAK downto C_TALIGN);
p_out_d10_2_senddis    : out   std_logic;

--p_out_gtp_rxbufreset   : out   std_logic;

--------------------------------------------------
--RocketIO Receiver
--------------------------------------------------
p_in_gtp_pll_lock      : in    std_logic;

p_out_gtp_txelecidle   : out   std_logic;
p_out_gtp_txcomstart   : out   std_logic;
p_out_gtp_txcomtype    : out   std_logic;

p_in_gtp_rxelecidle    : in    std_logic;
p_in_gtp_rxstatus      : in    std_logic_vector(2 downto 0);
p_out_rxreset          : out   std_logic;

--------------------------------------------------
--Технологические сигналы
--------------------------------------------------
p_in_tst               : in    std_logic_vector(31 downto 0);
p_out_tst              : out   std_logic_vector(31 downto 0);

--------------------------------------------------
--System
--------------------------------------------------
p_in_clk               : in    std_logic;
p_in_rst               : in    std_logic
);
end component;

component sata_alayer
generic
(
G_DBG      : string  := "OFF";
G_SIM      : string  := "OFF"
);
port
(
--------------------------------------------------
--Связь с USR APP Layer
--------------------------------------------------
p_in_ctrl                 : in    std_logic_vector(C_ALCTRL_LAST_BIT downto 0);
p_out_status              : out   TALStatus;

--//Связь с CMDFIFO
p_in_cmdfifo_dout         : in    std_logic_vector(15 downto 0);
p_in_cmdfifo_eof_n        : in    std_logic;
p_in_cmdfifo_src_rdy_n    : in    std_logic;
p_out_cmdfifo_dst_rdy_n   : out   std_logic;

--------------------------------------------------
--Связь с Transport/Link/PHY Layer
--------------------------------------------------
p_out_tl_ctrl             : out   std_logic_vector(C_TLCTRL_LAST_BIT downto 0);
p_in_tl_status            : in    std_logic_vector(C_TLSTAT_LAST_BIT downto 0);
p_in_ll_status            : in    std_logic_vector(C_LLSTAT_LAST_BIT downto 0);
p_in_pl_status            : in    std_logic_vector(C_PLSTAT_LAST_BIT downto 0);

p_out_reg_dma             : out   TRegDMA;
p_out_reg_shadow          : out   TRegShadow;
p_in_reg_hold             : in    TRegHold;
p_in_reg_update           : in    TRegShadowUpdate;

--------------------------------------------------
--Технологические сигналы
--------------------------------------------------
p_in_tst                  : in    std_logic_vector(31 downto 0);
p_out_tst                 : out   std_logic_vector(31 downto 0);

--------------------------------------------------
--System
--------------------------------------------------
p_in_clk               : in    std_logic;
p_in_rst               : in    std_logic
);
end component;

component sata_tlayer
generic
(
G_DBG      : string  := "OFF";
G_SIM      : string  := "OFF"
);
port
(
--------------------------------------------------
--Связь с USRAPP Layer
--------------------------------------------------
--//Связь с TXFIFO
p_in_txfifo_dout          : in    std_logic_vector(31 downto 0);
p_out_txfifo_rd           : out   std_logic;
p_in_txfifo_status        : in    TTxBufStatus;

--//Связь с RXFIFO
p_out_rxfifo_din          : out   std_logic_vector(31 downto 0);
p_out_rxfifo_wd           : out   std_logic;
p_in_rxfifo_status        : in    TRxBufStatus;

--------------------------------------------------
--Связь с APP Layer
--------------------------------------------------
p_in_tl_ctrl              : in    std_logic_vector(C_TLCTRL_LAST_BIT downto 0);
p_out_tl_status           : out   std_logic_vector(C_TLSTAT_LAST_BIT downto 0);

p_in_reg_dma              : in    TRegDMA;
p_in_reg_shadow           : in    TRegShadow;
p_out_reg_hold            : out   TRegHold;
p_out_reg_update          : out   TRegShadowUpdate;

--------------------------------------------------
--Связь с Link Layer
--------------------------------------------------
p_out_ll_ctrl             : out   std_logic_vector(C_LLCTRL_LAST_BIT downto 0);
p_in_ll_status            : in    std_logic_vector(C_LLSTAT_LAST_BIT downto 0);

p_out_ll_txd_close        : out   std_logic;
p_out_ll_txd              : out   std_logic_vector(31 downto 0);
p_in_ll_txd_rd            : in    std_logic;
p_out_ll_txd_status       : out   TTxBufStatus;

p_in_ll_rxd               : in    std_logic_vector(31 downto 0);
p_in_ll_rxd_wr            : in    std_logic;
p_out_ll_rxd_status       : out   TRxBufStatus;

--------------------------------------------------
--Связь с PHY Layer
--------------------------------------------------
--p_in_pl_ctrl              : in    std_logic_vector(C_PLCTRL_LAST_BIT downto 0);
p_in_pl_status            : in    std_logic_vector(C_PLSTAT_LAST_BIT downto 0);

--------------------------------------------------
--Технологические сигналы
--------------------------------------------------
p_in_tst                  : in    std_logic_vector(31 downto 0);
p_out_tst                 : out   std_logic_vector(31 downto 0);

--------------------------------------------------
--System
--------------------------------------------------
p_in_clk               : in    std_logic;
p_in_rst               : in    std_logic
);
end component;

component sata_llayer
generic
(
--G_GTP_DBUS : integer := 16;
G_DBG      : string  := "OFF";
G_SIM      : string  := "OFF"
);
port
(
--------------------------------------------------
--Связь с Transport Layer
--------------------------------------------------
p_in_ctrl               : in    std_logic_vector(C_LLCTRL_LAST_BIT downto 0);
p_out_status            : out   std_logic_vector(C_LLSTAT_LAST_BIT downto 0);

p_in_txd_close          : in    std_logic;
p_in_txd                : in    std_logic_vector(31 downto 0);
p_out_txd_rd            : out   std_logic;
p_in_txd_status         : in    TTxBufStatus;

p_out_rxd               : out   std_logic_vector(31 downto 0);
p_out_rxd_wr            : out   std_logic;
p_in_rxd_status         : in    TRxBufStatus;

--------------------------------------------------
--Связь с Phy Layer
--------------------------------------------------
p_in_phy_rdy            : in    std_logic;
p_in_phy_sync           : in    std_logic;

p_in_phy_rxtype         : in    std_logic_vector(C_TDATA_EN downto C_TSOF);
p_in_phy_rxd            : in    std_logic_vector(31 downto 0);

p_out_phy_txd           : out   std_logic_vector(31 downto 0);
p_out_phy_txreq         : out   std_logic_vector(7 downto 0);
p_in_phy_txrdy_n        : in    std_logic;

--------------------------------------------------
--Технологические сигналы
--------------------------------------------------
p_in_tst                : in    std_logic_vector(31 downto 0);
p_out_tst               : out   std_logic_vector(31 downto 0);

--------------------------------------------------
--System
--------------------------------------------------
p_in_clk               : in    std_logic;--
p_in_rst               : in    std_logic
);
end component;

component sata_player
generic
(
G_GTP_DBUS : integer := 16;
G_DBG      : string  := "OFF";
G_SIM      : string  := "OFF"
);
port
(
--------------------------------------------------
--Связь с Link Layer
--------------------------------------------------
p_in_ctrl                  : in    std_logic_vector(C_PLCTRL_LAST_BIT downto 0);
p_out_status               : out   std_logic_vector(C_PLSTAT_LAST_BIT downto 0);

p_in_phy_txd               : in    std_logic_vector(31 downto 0);
p_in_phy_txreq             : in    std_logic_vector(7 downto 0);
p_out_phy_txrdy_n          : out   std_logic;

p_out_phy_rxtype           : out   std_logic_vector(C_TDATA_EN downto C_TALIGN);
p_out_phy_rxdata           : out   std_logic_vector(31 downto 0);

p_out_phy_sync             : out   std_logic;

--------------------------------------------------
--Связь с RocketIO (Описание портов см. sata_rocketio.vhd)
--------------------------------------------------
p_in_gtp_pll_lock          : in    std_logic;

--RocketIO Tranceiver
p_out_gtp_txelecidle       : out   std_logic;
p_out_gtp_txcomstart       : out   std_logic;
p_out_gtp_txcomtype        : out   std_logic;
p_out_gtp_txdata           : out   std_logic_vector(15 downto 0);
p_out_gtp_txcharisk        : out   std_logic_vector(1 downto 0);
p_out_gtp_txreset          : out   std_logic;
p_in_gtp_txbufstatus       : in    std_logic_vector(1 downto 0);

--RocketIO Receiver
p_out_gtp_rxbufreset       : out   std_logic;
p_in_gtp_rxdata            : in    std_logic_vector(15 downto 0);
p_in_gtp_rxcharisk         : in    std_logic_vector(1 downto 0);
p_in_gtp_rxbufstatus       : in    std_logic_vector(2 downto 0);
p_in_gtp_rxstatus          : in    std_logic_vector(2 downto 0);
p_in_gtp_rxelecidle        : in    std_logic;
p_in_gtp_rxdisperr         : in    std_logic_vector(1 downto 0);
p_in_gtp_rxnotintable      : in    std_logic_vector(1 downto 0);
p_in_gtp_rxbyteisaligned   : in    std_logic;
p_in_gtp_rxbyterealigned   : in    std_logic;

p_out_gtp_datawidth        : out   std_logic;

--------------------------------------------------
--Технологические сигналы
--------------------------------------------------
p_in_tst                   : in    std_logic_vector(31 downto 0);
p_out_tst                  : out   std_logic_vector(31 downto 0);

--------------------------------------------------
--System
--------------------------------------------------
p_in_clk               : in    std_logic;
p_in_rst               : in    std_logic
);
end component;

component sata_rocketio
generic
(
G_GTP_DBUS : integer := 16;
G_SIM      : string  := "OFF"
);
port
(
---------------------------------------------------------------------------
--Driver
---------------------------------------------------------------------------
p_out_txn                        : out   std_logic_vector(C_GTP_CH_COUNT_MAX-1 downto 0);
p_out_txp                        : out   std_logic_vector(C_GTP_CH_COUNT_MAX-1 downto 0);

p_in_rxn                         : in    std_logic_vector(C_GTP_CH_COUNT_MAX-1 downto 0);
p_in_rxp                         : in    std_logic_vector(C_GTP_CH_COUNT_MAX-1 downto 0);

---------------------------------------------------------------------------
--Clocking
---------------------------------------------------------------------------
p_in_usrclk                      : in    std_logic_vector(C_GTP_CH_COUNT_MAX-1 downto 0);
p_in_usrclk2                     : in    std_logic_vector(C_GTP_CH_COUNT_MAX-1 downto 0);

---------------------------------------------------------------------------
--Tranceiver
---------------------------------------------------------------------------
p_in_txelecidle                  : in    std_logic_vector(C_GTP_CH_COUNT_MAX-1 downto 0);
p_in_txcomstart                  : in    std_logic_vector(C_GTP_CH_COUNT_MAX-1 downto 0);
p_in_txcomtype                   : in    std_logic_vector(C_GTP_CH_COUNT_MAX-1 downto 0);
p_in_txdata                      : in    TBus16_GtpCh;
p_in_txcharisk                   : in    TBus02_GtpCh;
p_in_txreset                     : in    std_logic_vector(C_GTP_CH_COUNT_MAX-1 downto 0);
p_out_txbufstatus                : out   TBus02_GtpCh;

---------------------------------------------------------------------------
--Receiver
---------------------------------------------------------------------------
p_in_rxreset                     : in    std_logic_vector(C_GTP_CH_COUNT_MAX-1 downto 0);
p_in_rxbufreset                  : in    std_logic_vector(C_GTP_CH_COUNT_MAX-1 downto 0);
p_out_rxdata                     : out   TBus16_GtpCh;
p_out_rxcharisk                  : out   TBus02_GtpCh;
p_out_rxbufstatus                : out   TBus03_GtpCh;
p_out_rxstatus                   : out   TBus03_GtpCh;
p_out_rxelecidle                 : out   std_logic_vector(C_GTP_CH_COUNT_MAX-1 downto 0);
p_out_rxdisperr                  : out   TBus02_GtpCh;
p_out_rxnotintable               : out   TBus02_GtpCh;
p_out_rxbyteisaligned            : out   std_logic_vector(C_GTP_CH_COUNT_MAX-1 downto 0);
p_out_rxbyterealigned            : out   std_logic_vector(C_GTP_CH_COUNT_MAX-1 downto 0);

---------------------------------------------------------------------------
--
---------------------------------------------------------------------------
p_in_datawidth                   : in    std_logic_vector(C_GTP_CH_COUNT_MAX-1 downto 0);

----------------------------------------------------------------------------
--System
----------------------------------------------------------------------------
p_in_drpclk                      : in    std_logic;
p_in_drpaddr                     : in    std_logic_vector(6 downto 0);
p_in_drpen                       : in    std_logic;
p_in_drpwe                       : in    std_logic;
p_in_drpdi                       : in    std_logic_vector(15 downto 0);
p_out_drpdo                      : out   std_logic_vector(15 downto 0);
p_out_drprdy                     : out   std_logic;

p_out_plllock                    : out   std_logic;
p_out_refclkout                  : out   std_logic;

p_in_refclkin                    : in    std_logic;
p_in_rst                         : in    std_logic
);
end component;

component sata_speed_ctrl
generic
(
--G_SPEED_SATA           : string  :="ALL";
G_SATA_MODULE_MAXCOUNT : integer := 1;
G_SATA_MODULE_IDX      : integer := 0;
G_GTP_CH_COUNT         : integer := 2;
G_DBG                  : string  := "OFF";
G_SIM                  : string  := "OFF"
);
port
(
--------------------------------------------------
--
--------------------------------------------------
p_in_cfg_sata_version   : in    std_logic_vector(1 downto 0);

--------------------------------------------------
--
--------------------------------------------------
p_out_sata_version      : out   std_logic_vector(C_GTP_CH_COUNT_MAX-1 downto 0);
p_in_link_establish     : in    std_logic_vector(C_GTP_CH_COUNT_MAX-1 downto 0);

p_out_gtp_ch_rst        : out   std_logic_vector(C_GTP_CH_COUNT_MAX-1 downto 0);
p_out_gtp_rst           : out   std_logic;

p_in_usr_dcm_lock       : in    std_logic;

--------------------------------------------------
--RocketIO
--------------------------------------------------
p_in_gtp_pll_lock       : in    std_logic;

p_out_gtp_drpclk        : out   std_logic;
p_out_gtp_drpaddr       : out   std_logic_vector(6 downto 0);
p_out_gtp_drpen         : out   std_logic;
p_out_gtp_drpwe         : out   std_logic;
p_out_gtp_drpdi         : out   std_logic_vector(15 downto 0);
p_in_gtp_drpdo          : in    std_logic_vector(15 downto 0);
p_in_gtp_drprdy         : in    std_logic;

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


component sata_host
generic
(
G_SATA_MODULE_MAXCOUNT   : integer   := 1;    --//кол-во модуле sata_host в иерархии модуля sata_dsn.vhd / (дипозон: 1...3)
G_SATA_MODULE_IDX        : integer   := 0;    --//индекс модуля sata_host в иерархии модуля sata_dsn.vhd / (дипозон: 0...G_SATA_MODULE_MAXCOUNT-1)
G_SATA_MODULE_CH_COUNT   : integer   := 1;    --//Кол-во портов SATA используемых в модуле sata_host.vhd / (дипозон: 1...2)
G_GTP_DBUS               : integer   := 16;   --//
G_DBG                    : string    := "OFF";--//В боевом проекте обязательно должно быть "OFF" - отладка через ChipScoupe
G_SIM                    : string    := "OFF" --//В боевом проекте обязательно должно быть "OFF" - моделирование
);
port
(
---------------------------------------------------------------------------
--Sata Driver
---------------------------------------------------------------------------
p_out_sata_txn              : out   std_logic_vector(C_GTP_CH_COUNT_MAX-1 downto 0);
p_out_sata_txp              : out   std_logic_vector(C_GTP_CH_COUNT_MAX-1 downto 0);
p_in_sata_rxn               : in    std_logic_vector(C_GTP_CH_COUNT_MAX-1 downto 0);
p_in_sata_rxp               : in    std_logic_vector(C_GTP_CH_COUNT_MAX-1 downto 0);

--------------------------------------------------
--Связь с APP Layer
--------------------------------------------------
p_in_al_ctrl                : in    TALCtrl_GtpCh;
p_out_al_status             : out   TALStatus_GtpCh;
p_out_al_clkout             : out   std_logic_vector(C_GTP_CH_COUNT_MAX-1 downto 0);

--//Связь с CMDFIFO
p_in_cmdfifo_dout           : in    TBus16_GtpCh;                                   --//
p_in_cmdfifo_eof_n          : in    std_logic_vector(C_GTP_CH_COUNT_MAX-1 downto 0);
p_in_cmdfifo_src_rdy_n      : in    std_logic_vector(C_GTP_CH_COUNT_MAX-1 downto 0);
p_out_cmdfifo_dst_rdy_n     : out   std_logic_vector(C_GTP_CH_COUNT_MAX-1 downto 0);

--//Связь с TXFIFO
p_in_txbuf_dout             : in    TBus32_GtpCh;                                   --//
p_out_txbuf_rd              : out   std_logic_vector(C_GTP_CH_COUNT_MAX-1 downto 0);
p_in_txbuf_status           : in    TTxBufStatus_GtpCh;

--//Связь с RXFIFO
p_out_rxbuf_din             : out   TBus32_GtpCh;                                   --//
p_out_rxbuf_wd              : out   std_logic_vector(C_GTP_CH_COUNT_MAX-1 downto 0);
p_in_rxbuf_status           : in    TRxBufStatus_GtpCh;

---------------------------------------------------------------------------
--Технологические сигналы
---------------------------------------------------------------------------
p_in_tst                    : in    std_logic_vector(31 downto 0);
p_out_tst                   : out   std_logic_vector(31 downto 0);

---------------------------------------------------------------------------
--Моделирование/Отладка - в рабочем проекте не используется
---------------------------------------------------------------------------
--//Моделирование
p_out_sim_gtp_txdata        : out   TBus16_GtpCh;
p_out_sim_gtp_txcharisk     : out   TBus02_GtpCh;
p_in_sim_gtp_rxdata         : in    TBus16_GtpCh;
p_in_sim_gtp_rxcharisk      : in    TBus02_GtpCh;
p_in_sim_gtp_rxstatus       : in    TBus03_GtpCh;
p_in_sim_gtp_rxelecidle     : in    std_logic_vector(C_GTP_CH_COUNT_MAX-1 downto 0);
p_out_sim_rst               : out   std_logic_vector(C_GTP_CH_COUNT_MAX-1 downto 0);
p_out_sim_clk               : out   std_logic_vector(C_GTP_CH_COUNT_MAX-1 downto 0);

---------------------------------------------------------------------------
--System
---------------------------------------------------------------------------
p_in_sys_dcm_gclk0          : in    std_logic;
p_in_sys_dcm_gclk2x         : in    std_logic;
p_in_sys_dcm_lock           : in    std_logic;
p_out_sys_dcm_rst           : out   std_logic;

p_out_gtp_refclk            : out   std_logic;--//выход порта REFCLKOUT модуля GTP_DUAL/sata_rocketio.vhdl
p_in_g_gtp_refclk           : in    std_logic;--//сигнлал p_out_gtp_refclk пропущенный через глобальный буфер
p_in_clk                    : in    std_logic;--//CLKIN для модуля RocketIO(GTP)
p_in_rst                    : in    std_logic
);
end component;

end sata_unit_pkg;


package body sata_unit_pkg is



end sata_unit_pkg;


