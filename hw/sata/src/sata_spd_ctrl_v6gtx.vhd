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
--
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
use work.sata_pkg.all;

entity sata_speed_ctrl is
generic
(
G_SATAH_COUNT_MAX : integer:=1;
G_SATAH_NUM       : integer:=0;
G_DBG             : string :="OFF";
G_SIM             : string :="OFF"
);
port
(
--------------------------------------------------
--
--------------------------------------------------
p_in_ctrl               : in    TSpdCtrl_GTCH;
p_out_spd_ver           : out   TSpdCtrl_GTCH;--//Выбор типа SATA: Generation 2 (3Gb/s)/ Generation 1 (1.5Gb/s)

p_in_gtp_pll_lock       : in    std_logic;
p_in_usr_dcm_lock       : in    std_logic;

--------------------------------------------------
--Связь с GTP
--------------------------------------------------
p_out_gtp_drpaddr       : out   std_logic_vector(7 downto 0);
p_out_gtp_drpen         : out   std_logic;
p_out_gtp_drpwe         : out   std_logic;
p_out_gtp_drpdi         : out   std_logic_vector(15 downto 0);
p_in_gtp_drpdo          : in    std_logic_vector(15 downto 0);
p_in_gtp_drprdy         : in    std_logic;

p_out_gtp_ch_rst        : out   std_logic_vector(C_GTCH_COUNT_MAX-1 downto 0);--//Сброс соотв. GTP
p_out_gtp_rst           : out   std_logic;                                      --//Полный сброс GTP.

--------------------------------------------------
--Технологические сигналы
--------------------------------------------------
p_in_tst                : in    std_logic_vector(31 downto 0);
p_out_tst               : out   std_logic_vector(31 downto 0);

--------------------------------------------------
--System
--------------------------------------------------
p_in_clk                : in    std_logic;
p_in_rst                : in    std_logic
);
end sata_speed_ctrl;

architecture behavioral of sata_speed_ctrl is

constant C_SATAH_COUNT_MAX : integer :=G_SATAH_COUNT_MAX;
constant C_SATAH_NUM       : integer :=G_SATAH_NUM;

--//Адреса регистров GTP
--//более подробно см.Appendix D/ug196_Virtex-5 FPGA RocketIO GTP Transceiver User Guide.pdf
constant C_AREG_REFCLK_SEL        : std_logic_vector(p_out_gtp_drpaddr'range):=CONV_STD_LOGIC_VECTOR(16#04#, p_out_gtp_drpaddr'length);

constant C_AREG_PLL_TXDIVSEL_OUT_0: std_logic_vector(p_out_gtp_drpaddr'range):=CONV_STD_LOGIC_VECTOR(16#45#, p_out_gtp_drpaddr'length);--//Канал 0
constant C_AREG_PLL_TXDIVSEL_OUT_1: std_logic_vector(p_out_gtp_drpaddr'range):=CONV_STD_LOGIC_VECTOR(16#05#, p_out_gtp_drpaddr'length);--//Канал 1

constant C_AREG_PLL_RXDIVSEL_OUT_0: std_logic_vector(p_out_gtp_drpaddr'range):=CONV_STD_LOGIC_VECTOR(16#46#, p_out_gtp_drpaddr'length);--//Канал 0
constant C_AREG_PLL_RXDIVSEL_OUT_1: std_logic_vector(p_out_gtp_drpaddr'range):=CONV_STD_LOGIC_VECTOR(16#0A#, p_out_gtp_drpaddr'length);--//Канал 1

type TBusADRP_GTCH is array (0 to C_GTCH_COUNT_MAX-1) of std_logic_vector (p_out_gtp_drpaddr'range);

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


type fsm_state is
(
S_IDLE,

----//-------------------------------------------
----//Перестройка частоты тактирования GTP
----//-------------------------------------------
--S_DRP_READ,
--S_DRP_READ_DONE,
--S_DRP_READ_PAUSE,
--S_DRP_WRITE,
--S_DRP_WRITE_DONE,
--S_DRP_WRITE_PAUSE,
--S_GTP_RESET_START,
--S_GTP_RESET_DONE,

--//-------------------------------------------
--//Перестройка скорости соединения с SATA устройством
--//-------------------------------------------
S_IDLE_SPDCFG,

S_READ_CH0,
S_READ_CH0_DONE,
S_PAUSE_R0,
S_READ_CH1,
S_READ_CH1_DONE,
S_PAUSE_R1,
S_WRITE_CH0,
S_WRITE_CH0_DONE,
S_PAUSE_W0,
S_WRITE_CH1,
S_WRITE_CH1_DONE,
S_PAUSE_W1,
S_DRP_PROG_DONE,

S_GTP_CH_RESET,
S_GTP_CH_RESET_DONE
);
signal fsm_state_cs: fsm_state;

signal i_tmr                    : std_logic_vector(4 downto 0);
signal i_tmr_en                 : std_logic;

signal i_spd_change             : std_logic_vector(C_GTCH_COUNT_MAX-1 downto 0);
signal i_spd_change_save        : std_logic_vector(C_GTCH_COUNT_MAX-1 downto 0);
signal i_spd_ver_out            : TSpdCtrl_GTCH;

signal i_gtp_drp_addr           : std_logic_vector(p_out_gtp_drpaddr'range);
signal i_gtp_drp_en             : std_logic;
signal i_gtp_drp_we             : std_logic;
signal i_gtp_drp_di             : std_logic_vector(15 downto 0);
signal i_gtp_drpdo              : std_logic_vector(15 downto 0);
signal i_gtp_drprdy             : std_logic;
signal i_gtp_drp_regsel         : std_logic;--//0/1 - выбор регистров канала GTP PLL_RXDIVSEL/PLL_TXDIVSEL
signal i_gtp_drp_rdval          : TBus16_GTCH;

signal i_gtp_rst                : std_logic;
signal i_gtp_ch_rst             : std_logic_vector(C_GTCH_COUNT_MAX-1 downto 0);

signal tst_fms_cs               : std_logic_vector(4 downto 0);
signal tst_fms_cs_dly           : std_logic_vector(tst_fms_cs'range);


--MAIN
begin

--//----------------------------------
--//Технологические сигналы
--//----------------------------------
gen_dbg_off : if strcmp(G_DBG,"OFF") generate
p_out_tst(31 downto 0)<=(others=>'0');
end generate gen_dbg_off;

gen_dbg_on : if strcmp(G_DBG,"ON") generate
ltstout:process(p_in_rst,p_in_clk)
begin
  if p_in_rst='1' then
    tst_fms_cs_dly<=(others=>'0');
    p_out_tst(31 downto 1)<=(others=>'0');
  elsif p_in_clk'event and p_in_clk='1' then

    tst_fms_cs_dly<=tst_fms_cs;
    p_out_tst(0)<=OR_reduce(tst_fms_cs_dly);
  end if;
end process ltstout;

tst_fms_cs<=CONV_STD_LOGIC_VECTOR(16#01#, tst_fms_cs'length) when fsm_state_cs=S_IDLE_SPDCFG else
            CONV_STD_LOGIC_VECTOR(16#02#, tst_fms_cs'length) when fsm_state_cs=S_READ_CH0 else
            CONV_STD_LOGIC_VECTOR(16#03#, tst_fms_cs'length) when fsm_state_cs=S_READ_CH0_DONE else
            CONV_STD_LOGIC_VECTOR(16#04#, tst_fms_cs'length) when fsm_state_cs=S_PAUSE_R0 else
            CONV_STD_LOGIC_VECTOR(16#05#, tst_fms_cs'length) when fsm_state_cs=S_READ_CH1 else
            CONV_STD_LOGIC_VECTOR(16#06#, tst_fms_cs'length) when fsm_state_cs=S_READ_CH1_DONE else
            CONV_STD_LOGIC_VECTOR(16#07#, tst_fms_cs'length) when fsm_state_cs=S_PAUSE_R1 else
            CONV_STD_LOGIC_VECTOR(16#08#, tst_fms_cs'length) when fsm_state_cs=S_WRITE_CH0 else
            CONV_STD_LOGIC_VECTOR(16#09#, tst_fms_cs'length) when fsm_state_cs=S_WRITE_CH0_DONE else
            CONV_STD_LOGIC_VECTOR(16#0A#, tst_fms_cs'length) when fsm_state_cs=S_PAUSE_W0 else
            CONV_STD_LOGIC_VECTOR(16#0B#, tst_fms_cs'length) when fsm_state_cs=S_WRITE_CH1 else
            CONV_STD_LOGIC_VECTOR(16#0C#, tst_fms_cs'length) when fsm_state_cs=S_WRITE_CH1_DONE else
            CONV_STD_LOGIC_VECTOR(16#0D#, tst_fms_cs'length) when fsm_state_cs=S_PAUSE_W1 else
            CONV_STD_LOGIC_VECTOR(16#0E#, tst_fms_cs'length) when fsm_state_cs=S_DRP_PROG_DONE else
            CONV_STD_LOGIC_VECTOR(16#0F#, tst_fms_cs'length) when fsm_state_cs=S_GTP_CH_RESET else
            CONV_STD_LOGIC_VECTOR(16#10#, tst_fms_cs'length) when fsm_state_cs=S_GTP_CH_RESET_DONE else
            CONV_STD_LOGIC_VECTOR(16#00#, tst_fms_cs'length); --//S_IDLE

end generate gen_dbg_on;


--//----------------------------------
--//Связь с Sata_Host
--//----------------------------------
p_out_spd_ver<=i_spd_ver_out;

p_out_gtp_rst     <= i_gtp_rst;
p_out_gtp_ch_rst  <= i_gtp_ch_rst;

p_out_gtp_drpaddr <= i_gtp_drp_addr;
p_out_gtp_drpen   <= i_gtp_drp_en;
p_out_gtp_drpwe   <= i_gtp_drp_we;
p_out_gtp_drpdi   <= i_gtp_drp_di;
i_gtp_drpdo       <= p_in_gtp_drpdo;
i_gtp_drprdy      <= p_in_gtp_drprdy;


----//----------------------------------
----//Логика управления
----//----------------------------------
--gen_ch : for i in 0 to C_GTCH_COUNT_MAX-1 generate
--  i_spd_change(i)<=p_in_ctrl(i).change;
--end generate gen_ch;
--
----//
--ltmr:process(p_in_rst,p_in_clk)
--begin
--  if p_in_rst='1' then
--    i_tmr<=(others=>'0');
--  elsif p_in_clk'event and p_in_clk='1' then
--    if i_tmr_en='1' then
--      i_tmr<=i_tmr+1;
--    else
--      i_tmr<= (others=>'0');
--    end if;
--  end if;
--end process ltmr;
--
----//Автомат программирования регистров GTP
--lfsm:process(p_in_rst,p_in_clk)
--begin
--  if p_in_rst='1' then
--
--    fsm_state_cs <= S_IDLE;
--
--    i_gtp_drp_addr <= (others=>'0');
--    i_gtp_drp_di   <= (others=>'0');
--    i_gtp_drp_en   <= '0';
--    i_gtp_drp_we   <= '0';
--
--    for i in 0 to i_gtp_drp_rdval'high loop
--    i_gtp_drp_rdval(i)<=(others=>'0');
--    end loop;
--    i_gtp_drp_regsel<=C_REG_PLL_RXDIVSEL;
--
--    i_gtp_ch_rst<=(others=>'0');
--    i_gtp_rst<='0';
--
--    for i in 0 to C_GTCH_COUNT_MAX-1 loop
--    i_spd_change_save(i)<='0';
--    i_spd_ver_out(i).change<='0';
--    i_spd_ver_out(i).sata_ver<=CONV_STD_LOGIC_VECTOR(C_FSATA_GEN_COUNT-1, i_spd_ver_out(i).sata_ver'length);
--    end loop;
--    i_tmr_en<='0';
--
--  elsif p_in_clk'event and p_in_clk='1' then
--
--    case fsm_state_cs is
--
--      when S_IDLE =>
--
----        if C_SATAH_COUNT_MAX=1 then
----        --//Используется только один компонент DUAL_GTP,то
----        --//изменять регистр REFCLK_SEL не имеет смысла.
----        --//Переходим к процессу установления соединения
--          fsm_state_cs <= S_IDLE_SPDCFG;
--
----        else
----        --//Используется несколько компонентов DUAL_GTP,
----          fsm_state_cs <= S_DRP_READ;
----
----        end if;
--
--
----      --//##################################################
----      --//Программирую CLOCK MUX компонента GTP
----      --//##################################################
----      when S_DRP_READ =>
----
----        i_gtp_drp_addr<=C_AREG_REFCLK_SEL;
----        i_gtp_drp_en<='1';
----        i_gtp_drp_we<='0';
----
----        fsm_state_cs <= S_DRP_READ_DONE;
----
----      when S_DRP_READ_DONE =>
----
----        if i_gtp_drprdy='1' then
----          i_gtp_drp_en           <='0';
----          i_gtp_drp_rdval(0) <= i_gtp_drpdo;
----
----          i_tmr_en<='1';
----          fsm_state_cs <= S_DRP_READ_PAUSE;
----        end if;
----
----      when S_DRP_READ_PAUSE =>
----
----        if i_tmr=CONV_STD_LOGIC_VECTOR(16#003#, i_tmr'length) then
----          i_tmr_en<='0';
----          fsm_state_cs <= S_DRP_WRITE;
----        end if;
----
----      when S_DRP_WRITE =>
----
----        i_gtp_drp_addr<=C_AREG_REFCLK_SEL;
----
----        if C_SATAH_NUM=0 then
----          --//Если общее кол-во модуле sata_host.vhd=1,то перепрограммирование блока Clock Muxing
----          --//не требуется
----
----          if   C_SATAH_COUNT_MAX=3 then
----            --//Если общее кол-во модуле sata_host.vhd=3,то
----            --// модуля sata_host.vhd с индексом 0
----            --//настраиваем так, чтобы входная частота подоваемая на DUAL_GTP модуля sata_host.vhd/IDX=0
----            --//передовалась на вывод CLKOUTSOUTH и CLKOUTNORTH блока Clock Muxing
----            --//см. ug196_Virtex-5 FPGA RocketIO GTP Transceiver User Guide.pdf/Appendix F/Figure F-1
----            i_gtp_drp_di(6 downto 0) <= i_gtp_drp_rdval(0)(6 downto 0);
----            i_gtp_drp_di(7)          <= '1';                               --//CLKSOUTH_SEL
----            i_gtp_drp_di(8)          <= '1';                               --//CLKNORTH_SEL
----            i_gtp_drp_di(15 downto 9)<= i_gtp_drp_rdval(0)(15 downto 9);
----
----          elsif C_SATAH_COUNT_MAX=2 then
----            --//Если общее кол-во модуле sata_host.vhd=2,то модуль sata_host.vhd с индексом 0
----            --//настраиваем так, чтобы входная частота подоваемая на DUAL_GTP модуля sata_host.vhd/IDX=0
----            --//передовалась на вывод CLKOUTSOUTH блока Clock Muxing
----            --//см. ug196_Virtex-5 FPGA RocketIO GTP Transceiver User Guide.pdf/Appendix F/Figure F-1
----            i_gtp_drp_di(6 downto 0) <= i_gtp_drp_rdval(0)(6 downto 0);
----            i_gtp_drp_di(7)          <= '1';                               --//CLKSOUTH_SEL
----            i_gtp_drp_di(8)          <= i_gtp_drp_rdval(0)(8);          --//CLKNORTH_SEL
----            i_gtp_drp_di(15 downto 9)<= i_gtp_drp_rdval(0)(15 downto 9);
----
----          end if;
----
----        elsif C_SATAH_NUM=1 then
----        --//Если модуль sata_host.vhd/IDX=1,то
----        --//тактирование компонента DUAL_GTP берем с линии CLKINSOUTH блока Clock Muxing
----        --//см. ug196_Virtex-5 FPGA RocketIO GTP Transceiver User Guide.pdf/Appendix F/Figure F-1
----          i_gtp_drp_di(3 downto 0) <= i_gtp_drp_rdval(0)(3 downto 0);
----          i_gtp_drp_di(6 downto 4) <= "100";
----          i_gtp_drp_di(15 downto 7)<= i_gtp_drp_rdval(0)(15 downto 7);
----
----        elsif C_SATAH_NUM=2 then
----        --//Если модуль sata_host.vhd/IDX=2,то
----        --//тактирование компонента DUAL_GTP берем с линии CLKOUTNORTH блока Clock Muxing
----        --//см. ug196_Virtex-5 FPGA RocketIO GTP Transceiver User Guide.pdf/Appendix F/Figure F-1
----          i_gtp_drp_di(3 downto 0) <= i_gtp_drp_rdval(0)(3 downto 0);
----          i_gtp_drp_di(6 downto 4) <= "101";
----          i_gtp_drp_di(15 downto 7)<= i_gtp_drp_rdval(0)(15 downto 7);
----
----        end if;
----
----        i_gtp_drp_en <= '1';
----        i_gtp_drp_we <= '1';
----        fsm_state_cs <= S_DRP_WRITE_DONE;
----
----      when S_DRP_WRITE_DONE =>
----
----        if i_gtp_drprdy='1' then
----          i_gtp_drp_en <= '0';
----          i_gtp_drp_we <= '0';
----
----          i_tmr_en<='1';
----          fsm_state_cs <= S_DRP_WRITE_PAUSE;--S_PAUSE_W0;
----        end if;
----
----      when S_DRP_WRITE_PAUSE =>
----
----        if i_tmr=CONV_STD_LOGIC_VECTOR(16#003#, i_tmr'length) then
----          i_tmr_en<='0';
----          fsm_state_cs <= S_GTP_RESET_START;
----        end if;
----
----      --//-------------------------------------------
----      --//Сброс DUAL_GTP
----      --//-------------------------------------------
----      when S_GTP_RESET_START =>
----        i_tmr_en<='1';
----        fsm_state_cs <= S_GTP_RESET_DONE;
----
----      when S_GTP_RESET_DONE =>
----
----        i_gtp_drp_addr <= (others=>'0');
----        i_gtp_drp_di   <= (others=>'0');
----        i_gtp_drp_en   <= '0';
----        i_gtp_drp_we   <= '0';
----
----        --//Генерю сброс для модуля RocketIO GTP
----        if i_tmr = CONV_STD_LOGIC_VECTOR(16#01F#, i_rst_cnt'length) then
----          i_tmr_en<='0';
----          i_gtp_rst<='0';
----          fsm_state_cs <= S_IDLE_SPDCFG;
----
----        elsif i_tmr = CONV_STD_LOGIC_VECTOR(16#0F#, i_rst_cnt'length) then
----          i_gtp_rst<='1';
----          fsm_state_cs <= S_GTP_RESET_DONE;
----
----        end if;
--
--
--
--      --//##################################################
--      --//Перестройка скорости соединения с SATA устройством
--      --//##################################################
--      when S_IDLE_SPDCFG =>
--
--        if p_in_gtp_pll_lock='0' or p_in_usr_dcm_lock='1' then
--          if i_spd_change/=(i_spd_change'range =>'0') then
--          --Ждем команды перестройки скорости соединения
--            i_spd_change_save<=i_spd_change;
--            fsm_state_cs <= S_READ_CH0;
--          end if;
--        end if;
--
--      --//-------------------------------------------
--      --//Канал CH0: Чтение регистра DRP
--      --//-------------------------------------------
--      when S_READ_CH0 =>
--
--        --//Читаю значения DRP регистров 0-ог канала. См. таблицу в шапке модуля sata_spd_ctrl.vhd
--        --GTP_0
--          if i_gtp_drp_regsel=C_REG_PLL_RXDIVSEL then
--            i_gtp_drp_addr<=C_AREG_PLL_RXDIVSEL_OUT(0);
--          else
--            i_gtp_drp_addr<=C_AREG_PLL_TXDIVSEL_OUT(0);
--          end if;
--
--          i_gtp_drp_en<='1';
--          i_gtp_drp_we<='0';
--          fsm_state_cs <= S_READ_CH0_DONE;
--
--      when S_READ_CH0_DONE =>
--
--        if i_gtp_drprdy='1' then
--          i_gtp_drp_en           <='0';
--          i_gtp_drp_rdval(0) <= i_gtp_drpdo;
--
--          i_tmr_en<='1';
--          fsm_state_cs <= S_PAUSE_R0;
--        end if;
--
--      when S_PAUSE_R0 =>
--
--        if i_tmr=CONV_STD_LOGIC_VECTOR(16#003#, i_tmr'length) then
--          i_tmr_en<='0';
--          fsm_state_cs <= S_READ_CH1;
--        end if;
--
--      --//-------------------------------------------
--      --//Канал CH1: Чтение регистра DRP
--      --//-------------------------------------------
--      when S_READ_CH1 =>
--        --//Читаю значения DRP регистров 1-ог канала. См. таблицу в шапке модуля sata_spd_ctrl.vhd
--        if i_gtp_drp_regsel=C_REG_PLL_RXDIVSEL then
--          i_gtp_drp_addr<=C_AREG_PLL_RXDIVSEL_OUT(1);
--        else
--          i_gtp_drp_addr<=C_AREG_PLL_TXDIVSEL_OUT(1);
--        end if;
--
--        i_gtp_drp_en<='1';
--        i_gtp_drp_we<='0';
--        fsm_state_cs <= S_READ_CH1_DONE;
--
--      when S_READ_CH1_DONE =>
--
--        if i_gtp_drprdy='1' then
--          i_gtp_drp_en           <='0';
--          i_gtp_drp_rdval(1) <= i_gtp_drpdo;
--
--          i_tmr_en<='1';
--          fsm_state_cs <= S_PAUSE_R1;
--        end if;
--
--      when S_PAUSE_R1 =>
--
--        if i_tmr=CONV_STD_LOGIC_VECTOR(16#003#, i_tmr'length) then
--          i_tmr_en<='0';
--          fsm_state_cs <= S_WRITE_CH0;
--        end if;
--
--      --//-------------------------------------------
--      --//Канал CH0: запись регистра DRP
--      --//-------------------------------------------
--      when S_WRITE_CH0 =>
--
--        --//Програмирую регистры DRP. См. таблицу в шапке модуля sata_spd_ctrl.vhd
--        --GTP_0
--        if i_gtp_drp_regsel=C_REG_PLL_RXDIVSEL then
--          i_gtp_drp_addr<=C_AREG_PLL_RXDIVSEL_OUT(0);
--
--          i_gtp_drp_di(1 downto 0) <= i_gtp_drp_rdval(0)(1 downto 0);
--          for i in 0 to C_FSATA_GEN_COUNT-1 loop
--            if p_in_ctrl(0).sata_ver=CONV_STD_LOGIC_VECTOR(i, p_in_ctrl(0).sata_ver'length) then
--              i_gtp_drp_di(2)<=C_VAL_PLL_DIVSEL_OUT(i);
--            end if;
--          end loop;
--          i_gtp_drp_di(15 downto 3)<= i_gtp_drp_rdval(0)(15 downto 3);
--
--        else
--          i_gtp_drp_addr<=C_AREG_PLL_TXDIVSEL_OUT(0);
--
--          i_gtp_drp_di(14 downto 0)<= i_gtp_drp_rdval(0)(14 downto 0);
--          for i in 0 to C_FSATA_GEN_COUNT-1 loop
--            if p_in_ctrl(0).sata_ver=CONV_STD_LOGIC_VECTOR(i, p_in_ctrl(0).sata_ver'length) then
--              i_gtp_drp_di(15)<=C_VAL_PLL_DIVSEL_OUT(i);
--            end if;
--          end loop;
--        end if;
--
--        i_gtp_drp_en <= '1';
--        i_gtp_drp_we <= '1';
--        fsm_state_cs <= S_WRITE_CH0_DONE;
--
--      when S_WRITE_CH0_DONE =>
--
--        if i_gtp_drprdy='1' then
--          i_gtp_drp_en <= '0';
--          i_gtp_drp_we <= '0';
--
--          i_tmr_en<='1';
--          fsm_state_cs <= S_PAUSE_W0;
--        end if;
--
--      when S_PAUSE_W0 =>
--
--        if i_tmr=CONV_STD_LOGIC_VECTOR(16#003#, i_tmr'length) then
--          i_tmr_en<='0';
--          fsm_state_cs <= S_WRITE_CH1;
--        end if;
--
--      --//-------------------------------------------
--      --//Канал CH1: запись регистра DRP
--      --//-------------------------------------------
--      when S_WRITE_CH1 =>
--
--        --//Програмирую регистры DRP. См. таблицу в шапке модуля sata_spd_ctrl.vhd
--        if i_gtp_drp_regsel=C_REG_PLL_RXDIVSEL then
--          i_gtp_drp_addr <= C_AREG_PLL_RXDIVSEL_OUT(1);
--
--          for i in 0 to C_FSATA_GEN_COUNT-1 loop
--            if p_in_ctrl(1).sata_ver=CONV_STD_LOGIC_VECTOR(i, p_in_ctrl(0).sata_ver'length) then
--              i_gtp_drp_di(0)<=C_VAL_PLL_DIVSEL_OUT(i);
--            end if;
--          end loop;
--          i_gtp_drp_di(15 downto 1)<= i_gtp_drp_rdval(1)(15 downto 1);
--
--        else
--          i_gtp_drp_addr<=C_AREG_PLL_TXDIVSEL_OUT(1);
--
--          i_gtp_drp_di(3 downto 0) <= i_gtp_drp_rdval(1)(3 downto 0);
--          for i in 0 to C_FSATA_GEN_COUNT-1 loop
--            if p_in_ctrl(1).sata_ver=CONV_STD_LOGIC_VECTOR(i, p_in_ctrl(0).sata_ver'length) then
--              i_gtp_drp_di(4)<=C_VAL_PLL_DIVSEL_OUT(i);
--            end if;
--          end loop;
--          i_gtp_drp_di(15 downto 5)<= i_gtp_drp_rdval(1)(15 downto 5);
--        end if;
--
--        i_gtp_drp_en <= '1';
--        i_gtp_drp_we <= '1';
--        fsm_state_cs <= S_WRITE_CH1_DONE;
--
--      when S_WRITE_CH1_DONE =>
--
--        if i_gtp_drprdy='1' then
--          i_gtp_drp_en <= '0';
--          i_gtp_drp_we <= '0';
--
--          i_tmr_en<='1';
--          fsm_state_cs <= S_PAUSE_W1;
--        end if;
--
--      when S_PAUSE_W1 =>
--
--        if i_tmr=CONV_STD_LOGIC_VECTOR(16#003#, i_tmr'length) then
--          i_tmr_en<='0';
--          fsm_state_cs <= S_DRP_PROG_DONE;
--        end if;
--
--      --//-------------------------------------------
--      --//Смотрим. записаны ли все регисты DRP
--      --//-------------------------------------------
--      when S_DRP_PROG_DONE =>
--
--        if i_gtp_drp_regsel=C_REG_PLL_TXDIVSEL then
--        --//Все регистры запрограммированы.
--        --//Переходим к процедуре сброса каналов DUAL_GTP
--          i_gtp_drp_regsel<=C_REG_PLL_RXDIVSEL;
--          i_tmr_en<='1';
--          fsm_state_cs <= S_GTP_CH_RESET;
--
--        else
--          i_gtp_drp_regsel<=C_REG_PLL_TXDIVSEL;
--          fsm_state_cs <= S_READ_CH0;
--
--        end if;
--
--      --//-------------------------------------------
--      --//Сброс каналов DUAL_GTP
--      --//-------------------------------------------
--      when S_GTP_CH_RESET =>
--
--        i_gtp_drp_addr <= (others=>'0');
--        i_gtp_drp_di   <= (others=>'0');
--        i_gtp_drp_en   <= '0';
--        i_gtp_drp_we   <= '0';
--
--        --//модуля RocketIO GTP и модулей sata_host
--        if i_tmr=CONV_STD_LOGIC_VECTOR(16#01F#, i_tmr'length) then
--          i_tmr_en<='0';
--          fsm_state_cs <= S_GTP_CH_RESET_DONE;
--
--        elsif i_tmr=CONV_STD_LOGIC_VECTOR(16#0F#, i_tmr'length) then
--
--          --//Формируем сброс канала
--          for i in 0 to i_spd_change_save'high loop
--            if i_spd_change_save(i)='0' then
--              i_gtp_ch_rst(i)<='1';
--            end if;
--          end loop;
--
--        end if;
--
--      when S_GTP_CH_RESET_DONE =>
--        i_gtp_ch_rst<=(others=>'0');
--        for i in 0 to C_GTCH_COUNT_MAX-1 loop
--        i_spd_ver_out(i).sata_ver<=p_in_ctrl(i).sata_ver;
--        end loop;
--        fsm_state_cs <= S_IDLE_SPDCFG;
--
--    end case;
--
--end if;
--end process lfsm;



--END MAIN
end behavioral;
