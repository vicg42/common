-------------------------------------------------------------------------
-- Company     : Linkos
-- Engineer    : Golovachenko Victor
--
-- Create Date : 18.09.2012 9:35:52
-- Module Name : ethphy_test_main
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
use work.prj_def.all;
--use work.cfgdev_pkg.all;
use work.eth_phypin_pkg.all;
use work.eth_pkg.all;
use work.dsn_eth_pkg.all;

entity ethphy_test_main is
generic(
G_SIM      : string:="OFF"
);
port(
--------------------------------------------------
--Технологический порт
--------------------------------------------------
pin_out_led       : out   std_logic_vector(7 downto 0);
pin_in_btn_N      : in    std_logic;

--------------------------------------------------
--ETH
--------------------------------------------------
pin_out_ethphy    : out   TEthPhyPinOUT;
pin_in_ethphy     : in    TEthPhyPinIN;
pin_inout_ethphy_mdio : inout std_logic;
pin_out_ethphy_mdc    : out   std_logic;
pin_out_ethphy_rst    : out   std_logic
);
end entity;

architecture struct of ethphy_test_main is

component host_ethg_txfifo
port(
din         : IN  std_logic_vector(31 downto 0);
wr_en       : IN  std_logic;
wr_clk      : IN  std_logic;

dout        : OUT std_logic_vector(31 downto 0);
rd_en       : IN  std_logic;
rd_clk      : IN  std_logic;

empty       : OUT std_logic;
full        : OUT std_logic;

rst         : IN  std_logic
);
end component;

component fpga_test_01
generic(
G_BLINK_T05   : integer:=10#125#; -- 1/2 периода мигания светодиода.(время в ms)
G_CLK_T05us   : integer:=10#1000# -- кол-во периодов частоты порта p_in_clk
                                  -- укладывающиес_ в 1/2 периода 1us
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

component eth_gt_clkbuf is
port(
p_in_ethphy : in    TEthPhyPinIN;
p_out_clk   : out   std_logic_vector(1 downto 0)
);
end component;

component mclk_gtp_wrap
generic(
G_SIM  : string:="OFF"
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

type TEth_cfg_fsm is (
S_CFG_ETH_START,
S_CFG_ETH_MAC_DST0,
S_CFG_ETH_MAC_DST1,
S_CFG_ETH_MAC_DST2,
S_CFG_ETH_MAC_SRC0,
S_CFG_ETH_MAC_SRC1,
S_CFG_ETH_MAC_SRC2,
S_CFG_ETH_DONE
);
signal fsm_ethcfg_cs: TEth_cfg_fsm;

type TUsrpkt_tx_fsm is (
S_USR_PKT_TXDLY,
S_USR_PKT_TX0,
S_USR_PKT_TX1
);
signal fsm_usrpkt_tx_cs: TUsrpkt_tx_fsm;

signal i_sys_rst_cnt                   : std_logic_vector(5 downto 0):=(others=>'0');
signal i_sys_rst                       : std_logic;
signal i_usr_rst                       : std_logic;

signal i_eth_cfg_radr                  : std_logic_vector(7 downto 0);
signal i_eth_cfg_radr_ld               : std_logic;
signal i_eth_cfg_radr_fifo             : std_logic;
signal i_eth_cfg_wr                    : std_logic;
signal i_eth_cfg_rd                    : std_logic;
signal i_eth_cfg_txd                   : std_logic_vector(15 downto 0);
signal i_eth_cfg_rxd                   : std_logic_vector(15 downto 0);

signal i_eth_gt_txp                    : std_logic_vector(1 downto 0);
signal i_eth_gt_txn                    : std_logic_vector(1 downto 0);
signal i_eth_gt_rxn                    : std_logic_vector(1 downto 0);
signal i_eth_gt_rxp                    : std_logic_vector(1 downto 0);
signal i_eth_gt_refclk125_in           : std_logic_vector(1 downto 0);
signal i_eth_gt_refclk125_out          : std_logic;

signal i_eth_out                       : TEthOUTs;
signal i_eth_in                        : TEthINs;
signal i_ethphy_out                    : TEthPhyOUT;
signal i_ethphy_in                     : TEthPhyIN;
signal dbg_eth_out                     : TEthDBG;
signal i_eth_tst_out                   : std_logic_vector(31 downto 0);
signal i_eth_cfg_done                  : std_logic;

signal i_eth_txpkt_dcnt                : std_logic_vector(15 downto 0);
signal i_eth_txpkt_d                   : std_logic_vector(31 downto 0);
signal i_eth_txpkt_wr                  : std_logic;
signal i_eth_txpkt_len                 : std_logic_vector(15 downto 0);
signal i_eth_txpkt_tx_dlycnt           : std_logic_vector(15 downto 0);

signal i_t1ms                          : std_logic;
signal i_test01_led                    : std_logic;
signal i_mnl_rst                       : std_logic;

--
-- If the synthesizer replicates an asynchronous reset signal due high fanout,
-- this can prevent flip-flops being mapped into IOBs. We set the maximum
-- fanout for such nets to a high enough value that replication never occurs.
--
attribute keep : string;
attribute keep of i_ethphy_out : signal is "true";


--//MAIN
begin

--***********************************************************
--RESET
--***********************************************************
process(i_ethphy_out)
begin
  if i_ethphy_out.clk'event and i_ethphy_out.clk = '1' then
    if i_sys_rst_cnt(i_sys_rst_cnt'high) = '0' then
      i_sys_rst_cnt <= i_sys_rst_cnt + 1;
    end if;
  end if;
end process;

i_sys_rst <= i_sys_rst_cnt(i_sys_rst_cnt'high - 1);


--***********************************************************
--Установка частот
--***********************************************************
ibuf_eth_gt_refclk : eth_gt_clkbuf
port map(
p_in_ethphy => pin_in_ethphy,
p_out_clk   => i_eth_gt_refclk125_in
);

----//Только для SGMII
--i_eth_gt_refclk125_out<=i_eth_gt_refclk125_in(0);

--//Только для GMII/RGMII
pin_out_ethphy.fiber.txp <= i_eth_gt_txp(pin_out_ethphy.fiber.txp'range);
pin_out_ethphy.fiber.txn <= i_eth_gt_txn(pin_out_ethphy.fiber.txn'range);

i_eth_gt_rxn <= EXT(pin_in_ethphy.fiber.rxn, i_eth_gt_rxp'length);
i_eth_gt_rxp <= EXT(pin_in_ethphy.fiber.rxp, i_eth_gt_rxp'length);

m_gt_clk : mclk_gtp_wrap
generic map(
G_SIM => G_SIM
)
port map(
p_out_txn => i_eth_gt_txn,
p_out_txp => i_eth_gt_txp,
p_in_rxn  => i_eth_gt_rxn,
p_in_rxp  => i_eth_gt_rxp,
clkin     => i_eth_gt_refclk125_in(0),
clkout    => i_eth_gt_refclk125_out
);


--***********************************************************
--Проект Ethernet - dsn_eth.vhd
--***********************************************************
pin_out_ethphy.rgmii(0).tx_ctl<=i_ethphy_out.pin.rgmii(0).tx_ctl;
pin_out_ethphy.rgmii(0).txc   <=i_ethphy_out.pin.rgmii(0).txc;
pin_out_ethphy.rgmii(0).txd   <=i_ethphy_out.pin.rgmii(0).txd;
i_ethphy_in.pin.rgmii(0)<=pin_in_ethphy.rgmii(0);

--pin_out_ethphy.gmii(0).tx_er <=i_ethphy_out.pin.gmii(0).tx_er;
--pin_out_ethphy.gmii(0).tx_en <=i_ethphy_out.pin.gmii(0).tx_en;
--pin_out_ethphy.gmii(0).txc   <=i_ethphy_out.pin.gmii(0).txc;
--pin_out_ethphy.gmii(0).txd   <=i_ethphy_out.pin.gmii(0).txd;
--i_ethphy_in.pin.gmii(0)<=pin_in_ethphy.gmii(0);

--pin_out_ethphy.sgmii.txp <=i_ethphy_out.pin.sgmii.txp;
--pin_out_ethphy.sgmii.txn <=i_ethphy_out.pin.sgmii.txn;
--i_ethphy_in.pin.sgmii.rxp<=pin_in_ethphy.sgmii.rxp;
--i_ethphy_in.pin.sgmii.rxn<=pin_in_ethphy.sgmii.rxn;

i_ethphy_in.clk<=i_eth_gt_refclk125_out;

pin_out_ethphy_rst<=not i_ethphy_out.rst;
pin_inout_ethphy_mdio<=i_ethphy_out.mdio when i_ethphy_out.mdio_t='1' else 'Z';
pin_out_ethphy_mdc<=i_ethphy_out.mdc;
i_ethphy_in.mdio<=pin_inout_ethphy_mdio;

m_eth : dsn_eth
generic map(
G_ETH.gtch_count_max  => C_PCFG_ETH_GTCH_COUNT_MAX,
G_ETH.usrbuf_dwidth   => 32,
G_ETH.phy_dwidth      => C_PCFG_ETH_PHY_DWIDTH,
G_ETH.phy_select      => 0,--C_PCFG_ETH_PHY_SEL,
G_ETH.mac_length_swap => 0,--1/0 Поле Length/Type первый мл./ст. байт (0 - по стандарту!!! 1 - как в проекте Вереск)
G_MODULE_USE => C_PCFG_ETH_USE,
G_DBG        => C_PCFG_ETH_DBG,
G_SIM        => G_SIM
)
port map(
-------------------------------
--Конфигурирование
-------------------------------
p_in_cfg_clk      => i_ethphy_out.clk,

p_in_cfg_adr      => i_eth_cfg_radr(7 downto 0),
p_in_cfg_adr_ld   => i_eth_cfg_radr_ld,
p_in_cfg_adr_fifo => i_eth_cfg_radr_fifo,

p_in_cfg_txdata   => i_eth_cfg_txd,
p_in_cfg_wd       => i_eth_cfg_wr,

p_out_cfg_rxdata  => open,
p_in_cfg_rd       => '0',

p_in_cfg_done     => '0',
p_in_cfg_rst      => i_sys_rst,

-------------------------------
--Связь с UsrBuf
-------------------------------
p_out_eth         => i_eth_out,
p_in_eth          => i_eth_in,

-------------------------------
--ETH
-------------------------------
p_out_ethphy      => i_ethphy_out,
p_in_ethphy       => i_ethphy_in,

-------------------------------
--Технологический
-------------------------------
p_out_dbg         => dbg_eth_out,
p_in_tst          => i_eth_tst_out,
p_out_tst         => open,

-------------------------------
--System
-------------------------------
p_in_rst          => i_sys_rst
);


--***********************************************************
--Назначаем MAC (DST/SCR) для модуля m_eth1
--***********************************************************
process(i_sys_rst,i_ethphy_out)
begin
  if i_sys_rst='1' then
    fsm_ethcfg_cs<=S_CFG_ETH_START;

    i_eth_cfg_radr<=(others=>'0');
    i_eth_cfg_radr_ld<='0';
    i_eth_cfg_radr_fifo<='0';

    i_eth_cfg_txd<=(others=>'0');
    i_eth_cfg_wr<='0';
    i_eth_cfg_done<='0';

  elsif i_ethphy_out.clk'event and i_ethphy_out.clk='1' then

    case fsm_ethcfg_cs is

      --
      when S_CFG_ETH_START =>

        if i_ethphy_out.rdy='1' then
        i_eth_cfg_radr_ld<='1';
        i_eth_cfg_radr_fifo<='0';
        i_eth_cfg_wr<='0';
        i_eth_cfg_radr<=CONV_STD_LOGIC_VECTOR(C_ETH_REG_MAC_PATRN0, i_eth_cfg_radr'length);
        fsm_ethcfg_cs<=S_CFG_ETH_MAC_DST0;
        end if;

      --Set MAC/DST
      when S_CFG_ETH_MAC_DST0 =>
        i_eth_cfg_radr_ld<='0';
        i_eth_cfg_radr_fifo<='0';
        i_eth_cfg_wr<='1';
        i_eth_cfg_txd(8*1-1 downto 8*0)<=CONV_STD_LOGIC_VECTOR(16#90#, 8);
        i_eth_cfg_txd(8*2-1 downto 8*1)<=CONV_STD_LOGIC_VECTOR(16#E6#, 8);
        fsm_ethcfg_cs<=S_CFG_ETH_MAC_DST1;

      when S_CFG_ETH_MAC_DST1 =>
        i_eth_cfg_txd(8*1-1 downto 8*0)<=CONV_STD_LOGIC_VECTOR(16#BA#, 8);
        i_eth_cfg_txd(8*2-1 downto 8*1)<=CONV_STD_LOGIC_VECTOR(16#CE#, 8);
        fsm_ethcfg_cs<=S_CFG_ETH_MAC_DST2;

      when S_CFG_ETH_MAC_DST2 =>
        i_eth_cfg_txd(8*1-1 downto 8*0)<=CONV_STD_LOGIC_VECTOR(16#31#, 8);
        i_eth_cfg_txd(8*2-1 downto 8*1)<=CONV_STD_LOGIC_VECTOR(16#DA#, 8);
        fsm_ethcfg_cs<=S_CFG_ETH_MAC_SRC0;

      --Set MAC/SRC
      when S_CFG_ETH_MAC_SRC0 =>
        i_eth_cfg_txd(8*1-1 downto 8*0)<=CONV_STD_LOGIC_VECTOR(16#A0#, 8);
        i_eth_cfg_txd(8*2-1 downto 8*1)<=CONV_STD_LOGIC_VECTOR(16#A1#, 8);
        fsm_ethcfg_cs<=S_CFG_ETH_MAC_SRC1;

      when S_CFG_ETH_MAC_SRC1 =>
        i_eth_cfg_txd(8*1-1 downto 8*0)<=CONV_STD_LOGIC_VECTOR(16#A2#, 8);
        i_eth_cfg_txd(8*2-1 downto 8*1)<=CONV_STD_LOGIC_VECTOR(16#A3#, 8);
        fsm_ethcfg_cs<=S_CFG_ETH_MAC_SRC2;

      when S_CFG_ETH_MAC_SRC2 =>
        i_eth_cfg_txd(8*1-1 downto 8*0)<=CONV_STD_LOGIC_VECTOR(16#A4#, 8);
        i_eth_cfg_txd(8*2-1 downto 8*1)<=CONV_STD_LOGIC_VECTOR(16#A5#, 8);
        fsm_ethcfg_cs<=S_CFG_ETH_DONE;

      when S_CFG_ETH_DONE =>
        i_eth_cfg_wr<='0';
        i_eth_cfg_done<='1';

    end case;
  end if;
end process;


--***********************************************************
--Формируем данные для MAC FRAME (Length + UsrDATA)
--и отправляем в модуль m_eth1
--***********************************************************
process(i_sys_rst,i_ethphy_out)
begin
  if i_sys_rst='1' then
    fsm_usrpkt_tx_cs<=S_USR_PKT_TXDLY;

    i_eth_txpkt_dcnt<=(others=>'0');
    i_eth_txpkt_d<=(others=>'0');
    i_eth_txpkt_wr<='0';
    i_eth_txpkt_len<=(others=>'0');
    i_eth_txpkt_tx_dlycnt<=(others=>'0');

  elsif i_ethphy_out.clk'event and i_ethphy_out.clk='1' then

    case fsm_usrpkt_tx_cs is

      -----------------------------------
      --Задержка между TxPKT
      -----------------------------------
      when S_USR_PKT_TXDLY =>

        if i_eth_cfg_done='1' and i_ethphy_out.rdy='1' then
          if i_ethphy_out.link='1' then

              if i_t1ms='1' then
                if i_eth_txpkt_tx_dlycnt=CONV_STD_LOGIC_VECTOR(250,i_eth_txpkt_tx_dlycnt'length) then
                  i_eth_txpkt_tx_dlycnt<=(others=>'0');
                  i_eth_txpkt_len<=CONV_STD_LOGIC_VECTOR(2 + 128, 16);
                  i_eth_txpkt_dcnt<=(others=>'0');
                  fsm_usrpkt_tx_cs<=S_USR_PKT_TX0;
                else
                  i_eth_txpkt_tx_dlycnt<=i_eth_txpkt_tx_dlycnt + 1;
                end if;
              end if;

          end if;
        end if;

      -----------------------------------
      --Отправляем TxPKT
      -----------------------------------
      when S_USR_PKT_TX0 =>

          if i_eth_in(0).txbuf.full='0' then
            i_eth_txpkt_d(15 downto 0)<=i_eth_txpkt_len;
            i_eth_txpkt_d(31 downto 16)<=CONV_STD_LOGIC_VECTOR(16#0000#, 16);
            i_eth_txpkt_wr<='1';
            i_eth_txpkt_dcnt<=i_eth_txpkt_dcnt + 2;
            fsm_usrpkt_tx_cs<=S_USR_PKT_TX1;
          end if;

      when S_USR_PKT_TX1 =>

          if i_eth_in(0).txbuf.full='0' then
            if i_eth_txpkt_dcnt=i_eth_txpkt_len then
              i_eth_txpkt_dcnt<=(others=>'0');
              i_eth_txpkt_wr<='0';
              fsm_usrpkt_tx_cs<=S_USR_PKT_TXDLY;
            else
              i_eth_txpkt_d<=EXT(i_eth_txpkt_dcnt, i_eth_txpkt_d'length);
              i_eth_txpkt_dcnt<=i_eth_txpkt_dcnt + 4;
            end if;
          end if;

    end case;
  end if;
end process;

m_eth_txbuf : host_ethg_txfifo
port map(
din     => i_eth_txpkt_d,
wr_en   => i_eth_txpkt_wr,
wr_clk  => i_ethphy_out.clk,

dout    => i_eth_in(0).txbuf.dout(31 downto 0),
rd_en   => i_eth_out(0).txbuf.rd,
rd_clk  => i_ethphy_out.clk,

empty   => i_eth_in(0).txbuf.empty,
full    => i_eth_in(0).txbuf.full,

rst     => i_sys_rst
);


--//#########################################
--//DBG
--//#########################################
gen_ml505 : if strcmp(C_PCFG_BOARD,"ML505") generate
i_usr_rst <= pin_in_btn_N;
end generate gen_ml505;

gen_htgv6 : if strcmp(C_PCFG_BOARD,"HTGV6") generate
i_usr_rst <= not pin_in_btn_N;
end generate gen_htgv6;

i_mnl_rst<=i_sys_rst or i_usr_rst;

pin_out_led(0)<=i_ethphy_out.opt(C_ETHPHY_OPTOUT_RST_BIT) and
                (OR_reduce(dbg_eth_out.app(0).mac_rx) or OR_reduce(dbg_eth_out.app(0).mac_tx));
pin_out_led(1)<=i_ethphy_out.opt(C_ETHPHY_OPTOUT_RST_BIT);
pin_out_led(2)<='0';
pin_out_led(3)<='0';

pin_out_led(4)<='0';
pin_out_led(5)<=not i_ethphy_out.rdy;--read bad ID from ETHPHY
pin_out_led(6)<=i_ethphy_out.link;
pin_out_led(7)<=i_test01_led;

m_gt_03_test: fpga_test_01
generic map(
G_BLINK_T05   =>10#250#, -- 1/2 периода мигания светодиода.(время в ms)
G_CLK_T05us   =>10#62#   -- 05us - 125MHz
)
port map(
p_out_test_led => i_test01_led,
p_out_test_done=> open,

p_out_1us      => open,
p_out_1ms      => i_t1ms,
-------------------------------
--System
-------------------------------
p_in_clk       => i_ethphy_out.clk,
p_in_rst       => i_mnl_rst
);

end architecture;
