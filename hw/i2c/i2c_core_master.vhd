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
G_CLK_FREQ : natural := 25000000;
G_BAUD     : natural := 100000;
G_DBG      : string:="OFF";
G_SIM      : string:="OFF"
);
port(
p_in_start  : in    std_logic;
p_in_cmd    : in    std_logic_vector(3 downto 0);
p_out_done  : out   std_logic;

p_in_txack  : in    std_logic;
p_out_rxack : out   std_logic;

p_in_di     : in    std_logic_vector (7 downto 0);
p_out_do    : out   std_logic_vector (7 downto 0);

--I2C
p_inout_sda : inout std_logic;
p_out_scl   : out   std_logic;

--Технологический
p_in_tst    : in    std_logic_vector(31 downto 0);
p_out_tst   : out   std_logic_vector(31 downto 0);

--System
p_in_clk    : in    std_logic;
p_in_rst    : in    std_logic
);
end i2c_core_master;

architecture behavioral of i2c_core_master is

-- constant BAUD      : natural := 100000;
constant CI_FULL_BIT  : natural := ( G_CLK_FREQ / G_BAUD - 1 ) / 2;
constant CI_HALF_BIT  : natural := CI_FULL_BIT / 2;
constant CI_GAP_WIDTH : natural := CI_FULL_BIT * 4;

signal i_sda        : std_logic;
signal i_scl        : std_logic;
signal i_scl_cnt    : natural;
signal i_bit_cnt    : natural range 0 to 7;
signal i_rxack      : std_logic;
signal i_done       : std_logic;
signal i_rxd        : std_logic_vector(7 downto 0);
signal i_txd        : std_logic_vector(7 downto 0); --latched address and data
alias  fld_rd_wr    : std_logic is i_txd( 0 ); --1 - read, 0 - write

type TI2C_master_state is (
S_IDLE,
S_START,
S_ACTIVE,
S_WAIT_1_HALF,
S_WAIT_2_HALF,
S_WAIT_FULL,
S_WAIT_ACK,
S_WAIT_ACK_2_HALF,
S_WAIT_ACK_3_HALF,
S_WAIT_ACK_4_HALF,
S_RD_WAIT_LOW,
S_RD_WAIT_HALF,
S_RD_READ,
S_STOP,
S_RD_WAIT_ACK_BIT,
S_RD_WAIT_ACK,
S_RD_GET_ACK,
S_RESTART,
S_RESTART_1,
S_RESTART_2,
S_GAP,
S_STOP_1,
S_RD_WAIT_LAST_HALF,
S_RESTART_CLK_HIGH
);

signal fsm_i2c_cs : TI2C_master_state;

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
    p_out_tst(31 downto 1)<=(others=>'0');
  elsif p_in_clk'event and p_in_clk='1' then

    tst_fms_cs_dly<=tst_fms_cs;
    p_out_tst(0)<=OR_reduce(tst_fms_cs_dly);
  end if;
end process ltstout;

tst_fms_cs<=CONV_STD_LOGIC_VECTOR(16#01#, tst_fms_cs'length) when fsm_i2c_cs=S_START                else
            CONV_STD_LOGIC_VECTOR(16#02#, tst_fms_cs'length) when fsm_i2c_cs=S_ACTIVE               else
            CONV_STD_LOGIC_VECTOR(16#03#, tst_fms_cs'length) when fsm_i2c_cs=S_WAIT_1_HALF          else
            CONV_STD_LOGIC_VECTOR(16#04#, tst_fms_cs'length) when fsm_i2c_cs=S_WAIT_2_HALF          else
            CONV_STD_LOGIC_VECTOR(16#05#, tst_fms_cs'length) when fsm_i2c_cs=S_WAIT_FULL            else
            CONV_STD_LOGIC_VECTOR(16#06#, tst_fms_cs'length) when fsm_i2c_cs=S_WAIT_ACK             else
            CONV_STD_LOGIC_VECTOR(16#07#, tst_fms_cs'length) when fsm_i2c_cs=S_WAIT_ACK_2_HALF      else
            CONV_STD_LOGIC_VECTOR(16#08#, tst_fms_cs'length) when fsm_i2c_cs=S_WAIT_ACK_3_HALF      else
            CONV_STD_LOGIC_VECTOR(16#09#, tst_fms_cs'length) when fsm_i2c_cs=S_WAIT_ACK_4_HALF      else
            CONV_STD_LOGIC_VECTOR(16#0A#, tst_fms_cs'length) when fsm_i2c_cs=S_RD_WAIT_LOW          else
            CONV_STD_LOGIC_VECTOR(16#0B#, tst_fms_cs'length) when fsm_i2c_cs=S_RD_WAIT_HALF         else
            CONV_STD_LOGIC_VECTOR(16#0C#, tst_fms_cs'length) when fsm_i2c_cs=S_RD_READ              else
            CONV_STD_LOGIC_VECTOR(16#0D#, tst_fms_cs'length) when fsm_i2c_cs=S_STOP                 else
            CONV_STD_LOGIC_VECTOR(16#0E#, tst_fms_cs'length) when fsm_i2c_cs=S_RD_WAIT_ACK_BIT      else
            CONV_STD_LOGIC_VECTOR(16#0F#, tst_fms_cs'length) when fsm_i2c_cs=S_RD_WAIT_ACK          else
            CONV_STD_LOGIC_VECTOR(16#10#, tst_fms_cs'length) when fsm_i2c_cs=S_RD_GET_ACK           else
            CONV_STD_LOGIC_VECTOR(16#11#, tst_fms_cs'length) when fsm_i2c_cs=S_RESTART              else
            CONV_STD_LOGIC_VECTOR(16#12#, tst_fms_cs'length) when fsm_i2c_cs=S_GAP                  else
            CONV_STD_LOGIC_VECTOR(16#13#, tst_fms_cs'length) when fsm_i2c_cs=S_STOP_1               else
            CONV_STD_LOGIC_VECTOR(16#14#, tst_fms_cs'length) when fsm_i2c_cs=S_RD_WAIT_LAST_HALF    else
            CONV_STD_LOGIC_VECTOR(16#15#, tst_fms_cs'length) when fsm_i2c_cs=S_RESTART_CLK_HIGH     else
            CONV_STD_LOGIC_VECTOR(16#16#, tst_fms_cs'length) when fsm_i2c_cs=S_RESTART_1            else
            CONV_STD_LOGIC_VECTOR(16#17#, tst_fms_cs'length) when fsm_i2c_cs=S_RESTART_2            else
            CONV_STD_LOGIC_VECTOR(16#00#, tst_fms_cs'length);-- when fsm_i2c_cs=S_IDLE             else

end generate gen_dbg_on;


p_inout_sda <= i_sda;
p_out_scl <= i_scl;

p_out_rxack <= i_rxack;
p_out_done  <= i_done;

i2c_master:
process( p_in_clk , p_in_rst )
begin
  if p_in_rst = '1' then
    fsm_i2c_cs <= S_IDLE;
    i_sda <= 'Z';
    i_scl <= 'Z';
    i_scl_cnt <= 0;
    i_bit_cnt <= 7;
    i_rxack <= '0';
    i_rxd <= (others=>'0');
    p_out_do <= (others=>'0');
    i_txd <= (others=>'0');

    i_done <='0';

  elsif p_in_clk'event and p_in_clk='1' then

    case fsm_i2c_cs is

        -------------------------------------
        --
        -------------------------------------
        when S_IDLE =>

            i_done <= '0';
            i_sda <= 'Z';
            i_scl <= 'Z';
            if p_in_start = '1' then
              if p_in_cmd = CONV_STD_LOGIC_VECTOR(C_I2C_CORE_CMD_START_WR, p_in_cmd'length) or
                 p_in_cmd = CONV_STD_LOGIC_VECTOR(C_I2C_CORE_CMD_START_RD, p_in_cmd'length) then
                fsm_i2c_cs <= S_START;
              end if;
            end if;

        -------------------------------------
        --START_WR
        -------------------------------------
        when S_START =>

            i_sda <= '0';
            if i_scl_cnt < CI_HALF_BIT then
              i_scl_cnt <= i_scl_cnt + 1;
              i_scl <= '1';
            else
              i_bit_cnt <= 7;
              i_scl_cnt <= 0;
              i_scl <= '0';
              i_txd <= p_in_di;
              if p_in_cmd = CONV_STD_LOGIC_VECTOR(C_I2C_CORE_CMD_START_WR, p_in_cmd'length) then
                fsm_i2c_cs <= S_WAIT_1_HALF;
              elsif p_in_cmd = CONV_STD_LOGIC_VECTOR(C_I2C_CORE_CMD_START_RD, p_in_cmd'length) then
                fsm_i2c_cs <= S_RD_WAIT_LOW;
              end if;
            end if;

        when S_ACTIVE =>

            i_done <= '0';
            i_bit_cnt <= 7;
            i_sda <= '0';
            i_scl <= '0';

            if p_in_start = '1' then
              if p_in_cmd = CONV_STD_LOGIC_VECTOR(C_I2C_CORE_CMD_RD, p_in_cmd'length) then --if p_in_cmd_rd = '1' then
                fsm_i2c_cs <= S_RD_WAIT_LOW;

              elsif p_in_cmd = CONV_STD_LOGIC_VECTOR(C_I2C_CORE_CMD_WR, p_in_cmd'length) then --elsif p_in_cmd_wr = '1' then
                i_txd <= p_in_di;
                fsm_i2c_cs <= S_WAIT_1_HALF;

              elsif p_in_cmd = CONV_STD_LOGIC_VECTOR(C_I2C_CORE_CMD_STOP, p_in_cmd'length) then --elsif p_in_stop = '1' then
                fsm_i2c_cs <= S_STOP_1;

              elsif p_in_cmd = CONV_STD_LOGIC_VECTOR(C_I2C_CORE_CMD_RESTART, p_in_cmd'length) then --elsif p_in_start = '1' then
                fsm_i2c_cs <= S_RESTART;

              end if;
            end if;


        -------------------------------------
        --WRITE BYTE
        -------------------------------------
        when S_WAIT_1_HALF =>

            if i_scl_cnt < CI_HALF_BIT then
              i_scl <= '0';
              i_scl_cnt <= i_scl_cnt + 1;
            else
              i_scl_cnt <= 0;
              fsm_i2c_cs <= S_WAIT_2_HALF;
              i_sda <= i_txd(i_bit_cnt);
            end if;

        when S_WAIT_2_HALF =>

            if i_scl_cnt < CI_HALF_BIT then
              i_scl_cnt <= i_scl_cnt + 1;
            else
              i_scl_cnt <= 0;
              fsm_i2c_cs <= S_WAIT_FULL;
            end if;

        when S_WAIT_FULL =>

            if i_scl_cnt < CI_FULL_BIT then
              i_scl <= '1';
              i_scl_cnt <= i_scl_cnt + 1;
            else
              i_scl_cnt <= 0;
              if i_bit_cnt >= 1 then
                i_bit_cnt <= i_bit_cnt - 1;
                fsm_i2c_cs <= S_WAIT_1_HALF;
              elsif i_bit_cnt = 0 then
                --i_sda <= 'Z';
                fsm_i2c_cs <= S_WAIT_ACK;
              end if;
            end if;

        -------------------------------------
        --WAIT ACKNOWLEDGE
        -------------------------------------
        when S_WAIT_ACK =>

            i_scl <= '0';
            if i_scl_cnt < CI_HALF_BIT then
              i_scl_cnt <= i_scl_cnt + 1;
            else
              i_scl_cnt <= 0;
              i_sda <= 'Z';
              fsm_i2c_cs <= S_WAIT_ACK_2_HALF;
            end if;

        when S_WAIT_ACK_2_HALF =>

            if i_scl_cnt < CI_HALF_BIT then
              i_scl_cnt <= i_scl_cnt + 1;
            else
              i_scl_cnt <= 0;
              i_sda <= 'Z';
              fsm_i2c_cs <= S_WAIT_ACK_3_HALF;
            end if;

        when S_WAIT_ACK_3_HALF =>

            i_scl <= '1';
            if i_scl_cnt < CI_HALF_BIT then
              i_scl_cnt <= i_scl_cnt + 1;
            else
              i_scl_cnt <= 0;
              i_sda <= 'Z';
              i_rxack <= p_inout_sda;--to_x01( p_inout_sda );--
              fsm_i2c_cs <= S_WAIT_ACK_4_HALF;
            end if;

        when S_WAIT_ACK_4_HALF =>

            i_done <= '0';
            if i_scl_cnt < CI_HALF_BIT then
              i_scl_cnt <= i_scl_cnt + 1;
            else
              i_scl_cnt <= 0;
              i_sda <= 'Z';
              i_done <= '1';
              fsm_i2c_cs <= S_ACTIVE;
            end if;


        -------------------------------------
        --READ BYTE
        -------------------------------------
        when S_RD_WAIT_LOW =>

            i_scl <= '0';
            i_sda <= 'Z';
            if i_scl_cnt < CI_FULL_BIT then
              i_scl_cnt <= i_scl_cnt + 1;
            else
              i_scl_cnt <= 0;
              fsm_i2c_cs <= S_RD_WAIT_HALF;
            end if;

        when S_RD_WAIT_HALF =>

            i_scl <= '1';
            if i_scl_cnt < CI_HALF_BIT then
              i_scl_cnt <= i_scl_cnt + 1;
            else
              i_scl_cnt <= 0;
              i_rxd <= i_rxd( 6 downto 0 ) & to_x01( p_inout_sda );
              fsm_i2c_cs <= S_RD_READ;
            end if;

        when S_RD_READ =>

            i_scl <= '1';
            if i_scl_cnt < CI_HALF_BIT then
              i_scl_cnt <= i_scl_cnt + 1;
            else
              i_scl_cnt <= 0;
              if i_bit_cnt > 0 then
                i_bit_cnt <= i_bit_cnt - 1;
                i_scl <= '0';
                fsm_i2c_cs <= S_RD_WAIT_LOW;
              else
                i_txd <= (others=>'0');
                p_out_do <= i_rxd;
                fsm_i2c_cs <= S_RD_WAIT_ACK;
              end if;
            end if;

        -------------------------------------
        --SEND ACKNOWELEDGE
        -------------------------------------
        when S_RD_WAIT_ACK =>

            i_scl <= '0';
            if i_scl_cnt < CI_HALF_BIT then
              i_scl_cnt <= i_scl_cnt + 1;
            else
              i_scl_cnt <= 0;
              i_sda <= p_in_txack;
              fsm_i2c_cs <= S_RD_GET_ACK;
            end if;

        when S_RD_GET_ACK =>

            i_scl <= '0';
            if i_scl_cnt < CI_HALF_BIT then
              i_scl_cnt <= i_scl_cnt + 1;
            else
              i_scl_cnt <= 0;
              --i_rxack <= p_inout_sda;
              fsm_i2c_cs <= S_RD_WAIT_ACK_BIT;
            end if;

        when S_RD_WAIT_ACK_BIT =>

--            i_done <= '0';
            i_scl <= '1';
            if i_scl_cnt < CI_FULL_BIT then
              i_scl_cnt <= i_scl_cnt + 1;
              fsm_i2c_cs <= S_RD_WAIT_ACK_BIT;
            else
              i_scl_cnt <= 0;
              fsm_i2c_cs <= S_RD_WAIT_LAST_HALF;
            end if;

        when S_RD_WAIT_LAST_HALF =>

            i_scl <= '0';
            if i_scl_cnt < CI_HALF_BIT then
              i_scl_cnt <= i_scl_cnt + 1;
              fsm_i2c_cs <= S_RD_WAIT_LAST_HALF;
            else
              i_scl_cnt <= 0;
              i_sda <= 'Z';
              i_done <= '1';
              fsm_i2c_cs <= S_ACTIVE;
            end if;

        -------------------------------------
        --STOP
        -------------------------------------
        when S_STOP_1 =>

            i_scl <= '0';
            i_sda <= '0';
            if i_scl_cnt < CI_HALF_BIT then
              i_scl_cnt <= i_scl_cnt + 1;
            else
              i_scl_cnt <= 0;
              fsm_i2c_cs <= S_STOP;
            end if;

        when S_STOP =>

            i_scl <= '1';
--            i_sda <= '0';
            if i_scl_cnt < CI_HALF_BIT then
              i_scl_cnt <= i_scl_cnt + 1;
            else
              i_scl_cnt <= 0;
              i_sda <= '1';
              fsm_i2c_cs <= S_GAP;
            end if;

        when S_GAP =>

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
--        when S_RESTART =>
--
--            i_scl <= '0';
--            i_sda <= '1';
--            if i_scl_cnt < CI_FULL_BIT then
--              i_scl_cnt <= i_scl_cnt + 1;
--            else
--              i_scl_cnt <= 0;
--              i_sda <= '1';
--              i_done <= '0';
--              fsm_i2c_cs <= S_RESTART_CLK_HIGH;
--            end if;
--
--        when S_RESTART_CLK_HIGH =>
--
--            i_scl <= '1';
--            i_sda <= '1';
--            i_done <= '0';
--            if i_scl_cnt < CI_HALF_BIT then
--              i_scl_cnt <= i_scl_cnt + 1;
--            else
--              i_scl_cnt <= 0;
--              fsm_i2c_cs <= S_START;
--            end if;

        when S_RESTART =>

            if i_scl_cnt < CI_HALF_BIT then
              i_scl_cnt <= i_scl_cnt + 1;
            else
              i_scl_cnt <= 0;
              i_scl <= '0';
              i_sda <= '1';
              fsm_i2c_cs <= S_RESTART_1;
            end if;

        when S_RESTART_1 =>

            if i_scl_cnt < CI_HALF_BIT then
              i_scl_cnt <= i_scl_cnt + 1;
            else
              i_scl_cnt <= 0;
              i_scl <= '1';
              i_sda <= '1';
--              i_done <= '1';
              fsm_i2c_cs <= S_RESTART_2;
            end if;

        when S_RESTART_2 =>

--            i_done <= '0';
            if i_scl_cnt < CI_HALF_BIT then
              i_scl_cnt <= i_scl_cnt + 1;
            else
              i_scl_cnt <= 0;
              i_scl <= '1';
              i_sda <= '0';
              fsm_i2c_cs <= S_RESTART_CLK_HIGH;
            end if;

        when S_RESTART_CLK_HIGH =>

--            i_done <= '0';
            if i_scl_cnt < CI_HALF_BIT then
              i_scl_cnt <= i_scl_cnt + 1;
            else
              i_scl_cnt <= 0;
              i_scl <= '0';
              i_sda <= '0';
              i_done <= '1';
              fsm_i2c_cs <= S_ACTIVE;
            end if;


        when others => fsm_i2c_cs <= S_IDLE;
    end case;

  end if;
end process i2c_master;

--END MAIN
end behavioral;
