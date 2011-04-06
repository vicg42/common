-------------------------------------------------------------------------
-- Company     : Linkos
-- Engineer    : Golovachenko Victor
--
-- Create Date : 02/04/2010
-- Module Name : eth_rx
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
use work.prj_def.all;
use work.eth_pkg.all;

library unisim;
use unisim.vcomponents.all;

entity eth_rx is
generic(
G_RD_REM_WIDTH    :       integer := 4;           -- Remainder width of read data
G_RD_DWIDTH       :       integer := 32           -- FIFO read data width,
);
port
(
--//------------------------------------
--//Управление
--//------------------------------------
p_in_usr_ctrl                   : in    std_logic_vector(15 downto 0);
p_in_usr_pattern_param          : in    std_logic_vector(15 downto 0);
p_in_usr_pattern                : in    TEthUsrPattern;

--//------------------------------------
--//Связь с пользовательским RXBUF
--//------------------------------------
p_out_usr_rxdata                : out   std_logic_vector(G_RD_DWIDTH-1 downto 0);
p_out_usr_rxdata_wr             : out   std_logic;
p_out_usr_rxdata_rdy            : out   std_logic;
p_out_usr_rxdata_sof            : out   std_logic;
p_in_usr_rxbuf_full             : in    std_logic;

--//------------------------------------
--//Связь с Local link RxFIFO
--//------------------------------------
p_in_rx_ll_data                 : in    std_logic_vector(7 downto 0);
p_in_rx_ll_sof_n                : in    std_logic;
p_in_rx_ll_eof_n                : in    std_logic;
p_in_rx_ll_src_rdy_n            : in    std_logic;
p_out_rx_ll_dst_rdy_n           : out   std_logic;
p_in_rx_ll_fifo_status          : in    std_logic_vector(3 downto 0);

--//------------------------------------
--//Управление передачей PAUSE Control Frame
--//(более подробно см. ug194.pdf/Flow Control Block/Flow Control Implementation Example)
--//------------------------------------
p_out_pause_req                 : out   std_logic;
p_out_pause_val                 : out   std_logic_vector(15 downto 0);

--//------------------------------------
--//Статистика принятого пакета
--//------------------------------------
p_in_rx_statistic               : in    std_logic_vector(27 downto 0);
p_in_rx_statistic_vld           : in    std_logic;

--//------------------------------------
--//SYSTEM
--//------------------------------------
p_in_clk                        : in    std_logic;
p_in_rst                        : in    std_logic
);
end eth_rx;


architecture behavioral of eth_rx is

--type   TPattern is array (0 to 15) of std_logic_vector(7 downto 0);
signal usr_pattern_size : std_logic_vector(15 downto 0);
--signal usr_pattern : TEthUsrPattern:=(
--CONV_STD_LOGIC_VECTOR(16#8A#, 8),
--CONV_STD_LOGIC_VECTOR(16#8B#, 8),
--CONV_STD_LOGIC_VECTOR(16#8C#, 8),
--CONV_STD_LOGIC_VECTOR(16#8D#, 8),
--CONV_STD_LOGIC_VECTOR(16#8E#, 8),
--CONV_STD_LOGIC_VECTOR(16#8F#, 8),
--CONV_STD_LOGIC_VECTOR(16#5A#, 8),
--CONV_STD_LOGIC_VECTOR(16#5B#, 8),
--CONV_STD_LOGIC_VECTOR(16#5C#, 8),
--CONV_STD_LOGIC_VECTOR(16#5D#, 8),
--CONV_STD_LOGIC_VECTOR(16#5E#, 8),
--CONV_STD_LOGIC_VECTOR(16#5F#, 8),
--CONV_STD_LOGIC_VECTOR(16#AA#, 8),
--CONV_STD_LOGIC_VECTOR(16#AB#, 8),
--CONV_STD_LOGIC_VECTOR(16#AC#, 8),
--CONV_STD_LOGIC_VECTOR(16#AD#, 8)
--);

component ll_fifo
generic (
MEM_TYPE        :       integer := 0;
BRAM_MACRO_NUM  :       integer := 1;
DRAM_DEPTH      :       integer := 16;
WR_DWIDTH       :       integer := 32;
RD_DWIDTH       :       integer := 32;
RD_REM_WIDTH    :       integer := 2;
WR_REM_WIDTH    :       integer := 2;
USE_LENGTH      :       boolean := true;
glbtm           :       time    := 1 ns
);
port
(
-- Reset
areset_in:              in std_logic;

-- clocks
write_clock_in:         in std_logic;
read_clock_in:          in std_logic;

-- Interface to downstream user application
data_out:               out std_logic_vector(0 to RD_DWIDTH-1);
rem_out:                out std_logic_vector(0 to RD_REM_WIDTH-1);
sof_out_n:              out std_logic;
eof_out_n:              out std_logic;
src_rdy_out_n:          out std_logic;
dst_rdy_in_n:           in std_logic;

-- Interface to upstream user application
data_in:                in std_logic_vector(0 to WR_DWIDTH-1);
rem_in:                 in std_logic_vector(0 to WR_REM_WIDTH-1);
sof_in_n:               in std_logic;
eof_in_n:               in std_logic;
src_rdy_in_n:           in std_logic;
dst_rdy_out_n:          out std_logic;

-- FIFO status signals
fifostatus_out:         out std_logic_vector(0 to 3);

-- Length Status
len_rdy_out:            out std_logic;
len_out:                out std_logic_vector(0 to 15);
len_err_out:            out std_logic
);
end component;

component eth_rx_mac_frame_header_clr
port
(
--//--------------------------
--//Пользовательское управление
--//--------------------------
--p_in_usr_pattern       : in  TEthUsrPattern;
p_in_usr_pattern_size  : in  std_logic_vector(15 downto 0); -- Input data

--//--------------------------
--//Upstream Port
--//--------------------------
p_in_upp_data          : in  std_logic_vector(7 downto 0);
p_in_upp_sof_n         : in  std_logic;
p_in_upp_eof_n         : in  std_logic;
p_in_upp_src_rdy_n     : in  std_logic;
p_out_upp_dst_rdy_n    : out std_logic;

--//--------------------------
--//Downstream Port
--//--------------------------
p_out_dwnp_data        : out std_logic_vector(7 downto 0);
p_out_dwnp_sof_n       : out std_logic;
p_out_dwnp_eof_n       : out std_logic;
p_out_dwnp_src_rdy_n   : out std_logic;
p_in_dwnp_dst_rdy_n    : in  std_logic;

--//--------------------------
--//System
--//--------------------------
p_in_clk               : in  std_logic;
p_in_rst               : in  std_logic
);
end component;

component eth_rx_mac_padding_clr
port
(
--//--------------------------
--//Пользовательское управление
--//--------------------------
p_in_usr_ctrl          : in  std_logic_vector(15 downto 0);

--//--------------------------
--//Upstream Port
--//--------------------------
p_in_upp_data          : in  std_logic_vector(7 downto 0); -- Input data
p_in_upp_sof_n         : in  std_logic; -- Input start of frame
p_in_upp_eof_n         : in  std_logic; -- Input end of frame
p_in_upp_src_rdy_n     : in  std_logic; -- Input source ready
p_out_upp_dst_rdy_n    : out std_logic;  -- Output destination ready

--//--------------------------
--//Downstream Port
--//--------------------------
p_out_dwnp_data        : out std_logic_vector(7 downto 0); -- Modified output data
p_out_dwnp_sof_n       : out std_logic; -- Output start of frame
p_out_dwnp_eof_n       : out std_logic; -- Output end of frame
p_out_dwnp_src_rdy_n   : out std_logic; -- Output source ready
p_in_dwnp_dst_rdy_n    : in  std_logic;  -- Input destination ready

--//--------------------------
--//System
--//--------------------------
p_in_clk               : in  std_logic; -- Input CLK from TRIMAC Reciever
p_in_rst               : in  std_logic -- Synchronous reset signal
);
end component;

component eth_rx_mac_cheker
port
(
--//--------------------------
--//Пользовательское управление
--//--------------------------
p_in_usr_ctrl          : in  std_logic_vector(15 downto 0);
p_in_usr_pattern       : in  TEthUsrPattern;
p_in_usr_pattern_size  : in  std_logic_vector(15 downto 0); -- Input data

--//--------------------------
--//Upstream Port
--//--------------------------
p_in_upp_data          : in  std_logic_vector(7 downto 0); -- Input data
p_in_upp_sof_n         : in  std_logic; -- Input start of frame
p_in_upp_eof_n         : in  std_logic; -- Input end of frame
p_in_upp_src_rdy_n     : in  std_logic; -- Input source ready
p_out_upp_dst_rdy_n    : out std_logic;  -- Output destination ready

--//--------------------------
--//Downstream Port
--//--------------------------
p_out_dwnp_data        : out std_logic_vector(7 downto 0); -- Modified output data
p_out_dwnp_sof_n       : out std_logic; -- Output start of frame
p_out_dwnp_eof_n       : out std_logic; -- Output end of frame
p_out_dwnp_src_rdy_n   : out std_logic; -- Output source ready
p_in_dwnp_dst_rdy_n    : in  std_logic;  -- Input destination ready

--//--------------------------
--//System
--//--------------------------
p_in_clk               : in  std_logic; -- Input CLK from TRIMAC Reciever
p_in_rst               : in  std_logic -- Synchronous reset signal
);
end component;


signal ll_sof                    : std_logic;
signal ll_eof                    : std_logic;
signal ll_src_rdy                : std_logic;
signal ll_data                   : std_logic_vector(G_RD_DWIDTH-1 downto 0);

signal i_usr_ll_data_tmp         : std_logic_vector(0 to G_RD_DWIDTH-1);
signal i_usr_ll_sof_n            : std_logic;
signal i_usr_ll_eof_n            : std_logic;
signal i_usr_ll_src_rdy_n        : std_logic;
signal i_usr_ll_dst_rdy_n        : std_logic;
signal i_usr_ll_rem_out          : std_logic_vector(0 to G_RD_REM_WIDTH-1);

signal rx_ll_data_tmp            : std_logic_vector(7 downto 0);
signal rx_ll_data                : std_logic_vector(0 to 7);
signal rx_ll_sof_n               : std_logic;
signal rx_ll_eof_n               : std_logic;
signal rx_ll_src_rdy_n           : std_logic;
signal rx_ll_dst_rdy_n           : std_logic;

signal rx_ll0_data_tmp           : std_logic_vector(7 downto 0);
signal rx_ll0_sof_n              : std_logic;
signal rx_ll0_eof_n              : std_logic;
signal rx_ll0_src_rdy_n          : std_logic;
signal rx_ll0_dst_rdy_n          : std_logic;

signal rx_ll1_data_tmp           : std_logic_vector(7 downto 0);
signal rx_ll1_sof_n              : std_logic;
signal rx_ll1_eof_n              : std_logic;
signal rx_ll1_src_rdy_n          : std_logic;
signal rx_ll1_dst_rdy_n          : std_logic;

--//Сигналы необходимые для Управление передачей Pause Frame
signal i_fifostatus_out          : std_logic_vector(0 to 3);
signal i_pause_req               : std_logic;
signal i_pause_val               : std_logic;

type fsm_pause_ctrl is
(
  S_SUSPEND_STREAM,
  S_RESUME_STREAM
);
signal fsm_pause_ctrl_cs: fsm_pause_ctrl;



--MAIN
begin


--//Связь с пользовательским RXBUF

p_out_usr_rxdata_sof <= ll_sof;
p_out_usr_rxdata_rdy <= ll_eof;
p_out_usr_rxdata_wr  <= ll_src_rdy;
p_out_usr_rxdata     <= ll_data;

process(p_in_rst,p_in_clk)
begin
  if p_in_rst='1' then
    ll_sof <='0';
    ll_eof <= '0';
    ll_src_rdy<='0';

    for i in 0 to 15 loop
      ll_data(i) <= '0';
    end loop;

  elsif p_in_clk'event and p_in_clk='1' then
    ll_sof <= not i_usr_ll_sof_n and not i_usr_ll_src_rdy_n;
    ll_eof <= not i_usr_ll_eof_n and not i_usr_ll_src_rdy_n;
    ll_src_rdy<=not i_usr_ll_src_rdy_n;

    for i in 0 to G_RD_DWIDTH-1 loop
      ll_data(i) <= i_usr_ll_data_tmp(i);
    end loop;
  end if;
end process;



i_usr_ll_dst_rdy_n<= p_in_usr_rxbuf_full;

--//--------------------------------
--//Буфер RxDATA - Size определяется параметром BRAM_MACRO_NUM
--//--------------------------------
m_ll_rxfifo : ll_fifo
generic map(
MEM_TYPE        => 0,           -- 0 choose BRAM, 1 choose Distributed RAM
BRAM_MACRO_NUM  => 1,           -- Memory Depth(Кол-во элементов BRAM (1BRAM-4kB). For BRAM only - Allowed: 1, 2, 4, 8, 16
DRAM_DEPTH      => 16,          -- Memory Depth. For DRAM only

WR_REM_WIDTH    => 1,           -- Remainder width of write data
WR_DWIDTH       => 8,           -- FIFO write data width,
                                   -- Acceptable values are 8, 16, 32, 64, 128.

RD_REM_WIDTH    => G_RD_REM_WIDTH,-- Remainder width of read data
RD_DWIDTH       => G_RD_DWIDTH,   -- FIFO read data width,
                                   -- Acceptable values are 8, 16, 32, 64, 128.

USE_LENGTH      => false,       -- Length FIFO option
glbtm           => 1 ns         -- Global timing delay for simulation
)
port map
(
-- Reset
areset_in              => p_in_rst,

-- Interface to downstream user application
data_out               => i_usr_ll_data_tmp,
rem_out                => i_usr_ll_rem_out,
sof_out_n              => i_usr_ll_sof_n,
eof_out_n              => i_usr_ll_eof_n,
src_rdy_out_n          => i_usr_ll_src_rdy_n,
dst_rdy_in_n           => i_usr_ll_dst_rdy_n,

read_clock_in          => p_in_clk,

-- Interface to upstream user application
data_in                => rx_ll_data,
rem_in                 => "0",
sof_in_n               => rx_ll_sof_n,
eof_in_n               => rx_ll_eof_n,
src_rdy_in_n           => rx_ll_src_rdy_n,
dst_rdy_out_n          => rx_ll_dst_rdy_n,

write_clock_in         => p_in_clk,

-- FIFO status signals
fifostatus_out         => i_fifostatus_out,

-- Length Status
len_rdy_out            => open,
len_out                => open,
len_err_out            => open
);

--//
LB_LL_RXBUF : for i in 0 to 7 generate
begin
rx_ll_data(i) <= rx_ll_data_tmp(i);
end generate LB_LL_RXBUF;


--//--------------------------------
--//Модуль управления удалением данных из потока p_in_rx_ll_data
--//--------------------------------
m_rx_mac_frame_header_clr : eth_rx_mac_frame_header_clr
port map
(
--//--------------------------
--//Пользовательское управление
--//--------------------------
--p_in_usr_pattern       => p_in_usr_pattern,
p_in_usr_pattern_size  => p_in_usr_pattern_param,--"0000000000001110",--

--//--------------------------
--//Upstream Port
--//--------------------------
--p_in_upp_data          => p_in_rx_ll_data,
--p_in_upp_sof_n         => p_in_rx_ll_sof_n,
--p_in_upp_eof_n         => p_in_rx_ll_eof_n,
--p_in_upp_src_rdy_n     => p_in_rx_ll_src_rdy_n,
--p_out_upp_dst_rdy_n    => p_out_rx_ll_dst_rdy_n,
p_in_upp_data          => rx_ll0_data_tmp,
p_in_upp_sof_n         => rx_ll0_sof_n,
p_in_upp_eof_n         => rx_ll0_eof_n,
p_in_upp_src_rdy_n     => rx_ll0_src_rdy_n,
p_out_upp_dst_rdy_n    => rx_ll0_dst_rdy_n,


--//--------------------------
--//Downstream Port
--//--------------------------
p_out_dwnp_data        => rx_ll_data_tmp,
p_out_dwnp_sof_n       => rx_ll_sof_n,
p_out_dwnp_eof_n       => rx_ll_eof_n,
p_out_dwnp_src_rdy_n   => rx_ll_src_rdy_n,
p_in_dwnp_dst_rdy_n    => rx_ll_dst_rdy_n,

--//--------------------------
--//System
--//--------------------------
p_in_clk               => p_in_clk,
p_in_rst               => p_in_rst
);



m_rx_mac_padding_clr : eth_rx_mac_padding_clr
port map
(
--//--------------------------
--//Пользовательское управление
--//--------------------------
p_in_usr_ctrl          => p_in_usr_ctrl,

--//--------------------------
--//Upstream Port
--//--------------------------
p_in_upp_data          => rx_ll1_data_tmp,
p_in_upp_sof_n         => rx_ll1_sof_n,
p_in_upp_eof_n         => rx_ll1_eof_n,
p_in_upp_src_rdy_n     => rx_ll1_src_rdy_n,
p_out_upp_dst_rdy_n    => rx_ll1_dst_rdy_n,

--//--------------------------
--//Downstream Port
--//--------------------------
p_out_dwnp_data        => rx_ll0_data_tmp,
p_out_dwnp_sof_n       => rx_ll0_sof_n,
p_out_dwnp_eof_n       => rx_ll0_eof_n,
p_out_dwnp_src_rdy_n   => rx_ll0_src_rdy_n,
p_in_dwnp_dst_rdy_n    => rx_ll0_dst_rdy_n,

--//--------------------------
--//System
--//--------------------------
p_in_clk               => p_in_clk,
p_in_rst               => p_in_rst
);


--//--------------------------------
--//Проверка в принятом пакете поля MAC DST
--//--------------------------------
usr_pattern_size<=CONV_STD_LOGIC_VECTOR(6, 16);

m_rx_mac_cheker : eth_rx_mac_cheker
port map
(
--//--------------------------
--//Пользовательское управление
--//--------------------------
p_in_usr_ctrl          => p_in_usr_ctrl,
p_in_usr_pattern       => p_in_usr_pattern,--МАС для сравнения с полем DST Кадра MAC
p_in_usr_pattern_size  => usr_pattern_size,

--//--------------------------
--//Upstream Port
--//--------------------------
p_in_upp_data          => p_in_rx_ll_data,
p_in_upp_sof_n         => p_in_rx_ll_sof_n,
p_in_upp_eof_n         => p_in_rx_ll_eof_n,
p_in_upp_src_rdy_n     => p_in_rx_ll_src_rdy_n,
p_out_upp_dst_rdy_n    => p_out_rx_ll_dst_rdy_n,

--//--------------------------
--//Downstream Port
--//--------------------------
p_out_dwnp_data        => rx_ll1_data_tmp,
p_out_dwnp_sof_n       => rx_ll1_sof_n,
p_out_dwnp_eof_n       => rx_ll1_eof_n,
p_out_dwnp_src_rdy_n   => rx_ll1_src_rdy_n,
p_in_dwnp_dst_rdy_n    => rx_ll1_dst_rdy_n,

--//--------------------------
--//System
--//--------------------------
p_in_clk               => p_in_clk,
p_in_rst               => p_in_rst
);

--rx_ll_data_tmp  <= p_in_rx_ll_data;
--rx_ll_sof_n     <= p_in_rx_ll_sof_n;
--rx_ll_eof_n     <= p_in_rx_ll_eof_n;
--rx_ll_src_rdy_n <= p_in_rx_ll_src_rdy_n;
--p_out_rx_ll_dst_rdy_n <= rx_ll_dst_rdy_n;


--//------------------------------------
--//Управление передачей Pause Frame
--//------------------------------------
p_out_pause_req <=i_pause_req;

LB_PAUSE_VAL : for i in 0 to 15 generate
begin
p_out_pause_val(i) <=i_pause_val;
end generate LB_PAUSE_VAL;

i_pause_req<='0';
i_pause_val<='0';

----//Автомат слежения за уровнем заполнености FIFO
----//В зависимости от уровня заполнености FIFO идет управление
----//отправкой пакетов PAUSE FRAME
--process(p_in_rst,p_in_clk)
--begin
--  if p_in_rst='1' then
--    i_pause_req<='0';
--    i_pause_val<='0';
--
--  elsif p_in_clk'event and p_in_clk='1' then
--
--    case fsm_pause_ctrl_cs is
--
--      when S_SUSPEND_STREAM =>
--        if i_fifostatus_out(0)='1' and
--          i_fifostatus_out(1)='1' and
--          i_fifostatus_out(2)='1' and
--          i_fifostatus_out(3)='0' then
--          --//LocalLink FIFO is 7/8 full
--          i_pause_req<='1';
--          i_pause_val<='1';
--          fsm_pause_ctrl_cs<=S_RESUME_STREAM;
--        else
--          i_pause_req<='0';
--        end if;
--
--      when S_RESUME_STREAM =>
--        i_pause_val<='0';
--
--        if i_fifostatus_out(0)='1' and
--          i_fifostatus_out(1)='0' and
--          i_fifostatus_out(2)='0' and
--          i_fifostatus_out(3)='0' then
--          --//LocalLink FIFO is 1/2 full
--          i_pause_req<='1';
--
--          fsm_pause_ctrl_cs<=S_SUSPEND_STREAM;
--        else
--          i_pause_req<='0';
--        end if;
--
--    end case;
--  end if;
--end process;

--END MAIN
end behavioral;




--component eth_rx_pkt_analizer
--port
--(
----//--------------------------
----//Upstream Port
----//--------------------------
--p_in_upp_data          : in  std_logic_vector(7 downto 0); -- Input data
--p_in_upp_sof_n         : in  std_logic; -- Input start of frame
--p_in_upp_eof_n         : in  std_logic; -- Input end of frame
--p_in_upp_src_rdy_n     : in  std_logic; -- Input source ready
--p_out_upp_dst_rdy_n    : out std_logic;  -- Output destination ready
--
----//--------------------------
----//Downstream Port
----//--------------------------
--p_out_dwnp_data        : out std_logic_vector(15 downto 0);
--p_out_dwnp_wr          : out std_logic;
--p_out_dwnp_rdy         : out std_logic;
--
----//--------------------------
----//System
----//--------------------------
--p_out_tst              : out std_logic_vector(7 downto 0); -- Modified output data
--
--p_in_clk               : in  std_logic; -- Input CLK from TRIMAC Reciever
--p_in_rst               : in  std_logic -- Synchronous reset signal
--);
--end component;
--
--m_rx_pkt_analizer : eth_rx_pkt_analizer
--port map
--(
----//--------------------------
----//Upstream Port
----//--------------------------
--p_in_upp_data          => p_in_rx_ll_data,
--p_in_upp_sof_n         => p_in_rx_ll_sof_n,
--p_in_upp_eof_n         => p_in_rx_ll_eof_n,
--p_in_upp_src_rdy_n     => p_in_rx_ll_src_rdy_n,
--p_out_upp_dst_rdy_n    => p_out_rx_ll_dst_rdy_n,
--
----//--------------------------
----//Downstream Port
----//--------------------------
--p_out_dwnp_data        => open,
--p_out_dwnp_wr          => open,
--p_out_dwnp_rdy         => open,
--
----//--------------------------
----//System
----//--------------------------
--p_out_tst              => open,
--
--p_in_clk               => p_in_clk,
--p_in_rst               => p_in_rst
--);

