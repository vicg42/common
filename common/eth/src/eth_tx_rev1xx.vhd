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

library unisim;
use unisim.vcomponents.all;

library work;
use work.vicg_common_pkg.all;
--use work.prj_def.all;
use work.eth_pkg.all;

entity eth_tx is
generic(
G_DBG : string:="OFF";
G_SIM : string:="OFF"
);
port
(
--//------------------------------------
--//Управление
--//------------------------------------
p_in_cfg             : in    TEthCfg;

--//------------------------------------
--//Связь с пользовательским TXBUF
--//------------------------------------
p_in_txbuf_dout      : in    std_logic_vector(C_ETH_USRBUF_DWIDTH-1 downto 0);
p_out_txbuf_rd       : out   std_logic;
p_in_txbuf_empty     : in    std_logic;
--p_in_txd_rdy         : in    std_logic;

--//------------------------------------
--//Связь с Local link TxFIFO
--//------------------------------------
p_out_txll_data      : out   std_logic_vector(7 downto 0);
p_out_txll_sof_n     : out   std_logic;
p_out_txll_eof_n     : out   std_logic;
p_out_txll_src_rdy_n : out   std_logic;
p_in_txll_dst_rdy_n  : in    std_logic;

--------------------------------------------------
--Технологические сигналы
--------------------------------------------------
p_in_tst             : in    std_logic_vector(31 downto 0);
p_out_tst            : out   std_logic_vector(31 downto 0);

--//------------------------------------
--//SYSTEM
--//------------------------------------
p_in_clk             : in    std_logic;
p_in_rst             : in    std_logic
);
end eth_tx;

architecture behavioral of eth_tx is

type TEth_fsm_tx is
(
S_IDLE,
S_TX_MACA_DST0,
S_TX_MACA_DST1,
S_TX_MACA_SRC,
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
    p_out_tst(0)<=OR_reduce(tst_fms_cs_dly) or p_in_txbuf_empty;
  end if;
end process ltstout;

tst_fms_cs<=CONV_STD_LOGIC_VECTOR(16#01#, tst_fms_cs'length) when fsm_eth_tx_cs=S_TX_MACA_DST0 else
            CONV_STD_LOGIC_VECTOR(16#02#, tst_fms_cs'length) when fsm_eth_tx_cs=S_TX_MACA_DST1 else
            CONV_STD_LOGIC_VECTOR(16#03#, tst_fms_cs'length) when fsm_eth_tx_cs=S_TX_MACA_SRC  else
            CONV_STD_LOGIC_VECTOR(16#04#, tst_fms_cs'length) when fsm_eth_tx_cs=S_TX_MACD      else
            CONV_STD_LOGIC_VECTOR(16#05#, tst_fms_cs'length) when fsm_eth_tx_cs=S_TX_DONE      else
            CONV_STD_LOGIC_VECTOR(16#00#, tst_fms_cs'length);-- when fsm_eth_tx_cs=S_IDLE         else

end generate gen_dbg_on;


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

    if p_in_txll_dst_rdy_n='0' then

      case fsm_eth_tx_cs is

        --//------------------------------------
        --//Ждем входных данных
        --//------------------------------------
        when S_IDLE =>

          i_ll_sof_n<='1';
          i_ll_eof_n<='1';
          i_ll_src_rdy_n<='1';

          if p_in_txbuf_empty='0' then
            --//кол-во передоваемых байт данных
            i_pkt_len<=p_in_txbuf_dout(15 downto 0);

            fsm_eth_tx_cs<=S_TX_MACA_DST0;
          end if;


        --//------------------------------------
        --//MACFRAME: отправка mac_dst
        --//------------------------------------
        when S_TX_MACA_DST0 =>

          i_ll_data<=p_in_cfg.mac.dst(0);
          i_ll_src_rdy_n<='0';
          i_ll_sof_n<='0';
          i_ll_eof_n<='1';

          i_dcnt<=i_dcnt + 1;

          fsm_eth_tx_cs<=S_TX_MACA_DST1;

        when S_TX_MACA_DST1 =>

          for i in 1 to p_in_cfg.mac.dst'high loop
            if i_dcnt(3 downto 0)=i then
              i_ll_data<=p_in_cfg.mac.dst(i);
            end if;
          end loop;

          i_ll_src_rdy_n<='0';
          i_ll_sof_n<='1';
          i_ll_eof_n<='1';

          if i_dcnt=CONV_STD_LOGIC_VECTOR(p_in_cfg.mac.dst'high, i_dcnt'length) then
            i_dcnt<=(others=>'0');
            fsm_eth_tx_cs<=S_TX_MACA_SRC;
          else
            i_dcnt<=i_dcnt + 1;
          end if;

        --//------------------------------------
        --//MACFRAME: отправка mac_src
        --//------------------------------------
        when S_TX_MACA_SRC =>

          for i in 0 to p_in_cfg.mac.src'high loop
            if i_dcnt(3 downto 0)=i then
              i_ll_data<=p_in_cfg.mac.src(i);
            end if;
          end loop;

          i_ll_src_rdy_n<='0';
          i_ll_sof_n<='1';
          i_ll_eof_n<='1';

          if i_dcnt=CONV_STD_LOGIC_VECTOR(p_in_cfg.mac.src'high, i_dcnt'length) then
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

          i_ll_src_rdy_n<=p_in_txbuf_empty;
          i_ll_sof_n<='1';

          if p_in_txbuf_empty='0' then

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
                  i_ll_data<=p_in_txbuf_dout((8*(i+1))-1 downto 8*i);
                end if;
              end loop;

              i_bcnt<=i_bcnt + 1;--//счетчик байт порта входных данных p_in_txbuf_dout

          end if;--//if p_in_txbuf_empty='0' then

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

    end if;--//if p_in_txll_dst_rdy_n='0'
  end if;
end process;

p_out_txbuf_rd<=not p_in_txbuf_empty and i_usr_txd_rden and (i_usr_txd_rd or AND_reduce(i_bcnt)) and not p_in_txll_dst_rdy_n;

p_out_txll_data<=i_ll_data;
p_out_txll_sof_n<=i_ll_sof_n;
p_out_txll_eof_n<=i_ll_eof_n;
p_out_txll_src_rdy_n<=i_ll_src_rdy_n;


--END MAIN
end behavioral;
