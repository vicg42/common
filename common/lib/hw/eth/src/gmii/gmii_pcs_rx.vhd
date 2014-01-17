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
--
--------------------------------------
p_out_rxcfg             : out   std_logic_vector(15 downto 0);
p_out_rxcfg_en          : out   std_logic;
p_in_xmit               : in    std_logic_vector(3 downto 0);

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
p_out_tst               : out   std_logic_vector(39 downto 0);

--------------------------------------
--SYSTEM
--------------------------------------
p_in_clk                : in    std_logic;
p_in_rst                : in    std_logic
);
end gmii_pcs_rx;

architecture behavioral of gmii_pcs_rx is

type fsm_sync_state is (
S_SYNC_LOSS      ,
S_SYNC_COMMA_DET1,
S_SYNC_ACQUIRE1  ,
S_SYNC_COMMA_DET2,
S_SYNC_ACQUIRE2  ,
S_SYNC_COMMA_DET3,

S_SYNC_ACQUIRED1 ,
S_SYNC_ACQUIRED2 ,
S_SYNC_ACQUIRED3 ,
S_SYNC_ACQUIRED4 ,

S_SYNC_ACQUIRED2A,
S_SYNC_ACQUIRED3A,
S_SYNC_ACQUIRED4A
);
signal fsm_sync_cs : fsm_sync_state;

type fsm_rx_state is (
S_RX_WAIT   ,
S_RX_K      ,

S_RX_CB     ,
S_RX_CC     ,
S_RX_CD     ,

S_RX_IDLE_D ,
S_RX_CRS_DET,
S_RX_CRS_ERR,

S_RX_RCV    ,
S_RX_END_EXT,
S_RX_TRI    ,

S_RX_CHK_END,
S_RX_PKT_RRS,
S_RX_END_ERR,

S_RX_INVALID
);
signal fsm_rx_cs : fsm_rx_state;

signal i_tmr_rst           : std_logic_vector(1 downto 0);
signal i_tmr_rst_en        : std_logic;

signal i_gt_rxbufreset     : std_logic;

signal i_status            : std_logic_vector(C_PCS_RxSTAT_LAST_BIT downto 0):=(others=>'0');

type TSrRxD is array (2 downto 0) of std_logic_vector(7 downto 0);
type TSrRx is array (1 downto 0) of std_logic_vector(7 downto 0);
signal sr_rx_d             : TSrRx;
signal sr_rx_dtype         : std_logic_vector(1 downto 0);

type TPCS_Rx is record
d : TSrRxD;
k : std_logic_vector(2 downto 0);
comma : std_logic;
end record;
signal i_rx                : TPCS_Rx;
signal i_rx_even           : std_logic;
signal i_good_cgs          : std_logic_vector(2 downto 0):=(others=>'0');

signal i_crs               : std_logic;
signal i_rcv               : std_logic;
signal i_regcfg            : std_logic_vector(15 downto 0);
signal i_regcfg_en         : std_logic;
type TGMII_Rx is record
d  : std_logic_vector(7 downto 0);
dv : std_logic;
er : std_logic;
end record;
signal i_gmii_rx           : TGMII_Rx;

signal tst_fsm_sync_cs     : std_logic_vector(4 downto 0):=(others=>'0');
signal tst_fsm_rx_cs       : std_logic_vector(4 downto 0):=(others=>'0');


--MAIN
begin

--//----------------------------------
--//Технологические сигналы
--//----------------------------------
gen_dbg_off : if strcmp(G_DBG,"OFF") generate
p_out_tst(31 downto 0)<=(others=>'0');
end generate gen_dbg_off;

gen_dbg_on : if strcmp(G_DBG,"ON") generate

p_out_tst(4 downto 0)<=tst_fsm_sync_cs;
p_out_tst(9 downto 5)<=tst_fsm_rx_cs;
p_out_tst(10)<=i_rx_even;
p_out_tst(11)<='0';
p_out_tst(15 downto 12)<=i_rx.k;
p_out_tst(23 downto 16)<=i_rx.d(0);
p_out_tst(31 downto 24)<=i_rx.d(1);
p_out_tst(39 downto 32)<=i_rx.d(2);

tst_fsm_sync_cs<=CONV_STD_LOGIC_VECTOR(16#01#,tst_fsm_sync_cs'length) when fsm_sync_cs=S_SYNC_COMMA_DET1    else
                 CONV_STD_LOGIC_VECTOR(16#02#,tst_fsm_sync_cs'length) when fsm_sync_cs=S_SYNC_ACQUIRE1      else
                 CONV_STD_LOGIC_VECTOR(16#03#,tst_fsm_sync_cs'length) when fsm_sync_cs=S_SYNC_COMMA_DET2    else
                 CONV_STD_LOGIC_VECTOR(16#04#,tst_fsm_sync_cs'length) when fsm_sync_cs=S_SYNC_ACQUIRE2      else
                 CONV_STD_LOGIC_VECTOR(16#05#,tst_fsm_sync_cs'length) when fsm_sync_cs=S_SYNC_COMMA_DET3    else
                 CONV_STD_LOGIC_VECTOR(16#06#,tst_fsm_sync_cs'length) when fsm_sync_cs=S_SYNC_ACQUIRED1     else
                 CONV_STD_LOGIC_VECTOR(16#07#,tst_fsm_sync_cs'length) when fsm_sync_cs=S_SYNC_ACQUIRED2     else
                 CONV_STD_LOGIC_VECTOR(16#08#,tst_fsm_sync_cs'length) when fsm_sync_cs=S_SYNC_ACQUIRED3     else
                 CONV_STD_LOGIC_VECTOR(16#09#,tst_fsm_sync_cs'length) when fsm_sync_cs=S_SYNC_ACQUIRED4     else
                 CONV_STD_LOGIC_VECTOR(16#0A#,tst_fsm_sync_cs'length) when fsm_sync_cs=S_SYNC_ACQUIRED2A    else
                 CONV_STD_LOGIC_VECTOR(16#0B#,tst_fsm_sync_cs'length) when fsm_sync_cs=S_SYNC_ACQUIRED3A    else
                 CONV_STD_LOGIC_VECTOR(16#0C#,tst_fsm_sync_cs'length) when fsm_sync_cs=S_SYNC_ACQUIRED4A    else
                 CONV_STD_LOGIC_VECTOR(16#00#,tst_fsm_sync_cs'length);-- when fsm_sync_cs=S_SYNC_LOSS          else

tst_fsm_rx_cs<=CONV_STD_LOGIC_VECTOR(16#01#,tst_fsm_rx_cs'length) when fsm_rx_cs=S_RX_K           else
               CONV_STD_LOGIC_VECTOR(16#02#,tst_fsm_rx_cs'length) when fsm_rx_cs=S_RX_CB          else
               CONV_STD_LOGIC_VECTOR(16#03#,tst_fsm_rx_cs'length) when fsm_rx_cs=S_RX_CC          else
               CONV_STD_LOGIC_VECTOR(16#04#,tst_fsm_rx_cs'length) when fsm_rx_cs=S_RX_CD          else
               CONV_STD_LOGIC_VECTOR(16#05#,tst_fsm_rx_cs'length) when fsm_rx_cs=S_RX_IDLE_D      else
               CONV_STD_LOGIC_VECTOR(16#06#,tst_fsm_rx_cs'length) when fsm_rx_cs=S_RX_CRS_DET     else
               CONV_STD_LOGIC_VECTOR(16#07#,tst_fsm_rx_cs'length) when fsm_rx_cs=S_RX_CRS_ERR     else
               CONV_STD_LOGIC_VECTOR(16#08#,tst_fsm_rx_cs'length) when fsm_rx_cs=S_RX_RCV         else
               CONV_STD_LOGIC_VECTOR(16#09#,tst_fsm_rx_cs'length) when fsm_rx_cs=S_RX_END_EXT     else
               CONV_STD_LOGIC_VECTOR(16#0A#,tst_fsm_rx_cs'length) when fsm_rx_cs=S_RX_TRI         else
               CONV_STD_LOGIC_VECTOR(16#0B#,tst_fsm_rx_cs'length) when fsm_rx_cs=S_RX_CHK_END     else
               CONV_STD_LOGIC_VECTOR(16#0C#,tst_fsm_rx_cs'length) when fsm_rx_cs=S_RX_PKT_RRS     else
               CONV_STD_LOGIC_VECTOR(16#0D#,tst_fsm_rx_cs'length) when fsm_rx_cs=S_RX_END_ERR     else
               CONV_STD_LOGIC_VECTOR(16#0E#,tst_fsm_rx_cs'length) when fsm_rx_cs=S_RX_INVALID     else
               CONV_STD_LOGIC_VECTOR(16#00#,tst_fsm_rx_cs'length);-- when fsm_rc_cs=S_RX_WAIT      else

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
p_out_rxd   <=i_gmii_rx.d;
p_out_rx_dv <=i_gmii_rx.dv;
p_out_rx_er <=i_gmii_rx.er;
p_out_rx_crs<=i_crs;

p_out_rxcfg <=i_regcfg;
p_out_rxcfg_en <=i_regcfg_en;


--//#########################################
--//Synchronization - FSM
--//(см. пп 36.2.5.2.6 IEEE_Std_802.3-2005_section3.pdf)
--//#########################################
process(p_in_clk)
begin
  if p_in_clk'event and p_in_clk='1' then
    sr_rx_d<=sr_rx_d(0 downto 0) & p_in_gt_rxdata(7 downto 0);
    sr_rx_dtype<=sr_rx_dtype(0 downto 0) & p_in_gt_rxcharisk(0);
  end if;
end process;

i_rx.comma<='1' when p_in_gt_rxcharisk(0)=C_CHAR_K and ( p_in_gt_rxdata(7 downto 0)=C_K28_5 or
                                                         p_in_gt_rxdata(7 downto 0)=C_K28_1 or
                                                         p_in_gt_rxdata(7 downto 0)=C_K28_7 ) else '0';

i_rx.d(0)<=p_in_gt_rxdata(7 downto 0);
i_rx.d(1)<=sr_rx_d(0);
i_rx.d(2)<=sr_rx_d(1);
i_rx.k(0)<=p_in_gt_rxcharisk(0);
i_rx.k(1)<=sr_rx_dtype(0);
i_rx.k(2)<=sr_rx_dtype(1);

process(p_in_rst,p_in_clk)
begin
  if p_in_rst='1' then
    fsm_sync_cs <= S_SYNC_LOSS;
    i_rx_even<='0';
    i_status(C_PCS_RxSTAT_SYNC)<='0';
    i_good_cgs<=(others=>'0');

  elsif p_in_clk'event and p_in_clk='1' then

    case fsm_sync_cs is
      --------------------------------------
      --
      --------------------------------------
      when S_SYNC_LOSS =>

        i_rx_even<=not i_rx_even;
        i_status(C_PCS_RxSTAT_SYNC)<='0';--fail
        i_good_cgs<=(others=>'0');

        if i_rx.comma='1' then
          fsm_sync_cs <= S_SYNC_COMMA_DET1;
        end if;

      --------------------------------------
      --
      --------------------------------------
      when S_SYNC_COMMA_DET1 =>

        i_rx_even<='1';

        if i_rx.k(0)=C_CHAR_D then
          fsm_sync_cs <= S_SYNC_ACQUIRE1;
        else
          fsm_sync_cs <= S_SYNC_LOSS;
        end if;

      --------------------------------------
      --
      --------------------------------------
      when S_SYNC_ACQUIRE1 =>

        i_rx_even<=not i_rx_even;

        if i_rx.comma='1' then
          if i_rx_even='1' then
            fsm_sync_cs <= S_SYNC_COMMA_DET2;--cggood
          else
            fsm_sync_cs <= S_SYNC_LOSS;--cgbad
          end if;
        end if;

      --------------------------------------
      --
      --------------------------------------
      when S_SYNC_COMMA_DET2 =>

        i_rx_even<='1';

        if i_rx.k(0)=C_CHAR_D then
          fsm_sync_cs <= S_SYNC_ACQUIRE2;
        else
          fsm_sync_cs <= S_SYNC_LOSS;
        end if;

      --------------------------------------
      --
      --------------------------------------
      when S_SYNC_ACQUIRE2 =>

        i_rx_even<=not i_rx_even;

        if i_rx.comma='1' then
          if i_rx_even='1' then
            fsm_sync_cs <= S_SYNC_COMMA_DET3;--cggood
          else
            fsm_sync_cs <= S_SYNC_LOSS;--cgbad
          end if;
        end if;

      --------------------------------------
      --
      --------------------------------------
      when S_SYNC_COMMA_DET3 =>

        i_rx_even<='1';

        if i_rx.k(0)=C_CHAR_D then
          fsm_sync_cs <= S_SYNC_ACQUIRED1;
        else
          fsm_sync_cs <= S_SYNC_LOSS;
        end if;



      --------------------------------------
      --
      --------------------------------------
      when S_SYNC_ACQUIRED1 =>

        i_rx_even<=not i_rx_even;
        i_status(C_PCS_RxSTAT_SYNC)<='1';--OK

        if i_rx.comma='1' then
          if i_rx_even='1' then
            fsm_sync_cs <= S_SYNC_ACQUIRED1;--cggood
          else
            fsm_sync_cs <= S_SYNC_ACQUIRED2;--cgbad
          end if;
        end if;

      --------------------------------------
      --
      --------------------------------------
      when S_SYNC_ACQUIRED2 =>

        i_rx_even<=not i_rx_even;
        i_good_cgs<=(others=>'0');

        if i_rx.comma='1' then
          if i_rx_even='1' then
            fsm_sync_cs <= S_SYNC_ACQUIRED2A;--cggood
          else
            fsm_sync_cs <= S_SYNC_ACQUIRED2;--cgbad
          end if;
        end if;

      when S_SYNC_ACQUIRED2A =>

        i_rx_even<=not i_rx_even;
        i_good_cgs<=i_good_cgs + 1;

        if i_rx.comma='1' then
          if i_rx_even='1' then
            if i_good_cgs=CONV_STD_LOGIC_VECTOR(3, i_good_cgs'length) then
              fsm_sync_cs <= S_SYNC_ACQUIRED1;
            else
              fsm_sync_cs <= S_SYNC_ACQUIRED2A;--cggood
            end if;
          else
            fsm_sync_cs <= S_SYNC_ACQUIRED3;--cgbad
          end if;
        end if;

      --------------------------------------
      --
      --------------------------------------
      when S_SYNC_ACQUIRED3 =>

        i_rx_even<=not i_rx_even;
        i_good_cgs<=(others=>'0');

        if i_rx.comma='1' then
          if i_rx_even='1' then
            fsm_sync_cs <= S_SYNC_ACQUIRED3A;--cggood
          else
            fsm_sync_cs <= S_SYNC_ACQUIRED4;--cgbad
          end if;
        end if;

      when S_SYNC_ACQUIRED3A =>

        i_rx_even<=not i_rx_even;
        i_good_cgs<=i_good_cgs + 1;

        if i_rx.comma='1' then
          if i_rx_even='1' then
            if i_good_cgs=CONV_STD_LOGIC_VECTOR(3, i_good_cgs'length) then
              fsm_sync_cs <= S_SYNC_ACQUIRED2;
            else
              fsm_sync_cs <= S_SYNC_ACQUIRED3A;--cggood
            end if;
          else
            fsm_sync_cs <= S_SYNC_ACQUIRED4;--cgbad
          end if;
        end if;

      --------------------------------------
      --
      --------------------------------------
      when S_SYNC_ACQUIRED4 =>

        i_rx_even<=not i_rx_even;
        i_good_cgs<=(others=>'0');

        if i_rx.comma='1' then
          if i_rx_even='1' then
            fsm_sync_cs <= S_SYNC_ACQUIRED4A;--cggood
          else
            fsm_sync_cs <= S_SYNC_LOSS;--cgbad
          end if;
        end if;

      when S_SYNC_ACQUIRED4A =>

        i_rx_even<=not i_rx_even;
        i_good_cgs<=i_good_cgs + 1;

        if i_rx.comma='1' then
          if i_rx_even='1' then
            if i_good_cgs=CONV_STD_LOGIC_VECTOR(3, i_good_cgs'length) then
              fsm_sync_cs <= S_SYNC_ACQUIRED3;
            else
              fsm_sync_cs <= S_SYNC_ACQUIRED4A;--cggood
            end if;
          else
            fsm_sync_cs <= S_SYNC_LOSS;--cgbad
          end if;
        end if;

    end case;

  end if;
end process;


--//#########################################
--//PCS receive - FSM
--//(см. пп 36.2.5.2.2 IEEE_Std_802.3-2005_section3.pdf)
--//#########################################
process(p_in_rst,p_in_clk)
begin
  if p_in_rst='1' then

    fsm_rx_cs <= S_RX_WAIT;
    i_regcfg<=(others=>'0');
    i_regcfg_en<='0';
    i_rcv <='0';
    i_crs <='0';
    i_gmii_rx.d  <=(others=>'0');
    i_gmii_rx.dv <='0';
    i_gmii_rx.er <='0';

  elsif p_in_clk'event and p_in_clk='1' then

    case fsm_rx_cs is
      --------------------------------------
      --
      --------------------------------------
      when S_RX_WAIT =>

        i_rcv <='0';
        i_gmii_rx.d  <=(others=>'0');
        i_gmii_rx.dv <='0';
        i_gmii_rx.er <='0';

        if i_rx.k(0)=C_CHAR_K and i_rx.d(0)=C_K28_5 then--and i_rx_even='1' then
          fsm_rx_cs <= S_RX_K;
        end if;

      when S_RX_K =>

        i_rcv <='0';
        i_gmii_rx.d  <=(others=>'0');
        i_gmii_rx.dv <='0';
        i_gmii_rx.er <='0';

        if i_rx.k(0)=C_CHAR_D then
          if (i_rx.d(0)=C_D21_5 or i_rx.d(0)=C_D2_2) then
          --Configuration
            fsm_rx_cs <= S_RX_CB;
          else
            fsm_rx_cs <= S_RX_IDLE_D;
          end if;

        elsif p_in_xmit/=CONV_STD_LOGIC_VECTOR(C_PCS_XMIT_DATA, p_in_xmit'length) and i_rx.k(0)=C_CHAR_K then
          fsm_rx_cs <= S_RX_INVALID;
        end if;


      --------------------------------------
      --Receive configuration
      --------------------------------------
      when S_RX_CB =>

        i_rcv <='0';
        i_gmii_rx.d  <=(others=>'0');
        i_gmii_rx.dv <='0';
        i_gmii_rx.er <='0';

        if i_rx.k(0)=C_CHAR_D then
          i_regcfg(7 downto 0)<=i_rx.d(0);
          fsm_rx_cs <= S_RX_CC;
        end if;

      when S_RX_CC =>

        if i_rx.k(0)=C_CHAR_D then
          i_regcfg(15 downto 8)<=i_rx.d(0);
          i_regcfg_en<='1';
          fsm_rx_cs <= S_RX_CD;
        end if;

      when S_RX_CD =>

        i_regcfg_en<='0';
        if i_rx_even='1' and i_rx.k(0)=C_CHAR_K and i_rx.d(0)=C_K28_5 then
          fsm_rx_cs <= S_RX_K;
        else
          fsm_rx_cs <= S_RX_INVALID;
        end if;


      --------------------------------------
      --
      --------------------------------------
      when S_RX_INVALID =>

        i_rcv <='0';
        i_gmii_rx.d  <=(others=>'0');
        i_gmii_rx.dv <='0';
        i_gmii_rx.er <='0';

        if i_rx_even='1' then
          if i_rx.k(0)=C_CHAR_K and i_rx.d(0)=C_K28_5 then
            fsm_rx_cs <= S_RX_K;
          else
            fsm_rx_cs <= S_RX_WAIT;
          end if;
        end if;


      --------------------------------------
      --
      --------------------------------------
      when S_RX_IDLE_D =>

        i_rcv <='0';
        i_gmii_rx.d  <=(others=>'0');
        i_gmii_rx.dv <='0';
        i_gmii_rx.er <='0';

        if i_rx.k(0)=C_CHAR_K and i_rx.d(0)=C_K28_5 then
--          if i_rx_even='1' then
            if i_crs='1' then
              fsm_rx_cs <= S_RX_CRS_DET;
            else
              i_crs<='1';
              fsm_rx_cs <= S_RX_K;
            end if;
--          end if;

        elsif p_in_xmit/=CONV_STD_LOGIC_VECTOR(C_PCS_XMIT_DATA, p_in_xmit'length) then
          fsm_rx_cs <= S_RX_INVALID;

        end if;

      when S_RX_CRS_DET =>

        i_rcv <='1';

        if i_rx.k(2)=C_CHAR_K and i_rx.d(2)=C_PDAT_S then
          i_gmii_rx.d  <="01010101";
          i_gmii_rx.dv <='1';
          i_gmii_rx.er <='0';
          fsm_rx_cs <= S_RX_RCV;
        else
          fsm_rx_cs <= S_RX_CRS_ERR;
        end if;

      when S_RX_CRS_ERR =>

        i_gmii_rx.d  <="00001110";
        i_gmii_rx.er <='1';

        if i_rx.k(0)=C_CHAR_K and i_rx.d(0)=C_K28_5 then --and i_rx_even='1' then
          fsm_rx_cs <= S_RX_K;
        end if;

      --------------------------------------
      --
      --------------------------------------
      when S_RX_RCV =>

          if ((i_rx.k(2)=C_CHAR_K and i_rx.k(1)=C_CHAR_D and i_rx.k(0)=C_CHAR_K  and
                   i_rx.d(2)=C_K28_5                             and     i_rx.d(0)=C_K28_5) or

              (i_rx.k(2)=C_CHAR_K and i_rx.k(1)=C_CHAR_D and i_rx.k(0)=C_CHAR_D and
                   i_rx.d(2)=C_K28_5  and     i_rx.d(1)=C_D21_5  and     i_rx.d(0)=C_D0_0 ) or

              (i_rx.k(2)=C_CHAR_K and i_rx.k(1)=C_CHAR_D and i_rx.k(0)=C_CHAR_D and
                   i_rx.d(2)=C_K28_5  and     i_rx.d(1)=C_D2_2   and     i_rx.d(0)=C_D0_0 )) then --and i_rx_even='1' then

            i_gmii_rx.er <='1';
            fsm_rx_cs <= S_RX_END_EXT;


          elsif i_rx.k(2)=C_CHAR_K and i_rx.k(1)=C_CHAR_K and i_rx.k(0)=C_CHAR_K and
                    i_rx.d(2)=C_PDAT_T and     i_rx.d(1)=C_PDAT_R and     i_rx.d(0)=C_K28_5 then --and i_rx_even='1' then

            i_rcv <='0';
            i_gmii_rx.dv <='0';
            i_gmii_rx.er <='0';
            fsm_rx_cs <= S_RX_TRI;


          elsif i_rx.k(2)=C_CHAR_K and i_rx.k(1)=C_CHAR_K and i_rx.k(0)=C_CHAR_K and
                    i_rx.d(2)=C_PDAT_T and     i_rx.d(1)=C_PDAT_R and     i_rx.d(0)=C_PDAT_R then --and i_rx_even='1' then

            i_gmii_rx.d  <="00001111";
            i_gmii_rx.dv <='0';
            i_gmii_rx.er <='1';
            fsm_rx_cs <= S_RX_CHK_END;--S_RX_TRR;


          elsif i_rx.k(2)=C_CHAR_K and i_rx.k(1)=C_CHAR_K and i_rx.k(0)=C_CHAR_K and
                    i_rx.d(2)=C_PDAT_R and     i_rx.d(1)=C_PDAT_R and     i_rx.d(0)=C_PDAT_R then --and i_rx_even='1' then

            i_gmii_rx.er <='1';
            fsm_rx_cs <= S_RX_CHK_END;--S_RX_EARLY_END_EXT;

          elsif i_rx.k(0) = C_CHAR_D then

            i_gmii_rx.d  <=i_rx.d(0);
            i_gmii_rx.er <='0';
            fsm_rx_cs <= S_RX_RCV;--S_RX_DATA;

          else

            i_gmii_rx.er <='1';
            fsm_rx_cs <= S_RX_RCV;--S_RX_DATA_ERR;

          end if;--//when S_RX_RCV


      when S_RX_END_EXT =>

          if i_rx.k(2)=C_CHAR_K and (i_rx.d(2)=C_D21_5 or i_rx.d(2)=C_D2_2) then
            fsm_rx_cs <= S_RX_CB;
          else
            fsm_rx_cs <= S_RX_IDLE_D;
          end if;

      when S_RX_TRI =>

          if i_rx.k(2)=C_CHAR_K and i_rx.d(2)=C_K28_5 then
            fsm_rx_cs <= S_RX_K;
          end if;

      when S_RX_CHK_END =>

          if    i_rx.k(2)=C_CHAR_K and i_rx.k(1)=C_CHAR_K and i_rx.k(0)=C_CHAR_K and
                    i_rx.d(2)=C_PDAT_R and     i_rx.d(1)=C_PDAT_R and     i_rx.d(0)=C_PDAT_R then

            i_gmii_rx.d  <="00001111";
            i_gmii_rx.dv <='0';
            i_gmii_rx.er <='1';
            fsm_rx_cs <= S_RX_CHK_END;

          elsif i_rx.k(2)=C_CHAR_K and i_rx.k(1)=C_CHAR_K and i_rx.k(0)=C_CHAR_K and
                    i_rx.d(2)=C_PDAT_R and     i_rx.d(1)=C_PDAT_R and     i_rx.d(0)=C_K28_5 then --and i_rx_even='1' then

            fsm_rx_cs <= S_RX_TRI;

          elsif i_rx.k(2)=C_CHAR_K and i_rx.k(1)=C_CHAR_K and i_rx.k(0)=C_CHAR_K and
                    i_rx.d(2)=C_PDAT_R and     i_rx.d(1)=C_PDAT_R and     i_rx.d(0)=C_PDAT_S  then

            i_gmii_rx.d  <="00001111";
            i_gmii_rx.dv <='0';
            fsm_rx_cs <= S_RX_PKT_RRS;

          else
            fsm_rx_cs <= S_RX_END_ERR;
          end if;

      when S_RX_PKT_RRS =>

          if i_rx.k(2)=C_CHAR_K and i_rx.d(2)=C_PDAT_S then
            i_gmii_rx.d  <="01010101";
            i_gmii_rx.dv <='1';
            i_gmii_rx.er <='0';
            fsm_rx_cs <= S_RX_RCV;
--            fsm_rx_cs <= S_RX_SOP;
          end if;

      when S_RX_END_ERR =>

          if i_rx.k(2)=C_CHAR_K and i_rx.d(2)=C_PDAT_S then
            i_gmii_rx.d  <="01010101";
            i_gmii_rx.dv <='1';
            i_gmii_rx.er <='0';
            fsm_rx_cs <= S_RX_RCV;
--            fsm_rx_cs <= S_RX_SOP;

          elsif i_rx.k(2)=C_CHAR_K and i_rx.d(2)=C_K28_5 then
            fsm_rx_cs <= S_RX_K;

          else
            fsm_rx_cs <= S_RX_CHK_END;
          end if;

    end case;

  end if;
end process;

--END MAIN
end behavioral;

