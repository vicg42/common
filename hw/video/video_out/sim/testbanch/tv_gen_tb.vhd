
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
    CONSTANT period_sys_clk       : TIME := 16.666 ns;--60MHz

  COMPONENT tv_gen
  PORT(
    p_in_rst : IN std_logic;
    p_in_clk : IN std_logic;
    p_in_clk_en : IN std_logic;
    p_out_tv_kci   : out std_logic;
    p_out_tv_ssi : OUT std_logic;
    p_out_tv_field : OUT std_logic;
    p_out_den : OUT std_logic
    );
  END COMPONENT;

  SIGNAL rst :  std_logic;
  SIGNAL clk :  std_logic;

  SIGNAL i_pixcnt : unsigned(9 downto 0) := (others => '0');
  signal i_tv_den : std_logic;


BEGIN

  uut: tv_gen PORT MAP(
    p_in_rst => rst,
    p_in_clk => clk,
    p_in_clk_en => '1',
    p_out_tv_ssi => p_out_tv_ssi,
    p_out_tv_kci => p_out_tv_kci,
    p_out_tv_field => p_out_tv_field,
    p_out_den => i_tv_den
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
  end if;
end process;

p_out_tst(0) <= i_pixcnt(8);
p_out_den <= i_tv_den;


END;
