-------------------------------------------------------------------------
-- Company     : Linkos
-- Engineer    : Golovachenko Victor
--
-- Create Date : 03.12.2011 15:42:59
-- Module Name : eth_mdio
--
-- Назначение/Описание :
-- Запись/Чтение регистров внешного PHY уровня Eth
-- через Managment Interface (MDIO,MDC)
--
-------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_misc.all;
use ieee.std_logic_unsigned.all;

library work;
use work.vicg_common_pkg.all;
use work.eth_pkg.all;

entity eth_mdio is
generic(
G_DIV : integer:=2; --Делитель частоты p_in_clk. Нужен для формирования сигнала MDC
G_DBG : string:="OFF";
G_SIM : string:="OFF"
);
port(
--------------------------------------
--Управление
--------------------------------------
p_in_cfg_start : in    std_logic;
p_in_cfg_wr    : in    std_logic; --C_ETH_MDIO_WR(RD) - значение констант см. eth_pkg.vhd
p_in_cfg_aphy  : in    std_logic_vector(4 downto 0);
p_in_cfg_areg  : in    std_logic_vector(4 downto 0);
p_in_cfg_txd   : in    std_logic_vector(15 downto 0);
p_out_cfg_rxd  : out   std_logic_vector(15 downto 0);
p_out_cfg_done : out   std_logic;

--------------------------------------
--Eth PHY (Managment Interface)
--------------------------------------
p_inout_mdio   : inout  std_logic;
p_out_mdc      : out    std_logic;

--------------------------------------------------
--Технологические сигналы
--------------------------------------------------
p_in_tst       : in    std_logic_vector(31 downto 0);
p_out_tst      : out   std_logic_vector(31 downto 0);

--------------------------------------
--SYSTEM
--------------------------------------
p_in_clk       : in    std_logic;
p_in_rst       : in    std_logic
);
end eth_mdio;

architecture behavioral of eth_mdio is

constant CI_PREAMBULE : integer:=32;

type TEth_fsm_mdio is (
S_IDLE,
S_LD_PREAMBULE,
S_TX_PREAMBULE,
S_TX_CTRL,
S_DATA,
S_RxD_LATCH,
S_EXIT
);
signal fsm_ethmdio_cs: TEth_fsm_mdio;

signal i_tmr_cnt       : integer range 0 to G_DIV-1;

signal i_mdio_done     : std_logic;
signal i_mdio_dir      : std_logic;
signal i_mdio_aphy     : std_logic_vector(4 downto 0);
signal i_mdio_areg     : std_logic_vector(4 downto 0);
signal i_mdio_txd      : std_logic_vector(15 downto 0);
signal i_mdio_rxd      : std_logic_vector(15 downto 0):=(others=>'0');

signal i_bitcnt        : std_logic_vector(5 downto 0):=(others=>'0');--Счетчик Tx/Rx битов

signal i_txd_ld        : std_logic;
signal i_txd_en        : std_logic;
signal i_txd           : std_logic_vector(15 downto 0);
signal sr_txd          : std_logic_vector(15 downto 0):=(others=>'0'); --Сдиговый регистр отправки данных
signal i_rxd_en        : std_logic;
signal i_rxd_latch     : std_logic;
signal sr_rxd          : std_logic_vector(15 downto 0):=(others=>'0'); --Сдиговый регистр приема данных
signal sr_en           : std_logic;

signal i_mdc           : std_logic:='0';

signal tst_fms_cs      : std_logic_vector(2 downto 0);
signal tst_fms_cs_dly  : std_logic_vector(tst_fms_cs'range);


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
    p_out_tst(31 downto 2)<=(others=>'0');
  elsif p_in_clk'event and p_in_clk='1' then

    tst_fms_cs_dly<=tst_fms_cs;
    p_out_tst(0)<=i_rxd_en;
    p_out_tst(1)<=OR_reduce(tst_fms_cs_dly);
  end if;
end process ltstout;

tst_fms_cs<=CONV_STD_LOGIC_VECTOR(16#01#, tst_fms_cs'length) when fsm_ethmdio_cs=S_LD_PREAMBULE  else
            CONV_STD_LOGIC_VECTOR(16#02#, tst_fms_cs'length) when fsm_ethmdio_cs=S_TX_PREAMBULE  else
            CONV_STD_LOGIC_VECTOR(16#03#, tst_fms_cs'length) when fsm_ethmdio_cs=S_TX_CTRL       else
            CONV_STD_LOGIC_VECTOR(16#04#, tst_fms_cs'length) when fsm_ethmdio_cs=S_DATA          else
            CONV_STD_LOGIC_VECTOR(16#05#, tst_fms_cs'length) when fsm_ethmdio_cs=S_EXIT          else
            CONV_STD_LOGIC_VECTOR(16#00#, tst_fms_cs'length);-- when fsm_ethmdio_cs=S_IDLE         else

end generate gen_dbg_on;


--//-------------------------------------------
--//Автомат управления
--//-------------------------------------------
process(p_in_rst,p_in_clk)
begin
  if p_in_rst='1' then
    fsm_ethmdio_cs<=S_IDLE;

    i_mdio_dir <='0';
    i_mdio_aphy<=(others=>'0');
    i_mdio_areg<=(others=>'0');
    i_mdio_txd<=(others=>'0');
    i_mdio_done<='0';

    i_rxd_en<='0';
    i_txd_en<='0';
    i_txd_ld<='0';
    i_txd<=(others=>'0');
    i_bitcnt<=(others=>'0');
    i_rxd_latch<='0';

  elsif p_in_clk'event and p_in_clk='1' then

      case fsm_ethmdio_cs is

        --------------------------------------
        --
        --------------------------------------
        when S_IDLE =>

          i_mdio_done<='0';

          if p_in_cfg_start='1' then

            i_mdio_dir <=p_in_cfg_wr;
            i_mdio_aphy<=p_in_cfg_aphy;
            i_mdio_areg<=p_in_cfg_areg;
            i_mdio_txd <=p_in_cfg_txd;

            fsm_ethmdio_cs<=S_LD_PREAMBULE;

          end if;

        --------------------------------------
        --
        --------------------------------------
        when S_LD_PREAMBULE =>

          if sr_en='1' and i_mdc='1' then
            i_txd_ld<='1';
            i_txd<=(others=>'1');
            i_bitcnt<=CONV_STD_LOGIC_VECTOR(0, i_bitcnt'length);
            fsm_ethmdio_cs<=S_TX_PREAMBULE;
          end if;

        when S_TX_PREAMBULE =>

          if sr_en='1' and i_mdc='1' then
            if i_bitcnt=CONV_STD_LOGIC_VECTOR(CI_PREAMBULE-1, i_bitcnt'length) then
              i_txd_en<='1';
              i_txd_ld<='1';
              i_txd(15 downto 14)<="01";          --Start
              i_txd(13)          <=not i_mdio_dir;--opcode(1);--//"10" -Read
              i_txd(12)          <=    i_mdio_dir;--opcode(0);--//"01" -Write
              i_txd(11 downto 7) <=i_mdio_aphy;
              i_txd(6 downto 2)  <=i_mdio_areg;
              i_txd(1 downto 0)  <="10";          --TA
              i_bitcnt<=CONV_STD_LOGIC_VECTOR(0, i_bitcnt'length);
              fsm_ethmdio_cs<=S_TX_CTRL;

            else
              i_txd_en<='1';
              i_txd_ld<='0';
              i_bitcnt<=i_bitcnt + 1;
            end if;
          end if;

        --------------------------------------
        --
        --------------------------------------
        when S_TX_CTRL =>

          if sr_en='1' and i_mdc='1' then
            if i_bitcnt=CONV_STD_LOGIC_VECTOR(16-1, i_bitcnt'length) then
              i_txd_en<=i_mdio_dir;
              i_txd_ld<=i_mdio_dir;
              i_txd<=i_mdio_txd;
              i_bitcnt<=CONV_STD_LOGIC_VECTOR(0, i_bitcnt'length);
              fsm_ethmdio_cs<=S_DATA;

            elsif i_mdio_dir='0' and i_bitcnt>=CONV_STD_LOGIC_VECTOR(15-1, i_bitcnt'length) then
              i_txd_en<='0';
              i_bitcnt<=i_bitcnt + 1;

            else
              i_txd_en<='1';
              i_txd_ld<='0';
              i_bitcnt<=i_bitcnt + 1;
            end if;
          end if;

        --------------------------------------
        --
        --------------------------------------
        when S_DATA =>

          if sr_en='1' and i_mdc='1' then
            if i_bitcnt=CONV_STD_LOGIC_VECTOR(16-1, i_bitcnt'length) then
              i_txd_en<=i_mdio_dir;
              i_bitcnt<=CONV_STD_LOGIC_VECTOR(0, i_bitcnt'length);
              fsm_ethmdio_cs<=S_RxD_LATCH;
            else
              i_rxd_en<=not i_mdio_dir;
              i_txd_en<=i_mdio_dir;
              i_txd_ld<='0';
              i_bitcnt<=i_bitcnt + 1;
            end if;
          end if;

        when S_RxD_LATCH =>

          if sr_en='1' and i_mdc='1' then
            i_rxd_en<='0';
            i_txd_en<='0';
            i_rxd_latch<='1';
            fsm_ethmdio_cs<=S_EXIT;
          end if;

        --------------------------------------
        --Перед завершением операции выдер
        --------------------------------------
        when S_EXIT =>

          i_rxd_latch<='0';
          if sr_en='1' and i_mdc='1' then
            if i_bitcnt=CONV_STD_LOGIC_VECTOR(32-1, i_bitcnt'length) then
              i_bitcnt<=CONV_STD_LOGIC_VECTOR(0, i_bitcnt'length);
              i_mdio_done<='1';
              fsm_ethmdio_cs<=S_IDLE;
            else
              i_bitcnt<=i_bitcnt + 1;
            end if;
          end if;

      end case;

  end if;
end process;

--//Делитель для генерации MDC
process(p_in_rst,p_in_clk)
begin
  if p_in_rst='1' then
    i_tmr_cnt<=0;
    sr_en<='0';
  elsif p_in_clk'event and p_in_clk='1' then
    if i_tmr_cnt=G_DIV-1 then
      i_tmr_cnt<=0;
      sr_en<='1';
    else
      i_tmr_cnt<=i_tmr_cnt + 1;
      sr_en<='0';
    end if;

    if sr_en='1' then
      i_mdc<=not i_mdc;
    end if;
  end if;
end process;

--//Отправка данных
process(p_in_clk)
begin
  if p_in_clk'event and p_in_clk='1' then
    if sr_en='1' and i_mdc='1' then
      if i_txd_ld='1' then
        sr_txd<=i_txd;
      else
        sr_txd<=sr_txd(sr_txd'length-2 downto 0)&'1';
      end if;
    end if;
  end if;
end process;

--//Прием данных
process(p_in_clk)
begin
  if p_in_clk'event and p_in_clk='1' then
    if sr_en='1' and i_mdc='0' then
      if i_rxd_en='1' then
        sr_rxd<=sr_rxd(sr_rxd'length-2 downto 0)&p_inout_mdio;
      end if;
    end if;
  end if;
end process;

process(p_in_clk)
begin
  if p_in_clk'event and p_in_clk='1' then
    if i_rxd_latch='1' then
      i_mdio_rxd<=sr_rxd;
    end if;
  end if;
end process;

p_out_cfg_rxd<=i_mdio_rxd;
p_out_cfg_done<=i_mdio_done;


--//Managment Interface
p_inout_mdio<=sr_txd(15) when i_txd_en='1' else 'Z';
p_out_mdc<=i_mdc;


--END MAIN
end behavioral;
