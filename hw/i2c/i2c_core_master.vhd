-------------------------------------------------------------------------
-- Company     : Linkos
-- Engineer    : Golovachenko Victor
--
-- Create Date : 25.09.2012 10:51:25
-- Module Name : i2c_core_master
--
-- Назначение/Описание :
--  Модернизация ядра http://opencores.org/project,i2c_master_slave
--
--  модуль выполняет следующие атоманые операции:
--  C_I2C_CORE_CMD_START_WR - Отправка Start состояния + отправка данных
--  C_I2C_CORE_CMD_START_RD - Отправка Start состояния + отправка данных
--  C_I2C_CORE_CMD_RESTART  - Отправка Retart состояния
--  C_I2C_CORE_CMD_STOP     - Отправка Stop состояния
--  C_I2C_CORE_CMD_WR       - Отправка данных
--  C_I2C_CORE_CMD_RD       - Прием данных
--
--
-- Revision:
-- Revision 0.01 - File Created
-------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_misc.all;
use ieee.std_logic_unsigned.all;

library work;
use work.vicg_common_pkg.all;
use work.i2c_core_pkg.all;

entity i2c_core_master is
generic(
G_CLK_FREQ : natural := 25000000; --Определяет частоту для прота p_in_clk
G_BAUD     : natural := 100000;
G_DBG      : string:="OFF";
G_SIM      : string:="OFF"
);
port(
p_in_cmd    : in    std_logic_vector(2 downto 0);--Тип операции
p_in_start  : in    std_logic;--Старт опрерации
p_out_done  : out   std_logic;--Операция закончена
p_in_txack  : in    std_logic;--Задаем уровень для ответа(acknowlege) slave устройству
p_out_rxack : out   std_logic;--Принятый ответ(acknowlege) от slave устройства

p_in_txd    : in    std_logic_vector(7 downto 0);
p_out_rxd   : out   std_logic_vector(7 downto 0);

--I2C
p_inout_sda : inout std_logic;
p_inout_scl : inout std_logic;

--Технологический
p_in_tst    : in    std_logic_vector(31 downto 0);
p_out_tst   : out   std_logic_vector(31 downto 0);

--System
p_in_clk    : in    std_logic;
p_in_rst    : in    std_logic
);
end i2c_core_master;

architecture behavioral of i2c_core_master is

constant CI_FULL_BIT  : natural := (G_CLK_FREQ / G_BAUD - 1) / 2;
constant CI_HALF_BIT  : natural := CI_FULL_BIT / 2;
constant CI_GAP_WIDTH : natural := CI_FULL_BIT * 4;

type TI2C_master_state is (
S_IDLE,
S_START,
S_ACTION,
S_TXD_1,
S_TXD_2,
S_TXD_3,
S_TX_WAIT_ACK1,
S_TX_WAIT_ACK2,
S_TX_WAIT_ACK3,
S_TX_WAIT_ACK4,
S_RXD_1,
S_RXD_2,
S_RXD_3,
S_RX_SEND_ACK1,
S_RX_SEND_ACK2,
S_RX_SEND_ACK3,
S_RX_SEND_ACK4,
S_RESTART_1,
S_RESTART_2,
S_RESTART_3,
S_RESTART_4,
S_STOP_1,
S_STOP_2,
S_STOP_3
);

signal fsm_i2c_cs     : TI2C_master_state;

signal i_sda_out_en   : std_logic;
signal i_scl_out_en   : std_logic;
signal i_sda_out      : std_logic;
signal i_sda_in       : std_logic;
signal i_scl_out      : std_logic;
signal i_scl_cnt      : natural;
signal i_bit_cnt      : natural range 0 to 7;
signal i_rxack        : std_logic;
signal i_done         : std_logic;
signal i_rxd          : std_logic_vector(7 downto 0);
signal i_txd          : std_logic_vector(7 downto 0); --ADEV or user data

signal tst_fms_cs_dly,tst_fms_cs    : std_logic_vector(4 downto 0);


--MAIN
begin

------------------------------------
--Технологические сигналы
------------------------------------
gen_dbg_off : if strcmp(G_DBG,"OFF") generate
p_out_tst<=(others=>'0');
end generate gen_dbg_off;

gen_dbg_on : if strcmp(G_DBG,"ON") generate
ltstout:process(p_in_rst,p_in_clk)
begin
  if p_in_rst='1' then
    tst_fms_cs_dly<=(others=>'0');
    p_out_tst(0 downto 0)<=(others=>'0');
  elsif p_in_clk'event and p_in_clk='1' then

    tst_fms_cs_dly<=tst_fms_cs;
    p_out_tst(0)<=OR_reduce(tst_fms_cs_dly);
  end if;
end process ltstout;

tst_fms_cs<=CONV_STD_LOGIC_VECTOR(16#01#, tst_fms_cs'length) when fsm_i2c_cs=S_START          else
            CONV_STD_LOGIC_VECTOR(16#02#, tst_fms_cs'length) when fsm_i2c_cs=S_ACTION         else
            CONV_STD_LOGIC_VECTOR(16#03#, tst_fms_cs'length) when fsm_i2c_cs=S_TXD_1          else
            CONV_STD_LOGIC_VECTOR(16#04#, tst_fms_cs'length) when fsm_i2c_cs=S_TXD_2          else
            CONV_STD_LOGIC_VECTOR(16#05#, tst_fms_cs'length) when fsm_i2c_cs=S_TXD_3          else
            CONV_STD_LOGIC_VECTOR(16#06#, tst_fms_cs'length) when fsm_i2c_cs=S_TX_WAIT_ACK1   else
            CONV_STD_LOGIC_VECTOR(16#07#, tst_fms_cs'length) when fsm_i2c_cs=S_TX_WAIT_ACK2   else
            CONV_STD_LOGIC_VECTOR(16#08#, tst_fms_cs'length) when fsm_i2c_cs=S_TX_WAIT_ACK3   else
            CONV_STD_LOGIC_VECTOR(16#09#, tst_fms_cs'length) when fsm_i2c_cs=S_TX_WAIT_ACK4   else
            CONV_STD_LOGIC_VECTOR(16#0A#, tst_fms_cs'length) when fsm_i2c_cs=S_RXD_1          else
            CONV_STD_LOGIC_VECTOR(16#0B#, tst_fms_cs'length) when fsm_i2c_cs=S_RXD_2          else
            CONV_STD_LOGIC_VECTOR(16#0C#, tst_fms_cs'length) when fsm_i2c_cs=S_RXD_3          else
            CONV_STD_LOGIC_VECTOR(16#0D#, tst_fms_cs'length) when fsm_i2c_cs=S_RX_SEND_ACK1   else
            CONV_STD_LOGIC_VECTOR(16#0E#, tst_fms_cs'length) when fsm_i2c_cs=S_RX_SEND_ACK2   else
            CONV_STD_LOGIC_VECTOR(16#0F#, tst_fms_cs'length) when fsm_i2c_cs=S_RX_SEND_ACK3   else
            CONV_STD_LOGIC_VECTOR(16#10#, tst_fms_cs'length) when fsm_i2c_cs=S_RX_SEND_ACK4   else
            CONV_STD_LOGIC_VECTOR(16#11#, tst_fms_cs'length) when fsm_i2c_cs=S_RESTART_1      else
            CONV_STD_LOGIC_VECTOR(16#12#, tst_fms_cs'length) when fsm_i2c_cs=S_RESTART_4      else
            CONV_STD_LOGIC_VECTOR(16#13#, tst_fms_cs'length) when fsm_i2c_cs=S_RESTART_2      else
            CONV_STD_LOGIC_VECTOR(16#14#, tst_fms_cs'length) when fsm_i2c_cs=S_RESTART_3      else
            CONV_STD_LOGIC_VECTOR(16#15#, tst_fms_cs'length) when fsm_i2c_cs=S_STOP_1         else
            CONV_STD_LOGIC_VECTOR(16#16#, tst_fms_cs'length) when fsm_i2c_cs=S_STOP_2         else
            CONV_STD_LOGIC_VECTOR(16#17#, tst_fms_cs'length) when fsm_i2c_cs=S_STOP_3         else
            CONV_STD_LOGIC_VECTOR(16#00#, tst_fms_cs'length);--when fsm_i2c_cs=S_IDLE           else

end generate gen_dbg_on;


p_inout_scl <= i_scl_out when i_scl_out_en='1' else 'Z';
p_inout_sda <= i_sda_out when i_sda_out_en='1' else 'Z';
i_sda_in <= p_inout_sda;

p_out_rxack <= i_rxack;
p_out_done  <= i_done;

process( p_in_clk , p_in_rst )
begin
  if p_in_rst = '1' then
    fsm_i2c_cs <= S_IDLE;
    i_sda_out_en <= '0';
    i_scl_out_en <= '0';
    i_sda_out <= '1';
    i_scl_out <= '1';
    i_scl_cnt <= 0;
    i_bit_cnt <= 7;
    i_rxack <= '0';
    i_rxd <= (others=>'0');
    p_out_rxd <= (others=>'0');
    i_txd <= (others=>'0');

    i_done <='0';

  elsif p_in_clk'event and p_in_clk='1' then

    case fsm_i2c_cs is

        -------------------------------------
        --
        -------------------------------------
        when S_IDLE =>

            i_done <= '0';
            i_sda_out_en <= '0';
            i_scl_out_en <= '0';
            i_sda_out <= '0';
            i_scl_out <= '0';

            if p_in_start = '1' then
              if p_in_cmd = CONV_STD_LOGIC_VECTOR(C_I2C_CORE_CMD_START_WR, p_in_cmd'length) or
                 p_in_cmd = CONV_STD_LOGIC_VECTOR(C_I2C_CORE_CMD_START_RD, p_in_cmd'length) then

                i_txd <= p_in_txd;
                fsm_i2c_cs <= S_START;
              end if;
            end if;

        -------------------------------------
        --START_WR
        -------------------------------------
        when S_START =>

            i_scl_out_en <= '1';
            i_sda_out_en <= '1';
            if i_scl_cnt < CI_HALF_BIT then
              i_scl_cnt <= i_scl_cnt + 1;
              i_scl_out <= '1';
            else
              i_bit_cnt <= 7;
              i_scl_cnt <= 0;
              i_scl_out <= '0';

              if p_in_cmd = CONV_STD_LOGIC_VECTOR(C_I2C_CORE_CMD_START_WR, p_in_cmd'length) then
                fsm_i2c_cs <= S_TXD_1;
              elsif p_in_cmd = CONV_STD_LOGIC_VECTOR(C_I2C_CORE_CMD_START_RD, p_in_cmd'length) then
                fsm_i2c_cs <= S_RXD_1;
              end if;
            end if;

        when S_ACTION =>

            i_done <= '0';
            i_bit_cnt <= 7;

            i_sda_out_en <= '1';
            i_sda_out <= '0';
            i_scl_out <= '0';

            if p_in_start = '1' then
              if p_in_cmd = CONV_STD_LOGIC_VECTOR(C_I2C_CORE_CMD_RD, p_in_cmd'length) then
                fsm_i2c_cs <= S_RXD_1;

              elsif p_in_cmd = CONV_STD_LOGIC_VECTOR(C_I2C_CORE_CMD_WR, p_in_cmd'length) then
                i_txd <= p_in_txd;
                fsm_i2c_cs <= S_TXD_1;

              elsif p_in_cmd = CONV_STD_LOGIC_VECTOR(C_I2C_CORE_CMD_STOP, p_in_cmd'length) then
                fsm_i2c_cs <= S_STOP_1;

              elsif p_in_cmd = CONV_STD_LOGIC_VECTOR(C_I2C_CORE_CMD_RESTART, p_in_cmd'length) then
                fsm_i2c_cs <= S_RESTART_1;

              end if;
            end if;


        -------------------------------------
        --WRITE BYTE
        -------------------------------------
        when S_TXD_1 =>

            if i_scl_cnt < CI_HALF_BIT then
              i_scl_out <= '0';
              i_scl_cnt <= i_scl_cnt + 1;
            else
              i_scl_cnt <= 0;
              fsm_i2c_cs <= S_TXD_2;
              i_sda_out <= i_txd(7);
            end if;

        when S_TXD_2 =>

            if i_scl_cnt < CI_HALF_BIT then
              i_scl_cnt <= i_scl_cnt + 1;
            else
              i_scl_cnt <= 0;
              fsm_i2c_cs <= S_TXD_3;
            end if;

        when S_TXD_3 =>

            if i_scl_cnt < CI_FULL_BIT then
              i_scl_out <= '1';
              i_scl_cnt <= i_scl_cnt + 1;
            else
              i_scl_cnt <= 0;
              i_txd<=i_txd(6 downto 0) & '0';--Shift left
              if i_bit_cnt >= 1 then
                i_bit_cnt <= i_bit_cnt - 1;
                fsm_i2c_cs <= S_TXD_1;
              elsif i_bit_cnt = 0 then
                fsm_i2c_cs <= S_TX_WAIT_ACK1;
              end if;
            end if;

        -------------------------------------
        --WAIT ACKNOWLEDGE
        -------------------------------------
        when S_TX_WAIT_ACK1 =>

            i_scl_out <= '0';
            if i_scl_cnt < CI_HALF_BIT then
              i_scl_cnt <= i_scl_cnt + 1;
            else
              i_scl_cnt <= 0;
              i_sda_out_en <= '0';
              i_sda_out <= '0';
              fsm_i2c_cs <= S_TX_WAIT_ACK2;
            end if;

        when S_TX_WAIT_ACK2 =>

            if i_scl_cnt < CI_HALF_BIT then
              i_scl_cnt <= i_scl_cnt + 1;
            else
              i_scl_cnt <= 0;
              fsm_i2c_cs <= S_TX_WAIT_ACK3;
            end if;

        when S_TX_WAIT_ACK3 =>

            i_scl_out <= '1';
            if i_scl_cnt < CI_HALF_BIT then
              i_scl_cnt <= i_scl_cnt + 1;
            else
              i_scl_cnt <= 0;
              i_rxack <= i_sda_in;
              fsm_i2c_cs <= S_TX_WAIT_ACK4;
            end if;

        when S_TX_WAIT_ACK4 =>

            i_done <= '0';
            if i_scl_cnt < CI_HALF_BIT then
              i_scl_cnt <= i_scl_cnt + 1;
            else
              i_scl_cnt <= 0;
              i_done <= '1';
              fsm_i2c_cs <= S_ACTION;
            end if;


        -------------------------------------
        --READ BYTE
        -------------------------------------
        when S_RXD_1 =>

            i_scl_out <= '0';
            i_sda_out <= '0'; i_sda_out_en <= '0';
            if i_scl_cnt < CI_FULL_BIT then
              i_scl_cnt <= i_scl_cnt + 1;
            else
              i_scl_cnt <= 0;
              fsm_i2c_cs <= S_RXD_2;
            end if;

        when S_RXD_2 =>

            i_scl_out <= '1';
            if i_scl_cnt < CI_HALF_BIT then
              i_scl_cnt <= i_scl_cnt + 1;
            else
              i_scl_cnt <= 0;
              i_rxd <= i_rxd( 6 downto 0 ) & i_sda_in;
              fsm_i2c_cs <= S_RXD_3;
            end if;

        when S_RXD_3 =>

            i_scl_out <= '1';
            if i_scl_cnt < CI_HALF_BIT then
              i_scl_cnt <= i_scl_cnt + 1;
            else
              i_scl_cnt <= 0;
              if i_bit_cnt > 0 then
                i_bit_cnt <= i_bit_cnt - 1;
                i_scl_out <= '0';
                fsm_i2c_cs <= S_RXD_1;
              else
                i_txd <= (others=>'0');
                p_out_rxd <= i_rxd;
                fsm_i2c_cs <= S_RX_SEND_ACK1;
              end if;
            end if;

        -------------------------------------
        --SEND ACKNOWELEDGE
        -------------------------------------
        when S_RX_SEND_ACK1 =>

            i_scl_out <= '0';
            i_sda_out_en <= '1';
            if i_scl_cnt < CI_HALF_BIT then
              i_scl_cnt <= i_scl_cnt + 1;
            else
              i_scl_cnt <= 0;
              i_sda_out <= p_in_txack;
              fsm_i2c_cs <= S_RX_SEND_ACK2;
            end if;

        when S_RX_SEND_ACK2 =>

            i_scl_out <= '0';
            if i_scl_cnt < CI_HALF_BIT then
              i_scl_cnt <= i_scl_cnt + 1;
            else
              i_scl_cnt <= 0;
              fsm_i2c_cs <= S_RX_SEND_ACK3;
            end if;

        when S_RX_SEND_ACK3 =>

            i_scl_out <= '1';
            if i_scl_cnt < CI_FULL_BIT then
              i_scl_cnt <= i_scl_cnt + 1;
              fsm_i2c_cs <= S_RX_SEND_ACK3;
            else
              i_scl_cnt <= 0;
              fsm_i2c_cs <= S_RX_SEND_ACK4;
            end if;

        when S_RX_SEND_ACK4 =>

            i_scl_out <= '0';
            if i_scl_cnt < CI_HALF_BIT then
              i_scl_cnt <= i_scl_cnt + 1;
              fsm_i2c_cs <= S_RX_SEND_ACK4;
            else
              i_scl_cnt <= 0;
              i_done <= '1';
              fsm_i2c_cs <= S_ACTION;
            end if;

        -------------------------------------
        --STOP
        -------------------------------------
        when S_STOP_1 =>

            i_scl_out <= '0';
            i_sda_out <= '0';
            if i_scl_cnt < CI_HALF_BIT then
              i_scl_cnt <= i_scl_cnt + 1;
            else
              i_scl_cnt <= 0;
              fsm_i2c_cs <= S_STOP_2;
            end if;

        when S_STOP_2 =>

            i_scl_out <= '1';
            if i_scl_cnt < CI_HALF_BIT then
              i_scl_cnt <= i_scl_cnt + 1;
            else
              i_scl_cnt <= 0;
              i_sda_out <= '1';
              fsm_i2c_cs <= S_STOP_3;
            end if;

        when S_STOP_3 =>

            if i_scl_cnt < CI_GAP_WIDTH then
              i_scl_cnt <= i_scl_cnt + 1;
            else
              i_done <= '1';
              i_scl_cnt <= 0;
              fsm_i2c_cs <= S_IDLE;
            end if;

        -------------------------------------
        --RESTART
        -------------------------------------
        when S_RESTART_1 =>

            if i_scl_cnt < CI_HALF_BIT then
              i_scl_cnt <= i_scl_cnt + 1;
            else
              i_scl_cnt <= 0;
              i_scl_out <= '0';
              i_sda_out <= '1';
              fsm_i2c_cs <= S_RESTART_2;
            end if;

        when S_RESTART_2 =>

            if i_scl_cnt < CI_HALF_BIT then
              i_scl_cnt <= i_scl_cnt + 1;
            else
              i_scl_cnt <= 0;
              i_scl_out <= '1';
              i_sda_out <= '1';
              fsm_i2c_cs <= S_RESTART_3;
            end if;

        when S_RESTART_3 =>

            if i_scl_cnt < CI_HALF_BIT then
              i_scl_cnt <= i_scl_cnt + 1;
            else
              i_scl_cnt <= 0;
              i_scl_out <= '1';
              i_sda_out <= '0';
              fsm_i2c_cs <= S_RESTART_4;
            end if;

        when S_RESTART_4 =>

            if i_scl_cnt < CI_HALF_BIT then
              i_scl_cnt <= i_scl_cnt + 1;
            else
              i_scl_cnt <= 0;
              i_scl_out <= '0';
              i_sda_out <= '0';
              i_done <= '1';
              fsm_i2c_cs <= S_ACTION;
            end if;

        when others =>
            fsm_i2c_cs <= S_IDLE;

    end case;

  end if;
end process;

--END MAIN
end behavioral;
