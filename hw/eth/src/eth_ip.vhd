-------------------------------------------------------------------------
-- Company     : Linkos
-- Engineer    : Golovachenko Victor
--
-- Create Date : 10.10.2012 10:49:15
-- Module Name : eth_ip
--
-- ����������/�������� :
--  ������ �������� �� ������� ARP(Broadcast) + ARP(MAC_DST=MAC_FPGA)
--  + �������� �� ������ ICMP(ping)
--  + ����� UDP �������
--  + �������� UDP �������
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
G_SIM : string:="OFF");
port(
--------------------------------------
--����������
--------------------------------------
p_in_cfg         : in    TEthCfg;

--------------------------------------
--����� � ���������������� RXBUF
--------------------------------------
p_out_rxbuf_din       : out   std_logic_vector(G_ETH.usrbuf_dwidth-1 downto 0);
p_out_rxbuf_wr        : out   std_logic;
p_in_rxbuf_full       : in    std_logic;
p_out_rxd_sof         : out   std_logic;
p_out_rxd_eof         : out   std_logic;

--------------------------------------
--����� � ���������������� TXBUF
--------------------------------------
p_in_txbuf_dout       : in    std_logic_vector(G_ETH.usrbuf_dwidth-1 downto 0);
p_out_txbuf_rd        : out   std_logic;
p_in_txbuf_empty      : in    std_logic;
--p_in_txd_rdy          : in    std_logic;

--------------------------------------
--����� � Local link RxFIFO
--------------------------------------
p_in_rxll_data        : in    std_logic_vector(G_ETH.phy_dwidth-1 downto 0);
p_in_rxll_sof_n       : in    std_logic;
p_in_rxll_eof_n       : in    std_logic;
p_in_rxll_src_rdy_n   : in    std_logic;
p_out_rxll_dst_rdy_n  : out   std_logic;
p_in_rxll_fifo_status : in    std_logic_vector(3 downto 0);
p_in_rxll_rem         : in    std_logic_vector(0 downto 0);

--------------------------------------
--����� � Local link TxFIFO
--------------------------------------
p_out_txll_data      : out   std_logic_vector(G_ETH.phy_dwidth-1 downto 0);
p_out_txll_sof_n     : out   std_logic;
p_out_txll_eof_n     : out   std_logic;
p_out_txll_src_rdy_n : out   std_logic;
p_in_txll_dst_rdy_n  : in    std_logic;
p_out_txll_rem       : out   std_logic_vector(0 downto 0);

--------------------------------------------------
--��������������� �������
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

constant CI_HREG_ETH_TYPE        : integer:=12;
constant CI_HREG_ARP_HTYPE       : integer:=14;
constant CI_HREG_ARP_PTYPE       : integer:=16;
constant CI_HREG_ARP_HPLEN       : integer:=18;
constant CI_HREG_ARP_OPER        : integer:=20;
constant CI_HREG_IP_PROTOCOL     : integer:=23;
constant CI_HREG_ICMP_OPER       : integer:=34;

constant CI_TX_REQ_ARP_ACK       : integer:=1;
constant CI_TX_REQ_ICMP_ACK      : integer:=2;

constant CI_ETH_TYPE_ARP         : std_logic_vector(15 downto 0):=CONV_STD_LOGIC_VECTOR(16#0806#, 16);
constant CI_ETH_TYPE_IP          : std_logic_vector(15 downto 0):=CONV_STD_LOGIC_VECTOR(16#0800#, 16);

constant CI_IP_HEADER_SIZE       : integer:=20;--byte
constant CI_IP_VER               : std_logic_vector(3 downto 0):=CONV_STD_LOGIC_VECTOR(4, 4);
constant CI_IP_HEADER_LEN        : std_logic_vector(3 downto 0):=CONV_STD_LOGIC_VECTOR(20/4, 4);
constant CI_IP_TTL               : std_logic_vector(7 downto 0):=CONV_STD_LOGIC_VECTOR(64, 8);
constant CI_IP_PTYPE_ICMP        : std_logic_vector(7 downto 0):=CONV_STD_LOGIC_VECTOR(1, 8);
constant CI_IP_PTYPE_UDP         : std_logic_vector(7 downto 0):=CONV_STD_LOGIC_VECTOR(17, 8);

constant CI_ARP_HTYPE            : std_logic_vector(15 downto 0):=CONV_STD_LOGIC_VECTOR(1, 16);
constant CI_ARP_HLEN             : std_logic_vector( 7 downto 0):=CONV_STD_LOGIC_VECTOR(6, 8);
constant CI_ARP_PLEN             : std_logic_vector( 7 downto 0):=CONV_STD_LOGIC_VECTOR(4, 8);
constant CI_ARP_HPLEN            : std_logic_vector(15 downto 0):=CONV_STD_LOGIC_VECTOR(16#0604#, 16);
constant CI_ARP_OPER_REQUST      : std_logic_vector(15 downto 0):=CONV_STD_LOGIC_VECTOR(1, 16);
constant CI_ARP_OPER_REPLY       : std_logic_vector(15 downto 0):=CONV_STD_LOGIC_VECTOR(2, 16);

constant CI_ICMP_OPER_REQUST     : std_logic_vector(7 downto 0):=CONV_STD_LOGIC_VECTOR(8, 8);
constant CI_ICMP_OPER_ECHO_REPLY : std_logic_vector(7 downto 0):=CONV_STD_LOGIC_VECTOR(0, 8);

constant CI_UDP_HEADER_SIZE      : integer:=8;--byte

type TEth_fsm_rx is (
S_RX_IDLE       ,
S_RX_ARP_CHK    ,
S_RX_IP_CHK     ,
S_RX_ICMP       ,
S_RX_UDP_CHK    ,
S_RX_UDP_DLEN   ,
S_RX_UDP_CRC    ,
S_RX_UDP_DATA   ,
S_RX_SEND_DONE
);
signal fsm_ip_rx_cs: TEth_fsm_rx;

type TEth_fsm_tx is (
S_TX_IDLE     ,
S_TX_ACK_DLY  ,
S_TX_ACK      ,
S_TX_DONE     ,
S_TX_UDP_H0   ,
S_TX_UDP_HN   ,
S_TX_UDP_D
);
signal fsm_ip_tx_cs: TEth_fsm_tx;

signal i_rxll_dst_rdy_n       : std_logic;
signal i_txll_data            : std_logic_vector(p_out_txll_data'range);
signal i_txll_sof_n           : std_logic;
signal i_txll_eof_n           : std_logic;
signal i_txll_src_rdy_n       : std_logic;
signal i_txll_rem             : std_logic_vector(p_out_txll_rem'range);

type THReg is array (0 to 74-1) of std_logic_vector(p_out_txll_data'range);
signal i_hreg_d               : THReg;
signal i_hreg_a               : std_logic_vector(6 downto 0);
signal i_hreg_wr              : std_logic;

signal i_tx_req               : std_logic_vector(1 downto 0);
signal i_tx_dlen              : std_logic_vector(15 downto 0);
signal i_tx_dcnt              : std_logic_vector(15 downto 0);
signal i_tx_done              : std_logic;
signal i_tx_bcnt              : std_logic_vector(selval(0, 1, (p_out_txll_data'length=16)) downto 0);

signal i_rx_ip_valid          : std_logic_vector(p_in_cfg.ip.src'length - 1 downto 0);
signal i_rx_mac_valid         : std_logic_vector(p_in_cfg.mac.src'length - 1 downto 0);
signal i_rx_mac_broadcast     : std_logic_vector(p_in_cfg.mac.src'length - 1 downto 0);

signal i_arp_ack              : THReg;
signal i_icmp_ack             : THReg;
signal i_udp_pkt              : THReg;

signal i_ip_crc_dcnt          : std_logic_vector(i_hreg_a'range);
signal i_ip_crc_tmp           : std_logic_vector(31 downto 0);
signal i_ip_crc_tmp2          : std_logic_vector(15 downto 0);
signal i_ip_crc               : std_logic_vector(15 downto 0);
signal i_ip_crc_calc          : std_logic;
signal i_ip_crc_rdy           : std_logic;
signal sr_ip_ack              : std_logic_vector(p_out_txll_data'range);

signal i_icmp_id              : std_logic_vector(15 downto 0);
signal i_icmp_crc_dcnt        : std_logic_vector(i_hreg_a'range);
signal i_icmp_crc_tmp         : std_logic_vector(31 downto 0);
signal i_icmp_crc_tmp2        : std_logic_vector(15 downto 0);
signal i_icmp_crc             : std_logic_vector(15 downto 0);
signal i_icmp_crc_calc        : std_logic;
signal i_icmp_crc_rdy         : std_logic;
signal sr_icmp_ack            : std_logic_vector(p_out_txll_data'range);

signal i_crc_start            : std_logic;

signal i_usr_txd_rd           : std_logic;--//����� ��������������� ������
signal i_usr_txd_rden         : std_logic;--//���������� ������ ������ �� usr_txbuf

signal i_rx_bcnt              : std_logic_vector(1 downto 0);
signal i_rx_fst               : std_logic;
signal i_rx_d                 : std_logic_vector(31 downto 0);
signal i_rx_en                : std_logic;
signal i_rx_sof               : std_logic;
signal i_rx_eof               : std_logic;
signal i_rx_sof_ext           : std_logic;
signal sr_rx_d                : std_logic_vector(p_out_txll_data'range);

signal i_udpip_crc_start      : std_logic;
signal i_udpip_id             : std_logic_vector(15 downto 0);
signal i_udpip_crc_dcnt       : std_logic_vector(i_hreg_a'range);
signal i_udpip_crc_tmp        : std_logic_vector(31 downto 0);
signal i_udpip_crc_tmp2       : std_logic_vector(15 downto 0);
signal i_udpip_crc            : std_logic_vector(15 downto 0);
signal i_udpip_crc_calc       : std_logic;
signal i_udpip_crc_rdy        : std_logic;
signal sr_udp_pkt             : std_logic_vector(p_out_txll_data'range);
signal i_udpip_len            : std_logic_vector(15 downto 0);
signal i_udp_len              : std_logic_vector(15 downto 0);
signal i_udp_done             : std_logic;

signal tst_fms_cs             : std_logic_vector(2 downto 0);
signal tst_fms_cs_dly         : std_logic_vector(tst_fms_cs'range);
signal tst_udp                : std_logic;


--MAIN
begin

--//----------------------------------
--//��������������� �������
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

--    tst_fms_cs_dly<=tst_fms_cs;
--    p_out_tst(0)<=OR_reduce(tst_fms_cs_dly);
    p_out_tst(0)<=tst_udp;
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
--//��������� ����� RxEthPkt ��� ������� ��������� EthPkt
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

gen_rx_mac_check : for i in 0 to p_in_cfg.mac.src'length - 1 generate
i_rx_mac_valid(i)<='1' when i_hreg_d(i) = p_in_cfg.mac.src(i) else '0';
i_rx_mac_broadcast(i)<='1' when i_hreg_d(i) = CONV_STD_LOGIC_VECTOR(16#FF#, i_hreg_d(i)'length) else '0';
end generate gen_rx_mac_check;

gen_rx_ip_check : for i in 0 to p_in_cfg.ip.src'length - 1 generate
i_rx_ip_valid(i)<='1' when i_hreg_d(30+i) = p_in_cfg.ip.src(i) else '0';
end generate gen_rx_ip_check;

--//-------------------------------------------
--//������ ��������� EthPkt
--//-------------------------------------------
p_out_rxbuf_din <=i_rx_d;
p_out_rxbuf_wr <= i_rx_en or i_rx_eof;
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
    sr_rx_d <= (others=>'0'); tst_udp<='0';

  elsif p_in_clk'event and p_in_clk='1' then

        case fsm_ip_rx_cs is

          --------------------------------------
          --
          --------------------------------------
          when S_RX_IDLE =>

              i_rxll_dst_rdy_n <= '0'; tst_udp<='0';

              i_rx_bcnt <= (others=>'0');
              i_rx_fst <= '0';
              i_rx_d <= (others=>'0');
              i_rx_en <= '0';
              i_rx_sof <= '0';
              i_rx_eof <= '0';
              i_rx_sof_ext <= '0';

              if p_in_rxll_src_rdy_n='0' and i_rxll_dst_rdy_n='0' and
                  i_hreg_a=CONV_STD_LOGIC_VECTOR(CI_HREG_ETH_TYPE+2, i_hreg_a'length) then

                  --MAC: ������
                  if (AND_reduce(i_rx_mac_broadcast)='1' or AND_reduce(i_rx_mac_valid)='1') then

                      --EthPkt Type: ������
                      if (i_hreg_d(CI_HREG_ETH_TYPE+0)&i_hreg_d(CI_HREG_ETH_TYPE+1))=CI_ETH_TYPE_ARP then
                        fsm_ip_rx_cs <= S_RX_ARP_CHK;

                      elsif (i_hreg_d(CI_HREG_ETH_TYPE+0)&i_hreg_d(CI_HREG_ETH_TYPE+1))=CI_ETH_TYPE_IP then
                        fsm_ip_rx_cs <= S_RX_IP_CHK;

                      end if;
                  end if;

              end if;

          --------------------------------------
          --
          --------------------------------------
          when S_RX_ARP_CHK =>

              if (p_in_rxll_eof_n='0' and p_in_rxll_src_rdy_n='0') then

                  if (i_hreg_d(CI_HREG_ARP_HTYPE+0)&i_hreg_d(CI_HREG_ARP_HTYPE+1))=CI_ARP_HTYPE and
                     (i_hreg_d(CI_HREG_ARP_PTYPE+0)&i_hreg_d(CI_HREG_ARP_PTYPE+1))=CI_ETH_TYPE_IP and
                     (i_hreg_d(CI_HREG_ARP_HPLEN+0)&i_hreg_d(CI_HREG_ARP_HPLEN+1))=CI_ARP_HPLEN and
                     (i_hreg_d(CI_HREG_ARP_OPER+0) &i_hreg_d(CI_HREG_ARP_OPER+1) )=CI_ARP_OPER_REQUST then

                        i_tx_req <= CONV_STD_LOGIC_VECTOR(CI_TX_REQ_ARP_ACK, i_tx_req'length);
                        i_rxll_dst_rdy_n <= '1';

                        fsm_ip_rx_cs <= S_RX_SEND_DONE;
                    else
                        fsm_ip_rx_cs <= S_RX_IDLE;
                    end if;

              end if;

          --------------------------------------
          --
          --------------------------------------
          when S_RX_IP_CHK =>

              if p_in_rxll_src_rdy_n='0' and
                 i_hreg_a=CONV_STD_LOGIC_VECTOR(CI_HREG_ICMP_OPER, i_hreg_a'length) then

                  --IP: ������
                  if AND_reduce(i_rx_ip_valid)='1' then

                      if i_hreg_d(CI_HREG_IP_PROTOCOL)=CI_IP_PTYPE_ICMP then
                        fsm_ip_rx_cs <= S_RX_ICMP;

                      elsif i_hreg_d(CI_HREG_IP_PROTOCOL)=CI_IP_PTYPE_UDP then
                        fsm_ip_rx_cs <= S_RX_UDP_CHK; tst_udp<='1';

                      else
                        fsm_ip_rx_cs <= S_RX_IDLE;
                      end if;
                  else
                    fsm_ip_rx_cs <= S_RX_IDLE;
                  end if;

              end if;

          --------------------------------------
          --ICMP: ������ + ����� (ping)
          --------------------------------------
          when S_RX_ICMP =>

              if p_in_rxll_src_rdy_n='0' then

                  if i_hreg_d(CI_HREG_ICMP_OPER)=CI_ICMP_OPER_REQUST then

                      if p_in_rxll_eof_n='0' then
                          i_tx_req <= CONV_STD_LOGIC_VECTOR(CI_TX_REQ_ICMP_ACK, i_tx_req'length);
                          i_rxll_dst_rdy_n <= '1';
                          i_crc_start <= '1';
                          fsm_ip_rx_cs <= S_RX_SEND_DONE;
                      end if;
                  else
                     fsm_ip_rx_cs <= S_RX_IDLE;
                  end if;

              end if;

          --------------------------------------
          --UDP: ������ + �����
          --------------------------------------
          when S_RX_UDP_CHK =>

              if p_in_rxll_src_rdy_n='0' and
                i_hreg_a=CONV_STD_LOGIC_VECTOR(37, i_hreg_a'length) then

                  --��������� DST PORT ������������ UDP Pkt
                  if (i_hreg_d(36) & p_in_rxll_data)=p_in_cfg.prt.src then
                    fsm_ip_rx_cs <= S_RX_UDP_DLEN;
                  else
                    fsm_ip_rx_cs <= S_RX_IDLE;
                  end if;

              end if;

          when S_RX_UDP_DLEN =>

              if p_in_rxll_src_rdy_n='0' then
                if i_rx_bcnt(0)='1' then
                  i_rx_d(15 downto 0) <= (sr_rx_d & p_in_rxll_data) - 8;
                  fsm_ip_rx_cs <= S_RX_UDP_CRC;
                else
                  sr_rx_d <= p_in_rxll_data;
                end if;

                i_rx_bcnt <= i_rx_bcnt + 1;
              end if;

          when S_RX_UDP_CRC =>

              if p_in_rxll_src_rdy_n='0' then
                if i_rx_bcnt=CONV_STD_LOGIC_VECTOR(4-1, i_rx_bcnt'length) then
                  i_rx_bcnt <= CONV_STD_LOGIC_VECTOR(2, i_rx_bcnt'length);
                  fsm_ip_rx_cs <= S_RX_UDP_DATA;
                else
                  i_rx_bcnt <= i_rx_bcnt + 1;
                end if;

                if i_rx_d(15 downto 0)<CONV_STD_LOGIC_VECTOR(2, i_rx_d'length) then
                  i_rx_sof_ext <= '1';
                end if;
              end if;

          when S_RX_UDP_DATA =>

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
          --���� ���������� ������ �� ������� ARP,ICMP
          --------------------------------------
          when S_RX_SEND_DONE =>

            i_crc_start <= '0';

            if i_tx_done='1' then
              i_tx_req <= (others=> '0');
              fsm_ip_rx_cs <= S_RX_IDLE;
            end if;

        end case;

  end if;
end process;



--//-------------------------------------------
--//Tx - EthPkt
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

    i_icmp_id <= (others=>'0');

    i_usr_txd_rd<='0';
    i_usr_txd_rden<='0';
    i_tx_bcnt<=(others=>'0');

    i_udpip_id <= (others=>'0');
    i_udpip_crc_start <= '0';
    i_udp_done <= '0';

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

            elsif p_in_txbuf_empty='0' then

              i_tx_dlen<=p_in_txbuf_dout(15 downto 0);--usr dlen (byte)
              i_udpip_crc_start <= '1';
              i_udpip_id <= i_udpip_id + 1;
              fsm_ip_tx_cs<=S_TX_UDP_H0;

            end if;

          --------------------------------------
          --����� �������� (��� ���� ���� ������ ��������� CRC)
          --------------------------------------
          when S_TX_ACK_DLY =>

              if i_tx_dcnt=CONV_STD_LOGIC_VECTOR(16#04#, i_tx_dcnt'length) then

                  i_tx_dcnt <= CONV_STD_LOGIC_VECTOR(16#01#, i_tx_dcnt'length);
                  if i_tx_req=CONV_STD_LOGIC_VECTOR(CI_TX_REQ_ARP_ACK, i_tx_req'length) then
                    i_txll_data <= i_arp_ack(0);
                  else
                    i_txll_data <= i_icmp_ack(0);
                    i_icmp_id <= i_icmp_id + 1;
                  end if;
                  i_txll_sof_n <= '0';
                  i_txll_src_rdy_n <= '0';

                  fsm_ip_tx_cs <= S_TX_ACK;
              else
                i_tx_dcnt <= i_tx_dcnt + 1;
              end if;

          --------------------------------------
          --
          --------------------------------------
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
                fsm_ip_tx_cs <= S_TX_DONE;

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
              i_udp_done <= '0';

              fsm_ip_tx_cs <= S_TX_IDLE;


          --------------------------------------
          --UDP Pkt: ��������� - MAC+EthType+IP(header)+UDP(header)
          --------------------------------------
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

          --------------------------------------
          --UDP Pkt: User DATA
          --------------------------------------
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

                  i_udp_done <= '1';
                  fsm_ip_tx_cs<=S_TX_DONE;
                else
                  i_tx_dcnt<=i_tx_dcnt + 1;--//������� ���� ������������ ������
                  i_txll_eof_n<='1';
                end if;

                --//������
                  for i in 0 to p_in_txbuf_dout'length/i_txll_data'length - 1 loop
                    if i_tx_bcnt=i then
                      i_txll_data<=p_in_txbuf_dout(8*(i_txll_data'length/8)*(i+1)-1 downto 8*(i_txll_data'length/8)*i);
                    end if;
                  end loop;

                i_tx_bcnt<=i_tx_bcnt + 1;--//������� ���� ����� ������� ������ p_in_txbuf_dout

            end if;--//if p_in_txbuf_empty='0' then

          end case;

    end if;-- p_in_txll_dst_rdy_n='0' then
  end if;
end process;


----------------------------------
--ARP �����
----------------------------------
--MAC ������
i_arp_ack(0)  <= i_hreg_d(6); --MAC Dst: ����� ����������� ARP �������
i_arp_ack(1)  <= i_hreg_d(7);
i_arp_ack(2)  <= i_hreg_d(8);
i_arp_ack(3)  <= i_hreg_d(9);
i_arp_ack(4)  <= i_hreg_d(10);
i_arp_ack(5)  <= i_hreg_d(11);
i_arp_ack(6)  <= p_in_cfg.mac.src(0); --MAC Src: FPGA
i_arp_ack(7)  <= p_in_cfg.mac.src(1);
i_arp_ack(8)  <= p_in_cfg.mac.src(2);
i_arp_ack(9)  <= p_in_cfg.mac.src(3);
i_arp_ack(10) <= p_in_cfg.mac.src(4);
i_arp_ack(11) <= p_in_cfg.mac.src(5);
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
i_arp_ack(22) <= p_in_cfg.mac.src(0);--ARP: MAC src
i_arp_ack(23) <= p_in_cfg.mac.src(1);
i_arp_ack(24) <= p_in_cfg.mac.src(2);
i_arp_ack(25) <= p_in_cfg.mac.src(3);
i_arp_ack(26) <= p_in_cfg.mac.src(4);
i_arp_ack(27) <= p_in_cfg.mac.src(5);
i_arp_ack(28) <= p_in_cfg.ip.src(0); --ARP: IP src
i_arp_ack(29) <= p_in_cfg.ip.src(1);
i_arp_ack(30) <= p_in_cfg.ip.src(2);
i_arp_ack(31) <= p_in_cfg.ip.src(3);
i_arp_ack(32) <= i_hreg_d(22);--ARP: MAC dst
i_arp_ack(33) <= i_hreg_d(23);
i_arp_ack(34) <= i_hreg_d(24);
i_arp_ack(35) <= i_hreg_d(25);
i_arp_ack(36) <= i_hreg_d(26);
i_arp_ack(37) <= i_hreg_d(27);
i_arp_ack(38) <= i_hreg_d(28);--ARP: IP dst
i_arp_ack(39) <= i_hreg_d(29);
i_arp_ack(40) <= i_hreg_d(30);
i_arp_ack(41) <= i_hreg_d(31);
gen_ack_null : for i in 42 to i_hreg_d'length-1 generate
i_arp_ack(i)  <= (others=>'0');
end generate gen_ack_null;


----------------------------------
--ICMP �����
----------------------------------
--MAC ������
i_icmp_ack(0)  <= i_hreg_d(6);  --MAC Dst: ����� ����������� ICMP �������
i_icmp_ack(1)  <= i_hreg_d(7);
i_icmp_ack(2)  <= i_hreg_d(8);
i_icmp_ack(3)  <= i_hreg_d(9);
i_icmp_ack(4)  <= i_hreg_d(10);
i_icmp_ack(5)  <= i_hreg_d(11);
i_icmp_ack(6)  <= i_hreg_d(0);  --MAC Src: FPGA
i_icmp_ack(7)  <= i_hreg_d(1);
i_icmp_ack(8)  <= i_hreg_d(2);
i_icmp_ack(9)  <= i_hreg_d(3);
i_icmp_ack(10) <= i_hreg_d(4);
i_icmp_ack(11) <= i_hreg_d(5);
--Eth type
i_icmp_ack(12) <= i_hreg_d(12); --Eth type
i_icmp_ack(13) <= i_hreg_d(13);
--IP
i_icmp_ack(14) <= i_hreg_d(14); --IP: ver
i_icmp_ack(15) <= i_hreg_d(15); --IP: ToS (��� ������������)
i_icmp_ack(16) <= i_hreg_d(16); --IP: dlen
i_icmp_ack(17) <= i_hreg_d(17);
i_icmp_ack(18) <= i_icmp_id(15 downto 8);--IP: id  --i_hreg_d(18);--
i_icmp_ack(19) <= i_icmp_id( 7 downto 0);          --i_hreg_d(19);--
i_icmp_ack(20) <= i_hreg_d(20); --IP: flag
i_icmp_ack(21) <= i_hreg_d(21);
i_icmp_ack(22) <= CI_IP_TTL;
i_icmp_ack(23) <= i_hreg_d(23); --IP: protocol
i_icmp_ack(24) <= (others=>'0') when i_ip_crc_rdy='0' else i_ip_crc(15 downto 8); --IP: CRC
i_icmp_ack(25) <= (others=>'0') when i_ip_crc_rdy='0' else i_ip_crc( 7 downto 0);
i_icmp_ack(26) <= i_hreg_d(30); --IP: ip_src - ��� ���� ICMP �����
i_icmp_ack(27) <= i_hreg_d(31);
i_icmp_ack(28) <= i_hreg_d(32);
i_icmp_ack(29) <= i_hreg_d(33);
i_icmp_ack(30) <= i_hreg_d(26); --IP: ip_dst - �� ���� ICMP ������
i_icmp_ack(31) <= i_hreg_d(27);
i_icmp_ack(32) <= i_hreg_d(28);
i_icmp_ack(33) <= i_hreg_d(29);
--ICMP
i_icmp_ack(34) <= CI_ICMP_OPER_ECHO_REPLY;--ICMP: Operation
i_icmp_ack(35) <= i_hreg_d(35);
i_icmp_ack(36) <= (others=>'0') when i_icmp_crc_rdy='0' else i_icmp_crc(15 downto 8); --ICMP: CRC
i_icmp_ack(37) <= (others=>'0') when i_icmp_crc_rdy='0' else i_icmp_crc( 7 downto 0);
gen_icmp_ack : for i in 38 to i_hreg_d'length-1 generate
i_icmp_ack(i)  <= i_hreg_d(i);
end generate gen_icmp_ack;


--������ CRC:
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

          if i_icmp_crc_dcnt=CONV_STD_LOGIC_VECTOR(i_icmp_ack'length-1, i_icmp_crc_dcnt'length)  then
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
                i_ip_crc_tmp <= i_ip_crc_tmp + (CONV_STD_LOGIC_VECTOR(0, 16) & sr_ip_ack & i_icmp_ack(i));
              else
                sr_ip_ack <= i_icmp_ack(i);
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
--MAC ������
i_udp_pkt(0)  <= p_in_cfg.mac.dst(0); --MAC Dst:
i_udp_pkt(1)  <= p_in_cfg.mac.dst(1);
i_udp_pkt(2)  <= p_in_cfg.mac.dst(2);
i_udp_pkt(3)  <= p_in_cfg.mac.dst(3);
i_udp_pkt(4)  <= p_in_cfg.mac.dst(4);
i_udp_pkt(5)  <= p_in_cfg.mac.dst(5);
i_udp_pkt(6)  <= p_in_cfg.mac.src(0); --MAC Src: FPGA
i_udp_pkt(7)  <= p_in_cfg.mac.src(1);
i_udp_pkt(8)  <= p_in_cfg.mac.src(2);
i_udp_pkt(9)  <= p_in_cfg.mac.src(3);
i_udp_pkt(10) <= p_in_cfg.mac.src(4);
i_udp_pkt(11) <= p_in_cfg.mac.src(5);
--Eth type
i_udp_pkt(12) <= CI_ETH_TYPE_IP(15 downto 8);
i_udp_pkt(13) <= CI_ETH_TYPE_IP( 7 downto 0);
--IP
i_udp_pkt(14) <= CONV_STD_LOGIC_VECTOR(16#45#, 8); --IP: ver
i_udp_pkt(15) <= (others=>'0'); --IP: ToS (��� ������������)
i_udp_pkt(16) <= i_udpip_len(15 downto 8); --IP: dlen
i_udp_pkt(17) <= i_udpip_len( 7 downto 0);
i_udp_pkt(18) <= i_udpip_id(15 downto 8);--IP: id
i_udp_pkt(19) <= i_udpip_id( 7 downto 0);
i_udp_pkt(20) <= (others=>'0'); --IP: flag
i_udp_pkt(21) <= (others=>'0');
i_udp_pkt(22) <= CI_IP_TTL;
i_udp_pkt(23) <= CI_IP_PTYPE_UDP; --IP: protocol
i_udp_pkt(24) <= (others=>'0') when i_udpip_crc_rdy='0' else i_udpip_crc(15 downto 8); --IP: CRC
i_udp_pkt(25) <= (others=>'0') when i_udpip_crc_rdy='0' else i_udpip_crc( 7 downto 0);
i_udp_pkt(26) <= p_in_cfg.ip.src(0); --IP: ip_src
i_udp_pkt(27) <= p_in_cfg.ip.src(1);
i_udp_pkt(28) <= p_in_cfg.ip.src(2);
i_udp_pkt(29) <= p_in_cfg.ip.src(3);
i_udp_pkt(30) <= p_in_cfg.ip.dst(0); --IP: ip_dst
i_udp_pkt(31) <= p_in_cfg.ip.dst(1);
i_udp_pkt(32) <= p_in_cfg.ip.dst(2);
i_udp_pkt(33) <= p_in_cfg.ip.dst(3);
--UDP
i_udp_pkt(34) <= p_in_cfg.prt.src(15 downto 8);--UDP: PORT SRC
i_udp_pkt(35) <= p_in_cfg.prt.src( 7 downto 0);
i_udp_pkt(36) <= p_in_cfg.prt.dst(15 downto 8);--UDP: PORT DST
i_udp_pkt(37) <= p_in_cfg.prt.dst( 7 downto 0);
i_udp_pkt(38) <= i_udp_len(15 downto 8);       --UDP: PKT_LEN
i_udp_pkt(39) <= i_udp_len( 7 downto 0);
i_udp_pkt(40) <= (others=>'0');                --UDP: CRC
i_udp_pkt(41) <= (others=>'0');
gen_udp : for i in 42 to i_hreg_d'length-1 generate
i_udp_pkt(i)  <= (others=>'0');
end generate gen_udp;

i_udp_len <= i_tx_dlen + CONV_STD_LOGIC_VECTOR(CI_UDP_HEADER_SIZE, i_udp_len'length);
i_udpip_len <= i_udp_len + CONV_STD_LOGIC_VECTOR(CI_IP_HEADER_SIZE, i_udpip_len'length);

--������ CRC:
i_udpip_crc_tmp2<=i_udpip_crc_tmp(31 downto 16) + i_udpip_crc_tmp(15 downto 0);
gen_ipudp_crc : for i in 0 to i_ip_crc'length-1 generate
i_udpip_crc(i) <= not i_udpip_crc_tmp2(i);
end generate gen_ipudp_crc;

process(p_in_rst,p_in_clk)
begin
  if p_in_rst='1' then
    i_udpip_crc_dcnt <= (others=>'0');
    i_udpip_crc_tmp <= (others=>'0');
    i_udpip_crc_rdy <= '0';
    i_udpip_crc_calc <= '0';
    sr_udp_pkt <= (others=>'0');

  elsif p_in_clk'event and p_in_clk='1' then

    if i_udp_done='1' then
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


--END MAIN
end behavioral;
