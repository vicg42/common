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
generic(
G_MODULE_USE : string:="ON";
G_DBG        : string:="OFF";
G_SIM        : string:="OFF"
);
port(
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
--p_in_eth_txd_rdy       : in   std_logic;

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

component mclk_gtp_wrap
generic(
G_SIM : string:="OFF"
);
port(
p_out_txn : out   std_logic_vector(1 downto 0);
p_out_txp : out   std_logic_vector(1 downto 0);
p_in_rxn  : in    std_logic_vector(1 downto 0);
p_in_rxp  : in    std_logic_vector(1 downto 0);
clkin     : in    std_logic;
clkout    : out   std_logic
);
end component;

signal i_cfg_adr_cnt                     : std_logic_vector(7 downto 0);

signal h_reg_ctrl                        : std_logic_vector(15 downto 0);
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
--signal i_eth_txd_rdy                     : std_logic_vector(C_GTCH_COUNT_MAX-1 downto 0);


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

    h_reg_eth_cfg.usrctrl<=(others=>'0');
    for i in 0 to h_reg_eth_cfg.mac.dst'high loop
    h_reg_eth_cfg.mac.dst(i)<=(others=>'0');
    h_reg_eth_cfg.mac.src(i)<=(others=>'0');
    end loop;
    h_reg_eth_cfg.mac.lentype<=(others=>'0');

  elsif p_in_cfg_clk'event and p_in_cfg_clk='1' then
    if p_in_cfg_wd='1' then
        if    i_cfg_adr_cnt=CONV_STD_LOGIC_VECTOR(C_ETH_REG_MAC_PATRN0, i_cfg_adr_cnt'length) then h_reg_eth_cfg.mac.dst(0)<=p_in_cfg_txdata(7 downto 0);
                                                                                                   h_reg_eth_cfg.mac.dst(1)<=p_in_cfg_txdata(15 downto 8);
        elsif i_cfg_adr_cnt=CONV_STD_LOGIC_VECTOR(C_ETH_REG_MAC_PATRN1, i_cfg_adr_cnt'length) then h_reg_eth_cfg.mac.dst(2)<=p_in_cfg_txdata(7 downto 0);
                                                                                                   h_reg_eth_cfg.mac.dst(3)<=p_in_cfg_txdata(15 downto 8);
        elsif i_cfg_adr_cnt=CONV_STD_LOGIC_VECTOR(C_ETH_REG_MAC_PATRN2, i_cfg_adr_cnt'length) then h_reg_eth_cfg.mac.dst(4)<=p_in_cfg_txdata(7 downto 0);
                                                                                                   h_reg_eth_cfg.mac.dst(5)<=p_in_cfg_txdata(15 downto 8);

        elsif i_cfg_adr_cnt=CONV_STD_LOGIC_VECTOR(C_ETH_REG_MAC_PATRN3, i_cfg_adr_cnt'length) then h_reg_eth_cfg.mac.src(0)<=p_in_cfg_txdata(7 downto 0);
                                                                                                   h_reg_eth_cfg.mac.src(1)<=p_in_cfg_txdata(15 downto 8);
        elsif i_cfg_adr_cnt=CONV_STD_LOGIC_VECTOR(C_ETH_REG_MAC_PATRN4, i_cfg_adr_cnt'length) then h_reg_eth_cfg.mac.src(2)<=p_in_cfg_txdata(7 downto 0);
                                                                                                   h_reg_eth_cfg.mac.src(3)<=p_in_cfg_txdata(15 downto 8);
        elsif i_cfg_adr_cnt=CONV_STD_LOGIC_VECTOR(C_ETH_REG_MAC_PATRN5, i_cfg_adr_cnt'length) then h_reg_eth_cfg.mac.src(4)<=p_in_cfg_txdata(7 downto 0);
                                                                                                   h_reg_eth_cfg.mac.src(5)<=p_in_cfg_txdata(15 downto 8);

--        elsif i_cfg_adr_cnt=CONV_STD_LOGIC_VECTOR(C_ETH_REG_MAC_PATRN6, i_cfg_adr_cnt'length) then h_reg_eth_cfg.mac.lentype<=p_in_cfg_txdata(15 downto 0);

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
        if    i_cfg_adr_cnt=CONV_STD_LOGIC_VECTOR(C_ETH_REG_MAC_PATRN0, i_cfg_adr_cnt'length) then p_out_cfg_rxdata(7 downto 0) <=h_reg_eth_cfg.mac.dst(0);
                                                                                                   p_out_cfg_rxdata(15 downto 8)<=h_reg_eth_cfg.mac.dst(1);
        elsif i_cfg_adr_cnt=CONV_STD_LOGIC_VECTOR(C_ETH_REG_MAC_PATRN1, i_cfg_adr_cnt'length) then p_out_cfg_rxdata(7 downto 0) <=h_reg_eth_cfg.mac.dst(2);
                                                                                                   p_out_cfg_rxdata(15 downto 8)<=h_reg_eth_cfg.mac.dst(3);
        elsif i_cfg_adr_cnt=CONV_STD_LOGIC_VECTOR(C_ETH_REG_MAC_PATRN2, i_cfg_adr_cnt'length) then p_out_cfg_rxdata(7 downto 0) <=h_reg_eth_cfg.mac.dst(4);
                                                                                                   p_out_cfg_rxdata(15 downto 8)<=h_reg_eth_cfg.mac.dst(5);

        elsif i_cfg_adr_cnt=CONV_STD_LOGIC_VECTOR(C_ETH_REG_MAC_PATRN3, i_cfg_adr_cnt'length) then p_out_cfg_rxdata(7 downto 0) <=h_reg_eth_cfg.mac.src(0);
                                                                                                   p_out_cfg_rxdata(15 downto 8)<=h_reg_eth_cfg.mac.src(1);
        elsif i_cfg_adr_cnt=CONV_STD_LOGIC_VECTOR(C_ETH_REG_MAC_PATRN4, i_cfg_adr_cnt'length) then p_out_cfg_rxdata(7 downto 0) <=h_reg_eth_cfg.mac.src(2);
                                                                                                   p_out_cfg_rxdata(15 downto 8)<=h_reg_eth_cfg.mac.src(3);
        elsif i_cfg_adr_cnt=CONV_STD_LOGIC_VECTOR(C_ETH_REG_MAC_PATRN5, i_cfg_adr_cnt'length) then p_out_cfg_rxdata(7 downto 0) <=h_reg_eth_cfg.mac.src(4);
                                                                                                   p_out_cfg_rxdata(15 downto 8)<=h_reg_eth_cfg.mac.src(5);

--        elsif i_cfg_adr_cnt=CONV_STD_LOGIC_VECTOR(C_ETH_REG_MAC_PATRN6, i_cfg_adr_cnt'length) then p_out_cfg_rxdata(15 downto 0)<=h_reg_eth_cfg.mac.lentype;

        end if;
    end if;
  end if;
end process;


--/-----------------------------------
--/Статусы
--/-----------------------------------
p_out_eth_rdy        <=i_eth_gt_plllkdet;--//Модуль готов к работе
p_out_eth_error      <=p_in_sfp_sd;      --//Carrier detect - Есть связь.
p_out_eth_gt_plllkdet<=i_eth_gt_plllkdet;

p_out_sfp_tx_dis <= '0';



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
--i_eth_txd_rdy(0)<=p_in_eth_txd_rdy;
--i_eth_txd_rdy(1)<=p_in_eth_txd_rdy;


gen_cfg_eth : for i in 0 to i_eth_cfg'high generate
process(p_in_rst,g_eth_gt_refclkout)
begin
  if p_in_rst='1' then
    i_eth_cfg(i).usrctrl<=(others=>'0');
    for y in 0 to i_eth_cfg(i).mac.dst'high loop
    i_eth_cfg(i).mac.dst(y)<=(others=>'0');
    i_eth_cfg(i).mac.src(y)<=(others=>'0');
    end loop;
    i_eth_cfg(i).mac.lentype<=(others=>'0');
  elsif g_eth_gt_refclkout'event and g_eth_gt_refclkout='1' then
    i_eth_cfg(i)<=h_reg_eth_cfg;
  end if;
end process;
end generate gen_cfg_eth;

--i_eth_gctrl(10..8) : V5GT_CLKIN_MUX_BIT            --//Значение для перепрограм. мультиплексора CLKIN RocketIO ETH
--i_eth_gctrl(12..11): V5GT_SOUTH_MUX_VAL_BIT(12..11)--//Значение для перепрограм. мультиплексора CLKSOUTH RocketIO ETH
--i_eth_gctrl(13)    : V5GT_CLKIN_MUX_CNG_BIT(13)    --//1- перепрограммирование мультиплексора CLKIN RocketIO ETH
--i_eth_gctrl(14)    : V5GT_SOUTH_MUX_CNG_BIT(14)    --//1- перепрограммирование мультиплексора CLKSOUTH RocketIO ETH
--i_eth_gctrl(15)    : V5GT_NORTH_MUX_CNG_BIT(15)    --//1- перепрограммирование мультиплексора CLKNORTH RocketIO ETH
i_eth_gctrl(10 downto 8) <=CONV_STD_LOGIC_VECTOR(16#07#, 3);
i_eth_gctrl(12 downto 11)<=CONV_STD_LOGIC_VECTOR(16#00#, 2);
i_eth_gctrl(15 downto 13)<=CONV_STD_LOGIC_VECTOR(16#01#, 3);
i_eth_gctrl(30 downto 16)<=(others=>'0');
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
--p_in_eth_txd_rdy       => i_eth_txd_rdy,

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
p_out_eth_rxd_sof <='0';--p_in_eth_txd_rdy;
p_out_eth_rxd_eof <='0';--p_in_eth_txd_rdy;

p_out_eth_txbuf_rd  <= not p_in_eth_txbuf_empty;


bufg_clk125 : BUFG port map (I => mac0_gtp_clk125_o, O => mac0_gtp_clk125);

i_eth_gt_plllkdet<='0';

m_gtp_dual_clk : mclk_gtp_wrap
generic map(
G_SIM => G_SIM
)
port map(
p_out_txn => p_out_eth_gt_txn,
p_out_txp => p_out_eth_gt_txp,
p_in_rxn  => p_in_eth_gt_rxn,
p_in_rxp  => p_in_eth_gt_rxp,
clkin     => p_in_eth_gt_refclk,
clkout    => mac0_gtp_clk125_o
);



end generate gen_use_off;

--END MAIN
end behavioral;
