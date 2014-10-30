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

--constant CI_OPT : integer := 0; --3x3
--constant CI_OPT : integer := 1; --5x5
--constant CI_OPT : integer := 2; --7x7
constant CI_OPT : integer := selval(0, selval(1, 2, C_VFILTER_RANG = 5), C_VFILTER_RANG = 3);

signal i_gnd_adrb          : std_logic_vector(G_BRAM_AWIDTH - 1 downto 0);
signal i_gnd_dinb          : std_logic_vector(p_in_upp_data'range);

signal i_buf_adr           : unsigned(G_BRAM_AWIDTH - 1 downto 0);
type TDBufs is array (0 to C_VFILTER_RANG - 1) of std_logic_vector(p_in_upp_data'range);
signal i_buf_do            : TDBufs;
signal i_buf_wr            : std_logic;
signal i_buf_en            : std_logic_vector(0 to C_VFILTER_RANG - 1);
type TSR_adr is array (0 to C_VFILTER_RANG - 1) of unsigned(i_buf_adr'range);
signal sr_buf_adr          : TSR_adr;
signal sr_buf_wr           : std_logic_vector(C_VFILTER_RANG - 1 downto 0);

type TSR is array (0 to C_VFILTER_RANG + CI_OPT + 1) of std_logic_vector(p_in_upp_data'range);
type TBuf_do is record do : TSR; end record;
type TSR_bufs is array (0 to C_VFILTER_RANG - 1) of TBuf_do;
signal sr_buf              : TSR_bufs;

signal i_dwnp_en           : std_logic;
signal sr_dwnp_en          : std_logic;
signal i_dwnp_eof_en       : std_logic;

signal i_eof_en            : std_logic;
signal i_eof_line_en       : std_logic;
signal i_eof               : std_logic;

signal i_cntline           : unsigned(1 downto 0);

signal i_matrix            : TMatrix;
signal sr_matrix_wr        : std_logic_vector(0 to (selval(1, CI_OPT, CI_OPT = 0)));

signal sr_sol              : std_logic_vector(0 to C_VFILTER_RANG - 1 + CI_OPT);
signal sr_eol              : std_logic_vector(0 to C_VFILTER_RANG - 1 + CI_OPT);
signal i_eol_en            : std_logic;
signal i_eol               : std_logic;

type TFsm_state is (
S_SOF_WAIT,
S_SOF_LINE,
S_EOF_WAIT,
S_EOF_LINE
);
signal i_fsm_ctrl          : TFsm_state;


begin --architecture behavioral


p_out_matrix <= i_matrix;
p_out_dwnp_wr <= i_dwnp_en and sr_matrix_wr(selval(0, sr_matrix_wr'high, CI_OPT = 0)) and not p_in_dwnp_rdy_n;
p_out_dwnp_eof <= sr_matrix_wr(selval(0, sr_matrix_wr'high, CI_OPT = 0)) and not p_in_dwnp_rdy_n and sr_eol(sr_eol'high) and i_eof;

i_matrix(0)(C_VFILTER_RANG - 1) <= UNSIGNED(i_buf_do(0))  ;
gen_matrix_y0 : for x in 0 to C_VFILTER_RANG - 2 generate begin
i_matrix(0)(C_VFILTER_RANG - 2 - x) <= UNSIGNED(sr_buf(0).do(x));
end generate gen_matrix_y0;

gen_matrix_y : for y in 1 to C_VFILTER_RANG - 1 generate begin
gen_matrix_x : for x in 0 to C_VFILTER_RANG - 1 generate begin
i_matrix(y)(x) <= UNSIGNED(sr_buf(y).do(sr_buf(y).do'high - (C_VFILTER_RANG - 1  - y)  - x));
end generate gen_matrix_x;
end generate gen_matrix_y;

----------------------------------------------------
--gen_matrix_y0 : for y in 0 to 0 generate begin
--i_matrix(y)(C_VFILTER_RANG - 1) <= (others => '0') when sr_eol(sr_eol'high) = '1' or sr_dwnp_en = '0' else
--  UNSIGNED(i_buf_do(y));
--
--gen_matrix_x : for x in 0 to C_VFILTER_RANG - 3 generate begin
--i_matrix(y)(C_VFILTER_RANG - 2 - x) <= (others => '0') when sr_dwnp_en = '0' else
--  UNSIGNED(sr_buf(y).do(x));
--end generate gen_matrix_x;
--
--gen_matrix_xmax : for x in C_VFILTER_RANG - 2 to C_VFILTER_RANG - 2 generate begin
--i_matrix(y)(C_VFILTER_RANG - 2 - x) <= (others => '0') when sr_sol(sr_sol'high) = '1' or sr_dwnp_en = '0' else
--  UNSIGNED(sr_buf(y).do(x));
--end generate gen_matrix_xmax;
--end generate gen_matrix_y0;
--
----------------------------------------------------
--gen_matrix_y : for y in 1 to C_VFILTER_RANG - 2 generate begin
--gen_matrix_x0 : for x in 0 to 0 generate begin
--i_matrix(y)(x) <= (others => '0') when sr_sol(sr_sol'high) = '1' else
--  UNSIGNED(sr_buf(y).do(sr_buf(y).do'high - (C_VFILTER_RANG - 1  - y)  - x));
--end generate gen_matrix_x0;
--
--gen_matrix_x : for x in 1 to C_VFILTER_RANG - 2 generate begin
--i_matrix(y)(x) <= UNSIGNED(sr_buf(y).do(sr_buf(y).do'high - (C_VFILTER_RANG - 1  - y)  - x));
--end generate gen_matrix_x;
--
--gen_matrix_xmax : for x in C_VFILTER_RANG - 1 to C_VFILTER_RANG - 1 generate begin
--i_matrix(y)(x) <= (others => '0') when sr_eol(sr_eol'high) = '1' else
--  UNSIGNED(sr_buf(y).do(sr_buf(y).do'high - (C_VFILTER_RANG - 1  - y)  - x));
--end generate gen_matrix_xmax;
--end generate gen_matrix_y;
--
----------------------------------------------------
--gen_matrix_ymax : for y in C_VFILTER_RANG - 1 to C_VFILTER_RANG - 1 generate begin
--gen_matrix_x0 : for x in 0 to 0 generate begin
--i_matrix(y)(x) <= (others => '0') when sr_sol(sr_sol'high) = '1' or i_eof = '1' else
--  UNSIGNED(sr_buf(y).do(sr_buf(y).do'high - (C_VFILTER_RANG - 1  - y)  - x));
--end generate gen_matrix_x0;
--
--gen_matrix_x : for x in 1 to C_VFILTER_RANG - 2 generate begin
--i_matrix(y)(x) <= (others => '0') when i_eof = '1' else
--  UNSIGNED(sr_buf(y).do(sr_buf(y).do'high - (C_VFILTER_RANG - 1  - y)  - x));
--end generate gen_matrix_x;
--
--gen_matrix_xmax : for x in C_VFILTER_RANG - 1 to C_VFILTER_RANG - 1 generate begin
--i_matrix(y)(x) <= (others => '0') when sr_eol(sr_eol'high) = '1' or i_eof = '1' else
--  UNSIGNED(sr_buf(y).do(sr_buf(y).do'high - (C_VFILTER_RANG - 1  - y)  - x));
--end generate gen_matrix_xmax;
--end generate gen_matrix_ymax;
----------------------------------------------------

--when sr_sol(sr_sol'high) = '1' or sr_eol(sr_eol'high) = '1' or sr_dwnp_en = '0' or i_eof = '1'

--i_matrix(0)(2) <= (others => '0') when sr_eol(sr_eol'high) = '1' or sr_dwnp_en = '0' else UNSIGNED(i_buf_do(0))    ;
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


--i_matrix(0)(2) <= UNSIGNED(i_buf_do(0))    ;
--i_matrix(0)(1) <= UNSIGNED(sr_buf(0).do(0));
--i_matrix(0)(0) <= UNSIGNED(sr_buf(0).do(1));
--
--i_matrix(1)(2) <= UNSIGNED(sr_buf(1).do(0));
--i_matrix(1)(1) <= UNSIGNED(sr_buf(1).do(1));
--i_matrix(1)(0) <= UNSIGNED(sr_buf(1).do(2));
--
--i_matrix(2)(2) <= UNSIGNED(sr_buf(2).do(1));
--i_matrix(2)(1) <= UNSIGNED(sr_buf(2).do(2));
--i_matrix(2)(0) <= UNSIGNED(sr_buf(2).do(3));

process(p_in_clk)
begin
if rising_edge(p_in_clk) then
  if p_in_rst = '1' then
      sr_matrix_wr <= (others => '0');
  else
    if p_in_dwnp_rdy_n = '0' then
      sr_matrix_wr <= sr_buf_wr(0) & sr_matrix_wr(0 to sr_matrix_wr'high - 1);
    end if;
  end if;
end if;
end process;


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
  if p_in_rst = '1' then
      sr_buf_wr(i) <= '0';
      sr_buf_adr(i) <= (others => '0');
  else
    if p_in_dwnp_rdy_n = '0' then
      sr_buf_adr(i) <= sr_buf_adr(i + 1);
      sr_buf_wr(i) <= sr_buf_wr(i + 1);
    end if;
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


i_eol <= i_buf_wr when i_buf_adr = RESIZE((UNSIGNED(p_in_cfg_pix_count) - 1), i_buf_adr'length) else '0';

process(p_in_clk)
begin
if rising_edge(p_in_clk) then
  if p_in_rst = '1' then
      sr_sol <= (others => '0');
      sr_eol <= (others => '0'); i_eol_en <= '0';
  else
      if p_in_dwnp_rdy_n = '0' then
        if i_buf_wr = '1' then
          sr_sol <= not OR_reduce(i_buf_adr) & sr_sol(0 to sr_sol'high - 1);
        end if;

        sr_eol <= i_eol & sr_eol(0 to sr_eol'high - 1);

        if i_eol = '1' then
          i_eol_en <= '1';
        elsif sr_eol(sr_eol'high) = '1' then
          i_eol_en <= '0';
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
        if p_in_upp_wr = '1' or i_eol_en = '1' or i_eof_en = '1' then
          for i in 0 to sr_buf'length - 1 loop
            sr_buf(i).do <= i_buf_do(i) & sr_buf(i).do(0 to sr_buf(i).do'high - 1);
          end loop;
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
  else
    if p_in_dwnp_rdy_n = '0' then
      if i_buf_wr = '1' then
        if i_buf_adr = RESIZE((UNSIGNED(p_in_cfg_pix_count) - 1), i_buf_adr'length) then
          i_buf_adr <= (others => '0');
        else
          i_buf_adr <= i_buf_adr + 1;
        end if;
      end if;
    end if;
  end if;
end if;
end process;


process(p_in_clk)
begin
if rising_edge(p_in_clk) then
  if p_in_rst = '1' then
    i_fsm_ctrl <= S_SOF_WAIT;

    i_cntline <= (others => '0');
    i_dwnp_en <= '0'; sr_dwnp_en <= '0';
    i_eof_en <= '0';
    i_eof_line_en <= '0';
    i_dwnp_en <= '0';
    i_dwnp_eof_en <= '0';

  else
    if p_in_dwnp_rdy_n = '0' then

      case i_fsm_ctrl is

        when S_SOF_WAIT =>

          if i_eof_en = '0' then
            if p_in_upp_wr = '1' then
              i_fsm_ctrl <= S_SOF_LINE;
            end if;
          end if;

        when S_SOF_LINE =>

          if sr_eol(sr_eol'high) = '1' then
            if i_cntline = TO_UNSIGNED(CI_OPT, i_cntline'length) then
              i_cntline <= (others => '0');
              i_dwnp_en <= '1';
              i_fsm_ctrl <= S_EOF_WAIT;
            else
              i_cntline <= i_cntline + 1;
            end if;
          end if;

        when S_EOF_WAIT =>

          if sr_eol(sr_eol'high) = '1' then
            sr_dwnp_en <= '1';
          end if;

          if p_in_upp_wr = '1' and p_in_upp_eof = '1' then
            i_eof_en <= '1';
            i_fsm_ctrl <= S_EOF_LINE;
          end if;

        when S_EOF_LINE =>

          if sr_eol(sr_eol'high) = '1' then
            if i_cntline = TO_UNSIGNED(CI_OPT + 1, i_cntline'length) then
              i_cntline <= (others => '0');
              i_eof_en <= '0';
              i_dwnp_en <= '0'; sr_dwnp_en <= '0';
              i_dwnp_eof_en <= '0';
              i_fsm_ctrl <= S_SOF_WAIT;
            else
              i_eof_line_en <= '1';
              i_cntline <= i_cntline + 1;
            end if;
          end if;

      end case;
    end if; --if p_in_dwnp_rdy_n = '0' then
  end if;
end if;
end process;

i_eof <= '1' when i_fsm_ctrl = S_EOF_LINE and i_cntline = TO_UNSIGNED(CI_OPT + 1, i_cntline'length) else '0';


--##################################
--DBG
--##################################
p_out_tst(31 downto 1) <= (others=>'0');
p_out_tst(0) <= sr_sol(sr_sol'high) or i_eol_en or sr_dwnp_en;


end architecture behavioral;
