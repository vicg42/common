
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity vtest_gen_tb is
generic(
G_DBG : string := "OFF";
G_VD_WIDTH : integer := 256;
G_VSYN_ACTIVE : std_logic := '0'
);
port(
p_out_vden    : out  std_logic;
p_out_vd      : out  std_logic_vector(G_VD_WIDTH - 1 downto 0);
p_out_vs      : out  std_logic;
p_out_hs      : out  std_logic
);
end vtest_gen_tb;

architecture behavior of vtest_gen_tb is

--  определяем частоты генераторов на плате:
constant period_sys_clk       : time := 56.388 ns;--17,733990147783251231527093596059 mhz

component vtest_gen is
generic(
G_DBG : string := "off";
G_VD_WIDTH : integer := 80;
G_VSYN_ACTIVE : std_logic := '1'
);
port(
--cfg
p_in_cfg      : in   std_logic_vector(15 downto 0);
p_in_vpix     : in   std_logic_vector(15 downto 0);--кол-во pix
p_in_vrow     : in   std_logic_vector(15 downto 0);--кол-во строк
p_in_syn_h    : in   std_logic_vector(15 downto 0);--ширина hs (кол-во тактов)
p_in_syn_v    : in   std_logic_vector(15 downto 0);--ширина vs (кол-во тактов)

--test video
p_out_vd      : out  std_logic_vector(G_VD_WIDTH - 1 downto 0);
p_out_vs      : out  std_logic;
p_out_hs      : out  std_logic;

--технологический
p_in_tst      : in   std_logic_vector(31 downto 0);
p_out_tst     : out  std_logic_vector(31 downto 0);

--system
p_in_clk_en   : in   std_logic;
p_in_clk      : in   std_logic;
p_in_rst      : in   std_logic
);
end component vtest_gen;

signal i_rst :  std_logic;
signal i_clk :  std_logic;

signal tst_vfr_pixcount  : unsigned(15 downto 0);
signal tst_vfr_rowcount  : unsigned(15 downto 0);
signal tst_vfr_cfg       : unsigned(15 downto 0);
signal tst_vfr_synwidth  : unsigned(15 downto 0);

signal i_video_den       : std_logic;
signal i_video_d         : std_logic_vector(G_VD_WIDTH - 1 downto 0);
signal i_video_vs        : std_logic;
signal i_video_hs        : std_logic;

begin

i_rst <='1', '0'after 500 ns;

board_clk : process
begin
  i_clk<='0';
  wait for period_sys_clk/2;
  i_clk<='1';
  wait for period_sys_clk/2;
end process;


uut : vtest_gen
generic map(
G_DBG => G_DBG,
G_VD_WIDTH => G_VD_WIDTH,
G_VSYN_ACTIVE => G_VSYN_ACTIVE
)
port map(
--CFG
p_in_cfg      => std_logic_vector(tst_vfr_cfg),
p_in_vpix     => std_logic_vector(tst_vfr_pixcount),
p_in_vrow     => std_logic_vector(tst_vfr_rowcount),
p_in_syn_h    => std_logic_vector(tst_vfr_synwidth),
p_in_syn_v    => std_logic_vector(tst_vfr_synwidth),

--Test Video
p_out_vd      => i_video_d,
p_out_vs      => i_video_vs,
p_out_hs      => i_video_hs,

--Технологический
p_in_tst      => (others => '0'),
p_out_tst     => open,

--System
p_in_clk_en   => '1',
p_in_clk      => i_clk,
p_in_rst      => i_rst
);


tst_vfr_pixcount <= TO_UNSIGNED(5120 / (G_VD_WIDTH/8), tst_vfr_pixcount'length);
tst_vfr_rowcount <= TO_UNSIGNED(5120, tst_vfr_rowcount'length);

--3..0 --0/1/2/3/4 - 30fps/60fps/120fps/240fps/480fps/
--7..4 --0/1/2/    - Test picture: V+H Counter/ V Counter/ H Counter/
tst_vfr_cfg <= TO_UNSIGNED(16#00#, tst_vfr_cfg'length);

--tst_vfr_synwidth <= TO_UNSIGNED(384, tst_vfr_synwidth'length);-- for 30fps (dwith 256)
tst_vfr_synwidth <= TO_UNSIGNED(244, tst_vfr_synwidth'length);-- for 30fps (dwith 256)

p_out_vden <= i_video_den;
p_out_vd   <= i_video_d;
p_out_vs   <= i_video_vs;
p_out_hs   <= i_video_hs;

i_video_den <= i_video_hs;


end;
