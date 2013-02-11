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
--use work.prj_def.all;
use work.clocks_pkg.all;
use work.prom_phypin_pkg.all;

entity flash_test_main is
port(
--------------------------------------------------
--Технологический порт
--------------------------------------------------
pin_out_led      : out   std_logic_vector(7 downto 0);
pin_out_tp       : out   std_logic_vector(1 downto 0);
pin_in_btn_N     : in    std_logic;
pin_in_btn_C     : in    std_logic;

-------------------------------
--PHY
-------------------------------
pin_in_prom     : in    TPromPhyIN;
pin_out_prom    : out   TPromPhyOUT;
pin_inout_prom  : inout TPromPhyINOUT;

--------------------------------------------------
--Reference clock
--------------------------------------------------
pin_in_refclk    : in    TRefClkPinIN
);
end flash_test_main;

architecture behavioral of flash_test_main is

constant CI_HOST_DWIDTH     : integer:=32;

constant CI_USR_CMD_ADR     : integer:=1;
constant CI_USR_CMD_DWR     : integer:=2;
constant CI_USR_CMD_DRD     : integer:=3;
constant CI_USR_CMD_DRD_CFI : integer:=4;
constant CI_USR_CMD_UNLOCK  : integer:=5;
constant CI_USR_CMD_ERASE   : integer:=6;

constant CI_TEST_ADR        : integer := 0;
constant CI_TEST_SIZE       : integer := 128 * 2;--(64*1024*2) * 2;--64KW * N

constant CI_DLY               : integer:=32;
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

component prom_ld is
generic(
G_HOST_DWIDTH : integer:=32
);
port(
p_in_tmr_en      : in    std_logic;
p_in_tmr_stb     : in    std_logic;

-------------------------------
--Связь с HOST
-------------------------------
p_out_host_rxd   : out   std_logic_vector(G_HOST_DWIDTH - 1 downto 0);
p_in_host_rd     : in    std_logic;
p_out_rxbuf_full : out   std_logic;
p_out_rxbuf_empty: out   std_logic;

p_in_host_txd    : in    std_logic_vector(G_HOST_DWIDTH - 1 downto 0);
p_in_host_wr     : in    std_logic;
p_out_txbuf_full : out   std_logic;
p_out_txbuf_empty: out   std_logic;

p_in_host_clk    : in    std_logic;

p_out_hirq       : out   std_logic;
p_out_herr       : out   std_logic;

-------------------------------
--PHY
-------------------------------
p_in_phy         : in    TPromPhyIN;
p_out_phy        : out   TPromPhyOUT;
p_inout_phy      : inout TPromPhyINOUT;

-------------------------------
--Технологический
-------------------------------
p_in_tst         : in    std_logic_vector(31 downto 0);
p_out_tst        : out   std_logic_vector(31 downto 0);

-------------------------------
--System
-------------------------------
p_in_clk         : in    std_logic;
p_in_rst         : in    std_logic
);
end component;

type TFsm_state is (
S_FLASH_IDLE  ,
S_FLASH_CFI_ADR   ,
S_FLASH_CFI_ADR_DONE,
S_FLASH_CFI_RD,
S_FLASH_CFI_RD_DONE,
S_FLASH_ADR   ,
S_FLASH_ADR_DONE,
--S_FLASH_UNLOCK,
--S_FLASH_UNLOCK_DONE,
--S_FLASH_ERASE ,
--S_FLASH_ERASE_DONE,
S_FLASH_DWR,
S_FLASH_DWR0,
S_FLASH_DWRN,
S_FLASH_DWR_DONE,
S_FLASH_DWR_DONE1,
S_FLASH_DRD,
S_FLASH_DRD_DONE,
S_FLASH_DONE
);
signal i_fsm_cs              : TFsm_state;

signal i_usr_rst             : std_logic;
signal i_usrclk_rst          : std_logic;
signal g_usrclk              : std_logic_vector(7 downto 0);
signal g_refclkopt           : std_logic_vector(3 downto 0);

signal i_hclk                : std_logic;
signal i_hrxbuf_di           : std_logic_vector(CI_HOST_DWIDTH - 1 downto 0);
signal i_hrxbuf_rd           : std_logic;
signal i_hrxbuf_full         : std_logic;
signal i_hrxbuf_empty        : std_logic;

signal i_htxbuf_full         : std_logic;
signal i_htxbuf_empty        : std_logic;
signal i_htxbuf_do           : std_logic_vector(CI_HOST_DWIDTH - 1 downto 0);
signal i_htxbuf_wr           : std_logic;

signal i_hirq                : std_logic;
signal i_herr                : std_logic;

signal sr_prom_start         : std_logic_vector(0 to 1);
signal i_prom_start          : std_logic;
signal i_prom_rst            : std_logic;
signal i_prom_clk            : std_logic;
signal i_prom_tst_in         : std_logic_vector(31 downto 0);
signal i_prom_tst_out        : std_logic_vector(31 downto 0);

signal sr_btn                : std_logic_vector(2 downto 0);
signal i_btn_debounce_en     : std_logic;
signal i_btn_debounce_cnt    : std_logic_vector(5 downto 0);
signal i_btn                 : std_logic;

signal i_test01_led          : std_logic;
signal i_t1ms                : std_logic;
signal tst_hrxbuf_empty      : std_logic;
signal i_txcnt               : std_logic_vector(23 downto 0);
signal sr_hirq               : std_logic;
signal sr_herr               : std_logic;

attribute keep : string;
attribute keep of i_hclk : signal is "true";
attribute keep of i_prom_clk : signal is "true";


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

i_prom_rst <= i_usrclk_rst or i_usr_rst;


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

i_hclk <= g_usrclk(0);--<= g_usrclk(1);
i_prom_clk <= g_usrclk(0);

--***********************************************************
--Блок обновления прошивки
--***********************************************************
m_prom : prom_ld
generic map(
G_HOST_DWIDTH => CI_HOST_DWIDTH
)
port map(
p_in_tmr_en      => '0',
p_in_tmr_stb     => '0',

-------------------------------
--Связь с HOST
-------------------------------
p_out_host_rxd    => i_hrxbuf_di,
p_in_host_rd      => i_hrxbuf_rd,
p_out_rxbuf_full  => i_hrxbuf_full,
p_out_rxbuf_empty => i_hrxbuf_empty,

p_in_host_txd     => i_htxbuf_do,
p_in_host_wr      => i_htxbuf_wr,
p_out_txbuf_full  => i_htxbuf_full,
p_out_txbuf_empty => i_htxbuf_empty,

p_in_host_clk     => i_hclk,

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
p_in_clk         => i_prom_clk,
p_in_rst         => i_prom_rst
);
i_prom_tst_in <= (others=>'0');

i_hrxbuf_rd <= not i_hrxbuf_empty;


--//#########################################
--//DBG
--//#########################################
pin_out_tp(0) <= i_herr;
pin_out_tp(1) <= OR_reduce(i_hrxbuf_di) or OR_reduce(i_prom_tst_out) or tst_hrxbuf_empty;

pin_out_led(0)<=i_test01_led;
pin_out_led(1)<=i_herr;
pin_out_led(2)<=i_hirq;
pin_out_led(3)<='0';
pin_out_led(4)<='0';
pin_out_led(5)<='0';
pin_out_led(6)<='0';
pin_out_led(7)<='0';

m_gt_03_test: fpga_test_01
generic map(
G_BLINK_T05   =>10#250#,
G_CLK_T05us   =>10#50#
)
port map(
p_out_test_led => i_test01_led,
p_out_test_done=> open,

p_out_1us      => open,
p_out_1ms      => i_t1ms,
-------------------------------
--System
-------------------------------
p_in_clk       => i_hclk,
p_in_rst       => i_usrclk_rst
);



process(i_prom_clk)
begin
  if rising_edge(i_prom_clk) then
    tst_hrxbuf_empty <= i_hrxbuf_empty;
  end if;
end process;


--Кнопка старт
process(i_prom_rst,i_hclk)
begin
  if i_prom_rst='1' then
    sr_btn <= (others=>'0');
    i_btn_debounce_en <= '0';
    i_btn_debounce_cnt <= (others=>'0');
    i_btn <= '0';

  elsif rising_edge(i_hclk) then
    sr_btn <= sr_btn(1 downto 0) & pin_in_btn_C;

    if XOR_reduce(sr_btn(2 downto 1)) = '1' then
      i_btn_debounce_en <= '1';
    elsif i_btn_debounce_en = '1' then
      if i_t1ms = '1' then
        if i_btn_debounce_cnt = CONV_STD_LOGIC_VECTOR(10, i_btn_debounce_cnt'length) then
          i_btn_debounce_en <= '0';
          i_btn_debounce_cnt <= (others=>'0');
          i_btn <= pin_in_btn_C;
        else
          i_btn_debounce_cnt <= i_btn_debounce_cnt + 1;
        end if;
      end if;
    end if;

  end if;
end process;


--Автомат управления
sr_hirq <= i_hirq;
sr_herr <= i_herr;

process(i_prom_rst,i_hclk)
begin
  if i_prom_rst='1' then
    i_fsm_cs <= S_FLASH_IDLE;
    i_prom_start <= '0';
    sr_prom_start <= (others=>'0');
    i_htxbuf_do <= (others=>'0');
    i_htxbuf_wr <= '0';
    i_txcnt <= (others=>'0');
--    sr_hirq <= '0';
--    sr_herr <= '0';

  elsif rising_edge(i_hclk) then

    sr_prom_start <= i_btn & sr_prom_start(0 to 0);
    i_prom_start <= sr_prom_start(0) and not sr_prom_start(1);

    case i_fsm_cs is

      when S_FLASH_IDLE =>

        if i_prom_start = '1' then
        i_fsm_cs <= S_FLASH_CFI_ADR;--S_FLASH_ADR;
        end if;

      -------------------------------
      --Testing Raad Data CFI
      -------------------------------
      when S_FLASH_CFI_ADR =>

        if i_htxbuf_empty = '1' and sr_herr = '0' then
          i_htxbuf_do(3 downto 0) <= CONV_STD_LOGIC_VECTOR(CI_USR_CMD_ADR, 4);
          i_htxbuf_do(31 downto 4) <= CONV_STD_LOGIC_VECTOR(16#27#, 28);
          i_htxbuf_wr <= '1';
          i_fsm_cs <= S_FLASH_CFI_ADR_DONE;
        end if;

      when S_FLASH_CFI_ADR_DONE =>

        i_htxbuf_wr <= '0';
        if i_htxbuf_empty = '1' and sr_hirq = '1' and sr_herr = '0' then
          if i_txcnt = CONV_STD_LOGIC_VECTOR(CI_DLY, i_txcnt'length) then
          i_txcnt <= (others=>'0');
          i_fsm_cs <= S_FLASH_CFI_RD;
          else
          i_txcnt <= i_txcnt + 1;
          end if;
        end if;

      ----------------------------------
      ---
      ----------------------------------
      when S_FLASH_CFI_RD =>

        if i_htxbuf_empty = '1' then
          i_htxbuf_do(3 downto 0) <= CONV_STD_LOGIC_VECTOR(CI_USR_CMD_DRD_CFI, 4);
          i_htxbuf_do(31 downto 4) <= CONV_STD_LOGIC_VECTOR(14, 28);--byte count
          i_htxbuf_wr <= '1';
          i_fsm_cs <= S_FLASH_CFI_RD_DONE;
        end if;

      when S_FLASH_CFI_RD_DONE =>

        i_htxbuf_wr <= '0';
        if i_htxbuf_empty = '1' and sr_hirq = '1' and sr_herr = '0' then
          if i_txcnt = CONV_STD_LOGIC_VECTOR(CI_DLY, i_txcnt'length) then
          i_txcnt <= (others=>'0');
          i_fsm_cs <= S_FLASH_ADR;
          else
          i_txcnt <= i_txcnt + 1;
          end if;
        end if;



      -------------------------------
      --Testing Write Data to Flash
      -------------------------------
      when S_FLASH_ADR =>

        if i_htxbuf_empty = '1' and sr_herr = '0' then
          i_htxbuf_do(3 downto 0) <= CONV_STD_LOGIC_VECTOR(CI_USR_CMD_ADR, 4);
          i_htxbuf_do(31 downto 4) <= CONV_STD_LOGIC_VECTOR(CI_TEST_ADR, 28);
          i_htxbuf_wr <= '1';
          i_fsm_cs <= S_FLASH_ADR_DONE;
        end if;

      when S_FLASH_ADR_DONE =>

        i_htxbuf_wr <= '0';
        if i_htxbuf_empty = '1' and sr_hirq = '1' and sr_herr = '0' then
          if i_txcnt = CONV_STD_LOGIC_VECTOR(CI_DLY, i_txcnt'length) then
          i_txcnt <= (others=>'0');
          i_fsm_cs <= S_FLASH_DWR;--S_FLASH_UNLOCK;
          else
          i_txcnt <= i_txcnt + 1;
          end if;
        end if;

--      ----------------------------------
--      ---
--      ----------------------------------
--      when S_FLASH_UNLOCK =>
--
--        if i_htxbuf_empty = '1' then
--          i_htxbuf_do(3 downto 0) <= CONV_STD_LOGIC_VECTOR(CI_USR_CMD_UNLOCK, 4);
--          i_htxbuf_do(31 downto 4) <= CONV_STD_LOGIC_VECTOR(CI_TEST_SIZE, 28);
--          i_htxbuf_wr <= '1';
--          i_fsm_cs <= S_FLASH_UNLOCK_DONE;
--        end if;
--
--      when S_FLASH_UNLOCK_DONE =>
--
--        i_htxbuf_wr <= '0';
--        if i_htxbuf_empty = '1' and sr_hirq = '1' and sr_herr = '0' then
--          if i_txcnt = CONV_STD_LOGIC_VECTOR(CI_DLY, i_txcnt'length) then
--          i_txcnt <= (others=>'0');
--          i_fsm_cs <= S_FLASH_ERASE;
--          else
--          i_txcnt <= i_txcnt + 1;
--          end if;
--        end if;
--
--      ----------------------------------
--      ---
--      ----------------------------------
--      when S_FLASH_ERASE =>
--
--        if i_htxbuf_empty = '1' then
--          i_htxbuf_do(3 downto 0) <= CONV_STD_LOGIC_VECTOR(CI_USR_CMD_ERASE, 4);
--          i_htxbuf_do(31 downto 4) <= CONV_STD_LOGIC_VECTOR(CI_TEST_SIZE, 28);
--          i_htxbuf_wr <= '1';
--          i_fsm_cs <= S_FLASH_ERASE_DONE;--S_FLASH_DONE;--S_FLASH_DWR;
--        end if;
--
--      when S_FLASH_ERASE_DONE =>
--
--        i_htxbuf_wr <= '0';
--        if i_htxbuf_empty = '1' and sr_hirq = '1' and sr_herr = '0' then
--          if i_txcnt = CONV_STD_LOGIC_VECTOR(CI_DLY, i_txcnt'length) then
--          i_txcnt <= (others=>'0');
--          i_fsm_cs <= S_FLASH_DWR;
--          else
--          i_txcnt <= i_txcnt + 1;
--          end if;
--        end if;


      ----------------------------------
      ---
      ----------------------------------
      when S_FLASH_DWR =>

        i_htxbuf_do(3 downto 0) <= CONV_STD_LOGIC_VECTOR(CI_USR_CMD_DWR, 4);
        i_htxbuf_do(31 downto 4) <= CONV_STD_LOGIC_VECTOR(CI_TEST_SIZE, 28);--(32*2, 28);--
        i_htxbuf_wr <= '1';
        i_fsm_cs <= S_FLASH_DWR0;

      when S_FLASH_DWR0 =>

        i_htxbuf_do(15 downto  0) <= CONV_STD_LOGIC_VECTOR(1, 16);
        i_htxbuf_do(31 downto 16) <= CONV_STD_LOGIC_VECTOR(2, 16);
        i_htxbuf_wr <= '1';
        if i_txcnt = CONV_STD_LOGIC_VECTOR(CI_TEST_SIZE/4 - 1, i_txcnt'length) then --if i_txcnt = CONV_STD_LOGIC_VECTOR((32*2)/4 - 1, i_txcnt'length) then
        i_txcnt <= (others=>'0');
        i_fsm_cs <= S_FLASH_DWR_DONE;
        else
        i_txcnt <= i_txcnt + 1;
        i_fsm_cs <= S_FLASH_DWRN;
        end if;

      when S_FLASH_DWRN =>

        if i_htxbuf_full = '0' then
          i_htxbuf_do(15 downto  0) <= i_htxbuf_do(15 downto  0) + 2;
          i_htxbuf_do(31 downto 16) <= i_htxbuf_do(31 downto 16) + 2;
          i_htxbuf_wr <= '1';
          if i_txcnt = CONV_STD_LOGIC_VECTOR(CI_TEST_SIZE/4 - 1, i_txcnt'length) then --if i_txcnt = CONV_STD_LOGIC_VECTOR((32*2)/4 - 1, i_txcnt'length) then
          i_txcnt <= (others=>'0');
          i_fsm_cs <= S_FLASH_DWR_DONE;
          else
          i_txcnt <= i_txcnt + 1;
          end if;
        else
          i_htxbuf_wr <= '0';
        end if;

      when S_FLASH_DWR_DONE =>

        i_htxbuf_wr <= '0';
        i_fsm_cs <= S_FLASH_DWR_DONE1;

      when S_FLASH_DWR_DONE1 =>

        i_htxbuf_wr <= '0';
        if i_htxbuf_empty = '1' and sr_hirq = '1' and sr_herr = '0' then
          if i_txcnt = CONV_STD_LOGIC_VECTOR(CI_DLY, i_txcnt'length) then
          i_txcnt <= (others=>'0');
          i_fsm_cs <= S_FLASH_DRD;
          else
          i_txcnt <= i_txcnt + 1;
          end if;
        end if;

      ----------------------------------
      ---
      ----------------------------------
      when S_FLASH_DRD =>

        if i_htxbuf_empty = '1' then
          i_htxbuf_do(3 downto 0) <= CONV_STD_LOGIC_VECTOR(CI_USR_CMD_DRD, 4);
          i_htxbuf_do(31 downto 4) <= CONV_STD_LOGIC_VECTOR(CI_TEST_SIZE, 28);
          i_htxbuf_wr <= '1';
          i_fsm_cs <= S_FLASH_DRD_DONE;--S_FLASH_DONE;--S_FLASH_DWR;
        end if;

      when S_FLASH_DRD_DONE =>

        i_htxbuf_wr <= '0';
        if i_htxbuf_empty = '1' and sr_hirq = '1' then
          if i_txcnt = CONV_STD_LOGIC_VECTOR(CI_DLY, i_txcnt'length) then
          i_txcnt <= (others=>'0');
          i_fsm_cs <= S_FLASH_DONE;
          else
          i_txcnt <= i_txcnt + 1;
          end if;
        end if;

      when S_FLASH_DONE =>

        i_htxbuf_wr <= '0';
        if sr_hirq = '1' then
          if i_txcnt = CONV_STD_LOGIC_VECTOR(CI_DLY, i_txcnt'length) then
          i_txcnt <= (others=>'0');
          i_fsm_cs <= S_FLASH_IDLE;
          else
          i_txcnt <= i_txcnt + 1;
          end if;
        end if;

    end case;
  end if;
end process;



--END MAIN
end behavioral;

