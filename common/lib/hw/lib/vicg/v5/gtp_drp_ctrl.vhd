-------------------------------------------------------------------------
-- Company     : Linkos
-- Engineer    : Golovachenko Victor
--
-- Create Date : 03/04/2010
-- Module Name : gtp_drp_ctrl
--
-- Назначение/Описание : Перепрограммирование GTP, а именно мультиплексора CLKIN - выбро источника опорной частоты
--                       для RocketIO + перепрограммирование ветвления опорной частоты поданой на диф. p_in_clk соотв. GTP
--
--//Bit map порта p_in_usr_ctrl:
--constant C_USRCTLR_GTP_CLKIN_MUX_VLSB_BIT  : integer:=8;  --//Значение для перепрограм. мультиплексора CLKIN RocketIO ETH
--constant C_USRCTLR_GTP_CLKIN_MUX_VMSB_BIT  : integer:=10; --//
--constant C_USRCTLR_GTP_SOUTH_MUX_VAL_BIT   : integer:=11; --//Значение для перепрограм. мультиплексора CLKSOUTH RocketIO ETH
--constant C_USRCTLR_GTP_NORTH_MUX_VAL_BIT   : integer:=12; --//Значение для перепрограм. мультиплексора CLKNORTH RocketIO ETH
--constant C_USRCTLR_GTP_CLKIN_MUX_CNG_BIT   : integer:=13; --//1- перепрограммирование мультиплексора CLKIN RocketIO ETH
--constant C_USRCTLR_GTP_SOUTH_MUX_CNG_BIT   : integer:=14; --//1- перепрограммирование мультиплексора CLKSOUTH RocketIO ETH
--constant C_USRCTLR_GTP_NORTH_MUX_CNG_BIT   : integer:=15; --//1- перепрограммирование мультиплексора CLKNORTH RocketIO ETH
--
-- Revision:
-- Revision 0.01 - File Created
--
-------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

use work.v5_gt_pkg.all;

library unisim;
use unisim.vcomponents.all;

entity gtp_drp_ctrl is
generic(
G_USE_USRCTLR      : integer   :=  0; --//1/0 -  управления модулем от порта p_in_usr_ctrl/ управление модулем от значений из generic

G_CLKIN_CHANGE     : std_logic := '0';--//'1'/'0' - разрешение/запрет изменения состояния мультиплексора CLKIN
G_CLKSOUTH_CHANGE  : std_logic := '0';--//'1'/'0' - разрешение/запрет изменения состояния мультиплексора CLKSOUTH
G_CLKNORTH_CHANGE  : std_logic := '0';--//'1'/'0' - разрешение/запрет изменения состояния мультиплексора CLKNORTH

G_CLKIN_MUX_VAL    : std_logic_vector(2 downto 0):="011"; --//Значение для мультиплексора CLKIN
G_CLKSOUTH_MUX_VAL : std_logic := '0';                    --//Значение для мультиплексора CLKSOUTH
G_CLKNORTH_MUX_VAL : std_logic := '0'                     --//Значение для мультиплексора CLKNORTH
);
port(
p_in_usr_ctrl     : in    std_logic_vector(31 downto 0):="00000000000000000000000000011011";

--------------------------------------------------
--RocketIO
--------------------------------------------------
p_out_gtp_drpclk  : out   std_logic;
p_out_gtp_drpaddr : out   std_logic_vector(6 downto 0);--Dynamic Reconfiguration Port (DRP)
p_out_gtp_drpen   : out   std_logic;
p_out_gtp_drpwe   : out   std_logic;
p_out_gtp_drpdi   : out   std_logic_vector(15 downto 0);
p_in_gtp_drpdo    : in    std_logic_vector(15 downto 0);
p_in_gtp_drprdy   : in    std_logic;

p_out_gtp_rst     : out   std_logic;

--------------------------------------------------
--Технологические сигналы
--------------------------------------------------
p_out_tst         : out   std_logic_vector(31 downto 0);

--------------------------------------------------
--SYSTEM
--------------------------------------------------
p_in_clk          : in    std_logic;--
p_in_rst          : in    std_logic --
);
end gtp_drp_ctrl;

architecture behavioral of gtp_drp_ctrl is

constant C_USRCTLR_GTP_CLKIN_MUX_VLSB_BIT  : integer:=C_V5GT_CLKIN_MUX_L_BIT  ;
constant C_USRCTLR_GTP_CLKIN_MUX_VMSB_BIT  : integer:=C_V5GT_CLKIN_MUX_M_BIT  ;
constant C_USRCTLR_GTP_SOUTH_MUX_VAL_BIT   : integer:=C_V5GT_SOUTH_MUX_VAL_BIT;
constant C_USRCTLR_GTP_NORTH_MUX_VAL_BIT   : integer:=C_V5GT_NORTH_MUX_VAL_BIT;
constant C_USRCTLR_GTP_CLKIN_MUX_CNG_BIT   : integer:=C_V5GT_CLKIN_MUX_CNG_BIT;
constant C_USRCTLR_GTP_SOUTH_MUX_CNG_BIT   : integer:=C_V5GT_SOUTH_MUX_CNG_BIT;
constant C_USRCTLR_GTP_NORTH_MUX_CNG_BIT   : integer:=C_V5GT_NORTH_MUX_CNG_BIT;

--//Адреса регистров порта DRP компонента DUAL_GTP
--//более подробно см.Appendix D/ug196_Virtex-5 FPGA RocketIO GTP Transceiver User Guide.pdf
constant C_ADR_REFCLK_SEL        : std_logic_vector(6 downto 0):=CONV_STD_LOGIC_VECTOR(16#04#, 7);

constant C_CLKIN_CHANGE     : std_logic :=G_CLKIN_CHANGE;
constant C_CLKSOUTH_CHANGE  : std_logic :=G_CLKSOUTH_CHANGE;
constant C_CLKNORTH_CHANGE  : std_logic :=G_CLKNORTH_CHANGE;

constant C_CLKIN_MUX_VAL    : std_logic_vector(2 downto 0):=G_CLKIN_MUX_VAL;
constant C_CLKSOUTH_MUX_VAL : std_logic :=G_CLKSOUTH_MUX_VAL;
constant C_CLKNORTH_MUX_VAL : std_logic :=G_CLKNORTH_MUX_VAL;

type fsm_drp_ctrl is (
S_PROG_CLOCK_MUX,

--//-------------------------------------------
--//Программирование CLOCK MUX компонента DUAL_GTP
--//-------------------------------------------
S_DRP_READ,
S_DRP_READ_DONE,
S_DRP_READ_PAUSE,
S_DRP_WRITE,
S_DRP_WRITE_DONE,
S_DRP_WRITE_PAUSE,
S_GTP_RESET,

S_1DONE,
S_DRP_1READ,
S_DRP_1READ_DONE,
S_DRP_1READ_PAUSE,

S_DONE
);
signal fsm_drp_ctrl_cs: fsm_drp_ctrl;

signal val_clkin_mux            : std_logic_vector(2 downto 0);
signal val_clksouth_mux         : std_logic;
signal val_clknorth_mux         : std_logic;

signal change_clkin_mux         : std_logic;
signal change_clksouth_mux      : std_logic;
signal change_clknorth_mux      : std_logic;

signal i_gtp_rst                : std_logic;

signal i_gtp_drpaddr            : std_logic_vector(6 downto 0);
signal i_gtp_drpen              : std_logic;
signal i_gtp_drpwe              : std_logic;
signal i_gtp_drpdi              : std_logic_vector(15 downto 0);
signal i_gtp_drpdo              : std_logic_vector(15 downto 0);
signal i_gtp_drprdy             : std_logic;

signal i_gtp_drp_read_val       : std_logic_vector(15 downto 0);

signal i_timer                  : std_logic_vector(4 downto 0);

--signal tst_gtp_drpen            : std_logic;
--signal tst_gtp_drpwe            : std_logic;
--signal tst_gtp_drprdy           : std_logic;


--MAIN
begin


--//----------------------------------
--//Технологические сигналы
--//----------------------------------
p_out_tst(31 downto 0)<=(others=>'0');
--process(p_in_rst,p_in_clk)
--begin
--  if p_in_rst='1' then
--    tst_gtp_drpen<='0';
--    tst_gtp_drpwe<='0';
--    tst_gtp_drprdy<='0';
--
--  elsif p_in_clk'event and p_in_clk='1' then
--    tst_gtp_drpen<= i_gtp_drpen;
--    tst_gtp_drpwe<= i_gtp_drpwe;
--    tst_gtp_drprdy<= i_gtp_drprdy;
--  end if;
--end process;
--p_out_tst(0)<=tst_gtp_drpen or tst_gtp_drpwe or tst_gtp_drprdy;
--p_out_tst(31 downto 1)<=(others=>'0');



gen_use_usrctrl_on: if G_USE_USRCTLR=1 generate
  val_clkin_mux      <=p_in_usr_ctrl(C_USRCTLR_GTP_CLKIN_MUX_VMSB_BIT downto C_USRCTLR_GTP_CLKIN_MUX_VLSB_BIT);
  val_clksouth_mux   <=p_in_usr_ctrl(C_USRCTLR_GTP_SOUTH_MUX_VAL_BIT);
  val_clknorth_mux   <=p_in_usr_ctrl(C_USRCTLR_GTP_NORTH_MUX_VAL_BIT);

  change_clkin_mux   <=p_in_usr_ctrl(C_USRCTLR_GTP_CLKIN_MUX_CNG_BIT);
  change_clksouth_mux<=p_in_usr_ctrl(C_USRCTLR_GTP_SOUTH_MUX_CNG_BIT);
  change_clknorth_mux<=p_in_usr_ctrl(C_USRCTLR_GTP_NORTH_MUX_CNG_BIT);
end generate gen_use_usrctrl_on;

gen_use_usrctrl_off: if G_USE_USRCTLR=0 generate
  val_clkin_mux      <=C_CLKIN_MUX_VAL;
  val_clksouth_mux   <=C_CLKSOUTH_MUX_VAL;
  val_clknorth_mux   <=C_CLKNORTH_MUX_VAL;

  change_clkin_mux   <=C_CLKIN_CHANGE;
  change_clksouth_mux<=C_CLKSOUTH_CHANGE;
  change_clknorth_mux<=C_CLKNORTH_CHANGE;
end generate gen_use_usrctrl_off;

p_out_gtp_rst     <= i_gtp_rst;

p_out_gtp_drpclk  <= p_in_clk;
p_out_gtp_drpaddr <= i_gtp_drpaddr;
p_out_gtp_drpen   <= i_gtp_drpen;
p_out_gtp_drpwe   <= i_gtp_drpwe;
p_out_gtp_drpdi   <= i_gtp_drpdi;
i_gtp_drpdo       <= p_in_gtp_drpdo;
i_gtp_drprdy      <= p_in_gtp_drprdy;

--//--------------------------------------------------
--//Автомат управления программированием регистров порта DPR DUAL_GTP
--//--------------------------------------------------
process(p_in_rst,p_in_clk)
begin

if p_in_rst='1' then

  i_gtp_drp_read_val<=(others=>'0');

  fsm_drp_ctrl_cs <= S_PROG_CLOCK_MUX;

  i_gtp_drpaddr <= (others=>'0');
  i_gtp_drpdi   <= (others=>'0');
  i_gtp_drpen   <= '0';
  i_gtp_drpwe   <= '0';

  i_timer <= (others=>'0');
  i_gtp_rst<='0';

elsif p_in_clk'event and p_in_clk='1' then
--  if clk_en='1' then

  case fsm_drp_ctrl_cs is

    when S_PROG_CLOCK_MUX =>

      if i_timer = CONV_STD_LOGIC_VECTOR(16#01F#, 5) then
        i_timer<=(others=>'0');
        fsm_drp_ctrl_cs <= S_DRP_READ;

      else
        i_timer<=i_timer + 1;
      end if;

    --//------------------------------------------
    --//Читаю значение региста C_ADR_REFCLK_SEL
    --//------------------------------------------
    when S_DRP_READ =>

      i_gtp_drpaddr<=C_ADR_REFCLK_SEL;
      i_gtp_drpen<='1';
      i_gtp_drpwe<='0';

      fsm_drp_ctrl_cs <= S_DRP_READ_DONE;

    when S_DRP_READ_DONE =>

      if i_gtp_drprdy='1' then
        i_gtp_drpen        <='0';
        i_gtp_drp_read_val <= i_gtp_drpdo;--//Сохраняю прочитаное заначение регистра DRP

        fsm_drp_ctrl_cs <= S_DRP_READ_PAUSE;
      end if;

    when S_DRP_READ_PAUSE =>

      if i_timer = CONV_STD_LOGIC_VECTOR(16#003#, 16) then
        i_timer<=(others=>'0');

        if change_clkin_mux='0' and change_clksouth_mux='0' and change_clknorth_mux='0' then
        --//Ни одно изменение не выбрано
        --//Выход.
          fsm_drp_ctrl_cs <= S_DONE;
        else
        --//Переходим к процессу программировния регистра REFCLK_SEL
          fsm_drp_ctrl_cs <= S_DRP_WRITE;
        end if;
      else
        i_timer<=i_timer + 1;
      end if;

    --//---------------------------------------------
    --//Изменяю значение региста C_ADR_REFCLK_SEL
    --//---------------------------------------------
    when S_DRP_WRITE =>

      i_gtp_drpaddr<=C_ADR_REFCLK_SEL;

      i_gtp_drpdi(3 downto 0) <= i_gtp_drp_read_val(3 downto 0);

      if change_clkin_mux='1' then
      --//Програмирую мультиплексор выбора источника опорной частоты для GTP
        i_gtp_drpdi(6) <= val_clkin_mux(0);
        i_gtp_drpdi(5) <= val_clkin_mux(1);
        i_gtp_drpdi(4) <= val_clkin_mux(2);
      else
        i_gtp_drpdi(6) <= i_gtp_drp_read_val(6);
        i_gtp_drpdi(5) <= i_gtp_drp_read_val(5);
        i_gtp_drpdi(4) <= i_gtp_drp_read_val(4);
      end if;

      if change_clksouth_mux='1' then
      --//Програмирую мультиплексор CLKSOUTH
        i_gtp_drpdi(7) <= val_clksouth_mux;
      else
        i_gtp_drpdi(7) <= i_gtp_drp_read_val(7);
      end if;

      if change_clknorth_mux='1' then
      --//Програмирую мультиплексор CLKNORTH
        i_gtp_drpdi(8) <= val_clknorth_mux;
      else
        i_gtp_drpdi(8) <= i_gtp_drp_read_val(8);
      end if;

      i_gtp_drpdi(15 downto 9) <= i_gtp_drp_read_val(15 downto 9);

      i_gtp_drpen <= '1';
      i_gtp_drpwe <= '1';
      fsm_drp_ctrl_cs <= S_DRP_WRITE_DONE;

    when S_DRP_WRITE_DONE =>

      if i_gtp_drprdy='1' then
        i_gtp_drpen <= '0';
        i_gtp_drpwe <= '0';

        fsm_drp_ctrl_cs <= S_DRP_WRITE_PAUSE;
      end if;

    when S_DRP_WRITE_PAUSE =>

      if i_timer = CONV_STD_LOGIC_VECTOR(16#003#, 16) then
        i_timer<=(others=>'0');
        fsm_drp_ctrl_cs <= S_GTP_RESET;
      else
        i_timer<=i_timer + 1;
      end if;

    --//-------------------------------------------
    --//Сброс DUAL_GTP
    --//-------------------------------------------
    when S_GTP_RESET =>

      i_gtp_drpaddr <= (others=>'0');
      i_gtp_drpdi   <= (others=>'0');
      i_gtp_drpen   <= '0';
      i_gtp_drpwe   <= '0';

      --//Генерю сброс для модуля RocketIO GTP и блоков sata_host
      if i_timer = CONV_STD_LOGIC_VECTOR(16#01F#, 5) then
        i_timer<=(others=>'0');
        i_gtp_rst<='0';--//Снимаю сигнал сброса
        fsm_drp_ctrl_cs <= S_1DONE;
--        fsm_drp_ctrl_cs <= S_DONE;

      elsif i_timer = CONV_STD_LOGIC_VECTOR(16#0F#, 5) then
        i_timer<=i_timer + 1;
        i_gtp_rst<='1';

      else
        i_timer<=i_timer + 1;
      end if;


    --//-------------------------------------------
    --//DONE configuration DUAL_GTP
    --//-------------------------------------------
    when S_1DONE =>
      i_gtp_rst<='0';

      --//Генерю сброс для модуля RocketIO GTP и блоков sata_host
      if i_timer = CONV_STD_LOGIC_VECTOR(16#01F#, 5) then
        i_timer<=(others=>'0');
        fsm_drp_ctrl_cs <= S_DRP_1READ;

      else
        i_timer<=i_timer + 1;
      end if;


    --//-------------------------------------------
    --//Программирую CLOCK MUX компонента DUAL_GTP
    --//-------------------------------------------
    --//Читаю значение региста C_ADR_REFCLK_SEL
    when S_DRP_1READ =>

      i_gtp_drpaddr<=C_ADR_REFCLK_SEL;
      i_gtp_drpen<='1';
      i_gtp_drpwe<='0';

      fsm_drp_ctrl_cs <= S_DRP_1READ_DONE;

    when S_DRP_1READ_DONE =>

      if i_gtp_drprdy='1' then
        i_gtp_drpen        <='0';
        i_gtp_drp_read_val <= i_gtp_drpdo;--//Сохраняю прочитаное заначение регистра DRP

        fsm_drp_ctrl_cs <= S_DRP_1READ_PAUSE;
      end if;

    when S_DRP_1READ_PAUSE =>

      if i_timer = CONV_STD_LOGIC_VECTOR(16#003#, 16) then
        i_timer<=(others=>'0');
        fsm_drp_ctrl_cs <= S_DONE;
      else
        i_timer<=i_timer + 1;
      end if;


    --//-------------------------------------------
    --//DONE configuration DUAL_GTP
    --//-------------------------------------------
    when S_DONE =>
      i_timer<=(others=>'0');
      i_gtp_rst<='0';

      fsm_drp_ctrl_cs <= S_DONE ;

  end case;
--  end if;
end if;
end process;

--//END MAIN
end architecture;