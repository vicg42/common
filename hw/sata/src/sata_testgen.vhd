-------------------------------------------------------------------------
-- Company     : Linkos
-- Engineer    : Golovachenko Victor
--
-- Create Date : 02.08.2011 9:44:37
-- Module Name : sata_testgen
--
-- Назначение :
--
-- Revision:
-- Revision 0.01
--
-------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

library work;
use work.vicg_common_pkg.all;
use work.sata_testgen_pkg.all;

entity sata_testgen is
port(
--------------------------------------------------
--USR
--------------------------------------------------
p_in_gen_cfg   : in   THDDTstGen;--//Подробнее см. sata_testgen_pkg.vhd

p_out_rdy      : out  std_logic;
p_out_hwon     : out  std_logic;

p_out_tdata    : out  std_logic_vector(31 downto 0);
p_out_tdata_en : out  std_logic;

----------------------------------------------------
----Технологические сигналы
----------------------------------------------------
--p_in_tst       : in    std_logic_vector(31 downto 0);
--p_out_tst      : out   std_logic_vector(31 downto 0);

--------------------------------------------------
--System
--------------------------------------------------
p_in_clk       : in   std_logic;
p_in_rst       : in   std_logic
);
end sata_testgen;

architecture behavioral of sata_testgen is

signal i_shim             : std_logic;
signal i_cntbase          : std_logic_vector(p_in_gen_cfg.tesing_spd'range):=(others=>'0');
signal i_spd              : std_logic_vector(p_in_gen_cfg.tesing_spd'range):=(others=>'0');
signal sr_start           : std_logic_vector(0 to 1);
signal sr_stop            : std_logic_vector(0 to 1);
signal i_start            : std_logic;
signal i_stop             : std_logic;
signal i_work             : std_logic;


--MAIN
begin


p_out_tdata<=CONV_STD_LOGIC_VECTOR(16#55667788#, p_out_tdata'length);
p_out_tdata_en<=i_shim;

--//Включение генерации тестовых данных
process(p_in_rst,p_in_clk)
begin
  if p_in_rst='1' then
    sr_start<=(others=>'0');
    sr_stop<=(others=>'0');
    i_start<='0';
    i_stop<='0';
    i_work<='0';
    i_spd<=(others=>'0');

    p_out_rdy<='0';
    p_out_hwon<='0';

  elsif p_in_clk'event and p_in_clk='1' then

    p_out_rdy<=p_in_gen_cfg.tesing_on;
    p_out_hwon<=p_in_gen_cfg.stop;

    i_spd<=p_in_gen_cfg.tesing_spd;

    sr_start<=(p_in_gen_cfg.tesing_on and p_in_gen_cfg.start) & sr_start(0 to 0);
    i_start<=sr_start(0) and not sr_start(1);

    sr_stop<=p_in_gen_cfg.stop & sr_stop(0 to 0);
    i_stop<=not sr_stop(0) and sr_stop(1);

    if i_stop='1' or p_in_gen_cfg.clr_err='1' then
      i_work<='0';
    elsif i_start='1' then
      i_work<='1';
    end if;
  end if;
end process;

--//Регулировка потока тестовых данных
process(p_in_rst,p_in_clk)
begin
  if p_in_rst='1' then
    i_shim<='0';
  elsif p_in_clk'event and p_in_clk='1' then
    if i_work='0' or (i_spd/=(i_spd'range =>'0') and i_cntbase=(i_cntbase'range => '1')) then
      i_shim<='0';
    elsif i_cntbase=i_spd then
      i_shim<='1';
    end if;
  end if;
end process;


--Базовый счетчик
process(p_in_clk)
begin
  if p_in_clk'event and p_in_clk='1' then
    if i_work='0' then
      i_cntbase<=(others=>'0');
    else
      i_cntbase<=i_cntbase+1;
    end if;
  end if;
end process;


--END MAIN
end behavioral;
