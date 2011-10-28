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
port(
-----------------------------
--Usr Ctrl
-----------------------------
p_in_irq_clr          : in   std_logic;                    --//Сброс прерывания
p_in_irq_num          : in   std_logic_vector(15 downto 0);--//Номер источника прерывания
p_in_irq_set          : in   std_logic_vector(15 downto 0);--//Установка прерывания
p_out_irq_status      : out  std_logic_vector(15 downto 0);--//Статус активности перываний

-----------------------------
--Связь с ядром PCI-EXPRESS
-----------------------------
p_in_cfg_irq_dis       : in   std_logic;
p_in_cfg_msi           : in   std_logic;
p_in_cfg_irq_rdy_n     : in   std_logic;
p_out_cfg_irq_assert_n : out  std_logic;
p_out_cfg_irq_n        : out  std_logic;
p_out_cfg_irq_di       : out  std_logic_vector(7 downto 0);

-----------------------------
--Технологические сигналы
-----------------------------
p_in_tst               : in   std_logic_vector(31 downto 0);
p_out_tst              : out  std_logic_vector(31 downto 0);

-----------------------------
--SYSTEM
-----------------------------
p_in_clk               : in   std_logic;
p_in_rst               : in   std_logic
);
end BMD_INTR_CTRL;

architecture behavioral of BMD_INTR_CTRL is

component BMD_INTR_CTRL_DEV
generic(
G_TIME_DLY : integer:=0
);
port(
--//Пользовательское управление
p_in_irq_set           : in   std_logic;
p_in_irq_clr           : in   std_logic;
p_out_irq_status       : out  std_logic;

--//Связь с ядром PCI-EXPRESS
p_in_cfg_msi           : in   std_logic;
p_in_cfg_irq_rdy_n     : in   std_logic;
p_out_cfg_irq_n        : out  std_logic;
p_out_cfg_irq_assert_n : out  std_logic;
p_out_cfg_irq_di       : out  std_logic_vector(7 downto 0);

--//Технологические сигналы
p_in_tst               : in  std_logic_vector(31 downto 0);
p_out_tst              : out std_logic_vector(31 downto 0);

--//SYSTEM
p_in_clk               : in   std_logic;
p_in_rst               : in   std_logic
);
end component;

Type TTimeDly is array (0 to C_HIRQ_COUNT_MAX-1) of integer;

constant C_TIMEDLY : TTimeDly:=(
8,   --HIRQ_PCIEXP_DMA_WR
12,  --HIRQ_PCIEXP_DMA_RD
0,   --HIRQ_TMR0
2,   --HIRQ_ETH_RXBUF
6,   --HIRQ_DEVCFG_RXBUF
9,   --HIRQ_HDD_CMDDONE
4,   --HIRQ_VIDEO_CH0
14,  --HIRQ_VIDEO_CH1
16,  --HIRQ_VIDEO_CH2
3,   --HIRQ_TRACK
7,
1,
5,
11,
10,
15
);

signal i_rst                       : std_logic;

signal i_cfg_irq_n                 : std_logic_vector(C_HIRQ_COUNT-1 downto 0);
signal i_cfg_irq_assert_n          : std_logic_vector(C_HIRQ_COUNT-1 downto 0);
signal i_irq_clr                   : std_logic_vector(C_HIRQ_COUNT-1 downto 0);

Type TIrqTST is array (0 to C_HIRQ_COUNT-1) of std_logic_vector(31 downto 0);
signal i_tst_out                   : TIrqTST;

signal i_irq_set                   : std_logic_vector(p_in_irq_set'range);


--//MAIN
begin

--//Технологические сигналы
p_out_tst<=(others=>'0');


--//Связь с ядром PCI-EXPRESS
--//16#00# - PCI_EXPRESS_LEGACY_INTA
--//16#01# - PCI_EXPRESS_LEGACY_INTB
--//16#02# - PCI_EXPRESS_LEGACY_INTC
--//16#03# - PCI_EXPRESS_LEGACY_INTD
p_out_cfg_irq_di       <= CONV_STD_LOGIC_VECTOR(16#00#, p_out_cfg_irq_di'length);

p_out_cfg_irq_n        <= AND_reduce(i_cfg_irq_n(C_HIRQ_COUNT - 1 downto 0));
p_out_cfg_irq_assert_n <= AND_reduce(i_cfg_irq_assert_n(C_HIRQ_COUNT - 1 downto 0));

--//Управление работой соответствующего канала прерывания
gen_ch: for i in 0 to C_HIRQ_COUNT - 1 generate

--//Назначаем флаг гашения перывания для выбраного канала перерывания
i_irq_clr(i)<=p_in_irq_clr when p_in_irq_num(C_HIRQ_COUNT - 1 downto 0)=i else '0';

--//Автомат управления прерыванием соотв. канала перерывания
m_BMD_INTR_CTRL_DEV : BMD_INTR_CTRL_DEV
generic map(
G_TIME_DLY => C_TIMEDLY(i)
)
port map(
--//Пользовательское управление
p_in_irq_set           => p_in_irq_set(i),--i_irq_set(i),--
p_in_irq_clr           => i_irq_clr(i),
p_out_irq_status       => p_out_irq_status(i),

--//Связь с ядром PCI-EXPRESS
p_in_cfg_msi           => p_in_cfg_msi,
p_in_cfg_irq_rdy_n     => p_in_cfg_irq_rdy_n,
p_out_cfg_irq_n        => i_cfg_irq_n(i),
p_out_cfg_irq_assert_n => i_cfg_irq_assert_n(i),
p_out_cfg_irq_di       => open,

--//Технологические сигналы
p_in_tst               => (others=>'0'),
p_out_tst              => i_tst_out(i),

--//SYSTEM
p_in_clk               => p_in_clk,
p_in_rst               => p_in_rst
);

end generate gen_ch;

--i_irq_set(C_HIRQ_PCIEXP_DMA_WR)<='0';--p_in_irq_set(C_HIRQ_PCIEXP_DMA_WR);
--i_irq_set(C_HIRQ_PCIEXP_DMA_RD)<='0';--p_in_irq_set(C_HIRQ_PCIEXP_DMA_RD);
--i_irq_set(C_HIRQ_TMR0         )<=p_in_irq_set(C_HIRQ_TMR0         );
--i_irq_set(C_HIRQ_ETH_RXBUF    )<='0';--p_in_irq_set(C_HIRQ_ETH_RXBUF    );
--i_irq_set(C_HIRQ_DEVCFG_RXBUF )<='0';--p_in_irq_set(C_HIRQ_DEVCFG_RXBUF );
--i_irq_set(C_HIRQ_HDD_CMDDONE  )<='0';--p_in_irq_set(C_HIRQ_HDD_CMDDONE  );
--i_irq_set(C_HIRQ_VIDEO_CH0    )<='0';--p_in_irq_set(C_HIRQ_VIDEO_CH0    );
--i_irq_set(C_HIRQ_VIDEO_CH1    )<='0';--p_in_irq_set(C_HIRQ_VIDEO_CH1    );
--i_irq_set(C_HIRQ_VIDEO_CH2    )<='0';--p_in_irq_set(C_HIRQ_VIDEO_CH2    );
--i_irq_set(C_HIRQ_TRACK_NIK    )<='0';--p_in_irq_set(C_HIRQ_TRACK_NIK    );

--END MAIN
end behavioral;

