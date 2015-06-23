-------------------------------------------------------------------------
-- Engineer    : Golovachenko Victor
--
-- Create Date : 28.10.2011 9:48:57
-- Module Name : pcie_irq_dev
--
-- Description : Endpoint Intrrupt Controller
--               pcie_blk_plus_ug341.pdf/topic Generating Interrupt Requests
--
-------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity pcie_irq_dev is
generic(
G_TIME_DLY : integer:=0
);
port(
-----------------------------
--Usr Ctrl
-----------------------------
p_in_irq_set           : in   std_logic;
p_in_irq_clr           : in   std_logic;
p_out_irq_status       : out  std_logic;--1/0 - IRQ work/no

-----------------------------
--PCIE Port
-----------------------------
p_in_cfg_msi           : in   std_logic;--1/0 - Interrupt mode MSI/Legacy
p_in_cfg_irq_rdy_n     : in   std_logic;
p_out_cfg_irq_n        : out  std_logic;
p_out_cfg_irq_assert_n : out  std_logic;
p_out_cfg_irq_di       : out  std_logic_vector(7 downto 0);

-----------------------------
--DBG
-----------------------------
p_in_tst               : in  std_logic_vector(31 downto 0);
p_out_tst              : out std_logic_vector(31 downto 0);

-----------------------------
--SYSTEM
-----------------------------
p_in_clk               : in   std_logic;
p_in_rst_n             : in   std_logic
);
end entity pcie_irq_dev;

architecture behavioral of pcie_irq_dev is

type fsm_state is (
S_IRQ_IDLE,
S_IRQ_ASSERT_DONE,
S_IRQ_WAIT_CLR,
S_IRQ_DEASSERT_DONE
);
signal fsm_cs: fsm_state;

signal i_irq_status    : std_logic := '0';
signal i_irq_assert_n  : std_logic := '1';
signal i_irq_n         : std_logic := '1';


begin --architecture behavioral


p_out_tst <= (others => '0');


p_out_cfg_irq_di       <= std_logic_vector(TO_UNSIGNED(16#00#, p_out_cfg_irq_di'length));
p_out_cfg_irq_assert_n <= i_irq_assert_n;
p_out_cfg_irq_n        <= i_irq_n;

p_out_irq_status <= i_irq_status;

process(p_in_clk)
begin
if rising_edge(p_in_clk) then
  if p_in_rst_n = '0' then

    i_irq_status <= '0';

    i_irq_assert_n <= '1';
    i_irq_n        <= '1';
    fsm_cs <= S_IRQ_IDLE;

  else

    case fsm_cs is

      ----------------------------------
      --
      ----------------------------------
      when S_IRQ_IDLE =>

        if p_in_irq_set='1' then
          i_irq_n        <= '0';
          i_irq_assert_n <= '0';--ASSERT IRQ
          fsm_cs <= S_IRQ_ASSERT_DONE;
        else
          i_irq_assert_n <= '1';
          i_irq_n        <= '1';
        end if;

      ----------------------------------
      --
      ----------------------------------
      when S_IRQ_ASSERT_DONE =>

        --Wait acknowledge from CORE
        if p_in_cfg_irq_rdy_n = '0' then
          i_irq_status   <= '1';
          i_irq_n        <= '1';
--          i_irq_assert_n <= '1';
          fsm_cs <= S_IRQ_WAIT_CLR;
        end if;

      ----------------------------------
      --
      ----------------------------------
      when S_IRQ_WAIT_CLR =>

        if p_in_irq_clr='1' then
          if p_in_cfg_msi='1' then
          --Interrupt mode MSI
            i_irq_status   <= '0';
            i_irq_n        <= '1';
            i_irq_assert_n <= '1';
            fsm_cs <= S_IRQ_IDLE;
          else
          --Interrupt mode Legacy
            i_irq_n        <= '0';
            i_irq_assert_n <= '1';
            fsm_cs <= S_IRQ_DEASSERT_DONE;
          end if;
        end if;

      ----------------------------------
      --
      ----------------------------------
      when S_IRQ_DEASSERT_DONE =>

        if p_in_cfg_irq_rdy_n = '0' then
          i_irq_status   <= '0';
          i_irq_assert_n <= '1';
          i_irq_n        <= '1';
          fsm_cs <= S_IRQ_IDLE;
        end if;

    end case;
  end if;
end if;--p_in_rst_n,
end process;


end architecture behavioral;
