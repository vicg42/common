-------------------------------------------------------------------------
-- Company     : Linkos
-- Engineer    : Golovachenko Victor
--
-- Create Date : 20.01.2012 18:14:58
-- Module Name : vtiming_gen
--
-- Назначение/Описание :
--   Выдов видео
--
-- Revision:
-- Revision 0.01 - File Created
--
--------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

library work;
use work.vicg_common_pkg.all;

entity vtiming_gen is
generic(
G_VSYN_ACTIVE: std_logic:='1';
G_VS_WIDTH   : integer:=32;--Кол-во тактов частоты p_in_clk
G_HS_WIDTH   : integer:=32;
G_PIX_COUNT  : integer:=32;
G_ROW_COUNT  : integer:=32
);
port(
p_out_vs : out  std_logic;
p_out_hs : out  std_logic;

p_in_clk : in   std_logic;
p_in_rst : in   std_logic
);
end vtiming_gen;

architecture behavioral of vtiming_gen is

type fsm_state is (
S_IDLE,
S_PIX,
S_HS,
S_VS
);
signal fsm_cs: fsm_state;

constant CI_SYNCH : integer:=max2 (G_VS_WIDTH, G_HS_WIDTH);

signal i_syncnt : integer range 0 to CI_SYNCH;
signal i_pixcnt : integer range 0 to G_PIX_COUNT;
signal i_rowcnt : integer range 0 to G_ROW_COUNT;
signal i_vs     : std_logic;
signal i_hs     : std_logic;


--MAIN
begin

p_out_hs<=i_hs;
p_out_vs<=i_vs;

process(p_in_rst,p_in_clk)
begin
  if p_in_rst='1' then

    fsm_cs <= S_IDLE;
    i_vs<=G_VSYN_ACTIVE;
    i_hs<=not G_VSYN_ACTIVE;

  elsif p_in_clk'event and p_in_clk='1' then

    case fsm_cs is

      --------------------------------------
      --Исходное состояние
      --------------------------------------
      when S_IDLE =>

        i_vs<=G_VSYN_ACTIVE;
        i_hs<=not G_VSYN_ACTIVE;
        fsm_cs <= S_PIX;

      --------------------------------------
      --
      --------------------------------------
      when S_PIX =>

        i_vs<=not G_VSYN_ACTIVE;

        if i_pixcnt=G_PIX_COUNT-1 then
          i_hs<=G_VSYN_ACTIVE;
          fsm_cs <= S_HS;
        end if;

      --------------------------------------
      --
      --------------------------------------
      when S_HS =>

        if i_syncnt=G_HS_WIDTH-1 then
          i_hs<=not G_VSYN_ACTIVE;
          if i_rowcnt=G_ROW_COUNT-1 then
            i_vs<=G_VSYN_ACTIVE;
            fsm_cs <= S_VS;
          else
            fsm_cs <= S_PIX;
          end if;
        end if;

      --------------------------------------
      --
      --------------------------------------
      when S_VS =>

        if i_syncnt=G_VS_WIDTH-1 then
          i_vs<=not G_VSYN_ACTIVE;
          fsm_cs <= S_PIX;
        end if;

    end case;
  end if;
end process;


process(p_in_rst,p_in_clk)
begin
  if p_in_rst='1' then
    i_syncnt<=0;
  elsif p_in_clk'event and p_in_clk='1' then
    if (fsm_cs=S_HS and i_syncnt=G_HS_WIDTH-1) or
       (fsm_cs=S_VS and i_syncnt=G_VS_WIDTH-1) then
      i_syncnt<=0;
    elsif fsm_cs=S_HS or fsm_cs=S_VS then
      i_syncnt<=i_syncnt + 1;
    end if;
  end if;
end process;

process(p_in_rst,p_in_clk)
begin
  if p_in_rst='1' then
    i_pixcnt<=0;
  elsif p_in_clk'event and p_in_clk='1' then
    if fsm_cs/=S_PIX then
      i_pixcnt<=0;
    else
      i_pixcnt<=i_pixcnt + 1;
    end if;
  end if;
end process;

process(p_in_rst,p_in_clk)
begin
  if p_in_rst='1' then
    i_rowcnt<=0;
  elsif p_in_clk'event and p_in_clk='1' then
    if fsm_cs=S_VS then
      i_rowcnt<=0;
    elsif fsm_cs=S_HS and i_syncnt=G_HS_WIDTH-1 then
      i_rowcnt<=i_rowcnt + 1;
    end if;
  end if;
end process;

--END MAIN
end behavioral;
