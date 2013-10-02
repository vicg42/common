-------------------------------------------------------------------------
-- Company     : Linkos
-- Engineer    : Golovachenko Victor
--
-- Create Date : 10/26/2007
-- Module Name : timer_v01
--
-- Назначение/Описание :
--  Отработка заданого кол-ва отсчетов (порт:p_in_tmr_count)
--  c дискретом времени задоваемым с порта (p_in_time_discret).
--  p_in_time_discret= 0 - 1us;
--  p_in_time_discret= 1 - 1ms;
--  p_in_time_discret= 2 - 1sec;
--  p_in_time_discret= 3 - 1min;
--
--  Запуск таймера происходи по внешнему синхроимпульсу. порт p_in_start
--  Ширина умпульса должна состовлять 1 период тактовой частоты (порт p_in_clk)
--
-- Revision:
-- Revision 0.01 - File Created
--
-------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity timer_v01 is
generic
(
G_T05us : integer:=10#1000# -- кол-во периодов частоты порта p_in_clk
                            -- укладывающихся в 1/2 периода 1us
);
port
(
p_in_start        : in std_logic;                    --//Внешний запуск таймера

p_in_time_discret : in std_logic_vector(1 downto 0); --//Выбора дискрета времини для таймера (соответствие кода к времени см. выше)
p_in_tmr_count    : in std_logic_vector(15 downto 0);--//Кол-во отсчетов таймера с выбраным дискретом

p_out_work        : out std_logic;                   --//модуль находится в работе
p_out_done        : out std_logic;                   --//Работа модуля завершена

-------------------------------
--System
-------------------------------
p_in_clk     : in    std_logic;
p_in_rst     : in    std_logic
);
end timer_v01;

architecture behavioral of timer_v01 is

component time_gen
generic
(
G_T05us      : integer:=10#1000#
);
port
(
p_out_en05us : out   std_logic;
p_out_en1us  : out   std_logic;
p_out_en1ms  : out   std_logic;
p_out_en1sec : out   std_logic;
p_out_en1min : out   std_logic;

-------------------------------
--System
-------------------------------
p_in_rst     : in    std_logic;
p_in_clk     : in    std_logic
);
end component;

signal i_done                   : std_logic;

signal i_discret_1us            : std_logic;
signal i_discret_1ms            : std_logic;
signal i_discret_1sec           : std_logic;
signal i_discret_1min           : std_logic;

signal i_tmr_cnt                : std_logic_vector(15 downto 0);
signal i_tmr_en                 : std_logic;
signal i_tmr_work               : std_logic;
signal i_tmr_work_inv           : std_logic;

--MAIN
begin


p_out_work<=i_tmr_work;
p_out_done<=i_done;

process(p_in_rst,p_in_clk)
begin
  if p_in_rst='1' then
    i_tmr_work<='0';
    i_tmr_cnt<=(others=>'0');
    i_done<='0';
  elsif p_in_clk'event and p_in_clk='1' then
    --Запуск таймера
    if p_in_start='1' then
      i_tmr_work<='1';
    elsif i_tmr_en='1' and p_in_tmr_count=i_tmr_cnt then
      i_tmr_work<='0';
      i_done<='1';
    else
      i_done<='0';
    end if;

  end if;
end process;

i_tmr_work_inv<=not i_tmr_work;

m_time_gen_i : time_gen
generic map
(
G_T05us  => G_T05us
)
port map
(
p_out_en05us => open,
p_out_en1us  => i_discret_1us,
p_out_en1ms  => i_discret_1ms,
p_out_en1sec => i_discret_1sec,
p_out_en1min => i_discret_1min,

-------------------------------
--System
-------------------------------
p_in_p_in_rst     => i_tmr_work_inv,
p_in_p_in_clk     => p_in_clk
);

--Выбор дискрета времни для таймера
process(
i_discret_1us,
i_discret_1ms,
i_discret_1sec,
i_discret_1min,
i_tmr_en
)
begin
  case CONV_INTEGER(p_in_time_discret) is
    when 16#00# => i_tmr_en<=i_discret_1us;
    when 16#01# => i_tmr_en<=i_discret_1ms;
    when 16#02# => i_tmr_en<=i_discret_1sec;
    when 16#03# => i_tmr_en<=i_discret_1min;
    when others=>NULL;
  end case;
end process;

--Timer
process(p_in_rst,p_in_clk)
begin
  if p_in_rst='1' then
    i_tmr_cnt<=(others=>'0');
  elsif p_in_clk'event and p_in_clk='1' then
    if i_tmr_work='0' then
      i_tmr_cnt<=(others=>'0');
    elsif i_tmr_en='1' then
      i_tmr_cnt<=i_tmr_cnt + 1;
    end if;
  end if;
end process;

--END MAIN
end behavioral;
