-------------------------------------------------------------------------
-- Company     : Linkos
-- Engineer    : Golovachenko Victor
--
-- Create Date : 25.11.2008 18:38
-- Module Name : sata_host_tb
--
-- Description :
--
-- Revision:
-- Revision 0.01 - File Created
--
-------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.ALL;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;
use ieee.std_logic_arith.all;

library unisim;
use unisim.vcomponents.all;

entity sata_crc_tb is
generic
(
G_TEST_FIS                : integer := 2
);
port
(
result1 : out std_logic_vector(31 downto 0);
result2 : out std_logic_vector(31 downto 0)
);
end sata_crc_tb;

architecture behavior of sata_crc_tb is

constant i_clk_period : TIME := 6.6 ns; --150MHz

component sata_crc
generic
(
G_INIT_VAL : integer := 16#52325032#
);
port
(
p_in_SOF               : in    std_logic;
--p_in_EOF               : in    std_logic;
p_in_en                : in    std_logic;
p_in_data              : in    std_logic_vector(31 downto 0);
p_out_crc              : out   std_logic_vector(31 downto 0);

--------------------------------------------------
--System
--------------------------------------------------
--p_in_clk_en            : in    std_logic;
p_in_clk               : in    std_logic;
p_in_rst               : in    std_logic
);
end component;

type TFis_array  is array (0 to 7) of std_logic_vector (31 downto 0);
constant tst_fis0 : TFis_array:=(
CONV_STD_LOGIC_VECTOR(16#00500034#, 32),
CONV_STD_LOGIC_VECTOR(16#00000001#, 32),
CONV_STD_LOGIC_VECTOR(16#00000000#, 32),
CONV_STD_LOGIC_VECTOR(16#00000001#, 32),
CONV_STD_LOGIC_VECTOR(16#00000000#, 32),
CONV_STD_LOGIC_VECTOR(16#DC052495#, 32),
CONV_STD_LOGIC_VECTOR(16#00000000#, 32),
CONV_STD_LOGIC_VECTOR(16#00000000#, 32)
);
constant tst_fis1 : TFis_array:=(
CONV_STD_LOGIC_VECTOR(16#00308027#, 32),
CONV_STD_LOGIC_VECTOR(16#E1234567#, 32),
CONV_STD_LOGIC_VECTOR(16#00000000#, 32),
CONV_STD_LOGIC_VECTOR(16#00000002#, 32),
CONV_STD_LOGIC_VECTOR(16#00000000#, 32),
CONV_STD_LOGIC_VECTOR(16#319FFF6F#, 32),
CONV_STD_LOGIC_VECTOR(16#00000000#, 32),
CONV_STD_LOGIC_VECTOR(16#00000000#, 32)
);
constant tst_fis2 : TFis_array:=(
CONV_STD_LOGIC_VECTOR(16#0058605F#, 32),
CONV_STD_LOGIC_VECTOR(16#4000006F#, 32),
CONV_STD_LOGIC_VECTOR(16#00000000#, 32),
CONV_STD_LOGIC_VECTOR(16#50000002#, 32),
CONV_STD_LOGIC_VECTOR(16#00000200#, 32),
CONV_STD_LOGIC_VECTOR(16#00000000#, 32),
CONV_STD_LOGIC_VECTOR(16#00000000#, 32),
CONV_STD_LOGIC_VECTOR(16#00000000#, 32)
);

type TTstfis_array  is array (0 to 2) of TFis_array;
constant tst_fis_array : TTstfis_array:=(
tst_fis0,
tst_fis1,
tst_fis2
);

signal i_clk                       : std_logic := '0';
signal i_rst                       : std_logic := '0';

signal i_en_print                  : std_logic := '0';

signal i_rxcrc_calc                : std_logic_vector(31 downto 0):=(others=>'0');
signal i_tst_data                  : std_logic_vector(31 downto 0):=(others=>'0');
signal i_tst_data_en               : std_logic := '0';

signal i_crc_calc                  : std_logic_vector(31 downto 0):=(others=>'0');
signal i_crc32_in_t1               : std_logic_vector(31 downto 0):=(others=>'0');
signal i_crc32_in                  : std_logic_vector(31 downto 0):=(others=>'0');
signal i_crc32_out                 : std_logic_vector(31 downto 0):=(others=>'0');
signal i_crc32_out_t1              : std_logic_vector(31 downto 0):=(others=>'0');
signal i_crc32_out_result          : std_logic_vector(31 downto 0):=(others=>'0');

signal i_din_in                    : std_logic_vector(31 downto 0):=(others=>'0');

signal mnl_rxcrc_in_en             : std_logic := '0';
signal mnl_rxcrc_in_en_d0          : std_logic := '0';
signal mnl_rxcrc_in_en_d1          : std_logic := '0';
signal mnl_rxcrc_in_en_d2          : std_logic := '0';

signal i_crc32_rst                 : std_logic;
signal i_crc32_en                  : std_logic;
signal i_crc32_rst_s                 : std_logic;
signal i_crc32_en_s                  : std_logic;
signal i_tst_data2                 : std_logic_vector(31 downto 0):=(others=>'0');


--Main
begin

m_xil : CRC32
generic map
(
CRC_INIT => x"52325032" --   x"26052625" ---- bit rotate ->
)
port map
(
CRCDATAWIDTH => "011",

CRCOUT       => i_crc32_out,
CRCIN        => i_crc32_in,
CRCDATAVALID => i_crc32_en,

CRCCLK       => i_clk,
CRCRESET     => i_crc32_rst
);

m_my : sata_crc
generic map
(
G_INIT_VAL             => 16#52325032#
)
port map
(
p_in_SOF               => '0',--i_crc_sof,
--  p_in_EOF               => '0',
p_in_en                => i_tst_data_en,
p_in_data              => i_tst_data,
p_out_crc              => i_rxcrc_calc,

--------------------------------------------------
--System
--------------------------------------------------
--  p_in_clk_en            => '1',
p_in_clk               => i_clk,
p_in_rst               => i_rst
);


clk_in_generator : process
begin
  i_clk<='0';
  wait for i_clk_period/2;
  i_clk<='1';
  wait for i_clk_period/2;
end process;

i_rst<='1','0' after 1 us;

--  mnl_rxcrc_in_en<='0','1' after 1.1 us, '0' after 1.11 us; -- разрешение для 1 данного
--  mnl_rxcrc_in_en<='0','1' after 1.1 us, '0' after 1.12 us; -- разрешение для 3 данных
mnl_rxcrc_in_en<='0','1' after 1.1 us, '0' after 1.14 us;

process(i_rst,i_clk)
variable i : integer:=0;
begin
  if i_rst='1' then
    mnl_rxcrc_in_en_d0<='0';
    mnl_rxcrc_in_en_d1<='0';
    mnl_rxcrc_in_en_d2<='0';

    i_tst_data_en<='0';
    i_tst_data<=(others=>'0');
    i_en_print<='0';

  elsif i_clk'event and i_clk='1' then
    mnl_rxcrc_in_en_d0<=mnl_rxcrc_in_en;
--      i_tst_data_en<=mnl_rxcrc_in_en_d0;
    mnl_rxcrc_in_en_d2<=i_tst_data_en;
--
--  i_crc32_rst_s<=i_crc32_rst;
--  i_crc32_en_s <=i_crc32_en;

    if mnl_rxcrc_in_en_d0='1' then
      if i<5 then
        i_en_print<='1';
        i_tst_data_en<='1';
        i_tst_data<=tst_fis_array(G_TEST_FIS)(i);
        i:=i+1;
      else
        i_en_print<='0';
        i_tst_data_en<='0';
        i_tst_data<=(others=>'0');
      end if;

    end if;
  end if;
end process;


process
begin

i_crc32_rst<='0';
i_crc32_en <='0';
i_tst_data2<=CONV_STD_LOGIC_VECTOR(16#00000000#, 32);

wait for 1 us;

wait until i_clk'event and i_clk='1';
i_crc32_rst<='1';
i_crc32_en <='1';
i_tst_data2<=CONV_STD_LOGIC_VECTOR(16#0058605F#, 32);

wait until i_clk'event and i_clk='1';
i_crc32_rst<='0';
i_crc32_en <='1';
i_tst_data2<=CONV_STD_LOGIC_VECTOR(16#4000006F#, 32);

wait until i_clk'event and i_clk='1';
i_crc32_rst<='0';
i_crc32_en <='1';
i_tst_data2<=CONV_STD_LOGIC_VECTOR(16#00000000#, 32);

wait until i_clk'event and i_clk='1';
i_crc32_rst<='0';
i_crc32_en <='0';
i_tst_data2<=CONV_STD_LOGIC_VECTOR(16#50000002#, 32);

wait;
end process;



--i_crc32_in(8*1-1 downto 8*0)<=i_tst_data2(8*1-1 downto 8*0);
--i_crc32_in(8*2-1 downto 8*1)<=i_tst_data2(8*2-1 downto 8*1);
--i_crc32_in(8*3-1 downto 8*2)<=i_tst_data2(8*3-1 downto 8*2);
--i_crc32_in(8*4-1 downto 8*3)<=i_tst_data2(8*4-1 downto 8*3);

gen_1: for i in 0 to 7 generate
  i_crc32_in_t1((8*1-1)-i)<=i_tst_data2(8*0+i);
  i_crc32_in_t1((8*2-1)-i)<=i_tst_data2(8*1+i);
  i_crc32_in_t1((8*3-1)-i)<=i_tst_data2(8*2+i);
  i_crc32_in_t1((8*4-1)-i)<=i_tst_data2(8*3+i);
end generate;

gen_2: for i in 0 to 31 generate
  i_crc32_in(i)<=not i_crc32_in_t1(i);
end generate;


process(i_clk)
begin
  if i_clk'event and i_clk='1' then
--    for i in 0 to 31 loop
--    i_crc32_out_t1(i)<=not i_crc32_out(i);
--    end loop;

    for i in 0 to 7 loop
    i_crc32_out_t1((8*1-1)-i)<=i_crc32_out(8*0+i);
    i_crc32_out_t1((8*2-1)-i)<=i_crc32_out(8*1+i);
    i_crc32_out_t1((8*3-1)-i)<=i_crc32_out(8*2+i);
    i_crc32_out_t1((8*4-1)-i)<=i_crc32_out(8*3+i);
    end loop;
  end if;
end process;

process(i_clk)
begin
  if i_clk'event and i_clk='1' then
--    for i in 0 to 7 loop
--    i_crc32_out_result((8*1-1)-i)<=i_crc32_out_t1(8*0+i);
--    i_crc32_out_result((8*2-1)-i)<=i_crc32_out_t1(8*1+i);
--    i_crc32_out_result((8*3-1)-i)<=i_crc32_out_t1(8*2+i);
--    i_crc32_out_result((8*4-1)-i)<=i_crc32_out_t1(8*3+i);
--    end loop;

    for i in 0 to 31 loop
    i_crc32_out_result(i)<=not i_crc32_out_t1(i);
    end loop;
  end if;
end process;



result1<=i_rxcrc_calc;--
result2<=i_crc32_out_result;

--End Main
end;
