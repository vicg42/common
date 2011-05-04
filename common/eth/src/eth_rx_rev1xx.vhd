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

library unisim;
use unisim.vcomponents.all;

library work;
use work.vicg_common_pkg.all;
--use work.prj_def.all;
use work.eth_pkg.all;

entity eth_rx is
generic(
G_DBG : string:="OFF";
G_SIM : string:="OFF"
);
port
(
--//------------------------------------
--//Управление
--//------------------------------------
p_in_cfg              : in    TEthCfg;

--//------------------------------------
--//Связь с пользовательским RXBUF
--//------------------------------------
p_out_rxbuf_din       : out   std_logic_vector(C_ETH_USRBUF_DWIDTH-1 downto 0);
p_out_rxbuf_wr        : out   std_logic;
p_in_rxbuf_full       : in    std_logic;
p_out_rxd_sof         : out   std_logic;
p_out_rxd_eof         : out   std_logic;

--//------------------------------------
--//Связь с Local link RxFIFO
--//------------------------------------
p_in_rxll_data        : in    std_logic_vector(7 downto 0);
p_in_rxll_sof_n       : in    std_logic;
p_in_rxll_eof_n       : in    std_logic;
p_in_rxll_src_rdy_n   : in    std_logic;
p_out_rxll_dst_rdy_n  : out   std_logic;
p_in_rxll_fifo_status : in    std_logic_vector(3 downto 0);

--//------------------------------------
--//Управление передачей PAUSE Control Frame
--//(более подробно см. ug194.pdf/Flow Control Block/Flow Control Implementation Example)
--//------------------------------------
p_out_pause_req       : out   std_logic;
p_out_pause_val       : out   std_logic_vector(15 downto 0);

--------------------------------------------------
--Технологические сигналы
--------------------------------------------------
p_in_tst              : in    std_logic_vector(31 downto 0);
p_out_tst             : out   std_logic_vector(31 downto 0);

--//------------------------------------
--//SYSTEM
--//------------------------------------
p_in_clk              : in    std_logic;
p_in_rst              : in    std_logic
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

signal i_rx_mac               : TEthMAC;

signal i_usr_rxd              : std_logic_vector(31 downto 0);
signal i_usr_rxd_sof          : std_logic;
signal sr_usr_rxd_sof         : std_logic;
signal i_usr_rxd_eof          : std_logic;

signal i_ll_dst_rdy_n         : std_logic;
signal sr_rxll_src_rdy_n      : std_logic;


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

tst_fms_cs<=CONV_STD_LOGIC_VECTOR(16#01#, tst_fms_cs'length) when fsm_eth_rx_cs=S_RX_MAC_DST else
            CONV_STD_LOGIC_VECTOR(16#02#, tst_fms_cs'length) when fsm_eth_rx_cs=S_RX_MAC_SRC else
            CONV_STD_LOGIC_VECTOR(16#03#, tst_fms_cs'length) when fsm_eth_rx_cs=S_RX_MAC_LENTYPE else
            CONV_STD_LOGIC_VECTOR(16#04#, tst_fms_cs'length) when fsm_eth_rx_cs=S_LENTYPE_CHECK else
            CONV_STD_LOGIC_VECTOR(16#05#, tst_fms_cs'length) when fsm_eth_rx_cs=S_RX_MAC_DATA_0 else
            CONV_STD_LOGIC_VECTOR(16#06#, tst_fms_cs'length) when fsm_eth_rx_cs=S_RX_MAC_DATA else
            CONV_STD_LOGIC_VECTOR(16#00#, tst_fms_cs'length) ; --//when fsm_eth_rx_cs=S_IDLE else

end generate gen_dbg_on;



--//-------------------------------------------
--//Автомат приема данных из ядра ETH
--//-------------------------------------------
process(p_in_rst,p_in_clk)
begin
  if p_in_rst='1' then

    fsm_eth_rx_cs<=S_IDLE;

    for i in 0 to 5 loop
    i_rx_mac.dst(i)<=(others=>'0');
    i_rx_mac.src(i)<=(others=>'0');
    end loop;
    i_rx_mac.lentype<=(others=>'0');

    i_ll_dst_rdy_n<='0';

    i_usr_rxd<=(others=>'0');
    i_usr_rxd_sof<='0';
    i_usr_rxd_eof<='0';
    sr_usr_rxd_sof<='0';

    i_dcnt<=(others=>'0');
    i_bcnt<=(others=>'0');

  elsif p_in_clk'event and p_in_clk='1' then

    if p_in_rxbuf_full='0' and p_in_rxll_src_rdy_n='0' then

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

          if p_in_rxll_sof_n='0' then

            i_rx_mac.dst(0)<=p_in_rxll_data(7 downto 0);
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
              i_rx_mac.dst(i)<=p_in_rxll_data(7 downto 0);
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
              i_rx_mac.src(i)<=p_in_rxll_data(7 downto 0);
            end if;
          end loop;

        --//------------------------------------
        --//MACFRAME: прием mac_len/type
        --//------------------------------------
        when S_RX_MAC_LENTYPE =>

          if i_dcnt=CONV_STD_LOGIC_VECTOR((i_rx_mac.lentype'length/8)-1, i_dcnt'length) then
            i_dcnt<=(others=>'0');
            i_ll_dst_rdy_n<='1';
            fsm_eth_rx_cs<=S_LENTYPE_CHECK;
          else
            i_dcnt<=i_dcnt + 1;
          end if;

          for i in 0 to (i_rx_mac.lentype'length/8)-1 loop
            if i_dcnt(1 downto 0)=i then
              i_rx_mac.lentype(8*(i+1)-1 downto 8*i)<=p_in_rxll_data(7 downto 0);
            end if;
          end loop;



        --//------------------------------------
        --//MACFRAME: проверка
        --//------------------------------------
        when S_LENTYPE_CHECK =>

          if i_rx_mac.lentype<CONV_STD_LOGIC_VECTOR(16#0800#, i_rx_mac.lentype'length) then
          --//i_rx_mac.lentype - является длинной mac frame:

            --//Проверяем кому адрисован MAC_FRAME:
            if i_rx_mac.dst(0)=p_in_cfg.mac.src(0) and
               i_rx_mac.dst(1)=p_in_cfg.mac.src(1) and
               i_rx_mac.dst(2)=p_in_cfg.mac.src(2) and
               i_rx_mac.dst(3)=p_in_cfg.mac.src(3) and
               i_rx_mac.dst(4)=p_in_cfg.mac.src(4) and
               i_rx_mac.dst(5)=p_in_cfg.mac.src(5) then

            --//MAC_FRAME - наш:
              fsm_eth_rx_cs<=S_RX_MAC_DATA_0;
            else
            --//MAC_FRAME - НЕ наш:
              i_ll_dst_rdy_n<='0';
              fsm_eth_rx_cs<=S_IDLE;
            end if;

          else
          --//i_rx_mac.lentype - является типом одного из стандартных mac frame:

            i_ll_dst_rdy_n<='0';
            fsm_eth_rx_cs<=S_IDLE;

          end if;


        --//------------------------------------
        --//MACFRAME: запись данных mac frame в usr_rxbuf
        --//------------------------------------
        --//Запись pkt_len
        when S_RX_MAC_DATA_0 =>

          if p_in_rxbuf_full='0' then

              for i in 0 to 1 loop
                if i_bcnt=i then
                  i_usr_rxd((8*(i+1))-1 downto 8*i)<=i_rx_mac.lentype((8*(i+1))-1 downto 8*i);
                end if;
              end loop;

              i_dcnt<=i_dcnt + 1;--//счетчик байт передоваемых данных
              i_bcnt<=i_bcnt + 1;--//счетчик байт порта входных данных p_in_usr_txdata

              if i_dcnt=CONV_STD_LOGIC_VECTOR((i_rx_mac.lentype'length/8)-1, i_dcnt'length) then
                i_ll_dst_rdy_n<='0';
                fsm_eth_rx_cs<=S_RX_MAC_DATA;
              end if;

          end if;--//if p_in_rxbuf_full='0' then

        --//Запись pkt_data
        when S_RX_MAC_DATA =>

          if p_in_rxbuf_full='0' then

              if i_dcnt=i_rx_mac.lentype+1 then
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
                  i_usr_rxd((8*(i+1))-1 downto 8*i)<=p_in_rxll_data(7 downto 0);
                end if;
              end loop;

              i_bcnt<=i_bcnt + 1;--//счетчик байт порта выходных данных p_out_usr_rxdata

          end if;--//if p_in_rxbuf_full='0' then

      end case;

    end if;--//if p_in_rxbuf_full='0' and p_in_rxll_src_rdy_n='0' then
  end if;
end process;


--//Линия задержек
process(p_in_rst,p_in_clk)
begin
  if p_in_rst='1' then
    sr_bcnt<=(others=>'0');
    sr_rxll_src_rdy_n<='1';

  elsif p_in_clk'event and p_in_clk='1' then
    sr_rxll_src_rdy_n<=p_in_rxll_src_rdy_n;
    sr_bcnt<=i_bcnt;

  end if;
end process;

p_out_rxbuf_din<=i_usr_rxd;
p_out_rxbuf_wr<=not p_in_rxbuf_full and not sr_rxll_src_rdy_n and (i_usr_rxd_eof or AND_reduce(sr_bcnt)) and not i_ll_dst_rdy_n;
p_out_rxd_sof <=not p_in_rxbuf_full and not sr_rxll_src_rdy_n and (not sr_usr_rxd_sof and i_usr_rxd_sof);
p_out_rxd_eof <=not p_in_rxbuf_full and not sr_rxll_src_rdy_n and  i_usr_rxd_eof;


p_out_rxll_dst_rdy_n<=i_ll_dst_rdy_n;




--//------------------------------------
--//Управление передачей Pause Frame
--//------------------------------------
p_out_pause_req<='0';
p_out_pause_val<=(others=>'0');



--END MAIN
end behavioral;

