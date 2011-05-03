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
-- Revision 1.00 - Прием MAC FRAME если пакет адресовн нашему устройсту (mac_dst=наш),
--                 если mac.lentype поле является длинной mac frame
--                 При приеме удаляем pad(пустые) байты, если таковые есть
--                 (Pading длеается передатчико в случае если отправляемый пакет меньше чем 46 byte)
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

entity eth_rx is
generic(
G_RD_REM_WIDTH : integer := 4; -- Remainder width of read data
G_RD_DWIDTH    : integer := 32 -- FIFO read data width,
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
--//Связь с пользовательским RXBUF
--//------------------------------------
p_out_usr_rxdata       : out   std_logic_vector(G_RD_DWIDTH-1 downto 0);
p_out_usr_rxdata_wr    : out   std_logic;
p_out_usr_rxdata_rdy   : out   std_logic;
p_out_usr_rxdata_sof   : out   std_logic;
p_in_usr_rxbuf_full    : in    std_logic;

--//------------------------------------
--//Связь с Local link RxFIFO
--//------------------------------------
p_in_rx_ll_data        : in    std_logic_vector(7 downto 0);
p_in_rx_ll_sof_n       : in    std_logic;
p_in_rx_ll_eof_n       : in    std_logic;
p_in_rx_ll_src_rdy_n   : in    std_logic;
p_out_rx_ll_dst_rdy_n  : out   std_logic;
p_in_rx_ll_fifo_status : in    std_logic_vector(3 downto 0);

--//------------------------------------
--//Управление передачей PAUSE Control Frame
--//(более подробно см. ug194.pdf/Flow Control Block/Flow Control Implementation Example)
--//------------------------------------
p_out_pause_req        : out   std_logic;
p_out_pause_val        : out   std_logic_vector(15 downto 0);

--//------------------------------------
--//Статистика принятого пакета
--//------------------------------------
p_in_rx_statistic      : in    std_logic_vector(27 downto 0);
p_in_rx_statistic_vld  : in    std_logic;

--//------------------------------------
--//SYSTEM
--//------------------------------------
p_in_clk               : in    std_logic;
p_in_rst               : in    std_logic
);
end eth_rx;

architecture behavioral of eth_rx is

type TEth_fsm_rx is
(
S_IDLE,
S_RX_MAC_DST,
S_RX_MAC_SRC,
S_RX_MAC_LENTYPE,
S_LENTYPE_CHECK,
S_RX_MAC_DATA_0,
S_RX_MAC_DATA
);
signal fsm_eth_rx_cs: TEth_fsm_rx;

signal sr_bcnt                : std_logic_vector(1 downto 0);
signal i_bcnt                 : std_logic_vector(1 downto 0); --//счетчик вайт в выходного порта p_out_usr_rxdata
signal i_dcnt                 : std_logic_vector(15 downto 0);--//счетчик входных данных

type TEthMacAdr is array (0 to 5) of std_logic_vector(7 downto 0);
type TEthMAC is record
dst     : TEthMacAdr;
src     : TEthMacAdr;
lentype : std_logic_vector(15 downto 0);
end record;

signal i_mac                  : TEthMAC;

signal i_usr_rxd              : std_logic_vector(31 downto 0);
signal i_usr_rxd_sof          : std_logic;
signal sr_usr_rxd_sof         : std_logic;
signal i_usr_rxd_eof          : std_logic;

signal i_ll_dst_rdy_n         : std_logic;
signal sr_rx_ll_src_rdy_n     : std_logic;



--MAIN
begin


--//-------------------------------------------
--//Автомат приема данных из ядра ETH
--//-------------------------------------------
process(p_in_rst,p_in_clk)
begin
  if p_in_rst='1' then

    fsm_eth_rx_cs<=S_IDLE;

    for i in 0 to 5 loop
    i_mac.dst(i)<=(others=>'0');
    i_mac.src(i)<=(others=>'0');
    end loop;
    i_mac.lentype<=(others=>'0');

    i_ll_dst_rdy_n<='0';

    i_usr_rxd<=(others=>'0');
    i_usr_rxd_sof<='0';
    i_usr_rxd_eof<='0';
    sr_usr_rxd_sof<='0';

    i_dcnt<=(others=>'0');
    i_bcnt<=(others=>'0');

  elsif p_in_clk'event and p_in_clk='1' then

    if p_in_usr_rxbuf_full='0' and p_in_rx_ll_src_rdy_n='0' then

      sr_usr_rxd_sof<=i_usr_rxd_sof;

      case fsm_eth_rx_cs is

        --//------------------------------------
        --//Ждем входных данных
        --//------------------------------------
        when S_IDLE =>

          i_ll_dst_rdy_n<='0';
          i_usr_rxd_sof<='0';
          i_usr_rxd_eof<='0';
          i_bcnt<=(others=>'0');

          if p_in_rx_ll_sof_n='0' then

            i_mac.dst(0)<=p_in_rx_ll_data(7 downto 0);
            i_dcnt<=i_dcnt + 1;
            fsm_eth_rx_cs<=S_RX_MAC_DST;
          end if;


        --//------------------------------------
        --//MACFRAME: прием mac_dst
        --//------------------------------------
        when S_RX_MAC_DST =>

          if i_dcnt=CONV_STD_LOGIC_VECTOR(TEthMacAdr'high, i_dcnt'length) then
            i_dcnt<=(others=>'0');
            fsm_eth_rx_cs<=S_RX_MAC_SRC;
          else
            i_dcnt<=i_dcnt + 1;
          end if;

          for i in 1 to TEthMacAdr'high loop
            if i_dcnt(2 downto 0)=i then
              i_mac.dst(i)<=p_in_rx_ll_data(7 downto 0);
            end if;
          end loop;

        --//------------------------------------
        --//MACFRAME: прием mac_src
        --//------------------------------------
        when S_RX_MAC_SRC =>

          if i_dcnt=CONV_STD_LOGIC_VECTOR(TEthMacAdr'high, i_dcnt'length) then
            i_dcnt<=(others=>'0');
            fsm_eth_rx_cs<=S_RX_MAC_LENTYPE;
          else
            i_dcnt<=i_dcnt + 1;
          end if;

          for i in 0 to TEthMacAdr'high loop
            if i_dcnt(2 downto 0)=i then
              i_mac.src(i)<=p_in_rx_ll_data(7 downto 0);
            end if;
          end loop;

        --//------------------------------------
        --//MACFRAME: прием mac_len/type
        --//------------------------------------
        when S_RX_MAC_LENTYPE =>

          if i_dcnt=CONV_STD_LOGIC_VECTOR((i_mac.lentype'length/8)-1, i_dcnt'length) then
            i_dcnt<=(others=>'0');
            i_ll_dst_rdy_n<='1';
            fsm_eth_rx_cs<=S_LENTYPE_CHECK;
          else
            i_dcnt<=i_dcnt + 1;
          end if;

          for i in 0 to (i_mac.lentype'length/8)-1 loop
            if i_dcnt(1 downto 0)=i then
              i_mac.lentype(8*(i+1)-1 downto 8*i)<=p_in_rx_ll_data(7 downto 0);
            end if;
          end loop;



        --//------------------------------------
        --//MACFRAME: проверка
        --//------------------------------------
        when S_LENTYPE_CHECK =>

          if i_mac.lentype<CONV_STD_LOGIC_VECTOR(16#0800#, i_mac.lentype'length) then
          --//i_mac.lentype - является длинной mac frame:

            --//Проверяем кому адрисован MAC_FRAME:
            if i_mac.dst(0)=p_in_usr_pattern(C_USR_PATTERN_MAC_SRC_LSB_BIT + 0) and
               i_mac.dst(1)=p_in_usr_pattern(C_USR_PATTERN_MAC_SRC_LSB_BIT + 1) and
               i_mac.dst(2)=p_in_usr_pattern(C_USR_PATTERN_MAC_SRC_LSB_BIT + 2) and
               i_mac.dst(3)=p_in_usr_pattern(C_USR_PATTERN_MAC_SRC_LSB_BIT + 3) and
               i_mac.dst(4)=p_in_usr_pattern(C_USR_PATTERN_MAC_SRC_LSB_BIT + 4) and
               i_mac.dst(5)=p_in_usr_pattern(C_USR_PATTERN_MAC_SRC_LSB_BIT + 5) then

            --//MAC_FRAME - наш:
              fsm_eth_rx_cs<=S_RX_MAC_DATA_0;
            else
            --//MAC_FRAME - НЕ наш:
              i_ll_dst_rdy_n<='0';
              fsm_eth_rx_cs<=S_IDLE;
            end if;

          else
          --//i_mac.lentype - является типом одного из стандартных mac frame:

            i_ll_dst_rdy_n<='0';
            fsm_eth_rx_cs<=S_IDLE;

          end if;


        --//------------------------------------
        --//MACFRAME: запись данных mac frame в usr_rxbuf
        --//------------------------------------
        --//Запись pkt_len
        when S_RX_MAC_DATA_0 =>

          if p_in_usr_rxbuf_full='0' then

              for i in 0 to 1 loop
                if i_bcnt=i then
                  i_usr_rxd((8*(i+1))-1 downto 8*i)<=i_mac.lentype((8*(i+1))-1 downto 8*i);
                end if;
              end loop;

              i_dcnt<=i_dcnt + 1;--//счетчик байт передоваемых данных
              i_bcnt<=i_bcnt + 1;--//счетчик байт порта входных данных p_in_usr_txdata

              if i_dcnt=CONV_STD_LOGIC_VECTOR((i_mac.lentype'length/8)-1, i_dcnt'length) then
                i_ll_dst_rdy_n<='0';
                fsm_eth_rx_cs<=S_RX_MAC_DATA;
              end if;

          end if;--//if p_in_usr_rxbuf_full='0' then

        --//Запись pkt_data
        when S_RX_MAC_DATA =>

          if p_in_usr_rxbuf_full='0' then

              if i_dcnt=i_mac.lentype+1 then
                i_dcnt<=(others=>'0');

--                if AND_reduce(i_bcnt)='0' then
                  i_usr_rxd_eof<='1';
--                end if;

                fsm_eth_rx_cs<=S_IDLE;

              else
                i_dcnt<=i_dcnt + 1;--//счетчик байт mac frame
              end if;

              if AND_reduce(i_bcnt)='1' then
                i_usr_rxd_sof<='1';
              end if;

              for i in 0 to 3 loop
                if i_bcnt=i then
                  i_usr_rxd((8*(i+1))-1 downto 8*i)<=p_in_rx_ll_data(7 downto 0);
                end if;
              end loop;

              i_bcnt<=i_bcnt + 1;--//счетчик байт порта выходных данных p_out_usr_rxdata

          end if;--//if p_in_usr_rxbuf_full='0' then

      end case;

    end if;--//if p_in_usr_rxbuf_full='0' and p_in_rx_ll_src_rdy_n='0' then
  end if;
end process;


--//Линия задержек
process(p_in_rst,p_in_clk)
begin
  if p_in_rst='1' then
    sr_bcnt<=(others=>'0');
    sr_rx_ll_src_rdy_n<='1';

  elsif p_in_clk'event and p_in_clk='1' then
    sr_rx_ll_src_rdy_n<=p_in_rx_ll_src_rdy_n;
    sr_bcnt<=i_bcnt;

  end if;
end process;

p_out_usr_rxdata<=i_usr_rxd;
p_out_usr_rxdata_wr <=not p_in_usr_rxbuf_full and not sr_rx_ll_src_rdy_n and (i_usr_rxd_eof or AND_reduce(sr_bcnt)) and not i_ll_dst_rdy_n;
p_out_usr_rxdata_rdy<=not p_in_usr_rxbuf_full and not sr_rx_ll_src_rdy_n and  i_usr_rxd_eof;
p_out_usr_rxdata_sof<=not p_in_usr_rxbuf_full and not sr_rx_ll_src_rdy_n and (not sr_usr_rxd_sof and i_usr_rxd_sof);

p_out_rx_ll_dst_rdy_n<=i_ll_dst_rdy_n;




--//------------------------------------
--//Управление передачей Pause Frame
--//------------------------------------
p_out_pause_req<='0';
p_out_pause_val<=(others=>'0');



--END MAIN
end behavioral;

