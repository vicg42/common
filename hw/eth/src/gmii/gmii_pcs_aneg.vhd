-------------------------------------------------------------------------
-- Company     : Linkos
-- Engineer    : Golovachenko Victor
--
-- Create Date : 22.05.2012 11:55:44
-- Module Name : gmii_pcs_aneg
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

entity gmii_pcs_aneg is
generic(
G_GT_DBUS : integer:=8;
G_DBG : string:="OFF";
G_SIM : string:="OFF"
);
port(
--------------------------------------
--
--------------------------------------
p_in_ctrl    : in    std_logic_vector(15 downto 0);

--------------------------------------
--
--------------------------------------
p_out_xmit   : out   std_logic_vector(3 downto 0);
p_in_rxcfg   : in    std_logic_vector(15 downto 0);
p_in_rxcfg_en: in    std_logic;
p_out_txcfg  : out   std_logic_vector(15 downto 0);

--------------------------------------
--Технологические сигналы
--------------------------------------
p_in_tst     : in    std_logic_vector(31 downto 0);
p_out_tst    : out   std_logic_vector(31 downto 0);

--------------------------------------
--SYSTEM
--------------------------------------
p_in_clk     : in    std_logic;
p_in_rst     : in    std_logic
);
end gmii_pcs_aneg;

architecture behavioral of gmii_pcs_aneg is

type fsm_ang_state is (
S_ANG_IDLE   ,
S_ANG_RESTART,

S_ANG_ABILITY_DET ,
S_ANG_ACK_DET,
S_ANG_ACK_DONE,

S_ANG_IDLE_DET,

S_ANG_LINK_OK
);
signal fsm_ang_cs : fsm_ang_state;

signal sr_rxcfg                       : std_logic_vector(15 downto 0);
signal i_rxcfg_cmp                    : std_logic_vector(1 downto 0);
signal i_rxcfg_cmp_clr                : std_logic;
signal i_txcfg                        : std_logic_vector(15 downto 0);
signal i_ang_done                     : std_logic;
signal i_xmit                         : std_logic_vector(3 downto 0);

signal tst_fsm_ang_cs                 : std_logic_vector(4 downto 0);


--MAIN
begin

--//----------------------------------
--//Технологические сигналы
--//----------------------------------
gen_dbg_off : if strcmp(G_DBG,"OFF") generate
p_out_tst(31 downto 0)<=(others=>'0');
end generate gen_dbg_off;

gen_dbg_on : if strcmp(G_DBG,"ON") generate

p_out_tst(4 downto 0)<=tst_fsm_ang_cs;
p_out_tst(31 downto 5)<=(others=>'0');

tst_fsm_ang_cs<=CONV_STD_LOGIC_VECTOR(16#01#,tst_fsm_ang_cs'length) when fsm_ang_cs=S_ANG_RESTART      else
                CONV_STD_LOGIC_VECTOR(16#02#,tst_fsm_ang_cs'length) when fsm_ang_cs=S_ANG_ABILITY_DET  else
                CONV_STD_LOGIC_VECTOR(16#03#,tst_fsm_ang_cs'length) when fsm_ang_cs=S_ANG_ACK_DET      else
                CONV_STD_LOGIC_VECTOR(16#04#,tst_fsm_ang_cs'length) when fsm_ang_cs=S_ANG_ACK_DONE     else
                CONV_STD_LOGIC_VECTOR(16#05#,tst_fsm_ang_cs'length) when fsm_ang_cs=S_ANG_IDLE_DET     else
                CONV_STD_LOGIC_VECTOR(16#06#,tst_fsm_ang_cs'length) when fsm_ang_cs=S_ANG_LINK_OK      else
                CONV_STD_LOGIC_VECTOR(16#00#,tst_fsm_ang_cs'length);-- when fsm_sync_cs=S_ANG_IDLE     else

end generate gen_dbg_on;


p_out_xmit<=i_xmit;-- CONV_STD_LOGIC_VECTOR(C_PCS_XMIT_DATA, p_out_xmit'length);

process(p_in_rst,p_in_clk)
begin
  if p_in_rst='1' then
    sr_rxcfg<=(others=>'1');
    i_rxcfg_cmp<=(others=>'0');
  elsif p_in_clk'event and p_in_clk='1' then
    if i_rxcfg_cmp_clr='1' then
      i_rxcfg_cmp<=(others=>'0');
      sr_rxcfg<=(others=>'1');
    else
        if p_in_rxcfg_en='1' then
          sr_rxcfg<=p_in_rxcfg;
          if p_in_rxcfg(15)=sr_rxcfg(15) and p_in_rxcfg(13 downto 0)=sr_rxcfg(13 downto 0) then
            if i_rxcfg_cmp="11" then
              i_rxcfg_cmp<="11";
            else
              i_rxcfg_cmp<=i_rxcfg_cmp + 1;
            end if;
          else
            i_rxcfg_cmp<=(others=>'0');
          end if;
        end if;
    end if;
  end if;
end process;

process(p_in_rst,p_in_clk)
begin
  if p_in_rst='1' then
    fsm_ang_cs <= S_ANG_IDLE;
    i_xmit<=(others=>'0');
    i_rxcfg_cmp_clr<='0';
    i_txcfg<=(others=>'0');
    i_ang_done<='0';

  elsif p_in_clk'event and p_in_clk='1' then

    case fsm_ang_cs is

      --------------------------------------
      --
      --------------------------------------
      when S_ANG_IDLE =>

        if i_ang_done='0' then
          i_txcfg<=(others=>'0');
          i_xmit<=CONV_STD_LOGIC_VECTOR(C_PCS_XMIT_CFG, i_xmit'length);
          i_rxcfg_cmp_clr<='1';
          fsm_ang_cs <= S_ANG_RESTART;
        else
          i_xmit<=CONV_STD_LOGIC_VECTOR(C_PCS_XMIT_DATA, i_xmit'length);
        end if;

      --------------------------------------
      --
      --------------------------------------
      when S_ANG_RESTART =>

        i_txcfg<=p_in_ctrl;

        if i_rxcfg_cmp="11" and p_in_rxcfg/=(p_in_rxcfg'range =>'0') then
          i_rxcfg_cmp_clr<='1';
          fsm_ang_cs <= S_ANG_ABILITY_DET;
        else
          i_rxcfg_cmp_clr<='0';
        end if;

      --------------------------------------
      --
      --------------------------------------
      when S_ANG_ABILITY_DET =>

        i_txcfg(14)<='1';

        if i_rxcfg_cmp="11" and p_in_rxcfg/=(p_in_rxcfg'range =>'0') then
          i_rxcfg_cmp_clr<='1';
          fsm_ang_cs <= S_ANG_ACK_DET;
        else
          i_rxcfg_cmp_clr<='0';
        end if;

      --------------------------------------
      --
      --------------------------------------
      when S_ANG_ACK_DET =>

        if i_rxcfg_cmp="11" and p_in_rxcfg=(p_in_rxcfg'range =>'0') then
          fsm_ang_cs <= S_ANG_IDLE;
        elsif i_rxcfg_cmp="11" and p_in_rxcfg/=(p_in_rxcfg'range =>'0') then
          i_rxcfg_cmp_clr<='1';
          fsm_ang_cs <= S_ANG_ACK_DONE;
        else
          i_rxcfg_cmp_clr<='0';
        end if;

      --------------------------------------
      --
      --------------------------------------
      when S_ANG_ACK_DONE =>

        if i_rxcfg_cmp="11" and p_in_rxcfg=(p_in_rxcfg'range =>'0') then
          fsm_ang_cs <= S_ANG_IDLE;
        elsif i_rxcfg_cmp="11" and p_in_rxcfg/=(p_in_rxcfg'range =>'0') then
          i_rxcfg_cmp_clr<='1';
          i_xmit<=CONV_STD_LOGIC_VECTOR(C_PCS_XMIT_IDLE, i_xmit'length);
          fsm_ang_cs <= S_ANG_IDLE_DET;
        else
          i_rxcfg_cmp_clr<='0';
        end if;

      --------------------------------------
      --
      --------------------------------------
      when S_ANG_IDLE_DET =>

        i_rxcfg_cmp_clr<='0';

        if i_rxcfg_cmp="11" and p_in_rxcfg=(p_in_rxcfg'range =>'0') then
          fsm_ang_cs <= S_ANG_IDLE;
        else
          i_ang_done<='1';
          i_xmit<=CONV_STD_LOGIC_VECTOR(C_PCS_XMIT_DATA, i_xmit'length);
          fsm_ang_cs <= S_ANG_LINK_OK;
        end if;

      when S_ANG_LINK_OK =>

          i_ang_done<='1';
          i_xmit<=CONV_STD_LOGIC_VECTOR(C_PCS_XMIT_DATA, i_xmit'length);
          fsm_ang_cs <= S_ANG_LINK_OK;

    end case;
  end if;
end process;

--END MAIN
end behavioral;

