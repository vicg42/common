-------------------------------------------------------------------------
-- Company     : Linkos
-- Engineer    : Golovachenko Victor
--
-- Create Date : 25.11.2012 14:08:21
-- Module Name : prom_ld
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
use work.prom_phypin_pkg.all;

entity prom_ld is
generic(
G_HOST_DWIDTH : integer:=32
);
port(
-------------------------------
--HOST
-------------------------------
--host -> dev
p_in_htxbuf_di       : in   std_logic_vector(G_HOST_DWIDTH - 1 downto 0);
p_in_htxbuf_wr       : in   std_logic;
p_out_htxbuf_full    : out  std_logic;
p_out_htxbuf_empty   : out  std_logic;

--host <- dev
p_out_hrxbuf_do      : out  std_logic_vector(G_HOST_DWIDTH - 1 downto 0);
p_in_hrxbuf_rd       : in   std_logic;
p_out_hrxbuf_full    : out  std_logic;
p_out_hrxbuf_empty   : out  std_logic;

p_out_hirq           : out  std_logic;
p_out_herr           : out  std_logic;

p_in_hclk            : in   std_logic;

-------------------------------
--PHY
-------------------------------
p_in_phy         : in    TPromPhyIN;
p_out_phy        : out   TPromPhyOUT;
p_inout_phy      : inout TPromPhyINOUT;

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
end prom_ld;

architecture behavioral of prom_ld is

component prog_flash
generic(
G_DBG : string:="OFF";
G_USRBUF_DWIDTH : integer := 32;
G_FLASH_AWIDTH : integer := 24;
G_FLASH_DWIDTH : integer := 16;
G_FLASH_BUFSIZE_DEFAULT : integer := 32;
G_FLASH_OPT : std_logic_vector(7 downto 0) := (others=>'0')
);
port(
--
p_in_txbuf_d      : in    std_logic_vector(G_USRBUF_DWIDTH - 1 downto 0);
p_out_txbuf_rd    : out   std_logic;
p_in_txbuf_empty  : in    std_logic;

p_out_rxbuf_d     : out   std_logic_vector(G_USRBUF_DWIDTH - 1 downto 0);
p_out_rxbuf_wr    : out   std_logic;
p_in_rxbuf_full   : in    std_logic;

--
p_out_irq         : out   std_logic;
p_out_status      : out   std_logic_vector(7 downto 0);

--PHY
p_out_phy_a       : out   std_logic_vector(G_FLASH_AWIDTH - 1 downto 0);
p_in_phy_d        : in    std_logic_vector(G_FLASH_DWIDTH - 1 downto 0);
p_out_phy_d       : out   std_logic_vector(G_FLASH_DWIDTH - 1 downto 0);
p_out_phy_oe      : out   std_logic;
p_out_phy_we      : out   std_logic;
p_out_phy_cs      : out   std_logic;
p_in_phy_wait     : in    std_logic;

--Технологический
p_in_tst          : in    std_logic_vector(31 downto 0);
p_out_tst         : out   std_logic_vector(31 downto 0);

--System
p_in_clk_en       : in    std_logic;
p_in_clk          : in    std_logic;
p_in_rst          : in    std_logic
);
end component;

component prom_buf
port (
din    : in  std_logic_vector(G_HOST_DWIDTH - 1 downto 0);
wr_en  : in  std_logic;
wr_clk : in  std_logic;

dout   : out std_logic_vector(G_HOST_DWIDTH - 1 downto 0);
rd_en  : in  std_logic;
rd_clk : in  std_logic;

empty  : out std_logic;
full   : out std_logic;
prog_full : out std_logic;

--clk         : in std_logic;
rst    : in  std_logic
);
end component;

signal i_txbuf_do       : std_logic_vector(G_HOST_DWIDTH - 1 downto 0);
signal i_txbuf_rd       : std_logic;
signal i_txbuf_full     : std_logic;
signal i_txbuf_empty    : std_logic;
signal i_rxbuf_di       : std_logic_vector(G_HOST_DWIDTH - 1 downto 0);
signal i_rxbuf_wr       : std_logic;
signal i_rxbuf_full     : std_logic;
signal i_rxbuf_empty    : std_logic;

signal i_phy_di         : std_logic_vector(C_PROG_PHY_DWIDTH - 1 downto 0);
signal i_phy_do         : std_logic_vector(C_PROG_PHY_DWIDTH - 1 downto 0);
signal i_phy_oe_n       : std_logic;
signal i_core_rdy       : std_logic;
signal i_core_irq       : std_logic;
signal i_core_status    : std_logic_vector(7 downto 0);

signal i_divcnt         : std_logic_vector(3 downto 0):=(others=>'0');
signal i_clk_en         : std_logic:='0';
signal i_tst_out        : std_logic_vector(31 downto 0);

signal i_phy_oe_out     : std_logic;


--MAIN
begin

------------------------------------
--Технологические сигналы
------------------------------------
p_out_tst(31 downto 0) <= i_tst_out;


------------------------------------
--
------------------------------------
p_out_hirq <= i_core_irq;
p_out_herr <= OR_reduce(i_core_status);

p_out_hrxbuf_full  <= i_rxbuf_full;
p_out_hrxbuf_empty <= i_rxbuf_empty;

p_out_htxbuf_full  <= i_txbuf_full;
p_out_htxbuf_empty <= i_txbuf_empty;

--fpga -> flash
m_txbuf : prom_buf
port map(
din    => p_in_htxbuf_di,
wr_en  => p_in_htxbuf_wr,
wr_clk => p_in_hclk,

dout   => i_txbuf_do,
rd_en  => i_txbuf_rd,
rd_clk => p_in_clk,

empty  => i_txbuf_empty,
full   => open,
prog_full => i_txbuf_full,

--clk         => p_in_clk,
rst    => p_in_rst
);

--fpga <- flash
m_rxbuf : prom_buf
port map(
din    => i_rxbuf_di,
wr_en  => i_rxbuf_wr,
wr_clk => p_in_clk,

dout   => p_out_hrxbuf_do,
rd_en  => p_in_hrxbuf_rd,
rd_clk => p_in_hclk,

empty  => i_rxbuf_empty,
full   => open,
prog_full => i_rxbuf_full,

--clk         => p_in_clk,
rst    => p_in_rst
);


------------------------------------
--
------------------------------------
i_phy_oe_out <= not i_phy_oe_n;

p_out_phy.oe_n <= i_phy_oe_out;
p_inout_phy.d <= i_phy_do when i_phy_oe_out = '1' else (others => 'Z');
i_phy_di <= p_inout_phy.d;

m_core : prog_flash
generic map(
G_DBG => "OFF",
G_USRBUF_DWIDTH => G_HOST_DWIDTH,
G_FLASH_AWIDTH => C_PROG_PHY_AWIDTH,
G_FLASH_DWIDTH => C_PROG_PHY_DWIDTH,
G_FLASH_BUFSIZE_DEFAULT => C_PROG_PHY_BUFSIZE_DEFAULT,
G_FLASH_OPT => X"00"
)
port map(
p_in_txbuf_d      => i_txbuf_do,
p_out_txbuf_rd    => i_txbuf_rd,
p_in_txbuf_empty  => i_txbuf_empty,

p_out_rxbuf_d     => i_rxbuf_di,
p_out_rxbuf_wr    => i_rxbuf_wr,
p_in_rxbuf_full   => i_rxbuf_full,

--
p_out_irq         => i_core_irq,
p_out_status      => i_core_status,

--PHY
p_out_phy_a       => p_out_phy.a,
p_in_phy_d        => i_phy_di,
p_out_phy_d       => i_phy_do,
p_out_phy_oe      => i_phy_oe_n,
p_out_phy_we      => p_out_phy.we_n,
p_out_phy_cs      => p_out_phy.cs_n,
p_in_phy_wait     => p_in_phy.wt,

--Технологический
p_in_tst          => (others=>'0'),
p_out_tst         => i_tst_out,

--System
p_in_clk_en       => i_clk_en,
p_in_clk          => p_in_clk,
p_in_rst          => p_in_rst
);


process(p_in_clk)
begin
  if rising_edge(p_in_clk) then
    i_divcnt <= i_divcnt + 1;

    --p_in_clk=100MHz
    if i_divcnt = (i_divcnt'range => '1') then
    i_clk_en <= '1';
    else
    i_clk_en <= '0';
    end if;

  end if;
end process;


--END MAIN
end behavioral;

