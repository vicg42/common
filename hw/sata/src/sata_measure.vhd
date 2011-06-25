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
use work.sata_unit_pkg.all;
use work.sata_pkg.all;
--use work.sata_sim_lite_pkg.all;
use work.sata_raid_pkg.all;

entity sata_measure is
generic
(
G_T05us     : integer:=1;
G_HDD_COUNT : integer:=1;    --//Кол-во sata устр-в (min/max - 1/8)
G_DBG       : string :="OFF";
G_SIM       : string :="OFF"
);
port
(
--------------------------------------------------
--Связь с модулем dsn_hdd.vhd
--------------------------------------------------
p_in_ctrl      : in    std_logic_vector(C_USR_GCTRL_LAST_BIT downto 0);
p_out_status   : out   TMeasureStatus;

--------------------------------------------------
--Связь с модулям sata_host.vhd
--------------------------------------------------
p_in_dev_busy  : in    std_logic;
p_in_sh_status : in    TMeasureALStatus_SHCountMax;

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
end sata_measure;

architecture behavioral of sata_measure is

constant C_Tms                  : integer:=10#1000#;--1ms
constant C_Tsec                 : integer:=10#1000#;--1sec
constant C_Tmin                 : integer:=10#0060#;--1min

signal i_1us                    : std_logic;
signal i_cnt_05us               : std_logic_vector(9 downto 0);
signal i_cnt_us                 : std_logic_vector(9 downto 0);
signal i_cnt_ms                 : std_logic_vector(9 downto 0);
signal i_cnt_sec                : std_logic_vector(5 downto 0);
signal i_cnt_min                : std_logic_vector(15 downto 0);
signal i_measure_dly_tcnt       : std_logic_vector(31 downto 0);
signal i_measure_dly_time       : std_logic_vector(31 downto 0);

signal i_sh_tlayer_rxon         : std_logic_vector(G_HDD_COUNT-1 downto 0);
signal i_sh_tlayer_txon         : std_logic_vector(G_HDD_COUNT-1 downto 0);
--signal i_sh_llayer_rxon         : std_logic_vector(G_HDD_COUNT-1 downto 0);
--signal i_sh_llayer_txon         : std_logic_vector(G_HDD_COUNT-1 downto 0);
signal i_sh_llayer_txhold       : std_logic_vector(G_HDD_COUNT-1 downto 0);
signal i_sh_llayer_rxhold       : std_logic_vector(G_HDD_COUNT-1 downto 0);

signal i_dly_on                 : std_logic;

signal sr_measure_start         : std_logic_vector(0 to 1);
signal i_measure_start          : std_logic;


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
p_out_tst(0)<=i_1us;
p_out_tst(31 downto 1)<=(others=>'0');




process(p_in_rst,p_in_clk)
begin
  if p_in_rst='1' then
    for i in 0 to G_HDD_COUNT-1 loop
      i_sh_tlayer_rxon(i)<='0';
      i_sh_tlayer_txon(i)<='0';
--      i_sh_llayer_rxon(i)<='0';
--      i_sh_llayer_txon(i)<='0';
      i_sh_llayer_txhold(i)<='0';
      i_sh_llayer_rxhold(i)<='0';
    end loop;

    i_dly_on<='0';
    sr_measure_start<=(others=>'0');
    i_measure_start<='0';

  elsif p_in_clk'event and p_in_clk='1' then

    for i in 0 to G_HDD_COUNT-1 loop

      i_sh_tlayer_rxon(i)<=p_in_sh_status(i).Usr(C_AUSER_TLRX_ON_BIT);
      i_sh_tlayer_txon(i)<=p_in_sh_status(i).Usr(C_AUSER_TLTX_ON_BIT);
--      i_sh_llayer_rxon(i)<=p_in_sh_status(i).Usr(C_AUSER_LLRX_ON_BIT);
--      i_sh_llayer_txon(i)<=p_in_sh_status(i).Usr(C_AUSER_LLTX_ON_BIT);
      i_sh_llayer_txhold(i)<=p_in_sh_status(i).Usr(C_AUSER_LLTXP_HOLD_BIT);
      i_sh_llayer_rxhold(i)<=p_in_sh_status(i).Usr(C_AUSER_LLRXP_HOLD_BIT);

    end loop;

    if p_in_ctrl(C_USR_GCTRL_MEASURE_BUSY_ONLY_BIT)='1' then
      i_dly_on<=p_in_dev_busy;
    else
      i_dly_on<=(p_in_dev_busy xor (OR_reduce(i_sh_tlayer_txon) or OR_reduce(i_sh_tlayer_rxon)) ) or
                ((OR_reduce(i_sh_llayer_txhold) and not p_in_ctrl(C_USR_GCTRL_MEASURE_TXHOLD_DIS_BIT)) or
                 (OR_reduce(i_sh_llayer_rxhold) and not p_in_ctrl(C_USR_GCTRL_MEASURE_RXHOLD_DIS_BIT)) );
    end if;

    sr_measure_start<=p_in_ctrl(C_USR_GCTRL_TST_ON_BIT) & sr_measure_start(0 to 0);

    i_measure_start<=sr_measure_start(0) and not sr_measure_start(1);

  end if;
end process;





--//-----------------------------------
--//Измеряем время работы
--//-----------------------------------
process(p_in_rst,p_in_clk)
  variable a: std_logic;
begin
  if p_in_rst='1' then
    i_cnt_05us<=(others=>'0');
    i_cnt_us<=(others=>'0');
    i_cnt_ms<=(others=>'0');
    i_cnt_sec<=(others=>'0');
    i_cnt_min<=(others=>'0');
    a:='0';
    i_1us<='0';

  elsif p_in_clk'event and p_in_clk='1' then

    if i_measure_start='1' then
      i_cnt_05us<=(others=>'0');
      i_cnt_us<=(others=>'0');
      i_cnt_ms<=(others=>'0');
      i_cnt_sec<=(others=>'0');
      i_cnt_min<=(others=>'0');
      a:='0';
      i_1us<='0';

    elsif p_in_dev_busy='1' then
      if i_cnt_05us=CONV_STD_LOGIC_VECTOR(G_T05us-1, i_cnt_05us'length) then
        i_cnt_05us<=(others=>'0');
        a:= not a;
        i_1us<=a;
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
--//Измеряем задержку
--//-----------------------------------
process(p_in_rst,p_in_clk)
begin
  if p_in_rst='1' then
    i_measure_dly_tcnt<=(others=>'0');
    i_measure_dly_time<=(others=>'0');

  elsif p_in_clk'event and p_in_clk='1' then

    if i_measure_start='1' then
      i_measure_dly_tcnt<=(others=>'0');

    elsif p_in_dev_busy='1' then

      if i_dly_on='1' then
        i_measure_dly_tcnt<=i_measure_dly_tcnt+1;
      else
        i_measure_dly_tcnt<=(others=>'0');
      end if;

    end if;

    if i_measure_start='1' then
      i_measure_dly_time<=(others=>'0');

    elsif i_measure_dly_tcnt>i_measure_dly_time then
    --//Сохр. значение задержки если текущее знач. больше предыдущего
      i_measure_dly_time<=i_measure_dly_tcnt;
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

  elsif p_in_clk'event and p_in_clk='1' then

    p_out_status.tdly<=i_measure_dly_time;
    p_out_status.twork<=i_cnt_min & i_cnt_sec & i_cnt_ms;

  end if;
end process;

p_out_status.dly<=i_dly_on;


--END MAIN
end behavioral;


