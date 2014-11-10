+-------------------------------------------------------------------------
-- Company     : Yansar
-- Engineer    : Golovachenko Victor
--
-- Create Date : 10.11.2014 10:47:07
-- Module Name : vsobel_main
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

entity vsobel_main is
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
end entity vsobel_main;

architecture behavioral of vsobel_main is

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
signal sr_matrix_wr        : std_logic_vector(0 to 5);
signal sr_dwnp_eof         : std_logic_vector(sr_matrix_wr'range);
signal sr_dwnp_eol         : std_logic_vector(sr_matrix_wr'range);

signal i_pix02_line0_sum   : unsigned((G_DWIDTH + 1) - 1 downto 0) := (others => '0');
signal i_pix02_line2_sum   : unsigned((G_DWIDTH + 1) - 1 downto 0) := (others => '0');
signal i_pix0_line02_sum   : unsigned((G_DWIDTH + 1) - 1 downto 0) := (others => '0');
signal i_pix2_line02_sum   : unsigned((G_DWIDTH + 1) - 1 downto 0) := (others => '0');

signal i_pix1_line0_x2     : unsigned((G_DWIDTH + 1) - 1 downto 0) := (others => '0');
signal i_pix1_line2_x2     : unsigned((G_DWIDTH + 1) - 1 downto 0) := (others => '0');
signal i_pix0_line1_x2     : unsigned((G_DWIDTH + 1) - 1 downto 0) := (others => '0');
signal i_pix2_line1_x2     : unsigned((G_DWIDTH + 1) - 1 downto 0) := (others => '0');

signal i_sum_x1            : unsigned((G_DWIDTH + 2) - 1 downto 0) := (others => '0');
signal i_sum_x2            : unsigned((G_DWIDTH + 2) - 1 downto 0) := (others => '0');
signal i_sum_y1            : unsigned((G_DWIDTH + 2) - 1 downto 0) := (others => '0');
signal i_sum_y2            : unsigned((G_DWIDTH + 2) - 1 downto 0) := (others => '0');

signal i_delt_xm           : unsigned((G_DWIDTH + 2) - 1 downto 0) := (others => '0');
signal i_delt_ym           : unsigned((G_DWIDTH + 2) - 1 downto 0) := (others => '0');
--signal sr_delt_xm          : unsigned((G_DWIDTH + 2) - 1 downto 0) := (others => '0');
--signal sr_delt_ym          : unsigned((G_DWIDTH + 2) - 1 downto 0) := (others => '0');

signal i_mult_01           : unsigned(((G_DWIDTH + 2) * 2) - 1 downto 0) := (others => '0');
signal i_mult_02           : unsigned(((G_DWIDTH + 2) * 2) - 1 downto 0) := (others => '0');
signal i_mult_01_div       : unsigned(((G_DWIDTH + 2) * 2) - 1 downto 0) := (others => '0');
signal i_mult_02_div       : unsigned(((G_DWIDTH + 2) * 2) - 1 downto 0) := (others => '0');

signal tmp_grad_out        : unsigned(G_DWIDTH - 1 downto 0) := (others => '0');
signal i_grad_out          : unsigned(G_DWIDTH - 1 downto 0) := (others => '0');




begin --architecture behavioral

p_out_dwnp_data <= std_logic_vector(i_grad_out);
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

      i_pix0_line02_sum <= RESIZE(i_matrix(0)(0), i_pix02_line1_sum'length) + RESIZE(i_matrix(2)(0), i_pix02_line1_sum'length);
      i_pix2_line02_sum <= RESIZE(i_matrix(2)(0), i_pix1_line02_sum'length) + RESIZE(i_matrix(2)(2), i_pix1_line02_sum'length);

      i_pix1_line0_x2 <= i_matrix(0)(1) & '0';
      i_pix1_line2_x2 <= i_matrix(2)(1) & '0';
      i_pix0_line1_x2 <= i_matrix(1)(0) & '0';
      i_pix2_line1_x2 <= i_matrix(1)(2) & '0';

      --------------------
      --1
      --------------------
      i_sum_x1 <= RESIZE(i_pix02_line0_sum, i_sum_x1'length) + RESIZE(i_pix1_line0_x2, i_sum_x1'length);
      i_sum_x2 <= RESIZE(i_pix02_line2_sum, i_sum_x2'length) + RESIZE(i_pix1_line2_x2, i_sum_x2'length);

      i_sum_y1 <= RESIZE(i_pix0_line02_sum, i_sum_y1'length) + RESIZE(i_pix0_line1_x2, i_sum_y1'length);
      i_sum_y2 <= RESIZE(i_pix2_line02_sum, i_sum_y2'length) + RESIZE(i_pix2_line1_x2, i_sum_y2'length);

      --------------------
      --2
      --------------------
      if i_sum_x1 > i_sum_x2 then
        i_delt_xm <= i_sum_x1 - i_sum_x2;
      else
        i_delt_xm <= i_sum_x2 - i_sum_x1;
      end if;

      if i_sum_y1 > i_sum_y2 then
        i_delt_ym <= i_sum_y1 - i_sum_y2;
      else
        i_delt_ym <= i_sum_y2 - i_sum_y1;
      end if;

      --------------------
      --3
      --------------------
      --accurate calculation gradient
      if i_delt_xm > i_delt_ym then
        i_mult_01 <= i_delt_xm * TO_UNSIGNED(10#123#, i_delt_xm'length);
        i_mult_02 <= i_delt_ym * TO_UNSIGNED(10#13# , i_delt_ym'length);
      else
        i_mult_01 <= i_delt_ym * TO_UNSIGNED(10#123#, i_delt_ym'length);
        i_mult_02 <= i_delt_xm * TO_UNSIGNED(10#13# , i_delt_xm'length);
      end if;

--      --simple calculation gradient
--      sr_delt_xm <= i_delt_xm;
--      sr_delt_ym <= i_delt_ym;

      --------------------
      --4  GRADIENT = (dx^2 + dy^2)^0.5
      --------------------
      --accurate calculation gradient
      --((delta_xm * 123)/128) + ((delt_ym * 13)/32)
      tmp_grad_out <= (TO_UNSIGNED(0, 7) & i_mult_01(i_mult_01'high downto 7))
                        + (TO_UNSIGNED(0, 5) & i_mult_02(i_mult_02'high downto 5));

--      --simple calculation gradient
--      tmp_grad_out <= RESIZE(sr_delt_xm, tmp_grad_out'length) + RESIZE(sr_delt_ym, tmp_grad_out'length);

      --------------------
      --5
      --------------------
      if tmp_grad_out >= TO_UNSIGNED(pwr(2, G_DWIDTH) - 1, tmp_grad_out'length) then
        i_grad_out <= (others=>'1');
      else
        i_grad_out <= tmp_grad_out(i_grad_out'range);
      end if;

      -----------------------------
      sr_matrix_wr <= i_matrix_wr & sr_matrix_wr(0 to sr_matrix_wr'high - 1);
      sr_dwnp_eof <= i_dwnp_eof & sr_dwnp_eof(0 to sr_dwnp_eof'high - 1);
      sr_dwnp_eol <= i_dwnp_eol & sr_dwnp_eol(0 to sr_dwnp_eol'high - 1);

  end if;
end if;
end process;


--##################################
--DBG
--##################################
p_out_tst(0) <= '0';
p_out_tst(31 downto 1) <= (others=>'0');

end architecture behavioral;
