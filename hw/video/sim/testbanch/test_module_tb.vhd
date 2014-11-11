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
use work.vfilter_core_pkg.all;

entity test_module_tb is
generic(
G_VFR_PIX_COUNT : integer := 8;
G_VFR_LINE_COUNT : integer := 5;
G_MIRX : std_logic := '0';
G_BRAM_SIZE_BYTE : integer := 8192;
G_PIX_SIZE : integer := 8;
G_DI_WIDTH : integer := 32;
G_DO_WIDTH : integer := 8
);
port(
p_out_dwnp_data     : out   std_logic_vector(G_DO_WIDTH - 1 downto 0);
p_out_dwnp_wr       : out   std_logic;
p_out_dwnp_eof      : out   std_logic
);
end entity test_module_tb;

architecture behavior of test_module_tb is

constant CI_CLK_PERIOD          : TIME := 6.6 ns; --150MHz
constant CI_OFIFO_CLK_PERIOD    : TIME := 7.6 ns;

component vmirx_main
generic(
G_BRAM_SIZE_BYTE : integer := 8;
G_PIX_SIZE : integer := 8;
G_DI_WIDTH : integer := 8;
G_DO_WIDTH : integer := 8
);
port(
-------------------------------
--CFG
-------------------------------
p_in_cfg_mirx       : in    std_logic;                    --1/0 - mirx ON/OFF
p_in_cfg_pix_count  : in    std_logic_vector(15 downto 0);--Count byte

----------------------------
--Upstream Port (IN)
----------------------------
p_in_upp_data       : in    std_logic_vector(G_DI_WIDTH - 1 downto 0);
p_in_upp_wr         : in    std_logic;
p_out_upp_rdy_n     : out   std_logic;
p_in_upp_eof        : in    std_logic;

----------------------------
--Downstream Port (OUT)
----------------------------
p_out_dwnp_data     : out   std_logic_vector(G_DO_WIDTH - 1 downto 0);
p_out_dwnp_wr       : out   std_logic;
p_in_dwnp_rdy_n     : in    std_logic;
p_out_dwnp_eof      : out   std_logic;
p_out_dwnp_eol      : out   std_logic;

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

component vdebayer_main is
generic(
G_BRAM_SIZE_BYTE : integer := 12;
G_DWIDTH : integer := 8
);
port(
-------------------------------
--CFG
-------------------------------
p_in_cfg_colorfst  : in    std_logic_vector(1 downto 0); --First pix 0/1/2 - R/G/B
p_in_cfg_pix_count : in    std_logic_vector(15 downto 0);
--p_in_cfg_row_count : in    std_logic_vector(15 downto 0);
p_in_cfg_init      : in    std_logic;

----------------------------
--Upstream Port (IN)
----------------------------
p_in_upp_data      : in    std_logic_vector(G_DWIDTH - 1 downto 0);
p_in_upp_wr        : in    std_logic;
p_out_upp_rdy_n    : out   std_logic;
p_in_upp_eof       : in    std_logic;

----------------------------
--Downstream Port (OUT)
----------------------------
p_out_dwnp_data    : out   std_logic_vector((G_DWIDTH * 3) - 1 downto 0);
p_out_dwnp_wr      : out   std_logic;
p_in_dwnp_rdy_n    : in    std_logic;
p_out_dwnp_eof     : out   std_logic;
p_out_dwnp_eol     : out   std_logic;

-------------------------------
--DBG
-------------------------------
p_in_tst           : in    std_logic_vector(31 downto 0);
p_out_tst          : out   std_logic_vector(31 downto 0);

-------------------------------
--System
-------------------------------
p_in_clk           : in    std_logic;
p_in_rst           : in    std_logic
);
end component vdebayer_main;

component vfilter_core is
generic(
G_VFILTER_RANG : integer := 3;
G_BRAM_SIZE_BYTE : integer := 12;
G_DWIDTH : integer := 8
);
port(
-------------------------------
--CFG
-------------------------------
p_in_cfg_pix_count : in    std_logic_vector(15 downto 0);--Byte count
p_in_cfg_init      : in    std_logic;

----------------------------
--Upstream Port (IN)
----------------------------
p_in_upp_data      : in    std_logic_vector(G_DWIDTH - 1 downto 0);
p_in_upp_wr        : in    std_logic;
p_out_upp_rdy_n    : out   std_logic;
p_in_upp_eof       : in    std_logic;

----------------------------
--Downstream Port (OUT)
----------------------------
p_out_matrix       : out   TMatrix;
p_out_dwnp_wr      : out   std_logic;
p_in_dwnp_rdy_n    : in    std_logic;
p_out_dwnp_eof     : out   std_logic;
p_out_dwnp_eol     : out   std_logic;
p_out_line_evod    : out   std_logic;
p_out_pix_evod     : out   std_logic;

-------------------------------
--DBG
-------------------------------
p_in_tst           : in    std_logic_vector(31 downto 0);
p_out_tst          : out   std_logic_vector(31 downto 0);

-------------------------------
--System
-------------------------------
p_in_clk           : in    std_logic;
p_in_rst           : in    std_logic
);
end component vfilter_core;

component vsobel_main is
generic(
G_BRAM_SIZE_BYTE : integer := 12;
G_DWIDTH : integer := 8
);
port(
-------------------------------
--CFG
-------------------------------
p_in_cfg_pix_count : in    std_logic_vector(15 downto 0);
p_in_cfg_init      : in    std_logic;

----------------------------
--Upstream Port (IN)
----------------------------
p_in_upp_data      : in    std_logic_vector(G_DWIDTH - 1 downto 0);
p_in_upp_wr        : in    std_logic;
p_out_upp_rdy_n    : out   std_logic;
p_in_upp_eof       : in    std_logic;

----------------------------
--Downstream Port (OUT)
----------------------------
p_out_dwnp_data    : out   std_logic_vector(G_DWIDTH - 1 downto 0);
p_out_dwnp_wr      : out   std_logic;
p_in_dwnp_rdy_n    : in    std_logic;
p_out_dwnp_eof     : out   std_logic;
p_out_dwnp_eol     : out   std_logic;

-------------------------------
--DBG
-------------------------------
p_in_tst           : in    std_logic_vector(31 downto 0);
p_out_tst          : out   std_logic_vector(31 downto 0);

-------------------------------
--System
-------------------------------
p_in_clk           : in    std_logic;
p_in_rst           : in    std_logic
);
end component vsobel_main;


component sim_fifo8x8bit
port(
din         : IN  std_logic_vector(7 downto 0);
wr_en       : IN  std_logic;
wr_clk      : IN  std_logic;

dout        : OUT std_logic_vector(7 downto 0);
rd_en       : IN  std_logic;
rd_clk      : IN  std_logic;

empty       : OUT std_logic;
full        : OUT std_logic;
prog_full   : OUT std_logic;

rst         : IN  std_logic
);
end component sim_fifo8x8bit;

type TFsm_state is (
S_IDLE,
S_PIX_COUNT,
S_LINE_COUNT,
S_DELAY_NFR
);
signal i_fsm_cs             : TFsm_state;

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

signal i_mir_do             : std_logic_vector(G_DO_WIDTH - 1 downto 0);
signal i_mir_wr             : std_logic;
signal i_mir_eof            : std_logic;
signal i_mir_eol            : std_logic;
signal i_bayer_rdy_n        : std_logic;

signal i_matrix             : TMatrix;
signal i_matrix_wr          : std_logic;
signal i_matrix_eof         : std_logic;
signal i_matrix_rdy_n       : std_logic;

signal i_byer_do            : std_logic_vector((8*3) -1 downto 0);--((G_DO_WIDTH * 3) - 1 downto 0);--
signal i_byer_do_wr         : std_logic;
signal i_byer_do_eof        : std_logic;
signal i_byer_do_eol        : std_logic;

signal i_ofifo_do           : std_logic_vector(7 downto 0);
signal i_ofifo_rd           : std_logic := '0';
signal i_ofifo_clk          : std_logic;
signal i_ofifo_empty        : std_logic;
signal i_ofifo_pfull        : std_logic;
signal i_ofifo_cnddiv       : unsigned(7 downto 0) := (others => '0');

signal i_sobel_do           : std_logic_vector(G_DO_WIDTH - 1 downto 0);
signal i_sobel_wr           : std_logic;
signal i_sobel_rdy_n        : std_logic;
signal i_sobel_eof          : std_logic;



begin --architecture behavior

i_rst <= '1','0' after 1 us;

clkgen : process
begin
  i_clk <= '0';
  wait for (CI_CLK_PERIOD / 2);
  i_clk <= '1';
  wait for (CI_CLK_PERIOD / 2);
end process clkgen;

clkgen2 : process
begin
  i_ofifo_clk <= '0';
  wait for (CI_OFIFO_CLK_PERIOD / 2);
  i_ofifo_clk <= '1';
  wait for (CI_OFIFO_CLK_PERIOD / 2);
end process clkgen2;



m_vmirx: vmirx_main
generic map(
G_BRAM_SIZE_BYTE => G_BRAM_SIZE_BYTE,
G_PIX_SIZE => G_PIX_SIZE,
G_DI_WIDTH => G_DI_WIDTH,
G_DO_WIDTH => G_DO_WIDTH
)
port map
(
-------------------------------
--CFG
-------------------------------
p_in_cfg_mirx       => G_MIRX,
p_in_cfg_pix_count  => std_logic_vector(TO_UNSIGNED(G_VFR_PIX_COUNT ,16)),

----------------------------
--Upstream Port (IN)
----------------------------
p_in_upp_data       => std_logic_vector(i_di),
p_in_upp_wr         => i_di_wr,
p_out_upp_rdy_n     => i_di_rdy_n,
p_in_upp_eof        => i_di_eof,

----------------------------
--Downstream Port (OUT)
----------------------------
p_out_dwnp_data     => i_mir_do      ,--i_mir_do      ,--p_out_dwnp_data,                 i_mir_do      ,--
p_out_dwnp_wr       => i_mir_wr      ,--i_mir_wr      ,--p_out_dwnp_wr  ,                 i_mir_wr      ,--
p_in_dwnp_rdy_n     => i_sobel_rdy_n ,--i_matrix_rdy_n,--i_bayer_rdy_n,--i_do_rdy_n     , i_ofifo_pfull ,--
p_out_dwnp_eof      => i_mir_eof     ,--i_mir_eof     ,--p_out_dwnp_eof ,                 i_mir_eof     ,--
p_out_dwnp_eol      => i_mir_eol     ,--i_mir_eol     ,--p_out_dwnp_eof ,                 i_mir_eol     ,--

-------------------------------
--DBG
-------------------------------
p_in_tst            => (others => '0'),
p_out_tst           => open,

-------------------------------
--System
-------------------------------
p_in_clk            => i_clk,
p_in_rst            => i_rst
);


--m_filter_core : vfilter_core
--generic map(
--G_VFILTER_RANG => 5,
--G_DWIDTH => 8, --G_DO_WIDTH,
--G_BRAM_SIZE_BYTE => G_BRAM_SIZE_BYTE
--)
--port map(
---------------------------------
----CFG
---------------------------------
--p_in_cfg_pix_count => std_logic_vector(TO_UNSIGNED(G_VFR_PIX_COUNT ,16)),
--p_in_cfg_init      => '0',
--
------------------------------
----Upstream Port (IN)
------------------------------
--p_in_upp_data      => i_mir_do(7 downto 0),
--p_in_upp_wr        => i_mir_wr,
--p_out_upp_rdy_n    => i_matrix_rdy_n,
--p_in_upp_eof       => i_mir_eof,
--
------------------------------
----Downstream Port (OUT)
------------------------------
--p_out_matrix       => i_matrix     ,
--p_out_dwnp_wr      => i_matrix_wr  ,
--p_in_dwnp_rdy_n    => i_bayer_rdy_n,
--p_out_dwnp_eof     => i_matrix_eof ,
--p_out_dwnp_eol     => open,--i_dwnp_eol,
--p_out_line_evod    => open,--i_line_evod,
--p_out_pix_evod     => open,--i_pix_evod,
--
---------------------------------
----DBG
---------------------------------
--p_in_tst           => (others => '0'),
--p_out_tst          => open,
--
---------------------------------
----System
---------------------------------
--p_in_clk           => i_clk,
--p_in_rst           => i_rst
--);

--m_bayer : vdebayer_main
--generic map(
--G_BRAM_SIZE_BYTE => G_BRAM_SIZE_BYTE,
--G_DWIDTH => 8 --G_DO_WIDTH
--)
--port map(
---------------------------------
----CFG
---------------------------------
--p_in_cfg_colorfst  => (others => '0'),
--p_in_cfg_pix_count  => std_logic_vector(TO_UNSIGNED(G_VFR_PIX_COUNT ,16)),
----p_in_cfg_row_count => (others => '0'),
--p_in_cfg_init      => '0',
--
------------------------------
----Upstream Port (IN)
------------------------------
--p_in_upp_data      => std_logic_vector(i_matrix(2)(2)(7 downto 0)),--(G_DO_WIDTH - 1 downto 0)),--i_mir_do,
--p_in_upp_wr        => i_matrix_wr,--i_mir_wr,
--p_in_upp_eof       => i_matrix_eof,--i_mir_eof,
--p_out_upp_rdy_n    => i_bayer_rdy_n,
--
------------------------------
----Downstream Port (OUT)
------------------------------
--p_out_dwnp_data    => i_byer_do,
--p_out_dwnp_wr      => i_byer_do_wr  ,
--p_in_dwnp_rdy_n    => i_ofifo_pfull , --i_do_rdy_n    ,
--p_out_dwnp_eof     => i_byer_do_eof ,
--p_out_dwnp_eol     => i_byer_do_eol ,
--
---------------------------------
----DBG
---------------------------------
--p_in_tst           => (others => '0'),
--p_out_tst          => open,
--
---------------------------------
----System
---------------------------------
--p_in_clk           => i_clk,
--p_in_rst           => i_rst
--);

m_sobel : vsobel_main
generic map(
G_BRAM_SIZE_BYTE => G_BRAM_SIZE_BYTE,
G_DWIDTH => 8
)
port map(
-------------------------------
--CFG
-------------------------------
p_in_cfg_pix_count => std_logic_vector(TO_UNSIGNED(G_VFR_PIX_COUNT ,16)),
p_in_cfg_init      => '0',

----------------------------
--Upstream Port (IN)
----------------------------
p_in_upp_data      => i_mir_do(7 downto 0),
p_in_upp_wr        => i_mir_wr,
p_out_upp_rdy_n    => i_sobel_rdy_n,
p_in_upp_eof       => i_mir_eof,

----------------------------
--Downstream Port (OUT)
----------------------------
p_out_dwnp_data    => i_sobel_do,
p_out_dwnp_wr      => i_sobel_wr,
p_in_dwnp_rdy_n    => i_ofifo_pfull,
p_out_dwnp_eof     => open,
p_out_dwnp_eol     => open,

-------------------------------
--DBG
-------------------------------
p_in_tst           => (others => '0'),
p_out_tst          => open,

-------------------------------
--System
-------------------------------
p_in_clk           => i_clk,
p_in_rst           => i_rst
);



m_ofifo : sim_fifo8x8bit
port map(
din         => i_sobel_do(7 downto 0),--i_byer_do(7 downto 0), --i_mir_do,
wr_en       => i_sobel_wr,--i_byer_do_wr,          --i_mir_wr,
wr_clk      => i_clk,

dout        => i_ofifo_do,
rd_en       => '1',--i_ofifo_rd,
rd_clk      => i_ofifo_clk,

empty       => i_ofifo_empty,
full        => open,
prog_full   => i_ofifo_pfull,

rst         => i_rst
);

p_out_dwnp_data <= std_logic_vector(RESIZE(UNSIGNED(i_ofifo_do), p_out_dwnp_data'length));--i_byer_do(G_DO_WIDTH - 1 downto 0);
p_out_dwnp_wr   <= i_ofifo_rd;--i_byer_do_wr;
p_out_dwnp_eof  <= i_byer_do_eof;


--Генератор тестовых данных
i_do_rdy_n <= '0';

process(i_clk)
begin
if rising_edge(i_clk) then
  if i_rst = '1' then

    i_fsm_cs <= S_IDLE;
    i_cntpix <= (others => '0');
    i_cntline <= (others => '0');
    i_di_wr <= '0';
    i_di_eof <= '0';

    for i in 0 to (i_di'length / 8) - 1 loop
    i_di(8 * (i + 1) - 1 downto (8 * i)) <= TO_UNSIGNED((i + 1), 8);
    end loop;

  else

    case i_fsm_cs is

      --------------------------------------
      --
      --------------------------------------
      when S_IDLE =>

        if i_vfr_start = '1' then
          i_fsm_cs <= S_PIX_COUNT;
        end if;

      --------------------------------------
      --
      --------------------------------------
      when S_PIX_COUNT =>

        if i_di_rdy_n = '0' then
          if i_di_wr = '1' then
            if i_cntpix = TO_UNSIGNED(G_VFR_PIX_COUNT - (i_di'length / 8),i_cntpix'length) then
              i_cntpix <= (others => '0');
              i_di_wr <= '0';
              i_fsm_cs <= S_LINE_COUNT;
            else
              i_cntpix <= i_cntpix + (i_di'length / 8);
            end if;

            for i in 0 to (i_di'length / 8) - 1 loop
            i_di(8 * (i + 1) - 1 downto (8 * i)) <= i_di(8 * (i + 1) - 1 downto (8 * i)) + (i_di'length / 8);
            end loop;
          else
            i_di_wr <= '1';
          end if;

--          i_di_wr <= not i_di_wr;
        end if;

      ------------------------------------------------
      --
      ------------------------------------------------
      when S_LINE_COUNT =>

        if i_mir_eol = '1' then
          if i_cntline = TO_UNSIGNED(G_VFR_LINE_COUNT - 1 ,i_cntline'length) then
            i_cntline <= (others => '0');
            i_fsm_cs <= S_DELAY_NFR;--S_IDLE;
          else
            i_cntline <= i_cntline + 1;
            i_fsm_cs <= S_PIX_COUNT;
          end if;
        end if;


      ------------------------------------------------
      --
      ------------------------------------------------
      when S_DELAY_NFR =>

          if i_cntline = TO_UNSIGNED(256 ,i_cntline'length) then
            i_cntline <= (others => '0');
            i_fsm_cs <= S_PIX_COUNT;
          else
            i_cntline <= i_cntline + 1;
          end if;

    end case;

    if i_cntline = TO_UNSIGNED(G_VFR_LINE_COUNT - 1 ,i_cntline'length) then
        i_di_eof <= '1';
    else
        i_di_eof <= '0';
    end if;

  end if;
end if;
end process;


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



process(i_clk)
begin
if rising_edge(i_ofifo_clk) then
  if i_rst = '1' then
    i_ofifo_cnddiv <= (others => '0');
    i_ofifo_rd <= '0';

  else
    if i_ofifo_cnddiv = TO_UNSIGNED(4, i_ofifo_cnddiv'length) then
      i_ofifo_cnddiv <= (others => '0');
      i_ofifo_rd <= '1';
    else
      i_ofifo_cnddiv <= i_ofifo_cnddiv + 1;
      i_ofifo_rd <= '0';
    end if;

  end if;
end if;
end process;

end architecture behavior;
