-------------------------------------------------------------------------
-- Company     : Linkos
-- Engineer    : Golovachenko Victor
--
-- Create Date : 10.10.2012 10:49:15
-- Module Name : eth_ip
--
-- Назначение/Описание :
--
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

constant CI_HREG_ETH_TYPE        : integer:=6;
constant CI_HREG_ARP_HTYPE       : integer:=7;
constant CI_HREG_ARP_PTYPE       : integer:=8;
constant CI_HREG_ARP_HPLEN       : integer:=9;
constant CI_HREG_ARP_OPER        : integer:=10;
constant CI_HREG_IP_PROTOCOL     : integer:=11;
constant CI_HREG_ICMP_OPER       : integer:=17;

constant CI_TX_REQ_ARP_ACK       : integer:=1;
constant CI_TX_REQ_ICMP_ACK      : integer:=2;

constant CI_ETH_TYPE_ARP         : integer:=16#0806#;
constant CI_ETH_TYPE_IP          : integer:=16#0800#;

constant CI_IP_VER               : integer:=4;
constant CI_IP_HEADER_LEN        : integer:=20;
constant CI_IP_TTL               : integer:=64;
constant CI_IP_PTYPE_ICMP        : integer:=1;

constant CI_ARP_HTYPE            : integer:=16#01#;
constant CI_ARP_HPLEN            : integer:=16#0406#;
constant CI_ARP_OPER_REQUST      : integer:=1;
constant CI_ARP_OPER_REPLY       : integer:=2;

constant CI_ICMP_OPER_REQUST     : integer:=8;
constant CI_ICMP_OPER_ECHO_REPLY : integer:=0;


type TEth_fsm_rx is (
S_RX_IDLE       ,
S_RX_SEND_DONE
);
signal fsm_ip_rx_cs: TEth_fsm_rx;

type TEth_fsm_tx is (
S_TX_IDLE     ,
S_TX_ACK_DLY  ,
S_TX_ACK      ,
S_TX_ACK_DONE
);
signal fsm_ip_tx_cs: TEth_fsm_tx;

signal i_rxll_dst_rdy_n       : std_logic;
signal i_txll_data            : std_logic_vector(p_out_txll_data'range);
signal i_txll_sof_n           : std_logic;
signal i_txll_eof_n           : std_logic;
signal i_txll_src_rdy_n       : std_logic;

type THReg is array (0 to 37-1) of std_logic_vector(15 downto 0);
signal i_hreg_d               : THReg;
signal i_hreg_a               : std_logic_vector(6 downto 0);
signal i_hreg_wr              : std_logic;

signal i_tx_req               : std_logic_vector(2 downto 0);
signal i_tx_dlen              : std_logic_vector(15 downto 0);
signal i_tx_dcnt              : std_logic_vector(15 downto 0);
signal i_tx_done              : std_logic;

signal i_rx_mac_valid         : std_logic_vector(p_in_cfg.mac.src'length/2 - 1 downto 0);
signal i_rx_mac_broadcast     : std_logic_vector(p_in_cfg.mac.src'length/2 - 1 downto 0);

type TARP_ask is array (0 to 21-1) of std_logic_vector(15 downto 0);
type TICMP_ask is array (0 to 37-1) of std_logic_vector(15 downto 0);
signal i_arp_ack              : TARP_ask;
signal i_icmp_ack             : TICMP_ask;

signal i_ip_crc_dcnt          : std_logic_vector(6 downto 0);
signal i_ip_crc_tmp           : std_logic_vector(31 downto 0);
signal i_ip_crc_tmp2          : std_logic_vector(15 downto 0);
signal i_ip_crc               : std_logic_vector(15 downto 0);
signal i_ip_crc_rdy           : std_logic;
signal i_ip_crc_bsy           : std_logic;

signal i_icmp_crc_dcnt        : std_logic_vector(6 downto 0);
signal i_icmp_crc_tmp         : std_logic_vector(31 downto 0);
signal i_icmp_crc_tmp2        : std_logic_vector(15 downto 0);
signal i_icmp_crc             : std_logic_vector(15 downto 0);
signal i_icmp_crc_rdy         : std_logic;
signal i_icmp_crc_bsy         : std_logic;

signal i_crc_start            : std_logic;

signal tst_fms_cs             : std_logic_vector(2 downto 0);
signal tst_fms_cs_dly         : std_logic_vector(tst_fms_cs'range);


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
    tst_fms_cs_dly<=(others=>'0');
    p_out_tst(31 downto 1)<=(others=>'0');
  elsif p_in_clk'event and p_in_clk='1' then

    tst_fms_cs_dly<=tst_fms_cs;
    p_out_tst(0)<=OR_reduce(tst_fms_cs_dly);
  end if;
end process ltstout;

--tst_fms_cs<=CONV_STD_LOGIC_VECTOR(16#01#, tst_fms_cs'length) when fsm_ip_rx_cs=S_TX_MACA_DST0 else
--            CONV_STD_LOGIC_VECTOR(16#02#, tst_fms_cs'length) when fsm_ip_rx_cs=S_TX_MACA_DST1 else
--            CONV_STD_LOGIC_VECTOR(16#03#, tst_fms_cs'length) when fsm_ip_rx_cs=S_TX_MACA_SRC  else
--            CONV_STD_LOGIC_VECTOR(16#04#, tst_fms_cs'length) when fsm_ip_rx_cs=S_TX_MACD      else
--            CONV_STD_LOGIC_VECTOR(16#05#, tst_fms_cs'length) when fsm_ip_rx_cs=S_TX_DONE      else
--            CONV_STD_LOGIC_VECTOR(16#00#, tst_fms_cs'length);-- when fsm_ip_rx_cs=S_TX_IP_IDLE         else

end generate gen_dbg_on;


--//-------------------------------------------
--//
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

gen_rx_mac_check : for i in 0 to p_in_cfg.mac.src'length/2 - 1 generate
i_rx_mac_valid(i)<='1' when i_hreg_d(i) = (p_in_cfg.mac.src(2*(i+1)-1) & p_in_cfg.mac.src(2*i)) else '0';
i_rx_mac_broadcast(i)<='1' when i_hreg_d(i) = CONV_STD_LOGIC_VECTOR(16#FFFF#, i_hreg_d(i)'length) else '0';
end generate gen_rx_mac_check;


--//-------------------------------------------
--//
--//-------------------------------------------
p_out_rxll_dst_rdy_n <= i_rxll_dst_rdy_n;

process(p_in_rst,p_in_clk)
begin
  if p_in_rst='1' then
    fsm_ip_rx_cs<=S_RX_IDLE;

    i_rxll_dst_rdy_n <= '0';
    i_tx_req <= (others=>'0');
    i_crc_start <= '0';

  elsif p_in_clk'event and p_in_clk='1' then

        case fsm_ip_rx_cs is

          --------------------------------------
          --
          --------------------------------------
          when S_RX_IDLE =>

              if (p_in_rxll_eof_n='0' and p_in_rxll_src_rdy_n='0') or
                  i_hreg_a=CONV_STD_LOGIC_VECTOR(i_hreg_d'length - 1, i_hreg_a'length) then

                    --ARP: анализ + ответ
                    if i_hreg_d(CI_HREG_ETH_TYPE)=CONV_STD_LOGIC_VECTOR(CI_ETH_TYPE_ARP, i_hreg_d(0)'length) and
                       AND_reduce(i_rx_mac_broadcast)='1' then

                        if i_hreg_d(CI_HREG_ARP_OPER)=CONV_STD_LOGIC_VECTOR(CI_ARP_OPER_REQUST, i_hreg_d(0)'length) and
                           i_hreg_d(CI_HREG_ARP_PTYPE)=CONV_STD_LOGIC_VECTOR(CI_ETH_TYPE_IP, i_hreg_d(0)'length) and
                           i_hreg_d(CI_HREG_ARP_HTYPE)=CONV_STD_LOGIC_VECTOR(CI_ARP_HTYPE, i_hreg_d(0)'length) and
                           i_hreg_d(CI_HREG_ARP_HPLEN)=CONV_STD_LOGIC_VECTOR(CI_ARP_HPLEN, i_hreg_d(0)'length) then

                          i_tx_req <= CONV_STD_LOGIC_VECTOR(CI_TX_REQ_ARP_ACK, i_tx_req'length);
                          i_rxll_dst_rdy_n <= '1';

                          fsm_ip_rx_cs <= S_RX_SEND_DONE;
                        end if;

                    --ICMP: анализ + ответ (ping)
                    elsif i_hreg_d(CI_HREG_ETH_TYPE)=CONV_STD_LOGIC_VECTOR(CI_ETH_TYPE_IP, i_hreg_d(0)'length) and
                          i_hreg_d(CI_HREG_IP_PROTOCOL)=CONV_STD_LOGIC_VECTOR(CI_IP_PTYPE_ICMP, i_hreg_d(0)'length) and
                           i_hreg_d(CI_HREG_ICMP_OPER)=CONV_STD_LOGIC_VECTOR(CI_ICMP_OPER_REQUST, i_hreg_d(0)'length) then

                          i_tx_req <= CONV_STD_LOGIC_VECTOR(CI_TX_REQ_ICMP_ACK, i_tx_req'length);
                          i_rxll_dst_rdy_n <= '1';
                          i_crc_start <= '1';

                          fsm_ip_rx_cs <= S_RX_SEND_DONE;

                    --UDP: анализ + прием
                    end if;
              end if;

          when S_RX_SEND_DONE =>

            i_crc_start <= '0';

            if i_tx_done='1' then
              i_rxll_dst_rdy_n <= '0';
              i_tx_req <= (others=> '0');
              fsm_ip_rx_cs <= S_RX_IDLE;
            end if;

        end case;

  end if;
end process;




--//-------------------------------------------
--//
--//-------------------------------------------
p_out_txll_data      <= i_txll_data;
p_out_txll_sof_n     <= i_txll_sof_n;
p_out_txll_eof_n     <= i_txll_eof_n;
p_out_txll_src_rdy_n <= i_txll_src_rdy_n;
p_out_txll_rem       <= (others=>'0');

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

  elsif p_in_clk'event and p_in_clk='1' then

    if p_in_txll_dst_rdy_n='0' then

        case fsm_ip_tx_cs is

          --------------------------------------
          --
          --------------------------------------
          when S_TX_IDLE =>

            i_tx_done <= '0';

            if i_tx_req = CONV_STD_LOGIC_VECTOR(CI_TX_REQ_ARP_ACK, i_tx_req'length) or
               i_tx_req = CONV_STD_LOGIC_VECTOR(CI_TX_REQ_ICMP_ACK, i_tx_req'length) then

              fsm_ip_tx_cs <= S_TX_ACK_DLY;

            end if;

          --------------------------------------
          --
          --------------------------------------
          when S_TX_ACK_DLY =>

              if i_tx_dcnt=CONV_STD_LOGIC_VECTOR(16#02#, i_tx_dcnt'length) then
                i_tx_dcnt <= CONV_STD_LOGIC_VECTOR(16#01#, i_tx_dcnt'length);
                if i_tx_req=CONV_STD_LOGIC_VECTOR(CI_TX_REQ_ARP_ACK, i_tx_req'length) then
                  i_txll_data <= i_arp_ack(0);
                else
                  i_txll_data <= i_icmp_ack(0);
                end if;
                i_txll_sof_n <= '0';
                i_txll_src_rdy_n <= '0';

                fsm_ip_tx_cs <= S_TX_ACK;
              else
                i_tx_dcnt <= i_tx_dcnt + 1;
              end if;

          when S_TX_ACK =>

              for i in 0 to i_hreg_d'length-1 loop
                if i_tx_dcnt=i then
                  if i_tx_req=CONV_STD_LOGIC_VECTOR(CI_TX_REQ_ARP_ACK, i_tx_req'length) then
                    i_txll_data <= i_arp_ack(i);
                  else
                    i_txll_data <= i_icmp_ack(i);
                  end if;
                end if;
              end loop;

              i_txll_sof_n <= '1';
              i_txll_src_rdy_n <= '0';

              if (i_tx_dcnt=CONV_STD_LOGIC_VECTOR(i_arp_ack'length - 1, i_tx_dcnt'length) and i_tx_req=CONV_STD_LOGIC_VECTOR(CI_TX_REQ_ARP_ACK, i_tx_req'length)) or
                 (i_tx_dcnt=CONV_STD_LOGIC_VECTOR(i_icmp_ack'length - 1, i_tx_dcnt'length) and i_tx_req=CONV_STD_LOGIC_VECTOR(CI_TX_REQ_ICMP_ACK, i_tx_req'length)) then

                i_tx_dcnt <= (others=>'0');
                i_tx_done <= '1';
                i_txll_eof_n <= '0';
                fsm_ip_tx_cs <= S_TX_ACK_DONE;

              else
                i_tx_dcnt <= i_tx_dcnt + 1;
              end if;

          --------------------------------------
          --
          --------------------------------------
          when S_TX_ACK_DONE =>

              i_txll_sof_n <= '1';
              i_txll_eof_n <= '1';
              i_txll_src_rdy_n <= '1';

              i_tx_done <= '0';
              fsm_ip_tx_cs <= S_TX_IDLE;

          end case;

    end if;-- p_in_txll_dst_rdy_n='0' then
  end if;
end process;


----------------------------------
--ARP ответ
----------------------------------
i_arp_ack(0)  <= i_hreg_d(3); --MAC адрес отправителя ARP запроса
i_arp_ack(1)  <= i_hreg_d(4);
i_arp_ack(2)  <= i_hreg_d(5);
i_arp_ack(3)  <= p_in_cfg.mac.src(1) & p_in_cfg.mac.src(0);
i_arp_ack(4)  <= p_in_cfg.mac.src(3) & p_in_cfg.mac.src(2);
i_arp_ack(5)  <= p_in_cfg.mac.src(5) & p_in_cfg.mac.src(4);
i_arp_ack(6)  <= i_hreg_d(6); --Eth type
i_arp_ack(7)  <= i_hreg_d(7); --ARP - HTYPE
i_arp_ack(8)  <= i_hreg_d(8); --ARP - PTYPE
i_arp_ack(9)  <= i_hreg_d(9); --ARP - HPLEN
i_arp_ack(10) <= CONV_STD_LOGIC_VECTOR(CI_ARP_OPER_REPLY, i_hreg_d(0)'length);
i_arp_ack(11) <= p_in_cfg.mac.src(1) & p_in_cfg.mac.src(0);
i_arp_ack(12) <= p_in_cfg.mac.src(3) & p_in_cfg.mac.src(2);
i_arp_ack(13) <= p_in_cfg.mac.src(5) & p_in_cfg.mac.src(4);
i_arp_ack(14) <= p_in_cfg.ip.src(1) & p_in_cfg.ip.src(0);
i_arp_ack(15) <= p_in_cfg.ip.src(3) & p_in_cfg.ip.src(2);
i_arp_ack(16) <= i_hreg_d(11); --MAC адрес отправителя ARP запроса
i_arp_ack(17) <= i_hreg_d(12);
i_arp_ack(18) <= i_hreg_d(13);
i_arp_ack(19) <= i_hreg_d(14); --IP адрес отправителя ARP запроса
i_arp_ack(20) <= i_hreg_d(15);


----------------------------------
--ICMP ответ
----------------------------------
i_icmp_ack(0)  <= i_hreg_d(3); --MAC адрес отправителя ARP запроса
i_icmp_ack(1)  <= i_hreg_d(4);
i_icmp_ack(2)  <= i_hreg_d(5);
i_icmp_ack(3)  <= p_in_cfg.mac.src(1) & p_in_cfg.mac.src(0);
i_icmp_ack(4)  <= p_in_cfg.mac.src(3) & p_in_cfg.mac.src(2);
i_icmp_ack(5)  <= p_in_cfg.mac.src(5) & p_in_cfg.mac.src(4);
i_icmp_ack(6)  <= i_hreg_d(6);  --Eth type
i_icmp_ack(7)  <= i_hreg_d(7);  --IP:
i_icmp_ack(8)  <= i_hreg_d(8);  --IP: dlen
i_icmp_ack(9)  <= i_hreg_d(9);  --IP: id
i_icmp_ack(10) <= i_hreg_d(10); --IP: flag
i_icmp_ack(11) <= i_hreg_d(11)(15 downto 8) & CONV_STD_LOGIC_VECTOR(CI_IP_TTL, 8);
i_icmp_ack(12) <= CONV_STD_LOGIC_VECTOR(0, i_icmp_ack(12)'length) when i_ip_crc_rdy='0' else i_ip_crc; --IP: CRC
i_icmp_ack(13) <= i_hreg_d(15); --IP адрес отправителя ARP запроса
i_icmp_ack(14) <= i_hreg_d(16);
i_icmp_ack(15) <= p_in_cfg.ip.src(1) & p_in_cfg.ip.src(0);
i_icmp_ack(16) <= p_in_cfg.ip.src(3) & p_in_cfg.ip.src(2);
i_icmp_ack(17) <= i_hreg_d(17)(15 downto 8) & CONV_STD_LOGIC_VECTOR(CI_ICMP_OPER_ECHO_REPLY, 8);
i_icmp_ack(18) <= CONV_STD_LOGIC_VECTOR(0, i_icmp_ack(18)'length) when i_icmp_crc_rdy='0' else i_icmp_crc; --ICMP: CRC
gen_icmp_ack : for i in 19 to i_icmp_ack'length-1 generate
i_icmp_ack(i)  <= i_hreg_d(i);
end generate gen_icmp_ack;


--Расчет CRC:
i_icmp_crc_tmp2<=i_icmp_crc_tmp(31 downto 16) + i_icmp_crc_tmp(15 downto 0);
gen_icmp_crc : for i in 0 to i_icmp_crc'length-1 generate
i_icmp_crc(i) <= not i_icmp_crc_tmp2(i);
end generate gen_icmp_crc;

process(p_in_rst,p_in_clk)
begin
  if p_in_rst='1' then
    i_icmp_crc_dcnt<=(others=>'0');
    i_icmp_crc_tmp<=(others=>'0');
    i_icmp_crc_rdy <= '0';
    i_icmp_crc_bsy <= '0';
  elsif p_in_clk'event and p_in_clk='1' then

    if i_icmp_crc_bsy='0' then
        if i_crc_start='1' then
          i_icmp_crc_rdy <= '0';
          i_icmp_crc_bsy <= '1';
          i_icmp_crc_dcnt <= CONV_STD_LOGIC_VECTOR(17, i_icmp_crc_dcnt'length);
        end if;
    else
        for i in 17 to i_icmp_ack'length-1 loop
          if i_icmp_crc_dcnt=i then
            i_icmp_crc_tmp <= i_icmp_crc_tmp + EXT(i_icmp_ack(i), i_icmp_crc_tmp'length);
          end if;
        end loop;

        if i_icmp_crc_dcnt=CONV_STD_LOGIC_VECTOR(i_icmp_ack'length-1, i_icmp_crc_dcnt'length)  then
          i_icmp_crc_dcnt <= (others=>'0');
          i_icmp_crc_bsy <= '0';
          i_icmp_crc_rdy <= '1';
        else
          i_icmp_crc_dcnt <= i_icmp_crc_dcnt + 1;
        end if;
    end if;
  end if;
end process;


i_ip_crc_tmp2<=i_ip_crc_tmp(31 downto 16) + i_ip_crc_tmp(15 downto 0);
gen_ip_crc : for i in 0 to i_ip_crc'length-1 generate
i_ip_crc(i) <= not i_ip_crc_tmp2(i);
end generate gen_ip_crc;

process(p_in_rst,p_in_clk)
begin
  if p_in_rst='1' then
    i_ip_crc_dcnt<=(others=>'0');
    i_ip_crc_tmp<=(others=>'0');
    i_ip_crc_rdy <= '0';
    i_ip_crc_bsy <= '0';
  elsif p_in_clk'event and p_in_clk='1' then

    if i_ip_crc_bsy='0' then
        if i_crc_start='1' then
          i_ip_crc_rdy <= '0';
          i_ip_crc_bsy <= '1';
          i_ip_crc_dcnt <= CONV_STD_LOGIC_VECTOR(7, i_ip_crc_dcnt'length);
        end if;
    else
        for i in 7 to 16 loop
          if i_ip_crc_dcnt=i then
            i_ip_crc_tmp <= i_ip_crc_tmp + EXT(i_icmp_ack(i), i_ip_crc_tmp'length);
          end if;
        end loop;

        if i_ip_crc_dcnt=CONV_STD_LOGIC_VECTOR(16, i_ip_crc_dcnt'length)  then
          i_ip_crc_dcnt <= (others=>'0');
          i_ip_crc_bsy <= '0';
          i_ip_crc_rdy <= '1';
        else
          i_ip_crc_dcnt <= i_ip_crc_dcnt + 1;
        end if;
    end if;
  end if;
end process;



--END MAIN
end behavioral;
