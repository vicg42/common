-------------------------------------------------------------------------
-- Company     : Linkos
-- Engineer    : Golovachenko Victor
--
-- Create Date : 11/11/2009
-- Module Name : BMD_INTR_CTRL.vhd
--
-- Description : Endpoint Intrrupt Controller
--               Подробно работа с перываниями CORE PCIEXPRESS описана в
--               pcie_blk_plus_ug341.pdf/п. Generating Interrupt Requests
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
use work.prj_def.all;

entity BMD_INTR_CTRL is
port
(
--//Пользовательское управление
p_in_init_rst                 : in   std_logic;                    --//Переход в исходное состояние
p_in_irq_clr                  : in   std_logic;                    --//Сброс прерывания
p_in_irq_src_adr              : in   std_logic_vector(15 downto 0);--//Номер источника прерывания
p_in_irq_src_set              : in   std_logic_vector(15 downto 0);--//Установка прерывания
p_out_irq_src_act             : out  std_logic_vector(15 downto 0);--//Статус активности перываний

--//Связь с ядром PCI-EXPRESS
p_in_cfg_msi_enable           : in   std_logic;
p_in_cfg_interrupt_rdy_n      : in   std_logic;
p_out_cfg_interrupt_di        : out  std_logic_vector(7 downto 0);
p_out_cfg_interrupt_assert_n  : out  std_logic;
p_out_cfg_interrupt_n         : out  std_logic;

--//Технологические сигналы
p_in_tst_ctrl                 : in  std_logic_vector(3 downto 0);
p_out_tst                     : out std_logic_vector(4 downto 0);

--//SYSTEM
p_in_clk             : in   std_logic;
p_in_rst_n           : in   std_logic
);
end BMD_INTR_CTRL;

architecture behavioral of BMD_INTR_CTRL is

component BMD_INTR_CTRL_DEV
generic(
G_TIME_DLY   : integer:=0
);
port
(
--//Пользовательское управление
p_in_init_rst                 : in   std_logic;
p_in_irq_set                  : in   std_logic;
p_in_irq_clr                  : in   std_logic;
p_out_irq_status_act          : out  std_logic;

--//Связь с ядром PCI-EXPRESS
p_in_cfg_msi_enable           : in   std_logic;
p_out_cfg_interrupt_di        : out  std_logic_vector(7 downto 0);
p_in_cfg_interrupt_rdy_n      : in   std_logic;
p_out_cfg_interrupt_assert_n  : out  std_logic;
p_out_cfg_interrupt_n         : out  std_logic;

--//Технологические сигналы
p_out_tst                     : out std_logic_vector(4 downto 0);

--//SYSTEM
p_in_clk             : in   std_logic;
p_in_rst_n           : in   std_logic
);
end component;

Type TTimeDly is array (0 to C_HIRQ_COUNT_MAX-1) of integer;

constant C_TIMEDLY : TTimeDly:=(
8,
12,
0,
2,
6,
9,
4,
14,
16,
3,
7,
1,
5,
11,
10,
15
);

--constant C_HIRQ_PCIEXP_DMA_RD                     : integer:=1;--//TRN: PC->FPGA
--constant C_HIRQ_TMR0                              : integer:=2;
--constant C_HIRQ_ETH_RXBUF                         : integer:=3;
--constant C_HIRQ_DEVCFG_RXBUF                      : integer:=4;
--constant C_HIRQ_HDD_CMDDONE                       : integer:=5;
--constant C_HIRQ_VIDEO_CH0                         : integer:=6;
--constant C_HIRQ_VIDEO_CH1                         : integer:=7;
--constant C_HIRQ_VIDEO_CH2                         : integer:=8;
--constant C_HIRQ_TRACK                             : integer:=9;

signal i_cfg_interrupt_n           : std_logic_vector(15 downto 0);
signal i_cfg_interrupt_assert_n    : std_logic_vector(15 downto 0);
signal i_irq_src_clr               : std_logic_vector(15 downto 0);

Type TIrqTST is array (0 to C_HIRQ_COUNT-1) of std_logic_vector(4 downto 0);
signal i_tst_out                   : TIrqTST;

--//MAIN
begin

--//Технологические сигналы
----p_out_tst<=i_tst_out(8) when p_in_tst_ctrl="1000" else
----           i_tst_out(7) when p_in_tst_ctrl="0111" else
----           i_tst_out(6) when p_in_tst_ctrl="0110" else
----           i_tst_out(5) when p_in_tst_ctrl="0101" else
----           i_tst_out(4) when p_in_tst_ctrl="0100" else
--p_out_tst<=i_tst_out(3) when p_in_tst_ctrl="0011" else
--           i_tst_out(2) when p_in_tst_ctrl="0010" else
--           i_tst_out(1) when p_in_tst_ctrl="0001" else
--           i_tst_out(0);

p_out_tst(0)<='0';--i_tst_out(C_HIRQ_VIDEO_CH0)(0) or i_tst_out(C_HIRQ_VIDEO_CH1)(0);
p_out_tst(4 downto 1)<=(others=>'0');



--//Связь с ядром PCI-EXPRESS
--//16#00# - PCI_EXPRESS_LEGACY_INTD
--//16#00# - PCI_EXPRESS_LEGACY_INTC
--//16#00# - PCI_EXPRESS_LEGACY_INTB
--//16#00# - PCI_EXPRESS_LEGACY_INTA
p_out_cfg_interrupt_di       <= CONV_STD_LOGIC_VECTOR(16#00#, 8);
p_out_cfg_interrupt_n        <= AND_reduce(i_cfg_interrupt_n(C_HIRQ_COUNT - 1 downto 0));
p_out_cfg_interrupt_assert_n <= AND_reduce(i_cfg_interrupt_assert_n(C_HIRQ_COUNT - 1 downto 0));

--//Управление работой соответствующего канала прерывания
LB_CH: for i in 0 to C_HIRQ_COUNT - 1 generate
begin

--//Назначаем флаг гашения перывания для выбраного канала перерывания
i_irq_src_clr(i)<=p_in_irq_clr when p_in_irq_src_adr(C_HIRQ_COUNT - 1 downto 0)=i else '0';

--//Автомат управления прерыванием соотв. канала перерывания
m_BMD_INTR_CTRL_DEV : BMD_INTR_CTRL_DEV
generic map(
G_TIME_DLY   => C_TIMEDLY(i)
)
port map
(
--//Пользовательское управление
p_in_init_rst                 => p_in_init_rst,
p_in_irq_set                  => p_in_irq_src_set(i),
p_in_irq_clr                  => i_irq_src_clr(i),
p_out_irq_status_act          => p_out_irq_src_act(i),

--//Связь с ядром PCI-EXPRESS
p_in_cfg_msi_enable           => p_in_cfg_msi_enable,
p_out_cfg_interrupt_di        => open,
p_in_cfg_interrupt_rdy_n      => p_in_cfg_interrupt_rdy_n,
p_out_cfg_interrupt_assert_n  => i_cfg_interrupt_assert_n(i),
p_out_cfg_interrupt_n         => i_cfg_interrupt_n(i),

--//Технологические сигналы
p_out_tst                     => i_tst_out(i),

--//SYSTEM
p_in_clk             => p_in_clk,
p_in_rst_n           => p_in_rst_n
);

end generate LB_CH;

--END MAIN
end behavioral;




