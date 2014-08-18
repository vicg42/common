-------------------------------------------------------------------------
-- Company     : Yansar
-- Engineer    : Golovachenko Victor
--
-- Create Date : 21.06.2014 12:31:25
-- Module Name : vga_gen
--
-- Назначение/Описание :
--
--------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.vicg_common_pkg.all;

entity vga_gen is
generic(
G_SEL : integer := 0 --Resolution select
);
port(
--SYNC
p_out_vsync   : out  std_logic; --Vertical Sync
p_out_hsync   : out  std_logic; --Horizontal Sync
p_out_pixen   : out  std_logic; --Pixels
p_out_pixcnt  : out  std_logic_vector(15 downto 0);
p_out_linecnt : out  std_logic_vector(15 downto 0);

--System
p_in_clk      : in   std_logic;
p_in_rst      : in   std_logic
);
end entity;

architecture behavioral of vga_gen is

type TVGA_param is array (0 to 3) of integer;

--Data from Standard_VESA_timing.pdf
--                                          ------------------------------------------
--                       Resolution select |    0     |    1    |    2     |    3     |
--                                         |-------------------------------------------
--                             Resolution  | 640x480 | 800x600 | 1024x768 | 1280x1024 |
--                             Frame Ferq  | @72Hz   | @72Hz   | @70Hz    | @75Hz     |
--                                 Pixclk  | 31.5MHz | 50MHz   | 75MHz    | 135MHz    |
--HS: (horisontal sync) values in pixel
constant CI_HS_SYN_W        : TVGA_param := (40      , 120     , 136      , 144       );
constant CI_HS_BACKPORCH_W  : TVGA_param := (120     , 64      , 144      , 248       );
constant CI_HS_ACTIV_W      : TVGA_param := (640     , 800     , 1024     , 1280      );
constant CI_HS_FRONTPORCH_W : TVGA_param := (16      , 56      , 24       , 16        );
--VS: (vertical synch) values in line
constant CI_VS_SYN_W        : TVGA_param := (3       , 6       , 6        , 3         );
constant CI_VS_BACKPORCH_W  : TVGA_param := (20      , 23      , 29       , 38        );
constant CI_VS_ACTIV_W      : TVGA_param := (480     , 600     , 768      , 1024      );
constant CI_VS_FRONTPORCH_W : TVGA_param := (1       , 37      , 3        , 1         );

signal i_vga_xcnt           : unsigned(12 downto 0) := (others =>'0');
signal i_vga_ycnt           : unsigned(12 downto 0) := (others =>'0');
signal i_vga_hs_e           : unsigned(i_vga_xcnt'range);--sync end
signal i_vga_ha_b           : unsigned(i_vga_xcnt'range);--active begin
signal i_vga_ha_e           : unsigned(i_vga_xcnt'range);--active end
signal i_vga_hend           : unsigned(i_vga_xcnt'range);--line end
signal i_vga_vs_e           : unsigned(i_vga_ycnt'range);
signal i_vga_va_b           : unsigned(i_vga_ycnt'range);
signal i_vga_va_e           : unsigned(i_vga_ycnt'range);
signal i_vga_vend           : unsigned(i_vga_ycnt'range);--frame end

signal i_pix_ha             : std_logic := '0';
signal i_pix_va             : std_logic := '0';
signal i_hsync              : std_logic := '0';
signal i_vsync              : std_logic := '0';

signal i_pixcnt             : unsigned(15 downto 0) := (others => '0');
signal i_linecnt            : unsigned(15 downto 0) := (others => '0');


--MAIN
begin


------------------------------------
--Video
------------------------------------
i_vga_hs_e <= TO_UNSIGNED(CI_HS_SYN_W(G_SEL) - 1, i_vga_hs_e'length);
i_vga_ha_b <= TO_UNSIGNED(CI_HS_SYN_W(G_SEL) + CI_HS_BACKPORCH_W(G_SEL) - 1, i_vga_ha_b'length);

i_vga_ha_e <= TO_UNSIGNED(CI_HS_SYN_W(G_SEL) + CI_HS_BACKPORCH_W(G_SEL) + CI_HS_ACTIV_W(G_SEL) - 1, i_vga_ha_e'length);
i_vga_hend <= TO_UNSIGNED(CI_HS_SYN_W(G_SEL) + CI_HS_BACKPORCH_W(G_SEL) + CI_HS_ACTIV_W(G_SEL) + CI_HS_FRONTPORCH_W(G_SEL) - 1, i_vga_hend'length);

i_vga_vs_e <= TO_UNSIGNED(CI_VS_SYN_W(G_SEL) - 1, i_vga_vs_e'length);
i_vga_va_b <= TO_UNSIGNED(CI_VS_SYN_W(G_SEL) + CI_VS_BACKPORCH_W(G_SEL) - 1, i_vga_va_b'length);
i_vga_va_e <= TO_UNSIGNED(CI_VS_SYN_W(G_SEL) + CI_VS_BACKPORCH_W(G_SEL) + CI_VS_ACTIV_W(G_SEL) - 1, i_vga_va_e'length);
i_vga_vend <= TO_UNSIGNED(CI_VS_SYN_W(G_SEL) + CI_VS_BACKPORCH_W(G_SEL) + CI_VS_ACTIV_W(G_SEL) + CI_VS_FRONTPORCH_W(G_SEL) - 1, i_vga_vend'length);


process(p_in_clk)
begin
  if rising_edge(p_in_clk) then
    if p_in_rst = '1' then
      i_vga_xcnt <= (others=>'0');
      i_vga_ycnt <= (others=>'0');
      i_hsync <= '0';
      i_vsync <= '0';
      i_pix_ha <= '0';
      i_pix_va <= '0';
      i_pixcnt <= (others => '0');
      i_linecnt <= (others => '0');

    else

      if i_vga_xcnt = i_vga_hend then
        i_vga_xcnt <= (others=>'0');
        if i_vga_ycnt = i_vga_vend then
          i_vga_ycnt <= (others=>'0');
        else
          i_vga_ycnt <= i_vga_ycnt + 1;
        end if;
      else
        i_vga_xcnt <= i_vga_xcnt + 1;
      end if;

      if i_vga_xcnt > i_vga_hs_e then i_hsync <= '1';
      else                            i_hsync <= '0';
      end if;

      if i_vga_ycnt > i_vga_vs_e then i_vsync <= '1';
      else                            i_vsync <= '0';
      end if;

      if (i_vga_xcnt > i_vga_ha_b) and (i_vga_xcnt <= i_vga_ha_e) then i_pix_ha <= '1';
      else                                                             i_pix_ha <= '0';
      end if;

      if (i_vga_ycnt > i_vga_va_b) and (i_vga_ycnt <= i_vga_va_e) then i_pix_va <= '1';
      else                                                             i_pix_va <= '0';
      end if;

      if i_vga_xcnt > i_vga_ha_e then
        i_pixcnt <= (others => '0');
      elsif i_pix_ha = '1' and i_pix_va = '1' then
        i_pixcnt <= i_pixcnt + 1;
      end if;

      if i_vga_xcnt = i_vga_vend then
        i_linecnt <= (others => '0');
      elsif i_pix_va = '1' and i_vga_xcnt = i_vga_ha_e then
        i_linecnt <= i_linecnt + 1;
      end if;

    end if;
  end if;
end process;

p_out_vsync <= i_vsync;
p_out_hsync <= i_hsync;
p_out_pixen <= i_pix_ha and i_pix_va;

p_out_pixcnt <= std_logic_vector(i_pixcnt);
p_out_linecnt <= std_logic_vector(i_linecnt);

--END MAIN
end architecture;
