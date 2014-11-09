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
G_BRAM_SIZE_BYTE : integer := 12;
G_DWIDTH : integer := 8
);
port(
-------------------------------
--CFG
-------------------------------
p_in_cfg_colorfst  : in    std_logic_vector(1 downto 0); --First pix
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
end entity bayer_main;

architecture behavioral of bayer_main is

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

signal i_matrix            : TMatrix;
signal i_matrix_wr         : std_logic;
signal i_dwnp_eof          : std_logic;
signal i_dwnp_eol          : std_logic;
signal sr_matrix_wr        : std_logic_vector(0 to 3);
signal sr_dwnp_eof         : std_logic_vector(sr_matrix_wr'range);
signal sr_dwnp_eol         : std_logic_vector(sr_matrix_wr'range);

signal i_line_evod         : std_logic;
signal sr_line_evod        : std_logic_vector(0 to sr_dwnp_eof'high - 1) := (others => '0');
signal i_pix_evod          : std_logic;
signal sr_pix_evod         : std_logic_vector(0 to sr_dwnp_eof'high - 1) := (others => '0');
signal i_sel               : std_logic_vector(1 downto 0);

signal i_pix02_line0_sum   : unsigned((G_DWIDTH + 1) - 1 downto 0) := (others => '0');
signal i_pix02_line2_sum   : unsigned((G_DWIDTH + 1) - 1 downto 0) := (others => '0');
signal i_pix02_line1_sum   : unsigned((G_DWIDTH + 1) - 1 downto 0) := (others => '0');
signal i_pix1_line02_sum   : unsigned((G_DWIDTH + 1) - 1 downto 0) := (others => '0');
signal i_pix1_line1        : unsigned(G_DWIDTH - 1 downto 0) := (others => '0');

signal i_pix0202_line02_sum : unsigned((G_DWIDTH + 2) - 1 downto 0) := (others => '0');
signal i_pix021_line102_sum : unsigned((G_DWIDTH + 2) - 1 downto 0) := (others => '0');
signal sr_pix02_line1_sum   : unsigned(i_pix02_line1_sum'range) := (others => '0');
signal sr_pix1_line02_sum   : unsigned(i_pix1_line02_sum'range) := (others => '0');
signal sr_pix1_line1_sum    : unsigned(i_pix1_line1'range) := (others => '0');

signal i_pix0202_line02_res : unsigned(G_DWIDTH - 1 downto 0) := (others => '0');
signal i_pix021_line102_res : unsigned(G_DWIDTH - 1 downto 0) := (others => '0');
signal i_pix02_line1_res    : unsigned(G_DWIDTH - 1 downto 0) := (others => '0');
signal i_pix1_line02_res    : unsigned(G_DWIDTH - 1 downto 0) := (others => '0');
signal i_pix1_line1_res     : unsigned(G_DWIDTH - 1 downto 0) := (others => '0');

signal i_rcolor             : unsigned(G_DWIDTH - 1 downto 0) := (others => '0');
signal i_gcolor             : unsigned(G_DWIDTH - 1 downto 0) := (others => '0');
signal i_bcolor             : unsigned(G_DWIDTH - 1 downto 0) := (others => '0');


begin --architecture behavioral

p_out_dwnp_data((G_DWIDTH * 3) - 1 downto (G_DWIDTH * 2)) <= std_logic_vector(i_bcolor);
p_out_dwnp_data((G_DWIDTH * 2) - 1 downto (G_DWIDTH * 1)) <= std_logic_vector(i_gcolor);
p_out_dwnp_data((G_DWIDTH * 1) - 1 downto (G_DWIDTH * 0)) <= std_logic_vector(i_rcolor);
p_out_dwnp_wr <= sr_matrix_wr(sr_matrix_wr'high) and not p_in_dwnp_rdy_n;
p_out_dwnp_eof <= sr_dwnp_eof(sr_dwnp_eof'high) and not p_in_dwnp_rdy_n;
p_out_dwnp_eol <= sr_dwnp_eol(sr_dwnp_eol'high) and not p_in_dwnp_rdy_n;


m_core : vfilter_core
generic map(
G_VFILTER_RANG => 3,
G_BRAM_SIZE_BYTE => G_BRAM_SIZE_BYTE
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
    if p_in_dwnp_rdy_n = '0' then

      --------------------------------------------
      --0
      --------------------------------------------
      i_pix02_line0_sum <= RESIZE(i_matrix(0)(0), i_pix02_line0_sum'length) + RESIZE(i_matrix(0)(2), i_pix02_line0_sum'length);
      i_pix02_line2_sum <= RESIZE(i_matrix(2)(0), i_pix02_line2_sum'length) + RESIZE(i_matrix(2)(2), i_pix02_line2_sum'length);

      i_pix02_line1_sum <= RESIZE(i_matrix(1)(0), i_pix02_line1_sum'length) + RESIZE(i_matrix(1)(2), i_pix02_line1_sum'length);
      i_pix1_line02_sum <= RESIZE(i_matrix(0)(1), i_pix1_line02_sum'length) + RESIZE(i_matrix(2)(1), i_pix1_line02_sum'length);

      i_pix1_line1 <= RESIZE(i_matrix(1)(1), i_pix1_line1'length);

      --------------------
      --1
      --------------------
      i_pix0202_line02_sum <= RESIZE(i_pix02_line0_sum, i_pix0202_line02_sum'length) + RESIZE(i_pix02_line2_sum, i_pix0202_line02_sum'length);

      i_pix021_line102_sum <= RESIZE(i_pix02_line1_sum, i_pix021_line102_sum'length) + RESIZE(i_pix1_line02_sum, i_pix021_line102_sum'length);

      sr_pix02_line1_sum <= RESIZE(i_pix02_line1_sum, sr_pix02_line1_sum'length);

      sr_pix1_line02_sum <= RESIZE(i_pix1_line02_sum, sr_pix1_line02_sum'length);

      sr_pix1_line1_sum <= i_pix1_line1;

      --------------------
      --2
      --------------------
      --X 0 X
      --0 0 0
      --X 0 X
      i_pix0202_line02_res <= i_pix0202_line02_sum(i_pix0202_line02_sum'high downto 2); --div 4

      --0 X 0
      --X 0 X
      --0 X 0
      i_pix021_line102_res <= i_pix021_line102_sum(i_pix021_line102_sum'high downto 2); --div 4

      --0 0 0
      --X 0 X
      --0 0 0
      i_pix02_line1_res <= sr_pix02_line1_sum(sr_pix02_line1_sum'high downto 1); --div 2

      --0 X 0
      --0 0 0
      --0 X 0
      i_pix1_line02_res <= sr_pix1_line02_sum(sr_pix1_line02_sum'high downto 1); --div 2

      --0 0 0
      --0 X 0
      --0 0 0
      i_pix1_line1_res <= sr_pix1_line1_sum;

      --------------------
      --3
      --------------------
--      case i_sel is
--        when "00" => --line/pix - even/even
--            i_rcolor <= i_pix1_line1_res;
--            i_gcolor <= i_pix021_line102_res;
--            i_bcolor <= i_pix0202_line02_res;
--
--        when "01" => --line/pix - even/odd
--            i_rcolor <= i_pix02_line1_res;
--            i_gcolor <= i_pix1_line1_res;
--            i_bcolor <= i_pix1_line02_res;
--
--        when "10" => --line/pix - odd/even
--            i_rcolor <= i_pix1_line02_res;
--            i_gcolor <= i_pix1_line1_res;
--            i_bcolor <= i_pix02_line1_res;
--
--        when "11" => --line/pix - odd/odd
--            i_rcolor <= i_pix0202_line02_res;
--            i_gcolor <= i_pix021_line102_res;
--            i_bcolor <= i_pix1_line1_res;
--
--        when others => null;
--      end case;

      case i_sel is
        when "00" => --line/pix - even/even
            i_rcolor <= i_pix0202_line02_res;
            i_gcolor <= i_pix021_line102_res;
            i_bcolor <= i_pix1_line1_res;

        when "01" => --line/pix - even/odd
            i_rcolor <= i_pix1_line02_res;
            i_gcolor <= i_pix1_line1_res;
            i_bcolor <= i_pix02_line1_res;

        when "10" => --line/pix - odd/even
            i_rcolor <= i_pix02_line1_res;
            i_gcolor <= i_pix1_line1_res;
            i_bcolor <= i_pix1_line02_res;

        when "11" => --line/pix - odd/odd
            i_rcolor <= i_pix1_line1_res;
            i_gcolor <= i_pix021_line102_res;
            i_bcolor <= i_pix0202_line02_res;

        when others => null;
      end case;
      -----------------------------
      sr_matrix_wr <= i_matrix_wr & sr_matrix_wr(0 to sr_matrix_wr'high - 1);
      sr_dwnp_eof <= i_dwnp_eof & sr_dwnp_eof(0 to sr_dwnp_eof'high - 1);
      sr_dwnp_eol <= i_dwnp_eol & sr_dwnp_eol(0 to sr_dwnp_eol'high - 1);

      sr_line_evod <= i_line_evod & sr_line_evod(0 to sr_line_evod'high - 1);
      sr_pix_evod <= i_pix_evod & sr_pix_evod(0 to sr_pix_evod'high - 1);

  end if;
end if;
end process;

i_sel <= sr_line_evod(sr_line_evod'high) & sr_pix_evod(sr_pix_evod'high);


--##################################
--DBG
--##################################
p_out_tst(0) <= '0';
p_out_tst(31 downto 1) <= (others=>'0');

end architecture behavioral;
