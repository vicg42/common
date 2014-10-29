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
signal i_buf_en            : std_logic_vector(0 to C_VFILTER_RANG - 1);
type TSR_adr is array (0 to C_VFILTER_RANG - 1) of unsigned(i_buf_adr'range);
signal sr_buf_adr          : TSR_adr;
signal sr_buf_wr           : std_logic_vector(0 to C_VFILTER_RANG - 1);

type TSR is array (0 to (C_VFILTER_RANG - 2) + (C_VFILTER_RANG - 1)) of std_logic_vector(p_in_upp_data'range);
type TBuf_do is record
do : TSR;
end record;
type TSR_bufs is array (0 to C_VFILTER_RANG - 1) of TBuf_do;
signal sr_buf              : TSR_bufs;

signal i_sol               : std_logic := '0';
signal sr_sol              : std_logic_vector(0 to C_VFILTER_RANG - 1) := (others => '0');
signal i_eol               : std_logic := '0';
signal sr_eol              : std_logic_vector(0 to C_VFILTER_RANG - 1) := (others => '0');--3x3

signal i_dwnp_en           : std_logic;
signal sr_dwnp_en          : std_logic;
signal i_cntdly_line       : unsigned(2 downto 0);
signal i_cntdly_pix        : unsigned(2 downto 0);
signal i_eol_en            : std_logic;
signal i_eof_en            : std_logic;
signal i_eof               : std_logic;
signal i_cleanup           : std_logic;

signal i_matrix            : TMatrix;
signal i_matrix_wr         : std_logic := '0';

begin --architecture behavioral


p_out_matrix <= i_matrix;
p_out_dwnp_wr <= i_matrix_wr and not p_in_dwnp_rdy_n;
p_out_dwnp_eof <= i_matrix_wr and not p_in_dwnp_rdy_n and i_eof and sr_eol(sr_eol'high);--3x3


--------------------------------------------------------
--
--------------------------------------------------------
i_gnd_adrb <= (others => '0');
i_gnd_dinb <= (others => '0');

p_out_upp_rdy_n <= i_eof_en or i_eol_en;

i_buf_wr <= (p_in_upp_wr or (i_eof_en and not i_eol_en));

sr_buf_adr(C_VFILTER_RANG - 1) <= i_buf_adr;
i_buf_do(C_VFILTER_RANG - 1) <= p_in_upp_data;
sr_buf_wr(C_VFILTER_RANG - 1) <= i_buf_wr;

gen_buf : for i in C_VFILTER_RANG - 2 downto 0  generate begin

process(p_in_clk)
begin
  if rising_edge(p_in_clk) then
    if p_in_rst = '1' or (i_cleanup = '1' and (i_eol = '1' or sr_eol(sr_eol'high) = '1')) then
        sr_buf_wr(i) <= '0';
        sr_buf_adr(i) <= (others => '0');
    else
        sr_buf_adr(i) <= sr_buf_adr(i + 1);
        sr_buf_wr(i) <= sr_buf_wr(i + 1);
    end if;
  end if;
end process;

i_buf_en(i + 1) <= sr_buf_wr(i + 1) and not p_in_dwnp_rdy_n;

m_buf : vbufpr
port map(
--READ FIRST
addra=> std_logic_vector(sr_buf_adr(i + 1)),
dina => i_buf_do(i + 1),
douta=> i_buf_do(i),
ena  => i_buf_en(i + 1),
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

i_sol <= not OR_reduce(i_buf_adr) and i_buf_wr;
i_eol <= i_buf_wr when i_buf_adr = RESIZE((UNSIGNED(p_in_cfg_pix_count) - 1), i_buf_adr'length) else '0';

process(p_in_clk)
begin
  if rising_edge(p_in_clk) then
    if p_in_rst = '1' or (i_cleanup = '1' and (i_eol = '1' or sr_eol(sr_eol'high) = '1')) then
        sr_sol <= (others => '0');
        sr_eol <= (others => '0');
    else
        if p_in_dwnp_rdy_n = '0' then
          if i_buf_wr = '1' or i_eol_en = '1' then
            sr_sol <= i_sol & sr_sol(0 to sr_sol'high - 1);
            sr_eol <= i_eol & sr_eol(0 to sr_eol'high - 1);--3x3
          end if;
        end if;
    end if;
  end if;
end process;

process(p_in_clk)
begin
  if rising_edge(p_in_clk) then
    if p_in_rst = '1' then
        for y in 0 to sr_buf'length - 1 loop
          for x in 0 to sr_buf(0).do'length - 1 loop
            sr_buf(y).do(x) <= (others => '0');
          end loop;
        end loop;
    else
        if p_in_dwnp_rdy_n = '0' then
          if i_buf_wr = '1' or i_eol_en = '1' then
            for i in 0 to sr_buf'length - 1 loop
              sr_buf(i).do <= i_buf_do(i) & sr_buf(i).do(0 to sr_buf(i).do'high - 1);
            end loop;
          end if;
        end if;
    end if;
  end if;
end process;

i_matrix(0)(C_VFILTER_RANG - 1) <= UNSIGNED(i_buf_do(0))  ;
gen_matrix_y0 : for x in 0 to C_VFILTER_RANG - 2 generate begin
i_matrix(0)(C_VFILTER_RANG - 2 - x) <= UNSIGNED(sr_buf(0).do(x));
end generate gen_matrix_y0;

gen_matrix_y : for y in 1 to C_VFILTER_RANG - 1 generate begin
  gen_matrix_x : for x in 0 to C_VFILTER_RANG - 1 generate begin
    i_matrix(y)(x) <= UNSIGNED(sr_buf(y).do(sr_buf(y).do'high - (C_VFILTER_RANG - 1  - y)  - x));
  end generate gen_matrix_x;
end generate gen_matrix_y;

--i_matrix(0)(2) <= (others => '0') when sr_eol(sr_eol'high) = '1' or sr_dwnp_en = '0' else UNSIGNED(i_buf_do(0))  ;
--i_matrix(0)(1) <= (others => '0') when                              sr_dwnp_en = '0' else UNSIGNED(sr_buf(0).do(0));
--i_matrix(0)(0) <= (others => '0') when sr_sol(sr_sol'high) = '1' or sr_dwnp_en = '0' else UNSIGNED(sr_buf(0).do(1));
--
--i_matrix(1)(2) <= (others => '0') when sr_eol(sr_eol'high) = '1' else UNSIGNED(sr_buf(1).do(0));
--i_matrix(1)(1) <= UNSIGNED(sr_buf(1).do(1));
--i_matrix(1)(0) <= (others => '0') when sr_sol(sr_sol'high) = '1' else UNSIGNED(sr_buf(1).do(2));
--
--i_matrix(2)(2) <= (others => '0') when sr_eol(sr_eol'high) = '1' or i_eof = '1' else UNSIGNED(sr_buf(2).do(1));
--i_matrix(2)(1) <= (others => '0') when                              i_eof = '1' else UNSIGNED(sr_buf(2).do(2));
--i_matrix(2)(0) <= (others => '0') when sr_sol(sr_sol'high) = '1' or i_eof = '1' else UNSIGNED(sr_buf(2).do(3));

process(p_in_clk)
begin
  if rising_edge(p_in_clk) then
    if p_in_dwnp_rdy_n = '0' then
      if (i_eof_en = '1' and sr_eol(sr_eol'high) = '1' and i_cntdly_line = TO_UNSIGNED(CI_DLY_LINE, i_cntdly_line'length))
       or (i_eol_en = '1' and sr_eol(sr_eol'high) = '1') then
        i_matrix_wr <= '0';

      elsif i_dwnp_en = '1' and i_buf_wr = '1' and i_buf_adr = TO_UNSIGNED((C_VFILTER_RANG - 2) * 2, i_buf_adr'length) then --TO_UNSIGNED(2, i_buf_adr'length) --3x3
--      elsif i_dwnp_en = '1' and i_buf_wr = '1' and i_buf_adr = TO_UNSIGNED(5, i_buf_adr'length) then --TO_UNSIGNED(2, i_buf_adr'length) --5x5
        i_matrix_wr <= '1';
      end if;
    end if;
  end if;
end process;

process(p_in_clk)
begin
  if rising_edge(p_in_clk) then
    if p_in_rst = '1' then
      i_buf_adr <= (others => '0');
      sr_dwnp_en <= '0';
      i_dwnp_en <= '0';
      i_cntdly_pix <= ( others => '0');
      i_cntdly_line <= (others => '0');
      i_eol_en <= '0';
      i_eof_en <= '0'; i_eof <= '0'; i_cleanup <= '0';

    else
      if p_in_dwnp_rdy_n = '0' then

        if i_buf_wr = '1' then
          if i_buf_adr = RESIZE((UNSIGNED(p_in_cfg_pix_count) - 1), i_buf_adr'length) then
            i_buf_adr <= (others => '0');
          else
            i_buf_adr <= i_buf_adr + 1;
          end if;
        end if;


        if i_eol_en = '0' then
          if (p_in_upp_wr = '1' and i_buf_adr = RESIZE((UNSIGNED(p_in_cfg_pix_count) - 1), i_buf_adr'length) and i_eof_en = '0')
            or (sr_eol(sr_eol'high) = '1' and i_eof_en = '1') then
            i_eol_en <= '1';
          end if;
        else
          if i_cntdly_pix = TO_UNSIGNED(sr_eol'high, i_cntdly_pix'length) then --3x3
            i_cntdly_pix <= ( others => '0');
            i_eol_en <= '0';
          else
            i_cntdly_pix <= i_cntdly_pix + 1;
          end if;
        end if;


        if i_dwnp_en = '1' then
          if p_in_upp_wr = '1' and p_in_upp_eof = '1' then
            i_eof_en <= '1';

          else
            if sr_eol(sr_eol'high) = '1' then
              sr_dwnp_en <= '1';
            end if;

            if i_eof_en = '1' then
              if i_buf_adr = RESIZE((UNSIGNED(p_in_cfg_pix_count) - 1), i_buf_adr'length) then
                if i_cntdly_line = TO_UNSIGNED(CI_DLY_LINE, i_cntdly_line'length) then
                  i_cntdly_line <= ( others => '0');
                  i_dwnp_en <= '0'; i_eof_en <= '0'; i_cleanup <= '0';
                  sr_dwnp_en <= '0';
                else
                  i_cntdly_line <= i_cntdly_line + 1;

                  if i_cntdly_line = TO_UNSIGNED(CI_DLY_LINE - 1, i_cntdly_line'length) then
                  i_cleanup <= '1';
                  end if;

                end if;

              end if;

              if sr_eol(sr_eol'high) = '1' then
                if i_cntdly_line = TO_UNSIGNED((C_VFILTER_RANG - 2) - 1, i_cntdly_line'length) then
                  i_eof <= '1';
                end if;
              end if;

            end if;

          end if;

        else
          i_eof <= '0'; sr_dwnp_en <= '0';

          if sr_eol(sr_eol'high) = '1' then
            if i_cntdly_line = TO_UNSIGNED((C_VFILTER_RANG - 2) - 1, i_cntdly_line'length) then --3x3 --TO_UNSIGNED(0, i_cntdly_line'length) then --
--            if i_cntdly_line = TO_UNSIGNED(1, i_cntdly_line'length) then --5x5 --
              i_cntdly_line <= (others => '0');
              i_dwnp_en <= '1';
            else
              i_cntdly_line <= i_cntdly_line + 1;
            end if;
          end if;

        end if;

    end if;

  end if;
  end if;
end process;


--##################################
--DBG
--##################################
p_out_tst(31 downto 1) <= (others=>'0');
p_out_tst(0) <= sr_sol(sr_sol'high) or i_eol_en or sr_dwnp_en;

end architecture behavioral;
