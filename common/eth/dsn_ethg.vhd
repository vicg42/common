-------------------------------------------------------------------------
-- Company     : Linkos
-- Engineer    : Golovachenko Victor
--
-- Create Date : 03.05.2011 16:39:38
-- Module Name : dsn_ethg
--
-- Назначение/Описание :
--  Запись/Чтение регистров устройств
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
use work.prj_def.all;
use work.eth_pkg.all;

entity dsn_ethg is
generic
(
G_MODULE_USE : string:="ON";
G_DBG        : string:="OFF";
G_SIM        : string:="OFF"
);
port
(
-------------------------------
-- Конфигурирование модуля dsn_ethg.vhd (host_clk domain)
-------------------------------
p_in_cfg_clk           : in   std_logic;                    --//

p_in_cfg_adr           : in   std_logic_vector(7 downto 0); --//
p_in_cfg_adr_ld        : in   std_logic;                    --//
p_in_cfg_adr_fifo      : in   std_logic;                    --//

p_in_cfg_txdata        : in   std_logic_vector(15 downto 0);--//
p_in_cfg_wd            : in   std_logic;                    --//

p_out_cfg_rxdata       : out  std_logic_vector(15 downto 0);--//
p_in_cfg_rd            : in   std_logic;                    --//

p_in_cfg_done          : in   std_logic;                    --//
p_in_cfg_rst           : in   std_logic;

-------------------------------
-- STATUS модуля dsn_ethg.vhd
-------------------------------
p_out_eth_rdy          : out  std_logic;                    --//
p_out_eth_error        : out  std_logic;                    --//
p_out_eth_gt_plllkdet  : out  std_logic;                    --//

p_out_sfp_tx_dis       : out  std_logic;                    --//SFP - TX DISABLE
p_in_sfp_sd            : in   std_logic;                    --//SFP - SD signal detect

-------------------------------
-- Связь с буферами модуля dsn_switch.vhd
-------------------------------
p_out_eth_rxbuf_din    : out  std_logic_vector(31 downto 0);
p_out_eth_rxbuf_wr     : out  std_logic;
p_in_eth_rxbuf_full    : in   std_logic;
p_out_eth_rxd_sof      : out  std_logic;
p_out_eth_rxd_eof      : out  std_logic;

p_in_eth_txbuf_dout    : in   std_logic_vector(31 downto 0);
p_out_eth_txbuf_rd     : out  std_logic;
p_in_eth_txbuf_empty   : in   std_logic;
p_in_eth_txd_rdy       : in   std_logic;

--------------------------------------------------
--ETH Driver
--------------------------------------------------
p_out_eth_gt_txp       : out   std_logic_vector(1 downto 0);
p_out_eth_gt_txn       : out   std_logic_vector(1 downto 0);
p_in_eth_gt_rxp        : in    std_logic_vector(1 downto 0);
p_in_eth_gt_rxn        : in    std_logic_vector(1 downto 0);

p_in_eth_gt_refclk     : in    std_logic;
p_out_eth_gt_refclkout : out   std_logic;
p_in_eth_gt_drpclk     : in    std_logic;

-------------------------------
--Технологический
-------------------------------
p_in_tst               : in    std_logic_vector(31 downto 0);
p_out_tst              : out   std_logic_vector(31 downto 0);

-------------------------------
--System
-------------------------------
p_in_rst               : in    std_logic
);
end dsn_ethg;

architecture behavioral of dsn_ethg is


component ROCKETIO_WRAPPER_GTP_TILE
generic
(
-- Simulation attributes
TILE_SIM_GTPRESET_SPEEDUP    : integer   := 0; -- Set to 1 to speed up sim reset
TILE_SIM_PLL_PERDIV2         : bit_vector:= x"190"; -- Set to the VCO Unit Interval time

-- Channel bonding attributes
TILE_CHAN_BOND_MODE_0        : string    := "OFF";  -- "MASTER", "SLAVE", or "OFF"
TILE_CHAN_BOND_LEVEL_0       : integer   := 0;     -- 0 to 7. See UG for details

TILE_CHAN_BOND_MODE_1        : string    := "OFF";  -- "MASTER", "SLAVE", or "OFF"
TILE_CHAN_BOND_LEVEL_1       : integer   := 0      -- 0 to 7. See UG for details
);
port
(
p_in_drp_ctrl                  : in   std_logic_vector(31 downto 0);

------------------------ Loopback and Powerdown Ports ----------------------
LOOPBACK0_IN                            : in   std_logic_vector(2 downto 0);
LOOPBACK1_IN                            : in   std_logic_vector(2 downto 0);
----------------------- Receive Ports - 8b10b Decoder ----------------------
RXCHARISCOMMA0_OUT                      : out  std_logic;
RXCHARISCOMMA1_OUT                      : out  std_logic;
RXCHARISK0_OUT                          : out  std_logic;
RXCHARISK1_OUT                          : out  std_logic;
RXDISPERR0_OUT                          : out  std_logic;
RXDISPERR1_OUT                          : out  std_logic;
RXNOTINTABLE0_OUT                       : out  std_logic;
RXNOTINTABLE1_OUT                       : out  std_logic;
RXRUNDISP0_OUT                          : out  std_logic;
RXRUNDISP1_OUT                          : out  std_logic;
------------------- Receive Ports - Clock Correction Ports -----------------
RXCLKCORCNT0_OUT                        : out  std_logic_vector(2 downto 0);
RXCLKCORCNT1_OUT                        : out  std_logic_vector(2 downto 0);
--------------- Receive Ports - Comma Detection and Alignment --------------
RXENMCOMMAALIGN0_IN                     : in   std_logic;
RXENMCOMMAALIGN1_IN                     : in   std_logic;
RXENPCOMMAALIGN0_IN                     : in   std_logic;
RXENPCOMMAALIGN1_IN                     : in   std_logic;
------------------- Receive Ports - RX Data Path interface -----------------
RXDATA0_OUT                             : out  std_logic_vector(7 downto 0);
RXDATA1_OUT                             : out  std_logic_vector(7 downto 0);
RXRECCLK0_OUT                           : out  std_logic;
RXRECCLK1_OUT                           : out  std_logic;
RXRESET0_IN                             : in   std_logic;
RXRESET1_IN                             : in   std_logic;
RXUSRCLK0_IN                            : in   std_logic;
RXUSRCLK1_IN                            : in   std_logic;
RXUSRCLK20_IN                           : in   std_logic;
RXUSRCLK21_IN                           : in   std_logic;
------- Receive Ports - RX Driver,OOB signalling,Coupling and Eq.,CDR ------
RXELECIDLE0_OUT                         : out  std_logic;
RXELECIDLE1_OUT                         : out  std_logic;
RXN0_IN                                 : in   std_logic;
RXN1_IN                                 : in   std_logic;
RXP0_IN                                 : in   std_logic;
RXP1_IN                                 : in   std_logic;
-------- Receive Ports - RX Elastic Buffer and Phase Alignment Ports -------
RXBUFRESET0_IN                          : in   std_logic;
RXBUFRESET1_IN                          : in   std_logic;
RXBUFSTATUS0_OUT                        : out  std_logic_vector(2 downto 0);
RXBUFSTATUS1_OUT                        : out  std_logic_vector(2 downto 0);
--------------------- Shared Ports - Tile and PLL Ports --------------------
CLKIN_IN                                : in   std_logic;
GTPRESET_IN                             : in   std_logic;
PLLLKDET_OUT                            : out  std_logic;
REFCLKOUT_OUT                           : out  std_logic;
RESETDONE0_OUT                          : out  std_logic;
RESETDONE1_OUT                          : out  std_logic;
---------------- Transmit Ports - 8b10b Encoder Control Ports --------------
TXCHARDISPMODE0_IN                      : in   std_logic;
TXCHARDISPMODE1_IN                      : in   std_logic;
TXCHARDISPVAL0_IN                       : in   std_logic;
TXCHARDISPVAL1_IN                       : in   std_logic;
TXCHARISK0_IN                           : in   std_logic;
TXCHARISK1_IN                           : in   std_logic;
------------- Transmit Ports - TX Buffering and Phase Alignment ------------
TXBUFSTATUS0_OUT                        : out  std_logic_vector(1 downto 0);
TXBUFSTATUS1_OUT                        : out  std_logic_vector(1 downto 0);
------------------ Transmit Ports - TX Data Path interface -----------------
TXDATA0_IN                              : in   std_logic_vector(7 downto 0);
TXDATA1_IN                              : in   std_logic_vector(7 downto 0);
TXOUTCLK0_OUT                           : out  std_logic;
TXOUTCLK1_OUT                           : out  std_logic;
TXRESET0_IN                             : in   std_logic;
TXRESET1_IN                             : in   std_logic;
TXUSRCLK0_IN                            : in   std_logic;
TXUSRCLK1_IN                            : in   std_logic;
TXUSRCLK20_IN                           : in   std_logic;
TXUSRCLK21_IN                           : in   std_logic;
--------------- Transmit Ports - TX Driver and OOB signalling --------------
TXN0_OUT                                : out  std_logic;
TXN1_OUT                                : out  std_logic;
TXP0_OUT                                : out  std_logic;
TXP1_OUT                                : out  std_logic
);
end component;

signal i_cfg_adr_cnt                     : std_logic_vector(7 downto 0);

signal h_reg_ctrl                        : std_logic_vector(15 downto 0);
signal h_reg_tst0                        : std_logic_vector(15 downto 0);
signal h_reg_eth_cfg                     : TEthCfg;

signal i_eth_gctrl                       : std_logic_vector(31 downto 0);
signal g_eth_gt_refclkout                : std_logic;
signal i_eth_gt_plllkdet                 : std_logic;

signal i_eth_cfg                         : TEthCfg_GTCH;
signal i_eth_rxbuf_din                   : TBusUsrBUF_GTCH;
signal i_eth_rxbuf_wr                    : std_logic_vector(C_GTCH_COUNT_MAX-1 downto 0);
signal i_eth_rxbuf_full                  : std_logic_vector(C_GTCH_COUNT_MAX-1 downto 0);
signal i_eth_rxd_sof                     : std_logic_vector(C_GTCH_COUNT_MAX-1 downto 0);
signal i_eth_rxd_eof                     : std_logic_vector(C_GTCH_COUNT_MAX-1 downto 0);

signal i_eth_txbuf_dout                  : TBusUsrBUF_GTCH;
signal i_eth_txbuf_rd                    : std_logic_vector(C_GTCH_COUNT_MAX-1 downto 0);
signal i_eth_txbuf_empty                 : std_logic_vector(C_GTCH_COUNT_MAX-1 downto 0);
signal i_eth_txd_rdy                     : std_logic_vector(C_GTCH_COUNT_MAX-1 downto 0);


signal mac0_gtp_clk125_o                 : std_logic;
signal mac0_gtp_clk125                   : std_logic;

signal i_eth_main_tst_out                : std_logic_vector(31 downto 0);



--MAIN
begin


--//--------------------------------------------------
--//Конфигурирование модуля
--//--------------------------------------------------
--//Счетчик адреса регистров
process(p_in_cfg_rst,p_in_cfg_clk)
begin
  if p_in_cfg_rst='1' then
    i_cfg_adr_cnt<=(others=>'0');
  elsif p_in_cfg_clk'event and p_in_cfg_clk='1' then
    if p_in_cfg_adr_ld='1' then
      i_cfg_adr_cnt<=p_in_cfg_adr;
    else
      if p_in_cfg_adr_fifo='0' and (p_in_cfg_wd='1' or p_in_cfg_rd='1') then
        i_cfg_adr_cnt<=i_cfg_adr_cnt+1;
      end if;
    end if;
  end if;
end process;

--//Запись регистров
process(p_in_cfg_rst,p_in_cfg_clk)
begin
  if p_in_cfg_rst='1' then
    h_reg_ctrl<=(others=>'0');
    h_reg_tst0<=(others=>'0');

    h_reg_eth_cfg.usrctrl<=(others=>'0');
    for i in 0 to h_reg_eth_cfg.mac.dst'high loop
    h_reg_eth_cfg.mac.dst(i)<=(others=>'0');
    h_reg_eth_cfg.mac.src(i)<=(others=>'0');
    end loop;
    h_reg_eth_cfg.mac.lentype<=(others=>'0');

  elsif p_in_cfg_clk'event and p_in_cfg_clk='1' then
    if p_in_cfg_wd='1' then
        if    i_cfg_adr_cnt=CONV_STD_LOGIC_VECTOR(C_DSN_ETHG_REG_CTRL_L, i_cfg_adr_cnt'length)     then h_reg_ctrl<=p_in_cfg_txdata;
        elsif i_cfg_adr_cnt=CONV_STD_LOGIC_VECTOR(C_DSN_ETHG_REG_TST0, i_cfg_adr_cnt'length)       then h_reg_tst0<=p_in_cfg_txdata;

        elsif i_cfg_adr_cnt=CONV_STD_LOGIC_VECTOR(C_DSN_ETHG_REG_MAC_USRCTRL, i_cfg_adr_cnt'length)then h_reg_eth_cfg.usrctrl<=p_in_cfg_txdata;

        elsif i_cfg_adr_cnt=CONV_STD_LOGIC_VECTOR(C_DSN_ETHG_REG_MAC_PATRN0, i_cfg_adr_cnt'length) then h_reg_eth_cfg.mac.dst(0)<=p_in_cfg_txdata(7 downto 0);
                                                                                                        h_reg_eth_cfg.mac.dst(1)<=p_in_cfg_txdata(15 downto 8);
        elsif i_cfg_adr_cnt=CONV_STD_LOGIC_VECTOR(C_DSN_ETHG_REG_MAC_PATRN1, i_cfg_adr_cnt'length) then h_reg_eth_cfg.mac.dst(2)<=p_in_cfg_txdata(7 downto 0);
                                                                                                        h_reg_eth_cfg.mac.dst(3)<=p_in_cfg_txdata(15 downto 8);
        elsif i_cfg_adr_cnt=CONV_STD_LOGIC_VECTOR(C_DSN_ETHG_REG_MAC_PATRN2, i_cfg_adr_cnt'length) then h_reg_eth_cfg.mac.dst(4)<=p_in_cfg_txdata(7 downto 0);
                                                                                                        h_reg_eth_cfg.mac.dst(5)<=p_in_cfg_txdata(15 downto 8);

        elsif i_cfg_adr_cnt=CONV_STD_LOGIC_VECTOR(C_DSN_ETHG_REG_MAC_PATRN3, i_cfg_adr_cnt'length) then h_reg_eth_cfg.mac.src(0)<=p_in_cfg_txdata(7 downto 0);
                                                                                                        h_reg_eth_cfg.mac.src(1)<=p_in_cfg_txdata(15 downto 8);
        elsif i_cfg_adr_cnt=CONV_STD_LOGIC_VECTOR(C_DSN_ETHG_REG_MAC_PATRN4, i_cfg_adr_cnt'length) then h_reg_eth_cfg.mac.src(2)<=p_in_cfg_txdata(7 downto 0);
                                                                                                        h_reg_eth_cfg.mac.src(3)<=p_in_cfg_txdata(15 downto 8);
        elsif i_cfg_adr_cnt=CONV_STD_LOGIC_VECTOR(C_DSN_ETHG_REG_MAC_PATRN5, i_cfg_adr_cnt'length) then h_reg_eth_cfg.mac.src(4)<=p_in_cfg_txdata(7 downto 0);
                                                                                                        h_reg_eth_cfg.mac.src(5)<=p_in_cfg_txdata(15 downto 8);

        elsif i_cfg_adr_cnt=CONV_STD_LOGIC_VECTOR(C_DSN_ETHG_REG_MAC_PATRN6, i_cfg_adr_cnt'length) then h_reg_eth_cfg.mac.lentype<=p_in_cfg_txdata(15 downto 0);

        end if;
    end if;
  end if;
end process;

--//Чтение регистров
process(p_in_cfg_rst,p_in_cfg_clk)
begin
  if p_in_cfg_rst='1' then
    p_out_cfg_rxdata<=(others=>'0');
  elsif p_in_cfg_clk'event and p_in_cfg_clk='1' then
    if p_in_cfg_rd='1' then
        if    i_cfg_adr_cnt=CONV_STD_LOGIC_VECTOR(C_DSN_ETHG_REG_CTRL_L, i_cfg_adr_cnt'length)     then p_out_cfg_rxdata<=h_reg_ctrl;
        elsif i_cfg_adr_cnt=CONV_STD_LOGIC_VECTOR(C_DSN_ETHG_REG_TST0, i_cfg_adr_cnt'length)       then p_out_cfg_rxdata<=h_reg_tst0;

        elsif i_cfg_adr_cnt=CONV_STD_LOGIC_VECTOR(C_DSN_ETHG_REG_MAC_USRCTRL, i_cfg_adr_cnt'length)then p_out_cfg_rxdata<=h_reg_eth_cfg.usrctrl;

        elsif i_cfg_adr_cnt=CONV_STD_LOGIC_VECTOR(C_DSN_ETHG_REG_MAC_PATRN0, i_cfg_adr_cnt'length) then p_out_cfg_rxdata(7 downto 0) <=h_reg_eth_cfg.mac.dst(0);
                                                                                                        p_out_cfg_rxdata(15 downto 8)<=h_reg_eth_cfg.mac.dst(1);
        elsif i_cfg_adr_cnt=CONV_STD_LOGIC_VECTOR(C_DSN_ETHG_REG_MAC_PATRN1, i_cfg_adr_cnt'length) then p_out_cfg_rxdata(7 downto 0) <=h_reg_eth_cfg.mac.dst(2);
                                                                                                        p_out_cfg_rxdata(15 downto 8)<=h_reg_eth_cfg.mac.dst(3);
        elsif i_cfg_adr_cnt=CONV_STD_LOGIC_VECTOR(C_DSN_ETHG_REG_MAC_PATRN2, i_cfg_adr_cnt'length) then p_out_cfg_rxdata(7 downto 0) <=h_reg_eth_cfg.mac.dst(4);
                                                                                                        p_out_cfg_rxdata(15 downto 8)<=h_reg_eth_cfg.mac.dst(5);

        elsif i_cfg_adr_cnt=CONV_STD_LOGIC_VECTOR(C_DSN_ETHG_REG_MAC_PATRN3, i_cfg_adr_cnt'length) then p_out_cfg_rxdata(7 downto 0) <=h_reg_eth_cfg.mac.src(0);
                                                                                                        p_out_cfg_rxdata(15 downto 8)<=h_reg_eth_cfg.mac.src(1);
        elsif i_cfg_adr_cnt=CONV_STD_LOGIC_VECTOR(C_DSN_ETHG_REG_MAC_PATRN4, i_cfg_adr_cnt'length) then p_out_cfg_rxdata(7 downto 0) <=h_reg_eth_cfg.mac.src(2);
                                                                                                        p_out_cfg_rxdata(15 downto 8)<=h_reg_eth_cfg.mac.src(3);
        elsif i_cfg_adr_cnt=CONV_STD_LOGIC_VECTOR(C_DSN_ETHG_REG_MAC_PATRN5, i_cfg_adr_cnt'length) then p_out_cfg_rxdata(7 downto 0) <=h_reg_eth_cfg.mac.src(4);
                                                                                                        p_out_cfg_rxdata(15 downto 8)<=h_reg_eth_cfg.mac.src(5);

        elsif i_cfg_adr_cnt=CONV_STD_LOGIC_VECTOR(C_DSN_ETHG_REG_MAC_PATRN6, i_cfg_adr_cnt'length) then p_out_cfg_rxdata(15 downto 0)<=h_reg_eth_cfg.mac.lentype;

        end if;
    end if;
  end if;
end process;


--/-----------------------------------
--/Статусы
--/-----------------------------------
p_out_eth_rdy        <=p_in_sfp_sd;
p_out_eth_error      <='0';
p_out_eth_gt_plllkdet<=i_eth_gt_plllkdet;

p_out_sfp_tx_dis <= h_reg_ctrl(C_DSN_ETHG_REG_CTRL_SFP_TX_DISABLE_BIT);



--/-----------------------------------
--/
--/-----------------------------------
gen_use_on : if strcmp(G_MODULE_USE,"ON") generate

gen_dbg_off : if strcmp(G_DBG,"OFF") generate
p_out_tst(31 downto 0)<=(others=>'0');
end generate gen_dbg_off;

gen_dbg_on : if strcmp(G_DBG,"ON") generate
ltstout:process(p_in_rst,g_eth_gt_refclkout)
begin
  if p_in_rst='1' then
    p_out_tst<=(others=>'0');
  elsif g_eth_gt_refclkout'event and g_eth_gt_refclkout='1' then
    p_out_tst(0)<=i_eth_main_tst_out(0);
  end if;
end process ltstout;

end generate gen_dbg_on;


p_out_eth_gt_refclkout<=g_eth_gt_refclkout;

p_out_eth_rxbuf_din<=i_eth_rxbuf_din(0);
p_out_eth_rxbuf_wr<=i_eth_rxbuf_wr(0);
p_out_eth_rxd_sof<=i_eth_rxd_sof(0);
p_out_eth_rxd_eof<=i_eth_rxd_eof(0);

i_eth_rxbuf_full(0)<=p_in_eth_rxbuf_full;
i_eth_rxbuf_full(1)<=p_in_eth_rxbuf_full;

i_eth_txbuf_dout(0)<=p_in_eth_txbuf_dout;
i_eth_txbuf_dout(1)<=p_in_eth_txbuf_dout;
p_out_eth_txbuf_rd<=i_eth_txbuf_rd(0);

i_eth_txbuf_empty(0)<=p_in_eth_txbuf_empty;
i_eth_txbuf_empty(1)<=p_in_eth_txbuf_empty;
i_eth_txd_rdy(0)<=p_in_eth_txd_rdy;
i_eth_txd_rdy(1)<=p_in_eth_txd_rdy;


i_eth_cfg(0)<=h_reg_eth_cfg;
i_eth_cfg(1)<=h_reg_eth_cfg;

i_eth_gctrl(30 downto 0)<=EXT(h_reg_ctrl, 31);
i_eth_gctrl(31)<=p_in_eth_gt_drpclk;


--//#############################################################
--//модуль управления Ethernet MAC
--//#############################################################
m_eth_main : eth_main
generic map(
G_DBG => G_DBG,
G_SIM => G_SIM
)
port map
(
--//Управление
p_in_gctrl             => i_eth_gctrl,

--//------------------------------------
--//Eth - Channel
--//------------------------------------
--//настройка канала
p_in_eth_cfg           => i_eth_cfg,

--//Связь с RXBUF
p_out_eth_rxbuf_din    => i_eth_rxbuf_din,
p_out_eth_rxbuf_wr     => i_eth_rxbuf_wr,
p_in_eth_rxbuf_full    => i_eth_rxbuf_full,
p_out_eth_rxd_sof      => i_eth_rxd_sof,
p_out_eth_rxd_eof      => i_eth_rxd_eof,

--//Связь с TXBUF
p_in_eth_txbuf_dout    => i_eth_txbuf_dout,
p_out_eth_txbuf_rd     => i_eth_txbuf_rd,
p_in_eth_txbuf_empty   => i_eth_txbuf_empty,
p_in_eth_txd_rdy       => i_eth_txd_rdy,

--------------------------------------------------
--ETH Driver
--------------------------------------------------
p_out_eth_gt_txp       => p_out_eth_gt_txp,
p_out_eth_gt_txn       => p_out_eth_gt_txn,
p_in_eth_gt_rxp        => p_in_eth_gt_rxp,
p_in_eth_gt_rxn        => p_in_eth_gt_rxn,

p_in_eth_gt_refclk     => p_in_eth_gt_refclk,
p_out_eth_gt_refclkout => g_eth_gt_refclkout,

p_out_eth_gt_plllkdet  => i_eth_gt_plllkdet,

--------------------------------------------------
--Технологические сигналы
--------------------------------------------------
p_in_tst               => "00000000000000000000000000000000",
p_out_tst              => i_eth_main_tst_out,

--//------------------------------------
--//SYSTEM
--//------------------------------------
p_in_rst               => p_in_rst
);

end generate gen_use_on;



--/-----------------------------------
--/
--/-----------------------------------
gen_use_off : if strcmp(G_MODULE_USE,"OFF") generate

p_out_tst<=(others=>'0');

p_out_eth_gt_refclkout<=mac0_gtp_clk125;

p_out_eth_rxbuf_din<=p_in_eth_txbuf_dout;
p_out_eth_rxbuf_wr<= not p_in_eth_txbuf_empty and not p_in_eth_rxbuf_full;
p_out_eth_rxd_sof <=p_in_eth_txd_rdy;
p_out_eth_rxd_eof <=p_in_eth_txd_rdy;

p_out_eth_txbuf_rd  <= not p_in_eth_txbuf_empty;


bufg_clk125 : BUFG port map (I => mac0_gtp_clk125_o, O => mac0_gtp_clk125);

i_eth_gctrl(30 downto 0)<=EXT(h_reg_ctrl, 31);
i_eth_gctrl(31)<=p_in_eth_gt_drpclk;

m_gtp_dual_clk : ROCKETIO_WRAPPER_GTP_TILE
generic map
(
-- Simulation attributes
TILE_SIM_GTPRESET_SPEEDUP   => 1,
TILE_SIM_PLL_PERDIV2        => x"190",

-- Channel bonding attributes
TILE_CHAN_BOND_MODE_0        => "OFF",
TILE_CHAN_BOND_LEVEL_0       => 0,

TILE_CHAN_BOND_MODE_1        => "OFF",
TILE_CHAN_BOND_LEVEL_1       => 0
)
port map
(
p_in_drp_ctrl                  => i_eth_gctrl,

------------------------ Loopback and Powerdown Ports ----------------------
LOOPBACK0_IN                            => "000",
LOOPBACK1_IN                            => "000",
----------------------- Receive Ports - 8b10b Decoder ----------------------
RXCHARISCOMMA0_OUT                      => open,
RXCHARISCOMMA1_OUT                      => open,
RXCHARISK0_OUT                          => open,
RXCHARISK1_OUT                          => open,
RXDISPERR0_OUT                          => open,
RXDISPERR1_OUT                          => open,
RXNOTINTABLE0_OUT                       => open,
RXNOTINTABLE1_OUT                       => open,
RXRUNDISP0_OUT                          => open,
RXRUNDISP1_OUT                          => open,
------------------- Receive Ports - Clock Correction Ports -----------------
RXCLKCORCNT0_OUT                        => open,
RXCLKCORCNT1_OUT                        => open,
--------------- Receive Ports - Comma Detection and Alignment --------------
RXENMCOMMAALIGN0_IN                     => '0',
RXENMCOMMAALIGN1_IN                     => '0',
RXENPCOMMAALIGN0_IN                     => '0',
RXENPCOMMAALIGN1_IN                     => '0',
------------------- Receive Ports - RX Data Path interface -----------------
RXDATA0_OUT                             => open,
RXDATA1_OUT                             => open,
RXRECCLK0_OUT                           => open,
RXRECCLK1_OUT                           => open,
RXRESET0_IN                             => '0',
RXRESET1_IN                             => '0',
RXUSRCLK0_IN                            => '0',
RXUSRCLK1_IN                            => '0',
RXUSRCLK20_IN                           => '0',
RXUSRCLK21_IN                           => '0',
------- Receive Ports - RX Driver,OOB signalling,Coupling and Eq.,CDR ------
RXELECIDLE0_OUT                         => open,
RXELECIDLE1_OUT                         => open,
RXN0_IN                                 => p_in_eth_gt_rxn(0),
RXN1_IN                                 => p_in_eth_gt_rxn(1),
RXP0_IN                                 => p_in_eth_gt_rxp(0),
RXP1_IN                                 => p_in_eth_gt_rxp(1),
-------- Receive Ports - RX Elastic Buffer and Phase Alignment Ports -------
RXBUFRESET0_IN                          => '0',
RXBUFRESET1_IN                          => '0',
RXBUFSTATUS0_OUT                        => open,
RXBUFSTATUS1_OUT                        => open,
--------------------- Shared Ports - Tile and PLL Ports --------------------
CLKIN_IN                                => p_in_eth_gt_refclk,
GTPRESET_IN                             => p_in_rst,
PLLLKDET_OUT                            => i_eth_gt_plllkdet,
REFCLKOUT_OUT                           => mac0_gtp_clk125_o,
RESETDONE0_OUT                          => open,
RESETDONE1_OUT                          => open,
---------------- Transmit Ports - 8b10b Encoder Control Ports --------------
TXCHARDISPMODE0_IN                      => '0',
TXCHARDISPMODE1_IN                      => '0',
TXCHARDISPVAL0_IN                       => '0',
TXCHARDISPVAL1_IN                       => '0',
TXCHARISK0_IN                           => '0',
TXCHARISK1_IN                           => '0',
------------- Transmit Ports - TX Buffering and Phase Alignment ------------
TXBUFSTATUS0_OUT                        => open,
TXBUFSTATUS1_OUT                        => open,
------------------ Transmit Ports - TX Data Path interface -----------------
TXDATA0_IN                              => "00000000",
TXDATA1_IN                              => "00000000",
TXOUTCLK0_OUT                           => open,
TXOUTCLK1_OUT                           => open,
TXRESET0_IN                             => '0',
TXRESET1_IN                             => '0',
TXUSRCLK0_IN                            => '0',
TXUSRCLK1_IN                            => '0',
TXUSRCLK20_IN                           => '0',
TXUSRCLK21_IN                           => '0',
--------------- Transmit Ports - TX Driver and OOB signalling --------------
TXN0_OUT                                => p_out_eth_gt_txn(0),
TXN1_OUT                                => p_out_eth_gt_txn(1),
TXP0_OUT                                => p_out_eth_gt_txp(0),
TXP1_OUT                                => p_out_eth_gt_txp(1)
);


end generate gen_use_off;

--END MAIN
end behavioral;
