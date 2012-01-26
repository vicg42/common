-------------------------------------------------------------------------
-- Company     : Linkos
-- Engineer    : Golovachenko Victor
--
-- Create Date : 21.01.2012 12:31:12
-- Module Name : video_ctrl_tb
--
-- Назначение/Описание :
--
-- Revision:
-- Revision 0.01 - File Created
-------------------------------------------------------------------------
--library ieee;
--use ieee.std_logic_1164.all;
--use ieee.std_logic_arith.all;
----use ieee.std_logic_misc.all;
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

library unisim;
use unisim.vcomponents.all;

library work;
use work.vicg_common_pkg.all;
use work.video_ctrl_pkg.all;
use work.mem_wr_pkg.all;
use work.mem_ctrl_pkg.all;

entity video_ctrl_tb is
generic(
G_SIM    : string:="ON";
G_MEM_AWIDTH : integer:=32;
G_MEM_DWIDTH : integer:=32
);
end video_ctrl_tb;

architecture behavioral of video_ctrl_tb is

component video_ctrl
generic(
G_SIM    : string:="OFF";
G_MEM_AWIDTH : integer:=32;
G_MEM_DWIDTH : integer:=32
);
port(
-------------------------------
--Параметры Видеокадра
-------------------------------
p_in_vfr_prm          : in  TFrXY;

----------------------------
--Связь с вх/вых видеобуферами
----------------------------
--Вх
p_in_vbufin_d         : in    std_logic_vector(31 downto 0);
p_out_vbufin_rd       : out   std_logic;
p_in_vbufin_empty     : in    std_logic;
--Вых
p_out_vbufout_d       : out   std_logic_vector(31 downto 0);
p_out_vbufout_wr      : out   std_logic;
p_in_vbufout_full     : in    std_logic;

---------------------------------
--Связь с mem_ctrl.vhd
---------------------------------
--CH WRITE
p_out_memwr           : out   TMemIN;
p_in_memwr            : in    TMemOUT;
--CH READ
p_out_memrd           : out   TMemIN;
p_in_memrd            : in    TMemOUT;

-------------------------------
--Технологический
-------------------------------
p_out_tst             : out   std_logic_vector(31 downto 0);

-------------------------------
--System
-------------------------------
p_in_clk              : in    std_logic;
p_in_rst              : in    std_logic
);
end component;

component vin_bufcam
port(
din    : in std_logic_vector(31 downto 0);
wr_en  : in std_logic;
wr_clk : in std_logic;

dout   : out std_logic_vector(31 downto 0);
rd_en  : in std_logic;
rd_clk : in std_logic;

full   : out std_logic;
empty  : out std_logic;

rst    : in std_logic
);
end component;

component ddr2_model_c5 is
port (
ck      : in    std_logic;
ck_n    : in    std_logic;
cke     : in    std_logic;
cs_n    : in    std_logic;
ras_n   : in    std_logic;
cas_n   : in    std_logic;
we_n    : in    std_logic;
dm_rdqs : inout std_logic_vector((C5_NUM_DQ_PINS/16) downto 0);
ba      : in    std_logic_vector((C5_MEM_BANKADDR_WIDTH - 1) downto 0);
addr    : in    std_logic_vector((C5_MEM_ADDR_WIDTH  - 1) downto 0);
dq      : inout std_logic_vector((C5_NUM_DQ_PINS - 1) downto 0);
dqs     : inout std_logic_vector((C5_NUM_DQ_PINS/16) downto 0);
dqs_n   : inout std_logic_vector((C5_NUM_DQ_PINS/16) downto 0);
rdqs_n  : out   std_logic_vector((C5_NUM_DQ_PINS/16) downto 0);
odt     : in    std_logic
);
end component;

--constant C5_CLK_PERIOD_NS   : real := 3200.0 / 1000.0;
constant C5_CLK_PERIOD_NS   : real := 2600.0 / 1000.0;
constant C5_TCYC_SYS        : real := C5_CLK_PERIOD_NS/2.0;
constant C5_TCYC_SYS_DIV2   : time := C5_TCYC_SYS * 1 ns;

constant PERIOD_VIN_CLK     : time := 30 * 1 ns;
constant PERIOD_VOUT_CLK    : time := 60 * 1 ns;

signal i_rst                   : std_logic;
signal p_in_rst                : std_logic;
signal p_in_clk                : std_logic := '0';

signal i_memch0_in_bank        : TMemINBank;
signal i_memch0_out_bank       : TMemOUTBank;
signal i_memch1_in_bank        : TMemINBank;
signal i_memch1_out_bank       : TMemOUTBank;

signal i_mem_ctrl_rdy          : std_logic_vector(C_MEM_BANK_COUNT-1 downto 0);

signal p_out_phymem           : TRam_outs  ;
signal p_inout_phymem         : TRam_inouts;

type TV01   is array(0 to C_MEM_BANK_COUNT-1) of std_logic_vector(1 downto 0) ;
type TV02   is array(0 to C_MEM_BANK_COUNT-1) of std_logic_vector(2 downto 0) ;
signal mcb5_dram_dqs_vector   : TV01;
signal mcb5_dram_dqs_n_vector : TV01;
signal mcb5_dram_dm_vector    : TV01;
signal mcb5_command           : TV02;
signal mcb5_enable1           : std_logic_vector(C_MEM_BANK_COUNT-1 downto 0);
signal mcb5_enable2           : std_logic_vector(C_MEM_BANK_COUNT-1 downto 0);
signal rzq5                   : std_logic_vector(C_MEM_BANK_COUNT-1 downto 0);
signal zio5                   : std_logic_vector(C_MEM_BANK_COUNT-1 downto 0);

signal i_vctrl_rst            : std_logic;
signal i_vfr_prm              : TFrXY;

signal i_vin_d                : std_logic_vector(31 downto 0):=(others=>'0');
signal i_vin_dwr              : std_logic:='0';
signal i_vin_clk              : std_logic:='0';
signal i_vout_d               : std_logic_vector(31 downto 0):=(others=>'0');
signal i_vout_clk             : std_logic:='0';

signal i_vbufin_d             : std_logic_vector(31 downto 0);
signal i_vbufin_rd            : std_logic;
signal i_vbufin_empty         : std_logic;
signal i_vbufout_d            : std_logic_vector(31 downto 0);
signal i_vbufout_wr           : std_logic;
signal i_vbufout_full         : std_logic;


constant CI_FRPIX : integer:=64;
constant CI_FRROW : integer:=64;

--MAIN
begin

-- ========================================================================== --
-- Clocks Generation                                                          --
-- ========================================================================== --
process
begin
  p_in_clk <= not p_in_clk;
  wait for (C5_TCYC_SYS_DIV2);
end process;


process
begin
  i_vin_clk <= not i_vin_clk;
  wait for (PERIOD_VIN_CLK);
end process;

process
begin
  i_vout_clk <= not i_vout_clk;
  wait for (PERIOD_VOUT_CLK);
end process;

-- ========================================================================== --
-- Reset Generation                                                           --
-- ========================================================================== --
process
begin
  i_rst <= '0';
  wait for 200 ns;
  i_rst <= '1';
  wait;
end process;

p_in_rst <= i_rst when (C5_RST_ACT_LOW = 1) else (not i_rst);



i_vctrl_rst<=not i_mem_ctrl_rdy(0) or p_in_rst;


i_vfr_prm.pix     <=CONV_STD_LOGIC_VECTOR(CI_FRPIX, i_vfr_prm.pix'length);
i_vfr_prm.row     <=CONV_STD_LOGIC_VECTOR(CI_FRROW, i_vfr_prm.pix'length);
i_vfr_prm.total_dw<=CONV_STD_LOGIC_VECTOR((CI_FRROW*CI_FRROW), i_vfr_prm.total_dw'length);

process(i_vctrl_rst,i_vin_clk)
begin
  if i_vctrl_rst='1' then
    i_vin_d<=(others=>'0');
    i_vin_dwr<='0';
  elsif i_vin_clk'event and i_vin_clk='1' then
    i_vin_dwr<= not i_vin_dwr;

    if i_vin_dwr='1' then
    i_vin_d<=i_vin_d + 1;
    end if;
  end if;
end process;


m_vin_buf : vin_bufcam
port map(
din    => i_vin_d,
wr_en  => i_vin_dwr,
wr_clk => i_vin_clk,

dout   => i_vbufin_d,
rd_en  => i_vbufin_rd,
rd_clk => p_in_clk,

full   => open,
empty  => i_vbufin_empty,

rst    => i_vctrl_rst
);

m_vout_buf : vin_bufcam
port map(
din    => i_vbufout_d,
wr_en  => i_vbufout_wr,
wr_clk => p_in_clk,

dout   => i_vout_d,
rd_en  => '1',
rd_clk => i_vout_clk,

full   => i_vbufout_full,
empty  => open,

rst    => i_vctrl_rst
);

m_vctrl : video_ctrl
generic map(
G_SIM => G_SIM,
G_MEM_AWIDTH => G_MEM_AWIDTH,
G_MEM_DWIDTH => G_MEM_DWIDTH
)
port map(
-------------------------------
--Параметры Видеокадра
-------------------------------
p_in_vfr_prm          => i_vfr_prm,

----------------------------
--Связь с вх/вых видеобуферами
----------------------------
--in
p_in_vbufin_d         => i_vbufin_d,
p_out_vbufin_rd       => i_vbufin_rd,
p_in_vbufin_empty     => i_vbufin_empty,
--out
p_out_vbufout_d       => i_vbufout_d,
p_out_vbufout_wr      => i_vbufout_wr,
p_in_vbufout_full     => i_vbufout_full,

---------------------------------
--Связь с mem_ctrl.vhd
---------------------------------
--CH WRITE
p_out_memwr           => i_memch0_in_bank(0), --: out   TMemIN;
p_in_memwr            => i_memch0_out_bank(0),--: in    TMemOUT;
--CH READ
p_out_memrd           => i_memch1_in_bank(0), --: out   TMemIN;
p_in_memrd            => i_memch1_out_bank(0),--: in    TMemOUT;

-------------------------------
--Технологический
-------------------------------
p_out_tst             => open,

-------------------------------
--System
-------------------------------
p_in_clk              => p_in_clk,
p_in_rst              => i_vctrl_rst
);


m_mem_ctrl : mem_ctrl
generic map(
G_SIM => G_SIM
)
port map(
------------------------------------
--User Post
------------------------------------
p_in_memch0     => i_memch0_in_bank, --: in    TMemINBank;
p_out_memch0    => i_memch0_out_bank,--: out   TMemOUTBank;

p_in_memch1     => i_memch1_in_bank, --: in    TMemINBank;
p_out_memch1    => i_memch1_out_bank,--: out   TMemOUTBank;

------------------------------------
--Memory physical interface
------------------------------------
p_out_phymem    => p_out_phymem,
p_inout_phymem  => p_inout_phymem,

------------------------------------
--Memory status
------------------------------------
p_out_mem_rdy   => i_mem_ctrl_rdy,

------------------------------------
--System
------------------------------------
--c5_clk0         : out   std_logic;
--c5_rst0         : out   std_logic;
p_in_clk        => p_in_clk,
p_in_rst        => p_in_rst
);




gen_bank : for i in 0 to C_MEM_BANK_COUNT-1 generate
-- ========================================================================== --
-- Memory model instances                                                     --
-- ========================================================================== --
-- The PULLDOWN component is connected to the ZIO signal primarily to avoid the
-- unknown state in simulation. In real hardware, ZIO should be a no connect(NC) pin.

mcb5_command(i) <= (p_out_phymem(i).ras_n & p_out_phymem(i).cas_n & p_out_phymem(i).we_n);

process(p_out_phymem(i).ck)--mcb5_dram_ck)
begin
  if (rising_edge(p_out_phymem(i).ck)) then --if (rising_edge(mcb5_dram_ck)) then
    if (i_rst = '0') then
      mcb5_enable1(i) <= '0';
      mcb5_enable2(i) <= '0';
    elsif (mcb5_command(i) = "100") then
      mcb5_enable2(i) <= '0';
    elsif (mcb5_command(i) = "101") then
      mcb5_enable2(i) <= '1';
    else
      mcb5_enable2(i) <= mcb5_enable2(i);
    end if;
    mcb5_enable1(i)   <= mcb5_enable2(i);
  end if;
end process;

-----------------------------------------------------------------------------
--read
-----------------------------------------------------------------------------
mcb5_dram_dqs_vector(i)(1 downto 0)  <= (p_inout_phymem(i).udqs & p_inout_phymem(i).dqs)     when (mcb5_enable2(i) = '0' and mcb5_enable1(i) = '0') else "ZZ";
mcb5_dram_dqs_n_vector(i)(1 downto 0)<= (p_inout_phymem(i).udqs_n & p_inout_phymem(i).dqs_n) when (mcb5_enable2(i) = '0' and mcb5_enable1(i) = '0') else "ZZ";

-----------------------------------------------------------------------------
--write
-----------------------------------------------------------------------------
p_inout_phymem(i).dqs    <= mcb5_dram_dqs_vector(i)(0)   when (mcb5_enable1(i) = '1') else 'Z';
p_inout_phymem(i).udqs   <= mcb5_dram_dqs_vector(i)(1)   when (mcb5_enable1(i) = '1') else 'Z';
p_inout_phymem(i).dqs_n  <= mcb5_dram_dqs_n_vector(i)(0) when (mcb5_enable1(i) = '1') else 'Z';
p_inout_phymem(i).udqs_n <= mcb5_dram_dqs_n_vector(i)(1) when (mcb5_enable1(i) = '1') else 'Z';

mcb5_dram_dm_vector(i) <= (p_out_phymem(i).udm & p_out_phymem(i).dm);

u_mem_c5 : ddr2_model_c5
port map(
ck        => p_out_phymem(i).ck,--mcb5_dram_ck,
ck_n      => p_out_phymem(i).ck_n,--mcb5_dram_ck_n,
cke       => p_out_phymem(i).cke,--mcb5_dram_cke,
cs_n      => '0',
ras_n     => p_out_phymem(i).ras_n,--mcb5_dram_ras_n,
cas_n     => p_out_phymem(i).cas_n,--mcb5_dram_cas_n,
we_n      => p_out_phymem(i).we_n,--mcb5_dram_we_n,
dm_rdqs   => mcb5_dram_dm_vector(i),
ba        => p_out_phymem(i).ba,--mcb5_dram_ba,
addr      => p_out_phymem(i).a,--mcb5_dram_a,
dq        => p_inout_phymem(i).dq,--mcb5_dram_dq,
dqs       => mcb5_dram_dqs_vector(i),
dqs_n     => mcb5_dram_dqs_n_vector(i),
rdqs_n    => open,
odt       => p_out_phymem(i).odt --mcb5_dram_odt
);

zio_pulldown5 : PULLDOWN port map(O => p_inout_phymem(i).zio);--zio5);
rzq_pulldown5 : PULLDOWN port map(O => p_inout_phymem(i).rzq);--rzq5);

end generate gen_bank;


--END MAIN
end behavioral;

