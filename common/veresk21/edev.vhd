-------------------------------------------------------------------------
-- Company     : Linkos
-- Engineer    : Golovachenko Victor
--
-- Create Date : 17.11.2012 13:43:05
-- Module Name : edev
--
--Обмен - запрос/ответ
--             ----------------------------
--             [31:24] [23:16] [15:8] [7:0]
--             ----------------------------
--HOST -> FPGA: BYTE2  BYTE1  BYTE0   DLEN(ByteCount)
--              BYTEN  ...    ...     ...
--
--HOST <- FPGA(irq + data):
--              BYTE2  BYTE1  BYTE0   DLEN(ByteCount)
--              BYTEN  ...    ...     ...
--
--Если HOST долго не получал прерывания(не было ответа на его запрос), то
--он имеет право делать следующий запрос
--
--Если модуль m_core ошибки:
--HOST <- FPGA(irq + err_bit + rxbuf reset)
-------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_misc.all;
use ieee.std_logic_unsigned.all;

library work;
use work.vicg_common_pkg.all;

entity edev is
generic(
G_DBG : string:="OFF";
G_SIM : string:="OFF"
);
port(
p_in_tmr_en       : in   std_logic;
p_in_tmr_stb      : in   std_logic;

-------------------------------
--Связь с HOST
-------------------------------
p_out_host_rxrdy  : out  std_logic;                      --//1 - rdy to used
p_out_host_rxd    : out  std_logic_vector(31 downto 0);  --//cfgdev -> host
p_in_host_rd      : in   std_logic;                      --//

p_out_host_txrdy  : out  std_logic;                      --//1 - rdy to used
p_in_host_txd     : in   std_logic_vector(31 downto 0);  --//cfgdev <- host
p_in_host_wr      : in   std_logic;                      --//

p_in_host_clk     : in   std_logic;

p_out_hirq        : out  std_logic;                      --//прерывание
p_out_herr        : out  std_logic;

--------------------------------------
--PHY (half-duplex)
--------------------------------------
p_in_phy_rx       : in   std_logic;
p_out_phy_tx      : out  std_logic;
p_out_phy_dir     : out  std_logic;

------------------------------------
--Технологические сигналы
------------------------------------
p_in_tst          : in   std_logic_vector(31 downto 0);
p_out_tst         : out  std_logic_vector(31 downto 0);

--------------------------------------
--System
--------------------------------------
p_in_bitclk       : in   std_logic; -- 1/0  = bitclk 1MHz/ bitclk 250kHz
p_in_clk          : in   std_logic;
p_in_rst          : in   std_logic
);
end edev;

architecture behavioral of edev is

constant CI_STATUS_RX_OK     : integer:=16#01#;
constant CI_STATUS_RX_ERR    : integer:=16#02#;

component master485n
port(
p_in_phy_rx   : in  std_logic;
p_out_phy_tx  : out std_logic;
p_out_phy_dir : out std_logic;

p_in_txd_rdy  : in  std_logic;
p_in_txd      : in  std_logic_vector(7 downto 0);
p_out_txd_rd  : out std_logic;

p_out_rxd     : out std_logic_vector(7 downto 0);
p_out_rxd_wr  : out std_logic;

p_out_status  : out std_logic_vector(2 downto 0);

p_in_tst      : in  std_logic_vector(31 downto 0);
p_out_tst     : out std_logic_vector(31 downto 0);

p_in_bitclk   : in  std_logic;
p_in_clk      : in  std_logic;
p_in_rst      : in  std_logic
);
end component;

component edev_buf
port (
din    : in  std_logic_vector(31 downto 0);
wr_en  : in  std_logic;
wr_clk : in  std_logic;

dout   : out std_logic_vector(31 downto 0);
rd_en  : in  std_logic;
rd_clk : in  std_logic;

full   : out std_logic;
empty  : out std_logic;

rst    : in  std_logic
);
end component;


type TFsmEdev is (
S_TX_IDLE     ,
S_TX_D_WAIT   ,
S_TX_D        ,
S_TX_DONE     ,
S_RX_D        ,
S_RX_DONE
);
signal i_fsm_edev_cs     : TFsmEdev;

signal i_lencnt          : std_logic_vector(7 downto 0);--Tx/Rx byte count
signal i_bcnt            : std_logic_vector(1 downto 0);--byte counter for Host Buffer data bus

--Host BUFs
signal i_host_rxd_en     : std_logic;
signal i_host_rxd        : std_logic_vector(31 downto 0);
signal i_txbuf_do        : std_logic_vector(31 downto 0);
signal i_txbuf_rd        : std_logic;
signal i_txbuf_empty     : std_logic;
signal i_rxbuf_wr        : std_logic;
signal i_rxbuf_di        : std_logic_vector(31 downto 0);
signal i_rxbuf_empty     : std_logic;
signal i_rxbuf_rst       : std_logic;

signal i_core_txd_rdy    : std_logic;
signal i_core_txd        : std_logic_vector(7 downto 0);
signal i_core_tx_rd      : std_logic;
signal i_core_rxd        : std_logic_vector(7 downto 0);
signal i_core_rx_wr      : std_logic;
signal i_core_status     : std_logic_vector(2 downto 0);

signal i_rcv_err         : std_logic;
signal i_rcv_irq         : std_logic;

signal i_tmr_en          : std_logic;
signal sr_tx_start       : std_logic_vector(0 to 2);

signal tst_out           : std_logic_vector(31 downto 0);
signal tst_fsm_edev,tst_fsm_edev_dly: std_logic_vector(3 downto 0);
signal tst_fms_core,tst_fms_core_dly: std_logic_vector(3 downto 0);
signal tst_txbufh_empty : std_logic;
signal tst_rxbufh_empty : std_logic;
signal sr_rcv_irq       : std_logic_vector(0 to 0);
signal tst_rcv_irq      : std_logic;


--MAIN
begin

------------------------------------
--Технологические сигналы
------------------------------------
p_out_tst(0) <= OR_reduce(tst_fms_core_dly) or OR_reduce(tst_fsm_edev_dly) or
tst_rxbufh_empty or tst_txbufh_empty or tst_rcv_irq;

process(p_in_rst, p_in_clk)
begin
  if p_in_rst = '1' then
    tst_fsm_edev_dly <= (others=>'0');
    tst_fms_core_dly <= (others=>'0');
    tst_txbufh_empty <= '0';
    tst_rxbufh_empty <= '0';
    sr_rcv_irq <= (others=>'0');
    tst_rcv_irq <= '0';

  elsif rising_edge(p_in_clk) then
    tst_fsm_edev_dly <= tst_fsm_edev;
    tst_fms_core_dly <= tst_fms_core;
    tst_txbufh_empty <= i_txbuf_empty;
    tst_rxbufh_empty <= i_rxbuf_empty;

    sr_rcv_irq(0) <= i_rcv_irq;
    tst_rcv_irq <= i_rcv_irq and not sr_rcv_irq(0);

  end if;
end process;

tst_fsm_edev <= CONV_STD_LOGIC_VECTOR(16#01#, tst_fsm_edev'length) when i_fsm_edev_cs = S_TX_D     else
                CONV_STD_LOGIC_VECTOR(16#02#, tst_fsm_edev'length) when i_fsm_edev_cs = S_TX_DONE  else
                CONV_STD_LOGIC_VECTOR(16#03#, tst_fsm_edev'length) when i_fsm_edev_cs = S_RX_D     else
                CONV_STD_LOGIC_VECTOR(16#04#, tst_fsm_edev'length) when i_fsm_edev_cs = S_RX_DONE  else
                CONV_STD_LOGIC_VECTOR(16#05#, tst_fsm_edev'length) when i_fsm_edev_cs = S_TX_D_WAIT else
                CONV_STD_LOGIC_VECTOR(16#00#, tst_fsm_edev'length);-- when fsm_tx_cs = S_TX_IDLE else

tst_fms_core <= CONV_STD_LOGIC_VECTOR(16#01#, tst_fms_core'length) when tst_out(3 downto 0) = CONV_STD_LOGIC_VECTOR(1 , 4) else
                CONV_STD_LOGIC_VECTOR(16#02#, tst_fms_core'length) when tst_out(3 downto 0) = CONV_STD_LOGIC_VECTOR(2 , 4) else
                CONV_STD_LOGIC_VECTOR(16#03#, tst_fms_core'length) when tst_out(3 downto 0) = CONV_STD_LOGIC_VECTOR(3 , 4) else
                CONV_STD_LOGIC_VECTOR(16#04#, tst_fms_core'length) when tst_out(3 downto 0) = CONV_STD_LOGIC_VECTOR(4 , 4) else
                CONV_STD_LOGIC_VECTOR(16#05#, tst_fms_core'length) when tst_out(3 downto 0) = CONV_STD_LOGIC_VECTOR(5 , 4) else
                CONV_STD_LOGIC_VECTOR(16#06#, tst_fms_core'length) when tst_out(3 downto 0) = CONV_STD_LOGIC_VECTOR(6 , 4) else
                CONV_STD_LOGIC_VECTOR(16#07#, tst_fms_core'length) when tst_out(3 downto 0) = CONV_STD_LOGIC_VECTOR(7 , 4) else
                CONV_STD_LOGIC_VECTOR(16#08#, tst_fms_core'length) when tst_out(3 downto 0) = CONV_STD_LOGIC_VECTOR(8 , 4) else
                CONV_STD_LOGIC_VECTOR(16#09#, tst_fms_core'length) when tst_out(3 downto 0) = CONV_STD_LOGIC_VECTOR(9 , 4) else
                CONV_STD_LOGIC_VECTOR(16#00#, tst_fms_core'length);-- when i_fsm_state = CONV_STD_LOGIC_VECTOR(0 , i_fsm_state'length);

--//----------------------------------
--//Связь с Host
--//----------------------------------
p_out_host_txrdy <= i_txbuf_empty;
p_out_host_rxrdy <= not i_rxbuf_empty and i_rcv_irq;--ВАЖНО!!! Взводим флаг готовности RXD
                                                    --одновременно с выдачей прерывания
p_out_herr <= i_rcv_err;
p_out_hirq <= i_rcv_irq;
i_rcv_err <= '1' when i_core_status = CONV_STD_LOGIC_VECTOR(CI_STATUS_RX_ERR, i_core_status'length) else '0';

--host->edev
m_txbuf : edev_buf
port map(
din    => p_in_host_txd,
wr_en  => p_in_host_wr,
wr_clk => p_in_host_clk,

dout   => i_txbuf_do,
rd_en  => i_txbuf_rd,
rd_clk => p_in_clk,

full   => open,
empty  => i_txbuf_empty,

rst    => p_in_rst
);

--host<-edev
m_rxbuf : edev_buf
port map(
din    => i_rxbuf_di,
wr_en  => i_rxbuf_wr,
wr_clk => p_in_clk,

dout   => i_host_rxd,
rd_en  => p_in_host_rd,
rd_clk => p_in_host_clk,

full   => open,
empty  => i_rxbuf_empty,

rst    => i_rxbuf_rst
);

i_rxbuf_rst <= p_in_rst or i_rcv_err;

--Встраивание в выходные данные Rx byte count
p_out_host_rxd( 7 downto 0) <= i_host_rxd( 7 downto 0) when i_host_rxd_en = '1' else i_lencnt(7 downto 0);
p_out_host_rxd(31 downto 8) <= i_host_rxd(31 downto 8);

process(p_in_rst, p_in_host_clk)
begin
  if p_in_rst = '1' then
    i_host_rxd_en <= '0';

  elsif rising_edge(p_in_host_clk) then
    if p_in_host_wr = '1' then
      i_host_rxd_en <= '0';

    elsif p_in_host_rd = '1' then
      i_host_rxd_en <= '1';
    end if;
  end if;
end process;

--//----------------------------------
--//Управнение приемом/передачей
--//----------------------------------
process(p_in_rst, p_in_clk)
variable i_rxbuf_wr_last : std_logic;
begin
  if p_in_rst = '1' then
    i_fsm_edev_cs <= S_TX_IDLE;

    i_lencnt <= (others=>'0');
    i_bcnt <= (others=>'0');

    i_core_txd_rdy <= '0';
    i_core_txd <= (others=>'0');

    i_tmr_en <= '0';
    sr_tx_start <= (others=>'0');

    i_rxbuf_di <= (others=>'0');
    i_rxbuf_wr <= '0'; i_rxbuf_wr_last := '0';
    i_txbuf_rd <= '0';

    i_rcv_irq <= '0';

  elsif rising_edge(p_in_clk) then

      i_tmr_en <= p_in_tmr_en;
      sr_tx_start <= p_in_tmr_stb & sr_tx_start(0 to 1);

      i_rxbuf_wr_last := '0';

      case i_fsm_edev_cs is

          ------------------------------------
          --Tx Data
          ------------------------------------
          when S_TX_IDLE =>

              i_rxbuf_wr <= '0';

              if (i_tmr_en = '0' and i_txbuf_empty = '0') or
                 (i_tmr_en = '1' and sr_tx_start(1) = '1' and sr_tx_start(2) = '0') then
                --Отправка данных сразу как данные появились в TXBUF хоста или
                --по сигналу от внешнего таймера
                i_fsm_edev_cs <= S_TX_D_WAIT;
              end if;

          when S_TX_D_WAIT =>

              if i_txbuf_empty = '0' then
                  i_lencnt <= i_txbuf_do(7 downto 0);--Tx byte count
                  i_bcnt <= CONV_STD_LOGIC_VECTOR(1, i_bcnt'length);--индекс байта шины i_txbuf_do
                                                                    --с которого начинаются данные,
                                                                    --индекс 0 в первом DWORD - кол-во
                                                                    --данных в byte

                  i_rcv_irq <= '0';
                  i_fsm_edev_cs <= S_TX_D;
              end if;

          when S_TX_D =>

              for idx in 0 to i_txbuf_do'length / 8 - 1 loop
                if i_bcnt = idx then
                  i_core_txd <= i_txbuf_do(8 * (idx + 1) - 1 downto 8 * idx);
                end if;
              end loop;

              i_txbuf_rd <= (not i_txbuf_empty and i_core_tx_rd and
                            (AND_reduce(i_bcnt) or not OR_reduce(i_lencnt)) );

              if i_txbuf_empty = '0' then
                  if i_core_txd_rdy = '0' then
                      i_lencnt <= i_lencnt - 1;
                      i_core_txd_rdy <= '1';--Сигнализируем о готовности txdata
                  else
                      if i_core_tx_rd = '1' then
                          if i_lencnt = (i_lencnt'range => '0') then
                            i_core_txd_rdy <= '0';
                            i_fsm_edev_cs <= S_TX_DONE;
                          else
                            i_lencnt <= i_lencnt - 1;
                          end if;

                          i_bcnt <= i_bcnt + 1;
                      end if;
                  end if;
              end if;

          when S_TX_DONE =>

              i_txbuf_rd <= '0';
              if i_txbuf_empty = '1' then
                i_lencnt <= (others=>'0');
                i_bcnt <= CONV_STD_LOGIC_VECTOR(1, i_bcnt'length);--индекс байта шины i_rxbuf_di
                                                                  --с которого начинаются данные,
                                                                  --индекс 0 в первом DWORD - кол-во
                                                                  --данных в byte
                --i_rxbuf_di(7 downto 0) - зарезервировано для Rx byte count!!!
                i_fsm_edev_cs <= S_RX_D;
              end if;

          ------------------------------------
          --Rx Data
          ------------------------------------
          when S_RX_D =>

              if i_core_rx_wr = '1' then
                for idx in 0 to i_rxbuf_di'length / 8 - 1 loop
                  if i_bcnt = idx then
                    i_rxbuf_di(8 * (idx + 1) - 1 downto 8 * idx) <= i_core_rxd;
                  end if;
                end loop;

                i_bcnt <= i_bcnt + 1;
                i_lencnt <= i_lencnt + 1;--Rx byte count
              end if;

              if i_core_status = CONV_STD_LOGIC_VECTOR(CI_STATUS_RX_ERR, i_core_status'length) then
                i_rcv_irq <= '1';
                i_fsm_edev_cs <= S_TX_IDLE;

              elsif i_core_status = CONV_STD_LOGIC_VECTOR(CI_STATUS_RX_OK, i_core_status'length) then
                i_rxbuf_wr_last := OR_reduce(i_bcnt);
                i_fsm_edev_cs <= S_RX_DONE;

              elsif i_txbuf_empty = '0' then
              --Если HOST долго не получал прерывания(не было ответа на его запрос), то
              --он имеет право делать следующий запрос
                i_fsm_edev_cs <= S_TX_IDLE;

              end if;

              i_rxbuf_wr <= (i_core_rx_wr and AND_reduce(i_bcnt)) or i_rxbuf_wr_last;

          when S_RX_DONE =>

              i_rxbuf_wr <= '0';

              if tst_out(4) = '1' then
                i_rcv_irq <= '1';
                i_fsm_edev_cs <= S_TX_IDLE;
              end if;

      end case;
  end if;
end process;


--//----------------------------------
--//
--//----------------------------------
m_core : master485n
port map(
p_in_phy_rx   => p_in_phy_rx,
p_out_phy_tx  => p_out_phy_tx,
p_out_phy_dir => p_out_phy_dir,

p_in_txd_rdy  => i_core_txd_rdy,
p_in_txd      => i_core_txd,
p_out_txd_rd  => i_core_tx_rd,

p_out_rxd     => i_core_rxd,
p_out_rxd_wr  => i_core_rx_wr,

p_out_status  => i_core_status,

p_in_tst      => (others=>'0'),
p_out_tst     => tst_out,

p_in_bitclk   => p_in_bitclk,
p_in_clk      => p_in_clk,
p_in_rst      => p_in_rst
);


--END MAIN
end behavioral;
