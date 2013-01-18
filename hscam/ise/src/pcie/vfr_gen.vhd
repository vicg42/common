-------------------------------------------------------------------------
-- Company     : Linkos
-- Engineer    : Golovachenko Victor
--
-- Create Date : 17.01.2013 15:00:39
-- Module Name : vfr_gen
--
-- ����������/�������� :
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
p_in_mode     : in   std_logic_vector(15 downto 0);--������
p_in_vpix     : in   std_logic_vector(15 downto 0);--���-�� pix
p_in_vrow     : in   std_logic_vector(15 downto 0);--���-�� �����
p_in_syn      : in   std_logic_vector(15 downto 0);--������ VS,HS (���-�� ������)

--Test Video
p_out_vd      : out  std_logic_vector(G_VD_WIDTH - 1 downto 0);
p_out_vs      : out  std_logic;
p_out_hs      : out  std_logic;
p_out_vclk    : out  std_logic;
p_out_vclk_en : out  std_logic;

--���������������
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
S_SYN
);
signal fsm_cs : fsm_state;

type TVData is array (0 to G_VD_WIDTH/8) of std_logic_vector(7 downto 0);
signal i_vd                 : TVData;
signal i_pix_cnt            : std_logic_vector(15 downto 0);
signal i_row_cnt            : std_logic_vector(15 downto 0);
signal i_hs                 : std_logic;
signal i_vs                 : std_logic;

signal i_div_cnt            : std_logic_vector(5 downto 0);
signal i_div                : std_logic;
signal tst_fsm_cs,tst_fsm_cs_dly: std_logic_vector(1 downto 0);


--MAIN
begin

--//----------------------------------
--//��������������� �������
--//----------------------------------
p_out_tst(1 downto 0) <= tst_fsm_cs_dly;
p_out_tst(31 downto 2) <= (others=>'0');
process(p_in_clk)
begin
  if p_in_clk'event and p_in_clk='1' then
    tst_fsm_cs_dly <= tst_fsm_cs;
  end if;
end process;
tst_fsm_cs <= CONV_STD_LOGIC_VECTOR(16#01#,tst_fsm_cs'length) when fsm_cs = S_SYN       else
              CONV_STD_LOGIC_VECTOR(16#00#,tst_fsm_cs'length);   --fsm_cs = S_PIX       else


--//----------------------------------
--//CFG
--//----------------------------------
process(p_in_rst, p_in_clk)
begin
  if p_in_rst = '1' then
    i_div <= '0';
    i_div_cnt <= (others=>'0');

  elsif rising_edge(p_in_clk) then
    i_div_cnt <= i_div_cnt + 1;


    if p_in_mode(2 downto 0) = "100" then --480 fps
          i_div <= '1';

    elsif p_in_mode(2 downto 0) = "011" then --240 fps
          i_div <= i_div_cnt(0);

    elsif p_in_mode(2 downto 0) = "010" then --120 fps
        if i_div_cnt(1 downto 0) = "11" then
          i_div <= '1';
        else
          i_div <= '0';
        end if;

    elsif p_in_mode(2 downto 0) = "001" then --60 fps
        if i_div_cnt(2 downto 0) = "111" then
          i_div <= '1';
        else
          i_div <= '0';
        end if;

    elsif p_in_mode(2 downto 0) = "000" then --30 fps
        if i_div_cnt(3 downto 0) = "1111" then
          i_div <= '1';
        else
          i_div <= '0';
        end if;

    end if;
  end if;
end process;


--//----------------------------------
--//Video
--//----------------------------------
gen_vd : for i in 0 to G_VD_WIDTH/8 - 1 generate
--p_out_vd((i_vd(i)'length * (i+1)) - 1 downto (i_vd(i)'length * i)) <= i_vd(i);
p_out_vd((8 * (i+1)) - 1 downto (8* i)) <= i_pix_cnt(7 downto 0);
end generate gen_vd;
p_out_vs <= i_vs when G_VSYN_ACTIVE = '1' else not i_vs;
p_out_hs <= i_hs when G_VSYN_ACTIVE = '1' else not i_hs;
p_out_vclk <= p_in_clk;
p_out_vclk_en <= i_div;

process(p_in_rst, p_in_clk)
begin
  if p_in_rst = '1' then
--    for i in 0 to i_vd'length - 1 loop
--    i_vd(i) <= CONV_STD_LOGIC_VECTOR(i, i_vd(i)'length);
--    end loop;
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
--            for i in 0 to i_vd'length - 1 loop
--            i_vd(i) <= CONV_STD_LOGIC_VECTOR(i, i_vd(i)'length);
--            end loop;
            i_hs <= '1';

            if i_row_cnt = (p_in_vrow - 1) then
              i_vs <= '1';
              i_row_cnt <= (others=>'0');
            else
              i_row_cnt <= i_row_cnt + 1;
            end if;

            fsm_cs <= S_SYN;

          else
            i_pix_cnt <= i_pix_cnt + 1;
--            for i in 0 to i_vd'length - 1 loop
--            i_vd(i) <= CONV_STD_LOGIC_VECTOR(i_vd'length, i_vd(i)'length);
--            end loop;
          end if;

      --------------------------------------
      --
      --------------------------------------
      when S_SYN =>

          if i_pix_cnt = (p_in_syn - 1) then
            i_pix_cnt <= (others=>'0');
            i_hs <= '0';
            i_vs <= '0';
            fsm_cs <= S_PIX;
          else
            i_pix_cnt <= i_pix_cnt + 1;
          end if;

    end case;

  end if;
  end if;
end process;


--END MAIN
end behavioral;
