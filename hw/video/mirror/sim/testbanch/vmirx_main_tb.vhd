-------------------------------------------------------------------------
-- Company     : Linkos
-- Engineer    : Golovachenko Victor
--
-- Create Date : 25.11.2008 18:38
-- Module Name : vscaler_main_tb
--
-- Назначение/Описание :
--    Проверка работы
--
-- Revision:
-- Revision 0.01 - File Created
--
-------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.vicg_common_pkg.all;

entity vmirx_main_tb is
generic(
G_VFR_PIX_COUNT : integer := 16;
G_VFR_LINE_COUNT : integer := 3;
G_MIRX : std_logic := '0';
G_BRAM_SIZE_BYTE : integer := 8192;
G_DI_WIDTH : integer := 32;
G_DO_WIDTH : integer := 8
);
port(
p_out_cfg_mirx_done : out   std_logic;
p_out_dwnp_data     : out   std_logic_vector(G_DO_WIDTH - 1 downto 0);
p_out_dwnp_wr       : out   std_logic;
p_out_dwnp_eol      : out   std_logic;
p_out_dwnp_eof      : out   std_logic
);
end entity vmirx_main_tb;

architecture behavior of vmirx_main_tb is

constant i_clk_period : TIME := 6.6 ns; --150MHz

component vmirx_main
generic(
G_BRAM_SIZE_BYTE : integer := 8;
G_DI_WIDTH : integer := 8;
G_DO_WIDTH : integer := 8
);
port(
-------------------------------
--CFG
-------------------------------
p_in_cfg_mirx       : in    std_logic;                    --1/0 - mirx ON/OFF
p_in_cfg_pix_count  : in    std_logic_vector(15 downto 0);--Count byte

p_out_cfg_mirx_done : out   std_logic;

----------------------------
--Upstream Port (IN)
----------------------------
--p_in_upp_clk        : in    std_logic;
p_in_upp_data       : in    std_logic_vector(G_DI_WIDTH - 1 downto 0);
p_in_upp_wr         : in    std_logic;
p_out_upp_rdy_n     : out   std_logic;

----------------------------
--Downstream Port (OUT)
----------------------------
--p_in_dwnp_clk       : in    std_logic;
p_out_dwnp_data     : out   std_logic_vector(G_DO_WIDTH - 1 downto 0);
p_out_dwnp_wr       : out   std_logic;
p_in_dwnp_rdy_n     : in    std_logic;
p_out_dwnp_eol      : out   std_logic;
p_out_dwnp_eof      : out   std_logic;

-------------------------------
--DBG
-------------------------------
p_in_tst            : in    std_logic_vector(31 downto 0);
p_out_tst           : out   std_logic_vector(31 downto 0);

-------------------------------
--System
-------------------------------
p_in_clk            : in    std_logic;
p_in_rst            : in    std_logic
);
end component vmirx_main;

--component vmirx_fifo
--port (
--din        : IN  std_logic_VECTOR(31 downto 0);
--wr_en      : IN  std_logic;
--
--dout       : OUT std_logic_VECTOR(31 downto 0);
--rd_en      : IN  std_logic;
--
--empty      : OUT std_logic;
--full       : OUT std_logic;
--almost_full: OUT std_logic;
--
--clk        : IN  std_logic;
--rst        : IN  std_logic
--);
--end component vmirx_fifo;

signal i_clk                : std_logic := '0';
signal i_rst                : std_logic := '0';

signal i_vfr_start          : std_logic := '0';
signal i_vfr_busy           : std_logic := '0';
signal i_cntpix             : unsigned(7 downto 0) := (others => '0');
signal i_cntline            : unsigned(7 downto 0) := (others => '0');

signal i_di                 : unsigned(G_DI_WIDTH - 1 downto 0) := (others => '0');
signal i_di_wr              : std_logic := '0';
signal i_di_eof             : std_logic := '0';
signal i_di_rdy_n           : std_logic;

signal i_do_rdy_n           : std_logic;


begin --architecture behavior

i_rst<='1','0' after 1 us;

clkgen : process
begin
  i_clk<='0';
  wait for i_clk_period/2;
  i_clk<='1';
  wait for i_clk_period/2;
end process clkgen;

m_vmirx: vmirx_main
generic map(
G_BRAM_SIZE_BYTE => G_BRAM_SIZE_BYTE,
G_DI_WIDTH => G_DI_WIDTH,
G_DO_WIDTH => G_DO_WIDTH
)
port map
(
-------------------------------
-- Управление
-------------------------------
p_in_cfg_mirx       => G_MIRX,
p_in_cfg_pix_count  => std_logic_vector(TO_UNSIGNED(G_VFR_PIX_COUNT ,16)),

p_out_cfg_mirx_done => p_out_cfg_mirx_done,

----------------------------
--Upstream Port (входные данные)
----------------------------
--p_in_upp_clk        : in    std_logic;
p_in_upp_data       => std_logic_vector(i_di),
p_in_upp_wr         => i_di_wr,
p_out_upp_rdy_n     => i_di_rdy_n,

----------------------------
--Downstream Port (результат)
----------------------------
--p_in_dwnp_clk       : in    std_logic;
p_out_dwnp_data     => p_out_dwnp_data,
p_out_dwnp_wr       => p_out_dwnp_wr  ,
p_in_dwnp_rdy_n     => i_do_rdy_n,
p_out_dwnp_eol      => p_out_dwnp_eol,
p_out_dwnp_eof      => p_out_dwnp_eof,

-------------------------------
--Технологический
-------------------------------
p_in_tst            => (others => '0'),
p_out_tst           => open,

-------------------------------
--System
-------------------------------
p_in_clk            => i_clk,
p_in_rst            => i_rst
);

--m_fifo_result : vmirx_fifo
--port map
--(
--din         => p_out_dwnp_data,
--wr_en       => p_out_dwnp_wr,
----wr_clk      => p_in_upp_clk,
--
--dout        => i_fifo_result_dout,
--rd_en       => i_fifo_result_rd,
----rd_clk      => p_in_dwnp_clk,
--
--empty       => i_fifo_result_empty,
--full        => open,
--almost_full => i_fifo_result_full,
--
--clk         => p_in_clk,
--rst         => p_in_rst
--);


--Генератор тестовых данных
process(i_rst, i_clk)
variable di_eof : std_logic;
begin
  if i_rst = '1' then
    i_vfr_busy <= '0';

    i_cntpix <= (others => '0');
    i_cntline <= (others => '0');

    i_di <= TO_UNSIGNED(16#04030201# ,i_di'length);
    i_di_wr <= '0';
    i_di_eof <= '0';
    i_di_eof <= '0';

  elsif rising_edge(i_clk) then

  if i_vfr_start = '1' then
    i_vfr_busy <= '1';
    i_di_wr <= '1';

  else

    if i_di_rdy_n = '0' and i_vfr_busy = '1' then

      if i_di_wr = '1' then
        if i_cntpix = TO_UNSIGNED(G_VFR_PIX_COUNT - 1 ,i_cntpix'length) then
          i_cntpix <= (others => '0');
          if i_cntline = TO_UNSIGNED(G_VFR_LINE_COUNT - 1 ,i_cntline'length) then
            i_cntline <= (others => '0');
            i_vfr_busy <= '0';
            i_di_wr <= '0';
          else
            i_cntline <= i_cntline + 1;
          end if;
        else
          i_cntpix <= i_cntpix + 1;

        end if;

        if i_cntline = TO_UNSIGNED(G_VFR_LINE_COUNT - 1 ,i_cntline'length) then
          if i_cntpix = TO_UNSIGNED(G_VFR_PIX_COUNT - 2 ,i_cntpix'length) then
            i_di_eof <= '1';
          else
            i_di_eof <= '0';
          end if;
        end if;

      end if;

      i_di_wr <= not i_di_wr;
      i_di((8 * 4) - 1 downto 8 * 3) <= i_di((8 * 4) - 1 downto 8 * 3) + 4;
      i_di((8 * 3) - 1 downto 8 * 2) <= i_di((8 * 3) - 1 downto 8 * 2) + 4;
      i_di((8 * 2) - 1 downto 8 * 1) <= i_di((8 * 2) - 1 downto 8 * 1) + 4;
      i_di((8 * 1) - 1 downto 8 * 0) <= i_di((8 * 1) - 1 downto 8 * 0) + 4;

    else
      i_di_wr <= '0';

    end if;
  end if;
  end if;

end process;

i_do_rdy_n <= '0';


process
begin

i_vfr_start <= '0';

wait for 2 us;

wait until rising_edge(i_clk);
i_vfr_start <= '1';
wait until rising_edge(i_clk);
i_vfr_start <= '0';

wait for 2 us;

wait until rising_edge(i_clk);
i_vfr_start <= '1';
wait until rising_edge(i_clk);
i_vfr_start <= '0';

wait;
end process;




end architecture behavior;
