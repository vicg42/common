-------------------------------------------------------------------------
-- Company     : Linkos
-- Engineer    : Golovachenko Victor
--
-- Create Date : 14.07.2011 11:49:04
-- Module Name : cfgdev_uart
--
-------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.vicg_common_pkg.all;
use work.cfgdev_pkg.all;

entity cfgdev_uart is
generic(
G_DBG : string:="OFF";
G_BAUDCNT_VAL: integer:=64
);
port(
-------------------------------
--Связь с UART
-------------------------------
p_out_uart_tx        : out    std_logic;
p_in_uart_rx         : in     std_logic;
p_in_uart_refclk     : in     std_logic;
p_out_err            : out    std_logic;

-------------------------------
--FPGA DEV
-------------------------------
p_out_cfg_dadr       : out    std_logic_vector(C_CFGPKT_DADR_M_BIT - C_CFGPKT_DADR_L_BIT downto 0); --Адрес модуля
p_out_cfg_radr       : out    std_logic_vector(C_CFGPKT_RADR_M_BIT - C_CFGPKT_RADR_L_BIT downto 0); --Адрес стартового регистра
p_out_cfg_radr_ld    : out    std_logic;                    --Загрузка адреса регистра
p_out_cfg_radr_fifo  : out    std_logic;                    --Тип адресации:1-FIFO(инкрементация адреса запрещена/0-Register(инкрементация адреса разрешена)
p_out_cfg_wr         : out    std_logic;                    --Строб записи
p_out_cfg_rd         : out    std_logic;                    --Строб чтения
p_out_cfg_txdata     : out    std_logic_vector(15 downto 0);
p_in_cfg_rxdata      : in     std_logic_vector(15 downto 0);
p_in_cfg_txrdy       : in     std_logic;                    --1 - rdy to used
p_in_cfg_rxrdy       : in     std_logic;                    --1 - rdy to used
p_out_cfg_done       : out    std_logic;                    --операция завершена
--p_in_cfg_irq         : in     std_logic;
p_in_cfg_clk         : in     std_logic;

-------------------------------
--DBG
-------------------------------
p_in_tst             : in     std_logic_vector(31 downto 0);
p_out_tst            : out    std_logic_vector(31 downto 0);

-------------------------------
--System
-------------------------------
p_in_rst             : in     std_logic
);
end entity cfgdev_uart;

architecture behavioral of cfgdev_uart is

component uart_rev01 is
generic(
G_BAUDCNT_VAL: integer:=64
);
port(
-------------------------------
--UART
-------------------------------
p_out_uart_tx    : out   std_logic;
p_in_uart_rx     : in    std_logic;

-------------------------------
--USR IF
-------------------------------
p_out_usr_rxd    : out   std_logic_vector(7 downto 0);
p_out_usr_rxrdy  : out   std_logic;
p_in_usr_rd      : in    std_logic;

p_in_usr_txd     : in    std_logic_vector(7 downto 0);
p_out_usr_txrdy  : out   std_logic;
p_in_usr_wr      : in    std_logic;

-------------------------------
--DBG
-------------------------------
p_in_tst         : in    std_logic_vector(31 downto 0);
p_out_tst        : out   std_logic_vector(31 downto 0);

-------------------------------
--System
-------------------------------
p_in_clk         : in    std_logic;
p_in_rst         : in    std_logic
);
end component;


signal tst_core_out     : std_logic_vector(31 downto 0);
signal tst_uart_out     : std_logic_vector(31 downto 0);


begin --architecture behavioral

--############################
--DBG
--############################
gen_dbg_off : if strcmp(G_DBG,"OFF") generate
p_out_tst(31 downto 0) <= (others=>'0');
end generate gen_dbg_off;

gen_dbg_on : if strcmp(G_DBG,"ON") generate
process(p_in_rst, p_in_cfg_clk)
begin
if rising_edge(p_in_cfg_clk) then
  if p_in_rst = '1' then
    p_out_tst <= (others => '0');
  else
    p_out_tst(0) <= tst_core_out(0) or tst_uart_out(0);
    p_out_tst(5) <= tst_uart_out(0);
  end if;
end if;
end process;

p_out_tst(31 downto 6) <= (others => '0');

end generate gen_dbg_on;


p_out_err <= '0';


--############################
--
--############################
m_uart: uart_rev01
generic map(
G_BAUDCNT_VAL => G_BAUDCNT_VAL
)
port map(
-------------------------------
--UART
-------------------------------
p_out_uart_tx    => p_out_uart_tx,
p_in_uart_rx     => p_in_uart_rx,

-------------------------------
--USR IF
-------------------------------
p_out_usr_rxd    => i_htxbuf_di,
p_out_usr_rxrdy  => i_htxbuf_drdy,
p_in_usr_rd      => i_htxbuf_rd,

p_in_usr_txd     => i_hrxbuf_do,
p_out_usr_txrdy  => i_hrxbuf_drdy,
p_in_usr_wr      => i_hrxbuf_wr,

-------------------------------
--DBG
-------------------------------
p_in_tst         => "00000000000000000000000000000000",
p_out_tst        => tst_uart_out,

-------------------------------
--System
-------------------------------
p_in_clk         => p_in_uart_refclk,
p_in_rst         => p_in_rst
);

process(p_in_uart_refclk)
begin
if rising_edge(p_in_uart_refclk) then
  i_htxbuf_rd <= i_htxbuf_drdy;
  i_hrxbuf_wr <= not i_hrxbuf_empty and i_hrxbuf_drdy;
end if;
end process;


m_cfgcore : cfgdev_host
generic map(
G_DBG => G_DBG,
G_HOST_DWIDTH => 8
)
port map(
-------------------------------
--HOST
-------------------------------
--host -> dev
p_in_htxbuf_di       => i_htxbuf_di   ,
p_in_htxbuf_wr       => i_htxbuf_rd   ,
p_out_htxbuf_full    => open,--i_htxbuf_full ,
p_out_htxbuf_empty   => open,--i_htxbuf_empty,

--host <- dev
p_out_hrxbuf_do      => i_hrxbuf_do   ,
p_in_hrxbuf_rd       => i_hrxbuf_wr   ,
p_out_hrxbuf_full    => open,--i_hrxbuf_full ,
p_out_hrxbuf_empty   => i_hrxbuf_empty,

p_out_hirq           => open,
p_out_herr           => open,

p_in_hclk            => p_in_uart_refclk,

-------------------------------
--FPGA DEV
-------------------------------
p_out_cfg_dadr       => p_out_cfg_dadr     ,
p_out_cfg_radr       => p_out_cfg_radr     ,
p_out_cfg_radr_ld    => p_out_cfg_radr_ld  ,
p_out_cfg_radr_fifo  => p_out_cfg_radr_fifo,
p_out_cfg_wr         => p_out_cfg_wr       ,
p_out_cfg_rd         => p_out_cfg_rd       ,
p_out_cfg_txdata     => p_out_cfg_txdata   ,
p_in_cfg_rxdata      => p_in_cfg_rxdata    ,
p_in_cfg_txrdy       => p_in_cfg_txrdy     ,
p_in_cfg_rxrdy       => p_in_cfg_rxrdy     ,
p_out_cfg_done       => p_out_cfg_done     ,
--p_in_cfg_irq         : in     std_logic;
p_in_cfg_clk         => p_in_cfg_clk       ,

-------------------------------
--DBG
-------------------------------
p_in_tst             => p_in_tst,
p_out_tst            => tst_core_out,

-------------------------------
--System
-------------------------------
p_in_rst             => p_in_rst
);


end architecture behavioral;

