-------------------------------------------------------------------------
-- Company     : Yansar
-- Engineer    : Golovachenko Victor
--
-- Create Date : 10.11.2014 12:51:18
-- Module Name : vmedian_main
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

entity vmedian_main is
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
end entity vmedian_main;

architecture behavioral of vmedian_main is

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
signal sr_matrix_wr        : std_logic_vector(0 to 8);
signal sr_dwnp_eof         : std_logic_vector(sr_matrix_wr'range);
signal sr_dwnp_eol         : std_logic_vector(sr_matrix_wr'range);

signal i_calc0_1H          : std_logic_vector(G_DWIDTH - 1 downto 0) := (others => '0');
signal i_calc0_1L          : std_logic_vector(G_DWIDTH - 1 downto 0) := (others => '0');
signal i_calc0_2           : std_logic_vector(G_DWIDTH - 1 downto 0) := (others => '0');
signal i_calc0_3H          : std_logic_vector(G_DWIDTH - 1 downto 0) := (others => '0');
signal i_calc0_3L          : std_logic_vector(G_DWIDTH - 1 downto 0) := (others => '0');
signal i_calc0_4           : std_logic_vector(G_DWIDTH - 1 downto 0) := (others => '0');
signal i_calc0_5H          : std_logic_vector(G_DWIDTH - 1 downto 0) := (others => '0');
signal i_calc0_5L          : std_logic_vector(G_DWIDTH - 1 downto 0) := (others => '0');
signal i_calc0_6           : std_logic_vector(G_DWIDTH - 1 downto 0) := (others => '0');

signal i_calc1_1           : std_logic_vector(G_DWIDTH - 1 downto 0) := (others => '0');
signal i_calc1_2H          : std_logic_vector(G_DWIDTH - 1 downto 0) := (others => '0');
signal i_calc1_2L          : std_logic_vector(G_DWIDTH - 1 downto 0) := (others => '0');
signal i_calc1_3           : std_logic_vector(G_DWIDTH - 1 downto 0) := (others => '0');
signal i_calc1_4H          : std_logic_vector(G_DWIDTH - 1 downto 0) := (others => '0');
signal i_calc1_4L          : std_logic_vector(G_DWIDTH - 1 downto 0) := (others => '0');
signal i_calc1_5           : std_logic_vector(G_DWIDTH - 1 downto 0) := (others => '0');
signal i_calc1_6H          : std_logic_vector(G_DWIDTH - 1 downto 0) := (others => '0');
signal i_calc1_6L          : std_logic_vector(G_DWIDTH - 1 downto 0) := (others => '0');
signal i_calc2_1H          : std_logic_vector(G_DWIDTH - 1 downto 0) := (others => '0');
signal i_calc2_1L          : std_logic_vector(G_DWIDTH - 1 downto 0) := (others => '0');
signal i_calc2_2           : std_logic_vector(G_DWIDTH - 1 downto 0) := (others => '0');
signal i_calc2_3H          : std_logic_vector(G_DWIDTH - 1 downto 0) := (others => '0');
signal i_calc2_3L          : std_logic_vector(G_DWIDTH - 1 downto 0) := (others => '0');
signal i_calc2_4           : std_logic_vector(G_DWIDTH - 1 downto 0) := (others => '0');
signal i_calc2_5H          : std_logic_vector(G_DWIDTH - 1 downto 0) := (others => '0');
signal i_calc2_5L          : std_logic_vector(G_DWIDTH - 1 downto 0) := (others => '0');
signal i_calc2_6           : std_logic_vector(G_DWIDTH - 1 downto 0) := (others => '0');

signal i_calc3_1H          : std_logic_vector(G_DWIDTH - 1 downto 0) := (others => '0');
signal i_calc3_1L          : std_logic_vector(G_DWIDTH - 1 downto 0) := (others => '0');
signal i_calc3_2           : std_logic_vector(G_DWIDTH - 1 downto 0) := (others => '0');
signal i_calc3_3H          : std_logic_vector(G_DWIDTH - 1 downto 0) := (others => '0');
signal i_calc3_3L          : std_logic_vector(G_DWIDTH - 1 downto 0) := (others => '0');
signal i_calc3_4           : std_logic_vector(G_DWIDTH - 1 downto 0) := (others => '0');
signal i_calc3_5H          : std_logic_vector(G_DWIDTH - 1 downto 0) := (others => '0');
signal i_calc3_5L          : std_logic_vector(G_DWIDTH - 1 downto 0) := (others => '0');
signal i_calc3_6           : std_logic_vector(G_DWIDTH - 1 downto 0) := (others => '0');

signal i_calc4_1H          : std_logic_vector(G_DWIDTH - 1 downto 0) := (others => '0');
signal i_calc4_1L          : std_logic_vector(G_DWIDTH - 1 downto 0) := (others => '0');
signal i_calc4_2           : std_logic_vector(G_DWIDTH - 1 downto 0) := (others => '0');
signal i_calc4_3H          : std_logic_vector(G_DWIDTH - 1 downto 0) := (others => '0');
signal i_calc4_3L          : std_logic_vector(G_DWIDTH - 1 downto 0) := (others => '0');
signal i_calc4_4H          : std_logic_vector(G_DWIDTH - 1 downto 0) := (others => '0');
signal i_calc4_4L          : std_logic_vector(G_DWIDTH - 1 downto 0) := (others => '0');

signal i_calc5_1           : std_logic_vector(G_DWIDTH - 1 downto 0) := (others => '0');
signal i_calc5_2H          : std_logic_vector(G_DWIDTH - 1 downto 0) := (others => '0');
signal i_calc5_2L          : std_logic_vector(G_DWIDTH - 1 downto 0) := (others => '0');
signal i_calc5_3           : std_logic_vector(G_DWIDTH - 1 downto 0) := (others => '0');

signal i_calc6_1H          : std_logic_vector(G_DWIDTH - 1 downto 0) := (others => '0');
signal i_calc6_1L          : std_logic_vector(G_DWIDTH - 1 downto 0) := (others => '0');
signal i_calc6_2           : std_logic_vector(G_DWIDTH - 1 downto 0) := (others => '0');

signal i_calc7_1           : std_logic_vector(G_DWIDTH - 1 downto 0) := (others => '0');
signal i_calc7_2H          : std_logic_vector(G_DWIDTH - 1 downto 0) := (others => '0');
signal i_calc7_2L          : std_logic_vector(G_DWIDTH - 1 downto 0) := (others => '0');

--signal i_calc8_1H          : std_logic_vector(G_DWIDTH - 1 downto 0);
signal i_calc8_1L          : std_logic_vector(G_DWIDTH - 1 downto 0) := (others => '0');




begin --architecture behavioral

p_out_dwnp_data <= std_logic_vector(i_calc8_1L);
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
      if i_matrix(0)(0) >= i_matrix(0)(1) then
        i_calc0_1H <= i_matrix(0)(0);
        i_calc0_1L <= i_matrix(0)(1);
      else
        i_calc0_1H <= i_matrix(0)(1);
        i_calc0_1L <= i_matrix(0)(0);
      end if;

      i_calc0_2 <= i_matrix(0)(2);

      if i_matrix(1)(0) >= i_matrix(1)(1) then
        i_calc0_3H <= i_matrix(1)(0);
        i_calc0_3L <= i_matrix(1)(1);
      else
        i_calc0_3H <= i_matrix(1)(1);
        i_calc0_3L <= i_matrix(1)(0);
      end if;

      i_calc0_4 <= i_matrix(1)(2);

      if i_matrix(2)(0) >= i_matrix(2)(1) then
        i_calc0_5H <= i_matrix(2)(0);
        i_calc0_5L <= i_matrix(2)(0);
      else
        i_calc0_5H <= i_matrix(2)(1);
        i_calc0_5L <= i_matrix(2)(1);
      end if;

      i_calc0_6 <= i_matrix(2)(2);


      --------------------
      --1
      --------------------
      i_calc1_1 <=i_calc0_1H;

      if i_calc0_1L >= i_calc0_2 then
        i_calc1_2H <= i_calc0_1L;
        i_calc1_2L <= i_calc0_2;
      else
        i_calc1_2H <= i_calc0_2;
        i_calc1_2L <= i_calc0_1L;
      end if;

      i_calc1_3 <= i_calc0_3H;

      if i_calc0_3L >= i_calc0_4 then
        i_calc1_4H <= i_calc0_3L;
        i_calc1_4L <= i_calc0_4;
      else
        i_calc1_4H <= i_calc0_4;
        i_calc1_4L <= i_calc0_3L;
      end if;

      i_calc1_5 <= i_calc0_5H;

      if i_calc0_5L >= i_calc0_6 then
        i_calc1_6H <= i_calc0_5L;
        i_calc1_6L <= i_calc0_6;
      else
        i_calc1_6H <= i_calc0_6;
        i_calc1_6L <= i_calc0_5L;
      end if;


      --------------------
      --2
      --------------------
      if i_calc1_1 >= i_calc1_2H then
        i_calc2_1H <= i_calc1_1;
        i_calc2_1L <= i_calc1_2H;
      else
        i_calc2_1H <= i_calc1_2H;
        i_calc2_1L <= i_calc1_1;
      end if;

      i_calc2_2 <= i_calc1_2L;

      if i_calc1_3 >= i_calc1_4H then
        i_calc2_3H <= i_calc1_3;
        i_calc2_3L <= i_calc1_4H;
      else
        i_calc2_3H <= i_calc1_4H;
        i_calc2_3L <= i_calc1_3;
      end if;

      i_calc2_4 <= i_calc1_4L;

      if i_calc1_5 >= i_calc1_6H then
        i_calc2_5H <= i_calc1_5;
        i_calc2_5L <= i_calc1_6H;
      else
        i_calc2_5H <= i_calc1_6H;
        i_calc2_5L <= i_calc1_5;
      end if;

      i_calc2_6 <= i_calc1_6L;


      --------------------
      --3
      --------------------
      if i_calc2_1H >= i_calc2_3H then
        i_calc3_1H <= i_calc2_1H;
        i_calc3_1L <= i_calc2_3H;
      else
        i_calc3_1H <= i_calc2_3H;
        i_calc3_1L <= i_calc2_1H;
      end if;

      i_calc3_2 <= i_calc2_2;

      if i_calc2_1L >= i_calc2_3L then
        i_calc3_3H <= i_calc2_1L;
        i_calc3_3L <= i_calc2_3L;
      else
        i_calc3_3H <= i_calc2_3L;
        i_calc3_3L <= i_calc2_1L;
      end if;

      i_calc3_4 <= i_calc2_5H;

      if i_calc2_4 >= i_calc2_6 then
        i_calc3_5H <= i_calc2_4;
        i_calc3_5L <= i_calc2_6;
      else
        i_calc3_5H <= i_calc2_6;
        i_calc3_5L <= i_calc2_4;
      end if;

      i_calc3_6 <= i_calc2_5L;


      --------------------
      --4
      --------------------
      if i_calc3_1L >= i_calc3_4 then
        i_calc4_1H <= i_calc3_1L;
        i_calc4_1L <= i_calc3_4;
      else
        i_calc4_1H <= i_calc3_4;
        i_calc4_1L <= i_calc3_1L;
      end if;

      i_calc4_2 <= i_calc3_3H;

      if i_calc3_3L >= i_calc3_6 then
        i_calc4_3H <= i_calc3_3L;
        i_calc4_3L <= i_calc3_6;
      else
        i_calc4_3H <= i_calc3_6;
        i_calc4_3L <= i_calc3_3L;
      end if;

      if i_calc3_5H >= i_calc3_2 then
        i_calc4_4H <= i_calc3_5H;
        i_calc4_4L <= i_calc3_2;
      else
        i_calc4_4H <= i_calc3_2;
        i_calc4_4L <= i_calc3_5H;
      end if;


      --------------------
      --5
      --------------------
      i_calc5_1 <= i_calc4_1L;

      if i_calc4_2 >= i_calc4_3H then
        i_calc5_2H <= i_calc4_2;
        i_calc5_2L <= i_calc4_3H;
      else
        i_calc5_2H <= i_calc4_3H;
        i_calc5_2L <= i_calc4_2;
      end if;

      i_calc5_3 <= i_calc4_4H;


      --------------------
      --6
      --------------------
      if i_calc5_1 >= i_calc5_2L then
        i_calc6_1H <= i_calc5_1;
        i_calc6_1L <= i_calc5_2L;
      else
        i_calc6_1H <= i_calc5_2L;
        i_calc6_1L <= i_calc5_1;
      end if;

      i_calc6_2 <= i_calc5_3;


      --------------------
      --7
      --------------------
      i_calc7_1 <= i_calc6_1H;

      if i_calc6_1L >= i_calc6_2 then
        i_calc7_2H <= i_calc6_1L;
        i_calc7_2L <= i_calc6_2;
      else
        i_calc7_2H <= i_calc6_2;
        i_calc7_2L <= i_calc6_1L;
      end if;


      --------------------
      --8
      --------------------
      if i_calc7_1 >= i_calc7_2H then
--        i_calc8_1H <= i_calc7_1;
        i_calc8_1L <= i_calc7_2H;
      else
--        i_calc8_1H <= i_calc7_2H;
        i_calc8_1L <= i_calc7_1;
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
