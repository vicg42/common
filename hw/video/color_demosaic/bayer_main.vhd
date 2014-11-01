-------------------------------------------------------------------------
-- Company     : Yansar
-- Engineer    : Golovachenko Victor
--
-- Create Date : 24.10.2014 10:28:44
-- Module Name : bayer_main
--
-- Назначение/Описание :
--
-- Revision:
-- Revision 0.01 - File Created
--
-------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.vicg_common_pkg.all;
use work.reduce_pack.all;
use work.vfilter_core_pkg.all;

entity bayer_main is
generic(
G_BRAM_AWIDTH : integer := 12;
G_SIM : string:="OFF"
);
port(
-------------------------------
--CFG
-------------------------------
p_in_cfg_bypass    : in    std_logic;                    --
p_in_cfg_colorfst  : in    std_logic_vector(1 downto 0); --First pix 0/1/2 - R/G/B
p_in_cfg_pix_count : in    std_logic_vector(15 downto 0);
--p_in_cfg_row_count : in    std_logic_vector(15 downto 0);
p_in_cfg_init      : in    std_logic;

----------------------------
--Upstream Port (IN)
----------------------------
p_in_upp_data      : in    std_logic_vector(7 downto 0);
p_in_upp_wr        : in    std_logic;
p_out_upp_rdy_n    : out   std_logic;
p_in_upp_eof       : in    std_logic;

----------------------------
--Downstream Port (OUT)
----------------------------
p_out_dwnp_data    : out   std_logic_vector(7 downto 0);
p_out_dwnp_wr      : out   std_logic;
p_in_dwnp_rdy_n    : in    std_logic;
p_out_dwnp_eof     : out   std_logic;

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
end entity bayer_main;

architecture behavioral of bayer_main is

component vfilter_core is
generic(
G_VFILTER_RANG : integer := 3;
G_BRAM_AWIDTH : integer := 12;
G_SIM : string:="OFF"
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
p_in_upp_data      : in    std_logic_vector(7 downto 0);
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

signal i_matrix            : TMatrix;
signal i_matrix_wr         : std_logic;
signal i_dwnp_eof          : std_logic;
signal i_dwnp_eol          : std_logic;
signal sr_matrix           : TMatrix;
signal sr_matrix_wr        : std_logic_vector(0 to 0);
signal sr_dwnp_eof         : std_logic_vector(0 to 0);

signal i_line_evod         : std_logic;
signal i_pix_evod          : std_logic;

signal i_pix02_line0_sum   : unsigned((8 + 1) - 1 downto 0) := (others => '0');
signal i_pix02_line2_sum   : unsigned((8 + 1) - 1 downto 0) := (others => '0');
signal i_pix02_line1_sum   : unsigned((8 + 1) - 1 downto 0) := (others => '0');
signal i_pix1_line02_sum   : unsigned((8 + 1) - 1 downto 0) := (others => '0');
signal i_pix1_line1        : unsigned(8 - 1 downto 0) := (others => '0');

signal i_pix0202_line02_sum : unsigned((8 + 2) - 1 downto 0) := (others => '0');
signal i_pix021_line102_sum : unsigned((8 + 2) - 1 downto 0) := (others => '0');
signal sr_pix02_line1_sum   : unsigned(i_pix02_line1_sum'range) := (others => '0');
signal sr_pix1_line02_sum   : unsigned(i_pix1_line02_sum'range) := (others => '0');
signal sr_pix1_line1_sum    : unsigned(i_pix1_line1'range) := (others => '0');

signal i_pix0202_line02_res : unsigned(8 - 1 downto 0) := (others => '0');
signal i_pix021_line102_res : unsigned(8 - 1 downto 0) := (others => '0');
signal i_pix02_line1_res    : unsigned(8 - 1 downto 0) := (others => '0');
signal i_pix1_line02_res    : unsigned(8 - 1 downto 0) := (others => '0');
signal i_pix1_line1_res     : unsigned(8 - 1 downto 0) := (others => '0');


begin --architecture behavioral

p_out_dwnp_data((8 * 3) - 1 downto (8 * 2)) <= std_logic_vector(sr_matrix(1)(1));
p_out_dwnp_data((8 * 2) - 1 downto (8 * 1)) <= std_logic_vector(sr_matrix(1)(1));
p_out_dwnp_data((8 * 1) - 1 downto (8 * 0)) <= std_logic_vector(sr_matrix(1)(1));
p_out_dwnp_wr <= sr_matrix_wr(sr_matrix_wr'high) and not p_in_dwnp_rdy_n;
p_out_dwnp_eof <= sr_dwnp_eof(sr_dwnp_eof'high) and not p_in_dwnp_rdy_n;


m_core : vfilter_core
generic map(
G_VFILTER_RANG => 3,
G_BRAM_AWIDTH => G_BRAM_AWIDTH,
G_SIM => G_SIM
)
port map(
-------------------------------
--CFG
-------------------------------
p_in_cfg_pix_count => p_in_cfg_pix_count,
p_in_cfg_init      => p_in_cfg_init,

----------------------------
--Upstream Port (IN)
----------------------------
p_in_upp_data      => p_in_upp_data  ,
p_in_upp_wr        => p_in_upp_wr    ,
p_out_upp_rdy_n    => p_out_upp_rdy_n,
p_in_upp_eof       => p_in_upp_eof   ,

----------------------------
--Downstream Port (OUT)
----------------------------
p_out_matrix       => i_matrix  ,
p_out_dwnp_wr      => i_matrix_wr ,
p_in_dwnp_rdy_n    => p_in_dwnp_rdy_n,
p_out_dwnp_eof     => i_dwnp_eof,
p_out_dwnp_eol     => i_dwnp_eol,
p_out_line_evod    => i_line_evod,
p_out_pix_evod     => i_pix_evod,

-------------------------------
--DBG
-------------------------------
p_in_tst           => (others => '0'),
p_out_tst          => open,

-------------------------------
--System
-------------------------------
p_in_clk           => p_in_clk,
p_in_rst           => p_in_rst
);


--##################################
--Calc
--##################################
process(p_in_clk)
begin
if rising_edge(p_in_clk) then
  if p_in_rst = '1' then
      for y in 0 to C_VFILTER_RANG - 1 loop
        for x in 0 to C_VFILTER_RANG - 1 loop
          sr_matrix(y)(x) <= (others => '0');
        end loop;
      end loop;
      sr_matrix_wr <= (others => '0');
      sr_dwnp_eof <= (others => '0');

      i_pix02_line0_sum <= (others => '0');
      i_pix02_line2_sum <= (others => '0');
      i_pix02_line1_sum <= (others => '0');
      i_pix1_line02_sum <= (others => '0');
      i_pix1_line1 <= (others => '0');

      i_pix0202_line02_sum <= (others => '0');
      i_pix021_line102_sum <= (others => '0');
      sr_pix02_line1_sum <= (others => '0');
      sr_pix1_line02_sum <= (others => '0');
      sr_pix1_line1_sum <= (others => '0');

      i_pix0202_line02_res <= (others => '0');
      i_pix021_line102_res <= (others => '0');
      i_pix02_line1_res <= (others => '0');
      i_pix1_line02_res <= (others => '0');
      i_pix1_line1_res <= (others => '0');

  else
    if p_in_dwnp_rdy_n = '0' then
      if i_matrix_wr = '1' then
--        sr_matrix <= i_matrix;
      --------------------------------------------
      --1
      --------------------------------------------
      i_pix02_line0_sum <= RESIZE(i_matrix(0)(0), i_pix02_line0_sum'length) + RESIZE(i_matrix(0)(2), i_pix02_line0_sum'length);
      i_pix02_line2_sum <= RESIZE(i_matrix(2)(0), i_pix02_line2_sum'length) + RESIZE(i_matrix(2)(2), i_pix02_line2_sum'length);

      i_pix02_line1_sum <= RESIZE(i_matrix(1)(0), i_pix02_line1_sum'length) + RESIZE(i_matrix(1)(2), i_pix02_line1_sum'length);
      i_pix1_line02_sum <= RESIZE(i_matrix(0)(1), i_pix1_line02_sum'length) + RESIZE(i_matrix(2)(1), i_pix1_line02_sum'length);

      i_pix1_line1 <= i_matrix(1)(1);

      --------------------
      --2
      --------------------
      i_pix0202_line02_sum <= RESIZE(i_pix02_line0_sum, i_pix0202_line02_sum'length) + RESIZE(i_pix02_line2_sum, i_pix0202_line02_sum'length);

      i_pix021_line102_sum <= RESIZE(i_pix02_line1_sum, i_pix021_line102_sum'length) + RESIZE(i_pix1_line02_sum, i_pix021_line102_sum'length);

      sr_pix02_line1_sum <= RESIZE(i_pix02_line1_sum, sr_pix02_line1_sum'length);

      sr_pix1_line02_sum <= RESIZE(i_pix1_line02_sum, sr_pix1_line02_sum'length);

      sr_pix1_line1_sum <= i_pix1_line1;

      sr_pix(i)(1)<=sr_pix(i)(0);

      --------------------
      --3
      --------------------
      --X 0 X
      --0 0 0
      --X 0 X
      i_pix0202_line02_res(7 downto 0) <= i_sum_pix0202_line02(9 downto 2);

      --0 X 0
      --X 0 X
      --0 X 0
      i_pix021_line102_res(7 downto 0) <= i_pix021_line102_sum(9 downto 2);

      --0 0 0
      --X 0 X
      --0 0 0
      i_pix02_line1_res(7 downto 0) <= sr_pix02_line1_sum(8 downto 1);

      --0 X 0
      --0 0 0
      --0 X 0
      i_pix1_line02_res(7 downto 0) <= sr_pix1_line02_sum(8 downto 1);

      --0 0 0
      --0 X 0
      --0 0 0
      i_pix1_line1_res(7 downto 0) <= sr_pix1_line1_sum(7 downto 0);


      end if;

      sr_matrix_wr <= i_matrix_wr & sr_matrix_wr(0 to 1);
      sr_dwnp_eof <= i_dwnp_eof & sr_dwnp_eof(0 to 1);

    end if;
  end if;
end if;
end process;


--##################################
--DBG
--##################################
p_out_tst(0) <= OR_reduce(std_logic_vector(i_matrix(0)(0)))
or OR_reduce(std_logic_vector(i_matrix(0)(1)))
or OR_reduce(std_logic_vector(i_matrix(0)(2)))
or OR_reduce(std_logic_vector(i_matrix(1)(0)))
or OR_reduce(std_logic_vector(i_matrix(1)(1)))
or OR_reduce(std_logic_vector(i_matrix(1)(2)))
or OR_reduce(std_logic_vector(i_matrix(2)(0)))
or OR_reduce(std_logic_vector(i_matrix(2)(1)))
or OR_reduce(std_logic_vector(i_matrix(2)(2)));
p_out_tst(31 downto 1) <= (others=>'0');

end architecture behavioral;



