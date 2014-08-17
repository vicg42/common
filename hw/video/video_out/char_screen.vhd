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

entity char_screen is
generic(
G_FONT_SIZEY : integer := 10;
G_CHAR_COUNT : integer := 8
);
port(
p_in_ram_adr  : in  std_logic_vector(11 downto 0);
p_in_ram_din  : in  std_logic_vector(31 downto 0);

--SYNC
p_out_vd      : out  std_logic_vector(23 downto 0);
p_in_vd       : in   std_logic_vector(23 downto 0);
p_in_vsync    : in   std_logic; --Vertical Sync
p_in_hsync    : in   std_logic; --Horizontal Sync
p_in_den      : in   std_logic; --Pixels

p_out_tst     : out  std_logic_vector(31 downto 0);

--System
p_in_clk      : in   std_logic;
p_in_rst      : in   std_logic
);
end entity;

architecture behavioral of char_screen is

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

signal i_font_cntx      : unsigned(2 downto 0);
signal i_font_cnty      : unsigned(3 downto 0);
signal i_font_dout      : std_logic_vector(7 downto 0);

signal i_char_cntx      : unsigned(7 downto 0);
signal i_char_cnty      : unsigned(7 downto 0);

signal i_ascii          : std_logic_vector(7 downto 0);

signal i_txt_ram_rd     : std_logic;
signal i_font_ram_rd    : std_logic;
signal i_nchar_out      : std_logic;
signal sr_ram_rd        : std_logic_vector(0 to 1);

signal i_font_ram_a     : std_logic_vector(11 downto 0);
signal i_text_ram_a     : std_logic_vector(11 downto 0);
signal i_font_ram_wr    : std_logic_vector(0 downto 0);
signal i_text_ram_wr    : std_logic_vector(0 downto 0);

signal sr_char_out      : std_logic_vector(7 downto 0);

signal tst_char         : std_logic_vector(i_font_dout'range) := (others => '0');;
signal tst_charen       : std_logic := '0';

--MAIN
begin

p_out_tst(31) <= sr_char_out(sr_char_out'length - 1);
p_out_tst(8) <= tst_charen;
p_out_tst(7 downto 0) <= tst_char;



process(p_in_clk)
begin
  if rising_edge(p_in_clk) then
    if p_in_rst = '1' then
      i_font_cntx <= (others => '0');
      i_font_cnty <= (others => '0');
      i_char_cntx <= (others => '0');
      i_char_cnty <= (others => '0');

    else
      if p_in_vsync = '0' then
        i_font_cntx <= (others => '0');
        i_font_cnty <= (others => '0');
        i_char_cntx <= (others => '0');
        i_char_cnty <= (others => '0');

      else

        if p_in_den = '1' then
          if i_font_cntx = TO_UNSIGNED(8, i_font_cntx'length) - 1 then
            i_font_cntx <= (others => '0');

              if i_char_cntx = TO_UNSIGNED(G_CHAR_COUNT, i_char_cntx'length) - 1 then
                i_char_cntx <= (others => '0');
              else
                i_char_cntx <= i_char_cntx + 1;
              end if;

            if i_font_cnty = TO_UNSIGNED(G_FONT_SIZEY, i_font_cnty'length) - 1 then
              i_font_cnty <= (others => '0');

              if i_char_cntx = TO_UNSIGNED(G_CHAR_COUNT, i_char_cntx'length) - 1 then
                if i_char_cnty = TO_UNSIGNED(G_CHAR_COUNT, i_char_cnty'length) - 1 then
                  i_char_cnty <= ( others => '0');
                else
                  i_char_cnty <= i_char_cnty + 1;
                end if;
              end if;

            else
              i_font_cnty <= i_font_cnty + 1;
            end if;

          else
            i_font_cntx <= i_font_cntx + 1;
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
      sr_char_out <= (others => '0');

    else
      if p_in_den = '1' then
        if i_nchar_out = '1' then
          sr_char_out <= i_font_dout;
        else
          sr_char_out <= sr_char_out(sr_char_out'length - 2 downto 0) & '0'; --MSB first
  --        sr_char_out <= '0' & sr_char_out(sr_reg'length - 1 downto 1); --LSB first
        end if;
      end if;
    end if;
  end if;
end process;


i_txt_ram_rd <= '1' when i_font_cntx = (TO_UNSIGNED(5, i_font_cntx'length)) else '0';
i_font_ram_rd <= sr_ram_rd(0);
i_nchar_out <= sr_ram_rd(1);

i_font_ram_a <= i_ascii(7 downto 0) & std_logic_vector(i_font_cnty(3 downto 0));
i_text_ram_a <= "00000" & std_logic_vector(i_char_cnty(3 downto 0)) & std_logic_vector(i_char_cntx(2 downto 0));
i_text_ram_wr(0) <= p_in_ram_adr(11);
i_font_ram_wr(0) <= p_in_ram_adr(10);

m_ram_txt : ram_font
port map(
clka  => p_in_clk                ,
ena   => i_text_ram_wr(0)        ,
wea   => i_text_ram_wr           ,
addra => p_in_ram_adr(9 downto 0),--: in  std_logic_vector(6 downto 0);
dina  => p_in_ram_din            ,--: in  std_logic_vector(31 downto 0);
douta => open                    ,

clkb  => p_in_clk                ,
enb   => '1'                     ,
web   => (others => '0')         ,
addrb => i_text_ram_a            ,--: in  std_logic_vector(8 downto 0);
dinb  => (others => '0')         ,
doutb => i_ascii                  --: out std_logic_vector(7 downto 0)
);

m_ram_font : ram_font
port map(
clka  => p_in_clk                ,
ena   => i_font_ram_wr(0)        ,
wea   => i_font_ram_wr           ,
addra => p_in_ram_adr(9 downto 0),--: in  std_logic_vector(6 downto 0);
dina  => p_in_ram_din            ,--: in  std_logic_vector(31 downto 0);
douta => open                    ,

clkb  => p_in_clk                ,
enb   => '1'                     ,
web   => (others => '0')         ,
addrb => i_font_ram_a            ,--: in  std_logic_vector(8 downto 0);
dinb  => (others => '0')         ,
doutb => i_font_dout              --: out std_logic_vector(7 downto 0)
);


process(p_in_clk)
begin
  if rising_edge(p_in_clk) then
    if p_in_rst = '1' then
      sr_ram_rd <= (others => '0');
    else
      if p_in_den = '1' then
        sr_ram_rd <= i_txt_ram_rd & sr_ram_rd(0 to 0);
      end if;
    end if;
  end if;
end process;

--blend
process(sr_char_out)
begin
  case sr_char_out(sr_char_out'length - 1) is
  when '0' => p_out_vd <= (others => '0');
  when '1' => p_out_vd <= (others => '1');
  when others => null;
  end case;
end process;

process(p_in_clk)
begin
  if rising_edge(p_in_clk) then
    if p_in_rst = '1' then
      tst_char <= (others => '0');
      tst_charen <= '0';
    else
      if p_in_den = '1' then
        if i_nchar_out = '1' then
          tst_char <= i_font_dout;
        end if;
      end if;

      tst_charen <= i_nchar_out;
    end if;
  end if;
end process;


--END MAIN
end architecture;
