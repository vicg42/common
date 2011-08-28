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

--------------------------------------------------
--System
--------------------------------------------------
p_in_clk       : in    std_logic;
p_in_rst       : in    std_logic
);
end sata_hwstart_ctrl;

architecture behavioral of sata_hwstart_ctrl is

signal i_1us                    : std_logic:='0';
signal i_cnt_05us               : integer range 0 to G_T05us-1:=0;--std_logic_vector(9 downto 0):=(others=>'0');
signal i_cnt_us                 : std_logic_vector(15 downto 0):=(others=>'0');

signal i_usr_dly                : std_logic_vector(C_USR_GCTRL_HWSTART_DLY_M_BIT-C_USR_GCTRL_HWSTART_DLY_L_BIT downto 0):=CONV_STD_LOGIC_VECTOR(20, C_USR_GCTRL_HWSTART_DLY_M_BIT-C_USR_GCTRL_HWSTART_DLY_L_BIT+1);--(others=>'0');
signal i_hw_work                : std_logic:='0';
signal i_hw_start_in            : std_logic:='0';
signal i_hw_start_out           : std_logic:='0';
signal sr_start                 : std_logic_vector(0 to 1):=(others=>'0');
signal i_start                  : std_logic:='0';


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
  end if;
end process;


--//Формироваение завдержки
process(p_in_clk)
begin
  if p_in_clk'event and p_in_clk='1' then

    sr_start<=i_hw_start_in & sr_start(0 to 0);
    i_start<=sr_start(0) and not sr_start(1);

    if i_start='1' or i_hw_work='0' then
      i_cnt_05us<=0;--(others=>'0');
      i_1us<='0';
      i_cnt_us<=(others=>'0');
      i_hw_start_out<=i_hw_work;

    elsif i_hw_start_out='1' then

      if i_cnt_05us=G_T05us-1 then--CONV_STD_LOGIC_VECTOR(G_T05us-1, i_cnt_05us'length) then
        i_cnt_05us<=0;--(others=>'0');
        i_1us<=not i_1us;
        if i_1us='1' then
          if i_cnt_us=EXT(i_usr_dly, i_cnt_us'length) then
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


--END MAIN
end behavioral;


