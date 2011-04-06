-------------------------------------------------------------------------
-- Company     : Linkos
-- Engineer    : Golovachenko Victor
--
-- Create Date : 11/11/2009
-- Module Name : BMD_INTR_CTRL.v
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

library unisim;
use unisim.vcomponents.all;

--library work;
--use work.vicg_common_pkg.all;
--use work.prj_def.all;

entity BMD_INTR_CTRL_DEV is
generic(
G_TIME_DLY   : integer:=0
);
port
(
--//Пользовательское управление
p_in_init_rst                 : in   std_logic;--//Переход в исходное состояние
p_in_irq_set                  : in   std_logic;--//Установка прерывания
p_in_irq_clr                  : in   std_logic;--//Сброс прерывания
p_out_irq_status_act          : out  std_logic;--//Статус активности перывания

--//Связь с ядром PCI-EXPRESS
p_in_cfg_msi_enable           : in   std_logic;
p_out_cfg_interrupt_di        : out  std_logic_vector(7 downto 0);
p_in_cfg_interrupt_rdy_n      : in   std_logic;
p_out_cfg_interrupt_assert_n  : out  std_logic;
p_out_cfg_interrupt_n         : out  std_logic;

--//Технологические сигналы
p_out_tst                     : out std_logic_vector(4 downto 0);

--//SYSTEM
p_in_clk             : in   std_logic;
p_in_rst_n           : in   std_logic
);
end BMD_INTR_CTRL_DEV;

architecture behavioral of BMD_INTR_CTRL_DEV is

type fsm_state is
(
S_INTR_IDLE,
S_INTR_ACT0,
S_INTR_ACT1,
S_INTR_ACT2,
S_INTR_ACT3,
S_INTR_DONE
);
signal fsm_state_cs: fsm_state;

signal i_interrupt_status_act   : std_logic;

signal i_cfg_interrupt_assert   : std_logic;
signal i_cfg_interrupt          : std_logic;

signal i_timer_en               : std_logic;
signal i_timer_cnt              : std_logic_vector(6 downto 0);

--signal tst_fsm                  : std_logic_vector(2 downto 0);
--signal tst_irq_work             : std_logic;



--//MAIN
begin

--//Технологические сигналы
--tst_fsm<="000" when fsm_state_cs=S_INTR_IDLE else
--         "001" when fsm_state_cs=S_INTR_ACT1 else
--         "010" when fsm_state_cs=S_INTR_ACT2 else
--         "011" when fsm_state_cs=S_INTR_ACT3 else
--         "100" when fsm_state_cs=S_INTR_DONE else
--         "111";
--process(p_in_clk)
--begin
--  if p_in_clk'event and p_in_clk='1' then
--    p_out_tst(2 downto 0)<=tst_fsm;
--    p_out_tst(3)<=p_in_irq_set;
--    p_out_tst(4)<=p_in_irq_clr;
--  end if;
--end process;

p_out_tst(0)<='0';--tst_irq_work;
p_out_tst(4 downto 1)<=(others=>'0');



--//
process(p_in_rst_n,p_in_clk)
begin
  if p_in_rst_n='0' then
    i_timer_cnt<=(others=>'0');
  elsif p_in_clk'event and p_in_clk='1' then
      if i_timer_en='0'then
      i_timer_cnt<=(others=>'0');
    else
      i_timer_cnt<=i_timer_cnt+1;
    end if;
  end if;
end process;

--//Связь с ядром PCI-EXPRESS
p_out_cfg_interrupt_di       <= CONV_STD_LOGIC_VECTOR(16#00#, p_out_cfg_interrupt_di'length);
p_out_cfg_interrupt_assert_n <= not i_cfg_interrupt_assert when p_in_cfg_msi_enable='0' else '1';
p_out_cfg_interrupt_n        <= not i_cfg_interrupt;

--//Статус активности перывания
p_out_irq_status_act <= i_interrupt_status_act;

--//Логика управления ядром PCI-EXPRESS
process(p_in_rst_n,p_in_clk)
begin
  if p_in_rst_n='0' then

  i_timer_en<='0';
  i_interrupt_status_act <= '0';

  i_cfg_interrupt_assert <= '0';
  i_cfg_interrupt        <= '0';
  fsm_state_cs <= S_INTR_IDLE;

--  tst_irq_work<='0';

  elsif p_in_clk'event and p_in_clk='1' then
    if p_in_init_rst='1' then
      i_interrupt_status_act <= '0';

      i_cfg_interrupt_assert <= '0';
      i_cfg_interrupt        <= '0';
      fsm_state_cs <= S_INTR_IDLE;
    else
      case fsm_state_cs is
--
--        when S_INTR_IDLE =>
--
--          if p_in_irq_set='1' then
--            --//Активируем прерывание
--            i_cfg_interrupt_assert <= '1';--//Выстовляем разрешение прерывания
--            i_cfg_interrupt        <= '1';--//Выстовляем запроса на отправку флага cfg_interrupt_assert_n_o
--            fsm_state_cs <= S_INTR_ACT1;
--          else
--            i_cfg_interrupt_assert <= '0';
--            i_cfg_interrupt        <= '0';
--            fsm_state_cs <= S_INTR_IDLE;
--          end if;

        when S_INTR_IDLE =>

          if p_in_irq_set='1' then
            i_timer_en<='1';
--            tst_irq_work<='1';
            fsm_state_cs <= S_INTR_ACT0;
          end if;

        when S_INTR_ACT0 =>

          if i_timer_cnt=CONV_STD_LOGIC_VECTOR(G_TIME_DLY, i_timer_cnt'length) then
            i_timer_en<='0';
            --//Активируем прерывание
            i_cfg_interrupt_assert <= '1';--//Выстовляем разрешение прерывания
            i_cfg_interrupt        <= '1';--//Выстовляем запроса на отправку флага cfg_interrupt_assert_n_o
            fsm_state_cs <= S_INTR_ACT1;
          else
            i_cfg_interrupt_assert <= '0';
            i_cfg_interrupt        <= '0';
            fsm_state_cs <= S_INTR_ACT0;
          end if;

        when S_INTR_ACT1 =>

          --//Ждем подтверждения от CORE
          if p_in_cfg_interrupt_rdy_n='0' then
            --//Core отправляет перрывание.
            i_interrupt_status_act <= '1';

            i_cfg_interrupt_assert <= '1';--//Выстовляем разрешение прерывания
            i_cfg_interrupt        <= '0';--//Снимаем запроса на отправку флага cfg_interrupt_assert_n_o
            fsm_state_cs <= S_INTR_ACT2;
          end if;

        when S_INTR_ACT2 =>
          --//Гашение прерывания
          if p_in_irq_clr='1' then
            i_cfg_interrupt_assert <= '0';--//Выстовляем запрещение прерывания
            i_cfg_interrupt        <= '1';--//Выстовляем запроса на отправку флага cfg_interrupt_assert_n_o

            if p_in_cfg_msi_enable='0' then
              fsm_state_cs <= S_INTR_ACT3;
            else
              fsm_state_cs <= S_INTR_DONE;
            end if;
          end if;

        when S_INTR_ACT3 =>
          --//Ждем подтверждения от CORE
          if p_in_cfg_interrupt_rdy_n='0' then
            i_interrupt_status_act <= '0';

            i_cfg_interrupt_assert <= '0';
            i_cfg_interrupt        <= '0';
            fsm_state_cs <= S_INTR_DONE;
          end if;

        when S_INTR_DONE =>

--          tst_irq_work<='0';
          i_cfg_interrupt_assert <= '0';
          i_cfg_interrupt        <= '0';
          fsm_state_cs <= S_INTR_IDLE;

      end case;
    end if;
  end if;
end process;


--END MAIN
end behavioral;




