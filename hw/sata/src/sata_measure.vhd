-------------------------------------------------------------------------
-- Company     : Linkos
-- Engineer    : Golovachenko Victor
--
-- Create Date : 27.05.2011 10:20:22
-- Module Name : sata_measure
--
-- Назначение :
--
-- Revision:
-- Revision 0.01 - File Created
--
--
-------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_misc.all;
use ieee.std_logic_unsigned.all;

library unisim;
use unisim.vcomponents.all;

library work;
use work.vicg_common_pkg.all;
use work.sata_glob_pkg.all;
use work.sata_pkg.all;
use work.sata_raid_pkg.all;
use work.sata_unit_pkg.all;

entity sata_measure is
generic(
G_T05us     : integer:=1;
G_HDD_COUNT : integer:=1;    --//Кол-во sata устр-в (min/max - 1/8)
G_DBGCS     : string :="OFF";
G_DBG       : string :="OFF";
G_SIM       : string :="OFF"
);
port(
--------------------------------------------------
--Связь с модулем dsn_hdd.vhd
--------------------------------------------------
p_in_ctrl      : in    std_logic_vector(C_USR_GCTRL_LAST_BIT downto 0);
p_out_status   : out   TMeasureStatus;

--------------------------------------------------
--Связь с модулям sata_host.vhd
--------------------------------------------------
p_in_sh_busy   : in    std_logic_vector(C_HDD_COUNT_MAX-1 downto 0);
p_in_dev_busy  : in    std_logic;
p_in_sh_status : in    TMeasureALStatus_SHCountMax;

--------------------------------------------------
--Технологические сигналы
--------------------------------------------------
p_in_tst       : in    std_logic_vector(31 downto 0);
p_out_tst      : out   std_logic_vector(31 downto 0);
p_out_dbgcs    : out   TSH_ila;

--------------------------------------------------
--System
--------------------------------------------------
p_in_clk       : in    std_logic;
p_in_rst       : in    std_logic
);
end sata_measure;

architecture behavioral of sata_measure is

constant C_Tms                  : integer:=10#1000#;--1ms
constant C_Tsec                 : integer:=10#1000#;--1sec
constant C_Tmin                 : integer:=10#0060#;--1min

signal i_sh_tlayer_rxon         : std_logic_vector(G_HDD_COUNT-1 downto 0);
signal i_sh_tlayer_txon         : std_logic_vector(G_HDD_COUNT-1 downto 0);
signal i_sh_llayer_rxon         : std_logic_vector(G_HDD_COUNT-1 downto 0);
signal i_sh_llayer_txon         : std_logic_vector(G_HDD_COUNT-1 downto 0);
--signal i_sh_llayer_txhold       : std_logic_vector(G_HDD_COUNT-1 downto 0);
--signal i_sh_llayer_rxhold       : std_logic_vector(G_HDD_COUNT-1 downto 0);

type TBus2 is array (0 to 1) of std_logic_vector(0 to 1);
type TBusTDly is array (0 to 1) of std_logic_vector(p_out_status.tdly'range);

signal i_1us                    : std_logic:='0';
signal i_cnt_05us               : integer range 0 to G_T05us-1:=0;
signal i_cnt_us                 : std_logic_vector(9 downto 0):=(others=>'0');
signal i_cnt_ms                 : std_logic_vector(9 downto 0):=(others=>'0');
signal i_cnt_sec                : std_logic_vector(5 downto 0):=(others=>'0');
signal i_cnt_min                : std_logic_vector(5 downto 0):=(others=>'0');

signal i_busy                   : std_logic_vector(1 downto 0):=(others=>'0');
signal i_dly_on                 : std_logic_vector(1 downto 0):=(others=>'0');
signal sr_measure_start         : TBus2;
signal i_measure_start          : std_logic_vector(1 downto 0);
signal i_measure_dly_tcnt       : TBusTDly:=( (others=>'0'), (others=>'0'));
signal i_measure_dly_time       : TBusTDly:=( (others=>'0'), (others=>'0'));

signal sr_stop                  : std_logic_vector(0 to 2);
signal i_measure_stop           : std_logic;


--MAIN
begin

--//----------------------------------
--//Технологические сигналы
--//----------------------------------
--gen_dbg_off : if strcmp(G_DBG,"OFF") generate
--p_out_tst(31 downto 0)<=(others=>'0');
--end generate gen_dbg_off;
--
--gen_dbg_on : if strcmp(G_DBG,"ON") generate
--p_out_tst(31 downto 0)<=(others=>'0');
----ltstout:process(p_in_rst,p_in_clk)
----begin
----  if p_in_rst='1' then
----    for i in 0 to G_HDD_COUNT-1 loop
----    i_tst(i)<='0';
----    end loop;
----  elsif p_in_clk'event and p_in_clk='1' then
----    for i in 0 to G_HDD_COUNT-1 loop
----    i_tst(i)<=OR_reduce(p_in_sh_tst(i)(2 downto 0));
----    end loop;
----  end if;
----end process ltstout;
----
----p_out_tst(0)<='0';
----p_out_tst(31 downto 1)<=(others=>'0');
--end generate gen_dbg_on;
p_out_tst(0)<='0';
p_out_tst(31 downto 1)<=(others=>'0');


--//------------------------------------------
--//Инициализация
--//------------------------------------------
process(p_in_rst,p_in_clk)
begin
  if p_in_rst='1' then
    for i in 0 to G_HDD_COUNT-1 loop
      i_sh_tlayer_rxon(i)<='0';
      i_sh_tlayer_txon(i)<='0';
      i_sh_llayer_rxon(i)<='0';
      i_sh_llayer_txon(i)<='0';
--      i_sh_llayer_txhold(i)<='0';
--      i_sh_llayer_rxhold(i)<='0';
    end loop;
    sr_stop<=(others=>'0');
    i_measure_stop<='0';

  elsif p_in_clk'event and p_in_clk='1' then

    for i in 0 to G_HDD_COUNT-1 loop
      i_sh_tlayer_rxon(i)<=p_in_sh_status(i).usr(C_AUSR_TLRX_ON_BIT);
      i_sh_tlayer_txon(i)<=p_in_sh_status(i).usr(C_AUSR_TLTX_ON_BIT);
      i_sh_llayer_rxon(i)<=p_in_sh_status(i).usr(C_AUSR_LLRX_ON_BIT);
      i_sh_llayer_txon(i)<=p_in_sh_status(i).usr(C_AUSR_LLTX_ON_BIT);
--      i_sh_llayer_txhold(i)<=p_in_sh_status(i).usr(C_AUSR_LLTXP_HOLD_BIT);
--      i_sh_llayer_rxhold(i)<=p_in_sh_status(i).usr(C_AUSR_LLRXP_HOLD_BIT);
    end loop;

    sr_stop<=i_busy(1) & sr_stop(0 to 1);
    i_measure_stop<=not sr_stop(0) and sr_stop(1);
  end if;
end process;




--//-----------------------------------
--//Измерения:
--//-----------------------------------
i_busy(0)<=p_in_dev_busy;
i_busy(1)<=OR_reduce(p_in_sh_busy(G_HDD_COUNT-1 downto 0));

gen : for i in 0 to 1 generate
--//Формируем  start
process(p_in_rst,p_in_clk)
begin
  if p_in_rst='1' then

    i_dly_on(i)<='0';
    sr_measure_start(i)<=(others=>'0');
    i_measure_start(i)<='0';

  elsif p_in_clk'event and p_in_clk='1' then

    i_dly_on(i)<=(i_busy(i) xor ((OR_reduce(i_sh_tlayer_txon) and OR_reduce(i_sh_llayer_txon)) or
                                 (OR_reduce(i_sh_tlayer_rxon) and OR_reduce(i_sh_llayer_rxon))) );

    sr_measure_start(i)<=i_busy(i) & sr_measure_start(i)(0 to 0);
    i_measure_start(i)<=sr_measure_start(i)(0) and not sr_measure_start(i)(1);

  end if;
end process;

--//Измеряем задержку
process(p_in_clk)
begin
  if p_in_clk'event and p_in_clk='1' then

    if i_measure_start(i)='1' then
      i_measure_dly_tcnt(i)<=(others=>'0');

    elsif i_busy(i)='1' then

      if i_dly_on(i)='1' then
        i_measure_dly_tcnt(i)<=i_measure_dly_tcnt(i)+1;
      else
        i_measure_dly_tcnt(i)<=(others=>'0');
      end if;

    end if;

    if i_measure_start(i)='1' then
      i_measure_dly_time(i)<=(others=>'0');

    elsif i_measure_dly_tcnt(i)>i_measure_dly_time(i) then
    --//Сохр. значение задержки если текущее знач. больше предыдущего
      i_measure_dly_time(i)<=i_measure_dly_tcnt(i);
    end if;

  end if;
end process;

end generate gen;

--//Измеряем время работы
process(p_in_clk)
begin
  if p_in_clk'event and p_in_clk='1' then

    if i_measure_start(0)='1' then
      i_cnt_05us<=0;
      i_cnt_us<=(others=>'0');
      i_cnt_ms<=(others=>'0');
      i_cnt_sec<=(others=>'0');
      i_cnt_min<=(others=>'0');
      i_1us<='0';

    elsif i_busy(0)='1' then
      if i_cnt_05us=G_T05us-1 then
        i_cnt_05us<=0;
        i_1us<=not i_1us;

        if i_1us='1' then
          if i_cnt_us=CONV_STD_LOGIC_VECTOR(C_Tms-1, i_cnt_us'length) then
            i_cnt_us<=(others=>'0');
            if i_cnt_ms=CONV_STD_LOGIC_VECTOR(C_Tsec-1, i_cnt_ms'length) then
              i_cnt_ms<=(others=>'0');
              if i_cnt_sec=CONV_STD_LOGIC_VECTOR(C_Tmin-1, i_cnt_sec'length) then
                i_cnt_sec<=(others=>'0');
                i_cnt_min<=i_cnt_min+1;
              else
                i_cnt_sec<=i_cnt_sec+1;
              end if;
            else
              i_cnt_ms<=i_cnt_ms+1;
            end if;
          else
            i_cnt_us<=i_cnt_us+1;
          end if;
        end if;

      else
        i_cnt_05us<=i_cnt_05us+1;
      end if;
    end if;
  end if;
end process;


--//-----------------------------------
--//Выдача результата
--//-----------------------------------
process(p_in_rst,p_in_clk)
begin
  if p_in_rst='1' then
    p_out_status.tdly<=(others=>'0');
    p_out_status.twork<=(others=>'0');
    p_out_status.hwlog.tdly<=(others=>'0');

  elsif p_in_clk'event and p_in_clk='1' then

    --//Общее время выполнения АТА команды + детектирование мах Delay
    p_out_status.tdly<=i_measure_dly_time(0);
    p_out_status.twork<=i_cnt_min & i_cnt_sec & i_cnt_ms & i_cnt_us;

    --//Только для режима HWЖ
    --//время выполнения АТА команды + детектирование Delay - для каждой HW транзакции
    if i_measure_stop='1' then
    p_out_status.hwlog.tdly<=i_measure_dly_time(1);
    end if;

  end if;
end process;
p_out_status.dly<=i_dly_on(0);
p_out_status.hwlog.measure<=sr_stop(2);
p_out_status.hwlog.log_on<=p_in_ctrl(C_USR_GCTRL_HWLOG_ON_BIT);



--//-----------------------------------
--//Debug/Sim
--//-----------------------------------
gen_dbgcs_off : if strcmp(G_DBGCS,"OFF") generate
p_out_dbgcs.clk   <=p_in_clk;
p_out_dbgcs.trig0 <=(others=>'0');
p_out_dbgcs.data  <=(others=>'0');
end generate gen_dbgcs_off;


gen_dbgcs_on : if strcmp(G_DBGCS,"ON") generate

p_out_dbgcs.clk   <=p_in_clk;
process(p_in_clk)
begin
if p_in_clk'event and p_in_clk='1' then

p_out_dbgcs.trig0(0)<=i_dly_on(0);
p_out_dbgcs.trig0(1)<=p_in_dev_busy;
p_out_dbgcs.trig0(2)<='0';--i_sh_llayer_txhold(0);
p_out_dbgcs.trig0(3)<='0';--i_sh_llayer_txhold(1);
p_out_dbgcs.trig0(4)<='0';--i_sh_llayer_rxhold(0);
p_out_dbgcs.trig0(5)<='0';--i_sh_llayer_rxhold(1);
p_out_dbgcs.trig0(6)<='0';
p_out_dbgcs.trig0(7)<='0';
p_out_dbgcs.trig0(8)<='0';


p_out_dbgcs.data(0)<=i_dly_on(0);
p_out_dbgcs.data(1)<=p_in_dev_busy;
p_out_dbgcs.data(2)<='0';--i_sh_llayer_txhold(0);
p_out_dbgcs.data(3)<='0';--i_sh_llayer_txhold(1);
p_out_dbgcs.data(4)<='0';--i_sh_llayer_rxhold(0);
p_out_dbgcs.data(5)<='0';--i_sh_llayer_rxhold(1);
p_out_dbgcs.data(6)<=i_sh_tlayer_txon(0);
p_out_dbgcs.data(7)<=i_sh_tlayer_txon(1);
p_out_dbgcs.data(8)<=i_sh_tlayer_rxon(0);
p_out_dbgcs.data(9)<=i_sh_tlayer_rxon(1);
p_out_dbgcs.data(41 downto 10)<=i_measure_dly_tcnt(0);
p_out_dbgcs.data(73 downto 42)<=i_measure_dly_time(0);

end if;
end process;

end generate gen_dbgcs_on;

--END MAIN
end behavioral;


