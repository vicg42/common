-------------------------------------------------------------------------
-- Engineer    : Golovachenko Victor
--
-- Create Date : 27.07.2015 16:11:21
-- Module Name : pcie_irq.vhd
--
-- Description : Endpoint Intrrupt Controller
--
-------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.reduce_pack.all;
use work.prj_def.all;

entity pcie_irq is
port(
-----------------------------
--Usr Ctrl
-----------------------------
p_in_irq_clr  : in   std_logic;
p_in_irq_set  : in   std_logic;
p_out_irq_ack : out  std_logic;

-----------------------------
--PCIE Port
-----------------------------
p_in_cfg_msi_fail : in   std_logic;
p_in_cfg_msi      : in   std_logic;
p_in_cfg_irq_rdy  : in   std_logic;
p_out_cfg_irq_pad : out  std_logic;
p_out_cfg_irq_int : out  std_logic;
p_out_cfg_irq_err : out  std_logic;

-----------------------------
--SYSTEM
-----------------------------
p_in_clk   : in   std_logic;
p_in_rst_n : in   std_logic
);
end entity pcie_irq;

architecture behavioral of pcie_irq is

type fsm_state is (
S_IRQ_IDLE,
S_IRQ_ASSERT_DONE,
S_IRQ_WAIT_CLR,
S_IRQ_DEASSERT_DONE,
S_IRQ_ERR
);
signal fsm_cs: fsm_state;

signal i_irq_int     : std_logic;
signal i_irq_pad     : std_logic;
signal i_irq_ack     : std_logic;
signal i_irq_err     : std_logic;

begin --architecture behavioral

p_out_irq_ack <= i_irq_ack;

p_out_cfg_irq_int <= i_irq_int;
p_out_cfg_irq_pad <= i_irq_pad;
p_out_cfg_irq_err <= i_irq_err;


process(p_in_clk)
begin
if rising_edge(p_in_clk) then
  if (p_in_rst_n = '0') then

    i_irq_ack <= '0';
    i_irq_int <= '0';
    i_irq_pad <= '0';
    fsm_cs <= S_IRQ_IDLE;

  else

    case fsm_cs is

      ----------------------------------
      --
      ----------------------------------
      when S_IRQ_IDLE =>

        if (p_in_irq_set = '1') then
          i_irq_pad <= '1';
          i_irq_int <= '1';--ASSERT IRQ
          fsm_cs <= S_IRQ_ASSERT_DONE;
        end if;

      ----------------------------------
      --
      ----------------------------------
      when S_IRQ_ASSERT_DONE =>

        --Wait acknowledge from CORE
        if (p_in_cfg_msi = '1' and p_in_cfg_msi_fail = '1') then

          i_irq_err <= '1';
          i_irq_int <= '0';
          i_irq_pad <= '0';
          fsm_cs <= S_IRQ_ERR;

        elsif (p_in_cfg_irq_rdy = '1') then

          i_irq_ack <= '1';

          if (p_in_cfg_msi = '1') then
            i_irq_int <= '0';
          end if;

          fsm_cs <= S_IRQ_WAIT_CLR;
        end if;

      ----------------------------------
      --
      ----------------------------------
      when S_IRQ_WAIT_CLR =>

        i_irq_ack <= '0';

        if (p_in_irq_clr = '1') then
          --Interrupt mode Legacy
          if (p_in_cfg_msi = '0') then
            i_irq_int <= '0';--DEASSERT IRQ
            fsm_cs <= S_IRQ_DEASSERT_DONE;
          else
            i_irq_pad <= '0';
            fsm_cs <= S_IRQ_IDLE;
          end if;
        end if;

      ----------------------------------
      --
      ----------------------------------
      when S_IRQ_DEASSERT_DONE =>

        --Wait acknowledge from CORE
        if (p_in_cfg_irq_rdy = '1') then
          i_irq_int <= '0';
          i_irq_pad <= '0';
          fsm_cs <= S_IRQ_IDLE;
        end if;

      ----------------------------------
      --
      ----------------------------------
      when S_IRQ_ERR =>

        i_irq_err <= '1';

    end case;
  end if;
end if;
end process;


--###############################
--DBG
--###############################
--p_out_tst <= (others => '0');

end architecture behavioral;

