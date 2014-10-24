-------------------------------------------------------------------------
-- Company     : Linkos
-- Engineer    : Golovachenko Victor
--
-- Create Date : 25.11.2008 18:38
-- Module Name : vscaler_main_tb
--
-- Назначение/Описание :
--    Проверка работы
--
-- Revision:
-- Revision 0.01 - File Created
--
-------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.vicg_common_pkg.all;

library std;
use std.textio.all;

entity bayer_main_tb is
generic(
G_VFR_PIX_COUNT : integer := 9;
G_VFR_LINE_COUNT : integer := 6
);
port(
p_out_do      : out std_logic_vector(7 downto 0);
p_out_do_wr   : out std_logic;
p_out_do_eof  : out std_logic;

p_out_tst     : out std_logic_vector(31 downto 0)
);
end bayer_main_tb;

architecture testbanch of bayer_main_tb is

constant i_clk_period : TIME := 6.6 ns; --150MHz

component bayer_main
generic(
G_SIM : string:="OFF"
);
port(
-------------------------------
-- Управление
-------------------------------
p_in_cfg_bypass    : in    std_logic;                    --0/1 - Upstream Port -> Downstream Port Обрабатывать/Не обрабатывать
p_in_cfg_colorfst  : in    std_logic_vector(1 downto 0); --Первый пиксель 0/1/2 - R/G/B
p_in_cfg_pix_count : in    std_logic_vector(15 downto 0);--Кол-во пиксел/4 т.к p_in_upp_data=32bit
p_in_cfg_row_count : in    std_logic_vector(15 downto 0);--Кол-во строк
p_in_cfg_init      : in    std_logic;                    --Инициализация. Сброс счетчика адреса BRAM

----------------------------
--Upstream Port (входные данные)
----------------------------
p_in_upp_data      : in    std_logic_vector(7 downto 0);
p_in_upp_wr        : in    std_logic;
p_in_upp_eof       : in    std_logic;
p_out_upp_rdy_n    : out   std_logic;

----------------------------
--Downstream Port (результат)
----------------------------
p_out_dwnp_data    : out   std_logic_vector(7 downto 0);
p_out_dwnp_wr      : out   std_logic;
p_out_dwnp_eof     : out   std_logic;
p_in_dwnp_rdy_n    : in    std_logic;

-------------------------------
--Технологический
-------------------------------
p_in_tst           : in    std_logic_vector(31 downto 0);
p_out_tst          : out   std_logic_vector(31 downto 0);

-------------------------------
--System
-------------------------------
p_in_clk           : in    std_logic;
p_in_rst           : in    std_logic
);
end component bayer_main;


signal i_clk                : std_logic := '0';
signal i_rst                : std_logic := '0';

signal i_vfr_start          : std_logic := '0';
signal i_vfr_busy           : std_logic := '0';
signal i_cntpix             : unsigned(7 downto 0) := (others => '0');
signal i_cntline            : unsigned(7 downto 0) := (others => '0');

signal i_di                 : unsigned(7 downto 0) := (others => '0');
signal i_di_wr              : std_logic := '0';
signal i_di_eof             : std_logic := '0';
signal i_di_rdy_n           : std_logic;

signal i_do_rdy_n           : std_logic;

signal sr_di                : unsigned(i_di'range) := (others => '0');
signal sr_di_wr             : std_logic := '0';


begin --architecture testbanch

i_rst<='1','0' after 1 us;

clkgen : process
begin
  i_clk<='0';
  wait for i_clk_period/2;
  i_clk<='1';
  wait for i_clk_period/2;
end process clkgen;


m_bayer: bayer_main
generic map(
G_SIM => "ON"
)
port map(
-------------------------------
-- Управление
-------------------------------
p_in_cfg_bypass    => '0',
p_in_cfg_colorfst  => "00",
p_in_cfg_pix_count => std_logic_vector(TO_UNSIGNED(G_VFR_PIX_COUNT ,16)),
p_in_cfg_row_count => std_logic_vector(TO_UNSIGNED(G_VFR_LINE_COUNT ,16)),
p_in_cfg_init      => '0',

----------------------------
--Upstream Port
----------------------------
p_in_upp_data      => std_logic_vector(i_di),
p_in_upp_wr        => i_di_wr,
p_in_upp_eof       => i_di_eof,
p_out_upp_rdy_n    => i_di_rdy_n,

----------------------------
--Downstream Port
----------------------------
p_out_dwnp_data    => p_out_do,
p_out_dwnp_wr      => p_out_do_wr,
p_out_dwnp_eof     => p_out_do_eof,
p_in_dwnp_rdy_n    => i_do_rdy_n,

-------------------------------
--Технологический
-------------------------------
p_in_tst           => (others => '0'),
p_out_tst          => p_out_tst,

-------------------------------
--System
-------------------------------
p_in_clk           => i_clk,
p_in_rst           => i_rst
);



process(i_rst, i_clk)
variable di_eof : std_logic;
begin
  if i_rst = '1' then
    i_vfr_busy <= '0';

    i_cntpix <= (others => '0');
    i_cntline <= (others => '0');

    i_di <= TO_UNSIGNED(2 ,i_di'length);
    i_di_wr <= '0';
    i_di_eof <= '0';
    i_di_eof <= '0';

    sr_di    <= (others => '0');
    sr_di_wr <= '0';

  elsif rising_edge(i_clk) then

  if i_vfr_start = '1' then
    i_vfr_busy <= '1';
    i_di_wr <= '1';

  else

    if i_di_rdy_n = '0' and i_vfr_busy = '1' then

      if i_di_wr = '1' then
        if i_cntpix = TO_UNSIGNED(G_VFR_PIX_COUNT - 1 ,i_cntpix'length) then
          i_cntpix <= (others => '0');
          if i_cntline = TO_UNSIGNED(G_VFR_LINE_COUNT - 1 ,i_cntline'length) then
            i_cntline <= (others => '0');
            i_vfr_busy <= '0';
            i_di_wr <= '0';
          else
            i_cntline <= i_cntline + 1;
          end if;
        else
          i_cntpix <= i_cntpix + 1;

        end if;

        if i_cntline = TO_UNSIGNED(G_VFR_LINE_COUNT - 1 ,i_cntline'length) then
          if i_cntpix = TO_UNSIGNED(G_VFR_PIX_COUNT - 2 ,i_cntpix'length) then
            i_di_eof <= '1';
          else
            i_di_eof <= '0';
          end if;
        end if;

      end if;

      i_di_wr <= not i_di_wr;
      i_di <= i_di + 1;

    else
      i_di_wr <= '0';

    end if;
  end if;
  end if;

--  sr_di    <= i_di;
--  sr_di_wr <= i_di_wr;
--  i_di_eof <= di_eof;

end process;

i_do_rdy_n <= '0';



process
begin

i_vfr_start <= '0';

wait for 2 us;

wait until rising_edge(i_clk);
i_vfr_start <= '1';
wait until rising_edge(i_clk);
i_vfr_start <= '0';

wait for 2 us;

wait until rising_edge(i_clk);
i_vfr_start <= '1';
wait until rising_edge(i_clk);
i_vfr_start <= '0';

wait;
end process;


end architecture testbanch;
