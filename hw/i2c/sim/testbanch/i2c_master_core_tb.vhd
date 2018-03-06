-------------------------------------------------------------------------
-- Company     : Linkos
-- Engineer    : Golovachenko Victor
--
-- Create Date : 24.09.2012 10:57:24
-- Module Name : i2c_master_core_tb
--
-- Description :
--
-- Revision:
-- Revision 0.01 - File Created
--
-------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_misc.all;
use ieee.std_logic_unsigned.all;

use ieee.std_logic_textio.all;
use std.textio.all;

library work;
use work.vicg_common_pkg.all;

library unisim;
use unisim.vcomponents.all;

entity i2c_master_core_tb is
port(
p_out_dvi_clk : out   std_logic_vector(1 downto 0);
p_out_dvi_d   : out   std_logic_vector(11 downto 0);
p_out_dvi_hs  : out   std_logic;
p_out_dvi_vs  : out   std_logic
);
end i2c_master_core_tb;

architecture behavior of i2c_master_core_tb is

constant C_SYSCLK_PERIOD        : TIME := 5.0 ns; --200MHz

constant CI_I2C_ADRDEV          : integer:=16#06#;

--component i2c_slave_model
--port(
--sda : inout std_logic;
--scl : inout std_logic
--);
--end component;

component i2c_slave_v02
port(
Addres_device : in std_logic_vector(7 downto 0);

--------------------------------------------------
--I2C signals
--------------------------------------------------
sda : inout std_logic;
scl : in std_logic;

--------------------------------------------------
--I2C Status
--------------------------------------------------
addr_match: out std_logic;
i2c_header: out std_logic_vector(7 downto 0);

--------------------------------------------------
--Interface connection to Internal FPGA blocks
--------------------------------------------------
-- ExtI2C -> FPGA
en_dout: out std_logic;
dout   : out std_logic_vector(7 downto 0); -- data receive
-- FPGA -> ExtI2C
en_din : out std_logic;
din    : in std_logic_vector(7 downto 0); -- data to transmit

--------------------------------------------------
clk : in std_logic;
rst : in std_logic
);
end component;

component i2c_core_master
generic(
G_CLK_FREQ : natural := 25000000; --Определяет частоту для прота p_in_clk
G_BAUD     : natural := 100000;
G_DBG      : string := "OFF";
G_SIM      : string := "OFF"
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

--DBG
p_in_tst    : in    std_logic_vector(31 downto 0);
p_out_tst   : out   std_logic_vector(31 downto 0);

--System
p_in_clk    : in    std_logic;
p_in_rst    : in    std_logic
);
end component;

component ctrl_dvi7301
generic(
G_CLK_FREQ : natural := 25000000;
G_BAUD     : natural := 100000;
G_DBG      : string:="OFF";
G_SIM      : string:="OFF"
);
port(
p_in_mode   : in    std_logic_vector(2 downto 0);
p_out_err   : out   std_logic;

--VOUT
p_out_dvi_clk : out   std_logic_vector(1 downto 0);
p_out_dvi_d   : out   std_logic_vector(11 downto 0);
p_out_dvi_hs  : out   std_logic;
p_out_dvi_vs  : out   std_logic;

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
end component;
signal i_sys_clk             : std_logic;
signal i_sys_rst             : std_logic;

signal p_inout_sda           : std_logic;
signal p_inout_scl           : std_logic;

signal i_start               : std_logic;
signal i_stop                : std_logic;
signal i_cmd_wr              : std_logic;
signal i_cmd_rd              : std_logic;
signal i_txack               : std_logic;
signal i_rxack               : std_logic;
signal i_done                : std_logic;

signal i_txd                 : std_logic_vector(7 downto 0);
signal i_rxd                 : std_logic_vector(7 downto 0);
signal i_i2c_adev            : std_logic_vector(7 downto 0);


--MAIN
begin

gen_clk : process
begin
  i_sys_clk<='0';
  wait for C_SYSCLK_PERIOD/2;
  i_sys_clk<='1';
  wait for C_SYSCLK_PERIOD/2;
end process;

i_sys_rst<='1','0' after 1 us;


m_i2c_core : i2c_core_master
generic map(
G_CLK_FREQ => 25000000,
G_BAUD     => 100000,
G_DBG => "OFF",
G_SIM => "OFF"
)
port map(
p_in_cmd    => i_cmd_wr,
--p_in_cmd_rd => i_cmd_rd,
p_in_start  => i_start,
p_out_done  => i_done,
p_in_txack  => i_txack,
p_out_rxack => i_rxack,

p_in_txd    => i_txd,
p_out_rxd   => i_rxd,

--I2C
p_inout_sda => p_inout_sda,
p_inout_scl => p_inout_scl,

--DBG
p_in_tst    => (others => '0'),
p_out_tst   => open,

--System
p_in_clk    => i_sys_clk,
p_in_rst    => i_sys_rst
);

--m_dvi7301 : ctrl_dvi7301
--generic map(
--G_CLK_FREQ => 25000000,
--G_BAUD     => 100000,
--G_DBG      => "OFF",
--G_SIM      => "ON"
--)
--port map(
--p_in_mode   => "000",
--p_out_err   => open,
--
----VOUT
--p_out_dvi_clk => p_out_dvi_clk,
--p_out_dvi_d   => p_out_dvi_d  ,
--p_out_dvi_hs  => p_out_dvi_hs ,
--p_out_dvi_vs  => p_out_dvi_vs ,
--
----I2C
--p_inout_sda => p_inout_sda,
--p_inout_scl => p_inout_scl,
--
----Технологический
--p_in_tst    => (others=>'0'),
--p_out_tst   => open,
--
----System
--p_in_clk    => i_sys_clk,
--p_in_rst    => i_sys_rst
--);


--m_i2c_slave : i2c_slave_model
--port map(
--sda => p_inout_sda,
--scl => p_out_scl
--);

m_i2c_slave : i2c_slave_v02
port map(
Addres_device => "10011010",--"11101100",

--------------------------------------------------
--I2C signals
--------------------------------------------------
sda => p_inout_sda,
scl => p_inout_scl,

--------------------------------------------------
--I2C Status
--------------------------------------------------
addr_match => open,
i2c_header => open,

--------------------------------------------------
--Interface connection to Internal FPGA blocks
--------------------------------------------------
-- ExtI2C -> FPGA
en_dout => open,
dout    => open,
-- FPGA -> ExtI2C
en_din => open,
din    => "11110000",

--------------------------------------------------
clk    => i_sys_clk,
rst    => i_sys_rst
);

m_pullup_sda : PULLUP port map(O => p_inout_sda);
m_pullup_scl : PULLUP port map(O => p_inout_scl);

--//########################################
--//Main Ctrl
--//########################################

process
variable string_value : std_logic_vector(3 downto 0);
variable GUI_line  : LINE;--Строка для вывода в ModelSim
begin

  i_start <= '0';
  i_stop <= '0';
  i_cmd_wr <= '0';
  i_cmd_rd <= '0';
  i_txack <= '0';
  i_txd <= (others=>'0');

  wait until i_sys_rst = '0';--i_sys_clk'event and i_sys_rst = '1' and

  wait for 1 us;

  ------------------------------
  --I2C - WRITE
  ------------------------------
  --START + WRITE ADEV
  wait until i_sys_clk'event and i_sys_clk = '1';

  i_start <= '1';
  i_stop <= '0';
  i_cmd_wr <= '1';
  i_cmd_rd <= '0';
  i_txack <= '0';
  i_txd(7 downto 1) <= "0000110";
  i_txd(0) <= '0';

  --WRITE DATA
  wait until i_sys_clk'event and i_sys_clk = '1' and i_done='1' and i_rxack='0';

  i_start <= '0';
  i_stop <= '0';
  i_cmd_wr <= '1';
  i_cmd_rd <= '0';
  i_txack <= '0';
  i_txd <= CONV_STD_LOGIC_VECTOR(16#AA#, i_txd'length);

  --STOP
  wait until i_sys_clk'event and i_sys_clk = '1' and i_done='1' and i_rxack='0';

  i_start <= '0';
  i_stop <= '1';
  i_cmd_wr <= '0';
  i_cmd_rd <= '0';
  i_txack <= '0';
  i_txd <= CONV_STD_LOGIC_VECTOR(16#00#, i_txd'length);

  wait until i_sys_clk'event and i_sys_clk = '1' and i_done='1';

  wait for 1 us;

  ------------------------------
  --I2C - READ
  ------------------------------
  wait until i_sys_clk'event and i_sys_clk = '1';
  --START + WRITE ADEV
  i_start <= '1';
  i_stop <= '0';
  i_cmd_wr <= '1';
  i_cmd_rd <= '0';
  i_txack <= '0';
  i_txd(7 downto 1) <= "0000110";
  i_txd(0) <= '1';

  wait until i_sys_clk'event and i_sys_clk = '1' and i_done='1';
  --READ
  i_start <= '0';
  i_stop <= '0';
  i_cmd_wr <= '0';
  i_cmd_rd <= '1';
  i_txack <= '0';
  i_txd(7 downto 1) <= "0000110";
  i_txd(0) <= '1';

  wait until i_sys_clk'event and i_sys_clk = '1' and i_done='1';
  --SEND ASK
  i_start <= '0';
  i_stop <= '0';
  i_cmd_wr <= '0';
  i_cmd_rd <= '0';
  i_txack <= '0';
  i_txd <= CONV_STD_LOGIC_VECTOR(16#00#, i_txd'length);

  wait until i_sys_clk'event and i_sys_clk = '1' and i_done='1';
  --STOP
  i_start <= '0';
  i_stop <= '1';
  i_cmd_wr <= '0';
  i_cmd_rd <= '0';
  i_txack <= '0';
  i_txd <= CONV_STD_LOGIC_VECTOR(16#00#, i_txd'length);

  wait;
end process;
--write(GUI_line,string'("SEND ADRDEV: RXACK - BAD!!!"));writeline(output, GUI_line);


--END MAIN
end;



