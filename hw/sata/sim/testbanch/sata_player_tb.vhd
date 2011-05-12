-------------------------------------------------------------------------
-- Company     : Linkos
-- Engineer    : Golovachenko Victor
--
-- Create Date : 09.02.2011 15:45:11
-- Module Name : sata_player_tb
--
-- Description : Моделирование работы модуля sata_llayer.vhd
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

use IEEE.std_logic_textio.all;
use STD.textio.all;

library unisim;
use unisim.vcomponents.all;

library work;
use work.vicg_common_pkg.all;
use work.sata_unit_pkg.all;
use work.sata_pkg.all;
use work.sata_sim_pkg.all;
use work.sata_sim_lite_pkg.all;

entity sata_player_tb is
generic
(
G_GT_DBUS    : integer:= 8;
G_DBG        : string := "ON";
G_SIM        : string := "ON"
);
end sata_player_tb;

architecture behavior of sata_player_tb is

constant i_clk_period : TIME := 6.6 ns; --150MHz

signal p_in_clk                   : std_logic;
signal p_in_rst                   : std_logic;
signal p_in_rst_inv               : std_logic;

signal i_sata_module_rst           : std_logic_vector(C_GTCH_COUNT_MAX-1 downto 0);

signal i_spd_ctrl                 : TSpdCtrl_GTCH;
signal i_spd_out                  : TSpdCtrl_GTCH;

signal i_link_ctrl                : TLLCtrl_GTCH;
signal i_link_status              : TLLStat_GTCH;
signal i_link_txd_close           : std_logic_vector(C_GTCH_COUNT_MAX-1 downto 0);
signal i_link_txd                 : TBus32_GTCH;
signal i_link_txd_rd              : std_logic_vector(C_GTCH_COUNT_MAX-1 downto 0);
signal i_link_txd_status          : TTxBufStatus_GTCH;
signal i_link_rxd                 : TBus32_GTCH;
signal i_link_rxd_wr              : std_logic_vector(C_GTCH_COUNT_MAX-1 downto 0);
signal i_link_rxd_status          : TRxBufStatus_GTCH;

signal i_phy_ctrl                 : TPLCtrl_GTCH;
signal i_phy_status               : TPLStat_GTCH;
signal i_phy_rxtype               : TBus21_GTCH;
signal i_phy_txreq                : TBus08_GTCH;
signal i_phy_txrdy_n              : std_logic_vector(C_GTCH_COUNT_MAX-1 downto 0);
signal i_phy_sync                 : std_logic_vector(C_GTCH_COUNT_MAX-1 downto 0);--: TBus02_GTCH;
signal i_phy_txd                  : TBus32_GTCH;
signal i_phy_rxd                  : TBus32_GTCH;

signal p_in_gtp_pll_lock          : std_logic;

signal i_sata_dcm_clk             : std_logic;
signal i_sata_dcm_clk2x           : std_logic;
signal i_sata_dcm_clk2div         : std_logic;
signal i_sata_dcm_lock            : std_logic;
signal i_sata_dcm_rst             : std_logic;

signal i_sim_gtp_clk              : std_logic;
signal i_sim_gtp_rst              : std_logic;
signal i_sim_gtp_rxelecidle       : std_logic;
signal i_sim_gtp_rxstatus         : std_logic_vector(2 downto 0);
signal i_sim_gtp_txdata           : std_logic_vector(31 downto 0);
signal i_sim_gtp_txcharisk        : std_logic_vector(3 downto 0);
signal i_sim_gtp_rxdata           : std_logic_vector(31 downto 0);
signal i_sim_gtp_rxcharisk        : std_logic_vector(3 downto 0);
signal i_sim_gtp_rxdisperr        : std_logic_vector(3 downto 0);
signal i_sim_gtp_rxnotintable     : std_logic_vector(3 downto 0);
signal i_sim_gtp_rxbyteisaligned  : std_logic;

signal i_sim_txd_cnt              : std_logic_vector(4 downto 0);
signal i_sim_txbuf_close          : std_logic;

signal i_satadev_ctrl             : TSataDevCtrl;


--Main
begin


i_phy_status(1)<=(others=>'0');



i_link_ctrl(0)(C_LCTRL_TxSTART_BIT)<='0','1' after 9 us, '0' after 9.4 us;
i_link_ctrl(0)(C_LCTRL_TRN_ESCAPE_BIT)<='0';
i_link_ctrl(0)(C_LCTRL_TL_CHECK_ERR_BIT)<='0';
i_link_ctrl(0)(C_LCTRL_TL_CHECK_DONE_BIT)<='1';
--i_link_ctrl(0)(C_LLCTRL_LAST_BIT downto 1)<=(others=>'0');

process(p_in_rst,p_in_clk)
variable tstdata : TSimBufData;
begin
  if p_in_rst='1' then
    i_sim_txd_cnt<=(others=>'0');
    i_sim_txbuf_close<='0';
    i_link_txd(0)(31 downto 0)<=(others=>'0');

    tstdata(0):=CONV_STD_LOGIC_VECTOR(C_FIS_DATA, tstdata(0)'length);
    for i in 1 to tstdata'high loop
    tstdata(i):=CONV_STD_LOGIC_VECTOR(i+1, tstdata(i)'length);
    end loop;

  elsif p_in_clk'event and p_in_clk='1' then
    if i_link_txd_rd(0)='1' then
      if i_sim_txd_cnt=CONV_STD_LOGIC_VECTOR(16#0E#, i_sim_txd_cnt'length) then
        i_sim_txbuf_close<='1';
        i_sim_txd_cnt<=i_sim_txd_cnt + 1;

      elsif i_sim_txd_cnt=CONV_STD_LOGIC_VECTOR(16#0F#, i_sim_txd_cnt'length) then
        i_sim_txbuf_close<='0';
        i_sim_txd_cnt<=(others=>'0');
      else
        i_sim_txd_cnt<=i_sim_txd_cnt + 1;
      end if;

      i_link_txd(0)(31 downto 0)<=tstdata(CONV_INTEGER(i_sim_txd_cnt));

    end if;
  end if;
end process;


i_link_txd_status(0).pfull<='0';
i_link_txd_close(0)<=i_sim_txbuf_close;

--i_link_txd_status(0).empty<='0';
--i_link_txd_status(0).aempty<='0';
--
--//Вариант 1 - отложеная передача HOLD перед выдачей данных
i_link_txd_status(0).aempty<='0','1' after 9.772 us, '0' after 9.8 us;
i_link_txd_status(0).empty<='1','1' after 9.772 us, '0' after 9.9 us;
------
------//Вариант 2 - нету отложеной передачи HOLD перед выдачей данных
----i_link_txd_status(0).empty<='0','1' after 11.8 us, '0' after 12.5 us;
----i_link_txd_status(0).aempty<='0','1' after 11.5 us, '0' after 11.8 us;


----i_link_rxd_status(0).pfull<='0';
--i_link_rxd_status(0).empty<='1';
--//Вариант 1
i_link_rxd_status(0).pfull<='0','1' after 6.872 us, '0' after 7.0 us;
i_link_rxd_status(0).empty<='1','0' after 6.872 us, '1' after 7.2 us;
----//Вариант 2
--i_link_rxd_status(0).pfull<='0','1' after 7.312 us, '0' after 7.8 us;
--i_link_rxd_status(0).empty<='1','0' after 7.312 us, '1' after 7.9 us;
----//Вариант 3
--i_link_rxd_status(0).pfull<='0','1' after 7.342 us, '0' after 7.8 us;
--i_link_rxd_status(0).empty<='1','0' after 7.342 us, '1' after 7.9 us;


i_link_ctrl(1)<=(others=>'0');
i_link_txd(1)<=(others=>'0');
i_link_txd_close(1)<='0';
i_link_txd_status(1).pfull<='0';
i_link_txd_status(1).aempty<='0';
i_link_txd_status(1).empty<='0';
i_link_rxd_status(1).pfull<='1';
i_link_rxd_status(1).empty<='1';


i_sata_module_rst(0)<=not i_sata_dcm_lock;
i_sata_module_rst(0)<='0';

m_llayer : sata_llayer
generic map
(
G_DBG      => G_DBG,
G_SIM      => G_SIM
)
port map
(
--------------------------------------------------
--Связь с Transport Layer
--------------------------------------------------
p_in_ctrl               => i_link_ctrl(0),
p_out_status            => i_link_status(0),

p_in_txd_close          => i_link_txd_close(0),
p_in_txd                => i_link_txd(0)(31 downto 0),
p_out_txd_rd            => i_link_txd_rd(0),
p_in_txd_status         => i_link_txd_status(0),

p_out_rxd               => i_link_rxd(0)(31 downto 0),
p_out_rxd_wr            => i_link_rxd_wr(0),
p_in_rxd_status         => i_link_rxd_status(0),

--------------------------------------------------
--Связь с Phy Layer
--------------------------------------------------
p_in_phy_status         => i_phy_status(0),
p_in_phy_sync           => i_phy_sync(0),

p_in_phy_rxtype         => i_phy_rxtype(0)(C_TDATA_EN downto C_TSYNC),
p_in_phy_rxd            => i_phy_rxd(0),

p_out_phy_txd           => i_phy_txd(0),
p_out_phy_txreq         => i_phy_txreq(0),
p_in_phy_txrdy_n        => i_phy_txrdy_n(0),

--------------------------------------------------
--Технологические сигналы
--------------------------------------------------
p_in_tst                => "00000000000000000000000000000000",
p_out_tst               => open,

--------------------------------------------------
--System
--------------------------------------------------
p_in_clk               => i_sata_dcm_clk,
p_in_rst               => i_sata_module_rst(0)
);


i_phy_ctrl(0)(C_PCTRL_SPD_BIT_M downto C_PCTRL_SPD_BIT_L)<=i_spd_out(0).sata_ver;
i_phy_ctrl(1)(C_PCTRL_SPD_BIT_M downto C_PCTRL_SPD_BIT_L)<=(others=>'0');

m_player : sata_player
generic map
(
G_GT_DBUS  => G_GT_DBUS,
G_DBG      => G_DBG,
G_SIM      => G_SIM
)
port map
(
--------------------------------------------------
--Управление (Описание портов см. sata_player_oob_cntrl.vhd)
--------------------------------------------------
p_in_ctrl                  => i_phy_ctrl(0),
p_out_status               => i_phy_status(0),

--------------------------------------------------
--Связь с Link Layer
--------------------------------------------------
p_in_phy_txd               => i_phy_txd(0),
p_in_phy_txreq             => i_phy_txreq(0),
p_out_phy_txrdy_n          => i_phy_txrdy_n(0),

p_out_phy_rxtype           => i_phy_rxtype(0)(C_TDATA_EN downto C_TALIGN),
p_out_phy_rxdata           => i_phy_rxd(0),

p_out_phy_sync             => i_phy_sync(0),

--------------------------------------------------
--Связь с RocketIO (Описание портов см. sata_player_gt.vhd)
--------------------------------------------------
p_out_gtp_rst              => open,

--RocketIO Tranceiver
p_out_gtp_txelecidle       => open,
p_out_gtp_txcomstart       => open,
p_out_gtp_txcomtype        => open,
p_out_gtp_txdata           => i_sim_gtp_rxdata,
p_out_gtp_txcharisk        => i_sim_gtp_rxcharisk,

--RocketIO Receiver
p_in_gtp_rxelecidle        => i_sim_gtp_rxelecidle,
p_in_gtp_rxstatus          => i_sim_gtp_rxstatus,
p_in_gtp_rxdata            => i_sim_gtp_txdata,
p_in_gtp_rxcharisk         => i_sim_gtp_txcharisk,
p_in_gtp_rxdisperr         => i_sim_gtp_rxdisperr,
p_in_gtp_rxnotintable      => i_sim_gtp_rxnotintable,
p_in_gtp_rxbyteisaligned   => i_sim_gtp_rxbyteisaligned,

--------------------------------------------------
--Технологические сигналы
--------------------------------------------------
p_in_tst                => "00000000000000000000000000000000",
p_out_tst               => open,

--------------------------------------------------
--System
--------------------------------------------------
p_in_tmrclk            => i_sata_dcm_clk2div,
p_in_clk               => i_sata_dcm_clk,
p_in_rst               => i_sata_module_rst(0)
);


i_spd_ctrl(0).change<='0';
i_spd_ctrl(0).sata_ver<=(others=>'0');

i_spd_ctrl(1).change<='0';
i_spd_ctrl(1).sata_ver<=(others=>'0');

m_speed_ctrl : sata_speed_ctrl
generic map
(
G_SATAH_COUNT_MAX => 1,
G_SATAH_NUM       => 0,
G_DBG             => G_DBG,
G_SIM             => G_SIM
)
port map
(
--------------------------------------------------
--
--------------------------------------------------
p_in_ctrl               => i_spd_ctrl,
p_out_spd_ver           => i_spd_out,

p_in_usr_dcm_lock       => i_sata_dcm_lock,
p_in_gtp_pll_lock       => '1',

--------------------------------------------------
--RocketIO
--------------------------------------------------
p_out_gtp_drpaddr       => open,
p_out_gtp_drpen         => open,
p_out_gtp_drpwe         => open,
p_out_gtp_drpdi         => open,
p_in_gtp_drpdo          => "0000000000000000",
p_in_gtp_drprdy         => '1',

p_out_gtp_ch_rst        => open,
p_out_gtp_rst           => open,

--------------------------------------------------
--Технологические сигналы
--------------------------------------------------
p_in_tst               => "00000000000000000000000000000000",
p_out_tst              => open,

--------------------------------------------------
--System
--------------------------------------------------
p_in_clk                => p_in_clk,
p_in_rst                => p_in_rst
);


m_sata_dev : sata_dev_model
generic map
(
G_DBG_LLAYER => "ON",
G_GT_DBUS    => G_GT_DBUS
)
port map
(
----------------------------
--
----------------------------
p_out_gtp_txdata            => i_sim_gtp_txdata,
p_out_gtp_txcharisk         => i_sim_gtp_txcharisk,

p_in_gtp_rxdata             => i_sim_gtp_rxdata,
p_in_gtp_rxcharisk          => i_sim_gtp_rxcharisk,

p_out_gtp_rxstatus          => i_sim_gtp_rxstatus,
p_out_gtp_rxelecidle        => i_sim_gtp_rxelecidle,
p_out_gtp_rxdisperr         => i_sim_gtp_rxdisperr,
p_out_gtp_rxnotintable      => i_sim_gtp_rxnotintable,
p_out_gtp_rxbyteisaligned   => i_sim_gtp_rxbyteisaligned,

p_in_ctrl                   => i_satadev_ctrl,

--------------------------------------------------
--Технологические сигналы
--------------------------------------------------
p_in_tst                   => "00000000000000000000000000000000",
p_out_tst                  => open,

----------------------------
--System
----------------------------
p_in_clk                    => i_sata_dcm_clk,
p_in_rst                    => p_in_rst_inv
);


m_sata_dcm : sata_dcm
port map
(
p_out_dcm_gclk0     => i_sata_dcm_clk,
p_out_dcm_gclk2x    => i_sata_dcm_clk2x,
p_out_dcm_gclkdv    => i_sata_dcm_clk2div,

p_out_dcmlock       => i_sata_dcm_lock,

p_in_clk            => p_in_clk,
p_in_rst            => p_in_rst
);


i_sata_dcm_clk<=p_in_clk;

clk_generator : process
begin
  p_in_clk<='0';
  wait for i_clk_period/2;
  p_in_clk<='1';
  wait for i_clk_period/2;
end process;

p_in_rst<='1','0' after 1 us;

p_in_rst_inv<=p_in_rst;--not i_sata_dcm_lock;


i_satadev_ctrl.atacmd_done<='0';
i_satadev_ctrl.loopback<='0';
i_satadev_ctrl.cmd_count<=1;
i_satadev_ctrl.dbuf_wuse<='0';
i_satadev_ctrl.dbuf_ruse<='0';

--End Main
end;
