-------------------------------------------------------------------------
-- Company     : Linkos
-- Engineer    : Golovachenko Victor
--
-- Create Date : 01.11.2012 16:48:24
-- Module Name : pult
--
-- Назначение/Описание :
--
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

library work;
use work.vicg_common_pkg.all;

entity pult is
generic(
G_MODULE_USE : string:="ON";
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

p_out_host_irq    : out  std_logic;                      --//прерывание
p_in_host_clk     : in   std_logic;

--------------------------------------
--PHY
--------------------------------------
p_in_phy_rx       : in   std_logic;
p_out_phy_tx      : out  std_logic;
p_out_phy_dir     : out  std_logic;

--------------------------------------
--System
--------------------------------------
p_in_clk          : in   std_logic; --128MHz
p_in_rst          : in   std_logic
);
end pult;

architecture behavioral of pult is

component pult_io
port(
trans_ack      : in  std_logic;

data_i         : in  std_logic;
data_o         : out std_logic;
dir_485        : out std_logic;

host_clk_wr    : in  std_logic;
wr_en          : in  std_logic;
data_from_host : in  std_logic_vector(31 downto 0);

host_clk_rd    : in  std_logic;
rd_en          : in  std_logic;
data_to_host   : out std_logic_vector(31 downto 0);

busy           : out std_logic;
ready          : out std_logic;

tmr_en         : in  std_logic;
tmr_stb        : in  std_logic;
clk_io_en      : in  std_logic;
clk_io         : in  std_logic;--нужно (4х битовой частоты обмена)
rst            : in  std_logic
);
end component;

signal i_clk4M_en         : std_logic:='0';
signal i_busy             : std_logic;
signal i_rdy              : std_logic;
signal i_tmr_en           : std_logic;
signal i_tmr_stb          : std_logic;
signal i_cnt_dev          : std_logic_vector(6 downto 0):=(others=>'0');


--MAIN
begin

gen_use_on : if strcmp(G_MODULE_USE,"ON") generate

m_core : pult_io
port map(
trans_ack      => '1',--input

data_i         => p_in_phy_rx,
data_o         => p_out_phy_tx,
dir_485        => p_out_phy_dir,

host_clk_wr    => p_in_host_clk ,
wr_en          => p_in_host_wr  ,
data_from_host => p_in_host_txd ,

host_clk_rd    => p_in_host_clk ,
rd_en          => p_in_host_rd  ,
data_to_host   => p_out_host_rxd,

busy           => i_busy,
ready          => i_rdy,

tmr_en         => i_tmr_en,
tmr_stb        => i_tmr_stb,
clk_io_en      => i_clk4M_en,--4MHz
clk_io         => p_in_clk,--128MHz
rst            => p_in_rst
);

p_out_host_txrdy <= not i_busy;
p_out_host_rxrdy <= i_rdy;

p_out_host_irq <= i_rdy;

process(p_in_clk)
begin
  if p_in_clk'event and p_in_clk='1' then
    i_cnt_dev <= i_cnt_dev + 1;

    if i_cnt_dev=CONV_STD_LOGIC_VECTOR(16#10#, i_cnt_dev'length) then
      i_clk4M_en <= '1';
    else
      i_clk4M_en <= '0';
    end if;
  end if;
end process;

process(p_in_host_clk)
begin
  if p_in_host_clk'event and p_in_host_clk='1' then
    i_tmr_en <=p_in_tmr_en ;
    i_tmr_stb<=p_in_tmr_stb;
  end if;
end process;

end generate gen_use_on;


--END MAIN
end behavioral;
