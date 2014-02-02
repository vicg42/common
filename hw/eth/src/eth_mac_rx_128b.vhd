-------------------------------------------------------------------------
-- Company     : Linkos
-- Engineer    : Golovachenko Victor
--
-- Create Date : 02.02.2014 14:49:38
-- Module Name : eth_rx
--
-- Назначение/Описание :
-- Реализация для шины данных 64bit!!!!
--
-- Revision:
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

entity eth_mac_rx is
generic(
G_ETH : TEthGeneric;
G_DBG : string:="OFF";
G_SIM : string:="OFF"
);
port(
--------------------------------------
--Управление
--------------------------------------
p_in_cfg              : in    TEthCfg;

--------------------------------------
--Связь с пользовательским RXBUF
--------------------------------------
p_out_rxbuf_din       : out   std_logic_vector(G_ETH.usrbuf_dwidth - 1 downto 0);
p_out_rxbuf_wr        : out   std_logic;
p_in_rxbuf_full       : in    std_logic;
p_out_rxd_sof         : out   std_logic;
p_out_rxd_eof         : out   std_logic;

--------------------------------------
--Связь с Local link RxFIFO
--------------------------------------
p_in_rxll_data        : in    std_logic_vector(G_ETH.phy_dwidth - 1 downto 0);
p_in_rxll_sof_n       : in    std_logic;
p_in_rxll_eof_n       : in    std_logic;
p_in_rxll_src_rdy_n   : in    std_logic;
p_out_rxll_dst_rdy_n  : out   std_logic;
p_in_rxll_fifo_status : in    std_logic_vector(3 downto 0);
p_in_rxll_rem         : in    std_logic_vector((G_ETH.phy_dwidth / 8) - 1 downto 0);

--------------------------------------
--Управление передачей PAUSE Control Frame
--(более подробно см. ug194.pdf/Flow Control Block/Flow Control Implementation Example)
--------------------------------------
p_out_pause_req       : out   std_logic;
p_out_pause_val       : out   std_logic_vector(15 downto 0);

--------------------------------------------------
--Технологические сигналы
--------------------------------------------------
p_in_tst              : in    std_logic_vector(31 downto 0);
p_out_tst             : out   std_logic_vector(31 downto 0);

--------------------------------------
--SYSTEM
--------------------------------------
p_in_clk              : in    std_logic;
p_in_rst              : in    std_logic
);
end eth_mac_rx;

architecture behavioral of eth_mac_rx is

type TEth_fsm_rx is (
S_IDLE,
S_RX_MAC_A,
S_RX_MAC_D,
S_RX_END,
S_RX_WAIT_EOF
);
signal fsm_eth_rx_cs: TEth_fsm_rx;

signal i_usrpkt_len_byte      : std_logic_vector(15 downto 0);
signal i_usrpkt_len_2dw       : std_logic_vector(15 downto 0);

signal i_mac_dlen_byte_swap   : std_logic_vector(15 downto 0);
signal i_mac_dlen_byte        : std_logic_vector(15 downto 0);
signal i_remain_byte          : std_logic_vector(15 downto 0);
signal i_remain_byte_tmp      : std_logic_vector(15 downto 0);
signal i_dcnt                 : std_logic_vector(15 downto 0);

signal i_rx_mac_dst           : TEthMacAdr;
signal i_rx_mac_valid         : std_logic_vector(p_in_cfg.mac.src'length - 1 downto 0);

signal i_usr_wr               : std_logic;
signal i_usr_rxd              : std_logic_vector(p_out_rxbuf_din'range);
signal i_usr_rxd_sof          : std_logic;
signal i_usr_rxd_eof          : std_logic;
signal i_usr_rxd_sof_en       : std_logic;

signal i_rxll_eof_det         : std_logic;
signal i_ll_dst_rdy           : std_logic;
signal sr_rxll_data           : std_logic_vector(31 downto 0);

signal i_rxbuf_din            : std_logic_vector(p_out_rxbuf_din'range);
signal i_rxbuf_wr             : std_logic;
signal i_rxd_sof              : std_logic;
signal i_rxd_eof              : std_logic;

signal tst_fms_cs             : std_logic_vector(2 downto 0);
signal tst_fms_cs_dly         : std_logic_vector(tst_fms_cs'range) := (others => '0');


--MAIN
begin

------------------------------------
--Технологические сигналы
------------------------------------
gen_dbg_off : if strcmp(G_DBG,"OFF") generate
p_out_tst(31 downto 0) <= (others=>'0');
end generate gen_dbg_off;

gen_dbg_on : if strcmp(G_DBG,"ON") generate
ltstout:process(p_in_clk)
begin
  if rising_edge(p_in_clk) then
    tst_fms_cs_dly <= tst_fms_cs;

    p_out_tst(0) <= OR_reduce(tst_fms_cs_dly);

  end if;
end process ltstout;

tst_fms_cs <= CONV_STD_LOGIC_VECTOR(16#01#, tst_fms_cs'length) when fsm_eth_rx_cs = S_RX_MAC_A  else
              CONV_STD_LOGIC_VECTOR(16#02#, tst_fms_cs'length) when fsm_eth_rx_cs = S_RX_MAC_D  else
              CONV_STD_LOGIC_VECTOR(16#03#, tst_fms_cs'length) when fsm_eth_rx_cs = S_RX_END    else
              CONV_STD_LOGIC_VECTOR(16#04#, tst_fms_cs'length) when fsm_eth_rx_cs = S_RX_WAIT_EOF    else
              CONV_STD_LOGIC_VECTOR(16#00#, tst_fms_cs'length);-- when fsm_eth_rx_cs = S_IDLE     else

end generate gen_dbg_on;


gen_rx_mac_check : for i in 0 to p_in_cfg.mac.src'length - 1 generate
i_rx_mac_valid(i) <= '1' when i_rx_mac_dst(i) = p_in_cfg.mac.src(i) else '0';
--i_rx_mac_valid(i) <= '1' when i_rx_mac_dst(i) = p_in_cfg.mac.dst(i) else '0';--for TEST
end generate gen_rx_mac_check;

i_usrpkt_len_byte <= i_mac_dlen_byte + 6;
i_usrpkt_len_2dw <= EXT(i_usrpkt_len_byte(i_usrpkt_len_byte'high
                          downto log2(p_out_rxbuf_din'length / 8)), i_usrpkt_len_byte'length)
                  + OR_reduce(i_usrpkt_len_byte(log2(p_out_rxbuf_din'length / 8) - 1 downto 0));

i_remain_byte_tmp <= 10 + i_mac_dlen_byte;

i_remain_byte <= (i_dcnt(i_dcnt'high - 3 downto 0) & "000") - i_remain_byte_tmp;


--Прием: первый ст. байт
gen_length_swap_0 : if G_ETH.mac_length_swap = 0 generate
i_mac_dlen_byte_swap((8 * 1) - 1 downto 8 * 0) <= p_in_rxll_data((8 * 6) - 1 downto 8 * 5);
i_mac_dlen_byte_swap((8 * 2) - 1 downto 8 * 1) <= p_in_rxll_data((8 * 5) - 1 downto 8 * 4);
end generate gen_length_swap_0;

--Прием: первый мл. байт
gen_length_swap_1 : if G_ETH.mac_length_swap = 1 generate
i_mac_dlen_byte_swap((8 * 2) - 1 downto 8 * 1) <= p_in_rxll_data((8 * 6) - 1 downto 8 * 5);
i_mac_dlen_byte_swap((8 * 1) - 1 downto 8 * 0) <= p_in_rxll_data((8 * 5) - 1 downto 8 * 4);
end generate gen_length_swap_1;

---------------------------------------------
--Автомат приема данных из ядра ETH
---------------------------------------------
process(p_in_clk)
begin
if rising_edge(p_in_clk) then
  if p_in_rst = '1' then

    fsm_eth_rx_cs <= S_IDLE;

    for i in 0 to i_rx_mac_dst'length - 1 loop
    i_rx_mac_dst(i) <= (others=>'0');
    end loop;
    i_mac_dlen_byte <= (others=>'0');

    i_ll_dst_rdy <= '0';

    i_usr_rxd_sof_en <= '0';
    i_usr_rxd_sof <= '0';
    i_usr_rxd_eof <= '0';
    i_usr_rxd <= (others=>'0');
    i_usr_wr <= '0';
    i_rxll_eof_det <= '0';

    i_dcnt <= (others=>'0');

    sr_rxll_data <= (others=>'0');

  else

    if p_in_rxbuf_full = '0' then

      case fsm_eth_rx_cs is

        --------------------------------------
        --Ждем входных данных
        --------------------------------------
        when S_IDLE =>

          i_ll_dst_rdy <= '0';
          i_usr_rxd_sof_en <= '0';
          i_usr_rxd_sof <= '0';
          i_usr_rxd_eof <= '0';
          i_usr_wr <= '0';
          i_dcnt <= (others=>'0');
          i_rxll_eof_det <= '0';

          if p_in_rxll_src_rdy_n = '0' and p_in_rxll_sof_n = '0' then

            i_rx_mac_dst(0) <= p_in_rxll_data((8 * 1) - 1 downto 8 * 0);
            i_rx_mac_dst(1) <= p_in_rxll_data((8 * 2) - 1 downto 8 * 1);
            i_rx_mac_dst(2) <= p_in_rxll_data((8 * 3) - 1 downto 8 * 2);
            i_rx_mac_dst(3) <= p_in_rxll_data((8 * 4) - 1 downto 8 * 3);
            i_rx_mac_dst(4) <= p_in_rxll_data((8 * 5) - 1 downto 8 * 4);
            i_rx_mac_dst(5) <= p_in_rxll_data((8 * 6) - 1 downto 8 * 5);

            fsm_eth_rx_cs <= S_RX_MAC_A;

          end if;


        --------------------------------------
        --MACFRAME: прием mac_dst
        --------------------------------------
        when S_RX_MAC_A =>

          if p_in_rxll_src_rdy_n = '0' then

            if AND_reduce(i_rx_mac_valid) = '0' then
            --пакет НЕ наш:
                i_dcnt <= (others=>'0');
                i_ll_dst_rdy <= '0';

                if p_in_rxll_eof_n = '0' then
                  fsm_eth_rx_cs <= S_IDLE;
                end if;

            else
            --пакет наш:
                sr_rxll_data((8 * 4) - 1 downto 8 * 2) <= p_in_rxll_data((8 * 8) - 1 downto 8 * 6); --rxdata

                if G_ETH.mac_length_swap = 0 then
                --Прием: первый ст. байт
                sr_rxll_data((8 * 1) - 1 downto 8 * 0) <= p_in_rxll_data((8 * 6) - 1 downto 8 * 5);
                sr_rxll_data((8 * 2) - 1 downto 8 * 1) <= p_in_rxll_data((8 * 5) - 1 downto 8 * 4);

                i_usr_rxd((8 * 1) - 1 downto 8 * 0) <= p_in_rxll_data((8 * 6) - 1 downto 8 * 5);
                i_usr_rxd((8 * 2) - 1 downto 8 * 1) <= p_in_rxll_data((8 * 5) - 1 downto 8 * 4);

                else
                --Прием: первый мл. байт
                sr_rxll_data((8 * 2) - 1 downto 8 * 1) <= p_in_rxll_data((8 * 6) - 1 downto 8 * 5);
                sr_rxll_data((8 * 1) - 1 downto 8 * 0) <= p_in_rxll_data((8 * 5) - 1 downto 8 * 4);

                i_usr_rxd((8 * 2) - 1 downto 8 * 1) <= p_in_rxll_data((8 * 6) - 1 downto 8 * 5);
                i_usr_rxd((8 * 1) - 1 downto 8 * 0) <= p_in_rxll_data((8 * 5) - 1 downto 8 * 4);

                end if;

                i_mac_dlen_byte <= i_mac_dlen_byte_swap;

                if i_mac_dlen_byte_swap > CONV_STD_LOGIC_VECTOR(16#02#, i_mac_dlen_byte_swap'length) then
                  i_dcnt <= i_dcnt + 2;
                  fsm_eth_rx_cs <= S_RX_MAC_D;

                else

                  if i_mac_dlen_byte_swap = CONV_STD_LOGIC_VECTOR(16#02#, i_mac_dlen_byte_swap'length) then
                  i_usr_rxd((8 * 4) - 1 downto 8 * 3) <= p_in_rxll_data((8 * 8) - 1 downto 8 * 7);
                  else
                  i_usr_rxd((8 * 4) - 1 downto 8 * 3) <= (others=>'0');
                  end if;

                  i_usr_rxd((8 * 3) - 1 downto 8 * 2) <= p_in_rxll_data((8 * 7) - 1 downto 8 * 6);

                  i_usr_wr <= '1';
                  i_usr_rxd_sof <= '1';
                  i_usr_rxd_eof <= '1';

                  i_ll_dst_rdy <= '1';

                  if p_in_rxll_eof_n = '0' then
                  fsm_eth_rx_cs <= S_IDLE;
                  else
                  fsm_eth_rx_cs <= S_RX_WAIT_EOF;
                  end if;

                end if;

            end if;

          end if;


        --------------------------------------
        --MACFRAME: запись данных mac frame в usr_rxbuf
        --------------------------------------
        when S_RX_MAC_D =>

          if p_in_rxll_src_rdy_n = '0' then

              sr_rxll_data <= p_in_rxll_data((8 * 8) - 1 downto 8 * 4); --rxdata(63..32)

              i_usr_wr <= '1';

              if i_usr_rxd_sof_en = '0' then
                i_usr_rxd_sof <= '1';
                i_usr_rxd_sof_en <= '1';
              else
                i_usr_rxd_sof <= '0';
              end if;

              if i_dcnt = i_usrpkt_len_2dw then

                  --USRDATA:LSB
                  i_usr_rxd((8 * 4) - 1 downto 8 * 0) <= sr_rxll_data;

                  if i_remain_byte(3 downto 0) < CONV_STD_LOGIC_VECTOR(16#04#, 4) then

                      --USRDATA:MSB
                      case i_remain_byte(1 downto 0) is
                      when "00" =>
                        i_usr_rxd((8 * 8) - 1 downto 8 * 7) <= p_in_rxll_data((8 * 4) - 1 downto 8 * 3);
                        i_usr_rxd((8 * 7) - 1 downto 8 * 6) <= p_in_rxll_data((8 * 3) - 1 downto 8 * 2);
                        i_usr_rxd((8 * 6) - 1 downto 8 * 5) <= p_in_rxll_data((8 * 2) - 1 downto 8 * 1);
                        i_usr_rxd((8 * 5) - 1 downto 8 * 4) <= p_in_rxll_data((8 * 1) - 1 downto 8 * 0);

                      when "01" =>
                        i_usr_rxd((8 * 8) - 1 downto 8 * 7) <= (others=>'0');--p_in_rxll_data((8 * 4) - 1 downto 8 * 3);
                        i_usr_rxd((8 * 7) - 1 downto 8 * 6) <= p_in_rxll_data((8 * 3) - 1 downto 8 * 2);
                        i_usr_rxd((8 * 6) - 1 downto 8 * 5) <= p_in_rxll_data((8 * 2) - 1 downto 8 * 1);
                        i_usr_rxd((8 * 5) - 1 downto 8 * 4) <= p_in_rxll_data((8 * 1) - 1 downto 8 * 0);

                      when "10" =>
                        i_usr_rxd((8 * 8) - 1 downto 8 * 7) <= (others=>'0');--p_in_rxll_data((8 * 4) - 1 downto 8 * 3);
                        i_usr_rxd((8 * 7) - 1 downto 8 * 6) <= (others=>'0');--p_in_rxll_data((8 * 3) - 1 downto 8 * 2);
                        i_usr_rxd((8 * 6) - 1 downto 8 * 5) <= p_in_rxll_data((8 * 2) - 1 downto 8 * 1);
                        i_usr_rxd((8 * 5) - 1 downto 8 * 4) <= p_in_rxll_data((8 * 1) - 1 downto 8 * 0);

                      when "11" =>
                        i_usr_rxd((8 * 8) - 1 downto 8 * 7) <= (others=>'0');--p_in_rxll_data((8 * 4) - 1 downto 8 * 3);
                        i_usr_rxd((8 * 7) - 1 downto 8 * 6) <= (others=>'0');--p_in_rxll_data((8 * 3) - 1 downto 8 * 2);
                        i_usr_rxd((8 * 6) - 1 downto 8 * 5) <= (others=>'0');--p_in_rxll_data((8 * 2) - 1 downto 8 * 1);
                        i_usr_rxd((8 * 5) - 1 downto 8 * 4) <= p_in_rxll_data((8 * 1) - 1 downto 8 * 0);

                      when others => null;
                      end case;

                      if i_dcnt = CONV_STD_LOGIC_VECTOR(16#02#, i_dcnt'length) then
                      i_ll_dst_rdy <= '1';
                      end if;
                      i_usr_rxd_eof <= '1';

                      if p_in_rxll_eof_n = '0' then
                      fsm_eth_rx_cs <= S_IDLE;
                      else
                      fsm_eth_rx_cs <= S_RX_WAIT_EOF;
                      end if;

                  else

                    i_usr_rxd((8 * 8) - 1 downto 8 * 7) <= p_in_rxll_data((8 * 4) - 1 downto 8 * 3);
                    i_usr_rxd((8 * 7) - 1 downto 8 * 6) <= p_in_rxll_data((8 * 3) - 1 downto 8 * 2);
                    i_usr_rxd((8 * 6) - 1 downto 8 * 5) <= p_in_rxll_data((8 * 2) - 1 downto 8 * 1);
                    i_usr_rxd((8 * 5) - 1 downto 8 * 4) <= p_in_rxll_data((8 * 1) - 1 downto 8 * 0);

                    i_ll_dst_rdy <= '1';

                    if p_in_rxll_eof_n = '0' then
                    i_rxll_eof_det <= '1';
                    end if;
                    fsm_eth_rx_cs <= S_RX_END;

                  end if;

              else

                i_usr_rxd((8 * 4) - 1 downto 8 * 0) <= sr_rxll_data;
                i_usr_rxd((8 * 8) - 1 downto 8 * 4) <= p_in_rxll_data((8 * 4) - 1 downto 8 * 0);

                i_dcnt <= i_dcnt + 1;

              end if;--if i_dcnt = i_usrpkt_len_2dw then

          end if;

        when S_RX_END =>

          if p_in_rxbuf_full = '0' then

              --USRDATA:MSB
              i_usr_rxd((8 * 8) - 1 downto 8 * 4) <= (others=>'0');

              --USRDATA:LSB
              case i_remain_byte(1 downto 0) is
              when "00" =>
                i_usr_rxd((8 * 4) - 1 downto 8 * 3) <= sr_rxll_data((8 * 4) - 1 downto 8 * 3);
                i_usr_rxd((8 * 3) - 1 downto 8 * 2) <= sr_rxll_data((8 * 3) - 1 downto 8 * 2);
                i_usr_rxd((8 * 2) - 1 downto 8 * 1) <= sr_rxll_data((8 * 2) - 1 downto 8 * 1);
                i_usr_rxd((8 * 1) - 1 downto 8 * 0) <= sr_rxll_data((8 * 1) - 1 downto 8 * 0);

              when "01" =>
                i_usr_rxd((8 * 4) - 1 downto 8 * 3) <= (others=>'0');--sr_rxll_data((8 * 4) - 1 downto 8 * 3);
                i_usr_rxd((8 * 3) - 1 downto 8 * 2) <= sr_rxll_data((8 * 3) - 1 downto 8 * 2);
                i_usr_rxd((8 * 2) - 1 downto 8 * 1) <= sr_rxll_data((8 * 2) - 1 downto 8 * 1);
                i_usr_rxd((8 * 1) - 1 downto 8 * 0) <= sr_rxll_data((8 * 1) - 1 downto 8 * 0);

              when "10" =>
                i_usr_rxd((8 * 4) - 1 downto 8 * 3) <= (others=>'0');--sr_rxll_data((8 * 4) - 1 downto 8 * 3);
                i_usr_rxd((8 * 3) - 1 downto 8 * 2) <= (others=>'0');--sr_rxll_data((8 * 3) - 1 downto 8 * 2);
                i_usr_rxd((8 * 2) - 1 downto 8 * 1) <= sr_rxll_data((8 * 2) - 1 downto 8 * 1);
                i_usr_rxd((8 * 1) - 1 downto 8 * 0) <= sr_rxll_data((8 * 1) - 1 downto 8 * 0);

              when "11" =>
                i_usr_rxd((8 * 4) - 1 downto 8 * 3) <= (others=>'0');--sr_rxll_data((8 * 4) - 1 downto 8 * 3);
                i_usr_rxd((8 * 3) - 1 downto 8 * 2) <= (others=>'0');--sr_rxll_data((8 * 3) - 1 downto 8 * 2);
                i_usr_rxd((8 * 2) - 1 downto 8 * 1) <= (others=>'0');--sr_rxll_data((8 * 2) - 1 downto 8 * 1);
                i_usr_rxd((8 * 1) - 1 downto 8 * 0) <= sr_rxll_data((8 * 1) - 1 downto 8 * 0);

              when others => null;
              end case;

              i_usr_rxd_sof <= '0';
              i_usr_rxd_eof <= '1';

              if i_rxll_eof_det = '1' then
              fsm_eth_rx_cs <= S_IDLE;
              else
              fsm_eth_rx_cs <= S_RX_WAIT_EOF;
              end if;

          end if;

        --------------------------------------
        --Ждем входных данных
        --------------------------------------
        when S_RX_WAIT_EOF =>

          i_ll_dst_rdy <= '0';
          i_usr_rxd_sof_en <= '0';
          i_usr_rxd_sof <= '0';
          i_usr_rxd_eof <= '0';
          i_usr_wr <= '0';
          i_dcnt <= (others=>'0');
          i_rxll_eof_det <= '0';

          if p_in_rxll_src_rdy_n = '0' and p_in_rxll_eof_n = '0' then
          fsm_eth_rx_cs <= S_IDLE;
          end if;

      end case;

    end if;--if p_in_rxbuf_full = '0' then
  end if;
end if;
end process;


process(p_in_clk)
begin
if rising_edge(p_in_clk) then
i_rxbuf_din <= i_usr_rxd;
i_rxbuf_wr <= not p_in_rxbuf_full and ((not p_in_rxll_src_rdy_n and i_usr_wr) or i_ll_dst_rdy or i_usr_rxd_eof);
i_rxd_sof <= not p_in_rxbuf_full and (not p_in_rxll_src_rdy_n or i_ll_dst_rdy) and i_usr_wr and i_usr_rxd_sof;
i_rxd_eof <= not p_in_rxbuf_full and i_usr_rxd_eof;
end if;
end process;

p_out_rxbuf_din <= i_rxbuf_din;
p_out_rxbuf_wr <= i_rxbuf_wr;
p_out_rxd_sof <= i_rxd_sof;
p_out_rxd_eof <= i_rxd_eof;

p_out_rxll_dst_rdy_n <= i_ll_dst_rdy or p_in_rxbuf_full;


--------------------------------------
--Управление передачей Pause Frame
--------------------------------------
p_out_pause_req <= '0';
p_out_pause_val <= (others=>'0');



--END MAIN
end behavioral;

