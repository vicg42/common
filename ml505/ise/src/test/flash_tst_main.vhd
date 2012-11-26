-------------------------------------------------------------------------
-- Company     : Linkos
-- Engineer    : Golovachenko Victor
--
-- Create Date : 25.11.2012 14:08:21
-- Module Name : flash_tst_main
--
-- Назначение/Описание :
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

library work;
use work.vicg_common_pkg.all;
use work.prj_cfg.all;
use work.prj_def.all;
use work.clocks_pkg.all;
use work.prom_phypin_pkg.all;

entity flash_tst_main is
port(
--------------------------------------------------
--Технологический порт
--------------------------------------------------
pin_out_led      : out   std_logic_vector(7 downto 0);
pin_out_tp       : out   std_logic_vector(0 downto 0);
pin_in_btn_N     : in    std_logic;

-------------------------------
--PHY
-------------------------------
p_in_phy         : in    TPromPhyIN;
p_out_phy        : out   TPromPhyOUT;
p_inout_phy      : inout TPromPhyINOUT;

--------------------------------------------------
--Reference clock
--------------------------------------------------
pin_in_refclk    : in    TRefClkPinIN
);
end flash_tst_main;

architecture behavioral of flash_tst_main is

constant CI_USR_CMD_ADR_START : integer:=0;
constant CI_USR_CMD_ADR_END   : integer:=1;
constant CI_USR_CMD_UNLOCK    : integer:=2;
constant CI_USR_CMD_ERASE     : integer:=3;
constant CI_USR_CMD_WRITE     : integer:=4;


constant CI_TX_DLY            : integer:=1024;

component fpga_test_01
generic(
G_BLINK_T05   : integer:=10#125#; -- 1/2 периода мигания светодиода.(время в ms)
G_CLK_T05us   : integer:=10#1000# -- кол-во периодов частоты порта p_in_clk
                                  -- укладывающиес_ в 1/2 периода 1us
);
port(
p_out_test_led : out   std_logic;--//мигание сведодиода
p_out_test_done: out   std_logic;--//сигнал переходи в '1' через 3 сек.

p_out_1us      : out   std_logic;
p_out_1ms      : out   std_logic;
-------------------------------
--System
-------------------------------
p_in_clk       : in    std_logic;
p_in_rst       : in    std_logic
);
end component;

component clocks
port(
p_out_rst  : out   std_logic;
p_out_gclk : out   std_logic_vector(7 downto 0);

p_in_clkopt: in    std_logic_vector(3 downto 0);
p_in_clk   : in    TRefClkPinIN
);
end component;

signal i_usr_rst             : std_logic;
signal i_usrclk_rst          : std_logic;
signal g_usrclk              : std_logic_vector(7 downto 0);
signal g_refclkopt           : std_logic_vector(3 downto 0);

signal i_test01_led          : std_logic;

signal i_hrxbuf_di           : std_logic_vector(31 downto 0);
signal i_hrxbuf_rd           : std_logic;
signal i_hrxbuf_full         : std_logic;
signal i_hrxbuf_empty        : std_logic;

signal i_htxbuf_full         : std_logic;
signal i_htxbuf_empty        : std_logic;
signal i_htxbuf_do           : std_logic_vector(31 downto 0);
signal i_htxbuf_wr           : std_logic;

signal i_hirq                : std_logic;
signal i_herr                : std_logic;

signal i_prom_tst_in         : std_logic_vector(31 downto 0);
signal i_prom_tst_out        : std_logic_vector(31 downto 0);

signal i_dlycnt              : std_logic_vector(15 downto 0);


--MAIN
begin

--***********************************************************
--//RESET модулей
--***********************************************************
gen_ml505 : if strcmp(C_PCFG_BOARD,"ML505") generate
i_usr_rst <= pin_in_btn_N;
end generate gen_ml505;

gen_htgv6 : if strcmp(C_PCFG_BOARD,"HTGV6") generate
i_usr_rst <= not pin_in_btn_N;
end generate gen_htgv6;

i_prom_rst<=i_usrclk_rst or i_usr_rst;


--***********************************************************
--Установка частот проекта:
--***********************************************************
m_clocks : clocks
port map(
p_out_rst  => i_usrclk_rst,
p_out_gclk => g_usrclk,

p_in_clkopt=> g_refclkopt,
p_in_clk   => pin_in_refclk
);


--***********************************************************
--Блок обновления прошивки
--***********************************************************
m_prom : prom_ld
port map(
-------------------------------
--Связь с HOST
-------------------------------
p_out_host_rxd    => i_hrxbuf_di,
p_in_host_rd      => i_hrxbuf_rd,
p_out_rxbuf_full  => i_hrxbuf_full,
p_out_rxbuf_empty => i_hrxbuf_empty,

p_out_txbuf_full  => i_htxbuf_full,
p_out_txbuf_empty => i_htxbuf_empty,
p_in_host_txd     => i_htxbuf_do,
p_in_host_wr      => i_htxbuf_wr,

p_in_host_clk     => g_usrclk(0), --200MHz

p_out_hirq        => i_hirq,
p_out_herr        => i_herr,

-------------------------------
--PHY
-------------------------------
p_in_phy         => pin_in_prom,
p_out_phy        => pin_out_prom,
p_inout_phy      => pin_inout_prom,

-------------------------------
--Технологический
-------------------------------
p_in_tst         => i_prom_tst_in,
p_out_tst        => i_prom_tst_out,

-------------------------------
--System
-------------------------------
p_in_clk         => g_usrclk(2),--100MHz
p_in_rst         => i_prom_rst
);
i_prom_tst_in <= (others=>'0');


--//#########################################
--//DBG
--//#########################################
pin_out_led(0)<=i_test01_led;
pin_out_led(1)<=i_hirq;
pin_out_led(2)<='0';
pin_out_led(3)<='0';
pin_out_led(4)<='0';
pin_out_led(5)<='0';
pin_out_led(6)<='0';
pin_out_led(7)<='0';

m_gt_03_test: fpga_test_01
generic map(
G_BLINK_T05   =>10#250#,
G_CLK_T05us   =>10#75#
)
port map(
p_out_test_led => i_test01_led,
p_out_test_done=> open,

p_out_1us      => open,
p_out_1ms      => i_t1ms,
-------------------------------
--System
-------------------------------
p_in_clk       => g_usrclk(0),
p_in_rst       => i_usrclk_rst
);


pin_out_tp(0) <= i_herr;


process(i_prom_rst,g_usrclk)
begin
  if i_prom_rst='1' then
    i_fsm_cs <= S_IDLE;

    i_htxbuf_do <= (others=>'0');
    i_htxbuf_wr <= '0';

    i_dlycnt <= (others=>'0');

  elsif g_usrclk(0)'event and g_usrclk(0)='1' then

    case i_fsm_cs is

      --
      when S_IDLE =>

        if i_htxbuf_empty = '1' then
          i_htxbuf_do(31 downto 8) <= (others=>'0');
          i_htxbuf_do(7 downto 0) <= CONV_STD_LOGIC_VECTOR(CI_USR_CMD_ADR_START, 8);
          i_htxbuf_wr <= '1';
          i_fsm_cs <= S_SET_ADR_S;
        end if;

      when S_SET_ADR_S =>

        i_htxbuf_wr <= '0';

        if i_htxbuf_wr = '0' then
          if i_hirq = '1' then
            i_htxbuf_do(31 downto 8) <= (others=>'0');
            i_htxbuf_do(7 downto 0) <= CONV_STD_LOGIC_VECTOR(CI_USR_CMD_ADR_END, 8);
            i_htxbuf_wr <= '1';
            i_fsm_cs <= S_SET_ADR_E;
          end if;
        end if;


      when S_TX_DELAY =>

        i_htxbuf_wr <= '0';

        if i_t1ms = '1' then
          if i_dlycnt = CONV_STD_LOGIC_VECTOR(CI_TX_DLY-1, i_dlycnt'length) then
            i_dlycnt <= (others=>'0');
            i_fsm_cs <= S_IDLE;
          else
            i_dlycnt <= i_dlycnt + 1;
          end if;
        end if;

    end case;
  end if;
end process;


--END MAIN
end behavioral;

