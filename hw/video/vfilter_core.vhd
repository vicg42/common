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
-- Управление
-------------------------------
p_in_cfg_pix_count : in    std_logic_vector(15 downto 0);--Кол-во пиксел/4 т.к p_in_upp_data=32bit
p_in_cfg_init      : in    std_logic;                    --Инициализация. Сброс счетчика адреса BRAM

----------------------------
--Upstream Port (входные данные)
----------------------------
p_in_upp_data      : in    std_logic_vector(7 downto 0);
p_in_upp_wr        : in    std_logic;
p_in_upp_eof       : in    std_logic;
p_out_upp_rdy_n    : out   std_logic;

----------------------------
--Downstream Port (результат)
----------------------------
p_out_matrix       : out   TMatrix;
p_out_dwnp_wr      : out   std_logic;
p_out_dwnp_eof     : out   std_logic;
p_in_dwnp_rdy_n    : in    std_logic;

-------------------------------
--Технологический
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

constant dly : time := 1 ps;

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
type TBufs is array (0 to C_VFILTER_RANG - 1) of std_logic_vector(p_in_upp_data'range);
signal i_buf_do            : TBufs;
signal i_buf_wr            : std_logic;

signal i_dly_cntline       : unsigned(CI_DLY_LINE - 1 downto 0);
signal i_dout_en_y         : std_logic;
signal i_dout_en_y1        : std_logic;
signal i_dout_en_x         : std_logic;
signal i_dout_eof          : std_logic;
signal i_dly_eof_on        : std_logic;

signal i_matrix            : TMatrix;
signal i_matrix_wr         : std_logic;




begin --architecture behavioral

------------------------------------
--Технологические сигналы
------------------------------------
p_out_tst(0) <= i_dout_en_y or i_dout_en_x or i_dout_en_y1
or OR_reduce(std_logic_vector(i_matrix(0)(0)))
or OR_reduce(std_logic_vector(i_matrix(0)(1)))
or OR_reduce(std_logic_vector(i_matrix(0)(2)))
or OR_reduce(std_logic_vector(i_matrix(1)(0)))
or OR_reduce(std_logic_vector(i_matrix(1)(1)))
or OR_reduce(std_logic_vector(i_matrix(1)(2)))
or OR_reduce(std_logic_vector(i_matrix(2)(0)))
or OR_reduce(std_logic_vector(i_matrix(2)(1)))
or OR_reduce(std_logic_vector(i_matrix(2)(2)));
p_out_tst(31 downto 1) <= (others=>'0');




p_out_matrix <= i_matrix;
p_out_dwnp_wr <= i_matrix_wr;
p_out_dwnp_eof <= i_matrix_wr and i_dly_eof_on;

--------------------------------------------------------
--RAM Строк видео информации
--------------------------------------------------------
i_gnd_adrb <= (others => '0');
i_gnd_dinb <= (others => '0');

p_out_upp_rdy_n <= i_dly_eof_on;

--Буфера строк:
--lineN : Текущая строка
i_buf_do(0) <= p_in_upp_data;
i_buf_wr <= (p_in_upp_wr or i_dly_eof_on) and not p_in_dwnp_rdy_n;

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


process(p_in_clk)
variable dout_eof : std_logic;
begin
  if rising_edge(p_in_clk) then
    if p_in_rst = '1' then
      i_buf_adr <= (others => '0');
      i_dly_cntline <= ( others => '0');
      i_dout_en_y <= '0'; i_dly_eof_on <= '0';
      i_dout_en_y1 <= '0';
      dout_eof := '0'; i_dout_eof <= '0';
      i_dout_en_x <= '0';

    else
      if p_in_dwnp_rdy_n = '0' then

        if i_buf_wr = '1' then
          if i_buf_adr = RESIZE((UNSIGNED(p_in_cfg_pix_count) - 1), i_buf_adr'length) then
            i_buf_adr <= (others => '0');
          else
            i_buf_adr <= i_buf_adr + 1;
          end if;
        end if;


        dout_eof := '0';

      if i_buf_wr = '1' then
        if i_dout_en_y1 = '1' then
          if p_in_upp_eof = '1' then
            i_dly_eof_on <= '1';

          else
            if i_dly_eof_on = '1' then
              if i_buf_adr = RESIZE((UNSIGNED(p_in_cfg_pix_count) - 1), i_buf_adr'length) then
                if i_dly_cntline = TO_UNSIGNED(CI_DLY_LINE, i_dly_cntline'length) then
                  i_dly_cntline <= ( others => '0');
                  i_dout_en_y <= '0'; i_dly_eof_on <= '0';  dout_eof := '1';
                  i_dout_en_y1 <= '0';
                else
                  i_dly_cntline <= i_dly_cntline + 1;
                end if;
              end if;
            end if;
          end if;

        else

          if i_buf_adr = RESIZE((UNSIGNED(p_in_cfg_pix_count) - 1), i_buf_adr'length) then
            if i_dly_cntline = TO_UNSIGNED(CI_DLY_LINE - 1, i_dly_cntline'length) then
              i_dly_cntline <= (others => '0');
              i_dout_en_y <= '1';
              i_dout_en_y1 <= i_dout_en_y;
            else
              i_dly_cntline <= i_dly_cntline + 1;
            end if;
          end if;

        end if;

        i_dout_eof <= dout_eof;

      end if;
    end if;

  end if;
  end if;
end process;



process(p_in_clk)
begin
  if rising_edge(p_in_clk) then
    if p_in_rst = '1' then
      for x in 0 to C_VFILTER_RANG - 1 loop
        for y in 0 to C_VFILTER_RANG - 1 loop
        i_matrix(y)(x) <= (others => '0');
        end loop;
      end loop;
      i_matrix_wr <= '0';

    else
      if p_in_dwnp_rdy_n = '0' then
        if i_buf_wr = '1' then

--          for x in 0 to C_VFILTER_RANG - 1 loop
--            for y in 0 to C_VFILTER_RANG - 1 loop
--              if i_buf_adr = x + y then
--              i_matrix(y)(x) <= UNSIGNED(i_buf_do(y));
--              end if;
--            end loop;
--          end loop;


          if i_dly_eof_on = '1' then

            if    i_buf_adr = TO_UNSIGNED(0, i_buf_adr'length) then i_matrix(0)(0) <= UNSIGNED(i_buf_do(2));
            elsif i_buf_adr = TO_UNSIGNED(1, i_buf_adr'length) then i_matrix(0)(1) <= UNSIGNED(i_buf_do(2));
            elsif i_buf_adr = TO_UNSIGNED(2, i_buf_adr'length) then i_matrix(0)(2) <= (others => '0');
            end if;

            if    i_buf_adr = TO_UNSIGNED(1, i_buf_adr'length) then i_matrix(1)(0) <= UNSIGNED(i_buf_do(1));
            elsif i_buf_adr = TO_UNSIGNED(2, i_buf_adr'length) then i_matrix(1)(1) <= UNSIGNED(i_buf_do(1));
            elsif i_buf_adr = TO_UNSIGNED(3, i_buf_adr'length) then i_matrix(1)(2) <= (others => '0');
            end if;

            i_matrix(2)(0) <= (others => '0');
            i_matrix(2)(1) <= (others => '0');
            i_matrix(2)(2) <= (others => '0');

          elsif i_dout_en_y = '1' and i_dout_en_y1 = '0' then
            i_matrix(0)(0) <= (others => '0');
            i_matrix(0)(1) <= (others => '0');
            i_matrix(0)(2) <= (others => '0');

            if    i_buf_adr = TO_UNSIGNED(3, i_buf_adr'length) then i_matrix(1)(0) <= (others => '0');
            elsif i_buf_adr = TO_UNSIGNED(1, i_buf_adr'length) then i_matrix(1)(1) <= UNSIGNED(i_buf_do(1));
            elsif i_buf_adr = TO_UNSIGNED(2, i_buf_adr'length) then i_matrix(1)(2) <= UNSIGNED(i_buf_do(1));
            end if;

            if    i_buf_adr = TO_UNSIGNED(2, i_buf_adr'length) then i_matrix(2)(0) <= (others => '0');
            elsif i_buf_adr = TO_UNSIGNED(0, i_buf_adr'length) then i_matrix(2)(1) <= UNSIGNED(i_buf_do(0));
            elsif i_buf_adr = TO_UNSIGNED(1, i_buf_adr'length) then i_matrix(2)(2) <= UNSIGNED(i_buf_do(0));
            end if;

          elsif i_dout_en_y = '1' and i_dout_en_y1 = '1' then
            for x in 0 to C_VFILTER_RANG - 1 loop
              for y in 0 to C_VFILTER_RANG - 1 loop
                if i_buf_adr = x + y then
                i_matrix(y)(x) <= UNSIGNED(i_buf_do(y));
                end if;
              end loop;
            end loop;

          elsif i_dout_en_y = '0' and i_dout_en_y1 = '0' then
              for x in 0 to C_VFILTER_RANG - 1 loop
                for y in 0 to C_VFILTER_RANG - 1 loop
                i_matrix(y)(x) <= (others => '0');
                end loop;
              end loop;

          end if;

        if i_dout_en_y = '1' and i_buf_adr = (TO_UNSIGNED(C_VFILTER_RANG + 1, i_buf_adr'length)) then
          i_matrix_wr <= i_buf_wr;
        else
          i_matrix_wr <= '0';
        end if;

      end if;
    end if;
  end if;
  end if;
end process;


end architecture behavioral;



