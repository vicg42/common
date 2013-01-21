-------------------------------------------------------------------------
-- Company     : Linkos
-- Engineer    : Golovachenko Victor
--
-- Create Date : 17.01.2013 15:00:39
-- Module Name : vfr_gen
--
-- Назначение/Описание :
--
--------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_misc.all;
use ieee.std_logic_unsigned.all;

library work;
use work.vicg_common_pkg.all;

entity vfr_gen is
generic(
G_VD_WIDTH : integer := 80;
G_VSYN_ACTIVE : std_logic := '1'
);
port(
--CFG
p_in_cfg      : in   std_logic_vector(15 downto 0);
p_in_vpix     : in   std_logic_vector(15 downto 0);--Кол-во pix
p_in_vrow     : in   std_logic_vector(15 downto 0);--Кол-во строк
p_in_syn_h    : in   std_logic_vector(15 downto 0);--Ширина HS (кол-во тактов)
p_in_syn_v    : in   std_logic_vector(15 downto 0);--Ширина VS (кол-во тактов)

--Test Video
p_out_vd      : out  std_logic_vector(G_VD_WIDTH - 1 downto 0);
p_out_vs      : out  std_logic;
p_out_hs      : out  std_logic;
p_out_vclk    : out  std_logic;
p_out_vclk_en : out  std_logic;

--Технологический
p_in_tst      : in   std_logic_vector(31 downto 0);
p_out_tst     : out  std_logic_vector(31 downto 0);

--System
p_in_clk      : in   std_logic;
p_in_rst      : in   std_logic
);
end vfr_gen;

architecture behavioral of vfr_gen is

type fsm_state is (
S_PIX,
S_SYN_H,
S_SYN_V
);
signal fsm_cs : fsm_state;

type TVData is array (0 to G_VD_WIDTH/8) of std_logic_vector(7 downto 0);
signal i_vd                 : TVData;
signal i_pix_cnt            : std_logic_vector(15 downto 0);
signal i_row_cnt            : std_logic_vector(15 downto 0);
signal i_hs                 : std_logic;
signal i_vs                 : std_logic;
signal i_vd_out             : std_logic_vector(G_VD_WIDTH - 1 downto 0);
signal i_div                : std_logic;

signal tst_fsm_cs,tst_fsm_cs_dly: std_logic_vector(1 downto 0);


--MAIN
begin

--//----------------------------------
--//Технологические сигналы
--//----------------------------------
p_out_tst(1 downto 0) <= tst_fsm_cs_dly;
p_out_tst(31 downto 2) <= (others=>'0');
process(p_in_clk)
begin
  if p_in_clk'event and p_in_clk='1' then
    tst_fsm_cs_dly <= tst_fsm_cs;
  end if;
end process;
tst_fsm_cs <= CONV_STD_LOGIC_VECTOR(16#02#,tst_fsm_cs'length) when fsm_cs = S_SYN_V     else
              CONV_STD_LOGIC_VECTOR(16#01#,tst_fsm_cs'length) when fsm_cs = S_SYN_H     else
              CONV_STD_LOGIC_VECTOR(16#00#,tst_fsm_cs'length);   --fsm_cs = S_PIX       else


--//----------------------------------
--//CFG
--//----------------------------------
i_div <= '1';


--//----------------------------------
--//Video
--//----------------------------------
p_out_vd <= i_vd_out;
p_out_vs <= i_vs when G_VSYN_ACTIVE = '1' else not i_vs;
p_out_hs <= i_hs when G_VSYN_ACTIVE = '1' else not i_hs;
p_out_vclk <= p_in_clk;
p_out_vclk_en <= i_div;

--vsync
process(p_in_rst, p_in_clk)
begin
  if p_in_rst = '1' then
    i_hs <= '0';
    i_vs <= '0';

    i_pix_cnt <= (others=>'0');
    i_row_cnt <= (others=>'0');
    fsm_cs <= S_PIX;

  elsif rising_edge(p_in_clk) then
  if i_div = '1' then

    case fsm_cs is
      --------------------------------------
      --
      --------------------------------------
      when S_PIX =>
          if i_pix_cnt = (p_in_vpix - 1) then
            i_pix_cnt <= (others=>'0');

            if i_row_cnt = (p_in_vrow - 1) then
              i_vs <= '1';
              i_row_cnt <= (others=>'0');
              fsm_cs <= S_SYN_V;
            else
              i_hs <= '1';
              i_row_cnt <= i_row_cnt + 1;
              fsm_cs <= S_SYN_H;
            end if;

          else
            i_pix_cnt <= i_pix_cnt + 1;
          end if;

      --------------------------------------
      --
      --------------------------------------
      when S_SYN_H =>

          if i_pix_cnt = (p_in_syn_h - 1) then
            i_pix_cnt <= (others=>'0');
            i_hs <= '0';
            fsm_cs <= S_PIX;
          else
            i_pix_cnt <= i_pix_cnt + 1;
          end if;

      --------------------------------------
      --
      --------------------------------------
      when S_SYN_V =>

          if i_pix_cnt = (p_in_syn_v - 1) then
            i_pix_cnt <= (others=>'0');
            i_vs <= '0';
            fsm_cs <= S_PIX;
          else
            i_pix_cnt <= i_pix_cnt + 1;
          end if;

    end case;

  end if;
  end if;
end process;

--gen test data (вертикальные полоски)
process(p_in_rst, p_in_clk)
begin
  if p_in_rst = '1' then
    for i in 0 to G_VD_WIDTH/8 - 1 loop
    i_vd(i) <= CONV_STD_LOGIC_VECTOR(i, i_vd(i)'length);
    end loop;
  elsif rising_edge(p_in_clk) then
  if i_div = '1' then
      if i_hs = '1' or i_vs = '1' then
        for i in 0 to G_VD_WIDTH/8 - 1 loop
        i_vd(i) <= CONV_STD_LOGIC_VECTOR(i, i_vd(i)'length);
        end loop;
      else
        for i in 0 to G_VD_WIDTH/8 - 1 loop
        i_vd(i) <= i_vd(i) + CONV_STD_LOGIC_VECTOR(G_VD_WIDTH/8, i_vd(i)'length);
        end loop;
      end if;
  end if;
  end if;
end process;

gen_vd : for i in 0 to G_VD_WIDTH/8 - 1 generate
i_vd_out((i_vd(i)'length * (i+1)) - 1 downto (i_vd(i)'length * i)) <= i_vd(i);
end generate gen_vd;

--END MAIN
end behavioral;
