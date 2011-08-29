-------------------------------------------------------------------------
-- Company     : Linkos
-- Engineer    : Golovachenko Victor
--
-- Create Date : 26.08.2011 19:16:50
-- Module Name : sata_hwstart_ctrl
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
--use work.sata_raid_pkg.all;
--use work.sata_unit_pkg.all;

entity sata_hwstart_ctrl is
generic
(
G_T05us     : integer:=1;
G_DBGCS     : string :="OFF";
G_DBG       : string :="OFF";
G_SIM       : string :="OFF"
);
port
(
--------------------------------------------------
--
--------------------------------------------------
p_in_ctrl      : in    std_logic_vector(C_USR_GCTRL_LAST_BIT downto 0);

--------------------------------------------------
--Связь с модулям sata_raid.vhd
--------------------------------------------------
p_in_hw_work   : in    std_logic;
p_in_hw_start  : in    std_logic;
p_out_hw_start : out   std_logic;

p_in_sh_cmddone: in    std_logic;
p_in_mstatus   : in    TMeasureStatus;

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
end sata_hwstart_ctrl;

architecture behavioral of sata_hwstart_ctrl is

signal i_1us                    : std_logic:='0';
signal i_cnt_05us               : integer range 0 to G_T05us-1:=0;
signal i_cnt_us                 : std_logic_vector(15 downto 0):=(others=>'0');
signal i_usr_hwdly_dis          : std_logic:='0';
signal i_usr_dly                : std_logic_vector(C_USR_GCTRL_HWSTART_DLY_M_BIT-C_USR_GCTRL_HWSTART_DLY_L_BIT downto 0):=CONV_STD_LOGIC_VECTOR(20, C_USR_GCTRL_HWSTART_DLY_M_BIT-C_USR_GCTRL_HWSTART_DLY_L_BIT+1);--(others=>'0');
signal i_hw_dly                 : std_logic_vector(i_usr_dly'range);
signal i_hw_work                : std_logic:='0';
signal i_hw_start_in            : std_logic:='0';
signal i_hw_start_out           : std_logic:='0';
signal sr_hw_start              : std_logic_vector(0 to 1):=(others=>'0');
signal i_hw_start               : std_logic:='0';
signal i_tmr_en                 : std_logic_vector(0 to 1);
signal i_tmr_start              : std_logic:='0';
signal sr_hwdly_set             : std_logic_vector(0 to 1);
signal i_hwdly_set              : std_logic;

signal tst_hw_dly_set             : std_logic_vector(3 downto 0);

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
--//Логика работы
--//------------------------------------------
--//Пересинхронизация
process(p_in_clk)
begin
  if p_in_clk'event and p_in_clk='1' then
    i_hw_work<=p_in_hw_work;
    i_hw_start_in<=p_in_hw_start;

    i_usr_dly<=p_in_ctrl(C_USR_GCTRL_HWSTART_DLY_M_BIT downto C_USR_GCTRL_HWSTART_DLY_L_BIT);
    i_usr_hwdly_dis<=p_in_ctrl(C_USR_GCTRL_HWSTART_DLY_DIS_BIT);
  end if;
end process;


--//Формирование запуска таймера
process(p_in_rst,p_in_clk)
begin
  if p_in_rst='1' then
    sr_hwdly_set<=(others=>'0');
    i_hwdly_set<='0';
    sr_hw_start<=(others=>'0');
    i_hw_start<='0';

    i_tmr_en<=(others=>'0');
    i_tmr_start<='0';

  elsif p_in_clk'event and p_in_clk='1' then
    sr_hwdly_set<=p_in_mstatus.hwlog.measure & sr_hwdly_set(0 to 0);
    i_hwdly_set<=not sr_hwdly_set(0) and sr_hwdly_set(1);

    sr_hw_start<=i_hw_start_in & sr_hw_start(0 to 0);
    i_hw_start<=sr_hw_start(0) and not sr_hw_start(1);

    if i_hw_work='0' or AND_reduce(i_tmr_en)='1' then
      i_tmr_en<=(others=>'0');
    else
      if i_hw_start='1' then
        i_tmr_en(0)<='1';
      end if;

      if i_hwdly_set='1' then
        i_tmr_en(1)<='1';
      end if;
    end if;

    i_tmr_start<=AND_reduce(i_tmr_en);

  end if;
end process;

--//TMR задержки
process(p_in_clk)
begin
  if p_in_clk'event and p_in_clk='1' then

    if i_tmr_start='1' then --or i_hw_work='0' then
      i_cnt_05us<=0;
      i_1us<='0';
      i_cnt_us<=(others=>'0');
      i_hw_start_out<='1';--i_hw_work;

    elsif i_hw_start_out='1' then

      if i_cnt_05us=G_T05us-1 then
        i_cnt_05us<=0;
        i_1us<=not i_1us;
        if i_1us='1' then
          if (i_usr_hwdly_dis='0' and i_cnt_us=i_hw_dly) or
             (i_usr_hwdly_dis='1' and i_cnt_us=CONV_STD_LOGIC_VECTOR(2, i_cnt_us'length)) then
            i_cnt_us<=(others=>'0');
            i_hw_start_out<='0';
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

p_out_hw_start<=i_hw_start_out;




gen_sim_off : if strcmp(G_SIM,"OFF") generate
--//Выбор задержки HWSTART
--//p_in_mstatus.hwlog.tdly=150 ----- 1us
--//p_in_mstatus.hwlog.tdly=150000 -- 1ms
process(p_in_rst,p_in_clk)
begin
  if p_in_rst='1' then
    i_hw_dly<=CONV_STD_LOGIC_VECTOR(1, i_hw_dly'length);

    tst_hw_dly_set<=(others=>'0');

  elsif p_in_clk'event and p_in_clk='1' then

    if i_hwdly_set='1' then

        if    p_in_mstatus.hwlog.tdly>=CONV_STD_LOGIC_VECTOR(150000*5, p_in_mstatus.hwlog.tdly'length) then
          --//min/max - 4ms/60ms - шаг 4ms
          i_hw_dly<=i_usr_dly(15 downto 12)&"000000000000";
          tst_hw_dly_set<=CONV_STD_LOGIC_VECTOR(16#8#, tst_hw_dly_set'length);

        elsif p_in_mstatus.hwlog.tdly>=CONV_STD_LOGIC_VECTOR(210000, p_in_mstatus.hwlog.tdly'length) then --150000*1.4
          --//min/max - 256us/3.8ms
          i_hw_dly<="0000"&i_usr_dly(11 downto 8)&"00000000";
          tst_hw_dly_set<=CONV_STD_LOGIC_VECTOR(16#4#, tst_hw_dly_set'length);

        elsif p_in_mstatus.hwlog.tdly>=CONV_STD_LOGIC_VECTOR(150*700, p_in_mstatus.hwlog.tdly'length) then
          --//min/max - 16us/240us
          i_hw_dly<="00000000"&i_usr_dly(7 downto 4)&"0000";
          tst_hw_dly_set<=CONV_STD_LOGIC_VECTOR(16#3#, tst_hw_dly_set'length);

        elsif p_in_mstatus.hwlog.tdly>=CONV_STD_LOGIC_VECTOR(150*200, p_in_mstatus.hwlog.tdly'length) then
          --//min/max - 1us/15us
          i_hw_dly<="000000000000"&i_usr_dly(3 downto 0);
          tst_hw_dly_set<=CONV_STD_LOGIC_VECTOR(16#1#, tst_hw_dly_set'length);

        else
          i_hw_dly<=CONV_STD_LOGIC_VECTOR(1, i_hw_dly'length);
          tst_hw_dly_set<=(others=>'0');

        end if;

    end if;

  end if;
end process;

end generate gen_sim_off;



--//-----------------------------------
--//Debug/Sim
--//-----------------------------------
gen_sim_on : if strcmp(G_SIM,"ON") generate

process(p_in_rst,p_in_clk)
begin
  if p_in_rst='1' then
    i_hw_dly<=CONV_STD_LOGIC_VECTOR(1, i_hw_dly'length);

  elsif p_in_clk'event and p_in_clk='1' then

    if i_hwdly_set='1' then

        if    p_in_mstatus.hwlog.tdly>=CONV_STD_LOGIC_VECTOR(150000*5, p_in_mstatus.hwlog.tdly'length) then
          i_hw_dly<="00000000"&i_usr_dly(15 downto 12)&"0000";

        elsif p_in_mstatus.hwlog.tdly>=CONV_STD_LOGIC_VECTOR(300, p_in_mstatus.hwlog.tdly'length) then
          i_hw_dly<="00000000"&i_usr_dly(11 downto 8)&"0000";

        elsif p_in_mstatus.hwlog.tdly>=CONV_STD_LOGIC_VECTOR(288, p_in_mstatus.hwlog.tdly'length) then
          i_hw_dly<="00000000"&i_usr_dly(7 downto 4)&"0000";

        elsif p_in_mstatus.hwlog.tdly>=CONV_STD_LOGIC_VECTOR(200, p_in_mstatus.hwlog.tdly'length) then
          i_hw_dly<="000000000000"&i_usr_dly(3 downto 0);

        else
          i_hw_dly<=CONV_STD_LOGIC_VECTOR(1, i_hw_dly'length);
        end if;

    end if;

  end if;
end process;

end generate gen_sim_on;


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

p_out_dbgcs.trig0(0)<=i_tmr_start;
p_out_dbgcs.trig0(1)<=tst_hw_dly_set(0);
p_out_dbgcs.trig0(2)<=tst_hw_dly_set(1);
p_out_dbgcs.trig0(3)<=tst_hw_dly_set(2);
p_out_dbgcs.trig0(4)<=tst_hw_dly_set(3);
p_out_dbgcs.trig0(5)<='0';
p_out_dbgcs.trig0(6)<='0';
p_out_dbgcs.trig0(7)<='0';
--p_out_dbgcs.trig0(8)<='0';
--p_out_dbgcs.trig0(41 downto 9)<=(others=>'0');

p_out_dbgcs.data(0)<=i_tmr_start;
p_out_dbgcs.data(1)<=tst_hw_dly_set(0);
p_out_dbgcs.data(2)<=tst_hw_dly_set(1);
p_out_dbgcs.data(3)<=tst_hw_dly_set(2);
p_out_dbgcs.data(4)<=tst_hw_dly_set(3);
p_out_dbgcs.data(5)<=i_hw_start;
p_out_dbgcs.data(6)<=i_hwdly_set;
p_out_dbgcs.data(7)<='0';
--p_out_dbgcs.data(8)<='0';
--p_out_dbgcs.data(73 downto 9)<=(others=>'0');

end if;
end process;

end generate gen_dbgcs_on;
--END MAIN
end behavioral;


