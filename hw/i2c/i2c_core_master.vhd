-------------------------------------------------------------------------
-- Engineer    : Golovachenko Victor
--
-- Create Date : 25.09.2012 10:51:25
-- Module Name : i2c_core_master
--
-- Description :
--  Change core from http://opencores.org/project,i2c_master_slave
--  created by - elis@(ELIS-WXP)
--
-- Atomic operations:
-- C_I2C_CORE_CMD_START_WR - Send Start state + send data
-- C_I2C_CORE_CMD_START_RD - Send Start state + send data
-- C_I2C_CORE_CMD_RESTART  - Send Retart state
-- C_I2C_CORE_CMD_STOP     - Send Stop state
-- C_I2C_CORE_CMD_WR       - Send data
-- C_I2C_CORE_CMD_RD       - Recieve data
--
-------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.reduce_pack.all;
--use ieee.std_logic_arith.all;
--use ieee.std_logic_misc.all;
--use ieee.std_logic_unsigned.all;

library work;
use work.vicg_common_pkg.all;
use work.i2c_core_pkg.all;

entity i2c_core_master is
generic(
G_CLK_FREQ : natural := 25000000; --Frequence of port p_in_clk
G_BAUD     : natural := 100000;
G_DBG      : string := "OFF";
G_SIM      : string := "OFF"
);
port(
p_in_cmd    : in    std_logic_vector(2 downto 0);--Type operation
p_in_start  : in    std_logic;--Start operation
p_out_done  : out   std_logic;--Operation done
p_in_txack  : in    std_logic;--Set level for acknowlege to slave device
p_out_rxack : out   std_logic;--Recieve acknowlege from slave device

p_in_txd    : in    std_logic_vector(7 downto 0);
p_out_rxd   : out   std_logic_vector(7 downto 0);

--I2C
p_inout_sda : inout std_logic;
p_inout_scl : inout std_logic;

--DBG
p_in_tst    : in    std_logic_vector(31 downto 0);
p_out_tst   : out   std_logic_vector(31 downto 0);

--System
p_in_clk    : in    std_logic;
p_in_rst    : in    std_logic
);
end entity i2c_core_master;

architecture behavioral of i2c_core_master is

constant CI_FULL_BIT  : natural := G_CLK_FREQ / G_BAUD;
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

signal i_fsm_i2c      : TI2C_master_state;

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
signal i_txd          : std_logic_vector(7 downto 0); --AdrDEV or user data

signal tst_fms_cs_dly : std_logic_vector(4 downto 0);
signal tst_fms_cs     : unsigned(4 downto 0);


begin --architecture behavioral


p_inout_scl <= i_scl_out when i_scl_out_en = '1' else 'Z';
p_inout_sda <= i_sda_out when i_sda_out_en = '1' else 'Z';
i_sda_in <= p_inout_sda;

p_out_rxack <= i_rxack;
p_out_done  <= i_done;

process(p_in_clk, p_in_rst)
begin
  if (p_in_rst = '1') then

    i_fsm_i2c <= S_IDLE;
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

  elsif rising_edge(p_in_clk) then

    case i_fsm_i2c is

        -------------------------------------
        --
        -------------------------------------
        when S_IDLE =>

            i_done <= '0';
            i_sda_out_en <= '0';
            i_scl_out_en <= '0';
            i_sda_out <= '0';
            i_scl_out <= '0';

            if (p_in_start = '1') then
              if ( UNSIGNED(p_in_cmd) = TO_UNSIGNED(C_I2C_CORE_CMD_START_WR, p_in_cmd'length) or
                   UNSIGNED(p_in_cmd) = TO_UNSIGNED(C_I2C_CORE_CMD_START_RD, p_in_cmd'length) ) then

                i_txd <= p_in_txd;
                i_fsm_i2c <= S_START;

              end if;
            end if;

        -------------------------------------
        --START_WR
        -------------------------------------
        when S_START =>

            i_scl_out_en <= '1';
            i_sda_out_en <= '1';

            if (i_scl_cnt < CI_HALF_BIT) then
              i_scl_cnt <= i_scl_cnt + 1;
              i_scl_out <= '1';

            else
              i_bit_cnt <= 7;
              i_scl_cnt <= 0;
              i_scl_out <= '0';

              if (UNSIGNED(p_in_cmd) = TO_UNSIGNED(C_I2C_CORE_CMD_START_WR, p_in_cmd'length)) then
                i_fsm_i2c <= S_TXD_1;

              elsif (UNSIGNED(p_in_cmd) = TO_UNSIGNED(C_I2C_CORE_CMD_START_RD, p_in_cmd'length)) then
                i_fsm_i2c <= S_RXD_1;

              end if;
            end if;

        when S_ACTION =>

            i_done <= '0';
            i_bit_cnt <= 7;

            i_sda_out_en <= '1';
            i_sda_out <= '0';
            i_scl_out <= '0';

            if (p_in_start = '1') then
              if (UNSIGNED(p_in_cmd) = TO_UNSIGNED(C_I2C_CORE_CMD_RD, p_in_cmd'length)) then
                i_fsm_i2c <= S_RXD_1;

              elsif (UNSIGNED(p_in_cmd) = TO_UNSIGNED(C_I2C_CORE_CMD_WR, p_in_cmd'length)) then
                i_txd <= p_in_txd;
                i_fsm_i2c <= S_TXD_1;

              elsif (UNSIGNED(p_in_cmd) = TO_UNSIGNED(C_I2C_CORE_CMD_STOP, p_in_cmd'length)) then
                i_fsm_i2c <= S_STOP_1;

              elsif (UNSIGNED(p_in_cmd) = TO_UNSIGNED(C_I2C_CORE_CMD_RESTART, p_in_cmd'length)) then
                i_fsm_i2c <= S_RESTART_1;

              end if;
            end if;


        -------------------------------------
        --WRITE BYTE
        -------------------------------------
        when S_TXD_1 =>

            if (i_scl_cnt < CI_HALF_BIT) then
              i_scl_out <= '0';
              i_scl_cnt <= i_scl_cnt + 1;

            else
              i_scl_cnt <= 0;
              i_fsm_i2c <= S_TXD_2;
              i_sda_out <= i_txd(7);

            end if;

        when S_TXD_2 =>

            if (i_scl_cnt < CI_HALF_BIT) then
              i_scl_cnt <= i_scl_cnt + 1;

            else
              i_scl_cnt <= 0;
              i_fsm_i2c <= S_TXD_3;

            end if;

        when S_TXD_3 =>

            if (i_scl_cnt < CI_FULL_BIT) then
              i_scl_out <= '1';
              i_scl_cnt <= i_scl_cnt + 1;

            else
              i_scl_cnt <= 0;
              i_txd <= i_txd(6 downto 0) & '0';--Shift left

              if (i_bit_cnt >= 1) then
                i_bit_cnt <= i_bit_cnt - 1;
                i_fsm_i2c <= S_TXD_1;

              elsif (i_bit_cnt = 0) then
                i_fsm_i2c <= S_TX_WAIT_ACK1;

              end if;
            end if;

        -------------------------------------
        --WAIT ACKNOWLEDGE
        -------------------------------------
        when S_TX_WAIT_ACK1 =>

            i_scl_out <= '0';

            if (i_scl_cnt < CI_HALF_BIT) then
              i_scl_cnt <= i_scl_cnt + 1;

            else
              i_scl_cnt <= 0;
              i_sda_out_en <= '0';
              i_sda_out <= '0';
              i_fsm_i2c <= S_TX_WAIT_ACK2;

            end if;

        when S_TX_WAIT_ACK2 =>

            if (i_scl_cnt < CI_HALF_BIT) then
              i_scl_cnt <= i_scl_cnt + 1;

            else
              i_scl_cnt <= 0;
              i_fsm_i2c <= S_TX_WAIT_ACK3;

            end if;

        when S_TX_WAIT_ACK3 =>

            i_scl_out <= '1';

            if (i_scl_cnt < CI_HALF_BIT) then
              i_scl_cnt <= i_scl_cnt + 1;

            else
              i_scl_cnt <= 0;
              i_rxack <= i_sda_in;
              i_fsm_i2c <= S_TX_WAIT_ACK4;

            end if;

        when S_TX_WAIT_ACK4 =>

            i_done <= '0';

            if (i_scl_cnt < CI_HALF_BIT) then
              i_scl_cnt <= i_scl_cnt + 1;

            else
              i_scl_cnt <= 0;
              i_done <= '1';
              i_fsm_i2c <= S_ACTION;

            end if;


        -------------------------------------
        --READ BYTE
        -------------------------------------
        when S_RXD_1 =>

            i_scl_out <= '0';
            i_sda_out <= '0'; i_sda_out_en <= '0';

            if (i_scl_cnt < CI_FULL_BIT) then
              i_scl_cnt <= i_scl_cnt + 1;

            else
              i_scl_cnt <= 0;
              i_fsm_i2c <= S_RXD_2;

            end if;

        when S_RXD_2 =>

            i_scl_out <= '1';

            if (i_scl_cnt < CI_HALF_BIT) then
              i_scl_cnt <= i_scl_cnt + 1;

            else
              i_scl_cnt <= 0;
              i_rxd <= i_rxd( 6 downto 0 ) & i_sda_in;
              i_fsm_i2c <= S_RXD_3;

            end if;

        when S_RXD_3 =>

            i_scl_out <= '1';

            if (i_scl_cnt < CI_HALF_BIT) then
              i_scl_cnt <= i_scl_cnt + 1;

            else
              i_scl_cnt <= 0;

              if (i_bit_cnt > 0) then
                i_bit_cnt <= i_bit_cnt - 1;
                i_scl_out <= '0';
                i_fsm_i2c <= S_RXD_1;

              else
                i_txd <= (others=>'0');
                p_out_rxd <= i_rxd;
                i_fsm_i2c <= S_RX_SEND_ACK1;

              end if;
            end if;

        -------------------------------------
        --SEND ACKNOWELEDGE
        -------------------------------------
        when S_RX_SEND_ACK1 =>

            i_scl_out <= '0';
            i_sda_out_en <= '1';

            if (i_scl_cnt < CI_HALF_BIT) then
              i_scl_cnt <= i_scl_cnt + 1;

            else
              i_scl_cnt <= 0;
              i_sda_out <= p_in_txack;
              i_fsm_i2c <= S_RX_SEND_ACK2;

            end if;

        when S_RX_SEND_ACK2 =>

            i_scl_out <= '0';

            if (i_scl_cnt < CI_HALF_BIT) then
              i_scl_cnt <= i_scl_cnt + 1;

            else
              i_scl_cnt <= 0;
              i_fsm_i2c <= S_RX_SEND_ACK3;

            end if;

        when S_RX_SEND_ACK3 =>

            i_scl_out <= '1';

            if (i_scl_cnt < CI_FULL_BIT) then
              i_scl_cnt <= i_scl_cnt + 1;
              i_fsm_i2c <= S_RX_SEND_ACK3;

            else
              i_scl_cnt <= 0;
              i_fsm_i2c <= S_RX_SEND_ACK4;

            end if;

        when S_RX_SEND_ACK4 =>

            i_scl_out <= '0';

            if (i_scl_cnt < CI_HALF_BIT) then
              i_scl_cnt <= i_scl_cnt + 1;
              i_fsm_i2c <= S_RX_SEND_ACK4;

            else
              i_scl_cnt <= 0;
              i_done <= '1';
              i_fsm_i2c <= S_ACTION;

            end if;

        -------------------------------------
        --STOP
        -------------------------------------
        when S_STOP_1 =>

            i_scl_out <= '0';
            i_sda_out <= '0';

            if (i_scl_cnt < CI_HALF_BIT) then
              i_scl_cnt <= i_scl_cnt + 1;

            else
              i_scl_cnt <= 0;
              i_fsm_i2c <= S_STOP_2;

            end if;

        when S_STOP_2 =>

            i_scl_out <= '1';

            if (i_scl_cnt < CI_HALF_BIT) then
              i_scl_cnt <= i_scl_cnt + 1;

            else
              i_scl_cnt <= 0;
              i_sda_out <= '1';
              i_fsm_i2c <= S_STOP_3;

            end if;

        when S_STOP_3 =>

            if (i_scl_cnt < CI_GAP_WIDTH) then
              i_scl_cnt <= i_scl_cnt + 1;

            else
              i_done <= '1';
              i_scl_cnt <= 0;
              i_fsm_i2c <= S_IDLE;

            end if;

        -------------------------------------
        --RESTART
        -------------------------------------
        when S_RESTART_1 =>

            if (i_scl_cnt < CI_HALF_BIT) then
              i_scl_cnt <= i_scl_cnt + 1;

            else
              i_scl_cnt <= 0;
              i_scl_out <= '0';
              i_sda_out <= '1';
              i_fsm_i2c <= S_RESTART_2;

            end if;

        when S_RESTART_2 =>

            if (i_scl_cnt < CI_HALF_BIT) then
              i_scl_cnt <= i_scl_cnt + 1;

            else
              i_scl_cnt <= 0;
              i_scl_out <= '1';
              i_sda_out <= '1';
              i_fsm_i2c <= S_RESTART_3;

            end if;

        when S_RESTART_3 =>

            if (i_scl_cnt < CI_HALF_BIT) then
              i_scl_cnt <= i_scl_cnt + 1;

            else
              i_scl_cnt <= 0;
              i_scl_out <= '1';
              i_sda_out <= '0';
              i_fsm_i2c <= S_RESTART_4;

            end if;

        when S_RESTART_4 =>

            if (i_scl_cnt < CI_HALF_BIT) then
              i_scl_cnt <= i_scl_cnt + 1;

            else
              i_scl_cnt <= 0;
              i_scl_out <= '0';
              i_sda_out <= '0';
              i_done <= '1';
              i_fsm_i2c <= S_ACTION;

            end if;

        when others =>
            i_fsm_i2c <= S_IDLE;

    end case;

  end if;
end process;


------------------------------------
--DBG
------------------------------------
gen_dbg_off : if strcmp(G_DBG,"OFF") generate
p_out_tst <= (others=>'0');
end generate gen_dbg_off;

gen_dbg_on : if strcmp(G_DBG,"ON") generate
process(p_in_rst, p_in_clk)
begin
  if (p_in_rst = '1') then

    tst_fms_cs_dly <= (others=>'0');
    p_out_tst <= (others=>'0');

  elsif rising_edge(p_in_clk) then

    tst_fms_cs_dly <= std_logic_vector(tst_fms_cs);
    p_out_tst(0) <= OR_reduce(tst_fms_cs_dly);

  end if;
end process;

tst_fms_cs <= TO_UNSIGNED(16#01#, tst_fms_cs'length) when i_fsm_i2c = S_START          else
              TO_UNSIGNED(16#02#, tst_fms_cs'length) when i_fsm_i2c = S_ACTION         else
              TO_UNSIGNED(16#03#, tst_fms_cs'length) when i_fsm_i2c = S_TXD_1          else
              TO_UNSIGNED(16#04#, tst_fms_cs'length) when i_fsm_i2c = S_TXD_2          else
              TO_UNSIGNED(16#05#, tst_fms_cs'length) when i_fsm_i2c = S_TXD_3          else
              TO_UNSIGNED(16#06#, tst_fms_cs'length) when i_fsm_i2c = S_TX_WAIT_ACK1   else
              TO_UNSIGNED(16#07#, tst_fms_cs'length) when i_fsm_i2c = S_TX_WAIT_ACK2   else
              TO_UNSIGNED(16#08#, tst_fms_cs'length) when i_fsm_i2c = S_TX_WAIT_ACK3   else
              TO_UNSIGNED(16#09#, tst_fms_cs'length) when i_fsm_i2c = S_TX_WAIT_ACK4   else
              TO_UNSIGNED(16#0A#, tst_fms_cs'length) when i_fsm_i2c = S_RXD_1          else
              TO_UNSIGNED(16#0B#, tst_fms_cs'length) when i_fsm_i2c = S_RXD_2          else
              TO_UNSIGNED(16#0C#, tst_fms_cs'length) when i_fsm_i2c = S_RXD_3          else
              TO_UNSIGNED(16#0D#, tst_fms_cs'length) when i_fsm_i2c = S_RX_SEND_ACK1   else
              TO_UNSIGNED(16#0E#, tst_fms_cs'length) when i_fsm_i2c = S_RX_SEND_ACK2   else
              TO_UNSIGNED(16#0F#, tst_fms_cs'length) when i_fsm_i2c = S_RX_SEND_ACK3   else
              TO_UNSIGNED(16#10#, tst_fms_cs'length) when i_fsm_i2c = S_RX_SEND_ACK4   else
              TO_UNSIGNED(16#11#, tst_fms_cs'length) when i_fsm_i2c = S_RESTART_1      else
              TO_UNSIGNED(16#12#, tst_fms_cs'length) when i_fsm_i2c = S_RESTART_4      else
              TO_UNSIGNED(16#13#, tst_fms_cs'length) when i_fsm_i2c = S_RESTART_2      else
              TO_UNSIGNED(16#14#, tst_fms_cs'length) when i_fsm_i2c = S_RESTART_3      else
              TO_UNSIGNED(16#15#, tst_fms_cs'length) when i_fsm_i2c = S_STOP_1         else
              TO_UNSIGNED(16#16#, tst_fms_cs'length) when i_fsm_i2c = S_STOP_2         else
              TO_UNSIGNED(16#17#, tst_fms_cs'length) when i_fsm_i2c = S_STOP_3         else
              TO_UNSIGNED(16#00#, tst_fms_cs'length);--when i_fsm_i2c = S_IDLE           else

end generate gen_dbg_on;

end architecture behavioral;
