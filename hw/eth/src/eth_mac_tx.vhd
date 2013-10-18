-------------------------------------------------------------------------
-- Company     : Linkos
-- Engineer    : Golovachenko Victor
--
-- Create Date : 01.05.2011 16:43:52
-- Module Name : eth_mac_tx
--
-- Назначение/Описание :
--
--
-- Revision:
-- Revision 1.00 - Передача MAC FRAME. Модуль вычитывает данных из пользовательского буфера, определяет
--                 размер передоваемого пакета (fst WORD пользовательских данных) + вставляет
--                 mac адреса (DST/SRC) в выходной MAC FRAME и пользовательские данных
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

entity eth_mac_tx is
generic(
G_ETH : TEthGeneric;
G_DBG : string:="OFF";
G_SIM : string:="OFF"
);
port(
--------------------------------------
--Управление
--------------------------------------
p_in_cfg             : in    TEthCfg;

--------------------------------------
--Связь с пользовательским TXBUF
--------------------------------------
p_in_txbuf_dout      : in    std_logic_vector(G_ETH.usrbuf_dwidth - 1 downto 0);
p_out_txbuf_rd       : out   std_logic;
p_in_txbuf_empty     : in    std_logic;
--p_in_txd_rdy         : in    std_logic;

--------------------------------------
--Связь с Local link TxFIFO
--------------------------------------
p_out_txll_data      : out   std_logic_vector(G_ETH.phy_dwidth - 1 downto 0);
p_out_txll_sof_n     : out   std_logic;
p_out_txll_eof_n     : out   std_logic;
p_out_txll_src_rdy_n : out   std_logic;
p_in_txll_dst_rdy_n  : in    std_logic;
p_out_txll_rem       : out   std_logic_vector((G_ETH.phy_dwidth / 8) - 1 downto 0);

--------------------------------------------------
--Технологические сигналы
--------------------------------------------------
p_in_tst             : in    std_logic_vector(31 downto 0);
p_out_tst            : out   std_logic_vector(31 downto 0);

--------------------------------------
--SYSTEM
--------------------------------------
p_in_clk             : in    std_logic;
p_in_rst             : in    std_logic
);
end eth_mac_tx;

architecture behavioral of eth_mac_tx is

type TEth_fsm_tx is (
S_IDLE,
S_TX_DST,
S_TX_SRC,
S_TX_LEN,
S_TX_D,
S_TX_DONE
);
signal fsm_eth_tx_cs: TEth_fsm_tx;

signal i_bcnt                 : std_logic_vector(log2(p_in_txbuf_dout'length / p_out_txll_data'length) - 1 downto 0);
signal i_dcnt                 : std_logic_vector(15 downto 0);

signal i_txbuf_rden           : std_logic;
signal i_usrpkt_len_byte      : std_logic_vector(15 downto 0);
signal i_usrpkt_len           : std_logic_vector(15 downto 0);

signal i_mac_dlen_byte        : std_logic_vector(15 downto 0);
signal i_mac_dlen_cnt         : std_logic_vector(15 downto 0);
signal i_mac_dlen_cnt_set     : std_logic_vector(15 downto 0);

signal i_tx_maclen_byte       : std_logic_vector(15 downto 0);

signal i_ll_data              : std_logic_vector(p_out_txll_data'range);
signal i_ll_sof_n             : std_logic;
signal i_ll_eof_n             : std_logic;
signal i_ll_src_rdy_n         : std_logic;
signal i_ll_rem               : std_logic_vector(p_out_txll_rem'range);
signal i_ll_dlast             : std_logic;

signal tst_fms_cs             : std_logic_vector(2 downto 0);
signal tst_fms_cs_dly         : std_logic_vector(tst_fms_cs'range);
signal tst_txbuf_empty        : std_logic;
signal tst_ll_dst_rdy_n       : std_logic;
signal tst_txbuf_d            : std_logic_vector(p_in_txbuf_dout'range);
signal tst_txbuf_rd           : std_logic;


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
    tst_txbuf_empty <= '0'; tst_ll_dst_rdy_n <= '0';
    tst_fms_cs_dly <= (others=>'0');
    p_out_tst(31 downto 1) <= (others=>'0');
  else

    tst_txbuf_empty <= p_in_txbuf_empty; tst_ll_dst_rdy_n <= p_in_txll_dst_rdy_n;
    tst_fms_cs_dly <= tst_fms_cs;
    p_out_tst(0) <= OR_reduce(tst_fms_cs_dly) or tst_txbuf_empty or OR_reduce(i_ll_rem) or tst_ll_dst_rdy_n;
  end if;
end if;
end process ltstout;

tst_fms_cs<=CONV_STD_LOGIC_VECTOR(16#01#, tst_fms_cs'length) when fsm_eth_tx_cs = S_TX_DST   else
            CONV_STD_LOGIC_VECTOR(16#02#, tst_fms_cs'length) when fsm_eth_tx_cs = S_TX_LEN   else
            CONV_STD_LOGIC_VECTOR(16#03#, tst_fms_cs'length) when fsm_eth_tx_cs = S_TX_SRC   else
            CONV_STD_LOGIC_VECTOR(16#04#, tst_fms_cs'length) when fsm_eth_tx_cs = S_TX_D     else
            CONV_STD_LOGIC_VECTOR(16#05#, tst_fms_cs'length) when fsm_eth_tx_cs = S_TX_DONE  else
            CONV_STD_LOGIC_VECTOR(16#00#, tst_fms_cs'length);-- when fsm_eth_tx_cs = S_IDLE   else

end generate gen_dbg_on;



i_usrpkt_len_byte <= i_mac_dlen_byte
                      + CONV_STD_LOGIC_VECTOR(p_in_txbuf_dout'length / 8, i_usrpkt_len_byte'length);
i_usrpkt_len <= EXT(i_usrpkt_len_byte(i_usrpkt_len_byte'high
                                      downto log2(p_in_txbuf_dout'length / 8)), i_usrpkt_len_byte'length);


gen_ll_dwith8 : if (p_out_txll_data'length / 8) = 1 generate
i_mac_dlen_cnt_set <= i_mac_dlen_byte;
end generate;--gen_ll_dwith8

gen_ll_dwith : if (p_out_txll_data'length / 8) /= 1 generate
i_mac_dlen_cnt_set <= EXT(i_mac_dlen_byte(i_mac_dlen_byte'high
                                          downto log2(p_out_txll_data'length / 8)), i_usrpkt_len_byte'length)
                      + OR_reduce(i_mac_dlen_byte(log2(p_out_txll_data'length / 8) - 1 downto 0));
end generate;--gen_ll_dwith

---------------------------------------------
--Автомат загрузки данных в ядро ETH
---------------------------------------------
process(p_in_clk)
begin
if rising_edge(p_in_clk) then
  if p_in_rst = '1' then
    fsm_eth_tx_cs <= S_IDLE;

    i_bcnt <= (others=>'0');
    i_dcnt <= (others=>'0');

    i_ll_data <= (others=>'0');
    i_ll_sof_n <= '1';
    i_ll_eof_n <= '1';
    i_ll_src_rdy_n <= '1';
    i_ll_rem <= (others=>'0');
    i_ll_dlast <= '0';

    i_mac_dlen_byte <= (others=>'0');
    i_mac_dlen_cnt <= (others=>'0');

    i_txbuf_rden <= '0';

    i_tx_maclen_byte <= (others=>'0');

  else

    if p_in_txll_dst_rdy_n = '0' then

      case fsm_eth_tx_cs is

        --------------------------------------
        --Ждем входных данных
        --------------------------------------
        when S_IDLE =>

          i_bcnt <= (others=>'0');
          i_dcnt <= (others=>'0');

          i_ll_sof_n <= '1';
          i_ll_eof_n <= '1';
          i_ll_src_rdy_n <= '1';
          i_ll_rem<=(others=>'0');
          i_ll_dlast <= '0';

          if p_in_txbuf_empty = '0' then

            i_mac_dlen_byte((8 * 2) - 1 downto 8 * 0) <= p_in_txbuf_dout((8 * 2) - 1 downto 8 * 0);

            if G_ETH.mac_length_swap = 0 then
            --Отправка: первый ст. байт
            i_tx_maclen_byte((8 * 2) - 1 downto 8 * 1) <= p_in_txbuf_dout((8 * 1) - 1 downto 8 * 0);
            i_tx_maclen_byte((8 * 1) - 1 downto 8 * 0) <= p_in_txbuf_dout((8 * 2) - 1 downto 8 * 1);

            else --if G_ETH.mac_length_swap = 1 then
            --Отправка: первый мл. байт
            i_tx_maclen_byte((8 * 2) - 1 downto 8 * 1) <= p_in_txbuf_dout((8 * 2) - 1 downto 8 * 1);
            i_tx_maclen_byte((8 * 1) - 1 downto 8 * 0) <= p_in_txbuf_dout((8 * 1) - 1 downto 8 * 0);

            end if;

            fsm_eth_tx_cs <= S_TX_DST;

          end if;


        --------------------------------------
        --MAC_DST
        --------------------------------------
        when S_TX_DST =>

          i_ll_src_rdy_n <= '0';
          i_ll_sof_n <= OR_reduce(i_dcnt(3 downto 0));

          for i in 0 to (p_in_cfg.mac.dst'length / (i_ll_data'length / 8)) - 1 loop
            if i_dcnt(2 downto 0) = i then
              for y in 0 to (i_ll_data'length / 8) - 1 loop
              i_ll_data((8 * (y + 1)) - 1 downto (8 * y)) <= p_in_cfg.mac.dst(((i_ll_data'length / 8) * i) + y);
              end loop;
            end if;
          end loop;

          if i_dcnt = CONV_STD_LOGIC_VECTOR((p_in_cfg.mac.dst'length / (i_ll_data'length / 8)) - 1
                                                                                      , i_dcnt'length) then
            i_dcnt <= (others=>'0');
            fsm_eth_tx_cs <= S_TX_SRC;
          else
            i_dcnt <= i_dcnt + 1;
          end if;


        --------------------------------------
        --MAC_SRC
        --------------------------------------
        when S_TX_SRC =>

          for i in 0 to (p_in_cfg.mac.dst'length / (i_ll_data'length / 8)) - 1 loop
            if i_dcnt(2 downto 0) = i then
              for y in 0 to (i_ll_data'length / 8) - 1 loop
              i_ll_data((8 * (y + 1)) - 1 downto (8 * y)) <= p_in_cfg.mac.src(((i_ll_data'length / 8) * i) + y);
              end loop;
            end if;
          end loop;

          if i_dcnt = CONV_STD_LOGIC_VECTOR((p_in_cfg.mac.src'length / (i_ll_data'length / 8)) - 1
                                                                                    , i_dcnt'length) then
            i_dcnt <= (others=>'0');
            fsm_eth_tx_cs <= S_TX_LEN;
          else
            i_dcnt <= i_dcnt + 1;
          end if;


        --------------------------------------
        --MAC_LEN
        --------------------------------------
        when S_TX_LEN =>

          for i in 0 to (i_tx_maclen_byte'length / i_ll_data'length) - 1 loop
            if i_dcnt(2 downto 0) = i then
              i_ll_data <= i_tx_maclen_byte((8 * (i_ll_data'length / 8) * (i + 1)) - 1
                                      downto 8 * (i_ll_data'length / 8) * i);
            end if;
          end loop;

          if i_dcnt = CONV_STD_LOGIC_VECTOR((i_tx_maclen_byte'length / i_ll_data'length) - 1
                                                                                , i_dcnt'length) then
            i_dcnt <= (others=>'0');
            i_bcnt <= CONV_STD_LOGIC_VECTOR(i_tx_maclen_byte'length / i_ll_data'length, i_bcnt'length);
            i_txbuf_rden <= '1';
            i_mac_dlen_cnt <= i_mac_dlen_cnt_set - 1;
            fsm_eth_tx_cs <= S_TX_D;
          else
            i_dcnt <= i_dcnt + 1;
          end if;


        --------------------------------------
        --MAC_DATA
        --------------------------------------
        when S_TX_D =>

          if p_in_txbuf_empty = '0' then

              if i_dcnt = i_usrpkt_len - 1 then

                  if i_mac_dlen_cnt = (i_mac_dlen_cnt'range =>'0') then
                    i_ll_rem(0) <= i_mac_dlen_byte(0);
                    i_ll_eof_n <= '0';
                    i_ll_dlast <= '1';
                    fsm_eth_tx_cs <= S_TX_DONE;
                  end if;

              else

                  if AND_reduce(i_bcnt) = '1' then
                    i_dcnt <= i_dcnt + 1;
                    i_ll_eof_n <= '1';
                  end if;

              end if;

              for i in 0 to (p_in_txbuf_dout'length / i_ll_data'length) - 1 loop
                if i_bcnt = i then
                  i_ll_data <= p_in_txbuf_dout((8 * (i_ll_data'length / 8) * (i + 1)) - 1
                                        downto (8 * (i_ll_data'length / 8) * i));
                end if;
              end loop;

              i_bcnt <= i_bcnt + 1;--счетчик байт для p_in_txbuf_dout
              i_mac_dlen_cnt <= i_mac_dlen_cnt - 1;

          end if;--if p_in_txbuf_empty='0' then

        when S_TX_DONE =>

          i_bcnt <= (others=>'0');
          i_dcnt <= (others=>'0');

          i_ll_sof_n <= '1';
          i_ll_eof_n <= '1';
          i_ll_src_rdy_n <= '1';
          i_ll_rem <= (others=>'0');
          i_ll_dlast <= '0';

          i_txbuf_rden <= '0';

          fsm_eth_tx_cs <= S_IDLE;

      end case;

    end if;--if p_in_txll_dst_rdy_n = '0' then
  end if;
end if;
end process;

p_out_txbuf_rd <= not p_in_txbuf_empty and (i_txbuf_rden and (AND_reduce(i_bcnt) or i_ll_dlast))
                  and not p_in_txll_dst_rdy_n
                  and not i_ll_src_rdy_n;

p_out_txll_data <= i_ll_data;
p_out_txll_sof_n <= i_ll_sof_n;
p_out_txll_eof_n <= i_ll_eof_n;
p_out_txll_src_rdy_n <= ((i_ll_sof_n and i_ll_src_rdy_n) or p_in_txbuf_empty) and not i_ll_dlast;
p_out_txll_rem <= i_ll_rem;


--END MAIN
end behavioral;
