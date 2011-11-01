-------------------------------------------------------------------------
-- Company     : Linkos
-- Engineer    : Golovachenko Victor
--
-- Create Date : 28.10.2011 9:48:57
-- Module Name : BMD_INTR_CTRL_DEV
--
-- Description : Endpoint Intrrupt Controller
--               Подробно работа с перываниями CORE PCIEXPRESS описана в
--               pcie_blk_plus_ug341.pdf/п. Generating Interrupt Requests
--
-- Revision:
-- Revision 0.01 - File Created
--
-------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity BMD_INTR_CTRL_DEV is
generic(
G_TIME_DLY : integer:=0
);
port(
-----------------------------
--Usr Ctrl
-----------------------------
p_in_irq_set           : in   std_logic;--//Установка прерывания
p_in_irq_clr           : in   std_logic;--//Сброс прерывания
p_out_irq_status       : out  std_logic;--//1/0 - перрывание активно/не активно

-----------------------------
--Связь с ядром PCI-EXPRESS
-----------------------------
p_in_cfg_msi           : in   std_logic;--//1/0 - Interrupt mode MSI/Legacy
p_in_cfg_irq_rdy_n     : in   std_logic;
p_out_cfg_irq_n        : out  std_logic;
p_out_cfg_irq_assert_n : out  std_logic;
p_out_cfg_irq_di       : out  std_logic_vector(7 downto 0);

-----------------------------
--Технологические сигналы
-----------------------------
p_in_tst               : in  std_logic_vector(31 downto 0);
p_out_tst              : out std_logic_vector(31 downto 0);

-----------------------------
--SYSTEM
-----------------------------
p_in_clk               : in   std_logic;
p_in_rst               : in   std_logic
);
end BMD_INTR_CTRL_DEV;

architecture behavioral of BMD_INTR_CTRL_DEV is

type fsm_state is
(
S_IRQ_IDLE,
S_IRQ_ASSERT_DONE,
S_IRQ_WAIT_CLR,
S_IRQ_DEASSERT_DONE
--S_IRQ_DLY
);
signal fsm_cs: fsm_state;

signal i_irq_status             : std_logic:='0';
signal i_irq_assert_n           : std_logic:='1';
signal i_irq_n                  : std_logic:='1';

--signal i_timer_en               : std_logic:='0';
--signal i_timer_cnt              : std_logic_vector(6 downto 0):=(others=>'0');


--//MAIN
begin


p_out_tst<=(others=>'0');

--//Связь с ядром PCI-EXPRESS
p_out_cfg_irq_di       <= CONV_STD_LOGIC_VECTOR(16#00#, p_out_cfg_irq_di'length);
p_out_cfg_irq_assert_n <= i_irq_assert_n;
p_out_cfg_irq_n        <= i_irq_n;

--//Статус активности перывания
p_out_irq_status <= i_irq_status;

--//Логика управления ядром PCI-EXPRESS
process(p_in_rst,p_in_clk)
begin
  if p_in_rst='1' then

--    i_timer_en<='0';
    i_irq_status <= '0';

    i_irq_assert_n <= '1';
    i_irq_n        <= '1';
    fsm_cs <= S_IRQ_IDLE;

  elsif p_in_clk'event and p_in_clk='1' then

    case fsm_cs is

      --//--------------------------------
      --//
      --//--------------------------------
      when S_IRQ_IDLE =>

        if p_in_irq_set='1' then
          i_irq_n        <= '0';
          i_irq_assert_n <= '0';--ASSERT IRQ
          fsm_cs <= S_IRQ_ASSERT_DONE;
        else
          i_irq_assert_n <= '1';
          i_irq_n        <= '1';
        end if;

--      --//--------------------------------
--      --//
--      --//--------------------------------
--      when S_IRQ_IDLE =>
--
--        i_irq_n        <= '1';
--        i_irq_assert_n <= '1';
--
--        if p_in_irq_set='1' then
--          i_timer_en<='1';
--          fsm_cs <= S_IRQ_DLY;
--        end if;
--
--      --//--------------------------------
--      --//
--      --//--------------------------------
--      when S_IRQ_DLY =>
--
--        if i_timer_cnt=CONV_STD_LOGIC_VECTOR(G_TIME_DLY, i_timer_cnt'length) then
--          i_timer_en<='0';
--          --//Активируем прерывание
--          i_irq_n        <= '0';
--          i_irq_assert_n <= '0';--ASSERT IRQ
--          fsm_cs <= S_IRQ_ASSERT_DONE;
--        end if;

      --//--------------------------------
      --//
      --//--------------------------------
      when S_IRQ_ASSERT_DONE =>

        --//Ждем подтверждения от CORE
        if p_in_cfg_irq_rdy_n='0' then
          i_irq_status   <= '1';
          i_irq_n        <= '1';
          i_irq_assert_n <= '1';
          fsm_cs <= S_IRQ_WAIT_CLR;
        end if;

      --//--------------------------------
      --//
      --//--------------------------------
      when S_IRQ_WAIT_CLR =>

        if p_in_irq_clr='1' then
          if p_in_cfg_msi='1' then
          --//Interrupt mode MSI
            i_irq_status   <= '0';
            i_irq_n        <= '1';
            i_irq_assert_n <= '1';
            fsm_cs <= S_IRQ_IDLE;
          else
          --//Interrupt mode Legacy
            i_irq_n        <= '0';
            i_irq_assert_n <= '1';
            fsm_cs <= S_IRQ_DEASSERT_DONE;
          end if;
        end if;

      --//--------------------------------
      --//
      --//--------------------------------
      when S_IRQ_DEASSERT_DONE =>

        if p_in_cfg_irq_rdy_n='0' then
          i_irq_status   <= '0';
          i_irq_assert_n <= '1';
          i_irq_n        <= '1';
          fsm_cs <= S_IRQ_IDLE;
        end if;

    end case;
  end if;
end process;

----//
--process(p_in_rst,p_in_clk)
--begin
--  if p_in_rst='1' then
--    i_timer_cnt<=(others=>'0');
--  elsif p_in_clk'event and p_in_clk='1' then
--    if i_timer_en='0'then
--      i_timer_cnt<=(others=>'0');
--    else
--      i_timer_cnt<=i_timer_cnt+1;
--    end if;
--  end if;
--end process;

--END MAIN
end behavioral;




