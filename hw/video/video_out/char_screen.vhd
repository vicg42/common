-------------------------------------------------------------------------
-- Company     : Yansar
-- Engineer    : Golovachenko Victor
--
-- Create Date : 15.08.2014 11:06:41
-- Module Name : char_screen
--
-- Назначение/Описание :
--
--------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.vicg_common_pkg.all;
use work.reduce_pack.all;

entity char_screen is
generic(
G_VDWIDTH    : integer := 32;
G_COLDWIDTH  : integer := 10;
G_FONT_SIZEX : integer := 8;
G_FONT_SIZEY : integer := 10;
G_SCR_STARTX : integer := 8; --(index pixel)
G_SCR_STARTY : integer := 8; --(index pixel)
G_SCR_SIZEX  : integer := 8; --(char count)
G_SCR_SIZEY  : integer := 8  --(char count)
);
port(
p_in_ram_adr  : in  std_logic_vector(11 downto 0);
p_in_ram_din  : in  std_logic_vector(31 downto 0);

--SYNC
p_out_vd      : out  std_logic_vector(G_VDWIDTH - 1 downto 0);--RBG
p_in_vd       : in   std_logic_vector(G_VDWIDTH - 1 downto 0);
p_in_vsync    : in   std_logic;
p_in_hsync    : in   std_logic;
p_in_pixen    : in   std_logic;
p_in_pixcnt   : in   std_logic_vector(15 downto 0);
p_in_linecnt  : in   std_logic_vector(15 downto 0);

p_out_tst     : out  std_logic_vector(31 downto 0);

--System
p_in_clk      : in   std_logic;
p_in_rst      : in   std_logic
);
end entity;

architecture behavioral of char_screen is

constant CI_FONT_SIZEX_MAX  : integer := 8;
constant CI_FONT_SIZEY_MAX  : integer := 16;
constant CI_CHAR_COUNTX_MAX : integer := 16;
constant CI_CHAR_COUNTY_MAX : integer := 16;

component ram_font is
port (
clka  : in  std_logic;
ena   : in  std_logic;
wea   : in  std_logic_vector(0 downto 0);
addra : in  std_logic_vector(9 downto 0);
dina  : in  std_logic_vector(31 downto 0);
douta : out std_logic_vector(31 downto 0);
clkb  : in  std_logic;
enb   : in  std_logic;
web   : in  std_logic_vector(0 downto 0);
addrb : in  std_logic_vector(11 downto 0);
dinb  : in  std_logic_vector(7 downto 0);
doutb : out std_logic_vector(7 downto 0)
);
end component ram_font;

component ram_txt is
port (
clka  : in  std_logic;
ena   : in  std_logic;
wea   : in  std_logic_vector(0 downto 0);
addra : in  std_logic_vector(9 downto 0);
dina  : in  std_logic_vector(31 downto 0);
douta : out std_logic_vector(31 downto 0);
clkb  : in  std_logic;
enb   : in  std_logic;
web   : in  std_logic_vector(0 downto 0);
addrb : in  std_logic_vector(11 downto 0);
dinb  : in  std_logic_vector(7 downto 0);
doutb : out std_logic_vector(7 downto 0)
);
end component ram_txt;

signal i_screen_eny     : std_logic;
signal i_screen_enx     : std_logic;
signal i_screen_en      : std_logic;

signal i_font_cntx      : unsigned(2 downto 0);
signal i_font_cnty      : unsigned(3 downto 0);
signal i_font_dout      : std_logic_vector(7 downto 0);

signal i_char_cntx      : unsigned(7 downto 0);
signal i_char_cnty      : unsigned(7 downto 0);
signal i_char_ascii     : std_logic_vector(7 downto 0);

signal i_font_ram_a     : unsigned(12 downto 0);
signal i_font_ram_a_tmp : unsigned(15 downto 0);
signal i_text_ram_a     : unsigned(12 downto 0);
signal i_text_ram_a_tmp : unsigned(15 downto 0);
signal i_font_ram_wr    : std_logic_vector(0 downto 0);
signal i_text_ram_wr    : std_logic_vector(0 downto 0);

signal i_char_out_ld    : std_logic;
signal sr_char_out      : std_logic_vector(7 downto 0);
signal i_char_out_mux   : std_logic;

signal i_colr           : std_logic_vector(G_COLDWIDTH - 1 downto 0);
signal i_colb           : std_logic_vector(G_COLDWIDTH - 1 downto 0);
signal i_colg           : std_logic_vector(G_COLDWIDTH - 1 downto 0);
signal i_palette        : std_logic_vector((i_colg'length * 3) - 1 downto 0);

signal tst_char         : std_logic_vector(i_font_dout'range) := (others => '0');
signal tst_charen       : std_logic := '0';

signal i_vd_out         : std_logic_vector(p_out_vd'range);
signal tst_vd_out       : std_logic_vector(p_out_vd'range);
signal tst_start        : std_logic;
signal sr_tst_start     : std_logic_vector(0 to 1);
signal tst_start_out    : std_logic;
signal sr_screen_en     : std_logic_vector(0 to 1) := (others => '0');
signal tst_char_out_mux : std_logic;

--MAIN
begin

p_out_tst(31) <= OR_reduce(tst_vd_out) and tst_start_out and sr_screen_en(0) and tst_char_out_mux;
p_out_tst(8) <= tst_charen;
p_out_tst(7 downto 0) <= tst_char;

i_screen_eny <= '1' when (UNSIGNED(p_in_linecnt) >= TO_UNSIGNED(G_SCR_STARTY, p_in_linecnt'length))
                      and (UNSIGNED(p_in_linecnt) <= TO_UNSIGNED(G_SCR_STARTY + (G_FONT_SIZEY * G_SCR_SIZEY)
                                                                                          , p_in_linecnt'length)) else '0';

i_screen_enx <= '1' when (UNSIGNED(p_in_pixcnt) >= TO_UNSIGNED(G_SCR_STARTX, p_in_pixcnt'length))
                      and (UNSIGNED(p_in_pixcnt) <= TO_UNSIGNED(G_SCR_STARTX + (G_FONT_SIZEX * G_SCR_SIZEX) - 1
                                                                                          , p_in_pixcnt'length)) else '0';

i_screen_en <= p_in_pixen and i_screen_enx and i_screen_eny;

process(p_in_clk)
begin
  if rising_edge(p_in_clk) then
    if p_in_rst = '1' then
      i_font_cntx <= (others => '0');
      i_font_cnty <= (others => '0');
      i_char_cntx <= (others => '0');
      i_char_cnty <= (others => '0'); tst_start <= '0';

    else

      if p_in_vsync = '0' then
        i_font_cntx <= (others => '0');
        i_font_cnty <= (others => '0');
        i_char_cntx <= (others => '0');
        i_char_cnty <= (others => '0'); tst_start <= '0';

      else

          if i_screen_en = '1' then  tst_start <= '1';

            if i_font_cntx = TO_UNSIGNED(G_FONT_SIZEX - 1, i_font_cntx'length) then
              i_font_cntx <= (others => '0');

              if i_char_cntx = TO_UNSIGNED(G_SCR_SIZEX, i_char_cntx'length) then
                i_char_cntx <= (others => '0');

                if i_font_cnty = TO_UNSIGNED(G_FONT_SIZEY - 1, i_font_cnty'length) then
                  i_font_cnty <= (others => '0');

                  if i_char_cnty = TO_UNSIGNED(G_SCR_SIZEY - 1, i_char_cnty'length) then
                    i_char_cnty <= ( others => '0');
                  else
                    i_char_cnty <= i_char_cnty + 1;
                  end if;
                else
                  i_font_cnty <= i_font_cnty + 1;
                end if;

              end if;

            else

              i_font_cntx <= i_font_cntx + 1;

              if i_font_cntx = (i_font_cntx'range => '0') then
                i_char_cntx <= i_char_cntx + 1;
              end if;

            end if;
          end if;

      end if;

    end if;
  end if;
end process;


i_char_out_ld <= '1' when (i_screen_en = '1' and (i_font_cntx = TO_UNSIGNED(G_FONT_SIZEX - 1, i_font_cntx'length)))
                            or (p_in_hsync = '0') else '0';
process(p_in_clk)
begin
  if rising_edge(p_in_clk) then
    if p_in_rst = '1' then
      sr_char_out <= (others => '0');

    else
      if i_char_out_ld = '1' then
        sr_char_out <= i_font_dout;

      else
        if i_screen_en = '1' then
          sr_char_out <= sr_char_out(sr_char_out'length - 2 downto 0) & '0'; --MSB first
--          sr_char_out <= '0' & sr_char_out(sr_reg'length - 1 downto 1); --LSB first
        end if;
      end if;
    end if;
  end if;
end process;

i_font_ram_a_tmp <= TO_UNSIGNED(G_FONT_SIZEY, 8) * UNSIGNED(i_char_ascii(7 downto 0));
i_font_ram_a <= i_font_ram_a_tmp(12 downto 0) + RESIZE(i_font_cnty, i_font_ram_a'length);

i_text_ram_a_tmp <= TO_UNSIGNED(G_SCR_SIZEY, 8) * i_char_cnty(7 downto 0);
i_text_ram_a <= i_text_ram_a_tmp(12 downto 0) + RESIZE(i_char_cntx, i_text_ram_a'length);

i_text_ram_wr(0) <= p_in_ram_adr(11);
i_font_ram_wr(0) <= p_in_ram_adr(10);

m_ram_txt : ram_txt
port map(
clka  => p_in_clk                 ,
ena   => i_text_ram_wr(0)         ,
wea   => i_text_ram_wr            ,
addra => p_in_ram_adr(9 downto 0) ,
dina  => p_in_ram_din(31 downto 0),
douta => open                     ,

clkb  => p_in_clk                 ,
enb   => '1'                      ,
web   => (others => '0')          ,
addrb => std_logic_vector(i_text_ram_a(11 downto 0)),--i_text_ram_a(11 downto 0),--: in  std_logic_vector(8 downto 0);
dinb  => (others => '0')          ,
doutb => i_char_ascii
);

m_ram_font : ram_font
port map(
clka  => p_in_clk                 ,
ena   => i_font_ram_wr(0)         ,
wea   => i_font_ram_wr            ,
addra => p_in_ram_adr(9 downto 0) ,--: in  std_logic_vector(6 downto 0);
dina  => p_in_ram_din(31 downto 0),--: in  std_logic_vector(31 downto 0);
douta => open                     ,

clkb  => p_in_clk                 ,
enb   => '1'                      ,
web   => (others => '0')          ,
addrb => std_logic_vector(i_font_ram_a(11 downto 0)),--std_logic_vector(p_in_pixcnt(11 downto 0)),--: in  std_logic_vector(8 downto 0);
dinb  => (others => '0')          ,
doutb => i_font_dout
);

i_char_out_mux <= i_screen_en and sr_char_out(sr_char_out'length - 1);

process(sr_char_out, p_in_vd, i_palette, i_char_out_mux)
begin
  case (i_char_out_mux)is
  when '0' => i_vd_out <= p_in_vd;
  when '1' => i_vd_out <= std_logic_vector(RESIZE(UNSIGNED(i_palette), p_out_vd'length));
  when others => null;
  end case;
end process;

i_palette <= i_colr & i_colb & i_colg;
i_colr <= (others => '1');
i_colb <= (others => '1');
i_colg <= (others => '1');

p_out_vd <= i_vd_out;

--DBG
process(p_in_clk)
begin
  if rising_edge(p_in_clk) then
    if p_in_rst = '1' then
      tst_char <= (others => '0');
      tst_charen <= '0';
      sr_screen_en <= (others => '0');
      tst_vd_out <= (others => '0');
      sr_tst_start <= (others => '0');
      tst_start_out <= '0'; tst_char_out_mux <= '0';

    else
      sr_screen_en <= i_screen_en & sr_screen_en(0 to 0);

      if i_screen_en = '1' then
        if (i_font_cntx = (i_font_cntx'range => '0')) then
          tst_char <= i_font_dout;
          tst_charen <= '1';
        else
          tst_charen <= '0';
        end if;
      else
        tst_charen <= '0';
      end if;
      tst_char_out_mux <= i_char_out_mux;
      tst_vd_out <= i_vd_out;
      sr_tst_start <= tst_start & sr_tst_start(0 to 0);
      tst_start_out <= sr_tst_start(0) and not sr_tst_start(1);
    end if;
  end if;
end process;


--END MAIN
end architecture;
