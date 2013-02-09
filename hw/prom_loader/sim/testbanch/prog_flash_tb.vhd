-------------------------------------------------------------------------
-- Company     : Linkos
-- Engineer    : Golovachenko Victor
--
-- Create Date : 27.11.2012 15:17:16
-- Module Name : prog_flash_tb
--
-- Назначение/Описание :
--
--
-- Revision:
-- Revision 0.01 - File Created
--
-------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_misc.all;
use ieee.std_logic_unsigned.all;

library work;
use work.vicg_common_pkg.all;
use work.prom_phypin_pkg.all;

entity prog_flash_tb is
port(
p_out_rxbuf_d     : out   std_logic_vector(31 downto 0);
p_out_rxbuf_wr    : out   std_logic
);
end prog_flash_tb;

architecture behavioral of prog_flash_tb is

constant C_USRCLK_PERIOD  : TIME := 100 ns;

constant CI_USR_CMD_ADR     : integer:=1;
constant CI_USR_CMD_UNLOCK  : integer:=2;
constant CI_USR_CMD_ERASE   : integer:=3;
constant CI_USR_CMD_DWR     : integer:=4;
constant CI_USR_CMD_DRD     : integer:=5;
constant CI_USR_CMD_DRD_CFI : integer:=6;

constant CI_PHY_DIR_TX      : std_logic:='1';
constant CI_PHY_DIR_RX      : std_logic:='0';

constant CI_FLASH_BLOCK_16KW      : integer:=16#04000#;
constant CI_FLASH_BLOCK_64KW      : integer:=16#10000#;
constant CI_FLASH_BUF_DCOUNT_MAX  : integer:=512;--Word


component prog_flash
generic(
G_USRBUF_DWIDTH : integer := 32;
G_FLASH_AWIDTH : integer := 24;
G_FLASH_DWIDTH : integer := 16
);
port(
--
p_out_txbuf_rd    : out   std_logic;
p_in_txbuf_d      : in    std_logic_vector(G_USRBUF_DWIDTH - 1 downto 0);
p_in_txbuf_empty  : in    std_logic;

p_out_rxbuf_d     : out   std_logic_vector(G_USRBUF_DWIDTH - 1 downto 0);
p_out_rxbuf_wr    : out   std_logic;
p_in_rxbuf_full   : in    std_logic;

--
p_out_irq         : out   std_logic;
p_out_status      : out   std_logic_vector(15 downto 0);

--PHY
p_out_phy_a       : out   std_logic_vector(G_FLASH_AWIDTH - 1 downto 0);
p_in_phy_d        : in    std_logic_vector(G_FLASH_DWIDTH - 1 downto 0);
p_out_phy_d       : out   std_logic_vector(G_FLASH_DWIDTH - 1 downto 0);
p_out_phy_oe      : out   std_logic;
p_out_phy_we      : out   std_logic;
p_out_phy_cs      : out   std_logic;
p_in_phy_wait     : in    std_logic;

--Технологический
p_in_tst          : in    std_logic_vector(31 downto 0);
p_out_tst         : out   std_logic_vector(31 downto 0);

--System
p_in_clk_en       : in    std_logic;
p_in_clk          : in    std_logic;
p_in_rst          : in    std_logic
);
end component;

component x28fxxxp30
port (
A     : in    std_logic_vector(23 downto 0);--input [`ADDRBUS_dim-1:0] // Address Bus
DQ    : inout std_logic_vector(15 downto 0);--inout [`DATABUS_dim-1:0] // Data I/0 Bus

W_N   : in    std_logic;--input // Write Enable
G_N   : in    std_logic;--input // Output Enable
E_N   : in    std_logic;--input // Chip Enable
L_N   : in    std_logic;--input // Latch Enable
K     : in    std_logic;--input // Clock
WP_N  : in    std_logic;--input // Write Protect
RP_N  : in    std_logic;--input // Reset/Power-Down

VDD   : in    std_logic_vector(35 downto 0);--input [`Voltage_range] // Supply Voltage
VDDQ  : in    std_logic_vector(35 downto 0);--input [`Voltage_range] // Input/Output Supply Voltage
VPP   : in    std_logic_vector(35 downto 0);--input [`Voltage_range] // Optional Supply Voltage for fast Program & Erase

pWAIT  : out   std_logic;  --// Wait
Info  : in    std_logic   --// Enable/Disable Information of the operation in the memory
);
end component;

signal VCC            : std_logic_vector(35 downto 0);
signal VCCQ           : std_logic_vector(35 downto 0);
signal VPP            : std_logic_vector(35 downto 0);

signal i_clk          : std_logic;
signal i_rst          : std_logic;

signal i_phy_rst      : std_logic;
signal pin_phy        : TPromPhyIN;
signal pout_phy       : TPromPhyOUT;
signal pinout_phy     : TPromPhyINOUT;

signal i_phy_di       : std_logic_vector(15 downto 0);
signal i_phy_do       : std_logic_vector(15 downto 0);
signal i_phy_oe_n     : std_logic;

signal i_tst_out      : std_logic_vector(31 downto 0);
signal i_core_status  : std_logic_vector(15 downto 0);
signal i_core_irq     : std_logic;

signal i_txbuf_rd     : std_logic;
signal i_txbuf_do     : std_logic_vector(31 downto 0);
signal i_txbuf_empty  : std_logic;
--signal i_txbuf_stop : std_logic;

signal i_divcnt : std_logic_vector(1 downto 0);
signal i_clk_en : std_logic;

--MAIN
begin


gen_clk_usr : process
begin
  i_clk<='0';
  wait for C_USRCLK_PERIOD/2;
  i_clk<='1';
  wait for C_USRCLK_PERIOD/2;
end process;

i_rst<='1','0' after 1 us;

process(i_rst,i_clk)
begin
  if i_rst = '1' then
    i_divcnt <= (others=>'0');
    i_clk_en <= '0';

  elsif rising_edge(i_clk) then
    i_divcnt <= i_divcnt + 1;

    --
    if i_divcnt = (i_divcnt'range => '1') then
    i_clk_en <= '1';
    else
    i_clk_en <= '0';
    end if;

  end if;
end process;

m_core : prog_flash
generic map(
G_USRBUF_DWIDTH => 32,
G_FLASH_AWIDTH => 24,
G_FLASH_DWIDTH => 16
)
port map(
p_out_txbuf_rd    => i_txbuf_rd,
p_in_txbuf_d      => i_txbuf_do,
p_in_txbuf_empty  => i_txbuf_empty,

p_out_rxbuf_d     => p_out_rxbuf_d ,--i_rxbuf_d,
p_out_rxbuf_wr    => p_out_rxbuf_wr,--i_rxbuf_wr,
p_in_rxbuf_full   => '0',

--
p_out_irq         => i_core_irq,
p_out_status      => i_core_status,

--PHY
p_out_phy_a       => pout_phy.a,
p_in_phy_d        => i_phy_di,
p_out_phy_d       => i_phy_do,
p_out_phy_oe      => i_phy_oe_n,
p_out_phy_we      => pout_phy.we_n,
p_out_phy_cs      => pout_phy.cs_n,
p_in_phy_wait     => pin_phy.wt,

--Технологический
p_in_tst          => (others=>'0'),

p_out_tst         => i_tst_out,

--System
p_in_clk_en       => i_clk_en,
p_in_clk          => i_clk,
p_in_rst          => i_rst
);

pout_phy.oe_n <= i_phy_oe_n;
pinout_phy.d <= i_phy_do when i_phy_oe_n = '1' else (others => 'Z');
i_phy_di <= pinout_phy.d;

i_phy_rst <= '0','1' after 1 us;

m_flash_dev : x28fxxxp30
port map (
A     => pout_phy.a,
DQ    => pinout_phy.d,

W_N   => pout_phy.we_n,
G_N   => pout_phy.oe_n,
E_N   => pout_phy.cs_n,
L_N   => '0',
K     => '0',
WP_N  => '1',
RP_N  => i_phy_rst,

VDD   => VCC ,--input [`Voltage_range] // Supply Voltage
VDDQ  => VCCQ,--input [`Voltage_range] // Input/Output Supply Voltage
VPP   => VPP ,--input [`Voltage_range] // Optional Supply Voltage for fast Program & Erase

pWAIT  => pin_phy.wt,
Info  => '1'   --// Enable/Disable Information of the operation in the memory
);

VCC  <= CONV_STD_LOGIC_VECTOR(1700, VCC'length);
VCCQ <= CONV_STD_LOGIC_VECTOR(1700, VCCQ'length);
VPP  <= CONV_STD_LOGIC_VECTOR(2000, VPP'length);



---------------------------------
--USR DATA WRITE
---------------------------------
process
variable i_txbuf_stop : std_logic;
begin
i_txbuf_stop := '0';
i_txbuf_do <= CONV_STD_LOGIC_VECTOR(0, i_txbuf_do'length);
i_txbuf_empty <= '1';

wait for 310 us;

--SET ADR START
i_txbuf_do(3 downto 0) <= CONV_STD_LOGIC_VECTOR(CI_USR_CMD_ADR, 4);
i_txbuf_do(31 downto 4) <= CONV_STD_LOGIC_VECTOR(16#00000#, 28);--адрес (byte)
wait until rising_edge(i_clk) and i_clk_en = '1';
i_txbuf_empty <= '0';
wait until rising_edge(i_clk) and i_clk_en = '1';
i_txbuf_empty <= '1';

wait until rising_edge(i_clk) and i_core_irq = '1';


--UNLOCK
i_txbuf_do(3 downto 0) <= CONV_STD_LOGIC_VECTOR(CI_USR_CMD_UNLOCK, 4);
i_txbuf_do(31 downto 4) <= CONV_STD_LOGIC_VECTOR((64*1024*2)*1 , 28);--size (byte) //(CI_FLASH_BLOCK_64KW*1 , 28);
wait until rising_edge(i_clk) and i_clk_en = '1';
i_txbuf_empty <= '0';
wait until rising_edge(i_clk) and i_clk_en = '1';
i_txbuf_empty <= '1';

wait until rising_edge(i_clk) and i_core_irq = '1';


--ERASE
i_txbuf_do(3 downto 0) <= CONV_STD_LOGIC_VECTOR(CI_USR_CMD_ERASE, 4);
i_txbuf_do(31 downto 4) <= CONV_STD_LOGIC_VECTOR((64*1024*2)*1 , 28);--size (byte) //(CI_FLASH_BLOCK_64KW*1 , 28);
wait until rising_edge(i_clk) and i_clk_en = '1';
i_txbuf_empty <= '0';
wait until rising_edge(i_clk) and i_clk_en = '1';
i_txbuf_empty <= '1';

wait until rising_edge(i_clk) and i_core_irq = '1';


--CMD WRITE DATA + DSIZE
i_txbuf_do(3 downto 0) <= CONV_STD_LOGIC_VECTOR(CI_USR_CMD_DWR, 4);
i_txbuf_do(31 downto 4) <= CONV_STD_LOGIC_VECTOR(96*2 , 28);--(CI_FLASH_BLOCK_64KW*1 , 28);--size (byte)
wait until rising_edge(i_clk) and i_clk_en = '1';
i_txbuf_empty <= '0';
--wait for 100 us;
wait until rising_edge(i_clk) and i_txbuf_rd='1';
i_txbuf_empty <= '1';
i_txbuf_do(15 downto  0) <= CONV_STD_LOGIC_VECTOR(1, 16);
i_txbuf_do(31 downto 16) <= CONV_STD_LOGIC_VECTOR(2, 16);

--WRITE DATA
wait until rising_edge(i_clk);
i_txbuf_empty <= '0';

while (i_txbuf_stop = '0') loop
  wait until (rising_edge(i_clk) and i_txbuf_rd='1') or (rising_edge(i_clk) and i_core_irq = '1');
  if i_core_irq = '1' then
    i_txbuf_empty <= '1';
    i_txbuf_stop := '1';
  else
    i_txbuf_do(15 downto  0) <= i_txbuf_do(15 downto  0) + 2;
    i_txbuf_do(31 downto 16) <= i_txbuf_do(31 downto 16) + 2;
  end if;
end loop;


wait;
end process;


-----------------------------------
----READ DATA CFI
-----------------------------------
--process
--begin
--
--i_txbuf_do <= CONV_STD_LOGIC_VECTOR(0, i_txbuf_do'length);
--i_txbuf_empty <= '1';
--
--wait for 310 us;
--
----SET ADR START
--i_txbuf_do(3 downto 0) <= CONV_STD_LOGIC_VECTOR(CI_USR_CMD_ADR, 4);
--i_txbuf_do(31 downto 4) <= CONV_STD_LOGIC_VECTOR(16#00011#, 28);
--wait until rising_edge(i_clk);
--i_txbuf_empty <= '0';
--wait until rising_edge(i_clk);
--i_txbuf_empty <= '1';
--
--wait until rising_edge(i_clk) and i_core_irq = '1';
--
--
----READ DATA SIZE
--i_txbuf_do(3 downto 0) <= CONV_STD_LOGIC_VECTOR(CI_USR_CMD_DRD_CFI, 4);
--i_txbuf_do(31 downto 4) <= CONV_STD_LOGIC_VECTOR(3 , 28);
--wait until rising_edge(i_clk);
--i_txbuf_empty <= '0';
--wait until rising_edge(i_clk);
--i_txbuf_empty <= '1';
--
--wait until rising_edge(i_clk) and i_core_irq = '1';
--
--
--wait;
--end process;



--process
--begin
--
--pinout_phy.d <= (others=>'Z');
--pout_phy.a <= (others=>'0');
--pout_phy.we_n <= '1';
--pout_phy.oe_n <= '1';
--pout_phy.cs_n <= '1';
--
--wait for 310 us;
--
--pout_phy.cs_n <= '0';
--pout_phy.a <= CONV_STD_LOGIC_VECTOR(16#00# + 16#00#, pout_phy.a'length);
--pinout_phy.d <= CONV_STD_LOGIC_VECTOR(16#60#, pinout_phy.d'length);
--
--wait for 1 us;
--pout_phy.we_n <= '0';
--
--wait for 1 us;
--pout_phy.we_n <= '1';
--
--wait for 1 us;
--pinout_phy.d <= (others=>'Z');
--
--wait for 1 us;
--pout_phy.we_n <= '1';
--
--wait for 1 us;
--pout_phy.a <= CONV_STD_LOGIC_VECTOR(16#00# + 16#00#, pout_phy.a'length);
--pinout_phy.d <= CONV_STD_LOGIC_VECTOR(16#D0#, pinout_phy.d'length);
----pinout_phy.d <= (others=>'Z');
--pout_phy.oe_n <= '1';
--pout_phy.we_n <= '0';
--
--wait for 1 us;
--pout_phy.oe_n <= '1';
--pout_phy.we_n <= '1';
--
--wait for 1 us;
--pout_phy.a <= CONV_STD_LOGIC_VECTOR(16#00# + 16#02#, pout_phy.a'length);
--pinout_phy.d <= CONV_STD_LOGIC_VECTOR(16#90#, pinout_phy.d'length);
----pinout_phy.d <= (others=>'Z');
--pout_phy.oe_n <= '1';
--pout_phy.we_n <= '0';
--
--wait for 1 us;
--pout_phy.oe_n <= '1';
--pout_phy.we_n <= '1';
--
--
--wait for 1 us;
--pout_phy.a <= CONV_STD_LOGIC_VECTOR(16#00# + 16#02#, pout_phy.a'length);
----pinout_phy.d <= CONV_STD_LOGIC_VECTOR(16#90#, pinout_phy.d'length);
--pinout_phy.d <= (others=>'Z');
--pout_phy.oe_n <= '0';
--pout_phy.we_n <= '1';
--
--wait for 1 us;
--pout_phy.oe_n <= '1';
--pout_phy.we_n <= '1';
--wait;
--end process;



--process
--begin
--
--pinout_phy.d <= (others=>'Z');
--pout_phy.a <= (others=>'0');
--pout_phy.we_n <= '1';
--pout_phy.oe_n <= '1';
--pout_phy.cs_n <= '1';
--
--wait for 310 us;
--
--pout_phy.cs_n <= '0';
--pout_phy.a <= CONV_STD_LOGIC_VECTOR(16#10# + 16#00#, pout_phy.a'length);
--pinout_phy.d <= CONV_STD_LOGIC_VECTOR(16#98#, pinout_phy.d'length);
--
--wait for 1 us;
--pout_phy.we_n <= '0';
--
--wait for 1 us;
--pout_phy.we_n <= '1';
--
--wait for 1 us;
--pinout_phy.d <= (others=>'Z');
--
--wait for 1 us;
--pout_phy.we_n <= '1';
--
--wait for 1 us;
--pout_phy.a <= CONV_STD_LOGIC_VECTOR(16#10# + 16#03#, pout_phy.a'length);
----pinout_phy.d <= CONV_STD_LOGIC_VECTOR(16#01#, pinout_phy.d'length);
--pinout_phy.d <= (others=>'Z');
--pout_phy.oe_n <= '0';
--pout_phy.we_n <= '1';
--
--wait for 1 us;
--pout_phy.oe_n <= '1';
--pout_phy.we_n <= '1';
--
----wait for 1 us;
----pout_phy.a <= CONV_STD_LOGIC_VECTOR(16#00# + 16#02#, pout_phy.a'length);
----pinout_phy.d <= CONV_STD_LOGIC_VECTOR(16#90#, pinout_phy.d'length);
------pinout_phy.d <= (others=>'Z');
----pout_phy.oe_n <= '1';
----pout_phy.we_n <= '0';
----
----wait for 1 us;
----pout_phy.oe_n <= '1';
----pout_phy.we_n <= '1';
----
----
----wait for 1 us;
----pout_phy.a <= CONV_STD_LOGIC_VECTOR(16#00# + 16#02#, pout_phy.a'length);
------pinout_phy.d <= CONV_STD_LOGIC_VECTOR(16#90#, pinout_phy.d'length);
----pinout_phy.d <= (others=>'Z');
----pout_phy.oe_n <= '0';
----pout_phy.we_n <= '1';
----
----wait for 1 us;
----pout_phy.oe_n <= '1';
----pout_phy.we_n <= '1';
--
--wait;
--end process;

--END MAIN
end behavioral;
