-------------------------------------------------------------------------
-- Company     : Linkos
-- Engineer    : Golovachenko Victor
--
-- Create Date : 10/26/2007
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
use ieee.std_logic_unsigned.all;

library unisim;
use unisim.vcomponents.all;

use work.vicg_common_pkg.all;
--use work.vereskm_pkg.all;
use work.prj_def.all;
use work.eth_pkg.all;

entity dsn_ethg is
generic
(
G_MODULE_USE           : string:="ON"
);
port
(
-------------------------------
-- Конфигурирование модуля dsn_ethg.vhd (host_clk domain)
-------------------------------
p_in_cfg_clk          : in   std_logic;                      --//

p_in_cfg_adr          : in   std_logic_vector(7 downto 0);  --//
p_in_cfg_adr_ld       : in   std_logic;                     --//
p_in_cfg_adr_fifo     : in   std_logic;                     --//

p_in_cfg_txdata       : in   std_logic_vector(15 downto 0);  --//
p_in_cfg_wd           : in   std_logic;                      --//

p_out_cfg_rxdata      : out  std_logic_vector(15 downto 0);  --//
p_in_cfg_rd           : in   std_logic;                      --//

p_in_cfg_done         : in   std_logic;                      --//
p_in_cfg_rst          : in   std_logic;

-------------------------------
-- STATUS модуля dsn_ethg.vhd
-------------------------------
p_out_eth_rdy         : out  std_logic;                      --//
p_out_eth_error       : out  std_logic;                      --//
p_out_eth_gtp_plllkdet: out  std_logic;                      --//

-------------------------------
-- Связь с буферами модуля dsn_switch.vhd
-------------------------------
p_out_eth0_bufclk           : out  std_logic;

p_out_eth0_rxdata_rdy       : out  std_logic;--//Строб rxdata - последний 2DWORD пакета Eth(готовность)
p_out_eth0_rxdata_sof       : out  std_logic;--//Строб rxdata - первый 2DWORD пакета Eth
p_out_eth0_rxbuf_din        : out  std_logic_vector(31 downto 0);
p_out_eth0_rxbuf_wd         : out  std_logic;
p_in_eth0_rxbuf_empty       : in   std_logic;
p_in_eth0_rxbuf_full        : in   std_logic;

p_in_eth0_txdata_rdy        : in   std_logic;--//Строб txdata - готовы, можно вычитывать данные из внешного TXBUF
p_in_eth0_txbuf_dout        : in   std_logic_vector(31 downto 0);
p_out_eth0_txbuf_rd         : out  std_logic;
p_in_eth0_txbuf_empty       : in   std_logic;
p_in_eth0_txbuf_empty_almost: in   std_logic;

-------------------------------
-- EthG Drive
-------------------------------
--//Связь с внешиним приемопередатчиком
p_out_eth0_gtp_txp         : out   std_logic;
p_out_eth0_gtp_txn         : out   std_logic;
p_in_eth0_gtp_rxp          : in    std_logic;
p_in_eth0_gtp_rxn          : in    std_logic;

p_in_eth0_clkref           : in    std_logic;                      --//

p_out_eth1_gtp_txp         : out   std_logic;
p_out_eth1_gtp_txn         : out   std_logic;
p_in_eth1_gtp_rxp          : in    std_logic;
p_in_eth1_gtp_rxn          : in    std_logic;

p_out_sfp_tx_dis           : out  std_logic;                      --//SFP - TX DISABLE
p_in_sfp_sd                : in   std_logic;                      --//SFP - SD signal detect

-------------------------------
--Технологический
-------------------------------
p_out_tst                  : out   std_logic_vector(31 downto 0);

-------------------------------
--System
-------------------------------
p_out_eth0_sync_acq_status : out   std_logic;
p_in_gtp_drp_clk           : in    std_logic;

p_in_rst        : in    std_logic
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

signal h_reg_ctrl                        : std_logic_vector(31 downto 0);
signal h_reg_tst0                        : std_logic_vector(15 downto 0);
--signal h_reg_tst1                        : std_logic_vector(15 downto 0);

signal h_reg_mac_usrctrl                 : std_logic_vector(15 downto 0);
signal h_reg_mac_pattern                 : std_logic_vector(111 downto 0);

signal i_reg_mac_usrctrl                 : std_logic_vector(15 downto 0);
signal i_usr0_mac_pattern                : std_logic_vector(127 downto 0);

signal i_eth0_txbuf_dout_swap            : std_logic_vector(31 downto 0);
signal i_eth0_rxbuf_din_swap             : std_logic_vector(31 downto 0);

signal i_ethg0_bufclk                    : std_logic;
signal i_gtp_plllkdet                    : std_logic;

signal i_drp_ctrl                        : std_logic_vector(31 downto 0);
signal mac0_gtp_clk125_o                 : std_logic;
signal mac0_gtp_clk125                   : std_logic;


signal tst_usr_out : std_logic_vector(31 downto 0);



--MAIN
begin

process(p_in_rst,i_ethg0_bufclk)
begin
  if p_in_rst='1' then
    p_out_tst<=(others=>'0');
  elsif i_ethg0_bufclk'event and i_ethg0_bufclk='1' then
      p_out_tst<=tst_usr_out;
  end if;
end process;
--p_out_tst<=(others=>'0');


--//--------------------------------------------------
--//Конфигурирование модуля dsn_ethg.vhd
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
    h_reg_ctrl(15 downto 0)<=(others=>'0');
    h_reg_tst0<=(others=>'0');
--    h_reg_tst1<=(others=>'0');

    h_reg_mac_usrctrl<=(others=>'0');
    h_reg_mac_pattern<=(others=>'0');

  elsif p_in_cfg_clk'event and p_in_cfg_clk='1' then
    if p_in_cfg_wd='1' then
        if    i_cfg_adr_cnt=CONV_STD_LOGIC_VECTOR(C_DSN_ETHG_REG_CTRL_L, i_cfg_adr_cnt'length) then h_reg_ctrl(15 downto 0) <=p_in_cfg_txdata;
--        elsif i_cfg_adr_cnt=CONV_STD_LOGIC_VECTOR(C_DSN_ETHG_REG_CTRL_M, i_cfg_adr_cnt'length) then h_reg_ctrl(31 downto 16)<=p_in_cfg_txdata;

        elsif i_cfg_adr_cnt=CONV_STD_LOGIC_VECTOR(C_DSN_ETHG_REG_TST0, i_cfg_adr_cnt'length)   then h_reg_tst0<=p_in_cfg_txdata;
--        elsif i_cfg_adr_cnt=CONV_STD_LOGIC_VECTOR(C_DSN_ETHG_REG_TST1, i_cfg_adr_cnt'length)   then h_reg_tst1<=p_in_cfg_txdata;

        elsif i_cfg_adr_cnt=CONV_STD_LOGIC_VECTOR(C_DSN_ETHG_REG_MAC_USRCTRL, i_cfg_adr_cnt'length)  then h_reg_mac_usrctrl<=p_in_cfg_txdata;
        elsif i_cfg_adr_cnt=CONV_STD_LOGIC_VECTOR(C_DSN_ETHG_REG_MAC_PATRN0, i_cfg_adr_cnt'length)   then h_reg_mac_pattern(15  downto 0)  <=p_in_cfg_txdata;
        elsif i_cfg_adr_cnt=CONV_STD_LOGIC_VECTOR(C_DSN_ETHG_REG_MAC_PATRN1, i_cfg_adr_cnt'length)   then h_reg_mac_pattern(31  downto 16) <=p_in_cfg_txdata;
        elsif i_cfg_adr_cnt=CONV_STD_LOGIC_VECTOR(C_DSN_ETHG_REG_MAC_PATRN2, i_cfg_adr_cnt'length)   then h_reg_mac_pattern(47  downto 32) <=p_in_cfg_txdata;
        elsif i_cfg_adr_cnt=CONV_STD_LOGIC_VECTOR(C_DSN_ETHG_REG_MAC_PATRN3, i_cfg_adr_cnt'length)   then h_reg_mac_pattern(63  downto 48) <=p_in_cfg_txdata;
        elsif i_cfg_adr_cnt=CONV_STD_LOGIC_VECTOR(C_DSN_ETHG_REG_MAC_PATRN4, i_cfg_adr_cnt'length)   then h_reg_mac_pattern(79  downto 64) <=p_in_cfg_txdata;
        elsif i_cfg_adr_cnt=CONV_STD_LOGIC_VECTOR(C_DSN_ETHG_REG_MAC_PATRN5, i_cfg_adr_cnt'length)   then h_reg_mac_pattern(95  downto 80) <=p_in_cfg_txdata;
        elsif i_cfg_adr_cnt=CONV_STD_LOGIC_VECTOR(C_DSN_ETHG_REG_MAC_PATRN6, i_cfg_adr_cnt'length)   then h_reg_mac_pattern(111 downto 96) <=p_in_cfg_txdata;
--        elsif i_cfg_adr_cnt=CONV_STD_LOGIC_VECTOR(C_DSN_ETHG_REG_MAC_PATRN7, i_cfg_adr_cnt'length)   then h_reg_mac_pattern(127 downto 112)<=p_in_cfg_txdata;

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
        if    i_cfg_adr_cnt=CONV_STD_LOGIC_VECTOR(C_DSN_ETHG_REG_CTRL_L, i_cfg_adr_cnt'length) then p_out_cfg_rxdata<=h_reg_ctrl(15 downto 0);
--        elsif i_cfg_adr_cnt=CONV_STD_LOGIC_VECTOR(C_DSN_ETHG_REG_CTRL_M, i_cfg_adr_cnt'length) then p_out_cfg_rxdata<=h_reg_ctrl(31 downto 16);

        elsif i_cfg_adr_cnt=CONV_STD_LOGIC_VECTOR(C_DSN_ETHG_REG_TST0, i_cfg_adr_cnt'length)   then p_out_cfg_rxdata<=h_reg_tst0;
--        elsif i_cfg_adr_cnt=CONV_STD_LOGIC_VECTOR(C_DSN_ETHG_REG_TST1, i_cfg_adr_cnt'length)   then p_out_cfg_rxdata<=h_reg_tst1;

        elsif i_cfg_adr_cnt=CONV_STD_LOGIC_VECTOR(C_DSN_ETHG_REG_MAC_USRCTRL, i_cfg_adr_cnt'length)  then p_out_cfg_rxdata<=h_reg_mac_usrctrl;
        elsif i_cfg_adr_cnt=CONV_STD_LOGIC_VECTOR(C_DSN_ETHG_REG_MAC_PATRN0, i_cfg_adr_cnt'length)   then p_out_cfg_rxdata<=h_reg_mac_pattern(15  downto 0);
        elsif i_cfg_adr_cnt=CONV_STD_LOGIC_VECTOR(C_DSN_ETHG_REG_MAC_PATRN1, i_cfg_adr_cnt'length)   then p_out_cfg_rxdata<=h_reg_mac_pattern(31  downto 16);
        elsif i_cfg_adr_cnt=CONV_STD_LOGIC_VECTOR(C_DSN_ETHG_REG_MAC_PATRN2, i_cfg_adr_cnt'length)   then p_out_cfg_rxdata<=h_reg_mac_pattern(47  downto 32);
        elsif i_cfg_adr_cnt=CONV_STD_LOGIC_VECTOR(C_DSN_ETHG_REG_MAC_PATRN3, i_cfg_adr_cnt'length)   then p_out_cfg_rxdata<=h_reg_mac_pattern(63  downto 48);
        elsif i_cfg_adr_cnt=CONV_STD_LOGIC_VECTOR(C_DSN_ETHG_REG_MAC_PATRN4, i_cfg_adr_cnt'length)   then p_out_cfg_rxdata<=h_reg_mac_pattern(79  downto 64);
        elsif i_cfg_adr_cnt=CONV_STD_LOGIC_VECTOR(C_DSN_ETHG_REG_MAC_PATRN5, i_cfg_adr_cnt'length)   then p_out_cfg_rxdata<=h_reg_mac_pattern(95  downto 80);
        elsif i_cfg_adr_cnt=CONV_STD_LOGIC_VECTOR(C_DSN_ETHG_REG_MAC_PATRN6, i_cfg_adr_cnt'length)   then p_out_cfg_rxdata<=h_reg_mac_pattern(111 downto 96);
--        elsif i_cfg_adr_cnt=CONV_STD_LOGIC_VECTOR(C_DSN_ETHG_REG_MAC_PATRN7, i_cfg_adr_cnt'length)   then p_out_cfg_rxdata<=h_reg_mac_pattern(127 downto 112);

        end if;
    end if;
  end if;
end process;

h_reg_ctrl(31 downto 16)<=(others=>'0');



LB_MOD_USE_ON : if strcmp(G_MODULE_USE,"ON") generate
begin

  p_out_eth_rdy         <=p_in_sfp_sd;
  p_out_eth_error       <='0';
  p_out_eth_gtp_plllkdet<=i_gtp_plllkdet;

  p_out_sfp_tx_dis <= h_reg_ctrl(C_DSN_ETHG_REG_CTRL_SFP_TX_DISABLE_BIT);

  p_out_eth0_bufclk<=i_ethg0_bufclk;


  i_usr0_mac_pattern(111 downto 0)  <=h_reg_mac_pattern(111 downto 0);
  i_usr0_mac_pattern(127 downto 112)<=(others=>'0');


  ----//-----------------------------------------------------------------
  ----//В случае если передача по Eth - DWORD user data старшим байтом вперед, то
  ----//-----------------------------------------------------------------
  ----//Для передоваемых данных:
  --i_eth0_txbuf_dout_swap(31 downto 24)<=p_in_eth0_txbuf_dout(23 downto 16);
  --i_eth0_txbuf_dout_swap(23 downto 16)<=p_in_eth0_txbuf_dout(31 downto 24);
  --i_eth0_txbuf_dout_swap(15 downto 8) <=p_in_eth0_txbuf_dout(7 downto 0);
  --i_eth0_txbuf_dout_swap(7 downto 0)  <=p_in_eth0_txbuf_dout(15 downto 8);
  --
  ----//Для принимаемых данных:
  --p_out_eth0_rxbuf_din(31 downto 24)<=i_eth0_rxbuf_din_swap(23 downto 16);
  --p_out_eth0_rxbuf_din(23 downto 16)<=i_eth0_rxbuf_din_swap(31 downto 24);
  --p_out_eth0_rxbuf_din(15 downto 8) <=i_eth0_rxbuf_din_swap(7 downto 0);
  --p_out_eth0_rxbuf_din(7 downto 0)  <=i_eth0_rxbuf_din_swap(15 downto 8);
  --
  --
  --//-----------------------------------------------------------------
  --//В случае если передача по Eth - DWORD user data младшим байтом вперед, то
  --//-----------------------------------------------------------------
  --//Для передоваемых данных:
  i_eth0_txbuf_dout_swap(31 downto 0)<=p_in_eth0_txbuf_dout(31 downto 0);

  --//Для принимаемых данных:
  p_out_eth0_rxbuf_din(31 downto 0)<=i_eth0_rxbuf_din_swap(31 downto 0);
  --
  --i_reg_mac_usrctrl(15 downto C_DSN_ETHG_REG_MAC_RX_SWAP_BYTE_BIT+1)<=h_reg_mac_usrctrl(15 downto C_DSN_ETHG_REG_MAC_RX_SWAP_BYTE_BIT+1);
  --i_reg_mac_usrctrl(C_DSN_ETHG_REG_MAC_RX_SWAP_BYTE_BIT)<='1';
  --i_reg_mac_usrctrl(C_DSN_ETHG_REG_MAC_RX_SWAP_BYTE_BIT-1 downto 0)<=h_reg_mac_usrctrl(C_DSN_ETHG_REG_MAC_RX_SWAP_BYTE_BIT-1 downto 0);

  ----//-----------------------------------------------------------------
  ----//В случае если передача по Eth - DWORD user data младшим байтом вперед, то
  ----//-----------------------------------------------------------------
  ----//Для передоваемых данных:
  --i_eth0_txbuf_dout_swap(31 downto 24)<=p_in_eth0_txbuf_dout(31 downto 24) when h_reg_mac_usrctrl(C_DSN_ETHG_REG_MAC_RX_SWAP_BYTE_BIT)='0' else p_in_eth0_txbuf_dout(23 downto 16);
  --i_eth0_txbuf_dout_swap(23 downto 16)<=p_in_eth0_txbuf_dout(23 downto 16) when h_reg_mac_usrctrl(C_DSN_ETHG_REG_MAC_RX_SWAP_BYTE_BIT)='0' else p_in_eth0_txbuf_dout(31 downto 24);
  --i_eth0_txbuf_dout_swap(15 downto 8) <=p_in_eth0_txbuf_dout(15 downto 8)  when h_reg_mac_usrctrl(C_DSN_ETHG_REG_MAC_RX_SWAP_BYTE_BIT)='0' else p_in_eth0_txbuf_dout(7 downto 0);
  --i_eth0_txbuf_dout_swap(7 downto 0)  <=p_in_eth0_txbuf_dout(7 downto 0)   when h_reg_mac_usrctrl(C_DSN_ETHG_REG_MAC_RX_SWAP_BYTE_BIT)='0' else p_in_eth0_txbuf_dout(15 downto 8);
  --
  ----//Для принимаемых данных:
  --p_out_eth0_rxbuf_din(31 downto 24)<=i_eth0_rxbuf_din_swap(31 downto 24)  when h_reg_mac_usrctrl(C_DSN_ETHG_REG_MAC_RX_SWAP_BYTE_BIT)='0' else i_eth0_rxbuf_din_swap(23 downto 16);
  --p_out_eth0_rxbuf_din(23 downto 16)<=i_eth0_rxbuf_din_swap(23 downto 16)  when h_reg_mac_usrctrl(C_DSN_ETHG_REG_MAC_RX_SWAP_BYTE_BIT)='0' else i_eth0_rxbuf_din_swap(31 downto 24);
  --p_out_eth0_rxbuf_din(15 downto 8) <=i_eth0_rxbuf_din_swap(15 downto 8)   when h_reg_mac_usrctrl(C_DSN_ETHG_REG_MAC_RX_SWAP_BYTE_BIT)='0' else i_eth0_rxbuf_din_swap(7 downto 0);
  --p_out_eth0_rxbuf_din(7 downto 0)  <=i_eth0_rxbuf_din_swap(7 downto 0)    when h_reg_mac_usrctrl(C_DSN_ETHG_REG_MAC_RX_SWAP_BYTE_BIT)='0' else i_eth0_rxbuf_din_swap(15 downto 8);


  --//#############################################################
  --//модуль управления Ethernet MAC
  --//#############################################################
  m_eth_main : eth_main
  generic map(
  G_REM_WIDTH    => 2,
  G_DWIDTH       => 32
  )
  port map
  (
  --//Управление
  p_in_glob_ctrl                  => h_reg_ctrl,

  --//------------------------------------
  --//EMAC - Channel 0
  --//------------------------------------
  --//Управление
  p_in_usr0_ctrl                  => h_reg_mac_usrctrl,
  p_in_usr0_mac_pattern           => i_usr0_mac_pattern,

  --//Связь с пользовательским RXBUF
  p_out_usr0_rxdata               => i_eth0_rxbuf_din_swap,--p_out_eth0_rxbuf_din,
  p_out_usr0_rxdata_wr            => p_out_eth0_rxbuf_wd,
  p_out_usr0_rxdata_rdy           => p_out_eth0_rxdata_rdy,
  p_out_usr0_rxdata_sof           => p_out_eth0_rxdata_sof,
  p_in_usr0_rxbuf_full            => '0',--p_in_eth0_rxbuf_full,

  --//Связь с пользовательским TXBUF
  p_in_usr0_txdata                => i_eth0_txbuf_dout_swap,--p_in_eth0_txbuf_dout,
  p_out_usr0_txdata_rd            => p_out_eth0_txbuf_rd,
  p_in_usr0_txdata_rdy            => p_in_eth0_txdata_rdy,
  p_in_usr0_txbuf_empty           => p_in_eth0_txbuf_empty,
  p_in_usr0_txbuf_empty_almost    => p_in_eth0_txbuf_empty_almost,

  --частота для буферов RX/TXBUF
  p_out_usr0_bufclk               => i_ethg0_bufclk,

  --//Связь с внешиним приемопередатчиком
  p_out_emac0_gtp_txp             => p_out_eth0_gtp_txp,
  p_out_emac0_gtp_txn             => p_out_eth0_gtp_txn,
  p_in_emac0_gtp_rxp              => p_in_eth0_gtp_rxp,
  p_in_emac0_gtp_rxn              => p_in_eth0_gtp_rxn,

  --Опорная частота для RocketIO
  p_in_emac0_clkref               => p_in_eth0_clkref,

  p_out_emac0_sync_acq_status     => p_out_eth0_sync_acq_status,

  --//------------------------------------
  --//EMAC - Channel 1
  --//------------------------------------
  p_out_emac1_gtp_txp             => p_out_eth1_gtp_txp,
  p_out_emac1_gtp_txn             => p_out_eth1_gtp_txn,
  p_in_emac1_gtp_rxp              => p_in_eth1_gtp_rxp,
  p_in_emac1_gtp_rxn              => p_in_eth1_gtp_rxn,

  --//------------------------------------
  --//SYSTEM
  --//------------------------------------
  p_in_gtp_drp_clk                => p_in_gtp_drp_clk,
  p_out_gtp_plllkdet              => i_gtp_plllkdet,
  p_out_ust_tst                   => tst_usr_out,


  -- Asynchronous Reset
  p_in_rst                        => p_in_rst
  );

end generate LB_MOD_USE_ON;

LB_MOD_USE_OFF : if strcmp(G_MODULE_USE,"OFF") generate
begin

  p_out_eth_rdy         <=p_in_sfp_sd;
  p_out_eth_error       <='0';
  p_out_eth_gtp_plllkdet<=i_gtp_plllkdet;

  p_out_sfp_tx_dis <= h_reg_ctrl(C_DSN_ETHG_REG_CTRL_SFP_TX_DISABLE_BIT);

  p_out_eth0_bufclk<=mac0_gtp_clk125;

  p_out_eth0_sync_acq_status<='0';

  p_out_eth0_rxdata_rdy<=p_in_eth0_txdata_rdy;
  p_out_eth0_rxdata_sof<=p_in_eth0_txdata_rdy;
  p_out_eth0_rxbuf_din<=p_in_eth0_txbuf_dout;
  p_out_eth0_rxbuf_wd  <= not p_in_eth0_txbuf_empty and not p_in_eth0_rxbuf_full;

  p_out_eth0_txbuf_rd  <= not p_in_eth0_txbuf_empty;

  i_ethg0_bufclk<=mac0_gtp_clk125;

  bufg_clk125 : BUFG port map (I => mac0_gtp_clk125_o, O => mac0_gtp_clk125);

  i_drp_ctrl(30 downto 0)<=h_reg_ctrl(30 downto 0);
  i_drp_ctrl(31)<=p_in_gtp_drp_clk;

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
  p_in_drp_ctrl                  => i_drp_ctrl,

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
  RXN0_IN                                 => p_in_eth0_gtp_rxn,
  RXN1_IN                                 => p_in_eth1_gtp_rxn,
  RXP0_IN                                 => p_in_eth0_gtp_rxp,
  RXP1_IN                                 => p_in_eth1_gtp_rxp,
  -------- Receive Ports - RX Elastic Buffer and Phase Alignment Ports -------
  RXBUFRESET0_IN                          => '0',
  RXBUFRESET1_IN                          => '0',
  RXBUFSTATUS0_OUT                        => open,
  RXBUFSTATUS1_OUT                        => open,
  --------------------- Shared Ports - Tile and PLL Ports --------------------
  CLKIN_IN                                => p_in_eth0_clkref,
  GTPRESET_IN                             => p_in_rst,
  PLLLKDET_OUT                            => i_gtp_plllkdet,
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
  TXN0_OUT                                => p_out_eth0_gtp_txn,
  TXN1_OUT                                => p_out_eth1_gtp_txn,
  TXP0_OUT                                => p_out_eth0_gtp_txp,
  TXP1_OUT                                => p_out_eth1_gtp_txp
  );


end generate LB_MOD_USE_OFF;

--END MAIN
end behavioral;
