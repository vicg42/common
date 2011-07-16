-------------------------------------------------------------------------
-- Company     : Linkos
-- Engineer    : Golovachenko Victor
--
-- Create Date : 15.07.2011 11:07:25
-- Module Name : uart_rev01
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

library unisim;
use unisim.vcomponents.all;

entity uart_rev01 is
generic(
G_BAUDCNT_VAL: integer:=64 --//G_BAUDCNT_VAL = Fuart_refclk/(16 * UART_BAUDRATE)
                           --//Например: FFuart_refclk=40MHz, UART_BAUDRATE=115200
                           --//
                           --// 40000000/(16 *115200)=21,701 - округляем до ближайшего цеого, т.е = 22
);
port
(
-------------------------------
--Связь с UART
-------------------------------
p_out_uart_tx    : out    std_logic;                    --//
p_in_uart_rx     : in     std_logic;                    --//

-------------------------------
--USR IF
-------------------------------
p_out_usr_rxd    : out    std_logic_vector(7 downto 0); --//RXD
p_out_usr_rxrdy  : out    std_logic;                    --//1/0 - rdy/not
p_in_usr_rd      : in     std_logic;                    --//read

p_in_usr_txd     : in     std_logic_vector(7 downto 0); --//TXD
p_out_usr_txrdy  : out    std_logic;                    --//1/0 - rdy/not
p_in_usr_wr      : in     std_logic;                    --//write

-------------------------------
--Технологический
-------------------------------
p_in_tst         : in    std_logic_vector(31 downto 0);
p_out_tst        : out   std_logic_vector(31 downto 0);

-------------------------------
--System
-------------------------------
p_in_clk         : in    std_logic;
p_in_rst         : in    std_logic
);
end uart_rev01;

architecture behavioral of uart_rev01 is

component uart_rx is
    port (            serial_in : in std_logic;
                       data_out : out std_logic_vector(7 downto 0);
                    read_buffer : in std_logic;
                   reset_buffer : in std_logic;
                   en_16_x_baud : in std_logic;
            buffer_data_present : out std_logic;
                    buffer_full : out std_logic;
               buffer_half_full : out std_logic;
                            clk : in std_logic);
    end component;

component uart_tx is
    Port (            data_in : in std_logic_vector(7 downto 0);
                 write_buffer : in std_logic;
                 reset_buffer : in std_logic;
                 en_16_x_baud : in std_logic;
                   serial_out : out std_logic;
                  buffer_full : out std_logic;
             buffer_half_full : out std_logic;
                          clk : in std_logic);
    end component;

signal i_en_16_x_baud         : std_logic;
signal i_baud_cnt             : integer range 0 to G_BAUDCNT_VAL-1 :=0;

signal i_txbuf_full           : std_logic;
signal i_txbuf_hfull          : std_logic;
signal i_txbuf_hfull_dly      : std_logic;



--MAIN
begin

--//----------------------------------
--//Технологические сигналы
--//----------------------------------
p_out_tst(31 downto 0)<=(others=>'0');
--process(p_in_rst,p_in_clk)
--begin
--  if p_in_rst='1' then
--    p_out_tst(0)<='0';
--    i_txbuf_hfull_dly<='0';
--
--  elsif p_in_clk'event and p_in_clk='1' then
--
--    i_txbuf_hfull_dly<=i_txbuf_hfull;
--    p_out_tst(0)<=i_txbuf_hfull_dly;
--
--  end if;
--end process;
--p_out_tst(31 downto 1)<=(others=>'0');


--------------------------------------------------
--
--------------------------------------------------
process(p_in_clk)
begin
  if p_in_clk'event and p_in_clk='1' then
    if i_baud_cnt=G_BAUDCNT_VAL-1 then
      i_en_16_x_baud<='1';
      i_baud_cnt<=0;
    else
      i_en_16_x_baud<='0';
      i_baud_cnt<=i_baud_cnt + 1;
    end if;
  end if;
end process;


m_rx : uart_rx
port map(
serial_in           => p_in_uart_rx,

data_out            => p_out_usr_rxd,
read_buffer         => p_in_usr_rd,
buffer_data_present => p_out_usr_rxrdy,
buffer_full         => open,
buffer_half_full    => open,

en_16_x_baud        => i_en_16_x_baud,
clk                 => p_in_clk,
reset_buffer        => p_in_rst
);

m_tx : uart_tx
port map(
serial_out       => p_out_uart_tx,

data_in          => p_in_usr_txd,
write_buffer     => p_in_usr_wr,
buffer_full      => open,--i_txbuf_full,--
buffer_half_full => i_txbuf_hfull,

en_16_x_baud     => i_en_16_x_baud,
clk              => p_in_clk,
reset_buffer     => p_in_rst
);

p_out_usr_txrdy<=not i_txbuf_hfull;

--END MAIN
end behavioral;
