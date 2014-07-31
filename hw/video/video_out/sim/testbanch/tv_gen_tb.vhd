
-- VHDL Test Bench Created from source file tv_gen.vhd -- 16:53:43 02/15/2005
--
-- Notes:
-- This testbench has been automatically generated using types std_logic and
-- std_logic_vector for the ports of the unit under test.  Xilinx recommends
-- that these types always be used for the top-level I/O of a design in order
-- to guarantee that the testbench will bind correctly to the post-implementation
-- simulation model.
--
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY tv_gen_tb IS
port(
p_out_tv_kci   : out std_logic;
p_out_tv_ssi : OUT std_logic;
p_out_tv_field : OUT std_logic;
p_out_den : OUT std_logic;
p_out_tst : out std_logic_vector(31 downto 0)
);
END tv_gen_tb;

ARCHITECTURE behavior OF tv_gen_tb IS

--  Определяем частоты генераторов на плате:
    CONSTANT period_sys_clk       : TIME := 56.388 ns;--17,733990147783251231527093596059 MHz

component tv_gen is
generic(
N_ROW  : integer:=625;--Кол-во строк в кадре. (312.5 строк в одном поле)
N_H2   : integer:=400;--т.е. 64us/2=32us (удвоеная частота строк)
W2_32us: integer:=29 ;--т.е. 2.32 us
W4_7us : integer:=59 ;--т.е. 4.7 us
W1_53us: integer:=19 ;--т.е. 1.53 us
W5_8us : integer:=73 ;--т.е. 5.8 us
var1   : integer:=4  ;--продстройка
var2   : integer:=5   --продстройка
);
port(
p_out_tv_kci   : out std_logic;
p_out_tv_ssi   : out std_logic;--Синхросмесь. Стандартный TV сигнал
p_out_tv_field : out std_logic;--Поле TV сигнала (Четные/Нечетные строки)
p_out_den      : out std_logic;--Активная часть строки.(Разрешение вывода пиксел)

p_in_clk_en: in std_logic;
p_in_clk   : in std_logic;
p_in_rst   : in std_logic
);
end component;

signal rst :  std_logic;
signal clk :  std_logic;

signal i_pixcnt : unsigned(9 downto 0) := (others => '0');
signal i_tv_den : std_logic;
signal sr_tv_den: std_logic_vector(0 to 1) := (others => '0');
signal i_kci    : std_logic := '0';
signal i_tv_field: std_logic := '0';
signal i_rowcnt : unsigned(9 downto 0) := (others => '0');

BEGIN

uut: tv_gen
generic map(
--Все значения относительно p_in_clk=17,734472MHz (Активных строк/пиксел - 574/xxx)
N_ROW   => 625, --Кол-во строк в кадре. (312.5 строк в одном поле)
N_H2    => 567, --т.е. 64us/2=32us (удвоеная частота строк)
W2_32us => 41 , --т.е. 2.32 us
W4_7us  => 83 , --т.е. 4.7 us
W1_53us => 27 , --т.е. 1.53 us
W5_8us  => 102, --т.е. 5.8 us
var1    => 13  , --продстройка
var2    => 14    --продстройка
)
port map(
p_out_tv_kci   => i_kci,
p_out_tv_ssi   => p_out_tv_ssi,
p_out_tv_field => i_tv_field,
p_out_den      => i_tv_den,

p_in_clk_en => '1',
p_in_clk => clk,
p_in_rst => rst
);


-- *** Test Bench - User Defined Section ***
  rst<='1', '0'after 500 ns;
  Board_clk : PROCESS
  BEGIN
    clk<='0';
    wait for period_sys_clk/2;
    clk<='1';
    wait for period_sys_clk/2;
  END PROCESS;
-- *** End Test Bench - User Defined Section ***

process(clk)
begin
  if rising_edge(clk) then
    if i_tv_den = '1' then
      i_pixcnt <= i_pixcnt + 1;
    else
      i_pixcnt <= (OTHERS => '0');
    end if;

    sr_tv_den <= i_tv_den & sr_tv_den(0 to 0);
    if i_kci = '1' and i_tv_field = '1' then
      i_rowcnt <= (OTHERS => '0');
    elsif sr_tv_den(0) = '1' and sr_tv_den(1) = '0' then
      i_rowcnt <= i_rowcnt + 1;
    end if;
  end if;
end process;

p_out_tst(0) <= i_pixcnt(8) or i_rowcnt(8);
p_out_den <= i_tv_den;
p_out_tv_kci <= i_kci;
p_out_tv_field <= i_tv_field;

END;
