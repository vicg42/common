-------------------------------------------------------------------------
-- Company     : Yansar
-- Engineer    : Golovachenko Victor
--
-- Create Date : 25.07.2014 13:46:00
-- Module Name : mem_tester
--
-- Назначение/Описание : Настройки тестирования в файле mem_tester_def.vhd
--
-- Revision:
-- Revision 0.01 - File Created
--
-------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.reduce_pack.all;
use work.vicg_common_pkg.all;
use work.prj_cfg.all;
use work.mem_ctrl_pkg.all;
use work.mem_wr_pkg.all;
use work.pcie_pkg.all;
use work.clocks_pkg.all;

entity mem_tester is
port(
--------------------------------------------------
--Технологический порт
--------------------------------------------------
pin_out_TP2         : out   std_logic_vector(2 downto 0);
pin_out_led         : out   std_logic_vector(0 downto 0);
pin_in_btn          : in    std_logic;

--------------------------------------------------
--Memory banks
--------------------------------------------------
pin_out_phymem      : out   TMEMCTRL_pinouts;
pin_inout_phymem    : inout TMEMCTRL_pininouts;

--------------------------------------------------
--Reference clock
--------------------------------------------------
pin_in_refclk       : in    TRefclk_pinin
);
end entity mem_tester;

architecture struct of mem_tester is

constant CI_HDEV_DWIDTH  : integer := C_AXIM_DWIDTH;

type TMemRandomINIT is array (0 to 7) of std_logic_vector(15 downto 0);
constant CI_RANDOM_INIT : TMemRandomINIT := (
std_logic_vector(TO_UNSIGNED(16#F0F6# + 0, 16)),
std_logic_vector(TO_UNSIGNED(16#F0F6# + 32, 16)),
std_logic_vector(TO_UNSIGNED(16#F0F6# + 34, 16)),
std_logic_vector(TO_UNSIGNED(16#F0F6# + 44, 16)),
std_logic_vector(TO_UNSIGNED(16#F0F6# + 66, 16)),
std_logic_vector(TO_UNSIGNED(16#F0F6# + 86, 16)),
std_logic_vector(TO_UNSIGNED(16#F0F6# + 91, 16)),
std_logic_vector(TO_UNSIGNED(16#F0F6# + 13, 16))
);


component debounce is
generic(
G_PUSH_LEVEL : std_logic := '0'; --Лог. уровень когда кнопка нажата
G_DEBVAL : integer := 4
);
port(
p_in_btn  : in    std_logic;
p_out_btn : out   std_logic;

p_in_clk_en : in    std_logic;
p_in_clk    : in    std_logic
);
end component debounce;

component fpga_test_01
generic(
G_BLINK_T05   : integer:=10#125#; -- 1/2 периода мигания светодиода.(время в ms)
G_CLK_T05us   : integer:=10#1000# -- кол-во периодов частоты порта p_in_clk
                                  -- укладывающиес_ в 1/2 периода 1us
);
port(
p_out_test_led : out   std_logic;--мигание сведодиода
p_out_test_done: out   std_logic;--сигнал переходи в '1' через 3 сек.

p_out_1us      : out   std_logic;
p_out_1ms      : out   std_logic;
-------------------------------
--System
-------------------------------
p_in_clk       : in    std_logic;
p_in_rst       : in    std_logic
);
end component fpga_test_01;

component clocks is
port(
p_out_rst  : out   std_logic;
p_out_gclk : out   std_logic_vector(6 downto 0);

p_in_clk   : in    TRefclk_pinin
);
end component clocks;

component pcie2mem_ctrl is
generic(
G_MEM_AWIDTH     : integer:=32;
G_MEM_DWIDTH     : integer:=32;
G_MEM_BANK_M_BIT : integer:=29;
G_MEM_BANK_L_BIT : integer:=28
);
port(
-------------------------------
--Управление
-------------------------------
p_in_ctrl         : in    TPce2Mem_Ctrl;
p_out_status      : out   TPce2Mem_Status;

--host -> dev
p_in_htxbuf_di    : in   std_logic_vector(G_MEM_DWIDTH - 1 downto 0);
p_in_htxbuf_wr    : in   std_logic;
p_out_htxbuf_full : out  std_logic;
p_out_htxbuf_empty: out  std_logic;

--host <- dev
p_out_hrxbuf_do   : out  std_logic_vector(G_MEM_DWIDTH - 1 downto 0);
p_in_hrxbuf_rd    : in   std_logic;
p_out_hrxbuf_full : out  std_logic;
p_out_hrxbuf_empty: out  std_logic;

p_in_hclk         : in    std_logic;

-------------------------------
--Связь с mem_ctrl
-------------------------------
p_out_mem         : out   TMemIN;
p_in_mem          : in    TMemOUT;

-------------------------------
--Технологический
-------------------------------
p_in_tst          : in    std_logic_vector(31 downto 0);
p_out_tst         : out   std_logic_vector(31 downto 0);

-------------------------------
--System
-------------------------------
p_in_clk          : in    std_logic;
p_in_rst          : in    std_logic
);
end component pcie2mem_ctrl;

signal i_rst              : std_logic;
signal g_usrclk           : std_logic_vector(6 downto 0);
signal g_usr_highclk      : std_logic;
signal g_hmem_clk         : std_logic;
signal i_hmem_rst         : std_logic;

signal i_memin_ch         : TMemINCh;
signal i_memout_ch        : TMemOUTCh;
signal i_memin_bank       : TMemINBank;
signal i_memout_bank      : TMemOUTBank;

--signal i_arb_mem_rst      : std_logic;
--signal i_arb_memin        : TMemIN;
--signal i_arb_memout       : TMemOUT;
--signal i_arb_mem_tst_out  : std_logic_vector(31 downto 0);

signal i_mem_ctrl_status  : TMEMCTRL_status;
signal i_mem_ctrl_sysin   : TMEMCTRL_sysin;
signal i_mem_ctrl_sysout  : TMEMCTRL_sysout;

signal i_mem_txd_rnd_init : std_logic;
signal i_mem_txd_rnd_en   : std_logic;
type TMemRandomData is array (0 to (CI_HDEV_DWIDTH / 32))
                                    of std_logic_vector(31 downto 0);
signal i_mem_txd_rnd      : TMemRandomData;
signal sr_hmem_rxd_busy   : std_logic_vector(0 to 1) := (others => '0');

signal i_hmem_ctrl        : TPce2Mem_Ctrl;
signal i_hmem_status      : TPce2Mem_Status;
signal i_hmem_txd_busy    : std_logic := '0';
signal i_hmem_rxd_busy    : std_logic := '0';
signal i_hmem_txbuf_di    : std_logic_vector(CI_HDEV_DWIDTH - 1 downto 0);
signal i_hmem_txbuf_wr    : std_logic;
signal i_hmem_txbuf_full  : std_logic;
signal i_hmem_rxbuf_do    : std_logic_vector(CI_HDEV_DWIDTH - 1 downto 0);
signal i_hmem_rxbuf_rd    : std_logic;
signal i_hmem_rxbuf_empty : std_logic;
signal i_hmem_tst_out     : std_logic_vector(31 downto 0);

signal i_mem_adr          : unsigned(31 downto 0) := (others => '0');
signal i_mem_dlen_rq      : unsigned(i_hmem_ctrl.req_len'range) := (others => '0');
signal i_mem_dir          : std_logic := '0';
signal i_mem_start        : std_logic := '0';
signal i_mem_done         : std_logic := '0';
signal i_mem_test_err     : unsigned((CI_HDEV_DWIDTH / C_PCFG_TEST_TYPE_CNT) - 1 downto 0);
signal i_mem_test_rnd_err : unsigned((CI_HDEV_DWIDTH / i_mem_txd_rnd(0)'length) - 1 downto 0);
signal sr_mem_done        : unsigned(0 to 1) := (others => '0');
signal i_mem_dcnt         : unsigned(31 downto 0) := (others => '0');

type TMemTestData is array (0 to (CI_HDEV_DWIDTH / C_PCFG_TEST_TYPE_CNT))
                                    of unsigned(C_PCFG_TEST_TYPE_CNT - 1 downto 0);
signal i_mem_txd          : TMemTestData;
signal i_mem_rxd          : TMemTestData;
signal i_mem_rxd_rnd      : TMemRandomData;

type TFsm_memctrl is (
S_IDLE       ,
S_MEMWR_START,
S_MEMWR_BUSY ,
S_MEMWR_NXT,
S_MEMRD_START,
S_MEMRD_BUSY,
S_MEMRD_NXT
);
signal i_fsm_memctrl_cs   : TFsm_memctrl;

type TFsm_memd is (
S_IDLE    ,
S_TXBUF_WR,
S_RXBUF_RD,
S_ERR
);
signal i_fsm_memd_cs      : TFsm_memd;

signal i_test_led         : std_logic_vector(1 downto 0);
signal i_1ms              : std_logic;
signal i_btn_push         : std_logic;
signal sr_btn_push        : unsigned(0 to 1);
signal i_test_start       : std_logic := '0';
signal i_test_err         : std_logic := '0';
signal tst_mem_txd_rnd_init: std_logic := '0';

signal tst_fsm_memctrl_cs,tmp_fsm_memctrl_cs  : unsigned(2 downto 0);
signal tst_fsm_memd_cs,tmp_fsm_memd_cs        : unsigned(1 downto 0);
signal tst_hmem_rxbuf_rd    : std_logic;
signal tst_hmem_rxbuf_do    : std_logic_vector(CI_HDEV_DWIDTH - 1 downto 0);
signal tst_hmem_txbuf_full  : std_logic;
signal tst_hmem_rxbuf_empty : std_logic;

signal tst_rxbuf_empty      : std_logic;
signal tst_rxbuf_full       : std_logic;
signal tst_txbuf_empty      : std_logic;
signal tst_txbuf_full       : std_logic;


attribute keep : string;
attribute keep of g_usrclk : signal is "true";
attribute keep of g_usr_highclk : signal is "true";


--MAIN
begin


--***********************************************************
--Установка частот проекта:
--***********************************************************
m_clocks : clocks
port map(
p_out_rst  => i_rst,
p_out_gclk => g_usrclk,

p_in_clk   => pin_in_refclk
);

g_hmem_clk <= g_usrclk(6);

g_usr_highclk <= i_mem_ctrl_sysout.clk;
i_mem_ctrl_sysin.ref_clk <= g_usrclk(3);
i_mem_ctrl_sysin.clk <= g_usrclk(4);

i_mem_ctrl_sysin.rst <= i_rst;
i_hmem_rst <= not OR_reduce(i_mem_ctrl_status.rdy);


--***********************************************************
--
--***********************************************************
----Арбитр контроллера памяти
--m_mem_arb : mem_arb
--generic map(
--G_CH_COUNT   => C_MEM_ARB_CH_COUNT,
--G_MEM_AWIDTH => C_AXI_AWIDTH,
--G_MEM_DWIDTH => C_AXIM_DWIDTH
--)
--port map(
---------------------------------
----Связь с пользователями ОЗУ
---------------------------------
--p_in_memch  => i_memin_ch,
--p_out_memch => i_memout_ch,
--
---------------------------------
----Связь с mem_ctrl.vhd
---------------------------------
--p_out_mem   => i_arb_memin,
--p_in_mem    => i_arb_memout,
--
---------------------------------
----Технологический
---------------------------------
--p_in_tst    => (others=>'0'),
--p_out_tst   => i_arb_mem_tst_out,
--
---------------------------------
----System
---------------------------------
--p_in_clk    => g_usr_highclk,
--p_in_rst    => i_arb_mem_rst
--);

--Подключаем арбитра ОЗУ к соотв банку
--i_memin_bank(0) <= i_arb_memin;
--i_arb_memout    <= i_memout_bank(0);
i_memin_bank(0) <= i_memin_ch(0);
i_memout_ch(0)    <= i_memout_bank(0);

--Core Memory controller
m_mem_ctrl : mem_ctrl
generic map(
G_SIM => C_PCFG_SIM
)
port map(
------------------------------------
--User Post
------------------------------------
p_in_mem   => i_memin_bank,
p_out_mem  => i_memout_bank,

------------------------------------
--Memory physical interface
------------------------------------
p_out_phymem    => pin_out_phymem,
p_inout_phymem  => pin_inout_phymem,

------------------------------------
--Memory status
------------------------------------
p_out_status    => i_mem_ctrl_status,

------------------------------------
--System
------------------------------------
p_out_sys       => i_mem_ctrl_sysout,
p_in_sys        => i_mem_ctrl_sysin
);


--***********************************************************
--Технологический порт
--***********************************************************
pin_out_led(0) <= i_test_err;
pin_out_TP2(0) <= OR_reduce(i_hmem_tst_out) or OR_reduce(tst_fsm_memctrl_cs) or OR_reduce(tst_fsm_memd_cs);
pin_out_TP2(1) <= tst_hmem_rxbuf_rd or OR_reduce(tst_hmem_rxbuf_do) or tst_mem_txd_rnd_init;
pin_out_TP2(2) <= tst_hmem_txbuf_full or tst_hmem_rxbuf_empty
or tst_rxbuf_empty
or tst_rxbuf_full
or tst_txbuf_empty
or tst_txbuf_full;

m_led: fpga_test_01
generic map(
G_BLINK_T05   =>10#250#,
G_CLK_T05us   =>10#155#
)
port map(
p_out_test_led => i_test_led(0),
p_out_test_done=> open,

p_out_1us      => open,
p_out_1ms      => i_1ms,
-------------------------------
--System
-------------------------------
p_in_clk       => g_usrclk(1),
p_in_rst       => i_rst
);


m_button : debounce
generic map(
G_PUSH_LEVEL => '0',
G_DEBVAL => 4
)
port map(
p_in_btn  => pin_in_btn,
p_out_btn => i_btn_push,

p_in_clk_en => i_1ms,
p_in_clk    => g_usrclk(1)
);


--***********************************************************
--Модуль управления контроллером памяти
--***********************************************************
i_hmem_ctrl.dir       <= i_mem_dir;
i_hmem_ctrl.start     <= i_mem_start;
i_hmem_ctrl.adr       <= std_logic_vector(i_mem_adr);
i_hmem_ctrl.req_len   <= std_logic_vector(i_mem_dlen_rq);
i_hmem_ctrl.trnwr_len <= std_logic_vector(TO_UNSIGNED(C_PCFG_MEMWR_TRLEN, i_hmem_ctrl.trnwr_len'length));
i_hmem_ctrl.trnrd_len <= std_logic_vector(TO_UNSIGNED(C_PCFG_MEMRD_TRLEN, i_hmem_ctrl.trnrd_len'length));

process(g_hmem_clk)
begin
  if rising_edge(g_hmem_clk) then
    sr_mem_done <= i_hmem_status.done & sr_mem_done(0 to 0);
    i_mem_done <= sr_mem_done(0) and not sr_mem_done(1);
  end if;
end process;

i_hmem_txbuf_wr <= i_hmem_txd_busy and not i_hmem_txbuf_full;
i_hmem_rxbuf_rd <= i_hmem_rxd_busy and not i_hmem_rxbuf_empty;

gen_rnd_off : if C_PCFG_TEST_TYPE_RANDOM = '0' generate
gen_memdata : for i in 0 to (CI_HDEV_DWIDTH / C_PCFG_TEST_TYPE_CNT) - 1 generate
i_hmem_txbuf_di((i_mem_txd(i)'length * (i + 1)) - 1
                            downto (i_mem_txd(i)'length * i)) <= std_logic_vector(i_mem_txd(i));

i_mem_rxd(i) <= UNSIGNED(i_hmem_rxbuf_do((i_mem_rxd(i)'length * (i + 1)) - 1
                                                downto (i_mem_rxd(i)'length * i)));
end generate gen_memdata;
end generate gen_rnd_off;


gen_rnd_on : if C_PCFG_TEST_TYPE_RANDOM = '1' generate
gen_memdata : for i in 0 to (CI_HDEV_DWIDTH / i_mem_txd_rnd(0)'length) - 1 generate
i_hmem_txbuf_di((i_mem_txd_rnd(i)'length * (i + 1)) - 1
                            downto (i_mem_txd_rnd(i)'length * i)) <= i_mem_txd_rnd(i);

i_mem_rxd_rnd(i) <= i_hmem_rxbuf_do((i_mem_rxd_rnd(i)'length * (i + 1)) - 1
                                                downto (i_mem_rxd_rnd(i)'length * i));
end generate gen_memdata;

gen_rnd_d : for i in 0 to (CI_HDEV_DWIDTH / i_mem_txd_rnd(0)'length) - 1 generate
process(g_hmem_clk)
begin
if rising_edge(g_hmem_clk) then
  if i_mem_txd_rnd_init = '1' then
    i_mem_txd_rnd(i) <= srambler32_0(CI_RANDOM_INIT(i));
  else
    if i_mem_txd_rnd_en = '1' then
      i_mem_txd_rnd(i) <= srambler32_0(i_mem_txd_rnd(i)(31 downto 16));
    end if;
  end if;
end if;
end process;
end generate gen_rnd_d;

process(g_hmem_clk)
begin
  if rising_edge(g_hmem_clk)  then
    sr_hmem_rxd_busy <= i_hmem_rxd_busy & sr_hmem_rxd_busy(0 to 0);
  end if;
end process;

i_mem_txd_rnd_init <= i_test_start
                    or (sr_hmem_rxd_busy(0) and not sr_hmem_rxd_busy(1));
i_mem_txd_rnd_en <= i_hmem_txbuf_wr or i_hmem_rxbuf_rd;

end generate gen_rnd_on;


m_host2mem : pcie2mem_ctrl
generic map(
G_MEM_AWIDTH     => C_AXI_AWIDTH,
G_MEM_DWIDTH     => CI_HDEV_DWIDTH,
G_MEM_BANK_M_BIT => 31,
G_MEM_BANK_L_BIT => 30
)
port map(
-------------------------------
--HOST
-------------------------------
p_in_ctrl         => i_hmem_ctrl,
p_out_status      => i_hmem_status,

--host -> dev
p_in_htxbuf_di     => i_hmem_txbuf_di,
p_in_htxbuf_wr     => i_hmem_txbuf_wr,
p_out_htxbuf_full  => i_hmem_txbuf_full,
p_out_htxbuf_empty => open,

--host <- dev
p_out_hrxbuf_do    => i_hmem_rxbuf_do,
p_in_hrxbuf_rd     => i_hmem_rxbuf_rd,
p_out_hrxbuf_full  => open,
p_out_hrxbuf_empty => i_hmem_rxbuf_empty,

p_in_hclk          => g_hmem_clk,

-------------------------------
--MEM
-------------------------------
p_out_mem         => i_memin_ch(0), --DEV -> MEM
p_in_mem          => i_memout_ch(0),--DEV <- MEM

-------------------------------
--Технологический
-------------------------------
p_in_tst          => (others=>'0'),
p_out_tst         => i_hmem_tst_out,

-------------------------------
--System
-------------------------------
p_in_clk         => g_usr_highclk,
p_in_rst         => i_hmem_rst
);




--###############################################
--TESTING MEM
--###############################################
process(g_hmem_clk)
begin
  if rising_edge(g_hmem_clk) then
    sr_btn_push <= i_btn_push & sr_btn_push(0 to 0);
    i_test_start <= sr_btn_push(0) and not sr_btn_push(1);
  end if;
end process;

--Управление модулем pcie2mem_ctrl.vhd
mem_ctrl : process(g_hmem_clk)
begin
if rising_edge(g_hmem_clk) then
  if i_hmem_rst = '1' then

    i_fsm_memctrl_cs <= S_IDLE;

    i_mem_adr <= (others=>'0');
    i_mem_dlen_rq <= (others=>'0');
    i_mem_dir <= '0';
    i_mem_start <= '0';

  else

    case i_fsm_memctrl_cs is

      --------------------------------------
      --
      --------------------------------------
      when S_IDLE =>

        if i_test_start = '1' then
          i_mem_adr <= TO_UNSIGNED(C_PCFG_MEMADR_START, i_mem_adr'length);
          i_fsm_memctrl_cs <= S_MEMWR_START;
        end if;

      --------------------------------------
      --WRITE (весь массив данных (C_PCFG_MEMTEST_SIZE) записываем частями (C_PCFG_MEMWR_BURST))
      --------------------------------------
      when S_MEMWR_START =>

        i_mem_dlen_rq <= TO_UNSIGNED(C_PCFG_MEMWR_BURST, i_mem_dlen_rq'length);
        i_mem_dir <= C_MEMWR_WRITE;
        i_mem_start <= '1';
        i_fsm_memctrl_cs <= S_MEMWR_BUSY;

      when S_MEMWR_BUSY =>

        i_mem_start <= '0';

        if i_mem_done = '1' then

          i_mem_adr <= i_mem_adr + TO_UNSIGNED(C_PCFG_MEMWR_BURST, i_mem_adr'length);
          i_fsm_memctrl_cs <= S_MEMWR_NXT;

        end if;

      when S_MEMWR_NXT =>

        if i_mem_adr >= (TO_UNSIGNED(C_PCFG_MEMADR_START, i_mem_adr'length)
                          + TO_UNSIGNED(C_PCFG_MEMTEST_SIZE, i_mem_adr'length)) then

          i_mem_adr <= TO_UNSIGNED(C_PCFG_MEMADR_START, i_mem_adr'length);
          i_fsm_memctrl_cs <= S_MEMRD_START;

        else

          i_fsm_memctrl_cs <= S_MEMWR_START;

        end if;


      --------------------------------------
      --READ (вычитывваем необходимое кол-во данных (C_PCFG_MEMTEST_SIZE) частями (C_PCFG_MEMRD_BURST))
      --------------------------------------
      when S_MEMRD_START =>

        i_mem_dlen_rq <= TO_UNSIGNED(C_PCFG_MEMRD_BURST, i_mem_dlen_rq'length);
        i_mem_dir <= C_MEMWR_READ;
        i_mem_start <= '1';
        i_fsm_memctrl_cs <= S_MEMRD_BUSY;

      when S_MEMRD_BUSY =>

        i_mem_start <= '0';

        if i_mem_done = '1' then

          i_mem_adr <= i_mem_adr + TO_UNSIGNED(C_PCFG_MEMRD_BURST, i_mem_adr'length);
          i_fsm_memctrl_cs <= S_MEMRD_NXT;

        end if;

      when S_MEMRD_NXT =>

        if i_mem_adr >= (TO_UNSIGNED(C_PCFG_MEMADR_START, i_mem_adr'length)
                          + TO_UNSIGNED(C_PCFG_MEMTEST_SIZE, i_mem_adr'length)) then

          i_mem_adr <= TO_UNSIGNED(C_PCFG_MEMADR_START, i_mem_adr'length);
          i_fsm_memctrl_cs <= S_IDLE;

        else

          i_fsm_memctrl_cs <= S_MEMRD_START;

        end if;

    end case;

  end if;
end if;
end process mem_ctrl;


--Test data generater + checker read data
mem_data : process(g_hmem_clk)
begin
if rising_edge(g_hmem_clk) then
  if i_hmem_rst = '1' then

    i_fsm_memd_cs <= S_IDLE;
    i_hmem_txd_busy <= '0';
    i_hmem_rxd_busy <= '0';
    i_mem_test_err <= (others => '0');
    i_mem_test_rnd_err <= (others => '0');
    i_mem_dcnt <= (others =>'0');

    for i in 0 to (CI_HDEV_DWIDTH / C_PCFG_TEST_TYPE_CNT) - 1 loop
    i_mem_txd(i) <= TO_UNSIGNED(i, i_mem_txd(i)'length);
    end loop;

    i_test_err <= '0';

  else

    case i_fsm_memd_cs is

      --------------------------------------
      --
      --------------------------------------
      when S_IDLE =>

        if i_fsm_memctrl_cs = S_MEMWR_BUSY then

          if C_PCFG_TEST_TYPE_RANDOM = '0' then
          for i in 0 to (CI_HDEV_DWIDTH / C_PCFG_TEST_TYPE_CNT) - 1 loop
          i_mem_txd(i) <= TO_UNSIGNED(i, i_mem_txd(i)'length);
          end loop;
          end if;

          if i_hmem_txbuf_full = '0' then
            i_hmem_txd_busy <= '1';
            i_fsm_memd_cs <= S_TXBUF_WR;
          end if;
        end if;


      --------------------------------------
      --WRITE 2 MEM
      --------------------------------------
      when S_TXBUF_WR =>

        if i_hmem_txbuf_full = '0' then
          if i_mem_dcnt = (TO_UNSIGNED(C_PCFG_MEMTEST_SIZE / (CI_HDEV_DWIDTH / 8), i_mem_dcnt'length) - 1) then

            i_mem_dcnt <= (others => '0');

            if C_PCFG_TEST_TYPE_RANDOM = '0' then
            for i in 0 to (CI_HDEV_DWIDTH / C_PCFG_TEST_TYPE_CNT) - 1 loop
            i_mem_txd(i) <= TO_UNSIGNED(i, i_mem_txd(i)'length);
            end loop;
            end if;

            i_hmem_txd_busy <= '0';
            i_hmem_rxd_busy <= '1';

            i_fsm_memd_cs <= S_RXBUF_RD;

          else

            i_mem_dcnt <= i_mem_dcnt + 1;

            if C_PCFG_TEST_TYPE_RANDOM = '0' then
            for i in 0 to (CI_HDEV_DWIDTH / C_PCFG_TEST_TYPE_CNT) - 1 loop
            i_mem_txd(i) <= i_mem_txd(i)
                              + TO_UNSIGNED((CI_HDEV_DWIDTH / C_PCFG_TEST_TYPE_CNT), i_mem_txd(i)'length);
            end loop;
            end if;

          end if;
        end if;


      --------------------------------------
      --READ from MEM + CHECK
      --------------------------------------
      when S_RXBUF_RD =>

        if i_hmem_rxbuf_empty = '0' then
          if i_mem_dcnt = (TO_UNSIGNED(C_PCFG_MEMTEST_SIZE / (CI_HDEV_DWIDTH / 8), i_mem_dcnt'length) - 1) then

            i_mem_dcnt <= (others => '0');
            i_hmem_rxd_busy <= '0';
            i_fsm_memd_cs <= S_IDLE;

          else

            i_mem_dcnt <= i_mem_dcnt + 1;

            if C_PCFG_TEST_TYPE_RANDOM = '0' then
            for i in 0 to (CI_HDEV_DWIDTH / C_PCFG_TEST_TYPE_CNT) - 1 loop
            i_mem_txd(i) <= i_mem_txd(i)
                              + TO_UNSIGNED((CI_HDEV_DWIDTH / C_PCFG_TEST_TYPE_CNT), i_mem_txd(i)'length);
            end loop;

            for i in 0 to (CI_HDEV_DWIDTH / C_PCFG_TEST_TYPE_CNT) - 1 loop
              if i_mem_rxd(i) /= i_mem_txd(i) then
                i_mem_test_err(i) <= '1';
              else
                i_mem_test_err(i) <= '0';
              end if;
            end loop;

            if OR_reduce(i_mem_test_err) = '1' then
              i_fsm_memd_cs <= S_ERR;
            end if;
            end if;


            if C_PCFG_TEST_TYPE_RANDOM = '1' then
            for i in 0 to (CI_HDEV_DWIDTH / i_mem_txd_rnd(0)'length) - 1 loop
              if i_mem_rxd_rnd(i) /= i_mem_txd_rnd(i) then
                i_mem_test_rnd_err(i) <= '1';
              else
                i_mem_test_rnd_err(i) <= '0';
              end if;
            end loop;

            if OR_reduce(i_mem_test_rnd_err) = '1' then
              i_fsm_memd_cs <= S_ERR;
            end if;
            end if;

          end if;
        end if;

      when S_ERR =>

        i_test_err <= '1';
        i_fsm_memd_cs <= S_ERR;

    end case;

  end if;
end if;
end process mem_data;


------------------------------------
--DBG
------------------------------------
process(g_hmem_clk)
begin
  if rising_edge(g_hmem_clk)  then
    tst_fsm_memctrl_cs <= tmp_fsm_memctrl_cs;
    tst_fsm_memd_cs <= tmp_fsm_memd_cs;

    tst_hmem_rxbuf_rd <= i_hmem_rxbuf_rd;
    tst_hmem_rxbuf_do <= i_hmem_rxbuf_do;
    tst_mem_txd_rnd_init <= i_mem_txd_rnd_init;
  end if;
end process;

tmp_fsm_memctrl_cs <= TO_UNSIGNED(16#01#, tmp_fsm_memctrl_cs'length) when i_fsm_memctrl_cs = S_MEMWR_START   else
                      TO_UNSIGNED(16#02#, tmp_fsm_memctrl_cs'length) when i_fsm_memctrl_cs = S_MEMWR_BUSY    else
                      TO_UNSIGNED(16#03#, tmp_fsm_memctrl_cs'length) when i_fsm_memctrl_cs = S_MEMWR_NXT     else
                      TO_UNSIGNED(16#04#, tmp_fsm_memctrl_cs'length) when i_fsm_memctrl_cs = S_MEMRD_START   else
                      TO_UNSIGNED(16#05#, tmp_fsm_memctrl_cs'length) when i_fsm_memctrl_cs = S_MEMRD_BUSY    else
                      TO_UNSIGNED(16#06#, tmp_fsm_memctrl_cs'length) when i_fsm_memctrl_cs = S_MEMRD_NXT     else
                      TO_UNSIGNED(16#00#, tmp_fsm_memctrl_cs'length);--when i_fsm_memctrl_cs = S_IDLE          else

tmp_fsm_memd_cs <= TO_UNSIGNED(16#01#, tmp_fsm_memd_cs'length) when i_fsm_memd_cs = S_TXBUF_WR   else
                   TO_UNSIGNED(16#02#, tmp_fsm_memd_cs'length) when i_fsm_memd_cs = S_RXBUF_RD   else
                   TO_UNSIGNED(16#03#, tmp_fsm_memd_cs'length) when i_fsm_memd_cs = S_ERR        else
                   TO_UNSIGNED(16#00#, tmp_fsm_memd_cs'length);--when i_fsm_memd_cs = S_IDLE


process(g_hmem_clk)
begin
  if rising_edge(g_hmem_clk)  then
    tst_hmem_txbuf_full   <= i_hmem_txbuf_full;
    tst_hmem_rxbuf_empty  <= i_hmem_rxbuf_empty;
  end if;
end process;

process(g_usr_highclk)
begin
  if rising_edge(g_usr_highclk)  then
    tst_rxbuf_empty <= i_hmem_tst_out(6);-- <= i_rxbuf_empty;
    tst_rxbuf_full  <= i_hmem_tst_out(7);-- <= i_rxbuf_full;
    tst_txbuf_empty <= i_hmem_tst_out(8);-- <= i_txbuf_empty;
    tst_txbuf_full  <= i_hmem_tst_out(9);-- <= i_txbuf_full;
  end if;
end process;




--END MAIN
end architecture struct;
