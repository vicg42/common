-------------------------------------------------------------------------
-- Company     : Linkos
-- Engineer    : Golovachenko Victor
--
-- Create Date : 02.05.2011 12:25:51
-- Module Name : eth_rx
--
-- Назначение/Описание :
--
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
p_in_rxll_rem         : in    std_logic_vector(G_ETH.phy_dwidth/8 - 1 downto 0);

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
S_RX_DST,
S_RX_SRC,
S_RX_LEN,
S_RX_LEN_CHK,
S_RX_D
);
signal fsm_eth_rx_cs: TEth_fsm_rx;

signal i_bcnt                 : std_logic_vector(log2(p_out_rxbuf_din'length / p_in_rxll_data'length) - 1 downto 0);
signal i_dcnt                 : std_logic_vector(15 downto 0);

signal i_rx_mac_dst           : TEthMacAdr;
signal i_rx_mac_valid         : std_logic_vector(i_rx_mac_dst'length - 1 downto 0);

signal i_rx_mac_lentype       : std_logic_vector(15 downto 0);
signal i_rx_lentype           : std_logic_vector(15 downto 0);

signal i_usrpkt_len           : std_logic_vector(15 downto 0);

signal i_usr_wr               : std_logic;
signal i_usr_rxd              : std_logic_vector(p_out_rxbuf_din'range);
signal i_usr_sof_en           : std_logic;
signal i_usr_eof              : std_logic;

signal i_ll_dst_rdy           : std_logic;

signal tst_fms_cs             : std_logic_vector(2 downto 0);
signal tst_fms_cs_dly         : std_logic_vector(tst_fms_cs'range);
signal tst_rxll_sof_n         : std_logic;
signal tst_rxll_eof_n         : std_logic;
signal tst_rxll_src_rdy_n     : std_logic;
signal tst_rxbuf_full         : std_logic;


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
  if p_in_rst = '1' then
    tst_rxll_sof_n <= '0';
    tst_rxll_eof_n <= '0';
    tst_rxll_src_rdy_n <= '0';
    tst_rxbuf_full <= '0';
    tst_fms_cs_dly <= (others=>'0');
    p_out_tst(31 downto 1) <= (others=>'0');
  else

    tst_rxll_sof_n <= p_in_rxll_sof_n;
    tst_rxll_eof_n <= p_in_rxll_eof_n;
    tst_rxll_src_rdy_n <= p_in_rxll_src_rdy_n;
    tst_rxbuf_full <= p_in_rxbuf_full;
    tst_fms_cs_dly <= tst_fms_cs;

    p_out_tst(0) <= OR_reduce(tst_fms_cs_dly) or tst_rxll_src_rdy_n
                  or tst_rxll_eof_n or tst_rxll_sof_n or tst_rxbuf_full or i_ll_dst_rdy;
  end if;
end if;
end process ltstout;

tst_fms_cs<=CONV_STD_LOGIC_VECTOR(16#01#, tst_fms_cs'length) when fsm_eth_rx_cs = S_RX_DST      else
            CONV_STD_LOGIC_VECTOR(16#02#, tst_fms_cs'length) when fsm_eth_rx_cs = S_RX_SRC      else
            CONV_STD_LOGIC_VECTOR(16#03#, tst_fms_cs'length) when fsm_eth_rx_cs = S_RX_LEN      else
            CONV_STD_LOGIC_VECTOR(16#04#, tst_fms_cs'length) when fsm_eth_rx_cs = S_RX_LEN_CHK  else
            CONV_STD_LOGIC_VECTOR(16#05#, tst_fms_cs'length) when fsm_eth_rx_cs = S_RX_D        else
            CONV_STD_LOGIC_VECTOR(16#00#, tst_fms_cs'length);--when fsm_eth_rx_cs = S_IDLE        else
end generate gen_dbg_on;


gen_swp_off : if G_ETH.mac_length_swap = 0 generate
i_rx_lentype((8 * 2) - 1 downto 8 * 1) <= i_rx_mac_lentype((8 * 1) - 1 downto 8 * 0);
i_rx_lentype((8 * 1) - 1 downto 8 * 0) <= i_rx_mac_lentype((8 * 2) - 1 downto 8 * 1);--первый ст. байт
end generate gen_swp_off;

gen_swp_on : if G_ETH.mac_length_swap = 1 generate
i_rx_lentype((8 * 2) - 1 downto 8 * 1) <= i_rx_mac_lentype((8 * 2) - 1 downto 8 * 1);
i_rx_lentype((8 * 1) - 1 downto 8 * 0) <= i_rx_mac_lentype((8 * 1) - 1 downto 8 * 0);--первый мл. байт
end generate gen_swp_on;


gen_rx_mac_check : for i in 0 to p_in_cfg.mac.src'length - 1 generate
i_rx_mac_valid(i) <= '1' when i_rx_mac_dst(i) = p_in_cfg.mac.src(i) else '0';
--i_rx_mac_valid(i) <= '1' when i_rx_mac_dst(i) = p_in_cfg.mac.dst(i) else '0';--for TEST
end generate gen_rx_mac_check;


gen_ll_dwith8 : if (p_in_rxll_data'length / 8) = 1 generate
i_usrpkt_len <= i_rx_lentype;
end generate;--gen_ll_dwith8

gen_ll_dwith : if (p_in_rxll_data'length / 8) /= 1 generate
i_usrpkt_len <= EXT(i_rx_lentype(i_rx_lentype'high
                              downto log2(p_in_rxll_data'length / 8)), i_rx_lentype'length)
                  + OR_reduce(i_rx_lentype(log2(p_in_rxll_data'length / 8) - 1 downto 0));
end generate;--gen_ll_dwith



---------------------------------------------
--Автомат приема данных из ядра ETH
---------------------------------------------
process(p_in_clk)
begin
if rising_edge(p_in_clk) then
  if p_in_rst = '1' then

    fsm_eth_rx_cs <= S_IDLE;

    i_bcnt <= (others=>'0');
    i_dcnt <= (others=>'0');

    for i in 0 to i_rx_mac_dst'length - 1 loop
    i_rx_mac_dst(i) <= (others=>'0');
    end loop;

    i_rx_mac_lentype <= (others=>'0');

    i_ll_dst_rdy <= '0';

    i_usr_rxd <= (others=>'0');
    i_usr_sof_en <= '0';
    i_usr_eof <= '0';
    i_usr_wr <= '0';

  else

      case fsm_eth_rx_cs is

        --------------------------------------
        --Ждем входных данных
        --------------------------------------
        when S_IDLE =>

          if p_in_rxbuf_full = '0' then
            i_bcnt <= (others=>'0');

            i_ll_dst_rdy <= '0';
            i_usr_sof_en <= '0';
            i_usr_eof <= '0';

            if p_in_rxll_sof_n = '0' and p_in_rxll_src_rdy_n = '0' then
              for i in 0 to 0 loop
                for y in 0 to (p_in_rxll_data'length / 8) - 1 loop
                i_rx_mac_dst(i + y) <= p_in_rxll_data((8 * (y + 1)) - 1 downto (8 * y));
                end loop;
              end loop;
              i_dcnt <= CONV_STD_LOGIC_VECTOR(1, i_dcnt'length);
              fsm_eth_rx_cs <= S_RX_DST;
            end if;
          end if;

        --------------------------------------
        --MAC_DST
        --------------------------------------
        when S_RX_DST =>

          if p_in_rxbuf_full = '0' and p_in_rxll_src_rdy_n = '0' then

            for i in 1 to (i_rx_mac_dst'length / (p_in_rxll_data'length / 8)) - 1 loop
              if i_dcnt(2 downto 0) = i then
                for y in 0 to (p_in_rxll_data'length / 8) - 1 loop
                i_rx_mac_dst((p_in_rxll_data'length / 8 * i) + y) <= p_in_rxll_data((8 * (y + 1)) - 1
                                                                              downto (8 * y));
                end loop;
              end if;
            end loop;

            if i_dcnt = CONV_STD_LOGIC_VECTOR((i_rx_mac_dst'length / (p_in_rxll_data'length / 8)) - 1
                                                                                      , i_dcnt'length) then
              i_dcnt <= (others=>'0');
              fsm_eth_rx_cs <= S_RX_SRC;
            else
              i_dcnt <= i_dcnt + 1;
            end if;

          end if;


        --------------------------------------
        --MAC_SRC
        --------------------------------------
        when S_RX_SRC =>

          if p_in_rxbuf_full = '0' and p_in_rxll_src_rdy_n = '0' then

            if i_dcnt = CONV_STD_LOGIC_VECTOR((i_rx_mac_dst'length / (p_in_rxll_data'length / 8)) - 1
                                                                                    , i_dcnt'length) then
              i_dcnt <= (others=>'0');
              fsm_eth_rx_cs <= S_RX_LEN;
            else
              i_dcnt <= i_dcnt + 1;
            end if;

          end if;

        --------------------------------------
        --MAC_LEN
        --------------------------------------
        when S_RX_LEN =>

          if p_in_rxbuf_full = '0' and p_in_rxll_src_rdy_n = '0' then

            for i in 0 to (i_rx_lentype'length / p_in_rxll_data'length) - 1 loop
              if i_dcnt(1 downto 0) = i then
                i_rx_mac_lentype(8 * (p_in_rxll_data'length / 8) * (i + 1) - 1
                          downto 8 * (p_in_rxll_data'length / 8) * i) <= p_in_rxll_data;
              end if;
            end loop;

            if i_dcnt = CONV_STD_LOGIC_VECTOR((i_rx_lentype'length / p_in_rxll_data'length) - 1
                                                                                , i_dcnt'length) then
              i_dcnt <= (others=>'0');
              i_ll_dst_rdy <= '1';
              fsm_eth_rx_cs <= S_RX_LEN_CHK;
            else
              i_dcnt <= i_dcnt + 1;
            end if;

          end if;

        when S_RX_LEN_CHK =>

          if p_in_rxbuf_full = '0' and p_in_rxll_src_rdy_n = '0' then

            i_ll_dst_rdy <= '0';

            if AND_reduce(i_rx_mac_valid) = '1' then
            --пакет наш:
              i_usr_rxd((8 * 2) - 1 downto 8 * 0) <= i_rx_lentype((8 * 2) - 1 downto 8 * 0);
              i_usr_sof_en <= '1';
              i_bcnt <= CONV_STD_LOGIC_VECTOR(i_rx_lentype'length / p_in_rxll_data'length, i_bcnt'length);
              fsm_eth_rx_cs <= S_RX_D;
            else
            --пакет НЕ наш:
              fsm_eth_rx_cs <= S_IDLE;
            end if;

          end if;

        --------------------------------------
        --MAC_DATA
        --------------------------------------
        when S_RX_D =>

          if p_in_rxbuf_full = '0' and p_in_rxll_src_rdy_n = '0' then

              if i_dcnt = i_usrpkt_len - 1 then

                  i_usr_eof <= '1';
                  i_usr_wr <= '0';

                  for i in 0 to (i_usr_rxd'length / p_in_rxll_data'length) - 1 loop
                    if (i > i_bcnt) and AND_reduce(i_bcnt) = '0'  then
                      i_usr_rxd(8 * (p_in_rxll_data'length / 8) * (i + 1) - 1
                          downto 8 * (p_in_rxll_data'length / 8) * i) <= (others=>'0');
                    elsif i_bcnt = i then
                      i_usr_rxd(8 * (p_in_rxll_data'length / 8) * (i + 1) - 1
                          downto 8 * (p_in_rxll_data'length / 8) * i) <= p_in_rxll_data;
                    end if;
                  end loop;

                  fsm_eth_rx_cs <= S_IDLE;

              else

                  for i in 0 to (i_usr_rxd'length / p_in_rxll_data'length) - 1 loop
                    if i_bcnt = i then
                      i_usr_rxd(8 * (p_in_rxll_data'length / 8) * (i + 1) - 1
                          downto 8 * (p_in_rxll_data'length / 8) * i) <= p_in_rxll_data;
                    end if;
                  end loop;

                  i_bcnt <= i_bcnt + 1;--счетчик байт для p_out_rxbuf_din
                  i_usr_wr <= AND_reduce(i_bcnt);

                  i_dcnt <= i_dcnt + 1;

              end if;

              if OR_reduce(i_bcnt) = '0' then
              i_usr_sof_en <= '0';
              end if;

          end if;

      end case;

  end if;
end if;
end process;


p_out_rxbuf_din <= i_usr_rxd;
p_out_rxbuf_wr <= not p_in_rxbuf_full and ((not p_in_rxll_src_rdy_n and i_usr_wr) or i_usr_eof);

p_out_rxd_sof <= not p_in_rxbuf_full and ( (not p_in_rxll_src_rdy_n and (i_usr_wr and i_usr_sof_en))
                                            or (i_usr_eof and i_usr_sof_en) );

p_out_rxd_eof <= not p_in_rxbuf_full and i_usr_eof;

p_out_rxll_dst_rdy_n <= p_in_rxbuf_full or i_ll_dst_rdy;


--------------------------------------
--Управление передачей Pause Frame
--------------------------------------
p_out_pause_req<='0';
p_out_pause_val<=(others=>'0');



--END MAIN
end behavioral;

