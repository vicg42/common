-------------------------------------------------------------------------
-- Company     : Linkos
-- Engineer    : Golovachenko Victor
--
-- Create Date : 02.02.2014 14:49:20
-- Module Name : eth_mac_tx
--
-- Назначение/Описание :
-- Реализация для шины данных 64bit!!!!
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
S_TX_MAC_A0,
S_TX_MAC_A00,
S_TX_MAC_A000,
S_TX_MAC_A1,
S_TX_MAC_D,
S_TX_END
);
signal fsm_eth_tx_cs: TEth_fsm_tx;

signal i_usrpkt_len_byte,i_usrpkt_len2_byte      : std_logic_vector(15 downto 0);
signal i_usrpkt_len       : std_logic_vector(15 downto 0);

signal i_mac_dlen_byte        : std_logic_vector(15 downto 0);
signal i_remain_byte          : std_logic_vector(15 downto 0);
signal i_dcnt                 : std_logic_vector(15 downto 0);

signal sr_txbuf_dout          : std_logic_vector(p_in_txbuf_dout'range);
signal i_bus_dcnt             : std_logic_vector(0 downto 0);
signal i_ll_data              : std_logic_vector(p_out_txll_data'range);
signal i_ll_sof_n             : std_logic;
signal i_ll_eof_n             : std_logic;
signal i_ll_src_rdy_n         : std_logic;
signal i_ll_rem               : std_logic_vector(p_out_txll_rem'range);
signal i_ll_dlast             : std_logic;

signal tst_fms_cs             : std_logic_vector(2 downto 0);
signal tst_fms_cs_dly         : std_logic_vector(tst_fms_cs'range) := (others => '0');
signal tst_txbuf_empty        : std_logic := '0';
signal tst_ll_dst_rdy_n       : std_logic := '0';
--signal tst_txbuf_d            : std_logic_vector(p_in_txbuf_dout'range) := (others => '1');
signal tst_txbuf_rd           : std_logic := '0';
signal tst_tx_start           : std_logic := '0';

signal i_remain_usrpkt_len_byte : std_logic_vector(log2(p_out_txll_data'length / 8) - 1 downto 0);

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

--    tst_txbuf_d <= p_in_txbuf_dout;
    tst_txbuf_rd <= not p_in_txbuf_empty and not p_in_txll_dst_rdy_n and not i_ll_src_rdy_n;

    tst_txbuf_empty <= p_in_txbuf_empty; tst_ll_dst_rdy_n <= p_in_txll_dst_rdy_n;
    tst_fms_cs_dly <= tst_fms_cs;
    p_out_tst(0) <= OR_reduce(tst_fms_cs_dly) or tst_txbuf_empty or tst_ll_dst_rdy_n or tst_txbuf_rd or OR_reduce(i_remain_byte);
    p_out_tst(1) <= tst_tx_start;

    if fsm_eth_tx_cs = S_TX_MAC_A0 then
      tst_tx_start <= '1';
    else
      tst_tx_start <= '0';
    end if;
  end if;
end process ltstout;

tst_fms_cs <= CONV_STD_LOGIC_VECTOR(16#01#, tst_fms_cs'length) when fsm_eth_tx_cs = S_TX_MAC_A0  else
              CONV_STD_LOGIC_VECTOR(16#02#, tst_fms_cs'length) when fsm_eth_tx_cs = S_TX_MAC_A00  else
              CONV_STD_LOGIC_VECTOR(16#03#, tst_fms_cs'length) when fsm_eth_tx_cs = S_TX_MAC_A000 else
              CONV_STD_LOGIC_VECTOR(16#04#, tst_fms_cs'length) when fsm_eth_tx_cs = S_TX_MAC_A1  else
              CONV_STD_LOGIC_VECTOR(16#05#, tst_fms_cs'length) when fsm_eth_tx_cs = S_TX_MAC_D   else
              CONV_STD_LOGIC_VECTOR(16#06#, tst_fms_cs'length) when fsm_eth_tx_cs = S_TX_END     else
              CONV_STD_LOGIC_VECTOR(16#00#, tst_fms_cs'length);-- when fsm_eth_tx_cs = S_IDLE     else

end generate gen_dbg_on;

i_usrpkt_len_byte <= i_mac_dlen_byte + 6;--2 + 4 is Len byte count
i_usrpkt_len <= EXT(i_usrpkt_len_byte(i_usrpkt_len_byte'high
                          downto log2(p_out_txll_data'length / 8)), i_usrpkt_len_byte'length)
                  + OR_reduce(i_usrpkt_len_byte(log2(p_out_txll_data'length / 8) - 1 downto 0));

i_remain_usrpkt_len_byte <= i_usrpkt_len_byte(log2(p_out_txll_data'length / 8) - 1 downto 0);

--i_usrpkt_len2_byte <= i_mac_dlen_byte + 2;--2 + 4 is Len byte count

i_remain_byte <= (i_dcnt(i_dcnt'high - 3 downto 0) & "000") - i_usrpkt_len_byte;

---------------------------------------------
--Автомат загрузки данных в ядро ETH
---------------------------------------------
process(p_in_clk)
begin
if rising_edge(p_in_clk) then
  if p_in_rst = '1' then
    fsm_eth_tx_cs <= S_IDLE;

    i_ll_data <= (others=>'0');
    i_ll_sof_n <= '1';
    i_ll_eof_n <= '1';
    i_ll_src_rdy_n <= '1';
    i_ll_rem <= (others=>'1');
    i_ll_dlast <= '0';

    sr_txbuf_dout <= (others=>'0');
    i_mac_dlen_byte <= (others=>'0');
    i_dcnt <= (others=>'0');
    i_bus_dcnt <= (others=>'0');

  else

--    if p_in_txll_dst_rdy_n = '0' then

      case fsm_eth_tx_cs is

        --------------------------------------
        --Ждем входных данных
        --------------------------------------
        when S_IDLE =>

--        if p_in_txll_dst_rdy_n = '0' then
--          i_ll_sof_n <= '1';
          i_ll_eof_n <= '1';
          i_ll_src_rdy_n <= '1';
          i_ll_rem <= (others=>'1');
          i_ll_dlast <= '0';
          i_dcnt <= (others=>'0');

          if p_in_txbuf_empty = '0' then

            i_ll_data((8 * 8) - 1 downto 8 * 7) <= p_in_cfg.mac.src(1);
            i_ll_data((8 * 7) - 1 downto 8 * 6) <= p_in_cfg.mac.src(0);

            i_ll_data((8 * 2) - 1 downto 8 * 1) <= p_in_cfg.mac.dst(1);
            i_ll_data((8 * 3) - 1 downto 8 * 2) <= p_in_cfg.mac.dst(2);
            i_ll_data((8 * 4) - 1 downto 8 * 3) <= p_in_cfg.mac.dst(3);
            i_ll_data((8 * 5) - 1 downto 8 * 4) <= p_in_cfg.mac.dst(4);
            i_ll_data((8 * 6) - 1 downto 8 * 5) <= p_in_cfg.mac.dst(5);
            i_ll_data((8 * 1) - 1 downto 8 * 0) <= p_in_cfg.mac.dst(0);

            i_mac_dlen_byte((8 * 2) - 1 downto 8 * 0) <= p_in_txbuf_dout((8 * 2) - 1 downto 8 * 0);

            if p_in_txbuf_dout((8 * 2) - 1 downto 8 * 0) /= CONV_STD_LOGIC_VECTOR(0, 16) then
--              i_ll_sof_n <= '0';
              fsm_eth_tx_cs <= S_TX_MAC_A0;
            end if;
          end if;
--        end if;


        --------------------------------------
        --MACFRAME: отправка mac_dst
        --------------------------------------
        when S_TX_MAC_A0 =>

          if p_in_txll_dst_rdy_n = '0' then

            i_ll_rem <= (others=>'1');
--            i_ll_src_rdy_n <= '0';
--            i_ll_sof_n <= '0';
--            i_ll_eof_n <= '1';

            fsm_eth_tx_cs <= S_TX_MAC_A00;

          end if;

        when S_TX_MAC_A00 =>

            fsm_eth_tx_cs <= S_TX_MAC_A000;

        when S_TX_MAC_A000 =>

--            i_dcnt <= (others=>'0');--
            i_dcnt <= CONV_STD_LOGIC_VECTOR(1, i_dcnt'length);
--            i_bus_dcnt <= CONV_STD_LOGIC_VECTOR(1, i_bus_dcnt'length);
            i_ll_src_rdy_n <= '0';
            i_ll_sof_n <= '0';
            fsm_eth_tx_cs <= S_TX_MAC_A1;

        when S_TX_MAC_A1 =>

          if p_in_txll_dst_rdy_n = '0' then


            if G_ETH.mac_length_swap = 0 then
            --Отправка: первый ст. байт
            i_ll_data((8 * 6) - 1 downto 8 * 5) <= p_in_txbuf_dout((8 * 1) - 1 downto 8 * 0);
            i_ll_data((8 * 5) - 1 downto 8 * 4) <= p_in_txbuf_dout((8 * 2) - 1 downto 8 * 1);

            else --if G_ETH.mac_length_swap = 1 then
            --Отправка: первый мл. байт
            i_ll_data((8 * 6) - 1 downto 8 * 5) <= p_in_txbuf_dout((8 * 2) - 1 downto 8 * 1);
            i_ll_data((8 * 5) - 1 downto 8 * 4) <= p_in_txbuf_dout((8 * 1) - 1 downto 8 * 0);

            end if;

            i_ll_data((8 * 4) - 1 downto 8 * 3) <= p_in_cfg.mac.src(5);
            i_ll_data((8 * 3) - 1 downto 8 * 2) <= p_in_cfg.mac.src(4);
            i_ll_data((8 * 2) - 1 downto 8 * 1) <= p_in_cfg.mac.src(3);
            i_ll_data((8 * 1) - 1 downto 8 * 0) <= p_in_cfg.mac.src(2);

            i_ll_src_rdy_n <= '0';
            i_ll_sof_n <= '1';

            if i_mac_dlen_byte > CONV_STD_LOGIC_VECTOR(2, i_mac_dlen_byte'length) then

                if i_dcnt = i_usrpkt_len then
                    i_ll_dlast <= '1';
                    fsm_eth_tx_cs <= S_TX_END;
                else
                    i_dcnt <= i_dcnt + 1;
                    i_ll_data((8 * 8) - 1 downto 8 * 7) <= p_in_txbuf_dout((8 * 4) - 1 downto 8 * 3);
                    i_ll_data((8 * 7) - 1 downto 8 * 6) <= p_in_txbuf_dout((8 * 3) - 1 downto 8 * 2);

                    sr_txbuf_dout <= p_in_txbuf_dout;
                    i_bus_dcnt <= i_bus_dcnt + 1;

                    i_ll_eof_n <= '1';
                    fsm_eth_tx_cs <= S_TX_MAC_D;
                end if;

            else

                if i_mac_dlen_byte(0) = '1' then
                i_ll_rem(7 downto 4) <= "0111";
                i_ll_rem(3 downto 0) <= (others=>'1');
                else
                i_ll_rem(7 downto 0) <= (others=>'1');
                end if;

                if i_mac_dlen_byte(0) = '1' then
                i_ll_data((8 * 8) - 1 downto 8 * 7) <= (others=> '0');
                i_ll_data((8 * 7) - 1 downto 8 * 6) <= p_in_txbuf_dout((8 * 3) - 1 downto 8 * 2);

                i_ll_rem(7 downto 4) <= "0111";
                i_ll_rem(3 downto 0) <= (others=>'1');
                else
                i_ll_data((8 * 8) - 1 downto 8 * 7) <= p_in_txbuf_dout((8 * 4) - 1 downto 8 * 3);
                i_ll_data((8 * 7) - 1 downto 8 * 6) <= p_in_txbuf_dout((8 * 3) - 1 downto 8 * 2);

                i_ll_rem(7 downto 4) <= (others=>'1');
                i_ll_rem(3 downto 0) <= (others=>'1');
                end if;

                i_ll_dlast <= '1';
                i_ll_eof_n <= '0';
                fsm_eth_tx_cs <= S_IDLE;

            end if;
          end if;

        --------------------------------------
        --MACFRAME: отправка данных
        --------------------------------------
        when S_TX_MAC_D =>

          if p_in_txll_dst_rdy_n = '0' then
          if p_in_txbuf_empty = '0' then

--              if ((i_dcnt = i_usrpkt_len) and (i_remain_usrpkt_len_byte(3) = '1' or i_remain_usrpkt_len_byte = "0000"))
--                 or ( i_dcnt = (i_usrpkt_len - 1) and i_remain_usrpkt_len_byte(3) = '0') then
              if i_dcnt = i_usrpkt_len then
--              if i_dcnt = (i_usrpkt_len - 1) then

                  i_ll_dlast <= '1';
                  i_ll_src_rdy_n <= '0';
                  i_bus_dcnt <= (others=>'1');

                  fsm_eth_tx_cs <= S_TX_END;
              else

                i_dcnt <= i_dcnt + 1;
              i_bus_dcnt <= i_bus_dcnt + 1;

              end if;--if i_dcnt = i_usrpkt_len then

--              i_bus_dcnt <= i_bus_dcnt + 1;

              if AND_reduce(i_bus_dcnt) = '1' then
                sr_txbuf_dout <= p_in_txbuf_dout;
              end if;

              if i_dcnt = CONV_STD_LOGIC_VECTOR(2, i_dcnt'length) then

                i_ll_data((8 * 8) - 1 downto 8 * 7) <= sr_txbuf_dout((8 * 12) - 1 downto 8 * 11);
                i_ll_data((8 * 7) - 1 downto 8 * 6) <= sr_txbuf_dout((8 * 11) - 1 downto 8 * 10);
                i_ll_data((8 * 6) - 1 downto 8 * 5) <= sr_txbuf_dout((8 * 10) - 1 downto 8 *  9);
                i_ll_data((8 * 5) - 1 downto 8 * 4) <= sr_txbuf_dout((8 *  9) - 1 downto 8 *  8);
                i_ll_data((8 * 4) - 1 downto 8 * 3) <= sr_txbuf_dout((8 *  8) - 1 downto 8 *  7);
                i_ll_data((8 * 3) - 1 downto 8 * 2) <= sr_txbuf_dout((8 *  7) - 1 downto 8 *  6);
                i_ll_data((8 * 2) - 1 downto 8 * 1) <= sr_txbuf_dout((8 *  6) - 1 downto 8 *  5);
                i_ll_data((8 * 1) - 1 downto 8 * 0) <= sr_txbuf_dout((8 *  5) - 1 downto 8 *  4);

              elsif i_dcnt = CONV_STD_LOGIC_VECTOR(3, i_dcnt'length) then

                i_ll_data((8 * 8) - 1 downto 8 * 7) <= p_in_txbuf_dout((8 * 4) - 1 downto 8 * 3);
                i_ll_data((8 * 7) - 1 downto 8 * 6) <= p_in_txbuf_dout((8 * 3) - 1 downto 8 * 2);
                i_ll_data((8 * 6) - 1 downto 8 * 5) <= p_in_txbuf_dout((8 * 2) - 1 downto 8 * 1);
                i_ll_data((8 * 5) - 1 downto 8 * 4) <= p_in_txbuf_dout((8 * 1) - 1 downto 8 * 0);

                i_ll_data((8 * 4) - 1 downto 8 * 3) <= sr_txbuf_dout((8 * 16) - 1 downto 8 * 15);
                i_ll_data((8 * 3) - 1 downto 8 * 2) <= sr_txbuf_dout((8 * 15) - 1 downto 8 * 14);
                i_ll_data((8 * 2) - 1 downto 8 * 1) <= sr_txbuf_dout((8 * 14) - 1 downto 8 * 13);
                i_ll_data((8 * 1) - 1 downto 8 * 0) <= sr_txbuf_dout((8 * 13) - 1 downto 8 * 12);

              elsif i_dcnt >= CONV_STD_LOGIC_VECTOR(4, i_dcnt'length) then

                if i_dcnt(0) = '0' then

                  i_ll_data((8 * 8) - 1 downto 8 * 7) <= p_in_txbuf_dout((8 * 12) - 1 downto 8 * 11);
                  i_ll_data((8 * 7) - 1 downto 8 * 6) <= p_in_txbuf_dout((8 * 11) - 1 downto 8 * 10);
                  i_ll_data((8 * 6) - 1 downto 8 * 5) <= p_in_txbuf_dout((8 * 10) - 1 downto 8 *  9);
                  i_ll_data((8 * 5) - 1 downto 8 * 4) <= p_in_txbuf_dout((8 *  9) - 1 downto 8 *  8);
                  i_ll_data((8 * 4) - 1 downto 8 * 3) <= p_in_txbuf_dout((8 *  8) - 1 downto 8 *  7);
                  i_ll_data((8 * 3) - 1 downto 8 * 2) <= p_in_txbuf_dout((8 *  7) - 1 downto 8 *  6);
                  i_ll_data((8 * 2) - 1 downto 8 * 1) <= p_in_txbuf_dout((8 *  6) - 1 downto 8 *  5);
                  i_ll_data((8 * 1) - 1 downto 8 * 0) <= p_in_txbuf_dout((8 *  5) - 1 downto 8 *  4);

                else --if i_dcnt = CONV_STD_LOGIC_VECTOR(4, i_dcnt'length) then

                  i_ll_data((8 * 8) - 1 downto 8 * 7) <= p_in_txbuf_dout((8 * 4) - 1 downto 8 * 3);
                  i_ll_data((8 * 7) - 1 downto 8 * 6) <= p_in_txbuf_dout((8 * 3) - 1 downto 8 * 2);
                  i_ll_data((8 * 6) - 1 downto 8 * 5) <= p_in_txbuf_dout((8 * 2) - 1 downto 8 * 1);
                  i_ll_data((8 * 5) - 1 downto 8 * 4) <= p_in_txbuf_dout((8 * 1) - 1 downto 8 * 0);

                  i_ll_data((8 * 4) - 1 downto 8 * 3) <= sr_txbuf_dout((8 * 16) - 1 downto 8 * 15);
                  i_ll_data((8 * 3) - 1 downto 8 * 2) <= sr_txbuf_dout((8 * 15) - 1 downto 8 * 14);
                  i_ll_data((8 * 2) - 1 downto 8 * 1) <= sr_txbuf_dout((8 * 14) - 1 downto 8 * 13);
                  i_ll_data((8 * 1) - 1 downto 8 * 0) <= sr_txbuf_dout((8 * 13) - 1 downto 8 * 12);
                end if;

              end if;


--              case i_remain_byte(2 downto 0) is
--              when "0000" =>
--                  i_ll_data((8 * 8) - 1 downto 8 * 7) <= p_in_txbuf_dout((8 * 4) - 1 downto 8 * 3);
--                  i_ll_data((8 * 7) - 1 downto 8 * 6) <= p_in_txbuf_dout((8 * 3) - 1 downto 8 * 2);
--                  i_ll_data((8 * 6) - 1 downto 8 * 5) <= p_in_txbuf_dout((8 * 2) - 1 downto 8 * 1);
--                  i_ll_data((8 * 5) - 1 downto 8 * 4) <= p_in_txbuf_dout((8 * 1) - 1 downto 8 * 0);
--
--              when "01" =>
--                  i_ll_data((8 * 8) - 1 downto 8 * 7) <= (others=>'0');--p_in_txbuf_dout((8 * 4) - 1 downto 8 * 3);
--                  i_ll_data((8 * 7) - 1 downto 8 * 6) <= p_in_txbuf_dout((8 * 3) - 1 downto 8 * 2);
--                  i_ll_data((8 * 6) - 1 downto 8 * 5) <= p_in_txbuf_dout((8 * 2) - 1 downto 8 * 1);
--                  i_ll_data((8 * 5) - 1 downto 8 * 4) <= p_in_txbuf_dout((8 * 1) - 1 downto 8 * 0);
--
--              when "10" =>
--                  i_ll_data((8 * 8) - 1 downto 8 * 7) <= (others=>'0');--p_in_txbuf_dout((8 * 4) - 1 downto 8 * 3);
--                  i_ll_data((8 * 7) - 1 downto 8 * 6) <= (others=>'0');--p_in_txbuf_dout((8 * 3) - 1 downto 8 * 2);
--                  i_ll_data((8 * 6) - 1 downto 8 * 5) <= p_in_txbuf_dout((8 * 2) - 1 downto 8 * 1);
--                  i_ll_data((8 * 5) - 1 downto 8 * 4) <= p_in_txbuf_dout((8 * 1) - 1 downto 8 * 0);
--
--              when "11" =>
--                  i_ll_data((8 * 8) - 1 downto 8 * 7) <= (others=>'0');--p_in_txbuf_dout((8 * 4) - 1 downto 8 * 3);
--                  i_ll_data((8 * 7) - 1 downto 8 * 6) <= (others=>'0');--p_in_txbuf_dout((8 * 3) - 1 downto 8 * 2);
--                  i_ll_data((8 * 6) - 1 downto 8 * 5) <= (others=>'0');--p_in_txbuf_dout((8 * 2) - 1 downto 8 * 1);
--                  i_ll_data((8 * 5) - 1 downto 8 * 4) <= p_in_txbuf_dout((8 * 1) - 1 downto 8 * 0);
--
--              when others => null;
--              end case;


          end if;--if p_in_txbuf_empty = '0' then
          end if;

        when S_TX_END =>

            i_ll_src_rdy_n <= '1';

            i_bus_dcnt <= (others=>'0');

            i_ll_data((8 * 8) - 1 downto 8 * 7) <= p_in_txbuf_dout((8 * 4) - 1 downto 8 * 3);
            i_ll_data((8 * 7) - 1 downto 8 * 6) <= p_in_txbuf_dout((8 * 3) - 1 downto 8 * 2);
            i_ll_data((8 * 6) - 1 downto 8 * 5) <= p_in_txbuf_dout((8 * 2) - 1 downto 8 * 1);
            i_ll_data((8 * 5) - 1 downto 8 * 4) <= p_in_txbuf_dout((8 * 1) - 1 downto 8 * 0);

            i_ll_data((8 * 4) - 1 downto 8 * 3) <= sr_txbuf_dout((8 * 16) - 1 downto 8 * 15);
            i_ll_data((8 * 3) - 1 downto 8 * 2) <= sr_txbuf_dout((8 * 15) - 1 downto 8 * 14);
            i_ll_data((8 * 2) - 1 downto 8 * 1) <= sr_txbuf_dout((8 * 14) - 1 downto 8 * 13);
            i_ll_data((8 * 1) - 1 downto 8 * 0) <= sr_txbuf_dout((8 * 13) - 1 downto 8 * 12);

            i_ll_eof_n <= '0';
            fsm_eth_tx_cs <= S_IDLE;

      end case;

--    end if;--if p_in_txll_dst_rdy_n = '0' then
  end if;
end if;
end process;

p_out_txbuf_rd <= not p_in_txbuf_empty and not p_in_txll_dst_rdy_n and not i_ll_src_rdy_n and AND_reduce(i_bus_dcnt);

p_out_txll_data <= i_ll_data;
p_out_txll_sof_n <= i_ll_sof_n;
p_out_txll_eof_n <= i_ll_eof_n;
p_out_txll_src_rdy_n <= ((i_ll_sof_n and i_ll_src_rdy_n) or p_in_txbuf_empty) and not i_ll_dlast;
p_out_txll_rem <= i_ll_rem;




--                    sr_txbuf_dout((8 * 16) - 1 downto 8 * 15) <= p_in_txbuf_dout((8 * 16) - 1 downto 8 * 15);
--                    sr_txbuf_dout((8 * 15) - 1 downto 8 * 14) <= p_in_txbuf_dout((8 * 15) - 1 downto 8 * 14);
--                    sr_txbuf_dout((8 * 14) - 1 downto 8 * 13) <= p_in_txbuf_dout((8 * 14) - 1 downto 8 * 13);
--                    sr_txbuf_dout((8 * 13) - 1 downto 8 * 12) <= p_in_txbuf_dout((8 * 13) - 1 downto 8 * 12);
--                    sr_txbuf_dout((8 * 12) - 1 downto 8 * 11) <= p_in_txbuf_dout((8 * 12) - 1 downto 8 * 11);
--                    sr_txbuf_dout((8 * 11) - 1 downto 8 * 10) <= p_in_txbuf_dout((8 * 11) - 1 downto 8 * 10);
--                    sr_txbuf_dout((8 * 10) - 1 downto 8 * 9)  <= p_in_txbuf_dout((8 * 10) - 1 downto 8 * 9) ;
--                    sr_txbuf_dout((8 * 9) - 1  downto 8 * 8)  <= p_in_txbuf_dout((8 * 9) - 1  downto 8 * 8) ;
--                    sr_txbuf_dout((8 * 8) - 1 downto 8 * 7) <= p_in_txbuf_dout((8 * 8) - 1 downto 8 * 7);
--                    sr_txbuf_dout((8 * 7) - 1 downto 8 * 6) <= p_in_txbuf_dout((8 * 7) - 1 downto 8 * 6);
--                    sr_txbuf_dout((8 * 6) - 1 downto 8 * 5) <= p_in_txbuf_dout((8 * 6) - 1 downto 8 * 5);
--                    sr_txbuf_dout((8 * 5) - 1 downto 8 * 4) <= p_in_txbuf_dout((8 * 5) - 1 downto 8 * 4);
--                    sr_txbuf_dout((8 * 4) - 1 downto 8 * 3) <= p_in_txbuf_dout((8 * 4) - 1 downto 8 * 3);
--                    sr_txbuf_dout((8 * 3) - 1 downto 8 * 2) <= p_in_txbuf_dout((8 * 3) - 1 downto 8 * 2);
--                    sr_txbuf_dout((8 * 2) - 1 downto 8 * 1) <= p_in_txbuf_dout((8 * 2) - 1 downto 8 * 1);
--                    sr_txbuf_dout((8 * 1) - 1 downto 8 * 0) <= p_in_txbuf_dout((8 * 1) - 1 downto 8 * 0);

--END MAIN
end behavioral;
