-------------------------------------------------------------------------
-- Company     : Linkos
-- Engineer    : Golovachenko Victor
--
-- Create Date : 06.02.2011 18:14:26
-- Module Name : sata_speed_ctrl
--
-- Назначение/Описание :
--      1. Задание типа спецификации SATA(Gen1,Gen2) на которой будет производиться установка связи
--      2. Сброс модулей управления SATA соотв. канала DUAL_GTP перед попыткой установления связи.
--
-- адреса/значения атрибутов PLL модуля GT
-- -----------------------------------------------------------------
--| GTCH |     Attribute      | DRP | DRP   | Value for | Value for |
--|      |                    | Adr | bits  | SATA-I    | SATA-II   |
--|-----------------------------------------------------------------
--| CH0  | PLL_RXDIVSEL_OUT_0 | x1B |  14   |     1     |     0     |
--|      | PLL_TXDIVSEL_OUT_0 | x1F |  14   |     1     |     0     |
--|-----------------------------------------------------------------
--
-- Revision:
-- Revision 0.01 - File Created
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
use work.sata_sim_lite_pkg.all;

entity sata_speed_ctrl is
generic(
G_SATAH_COUNT_MAX : integer:=1;    --//кол-во модулей sata_host
G_SATAH_NUM       : integer:=0;    --//индекс модуля sata_host
G_SATAH_CH_COUNT  : integer:=1;    --//Кол-во портов используемых в модуле GT.(возможные значения - 1,2)
G_DBG             : string :="OFF";
G_DBGCS           : string :="OFF";--//Отладка через ChipScope
G_SIM             : string :="OFF"
);
port(
--------------------------------------------------
--
--------------------------------------------------
p_in_ctrl           : in    TSpdCtrl_GTCH;
p_out_phy_spd       : out   TSpdCtrl_GTCH;--//Текущая скорость соединения (SATA-II/I(3Gb/s)/(1.5Gb/s))
p_out_phy_layer_rst : out   std_logic_vector(C_GTCH_COUNT_MAX-1 downto 0);

p_in_phy_linkup     : in    std_logic_vector(C_GTCH_COUNT_MAX-1 downto 0);
p_in_gt_pll_lock    : in    std_logic;
p_in_usr_dcm_lock   : in    std_logic;

--------------------------------------------------
--Связь с GTP
--------------------------------------------------
p_out_gt_drpaddr    : out   std_logic_vector(7 downto 0);
p_out_gt_drpen      : out   std_logic;
p_out_gt_drpwe      : out   std_logic;
p_out_gt_drpdi      : out   std_logic_vector(15 downto 0);
p_in_gt_drpdo       : in    std_logic_vector(15 downto 0);
p_in_gt_drprdy      : in    std_logic;

p_out_gt_ch_rst     : out   std_logic_vector(C_GTCH_COUNT_MAX-1 downto 0);--//Сброс канала GT
p_in_gt_resetdone   : in    std_logic_vector(C_GTCH_COUNT_MAX-1 downto 0);--//Подтвержение завершения сброса GT

--------------------------------------------------
--Технологические сигналы
--------------------------------------------------
p_in_tst            : in    std_logic_vector(31 downto 0);
p_out_tst           : out   std_logic_vector(31 downto 0);
p_out_dbgcs_ila     : out   TSH_ila;

--------------------------------------------------
--System
--------------------------------------------------
p_in_clk            : in    std_logic;
p_in_rst            : in    std_logic
);
end sata_speed_ctrl;

architecture behavioral of sata_speed_ctrl is

constant C_TIME_OUT        : integer := 16#00081EB4#;--16#00080EB4# - timeout для боевого проекта -3.5ms на 150MHz

constant C_SATAH_COUNT_MAX : integer :=G_SATAH_COUNT_MAX;
constant C_SATAH_NUM       : integer :=G_SATAH_NUM;

constant C_GT_CH0          : integer :=0;
constant C_GT_CH1          : integer :=1;

--//Адреса регистров GT
--//более подробно см.Appendix B/ug386_Spartan6_GTP_Transceivers_User_Guide.pdf
constant C_AREG_PLL_TXDIVSEL_OUT_0: std_logic_vector(p_out_gt_drpaddr'range):=CONV_STD_LOGIC_VECTOR(16#1F#, p_out_gt_drpaddr'length);--//Канал 0
constant C_AREG_PLL_TXDIVSEL_OUT_1: std_logic_vector(p_out_gt_drpaddr'range):=CONV_STD_LOGIC_VECTOR(16#7F#, p_out_gt_drpaddr'length);--//Канал 1(не используется)

constant C_AREG_PLL_RXDIVSEL_OUT_0: std_logic_vector(p_out_gt_drpaddr'range):=CONV_STD_LOGIC_VECTOR(16#1B#, p_out_gt_drpaddr'length);--//Канал 0
constant C_AREG_PLL_RXDIVSEL_OUT_1: std_logic_vector(p_out_gt_drpaddr'range):=CONV_STD_LOGIC_VECTOR(16#7F#, p_out_gt_drpaddr'length);--//Канал 1(не используется)

type TBusADRP_GTCH is array (0 to 1) of std_logic_vector (p_out_gt_drpaddr'range);

constant C_AREG_PLL_TXDIVSEL_OUT  : TBusADRP_GTCH:=(C_AREG_PLL_TXDIVSEL_OUT_0,C_AREG_PLL_TXDIVSEL_OUT_1);
constant C_AREG_PLL_RXDIVSEL_OUT  : TBusADRP_GTCH:=(C_AREG_PLL_RXDIVSEL_OUT_0,C_AREG_PLL_RXDIVSEL_OUT_1);

type TRegValue is array (0 to C_FSATA_GEN_COUNT-1) of std_logic;
constant C_VAL_PLL_DIVSEL_OUT  : TRegValue:=
(
'1',--//Значения для программирования SATA-I
'0' --//Значения для программирования SATA-II
);

constant C_REG_PLL_RXDIVSEL       : std_logic:='0';
constant C_REG_PLL_TXDIVSEL       : std_logic:='1';


type TSpdCtrl_fsm_state is (
S_IDLE,
S_IDLE_INIT,
S_IDLE_INIT_DONE,

---------------------------------------------
--Перестройка скорости соединения с SATA устройством
---------------------------------------------
S_CH0_CHECK_LINK,
S_CH0_READ,
S_CH0_READ_DONE,
S_CH0_PAUSE_R,
S_CH0_WRITE,
S_CH0_WRITE_DONE,
S_CH0_PAUSE_W,
S_CH0_DRP_PROG_DONE,

--S_CH1_CHECK_LINK,
--S_CH1_READ,
--S_CH1_READ_DONE,
--S_CH1_PAUSE_R,
--S_CH1_WRITE,
--S_CH1_WRITE_DONE,
--S_CH1_PAUSE_W,
--S_CH1_DRP_PROG_DONE,

S_GT_CH_RESET,
S_GT_CH_RESET_DONE,

S_WAIT_CONNECT,
S_LINKUP
);
signal fsm_spdctrl_cs           : TSpdCtrl_fsm_state;

signal i_tmr                    : std_logic_vector(31 downto 0);
signal i_tmr_en                 : std_logic;

signal in_phy_linkup            : std_logic_vector(p_in_phy_linkup'range);
signal i_phy_linkup             : std_logic_vector(p_in_phy_linkup'range);
signal i_phy_layer_rst_n        : std_logic_vector(p_out_phy_layer_rst'range);
signal i_phy_layer_rst          : std_logic_vector(p_out_phy_layer_rst'range);
signal i_phy_spd                : TSpdCtrl_GTCH;

signal i_gt_drpaddr             : std_logic_vector(p_out_gt_drpaddr'range);
signal i_gt_drpen               : std_logic;
signal i_gt_drpwe               : std_logic;
signal i_gt_drpdi               : std_logic_vector(p_out_gt_drpdi'range);
signal i_gt_ch_rst              : std_logic_vector(p_out_gt_ch_rst'range);

signal i_gt_drp_rdval           : std_logic_vector(p_out_gt_drpdi'range);
signal i_gt_drp_regsel          : std_logic;--//0/1 - выбор регистров канала GTP PLL_RXDIVSEL/PLL_TXDIVSEL

signal sr0_ctrl                 : TSpdCtrl_GTCH;
signal sr1_ctrl                 : TSpdCtrl_GTCH;
signal i_spd_change_det         : std_logic_vector(C_GTCH_COUNT_MAX-1 downto 0);

signal tst_fms_cs               : std_logic_vector(5 downto 0);
signal i_dbgcs_trig00           : std_logic_vector(41 downto 0);
signal i_dbgcs_data             : std_logic_vector(122 downto 0);


--MAIN
begin

--//----------------------------------
--//Технологические сигналы
--//----------------------------------
gen_dbg_off : if strcmp(G_DBG,"OFF") generate
p_out_tst(31 downto 0)<=(others=>'0');
end generate gen_dbg_off;

gen_dbg_on : if strcmp(G_DBG,"ON") generate
p_out_tst(31 downto 0)<=(others=>'0');
--ltstout:process(p_in_rst,p_in_clk)
--begin
--  if p_in_rst='1' then
----    tst_fms_cs_dly<=(others=>'0');
--    p_out_tst(0)<='0';
--  elsif p_in_clk'event and p_in_clk='1' then
--
----    tst_fms_cs_dly<=tst_fms_cs;
--    p_out_tst(0)<='0';--OR_reduce(tst_fms_cs_dly);
--  end if;
--end process ltstout;
--
--p_out_tst(31 downto 1)<=(others=>'0');

end generate gen_dbg_on;


--//----------------------------------
--//Связь с Sata_Host
--//----------------------------------
gen_ch_count1 : if G_SATAH_CH_COUNT=1 generate
in_phy_linkup(1)<='1';
end generate gen_ch_count1;

gen_ch: for i in 0 to G_SATAH_CH_COUNT-1 generate
in_phy_linkup(i)<=p_in_phy_linkup(i);
end generate gen_ch;

--//Детектируем изменение скорости соединения пользователем
gen_chg_det : for i in 0 to C_GTCH_COUNT_MAX-1 generate

process(p_in_rst,p_in_clk)
begin
  if p_in_rst='1' then
    sr0_ctrl(i).sata_ver<=(others=>'0');
    sr1_ctrl(i).sata_ver<=(others=>'0');
    i_spd_change_det(i)<='0';

  elsif p_in_clk'event and p_in_clk='1' then

    sr0_ctrl(i).sata_ver<=p_in_ctrl(i).sata_ver;
    sr1_ctrl(i).sata_ver<=sr0_ctrl(i).sata_ver;

    if  i_spd_change_det(i)='0' and sr0_ctrl(i).sata_ver/=sr1_ctrl(i).sata_ver then
    --//Пользователь измененил скорость соединения
      i_spd_change_det(i)<='1';
    else
      i_spd_change_det(i)<='0';
    end if;

  end if;
end process;

--//Сброс SATA PHY Layer:
i_phy_layer_rst(i)<=not i_phy_layer_rst_n(i) when i_phy_linkup(i)='0' else i_spd_change_det(i);

end generate gen_chg_det;

p_out_phy_layer_rst<=i_phy_layer_rst;
p_out_phy_spd<=i_phy_spd;

p_out_gt_drpaddr<=i_gt_drpaddr;
p_out_gt_drpen  <=i_gt_drpen;
p_out_gt_drpwe  <=i_gt_drpwe;
p_out_gt_drpdi  <=i_gt_drpdi;

p_out_gt_ch_rst<=i_gt_ch_rst;



--//----------------------------------
--//Логика управления
--//----------------------------------
--//
ltmr:process(p_in_rst,p_in_clk)
begin
  if p_in_rst='1' then
    i_tmr<=(others=>'0');
  elsif p_in_clk'event and p_in_clk='1' then
    if i_tmr_en='0' then
      i_tmr<=(others=>'0');
    else
      i_tmr<=i_tmr+1;
    end if;
  end if;
end process ltmr;


--//Автомат программирования регистров GTP
lfsm:process(p_in_rst,p_in_clk)
begin
  if p_in_rst='1' then

    fsm_spdctrl_cs<=S_IDLE;

    i_phy_layer_rst_n<=(others=>'0');
    i_gt_ch_rst<=(others=>'0');

    i_gt_drpaddr<=(others=>'0');
    i_gt_drpdi<=(others=>'0');
    i_gt_drpen<='0';
    i_gt_drpwe<='0';

    i_gt_drp_rdval<=(others=>'0');
    i_gt_drp_regsel<=C_REG_PLL_RXDIVSEL;

    for i in 0 to C_GTCH_COUNT_MAX-1 loop
    i_phy_spd(i).sata_ver<=CONV_STD_LOGIC_VECTOR(C_FSATA_GEN_DEFAULT, i_phy_spd(i).sata_ver'length);
    end loop;
    i_tmr_en<='0';

    i_phy_linkup<=(others=>'0');

  elsif p_in_clk'event and p_in_clk='1' then

    i_phy_linkup<=in_phy_linkup;

    case fsm_spdctrl_cs is

      --//---------------------------------------------
      --//Жду пока установятся тактовые частоты
      --//---------------------------------------------
      when S_IDLE =>

        for i in 0 to C_GTCH_COUNT_MAX-1 loop
          i_phy_spd(i).sata_ver<=p_in_ctrl(i).sata_ver;
        end loop;

        if p_in_gt_pll_lock='1' or p_in_usr_dcm_lock='1' then
          if i_tmr=CONV_STD_LOGIC_VECTOR(16#0F#, i_tmr'length) then
            i_tmr_en<='0';
            fsm_spdctrl_cs<=S_IDLE_INIT;
          else
            i_tmr_en<='1';
          end if;
        end if;


      --//---------------------------------------------
      --//Cброс GT
      --//---------------------------------------------
      when S_IDLE_INIT =>

        if i_tmr=CONV_STD_LOGIC_VECTOR(16#01F#, i_tmr'length) then
          i_tmr_en<='0';
          i_gt_ch_rst<=(others=>'0');
          fsm_spdctrl_cs<=S_IDLE_INIT_DONE;

        elsif i_tmr=CONV_STD_LOGIC_VECTOR(16#0F#, i_tmr'length) then
          i_gt_ch_rst<=(others=>'1');

        else
          i_tmr_en<='1';
        end if;

      when S_IDLE_INIT_DONE =>

        --//Ждем завершения процеса сброса GT
        if AND_reduce(p_in_gt_resetdone)='1' then
          fsm_spdctrl_cs<=S_CH0_CHECK_LINK;
        end if;




      --//##################################################
      --//CH0 - программирование DRP регстиров
      --//##################################################
      when S_CH0_CHECK_LINK =>

        if i_phy_linkup(C_GT_CH0)='0' then
        --//Не соединения в этом канале
          fsm_spdctrl_cs<=S_CH0_READ;
        else
          fsm_spdctrl_cs<=S_GT_CH_RESET;--S_CH1_CHECK_LINK;
        end if;

      --//-------------------------------------------
      --//Чтение регистра DRP (См. таблицу в шапке модуля sata_spd_ctrl.vhd)
      --//-------------------------------------------
      when S_CH0_READ =>

        if i_gt_drp_regsel=C_REG_PLL_RXDIVSEL then
          i_gt_drpaddr<=C_AREG_PLL_RXDIVSEL_OUT(C_GT_CH0);
        else
          i_gt_drpaddr<=C_AREG_PLL_TXDIVSEL_OUT(C_GT_CH0);
        end if;

        i_gt_drpen<='1';
        i_gt_drpwe<='0';
        fsm_spdctrl_cs<=S_CH0_READ_DONE;

      when S_CH0_READ_DONE =>

        if p_in_gt_drprdy='1' then
          i_gt_drpen<='0';
          i_gt_drp_rdval<=p_in_gt_drpdo;

          fsm_spdctrl_cs<=S_CH0_PAUSE_R;
        end if;

      when S_CH0_PAUSE_R =>

        if i_tmr=CONV_STD_LOGIC_VECTOR(16#003#, i_tmr'length) then
          i_tmr_en<='0';
          fsm_spdctrl_cs<=S_CH0_WRITE;
        else
          i_tmr_en<='1';
        end if;

      --//-------------------------------------------
      --//Запись регистра DRP (См. таблицу в шапке модуля sata_spd_ctrl.vhd)
      --//-------------------------------------------
      when S_CH0_WRITE =>

        if i_gt_drp_regsel=C_REG_PLL_RXDIVSEL then
          i_gt_drpaddr<=C_AREG_PLL_RXDIVSEL_OUT(C_GT_CH0);

          for i in 0 to C_FSATA_GEN_COUNT-1 loop
            if i_phy_spd(C_GT_CH0).sata_ver=CONV_STD_LOGIC_VECTOR(i, i_phy_spd(C_GT_CH0).sata_ver'length) then
              i_gt_drpdi(14)<=C_VAL_PLL_DIVSEL_OUT(i);
            end if;
          end loop;
          i_gt_drpdi(13 downto 0)<=i_gt_drp_rdval(13 downto 0);
--          i_gt_drpdi(14)         <=i_gt_drp_rdval(14);
          i_gt_drpdi(15)         <=i_gt_drp_rdval(15);

        else
          i_gt_drpaddr<=C_AREG_PLL_TXDIVSEL_OUT(C_GT_CH0);

          for i in 0 to C_FSATA_GEN_COUNT-1 loop
            if i_phy_spd(C_GT_CH0).sata_ver=CONV_STD_LOGIC_VECTOR(i, i_phy_spd(C_GT_CH0).sata_ver'length) then
              i_gt_drpdi(14)<=C_VAL_PLL_DIVSEL_OUT(i);
            end if;
          end loop;
          i_gt_drpdi(13 downto 0)<=i_gt_drp_rdval(13 downto 0);
--          i_gt_drpdi(14)         <=i_gt_drp_rdval(14);
          i_gt_drpdi(15)         <=i_gt_drp_rdval(15);

        end if;

        i_gt_drpen<='1';
        i_gt_drpwe<='1';
        fsm_spdctrl_cs<=S_CH0_WRITE_DONE;

      when S_CH0_WRITE_DONE =>

        if p_in_gt_drprdy='1' then
          i_gt_drpen<='0';
          i_gt_drpwe<='0';

          fsm_spdctrl_cs<=S_CH0_PAUSE_W;
        end if;

      when S_CH0_PAUSE_W =>

        if i_tmr=CONV_STD_LOGIC_VECTOR(16#003#, i_tmr'length) then
          i_tmr_en<='0';
          fsm_spdctrl_cs<=S_CH0_DRP_PROG_DONE;
        else
          i_tmr_en<='1';
        end if;

      --//-------------------------------------------
      --//Проверяем запрограмированы ли все регисты DRP
      --//-------------------------------------------
      when S_CH0_DRP_PROG_DONE =>

        if i_gt_drp_regsel=C_REG_PLL_TXDIVSEL then
          --//Все регистры запрограммированы.
          i_gt_drp_regsel<=C_REG_PLL_RXDIVSEL;

          fsm_spdctrl_cs<=S_GT_CH_RESET;--S_CH1_CHECK_LINK;

        else
          i_gt_drp_regsel<=C_REG_PLL_TXDIVSEL;
          fsm_spdctrl_cs<=S_CH0_READ;

        end if;



--      --//##################################################
--      --//CH1 - программирование DRP регстиров
--      --//##################################################
--      when S_CH1_CHECK_LINK =>
--
--        if i_phy_linkup(C_GT_CH1)='0' then
--        --//Не соединения в этом канале
--          fsm_spdctrl_cs<=S_CH1_READ;
--        else
--          fsm_spdctrl_cs<=S_GT_CH_RESET;
--        end if;
--
--      --//-------------------------------------------
--      --//Чтение регистра DRP (См. таблицу в шапке модуля sata_spd_ctrl.vhd)
--      --//-------------------------------------------
--      when S_CH1_READ =>
--
--        if i_gt_drp_regsel=C_REG_PLL_RXDIVSEL then
--          i_gt_drpaddr<=C_AREG_PLL_RXDIVSEL_OUT(C_GT_CH1);
--        else
--          i_gt_drpaddr<=C_AREG_PLL_TXDIVSEL_OUT(C_GT_CH1);
--        end if;
--
--        i_gt_drpen<='1';
--        i_gt_drpwe<='0';
--        fsm_spdctrl_cs<=S_CH1_READ_DONE;
--
--      when S_CH1_READ_DONE =>
--
--        if p_in_gt_drprdy='1' then
--          i_gt_drpen<='0';
--          i_gt_drp_rdval<=p_in_gt_drpdo;
--
--          fsm_spdctrl_cs<=S_CH1_PAUSE_R;
--        end if;
--
--      when S_CH1_PAUSE_R =>
--
--        if i_tmr=CONV_STD_LOGIC_VECTOR(16#003#, i_tmr'length) then
--          i_tmr_en<='0';
--          fsm_spdctrl_cs<=S_CH1_WRITE;
--        else
--          i_tmr_en<='1';
--        end if;
--
--      --//-------------------------------------------
--      --//Запись регистра DRP (См. таблицу в шапке модуля sata_spd_ctrl.vhd)
--      --//-------------------------------------------
--      when S_CH1_WRITE =>
--
--        if i_gt_drp_regsel=C_REG_PLL_RXDIVSEL then
--          i_gt_drpaddr<=C_AREG_PLL_RXDIVSEL_OUT(C_GT_CH1);
--
--          for i in 0 to C_FSATA_GEN_COUNT-1 loop
--            if i_phy_spd(C_GT_CH1).sata_ver=CONV_STD_LOGIC_VECTOR(i, i_phy_spd(C_GT_CH1).sata_ver'length) then
--              i_gt_drpdi(8)<=C_VAL_PLL_DIVSEL_OUT(i);
--            end if;
--          end loop;
--          i_gt_drpdi(7 downto 0) <=i_gt_drp_rdval(7 downto 0);
----          i_gt_drpdi(8)          <=i_gt_drp_rdval(8);
--          i_gt_drpdi(15 downto 9)<=i_gt_drp_rdval(15 downto 9);
--
--        else
--          i_gt_drpaddr<=C_AREG_PLL_TXDIVSEL_OUT(C_GT_CH1);
--
--          for i in 0 to C_FSATA_GEN_COUNT-1 loop
--            if i_phy_spd(C_GT_CH1).sata_ver=CONV_STD_LOGIC_VECTOR(i, i_phy_spd(C_GT_CH1).sata_ver'length) then
--              i_gt_drpdi(10)<=C_VAL_PLL_DIVSEL_OUT(i);
--            end if;
--          end loop;
--          i_gt_drpdi(9 downto 0)  <=i_gt_drp_rdval(9 downto 0);
----          i_gt_drpdi(10)          <=i_gt_drp_rdval(10);
--          i_gt_drpdi(15 downto 11)<=i_gt_drp_rdval(15 downto 11);
--
--        end if;
--
--        i_gt_drpen<='1';
--        i_gt_drpwe<='1';
--        fsm_spdctrl_cs<=S_CH1_WRITE_DONE;
--
--      when S_CH1_WRITE_DONE =>
--
--        if p_in_gt_drprdy='1' then
--          i_gt_drpen<='0';
--          i_gt_drpwe<='0';
--
--          fsm_spdctrl_cs<=S_CH1_PAUSE_W;
--        end if;
--
--      when S_CH1_PAUSE_W =>
--
--        if i_tmr=CONV_STD_LOGIC_VECTOR(16#003#, i_tmr'length) then
--          i_tmr_en<='0';
--          fsm_spdctrl_cs<=S_CH1_DRP_PROG_DONE;
--        else
--          i_tmr_en<='1';
--        end if;
--
--      --//-------------------------------------------
--      --//Проверяем запрограмированы ли все регисты DRP
--      --//-------------------------------------------
--      when S_CH1_DRP_PROG_DONE =>
--
--        if i_gt_drp_regsel=C_REG_PLL_TXDIVSEL then
--          --//Все регистры запрограммированы.
--          i_gt_drp_regsel<=C_REG_PLL_RXDIVSEL;
--
--          fsm_spdctrl_cs<=S_GT_CH_RESET;
--
--        else
--          i_gt_drp_regsel<=C_REG_PLL_TXDIVSEL;
--          fsm_spdctrl_cs<=S_CH1_READ;
--
--        end if;



      --//##################################################
      --//Сброс канала GT
      --//##################################################
      when S_GT_CH_RESET =>

        i_gt_drpaddr<=(others=>'0');
        i_gt_drpdi<=(others=>'0');
        i_gt_drpen<='0';
        i_gt_drpwe<='0';

        if i_tmr=CONV_STD_LOGIC_VECTOR(16#01F#, i_tmr'length) then
          i_tmr_en<='0';
          fsm_spdctrl_cs<=S_GT_CH_RESET_DONE;

        elsif i_tmr=CONV_STD_LOGIC_VECTOR(16#0F#, i_tmr'length) then

          for i in 0 to C_GTCH_COUNT_MAX-1 loop
            if i_phy_linkup(i)='0' then
              i_gt_ch_rst(i)<='1';
            end if;
          end loop;

        else
          i_tmr_en<='1';
        end if;

      when S_GT_CH_RESET_DONE =>

        i_gt_ch_rst<=(others=>'0');

        if AND_reduce(p_in_gt_resetdone)='1' then
          for i in 0 to C_GTCH_COUNT_MAX-1 loop
            i_phy_layer_rst_n(i)<='1';
          end loop;

          fsm_spdctrl_cs<=S_WAIT_CONNECT;
        end if;



      --//##################################################
      --//Ждем соединения
      --//##################################################
      when S_WAIT_CONNECT =>

        if  i_phy_linkup=(i_phy_linkup'range=>'1') then
          --//ЕСТЬ соединение в обоих каналах
          i_tmr_en<='0';--//CLR TIMER
          fsm_spdctrl_cs<=S_LINKUP;
        else
          if i_tmr=CONV_STD_LOGIC_VECTOR(C_TIME_OUT, i_tmr'length) then
          --//Время ожидания вышло
            i_tmr_en<='0';--//CLR TIMER
            for i in 0 to C_GTCH_COUNT_MAX-1 loop
              if i_phy_linkup(i)='0' then
                i_phy_layer_rst_n(i)<='0';
              end if;

             i_phy_spd(i).sata_ver<=p_in_ctrl(i).sata_ver;

            end loop;

            fsm_spdctrl_cs<=S_CH0_CHECK_LINK;
          else
            i_tmr_en<='1';
          end if;
        end if;

      when S_LINKUP =>

        if i_phy_linkup/=(i_phy_linkup'range=>'1') then
        --//Обрыв соединения!!

          for i in 0 to C_GTCH_COUNT_MAX-1 loop
            if i_phy_linkup(i)='0' then
              i_phy_layer_rst_n(i)<='0';
            end if;
          end loop;

          fsm_spdctrl_cs<=S_CH0_CHECK_LINK;

        end if;

    end case;

end if;
end process lfsm;






--//-----------------------------------
--//Debug/Sim
--//-----------------------------------
gen_dbgcs_off : if strcmp(G_DBGCS,"OFF") generate
p_out_dbgcs_ila.clk   <='0';
p_out_dbgcs_ila.trig0 <=(others=>'0');
p_out_dbgcs_ila.data  <=(others=>'0');
end generate gen_dbgcs_off;


gen_dbgcs_on : if strcmp(G_DBGCS,"ON") generate

process(p_in_clk)
begin
if p_in_clk'event and p_in_clk='1' then

i_dbgcs_trig00(5 downto 0)<=tst_fms_cs(5 downto 0);
for d in 0 to C_GTCH_COUNT_MAX-1 loop
i_dbgcs_trig00(6+d)<=i_gt_ch_rst(d);
end loop;
for e in 0 to C_GTCH_COUNT_MAX-1 loop
i_dbgcs_trig00(8+e)<=i_phy_linkup(e);
end loop;

i_dbgcs_trig00(10)<=AND_reduce(p_in_gt_resetdone);
i_dbgcs_trig00(41 downto 11)<=(others=>'0');


i_dbgcs_data(5 downto 0)<=tst_fms_cs(5 downto 0);
for a in 0 to C_GTCH_COUNT_MAX-1 loop
i_dbgcs_data(6+a)<=i_gt_ch_rst(a);
end loop;
for b in 0 to C_GTCH_COUNT_MAX-1 loop
i_dbgcs_data(8+b)<=i_phy_linkup(b);
end loop;
for c in 0 to C_GTCH_COUNT_MAX-1 loop
i_dbgcs_data(10+c)<=i_phy_layer_rst(c);
end loop;
i_dbgcs_data(12)<=i_gt_drp_regsel;

i_dbgcs_data(20 downto 13)<=i_gt_drpaddr;
i_dbgcs_data(21)<=i_gt_drpen;
i_dbgcs_data(22)<=i_gt_drpwe;
i_dbgcs_data(23)<=p_in_gt_drprdy;
i_dbgcs_data(39 downto 24)<=i_gt_drpdi;
i_dbgcs_data(55 downto 40)<=p_in_gt_drpdo;
i_dbgcs_data(122 downto 56)<=(others=>'0');


end if;
end process;

tst_fms_cs<=CONV_STD_LOGIC_VECTOR(16#01#, tst_fms_cs'length) when fsm_spdctrl_cs=S_IDLE_INIT                   else
            CONV_STD_LOGIC_VECTOR(16#02#, tst_fms_cs'length) when fsm_spdctrl_cs=S_IDLE_INIT_DONE              else
            CONV_STD_LOGIC_VECTOR(16#03#, tst_fms_cs'length) when fsm_spdctrl_cs=S_CH0_CHECK_LINK              else
            CONV_STD_LOGIC_VECTOR(16#04#, tst_fms_cs'length) when fsm_spdctrl_cs=S_CH0_READ                    else
            CONV_STD_LOGIC_VECTOR(16#05#, tst_fms_cs'length) when fsm_spdctrl_cs=S_CH0_READ_DONE               else
            CONV_STD_LOGIC_VECTOR(16#06#, tst_fms_cs'length) when fsm_spdctrl_cs=S_CH0_PAUSE_R                 else
            CONV_STD_LOGIC_VECTOR(16#07#, tst_fms_cs'length) when fsm_spdctrl_cs=S_CH0_WRITE                   else
            CONV_STD_LOGIC_VECTOR(16#08#, tst_fms_cs'length) when fsm_spdctrl_cs=S_CH0_WRITE_DONE              else
            CONV_STD_LOGIC_VECTOR(16#09#, tst_fms_cs'length) when fsm_spdctrl_cs=S_CH0_PAUSE_W                 else
            CONV_STD_LOGIC_VECTOR(16#0A#, tst_fms_cs'length) when fsm_spdctrl_cs=S_CH0_DRP_PROG_DONE           else
--            CONV_STD_LOGIC_VECTOR(16#0B#, tst_fms_cs'length) when fsm_spdctrl_cs=S_CH1_CHECK_LINK              else
--            CONV_STD_LOGIC_VECTOR(16#0C#, tst_fms_cs'length) when fsm_spdctrl_cs=S_CH1_READ                    else
--            CONV_STD_LOGIC_VECTOR(16#0D#, tst_fms_cs'length) when fsm_spdctrl_cs=S_CH1_READ_DONE               else
--            CONV_STD_LOGIC_VECTOR(16#0E#, tst_fms_cs'length) when fsm_spdctrl_cs=S_CH1_PAUSE_R                 else
--            CONV_STD_LOGIC_VECTOR(16#0F#, tst_fms_cs'length) when fsm_spdctrl_cs=S_CH1_WRITE                   else
--            CONV_STD_LOGIC_VECTOR(16#10#, tst_fms_cs'length) when fsm_spdctrl_cs=S_CH1_WRITE_DONE              else
--            CONV_STD_LOGIC_VECTOR(16#11#, tst_fms_cs'length) when fsm_spdctrl_cs=S_CH1_PAUSE_W                 else
--            CONV_STD_LOGIC_VECTOR(16#12#, tst_fms_cs'length) when fsm_spdctrl_cs=S_CH1_DRP_PROG_DONE           else
            CONV_STD_LOGIC_VECTOR(16#13#, tst_fms_cs'length) when fsm_spdctrl_cs=S_GT_CH_RESET                 else
            CONV_STD_LOGIC_VECTOR(16#14#, tst_fms_cs'length) when fsm_spdctrl_cs=S_GT_CH_RESET_DONE            else
            CONV_STD_LOGIC_VECTOR(16#15#, tst_fms_cs'length) when fsm_spdctrl_cs=S_WAIT_CONNECT                else
            CONV_STD_LOGIC_VECTOR(16#16#, tst_fms_cs'length) when fsm_spdctrl_cs=S_LINKUP                      else
            CONV_STD_LOGIC_VECTOR(16#00#, tst_fms_cs'length); --//S_IDLE

p_out_dbgcs_ila.clk   <=p_in_clk;
p_out_dbgcs_ila.trig0 <=EXT(i_dbgcs_trig00, p_out_dbgcs_ila.trig0'length);
p_out_dbgcs_ila.data  <=EXT(i_dbgcs_data, p_out_dbgcs_ila.data'length);

end generate gen_dbgcs_on;


--END MAIN
end behavioral;
