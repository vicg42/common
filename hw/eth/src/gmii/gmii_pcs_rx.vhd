-------------------------------------------------------------------------
-- Company     : Linkos
-- Engineer    : Golovachenko Victor
--
-- Create Date : 22.05.2012 11:55:44
-- Module Name : gmii_pcs_rx
--
-- Назначение/Описание :
--
--
--
-------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_misc.all;
use ieee.std_logic_unsigned.all;

library work;
use work.vicg_common_pkg.all;
use work.gmii_pkg.all;

entity gmii_pcs_rx is
generic(
G_GT_DBUS : integer:=8;
G_DBG : string:="OFF";
G_SIM : string:="OFF"
);
port(
--------------------------------------
--GMII
--------------------------------------
p_out_rxd               : out   std_logic_vector(7 downto 0);
p_out_rx_dv             : out   std_logic;
p_out_rx_er             : out   std_logic;
p_out_rx_crs            : out   std_logic;

--------------------------------------
--RocketIO Receiver
--------------------------------------
p_in_gt_rxdata          : in    std_logic_vector(31 downto 0);
p_in_gt_rxcharisk       : in    std_logic_vector(3 downto 0);
p_in_gt_rxdisperr       : in    std_logic_vector(3 downto 0);
p_in_gt_rxnotintable    : in    std_logic_vector(3 downto 0);
p_in_gt_rxbyteisaligned : in    std_logic;

p_in_gt_rxbufstatus     : in    std_logic_vector(2 downto 0);
p_out_gt_rxbufreset     : out   std_logic;

--------------------------------------
--Технологические сигналы
--------------------------------------
p_in_tst                : in    std_logic_vector(31 downto 0);
p_out_tst               : out   std_logic_vector(31 downto 0);

--------------------------------------
--SYSTEM
--------------------------------------
p_in_clk                : in    std_logic;
p_in_rst                : in    std_logic
);
end gmii_pcs_rx;

architecture behavioral of gmii_pcs_rx is

type fsm_state is (
S_LOS,
S_COMMA_DET1,
S_ACQU_SYNC1,
S_COMMA_DET2,
S_ACQU_SYNC2,
S_COMMA_DET3,

S_SYNC_ACQU1
--S_SYNC_ACQU2,
--S_SYNC_ACQU3,
--S_SYNC_ACQU4,
--
--S_SYNC_ACQU1A,
--S_SYNC_ACQU2A,
--S_SYNC_ACQU3A,
--S_SYNC_ACQU4A
);
signal fsm_sync_cs : fsm_state;

signal i_tmr_rst           : std_logic_vector(1 downto 0);
signal i_tmr_rst_en        : std_logic;

signal i_gt_rxbufreset     : std_logic;

--signal i_rxstatus          : std_logic_vector(C_PCS_RxSTAT_LAST_BIT downto 0):=(others=>'0');
signal i_rxd               : std_logic_vector(7 downto 0):=(others=>'0');
signal i_rxdtype           : std_logic:='0';
signal i_rx_even           : std_logic;

signal tst_fsm_sync_cs    : std_logic_vector(5 downto 0):=(others=>'0');

--MAIN
begin

--//----------------------------------
--//Технологические сигналы
--//----------------------------------
gen_dbg_off : if strcmp(G_DBG,"OFF") generate
p_out_tst(31 downto 0)<=(others=>'0');
end generate gen_dbg_off;

gen_dbg_on : if strcmp(G_DBG,"ON") generate
--process(p_in_clk)
--begin
--  if p_in_clk'event and p_in_clk='1' then
p_out_tst(5 downto 0)<=tst_fsm_sync_cs;
p_out_tst(11 downto 6)<=(others=>'0');--tst_fsm_pcs_rx;
p_out_tst(12)<=i_rx_even;
p_out_tst(15 downto 13)<=(others=>'0');
p_out_tst(23 downto 16)<=i_rxd;
p_out_tst(24)          <=i_rxdtype;
p_out_tst(31 downto 25)<=(others=>'0');
--  end if;
--end process;
tst_fsm_sync_cs<=CONV_STD_LOGIC_VECTOR(16#01#,tst_fsm_sync_cs'length) when fsm_sync_cs=S_COMMA_DET1     else
                 CONV_STD_LOGIC_VECTOR(16#02#,tst_fsm_sync_cs'length) when fsm_sync_cs=S_ACQU_SYNC1     else
                 CONV_STD_LOGIC_VECTOR(16#03#,tst_fsm_sync_cs'length) when fsm_sync_cs=S_COMMA_DET2     else
                 CONV_STD_LOGIC_VECTOR(16#04#,tst_fsm_sync_cs'length) when fsm_sync_cs=S_ACQU_SYNC2     else
                 CONV_STD_LOGIC_VECTOR(16#05#,tst_fsm_sync_cs'length) when fsm_sync_cs=S_COMMA_DET3     else
                 CONV_STD_LOGIC_VECTOR(16#06#,tst_fsm_sync_cs'length) when fsm_sync_cs=S_SYNC_ACQU1     else
--                 CONV_STD_LOGIC_VECTOR(16#07#,tst_fsm_sync_cs'length) when fsm_sync_cs=S_SYNC_ACQU2     else
--                 CONV_STD_LOGIC_VECTOR(16#08#,tst_fsm_sync_cs'length) when fsm_sync_cs=S_SYNC_ACQU3     else
--                 CONV_STD_LOGIC_VECTOR(16#09#,tst_fsm_sync_cs'length) when fsm_sync_cs=S_SYNC_ACQU4     else
--                 CONV_STD_LOGIC_VECTOR(16#0A#,tst_fsm_sync_cs'length) when fsm_sync_cs=S_SYNC_ACQU1A    else
--                 CONV_STD_LOGIC_VECTOR(16#0B#,tst_fsm_sync_cs'length) when fsm_sync_cs=S_SYNC_ACQU2A    else
--                 CONV_STD_LOGIC_VECTOR(16#0C#,tst_fsm_sync_cs'length) when fsm_sync_cs=S_SYNC_ACQU3A    else
--                 CONV_STD_LOGIC_VECTOR(16#0D#,tst_fsm_sync_cs'length) when fsm_sync_cs=S_SYNC_ACQU4A    else
                 CONV_STD_LOGIC_VECTOR(16#00#,tst_fsm_sync_cs'length);-- when fsm_sync_cs=S_LOS            else

end generate gen_dbg_on;


--//-----------------------------------
--//Контроль переполнения буфера приемника GT/  RX elastic buffer
--//-----------------------------------
tmr_rst:process(p_in_rst,p_in_clk)
begin
  if p_in_rst='1' then
    i_tmr_rst<=(others=>'0');
  elsif p_in_clk'event and p_in_clk='1' then
    if i_tmr_rst_en='1' then
      i_tmr_rst<=i_tmr_rst+1;
    else
      i_tmr_rst<=(others=>'0');
    end if;
  end if;
end process;

process(p_in_rst,p_in_clk)
begin
  if p_in_rst='1' then
    i_tmr_rst_en<='0';
    i_gt_rxbufreset<='0';

  elsif p_in_clk'event and p_in_clk='1' then
    if i_tmr_rst_en='0' then
      i_gt_rxbufreset<='0';
      if (p_in_gt_rxbufstatus="101" or p_in_gt_rxbufstatus="110") then
      --"101" - underflow
      --"110" - overflow
      --формирую сброс
        i_tmr_rst_en<='1';
      end if;
    else
      i_gt_rxbufreset<='1';
      if i_tmr_rst=CONV_STD_LOGIC_VECTOR(16#02#, i_tmr_rst'length) then
        i_tmr_rst_en<='0';
      end if;
    end if;
  end if;
end process;

p_out_gt_rxbufreset<=i_gt_rxbufreset;

--//----------------------------------
--//Статусы
--//----------------------------------
p_out_rxd     <=i_rxd;
--p_out_rxstatus<=i_status;

--i_status(C_PCS_RxSTAT_EVEN)<=i_rx_even;
process(p_in_rst,p_in_clk)
begin
  if p_in_rst='1' then
    i_rxd<=(others=>'0');
    i_rxdtype<='0';
  elsif p_in_clk'event and p_in_clk='1' then
    i_rxd<=p_in_gt_rxdata(7 downto 0);
    i_rxdtype<=p_in_gt_rxcharisk(0);
  end if;
end process;


--//#########################################
--//Synchronization - FSM
--//(см. пп 36.2.5.2.6 IEEE_Std_802.3-2005_section3.pdf)
--//#########################################
process(p_in_rst,p_in_clk)
begin
  if p_in_rst='1' then
    fsm_sync_cs <= S_LOS;
    i_rx_even<='0';
    i_status(C_PCS_RxSTAT_SYNC)<='0';

  elsif p_in_clk'event and p_in_clk='1' then

    case fsm_sync_cs is
      --------------------------------------
      --
      --------------------------------------
      when S_LOS =>

        i_rx_even<=not i_rx_even;
        i_status(C_PCS_RxSTAT_SYNC)<='0';--fail

        if p_in_gt_rxcharisk(0)=C_CHAR_K and
           ( p_in_gt_rxdata(7 downto 0)=C_K28_5 or
             p_in_gt_rxdata(7 downto 0)=C_K28_1 or
             p_in_gt_rxdata(7 downto 0)=C_K28_7) then

            fsm_sync_cs <= S_COMMA_DET1;
        end if;

      --------------------------------------
      --
      --------------------------------------
      when S_COMMA_DET1 =>

        i_rx_even<='1';

        if p_in_gt_rxcharisk(0)=C_CHAR_D then
          fsm_sync_cs <= S_ACQU_SYNC1;
        else
          fsm_sync_cs <= S_LOS;
        end if;

      --------------------------------------
      --
      --------------------------------------
      when S_ACQU_SYNC1 =>

        i_rx_even<=not i_rx_even;

        if p_in_gt_rxcharisk(0)=C_CHAR_K and
           ( p_in_gt_rxdata(7 downto 0)=C_K28_5 or
             p_in_gt_rxdata(7 downto 0)=C_K28_1 or
             p_in_gt_rxdata(7 downto 0)=C_K28_7) then

            if i_rx_even='1' then
              fsm_sync_cs <= S_COMMA_DET2;--cggood
            else
              fsm_sync_cs <= S_LOS;--cgbad
            end if;
        end if;

      --------------------------------------
      --
      --------------------------------------
      when S_COMMA_DET2 =>

        i_rx_even<='1';

        if p_in_gt_rxcharisk(0)=C_CHAR_D then
          fsm_sync_cs <= S_ACQU_SYNC2;
        else
          fsm_sync_cs <= S_LOS;
        end if;

      --------------------------------------
      --
      --------------------------------------
      when S_ACQU_SYNC2 =>

        i_rx_even<=not i_rx_even;

        if p_in_gt_rxcharisk(0)=C_CHAR_K and
           ( p_in_gt_rxdata(7 downto 0)=C_K28_5 or
             p_in_gt_rxdata(7 downto 0)=C_K28_1 or
             p_in_gt_rxdata(7 downto 0)=C_K28_7) then

            if i_rx_even='1' then
              fsm_sync_cs <= S_COMMA_DET3;--cggood
            else
              fsm_sync_cs <= S_LOS;--cgbad
            end if;
        end if;

      --------------------------------------
      --
      --------------------------------------
      when S_COMMA_DET3 =>

        i_rx_even<='1';

        if p_in_gt_rxcharisk(0)=C_CHAR_D then
          fsm_sync_cs <= S_ACQU_SYNC1;
        else
          fsm_sync_cs <= S_LOS;
        end if;

      --------------------------------------
      --
      --------------------------------------
      when S_SYNC_ACQU1 =>

        i_rx_even<=not i_rx_even;
        i_status(C_PCS_RxSTAT_SYNC)<='1';--OK

        if p_in_gt_rxcharisk(0)=C_CHAR_K and
           ( p_in_gt_rxdata(7 downto 0)=C_K28_5 or
             p_in_gt_rxdata(7 downto 0)=C_K28_1 or
             p_in_gt_rxdata(7 downto 0)=C_K28_7) then

--          if i_rx_even='1' then
--            fsm_sync_cs <= S_COMMA_DET3;--cggood
--          else
            fsm_sync_cs <= S_LOS;--cgbad
--          end if;
        end if;

    end case;

  end if;
end process;



--END MAIN
end behavioral;

