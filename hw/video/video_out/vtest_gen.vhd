-------------------------------------------------------------------------
-- Engineer    : Golovachenko Victor
--
-- Create Date : 21.07.2014 10:23:17
-- Module Name : vtest_gen
--
-- Description :
--
--7..4 -  --0/1/2/    - Test picture: V+H Counter/ V Counter/ H Counter/
--Vertical Counter - gradiet from left to right
--Horizontal Counter - gradiet from top to bottom
--
-- architecture test_gen_1:
-- p_in_syn_h --set count clk for horisontal sync
-- p_in_syn_v --set count clk for vertical sync
--
-- until p_out_vs is valid port p_out_hs not change value!!!!
--
-- architecture test_gen_2:
-- p_in_syn_h --set count clk for horisontal sync
-- p_in_syn_v --set count line(hs+pixcount) for vertical sync
--
-- port p_out_vs and port p_out_hs  change value independently
--------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.vicg_common_pkg.all;

entity vtest_gen is
generic(
G_DBG : string := "OFF";
G_VD_WIDTH : integer := 80;
G_VSYN_ACTIVE : std_logic := '1'
);
port(
--CFG
p_in_cfg      : in   std_logic_vector(15 downto 0);
p_in_vpix     : in   std_logic_vector(15 downto 0);--VFrame:Pixel count
p_in_vrow     : in   std_logic_vector(15 downto 0);--VFrame:Line count
p_in_syn_h    : in   std_logic_vector(15 downto 0);--Width HS (clk count)
p_in_syn_v    : in   std_logic_vector(15 downto 0);--Width VS (clk count)

--Test Video
p_out_vd      : out  std_logic_vector(G_VD_WIDTH - 1 downto 0);
p_out_vs      : out  std_logic;
p_out_hs      : out  std_logic;

--DBG
p_in_tst      : in   std_logic_vector(31 downto 0);
p_out_tst     : out  std_logic_vector(31 downto 0);

--System
p_in_clk_en   : in   std_logic;
p_in_clk      : in   std_logic;
p_in_rst      : in   std_logic
);
end entity vtest_gen;

architecture test_gen_1 of vtest_gen is

type fsm_state is (
S_PIX,
S_SYN_H,
S_SYN_V
);
signal fsm_cs : fsm_state;
signal i_cfg                : std_logic_vector(p_in_cfg'range);
type TVData is array (0 to (G_VD_WIDTH / 8) -  1) of unsigned(7 downto 0);
signal i_vd                 : TVData;
signal i_pix_cnt            : unsigned(p_in_vpix'range) := (others => '0');
signal i_row_cnt            : unsigned(p_in_vrow'range) := (others => '0');
signal i_hs                 : std_logic := not G_VSYN_ACTIVE;
signal i_vs                 : std_logic := not G_VSYN_ACTIVE;
signal i_vd_out             : std_logic_vector(G_VD_WIDTH - 1 downto 0) := (others => '0');
signal i_row_half           : std_logic;
signal i_vrow_half_count    : unsigned(i_row_cnt'range);
signal tst_fsm_cs,tst_fsm_cs_dly: unsigned(1 downto 0) := (others => '0');

signal sr_hs                : std_logic := not G_VSYN_ACTIVE;
signal sr_vs                : std_logic := not G_VSYN_ACTIVE;
signal sr_vd_out            : std_logic_vector(G_VD_WIDTH - 1 downto 0) := (others => '0');
signal sr_row_half          : std_logic_vector(0 to 1);
signal i_row_half_edge      : std_logic;


begin --architecture test_gen_1

------------------------------------
--DBG
------------------------------------
gen_dbg_off : if strcmp(G_DBG, "OFF") generate
p_out_tst <= (others => '0');
end generate gen_dbg_off;

gen_dbg_on : if strcmp(G_DBG, "ON") generate
p_out_tst(1 downto 0) <= std_logic_vector(tst_fsm_cs_dly);
p_out_tst(2) <= i_row_half;
p_out_tst(3) <= i_row_half_edge;
p_out_tst(31 downto 4) <= (others => '0');
process(p_in_clk)
begin
  if rising_edge(p_in_clk) then
    if p_in_clk_en = '1' then
      tst_fsm_cs_dly <= tst_fsm_cs;
      sr_row_half <= i_row_half & sr_row_half(0 to 0);
      i_row_half_edge <= sr_row_half(0) and not sr_row_half(1);
    end if;
  end if;
end process;
tst_fsm_cs <= TO_UNSIGNED(16#02#,tst_fsm_cs'length) when fsm_cs = S_SYN_V else
              TO_UNSIGNED(16#01#,tst_fsm_cs'length) when fsm_cs = S_SYN_H else
              TO_UNSIGNED(16#00#,tst_fsm_cs'length);   --fsm_cs = S_PIX      else
end generate gen_dbg_on;


------------------------------------
--CFG
------------------------------------
process(p_in_clk)
begin
if rising_edge(p_in_clk) then
  if p_in_rst = '1' then
    i_cfg <= (others => '0');
  else
  if p_in_clk_en = '1' then
      if i_vs = '1' then
      i_cfg <= p_in_cfg;
      end if;
  end if;
  end if;
end if;--p_in_rst,
end process;

------------------------------------
--Video
------------------------------------
p_out_vd <= i_vd_out;
p_out_vs <= i_vs;
p_out_hs <= i_hs;

i_vrow_half_count <= RESIZE(UNSIGNED(p_in_vrow(p_in_vrow'length - 1 downto 1))
                                                    , i_vrow_half_count'length);

--vsync
process(p_in_clk)
begin
if rising_edge(p_in_clk) then
  if p_in_rst = '1' then
    i_hs <= not G_VSYN_ACTIVE;
    i_vs <= not G_VSYN_ACTIVE;
    i_row_half <= '0';
    i_pix_cnt <= (others => '0');
    i_row_cnt <= (others => '0');
    fsm_cs <= S_SYN_H;

  else
  if p_in_clk_en = '1' then

    case fsm_cs is
      --------------------------------------
      --
      --------------------------------------
      when S_PIX =>
          if i_pix_cnt = (UNSIGNED(p_in_vpix) - 1) then
            i_pix_cnt <= (others => '0');

            if i_row_cnt = (UNSIGNED(p_in_vrow) - 1) then
              i_vs <= G_VSYN_ACTIVE;
              i_row_cnt <= (others => '0');
              fsm_cs <= S_SYN_V;
            else
              i_hs <= G_VSYN_ACTIVE;
              i_row_cnt <= i_row_cnt + 1;
              fsm_cs <= S_SYN_H;
            end if;

            if i_row_cnt = (i_vrow_half_count - 1) then
              i_row_half <= '1';
            end if;

          else
            i_pix_cnt <= i_pix_cnt + 1;
          end if;

      --------------------------------------
      --
      --------------------------------------
      when S_SYN_H =>

          if i_pix_cnt = (UNSIGNED(p_in_syn_h) - 1) then
            i_pix_cnt <= (others => '0');
            i_hs <= not G_VSYN_ACTIVE;
            fsm_cs <= S_PIX;
          else
            i_pix_cnt <= i_pix_cnt + 1;
          end if;

      --------------------------------------
      --
      --------------------------------------
      when S_SYN_V =>

          if i_pix_cnt = (UNSIGNED(p_in_syn_v) - 1) then
            i_pix_cnt <= (others => '0');
            i_vs <= not G_VSYN_ACTIVE; i_row_half <= '0';
            i_hs <= G_VSYN_ACTIVE;
            fsm_cs <= S_SYN_H;
          else
            i_pix_cnt <= i_pix_cnt + 1;
          end if;

    end case;

  end if;
  end if;
end if;--p_in_rst,
end process;

--gen test data
process(p_in_clk)
begin
if rising_edge(p_in_clk) then
  if p_in_rst = '1' then
    for i in 0 to (G_VD_WIDTH / 8) - 1 loop
    i_vd(i) <= TO_UNSIGNED(i, i_vd(i)'length);
    end loop;
  else
  if p_in_clk_en = '1' then

      if i_cfg(5 downto 4) = "01" then
      --(V Counter - gradiet from left to right)
          if i_hs = G_VSYN_ACTIVE or i_vs = G_VSYN_ACTIVE then
            for i in 0 to (G_VD_WIDTH / 8) - 1 loop
            i_vd(i) <= TO_UNSIGNED(i, i_vd(i)'length);
            end loop;
          else
            for i in 0 to (G_VD_WIDTH / 8) - 1 loop
            i_vd(i) <= i_vd(i) + TO_UNSIGNED((G_VD_WIDTH / 8), i_vd(i)'length);
            end loop;
          end if;

      elsif i_cfg(5 downto 4) = "10" then
      --(H Counter - gradiet from top to bottom)
          if i_vs = G_VSYN_ACTIVE then
            for i in 0 to (G_VD_WIDTH / 8) - 1 loop
            i_vd(i) <= (others => '0');
            end loop;
          else
            for i in 0 to (G_VD_WIDTH / 8) - 1 loop
            i_vd(i) <= i_row_cnt(i_vd(i)'range);
            end loop;
          end if;

      elsif i_cfg(5 downto 4) = "00" then
      --(1/2 vfr - V Count; 1/2 vfr - H Count)
        if i_row_half = '0' then
          if i_hs = G_VSYN_ACTIVE or i_vs = G_VSYN_ACTIVE then
            for i in 0 to (G_VD_WIDTH / 8) - 1 loop
            i_vd(i) <= TO_UNSIGNED(i, i_vd(i)'length);
            end loop;
          else
            for i in 0 to (G_VD_WIDTH / 8) - 1 loop
            i_vd(i) <= i_vd(i) + TO_UNSIGNED((G_VD_WIDTH / 8), i_vd(i)'length);
            end loop;
          end if;
        else
          if i_vs = G_VSYN_ACTIVE then
            for i in 0 to (G_VD_WIDTH / 8) - 1 loop
            i_vd(i) <= TO_UNSIGNED(i, i_vd(i)'length);
            end loop;
          else
            for i in 0 to (G_VD_WIDTH / 8) - 1 loop
            i_vd(i) <= i_row_cnt(i_vd(i)'range);
            end loop;
          end if;
        end if;
      end if;

  end if;
  end if;
end if;--p_in_rst,
end process;

gen_vd : for i in 0 to (G_VD_WIDTH / 8) - 1 generate
i_vd_out((i_vd(i)'length * (i + 1)) - 1 downto (i_vd(i)'length * i)) <= std_logic_vector(i_vd(i));
end generate gen_vd;


end architecture test_gen_1;



--######################################################################################
--
--######################################################################################
architecture test_gen_2 of vtest_gen is

type TFsm_sync is (
S_DOUT,
S_SYN
);

signal i_fsm_hs_cs          : TFsm_sync;
signal i_fsm_vs_cs          : TFsm_sync;
signal i_cfg                : std_logic_vector(p_in_cfg'range);
type TVData is array (0 to (G_VD_WIDTH / 8) -  1) of unsigned(7 downto 0);
signal i_vd                 : TVData;
signal i_pix_cnt            : unsigned(p_in_vpix'range) := (others => '0');
signal i_row_cnt            : unsigned(p_in_vrow'range) := (others => '0');
signal i_hs                 : std_logic := not G_VSYN_ACTIVE;
signal i_vs                 : std_logic := not G_VSYN_ACTIVE;
signal i_vd_out             : std_logic_vector(G_VD_WIDTH - 1 downto 0) := (others => '0');
signal i_row_half           : std_logic;
signal i_vrow_half_count    : unsigned(i_row_cnt'range);
signal tst_i_fsm_hs_cs,tst_i_fsm_hs_cs_dly: unsigned(1 downto 0) := (others => '0');

signal sr_hs                : std_logic := not G_VSYN_ACTIVE;
signal sr_vs                : std_logic := not G_VSYN_ACTIVE;
signal sr_vd_out            : std_logic_vector(G_VD_WIDTH - 1 downto 0) := (others => '0');
signal sr_row_half          : std_logic_vector(0 to 1);
signal i_row_half_edge      : std_logic;


begin --architecture test_gen_2

------------------------------------
--DBG
------------------------------------
gen_dbg_off : if strcmp(G_DBG, "OFF") generate
p_out_tst <= (others => '0');
end generate gen_dbg_off;

gen_dbg_on : if strcmp(G_DBG, "ON") generate
p_out_tst(1 downto 0) <= std_logic_vector(tst_i_fsm_hs_cs_dly);
p_out_tst(2) <= i_row_half;
p_out_tst(3) <= i_row_half_edge;
p_out_tst(31 downto 4) <= (others => '0');
process(p_in_clk)
begin
  if rising_edge(p_in_clk) then
    if p_in_clk_en = '1' then
      tst_i_fsm_hs_cs_dly <= tst_i_fsm_hs_cs;
      sr_row_half <= i_row_half & sr_row_half(0 to 0);
      i_row_half_edge <= sr_row_half(0) and not sr_row_half(1);
    end if;
  end if;
end process;
--tst_i_fsm_hs_cs <= TO_UNSIGNED(16#02#,tst_i_fsm_hs_cs'length) when i_fsm_hs_cs = S_SYN_V else
tst_i_fsm_hs_cs <= TO_UNSIGNED(16#01#,tst_i_fsm_hs_cs'length) when i_fsm_hs_cs = S_SYN else
              TO_UNSIGNED(16#00#,tst_i_fsm_hs_cs'length);   --i_fsm_hs_cs = S_PIX      else
end generate gen_dbg_on;


------------------------------------
--CFG
------------------------------------
process(p_in_clk)
begin
if rising_edge(p_in_clk) then
  if p_in_rst = '1' then
    i_cfg <= (others => '0');
  else
  if p_in_clk_en = '1' then
      if i_vs = '1' then
      i_cfg <= p_in_cfg;
      end if;
  end if;
  end if;
end if;--p_in_rst,
end process;

------------------------------------
--Video
------------------------------------
p_out_vd <= i_vd_out;
p_out_vs <= i_vs;
p_out_hs <= i_hs;

i_vrow_half_count <= RESIZE(UNSIGNED(p_in_vrow(p_in_vrow'length - 1 downto 1))
                                                    , i_vrow_half_count'length);

--vsync
process(p_in_clk)
begin
if rising_edge(p_in_clk) then
  if p_in_rst = '1' then
    i_hs <= not G_VSYN_ACTIVE;
    i_vs <= not G_VSYN_ACTIVE;
    i_row_half <= '0';
    i_pix_cnt <= (others => '0');
    i_row_cnt <= (others => '0');
    i_fsm_hs_cs <= S_DOUT;
    i_fsm_vs_cs <= S_DOUT;

  else
  if p_in_clk_en = '1' then

    --------------------------------------
    --Horizontal synch
    --------------------------------------
    case i_fsm_hs_cs is
      when S_DOUT =>
          if i_pix_cnt = (UNSIGNED(p_in_vpix) - 1) then
            i_pix_cnt <= (others => '0');
            i_hs <= G_VSYN_ACTIVE;
            i_fsm_hs_cs <= S_SYN;
          else
            i_pix_cnt <= i_pix_cnt + 1;
          end if;

      when S_SYN =>

          if i_pix_cnt = (UNSIGNED(p_in_syn_h) - 1) then
            i_pix_cnt <= (others => '0');
            i_hs <= not G_VSYN_ACTIVE;
            i_fsm_hs_cs <= S_DOUT;
          else
            i_pix_cnt <= i_pix_cnt + 1;
          end if;

    end case;

    --------------------------------------
    --Vertical synch
    --------------------------------------
    case i_fsm_vs_cs is
      when S_DOUT =>
          if i_pix_cnt = (UNSIGNED(p_in_vpix) - 1) then

            if i_row_cnt = (UNSIGNED(p_in_vrow) - 1) then
              i_vs <= G_VSYN_ACTIVE;
              i_row_cnt <= (others => '0');
              i_fsm_vs_cs <= S_SYN;
            else
              i_row_cnt <= i_row_cnt + 1;
            end if;

            if i_row_cnt = (i_vrow_half_count - 1) then
              i_row_half <= '1';
            end if;
          end if;

      when S_SYN =>

          if i_pix_cnt = (UNSIGNED(p_in_vpix) - 1) then
            if i_row_cnt = (UNSIGNED(p_in_syn_v) - 1) then
              i_vs <= not G_VSYN_ACTIVE; i_row_half <= '0';
              i_row_cnt <= (others => '0');
              i_fsm_vs_cs <= S_DOUT;
            else
              i_row_cnt <= i_row_cnt + 1;
            end if;
          end if;

    end case;

  end if;
  end if;
end if;--p_in_rst,
end process;

--gen test data
process(p_in_clk)
begin
if rising_edge(p_in_clk) then
  if p_in_rst = '1' then
    for i in 0 to (G_VD_WIDTH / 8) - 1 loop
    i_vd(i) <= TO_UNSIGNED(i, i_vd(i)'length);
    end loop;
  else
  if p_in_clk_en = '1' then

      if i_cfg(5 downto 4) = "01" then
      --(V Counter - gradiet from left to right)
          if i_hs = G_VSYN_ACTIVE or i_vs = G_VSYN_ACTIVE then
            for i in 0 to (G_VD_WIDTH / 8) - 1 loop
            i_vd(i) <= TO_UNSIGNED(i, i_vd(i)'length);
            end loop;
          else
            for i in 0 to (G_VD_WIDTH / 8) - 1 loop
            i_vd(i) <= i_vd(i) + TO_UNSIGNED((G_VD_WIDTH / 8), i_vd(i)'length);
            end loop;
          end if;

      elsif i_cfg(5 downto 4) = "10" then
      --(H Counter - gradiet from top to bottom)
          if i_vs = G_VSYN_ACTIVE then
            for i in 0 to (G_VD_WIDTH / 8) - 1 loop
            i_vd(i) <= (others => '0');
            end loop;
          else
            for i in 0 to (G_VD_WIDTH / 8) - 1 loop
            i_vd(i) <= i_row_cnt(i_vd(i)'range);
            end loop;
          end if;

      elsif i_cfg(5 downto 4) = "00" then
      --(1/2 vfr - V Count; 1/2 vfr - H Count)
        if i_row_half = '0' then
          if i_hs = G_VSYN_ACTIVE or i_vs = G_VSYN_ACTIVE then
            for i in 0 to (G_VD_WIDTH / 8) - 1 loop
            i_vd(i) <= TO_UNSIGNED(i, i_vd(i)'length);
            end loop;
          else
            for i in 0 to (G_VD_WIDTH / 8) - 1 loop
            i_vd(i) <= i_vd(i) + TO_UNSIGNED((G_VD_WIDTH / 8), i_vd(i)'length);
            end loop;
          end if;
        else
          if i_vs = G_VSYN_ACTIVE then
            for i in 0 to (G_VD_WIDTH / 8) - 1 loop
            i_vd(i) <= TO_UNSIGNED(i, i_vd(i)'length);
            end loop;
          else
            for i in 0 to (G_VD_WIDTH / 8) - 1 loop
            i_vd(i) <= i_row_cnt(i_vd(i)'range);
            end loop;
          end if;
        end if;
      end if;

  end if;
  end if;
end if;--p_in_rst,
end process;

gen_vd : for i in 0 to (G_VD_WIDTH / 8) - 1 generate
i_vd_out((i_vd(i)'length * (i + 1)) - 1 downto (i_vd(i)'length * i)) <= std_logic_vector(i_vd(i));
end generate gen_vd;


end architecture test_gen_2;
