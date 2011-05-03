-------------------------------------------------------------------------
-- Company     : Linkos
-- Engineer    : Golovachenko Victor
--
-- Create Date : 01.05.2011 16:43:52
-- Module Name : eth_tx
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
use work.prj_def.all;
use work.eth_pkg.all;

library unisim;
use unisim.vcomponents.all;

entity eth_tx is
generic(
G_WR_REM_WIDTH : integer := 4; -- Remainder width of read data
G_WR_DWIDTH    : integer := 32 -- FIFO read data width,
);
port
(
--//------------------------------------
--//Управление
--//------------------------------------
p_in_usr_ctrl          : in    std_logic_vector(15 downto 0);
p_in_usr_pattern_param : in    std_logic_vector(15 downto 0);
p_in_usr_pattern       : in    TEthUsrPattern;

--//------------------------------------
--//Связь с пользовательским TXBUF
--//------------------------------------
p_in_usr_txdata             : in    std_logic_vector(G_WR_DWIDTH-1 downto 0);
p_out_usr_txdata_rd         : out   std_logic;
p_in_usr_txdata_rdy         : in    std_logic;
p_in_usr_txbuf_empty        : in    std_logic;--//Должен быть соединен с портом user_TXBUF/empty_almost
p_in_usr_txbuf_empty_almost : in    std_logic;


--//------------------------------------
--//Связь с Local link TxFIFO
--//------------------------------------
p_out_tx_ll_data       : out   std_logic_vector(7 downto 0);
p_out_tx_ll_sof_n      : out   std_logic;
p_out_tx_ll_eof_n      : out   std_logic;
p_out_tx_ll_src_rdy_n  : out   std_logic;
p_in_tx_ll_dst_rdy_n   : in    std_logic;


--//------------------------------------
--//SYSTEM
--//------------------------------------
p_in_clk               : in    std_logic;
p_in_rst               : in    std_logic
);
end eth_tx;

architecture behavioral of eth_tx is

type TEth_fsm_tx is
(
S_IDLE,
S_TX_MACA_0,
S_TX_MACA_1,
S_TX_MACD,
S_TX_DONE
);
signal fsm_eth_tx_cs: TEth_fsm_tx;

signal i_bcnt                 : std_logic_vector(1 downto 0);
signal i_dcnt                 : std_logic_vector(15 downto 0);
signal i_pkt_len              : std_logic_vector(15 downto 0);--//кол-во передоваемых байт

signal i_usr_txd_rd           : std_logic;--//строб дополнительного чтения
signal i_usr_txd_rden         : std_logic;--//разрешение чтения данных из usr_txbuf

signal i_ll_data              : std_logic_vector(7 downto 0);
signal i_ll_sof_n             : std_logic;
signal i_ll_eof_n             : std_logic;
signal i_ll_src_rdy_n         : std_logic;


--MAIN
begin


--//-------------------------------------------
--//Автомат загрузки данных в ядро ETH
--//-------------------------------------------
process(p_in_rst,p_in_clk)
begin
  if p_in_rst='1' then
    fsm_eth_tx_cs<=S_IDLE;

    i_ll_data<=(others=>'0');
    i_ll_sof_n<='1';
    i_ll_eof_n<='1';
    i_ll_src_rdy_n<='1';

    i_usr_txd_rd<='0';
    i_usr_txd_rden<='0';
    i_pkt_len<=(others=>'0');
    i_dcnt<=(others=>'0');
    i_bcnt<=(others=>'0');

  elsif p_in_clk'event and p_in_clk='1' then

    if p_in_tx_ll_dst_rdy_n='0' then

      case fsm_eth_tx_cs is

        --//------------------------------------
        --//Ждем входных данных
        --//------------------------------------
        when S_IDLE =>

          i_ll_sof_n<='1';
          i_ll_eof_n<='1';
          i_ll_src_rdy_n<='1';

          if p_in_usr_txbuf_empty='0' then
            --//кол-во передоваемых байт данных
            i_pkt_len<=p_in_usr_txdata(15 downto 0);

            fsm_eth_tx_cs<=S_TX_MACA_0;
          end if;


        --//------------------------------------
        --//MACFRAME: отправка mac_dst/mac_src
        --//------------------------------------
        when S_TX_MACA_0 =>

          i_ll_data<=p_in_usr_pattern(0);
          i_ll_sof_n<='0';
          i_ll_src_rdy_n<='0';
          i_ll_eof_n<='1';

          i_dcnt<=i_dcnt + 1;

          fsm_eth_tx_cs<=S_TX_MACA_1;

        when S_TX_MACA_1 =>

          for i in 1 to 11 loop
            if i_dcnt(3 downto 0)=i then
              i_ll_data<=p_in_usr_pattern(i);
            end if;
          end loop;

          i_ll_src_rdy_n<='0';
          i_ll_sof_n<='1';
          i_ll_eof_n<='1';

          if i_dcnt=CONV_STD_LOGIC_VECTOR(11, i_dcnt'length) then
            i_dcnt<=(others=>'0');
            i_usr_txd_rden<='1';
            fsm_eth_tx_cs<=S_TX_MACD;
          else
            i_dcnt<=i_dcnt + 1;
          end if;

        --//------------------------------------
        --//MACFRAME: отправка данных
        --//------------------------------------
        when S_TX_MACD =>

          i_usr_txd_rd<='0';

          i_ll_src_rdy_n<=p_in_usr_txbuf_empty;
          i_ll_sof_n<='1';

          if p_in_usr_txbuf_empty='0' then

              if i_dcnt=i_pkt_len+1 then
                i_dcnt<=(others=>'0');
                i_ll_eof_n<='0';

                if AND_reduce(i_bcnt)='0' then
                  i_usr_txd_rd<='1';
                end if;

                fsm_eth_tx_cs<=S_TX_DONE;
              else
                i_dcnt<=i_dcnt + 1;--//счетчик байт передоваемых данных
                i_ll_eof_n<='1';
              end if;

              for i in 0 to 3 loop
                if i_bcnt=i then
                  i_ll_data<=p_in_usr_txdata((8*(i+1))-1 downto 8*i);
                end if;
              end loop;

              i_bcnt<=i_bcnt + 1;--//счетчик байт порта входных данных p_in_usr_txdata

          end if;--//if p_in_usr_txbuf_empty='0' then

        when S_TX_DONE =>

          i_bcnt<=(others=>'0');
          i_dcnt<=(others=>'0');

          i_ll_sof_n<='1';
          i_ll_eof_n<='1';
          i_ll_src_rdy_n<='1';

          i_usr_txd_rd<='0';
          i_usr_txd_rden<='0';

          fsm_eth_tx_cs<=S_IDLE;

      end case;

    end if;--//if p_in_tx_ll_dst_rdy_n='0'
  end if;
end process;

p_out_usr_txdata_rd<=not p_in_usr_txbuf_empty and i_usr_txd_rden and (i_usr_txd_rd or AND_reduce(i_bcnt)) and not p_in_tx_ll_dst_rdy_n;

p_out_tx_ll_data<=i_ll_data;
p_out_tx_ll_sof_n<=i_ll_sof_n;
p_out_tx_ll_eof_n<=i_ll_eof_n;
p_out_tx_ll_src_rdy_n<=i_ll_src_rdy_n;


--END MAIN
end behavioral;
