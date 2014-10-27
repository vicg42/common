-------------------------------------------------------------------------
-- Company     : Yansar
-- Engineer    : Golovachenko Victor
--
-- Create Date : 24.10.2014 10:28:44
-- Module Name : vfilter_core
--
-- Expample :
-- LINI0 : PIX(0)=2 , PIX(1)=4 , PIX(2)=6
-- LINI1 : PIX(0)=14, PIX(1)=16, PIX(2)=18
-- LINI2 : PIX(0)=26, PIX(1)=28, PIX(2)=2A
-- ====================
-- matrix(0)(0)=2 , matrix(0)(1)=4 , matrix(0)(2)=6
-- matrix(1)(0)=14, matrix(1)(1)=16, matrix(1)(2)=18
-- matrix(2)(0)=26, matrix(2)(1)=28, matrix(2)(2)=2A
--
--
-------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library unisim;
use unisim.vcomponents.all;

library work;
use work.vicg_common_pkg.all;
use work.reduce_pack.all;
use work.vfilter_core_pkg.all;

entity vfilter_core is
generic(
G_BRAM_AWIDTH : integer := 12;
G_SIM : string:="OFF"
);
port(
-------------------------------
--CFG
-------------------------------
p_in_cfg_pix_count : in    std_logic_vector(15 downto 0);--Кол-во пиксел/4 т.к p_in_upp_data=32bit
p_in_cfg_init      : in    std_logic;                    --Инициализация. Сброс счетчика адреса BRAM

----------------------------
--Upstream Port (IN)
----------------------------
p_in_upp_data      : in    std_logic_vector(7 downto 0);
p_in_upp_wr        : in    std_logic;
p_in_upp_eol       : in    std_logic;
p_in_upp_eof       : in    std_logic;
p_out_upp_rdy_n    : out   std_logic;

----------------------------
--Downstream Port (OUT)
----------------------------
p_out_matrix       : out   TMatrix;
p_out_dwnp_wr      : out   std_logic;
p_out_dwnp_eof     : out   std_logic;
p_in_dwnp_rdy_n    : in    std_logic;
--p_out_line_evod    : out   std_logic;
--p_out_pix_evod     : out   std_logic;

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
end entity vfilter_core;

architecture behavioral of vfilter_core is

component vbufpr
port(
--read first
addra: in  std_logic_vector(G_BRAM_AWIDTH - 1 downto 0);
dina : in  std_logic_vector(7 downto 0);
douta: out std_logic_vector(7 downto 0);
ena  : in  std_logic;
wea  : in  std_logic_vector(0 downto 0);
clka : in  std_logic;
rsta : in  std_logic;

--write first
addrb: in  std_logic_vector(G_BRAM_AWIDTH - 1 downto 0);
dinb : in  std_logic_vector(7 downto 0);
doutb: out std_logic_vector(7 downto 0);
enb  : in  std_logic;
web  : in  std_logic_vector(0 downto 0);
clkb : in  std_logic;
rstb : in  std_logic
);
end component vbufpr;

signal i_gnd_adrb          : std_logic_vector(G_BRAM_AWIDTH - 1 downto 0);
signal i_gnd_dinb          : std_logic_vector(p_in_upp_data'range);

constant CI_DLY_LINE : integer := 1;

signal i_buf_adr           : unsigned(G_BRAM_AWIDTH - 1 downto 0);
type TDBufs is array (0 to C_VFILTER_RANG - 1) of std_logic_vector(p_in_upp_data'range);
signal i_buf_do            : TDBufs;
signal i_buf_wr            : std_logic;

type TSR2 is array (0 to C_VFILTER_RANG - 2 + 0) of std_logic_vector(p_in_upp_data'range);
type TSR3 is array (0 to C_VFILTER_RANG - 2 + 1) of std_logic_vector(p_in_upp_data'range);
type TSR4 is array (0 to C_VFILTER_RANG - 2 + 2) of std_logic_vector(p_in_upp_data'range);
signal sr_buf0_do          : TSR4 := ((others => '0'), (others => '0'), (others => '0'), (others => '0'));
signal sr_buf1_do          : TSR3 := ((others => '0'), (others => '0'), (others => '0'));
signal sr_buf2_do          : TSR2 := ((others => '0'), (others => '0'));

signal i_sol               : std_logic := '0';
signal sr_sol              : std_logic_vector(0 to C_VFILTER_RANG - 1) := (others => '0');
signal i_eol               : std_logic := '0';
signal sr_eol              : std_logic_vector(0 to C_VFILTER_RANG - 1) := (others => '0');

signal i_dwnp_en           : std_logic;
signal i_sof_n             : std_logic;
signal i_eof_en            : std_logic;
signal i_eof               : std_logic;
signal i_cnteof            : unsigned(CI_DLY_LINE - 1 downto 0);

signal i_matrix            : TMatrix;
signal i_matrix_wr         : std_logic := '0';

--signal i_pix_evod          : std_logic;
--signal i_line_evod         : std_logic;



begin --architecture behavioral


p_out_matrix <= i_matrix;
p_out_dwnp_wr <= i_matrix_wr and not p_in_dwnp_rdy_n;--i_matrix_wr and i_buf_wr;
p_out_dwnp_eof <= i_matrix_wr and i_eof and sr_eol(2) and not p_in_dwnp_rdy_n;
--p_out_line_evod <= i_line_evod;
--p_out_pix_evod  <= i_pix_evod;


--------------------------------------------------------
--
--------------------------------------------------------
i_gnd_adrb <= (others => '0');
i_gnd_dinb <= (others => '0');

p_out_upp_rdy_n <= i_eof_en;

--Буфера строк:
--lineN : Текущая строка
i_buf_do(0) <= p_in_upp_data;
i_buf_wr <= (p_in_upp_wr or i_eof_en) and not p_in_dwnp_rdy_n;

gen_buf : for i in 0 to C_VFILTER_RANG - 2 generate begin
m_buf : vbufpr
port map(
--READ FIRST
addra=> std_logic_vector(i_buf_adr),
dina => i_buf_do(i + 0),
douta=> i_buf_do(i + 1),
ena  => i_buf_wr,
wea  => "1",
clka => p_in_clk,
rsta => p_in_rst,

--WRITE FIRST
addrb=> i_gnd_adrb,
dinb => i_gnd_dinb,
doutb=> open,
enb  => '0',
web  => "0",
clkb => p_in_clk,
rstb => p_in_rst
);

end generate gen_buf;

i_sol <= not OR_reduce(i_buf_adr);
i_eol <= p_in_upp_eol; --'1' when i_buf_adr = RESIZE((UNSIGNED(p_in_cfg_pix_count) - 1), i_buf_adr'length) else '0';

process(p_in_clk)
begin
  if rising_edge(p_in_clk) then
    if p_in_dwnp_rdy_n = '0' then
      if i_buf_wr = '1' then
        sr_buf0_do <= i_buf_do(0) & sr_buf0_do(0 to sr_buf0_do'high - 1);
        sr_buf1_do <= i_buf_do(1) & sr_buf1_do(0 to sr_buf1_do'high - 1);
        sr_buf2_do <= i_buf_do(2) & sr_buf2_do(0 to sr_buf2_do'high - 1);

        sr_sol <= i_sol & sr_sol(0 to C_VFILTER_RANG - 2);
        sr_eol <= i_eol & sr_eol(0 to C_VFILTER_RANG - 2);
      end if;
    end if;
  end if;
end process;

i_matrix(0)(2) <= UNSIGNED(i_buf_do(2))  ;
i_matrix(0)(1) <= UNSIGNED(sr_buf2_do(0));
i_matrix(0)(0) <= UNSIGNED(sr_buf2_do(1));

i_matrix(1)(2) <= UNSIGNED(sr_buf1_do(0));
i_matrix(1)(1) <= UNSIGNED(sr_buf1_do(1));
i_matrix(1)(0) <= UNSIGNED(sr_buf1_do(2));

i_matrix(2)(2) <= UNSIGNED(sr_buf0_do(1));
i_matrix(2)(1) <= UNSIGNED(sr_buf0_do(2));
i_matrix(2)(0) <= UNSIGNED(sr_buf0_do(3));

process(p_in_clk)
begin
  if rising_edge(p_in_clk) then
    if p_in_dwnp_rdy_n = '0' then
      if i_buf_wr = '1' then
        if i_eof_en = '1' and sr_eol(2) = '1' and i_cnteof = TO_UNSIGNED(CI_DLY_LINE, i_cnteof'length) then
        i_matrix_wr <= '0';
        elsif i_dwnp_en = '1' and sr_eol(2) = '1' then
        i_matrix_wr <= '1';
        end if;
      end if;
    end if;
  end if;
end process;

process(p_in_clk)
begin
  if rising_edge(p_in_clk) then
    if p_in_rst = '1' then
      i_buf_adr <= (others => '0');
      i_eof_en <= '0'; i_eof <= '0'; i_cnteof <= (others => '0');
      i_sof_n <= '0';
      i_dwnp_en <= '0';

    else
      if p_in_dwnp_rdy_n = '0' then

        if i_buf_wr = '1' then
          if p_in_upp_eol = '1' then --i_buf_adr = RESIZE((UNSIGNED(p_in_cfg_pix_count) - 1), i_buf_adr'length) then
            i_buf_adr <= (others => '0');
          else
            i_buf_adr <= i_buf_adr + 1;
          end if;

          if i_sof_n = '1' then
            if p_in_upp_eof = '1' then
              i_eof_en <= '1';

            else
              if i_eof_en = '1' then
                if p_in_upp_eol = '1' then --i_buf_adr = RESIZE((UNSIGNED(p_in_cfg_pix_count) - 1), i_buf_adr'length) then
                  if i_cnteof = TO_UNSIGNED(CI_DLY_LINE, i_cnteof'length) then
                    i_cnteof <= ( others => '0');
                    i_dwnp_en <= '0'; i_eof_en <= '0'; i_eof <= '0';
                    i_sof_n <= '0';
                  else
                    i_cnteof <= i_cnteof + 1;

                    if i_cnteof = TO_UNSIGNED(CI_DLY_LINE - 1, i_cnteof'length) then
                    i_eof <= '1';
                    end if;

                  end if;

                end if;
              end if;
            end if;

          else

            if p_in_upp_eol = '1' then --i_buf_adr = RESIZE((UNSIGNED(p_in_cfg_pix_count) - 1), i_buf_adr'length) then
              if i_cnteof = TO_UNSIGNED(CI_DLY_LINE - 1, i_cnteof'length) then
                i_cnteof <= (others => '0');
                i_dwnp_en <= '1';
                i_sof_n <= i_dwnp_en;
              else
                i_cnteof <= i_cnteof + 1;
              end if;
            end if;

          end if;

        end if; --if i_buf_wr = '1' then
    end if;

  end if;
  end if;
end process;

--process(p_in_clk)
--begin
--  if rising_edge(p_in_clk) then
--  if p_in_rst = '1' then
--    i_pix_evod <= '0';
--    i_line_evod <= '0';
--  else
--    if p_in_dwnp_rdy_n = '0' then
--      if i_dwnp_en = '0' then
--        i_pix_evod <= '0';
--        i_line_evod <= '0';
--      else
--        if i_matrix_wr = '1' and i_buf_wr = '1' then
--          i_pix_evod <= not i_pix_evod;
--
--          if sr_eol(2) = '1' then
--            i_line_evod <= not i_line_evod;
--          end if;
--        end if;
--      end if;
--    end if;
--  end if;
--  end if;
--end process;


--##################################
--DBG
--##################################
p_out_tst(31 downto 1) <= (others=>'0');
p_out_tst(0) <= sr_sol(2) or i_line_evod or i_pix_evod;

end architecture behavioral;
