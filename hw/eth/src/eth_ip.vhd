-------------------------------------------------------------------------
-- Company     : Linkos
-- Engineer    : Golovachenko Victor
--
-- Create Date : 10.10.2012 10:49:15
-- Module Name : eth_ip
--
-- Назначение/Описание :
--  Модуль отвечает на запросы ARP(Broadcast) + ARP(MAC_DST=MAC_FPGA)
--  + отвечает на запрос ICMP(ping)
--  + прием/отправка UDP пакетов
--  + прием IP адреса FPGA от сервера DHCP (минимальная реализация DHCP Client)
--
-------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_misc.all;
use ieee.std_logic_unsigned.all;

library work;
use work.vicg_common_pkg.all;
use work.eth_pkg.all;

entity eth_ip is
generic(
G_ETH : TEthGeneric;
G_DBG : string:="OFF";
G_SIM : string:="OFF"
);
port(
--------------------------------------
--Управление
--------------------------------------
p_in_cfg         : in    TEthCfg;
p_in_link        : in    std_logic;

--------------------------------------
--Связь с пользовательским RXBUF
--------------------------------------
p_out_rxbuf_din       : out   std_logic_vector(G_ETH.usrbuf_dwidth-1 downto 0);
p_out_rxbuf_wr        : out   std_logic;
p_in_rxbuf_full       : in    std_logic;
p_out_rxd_sof         : out   std_logic;
p_out_rxd_eof         : out   std_logic;

--------------------------------------
--Связь с пользовательским TXBUF
--------------------------------------
p_in_txbuf_dout       : in    std_logic_vector(G_ETH.usrbuf_dwidth-1 downto 0);
p_out_txbuf_rd        : out   std_logic;
p_in_txbuf_empty      : in    std_logic;
--p_in_txd_rdy          : in    std_logic;

--------------------------------------
--Связь с Local link RxFIFO
--------------------------------------
p_in_rxll_data        : in    std_logic_vector(G_ETH.phy_dwidth-1 downto 0);
p_in_rxll_sof_n       : in    std_logic;
p_in_rxll_eof_n       : in    std_logic;
p_in_rxll_src_rdy_n   : in    std_logic;
p_out_rxll_dst_rdy_n  : out   std_logic;
p_in_rxll_fifo_status : in    std_logic_vector(3 downto 0);
p_in_rxll_rem         : in    std_logic_vector(0 downto 0);

--------------------------------------
--Связь с Local link TxFIFO
--------------------------------------
p_out_txll_data      : out   std_logic_vector(G_ETH.phy_dwidth-1 downto 0);
p_out_txll_sof_n     : out   std_logic;
p_out_txll_eof_n     : out   std_logic;
p_out_txll_src_rdy_n : out   std_logic;
p_in_txll_dst_rdy_n  : in    std_logic;
p_out_txll_rem       : out   std_logic_vector(0 downto 0);

--------------------------------------------------
--Технологические сигналы
--------------------------------------------------
p_in_tst         : in    std_logic_vector(31 downto 0);
p_out_tst        : out   std_logic_vector(31 downto 0);

--------------------------------------
--SYSTEM
--------------------------------------
p_in_clk         : in    std_logic;
p_in_rst         : in    std_logic
);
end eth_ip;

architecture behavioral of eth_ip is

constant CI_DHCP_USE             : std_logic:='1';

constant CI_HREG_ETH_TYPE        : integer:=12;
constant CI_HREG_ARP_HTYPE       : integer:=14;
constant CI_HREG_IP_VER          : integer:=14;
constant CI_HREG_ARP_PTYPE       : integer:=16;
constant CI_HREG_ARP_HPLEN       : integer:=18;
constant CI_HREG_ARP_OPER        : integer:=20;
constant CI_HREG_IP_PROTOCOL     : integer:=23;
constant CI_HREG_ICMP_OPER       : integer:=34;

constant CI_TX_REQ_ARP_ACK       : integer:=1;
constant CI_TX_REQ_ICMP_ACK      : integer:=2;
constant CI_TX_REQ_DHCP_DISCOVER : integer:=3;
constant CI_TX_REQ_DHCP_REQUEST  : integer:=4;

constant CI_ETH_TYPE_ARP         : std_logic_vector(15 downto 0):=CONV_STD_LOGIC_VECTOR(16#0806#, 16);
constant CI_ETH_TYPE_IP          : std_logic_vector(15 downto 0):=CONV_STD_LOGIC_VECTOR(16#0800#, 16);

constant CI_IP_HEADER_SIZE       : integer:=20;--byte
constant CI_IP_VER               : integer:=4;--IPv4
constant CI_IP_TTL               : std_logic_vector(7 downto 0):=CONV_STD_LOGIC_VECTOR(64, 8);
constant CI_IP_PTYPE_ICMP        : std_logic_vector(7 downto 0):=CONV_STD_LOGIC_VECTOR(1, 8);
constant CI_IP_PTYPE_UDP         : std_logic_vector(7 downto 0):=CONV_STD_LOGIC_VECTOR(17, 8);

constant CI_ARP_HTYPE            : std_logic_vector(15 downto 0):=CONV_STD_LOGIC_VECTOR(1, 16);
constant CI_ARP_HLEN             : std_logic_vector( 7 downto 0):=CONV_STD_LOGIC_VECTOR(6, 8);
constant CI_ARP_PLEN             : std_logic_vector( 7 downto 0):=CONV_STD_LOGIC_VECTOR(4, 8);
constant CI_ARP_HPLEN            : std_logic_vector(15 downto 0):=CONV_STD_LOGIC_VECTOR(16#0604#, 16);
constant CI_ARP_OPER_REQUEST     : std_logic_vector(15 downto 0):=CONV_STD_LOGIC_VECTOR(1, 16);
constant CI_ARP_OPER_REPLY       : std_logic_vector(15 downto 0):=CONV_STD_LOGIC_VECTOR(2, 16);

constant CI_ICMP_OPER_REQUEST    : std_logic_vector(7 downto 0):=CONV_STD_LOGIC_VECTOR(8, 8);
constant CI_ICMP_OPER_ECHO_REPLY : std_logic_vector(7 downto 0):=CONV_STD_LOGIC_VECTOR(0, 8);

constant CI_UDP_HEADER_SIZE      : integer:=8;--byte
constant CI_UDP_PORT_DHCP_SERVER : std_logic_vector(15 downto 0):=CONV_STD_LOGIC_VECTOR(67, 16);
constant CI_UDP_PORT_DHCP_CLIENT : std_logic_vector(15 downto 0):=CONV_STD_LOGIC_VECTOR(68, 16);

constant CI_DHCP_FIELD_SNAME_SIZE: integer:=64;
constant CI_DHCP_FIELD_FILE_SIZE : integer:=128;
constant CI_DHCP_OPER_REQUEST    : std_logic_vector(7 downto 0):=CONV_STD_LOGIC_VECTOR(1, 8);
constant CI_DHCP_OPER_REPLY      : std_logic_vector(7 downto 0):=CONV_STD_LOGIC_VECTOR(2, 8);
constant CI_DHCP_MAGIC_COOKIE    : std_logic_vector(31 downto 0):=CONV_STD_LOGIC_VECTOR(16#63538263#, 32);
constant CI_DHCP_CODE_50         : std_logic_vector(7 downto 0):=CONV_STD_LOGIC_VECTOR(50, 8); --DHCP - Requested IP Address
constant CI_DHCP_CODE_53         : std_logic_vector(7 downto 0):=CONV_STD_LOGIC_VECTOR(53, 8); --DHCP - Message Type
constant CI_DHCP_CODE_54         : std_logic_vector(7 downto 0):=CONV_STD_LOGIC_VECTOR(54, 8); --DHCP - Server Identifier
constant CI_DHCP_CODE_61         : std_logic_vector(7 downto 0):=CONV_STD_LOGIC_VECTOR(61, 8); --DHCP - Client Identifier
constant CI_DHCP_CODE_255        : std_logic_vector(7 downto 0):=CONV_STD_LOGIC_VECTOR(255, 8);--DHCP - End Option
constant CI_DHCP_DHCPDISCOVER    : std_logic_vector(7 downto 0):=CONV_STD_LOGIC_VECTOR(1, 8);
constant CI_DHCP_DHCPOFFER       : std_logic_vector(7 downto 0):=CONV_STD_LOGIC_VECTOR(2, 8);
constant CI_DHCP_DHCPREQUEST     : std_logic_vector(7 downto 0):=CONV_STD_LOGIC_VECTOR(3, 8);
constant CI_DHCP_DHCPACK         : std_logic_vector(7 downto 0):=CONV_STD_LOGIC_VECTOR(5, 8);

type TEth_fsm_rx is (
S_RX_IDLE       ,
S_RX_ARP        ,
S_RX_IP         ,
S_RX_ICMP       ,
S_RX_UDP_PORT   ,
S_RX_UDP_DLEN   ,
S_RX_UDP_CRC    ,
S_RX_UDP_D      ,
S_RX_WAIT_DONE  ,
S_RX_WAIT_TX_DONE ,
S_RX_DHCP_0     ,
S_RX_DHCP_1     ,
S_RX_DHCP_2     ,
S_RX_DHCP_3
);
signal fsm_ip_rx_cs: TEth_fsm_rx;

type TEth_fsm_tx is (
S_TX_IDLE     ,
S_TX_ACK_DLY  ,
S_TX_ACK      ,
S_TX_DONE     ,
S_TX_UDP_H0   ,
S_TX_UDP_HN   ,
S_TX_UDP_D    ,
S_TX_DHCP_0   ,
S_TX_DHCP_1
);
signal fsm_ip_tx_cs: TEth_fsm_tx;

signal i_fpga_mac             : TEthMacAdr;  --Параметры ETH для FPGA:
signal i_fpga_ip              : TEthIPv4;
signal i_fpga_udp_port        : std_logic_vector(p_in_cfg.prt.src'range);
signal i_host_mac             : TEthMacAdr;  --Параметры ETH для управляющего PC:
signal i_host_ip              : TEthIPv4;
signal i_host_udp_port        : std_logic_vector(p_in_cfg.prt.src'range);

signal i_rxll_dst_rdy_n       : std_logic;
signal i_txll_data            : std_logic_vector(p_out_txll_data'range);
signal i_txll_sof_n           : std_logic;
signal i_txll_eof_n           : std_logic;
signal i_txll_src_rdy_n       : std_logic;
signal i_txll_rem             : std_logic_vector(p_out_txll_rem'range);

type THReg is array (0 to 128-1) of std_logic_vector(p_out_txll_data'range);
signal i_hreg_d               : THReg;
signal i_hreg_a               : std_logic_vector(6 downto 0);
signal i_hreg_wr              : std_logic;

signal i_tx_req               : std_logic_vector(2 downto 0);
signal i_tx_dlen              : std_logic_vector(15 downto 0);
signal i_tx_dcnt              : std_logic_vector(15 downto 0);
signal i_tx_done              : std_logic;
signal i_tx_bcnt              : std_logic_vector(selval(0, 1, (p_out_txll_data'length=16)) downto 0);
signal i_tx_pktid             : std_logic_vector(15 downto 0);

signal i_rx_ip_valid          : std_logic_vector(i_fpga_ip'length - 1 downto 0);
signal i_rx_mac_valid         : std_logic_vector(i_fpga_mac'length - 1 downto 0);
signal i_rx_mac_broadcast     : std_logic_vector(i_fpga_mac'length - 1 downto 0);
signal i_rx_ip_broadcast      : std_logic_vector(i_fpga_ip'length - 1 downto 0);

signal i_arp_ack              : THReg;
signal i_icmp_ack             : THReg;
signal i_udp_pkt              : THReg;
signal i_dhcp_pkt             : THReg;

type TCRCData is array (14 to 33) of std_logic_vector(p_out_txll_data'range);
signal i_ip_crc_d             : TCRCData;
signal i_ip_crc_dcnt          : std_logic_vector(i_hreg_a'range);
signal i_ip_crc_tmp           : std_logic_vector(31 downto 0);
signal i_ip_crc_tmp2          : std_logic_vector(15 downto 0);
signal i_ip_crc               : std_logic_vector(15 downto 0);
signal i_ip_crc_calc          : std_logic;
signal i_ip_crc_rdy           : std_logic;
signal sr_ip_ack              : std_logic_vector(p_out_txll_data'range);
signal i_arp_ack_ereg         : std_logic_vector(15 downto 0);

signal i_icmp_crc_dcnt        : std_logic_vector(i_hreg_a'range);
signal i_icmp_crc_tmp         : std_logic_vector(31 downto 0);
signal i_icmp_crc_tmp2        : std_logic_vector(15 downto 0);
signal i_icmp_crc             : std_logic_vector(15 downto 0);
signal i_icmp_crc_calc        : std_logic;
signal i_icmp_crc_rdy         : std_logic;
signal sr_icmp_ack            : std_logic_vector(p_out_txll_data'range);
signal i_icmp_ack_ereg        : std_logic_vector(15 downto 0);

signal i_crc_start            : std_logic;

signal i_usr_txd_rd           : std_logic;--строб дополнительного чтения
signal i_usr_txd_rden         : std_logic;--разрешение чтения данных из usr_txbuf

signal i_rx_bcnt              : std_logic_vector(1 downto 0);
signal i_rx_fst               : std_logic;
signal i_rx_d                 : std_logic_vector(31 downto 0);
signal i_rx_en                : std_logic;
signal i_rx_sof               : std_logic;
signal i_rx_eof               : std_logic;
signal i_rx_sof_ext           : std_logic;
type TSr_rxd is array (2 downto 0) of std_logic_vector(p_out_txll_data'range);
signal sr_rx_d                : TSr_rxd;

signal i_udpip_crc_start      : std_logic;
signal i_udpip_crc_dcnt       : std_logic_vector(i_hreg_a'range);
signal i_udpip_crc_tmp        : std_logic_vector(31 downto 0);
signal i_udpip_crc_tmp2       : std_logic_vector(15 downto 0);
signal i_udpip_crc            : std_logic_vector(15 downto 0);
signal i_udpip_crc_calc       : std_logic;
signal i_udpip_crc_rdy        : std_logic;
signal sr_udp_pkt             : std_logic_vector(p_out_txll_data'range);
signal i_udpip_len            : std_logic_vector(15 downto 0);
signal i_udp_len              : std_logic_vector(15 downto 0);

signal i_dhcpip_len           : std_logic_vector(15 downto 0);
signal i_dhcp_len             : std_logic_vector(15 downto 0);
signal i_dhcp_ereg0           : std_logic_vector(15 downto 0);
signal i_dhcp_ereg1           : std_logic_vector(15 downto 0);
signal i_dhcp_xid             : std_logic_vector(31 downto 0);
signal i_dhcp_flags           : std_logic_vector(15 downto 0);
signal i_dhcp_discover_tx_done: std_logic;
signal i_dhcp_get_prm_done    : std_logic;
signal i_dhcp_server_ip       : TEthIPv4;
signal i_dhcp_client_ip       : TEthIPv4;
signal i_dhcp_server_mac      : TEthMacAdr;

signal tst_fms_cs_rx          : std_logic_vector(3 downto 0);
signal tst_fms_cs_tx          : std_logic_vector(3 downto 0);
signal tst_fms_cs_rx_dly      : std_logic_vector(3 downto 0);
signal tst_fms_cs_tx_dly      : std_logic_vector(3 downto 0);
signal tst_dhcp               : std_logic;


--MAIN
begin

--//----------------------------------
--//Технологические сигналы
--//----------------------------------
gen_dbg_off : if strcmp(G_DBG,"OFF") generate
p_out_tst(31 downto 0)<=(others=>'0');
end generate gen_dbg_off;

gen_dbg_on : if strcmp(G_DBG,"ON") generate
ltstout:process(p_in_rst,p_in_clk)
begin
  if p_in_rst='1' then
    tst_fms_cs_rx_dly<=(others=>'0');
    tst_fms_cs_tx_dly<=(others=>'0');
    p_out_tst(31 downto 1)<=(others=>'0');
  elsif p_in_clk'event and p_in_clk='1' then

    tst_fms_cs_rx_dly<=tst_fms_cs_rx;
    tst_fms_cs_tx_dly<=tst_fms_cs_tx;
    p_out_tst(0)<=OR_reduce(tst_fms_cs_rx_dly) or OR_reduce(tst_fms_cs_tx_dly) or tst_dhcp;
    p_out_tst(1)<=i_dhcp_get_prm_done;
  end if;
end process ltstout;

tst_fms_cs_rx<=CONV_STD_LOGIC_VECTOR(16#01#, tst_fms_cs_rx'length) when fsm_ip_rx_cs=S_RX_ARP       else
               CONV_STD_LOGIC_VECTOR(16#02#, tst_fms_cs_rx'length) when fsm_ip_rx_cs=S_RX_IP        else
               CONV_STD_LOGIC_VECTOR(16#03#, tst_fms_cs_rx'length) when fsm_ip_rx_cs=S_RX_ICMP      else
               CONV_STD_LOGIC_VECTOR(16#04#, tst_fms_cs_rx'length) when fsm_ip_rx_cs=S_RX_UDP_PORT  else
               CONV_STD_LOGIC_VECTOR(16#05#, tst_fms_cs_rx'length) when fsm_ip_rx_cs=S_RX_UDP_DLEN  else
               CONV_STD_LOGIC_VECTOR(16#06#, tst_fms_cs_rx'length) when fsm_ip_rx_cs=S_RX_UDP_CRC   else
               CONV_STD_LOGIC_VECTOR(16#07#, tst_fms_cs_rx'length) when fsm_ip_rx_cs=S_RX_UDP_D     else
               CONV_STD_LOGIC_VECTOR(16#08#, tst_fms_cs_rx'length) when fsm_ip_rx_cs=S_RX_WAIT_TX_DONE else
               CONV_STD_LOGIC_VECTOR(16#09#, tst_fms_cs_rx'length) when fsm_ip_rx_cs=S_RX_WAIT_DONE else
               CONV_STD_LOGIC_VECTOR(16#0A#, tst_fms_cs_rx'length) when fsm_ip_rx_cs=S_RX_DHCP_0    else
               CONV_STD_LOGIC_VECTOR(16#0B#, tst_fms_cs_rx'length) when fsm_ip_rx_cs=S_RX_DHCP_1    else
               CONV_STD_LOGIC_VECTOR(16#0C#, tst_fms_cs_rx'length) when fsm_ip_rx_cs=S_RX_DHCP_2    else
               CONV_STD_LOGIC_VECTOR(16#0D#, tst_fms_cs_rx'length) when fsm_ip_rx_cs=S_RX_DHCP_3    else
               CONV_STD_LOGIC_VECTOR(16#00#, tst_fms_cs_rx'length);-- when fsm_ip_rx_cs=S_RX_IDLE      else

tst_fms_cs_tx<=CONV_STD_LOGIC_VECTOR(16#01#, tst_fms_cs_tx'length) when fsm_ip_tx_cs=S_TX_ACK_DLY  else
               CONV_STD_LOGIC_VECTOR(16#02#, tst_fms_cs_tx'length) when fsm_ip_tx_cs=S_TX_ACK      else
               CONV_STD_LOGIC_VECTOR(16#03#, tst_fms_cs_tx'length) when fsm_ip_tx_cs=S_TX_DONE     else
               CONV_STD_LOGIC_VECTOR(16#04#, tst_fms_cs_tx'length) when fsm_ip_tx_cs=S_TX_UDP_H0   else
               CONV_STD_LOGIC_VECTOR(16#05#, tst_fms_cs_tx'length) when fsm_ip_tx_cs=S_TX_UDP_HN   else
               CONV_STD_LOGIC_VECTOR(16#06#, tst_fms_cs_tx'length) when fsm_ip_tx_cs=S_TX_UDP_D    else
               CONV_STD_LOGIC_VECTOR(16#07#, tst_fms_cs_tx'length) when fsm_ip_tx_cs=S_TX_DHCP_0   else
               CONV_STD_LOGIC_VECTOR(16#08#, tst_fms_cs_tx'length) when fsm_ip_tx_cs=S_TX_DHCP_1   else
               CONV_STD_LOGIC_VECTOR(16#00#, tst_fms_cs_tx'length);-- when fsm_ip_tx_cs=S_TX_IDLE     else

end generate gen_dbg_on;


--//-------------------------------------------
--//Сохраняем данны RxEthPkt для анализа
--//-------------------------------------------
process(p_in_rst,p_in_clk)
begin
  if p_in_rst='1' then
    for i in 0 to i_hreg_d'length-1 loop
    i_hreg_d(i) <= (others=>'0');
    end loop;
    i_hreg_a <= (others=>'0');
    i_hreg_wr <= '0';

  elsif p_in_clk'event and p_in_clk='1' then

    if i_hreg_wr='0' and p_in_rxll_sof_n='0' and p_in_rxll_src_rdy_n='0' then
      i_hreg_wr <= '1';
      i_hreg_a <= i_hreg_a + 1;
      i_hreg_d(0) <= p_in_rxll_data;

    elsif i_hreg_wr='1' and p_in_rxll_src_rdy_n='0' then

        for i in 1 to i_hreg_d'length-1 loop
          if i_hreg_a=i then
            i_hreg_d(i) <= p_in_rxll_data;
          end if;
        end loop;

        if i_hreg_a=CONV_STD_LOGIC_VECTOR(i_hreg_d'length - 1, i_hreg_a'length) or p_in_rxll_eof_n='0' then
          i_hreg_a <= (others=>'0');
          i_hreg_wr <= '0';
        else
          i_hreg_a <= i_hreg_a + 1;
        end if;

    end if;

  end if;
end process;
--Детектирование IP + MAC адресов
gen_rx_mac_check : for i in 0 to i_fpga_mac'length - 1 generate
i_rx_mac_valid(i)<='1' when i_hreg_d(i) = i_fpga_mac(i) else '0';
i_rx_mac_broadcast(i)<='1' when i_hreg_d(i) = CONV_STD_LOGIC_VECTOR(16#FF#, i_hreg_d(i)'length) else '0';
end generate gen_rx_mac_check;

gen_rx_ip_check : for i in 0 to i_fpga_ip'length - 1 generate
i_rx_ip_valid(i)<='1' when i_hreg_d(30 + i) = i_fpga_ip(i) else '0';
i_rx_ip_broadcast(i)<='1' when i_hreg_d(30 + i) = CONV_STD_LOGIC_VECTOR(16#FF#, i_hreg_d(i)'length) else '0';
end generate gen_rx_ip_check;

--Установка IP + MAC адресов + UDP портов
i_fpga_udp_port <= p_in_cfg.prt.src;
i_host_udp_port <= p_in_cfg.prt.dst;

gen_dhcp_use_on : if CI_DHCP_USE='1' generate
gen_set_ip : for i in 0 to i_fpga_ip'length-1 generate
i_fpga_ip(i) <= i_dhcp_client_ip(i);
i_host_ip(i) <= i_dhcp_server_ip(i);
end generate gen_set_ip;

gen_set_mac : for i in 0 to i_host_mac'length-1 generate
i_fpga_mac(i) <= p_in_cfg.mac.src(i);
i_host_mac(i) <= i_dhcp_server_mac(i);
end generate gen_set_mac;
end generate gen_dhcp_use_on;

gen_dhcp_use_off : if CI_DHCP_USE='0' generate
gen_set_ip : for i in 0 to i_fpga_ip'length-1 generate
i_fpga_ip(i) <= p_in_cfg.ip.src(i);
i_host_ip(i) <= p_in_cfg.ip.dst(i);
end generate gen_set_ip;

gen_set_mac : for i in 0 to i_host_mac'length-1 generate
i_fpga_mac(i) <= p_in_cfg.mac.src(i);
i_host_mac(i) <= p_in_cfg.mac.dst(i);
end generate gen_set_mac;
end generate gen_dhcp_use_off;


--//-------------------------------------------
--//RxEthPkt
--//-------------------------------------------
p_out_rxbuf_din <=i_rx_d;
p_out_rxbuf_wr <= (i_rx_en or i_rx_eof);
p_out_rxd_sof <= i_rx_sof when i_rx_sof_ext='0' else i_rx_eof;
p_out_rxd_eof <= i_rx_eof;

p_out_rxll_dst_rdy_n <= i_rxll_dst_rdy_n;

process(p_in_rst,p_in_clk)
begin
  if p_in_rst='1' then
    fsm_ip_rx_cs<=S_RX_IDLE;

    i_rxll_dst_rdy_n <= '0';
    i_tx_req <= (others=>'0');
    i_crc_start <= '0';

    i_rx_bcnt <= (others=>'0');
    i_rx_fst <= '0';
    i_rx_d <= (others=>'0');
    i_rx_en <= '0';
    i_rx_sof <= '0';
    i_rx_eof <= '0';
    i_rx_sof_ext <= '0';
    for i in 0 to sr_rx_d'length-1 loop
    sr_rx_d(i) <= (others=>'0');
    end loop;

    i_dhcp_discover_tx_done <= '0'; tst_dhcp <= '0';
    i_dhcp_get_prm_done <= '0';
    for i in 0 to i_dhcp_server_ip'length-1 loop
    i_dhcp_server_ip(i) <= (others=>'0');
    i_dhcp_client_ip(i) <= (others=>'0');
    end loop;

    for i in 0 to i_dhcp_server_mac'length-1 loop
    i_dhcp_server_mac(i) <= (others=>'0');
    end loop;

  elsif p_in_clk'event and p_in_clk='1' then

        case fsm_ip_rx_cs is

          --------------------------------------
          --
          --------------------------------------
          when S_RX_IDLE =>

              i_rxll_dst_rdy_n <= '0'; tst_dhcp <= '0';

              i_rx_bcnt <= (others=>'0');
              i_rx_fst <= '0';
              i_rx_d <= (others=>'0');
              i_rx_en <= '0';
              i_rx_sof <= '0';
              i_rx_eof <= '0';
              i_rx_sof_ext <= '0';

            if i_dhcp_discover_tx_done='0' and CI_DHCP_USE='1' then
                if p_in_link='1' then
                    i_tx_req <= CONV_STD_LOGIC_VECTOR(CI_TX_REQ_DHCP_DISCOVER, i_tx_req'length);
                    i_rxll_dst_rdy_n <= '1';
                    i_crc_start <= '1';
                    fsm_ip_rx_cs <= S_RX_WAIT_TX_DONE;
                end if;
            else
              if p_in_rxll_src_rdy_n='0' and i_rxll_dst_rdy_n='0' and
                  i_hreg_a=CONV_STD_LOGIC_VECTOR(CI_HREG_ETH_TYPE + 2, i_hreg_a'length) then

                  --MAC: (Dst)
                  if (AND_reduce(i_rx_mac_broadcast)='1' or AND_reduce(i_rx_mac_valid)='1') then

                      --EthPkt Type:
                      if (i_hreg_d(CI_HREG_ETH_TYPE + 0) & i_hreg_d(CI_HREG_ETH_TYPE + 1))=CI_ETH_TYPE_ARP then
                        fsm_ip_rx_cs <= S_RX_ARP;

                      elsif (i_hreg_d(CI_HREG_ETH_TYPE + 0) & i_hreg_d(CI_HREG_ETH_TYPE + 1))=CI_ETH_TYPE_IP then
                        fsm_ip_rx_cs <= S_RX_IP;

                      end if;
                  else

                    fsm_ip_rx_cs <= S_RX_WAIT_DONE;
                  end if;

              end if;
            end if;
          --------------------------------------
          --ARP:
          --------------------------------------
          when S_RX_ARP =>

            if i_dhcp_get_prm_done='0' and  CI_DHCP_USE='1' then
              fsm_ip_rx_cs <= S_RX_WAIT_DONE;
            else
              if (p_in_rxll_src_rdy_n='0' and p_in_rxll_eof_n='0') then

                  if (i_hreg_d(CI_HREG_ARP_HTYPE + 0) & i_hreg_d(CI_HREG_ARP_HTYPE + 1))=CI_ARP_HTYPE and
                     (i_hreg_d(CI_HREG_ARP_PTYPE + 0) & i_hreg_d(CI_HREG_ARP_PTYPE + 1))=CI_ETH_TYPE_IP and
                     (i_hreg_d(CI_HREG_ARP_HPLEN + 0) & i_hreg_d(CI_HREG_ARP_HPLEN + 1))=CI_ARP_HPLEN and
                     (i_hreg_d(CI_HREG_ARP_OPER  + 0) & i_hreg_d(CI_HREG_ARP_OPER  + 1))=CI_ARP_OPER_REQUEST then

                        i_tx_req <= CONV_STD_LOGIC_VECTOR(CI_TX_REQ_ARP_ACK, i_tx_req'length);
                        i_rxll_dst_rdy_n <= '1';

                        fsm_ip_rx_cs <= S_RX_WAIT_TX_DONE;
                    else
                        fsm_ip_rx_cs <= S_RX_IDLE;
                    end if;

              end if;
            end if;

          --------------------------------------
          --IP:
          --------------------------------------
          when S_RX_IP =>

              if p_in_rxll_src_rdy_n='0' and
                 i_hreg_a=CONV_STD_LOGIC_VECTOR(CI_HREG_ICMP_OPER, i_hreg_a'length) then

                  if (AND_reduce(i_rx_ip_valid)='1' or (AND_reduce(i_rx_ip_broadcast)='1' and i_dhcp_get_prm_done='0' and  CI_DHCP_USE='1')) and
                      i_hreg_d(CI_HREG_IP_VER)=(CONV_STD_LOGIC_VECTOR(CI_IP_VER, 4) & CONV_STD_LOGIC_VECTOR(CI_IP_HEADER_SIZE/4, 4)) then

                      if i_hreg_d(CI_HREG_IP_PROTOCOL)=CI_IP_PTYPE_ICMP then
                        fsm_ip_rx_cs <= S_RX_ICMP;

                      elsif i_hreg_d(CI_HREG_IP_PROTOCOL)=CI_IP_PTYPE_UDP then
                        fsm_ip_rx_cs <= S_RX_UDP_PORT;

                      else
                        fsm_ip_rx_cs <= S_RX_IDLE;
                      end if;
                  else
                    fsm_ip_rx_cs <= S_RX_IDLE;
                  end if;

              end if;

          --------------------------------------
          --ICMP:
          --------------------------------------
          when S_RX_ICMP =>

            if i_dhcp_get_prm_done='0' and  CI_DHCP_USE='1' then
              fsm_ip_rx_cs <= S_RX_WAIT_DONE;
            else
              if p_in_rxll_src_rdy_n='0' then

                  if i_hreg_d(CI_HREG_ICMP_OPER)=CI_ICMP_OPER_REQUEST then

                      if p_in_rxll_eof_n='0' then
                          i_tx_req <= CONV_STD_LOGIC_VECTOR(CI_TX_REQ_ICMP_ACK, i_tx_req'length);
                          i_rxll_dst_rdy_n <= '1';
                          i_crc_start <= '1';
                          fsm_ip_rx_cs <= S_RX_WAIT_TX_DONE;
                      end if;
                  else
                     fsm_ip_rx_cs <= S_RX_IDLE;
                  end if;

              end if;
            end if;

          --------------------------------------
          --UDP:
          --------------------------------------
          when S_RX_UDP_PORT =>

              if p_in_rxll_src_rdy_n='0' and
                i_hreg_a=CONV_STD_LOGIC_VECTOR(37, i_hreg_a'length) then

                  --Проверяем DST PORT принимаемого UDP Pkt
                  if (i_hreg_d(36) & p_in_rxll_data)=i_fpga_udp_port then
                    fsm_ip_rx_cs <= S_RX_UDP_DLEN;

                  elsif (i_hreg_d(36) & p_in_rxll_data)=CI_UDP_PORT_DHCP_CLIENT and i_dhcp_get_prm_done='0' then
                    fsm_ip_rx_cs <= S_RX_DHCP_0; tst_dhcp <= '1';

                  else
                    fsm_ip_rx_cs <= S_RX_IDLE;
                  end if;

                  for i in 0 to sr_rx_d'length-1 loop
                  sr_rx_d(i) <= (others=>'0');
                  end loop;

              end if;

          --вычисляем размер пользовательских данных и выдаем полученое значение в USR RxBUF
          when S_RX_UDP_DLEN =>

            if i_dhcp_get_prm_done='0' and  CI_DHCP_USE='1' then
              fsm_ip_rx_cs <= S_RX_WAIT_DONE;
            else
              if p_in_rxll_src_rdy_n='0' then
                if i_rx_bcnt(0)='1' then
                  i_rx_d(15 downto 0) <= (sr_rx_d(0) & p_in_rxll_data) - CONV_STD_LOGIC_VECTOR(CI_UDP_HEADER_SIZE, 16);
                  fsm_ip_rx_cs <= S_RX_UDP_CRC;
                else
                  sr_rx_d(0) <= p_in_rxll_data;
                end if;

                i_rx_bcnt <= i_rx_bcnt + 1;
              end if;
            end if;

          --пропускаем данные CRC
          when S_RX_UDP_CRC =>

              if p_in_rxll_src_rdy_n='0' then
                if i_rx_bcnt=CONV_STD_LOGIC_VECTOR(4-1, i_rx_bcnt'length) then
                  i_rx_bcnt <= CONV_STD_LOGIC_VECTOR(2, i_rx_bcnt'length);
                  fsm_ip_rx_cs <= S_RX_UDP_D;
                else
                  i_rx_bcnt <= i_rx_bcnt + 1;
                end if;

                if i_rx_d(15 downto 0)<CONV_STD_LOGIC_VECTOR(2, i_rx_d'length) then
                  i_rx_sof_ext <= '1';
                end if;
              end if;

          --принимаем пользовательские данные в USR RxBUF
          when S_RX_UDP_D =>

              if p_in_rxll_src_rdy_n='0' then

                  for i in 0 to 3 loop
                    if i_rx_bcnt=i then
                      i_rx_d(8*(i+1)-1 downto 8*i) <= p_in_rxll_data;
                    end if;
                  end loop;

                  i_rx_bcnt <= i_rx_bcnt + 1;

                  if AND_reduce(i_rx_bcnt)='1' then
                    i_rx_fst <= '1';
                  end if;

                  i_rx_en <= AND_reduce(i_rx_bcnt);
                  i_rx_sof <= AND_reduce(i_rx_bcnt) and not i_rx_fst;

                  if p_in_rxll_eof_n='0' then
                    i_rx_eof <= '1';
                    i_rxll_dst_rdy_n <= '1';
                    fsm_ip_rx_cs <= S_RX_IDLE;
                  end if;

              end if;

          --------------------------------------
          --Ждем завершения отправки EthPkt
          --------------------------------------
          when S_RX_WAIT_TX_DONE =>

            i_crc_start <= '0';

            if i_tx_done='1' then
              i_tx_req <= (others=> '0');
              if i_tx_req = CONV_STD_LOGIC_VECTOR(CI_TX_REQ_DHCP_DISCOVER, i_tx_req'length) then
                i_dhcp_discover_tx_done <= '1';
              end if;

              fsm_ip_rx_cs <= S_RX_IDLE;
            end if;

          --------------------------------------
          --Ждем завершения приема текущего EthPkt
          --------------------------------------
          when S_RX_WAIT_DONE =>

            if (p_in_rxll_src_rdy_n='0' and p_in_rxll_eof_n='0') then
              fsm_ip_rx_cs <= S_RX_IDLE;
            end if;

          --------------------------------------
          --DHCP:
          --------------------------------------
          when S_RX_DHCP_0 =>

            if CI_DHCP_USE='0' then
              fsm_ip_rx_cs <= S_RX_DHCP_1;
            else
              if p_in_rxll_src_rdy_n='0' then
                if i_hreg_a=CONV_STD_LOGIC_VECTOR(i_hreg_d'length - 1, i_hreg_a'length) and
                  i_hreg_d(42)=CI_DHCP_OPER_REPLY and
                  i_hreg_d(43)=CONV_STD_LOGIC_VECTOR(1, 8) and
                  i_hreg_d(44)=CONV_STD_LOGIC_VECTOR(6, 8) and
                  i_hreg_d(46)=i_dhcp_xid( 7 downto  0) and
                  i_hreg_d(47)=i_dhcp_xid(15 downto  8) and
                  i_hreg_d(48)=i_dhcp_xid(23 downto 16) and
                  i_hreg_d(49)=i_dhcp_xid(31 downto 24) then

                  fsm_ip_rx_cs <= S_RX_DHCP_1;
                end if;
              end if;
            end if;

          --Ищем DHCP_MAGIC_COOKIE
          when S_RX_DHCP_1 =>

            if CI_DHCP_USE='0' then
              fsm_ip_rx_cs <= S_RX_DHCP_2;
            else
              if p_in_rxll_src_rdy_n='0' then

                  if p_in_rxll_data = CI_DHCP_MAGIC_COOKIE(31 downto 24) and
                         sr_rx_d(0) = CI_DHCP_MAGIC_COOKIE(23 downto 16) and
                         sr_rx_d(1) = CI_DHCP_MAGIC_COOKIE(15 downto  8) and
                         sr_rx_d(2) = CI_DHCP_MAGIC_COOKIE( 7 downto  0) then

                    fsm_ip_rx_cs <= S_RX_DHCP_2;

                  elsif p_in_rxll_eof_n='0' then
                    fsm_ip_rx_cs <= S_RX_IDLE;

                  end if;

                  sr_rx_d <= sr_rx_d(1 downto 0) & p_in_rxll_data;

              end if;
            end if;

          --Ищем тип ответа
          when S_RX_DHCP_2 =>

            if CI_DHCP_USE='0' then
              fsm_ip_rx_cs <= S_RX_DHCP_3;
            else
              if p_in_rxll_src_rdy_n='0' then

                  if p_in_rxll_data = CI_DHCP_DHCPOFFER and
                         sr_rx_d(0) = CONV_STD_LOGIC_VECTOR(1, 8) and
                         sr_rx_d(1) = CI_DHCP_CODE_53 then

                    fsm_ip_rx_cs <= S_RX_DHCP_3;

                  elsif p_in_rxll_data = CI_DHCP_DHCPACK and
                            sr_rx_d(0) = CONV_STD_LOGIC_VECTOR(1, 8) and
                            sr_rx_d(1) = CI_DHCP_CODE_53 then

                    i_dhcp_get_prm_done <= '1';
                    fsm_ip_rx_cs <= S_RX_DHCP_3;

                  elsif p_in_rxll_eof_n='0' then
                    fsm_ip_rx_cs <= S_RX_IDLE;

                  end if;

                  sr_rx_d <= sr_rx_d(1 downto 0) & p_in_rxll_data;

              end if;
            end if;

          --Ждем завершения текущего пакета и копируем принятые параметры
          when S_RX_DHCP_3 =>

            if CI_DHCP_USE='0' then
              fsm_ip_rx_cs <= S_RX_WAIT_DONE;
            else
              if p_in_rxll_src_rdy_n='0' and p_in_rxll_eof_n='0' then

                  i_dhcp_server_mac(0) <= i_hreg_d(0); --MAC Dst:
                  i_dhcp_server_mac(1) <= i_hreg_d(1);
                  i_dhcp_server_mac(2) <= i_hreg_d(2);
                  i_dhcp_server_mac(3) <= i_hreg_d(3);
                  i_dhcp_server_mac(4) <= i_hreg_d(4);
                  i_dhcp_server_mac(5) <= i_hreg_d(5);

                  i_dhcp_server_ip(0) <= i_hreg_d(26); --IP: ip_src
                  i_dhcp_server_ip(1) <= i_hreg_d(27);
                  i_dhcp_server_ip(2) <= i_hreg_d(28);
                  i_dhcp_server_ip(3) <= i_hreg_d(29);

                  i_dhcp_client_ip(0) <= i_hreg_d(58); --DHCP: YIADDR
                  i_dhcp_client_ip(1) <= i_hreg_d(59);
                  i_dhcp_client_ip(2) <= i_hreg_d(60);
                  i_dhcp_client_ip(3) <= i_hreg_d(61);

                  if i_dhcp_get_prm_done='0' then
                    i_tx_req <= CONV_STD_LOGIC_VECTOR(CI_TX_REQ_DHCP_REQUEST, i_tx_req'length);
                    i_rxll_dst_rdy_n <= '1';
                    i_crc_start <= '1';
                    fsm_ip_rx_cs <= S_RX_WAIT_TX_DONE;

                  else
                    i_dhcp_get_prm_done <= '1';

                    fsm_ip_rx_cs <= S_RX_IDLE;

                  end if;
              end if;
            end if;

        end case;

  end if;
end process;



--//-------------------------------------------
--//TxEthPkt
--//-------------------------------------------
p_out_txll_data      <= i_txll_data;
p_out_txll_sof_n     <= i_txll_sof_n;
p_out_txll_eof_n     <= i_txll_eof_n;
p_out_txll_src_rdy_n <= i_txll_src_rdy_n;
p_out_txll_rem       <= i_txll_rem;

p_out_txbuf_rd<=not p_in_txbuf_empty and i_usr_txd_rden and (i_usr_txd_rd or AND_reduce(i_tx_bcnt)) and not p_in_txll_dst_rdy_n;

process(p_in_rst,p_in_clk)
begin
  if p_in_rst='1' then
    fsm_ip_tx_cs<=S_TX_IDLE;

    i_tx_dlen <= (others=>'0');
    i_tx_dcnt <= (others=>'0');
    i_tx_done <= '0';

    i_txll_data <= (others=>'0');
    i_txll_sof_n <= '1';
    i_txll_eof_n <= '1';
    i_txll_src_rdy_n <= '1';

    i_tx_pktid <=(others=>'0');

    i_usr_txd_rd<='0';
    i_usr_txd_rden<='0';
    i_tx_bcnt<=(others=>'0');

    i_udpip_crc_start <= '0';

  elsif p_in_clk'event and p_in_clk='1' then

    if p_in_txll_dst_rdy_n='0' then

        case fsm_ip_tx_cs is

          --------------------------------------
          --
          --------------------------------------
          when S_TX_IDLE =>

            i_tx_done <= '0';

            if i_tx_req = CONV_STD_LOGIC_VECTOR(CI_TX_REQ_ARP_ACK, i_tx_req'length) or
               i_tx_req = CONV_STD_LOGIC_VECTOR(CI_TX_REQ_ICMP_ACK, i_tx_req'length) or
               i_tx_req = CONV_STD_LOGIC_VECTOR(CI_TX_REQ_DHCP_DISCOVER, i_tx_req'length) or
               i_tx_req = CONV_STD_LOGIC_VECTOR(CI_TX_REQ_DHCP_REQUEST, i_tx_req'length) then

              fsm_ip_tx_cs <= S_TX_ACK_DLY;

            elsif p_in_txbuf_empty='0' then

              i_tx_dlen<=p_in_txbuf_dout(15 downto 0);--usr dlen (byte)
              i_udpip_crc_start <= '1';
              i_tx_pktid <= i_tx_pktid + 1;
              fsm_ip_tx_cs<=S_TX_UDP_H0;

            end if;

          --------------------------------------
          --Линия задержки (для того чтоб успеть вычислить CRC)
          --------------------------------------
          when S_TX_ACK_DLY =>

              if i_tx_dcnt=CONV_STD_LOGIC_VECTOR(16#04#, i_tx_dcnt'length) then

                  i_tx_dcnt <= CONV_STD_LOGIC_VECTOR(16#01#, i_tx_dcnt'length);
                  if i_tx_req=CONV_STD_LOGIC_VECTOR(CI_TX_REQ_ARP_ACK, i_tx_req'length) then
                    i_txll_data <= i_arp_ack(0);

                  elsif i_tx_req=CONV_STD_LOGIC_VECTOR(CI_TX_REQ_ICMP_ACK, i_tx_req'length) then
                    i_txll_data <= i_icmp_ack(0);

                  elsif i_tx_req=CONV_STD_LOGIC_VECTOR(CI_TX_REQ_DHCP_DISCOVER, i_tx_req'length) or
                        i_tx_req=CONV_STD_LOGIC_VECTOR(CI_TX_REQ_DHCP_REQUEST, i_tx_req'length) then
                    i_txll_data <= i_dhcp_pkt(0);

                  end if;

                  i_txll_sof_n <= '0';
                  i_txll_src_rdy_n <= '0';
                  i_tx_pktid <= i_tx_pktid + 1;

                  fsm_ip_tx_cs <= S_TX_ACK;
              else
                i_tx_dcnt <= i_tx_dcnt + 1;
              end if;

          --------------------------------------
          --Отправка ответов для соответствующих протоколов
          --------------------------------------
          when S_TX_ACK =>

              for i in 0 to i_hreg_d'length-1 loop
                if i_tx_dcnt=i then
                  if i_tx_req=CONV_STD_LOGIC_VECTOR(CI_TX_REQ_ARP_ACK, i_tx_req'length) then
                    i_txll_data <= i_arp_ack(i);

                  elsif i_tx_req=CONV_STD_LOGIC_VECTOR(CI_TX_REQ_ICMP_ACK, i_tx_req'length) then
                    i_txll_data <= i_icmp_ack(i);

                  elsif i_tx_req=CONV_STD_LOGIC_VECTOR(CI_TX_REQ_DHCP_DISCOVER, i_tx_req'length) or
                        i_tx_req=CONV_STD_LOGIC_VECTOR(CI_TX_REQ_DHCP_REQUEST, i_tx_req'length) then

                    i_txll_data <= i_dhcp_pkt(i);
                  end if;
                end if;
              end loop;

              i_txll_sof_n <= '1';
              i_txll_src_rdy_n <= '0';

              if (i_tx_dcnt=(i_arp_ack_ereg - 1) and i_tx_req=CONV_STD_LOGIC_VECTOR(CI_TX_REQ_ARP_ACK, i_tx_req'length)) or
                 (i_tx_dcnt=(i_icmp_ack_ereg - 1) and i_tx_req=CONV_STD_LOGIC_VECTOR(CI_TX_REQ_ICMP_ACK, i_tx_req'length)) or
                 (i_tx_dcnt=(i_dhcp_ereg0 - 1) and (i_tx_req=CONV_STD_LOGIC_VECTOR(CI_TX_REQ_DHCP_DISCOVER, i_tx_req'length) or
                                                    i_tx_req=CONV_STD_LOGIC_VECTOR(CI_TX_REQ_DHCP_REQUEST, i_tx_req'length))) then

                  if i_tx_req=CONV_STD_LOGIC_VECTOR(CI_TX_REQ_ARP_ACK, i_tx_req'length) or
                     i_tx_req=CONV_STD_LOGIC_VECTOR(CI_TX_REQ_ICMP_ACK, i_tx_req'length) then
                    i_tx_dcnt <= (others=>'0');
                    i_tx_done <= '1';
                    i_txll_eof_n <= '0';
                    fsm_ip_tx_cs <= S_TX_DONE;
                  else
                    i_tx_dcnt <= (others=>'0');
                    fsm_ip_tx_cs <= S_TX_DHCP_0;
                  end if;
              else
                i_tx_dcnt <= i_tx_dcnt + 1;
              end if;

          --------------------------------------
          --
          --------------------------------------
          when S_TX_DONE =>

              i_tx_bcnt<=(others=>'0');
              i_tx_dcnt<=(others=>'0');

              i_txll_sof_n<='1';
              i_txll_eof_n<='1';
              i_txll_src_rdy_n<='1';
              i_txll_rem<=(others=>'0');

              i_usr_txd_rd<='0';
              i_usr_txd_rden<='0';

              i_tx_done <= '0';

              fsm_ip_tx_cs <= S_TX_IDLE;

          --------------------------------------
          --UDP: usr data
          --------------------------------------
          --MAC+EthType+IP(header)+UDP(header)
          when S_TX_UDP_H0 =>

              i_udpip_crc_start <= '0';
              i_txll_src_rdy_n<='0';
              i_txll_sof_n<='0';
              i_txll_eof_n<='1';
              i_txll_data<=i_udp_pkt(0);

              i_tx_dcnt<=i_tx_dcnt + 1;

              fsm_ip_tx_cs<=S_TX_UDP_HN;

          when S_TX_UDP_HN =>

              i_txll_src_rdy_n<='0';
              i_txll_sof_n<='1';
              i_txll_eof_n<='1';

              for i in 0 to 42-1 loop
                if i_tx_dcnt=i then
                  i_txll_data<=i_udp_pkt(i);
                end if;
              end loop;

              if i_tx_dcnt=CONV_STD_LOGIC_VECTOR(42-1, i_tx_dcnt'length) then
                i_tx_dcnt<=(others=>'0');
                i_tx_bcnt<=CONV_STD_LOGIC_VECTOR(2, i_tx_bcnt'length);

                i_usr_txd_rden<='1';
                fsm_ip_tx_cs<=S_TX_UDP_D;
              else
                i_tx_dcnt<=i_tx_dcnt + 1;
              end if;

          --Usr data
          when S_TX_UDP_D =>

            i_txll_src_rdy_n<=p_in_txbuf_empty;
            i_txll_sof_n<='1';

            if p_in_txbuf_empty='0' then

                if i_tx_dcnt=i_tx_dlen - 1 then
                  i_txll_rem<=not i_tx_dcnt(0 downto 0);
                  i_tx_dcnt<=(others=>'0');
                  i_txll_eof_n<='0';

                  if AND_reduce(i_tx_bcnt)='0' then
                    i_usr_txd_rd<='1';
                  end if;

                  i_tx_done <= '1';
                  fsm_ip_tx_cs<=S_TX_DONE;
                else
                  i_tx_dcnt<=i_tx_dcnt + 1;--счетчик байт передоваемых данных
                  i_txll_eof_n<='1';
                end if;

                --//Данные
                  for i in 0 to p_in_txbuf_dout'length/i_txll_data'length - 1 loop
                    if i_tx_bcnt=i then
                      i_txll_data<=p_in_txbuf_dout(8*(i_txll_data'length/8)*(i+1)-1 downto 8*(i_txll_data'length/8)*i);
                    end if;
                  end loop;

                i_tx_bcnt<=i_tx_bcnt + 1;--счетчик байт порта входных данных p_in_txbuf_dout

            end if;--if p_in_txbuf_empty='0' then

          --------------------------------------
          --
          --------------------------------------
          when S_TX_DHCP_0 =>

              if i_tx_dcnt=CONV_STD_LOGIC_VECTOR(CI_DHCP_FIELD_SNAME_SIZE + CI_DHCP_FIELD_FILE_SIZE - 1, i_tx_dcnt'length) then
                i_tx_dcnt <= CONV_STD_LOGIC_VECTOR(86, i_tx_dcnt'length);
                i_txll_data <= i_dhcp_pkt(86);
                fsm_ip_tx_cs <= S_TX_DHCP_1;
              else
                i_txll_data <= (others=>'0');
                i_tx_dcnt <= i_tx_dcnt + 1;
              end if;

          when S_TX_DHCP_1 =>

              for i in 86 to i_hreg_d'length-1 loop
                if i_tx_dcnt=i then
                  i_txll_data <= i_dhcp_pkt(i);
                end if;
              end loop;

              if i_tx_dcnt=(i_dhcp_ereg1) then
                i_txll_data <= (others=>'1');
                i_tx_dcnt <= (others=>'0');
                i_tx_done <= '1';
                i_txll_eof_n <= '0';
                fsm_ip_tx_cs <= S_TX_DONE;
              else
                i_tx_dcnt <= i_tx_dcnt + 1;
              end if;

          end case;

    end if;-- p_in_txll_dst_rdy_n='0' then
  end if;
end process;


----------------------------------
--ARP ответ
----------------------------------
--MAC адреса
i_arp_ack(0)  <= i_hreg_d(6);  --MAC Dst:
i_arp_ack(1)  <= i_hreg_d(7);
i_arp_ack(2)  <= i_hreg_d(8);
i_arp_ack(3)  <= i_hreg_d(9);
i_arp_ack(4)  <= i_hreg_d(10);
i_arp_ack(5)  <= i_hreg_d(11);
i_arp_ack(6)  <= i_fpga_mac(0);--MAC Src
i_arp_ack(7)  <= i_fpga_mac(1);
i_arp_ack(8)  <= i_fpga_mac(2);
i_arp_ack(9)  <= i_fpga_mac(3);
i_arp_ack(10) <= i_fpga_mac(4);
i_arp_ack(11) <= i_fpga_mac(5);
--Eth type
i_arp_ack(12) <= i_hreg_d(12);
i_arp_ack(13) <= i_hreg_d(13);
--ARP
i_arp_ack(14) <= i_hreg_d(14); --ARP: HTYPE
i_arp_ack(15) <= i_hreg_d(15);
i_arp_ack(16) <= i_hreg_d(16); --ARP: PTYPE
i_arp_ack(17) <= i_hreg_d(17);
i_arp_ack(18) <= i_hreg_d(18); --ARP: HLEN
i_arp_ack(19) <= i_hreg_d(19); --ARP: PLEN
i_arp_ack(20) <= CI_ARP_OPER_REPLY(15 downto 8);--ARP:  OPERATION
i_arp_ack(21) <= CI_ARP_OPER_REPLY( 7 downto 0);
i_arp_ack(22) <= i_fpga_mac(0);--ARP: MAC src
i_arp_ack(23) <= i_fpga_mac(1);
i_arp_ack(24) <= i_fpga_mac(2);
i_arp_ack(25) <= i_fpga_mac(3);
i_arp_ack(26) <= i_fpga_mac(4);
i_arp_ack(27) <= i_fpga_mac(5);
i_arp_ack(28) <= i_fpga_ip(0); --ARP: IP src
i_arp_ack(29) <= i_fpga_ip(1);
i_arp_ack(30) <= i_fpga_ip(2);
i_arp_ack(31) <= i_fpga_ip(3);
i_arp_ack(32) <= i_hreg_d(22); --ARP: MAC dst
i_arp_ack(33) <= i_hreg_d(23);
i_arp_ack(34) <= i_hreg_d(24);
i_arp_ack(35) <= i_hreg_d(25);
i_arp_ack(36) <= i_hreg_d(26);
i_arp_ack(37) <= i_hreg_d(27);
i_arp_ack(38) <= i_hreg_d(28); --ARP: IP dst
i_arp_ack(39) <= i_hreg_d(29);
i_arp_ack(40) <= i_hreg_d(30);
i_arp_ack(41) <= i_hreg_d(31);
gen_ack_null : for i in 42 to i_hreg_d'length-1 generate
i_arp_ack(i) <= (others=>'0');
end generate gen_ack_null;

--вычисляем адрес последнего региста в котором содержатся данные ARP запроса:
--i_arp_ack_ereg = кол-во байт(ARP запроса) + кол-во байт(MAC_DST+MAC_DST+ETH_TYPE)
i_arp_ack_ereg <= CONV_STD_LOGIC_VECTOR(28 + 14, i_arp_ack_ereg'length);

----------------------------------
--ICMP ответ
----------------------------------
--MAC адреса
i_icmp_ack(0)  <= i_hreg_d(6);  --MAC Dst:
i_icmp_ack(1)  <= i_hreg_d(7);
i_icmp_ack(2)  <= i_hreg_d(8);
i_icmp_ack(3)  <= i_hreg_d(9);
i_icmp_ack(4)  <= i_hreg_d(10);
i_icmp_ack(5)  <= i_hreg_d(11);
i_icmp_ack(6)  <= i_hreg_d(0);  --MAC Src:
i_icmp_ack(7)  <= i_hreg_d(1);
i_icmp_ack(8)  <= i_hreg_d(2);
i_icmp_ack(9)  <= i_hreg_d(3);
i_icmp_ack(10) <= i_hreg_d(4);
i_icmp_ack(11) <= i_hreg_d(5);
--Eth type
i_icmp_ack(12) <= i_hreg_d(12); --Eth type
i_icmp_ack(13) <= i_hreg_d(13);
--IP
i_icmp_ack(14) <= i_hreg_d(14); --IP: ip ver + ip header size
i_icmp_ack(15) <= i_hreg_d(15); --IP: ToS (тип обслуживания)
i_icmp_ack(16) <= i_hreg_d(16); --IP: dlen
i_icmp_ack(17) <= i_hreg_d(17);
i_icmp_ack(18) <= i_tx_pktid(15 downto 8);--IP: id
i_icmp_ack(19) <= i_tx_pktid( 7 downto 0);
i_icmp_ack(20) <= i_hreg_d(20); --IP: flag
i_icmp_ack(21) <= i_hreg_d(21);
i_icmp_ack(22) <= CI_IP_TTL;
i_icmp_ack(23) <= i_hreg_d(23); --IP: protocol
i_icmp_ack(24) <= (others=>'0') when i_ip_crc_rdy='0' else i_ip_crc(15 downto 8); --IP: CRC
i_icmp_ack(25) <= (others=>'0') when i_ip_crc_rdy='0' else i_ip_crc( 7 downto 0);
i_icmp_ack(26) <= i_hreg_d(30); --IP: ip_src - для кого ICMP ответ
i_icmp_ack(27) <= i_hreg_d(31);
i_icmp_ack(28) <= i_hreg_d(32);
i_icmp_ack(29) <= i_hreg_d(33);
i_icmp_ack(30) <= i_hreg_d(26); --IP: ip_dst - от кого ICMP запрос
i_icmp_ack(31) <= i_hreg_d(27);
i_icmp_ack(32) <= i_hreg_d(28);
i_icmp_ack(33) <= i_hreg_d(29);
--ICMP
i_icmp_ack(34) <= CI_ICMP_OPER_ECHO_REPLY;--ICMP: Operation
i_icmp_ack(35) <= i_hreg_d(35);
i_icmp_ack(36) <= (others=>'0') when i_icmp_crc_rdy='0' else i_icmp_crc(15 downto 8); --ICMP: CRC
i_icmp_ack(37) <= (others=>'0') when i_icmp_crc_rdy='0' else i_icmp_crc( 7 downto 0);
gen_icmp_ack : for i in 38 to i_hreg_d'length-1 generate
i_icmp_ack(i) <= i_hreg_d(i);
end generate gen_icmp_ack;

--вычисляем адрес последнего региста в котором содержатся данные ICMP запроса:
--i_icmp_ack_ereg = IP_totallen + кол-во байт(MAC_DST+MAC_DST+ETH_TYPE)
i_icmp_ack_ereg <= (i_hreg_d(16)&i_hreg_d(17)) + CONV_STD_LOGIC_VECTOR(14, i_icmp_ack_ereg'length);

--Расчет CRC:
i_icmp_crc_tmp2<=i_icmp_crc_tmp(31 downto 16) + i_icmp_crc_tmp(15 downto 0);
gen_icmp_crc : for i in 0 to i_icmp_crc'length-1 generate
i_icmp_crc(i) <= not i_icmp_crc_tmp2(i);
end generate gen_icmp_crc;

process(p_in_rst,p_in_clk)
begin
  if p_in_rst='1' then
    i_icmp_crc_dcnt <= (others=>'0');
    i_icmp_crc_tmp <= (others=>'0');
    i_icmp_crc_rdy <= '0';
    i_icmp_crc_calc <= '0';
    sr_icmp_ack <= (others=>'0');

  elsif p_in_clk'event and p_in_clk='1' then

    if i_tx_done='1' then
        i_icmp_crc_rdy <= '0';

    elsif i_crc_start='1' then
        i_icmp_crc_tmp <= (others=>'0');
        i_icmp_crc_dcnt <= CONV_STD_LOGIC_VECTOR(34, i_icmp_crc_dcnt'length);
        i_icmp_crc_calc <= '1';

    else
      if i_icmp_crc_calc='1' then
          for i in 34 to i_icmp_ack'length-1 loop
            if i_icmp_crc_dcnt=i then
              if i_icmp_crc_dcnt(0)='1' then
                i_icmp_crc_tmp <= i_icmp_crc_tmp + (CONV_STD_LOGIC_VECTOR(0, 16) & sr_icmp_ack & i_icmp_ack(i));
              else
                sr_icmp_ack <= i_icmp_ack(i);
              end if;
            end if;
          end loop;

          if EXT(i_icmp_crc_dcnt, i_icmp_ack_ereg'length)=(i_icmp_ack_ereg - 1)  then
            i_icmp_crc_calc <= '0';
            i_icmp_crc_rdy <= '1';
          end if;

          i_icmp_crc_dcnt <= i_icmp_crc_dcnt + 1;
      end if;
    end if;

  end if;
end process;


i_ip_crc_tmp2<=i_ip_crc_tmp(31 downto 16) + i_ip_crc_tmp(15 downto 0);
gen_ip_crc : for i in 0 to i_ip_crc'length-1 generate
i_ip_crc(i) <= not i_ip_crc_tmp2(i);
end generate gen_ip_crc;

gen_ip_crc_d : for i in 14 to 33 generate
i_ip_crc_d(i) <= i_icmp_ack(i) when i_tx_req = CONV_STD_LOGIC_VECTOR(CI_TX_REQ_ICMP_ACK, i_tx_req'length) else i_dhcp_pkt(i);
end generate gen_ip_crc_d;

process(p_in_rst,p_in_clk)
begin
  if p_in_rst='1' then
    i_ip_crc_dcnt <= (others=>'0');
    i_ip_crc_tmp <= (others=>'0');
    i_ip_crc_rdy <= '0';
    i_ip_crc_calc <= '0';
    sr_ip_ack <= (others=>'0');

  elsif p_in_clk'event and p_in_clk='1' then

    if i_tx_done='1' then
        i_ip_crc_rdy <= '0';

    elsif i_crc_start='1' then
        i_ip_crc_tmp <= (others=>'0');
        i_ip_crc_dcnt <= CONV_STD_LOGIC_VECTOR(14, i_ip_crc_dcnt'length);
        i_ip_crc_calc <= '1';

    else
      if i_ip_crc_calc='1' then
          for i in 14 to 33 loop
            if i_ip_crc_dcnt=i then
              if i_ip_crc_dcnt(0)='1' then
                i_ip_crc_tmp <= i_ip_crc_tmp + (CONV_STD_LOGIC_VECTOR(0, 16) & sr_ip_ack & i_ip_crc_d(i));
              else
                sr_ip_ack <= i_ip_crc_d(i);
              end if;
            end if;
          end loop;

          if i_ip_crc_dcnt=CONV_STD_LOGIC_VECTOR(33, i_ip_crc_dcnt'length)  then
            i_ip_crc_calc <= '0';
            i_ip_crc_rdy <= '1';
          end if;

          i_ip_crc_dcnt <= i_ip_crc_dcnt + 1;
      end if;
    end if;

  end if;
end process;


----------------------------------
--UDP: usrdata -> UDP Pkt
----------------------------------
--MAC адреса
i_udp_pkt(0)  <= i_host_mac(0); --MAC Dst:
i_udp_pkt(1)  <= i_host_mac(1);
i_udp_pkt(2)  <= i_host_mac(2);
i_udp_pkt(3)  <= i_host_mac(3);
i_udp_pkt(4)  <= i_host_mac(4);
i_udp_pkt(5)  <= i_host_mac(5);
i_udp_pkt(6)  <= i_fpga_mac(0); --MAC Src:
i_udp_pkt(7)  <= i_fpga_mac(1);
i_udp_pkt(8)  <= i_fpga_mac(2);
i_udp_pkt(9)  <= i_fpga_mac(3);
i_udp_pkt(10) <= i_fpga_mac(4);
i_udp_pkt(11) <= i_fpga_mac(5);
--Eth type
i_udp_pkt(12) <= CI_ETH_TYPE_IP(15 downto 8);
i_udp_pkt(13) <= CI_ETH_TYPE_IP( 7 downto 0);
--IP
i_udp_pkt(14) <= CONV_STD_LOGIC_VECTOR(CI_IP_VER, 4) & CONV_STD_LOGIC_VECTOR(CI_IP_HEADER_SIZE/4, 4); --IP: ip ver + ip header size
i_udp_pkt(15) <= (others=>'0'); --IP: ToS (тип обслуживания)
i_udp_pkt(16) <= i_udpip_len(15 downto 8); --IP: dlen
i_udp_pkt(17) <= i_udpip_len( 7 downto 0);
i_udp_pkt(18) <= i_tx_pktid(15 downto 8);--IP: id
i_udp_pkt(19) <= i_tx_pktid( 7 downto 0);
i_udp_pkt(20) <= (others=>'0'); --IP: flag
i_udp_pkt(21) <= (others=>'0');
i_udp_pkt(22) <= CI_IP_TTL;
i_udp_pkt(23) <= CI_IP_PTYPE_UDP; --IP: protocol
i_udp_pkt(24) <= (others=>'0') when i_udpip_crc_rdy='0' else i_udpip_crc(15 downto 8); --IP: CRC
i_udp_pkt(25) <= (others=>'0') when i_udpip_crc_rdy='0' else i_udpip_crc( 7 downto 0);
i_udp_pkt(26) <= i_fpga_ip(0); --IP: ip_src
i_udp_pkt(27) <= i_fpga_ip(1);
i_udp_pkt(28) <= i_fpga_ip(2);
i_udp_pkt(29) <= i_fpga_ip(3);
i_udp_pkt(30) <= i_host_ip(0); --IP: ip_dst
i_udp_pkt(31) <= i_host_ip(1);
i_udp_pkt(32) <= i_host_ip(2);
i_udp_pkt(33) <= i_host_ip(3);
--UDP
i_udp_pkt(34) <= i_fpga_udp_port(15 downto 8);--UDP: PORT SRC
i_udp_pkt(35) <= i_fpga_udp_port( 7 downto 0);
i_udp_pkt(36) <= i_host_udp_port(15 downto 8);--UDP: PORT DST
i_udp_pkt(37) <= i_host_udp_port( 7 downto 0);
i_udp_pkt(38) <= i_udp_len(15 downto 8);      --UDP: PKT_LEN
i_udp_pkt(39) <= i_udp_len( 7 downto 0);
i_udp_pkt(40) <= (others=>'0');               --UDP: CRC
i_udp_pkt(41) <= (others=>'0');
gen_udp : for i in 42 to i_hreg_d'length-1 generate
i_udp_pkt(i) <= (others=>'0');
end generate gen_udp;

i_udp_len <= i_tx_dlen + CONV_STD_LOGIC_VECTOR(CI_UDP_HEADER_SIZE, i_udp_len'length);
i_udpip_len <= i_udp_len + CONV_STD_LOGIC_VECTOR(CI_IP_HEADER_SIZE, i_udpip_len'length);

--Расчет CRC:
i_udpip_crc_tmp2<=i_udpip_crc_tmp(31 downto 16) + i_udpip_crc_tmp(15 downto 0);
gen_udpip_crc : for i in 0 to i_ip_crc'length-1 generate
i_udpip_crc(i) <= not i_udpip_crc_tmp2(i);
end generate gen_udpip_crc;

process(p_in_rst,p_in_clk)
begin
  if p_in_rst='1' then
    i_udpip_crc_dcnt <= (others=>'0');
    i_udpip_crc_tmp <= (others=>'0');
    i_udpip_crc_rdy <= '0';
    i_udpip_crc_calc <= '0';
    sr_udp_pkt <= (others=>'0');

  elsif p_in_clk'event and p_in_clk='1' then

    if i_tx_done='1' then
        i_udpip_crc_rdy <= '0';

    elsif i_udpip_crc_start='1' then
        i_udpip_crc_tmp <= (others=>'0');
        i_udpip_crc_dcnt <= CONV_STD_LOGIC_VECTOR(14, i_ip_crc_dcnt'length);
        i_udpip_crc_calc <= '1';

    else
      if i_udpip_crc_calc='1' then
          for i in 14 to 33 loop
            if i_udpip_crc_dcnt=i then
              if i_udpip_crc_dcnt(0)='1' then
                i_udpip_crc_tmp <= i_udpip_crc_tmp + (CONV_STD_LOGIC_VECTOR(0, 16) & sr_udp_pkt & i_udp_pkt(i));
              else
                sr_udp_pkt <= i_udp_pkt(i);
              end if;
            end if;
          end loop;

          if i_udpip_crc_dcnt=CONV_STD_LOGIC_VECTOR(33, i_udpip_crc_dcnt'length)  then
            i_udpip_crc_calc <= '0';
            i_udpip_crc_rdy <= '1';
          end if;

          i_udpip_crc_dcnt <= i_udpip_crc_dcnt + 1;
      end if;
    end if;

  end if;
end process;


----------------------------------
--DHCP запросы
----------------------------------
--MAC адреса
i_dhcp_pkt(0)  <= (others=>'1'); --MAC Dst: (broadcast!!!)
i_dhcp_pkt(1)  <= (others=>'1');
i_dhcp_pkt(2)  <= (others=>'1');
i_dhcp_pkt(3)  <= (others=>'1');
i_dhcp_pkt(4)  <= (others=>'1');
i_dhcp_pkt(5)  <= (others=>'1');
i_dhcp_pkt(6)  <= i_fpga_mac(0); --MAC Src:
i_dhcp_pkt(7)  <= i_fpga_mac(1);
i_dhcp_pkt(8)  <= i_fpga_mac(2);
i_dhcp_pkt(9)  <= i_fpga_mac(3);
i_dhcp_pkt(10) <= i_fpga_mac(4);
i_dhcp_pkt(11) <= i_fpga_mac(5);
--Eth type
i_dhcp_pkt(12) <= CI_ETH_TYPE_IP(15 downto 8);
i_dhcp_pkt(13) <= CI_ETH_TYPE_IP( 7 downto 0);
--IP
i_dhcp_pkt(14) <= CONV_STD_LOGIC_VECTOR(CI_IP_VER, 4) & CONV_STD_LOGIC_VECTOR(CI_IP_HEADER_SIZE/4, 4); --IP: ip ver + ip header size
i_dhcp_pkt(15) <= (others=>'0'); --IP: ToS (тип обслуживания)
i_dhcp_pkt(16) <= i_dhcpip_len(15 downto 8); --IP: dlen
i_dhcp_pkt(17) <= i_dhcpip_len( 7 downto 0);
i_dhcp_pkt(18) <= i_tx_pktid(15 downto 8); --IP: id
i_dhcp_pkt(19) <= i_tx_pktid( 7 downto 0);
i_dhcp_pkt(20) <= (others=>'0'); --IP: flag
i_dhcp_pkt(21) <= (others=>'0');
i_dhcp_pkt(22) <= CI_IP_TTL;
i_dhcp_pkt(23) <= CI_IP_PTYPE_UDP; --IP: protocol
i_dhcp_pkt(24) <= (others=>'0') when i_ip_crc_rdy='0' else i_ip_crc(15 downto 8); --IP: CRC
i_dhcp_pkt(25) <= (others=>'0') when i_ip_crc_rdy='0' else i_ip_crc( 7 downto 0);
i_dhcp_pkt(26) <= (others=>'0'); --IP: ip_src
i_dhcp_pkt(27) <= (others=>'0');
i_dhcp_pkt(28) <= (others=>'0');
i_dhcp_pkt(29) <= (others=>'0');
i_dhcp_pkt(30) <= (others=>'1'); --IP: ip_dst (broadcast!!!)
i_dhcp_pkt(31) <= (others=>'1');
i_dhcp_pkt(32) <= (others=>'1');
i_dhcp_pkt(33) <= (others=>'1');
--UDP
i_dhcp_pkt(34) <= CI_UDP_PORT_DHCP_CLIENT(15 downto 8);--UDP: PORT SRC
i_dhcp_pkt(35) <= CI_UDP_PORT_DHCP_CLIENT( 7 downto 0);
i_dhcp_pkt(36) <= CI_UDP_PORT_DHCP_SERVER(15 downto 8);--UDP: PORT DST
i_dhcp_pkt(37) <= CI_UDP_PORT_DHCP_SERVER( 7 downto 0);
i_dhcp_pkt(38) <= i_dhcp_len(15 downto 8); --UDP: PKT_LEN
i_dhcp_pkt(39) <= i_dhcp_len( 7 downto 0);
i_dhcp_pkt(40) <= (others=>'0');           --UDP: CRC
i_dhcp_pkt(41) <= (others=>'0');
--DHCP
i_dhcp_pkt(42) <= CI_DHCP_OPER_REQUEST;        --DHCP: OP
i_dhcp_pkt(43) <= CONV_STD_LOGIC_VECTOR(1, 8); --DHCP: HTYPE
i_dhcp_pkt(44) <= CONV_STD_LOGIC_VECTOR(6, 8); --DHCP: HLEN
i_dhcp_pkt(45) <= (others=>'0');               --DHCP: HOPS
i_dhcp_pkt(46) <= i_dhcp_xid( 7 downto  0);    --DHCP: XID
i_dhcp_pkt(47) <= i_dhcp_xid(15 downto  8);
i_dhcp_pkt(48) <= i_dhcp_xid(23 downto 16);
i_dhcp_pkt(49) <= i_dhcp_xid(31 downto 24);
i_dhcp_pkt(50) <= (others=>'0');               --DHCP: SECS
i_dhcp_pkt(51) <= (others=>'0');
i_dhcp_pkt(52) <= i_dhcp_flags( 7 downto 0);   --DHCP: FLAGS
i_dhcp_pkt(53) <= i_dhcp_flags(15 downto 8);
i_dhcp_pkt(54) <= (others=>'0');               --DHCP: CIADDR
i_dhcp_pkt(55) <= (others=>'0');
i_dhcp_pkt(56) <= (others=>'0');
i_dhcp_pkt(57) <= (others=>'0');
i_dhcp_pkt(58) <= (others=>'0');               --DHCP: YIADDR
i_dhcp_pkt(59) <= (others=>'0');
i_dhcp_pkt(60) <= (others=>'0');
i_dhcp_pkt(61) <= (others=>'0');
i_dhcp_pkt(62) <= (others=>'0');               --DHCP: SIADDR
i_dhcp_pkt(63) <= (others=>'0');
i_dhcp_pkt(64) <= (others=>'0');
i_dhcp_pkt(65) <= (others=>'0');
i_dhcp_pkt(66) <= (others=>'0');               --DHCP: GIADDR
i_dhcp_pkt(67) <= (others=>'0');
i_dhcp_pkt(68) <= (others=>'0');
i_dhcp_pkt(69) <= (others=>'0');
i_dhcp_pkt(70) <= i_fpga_mac(0);               --DHCP: CHADDR
i_dhcp_pkt(71) <= i_fpga_mac(1);
i_dhcp_pkt(72) <= i_fpga_mac(2);
i_dhcp_pkt(73) <= i_fpga_mac(3);
i_dhcp_pkt(74) <= i_fpga_mac(4);
i_dhcp_pkt(75) <= i_fpga_mac(5);
i_dhcp_pkt(76) <= (others=>'0');
i_dhcp_pkt(77) <= (others=>'0');
i_dhcp_pkt(78) <= (others=>'0');
i_dhcp_pkt(79) <= (others=>'0');
i_dhcp_pkt(80) <= (others=>'0');
i_dhcp_pkt(81) <= (others=>'0');
i_dhcp_pkt(82) <= (others=>'0');
i_dhcp_pkt(83) <= (others=>'0');
i_dhcp_pkt(84) <= (others=>'0');
i_dhcp_pkt(85) <= (others=>'0');
i_dhcp_pkt(86) <= CI_DHCP_MAGIC_COOKIE( 7 downto  0);--DHCP: MAGICCOOKIE
i_dhcp_pkt(87) <= CI_DHCP_MAGIC_COOKIE(15 downto  8);
i_dhcp_pkt(88) <= CI_DHCP_MAGIC_COOKIE(23 downto 16);
i_dhcp_pkt(89) <= CI_DHCP_MAGIC_COOKIE(31 downto 24);
i_dhcp_pkt(90) <= CI_DHCP_CODE_53;                   --DHCP: Message Type(COD)
i_dhcp_pkt(91) <= CONV_STD_LOGIC_VECTOR(1, 8);       --DHCP: Message Type(LEN)
i_dhcp_pkt(92) <= CI_DHCP_DHCPDISCOVER when i_dhcp_discover_tx_done='0' else CI_DHCP_DHCPREQUEST; --DHCP: DHCP Message Type(VALUE)
i_dhcp_pkt(93) <= CI_DHCP_CODE_61;                   --DHCP: Client Identifier(COD)
i_dhcp_pkt(94) <= CONV_STD_LOGIC_VECTOR(7, 8);       --DHCP: Client Identifier(LEN)
i_dhcp_pkt(95) <= CONV_STD_LOGIC_VECTOR(1, 8);       --DHCP: Client Identifier(VALUE)
i_dhcp_pkt(96) <= i_fpga_mac(0);                     --DHCP: Client Identifier(VALUE)
i_dhcp_pkt(97) <= i_fpga_mac(1);                     --...
i_dhcp_pkt(98) <= i_fpga_mac(2);                     --...
i_dhcp_pkt(99) <= i_fpga_mac(3);                     --...
i_dhcp_pkt(100)<= i_fpga_mac(4);                     --...
i_dhcp_pkt(101)<= i_fpga_mac(5);                     --DHCP: Client Identifier(VALUE)
i_dhcp_pkt(102)<= CI_DHCP_CODE_50;                   --DHCP: Requested IP Address(COD)
i_dhcp_pkt(103)<= CONV_STD_LOGIC_VECTOR(4, 8);       --DHCP: Requested IP Address(LEN)
i_dhcp_pkt(104)<= i_dhcp_client_ip(0);               --DHCP: Requested IP Address(VALUE)
i_dhcp_pkt(105)<= i_dhcp_client_ip(1);               --...
i_dhcp_pkt(106)<= i_dhcp_client_ip(2);               --...
i_dhcp_pkt(107)<= i_dhcp_client_ip(3);               --DHCP: Requested IP Address(VALUE)
i_dhcp_pkt(108)<= CI_DHCP_CODE_255 when i_dhcp_discover_tx_done='0' else CI_DHCP_CODE_54; --DHCP: End Option/Server Identifier(COD)
i_dhcp_pkt(109)<= CONV_STD_LOGIC_VECTOR(4, 8);       --DHCP: Server Identifier(LEN)
i_dhcp_pkt(110)<= i_dhcp_server_ip(0);               --DHCP: Server Identifier(VALUE)
i_dhcp_pkt(111)<= i_dhcp_server_ip(1);               --...
i_dhcp_pkt(112)<= i_dhcp_server_ip(2);               --...
i_dhcp_pkt(113)<= i_dhcp_server_ip(3);               --DHCP: Server Identifier(VALUE)
i_dhcp_pkt(114)<= CI_DHCP_CODE_255;                  --DHCP: End Option
gen_dhcp : for i in 115 to i_hreg_d'length-1 generate
i_dhcp_pkt(i) <= (others=>'0');
end generate gen_dhcp;

gen_dhcp_xid : for i in 0 to i_dhcp_xid'length/8 - 1 generate
i_dhcp_xid(8*(i+1)-1 downto 8*i) <= i_fpga_mac(i);
end generate gen_dhcp_xid;

i_dhcp_flags <= CONV_STD_LOGIC_VECTOR(16#80#, i_dhcp_flags'length);--x80/0x00 - type broadcast/unicast

i_dhcpip_len <= CONV_STD_LOGIC_VECTOR(86 - 14 + CI_DHCP_FIELD_SNAME_SIZE + CI_DHCP_FIELD_FILE_SIZE + (109 - 86), i_dhcpip_len'length) when i_dhcp_discover_tx_done='0' else
                CONV_STD_LOGIC_VECTOR(86 - 14 + CI_DHCP_FIELD_SNAME_SIZE + CI_DHCP_FIELD_FILE_SIZE + (115 - 86), i_dhcpip_len'length);

i_dhcp_len <= CONV_STD_LOGIC_VECTOR(86 - 34 + CI_DHCP_FIELD_SNAME_SIZE + CI_DHCP_FIELD_FILE_SIZE + (109 - 86), i_dhcp_len'length) when i_dhcp_discover_tx_done='0' else
              CONV_STD_LOGIC_VECTOR(86 - 34 + CI_DHCP_FIELD_SNAME_SIZE + CI_DHCP_FIELD_FILE_SIZE + (115 - 86), i_dhcp_len'length);

--вычисляем адрес последнего региста
i_dhcp_ereg0 <= CONV_STD_LOGIC_VECTOR(86, i_dhcp_ereg0'length);

i_dhcp_ereg1 <= CONV_STD_LOGIC_VECTOR(109 - 1, i_dhcp_ereg1'length) when i_dhcp_discover_tx_done='0' else
                CONV_STD_LOGIC_VECTOR(115 - 1, i_dhcp_ereg1'length);


--END MAIN
end behavioral;
