-------------------------------------------------------------------------
-- Company     : Linkos
-- Engineer    : Golovachenko Victor
--
-- Create Date : 05.03.2011 13:10:01
-- Module Name : sata_host
--
-- Назначение :
--   Реализация SATA HOST.
--   Объединяет следующие уровни управления PHY/Link/Transport/Application Layer
--
-- Revision:
-- Revision 0.01 - 25.11.2008 - Начало работы над проектом SATA
-- Revision 1.00 - Полная переделка проекта
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
use work.sata_unit_pkg.all;
use work.sata_pkg.all;
use work.sata_sim_lite_pkg.all;

entity sata_host is
generic
(
G_SATAH_COUNT_MAX : integer:=1;    --//кол-во модулей sata_host
G_SATAH_NUM       : integer:=0;    --//индекс модуля sata_host
G_SATAH_CH_COUNT  : integer:=1;    --//Кол-во портов используемых в модуле GT.(возможные значения - 1,2)
G_GT_DBUS         : integer:=16;   --//Шина данных модуля GT
G_DBG             : string :="OFF";--//
G_DBGCS           : string :="OFF";--//Отладка через ChipScope
G_SIM             : string :="OFF" --//В боевом проекте обязательно должно быть "OFF" - моделирование
);
port
(
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
p_in_sys_dcm_gclk2div       : in    std_logic;--//dcm_clk0 /2
p_in_sys_dcm_gclk           : in    std_logic;--//dcm_clk0
p_in_sys_dcm_gclk2x         : in    std_logic;--//dcm_clk0 x 2
p_in_sys_dcm_lock           : in    std_logic;

p_out_gt_pllkdet            : out   std_logic;
p_out_gt_refclk             : out   std_logic;--//выход порта REFCLKOUT модуля GT/sata_player_gt.vhdl
p_in_gt_drpclk              : in    std_logic;--//
p_in_gt_refclk              : in    std_logic;--//CLKIN для модуля GT (RocketIO)

p_in_optrefclksel           : in    std_logic_vector(3 downto 0);
p_in_optrefclk              : in    std_logic_vector(3 downto 0);
p_out_optrefclk             : out   std_logic_vector(3 downto 0);

p_in_rst                    : in    std_logic
);
end sata_host;

architecture behavioral of sata_host is

signal i_spd_ctrl                  : TSpdCtrl_GTCH;
signal i_spd_gt_ch_rst             : std_logic_vector(C_GTCH_COUNT_MAX-1 downto 0);

signal i_reg_fpdma                 : TRegFPDMASetup_GTCH;
signal i_reg_shadow                : TRegShadow_GTCH;
signal i_reg_hold                  : TRegHold_GTCH;
signal i_reg_update                : TRegShadowUpdate_GTCH;

signal i_alstatus                  : TALStatus_GTCH;

signal i_tr_ctrl                   : TTLCtrl_GTCH;
signal i_tr_status                 : TTLStat_GTCH;

signal i_link_ctrl                 : TLLCtrl_GTCH;
signal i_link_status               : TLLStat_GTCH;
signal i_link_txd_close            : std_logic_vector(C_GTCH_COUNT_MAX-1 downto 0);
signal i_link_txd                  : TBus32_GTCH;
signal i_link_txd_rd               : std_logic_vector(C_GTCH_COUNT_MAX-1 downto 0);
signal i_link_txd_status           : TTxBufStatus_GTCH;
signal i_link_rxd                  : TBus32_GTCH;
signal i_link_rxd_wr               : std_logic_vector(C_GTCH_COUNT_MAX-1 downto 0);
signal i_link_rxd_status           : TRxBufStatus_GTCH;

signal i_phy_layer_rst             : std_logic_vector(C_GTCH_COUNT_MAX-1 downto 0);
signal i_phy_linkup                : std_logic_vector(C_GTCH_COUNT_MAX-1 downto 0);
signal i_phy_spd                   : TSpdCtrl_GTCH;
signal i_phy_rxtype                : TBus21_GTCH;
signal i_phy_txreq                 : TBus08_GTCH;
signal i_phy_txrdy_n               : std_logic_vector(C_GTCH_COUNT_MAX-1 downto 0);
signal i_phy_sync                  : std_logic_vector(C_GTCH_COUNT_MAX-1 downto 0);
signal i_phy_txd                   : TBus32_GTCH;
signal i_phy_rxd                   : TBus32_GTCH;
signal i_phy_ctrl                  : TPLCtrl_GTCH;
signal i_phy_status                : TPLStat_GTCH;
signal i_phy_gt_ch_rst             : std_logic_vector(C_GTCH_COUNT_MAX-1 downto 0);
signal i_phy_gt_rxbufreset         : std_logic_vector(C_GTCH_COUNT_MAX-1 downto 0);

signal i_gt_plllkdet               : std_logic;
signal i_gt_resetdone              : std_logic_vector(C_GTCH_COUNT_MAX-1 downto 0);
signal g_gt_usrclk2                : std_logic_vector(C_GTCH_COUNT_MAX-1 downto 0);

signal i_gt_drpaddr                : std_logic_vector(7 downto 0);
signal i_gt_drpen                  : std_logic;
signal i_gt_drpwe                  : std_logic;
signal i_gt_drpdi                  : std_logic_vector(15 downto 0);
signal i_gt_drpdo                  : std_logic_vector(15 downto 0);
signal i_gt_drprdy                 : std_logic;

signal i_gt_rxreset                : std_logic_vector(C_GTCH_COUNT_MAX-1 downto 0);
signal i_gt_rxcdrreset             : std_logic_vector(C_GTCH_COUNT_MAX-1 downto 0);
signal i_gt_rxstatus               : TBus03_GTCH;
signal i_gt_rxelecidle             : std_logic_vector(C_GTCH_COUNT_MAX-1 downto 0):=(others=>'0');
signal i_gt_rxdata                 : TBus32_GTCH;
signal i_gt_rxcharisk              : TBus04_GTCH;
signal i_gt_rxdisperr              : TBus04_GTCH;
signal i_gt_rxnotintable           : TBus04_GTCH;
signal i_gt_rxbyteisaligned        : std_logic_vector(C_GTCH_COUNT_MAX-1 downto 0):=(others=>'0');

signal i_gt_rxbufstatus            : TBus03_GTCH;
signal i_gt_rxbufreset             : std_logic_vector(C_GTCH_COUNT_MAX-1 downto 0):=(others=>'0');

signal i_gt_txreset                : std_logic_vector(C_GTCH_COUNT_MAX-1 downto 0):=(others=>'0');
signal i_gt_txbufreset             : std_logic_vector(C_GTCH_COUNT_MAX-1 downto 0):=(others=>'0');
signal i_gt_txbufstatus            : TBus02_GTCH;

signal i_gt_txelecidle             : std_logic_vector(C_GTCH_COUNT_MAX-1 downto 0):=(others=>'0');
signal i_gt_txcomstart             : std_logic_vector(C_GTCH_COUNT_MAX-1 downto 0):=(others=>'0');
signal i_gt_txcomtype              : std_logic_vector(C_GTCH_COUNT_MAX-1 downto 0):=(others=>'0');
signal i_gt_txdata                 : TBus32_GTCH;
signal i_gt_txcharisk              : TBus04_GTCH;

signal i_dbgcs_spd                 : TSH_ila;
signal i_dbg                       : TSH_dbgport_GTCH;

signal tst_alayer_out              : TBus32_GTCH;
signal tst_tlayer_out              : TBus32_GTCH;
signal tst_llayer_out              : TBus32_GTCH;
signal tst_player_out              : TBus32_GTCH;
signal tst_spctrl_out              : std_logic_vector(31 downto 0);



--MAIN
begin




--//#############################
--//Инициализация
--//#############################
p_out_gt_pllkdet<=i_gt_plllkdet;


--//#############################
--//Программирование регистров модуля GT (RocketIO)
--//#############################
m_speed_ctrl : sata_speed_ctrl
generic map
(
G_SATAH_COUNT_MAX => G_SATAH_COUNT_MAX,
G_SATAH_NUM       => G_SATAH_NUM,
G_SATAH_CH_COUNT  => G_SATAH_CH_COUNT,
G_DBG             => G_DBG,
G_DBGCS           => G_DBGCS,
G_SIM             => G_SIM
)
port map
(
--------------------------------------------------
--
--------------------------------------------------
p_in_ctrl           => i_spd_ctrl,
p_out_phy_spd       => i_phy_spd,
p_out_phy_layer_rst => i_phy_layer_rst,

p_in_phy_linkup     => i_phy_linkup,
p_in_gt_pll_lock    => i_gt_plllkdet,
p_in_usr_dcm_lock   => p_in_sys_dcm_lock,

--------------------------------------------------
--RocketIO
--------------------------------------------------
p_out_gt_drpaddr    => i_gt_drpaddr,
p_out_gt_drpen      => i_gt_drpen,
p_out_gt_drpwe      => i_gt_drpwe,
p_out_gt_drpdi      => i_gt_drpdi,
p_in_gt_drpdo       => i_gt_drpdo,
p_in_gt_drprdy      => i_gt_drprdy,

p_out_gt_ch_rst     => i_spd_gt_ch_rst,
p_in_gt_resetdone   => i_gt_resetdone,

--------------------------------------------------
--Технологические сигналы
--------------------------------------------------
p_in_tst            => p_in_tst(0),
p_out_tst           => tst_spctrl_out,
p_out_dbgcs_ila     => i_dbgcs_spd,

--------------------------------------------------
--System
--------------------------------------------------
p_in_clk            => p_in_gt_drpclk,
p_in_rst            => p_in_rst
);



--//###########################################################################
--//Размножение модулей управления SATA соответствующего канала GT (RocketIO)
--//###########################################################################
gen_ch: for i in 0 to G_SATAH_CH_COUNT-1 generate

--//----------------------------------
--//Технологические сигналы
--//----------------------------------
gen_dbg_off : if strcmp(G_DBG,"OFF") generate
p_out_tst(i)(31 downto 0)<=(others=>'0');
end generate gen_dbg_off;

gen_dbg_on : if strcmp(G_DBG,"ON") generate

--p_out_tst(i)(31 downto 0)<=(others=>'0');
tst0out:process(p_in_rst,g_gt_usrclk2(i))
begin
  if p_in_rst='1' then
    p_out_tst(i)(0)<='0';

  elsif g_gt_usrclk2(i)'event and g_gt_usrclk2(i)='1' then

    p_out_tst(i)(0)<=tst_player_out(i)(0) or
                     tst_llayer_out(i)(0) or
                     tst_tlayer_out(i)(0) or
                     tst_alayer_out(i)(0);

  end if;
end process tst0out;

p_out_tst(i)(1)<='0';

tst2out:process(p_in_rst,p_in_gt_drpclk)
begin
  if p_in_rst='1' then
    p_out_tst(i)(2)<='0';
  elsif p_in_gt_drpclk'event and p_in_gt_drpclk='1' then
    p_out_tst(i)(2)<=tst_spctrl_out(0);
  end if;
end process tst2out;

p_out_tst(i)(31 downto 3)<=(others=>'0');

end generate gen_dbg_on;



--//-----------------------------
--//Инициализация
--//-----------------------------
p_out_dbgcs(i).spd<=i_dbgcs_spd;

i_phy_linkup(i)<=i_phy_status(i)(C_PSTAT_DET_ESTABLISH_ON_BIT);

i_phy_ctrl(i)(C_PCTRL_SPD_BIT_M downto C_PCTRL_SPD_BIT_L)<=i_phy_spd(i).sata_ver;

--//Сброс канала GT
i_gt_txreset(i)<=i_spd_gt_ch_rst(i) or i_phy_gt_ch_rst(i) or i_gt_txbufreset(i);
i_gt_rxreset(i)<=i_spd_gt_ch_rst(i) or i_phy_gt_ch_rst(i);
i_gt_rxbufreset(i)<=i_spd_gt_ch_rst(i) or i_phy_gt_rxbufreset(i);
i_gt_rxcdrreset(i)<=i_spd_gt_ch_rst(i);--//Сброс модуля востановления частоты RxCDR


--//Тактирование Cmd/Rx/TxBUF - usrapp_layer
p_out_usrfifo_clkout(i)<=g_gt_usrclk2(i);

p_out_status(i)<=i_alstatus(i);


--//-----------------------------
--//Implemention Layers:
--//-----------------------------
m_alayer : sata_alayer
generic map
(
G_DBG => G_DBG,
G_SIM => G_SIM
)
port map
(
--------------------------------------------------
--Связь с USR APP Layer
--------------------------------------------------
p_in_ctrl               => p_in_ctrl(i),
p_out_status            => i_alstatus(i),

--//Связь с CMDFIFO
p_in_cmdfifo_dout       => p_in_cmdfifo_dout(i),
p_in_cmdfifo_eof_n      => p_in_cmdfifo_eof_n(i),
p_in_cmdfifo_src_rdy_n  => p_in_cmdfifo_src_rdy_n(i),
--p_out_cmdfifo_dst_rdy_n => p_out_cmdfifo_dst_rdy_n(i),

--------------------------------------------------
--Связь с Transport/Link/PHY Layer
--------------------------------------------------
p_out_spd_ctrl          => i_spd_ctrl(i),
p_out_tl_ctrl           => i_tr_ctrl(i),
p_in_tl_status          => i_tr_status(i),
p_in_ll_status          => i_link_status(i),
p_in_pl_status          => i_phy_status(i),

p_in_reg_fpdma          => i_reg_fpdma(i),
p_out_reg_shadow        => i_reg_shadow(i),
p_in_reg_hold           => i_reg_hold(i),
p_in_reg_update         => i_reg_update(i),

--------------------------------------------------
--Технологические сигналы
--------------------------------------------------
p_in_tst                => p_in_tst(i),
p_out_tst               => tst_alayer_out(i),
p_out_dbg               => i_dbg(i).alayer,

--------------------------------------------------
--System
--------------------------------------------------
p_in_clk                => g_gt_usrclk2(i),
p_in_rst                => p_in_rst
);

m_tlayer : sata_tlayer
generic map
(
G_DBG => G_DBG,
G_SIM => G_SIM
)
port map
(
--------------------------------------------------
--Связь с USERAPP Layer
--------------------------------------------------
--//Связь с TXFIFO
p_in_txfifo_dout     => p_in_txbuf_dout(i),
p_out_txfifo_rd      => p_out_txbuf_rd(i),
p_in_txfifo_status   => p_in_txbuf_status(i),

--//Связь с RXFIFO
p_out_rxfifo_din     => p_out_rxbuf_din(i),
p_out_rxfifo_wd      => p_out_rxbuf_wd(i),
p_in_rxfifo_status   => p_in_rxbuf_status(i),

--------------------------------------------------
--Связь с APP Layer
--------------------------------------------------
p_in_tl_ctrl         => i_tr_ctrl(i),
p_out_tl_status      => i_tr_status(i),

p_out_reg_fpdma      => i_reg_fpdma(i),
p_in_reg_shadow      => i_reg_shadow(i),
p_out_reg_hold       => i_reg_hold(i),
p_out_reg_update     => i_reg_update(i),

--------------------------------------------------
--Связь с Link Layer
--------------------------------------------------
p_out_ll_ctrl        => i_link_ctrl(i),
p_in_ll_status       => i_link_status(i),

p_out_ll_txd_close   => i_link_txd_close(i),
p_out_ll_txd         => i_link_txd(i),
p_in_ll_txd_rd       => i_link_txd_rd(i),
p_out_ll_txd_status  => i_link_txd_status(i),

p_in_ll_rxd          => i_link_rxd(i),
p_in_ll_rxd_wr       => i_link_rxd_wr(i),
p_out_ll_rxd_status  => i_link_rxd_status(i),

--------------------------------------------------
--Связь с PHY Layer
--------------------------------------------------
p_in_pl_status       => i_phy_status(i),

--------------------------------------------------
--Технологические сигналы
--------------------------------------------------
p_in_tst             => p_in_tst(i),
p_out_tst            => tst_tlayer_out(i),
p_out_dbg            => i_dbg(i).tlayer,

--------------------------------------------------
--System
--------------------------------------------------
p_in_clk             => g_gt_usrclk2(i),
p_in_rst             => p_in_rst
);

m_llayer : sata_llayer
generic map
(
G_DBG => G_DBG,
G_SIM => G_SIM
)
port map
(
--------------------------------------------------
--Связь с Transport Layer
--------------------------------------------------
p_in_ctrl         => i_link_ctrl(i),
p_out_status      => i_link_status(i),

p_in_txd_close    => i_link_txd_close(i),
p_in_txd          => i_link_txd(i),
p_out_txd_rd      => i_link_txd_rd(i),
p_in_txd_status   => i_link_txd_status(i),

p_out_rxd         => i_link_rxd(i),
p_out_rxd_wr      => i_link_rxd_wr(i),
p_in_rxd_status   => i_link_rxd_status(i),

--------------------------------------------------
--Связь с Phy Layer
--------------------------------------------------
p_in_phy_status   => i_phy_status(i),
p_in_phy_sync     => i_phy_sync(i),

p_in_phy_rxtype   => i_phy_rxtype(i)(C_TDATA_EN downto C_TSYNC),
p_in_phy_rxd      => i_phy_rxd(i),

p_out_phy_txd     => i_phy_txd(i),
p_out_phy_txreq   => i_phy_txreq(i),
p_in_phy_txrdy_n  => i_phy_txrdy_n(i),

--------------------------------------------------
--Технологические сигналы
--------------------------------------------------
p_in_tst          => p_in_tst(i),
p_out_tst         => tst_llayer_out(i),
p_out_dbg         => i_dbg(i).llayer,

--------------------------------------------------
--System
--------------------------------------------------
p_in_clk          => g_gt_usrclk2(i),
p_in_rst          => p_in_rst
);

m_player : sata_player
generic map
(
G_GT_DBUS   => G_GT_DBUS,
G_DBG       => G_DBG,
G_SIM       => G_SIM
)
port map
(
--------------------------------------------------
--Управление
--------------------------------------------------
p_in_ctrl               => i_phy_ctrl(i),
p_out_status            => i_phy_status(i),

--------------------------------------------------
--Связь с Link Layer
--------------------------------------------------
p_in_phy_txd            => i_phy_txd(i),
p_in_phy_txreq          => i_phy_txreq(i),
p_out_phy_txrdy_n       => i_phy_txrdy_n(i),

p_out_phy_rxtype        => i_phy_rxtype(i)(C_TDATA_EN downto C_TALIGN),
p_out_phy_rxdata        => i_phy_rxd(i),

p_out_phy_sync          => i_phy_sync(i),

--------------------------------------------------
--Связь с RocketIO
--------------------------------------------------
p_out_gt_rst            => i_phy_gt_ch_rst(i),

--RocketIO Tranceiver
p_out_gt_txelecidle     => i_gt_txelecidle(i),
p_out_gt_txcomstart     => i_gt_txcomstart(i),
p_out_gt_txcomtype      => i_gt_txcomtype(i),
p_out_gt_txdata         => i_gt_txdata(i),
p_out_gt_txcharisk      => i_gt_txcharisk(i),

p_out_gt_txreset        => i_gt_txbufreset(i),
p_in_gt_txbufstatus     => i_gt_txbufstatus(i),

--RocketIO Receiver
p_in_gt_rxelecidle      => i_gt_rxelecidle(i),
p_in_gt_rxstatus        => i_gt_rxstatus(i),
p_in_gt_rxdata          => i_gt_rxdata(i),
p_in_gt_rxcharisk       => i_gt_rxcharisk(i),
p_in_gt_rxdisperr       => i_gt_rxdisperr(i),
p_in_gt_rxnotintable    => i_gt_rxnotintable(i),
p_in_gt_rxbyteisaligned => i_gt_rxbyteisaligned(i),

p_in_gt_rxbufstatus     => i_gt_rxbufstatus(i),
p_out_gt_rxbufreset     => i_phy_gt_rxbufreset(i),

--------------------------------------------------
--Технологические сигналы
--------------------------------------------------
p_in_tst                => p_in_tst(i),
p_out_tst               => tst_player_out(i),
p_out_dbg               => i_dbg(i).player,

--------------------------------------------------
--System
--------------------------------------------------
p_in_tmrclk             => p_in_sys_dcm_gclk2div,
p_in_clk                => g_gt_usrclk2(i),
p_in_rst                => i_phy_layer_rst(i)
);


gen_dbgcs_on : if strcmp(G_DBGCS,"ON") generate

m_dbgcs : sata_dbgcs
generic map
(
G_DBG => G_DBG,
G_SIM => G_SIM
)
port map
(
--------------------------------------------------
--Связь с СhipScope ICON
--------------------------------------------------
p_out_dbgcs_ila   => p_out_dbgcs(i).layer,

--------------------------------------------------
--USR
--------------------------------------------------
p_in_ctrl         => p_in_ctrl(i),

p_in_dbg          => i_dbg(i),
p_in_alstatus     => i_alstatus(i),
p_in_phy_txreq    => i_phy_txreq(i),
p_in_phy_rxtype   => i_phy_rxtype(i)(C_TDATA_EN downto C_TALIGN),
p_in_phy_rxdata   => i_phy_rxd(i),
p_in_phy_sync     => i_phy_sync(i),

p_in_reg_hold     => i_reg_hold(i),
p_in_reg_update   => i_reg_update(i),

p_in_ll_rxd       => i_link_rxd(i), --//llayer -> tlayer
p_in_ll_rxd_wr    => i_link_rxd_wr(i),
p_in_ll_txd       => i_link_txd(i), --//llayer <- tlayer
p_in_ll_txd_rd    => i_link_txd_rd(i),

p_in_gt_rxdata    => i_gt_rxdata(i),
p_in_gt_rxcharisk => i_gt_rxcharisk(i),

p_in_gt_txdata    => i_gt_txdata(i),
p_in_gt_txcharisk => i_gt_txcharisk(i),

--------------------------------------------------
--Технологические сигналы
--------------------------------------------------
p_out_tst         => open,

--------------------------------------------------
--System
--------------------------------------------------
p_in_clk          => g_gt_usrclk2(i),
p_in_rst          => p_in_rst
);

end generate gen_dbgcs_on;

end generate gen_ch;



--//############################
--//GT (RocketIO)
--//############################
gen_sim_off : if strcmp(G_SIM,"OFF") generate

m_gt : sata_player_gt
generic map
(
G_SATAH_NUM   => G_SATAH_NUM,
G_GT_CH_COUNT => G_SATAH_CH_COUNT,
G_GT_DBUS     => G_GT_DBUS,
G_SIM         => G_SIM
)
port map
(
--------------------------------------------------
--
--------------------------------------------------
p_in_spd               => i_phy_spd,
p_in_sys_dcm_gclk2div  => p_in_sys_dcm_gclk2div,
p_in_sys_dcm_gclk      => p_in_sys_dcm_gclk,
p_in_sys_dcm_gclk2x    => p_in_sys_dcm_gclk2x,

p_out_usrclk2          => g_gt_usrclk2,
p_out_resetdone        => i_gt_resetdone,

--------------------------------------------------
--Driver
--------------------------------------------------
p_out_txn              => p_out_sata_txn,
p_out_txp              => p_out_sata_txp,
p_in_rxn               => p_in_sata_rxn,
p_in_rxp               => p_in_sata_rxp,

--------------------------------------------------
--Tranceiver
--------------------------------------------------
p_in_txelecidle        => i_gt_txelecidle,
p_in_txcomstart        => i_gt_txcomstart,
p_in_txcomtype         => i_gt_txcomtype,
p_in_txdata            => i_gt_txdata,
p_in_txcharisk         => i_gt_txcharisk,

p_in_txreset           => i_gt_txreset,
p_out_txbufstatus      => i_gt_txbufstatus,

--------------------------------------------------
--Receiver
--------------------------------------------------
p_in_rxcdrreset        => i_gt_rxcdrreset,
p_in_rxreset           => i_gt_rxreset,
p_out_rxelecidle       => i_gt_rxelecidle,
p_out_rxstatus         => i_gt_rxstatus,
p_out_rxdata           => i_gt_rxdata,
p_out_rxcharisk        => i_gt_rxcharisk,
p_out_rxdisperr        => i_gt_rxdisperr,
p_out_rxnotintable     => i_gt_rxnotintable,
p_out_rxbyteisaligned  => i_gt_rxbyteisaligned,

p_in_rxbufreset        => i_gt_rxbufreset,
p_out_rxbufstatus      => i_gt_rxbufstatus,

--------------------------------------------------
--System
--------------------------------------------------
p_in_drpclk            => p_in_gt_drpclk,
p_in_drpaddr           => i_gt_drpaddr,
p_in_drpen             => i_gt_drpen,
p_in_drpwe             => i_gt_drpwe,
p_in_drpdi             => i_gt_drpdi,
p_out_drpdo            => i_gt_drpdo,
p_out_drprdy           => i_gt_drprdy,

p_out_plllock          => i_gt_plllkdet,
p_out_refclkout        => p_out_gt_refclk,

p_in_refclkin          => p_in_gt_refclk,

p_in_optrefclksel      => p_in_optrefclksel,
p_in_optrefclk         => p_in_optrefclk,
p_out_optrefclk        => p_out_optrefclk,

p_in_rst               => p_in_rst
);

end generate gen_sim_off;



---##############################
-- Debug/Sim
---##############################
gen_sim_on: if strcmp(G_SIM,"ON") generate

p_out_dbg<=i_dbg;

p_out_sim_rst <= i_phy_layer_rst;
p_out_sim_clk <= g_gt_usrclk2;

p_out_sim_gt_txdata   <= i_gt_txdata;
p_out_sim_gt_txcharisk <= i_gt_txcharisk;
p_out_sim_gt_txcomstart <= i_gt_txcomstart;

i_gt_rxelecidle      <= p_in_sim_gt_rxelecidle;
i_gt_rxstatus        <= p_in_sim_gt_rxstatus;
i_gt_rxdata          <= p_in_sim_gt_rxdata;
i_gt_rxcharisk       <= p_in_sim_gt_rxcharisk;
i_gt_rxdisperr       <= p_in_sim_gt_rxdisperr;
i_gt_rxnotintable    <= p_in_sim_gt_rxnotintable;
i_gt_rxbyteisaligned <= p_in_sim_gt_rxbyteisaligned;

m_gt_sim : sata_player_gtsim
generic map
(
G_SATAH_NUM   => G_SATAH_NUM,
G_GT_CH_COUNT => G_SATAH_CH_COUNT,
G_GT_DBUS     => G_GT_DBUS,
G_SIM         => G_SIM
)
port map
(
--------------------------------------------------
--
--------------------------------------------------
p_in_spd               => i_phy_spd,
p_in_sys_dcm_gclk2div  => p_in_sys_dcm_gclk2div,
p_in_sys_dcm_gclk      => p_in_sys_dcm_gclk,
p_in_sys_dcm_gclk2x    => p_in_sys_dcm_gclk2x,

p_out_usrclk2          => g_gt_usrclk2,

---------------------------------------------------
--System
---------------------------------------------------
--Порт динамическаго конфигурирования GT (RocketIO)
p_out_drpdo            => i_gt_drpdo,
p_out_drprdy           => i_gt_drprdy,

p_out_plllock          => i_gt_plllkdet,
p_out_refclkout        => p_out_gt_refclk,

p_in_refclkin          => p_in_gt_refclk,

p_in_optrefclksel      => p_in_optrefclksel,
p_in_optrefclk         => p_in_optrefclk,
p_out_optrefclk        => p_out_optrefclk,

p_in_rst               => p_in_rst
);

gen_null : for i in 0 to C_GTCH_COUNT_MAX-1 generate
i_gt_rxbufstatus(i)<=(others=>'0');
i_gt_txbufstatus(i)<=(others=>'0');
i_gt_resetdone(i)<='1';
end generate gen_null;

end generate gen_sim_on;


--END MAIN
end behavioral;

