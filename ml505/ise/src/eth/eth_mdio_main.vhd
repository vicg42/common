-------------------------------------------------------------------------
-- Company     : Linkos
-- Engineer    : Golovachenko Victor
--
-- Create Date : 04.12.2011 12:46:13
-- Module Name : eth_mdio_main
--
-- Назначение/Описание :
-- Логика работы c Eth PHY через интерфейс MDIO
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
use work.eth_pkg.all;

entity eth_mdio_main is
generic(
G_PHYADR : integer:=16#07#;
G_DIV : integer:=2; --Делитель частоты p_in_clk. Нужен для формирования сигнала MDC
G_DBG : string:="OFF";
G_SIM : string:="OFF"
);
port(
--------------------------------------
--Управление
--------------------------------------
p_in_start     : in    std_logic;

p_out_done     : out   std_logic;
p_out_err      : out   std_logic;
p_out_link     : out   std_logic;
p_out_change   : out   std_logic;
p_in_change    : in    std_logic;

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
end eth_mdio_main;

architecture behavioral of eth_mdio_main is

--Register Map:
constant CI_RPHY_CTRL       : integer:=0;--Глобальное управление
constant CI_RPHY_IDENTIFIER : integer:=3;
constant CI_RPHY_STATUS     : integer:=1;--Статус для Eth Copper
constant CI_RPHY_SCTRL      : integer:=20;--Управление RGMII

--CI_RPHY_IDENTIFIER BitMap:
constant CI_PHY_ID : std_logic_vector(11 downto 0):="000011001100";--ID for chip Marvel 88E1111


component eth_mdio
generic(
G_DIV : integer:=2;
G_DBG : string:="OFF";
G_SIM : string:="OFF"
);
port(
--------------------------------------
--Управление
--------------------------------------
p_in_cfg_start : in    std_logic;
p_in_cfg_wr    : in    std_logic;
p_in_cfg_aphy  : in    std_logic_vector(4 downto 0);
p_in_cfg_areg  : in    std_logic_vector(4 downto 0);
p_in_cfg_txd   : in    std_logic_vector(15 downto 0);
p_out_cfg_rxd  : out   std_logic_vector(15 downto 0);
p_out_cfg_done : out   std_logic;

--------------------------------------
--Связь с PHY
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
end component;

type TEth_fsm_mdioctrl is (
S_IDLE,
S_PHY_ID_RD,
S_PHY_SCTRL_RD,
S_PHY_SCTRL_RD_DONE,
S_PHY_SCTRL_WR,
S_PHY_SCTRL_WR_DONE,
S_PHY_CTRL_RD,
S_PHY_CTRL_RD_DONE,
S_PHY_CTRL_WR,
S_PHY_CTRL_WR_DONE,
S_PHY_STATUS_RD,
S_PHY_STATUS_RD_DONE
);
signal fsm_ethmio_ctrl_cs: TEth_fsm_mdioctrl;

signal i_tmr_cnt       : integer range 0 to G_DIV-1;

signal i_mdio_start    : std_logic;
signal i_mdio_wr       : std_logic;
signal i_mdio_aphy     : std_logic_vector(4 downto 0);
signal i_mdio_areg     : std_logic_vector(4 downto 0);
signal i_mdio_done     : std_logic;
signal i_mdio_txd      : std_logic_vector(15 downto 0);
signal i_mdio_rxd      : std_logic_vector(15 downto 0);

signal i_err           : std_logic;
signal i_link          : std_logic;

signal i_change_done   : std_logic;

signal tst_fms_cs      : std_logic_vector(3 downto 0);
signal tst_fms_cs_dly  : std_logic_vector(3 downto 0);
signal i_tst_out       : std_logic_vector(31 downto 0);

--MAIN
begin

--//----------------------------------
--//Технологические сигналы
--//----------------------------------
gen_dbg_off : if strcmp(G_DBG,"OFF") generate
p_out_tst(0)<=OR_reduce(i_mdio_rxd);
p_out_tst(31 downto 1)<=(others=>'0');
end generate gen_dbg_off;

gen_dbg_on : if strcmp(G_DBG,"ON") generate
ltstout:process(p_in_rst,p_in_clk)
begin
  if p_in_rst='1' then
    tst_fms_cs_dly<=(others=>'0');
    p_out_tst(31 downto 2)<=(others=>'0');
  elsif p_in_clk'event and p_in_clk='1' then

    tst_fms_cs_dly<=tst_fms_cs;
    p_out_tst(0)<=OR_reduce(tst_fms_cs_dly) or i_tst_out(0) or i_tst_out(1);
  end if;
end process ltstout;

tst_fms_cs<=CONV_STD_LOGIC_VECTOR(16#01#, tst_fms_cs'length) when fsm_ethmio_ctrl_cs=S_PHY_ID_RD           else
            CONV_STD_LOGIC_VECTOR(16#02#, tst_fms_cs'length) when fsm_ethmio_ctrl_cs=S_PHY_STATUS_RD       else
            CONV_STD_LOGIC_VECTOR(16#03#, tst_fms_cs'length) when fsm_ethmio_ctrl_cs=S_PHY_STATUS_RD_DONE  else
            CONV_STD_LOGIC_VECTOR(16#04#, tst_fms_cs'length) when fsm_ethmio_ctrl_cs=S_PHY_SCTRL_RD        else
            CONV_STD_LOGIC_VECTOR(16#05#, tst_fms_cs'length) when fsm_ethmio_ctrl_cs=S_PHY_SCTRL_RD_DONE   else
            CONV_STD_LOGIC_VECTOR(16#06#, tst_fms_cs'length) when fsm_ethmio_ctrl_cs=S_PHY_SCTRL_WR        else
            CONV_STD_LOGIC_VECTOR(16#07#, tst_fms_cs'length) when fsm_ethmio_ctrl_cs=S_PHY_SCTRL_WR_DONE   else
            CONV_STD_LOGIC_VECTOR(16#08#, tst_fms_cs'length) when fsm_ethmio_ctrl_cs=S_PHY_CTRL_RD         else
            CONV_STD_LOGIC_VECTOR(16#09#, tst_fms_cs'length) when fsm_ethmio_ctrl_cs=S_PHY_CTRL_RD_DONE    else
            CONV_STD_LOGIC_VECTOR(16#0A#, tst_fms_cs'length) when fsm_ethmio_ctrl_cs=S_PHY_CTRL_WR         else
            CONV_STD_LOGIC_VECTOR(16#0B#, tst_fms_cs'length) when fsm_ethmio_ctrl_cs=S_PHY_CTRL_WR_DONE    else
            CONV_STD_LOGIC_VECTOR(16#00#, tst_fms_cs'length);-- when fsm_ethmio_ctrl_cs=S_IDLE             else

end generate gen_dbg_on;


p_out_done<=i_mdio_done;
p_out_err <=i_err;
p_out_link<=i_link;
p_out_change<=i_change_done;

--//-------------------------------------------
--//Автомат управления
--//-------------------------------------------
process(p_in_rst,p_in_clk)
begin
  if p_in_rst='1' then
    fsm_ethmio_ctrl_cs<=S_IDLE;

    i_mdio_start<='0';
    i_mdio_wr<='0';
    i_mdio_aphy<=(others=>'0');
    i_mdio_areg<=(others=>'0');
    i_mdio_txd <=(others=>'0');

    i_err<='0';
    i_link<='0';
    i_change_done<='0';

  elsif p_in_clk'event and p_in_clk='1' then

    case fsm_ethmio_ctrl_cs is

      --------------------------------------
      --
      --------------------------------------
      when S_IDLE =>

        if p_in_start='1' then
          i_mdio_start<='1';
          i_mdio_wr<=C_ETH_MDIO_RD;
          i_mdio_aphy<=CONV_STD_LOGIC_VECTOR(G_PHYADR,i_mdio_aphy'length);
          i_mdio_areg<=CONV_STD_LOGIC_VECTOR(CI_RPHY_IDENTIFIER,i_mdio_areg'length);
          i_mdio_txd <=CONV_STD_LOGIC_VECTOR(16#0000#,i_mdio_txd'length);

          fsm_ethmio_ctrl_cs<=S_PHY_ID_RD;
        end if;

      when S_PHY_ID_RD =>

        i_mdio_start<='0';
        if i_mdio_done='1' then
          if i_mdio_rxd(15 downto 4)/=CI_PHY_ID then
            i_err<='1';
            fsm_ethmio_ctrl_cs<=S_IDLE;
          else
            i_err<='0';
            fsm_ethmio_ctrl_cs<=S_PHY_SCTRL_RD;--Переходим к установке парвметров для интерфейса с PHY (GMII/RGMII/SGMII)
          end if;
        end if;

      --------------------------------------
      --Управление для RGMII
      --------------------------------------
      when S_PHY_SCTRL_RD =>

        if p_in_start='1' then
          i_mdio_start<='1';
          i_mdio_wr<=C_ETH_MDIO_RD;
          i_mdio_aphy<=CONV_STD_LOGIC_VECTOR(G_PHYADR,i_mdio_aphy'length);
          i_mdio_areg<=CONV_STD_LOGIC_VECTOR(CI_RPHY_SCTRL,i_mdio_areg'length);
          i_mdio_txd <=CONV_STD_LOGIC_VECTOR(16#0000#,i_mdio_txd'length);

          fsm_ethmio_ctrl_cs<=S_PHY_SCTRL_RD_DONE;
        end if;

      when S_PHY_SCTRL_RD_DONE =>

        i_mdio_start<='0';
        if i_mdio_done='1' then
          fsm_ethmio_ctrl_cs<=S_PHY_SCTRL_WR;
        end if;

      when S_PHY_SCTRL_WR =>

        if p_in_start='1' then
          i_mdio_start<='1';
          i_mdio_wr<=C_ETH_MDIO_WR;
          i_mdio_aphy<=CONV_STD_LOGIC_VECTOR(G_PHYADR,i_mdio_aphy'length);
          i_mdio_areg<=CONV_STD_LOGIC_VECTOR(CI_RPHY_SCTRL,i_mdio_areg'length);

          i_mdio_txd(15)<=i_mdio_rxd(15);
          i_mdio_txd(14)<='0';--1/0 - Enable/Disable Loopback
          i_mdio_txd(13 downto 8)<=i_mdio_rxd(13 downto 8);
          i_mdio_txd(7)<='1';--1 - Add delay to RX_CLK for RxD output
          i_mdio_txd(6 downto 4)<=i_mdio_rxd(6 downto 4);
          i_mdio_txd(3 downto 2)<=i_mdio_rxd(3 downto 2);
          i_mdio_txd(1)<='1';--1 - Add delay to GTX_CLK for TxD output
          i_mdio_txd(0)<='1';--1/0 - Transmiter disable/enable

          fsm_ethmio_ctrl_cs<=S_PHY_SCTRL_WR_DONE;
        end if;

      when S_PHY_SCTRL_WR_DONE =>

        i_mdio_start<='0';
        if i_mdio_done='1' then
          i_change_done<='1';

          fsm_ethmio_ctrl_cs<=S_PHY_CTRL_RD;
        end if;


      --------------------------------------
      --Общее управление
      --------------------------------------
      when S_PHY_CTRL_RD =>

        if p_in_start='1' then
          i_mdio_start<='1';
          i_mdio_wr<=C_ETH_MDIO_RD;
          i_mdio_aphy<=CONV_STD_LOGIC_VECTOR(G_PHYADR,i_mdio_aphy'length);
          i_mdio_areg<=CONV_STD_LOGIC_VECTOR(CI_RPHY_CTRL,i_mdio_areg'length);
          i_mdio_txd <=CONV_STD_LOGIC_VECTOR(16#0000#,i_mdio_txd'length);

          fsm_ethmio_ctrl_cs<=S_PHY_CTRL_RD_DONE;
        end if;

      when S_PHY_CTRL_RD_DONE =>

        i_mdio_start<='0';
        if i_mdio_done='1' then
          fsm_ethmio_ctrl_cs<=S_PHY_CTRL_WR;
        end if;

      when S_PHY_CTRL_WR =>

        if p_in_start='1' then
          i_mdio_start<='1';
          i_mdio_wr<=C_ETH_MDIO_WR;
          i_mdio_aphy<=CONV_STD_LOGIC_VECTOR(G_PHYADR,i_mdio_aphy'length);
          i_mdio_areg<=CONV_STD_LOGIC_VECTOR(CI_RPHY_CTRL,i_mdio_areg'length);
          i_mdio_txd(15)<='1';--SW_RESET
          i_mdio_txd(14 downto 0)<=i_mdio_rxd(14 downto 0);

          fsm_ethmio_ctrl_cs<=S_PHY_CTRL_WR_DONE;
        end if;

      when S_PHY_CTRL_WR_DONE =>

        i_mdio_start<='0';
        if i_mdio_done='1' then
          i_change_done<='1';
           fsm_ethmio_ctrl_cs<=S_PHY_STATUS_RD;
        end if;


      --------------------------------------
      --Read STATUS (!!!for ETH copper)
      --------------------------------------
      when S_PHY_STATUS_RD =>

        if p_in_start='1' then
          i_mdio_start<='1';
          i_mdio_wr<=C_ETH_MDIO_RD;
          i_mdio_aphy<=CONV_STD_LOGIC_VECTOR(G_PHYADR,i_mdio_aphy'length);
          i_mdio_areg<=CONV_STD_LOGIC_VECTOR(CI_RPHY_STATUS,i_mdio_areg'length);
          i_mdio_txd <=CONV_STD_LOGIC_VECTOR(16#0000#,i_mdio_txd'length);

          fsm_ethmio_ctrl_cs<=S_PHY_STATUS_RD_DONE;
        end if;

      when S_PHY_STATUS_RD_DONE =>

        i_mdio_start<='0';
        if i_mdio_done='1' then
          i_link<=i_mdio_rxd(2);
          fsm_ethmio_ctrl_cs<=S_PHY_STATUS_RD;
        end if;
    end case;
  end if;
end process;


m_mdio : eth_mdio
generic map (
G_DIV => G_DIV,
G_DBG => G_DBG,
G_SIM => G_SIM
)
port map(
--------------------------------------
--Управление
--------------------------------------
p_in_cfg_start => i_mdio_start,
p_in_cfg_wr    => i_mdio_wr,
p_in_cfg_aphy  => i_mdio_aphy,
p_in_cfg_areg  => i_mdio_areg,
p_in_cfg_txd   => i_mdio_txd,
p_out_cfg_rxd  => i_mdio_rxd,
p_out_cfg_done => i_mdio_done,

--------------------------------------
--Связь с PHY
--------------------------------------
p_inout_mdio   => p_inout_mdio,
p_out_mdc      => p_out_mdc,

--------------------------------------------------
--Технологические сигналы
--------------------------------------------------
p_in_tst       => (others=>'0'),
p_out_tst      => i_tst_out,

--------------------------------------
--SYSTEM
--------------------------------------
p_in_clk       => p_in_clk,
p_in_rst       => p_in_rst
);


--END MAIN
end behavioral;
