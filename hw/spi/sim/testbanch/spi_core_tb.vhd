library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.reduce_pack.all;
use work.spi_pkg.all;

entity spi_core_tb is
port(
pin_out_spi    : out TSPI_pinout;
pin_out_tp     : out std_logic_vector(1 downto 0)
);
end spi_core_tb;

architecture test of spi_core_tb is

component spi_core is
generic(
G_AWIDTH : integer := 16;
G_DWIDTH : integer := 16
);
port(
p_in_adr    : in   std_logic_vector(G_AWIDTH - 1 downto 0);
p_in_data   : in   std_logic_vector(G_DWIDTH - 1 downto 0); --FPGA -> DEV
p_out_data  : out  std_logic_vector(G_DWIDTH - 1 downto 0); --FPGA <- DEV
p_in_dir    : in   std_logic;
p_in_start  : in   std_logic;

p_out_busy  : out  std_logic;

p_out_physpi : out TSPI_pinout;
p_in_physpi  : in  TSPI_pinin;

p_out_tst    : out std_logic_vector(31 downto 0);
p_in_tst     : in  std_logic_vector(31 downto 0);

p_in_clk_en : in   std_logic;
p_in_clk    : in   std_logic;
p_in_rst    : in   std_logic
);
end component;

constant CI_CLK_PERIOD         : time := 10 ns; -- 100 MHz clk

signal i_spi_in  : TSPI_pinin;
signal i_spi_out : TSPI_pinout;

signal i_clk    : std_logic:='0';
signal i_rst    : std_logic:='0';
signal i_busy   : std_logic;
signal i_adr    : std_logic_vector(15 downto 0);
signal i_txd    : std_logic_vector(15 downto 0);
signal i_rxd    : std_logic_vector(15 downto 0);
signal i_start  : std_logic := '0';
signal i_dir    : std_logic := '0';

signal i_cntclk : unsigned(1 downto 0) := (others => '0');
signal i_clk_en : std_logic := '0';

signal i_tst_out: std_logic_vector(31 downto 0);
signal sr_dev_data : std_logic_vector(15 downto 0) := (others => '0');

begin


process begin
  wait for (CI_CLK_PERIOD/2);
  i_clk <= not i_clk;
end process;

process(i_clk)
begin
  if rising_edge(i_clk) then
    i_cntclk <= i_cntclk + 1;

  end if;
end process;

i_clk_en <= i_cntclk(0);

m_core : spi_core
generic map(
G_AWIDTH => 16,
G_DWIDTH => 16
)
port map(
p_in_adr    => i_adr,
p_in_data   => i_txd, --FPGA -> DEV
p_out_data  => i_rxd, --FPGA <- DEV
p_in_dir    => i_dir,
p_in_start  => i_start,

p_out_busy  => i_busy,

p_out_physpi => i_spi_out,
p_in_physpi  => i_spi_in,

p_out_tst   => i_tst_out,
p_in_tst    => (others => '0'),

p_in_clk_en => i_clk_en,
p_in_clk    => i_clk,
p_in_rst    => '0' --i_rst
);


i_rst <= '1', '0' after 1 us;

pin_out_tp(0) <= OR_reduce(i_rxd);
pin_out_tp(1) <= i_dir or i_start or i_busy;


process
begin
i_adr <= std_logic_vector(TO_UNSIGNED(16#1F5#, i_adr'length));
i_txd <= std_logic_vector(TO_UNSIGNED(16#F755#, i_txd'length));
i_start <= '0';
i_spi_in.miso <= 'Z';
i_dir <= C_SPI_WRITE;


wait for 2 us;

wait until rising_edge(i_clk) and i_clk_en = '1';
i_start <= '1';

wait until rising_edge(i_clk) and i_clk_en = '1';
i_start <= '0';

wait for 50 ns;

wait until i_busy = '0';

wait until rising_edge(i_clk) and i_clk_en = '1';
i_dir <= C_SPI_READ;
i_start <= '1';

wait until rising_edge(i_clk) and i_clk_en = '1';
i_start <= '0';

--------------
wait until rising_edge(i_spi_out.sck) and i_tst_out(0) = '1';
i_spi_in.miso <= '1';

wait until rising_edge(i_spi_out.sck) and i_tst_out(0) = '1';
i_spi_in.miso <= '0';

wait until rising_edge(i_spi_out.sck) and i_tst_out(0) = '1';
i_spi_in.miso <= '1';

wait until rising_edge(i_spi_out.sck) and i_tst_out(0) = '1';
i_spi_in.miso <= '0';

--------------
wait until rising_edge(i_spi_out.sck) and i_tst_out(0) = '1';
i_spi_in.miso <= '1';

wait until rising_edge(i_spi_out.sck) and i_tst_out(0) = '1';
i_spi_in.miso <= '1';

wait until rising_edge(i_spi_out.sck) and i_tst_out(0) = '1';
i_spi_in.miso <= '1';

wait until rising_edge(i_spi_out.sck) and i_tst_out(0) = '1';
i_spi_in.miso <= '1';

--------------
wait until rising_edge(i_spi_out.sck) and i_tst_out(0) = '1';
i_spi_in.miso <= '0';

wait until rising_edge(i_spi_out.sck) and i_tst_out(0) = '1';
i_spi_in.miso <= '1';

wait until rising_edge(i_spi_out.sck) and i_tst_out(0) = '1';
i_spi_in.miso <= '0';

wait until rising_edge(i_spi_out.sck) and i_tst_out(0) = '1';
i_spi_in.miso <= '1';

--------------
wait until rising_edge(i_spi_out.sck) and i_tst_out(0) = '1';
i_spi_in.miso <= '0';

wait until rising_edge(i_spi_out.sck) and i_tst_out(0) = '1';
i_spi_in.miso <= '1';

wait until rising_edge(i_spi_out.sck) and i_tst_out(0) = '1';
i_spi_in.miso <= '0';

wait until rising_edge(i_spi_out.sck) and i_tst_out(0) = '1';
i_spi_in.miso <= '1';

wait;

end process;


--process(i_spi_out.sck)
--begin
--  if rising_edge(i_spi_out.sck) then
--    if i_dir = C_SPI_READ then
--      sr_dev_data <= std_logic_vector(TO_UNSIGNED(16#8855#, sr_dev_data'length));
--    else
----      if i_tst_out(0) = '1' then
--        sr_dev_data <= sr_dev_data(14 downto 0) & '0';
----      end if;
--    end if;
--  end if;
--end process;
--
--i_spi_in.miso <= sr_dev_data(15) when i_tst_out(0) = '1' else 'Z';
pin_out_spi <= i_spi_out;

end test;

